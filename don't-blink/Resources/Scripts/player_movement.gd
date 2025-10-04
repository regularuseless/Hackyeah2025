extends CharacterBody2D

@export var max_speed := 200.0
@export var acceleration := 1200.0
@export var friction := 1200.0
var _last_dir := "down"

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left","move_right","move_up","move_down")
	var target_vel := input_dir * max_speed

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(target_vel, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
	_update_anim(input_dir)

func _update_anim(input_dir: Vector2) -> void:
	if not has_node("AnimatedSprite2D"):
		return
	var anim := $"AnimatedSprite2D"
	if input_dir == Vector2.ZERO:
		anim.play("idle_" + _last_dir)
		return

	var dir := "down"
	if abs(input_dir.x) > abs(input_dir.y):
		dir = "right" if input_dir.x > 0 else "left"
	else:
		dir = "down" if input_dir.y > 0 else "up"

	_last_dir = dir
	anim.play("walk_" + dir)
