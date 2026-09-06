class_name Inventory
extends Node

signal inventory_updated

@export var capacity: int = 9
@export var starting_items: Array[Item] = [] # Itens (.tres) que o personagem já começa com no inventário
var slots: Array = []
var quantities: Array = []
var _initialized: bool = false

func _ready() -> void:
	_ensure_slots()

# Garante que slots existam e que os starting_items já tenham sido
# adicionados, não importa quem chame o Inventory primeiro (a UI ou o
# próprio _ready deste nó — a ordem entre nós irmãos não é garantida).
func _ensure_slots() -> void:
	if slots.size() != capacity:
		slots.resize(capacity)
		quantities.resize(capacity)
		for i in range(capacity):
			if quantities[i] == null:
				quantities[i] = 0
	if not _initialized:
		_initialized = true
		for item in starting_items:
			add_item(item)

# Se o item já existe numa pilha (e for empilhável), só soma +1 nela.
# Caso contrário procura um slot vazio e cria uma pilha nova.
func add_item (item: Item) -> bool:
	_ensure_slots()
	if item == null:
		return false

	if item.stackable:
		for i in range(capacity):
			if slots[i] == item:
				quantities[i] += 1
				inventory_updated.emit()
				return true

	for i in range(capacity):
		if slots[i] == null:
			slots[i] = item
			quantities[i] = 1
			inventory_updated.emit()
			return true
	return false

# Consome 1 unidade da pilha (usado ao "Usar" ou "Descartar" um item).
# Quando a quantidade chega a 0, o slot libera por completo.
func consume_item(index: int) -> void:
	_ensure_slots()
	if index < 0 or index >= capacity or slots[index] == null:
		return
	quantities[index] -= 1
	if quantities[index] <= 0:
		slots[index] = null
		quantities[index] = 0
	inventory_updated.emit()

# Descarta a pilha inteira de uma vez (não usado pela UI atualmente, mas
# fica disponível caso algum sistema precise esvaziar o slot de golpe).
func remove_item (index: int) -> void:
	_ensure_slots()
	if index >= 0 and index < capacity:
		slots[index] = null
		quantities[index] = 0
		inventory_updated.emit()

func get_item(index: int) -> Item:
	_ensure_slots()
	if index >= 0 and index < capacity:
		return slots[index]
	return null

func get_quantity(index: int) -> int:
	_ensure_slots()
	if index >= 0 and index < capacity:
		return quantities[index]
	return 0

func has_ammo() -> bool:
	_ensure_slots()
	for item in slots:
		if item and item.type == Item.ItemType.AMMO:
			return true
	return false
