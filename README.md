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
- `wanderer-bot/` — a cryptic NPC, played by Claude, that joins the server as
  a real player for a session and then leaves. See below, and
  `wanderer-bot/README.md` for setup.
- `custom-plugins/` — real compiled Paper plugins for anything a datapack
  can't do (custom commands, GUIs, persistent data). See
  `custom-plugins/README.md`.

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
your Telegram user ID if you should have access. Most people get a read-only
tier: they can ask it questions but it has no ability to change or restart
anything for them.

Its main job is changing how the server is configured — it edits
`docker-compose.yml`, commits the change, and applies it. For example:

- "add the Dynmap plugin"
- "increase memory to 6G, we're getting lag with everyone on"
- "set view distance to 12"
- "change the MOTD to 'back up, survival world reset this weekend'"
- "add someone to the whitelist: their username is X"
- "disable anti-xray in the nether, it's not needed there"

It can also just check in on things ("how's the server doing? any errors in
the logs?") or restart it to apply a change.

Routine stuff (checking status/logs, restarting, editing config, whitelist)
happens immediately. Anything destructive or hard to undo — stopping the
stack, removing data, force-pushing — makes the bot stop and ask for
confirmation before doing it. Send `/new` to start a fresh conversation with
it.

## Wanderer bot

A separate character, also played by Claude, that joins the server itself as
a whitelisted player — not through chat, in-world. It's a cryptic wanderer:
speaks rarely, in riddles, keeps to itself, and only sticks around for one
session before leaving. The one rule it never breaks: if it promises you
something in chat, it will follow through. See `wanderer-bot/README.md`.
