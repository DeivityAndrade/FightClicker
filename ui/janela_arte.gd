class_name JanelaArte
extends JanelaBase
## Janela "QUE TIPO DE LUTADOR VOCÊ QUER SER?" (Fase 5): as duas artes lado a lado, cada uma com o ícone do aparelho, o nome,
## a frase de tom (`tagline`), a regra em número (`rule_text`), a passiva de luta (`art_card_*_fight`, 3 linhas), "VALE A CARREIRA INTEIRA" e o
## botão ESCOLHER. Abre na 1ª chegada à academia, no começo de toda carreira (com as artes liberadas) e ao reabrir o jogo sem
## ter escolhido (`GameState.escolha_arte_pendente()`). Sem X: enquanto não escolhe, o jogo fica travado. 1 clique escolhe
## (no botão ESCOLHER ou em qualquer ponto do cartão). A arte da carreira anterior vem com a borda dourada e o selo
## "ÚLTIMA: BOXE". Só lê `artes_para_escolha()` e chama `escolher_arte()`; nenhuma regra aqui.
## Geometria: manifest.by_data_id.art_window (janela 420x268 em 110,34; 2 cartões de 190x220).

signal escolheu(arte: String)

# 7b2: cada cartão ganhou as 2 opções de passiva (1ª e 2ª) e ficou mais alto (190x288); a janela cresce junto e continua no meio (14..346).
const JANELA := Rect2(110, 14, 420, 332)
const CARTOES := [Rect2(124, 48, 190, 288), Rect2(326, 48, 190, 288)]
# 7b1: com a 3ª arte (Muay Thai) os 3 cartões de 190x220 ficam lado a lado numa janela mais larga (604 px, margem 11 px dos dois lados).
const JANELA_3 := Rect2(18, 14, 604, 332)
const CARTOES_3 := [Rect2(29, 48, 190, 288), Rect2(225, 48, 190, 288), Rect2(421, 48, 190, 288)]
# 7b2: as 2 caixas de passiva dentro do cartão (coordenadas do cartão).
const OPC_X := 6.0
const OPC_LARG := 178.0
const OPC_ALT := 52.0
const OPC_Y := [138.0, 194.0]
const LARG_BOTAO := 120.0
const ALT_BOTAO := 20.0

var sfx: Sfx
var _cartoes: Array[Dictionary] = []  # {id, area, fundo, ultima, container, botao, hover}
var _escolhida := ""
var _sel: Dictionary = {}  # arte -> passiva marcada (1 ou 2); a que vale quando o cartão é clicado
var _opcoes: Dictionary = {}  # arte -> [{n, borda, fundo, botao, nome, estrela, trancada, cor}]
var _t := 0.0


