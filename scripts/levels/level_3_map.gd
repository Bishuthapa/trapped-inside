extends Node2D

signal completed()
signal objective_changed(text: String)

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const GOBLIN_SCENE: PackedScene = preload("res://scenes/enemies/Goblin.tscn")

# Two regular waves, then one guaranteed-visible mini-boss instead of a
# crowded final wave — large maps + many simultaneous nav agents let enemies
# wander into distant/unreachable corners the player can't find (the "wave
# enemies remaining: 2" soft-lock). One boss spawned beside the player
# removes that failure mode entirely and reads as a proper final encounter.
const WAVES: Array[int] = [2, 3]
const GOBLIN_WAVES: Array[int] = [0, 1]
const BOSS_EXTRA_HP: int = 500
const BOSS_SCALE: float = 1.6
const BOSS_EXTRA_DAMAGE: int = 45
const WAVE_DELAY: float = 1.5

@onready var enemies_node: Node = $Enemies

var _spawn_points: Array[Vector2] = []
var _wave_index: int = 0
var _enemies_alive_in_wave: int = 0
var _completion_triggered: bool = false
var _spawning_wave: bool = false
var _boss_active: bool = false


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
	if _wave_index > WAVES.size():
		return

	_spawning_wave = true

	if _wave_index == WAVES.size():
		_spawn_boss_wave()
		_wave_index += 1
		_spawning_wave = false
		return

	var wave_number := _wave_index + 1
	var enemy_count := WAVES[_wave_index]
	var goblin_count := GOBLIN_WAVES[_wave_index]
	_enemies_alive_in_wave = enemy_count + goblin_count
	objective_changed.emit("Survive wave %d/%d" % [wave_number, WAVES.size() + 1])

	var spawn_index := 0
	for i in enemy_count:
		_spawn_enemy(ENEMY_SCENE, spawn_index)
		spawn_index += 1
	for i in goblin_count:
		_spawn_enemy(GOBLIN_SCENE, spawn_index)
		spawn_index += 1

	_wave_index += 1
	_spawning_wave = false


func _spawn_boss_wave() -> void:
	_enemies_alive_in_wave = 1
	_boss_active = true
	objective_changed.emit("Final wave — a champion approaches!")

	var boss := ENEMY_SCENE.instantiate() as CharacterBody2D
	enemies_node.add_child(boss)
	boss.global_position = _spawn_position_near_player()
	boss.spawn_point = boss.global_position
	boss.aggro_range = 100000.0
	if boss.has_method("configure_as_boss"):
		boss.configure_as_boss(BOSS_EXTRA_HP, BOSS_SCALE, BOSS_EXTRA_DAMAGE)
	if boss.has_signal("died"):
		boss.died.connect(_on_enemy_died)


func _spawn_position_near_player() -> Vector2:
	# Spawn just off-screen-adjacent to the player so the boss is always
	# visible on arrival instead of relying on a distant map placeholder.
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return _spawn_points[0] if not _spawn_points.is_empty() else global_position
	return player.global_position + Vector2(280.0, 0.0)


func _spawn_enemy(enemy_scene: PackedScene, spawn_index: int) -> void:
	var enemy := enemy_scene.instantiate() as CharacterBody2D
	enemies_node.add_child(enemy)
	enemy.global_position = _spawn_points[spawn_index % _spawn_points.size()]
	# The enemy's @onready spawn_point captured its pre-placement position
	# (world origin) — fix it so RETURN state goes here, not off-map.
	enemy.spawn_point = enemy.global_position
	# Survival arena: waves should always hunt the player, never lose aggro.
	enemy.aggro_range = 100000.0
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died(_pos: Vector2) -> void:
	_enemies_alive_in_wave = maxi(_enemies_alive_in_wave - 1, 0)

	if _enemies_alive_in_wave > 0:
		objective_changed.emit("Wave enemies remaining: %d" % _enemies_alive_in_wave)
		return

	call_deferred("_on_wave_cleared")


func _on_wave_cleared() -> void:
	if _completion_triggered or _spawning_wave:
		return

	if _boss_active:
		_boss_active = false
		_trigger_completion()
		return

	if _wave_index <= WAVES.size():
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
