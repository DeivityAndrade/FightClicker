class_name TelaRondaMinima
extends Control
## Tela MÍNIMA da Ronda (só para provar a lógica de ponta a ponta; o UI/UX troca pela tela de verdade com a arte de assets/).
## Uso: add_child(TelaRondaMinima.new()) depois de GameState.ronda_ir(); ela fecha sozinha no VOLTAR (ronda_voltar).
## Consome: GameState.ronda_jogo().estado() / apertar() / soltar(), ronda_concluir() (prêmio), ronda_voltar(). Não chama `passo`.

var _info := Label.new()
var _sair := Button.new()
var _premio := {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_info.position = Vector2(8, 8)
	add_child(_info)
	_sair.text = GameState.texto_ui("mini_exit", "SAIR")
	_sair.position = Vector2(8, 200)
	_sair.pressed.connect(_ao_sair)
	add_child(_sair)


func _gui_input(e: InputEvent) -> void:
	var j = GameState.ronda_jogo()
	if j == null or not _premio.is_empty():
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		j.apertar() if e.pressed else j.soltar()


func _unhandled_key_input(e: InputEvent) -> void:
	var j = GameState.ronda_jogo()
	if j != null and e is InputEventKey and e.keycode == KEY_SPACE and not e.echo:
		j.apertar() if e.pressed else j.soltar()


func _ao_sair() -> void:
	if _premio.is_empty():
		_premio = GameState.ronda_concluir()
	else:
		GameState.ronda_voltar()
		queue_free()


func _process(_d: float) -> void:
	var j = GameState.ronda_jogo()
	if j == null:
		queue_free()
		return
	if _premio.is_empty() and j.fase == "fim":
		_premio = GameState.ronda_concluir()
	if not _premio.is_empty():
		_sair.text = GameState.texto_ui("mini_back", "VOLTAR")
		_info.text = "%s\n%s\n%s" % [GameState.texto_ui("ronda_reward_title", "RONDA FEITA"),
			GameState.preencher(GameState.texto_ui("ronda_reward_legend", "+{n} LENDA"), {"n": _premio.legend_gain}), _premio.line]
		return
	var e: Dictionary = j.estado()
	_info.text = "%s  %d/%d\ndist %.2f  ladrao %s%s\nsustos %d  vistos %d" % [e.fase, e.ocorrencia + 1, e.total, e.distancia, e.ladrao,
		"  PERTO!" if e.perto else "", e.sustos, e.vistos]
