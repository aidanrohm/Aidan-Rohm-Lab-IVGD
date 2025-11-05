extends Sprite2D
# Function used to handle coin collection and increase score

signal collected(value: int)

@export var value: int = 10

# Bobbing controls
@export var bob_amplitude: float = 6.0
@export var bob_period: float = 1.2

@onready var area: Area2D = $Area2D
@onready var sfx: AudioStreamPlayer2D = $CoinSound

var _start_pos: Vector2
var _bob_tween: Tween

func _ready() -> void:
	# Detect player
	area.body_entered.connect(_on_area_body_entered)
	area.monitoring = true

	# Bobbing tween (loops forever), until it is collected and freed
	_start_pos = position
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(self, "position:y", _start_pos.y - bob_amplitude, bob_period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(self, "position:y", _start_pos.y + bob_amplitude, bob_period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bob_tween.tween_property(self, "position:y", _start_pos.y, bob_period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	# Visually disappear to be collected
	visible = false

	# Stop detecting
	area.set_deferred("monitoring", false)
	var shape := area.get_node_or_null("CollisionShape2D")
	if shape:
		shape.set_deferred("disabled", true)

	# Stop bobbing
	if _bob_tween:
		_bob_tween.kill()

	# Update global score
	if has_node("/root/score_manager"):
		get_node("/root/score_manager").add(value)

	collected.emit(value)

	# Play pickup SFX then free itself from the node tree
	# Classic coin sound
	if sfx and sfx.stream:
		sfx.play()
		await sfx.finished
	else:
		await get_tree().create_timer(0.1).timeout

	queue_free()
