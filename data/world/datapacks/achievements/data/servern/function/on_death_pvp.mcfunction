# Runs as the victim. The killer is the player whose lastkill is this tick.
advancement revoke @s only servern:_died_to_player
execute store result score #now servern.tmp run time query gametime
tag @s add servern.victim
execute as @a[tag=!servern.victim] if score @s servern.lastkill = #now servern.tmp run tag @s add servern.killer
# Revenge: the killer's nemesis is this victim and the killer's timer is still running
execute as @a[tag=servern.killer,scores={servern.rtimer=1..}] if score @s servern.nemesis = @a[tag=servern.victim,limit=1] servern.pid run advancement grant @s only servern:hamnd
# The victim now has 5 minutes to take revenge on the killer
scoreboard players operation @s servern.nemesis = @a[tag=servern.killer,limit=1] servern.pid
execute if entity @a[tag=servern.killer] run scoreboard players set @s servern.rtimer 6000
tag @a remove servern.killer
tag @s remove servern.victim
