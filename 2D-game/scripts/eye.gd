extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D					# Used to control the animations played
@onready var hitbox: Area2D = $Hitbox                      				# Used to detect hits
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D	# Hitbox shape itself

var is_dead: bool = false

func _ready() -> void:
	# Start the flight animation
	if anim:
		anim.play("flight")
		# Listen for animation end to know when to free after "death"
		anim.animation_finished.connect(_on_animation_finished)

func take_damage(_from: Vector2 = Vector2.ZERO) -> void:
	# Similar functionality to the troll death
	if is_dead:
		return
	is_dead = true

	# Stop any motion
	velocity = Vector2.ZERO
	set_physics_process(false)     
	set_process(false)

	# Make the eye no longer hittable
	_disable_collisions()

	# Play death animation
	if anim:
		anim.play("death")
		$DeathSound.play()
	else:
		queue_free()   			# Fallback	

# Disable collisions so we don't take multiple hits while dying
func _disable_collisions() -> void:
	# Turn off CharacterBody2D collisions completely
	collision_layer = 0
	collision_mask  = 0

	# Turn off the Area2D hitbox and its shape
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
	if hitbox_shape:
		hitbox_shape.disabled = true

# Function used to remove the eye from the scene tree when the death animation finishes properly
func _on_animation_finished() -> void:
	if anim.animation == "death":
		queue_free()



	
