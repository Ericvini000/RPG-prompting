extends SceneTree
func _initialize() -> void:
	call_deferred("_verify")
func _verify() -> void:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	game.adventure_map = null
	root.add_child(game)
	game.adventure_session.mount_definition(load("res://data/maps/map_01.tres") as MapDefinition)
	await _clear(game)
	assert(game.room_director.try_enter_room(&"R02A"))
	await _clear(game)
	assert(game.room_director.try_enter_room(&"R03"))
	await _clear(game)
	assert(game.room_director.try_enter_room(&"R04"))
	await process_frame
	var elite: RoomController = game.room_director.controllers[&"R04"] as RoomController
	assert(elite.active_enemies.size() == 3)
	for enemy: EnemyController in elite.active_enemies:
		assert(enemy.health.maximum == roundi(enemy.data.max_health * 1.6))
		assert(is_equal_approx(enemy.damage_multiplier, 1.2))
	var rewards: Array[StringName] = []
	var upgrades: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	upgrades.reward_choice_resolved.connect(func(id: StringName) -> void: rewards.append(id))
	await _clear(game)
	assert(rewards == [&"map_01:R04:0"])
	assert(game.room_director.is_completed(&"R04"))
	assert((root.get_node("RunManager") as RunProgress).state == RunProgress.RunState.EXPLORATION)
	assert((load("res://data/tank.tres") as EnemyData).max_health == 100)
	assert(game.room_director.try_enter_room(&"R03") and game.room_director.try_enter_room(&"R04"))
	assert(rewards.size() == 1)
	print("Elite room smoke: OK")
	quit()
func _clear(game: Node) -> void:
	var room: RoomController = game.room_director.controllers[game.room_director.current_room_id] as RoomController
	var upgrades: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	for frame: int in range(60):
		for enemy: EnemyController in room.active_enemies.duplicate():
			enemy.health.apply_damage(enemy.health.current)
		if upgrades.has_pending_choices():
			upgrades.select_upgrade(upgrades.current_offer[0].upgrade_id)
		await process_frame
		if game.room_director.is_completed(room.definition.room_id):
			return
	assert(false, "Sala não concluiu")
