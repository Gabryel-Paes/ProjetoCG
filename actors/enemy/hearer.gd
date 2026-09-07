extends CharacterBody2D
class_name Hearer

# --- Hearer ---
# Cego — não usa cone de visão nenhum. Reage a barulho: passos (correndo) e
# tiro. Investiga o último lugar onde ouviu algo por um tempo, depois desiste
# e volta a rondar. Ao contrário do Anjo/Stalker, é mortal (tem Health normal).

@export var speed: float = 45.0
@export var dano_toque: float = 1.0

@export var footstep_range: float = 130.0  # alcance pra ouvir passos correndo
@export var gunshot_range: float = 500.0   # alcance pra ouvir um tiro
@export var investigate_time: float = 6.0  # quanto tempo persegue o último som antes de desistir

# --- Ronda (quando não ouviu nada) ---
@export var wander_speed: float = 45.0
@export var wander_radius: float = 150.0   # usado só se "Patrol Points" estiver vazio
@export var wander_interval: float = 4.0

## Distância em que ele para de avançar. Sem isso ele mira o centro exato do
## Player pra sempre e fica "empurrando"/colado nele — e perto o bastante o
## vetor de direção (quase zero) normalizado fica instável e treme.
@export var stop_distance: float = 8.0

## Pequeno empurrão ao tomar dano (tiro/faca), pra dar espaço de reação.
@export var knockback_strength: float = 160.0
@export var knockback_friction: float = 900.0

## Arraste nós Marker2D espalhados pela biblioteca, na ordem que ele deve
## visitar. Se preenchido, ele anda em loop por esses pontos em vez de vagar
## num raio aleatório em torno de onde nasceu.
@export var patrol_points: Array[Marker2D] = []

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var health: Health = $Health

var player: CharacterBody2D = null
var _gun: Gun = null

var _spawn_position: Vector2
var _wander_timer: float = 0.0
var _patrol_index: int = 0

var _alert: bool = false
var _investigate_timer: float = 0.0
var _last_heard_position: Vector2
var _knockback: Vector2 = Vector2.ZERO


func _ready() -> void:
	_spawn_position = global_position
	_pick_wander_target()
	health.died.connect(die)
	health.damaged.connect(_on_damaged)
	# Mesma correção do Anjo/Stalker: rota pelo meio da abertura, não rente à parede.
	nav_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED


func _physics_process(delta: float) -> void:
	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_friction * delta)

	if player == null:
		_wander(delta)
		_move_along_path(wander_speed)
		return

	_check_footsteps()

	if _alert:
		_investigate_timer -= delta
		if _investigate_timer <= 0.0:
			_alert = false

	if _alert:
		nav_agent.target_position = _last_heard_position
		_move_along_path(speed)
	else:
		_wander(delta)
		_move_along_path(wander_speed)


func _move_along_path(current_speed: float) -> void:
	var chase_velocity := Vector2.ZERO

	if player == null or global_position.distance_to(player.global_position) > stop_distance:
		var has_path := not nav_agent.is_navigation_finished() and not nav_agent.get_current_navigation_path().is_empty()

		if has_path:
			var next_point := nav_agent.get_next_path_position()
			chase_velocity = (next_point - global_position).normalized() * current_speed
		else:
			var target := nav_agent.target_position
			if global_position.distance_to(target) > 2.0:
				chase_velocity = (target - global_position).normalized() * current_speed

	velocity = chase_velocity + _knockback
	move_and_slide()


func _wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0 or nav_agent.is_navigation_finished():
		_pick_wander_target()


func _pick_wander_target() -> void:
	_wander_timer = wander_interval

	if not patrol_points.is_empty():
		nav_agent.target_position = patrol_points[_patrol_index].global_position
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		return

	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, wander_radius)
	nav_agent.target_position = _snap_to_navmesh(_spawn_position + offset)


# Wander_radius pode cair fora da área navegável. Sem isso, o
# NavigationAgent2D pede rota pra um ponto que não existe e o motor spama
# aviso toda hora — mesma correção usada no Anjo/stalker_director.gd.
func _snap_to_navmesh(point: Vector2) -> Vector2:
	var map_rid: RID = get_viewport().world_2d.navigation_map
	var snapped_point := NavigationServer2D.map_get_closest_point(map_rid, point)

	if snapped_point == Vector2.ZERO and point != Vector2.ZERO:
		return point

	return snapped_point


# --- Audição ---
func _check_footsteps() -> void:
	var player_speed := player.velocity.length()
	if player_speed < 1.0:
		return # parado não faz barulho

	var base_speed: float = player.get("base_speed") if player.get("base_speed") != null else 200.0
	if player_speed <= base_speed + 1.0:
		return # andando devagar é baixo demais pra ouvir

	if global_position.distance_to(player.global_position) <= footstep_range:
		_hear(player.global_position)


func _on_gun_fired() -> void:
	if player and global_position.distance_to(player.global_position) <= gunshot_range:
		_hear(player.global_position)


func _hear(where: Vector2) -> void:
	_alert = true
	_investigate_timer = investigate_time
	_last_heard_position = where


# --- Detecção (só existe fisicamente pra quem está no mesmo andar — ver DetectionArea) ---
func _on_detection_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	player = body
	if body.has_node("Aim/Gun"):
		_gun = body.get_node("Aim/Gun")
		if not _gun.fired.is_connected(_on_gun_fired):
			_gun.fired.connect(_on_gun_fired)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		if _gun and _gun.fired.is_connected(_on_gun_fired):
			_gun.fired.disconnect(_on_gun_fired)
		_gun = null
		player = null


# --- Dano de contato ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_node("Health"):
		body.get_node("Health").apply_damage(dano_toque, global_position)


# --- Vida (mortal, ao contrário do Anjo/Stalker) ---
func take_damage(amount: float, source_position: Vector2) -> void:
	health.apply_damage(amount, source_position)


func _on_damaged(_amount: float, source_position: Vector2) -> void:
	var push_dir := global_position - source_position
	if push_dir.length() < 0.01:
		push_dir = Vector2.RIGHT
	_knockback = push_dir.normalized() * knockback_strength


func die() -> void:
	queue_free()
