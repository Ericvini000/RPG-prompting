extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var errors: Array[String] = []
	var health: HealthComponent = HealthComponent.new()
	root.add_child(health)
	health.configure(100, 0.5)
	_check(health.apply_damage(10) and health.current == 90, "Primeiro acerto deve causar dano", errors)
	_check(not health.apply_damage(10) and health.current == 90, "Acerto repetido deve ser bloqueado", errors)
	for index: int in range(32):
		await physics_frame
	_check(health.apply_damage(10) and health.current == 80, "Dano deve voltar apos invulnerabilidade", errors)

	var target: Node2D = Node2D.new()
	root.add_child(target)
	target.position = Vector2(120, 0)
	var target_health: HealthComponent = HealthComponent.new()
	target.add_child(target_health)
	target_health.configure(35)
	var hurtbox: HurtboxComponent = HurtboxComponent.new()
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 0
	hurtbox.health = target_health
	target.add_child(hurtbox)
	var collision: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 13.0
	collision.shape = circle
	hurtbox.add_child(collision)

	var arrow: Projectile = (load("res://scenes/combat/arrow.tscn") as PackedScene).instantiate() as Projectile
	root.add_child(arrow)
	arrow.global_position = Vector2.ZERO
	arrow.configure(Vector2.RIGHT, 700.0, 10)
	for index: int in range(20):
		await physics_frame
	_check(target_health.current == 25, "Flecha deve causar 10 de dano uma vez", errors)
	_check(not is_instance_valid(arrow), "Flecha deve desaparecer apos impacto", errors)

	if errors.is_empty():
		print("Projectile smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)
