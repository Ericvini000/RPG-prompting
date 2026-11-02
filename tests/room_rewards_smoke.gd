extends SceneTree
func _initialize() -> void:
	call_deferred("_verify")
func _verify() -> void:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	var manager: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	if not manager.has_method("request_reward_choice"):
		push_error("Recompensa deve usar fila distinta de níveis")
		quit(1)
		return
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	run.add_experience(100)
	manager.request_reward_choice(&"test:reward")
	for choice: int in range(3):
		manager.select_upgrade(manager.current_offer[0].upgrade_id)
	assert(run.pending_level_ups == 0 and manager.has_pending_choices() and run.level == 4 and run.experience == 10)
	manager.select_upgrade(manager.current_offer[0].upgrade_id)
	assert(not manager.has_pending_choices() and run.level == 4 and run.experience == 10)
	manager.request_reward_choice(&"test:reward")
	assert(not manager.has_pending_choices())
	manager.request_reward_choice(&"test:victory")
	run.request_victory()
	assert(run.state == RunProgress.RunState.UPGRADE_SELECTION)
	manager.select_upgrade(manager.current_offer[0].upgrade_id)
	assert(run.state == RunProgress.RunState.VICTORY)
	game.queue_free()
	await process_frame
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	manager = game.get_node("UpgradeManager") as UpgradeManager
	game.adventure_session.mount_definition(load("res://data/maps/map_01.tres") as MapDefinition)
	await process_frame
	for enemy: EnemyController in game.room_director.controllers[&"R01"].active_enemies.duplicate():
		enemy.health.apply_damage(enemy.health.current)
	for frame: int in range(10):
		if manager.has_pending_choices():
			manager.select_upgrade(manager.current_offer[0].upgrade_id)
		await process_frame
	assert(game.room_director.is_completed(&"R01"))
	game.player.health.configure(100)
	game.player.health.apply_damage(70)
	assert(game.room_director.try_enter_room(&"R02B"))
	await process_frame
	await process_frame
	assert(game.player.health.current == 60 and game.room_director.is_completed(&"R02B"))
	assert(game.room_director.try_enter_room(&"R01"))
	assert(game.room_director.try_enter_room(&"R02B"))
	assert(game.player.health.current == 60 and game.room_director.is_locked(&"R02A"))
	manager.request_reward_choice(&"test:cancel")
	run.request_game_over()
	var owned: Dictionary = manager.owned_counts.duplicate()
	manager.select_upgrade("UPG-001")
	assert(manager.owned_counts == owned and not manager.has_pending_choices() and run.state == RunProgress.RunState.GAME_OVER)
	print("Room rewards smoke: OK")
	quit()
