extends Control

@onready var v_box_container: VBoxContainer = $TextureRect/CenterContainer/VBoxContainer
@onready var setting: Panel = $Setting
@onready var how_to_play: Panel = $HowToPlay

signal new_game_pressed(origin: String)
signal settings_pressed(origin: String)
signal exit_pressed(origin: String)

func _ready():
	v_box_container.visible = true
	setting.visible = false
	how_to_play.visible = false

func _on_new_game_pressed() -> void:
	$"TextureRect/CenterContainer/VBoxContainer/new game/click".play()
	new_game_pressed.emit("main_menu")

func _on_settings_pressed() -> void:
	$TextureRect/CenterContainer/VBoxContainer/settings/click.play()
	settings_pressed.emit("main_menu")
	v_box_container.visible = false
	setting.visible = true

func _on_exit_pressed() -> void:
	$TextureRect/CenterContainer/VBoxContainer/exit/click.play()
	exit_pressed.emit("main_menu")

func _on_new_game_mouse_entered() -> void:
	$"TextureRect/CenterContainer/VBoxContainer/new game/hover".play()

func _on_settings_mouse_entered() -> void:
	$TextureRect/CenterContainer/VBoxContainer/settings/hover2.play()

func _on_exit_mouse_entered() -> void:
	$TextureRect/CenterContainer/VBoxContainer/exit/hover3.play()

func _on_ready() -> void:
	$AudioStreamPlayer2D.play()

func _on_animation_player_ready() -> void:
	$AnimationPlayer.play("fadein")

func _on_backoption_2_pressed() -> void:
	_show_main_panel()

func _show_main_panel() -> void:
	v_box_container.visible = true
	setting.visible = false
	how_to_play.visible = false


func _on_how_to_play_pressed() -> void:
	v_box_container.visible = false
	how_to_play.visible = true


func _on_how_to_play_back_pressed() -> void:
	_show_main_panel()
