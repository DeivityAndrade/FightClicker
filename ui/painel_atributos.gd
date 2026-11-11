class_name PainelAtributos
extends Control
## Painel esquerdo: os 3 atributos (valor truncado, barra de proporção, dica) e, embaixo,
## a caixa de informação do item sob o mouse (ou a ambientação do local).

const LINHA := 30.0

var _linhas: Dictionary = {}  # atributo -> {fundo, valor, fill, barra_largura}
var _info_titulo: Label
var _info_texto: Label
var _info_extra: Label
var _ambientacao := ""
var _div_info: ColorRect
var _caixa_info: VBoxContainer


func _ready() -> void:
	position = Vector2(0, 18)
	size = Vector2(128, 272)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("ui_margens", "h")  # conteúdo com a mesma margem à esquerda e à direita
	UiTema.painel(self, "ui_panel", Rect2(0, 0, 128, 272))
	UiTema.rotulo(self, str(GameState.dados.ui.get("panel_attributes", "ATRIBUTOS")).to_upper(), UiTema.G3, 8, 5)
	_divisor(16)

	var i := 0
	for id in GameState.dados.atributos:
		var y0 := 22.0 + i * LINHA
		var cor := UiTema.cor_atributo(id)
		var info: Dictionary = GameState.dados.atributo_info(id)

		var fundo := ColorRect.new()
		# Passar o mouse na linha mostra a dica do atributo na caixa de informação.
		fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.color = Color(cor.r, cor.g, cor.b, 0.16)
		fundo.position = Vector2(4, y0 - 3)
		fundo.size = Vector2(120, LINHA - 4)
		add_child(fundo)
		var area := Control.new()
		area.mouse_filter = Control.MOUSE_FILTER_PASS
		area.position = fundo.position
		area.size = fundo.size
		var id_linha: String = id
		area.mouse_entered.connect(func() -> void:
			var inf: Dictionary = GameState.dados.atributo_info(id_linha)
			mostrar_info({"titulo": str(inf.get("name", id_linha)), "texto": str(inf.get("hint", "")),
				"extra": _aviso_trancado(id_linha)}))
		area.mouse_exited.connect(func() -> void: mostrar_info({}))
		add_child(area)

		UiTema.textura_rect(self, "icon_" + id, 8, y0 + 1)
		var nome_rotulo := UiTema.rotulo(self, str(info.get("name", id)).to_upper(), cor, 21, y0)
		var valor := UiTema.rotulo(self, "0", UiTema.WHITE, 8, y0, 112, HORIZONTAL_ALIGNMENT_RIGHT)

		var bg := NinePatchRect.new()
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.texture = UiTema.textura("ui_bar_bg")
		_margens_nove(bg, "ui_bar_bg")
		bg.position = Vector2(8, y0 + 12)
		bg.size = Vector2(112, 5)
		add_child(bg)
		var fill := NinePatchRect.new()
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.texture = UiTema.textura("ui_bar_fill_" + id)
		_margens_nove(fill, "ui_bar_fill_" + id)
		fill.position = Vector2(9, y0 + 13)
		fill.size = Vector2(2, 3)
		add_child(fill)

		# Aparelho ainda não comprado: no lugar da barra, o aviso curto (sempre visível, sem precisar do mouse).
		var aviso := UiTema.rotulo(self, "", UiTema.G2, 8, y0 + 11, 112)
		aviso.clip_text = true
		aviso.visible = false
		UiTema.alinhar(aviso, "left")

		_linhas[id] = {"fundo": fundo, "valor": valor, "fill": fill, "nome": nome_rotulo, "bg": bg, "aviso": aviso}
		i += 1

	# Próxima luta (nome, risco, prêmio) entre os atributos e a caixa de informação.
	_divisor(110)
	var proxima := BlocoProxima.new()
	add_child(proxima)
	_div_info = _divisor(184)
	_ambientacao = str(GameState.dados.ui.get("location_ambience", "")).to_upper()
	_caixa_info = VBoxContainer.new()
	_caixa_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caixa_info.position = Vector2(8, 188)
	_caixa_info.size = Vector2(112, 79)
	_caixa_info.add_theme_constant_override("separation", 4)
	add_child(_caixa_info)
	_info_titulo = UiTema.rotulo(_caixa_info, "", UiTema.Y1, 0, 0, 112)
	_info_texto = UiTema.rotulo(_caixa_info, "", UiTema.CREAM, 0, 0, 112)
	_info_extra = UiTema.rotulo(_caixa_info, "", UiTema.GR3, 0, 0, 112)
	# Fase 4: o bloco PRÓXIMA cresce com a fita da revanche e a dica do verde; a caixa de informação desce junto.
	proxima.altura_mudou.connect(_ao_altura_proxima)
	GameState.local_mudou.connect(func(_l: String) -> void: mostrar_info({}))
	mostrar_info({})
	atualizar()


