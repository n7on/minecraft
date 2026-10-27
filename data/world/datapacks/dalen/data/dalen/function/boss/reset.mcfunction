kill @e[type=minecraft:illusioner,tag=dalen_boss]
kill @e[type=minecraft:vex,tag=dalen_sjal]
kill @e[tag=dalen_minion]
bossbar set dalen:boss visible false
bossbar set dalen:boss players
tag @a remove dalen.deltagare
scoreboard players set #active dalen.state 0
scoreboard players set #spawning dalen.state 0
scoreboard players set #phase2 dalen.state 0
scoreboard players set #phase3 dalen.state 0
forceload remove -7114 -1647 -7018 -1551
