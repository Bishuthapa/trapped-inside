extends Node2D

signal completed()
signal objective_changed(text: String)

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const WAVES: Array[int] = [2, 2, 1]
const WAVE_DELAY: float = 1.5

@onready var enemies_node: Node = $Enemies

var _spawn_points: Array[Vector2] = []
var _wave_index: int = 0
var _enemies_alive_in_wave: int = 0
var _completion_triggered: bool = false
var _spawning_wave: bool = false


func _ready() -> void:
	var placeholders := enemies_node.get_children()
	for enemy in placeholders:
		_spawn_points.append(enemy.global_position)
		enemy.queue_free()

	await _wait_until_enemies_cleared()
	call_deferred("_emit_initial_objective")
	await get_tree().create_timer(1.0).timeout
	_start_next_wave()


func _wait_until_enemies_cleared() -> void:
	while enemies_node.get_child_count() > 0:
		await get_tree().process_frame


func _emit_initial_objective() -> void:
	objective_changed.emit("Hold your ground — waves incoming")


func _start_next_wave() -> void:
	if _spawning_wave or _completion_triggered:
		return
	if _wave_index >= WAVES.size():
		return

	_spawning_wave = true
	var wave_number := _wave_index + 1
	var enemy_count := WAVES[_wave_index]
	_enemies_alive_in_wave = enemy_count
	objective_changed.emit("Survive wave %d/%d" % [wave_number, WAVES.size()])

	for i in enemy_count:
		var enemy := ENEMY_SCENE.instantiate() as CharacterBody2D
		enemies_node.add_child(enemy)
		enemy.global_position = _spawn_points[i % _spawn_points.size()]
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)

	_wave_index += 1
	_spawning_wave = false


func _on_enemy_died(_pos: Vector2) -> void:
	_enemies_alive_in_wave = maxi(_enemies_alive_in_wave - 1, 0)

	if _enemies_alive_in_wave > 0:
		objective_changed.emit("Wave enemies remaining: %d" % _enemies_alive_in_wave)
		return

	call_deferred("_on_wave_cleared")


func _on_wave_cleared() -> void:
	if _completion_triggered or _spawning_wave:
		return

	if _wave_index < WAVES.size():
		objective_changed.emit("Wave cleared — next wave incoming")
		await get_tree().create_timer(WAVE_DELAY).timeout
		_start_next_wave()
		return

	_trigger_completion()


func _trigger_completion() -> void:
	if _completion_triggered:
		return
	_completion_triggered = true
	objective_changed.emit("All waves cleared — you are free!")
	completed.emit()
