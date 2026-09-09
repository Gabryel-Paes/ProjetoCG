extends StaticBody2D
class_name ShortcutDoor

# --- Porta de atalho (estilo Dark Souls/Resident Evil) ---
# Só dá pra abrir pelo lado onde a InteractArea está — o corpo sólido da
# própria porta impede o Player de alcançar essa área vindo do outro lado,
# sem precisar de nenhuma checagem extra de "lado certo". Uma vez aberta,
# fica aberta pra sempre (não fecha de novo, ao contrário da SimpleDoor):
# é um atalho permanente de volta pra essa área.

## Precisa ser único por atalho no mapa — é o que o save usa pra lembrar
## que esse atalho específico já foi aberto.
@export var save_id: String = ""

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var occluder: LightOccluder2D = $LightOccluder2D
@onready var label: Label = $Label

var is_open: bool = false
var _player_in_range: Node2D = null


func _ready() -> void:
	label.visible = false

	if save_id != "" and GameState.get_flag(save_id):
		_open(false)


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and not is_open and event.is_action_pressed("Interact"):
		_open()


func _open(animate: bool = true) -> void:
	is_open = true
	label.visible = false
	collision.set_deferred("disabled", true)
	occluder.visible = false # luz passa livre, igual porta aberta de verdade

	if sprite:
		if animate:
			var tween := create_tween()
			tween.tween_property(sprite, "modulate:a", 0.3, 0.4)
		else:
			sprite.modulate.a = 0.3 # veio de um save já aberto — sem animação

	if save_id != "":
		GameState.set_flag(save_id, true)


func _on_interact_area_body_entered(body: Node2D) -> void:
	if is_open:
		return
	if body.is_in_group("Player"):
		_player_in_range = body
		label.text = "[E] Abrir atalho"
		label.visible = true


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		label.visible = false


# --- Imunidade ---
func take_damage(_amount: float, _source_position: Vector2) -> void:
	# Atalho não quebra, só abre por interação mesmo.
	pass
