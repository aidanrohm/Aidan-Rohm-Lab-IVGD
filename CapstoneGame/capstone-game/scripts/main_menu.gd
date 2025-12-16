# A simple script to create the main menu page
# Has buttons to begin playing, go to the how to play screen, and quit

extends Control

@onready var play_button: Button = $Center/VBoxContainer/PlayButton
@onready var howto_button: Button = $Center/VBoxContainer/HowToButton
@onready var quit_button: Button = $Center/VBoxContainer/Quit

func _ready() -> void:
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	play_button.pressed.connect(_on_play_pressed)
	howto_button.pressed.connect(_on_howto_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")


func _on_howto_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/HowToPlay.tscn")

# Simply quits the player
func _on_quit_pressed() -> void:
	get_tree().quit()
