extends Node2D

@onready var _score_label = $CanvasLayer/ScoreLabel
var score: int = 0

func _ready() -> void:
	for collectible in $Collectibles.get_children():
		if collectible.has_signal("collected"):
			collectible.connect("collected", Callable(self, "_on_collectible_collected"))
			
	_update_score_label()
	
func _on_collectible_collected(value: int) -> void:
	score += value
	_update_score_label()
	if $Collectibles.get_child_count() == 0:
		_score_label.text = "All collected! %d" % score
		
func _update_score_label() -> void:
	_score_label.text = "Score: %d" % score
