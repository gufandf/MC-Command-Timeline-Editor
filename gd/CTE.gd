extends Control

onready var MenuButtonFile = $topbar/MenuButtonFile
onready var MenuButtonDebug = $topbar/MenuButtonDebug
onready var MenuButtonMenu = $topbar/MenuButtonMenu
onready var openDatapack = $openDatapack

onready var animList = $workspace/HSplitContainer/list/animList/ItemList
onready var frameList = $workspace/HSplitContainer/list/frameList/ItemList
onready var textEdit = $workspace/HSplitContainer/edit/TextEdit

onready var addAnim = $addAnim
onready var addAnimNameSpace = $addAnim/NameSpace
onready var addFrame = $addFrame
onready var addFrameTime = $addFrame/Time
onready var addFrameButton = $workspace/HSplitContainer/list/frameList/addFrame
onready var deleFrameButton = $workspace/HSplitContainer/list/frameList/deleFrame
onready var addAnimButton = $workspace/HSplitContainer/list/animList/addAnim
onready var deleAnimButton = $workspace/HSplitContainer/list/animList/deleAnim
onready var editFrameTick = $workspace/HSplitContainer/list/frameList/frameTick

var root = ""
var FuncRoot = ""

var selecedAnim = ""
var selecedFrame = ""

var allAnimData = {}

var test_allAnimData = {
	"test_animName":{
		"pos":{
			"x":"~",
			"y":"~",
			"z":"~"
		},
		"frames":{
			"test_frameName1":{
				"tick":1,
				"command":""
			}
		}
	}
}

var tickRegex = RegEx.new()
var posRegex = RegEx.new()

#settings
var autoSave = false

func _ready():
	tickRegex.compile("animFrames=[0-9]{1,}")
	posRegex.compile("animFrames=.*？")
	
	MenuButtonMenu.get_popup().connect("id_pressed",self,"_menu_id_pressed")
	MenuButtonFile.get_popup().connect("id_pressed",self,"_file_id_pressed")
	MenuButtonDebug.get_popup().connect("id_pressed",self,"_debug_pressed")
	$AcceptDialog.popup()
	loadAnimList()

# 菜单栏
# 菜单
func _menu_id_pressed(id):
	if id == 0:
		$settings.popup()
	if id == 1:
		$about.popup()

# file
func _file_id_pressed(id):
	if id == 0:
		openDatapack.popup()
	if id == 1:
		if root != "":
			saveData()

## 设置
#func _on_settings_pressed():
#	$settings.popup()
## 关于
#func _on_about_pressed():
#	$about.popup()

# debug
func _debug_pressed(id):
	if id == 0:
		print("allAnimData:",allAnimData)
	elif id == 1:
		print("selecedAnim:",selecedAnim)
		print("selecedFrame:",selecedFrame)

# 读取数据包
func _on_openDatapack_file_selected(path):
	$topbar/MenuButtonFile.get_popup().set_item_disabled(1,false)
	loadData(path)

# 读取文件
func readFile(path:String) -> String:
	var file = File.new()
	if file.file_exists(path):
		file.open(path,File.READ)
		var f = file.get_as_text()
		file.close()
		return f
	else:
		return ""
# 写入
func writeFile(filePath:String,context:String):
	var file = File.new()
	file.open(filePath,File.WRITE)
	file.store_string(context)
	file.close()
# 创建文件夹
func createDir(path:String):
	var dir = Directory.new()
	dir.make_dir(path)
# 遍历文件
func scan(path:String) -> Array:
	var file_name := ""
	var files := []
	var dir := Directory.new()
	if dir.open(path) != OK:
		print("Failed to open:"+path)
	else:
