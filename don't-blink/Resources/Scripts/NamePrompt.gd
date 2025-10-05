extends Control

@onready var name_edit: LineEdit       = %LineEdit
@onready var ok_btn: Button            = %OkButton
@onready var back_btn: Button          = %BackButton
@onready var os_prompt: AcceptDialog   = %OSPrompt
@onready var os_label: Label           = %OsPromptLabel

var _typed_name: String = ""
var _os_name: String = ""

func _ready() -> void:
	ok_btn.pressed.connect(_confirm)
	back_btn.pressed.connect(_back)
	name_edit.text_submitted.connect(func(_t: String) -> void: _confirm())
	name_edit.grab_focus()

	# Configure the OS-name prompt
	os_prompt.get_ok_button().text = "Yes"
	os_prompt.confirmed.connect(_on_os_yes)
	# (If you want closing the dialog to start with typed name, uncomment below)
	# os_prompt.canceled.connect(func(): Game.start_new_game(_typed_name))

func _confirm() -> void:
	# 1) Cache what the player typed (fallback)
	_typed_name = name_edit.text.strip_edges()
	if _typed_name.is_empty():
		_typed_name = "Player"

	# 2) Try to read OS account name

	_os_name = _guess_os_username()

	# 3) If we have an OS name → prompt; otherwise start immediately with typed
	if _os_name.is_empty():
		Game.start_new_game(_typed_name)
		return
	if _os_name != _typed_name:
		os_label.text = "Isn't your name:  %s ?" % _os_name
		os_prompt.popup_centered()
	else:
		Game.start_new_game(_os_name)

func _on_os_yes() -> void:
	# Start game using the OS account name
	Game.start_new_game(_os_name)

func _back() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _guess_os_username() -> String:
	# Cross-platform try: Windows (USERNAME), Unix (USER/LOGNAME)
	var keys: PackedStringArray = ["USERNAME", "USER", "LOGNAME"]
	for k in keys:
		var v: String = OS.get_environment(k)
		if not v.is_empty():
			return v
	return ""
