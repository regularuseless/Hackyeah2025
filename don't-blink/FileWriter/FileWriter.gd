# FileWriter.gd
extends Node

# This function is called when the node enters the scene tree for the first time.
func _ready():
	# We call our main function here to demonstrate it works as soon as you run the scene.
	write_note_to_documents()

# --- The Core Functionality ---

# This function writes a predefined text file to the user's Documents folder.
func write_note_to_documents():
	# 1. DEFINE THE FILENAME AND CONTENT
	const FILE_NAME = "a_note_from_the_game.txt"
	const FILE_CONTENT = """
Hello, Player!

If you are reading this, it means the file was created successfully.
This note could contain a clue, a piece of lore, or a reward.

Have a great day!
"""

	# 2. GET THE PATH TO THE USER'S DOCUMENTS FOLDER
	# This is the cross-platform way to find the right directory.
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	# 3. CONSTRUCT THE FULL, FINAL PATH FOR THE FILE
	# path_join correctly adds the "/" or "\" depending on the OS.
	var full_path = documents_path.path_join(FILE_NAME)
	
	# 4. OPEN THE FILE FOR WRITING
	# FileAccess.WRITE will create the file if it doesn't exist,
	# or overwrite it completely if it does.
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	
	# 5. CHECK FOR ERRORS AND WRITE THE FILE
	if file:
		# If the file was opened successfully (is not null)...
		file.store_string(FILE_CONTENT)
		# In Godot 4, the file is automatically closed when 'file' goes out of scope,
		# but file.close() can be called for clarity if you prefer.
		
		# Print a success message to the Godot output log.
		print("SUCCESS: File written to: " + full_path)
	else:
		# If 'file' is null, it means Godot failed to open/create it.
		# This is often due to a lack of permissions.
		printerr("ERROR: Failed to write file. Check permissions for path: " + full_path)
