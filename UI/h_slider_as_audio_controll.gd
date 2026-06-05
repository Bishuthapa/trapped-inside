extends HSlider

@export var audio_bus_name: String

var _audio_bus_id: int = -1


func _ready() -> void:
	_audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	if _audio_bus_id < 0:
		push_warning("Audio bus not found: %s" % audio_bus_name)
		return
	value = db_to_linear(AudioServer.get_bus_volume_db(_audio_bus_id))


@warning_ignore("shadowed_variable_base_class")
func _on_value_changed(value: float) -> void:
	if _audio_bus_id < 0:
		return
	AudioServer.set_bus_volume_db(_audio_bus_id, linear_to_db(value))
