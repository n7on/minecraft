# Opens the floor shaft down to the treasure vault built in build/vault.mcfunction
fill -7066 37 -1599 -7066 37 -1599 air
particle minecraft:totem_of_undying -7066 32 -1599 0.5 3 0.5 0.3 100 force
playsound minecraft:block.vault.open_shutter master @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] -7066 37 -1599 1 1
playsound minecraft:entity.wither.break_block master @a[x=-7114,y=20,z=-1647,dx=96,dy=50,dz=96] -7066 37 -1599 1 0.5
