extends Node

var player_name: String = ""

@export var gameplay_scene: String = "res://scenes/Test-FieldofView.tscn"

func start_new_game(name: String) -> void:
	#tutaj branie imienia ze sciezki systemowej
	player_name = name.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	_goto_scene(gameplay_scene)

func _goto_scene(path: String) -> void:
	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Failed to change scene to: %s (err %d)" % [path, err])
