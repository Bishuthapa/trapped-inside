extends Area2D

@export var heal_amount: int = 50

var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Spawner positions us right after add_child — wait a frame so the bob
	# tween anchors to the real drop position, not the pre-placement origin.
	await get_tree().process_frame
	if _collected or not is_instance_valid(self):
		return
	var bob := create_tween().set_loops()
	bob.tween_property(self, "position:y", position.y - 6.0, 0.5).set_trans(Tween.TRANS_SINE)
	bob.tween_property(self, "position:y", position.y, 0.5).set_trans(Tween.TRANS_SINE)
	# Despawn after a while so uncollected drops don't pile up.
	await get_tree().create_timer(12.0).timeout
	if not _collected and is_instance_valid(self):
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 0.0, 0.6)
		fade.finished.connect(queue_free)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	var player_data: Node = get_node_or_null("/root/PlayerData")
	if player_data:
		player_data.heal(heal_amount)
	# Quick pop feedback, then free.
	var pop := create_tween()
	pop.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08)
	pop.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	pop.finished.connect(queue_free)
