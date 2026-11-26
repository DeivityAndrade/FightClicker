class_name TelaEsconderijo
extends JanelaBase
## Ronda 2a1: o Esconderijo do Gato Preto (tela cheia no tema C, asfalto). À esquerda o quadro ESTA NOITE (cartões SUSTO, BRIGA, DESAFIO,
## REVANCHE ou "o beco está quieto"), à direita a parede do Dossiê (uma ficha por bandido: obtida, com o motivo do que falta, com o carimbo
## de vencido), embaixo a prateleira de troféus (vazia na 2a1, com os 4 lugares marcados). Só lê `GameState.esconderijo()`; os botões IR
## e VOLTAR só emitem sinais: quem congela o jogo e abre a noite é o Fluxo (`GameState.ronda_ir`). VOLTAR não grava nada.
## Esconderijo travado (`open` falso): o cartão da briga vira o motivo e o IR dele fica desabilitado; o SUSTO segue valendo.

signal ir_pedido(noite: String, bandido: String)
signal voltar_pedido
signal ficha_pedida(bandido: String)

const COL_E := 12.0
const LARG_E := 296.0
const COL_D := 324.0
const LARG_D := 304.0
const Y0 := 44.0
const ALT_SUSTO := 28.0
const ALT_BRIGA := 62.0
const ALT_DESAFIO := 38.0
const ALT_FICHA := 44.0
const GAP := 4.0

var sfx: Sfx
var _d: Dictionary = {}


func abrir_com(dados: Dictionary = {}) -> void:
	texto_em_papel = false  # fundo asphalt: cada texto escolhe a cor (ink no papel dos cartões, cream no escuro)
	sfx = Sfx.new()
	add_child(sfx)
	_d = dados if not dados.is_empty() else GameState.esconderijo()
	var f := TextureRect.new()
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.texture = UiTema.textura("c_tela_fundo")
	f.stretch_mode = TextureRect.STRETCH_KEEP
	f.size = TELA
	f.set_meta("ui_fundo_escuro", true)
	_dim.add_child(f)
	UiTema.rotulo_centrado(painel, Rect2(0, 8, 640, 14), UiTema.txt("hideout_title", "ESCONDERIJO"), UiTema.CREAM, 2, false, "center_h").set_meta("ui_fundo_escuro", true)
	_montar_quadro()
	_montar_dossie()
	_montar_prateleira()
	var b := botao_texto(Rect2(260, 318, 120, 22), UiTema.txt("hideout_back", "VOLTAR"))
	b.pressed.connect(func() -> void: voltar_pedido.emit())
	animar_entrada()


# ---------------------------------------------------------------- peças
func _chip(pai: Node, texto: String, x: float, y: float) -> NinePatchRect:
	var w := roundf(UiTema.largura_visivel(texto)) + 14.0
	var c := UiTema.nine_patch(pai, "c_chip", Rect2(x, y, w, 13))
	c.set_meta("ui_fundo_escuro", true)
	UiTema.rotulo_centrado(c, UiTema.area_nove("c_chip", Vector2(w, 13)), texto, UiTema.CREAM)
	return c


## Cabeçalho de coluna: chip escuro com o título, colado na esquerda da coluna.
func _cabecalho(texto: String, x: float) -> void:
	_chip(painel, texto, x, 28.0)


func _cartao(x: float, y: float, w: float, h: float) -> Panel:
	return UiTema.painel(painel, "c_cartao", Rect2(x, y, w, h + 2.0))  # +2: a sombra do cartão


## Texto de 1 linha dentro de um cartão; `gy` = topo do glifo (o rótulo sobe 2 px).
func _txt(pai: Node, texto: String, cor: Color, x: float, gy: float) -> Label:
	return UiTema.rotulo(pai, texto, cor, x, gy - 2.0)


## Cadeado de 7x8 px (arco + corpo), canto de cima à esquerda em (x, gy).
func _cadeado(pai: Node, x: float, gy: float) -> void:
	var partes := [[Rect2(1, 0, 5, 1), UiTema.R1], [Rect2(1, 1, 1, 2), UiTema.R1], [Rect2(5, 1, 1, 2), UiTema.R1], [Rect2(0, 3, 7, 5), UiTema.R1],
		[Rect2(3, 5, 1, 2), UiTema.CREAM]]
	for p in partes:
		var c := ColorRect.new()
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.color = p[1]
		c.position = Vector2(x, gy) + (p[0] as Rect2).position
		c.size = (p[0] as Rect2).size
		c.set_meta("ui_align", "ignore")
		pai.add_child(c)


