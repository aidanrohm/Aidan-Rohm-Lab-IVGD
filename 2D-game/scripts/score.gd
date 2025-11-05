extends Label

func _ready() -> void:
	# Initial display
	text = "Score: %d" % score_manager.score
	
	# Update automatically whenever the score changes from coin collection
	score_manager.score_changed.connect(_on_score_changed)

func _on_score_changed(new_score: int) -> void:
	text = "Score: %d" % new_score
