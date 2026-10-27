# Applied to each player caught in an El Jefe aura
effect give @s minecraft:slowness 8 1
effect give @s minecraft:weakness 8 0
effect give @s minecraft:glowing 8 0
title @s actionbar {"text":"El Jefe har kommit...","color":"gold","bold":true}
execute at @s run particle minecraft:angry_villager ~ ~2 ~ 0.3 0.2 0.3 0 5
