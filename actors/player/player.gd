extends CharacterBody2D

var sprt_normal = preload("res://ui/assets/sprites/Sprite-idle.png")
var sprt_armado = preload("res://ui/assets/sprites/Sprite-armado.png")
var sprt_faca = preload("res://ui/assets/sprites/Sprite-faca.png")
var sprt_corpse = preload("res://ui/assets/sprites/corpse.png")

signal weapon_changed(weapon: Weapon)
enum Weapon { NONE, KNIFE, PISTOL }

@export var unarmed_speed_multiplier: float = 1.07 # Mãos vazias = um pouco mais rápido

var weapon_order: Array[Weapon] = [Weapon.NONE, Weapon.KNIFE, Weapon.PISTOL]
var weapon_index: int = 0
var current_weapon: Weapon = Weapon.NONE

@onready var melee = $Aim/MeleeAttack

# --- Vida ---
@onready var health: Health = $Health
@onready var blood_overlay = $HUD/BloodOverlay
# --- Movimento ---
@export var base_speed: float = 95.0
@export var sprint_speed: float = 190.0 # Velocidade da corrida
@export var sprint_cost: float = 25.0   # Custo de stamina por segundo
@export var acceleration: float = 2400.0   # px/s². Alto = snap estilo Hotline Miami
# --- Chute em itens ---
# move_and_slide() NÃO empurra RigidBody2D sozinho — só resolve o próprio
# movimento do Player, tratando o item como obstáculo. Sem isso, esbarrar
# num item largado (ItemPickup) parece esbarrar numa parede.
@export var item_push_strength: float = 0.35 # fração da sua velocidade que vira impulso no item
# --- Knockback ---
# Sem isso, um inimigo com velocidade igual/maior que a sua sempre reocupava
# o espaço no frame seguinte e dava a sensação de "grudar" ao encostar.
@export var knockback_strength: float = 220.0 # impulso aplicado ao tomar dano
@export var knockback_friction: float = 900.0 # px/s² de quão rápido o empurrão desaparece
var _input_velocity: Vector2 = Vector2.ZERO   # movimento controlado pelo jogador
var _knockback: Vector2 = Vector2.ZERO        # empurrão externo, decai sozinho
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
@onready var inventory: Inventory = $Inventory
@onready var knife_attack: AnimatedSprite2D = $Aim/KnifeAttack

# ---Animação ---
@onready var anim: AnimatedSprite2D = $Aim/AnimatedSprite2D
@onready var legs: AnimatedSprite2D = $Legs

var _knife_swinging: bool = false
var _knife_combo_queued: bool = false

# --- luz ---
# Exposto pra outros scripts (ex: angel.gd) checarem o estado da lanterna.
@onready var flashlight: PlayerFlashlight = $Aim/PointLight2D

var aim_angle: float = 0.0
var menu_open: bool = false # travado pelo inventory_ui.gd enquanto o menu está aberto

# --- Morte ---
@export var corpse_throw_distance: float = 40.0 # o quanto o corpo desliza na direção do último hit
@export var corpse_throw_duration: float = 0.35
@export var death_screen_delay: float = 2.0 # tempo parado, olhando pro corpo, antes da tela de morte
## Ajusta a rotação do sprite do corpo — mesma ideia do sprite_angle_offset,
## só que aplicado na direção do golpe em vez da mira.
@export var corpse_angle_offset_deg: float = -90.0

var _last_hit_direction: Vector2 = Vector2.RIGHT
var _is_dead: bool = false

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	hud.visible = true
	gun.fired.connect(_on_gun_fired)
	knife_attack.animation_finished.connect(_on_knife_animation_finished)

	stamina.stamina_changed.connect(_update_stamina_bar)
	# NOVO: Conecta a vida mudando à função que atualiza o sangue
	health.health_changed.connect(_update_blood_overlay)
	# died já vem conectado a _die() pelo próprio player.tscn (editor) —
	# conectar de novo aqui duplicava o sinal.
	health.damaged.connect(_on_damaged)

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

func _on_damaged(_amount: float, source_position: Vector2) -> void:
	var push_dir := global_position - source_position
	if push_dir.length() < 0.01:
		push_dir = Vector2.RIGHT # posições coincidentes: empurra em qualquer direção em vez de ficar zerado
	push_dir = push_dir.normalized()
	_knockback = push_dir * knockback_strength
	# Guardado pra _die() saber pra que lado jogar o corpo caso esse seja o
	# hit que zerou a vida.
	_last_hit_direction = push_dir

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
	_input_velocity = _input_velocity.move_toward(direction * target_speed, acceleration * delta)
	# Empurrão de knockback é somado por cima e desaparece sozinho — assim ele
	# te afasta de verdade do inimigo mesmo se você não estiver se mexendo.
	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_friction * delta)
	velocity = _input_velocity + _knockback
	move_and_slide()
	_push_kicked_bodies()

	if direction != Vector2.ZERO:
		anim.play("walking")
		# +90°: a arte das pernas foi desenhada de frente (postura vertical),
		# não de lado — mesma correção que o Sprite2D do corpo já usa.
		legs.rotation = direction.angle() + PI / 2.0
		legs.play("walking")
	else:
		anim.play("idle")
		legs.stop() # congela no último quadro, pernas paradas

	gun.set_moving(velocity.length() > 0.0)

