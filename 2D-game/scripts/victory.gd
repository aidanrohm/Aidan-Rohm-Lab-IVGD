extends Control

@onready var menu_button: Button = $MenuButton

func _ready() -> void:
	menu_button.pressed.connect(_on_menu_pressed)

func _on_menu_pressed() -> void:
	# Reset score if score_manager autoload exists
	if has_node("/root/score_manager"):
		get_node("/root/score_manager").reset()

	# Reload the menu scene fresh
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
