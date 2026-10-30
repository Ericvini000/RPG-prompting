extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	var player: PlayerController = main.get_node("Arena01/Player") as PlayerController
	var manager: UpgradeManager = main.get_node("UpgradeManager") as UpgradeManager
	var results: ResultScreen = main.get_node("ResultScreen") as ResultScreen
	await physics_frame

	run.toggle_pause()
	var dashboard: Control = results.get_node("Overlay/Panel/Content/PauseDashboard") as Control
	var values: Label = dashboard.get_node("Columns/StatsFrame/Stats/Values") as Label
	var list: VBoxContainer = dashboard.get_node("Columns/CardsFrame/Cards/Scroll/List") as VBoxContainer
	var progress: Label = dashboard.get_node("Progress") as Label
	_check(paused and results.visible and dashboard.visible, "Pausa deve exibir o painel", errors)
	_check(values.text.contains("Vida: 100 / 100") and values.text.contains("Ataques por segundo: 1.67"), "Valores iniciais devem refletir o gameplay", errors)
	_check(list.get_child_count() == 1 and (list.get_child(0) as Label).text.contains("Nenhuma carta"), "Lista vazia deve ser informativa", errors)
	_check(progress.text.contains("Nível 1") and progress.text.contains("XP 0 / 20") and progress.text.contains("Onda 1"), "Progresso inicial deve aparecer", errors)
	run.toggle_pause()
	_check(not paused and not results.visible, "Esc deve retomar o combate", errors)

	var damage: UpgradeDefinition = load("res://data/upgrades/damage.tres") as UpgradeDefinition
	var rapid: UpgradeDefinition = load("res://data/upgrades/rapid.tres") as UpgradeDefinition
	var triple: UpgradeDefinition = load("res://data/upgrades/triple.tres") as UpgradeDefinition
	var fire: UpgradeDefinition = load("res://data/upgrades/fire.tres") as UpgradeDefinition
	player.apply_upgrade(damage)
	player.apply_upgrade(damage)
	player.apply_upgrade(rapid)
	player.apply_upgrade(triple)
	player.apply_upgrade(fire)
	manager.owned_counts[damage.upgrade_id] = 2
	manager.owned_counts[rapid.upgrade_id] = 1
	manager.owned_counts[triple.upgrade_id] = 1
	manager.owned_counts[fire.upgrade_id] = 1
	player.health.apply_damage(10)
	run.toggle_pause()
	_check(values.text.contains("Vida: 90 / 100") and values.text.contains("Dano por flecha: 14"), "Vida e dano efetivo devem atualizar", errors)
	_check(values.text.contains("Ataques por segundo: 1.92") and values.text.contains("Flechas por disparo: 3"), "Cadência e disparo triplo devem atualizar", errors)
	_check(values.text.contains("Flecha Flamejante") and values.text.contains("3 dano/s por 3 s"), "Habilidade elemental deve aparecer", errors)
	_check(list.get_child_count() == 4, "Cartas adquiridas devem ser agrupadas", errors)
	_check((list.get_child(0).get_child(1) as Label).text.contains("×2"), "Carta repetida deve mostrar contagem", errors)
	_check((list.get_child(0).get_child(0) as TextureRect).texture == damage.icon, "Ícone deve vir da definição", errors)
	_check((dashboard.get_node("Columns/CardsFrame/Cards/Scroll") as ScrollContainer).vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED, "Lista deve permitir rolagem", errors)
	_check(run.level == 1 and manager.get_acquired_count(damage.upgrade_id) == 2, "Consulta não deve alterar o estado", errors)
	for definition: UpgradeDefinition in manager.definitions:
		manager.owned_counts[definition.upgrade_id] = 1
	(dashboard.get_node("Columns/CardsFrame/Cards") as PauseCardsPanel).refresh(manager)
	await process_frame
	var scroll: ScrollContainer = dashboard.get_node("Columns/CardsFrame/Cards/Scroll") as ScrollContainer
	_check(list.get_child_count() == 8 and scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page, "Lista longa deve ser rolável", errors)
	run.toggle_pause()
	run.request_victory()
	_check(results.visible and not dashboard.visible and not results.get_node("Overlay/Panel/Content/Resume").visible, "Vitória não deve exibir painel de pausa", errors)
	main.queue_free()
	await process_frame
	var second: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(second)
	var second_results: ResultScreen = second.get_node("ResultScreen") as ResultScreen
	var second_player: PlayerController = second.get_node("Arena01/Player") as PlayerController
	await physics_frame
	_check(second_player.runtime_stats.effective_damage() == 10 and (second.get_node("UpgradeManager") as UpgradeManager).get_acquired_upgrades().is_empty(), "Nova partida deve limpar melhorias", errors)
	second_player.health.apply_damage(second_player.health.current)
	_check(second_results.visible and not second_results.get_node("Overlay/Panel/Content/PauseDashboard").visible, "Derrota não deve exibir painel de pausa", errors)
	_finish(errors)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Pause menu smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
