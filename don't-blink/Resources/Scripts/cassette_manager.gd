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

# ---- Settings.json watcher (Documents/forget me not/settings.json) ----
@export var monitor_settings: bool = true
@export var settings_rel_path: String = "forget me not/settings.json"
@export var settings_poll_interval_s: float = 0.5
var _settings_timer: Timer
var _settings_file_path: String = ""
var _settings_last_loop: bool = true

func _ready() -> void:
	_fix_layout_hard()
	player.process_mode = Node.PROCESS_MODE_ALWAYS

	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false

	close_btn.pressed.connect(close)
	play_btn.pressed.connect(_press_play)
	pause_btn.pressed.connect(_press_pause)
	loop_btn.pressed.connect(_toggle_loop)

	player.finished.connect(_on_player_finished)

	# prepare the file watcher timer (runs even while paused)
	_settings_timer = Timer.new()
	_settings_timer.one_shot = false
	_settings_timer.wait_time = settings_poll_interval_s
	_settings_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	add_child(_settings_timer)
	_settings_timer.timeout.connect(_check_settings_file)

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

	# Special case: auto-loop & lock when title is "video loop"
	print (_current_title)
	_special_locked_loop = _current_title.to_lower() == "video_loop"
	if _special_locked_loop:
		_loop = true
		loop_btn.disabled = true
		diode.texture = red_diode
	else:
		loop_btn.disabled = false
		diode.texture = red_diode if _loop else white_diode

	# start/stop watcher
	_prepare_settings_path()
	_settings_timer.stop()
	if monitor_settings and _special_locked_loop and _settings_file_path != "":
		_settings_last_loop = true  # initial file state
		_settings_timer.wait_time = settings_poll_interval_s
		_settings_timer.start()
		_check_settings_file()  # immediate check

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
	# ignore when locked by the special title
	if _special_locked_loop:
		return
	_loop = not _loop
	diode.texture = red_diode if _loop else white_diode
	_refresh_loop_label()

func _refresh_loop_label() -> void:
	loop_btn.text = "Loop: " + ("On" if _loop else "Off")

func _on_player_finished() -> void:
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
	_settings_timer.stop()

func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		close()

# ---- Call this when the watcher detects loop=false (or from your own code) ----
func unlock_loop_and_play_fin() -> void:
	# Unlock UI & turn loop OFF
	_special_locked_loop = false
	loop_btn.disabled = false
	_loop = false
	diode.texture = white_diode
	_refresh_loop_label()

	# Stop watching the file; we’re acting on it now
	_settings_timer.stop()

	if video_fin_stream != null:
		# Stop current video and force a clean stream swap
		player.stop()
		player.stream = null
		await get_tree().process_frame  # let the node clear

		player.stream = video_fin_stream
		player.stream_position = 0.0

		# Mark state before starting, so finished→quit works
		_playing_fin = true
		_is_playing = true
		_update_controls()

		# Start playback *after* the stream assignment has taken effect
		player.call_deferred("play")
	else:
		push_warning("CassetteManager: video_fin_stream not assigned; cannot play fin video.")

# ---- Settings.json watcher helpers ----
func _prepare_settings_path() -> void:
	var docs: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if docs == "":
		# Fallbacks if needed:
		var env_userprofile: String = OS.get_environment("USERPROFILE")
		if env_userprofile != "":
			docs = env_userprofile.path_join("Documents")
	_settings_file_path = docs.path_join(settings_rel_path) if docs != "" else ""

func _check_settings_file() -> void:
	if _settings_file_path == "":
		return
	# Only act when still locked by the special title
	if not _special_locked_loop:
		_settings_timer.stop()
		return

	var fa := FileAccess.open(_settings_file_path, FileAccess.READ)
	if fa == null:
		return  # file missing or busy; try next tick
	var text: String = fa.get_as_text()
	fa.close()

	if text == "":
		return
	var data : Variant =  JSON.parse_string(text)
	if typeof(data) == TYPE_DICTIONARY and data.has("loop"):
		var val = data["loop"]
		var loop_now: bool = false
		match typeof(val):
			TYPE_BOOL:
				loop_now = val
			TYPE_INT:
				loop_now = int(val) != 0
			TYPE_STRING:
				loop_now = String(val).to_lower() == "false"
			_:
				loop_now = false

		if loop_now != _settings_last_loop:
			_settings_last_loop = loop_now
			if not loop_now:
				# Detected change to false -> unlock & play fin
				unlock_loop_and_play_fin()

# ---------- Aspect / Layout helpers ----------
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
