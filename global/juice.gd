extends Node

# Game-feel helpers that must outlive the nodes triggering them.
# Visual effects are parented to this autoload: Camera2D sets the root
# viewport's canvas transform, so Node2D children here render in world space
# and survive the enemy/player that spawned them being freed.

const NUMBER_FONT: FontFile = preload("res://UI/PirataOne-Regular.ttf")
const COLOR_NORMAL: Color = Color(1.0, 0.95, 0.85)
const COLOR_HEAVY: Color = Color(1.0, 0.65, 0.2)
const COLOR_CRIT: Color = Color(0.45, 0.95, 1.0)
const COLOR_LUCKY: Color = Color(1.0, 0.9, 0.3)
const COLOR_PLAYER_HURT: Color = Color(1.0, 0.3, 0.3)

var _time_scale_active: bool = false


func kill_hitstop(scale: float = 0.15, real_duration: float = 0.09) -> void:
	# Brief slow-mo punch on a kill. Real-time timer so it always recovers,
	# and living here means the dying enemy freeing itself can't strand
	# Engine.time_scale below 1.
	if not SaveData.hitstop_enabled():
		return
	slow_motion(scale, real_duration)


func slow_motion(scale: float, real_duration: float) -> void:
	if _time_scale_active:
		return
	_time_scale_active = true
	Engine.time_scale = scale
	await get_tree().create_timer(real_duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_time_scale_active = false


func damage_number(world_pos: Vector2, amount: int, color: Color = COLOR_NORMAL, big: bool = false) -> void:
	var holder := Node2D.new()
	holder.z_index = 100
	add_child(holder)
	holder.global_position = world_pos + Vector2(randf_range(-14.0, 14.0), -70.0)

	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_override("font", NUMBER_FONT)
	label.add_theme_font_size_override("font_size", 44 if big else 32)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.position = Vector2(-40, -24)
	label.size = Vector2(80, 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(label)

	holder.scale = Vector2.ONE * (1.5 if big else 1.2)
	var tween := holder.create_tween()
	tween.tween_property(holder, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(holder, "global_position:y", holder.global_position.y - 50.0, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(holder, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tween.finished.connect(holder.queue_free)


func text_popup(world_pos: Vector2, text: String, color: Color) -> void:
	var holder := Node2D.new()
	holder.z_index = 100
	add_child(holder)
	holder.global_position = world_pos + Vector2(0, -110.0)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", NUMBER_FONT)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.position = Vector2(-120, -24)
	label.size = Vector2(240, 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(label)
	var tween := holder.create_tween()
	tween.tween_property(holder, "global_position:y", holder.global_position.y - 30.0, 0.8)
	tween.parallel().tween_property(holder, "modulate:a", 0.0, 0.35).set_delay(0.5)
	tween.finished.connect(holder.queue_free)


func hit_burst(world_pos: Vector2, direction: Vector2 = Vector2.ZERO, color: Color = Color(1.0, 0.85, 0.6), amount: int = 10) -> void:
	# One-shot spark spray. CPUParticles2D so it works on the GL Compatibility renderer.
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.spread = 50.0 if direction != Vector2.ZERO else 180.0
	p.direction = direction if direction != Vector2.ZERO else Vector2.UP
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 360.0
	p.gravity = Vector2(0, 600)
	p.damping_min = 200.0
	p.damping_max = 300.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = color
	p.z_index = 50
	add_child(p)
	p.global_position = world_pos + Vector2(0, -32)
	p.finished.connect(p.queue_free)
	p.emitting = true
