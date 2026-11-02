extends SceneTree
func _initialize() -> void:
	call_deferred("_verify")
func _verify() -> void:
	var map: Node2D = (load("res://scenes/maps/map_01.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(map)
	var player: PlayerController = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	var room: RoomController = map.get_node("Rooms/R01") as RoomController
	var requests: Array[int] = [0]
	room.entry_requested.connect(func(_id: StringName) -> void: requests[0] += 1)
	player.global_position = (map.get_node("Rooms/R02A") as Node2D).global_position
	room.call("_on_body_entered", player)
	assert(requests[0] == 0, "Evento atrasado de sala anterior não deve alterar a rota")
	player.global_position = room.global_position
	room.call("_on_body_entered", player)
	assert(requests[0] == 1)
	player.global_position = room.global_position + Vector2(350, 0)
	for frame: int in range(5):
		await physics_frame
	assert((room.get_node("Entry") as Area2D).overlaps_body(player), "Entrada deve abranger a borda navegável da sala")
	print("Room entry smoke: OK")
	quit()