func _retrato(pai: Node, bandido: String, x: float, y: float, conhecido: bool) -> void:
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("opp_alley_" + bandido, {})
	var q := UiTema.textura_rect(pai, "c_retrato_moldura", x, y)
	var t := UiTema.textura_rect(q, str(info.get("portrait", "")), 2, 2)
	if not conhecido:
		t.modulate = UiTema.INK  # silhueta


func _botao_ir(card: Control, x: float, y: float, habilitado: bool, ao_clicar: Callable) -> void:
	var b := UiTema.botao(card, Rect2(x, y, 40, 20), "c_btn_foco")
	UiTema.botao_conteudo(b, UiTema.txt("hideout_go", "IR"), UiTema.CREAM)
	b.disabled = not habilitado
	b.pressed.connect(func() -> void:
		sfx.foco()
		ao_clicar.call())


# ---------------------------------------------------------------- quadro ESTA NOITE
func _montar_quadro() -> void:
	_cabecalho(UiTema.txt("hideout_board_title", "ESTA NOITE"), COL_E)
	var aberta := bool(_d.get("open", false))
	var y := Y0
	var primeiro_bandido := true
	for c in _d.get("board", []):
		match str(c.get("night", "")):
			"scare":
				y += _cartao_susto(c, y) + GAP
			"alley":
				if not aberta:
					if primeiro_bandido:
						y += _cartao_travado(y) + GAP
					primeiro_bandido = false
					continue
				primeiro_bandido = false
				if bool(c.get("challenge_only", false)):
					y += _cartao_desafio(c, y) + GAP
				else:
					y += _cartao_briga(c, y) + GAP
			"quiet":
				y += _cartao_quieto(c, y) + GAP


func _cartao_susto(c: Dictionary, y: float) -> float:
	var card := _cartao(COL_E, y, LARG_E, ALT_SUSTO)
	var chip := _chip(card, UiTema.txt("hideout_kind_scare", "SUSTO"), 6, 6)
	var x := 6.0 + chip.size.x + 6.0
	_txt(card, str(c.get("name", "")).to_upper(), UiTema.INK, x, 9.0)
	var nivel := UiTema.txt("ronda_level_label", "NÍVEL {n}", {"n": int(c.get("level", 0))})
	var l := UiTema.rotulo(card, nivel, UiTema.G0, LARG_E - 6.0 - 40.0 - 6.0 - 70.0, 7.0, 70.0, HORIZONTAL_ALIGNMENT_RIGHT)
	UiTema.alinhar(l, "right")  # nível da lenda à esquerda do botão IR
	_botao_ir(card, LARG_E - 6.0 - 40.0, 4.0, true, func() -> void: ir_pedido.emit("scare", ""))
	return ALT_SUSTO + 2.0


func _cartao_travado(y: float) -> float:
	var card := _cartao(COL_E, y, LARG_E, ALT_SUSTO + 8.0)
	var chip := _chip(card, UiTema.txt("hideout_kind_fight", "BRIGA"), 6, 6)
	var falta := ""
	for f in _d.get("dossier", []):
		if str(f.get("missing_text", "")) != "":
			falta = str(f.missing_text)
			break
	_txt(card, falta.to_upper(), UiTema.R1, 6.0 + chip.size.x + 6.0, 9.0)
	_botao_ir(card, LARG_E - 6.0 - 40.0, 8.0, false, func() -> void: pass)
	return ALT_SUSTO + 10.0


func _cartao_quieto(c: Dictionary, y: float) -> float:
	var card := _cartao(COL_E, y, LARG_E, ALT_SUSTO)
	var l := UiTema.rotulo_centrado(card, UiTema.area_nove("c_cartao", Vector2(LARG_E, ALT_SUSTO + 2.0)), str(c.get("text", "")).to_upper(), UiTema.G0, 1, false, "center_h")
	l.set_meta("ui_texto_dinamico", true)
	return ALT_SUSTO + 2.0


