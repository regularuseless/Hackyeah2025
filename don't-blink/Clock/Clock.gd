# Clock.gd
extends Control

# Set the target time for the puzzle.
# This is in 24-hour format. For example, 3:30 PM is 15:30.
const TARGET_HOUR = 00
const TARGET_MINUTE = 05

# A flag to make sure our success message only prints once.
var _puzzle_solved = false

# Get a reference to our Label node so we can update its text.
@onready var time_label = $Label

func _process(_delta):
	# This fetches the time directly from the user's computer.
	var now = Time.get_datetime_dict_from_system()
	
	# We use "%02d" to format the numbers. This ensures a leading zero
	# is added if the number is less than 10 (e.g., 9 becomes "09").
	var time_string = "%02d:%02d" % [now.hour, now.minute]
	
	# Set the label's text to our newly formatted string.
	time_label.text = time_string
	
	# Check if the time matches our target AND if the puzzle hasn't been solved yet.
	if now.hour == TARGET_HOUR and now.minute == TARGET_MINUTE and not _puzzle_solved:
		# If it matches, print the success message.
		print("CLOCK PUZZLE SOLVED!")
		
		# Set the flag to true so this code doesn't run again.
		_puzzle_solved = true
