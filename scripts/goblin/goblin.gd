extends "res://scripts/enemies/enemy.gd"

# Goblin = ranged skirmisher. Keeps its distance, backs off when the player
# gets close, and throws a projectile after a short wind-up. The throw
# direction is locked when the wind-up starts, so a sidestep or dash dodges it.
# Stats live in Goblin.tscn.

const PROJECTILE_SCENE: PackedScene = preload("res://effects/turret_arrow.tscn")

@export var retreat_distance: float = 190.0
@export var projectile_speed: float = 460.0
@export var throw_windup: float = 0.35


func _determine_next_state() -> State:
	if _is_attacking:
		return State.ATTACK
	var d := distance_to_player()
	if d < retreat_distance:
		return State.CHASE  # move() turns CHASE into a retreat at close range
	if d <= attack_range:
		return State.ATTACK
	if d <= aggro_range:
		return State.CHASE
	if global_position.distance_to(spawn_point) > 32.0:
		return State.RETURN
	return State.IDLE


func move() -> void:
	var target_player := _get_player()
	if state == State.CHASE and target_player and distance_to_player() < retreat_distance:
		# Path to a point away from the player; the nav agent keeps it off walls.
		var away := (global_position - target_player.global_position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		nav_agent.target_position = global_position + away * 200.0
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		velocity = global_position.direction_to(next_path_position) * speed
		return
	super.move()


func _attack_hitbox_on(attack_dir: Vector2) -> void:
	await get_tree().create_timer(throw_windup).timeout
	if not is_instance_valid(self) or state == State.DEAD:
		return
	var projectile := PROJECTILE_SCENE.instantiate() as Area2D
	projectile.setup(attack_dir, projectile_speed, attack_damage)
	var parent: Node = _get_effects_node()
	if parent == null:
		parent = get_parent()
	parent.add_child(projectile)
	projectile.global_position = global_position + Vector2(0.0, -28.0) + attack_dir * 30.0
