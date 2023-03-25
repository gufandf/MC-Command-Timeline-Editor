extends WindowDialog


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal addFrame(frameName,tick,command)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_NameSpace_text_changed(new_text):
	changeButton()

func changeButton():
	if $NameSpace.text == "":
		$confirm.disabled = true
	else:
		$confirm.disabled = false

func _on_confirm_pressed():
	if $NameSpace.text != "":
		emit_signal("addFrame",$NameSpace.text,$Time.value,"")
		self.hide()


