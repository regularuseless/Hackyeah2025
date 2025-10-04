@tool
extends Node2D

@export var world_boundary := Rect2(0, 0, 1920, 1080):
	set(value):
		world_boundary = value
		# If the value changes, tell the editor it needs to redraw this node.
		if Engine.is_editor_hint():
			queue_redraw()

## The master switch for the wrapping mechanic.
@export var is_wrapping_enabled := true

@onready var player = $Player
@onready var map_clones = $MapClones

func _draw():
	# This check ensures the drawing only happens in the editor, not in the game.
	if not Engine.is_editor_hint():
		return
		
	# Draw a rectangle with a yellow color, not filled, and a width of 2 pixels.
	draw_rect(world_boundary, Color.YELLOW, false, 2.0)


func _physics_process(_delta: float):
	if Engine.is_editor_hint():
		return

	# Lazily get nodes only when the game is running
	if player == null:
		player = get_node("Player")
	if map_clones == null:
		map_clones = get_node("MapClones")

	map_clones.visible = is_wrapping_enabled
	
	if not is_wrapping_enabled:
		return

	var player_pos = player.global_position
	
	# Use the same fmod logic to calculate the correct wrapped position
	var new_pos = player_pos
	var bounds_pos = world_boundary.position
	var bounds_size = world_boundary.size
	new_pos.x = fmod(player_pos.x - bounds_pos.x + bounds_size.x, bounds_size.x) + bounds_pos.x
	new_pos.y = fmod(player_pos.y - bounds_pos.y + bounds_size.y, bounds_size.y) + bounds_pos.y

	if new_pos != player_pos:
		var adjustment = new_pos - player_pos
		
		player.global_position = new_pos
		
		player.adjust_target_after_teleport(adjustment)


func _on_settings_manager_loop_mode_changed(is_enabled: bool) -> void:
	is_wrapping_enabled = is_enabled
