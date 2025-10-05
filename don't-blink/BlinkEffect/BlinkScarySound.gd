extends Node
class_name BlinkScarySound

# --- Hookup ---
@export var blink_path: NodePath
@export var listener_path: NodePath     # Camera2D or Player

# --- Chance & cooldown ---
@export var chance_per_closing: float = 0.35              # overall chance per CLOSING
@export var cooldown_s: float = 2.5

# --- Mix (monster is rarer by default) ---
@export var weight_sound: float = 1.0
@export var weight_monster: float = 0.2                   # smaller = rarer

# --- SOUND setup ---
@export var sounds: Array[AudioStream] = []
@export var sound_bus: StringName = &"Master"
@export var base_volume_db: float = -6.0
@export var volume_jitter_db: float = 2.0
@export var pitch_jitter: float = 0.08

# --- MONSTER setup (still image that vanishes on cursor hover) ---
@export var monster_texture: Texture2D
@export var monster_scale: float = 1.0
@export var hit_radius_px: float = 64.0
@export var monster_z_index: int = 20
@export var touch_delay_s: float = 0.12
@export var fade_out_s: float = 0.18
@export var monster_max_lifetime_s: float = 0.5

# --- Placement (directional, “far away”) ---
@export var min_distance: float = 700.0
@export var max_distance: float = 1500.0

# Blink specifics
@export var closing_state_value: int = 1                  # your enum: CLOSING = 1
@export var run_when_paused: bool = true

# Internals
var _blink: Node
var _listener: Node2D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _cooldown_until_s: float = 0.0
var _last_state: int = -999

func _ready() -> void:
	if run_when_paused:
		process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()

	if blink_path != NodePath(""):
		_blink = get_node(blink_path)
	if listener_path != NodePath(""):
		_listener = get_node(listener_path) as Node2D

	# Prefer BlinkEffect.state_changed if available
	if _blink and _blink.has_signal("state_changed"):
		_blink.connect("state_changed", Callable(self, "_on_state_changed"))
	else:
		_last_state = _get_state()

func _process(_dt: float) -> void:
	# Poll only if no signal
	if not _blink or _blink.has_signal("state_changed"):
		return
	var s: int = _get_state()
	if s != _last_state:
		_last_state = s
		if s == closing_state_value:
			_maybe_trigger()

func _on_state_changed(new_state: int) -> void:
	if new_state == closing_state_value:
		_maybe_trigger()

func _get_state() -> int:
	if _blink and _blink.has_method("get"):
		var v: Variant = _blink.get("state")
		if typeof(v) == TYPE_INT:
			return int(v)
	return _last_state

func _maybe_trigger() -> void:
	var now_s: float = float(Time.get_ticks_msec()) / 1000.0
	if now_s < _cooldown_until_s:
		return
	if _rng.randf() > chance_per_closing:
		return

	# Choose between SOUND and MONSTER (monster rarer by weight)
	var ws: float = 0.0
	var wm: float = 0.0
	if not sounds.is_empty():
		ws = weight_sound
	if monster_texture != null:
		wm = weight_monster

	var total: float = ws + wm
	if total <= 0.0:
		return

	_cooldown_until_s = now_s + cooldown_s
	var r: float = _rng.randf() * total
	if r < wm:
		_spawn_monster()
	else:
		_play_sound()

# ---------------- SOUND ----------------
func _play_sound() -> void:
	var origin: Vector2 = Vector2.ZERO
	if is_instance_valid(_listener):
		origin = _listener.global_position
	else:
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam:
			origin = cam.global_position

	var pos: Vector2 = _random_pos_around(origin)

	var asp: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	asp.stream = sounds[_rng.randi_range(0, sounds.size() - 1)]
	asp.global_position = pos
	asp.bus = String(sound_bus)
	asp.volume_db = base_volume_db + _rng.randf_range(-volume_jitter_db, volume_jitter_db)
	asp.pitch_scale = 1.0 + _rng.randf_range(-pitch_jitter, pitch_jitter)
	asp.max_distance = max_distance * 1.5
	asp.attenuation = 1.0
	if run_when_paused:
		asp.process_mode = Node.PROCESS_MODE_ALWAYS

	add_child(asp)
	asp.finished.connect(func(): asp.queue_free())
	asp.play()

# ---------------- MONSTER ----------------
func _spawn_monster() -> void:
	if monster_texture == null:
		return

	var origin: Vector2 = Vector2.ZERO
	if is_instance_valid(_listener):
		origin = _listener.global_position
	else:
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam:
			origin = cam.global_position

	var pos: Vector2 = _random_pos_around(origin)

	var m: Node2D = Node2D.new()
	if run_when_paused:
		m.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(m)
	m.global_position = pos

	# Visual
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = monster_texture
	sprite.scale = Vector2(monster_scale, monster_scale)
	sprite.z_index = monster_z_index
	m.add_child(sprite)

	# Hover hit area
	var area: Area2D = Area2D.new()
	area.input_pickable = true
	if run_when_paused:
		area.process_mode = Node.PROCESS_MODE_ALWAYS
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = hit_radius_px
	var cs: CollisionShape2D = CollisionShape2D.new()
	cs.shape = shape
	area.add_child(cs)
	m.add_child(area)

	# Vanish on cursor touch (with tiny delay + fade)
	var touched: bool = false
	area.mouse_entered.connect(func():
		if touched: return
		touched = true
		area.input_pickable = false
		var tw: Tween = m.create_tween()
		if run_when_paused:
			tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_interval(touch_delay_s)
		tw.tween_property(sprite, "modulate:a", 0.0, fade_out_s).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.finished.connect(func():
			if is_instance_valid(m):
				m.queue_free()
		)
	)

	# Safety auto-despawn
	var t: Timer = Timer.new()
	t.one_shot = true
	t.wait_time = monster_max_lifetime_s
	if run_when_paused:
		t.process_mode = Node.PROCESS_MODE_ALWAYS
	m.add_child(t)
	t.timeout.connect(func():
		if is_instance_valid(m):
			m.queue_free()
	)
	t.start()

# ---------------- helpers ----------------
func _random_pos_around(origin: Vector2) -> Vector2:
	var dmin: float = min(min_distance, max_distance)
	var dmax: float = max(min_distance, max_distance)
	var dist: float = _rng.randf_range(dmin, dmax)
	var ang: float = _rng.randf_range(0.0, TAU)
	return origin + Vector2.RIGHT.rotated(ang) * dist
