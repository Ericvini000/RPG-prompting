extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var arena: Node2D = (load("res://scenes/arena_01.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(arena)
	var player: PlayerController = arena.get_node("Player") as PlayerController
	var chaser: EnemyController = (load("res://scenes/enemies/chaser.tscn") as PackedScene).instantiate() as EnemyController
	chaser.target = player
	arena.add_child(chaser)
	chaser.global_position = (arena.get_node("Spawns/EnemySpawn01") as Marker2D).global_position
	var player_health: HealthComponent = player.health
	var chaser_health: HealthComponent = chaser.health
	_check(player_health.current == 100, "Arqueiro deve iniciar com 100 de vida", errors)
	_check(chaser_health.current == 35, "Perseguidor deve iniciar com 35 de vida", errors)
	_check(chaser.data.move_speed == 120.0 and chaser.data.contact_damage == 10 and chaser.data.xp_reward == 10, "Atributos do perseguidor devem seguir o GDD", errors)

	var initial_distance: float = chaser.global_position.distance_to(player.global_position)
	for index: int in range(12):
		await physics_frame
	_check(chaser.global_position.distance_to(player.global_position) < initial_distance, "Perseguidor deve se aproximar do arqueiro", errors)

	chaser.global_position = player.global_position + Vector2(22, 0)
	for index: int in range(3):
		await physics_frame
	_check(player_health.current == 90, "Contato deve causar 10 de dano uma vez", errors)
	_check(not player.get_node("Hurtbox").receive_damage(10), "Acerto imediato repetido deve ser ignorado", errors)
	_check(player_health.current == 90, "Invulnerabilidade apos dano deve preservar a vida", errors)

	chaser.set_physics_process(false)
	chaser.global_position = player.global_position + Vector2(140, 0)
	var arrow: Projectile = player.fire_at(chaser.global_position)
	_check(arrow != null, "Arqueiro deve disparar flecha", errors)
	for index: int in range(30):
		await physics_frame
	_check(chaser_health.current == 25, "Flecha deve causar 10 de dano uma vez", errors)
	_check(not is_instance_valid(arrow), "Flecha deve desaparecer apos atingir o inimigo", errors)
	_check(player_health.current == 90, "Flecha nao deve atingir o arqueiro", errors)

	var rewards: Array[int] = []
	chaser.enemy_defeated.connect(func(xp: int) -> void: rewards.append(xp))
	_check((chaser.get_node("Hurtbox") as HurtboxComponent).receive_damage(25), "Dano letal deve ser recebido", errors)
	_check(rewards == [10], "Morte deve emitir 10 XP uma unica vez", errors)
	await physics_frame
	_check(not is_instance_valid(chaser), "Inimigo morto deve ser removido", errors)
	var pillar: StaticBody2D = arena.get_node("Obstacles/Pillar01") as StaticBody2D
	var blocked_arrow: Projectile = player.fire_at(pillar.global_position)
	_check(blocked_arrow != null, "Arqueiro deve conseguir atirar contra obstaculos", errors)
	for index: int in range(25):
		await physics_frame
	_check(not is_instance_valid(blocked_arrow), "Flecha deve desaparecer ao tocar o obstaculo", errors)
	for index: int in range(37):
		await physics_frame

	var fired: Array[Projectile] = []
	player.arrow_fired.connect(func(shot: Projectile) -> void: fired.append(shot))
	Input.action_press("attack")
	for index: int in range(45):
		await physics_frame
	Input.action_release("attack")
	_check(fired.size() == 2, "Ataque pressionado deve respeitar intervalo de 0,60 s; observado: " + str(fired.size()), errors)
	var player_hurtbox: HurtboxComponent = player.get_node("Hurtbox") as HurtboxComponent
	Input.action_press("dash")
	await physics_frame
	await physics_frame
	Input.action_release("dash")
	_check(player.is_dashing(), "Dash deve iniciar no teste de dano", errors)
	_check(not player_hurtbox.receive_damage(10), "Dash deve impedir dano recebido", errors)
	for index: int in range(12):
		await physics_frame
	_check(player_hurtbox.receive_damage(10), "Dano deve voltar a funcionar apos invulnerabilidade", errors)
	_check(player_health.current == 80, "Vida deve refletir segundo acerto valido", errors)

	if errors.is_empty():
		print("Combat smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)
