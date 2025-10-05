# custom_cursor.gd
extends CanvasLayer

const CURSOR_DEFAULT = preload("res://Cursor/default.png")
const CURSOR_DEFAULT_PRESSED = preload("res://Cursor/default pressed.png")
const CURSOR_INTERACTION = preload("res://Cursor/highlight interaction.png")
const CURSOR_PRESSED_INTERACTION = preload("res://Cursor/pressed interaction.png")

@onready var sprite: Sprite2D = $Sprite2D

var is_pressed: bool = false
var is_over_interactable: bool = false

# --- NEW: A variable to hold a reference to the player node ---
var player = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# We wait one frame before getting the player. This is a robust way
	# to make sure the main scene tree has loaded and the "player" group is available.
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	sprite.global_position = get_viewport().get_mouse_position()
	check_for_interactable()
	update_cursor_texture()

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_pressed = event.is_pressed()

func check_for_interactable():
	# --- MODIFIED LOGIC ---
	# If we haven't found the player for some reason, we can't do the check,
	# so we should default to the non-interactable state.
	if player == null:
		is_over_interactable = false
		return

	var viewport = get_viewport()
	var world_mouse_position = viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	var world_space = viewport.get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_mouse_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 2 
	
	var results = world_space.intersect_point(query)
	
	is_over_interactable = false # Reset the state each frame
	
	if not results.is_empty():
		for result in results:
			var hovered_object = result.collider
			
			# Check 1: Is the object under the mouse in the "interactable" group?
			if hovered_object.is_in_group("interactable"):
				
				# Check 2: Is the player in range of THIS specific object?
				if player.is_in_interaction_range(hovered_object):
					# Only if both checks pass, we set the flag to true.
					is_over_interactable = true
					break # Found a valid target, no need to check others.

func update_cursor_texture():
	var new_texture = null
	
	if is_over_interactable:
		if is_pressed:
			new_texture = CURSOR_PRESSED_INTERACTION
		else:
			new_texture = CURSOR_INTERACTION
	else:
		if is_pressed:
			new_texture = CURSOR_DEFAULT_PRESSED
		else:
			new_texture = CURSOR_DEFAULT
			
	if sprite.texture != new_texture:
		sprite.texture = new_texture
