extends Area2D
class_name LevelExit

# --- Transição de cena ---
# Quando o Player entra aqui, troca pra outra cena inteira (não é o truque
# de camada/z_index do mezanino — é uma cena .tscn separada de verdade).

@export var target_scene: PackedScene


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	if target_scene == null:
		push_warning("LevelExit sem target_scene configurada.")
		return

	get_tree().change_scene_to_packed(target_scene)
