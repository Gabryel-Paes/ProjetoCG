extends TextureRect

@export var icon_hands: Texture2D
@export var icon_knife: Texture2D
@export var icon_pistol: Texture2D
@export var visible_time: float = 2.5

@onready var hide_timer: Timer = Timer.new()


func _ready() -> void:
	modulate.a = 0.0
	hide_timer.one_shot = true
	hide_timer.wait_time = visible_time
	hide_timer.timeout.connect(_fade_out)
	add_child(hide_timer)


func _on_weapon_changed(weapon: int) -> void:
	match weapon:
		0: texture = icon_hands   # Weapon.NONE
		1: texture = icon_knife   # Weapon.KNIFE
		2: texture = icon_pistol  # Weapon.PISTOL

	if texture == null:
		modulate.a = 0.0
		return

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	hide_timer.start()


func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
