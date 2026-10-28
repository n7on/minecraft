# El Jefe aura: runs as the player who ate it. Nearby players get weakened and lit up.
advancement revoke @s only cartel:eljefe
tag @s add cartel.jefe
execute at @s run particle minecraft:totem_of_undying ~ ~1 ~ 0.5 1 0.5 0.8 250 force
execute at @s run particle minecraft:explosion_emitter ~ ~1 ~ 0 0 0 0 1 force
execute at @s run playsound minecraft:entity.generic.explode player @a ~ ~ ~ 0.8 1.2
execute at @s run playsound minecraft:item.totem.use player @a ~ ~ ~ 1 1
execute at @s as @a[distance=..12,tag=!cartel.jefe,gamemode=!spectator] run function cartel:eljefe_hit
tag @s remove cartel.jefe
