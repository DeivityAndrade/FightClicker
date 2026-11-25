class_name DebugOverlay
extends Control
## Depuração escondida (F12, só em build de debug). Só chama as ações debug_* do GameState.

var _info: Label
var _apagar: Button
var _apagar_rot: Label
var _confirmando := 0.0
var _t := 0.0


func _ready() -> void:
	visible = false
	z_index = 3100  # ID2/B3: acima da sala (sprites z=sort_y), dos painéis e do Fluxo (3000); abaixo da faixa de aviso (3200)
	position = Vector2(144, 24)  # x=144: não cobre o retrato do HUD (termina em 139)
	size = Vector2(150, 150)
	mouse_filter = Control.MOUSE_FILTER_STOP
	UiTema.painel(self, "ui_card", Rect2(0, 0, 150, 150))
	UiTema.alinhar_motivo(UiTema.rotulo(self, "DEPURAÇÃO (F12)", UiTema.Y1, 8, 4), "left", "painel de depuração: título e linhas de dados alinhados à esquerda (8 px)")

	var t: Dictionary = GameState.dados.ui
	_botao(str(t.get("debug_add_currency", "SALDO x1000")).to_upper(), 0, GameState.debug_multiplicar_saldo)
	_botao(str(t.get("debug_add_generators", "+10 DE CADA GERADOR")).to_upper(), 1,
		GameState.debug_somar_geradores)
	_botao(str(t.get("debug_save", "SALVAR")).to_upper(), 2, func() -> void: GameState.salvar())
	_botao(str(t.get("debug_reload", "RECARREGAR")).to_upper(), 3, GameState.carregar_save)
	_apagar = _botao(str(t.get("debug_wipe_save", "APAGAR SAVE")).to_upper(), 4, _pedir_apagar)
	_info = UiTema.rotulo(self, "", UiTema.G3, 8, 98, 134)
	UiTema.alinhar_motivo(_info, "left", "painel de depuração: linhas de dados alinhadas à esquerda (8 px)")
	if AppControls != null:
		AppControls.debug_visivel_mudou.connect(_ao_mudar_visibilidade)
		visible = AppControls.debug_visivel and GameState.debug_disponivel()


func _botao(texto: String, i: int, acao: Callable) -> Button:
	var b := UiTema.botao(self, Rect2(6, 17 + i * 16, 138, 15))
	var r := UiTema.rotulo(b, texto, UiTema.WHITE, 0, UiTema.y_texto(UiTema.area_botao(b)), 138, HORIZONTAL_ALIGNMENT_CENTER)
	b.pressed.connect(acao)
	if i == 4:
		_apagar_rot = r
	return b


func _ao_mudar_visibilidade(v: bool) -> void:
	visible = v and GameState.debug_disponivel()
	_confirmando = 0.0


func _pedir_apagar() -> void:
	if _confirmando > 0.0:
		_confirmando = 0.0
		GameState.apagar_save()
	else:
		_confirmando = 4.0


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _confirmando > 0.0:
		_confirmando -= delta
		_apagar_rot.text = str(GameState.dados.ui.get("debug_confirm", "CONFIRMAR")).to_upper()
		_apagar_rot.add_theme_color_override("font_color", UiTema.R3)
	else:
		_apagar_rot.text = str(GameState.dados.ui.get("debug_wipe_save", "APAGAR SAVE")).to_upper()
		_apagar_rot.add_theme_color_override("font_color", UiTema.WHITE)
	var aviso := ""
	if not GameState.avisos.is_empty():
		aviso = "\nAVISO: " + str(GameState.avisos[0])
	_info.text = "FPS %d  SALVO %s%s" % [Engine.get_frames_per_second(), GameState.ultimo_save_texto, aviso]
	if _confirmando > 0.0:
		_info.text += "\n" + GameState.texto_confirmar_apagar()
