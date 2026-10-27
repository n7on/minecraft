# Runs as the freshly summoned boss
execute store result storage dalen:boss hp int 1 run scoreboard players get #hp dalen.tmp
function dalen:boss/set_hp with storage dalen:boss
attribute @s minecraft:scale base set 1.8
attribute @s minecraft:armor base set 12
attribute @s minecraft:knockback_resistance base set 0.7
attribute @s minecraft:follow_range base set 40
attribute @s minecraft:movement_speed base set 0.4
