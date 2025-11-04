extends CharacterBody2D

# -- BELOW ARE NECESSARY VARIABLES FOR troll ACTIVITY -- #
# ---------- PLACED HERE FOR EASE OF MODIFICATION --------- #
@export var speed: float = 50.0				# Wandering speed
@export var chase_speed: float = 100.0		# Speed when chasing player
@export var wander_min_time: float = 0.5		# Min time for wandering on one execute
@export var wander_max_time: float = 2.0		# Max time for wandering on one execute
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
		_update_facing() # ensure the idle facing flips immediately on edge turn

	if is_chasing and player:
		var dx = player.global_position.x - global_position.x
		var distance = abs(dx)
		
		# Move toward the player only if farther than attack_threshold
		if distance > attack_threshold:
			velocity.x = chase_speed * sign(dx)
			direction = 1 if velocity.x > 0 else -1
			anim.play("run")
			_update_facing() # face toward movement
		else:
			velocity.x = 0
			anim.play("idle")
			_update_facing() # keep facing the last known direction toward player

		# Attack cadence: after 0.5s within range, play a damage (hurt) animation
		# Note: This currently uses the enemy's own "damage" clip as the attack tell.
		# If you later add a true "attack" clip, just swap the name in _attack().
		if player and "is_attacking" in player and not player.is_attacking:
			player_in_range_time += delta
			if player_in_range_time >= 0.5:
				_attack()				# plays "damage" and locks animation until finished
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
		_update_facing() # face based on current direction/velocity

	# Move and detect collisions
	move_and_slide()

	# Turn around if collided with another troll (avoid pile-ups)
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var other = collision.get_collider()
		if other and other.is_in_group("troll"):
			direction *= -1
			_update_facing()
			break

func _update_facing() -> void:
	# Sprite art faces RIGHT by default.
	# We want it to face LEFT when moving/looking left.
	# If moving, use velocity.x; if idle, use 'direction'.
	var look = direction
	if abs(velocity.x) > 0.1:
		look = 1 if velocity.x > 0 else -1
	# flip_h = true means mirror horizontally (to face left)
	anim.flip_h = (look < 0)

func _attack() -> void:
	'''A small function that controls the enemy's "damage" animation sequence.
	   The is_hurting flag locks the state so other animations can't interrupt it.'''
	if is_dead or is_hurting:
		return
	is_hurting = true
	velocity.x = 0
	anim.play("damage")				# Ensure a non-looping "damage" animation exists in SpriteFrames
	await anim.animation_finished	# Wait until it completes so nothing else can overwrite it
	is_hurting = false

func _start_wandering():
	'''Function used to change the wandering flag to true to allow the troll to roam'''
	# Prevents wandering from starting while the troll is chasing
	if is_chasing or wandering:
		return
	wandering = true
	_wander_loop()

func _wander_loop() -> void:
	'''Function used to actually handle the wandering mechanics of the troll'''
	# Don't want the troll to roam if it is chasing or dead
	while not is_chasing and not is_dead:
		# Random direction
		direction = 1 if randi() % 2 == 0 else -1
		_update_facing()

		# Wander for random duration as specified at the beginning of the code
		var wander_time = randf_range(wander_min_time, wander_max_time)
		await get_tree().create_timer(wander_time).timeout

		# Idle
		velocity.x = 0
		anim.play("idle")
		_update_facing()

		# Idle for random duration as specified at the beginning of the code
		var idle_time = randf_range(idle_min_time, idle_max_time)
		await get_tree().create_timer(idle_time).timeout

	wandering = false	# Exited loop because chasing started (or died)

func _on_player_entered(body: Node):
	'''Function used to start chase mechanics by detecting what group the entered body is in'''
	var player_node = body
	if not body is CharacterBody2D and body.get_parent() and body.get_parent() is CharacterBody2D:
		player_node = body.get_parent()
	
	if player_node.is_in_group("player"):
		is_chasing = true
		player = player_node
		velocity.x = 0
		player_in_range_time = 0.0
		attack_counter = 0
		# Face toward the player immediately
		direction = 1 if (player.global_position.x - global_position.x) >= 0 else -1
		_update_facing()

func _on_player_exited(body: Node):
	'''Resets the chasing mechanics so that the troll can go back to wandering'''
	var player_node = body
	if not body is CharacterBody2D and body.get_parent() and body.get_parent() is CharacterBody2D:
		player_node = body.get_parent()
	
	if player_node.is_in_group("player"):
		is_chasing = false
		player = null
		player_in_range_time = 0.0
		_start_wandering()

func take_damage(_player_pos: Vector2):
	'''Function used to "kill" a troll, ultimately removing it from the scene tree
	   Occurs when a player attacks (i.e. the troll takes damage)'''
	var trolls = get_tree().get_nodes_in_group("troll")
	
	if is_dead:
		return

	is_dead = true
	collision_layer = 0
	collision_mask = 0
	detection_area.monitoring = false
	velocity = Vector2.ZERO

	anim.play("death")
	$DeathSound.play()
	await anim.animation_finished
	var numtrolls = trolls.size()
	numtrolls -= 1
	print(numtrolls)
	queue_free()
