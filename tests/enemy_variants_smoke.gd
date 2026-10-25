extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var ranged_scene: PackedScene = load("res://scenes/enemies/ranged_enemy.tscn") as PackedScene
	var tank_scene: PackedScene = load("res://scenes/enemies/tank.tscn") as PackedScene
	if ranged_scene == null or tank_scene == null:
		_finish(["Cenas do atirador e do tanque devem carregar"])
		return

	var world: Node2D = Node2D.new()
	root.add_child(world)
	var player: PlayerController = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerController
	world.add_child(player)
	var ranged: EnemyController = ranged_scene.instantiate() as EnemyController
	ranged.target = player
	world.add_child(ranged)
	ranged.global_position = player.global_position + Vector2(100, 0)
	_check(ranged.health.current == 25, "Atirador deve ter 25 HP", errors)
	_check(ranged.data.move_speed == 80.0 and ranged.data.xp_reward == 15, "Velocidade e XP do atirador devem seguir o GDD", errors)
	_check(is_equal_approx(ranged.data.attack_interval, 1.8), "Atirador deve disparar a cada 1,8 s", errors)
	_check(ranged.data.projectile_damage == 7, "Projetil do atirador deve causar 7 de dano", errors)
	var shots: Array[Projectile] = []
	ranged.projectile_fired.connect(func(projectile: Projectile) -> void: shots.append(projectile))
	var initial_distance: float = ranged.global_position.distance_to(player.global_position)
	for index: int in range(35):
		await physics_frame
	_check(ranged.global_position.distance_to(player.global_position) > initial_distance, "Atirador deve recuar quando o jogador se aproxima", errors)
	_check(shots.size() == 1, "Atirador deve disparar uma vez no primeiro intervalo", errors)
	_check(player.health.current == 93, "Projetil inimigo deve causar 7 de dano ao jogador", errors)
	_check(ranged.health.current == 25, "Atirador nao deve receber dano do proprio projetil", errors)
	for index: int in range(85):
		await physics_frame
	_check(shots.size() == 2, "Atirador deve respeitar o intervalo de 1,8 s", errors)
	var ranged_rewards: Array[int] = []
	ranged.enemy_defeated.connect(func(xp: int) -> void: ranged_rewards.append(xp))
	ranged.health.apply_damage(ranged.health.current)
	_check(ranged_rewards == [15], "Atirador deve emitir 15 XP ao morrer", errors)
	for shot: Projectile in shots:
		if is_instance_valid(shot):
			shot.queue_free()
	await physics_frame

	player.health.configure(100, player.stats.hurt_invulnerability)
	var tank: EnemyController = tank_scene.instantiate() as EnemyController
	tank.target = player
	world.add_child(tank)
	tank.global_position = player.global_position + Vector2(180, 0)
	_check(tank.health.current == 100, "Tanque deve ter 100 HP", errors)
	_check(tank.data.move_speed == 65.0 and tank.data.contact_damage == 20 and tank.data.xp_reward == 25, "Atributos do tanque devem seguir o GDD", errors)
	var tank_distance: float = tank.global_position.distance_to(player.global_position)
	for index: int in range(10):
		await physics_frame
	_check(tank.global_position.distance_to(player.global_position) < tank_distance, "Tanque deve perseguir o jogador", errors)
	tank.global_position = player.global_position + Vector2(22, 0)
	for index: int in range(3):
		await physics_frame
	_check(player.health.current == 80, "Contato do tanque deve causar 20 de dano", errors)
	var rewards: Array[int] = []
	tank.enemy_defeated.connect(func(xp: int) -> void: rewards.append(xp))
	_check(tank.get_node("Hurtbox").receive_damage(100), "Tanque deve receber dano letal", errors)
	_check(rewards == [25], "Tanque deve emitir 25 XP ao morrer", errors)
	await physics_frame
	_check(not is_instance_valid(tank), "Tanque derrotado deve ser removido", errors)
	_finish(errors)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Enemy variants smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
