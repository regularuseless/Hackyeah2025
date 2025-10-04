extends Control

@onready var resume_btn: Button     = %ResumeButton
@onready var quit_btn: Button       = %QuitButton

var _open: bool = false

func _ready() -> void:
	# Make this UI work even when the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	# Wire buttons
	resume_btn.pressed.connect(_resume)
	quit_btn.pressed.connect(_quit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Esc by default
		if _open:
			_resume()
		else:
			_show_menu()

func _show_menu() -> void:
	_open = true
	visible = true
	get_tree().paused = true
	resume_btn.grab_focus()

func _resume() -> void:
	_open = false
	visible = false
	get_tree().paused = false

func _quit() -> void:
	get_tree().quit()
