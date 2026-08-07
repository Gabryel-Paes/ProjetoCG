extends CharacterBody2D

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
@export var zoom_rest: float = 1.15          # mouse perto: zoom in
@export var zoom_far: float = 0.85           # mouse longe: zoom out

@onready var aim: Node2D = $Aim
@onready var camera: Camera2D = $Camera2D

# ---Animação ---
@onready var anim: AnimatedSprite2D = $Aim/AnimatedSprite2D


var aim_angle: float = 0.0


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("Left", "Right", "Up", "Down")
	velocity = velocity.move_toward(direction * speed, acceleration * delta)
	move_and_slide()
	if direction != Vector2.ZERO:
		anim.play("walking")
	else:
		anim.play("idle")
	


func _process(delta: float) -> void:
	_update_aim()
	_update_camera(delta)


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
