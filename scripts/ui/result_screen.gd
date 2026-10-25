extends CanvasLayer
class_name ResultScreen

signal restart_requested()
signal resume_requested()

@onready var _title: Label = $Overlay/Panel/Content/Title
@onready var _detail: Label = $Overlay/Panel/Content/Detail
@onready var _resume_button: Button = $Overlay/Panel/Content/Resume
@onready var _restart_button: Button = $Overlay/Panel/Content/Restart

var _run_manager: RunProgress


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_resume_button.pressed.connect(func() -> void: resume_requested.emit())
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())


func bind(run_manager: RunProgress) -> void:
	_run_manager = run_manager
	run_manager.state_changed.connect(_on_state_changed)
	run_manager.pause_changed.connect(_on_pause_changed)
	_on_state_changed(run_manager.state)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo() and _run_manager != null:
		_run_manager.toggle_pause()
		get_viewport().set_input_as_handled()


func _on_state_changed(new_state: int) -> void:
	match new_state:
		RunProgress.RunState.VICTORY:
			_show_message("VITÓRIA", "Você concluiu as três ondas da arena.", false)
		RunProgress.RunState.GAME_OVER:
			_show_message("DERROTA", "O arqueiro caiu. Tente outra combinação de cartas.", false)
		_:
			visible = false


func _on_pause_changed(is_paused: bool) -> void:
	if _run_manager != null and _run_manager.state == RunProgress.RunState.COMBAT:
		if is_paused:
			_show_message("PAUSA", "A arena está aguardando.", true)
		else:
			visible = false


func _show_message(heading: String, description: String, can_resume: bool) -> void:
	_title.text = heading
	_detail.text = description
	_resume_button.visible = can_resume
	_restart_button.text = "REINICIAR PARTIDA" if not can_resume else "RECOMEÇAR"
	visible = true
