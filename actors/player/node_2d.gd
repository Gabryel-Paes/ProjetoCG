extends Node2D

@export var raio_alcance: float = 350.0
@export var angulo_abertura: float = PI / 3.0
@export var resolucao_raios: int = 90 
@export var cor_luz := Color(0.979, 0.945, 0.911, 0.6) 

var pontos_poligono := PackedVector2Array()

func _physics_process(_delta: float) -> void:
	_calcular_malha_visibilidade()
	queue_redraw()

func _calcular_malha_visibilidade() -> void:
	pontos_poligono.clear()
	
	pontos_poligono.append(Vector2.ZERO)

	# Acesso direto ao estado da física
	var espaco_fisico := get_world_2d().direct_space_state
	var origem_global := global_position
	var rotacao_global := global_rotation
	
	# Define os limites do cone de luz
	var angulo_inicial := -angulo_abertura / 2.0
	var incremento_angular := angulo_abertura / float(resolucao_raios - 1)

	#Ray Casting
	for i in range(resolucao_raios):
		var angulo_relativo := angulo_inicial + (i * incremento_angular)
		var angulo_absoluto := rotacao_global + angulo_relativo
		
		var direcao := Vector2(cos(angulo_absoluto), sin(angulo_absoluto))
		var destino_global := origem_global + (direcao * raio_alcance)
		
		#consulta de física
		var query := PhysicsRayQueryParameters2D.create(origem_global, destino_global)
		
		#máscara de colisão
		query.collision_mask = 1 
		var corpo_jogador = get_parent().get_parent()
		
		# Garante que o nó encontrado é de fato um objeto físico antes de pegar o RID
		if corpo_jogador is CollisionObject2D:
			query.exclude = [corpo_jogador.get_rid()]
		# -----------------------------
		
		var resultado := espaco_fisico.intersect_ray(query)
		
		var vertice_local: Vector2
		if resultado:
			# Se o raio atingir uma parede, converte a posição do impacto para o espaço local
			vertice_local = to_local(resultado.position)
		else:
			# Se não atingir nada, o vértice será projetado na distância máxima do raio
			vertice_local = Vector2(cos(angulo_relativo), sin(angulo_relativo)) * raio_alcance
			
		pontos_poligono.append(vertice_local)

func _draw() -> void:
	if pontos_poligono.size() > 2:
		draw_colored_polygon(pontos_poligono, cor_luz)
