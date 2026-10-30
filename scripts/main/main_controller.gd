extends Node2D


func _ready() -> void:
	var run_manager: RunProgress = get_node("/root/RunManager") as RunProgress
	var player: PlayerController = $Arena01/Player as PlayerController
	var director: WaveDirector = $WaveDirector as WaveDirector
	var upgrade_manager: UpgradeManager = $UpgradeManager as UpgradeManager
	var hud: GameHUD = $HUD as GameHUD
	var results: ResultScreen = $ResultScreen as ResultScreen
	run_manager.reset_run()
	hud.bind(player, director, run_manager)
	results.bind(run_manager, player, upgrade_manager, director)
	player.health.died.connect(run_manager.request_game_over)
	director.arena_completed.connect(run_manager.complete_initial_waves)
	results.restart_requested.connect(_restart_run)
	results.resume_requested.connect(run_manager.toggle_pause)
	results.endless_requested.connect(run_manager.choose_endless_mode)
	results.victory_requested.connect(run_manager.choose_victory)
	results.main_menu_requested.connect(_return_to_menu)
	run_manager.begin_combat()


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
