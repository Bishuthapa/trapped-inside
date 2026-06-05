extends CanvasLayer

const FILL_DURATION: float = 3.0

@onready var _progress_bar: TextureProgressBar = %ProgressBar
@onready var _subtitle: Label = %Subtitle


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_progress_bar.value = 0.0

	var tween := create_tween()
	tween.tween_property(_progress_bar, "value", 100.0, FILL_DURATION)


func set_message(subtitle: String) -> void:
	if _subtitle:
		_subtitle.text = subtitle
