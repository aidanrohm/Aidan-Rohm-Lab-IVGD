extends Node2D

# This script keeps track of all the trolls in the scene.
# When there are no more trolls left, it moves to the next scene (level2.tscn).

func _ready():
	# Count how many trolls exist when the level starts.
	# Make sure all your troll enemies are in the group "troll".
	_check_troll_count()

func _process(_delta):
	# Continuously check each frame if there are any trolls left.
	# You could also use a signal-based system, but this is simple and reliable for now.
	_check_troll_count()

func _check_troll_count():
	var trolls = get_tree().get_nodes_in_group("troll")
	if trolls.size() == 0:
		_load_next_level()

func _load_next_level():
	print("All trolls defeated! Loading level 2...")
	get_tree().change_scene_to_file("res://scenes/level2.tscn")
