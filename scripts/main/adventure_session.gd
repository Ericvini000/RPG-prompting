extends Node2D
class_name AdventureSession

signal map_loaded(map: Node2D)

@onready var player: PlayerController = $GameplayRoot/Player
@onready var map_root: Node2D = $GameplayRoot/MapRoot
@onready var _run_manager: RunProgress = get_node("/root/RunManager") as RunProgress

var current_map: Node2D


func _ready() -> void:
	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED


## Mounts one complete map without resetting the player or the run.
## Room progression and map definitions belong to the following increments.
func mount_map(scene: PackedScene) -> Error:
	if scene == null:
		return ERR_INVALID_PARAMETER
	if current_map != null:
		return ERR_ALREADY_IN_USE
	if _run_manager.selected_mode != RunProgress.GameMode.ADVENTURE or _run_manager.state != RunProgress.RunState.READY:
		return ERR_BUSY
	if not scene.can_instantiate():
		return ERR_INVALID_DATA
	var instance: Node = scene.instantiate()
	var map: Node2D = instance as Node2D
	var spawn: Marker2D = instance.get_node_or_null("PlayerSpawn") as Marker2D
	if map == null or spawn == null:
		instance.free()
		return ERR_INVALID_DATA
	map_root.add_child(map)
	current_map = map
	player.global_position = spawn.global_position
	player.visible = true
	player.process_mode = Node.PROCESS_MODE_INHERIT
	map_loaded.emit(map)
	return OK
