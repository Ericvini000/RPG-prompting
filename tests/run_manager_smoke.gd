extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var manager: Node = root.get_node_or_null("RunManager")
	if manager == null:
		_finish(["RunManager deve existir como Autoload"])
		return
	var errors: Array[String] = []
	var progress_events: Array[Vector2i] = []
	var level_requests: Array[int] = [0]
	manager.connect("experience_changed", func(xp: int, required: int) -> void: progress_events.append(Vector2i(xp, required)))
	manager.connect("level_up_requested", func() -> void: level_requests[0] += 1)
	manager.call("reset_run")
	_check(manager.get("level") == 1 and manager.get("experience") == 0, "Partida deve iniciar no nivel 1 com 0 XP", errors)
	for level: int in range(1, 5):
		_check(manager.call("required_experience_for_level", level) == 20 + 10 * (level - 1), "Formula de XP incorreta no nivel " + str(level), errors)
	manager.call("add_experience", 0)
	manager.call("add_experience", -10)
	_check(level_requests[0] == 0 and manager.get("experience") == 0, "XP nao positivo deve ser ignorado", errors)

	manager.call("add_experience", 20)
	_check(manager.get("level") == 2 and manager.get("experience") == 0, "Limiar exato deve subir um nivel sem XP excedente", errors)
	_check(manager.get("pending_level_ups") == 1 and level_requests[0] == 1, "Primeira evolucao deve ficar pendente", errors)
	_check(progress_events.back() == Vector2i(0, 30), "Sinal deve informar XP e proximo limiar", errors)

	manager.call("add_experience", 120)
	_check(manager.get("level") == 5 and manager.get("experience") == 0, "Uma recompensa deve permitir varias evolucoes", errors)
	_check(manager.get("pending_level_ups") == 4 and level_requests[0] == 4, "Cada nivel deve gerar uma escolha pendente", errors)
	manager.call("add_experience", 65)
	_check(manager.get("level") == 6 and manager.get("experience") == 5, "XP excedente deve ser preservado", errors)
	_check(manager.get("pending_level_ups") == 5 and level_requests[0] == 5, "Evolucao posterior deve entrar na fila", errors)
	_check(progress_events.back() == Vector2i(5, 70), "Sinal deve refletir o proximo limiar apos XP excedente", errors)
	for index: int in range(5):
		_check(manager.call("consume_pending_level_up"), "Escolha pendente deve ser consumida uma vez", errors)
	_check(not manager.call("consume_pending_level_up"), "Fila vazia nao deve gerar escolha extra", errors)
	_check(manager.get("pending_level_ups") == 0 and manager.get("experience") == 5, "Consumir escolhas nao deve apagar XP", errors)
	manager.call("reset_run")
	_check(manager.get("level") == 1 and manager.get("experience") == 0 and manager.get("pending_level_ups") == 0, "Nova partida deve limpar a progressao", errors)
	_check(progress_events.back() == Vector2i(0, 20), "Reset deve publicar progresso inicial", errors)
	_finish(errors)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Run manager smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
