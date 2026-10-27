# Victim of Spindelnät: a cobweb appears at their feet once they are at or below half health (5 s cooldown)
execute if score @s dalen.natcd matches 1.. run return 0
execute store result score @s dalen.hp run data get entity @s Health 100
execute store result score @s dalen.maxhp run attribute @s minecraft:max_health get 100
scoreboard players operation @s dalen.hp *= #2 dalen.const
execute if score @s dalen.hp > @s dalen.maxhp run return 0
execute if block ~ ~ ~ #minecraft:air run summon minecraft:marker ~ ~ ~ {Tags:["dalen_nat"]}
setblock ~ ~ ~ minecraft:cobweb keep
scoreboard players set @s dalen.natcd 100
