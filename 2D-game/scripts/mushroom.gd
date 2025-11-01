extends CharacterBody2D


# -- BELOW ARE NECESSARY VARIABLES FOR MUSHROOM ACTIVITY -- #
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
@onready var edge_ray: RayCast2D = $EdgeRay					# Detects platform edges to keep mushrooms on platform

# Defaults for flagging and behavior
var is_chasing: bool = false			# Whether or not the mushroom is chasing
var wandering: bool = false				# Whether or not the mushroom is wandering
var player: Node2D = null				# Stores a reference so the mushroom can chase the player
var direction: int = 1					# 1 = right, -1 = left
var is_dead: bool = false				# Flag for death state
var attack_counter: int = 0				# Tracks number of attacks made on player
var player_in_range_time: float = 0.0	# Timer for player being in range

# Add gravity for mushroom functionality
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

	# Reset horizontal movement
	velocity.x = 0

	# Edge detection used to turn around if no platform is in front of the mushroom
	if not edge_ray.is_colliding() and not is_dead:
		direction *= -1

	if is_chasing and player:
		var dx = player.global_position.x - global_position.x
		var distance = abs(dx)
		
		# Move toward the player only if farther than attack_threshold
		# Otherwise, play the idle animation
		# Hoping to modify if I can get a mushroom sprite that has an attack animation
		if distance > attack_threshold:
			velocity.x = chase_speed * sign(dx)
			direction = 1 if velocity.x > 0 else -1
			if not is_dead:
				anim.play("run")
				anim.flip_h = velocity.x > 0
		else:
			velocity.x = 0
			if not is_dead:
				anim.play("idle")	# Stop running when close to player

		# The attack mechanic so that the mushroom can deal damage to the player
		if player and "is_attacking" in player and not player.is_attacking:
			player_in_range_time += delta
			if player_in_range_time >= 0.5: 						# Attack if the player has been in range for at least .5 seconds
				_flash_red() 				 						# Flash red to indicate attack
				player_in_range_time = 0.0 							# Reset the attack timer
				attack_counter += 1									# Increment the attack counter
				if attack_counter >= 2 and "lose_life" in player:	# 2 attacks = 1 life lost
					player.lose_life()  							# Player loses life
					attack_counter = 0								# Reset attack counter
		else:
			player_in_range_time = 0.0								# Reset attack timer

	else:
		player_in_range_time = 0.0  		# Reset if player leaves
		
		# Wandering behavior if not chasing
		velocity.x = direction * speed
		if velocity.x != 0 and not is_dead:
			anim.play("run")
			anim.flip_h = velocity.x > 0	# Correct facing for sprite facing left by default
		elif not is_dead:
			anim.play("idle")

	# Move and detect collisions
	move_and_slide()

	# Turn around if collided with wall or another mushroom
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var other = collision.get_collider()
		
		if other.is_in_group("mushroom"):
			direction *= -1	# Mushroom flips direction if it collides with another mushroom
			break

func _flash_red():
	"""A small function to allow the mushroom to flash red when it is going to attack"""
	var original_color = anim.modulate
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color(1,0,0), 0.15)
	tween.tween_property(anim, "modulate", original_color, 0.15)

func _start_wandering():
	'''Function used to change the wandering flag to true to allow the mushroom to roam'''
	# Prevents wandering from starting while the mushroom is chasing
	if is_chasing or wandering:
		return
	wandering = true
	_wander_loop()

func _wander_loop() -> void:
	'''Function used to actually handle the wandering mechanics of the mushroom'''
	# Don't want the mushroom to roam if it is chasing
	while not is_chasing and not is_dead:
		# Random direction
		direction = -1 if randi() % 2 == 0 else 1

		# Wander for random duration as specified at the beginning of the code
		var wander_time = randf_range(wander_min_time, wander_max_time)
		await get_tree().create_timer(wander_time).timeout

		# Idle
		velocity.x = 0
		if not is_dead:
			anim.play("idle")
			
		# Idle for random duration as specified at the beginning of the code
		var idle_time = randf_range(idle_min_time, idle_max_time)
		await get_tree().create_timer(idle_time).timeout

	wandering = false	# Exited loop because chasing started

func _on_player_entered(body: Node):
	'''Function used to start chse mechanics by detecting what group the entered body is in'''
	var player_node = body
	if not body is CharacterBody2D and body.get_parent() and body.get_parent() is CharacterBody2D:
		player_node = body.get_parent()
	
	if player_node.is_in_group("player"):
		is_chasing = true
		player = player_node
		velocity.x = 0
		player_in_range_time = 0.0
		attack_counter = 0

func _on_player_exited(body: Node):
	'''Resets the chasing mechanics so that the mushroom can go back to wandering'''
	var player_node = body
	if not body is CharacterBody2D and body.get_parent() and body.get_parent() is CharacterBody2D:
		player_node = body.get_parent()
	
	if player_node.is_in_group("player"):
		is_chasing = false
		player = null
		player_in_range_time = 0.0
		_start_wandering()

func take_damage(_player_pos: Vector2):
	'''Function used to "kill" a mushroom, ultimately removing it from the scene tree
	   Occurs when a player attacks (i.e. the mushroom takes damage)
	'''
	
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
	queue_free()
