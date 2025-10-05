# ImageOverlay.gd
extends Control
class_name ImageOverlay

@onready var picture: TextureRect = $Picture

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # łap klik, nie przepuszczaj do gry

func show_image(tex: Texture2D) -> void:
	if tex == null: 
		return
	picture.texture = tex
	visible = true

func close() -> void:
	visible = false
	picture.texture = null

# kliknięcie gdziekolwiek w overlay zamyka
func gui_input(event: InputEvent) -> void:
	if not visible: 
		return
	if event is InputEventMouseButton and event.pressed:
		close()

# Esc też zamyka
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
