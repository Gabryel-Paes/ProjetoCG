extends Node2D

# --- Sala do confronto final ---
# Quando o StalkerBoss morre, ele emite "defeated" — é só isso que dispara
# a sequência de vitória, não precisa de mais nenhuma lógica de fim de jogo
# aqui.

const VICTORY_SCENE := "res://ui/menu/victory_screen.tscn"


func _ready() -> void:
	if has_node("StalkerBoss"):
		$StalkerBoss.defeated.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	get_tree().change_scene_to_file(VICTORY_SCENE)
