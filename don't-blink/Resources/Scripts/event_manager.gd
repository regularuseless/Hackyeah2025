extends Node
class_name RandomEventManager

# --- Scheduling ---
@export var autostart: bool = true
@export var run_when_paused: bool = false
@export var min_interval_s: float = 8.0
@export var interval_jitter_s: float = 6.0

# Event weights
@export var weight_sound: float = 1.0
@export var weight_animation: float = 1.0
@export var weight_face: float = 1.0

# --- SOUND EVENT ---
@export var listener: NodePath
@export var sound_min_distance: float = 400.0
@export var sound_max_distance: float = 900.0
@export var sound_streams: Array[AudioStream] = []
@export var sound_bus: StringName = &"Master"
@export var sound_volume_db: float = 0.0

# --- ANIMATION EVENT ---
@export var animation_targets: Array[NodePath] = []
@export var animation_name: StringName = &""

# --- FACE EVENT (UI overlay) ---
@export var faces_layer: NodePath
@export var face_bounds: NodePath    # optional rect to confine faces (e.g., camera viewfinder)
@export var face_textures: Array[Texture2D] = []
@export var face_min_scale: float = 0.1
@export var face_max_scale: float = 0.2
@export var face_padding: float = 160.0
@export var face_fade_in_s: float = 0.25
@export var face_hold_s: float = 0.7
@export var face_fade_out_s: float = 0.4
@export var face_jitter_s: float = 0.3
@export var face_z_index: int = 100

# --- Internals ---
var _timer: Timer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _running: bool = false

func _ready() -> void:
	_rng.randomize()

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.autostart = false
	_timer.process_callback = Timer.TIMER_PROCESS_IDLE
	add_child(_timer)

	if run_when_paused:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_timer.process_mode = Node.PROCESS_MODE_ALWAYS

	_ensure_faces_layer()

	if autostart:
		start()

func start() -> void:
	if _running:
		return
	_running = true
	_schedule_next()

func stop() -> void:
	_running = false
	if _timer:
		_timer.stop()

func _schedule_next() -> void:
	if not _running:
		return
	var t: float = min_interval_s + _rng.randf_range(0.0, max(0.0, interval_jitter_s))
	_timer.start(t)
	_timer.timeout.connect(_on_tick, Object.CONNECT_ONE_SHOT)

func _on_tick() -> void:
	var total: float = weight_sound + weight_animation + weight_face
	if total <= 0.0:
		_schedule_next()
		return

	var r: float = _rng.randf() * total
	if r < weight_sound:
		_event_sound()
	elif r < weight_sound + weight_animation:
		_event_animation()
	else:
		_event_face()

	_schedule_next()

# ===================== EVENTS =====================

func _event_sound() -> void:
	if sound_streams.is_empty():
		return

	var origin: Vector2 = Vector2.ZERO
	var l: Node2D = get_node_or_null(listener) as Node2D
	if l:
		origin = l.global_position
	else:
		var cam: Camera2D = get_viewport().get_camera_2d()
		if cam:
			origin = cam.global_position

	var dist: float = _rng.randf_range(sound_min_distance, sound_max_distance)
	var ang: float = _rng.randf_range(0.0, TAU)
	var pos: Vector2 = origin + Vector2.RIGHT.rotated(ang) * dist

	var asp: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	asp.stream = sound_streams[_rng.randi_range(0, sound_streams.size() - 1)]
	asp.global_position = pos
	asp.bus = sound_bus
	asp.volume_db = sound_volume_db
	asp.max_distance = sound_max_distance * 1.5
	asp.attenuation = 1.0
	add_child(asp)
	asp.finished.connect(func(): asp.queue_free())
	asp.play()

func _event_animation() -> void:
	if animation_targets.is_empty():
		return

	var target_path: NodePath = animation_targets[_rng.randi_range(0, animation_targets.size() - 1)]
	var node: Node = get_node_or_null(target_path)
	if node == null:
		return

	var ap: AnimationPlayer = node.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if ap == null:
		if node is AnimationPlayer:
			ap = node as AnimationPlayer
		else:
			ap = node.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return

	var name_to_play: StringName = animation_name
	if String(name_to_play).is_empty():
		var list: PackedStringArray = ap.get_animation_list()
		if list.is_empty():
			return
		name_to_play = list[_rng.randi_range(0, list.size() - 1)]

	ap.play(name_to_play)

func _event_face() -> void:
	var layer: Control = _ensure_faces_layer()
	if layer == null or face_textures.is_empty():
		return

	# Determine spawn parent & rect (bounds if provided, else whole layer)
	var parent: Control = layer
	var rect: Rect2 = layer.get_rect()
	var bounds_node: Control = get_node_or_null(face_bounds) as Control
	if bounds_node:
		parent = bounds_node
		rect = bounds_node.get_rect()

	# If rect hasn't been sized yet, wait a frame
	if rect.size == Vector2.ZERO:
		await get_tree().process_frame
		rect = parent.get_rect()

	var tex: Texture2D = face_textures[_rng.randi_range(0, face_textures.size() - 1)]
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.z_as_relative = false
	tr.z_index = face_z_index
	tr.set_anchors_preset(Control.PRESET_TOP_LEFT)

	var scale: float = _rng.randf_range(face_min_scale, face_max_scale)
	var tex_size: Vector2 = tex.get_size() * scale
	tr.custom_minimum_size = tex_size

	var minx: float = face_padding
	var miny: float = face_padding
	var maxx: float = max(minx, rect.size.x - tex_size.x - face_padding)
	var maxy: float = max(miny, rect.size.y - tex_size.y - face_padding)
	tr.position = Vector2(_rng.randf_range(minx, maxx), _rng.randf_range(miny, maxy))
	tr.modulate = Color(1, 1, 1, 0.0)

	parent.add_child(tr)
	tr.move_to_front()

	var hold: float = max(0.1, face_hold_s + _rng.randf_range(-face_jitter_s, face_jitter_s))
	var tw: Tween = tr.create_tween()
	if run_when_paused:
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(tr, "modulate:a", 1.0, face_fade_in_s).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(tr, "modulate:a", 0.0, face_fade_out_s).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.finished.connect(func(): tr.queue_free())

# ===================== UTIL =====================

func _ensure_faces_layer() -> Control:
	var layer: Control = get_node_or_null(faces_layer) as Control
	if layer:
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.visible = true
		layer.z_as_relative = false
		layer.z_index = 10_000
	return layer
