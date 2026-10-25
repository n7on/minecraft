# Server resource pack

Textures for the items added by the `cartel` datapack (data/world/datapacks/cartel).
Each item is a vanilla item tagged with `custom_model_data`; the pack swaps in the
custom texture and falls back to the vanilla look for anything else, so players
without the pack just see the normal item.

- `draw.py` draws the 16x16 PNGs: `python3 draw.py src/assets/cartel/textures/item`
- Rebuild the zip from `src/`: `cd src && zip -qr -X ../kartell-texturer.zip pack.mcmeta assets`
- After changing the zip, update `RESOURCE_PACK_SHA1` in docker-compose.yml (`sha1sum kartell-texturer.zip`).
