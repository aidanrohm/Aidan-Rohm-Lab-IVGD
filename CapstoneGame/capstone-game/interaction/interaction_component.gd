# InteractionComponent:
# Handles the item iteractions for letters
# Responsibilities:
# - Detect / track when the player clicks on a note
# - Pull the note towards the player's hand marker in the world
# - When close enough, collect the note by reparenting it in the NoteHand (to give correct view)
# - Allow the note to be put away by reparenting into NoteStorage and hiding it
#		which can be used to create a diary system in future development
# - Immediately disable collision on interaction to prevent the node from getting pushed

extends Node

# Signals emitted to the InteractionController
signal item_collected
signal item_put_away

# Used enum for InteractionType for future development to make more interactions
enum InteractionType { ITEM }
@export var interaction_type: InteractionType = InteractionType.ITEM

@export var object_ref: Node3D
@export var lock_camera: bool = false

# Used for picking up the items/notes
@export var pull_speed: float = 12.0
@export var stop_distance: float = 0.15
@export var collect_distance: float = 0.18

@export var disable_collision_while_pulling: bool = true

# Render layers for the notes to be visible at specific times
@export var note_visual_layer: int = 2

# Default unless it is the last letter aka Letter5
@export var is_final_note: bool = false
@export var ending_scene_path: String = "res://scenes/EndingScreen.tscn"

# Variables for interaction
var can_interact: bool = true
var is_interacting: bool = false

var player_hand: Marker3D = null
var note_hand: Node3D = null
var note_storage: Node3D = null

var _collected: bool = false
var _put_away: bool = false

func pre_interact(hand: Marker3D, note_hand_node: Node3D, note_storage_node: Node3D) -> void:
	# If already collected do nothing
	if _collected or not can_interact:
		return
	
	# Mark the interactiona s active and cache references from the player
	is_interacting = true
	player_hand = hand
	note_hand = note_hand_node
	note_storage = note_storage_node
	
	# If the object_ref wasn't set, try to infer it
	if object_ref == null:
		object_ref = _find_staticbody_parent()
		if object_ref == null:
			object_ref = get_parent() as Node3D
	
	# Preventing a click from the player from pushing the note in the environment
	if object_ref != null and disable_collision_while_pulling:
		_disable_collision_immediately(object_ref)

# Called in each frame while the primary click is held
func interact() -> void:
	if not can_interact or not is_interacting or _collected:
		return

	_item_pull_to_hand()

# Called by the controller when the primary click is released on interaction
func post_interact() -> void:
	is_interacting = false
	player_hand = null
	note_hand = null
	note_storage = null

# Controller for putting the letter away when E is pressed
func put_away() -> void:
	if not _collected or _put_away:
		return
	if object_ref == null or note_storage == null:
		return

	_put_away = true

	var old_parent: Node = object_ref.get_parent()
	if old_parent != null:
		old_parent.remove_child(object_ref)
	note_storage.add_child(object_ref)

	_set_visual_layers_off_recursive(object_ref)

	emit_signal("item_put_away")

# Move the note to the player hand so it is visible in the view
func _item_pull_to_hand() -> void:
	if object_ref == null or player_hand == null:
		return

	var current_pos: Vector3 = object_ref.global_position
	var target_pos: Vector3 = player_hand.global_position

	var to_hand: Vector3 = target_pos - current_pos
	var dist: float = to_hand.length()

	if dist <= collect_distance:
		_collect_to_note_hand()
		return

	# Smooth pull (manual)
	object_ref.global_position = current_pos.lerp(
		target_pos,
		clamp(pull_speed * 0.02, 0.001, 0.5)
	)

# Logic for pickup, reparenting the note into the NoteHand and forcing the visual layer for the camera
func _collect_to_note_hand() -> void:
	if _collected or object_ref == null or note_hand == null:
		return

	_collected = true
	can_interact = false
	is_interacting = false

	_set_visual_layer_recursive(object_ref, note_visual_layer)

	var old_parent: Node = object_ref.get_parent()
	if old_parent != null:
		old_parent.remove_child(object_ref)
	note_hand.add_child(object_ref)

	object_ref.global_transform = note_hand.global_transform

	emit_signal("item_collected")

# Utility function
func _find_staticbody_parent() -> Node3D:
	var p: Node = get_parent()
	while p != null:
		if p is StaticBody3D:
			return p as Node3D
		p = p.get_parent()
	return null

# Collision handling to prevent physics push-back glitching
func _disable_collision_immediately(root: Node3D) -> void:
	if root is CollisionObject3D:
		var co := root as CollisionObject3D
		co.collision_layer = 0
		co.collision_mask = 0

	for c in _collect_collision_objects(root):
		c.collision_layer = 0
		c.collision_mask = 0

# Recursively gather all collision object nodes under a root
func _collect_collision_objects(root: Node) -> Array[CollisionObject3D]:
	var out: Array[CollisionObject3D] = []
	if root is CollisionObject3D:
		out.append(root)
	for ch in root.get_children():
		out.append_array(_collect_collision_objects(ch))
	return out

# Visual layer helpers specifically for the NoteCamera rendering
func _set_visual_layer_recursive(root: Node, layer_index: int) -> void:
	if root is VisualInstance3D:
		var v := root as VisualInstance3D
		v.layers = 0
		v.set_layer_mask_value(layer_index, true)
	for c in root.get_children():
		_set_visual_layer_recursive(c, layer_index)

func _set_visual_layers_off_recursive(root: Node) -> void:
	if root is VisualInstance3D:
		(root as VisualInstance3D).layers = 0
	for c in root.get_children():
		_set_visual_layers_off_recursive(c)
