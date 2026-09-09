extends Node
class_name LeverPuzzle

signal solved()

## Alavancas na ORDEM EXATA em que precisam ser ativadas (ex: Lever1,
## Lever2, Lever3...). Ativar qualquer uma fora da vez reseta todas de
## volta pra desligado e o jogador tem que começar de novo.
@export var sequence: Array[Lever] = []

var _solved: bool = false
var _next_index: int = 0


func _ready() -> void:
	for lever in sequence:
		lever.toggled.connect(_on_lever_toggled.bind(lever))


func _on_lever_toggled(is_on: bool, lever: Lever) -> void:
	if _solved:
		return

	# Só a ação de LIGAR conta pra sequência — desligar uma alavanca (pra
	# conferir de novo, por exemplo) não avança nem quebra nada sozinho.
	if not is_on:
		return

	var lever_index := sequence.find(lever)

	if lever_index == _next_index:
		_next_index += 1
		if _next_index >= sequence.size():
			_solved = true
			solved.emit()
	elif lever_index >= 0 and lever_index < _next_index:
		# Já era uma das certas (religou ela sem querer, ex: desligou e ligou
		# de novo por engano) — não pune, só ignora, o progresso continua.
		pass
	else:
		_reset_all()


func _reset_all() -> void:
	_next_index = 0
	for lever in sequence:
		# Atribui direto (não usa toggle()) de propósito — isso não emite
		# "toggled", senão o próprio reset disparava _on_lever_toggled de
		# novo pra cada alavanca e bagunçava tudo.
		lever.is_on = false
