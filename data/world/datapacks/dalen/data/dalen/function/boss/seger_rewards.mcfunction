# Runs ~2s after seger.mcfunction: restore vision, reveal the vault, give rewards.
execute as @a[tag=dalen.deltagare] run gamemode survival
kill @e[tag=dalen_camd]
function dalen:boss/reveal_vault
minecraft:give @a[tag=dalen.deltagare] minecraft:enchanted_book[minecraft:stored_enchantments={"dalen:frost_aspect":1}]
execute as @a[tag=dalen.deltagare] if predicate dalen:half run minecraft:give @s minecraft:enchanted_book[minecraft:stored_enchantments={"dalen:spindelnat":1}]
advancement grant @a[tag=dalen.deltagare] only servern:dalen_boss
title @a[tag=dalen.deltagare] times 10 80 20
title @a[tag=dalen.deltagare] subtitle {"text":"Det glömda är äntligen ihågkommet","color":"gray","italic":true}
title @a[tag=dalen.deltagare] title {"text":"Den Glömde är besegrad","color":"gold","bold":true}
tellraw @a [{"text":"[Dalen] ","color":"gold"},{"text":"Den Glömde har besegrats! Valvet under arenan har öppnats.","color":"yellow"}]
playsound minecraft:ui.toast.challenge_complete master @a[tag=dalen.deltagare] ~ ~ ~ 1 1
tag @a remove dalen.deltagare
forceload remove -7114 -1647 -7018 -1551
