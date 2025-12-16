# A simple script for the ending screen that is displayed when the last letter
# is picked up from the cabin bed

extends Control

@onready var back_button: Button = $CenterContainer/VBoxContainer/BackToMenuButton

func _ready() -> void:
	# Show mouse so UI can be clicked
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	# Also keep mouse visible in the main menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
