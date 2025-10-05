extends CharacterBody2D

@export var walk_speed := 160.0
@export var sprint_multiplier := 1.8
@export var stop_radius := 2.0

# --- Stamina ---
@export var stamina_max := 100.0
@export var stamina_drain := 30.0
@export var stamina_regen := 20.0
@export var stamina_regen_delay := 0.5

var stamina := 100.0
var _time_since_sprint := 9999.0

var _has_target := false
var _target := Vector2.ZERO

@onready var animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	stamina = stamina_max

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_target = get_global_mouse_position()
		_has_target = true

func _physics_process(delta: float) -> void:
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

	if sprinting:
		_time_since_sprint = 0.0
	else:
		_time_since_sprint += delta
		if _time_since_sprint >= stamina_regen_delay:
			stamina = min(stamina_max, stamina + stamina_regen * delta)

	_update_animation()

func _update_animation():
	if velocity.x > 0:
		# The player is moving right, so we flip the sprite horizontally.
		animated_sprite.flip_h = true
	elif velocity.x < 0:
		# The player is moving left, so we un-flip it to its default (left-facing) state.
		animated_sprite.flip_h = false

	# --- Animation State ---
	# Check if the player is currently moving.
	if velocity.length() > 0:
		# If we're moving, play the "walk" animation.
		# We check if the animation is not already "walk" to prevent restarting it every frame.
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		# If we're not moving (velocity is zero), play the "default" (idle) animation.
		if animated_sprite.animation != "default":
			animated_sprite.play("default")

func adjust_target_after_teleport(adjustment: Vector2):
	if _has_target:
		_target += adjustment
