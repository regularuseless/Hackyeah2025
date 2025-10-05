extends Control

@export var pause_while_open: bool = false

@onready var picture: TextureRect = $Picture

func show_image(tex: Texture2D) -> void:
	if tex == null:
		return
	picture.texture = tex
	visible = true
	if pause_while_open:
		get_tree().paused = true

func close() -> void:
	visible = false
	if pause_while_open:
		get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		close()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
