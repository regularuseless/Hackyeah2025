extends Polygon2D

func _ready():
	var points = []
	var segments = 64
	var radius = 300
	for i in range(segments):
		var angle = i * TAU / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	polygon = points
	color = Color(1, 1, 1, 0) # fully transparent
