extends CharacterBody3D

@export var speed: float = 4.0
@export var mouse_sensitivity: float = 0.003

# --- Ringing fade settings (KEEP THIS STRUCTURE) ---
@export var ring_start_db: float = -15.0
@export var ring_end_db: float = -60.0

# --- Footstep track settings ---
@export var step_min_db: float = -80.0      # quiet at spawn (when moving)
@export var step_max_db: float = -15.0       # loudest by z = 70 (when moving)
@export var step_idle_db: float = -80.0     # inaudible when NOT moving
@export var step_fade_speed: float = 8.0    # how fast footsteps fade in/out
@export var min_move_speed_for_steps: float = 0.2

const SPAWN_Z: float = 120.0
const RING_END_Z: float = 80.0
const FADE_DISTANCE: float = SPAWN_Z - RING_END_Z  # 40 units

const STEP_END_Z: float = 70.0
const STEP_DISTANCE: float = SPAWN_Z - STEP_END_Z  # 50 units

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

@onready var neck: Node3D = $Neck
@onready var cam: Camera3D = $Neck/Camera3D
@onready var ringing_player: AudioStreamPlayer3D = $RingingPlayer
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer

var yaw: float = 0.0
var pitch: float = 0.0

# Ringing progress tracking
var max_forward_progress: float = 0.0

# Footstep state
var moving: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Start ringing immediately
	ringing_player.volume_db = ring_start_db
	ringing_player.play()

	# Footsteps are a LOOPING TRACK:
	# - Set the stream's Loop = ON in the Inspector (AudioStream resource)
	# - Set FootstepPlayer Autoplay = OFF
	footstep_player.volume_db = step_idle_db
	footstep_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-80.0), deg_to_rad(80.0))
		rotation.y = yaw
		neck.rotation.x = pitch

func _physics_process(delta: float) -> void:
	# ------------------------
	# Movement
	# ------------------------
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

	# --- Forward progress: z decreases from 120 toward 80/70 ---
	var forward_progress: float = SPAWN_Z - global_position.z
	forward_progress = max(0.0, forward_progress)

	# Monotonic (never decreases)
	if forward_progress > max_forward_progress:
		max_forward_progress = forward_progress

	# ------------------------
	# Ringing fade (by z = 80)  <-- KEEP EXACTLY THIS STRUCTURE
	# ------------------------
	var ring_progress: float = clamp(max_forward_progress, 0.0, FADE_DISTANCE)
	var t: float = ring_progress / FADE_DISTANCE
	t = pow(t, 0.35)
	ringing_player.volume_db = lerp(ring_start_db, ring_end_db, t)

	if t >= 1.0 and ringing_player.playing:
		ringing_player.stop()

	# ------------------------
	# Footsteps: LOOPING TRACK gated by moving flag + progress-based loudness
	# ------------------------
	# 1) Monotonic loudness ramp (quiet at spawn, loudest by z=70)
	var step_progress: float = clamp(max_forward_progress, 0.0, STEP_DISTANCE)
	var s: float = step_progress / STEP_DISTANCE
	var ramp_db: float = lerp(step_min_db, step_max_db, s)

	# 2) Simple moving flag based on actual horizontal speed
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	moving = is_on_floor() and horizontal_speed > min_move_speed_for_steps

	# 3) Fade volume toward target (ramp when moving, idle when not)
	var target_db: float = ramp_db if moving else step_idle_db
	footstep_player.volume_db = lerp(
		footstep_player.volume_db,
		target_db,
		clamp(step_fade_speed * delta, 0.0, 1.0)
	)

	# Optional: pause the stream once fully faded out (uncomment if you want)
	# if (not moving) and footstep_player.volume_db <= step_idle_db + 1.0:
	#     footstep_player.stream_paused = true
	# elif moving:
	#     footstep_player.stream_paused = false
