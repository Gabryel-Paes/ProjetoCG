extends Node2D

# --- Sala do confronto final ---
# Quando o StalkerBoss morre, ele emite "defeated" — é só isso que dispara
# a sequência de vitória, não precisa de mais nenhuma lógica de fim de jogo
# aqui.

const VICTORY_SCENE := "res://ui/menu/victory_screen.tscn"


func _ready() -> void:
	if has_node("StalkerBoss"):
		# Se o chefe já foi derrotado num save anterior, o próprio script dele
		# já chamou queue_free() no _ready() (que roda antes do nosso, filhos
		# ficam prontos primeiro) — nesse caso não tem luta nem barra de vida.
		if $StalkerBoss.is_queued_for_deletion():
			return

		$StalkerBoss.defeated.connect(_on_boss_defeated)
		# Mostra a vida do chefe no topo da tela assim que o confronto começa.
		if has_node("BossHealthBar") and $StalkerBoss.has_node("Health"):
			$BossHealthBar.track($StalkerBoss.get_node("Health"), "MR. G")


func _on_boss_defeated() -> void:
	# "defeated" dispara no meio da própria chamada do tiro que matou o boss
	# (Gun.try_fire → take_damage → died → _die → defeated) — trocar de cena
	# na hora desmonta o Player/Gun antes do try_fire terminar de rodar
	# (cria o rastro do tiro logo depois). Adia pro fim do frame, mesma
	# correção já usada no _die() do Player.
	get_tree().change_scene_to_file.call_deferred(VICTORY_SCENE)
