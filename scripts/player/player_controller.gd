extends CharacterBody2D
class_name PlayerController

signal arrow_fired(arrow: Projectile)

@export var stats: PlayerStats
@export var arrow_scene: PackedScene

@onready var visuals: Node2D = $Visuals
@onready var bow_pivot: Node2D = $Visuals/BowPivot
@onready var bow_origin: Marker2D = $Visuals/BowPivot/BowOrigin
@onready var health: HealthComponent = $HealthComponent

var _aim_direction: Vector2 = Vector2.RIGHT
var _move_direction: Vector2 = Vector2.ZERO
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _animation_time: float = 0.0
var _attack_time_left: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if stats == null:
		push_error("Player precisa de PlayerStats.")
		set_physics_process(false)
		return
	health.configure(stats.max_health, stats.hurt_invulnerability)
	health.died.connect(_on_died)
	$Camera2D.make_current()


func _physics_process(delta: float) -> void:
	if health.current <= 0:
		velocity = Vector2.ZERO
		return
	_move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	aim_at(get_global_mouse_position())
	_attack_time_left = maxf(_attack_time_left - delta, 0.0)
	if Input.is_action_pressed("attack") and _attack_time_left <= 0.0:
		fire_at(get_global_mouse_position())

	if Input.is_action_just_pressed("dash") and can_dash():
		_dash_direction = _move_direction if not _move_direction.is_zero_approx() else _aim_direction
		_dash_time_left = stats.dash_duration
		_dash_cooldown_left = stats.dash_cooldown

	velocity = _dash_direction * stats.dash_speed if is_dashing() else _move_direction * stats.move_speed
	move_and_slide()

	_dash_time_left = maxf(_dash_time_left - delta, 0.0)
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_animate(delta)


func fire_at(world_position: Vector2) -> Projectile:
	if health.current <= 0 or arrow_scene == null:
		return null
	aim_at(world_position)
	var arrow: Projectile = arrow_scene.instantiate() as Projectile
	if arrow == null:
		return null
	get_parent().add_child(arrow)
	arrow.global_position = bow_origin.global_position
	arrow.configure(_aim_direction, stats.arrow_speed, roundi(stats.base_damage))
	_attack_time_left = stats.attack_interval
	arrow_fired.emit(arrow)
	return arrow


func aim_at(world_position: Vector2) -> void:
	var offset: Vector2 = world_position - bow_pivot.global_position
	if offset.is_zero_approx():
		return
	_aim_direction = offset.normalized()
	bow_pivot.global_rotation = _aim_direction.angle()


func can_dash() -> bool:
	return _dash_cooldown_left <= 0.0 and not is_dashing()


func is_dashing() -> bool:
	return _dash_time_left > 0.0


func is_invulnerable() -> bool:
	return is_dashing()


func _on_died() -> void:
	visuals.modulate = Color(0.55, 0.55, 0.55, 1.0)


func _animate(delta: float) -> void:
	var moving: bool = not _move_direction.is_zero_approx() or is_dashing()
	if moving:
		_animation_time += delta * (18.0 if is_dashing() else 11.0)
	var bob: float = sin(_animation_time) * 2.0 if moving else 0.0
	visuals.position.y = lerpf(visuals.position.y, bob, minf(delta * 12.0, 1.0))
	var target_scale: Vector2 = Vector2(1.12, 0.88) if is_dashing() else Vector2.ONE
	visuals.scale = visuals.scale.lerp(target_scale, minf(delta * 16.0, 1.0))
