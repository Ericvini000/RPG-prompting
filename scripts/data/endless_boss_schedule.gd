extends Resource
class_name EndlessBossSchedule

@export var wave_interval: int = 5
@export var boss_scene: PackedScene
@export_range(0, 3) var reward_choices: int = 1
