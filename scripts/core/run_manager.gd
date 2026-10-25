extends Node
class_name RunProgress

signal experience_changed(xp: int, required: int)
signal level_up_requested()
signal state_changed(new_state: int)

enum RunState { READY, COMBAT, UPGRADE_SELECTION, VICTORY, GAME_OVER }

var level: int = 1
var experience: int = 0
var pending_level_ups: int = 0
var state: RunState = RunState.READY


func _ready() -> void:
	reset_run()


func required_experience_for_level(current_level: int) -> int:
	return 20 + 10 * (maxi(1, current_level) - 1)


func reset_run() -> void:
	level = 1
	experience = 0
	pending_level_ups = 0
	set_state(RunState.READY)
	experience_changed.emit(experience, required_experience_for_level(level))


func begin_combat() -> void:
	set_state(RunState.COMBAT)


func set_state(new_state: RunState) -> void:
	var changed: bool = state != new_state
	state = new_state
	get_tree().paused = state == RunState.UPGRADE_SELECTION or state == RunState.VICTORY or state == RunState.GAME_OVER
	if changed:
		state_changed.emit(state)


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
