extends Control

const ITEM_PICKUP_SCENE := preload("res://props/item_pickup.tscn")

@export var inventory: Inventory
@export var slot_scene: PackedScene # Arraste inventory_slot.tscn aqui pelo Inspetor
@export var grid_size: int = 9      # 3x3

@onready var grid_container: GridContainer = $MainContainer/GridContainer
@onready var selected_icon: TextureRect = $MainContainer/RightPanel/SelectedIcon
@onready var selected_name: Label = $MainContainer/RightPanel/NameLabel
@onready var selected_desc: Label = $MainContainer/DescLabel
@onready var action_menu: PopupMenu = $PopupMenu

var selected_slot_index: int = -1
var slot_buttons: Array[Button] = []
var player_node: Node = null

func _ready() -> void:
	action_menu.id_pressed.connect(_on_action_selected)
	visible = false

	player_node = get_tree().get_first_node_in_group("Player")

	# Se você não arrastou o inventário pelo Inspetor, o jogo procura automaticamente
	if not inventory and player_node and player_node.has_node("Inventory"):
		inventory = player_node.get_node("Inventory")

	_build_grid()

	if inventory:
		inventory.inventory_updated.connect(_update_ui)
		_update_ui()

func _build_grid() -> void:
	if not slot_scene:
		push_error("inventory_ui: 'slot_scene' não foi definido no Inspetor!")
		return

	for child in grid_container.get_children():
		child.queue_free()
	slot_buttons.clear()

	for i in range(grid_size):
		var slot = slot_scene.instantiate() as Button
		grid_container.add_child(slot)
		slot.pressed.connect(_on_slot_clicked.bind(i))
		slot_buttons.append(slot)

func _update_ui() -> void:
	for i in range(slot_buttons.size()):
		var item = inventory.get_item(i)
		slot_buttons[i].set_item(item, inventory.get_quantity(i))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"): # Crie essa ação no Input Map (tecla 'I' ou 'TAB')
		_set_open(!visible)

# Mostra/esconde o inventário, revela o cursor do mouse e trava os
# comandos de combate do player para não atirar sem querer nos slots.
func _set_open(open: bool) -> void:
	visible = open
	action_menu.hide()
	if not open:
		_clear_preview()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_HIDDEN

	if player_node:
		player_node.menu_open = open
		if player_node.has_node("HUD/Crosshair"):
			player_node.get_node("HUD/Crosshair").visible = not open

func _on_slot_clicked(index: int) -> void:
	var item = inventory.get_item(index)
	if not item:
		_clear_preview()
		return

	selected_slot_index = index

	# Atualiza o painel direito
	var quantity = inventory.get_quantity(index)
	selected_icon.texture = item.texture
	selected_name.text = item.item_name if quantity <= 1 else "%s (x%d)" % [item.item_name, quantity]
	selected_desc.text = item.description

	# Configura o menu de ações flutuante baseado no tipo do item
	action_menu.clear()

	match item.type:
		Item.ItemType.MEDKIT, Item.ItemType.PILLS:
			action_menu.add_item("Usar", 0)
			action_menu.add_item("Descartar", 1)
		Item.ItemType.KEYITEM:
			pass # Itens-chave (arma, lanterna, faca...) não podem ser usados nem descartados pelo inventário
		_:
			action_menu.add_item("Descartar", 1)

	# Só mostra o menu flutuante se houver alguma ação disponível para o item
	if action_menu.item_count > 0:
		action_menu.position = get_viewport().get_mouse_position()
		action_menu.popup()

func _on_action_selected(id: int) -> void:
	var item = inventory.get_item(selected_slot_index)
	if not item:
		return

	match id:
		0: # Usar
			var curou := false
			match item.type:
				Item.ItemType.MEDKIT:
					if player_node and player_node.has_method("heal_full"):
						curou = player_node.heal_full()
				Item.ItemType.PILLS:
					if player_node and player_node.has_method("heal"):
						curou = player_node.heal(item.value)

			# Só consome o item se a cura realmente aconteceu — vida já
			# cheia não gasta Medkit/Pills à toa.
			if curou:
				inventory.consume_item(selected_slot_index) # tira 1 da pilha, não a pilha inteira
				_clear_preview()
		1: # Descartar
			_drop_item(item)
			inventory.consume_item(selected_slot_index) # descarta 1 unidade por vez
			_clear_preview()

# Em vez de só sumir: nasce um ItemPickup de verdade no chão, perto do
# Player — reaproveita a mesma cena de item largado no mapa (com o mesmo
# NudgeOnApproach de "chutar" que os pickups colocados no editor já têm).
func _drop_item(item: Item) -> void:
	var player_2d := player_node as Node2D
	if not player_2d:
		return

	var dropped := ITEM_PICKUP_SCENE.instantiate() as ItemPickup
	dropped.item = item

	# Pequeno espalhamento aleatório — descartar várias vezes seguidas não
	# empilha tudo exatamente no mesmo pixel.
	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(4.0, 10.0)
	dropped.global_position = player_2d.global_position + offset

	get_tree().current_scene.add_child(dropped)

func _clear_preview() -> void:
	selected_icon.texture = null
	selected_name.text = ""
	selected_desc.text = ""
	selected_slot_index = -1
