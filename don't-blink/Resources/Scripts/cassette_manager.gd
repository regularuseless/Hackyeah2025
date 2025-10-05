extends CanvasLayer
class_name CassetteManager

@onready var root: Control               = %Root
@onready var close_btn: Button           = %CloseButton
@onready var play_btn: Button            = %PlayButton       # <- renamed
@onready var pause_btn: Button           = %PauseButton      # <- new button
@onready var loop_btn: Button            = %LoopButton
@onready var player: VideoStreamPlayer   = %VideoPlayer
@onready var video_ar: AspectRatioContainer = %VideoAR

var _open: bool = false
var _saved_paused: bool = false
var _loop: bool = false
@export var default_loop: bool = false
var _is_playing: bool = false   # our UI state flag

func _ready() -> void:
	_fix_layout_hard()
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false

	close_btn.pressed.connect(close)
	play_btn.pressed.connect(_press_play)
	pause_btn.pressed.connect(_press_pause)
	loop_btn.pressed.connect(_toggle_loop)

	player.finished.connect(_on_player_finished)

	_loop = default_loop
	_refresh_loop_label()
	_update_controls()

func open(_title: String, stream: VideoStream) -> void:
	if stream == null:
		push_warning("CassetteManager.open called with null stream"); return

	_saved_paused = get_tree().paused
	get_tree().paused = true
	root.visible = true
	_open = true

	player.stream = stream
	player.stream_position = 0.0
	player.play()
	_is_playing = true
	_update_controls()

	await get_tree().process_frame
	_apply_video_aspect_from_stream_or_texture()

func _press_play() -> void:
	if player.stream == null:
		return
	player.play()          # resumes from current stream_position
	_is_playing = true
	_update_controls()

func _press_pause() -> void:
	if player.is_playing():
		player.stop()
	_is_playing = false
	_update_controls()

func _toggle_loop() -> void:
	_loop = !_loop
	_refresh_loop_label()

func _refresh_loop_label() -> void:
	loop_btn.text = "Loop: " + ("On" if _loop else "Off")

func _on_player_finished() -> void:
	if _loop:
		player.stream_position = 0.0
		player.play()
		_is_playing = true
	else:
		_is_playing = false
	_update_controls()

func _update_controls() -> void:
	# Enable exactly one of them based on state
	play_btn.disabled = _is_playing
	pause_btn.disabled = not _is_playing

func close() -> void:
	_open = false
	player.stop()
	player.stream = null
	root.visible = false
	get_tree().paused = _saved_paused

func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		close()

func _apply_video_aspect_from_stream_or_texture() -> void:
	var w := 0
	var h := 0
	if player.stream and player.stream.has_method("get_width") and player.stream.has_method("get_height"):
		w = int(player.stream.get_width())
		h = int(player.stream.get_height())
	if (w == 0 or h == 0):
		var tex := player.get_video_texture()
		if tex:
			var sz := tex.get_size()
			w = int(sz.x)
			h = int(sz.y)
	if w > 0 and h > 0 and is_instance_valid(video_ar):
		video_ar.ratio = float(w) / float(h)
		video_ar.custom_minimum_size = Vector2(w, h)

func _fix_layout_hard() -> void:
	%Root.set_anchors_preset(Control.PRESET_FULL_RECT)
	if %Root.has_node("Dim"):
		%Dim.set_anchors_preset(Control.PRESET_FULL_RECT)

	if is_instance_valid(video_ar):
		video_ar.set_anchors_preset(Control.PRESET_FULL_RECT)
		video_ar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		video_ar.size_flags_vertical   = Control.SIZE_EXPAND_FILL
		video_ar.stretch_mode = AspectRatioContainer.STRETCH_FIT
		video_ar.custom_minimum_size = Vector2(960, 540)

	%VideoPlayer.set_anchors_preset(Control.PRESET_FULL_RECT)
	%VideoPlayer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%VideoPlayer.size_flags_vertical   = Control.SIZE_EXPAND_FILL
