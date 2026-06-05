extends CharacterBody2D

enum State {
	IDLE,
	CHASE,
	RETURN,
	ATTACK,
	DEAD
}

@export_category("Stats")
@export_category("Related Scenes")
@export var death_packed: PackedScene
@export var speed: int = 128
@export var attack_damage: int = 30
@export var attack_speed: float = 1.0
@export var hitpoints:int = 180
@export var max_hitpoints: int = 180
@export var aggro_range: float = 400.0
@export var attack_range: float = 80.0
@export var knockback_force: float = 420.0
@export var knockback_duration: float = 0.15
@export_category("Related Scenes")

var state: State = State.IDLE
var previous_state: State = State.IDLE
var _is_attacking: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_time: float = 0.0


@onready var spawn_point: Vector2 = global_position
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree ["parameters/playback"]
@onready var health_bar: TextureProgressBar = $HealthBar

@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D

signal died(pos: Vector2)

func _ready() -> void:
	animation_tree.set_active(true)
	hitpoints = max_hitpoints
	health_bar.max_value = max_hitpoints
	health_bar.value = hitpoints


func _get_player() -> CharacterBody2D:
	var node := get_tree().get_first_node_in_group("player")
	if node is CharacterBody2D and is_instance_valid(node):
		return node
	return null


func _get_effects_node() -> Node2D:
	var node: Node = self
	while node:
		var effects := node.get_node_or_null("Effects") as Node2D
		if effects:
			return effects
		node = node.get_parent()
	return null


func configure_as_boss(extra_hp: int = 200, scale_factor: float = 1.3) -> void:
	max_hitpoints += extra_hp
	hitpoints = max_hitpoints
	health_bar.max_value = max_hitpoints
	health_bar.value = hitpoints
	scale = Vector2.ONE * scale_factor


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(self):
		return
	if state == State.DEAD:
		return

	if _knockback_time > 0.0:
		_knockback_time = maxf(_knockback_time - _delta, 0.0)
		velocity = _knockback_velocity
		move_and_slide()
		if _knockback_time <= 0.0:
			_knockback_velocity = Vector2.ZERO
		return

	var next_state: State = _determine_next_state()
	if next_state != state:
		_change_state(next_state)

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.CHASE, State.RETURN:
			move()
		State.ATTACK:
			velocity = Vector2.ZERO
	move_and_slide()

	if state in [State.IDLE, State.CHASE, State.RETURN]:
		if velocity.x < -0.01:
			$Sprite2D.flip_h = true
		elif velocity.x > 0.01:
			$Sprite2D.flip_h = false


func _determine_next_state() -> State:
	if _is_attacking:
		return State.ATTACK

	if distance_to_player() <= attack_range:
		return State.ATTACK

	if distance_to_player() <= aggro_range:
		return State.CHASE

	if global_position.distance_to(spawn_point) > 32.0:
		return State.RETURN

	return State.IDLE


func _change_state(new_state: State) -> void:
	previous_state = state
	state = new_state
	update_animation()

	if state == State.ATTACK:
		attack()


func distance_to_player() -> float:
	var target_player := _get_player()
	if target_player == null:
		return INF
	return global_position.distance_to(target_player.global_position)
	
	
func attack() -> void:
	if _is_attacking or state == State.DEAD:
		return

	_is_attacking = true

	var target_player := _get_player()
	if target_player == null:
		_is_attacking = false
		return

	var player_pos: Vector2 = target_player.global_position
	var attack_dir: Vector2 = (player_pos - global_position).normalized()
	$Sprite2D.flip_h = attack_dir.x < 0 and abs(attack_dir.x) >= abs(attack_dir.y)
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	
	await get_tree().create_timer(attack_speed).timeout
	if not is_instance_valid(self):
		return
	_is_attacking = false

	if state == State.DEAD:
		return

	if _get_player() == null:
		return

	var next_state: State = _state_after_attack()
	if next_state != state:
		_change_state(next_state)


func _state_after_attack() -> State:
	# Prefer returning to the previous locomotion state when still valid,
	# otherwise re-evaluate from current world conditions.
	if previous_state == State.CHASE and distance_to_player() <= aggro_range:
		return State.CHASE

	if previous_state == State.RETURN and global_position.distance_to(spawn_point) > 32.0:
		return State.RETURN

	if previous_state == State.IDLE:
		return State.IDLE

	return _determine_next_state()
	

func move() -> void:
	if state == State.CHASE:
		var target_player := _get_player()
		if target_player == null:
			return
		nav_agent.target_position = target_player.global_position
	elif state == State.RETURN:
		nav_agent.target_position = spawn_point
	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	velocity =global_position.direction_to(next_path_position) * speed
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(velocity)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	nav_agent.velocity = safe_velocity


func update_animation() -> void:
	match state:
		State.IDLE:
			animation_playback.travel("idle")
		State.CHASE:
			animation_playback.travel("run")
		State.RETURN:
			animation_playback.travel("run")
		State.ATTACK:
			animation_playback.travel("attack")

func take_damage(damage_taken: int, source_pos: Vector2 = Vector2.INF) -> void:
	if state == State.DEAD:
		return
	hitpoints -= damage_taken
	hitpoints = clamp(hitpoints, 0, max_hitpoints)
	health_bar.value = hitpoints
	_apply_knockback(source_pos)
	_flash_hit()
	if hitpoints <= 0:
		death()


func _apply_knockback(source_pos: Vector2) -> void:
	if source_pos == Vector2.INF:
		return
	var direction := (global_position - source_pos).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	_knockback_velocity = direction * knockback_force
	_knockback_time = knockback_duration


func _flash_hit() -> void:
	var sprite := $Sprite2D
	if sprite == null:
		return
	var original: Color = sprite.modulate
	sprite.modulate = Color(1.5, 0.6, 0.6)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(sprite):
		sprite.modulate = original


func death() -> void:
	if state == State.DEAD:
		return

	var death_pos := global_position
	state = State.DEAD
	died.emit(death_pos)

	var death_scene: Node2D = death_packed.instantiate()
	var effects := _get_effects_node()
	if effects:
		effects.add_child(death_scene)
		death_scene.global_position = death_pos + Vector2(0.0, -32.0)
	else:
		push_warning("Effects node not found; could not spawn enemy death VFX.")

	queue_free()


func _on_hit_box_area_entered(area: Area2D) -> void:
	area.owner.take_damage(attack_damage)
