extends Node2D

func _ready():
	# Used to start the movement of the platforms across the screen
	$MovingPlatform1/PlatformAnimation1.play("move")
	$MovingPlatform2/PlatformAnimation2.play("move")

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
	get_tree().change_scene_to_file("res://scenes/level3.tscn")
