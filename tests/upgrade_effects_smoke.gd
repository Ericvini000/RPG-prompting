extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var world: Node2D = Node2D.new()
	root.add_child(world)
	var player: PlayerController = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerController
	world.add_child(player)
	var runtime: Object = player.get("runtime_stats")
	if runtime == null or not player.has_method("apply_upgrade"):
		_finish(["Arqueiro precisa de atributos efetivos e aplicação de cartas"])
		return
	var base: PlayerStats = player.stats
	var cards: Dictionary = {}
	for file_name: String in ["damage", "rapid", "agility", "vitality", "pierce", "triple", "fire", "dash"]:
		var definition: UpgradeDefinition = load("res://data/upgrades/" + file_name + ".tres") as UpgradeDefinition
		cards[file_name] = definition
	_check(runtime.call("effective_damage") == 10, "Dano inicial deve ser 10", errors)
	_check(is_equal_approx(runtime.call("effective_attack_interval"), 0.6), "Intervalo inicial deve ser 0,60 s", errors)
	_check(is_equal_approx(runtime.call("effective_move_speed"), 230.0), "Movimento inicial deve ser 230 px/s", errors)

	player.apply_upgrade(cards["damage"])
	player.apply_upgrade(cards["damage"])
	_check(runtime.call("effective_damage") == 14, "Duas cartas de dano devem somar 40%", errors)
	player.apply_upgrade(cards["rapid"])
	player.apply_upgrade(cards["rapid"])
	_check(is_equal_approx(runtime.call("effective_attack_interval"), 0.6 / 1.3), "Velocidade de ataque deve acumular pelo divisor do GDD", errors)
	player.apply_upgrade(cards["agility"])
	player.apply_upgrade(cards["agility"])
	_check(is_equal_approx(runtime.call("effective_move_speed"), 230.0 * 1.24), "Duas cartas de movimento devem somar 24%", errors)

	player.health.apply_damage(10)
	player.apply_upgrade(cards["vitality"])
	_check(player.health.maximum == 125 and player.health.current == 115, "Vitalidade deve aumentar vida máxima e atual em 25", errors)
	player.apply_upgrade(cards["vitality"])
	_check(player.health.maximum == 150 and player.health.current == 140, "Vitalidade deve acumular", errors)
	player.apply_upgrade(cards["pierce"])
	player.apply_upgrade(cards["pierce"])
	_check(runtime.get("pierce_count") == 2, "Perfuração deve somar um inimigo adicional por carta", errors)
	player.apply_upgrade(cards["triple"])
	player.apply_upgrade(cards["fire"])
	_check(runtime.get("triple_shot") and runtime.get("fire_arrow"), "Habilidades especiais devem ativar", errors)
	player.apply_upgrade(cards["dash"])
	player.apply_upgrade(cards["dash"])
	_check(is_equal_approx(runtime.call("effective_dash_cooldown"), 1.2 * 0.85 * 0.85), "Dash deve reduzir recarga em 15% por carta", errors)

	var arrows: Array[Projectile] = []
	player.arrow_fired.connect(func(arrow: Projectile) -> void: arrows.append(arrow))
	player.fire_at(player.global_position + Vector2(300, 0))
	_check(arrows.size() == 3, "Disparo Triplo deve criar tres flechas", errors)
	if arrows.size() == 3:
		_check(arrows[0].damage == 14 and arrows[0].get("remaining_pierces") == 2, "Flechas devem usar dano e perfuração efetivos", errors)
		_check(arrows[0].get("burn_damage_per_second") == 3 and is_equal_approx(arrows[0].get("burn_duration"), 3.0), "Flechas devem carregar queimadura", errors)
		_check(absf(arrows[1].direction.angle() - arrows[0].direction.angle()) > 0.1 and absf(arrows[2].direction.angle() - arrows[0].direction.angle()) > 0.1, "Flechas laterais devem ter dispersão angular", errors)
	_check(base.max_health == 100 and base.base_damage == 10.0 and base.move_speed == 230.0 and base.dash_cooldown == 1.2, "Cartas nao devem modificar o Resource básico", errors)
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var game_player: PlayerController = main.get_node("Arena01/Player") as PlayerController
	var manager: UpgradeManager = main.get_node("UpgradeManager") as UpgradeManager
	var before: Array = _combat_signature(game_player)
	(root.get_node("RunManager") as RunProgress).add_experience(20)
	var offered: UpgradeDefinition = manager.current_offer[0]
	manager.select_upgrade(offered.upgrade_id)
	_check(_combat_signature(game_player) != before, "Escolher uma carta deve alterar o combate do arqueiro", errors)
	_check(manager.get_acquired_count(offered.upgrade_id) == 1, "Carta aplicada deve constar na partida", errors)
	_finish(errors)


func _combat_signature(player: PlayerController) -> Array:
	var runtime: PlayerRuntimeStats = player.runtime_stats
	return [runtime.effective_damage(), runtime.effective_attack_interval(), runtime.effective_move_speed(), player.health.maximum, runtime.pierce_count, runtime.triple_shot, runtime.fire_arrow, runtime.effective_dash_cooldown()]


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Upgrade effects smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
