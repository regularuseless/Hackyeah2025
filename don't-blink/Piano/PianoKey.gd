# PianoKey.gd
extends Area2D

signal key_played(note_name)

@export var note_name: String = ""

@export var note_sound: AudioStream

@onready var sprite = $Sprite2D
@onready var audio_player = $AudioStreamPlayer2D

func _ready():
	if note_sound:
		audio_player.stream = note_sound

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		play_note()

func play_note():
	audio_player.play()
	
	# --- NEW ---
	# Emit the signal, sending this key's note_name with it.
	emit_signal("key_played", note_name)
	
	sprite.modulate = Color(1, 0.8, 0.8)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1)
