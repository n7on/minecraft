# Glömda själar: short-lived vexes
execute as @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] at @s run summon minecraft:vex ~1 ~2 ~ {Tags:["dalen_sjal"],life_ticks:400,CustomName:{"text":"Glömd själ","color":"gray"}}
execute as @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] at @s run summon minecraft:vex ~-1 ~2 ~ {Tags:["dalen_sjal"],life_ticks:400,CustomName:{"text":"Glömd själ","color":"gray"}}
execute as @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] at @s run playsound minecraft:entity.evoker.prepare_summon hostile @a ~ ~ ~ 1 0.8
