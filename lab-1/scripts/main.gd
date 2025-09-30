extends Node2D

@onready var _score_label = $CanvasLayer/ScoreLabel 			# Stores a reference to the label that holds player score
@onready var _collectibles = $Collectibles.get_children() 	# Stores an array of collectible nodes
															# Effectively providing all coin instances at start

var score: int = 0 # Score is used to display the player's score
var remaining_collectibles: int = 0 # Remaining obstacles is used as opposed to get_child_count (more reliable for timing issues)

# Runs automatically when the scene enters the schene tree
func _ready() -> void:
	# remainingcollectibles is set to the number of coins when the main scene loads
	remaining_collectibles = _collectibles.size()
	
	# Loops over the collectibles and connects its signal to the modifier function
	# --> Crucial as it allows the main scene to react when a coin is collected
	for collectible in _collectibles:
		if collectible.has_signal("collected"):
			collectible.connect("collected", Callable(self, "_on_collectible_collected"))
	
	# Function call to update the score label
	_update_score_label()

# Modifier function used to impact the score shown to the player
func _on_collectible_collected(value: int) -> void:
	score += value 					# Updates the player score
	remaining_collectibles -= 1		# Decreases the number of remaining collectibles
	if remaining_collectibles <= 0:	# Condition to display the victory condition
		_score_label.text = "All collected! Level Complete - Hooray!"
	else:
		_update_score_label()

# Updater function used to display the score label accurately
func _update_score_label() -> void:
	_score_label.text = "Score: %d" % score
