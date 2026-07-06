extends Node

# Persists per-bus volume to user://settings.cfg and restores it on launch.
# Buses not present in the file keep the default_bus_layout.tres values.

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "audio"
const SAVED_BUSES: Array[String] = ["Music", "sfx"]


func _ready() -> void:
	_load_volumes()


func _load_volumes() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for bus_name in SAVED_BUSES:
		if not config.has_section_key(SECTION, bus_name):
			continue
		var bus_id := AudioServer.get_bus_index(bus_name)
		if bus_id < 0:
			continue
		var linear: float = config.get_value(SECTION, bus_name)
		AudioServer.set_bus_volume_db(bus_id, linear_to_db(clampf(linear, 0.0001, 1.0)))


func save_bus_volume(bus_name: String, linear: float) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)  # keep existing entries; missing file is fine
	config.set_value(SECTION, bus_name, linear)
	config.save(SETTINGS_PATH)
