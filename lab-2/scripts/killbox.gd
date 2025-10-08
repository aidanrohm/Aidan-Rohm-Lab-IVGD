extends Area2D

@export var respawn_point: NodePath
var player: CharacterBody2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		if respawn_point:
			var spawn = get_node(respawn_point)
			body.global_position = spawn.global_position
			body.velocity = Vector2.ZERO
