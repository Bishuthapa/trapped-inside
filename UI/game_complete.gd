extends CanvasLayer

signal return_to_menu_pressed()
signal restart_pressed()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_stats()
	UIFocus.setup(self)
	UIFocus.focus_first.call_deferred(self)


func _populate_stats() -> void:
	var pd: Node = get_node_or_null("/root/PlayerData")
	var stats: Label = get_node_or_null("CenterContainer/VBoxContainer/Stats")
	if pd == null or stats == null:
		return
	var text := "Enemies slain: %d     Time: %s" % [pd.enemies_killed, pd.format_run_time()]
	var best := float(SaveData.get_stat("best_time_sec"))
	if best > 0.0:
		if is_equal_approx(best, pd.get_run_time_seconds()):
			text += "
New best time!"
		else:
			@warning_ignore("integer_division")
			text += "
Best: %d:%02d" % [int(best) / 60, int(best) % 60]
	stats.text = text + _run_summary()


func _on_main_menu_pressed() -> void:
	return_to_menu_pressed.emit()


func _on_restart_pressed() -> void:
	restart_pressed.emit()

func _run_summary() -> String:
	var titles: Array[String] = RunState.picked_titles()
	var upgrades := ", ".join(titles) if not titles.is_empty() else "none"
	return "\nUpgrades: %s\nSeed: %d" % [upgrades, RunState.run_seed]
