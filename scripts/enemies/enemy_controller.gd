extends CharacterBody2D
class_name EnemyController

signal enemy_defeated(xp_reward: int)

@export var data: EnemyData
@export var target: PlayerController

@onready var health: HealthComponent = $HealthComponent
@onready var attack_area: Area2D = $AttackArea

var _attack_time_left: float = 0.0
var _defeated: bool = false


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if data == null:
		push_error("Chaser precisa de EnemyData.")
		set_physics_process(false)
		return
	health.configure(data.max_health)
	health.died.connect(_on_died)
	if target == null:
		target = get_tree().get_first_node_in_group("player") as PlayerController


func _physics_process(delta: float) -> void:
	if _defeated or target == null or target.health.current <= 0:
		velocity = Vector2.ZERO
		return
	var to_player: Vector2 = target.global_position - global_position
	velocity = to_player.normalized() * data.move_speed if to_player.length() > 24.0 else Vector2.ZERO
	move_and_slide()
	_attack_time_left = maxf(0.0, _attack_time_left - delta)
	if _attack_time_left > 0.0:
		return
	for area: Area2D in attack_area.get_overlapping_areas():
		if area is HurtboxComponent and area.get_parent() == target:
			if (area as HurtboxComponent).receive_damage(data.contact_damage):
				_attack_time_left = data.attack_interval
			break


func _on_died() -> void:
	if _defeated:
		return
	_defeated = true
	enemy_defeated.emit(data.xp_reward)
	queue_free()
