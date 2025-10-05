extends Area2D

@export var picture_to_show: Texture2D     # obrazek, który ma się wyświetlić na ekranie
@export var overlay_path: NodePath         # ścieżka do węzła ImageOverlay

var overlay: ImageOverlay = null

func _ready() -> void:
	input_pickable = true  # dla pewności
	if overlay_path != NodePath():
		overlay = get_node_or_null(overlay_path) as ImageOverlay
	if overlay == null:
		push_warning("overlay_path nie ustawiony lub nie wskazuje ImageOverlay.")

func _input_event(_vp, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if overlay and picture_to_show:
			overlay.show_image(picture_to_show)
