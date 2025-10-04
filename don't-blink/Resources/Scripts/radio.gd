extends Node2D

# --- zakres strojenia ---
@export var min_freq: float = 88.0
@export var max_freq: float = 108.0

# --- cele i tolerancje ---
@export var target_freq_a: float = 100.1
@export var target_freq_b: float = 101.1
@export var tolerance_a: float = 0.25
@export var tolerance_b: float = 0.25

# --- kąt gałek ---
@export var angle_min: float = -120.0
@export var angle_max: float = 120.0

# --- debugowy podgląd częstotliwości ---
@export var show_debug_text: bool = true
@export var debug_text_size: int = 18
@export var debug_offset_a: Vector2 = Vector2(0, -50)
@export var debug_offset_b: Vector2 = Vector2(0, -50)

@onready var knob_a: Node2D = $KnobA
@onready var knob_b: Node2D = $KnobB
@onready var area_a: Area2D = $KnobA/Area2D
@onready var area_b: Area2D = $KnobB/Area2D
@onready var noise_player: AudioStreamPlayer2D = $NoisePlayer
@onready var msg_player: AudioStreamPlayer2D = $MessagePlayer

var current_freq_a: float
var current_freq_b: float
var _dragging_idx: int = -1
var _both_prev: bool = false

func _ready() -> void:
	current_freq_a = clampf((min_freq + max_freq) * 0.45, min_freq, max_freq)
	current_freq_b = clampf((min_freq + max_freq) * 0.55, min_freq, max_freq)
	_set_knob_from_freq(0, current_freq_a)
	_set_knob_from_freq(1, current_freq_b)

	noise_player.play()  # startowo szum
	msg_player.stop()

	area_a.input_event.connect(func(_vp, e, _s): _on_knob_input(0, e))
	area_b.input_event.connect(func(_vp, e, _s): _on_knob_input(1, e))

	_update_audio_state()
	queue_redraw()

func _on_knob_input(idx: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging_idx = idx if event.pressed else -1
		if event.pressed:
			_update_knob_to_mouse(idx)
	elif event is InputEventMouseMotion and _dragging_idx == idx:
		_update_knob_to_mouse(idx)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging_idx = -1
	elif event is InputEventMouseMotion and _dragging_idx != -1:
		_update_knob_to_mouse(_dragging_idx)

func _update_knob_to_mouse(idx: int) -> void:
	var knob: Node2D = knob_a if idx == 0 else knob_b
	var ang := (get_global_mouse_position() - knob.global_position).angle()
	var deg := rad_to_deg(ang)
	var clamped := clampf(deg, angle_min, angle_max)
	knob.rotation_degrees = clamped

	var t := inverse_lerp(angle_min, angle_max, clamped)     # 0..1
	var f := lerpf(min_freq, max_freq, clampf(t, 0.0, 1.0))
	if idx == 0:
		current_freq_a = f
	else:
		current_freq_b = f

	_update_audio_state()
	queue_redraw()

func _set_knob_from_freq(idx: int, f: float) -> void:
	var knob: Node2D = knob_a if idx == 0 else knob_b
	var t := inverse_lerp(min_freq, max_freq, clampf(f, min_freq, max_freq))
	var deg := lerpf(angle_min, angle_max, clampf(t, 0.0, 1.0))
	knob.rotation_degrees = deg

func _is_in_band(f: float, target: float, tol: float) -> bool:
	return absf(f - target) <= tol

func _update_audio_state() -> void:
	var ok_a := _is_in_band(current_freq_a, target_freq_a, tolerance_a)
	var ok_b := _is_in_band(current_freq_b, target_freq_b, tolerance_b)
	var both := ok_a and ok_b

	if both and not _both_prev:
		if noise_player.playing: noise_player.stop()
		msg_player.stop()
		msg_player.play(0.0)
	elif not both and _both_prev:
		if msg_player.playing: msg_player.stop()
		noise_player.play()

	_both_prev = both

# ---------- DEBUG TEKST (Hz/MHz) ----------
func _draw() -> void:
	if not show_debug_text:
		return
	var font: Font = ThemeDB.fallback_font
	var txt_a := _fmt_freq("A", current_freq_a)
	var txt_b := _fmt_freq("B", current_freq_b)
	draw_string(font, knob_a.position + debug_offset_a, txt_a, HORIZONTAL_ALIGNMENT_LEFT, -1.0, debug_text_size)
	draw_string(font, knob_b.position + debug_offset_b, txt_b, HORIZONTAL_ALIGNMENT_LEFT, -1.0, debug_text_size)

func _fmt_freq(label: String, f: float) -> String:
	var hz := int(round(f * 1_000_000.0))
	return "%s: %s MHz (%d Hz)" % [label, String.num(f, 2), hz]
