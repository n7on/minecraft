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

## Usage

```sh
docker compose up -d      # start (pulls/updates plugins, applies anti-xray patches)
docker compose stop minecraft && docker compose up -d   # apply docker-compose.yml changes
docker exec -it minecraft rcon-cli                      # console access
```

Whitelist/ops are managed in-game (`/whitelist add <name>`, `/op <name>`) or
via the `OPS` env var in `docker-compose.yml` for the initial admin.
