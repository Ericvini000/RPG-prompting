extends SceneTree
func _initialize() -> void:
	call_deferred("_verify")
func _verify() -> void:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	game.adventure_session.mount_definition(load("res://data/maps/map_01.tres") as MapDefinition)
	var room: RoomController = game.room_director.controllers[&"R01"] as RoomController
	await process_frame
	if room.get("active_enemies") == null:
		push_error("Sala deve iniciar encontro com inimigos")
		quit(1)
		return
	assert(room.active_enemies.size() == 3)
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	var manager: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	for enemy: EnemyController in room.active_enemies.duplicate():
		enemy.health.apply_damage(enemy.health.current)
		enemy.health.apply_damage(10)
	while run.pending_level_ups > 0:
		manager.select_upgrade(manager.current_offer[0].upgrade_id)
	await process_frame
	await process_frame
	assert(game.room_director.is_completed(&"R01"))
	assert(run.level == 2 and run.experience == 10)
	assert(not game.room_director.try_enter_room(&"R01"))
	assert(game.room_director.try_enter_room(&"R02A"))
	await process_frame
	game.player.health.configure(100)
	game.player.health.apply_damage(100)
	var side: RoomController = game.room_director.controllers[&"R02A"] as RoomController
	for enemy: EnemyController in side.active_enemies.duplicate():
		enemy.health.apply_damage(enemy.health.current)
	await process_frame
	assert(not game.room_director.is_completed(&"R02A") and run.state == RunProgress.RunState.GAME_OVER)
	print("Room encounter smoke: OK")
	quit()
