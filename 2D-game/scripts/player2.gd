extends CharacterBody2D

# --- BELOW ARE NECESSARY VARIABLES FOR PLAYER ACTIVITY --- #
# ---------- PLACED HERE FOR EASE OF MODIFICATION --------- #
const SPEED = 150.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackRange  			# The new attack range Area2D
@onready var lives_label = get_tree().get_root().get_node("Level2/UI/LivesLabel")

var is_attacking: bool = false 								# Flag to track if attack animation is playing
var can_attack: bool = false 								# Flag to allow continuous attack while overlapping
var overlapping_mushrooms: Array = [] 						# List of mushrooms currently inside attack range
var lives: int = 3 											# Player starts with 3 lives
var checkpoint_position: Vector2 = Vector2(30, 575) 		# Default spawn position
var idle_timer: float = 0.0
const IDLE_DAMAGE_THRESHOLD: float = 3.0 					# Seconds the player can idle at spawn without moving

func _ready():
	# Connect to detect when animations finish
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Connect the attack area signals to track overlapping mushrooms
	attack_area.area_entered.connect(_on_attack_area_area_entered)
	attack_area.area_exited.connect(_on_attack_area_area_exited)
	
	# Initialize lives label on scene start
	_update_lives_label()

func _physics_process(delta: float) -> void:
	'''Basic movement and system development
	   The player will take damage/lose a life if they idle for too long
	'''
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta # Use delta to smooth the movement

	# Handle jump
	if (Input.is_action_just_pressed("ui_up")) and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY
		animated_sprite.play("jump") # Using the jump animation

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right") 	# Direction based on pressed keys
	if not is_attacking: 									# Prevent movement during attack
		if direction != 0:
			velocity.x = direction * SPEED 					# Set horizontal speed
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED) 	# Graceful slowdown
	else:
		velocity.x = 0 										# Stop horizontal movement while attacking

	# Idle damage handling
	if velocity.x == 0 and velocity.y == 0:
		idle_timer += delta
		# Only trigger idle damage after 3 seconds from respawn
		if idle_timer >= IDLE_DAMAGE_THRESHOLD:
			lose_life()
			idle_timer = 0.0
	else:
		idle_timer = 0.0 # Reset timer if player moves

	# Move the player
	move_and_slide()

	# Attack handling
	if Input.is_action_just_pressed("ui_attack") and not is_attacking:
		is_attacking = true
		can_attack = true # Allow attacks to trigger continuously while overlapping
		animated_sprite.play("attack")
		$AttackSound.play()
	
	# Apply attack to all overlapping mushrooms if attack is active
	if is_attacking and can_attack:
		for mushroom in overlapping_mushrooms:
			if "take_damage" in mushroom:
				mushroom.take_damage(global_position)

	# Animation controller
	if is_attacking:
		return # Don’t change animation while attacking

	if not is_on_floor():
		# Stay in jump animation while airborne
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif direction == 0:
		animated_sprite.play("idle") 	# Idle animation trigger
	else:
		animated_sprite.play("run") 	# Run animation trigger

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
	if area.is_in_group("mushroom_hitbox"):				# Mushroom hitbox is in the group
		overlapping_mushrooms.append(area.get_parent()) # get the mushroom node

func _on_attack_area_area_exited(area: Area2D):
	# Remove mushrooms leaving attack range
	if area.is_in_group("mushroom_hitbox"):
		overlapping_mushrooms.erase(area.get_parent())

# Called when player touches the killbox or idle damage triggers
func lose_life():
	lives -= 1
	_update_lives_label()

	# If no lives remain, end the game/reload scene
	# Eventually will be modified to show a game over screen
	if lives <= 0:
		_game_over()
	else:
		print("Player lost a life! Remaining: %d" % lives)
		respawn_at_checkpoint()

# Update the label UI on screen
func _update_lives_label():
	if lives_label:
		lives_label.text = "Lives: %d" % lives

# Handle when lives reach 0
func _game_over():
	print("Game Over! Restarting scene...")
	call_deferred("_reload_scene_safely") # Prevents modifying nodes during physics

# Reload safely (avoids physics crash)
func _reload_scene_safely():
	get_tree().reload_current_scene()

# Called by checkpoint when activated
func set_checkpoint(checkpoint_pos: Vector2):
	checkpoint_position = checkpoint_pos
	print("Checkpoint set at: ", checkpoint_pos)

	# Give player an extra life
	lives += 1
	_update_lives_label()
	print("Extra life gained! Lives: %d" % lives)

	# Play green flash + grow animation to visualize gaining a life
	_flash_green_and_scale_effect()

# Respawn player at checkpoint
func respawn_at_checkpoint():
	global_position = checkpoint_position
	velocity = Vector2.ZERO
	idle_timer = 0.0 # Allow player to idle without penalty for 3s
	print("Player respawned at checkpoint: ", checkpoint_position)

	# Flash red and grow/shrink effect, for idling too long
	_flash_red_and_scale_effect()

# Visualizing the respawn effect so the player knows they did something wrong
func _flash_red_and_scale_effect():
	var original_color = animated_sprite.modulate
	var original_scale = scale
	var tween = create_tween()		# Uses a tween variable to modify the animation

	# Flash red & grow over 0.15s
	tween.tween_property(animated_sprite, "modulate", Color(1, 0, 0), 0.15)
	tween.tween_property(self, "scale", original_scale * 1.3, 0.15)

	# Then return to normal over 0.15s
	tween.tween_property(animated_sprite, "modulate", original_color, 0.15)
	tween.tween_property(self, "scale", original_scale, 0.15)

# Visualizing the checkpoint effect so the player knows they did something right
func _flash_green_and_scale_effect():
	var original_color = animated_sprite.modulate
	var original_scale = scale
	var tween = create_tween()		# Uses a tween variable to modify the animation

	# Flash green & grow over 0.15s
	tween.tween_property(animated_sprite, "modulate", Color(0, 1, 0), 0.15)
	tween.tween_property(self, "scale", original_scale * 1.3, 0.15)

	# Return to normal over 0.15s
	tween.tween_property(animated_sprite, "modulate", original_color, 0.15)
	tween.tween_property(self, "scale", original_scale, 0.15)
