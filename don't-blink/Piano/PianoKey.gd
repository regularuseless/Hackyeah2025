extends Area2D

signal note_played(note_name)
signal key_pressed_visual()
signal key_released_visual()

@export var note_name: String = ""
@export var note_sound: AudioStream

@onready var audio_player = $AudioStreamPlayer2D

var _is_pressed = false

func _ready():
	if note_sound:
		audio_player.stream = note_sound

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed() and not _is_pressed:
			_is_pressed = true
			# Play the sound and tell the game logic which note was played.
			audio_player.play()
			emit_signal("note_played", note_name)
			# Tell the main piano to show the visual for this key.
			emit_signal("key_pressed_visual")
		
		elif event.is_released() and _is_pressed:
			_is_pressed = false
			# Tell the main piano to hide the visual.
			emit_signal("key_released_visual")

func _on_mouse_exited():
	if _is_pressed:
		_is_pressed = false
		emit_signal("key_released_visual")
