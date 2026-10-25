extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	var player: PlayerController = main.get_node("Arena01/Player") as PlayerController
	var director: WaveDirector = main.get_node("WaveDirector") as WaveDirector
	var manager: UpgradeManager = main.get_node("UpgradeManager") as UpgradeManager
	var hud: Control = main.get_node("HUD/Overlay") as Control
	var results: CanvasLayer = main.get_node("ResultScreen") as CanvasLayer
	await physics_frame
	_check(hud != null and results != null, "HUD e tela de resultado devem existir", errors)
	_check(run.state == RunProgress.RunState.COMBAT, "Partida deve iniciar em combate", errors)
	_check(director.current_wave == 1, "Primeira onda deve iniciar", errors)
	_check(str(hud.get_node("Top/Health/Value").text).contains("100"), "HUD deve exibir vida inicial", errors)
	player.health.apply_damage(10)
	_check(str(hud.get_node("Top/Health/Value").text).contains("90"), "HUD deve atualizar vida", errors)
	_check(float(player.get("_hurt_flash_left")) > 0.0, "Dano deve gerar feedback visual", errors)
	run.add_experience(20)
	_check(run.state == RunProgress.RunState.UPGRADE_SELECTION, "Subida de nivel deve pausar", errors)
	_check(str(hud.get_node("Top/Progress/Level").text).contains("2"), "HUD deve atualizar nivel", errors)
	run.request_victory()
	_check(run.state == RunProgress.RunState.UPGRADE_SELECTION, "Vitoria deve esperar carta pendente", errors)
	manager.select_upgrade(manager.current_offer[0].upgrade_id)
	_check(run.state == RunProgress.RunState.VICTORY and results.visible, "Vitoria deve aparecer apos escolha", errors)
	_check(get_tree_paused(), "Vitoria deve pausar a arena", errors)
	main.queue_free()
	await process_frame

	var second: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(second)
	var second_run: RunProgress = root.get_node("RunManager") as RunProgress
	var second_player: PlayerController = second.get_node("Arena01/Player") as PlayerController
	var second_results: CanvasLayer = second.get_node("ResultScreen") as CanvasLayer
	await physics_frame
	_check(second_run.level == 1 and second_run.pending_level_ups == 0 and second_run.state == RunProgress.RunState.COMBAT, "Reinicio deve limpar progresso e estado", errors)
	_check(second_player.runtime_stats.triple_shot == false and second_player.health.current == 100, "Reinicio deve limpar melhorias e vida", errors)
	second_run.toggle_pause()
	_check(get_tree_paused() and second_results.visible, "Pausa normal deve abrir menu", errors)
	_check(str(second_results.get_node("Overlay/Panel/Content/Title").text) == "PAUSA", "Menu de pausa deve identificar estado", errors)
	second_run.toggle_pause()
	_check(not get_tree_paused() and not second_results.visible, "Retomar deve fechar menu", errors)
	second_player.health.apply_damage(second_player.health.current)
	_check(second_run.state == RunProgress.RunState.GAME_OVER and second_results.visible, "Morte deve exibir derrota", errors)
	second_run.toggle_pause()
	_check(second_run.state == RunProgress.RunState.GAME_OVER and paused, "Pausa normal nao deve sobrescrever derrota", errors)
	current_scene = second
	(second_results.get_node("Overlay/Panel/Content/Restart") as Button).pressed.emit()
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene != second and second_run.state == RunProgress.RunState.COMBAT, "Botao reiniciar deve recarregar partida", errors)
	_check((current_scene.get_node("WaveDirector") as WaveDirector).current_wave == 1, "Reinicio deve restaurar primeira onda", errors)
	_finish(errors)


func get_tree_paused() -> bool:
	return paused


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Run flow smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
