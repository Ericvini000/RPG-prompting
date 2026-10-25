extends Node
class_name UpgradeManager

signal upgrade_selected(upgrade_id: String)

@export var player: PlayerController
@export var screen: UpgradeScreen
@export var definitions: Array[UpgradeDefinition] = []

@onready var run_manager: RunProgress = get_node("/root/RunManager") as RunProgress

var owned_counts: Dictionary = {}
var current_offer: Array[UpgradeDefinition] = []
var _offer_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if player == null or screen == null:
		push_error("UpgradeManager precisa do jogador e da tela de cartas.")
		return
	run_manager.level_up_requested.connect(_on_level_up_requested)
	screen.upgrade_chosen.connect(select_upgrade)


func get_acquired_count(upgrade_id: String) -> int:
	return int(owned_counts.get(upgrade_id, 0))


func is_eligible(definition: UpgradeDefinition) -> bool:
	return definition.max_stacks <= 0 or get_acquired_count(definition.upgrade_id) < definition.max_stacks


func roll_offer() -> Array[UpgradeDefinition]:
	var eligible: Array[UpgradeDefinition] = []
	for definition: UpgradeDefinition in definitions:
		if definition != null and is_eligible(definition):
			eligible.append(definition)
	eligible.shuffle()
	var offer: Array[UpgradeDefinition] = []
	for index: int in range(mini(3, eligible.size())):
		offer.append(eligible[index])
	return offer


func select_upgrade(upgrade_id: String) -> void:
	if not _offer_active:
		return
	var selected: UpgradeDefinition
	for definition: UpgradeDefinition in current_offer:
		if definition.upgrade_id == upgrade_id:
			selected = definition
			break
	if selected == null:
		return
	_offer_active = false
	player.apply_upgrade(selected)
	owned_counts[upgrade_id] = get_acquired_count(upgrade_id) + 1
	run_manager.consume_pending_level_up()
	upgrade_selected.emit(upgrade_id)
	if run_manager.pending_level_ups > 0:
		_show_next_offer()
	else:
		current_offer.clear()
		screen.hide_offer()
		run_manager.begin_combat()


func _on_level_up_requested() -> void:
	if not _offer_active:
		_show_next_offer()


func _show_next_offer() -> void:
	current_offer = roll_offer()
	if current_offer.size() != 3:
		push_error("Não há três cartas elegíveis para a evolução.")
		return
	_offer_active = true
	screen.show_offer(current_offer, owned_counts)
	run_manager.set_state(RunProgress.RunState.UPGRADE_SELECTION)
