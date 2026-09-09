extends Node2D

# Volta a 0.0 (totalmente invisível) por enquanto — a ideia de deixar o
# térreo apagado (tipo "olhando de cima" através de um vão do mezanino) fica
# pra resolver depois, com calma.
const FLOOR_BELOW_ALPHA := 0.0

# Guarda a camada de colisão original de cada objeto floor1_only/floor2_only
# que não seja uma TileMapLayer (essas já têm o collision_enabled cuidando
# delas à parte) — ex: móveis soltos na cena, não pintados como tile. Sem
# isso não dá pra "religar" a colisão certa depois de zerá-la, já que cada
# prop pode usar uma camada diferente.
var _prop_collision_cache: Dictionary = {}


# Zera (ou devolve) a colisão de todo objeto solto de um grupo de andar —
# complemento do collision_enabled, que só cobre TileMapLayer inteira.
#
# Recursivo de propósito: inimigos (Zumbi, Angel, Stalker...) têm Area2D
# filhas (Hitbox, Hurtbox, DetectionArea) com collision_layer PRÓPRIA,
# separada da do CharacterBody2D raiz — só zerar o nó do grupo deixava a
# Hitbox ativa pra sempre, acertando o Player mesmo no andar errado.
func _set_prop_collision(group: String, enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group(group):
		if node is CollisionObject2D and not node is TileMapLayer:
			_apply_prop_collision(node, enabled)
			for descendant in node.find_children("*", "CollisionObject2D", true, false):
				_apply_prop_collision(descendant, enabled)


func _apply_prop_collision(node: CollisionObject2D, enabled: bool) -> void:
	# Zera layer E mask — o Player carrega o bit "world" (1) o tempo todo
	# no próprio collision_layer (pra colidir com paredes fora do sistema
	# de andar), e a Hitbox de inimigo nunca teve collision_mask configurada
	# (fica no padrão = 1, "world"). Ou seja: zerar só a layer não impedia a
	# Hitbox de continuar "vendo" o Player por esse bit compartilhado — só
	# zerando os dois lados garante que não colide nem detecta nada.
	if not _prop_collision_cache.has(node):
		_prop_collision_cache[node] = {"layer": node.collision_layer, "mask": node.collision_mask}
	var original: Dictionary = _prop_collision_cache[node]
	node.collision_layer = original["layer"] if enabled else 0
	node.collision_mask = original["mask"] if enabled else 0


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
		if node is CanvasItem:
			node.modulate.a = 0.0

	# Móveis soltos (não pintados como tile) também precisam da colisão
	# desligada enquanto invisíveis — o collision_enabled acima só cobre a
	# TileMapLayer inteira, não cada prop individual do grupo.
	_set_prop_collision("floor1_only", true)
	_set_prop_collision("floor2_only", false)

	# Trava a "camada de luz" de cada andar pelo grupo, automaticamente —
	# sem isso, qualquer coisa nova marcada floor1_only/floor2_only nasce no
	# light_mask padrão (1) e a lanterna do andar errado enxerga ela (foi
	# exatamente o que aconteceu com o 2fMoveis e a chaveBiblioteca, que
	# precisaram ser corrigidos na mão na cena).
	#
	# Os dois de propósito recursivos: um inimigo/prop composto (ex: Zumbi)
	# é um CharacterBody2D que não desenha nada sozinho — quem desenha é um
	# Sprite2D/AnimatedSprite2D filho, que tem seu PRÓPRIO light_mask (não
	# herda do pai). Só marcar o nó do grupo não chega no filho — foi
	# exatamente esse bug que deixou o Stalker invisível no 2º andar.
	for node in get_tree().get_nodes_in_group("floor1_only"):
		_apply_floor_layering(node, 1, 0)
	for node in get_tree().get_nodes_in_group("floor2_only"):
		_apply_floor_layering(node, 2, 1)

	# Carregando um save feito no 2º andar: tudo acima deixou o Player no
	# estado padrão do térreo — reaplica a mesma transição de "subir" que o
	# Trigger_Up dispara, agora na hora do _ready(), pra devolver o mezanino
	# de verdade em vez de só a posição (x,y), que sozinha não diz em qual
	# andar você realmente estava (os dois compartilham coordenada).
	if has_node("Player") and GameState.pending_player_floor2():
		_on_trigger_up_body_entered($Player)


# z_index: TileMap_2sFloor/2fMoveis desenham em z_index 1 de propósito, por
# cima de tudo que fica no 0 padrão (assim o térreo fica "por baixo" quando
# os dois andares compartilham a mesma coordenada). Qualquer coisa marcada
# floor2_only precisa do mesmo z_index, senão fica desenhada atrás do
# próprio chão de cima — mesmo bug de z_index que pegou o Stalker. Só no nó
# raiz: z_as_relative é true por padrão, então isso já cascata pros filhos
# sozinho, sem precisar (e sem risco de atropelar alguma ordenação relativa
# interna que um filho já tenha entre as próprias partes).
func _apply_floor_layering(node: Node, target_light_mask: int, target_z_index: int) -> void:
	if node is Node2D:
		node.z_index = target_z_index
	_apply_light_mask_recursive(node, target_light_mask)


# light_mask NÃO é herdado (ao contrário do z_index) — precisa marcar em
# CADA CanvasItem da árvore. Um inimigo composto (ex: Zumbi) é um
# CharacterBody2D que não desenha nada sozinho; quem desenha é um
# Sprite2D/AnimatedSprite2D filho, com seu PRÓPRIO light_mask. Só marcar o
# nó do grupo não chega no filho — foi exatamente esse bug que deixou o
# Stalker invisível no 2º andar.
func _apply_light_mask_recursive(node: Node, target_light_mask: int) -> void:
	if node is CanvasItem:
		node.light_mask = target_light_mask
	for child in node.get_children():
		_apply_light_mask_recursive(child, target_light_mask)

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

		_set_prop_collision("floor1_only", false)
		_set_prop_collision("floor2_only", true)

		# Animação suave para APARECER (Fade-In)
		if has_node("TileMap_2sFloor"):
			var tween = create_tween()
			# Faz a opacidade (Alpha) ir de onde está até 1.0 em 0.5 segundos
			tween.tween_property($TileMap_2sFloor, "modulate:a", 1.0, 0.5)

		for node in get_tree().get_nodes_in_group("floor2_only"):
			if node is CanvasItem:
				var tween_node = create_tween()
				tween_node.tween_property(node, "modulate:a", 1.0, 0.5)

		if has_node("TileMap_1sFloor"):
			var tween_floor1 = create_tween()
			tween_floor1.tween_property($TileMap_1sFloor, "modulate:a", FLOOR_BELOW_ALPHA, 0.5)

		for node in get_tree().get_nodes_in_group("floor1_only"):
			if node is CanvasItem:
				var tween_node1 = create_tween()
				tween_node1.tween_property(node, "modulate:a", FLOOR_BELOW_ALPHA, 0.5)

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

		_set_prop_collision("floor1_only", true)
		_set_prop_collision("floor2_only", false)

		# Animação suave para SUMIR (Fade-Out)
		if has_node("TileMap_2sFloor"):
			var tween = create_tween()
			# Faz a opacidade (Alpha) ir para 0.0 em 0.5 segundos
			tween.tween_property($TileMap_2sFloor, "modulate:a", 0.0, 0.5)

		for node in get_tree().get_nodes_in_group("floor2_only"):
			if node is CanvasItem:
				var tween_node = create_tween()
				tween_node.tween_property(node, "modulate:a", 0.0, 0.5)

		if has_node("TileMap_1sFloor"):
			var tween_floor1 = create_tween()
			tween_floor1.tween_property($TileMap_1sFloor, "modulate:a", 1.0, 0.5)

		for node in get_tree().get_nodes_in_group("floor1_only"):
			if node is CanvasItem:
				var tween_node1 = create_tween()
				tween_node1.tween_property(node, "modulate:a", 1.0, 0.5)

		print("Desceu: Mezanino sumindo gradualmente!")
		
		# MÁGICA DA LUZ: Volta a lanterna para a Camada 1 (Térreo)
		if body.has_node("Aim/PointLight2D"):
			var luz = body.get_node("Aim/PointLight2D")
			luz.range_item_cull_mask = 1  # Ilumina apenas a Camada 1
			luz.shadow_item_cull_mask = 1 # Sombra bate apenas na Camada 1
			
		print("Desceu: Lanterna voltou para o Térreo!")
