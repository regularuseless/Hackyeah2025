extends Control

@onready var start_btn: Button   = %StartButton
@onready var options_btn: Button = %OptionsButton
@onready var quit_btn: Button    = %QuitButton
#@onready var options_popup: AcceptDialog = %OptionsDialog

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	#options_btn.pressed.connect(_on_options_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/NamePrompt.tscn")

#func _on_options_pressed() -> void:
	#options_popup.popup_centered()

func _on_quit_pressed() -> void:
	get_tree().quit()
