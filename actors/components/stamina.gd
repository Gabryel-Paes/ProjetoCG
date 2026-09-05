extends Node

signal stamina_changed(current: float, max: float)

@export var max_stamina: float = 100.0
@export var regen_rate: float = 15.0 
@export var regen_delay: float = 1.0 # Tempo de pausa antes de voltar a curar

var current_stamina: float
var regen_timer: float = 0.0 # Cronômetro interno da pausa

func _ready() -> void:
	current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina) 

func _process(delta: float) -> void:
	# Se o timer for maior que zero, ele diminui e segura a regeneração
	if regen_timer > 0:
		regen_timer -= delta
	elif current_stamina < max_stamina:
		_regen_stamina(delta)

func drain_stamina(amount: float) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		stamina_changed.emit(current_stamina, max_stamina)
		
		# Reinicia a pausa sempre que gastar stamina
		regen_timer = regen_delay 
		return true 
	
	return false 

func _regen_stamina(delta: float) -> void:
	current_stamina += regen_rate * delta
	if current_stamina > max_stamina:
		current_stamina = max_stamina
	stamina_changed.emit(current_stamina, max_stamina)
