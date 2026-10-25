extends CanvasLayer
class_name UpgradeScreen

signal upgrade_chosen(upgrade_id: String)

@onready var _buttons: Array[Button] = [
	$Overlay/Panel/Content/Cards/Card1,
	$Overlay/Panel/Content/Cards/Card2,
	$Overlay/Panel/Content/Cards/Card3,
]

var _offer: Array[UpgradeDefinition] = []
var _selection_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	for index: int in range(_buttons.size()):
		_buttons[index].pressed.connect(_choose.bind(index))


func show_offer(offer: Array[UpgradeDefinition], acquired_counts: Dictionary) -> void:
	_offer = offer.duplicate()
	_selection_open = true
	for index: int in range(_buttons.size()):
		var definition: UpgradeDefinition = _offer[index]
		var count: int = int(acquired_counts.get(definition.upgrade_id, 0))
		var ownership: String = "Nova carta" if count == 0 else "Adquirida: " + str(count)
		_buttons[index].icon = definition.icon
		_buttons[index].text = definition.title + "\n\n" + definition.description + "\n\n" + definition.effect_text + "\n" + ownership
		_buttons[index].disabled = false
	visible = true


func hide_offer() -> void:
	_selection_open = false
	_offer.clear()
	visible = false


func _choose(index: int) -> void:
	if not _selection_open or index < 0 or index >= _offer.size():
		return
	_selection_open = false
	upgrade_chosen.emit(_offer[index].upgrade_id)
