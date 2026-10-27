execute as @a[tag=dalen.cutscene] run spectate @e[tag=dalen_cam3,limit=1,sort=nearest] @s
title @a[tag=dalen.cutscene] subtitle {"text":"Den Glömde öppnar ögonen","color":"red","italic":true}
schedule function dalen:boss/cutscene_end 50t
