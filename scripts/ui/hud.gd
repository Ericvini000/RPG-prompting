extends CanvasLayer
class_name GameHUD

@onready var _health_value: Label = $Overlay/Top/Health/Value
@onready var _health_bar: ProgressBar = $Overlay/Top/Health/Bar
@onready var _level_label: Label = $Overlay/Top/Progress/Level
@onready var _xp_bar: ProgressBar = $Overlay/Top/Progress/Bar
@onready var _wave_label: Label = $Overlay/Top/Wave
@onready var _dash_label: Label = $Overlay/Dash

var _player: PlayerController


func bind(player: PlayerController, director: WaveDirector, run_manager: RunProgress) -> void:
	_player = player
	player.health.health_changed.connect(_update_health)
	run_manager.experience_changed.connect(_update_experience)
	if director != null:
		director.wave_changed.connect(_update_wave)
	_update_health(player.health.current, player.health.maximum)
	_update_experience(run_manager.experience, run_manager.required_experience_for_level(run_manager.level))
	if director != null:
		_update_wave(director.current_wave)
	else:
		_wave_label.text = "AVENTURA"


func _process(_delta: float) -> void:
	if _player == null:
		return
	var remaining: float = _player.dash_cooldown_remaining()
	_dash_label.text = "DASH  PRONTO [ESPAÇO]" if remaining <= 0.0 else "DASH  %.1f s" % remaining


func _update_health(current: int, maximum: int) -> void:
	_health_value.text = "VIDA  %d / %d" % [current, maximum]
	_health_bar.max_value = maximum
	_health_bar.value = current


func _update_experience(xp: int, required: int) -> void:
	var run_manager: RunProgress = get_node("/root/RunManager") as RunProgress
	_level_label.text = "NÍVEL %d     XP %d / %d" % [run_manager.level, xp, required]
	_xp_bar.max_value = required
	_xp_bar.value = xp


func _update_wave(number: int) -> void:
	if number <= 0:
		_wave_label.text = "ARENA"
	elif number <= 3:
		_wave_label.text = "ONDA  %d / 3" % number
	else:
		_wave_label.text = "ONDA  %d  ·  INFINITO" % number
