extends Control

var selAnim = ""
var selFrame = 1
var selMaxFrame = 1
var rootPath = ""
var allAnimData = {}
var NameToSpace={}
var debugData = {}
var settings = {
	"autoSave":false,
	"debugMode":false
}

@onready var debugText = $logsWindow/debugText
@onready var animList = $HSplitContainer/anims/list
@onready var code = $HSplitContainer/edit/code
@onready var info = $HSplitContainer/edit/info

func _ready():
	$fileWindow.show()
	$editWindow.show()
	$addAnim.show()
	flashAnimList()
	addLog("CTE 启动成功")

func _process(delta):
	debugData["rootPath"] = rootPath
	debugData["selAnim"] = selAnim
	debugData["selFrame"] = selFrame
	debugData["selMaxFrame"] = selMaxFrame
	debugData["allAnimData"] = allAnimData
	debugData["settings"] = settings
	
	#debugText.text = "根目录: "+rootPath+"\n选择的动画: "+selAnim+"\n选择的帧: "+JSON.stringify(selFrame)+"\n动画时长: "+JSON.stringify(selMaxFrame)+"\ndeBugMode: "+JSON.stringify(debugMode)+"\n"+JSON.stringify(allAnimData,"\t")
	debugText.text = JSON.stringify(debugData,"\t")
	
	info.text = ""
	if settings["debugMode"]:
		info.text += "  调试模式: 开"
	else :
		info.text += "  调试模式: 关"
	if settings["autoSave"]:
		info.text += "  自动保存: 开"
	else :
		info.text += "  自动保存: 关"
	info.text += "  CTE 1.0"
	#调整启用和禁用
	if rootPath == "":
		$HSplitContainer/anims/addButton.disabled = true
	else:
		$HSplitContainer/anims/addButton.disabled = false
	
	if selAnim == "":
		frameSlider.editable = false
		frameMaxCount.editable = false
		frameCount.editable = false
		code.editable = false
		$HSplitContainer/anims/removeButton.disabled = true
		setFrameCount(1)
		setMaxFrameCount(1)
	else:
		frameSlider.editable = true
		frameMaxCount.editable = true
		frameCount.editable = true
		code.editable = true
		$HSplitContainer/anims/removeButton.disabled = false
	
	if $addAnim/name.text == "" or $addAnim/nameSpace.text == "":
		$addAnim/add.disabled = true
	else:
		$addAnim/add.disabled = false

#func _input(event):
#	if event is InputEventMouseMotion:
#		if $drag.button_pressed:
#			get_window().position = event.relative*1.1 + Vector2(get_window().position)
#			print("Mouse Motion at: ", event.relative)


################################################################################
#滑动选帧条
@onready var frameSlider = $HSplitContainer/edit/frameSlider
@onready var frameMaxCount = $HSplitContainer/edit/frameMaxCount
@onready var frameCount = $HSplitContainer/edit/frameCount
#修改函数
func setFrameCount(value:float):
	frameSlider.value = value
	frameCount.value = value
func setMaxFrameCount(maxValue:float):
	frameSlider.max_value = maxValue
	frameCount.max_value = maxValue
	frameMaxCount.value = maxValue
	if not selAnim == "":
		allAnimData[selAnim]["lengh"] = maxValue
#修改选择帧
func _on_resentSlider_value_changed(value):
	selFrame = value
	setFrameCount(value)
	flashFrame()
func _on_frameCount_value_changed(value):
	selFrame = value
	setFrameCount(value)
#修改帧的最大值
func _on_frameMaxCount_value_changed(value):
	selMaxFrame = value
	setMaxFrameCount(value)
################################################################################
#加载和保存
func loadData(path:String):
	addLog("加载: "+path)
	allAnimData = {}
	rootPath = path
	var jsonFilePath = rootPath+"/cte.json"
	if FileAccess.file_exists(jsonFilePath):
		var fileData = readFile(jsonFilePath)
		allAnimData = JSON.parse_string(fileData)
	else:
		writeFile(jsonFilePath,"{}")
	flashAnimList()
	addLog("加载完成: "+path)
