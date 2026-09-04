extends StaticBody2D
class_name Door

@export var requires_key: bool = true
@export var requires_power: bool = true

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var has_key: bool = false
var has_power: bool = false
var is_unlocked: bool = false


func _on_key_collected(_key_id: String) -> void:
	has_key = true
	_check_unlock()


func _on_lever_puzzle_solved() -> void:
	has_power = true
	_check_unlock()


func _check_unlock() -> void:
	if is_unlocked:
		return
	if requires_key and not has_key:
		return
	if requires_power and not has_power:
		return

	_unlock()


func _unlock() -> void:
	is_unlocked = true
	collision.set_deferred("disabled", true)

	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.3, 0.4)
