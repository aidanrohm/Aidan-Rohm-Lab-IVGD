extends CharacterBody2D

@export var speed: float = 50.0            	# Wandering speed
@export var chase_speed: float = 100.0     	# Speed when chasing player
@export var wander_min_time: float = .5		# Min time for wandering on one execute
@export var wander_max_time: float = 2.0	# Max time for wandering on one execute
@export var idle_min_time: float = .5		# Min time for idling (time after execute of wander)
@export var idle_max_time: float = 1.5		# Max time for idling (time after execute of wander)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D  # Controls which animations run
@onready var detection_area: Area2D = $DetectionArea	 # Detects when the player enters/exits

# Defaults for flagging and behavior
var is_chasing: bool = false
var player: Node2D = null # Stores a reference so the mushroom can chase the player
var wandering: bool = false
var direction: int = 1  # 1 = right, -1 = left

func _ready():
	# Connects the detection area's signals to the respective functions
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)
	
	_start_wandering() # Starts the wandering when the scene starts

func _physics_process(_delta):
	# Reset horizontal movement
	velocity.x = 0

	if is_chasing and player:
		# Move toward the player
		var dx = player.global_position.x - global_position.x
		velocity.x = chase_speed * sign(dx) 		# Move at chase speed
		direction = 1 if velocity.x > 0 else -1		# Flips the sprite/animation depending on movement direction
		anim.play("run") 							# Plays the run animation
		anim.flip_h = direction > 0  # Flip when moving left
	else:
		# Wandering behavior if it is not chasing
		velocity.x = direction * speed
		if velocity.x != 0:
			anim.play("run") # Play the run animation
			anim.flip_h = direction > 0
		else:
			anim.play("idle") # Play the idle animation

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
	# Don't want the mushroom to roam if it is meant to be chasing, flag is used here to set that
	while not is_chasing:
		# Random direction
		direction = -1 if randi() % 2 == 0 else 1

		# Wander for random duration specified at start of code
		var wander_time = randf_range(wander_min_time, wander_max_time)
		await get_tree().create_timer(wander_time).timeout

		# Idle
		velocity.x = 0
		anim.play("idle")
		# Idle for time specified at the start of code
		var idle_time = randf_range(idle_min_time, idle_max_time)
		await get_tree().create_timer(idle_time).timeout

	wandering = false  # Exited loop because chasing started

func _on_player_entered(body: Node):
	'''
	This is used to detect when a player enters the radius of a mushroom.
	If a player does enter the radius of a mushroom, the mushroom will lock on to it
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
	
	if player_node.is_in_group("player"):
		is_chasing = false
		player = null
		_start_wandering()
