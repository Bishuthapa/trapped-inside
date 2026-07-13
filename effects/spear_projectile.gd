extends Area2D

var _direction: Vector2 = Vector2.RIGHT
var _speed: float = 420.0
var _damage: int = 40
var _hit: bool = false

const LIFETIME: float = 4.0


func setup(direction: Vector2, speed: float, damage: int) -> void:
	_direction = direction.normalized()
	_speed = speed
	_damage = damage
	rotation = _direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	if _hit:
		return
	global_position += _direction * _speed * delta


func _on_area_entered(area: Area2D) -> void:
	if _hit:
		return

	# Only the player's hurtbox can be damaged by this — enemies are on a
	# different collision layer so they never reach this callback at all,
	# but the group check keeps the intent explicit.
	var owner_node: Node = area.owner
	if owner_node == null or not owner_node.is_in_group("player"):
		return
	if not owner_node.has_method("take_damage"):
		return

	_hit = true
	owner_node.take_damage(_damage, global_position)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _hit or body.is_in_group("player"):
		return
	queue_free()
