extends StaticBody2D
class_name KeyGate

# --- Portão de múltiplas chaves ---
# Só abre quando TODAS as chaves em `required_keys` tiverem sido coletadas.
# Reaproveita o mesmo KeyPickup (key.gd) de sempre — só liga o sinal
# "collected" de cada chave nessa mesma função, uma vez por chave.

## IDs das chaves necessárias — precisa bater exatamente com o "Key Id"
## exportado em cada instância de key.tscn espalhada pelo mapa.
@export var required_keys: Array[String] = []

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var is_unlocked: bool = false
var _collected: Array[String] = []
var _player_in_range: Node2D = null


func _ready() -> void:
	label.visible = false

	# Não guarda flag própria: reconstrói quem já foi coletada olhando a
	# mesma flag que key.gd grava ("key:" + key_id) — se não tiver save
	# nenhum ainda, GameState.get_flag só devolve false pra tudo.
	for key_id in required_keys:
		if GameState.get_flag("key:" + key_id):
			_collected.append(key_id)

	if not required_keys.is_empty() and _collected.size() >= required_keys.size():
		_unlock(false)


func _on_key_collected(key_id: String) -> void:
	if is_unlocked or required_keys.is_empty():
		return

	if key_id in required_keys and not _collected.has(key_id):
		_collected.append(key_id)

	if _collected.size() >= required_keys.size():
		_unlock()
	else:
		_update_label()


func _unlock(animate: bool = true) -> void:
	is_unlocked = true
	collision.set_deferred("disabled", true)
	label.visible = false

	if sprite:
		if animate:
			var tween := create_tween()
			tween.tween_property(sprite, "modulate:a", 0.3, 0.4)
		else:
			sprite.modulate.a = 0.3 # veio de um save já destrancado — sem animação


# --- Indicador visual: quantas chaves ainda faltam ---
func _update_label() -> void:
	label.text = "Precisa de %d chaves (%d/%d)" % [required_keys.size(), _collected.size(), required_keys.size()]


func _on_info_area_body_entered(body: Node2D) -> void:
	if is_unlocked or not body.is_in_group("Player"):
		return
	_player_in_range = body
	_update_label()
	label.visible = true


func _on_info_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		label.visible = false


# --- Imunidade: portão não quebra, só abre com as chaves certas ---
func take_damage(_amount: float, _source_position: Vector2) -> void:
	pass
