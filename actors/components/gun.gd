extends Node2D
class_name Gun

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
		return false

	pode_atirar = false
	municao_atual -= 1
	ammo_changed.emit(municao_atual, municao_maxima)

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
	var query = PhysicsRayQueryParameters2D.create(global_position, destino)
	query.exclude = [owner]

	var result = space_state.intersect_ray(query)
	var ponto_impacto = destino

	if result:
		ponto_impacto = result.position
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(dano_tiro, ponto_impacto)

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


func _criar_rastro(inicio: Vector2, fim: Vector2) -> void:
	var linha = Line2D.new()
	linha.add_point(inicio)
	linha.add_point(fim)
	linha.width = 1.5
	linha.default_color = Color(1.0, 0.973, 0.808, 1.0)

	get_tree().root.add_child(linha)

	var tween = create_tween()
	tween.tween_property(linha, "modulate:a", 0.0, 0.07)
	tween.tween_callback(linha.queue_free)
