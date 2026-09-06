extends StaticBody2D
class_name SimpleDoor

@export var starts_open: bool = false

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var occluder: LightOccluder2D = $LightOccluder2D

var is_open: bool = false
var _player_in_range: Node2D = null


func _ready() -> void:
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


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null


# --- Imunidade ---
func take_damage(_amount: float, _source_position: Vector2) -> void:
	# Porta não quebra. Inimigo não tem como interagir nem destruir de propósito.
	pass
