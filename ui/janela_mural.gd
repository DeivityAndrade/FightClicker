class_name JanelaMural
extends JanelaBase
## MURAL DA ESCOLA (Fase 6c2): um retrato por entrada do roster (o John primeiro), o saldo de Honra, o bônus dos selos e o
## hall ("O QUE FICOU NA PAREDE", 6 nós). Abre da parede da sala (consulta, a qualquer hora) e do botão MURAL da tela de fim
## (única hora em que o hall compra). Só lê `GameState.mural()` / `hall_lista()` e chama `comprar_hall()`; nenhuma conta aqui.
## Layout (base 640x360): janela 600x344 no meio; esquerda a grade de retratos (5 colunas x 2 fileiras por página, páginas
## com < > e roda do mouse); direita a lista do hall. O texto dos cartões quebra por largura medida: nada é cortado.

signal fechar_pedido

const JANELA := Rect2(20, 8, 600, 344)
const GRADE_X := 30.0
const CELULA_W := 80.0
const TOPO_GRADE := 62.0
const PASSO_FILEIRA := 139.0
const QUADRO_W := 62.0
const TEXTO_Y := 72.0
const LINHA_H := 9.0
const LINHAS_MAX := 7
const BORDA_E := 28.0
const BORDA_D := 612.0
const HALL_X := 441.0
const HALL_Y := 94.0
const HALL_PASSO := 42.0
const HALL_LARG := 171.0

var sfx: Sfx
var _dados: Dictionary = {}
var _pagina := 0
var _conteudo: Control
var _pode_comprar_aqui := false


