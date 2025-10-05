extends CanvasLayer
class_name CassetteManager

@onready var root: Control          = %Root
@onready var title_label: Label     = %Title
@onready var close_btn: Button      = %CloseButton
@onready var play_btn: Button       = %PlayPauseButton
@onready var player: VideoStreamPlayer    = %VideoPlayer

var _open: bool = false
var _saved_paused: bool = false

func _ready() -> void:
	# If it's a Control (it is, in 2D UI)
	player.set_anchors_preset(Control.PRESET_FULL_RECT)
	player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	# Helps if the parent gives zero size at start:
	player.custom_minimum_size = Vector2(960, 540)  # pick any sane preview size
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	close_btn.pressed.connect(close)
	play_btn.pressed.connect(_toggle_play)
	player.finished.connect(func(): play_btn.text = "Play")

func open(title: String, stream: VideoStream) -> void:
	if stream == null:
		push_warning("CassetteManager.open called with null stream"); return
	_saved_paused = get_tree().paused
	get_tree().paused = true
	root.visible = true
	_open = true
	title_label.text = title
	player.stream = stream
	player.play()
	play_btn.text = "Pause"
	player.set_expand(true)

func close() -> void:
	_open = false
	player.stop()
	player.stream = null
	root.visible = false
	get_tree().paused = _saved_paused

func _toggle_play() -> void:
	if player.is_playing():
		player.stop()
		play_btn.text = "Play"
	else:
		player.play()
		play_btn.text = "Pause"

func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		close()
