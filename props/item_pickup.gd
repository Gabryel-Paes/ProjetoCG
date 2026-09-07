extends RigidBody2D
class_name ItemPickup

# --- Item largado no chão ---
# É um RigidBody2D de verdade (não Area2D) de propósito: andar contra ele
# empurra/"chuta" o item pra valer, deslizando até parar sozinho por atrito
# — física de verdade, não um balancinho que volta pro lugar (isso é só pra
# decoração, ver nudge_on_approach.gd). A detecção de "pode pegar com E"
# mora à parte, no PickupArea (Area2D filho), com um alcance maior que o
# corpo físico do item.

@export var item: Item
@export var amount: int = 1
@export var prompt_text: String = "Pressione E para pegar"

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $PromptLabel

var _player_in_range: Node2D = null


func _ready() -> void:
	prompt.text = prompt_text
	prompt.visible = false
	if item:
		sprite.texture = item.texture


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("Interact"):
		_collect()


func _collect() -> void:
	if not item or not _player_in_range:
		return
	if not _player_in_range.has_node("Inventory"):
		return

	var inventory: Inventory = _player_in_range.get_node("Inventory")
	var collected := 0
	for i in range(amount):
		if inventory.add_item(item):
			collected += 1
		else:
			break # inventário cheio, o resto fica no chão

	if collected >= amount:
		queue_free()


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		_player_in_range = body
		prompt.visible = true


func _on_pickup_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		prompt.visible = false
