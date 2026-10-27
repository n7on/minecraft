# Every second while the boss is awake
bossbar set dalen:boss players @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96]
tag @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96,gamemode=!spectator,gamemode=!creative] add dalen.deltagare
execute store result bossbar dalen:boss value run data get entity @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] Health
# Boss gone without being killed by a player (e.g. /kill): reset so it can be fought later
execute unless entity @e[type=minecraft:illusioner,tag=dalen_boss] run return run function dalen:boss/reset
# Everyone left for 60 s: put it back to sleep at full health
execute unless entity @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96,gamemode=!spectator] run scoreboard players add #empty dalen.state 1
execute if entity @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96,gamemode=!spectator] run scoreboard players set #empty dalen.state 0
execute if score #empty dalen.state matches 60.. run return run function dalen:boss/reset
scoreboard players add #timer dalen.state 1
# Phase thresholds: phase2 at 66% hp, phase3 at 33% hp (integer-safe: health*3 vs hp*2 / hp*1)
execute store result score #h dalen.tmp run data get entity @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] Health
scoreboard players operation #h66 dalen.tmp = #h dalen.tmp
scoreboard players operation #h66 dalen.tmp *= #3 dalen.const
scoreboard players operation #thresh66 dalen.tmp = #hp dalen.tmp
scoreboard players operation #thresh66 dalen.tmp *= #2 dalen.const
execute if score #phase2 dalen.state matches 0 if score #h66 dalen.tmp <= #thresh66 dalen.tmp run function dalen:boss/phase2
scoreboard players operation #h33 dalen.tmp = #h dalen.tmp
scoreboard players operation #h33 dalen.tmp *= #3 dalen.const
execute if score #phase3 dalen.state matches 0 if score #h33 dalen.tmp <= #hp dalen.tmp run function dalen:boss/phase3
# Attacks -- cadence quickens each phase
scoreboard players operation #t dalen.tmp = #timer dalen.state
scoreboard players operation #t dalen.tmp %= #6 dalen.const
execute if score #t dalen.tmp matches 0 run function dalen:boss/frostblick
scoreboard players operation #t dalen.tmp = #timer dalen.state
scoreboard players operation #t dalen.tmp %= #9 dalen.const
execute if score #t dalen.tmp matches 0 run function dalen:boss/hostvind
scoreboard players operation #t dalen.tmp = #timer dalen.state
execute if score #phase3 dalen.state matches 1 run scoreboard players operation #t dalen.tmp %= #6 dalen.const
execute unless score #phase3 dalen.state matches 1 if score #phase2 dalen.state matches 1 run scoreboard players operation #t dalen.tmp %= #8 dalen.const
execute if score #phase2 dalen.state matches 0 run scoreboard players operation #t dalen.tmp %= #14 dalen.const
execute if score #t dalen.tmp matches 0 run function dalen:boss/sjalar
execute as @e[type=minecraft:illusioner,tag=dalen_boss,limit=1] at @s run particle minecraft:orange_poplar_leaves ~ ~2 ~ 1.2 1.5 1.2 0.02 6
