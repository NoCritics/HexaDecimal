extends Panel

var grid_radius: int = 2
var hex_size: float = 70.0
var grid_color: Color = Color(0, 0.698039, 0.878431, 0.15)

func _ready():
	queue_redraw()

func _draw():
	for q in range(-grid_radius-1, grid_radius + 1):
		for r in range(-grid_radius-1, grid_radius + 1):
			var s = -q - r
			if abs(s) <= grid_radius and abs(q) <= grid_radius and abs(r) <= grid_radius:
				var coord = Vector2i(q, r)
				var pixel_pos = axial_to_pixel(coord)
				draw_hex_outline(pixel_pos, hex_size)

func axial_to_pixel(hex_coord: Vector2i) -> Vector2:
	var x = hex_size * (3.0/2.0 * hex_coord.x)
	var y = hex_size * (sqrt(3)/2.0 * hex_coord.x + sqrt(3) * hex_coord.y)
	return Vector2(x, y) + Vector2(self.size.x / 2, self.size.y / 2)

func draw_hex_outline(center: Vector2, size: float):
	var points = []
	
	for i in range(6):
		var angle = i * TAU / 6 + PI/2
		points.append(center + Vector2(cos(angle), sin(angle)) * size)
	
	for i in range(6):
		draw_line(points[i], points[(i + 1) % 6], grid_color, 2.0, true)
		
	draw_polyline(points + [points[0]], grid_color.lightened(0.2), 1.0, true)