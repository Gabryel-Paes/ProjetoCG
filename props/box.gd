extends StaticBody2D

var health: float = 20.0

func take_damage(amount: float, _source_position: Vector2) -> void:
	health -= amount
	print("A caixa tomou dano! Vida restante: ", health)
	
	if health <= 0:
		break_box()

func break_box() -> void:
	# Aqui você pode tocar um som ou soltar partículas antes de sumir
	queue_free()
