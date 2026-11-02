extends SceneTree

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var map_script: Script = load("res://scripts/data/map_definition.gd") as Script
	if map_script == null:
		push_error("MapDefinition deve existir")
		quit(1)
		return
	var map: Resource = map_script.new()
	map.map_id = &"test"
	map.entry_room_id = &"R01"
	var ids: Array[String] = ["R01", "R02A", "R02B", "R03", "R04", "R05"]
	var stages: Array[int] = [1, 2, 2, 3, 4, 5]
	var kinds: Array[int] = [0, 0, 1, 0, 2, 3]
	var links: Array = [["R02A", "R02B"], ["R03"], ["R03"], ["R04"], ["R05"], []]
	for index: int in range(ids.size()):
		var room: Resource = (load("res://scripts/data/room_definition.gd") as Script).new()
		room.room_id = StringName(ids[index])
		room.stage = stages[index]
		room.room_type = kinds[index]
		room.next_room_ids.assign(links[index])
		if index == 1 or index == 2:
			room.exclusive_group = &"fork"
		map.rooms.append(room)
	assert(map.validate().is_empty())
	assert(map.validate_first_map().is_empty())
	map.rooms[1].room_id = &"R01"
	assert(not map.validate().is_empty())
	map.rooms[1].room_id = &"R02A"
	map.rooms[0].next_room_ids.append(&"missing")
	assert(not map.validate().is_empty())
	map.rooms[0].next_room_ids.pop_back()
	map.rooms[4].next_room_ids.clear()
	assert(not map.validate().is_empty())
	map.rooms[4].next_room_ids.append(&"R05")
	var map_node: Node2D = Node2D.new()
	var rooms: Node2D = Node2D.new()
	rooms.name = "Rooms"
	map_node.add_child(rooms)
	for definition: Resource in map.rooms:
		var controller: Node2D = (load("res://scripts/rooms/room_controller.gd") as Script).new()
		controller.definition = definition
		rooms.add_child(controller)
	root.add_child(map_node)
	var player: PlayerController = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as PlayerController
	root.add_child(player)
	var director: Node = (load("res://scripts/systems/room_director.gd") as Script).new()
	root.add_child(director)
	var run: RunProgress = root.get_node("RunManager") as RunProgress
	run.reset_run()
	assert(director.configure(map, map_node, player) == OK)
	assert(not director.try_enter_room(&"R05"))
	assert(director.try_enter_room(&"R01"))
	assert(not director.try_enter_room(&"R01"))
	director.controllers[&"R01"].complete_encounter()
	assert(run.state != RunProgress.RunState.VICTORY)
	assert(director.try_enter_room(&"R02A"))
	assert(director.is_locked(&"R02B"))
	director.controllers[&"R02A"].complete_encounter()
	assert(not director.try_enter_room(&"R02B"))
	assert(director.try_enter_room(&"R03"))
	run.request_game_over()
	director.controllers[&"R03"].complete_encounter()
	assert(not director.is_completed(&"R03"))
	assert(not director.try_enter_room(&"R04"))
	print("Room graph smoke: OK")
	quit()
