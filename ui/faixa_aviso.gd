class_name FaixaAviso
extends Control
## Faixa de aviso da data da luta (Fase 5.3), no topo da sala, centrada em x 320, y 22, 18 px de altura. Não é janela:
## a sala continua rodando e o clique no alvo passa por fora dela.
##  - 3 dias: faixa calma (`ui_warn_strip_3d` + `icon_calendar`), desce em 0,2 s, fica ~6 s e sobe, sem som;
##  - 1 dia: faixa urgente (`ui_warn_strip_1d` <-> `_1d_hi` a 2 fps, sem alpha nem tremida + `icon_calendar_alert`), com o som
##    do sino (que já existe). Fica até a luta, o dia chegar ou o jogador clicar nela.
## Só reage ao sinal `aviso_data` do GameState; o texto é `warn_3_days` / `warn_1_day` com o nome do adversário.

const Y_FINAL := 22.0
const ALTURA := 18.0
const TEMPO_VISIVEL := 6.0

var urgente := false
var _fundo: NinePatchRect
var _icone: TextureRect
var _texto: Label
var _tween: Tween
var _t := 0.0
var _quadro_aceso := false
var _sfx: Sfx


func _ready() -> void:
	size = Vector2(40, ALTURA)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 3200  # acima da sala e dos números flutuantes, abaixo das janelas (o Fluxo vai a 3000 + 2000)
	set_meta("ui_margens", "h")
	_fundo = UiTema.nine_patch(self, "ui_warn_strip_3d", Rect2(0, 0, 40, ALTURA))
	_icone = UiTema.textura_rect(self, "icon_calendar", 7, 3)
	_texto = UiTema.rotulo(self, "", UiTema.COL_TEXT_1, 23, 5)
	_sfx = Sfx.new()
	add_child(_sfx)
	GameState.aviso_data.connect(_ao_aviso)
	GameState.dia_da_luta_chegou.connect(esconder)
	GameState.luta_iniciada.connect(func(_i: Dictionary) -> void: esconder())
	GameState.fim_de_carreira.connect(func(_f: Dictionary) -> void: esconder())
	GameState.carreira_mudou.connect(esconder)


func _ao_aviso(dias: int) -> void:
	var opp: Dictionary = GameState.proximo_adversario()
	if opp.is_empty():
		return
	var forte := dias <= int(GameState.lutas.calendario.get("warn_sound_days", 1))
	if visible and urgente:
		return  # o aviso de 1 dia já está no ar (a faixa de 3 dias que chegou junto não o substitui nem repete o som)
	mostrar(forte, str(opp.name))


## Monta a faixa (calma ou urgente) com o nome do adversário e faz a entrada. Público para o verificador de alinhamento.
func mostrar(forte: bool, nome: String) -> void:
	urgente = forte
	var texto := UiTema.txt("warn_1_day" if forte else "warn_3_days", "", {"nome": nome})
	var ic_x := 13.0 if forte else 7.0
	var tx := 29.0 if forte else 23.0
	var w := tx + UiTema.largura_visivel(texto) + ic_x  # margem esquerda do ícone = margem direita do texto
	w = ceilf(w)
	if int(w) % 2 != 0:
		w += 1.0  # largura par: a faixa fica no meio exato da tela
	size = Vector2(w, ALTURA)
	position = Vector2(roundf(320.0 - w / 2.0), Y_FINAL)
	set_meta("ui_pos", "center_h")
	_fundo.size = size
	_quadro_aceso = false
	_fundo.texture = UiTema.textura("ui_warn_strip_1d" if forte else "ui_warn_strip_3d")
	var ns: Dictionary = UiTema.sprite("ui_warn_strip_1d" if forte else "ui_warn_strip_3d").get("nine_slice", {})
	_fundo.patch_margin_left = int(ns.get("left", 4))
	_fundo.patch_margin_right = int(ns.get("right", 4))
	_icone.texture = UiTema.textura("icon_calendar_alert" if forte else "icon_calendar")
	_icone.position = Vector2(ic_x, 3)
	_texto.text = texto
	_texto.position = Vector2(tx, 5)
	_texto.add_theme_color_override("font_color", UiTema.Y2 if forte else UiTema.COL_TEXT_1)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = true
	position.y = Y_FINAL - ALTURA
	_tween = create_tween()
	_tween.tween_property(self, "position:y", Y_FINAL, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if forte:
		_sfx.sino_inicio()
	else:
		_tween.tween_interval(TEMPO_VISIVEL)
		_tween.tween_property(self, "position:y", Y_FINAL - ALTURA, 0.2)
		_tween.tween_callback(esconder)


func esconder() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	visible = false
	urgente = false


## O clique na faixa a dispensa (e não treina por baixo).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		esconder()
		accept_event()


func _process(delta: float) -> void:
	if not visible or not urgente:
		return
	_t += delta
	var aceso := int(_t * 2.0) % 2 == 1  # 2 fps: troca de quadro, sem alpha
	if aceso != _quadro_aceso:
		_quadro_aceso = aceso
		_fundo.texture = UiTema.textura("ui_warn_strip_1d_hi" if aceso else "ui_warn_strip_1d")
