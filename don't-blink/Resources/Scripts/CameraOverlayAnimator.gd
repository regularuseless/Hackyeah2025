extends TextureRect
class_name CameraOverlayAnimator

@export var normal_tex: Texture2D

# Button nodes resolved via Unique Names (as you have)
@onready var play_btn: Button  = %PlayButton
@onready var pause_btn: Button = %PauseButton
@onready var loop_btn: Button  = %LoopButton
# If you add Close later, just add:
# @onready var close_btn: Button = %CloseButton

# PLAY overlays
@export var play_hover: Texture2D
@export var play_down: Texture2D          # “start pressing”
@export var play_pressed: Texture2D

# PAUSE overlays
@export var pause_hover: Texture2D
@export var pause_down: Texture2D
@export var pause_pressed: Texture2D

# LOOP overlays
@export var loop_hover: Texture2D
@export var loop_down: Texture2D
@export var loop_pressed: Texture2D

var _current: StringName = &""
var _state: StringName = &"normal"
var _bounce_ticket: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture = normal_tex

	_wire_button(&"play",  play_btn)
	_wire_button(&"pause", pause_btn)
	_wire_button(&"loop",  loop_btn)
	# _wire_button(&"close", close_btn)  # if you add Close later

func _wire_button(id: StringName, b: Button) -> void:
	if b == null:
		return

	b.mouse_entered.connect(func(): _set_state(id, &"hover"))

	b.mouse_exited.connect(func():
		if _current == id:
			_set_state(&"", &"normal")
	)

	b.button_down.connect(func(): _set_state(id, &"down"))

	b.button_up.connect(func():
		var over := b.get_global_rect().has_point(get_viewport().get_mouse_position())
		_set_state(id if over else &"", &"hover" if over else &"normal")
	)

	b.pressed.connect(func(): _pressed_bounce(id, b))

func _pressed_bounce(id: StringName, b: Button) -> void:
	# Sequence: pressed → short down flash → hover/normal
	_set_state(id, &"pressed")
	_bounce_ticket += 1
	var my := _bounce_ticket

	get_tree().create_timer(0.07, false).timeout.connect(func():
		if my != _bounce_ticket or _current != id:
			return
		_set_state(id, &"down")
		get_tree().create_timer(0.12, false).timeout.connect(func():
			if my != _bounce_ticket:
				return
			var over := b.get_global_rect().has_point(get_viewport().get_mouse_position())
			_set_state(id if over else &"", &"hover" if over else &"normal")
		)
	)

func _set_state(id: StringName, st: StringName) -> void:
	_current = id
	_state = st
	var tex := _pick_texture(id, st)
	texture = tex if tex != null else normal_tex

func _pick_texture(id: StringName, st: StringName) -> Texture2D:
	match String(id):
		"play":
			match String(st):
				"hover":   return play_hover
				"down":    return play_down
				"pressed": return play_pressed
		"pause":
			match String(st):
				"hover":   return pause_hover
				"down":    return pause_down
				"pressed": return pause_pressed
		"loop":
			match String(st):
				"hover":   return loop_hover
				"down":    return loop_down
				"pressed": return loop_pressed
		# Add a "close" branch here if you add CloseButton + its textures.
	return null
