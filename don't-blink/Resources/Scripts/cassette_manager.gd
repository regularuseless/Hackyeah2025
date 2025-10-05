extends CanvasLayer
class_name CassetteManager

@onready var root: Control               = %Root
@onready var close_btn: Button           = %CloseButton
@onready var play_btn: Button            = %PlayButton
@onready var pause_btn: Button           = %PauseButton
@onready var loop_btn: Button            = %LoopButton
@onready var player: VideoStreamPlayer   = %VideoPlayer
@onready var video_ar: AspectRatioContainer = %VideoAR
@onready var diode: TextureRect          = %Diode

var _open: bool = false
var _saved_paused: bool = false
var _loop: bool = false
var red_diode = load("res://Resources/Assets/red.png")
var white_diode = load("res://Resources/Assets/white.png")
@export var default_loop: bool = false
var _is_playing: bool = false

# ---- Special flow: auto-loop & fin video ----
@export var video_fin_stream: VideoStream      # assign in Inspector
var _current_title: String = ""
var _special_locked_loop: bool = false         # true when title == "video loop"
var _playing_fin: bool = false                 # true while playing the fin video

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
	diode.texture = red_diode if _loop else white_diode
	_refresh_loop_label()
	_update_controls()

func open(_title: String, stream: VideoStream) -> void:
	if stream == null:
		push_warning("CassetteManager.open called with null stream"); return

	_saved_paused = get_tree().paused
	get_tree().paused = true
	root.visible = true
	_open = true

	_current_title = _title
	_playing_fin = false

	# Special case: if title is exactly "video loop" (case-insensitive)
	_special_locked_loop = _current_title.to_lower() == "video loop"
	if _special_locked_loop:
		_loop = true
		loop_btn.disabled = true           # prevent user from disabling loop
		diode.texture = red_diode
	else:
		loop_btn.disabled = false
		diode.texture = red_diode if _loop else white_diode

	player.stream = stream
	player.stream_position = 0.0
	player.play()
	_is_playing = true
	_update_controls()
	_refresh_loop_label()

	await get_tree().process_frame
	_apply_video_aspect_from_stream_or_texture()

func _press_play() -> void:
	if player.stream == null:
		return
	player.play()
	_is_playing = true
	_update_controls()

func _press_pause() -> void:
	if player.is_playing():
		player.stop()
	_is_playing = false
	_update_controls()

func _toggle_loop() -> void:
	# If we're in the special locked state, ignore presses (button is disabled anyway).
	if _special_locked_loop:
		return
	_loop = not _loop
	diode.texture = red_diode if _loop else white_diode
	_refresh_loop_label()

func _refresh_loop_label() -> void:
	loop_btn.text = "Loop: " + ("On" if _loop else "Off")

func _on_player_finished() -> void:
	# If we're playing the fin video, exit the game when it ends.
	if _playing_fin:
		get_tree().quit()
		return

	if _loop:
		player.stream_position = 0.0
		player.play()
		_is_playing = true
	else:
		_is_playing = false
	_update_controls()

func _update_controls() -> void:
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

# ---- Call this when your custom unlock condition is met ----
func unlock_loop_and_play_fin() -> void:
	# TODO: call this from your own condition when it becomes true.
	#  e.g., from anywhere:  %CassetteManager.unlock_loop_and_play_fin()
	_special_locked_loop = false
	loop_btn.disabled = false
	_loop = false
	diode.texture = white_diode
	_refresh_loop_label()

	if video_fin_stream != null:
		player.stop()
		player.stream = video_fin_stream
		player.stream_position = 0.0
		_is_playing = true
		_playing_fin = true
		player.play()
		_update_controls()
	else:
		push_warning("CassetteManager: video_fin_stream not assigned; cannot play fin video.")

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
