extends Node
class_name HealthComponent

signal health_changed(current: int, maximum: int)
signal died()

var maximum: int = 1
var current: int = 1
var invulnerability_duration: float = 0.0
var _invulnerability_left: float = 0.0


func _physics_process(delta: float) -> void:
	_invulnerability_left = maxf(0.0, _invulnerability_left - delta)


func configure(max_health: int, hurt_invulnerability: float = 0.0) -> void:
	maximum = maxi(1, max_health)
	current = maximum
	invulnerability_duration = maxf(0.0, hurt_invulnerability)
	_invulnerability_left = 0.0
	health_changed.emit(current, maximum)


func apply_damage(amount: int) -> bool:
	if amount <= 0 or current <= 0 or _invulnerability_left > 0.0:
		return false
	current = maxi(0, current - amount)
	_invulnerability_left = invulnerability_duration
	health_changed.emit(current, maximum)
	if current == 0:
		died.emit()
	return true


func heal(amount: int) -> void:
	if amount <= 0 or current <= 0:
		return
	current = mini(maximum, current + amount)
	health_changed.emit(current, maximum)
