extends Control
class_name VictoryScreen

const MAIN_MENU_SCENE := "res://ui/menu/main_menu.tscn"

@onready var menu_button: Button = $MenuButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_button.visible = false


func _on_sequence_finished() -> void:
	menu_button.visible = true


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
