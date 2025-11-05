extends Control
# Basic script used to control the how_to_play screen
# Includes functionality for the back button
@onready var back_button: Button = $BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	
func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
