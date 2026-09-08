extends Control
class_name MainMenu

# --- Menu principal ---
const STORY_INTRO_SCENE := "res://ui/menu/story_intro.tscn"

@onready var continue_button: Button = $Margin/VBox/ContinuarButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Só deixa "Continuar" clicável se existir save de verdade.
	continue_button.disabled = not GameState.has_save()


func _on_iniciar_pressed() -> void:
	# Jogo novo de verdade: apaga o save antigo (se tiver) e limpa qualquer
	# progresso que ainda estivesse na memória — sem isso, um save de um
	# teste antigo continuava valendo como "Continuar" pra sempre.
	GameState.delete_save()
	get_tree().change_scene_to_file(STORY_INTRO_SCENE)


func _on_continuar_pressed() -> void:
	if not GameState.has_save():
		return
	GameState.load_game()


func _on_sair_pressed() -> void:
	get_tree().quit()
