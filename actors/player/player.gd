extends CharacterBody2D

var sprt_normal = preload("res://ui/assets/sprites/Sprite-parado.png")
var sprt_armado = preload("res://ui/assets/sprites/Sprite-armado.png")

var arma_equipada: bool = false

# --- Movimento ---
@export var speed: float = 200.0
@export var acceleration: float = 2400.0   # px/s². Alto = snap estilo Hotline Miami

# --- Mira ---
## Graus de correção se o sprite não foi desenhado apontando para a direita (+X)
@export var sprite_angle_offset: float = 0.0

@onready var aim: Node2D = $Aim
@onready var camera: CameraController = $Camera2D
@onready var sprite: Sprite2D = $Aim/Sprite2D
@onready var fumaca: GPUParticles2D = $Aim/BulletPoint/FumacaCano
@onready var gun: Gun = $Aim/Gun

# ---Animação ---
@onready var anim: AnimatedSprite2D = $Aim/AnimatedSprite2D


var aim_angle: float = 0.0

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	gun.fired.connect(_on_gun_fired)

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("Left", "Right", "Up", "Down")
	velocity = velocity.move_toward(direction * speed, acceleration * delta)
	move_and_slide()
	if direction != Vector2.ZERO:
		anim.play("walking")
	else:
		anim.play("idle")

	gun.set_moving(velocity.length() > 0.0)

func _process(delta: float) -> void:
	_update_aim()

	if Input.is_action_just_pressed("Attack_Melee"):
		$Aim/MeleeAttack.attack()

# --- Controles de Ação ---

func _input(event:InputEvent) -> void:
	#equipar arma
	if event.is_action_pressed("Equipar Arma"):
		arma_equipada = !arma_equipada
		#mudar sprite de arma equipada
		if arma_equipada:
			sprite.texture = sprt_armado
		else:
			sprite.texture = sprt_normal

	if not arma_equipada:
		return

	if event.is_action_pressed("Atirar"):
		gun.try_fire(get_global_mouse_position())
	if event.is_action_pressed("Recarregar"):
		gun.try_reload()

func _on_gun_fired() -> void:
	camera.shake(1.0)
	fumaca.restart()

func _update_aim() -> void:
	# Guardado como variável: sprite, lanterna e projétil bebem da mesma fonte
	aim_angle = (get_global_mouse_position() - global_position).angle()
	aim.rotation = aim_angle + deg_to_rad(sprite_angle_offset)
