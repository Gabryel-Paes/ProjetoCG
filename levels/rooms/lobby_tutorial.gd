extends Node2D

func _ready() -> void:
	if has_node("Player"):
		$Player.z_index = 0
		$Player.set_collision_mask_value(1, true)
		$Player.set_collision_mask_value(2, false)
	
	# Garante que o mezanino comece totalmente transparente (invisível)
	if has_node("TileMap_2sFloor"):
		$TileMap_2sFloor.modulate.a = 0.0

# Conectado ao Trigger_Up (Subindo)
func _on_trigger_up_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.z_index = 1 
		body.set_collision_mask_value(1, false)
		body.set_collision_mask_value(2, true)
		
		# Animação suave para APARECER (Fade-In)
		if has_node("TileMap_2sFloor"):
			var tween = create_tween()
			# Faz a opacidade (Alpha) ir de onde está até 1.0 em 0.5 segundos
			tween.tween_property($TileMap_2sFloor, "modulate:a", 1.0, 0.5)
			
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
		body.set_collision_mask_value(1, true)
		body.set_collision_mask_value(2, false)
		
		# Animação suave para SUMIR (Fade-Out)
		if has_node("TileMap_2sFloor"):
			var tween = create_tween()
			# Faz a opacidade (Alpha) ir para 0.0 em 0.5 segundos
			tween.tween_property($TileMap_2sFloor, "modulate:a", 0.0, 0.5)
			
		print("Desceu: Mezanino sumindo gradualmente!")
		
		# MÁGICA DA LUZ: Volta a lanterna para a Camada 1 (Térreo)
		if body.has_node("Aim/PointLight2D"):
			var luz = body.get_node("Aim/PointLight2D")
			luz.range_item_cull_mask = 1  # Ilumina apenas a Camada 1
			luz.shadow_item_cull_mask = 1 # Sombra bate apenas na Camada 1
			
		print("Desceu: Lanterna voltou para o Térreo!")
