# A script to impact the way the letter moves when it is in hand
# When the player moves left/right the letter will tilt in the respective direction
# When the player moves forward/back the letter will tilt in the respective direction

extends Node3D

@export var camera_path: NodePath

# Input actions
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_forward_action: StringName = &"move_forward"
@export var move_back_action: StringName = &"move_back"

# Max tilt angles (degrees)
@export var max_roll_deg: float = 10.0   # left/right
@export var max_pitch_deg: float = 8.0   # forward/back

# Responsiveness
@export var follow_speed: float = 12.0
@export var return_speed: float = 16.0

# Only sway when holding something
@export var sway_only_when_holding: bool = true

# Idle bob (only when NOT moving)
@export var idle_bob_strength_deg: float = 0.6
@export var idle_bob_speed: float = 2.0

var _cam: Camera3D = null
var _base_rot: Vector3 = Vector3.ZERO
var _t: float = 0.0


func _ready() -> void:
	_base_rot = rotation
	if camera_path != NodePath():
		_cam = get_node(camera_path) as Camera3D


func _process(delta: float) -> void:
	if sway_only_when_holding and get_child_count() == 0:
		var a_return: float = clampf(delta * return_speed, 0.0, 1.0)
		rotation = rotation.lerp(_base_rot, a_return)
		return

	_t += delta

	# Movement intent
	var move_vec: Vector2 = Input.get_vector(
		move_left_action,
		move_right_action,
		move_forward_action,
		move_back_action
	)

	var moving: bool = move_vec.length() > 0.001
	
	var roll_deg: float = -max_roll_deg * move_vec.x
	var pitch_deg: float = max_pitch_deg * move_vec.y

	var target_roll: float = deg_to_rad(roll_deg)
	var target_pitch: float = deg_to_rad(pitch_deg)

	# Idle wobble only when not moving
	if not moving:
		var idle_roll: float = deg_to_rad(idle_bob_strength_deg) * sin(_t * idle_bob_speed)
		var idle_pitch: float = deg_to_rad(idle_bob_strength_deg * 0.7) * cos(_t * idle_bob_speed * 0.9)
		target_roll += idle_roll
		target_pitch += idle_pitch

	var target_rot: Vector3 = _base_rot
	target_rot.z += target_roll   # Roll (L/R)
	target_rot.x += target_pitch  # Pitch (F/B)

	var a_follow: float = clampf(delta * follow_speed, 0.0, 1.0)
	rotation = rotation.lerp(target_rot, a_follow)
