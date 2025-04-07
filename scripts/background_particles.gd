extends Node2D

var particles = []
const MAX_PARTICLES = 40
var screen_size = Vector2(1280, 720)

var particle_colors = [
	Color(0, 0.8, 1, 0.8),
	Color(0, 0.6, 1, 0.8),
	Color(0.5, 0, 1, 0.8),
	Color(0.9, 0, 0.9, 0.8)
]

var connection_distance = 150.0
var max_connections_per_particle = 3

func _ready():
	randomize()
	for i in range(MAX_PARTICLES):
		create_particle()

func _process(delta):
	for particle in particles:
		particle.position += particle.velocity * delta
		
		if particle.position.x < 0:
			particle.position.x = screen_size.x
		elif particle.position.x > screen_size.x:
			particle.position.x = 0
			
		if particle.position.y < 0:
			particle.position.y = screen_size.y
		elif particle.position.y > screen_size.y:
			particle.position.y = 0
	
	queue_redraw()

func create_particle():
	var particle = {
		"position": Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y)),
		"velocity": Vector2(randf_range(-20, 20), randf_range(-20, 20)),
		"size": randf_range(1, 3),
		"color": particle_colors[randi() % particle_colors.size()]
	}
	particles.append(particle)
	return particle

func _draw():
	draw_connections()
	
	for particle in particles:
		draw_circle(particle.position, particle.size, particle.color)

func draw_connections():
	for i in range(particles.size()):
		var connections = 0
		var particle = particles[i]
		
		for j in range(i + 1, particles.size()):
			if connections >= max_connections_per_particle:
				break
				
			var other = particles[j]
			var distance = particle.position.distance_to(other.position)
			
			if distance < connection_distance:
				var alpha = 1.0 - (distance / connection_distance)
				var line_color = particle.color
				line_color.a = alpha * 0.3
				
				draw_line(particle.position, other.position, line_color, 1.0)
				connections += 1

func set_screen_dimensions(width, height):
	screen_size = Vector2(width, height)
	for particle in particles:
		if particle.position.x > width:
			particle.position.x = randf_range(0, width)
		if particle.position.y > height:
			particle.position.y = randf_range(0, height)