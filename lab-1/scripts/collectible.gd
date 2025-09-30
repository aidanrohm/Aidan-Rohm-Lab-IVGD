extends Area2D

# This signal helps to update the main script when a coin is collected from the player space
signal collected(value: int)


@export var value: int = 1			# Impacts the value of the collectible (coin)
@onready var _sprite = $Sprite2D

# Runs automatically when the scene enters the scene tree
func _ready() -> void:
	# Connect allows the engine to act on something under a specific circumstance
	# Specifically, when "body_entered" occurs, this will call _on_body_entered
	connect("body_entered", Callable(self, "_on_body_entered"))
	
# Function that is called automatically when the player touches a collectible
func _on_body_entered(body: Node) -> void:
	# To be sure that the collectible is triggered effectively
	if body.is_in_group("player"):
		_sprite.visible = false						# Gives the appearance that the coin has been picked up
		emit_signal("collected", value)				# Main listens to this signal in order to update the score
		await get_tree().create_timer(0.35).timeout	# Helpful for later development
													# I have yet to do anything with the timer, but I would liek to add a sound
													# The timer is helpful because it will delay continuation and can allow something,
													# like a sound to be played
		queue_free() 	# This is a "safe" way to delete a node
						# The node will be deleted until the scene is reset