func abrir_com() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	var artes: Array = GameState.artes_para_escolha()
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("art_window", {})
	var tres := artes.size() >= 3
	var janela := JANELA_3 if tres else JANELA
	var posicoes: Array = CARTOES_3 if tres else CARTOES
	moldura("ui_window", janela)
	faixa_titulo("retire", Rect2(janela.position.x + 6.0, janela.position.y + 6.0, janela.size.x - 12.0, 16), UiTema.txt("art_title", "QUE TIPO DE LUTADOR VOCÊ QUER SER?"))
	UiTema.rotulo_centro(painel, GameState.subtitulo_escolha_arte().to_upper(), UiTema.G3, 320.0, janela.position.y + 22.0)
	# Camadas: fundos dos cartões, a área clicável de cada cartão e, por cima, o conteúdo (rótulos e botões ESCOLHER).
	var fundos := Control.new()
	fundos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundos.size = TELA
	painel.add_child(fundos)
	var cliques := Control.new()
	cliques.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cliques.size = TELA
	UiTema.fileira_livre(cliques, "os cartões (2 ou 3) ficam lado a lado e a área clicável de cada um tem o tamanho do cartão")
	painel.add_child(cliques)
	var conteudo := Control.new()
	conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conteudo.size = TELA
	painel.add_child(conteudo)
	var n := mini(artes.size(), posicoes.size())
	# Com uma arte só (não acontece hoje) o cartão fica no meio da janela.
	for i in n:
		var r: Rect2 = posicoes[i]
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
	var nome_normal := "c_cartao"  # tema C: o cartão é papel; a arte da última carreira leva o selo ÚLTIMA e o hover clareia
	var base := Control.new()  # cada cartão tem o próprio Control do tamanho dele (não é uma "janela" solta na tela cheia)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.position = r.position
	base.size = r.size
	fundos.add_child(base)
	var fundo := UiTema.nine_patch(base, nome_normal, Rect2(Vector2.ZERO, r.size))

	# Área clicável do cartão (por baixo do conteúdo: o botão ESCOLHER continua clicável por cima).
	var area := Button.new()
	area.focus_mode = Control.FOCUS_NONE
	area.flat = true
	area.position = r.position + Vector2(0, 6)  # a área clicável começa na faixa do nome: os 6 px de cima são do selo ÚLTIMA (sem botão por baixo do texto dele)
	area.size = r.size - Vector2(0, 6)
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
	var cab := UiTema.nine_patch(c, cab_nome, Rect2(6, 6, 178, 20))
	cab.set_meta("ui_pos", "center_h")
	cab.set_meta("ui_fundo_escuro", true)  # a faixa do nome é colorida: texto claro
	UiTema.textura_rect(cab, str(por_id.get("icon", "art_" + id)), 3, 1)
	UiTema.rotulo_centrado(cab, UiTema.area_nove(cab_nome, Vector2(178, 20)), str(arte.name).to_upper(), UiTema.WHITE, 2, false, "center_h")

	# Ilustração do aparelho (72x56) no meio do cartão.
	var ilus := UiTema.textura_rect(c, str(por_id.get("card_art", "art_card_" + id)), floorf((r.size.x - 72.0) / 2.0), 28)
	ilus.set_meta("ui_pos", "center_h")

	# Textos: tagline, regra, traço de luta, "vale a carreira inteira". Cada um centralizado, até 2 linhas em 174 px.
	_texto(c, str(arte.tagline).to_upper(), UiTema.CREAM, 90.0, r.size.x)
	_texto(c, str(arte.rule_text).to_upper(), UiTema.P2, 114.0, r.size.x)
	# 7b2: as 2 opções de passiva (a 2ª trancada mostra o cadeado e a meta "N/3"). Clicar numa opção só a marca;
	# a arte é escolhida pelo ESCOLHER ou pelo resto do cartão, com a passiva marcada.
	var passivas: Array = arte.get("passives", [])
	_sel[id] = int(arte.get("passive_default", 1))
	_opcoes[id] = []
	for k in mini(passivas.size(), OPC_Y.size()):
		_opcoes[id].append(_montar_opcao(c, id, passivas[k], float(OPC_Y[k]), por_id))
	_pintar(id)
	_texto(c, UiTema.txt("art_whole_career", "VALE A CARREIRA INTEIRA"), UiTema.G2, 250.0, r.size.x)

	# Botão ESCOLHER, centralizado no cartão.
	var b := UiTema.botao(c, Rect2(floorf((r.size.x - LARG_BOTAO) / 2.0), 262, LARG_BOTAO, ALT_BOTAO), "c_btn_foco")
	UiTema.botao_conteudo(b, UiTema.txt("art_choose", "ESCOLHER"), UiTema.CREAM, 1)
	b.set_meta("ui_pos", "center_h")
	b.pressed.connect(func() -> void: _escolher(id))

	# Selo "ÚLTIMA: BOXE" sobre a borda de cima, do lado direito.
	if ultima:
		var texto := str(arte.get("last_text", "")).to_upper()
		var w := roundf(UiTema.largura_visivel(texto)) + 10.0
		if int(w) % 2 != 0:
			w += 1.0
		var tag := UiTema.nine_patch(c, str(info.get("tag_last", "ui_art_tag_last")), Rect2(r.size.x - w - 10.0, -7, w, 13))
		var a := UiTema.area_nove("ui_art_tag_last", Vector2(w, 13))
		var l := UiTema.rotulo(tag, texto, Sala.BR0, roundf(a.position.x + (a.size.x - UiTema.largura_visivel(texto)) / 2.0),
			UiTema.y_texto(a), 0, HORIZONTAL_ALIGNMENT_LEFT, false)
		UiTema.alinhar_motivo(l, "left", "texto do selo ÚLTIMA sobre a borda do cartão")
	return {"id": id, "area": area, "fundo": fundo, "ultima": ultima, "container": c, "botao": b, "rect": r,
		"normal": nome_normal, "hover": str(info.get("card", {}).get("hover", "ui_art_card_hover")), "aceso": false}


