extends Node2D

@onready var _score_label = $CanvasLayer/ScoreLabel
@onready var _collectibles = $Collectibles.get_children()

var score: int = 0
var remaining_collectibles: int = 0

func _ready() -> void:
	remaining_collectibles = _collectibles.size()

	for collectible in _collectibles:
		if collectible.has_signal("collected"):
			collectible.connect("collected", Callable(self, "_on_collectible_collected"))
	
	_update_score_label()

func _on_collectible_collected(value: int) -> void:
	score += value
	remaining_collectibles -= 1
	if remaining_collectibles <= 0:
		_score_label.text = "All collected!"
	else:
		_update_score_label()

func _update_score_label() -> void:
	_score_label.text = "Score: %d" % score
