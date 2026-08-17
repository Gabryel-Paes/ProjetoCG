extends Label


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	text = str(current) + " / " + str(max_ammo)


func _on_reload_started() -> void:
	text = "Recarregando..."


func _on_ammo_empty() -> void:
	text = "Sem munição."