## Uma caixa de passiva: ícone 16x16 + nome (linha de cima) e, embaixo, a frase da passiva ou, se trancada, "N/3 META" + barra.
func _montar_opcao(c: Control, id: String, p: Dictionary, y: float, por_id: Dictionary) -> Dictionary:
	var trancada := bool(p.get("locked", false))
	var cor := _cor_arte(id)
	var borda := ColorRect.new()
	borda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	borda.position = Vector2(OPC_X, y)
	borda.size = Vector2(OPC_LARG, OPC_ALT)
	borda.set_meta("ui_fundo_escuro", true)  # a caixa da passiva é escura (ink): texto claro dentro
	c.add_child(borda)
	var fundo := ColorRect.new()
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.position = Vector2(1, 1)
	fundo.size = Vector2(OPC_LARG - 2.0, OPC_ALT - 2.0)
	borda.add_child(fundo)
	# Ícone: a 1ª usa o ícone da arte; a 2ª, o ícone próprio (a versão cinza com cadeado enquanto trancada).
	var icone := str(por_id.get("icon", "art_" + id)) if int(p.n) == 1 else str(p.get("icon", ""))
	if trancada and icone != "":
		icone += "_locked"
	if icone != "" and not UiTema.sprite(icone).is_empty():
		UiTema.textura_rect(borda, icone, 4, 2)
	var nome := UiTema.rotulo(borda, str(p.name).to_upper(), UiTema.G2 if trancada else cor, 24, 5, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	UiTema.alinhar_motivo(nome, "left", "nome da passiva ao lado do ícone, na caixa da passiva")
	var marca: Control = null
	var texto_label: Label = null
	var largura_texto := OPC_LARG - 10.0
	if trancada:
		# Cadeado à direita do nome; embaixo a meta e a barra.
		marca = _quadro(borda, "ui_passive_lock", 9, 12, 0, OPC_LARG - 14.0, 2.0)
		var prog: Dictionary = p.get("progress", {})
		var l := UiTema.rotulo(borda, str(prog.get("text", "")).to_upper(), UiTema.Y1, 5, 21, largura_texto, HORIZONTAL_ALIGNMENT_LEFT)
		UiTema.alinhar_motivo(l, "left", "texto da passiva ao lado do ícone, na caixa da passiva")
		_barra_meta(borda, 5.0, 36.0, largura_texto, int(prog.get("n", 0)), int(prog.get("m", 3)))
	else:
		marca = _quadro(borda, "ui_passive_goal_pip", 7, 7, 0, OPC_LARG - 13.0, 5.0)
		var l := UiTema.rotulo(borda, str(p.fight_text).to_upper(), UiTema.CREAM, 5, 19, largura_texto, HORIZONTAL_ALIGNMENT_LEFT)
		UiTema.alinhar_motivo(l, "left", "texto da passiva em até 3 linhas, na caixa da passiva")
		l.size = Vector2(largura_texto, 32)
		texto_label = l
	# Botão invisível sobre a caixa: marca a opção (a trancada só treme o cadeado).
	var botao := Button.new()
	botao.focus_mode = Control.FOCUS_NONE
	botao.flat = true
	botao.position = Vector2(OPC_X, y)
	botao.size = Vector2(OPC_LARG, OPC_ALT)
	for e in ["normal", "hover", "pressed", "disabled", "focus"]:
		botao.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	var n := int(p.n)
	botao.pressed.connect(func() -> void: _marcar(id, n))
	c.add_child(botao)
	return {"n": n, "borda": borda, "fundo": fundo, "botao": botao, "nome": nome, "marca": marca, "trancada": trancada, "cor": cor, "texto": texto_label}


## Quadro `q` de uma folha horizontal (cada quadro lw x lh).
func _quadro(pai: Control, nome: String, lw: int, lh: int, q: int, x: float, y: float) -> Control:
	if UiTema.sprite(nome).is_empty():
		var cr := ColorRect.new()
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.color = UiTema.Y2
		cr.position = Vector2(x, y)
		cr.size = Vector2(lw, lh)
		pai.add_child(cr)
		return cr
	var t := TextureRect.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var at := AtlasTexture.new()
	at.atlas = UiTema.textura(nome)
	at.region = Rect2(float(lw * q), 0, lw, lh)
	t.texture = at
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.position = Vector2(x, y)
	t.size = Vector2(lw, lh)
	UiTema.ignorar(t, "quadro de folha de sprites (pip/cadeado) em posição livre dentro da caixa da passiva")
	pai.add_child(t)
	return t


static func _definir_quadro(t: Control, lw: int, q: int) -> void:
	if t is TextureRect and (t as TextureRect).texture is AtlasTexture:
		var at := (t as TextureRect).texture as AtlasTexture
		at.region = Rect2(float(lw * q), at.region.position.y, at.region.size.x, at.region.size.y)


## Barra da meta: moldura 9-slice + enchimento (n/m do interior) + uma divisória em cada 1/m.
func _barra_meta(pai: Control, x: float, y: float, larg: float, n: int, m: int) -> void:
	var interior := larg - 4.0
	if not UiTema.sprite("ui_passive_progress_bar").is_empty():
		UiTema.ignorar(UiTema.nine_patch(pai, "ui_passive_progress_bar", Rect2(x, y, larg, 8)), "moldura da barra de meta, em posição livre dentro da caixa da passiva")
	else:
		var q := ColorRect.new()
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
		q.color = UiTema.D2
		q.position = Vector2(x, y)
		q.size = Vector2(larg, 8)
		pai.add_child(q)
	var w := roundf(interior * float(n) / float(maxi(m, 1)))
	if w >= 1.0:
		var t := TextureRect.new()
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not UiTema.sprite("ui_passive_progress_fill").is_empty():
			var at := AtlasTexture.new()
			at.atlas = UiTema.textura("ui_passive_progress_fill")
			at.region = Rect2(4.0 if n >= m else 0.0, 0, 4, 4)
			t.texture = at
		else:
			var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
			img.fill(UiTema.Y2)
			t.texture = ImageTexture.create_from_image(img)
		t.stretch_mode = TextureRect.STRETCH_TILE
		t.position = Vector2(x + 2.0, y + 2.0)
		t.size = Vector2(w, 4)
		UiTema.ignorar(t, "enchimento da barra de meta, dentro da moldura")
		pai.add_child(t)
	for k in range(1, m):
		var tick := ColorRect.new()
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.color = UiTema.G2
		tick.position = Vector2(x + 2.0 + roundf(interior * float(k) / float(m)), y + 2.0)
		tick.size = Vector2(1, 4)
		UiTema.ignorar(tick, "divisória da barra de meta, em posição livre dentro da moldura")
		pai.add_child(tick)


## Marca uma opção (a trancada não marca: o cadeado treme).
func _marcar(id: String, n: int) -> void:
	if _escolhida != "":
		return
	for o in _opcoes.get(id, []):
		if int(o.n) != n:
			continue
		if bool(o.trancada):
			var cad: Control = o.marca
			var x0 := cad.position.x
			var tw := create_tween()
			tw.tween_property(cad, "position:x", x0 - 2.0, 0.04)
			tw.tween_property(cad, "position:x", x0 + 2.0, 0.06)
			tw.tween_property(cad, "position:x", x0, 0.04)
			return
		_sel[id] = n
		_pintar(id)
		return


## Seleção clara: a marcada tem borda dourada, fundo mais claro, nome branco e a estrela cheia; as outras ficam apagadas.
func _pintar(id: String) -> void:
	for o in _opcoes.get(id, []):
		var marcada: bool = int(o.n) == int(_sel.get(id, 1)) and not bool(o.trancada)
		(o.borda as ColorRect).color = UiTema.Y2 if marcada else UiTema.G1
		(o.fundo as ColorRect).color = UiTema.D2.lightened(0.1) if marcada else UiTema.INK
		if not bool(o.trancada):
			(o.nome as Label).add_theme_color_override("font_color", UiTema.WHITE if marcada else o.cor)
			_definir_quadro(o.marca, 7, 1 if marcada else 0)
			(o.marca as Control).modulate = Color.WHITE if marcada else Color(1, 1, 1, 0.6)


## Cor da arte no texto da passiva: Boxe vermelho, Jiu-jitsu azul, Muay Thai laranja de couro (7b1).
func _cor_arte(id: String) -> Color:
	return UiTema.R3 if id == "boxing" else (UiTema.BR3 if id == "muay_thai" else UiTema.B3)


## Linha de texto centralizada no cartão (até 2 linhas de 174 px, quebra por palavra).
func _texto(c: Control, texto: String, cor: Color, y: float, largura_cartao: float) -> void:
	var l := UiTema.rotulo(c, texto, cor, 8.0, y, largura_cartao - 16.0, HORIZONTAL_ALIGNMENT_CENTER)
	UiTema.alinhar(l, "center_h")


func _escolher(id: String) -> void:
	if _escolhida != "":
		return
	if not GameState.escolher_arte(id, int(_sel.get(id, 0))):
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
		for o in _opcoes.get(c.id, []):
			(o.botao as Button).disabled = true
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
		c.fundo.modulate = Color(1.15, 1.12, 1.0) if dentro else Color.WHITE  # hover: o papel clareia
