extends Node
class_name BurnComponent

@export var health: HealthComponent

var _damage_per_second: int = 0
var _seconds_left: float = 0.0
var _tick_accumulator: float = 0.0


func apply_burn(damage_per_second: int, duration: float) -> void:
	if health == null or health.current <= 0 or damage_per_second <= 0 or duration <= 0.0:
		return
	if _seconds_left <= 0.0:
		_tick_accumulator = 0.0
		_damage_per_second = damage_per_second
	else:
		_damage_per_second = maxi(_damage_per_second, damage_per_second)
	_seconds_left = maxf(_seconds_left, duration)


func _physics_process(delta: float) -> void:
	if _seconds_left <= 0.0 or health == null or health.current <= 0:
		return
	var active_delta: float = minf(delta, _seconds_left)
	_seconds_left = maxf(0.0, _seconds_left - delta)
	_tick_accumulator += active_delta
	while _tick_accumulator >= 1.0 and health.current > 0:
		_tick_accumulator -= 1.0
		health.apply_damage(_damage_per_second)
