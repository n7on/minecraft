scoreboard players set @s servern.total 0
scoreboard players operation @s servern.total += @s servern.m_walk
scoreboard players operation @s servern.total += @s servern.m_sprint
scoreboard players operation @s servern.total += @s servern.m_crouch
scoreboard players operation @s servern.total += @s servern.m_swim
scoreboard players operation @s servern.total += @s servern.m_aviate
scoreboard players operation @s servern.total += @s servern.m_boat
scoreboard players operation @s servern.total += @s servern.m_horse
scoreboard players operation @s servern.total += @s servern.m_minecart
scoreboard players operation @s servern.total += @s servern.m_happy_ghast
scoreboard players operation @s servern.total += @s servern.m_walk_on_water
scoreboard players operation @s servern.total += @s servern.m_walk_under_water
scoreboard players operation @s servern.total += @s servern.m_climb
# First run for this player: start counting from now
execute unless score @s servern.last = @s servern.last run scoreboard players operation @s servern.last = @s servern.total
scoreboard players operation @s servern.total -= @s servern.last
execute at @s if entity @a[distance=0.1..64,gamemode=!spectator] run scoreboard players operation @s servern.buddy += @s servern.total
scoreboard players operation @s servern.last += @s servern.total
execute if score @s servern.buddy matches 1000000.. run advancement grant @s only servern:ride_or_die
execute if score @s servern.left matches 1.. run scoreboard players set @s servern.session 0
execute if score @s servern.left matches 1.. run scoreboard players set @s servern.alone 0
scoreboard players set @s servern.left 0
scoreboard players add @s servern.session 20
execute if score @s servern.session matches 72000.. run advancement grant @s only servern:nykomling
# 8 hours in a row = 576000 ticks
execute if score @s servern.session matches 576000.. run advancement grant @s only servern:touch_grass
execute if score @s servern.wtimer matches 1.. run scoreboard players remove @s servern.wtimer 20
execute unless score @s servern.pid matches 1.. run function servern:assign_pid
execute if score @s servern.rtimer matches 1.. run scoreboard players remove @s servern.rtimer 20
# Ensam varg: 3 hours = 216000 ticks
execute if score #online servern.tmp matches 1 run scoreboard players add @s servern.alone 20
execute unless score #online servern.tmp matches 1 run scoreboard players set @s servern.alone 0
execute if score @s servern.alone matches 216000.. run advancement grant @s only servern:ensam_varg
# Moein-mode: count new deaths; restart the window if it is older than 24h (1728000 ticks)
execute unless score @s servern.dlast = @s servern.dlast run scoreboard players operation @s servern.dlast = @s servern.deaths
scoreboard players operation #d servern.tmp = @s servern.deaths
scoreboard players operation #d servern.tmp -= @s servern.dlast
scoreboard players operation @s servern.dlast = @s servern.deaths
scoreboard players operation #age servern.tmp = #now servern.tmp
scoreboard players operation #age servern.tmp -= @s servern.dstart
execute if score #d servern.tmp matches 1.. if score #age servern.tmp matches 1728000.. run scoreboard players set @s servern.dday 0
execute if score #d servern.tmp matches 1.. unless score @s servern.dday matches 1.. run scoreboard players operation @s servern.dstart = #now servern.tmp
scoreboard players operation @s servern.dday += #d servern.tmp
execute if score @s servern.dday matches 10.. run advancement grant @s only servern:moein_mode
execute unless entity @s[advancements={servern:samlare=true}] run function servern:samlare
