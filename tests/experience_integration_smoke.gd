extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var manager: Node = root.get_node("RunManager")
	manager.call("reset_run")
	manager.call("add_experience", 100)
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var director: WaveDirector = main.get_node("WaveDirector") as WaveDirector
	_check(manager.get("level") == 1 and manager.get("experience") == 0 and manager.get("pending_level_ups") == 0, "Nova cena principal deve iniciar uma partida sem progresso anterior", errors)
	var level_requests: Array[int] = [0]
	var progress_events: Array[Vector2i] = []
	manager.connect("level_up_requested", func() -> void: level_requests[0] += 1)
	manager.connect("experience_changed", func(xp: int, required: int) -> void: progress_events.append(Vector2i(xp, required)))
	await physics_frame
	await physics_frame
	_check(director.current_wave == 1 and director.active_enemies.size() == 4, "Primeira onda deve iniciar", errors)

	var first_enemy: EnemyController = director.active_enemies[0]
	_check(first_enemy.health.apply_damage(first_enemy.health.current), "Primeiro inimigo deve morrer", errors)
	_check(not first_enemy.health.apply_damage(10), "Derrota repetida nao deve conceder XP", errors)
	_check(manager.get("experience") == 10 and manager.get("level") == 1, "Perseguidor deve conceder exatamente 10 XP", errors)
	var second_enemy: EnemyController = director.active_enemies[0]
	second_enemy.health.apply_damage(second_enemy.health.current)
	_check(manager.get("level") == 2 and manager.get("experience") == 0, "20 XP devem subir ao nivel 2", errors)
	_kill_active(director)
	await physics_frame
	await physics_frame
	_check(director.current_wave == 2, "Segunda onda deve iniciar", errors)
	_check(manager.get("level") == 2 and manager.get("experience") == 20, "XP restante da primeira onda deve ser preservado", errors)
	_kill_active(director)
	await physics_frame
	await physics_frame
	_check(director.current_wave == 3, "Terceira onda deve iniciar", errors)
	_check(manager.get("level") == 4 and manager.get("experience") == 10, "Segunda onda deve conceder 60 XP e preservar excedente", errors)
	_kill_active(director)
	await physics_frame
	await physics_frame
	_check(manager.get("level") == 5 and manager.get("experience") == 35, "Três ondas devem conceder 175 XP no total", errors)
	_check(manager.get("pending_level_ups") == 4 and level_requests[0] == 4, "Quatro evolucoes devem permanecer pendentes", errors)
	_check(not progress_events.is_empty() and progress_events.back() == Vector2i(35, 60), "Sinal final deve informar 35 de 60 XP", errors)
	_finish(errors)


func _kill_active(director: WaveDirector) -> void:
	var enemies: Array[EnemyController] = director.active_enemies.duplicate()
	for enemy: EnemyController in enemies:
		enemy.health.apply_damage(enemy.health.current)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Experience integration smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
