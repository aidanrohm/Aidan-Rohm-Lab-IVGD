extends CharacterBody2D

# --- BELOW ARE NECESSARY VARIABLES FOR PLAYER ACTIVITY --- #
# ---------- PLACED HERE FOR EASE OF MODIFICATION --------- #
const SPEED = 150.0
const JUMP_VELOCITY = -400.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackRange  			# The new attack range Area2D
@onready var lives_label = get_tree().get_root().get_node("Level1/UI/LivesLabel")

var is_attacking: bool = false 								# Flag to track if attack animation is playing
var can_attack: bool = false 								# Flag to allow continuous attack while overlapping
var overlapping_trolls: Array = [] 							# List of trolls currently inside attack range
var lives: int = 3 											# Player starts with 3 lives
var checkpoint_position: Vector2 = Vector2(30, 575) 		# Default spawn position
var idle_timer: float = 0.0
const IDLE_DAMAGE_THRESHOLD: float = 3.0 					# Seconds the player can idle at spawn without moving

# --- Safety/flow control to avoid double/triple respawns & mid-respawn state ---
var _respawn_lock: bool = false
var _post_respawn_invuln_timer: Timer
var _death_lock: bool = false 								# If you later play a death anim, this prevents input

func _ready():
	# Connect to detect when animations finish
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Connect the attack area signals to track overlapping trolls
	attack_area.area_entered.connect(_on_attack_area_area_entered)
	attack_area.area_exited.connect(_on_attack_area_area_exited)
	
	# Initialize lives label on scene start
	_update_lives_label()

	# Small one-shot timer to give a short grace period right after respawn
	_post_respawn_invuln_timer = Timer.new()
	_post_respawn_invuln_timer.one_shot = true
	_post_respawn_invuln_timer.wait_time = 0.25
	add_child(_post_respawn_invuln_timer)

func _physics_process(delta: float) -> void:
	'''Basic movement and system development
	   The player will take damage/lose a life if they idle for too long
	'''
	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta # Use delta to smooth the movement

	# Handle jump
	if (Input.is_action_just_pressed("ui_up")) and is_on_floor() and not is_attacking and not _death_lock:
		velocity.y = JUMP_VELOCITY
		animated_sprite.play("jump") # Using the jump animation

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right") 	# Direction based on pressed keys
	if not is_attacking and not _death_lock: 				# Prevent movement during attack/death
		if direction != 0:
			velocity.x = direction * SPEED 					# Set horizontal speed
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED) 	# Graceful slowdown
	else:
		velocity.x = 0 										# Stop horizontal movement while attacking/dead

	# Idle damage handling
	if velocity.x == 0 and velocity.y == 0 and not _death_lock:
		idle_timer += delta
		# Only trigger idle damage after N seconds from respawn
		if idle_timer >= IDLE_DAMAGE_THRESHOLD:
			lose_life()
			idle_timer = 0.0
	else:
		idle_timer = 0.0 # Reset timer if player moves

	# Move the player
	move_and_slide()

	# Attack handling
	if Input.is_action_just_pressed("ui_attack") and not is_attacking and not _death_lock:
		is_attacking = true
		can_attack = true # Allow attacks to trigger continuously while overlapping
		animated_sprite.play("attack")
		if has_node("AttackSound"):
			$AttackSound.play()
	
	# Apply attack to all overlapping trolls if attack is active
	if is_attacking and can_attack:
		for troll in overlapping_trolls:
			if "take_damage" in troll:
				troll.take_damage(global_position)

	# Animation controller
	if is_attacking or _death_lock:
		return # Don’t change animation while attacking or in death lock

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
	# Track trolls entering attack range
	if area.is_in_group("troll_hitbox"):				# troll hitbox is in the group
		overlapping_trolls.append(area.get_parent()) # get the troll node

func _on_attack_area_area_exited(area: Area2D):
	# Remove trolls leaving attack range
	if area.is_in_group("troll_hitbox"):
		overlapping_trolls.erase(area.get_parent())

# Called when player touches the killbox or idle damage triggers
func lose_life():
	if _respawn_lock or _death_lock:
		return
	lives -= 1
	_update_lives_label()

	# If no lives remain, end the game/reload scene
	# Eventually will be modified to show a game over screen
	if lives <= 0:
		_death_lock = true
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

# Respawn player at checkpoint (idempotent & safe even if called twice quickly)
func respawn_at_checkpoint():
	if _respawn_lock:
		return
	_respawn_lock = true
	# Do the repositioning on the idle frame to avoid physics reentrancy
	call_deferred("_do_respawn")

func _do_respawn():
	# --- Hard reset of visibility/collision/scale states that can hide the sprite ---
	visible = true
	modulate.a = 1.0
	scale = Vector2.ONE

	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.modulate.a = 1.0
		animated_sprite.play("idle")

	# (Re)enable collisions if they were disabled elsewhere
	if has_node("CollisionShape2D"):
		var cs = $CollisionShape2D
		if cs is CollisionShape2D:
			cs.disabled = false

	# Teleport & reset kinematics/timers
	global_position = checkpoint_position
	velocity = Vector2.ZERO
	idle_timer = 0.0
	_death_lock = false
	is_attacking = false
	can_attack = false

	print("Player respawned at checkpoint: ", checkpoint_position)

	# Flash red and grow/shrink effect, for idling too long
	_flash_red_and_scale_effect()

	# Short grace period to avoid re-triggering the Killbox immediately
	_post_respawn_invuln_timer.start()
	await _post_respawn_invuln_timer.timeout

	# Release the lock after one more frame to swallow duplicate triggers
	await get_tree().process_frame
	_respawn_lock = false

# Visualizing the respawn effect so the player knows they did something wrong
func _flash_red_and_scale_effect():
	var original_color = animated_sprite.modulate
	var original_scale = scale
	var tween = create_tween()		# Uses a tween variable to modify the animation

	# Flash red & grow over 0.15s
	tween.tween_property(animated_sprite, "modulate", Color(1, 0, 0, 1), 0.15)
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
	tween.tween_property(animated_sprite, "modulate", Color(0, 1, 0, 1), 0.15)
	tween.tween_property(self, "scale", original_scale * 1.3, 0.15)

	# Return to normal over 0.15s
	tween.tween_property(animated_sprite, "modulate", original_color, 0.15)
	tween.tween_property(self, "scale", original_scale, 0.15)
