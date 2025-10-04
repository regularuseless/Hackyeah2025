# SettingsManager.gd
extends Node

## --- MODIFIED: Renamed signal for clarity ---
signal loop_mode_changed(is_enabled: bool)

var settings_path = ""

var last_modified_time = 0
# --- MODIFIED: Renamed state variable ---
var current_loop_state = true


func _ready():
	var documents_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	var folder_path = documents_path.path_join("forget me not")
	
	var err = DirAccess.make_dir_recursive_absolute(folder_path)
	if err != OK:
		printerr("CRITICAL ERROR: Could not create settings directory at: ", folder_path)
		set_process(false)
		return
		
	settings_path = folder_path.path_join("settings.json")
	
	if not FileAccess.file_exists(settings_path):
		create_default_settings_file()
	
	read_settings_file()
	
	last_modified_time = FileAccess.get_modified_time(settings_path)


func _process(_delta: float):
	if settings_path.is_empty():
		return
		
	var current_mod_time = FileAccess.get_modified_time(settings_path)
	
	if current_mod_time > last_modified_time:
		last_modified_time = current_mod_time
		print("Settings file has changed, reloading...")
		read_settings_file()


func create_default_settings_file():
	print("Creating default settings file at: ", settings_path)
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		# --- MODIFIED: Added decoy settings and changed "infinite" to "loop" ---
		var default_settings = {
			"graphics": {
				"resolution": "1920x1080",
				"fullscreen": true,
				"vsync": true,
				"shadow_quality": "high"
			},
			"audio": {
				"master_volume": 0.8,
				"music_volume": 0.6
			},
			"language": "en_US",
			"loop": true  # This is the actual setting we will read
		}
		
		var json_string = JSON.stringify(default_settings, "\t")
		file.store_string(json_string)


func read_settings_file():
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if not file:
		printerr("Failed to open settings file for reading.")
		return

	var content = file.get_as_text()
	var parsed_json = JSON.parse_string(content)
	
	if parsed_json:
		# --- MODIFIED: Now reading the "loop" key instead of "infinite" ---
		var new_state = parsed_json.get("loop", true)
		
		if new_state != current_loop_state:
			current_loop_state = new_state
			print("Loop mode set to: ", current_loop_state)
			# --- MODIFIED: Emitting the renamed signal ---
			emit_signal("loop_mode_changed", current_loop_state)
	else:
		printerr("Failed to parse settings.json. Check for syntax errors.")
