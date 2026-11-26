extends CanvasLayer

signal return_to_menu_pressed()


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
	stats.text = "Enemies slain: %d     Time: %s" % [pd.enemies_killed, pd.format_run_time()] + _run_summary()


func _on_main_menu_pressed() -> void:
	return_to_menu_pressed.emit()

func _run_summary() -> String:
	var titles: Array[String] = RunState.picked_titles()
	var upgrades := ", ".join(titles) if not titles.is_empty() else "none"
	return "\nUpgrades: %s\nSeed: %d" % [upgrades, RunState.run_seed]
