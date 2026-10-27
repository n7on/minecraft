# Runs as the killer, before the victim's reward: remember when this player last killed someone
advancement revoke @s only servern:_killed_player
execute store result score @s servern.lastkill run time query gametime
