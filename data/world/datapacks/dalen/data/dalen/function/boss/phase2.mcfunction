scoreboard players set #phase2 dalen.state 1
effect give @e[type=minecraft:illusioner,tag=dalen_boss] minecraft:speed infinite 0
title @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] actionbar {"text":"Den Glömde blir rasande!","color":"red","bold":true}
playsound minecraft:entity.illusioner.cast_spell hostile @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] -7066 40 -1599 1 0.5
execute as @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] at @s run function dalen:boss/minion_wave_2
