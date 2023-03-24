scoreboard players add @e[nbt={Tags:["gf_animation_player","playing"]}] animFrames 1
execute as @e[nbt={Tags:["gf_animation_player","test","playing"]}] at @s run function cte:frames/test/_play_frames
