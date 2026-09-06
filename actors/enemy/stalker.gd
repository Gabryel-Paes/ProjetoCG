extends CharacterBody2D
class_name Stalker

# --- Stalker (boss final) ---
# Persegue o Player direto, sem parar, sem stealth. Imune a dano de verdade —
# sem Health, sem Hurtbox — mas um tiro/golpe o deixa mais lento por um tempo.

@export var speed: float = 55.0
@export var dano_toque: float = 3.0 # dano de contato, pesado mas não é instakill

@export var slow_amount: float = 0.5   # fração da velocidade normal enquanto lento (0.5 = -50%)
@export var slow_duration: float = 1.5 # segundos que a lentidão dura a cada acerto

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var player: CharacterBody2D = null

var _slow_timer: float = 0.0


func _ready() -> void:
	# Traça a rota pelo meio de cada abertura em vez do caminho mais curto
	# possível (que corta rente nas quinas) — evita grudar na parede sem
	# precisar erodir o polígono de navegação (isso quebra a conexão entre tiles).
	nav_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED


func _physics_process(_delta: float) -> void:
	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	nav_agent.target_position = player.global_position
	_move_along_path()


func _process(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta


func _current_speed() -> float:
	return speed * slow_amount if _slow_timer > 0.0 else speed


func _move_along_path() -> void:
	var has_path := not nav_agent.is_navigation_finished() and not nav_agent.get_current_navigation_path().is_empty()
	var current_speed := _current_speed()

	if has_path:
		var next_point := nav_agent.get_next_path_position()
		velocity = (next_point - global_position).normalized() * current_speed
	else:
		# Sem navmesh (ainda) ou sem rota: cai pra linha reta, mesmo recurso do Anjo.
		var target := nav_agent.target_position
		if global_position.distance_to(target) > 2.0:
			velocity = (target - global_position).normalized() * current_speed
		else:
			velocity = Vector2.ZERO

	move_and_slide()


# --- Dano de contato ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_node("Health"):
		body.get_node("Health").apply_damage(dano_toque, global_position)


# --- Imunidade a morte: tiro/faca não mata, só atrapalha ---
func take_damage(_amount: float, _source_position: Vector2) -> void:
	_slow_timer = slow_duration
