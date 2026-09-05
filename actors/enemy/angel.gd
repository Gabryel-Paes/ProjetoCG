extends CharacterBody2D

# --- Weeping Angel ---
# Regra: só se move quando o Player NÃO está olhando pra ele.
# É pedra: sem Health, sem Hurtbox, "take_damage" é um no-op de propósito.

@export var speed: float = 40.0
@export var flank_distance: float = 10.0     # o quanto ele tenta se posicionar atrás do Player
@export var dano_toque: float = 1.0          # dano se ele alcançar o Player

# --- Wanderer (quando nenhum Player foi detectado ainda) ---
@export var wander_speed: float = 24.0
@export var wander_radius: float = 400.0     # o quanto ele se afasta do ponto de origem
@export var wander_interval: float = 3.0     # segundos até escolher um novo destino

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var player: CharacterBody2D = null

var _spawn_position: Vector2
var _wander_timer: float = 0.0


func _ready() -> void:
	_spawn_position = global_position
	_pick_wander_target()
	# Traça a rota pelo meio de cada abertura em vez do caminho mais curto
	# possível (que corta rente nas quinas) — evita grudar na parede sem
	# precisar erodir o polígono de navegação (isso quebra a conexão entre tiles).
	nav_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED


func _physics_process(delta: float) -> void:
	if player == null:
		_wander(delta)
		_move_along_path(wander_speed)
		return

	if _is_being_watched():
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		# Tenta chegar nas costas do Player, não direto na frente dele
		var aim_dir := Vector2.RIGHT.rotated(player.aim_angle)
		nav_agent.target_position = player.global_position - aim_dir * flank_distance
		_move_along_path(speed)


func _move_along_path(current_speed: float) -> void:
	var has_path := not nav_agent.is_navigation_finished() and not nav_agent.get_current_navigation_path().is_empty()

	if has_path:
		var next_point := nav_agent.get_next_path_position()
		velocity = (next_point - global_position).normalized() * current_speed
	else:
		# Sem navmesh (ainda) ou sem rota encontrada: cai pra linha reta,
		# só pra não ficar parado enquanto o bake não estiver funcionando.
		var target := nav_agent.target_position
		if global_position.distance_to(target) > 2.0:
			velocity = (target - global_position).normalized() * current_speed
		else:
			velocity = Vector2.ZERO

	move_and_slide()


func _wander(delta: float) -> void:
	_wander_timer -= delta

	if _wander_timer <= 0.0 or nav_agent.is_navigation_finished():
		_pick_wander_target()


func _pick_wander_target() -> void:
	_wander_timer = wander_interval
	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, wander_radius)
	nav_agent.target_position = _spawn_position + offset


func _is_being_watched() -> bool:
	var flashlight: PlayerFlashlight = player.flashlight

	# Lanterna apagada = escuridão total (estilo Darkwood) — nunca "visto".
	if not flashlight.enabled:
		return false

	var to_angel := global_position - flashlight.global_position
	var distance := to_angel.length()

	# Nota: não usa RAIO_AMBIENTE aqui de propósito — o brilho ambiente é só
	# pra você enxergar o chão ao redor, não conta como "estar olhando" pro
	# Anjo. "Visto" é só sobre o cone (direção), senão ele travava nas costas
	# do Player mesmo estando fora do campo de visão, só por estar perto.

	# Fora do alcance máximo do cone: escuro demais pra enxergar.
	if distance > float(PlayerFlashlight.RESOLUCAO_TEXTURA) / 2.0:
		return false

	# Mesmo cone da lanterna de verdade — não um ângulo "de mira" à parte,
	# que é o que fazia ele travar mesmo estando atrás do Player.
	var angle_diff := absf(wrapf(to_angel.angle() - flashlight.global_rotation, -PI, PI))
	if angle_diff > PlayerFlashlight.ABERTURA_CONE:
		return false

	return _has_line_of_sight()


func _has_line_of_sight() -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.collision_mask = 1 # só paredes ("world") bloqueiam a visão
	# O Player também está na layer "world" (padrão do projeto) — sem isso,
	# o raio "bateria" no próprio Player e acharia que sempre tem parede no meio.
	query.exclude = [self, player]
	var result := space_state.intersect_ray(query)
	return result.is_empty()


# --- Detecção (raio de "despertar") ---
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null


# --- Dano de contato ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_node("Health"):
		body.get_node("Health").apply_damage(dano_toque, global_position)


# --- Imunidade ---
func take_damage(_amount: float, _source_position: Vector2) -> void:
	# É pedra. Balas e faca não fazem nada aqui, de propósito.
	pass
