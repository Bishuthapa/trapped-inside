class_name UpgradeData
extends Resource

# One in-run upgrade. `effects` maps a RunState modifier name to the amount
# added per stack (see RunState.DEFAULT_MODS), plus two special keys handled
# by RunState.apply(): "max_hp" (int) and "restore_life" (int).

enum Rarity { COMMON, RARE, LEGENDARY }

const RARITY_NAMES: Array[String] = ["Common", "Rare", "Legendary"]
const RARITY_COLORS: Array[Color] = [
	Color(0.85, 0.85, 0.8),
	Color(0.4, 0.75, 1.0),
	Color(1.0, 0.7, 0.2),
]

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var max_stacks: int = 1
@export var effects: Dictionary = {}


static func make(p_id: String, p_title: String, p_description: String, p_rarity: Rarity, p_max_stacks: int, p_effects: Dictionary) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = p_id
	u.title = p_title
	u.description = p_description
	u.rarity = p_rarity
	u.max_stacks = p_max_stacks
	u.effects = p_effects
	return u


func rarity_name() -> String:
	return RARITY_NAMES[rarity]


func rarity_color() -> Color:
	return RARITY_COLORS[rarity]
