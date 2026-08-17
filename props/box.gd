extends StaticBody2D

@onready var health: Health = $Health

func _ready() -> void:
	health.died.connect(break_box)

func take_damage(amount: float, source_position: Vector2) -> void:
	health.apply_damage(amount, source_position)

func break_box() -> void:
	# Aqui você pode tocar um som ou soltar partículas antes de sumir
	queue_free()
