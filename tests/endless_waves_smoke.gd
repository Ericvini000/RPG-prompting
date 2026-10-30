extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	var director: WaveDirector = main.get_node("WaveDirector") as WaveDirector
	var manager: UpgradeManager = main.get_node("UpgradeManager") as UpgradeManager
	var results: ResultScreen = main.get_node("ResultScreen") as ResultScreen
	await physics_frame
	await _clear_fixed_waves(director, manager, run, errors)
	_check(run.state == RunProgress.RunState.VICTORY and results.visible and paused, "Modo Ondas deve vencer após as cartas da terceira onda", errors)
	_check(not (results.get_node("Overlay/Panel/Content/Endless") as Button).visible and not (results.get_node("Overlay/Panel/Content/Finish") as Button).visible, "Modo Ondas não deve oferecer escolha extra", errors)
	_check(director.current_wave == 3 and not run.endless_mode, "Modo Ondas deve terminar na terceira onda", errors)
	main.queue_free()
	await process_frame

	run.select_mode(RunProgress.GameMode.ENDLESS)
	var endless_main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(endless_main)
	var endless_run: RunProgress = root.get_node("RunManager") as RunProgress
	var endless_director: WaveDirector = endless_main.get_node("WaveDirector") as WaveDirector
	var endless_manager: UpgradeManager = endless_main.get_node("UpgradeManager") as UpgradeManager
	var endless_results: ResultScreen = endless_main.get_node("ResultScreen") as ResultScreen
	var player: PlayerController = endless_main.get_node("Arena01/Player") as PlayerController
	endless_director.maximum_active_enemies = 3
	endless_director.endless_spawn_interval = 0.0
	endless_director.endless_wave_interval = 0.0
	endless_director.invalid_spawn_retry_interval = 0.0
	endless_director.spawn_fallback_after = 0.1
	var spawned: Array[int] = [0]
	(endless_main.get_node("Arena01") as Node2D).child_entered_tree.connect(func(child: Node) -> void:
		if child is EnemyController:
			spawned[0] += 1
	)
	await physics_frame
	await _clear_fixed_waves(endless_director, endless_manager, endless_run, errors)
	var acquired_before: Dictionary = endless_manager.owned_counts.duplicate()
	var damage_before: int = player.runtime_stats.effective_damage()
	spawned[0] = endless_director.active_enemies.size()
	for frame: int in range(10):
		await process_frame
	_check(endless_run.endless_mode and endless_run.state == RunProgress.RunState.COMBAT, "Continuar deve retomar o combate", errors)
	_check(not (endless_results.get_node("Overlay/Panel/Content/Endless") as Button).visible and not (endless_results.get_node("Overlay/Panel/Content/Finish") as Button).visible, "Modo Infinito não deve mostrar a escolha antiga", errors)
	_check(endless_director.current_wave == 4 and endless_director.active_enemies.size() == 3, "Onda 4 deve usar o primeiro lote de três inimigos", errors)
	_check(spawned[0] == 3, "Limite simultâneo deve impedir spawns extras", errors)
	var initial_types: Dictionary = {}
	for enemy: EnemyController in endless_director.active_enemies:
		initial_types[enemy.data.max_health] = true
	_check(initial_types.size() == 3, "Composição infinita deve usar os três tipos existentes", errors)
	_check((endless_main.get_node("HUD/Overlay/Top/Wave") as Label).text.contains("4") and not (endless_main.get_node("HUD/Overlay/Top/Wave") as Label).text.contains("/ 3"), "HUD deve identificar onda infinita", errors)
	endless_run.toggle_pause()
	_check(paused and endless_results.visible and (endless_results.get_node("Overlay/Panel/Content/PauseDashboard") as Control).visible, "Menu de atributos deve funcionar no modo infinito", errors)
	endless_run.toggle_pause()
	for enemy: EnemyController in endless_director.active_enemies:
		_check(enemy.health.maximum == roundi(enemy.data.max_health * 1.05) and is_equal_approx(enemy.damage_multiplier, 1.02), "Onda 4 deve escalar vida e dano sem alterar EnemyData", errors)
		if enemy is RangedEnemyController:
			var shots: Array[Projectile] = []
			(enemy as RangedEnemyController).projectile_fired.connect(func(projectile: Projectile) -> void: shots.append(projectile))
			enemy.damage_multiplier = 1.5
			(enemy as RangedEnemyController).call("_fire_at_player")
			_check(shots.size() == 1 and shots[0].damage == 11, "Projétil deve usar dano efetivo da instância", errors)
			shots[0].queue_free()
			enemy.damage_multiplier = 1.02
	endless_run.add_experience(endless_run.required_experience_for_level(endless_run.level) - endless_run.experience)
	var spawned_before_cards: int = spawned[0]
	for frame: int in range(10):
		await process_frame
	_check(endless_run.state == RunProgress.RunState.UPGRADE_SELECTION and spawned[0] == spawned_before_cards, "Seleção pendente deve interromper novos spawns", errors)
	_resolve_choices(endless_manager, endless_run)
	var attempts: int = 0
	while spawned[0] < 6 and attempts < 30:
		attempts += 1
		if not endless_director.active_enemies.is_empty():
			var enemy: EnemyController = endless_director.active_enemies[0]
			enemy.health.apply_damage(enemy.health.current)
			_resolve_choices(endless_manager, endless_run)
		await process_frame
	_check(spawned[0] == 6 and endless_director.active_enemies.size() <= 3, "Onda 4 deve criar seis inimigos em lotes", errors)
	_check(endless_director.current_wave == 4 and endless_run.state == RunProgress.RunState.COMBAT, "Onda não termina antes da última derrota", errors)
	for id: Variant in acquired_before.keys():
		_check(endless_manager.get_acquired_count(str(id)) >= int(acquired_before[id]), "Cartas devem persistir entre ondas", errors)
	_check(player.runtime_stats.effective_damage() >= damage_before, "Atributos adquiridos devem persistir", errors)
	endless_director.minimum_player_distance = 999999.0
	for enemy: EnemyController in endless_director.active_enemies.duplicate():
		enemy.health.apply_damage(enemy.health.current)
	_resolve_choices(endless_manager, endless_run)
	for frame: int in range(20):
		await process_frame
	_check(endless_director.current_wave == 5 and not endless_director.active_enemies.is_empty(), "Onda 5 deve avançar mesmo sem spawn ideal", errors)
	_check(spawned[0] > 6 and endless_director.active_enemies.size() <= 3, "Onda 5 deve preservar o limite ativo", errors)
	_check(endless_run.state == RunProgress.RunState.COMBAT, "Modo infinito não deve oferecer a escolha novamente", errors)
	for enemy: EnemyController in endless_director.active_enemies:
		_check(enemy.health.maximum == roundi(enemy.data.max_health * 1.10) and is_equal_approx(enemy.damage_multiplier, 1.04), "Onda 5 deve acumular o escalonamento", errors)
		if enemy.data.max_health == 100:
			_check(enemy.effective_contact_damage() == 21, "Tanque deve aplicar dano de contato escalado", errors)
	_check((load("res://data/chaser.tres") as EnemyData).max_health == 35 and (load("res://data/tank.tres") as EnemyData).contact_damage == 20, "EnemyData compartilhados devem permanecer inalterados", errors)
	attempts = 0
	while spawned[0] < 13 and attempts < 120:
		attempts += 1
		if not endless_director.active_enemies.is_empty():
			var enemy: EnemyController = endless_director.active_enemies[0]
			enemy.health.apply_damage(enemy.health.current)
			_resolve_choices(endless_manager, endless_run)
		await process_frame
	_check(spawned[0] == 13 and endless_director.current_wave == 5, "Onda 5 deve planejar sete inimigos", errors)
	for enemy: EnemyController in endless_director.active_enemies.duplicate():
		enemy.health.apply_damage(enemy.health.current)
	_resolve_choices(endless_manager, endless_run)
	for frame: int in range(10):
		await process_frame
	_check(endless_director.current_wave == 6 and endless_run.state == RunProgress.RunState.COMBAT, "Onda 6 deve começar sem repetir a escolha", errors)
	player.health.configure(100)
	player.health.apply_damage(100)
	var spawned_at_death: int = spawned[0]
	for frame: int in range(10):
		await process_frame
	_check(endless_run.state == RunProgress.RunState.GAME_OVER and spawned[0] == spawned_at_death, "Morte deve cancelar spawns pendentes", errors)
	_check(endless_director.current_wave == 6, "Morte não deve iniciar outra onda", errors)
	endless_main.queue_free()
	await process_frame
	var fresh: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(fresh)
	await physics_frame
	_check(not endless_run.endless_mode and endless_run.selected_mode == RunProgress.GameMode.ENDLESS and (fresh.get_node("WaveDirector") as WaveDirector).current_wave == 1, "Reinício deve limpar progresso e preservar modo infinito", errors)
	_finish(errors)


func _clear_fixed_waves(director: WaveDirector, manager: UpgradeManager, run: RunProgress, errors: Array[String]) -> void:
	for wave_number: int in range(1, 4):
		_check(director.current_wave == wave_number, "Onda fixa incorreta", errors)
		for enemy: EnemyController in director.active_enemies.duplicate():
			enemy.health.apply_damage(enemy.health.current)
		if wave_number == 3:
			await process_frame
			_check(run.pending_level_ups > 0 and run.state == RunProgress.RunState.UPGRADE_SELECTION and director.current_wave == 3, "Escolhas pendentes devem preceder a decisão do modo", errors)
		_resolve_choices(manager, run)
		await physics_frame
		await physics_frame


func _resolve_choices(manager: UpgradeManager, run: RunProgress) -> void:
	while run.pending_level_ups > 0:
		manager.select_upgrade(manager.current_offer[0].upgrade_id)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Endless waves smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
