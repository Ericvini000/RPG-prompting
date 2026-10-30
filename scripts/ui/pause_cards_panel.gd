extends VBoxContainer
class_name PauseCardsPanel

@onready var _list: VBoxContainer = $Scroll/List


func refresh(manager: UpgradeManager) -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var acquired: Array[UpgradeDefinition] = manager.get_acquired_upgrades()
	if acquired.is_empty():
		var empty: Label = Label.new()
		empty.text = "Nenhuma carta adquirida nesta partida."
		_list.add_child(empty)
		return
	for definition: UpgradeDefinition in acquired:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.texture = definition.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var copy: Label = Label.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.text = "%s  ×%d\n%s  %s" % [definition.title, manager.get_acquired_count(definition.upgrade_id), definition.description, definition.effect_text]
		row.add_child(copy)
		_list.add_child(row)