## Nome da passiva dele com o ícone 9x9: "[ícone] BASE LARGA".
func _passiva_linha(pai: Node, p: Dictionary, x: float, gy: float) -> float:
	if p.is_empty():
		return x
	var ic := str(UiTema.manifest().get("by_data_id", {}).get("opp_passives", {}).get(str(p.get("id", "")), {}).get("icon_9", ""))
	if ic != "" and not UiTema.sprite(ic).is_empty():
		UiTema.textura_rect(pai, ic, x, gy - 1.0)
		x += 12.0
	var nome := str(p.get("name", "")).to_upper()
	_txt(pai, nome, UiTema.G0, x, gy)
	return x + UiTema.largura(nome)


func _cartao_briga(c: Dictionary, y: float) -> float:
	var card := _cartao(COL_E, y, LARG_E, ALT_BRIGA)
	var revenge := bool(c.get("revenge", false))
	_retrato(card, str(c.get("bandit", "")), 6, 12, bool(c.get("known", false)))
	var x := 48.0
	if revenge:
		_carimbo(card, UiTema.txt("hideout_kind_revenge", "REVANCHE"), x, 6.0)
	else:
		_chip(card, UiTema.txt("hideout_kind_fight", "BRIGA"), x, 6)
	var larg_marca := (UiTema.largura_visivel(UiTema.txt("hideout_kind_revenge", "REVANCHE")) + 14.0) if revenge else (UiTema.largura_visivel(UiTema.txt("hideout_kind_fight", "BRIGA")) + 14.0)
	_txt(card, str(c.get("nickname", "")).to_upper(), UiTema.INK, x + roundf(larg_marca) + 6.0, 10.0 if not revenge else 12.0)
	var perfil := str(c.get("profile", "")).to_upper()
	_txt(card, perfil, UiTema.G0, x, 29.0)
	_passiva_linha(card, c.get("passive", {}), x + UiTema.largura(perfil) + 8.0, 29.0)
	_txt(card, str(c.get("challenge_text", "")).to_upper(), UiTema.R1, x, 41.0)
	var bandido := str(c.get("bandit", ""))
	_botao_ir(card, LARG_E - 6.0 - 40.0, 21.0, true, func() -> void: ir_pedido.emit("alley", bandido))
	return ALT_BRIGA + 2.0


func _cartao_desafio(c: Dictionary, y: float) -> float:
	var card := _cartao(COL_E, y, LARG_E, ALT_DESAFIO)
	var chip := _chip(card, UiTema.txt("hideout_kind_challenge", "DESAFIO"), 6, 6)
	_txt(card, str(c.get("nickname", "")).to_upper(), UiTema.INK, 6.0 + chip.size.x + 6.0, 9.0)
	_txt(card, str(c.get("challenge_text", "")).to_upper(), UiTema.R1, 6.0, 26.0)
	var bandido := str(c.get("bandit", ""))
	_botao_ir(card, LARG_E - 6.0 - 40.0, 9.0, true, func() -> void: ir_pedido.emit("alley", bandido))
	return ALT_DESAFIO + 2.0


## Carimbo REVANCHE (moldura dupla falhada, texto r2: carimbo fica fora da regra de contraste).
func _carimbo(pai: Node, texto: String, x: float, y: float) -> void:
	var w := roundf(UiTema.largura_visivel(texto)) + 14.0
	var c := UiTema.nine_patch(pai, "c_carimbo_moldura", Rect2(x, y - 2.0, w, 16))
	UiTema.rotulo_centrado(c, UiTema.area_nove("c_carimbo_moldura", Vector2(w, 16)), texto, UiTema.R1)


# ---------------------------------------------------------------- parede do Dossiê
func _montar_dossie() -> void:
	_cabecalho(UiTema.txt("hideout_dossier_title", "DOSSIÊ"), COL_D)
	var y := Y0
	for f in _d.get("dossier", []):
		_ficha(f, y)
		y += ALT_FICHA + 2.0 + GAP
	_ficha_chefe(_d.get("boss", {}), y)


