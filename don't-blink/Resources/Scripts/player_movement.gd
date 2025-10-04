# Player.gd
extends CharacterBody2D


@export var walk_speed := 160.0
@export var sprint_multiplier := 1.8
@export var stop_radius := 2.0  # odległość, przy której uznajemy, że doszliśmy

# --- Stamina ---
@export var stamina_max := 100.0
@export var stamina_drain := 30.0      # ile staminy/sek. spala sprint
@export var stamina_regen := 20.0      # ile staminy/sek. wraca, gdy NIE sprintujemy
@export var stamina_regen_delay := 0.5 # po ilu sekundach od sprintu zaczyna się regen
# Stamina 

var stamina := 100.0
var _time_since_sprint := 9999.0

var _has_target := false
var _target := Vector2.ZERO

func _ready() -> void:
	stamina = stamina_max

func _unhandled_input(event: InputEvent) -> void:
	# LPM: ustaw nowy cel marszu
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
			# Sprint tylko gdy trzymasz "sprint" i masz staminy > 0
			if Input.is_action_pressed("sprint") and stamina > 0.1:
				sprinting = true
				speed *= sprint_multiplier
				stamina = max(0.0, stamina - stamina_drain * delta)
				_time_since_sprint = 0.0

			velocity = dir * speed
			move_and_slide()
	else:
		velocity = Vector2.ZERO

	# Regen staminy z opóźnieniem po sprintowaniu
	if sprinting:
		_time_since_sprint = 0.0
	else:
		_time_since_sprint += delta
		if _time_since_sprint >= stamina_regen_delay:
			stamina = min(stamina_max, stamina + stamina_regen * delta)
