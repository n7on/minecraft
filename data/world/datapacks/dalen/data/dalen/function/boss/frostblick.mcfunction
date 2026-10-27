# Frostblick: the nearest player is slowed and covered in frost
execute as @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] at @s as @p[distance=..24,gamemode=!spectator,gamemode=!creative] at @s run function dalen:boss/frost_target
