# Runs "as" the boss. Bigger wave: 4 melee + 1 ranged.
summon minecraft:vindicator ~4 ~1 ~3 {Tags:["dalen_minion"],CustomName:{"text":"Glömd krigare","color":"gray"},equipment:{mainhand:{id:"minecraft:iron_axe"}}}
summon minecraft:vindicator ~-4 ~1 ~3 {Tags:["dalen_minion"],CustomName:{"text":"Glömd krigare","color":"gray"},equipment:{mainhand:{id:"minecraft:iron_axe"}}}
summon minecraft:vindicator ~4 ~1 ~-3 {Tags:["dalen_minion"],CustomName:{"text":"Glömd krigare","color":"gray"},equipment:{mainhand:{id:"minecraft:iron_axe"}}}
summon minecraft:vindicator ~-4 ~1 ~-3 {Tags:["dalen_minion"],CustomName:{"text":"Glömd krigare","color":"gray"},equipment:{mainhand:{id:"minecraft:iron_axe"}}}
summon minecraft:pillager ~0 ~1 ~5 {Tags:["dalen_minion"],CustomName:{"text":"Glömd bågskytt","color":"gray"},equipment:{mainhand:{id:"minecraft:crossbow"}}}
playsound minecraft:entity.vindicator.celebrate hostile @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] ~ ~ ~ 1 1.0
