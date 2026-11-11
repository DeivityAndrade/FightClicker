class_name JanelaArte
extends JanelaBase
## Janela "QUE TIPO DE LUTADOR VOCÊ QUER SER?" (Fase 5): as duas artes lado a lado, cada uma com o ícone do aparelho, o nome,
## a frase de tom (`tagline`), a regra em número (`rule_text`), o traço de luta (`fight_text`), "VALE A CARREIRA INTEIRA" e o
## botão ESCOLHER. Abre na 1ª chegada à academia, no começo de toda carreira (com as artes liberadas) e ao reabrir o jogo sem
## ter escolhido (`GameState.escolha_arte_pendente()`). Sem X: enquanto não escolhe, o jogo fica travado. 1 clique escolhe
## (no botão ESCOLHER ou em qualquer ponto do cartão). A arte da carreira anterior vem com a borda dourada e o selo
## "ÚLTIMA: BOXE". Só lê `artes_para_escolha()` e chama `escolher_arte()`; nenhuma regra aqui.
## Geometria: manifest.by_data_id.art_window (janela 420x268 em 110,34; 2 cartões de 190x220).

signal escolheu(arte: String)

const JANELA := Rect2(110, 34, 420, 268)
const CARTOES := [Rect2(124, 70, 190, 220), Rect2(326, 70, 190, 220)]
const LARG_BOTAO := 120.0
const ALT_BOTAO := 20.0

var sfx: Sfx
var _cartoes: Array[Dictionary] = []  # {id, area, fundo, ultima, container, botao, hover}
var _escolhida := ""
var _t := 0.0


