extends Area2D
class_name Projectile

@export var maximum_lifetime: float = 1.5

var direction: Vector2 = Vector2.RIGHT
var speed: float = 700.0
var damage: int = 10
var remaining_pierces: int = 0
var burn_damage_per_second: int = 0
var burn_duration: float = 0.0
var _lifetime_left: float = 0.0
var _spent: bool = false
var _hit_areas: Dictionary = {}


func _ready() -> void:
	_lifetime_left = maximum_lifetime
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()


func configure(aim_direction: Vector2, arrow_speed: float, arrow_damage: int, extra_pierces: int = 0, burn_dps: int = 0, fire_duration: float = 0.0) -> void:
	direction = aim_direction.normalized()
	speed = arrow_speed
	damage = arrow_damage
	remaining_pierces = maxi(0, extra_pierces)
	burn_damage_per_second = maxi(0, burn_dps)
	burn_duration = maxf(0.0, fire_duration)
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if _spent:
		return
	global_position += direction * speed * delta
	_lifetime_left -= delta
	if _lifetime_left <= 0.0:
		_spend()


func _on_area_entered(area: Area2D) -> void:
	if _spent or not area is HurtboxComponent:
		return
	var area_id: int = area.get_instance_id()
	if _hit_areas.has(area_id):
		return
	if not (area as HurtboxComponent).receive_damage(damage):
		return
	_hit_areas[area_id] = true
	if burn_damage_per_second > 0 and burn_duration > 0.0:
		var burn: BurnComponent = area.get_parent().get_node_or_null("BurnComponent") as BurnComponent
		if burn != null:
			burn.apply_burn(burn_damage_per_second, burn_duration)
	if remaining_pierces > 0:
		remaining_pierces -= 1
	else:
		_spend()


func _on_body_entered(_body: Node2D) -> void:
	_spend()


func _spend() -> void:
	if _spent:
		return
	_spent = true
	set_deferred("monitoring", false)
	queue_free()
