extends Node
## Atalhos globais (autoload "AppControls").
##   F11: alterna tela cheia (em 1080p dá escala x3; a janela maximizada dá x2 com faixas).
##   F12: liga/desliga a depuração escondida. Só funciona em build de debug.

signal debug_visivel_mudou(visivel: bool)

var debug_visivel := false


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_F11:
			alternar_tela_cheia()
			get_viewport().set_input_as_handled()
		KEY_F12:
			alternar_debug()
			get_viewport().set_input_as_handled()


func alternar_tela_cheia() -> void:
	var cheia := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if cheia else DisplayServer.WINDOW_MODE_FULLSCREEN)


func alternar_debug() -> void:
	if not OS.is_debug_build():
		return
	debug_visivel = not debug_visivel
	debug_visivel_mudou.emit(debug_visivel)
