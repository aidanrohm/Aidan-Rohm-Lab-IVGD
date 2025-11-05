extends CharacterBody2D

# -- BELOW ARE NECESSARY VARIABLES FOR troll ACTIVITY -- #
# ---------- PLACED HERE FOR EASE OF MODIFICATION --------- #
@export var speed: float = 50.0				# Wandering speed
@export var chase_speed: float = 100.0		# Speed when chasing player
@export var wander_min_time: float = 0.5	# Min time for wandering on one execute
@export var wander_max_time: float = 2.0	# Max time for wandering on one execute
@export var idle_min_time: float = 0.5		# Min time for idling (time after execute of wander)
@export var idle_max_time: float = 1.5		# Max time for idling (time after execute of wander)
@export var attack_threshold: float = 50.0	# Distance to stop running toward player

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D		# Controls which animations run
@onready var detection_area: Area2D = $DetectionArea		# Detects when the player enters/exits
@onready var edge_ray: RayCast2D = $EdgeRay					# Detects platform edges to keep trolls on platform

# Defaults for flagging and behavior
var is_chasing: bool = false			# Whether or not the troll is chasing
var wandering: bool = false				# Whether or not the troll is wandering
var player: Node2D = null				# Stores a reference so the troll can chase the player
var direction: int = 1					# 1 = right, -1 = left
var is_dead: bool = false				# Flag for death state
var is_hurting: bool = false			# Flag to lock animation/logic while "damage" is playing
var death_lock: bool = false			# Prevents multiple simultaneous death triggers
var attack_counter: int = 0				# Tracks number of attacks made on player
var player_in_range_time: float = 0.0	# Timer for player being in range

# Add gravity for troll functionality
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Connects the detection area's signals to the respective functions
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)

	# Start wandering when the scene starts
	_start_wandering()

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Stop all logic if dead, allows death animation/sound to finish undisturbed
	if is_dead:
		move_and_slide()
		return

	# If taking damage, lock out normal AI/animation until "damage" finishes
	if is_hurting:
		velocity.x = 0
		move_and_slide()
		return

	# Reset horizontal movement before computing this frame's intent
	velocity.x = 0

	# Edge detection: if no platform ahead, flip direction
	if not edge_ray.is_colliding():
		direction *= -1
		_update_facing() # Ensures the idle facing flips immediately on edge turn

	if is_chasing and player:
		var dx = player.global_position.x - global_position.x
		var distance = abs(dx)
		
		# Move toward the player only if farther than attack_threshold
		if distance > attack_threshold:
			velocity.x = chase_speed * sign(dx)
			direction = 1 if velocity.x > 0 else -1
			anim.play("run")
			_update_facing() # Face toward movement
		else:
			velocity.x = 0
			anim.play("idle")
			_update_facing() # Keep facing the last known direction toward player

		# Attack cadence: after 0.5s within range, play a damage (hurt) animation
		if player and "is_attacking" in player and not player.is_attacking:
			player_in_range_time += delta
			if player_in_range_time >= 0.5:
				_attack()				# plays "attack" animation with lock
				player_in_range_time = 0.0
				attack_counter += 1
				if attack_counter >= 2 and "lose_life" in player:
					player.lose_life()	# 2 attacks = 1 life lost
					attack_counter = 0
		else:
			player_in_range_time = 0.0

	else:
		# Not chasing: wander in the current direction
		player_in_range_time = 0.0
		velocity.x = direction * speed
		if velocity.x != 0:
			anim.play("run")
		else:
			anim.play("idle")
		_update_facing() # Face based on current direction/velocity

	# Move and detect collisions
	move_and_slide()

	# Turn around if collided with another troll (avoid pile-ups), not currently needed with how the level is designed
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var other = collision.get_collider()
		if other and other.is_in_group("troll"):
			direction *= -1
			_update_facing()
			break

func _update_facing() -> void:
	# Sprite art faces RIGHT by default
	# We want it to face LEFT when moving/looking left
	var look = direction
	if abs(velocity.x) > 0.1:
		look = 1 if velocity.x > 0 else -1
	anim.flip_h = (look < 0)

func _attack() -> void:
	'''Controls the enemy's "attack" animation and locks state until finished.'''
	if is_dead or is_hurting:
		return
	is_hurting = true
	velocity.x = 0
	anim.play("attack")				
	await wait_for_animation(anim, "attack")
	is_hurting = false

func _start_wandering():
	# Function to return the troll to a wandering state
	if is_chasing or wandering:
		return
	wandering = true
	_wander_loop()

func _wander_loop() -> void:
	# Function that is actually used to wander
	while not is_chasing and not is_dead:
		direction = 1 if randi() % 2 == 0 else -1
		_update_facing()

		var wander_time = randf_range(wander_min_time, wander_max_time)
		await get_tree().create_timer(wander_time).timeout

		velocity.x = 0
		anim.play("idle")
		_update_facing()

		var idle_time = randf_range(idle_min_time, idle_max_time)
		await get_tree().create_timer(idle_time).timeout

	wandering = false

func _on_player_entered(body: Node):
	# Function used for chasing mechanics
	var player_node = body
	if not body is CharacterBody2D and body.get_parent() and body.get_parent() is CharacterBody2D:
		player_node = body.get_parent()
	
	if player_node.is_in_group("player"):
		is_chasing = true
		player = player_node
		velocity.x = 0
		player_in_range_time = 0.0
		attack_counter = 0
		direction = 1 if (player.global_position.x - global_position.x) >= 0 else -1
		_update_facing()

func _on_player_exited(body: Node):
	# Function used to return the troll to a wander state if the player is no longer detectable
	var player_node = body
	if not body is CharacterBody2D and body.get_parent() and body.get_parent() is CharacterBody2D:
		player_node = body.get_parent()
	
	if player_node.is_in_group("player"):
		is_chasing = false
		player = null
		player_in_range_time = 0.0
		_start_wandering()

func take_damage(_player_pos: Vector2):
	'''Kill the troll and remove it from the scene tree after the death animation completes.'''
	if is_dead or death_lock:
		return
	is_dead = true
	death_lock = true

	collision_layer = 0
	collision_mask = 0
	if is_instance_valid(detection_area):
		detection_area.set_deferred("monitoring", false)
	velocity = Vector2.ZERO

	anim.play("death")
	$DeathSound.play()
	await wait_for_animation(anim, "death")
	
	# Drop group immediately so level count reflects this kill
	if is_in_group("troll"):
		remove_from_group("troll")
	call_deferred("queue_free")


# --- Helper function to reliably wait for animation completion --- #
# Needed this because for some reason the await animation completion function was not always guaranteeing completion
func wait_for_animation(sprite: AnimatedSprite2D, animation_name: String) -> void:
	if not sprite.sprite_frames.has_animation(animation_name):
		return
	if sprite.sprite_frames.get_animation_loop(animation_name) == false:
		await sprite.animation_finished
	else:
		var anim_length = sprite.sprite_frames.get_frame_count(animation_name) / sprite.sprite_frames.get_animation_speed(animation_name)
		await get_tree().create_timer(anim_length, false).timeout
