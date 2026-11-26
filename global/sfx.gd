extends Node

# Central sound effect player. Add a sound once to LIBRARY, then play it from
# anywhere with Sfx.play("name") or Sfx.play("name", global_position) for
# positional audio. Players are parented here, so a sound keeps playing even
# if the node that triggered it is freed on the same frame (e.g. a dying enemy).

const BUS: String = "sfx"
const PITCH_JITTER: float = 0.08  # +/- random pitch so repeated hits don't sound robotic

const LIBRARY: Dictionary = {
	"sword_swing": preload("res://assets/audio/sfx/sword_swing.mp3"),
	"sword_slice": preload("res://assets/audio/sfx/sword_slice.mp3"),
	"hit": preload("res://assets/audio/sfx/normal_enemy_hit.mp3"),
	"hit_large": preload("res://assets/audio/sfx/large_enemy_hit.mp3"),
	"turret_fire": preload("res://assets/audio/sfx/goblin_fire_attack.wav"),
	"turret_hit": preload("res://assets/audio/sfx/hit.wav"),
}


func _ready() -> void:
	# Keep sounds working in paused screens (pause menu, upgrade picker).
	process_mode = Node.PROCESS_MODE_ALWAYS


func play(sound_name: String, world_pos: Vector2 = Vector2.INF, jitter: bool = true) -> void:
	var stream: AudioStream = LIBRARY.get(sound_name)
	if stream == null:
		push_warning("Sfx: unknown sound '%s'" % sound_name)
		return
	play_stream(stream, world_pos, jitter)


func play_stream(stream: AudioStream, world_pos: Vector2 = Vector2.INF, jitter: bool = true) -> void:
	if stream == null:
		return
	var pitch := randf_range(1.0 - PITCH_JITTER, 1.0 + PITCH_JITTER) if jitter else 1.0

	if world_pos == Vector2.INF:
		var p := AudioStreamPlayer.new()
		p.stream = stream
		p.bus = BUS
		p.pitch_scale = pitch
		add_child(p)
		p.finished.connect(p.queue_free)
		p.play()
		return

	var p2d := AudioStreamPlayer2D.new()
	p2d.stream = stream
	p2d.bus = BUS
	p2d.pitch_scale = pitch
	add_child(p2d)
	p2d.global_position = world_pos
	p2d.finished.connect(p2d.queue_free)
	p2d.play()
