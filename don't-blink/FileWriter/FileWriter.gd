extends Node

const INITIAL_FILE_NAME = "a_note_from_the_game.txt"
const INITIAL_FILE_CONTENT = """
Hello, Player!

If you are reading this, it means the file was created successfully.
Perhaps you should try renaming this file? I'm waiting for a file named: the_magic_word.txt

This note could contain a clue, a piece of lore, or a reward.

Have a great day!
"""

const EXPECTED_FILE_NAME = "the_magic_word.txt"

var _rename_puzzle_solved = false

var _original_file_path = ""
var _expected_file_path = ""


func _ready():
	write_note_to_documents()


func _process(_delta):
	if _rename_puzzle_solved or _original_file_path == "":
		return
		
	if not FileAccess.file_exists(_original_file_path) and FileAccess.file_exists(_expected_file_path):
		print("SUCCESS: File rename puzzle has been solved!")
		_rename_puzzle_solved = true


func write_note_to_documents():
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	var folder_path = documents_path.path_join("forget me not")
	
	var err = DirAccess.make_dir_recursive_absolute(folder_path)
	if err != OK:
		printerr("CRITICAL ERROR: Could not create puzzle directory at: ", folder_path)
		return # Stop if we can't create the folder.
		
	_original_file_path = folder_path.path_join(INITIAL_FILE_NAME)
	_expected_file_path = folder_path.path_join(EXPECTED_FILE_NAME)
		
	var file = FileAccess.open(_original_file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(INITIAL_FILE_CONTENT)
		print("SUCCESS: Initial puzzle file written to: " + _original_file_path)
	else:
		printerr("ERROR: Failed to write initial file. Check permissions for path: " + _original_file_path)
