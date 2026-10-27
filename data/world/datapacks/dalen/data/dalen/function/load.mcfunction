scoreboard objectives add dalen.state dummy
scoreboard objectives add dalen.tmp dummy
scoreboard objectives add dalen.const dummy
scoreboard objectives add dalen.hp dummy
scoreboard objectives add dalen.maxhp dummy
scoreboard objectives add dalen.natcd dummy
scoreboard objectives add dalen.age dummy
scoreboard players set #2 dalen.const 2
scoreboard players set #3 dalen.const 3
scoreboard players set #6 dalen.const 6
scoreboard players set #8 dalen.const 8
scoreboard players set #9 dalen.const 9
scoreboard players set #14 dalen.const 14
execute unless score #active dalen.state matches 0.. run scoreboard players set #active dalen.state 0
execute unless score #spawning dalen.state matches 0.. run scoreboard players set #spawning dalen.state 0
bossbar add dalen:boss {"text":"Den Glömde","color":"gold","bold":true}
bossbar set dalen:boss color red
bossbar set dalen:boss style notched_10
schedule function dalen:second 20t replace
