extends Label

var fonts = []
var font_names = [
	"NeonLights",
	"ZappedSticks",
	"SurrealismRose",
	"NeonFuture",
	"DriveThru", 
	"MadSense",
	"NeonAndroid",
	"Mama",
	"Neonland",
	"Monage"
]
var current_font_index = 0

var glitch_timer = 0
var glitch_interval = 3.0
var glitch_duration = 0.5
var is_glitching = false
var original_position = Vector2.ZERO
var original_color: Color
var original_scale = Vector2.ONE
var original_rotation = 0

var title_text = "HEXADECIMAL"

func _ready():
	original_color = self.modulate
	original_position = self.position
	original_rotation = self.rotation
	
	for font_name in font_names:
		var font = load("res://fonts/" + font_name + ".ttf")
		if font:
			fonts.append(font)
	
	if fonts.size() > 0:
		set_font(0)
	
	glitch_timer = randf_range(1.0, glitch_interval)

func _process(delta):
	glitch_timer -= delta
	
	if glitch_timer <= 0:
		if !is_glitching:
			is_glitching = true
			apply_glitch_effect()
			
			var glitch_end_timer = get_tree().create_timer(glitch_duration)
			glitch_end_timer.timeout.connect(end_glitch)
			
			glitch_timer = glitch_duration
		else:
			is_glitching = false
			current_font_index = (current_font_index + 1) % fonts.size()
			set_font(current_font_index)
			
			glitch_timer = glitch_interval + randf_range(-1.0, 1.0)

func set_font(index):
	if index < fonts.size():
		set("theme_override_fonts/font", fonts[index])

func apply_glitch_effect():
	var tween = create_tween()
	
	var glitch_type = randi() % 5
	
	match glitch_type:
		0:
			tween.tween_property(self, "position:x", original_position.x + randf_range(-20, 20), 0.1)
			tween.tween_property(self, "position:x", original_position.x, 0.1)
		1:
			var glitch_color = Color(randf(), randf(), randf(), 1.0)
			tween.tween_property(self, "modulate", glitch_color, 0.1)
		2:
			var scale_amount = randf_range(0.8, 1.2)
			tween.tween_property(self, "scale", Vector2(scale_amount, 1.0), 0.1)
		3:
			tween.tween_property(self, "rotation", randf_range(-0.1, 0.1), 0.1)
		4:
			var glitched_text = ""
			for i in range(title_text.length()):
				if randf() < 0.2:
					glitched_text += char(randi_range(65, 90))
				else:
					glitched_text += title_text[i]
			self.text = glitched_text
	
	for i in range(3):
		tween.tween_property(self, "visible", false, 0.05)
		tween.tween_property(self, "visible", true, 0.05)

func end_glitch():
	var tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.2)
	tween.tween_property(self, "modulate", original_color, 0.2)
	tween.tween_property(self, "scale", original_scale, 0.2)
	tween.tween_property(self, "rotation", original_rotation, 0.2)
	self.text = title_text