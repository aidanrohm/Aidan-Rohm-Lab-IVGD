extends Node

signal item_collected(item_node: Node)

# Only one interaction type exists in your game now.
enum InteractionType { ITEM }

@export var interaction_type: InteractionType = InteractionType.ITEM

# Point this to the ITEM node (your StaticBody3D) or a Node3D parent that visually represents it.
@export var object_ref: Node3D

# Keeps compatibility with your controller's isCameraLocked()
@export var lock_camera: bool = false

# "Pull" tuning (manual movement, not physics)
@export var pull_speed: float = 12.0          # higher = snappier
@export var stop_distance: float = 0.12       # how close to hand before "collect" triggers
@export var disable_collision_while_held: bool = true

# Optional pickup sound
@export var pickup_sound: AudioStream
@export var sound_volume_db: float = -6.0

var can_interact: bool = true
var is_interacting: bool = false
var player_hand: Marker3D = null

var _collected: bool = false
var _saved_layer: int = 0
var _saved_mask: int = 0
var _pickup_player: AudioStreamPlayer3D


func _ready() -> void:
	_pickup_player = AudioStreamPlayer3D.new()
	add_child(_pickup_player)
	_pickup_player.bus = "Master"
	_pickup_player.volume_db = sound_volume_db


# Run once when the player first clicks
func pre_interact(hand: Marker3D) -> void:
	if _collected:
		return
	is_interacting = true
	player_hand = hand

	# Optional: disable collisions while held so it doesn't block raycasts
	if disable_collision_while_held:
		_set_item_collision_enabled(false)


# Run every frame while holding primary
func interact() -> void:
	if _collected or not can_interact or not is_interacting:
		return

	_pull_to_hand_and_collect_if_close()


# Runs once when the player last interacts with an object
func post_interact() -> void:
	is_interacting = false
	player_hand = null

	# If we didn't collect, restore collision
	if disable_collision_while_held and not _collected:
		_set_item_collision_enabled(true)


func _pull_to_hand_and_collect_if_close() -> void:
	if object_ref == null or player_hand == null:
		return

	var current_pos: Vector3 = object_ref.global_position
	var target_pos: Vector3 = player_hand.global_position
	var to_target: Vector3 = target_pos - current_pos
	var dist: float = to_target.length()

	# Close enough -> collect
	if dist <= stop_distance:
		object_ref.global_position = target_pos
		_collect_item()
		return

	# Move toward hand (frame-rate independent)
	var step: float = pull_speed * get_process_delta_time()
	object_ref.global_position = current_pos + to_target.normalized() * min(step, dist)


func _collect_item() -> void:
	if _collected:
		return
	_collected = true
	is_interacting = false
	can_interact = false

	# Keep collisions off so it can't be picked again (even for the brief frame before free)
	if disable_collision_while_held:
		_set_item_collision_enabled(false)

	_play_pickup_sound()

	# Match the original pattern: emit a signal for game/inventory logic,
	# then remove the item from the world.
	emit_signal("item_collected", get_parent())
	get_parent().queue_free()


func _play_pickup_sound() -> void:
	if pickup_sound == null:
		return
	_pickup_player.stream = pickup_sound
	_pickup_player.play()


func _set_item_collision_enabled(enabled: bool) -> void:
	var static_body := object_ref as StaticBody3D
	if static_body == null:
		return

	# Save the original layers/masks once
	if _saved_layer == 0 and _saved_mask == 0:
		_saved_layer = static_body.collision_layer
		_saved_mask = static_body.collision_mask

	if enabled:
		static_body.collision_layer = _saved_layer
		static_body.collision_mask = _saved_mask
	else:
		static_body.collision_layer = 0
		static_body.collision_mask = 0

	# Toggle any CollisionShape3D children too
	for child in static_body.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = not enabled
