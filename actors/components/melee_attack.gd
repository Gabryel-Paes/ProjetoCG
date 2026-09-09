extends Area2D

@export var damage: float = 10.0
@export var active_time: float = 0.2

func _ready() -> void:
	monitoring = false # Começa desligado

func attack() -> void:
	monitoring = true
	# Espera o tempo ativo do ataque
	await get_tree().create_timer(active_time).timeout
	monitoring = false

# Lembre-se de ir na aba "Nó" (Node) e conectar o sinal "area_entered" a esta função!
func _on_area_entered(area: Area2D) -> void:
	# "take_melee_damage" é opcional — só o Zumbi implementa até agora, pra
	# ter um nocaute maior específico de faca (corpo a corpo pesa mais que
	# bala). Quem não tiver esse método cai no "take_damage" normal, igual
	# antes.
	if area.has_method("take_melee_damage"):
		area.take_melee_damage(damage, global_position)
	elif area.has_method("take_damage"):
		area.take_damage(damage, global_position)
	# Alternativa: se o script de dano estiver no "Pai" da área atingida
	elif area.owner and area.owner.has_method("take_melee_damage"):
		area.owner.take_melee_damage(damage, global_position)
	elif area.owner and area.owner.has_method("take_damage"):
		area.owner.take_damage(damage, global_position)
