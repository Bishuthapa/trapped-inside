extends CharacterBody2D

signal update_hp_bar(hp_bar_value: int)
signal attack_cooldown_changed(ready_ratio: float)
signal dash_cooldown_changed(ready_ratio: float)

enum State {
	IDLE,
	RUN,
	ATTACK,
	DEAD
}

@export_category("Stats")
@export var speed: int = 400
@export var attack_damage: int = 60          # light hit; finisher deals FINISHER_MULT x this
@export var attack_cooldown: float = 0.35   # recovery after the 3rd (finisher) hit
@export var dash_speed: int = 900
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 1.2
@export var knockback_force: float = 320.0
@export var knockback_duration: float = 0.15

const INVULNERABILITY_TIME: float = 2.0

# 3-hit combo. Each swing replays the 0.6s attack animation at its own speed;
# the hitbox is live at 0.2-0.3s of animation time (set in player.tscn).
const ATTACK_ANIM_LENGTH: float = 0.6
const COMBO_TIME_SCALES: Array[float] = [1.8, 1.8, 1.25]
const COMBO_LUNGE: Array[float] = [10.0, 10.0, 26.0]
const COMBO_WINDOW: float = 0.35       # time after a swing ends to press attack and continue
const BUFFER_OPEN_RATIO: float = 0.25  # presses after this fraction of a swing are buffered
const FINISHER_MULT: float = 2.0
const FINISHER_KNOCKBACK_MULT: float = 2.2

# Perfect dodge: getting hit during the first part of a dash.
const PERFECT_DODGE_WINDOW: float = 0.12
const PERFECT_DODGE_SLOWMO: float = 0.35
const PERFECT_DODGE_SLOWMO_TIME: float = 0.35  # real seconds
const EMPOWER_MULT: float = 1.5
const EMPOWER_TIME: float = 2.0
const EMPOWER_COLOR: Color = Color(0.7, 1.3, 1.5)
const HURT_FLASH_COLOR: Color = Color(1.5, 0.5, 0.5)
const DEATH_SCENE: PackedScene = preload("res://assets/effects/death.tscn")

var state: State = State.IDLE
var move_direction: Vector2 = Vector2.ZERO
var hitpoints: int = PlayerDataService.MAX_HP
var hitpoint_max: int = PlayerDataService.MAX_HP

var spawn_position: Vector2
var _is_respawning: bool = false
var _invulnerable: bool = false
var _is_dashing: bool = false
var _dash_direction: Vector2 = Vector2.ZERO
var _dash_time_left: float = 0.0
var _attack_cooldown_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_time: float = 0.0
var _attack_was_on_cooldown: bool = false
var _dash_was_on_cooldown: bool = false
var _using_gamepad: bool = false
var _combo_step: int = 0
var _combo_window_left: float = 0.0
var _swing_time_left: float = 0.0
var _swing_length: float = 0.0
var _attack_buffered: bool = false
var _swing_hit_targets: Array[Node] = []
var _empowered_time_left: float = 0.0
var _perfect_dodge_used: bool = false

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var _player_data: PlayerDataService = get_node("/root/PlayerData")


func _ready() -> void:
	spawn_position = global_position
	hitpoint_max = _player_data.MAX_HP
	sync_from_player_data()
	animation_tree.active = true
	if not _player_data.hp_changed.is_connected(_on_player_data_hp_changed):
		_player_data.hp_changed.connect(_on_player_data_hp_changed)
	attack_cooldown_changed.emit(1.0)
	dash_cooldown_changed.emit(1.0)


func sync_from_player_data() -> void:
	hitpoints = _player_data.hitpoints
	hitpoint_max = _player_data.MAX_HP
	_emit_hp_bar()


func _emit_hp_bar() -> void:
	if hitpoint_max <= 0:
		return
	@warning_ignore("integer_division")
	update_hp_bar.emit(hitpoints * 100 / hitpoint_max)


func _input(event: InputEvent) -> void:
	# Track the last device used so aiming follows the mouse or the right stick.
	if event is InputEventJoypadButton:
		_using_gamepad = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.3:
		_using_gamepad = true
	elif event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		_using_gamepad = false


func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEAD or _is_respawning or _is_dashing:
		return
	if event.is_action_pressed("dash"):
		try_dash()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("attack"):
		attack()


