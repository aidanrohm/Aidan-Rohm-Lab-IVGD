extends Area2D

@export var flag_sprite: AnimatedSprite2D
@export var active_color: Color = Color(1, 1, 1)        	# Bright when active
@export var inactive_color: Color = Color(0.5, 0.5, 0.5) # Dimmed when inactive
@export var raise_on_activate: bool = true               

var is_active: bool = false		# Flag used to determine whether checkpoint is active or not (no pun intended)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

	# Set initial visual state for non active checpoint
	if flag_sprite:
		flag_sprite.modulate = inactive_color
		flag_sprite.play("sway")

func _on_body_entered(body):
	# Triggered when the player enters the detection space
	if body.is_in_group("player") and not is_active:
		$CheckpointSound.play()
		activate_checkpoint(body)	# Calling the function to activate the checkpoint

# Function to activate the checkpoint
func activate_checkpoint(player):
	is_active = true # Change the active flag to true
	player.set_checkpoint(global_position)

	# Changing the flag color to show that it is active
	if flag_sprite:
		flag_sprite.modulate = active_color
		flag_sprite.play("sway") # play the waving animation

		# Playing a sligjt jump animation on the flag by using a tween, to animate its active state
		if raise_on_activate:
			var tween = get_tree().create_tween()
			tween.tween_property(flag_sprite, "position:y", flag_sprite.position.y - 10, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(flag_sprite, "position:y", flag_sprite.position.y, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	print("Checkpoint activated at ", global_position)
