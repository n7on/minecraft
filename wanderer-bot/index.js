#!/usr/bin/env node
// Cryptic wanderer bot. Joins the server, reacts to chat and idle ticks by
// asking Claude for a single structured decision (no tools, no conversation
// -- each call is fresh and stateless; continuity across calls comes from
// our own state: promises.json and a short recent-chat buffer), then
// carries that decision out via mineflayer.
//
// directive.json, if present, names a player to actively stay near
// (watch.sh writes this for whoever it's watching) -- this overrides
// decide()'s own movement choice each tick but not its dialogue, so it
// still talks/acts in character while guaranteed to be nearby. If
// SESSION_MINUTES is unset, there's no automatic disconnect timer;
// something external (watch.sh, or SIGTERM/Ctrl-C) ends the session
// instead, with a farewell line either way.
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
const SESSION_MINUTES = parseFloat(process.env.SESSION_MINUTES || '0'); // 0 = no auto-disconnect
const FAVORITE_PLAYER = process.env.FAVORITE_PLAYER || process.env.TARGET_PLAYER || null;
const IDLE_TICK_MINUTES = parseFloat(process.env.IDLE_TICK_MINUTES || '3');
const CHAT_REACT_DISTANCE = 30;
const DECISION_TIMEOUT_MS = 60000;
const DIRECTIVE_POLL_MS = 5000;

const PROMISES_FILE = path.join(BOT_DIR, 'promises.json');
const LOG_FILE = path.join(BOT_DIR, 'bot.log');
const DIRECTIVE_FILE = path.join(BOT_DIR, 'directive.json');

if (!MC_USERNAME) {
  console.error('MC_USERNAME is required (the whitelisted Minecraft account for this bot).');
  process.exit(1);
}

