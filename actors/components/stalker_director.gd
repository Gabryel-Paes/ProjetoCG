extends Node
class_name StalkerDirector

# --- Orquestra o encontro do Stalker ---
# Espera um tempo aleatório, spawna o Stalker perto do Player, e some com ele
# sozinho depois de `encounter_duration`, não importa o que tenha acontecido.

signal encounter_started()
signal encounter_ended()

@export var stalker_scene: PackedScene
@export var min_delay: float = 420.0   # 7 minutos
@export var max_delay: float = 600.0   # 10 minutos
@export var encounter_duration: float = 30.0
@export var spawn_distance: float = 300.0 # o quão longe do Player ele nasce

var _stalker: Stalker = null


func _ready() -> void:
	var delay := randf_range(min_delay, max_delay)
	get_tree().create_timer(delay).timeout.connect(_start_encounter)


func _start_encounter() -> void:
	if _stalker != null or stalker_scene == null:
		return

	var player := get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if player == null:
		return

	_stalker = stalker_scene.instantiate()

	var spawn_dir := Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	var raw_point := player.global_position + spawn_dir * spawn_distance
	_stalker.global_position = _snap_to_navmesh(raw_point)

	get_tree().current_scene.add_child(_stalker)
	_stalker.player = player

	# O Stalker nasce dinamicamente, fora da árvore original da cena — sem
	# isso ele nunca entra no sistema de andares (floor1_only/floor2_only)
	# que a lobby_tutorial.gd usa pra ligar/desligar colisão e luz por piso
	# (esse setup só roda uma vez, no _ready(), bem antes dele existir).
	# Resultado sem essa marcação: ele continua sólido em qualquer andar,
	# mesmo depois do Player mudar de piso.
	var floor_group := "floor2_only" if player.get_collision_layer_value(7) else "floor1_only"
	_stalker.add_to_group(floor_group)

	# light_mask não é herdado — precisa marcar em CADA CanvasItem (o
	# Sprite2D que desenha de verdade, não só o CharacterBody2D raiz, que
	# não desenha nada sozinho). Sem isso ele fica com o light_mask padrão
	# (1, térreo) e nenhuma luz do andar 2 ilumina o sprite — ele fica
	# fisicamente ali (a colisão funciona) mas visualmente invisível de
	# verdade, sempre sem luz nenhuma nele.
	var floor_light_mask := 2 if floor_group == "floor2_only" else 1
	_apply_light_mask_recursive(_stalker, floor_light_mask)

	# TileMap_2sFloor/2fMoveis (o chão do mezanino) desenham em z_index = 1
	# de propósito, por cima de tudo que fica no 0 padrão — é assim que o
	# térreo fica "por baixo" quando os dois andares compartilham a mesma
	# coordenada. O Stalker nascia sempre em z_index 0: no térreo ficava
	# certo, mas no mezanino ele ficava desenhado ATRÁS do próprio chão de
	# cima, sumindo visualmente mesmo com colisão e luz corretas (z_as_relative
	# é true por padrão, então setar no nó raiz já cobre os filhos).
	_stalker.z_index = 1 if floor_group == "floor2_only" else 0

	encounter_started.emit()
	MusicManager.play_stalker_theme()
	get_tree().create_timer(encounter_duration).timeout.connect(_end_encounter)


func _apply_light_mask_recursive(node: Node, mask: int) -> void:
	if node is CanvasItem:
		node.light_mask = mask
	for child in node.get_children():
		_apply_light_mask_recursive(child, mask)


func _snap_to_navmesh(point: Vector2) -> Vector2:
	var map_rid: RID = get_viewport().world_2d.navigation_map
	var snapped_point := NavigationServer2D.map_get_closest_point(map_rid, point)

	# Se o navmesh ainda não estiver "bakeado" (mapa vazio), isso volta (0,0) —
	# nesse caso é bem pior teleportar o Stalker pra origem do mundo do que
	# só usar o ponto original (sem garantia de não cair na parede, mas ao
	# menos fica perto de onde devia).
	if snapped_point == Vector2.ZERO and point != Vector2.ZERO:
		return point

	return snapped_point


func _end_encounter() -> void:
	if is_instance_valid(_stalker):
		_stalker.queue_free()
	_stalker = null
	MusicManager.stop_stalker_theme()
	encounter_ended.emit()
