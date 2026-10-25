extends Node
class_name WaveDirector

signal wave_changed(number: int)
signal arena_completed()

@export var arena: Node2D
@export var waves: Array[WaveData] = []
@export var minimum_player_distance: float = 128.0
@export var minimum_spawn_separation: float = 80.0

@onready var run_manager: RunProgress = get_node("/root/RunManager") as RunProgress

var current_wave: int = 0
var active_enemies: Array[EnemyController] = []

var _player: PlayerController
var _spawn_points: Array[Marker2D] = []
var _waiting_for_spawns: bool = false
var _completed: bool = false


func _ready() -> void:
	if arena == null:
		push_error("WaveDirector precisa de uma arena.")
		set_process(false)
		return
	_player = arena.get_node_or_null("Player") as PlayerController
	if _player == null:
		push_error("WaveDirector precisa do arqueiro na arena.")
		set_process(false)
		return
	for child: Node in arena.get_node("Spawns").get_children():
		if child is Marker2D and child.name.begins_with("EnemySpawn"):
			_spawn_points.append(child as Marker2D)
	run_manager.state_changed.connect(_on_run_state_changed)
	call_deferred("_start_next_wave")


func _process(_delta: float) -> void:
	if _waiting_for_spawns:
		_start_next_wave()


func _start_next_wave() -> void:
	if _completed or _player == null or _player.health.current <= 0 or run_manager.state == RunProgress.RunState.GAME_OVER or run_manager.state == RunProgress.RunState.VICTORY:
		return
	if current_wave >= waves.size():
		_completed = true
		arena_completed.emit()
		return
	if run_manager.state != RunProgress.RunState.COMBAT or get_tree().paused:
		_waiting_for_spawns = true
		return
	var wave: WaveData = waves[current_wave]
	if wave == null or wave.enemy_scenes.is_empty():
		push_error("Onda precisa de inimigos configurados.")
		_waiting_for_spawns = false
		return
	var locations: Array[Marker2D] = _choose_spawns(wave.enemy_scenes.size())
	if locations.size() < wave.enemy_scenes.size():
		_waiting_for_spawns = true
		return
	_waiting_for_spawns = false
	for index: int in range(wave.enemy_scenes.size()):
		var enemy: EnemyController = wave.enemy_scenes[index].instantiate() as EnemyController
		if enemy == null:
			push_error("Cena da onda precisa instanciar EnemyController.")
			continue
		enemy.target = _player
		arena.add_child(enemy)
		enemy.global_position = locations[index].global_position
		enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))
		enemy.enemy_defeated.connect(run_manager.add_experience)
		active_enemies.append(enemy)
	current_wave += 1
	wave_changed.emit(current_wave)


func _choose_spawns(count: int) -> Array[Marker2D]:
	var chosen: Array[Marker2D] = []
	for marker: Marker2D in _spawn_points:
		if marker.global_position.distance_to(_player.global_position) < minimum_player_distance:
			continue
		var separated: bool = true
		for selected: Marker2D in chosen:
			if marker.global_position.distance_to(selected.global_position) < minimum_spawn_separation:
				separated = false
				break
		if separated:
			chosen.append(marker)
			if chosen.size() == count:
				break
	return chosen


func _on_enemy_defeated(_xp_reward: int, enemy: EnemyController) -> void:
	active_enemies.erase(enemy)
	if active_enemies.is_empty():
		call_deferred("_start_next_wave")


func _on_run_state_changed(new_state: int) -> void:
	if _waiting_for_spawns and new_state == RunProgress.RunState.COMBAT:
		call_deferred("_start_next_wave")
