extends Resource
class_name MapDefinition

@export var map_id: StringName
@export var scene: PackedScene
@export var entry_room_id: StringName
@export var rooms: Array[RoomDefinition] = []

func get_room(id: StringName) -> RoomDefinition:
	for room: RoomDefinition in rooms:
		if room != null and room.room_id == id:
			return room
	return null

func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	var ids: Dictionary = {}
	if map_id.is_empty() or rooms.is_empty():
		errors.append("Mapa precisa de ID e salas.")
	for room: RoomDefinition in rooms:
		if room == null or room.room_id.is_empty():
			errors.append("Sala sem definição/ID.")
			continue
		if ids.has(room.room_id) or room.stage < 1:
			errors.append("ID duplicado ou etapa inválida: " + room.room_id)
		ids[room.room_id] = true
	if not ids.has(entry_room_id):
		errors.append("Entrada do mapa inexistente.")
	for room: RoomDefinition in rooms:
		if room == null:
			continue
		for next_id: StringName in room.next_room_ids:
			var next: RoomDefinition = get_room(next_id)
			if next == null or next.stage <= room.stage:
				errors.append("Conexão inválida: %s -> %s" % [room.room_id, next_id])
	if not errors.is_empty():
		return errors
	var reached: Dictionary = {}
	var pending: Array[StringName] = [entry_room_id]
	var has_boss: bool = false
	while not pending.is_empty():
		var id: StringName = pending.pop_front()
		if reached.has(id):
			continue
		reached[id] = true
		var room: RoomDefinition = get_room(id)
		has_boss = has_boss or room.room_type == RoomDefinition.RoomType.BOSS
		pending.append_array(room.next_room_ids)
	if reached.size() != rooms.size() or not has_boss:
		errors.append("Há salas inacessíveis ou não há caminho até o chefe.")
	return errors

func validate_first_map() -> PackedStringArray:
	var errors: PackedStringArray = validate()
	var stages: Dictionary = {}
	for room: RoomDefinition in rooms:
		if room != null:
			stages[room.stage] = int(stages.get(room.stage, 0)) + 1
	if rooms.size() != 6 or stages != {1: 1, 2: 2, 3: 1, 4: 1, 5: 1}:
		errors.append("Primeiro mapa requer seis salas em cinco etapas e bifurcação na etapa 2.")
	var branch_types: Array[int] = []
	var branch_group: StringName
	for room: RoomDefinition in rooms:
		if room == null:
			continue
		if room.stage == 2:
			branch_types.append(room.room_type)
			if branch_group.is_empty():
				branch_group = room.exclusive_group
			if room.exclusive_group.is_empty() or room.exclusive_group != branch_group:
				errors.append("Bifurcação requer o mesmo grupo exclusivo.")
		elif (room.stage in [1, 3] and room.room_type != RoomDefinition.RoomType.COMBAT) or (room.stage == 4 and room.room_type != RoomDefinition.RoomType.ELITE) or (room.stage == 5 and room.room_type != RoomDefinition.RoomType.BOSS):
			errors.append("Tipo de sala incompatível com etapa.")
	branch_types.sort()
	if branch_types != [RoomDefinition.RoomType.COMBAT, RoomDefinition.RoomType.REST]:
		errors.append("Bifurcação requer combate e descanso.")
	return errors
