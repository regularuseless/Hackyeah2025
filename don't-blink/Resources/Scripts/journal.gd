extends Area2D

@export var picture_to_show: Texture2D        # to jest obrazek który pokażemy na ekranie
@export var overlay_path: NodePath            # odnieś do instancji ImageOverlay w scenie

var overlay: Control

func _ready() -> void:
	if overlay_path != NodePath():
		overlay = get_node_or_null(overlay_path)
	# alternatywnie: szukaj po nazwie lub klasie:
	if overlay == null:
		overlay = get_tree().get_first_node_in_group("ImageOverlay")

func _input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if overlay and overlay.has_method("show_image") and picture_to_show:
			overlay.call("show_image", picture_to_show)
