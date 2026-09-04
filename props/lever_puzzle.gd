extends Node
class_name LeverPuzzle

signal solved()

## Alavancas que precisam estar LIGADAS pra resolver o puzzle.
@export var required_on: Array[Lever] = []
## Alavancas que precisam estar DESLIGADAS pra resolver o puzzle (as erradas).
## Alavancas que não estão em nenhum dos dois arrays são ignoradas.
@export var required_off: Array[Lever] = []

var _solved: bool = false


func _ready() -> void:
	for lever in required_on:
		lever.toggled.connect(_check_solution)
	for lever in required_off:
		lever.toggled.connect(_check_solution)


func _check_solution(_is_on: bool = false) -> void:
	if _solved:
		return

	for lever in required_on:
		if not lever.is_on:
			return

	for lever in required_off:
		if lever.is_on:
			return

	_solved = true
	solved.emit()
