extends Node2D

# When true the final animation frame (the skull) stays on screen instead of
# the effect freeing itself — used for the player's game-over death.
@export var persist_last_frame: bool = false


func _ready() -> void:
	$AnimationPlayer.play("death")


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	if persist_last_frame:
		return
	queue_free()
