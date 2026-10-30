extends Node
class_name WaveDirector

signal wave_changed(number: int)
signal arena_completed()

@export var arena: Node2D
@export var waves: Array[WaveData] = []
@export var minimum_player_distance: float = 128.0
@export var minimum_spawn_separation: float = 80.0
@export_range(1, 12, 1) var maximum_active_enemies: int = 12
@export var endless_health_bonus_per_wave: float = 0.05
@export var endless_damage_bonus_per_wave: float = 0.02
@export var endless_spawn_interval: float = 0.3
@export var endless_wave_interval: float = 1.5
@export var invalid_spawn_retry_interval: float = 0.5
@export var spawn_fallback_after: float = 3.0
@export var minimum_fallback_player_distance: float = 64.0

@onready var run_manager: RunProgress = get_node("/root/RunManager") as RunProgress

var current_wave: int = 0
var active_enemies: Array[EnemyController] = []

var _player: PlayerController
var _spawn_points: Array[Marker2D] = []
var _waiting_for_spawns: bool = false
var _completed: bool = false
var _endless_pool: Array[PackedScene] = []
var _pending_endless: Array[PackedScene] = []
var _spawn_wait: float = 0.0
var _wave_wait: float = 0.0
var _blocked_spawn_time: float = 0.0
var _spawn_blocked: bool = false


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
	for wave: WaveData in waves:
		if wave == null:
			continue
		for scene: PackedScene in wave.enemy_scenes:
			if scene != null and not _endless_pool.has(scene):
				_endless_pool.append(scene)
	run_manager.state_changed.connect(_on_run_state_changed)
	run_manager.endless_mode_started.connect(_on_endless_mode_started)
	call_deferred("_start_next_wave")


func _process(delta: float) -> void:
	if _completed or run_manager.state != RunProgress.RunState.COMBAT or get_tree().paused:
		return
	if not _pending_endless.is_empty():
		if _spawn_blocked:
			_blocked_spawn_time += delta
		_spawn_wait = maxf(0.0, _spawn_wait - delta)
		if _spawn_wait <= 0.0:
			_spawn_endless_enemy()
	elif _waiting_for_spawns:
		_wave_wait = maxf(0.0, _wave_wait - delta)
		if _wave_wait <= 0.0:
			_start_next_wave()


func _start_next_wave() -> void:
	if _completed or _player == null or _player.health.current <= 0 or run_manager.state == RunProgress.RunState.GAME_OVER or run_manager.state == RunProgress.RunState.VICTORY:
		return
	if current_wave >= waves.size():
		if run_manager.endless_mode:
			_start_endless_wave()
		else:
			_completed = true
			_waiting_for_spawns = false
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
		_spawn_enemy(wave.enemy_scenes[index], locations[index])
	current_wave += 1
	wave_changed.emit(current_wave)


func _start_endless_wave() -> void:
	if _endless_pool.is_empty():
		push_error("Modo infinito precisa de cenas inimigas nas ondas iniciais.")
		_waiting_for_spawns = false
		return
	var next_wave: int = current_wave + 1
	var total: int = waves.back().enemy_scenes.size() + next_wave - 3
	var pool: Array[PackedScene] = _endless_pool.duplicate()
	pool.shuffle()
	_pending_endless.clear()
	for index: int in range(total):
		_pending_endless.append(pool[index % pool.size()])
	current_wave = next_wave
	_waiting_for_spawns = false
	_spawn_wait = 0.0
	_blocked_spawn_time = 0.0
	_spawn_blocked = false
	wave_changed.emit(current_wave)
	_spawn_endless_enemy()


func _spawn_endless_enemy() -> void:
	if _pending_endless.is_empty() or active_enemies.size() >= clampi(maximum_active_enemies, 1, 12):
		return
	var marker: Marker2D = _find_endless_spawn()
	if marker == null:
		_spawn_blocked = true
		_spawn_wait = maxf(0.05, invalid_spawn_retry_interval)
		return
	var waves_after_third: int = current_wave - 3
	var health_scale: float = 1.0 + endless_health_bonus_per_wave * waves_after_third
	var damage_scale: float = 1.0 + endless_damage_bonus_per_wave * waves_after_third
	var scene: PackedScene = _pending_endless.pop_front()
	_spawn_enemy(scene, marker, health_scale, damage_scale)
	_spawn_blocked = false
	_blocked_spawn_time = 0.0
	_spawn_wait = maxf(0.0, endless_spawn_interval)


func _find_endless_spawn() -> Marker2D:
	var fallback: Marker2D
	var fallback_distance: float = 0.0
	for marker: Marker2D in _spawn_points:
		var player_distance: float = marker.global_position.distance_to(_player.global_position)
		var separated: bool = true
		for enemy: EnemyController in active_enemies:
			if marker.global_position.distance_to(enemy.global_position) < minimum_spawn_separation:
				separated = false
				break
		if not separated:
			continue
		if player_distance >= minimum_player_distance:
			return marker
		if player_distance > fallback_distance and player_distance >= minimum_fallback_player_distance:
			fallback = marker
			fallback_distance = player_distance
	if _blocked_spawn_time >= spawn_fallback_after:
		return fallback
	return null


func _spawn_enemy(scene: PackedScene, marker: Marker2D, health_scale: float = 1.0, damage_scale: float = 1.0) -> void:
	var enemy: EnemyController = scene.instantiate() as EnemyController
	if enemy == null:
		push_error("Cena da onda precisa instanciar EnemyController.")
		return
	enemy.target = _player
	enemy.health_multiplier = health_scale
	enemy.damage_multiplier = damage_scale
	arena.add_child(enemy)
	enemy.global_position = marker.global_position
	enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))
	enemy.enemy_defeated.connect(run_manager.add_experience)
	active_enemies.append(enemy)


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
	if active_enemies.is_empty() and _pending_endless.is_empty():
		if run_manager.endless_mode:
			_wave_wait = maxf(0.0, endless_wave_interval)
			_waiting_for_spawns = true
		else:
			call_deferred("_start_next_wave")


func _on_run_state_changed(new_state: int) -> void:
	if new_state == RunProgress.RunState.GAME_OVER or new_state == RunProgress.RunState.VICTORY:
		_completed = true
		_pending_endless.clear()
		_waiting_for_spawns = false
	elif new_state == RunProgress.RunState.COMBAT and run_manager.endless_mode and _completed:
		_completed = false
		_wave_wait = maxf(0.0, endless_wave_interval)
		_waiting_for_spawns = true
	elif _waiting_for_spawns and new_state == RunProgress.RunState.COMBAT and _wave_wait <= 0.0:
		call_deferred("_start_next_wave")


func _on_endless_mode_started() -> void:
	if not _completed:
		return
	_completed = false
	_wave_wait = maxf(0.0, endless_wave_interval)
	_waiting_for_spawns = true
