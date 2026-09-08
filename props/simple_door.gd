extends StaticBody2D
class_name SimpleDoor

@export var starts_open: bool = false

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var occluder: LightOccluder2D = $LightOccluder2D
@onready var label: Label = $Label # Referência ao nó Label

var is_open: bool = false
var _player_in_range: Node2D = null


func _ready() -> void:
	label.visible = false # Esconde a mensagem ao iniciar
	
	if starts_open:
		_open()
	else:
		_close()


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("Interact"):
		toggle()


func toggle() -> void:
	if is_open:
		_close()
	else:
		_open()
	_update_label() # Atualiza o texto imediatamente após abrir/fechar


func _open() -> void:
	is_open = true
	collision.set_deferred("disabled", true)
	occluder.visible = false # luz passa livre com a porta aberta
	if sprite:
		sprite.modulate.a = 0.3


func _close() -> void:
	is_open = false
	collision.set_deferred("disabled", false)
	occluder.visible = true # fechada = bloqueia luz igual uma parede
	if sprite:
		sprite.modulate.a = 1.0


func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_player_in_range = body
		_update_label()
		label.visible = true # Exibe a mensagem quando o jogador chega perto


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		label.visible = false # Esconde a mensagem quando o jogador se afasta


# Atualiza o texto dinamicamente dependendo do estado da porta
func _update_label() -> void:
	if is_open:
		label.text = "[E] Fechar"
	else:
		label.text = "[E] Abrir"


# --- Imunidade ---
func take_damage(_amount: float, _source_position: Vector2) -> void:
	# Porta não quebra. Inimigo não tem como interagir nem destruir de propósito.
	pass
