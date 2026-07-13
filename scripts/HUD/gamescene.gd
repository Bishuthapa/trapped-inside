extends Node2D

const GAME_OVER_SCENE: PackedScene = preload("res://UI/game_over.tscn")
const GAME_COMPLETE_SCENE: PackedScene = preload("res://UI/game_complete.tscn")
const LOADING_SCENE: PackedScene = preload("res://UI/LoadingScene.tscn")
const TRANSITION_DURATION: float = 3.0

const LOADING_MESSAGES: Dictionary = {
	"level_2_map.tscn": "Level 2: The Deep Halls — Deeper inside. The air gets colder.",
	"level_3_map.tscn": "Level 3: Final Chamber — One last room. Find a way out.",
}
const FLOOR_TINT: Color = Color(1.08, 1.05, 0.98, 1.0)

@onready var HUD: Control = $UI/HUD
@onready var _pause_menu: CanvasLayer = $UI/pause
@onready var _game_music: AudioStreamPlayer = $UI/GameMusic
@onready var _player_data: PlayerDataService = get_node("/root/PlayerData")
var current_level: Node2D
var _is_loading: bool = false
var _game_over_ui: CanvasLayer
var _game_complete_ui: CanvasLayer
var _loading_ui: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_start_game_music()
	_player_data.game_over.connect(_on_game_over)
	current_level = _find_level_node()
	_apply_floor_tint(current_level)
	_connect_player_to_hud()
	_connect_level_events()
	_wire_pause_menu()


func _wire_pause_menu() -> void:
	if _pause_menu == null:
		return
	if _pause_menu.has_signal("quit_to_menu") and not _pause_menu.quit_to_menu.is_connected(_on_pause_quit_to_menu):
		_pause_menu.quit_to_menu.connect(_on_pause_quit_to_menu)
	if _pause_menu.has_signal("restart_requested") and not _pause_menu.restart_requested.is_connected(_on_pause_restart_requested):
		_pause_menu.restart_requested.connect(_on_pause_restart_requested)


func _on_pause_restart_requested() -> void:
	# Prefer letting scenehandler own the transition (proper main-menu flow),
	# but fall back to a plain scene reload when this level is run standalone
	# (e.g. F6 "play current scene" in the editor) and no scenehandler exists.
	var scene_handler: Node = get_tree().root.get_node_or_null("scenehandler")
	if scene_handler and scene_handler.has_method("restart_game"):
		scene_handler.restart_game()
	else:
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_pause_quit_to_menu() -> void:
	var scene_handler: Node = get_tree().root.get_node_or_null("scenehandler")
	if scene_handler and scene_handler.has_method("go_to_main_menu"):
		scene_handler.go_to_main_menu()
	else:
		get_tree().paused = false
		get_tree().quit()


func _start_game_music() -> void:
	var stream := preload("res://sound/flutemusic.mp3").duplicate() as AudioStreamMP3
	stream.loop = true
	_game_music.stream = stream
	if not _game_music.playing:
		_game_music.play()


func _unhandled_input(event: InputEvent) -> void:
	if _is_loading:
		return
	if _game_over_ui and is_instance_valid(_game_over_ui):
		return
	if _game_complete_ui and is_instance_valid(_game_complete_ui):
		return
	if not (event.is_action_pressed("escape") or event.is_action_pressed("ui_cancel")):
		return
	if _pause_menu.has_method("toggle_pause"):
		_pause_menu.toggle_pause()
		get_viewport().set_input_as_handled()


func load_level(level_scene_path: String) -> void:
	_player_data.apply_room_transition()
	_transition_to_level(level_scene_path)


func _transition_to_level(level_scene_path: String) -> void:
	if _is_loading:
		return
	_is_loading = true

	get_tree().paused = false
	_pause_menu.visible = false

	_loading_ui = LOADING_SCENE.instantiate() as CanvasLayer
	if _loading_ui.has_method("set_message"):
		_loading_ui.set_message(_get_loading_message(level_scene_path))
	$UI.add_child(_loading_ui)

	ResourceLoader.load_threaded_request(level_scene_path)

	await get_tree().create_timer(TRANSITION_DURATION).timeout

	if _loading_ui and is_instance_valid(_loading_ui):
		_loading_ui.queue_free()
		_loading_ui = null

	await _swap_level(level_scene_path)
	_is_loading = false


