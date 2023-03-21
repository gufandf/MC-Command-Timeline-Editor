extends Control

onready var MenuButtonFile = $topbar/MenuButtonFile
onready var openDatapack = $openDatapack

onready var animList = $workspace/HSplitContainer/list/animList/ItemList
onready var frameList = $workspace/HSplitContainer/list/frameList/ItemList
onready var textEdit = $workspace/HSplitContainer/TextEdit

onready var addAnim = $addAnim
onready var addAnimNameSpace = $addAnim/NameSpace
onready var addFrame = $addFrame
onready var addFrameTime = $addFrame/Time
onready var addFrameButton = $workspace/HSplitContainer/list/frameList/addFrame
onready var deleFrameButton = $workspace/HSplitContainer/list/frameList/deleFrame

var root = ""
var FuncRoot = ""

var selecedAnim = ""
var selecedFrame = ""

var allAnimData = {}

#settings
var autoSave = false

func _ready():
	MenuButtonFile.get_popup().connect("id_pressed",self,"_file_id_pressed")
	$AcceptDialog.popup()
	#loadData("G:/Godot/testmcdatapack2/pack.mcmeta")
	#loadAnimList()

# 菜单栏
# file
func _file_id_pressed(id):
	if id == 0:
		openDatapack.popup()
	if id == 1:
		if root != "":
			saveData()
# 设置
func _on_settings_pressed():
	$settings.popup()
# 关于
func _on_about_pressed():
	$about.popup()

# 读取数据包
func _on_openDatapack_file_selected(path):
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
	var mineload = '{"replace": false,"values": ["cte:load"]}'
	var minetick = '{"replace": false,"values": ["cte:tick"]}'
	writeFile(root+"/data/minecraft/tags/functions/load.json",mineload)
	writeFile(root+"/data/minecraft/tags/functions/tick.json",minetick)
	createDir(playRoot)
	createDir(framesRoot)
	for animPath in scan(playRoot):
		var animName = animPath.get_basename().get_file()
		allAnimData[animName] = {}
		print("\n"+framesRoot+"/"+animName+"/_play_frames.mcfunction")
		print("发现动画:",animName)
		var file = readFile(framesRoot+"/"+animName+"/_play_frames.mcfunction")
		for codeLine in file.split("\n",false):
			var frameName = codeLine.split("/",false)[-1]
			if not "kill" in frameName:
				print("\t包含帧:",frameName)
				var frameData = readFile(framesRoot+"/"+animName+"/"+frameName+".mcfunction")
				allAnimData[animName][frameName] = frameData
	print(allAnimData)
	loadAnimList()

func saveData():
	var lastFrameName
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
		# tick
		tickmc += 'execute as @e[nbt={Tags:["gf_animation_player","%s","playing"]}] at @s run function cte:frames/%s/_play_frames\n' % [animName,animName]
		# /play/animName
		writeFile(playRoot+"/"+animName+".mcfunction",'summon marker ~ ~ ~ {Tags:["gf_animation_player","%s","playing"]}' % animName)
		# /frames/animName/_play_frames
		var _play_frames = ""
		for frameName in allAnimData[animName]:
			lastFrameName = frameName
			createDir(framesRoot+"/"+animName)
			_play_frames += 'execute if entity @s[scores={animFrames=%s}] run function cte:frames/%s/%s\n' % [frameName.trim_prefix("frame"),animName,frameName]
			writeFile(framesRoot+"/"+animName+"/"+frameName+".mcfunction",allAnimData[animName][frameName])
		_play_frames += 'execute if entity @s[scores={animFrames=%s}] run kill @s' % lastFrameName.trim_prefix("frame")
		writeFile(framesRoot+"/"+animName+"/_play_frames.mcfunction",_play_frames)
	writeFile(FuncRoot+"/"+"tick.mcfunction",tickmc)

func loadAnimList():
	animList.clear()
	selecedAnim = ""
	selecedFrame = ""
	addFrameButton.disabled = true
	deleFrameButton.disabled = true
	for animName in allAnimData:
		animList.add_item(animName)
	loadFrameList()
func loadFrameList():
	frameList.clear()
	if selecedAnim != "":
		for FrameName in allAnimData[selecedAnim]:
			frameList.add_item(FrameName)
func loadFrame():
	var command = allAnimData[selecedAnim][selecedFrame]
	textEdit.text = command

# 选择动画与帧
func _on_animList_selected(index):
	selecedAnim = animList.get_item_text(index)
	loadFrameList()
	textEdit.text = ""
	textEdit.readonly = true
	addFrameButton.disabled = false
	deleFrameButton.disabled = false
	print("选中动画:"+selecedAnim)

func _on_frameList_selected(index):
	selecedFrame = frameList.get_item_text(index)
	loadFrame()
	textEdit.readonly = false
	print("选中帧:"+selecedFrame)

# 编辑
func _on_TextEdit_text_changed():
	var command = textEdit.text
	allAnimData[selecedAnim][selecedFrame] = command

# 删除动画
func _on_deleAnim_pressed():
	if selecedAnim != "":
		$ConfirmationDeleAnim.popup()
		$ConfirmationDeleAnim.dialog_text = "确定删除动画 %s 吗？" % selecedAnim
func _on_ConfirmationDeleAnim_confirmed():
	allAnimData.erase(selecedAnim)
	loadAnimList()
# 添加动画
func _on_addAnim_pressed():
	addAnim.popup()
func _on_addAnim_confirm_pressed():
	var animName = addAnimNameSpace.text
	if animName != "":
		allAnimData[animName] = {}
		loadAnimList()
		addAnim.hide()
		addAnimNameSpace.text = ""
# 删除帧
func _on_deleFrame_pressed():
	if selecedFrame != "":
		$ConfirmationDeleFrame.popup()
		$ConfirmationDeleFrame.dialog_text = "确定删除帧 %s 吗？" % selecedFrame
func _on_ConfirmationDeleFrame_confirmed():
	if selecedAnim != "" and selecedFrame != "":
		allAnimData[selecedAnim].erase(selecedFrame)
		selecedFrame = ""
		textEdit.text = ""
		textEdit.readonly = true
	loadFrameList()
# 添加帧
func _on_addFrame_pressed():
	addFrame.popup()
func _on_addFrame_confirm_pressed():
	var frameTime = addFrameTime.value
	allAnimData[selecedAnim]["frame"+str(frameTime)] = ""
	addFrame.hide()
	loadFrameList()


func _on_autoSave_toggled(button_pressed):
	autoSave = button_pressed

func _on_autoSave_timeout():
	if root != "" and autoSave:
		saveData()
		print("自动保存...")

func _on_autoSaveTime_value_changed(value):
	$autoSaveTimer.wait_time = value



