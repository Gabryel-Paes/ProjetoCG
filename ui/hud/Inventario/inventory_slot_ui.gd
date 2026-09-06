extends Button

@onready var item_icon: TextureRect = $TextureRect
@onready var qty_label: Label = $QtyLabel

var item: Resource = null

# Chamado pelo inventory_ui.gd para atualizar o que esse slot mostra.
func set_item(new_item: Resource, quantity: int = 1) -> void:
	item = new_item
	if item:
		item_icon.texture = item.texture
		item_icon.visible = true
		qty_label.visible = quantity > 1
		qty_label.text = str(quantity)
	else:
		item_icon.texture = null
		item_icon.visible = false
		qty_label.visible = false
