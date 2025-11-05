extends Area2D
# If the player falls off the map, they lose a life --> the need for a killbox to reset the player's position.

# Uses a specific respawn point node in order to put the player back to a specific point
# (Kept for future use; the player now owns all respawn logic.)
@export var respawn_point: NodePath
var player: CharacterBody2D

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	# The player's group is detected in order to determine where to send it
	# Not everything is meant to be respawned if it falls off the map
	if body.is_in_group("player"):
		# Trigger life loss first. Do NOT call respawn here—
		# the player script handles that safely and idempotently.
		body.lose_life()

	elif body.is_in_group("enemy"):
		# The enemy should remove itself from the scene tree if it falls off the platform to its death
		# This will be important for future development
		body.queue_free()

	# NOTE:
	# We no longer reposition the player here. If you want to use a fixed spawn point
	# (ignoring checkpoints), you can call a method on the player that sets its checkpoint:
	#
	#   if body.is_in_group("player") and respawn_point:
	#       var spawn := get_node(respawn_point)
	#       body.set_checkpoint(spawn.global_position)
	#
	# The actual respawn teleport must still be done by the player via lose_life()/respawn_at_checkpoint().
