schedule function dalen:second 20t replace
# Spindelnät: cobwebs disappear after 4 seconds, cooldowns tick down
scoreboard players add @e[type=minecraft:marker,tag=dalen_nat] dalen.age 1
execute as @e[type=minecraft:marker,tag=dalen_nat,scores={dalen.age=4..}] at @s run fill ~ ~ ~ ~ ~ ~ minecraft:air replace minecraft:cobweb
kill @e[type=minecraft:marker,tag=dalen_nat,scores={dalen.age=4..}]
scoreboard players remove @e[scores={dalen.natcd=1..}] dalen.natcd 20
# Boss fight (repeatable -- wakes again whenever someone's in the arena and it's not already active)
execute if score #active dalen.state matches 0 if score #spawning dalen.state matches 0 if entity @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96,gamemode=!spectator,gamemode=!creative] run function dalen:boss/spawn
execute if score #active dalen.state matches 1 run function dalen:boss/tick
