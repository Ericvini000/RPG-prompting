extends VBoxContainer
class_name PauseStatsPanel

@onready var _values: Label = $Values


func refresh(player: PlayerController) -> void:
	var stats: PlayerRuntimeStats = player.runtime_stats
	var elemental: String = "Flecha Flamejante (%d dano/s por %.0f s)" % [stats.burn_damage_per_second, stats.burn_duration] if stats.fire_arrow else "Nenhuma"
	_values.text = "Vida: %d / %d\nDano por flecha: %d\nAtaques por segundo: %.2f\nMovimento: %.0f px/s\nRecarga do dash: %.2f s\nFlechas por disparo: %d\nPerfurações adicionais: %d\nHabilidades elementais: %s" % [
		player.health.current, player.health.maximum,
		stats.effective_damage(), 1.0 / stats.effective_attack_interval(),
		stats.effective_move_speed(), stats.effective_dash_cooldown(),
		stats.arrows_per_shot(), stats.pierce_count, elemental,
	]
