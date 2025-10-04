# Piano.gd
extends Node2D

# The correct sequence of notes the player needs to input.
# You can change this to any sequence you want using the note names.
const CORRECT_SEQUENCE = ["C", "E", "G", "H"]

# An array to store the notes the player has pressed so far.
var player_sequence = []

func _ready():
	# This loop goes through all the children of the Piano node.
	for key in get_children():
		# Check if the child is actually a PianoKey.
		if key is Area2D:
			# Connect the 'key_played' signal from each key to our new function.
			# When any key emits the signal, it will call the '_on_key_played' function.
			key.key_played.connect(_on_key_played)

# This function is called whenever any connected key is played.
# It receives the note_name that the key sent with its signal.
func _on_key_played(note_name):
	# Add the played note to the player's current sequence.
	player_sequence.append(note_name)
	print("Player input: ", player_sequence)

	# Check if the player's input so far matches the beginning of the correct sequence.
	var current_correct_part = CORRECT_SEQUENCE.slice(0, player_sequence.size())
	
	if player_sequence != current_correct_part:
		# If the player makes a mistake, reset their progress.
		print("Wrong note! Sequence reset.")
		player_sequence.clear()
	elif player_sequence.size() == CORRECT_SEQUENCE.size():
		# If the player's sequence matches the correct sequence perfectly...
		print("SUCCESS! You played the correct sequence!")
		# Reset for the next attempt.
		player_sequence.clear()
