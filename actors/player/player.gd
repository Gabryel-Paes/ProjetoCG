extends CharacterBody2D

const WALK_SPEED := 180.0
const GRAVITY := 3300.0
const MAX_FALL_SPEED := 1800.0

const JUMP_FORCE_MIN := 600.0
const JUMP_FORCE_MAX := 1860.0
const JUMP_SPEED_H := 300.0
const CHARGE_TIME := 0.6

var charge := 0.0
var is_charging := false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	else:
		_handle_ground(delta)

	move_and_slide()


func _handle_ground(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		is_charging = true
		charge = 0.0

	if is_charging:
		velocity.x = 0.0                  # trava no lugar enquanto carrega
		charge = minf(charge + delta, CHARGE_TIME)

		if Input.is_action_just_released("jump"):
			is_charging = false
			var t := charge / CHARGE_TIME
			var dir := Input.get_axis("move_left", "move_right")
			velocity.y = -lerpf(JUMP_FORCE_MIN, JUMP_FORCE_MAX, t)
			velocity.x = dir * JUMP_SPEED_H
	else:
		velocity.x = Input.get_axis("move_left", "move_right") * WALK_SPEED
