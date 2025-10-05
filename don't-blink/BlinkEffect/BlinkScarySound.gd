extends Node
class_name BlinkScarySound

@export var blink_path: NodePath
@export var listener_path: NodePath

@export var sounds: Array[AudioStream] = []
@export var chance_per_closing: float = 0.15
@export var cooldown_s: float = 3.0

@export var min_distance: float = 700.0
@export var max_distance: float = 1500.0
@export var base_volume_db: float = -6.0
@export var volume_jitter_db: float = 2.0
@export var pitch_jitter: float = 0.08
@export var bus: StringName = &"Master"

@export var closing_state_value: int = 1  # CLOSING per your enum
@export var run_when_paused: bool = true

var _blink: Node
var _listener: Node2D
var _last_state: int = -999
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _cooldown_until_s: float = 0.0

func _ready() -> void:
	if run_when_paused:
		process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()

	if blink_path != NodePath(""):
		_blink = get_node(blink_path)
	if listener_path != NodePath(""):
		_listener = get_node(listener_path) as Node2D

	# Prefer the new state_changed signal
	if _blink and _blink.has_signal("state_changed"):
		_blink.connect("state_changed", Callable(self, "_on_state_changed"))
	else:
		# Fallback: poll property if available
		_last_state = _get_state()

func _process(_dt: float) -> void:
	# Only used if we didn't get the signal
	if not _blink or _blink.has_signal("state_changed") == true:
		return
	var s: int = _get_state()
	if s != _last_state:
		_last_state = s
		if s == closing_state_value:
			_maybe_play()

func _on_state_changed(new_state: int) -> void:
	if new_state == closing_state_value:
		_maybe_play()

func _get_state() -> int:
	if _blink and _blink.has_method("get"):
		var v: Variant = _blink.get("state")  # uses the property we added
		if typeof(v) == TYPE_INT:
			return int(v)
	return _last_state

func _maybe_play() -> void:
	if sounds.is_empty():
		return
	var now_s: float = float(Time.get_ticks_msec()) / 1000.0
	if now_s < _cooldown_until_s:
		return
	if _rng.randf() > chance_per_closing:
		return
	_cooldown_until_s = now_s + cooldown_s
	_play_at_random_direction()

func _play_at_random_direction() -> void:
	var origin: Vector2 = Vector2.ZERO
	if is_instance_valid(_listener):
		origin = _listener.global_position
	else:
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam:
			origin = cam.global_position

	var dmin: float = min(min_distance, max_distance)
	var dmax: float = max(min_distance, max_distance)
	var dist: float = _rng.randf_range(dmin, dmax)
	var ang: float = _rng.randf_range(0.0, TAU)
	var pos: Vector2 = origin + Vector2.RIGHT.rotated(ang) * dist

	var asp: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	asp.stream = sounds[_rng.randi_range(0, sounds.size() - 1)]
	asp.global_position = pos
	asp.bus = String(bus)
	asp.volume_db = base_volume_db + _rng.randf_range(-volume_jitter_db, volume_jitter_db)
	asp.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
	asp.max_distance = dmax * 1.5
	asp.attenuation = 1.0
	if run_when_paused:
		asp.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(asp)
	asp.finished.connect(func(): asp.queue_free())
	asp.play()
