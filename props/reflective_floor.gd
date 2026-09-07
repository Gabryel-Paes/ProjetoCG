extends Area2D
class_name ReflectiveFloor

# --- Piso refletivo (poça/espelho) ---
# Não desenha o piso em si — isso já é um tile normal do mapa, escolhido só
# por parecer molhado/polido na arte. Esse nó apenas liga/desliga um
# "fantasma" espelhado do Player por cima do tile quando ele passa perto.
#
# O reflexo vem ao vivo do MirrorViewport dentro do próprio player.tscn (uma
# câmera que só enxerga o Player, sem rotacionar com a mira) — assim pega
# pernas, arma equipada e golpe de faca automaticamente, sem precisar
# duplicar sprite por sprite aqui.
#
# O ReflectionSprite (ver .tscn) fica em "Visibility Layer 2" de propósito —
# essa camada some só pra MirrorViewport (configurado em player.gd), senão
# ela tentaria desenhar a própria textura dentro dela mesma.

@export var reflection_offset: Vector2 = Vector2(0, 10) # o quanto abaixo do Player o reflexo aparece
@export var reflection_alpha: float = 0.35
@export var wobble_amount: float = 2.0 # leve distorção horizontal, pra não parecer um decalque perfeito
@export var wobble_speed: float = 1.5

@onready var sprite: Sprite2D = $ReflectionSprite

var _player: Node2D = null
var _time: float = 0.0


func _ready() -> void:
	sprite.visible = false
	sprite.flip_v = true
	sprite.modulate.a = reflection_alpha


func _process(delta: float) -> void:
	if _player == null:
		return

	_time += delta
	var wobble := sin(_time * wobble_speed) * wobble_amount
	sprite.global_position = Vector2(_player.global_position.x + wobble, _player.global_position.y) + reflection_offset


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	_player = body
	if body.has_node("MirrorViewport"):
		sprite.texture = body.get_node("MirrorViewport").get_texture()
	sprite.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
		sprite.visible = false
