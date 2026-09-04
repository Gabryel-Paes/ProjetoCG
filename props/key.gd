extends Area2D
class_name KeyPickup

signal collected(key_id: String)

@export var key_id: String = "chave_mezanino"


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	collected.emit(key_id)
	queue_free()
