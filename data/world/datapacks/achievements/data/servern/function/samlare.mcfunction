# Samlare: count how many flowers from Flower Extinction this player has collected
scoreboard players set @s servern.flowers 0
execute if entity @s[advancements={servern:flower_extinction={dandelion=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={golden_dandelion=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={open_eyeblossom=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={closed_eyeblossom=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={poppy=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={blue_orchid=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={allium=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={azure_bluet=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={red_tulip=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={orange_tulip=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={white_tulip=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={pink_tulip=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={oxeye_daisy=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={cornflower=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={lily_of_the_valley=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={wither_rose=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={torchflower=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={sunflower=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={lilac=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={peony=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={rose_bush=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={pitcher_plant=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={pink_petals=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={wildflowers=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={cactus_flower=true}}] run scoreboard players add @s servern.flowers 1
execute if entity @s[advancements={servern:flower_extinction={spore_blossom=true}}] run scoreboard players add @s servern.flowers 1
execute if score @s servern.flowers matches 5.. run advancement grant @s only servern:samlare
