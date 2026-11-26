extends Node

# State of the current run: seed, picked upgrades and the stat modifiers they
# add up to. Reset by start_run() at the beginning of every new game.
# Gameplay code reads modifiers through the helpers at the bottom, so base
# stats in scenes stay the reference and upgrades only scale them.

signal upgrades_changed()

const CHOICES_PER_PICK: int = 3
const REROLLS_PER_PICK: int = 1
const RARITY_WEIGHTS: Array[float] = [70.0, 25.0, 5.0]

# Additive modifiers. *_mult values start at 1.0 and are multiplied into stats.
const DEFAULT_MODS: Dictionary = {
	"damage_mult": 1.0,
	"attack_speed_mult": 1.0,
	"move_speed_mult": 1.0,
	"dash_cooldown_mult": 1.0,
	"crit_chance": 0.0,
	"finisher_mult_bonus": 0.0,
	"heal_on_kill": 0,
	"heart_drop_bonus": 0.0,
	"perfect_window_bonus": 0.0,
	"empower_mult_bonus": 0.0,
	"finisher_area_mult": 1.0,
}

var run_seed: int = 0
var rng := RandomNumberGenerator.new()
var picked: Array[String] = []
var mods: Dictionary = DEFAULT_MODS.duplicate()


func start_run(p_seed: int = -1) -> void:
	if p_seed < 0:
		var r := RandomNumberGenerator.new()
		r.randomize()
		p_seed = r.randi() % 1000000
	run_seed = p_seed
	rng.seed = run_seed
	seed(run_seed)  # global randf() (heart drops etc.) follows the run seed too
	picked.clear()
	mods = DEFAULT_MODS.duplicate()
	upgrades_changed.emit()


func stacks_of(id: String) -> int:
	return picked.count(id)


func is_available(u: UpgradeData) -> bool:
	if stacks_of(u.id) >= u.max_stacks:
		return false
	if u.effects.has("restore_life"):
		var pd: Node = get_node_or_null("/root/PlayerData")
		if pd and pd.lives >= pd.MAX_LIVES:
			return false
	return true


func roll_choices(count: int = CHOICES_PER_PICK, exclude: Array[String] = []) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for u in UpgradeCatalog.all():
		if is_available(u) and u.id not in exclude:
			pool.append(u)
	var result: Array[UpgradeData] = []
	while result.size() < count and not pool.is_empty():
		var total := 0.0
		for u in pool:
			total += RARITY_WEIGHTS[u.rarity]
		var roll := rng.randf() * total
		for u in pool:
			roll -= RARITY_WEIGHTS[u.rarity]
			if roll <= 0.0:
				result.append(u)
				pool.erase(u)
				break
	return result


func apply(u: UpgradeData) -> void:
	picked.append(u.id)
	var pd: Node = get_node_or_null("/root/PlayerData")
	for key in u.effects:
		var amount = u.effects[key]
		match key:
			"max_hp":
				if pd:
					pd.increase_max_hp(int(amount))
			"restore_life":
				if pd:
					pd.restore_life()
			_:
				if mods.has(key):
					mods[key] += amount
				else:
					push_warning("RunState: unknown upgrade effect '%s'" % key)
	upgrades_changed.emit()


func picked_titles() -> Array[String]:
	# "Sharpened Blade x2", in pick order, one entry per upgrade.
	var out: Array[String] = []
	var seen: Array[String] = []
	for id in picked:
		if id in seen:
			continue
		seen.append(id)
		var u := UpgradeCatalog.by_id(id)
		var n := stacks_of(id)
		out.append(u.title + (" x%d" % n if n > 1 else ""))
	return out


# --- Read helpers used by gameplay code -------------------------------------

func mod(key: String) -> float:
	return float(mods.get(key, DEFAULT_MODS.get(key, 0.0)))


func roll_crit() -> bool:
	# Global randf so combat rolls never shift which upgrades the run seed offers.
	return randf() < mod("crit_chance")
