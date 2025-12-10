extends Node3D

@onready var player: CharacterBody3D = get_node("../Player")
@onready var sun: DirectionalLight3D = get_node("../DirectionalLight3D")

@export var start_z: float = 120.0
@export var end_z: float = -120.0

var progress: float = 0.0

var sun_start_rot := Vector3(-5.0, 180.0, 0.0) # in front
var sun_mid_rot   := Vector3(-90.0, 90.0, 0.0) # overhead
var sun_end_rot   := Vector3(-175.0, 0.0, 0.0) # behind

func _process(_delta: float) -> void:
	# 1) Compute progress along Z
	var t: float = (player.position.z - start_z) / (end_z - start_z)
	progress = clamp(t, 0.0, 1.0)

	# 2) Rotate sun based on that progress
	if progress <= 0.5:
		sun.rotation_degrees = sun_start_rot.lerp(sun_mid_rot, progress * 2.0)
	else:
		sun.rotation_degrees = sun_mid_rot.lerp(sun_end_rot, (progress - 0.5) * 2.0)

	# DEBUG: print to confirm it's changing
	print("z:", player.position.z, " progress:", progress, " sun:", sun.rotation_degrees)