func _swap_level(level_scene_path: String) -> void:
	if current_level and is_instance_valid(current_level):
		var old_level := current_level
		current_level = null
		old_level.queue_free()
		await old_level.tree_exited

	var level_scene := await _fetch_level_scene(level_scene_path)
	if level_scene == null:
		push_error("Failed to load level scene: %s" % level_scene_path)
		return

	current_level = level_scene.instantiate()
	add_child(current_level)
	move_child(current_level, 0)
	_apply_floor_tint(current_level)

	await get_tree().process_frame
	_connect_player_to_hud()
	_connect_level_events()


func _get_loading_message(level_scene_path: String) -> String:
	for key in LOADING_MESSAGES:
		if level_scene_path.ends_with(key):
			return LOADING_MESSAGES[key]
	return "Entering next area"


func _fetch_level_scene(level_scene_path: String) -> PackedScene:
	var status := ResourceLoader.load_threaded_get_status(level_scene_path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(level_scene_path)

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		return ResourceLoader.load_threaded_get(level_scene_path) as PackedScene

	push_error("Threaded load failed for: %s" % level_scene_path)
	return load(level_scene_path) as PackedScene


func _find_level_node() -> Node2D:
	for child in get_children():
		if child == HUD.get_parent():
			continue
		if child is Node2D:
			return child
	return null


func _apply_floor_tint(_level: Node) -> void:
	pass


func _connect_player_to_hud() -> void:
	var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("sync_from_player_data"):
		player.sync_from_player_data()
	if not player.update_hp_bar.is_connected(HUD.update_hp_bar):
		player.update_hp_bar.connect(HUD.update_hp_bar)
	if player.has_signal("attack_cooldown_changed") and not player.attack_cooldown_changed.is_connected(HUD.update_attack_cooldown):
		player.attack_cooldown_changed.connect(HUD.update_attack_cooldown)
	if player.has_signal("dash_cooldown_changed") and not player.dash_cooldown_changed.is_connected(HUD.update_dash_cooldown):
		player.dash_cooldown_changed.connect(HUD.update_dash_cooldown)


func _connect_level_events() -> void:
	if current_level == null or not is_instance_valid(current_level):
		return
	if current_level.has_signal("objective_changed"):
		var objective_cb := Callable(HUD, "update_objective")
		if not current_level.is_connected("objective_changed", objective_cb):
			current_level.connect("objective_changed", HUD.update_objective)
	if current_level.has_signal("completed"):
		var completed_cb := Callable(self, "_on_level_completed")
		if not current_level.is_connected("completed", completed_cb):
			current_level.connect("completed", completed_cb)


func _on_game_over() -> void:
	if _game_over_ui and is_instance_valid(_game_over_ui):
		return

	get_tree().paused = true
	_game_over_ui = GAME_OVER_SCENE.instantiate()
	$UI.add_child(_game_over_ui)
	_game_over_ui.return_to_menu_pressed.connect(_on_game_over_return_to_menu)


func _on_game_over_return_to_menu() -> void:
	get_tree().paused = false
	if _game_over_ui and is_instance_valid(_game_over_ui):
		_game_over_ui.queue_free()
		_game_over_ui = null

	var scene_handler: Node = get_tree().root.get_node_or_null("scenehandler")
	if scene_handler and scene_handler.has_method("go_to_main_menu"):
		scene_handler.go_to_main_menu()


func _on_level_completed() -> void:
	if _game_complete_ui and is_instance_valid(_game_complete_ui):
		return
	get_tree().paused = true
	_game_complete_ui = GAME_COMPLETE_SCENE.instantiate()
	$UI.add_child(_game_complete_ui)
	_game_complete_ui.return_to_menu_pressed.connect(_on_game_complete_return_to_menu)
	_game_complete_ui.restart_pressed.connect(_on_game_complete_restart)


func _on_game_complete_return_to_menu() -> void:
	get_tree().paused = false
	if _game_complete_ui and is_instance_valid(_game_complete_ui):
		_game_complete_ui.queue_free()
		_game_complete_ui = null
	var scene_handler: Node = get_tree().root.get_node_or_null("scenehandler")
	if scene_handler and scene_handler.has_method("go_to_main_menu"):
		scene_handler.go_to_main_menu()


func _on_game_complete_restart() -> void:
	get_tree().paused = false
	if _game_complete_ui and is_instance_valid(_game_complete_ui):
		_game_complete_ui.queue_free()
		_game_complete_ui = null
	var scene_handler: Node = get_tree().root.get_node_or_null("scenehandler")
	if scene_handler and scene_handler.has_method("restart_game"):
		scene_handler.restart_game()
