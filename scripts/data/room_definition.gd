extends Resource
class_name RoomDefinition

enum RoomType { COMBAT, REST, ELITE, BOSS }

@export var room_id: StringName
@export var display_name: String = "Sala"
@export var stage: int = 1
@export var room_type: RoomType = RoomType.COMBAT
@export var next_room_ids: Array[StringName] = []
@export var exclusive_group: StringName
@export var encounters: Array[WaveData] = []
@export_range(0, 3) var reward_choices: int = 0
@export var rest_heal: int = 0
@export var health_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
