extends Control
class_name TextSequence

# --- Sequência de telas de texto ---
# Componente genérico: mostra uma página de texto por vez, avança com
# clique/tecla, e avisa quando acabou. Reutilizado tanto pro resumo da
# história (início do jogo) quanto pro final (depois do chefe), pra não
# duplicar essa lógica em dois lugares.

signal finished()

@export var pages: Array[String] = []
@export var prompt_text: String = "Clique ou pressione qualquer tecla para continuar"

## Se preenchido, troca de cena sozinho ao acabar as páginas (ex: história
## inicial → primeira cena do jogo). Se vazio, só emite "finished" e quem
## instanciou decide o que fazer (ex: a tela de vitória, que mostra um
## botão "Voltar ao Menu" em vez de trocar de cena na hora).
@export var next_scene_path: String = ""

@onready var label: RichTextLabel = $Margin/VBox/Label
@onready var prompt: Label = $Margin/VBox/Prompt

var _index: int = 0
var _done: bool = false


func _ready() -> void:
	prompt.text = prompt_text
	_show_page()


func _show_page() -> void:
	if _index >= pages.size():
		_done = true
		prompt.visible = false
		finished.emit()
		if next_scene_path != "":
			get_tree().change_scene_to_file(next_scene_path)
		return

	label.text = pages[_index]


func _advance() -> void:
	if _done:
		return
	_index += 1
	_show_page()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton) and event.is_pressed() and not event.is_echo():
		# Marca tratado ANTES de avançar — _advance() pode trocar de cena
		# (última página + next_scene_path), e depois disso esse nó já
		# pode não estar mais na árvore (get_viewport() viraria null).
		get_viewport().set_input_as_handled()
		_advance()
