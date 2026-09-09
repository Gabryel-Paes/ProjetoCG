extends StaticBody2D
class_name Door

@export var requires_key: bool = true
@export var requires_power: bool = true

## Precisa ser único por porta no mapa — é o que o save usa pra lembrar que
## essa porta específica já foi destrancada (a chave e a alavanca que a
## abriram não guardam esse estado sozinhas).
@export var save_id: String = ""

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var sfx_unlock: AudioStreamPlayer2D = $SfxUnlock

var has_key: bool = false
var has_power: bool = false
var is_unlocked: bool = false


func _ready() -> void:
	if save_id == "":
		return

	if GameState.get_flag(save_id):
		_unlock(false)
		return

	# Precisa lembrar CADA pré-condição separadamente, não só o desbloqueio
	# final — senão, cumprir uma condição (pegar a chave), salvar, morrer e
	# carregar antes de cumprir a outra (resolver as alavancas) esquecia a
	# primeira pra sempre. E como a própria chave já não existe mais no
	# mundo nesse ponto (ela lembra sozinha que já foi pega, então não
	# respawna), não sobrava nenhum jeito de destrancar a porta de novo —
	# um impasse sem solução. Essas duas flags à parte resolvem isso.
	has_key = not requires_key or GameState.get_flag(save_id + ":key")
	has_power = not requires_power or GameState.get_flag(save_id + ":power")


func _on_key_collected(_key_id: String) -> void:
	has_key = true
	if save_id != "":
		GameState.set_flag(save_id + ":key", true)
	_check_unlock()


func _on_lever_puzzle_solved() -> void:
	has_power = true
	if save_id != "":
		GameState.set_flag(save_id + ":power", true)
	_check_unlock()


func _check_unlock() -> void:
	if is_unlocked:
		return
	if requires_key and not has_key:
		return
	if requires_power and not has_power:
		return

	_unlock()


func _unlock(animate: bool = true) -> void:
	is_unlocked = true
	collision.set_deferred("disabled", true)

	if sprite:
		if animate:
			var tween := create_tween()
			tween.tween_property(sprite, "modulate:a", 0.3, 0.4)
		else:
			sprite.modulate.a = 0.3 # veio de um save já destrancada — sem animação

	# Só toca o som num desbloqueio de verdade, não ao restaurar de um save
	# que já estava destrancado (senão apitava sozinha toda vez que a cena
	# carregasse).
	if animate:
		sfx_unlock.play()

	if save_id != "":
		GameState.set_flag(save_id, true)
