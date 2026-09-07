extends CharacterBody2D

# Configurações
@export var speed: float = 25.0
@export var dano_do_ataque: float = 1.0 # <-- NOVO: Dano que este inimigo causa

## Distância em que ele para de avançar. Sem isso ele mira o centro exato do
## Player pra sempre e fica "empurrando"/colado nele — e perto o bastante o
## vetor de direção (quase zero) normalizado fica instável e treme.
@export var stop_distance: float = 8.0

## Pequeno empurrão ao tomar dano (tiro/faca), pra dar espaço de reação.
@export var knockback_strength: float = 160.0
@export var knockback_friction: float = 900.0

enum PatrolAxis {
	HORIZONTAL,
	VERTICAL
}

@export var patrol_axis: PatrolAxis = PatrolAxis.HORIZONTAL

@onready var health: Health = $Health

var direction: Vector2
var player: CharacterBody2D = null
var _knockback: Vector2 = Vector2.ZERO

# Inicialização
func _ready():
	health.died.connect(die)
	health.damaged.connect(_on_damaged)

	if patrol_axis == PatrolAxis.HORIZONTAL:
		direction = Vector2.RIGHT
	else:
		direction = Vector2.DOWN

# Loop principal
func _physics_process(delta):
	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_friction * delta)
	var chase_velocity := Vector2.ZERO

	if player != null:
		# Persegue o jogador, mas para perto o bastante em vez de ficar
		# empurrando/colado nele pra sempre.
		var to_player = player.global_position - global_position
		if to_player.length() > stop_distance:
			chase_velocity = to_player.normalized() * speed

	else:
		# Patrulha
		chase_velocity = direction * speed

	velocity = chase_velocity + _knockback
	move_and_slide()

	# Se estiver patrulhando e bater em algo, inverte a direção.
	if player == null:
		if get_slide_collision_count() > 0:
			direction *= -1

# Área de detecção (Visão do Inimigo)
func _on_detection_area_body_entered(body):
	if body.is_in_group("Player"):
		player = body

func _on_detection_area_body_exited(body):
	if body == player:
		player = null

# --- NOVO: Lógica de Causar Dano (Hitbox) ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	# Confirma se é o Player e se ele possui o componente de vida
	if body.is_in_group("Player") and body.has_node("Health"):
		var alvo_health = body.get_node("Health")
		alvo_health.apply_damage(dano_do_ataque, global_position)


# Dano recebido pelo inimigo
func take_damage(amount: float, source_position: Vector2) -> void:
	health.apply_damage(amount, source_position)

func _on_damaged(_amount: float, source_position: Vector2) -> void:
	var push_dir := global_position - source_position
	if push_dir.length() < 0.01:
		push_dir = Vector2.RIGHT
	_knockback = push_dir.normalized() * knockback_strength

func die() -> void:
	queue_free()
