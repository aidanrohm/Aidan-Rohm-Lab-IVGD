# Player controller:
# - WASD / Arrow key movement 
# - Mouse look (yaw/pitch)
# - Ringing audio that fades out as the player progresses forward
# - Footsteps that loop and play based on player movement status
# - Camera headbob while walking
extends CharacterBody3D

@export var speed: float = 4.0 					# Player movement speed
@export var mouse_sensitivity: float = 0.0015	# Mouse look sensitivity

@export var ring_start_db: float = -15.0		# Louder at spawn
@export var ring_end_db: float = -60.0			# Finishing volume to turn it off

@export var min_move_speed_for_steps: float = 0.2	# Minimum speed for step sound to play/bobbing

# Forward progress / ring fade geometry
const SPAWN_Z: float = 120.0
const RING_END_Z: float = 80.0
const FADE_DISTANCE: float = SPAWN_Z - RING_END_Z

# Head bob settings
@export var head_bob_speed: float = 14.0
@export var head_bob_intensity: float = 0.08
@export var bob_lerp_speed: float = 10.0

@export var sensitivity_restore_speed: float = 5.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

# Node references
@onready var neck: Node3D = $Neck
@onready var cam: Camera3D = $Neck/Camera3D
@onready var ringing_player: AudioStreamPlayer3D = $RingingPlayer
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@onready var interaction_controller: Node = get_node_or_null("InteractionController")

# Look variables
var yaw: float = 0.0
var pitch: float = 0.0

# Ringing progress tracking
var max_forward_progress: float = 0.0

# Footstep state
var moving: bool = false
var was_moving: bool = false

# Headbob state
var head_bob_index: float = 0.0
var head_bob_vec: Vector2 = Vector2.ZERO
var cam_base_local_pos: Vector3

# Sensitivity gating
var normal_sensitivity: float = 1.0
var current_sensitivity: float = 1.0
var sensitivity_fading_in: bool = false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	cam_base_local_pos = cam.position

	# Start ringing immediately
	ringing_player.volume_db = ring_start_db
	ringing_player.play()

	# Footsteps setup (manual start/stop)
	footstep_player.stop()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if interaction_controller != null and interaction_controller.has_method("isCameraLocked"):
			if interaction_controller.call("isCameraLocked"):
				return
		
		# Effective mouse sensitivity and clamping to avoid spinning view
		var sens := mouse_sensitivity * current_sensitivity
		yaw -= event.relative.x * sens
		pitch -= event.relative.y * sens
		pitch = clamp(pitch, deg_to_rad(-80.0), deg_to_rad(80.0))
		
		# Apply rotations
		rotation.y = yaw
		neck.rotation.x = pitch


func _physics_process(delta: float) -> void:
	# Movement
	var input_dir: Vector3 = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1.0
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 0.3
	if Input.is_action_pressed("move_right"):
		input_dir.x += 0.3

	input_dir = input_dir.normalized()
	var direction: Vector3 = (transform.basis * input_dir).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	
	# Moving flag
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	moving = is_on_floor() and horizontal_speed > min_move_speed_for_steps

	# Headbob
	_update_headbob(delta)

	# Ringing fade
	var forward_progress: float = SPAWN_Z - global_position.z
	forward_progress = max(0.0, forward_progress)

	if forward_progress > max_forward_progress:
		max_forward_progress = forward_progress

	var ring_progress: float = clamp(max_forward_progress, 0.0, FADE_DISTANCE)
	var t: float = ring_progress / FADE_DISTANCE
	t = pow(t, 0.35)
	ringing_player.volume_db = lerp(ring_start_db, ring_end_db, t)

	if t >= 1.0 and ringing_player.playing:
		ringing_player.stop()

	# Footsteps
	if moving and not was_moving:
		footstep_player.play()
	elif not moving and was_moving:
		footstep_player.stop()

	was_moving = moving


func _process(delta: float) -> void:
	# Ease back to normal sensitivity after camera lock
	if sensitivity_fading_in:
		current_sensitivity = lerp(
			current_sensitivity,
			normal_sensitivity,
			delta * sensitivity_restore_speed
		)
		# Snap when close enough to avoid endless adjustments
		if abs(current_sensitivity - normal_sensitivity) < 0.01:
			current_sensitivity = normal_sensitivity
			sensitivity_fading_in = false

	if interaction_controller != null and interaction_controller.has_method("isCameraLocked"):
		_set_camera_locked(interaction_controller.call("isCameraLocked") as bool)
	else:
		_set_camera_locked(false)

# Toggle the sensitivity multiplier based on the lock state
func _set_camera_locked(locked: bool) -> void:
	if locked:
		current_sensitivity = 0.0
		sensitivity_fading_in = false
	else:
		if current_sensitivity < normal_sensitivity:
			sensitivity_fading_in = true

# Helper function for the headbobbing
func _update_headbob(delta: float) -> void:
	head_bob_index += head_bob_speed * delta
	head_bob_vec.y = sin(head_bob_index)
	head_bob_vec.x = sin(head_bob_index / 2.0)

	var target_local: Vector3 = cam_base_local_pos
	if moving:
		target_local.y += head_bob_vec.y * (head_bob_intensity * 0.5)
		target_local.x += head_bob_vec.x * head_bob_intensity
	
	# Smoothly interpolate the camera so that it avoids any jitter
	cam.position = cam.position.lerp(target_local, delta * bob_lerp_speed)
