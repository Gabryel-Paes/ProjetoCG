extends CharacterBody2D

# Configurações
@export var speed: float = 20.0
enum PatrolAxis {
	HORIZONTAL,
	VERTICAL
}

@export var patrol_axis: PatrolAxis = PatrolAxis.HORIZONTAL
@export var health: float = 30.0

var direction: Vector2
var player: CharacterBody2D = null

# Inicialização
func _ready():

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

	# Se estiver patrulhando e bater em algo,
	# inverte a direção.

	if player == null:

		if get_slide_collision_count() > 0:
			direction *= -1

# Área de detecção
func _on_detection_area_body_entered(body):

	if body.is_in_group("Player"):
		player = body

func _on_detection_area_body_exited(body):

	if body == player:
		player = null

# Dano
func take_damage(amount: float, _source_position: Vector2) -> void:
	health -= amount
	print("Inimigo tomou dano! Vida restante: ", health)

	if health <= 0:
		die()

func die() -> void:
	queue_free()
