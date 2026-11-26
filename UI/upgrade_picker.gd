extends CanvasLayer

# "Choose 1 of 3" upgrade screen shown after each cleared room. Built in code
# (no .tscn) so card count and layout follow RunState settings. Runs while the
# tree is paused; the caller pauses before adding it and unpauses on `closed`.
# Input: click a card, 1/2/3 keys, or d-pad/stick + A. R or the button rerolls.

signal closed(upgrade: UpgradeData)

const FONT: FontFile = preload("res://UI/PirataOne-Regular.ttf")
const CARD_SIZE: Vector2 = Vector2(320, 380)

var _choices: Array[UpgradeData] = []
var _rerolls_left: int = RunState.REROLLS_PER_PICK
var _cards_box: HBoxContainer
var _reroll_button: Button
var _done: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_frame()
	_choices = RunState.roll_choices()
	if _choices.is_empty():
		# Every upgrade is maxed out: nothing to pick.
		_finish.call_deferred(null)
		return
	_build_cards()


func _build_frame() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 28)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	column.add_child(_label("Room cleared", 64, Color(1.0, 0.85, 0.55)))
	column.add_child(_label("Choose an upgrade", 34, Color(0.9, 0.9, 0.9)))

	_cards_box = HBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 32)
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_cards_box)

	_reroll_button = Button.new()
	_reroll_button.add_theme_font_override("font", FONT)
	_reroll_button.add_theme_font_size_override("font_size", 30)
	_reroll_button.custom_minimum_size = Vector2(260, 56)
	_reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reroll_button.pressed.connect(_reroll)
	column.add_child(_reroll_button)
	_update_reroll_text()


func _build_cards() -> void:
	for child in _cards_box.get_children():
		child.queue_free()
	for i in _choices.size():
		_cards_box.add_child(_make_card(_choices[i], i))
	UIFocus.setup(self)
	_focus_first_card.call_deferred()


func _focus_first_card() -> void:
	for child in _cards_box.get_children():
		if not child.is_queued_for_deletion() and child is Button:
			child.grab_focus()
			return


func _make_card(u: UpgradeData, index: int) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_ALL
	card.pressed.connect(_pick.bind(index))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.09, 0.08, 0.95)
	style.border_color = u.rarity_color()
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.2, 0.17, 0.13, 0.98)
	hover.set_border_width_all(7)
	card.add_theme_stylebox_override("normal", style)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("focus", hover)
	card.add_theme_stylebox_override("pressed", hover)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 22
	box.offset_right = -22
	box.offset_top = 26
	box.offset_bottom = -22
	box.add_theme_constant_override("separation", 18)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	box.add_child(_label("%d · %s" % [index + 1, u.rarity_name()], 24, u.rarity_color()))
	box.add_child(_label(u.title, 42, Color.WHITE))
	var desc := _label(u.description, 28, Color(0.85, 0.85, 0.8))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)
	var owned := RunState.stacks_of(u.id)
	var stacks_text := "Max %d" % u.max_stacks if owned == 0 else "Owned %d / %d" % [owned, u.max_stacks]
	box.add_child(_label(stacks_text, 22, Color(0.6, 0.6, 0.6)))
	return card


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _unhandled_input(event: InputEvent) -> void:
	if _done or not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: int = event.physical_keycode
	if key >= KEY_1 and key <= KEY_9 and key - KEY_1 < _choices.size():
		_pick(key - KEY_1)
		get_viewport().set_input_as_handled()
	elif key == KEY_R:
		_reroll()
		get_viewport().set_input_as_handled()


func _reroll() -> void:
	if _done or _rerolls_left <= 0:
		return
	var current: Array[String] = []
	for u in _choices:
		current.append(u.id)
	var fresh := RunState.roll_choices(RunState.CHOICES_PER_PICK, current)
	if fresh.is_empty():
		return  # nothing else left to offer; keep the current cards
	_rerolls_left -= 1
	_choices = fresh
	_build_cards()
	_update_reroll_text()
	Sfx.play("sword_swing")


func _update_reroll_text() -> void:
	_reroll_button.text = "Reroll (%d)  [R]" % _rerolls_left
	_reroll_button.disabled = _rerolls_left <= 0


func _pick(index: int) -> void:
	if _done or index < 0 or index >= _choices.size():
		return
	var u := _choices[index]
	RunState.apply(u)
	Sfx.play("sword_slice", Vector2.INF, false)
	_finish(u)


func _finish(u: UpgradeData) -> void:
	if _done:
		return
	_done = true
	closed.emit(u)
	queue_free()
