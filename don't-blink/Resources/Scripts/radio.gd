extends Node2D

# --- Zakres strojenia (MHz) ---
@export var min_freq: float = 88.0
@export var max_freq: float = 108.0

# --- Cel i „miękkość” strojenia ---
@export var target_freq: float = 101.7
@export var tolerance: float = 0.25      # ±MHz = pełna czytelność
@export var soft_edge: float = 1.0       # jak łagodnie spada poza tolerancją (większe = łagodniej)

# --- Mapa kąt <-> częstotliwość ---
@export var angle_min: float = -120.0    # stopnie
@export var angle_max: float = 120.0

# --- Crossfade w dB (głośność docelowa) ---
@export var msg_db_min: float = -40.0
@export var msg_db_max: float = 0.0
@export var noise_db_min: float = -80.0
@export var noise_db_max: float = 0.0

# --- Wygładzenie zmian głośności (dB/s) ---
@export var fade_speed_db: float = 60.0  # jak szybko dochodzimy do docelowej głośności

# (opcjonalnie) debugowy tekst w świecie
@export var show_debug_text: bool = false
@export var debug_text_size: int = 18
@export var debug_offset: Vector2 = Vector2(0, -50)

@onready var knob: Node2D = $Knob
@onready var area: Area2D = $Knob/Area2D
@onready var noise_player: AudioStreamPlayer2D = $NoisePlayer
@onready var msg_player: AudioStreamPlayer2D = $MessagePlayer

var current_freq: float
var _dragging: bool = false

# cele (docelowe dB), do których płynnie dochodzimy w _process
var _msg_db_goal: float = 0.0
var _noise_db_goal: float = 0.0

func _ready() -> void:
	# start: środek zakresu
	current_freq = (min_freq + max_freq) * 0.5
	_set_knob_from_freq(current_freq)

	# grają oba — będziemy tylko zmieniać głośność
	if not noise_player.playing: noise_player.play()
	if not msg_player.playing: msg_player.play()

	area.input_event.connect(_on_area_input)

	_update_goals()
	_apply_volume_immediate()

func _process(delta: float) -> void:
	# płynne dochodzenie do docelowych głośności (dB)
	var step := fade_speed_db * delta
	if absf(noise_player.volume_db - _noise_db_goal) > 0.05:
		noise_player.volume_db = move_toward(noise_player.volume_db, _noise_db_goal, step)
	if absf(msg_player.volume_db - _msg_db_goal) > 0.05:
		msg_player.volume_db = move_toward(msg_player.volume_db, _msg_db_goal, step)

func _on_area_input(_vp, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_update_to_mouse()
	elif event is InputEventMouseMotion and _dragging:
		_update_to_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		_update_to_mouse()

func _update_to_mouse() -> void:
	var ang := (get_global_mouse_position() - knob.global_position).angle()
	var deg := rad_to_deg(ang)
	var clamped := clampf(deg, angle_min, angle_max)
	knob.rotation_degrees = clamped

	var t := inverse_lerp(angle_min, angle_max, clamped)            # 0..1
	current_freq = lerpf(min_freq, max_freq, clampf(t, 0.0, 1.0))   # MHz

	_update_goals()
	if show_debug_text:
		queue_redraw()

func _set_knob_from_freq(f: float) -> void:
	var t := inverse_lerp(min_freq, max_freq, clampf(f, min_freq, max_freq))
	var deg := lerpf(angle_min, angle_max, t)
	knob.rotation_degrees = deg

func _tuned_ratio() -> float:
	# 1.0 w tolerancji, potem liniowo maleje o 1/soft_edge na każdy MHz poza
	var d := absf(current_freq - target_freq)
	if d <= tolerance:
		return 1.0
	var extra := d - tolerance
	var falloff := 1.0 / maxf(0.001, soft_edge)
	return clampf(1.0 - extra * falloff, 0.0, 1.0)

func _update_goals() -> void:
	var r := _tuned_ratio()   # 0..1
	_msg_db_goal = lerpf(msg_db_min, msg_db_max, r)
	_noise_db_goal = lerpf(noise_db_max, noise_db_min, r)

func _apply_volume_immediate() -> void:
	noise_player.volume_db = _noise_db_goal
	msg_player.volume_db = _msg_db_goal

# --- debug: wyświetlanie częstotliwości (opcjonalne) ---
func _draw() -> void:
	if not show_debug_text:
		return
	var font: Font = ThemeDB.fallback_font
	var txt := String.num(current_freq, 2) + " MHz"
	draw_string(font, knob.position + debug_offset, txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, debug_text_size)
