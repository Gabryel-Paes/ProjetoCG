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

# --- Câmera ---
@export var camera_lead: float = 0.35        # fração do offset do mouse na tela
@export var camera_deadzone: float = 120.0   # px de tela sem deslocamento
@export var max_camera_offset: float = 260.0 # teto do deslocamento
@export var camera_smooth: float = 8.0       # maior = mais rápido
@export var zoom_rest: float = 3.15          # mouse perto: zoom in
@export var zoom_far: float = 1.85           # mouse longe: zoom out

@onready var aim: Node2D = $Aim
@onready var camera: CameraController = $Camera2D
@onready var sprite: Sprite2D = $Aim/Sprite2D
@onready var fumaca: GPUParticles2D = $Aim/BulletPoint/FumacaCano
@onready var gun: Gun = $Aim/Gun

# ---Animação ---
@onready var anim: AnimatedSprite2D = $Aim/AnimatedSprite2D

 # --- luz ---




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


func _update_camera(delta: float) -> void:
	# Offset do mouse em relação ao CENTRO DA TELA — não ao mundo.
	# É isso que quebra o loop de realimentação.
	var viewport_size := get_viewport_rect().size
	var from_center := get_viewport().get_mouse_position() - viewport_size * 0.5
	var dist := from_center.length()

	var lead := Vector2.ZERO
	var t := 0.0

	if dist > camera_deadzone:
		var beyond := dist - camera_deadzone
		var max_beyond := maxf(viewport_size.length() * 0.5 - camera_deadzone, 1.0)
		t = clampf(beyond / max_beyond, 0.0, 1.0)
		lead = (from_center / dist) * minf(beyond * camera_lead, max_camera_offset)

	# Suavização independente de framerate
	var w := 1.0 - exp(-camera_smooth * delta)
	camera.position = camera.position.lerp(lead, w)

	var z := lerpf(zoom_rest, zoom_far, t)
	camera.zoom = camera.zoom.lerp(Vector2(z, z), w)


# ligar e desligar a lanterna
