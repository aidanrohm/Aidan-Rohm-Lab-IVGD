extends Area2D

signal collected(value: int)

@export var value: int = 1
@onready var _sprite = $Sprite2D


func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_sprite.visible = false
		emit_signal("collected", value)
		await get_tree().create_timer(0.35).timeout
		queue_free()
