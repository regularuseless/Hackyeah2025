extends Control
class_name FaceOverlay

@export var face_textures: Array[Texture2D] = []

# Random delay between spawns
@export var min_delay: float = 6.0
@export var max_delay: float = 14.0

# Fade timings
@export var fade_in_time: float = 0.35
@export var hold_time: float = 0.7
@export var fade_out_time: float = 0.6

# Face sizing & placement
@export var min_size_px: int = 160
@export var max_size_px: int = 420
@export var screen_margin_px: int = 24
@export var max_simultaneous: int = 1
@export var random_rotation_deg: float = 0.0    # e.g. 5.0 for a subtle tilt

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

	# Make sure this Control is full-screen and on top of other UI
	anchors_preset = PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	z_index = 1000

	# Keep size in sync with window/viewport
	if get_viewport() != null:
		size = get_viewport().get_visible_rect().size
		get_viewport().size_changed.connect(_on_viewport_resized)

	# Start the spawn loop
	_spawn_loop()

func _on_viewport_resized() -> void:
	if get_viewport() != null:
		size = get_viewport().get_visible_rect().size

func _spawn_loop() -> void:
	await get_tree().process_frame  # let scene settle
	while true:
		var wait_s: float = _rng.randf_range(min_delay, max_delay)
		var timer: SceneTreeTimer = get_tree().create_timer(wait_s)
		await timer.timeout
		if face_textures.is_empty():
			continue
		_spawn_one_face()

func _spawn_one_face() -> void:
	# Limit how many faces can be visible at the same time
	var live: Array[Node] = get_tree().get_nodes_in_group("face_overlay_face")
	if live.size() >= max_simultaneous:
		return

	var tex_index: int = _rng.randi_range(0, face_textures.size() - 1)
	var tex: Texture2D = face_textures[tex_index]
	if tex == null:
		return

	# Create a TextureRect as the face
	var face: TextureRect = TextureRect.new()
	face.add_to_group("face_overlay_face")
	face.texture = tex
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.focus_mode = Control.FOCUS_NONE
	face.modulate = Color(1.0, 1.0, 1.0, 0.0)
	face.z_index = 1001  # above this control if needed

	# --- SIZING ---
	var tex_w: float = float(tex.get_width())
	var tex_h: float = float(tex.get_height())
	var aspect: float = tex_w / max(tex_h, 0.0001)

	var desired_w: float = _rng.randf_range(float(min_size_px), float(max_size_px))
	var w: float = desired_w
	var h: float = w / max(aspect, 0.0001)

	face.size = Vector2(w, h)

	# --- POSITION (viewport-relative) ---
	var vp: Vector2 = size
	var margin_f: float = float(screen_margin_px)
	var min_x: float = margin_f
	var min_y: float = margin_f
	var max_x: float = max(vp.x - margin_f - face.size.x, margin_f)
	var max_y: float = max(vp.y - margin_f - face.size.y, margin_f)

	face.position = Vector2(
		_rng.randf_range(min_x, max_x),
		_rng.randf_range(min_y, max_y)
	)

	# Optional small random rotation (Control uses radians)
	if random_rotation_deg > 0.0:
		face.pivot_offset = face.size * 0.5
		face.position -= face.size * 0.5  # center the pivot on screen pos
		var rot_deg: float = _rng.randf_range(-random_rotation_deg, random_rotation_deg)
		face.rotation = deg_to_rad(rot_deg)

	add_child(face)

	# --- TWEEN ---
	var tw: Tween = create_tween()
	tw.tween_property(face, "modulate:a", 1.0, fade_in_time)
	tw.tween_interval(hold_time)
	tw.tween_property(face, "modulate:a", 0.0, fade_out_time)
	tw.tween_callback(Callable(face, "queue_free"))

# Optional helper to trigger a face immediately (e.g., from a debug key)
func spawn_now() -> void:
	_spawn_one_face()
