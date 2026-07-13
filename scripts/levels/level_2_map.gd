extends Node2D

signal objective_changed(text: String)

const KEY_SCENE: PackedScene = preload("res://effects/key/key.tscn")
const PILLAR_TURRET_SCENE: PackedScene = preload("res://scenes/hazards/pillar_turret.tscn")

var has_key: bool = false
var key_spawned: bool = false
var key_node: Area2D
var last_enemy_position: Vector2
var _enemies_remaining: int = 0

@onready var enemies_node: Node = $Enemies
@onready var door: Area2D = $Door
@onready var pillers_layer: TileMapLayer = $pillers


func _ready() -> void:
	_spawn_pillar_turrets()
	_enemies_remaining = enemies_node.get_child_count()

	var boss := enemies_node.get_child(0) as CharacterBody2D
	if boss and boss.has_method("configure_as_boss"):
		boss.configure_as_boss()

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
		game_scene.call_deferred("load_level", "res://scenes/levels/level_3_map.tscn")


func _spawn_pillar_turrets() -> void:
	if pillers_layer == null:
		return

	var hazards := get_node_or_null("Hazards") as Node2D
	if hazards == null:
		hazards = Node2D.new()
		hazards.name = "Hazards"
		add_child(hazards)

	for center in _get_pillar_centers(pillers_layer):
		var turret := PILLAR_TURRET_SCENE.instantiate() as Node2D
		hazards.add_child(turret)
		turret.global_position = center


func _get_pillar_centers(layer: TileMapLayer) -> Array[Vector2]:
	var used_cells := layer.get_used_cells()
	if used_cells.is_empty():
		return []

	var tile_size := Vector2(layer.tile_set.tile_size)
	var cell_lookup: Dictionary = {}
	for cell in used_cells:
		cell_lookup[cell] = true

	var visited: Dictionary = {}
	var centers: Array[Vector2] = []

	for cell in used_cells:
		if visited.has(cell):
			continue

		var group: Array[Vector2i] = []
		var stack: Array[Vector2i] = [cell]
		while not stack.is_empty():
			var current: Vector2i = stack.pop_back()
			if visited.has(current):
				continue
			visited[current] = true
			group.append(current)
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var neighbor := current + Vector2i(dx, dy)
					if cell_lookup.has(neighbor) and not visited.has(neighbor):
						stack.append(neighbor)

		var center_sum := Vector2.ZERO
		for grouped_cell in group:
			center_sum += layer.to_global(layer.map_to_local(grouped_cell) + tile_size * 0.5)
		centers.append(center_sum / float(group.size()))

	return centers
