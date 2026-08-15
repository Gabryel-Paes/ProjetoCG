extends Node2D

@export var cor: Color = Color.WHITE 
@export var espessura: float = 2.0
@export var tamanho_linha: float = 8.0

@onready var player = owner

func _ready () -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
func _process (delta:float) -> void:
	position = get_viewport().get_mouse_position()
	queue_redraw()

func _draw() -> void:
	var abertura = 1.0
	
	if player and "spread_atual" in player:
		abertura += player.spread_atual * 3.0
	
	# Risquinho da Direita
	draw_line(Vector2(abertura, 0), Vector2(abertura + tamanho_linha, 0), cor, espessura)
	
	# Risquinho da Esquerda
	draw_line(Vector2(-abertura, 0), Vector2(-abertura - tamanho_linha, 0), cor, espessura)
	
	# Risquinho de Baixo
	draw_line(Vector2(0, abertura), Vector2(0, abertura + tamanho_linha), cor, espessura)
	
	# Risquinho de Cima
	draw_line(Vector2(0, -abertura), Vector2(0, -abertura - tamanho_linha), cor, espessura)
