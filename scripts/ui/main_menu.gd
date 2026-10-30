extends Control
class_name MainMenu

@onready var _home: VBoxContainer = $Margin/Layout/Center/MenuPanel/Content/Home
@onready var _mode_choices: VBoxContainer = $Margin/Layout/Center/MenuPanel/Content/ModeChoices

var _run_manager: RunProgress


func _ready() -> void:
	get_tree().paused = false
	_run_manager = get_node("/root/RunManager") as RunProgress
	_run_manager.return_to_menu()
	$Margin/Layout/Center/MenuPanel/Content/Home/Play.pressed.connect(_show_modes)
	$Margin/Layout/Center/MenuPanel/Content/ModeChoices/Adventure.pressed.connect(_start_mode.bind(RunProgress.GameMode.ADVENTURE))
	$Margin/Layout/Center/MenuPanel/Content/ModeChoices/Endless.pressed.connect(_start_mode.bind(RunProgress.GameMode.ENDLESS))
	$Margin/Layout/Center/MenuPanel/Content/ModeChoices/Back.pressed.connect(_show_home)
	_show_home()


func _show_modes() -> void:
	_home.visible = false
	_mode_choices.visible = true


func _show_home() -> void:
	_mode_choices.visible = false
	_home.visible = true


func _start_mode(mode: RunProgress.GameMode) -> void:
	_run_manager.select_mode(mode)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
