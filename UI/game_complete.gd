extends CanvasLayer

signal return_to_menu_pressed()
signal restart_pressed()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_stats()


func _populate_stats() -> void:
	var pd: Node = get_node_or_null("/root/PlayerData")
	var stats: Label = get_node_or_null("CenterContainer/VBoxContainer/Stats")
	if pd == null or stats == null:
		return
	stats.text = "Enemies slain: %d     Time: %s" % [pd.enemies_killed, pd.format_run_time()]


func _on_main_menu_pressed() -> void:
	return_to_menu_pressed.emit()


func _on_restart_pressed() -> void:
	restart_pressed.emit()
