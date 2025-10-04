extends Control

@onready var name_edit: LineEdit = %LineEdit
@onready var ok_btn: Button      = %OkButton
@onready var back_btn: Button    = %BackButton

func _ready() -> void:
	ok_btn.pressed.connect(_confirm)
	back_btn.pressed.connect(_back)
	name_edit.text_submitted.connect(func(_t: String) -> void: _confirm())
	name_edit.grab_focus()

func _confirm() -> void:
	Game.start_new_game(name_edit.text)

func _back() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
