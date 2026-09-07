extends Area2D
class_name NudgeOnApproach

# --- Empurrão ao se aproximar ---
# Componente reutilizável: quando o Player entra nessa área, dá um "empurrão"
# visual (só um Tween, sem física de verdade) no nó apontado por
# "visual_path", na direção que ele veio, e volta sozinho pro lugar.
#
# Serve tanto pra decoração andável — folhas, papel espalhado no chão, onde
# o Player nem precisa colidir, só passar por cima e elas reagem — quanto
# pra itens largados: aí o Player também pode "chutar" de propósito, andando
# na direção deles. Mesmo componente, dois usos.
#
## Caminho (relativo a este nó) até o Node2D que deve ser empurrado —
## normalmente o Sprite2D irmão que já existe na cena onde isso for colocado.
@export var visual_path: NodePath = ^"../Sprite2D"
@export var push_distance: float = 6.0
@export var push_out_time: float = 0.15
@export var return_time: float = 0.5
@export var wobble_deg: float = 10.0

@onready var visual: Node2D = get_node(visual_path)

var _tween: Tween = null


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	# CharacterBody2D.velocity é de verdade do motor (não script) — dá pra
	# tipar direto, sem o truque de acesso dinâmico que usamos pra
	# variáveis customizadas de player.gd.
	var player_body := body as CharacterBody2D
	var push_dir: Vector2

	if player_body and player_body.velocity.length() > 1.0:
		push_dir = player_body.velocity.normalized() # empurra pra onde o Player estava indo
	else:
		push_dir = (global_position - body.global_position).normalized() # parado: empurra pra longe dele

	if push_dir == Vector2.ZERO:
		push_dir = Vector2.RIGHT

	_nudge(push_dir)


func _nudge(push_dir: Vector2) -> void:
	# Mata o tween anterior em vez de deixar acumular — sem isso, passar
	# várias vezes rápido deixa o movimento acelerado/errático.
	if _tween and _tween.is_valid():
		_tween.kill()

	var side := 1.0 if randf() > 0.5 else -1.0

	_tween = create_tween()
	_tween.tween_property(visual, "position", push_dir * push_distance, push_out_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(visual, "rotation", deg_to_rad(wobble_deg) * side, push_out_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_tween.tween_property(visual, "position", Vector2.ZERO, return_time) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(visual, "rotation", 0.0, return_time) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
