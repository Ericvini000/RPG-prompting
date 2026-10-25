extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var arena: Node2D = main.get_node("Arena01") as Node2D
	var player: PlayerController = arena.get_node("Player") as PlayerController
	var director: Node = main.get_node_or_null("WaveDirector")
	if director == null:
		_finish(["Main precisa de WaveDirector"])
		return
	var waves_seen: Array[int] = []
	var completed: Array[int] = [0]
	director.wave_changed.connect(func(number: int) -> void: waves_seen.append(number))
	director.arena_completed.connect(func() -> void: completed[0] += 1)
	await physics_frame
	await physics_frame
	_check_wave(director, player, 1, [35, 35, 35, 35], errors)

	player.global_position = (arena.get_node("Spawns/EnemySpawn01") as Marker2D).global_position
	_kill_active(director)
	_resolve_choices(main)
	await physics_frame
	await physics_frame
	_check_wave(director, player, 2, [35, 35, 35, 25, 25], errors)

	player.global_position = (arena.get_node("Spawns/EnemySpawn02") as Marker2D).global_position
	_kill_active(director)
	_resolve_choices(main)
	await physics_frame
	await physics_frame
	_check_wave(director, player, 3, [35, 35, 25, 25, 100], errors)

	_kill_active(director)
	_resolve_choices(main)
	await physics_frame
	await physics_frame
	_check(waves_seen == [1, 2, 3], "Ondas devem iniciar em ordem, uma vez cada", errors)
	_check(completed[0] == 1, "Arena deve emitir conclusao uma unica vez", errors)
	_check(director.active_enemies.is_empty(), "Nao devem restar inimigos ativos", errors)
	_finish(errors)


func _check_wave(director: Node, player: PlayerController, number: int, expected_health: Array[int], errors: Array[String]) -> void:
	_check(director.current_wave == number, "Numero incorreto da onda " + str(number), errors)
	var enemies: Array[EnemyController] = director.active_enemies.duplicate()
	_check(enemies.size() == expected_health.size(), "Quantidade incorreta de inimigos na onda " + str(number), errors)
	var actual_health: Array[int] = []
	for enemy: EnemyController in enemies:
		actual_health.append(enemy.health.maximum)
		_check(enemy.global_position.distance_to(player.global_position) >= 128.0, "Inimigo surgiu perto demais do jogador", errors)
	for index: int in range(enemies.size()):
		for other_index: int in range(index + 1, enemies.size()):
			_check(enemies[index].global_position.distance_to(enemies[other_index].global_position) >= 80.0, "Inimigos surgiram sobrepostos", errors)
	actual_health.sort()
	expected_health.sort()
	_check(actual_health == expected_health, "Composicao incorreta da onda " + str(number), errors)


func _kill_active(director: Node) -> void:
	var enemies: Array[EnemyController] = director.active_enemies.duplicate()
	for enemy: EnemyController in enemies:
		enemy.health.apply_damage(enemy.health.current)


func _resolve_choices(main: Node) -> void:
	var run_manager: RunProgress = root.get_node("RunManager") as RunProgress
	var manager: UpgradeManager = main.get_node("UpgradeManager") as UpgradeManager
	while run_manager.pending_level_ups > 0:
		manager.select_upgrade(manager.current_offer[0].upgrade_id)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Wave smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
