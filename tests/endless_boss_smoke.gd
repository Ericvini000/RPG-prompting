extends SceneTree
func _initialize() -> void:
	call_deferred("_verify")
func _verify() -> void:
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	run.select_mode(RunProgress.GameMode.ENDLESS)
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	var director: WaveDirector = game.wave_director
	if director.get("boss_schedule") == null:
		push_error("Infinito deve configurar chefes periódicos")
		quit(1)
		return
	director.endless_wave_interval = 0.0
	director.endless_spawn_interval = 0.0
	game.player.health.configure(10000)
	var identity: int = game.player.get_instance_id()
	var upgrades: UpgradeManager = game.get_node("UpgradeManager") as UpgradeManager
	var rewards: Array[StringName] = []
	upgrades.reward_choice_resolved.connect(func(id: StringName) -> void: rewards.append(id))
	for target_wave: int in [5, 10]:
		for step: int in range(600):
			if director.current_wave == target_wave and not director.active_enemies.is_empty():
				break
			for enemy: EnemyController in director.active_enemies.duplicate():
				enemy.health.apply_damage(enemy.health.current)
			if upgrades.has_pending_choices():
				upgrades.select_upgrade(upgrades.current_offer[0].upgrade_id)
			await process_frame
		assert(director.current_wave == target_wave and director.active_enemies.size() == 1)
		var boss: EnemyController = director.active_enemies[0]
		assert(boss is BossController)
		assert(boss.health.maximum == roundi(450 * (1.0 + 0.05 * (target_wave - 3))))
		run.toggle_pause()
		assert(paused)
		run.toggle_pause()
		boss.health.apply_damage(boss.health.current)
		boss.health.apply_damage(10)
		for step: int in range(30):
			if upgrades.has_pending_choices():
				upgrades.select_upgrade(upgrades.current_offer[0].upgrade_id)
			await process_frame
			if director.current_wave > target_wave:
				break
		assert(run.state == RunProgress.RunState.COMBAT and director.current_wave == target_wave + 1)
		assert(game.player.get_instance_id() == identity)
	assert(rewards.size() == 2 and rewards[0] != rewards[1])
	game.player.health.apply_damage(game.player.health.current)
	assert(run.state == RunProgress.RunState.GAME_OVER)
	var wave_before: int = director.current_wave
	for step: int in range(10):
		await process_frame
	assert(director.current_wave == wave_before)
	(game.get_node("ResultScreen/Overlay/Panel/Content/Restart") as Button).pressed.emit()
	await process_frame
	await process_frame
	assert(run.selected_mode == RunProgress.GameMode.ENDLESS and run.level == 1 and current_scene.wave_director.current_wave == 1)
	assert((current_scene.get_node("UpgradeManager") as UpgradeManager).get_acquired_upgrades().is_empty())
	print("Endless boss smoke: OK")
	quit()
