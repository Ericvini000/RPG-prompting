extends Area2D
class_name Projectile

@export var maximum_lifetime: float = 1.5

var direction: Vector2 = Vector2.RIGHT
var speed: float = 700.0
var damage: int = 10
var _lifetime_left: float = 0.0
var _spent: bool = false


func _ready() -> void:
	_lifetime_left = maximum_lifetime
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()


func configure(aim_direction: Vector2, arrow_speed: float, arrow_damage: int) -> void:
	direction = aim_direction.normalized()
	speed = arrow_speed
	damage = arrow_damage
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
	if (area as HurtboxComponent).receive_damage(damage):
		_spend()


func _on_body_entered(_body: Node2D) -> void:
	_spend()


func _spend() -> void:
	if _spent:
		return
	_spent = true
	set_deferred("monitoring", false)
	queue_free()
