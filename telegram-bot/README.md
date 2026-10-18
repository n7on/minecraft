# Telegram control bot

Lets you administer the Minecraft server by chatting with a Telegram bot.
Each message is forwarded to `claude -p` running in the project directory, so
it can edit `docker-compose.yml`, run `docker compose`/`git` commands, read
logs, etc. Uses your existing Claude Code login — no separate API key needed.

**Two access tiers**, set via Telegram user ID:

- `ALLOWED_USER_IDS` — full control. `bot-settings.json` allows any shell
  command, except a short explicit deny-list of destructive ops (`docker
  compose down`, volume/image prune, force-push, `reset --hard`, etc.), which
  is auto-denied with no prompt — there's no human at a terminal to ask. When
  that happens, the bot relays what was blocked and asks you to reply
  `yes`/`no` in the chat; `yes` resumes the same conversation with
  permissions bypassed for just that one action. Note the deny-list is a
  prefix match on the command string, so it can in principle be bypassed by
  chaining (`docker compose up -d && docker compose down -v` doesn't match
  the `docker compose down*` pattern since the string starts with `up`).
  That's an accepted tradeoff for this tier — it's for trusted admins, not a
  hard boundary — unlike the read-only tier below, which has no such gap.
- `READONLY_USER_IDS` — information only. Runs with no shell/edit/write
  tools at all (`--tools Read,Glob,Grep`), so nothing they say can change
  anything, full stop. This is deliberately *not* done via a narrow
  allow-list of "safe" shell commands — permission patterns are a prefix
  match on the whole command string, so e.g. an allow-list for `echo *`
  still lets `echo hi && whoami` run. Dropping the tools entirely avoids
  that class of bypass.

## Setup

1. **Create the bot:** message **@BotFather** on Telegram, send `/newbot`,
   follow the prompts. Copy the token it gives you.
2. **Get your Telegram user ID:** message **@userinfobot**, it replies with
   your numeric ID.
3. **Configure:**
   ```sh
   cp .env.example .env
   # edit .env: set BOT_TOKEN, ALLOWED_USER_IDS, and (optionally) READONLY_USER_IDS
   ```
4. **Install the systemd service:**
   ```sh
   sudo cp minecraft-telegram-bot.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable --now minecraft-telegram-bot
   sudo systemctl status minecraft-telegram-bot
   journalctl -u minecraft-telegram-bot -f   # watch logs
   ```

## Usage

Message your bot on Telegram. Examples:
- "how's the server doing, any errors in the logs?"
- "add a plugin for X" / "bump view distance to 12"
- "restart the server to apply changes"
- "take the server down for maintenance" → will ask for confirmation

Send `/new` to start a fresh conversation (drops prior context for that chat).

Read-only users (`READONLY_USER_IDS`) get the same bot, just answering from
file access only — e.g. "is the server up?", "what plugins are installed?",
"how do I join?". Asking it to change or restart anything gets a plain "I
don't have permission for that, ask an admin."

## Files

- `bot.py` — the bot (stdlib only, no pip install needed)
- `bot-settings.json` — Claude Code permission allow/deny list used for every
  invocation
- `minecraft-telegram-bot.service` — systemd unit template
- `.env` — secrets (gitignored; copy from `.env.example`)
- `state.json`, `bot.log` — runtime state and audit log (gitignored)
