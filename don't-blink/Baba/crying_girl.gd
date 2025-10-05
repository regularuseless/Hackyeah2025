extends Area2D

@onready var animated_sprite = $AnimatedSprite2D

var _jumpscare_triggered = false
var player = null

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _input_event(_viewport, event, _shape_idx):
	# Do nothing if the jumpscare already happened or if the player isn't found.
	if _jumpscare_triggered or player == null:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Ask the player if we (self) are in its interaction range.
		if player.is_in_interaction_range(self):
			# If yes, trigger the jumpscare and handle the input.
			_jumpscare_triggered = true
			animated_sprite.play("jumpscare")
			get_viewport().set_input_as_handled()
			print("Jumpscare triggered!")
		else:
			# If no, do nothing. The click will "fall through" and the player will walk.
			print("You are too far away.")
