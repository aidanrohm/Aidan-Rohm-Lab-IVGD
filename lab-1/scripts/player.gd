extends CharacterBody2D

@export var speed : float = 220.0

# A built in function that Godot calls about 60 times per second
# Useful for continuous things that are meant to be in tune with physics, such as movement
func _physics_process(delta: float) -> void:
	# Get the input from the user actions
	var direction = Vector2(
		# get_action_strength returns 1 if the button is pressed, 0 if not
		# This setup allows us to move the player right if the left key is not pressed
		# This is similar for all other movement cases
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	if direction.length() > 0:
		# Normalization helps us ensure that movement is not faster when moving diagonally
		direction = direction.normalized()
		
	# Setting the velocity is important, but uses the direction defined by the previous variable
	velocity = direction * speed
	
	# A built in function that uses the variable velocity
	# Has built in collision detection, and will "slide" along walls instead of simply stopping on collision
	move_and_slide()
	
