extends Node

# Game-feel helpers that must outlive the nodes triggering them.

var _hitstop_active: bool = false


func kill_hitstop(scale: float = 0.15, real_duration: float = 0.09) -> void:
	# Brief slow-mo punch on a kill. Real-time timer so it always recovers,
	# and living here means the dying enemy freeing itself can't strand
	# Engine.time_scale below 1.
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = scale
	await get_tree().create_timer(real_duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false
