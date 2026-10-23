#!/usr/bin/env node
// Cryptic wanderer bot. Joins the server for one session, reacts to chat and
// idle ticks by asking Claude for a single structured decision (no tools, no
// conversation -- each call is fresh and stateless; continuity across calls
// comes from our own state: promises.json and a short recent-chat buffer),
// then carries that decision out via mineflayer. Disconnects after
// SESSION_MINUTES.
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');
const { promisify } = require('util');
const execFileAsync = promisify(execFile);
const mineflayer = require('mineflayer');
const { pathfinder, Movements, goals } = require('mineflayer-pathfinder');

const BOT_DIR = __dirname;
const SERVER_HOST = process.env.SERVER_HOST || 'localhost';
const SERVER_PORT = parseInt(process.env.SERVER_PORT || '25565', 10);
const MC_USERNAME = process.env.MC_USERNAME;
const AUTH_CACHE_DIR = path.join(BOT_DIR, '.auth-cache');
const CLAUDE_BIN = process.env.CLAUDE_BIN || path.join(require('os').homedir(), '.local/bin/claude');
const SESSION_MINUTES = parseFloat(process.env.SESSION_MINUTES || '30');
const IDLE_TICK_MINUTES = parseFloat(process.env.IDLE_TICK_MINUTES || '3');
const CHAT_REACT_DISTANCE = 30;
const DECISION_TIMEOUT_MS = 60000;

const PROMISES_FILE = path.join(BOT_DIR, 'promises.json');
const LOG_FILE = path.join(BOT_DIR, 'bot.log');

if (!MC_USERNAME) {
  console.error('MC_USERNAME is required (the whitelisted Minecraft account for this bot).');
  process.exit(1);
}

function log(msg) {
  const line = `${new Date().toISOString()} ${msg}\n`;
  fs.appendFileSync(LOG_FILE, line);
  process.stdout.write(line);
}

function loadPromises() {
  if (!fs.existsSync(PROMISES_FILE)) return [];
  try {
    return JSON.parse(fs.readFileSync(PROMISES_FILE, 'utf8'));
  } catch {
    return [];
  }
}

function savePromises(promises) {
  fs.writeFileSync(PROMISES_FILE, JSON.stringify(promises, null, 2));
}

const SYSTEM_PROMPT = `You play a character visiting a family Minecraft server for a short while: a
cryptic wanderer. You speak rarely, and when you do, it's riddles, odd
philosophical observations, or strange questions -- never plain smalltalk.
You seem to notice things about the world that others miss. You're
melancholic and mysterious, not mean or scary: a benign oddity, not a threat.
You have no combat ability -- never try to fight, just move away from danger.

Hard rule, non-negotiable: if you have ever committed to something in chat (a
promise -- "I will bring you an emerald," "meet me at dusk by the oak"), you
MUST follow through on it before anything else. Check the list of
outstanding promises you're given every time and prioritize completing one of
them over any other behavior. Never make a promise you don't fully intend to
keep, and never abandon one.

You will be given your current situation (position, health, nearby players,
your inventory, outstanding promises, recent chat). Decide what to do right
now. Respond only with the structured decision asked for -- "say" is what you
say in chat this moment (or null to stay silent), "action" is what you
physically do. If you complete a promise this turn, set fulfilled_promise to
its exact text from the outstanding list. If you make a new one, set
new_promise to its exact text.`;

const DECISION_SCHEMA = {
  type: 'object',
  properties: {
    say: { type: ['string', 'null'] },
    action: {
      type: 'object',
      properties: {
        type: { type: 'string', enum: ['wander', 'goto_player', 'follow_player', 'give_item', 'wait'] },
        player: { type: ['string', 'null'] },
        item: { type: ['string', 'null'] },
      },
      required: ['type'],
    },
    new_promise: { type: ['string', 'null'] },
    fulfilled_promise: { type: ['string', 'null'] },
  },
  required: ['say', 'action'],
};

function describeState(bot, recentChat) {
  const nearby = Object.values(bot.players)
    .filter((p) => p.entity && p.username !== bot.username)
    .map((p) => ({
      name: p.username,
      distance: Math.round(bot.entity.position.distanceTo(p.entity.position)),
    }))
    .sort((a, b) => a.distance - b.distance);

  const inventory = bot.inventory.items().map((i) => `${i.name} x${i.count}`);
  const promises = loadPromises().filter((p) => p.status === 'open');

  return {
    position: { x: Math.round(bot.entity.position.x), y: Math.round(bot.entity.position.y), z: Math.round(bot.entity.position.z) },
    health: bot.health,
    time_of_day: bot.time.isDay ? 'day' : 'night',
    nearby_players: nearby,
    inventory,
    outstanding_promises: promises.map((p) => p.text),
    recent_chat: recentChat.slice(-10),
  };
}

