extends Label

const PISTOL := 2 # Weapon.PISTOL

@export var visible_time: float = 2.0

@onready var hide_timer: Timer = Timer.new()
var is_pistol_equipped: bool = false


func _ready() -> void:
	modulate.a = 0.0
	hide_timer.one_shot = true
	hide_timer.wait_time = visible_time
	hide_timer.timeout.connect(_fade_out)
	add_child(hide_timer)


func _on_weapon_changed(weapon: int) -> void:
	is_pistol_equipped = (weapon == PISTOL)
	if not is_pistol_equipped:
		modulate.a = 0.0


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	text = str(current) + " / " + str(max_ammo)
	_show_temporarily()


func _on_reload_started() -> void:
	text = "Recarregando..."
	_show_temporarily()


func _on_ammo_empty() -> void:
	text = "Sem munição."
	_show_temporarily()


func _show_temporarily() -> void:
	if not is_pistol_equipped:
		return

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.1)
	hide_timer.start()


func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
