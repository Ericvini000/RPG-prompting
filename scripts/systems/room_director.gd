extends Node
class_name RoomDirector

signal room_entered(room_id: StringName)
signal room_completed(room_id: StringName)
signal progress_changed(stage: int, room_name: String)

var definition: MapDefinition
var player: PlayerController
var controllers: Dictionary = {}
var current_room_id: StringName
var _map_root: Node2D
var _completed: Dictionary = {}
var _locked: Dictionary = {}
var upgrades: UpgradeManager
var _pending_room_id: StringName
var _reward_sources: Dictionary = {}
@onready var run_manager: RunProgress = get_node("/root/RunManager") as RunProgress

func bind_upgrades(manager: UpgradeManager) -> void:
	upgrades = manager
	manager.reward_choice_resolved.connect(_on_reward_resolved)
	manager.all_choices_resolved.connect(_finish_pending_room)

func configure(map_data: MapDefinition, map_root: Node2D, target: PlayerController) -> Error:
	if map_data == null or not map_data.validate().is_empty() or map_root.get_node_or_null("Rooms") == null:
		return ERR_INVALID_DATA
	definition = map_data
	_map_root = map_root
	player = target
	controllers.clear()
	_completed.clear()
	_locked.clear()
	current_room_id = &""
	for child: Node in map_root.get_node("Rooms").get_children():
		if child is RoomController and child.definition != null:
			var room: RoomController = child as RoomController
			controllers[room.definition.room_id] = room
			room.entry_requested.connect(try_enter_room)
			room.encounter_completed.connect(_on_encounter_completed)
	if controllers.size() != definition.rooms.size():
		return ERR_INVALID_DATA
	run_manager.begin_exploration()
	return OK

func is_completed(id: StringName) -> bool:
	return _completed.has(id)

func is_locked(id: StringName) -> bool:
	return _locked.has(id)

func can_enter(id: StringName) -> bool:
	if definition == null or is_locked(id) or not controllers.has(id):
		return false
	if run_manager.state != RunProgress.RunState.EXPLORATION or get_tree().paused:
		return false
	if current_room_id.is_empty():
		return id == definition.entry_room_id
	if id == current_room_id:
		return false
	var current: RoomDefinition = definition.get_room(current_room_id)
	var destination: RoomDefinition = definition.get_room(id)
	return is_completed(current_room_id) and (current.next_room_ids.has(id) or (is_completed(id) and destination.next_room_ids.has(current_room_id)))

func try_enter_room(id: StringName) -> bool:
	if not can_enter(id):
		return false
	current_room_id = id
	var room: RoomDefinition = definition.get_room(id)
	progress_changed.emit(room.stage, room.display_name)
	if not is_completed(id):
		if not room.exclusive_group.is_empty():
			for other: RoomDefinition in definition.rooms:
				if other.room_id != id and other.exclusive_group == room.exclusive_group:
					_locked[other.room_id] = true
		run_manager.begin_combat()
		room_entered.emit(id)
		(controllers[id] as RoomController).begin_encounter(player)
	_refresh_doors()
	return true

func _on_encounter_completed(id: StringName) -> void:
	if id != current_room_id or is_completed(id) or run_manager.state == RunProgress.RunState.GAME_OVER:
		return
	_pending_room_id = id
	run_manager.begin_exploration()
	var room: RoomDefinition = definition.get_room(id)
	for index: int in range(room.reward_choices):
		var source: StringName = StringName("%s:%s:%d" % [definition.map_id, id, index])
		_reward_sources[source] = true
	for source: StringName in _reward_sources:
		if upgrades != null:
			upgrades.request_reward_choice(source)
	_finish_pending_room()
	_refresh_doors()

func _on_reward_resolved(source: StringName) -> void:
	_reward_sources.erase(source)
	_finish_pending_room()

func _finish_pending_room() -> void:
	if _pending_room_id.is_empty() or not _reward_sources.is_empty() or run_manager.state == RunProgress.RunState.GAME_OVER:
		return
	if upgrades != null and upgrades.has_pending_choices():
		return
	var id: StringName = _pending_room_id
	_pending_room_id = &""
	_completed[id] = true
	run_manager.begin_exploration()
	room_completed.emit(id)
	_refresh_doors()

func _refresh_doors() -> void:
	var doors: Node = _map_root.get_node_or_null("Doors")
	if doors == null:
		return
	for child: Node in doors.get_children():
		var door: RoomDoor = child as RoomDoor
		if door != null:
			var open: bool = run_manager.state == RunProgress.RunState.EXPLORATION and not is_locked(door.from_room_id) and not is_locked(door.to_room_id) and is_completed(door.from_room_id)
			door.set_open(open)