## O bloco PRÓXIMA ocupa `altura` px a partir de y=113 do painel. O divisor e a caixa de informação ficam logo abaixo
## (no mínimo onde sempre estiveram: divisor em 184). A caixa mantém o fim em y=267.
func _ao_altura_proxima(altura: int) -> void:
	var y_div := maxf(184.0, 113.0 + float(altura) + 1.0)
	_div_info.position.y = y_div
	_caixa_info.position.y = y_div + 4.0
	var sobra := 267.0 - (y_div + 4.0)
	_caixa_info.size.y = maxf(sobra, 0.0)
	# Fase 5: o cartão da mudança ocupa quase o painel todo; sem espaço para a caixa de informação, ela some (e o divisor).
	var cabe := sobra >= 20.0
	_div_info.visible = cabe
	_caixa_info.visible = cabe


## "COMPRE A ESTEIRA PARA TREINAR" se o aparelho que treina o atributo ainda não chegou (o atributo continua valendo
## na luta pelos 10% gerais). Vazio caso contrário.
func _aviso_trancado(atributo: String) -> String:
	for ap in GameState.dados.aparelhos:
		if str(ap.attribute) == atributo and not GameState.aparelho_montado(str(ap.id)):
			return str(GameState.textos_trancado(str(ap.id)).get("attr_locked", ""))
	return ""


## Versão da linha para caber nos 112 px do painel: se o aviso completo não couber, tira o fim ("... PARA TREINAR")
## e, se ainda não couber, palavra por palavra. A frase completa continua na dica do mouse.
func _aviso_curto(texto: String) -> String:
	var t := texto.to_upper()
	if UiTema.largura_visivel(t) <= 112.0:
		return t
	var corte := t.rfind(" PARA ")
	if corte > 0:
		t = t.substr(0, corte)
	while UiTema.largura_visivel(t) > 112.0 and t.contains(" "):
		t = t.substr(0, t.rfind(" "))
	return t


func _divisor(y: float) -> ColorRect:
	var d := ColorRect.new()
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.color = UiTema.D2
	d.position = Vector2(8, y)
	d.size = Vector2(112, 1)
	add_child(d)
	return d


func _margens_nove(n: NinePatchRect, nome: String) -> void:
	var ns: Dictionary = UiTema.sprite(nome).get("nine_slice", {})
	n.patch_margin_left = int(ns.get("left", 1))
	n.patch_margin_top = int(ns.get("top", 1))
	n.patch_margin_right = int(ns.get("right", 1))
	n.patch_margin_bottom = int(ns.get("bottom", 1))


## Caixa de informação: {} mostra a ambientação do local. Senão {titulo, texto, extra}.
func mostrar_info(info: Dictionary) -> void:
	if info.is_empty():
		_info_titulo.text = ""
		# Fase 5: a ambientação é a do local atual (garagem ou Academia Boa Esquina).
		var amb := str(GameState.local_atual().get("ambience", "")).to_upper()
		_info_texto.text = amb if amb != "" else _ambientacao
		_info_texto.add_theme_color_override("font_color", UiTema.G2)
		_info_extra.text = ""
	else:
		_info_titulo.text = str(info.get("titulo", "")).to_upper()
		_info_texto.text = str(info.get("texto", "")).to_upper()
		_info_texto.add_theme_color_override("font_color", UiTema.CREAM)
		_info_extra.text = str(info.get("extra", "")).to_upper()
	_info_titulo.visible = _info_titulo.text != ""
	_info_extra.visible = _info_extra.text != ""


func atualizar() -> void:
	var total := 0.0
	for id in _linhas:
		total += float(GameState.atributos.get(id, 0.0))
	var foco_attr := GameState.atributo_do_aparelho(GameState.foco)
	for id in _linhas:
		var v := float(GameState.atributos.get(id, 0.0))
		var l: Dictionary = _linhas[id]
		l.valor.text = NumberFormat.fmt(v, NumberFormat.TRUNCAR)
		l.fundo.visible = id == foco_attr
		# Atributo de aparelho que ainda não chegou: o nome fica apagado (a dica completa vem ao passar o mouse).
		l.nome.add_theme_color_override("font_color", UiTema.cor_atributo(id) if _aviso_trancado(id) == "" else UiTema.G2)
		var aviso := _aviso_trancado(id)
		l.aviso.text = _aviso_curto(aviso)
		l.aviso.visible = aviso != ""
		l.bg.visible = aviso == ""
		# Barra = parte do treino total que foi para este atributo.
		var frac := v / total if total > 0.0 else 0.0
		var w := roundf(110.0 * frac)
		l.fill.visible = w >= 2.0 and aviso == ""
		l.fill.size = Vector2(maxf(w, 2.0), 3)
