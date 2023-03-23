extends WindowDialog


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal addAnim(animName,posX,posY,posZ,data)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_posSelect_item_selected(index):
	if index == 0:
		$X.editable = false
		$Y.editable = false
		$Z.editable = false
	else:
		$X.editable = true
		$Y.editable = true
		$Z.editable = true
	if index == 0:
		pass
	elif index == 1:
		$X.prefix = "~"
		$Y.prefix = "~"
		$Z.prefix = "~"
	elif index == 2:
		$X.prefix = ""
		$Y.prefix = ""
		$Z.prefix = ""
	changeButton()

func _on_NameSpace_text_changed(new_text):
	changeButton()


func changeButton():
	if $NameSpace.text == "" or $posSelect.get_selected_id() == 0:
		$confirm.disabled = true
	else:
		$confirm.disabled = false

func _on_confirm_pressed():
	var animName = $NameSpace.text
	var posX = str($X.value)
	var posY = str($Y.value)
	var posZ = str($Z.value)
	var pos = {
		"x":posX,
		"y":posY,
		"z":posZ
	}
	emit_signal("addAnim", animName, pos, {})
	
	self.hide()
	$NameSpace.text = ""
	$X.value = 0
	$Y.value = 0
	$Z.value = 0
	changeButton()



