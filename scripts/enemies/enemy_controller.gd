extends CharacterBody2D
class_name EnemyController

signal enemy_defeated(xp_reward: int)

@export var data: EnemyData
@export var target: PlayerController

@onready var health: HealthComponent = $HealthComponent

var _defeated: bool = false
var health_multiplier: float = 1.0
var damage_multiplier: float = 1.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if data == null:
		push_error("Inimigo precisa de EnemyData.")
		set_physics_process(false)
		return
	health.configure(maxi(1, roundi(data.max_health * health_multiplier)))
	health.died.connect(_on_died)
	if target == null:
		target = get_tree().get_first_node_in_group("player") as PlayerController


func can_act() -> bool:
	return not _defeated and target != null and target.health.current > 0


func effective_contact_damage() -> int:
	return maxi(1, roundi(data.contact_damage * damage_multiplier))


func effective_projectile_damage() -> int:
	return maxi(1, roundi(data.projectile_damage * damage_multiplier))


func _on_died() -> void:
	if _defeated:
		return
	_defeated = true
	enemy_defeated.emit(data.xp_reward)
	queue_free()
