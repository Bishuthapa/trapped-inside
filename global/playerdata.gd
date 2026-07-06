extends Node


class_name PlayerDataService

signal lives_changed(lives: int)
signal hp_changed(hitpoints: int, hitpoint_max: int)
signal game_over()

const MAX_LIVES: int = 3
const MAX_HP: int = 200

var lives: int = MAX_LIVES
var hitpoints: int = MAX_HP


func reset_for_new_game() -> void:
	lives = MAX_LIVES
	hitpoints = MAX_HP
	lives_changed.emit(lives)
	hp_changed.emit(hitpoints, MAX_HP)


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
