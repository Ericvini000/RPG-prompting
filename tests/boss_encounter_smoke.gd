extends SceneTree
func _initialize() -> void:
	call_deferred("_verify")
func _verify() -> void:
	var packed: PackedScene = load("res://scenes/enemies/boss.tscn") as PackedScene
	if packed == null:
		push_error("Chefe reutilizável deve existir")
		quit(1)
		return
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	run.select_mode(RunProgress.GameMode.ENDLESS)
	run.begin_combat()
	var player: PlayerController = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	var boss: EnemyController = packed.instantiate() as EnemyController
	boss.target = player
	boss.position = Vector2(300, 0)
	root.add_child(boss)
	boss.set_physics_process(false)
	assert(boss.health.maximum == 450 and boss.effective_contact_damage() == 15)
	var shots: Array[Projectile] = []
	boss.connect("projectile_fired", func(shot: Projectile) -> void: shots.append(shot))
	boss.call("_physics_process", 2.5)
	assert(shots.is_empty())
	boss.call("_physics_process", 0.61)
	assert(shots.size() == 3)
	assert(shots[1].direction.is_equal_approx((player.global_position - shots[1].global_position).normalized()), "Leque deve mirar a partir da origem visual do projétil")
	boss.call("_physics_process", 2.5)
	boss.call("_physics_process", 0.61)
	assert(shots.size() == 11)
	for shot: Projectile in shots:
		assert(shot.damage == 9)
		shot.queue_free()
	var defeats: Array[int] = [0]
	boss.enemy_defeated.connect(func(_xp: int) -> void: defeats[0] += 1)
	boss.health.apply_damage(450)
	boss.health.apply_damage(450)
	assert(defeats[0] == 1 and run.state == RunProgress.RunState.COMBAT)
	player.queue_free()
	await process_frame
	run.select_mode(RunProgress.GameMode.ADVENTURE)
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	game.adventure_map = null
	root.add_child(game)
	game.adventure_session.mount_definition(load("res://data/maps/map_01.tres") as MapDefinition)
	for id: StringName in [&"R01", &"R02A", &"R03", &"R04", &"R05"]:
		if id != &"R01":
			game.player.global_position = game.room_director.controllers[id].global_position
			assert(game.room_director.try_enter_room(id))
		var room: RoomController = game.room_director.controllers[id] as RoomController
		var upgrades: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
		for frame: int in range(60):
			for enemy: EnemyController in room.active_enemies.duplicate():
				enemy.health.apply_damage(enemy.health.current)
			if upgrades.has_pending_choices():
				assert(run.state != RunProgress.RunState.VICTORY)
				upgrades.select_upgrade(upgrades.current_offer[0].upgrade_id)
			await process_frame
			if game.room_director.is_completed(id):
				break
		assert(game.room_director.is_completed(id))
	assert(run.state == RunProgress.RunState.VICTORY)
	print("Boss encounter smoke: OK")
	quit()
