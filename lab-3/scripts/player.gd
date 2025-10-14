extends CharacterBody2D

# Set for player movement
const SPEED = 150.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackRange  # The new attack range Area2D

var is_attacking: bool = false # Flag to track if attack animation is playing
var can_attack: bool = false # Flag to allow continuous attack while overlapping
var overlapping_mushrooms: Array = [] # List of mushrooms currently inside attack range

func _ready():
	# Connect to detect when animations finish
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Connect the attack area signals to track overlapping mushrooms
	attack_area.area_entered.connect(_on_attack_area_area_entered)
	attack_area.area_exited.connect(_on_attack_area_area_exited)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta # Use delta to smooth the movement

	# Handle jump
	if (Input.is_action_just_pressed("ui_up")) and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY
		animated_sprite.play("jump") # Using the jump animation

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right") # Direction based on pressed keys
	if not is_attacking: # Prevent movement during attack
		if direction != 0:
			velocity.x = direction * SPEED # Set horizontal speed
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED) # Graceful slowdown
	else:
		velocity.x = 0 # Stop horizontal movement while attacking

	# Move the player
	move_and_slide()

	# --- Attack handling ---
	if Input.is_action_just_pressed("ui_attack") and not is_attacking:
		is_attacking = true
		can_attack = true # Allow attacks to trigger continuously while overlapping
		animated_sprite.play("attack")
	
	# Apply attack to all overlapping mushrooms if attack is active
	if is_attacking and can_attack:
		for mush in overlapping_mushrooms:
			if "take_damage" in mush:
				mush.take_damage(global_position)

	# Animation controller
	if is_attacking:
		return # Don’t change animation while attacking

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

func _on_animation_finished():
	# Reset the attack state once the attack animation completes
	if animated_sprite.animation == "attack":
		is_attacking = false
		can_attack = false # Stop applying attacks after animation ends

func _on_attack_area_area_entered(area: Area2D):
	# Track mushrooms entering attack range
	if area.is_in_group("mushroom_hitbox"): # Make sure mushroom hitbox is in this group
		overlapping_mushrooms.append(area.get_parent()) # get the mushroom node

func _on_attack_area_area_exited(area: Area2D):
	# Remove mushrooms leaving attack range
	if area.is_in_group("mushroom_hitbox"):
		overlapping_mushrooms.erase(area.get_parent())
