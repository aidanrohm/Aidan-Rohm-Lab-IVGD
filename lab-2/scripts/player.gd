extends CharacterBody2D

const SPEED = 275.0
const JUMP_VELOCITY = -450.0

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		animated_sprite.play("jump")

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Move the body
	move_and_slide()

	# --- ANIMATION CONTROL ---
	if not is_on_floor():
		# Stay in jump animation while airborne
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif direction == 0:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run")

	# --- FLIP SPRITE BASED ON DIRECTION ---
	if direction != 0:
		animated_sprite.flip_h = direction < 0
