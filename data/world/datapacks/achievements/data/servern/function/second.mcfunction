function servern:happy_ghast
execute as @e[type=minecraft:warden,tag=!servern.seen] at @s run function servern:warden_new
execute as @e[type=minecraft:happy_ghast] run function servern:hg_taxi
execute store result score #now servern.tmp run time query gametime
execute store result score #online servern.tmp if entity @a
execute as @a run function servern:player
schedule function servern:second 20t replace
