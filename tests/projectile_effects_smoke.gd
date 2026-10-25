extends SceneTree


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	var burn_script: Script = load("res://scripts/components/burn_component.gd") as Script
	if burn_script == null:
		_finish(["Componente de queimadura deve existir"])
		return
	var errors: Array[String] = []
	var targets: Array[Node2D] = []
	for position_x: int in [80, 160, 240]:
		targets.append(_make_target(position_x, burn_script))
	var arrow: Projectile = (load("res://scenes/combat/arrow.tscn") as PackedScene).instantiate() as Projectile
	root.add_child(arrow)
	arrow.global_position = Vector2.ZERO
	arrow.call("configure", Vector2.RIGHT, 700.0, 10, 1, 3, 3.0)
	for index: int in range(30):
		await physics_frame
	_check((targets[0].get_node("Health") as HealthComponent).current == 25, "Primeiro inimigo deve receber um acerto", errors)
	_check((targets[1].get_node("Health") as HealthComponent).current == 25, "Perfuração deve acertar um segundo inimigo", errors)
	_check((targets[2].get_node("Health") as HealthComponent).current == 35, "Flecha deve desaparecer antes do terceiro inimigo", errors)
	_check(not is_instance_valid(arrow), "Flecha deve ser removida apos esgotar a perfuração", errors)
	for target: Node2D in targets:
		var burn: Node = target.get_node("BurnComponent")
		burn.set_physics_process(false)
	for index: int in range(3):
		for target: Node2D in targets.slice(0, 2):
			target.get_node("BurnComponent").call("_physics_process", 1.0)
	_check((targets[0].get_node("Health") as HealthComponent).current == 16, "Queimadura deve causar 3 dano/s por 3 s", errors)
	_check((targets[1].get_node("Health") as HealthComponent).current == 16, "Queimadura deve atingir o segundo alvo", errors)
	_check((targets[2].get_node("Health") as HealthComponent).current == 35, "Alvo nao atingido nao deve queimar", errors)
	_finish(errors)


func _make_target(position_x: int, burn_script: Script) -> Node2D:
	var target: Node2D = Node2D.new()
	target.position = Vector2(position_x, 0)
	root.add_child(target)
	var health: HealthComponent = HealthComponent.new()
	health.name = "Health"
	target.add_child(health)
	health.configure(35)
	var hurtbox: HurtboxComponent = HurtboxComponent.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 0
	hurtbox.health = health
	target.add_child(hurtbox)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 13.0
	shape.shape = circle
	hurtbox.add_child(shape)
	var burn: Node = Node.new()
	burn.name = "BurnComponent"
	burn.set_script(burn_script)
	burn.set("health", health)
	target.add_child(burn)
	return target


func _check(condition: bool, message: String, errors: Array[String]) -> void:
	if not condition:
		errors.append(message)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("Projectile effects smoke: OK")
		quit(0)
		return
	for message: String in errors:
		push_error(message)
	quit(1)
