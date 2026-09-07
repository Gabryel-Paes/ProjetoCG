extends Stalker
class_name StalkerBoss

# --- Stalker do confronto do porão ---
# Herda toda a perseguição/movimento do Stalker normal (actors/enemy/stalker.gd)
# — só troca a regra de dano: em vez de imune + lentidão, tem vida de verdade
# e pode morrer.

signal defeated()

## Pequeno empurrão ao tomar dano de verdade — o Stalker normal não tem isso
## porque não tem Health (usa `_slow_timer` no lugar de knockback).
@export var knockback_strength: float = 160.0

## Precisa ser único se um dia existir mais de um confronto assim — é o que
## o save usa pra lembrar que esse chefe já foi derrotado.
@export var save_id: String = "stalker_boss"

@onready var health: Health = $Health


func _ready() -> void:
	# Já foi derrotado num save anterior — nem chega a existir na cena.
	if save_id != "" and GameState.get_flag(save_id):
		queue_free()
		return

	super._ready()
	health.died.connect(_die)
	health.damaged.connect(_on_damaged)


func take_damage(amount: float, source_position: Vector2) -> void:
	health.apply_damage(amount, source_position)


func _on_damaged(_amount: float, source_position: Vector2) -> void:
	var push_dir := global_position - source_position
	if push_dir.length() < 0.01:
		push_dir = Vector2.RIGHT
	_knockback = push_dir.normalized() * knockback_strength


func _die() -> void:
	if save_id != "":
		GameState.set_flag(save_id, true)
	defeated.emit()
	queue_free()
