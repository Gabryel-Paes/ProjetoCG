extends Area2D

var velocidade = 600
var direcao = Vector2.ZERO

func _physics_process(delta):
	# Move a bala para frente continuamente
	position += direcao * velocidade * delta

# Conecte o sinal 'body_entered' do Area2D nesta função:
func _on_body_entered(body):
	# Aqui depois faremos a lógica de dar dano no inimigo!
	queue_free() # Destrói a bala ao bater em algo

# Conecte o sinal 'timeout' do Timer nesta função:
func _on_timer_timeout():
	queue_free() # Destrói a bala pelo tempo (distância máxima)
