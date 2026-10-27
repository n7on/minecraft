# Wake the boss. HP scales with the number of players in the arena.
# #spawning (not #active yet) guards the cutscene window: tick.mcfunction
# would otherwise see no boss entity yet and immediately reset things.
forceload add -7114 -1647 -7018 -1551
scoreboard players set #spawning dalen.state 1
scoreboard players set #timer dalen.state 0
scoreboard players set #empty dalen.state 0
scoreboard players set #phase2 dalen.state 0
scoreboard players set #phase3 dalen.state 0
execute store result score #n dalen.tmp if entity @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96,gamemode=!spectator,gamemode=!creative]
scoreboard players set #hp dalen.tmp 150
scoreboard players operation #hp dalen.tmp *= #n dalen.tmp
scoreboard players add #hp dalen.tmp 500
function dalen:boss/cutscene_intro
