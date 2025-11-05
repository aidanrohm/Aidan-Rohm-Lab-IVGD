extends Area2D
# If the player falls off the map, they lose a life --> the need for a killbox to reset the player's position.

# Uses a specific respawn point node in order to put the player back to a specific point
@export var respawn_point: NodePath
var player: CharacterBody2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# The player's group is detected in order to determine where to send it
	# Not everything is meant to be respawned if it falls off the map
	if body.is_in_group("player"):
		# Trigger life loss first
		body.lose_life()
	
	# The mushroom should remove itself from the scene tree if it falls off the platform to its death
	# This will be important for future development
	if body.is_in_group("enemy") || body.is_in_group("troll"):
		queue_free()

		# Use checkpoint respawn if available, otherwise use respawn point
		if "respawn_at_checkpoint" in body:
			body.respawn_at_checkpoint()
		elif respawn_point:
			var spawn = get_node(respawn_point)
			body.global_position = spawn.global_position
			
			# Resetting the player's velocity after respawn, just to be sure it doesn't move around on a fresh spawn
			body.velocity = Vector2.ZERO
