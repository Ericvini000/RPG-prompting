extends Resource
class_name UpgradeDefinition

enum Effect {
	DAMAGE,
	ATTACK_SPEED,
	MOVE_SPEED,
	VITALITY,
	PIERCE,
	TRIPLE_SHOT,
	FIRE,
	DASH_COOLDOWN,
}

@export var upgrade_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var effect_text: String = ""
@export var icon: Texture2D
@export var effect: Effect = Effect.DAMAGE
@export var magnitude: float = 0.0
@export var duration: float = 0.0
@export var max_stacks: int = 0
