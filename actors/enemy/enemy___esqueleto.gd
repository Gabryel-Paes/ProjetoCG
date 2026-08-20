extends CharacterBody2D

# Configurações
@export var speed: float = 20.0
@export var dano_do_ataque: float = 1.0 # <-- NOVO: Dano que este inimigo causa

enum PatrolAxis {
	HORIZONTAL,
	VERTICAL
}

@export var patrol_axis: PatrolAxis = PatrolAxis.HORIZONTAL

@onready var health: Health = $Health

var direction: Vector2
var player: CharacterBody2D = null

# Inicialização
func _ready():
	health.died.connect(die)

	if patrol_axis == PatrolAxis.HORIZONTAL:
		direction = Vector2.RIGHT
	else:
		direction = Vector2.DOWN

# Loop principal
func _physics_process(delta):

	if player != null:
		# Persegue o jogador
		var chase_direction = (player.global_position - global_position).normalized()
		velocity = chase_direction * speed

	else:
		# Patrulha
		velocity = direction * speed

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

func die() -> void:
	queue_free()