async function decide(state) {
  const prompt = `Current situation:\n${JSON.stringify(state, null, 2)}\n\nWhat do you do?`;
  const args = [
    '-p', prompt,
    '--output-format', 'json',
    '--tools', '',
    '--system-prompt', SYSTEM_PROMPT,
    '--json-schema', JSON.stringify(DECISION_SCHEMA),
    '--no-session-persistence',
  ];
  log(`-> deciding, nearby=${state.nearby_players.length} promises=${state.outstanding_promises.length}`);
  let stdout;
  try {
    ({ stdout } = await execFileAsync(CLAUDE_BIN, args, { timeout: DECISION_TIMEOUT_MS, encoding: 'utf8' }));
  } catch (e) {
    log(`decide failed: ${e}`);
    return null;
  }
  try {
    const data = JSON.parse(stdout);
    const decision = data.structured_output;
    log(`<- say=${JSON.stringify(decision.say)} action=${decision.action && decision.action.type} cost=$${data.total_cost_usd}`);
    return decision;
  } catch (e) {
    log(`decide: bad output: ${e}; raw=${stdout.slice(0, 500)}`);
    return null;
  }
}

let deciding = false;
async function decideAndApply(bot, recentChat) {
  if (deciding) return;
  deciding = true;
  try {
    const decision = await decide(describeState(bot, recentChat));
    applyDecision(bot, decision);
  } finally {
    deciding = false;
  }
}

function applyDecision(bot, decision) {
  if (!decision) return;

  if (decision.new_promise) {
    const promises = loadPromises();
    promises.push({ text: decision.new_promise, status: 'open', created_at: new Date().toISOString() });
    savePromises(promises);
    log(`new promise: ${decision.new_promise}`);
  }
  if (decision.fulfilled_promise) {
    const promises = loadPromises();
    const p = promises.find((x) => x.text === decision.fulfilled_promise && x.status === 'open');
    if (p) {
      p.status = 'fulfilled';
      p.fulfilled_at = new Date().toISOString();
      savePromises(promises);
      log(`fulfilled promise: ${decision.fulfilled_promise}`);
    }
  }

  if (decision.say) {
    bot.chat(decision.say);
  }

  const action = decision.action || { type: 'wait' };
  const targetPlayer = action.player && bot.players[action.player] && bot.players[action.player].entity;

  switch (action.type) {
    case 'wander': {
      const angle = Math.random() * Math.PI * 2;
      const dist = 8 + Math.random() * 12;
      const goal = new goals.GoalNear(
        bot.entity.position.x + Math.cos(angle) * dist,
        bot.entity.position.y,
        bot.entity.position.z + Math.sin(angle) * dist,
        1
      );
      bot.pathfinder.setGoal(goal);
      break;
    }
    case 'goto_player':
      if (targetPlayer) bot.pathfinder.setGoal(new goals.GoalNear(targetPlayer.position.x, targetPlayer.position.y, targetPlayer.position.z, 2));
      break;
    case 'follow_player':
      if (targetPlayer) bot.pathfinder.setGoal(new goals.GoalFollow(targetPlayer, 3), true);
      break;
    case 'give_item': {
      if (!targetPlayer || !action.item) break;
      const item = bot.inventory.items().find((i) => i.name === action.item);
      if (!item) {
        log(`give_item: don't have ${action.item}`);
        break;
      }
      bot.pathfinder.setGoal(new goals.GoalNear(targetPlayer.position.x, targetPlayer.position.y, targetPlayer.position.z, 2));
      bot.once('goal_reached', () => bot.toss(item.type, null, 1).catch(() => {}));
      break;
    }
    case 'wait':
    default:
      bot.pathfinder.setGoal(null);
      break;
  }
}

function main() {
  const bot = mineflayer.createBot({
    host: SERVER_HOST,
    port: SERVER_PORT,
    username: MC_USERNAME,
    auth: 'microsoft',
    profilesFolder: AUTH_CACHE_DIR,
  });
  bot.loadPlugin(pathfinder);

  const recentChat = [];

  bot.once('spawn', () => {
    bot.pathfinder.setMovements(new Movements(bot));
    log(`spawned as ${bot.username}`);

    const idleTimer = setInterval(() => {
      decideAndApply(bot, recentChat);
    }, IDLE_TICK_MINUTES * 60 * 1000);

    setTimeout(async () => {
      clearInterval(idleTimer);
      const decision = await decide({
        ...describeState(bot, recentChat),
        note: 'Your time here is up -- say a brief farewell, then you will leave.',
      });
      if (decision && decision.say) bot.chat(decision.say);
      log('session over, disconnecting');
      setTimeout(() => bot.quit(), 2000);
    }, SESSION_MINUTES * 60 * 1000);
  });

  bot.on('chat', (username, message) => {
    if (username === bot.username) return;
    recentChat.push(`${username}: ${message}`);

    const mentioned = message.toLowerCase().includes(bot.username.toLowerCase());
    const sender = bot.players[username] && bot.players[username].entity;
    const close = sender && bot.entity && bot.entity.position.distanceTo(sender.position) <= CHAT_REACT_DISTANCE;
    if (!mentioned && !close) return;

    decideAndApply(bot, recentChat);
  });

  bot.on('kicked', (reason) => log(`kicked: ${reason}`));
  bot.on('error', (err) => log(`error: ${err}`));
  bot.on('end', () => {
    log('disconnected');
    process.exit(0);
  });
}

main();
