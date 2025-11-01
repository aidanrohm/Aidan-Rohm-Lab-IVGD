extends Control

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var how_to_button: Button = $VBoxContainer/HowToButton

func _ready():
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	how_to_button.pressed.connect(_on_how_to_pressed)
	
# Function to take the player to the first level when they click play
func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/level1.tscn")
	
# Function to take the player to the how to play screne when they click play
func _on_how_to_pressed():
	get_tree().change_scene_to_file("res://scenes/howtoplay.tscn")
	
