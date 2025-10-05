extends Area2D

@export var title: String = "Cassette"
@export var video: VideoStream

@export var manager: CassetteManager

func _ready() -> void:
	# Ensure it can be clicked
	input_pickable = true
	# Make sure there's a shape
	if get_node_or_null("CollisionShape2D") == null:
		push_warning("[%s] No CollisionShape2D → clicks won't register." % name)
	# Connect the click signal
	self.input_event.connect(_on_input_event)

	# Quick diagnostics
	print("[%s] manager resolved: %s" % [name, str(manager)])
	if video == null:
		push_warning("[%s] No VideoStream assigned in Inspector." % name)

func _on_input_event(_vp: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("[%s] CLICK" % name)
		if manager == null:
			push_warning("[%s] CassetteManager not found (Unique Name?)." % name)
			return
		if video == null:
			push_warning("[%s] Missing VideoStream." % name)
			return
		manager.open(title, video)
