extends GPUParticles2D

## Script genérico pros dois efeitos de impacto (poeira de parede, sangue de
## inimigo) — dispara a explosão de partículas e se autodestrói sozinho
## assim que termina, sem precisar que quem instanciou fique cuidando disso.

func _ready() -> void:
	emitting = true
	finished.connect(queue_free)
