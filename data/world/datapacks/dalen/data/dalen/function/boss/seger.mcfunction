# The boss was killed by a player. Repeatable: it just goes back to sleep
# and can be woken again later (see second.mcfunction).
advancement revoke @s only dalen:_boss_killed
scoreboard players set #active dalen.state 0
tag @s add dalen.deltagare
kill @e[type=minecraft:vex,tag=dalen_sjal]
kill @e[tag=dalen_minion]
bossbar set dalen:boss visible false
bossbar remove dalen:boss
# A short death shot: lock participants' view on the boss's position as it falls
summon minecraft:armor_stand -7066 44 -1603 {Tags:["dalen_camd"],Marker:1b,Invisible:1b,NoGravity:1b,Rotation:[0f,15f]}
execute as @a[tag=dalen.deltagare,gamemode=survival] run gamemode spectator
execute as @a[tag=dalen.deltagare] run spectate @e[tag=dalen_camd,limit=1,sort=nearest] @s
title @a[tag=dalen.deltagare] times 0 30 10
title @a[tag=dalen.deltagare] subtitle {"text":"Den Glömde faller...","color":"red","italic":true}
execute positioned -7066 42 -1599 run particle minecraft:totem_of_undying ~ ~ ~ 3 3 3 0.4 500 force
schedule function dalen:boss/seger_rewards 40t