func _physics_process(delta: float) -> void:
	_update_cooldowns(delta)
	if state == State.DEAD or _is_respawning:
		return
	if _is_dashing:
		_process_dash(delta)
		return
	if _knockback_time > 0.0:
		_process_knockback(delta)
		return
	if state == State.ATTACK:
		_process_swing(delta)
	else:
		movement_loop()


func _process_knockback(delta: float) -> void:
	velocity = _knockback_velocity
	move_and_slide()
	_knockback_time -= delta
	if _knockback_time <= 0.0:
		_knockback_velocity = Vector2.ZERO


func _process_dash(delta: float) -> void:
	velocity = _dash_direction * dash_speed
	move_and_slide()
	_dash_time_left -= delta
	if _dash_time_left <= 0.0:
		_end_dash()


func _update_cooldowns(delta: float) -> void:
	if _combo_window_left > 0.0:
		_combo_window_left -= delta
		if _combo_window_left <= 0.0:
			_combo_step = 0
	if _empowered_time_left > 0.0:
		_empowered_time_left -= delta
		if _empowered_time_left <= 0.0:
			_set_empowered_visual(false)

	if _attack_cooldown_left > 0.0:
		_attack_was_on_cooldown = true
		_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
		attack_cooldown_changed.emit(1.0 - _attack_cooldown_left / attack_cooldown)
	elif _attack_was_on_cooldown:
		_attack_was_on_cooldown = false
		attack_cooldown_changed.emit(1.0)

	if _dash_cooldown_left > 0.0:
		_dash_was_on_cooldown = true
		_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
		dash_cooldown_changed.emit(1.0 - _dash_cooldown_left / dash_cooldown)
	elif _dash_was_on_cooldown:
		_dash_was_on_cooldown = false
		dash_cooldown_changed.emit(1.0)


func movement_loop() -> void:
	# get_vector gives analog stick values and already normalizes keyboard diagonals.
	move_direction = Input.get_vector("left", "right", "up", "down")

	var motion: Vector2 = move_direction * speed
	velocity = motion
	move_and_slide()

	if state in [State.IDLE, State.RUN]:
		if move_direction.x < 0:
			$Sprite2D.flip_h = true
		elif move_direction.x > 0:
			$Sprite2D.flip_h = false

	if motion != Vector2.ZERO and state == State.IDLE:
		state = State.RUN
		update_animation()
	elif motion == Vector2.ZERO and state == State.RUN:
		state = State.IDLE
		update_animation()


func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.RUN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")


func try_dash() -> void:
	if _is_dashing or _dash_cooldown_left > 0.0:
		return
	if state == State.ATTACK:
		# Dash-cancel is allowed once the swing's hit window has passed.
		if _swing_time_left > _swing_length * 0.5:
			return
		_cancel_swing()

	var dash_direction := move_direction
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.LEFT if $Sprite2D.flip_h else Vector2.RIGHT

	_start_dash(dash_direction.normalized())


func _start_dash(direction: Vector2) -> void:
	_is_dashing = true
	_invulnerable = true
	_perfect_dodge_used = false
	_dash_direction = direction
	_dash_time_left = dash_duration

	if direction.x < 0:
		$Sprite2D.flip_h = true
	elif direction.x > 0:
		$Sprite2D.flip_h = false


func _end_dash() -> void:
	_is_dashing = false
	_invulnerable = false
	velocity = Vector2.ZERO
	_dash_cooldown_left = dash_cooldown
	_dash_was_on_cooldown = true
	dash_cooldown_changed.emit(0.0)


func attack() -> void:
	if state == State.DEAD or _is_respawning or _is_dashing:
		return
	if state == State.ATTACK:
		# Mid-swing press: queue the next combo hit.
		if _combo_step < COMBO_TIME_SCALES.size() - 1 and _swing_time_left < _swing_length * (1.0 - BUFFER_OPEN_RATIO):
			_attack_buffered = true
		return
	if _attack_cooldown_left > 0.0:
		return
	if _combo_window_left > 0.0 and _combo_step < COMBO_TIME_SCALES.size() - 1:
		_combo_step += 1
	else:
		_combo_step = 0
	_combo_window_left = 0.0
	_start_swing()


