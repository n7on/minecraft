# Runs as a happy ghast: two or more players riding it get the taxi advancement
tag @a remove servern.rider
execute on passengers if entity @s[type=minecraft:player] run tag @s add servern.rider
execute store result score #riders servern.tmp if entity @a[tag=servern.rider]
execute if score #riders servern.tmp matches 2.. run advancement grant @a[tag=servern.rider] only servern:ghast_taxi
tag @a remove servern.rider