# Empurra na mão qualquer RigidBody2D que o move_and_slide() acabou de
# encostar (ex: ItemPickup chutável) — sem isso ele fica parado feito parede.
func _push_kicked_bodies() -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			var push_dir := -collision.get_normal()
			collider.apply_central_impulse(push_dir * velocity.length() * item_push_strength)

func _process(_delta: float) -> void:
	if _is_dead:
		return
	_update_aim()

# --- Controles de Ação ---

func _input(event:InputEvent) -> void:
	if menu_open or _is_dead:
		return
	if event.is_action_pressed("NextWeapon"):
		_cycle_weapon(1)
	elif event.is_action_pressed("LastWeapon"):
		_cycle_weapon(-1)
	elif event.is_action_pressed("Attack"):
		_try_attack()
	elif event.is_action_pressed("Recarregar") and current_weapon == Weapon.PISTOL:
		gun.try_reload(inventory)
	elif event.is_action_pressed("Lanterna"):
		_toggle_flashlight()

func _toggle_flashlight() -> void:
	flashlight.enabled = !flashlight.enabled
	# O toggle da lanterna (tecla F) mora no próprio point_light_2d.gd agora —
	# não duplica aqui.

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
				_play_knife_swing()
		Weapon.NONE:
			pass # mãos vazias não atacam

func _play_knife_swing() -> void:
	if _knife_swinging:
		# Já está no meio de um golpe: sinaliza que é pra continuar pro combo
		_knife_combo_queued = true
		return

	_knife_swinging = true
	_knife_combo_queued = false
	sprite.visible = false
	knife_attack.visible = true
	knife_attack.play("swing_start")

func _on_knife_animation_finished() -> void:
	if knife_attack.animation == "swing_start" and _knife_combo_queued:
		_knife_combo_queued = false
		knife_attack.play("swing_finish")
		return

	# Acabou de vez (golpe único, ou combo já terminou)
	_knife_swinging = false
	knife_attack.visible = false
	sprite.visible = true

func _on_gun_fired() -> void:
	camera.shake(1.0)
	fumaca.restart()

func _update_aim() -> void:
	# Guardado como variável: sprite, lanterna e projétil bebem da mesma fonte
	aim_angle = (get_global_mouse_position() - global_position).angle()
	aim.rotation = aim_angle + deg_to_rad(sprite_angle_offset)

func _die() -> void:
	if _is_dead:
		return
	_is_dead = true

	# Trava o Player: sem input, sem física normal (paramos o
	# _physics_process inteiro, então move_and_slide() não roda mais — o
	# "arremesso" abaixo move a posição direto, sem física).
	set_physics_process(false)

	# Vira o corpo: esconde qualquer coisa de combate que possa ter ficado no
	# ar (golpe de faca no meio da animação) e as pernas separadas (o
	# corpse.png já é um corpo inteiro, não precisa da Legs por baixo
	# congelada no meio de uma passada) — e troca pro sprite do cadáver.
	knife_attack.visible = false
	legs.visible = false
	sprite.visible = true
	sprite.texture = sprt_corpse
	sprite.rotation = _last_hit_direction.angle() + deg_to_rad(corpse_angle_offset_deg)
	aim.rotation = 0.0 # solta a mira — o corpo não aponta mais pra lugar nenhum

	# "Arremessa" o corpo na direção do último golpe que zerou a vida.
	var destino := global_position + _last_hit_direction * corpse_throw_distance
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", destino, corpse_throw_duration)

	# Segura a cena aqui — corpo caído, sem fazer nada — pra dar tempo do
	# jogador entender o que aconteceu antes da tela de morte definitiva.
	await get_tree().create_timer(death_screen_delay).timeout

	# died dispara no meio de um callback de física (Hitbox/apply_damage) —
	# trocar de cena tenta remover o Player (CollisionObject2D) nesse
	# momento, o que o Godot não permite. Mantido deferred por segurança,
	# mesmo já estando alguns frames depois por causa do await acima.
	get_tree().change_scene_to_file.call_deferred("res://ui/menu/death_screen.tscn")

# --- Cura (chamado pela UI do inventário ao usar Medkit/Pills) ---
func heal(amount: float) -> bool:
	return health.heal(amount)

func heal_full() -> bool:
	return health.heal_full()
