# Telegram control bot

Lets you administer the Minecraft server by chatting with a Telegram bot.
Each message is forwarded to `claude -p` running in the project directory, so
it can edit `docker-compose.yml`, run `docker compose`/`git` commands, read
logs, etc. Uses your existing Claude Code login — no separate API key needed.

**Safety model:** `bot-settings.json` allow-lists routine `docker`/`git`
commands. Anything not allow-listed (and a short explicit deny-list of
destructive ops: `docker compose down`, volume/image prune, force-push,
`reset --hard`, etc.) is auto-denied with no prompt — there's no human at a
terminal to ask. When that happens, the bot relays what was blocked and asks
you to reply `yes`/`no` in the chat; `yes` resumes the same conversation with
permissions bypassed for just that one action.

## Setup

1. **Create the bot:** message **@BotFather** on Telegram, send `/newbot`,
   follow the prompts. Copy the token it gives you.
2. **Get your Telegram user ID:** message **@userinfobot**, it replies with
   your numeric ID.
3. **Configure:**
   ```sh
   cp .env.example .env
   # edit .env: set BOT_TOKEN and ALLOWED_USER_IDS
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

## Files

- `bot.py` — the bot (stdlib only, no pip install needed)
- `bot-settings.json` — Claude Code permission allow/deny list used for every
  invocation
- `minecraft-telegram-bot.service` — systemd unit template
- `.env` — secrets (gitignored; copy from `.env.example`)
- `state.json`, `bot.log` — runtime state and audit log (gitignored)
