extends Node
class_name Health

signal died
signal health_changed(current: float, max: float)
## Emitido a cada acerto (mesmo que não mate), com de onde veio o golpe —
## quem escuta (ex: player.gd) pode usar isso pra aplicar knockback.
signal damaged(amount: float, source_position: Vector2)

@export var max_health: float = 20.0

var current_health: float


func _ready() -> void:
	current_health = max_health


func apply_damage(amount: float, source_position: Vector2 = Vector2.ZERO) -> void:
	if current_health <= 0.0:
		return

	current_health = max(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	damaged.emit(amount, source_position)

	if current_health <= 0.0:
		died.emit()
