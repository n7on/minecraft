# Travel stats (cm) summed each second; distance only counts toward Ride or Die while a friend is within 64 blocks
scoreboard objectives add servern.m_walk minecraft.custom:minecraft.walk_one_cm
scoreboard objectives add servern.m_sprint minecraft.custom:minecraft.sprint_one_cm
scoreboard objectives add servern.m_crouch minecraft.custom:minecraft.crouch_one_cm
scoreboard objectives add servern.m_swim minecraft.custom:minecraft.swim_one_cm
scoreboard objectives add servern.m_aviate minecraft.custom:minecraft.aviate_one_cm
scoreboard objectives add servern.m_boat minecraft.custom:minecraft.boat_one_cm
scoreboard objectives add servern.m_horse minecraft.custom:minecraft.horse_one_cm
scoreboard objectives add servern.m_minecart minecraft.custom:minecraft.minecart_one_cm
scoreboard objectives add servern.m_happy_ghast minecraft.custom:minecraft.happy_ghast_one_cm
scoreboard objectives add servern.m_walk_on_water minecraft.custom:minecraft.walk_on_water_one_cm
scoreboard objectives add servern.m_walk_under_water minecraft.custom:minecraft.walk_under_water_one_cm
scoreboard objectives add servern.m_climb minecraft.custom:minecraft.climb_one_cm
scoreboard objectives add servern.total dummy
scoreboard objectives add servern.last dummy
scoreboard objectives add servern.buddy dummy
scoreboard objectives remove servern.play
# Touch Grass: ticks online since last join; reset whenever the player has left the game
scoreboard objectives add servern.session dummy
scoreboard objectives add servern.left minecraft.custom:minecraft.leave_game
# Warden counter: wardens woken within a 5 minute window (timer in ticks)
scoreboard objectives add servern.wcount dummy
scoreboard objectives add servern.wtimer dummy
scoreboard objectives add servern.tmp dummy
scoreboard objectives add servern.pid dummy
scoreboard objectives add servern.lastkill dummy
scoreboard objectives add servern.nemesis dummy
scoreboard objectives add servern.rtimer dummy
# Moein-mode: deaths since the window started (window = 24h of server ticks)
scoreboard objectives add servern.deaths deathCount
scoreboard objectives add servern.dlast dummy
scoreboard objectives add servern.dday dummy
scoreboard objectives add servern.dstart dummy
# Ensam varg: ticks alone on the server
scoreboard objectives add servern.alone dummy
scoreboard objectives add servern.flowers dummy
schedule function servern:second 20t replace
