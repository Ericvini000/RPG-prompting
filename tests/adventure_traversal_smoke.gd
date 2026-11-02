extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	for branch: StringName in [&"R02A", &"R02B"]:
		var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
		root.add_child(game)
		var identity: int = game.player.get_instance_id()
		for id: StringName in [&"R01", branch, &"R03", &"R04", &"R05"]:
			var destination: Vector2 = game.room_director.controllers[id].global_position
			var reached: bool = false
			for step: int in range(600):
				_settle(game)
				if id == &"R05" and game.room_director.is_completed(id):
					reached = true
					break
				var offset: Vector2 = destination - game.player.global_position
				if offset.length() < 15.0 and game.room_director.is_completed(id):
					reached = true
					break
				_move(offset.normalized() if offset.length() >= 15.0 else Vector2.ZERO)
				await physics_frame
			_move(Vector2.ZERO)
			assert(reached, "Portas/corredor impediram travessia física para %s, posição %s" % [id, game.player.global_position])
			assert(game.player.get_instance_id() == identity)
			if id == &"R03" and branch == &"R02A":
				var rooms: Dictionary = game.room_director.controllers
				await _walk_to(game, rooms[&"R02A"].global_position)
				await _walk_to(game, rooms[&"R01"].global_position)
				assert(game.room_director.current_room_id == &"R01")
				var map: Node2D = game.adventure_session.current_map
				var points: Array[Vector2] = [
					map.get_node("Doors/Door01").global_position,
					rooms[&"R02A"].global_position + Vector2(-260, -70),
					rooms[&"R02A"].global_position + Vector2(-350, 0),
					rooms[&"R02A"].global_position + Vector2(-260, 70),
					map.get_node("Doors/Door03").global_position,
					rooms[&"R03"].global_position + Vector2(260, -70),
					rooms[&"R03"].global_position + Vector2(350, 0),
					rooms[&"R03"].global_position + Vector2(260, 70),
				]
				for point: Vector2 in points:
					await _walk_to(game, point)
				assert(game.room_director.current_room_id == &"R03", "Percurso periférico deve manter a sala lógica sincronizada")
			if id == branch:
				await physics_frame
				var door: RoomDoor = game.adventure_session.current_map.get_node("Doors/Door02" if branch == &"R02A" else "Doors/Door01") as RoomDoor
				var direction: Vector2 = Vector2(-2, 1).normalized() if branch == &"R02A" else Vector2(2, 1).normalized()
				var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(door.global_position - direction * 50.0, door.global_position + direction * 50.0, 1)
				assert(game.player.get_world_2d().direct_space_state.intersect_ray(ray).get("collider") == door.get_node("Body"), "Ramo não escolhido deve permanecer bloqueado fisicamente")
		assert((root.get_node("RunManager") as RunProgress).state == RunProgress.RunState.VICTORY)
		game.queue_free()
		await process_frame
	print("Adventure traversal smoke: OK")
	quit()

func _walk_to(game: Node, destination: Vector2) -> void:
	for step: int in range(600):
		var offset: Vector2 = destination - game.player.global_position
		if offset.length() < 12.0:
			_move(Vector2.ZERO)
			return
		_move(offset.normalized())
		await physics_frame
	_move(Vector2.ZERO)
	assert(false, "Percurso periférico bloqueado em %s rumo a %s" % [game.player.global_position, destination])

func _move(direction: Vector2) -> void:
	for action: String in ["move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(action)
	if direction.x > 0.0:
		Input.action_press("move_right", direction.x)
	elif direction.x < 0.0:
		Input.action_press("move_left", -direction.x)
	if direction.y > 0.0:
		Input.action_press("move_down", direction.y)
	elif direction.y < 0.0:
		Input.action_press("move_up", -direction.y)

func _settle(game: Node) -> void:
	var room: RoomController = game.room_director.controllers[game.room_director.current_room_id] as RoomController
	for enemy: EnemyController in room.active_enemies.duplicate():
		enemy.health.apply_damage(enemy.health.current)
	var upgrades: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	if upgrades.has_pending_choices():
		# Avoid movement upgrades to keep this collision test's speed stable.
		for card: UpgradeDefinition in upgrades.current_offer:
			if card.upgrade_id != "UPG-003":
				upgrades.select_upgrade(card.upgrade_id)
				break
