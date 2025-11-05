extends Node2D

# This script keeps track of all the trolls in the scene
# When there are no more trolls left, it moves to the next scene (level2.tscn)

func _ready():
	# Function call to count the number of trolls in the scene tree
	_check_troll_count()

func _process(_delta):
	# Function used to continuously count the number of trolls in the scene each frame
	_check_troll_count()

func _check_troll_count():
	# Counts by looking at the scene structure
	var trolls = get_tree().get_nodes_in_group("troll")
	if trolls.size() == 0:
		_load_next_level()

func _load_next_level():
	# Occurs when all trolls are dead
	print("All trolls defeated! Loading level 2...")
	get_tree().change_scene_to_file("res://scenes/Victory.tscn")
