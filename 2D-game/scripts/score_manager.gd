extends Node
class_name ScoreManager

# Simple script that runs automatically in global control
# This allows the score to be updated, and cary through each level to the end of the game

signal score_changed(score: int)

var score: int = 0

func add(points: int) -> void:
	score += points
	score_changed.emit(score)

func set_score(value: int) -> void:
	score = value
	score_changed.emit(score)

func reset() -> void:
	score = 0
	score_changed.emit(score)
