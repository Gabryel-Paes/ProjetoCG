extends StaticBody2D
class_name SaveTypewriter

# --- Máquina de inscrever ---
# Sem tela, sem confirmação: interagir já salva na hora, sempre por cima do
# mesmo save (GameState cuida do slot único). Só um feedback visual rápido
# pra você saber que funcionou.

signal saved()

@onready var sprite: Sprite2D = $Sprite2D

var _player_in_range: Node2D = null


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("Interact"):
		_save()


func _save() -> void:
	GameState.save_game()
	saved.emit()

	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1.6, 1.6, 1.6), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)


func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_player_in_range = body


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null


# --- Imunidade: mesma convenção de todo prop imóvel do jogo ---
func take_damage(_amount: float, _source_position: Vector2) -> void:
	pass
