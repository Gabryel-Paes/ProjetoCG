extends CharacterBody2D
class_name Zumbi

# --- Zumbi ---
# O inimigo "normal" do jogo, espalhado pelas áreas. Diferente do Esqueleto
# (detecção simples, persegue pra sempre uma vez que te vê, patrulha em
# eixo fixo): o Zumbi tem visão curta de verdade (parede bloqueia, igual o
# Anjo) e audição curta (passos correndo e tiro, igual o Hearer da
# biblioteca, só que mais fraca) — e se você escapar do raio de
# perseguição, ele desiste e volta a vagar por perto, em vez de perseguir
# pra sempre ou voltar pro eixo fixo.

@export var speed: float = 35.0
@export var dano_do_ataque: float = 1.0

## Distância em que ele para de avançar. Sem isso ele mira o centro exato do
## Player pra sempre e fica "empurrando"/colado nele — e perto o bastante o
## vetor de direção (quase zero) normalizado fica instável e treme.
@export var stop_distance: float = 8.0

## Empurrão ao tomar dano de tiro, pra dar espaço de reação.
@export var knockback_strength: float = 120.0
## Empurrão ao tomar dano de faca — maior que o do tiro, corpo a corpo pesa
## mais que um projétil.
@export var melee_knockback_strength: float = 260.0
@export var knockback_friction: float = 800.0

## Ajusta se a arte não foi desenhada de frente/direita (+X) — mesma ideia
## do Player/Anjo/Stalker: esse zumbi foi desenhado de frente (+Y), então
## precisa girar -90° a mais pra "olhar" de verdade pra direção que anda.
@export var sprite_angle_offset_deg: float = -90.0

# --- Visão: curta, e de verdade — parede bloqueia (mesma técnica do Anjo) ---
@export var vision_range: float = 100.0

# --- Audição: mesma ideia do Hearer, só que mais fraca ---
@export var footstep_range: float = 70.0  # Hearer usa 130
@export var gunshot_range: float = 220.0  # Hearer usa 500

## Se o Player se afastar mais que isso durante a perseguição, o Zumbi
## desiste e volta a vagar — é o que o diferencia do Esqueleto, que persegue
## pra sempre assim que detecta.
@export var pursuit_range: float = 140.0

## Tempo de tolerância depois de ganhar aggro antes da checagem de
## pursuit_range valer — sem isso, um tiro ouvido ou um dano levado de mais
## longe que pursuit_range (ex: gunshot_range = 220 > pursuit_range = 140)
## cancelava o aggro no frame seguinte, antes do Zumbi conseguir sequer
## começar a se aproximar.
@export var pursuit_grace: float = 2.0
var _pursuit_grace_timer: float = 0.0

## Depois de acertar o Player, fica parado esse tempo antes de voltar a
## perseguir — sem isso ele fica "grudado", tentando reocupar o mesmo
## espaço a cada frame, e às vezes nem consegue bater de novo.
@export var attack_cooldown: float = 1.0
var _attack_cooldown_timer: float = 0.0

# --- Vagar (quando não está perseguindo nada) ---
@export var wander_speed: float = 25.0
@export var wander_radius: float = 90.0
@export var wander_interval: float = 3.5

## Quanto tempo ele fica parado entre um destino de wander e outro.
@export var wander_pause_min: float = 1.0
@export var wander_pause_max: float = 3.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var health: Health = $Health
@onready var sprite: AnimatedSprite2D = $Aim/AnimatedSprite2D

var player: CharacterBody2D = null
var _gun: Gun = null

var _spawn_position: Vector2
var _wander_timer: float = 0.0
var _wander_pausing: bool = false
var _wander_pause_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO


func _ready() -> void:
	health.died.connect(die)
	health.damaged.connect(_on_damaged)

	_spawn_position = global_position
	_pick_wander_target()

	# Traça a rota pelo meio de cada abertura em vez do caminho mais curto
	# possível (que corta rente nas quinas) — mesma correção já usada nos
	# outros inimigos com NavigationAgent2D.
	nav_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED

	# Escuta o tiro do Player direto, sem precisar de uma Area2D de detecção
	# — igual o fallback que o Stalker usa pra achar o Player sozinho.
	var found_player := get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if found_player and found_player.has_node("Aim/Gun"):
		_gun = found_player.get_node("Aim/Gun")
		_gun.fired.connect(_on_gun_fired)


func _physics_process(delta: float) -> void:
	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_friction * delta)

	if player != null:
		_pursuit_grace_timer -= delta
		if _pursuit_grace_timer <= 0.0 and global_position.distance_to(player.global_position) > pursuit_range:
			# Desistiu — some da perseguição e volta a vagar por perto.
			player = null
		else:
			if _attack_cooldown_timer > 0.0:
				_attack_cooldown_timer -= delta
				velocity = _knockback
				move_and_slide()
				_update_sprite()
				return

			nav_agent.target_position = player.global_position
			_move_along_path(speed)
			return

	# Sem alvo no momento: tenta notar o Player por visão ou audição antes
	# de simplesmente continuar vagando.
	_check_vision()
	_check_footsteps()

	_wander(delta)
	if _wander_pausing:
		# Parado de propósito entre um destino de wander e outro — ainda
		# aplica o knockback (se levou dano) e atualiza o sprite pra "idle".
		velocity = _knockback
		move_and_slide()
		_update_sprite()
	else:
		_move_along_path(wander_speed)


