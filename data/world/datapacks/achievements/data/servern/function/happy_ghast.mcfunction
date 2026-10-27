# Ridden happy ghasts fly twice as fast; the boost is dropped as soon as nobody rides them
execute as @e[type=minecraft:happy_ghast] run attribute @s minecraft:flying_speed modifier remove servern:ride_boost
execute as @e[type=minecraft:happy_ghast] on passengers if entity @s[type=minecraft:player] on vehicle run attribute @s minecraft:flying_speed modifier add servern:ride_boost 1.0 add_multiplied_base
