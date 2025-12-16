extends Node

@onready var interaction_raycast: RayCast3D = %InteractionRaycast
@onready var player_camera: Camera3D = %Camera3D
@onready var hand: Marker3D = %Hand

@onready var default_reticle: TextureRect = $"../GUI/Reticle/Control/DefaultReticle"
@onready var highlight_reticle: TextureRect = %HighlightReticle
@onready var interacting_reticle: TextureRect = %InteractingReticle

var current_object: Node = null
var interaction_component: Node = null


func _ready() -> void:
	_center_reticle(default_reticle)
	_center_reticle(highlight_reticle)
	_center_reticle(interacting_reticle)

	_show_default()


func _process(_delta: float) -> void:
	# --- If currently interacting, keep interacting while held ---
	if current_object != null and interaction_component != null:
		if Input.is_action_pressed("primary"):
			# Show "interacting" reticle while holding
			_show_interacting()
			interaction_component.interact()
		else:
			# Released primary -> end interaction
			interaction_component.post_interact()
			current_object = null
			interaction_component = null
			_show_default()
		return

	# --- Not interacting: raycast for potential item ---
	var collider := interaction_raycast.get_collider()
	if collider == null or not (collider is Node):
		_show_default()
		return

	var potential_object := collider as Node
	var potential_component := potential_object.get_node_or_null("InteractionComponent")
	if potential_component == null:
		_show_default()
		return

	# If component exists but says "no"
	if not potential_component.can_interact:
		_show_default()
		return

	# We can focus it
	_show_highlight()

	# Start interaction if primary is held
	if Input.is_action_pressed("primary"):
		current_object = potential_object
		interaction_component = potential_component
		interaction_component.pre_interact(hand)
		_show_interacting()


func isCameraLocked() -> bool:
	# Maintains your prior behavior: lock only while actively interacting
	if interaction_component != null:
		return interaction_component.lock_camera and interaction_component.is_interacting
	return false


func _center_reticle(reticle: TextureRect) -> void:
	if reticle == null or reticle.texture == null:
		return
	var vp := get_viewport()
	var tex_size := reticle.texture.get_size()
	reticle.position = Vector2(
		vp.size.x * 0.5 - tex_size.x * 0.5,
		vp.size.y * 0.5 - tex_size.y * 0.5
	)


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
