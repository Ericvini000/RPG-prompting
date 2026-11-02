extends Node2D
class_name RoomController

signal entry_requested(room_id: StringName)
signal encounter_completed(room_id: StringName)

@export var definition: RoomDefinition

var started: bool = false
var completed: bool = false
var player: PlayerController

func _ready() -> void:
	var entry: Area2D = get_node_or_null("Entry") as Area2D
	if entry != null:
		entry.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController and definition != null:
		entry_requested.emit(definition.room_id)

func begin_encounter(target: PlayerController) -> void:
	if started:
		return
	started = true
	player = target

func complete_encounter() -> void:
	if not started or completed:
		return
	completed = true
	encounter_completed.emit(definition.room_id)
