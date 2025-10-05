extends Area2D

@export var puzzle_scene: PackedScene = preload("res://Scenes/Radio_puzzle.tscn")
@export var overlay_parent_path: NodePath = ^"../../Ui"   # <-- set to your CanvasLayer "Ui"
@export var player_path: NodePath = ^"../../Player"       # optional, if you want Node2D puzzles at player
@export var spawn_on_player: bool = false                 # true only if your puzzle root is Node2D

var _puzzle: Node = null

func _ready() -> void:
	input_pickable = true  # required for _input_event on Area2D
	# (also be sure CollisionShape2D.shape is set)

func _input_event(_vp, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_open_puzzle()

func _open_puzzle() -> void:
	if _puzzle != null:
		return
	if puzzle_scene == null:
		push_warning("puzzle_scene is not set.")
		return

	var parent := get_node_or_null(overlay_parent_path)
	if parent == null:
		
		parent = get_tree().current_scene

	_puzzle = puzzle_scene.instantiate()
	parent.add_child(_puzzle)

	
	if _puzzle is Control:
		var c := _puzzle as Control
		c.set_anchors_preset(Control.PRESET_FULL_RECT)
		c.offset_left = 0
		c.offset_top = 0
		c.offset_right = 0
		c.offset_bottom = 0
	
	elif _puzzle is Node2D and spawn_on_player:
		var n := _puzzle as Node2D
		var spawn_pos := global_position
		var player := get_node_or_null(player_path) as Node2D
		if player != null:
			spawn_pos = player.global_position
		n.global_position = spawn_pos
		n.z_index = 100

	_puzzle.tree_exited.connect(func ():
		_puzzle = null
	)
