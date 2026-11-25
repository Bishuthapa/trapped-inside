extends Node

# Persistent save: run statistics, meta progression and accessibility settings.
# Lives in user://save.cfg (separate from AudioSettings' user://settings.cfg so
# wiping progress never resets volume). Every write saves immediately — the data
# is tiny and this keeps web builds (which can close at any moment) safe.

signal settings_changed()

const SAVE_PATH: String = "user://save.cfg"
const SAVE_VERSION: int = 1

const DEFAULT_SETTINGS: Dictionary = {
	"screen_shake": true,
	"hitstop": true,
}

const DEFAULT_STATS: Dictionary = {
	"runs_started": 0,
	"runs_won": 0,
	"total_kills": 0,
	"best_time_sec": 0.0,  # fastest win; 0 = never won
	"deepest_level": 0,
}

const DEFAULT_META: Dictionary = {
	"bones": 0,
	"unlocks": [],
}

var _config := ConfigFile.new()


func _ready() -> void:
	var err := _config.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("SaveData: could not read %s (error %d), starting fresh." % [SAVE_PATH, err])
	_config.set_value("meta_info", "version", SAVE_VERSION)


# --- Settings -------------------------------------------------------------

func get_setting(key: String) -> Variant:
	return _config.get_value("settings", key, DEFAULT_SETTINGS.get(key))


func set_setting(key: String, value: Variant) -> void:
	_config.set_value("settings", key, value)
	_save()
	settings_changed.emit()


func screen_shake_enabled() -> bool:
	return bool(get_setting("screen_shake"))


func hitstop_enabled() -> bool:
	return bool(get_setting("hitstop"))


# --- Stats ----------------------------------------------------------------

func get_stat(key: String) -> Variant:
	return _config.get_value("stats", key, DEFAULT_STATS.get(key))


func record_run_started() -> void:
	_config.set_value("stats", "runs_started", int(get_stat("runs_started")) + 1)
	_save()


func record_level_reached(level_index: int) -> void:
	if level_index > int(get_stat("deepest_level")):
		_config.set_value("stats", "deepest_level", level_index)
		_save()


# Returns true when this run set a new best time.
func record_run_ended(won: bool, kills: int, time_sec: float) -> bool:
	_config.set_value("stats", "total_kills", int(get_stat("total_kills")) + kills)
	var new_best := false
	if won:
		_config.set_value("stats", "runs_won", int(get_stat("runs_won")) + 1)
		var best := float(get_stat("best_time_sec"))
		if best <= 0.0 or time_sec < best:
			_config.set_value("stats", "best_time_sec", time_sec)
			new_best = true
	_save()
	return new_best


# --- Meta progression (used by the roguelite hub later) --------------------

func get_bones() -> int:
	return int(_config.get_value("meta", "bones", DEFAULT_META["bones"]))


func add_bones(amount: int) -> void:
	_config.set_value("meta", "bones", maxi(get_bones() + amount, 0))
	_save()


func is_unlocked(id: String) -> bool:
	return id in _get_unlocks()


func unlock(id: String) -> void:
	var unlocks := _get_unlocks()
	if id in unlocks:
		return
	unlocks.append(id)
	_config.set_value("meta", "unlocks", unlocks)
	_save()


func _get_unlocks() -> Array:
	return (_config.get_value("meta", "unlocks", DEFAULT_META["unlocks"]) as Array).duplicate()


func reset_progress() -> void:
	# Keeps settings, wipes stats + meta.
	for section in ["stats", "meta"]:
		if _config.has_section(section):
			_config.erase_section(section)
	_save()


func _save() -> void:
	var err := _config.save(SAVE_PATH)
	if err != OK:
		push_warning("SaveData: failed to write %s (error %d)." % [SAVE_PATH, err])