# warning-ignore:return_value_discarded
		dir.list_dir_begin(true)
		file_name = dir.get_next()
		while file_name!="":
			if dir.current_is_dir():
				var sub_path = path+"/"+file_name
				files += scan(sub_path)
			else:
				var name := path+"/"+file_name
				files.push_back(name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return files

# 打开数据包
func loadData(path:String):
	allAnimData.clear()
	addAnimButton.disabled = false
	
	root = path.get_base_dir()
	FuncRoot = root+"/data/cte/functions"
	var playRoot = FuncRoot+"/_play"
	var framesRoot = FuncRoot+"/frames"
	createDir(root+"/data")
	createDir(root+"/data/cte")
	createDir(root+"/data/cte/functions")
	createDir(root+"/data/minecraft")
	createDir(root+"/data/minecraft/tags")
	createDir(root+"/data/minecraft/tags/functions")
	#var mineload = '{"replace": false,"values": ["cte:load"]}'
	#var minetick = '{"replace": false,"values": ["cte:tick"]}'
	#writeFile(root+"/data/minecraft/tags/functions/load.json",mineload)
	#writeFile(root+"/data/minecraft/tags/functions/tick.json",minetick)
	createDir(playRoot)
	createDir(framesRoot)
	
	loadAnimList()
	for animPath in scan(playRoot):
		var animName = animPath.get_basename().get_file()
		var animPathFile = readFile(animPath)
		var animPos = {"x":animPathFile.split(" ")[2],"y":animPathFile.split(" ")[3],"z":animPathFile.split(" ")[4]}
		allAnimData[animName] = {}
		allAnimData[animName]["frames"] = {}
		allAnimData[animName]["pos"] = animPos
		print("\n"+framesRoot+"/"+animName+"/_play_frames.mcfunction")
		print("发现动画:",animName)
		print("\t动画原点:",animPos)
		var file = readFile(framesRoot+"/"+animName+"/_play_frames.mcfunction")
		for codeLine in file.split("\n",false):
			var frameName = codeLine.split("/",false)[-1]
			var tick = tickRegex.search(codeLine).get_string().split("=")[1]
			if not "kill" in frameName:
				var frameData = readFile(framesRoot+"/"+animName+"/"+frameName+".mcfunction")
				allAnimData[animName]["frames"][frameName] = {}
				allAnimData[animName]["frames"][frameName]["tick"] = int(tick)
				allAnimData[animName]["frames"][frameName]["command"] = frameData
				print("\t包含帧:",frameName)
	loadAnimList()


func saveData():
	var lastFrameTime
	var playRoot = FuncRoot+"/_play"
	var framesRoot = FuncRoot+"/frames"
	createDir(playRoot)
	createDir(framesRoot)
	# load
	var loadmc = "scoreboard objectives add animFrames dummy"
	writeFile(FuncRoot+"/load.mcfunction",loadmc)
	# tick 和 /play/animName 和 /frames/animName
	var tickmc = 'scoreboard players add @e[nbt={Tags:["gf_animation_player","playing"]}] animFrames 1\n'
	for animName in allAnimData:
		createDir(framesRoot+"/"+animName)
		# tick
		tickmc += 'execute as @e[nbt={Tags:["gf_animation_player","%s","playing"]}] at @s run function cte:frames/%s/_play_frames\n' % [animName,animName]
		# /play/animName
		writeFile(playRoot+"/"+animName+".mcfunction",'summon marker %s %s %s {Tags:["gf_animation_player","%s","playing"]}' % [allAnimData[animName]["pos"]["x"],allAnimData[animName]["pos"]["y"],allAnimData[animName]["pos"]["z"],animName])
		# /frames/animName/_play_frames
		var _play_frames = ""
		lastFrameTime = 0
		for frameName in allAnimData[animName]["frames"]:
			if lastFrameTime < allAnimData[animName]["frames"][frameName]["tick"]:
				lastFrameTime = allAnimData[animName]["frames"][frameName]["tick"]
			_play_frames += 'execute if entity @s[scores={animFrames=%s}] run function cte:frames/%s/%s\n' % [allAnimData[animName]["frames"][frameName]["tick"],animName,frameName]
			writeFile(framesRoot+"/"+animName+"/"+frameName+".mcfunction",allAnimData[animName]["frames"][frameName]["command"])
		_play_frames += 'execute if entity @s[scores={animFrames=%s}] run kill @s' % lastFrameTime
		writeFile(framesRoot+"/"+animName+"/_play_frames.mcfunction",_play_frames)
	writeFile(FuncRoot+"/"+"tick.mcfunction",tickmc)

# 刷新UI
func loadButton():
	if selecedAnim == "":
		deleAnimButton.disabled = true
		addFrameButton.disabled = true
	else:
		deleAnimButton.disabled = false
		addFrameButton.disabled = false
	if selecedFrame == "":
		textEdit.readonly = true
		editFrameTick.hide()
		deleFrameButton.disabled = true
	else:
		textEdit.readonly = false
		editFrameTick.show()
		deleFrameButton.disabled = false

func loadAnimList():
	selecedAnim = ""
	selecedFrame = ""
	animList.clear()
	loadFrameList()
	loadButton()
	for animName in allAnimData:
		animList.add_item(animName)

func loadFrameList():
	selecedFrame = ""
	textEdit.text = ""
	frameList.clear()
	loadButton()
	if selecedAnim != "":
		for FrameName in allAnimData[selecedAnim]["frames"]:
			frameList.add_item(FrameName)

func loadFrame():
	loadButton()
	var tick = allAnimData[selecedAnim]["frames"][selecedFrame]["tick"]
	var command = allAnimData[selecedAnim]["frames"][selecedFrame]["command"]
	editFrameTick.value = tick
	textEdit.text = command

# 选择动画与帧
func _on_animList_selected(index):
	selecedAnim = animList.get_item_text(index)
	loadFrameList()
	print("选中动画:"+selecedAnim)

func _on_frameList_selected(index):
	selecedFrame = frameList.get_item_text(index)
	loadFrame()
	print("选中帧:"+selecedFrame)

# 编辑
func _on_TextEdit_text_changed():
	var command = textEdit.text
	allAnimData[selecedAnim]["frames"][selecedFrame]["command"] = command

# 自动保存
func _on_autoSave_toggled(button_pressed):
	autoSave = button_pressed
func _on_autoSave_timeout():
	if root != "" and autoSave:
		saveData()
		print("自动保存...")
func _on_autoSaveTime_value_changed(value):
	$autoSaveTimer.wait_time = value

## 函数
# 添加动画
func addAnim(animName:String,pos:Dictionary,frames:Dictionary):
	allAnimData[animName] = {}
	allAnimData[animName]["pos"] = pos
	allAnimData[animName]["frames"] = frames
	loadAnimList()
	print("添加动画:",animName,str(pos),str(frames))
# 删除动画
func deleAnim(animName):
	selecedFrame = ""
	selecedAnim = ""
	allAnimData.erase(animName)
	loadAnimList()
	print("删除动画"+animName)
# 添加帧
func addFrame(animName,frameName,tick,command):
	allAnimData[animName]["frames"][frameName] = {}
	allAnimData[animName]["frames"][frameName]["tick"] = tick
	allAnimData[animName]["frames"][frameName]["command"] = command
	loadFrameList()
	print("添加帧:"+frameName+"\n"+command)
# 删除帧
func deleFrame(animName,frameName):
	allAnimData[animName]["frames"].erase(frameName)
	selecedFrame = ""
	textEdit.text = ""
	loadFrameList()
	print("删除帧"+animName)

## 信号处理
# 添加动画
func _on_addAnim_pressed():
	addAnim.popup()
func _on_addAnim_addAnim(animName,pos):
	addAnim(animName,pos,{})
# 修改动画
func _on_AnimItemList_item_rmb_selected(index,at_position):
	selecedAnim = animList.get_item_text(index)
	loadFrameList()
	print("编辑动画:"+selecedAnim)
	$editAnim/NameSpace.text = selecedAnim
	if "~" in allAnimData[selecedAnim]["pos"]["x"]:
		$editAnim/posSelect.select(1)
	else:
		$editAnim/posSelect.select(2)
	$editAnim/X.editable = true
	$editAnim/Y.editable = true
	$editAnim/Z.editable = true
	$editAnim/X.value = int(allAnimData[selecedAnim]["pos"]["x"].trim_prefix("~"))
	$editAnim/Y.value = int(allAnimData[selecedAnim]["pos"]["y"].trim_prefix("~"))
	$editAnim/Z.value = int(allAnimData[selecedAnim]["pos"]["z"].trim_prefix("~"))
	$editAnim.popup()
func _on_editAnim_editAnim(animName, pos):
	var oldAnimName = selecedAnim
	var newAnimName = animName
	var frames = allAnimData[oldAnimName]["frames"]
	deleAnim(oldAnimName)
	addAnim(newAnimName,pos,frames)
	
# 删除动画
func _on_deleAnim_pressed():
	$ConfirmationDeleAnim.popup()
	$ConfirmationDeleAnim.dialog_text = "确定删除动画 %s 吗？" % selecedAnim
func _on_ConfirmationDeleAnim_confirmed():
	deleAnim(selecedAnim)
# 添加帧
func _on_addFrame_pressed():
	addFrame.popup()
func _on_addFrame_addFrame(frameName, tick, command):
	addFrame(selecedAnim,frameName,tick,command)
# 修改帧tick
func _on_frameTick_value_changed(value):
	allAnimData[selecedAnim]["frames"][selecedFrame]["tick"] = value
	print("修改tick:",value)
# 删除帧
func _on_deleFrame_pressed():
	$ConfirmationDeleFrame.popup()
	$ConfirmationDeleFrame.dialog_text = "确定删除帧 %s 吗？" % selecedFrame
func _on_ConfirmationDeleFrame_confirmed():
	deleFrame(selecedAnim,selecedFrame)






