extends Area2D
class_name HurtboxComponent

@export var health: HealthComponent


func receive_damage(amount: int) -> bool:
	if health == null:
		return false
	var owner_node: Node = get_parent()
	if owner_node.has_method("is_invulnerable") and owner_node.call("is_invulnerable"):
		return false
	return health.apply_damage(amount)
