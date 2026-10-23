# Wanderer bot

A cryptic NPC that joins the server as a real (whitelisted) player for one
session, wanders, speaks in riddles, and leaves. Built on
[mineflayer](https://github.com/PrismarineJS/mineflayer) for movement/world
interaction; Claude (via the `claude` CLI, same login as the Telegram bot --
no separate API key) decides what to say and do.

**How it decides things:** each decision is a single, fresh, stateless call
to `claude -p` with no tools and no growing conversation -- just a compact
snapshot (position, health, nearby players, inventory, outstanding promises,
recent chat) and a JSON-schema-constrained response (`say` + `action`). This
is deliberately cheap (~$0.04/decision in testing) and keeps behavior
reactive rather than looping expensively like the admin bot sometimes does.

**The one hard rule:** if it promises something in chat, it must keep that
promise. Promises are tracked in `promises.json` and fed back into every
decision until fulfilled.

## Setup

1. **Get a Minecraft Java account for it.** Any account that owns Java
   Edition works -- it doesn't need to be special, just a real one.
2. **Whitelist it:** in-game `/whitelist add <its-username>`, or via the
   Telegram bot.
3. **Configure:**
   ```sh
   cp .env.example .env
   # edit .env: set MC_USERNAME to the account's email/Microsoft username
   ```
4. **First run / authorize:** run it once manually --
   ```sh
   set -a; source .env; set +a
   node index.js
   ```
   The first time, it'll print a Microsoft device-code URL + code (same flow
   as the `gh`/Telegram logins) -- open it, approve, and it caches the token
   under `.auth-cache/` so future runs don't need this again.

## Running a session

```sh
set -a; source .env; set +a
node index.js
```

It joins, runs for `SESSION_MINUTES`, says a farewell, and disconnects. Stop
early any time with Ctrl-C (or `kill` if backgrounded).

## Files

- `index.js` — the bot
- `promises.json` — outstanding/fulfilled promises (gitignored, created on
  first use)
- `.auth-cache/` — cached Microsoft login token (gitignored, sensitive --
  don't share it, it's equivalent to being logged into that account)
- `bot.log` — decision/action log (gitignored)

## Not yet done

Summoning it currently means running `node index.js` by hand. Wiring it up
so the admin Telegram bot can start/stop a session on request is a natural
next step once this is confirmed to work and the cost/vibe feel right.
