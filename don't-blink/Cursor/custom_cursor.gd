# custom_cursor.gd (Typo fixed, with enhanced debugging)
extends CanvasLayer

const CURSOR_DEFAULT = preload("res://Cursor/default.png")
const CURSOR_DEFAULT_PRESSED = preload("res://Cursor/default pressed.png")
const CURSOR_INTERACTION = preload("res://Cursor/highlight interaction.png")
const CURSOR_PRESSED_INTERACTION = preload("res://Cursor/pressed interaction.png")

@onready var sprite: Sprite2D = $Sprite2D

var is_pressed: bool = false
var is_over_interactable: bool = false
var current_texture: Texture = CURSOR_DEFAULT # Track the current texture

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta):
	sprite.global_position = get_viewport().get_mouse_position()
	check_for_interactable()
	update_cursor_texture()

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_pressed = event.is_pressed()

func check_for_interactable():
	var viewport = get_viewport()
	
	var world_mouse_position = viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	
	var world_space = viewport.get_world_2d().direct_space_state

	var query = PhysicsPointQueryParameters2D.new()
	# Use the correctly transformed world position for the query
	query.position = world_mouse_position
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 2 
	
	var results = world_space.intersect_point(query)
	
	# The rest of the function remains the same
	is_over_interactable = false
	
	if not results.is_empty():
		for result in results:
			# The debug prints are still here if you need them
			# print("  - Checking: ", result.collider.name, " | In 'interactable' group? -> ", result.collider.is_in_group("interactable"))
			if result.collider.is_in_group("interactable"):
				is_over_interactable = true
				break

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
			
	# This logic only updates the texture and prints when a change is needed
	if sprite.texture != new_texture:
		sprite.texture = new_texture
		print("[Cursor Debug] Texture changed to: ", new_texture.resource_path.get_file())
