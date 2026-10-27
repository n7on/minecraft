# A sealed treasure vault beneath the arena floor. Run once (like colosseum).
# Normally sealed by the block at the shaft bottom; dalen:boss/reveal_vault
# clears it and the shaft to let players down after the boss dies.
fill -7072 26 -1605 -7060 31 -1593 minecraft:deepslate_bricks
fill -7071 27 -1604 -7061 30 -1594 air
fill -7071 27 -1604 -7061 27 -1594 minecraft:deepslate_tiles
fill -7068 28 -1601 -7064 28 -1597 minecraft:sea_lantern
setblock -7069 28 -1602 minecraft:chest[facing=south]{LootTable:"dalen:chests/skatt"}
setblock -7067 28 -1602 minecraft:chest[facing=south]{LootTable:"dalen:chests/skatt"}
setblock -7065 28 -1602 minecraft:chest[facing=south]{LootTable:"dalen:chests/skatt"}
setblock -7069 28 -1596 minecraft:chest[facing=north]{LootTable:"dalen:chests/skatt"}
setblock -7067 28 -1596 minecraft:chest[facing=north]{LootTable:"dalen:chests/skatt"}
setblock -7065 28 -1596 minecraft:chest[facing=north]{LootTable:"dalen:chests/skatt"}
# Shaft from the arena floor down to the vault, sealed until the boss dies
fill -7067 29 -1599 -7065 36 -1599 air
setblock -7066 29 -1599 minecraft:ladder[facing=south]
fill -7066 37 -1599 -7066 37 -1599 minecraft:polished_deepslate
