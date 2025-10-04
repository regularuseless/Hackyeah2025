extends Node2D

const CORRECT_SEQUENCE = ["D", "G", "C", "F"]
var player_sequence = []

# A dictionary to link note names to their pressed sprite nodes ---
var key_visuals = {}

func _ready():
	var pressed_sprites_container = $PressedKeySprites
	for sprite in pressed_sprites_container.get_children():
		# Extracts the note name (e.g., "C") from the node name ("Pressed_C")
		var note_name = sprite.name.split("_")[1]
		key_visuals[note_name] = sprite

	# Go through all the hotspot children (KeyC, KeyD, etc.)
	for key_node in get_children():
		# Check if it's a key and has the signals we need.
		if key_node.has_signal("note_played"):
			# Connect to the game logic signal
			key_node.note_played.connect(_on_note_played)
			
			key_node.key_pressed_visual.connect(_on_key_pressed_visual.bind(key_node.note_name))
			key_node.key_released_visual.connect(_on_key_released_visual.bind(key_node.note_name))

func _on_key_pressed_visual(note_name):
	if key_visuals.has(note_name):
		key_visuals[note_name].show()

func _on_key_released_visual(note_name):
	if key_visuals.has(note_name):
		key_visuals[note_name].hide()

func _on_note_played(note_name):
	player_sequence.append(note_name)
	print("Player input: ", player_sequence)

	var current_correct_part = CORRECT_SEQUENCE.slice(0, player_sequence.size())
	
	if player_sequence != current_correct_part:
		print("Wrong note! Sequence reset.")
		player_sequence.clear()
	elif player_sequence.size() == CORRECT_SEQUENCE.size():
		print("SUCCESS! You played the correct sequence!")
		player_sequence.clear()
