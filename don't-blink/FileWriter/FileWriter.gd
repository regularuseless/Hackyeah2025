extends Node

const INITIAL_FILE_NAME = "a_note_from_the_game.txt"
const INITIAL_FILE_CONTENT = """
Hello, Player!

If you are reading this, it means the file was created successfully.
Perhaps you should try renaming this file? I'm waiting for a file named: the_magic_word.txt

This note could contain a clue, a piece of lore, or a reward.

Have a great day!
"""

# The filename we expect the user to rename the file to.
const EXPECTED_FILE_NAME = "the_magic_word.txt"

# A flag to make sure our success message only prints once.
var _rename_puzzle_solved = false

# A variable to store the full path of the file we create.
var _original_file_path = ""
var _expected_file_path = ""


func _ready():
	write_note_to_documents()


func _process(_delta):
	if _rename_puzzle_solved or _original_file_path == "":
		return
		
	# Check for the winning condition:
	# 1. Does the original file NOT exist anymore?
	# 2. AND does the new, expected file NOW exist?
	if not FileAccess.file_exists(_original_file_path) and FileAccess.file_exists(_expected_file_path):
		
		# If both are true, the player has solved the puzzle!
		print("SUCCESS: File rename puzzle has been solved!")
		
		# Set the flag to true to stop this check from running again.
		_rename_puzzle_solved = true

func write_note_to_documents():
	# Get the path to the user's Documents folder.
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	# Construct the full paths for both the initial file and the expected file.
	_original_file_path = documents_path.path_join(INITIAL_FILE_NAME)
	_expected_file_path = documents_path.path_join(EXPECTED_FILE_NAME)
	
	# Open the file for writing.
	var file = FileAccess.open(_original_file_path, FileAccess.WRITE)
	
	if file:
		# If the file was opened successfully, write the content.
		file.store_string(INITIAL_FILE_CONTENT)
		print("SUCCESS: Initial puzzle file written to: " + _original_file_path)
	else:
		# If it failed, print an error.
		printerr("ERROR: Failed to write initial file. Check permissions for path: " + _original_file_path)
