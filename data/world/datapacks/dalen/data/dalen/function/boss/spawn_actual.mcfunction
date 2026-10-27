# The actual boss summon + wake flourish, run at the end of the intro cutscene
scoreboard players set #active dalen.state 1
scoreboard players set #spawning dalen.state 0
summon minecraft:illusioner -7066 41 -1599 {Tags:["dalen_boss"],PersistenceRequired:1b,CustomName:{"text":"Den Glömde","color":"gold","bold":true},CustomNameVisible:1b,equipment:{mainhand:{id:"minecraft:bow",components:{"minecraft:enchantments":{"minecraft:power":3,"minecraft:punch":1}}}},drop_chances:{mainhand:0.0f}}
execute as @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] run function dalen:boss/setup
bossbar set dalen:boss visible true
title @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] times 10 60 20
title @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] subtitle {"text":"Allt som glömts har vaknat...","color":"gray","italic":true}
title @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] title {"text":"Den Glömde","color":"gold","bold":true}
playsound minecraft:entity.wither.spawn hostile @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] -7066 40 -1599 1 0.7
execute positioned -7066 42 -1599 run particle minecraft:orange_poplar_leaves ~ ~ ~ 4 3 4 0.05 400 force
