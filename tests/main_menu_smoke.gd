extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	_check(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/ui/main_menu.tscn", "O jogo deve abrir no menu", errors)
	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn") as PackedScene
	if menu_scene == null:
		push_error("O projeto deve abrir em uma cena de menu principal")
		quit(1)
		return
	var menu: MainMenu = menu_scene.instantiate() as MainMenu
	root.add_child(menu)
	current_scene = menu
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	var home: Control = menu.get_node("Margin/Layout/Center/MenuPanel/Content/Home") as Control
	var choices: Control = menu.get_node("Margin/Layout/Center/MenuPanel/Content/ModeChoices") as Control
	_check(home.visible and not choices.visible, "Menu inicial deve mostrar apenas Jogar", errors)
	(menu.get_node("Margin/Layout/Center/MenuPanel/Content/Home/Play") as Button).pressed.emit()
	_check(not home.visible and choices.visible, "Jogar deve mostrar os dois modos", errors)
	(menu.get_node("Margin/Layout/Center/MenuPanel/Content/ModeChoices/Back") as Button).pressed.emit()
	_check(home.visible and not choices.visible, "Voltar deve restaurar o menu inicial", errors)
	(menu.get_node("Margin/Layout/Center/MenuPanel/Content/Home/Play") as Button).pressed.emit()
	(menu.get_node("Margin/Layout/Center/MenuPanel/Content/ModeChoices/Adventure") as Button).pressed.emit()
	await process_frame
	await process_frame
	var game: Node = current_scene
	_check(game != null and game.name == "Main" and run.selected_mode == RunProgress.GameMode.ADVENTURE, "Modo Aventura deve iniciar a partida", errors)
	var player: PlayerController = game.get("player") as PlayerController
	var manager: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	var results: ResultScreen = game.get_node("ResultScreen") as ResultScreen
	_check(run.level == 1 and run.experience == 0 and player.health.current == 100 and manager.get_acquired_upgrades().is_empty(), "Nova partida deve começar limpa", errors)
	run.add_experience(20)
	manager.select_upgrade(manager.current_offer[0].upgrade_id)
	_check(run.state == RunProgress.RunState.READY and game.get("wave_director") == null, "Fundação Aventura deve aguardar mapa sem ondas", errors)
	(game.get_node("AdventureNotice/Center/Panel/Content/MainMenu") as Button).pressed.emit()
	await process_frame
	await process_frame
	menu = current_scene as MainMenu
	_check(menu != null and not paused and run.state == RunProgress.RunState.READY, "Menu Principal deve limpar a partida e desfazer a pausa", errors)
	(menu.get_node("Margin/Layout/Center/MenuPanel/Content/Home/Play") as Button).pressed.emit()
	(menu.get_node("Margin/Layout/Center/MenuPanel/Content/ModeChoices/Endless") as Button).pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	_check(game != null and game.name == "Main" and run.selected_mode == RunProgress.GameMode.ENDLESS and run.level == 1 and (game.get_node("UpgradeManager") as UpgradeManager).get_acquired_upgrades().is_empty() and (game.get("player") as PlayerController).runtime_stats.effective_damage() == 10, "Modo Infinito deve iniciar uma partida limpa", errors)
	var director: WaveDirector = game.get_node("SessionRoot/EndlessSession/WaveDirector") as WaveDirector
	director.endless_wave_interval = 0.0
	await _clear_fixed_waves(game)
	for frame: int in range(10):
		await process_frame
	results = game.get_node("ResultScreen") as ResultScreen
	_check(run.endless_mode and run.state == RunProgress.RunState.COMBAT and director.current_wave == 4, "Modo Infinito deve passar automaticamente à onda 4", errors)
	_check(not results.visible, "Modo Infinito não deve exibir escolha após onda 3", errors)
	player = game.get_node("SessionRoot/EndlessSession/Arena01/Player") as PlayerController
	player.health.configure(100)
	player.health.apply_damage(100)
	_check(run.state == RunProgress.RunState.GAME_OVER, "Morte deve encerrar Modo Infinito", errors)
	(results.get_node("Overlay/Panel/Content/Restart") as Button).pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	_check(game != null and game.name == "Main" and run.selected_mode == RunProgress.GameMode.ENDLESS and not run.endless_mode and run.level == 1, "Recomeçar deve manter Modo Infinito e limpar a sessão", errors)
	_check((game.get_node("UpgradeManager") as UpgradeManager).get_acquired_upgrades().is_empty(), "Recomeçar Modo Infinito deve limpar cartas", errors)
	player = game.get_node("SessionRoot/EndlessSession/Arena01/Player") as PlayerController
	results = game.get_node("ResultScreen") as ResultScreen
	player.health.configure(100)
	player.health.apply_damage(100)
	(results.get_node("Overlay/Panel/Content/MainMenu") as Button).pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene is MainMenu and not paused and run.selected_mode == RunProgress.GameMode.ADVENTURE and run.level == 1, "Menu Principal deve descartar o modo e o estado transitório", errors)
	_finish(errors)


func _clear_fixed_waves(game: Node) -> void:
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	var director: WaveDirector = game.get_node("SessionRoot/EndlessSession/WaveDirector") as WaveDirector
	var manager: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	for wave_number: int in range(1, 4):
		while director.current_wave < wave_number:
			await process_frame
		for enemy: EnemyController in director.active_enemies.duplicate():
			enemy.health.apply_damage(enemy.health.current)
		while run.pending_level_ups > 0:
			manager.select_upgrade(manager.current_offer[0].upgrade_id)
		await process_frame
		await process_frame


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Main menu smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
