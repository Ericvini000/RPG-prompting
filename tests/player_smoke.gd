extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var packed: PackedScene = load("res://scenes/arena_01.tscn") as PackedScene
	if packed == null:
		_finish(["A cena principal não carrega"])
		return

	var arena: Node2D = packed.instantiate() as Node2D
	root.add_child(arena)
	var player: CharacterBody2D = arena.get_node_or_null("Player") as CharacterBody2D
	if arena == null or player == null:
		_finish(["A arena deve conter Player como CharacterBody2D"])
		return

	var spawn: Marker2D = arena.get_node_or_null("Spawns/PlayerSpawn") as Marker2D
	_check(spawn != null and player.global_position.distance_to(spawn.global_position) < 0.1, "Player deve começar no PlayerSpawn", errors)
	_check(player.get_node_or_null("CollisionShape2D") is CollisionShape2D, "Player precisa de colisão", errors)
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	_check(camera != null and camera.is_current(), "Câmera do Player deve acompanhar a cena", errors)
	_check(player.get_node_or_null("Visuals/BowPivot/BowOrigin") is Marker2D, "Origem visual do arco ausente", errors)

	var stats: Resource = load("res://data/player_stats.tres") as Resource
	if stats == null:
		errors.append("PlayerStats não carrega")
	else:
		_check(is_equal_approx(stats.get("move_speed"), 230.0), "Velocidade de movimento deve ser 230", errors)
		_check(is_equal_approx(stats.get("dash_speed"), 600.0), "Velocidade do dash deve ser 600", errors)
		_check(is_equal_approx(stats.get("dash_duration"), 0.14), "Duração do dash deve ser 0,14", errors)
		_check(is_equal_approx(stats.get("dash_cooldown"), 1.2), "Recarga do dash deve ser 1,20", errors)

	if not errors.is_empty():
		_finish(errors)
		return

	var bow_pivot: Node2D = player.get_node("Visuals/BowPivot") as Node2D
	player.call("aim_at", bow_pivot.global_position + Vector2(100, 0))
	_check(absf(bow_pivot.global_rotation) < 0.01, "Arco deve apontar para a direita", errors)
	player.call("aim_at", bow_pivot.global_position + Vector2(0, -100))
	_check(absf(bow_pivot.global_rotation + PI / 2.0) < 0.01, "Arco deve apontar para cima", errors)

	var start_position: Vector2 = player.global_position
	Input.action_press("move_right")
	for index: int in range(5):
		await physics_frame
	Input.action_release("move_right")
	_check(player.global_position.x > start_position.x, "WASD deve mover o Player", errors)
	_check(player.velocity.length() <= 230.1, "Velocidade normal deve respeitar 230 px/s", errors)

	Input.action_press("move_up")
	Input.action_press("move_right")
	await physics_frame
	Input.action_release("move_up")
	Input.action_release("move_right")
	_check(player.velocity.length() <= 230.1, "Movimento diagonal deve ser normalizado", errors)

	Input.action_press("dash")
	await physics_frame
	await physics_frame
	Input.action_release("dash")
	_check(player.call("is_dashing"), "Dash deve iniciar ao pressionar Espaço", errors)
	_check(player.call("is_invulnerable"), "Dash deve conceder invulnerabilidade", errors)
	_check(player.velocity.length() > 500.0, "Dash deve usar velocidade superior ao movimento normal", errors)
	for index: int in range(12):
		await physics_frame
	_check(not player.call("is_dashing"), "Dash deve terminar após a duração configurada", errors)
	_check(not player.call("is_invulnerable"), "Invulnerabilidade deve terminar com o dash", errors)
	_check(not player.call("can_dash"), "Recarga deve impedir dash imediato", errors)

	for index: int in range(80):
		await physics_frame
	_check(player.call("can_dash"), "Dash deve voltar após a recarga", errors)
	player.position = Vector2(84, 280)
	Input.action_press("move_down")
	Input.action_press("dash")
	for index: int in range(15):
		await physics_frame
	Input.action_release("dash")
	Input.action_release("move_down")
	_check(player.position.y < 325.0, "Player não deve atravessar a parede durante o dash", errors)

	_finish(errors)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Player smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
