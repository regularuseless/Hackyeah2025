extends Area2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var crying_sound = $CryingSound
@onready var jumpscare_sound = $JumpscareSound

var already_jumpscared = false
var player = null

func _ready():
	# Find the player node once when the scene loads.
	player = get_tree().get_first_node_in_group("player")
	
	# --- NEW: Connect the animation_finished signal ---
	# This tells the animated_sprite to call our new function _on_animation_finished()
	# every time any of its animations completes a cycle.
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Start in the default crying state.
	animated_sprite.play("crying")
	
func _input_event(_viewport, event, _shape_idx):
	# If a jumpscare is already in progress, or player isn't found, ignore clicks.
	if already_jumpscared or player == null:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Ask the player if we (self) are in its interaction range.
		if player.is_in_interaction_range(self):
			# --- TRIGGER THE JUMPSCARE ---
			already_jumpscared = true
			crying_sound.stop()
			animated_sprite.play("jumpscare") # This animation should NOT loop.
			jumpscare_sound.play()
			
			get_viewport().set_input_as_handled()
			print("Jumpscare triggered!")
		else:
			print("You are too far away.")


# --- NEW: This function is called automatically when an animation finishes ---
func _on_animation_finished():
	# We only want to run this code when the "jumpscare" animation is the one that finished.
	# This prevents it from running every time the looping "crying" animation finishes a cycle.
	if animated_sprite.animation == "jumpscare":
		print("Jumpscare finished. Returning to crying state.")		
		
		# 2. Play the default "crying" animation (which should be set to loop).
		animated_sprite.play("crying")
		
		# 3. Start the looping crying sound again.
		crying_sound.play()
