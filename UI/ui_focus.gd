class_name UIFocus
extends RefCounted

# Gamepad/keyboard menu support. TextureButtons have no visible focus style,
# so highlight the focused one and give the first visible button focus.

const FOCUS_TINT: Color = Color(1.35, 1.25, 0.9)


static func setup(root: Node) -> void:
	for button in _buttons_under(root):
		if not button.focus_entered.is_connected(_on_focus_entered.bind(button)):
			button.focus_entered.connect(_on_focus_entered.bind(button))
			button.focus_exited.connect(_on_focus_exited.bind(button))


static func focus_first(root: Node) -> void:
	for button in _buttons_under(root):
		if button.is_visible_in_tree() and button.focus_mode != Control.FOCUS_NONE:
			button.grab_focus()
			return


static func _buttons_under(root: Node) -> Array[BaseButton]:
	var out: Array[BaseButton] = []
	for node in root.find_children("*", "BaseButton", true, false):
		out.append(node as BaseButton)
	return out


static func _on_focus_entered(button: BaseButton) -> void:
	button.modulate = FOCUS_TINT


static func _on_focus_exited(button: BaseButton) -> void:
	button.modulate = Color.WHITE
