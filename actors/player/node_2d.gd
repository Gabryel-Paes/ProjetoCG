extends Node2D

@export var raio_alcance: float = 220.0
@export var angulo_abertura: float = PI / 5.0
@export var resolucao_raios: int = 350

var pontos_poligono := PackedVector2Array()
var cores_poligono := PackedColorArray() 

# 1. Definição inicial do estado da lanterna
var lanterna_ligada: bool = false

func _unhandled_input(event: InputEvent) -> void:
	# 2. Captura da tecla física 'F' sem repetição de eco
	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		lanterna_ligada = not lanterna_ligada
		queue_redraw()

func _physics_process(_delta: float) -> void:
	# 3. Interrupção do ciclo de física caso a lanterna esteja desligada
	if lanterna_ligada:
		_calcular_malha_visibilidade()
	else:
		# Esvazia a memória vetorial para apagar o último polígono gerado
		pontos_poligono.clear()
		cores_poligono.clear()
		
	queue_redraw()

func _calcular_malha_visibilidade() -> void:
	pontos_poligono.clear()
	cores_poligono.clear()
	
	pontos_poligono.append(Vector2.ZERO)
	cores_poligono.append(Color(0))

	var espaco_fisico := get_world_2d().direct_space_state
	var origem_global := global_position
	var rotacao_global := global_rotation
	
	var metade_abertura := angulo_abertura / 2.0
	var angulo_inicial := -metade_abertura
	var incremento_angular := angulo_abertura / float(resolucao_raios - 1)

	for i in range(resolucao_raios):
		var angulo_relativo := angulo_inicial + (i * incremento_angular)
		var angulo_absoluto := rotacao_global + angulo_relativo
		
		var direcao := Vector2(cos(angulo_absoluto), sin(angulo_absoluto))
		var destino_global := origem_global + (direcao * raio_alcance)
		
		var query := PhysicsRayQueryParameters2D.create(origem_global, destino_global)
		query.collision_mask = 1 
		var corpo_jogador = get_parent().get_parent()
		
		if corpo_jogador is CollisionObject2D:
			query.exclude = [corpo_jogador.get_rid()]
		
		var resultado: Dictionary = espaco_fisico.intersect_ray(query)
		
		var vertice_local: Vector2
		if resultado:
			vertice_local = to_local(resultado.position)
		else:
			vertice_local = Vector2(cos(angulo_relativo), sin(angulo_relativo)) * raio_alcance
			
		pontos_poligono.append(vertice_local)
		
		var distancia := vertice_local.length()
		var intensidade := 1.0 - (distancia / raio_alcance)
		var limite_suavizacao := metade_abertura * 0.80
		
		var abs_angulo := absf(angulo_relativo)
		
		if abs_angulo > limite_suavizacao:
			var gradiente: float = 1.0 - (abs_angulo - limite_suavizacao) / (metade_abertura - limite_suavizacao)
			intensidade *= gradiente
			
		intensidade = maxf(intensidade, 0.0)
		
		cores_poligono.append(Color(1.2, 1.2, 1.2, intensidade))

func _draw() -> void:
	# 4. Bloqueio de renderização na GPU baseado na variável de estado
	if lanterna_ligada and pontos_poligono.size() > 2:
		draw_polygon(pontos_poligono, cores_poligono)
