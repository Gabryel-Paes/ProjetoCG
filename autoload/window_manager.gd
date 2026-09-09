extends Node

# --- Atalho global de janela ---
# F11 alterna entre tela cheia e janela, em qualquer tela do jogo (menu,
# gameplay, etc) — por isso mora num autoload em vez de ficar preso a um
# script específico de uma cena só.

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	var window := get_window()
	var is_fullscreen := window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	window.mode = Window.MODE_WINDOWED if is_fullscreen else Window.MODE_FULLSCREEN
