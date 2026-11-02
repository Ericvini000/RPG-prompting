extends SceneTree
func _initialize() -> void:
	call_deferred("_verify")
func _verify() -> void:
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	for branch: StringName in [&"R02A", &"R02B"]:
		var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
		root.add_child(game)
		current_scene = game
		if game.get("room_director") == null:
			push_error("Aventura deve abrir o primeiro mapa automaticamente")
			quit(1)
			return
		var identity: int = game.player.get_instance_id()
		assert(game.wave_director == null and run.state == RunProgress.RunState.COMBAT)
		for id: StringName in [&"R01", branch, &"R03", &"R04", &"R05"]:
			if id != &"R01":
				game.player.global_position = game.room_director.controllers[id].global_position
				for attempt: int in range(10):
					await physics_frame
					if game.room_director.current_room_id == id:
						break
				assert(game.room_director.current_room_id == id, "Entrada esperada %s, atual %s, estado %s" % [id, game.room_director.current_room_id, run.state])
			assert(game.player.get_instance_id() == identity)
			await _clear(game)
			assert(game.room_director.is_completed(id))
		assert(run.state == RunProgress.RunState.VICTORY)
		assert((game.get_node("ResultScreen") as ResultScreen).visible)
		assert((game.get_node("HUD/Overlay/Top/Wave") as Label).text.contains("5/5"))
		assert(game.room_director.is_locked(&"R02B" if branch == &"R02A" else &"R02A"))
		(game.get_node("ResultScreen/Overlay/Panel/Content/Restart") as Button).pressed.emit()
		await process_frame
		await process_frame
		game = current_scene
		assert(run.level == 1 and game.player.health.current == 100 and run.selected_mode == RunProgress.GameMode.ADVENTURE)
		assert((game.get_node("UpgradeManager") as UpgradeManager).get_acquired_upgrades().is_empty())
		game.player.health.apply_damage(100)
		assert(run.state == RunProgress.RunState.GAME_OVER)
		(game.get_node("ResultScreen/Overlay/Panel/Content/MainMenu") as Button).pressed.emit()
		await process_frame
		await process_frame
		assert(current_scene is MainMenu and not paused)
		current_scene.queue_free()
		await process_frame
	print("Adventure flow smoke: OK")
	quit()
func _clear(game: Node) -> void:
	var room: RoomController = game.room_director.controllers[game.room_director.current_room_id] as RoomController
	var upgrades: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	for frame: int in range(90):
		for enemy: EnemyController in room.active_enemies.duplicate():
			enemy.health.apply_damage(enemy.health.current)
		if upgrades.has_pending_choices():
			upgrades.select_upgrade(upgrades.current_offer[0].upgrade_id)
		await process_frame
		if game.room_director.is_completed(room.definition.room_id):
			return
	assert(false, "Sala não concluiu")
