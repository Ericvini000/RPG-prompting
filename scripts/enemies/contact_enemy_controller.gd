extends EnemyController
class_name ContactEnemyController

@onready var attack_area: Area2D = $AttackArea

var _attack_time_left: float = 0.0


func _physics_process(delta: float) -> void:
	if not can_act():
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
			if (area as HurtboxComponent).receive_damage(effective_contact_damage()):
				_attack_time_left = data.attack_interval
			break
