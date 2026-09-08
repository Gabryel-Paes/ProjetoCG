extends Node2D

func _ready() -> void:
	if has_node("Player"):
		$Player.z_index = 0
		# Marca o Player como "presente no térreo" pra quem precisa saber
		# em qual andar ele está de verdade (não só a parede que ele bate).
		$Player.set_collision_layer_value(6, true)
		$Player.set_collision_layer_value(7, false)
	
	# Garante que o mezanino comece totalmente transparente (invisível)
	if has_node("TileMap_2sFloor"):
		$TileMap_2sFloor.modulate.a = 0.0

	# Os dois andares compartilham as mesmas coordenadas e a mesma camada de
	# física ("mundo") pras paredes — não dá pra diferenciar "parede do 1º"
	# de "parede do 2º" só pela camada, os dois são fisicamente idênticos.
	# Por isso desligamos a colisão da TileMapLayer inteira de quem não é o
	# andar atual, em vez de mexer em bit de camada/máscara.
	if has_node("TileMap_1sFloor"):
		$TileMap_1sFloor.collision_enabled = true
	if has_node("TileMap_2sFloor"):
		$TileMap_2sFloor.collision_enabled = false
	if has_node("1fMoveis"):
		$"1fMoveis".collision_enabled = true
	if has_node("2fMoveis"):
		$"2fMoveis".collision_enabled = false

	# Mesmo problema, mas com a sombra: a Occlusion Layer do TileSet (o
	# "Light Mask" lá no Inspector) é UMA SÓ, compartilhada pelos dois
	# andares — não dá pra marcar diferente por camada, marcar num
	# sobrescreve o outro. Por isso a oclusão inteira liga/desliga junto
	# com a colisão, por andar.
	if has_node("TileMap_1sFloor"):
		$TileMap_1sFloor.occlusion_enabled = true
	if has_node("TileMap_2sFloor"):
		$TileMap_2sFloor.occlusion_enabled = false
	if has_node("1fMoveis"):
		$"1fMoveis".occlusion_enabled = true
	if has_node("2fMoveis"):
		$"2fMoveis".occlusion_enabled = false

	# Mesmo problema de novo, agora com a navegação: os dois andares tavam
	# jogando o navmesh inteiro no mesmo mapa o tempo todo, sobrepondo
	# milhares de bordas idênticas (era o "12844 edge error(s)" spammando o
	# Output). Liga só o navmesh do andar atual, igual colisão/oclusão.
	if has_node("TileMap_1sFloor"):
		$TileMap_1sFloor.navigation_enabled = true
	if has_node("TileMap_2sFloor"):
		$TileMap_2sFloor.navigation_enabled = false
	if has_node("1fMoveis"):
		$"1fMoveis".navigation_enabled = true
	if has_node("2fMoveis"):
		$"2fMoveis".navigation_enabled = false

	# Mesma coisa pra tudo que é exclusivo do 2º andar (Hearer, e qualquer
	# outra coisa que entrar no grupo "floor2_only" no futuro).
	for node in get_tree().get_nodes_in_group("floor2_only"):
		node.modulate.a = 0.0

	# Trava a "camada de luz" de cada andar pelo grupo, automaticamente —
	# sem isso, qualquer coisa nova marcada floor1_only/floor2_only nasce no
	# light_mask padrão (1) e a lanterna do andar errado enxerga ela (foi
	# exatamente o que aconteceu com o 2fMoveis e a chaveBiblioteca, que
	# precisaram ser corrigidos na mão na cena).
	for node in get_tree().get_nodes_in_group("floor1_only"):
		if node is CanvasItem:
			node.light_mask = 1
	for node in get_tree().get_nodes_in_group("floor2_only"):
		if node is CanvasItem:
			node.light_mask = 2