## `do_fim`: aberto pelo botão MURAL da tela de fim (o hall pode comprar; o GameState decide pelos estados).
func abrir_com(do_fim: bool = false) -> void:
	_pode_comprar_aqui = do_fim
	sfx = Sfx.new()
	add_child(sfx)
	moldura("ui_window", JANELA)
	faixa_titulo("neutral", Rect2(BORDA_E, 14, BORDA_D - BORDA_E, 22), UiTema.txt("mural_title", "MURAL DA ESCOLA"), UiTema.WHITE, 2)
	var x := UiTema.botao_estilizado(painel, Rect2(592, 17, 16, 16), "ui_map_close")
	x.name = "Fechar"
	x.pressed.connect(func() -> void: fechar_pedido.emit())
	_conteudo = Control.new()
	_conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.size = TELA
	painel.add_child(_conteudo)
	_montar()
	animar_entrada()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_ir_para(_pagina + 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_ir_para(_pagina - 1)


func _paginas() -> int:
	var por_pagina := maxi(1, int(_dados.get("columns", 5)) * int(_dados.get("rows_per_page", 2)))
	return maxi(1, int(ceil(float(_dados.entries.size()) / float(por_pagina))))


func _ir_para(p: int) -> void:
	var nova := clampi(p, 0, _paginas() - 1)
	if nova == _pagina:
		return
	_pagina = nova
	sfx.foco()
	call_deferred("_montar")


## Reconstrói tudo o que depende dos dados (troca de página, compra no hall).
func _montar() -> void:
	for c in _conteudo.get_children():
		c.queue_free()
		_conteudo.remove_child(c)
	_dados = GameState.mural()
	_pagina = clampi(_pagina, 0, _paginas() - 1)
	_cabecalho()
	_grade()
	_hall()


# --- Cabeçalho: saldo de Honra (esquerda), bônus dos selos (direita), páginas ---

func _cabecalho() -> void:
	var saldo := UiTema.txt("mural_honor_balance", "HONRA: {n}", {"n": NumberFormat.fmt(float(_dados.honor))})
	UiTema.textura_rect(_conteudo, "icon_honor", BORDA_E + 2.0, 43)
	UiTema.rotulo(_conteudo, saldo, UiTema.COL_HONOR, BORDA_E + 14.0, 43)
	var linha := str(_dados.bonus_line).to_upper()
	var bonus := UiTema.rotulo(_conteudo, linha, UiTema.GR3 if int(_dados.bonus_pct) > 0 else UiTema.G2, 0, 43)
	bonus.position.x = roundf(BORDA_D - UiTema.largura_visivel(linha))
	divisor(BORDA_E, 57, BORDA_D - BORDA_E)
	fundo_cor(Rect2(434, 62, 1, 282), UiTema.D2)
	if _paginas() > 1:
		_paginador()


## "<  2/3  >" no canto da faixa do título, à esquerda do X.
func _paginador() -> void:
	var texto := "%d/%d" % [_pagina + 1, _paginas()]
	var ant := UiTema.botao(_conteudo, Rect2(504, 16, 18, 18))
	var glifo_a := UiTema.botao_conteudo(ant, "<", UiTema.G1 if _pagina <= 0 else UiTema.WHITE)  # desligada: o glifo apaga junto
	ant.name = "PaginaAnterior"
	ant.disabled = _pagina <= 0
	ant.pressed.connect(func() -> void: _ir_para(_pagina - 1))
	var prox := UiTema.botao(_conteudo, Rect2(562, 16, 18, 18))
	var glifo_p := UiTema.botao_conteudo(prox, ">", UiTema.G1 if _pagina >= _paginas() - 1 else UiTema.WHITE)
	prox.name = "PaginaSeguinte"
	prox.disabled = _pagina >= _paginas() - 1
	prox.pressed.connect(func() -> void: _ir_para(_pagina + 1))
	var pag := UiTema.rotulo_centrado(_conteudo, Rect2(522, 16, 40, 18), texto, UiTema.G3)
	UiTema.alinhar(pag, "ignore")  # centrado entre os dois botões (522..562), não no pai


# --- Grade de retratos ---

func _grade() -> void:
	var colunas := maxi(1, int(_dados.get("columns", 5)))
	var por_pagina := colunas * maxi(1, int(_dados.get("rows_per_page", 2)))
	var itens: Array = _dados.entries
	if itens.is_empty():
		# Carreira 1 (o John ainda joga): ninguém passou o posto. Chave pedida ao produtor: mural_empty.
		var vazio := UiTema.rotulo_centrado(_conteudo, Rect2(GRADE_X, TOPO_GRADE + 60.0, CELULA_W * 5.0, 12), UiTema.txt("mural_empty", "AINDA NINGUÉM PASSOU O POSTO"), UiTema.G2)
		vazio.name = "MuralVazio"
		UiTema.alinhar(vazio, "ignore")  # centrado na área da grade (30..430), não na janela
		return
	for k in por_pagina:
		var i := _pagina * por_pagina + k
		if i >= itens.size():
			break
		_cartao(itens[i], GRADE_X + float(k % colunas) * CELULA_W, TOPO_GRADE + float(k / colunas) * PASSO_FILEIRA, i == 0)


func _cartao(e: Dictionary, x: float, y: float, primeiro: bool) -> void:
	var linhas := _linhas_do_cartao(e)
	var card := Control.new()
	card.name = "Retrato_%d" % int(e.campaign)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.position = Vector2(x, y)
	card.size = Vector2(CELULA_W, TEXTO_Y + LINHA_H * float(linhas.size()))
	_conteudo.add_child(card)
	var fx := floorf((CELULA_W - QUADRO_W) / 2.0)
	# A moldura é a mãe: fundo e busto ficam DENTRO do furo dela (3,3), não sobre ela.
	var moldura_t := UiTema.textura_rect(card, "ui_mural_portrait_frame_first" if primeiro else "ui_mural_portrait_frame", fx, 0)
	UiTema.textura_rect(moldura_t, "ui_mural_portrait_bg", 3, 3)
	var busto := TextureRect.new()
	busto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busto.texture = _busto(e)
	busto.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	busto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	busto.stretch_mode = TextureRect.STRETCH_SCALE
	busto.position = Vector2(3, 3)
	busto.size = Vector2(56, 60)  # o busto 28x30 em 2x
	UiTema.alinhar(busto, "ignore")  # imagem dentro do furo da moldura
	moldura_t.add_child(busto)
	if bool(e.sealed):
		var selo := UiTema.textura_rect(card, "ui_mural_seal", fx + 48.0, 48)
		selo.name = "Selo"
		UiTema.alinhar(selo, "ignore")  # o selo sai da moldura de propósito (embaixo à direita)
	for i in linhas.size():
		var l: Dictionary = linhas[i]
		var yy := TEXTO_Y + LINHA_H * float(i)
		if str(l.get("icone", "")) != "":
			var grupo := 9.0 + 3.0 + UiTema.largura_visivel(str(l.texto))
			var x0 := roundf((CELULA_W - grupo) / 2.0)
			UiTema.textura_rect(card, str(l.icone), x0, yy)
			UiTema.rotulo(card, str(l.texto), l.cor, x0 + 12.0, yy)
		else:
			UiTema.rotulo_centro(card, str(l.texto), l.cor, CELULA_W / 2.0, yy)


func _busto(e: Dictionary) -> Texture2D:
	if str(e.kind) == "first":
		return UiTema.textura("mural_portrait_john")
	var look = e.get("look", null)
	var lk: Dictionary = GameState.disciples.validar_look(look) if look is Dictionary else GameState.disciples.look_padrao.duplicate()
	return DiscVisual.textura("mural_portrait_disc", lk, bool(e.symbol))


## Linhas de texto do cartão (já quebradas na largura da célula). Passam de LINHAS_MAX só em casos extremos: aí cai primeiro a
## linha da arte, depois a da carreira (o recorte e o fim contam a história; o resto o jogador vê na ficha).
func _linhas_do_cartao(e: Dictionary) -> Array:
	var nome: Array = _quebrar(str(e.name).to_upper(), CELULA_W - 4.0)
	var fim: Array = _quebrar(str(e.end_text).to_upper(), CELULA_W - 4.0)
	var extra: Array = []
	if str(e.extra_key) != "":
		extra = _quebrar(UiTema.txt(str(e.extra_key)), CELULA_W - 4.0)
	var blocos := {"nome": [], "carreira": [], "arte": [], "vitorias": [], "fim": [], "honra": [], "extra": []}
	for t in nome:
		blocos.nome.append({"texto": t, "cor": UiTema.Y1 if str(e.kind) == "first" else UiTema.WHITE})
	blocos.carreira.append({"texto": str(e.career_text).to_upper(), "cor": UiTema.G2})
	blocos.arte.append({"texto": str(e.art_text).to_upper(), "cor": UiTema.P2 if str(e.art) != "" else UiTema.G1})
	var vit := {"texto": str(e.wins_text).to_upper(), "cor": UiTema.Y1}
	if bool(e.belt):
		vit["icone"] = "icon_belt_amateur_9"
	blocos.vitorias.append(vit)
	for t in fim:
		blocos.fim.append({"texto": t, "cor": UiTema.CREAM})
	if bool(e.sealed):
		blocos.honra.append({"texto": UiTema.txt("end_honor_gain", "+{n} HONRA", {"n": NumberFormat.fmt(float(e.honor))}), "cor": UiTema.COL_HONOR})
	for t in extra:
		blocos.extra.append({"texto": t, "cor": UiTema.G3})
	var ordem := ["nome", "carreira", "arte", "vitorias", "fim", "honra", "extra"]
	var total := 0
	for k in ordem:
		total += blocos[k].size()
	for corte in ["arte", "carreira"]:
		if total > LINHAS_MAX:
			total -= blocos[corte].size()
			blocos[corte] = []
	var r: Array = []
	for k in ordem:
		r.append_array(blocos[k])
	return r


## Quebra por palavras na largura medida da fonte; palavra maior que a largura quebra por letra (nome longo sem espaço).
func _quebrar(texto: String, largura_max: float) -> Array:
	var r: Array = []
	var atual := ""
	for palavra in texto.split(" ", false):
		var p: String = palavra
		while UiTema.largura_visivel(p) > largura_max:
			var corte := p.length() - 1
			while corte > 1 and UiTema.largura_visivel(p.substr(0, corte)) > largura_max:
				corte -= 1
			if atual != "":
				r.append(atual)
				atual = ""
			r.append(p.substr(0, corte))
			p = p.substr(corte)
		var teste := p if atual == "" else atual + " " + p
		if UiTema.largura_visivel(teste) <= largura_max:
			atual = teste
		else:
			r.append(atual)
			atual = p
	if atual != "":
		r.append(atual)
	return r


# --- Hall ---

func _hall() -> void:
	UiTema.rotulo(_conteudo, UiTema.txt("hall_title", "O QUE FICOU NA PAREDE"), UiTema.WHITE, HALL_X, 62)
	var lista: Array = GameState.hall_lista()
	var fechado := false
	for n in lista:
		if str(n.state) == "closed":
			fechado = true
	if fechado:
		pass  # 6d2: "O HALL SÓ SE COMPRA ENTRE CAMPANHAS" saiu: cada nó trancado já diz COMPRA NO FIM DA CAMPANHA
	for i in lista.size():
		_no(lista[i], HALL_Y + HALL_PASSO * float(i))


func _no(n: Dictionary, y: float) -> void:
	var estado := str(n.state)
	var aceso := estado == "owned" or estado == "buyable"
	var linha := Control.new()
	linha.name = "No_" + str(n.id)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.position = Vector2(HALL_X, y)
	linha.size = Vector2(HALL_LARG, 41)
	_conteudo.add_child(linha)
	var icone := "icon_hall_" + str(n.id).trim_prefix("hall_")
	UiTema.textura_rect(linha, icone if aceso else icone + "_gray", 0, 0)
	# Nome e descrição pelas chaves do Roteirista (hall_box_name / hall_box_desc); o GameState ainda devolve os provisórios do hall.json.
	var nome_no := UiTema.txt(str(n.id) + "_name", str(n.name))
	UiTema.rotulo(linha, nome_no, UiTema.Y2 if estado == "buyable" else (UiTema.WHITE if aceso else UiTema.G2), 20, 1)
	if estado != "owned":
		var custo := NumberFormat.fmt(float(n.cost))
		var larg := UiTema.largura_visivel(custo)
		var rc := UiTema.rotulo(linha, custo, UiTema.COL_HONOR if aceso else UiTema.G1, 0, 1)
		rc.position.x = roundf(HALL_LARG - larg)
		UiTema.textura_rect(linha, "icon_honor", roundf(HALL_LARG - larg - 12.0), 1)
	var desc: Array = _quebrar(UiTema.txt(str(n.id) + "_desc", str(n.effect_text)), HALL_LARG - 20.0)
	for k in mini(2, desc.size()):
		UiTema.rotulo(linha, str(desc[k]), UiTema.G3 if aceso else UiTema.G1, 20, 11 + 9 * k)
	var texto := ""
	var cor := UiTema.G1
	match estado:
		"owned":
			texto = UiTema.txt("hall_owned", "COMPRADO")
			cor = UiTema.GR3
		"buyable":
			texto = UiTema.txt("hall_cost", "{n} DE HONRA", {"n": NumberFormat.fmt(float(n.cost))})
			cor = UiTema.COL_HONOR
		"missing":
			texto = UiTema.txt("hall_missing", "FALTAM {n} DE HONRA", {"n": NumberFormat.fmt(float(n.missing))})
			cor = UiTema.R3
		_:
			texto = UiTema.txt("hall_buy_only_end", "COMPRA NO FIM DA CAMPANHA")
	# Fase 6d: balão colado ao cursor com o que o nó dá (descrição inteira), o preço e o estado.
	var linhas_dica: Array = [
		{"texto": nome_no, "cor": UiTema.WHITE},
		{"texto": UiTema.txt(str(n.id) + "_desc", str(n.effect_text)), "cor": UiTema.G3},
		{"texto": texto, "cor": cor if estado != "closed" else UiTema.G2},
	]
	var area := Control.new()
	area.name = "Hover"
	area.mouse_filter = Control.MOUSE_FILTER_PASS
	area.size = linha.size
	UiTema.alinhar(area, "ignore")
	linha.add_child(area)
	_ligar_balao(area, linhas_dica, linha)
	var w := roundf(UiTema.largura_visivel(texto)) + 12.0
	var rect := Rect2(20, 30, w, 11)
	if estado == "buyable":
		var b := UiTema.botao(linha, rect, "ui_honor_chip")
		for e in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(e, UiTema.estilo("ui_honor_chip"))
		b.mouse_entered.connect(func() -> void: b.modulate = Color(1.3, 1.3, 1.3))
		b.mouse_exited.connect(func() -> void: b.modulate = Color.WHITE)
		UiTema.botao_conteudo(b, texto, cor)
		b.name = "Comprar"
		_ligar_balao(b, linhas_dica, linha)  # o botão fica por cima da área: também mostra o balão
		var id := str(n.id)
		b.pressed.connect(func() -> void: _comprar(id))
	else:
		var chip := UiTema.nine_patch(linha, "ui_honor_chip", rect)
		UiTema.rotulo_centrado(chip, UiTema.area_nove("ui_honor_chip", rect.size), texto, cor)


func _ligar_balao(c: Control, linhas: Array, alvo: Control) -> void:
	c.mouse_entered.connect(func() -> void: Dica.pedir_linhas(linhas, alvo))
	c.mouse_exited.connect(Dica.limpar)
	c.tree_exiting.connect(Dica.limpar)  # a linha é refeita depois da compra e a janela fecha: o balão não fica órfão


func _comprar(id: String) -> void:
	if GameState.comprar_hall(id):
		sfx.compra()
		call_deferred("_montar")
