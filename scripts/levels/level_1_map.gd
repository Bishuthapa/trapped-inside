extends Node2D

signal objective_changed(text: String)

const KEY_SCENE: PackedScene = preload("res://effects/key/key.tscn")

var has_key: bool = false
var key_spawned: bool = false
var key_node: Area2D
var last_enemy_position: Vector2
var _enemies_remaining: int = 0

@onready var enemies_node: Node = $Enemies
@onready var door: Area2D = $Door


func _ready() -> void:
	_enemies_remaining = enemies_node.get_child_count()
	for enemy in enemies_node.get_children():
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)
	call_deferred("_emit_initial_objective")


func _emit_initial_objective() -> void:
	objective_changed.emit("Defeat all enemies (%d remaining)" % _enemies_remaining)


func _on_enemy_died(pos: Vector2) -> void:
	last_enemy_position = pos
	_enemies_remaining = maxi(_enemies_remaining - 1, 0)

	if _enemies_remaining > 0:
		objective_changed.emit("Defeat all enemies (%d remaining)" % _enemies_remaining)
		return

	call_deferred("_spawn_key")


func _spawn_key() -> void:
	if key_spawned:
		return
	key_spawned = true
	objective_changed.emit("Collect the key")

	var key_instance := KEY_SCENE.instantiate() as Area2D
	key_instance.name = "Key"
	key_instance.global_position = last_enemy_position
	key_instance.key_collected.connect(_on_key_collected)
	key_node = key_instance
	add_child(key_instance)


func _on_key_collected(_key: Area2D, _collector: Node2D) -> void:
	if has_key:
		return
	has_key = true
	objective_changed.emit("Reach the door with the key")


func _on_door_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not has_key:
		return

	var game_scene := get_parent()
	if game_scene and game_scene.has_method("load_level"):
		game_scene.call_deferred("load_level", "res://scenes/levels/level_2_map.tscn")
