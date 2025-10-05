extends CanvasLayer

signal blink_happened

@export var auto_blink_delay: float = 5.0
@export var blink_speed: float = 10.0
@export var auto_blink_hold: float = 0.5
@export var manual_blink_hold: float = 0.05
@export var manual_blink_cooldown: float = 1.0

@export_group("Visuals")
@export var open_scale: float = 1.5
@export var blur_size: float = 0.05

enum State { IDLE, CLOSING, HOLDING, OPENING }
var _current_state = State.IDLE
var _blink_progress: float = 0.0
var _hold_timer: float = 0.0
var _on_cooldown: bool = false

@onready var overlay_material = $Overlay.material
@onready var auto_blink_timer = $AutoBlinkTimer
@onready var cooldown_timer = $CooldownTimer


func _ready():
	overlay_material.set_shader_parameter("open_scale", open_scale)
	overlay_material.set_shader_parameter("blur_size", blur_size)
	
	_start_auto_blink_timer()
	cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)


func _input(event: InputEvent):
	if event.is_action_pressed("blink_manual") and _current_state == State.IDLE and not _on_cooldown:
		_trigger_blink(manual_blink_hold, true)

func _process(delta: float):
	match _current_state:
		State.CLOSING:
			_blink_progress = move_toward(_blink_progress, 1.0, blink_speed * delta)
			if _blink_progress >= 1.0:
				emit_signal("blink_happened")
				_current_state = State.HOLDING
		State.HOLDING:
			_hold_timer -= delta
			if _hold_timer <= 0:
				_current_state = State.OPENING
		State.OPENING:
			_blink_progress = move_toward(_blink_progress, 0.0, blink_speed * delta)
			if _blink_progress <= 0.0:
				_current_state = State.IDLE
				if not _on_cooldown:
					_start_auto_blink_timer()

	overlay_material.set_shader_parameter("blink_progress", _blink_progress)

func _trigger_blink(hold_duration: float, is_manual: bool = false):
	if _current_state != State.IDLE:
		return
		
	_current_state = State.CLOSING
	_hold_timer = hold_duration
	auto_blink_timer.stop()
	
	if is_manual:
		_on_cooldown = true
		cooldown_timer.start(manual_blink_cooldown)

func _start_auto_blink_timer():
	auto_blink_timer.wait_time = auto_blink_delay
	auto_blink_timer.start()

func _on_auto_blink_timer_timeout():
	_trigger_blink(auto_blink_hold)

func _on_cooldown_timer_timeout():
	_on_cooldown = false
	if _current_state == State.IDLE:
		_start_auto_blink_timer()