# Conectado ao Trigger_Up (Subindo)
func _on_trigger_up_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.z_index = 1
		body.set_collision_layer_value(6, false)
		body.set_collision_layer_value(7, true)
		# O Hearer só está na camada floor2_occupant (não a "enemies"
		# genérica) — sem isso na própria máscara do Player, ele nunca
		# colide com o Hearer, nem estando no mesmo andar de verdade.
		body.set_collision_mask_value(7, true)

		if has_node("TileMap_1sFloor"):
			$TileMap_1sFloor.collision_enabled = false
		if has_node("TileMap_2sFloor"):
			$TileMap_2sFloor.collision_enabled = true
		if has_node("1fMoveis"):
			$"1fMoveis".collision_enabled = false
		if has_node("2fMoveis"):
			$"2fMoveis".collision_enabled = true

		if has_node("TileMap_1sFloor"):
			$TileMap_1sFloor.occlusion_enabled = false
		if has_node("TileMap_2sFloor"):
			$TileMap_2sFloor.occlusion_enabled = true
		if has_node("1fMoveis"):
			$"1fMoveis".occlusion_enabled = false
		if has_node("2fMoveis"):
			$"2fMoveis".occlusion_enabled = true

		if has_node("TileMap_1sFloor"):
			$TileMap_1sFloor.navigation_enabled = false
		if has_node("TileMap_2sFloor"):
			$TileMap_2sFloor.navigation_enabled = true
		if has_node("1fMoveis"):
			$"1fMoveis".navigation_enabled = false
		if has_node("2fMoveis"):
			$"2fMoveis".navigation_enabled = true

		# Animação suave para APARECER (Fade-In)
		if has_node("TileMap_2sFloor"):
			var tween = create_tween()
			# Faz a opacidade (Alpha) ir de onde está até 1.0 em 0.5 segundos
			tween.tween_property($TileMap_2sFloor, "modulate:a", 1.0, 0.5)

		for node in get_tree().get_nodes_in_group("floor2_only"):
			var tween_node = create_tween()
			tween_node.tween_property(node, "modulate:a", 1.0, 0.5)

		if has_node("TileMap_1sFloor"):
			var tween_floor1 = create_tween()
			tween_floor1.tween_property($TileMap_1sFloor, "modulate:a", 0.0, 0.5)

		for node in get_tree().get_nodes_in_group("floor1_only"):
			var tween_node1 = create_tween()
			tween_node1.tween_property(node, "modulate:a", 0.0, 0.5)

		print("Subiu: Mezanino aparecendo gradualmente!")

# MÁGICA DA LUZ: Muda a lanterna para a Camada 2 (Mezanino)
		if body.has_node("Aim/PointLight2D"):
			var luz = body.get_node("Aim/PointLight2D")
			luz.range_item_cull_mask = 2  # Ilumina apenas a Camada 2
			luz.shadow_item_cull_mask = 2 # Sombra bate apenas na Camada 2
			
		print("Subiu: Lanterna agora ilumina o Mezanino!")
		
func _on_trigger_down_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.z_index = 0
		body.set_collision_layer_value(6, true)
		body.set_collision_layer_value(7, false)
		body.set_collision_mask_value(7, false)

		if has_node("TileMap_1sFloor"):
			$TileMap_1sFloor.collision_enabled = true
		if has_node("TileMap_2sFloor"):
			$TileMap_2sFloor.collision_enabled = false
		if has_node("1fMoveis"):
			$"1fMoveis".collision_enabled = true
		if has_node("2fMoveis"):
			$"2fMoveis".collision_enabled = false

		if has_node("TileMap_1sFloor"):
			$TileMap_1sFloor.occlusion_enabled = true
		if has_node("TileMap_2sFloor"):
			$TileMap_2sFloor.occlusion_enabled = false
		if has_node("1fMoveis"):
			$"1fMoveis".occlusion_enabled = true
		if has_node("2fMoveis"):
			$"2fMoveis".occlusion_enabled = false

		if has_node("TileMap_1sFloor"):
			$TileMap_1sFloor.navigation_enabled = true
		if has_node("TileMap_2sFloor"):
			$TileMap_2sFloor.navigation_enabled = false
		if has_node("1fMoveis"):
			$"1fMoveis".navigation_enabled = true
		if has_node("2fMoveis"):
			$"2fMoveis".navigation_enabled = false

		# Animação suave para SUMIR (Fade-Out)
		if has_node("TileMap_2sFloor"):
			var tween = create_tween()
			# Faz a opacidade (Alpha) ir para 0.0 em 0.5 segundos
			tween.tween_property($TileMap_2sFloor, "modulate:a", 0.0, 0.5)

		for node in get_tree().get_nodes_in_group("floor2_only"):
			var tween_node = create_tween()
			tween_node.tween_property(node, "modulate:a", 0.0, 0.5)

		if has_node("TileMap_1sFloor"):
			var tween_floor1 = create_tween()
			tween_floor1.tween_property($TileMap_1sFloor, "modulate:a", 1.0, 0.5)

		for node in get_tree().get_nodes_in_group("floor1_only"):
			var tween_node1 = create_tween()
			tween_node1.tween_property(node, "modulate:a", 1.0, 0.5)

		print("Desceu: Mezanino sumindo gradualmente!")
		
		# MÁGICA DA LUZ: Volta a lanterna para a Camada 1 (Térreo)
		if body.has_node("Aim/PointLight2D"):
			var luz = body.get_node("Aim/PointLight2D")
			luz.range_item_cull_mask = 1  # Ilumina apenas a Camada 1
			luz.shadow_item_cull_mask = 1 # Sombra bate apenas na Camada 1
			
		print("Desceu: Lanterna voltou para o Térreo!")
