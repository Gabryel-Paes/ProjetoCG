extends CharacterBody2D

var sprt_normal = preload("res://ui/assets/sprites/Sprite-idle.png")
var sprt_armado = preload("res://ui/assets/sprites/Sprite-armado.png")
var sprt_faca = preload("res://ui/assets/sprites/Sprite-faca.png")

signal weapon_changed(weapon: Weapon)
enum Weapon { NONE, KNIFE, PISTOL }

@export var unarmed_speed_multiplier: float = 1.15 # Mãos vazias = um pouco mais rápido

var weapon_order: Array[Weapon] = [Weapon.NONE, Weapon.KNIFE, Weapon.PISTOL]
var weapon_index: int = 0
var current_weapon: Weapon = Weapon.NONE

@onready var melee = $Aim/MeleeAttack

# --- Vida ---
@onready var health: Health = $Health
@onready var blood_overlay = $HUD/BloodOverlay
# --- Movimento ---
@export var base_speed: float = 200.0
@export var sprint_speed: float = 350.0 # Velocidade da corrida
@export var sprint_cost: float = 25.0   # Custo de stamina por segundo
@export var acceleration: float = 2400.0   # px/s². Alto = snap estilo Hotline Miami
@onready var stamina = $Stamina
@onready var stamina_bar = $HUD/StaminaBar
# --- Mira ---
## Graus de correção se o sprite não foi desenhado apontando para a direita (+X)
@export var sprite_angle_offset: float = 0.0

@onready var aim: Node2D = $Aim
@onready var hud: CanvasLayer = $HUD
@onready var camera: CameraController = $Camera2D
@onready var sprite: Sprite2D = $Aim/Sprite2D
@onready var fumaca: GPUParticles2D = $Aim/BulletPoint/FumacaCano
@onready var gun: Gun = $Aim/Gun

# ---Animação ---
@onready var anim: AnimatedSprite2D = $Aim/AnimatedSprite2D


var aim_angle: float = 0.0

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	hud.visible = true
	gun.fired.connect(_on_gun_fired)

	stamina.stamina_changed.connect(_update_stamina_bar)
	# NOVO: Conecta a vida mudando à função que atualiza o sangue
	health.health_changed.connect(_update_blood_overlay)

	# Garante que o sangue comece invisível
	blood_overlay.modulate.a = 0.0
	stamina_bar.modulate.a = 0.0

	_equip_weapon(current_weapon)

func _update_stamina_bar(current: float, max_value: float) -> void:
	stamina_bar.max_value = max_value
	stamina_bar.value = current
	
	# Se a stamina for menor que o máximo (você correu ou atacou)
	if current < max_value:
		# Aparece instantaneamente
		stamina_bar.modulate.a = 1.0 
	else:
		# Se a stamina voltou pro máximo, some suavemente ao longo de 0.5 segundos
		var tween = create_tween()
		tween.tween_property(stamina_bar, "modulate:a", 0.0, 0.5)

func _update_blood_overlay(current_health: float, max_health: float) -> void:
	# Calcula a porcentagem de DANO sofrido (0.0 a 1.0)
	# Se a vida for 3/3, o dano é 0.0. Se for 1/3, é ~0.66.
	var damage_percent = 1.0 - (current_health / max_health)
	
	# Cria uma animação suave (Tween) da transparência atual até a nova
	# O 0.3 no final é o tempo da animação (0.3 segundos)
	var tween = create_tween()
	tween.tween_property(blood_overlay, "modulate:a", damage_percent, 0.3)

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("Left", "Right", "Up", "Down")
	
	# Começa com a velocidade base
	var target_speed = base_speed
	
	# Verifica se está segurando Shift, se está se movendo, e se tem stamina
	if Input.is_action_pressed("Sprint") and direction != Vector2.ZERO:
		if stamina.drain_stamina(sprint_cost * delta):
			target_speed = sprint_speed # Acelera o passo!

	if current_weapon == Weapon.NONE:
		target_speed *= unarmed_speed_multiplier

	# Aplica o target_speed na movimentação (mantendo sua aceleração fluida)
	velocity = velocity.move_toward(direction * target_speed, acceleration * delta)
	move_and_slide()
	
	if direction != Vector2.ZERO:
		anim.play("walking")
	else:
		anim.play("idle")

	gun.set_moving(velocity.length() > 0.0)

func _process(delta: float) -> void:
	_update_aim()

# --- Controles de Ação ---

func _input(event:InputEvent) -> void:
	if event.is_action_pressed("NextWeapon"):
		_cycle_weapon(1)
	elif event.is_action_pressed("LastWeapon"):
		_cycle_weapon(-1)
	elif event.is_action_pressed("Attack"):
		_try_attack()
	elif event.is_action_pressed("Recarregar") and current_weapon == Weapon.PISTOL:
		gun.try_reload()

func _cycle_weapon(step: int) -> void:
	var count := weapon_order.size()
	weapon_index = (weapon_index + step + count) % count
	_equip_weapon(weapon_order[weapon_index])

func _equip_weapon(weapon: Weapon) -> void:
	current_weapon = weapon
	weapon_changed.emit(weapon)
	match weapon:
		Weapon.NONE:
			sprite.texture = sprt_normal
		Weapon.KNIFE:
			sprite.texture = sprt_faca
		Weapon.PISTOL:
			sprite.texture = sprt_armado

func _try_attack() -> void:
	match current_weapon:
		Weapon.PISTOL:
			gun.try_fire(get_global_mouse_position())
		Weapon.KNIFE:
			# Tenta gastar 20 de stamina para o golpe de faca
			if stamina.drain_stamina(20.0):
				melee.attack()
		Weapon.NONE:
			pass # mãos vazias não atacam

func _on_gun_fired() -> void:
	camera.shake(1.0)
	fumaca.restart()

func _update_aim() -> void:
	# Guardado como variável: sprite, lanterna e projétil bebem da mesma fonte
	aim_angle = (get_global_mouse_position() - global_position).angle()
	aim.rotation = aim_angle + deg_to_rad(sprite_angle_offset)
func _die() -> void: 
	print("MOrreu");
