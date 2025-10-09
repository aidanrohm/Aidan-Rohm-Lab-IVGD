extends CharacterBody2D

# Set for player movement
const SPEED = 150.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta # Use delta to smoothe the movement as discussed in class

	# Handle jump
	if (Input.is_action_just_pressed("ui_up")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animated_sprite.play("jump") # Using the jump animation

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right") # Direction based on what key is pressed by user
	if direction:
		velocity.x = direction * SPEED # Global speed variable used here to create the velocity
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED) # Graceful slowdown

	# Move the body
	move_and_slide()

	# Animation controller
	if not is_on_floor():
		# Stay in jump animation while airborne
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif direction == 0:
		animated_sprite.play("idle") # Idle animation trigger
	else:
		animated_sprite.play("run") # Run animation trigger

	# Flip the sprite based on direction of movement
	if direction != 0:
		animated_sprite.flip_h = direction < 0
