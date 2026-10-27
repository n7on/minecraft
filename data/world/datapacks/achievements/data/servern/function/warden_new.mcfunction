# A warden that hasn't been counted yet: credit the nearest player who woke it
tag @s add servern.seen
execute as @p[distance=..48,gamemode=!spectator,gamemode=!creative] run function servern:warden_credit
