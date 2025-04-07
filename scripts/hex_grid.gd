class_name HexGrid
extends Node2D

var hex_size: float = 70.0
var grid_radius: int = 2
var show_radius: int = 2
var grid: Dictionary = {}

var directions = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1)
]

var hex_tile_scene: PackedScene

var is_animating: bool = false
var active_tweens: int = 0

signal tiles_merged(position, value)
signal game_over
signal game_won

func _ready():
	hex_tile_scene = load("res://scenes/hex_tile.tscn")
	
	for child in get_children():
		if child is HexTile:
			remove_child(child)
			child.queue_free()
			
	initialize_grid()
	spawn_initial_tiles()

func axial_to_pixel(hex_coord: Vector2i) -> Vector2:
	var x = hex_size * (3.0/2.0 * hex_coord.x)
	var y = hex_size * (sqrt(3)/2.0 * hex_coord.x + sqrt(3) * hex_coord.y)
	return Vector2(x, y)

func pixel_to_axial(pixel_coord: Vector2) -> Vector2i:
	var q = (2.0/3.0 * pixel_coord.x) / hex_size
	var r = (-1.0/3.0 * pixel_coord.x + sqrt(3)/3.0 * pixel_coord.y) / hex_size
	return hex_round(Vector2(q, r))

func hex_round(hex: Vector2) -> Vector2i:
	var s = -hex.x - hex.y
	var q = round(hex.x)
	var r = round(hex.y)
	var s_round = round(s)
	
	var q_diff = abs(q - hex.x)
	var r_diff = abs(r - hex.y)
	var s_diff = abs(s_round - s)
	
	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s_round
	elif r_diff > s_diff:
		r = -q - s_round
	
	return Vector2i(int(q), int(r))

func is_within_grid(coord: Vector2i) -> bool:
	var s = -coord.x - coord.y
	return abs(coord.x) <= grid_radius and abs(coord.y) <= grid_radius and abs(s) <= grid_radius

func initialize_grid():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	grid.clear()
	
	for q in range(-show_radius, show_radius + 1):
		for r in range(-show_radius, show_radius + 1):
			var s = -q - r
			if abs(s) <= show_radius:
				var coord = Vector2i(q, r)
				var pixel_pos = axial_to_pixel(coord)
				grid[coord] = null
				
				print("Created grid cell at: ", coord)

func create_tile_at(coord: Vector2i, value: int = 0) -> HexTile:
	if !is_gameplay_position(coord):
		return null
	
	if grid[coord] != null:
		print("WARNING: Attempted to create tile at occupied position: ", coord)
		if is_instance_valid(grid[coord]):
			grid[coord].queue_free()
		else:
			grid[coord] = null
	
	var tile = hex_tile_scene.instantiate()
	tile.position = axial_to_pixel(coord)
	tile.coordinates = coord
	
	if value == 0:
		tile.value = 3 if randf() < 0.7 else 6
	else:
		tile.value = value
	
	add_child(tile)
	grid[coord] = tile
	
	return tile

func is_gameplay_position(coord: Vector2i) -> bool:
	var gameplay_radius = 2
	var s = -coord.x - coord.y
	return abs(coord.x) <= gameplay_radius and abs(coord.y) <= gameplay_radius and abs(s) <= gameplay_radius

func spawn_initial_tiles():
	for i in range(2):
		spawn_random_tile()

func spawn_random_tile():
	validate_grid_state()
	
	var empty_cells = []
	for coord in grid:
		if grid[coord] == null and is_gameplay_position(coord):
			empty_cells.append(coord)
	
	if empty_cells.size() > 0:
		var rand_index = randi() % empty_cells.size()
		var rand_cell = empty_cells[rand_index]
		var new_tile = create_tile_at(rand_cell)
		if new_tile:
			print("Spawned new tile at ", rand_cell, " with value ", new_tile.value)
	else:
		check_game_over()

func increment_tween_count():
	active_tweens += 1

func decrement_tween_count():
	active_tweens -= 1
	if active_tweens <= 0:
		active_tweens = 0
		if is_animating:
			await get_tree().create_timer(0.03).timeout
			spawn_random_tile()
			await get_tree().create_timer(0.02).timeout
			is_animating = false

