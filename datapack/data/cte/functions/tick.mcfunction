scoreboard players add @e[nbt={Tags:["gf_animation_player","playing"]}] animFrames 1
execute as @e[nbt={Tags:["gf_animation_player","test_animation1","playing"]}] at @s run function cte:frames/test_animation1/_play_frames
execute as @e[nbt={Tags:["gf_animation_player","test_animation2","playing"]}] at @s run function cte:frames/test_animation2/_play_frames
execute as @e[nbt={Tags:["gf_animation_player","test_animation3","playing"]}] at @s run function cte:frames/test_animation3/_play_frames
