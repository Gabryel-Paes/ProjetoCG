extends Area2D
class_name Lever

signal toggled(is_on: bool)

@export var is_on: bool = false:
	set(value):
		is_on = value
		_update_visual()

var _player_in_range: Node2D = null


func _ready() -> void:
	_update_visual()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("Interact"):
		toggle()


func toggle() -> void:
	is_on = !is_on
	toggled.emit(is_on)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_player_in_range = body


func _on_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null


func _update_visual() -> void:
	modulate = Color.WHITE if is_on else Color(0.5, 0.5, 0.5)
