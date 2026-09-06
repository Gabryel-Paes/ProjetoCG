extends Node

# --- Save/Load (slot único) ---
# De propósito não existe tela de "escolher save": só um arquivo, e cada save
# novo sobrescreve o anterior. Quem dispara o save é a SaveTypewriter
# (props/save_typewriter.gd) ao interagir.
#
# "flags" guarda o PROGRESSO DO MUNDO — chave já pega, porta já destrancada,
# chefe já derrotado — qualquer coisa que não deve reaparecer ao carregar.
# Cada prop lê/escreve a própria flag usando um id que ele já tem por outro
# motivo (o "Key Id" da chave, um "Save Id" exportado na porta/chefe), então
# não existe uma lista central pra manter atualizada — ver key.gd, door.gd,
# key_gate.gd e stalker_boss.gd.

const SAVE_PATH := "user://savegame.json"

var flags: Dictionary = {}

var _pending_player_data: Dictionary = {}


func set_flag(id: String, value: bool = true) -> void:
	flags[id] = value


func get_flag(id: String) -> bool:
	return flags.get(id, false)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# --- Atalho temporário só pra testar o carregamento ---
# Ainda não existe menu principal com um botão "Continuar". Quando existir,
# chama GameState.load_game() a partir dele e pode tirar isso daqui.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F9:
		load_game()


func save_game() -> void:
	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		push_warning("GameState: não encontrei o Player, save cancelado.")
		return

	var items_data := []
	if player.has_node("Inventory"):
		var inventory: Inventory = player.get_node("Inventory")
		inventory._ensure_slots()
		for i in range(inventory.capacity):
			var item := inventory.get_item(i)
			items_data.append({
				"path": item.resource_path if item else "",
				"quantity": inventory.get_quantity(i),
			})

	var health_data := {}
	if player.has_node("Health"):
		var health: Health = player.get_node("Health")
		health_data = {"current": health.current_health, "max": health.max_health}

	var save_data := {
		"flags": flags,
		"player": {
			"scene": get_tree().current_scene.scene_file_path,
			"position": {"x": player.global_position.x, "y": player.global_position.y},
			"health": health_data,
			"weapon_index": player.get("weapon_index"),
			"items": items_data,
		},
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameState: não consegui abrir '%s' pra escrita." % SAVE_PATH)
		return

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("GameState: jogo salvo.")


func load_game() -> void:
	if not has_save():
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("GameState: savegame.json corrompido, ignorando.")
		return

	# As flags já ficam disponíveis antes mesmo da cena trocar — é o que faz
	# Key/Door/KeyGate/StalkerBoss se ajustarem sozinhos no _ready() deles.
	flags = parsed.get("flags", {})
	_pending_player_data = parsed.get("player", {})

	var scene_path: String = _pending_player_data.get("scene", "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_warning("GameState: save sem cena válida.")
		return

	get_tree().change_scene_to_file(scene_path)
	# O Player da cena nova só existe a partir do próximo frame.
	await get_tree().process_frame
	await get_tree().process_frame
	_apply_pending_player_data()


func _apply_pending_player_data() -> void:
	if _pending_player_data.is_empty():
		return

	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		push_warning("GameState: cena carregada mas não achei o Player.")
		return

	var pos: Dictionary = _pending_player_data.get("position", {})
	player.global_position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))

	var health_data: Dictionary = _pending_player_data.get("health", {})
	if player.has_node("Health") and not health_data.is_empty():
		var health: Health = player.get_node("Health")
		health.max_health = health_data.get("max", health.max_health)
		health.current_health = health_data.get("current", health.current_health)
		health.health_changed.emit(health.current_health, health.max_health)

	if player.has_node("Inventory"):
		var inventory: Inventory = player.get_node("Inventory")
		inventory._ensure_slots()
		var items: Array = _pending_player_data.get("items", [])
		for i in range(min(items.size(), inventory.capacity)):
			var entry: Dictionary = items[i]
			var path: String = entry.get("path", "")
			inventory.slots[i] = load(path) if path != "" else null
			inventory.quantities[i] = entry.get("quantity", 0)
		inventory.inventory_updated.emit()

	# current_weapon/weapon_index/_equip_weapon são do script do Player, que
	# não tem class_name — acesso dinâmico (get/set/call) pra não quebrar em
	# tempo de análise, mesmo truque já usado em hearer.gd.
	var weapon_index = _pending_player_data.get("weapon_index")
	var weapon_order = player.get("weapon_order")
	if weapon_index != null and weapon_order != null and weapon_index >= 0 and weapon_index < weapon_order.size():
		player.set("weapon_index", weapon_index)
		player.call("_equip_weapon", weapon_order[weapon_index])

	_pending_player_data = {}
