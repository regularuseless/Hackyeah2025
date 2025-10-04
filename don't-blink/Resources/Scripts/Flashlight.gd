extends Node2D

func _draw():
	# Draw the black rectangle
	draw_rect(Rect2(Vector2.ZERO, Vector2(400, 300)), Color.BLACK)
	
	# Draw a transparent circle using BLEND_MODE_SUB
	draw_circle(Vector2(200, 150), 50, Color(0, 0, 0, 1), true) 
	# Actually we need to make a mask instead
