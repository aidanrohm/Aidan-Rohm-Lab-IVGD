extends Node2D

func _ready():
	$PlatformAnimation1.play("move")
	$PlatformAnimation2.play("move")
	
	# Count how many mushrooms exist when the level starts.
	# Make sure all your mushroom enemies are in the group "mushroom".
	_check_mushroom_count()

func _process(_delta):
	# Continuously check each frame if there are any mushrooms left.
	# You could also use a signal-based system, but this is simple and reliable for now.
	_check_mushroom_count()

func _check_mushroom_count():
	var mushrooms = get_tree().get_nodes_in_group("mushroom")
	if mushrooms.size() == 0:
		_load_next_level()

func _load_next_level():
	print("All mushrooms defeated! Loading level 3...")
	get_tree().change_scene_to_file("res://scenes/level3.tscn")
