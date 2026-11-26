class_name UpgradeCatalog
extends RefCounted

# Every upgrade that can show up during a run. To add one: append a line here.
# Effect keys must exist in RunState.DEFAULT_MODS (or be "max_hp" / "restore_life").
# Numbers are tuned against docs/Balance.md.

const C := UpgradeData.Rarity.COMMON
const R := UpgradeData.Rarity.RARE
const L := UpgradeData.Rarity.LEGENDARY

static var _all: Array[UpgradeData] = []


static func all() -> Array[UpgradeData]:
	if _all.is_empty():
		_all = [
			# --- Common ---
			UpgradeData.make("sharpened_blade", "Sharpened Blade", "+20% sword damage.", C, 5, {"damage_mult": 0.2}),
			UpgradeData.make("quick_hands", "Quick Hands", "Swing 15% faster.", C, 3, {"attack_speed_mult": 0.15}),
			UpgradeData.make("fleet_foot", "Fleet Foot", "Move 12% faster.", C, 3, {"move_speed_mult": 0.12}),
			UpgradeData.make("shadow_step", "Shadow Step", "Dash cooldown -20%.", C, 3, {"dash_cooldown_mult": -0.2}),
			UpgradeData.make("iron_skin", "Iron Skin", "+40 max HP and heal 40.", C, 5, {"max_hp": 40}),
			UpgradeData.make("bloodthirst", "Bloodthirst", "Heal 8 HP on every kill.", C, 3, {"heal_on_kill": 8}),
			UpgradeData.make("scavenger", "Scavenger", "Enemies are 15% more likely to drop hearts.", C, 2, {"heart_drop_bonus": 0.15}),
			# --- Rare ---
			UpgradeData.make("lucky_strike", "Lucky Strike", "12% chance to crit for double damage.", R, 3, {"crit_chance": 0.12}),
			UpgradeData.make("executioner", "Executioner", "Combo finisher deals 3x damage instead of 2x.", R, 2, {"finisher_mult_bonus": 1.0}),
			UpgradeData.make("riposte", "Riposte", "Bigger perfect-dodge window; empowered hits deal 2x.", R, 2, {"perfect_window_bonus": 0.06, "empower_mult_bonus": 0.5}),
			UpgradeData.make("whirlwind", "Whirlwind", "Combo finisher reaches 40% further.", R, 2, {"finisher_area_mult": 0.4}),
			# --- Legendary ---
			UpgradeData.make("second_wind", "Second Wind", "Restore one lost life.", L, 1, {"restore_life": 1}),
			UpgradeData.make("blade_dance", "Blade Dance", "Swing 30% faster and move 10% faster.", L, 1, {"attack_speed_mult": 0.3, "move_speed_mult": 0.1}),
		]
	return _all


static func by_id(id: String) -> UpgradeData:
	for u in all():
		if u.id == id:
			return u
	return null
