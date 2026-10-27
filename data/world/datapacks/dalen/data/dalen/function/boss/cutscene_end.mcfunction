execute as @a[tag=dalen.cutscene] run gamemode survival
tag @a remove dalen.cutscene
kill @e[tag=dalen_cam1]
kill @e[tag=dalen_cam2]
kill @e[tag=dalen_cam3]
function dalen:boss/spawn_actual
