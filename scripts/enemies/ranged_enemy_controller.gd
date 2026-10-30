extends EnemyController
class_name RangedEnemyController

signal projectile_fired(projectile: Projectile)

@export var projectile_scene: PackedScene

@onready var projectile_origin: Marker2D = $ProjectileOrigin

var _attack_time_left: float = 0.0


func _physics_process(delta: float) -> void:
	if not can_act():
		velocity = Vector2.ZERO
		return
	var to_player: Vector2 = target.global_position - global_position
	var distance: float = to_player.length()
	if distance < data.preferred_distance - data.distance_tolerance:
		velocity = -to_player.normalized() * data.move_speed
	elif distance > data.preferred_distance + data.distance_tolerance:
		velocity = to_player.normalized() * data.move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_attack_time_left = maxf(0.0, _attack_time_left - delta)
	if _attack_time_left <= 0.0:
		_fire_at_player()


func _fire_at_player() -> void:
	if projectile_scene == null:
		return
	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	if projectile == null:
		return
	get_parent().add_child(projectile)
	projectile.global_position = projectile_origin.global_position
	projectile.configure(target.global_position - projectile.global_position, data.projectile_speed, effective_projectile_damage())
	_attack_time_left = data.attack_interval
	projectile_fired.emit(projectile)
