extends ColorRect

@onready var mat: ShaderMaterial = (material as ShaderMaterial)

# — Tweakables —
@export var base_radius: float = 100.0
@export var pulse_amp: float = 4.0
@export var pulse_speed: float = 0.5          # pulses per second
@export var jitter_amp: float = 1.0
@export var jitter_change_interval: float = 0.25
@export var follow_smoothing_px_per_s: float = 0.0  # 0 = instant; >0 = lag

# — Internals —
var _t: float = 0.0
var _jitter_val: float = 0.0
var _jitter_target: float = 0.0
var _jitter_timer: float = 0.0
var _center: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_center = get_viewport().get_mouse_position()

func _process(delta: float) -> void:
	if mat == null:
		return
	_t += delta

	# 1) Update center (mouse follow with optional smoothing)
	var mouse_px: Vector2 = get_viewport().get_mouse_position()
	if follow_smoothing_px_per_s <= 0.0:
		_center = mouse_px
	else:
		_center = _center.move_toward(mouse_px, follow_smoothing_px_per_s * delta)
	mat.set_shader_parameter("hole_center", _center)

	# 2) Smooth random jitter target
	_jitter_timer -= delta
	if _jitter_timer <= 0.0:
		_jitter_timer = jitter_change_interval
		_jitter_target = randf_range(-jitter_amp, jitter_amp)
	# exponential smoothing factor; explicitly float math
	var smooth_k: float = 1.0 - pow(0.001, delta)
	_jitter_val = lerpf(_jitter_val, _jitter_target, smooth_k)

	# 3) Pulse + jitter radius
	var pulse: float = sin(TAU * pulse_speed * _t) * pulse_amp
	var radius: float = max(0.0, base_radius + pulse + _jitter_val)
	mat.set_shader_parameter("hole_radius", radius)
