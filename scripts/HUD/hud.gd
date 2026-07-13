extends Control

const LOW_HP_RATIO: float = 0.3

@onready var _hearts: Array[TextureRect] = [%Heart1, %Heart2, %Heart3]
@onready var _player_data: PlayerDataService = get_node("/root/PlayerData")

var _vignette: ColorRect
var _vignette_tween: Tween


func _ready() -> void:
	_build_low_hp_vignette()
	_player_data.lives_changed.connect(update_lives)
	_player_data.hp_changed.connect(_on_player_data_hp_changed)
	_player_data.kills_changed.connect(update_kills)
	update_lives(_player_data.lives)
	_on_player_data_hp_changed(_player_data.hitpoints, _player_data.MAX_HP)
	update_kills(_player_data.enemies_killed)
	update_objective("Explore the area")
	%AttackCooldownBar.value = 100.0
	%DashCooldownBar.value = 100.0


func update_kills(total: int) -> void:
	if has_node("%KillCounter"):
		%KillCounter.text = "Enemies slain: %d" % total


func _build_low_hp_vignette() -> void:
	_vignette = ColorRect.new()
	_vignette.color = Color(0.7, 0.0, 0.0, 0.0)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_vignette)
	move_child(_vignette, 0)


func _set_low_hp_vignette(active: bool) -> void:
	if active:
		if _vignette_tween and _vignette_tween.is_valid():
			return
		_vignette_tween = create_tween().set_loops()
		_vignette_tween.tween_property(_vignette, "color:a", 0.22, 0.55).set_trans(Tween.TRANS_SINE)
		_vignette_tween.tween_property(_vignette, "color:a", 0.05, 0.55).set_trans(Tween.TRANS_SINE)
	else:
		if _vignette_tween and _vignette_tween.is_valid():
			_vignette_tween.kill()
			_vignette_tween = null
		_vignette.color.a = 0.0


func update_hp_bar(new_value: int) -> void:
	%HitpointsBar.value = new_value


func update_lives(lives: int) -> void:
	for i in _hearts.size():
		_hearts[i].visible = i < lives


func update_objective(text: String) -> void:
	%ObjectiveLabel.text = text


func update_attack_cooldown(ready_ratio: float) -> void:
	%AttackCooldownBar.value = clampf(ready_ratio, 0.0, 1.0) * 100.0


func update_dash_cooldown(ready_ratio: float) -> void:
	%DashCooldownBar.value = clampf(ready_ratio, 0.0, 1.0) * 100.0


func _on_player_data_hp_changed(hitpoints: int, hitpoint_max: int) -> void:
	if hitpoint_max <= 0:
		return
	@warning_ignore("integer_division")
	update_hp_bar(hitpoints * 100 / hitpoint_max)
	_set_low_hp_vignette(hitpoints > 0 and float(hitpoints) / hitpoint_max <= LOW_HP_RATIO)
