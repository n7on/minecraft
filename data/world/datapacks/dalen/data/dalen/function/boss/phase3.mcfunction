scoreboard players set #phase3 dalen.state 1
effect give @e[type=minecraft:illusioner,tag=dalen_boss] minecraft:strength infinite 1
effect give @e[type=minecraft:illusioner,tag=dalen_boss] minecraft:speed infinite 1
effect give @e[type=minecraft:illusioner,tag=dalen_boss] minecraft:resistance infinite 0
title @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] times 5 40 10
title @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] subtitle {"text":"Allt det glömda reser sig med honom","color":"red","italic":true}
title @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] title {"text":"Den Glömde Vaknar Helt","color":"dark_red","bold":true}
playsound minecraft:entity.wither.ambient hostile @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] -7066 40 -1599 1 0.6
execute as @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] at @s run function dalen:boss/minion_wave_3
