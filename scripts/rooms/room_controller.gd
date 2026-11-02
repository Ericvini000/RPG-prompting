extends Node2D
class_name RoomController

signal entry_requested(room_id: StringName)
signal encounter_completed(room_id: StringName)

@export var definition: RoomDefinition

var started: bool = false
var completed: bool = false
var player: PlayerController
var active_enemies: Array[EnemyController] = []
var _wave_index: int = 0
var _waiting: bool = false
@onready var _run_manager: RunProgress = get_node("/root/RunManager") as RunProgress

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
	if definition.room_type == RoomDefinition.RoomType.REST:
		player.health.heal(definition.rest_heal)
		call_deferred("complete_encounter")
		return
	_waiting = not definition.encounters.is_empty()
	call_deferred("_start_next_wave")

func _process(_delta: float) -> void:
	if _waiting:
		_start_next_wave()

func _start_next_wave() -> void:
	if not _waiting or _run_manager.state != RunProgress.RunState.COMBAT or get_tree().paused:
		return
	if _wave_index >= definition.encounters.size():
		_waiting = false
		complete_encounter()
		return
	var wave: WaveData = definition.encounters[_wave_index]
	if wave == null or wave.enemy_scenes.is_empty():
		_waiting = false
		push_error("Encontro precisa de inimigos configurados.")
		return
	var points: Array[Marker2D] = []
	var spawns: Node = get_node_or_null("Spawns")
	if spawns == null:
		return
	for child: Node in spawns.get_children():
		if child is Marker2D and (child as Marker2D).global_position.distance_to(player.global_position) >= 80.0:
			points.append(child as Marker2D)
	if points.size() < wave.enemy_scenes.size():
		return
	_waiting = false
	_wave_index += 1
	for index: int in range(wave.enemy_scenes.size()):
		var enemy: EnemyController = wave.enemy_scenes[index].instantiate() as EnemyController
		enemy.target = player
		enemy.health_multiplier = definition.health_multiplier
		enemy.damage_multiplier = definition.damage_multiplier
		if definition.room_type == RoomDefinition.RoomType.ELITE:
			enemy.modulate = Color(1.0, 0.78, 0.5)
		add_child(enemy)
		enemy.global_position = points[index].global_position
		enemy.enemy_defeated.connect(_run_manager.add_experience)
		enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))
		active_enemies.append(enemy)

func _on_enemy_defeated(_xp: int, enemy: EnemyController) -> void:
	active_enemies.erase(enemy)
	if active_enemies.is_empty() and _run_manager.state != RunProgress.RunState.GAME_OVER:
		_waiting = true
		call_deferred("_start_next_wave")

func complete_encounter() -> void:
	if not started or completed or not active_enemies.is_empty() or _run_manager.state == RunProgress.RunState.GAME_OVER:
		return
	completed = true
	_waiting = false
	for projectile: Node in get_tree().get_nodes_in_group("projectiles"):
		projectile.queue_free()
	encounter_completed.emit(definition.room_id)
