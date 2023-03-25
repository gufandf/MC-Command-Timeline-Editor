extends WindowDialog


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal addAnim(animName,pos)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_posSelect_item_selected(index):
	changeButton()

func _on_NameSpace_text_changed(new_text):
	changeButton()


func changeButton():
	if $posSelect.get_selected_id() == 0:
		$X.editable = false
		$Y.editable = false
		$Z.editable = false
	else:
		$X.editable = true
		$Y.editable = true
		$Z.editable = true
	if $posSelect.get_selected_id() == 0:
		pass
	elif $posSelect.get_selected_id() == 1:
		$X.prefix = "~"
		$Y.prefix = "~"
		$Z.prefix = "~"
	elif $posSelect.get_selected_id() == 2:
		$X.prefix = ""
		$Y.prefix = ""
		$Z.prefix = ""
	if $NameSpace.text == "" or $posSelect.get_selected_id() == 0:
		$confirm.disabled = true
	else:
		$confirm.disabled = false

func _on_confirm_pressed():
	var animName = $NameSpace.text
	var posX = $X.prefix+str($X.value)
	var posY = $Y.prefix+str($Y.value)
	var posZ = $Z.prefix+str($Z.value)
	var pos = {
		"x":posX,
		"y":posY,
		"z":posZ
	}
	emit_signal("addAnim", animName, pos)
	
	self.hide()
	$NameSpace.text = ""
	$posSelect.select(0)
	$X.value = 0
	$Y.value = 0
	$Z.value = 0
	changeButton()



