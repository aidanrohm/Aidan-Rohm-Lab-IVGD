extends Area2D
# Killbox was implemented because I ultimately want to keep on building this game.
# Hopefully I can get to a point where there are platforms the mushrooms reside on.
# The player can attack these mushrooms on these platforms and will have to kill all of them to win.
# If the player falls off the map, they lose a life --> the need for a killbox to reset the player's position.
# The killbox is fully implemented, just not being used for anything at the moment.

# Uses a specific respawn point node in order to put the player back to a specific point
@export var respawn_point: NodePath
var player: CharacterBody2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# The player's group is detected in order to determine where to send it
	# Not everything is meant to be respawned if it falls off the map
	if body.is_in_group("player"):
		if respawn_point:
			var spawn = get_node(respawn_point)
			body.global_position = spawn.global_position
			
			# Resetting the player's velocity after respawn, 
			# just to be sure it doesn't move around on a fresh spawn
			body.velocity = Vector2.ZERO
