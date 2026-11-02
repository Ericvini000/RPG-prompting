extends Node2D
class_name RoomDoor

@export var from_room_id: StringName
@export var to_room_id: StringName
var is_open: bool = false

func set_open(open: bool) -> void:
	is_open = open
	($Body/Collision as CollisionPolygon2D).set_deferred("disabled", open)
	($Visual as Polygon2D).color = Color(0.2, 0.65, 0.55, 0.18) if open else Color(0.65, 0.35, 0.18, 0.95)