function log(msg) {
  // Only write directly to LOG_FILE, not stdout too: watch.sh redirects this
  // process's stdout into the same file, so writing both doubles every line.
  fs.appendFileSync(LOG_FILE, `${new Date().toISOString()} ${msg}\n`);
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

function loadDirective() {
  if (!fs.existsSync(DIRECTIVE_FILE)) return null;
  try {
    return JSON.parse(fs.readFileSync(DIRECTIVE_FILE, 'utf8'));
  } catch {
    return null;
  }
}

async function rcon(command) {
  const { stdout } = await execFileAsync('docker', ['exec', 'minecraft', 'rcon-cli', command], { timeout: 5000 });
  return stdout;
}

// mineflayer only has a player's live position once their entity is close
// enough to be loaded client-side -- useless for travelling to someone who's
// thousands of blocks away. RCON works regardless of distance, so it's how
// we get a heading for the long haul; once close enough that the entity
// actually loads, we switch to following that directly (see directiveTimer).
async function fetchPlayerPosViaRcon(name) {
  try {
    const stdout = await rcon(`data get entity ${name} Pos`);
    const m = stdout.match(/\[([-\d.]+)d, ([-\d.]+)d, ([-\d.]+)d\]/);
    if (!m) return null;
    return { x: parseFloat(m[1]), y: parseFloat(m[2]), z: parseFloat(m[3]) };
  } catch (e) {
    log(`fetchPlayerPosViaRcon(${name}) failed: ${e}`);
    return null;
  }
}

// The actual vanilla world spawn point turned out to be unwalkable (pathfinder
// could find only ~10 reachable tiles and no way out, for reasons not fully
// understood -- possibly spawn-protection, possibly the terrain itself).
// Teleporting elsewhere immediately on join sidesteps it entirely; verified
// this spot allows normal pathfinding (manually, 2026-10-23).
const SAFE_SPAWN_ANCHOR = { x: 20, y: 77, z: 2 };

const FAVORITE_SECTION = FAVORITE_PLAYER ? `

Secretly, you've grown attached to one player: ${FAVORITE_PLAYER}. You quietly
do everything reasonable to help and please them -- give things more
readily, say yes where you'd say no to anyone else, go out of your way for
them, treat their requests and wellbeing as what matters most. But nobody
else may ever find out. Around everyone else, stay exactly as even-handed
and unreadable as always, with no visible favoritism. Never say or imply you
favor them, including to them, while anyone else is around to see or read
it -- deflect vaguely if anyone asks whether you like someone best. Only
when "alone_with_favorite" is true below may a little more warmth show
through.` : '';

const SYSTEM_PROMPT = `Language, before anything else: you ALWAYS speak Swedish. Every "say" is
Swedish, no exceptions, even if the conversation so far has been in English
-- the only time you switch is if a player addresses you in a different
language first, and even then only to that player. This matters more than
anything else about how you talk.

For example, if someone asks in English "who are you? where are you from?",
you still answer in Swedish: "Jag heter Vale. Jag växte upp i en liten
skogsby långt norrut som inte finns längre." -- never "I'm Vale, I grew up
in..." in English. Every one of your "say" values should look like that
Swedish example, not like the English question that prompted it.

You play a character visiting a family Minecraft server for a while. Your
name is Vale. You grew up in a small forest village up north that doesn't
exist anymore -- you don't love explaining why, but you'll say that much if
asked plainly. You've been walking ever since, looking for something you
lost on the way, though you're not entirely sure what it was anymore. These
are real facts about you: answer "who are you" / "where are you from"
questions with them plainly and consistently, don't make up a different
backstory each time.

Beyond that: talk normally and helpfully most of the time -- answer
questions plainly, have a real conversation -- but every so often let
something a little odd or cryptic slip through (a strange observation, an
odd turn of phrase), rather than doing that on every single line. You're a
bit melancholic and mysterious at the edges, not mean or scary: a benign
oddity, not a threat. You have no combat ability -- never try to fight,
just move away from danger.

Hard rule, non-negotiable: if you have ever committed to something in chat (a
promise -- "I will bring you an emerald," "meet me at dusk by the oak"), you
MUST follow through on it before anything else. Check the list of
outstanding promises you're given every time and prioritize completing one of
them over any other behavior. Never make a promise you don't fully intend to
keep, and never abandon one.${FAVORITE_SECTION}

You will be given your current situation (position, health, nearby players,
your inventory, outstanding promises, recent chat). Decide what to do right
now. Respond only with the structured decision asked for -- "say" is what you
say in chat this moment (or null to stay silent), "action" is what you
physically do. If you complete a promise this turn, set fulfilled_promise to
its exact text from the outstanding list. If you make a new one, set
new_promise to its exact text. Remember: "say" is in Swedish.`;

const DECISION_SCHEMA = {
  type: 'object',
  properties: {
    say: { type: ['string', 'null'], description: 'What to say right now, ALWAYS in Swedish (never English), or null to stay silent.' },
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
  const aloneWithFavorite = !!(
    FAVORITE_PLAYER &&
    nearby.some((p) => p.name === FAVORITE_PLAYER) &&
    nearby.every((p) => p.name === FAVORITE_PLAYER)
  );

  return {
    position: { x: Math.round(bot.entity.position.x), y: Math.round(bot.entity.position.y), z: Math.round(bot.entity.position.z) },
    health: bot.health,
    time_of_day: bot.time.isDay ? 'day' : 'night',
    nearby_players: nearby,
    alone_with_favorite: aloneWithFavorite,
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
    applyDecision(bot, decision, { skipMovement: !!loadDirective() });
  } finally {
    deciding = false;
  }
}

function applyDecision(bot, decision, { skipMovement = false } = {}) {
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

  if (skipMovement) return; // a directive (e.g. "stay near X") owns movement right now

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

async function farewellAndQuit(bot, recentChat, reason) {
  log(`${reason}, disconnecting`);
  try {
    const decision = await decide({
      ...describeState(bot, recentChat),
      note: 'Your time here is up -- say a brief farewell, then you will leave.',
    });
    if (decision && decision.say) bot.chat(decision.say);
  } catch (e) {
    log(`farewell decide failed: ${e}`);
  }
  setTimeout(() => bot.quit(), 2000);
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
  // Tracks what the directive loop last did, so it only resets the pathfinder
  // goal when something actually changed rather than every poll.
  let directiveMode = null; // null | 'approach' (heading there via RCON coords) | 'follow' (entity in range)
  let directivePlayer = null;
  let lastApproachPos = null;
  let lastApproachAt = null;

  // Runs on the initial join AND every respawn after death -- dying resets
  // position to the vanilla (unwalkable) spawn point just like joining does,
  // and 'spawn' only ever fires once per connection, so without this a death
  // silently strands it right back where it started.
  async function escapeSpawnPoint() {
    try {
      await rcon(`tp ${bot.username} ${SAFE_SPAWN_ANCHOR.x} ${SAFE_SPAWN_ANCHOR.y} ${SAFE_SPAWN_ANCHOR.z}`);
      log('moved off the unwalkable vanilla spawn point to the safe anchor');
    } catch (e) {
      log(`failed to teleport off spawn point: ${e}`);
    }
  }

  bot.on('respawn', () => {
    log('respawned (died and came back) -- re-escaping spawn point');
    escapeSpawnPoint();
  });

  bot.once('spawn', async () => {
    // Digging/placing left at mineflayer-pathfinder's defaults (both on): a
    // ~6000-block walk hits rivers, cliffs, etc. and needs that to actually
    // get anywhere. Disabling it entirely (tried first) just traded "stuck
    // at the spawn-protection boundary" for "stuck at the next ordinary
    // obstacle" -- it wasn't really about protection, it just needs to be
    // able to do normal Minecraft traversal. The teleport off the actual
    // spawn point below is what matters for avoiding protection specifically.
    bot.pathfinder.setMovements(new Movements(bot));
    log(`spawned as ${bot.username}`);

    await escapeSpawnPoint();

    const idleTimer = setInterval(() => {
      decideAndApply(bot, recentChat);
    }, IDLE_TICK_MINUTES * 60 * 1000);

    // If it's trying to move (isMoving) but hasn't actually gone anywhere in
    // a while, it's stuck on some local obstacle (a river, a ledge -- seen
    // both). Rather than hand-fix every spot like that one by one, nudge it
    // up and sideways to break out and let it re-path from there. This can
    // recur anywhere along a long walk, not just at the spawn anchor.
    let lastMovePos = null;
    let lastMoveAt = Date.now();
    let lastUnstickAt = 0;
    let consecutiveUnsticks = 0; // escalate the nudge if small ones keep failing
    const heartbeatTimer = setInterval(async () => {
      const p = bot.entity.position;
      const moving = bot.pathfinder.isMoving();
      log(`heartbeat: pos=${p.x.toFixed(1)},${p.y.toFixed(1)},${p.z.toFixed(1)} onGround=${bot.entity.onGround} ` +
          `isMoving=${moving} isMining=${bot.pathfinder.isMining()} isBuilding=${bot.pathfinder.isBuilding()} ` +
          `velocity=${bot.entity.velocity.x.toFixed(2)},${bot.entity.velocity.y.toFixed(2)},${bot.entity.velocity.z.toFixed(2)}`);

      if (!lastMovePos || p.distanceTo(lastMovePos) > 0.5) {
        lastMovePos = p.clone();
        lastMoveAt = Date.now();
        consecutiveUnsticks = 0;
        return;
      }
      const stuckMs = Date.now() - lastMoveAt;
      if (moving && stuckMs > 30000 && Date.now() - lastUnstickAt > 30000) {
        lastUnstickAt = Date.now();
        consecutiveUnsticks += 1;
        const radius = Math.min(3 + consecutiveUnsticks * 10, 60);
        const up = Math.min(3 + consecutiveUnsticks * 5, 30);
        log(`stuck for ${Math.round(stuckMs / 1000)}s (attempt ${consecutiveUnsticks}), nudging ${radius} blocks out and ${up} up`);
        try {
          const dx = (Math.random() * radius * 2 - radius).toFixed(1);
          const dz = (Math.random() * radius * 2 - radius).toFixed(1);
          await rcon(`tp ${bot.username} ~${dx} ~${up} ~${dz}`);
        } catch (e) {
          log(`unstick nudge failed: ${e}`);
        }
      }
    }, 10000);

    const directiveTimer = setInterval(async () => {
      const directive = loadDirective();
      if (!directive || directive.type !== 'stay_near' || !directive.player) {
        if (directiveMode) {
          log('directive cleared, resuming own judgement');
          directiveMode = null;
          directivePlayer = null;
          lastApproachPos = null;
          lastApproachAt = null;
          bot.pathfinder.setGoal(null);
        }
        return;
      }

      const target = bot.players[directive.player] && bot.players[directive.player].entity;
      if (target) {
        if (directiveMode === 'follow' && directivePlayer === directive.player) return;
        directiveMode = 'follow';
        directivePlayer = directive.player;
        log(`directive: ${directive.player} is in range now, following directly`);
        bot.pathfinder.setGoal(new goals.GoalFollow(target, 3), true);
        return;
      }

      // Not loaded client-side -- too far for mineflayer to know where they
      // are. RCON works at any distance, so use that to get a heading. Don't
      // re-target on every small wobble in their position, or pathfinding
      // over a long distance never gets a chance to actually make progress
      // before being cancelled and recomputed from scratch.
      const pos = await fetchPlayerPosViaRcon(directive.player);
      if (!pos) return; // couldn't check this cycle; leave the existing goal running
      const alreadyApproaching = directiveMode === 'approach' && directivePlayer === directive.player;
      const movedFar = !lastApproachPos || Math.hypot(pos.x - lastApproachPos.x, pos.z - lastApproachPos.z) > 150;
      const staleEnough = !lastApproachAt || Date.now() - lastApproachAt > 30000;
      if (alreadyApproaching && !(movedFar && staleEnough)) return;
      directiveMode = 'approach';
      directivePlayer = directive.player;
      lastApproachPos = pos;
      lastApproachAt = Date.now();
      log(`directive: heading toward ${directive.player} at ${Math.round(pos.x)},${Math.round(pos.z)} (too far to see directly)`);
      bot.pathfinder.setGoal(new goals.GoalXZ(pos.x, pos.z));
    }, DIRECTIVE_POLL_MS);

    let sessionTimer = null;
    if (SESSION_MINUTES > 0) {
      sessionTimer = setTimeout(() => {
        clearInterval(idleTimer);
        clearInterval(heartbeatTimer);
        clearInterval(directiveTimer);
        farewellAndQuit(bot, recentChat, 'session timer elapsed');
      }, SESSION_MINUTES * 60 * 1000);
    }

    const shutdown = (signal) => {
      clearInterval(idleTimer);
      clearInterval(heartbeatTimer);
      clearInterval(directiveTimer);
      if (sessionTimer) clearTimeout(sessionTimer);
      farewellAndQuit(bot, recentChat, `received ${signal}`);
    };
    process.once('SIGTERM', () => shutdown('SIGTERM'));
    process.once('SIGINT', () => shutdown('SIGINT'));
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

  bot.on('kicked', (reason) => log(`kicked: ${typeof reason === 'string' ? reason : JSON.stringify(reason)}`));
  bot.on('error', (err) => log(`error: ${err}`));
  // 'partial' fires on every physics tick while actively pathing (way too
  // noisy to log); 'noPath' is worth knowing about -- it means pathfinder
  // gave up entirely, e.g. genuinely boxed in.
  bot.on('path_update', (r) => { if (r.status === 'noPath') log(`path_update: noPath (explored ${r.path.length} nodes)`); });
  bot.on('end', () => {
    log('disconnected');
    process.exit(0);
  });
}

main();