func saveData():
	if rootPath == "":
		addLog("你还没有打开文件")
	else:
		writeFile(rootPath+"/cte.json",JSON.stringify(allAnimData,"\t"))
		creatDir(rootPath+"/data")
		creatDir(rootPath+"/data/cte")
		creatDir(rootPath+"/data/cte/functions")
		creatDir(rootPath+"/data/cte/functions/_play")
		creatDir(rootPath+"/data/cte/functions/frames")
		var funcPath = rootPath+"/data/cte/functions"
		
		var tickData = 'scoreboard players add @e[nbt={Tags:["gf_animation_player","playing"]}] animFrames 1\n'
		for nameSpace in allAnimData:
			tickData += 'execute as @e[nbt={Tags:["gf_animation_player","{nameSpace}","playing"]}] at @s run function cte:frames/{nameSpace}/_play_frames\n'.format({"nameSpace":nameSpace})
			var _playData = 'summon marker ~0 ~0 ~0 {Tags:["gf_animation_player","{nameSpace}","playing"]}\n'.format({"nameSpace":nameSpace})
			writeFile(funcPath+"/_play/{nameSpace}.mcfunction".format({"nameSpace":nameSpace}),_playData)
			creatDir(funcPath+"/frames/"+nameSpace)
			var _playFrames = ""
			for frameNum in allAnimData[nameSpace]["frames"]:
				_playFrames += 'execute if entity @s[scores={animFrames={frameNum}}] run function cte:frames/{nameSpace}/{frameNum}\n'.format({"frameNum":frameNum,"nameSpace":nameSpace})
				var frameData = allAnimData[nameSpace]["frames"][frameNum]
				if settings["debugMode"]:
					frameData += '\ntellraw @a [{"text":"[调试]正在播放 {nameSpace} 中的第 {frameNum} 帧","color":"yellow"}]'.format({"frameNum":frameNum,"nameSpace":nameSpace})
				writeFile(funcPath+"/frames/{nameSpace}/{frameNum}.mcfunction".format({"frameNum":frameNum,"nameSpace":nameSpace}),frameData)
			_playFrames += 'execute if entity @s[scores={animFrames={lengh}}] run kill @s\n'.format({"lengh":allAnimData[nameSpace]["lengh"],"nameSpace":nameSpace})
			writeFile(funcPath+"/frames/{nameSpace}/_play_frames.mcfunction".format({"nameSpace":nameSpace}),_playFrames)
		writeFile(funcPath+"/tick.mcfunction",tickData)
		writeFile(funcPath+"/load.mcfunction","scoreboard objectives add animFrames dummy\n")

# 读取写入文件
func readFile(filePath:String) -> String:
	if FileAccess.file_exists(filePath):
		var fileData = FileAccess.open(filePath, FileAccess.READ)
		return fileData.get_as_text()
	else :
		addLog("文件不存在: "+filePath)
		return ""
func writeFile(filePath:String,context:String):
	var file = FileAccess.open(filePath, FileAccess.WRITE)
	file.store_string(context)
func creatDir(path):
	DirAccess.make_dir_absolute(path)
# 添加删除动画
func _on_add_anim_button_pressed():
	$addAnim/name.text = ""
	$addAnim/nameSpace.text = ""
	animPlayer.play("addAnimWindowPopup")
func _on_cancel_add_anim_button_pressed():
	animPlayer.play("addAnimWindowPopdown")
func _on_accept_add_anim_button_pressed():
	var name = $addAnim/name.text
	var nameSpace = $addAnim/nameSpace.text
	if nameSpace in allAnimData:
		addLog("nameSpace已存在: "+nameSpace)
	elif name in NameToSpace:
		addLog("name已存在: "+name)
	else:
		allAnimData[nameSpace] = {}
		allAnimData[nameSpace]["name"] = name
		allAnimData[nameSpace]["lengh"] = 20
		allAnimData[nameSpace]["frames"] = {}
		animPlayer.play("addAnimWindowPopdown")
		addLog("新建动画: "+name)
	flashAnimList()
