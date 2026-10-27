# Victim of Frost Aspect: frozen solid for 1.2 s (slowness X), weakened, takes a little frost damage
particle minecraft:snowflake ~ ~1 ~ 0.3 0.6 0.3 0.02 40 force
particle minecraft:block{block_state:"minecraft:ice"} ~ ~1 ~ 0.3 0.6 0.3 0 25 force
playsound minecraft:block.glass.break player @a ~ ~ ~ 0.6 1.6
playsound minecraft:entity.player.hurt_freeze player @a ~ ~ ~ 1 1
damage @s 3 minecraft:freeze
