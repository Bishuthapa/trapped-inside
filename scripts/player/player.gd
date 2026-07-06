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
@export var attack_speed: float = 0.6
@export var attack_damage: int = 180
@export var attack_cooldown: float = 0.85
@export var dash_speed: int = 900
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 1.2

const INVULNERABILITY_TIME: float = 2.0
const HURT_FLASH_COLOR: Color = Color(1.5, 0.5, 0.5)
const SWORD_SWING_SFX: AudioStream = preload("res://assets/audio/sfx/sword_swing.mp3")
const NORMAL_ENEMY_HIT_SFX: AudioStream = preload("res://assets/audio/sfx/normal_enemy_hit.mp3")
const LARGE_ENEMY_HIT_SFX: AudioStream = preload("res://assets/audio/sfx/large_enemy_hit.mp3")
const SWORD_SLICE_SFX: AudioStream = preload("res://assets/audio/sfx/sword_slice.mp3")
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
var _attack_was_on_cooldown: bool = false
var _dash_was_on_cooldown: bool = false

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


func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEAD or _is_respawning or _is_dashing:
		return
	if event.is_action_pressed("dash"):
		try_dash()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		attack()


func _physics_process(delta: float) -> void:
	_update_cooldowns(delta)
	if state == State.DEAD or _is_respawning:
		return
	if _is_dashing:
		_process_dash(delta)
		return
	if state != State.ATTACK:
		movement_loop()


func _process_dash(delta: float) -> void:
	velocity = _dash_direction * dash_speed
	move_and_slide()
	_dash_time_left -= delta
	if _dash_time_left <= 0.0:
		_end_dash()


func _update_cooldowns(delta: float) -> void:
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
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))

	var motion: Vector2 = move_direction.normalized() * speed
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
	if _is_dashing or _dash_cooldown_left > 0.0 or state == State.ATTACK:
		return

	var dash_direction := move_direction
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.LEFT if $Sprite2D.flip_h else Vector2.RIGHT

	_start_dash(dash_direction.normalized())


func _start_dash(direction: Vector2) -> void:
	_is_dashing = true
	_invulnerable = true
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
	if state == State.ATTACK or _is_respawning or _attack_cooldown_left > 0.0:
		return

	state = State.ATTACK
	_attack_cooldown_left = attack_cooldown
	attack_cooldown_changed.emit(0.0)
	_play_sfx(SWORD_SWING_SFX)

	var mouse_pos: Vector2 = get_global_mouse_position()
	var attck_dir: Vector2 = (mouse_pos - global_position).normalized()
	$Sprite2D.flip_h = attck_dir.x < 0 and abs(attck_dir.x) >= abs(attck_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attck_dir)

	update_animation()

	await get_tree().create_timer(attack_speed).timeout
	if not is_instance_valid(self) or state == State.DEAD:
		return

	if move_direction != Vector2.ZERO:
		state = State.RUN
	else:
		state = State.IDLE

	update_animation()


func take_damage(damage_taken: int) -> void:
	if _invulnerable or state == State.DEAD or _is_respawning or _is_dashing:
		return
	_player_data.take_damage(damage_taken)
	if _player_data.hitpoints <= 0:
		_play_sfx(SWORD_SLICE_SFX)
	else:
		_play_sfx(NORMAL_ENEMY_HIT_SFX)
	_flash_hurt()
	_shake_camera()


func _flash_hurt() -> void:
	var sprite := $Sprite2D
	var original: Color = Color.WHITE
	sprite.modulate = HURT_FLASH_COLOR
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(sprite):
		sprite.modulate = original


func _shake_camera(strength: float = 6.0, duration: float = 0.18) -> void:
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


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.bus = "sfx"
	add_child(sfx_player)
	sfx_player.finished.connect(sfx_player.queue_free)
	sfx_player.play()


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
	if area.owner and area.owner.has_method("take_damage"):
		var target: Node = area.owner
		target.take_damage(attack_damage, global_position)
		var is_fatal: bool = is_instance_valid(target) and "hitpoints" in target and target.hitpoints <= 0
		if is_fatal:
			_play_sfx(SWORD_SLICE_SFX)
		elif "is_large_enemy" in target and target.is_large_enemy:
			_play_sfx(LARGE_ENEMY_HIT_SFX)
		else:
			_play_sfx(NORMAL_ENEMY_HIT_SFX)
