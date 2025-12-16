# Simple script for the how to play scene/page that is selectable from the main menu

extends Control

@onready var back_button: Button = $CenterContainer/VBoxContainer/Button

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
