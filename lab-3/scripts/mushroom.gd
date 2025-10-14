extends CharacterBody2D

@export var speed: float = 50.0            	# Wandering speed
@export var chase_speed: float = 100.0     	# Speed when chasing player
@export var wander_min_time: float = 0.5	# Min time for wandering on one execute
@export var wander_max_time: float = 2.0	# Max time for wandering on one execute
@export var idle_min_time: float = 0.5		# Min time for idling (time after execute of wander)
@export var idle_max_time: float = 1.5		# Max time for idling (time after execute of wander)
@export var attack_threshold: float = 50.0  # Distance to stop running toward player

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D  	# Controls which animations run
@onready var detection_area: Area2D = $DetectionArea	 	# Detects when the player enters/exits
@onready var edge_ray: RayCast2D = $EdgeRay				# Detects platform edges

# Defaults for flagging and behavior
var is_chasing: bool = false
var player: Node2D = null # Stores a reference so the mushroom can chase the player
var wandering: bool = false
var direction: int = 1  # 1 = right, -1 = left
var is_damaged: bool = false # Flag so mushroom doesn’t double-trigger the damage animation
var is_dead: bool = false # Flag for death state

# Add gravity
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

	# Stop everything if dead
	if is_dead:
		queue_free()
		return

	# Don’t move while damaged
	if is_damaged:
		move_and_slide()
		return

	# Update edge ray to always be in front of mushroom
	edge_ray.position.x = direction * abs(edge_ray.position.x)

	# Reset horizontal movement
	velocity.x = 0

	# Edge detection: turn around if no ground in front
	if not edge_ray.is_colliding() and not is_damaged:
		direction *= -1

	if is_chasing and player:
		# Move toward the player only if farther than attack_threshold
		var dx = player.global_position.x - global_position.x
		var distance = abs(dx)
		
		if distance > attack_threshold:
			velocity.x = chase_speed * sign(dx)
			direction = 1 if velocity.x > 0 else -1
			if not is_damaged:
				anim.play("run")
				anim.flip_h = velocity.x > 0  # Correct facing for sprite facing left by default
		else:
			velocity.x = 0
			if not is_damaged:
				anim.play("idle") # Stop running when close to player
	else:
		# Wandering behavior if not chasing
		velocity.x = direction * speed
		if velocity.x != 0 and not is_damaged:
			anim.play("run")
			anim.flip_h = velocity.x > 0  # Correct facing for sprite facing left by default
		elif not is_damaged:
			anim.play("idle")

	# Move and detect collisions
	move_and_slide()

	# Turn around if collided with wall/boundary or another mushroom
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var other = collision.get_collider()
		
		if other.is_in_group("mushroom") or other.is_in_group("boundary"):
			direction *= -1 # Mushroom flips direction if it collides with a wall/other mushroom
			break

func _start_wandering():
	# Prevents wandering from starting while the mushroom is chasing
	if is_chasing or wandering:
		return
	wandering = true
	_wander_loop()

func _wander_loop() -> void:
	# Don't want the mushroom to roam if it is chasing
	while not is_chasing and not is_dead:
		# Random direction
		direction = -1 if randi() % 2 == 0 else 1

		# Wander for random duration as specified at the beginning of the code
		var wander_time = randf_range(wander_min_time, wander_max_time)
		await get_tree().create_timer(wander_time).timeout

		# Idle
		velocity.x = 0
		if not is_damaged:
			anim.play("idle")
			
		# Idle for random duration as specified at the beginning of the code
		var idle_time = randf_range(idle_min_time, idle_max_time)
		await get_tree().create_timer(idle_time).timeout

	wandering = false  # Exited loop because chasing started

func _on_player_entered(body: Node):
	'''
	This is used to detect when a player enters the radius of a mushroom.
	If a player does enter the area, the mushroom will lock on to it.
	'''
	var player_node = body
	# If a child enters the area, use parent if it's a CharacterBody2D
	if not body is CharacterBody2D and body.get_parent() and body.get_parent() is CharacterBody2D:
		player_node = body.get_parent()
	
	# Chase if the object is in the "player" group
	if player_node.is_in_group("player"):
		is_chasing = true
		player = player_node
		velocity.x = 0

func _on_player_exited(body: Node):
	# Triggered when the player exits the detection radius of the mushroom
	var player_node = body
	if not body is CharacterBody2D and body.get_parent() and body.get_parent() is CharacterBody2D:
		player_node = body.get_parent()
	
	# Mushroom will continue to wandering/patrolling the area
	if player_node.is_in_group("player"):
		is_chasing = false
		player = null
		_start_wandering()

# Called by Player when attack lands
func take_damage(_player_pos: Vector2):
	'''
	This triggers when the player’s attack hits the mushroom.
	Plays damage animation first. Once complete, plays death animation and despawns.
	'''
	if is_dead or is_damaged:
		return

	# Play damage animation
	is_damaged = true
	anim.play("damage")
	await anim.animation_finished
	is_damaged = false

	# Begin death sequence
	is_dead = true
	anim.play("death")
	await anim.animation_finished
	queue_free()
