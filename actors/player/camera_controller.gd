extends Camera2D
class_name CameraController

@export var lead: float = 0.35        # fração do offset do mouse na tela
@export var deadzone: float = 120.0   # px de tela sem deslocamento
@export var max_offset: float = 260.0 # teto do deslocamento
@export var smooth: float = 8.0       # maior = mais rápido
@export var zoom_rest: float = 3.0    # mouse perto: zoom in
@export var zoom_far: float = 2.0     # mouse longe: zoom out

# --- Screen Shake ---
@export var shake_strength: float = 20.0 # px que a cam vai tremer
@export var shake_decay: float = 3.0     # velocidade de decaimento do tremor
var shake_amount: float = 0.0


func _process(delta: float) -> void:
	# Offset do mouse em relação ao CENTRO DA TELA — não ao mundo.
	# É isso que quebra o loop de realimentação.
	var viewport_size := get_viewport_rect().size
	var from_center := get_viewport().get_mouse_position() - viewport_size * 0.5
	var dist := from_center.length()

	var target := Vector2.ZERO
	var t := 0.0

	if dist > deadzone:
		var beyond := dist - deadzone
		var max_beyond := maxf(viewport_size.length() * 0.5 - deadzone, 1.0)
		t = clampf(beyond / max_beyond, 0.0, 1.0)
		target = (from_center / dist) * minf(beyond * lead, max_offset)

	# Suavização independente de framerate
	var w := 1.0 - exp(-smooth * delta)
	position = position.lerp(target, w)

	var z := lerpf(zoom_rest, zoom_far, t)
	zoom = zoom.lerp(Vector2(z, z), w)

	_update_shake(delta)


func shake(amount: float = 1.0) -> void:
	shake_amount = amount


func _update_shake(delta: float) -> void:
	if shake_amount > 0.0:
		shake_amount = max(shake_amount - shake_decay * delta, 0.0)
		var force := pow(shake_amount, 2)
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_strength * force
	else:
		offset = Vector2.ZERO
