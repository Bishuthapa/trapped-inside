extends CanvasLayer

signal return_to_menu_pressed()
signal restart_pressed()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_main_menu_pressed() -> void:
	return_to_menu_pressed.emit()


func _on_restart_pressed() -> void:
	restart_pressed.emit()