func _start_swing() -> void:
	_attack_buffered = false
	_swing_hit_targets.clear()
	state = State.ATTACK
	var time_scale: float = COMBO_TIME_SCALES[_combo_step]
	_swing_length = ATTACK_ANIM_LENGTH / time_scale
	_swing_time_left = _swing_length

	var attack_dir: Vector2 = _get_aim_direction()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	animation_tree.set("parameters/attack/TimeScale/scale", time_scale)
	animation_playback.start("attack", true)

	# Small step into the swing; bigger on the finisher.
	move_and_collide(attack_dir * COMBO_LUNGE[_combo_step])
	Sfx.play("sword_swing")


func _process_swing(delta: float) -> void:
	velocity = Vector2.ZERO
	_swing_time_left -= delta
	if _swing_time_left > 0.0:
		return
	_finish_swing()


func _finish_swing() -> void:
	var last_step := COMBO_TIME_SCALES.size() - 1
	if _attack_buffered and _combo_step < last_step:
		_combo_step += 1
		_start_swing()
		return

	if _combo_step >= last_step:
		_combo_step = 0
		_attack_cooldown_left = attack_cooldown
		_attack_was_on_cooldown = true
		attack_cooldown_changed.emit(0.0)
	else:
		_combo_window_left = COMBO_WINDOW

	_return_to_locomotion()


func _cancel_swing() -> void:
	_attack_buffered = false
	_swing_time_left = 0.0
	_combo_step = 0
	_combo_window_left = 0.0
	$HitBox.set_deferred("monitoring", false)
	_return_to_locomotion()


func _return_to_locomotion() -> void:
	animation_tree.set("parameters/attack/TimeScale/scale", 1.0)
	state = State.RUN if move_direction != Vector2.ZERO else State.IDLE
	update_animation()


func _is_finisher() -> bool:
	return _combo_step == COMBO_TIME_SCALES.size() - 1


func _get_aim_direction() -> Vector2:
	if not _using_gamepad:
		return (get_global_mouse_position() - global_position).normalized()
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick != Vector2.ZERO:
		return stick.normalized()
	if move_direction != Vector2.ZERO:
		return move_direction.normalized()
	return Vector2.LEFT if $Sprite2D.flip_h else Vector2.RIGHT


func take_damage(damage_taken: int, source_pos: Vector2 = Vector2.INF) -> void:
	if _is_dashing and not _is_respawning:
		_try_perfect_dodge()
		return
	if _invulnerable or state == State.DEAD or _is_respawning:
		return
	_player_data.take_damage(damage_taken)
	Juice.damage_number(global_position, damage_taken, Juice.COLOR_PLAYER_HURT)
	if _player_data.hitpoints <= 0:
		Sfx.play("sword_slice")
	else:
		Sfx.play("hit")
	_flash_hurt()
	_shake_camera()
	_apply_knockback(source_pos)


func _try_perfect_dodge() -> void:
	# Only the first PERFECT_DODGE_WINDOW seconds of a dash count, once per dash.
	if _perfect_dodge_used or (dash_duration - _dash_time_left) > PERFECT_DODGE_WINDOW:
		return
	_perfect_dodge_used = true
	_attack_cooldown_left = 0.0
	attack_cooldown_changed.emit(1.0)
	_empowered_time_left = EMPOWER_TIME
	_set_empowered_visual(true)
	Juice.text_popup(global_position, "Perfect!", Juice.COLOR_CRIT)
	Juice.slow_motion(PERFECT_DODGE_SLOWMO, PERFECT_DODGE_SLOWMO_TIME)
	Sfx.play("sword_swing")


func _set_empowered_visual(on: bool) -> void:
	$Sprite2D.self_modulate = EMPOWER_COLOR if on else Color.WHITE


func _apply_knockback(source_pos: Vector2) -> void:
	if source_pos == Vector2.INF:
		return
	var direction := (global_position - source_pos).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	_knockback_velocity = direction * knockback_force
	_knockback_time = knockback_duration


func _flash_hurt() -> void:
	var sprite := $Sprite2D
	var original: Color = Color.WHITE
	sprite.modulate = HURT_FLASH_COLOR
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(sprite):
		sprite.modulate = original


