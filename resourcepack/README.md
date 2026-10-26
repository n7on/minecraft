# Server resource pack

Textures for the items added by the `cartel` datapack (data/world/datapacks/cartel).
Each item is a vanilla item tagged with `custom_model_data`; the pack swaps in the
custom texture and falls back to the vanilla look for anything else, so players
without the pack just see the normal item.

- `draw.py` draws the 16x16 PNGs: `python3 draw.py src/assets/cartel/textures/item`
- Rebuild the zip from `src/`: `cd src && zip -qr -X ../kartell-texturer.zip pack.mcmeta assets`
- After changing the zip, update `RESOURCE_PACK_SHA1` in docker-compose.yml (`sha1sum kartell-texturer.zip`).

The leaf blockstates, models and textures are from Better Leaves by Motschen (MIT, see
`src/LICENSE-better-leaves.txt`, https://modrinth.com/resourcepack/better-leaves); only the vanilla
`minecraft` namespace is included. The base copy is Better Leaves 9.4 (for 1.21.x clients, which the
server still accepts through ViaBackwards); the `bl_26` overlay holds 9.6 and is applied only by
26.x clients (resource format 84+).
