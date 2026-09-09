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

## Ajusta se a arte não foi desenhada de frente/direita (+X) — mesma ideia do sprite_angle_offset do Player.
@export var sprite_angle_offset_deg: float = -90.0

## Distância em que ele para de avançar. Sem isso ele mira o ponto de flanco
## exato pra sempre e fica "empurrando"/colado no Player — e perto o bastante
## o vetor de direção (quase zero) normalizado fica instável e treme.
@export var stop_distance: float = 8.0

## Depois de acertar o Player, fica parado esse tempo antes de voltar a
## avançar — sem isso ele fica "grudado", tentando reocupar o mesmo espaço
## a cada frame (mesmo ajuste já feito no Zumbi/Stalker).
@export var attack_cooldown: float = 1.0
var _attack_cooldown_timer: float = 0.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D

var sprt_idle = preload("res://ui/assets/sprites/angel_idle_outlined.png")
var sprt_moving = preload("res://ui/assets/sprites/angel_moving_outlined.png")

var player: CharacterBody2D = null

var _spawn_position: Vector2
var _wander_timer: float = 0.0

var _stuck_check_timer: float = 1.5
var _stuck_check_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	_spawn_position = global_position
	_pick_wander_target()
	# Traça a rota pelo meio de cada abertura em vez do caminho mais curto
	# possível (que corta rente nas quinas) — evita grudar na parede sem
	# precisar erodir o polígono de navegação (isso quebra a conexão entre tiles).
	nav_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED


func _physics_process(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta

	if player == null:
		_wander(delta)
		_move_along_path(wander_speed)
		return

	if _is_being_watched():
		velocity = Vector2.ZERO
		move_and_slide()
		# Só congela — mantém a última rotação que já tinha, não precisa
		# girar pra encarar quem o observou.
		sprite.texture = sprt_idle
	elif _attack_cooldown_timer > 0.0:
		# Acabou de acertar o Player — fica parado um instante antes de
		# voltar a se posicionar atrás dele.
		velocity = Vector2.ZERO
		move_and_slide()
		_update_sprite()
	else:
		# Tenta chegar nas costas do Player, não direto na frente dele
		var aim_dir := Vector2.RIGHT.rotated(player.aim_angle)
		nav_agent.target_position = player.global_position - aim_dir * flank_distance
		_move_along_path(speed)


func _move_along_path(current_speed: float) -> void:
	if player != null and global_position.distance_to(player.global_position) <= stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_sprite()
		return

	var has_path := not nav_agent.is_navigation_finished() and not nav_agent.get_current_navigation_path().is_empty()

	if has_path:
		var next_point := nav_agent.get_next_path_position()
		var to_next := next_point - global_position
		# Perto o bastante (ex: rente à borda de um buraco no navmesh), o
		# vetor quase-zero normalizado fica instável e treme — só recalcula
		# direção quando a distância é o bastante pra normalizar direito.
		if to_next.length() > 1.0:
			velocity = to_next.normalized() * current_speed
		else:
			velocity = Vector2.ZERO
	else:
		# Sem navmesh (ainda) ou sem rota encontrada: cai pra linha reta,
		# só pra não ficar parado enquanto o bake não estiver funcionando.
		var target := nav_agent.target_position
		if global_position.distance_to(target) > 2.0:
			velocity = (target - global_position).normalized() * current_speed
		else:
			velocity = Vector2.ZERO

	move_and_slide()
	_update_sprite()


func _update_sprite() -> void:
	if velocity.length() > 1.0:
		sprite.texture = sprt_moving
		sprite.rotation = velocity.angle() + deg_to_rad(sprite_angle_offset_deg)
	else:
		sprite.texture = sprt_idle
		# Parado sem estar sendo observado (ex: esperando novo destino do
		# wander) — mantém a última rotação, não trava num ângulo fixo.


func _wander(delta: float) -> void:
	_wander_timer -= delta

	# Detector de "preso": se o destino escolhido for impossível de alcançar
	# de verdade (ex: uma borda de navmesh que não conecta direito perto de
	# uma pedra), ele fica tentando pra sempre sem perceber que não anda.
	# Confere de tempos em tempos se realmente andou alguma coisa — se não
	# andou, desiste desse destino e escolhe outro.
	_stuck_check_timer -= delta
	if _stuck_check_timer <= 0.0:
		if global_position.distance_to(_stuck_check_position) < 4.0:
			_pick_wander_target()
		_stuck_check_timer = 1.5
		_stuck_check_position = global_position

	if _wander_timer <= 0.0 or nav_agent.is_navigation_finished():
		_pick_wander_target()


func _pick_wander_target() -> void:
	_wander_timer = wander_interval
	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, wander_radius)
	nav_agent.target_position = _snap_to_navmesh(_spawn_position + offset)


# Wander_radius pode facilmente cair fora da área navegável (fora da casa,
# do outro lado de uma parede). Sem isso, o NavigationAgent2D fica pedindo
# rota pra um ponto que não existe e o motor spama aviso toda hora — mesma
# correção já usada no stalker_director.gd pra posicionar o Stalker.
func _snap_to_navmesh(point: Vector2) -> Vector2:
	var map_rid: RID = get_viewport().world_2d.navigation_map
	var snapped_point := NavigationServer2D.map_get_closest_point(map_rid, point)

	# Navmesh ainda não pronto (mapa vazio) devolve (0,0) — nesse caso é
	# pior "ajustar" pra origem do mundo do que só usar o ponto original.
	if snapped_point == Vector2.ZERO and point != Vector2.ZERO:
		return point

	return snapped_point


func _is_being_watched() -> bool:
	var flashlight: PlayerFlashlight = player.flashlight

	# Feixe desligado (F alterna pra textura só-ambiente) = sem cone
	# apontado pra nada — nunca "visto". `enabled` não serve mais aqui,
	# porque o Light2D continua ligado até no modo só-ambiente.
	if not flashlight.lanterna_ligada:
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
	if body.is_in_group("Player") and body.has_node("Health") and _same_floor_as(body):
		body.get_node("Health").apply_damage(dano_toque, global_position)
		_attack_cooldown_timer = attack_cooldown


# Rede de segurança independente do sistema de andar da lobby_tutorial.gd
# (que liga/desliga collision_layer/mask por grupo floor1_only/floor2_only):
# mesmo que aquele sistema falhe por algum motivo (corrida de timing, andar
# trocado rápido demais, um inimigo novo esquecido no grupo certo...), não
# aplica dano se o Player não estiver de verdade no mesmo andar que este
# inimigo — confirma direto pelo bit floor1_occupant/floor2_occupant.
func _same_floor_as(body: Node) -> bool:
	var body_layer: int = body.get("collision_layer")
	if is_in_group("floor1_only") and (body_layer & 32) == 0:
		return false
	if is_in_group("floor2_only") and (body_layer & 64) == 0:
		return false
	return true


# --- Imunidade ---
func take_damage(_amount: float, _source_position: Vector2) -> void:
	# É pedra. Balas e faca não fazem nada aqui, de propósito.
	pass