func _move_along_path(current_speed: float) -> void:
	var chase_velocity := Vector2.ZERO

	if player == null or global_position.distance_to(player.global_position) > stop_distance:
		var has_path := not nav_agent.is_navigation_finished() and not nav_agent.get_current_navigation_path().is_empty()

		if has_path:
			var next_point := nav_agent.get_next_path_position()
			var to_next := next_point - global_position
			# Perto o bastante (ex: rente à borda de um buraco no navmesh), o
			# vetor quase-zero normalizado fica instável e treme — mesma
			# correção já usada no Anjo/Hearer/Stalker.
			if to_next.length() > 1.0:
				chase_velocity = to_next.normalized() * current_speed
		else:
			# Sem navmesh (ainda) ou sem rota: cai pra linha reta.
			var target := nav_agent.target_position
			if global_position.distance_to(target) > 2.0:
				chase_velocity = (target - global_position).normalized() * current_speed

	velocity = chase_velocity + _knockback
	move_and_slide()
	_update_sprite()


func _update_sprite() -> void:
	# "running" sempre que ele estiver de fato se movendo — vagando ou
	# perseguindo, tanto faz. Só fica em "idle" quando realmente parado
	# (ex: chegou perto demais do Player e respeitou o stop_distance).
	var desired_animation := "running" if velocity.length() > 1.0 else "idle"
	if sprite.animation != desired_animation:
		sprite.play(desired_animation)

	# Gira pra direção que anda — sem isso o sprite fica sempre voltado pro
	# mesmo lado, perseguindo de qualquer ângulo.
	if velocity.length() > 1.0:
		sprite.rotation = velocity.angle() + deg_to_rad(sprite_angle_offset_deg)


func _wander(delta: float) -> void:
	if _wander_pausing:
		_wander_pause_timer -= delta
		if _wander_pause_timer <= 0.0:
			_wander_pausing = false
			_pick_wander_target()
		return

	_wander_timer -= delta
	if _wander_timer <= 0.0 or nav_agent.is_navigation_finished():
		_wander_pausing = true
		_wander_pause_timer = randf_range(wander_pause_min, wander_pause_max)


func _pick_wander_target() -> void:
	_wander_timer = wander_interval
	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, wander_radius)
	nav_agent.target_position = _spawn_position + offset


func _gain_aggro(candidate: CharacterBody2D) -> void:
	player = candidate
	_pursuit_grace_timer = pursuit_grace


# --- Visão: curta e bloqueada por parede ---
func _check_vision() -> void:
	var candidate := get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if candidate == null:
		return
	if global_position.distance_to(candidate.global_position) > vision_range:
		return
	if _has_line_of_sight(candidate):
		_gain_aggro(candidate)


func _has_line_of_sight(target: CharacterBody2D) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	query.collision_mask = 1 # só paredes ("world") bloqueiam a visão
	query.exclude = [self, target]
	var result := space_state.intersect_ray(query)
	return result.is_empty()


# --- Audição: passos correndo e tiro, mais fraca que o Hearer ---
func _check_footsteps() -> void:
	var candidate := get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if candidate == null:
		return

	var player_speed := candidate.velocity.length()
	if player_speed < 1.0:
		return # parado não faz barulho

	var base_speed: float = candidate.get("base_speed") if candidate.get("base_speed") != null else 200.0
	if player_speed <= base_speed + 1.0:
		return # andando devagar é baixo demais pra ouvir

	if global_position.distance_to(candidate.global_position) <= footstep_range:
		_gain_aggro(candidate)


func _on_gun_fired() -> void:
	var candidate := get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if candidate and global_position.distance_to(candidate.global_position) <= gunshot_range:
		_gain_aggro(candidate)


# --- Dano de contato ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_node("Health") and _same_floor_as(body):
		body.get_node("Health").apply_damage(dano_do_ataque, global_position)
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


# --- Vida ---
func take_damage(amount: float, source_position: Vector2) -> void:
	health.apply_damage(amount, source_position)
	_apply_knockback(source_position, knockback_strength)


# Chamado pelo melee_attack.gd em vez de take_damage quando quem bateu foi a
# faca — mesmo dano, só que com um empurrão maior (melee_knockback_strength).
func take_melee_damage(amount: float, source_position: Vector2) -> void:
	health.apply_damage(amount, source_position)
	_apply_knockback(source_position, melee_knockback_strength)


func _apply_knockback(source_position: Vector2, strength: float) -> void:
	var push_dir := global_position - source_position
	if push_dir.length() < 0.01:
		push_dir = Vector2.RIGHT
	_knockback = push_dir.normalized() * strength


func _on_damaged(_amount: float, _source_position: Vector2) -> void:
	# O empurrão em si já é aplicado direto em take_damage/take_melee_damage
	# (cada um com sua intensidade) — aqui só sobra a parte do aggro, que
	# vale pra qualquer tipo de dano.
	var candidate := get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if candidate:
		_gain_aggro(candidate)


func die() -> void:
	queue_free()
