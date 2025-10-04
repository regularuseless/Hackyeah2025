extends ColorRect

@export var circle_node: Node2D
@export var radius := 100.0

func _process(delta):
	if circle_node:
		# Convert global position to ColorRect local coordinates
		var local_pos = circle_node.global_position - global_position
		material.set_shader_parameter("circle_position", local_pos)
		material.set_shader_parameter("radius", radius)
