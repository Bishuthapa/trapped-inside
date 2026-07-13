extends Node2D

@export var shoot_range: float = 400.0
@export var shoot_cooldown: float = 2.0
@export var arrow_damage: int = 45
@export var arrow_speed: float = 480.0
@export var telegraph_duration: float = 0.35

const TURRET_ARROW_SCENE: PackedScene = preload("res://effects/turret_arrow.tscn")

var _cooldown_left: float = 0.0
var _is_telegraphing: bool = false

@onready var _line_of_sight: RayCast2D = $LineOfSight
@onready var _indicator: Sprite2D = $Indicator


func _ready() -> void:
	_cooldown_left = randf_range(0.0, shoot_cooldown * 0.5)


func _physics_process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
	if _is_telegraphing:
		return

	var player := _get_player()
	if player == null:
		return
	if global_position.distance_to(player.global_position) > shoot_range:
		return
	if not _has_line_of_sight(player):
		return
	if _cooldown_left > 0.0:
		return

	_start_telegraph(player.global_position)


func _get_player() -> CharacterBody2D:
	var node := get_tree().get_first_node_in_group("player")
	if node is CharacterBody2D and is_instance_valid(node):
		return node
	return null


func _has_line_of_sight(player: Node2D) -> bool:
	_line_of_sight.target_position = to_local(player.global_position)
	_line_of_sight.force_raycast_update()
	return not _line_of_sight.is_colliding()


func _start_telegraph(target_pos: Vector2) -> void:
	_is_telegraphing = true

	if _indicator:
		var tween := create_tween()
		tween.tween_property(_indicator, "modulate", Color(1.6, 0.35, 0.35), telegraph_duration * 0.5)
		tween.tween_property(_indicator, "modulate", Color.WHITE, telegraph_duration * 0.5)

	await get_tree().create_timer(telegraph_duration).timeout
	if not is_instance_valid(self):
		return

	var player := _get_player()
	if player and global_position.distance_to(player.global_position) <= shoot_range and _has_line_of_sight(player):
		_shoot_at(player.global_position)

	_is_telegraphing = false


func _shoot_at(target_pos: Vector2) -> void:
	var direction := (target_pos - global_position).normalized()
	if direction == Vector2.ZERO:
		return

	var arrow := TURRET_ARROW_SCENE.instantiate() as Area2D
	var effects := _get_effects_node()
	var parent: Node = effects if effects else get_parent()
	parent.add_child(arrow)
	arrow.global_position = global_position + direction * 14.0
	arrow.setup(direction, arrow_speed, arrow_damage)
	_cooldown_left = shoot_cooldown


func _get_effects_node() -> Node2D:
	var node: Node = self
	while node:
		var effects := node.get_node_or_null("Effects") as Node2D
		if effects:
			return effects
		node = node.get_parent()
	return null
