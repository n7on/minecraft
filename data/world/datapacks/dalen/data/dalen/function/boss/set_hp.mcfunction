$attribute @s minecraft:max_health base set $(hp)
$data modify entity @s Health set value $(hp).0f
$bossbar set dalen:boss max $(hp)
