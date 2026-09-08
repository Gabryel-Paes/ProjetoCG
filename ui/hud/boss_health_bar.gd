extends CanvasLayer
class_name BossHealthBar

# --- Barra de vida do chefe ---
# Fica escondida até alguém chamar track() com o Health de um boss — assim
# a mesma cena serve pra qualquer confronto de chefe (não só o Stalker),
# só precisa apontar pro Health certo em cada sala.

@onready var bar: ProgressBar = $Margin/VBox/Bar
@onready var name_label: Label = $Margin/VBox/NameLabel
@onready var margin: MarginContainer = $Margin

var _tracked_health: Health = null


func _ready() -> void:
	visible = false


func track(boss_health: Health, boss_name: String = "") -> void:
	if _tracked_health != null and _tracked_health.health_changed.is_connected(_on_health_changed):
		_tracked_health.health_changed.disconnect(_on_health_changed)
		_tracked_health.died.disconnect(_on_boss_died)

	_tracked_health = boss_health
	name_label.text = boss_name
	bar.max_value = boss_health.max_health
	bar.value = boss_health.current_health
	visible = true

	boss_health.health_changed.connect(_on_health_changed)
	boss_health.died.connect(_on_boss_died)


func _on_health_changed(current: float, max_health: float) -> void:
	bar.max_value = max_health
	bar.value = current


func _on_boss_died() -> void:
	# Some com um fade rápido em vez de sumir na hora — dá tempo do jogador
	# registrar que a vida zerou antes da troca pra tela de vitória.
	# CanvasLayer não tem "modulate" próprio (não é CanvasItem) — quem
	# desaparece de fato é o Control filho.
	var tween := create_tween()
	tween.tween_property(margin, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): visible = false)
