execute unless score @s servern.wtimer matches 1.. run scoreboard players set @s servern.wcount 0
execute unless score @s servern.wtimer matches 1.. run scoreboard players set @s servern.wtimer 6000
scoreboard players add @s servern.wcount 1
execute if score @s servern.wcount matches 4.. run advancement grant @s only servern:warden_bubble
