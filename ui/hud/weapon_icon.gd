extends Control

@export var icon_hands: Texture2D
@export var icon_knife: Texture2D
@export var icon_pistol: Texture2D
@export var visible_time: float = 2.5
@export var side_alpha: float = 0.45  # opacidade das câmaras vizinhas do tambor
@export var flick_angle_deg: float = 35.0 # o quanto o tambor chicoteia pro lado
@export var flick_out_time: float = 0.12
@export var flick_back_time: float = 0.2

@onready var hide_timer: Timer = Timer.new()
@onready var drum: Control = $Drum
@onready var slot_prev: TextureRect = $Drum/SlotPrev
@onready var slot_current: TextureRect = $Drum/SlotCurrent
@onready var slot_next: TextureRect = $Drum/SlotNext

var icons: Array[Texture2D]


func _ready() -> void:
	icons = [icon_hands, icon_knife, icon_pistol]
	modulate.a = 0.0

	hide_timer.one_shot = true
	hide_timer.wait_time = visible_time
	hide_timer.timeout.connect(_fade_out)
	add_child(hide_timer)

	slot_prev.modulate.a = side_alpha
	slot_next.modulate.a = side_alpha


func _on_weapon_changed(weapon: int) -> void:
	modulate.a = 1.0
	hide_timer.start()

	# Gira o tambor pro lado (como o revólver do DMC), troca as câmaras
	# escondido no meio do giro, e volta de estalo.
	var tween := create_tween()
	tween.tween_property(drum, "rotation_degrees", flick_angle_deg, flick_out_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_apply_icons.bind(weapon))
	tween.tween_property(drum, "rotation_degrees", 0.0, flick_back_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply_icons(weapon: int) -> void:
	var count := icons.size()
	var prev_index := (weapon + count - 1) % count
	var next_index := (weapon + 1) % count

	slot_prev.texture = icons[prev_index]
	slot_current.texture = icons[weapon]
	slot_next.texture = icons[next_index]


func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
