extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var viewport_size: Vector2i = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width", 0),
		ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	)
	_check(viewport_size == Vector2i(1280, 720), "Viewport deve ser 1280x720", errors)
	_check(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/main.tscn", "main.tscn deve ser a cena principal", errors)
	_check(load("res://Cenas/cena01.tscn") is PackedScene, "Cena 1 preservada deve carregar", errors)

	for action: String in ["move_up", "move_down", "move_left", "move_right", "attack", "dash", "pause"]:
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "Ação de entrada ausente: " + action, errors)
	for binding: Array in [["move_up", KEY_W], ["move_down", KEY_S], ["move_left", KEY_A], ["move_right", KEY_D], ["dash", KEY_SPACE], ["pause", KEY_ESCAPE]]:
		_check(_has_key(binding[0], binding[1]), "Tecla incorreta para " + binding[0], errors)
	_check(_has_left_mouse("attack"), "Ataque deve usar mouse esquerdo", errors)

	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		errors.append("Não foi possível carregar main.tscn")
		_finish(errors)
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	var arena: Node2D = main.get_node_or_null("Arena01") as Node2D
	if arena == null:
		errors.append("Main deve conter Arena01")
		_finish(errors)
		return

	var floor_layer: TileMapLayer = arena.get_node_or_null("Floor") as TileMapLayer
	if floor_layer == null or floor_layer.tile_set == null:
		errors.append("Arena precisa de TileMapLayer com TileSet")
	else:
		_check(floor_layer.tile_set.tile_shape == TileSet.TILE_SHAPE_ISOMETRIC, "TileSet deve ser isométrico", errors)
		_check(floor_layer.tile_set.tile_size == Vector2i(128, 64), "Tiles devem medir 128x64", errors)
		_check(floor_layer.get_used_cells().size() == 110, "Piso deve conter ao menos 40 células", errors)

	var alias_scene: PackedScene = load("res://Cenas/cena01.tscn") as PackedScene
	if alias_scene != null:
		var alias_arena: Node2D = alias_scene.instantiate() as Node2D
		_check((alias_arena.get_node("Floor") as TileMapLayer).get_used_cells().size() == 110, "Cena 1 deve herdar o piso ampliado", errors)
		alias_arena.free()

	_check(arena.y_sort_enabled, "Arena deve habilitar ordenação por Y", errors)
	_check(_has_collision(arena.get_node_or_null("Bounds")), "Limites devem ter colisão", errors)
	_check(_has_collision(arena.get_node_or_null("Obstacles")), "Obstáculos devem ter colisão", errors)
	_check(arena.get_node_or_null("Spawns/PlayerSpawn") is Marker2D, "Spawn do jogador ausente", errors)
	_check(arena.get_node_or_null("Spawns/EnemySpawn01") is Marker2D, "Spawn de inimigo ausente", errors)
	await physics_frame
	var pillar: StaticBody2D = arena.get_node_or_null("Obstacles/Pillar01") as StaticBody2D
	if pillar != null:
		var pillar_ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			pillar.global_position + Vector2(-60, 0), pillar.global_position + Vector2(60, 0)
		)
		var pillar_hit: Dictionary = arena.get_world_2d().direct_space_state.intersect_ray(pillar_ray)
		_check(pillar_hit.get("collider") == pillar, "Pilar deve bloquear fisicamente o caminho", errors)
	var rim_ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			arena.to_global(Vector2(84, 280)), arena.to_global(Vector2(84, 360))
	)
	var rim_hit: Dictionary = arena.get_world_2d().direct_space_state.intersect_ray(rim_ray)
	_check(rim_hit.get("collider") is StaticBody2D, "Limite inferior deve bloquear fisicamente o caminho", errors)

	_finish(errors)


func _has_collision(node: Node) -> bool:
	if node == null:
		return false
	if node is CollisionPolygon2D or node is CollisionShape2D:
		return true
	for child: Node in node.get_children():
		if _has_collision(child):
			return true
	return false


func _has_key(action: String, key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == key:
			return true
	return false


func _has_left_mouse(action: String) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			return true
	return false


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Arena smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
