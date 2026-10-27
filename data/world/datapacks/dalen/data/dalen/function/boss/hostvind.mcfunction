# Höstvind: a gust of leaves throws everyone in the arena into the air
execute as @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] at @s run particle minecraft:orange_poplar_leaves ~ ~1 ~ 6 1 6 0.3 300 force
playsound minecraft:entity.breeze.wind_burst hostile @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] -7066 40 -1599 1 0.8
effect give @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96,gamemode=!spectator,gamemode=!creative] minecraft:levitation 1 3
effect give @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96,gamemode=!spectator,gamemode=!creative] minecraft:slow_falling 3 0
