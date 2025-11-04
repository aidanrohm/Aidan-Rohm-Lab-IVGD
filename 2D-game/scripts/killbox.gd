extends Area2D
# Killbox: if the player falls, they lose a life and respawn.
# Enemies (trolls) that fall are removed from the scene.

@export var respawn_point: NodePath

var _spawn_point: Node2D = null

func _ready() -> void:
	# If you didn't connect in the editor:
	body_entered.connect(_on_body_entered)
	# Cache optional respawn point node
	if respawn_point != NodePath(""):
		var n := get_node(respawn_point)
		if n is Node2D:
			_spawn_point = n

func _on_body_entered(body: Node) -> void:
	# Resolve the actual character root in case a child (e.g., CollisionShape2D) entered
	var who: Node = body
	if not (who is CharacterBody2D) and body.get_parent() and (body.get_parent() is CharacterBody2D):
		who = body.get_parent()

	# PLAYER: lose a life and respawn
	if who.is_in_group("player"):
		if "lose_life" in who:
			who.lose_life()

		# Prefer the player's own respawn logic (checkpoints etc.)
		if "respawn_at_checkpoint" in who:
			who.respawn_at_checkpoint()
		elif _spawn_point:
			# Fallback to explicit respawn point
			who.global_position = _spawn_point.global_position
			# Reset velocity if the player exposes it (CharacterBody2D does)
			if "velocity" in who:
				who.velocity = Vector2.ZERO

	# TROLL: just remove it
	elif who.is_in_group("troll"):
		who.queue_free()