func abrir_com() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	var artes: Array = GameState.artes_para_escolha()
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("art_window", {})
	moldura("ui_window", JANELA)
	faixa_titulo("retire", Rect2(116, 40, 408, 16), UiTema.txt("art_title", "QUE TIPO DE LUTADOR VOCÊ QUER SER?"))
	UiTema.rotulo_centro(painel, GameState.subtitulo_escolha_arte().to_upper(), UiTema.G3, 320.0, 56.0)
	# Camadas: fundos dos cartões, a área clicável de cada cartão e, por cima, o conteúdo (rótulos e botões ESCOLHER).
	var fundos := Control.new()
	fundos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundos.size = TELA
	painel.add_child(fundos)
	var cliques := Control.new()
	cliques.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cliques.size = TELA
	cliques.set_meta("ui_align_row", "free")
	painel.add_child(cliques)
	var conteudo := Control.new()
	conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conteudo.size = TELA
	painel.add_child(conteudo)
	var n := mini(artes.size(), CARTOES.size())
	# Com uma arte só (não acontece hoje) o cartão fica no meio da janela.
	for i in n:
		var r: Rect2 = CARTOES[i]
		if n == 1:
			r.position.x = 320.0 - r.size.x / 2.0
		_cartoes.append(_montar_cartao(artes[i], r, fundos, cliques, conteudo, info))
	animar_entrada()
	# Os cartões entram um depois do outro (pop de baixo para cima).
	for i in _cartoes.size():
		var c: Control = _cartoes[i].container
		var f: Control = _cartoes[i].fundo
		var y0 := c.position.y
		c.modulate.a = 0.0
		f.modulate.a = 0.0
		c.position.y = y0 + 8.0
		f.position.y += 8.0
		var tw := create_tween().set_parallel(true)
		tw.tween_interval(0.06 * i)
		tw.chain().tween_property(c, "modulate:a", 1.0, 0.12)
		tw.parallel().tween_property(f, "modulate:a", 1.0, 0.12)
		tw.parallel().tween_property(c, "position:y", y0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(f, "position:y", f.position.y - 8.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _montar_cartao(arte: Dictionary, r: Rect2, fundos: Control, cliques: Control, conteudo: Control, info: Dictionary) -> Dictionary:
	var id := str(arte.id)
	var ultima := bool(arte.get("last", false))
	var por_id: Dictionary = UiTema.manifest().get("by_data_id", {}).get(id, {})
	var nome_normal := str(info.get("card", {}).get("last" if ultima else "normal", "ui_art_card"))
	var fundo := UiTema.nine_patch(fundos, nome_normal, r)

	# Área clicável do cartão (por baixo do conteúdo: o botão ESCOLHER continua clicável por cima).
	var area := Button.new()
	area.focus_mode = Control.FOCUS_NONE
	area.flat = true
	area.position = r.position
	area.size = r.size
	for e in ["normal", "hover", "pressed", "disabled", "focus"]:
		area.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	area.pressed.connect(func() -> void: _escolher(id))
	cliques.add_child(area)

	# Conteúdo: um Control do tamanho do cartão (coordenadas locais do cartão).
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = r.position
	c.size = r.size
	conteudo.add_child(c)

	# Faixa do nome: ícone da arte à esquerda e o nome em 2x, centralizado na faixa.
	var cab_nome := str(por_id.get("card_header", "ui_art_card_header_" + id))
	var cab := UiTema.nine_patch(c, cab_nome, Rect2(6, 6, 178, 18))
	cab.set_meta("ui_pos", "center_h")
	UiTema.textura_rect(cab, str(por_id.get("icon", "art_" + id)), 3, 1)
	UiTema.rotulo_centrado(cab, UiTema.area_nove(cab_nome, Vector2(178, 18)), str(arte.name).to_upper(), UiTema.WHITE, 2, false, "center_h")

	# Ilustração do aparelho (72x56) no meio do cartão.
	var ilus := UiTema.textura_rect(c, str(por_id.get("card_art", "art_card_" + id)), floorf((r.size.x - 72.0) / 2.0), 28)
	ilus.set_meta("ui_pos", "center_h")

	# Textos: tagline, regra, traço de luta, "vale a carreira inteira". Cada um centralizado, até 2 linhas em 174 px.
	_texto(c, str(arte.tagline).to_upper(), UiTema.CREAM, 90.0, r.size.x)
	_texto(c, str(arte.rule_text).to_upper(), UiTema.P2, 114.0, r.size.x)
	_texto(c, str(arte.fight_text).to_upper(), UiTema.R3 if id == "boxing" else UiTema.B3, 138.0, r.size.x)
	_texto(c, UiTema.txt("art_whole_career", "VALE A CARREIRA INTEIRA"), UiTema.G2, 166.0, r.size.x)

	# Botão ESCOLHER, centralizado no cartão.
	var b := UiTema.botao_estilizado(c, Rect2(floorf((r.size.x - LARG_BOTAO) / 2.0), 190, LARG_BOTAO, ALT_BOTAO), "ui_button_art")
	UiTema.botao_conteudo(b, UiTema.txt("art_choose", "ESCOLHER"), UiTema.WHITE, 1)
	b.set_meta("ui_pos", "center_h")
	b.pressed.connect(func() -> void: _escolher(id))

	# Selo "ÚLTIMA: BOXE" sobre a borda de cima, do lado direito.
	if ultima:
		var texto := str(arte.get("last_text", "")).to_upper()
		var w := roundf(UiTema.largura_visivel(texto)) + 10.0
		if int(w) % 2 != 0:
			w += 1.0
		var tag := UiTema.nine_patch(c, str(info.get("tag_last", "ui_art_tag_last")), Rect2(r.size.x - w - 10.0, -3, w, 11))
		var a := UiTema.area_nove("ui_art_tag_last", Vector2(w, 11))
		var l := UiTema.rotulo(tag, texto, Sala.BR0, roundf(a.position.x + (a.size.x - UiTema.largura_visivel(texto)) / 2.0),
			UiTema.y_texto(a), 0, HORIZONTAL_ALIGNMENT_LEFT, false)
		UiTema.alinhar(l, "left")
	return {"id": id, "area": area, "fundo": fundo, "ultima": ultima, "container": c, "botao": b, "rect": r,
		"normal": nome_normal, "hover": str(info.get("card", {}).get("hover", "ui_art_card_hover")), "aceso": false}


## Linha de texto centralizada no cartão (até 2 linhas de 174 px, quebra por palavra).
func _texto(c: Control, texto: String, cor: Color, y: float, largura_cartao: float) -> void:
	var l := UiTema.rotulo(c, texto, cor, 8.0, y, largura_cartao - 16.0, HORIZONTAL_ALIGNMENT_CENTER)
	UiTema.alinhar(l, "center_h")


func _escolher(id: String) -> void:
	if _escolhida != "":
		return
	if not GameState.escolher_arte(id):
		return
	_escolhida = id
	sfx.no_aprendido()
	# Feedback: o cartão escolhido brilha e dá um pulo; o outro apaga. A janela fecha logo depois.
	for c in _cartoes:
		var escolhido: bool = c.id == id
		var alvo: Control = c.container
		if escolhido:
			c.fundo.modulate = Color(1.9, 1.9, 1.6)
			alvo.modulate = Color(1.6, 1.6, 1.4)
			create_tween().tween_property(c.fundo, "modulate", Color.WHITE, 0.2)
			create_tween().tween_property(alvo, "modulate", Color.WHITE, 0.2)
		else:
			create_tween().tween_property(alvo, "modulate:a", 0.35, 0.15)
			create_tween().tween_property(c.fundo, "modulate:a", 0.35, 0.15)
		(c.area as Button).disabled = true
		(c.botao as Button).disabled = true
	var tw := create_tween()
	tw.tween_interval(0.22)
	tw.tween_callback(func() -> void: escolheu.emit(id))


func _process(delta: float) -> void:
	_t += delta
	# Hover do cartão inteiro (a área clicável fica por baixo do botão ESCOLHER, que tem o próprio hover).
	if _escolhida != "":
		return
	var mouse := get_local_mouse_position()
	for c in _cartoes:
		var dentro: bool = Rect2(c.rect).has_point(mouse)
		if dentro == bool(c.aceso):
			continue
		c.aceso = dentro
		if bool(c.ultima):
			c.fundo.modulate = Color(1.18, 1.14, 1.0) if dentro else Color.WHITE  # já tem a borda dourada
		else:
			(c.fundo as NinePatchRect).texture = UiTema.textura(str(c.hover) if dentro else str(c.normal))
