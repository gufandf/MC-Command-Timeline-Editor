extends Control


var tickRegex = RegEx.new()
var code = "execute if entity @s[scores={animFrames=12131}] run function cte:frames/test_anim/frame1"

func _ready():
	tickRegex.compile("animFrames=[0-9]{1,}")
	print(tickRegex.search(code).get_string().split("=")[1])
