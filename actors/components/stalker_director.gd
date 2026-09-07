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

	encounter_started.emit()
	get_tree().create_timer(encounter_duration).timeout.connect(_end_encounter)


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
	encounter_ended.emit()
