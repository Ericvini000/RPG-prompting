extends Node
class_name RunProgress

signal experience_changed(xp: int, required: int)
signal level_up_requested()

var level: int = 1
var experience: int = 0
var pending_level_ups: int = 0


func _ready() -> void:
	reset_run()


func required_experience_for_level(current_level: int) -> int:
	return 20 + 10 * (maxi(1, current_level) - 1)


func reset_run() -> void:
	level = 1
	experience = 0
	pending_level_ups = 0
	experience_changed.emit(experience, required_experience_for_level(level))


func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	while experience >= required_experience_for_level(level):
		experience -= required_experience_for_level(level)
		level += 1
		pending_level_ups += 1
		level_up_requested.emit()
	experience_changed.emit(experience, required_experience_for_level(level))


func consume_pending_level_up() -> bool:
	if pending_level_ups <= 0:
		return false
	pending_level_ups -= 1
	return true
