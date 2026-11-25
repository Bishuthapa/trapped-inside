extends "res://scripts/enemies/enemy.gd"

# Lizardman reuses the full enemy AI (chase / return / attack / knockback /
# death / heart-drop) but renders through an AnimatedSprite2D + SpriteFrames
# instead of the Sprite2D + AnimationTree the Warrior/Goblin use.
#
# Role: charger. At mid range it stops, shows a red line on the floor for
# charge_windup seconds, then rushes along that line. After the charge it is
# stunned and open to free hits. Walls clamp the charge length (enemies don't
# collide with the wall layer, so the ray check keeps it inside the room).

enum Charge { NONE, WINDUP, CHARGING, STUNNED }

@export_category("Charge")
@export var charge_min_range: float = 160.0
@export var charge_max_range: float = 460.0
@export var charge_distance: float = 520.0
@export var charge_speed: float = 720.0
@export var charge_windup: float = 0.55
@export var charge_cooldown: float = 3.5
@export var charge_damage_mult: float = 1.4
@export var stun_time: float = 0.8

const WALL_MASK: int = 1
const WARNING_COLOR: Color = Color(1.0, 0.2, 0.1, 0.35)
const STUN_TINT: Color = Color(0.6, 0.7, 1.0)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _charge: Charge = Charge.NONE
var _charge_time_left: float = 0.0
var _charge_cooldown_left: float = 0.6
var _charge_dir: Vector2 = Vector2.RIGHT
var _charge_hit_landed: bool = false
var _warning_line: Line2D


func _ready() -> void:
	super._ready()
	_sprite.animation_finished.connect(_on_anim_finished)
	update_animation()


func _visual() -> Node2D:
	return _sprite


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_charge_cooldown_left = maxf(_charge_cooldown_left - delta, 0.0)
	if _charge != Charge.NONE:
		_process_charge(delta)
		return
	if _can_start_charge():
		_begin_charge()
		return
	super._physics_process(delta)


func _can_start_charge() -> bool:
	if _charge_cooldown_left > 0.0 or _is_attacking or _knockback_time > 0.0:
		return false
	var target_player := _get_player()
	if target_player == null:
		return false
	var d := distance_to_player()
	if d < charge_min_range or d > charge_max_range or d > aggro_range:
		return false
	# Need a clear line to the player.
	return _wall_distance(target_player.global_position - global_position) >= d