func move_tiles(direction_index: int) -> bool:
	var direction = directions[direction_index]
	
	var moved = false
	var merged_positions = []
	active_tweens = 0
	
	is_animating = true
	
	var grid_copy = grid.duplicate(true)
	
	var sorted_coords = grid.keys().duplicate()
	
	sorted_coords.sort_custom(func(a, b):
		var a_s = -a.x - a.y
		var b_s = -b.x - b.y
		
		var a_cubic = Vector3(a.x, a.y, a_s)
		var b_cubic = Vector3(b.x, b.y, b_s)
		
		var dir_s = -direction.x - direction.y
		var dir_cubic = Vector3(direction.x, direction.y, dir_s)
		
		var a_proj = a_cubic.x * dir_cubic.x + a_cubic.y * dir_cubic.y + a_cubic.z * dir_cubic.z
		var b_proj = b_cubic.x * dir_cubic.x + b_cubic.y * dir_cubic.y + b_cubic.z * dir_cubic.z
		
		if direction_index == 2:
			return a_cubic.z > b_cubic.z
		elif dir_cubic.x < 0 or dir_cubic.y < 0 or dir_cubic.z < 0:
			return a_proj < b_proj
		else:
			return a_proj > b_proj
	)
		
	for coord in sorted_coords:
		if grid[coord] == null:
			continue
		
		var start_coord = coord
		var current_coord = coord
		var next_coord = current_coord + direction
		var max_steps = 10
		var steps = 0
		
		var found_furthest = false
		while !found_furthest and is_within_grid(next_coord) and is_gameplay_position(next_coord) and steps < max_steps:
			steps += 1
			
			if grid[next_coord] == null:
				current_coord = next_coord
				next_coord = current_coord + direction
			elif grid[next_coord].value == grid[start_coord].value and !merged_positions.has(next_coord):
				current_coord = next_coord
				found_furthest = true
			else:
				found_furthest = true
		
		if current_coord != start_coord:
			moved = true
			
			if grid[current_coord] != null:
				merged_positions.append(current_coord)
				
				if !is_instance_valid(grid[start_coord]) or !is_instance_valid(grid[current_coord]):
					print("WARNING: Invalid tile during merge from ", start_coord, " to ", current_coord)
					if !is_instance_valid(grid[start_coord]):
						grid[start_coord] = null
					if !is_instance_valid(grid[current_coord]):
						grid[current_coord] = null
					continue
				
				var merged_value = grid[start_coord].value + grid[current_coord].value
				var start_tile = grid[start_coord]
				var target_tile = grid[current_coord]
				
				if start_tile.coordinates != start_coord or target_tile.coordinates != current_coord:
					print("WARNING: Tile coordinate mismatch during merge")
					start_tile.coordinates = start_coord
					target_tile.coordinates = current_coord
				
				start_tile.set_moving(true)
				
				var end_pos = axial_to_pixel(current_coord)
				
				target_tile.prepare_for_merge()
				
				increment_tween_count()
				
				var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
				tween.tween_property(start_tile, "position", end_pos, 0.18)
				
				tween.tween_callback(func():
					if !is_instance_valid(start_tile) or !is_instance_valid(target_tile):
						decrement_tween_count()
						return
						
					grid[start_coord] = null
					grid[current_coord] = null
					
					start_tile.label.z_index = -1
					target_tile.label.z_index = -1
					
					start_tile.queue_free()
					target_tile.queue_free()
					
					var new_tile = create_tile_at(current_coord, merged_value)
					if new_tile:
						new_tile.set_moving(false)
						new_tile.label.z_index = 5
						emit_signal("tiles_merged", current_coord, merged_value)
						
						if merged_value >= 3072:
							emit_signal("game_won")
					
					decrement_tween_count()
				)
			else:
				var tile = grid[start_coord]
				
				if !is_instance_valid(tile) or tile.coordinates != start_coord:
					print("WARNING: Invalid tile during movement at ", start_coord)
					grid[start_coord] = null
					continue
				
				if grid[current_coord] != null:
					print("WARNING: Destination no longer empty. Skipping move.")
					continue
				
				var safe_tile = tile
				
				grid[current_coord] = safe_tile
				grid[start_coord] = null
				safe_tile.coordinates = current_coord
				
				safe_tile.set_moving(true)
				
				increment_tween_count()
				
				var end_pos = axial_to_pixel(current_coord)
				var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
				tween.tween_property(safe_tile, "position", end_pos, 0.18)
				tween.tween_callback(func(): 
					if is_instance_valid(safe_tile):
						safe_tile.set_moving(false)
					decrement_tween_count()
				)
	
	if !moved:
		is_animating = false
	else:
		call_deferred("validate_grid_state")
	
	return moved

func check_game_over():
	for i in range(directions.size()):
		var test_grid = grid.duplicate()
		if can_move(i, test_grid):
			return false
	
	emit_signal("game_over")
	return true

func can_move(direction_index: int, test_grid: Dictionary) -> bool:
	var direction = directions[direction_index]
	
	for coord in test_grid.keys():
		if test_grid[coord] == null or !is_gameplay_position(coord):
			continue
		
		var next_coord = coord + direction
		if is_within_grid(next_coord) and is_gameplay_position(next_coord):
			if test_grid[next_coord] == null or test_grid[next_coord].value == test_grid[coord].value:
				return true
	
	return false

func validate_grid_state():
	var visual_tiles = get_children()
	var tile_count = 0
	
	for child in visual_tiles:
		if child is HexTile:
			tile_count += 1
			var coord = child.coordinates
			
			if !grid.has(coord) or grid[coord] != child:
				print("WARNING: Visual tile mismatch detected at ", coord)
				
				grid[coord] = child
	
	var grid_tile_count = 0
	for coord in grid:
		if grid[coord] != null:
			grid_tile_count += 1
			
			if !is_instance_valid(grid[coord]):
				print("WARNING: Found phantom block in grid at ", coord)
				grid[coord] = null
	
	if tile_count != grid_tile_count:
		print("WARNING: Tile count mismatch: visual tiles=", tile_count, " grid tiles=", grid_tile_count)
		
		print("Detailed grid state:")
		for coord in grid.keys():
			if grid[coord] != null:
				if is_instance_valid(grid[coord]):
					print("  Position ", coord, ": Valid tile with value ", grid[coord].value)
				else:
					print("  Position ", coord, ": Invalid tile reference")
					grid[coord] = null

func create_debug_visual(coord: Vector2i, color: Color = Color.RED):
	var debug_node = Node2D.new()
	var debug_shape = Polygon2D.new()
	
	var hex_points = []
	for i in range(6):
		var angle = i * TAU / 6 + PI/2
		hex_points.append(Vector2(cos(angle), sin(angle)) * (hex_size * 0.3))
	
	debug_shape.polygon = hex_points
	debug_shape.color = color
	
	debug_node.position = axial_to_pixel(coord)
	debug_node.add_child(debug_shape)
	add_child(debug_node)
	
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(debug_node):
		debug_node.queue_free()

var last_input_time: float = 0
var input_cooldown: float = 0.15

func handle_input(input_direction: int) -> bool:
	if is_animating:
		return false
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_input_time < input_cooldown:
		return false
	
	last_input_time = current_time
	return move_tiles(input_direction)