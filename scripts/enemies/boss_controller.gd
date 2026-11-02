extends ContactEnemyController
class_name BossController

signal projectile_fired(projectile: Projectile)

@export var projectile_scene: PackedScene
@export var warning_duration: float = 0.6
@export var fan_count: int = 3
@export var radial_count: int = 8
@export var fan_spread: float = 0.25

var _volley_wait: float = 0.0
var _warning_left: float = 0.0
var _pattern: int = 0
var _aim: Vector2 = Vector2.RIGHT

func _ready() -> void:
	super._ready()
	add_to_group("bosses")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not can_act():
		return
	if _warning_left > 0.0:
		_warning_left = maxf(0.0, _warning_left - delta)
		queue_redraw()
		if _warning_left <= 0.0:
			_fire_pattern()
	else:
		_volley_wait = maxf(0.0, _volley_wait - delta)
		if _volley_wait <= 0.0:
			_aim = (target.global_position - ($ProjectileOrigin as Marker2D).global_position).normalized()
			_warning_left = warning_duration
			queue_redraw()

func _directions() -> Array[Vector2]:
	var directions: Array[Vector2] = []
	var count: int = fan_count if _pattern == 0 else radial_count
	for index: int in range(count):
		var angle: float = _aim.angle() + (index - (count - 1) * 0.5) * fan_spread if _pattern == 0 else TAU * index / count
		directions.append(Vector2.from_angle(angle))
	return directions

func _fire_pattern() -> void:
	for direction: Vector2 in _directions():
		var projectile: Projectile = projectile_scene.instantiate() as Projectile
		projectile.configure(direction, data.projectile_speed, effective_projectile_damage())
		get_parent().add_child(projectile)
		projectile.global_position = ($ProjectileOrigin as Marker2D).global_position
		projectile_fired.emit(projectile)
	_pattern = 1 - _pattern
	_volley_wait = data.attack_interval

func _draw() -> void:
	if _warning_left <= 0.0:
		return
	for direction: Vector2 in _directions():
		draw_line(Vector2(0, -35), Vector2(0, -35) + direction * 260.0, Color(1.0, 0.55, 0.25, 0.65), 4.0)
