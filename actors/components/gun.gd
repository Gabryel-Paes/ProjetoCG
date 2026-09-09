extends Node2D
class_name Gun

const IMPACT_WALL := preload("res://props/impact_wall.tscn")
const IMPACT_BLOOD := preload("res://props/impact_blood.tscn")

signal ammo_changed(current: int, max_ammo: int)
signal reload_started()
signal ammo_empty()
signal spread_changed(value: float)
signal fired()

# --- Disparo ---
@export var fire_rate: float = 0.3
@export var dano_tiro: float = 10.0
@export var alcance_maximo: float = 1000.0

# --- Munição ---
@export var municao_maxima: int = 6
@export var tempo_recarga: float = 1.5

# --- Spread ---
@export var spread_andando: float = 12.0
@export var spread_parado: float = 1.0
@export var velocidade_mira: float = 20.0
@export var recuo: float = 4.0

var municao_atual: int
var pode_atirar: bool = true
var recarregando: bool = false
var spread_atual: float = 1.0
var moving: bool = false

@onready var sfx_gunshot: AudioStreamPlayer2D = $SfxGunshot
@onready var sfx_reload: AudioStreamPlayer2D = $SfxReload
## Clique de "sem munição" — toca quando o gatilho é puxado com o pente vazio.
@onready var sfx_click: AudioStreamPlayer2D = $SfxClick


func _ready() -> void:
	municao_atual = municao_maxima
	ammo_changed.emit(municao_atual, municao_maxima)


func _process(delta: float) -> void:
	if moving:
		spread_atual = lerpf(spread_atual, spread_andando, 10.0 * delta)
	else:
		spread_atual = move_toward(spread_atual, spread_parado, velocidade_mira * delta)

	spread_changed.emit(spread_atual)


func set_moving(value: bool) -> void:
	moving = value


func try_fire(alvo: Vector2) -> bool:
	if not pode_atirar or recarregando:
		return false

	if municao_atual <= 0:
		ammo_empty.emit()
		sfx_click.play()
		return false

	pode_atirar = false
	municao_atual -= 1
	ammo_changed.emit(municao_atual, municao_maxima)
	sfx_gunshot.play()

	# --- Lógica do Hitscan ---
	##Direção base reta até o alvo
	var direcao_base = (alvo - global_position).normalized()
	##Sorteia o desvio baseado no spread atual
	var desvio = deg_to_rad(randf_range(-spread_atual, spread_atual))
	##Gira direcao base aplicando desvio
	var direcao_tiro = direcao_base.rotated(desvio)
	##Coice
	spread_atual = min(spread_atual + recuo, spread_andando)

	var destino = global_position + (direcao_tiro * alcance_maximo)
	var space_state = get_world_2d().direct_space_state

	# Raycast principal: só corpos físicos (paredes, corpo do inimigo) —
	# decide só onde a bala visualmente para (o rastro/impacto).
	var query = PhysicsRayQueryParameters2D.create(global_position, destino)
	query.exclude = [owner]

	var result = space_state.intersect_ray(query)
	var ponto_impacto = destino
	if result:
		ponto_impacto = result.position

	# Raycast separado, só até onde a bala parou, filtrado só pra layer
	# "hurtbox" (4) — a mesma área que a faca usa (melee_attack.gd). Feito
	# à parte do raycast principal de propósito: Trigger_Up/Trigger_Down/
	# DetectionArea/InteractArea não têm collision_layer definida (ficam na
	# 1, "world", junto das paredes) — se o raycast principal enxergasse
	# áreas também, a bala ia parar em zonas de gatilho invisíveis por engano.
	var hurtbox_query = PhysicsRayQueryParameters2D.create(global_position, ponto_impacto)
	hurtbox_query.exclude = [owner]
	hurtbox_query.collide_with_bodies = false
	hurtbox_query.collide_with_areas = true
	hurtbox_query.collision_mask = 8 # só "hurtbox"

	var hurtbox_result = space_state.intersect_ray(hurtbox_query)
	if hurtbox_result:
		var atingido = hurtbox_result.collider
		if atingido.has_method("take_damage"):
			atingido.take_damage(dano_tiro, hurtbox_result.position)
		# A Hurtbox em si não tem o método — quem tem é o dono dela (o
		# inimigo), mesmo fallback que o ataque de faca já usa.
		elif atingido.owner and atingido.owner.has_method("take_damage"):
			atingido.owner.take_damage(dano_tiro, hurtbox_result.position)

		# Sangue, continuando na direção que a bala vinha andando.
		_spawn_impact(IMPACT_BLOOD, hurtbox_result.position, direcao_tiro.angle())
	elif result:
		# Poeira/estilhaço, jogado pra fora na direção da normal da
		# superfície (result.normal) — sem isso o efeito saía "de lado"
		# em vez de espirrar pra fora da parede.
		var normal_valida = result.normal if result.normal != Vector2.ZERO else -direcao_tiro
		_spawn_impact(IMPACT_WALL, result.position, normal_valida.angle())

	_criar_rastro(global_position, ponto_impacto)
	fired.emit()

	await get_tree().create_timer(fire_rate).timeout
	pode_atirar = true
	return true


func try_reload(inventory: Inventory = null) -> bool:
	if recarregando or municao_atual >= municao_maxima:
		return false

	# Se um inventário foi passado, a recarga só acontece se houver uma
	# pilha de munição nele — e essa pilha é gasta (1 unidade) na hora.
	if inventory:
		var ammo_slot = _find_ammo_slot(inventory)
		if ammo_slot == -1:
			ammo_empty.emit()
			return false
		inventory.consume_item(ammo_slot)

	recarregando = true
	reload_started.emit()
	sfx_reload.play()

	await get_tree().create_timer(tempo_recarga).timeout
	municao_atual = municao_maxima
	recarregando = false
	ammo_changed.emit(municao_atual, municao_maxima)
	return true


func _find_ammo_slot(inventory: Inventory) -> int:
	for i in range(inventory.capacity):
		var item = inventory.get_item(i)
		if item and item.type == Item.ItemType.AMMO and inventory.get_quantity(i) > 0:
			return i
	return -1


func _spawn_impact(cena: PackedScene, posicao: Vector2, angulo: float) -> void:
	var efeito: GPUParticles2D = cena.instantiate()
	efeito.global_position = posicao
	efeito.rotation = angulo

	_apply_floor_layering(efeito)
	get_tree().root.add_child(efeito)


# Mesmo problema do Stalker (stalker_director.gd): TileMap_2sFloor desenha em
# z_index 1 e só é iluminado por luzes com light_mask 2 — qualquer coisa
# nascida dinamicamente (fora da árvore estática da cena) fica sempre em
# z_index/light_mask padrão (0/1, térreo) e some atrás do chão do mezanino,
# sem luz nenhuma, com o Player no 2º andar. `owner` aqui é o Player (mesmo
# nó já excluído dos raycasts acima).
func _apply_floor_layering(node: CanvasItem) -> void:
	if owner and owner.get_collision_layer_value(7):
		node.z_index = 1
		node.light_mask = 2


func _criar_rastro(inicio: Vector2, fim: Vector2) -> void:
	var linha = Line2D.new()
	linha.add_point(inicio)
	linha.add_point(fim)
	linha.width = 1.5
	linha.default_color = Color(1.0, 0.973, 0.808, 1.0)

	_apply_floor_layering(linha)
	get_tree().root.add_child(linha)

	var tween = create_tween()
	tween.tween_property(linha, "modulate:a", 0.0, 0.07)
	tween.tween_callback(linha.queue_free)
