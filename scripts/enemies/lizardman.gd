extends "res://scripts/enemies/enemy.gd"

# Lizardman reuses the full enemy AI (chase / return / attack / knockback /
# death / heart-drop) but renders through an AnimatedSprite2D + SpriteFrames
# instead of the Sprite2D + AnimationTree the Warrior/Goblin use. Only the
# visual + hitbox-timing hooks are overridden here.

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	super._ready()
	_sprite.animation_finished.connect(_on_anim_finished)
	update_animation()


func _visual() -> Node2D:
	return _sprite


func update_animation() -> void:
	match state:
		State.IDLE:
			_sprite.play("idle")
		State.CHASE:
			_sprite.play("run")
		State.RETURN:
			_sprite.play("walk")
		State.ATTACK:
			_sprite.play("attack")


func _on_anim_finished() -> void:
	# hurt/attack are one-shot; when they end, fall back to the state anim.
	if state == State.DEAD:
		return
	if _sprite.animation in ["hurt", "attack"]:
		update_animation()


func _attack_hitbox_on(attack_dir: Vector2) -> void:
	var hb := get_node_or_null("HitBox") as Area2D
	if hb == null:
		return
	# Reach the blade toward the player, then open the damage window mid-swing.
	var facing := -1.0 if attack_dir.x < 0.0 else 1.0
	hb.position = Vector2(40.0 * facing, -40.0)

	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self) or state == State.DEAD:
		return
	hb.monitoring = true

	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(hb):
		hb.monitoring = false


func take_damage(damage_taken: int, source_pos: Vector2 = Vector2.INF) -> void:
	var was_alive := state != State.DEAD
	super.take_damage(damage_taken, source_pos)
	# super may have triggered death(); only play hurt if still alive.
	if was_alive and state != State.DEAD and hitpoints > 0:
		_sprite.play("hurt")


func death() -> void:
	if state == State.DEAD:
		return
	var death_pos := global_position
	state = State.DEAD
	died.emit(death_pos)

	# Freeze combat: no more hits in or out.
	health_bar.visible = false
	var hb := get_node_or_null("HitBox") as Area2D
	if hb:
		hb.set_deferred("monitoring", false)
	var hurt := get_node_or_null("HurtBox") as Area2D
	if hurt:
		hurt.set_deferred("monitorable", false)

	_sprite.play("death")
	await _sprite.animation_finished
	if not is_instance_valid(self):
		return

	var effects := _get_effects_node()
	if effects:
		_maybe_drop_heart(effects, death_pos)
	_trigger_kill_hitstop()
	queue_free()
