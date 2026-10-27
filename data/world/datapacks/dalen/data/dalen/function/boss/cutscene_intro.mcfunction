# 3-shot intro cutscene using /spectate to lock players' cameras onto marker
# entities placed around the new arena, then hands off to spawn_actual.
summon minecraft:armor_stand -7066 46 -1556 {Tags:["dalen_cam1"],Marker:1b,Invisible:1b,NoGravity:1b,Rotation:[180f,25f]}
summon minecraft:armor_stand -7066 75 -1599 {Tags:["dalen_cam2"],Marker:1b,Invisible:1b,NoGravity:1b,Rotation:[0f,90f]}
summon minecraft:armor_stand -7070 43 -1603 {Tags:["dalen_cam3"],Marker:1b,Invisible:1b,NoGravity:1b,Rotation:[135f,5f]}
tag @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96,gamemode=survival] add dalen.cutscene
execute as @a[tag=dalen.cutscene] run gamemode spectator
execute as @a[tag=dalen.cutscene] run spectate @e[tag=dalen_cam1,limit=1,sort=nearest] @s
title @a[tag=dalen.cutscene] times 0 40 10
title @a[tag=dalen.cutscene] subtitle {"text":"Något rör sig i dalen...","color":"gray","italic":true}
schedule function dalen:boss/cutscene_shot2 40t
