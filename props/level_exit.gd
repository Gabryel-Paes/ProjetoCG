extends Area2D
class_name LevelExit

# --- Transição de cena ---
# Quando o Player entra aqui, troca pra outra cena inteira (não é o truque
# de camada/z_index do mezanino — é uma cena .tscn separada de verdade).

@export var target_scene: PackedScene

## Opcional: se marcado, só deixa passar com o portão já destrancado (ex: o
## alçapão do porão, que exige as chaves antes de deixar o Player cair).
@export var required_gate: KeyGate

## Opcional: exige que o Player esteja no térreo de verdade — os dois andares
## compartilham as mesmas coordenadas, então sem isso essa saída também
## dispara vindo do 2º andar, mesmo estando "embaixo" dele. Camada 7 é a
## mesma que o lobby_tutorial.gd usa pra marcar "presente no mezanino".
@export var require_ground_floor: bool = false


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	if required_gate and not required_gate.is_unlocked:
		return

	if require_ground_floor and body is CollisionObject2D and body.get_collision_layer_value(7):
		return

	if target_scene == null:
		push_warning("LevelExit sem target_scene configurada.")
		return

	# Trocar de cena na hora desmonta o Player (e quem mais estiver na cena)
	# ainda dentro do callback de física do body_entered — o Godot não deixa
	# remover um CollisionObject nesse momento. Adia pro fim do frame.
	get_tree().change_scene_to_packed.call_deferred(target_scene)
