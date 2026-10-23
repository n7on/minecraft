# Wanderer bot

A cryptic NPC that joins the server as a real (whitelisted) player, speaks in
riddles, and stays near whoever it's watching for. Built on
[mineflayer](https://github.com/PrismarineJS/mineflayer) for movement/world
interaction; Claude (via the `claude` CLI, same login as the Telegram bot --
no separate API key) decides what to say and do.

**Presence:** `watch.sh` is a tiny always-on supervisor (no LLM calls, just an
RCON poll every `POLL_SECONDS`) that starts the bot when `TARGET_PLAYER` is
online and stops it when they leave. While running, it writes
`directive.json` telling the bot to actively stay near that player (rather
than wander off on its own) -- it still talks/acts in character, it's just
guaranteed to be nearby. If they're far enough away that mineflayer can't
see their entity yet, it uses RCON to get their real position and heads
that way (re-targeting only every 30s+/150+ blocks moved, so a long walk
actually gets a chance to progress instead of being recomputed from scratch
on every wobble); once close enough, it switches to following them directly.

**How it decides things:** each decision is a single, fresh, stateless call
to `claude -p` with no tools and no growing conversation -- just a compact
snapshot (position, health, nearby players, inventory, outstanding promises,
recent chat) and a JSON-schema-constrained response (`say` + `action`). This
is deliberately cheap (~$0.02-0.04/decision in testing) and keeps behavior
reactive rather than looping expensively like the admin bot sometimes does.

**The one hard rule:** if it promises something in chat, it must keep that
promise. Promises are tracked in `promises.json` and fed back into every
decision until fulfilled.

**Known quirk:** the server's actual vanilla spawn point turned out to be
unwalkable for the bot -- pathfinder could only find ~10 reachable tiles
there with no way out (root cause not fully pinned down; possibly
spawn-protection, possibly the terrain itself). It now teleports to a known-
good nearby spot (`SAFE_SPAWN_ANCHOR` in `index.js`) immediately on join. If
that spot ever stops working (world changes, etc.), pathfinder will report
`noPath` in `bot.log` and it'll need a new anchor -- pick any spot you can
confirm is normal open terrain. It also never digs or places blocks at all
(fits the character, and avoids fighting spawn-protection anywhere else).

## Setup

1. **Get a Minecraft Java account for it.** Any account that owns Java
   Edition works -- it doesn't need to be special, just a real one.
2. **Whitelist it:** in-game `/whitelist add <its-username>`, or via the
   Telegram bot.
3. **Configure:**
   ```sh
   cp .env.example .env
   # edit .env: MC_USERNAME (the bot account), TARGET_PLAYER (who to follow)
   ```
4. **First run / authorize:** run it once manually --
   ```sh
   set -a; source .env; set +a
   node index.js
   ```
   The first time, it'll print a Microsoft device-code URL + code (same flow
   as the `gh`/Telegram logins) -- open it, approve, and it caches the token
   under `.auth-cache/` so future runs don't need this again. Ctrl-C to stop.

## Running

Normally, just run the watcher and leave it running (a systemd service like
`telegram-bot`'s is the natural way to do that, not yet set up):

```sh
set -a; source .env; set +a
./watch.sh
```

It'll start/stop `index.js` on its own as `TARGET_PLAYER` comes and goes.

For a one-off manual session instead (ignoring `TARGET_PLAYER`), run
`node index.js` directly as in step 4 above; set `SESSION_MINUTES` if you
want it to leave on its own after a while, otherwise stop it with Ctrl-C.

## Files

- `index.js` — the bot
- `watch.sh` — the presence supervisor
- `promises.json` — outstanding/fulfilled promises (gitignored, created on
  first use)
- `directive.json` — current "stay near this player" instruction, written by
  `watch.sh` (gitignored, runtime state)
- `.auth-cache/` — cached Microsoft login token (gitignored, sensitive --
  don't share it, it's equivalent to being logged into that account)
- `bot.log` — decision/action log (gitignored)

## Not yet done

No systemd unit for `watch.sh` yet (so it doesn't survive a reboot on its
own), and the Telegram admin bot has no hook into this one yet (e.g. to
nudge its behavior or point it at a different player on request).
