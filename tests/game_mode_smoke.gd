extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	_check(RunProgress.GameMode.keys() == ["ADVENTURE", "ENDLESS"], "Modos devem ser ADVENTURE e ENDLESS", errors)
	_check(RunProgress.RunState.keys() == ["READY", "COMBAT", "UPGRADE_SELECTION", "VICTORY", "GAME_OVER"], "Escolha legada deve ser removida", errors)
	if not errors.is_empty():
		_finish(errors)
		return
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	_check(run.selected_mode == RunProgress.GameMode.ADVENTURE, "Aventura deve ser o modo padrão", errors)
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	var session: Node = game.get("adventure_session") as Node
	var player: PlayerController = game.get("player") as PlayerController
	_check(session != null and player != null and game.get("wave_director") == null, "Aventura deve ter sessão e jogador sem diretor de ondas", errors)
	if session == null or player == null:
		_finish(errors)
		return
	_check(run.state == RunProgress.RunState.READY and not paused, "Sem mapa, Aventura deve aguardar em READY", errors)
	_check(player.process_mode == Node.PROCESS_MODE_DISABLED and not player.visible, "Jogador não deve explorar um mapa ausente", errors)
	_check((game.get_node("AdventureNotice") as CanvasLayer).visible, "Preparação deve informar que o mapa ainda não está disponível", errors)
	var manager: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	manager.definitions = [
		load("res://data/upgrades/vitality.tres") as UpgradeDefinition,
		load("res://data/upgrades/damage.tres") as UpgradeDefinition,
		load("res://data/upgrades/rapid.tres") as UpgradeDefinition,
	]
	var map_scene: PackedScene = _map_fixture()
	run.add_experience(20)
	_check(session.call("mount_map", map_scene) == ERR_BUSY and run.state == RunProgress.RunState.UPGRADE_SELECTION and paused, "Montagem durante cartas deve ser rejeitada sem retirar a pausa", errors)
	manager.select_upgrade("UPG-004")
	_check(run.state == RunProgress.RunState.READY and not paused, "Escolha em preparação deve retornar ao contexto READY", errors)
	player.health.apply_damage(10)
	var identity: int = player.get_instance_id()
	var damage: int = player.runtime_stats.effective_damage()
	var health_before: int = player.health.current
	var maximum_before: int = player.health.maximum
	_check(session.call("mount_map", map_scene) == OK, "Contrato deve aceitar mapa com PlayerSpawn", errors)
	_check(health_before == 115 and maximum_before == 125, "Fixture deve incluir Vitalidade e dano antes da montagem", errors)
	_check(player.get_instance_id() == identity and player.health.current == health_before and player.health.maximum == maximum_before and player.runtime_stats.effective_damage() == damage, "Montar mapa deve preservar jogador, vida atual/máxima e build", errors)
	_check(run.level == 2 and run.state == RunProgress.RunState.COMBAT, "Mapa pronto deve ativar sessão sem resetar progresso", errors)
	_check(player.visible and player.process_mode == Node.PROCESS_MODE_INHERIT and player.global_position == Vector2(100, 150), "Mapa deve ativar jogador no marcador de entrada", errors)
	_check(not (game.get_node("AdventureNotice") as CanvasLayer).visible, "Mapa carregado deve esconder aviso", errors)
	_check(session.call("mount_map", map_scene) == ERR_ALREADY_IN_USE, "Montar duas vezes não deve substituir mapa/jogador", errors)
	run.toggle_pause()
	var results: ResultScreen = game.get_node("ResultScreen") as ResultScreen
	_check(paused and results.visible and (results.get_node("Overlay/Panel/Content/PauseDashboard") as Control).visible, "Pausa deve funcionar sem WaveDirector", errors)
	run.toggle_pause()
	player.health.configure(100)
	player.health.apply_damage(100)
	_check(run.state == RunProgress.RunState.GAME_OVER and results.visible, "Morte deve funcionar na sessão sem WaveDirector", errors)
	(results.get_node("Overlay/Panel/Content/Restart") as Button).pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	player = game.get("player") as PlayerController
	_check(run.selected_mode == RunProgress.GameMode.ADVENTURE and run.level == 1 and run.state == RunProgress.RunState.READY and player.health.current == 100, "Reinício deve preservar Aventura e limpar a tentativa", errors)
	_check((game.get_node("UpgradeManager") as UpgradeManager).get_acquired_upgrades().is_empty(), "Reinício deve limpar cartas", errors)
	session = game.get("adventure_session") as Node
	var invalid_map: PackedScene = PackedScene.new()
	var invalid_root: Node2D = Node2D.new()
	invalid_map.pack(invalid_root)
	invalid_root.free()
	_check(session.call("mount_map", invalid_map) == ERR_INVALID_DATA and session.get("current_map") == null, "Mapa sem marcador deve ser rejeitado sem ativar sessão", errors)
	_check(session.call("mount_map", null) == ERR_INVALID_PARAMETER, "Mapa nulo deve ser rejeitado", errors)
	_check(session.call("mount_map", PackedScene.new()) == ERR_INVALID_DATA, "PackedScene vazia deve ser rejeitada sem erro de script", errors)
	run.request_game_over()
	_check(session.call("mount_map", map_scene) == ERR_BUSY and run.state == RunProgress.RunState.GAME_OVER and paused, "Montagem não deve substituir derrota", errors)
	run.reset_run()
	(game.get_node("AdventureNotice/Center/Panel/Content/MainMenu") as Button).pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene is MainMenu and not paused and run.state == RunProgress.RunState.READY, "Preparação deve permitir voltar ao menu", errors)
	_finish(errors)


func _map_fixture() -> PackedScene:
	var map: Node2D = Node2D.new()
	map.name = "MapFixture"
	var spawn: Marker2D = Marker2D.new()
	spawn.name = "PlayerSpawn"
	spawn.position = Vector2(100, 150)
	map.add_child(spawn)
	spawn.owner = map
	var packed: PackedScene = PackedScene.new()
	packed.pack(map)
	map.free()
	return packed


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Game mode smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