func _ficha(f: Dictionary, y: float) -> void:
	var card := _cartao(COL_D, y, LARG_D, ALT_FICHA)
	var sabe := bool(f.get("known", false))
	_retrato(card, str(f.get("bandit", "")), 4, 4, sabe)
	var x := 44.0
	var nome := str(f.get("name", "")).to_upper()
	_txt(card, nome, UiTema.INK if sabe else UiTema.G0, x, 7.0)
	if sabe:
		_txt(card, str(f.get("nickname", "")).to_upper(), UiTema.R1, x + UiTema.largura(nome) + 8.0, 7.0)
		_txt(card, str(f.get("stamp", "")).to_upper(), UiTema.G0, x, 18.0)
	else:
		_cadeado(card, x, 16.0)  # o texto "LENDA {n}" sozinho é ambíguo: o cadeado diz que a ficha está trancada
		_txt(card, str(f.get("missing_text", "")).to_upper(), UiTema.R1, x + 10.0, 18.0)
	# B3: desafio feito = selo dourado com o gato aceso e texto escuro; por fazer = ícone e texto apagados.
	var feito := bool(f.get("challenge", false))
	if feito:
		for k in 2:  # moldura de tinta (11x11) e miolo dourado (9x9)
			var selo := ColorRect.new()
			selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			selo.color = UiTema.INK if k == 0 else UiTema.Y1
			selo.position = Vector2(x - 1.0 + float(k), 26.0 + float(k))
			selo.size = Vector2(11 - 2 * k, 11 - 2 * k)
			selo.set_meta("ui_align", "ignore")
			card.add_child(selo)
	var ic := UiTema.textura_rect(card, "icon_region_black_cat_9", x, 27.0)
	ic.modulate = Color.WHITE if feito else Color(1, 1, 1, 0.3)
	_txt(card, str(f.get("challenge_text", "")).to_upper(), UiTema.INK if feito else Color(UiTema.G0, 0.55), x + 14.0, 29.0)
	if sabe:
		var b := UiTema.botao(card, Rect2(LARG_D - 6.0 - 36.0, 6.0, 36, 16), "c_btn_papel_normal")
		UiTema.botao_conteudo(b, UiTema.txt("hideout_read", "LER"), UiTema.INK)
		var id := str(f.get("bandit", ""))
		b.pressed.connect(func() -> void:
			sfx.foco()
			ficha_pedida.emit(id))


## A 4ª ficha: a silhueta do chefe da 2a2 ("???" e o que falta).
func _ficha_chefe(boss: Dictionary, y: float) -> void:
	var card := _cartao(COL_D, y, LARG_D, ALT_FICHA)
	var q := UiTema.textura_rect(card, "c_retrato_moldura", 4, 4)
	var fundo := ColorRect.new()
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.color = UiTema.INK
	fundo.position = Vector2(2, 2)
	fundo.size = Vector2(32, 32)
	q.add_child(fundo)
	_txt(card, UiTema.txt("fighter_name_hidden", "???"), UiTema.G0, 44.0, 7.0)
	_cadeado(card, 44.0, 16.0)
	_txt(card, str(boss.get("missing_text", "")).to_upper(), UiTema.R1, 54.0, 18.0)


# ---------------------------------------------------------------- prateleira de troféus (vazia na 2a1)
func _montar_prateleira() -> void:
	var y := 244.0
	var card := _cartao(12, y, 616, 56)
	var chip := _chip(card, UiTema.txt("hideout_shelf_title", "TROFÉUS"), 6, 6)
	var vazio := UiTema.txt("hideout_shelf_empty", "AINDA VAZIA")
	var l := _txt(card, vazio, UiTema.G0, 6, 32.0)
	UiTema.alinhar(l, "left")  # embaixo do chip TROFÉUS, colada na esquerda
	var tem: Array = _d.get("trophies", [])
	# 4 lugares marcados (nicho ink com o filete de cima em d2), no meio da prateleira.
	var n := 4
	var w := 64.0
	var gap := 12.0
	var x0 := roundf((616.0 - (float(n) * w + float(n - 1) * gap)) / 2.0)
	for i in n:
		var nicho := ColorRect.new()
		nicho.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nicho.color = UiTema.INK
		nicho.position = Vector2(x0 + float(i) * (w + gap), 9.0)
		nicho.size = Vector2(w, 38)
		nicho.set_meta("ui_fundo_escuro", true)
		card.add_child(nicho)
		var luz := ColorRect.new()
		luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		luz.color = UiTema.D2
		luz.size = Vector2(w, 1)
		nicho.add_child(luz)
		if i < tem.size():
			UiTema.rotulo_centrado(nicho, Rect2(0, 0, w, 38), "*", UiTema.Y1)
	chip.visible = true
