class_name HexTile
extends Node2D

var value: int = 3
var coordinates: Vector2i = Vector2i.ZERO

var colors = {
	3: Color("#00ccff"),
	6: Color("#0088ff"),
	12: Color("#0044ff"),
	24: Color("#8800ff"),
	48: Color("#dd00ff"),
	96: Color("#ff00aa"),
	192: Color("#ff008e"),
	384: Color("#ff00aa"),
	768: Color("#cc00ff"),
	1536: Color("#5500ff"),
	3072: Color("#0088ff")
}

var glow_strength = {
	3: 0.3,
	6: 0.4,
	12: 0.5,
	24: 0.6,
	48: 0.7,
	96: 0.8,
	192: 0.9,
	384: 1.0,
	768: 1.1,
	1536: 1.3,
	3072: 1.7
}

var hex_size: float = 60.0
var label: Label
var polygon: Polygon2D
var glow: Polygon2D
var hex_outline: Polygon2D
var border: Line2D
var is_moving: bool = false
var active_pulse_tween = null

func _ready():
	setup_visuals()
	update_appearance()

func _exit_tree():
	if active_pulse_tween != null and active_pulse_tween.is_valid():
		active_pulse_tween.kill()
	active_pulse_tween = null

func setup_visuals():
	polygon = Polygon2D.new()
	add_child(polygon)
	
	glow = Polygon2D.new()
	glow.z_index = -1
	add_child(glow)
	
	hex_outline = Polygon2D.new()
	hex_outline.color = Color(0, 0, 0, 0)
	hex_outline.z_index = 1
	add_child(hex_outline)
	
	border = Line2D.new()
	border.width = 3.0
	border.default_color = Color(1, 1, 1, 0.8)
	border.z_index = 2
	border.joint_mode = Line2D.LINE_JOINT_ROUND
	border.antialiased = true
	add_child(border)
	
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var system_font = SystemFont.new()
	system_font.font_names = ["Arial", "Helvetica", "Sans-Serif"]
	system_font.font_weight = 700
	
	label.add_theme_font_override("font", system_font)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0.2, 0.4, 1))
	label.add_theme_constant_override("outline_size", 4)
	
	label.position = Vector2(-50, -25)
	label.size = Vector2(100, 50)
	label.z_index = 5
	
	label.clip_text = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	add_child(label)
	
	var hex_points = []
	for i in range(6):
		var angle = i * TAU / 6 + PI/2
		hex_points.append(Vector2(cos(angle), sin(angle)) * hex_size)
	
	polygon.polygon = hex_points
	glow.polygon = hex_points
	
	for i in range(6):
		border.add_point(hex_points[i])
	border.add_point(hex_points[0])
	
	var border_material = CanvasItemMaterial.new()
	border_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	border.material = border_material

func update_appearance():
	label.text = ""
	label.text = str(value)
	
	label.clip_text = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	var system_font = SystemFont.new()
	system_font.font_names = ["Arial", "Helvetica", "Sans-Serif"]
	system_font.font_weight = 700
	label.add_theme_font_override("font", system_font)
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	
	label.show()
	
	var tile_color = colors.get(value, Color("#333333"))
	polygon.color = tile_color
	
	var glow_color = tile_color
	glow_color.a = 0.3
	glow.color = glow_color
	glow.scale = Vector2(1.2, 1.2) * glow_strength.get(value, 0.5)
	
	var border_color = tile_color.lightened(0.3)
	border_color.a = 0.9
	border.default_color = border_color
	
	label.add_theme_color_override("font_color", Color.WHITE)
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.25).from(Vector2(0.2, 0.2))
	
	var glow_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(glow, "scale", Vector2(1.25, 1.25) * glow_strength.get(value, 0.5), 0.15)
	glow_tween.tween_property(glow, "scale", Vector2(1.2, 1.2) * glow_strength.get(value, 0.5), 0.15)
	
	call_deferred("start_idle_pulse")

func prepare_for_merge():
	if active_pulse_tween != null and active_pulse_tween.is_valid():
		active_pulse_tween.kill()
	active_pulse_tween = null
	
	var pulse_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	var original_color = glow.color
	var brighter_color = original_color
	brighter_color.a = 0.5
	
	var glow_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(glow, "color", brighter_color, 0.15)
	glow_tween.tween_property(glow, "color", original_color, 0.15)
	
	var border_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var original_border_color = border.default_color
	var bright_border_color = Color(1, 1, 1, 0.9)
	border_tween.tween_property(border, "default_color", bright_border_color, 0.15)
	border_tween.tween_property(border, "default_color", original_border_color, 0.15)

func start_idle_pulse():
	if active_pulse_tween != null and active_pulse_tween.is_valid():
		active_pulse_tween.kill()
	active_pulse_tween = null
	
	if is_moving:
		return
		
	var pulse_delay = randf_range(0.0, 1.0)
	await get_tree().create_timer(pulse_delay).timeout
	
	if !is_instance_valid(self) or is_moving:
		return
		
	_create_idle_pulse()

func _create_idle_pulse():
	if !is_instance_valid(self):
		return
		
	if is_moving:
		return
		
	var pulse_intensity = 0.025 + (0.003 * log(value))
	var base_scale = Vector2(1.0, 1.0)
	var pulse_scale = Vector2(1.0 + pulse_intensity, 1.0 + pulse_intensity)
	
	active_pulse_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_pulse_tween.tween_property(self, "scale", pulse_scale, 1.5)
	active_pulse_tween.tween_property(self, "scale", base_scale, 1.5)
	active_pulse_tween.tween_callback(func(): 
		if is_instance_valid(self) and !is_moving: 
			_create_idle_pulse()
	)
	
	var glow_intensity = glow_strength.get(value, 0.5)
	var base_glow = Vector2(1.2, 1.2) * glow_intensity
	var peak_glow = Vector2(1.22, 1.22) * glow_intensity
	
	var glow_pulse = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_pulse.tween_property(glow, "scale", peak_glow, 1.5)
	glow_pulse.tween_property(glow, "scale", base_glow, 1.5)
	
	var border_width_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	border_width_tween.tween_property(border, "width", 3.2, 1.5)
	border_width_tween.tween_property(border, "width", 3.0, 1.5)

func set_moving(moving: bool):
	is_moving = moving
	
	if !moving:
		call_deferred("start_idle_pulse")