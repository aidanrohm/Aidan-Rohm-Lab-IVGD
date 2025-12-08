# Basic player movement script

extends CharacterBody3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.003

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

@onready var neck: Node3D = $Neck
@onready var cam: Camera3D = $Neck/Camera3D

var yaw: float = 0.0      # left/right rotation
var pitch: float = 0.0    # up/down rotation

func _ready() -> void:
	# Lock the mouse to the center for FPS control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Horizontal mouse => yaw (turn body)
		yaw -= event.relative.x * mouse_sensitivity
		# Vertical mouse => pitch (look up/down)
		pitch -= event.relative.y * mouse_sensitivity

		# Clamp pitch so you can't flip over
		pitch = clamp(pitch, deg_to_rad(-80.0), deg_to_rad(80.0))

		# Apply rotations
		rotation.y = yaw           # body turns left/right
		neck.rotation.x = pitch    # neck/camera tilt up/down


func _physics_process(delta: float) -> void:
	var input_dir: Vector3 = Vector3.ZERO

	# Forward / backward
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1.0
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1.0

	# Slight sideways movement
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 0.3
	if Input.is_action_pressed("move_right"):
		input_dir.x += 0.3

	input_dir = input_dir.normalized()

	# Movement relative to where the body is facing (yaw only)
	var direction: Vector3 = (transform.basis * input_dir).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
