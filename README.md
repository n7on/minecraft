# minecraft

Paper Minecraft server for my son and his friends, running via
[itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server).
Java (port 25565) and Bedrock via Geyser/Floodgate (UDP 19132) are both supported.

## Layout

- `docker-compose.yml` — the whole setup: server version/resources, plugins
  (EssentialsX, ViaVersion, Geyser, Floodgate), access control, and Paper
  anti-xray/anti-duping settings.
- `data/` — runtime state (world saves, server jar, plugin jars, logs, cache,
  whitelist/ops/bans). Not tracked in git: it's large, mostly regenerated on
  start, and contains player data. Back it up separately if you want world
  save backups.
- `telegram-bot/` — a Telegram bot that lets admins manage the server by just
  chatting with it. See below, and `telegram-bot/README.md` for setup.

## Usage

```sh
docker compose up -d      # start (pulls/updates plugins, applies anti-xray patches)
docker compose stop minecraft && docker compose up -d   # apply docker-compose.yml changes
docker exec -it minecraft rcon-cli                      # console access
```

Whitelist/ops are managed in-game (`/whitelist add <name>`, `/op <name>`) or
via the `OPS` env var in `docker-compose.yml` for the initial admin.

## Telegram bot

The server can also be managed by chatting with **[@aarons_minecraft_server_bot](https://t.me/aarons_minecraft_server_bot)**
on Telegram. It's an AI agent (Claude) with real access to this repo and the
Docker host, so you talk to it in plain English rather than typing commands.

Only specific Telegram accounts are allowed to use it — ask an admin to add
your Telegram user ID if you should have access.

Example things you can say to it:

- "how's the server doing? any errors in the logs?"
- "restart the server"
- "add someone to the whitelist: their username is X"
- "bump view distance to 12 and apply it"
- "take the server down for maintenance"

Routine stuff (checking status/logs, restarting, editing config, whitelist)
happens immediately. Anything destructive or hard to undo — stopping the
stack, removing data, force-pushing — makes the bot stop and ask for
confirmation before doing it. Send `/new` to start a fresh conversation with
it.
