extends Node
class_name RunProgress

signal experience_changed(xp: int, required: int)
signal level_up_requested()
signal state_changed(new_state: int)
signal pause_changed(is_paused: bool)
signal endless_mode_started()

enum RunState { READY, COMBAT, UPGRADE_SELECTION, VICTORY, GAME_OVER }
enum GameMode { ADVENTURE, ENDLESS }

var level: int = 1
var experience: int = 0
var pending_level_ups: int = 0
var state: RunState = RunState.READY
var normal_paused: bool = false
var endless_mode: bool = false
var selected_mode: GameMode = GameMode.ADVENTURE
var _victory_pending: bool = false
var _endless_start_pending: bool = false
var _upgrade_return_state: RunState = RunState.READY


func _ready() -> void:
	reset_run()


func required_experience_for_level(current_level: int) -> int:
	return 20 + 10 * (maxi(1, current_level) - 1)


func select_mode(mode: GameMode) -> void:
	selected_mode = mode
	reset_run()


func return_to_menu() -> void:
	selected_mode = GameMode.ADVENTURE
	reset_run()


func reset_run() -> void:
	level = 1
	experience = 0
	pending_level_ups = 0
	_victory_pending = false
	_endless_start_pending = false
	_upgrade_return_state = RunState.READY
	endless_mode = false
	normal_paused = false
	set_state(RunState.READY)
	pause_changed.emit(false)
	experience_changed.emit(experience, required_experience_for_level(level))


func begin_combat() -> void:
	set_state(RunState.COMBAT)


func begin_upgrade_selection() -> void:
	if state != RunState.UPGRADE_SELECTION:
		_upgrade_return_state = state
	set_state(RunState.UPGRADE_SELECTION)


func finish_upgrade_selection() -> void:
	if state != RunState.UPGRADE_SELECTION or pending_level_ups > 0:
		return
	if _victory_pending:
		_victory_pending = false
		set_state(RunState.VICTORY)
	elif _endless_start_pending:
		_endless_start_pending = false
		_start_endless_mode()
		begin_combat()
	else:
		set_state(_upgrade_return_state)


func complete_initial_waves() -> void:
	if selected_mode == GameMode.ENDLESS and not endless_mode and state != RunState.GAME_OVER and state != RunState.VICTORY:
		if pending_level_ups > 0 or state == RunState.UPGRADE_SELECTION:
			_endless_start_pending = true
		else:
			_start_endless_mode()


func _start_endless_mode() -> void:
	endless_mode = true
	endless_mode_started.emit()


func request_victory() -> void:
	if state == RunState.GAME_OVER or state == RunState.VICTORY:
		return
	if pending_level_ups > 0 or state == RunState.UPGRADE_SELECTION:
		_victory_pending = true
		return
	set_state(RunState.VICTORY)


func request_game_over() -> void:
	if state == RunState.VICTORY or state == RunState.GAME_OVER:
		return
	_victory_pending = false
	_endless_start_pending = false
	set_state(RunState.GAME_OVER)


func toggle_pause() -> void:
	if state != RunState.COMBAT:
		return
	normal_paused = not normal_paused
	get_tree().paused = normal_paused
	pause_changed.emit(normal_paused)


func set_state(new_state: RunState) -> void:
	var changed: bool = state != new_state
	state = new_state
	if state != RunState.COMBAT and normal_paused:
		normal_paused = false
		pause_changed.emit(false)
	get_tree().paused = normal_paused or state == RunState.UPGRADE_SELECTION or state == RunState.VICTORY or state == RunState.GAME_OVER
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
