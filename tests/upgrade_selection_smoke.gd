extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	(root.get_node("RunManager") as RunProgress).select_mode(RunProgress.GameMode.ENDLESS)
	var errors: Array[String] = []
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var manager: Node = main.get_node_or_null("UpgradeManager")
	var screen: CanvasLayer = main.get_node_or_null("UpgradeScreen") as CanvasLayer
	if manager == null or screen == null:
		_finish(["Main precisa de UpgradeManager e UpgradeScreen"])
		return
	var run_manager: RunProgress = root.get_node("RunManager") as RunProgress
	var definitions: Array = manager.get("definitions")
	_check(definitions.size() == 8, "Catalogo inicial deve conter oito cartas", errors)
	var all_ids: Dictionary = {}
	for definition: Resource in definitions:
		all_ids[definition.get("upgrade_id")] = true
		_check(definition.get("icon") != null, "Cada carta precisa de icone", errors)
	_check(all_ids.size() == 8, "IDs das cartas devem ser diferentes", errors)

	manager.owned_counts["UPG-006"] = 1
	manager.owned_counts["UPG-007"] = 1
	for index: int in range(12):
		var offer: Array = manager.call("roll_offer")
		var offer_ids: Dictionary = {}
		for definition: Resource in offer:
			offer_ids[definition.get("upgrade_id")] = true
		_check(offer.size() == 3 and offer_ids.size() == 3, "Oferta deve ter tres cartas diferentes", errors)
		_check(not offer_ids.has("UPG-006") and not offer_ids.has("UPG-007"), "Habilidades unicas adquiridas devem sair do sorteio", errors)
	manager.owned_counts.clear()

	run_manager.add_experience(100)
	_check(run_manager.pending_level_ups == 3, "100 XP devem gerar tres escolhas pendentes", errors)
	_check(paused and screen.visible, "Selecao deve mostrar a tela e pausar o combate", errors)
	_check(screen.process_mode == Node.PROCESS_MODE_ALWAYS, "Cartas devem receber entrada durante a pausa", errors)
	var first_offer: Array = manager.get("current_offer")
	var first_id: String = first_offer[0].get("upgrade_id")
	var first_button: Button = screen.get_node("Overlay/Panel/Content/Cards/Card1") as Button
	first_button.pressed.emit()
	_check(manager.call("get_acquired_count", first_id) == 1, "Clique deve escolher exatamente uma carta", errors)
	_check(run_manager.pending_level_ups == 2 and paused, "Outra evolucao deve aparecer sem retomar o combate", errors)
	for index: int in range(2):
		var offer: Array = manager.get("current_offer")
		manager.call("select_upgrade", offer[0].get("upgrade_id"))
	_check(run_manager.pending_level_ups == 0, "Todas as escolhas pendentes devem ser consumidas", errors)
	_check(not paused and not screen.visible, "Combate deve retomar apos a ultima escolha", errors)
	manager.call("select_upgrade", first_id)
	_check(run_manager.pending_level_ups == 0, "Clique extra nao deve aplicar outra carta", errors)
	await physics_frame
	var director: WaveDirector = main.get_node("SessionRoot/EndlessSession/WaveDirector") as WaveDirector
	_check(director.current_wave == 1 and director.active_enemies.size() == 4, "Primeira onda deve estar ativa", errors)
	var remaining_enemies: Array[EnemyController] = director.active_enemies.duplicate()
	for enemy: EnemyController in remaining_enemies:
		enemy.health.apply_damage(enemy.health.current)
	_check(paused and run_manager.pending_level_ups == 1, "Ultima derrota da onda deve pausar para a nova carta", errors)
	await process_frame
	_check(director.current_wave == 1, "Onda seguinte deve aguardar a escolha pendente", errors)
	var transition_offer: Array = manager.get("current_offer")
	manager.call("select_upgrade", transition_offer[0].get("upgrade_id"))
	await process_frame
	_check(director.current_wave == 2 and not paused, "Onda seguinte deve iniciar apos a escolha", errors)
	_finish(errors)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Upgrade selection smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
