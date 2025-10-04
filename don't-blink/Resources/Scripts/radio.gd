extends Node2D

# --- zakres strojenia (MHz) ---
@export var min_freq: float = 88.0
@export var max_freq: float = 108.0

# --- cele i tolerancje (MHz) ---
@export var target_freq_a: float = 101.7
@export var target_freq_b: float = 96.3
@export var tolerance_a: float = 0.25
@export var tolerance_b: float = 0.25

# --- zakres obrotu gałek (stopnie) ---
@export var angle_min: float = -120.0
@export var angle_max: float = 120.0

# --- krok strojenia (0 = płynnie) ---
@export var freq_step: float = 0.0

# --- (opcjonalnie) etykiety Control do wyświetlania tekstu ---
@export var label_a_path: NodePath
@export var label_b_path: NodePath

# Audio 2D
@onready var noise_player: AudioStreamPlayer2D = $NoisePlayer
@onready var msg_player: AudioStreamPlayer2D = $MessagePlayer

# Gałki + strefy wejścia
@onready var knob_a: Node2D = $KnobA
@onready var knob_b: Node2D = $KnobB
@onready var area_a: Area2D = $KnobA/Area2D
@onready var area_b: Area2D = $KnobB/Area2D

# (opcjonalne) etykiety
@onready var label_a: Label = $"LabelA"
@onready var label_b: Label = $"LabelB"

# Bieżące wartości (dostępne dla innych skryptów)
var current_freq_a: float
var current_freq_b: float
var freq_text_a: String = ""
var freq_text_b: String = ""

var _dragging_idx: int = -1  # -1 brak, 0=A, 1=B
var _both_prev: bool = false

func _ready() -> void:
	# podepnij etykiety jeśli ustawiono ścieżki
	if label_a_path != NodePath():
		var n := get_node_or_null(label_a_path)
		if n and n is Label:
			label_a = n
	if label_b_path != NodePath():
		var n2 := get_node_or_null(label_b_path)
		if n2 and n2 is Label:
			label_b = n2

	# startowe częstotliwości i obrót gałek
	current_freq_a = (min_freq + max_freq) * 0.45
	current_freq_b = (min_freq + max_freq) * 0.55
	_apply_knob_from_freq(0, current_freq_a)
	_apply_knob_from_freq(1, current_freq_b)

	# audio: szum gra, wiadomość zatrzymana
	noise_player.play()
	msg_player.stop()

	# wejście myszy
	area_a.input_event.connect(func(_vp, e, _s): _on_knob_input(0, e))
	area_b.input_event.connect(func(_vp, e, _s): _on_knob_input(1, e))

	_update_freq_texts()
	_update_audio_state()

func _on_knob_input(idx: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging_idx = idx
			_drag_update(idx)
		else:
			_dragging_idx = -1
	elif event is InputEventMouseMotion and _dragging_idx == idx:
		_drag_update(idx)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging_idx = -1
	elif event is InputEventMouseMotion and _dragging_idx != -1:
		_drag_update(_dragging_idx)

# aktualizacja podczas przeciągania:
# - kąt gałki clamp do angle_min/max
# - częstotliwość mapowana 1:1 do min/max i clamp (saturacja)
func _drag_update(idx: int) -> void:
	var knob := _get_knob(idx)
	var mouse := get_global_mouse_position()
	var deg := rad_to_deg((mouse - knob.global_position).angle())
	var clamped_deg := clampf(deg, angle_min, angle_max)
	knob.rotation_degrees = clamped_deg

	var t := inverse_lerp(angle_min, angle_max, clamped_deg)      # 0..1
	var f := lerpf(min_freq, max_freq, clampf(t, 0.0, 1.0))       # MHz
	if freq_step > 0.0:
		f = round(f / freq_step) * freq_step
	f = clampf(f, min_freq, max_freq)                             # SATURACJA

	if idx == 0:
		current_freq_a = f
	else:
		current_freq_b = f

	_update_freq_texts()
	_update_audio_state()

# mapowanie: częstotliwość -> obrót (do ustawień startowych lub z zewnątrz)
func _apply_knob_from_freq(idx: int, f: float) -> void:
	var knob := _get_knob(idx)
	var cf := clampf(f, min_freq, max_freq)
	var t := inverse_lerp(min_freq, max_freq, cf)
	var deg := lerpf(angle_min, angle_max, clampf(t, 0.0, 1.0))
	knob.rotation_degrees = deg

func _get_knob(idx: int) -> Node2D:
	if idx == 0:
		return knob_a
	return knob_b

func _is_in_band(f: float, target: float, tol: float) -> bool:
	return absf(f - target) <= tol

func _update_audio_state() -> void:
	var ok_a := _is_in_band(current_freq_a, target_freq_a, tolerance_a)
	var ok_b := _is_in_band(current_freq_b, target_freq_b, tolerance_b)
	var both := ok_a and ok_b

	if both and not _both_prev:
		if noise_player.playing:
			noise_player.stop()
		msg_player.stop()
		msg_player.play(0.0)
	elif not both and _both_prev:
		if msg_player.playing:
			msg_player.stop()
		noise_player.play()

	_both_prev = both

# --- tekst do etykiet / na potrzeby innych skryptów ---
func _update_freq_texts() -> void:
	freq_text_a = _fmt_freq(current_freq_a)
	freq_text_b = _fmt_freq(current_freq_b)
	if label_a:
		label_a.text = freq_text_a
	if label_b:
		label_b.text = freq_text_b

func _fmt_freq(f: float) -> String:
	return String.num(f, 2) + " MHz"
