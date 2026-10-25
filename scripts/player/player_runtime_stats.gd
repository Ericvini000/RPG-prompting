extends RefCounted
class_name PlayerRuntimeStats

var base_stats: PlayerStats
var damage_bonus: float = 0.0
var attack_speed_bonus: float = 0.0
var move_speed_bonus: float = 0.0
var bonus_health: int = 0
var pierce_count: int = 0
var triple_shot: bool = false
var fire_arrow: bool = false
var burn_damage_per_second: int = 0
var burn_duration: float = 0.0
var dash_cooldown_multiplier: float = 1.0


func _init(initial_stats: PlayerStats) -> void:
	base_stats = initial_stats


func apply_upgrade(definition: UpgradeDefinition) -> void:
	match definition.effect:
		UpgradeDefinition.Effect.DAMAGE:
			damage_bonus += definition.magnitude
		UpgradeDefinition.Effect.ATTACK_SPEED:
			attack_speed_bonus += definition.magnitude
		UpgradeDefinition.Effect.MOVE_SPEED:
			move_speed_bonus += definition.magnitude
		UpgradeDefinition.Effect.VITALITY:
			bonus_health += roundi(definition.magnitude)
		UpgradeDefinition.Effect.PIERCE:
			pierce_count += roundi(definition.magnitude)
		UpgradeDefinition.Effect.TRIPLE_SHOT:
			triple_shot = true
		UpgradeDefinition.Effect.FIRE:
			fire_arrow = true
			burn_damage_per_second = roundi(definition.magnitude)
			burn_duration = definition.duration
		UpgradeDefinition.Effect.DASH_COOLDOWN:
			dash_cooldown_multiplier *= 1.0 - definition.magnitude


func effective_damage() -> int:
	return roundi(base_stats.base_damage * (1.0 + damage_bonus))


func effective_attack_interval() -> float:
	return base_stats.attack_interval / (1.0 + attack_speed_bonus)


func effective_move_speed() -> float:
	return base_stats.move_speed * (1.0 + move_speed_bonus)


func effective_dash_cooldown() -> float:
	return base_stats.dash_cooldown * dash_cooldown_multiplier
