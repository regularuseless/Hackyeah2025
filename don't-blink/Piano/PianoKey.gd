extends Area2D

signal key_played(note_name)

@export var note_name: String = ""
@export var note_sound: AudioStream

@onready var sprite = $Sprite2D
@onready var audio_player = $AudioStreamPlayer2D

# This flag will track if the key is currently being held down.
var _is_pressed = false

func _ready():
	if note_sound:
		audio_player.stream = note_sound

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				# If the mouse button is pressed DOWN and our key isn't already pressed.
		if event.is_pressed() and not _is_pressed:
			_is_pressed = true # Mark the key as pressed.
			play_note()
		
		# If the mouse button is RELEASED.
		elif event.is_released():
			_is_pressed = false # Reset the flag so it can be clicked again.

func play_note():
	audio_player.play()
	emit_signal("key_played", note_name)
	
	sprite.modulate = Color(1, 0.8, 0.8)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1)
