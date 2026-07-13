extends Node


class_name PlayerDataService

signal lives_changed(lives: int)
signal hp_changed(hitpoints: int, hitpoint_max: int)
signal game_over()
signal kills_changed(total: int)

const MAX_LIVES: int = 3
const MAX_HP: int = 200

var lives: int = MAX_LIVES
var hitpoints: int = MAX_HP

# Run-wide stats (reset each new game, persist across level transitions).
var enemies_killed: int = 0
var _run_start_msec: int = 0
var _run_ended_msec: int = 0


func reset_for_new_game() -> void:
	lives = MAX_LIVES
	hitpoints = MAX_HP
	enemies_killed = 0
	_run_start_msec = Time.get_ticks_msec()
	_run_ended_msec = 0
	lives_changed.emit(lives)
	hp_changed.emit(hitpoints, MAX_HP)
	kills_changed.emit(enemies_killed)


func register_kill() -> void:
	enemies_killed += 1
	kills_changed.emit(enemies_killed)


func mark_run_ended() -> void:
	# Freeze the survival timer at win/lose so the end screen shows the real
	# run length instead of ticking while the results panel is open.
	if _run_ended_msec == 0:
		_run_ended_msec = Time.get_ticks_msec()


func get_run_time_seconds() -> float:
	var end_msec: int = _run_ended_msec if _run_ended_msec > 0 else Time.get_ticks_msec()
	return maxf(0.0, float(end_msec - _run_start_msec) / 1000.0)


func format_run_time() -> String:
	var total := int(get_run_time_seconds())
	@warning_ignore("integer_division")
	var minutes := total / 60
	var seconds := total % 60
	return "%d:%02d" % [minutes, seconds]


func apply_room_transition() -> void:
	hitpoints = MAX_HP
	hp_changed.emit(hitpoints, MAX_HP)


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	hitpoints = maxi(hitpoints - amount, 0)
	hp_changed.emit(hitpoints, MAX_HP)


func heal(amount: int) -> void:
	if amount <= 0 or hitpoints <= 0:
		return
	hitpoints = mini(hitpoints + amount, MAX_HP)
	hp_changed.emit(hitpoints, MAX_HP)


func lose_life() -> bool:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		hitpoints = 0
		hp_changed.emit(hitpoints, MAX_HP)
		game_over.emit()
		return false
	hitpoints = MAX_HP
	hp_changed.emit(hitpoints, MAX_HP)
	return true
