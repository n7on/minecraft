# Runs "as" the boss, so ~ ~ ~ is relative to it. 3 minions.
summon minecraft:vindicator ~3 ~1 ~2 {Tags:["dalen_minion"],CustomName:{"text":"Glömd krigare","color":"gray"},equipment:{mainhand:{id:"minecraft:iron_axe"}}}
summon minecraft:vindicator ~-3 ~1 ~2 {Tags:["dalen_minion"],CustomName:{"text":"Glömd krigare","color":"gray"},equipment:{mainhand:{id:"minecraft:iron_axe"}}}
summon minecraft:vindicator ~0 ~1 ~-3 {Tags:["dalen_minion"],CustomName:{"text":"Glömd krigare","color":"gray"},equipment:{mainhand:{id:"minecraft:iron_axe"}}}
playsound minecraft:entity.vindicator.celebrate hostile @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] ~ ~ ~ 1 0.8
