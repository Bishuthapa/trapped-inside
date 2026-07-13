extends Node2D

@export var aggro_range: float = 400.0
@export var shoot_cooldown: float = 3.0
@export var spear_damage: int = 40
@export var spear_speed: float = 420.0
@export var rotation_speed: float = 8.0
@export var telegraph_duration: float = 0.4
@export var max_hitpoints: int = 80

const SPEAR_SCENE: PackedScene = preload("res://effects/spear_projectile.tscn")
const FIRE_SFX: AudioStream = preload("res://assets/audio/sfx/goblin_fire_attack.wav")
const HIT_SFX: AudioStream = preload("res://assets/audio/sfx/hit.wav")

var hitpoints: int = 0
var _cooldown_left: float = 0.0
var _is_telegraphing: bool = false
var _is_dead: bool = false

@onready var _body: Node2D = $Body
@onready var _tip: Polygon2D = $Body/Blade
@onready var _base: Polygon2D = $Base
@onready var _hurt_box: Area2D = $HurtBox


func _ready() -> void:
	hitpoints = max_hitpoints
	_cooldown_left = randf_range(0.0, shoot_cooldown * 0.5)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	if _cooldown_left > 0.0:
		_cooldown_left -= delta

	var player := _get_player()
	var in_aggro := player != null and global_position.distance_to(player.global_position) <= aggro_range
	if not in_aggro:
		return

	# Keep aiming at the player the whole time it's aggro'd, not just at the
	# moment of firing, so the turn looks smooth instead of snapping.
	_face_player(player.global_position, delta)

	if _is_telegraphing or _cooldown_left > 0.0:
		return

	_start_telegraph()


func _get_player() -> CharacterBody2D:
	var node := get_tree().get_first_node_in_group("player")
	if node is CharacterBody2D and is_instance_valid(node):
		return node
	return null


func _face_player(target_pos: Vector2, delta: float) -> void:
	var target_angle := (target_pos - global_position).angle()
	_body.rotation = lerp_angle(_body.rotation, target_angle, 1.0 - exp(-rotation_speed * delta))


func _start_telegraph() -> void:
	_is_telegraphing = true

	var tween := create_tween()
	tween.tween_property(_tip, "modulate", Color(1.8, 1.4, 0.3), telegraph_duration * 0.5)
	tween.tween_property(_tip, "modulate", Color.WHITE, telegraph_duration * 0.5)

	await get_tree().create_timer(telegraph_duration).timeout
	if not is_instance_valid(self) or _is_dead:
		return

	var player := _get_player()
	if player and global_position.distance_to(player.global_position) <= aggro_range:
		_shoot()

	_is_telegraphing = false


func _shoot() -> void:
	var direction := Vector2.RIGHT.rotated(_body.rotation)

	var spear := SPEAR_SCENE.instantiate() as Area2D
	var effects := _get_effects_node()
	var parent: Node = effects if effects else get_parent()
	parent.add_child(spear)
	spear.global_position = global_position + direction * 18.0
	spear.setup(direction, spear_speed, spear_damage)
	_cooldown_left = shoot_cooldown

	_play_recoil()
	_play_sfx(FIRE_SFX)


func _play_recoil() -> void:
	var tween := create_tween()
	tween.tween_property(_body, "scale", Vector2(0.85, 1.0), 0.06)
	tween.tween_property(_body, "scale", Vector2(1.0, 1.0), 0.12)


func take_damage(damage_taken: int, _source_pos: Vector2 = Vector2.INF) -> void:
	if _is_dead:
		return
	hitpoints = clamp(hitpoints - damage_taken, 0, max_hitpoints)
	_flash_hit()
	_play_sfx(HIT_SFX)
	if hitpoints <= 0:
		_destroy()


func _flash_hit() -> void:
	var flash_color := Color(1.6, 0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(_base, "modulate", flash_color, 0.05)
	tween.parallel().tween_property(_body, "modulate", flash_color, 0.05)
	tween.tween_property(_base, "modulate", Color.WHITE, 0.1)
	tween.parallel().tween_property(_body, "modulate", Color.WHITE, 0.1)


func _destroy() -> void:
	_is_dead = true
	_hurt_box.set_deferred("monitorable", false)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.finished.connect(queue_free)


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var sfx_player := AudioStreamPlayer2D.new()
	sfx_player.stream = stream
	sfx_player.bus = "sfx"
	get_tree().current_scene.add_child(sfx_player)
	sfx_player.global_position = global_position
	sfx_player.finished.connect(sfx_player.queue_free)
	sfx_player.play()


func _get_effects_node() -> Node2D:
	var node: Node = self
	while node:
		var effects := node.get_node_or_null("Effects") as Node2D
		if effects:
			return effects
		node = node.get_parent()
	return null
