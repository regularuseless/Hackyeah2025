extends CharacterBody2D

@export var walk_speed := 160.0
@export var sprint_multiplier := 1.8
@export var stop_radius := 2.0
@export var stamina_max := 100.0
@export var stamina_drain := 30.0
@export var stamina_regen := 20.0
@export var stamina_regen_delay := 0.5

var stamina := 100.0
var _time_since_sprint := 9999.0
var _has_target := false
var _target := Vector2.ZERO
@onready var animated_sprite = $AnimatedSprite2D

var _interactable_objects_in_range = []

func _ready() -> void:
	stamina = stamina_max
	$Camera2D.make_current()
	$Camera2D.zoom = Vector2(3.5, 3.5)  # przybliżenie (mniej niż 1.0 = bliżej)

func _input(event: InputEvent) -> void:
	# We only care about left mouse button presses.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		
		# Before moving, let's check what we clicked on.
		var mouse_pos = get_global_mouse_position()
		
		# Create a query to check the physics space at the mouse position.
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		# We query for Area2D nodes, since our interactables are Areas.
		query.collide_with_areas = true
		var results = space_state.intersect_point(query)
		
		# Loop through everything we clicked on.
		for result in results:
			var clicked_object = result.collider
			# If the object we clicked is one of the interactables currently in our range...
			if _interactable_objects_in_range.has(clicked_object):
				# ...then this click was for an interaction, NOT for movement.
				# We stop processing here and do not set a new movement target.
				print("Clicked on a nearby interactable. Ignoring for movement.")
				return 
		
		# If the loop finishes without finding a nearby interactable, it was a normal movement click.
		_target = mouse_pos
		_has_target = true


func _physics_process(delta: float):
	var sprinting := false
	var speed := walk_speed

	if _has_target:
		var to_target := _target - global_position
		if to_target.length() <= stop_radius:
			_has_target = false
			velocity = Vector2.ZERO
		else:
			var dir := to_target.normalized()
			if Input.is_action_pressed("sprint") and stamina > 0.1:
				sprinting = true
				speed *= sprint_multiplier
				stamina = max(0.0, stamina - stamina_drain * delta)
				_time_since_sprint = 0.0
			velocity = dir * speed
			move_and_slide()
	else:
		velocity = Vector2.ZERO

	if sprinting: _time_since_sprint = 0.0
	else:
		_time_since_sprint += delta
		if _time_since_sprint >= stamina_regen_delay:
			stamina = min(stamina_max, stamina + stamina_regen * delta)

	_update_animation()

func _update_animation():
	if velocity.x > 0: animated_sprite.flip_h = true
	elif velocity.x < 0: animated_sprite.flip_h = false
	if velocity.length() > 0:
		if animated_sprite.animation != "walk": animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "default": animated_sprite.play("default")

func adjust_target_after_teleport(adjustment: Vector2):
	if _has_target: _target += adjustment

func is_in_interaction_range(object: Node) -> bool:
	return _interactable_objects_in_range.has(object)

func _on_interaction_area_area_entered(area: Area2D):
	if area.is_in_group("interactable"):
		if not _interactable_objects_in_range.has(area):
			_interactable_objects_in_range.append(area)
			print("Entered range of: ", area.name)

func _on_interaction_area_area_exited(area: Area2D):
	if _interactable_objects_in_range.has(area):
		_interactable_objects_in_range.erase(area)
		print("Left range of: ", area.name)
