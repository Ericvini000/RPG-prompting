extends Node2D


func _ready() -> void:
	var run_manager: RunProgress = get_node("/root/RunManager") as RunProgress
	run_manager.reset_run()
	run_manager.begin_combat()
