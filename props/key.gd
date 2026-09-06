extends Area2D
class_name KeyPickup

signal collected(key_id: String)

@export var key_id: String = "chave_mezanino"


func _ready() -> void:
	# Já foi pega num save anterior — não reaparece.
	if GameState.get_flag(_save_flag()):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	GameState.set_flag(_save_flag(), true)
	collected.emit(key_id)
	queue_free()


func _save_flag() -> String:
	return "key:" + key_id
