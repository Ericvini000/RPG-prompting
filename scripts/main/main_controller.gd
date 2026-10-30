extends Node2D

const ENDLESS_SESSION: PackedScene = preload("res://scenes/main/endless_session.tscn")
const ADVENTURE_SESSION: PackedScene = preload("res://scenes/main/adventure_session.tscn")

var player: PlayerController
var wave_director: WaveDirector
var adventure_session: AdventureSession
var _run_manager: RunProgress


func _ready() -> void:
	_run_manager = get_node("/root/RunManager") as RunProgress
	_run_manager.reset_run()
	if _run_manager.selected_mode == RunProgress.GameMode.ENDLESS:
		var session: Node2D = ENDLESS_SESSION.instantiate() as Node2D
		$SessionRoot.add_child(session)
		player = session.get_node("Arena01/Player") as PlayerController
		wave_director = session.get_node("WaveDirector") as WaveDirector
		wave_director.arena_completed.connect(_run_manager.complete_initial_waves)
	else:
		adventure_session = ADVENTURE_SESSION.instantiate() as AdventureSession
		$SessionRoot.add_child(adventure_session)
		player = adventure_session.player
		adventure_session.map_loaded.connect(_on_adventure_map_loaded)
	var upgrade_manager: UpgradeManager = $UpgradeManager as UpgradeManager
	var hud: GameHUD = $HUD as GameHUD
	var results: ResultScreen = $ResultScreen as ResultScreen
	upgrade_manager.bind(player, $UpgradeScreen as UpgradeScreen)
	hud.bind(player, wave_director, _run_manager)
	results.bind(_run_manager, player, upgrade_manager, wave_director)
	player.health.died.connect(_run_manager.request_game_over)
	results.restart_requested.connect(_restart_run)
	results.resume_requested.connect(_run_manager.toggle_pause)
	results.main_menu_requested.connect(_return_to_menu)
	$AdventureNotice/Center/Panel/Content/MainMenu.pressed.connect(_return_to_menu)
	$AdventureNotice.visible = adventure_session != null
	if wave_director != null:
		_run_manager.begin_combat()


func _on_adventure_map_loaded(_map: Node2D) -> void:
	if _run_manager.state != RunProgress.RunState.READY:
		return
	$AdventureNotice.visible = false
	_run_manager.begin_combat()


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
