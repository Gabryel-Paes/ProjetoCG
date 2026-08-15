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

# --- Spread ---
@export var spread_andando: float  = 12.0 
@export var spread_parado: float = 1.0
@export var velocidade_mira: float = 20.0
@export var recuo: float = 4.0

var spread_atual: float = 1.0

# --- Armamento ---
@export var fire_rate: float = 0.3
var pode_atirar: bool = true

@export var municao_maxima: int = 6
var municao_atual: int = municao_maxima
@export var tempo_recarga: float = 1.5
var recarregando: bool = false

# --- Câmera ---
@export var camera_lead: float = 0.35        # fração do offset do mouse na tela
@export var camera_deadzone: float = 120.0   # px de tela sem deslocamento
@export var max_camera_offset: float = 260.0 # teto do deslocamento
@export var camera_smooth: float = 8.0       # maior = mais rápido
@export var zoom_rest: float = 3         # mouse perto: zoom in
@export var zoom_far: float = 2       # mouse longe: zoom out

#--- Screen Shake ---
@export var forca_tremor: float = 20.0 # Numero de pixel que a cam vai tremer
@export var decay: float = 3.0 # Velocidade de decaimento do tremor
var tremor_atual: float = 0.0 # dá pra imaginar

@onready var aim: Node2D = $Aim
@onready var camera: Camera2D = $Camera2D
@onready var sprite: Sprite2D = $Aim/Sprite2D
@onready var label_ammo: Label = $HUD/LabelMunicao
@onready var fumaca: GPUParticles2D = $Aim/BulletPoint/FumacaCano

var aim_angle: float = 0.0

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	
	municao_atual = municao_maxima
	atualizar_hud()

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("Left", "Right", "Up", "Down")
	velocity = velocity.move_toward(direction * speed, acceleration * delta)
	move_and_slide()

func _process(delta: float) -> void:
	_update_aim()
	_update_camera(delta)
	_update_spread(delta)

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
	
	if event.is_action_pressed("Atirar") and arma_equipada and pode_atirar and not recarregando:
		if municao_atual > 0:
			atirar()
		else: label_ammo.text = "Sem munição."
	if event.is_action_pressed("Recarregar") and arma_equipada and not recarregando:
		if municao_atual < municao_maxima:
			recarregar()
	
func atualizar_hud()-> void:
	label_ammo.text = str(municao_atual) + " / " + str(municao_maxima)

func recarregar() -> void:
	recarregando = true
	label_ammo.text = "Recarregando..."
	
	await get_tree().create_timer(tempo_recarga).timeout
	municao_atual = municao_maxima
	recarregando = false
	atualizar_hud()


func atirar() -> void:
	
	pode_atirar = false
	
	municao_atual -= 1
	atualizar_hud()
	
	fumaca.restart()
	
	#Pega o marker2D
	var ponto_disparo = $Aim/BulletPoint
	
	tremor_atual = 1.0
	
	# --- Lógica do Hitscan ---
	var space_state = get_world_2d().direct_space_state
	

	##Direção base reta até o mouse
	var direcao_base = (get_global_mouse_position() - ponto_disparo.global_position).normalized()
	##Sorteia o desvio baseado no spread atual
	var desvio = deg_to_rad(randf_range(-spread_atual, spread_atual))
	##Gira direcao base aplicando desvio
	var direcao_tiro = direcao_base.rotated(desvio)
	##Coice
	spread_atual = min(spread_atual + recuo, spread_andando)
	
	var alcance_maximo = 1000.0
	var destino = ponto_disparo.global_position + (direcao_tiro * alcance_maximo)
	var query = PhysicsRayQueryParameters2D.create(ponto_disparo.global_position, destino)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	var ponto_impacto = destino
	
	if result:
		ponto_impacto = result.position
		#particulas aqui depois
		# if result.collider.has_method("tomar_dano"):
		#     result.collider.tomar_dano(10)
		
	criar_rastro(ponto_disparo.global_position, ponto_impacto)
	
	await get_tree().create_timer(fire_rate).timeout
	pode_atirar = true

func criar_rastro(inicio: Vector2, fim: Vector2) -> void:
	var linha = Line2D.new()
	linha.add_point(inicio)
	linha.add_point(fim)
	linha.width = 1.5
	linha.default_color = Color(1.0,0.9,0.5,0.8)
	
	get_tree().root.add_child(linha)
	
	var tween = create_tween()
	tween.tween_property(linha, "modulate:a", 0.0, 0.2)
	tween.tween_callback(linha.queue_free)

func _update_spread (delta:float) -> void:
	if velocity.length() > 0:
		spread_atual = lerpf(spread_atual, spread_andando, 10.0 * delta)
	else:
		spread_atual = move_toward(spread_atual, spread_parado, velocidade_mira * delta)

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
	
	# -- Camera Shake --
	if tremor_atual > 0:
		tremor_atual = max(tremor_atual - decay * delta, 0.0)
		var forca = pow(tremor_atual, 2)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * forca_tremor * forca
		
	else:
		camera.offset = Vector2.ZERO