func _on_remove_anim_button_pressed():
	if not selAnim == "":
		$ConfirmationDialog.popup_centered()
		addLog("请确认删除动画: "+allAnimData[selAnim]["name"])
func _on_remove_anim_button_confirm():
	var name = allAnimData[selAnim]["name"]
	allAnimData.erase(selAnim)
	flashAnimList()
	addLog("已删除动画: "+name)
#设置选中的动画
func _on_animList_item_selected(index):
	var animName = animList.get_item_text(index)
	selAnim = NameToSpace[animName]
	frameMaxCount.value = allAnimData[selAnim]["lengh"]
	addLog("选择动画 {name}".format({"name":animName}))
	flashFrame()
#刷新UI
func flashAnimList():
	selAnim = ""
	setFrameCount(1)
	setMaxFrameCount(1)
	code.text = ""
	animList.clear()
	for i in allAnimData:
		NameToSpace[allAnimData[i]["name"]] = i
		animList.add_item(allAnimData[i]["name"])
	flashFrame()
func flashFrame():
	if selAnim == "":
		code.text = ""
	else:
		if str(selFrame) in allAnimData[selAnim]["frames"]:
			code.text = allAnimData[selAnim]["frames"][str(selFrame)]
		else :
			code.text = ""
#设置帧内容
func _on_code_text_changed():
	allAnimData[selAnim]["frames"][str(selFrame)] = code.text
	#addLog("编辑动画 {name} 帧 {frame}".format({"name":allAnimData[selAnim]["name"],"frame":str(selFrame)}))

#文件菜单按下
@onready var fileWindow = $fileWindow
@onready var animTree = $AnimationTree
@onready var animPlayer = $AnimationPlayer
func _on_file_pressed():
	animPlayer.play("fileWindowPopup")
func _on_fileClose_pressed():
	animPlayer.play("fileWindowPopdown")
func _on_save_file_pressed():
	animPlayer.play("fileWindowPopdown")
	saveData()
	addLog("保存完成: "+rootPath)
func _on_edit_pressed():
	animPlayer.play("editWindowPopup")
func _on_editClose_pressed():
	animPlayer.play("editWindowPopdown")
func _on_logs_pressed():
	animPlayer.play("logsWindowPopup")
func _on_logsClose_pressed():
	animPlayer.play("logsWindowPopdown")

func _on_debug_mode_toggled(button_pressed):
	settings["debugMode"] = button_pressed
	if button_pressed:
		$editWindow/debugMode.text = "禁用调试模式"
		addLog("启用调试模式")
	else:
		$editWindow/debugMode.text = "启用调试模式"
		addLog("禁用调试模式")
	animPlayer.play("editWindowPopdown")
func _on_auto_save_toggled(button_pressed):
	settings["autoSave"] = button_pressed
	if button_pressed:
		$editWindow/autoSave.text = "禁用自动保存"
		addLog("启用自动保存")
	else:
		$editWindow/autoSave.text = "启用自动保存"
		addLog("禁用自动保存")
	animPlayer.play("editWindowPopdown")
func _on_quit_pressed():
	addLog("退出")
	get_tree().quit()
func _on_open_file_pressed():
	animPlayer.play("fileWindowPopdown")
	$FileDialog.popup_centered()
#自动保存
func _on_timer_timeout():
	if settings["autoSave"]:
		saveData()
# 窗口
func _on_file_dialog_dir_selected(dir):
	loadData(dir)
func addLog(text):
	var time = Time.get_time_string_from_system()
	$logsWindow/log.add_text("[{time}]{text}\n".format({"time":time,"text":text}))



