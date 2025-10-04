# Clock.gd
extends Control

# --- PUZZLE SETUP ---
# Set the target time for the puzzle.
# This is in 24-hour format. For example, 3:30 PM is 15:30.
const TARGET_HOUR = 15
const TARGET_MINUTE = 00

# A flag to make sure our success message only prints once.
var _puzzle_solved = false

# Get a reference to our Label node so we can update its text.
@onready var time_label = $Label

# The _process function runs on every single frame.
func _process(_delta):
	# 1. GET THE CURRENT SYSTEM TIME
	# This fetches the time directly from the user's computer.
	var now = Time.get_datetime_dict_from_system()
	
	# 2. FORMAT THE TIME STRING
	# We use "%02d" to format the numbers. This ensures a leading zero
	# is added if the number is less than 10 (e.g., 9 becomes "09").
	var time_string = "%02d:%02d:%02d" % [now.hour, now.minute, now.second]
	
	# 3. UPDATE THE DISPLAY
	# Set the label's text to our newly formatted string.
	time_label.text = time_string
	
	# 4. CHECK FOR PUZZLE SUCCESS
	# Check if the time matches our target AND if the puzzle hasn't been solved yet.
	if now.hour == TARGET_HOUR and now.minute == TARGET_MINUTE and not _puzzle_solved:
		# If it matches, print the success message.
		print("CLOCK PUZZLE SOLVED!")
		
		# Set the flag to true so this code doesn't run again.
		_puzzle_solved = true
