extends Node2D

@onready var hex_grid = $HexGrid
@onready var score_label = $UI/ScoreLabel
@onready var high_score_label = $UI/HighScoreLabel
@onready var game_over_panel = $UI/GameOverPanel
@onready var game_won_panel = $UI/GameWonPanel

var score: int = 0
var high_score: int = 0

func _ready():
	DisplayServer.window_set_size(Vector2i(1600, 900))
	
	print("Game starting - Engine version: ", Engine.get_version_info())
	print("Running on platform: ", OS.get_name())
	print("Web export: ", OS.has_feature("web"))
	
	if OS.has_feature("web"):
		print("Running in web mode - initializing debug handlers")
		get_tree().set_auto_accept_quit(false)
	
	var font_path = "res://fonts/AlienCybernetics.ttf"
	var font = load(font_path)
	if font:
		var instructions = $UI/Instructions
		if instructions:
			instructions.add_theme_font_override("font", font)
	
	hex_grid.tiles_merged.connect(_on_tiles_merged)
	hex_grid.game_over.connect(_on_game_over)
	hex_grid.game_won.connect(_on_game_won)
	
	game_over_panel.visible = false
	game_won_panel.visible = false
	
	load_high_score()
	
	update_score_display()
	
	var particles = $BackgroundParticles
	if particles:
		particles.set_screen_dimensions(1600, 900)

func _input(event):
	if game_over_panel.visible or game_won_panel.visible:
		return
	
	if event is InputEventKey:
		if event.pressed:
			var direction = -1
			
			match event.keycode:
				KEY_D, KEY_RIGHT:
					direction = 0
				KEY_E:
					direction = 1
				KEY_W, KEY_UP:
					direction = 2
				KEY_Q, KEY_LEFT:
					direction = 3
				KEY_A:
					direction = 4
				KEY_S, KEY_DOWN:
					direction = 5
				KEY_R:
					restart_game()
					return
			
			if direction >= 0:
				hex_grid.handle_input(direction)

func _on_tiles_merged(position, value):
	score += value
	update_score_display()
	
	if score > high_score:
		high_score = score
		save_high_score()
		update_score_display()

func _on_game_over():
	game_over_panel.visible = true
	
	if OS.has_feature("web"):
		DisplayServer.window_set_title("GAMEOVER:" + str(score))

func _on_game_won():
	game_won_panel.visible = true
	
	if OS.has_feature("web"):
		DisplayServer.window_set_title("FINALSCORE:" + str(score))

func update_score_display():
	score_label.text = "Score: " + str(score)
	high_score_label.text = "Best: " + str(high_score)
	
	if OS.has_feature("web"):
		DisplayServer.window_set_title("SCORE:" + str(score))

func restart_game():
	score = 0
	update_score_display()
	
	hex_grid.initialize_grid()
	hex_grid.spawn_initial_tiles()
	
	game_over_panel.visible = false
	game_won_panel.visible = false

func load_high_score():
	var config = ConfigFile.new()
	var err = config.load("user://hex_neon_2048_save.cfg")
	
	if err == OK:
		high_score = config.get_value("game", "high_score", 0)

func save_high_score():
	var config = ConfigFile.new()
	config.set_value("game", "high_score", high_score)
	config.save("user://hex_neon_2048_save.cfg")

func _on_restart_button_pressed():
	restart_game()

func _on_continue_button_pressed():
	game_won_panel.visible = false