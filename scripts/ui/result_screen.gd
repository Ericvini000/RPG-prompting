extends CanvasLayer
class_name ResultScreen

signal restart_requested()
signal resume_requested()
signal endless_requested()
signal victory_requested()

@onready var _title: Label = $Overlay/Panel/Content/Title
@onready var _detail: Label = $Overlay/Panel/Content/Detail
@onready var _resume_button: Button = $Overlay/Panel/Content/Resume
@onready var _restart_button: Button = $Overlay/Panel/Content/Restart
@onready var _endless_button: Button = $Overlay/Panel/Content/Endless
@onready var _finish_button: Button = $Overlay/Panel/Content/Finish
@onready var _panel: PanelContainer = $Overlay/Panel
@onready var _content: VBoxContainer = $Overlay/Panel/Content
@onready var _dashboard: VBoxContainer = $Overlay/Panel/Content/PauseDashboard
@onready var _stats_panel: PauseStatsPanel = $Overlay/Panel/Content/PauseDashboard/Columns/StatsFrame/Stats
@onready var _cards_panel: PauseCardsPanel = $Overlay/Panel/Content/PauseDashboard/Columns/CardsFrame/Cards
@onready var _progress: Label = $Overlay/Panel/Content/PauseDashboard/Progress

var _run_manager: RunProgress
var _player: PlayerController
var _upgrade_manager: UpgradeManager
var _wave_director: WaveDirector


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(func() -> void: resume_requested.emit())
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_endless_button.pressed.connect(func() -> void: endless_requested.emit())
	_finish_button.pressed.connect(func() -> void: victory_requested.emit())


func bind(run_manager: RunProgress, player: PlayerController, upgrade_manager: UpgradeManager, wave_director: WaveDirector) -> void:
	_run_manager = run_manager
	_player = player
	_upgrade_manager = upgrade_manager
	_wave_director = wave_director
	run_manager.state_changed.connect(_on_state_changed)
	run_manager.pause_changed.connect(_on_pause_changed)
	_on_state_changed(run_manager.state)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo() and _run_manager != null:
		_run_manager.toggle_pause()
		get_viewport().set_input_as_handled()


func _on_state_changed(new_state: int) -> void:
	match new_state:
		RunProgress.RunState.ENDLESS_CHOICE:
			_show_message("ARENA CONCLUÍDA", "Você superou as três ondas. Como deseja continuar?", false)
			_restart_button.visible = false
			_endless_button.visible = true
			_finish_button.visible = true
		RunProgress.RunState.VICTORY:
			_show_message("VITÓRIA", "Você concluiu as três ondas da arena.", false)
		RunProgress.RunState.GAME_OVER:
			_show_message("DERROTA", "O arqueiro caiu. Tente outra combinação de cartas.", false)
		_:
			visible = false


func _on_pause_changed(is_paused: bool) -> void:
	if _run_manager != null and _run_manager.state == RunProgress.RunState.COMBAT:
		if is_paused:
			_stats_panel.refresh(_player)
			_cards_panel.refresh(_upgrade_manager)
			_progress.text = "Nível %d  |  XP %d / %d  |  Onda %d" % [
				_run_manager.level, _run_manager.experience,
				_run_manager.required_experience_for_level(_run_manager.level),
				_wave_director.current_wave,
			]
			_show_message("PAUSA", "A arena está aguardando.", true)
		else:
			visible = false


func _show_message(heading: String, description: String, can_resume: bool) -> void:
	_endless_button.visible = false
	_finish_button.visible = false
	_restart_button.visible = true
	_dashboard.visible = can_resume
	_detail.visible = not can_resume
	_content.add_theme_constant_override("separation", 12 if can_resume else 22)
	_panel.offset_left = -535.0 if can_resume else -310.0
	_panel.offset_right = 535.0 if can_resume else 310.0
	_panel.offset_top = -310.0 if can_resume else -190.0
	_panel.offset_bottom = 310.0 if can_resume else 190.0
	_title.text = heading
	_detail.text = description
	_resume_button.visible = can_resume
	_restart_button.text = "REINICIAR PARTIDA" if not can_resume else "RECOMEÇAR"
	visible = true