func _wall_distance(dir: Vector2) -> float:
	var space := get_world_2d().direct_space_state
	var to := global_position + dir.normalized() * charge_distance
	var query := PhysicsRayQueryParameters2D.create(global_position, to, WALL_MASK)
	# The player's body sits on layer 1 too; only real walls should stop the charge.
	var target_player := _get_player()
	if target_player:
		query.exclude = [target_player.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return charge_distance
	return global_position.distance_to(hit.position)


func _begin_charge() -> void:
	var target_player := _get_player()
	_charge_dir = (target_player.global_position - global_position).normalized()
	var length := maxf(_wall_distance(_charge_dir) - 40.0, 0.0)
	_charge = Charge.WINDUP
	_charge_time_left = charge_windup
	_charge_hit_landed = false
	velocity = Vector2.ZERO
	_sprite.flip_h = _charge_dir.x < 0.0
	_sprite.play("idle")
	_sprite.modulate = Color(1.5, 0.8, 0.6)

	_warning_line = Line2D.new()
	_warning_line.width = 44.0
	_warning_line.default_color = WARNING_COLOR
	_warning_line.z_index = -1
	_warning_line.points = PackedVector2Array([Vector2.ZERO, _charge_dir * length])
	_warning_line.modulate.a = 0.0
	add_child(_warning_line)
	_warning_line.create_tween().tween_property(_warning_line, "modulate:a", 1.0, charge_windup * 0.6)
	# Store the travel time now; the line length is the charge length.
	set_meta("charge_travel_time", length / charge_speed)


func _process_charge(delta: float) -> void:
	_charge_time_left -= delta
	match _charge:
		Charge.WINDUP:
			if _charge_time_left <= 0.0:
				_start_rush()
		Charge.CHARGING:
			global_position += _charge_dir * charge_speed * delta
			if _charge_time_left <= 0.0:
				_end_rush()
		Charge.STUNNED:
			if _charge_time_left <= 0.0:
				_charge = Charge.NONE
				_charge_cooldown_left = charge_cooldown
				_sprite.modulate = Color.WHITE
				update_animation()


func _start_rush() -> void:
	_charge = Charge.CHARGING
	_charge_time_left = float(get_meta("charge_travel_time", 0.5))
	if is_instance_valid(_warning_line):
		_warning_line.queue_free()
	_sprite.modulate = Color.WHITE
	_sprite.play("run")
	_sprite.speed_scale = 2.0
	var hb := get_node_or_null("HitBox") as Area2D
	if hb:
		hb.position = Vector2(30.0 * signf(_charge_dir.x if _charge_dir.x != 0.0 else 1.0), -40.0)
		hb.monitoring = true
	Sfx.play_stream(attack_sfx, global_position)


func _end_rush() -> void:
	_charge = Charge.STUNNED
	_charge_time_left = stun_time
	_knockback_time = 0.0
	_knockback_velocity = Vector2.ZERO
	_sprite.speed_scale = 1.0
	_sprite.play("idle")
	_sprite.modulate = STUN_TINT
	var hb := get_node_or_null("HitBox") as Area2D
	if hb:
		hb.set_deferred("monitoring", false)


func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.owner == null or not area.owner.has_method("take_damage"):
		return
	if _charge == Charge.CHARGING:
		if _charge_hit_landed:
			return
		_charge_hit_landed = true
		area.owner.take_damage(int(round(attack_damage * charge_damage_mult)), global_position)
		return
	area.owner.take_damage(attack_damage, global_position)


func update_animation() -> void:
	if _charge != Charge.NONE:
		return
	match state:
		State.IDLE:
			_sprite.play("idle")
		State.CHASE:
			_sprite.play("run")
		State.RETURN:
			_sprite.play("walk")
		State.ATTACK:
			_sprite.play("attack")


func _on_anim_finished() -> void:
	# hurt/attack are one-shot; when they end, fall back to the state anim.
	if state == State.DEAD:
		return
	if _sprite.animation in ["hurt", "attack"]:
		update_animation()


func _attack_hitbox_on(attack_dir: Vector2) -> void:
	var hb := get_node_or_null("HitBox") as Area2D
	if hb == null:
		return
	# Reach the blade toward the player, then open the damage window mid-swing.
	var facing := -1.0 if attack_dir.x < 0.0 else 1.0
	hb.position = Vector2(40.0 * facing, -40.0)

	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self) or state == State.DEAD:
		return
	hb.monitoring = true

	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(hb):
		hb.monitoring = false


func take_damage(damage_taken: int, source_pos: Vector2 = Vector2.INF) -> void:
	var was_alive := state != State.DEAD
	super.take_damage(damage_taken, source_pos)
	# super may have triggered death(); only play hurt if still alive.
	if was_alive and state != State.DEAD and hitpoints > 0 and _charge == Charge.NONE:
		_sprite.play("hurt")


func death() -> void:
	if state == State.DEAD:
		return
	var death_pos := global_position
	state = State.DEAD
	died.emit(death_pos)
	_register_kill()

	# Freeze combat: no more hits in or out.
	_charge = Charge.NONE
	_sprite.speed_scale = 1.0
	_sprite.modulate = Color.WHITE
	if is_instance_valid(_warning_line):
		_warning_line.queue_free()
	health_bar.visible = false
	var hb := get_node_or_null("HitBox") as Area2D
	if hb:
		hb.set_deferred("monitoring", false)
	var hurt := get_node_or_null("HurtBox") as Area2D
	if hurt:
		hurt.set_deferred("monitorable", false)

	_sprite.play("death")
	await _sprite.animation_finished
	if not is_instance_valid(self):
		return

	var effects := _get_effects_node()
	if effects:
		_maybe_drop_heart(effects, death_pos)
	_trigger_kill_hitstop()
	queue_free()