func _shake_camera(strength: float = 6.0, duration: float = 0.18) -> void:
	if not SaveData.screen_shake_enabled():
		return
	var camera := $Camera2D as Camera2D
	if camera == null:
		return
	var tween := create_tween()
	var steps := 4
	for i in steps:
		var fade := 1.0 - float(i) / steps
		var offset := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * fade
		tween.tween_property(camera, "offset", offset, duration / steps)
	tween.tween_property(camera, "offset", Vector2.ZERO, duration / steps)


func _on_player_data_hp_changed(new_hp: int, max_hp: int) -> void:
	hitpoints = new_hp
	hitpoint_max = max_hp
	_emit_hp_bar()
	if new_hp > 0 or state == State.DEAD or _is_respawning:
		return
	if _player_data.lives > 0:
		_handle_hp_depleted()
	else:
		_enter_game_over_state()


func _handle_hp_depleted() -> void:
	if _player_data.lose_life():
		respawn()
	else:
		_enter_game_over_state()


func respawn() -> void:
	_is_respawning = true
	_invulnerable = true
	state = State.IDLE
	velocity = Vector2.ZERO
	global_position = spawn_position
	sync_from_player_data()
	update_animation()
	_blink_while_invulnerable()
	await get_tree().create_timer(INVULNERABILITY_TIME).timeout
	if is_instance_valid(self):
		_invulnerable = false
		_is_respawning = false


func _blink_while_invulnerable() -> void:
	var sprite := $Sprite2D
	var blink := create_tween()
	blink.set_loops(int(INVULNERABILITY_TIME / 0.3))
	blink.tween_property(sprite, "modulate:a", 0.35, 0.15)
	blink.tween_property(sprite, "modulate:a", 1.0, 0.15)
	blink.finished.connect(func() -> void:
		if is_instance_valid(sprite):
			sprite.modulate.a = 1.0)


func _enter_game_over_state() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector2.ZERO
	animation_tree.active = false
	$Sprite2D.visible = false
	# Stop enemies from targeting and hitting the corpse.
	remove_from_group("player")
	$HurtBox.set_deferred("monitorable", false)
	$HitBox.set_deferred("monitoring", false)
	_spawn_death_skull()


func _spawn_death_skull() -> void:
	var skull := DEATH_SCENE.instantiate()
	skull.persist_last_frame = true
	# Game-over pauses the tree right before this spawns — keep the skull
	# animating through the pause.
	skull.process_mode = Node.PROCESS_MODE_ALWAYS
	get_parent().add_child(skull)
	skull.global_position = global_position + Vector2(0.0, -32.0)


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.owner == null or not area.owner.has_method("take_damage"):
		return
	var target: Node = area.owner
	if target in _swing_hit_targets:
		return  # one hit per target per swing
	_swing_hit_targets.append(target)

	var finisher := _is_finisher()
	var empowered := _empowered_time_left > 0.0
	var damage := float(attack_damage)
	if finisher:
		damage *= FINISHER_MULT
	if empowered:
		damage *= EMPOWER_MULT
	var dmg := int(round(damage))

	var target_pos: Vector2 = (target as Node2D).global_position if target is Node2D else global_position
	target.take_damage(dmg, global_position)
	if finisher and is_instance_valid(target) and target.has_method("boost_knockback"):
		target.boost_knockback(FINISHER_KNOCKBACK_MULT)

	if empowered:
		# Empowered bonus is spent on the first swing that connects.
		_empowered_time_left = 0.0
		_set_empowered_visual(false)

	var hit_dir := (target_pos - global_position).normalized()
	var color := Juice.COLOR_CRIT if empowered else (Juice.COLOR_HEAVY if finisher else Juice.COLOR_NORMAL)
	Juice.damage_number(target_pos, dmg, color, finisher or empowered)
	Juice.hit_burst(target_pos, hit_dir, color, 16 if finisher else 9)

	var is_fatal: bool = is_instance_valid(target) and "hitpoints" in target and target.hitpoints <= 0
	if is_fatal:
		Sfx.play("sword_slice")
		# Killing blow: bigger shake to sell the kill (hitstop is fired by
		# the enemy's own death() via the Juice autoload).
		_shake_camera(10.0, 0.28)
	elif finisher or ("is_large_enemy" in target and target.is_large_enemy):
		Sfx.play("hit_large")
		_shake_camera(6.0, 0.18)
	else:
		Sfx.play("hit")
		_shake_camera(3.0, 0.12)
