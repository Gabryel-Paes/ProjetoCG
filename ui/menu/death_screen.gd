extends Control
class_name DeathScreen

const MAIN_MENU_SCENE := "res://ui/menu/main_menu.tscn"

@onready var continue_button: Button = $Margin/VBox/ContinuarButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	continue_button.disabled = not GameState.has_save()


func _on_continuar_pressed() -> void:
	if not GameState.has_save():
		return
	GameState.load_game()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
