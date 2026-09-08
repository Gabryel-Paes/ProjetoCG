extends CharacterBody2D
class_name Stalker

# --- Stalker (boss final) ---
# Persegue o Player direto, sem parar, sem stealth. Imune a dano de verdade —
# sem Health, sem Hurtbox — mas um tiro/golpe o deixa mais lento por um tempo.

@export var speed: float = 55.0
@export var dano_toque: float = 3.0 # dano de contato, pesado mas não é instakill

@export var slow_amount: float = 0.5   # fração da velocidade normal enquanto lento (0.5 = -50%)
@export var slow_duration: float = 1.5 # segundos que a lentidão dura a cada acerto

## Distância em que ele para de avançar. Sem isso ele mira o centro exato do
## Player pra sempre e fica "empurrando"/colado nele — e perto o bastante o
## vetor de direção (quase zero) normalizado fica instável e treme.
@export var stop_distance: float = 8.0

## Quão rápido o empurrão de knockback desaparece (px/s²). Só é usado por
## quem realmente toma dano de verdade (ver StalkerBoss) — o Stalker normal
## nunca recebe o sinal "damaged" porque não tem Health.
@export var knockback_friction: float = 900.0

## Ajusta se a arte não foi desenhada de frente/direita (+X) — mesma ideia
## do sprite_angle_offset do Player/Anjo.
@export var sprite_angle_offset_deg: float = -90.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Sprite2D

var player: CharacterBody2D = null

var _slow_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO


func _ready() -> void:
	# O StalkerDirector normalmente atribui isso na mão logo depois de
	# instanciar (pra escolher o Player certo em cenas com mais de um caso
	# especial). Mas se o Stalker/StalkerBoss for colocado direto numa cena
	# (ex: o chefe fixo do porão, ou um teste) e ninguém fizer isso, ele
	# ficava parado pra sempre — esse fallback acha o Player sozinho.
	if player == null:
		player = get_tree().get_first_node_in_group("Player") as CharacterBody2D

	# Traça a rota pelo meio de cada abertura em vez do caminho mais curto
	# possível (que corta rente nas quinas) — evita grudar na parede sem
	# precisar erodir o polígono de navegação (isso quebra a conexão entre tiles).
	nav_agent.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_EDGECENTERED


func _physics_process(delta: float) -> void:
	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_friction * delta)

	if player == null:
		velocity = _knockback
		move_and_slide()
		_update_sprite()
		return

	nav_agent.target_position = player.global_position
	_move_along_path()


func _process(delta: float) -> void:
	if _slow_timer > 0.0:
		_slow_timer -= delta


func _current_speed() -> float:
	return speed * slow_amount if _slow_timer > 0.0 else speed


func _move_along_path() -> void:
	var chase_velocity := Vector2.ZERO

	if player == null or global_position.distance_to(player.global_position) > stop_distance:
		var has_path := not nav_agent.is_navigation_finished() and not nav_agent.get_current_navigation_path().is_empty()
		var current_speed := _current_speed()

		if has_path:
			var next_point := nav_agent.get_next_path_position()
			var to_next := next_point - global_position
			# Perto o bastante (ex: rente à borda de um buraco no navmesh), o
			# vetor quase-zero normalizado fica instável e treme.
			if to_next.length() > 1.0:
				chase_velocity = to_next.normalized() * current_speed
		else:
			# Sem navmesh (ainda) ou sem rota: cai pra linha reta, mesmo recurso do Anjo.
			var target := nav_agent.target_position
			if global_position.distance_to(target) > 2.0:
				chase_velocity = (target - global_position).normalized() * current_speed

	velocity = chase_velocity + _knockback
	move_and_slide()
	_update_sprite()


func _update_sprite() -> void:
	# Ciclo de passos só faz sentido girando pra direção que ele anda —
	# sem isso, o sprite fica sempre voltado pro mesmo lado enquanto persegue
	# de qualquer ângulo.
	if velocity.length() > 1.0:
		sprite.rotation = velocity.angle() + deg_to_rad(sprite_angle_offset_deg)


# --- Dano de contato ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_node("Health"):
		body.get_node("Health").apply_damage(dano_toque, global_position)


# --- Imunidade a morte: tiro/faca não mata, só atrapalha ---
func take_damage(_amount: float, _source_position: Vector2) -> void:
	_slow_timer = slow_duration
