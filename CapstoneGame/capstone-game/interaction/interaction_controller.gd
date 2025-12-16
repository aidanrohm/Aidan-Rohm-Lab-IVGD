# InteractionController:
# The central manager attached under the Player to handle:
# - Raycasting from the camera to find interactable notes
# - Reticle UI state (default / highlight / interacting)
# - Starting / continuing / stopping interactions based on input
# - Tracking whether a player is currently holding something
# - Displaying "press E to put away" prompt after a delay
# - Sending final note to the ending scene

extends Node

# Player node references
@onready var interaction_raycast: RayCast3D = %InteractionRaycast
@onready var hand: Marker3D = %Hand

# Note overlay pipeline
@onready var note_hand: Node3D = get_node("../Neck/SubViewportContainer/SubViewport/NoteCamera/NoteAnchor/NoteHand")
@onready var note_storage: Node3D = get_node("../Neck/SubViewportContainer/SubViewport/NoteStorage")
@onready var put_away_prompt: Label = get_node("../GUI/PutAwayPrompt")

@onready var default_reticle: TextureRect = $"../GUI/Reticle/Control/DefaultReticle"
@onready var highlight_reticle: TextureRect = $"../GUI/Reticle/Control/HighlightReticle"
@onready var interacting_reticle: TextureRect = $"../GUI/Reticle/Control/InteractingReticle"

var current_component: Node = null
var is_holding_note: bool = false

@export var put_away_prompt_delay_seconds: float = 5.0
var _time_since_collect: float = 999.0
var _prompt_shown: bool = false


func _ready() -> void:
	# Centers the reticle
	_center_reticle(default_reticle)
	_center_reticle(highlight_reticle)
	_center_reticle(interacting_reticle)

	put_away_prompt.visible = false
	_show_default()

# Input driven interaction state machine
func _process(delta: float) -> void:
	# Manage the put away timer if the player is holding a note
	if is_holding_note:
		_time_since_collect += delta

		if not _prompt_shown and _time_since_collect >= put_away_prompt_delay_seconds:
			_prompt_shown = true
			put_away_prompt.visible = true

	# Allow put away only after a delay
	if is_holding_note and current_component != null:
		if _time_since_collect >= put_away_prompt_delay_seconds and Input.is_action_just_pressed("put_away"):
			current_component.put_away()
		return
	
	# If interacting with a world item but it is not yet collected
	if current_component != null and not is_holding_note:
		if Input.is_action_pressed("primary"):
			_show_interacting()
			current_component.interact()
		else:
			current_component.post_interact()
			_disconnect_signals()
			current_component = null
			_show_default()
		return
	
	# Not interacting, using the raycast to find an interactable note
	var collider := interaction_raycast.get_collider()
	if collider == null:
		_show_default()
		return
	
	# Find the InteractionComponent by walking up parents until one is found
	var comp := _find_interaction_component(collider)
	if comp == null or not comp.can_interact:
		_show_default()
		return

	_show_highlight()
	
	# Start the interaction when the primary mouse button is pressed
	if Input.is_action_pressed("primary"):
		current_component = comp
		_connect_signals_if_needed()
		current_component.pre_interact(hand, note_hand, note_storage)
		_show_interacting()

# Signal handlers
func _on_item_collected() -> void:
	is_holding_note = true
	_time_since_collect = 0.0
	_prompt_shown = false
	put_away_prompt.visible = false
	_show_default()

func _on_item_put_away() -> void:
	# Final note -> go to ending screen
	if current_component != null and current_component.is_final_note:
		get_tree().change_scene_to_file(current_component.ending_scene_path)
		return

	is_holding_note = false
	put_away_prompt.visible = false
	_disconnect_signals()
	current_component = null
	_show_default()

# Signal wiring helpers
func _connect_signals_if_needed() -> void:
	if current_component == null:
		return
	if not current_component.is_connected("item_collected", _on_item_collected):
		current_component.connect("item_collected", _on_item_collected)
	if not current_component.is_connected("item_put_away", _on_item_put_away):
		current_component.connect("item_put_away", _on_item_put_away)

func _disconnect_signals() -> void:
	if current_component == null:
		return
	if current_component.is_connected("item_collected", _on_item_collected):
		current_component.disconnect("item_collected", _on_item_collected)
	if current_component.is_connected("item_put_away", _on_item_put_away):
		current_component.disconnect("item_put_away", _on_item_put_away)

# Helper to find the InteractionComponent
func _find_interaction_component(n: Node) -> Node:
	var cur := n
	while cur != null:
		var comp := cur.get_node_or_null("InteractionComponent")
		if comp != null:
			return comp
		cur = cur.get_parent()
	return null

# Reticle positioning and visibility helpers
func _center_reticle(reticle: TextureRect) -> void:
	if reticle == null or reticle.texture == null:
		return
	var vp: Viewport = get_viewport()
	var tex_size: Vector2 = reticle.texture.get_size()
	reticle.position = Vector2(
		vp.size.x * 0.5 - tex_size.x * 0.5,
		vp.size.y * 0.5 - tex_size.y * 0.5
	)

# Functions for showing the correct reticle based on the player's pre interaction status
func _show_default() -> void:
	default_reticle.visible = true
	highlight_reticle.visible = false
	interacting_reticle.visible = false

func _show_highlight() -> void:
	default_reticle.visible = false
	highlight_reticle.visible = true
	interacting_reticle.visible = false

func _show_interacting() -> void:
	default_reticle.visible = false
	highlight_reticle.visible = false
	interacting_reticle.visible = true
