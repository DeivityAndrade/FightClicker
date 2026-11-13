class_name JanelaArvore
extends JanelaBase
## Árvore de habilidades (Fase 4), entre uma carreira e outra. Abre pelo botão ÁRVORE da tela de fim (só existe com a
## tela de fim pendente: `GameState.arvore_aberta()`). Duas colunas, CORPO e CARREIRA, com o "Y" que sai do 1º nó.
## Cada nó mostra peça 24x24 do estado (aprendido / comprável / falta Legado / trancado), nome, efeito curto e plaquinha
## com o preço; o texto completo vem num cartão ao passar o mouse. Comprar = 1 clique (sem confirmação). Os bônus valem na
## carreira seguinte. A UI só lê `arvore_nos()` e chama `comprar_no()`; nenhuma conta aqui.
## Geometria: manifest.tree_layout (janela 480x300 em 80,20).

signal nova_carreira_pedido

const JANELA := Rect2(80, 20, 480, 300)
const FAIXA := Rect2(86, 26, 468, 16)
const COLUNAS := {"body": Rect2(90, 48, 226, 228), "career": Rect2(324, 48, 226, 228), "style": Rect2(207, 48, 226, 228)}
const SLOTS_ESTILO := [[56, 40], [170, 40]]  # Fase 5: os 2 nós do ESTILO lado a lado (centro-topo, relativo à coluna)
const ALT_NO_ESTILO := 79.0  # peça + nome + efeito + plaquinha + "SÓ VALE JOGANDO DE ..." (2 linhas)
const PAGINA_PRINCIPAL := "main"
const PAGINA_ESTILO := "style"
const ALTURA_CAB := 14.0
const LARG_NO := 104.0  # largura útil por nó
const ALT_NO := 57.0  # peça 24 + nome + efeito + plaquinha
const DICA_LARGURA := 160.0

var sfx: Sfx
var _layout: Dictionary = {}
var _slots: Dictionary = {}  # id do nó -> "root" | "a1" | "a2" | "b1" | "b2"
var _camada: Control  # desenho dos nós (refeito a cada compra)
var _cliques: Control  # botões transparentes por cima (refeitos junto)
var _legado_rotulo: Label
var _legado_icone: TextureRect
var _legado_mostrado := 0
var _celulas: Dictionary = {}  # id -> {cel, peca, plaqueta}
var _donos_antes: Array = []
var _dica: Control
var _tw_legado: Tween
var _pagina := PAGINA_PRINCIPAL  # Fase 5: "main" = CORPO e CARREIRA; "style" = aba ESTILO (só com as artes liberadas)
var _colunas: Control
var _abas: Dictionary = {}  # pagina -> Button


func abrir_com() -> void:
	sfx = Sfx.new()
	add_child(sfx)
	_layout = UiTema.manifest().get("tree_layout", {})
	for ramo in _layout.get("slots_by_branch", {}):
		for slot in _layout.slots_by_branch[ramo]:
			_slots[str(_layout.slots_by_branch[ramo][slot])] = str(slot)
	_donos_antes = GameState.nos_comprados()
	_legado_mostrado = GameState.legado_disponivel()
	_montar_fixo()
	_reconstruir()
	GameState.arvore_mudou.connect(_ao_arvore_mudou)
	animar_entrada()


# --- Partes fixas: moldura, título, colunas, botão ---

func _montar_fixo() -> void:
	moldura("ui_tree_window", JANELA)
	# Faixa roxa: o título à esquerda e "LEGADO: N" à direita (com o ícone), os dois centralizados na altura da faixa.
	var faixa := UiTema.nine_patch(painel, "ui_window_title_retire", FAIXA)
	faixa.set_meta("ui_pos", "center_h")
	var area := UiTema.area_nove("ui_window_title_retire", FAIXA.size)
	var titulo := UiTema.rotulo(faixa, UiTema.txt("tree_title", "O QUE O VELHO TE ENSINOU"), UiTema.WHITE, area.position.x + 4.0,
		UiTema.y_texto(area))
	UiTema.alinhar(titulo, "left")
	var ic := UiTema.tamanho_quadro("icon_legacy")
	_legado_icone = UiTema.textura_rect(faixa, "icon_legacy", 0, UiTema.y_imagem(area, ic.y))
	_legado_rotulo = UiTema.rotulo(faixa, "", UiTema.P2, 0, UiTema.y_texto(area))
	_mostrar_legado(_legado_mostrado)

	_colunas = Control.new()
	_colunas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_colunas.size = TELA
	painel.add_child(_colunas)

	_camada = Control.new()
	_camada.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada.size = TELA
	painel.add_child(_camada)
	_cliques = Control.new()
	_cliques.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cliques.size = TELA
	_cliques.set_meta("ui_align_row", "free")  # os 4 botões da fileira dos nós não precisam de espaçamento igual
	painel.add_child(_cliques)

	# Com a aba ESTILO a fileira de baixo tem 3 botões iguais (140 px, folga de 20): [CORPO / CARREIRA] [NOVA CARREIRA] [ESTILO].
	var com_abas := GameState.arvore_ramos().any(func(r: Dictionary) -> bool: return str(r.id) == "style")
	var b := botao_texto(Rect2(250, 284, 140, 24) if com_abas else Rect2(240, 284, 160, 24),
		UiTema.txt("tree_new_career", "NOVA CAMPANHA"), UiTema.WHITE)
	b.pressed.connect(func() -> void: nova_carreira_pedido.emit())
	_montar_abas()


## Colunas da página atual: CORPO e CARREIRA, ou ESTILO (cada uma com a faixa de cima: ícone + nome do ramo, centralizados).
func _montar_colunas() -> void:
	for c in _colunas.get_children():
		c.queue_free()
	var visiveis: Array = GameState.arvore_ramos().map(func(b: Dictionary) -> String: return str(b.id))
	for ramo in GameState.lutas.ramos:
		var id := str(ramo.id)
		if not COLUNAS.has(id) or not (id in visiveis) or (id == "style") != (_pagina == PAGINA_ESTILO):
			continue
		var r: Rect2 = COLUNAS[id]
		UiTema.nine_patch(_colunas, "ui_tree_column_" + id, r)
		var cab := Control.new()
		cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cab.position = r.position
		cab.size = Vector2(r.size.x, ALTURA_CAB)
		_colunas.add_child(cab)
		var nome := UiTema.txt("tree_branch_" + id, str(ramo.name))
		var icone := "icon_branch_" + id
		var ti := UiTema.tamanho_quadro(icone)
		var grupo := ti.x + 4.0 + UiTema.largura_visivel(nome)
		var gx := roundf((r.size.x - grupo) / 2.0)
		UiTema.textura_rect(cab, icone, gx, UiTema.y_imagem(Rect2(0, 0, r.size.x, ALTURA_CAB), ti.y))
		var l := UiTema.rotulo(cab, nome, UiTema.WHITE, gx + ti.x + 4.0, UiTema.y_texto(Rect2(0, 0, r.size.x, ALTURA_CAB)))
		l.add_theme_color_override("font_color", UiTema.WHITE)


## Abas na fileira de baixo (só com o ramo ESTILO liberado): [CORPO / CARREIRA] NOVA CARREIRA [ESTILO], as duas abas do
## mesmo tamanho e a mesma folga (10 px) para o botão do meio.
func _montar_abas() -> void:
	var tem_estilo := false
	var nomes: Array[String] = []
	for r in GameState.arvore_ramos():
		if str(r.id) == "style":
			tem_estilo = true
		else:
			nomes.append(UiTema.txt("tree_branch_" + str(r.id), str(r.name)))
	if not tem_estilo:
		return
	var defs := [[PAGINA_PRINCIPAL, " / ".join(nomes), Rect2(90, 284, 140, 24)],
		[PAGINA_ESTILO, UiTema.txt("tree_branch_style", "ESTILO"), Rect2(410, 284, 140, 24)]]
	for d in defs:
		var b := botao_texto(d[2], str(d[1]), UiTema.WHITE)
		var pag: String = d[0]
		b.pressed.connect(func() -> void: _trocar_pagina(pag))
		_abas[pag] = b
	_estilizar_abas()


func _estilizar_abas() -> void:
	for pag in _abas:
		var b: Button = _abas[pag]
		var ativa: bool = pag == _pagina
		UiTema.aplicar_estilo_botao(b, "ui_button_pressed" if ativa else "ui_button_normal")
		for c in b.get_children():
			if c is Label:
				c.add_theme_color_override("font_color", (UiTema.P2 if pag == PAGINA_ESTILO else UiTema.WHITE) if ativa else UiTema.G2)


func _trocar_pagina(pag: String) -> void:
	if pag == _pagina:
		return
	_pagina = pag
	_estilizar_abas()
	_reconstruir()
	sfx.foco()


## "LEGADO: N" encostado na direita da faixa, com o ícone logo antes do texto.
func _mostrar_legado(valor: int) -> void:
	var texto := UiTema.txt("tree_legacy", "LEGADO: {n}", {"n": valor})
	_legado_rotulo.text = texto
	var area := UiTema.area_nove("ui_window_title_retire", FAIXA.size)
	var larg := UiTema.largura_visivel(texto)
	var x_fim := area.end.x - 4.0
	_legado_rotulo.position.x = roundf(x_fim - larg)
	_legado_icone.position.x = roundf(x_fim - larg - 4.0 - UiTema.tamanho_quadro("icon_legacy").x)


# --- Nós ---

func _reconstruir() -> void:
	_esconder_dica()
	_montar_colunas()
	for c in _camada.get_children():
		c.queue_free()
	for c in _cliques.get_children():
		c.queue_free()
	_celulas.clear()
	var nos := GameState.arvore_nos()
	var estado: Dictionary = {}
	for n in nos:
		estado[str(n.id)] = str(n.state)
	# Ligações e Y por baixo dos nós (só CORPO e CARREIRA: o ESTILO tem 2 nós soltos).
	if _pagina == PAGINA_PRINCIPAL:
		for ramo in ["body", "career"]:
			_desenhar_fios(ramo, COLUNAS[ramo], estado)
	var i_estilo := 0
	for n in nos:
		if (str(n.branch) == "style") != (_pagina == PAGINA_ESTILO):
			continue
		_montar_no(n, i_estilo)
		if str(n.branch) == "style":
			i_estilo += 1


func _slot(id: String, ramo: String, i_estilo: int = 0) -> Array:
	if ramo == "style":
		return SLOTS_ESTILO[mini(i_estilo, SLOTS_ESTILO.size() - 1)]
	var slots: Dictionary = _layout.get("node_slots", {})
	var nome := str(_slots.get(id, ""))
	return slots.get(nome, [])


## "Y" que sai do 1º nó e a ligação de cada caminho até o 2º nó. Acende (roxo) quando o nó de baixo está aprendido.
func _desenhar_fios(ramo: String, col: Rect2, estado: Dictionary) -> void:
	var por_slot: Dictionary = _layout.get("slots_by_branch", {}).get(ramo, {})
	if por_slot.is_empty():
		return
	var raiz_ok := str(estado.get(str(por_slot.get("root", "")), "")) == "owned"
	var a1_ok := str(estado.get(str(por_slot.get("a1", "")), "")) == "owned"
	var b1_ok := str(estado.get(str(por_slot.get("b1", "")), "")) == "owned"
	var a2_ok := str(estado.get(str(por_slot.get("a2", "")), "")) == "owned"
	var b2_ok := str(estado.get(str(por_slot.get("b2", "")), "")) == "owned"
	var fp: Array = _layout.get("fork_pos", [55, 78])
	var origem := col.position + Vector2(float(fp[0]), float(fp[1]))
	for parte in [["stem", raiz_ok], ["left", a1_ok], ["right", b1_ok]]:
		_sprite_fio(origem, "ui_tree_fork_%s_normal" % parte[0])
		if parte[1]:
			_sprite_fio(origem, "ui_tree_fork_%s_active" % parte[0])
	var lk: Array = _layout.get("links", [[56, 155], [170, 155]])
	var pivo := UiTema.pivo("ui_tree_link_normal")
	for i in 2:
		var p := col.position + Vector2(float(lk[i][0]), float(lk[i][1])) - pivo
		_sprite_fio(p, "ui_tree_link_normal")
		if (a2_ok if i == 0 else b2_ok):
			_sprite_fio(p, "ui_tree_link_active")


func _sprite_fio(pos_: Vector2, nome: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.texture = UiTema.textura(nome)
	s.position = pos_
	_camada.add_child(s)
	return s


func _montar_no(n: Dictionary, i_estilo: int = 0) -> void:
	var id := str(n.id)
	var ramo := str(n.branch)
	var slot := _slot(id, ramo, i_estilo)
	if slot.is_empty() or not COLUNAS.has(ramo):
		push_warning("JanelaArvore: nó '%s' sem lugar no manifest.tree_layout; não aparece." % id)
		return
	var col: Rect2 = COLUNAS[ramo]
	var cx := col.position.x + float(slot[0])
	var topo := col.position.y + float(slot[1])
	var estado := str(n.state)
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get(id, {})
	var tile: Dictionary = info.get("tile", {})

	# Célula do nó: 104 px de largura, centrada no x do slot. Tudo o que é texto fica dentro dela.
	var cel := Control.new()
	cel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cel.position = Vector2(cx - LARG_NO / 2.0, topo)
	cel.size = Vector2(LARG_NO, ALT_NO_ESTILO if ramo == "style" else ALT_NO)
	_camada.add_child(cel)
	var peca := AnimSprite.new()
	var nome_peca := str(tile.get(estado, "skill_%s_%s" % [id, estado]))
	peca.definir(nome_peca)
	peca.position = Vector2(LARG_NO / 2.0 - 12.0, 0)
	if UiTema.sprite(nome_peca).get("frames", 1) > 1:
		peca.tocar([0, 1], float(UiTema.sprite(nome_peca).get("fps", 3.0)), true)
	cel.add_child(peca)

	var trancado := estado == "locked"
	var cor_ramo := UiTema.R3 if ramo == "body" else (UiTema.P2 if ramo == "style" else UiTema.Y1)
	var cor_nome := UiTema.G2 if trancado else UiTema.WHITE
	var cor_efeito := UiTema.G1 if trancado else cor_ramo
	UiTema.rotulo_centrado(cel, Rect2(0, 26, LARG_NO, 7), str(n.name).to_upper(), cor_nome, 1, false, "center_h")
	UiTema.rotulo_centrado(cel, Rect2(0, 35, LARG_NO, 7), _efeito_curto(n), cor_efeito, 1, false, "center_h")

	# Plaquinha: preço (comprável), APRENDIDO, FALTAM n ou PEDE O DE CIMA.
	var texto := ""
	var cor_plaqueta := UiTema.WHITE
	match estado:
		"owned":
			texto = UiTema.txt("tree_owned", "APRENDIDO")
			cor_plaqueta = UiTema.GR3
		"buyable":
			texto = UiTema.txt("tree_buy", "{n} DE LEGADO", {"n": NumberFormat.fmt(float(n.cost))})
			cor_plaqueta = UiTema.Y1
		"missing":
			texto = UiTema.txt("tree_missing", "FALTAM {n}", {"n": NumberFormat.fmt(float(n.missing))})
			cor_plaqueta = UiTema.R3
		_:
			texto = UiTema.txt("tree_requires_short", "PEDE O DE CIMA")
			cor_plaqueta = UiTema.G1
	var w := roundf(UiTema.largura_visivel(texto)) + 12.0
	if int(w) % 2 != 0:
		w += 1.0  # largura par: a plaquinha fica no meio exato da célula
	w = maxf(w, 56.0)
	var plaqueta := UiTema.nine_patch(cel, "ui_tree_plate_" + _sufixo_plaqueta(estado), Rect2((LARG_NO - w) / 2.0, 45, w, 11))
	plaqueta.set_meta("ui_pos", "center_h")
	UiTema.rotulo_centrado(plaqueta, UiTema.area_nove("ui_tree_plate_" + _sufixo_plaqueta(estado), Vector2(w, 11)), texto, cor_plaqueta)
	if str(n.get("art_only_text", "")) != "":
		# "SÓ VALE JOGANDO DE BOXE": o nó só vale na carreira dessa arte (2 linhas, centralizadas, embaixo da plaquinha).
		var so := UiTema.rotulo(cel, str(n.art_only_text).to_upper(), UiTema.G2, 0, 60, LARG_NO, HORIZONTAL_ALIGNMENT_CENTER)
		UiTema.alinhar(so, "center_h")
	_celulas[id] = {"cel": cel, "peca": peca, "plaqueta": plaqueta}

	# Botão transparente por cima da célula inteira: passar o mouse mostra o cartão, clicar compra.
	var botao := Button.new()
	botao.focus_mode = Control.FOCUS_NONE
	botao.flat = true
	botao.position = cel.position
	botao.size = cel.size
	for estilo in ["normal", "hover", "pressed", "disabled", "focus"]:
		botao.add_theme_stylebox_override(estilo, StyleBoxEmpty.new())
	botao.mouse_entered.connect(func() -> void: _sobre(id, true))
	botao.mouse_exited.connect(func() -> void: _sobre(id, false))
	botao.pressed.connect(func() -> void: _clicou(id))
	_cliques.add_child(botao)


func _sufixo_plaqueta(estado: String) -> String:
	match estado:
		"owned":
			return "owned"
		"buyable":
			return "buy"
		"missing":
			return "missing"
	return "locked"


## Efeito curto (cabe em 16 caracteres): `effect_short` do nó, se vier no dado; senão as chaves `tree_short_<id>` do
## ui_texts.json; senão o efeito completo.
func _efeito_curto(n: Dictionary) -> String:
	var modelo := str(n.get("effect_short", ""))
	if modelo == "":
		modelo = GameState.texto_ui("tree_short_" + str(n.id), "")
	if modelo == "":
		modelo = str(n.get("effect_text", ""))
	var enviado: Dictionary = n.duplicate()
	enviado["effect_text"] = modelo
	return GameState.texto_efeito_no(enviado).to_upper()


# --- Mouse ---

func _sobre(id: String, dentro: bool) -> void:
	if not _celulas.has(id):
		return
	var cel: Control = _celulas[id].cel
	cel.modulate = Color(1.18, 1.18, 1.18) if dentro else Color.WHITE
	if dentro:
		mostrar_dica(id)
	else:
		_esconder_dica()


func _clicou(id: String) -> void:
	if GameState.estado_no(id) == "buyable" and GameState.comprar_no(id):
		return  # o resto acontece no sinal `arvore_mudou`
	_recusar(id)


## Nó que não dá para comprar (falta Legado ou está trancado): a plaquinha treme de leve e pisca.
func _recusar(id: String) -> void:
	if not _celulas.has(id):
		return
	var p: Control = _celulas[id].plaqueta
	var x0 := p.position.x
	var tw := create_tween()
	for d in [2.0, -2.0, 1.0, 0.0]:
		tw.tween_property(p, "position:x", x0 + d, 0.035)
	p.modulate = Color(1.6, 0.9, 0.9)
	create_tween().tween_property(p, "modulate", Color.WHITE, 0.3)


# --- Cartão de detalhes (nome, descrição, efeito completo e estado) ---

func mostrar_dica(id: String) -> void:
	_esconder_dica()
	var n: Dictionary = {}
	for item in GameState.arvore_nos():
		if str(item.id) == id:
			n = item
			break
	if n.is_empty() or not _celulas.has(id):
		return
	var cel: Control = _celulas[id].cel
	var fonte := UiTema.fonte()
	var largura_txt := DICA_LARGURA - 14.0
	var estado := str(n.state)
	var linhas: Array = [
		{"texto": str(n.name).to_upper(), "cor": UiTema.Y1},
		{"texto": str(n.description).to_upper(), "cor": UiTema.CREAM},
		{"texto": str(n.effect_text).to_upper(), "cor": UiTema.R3 if str(n.branch) == "body" else (UiTema.P2 if str(n.branch) == "style" else UiTema.Y1)},
	]
	if str(n.get("art_only_text", "")) != "":
		linhas.append({"texto": str(n.art_only_text).to_upper(), "cor": UiTema.G2})
	match estado:
		"owned":
			linhas.append({"texto": UiTema.txt("tree_owned", "APRENDIDO"), "cor": UiTema.GR3})
		"buyable":
			linhas.append({"texto": UiTema.txt("tree_buy", "{n} DE LEGADO", {"n": NumberFormat.fmt(float(n.cost))}), "cor": UiTema.Y1})
		"missing":
			linhas.append({"texto": UiTema.txt("tree_buy", "{n} DE LEGADO", {"n": NumberFormat.fmt(float(n.cost))}) + "  " \
				+ UiTema.txt("tree_missing", "FALTAM {n}", {"n": NumberFormat.fmt(float(n.missing))}), "cor": UiTema.R3})
		_:
			linhas.append({"texto": UiTema.txt("tree_requires", "PRIMEIRO APRENDA: {nome}", {"nome": str(n.requires_name)}),
				"cor": UiTema.G2})
	var altura := 12.0
	for l in linhas:
		var tam := fonte.get_multiline_string_size(str(l.texto), HORIZONTAL_ALIGNMENT_LEFT, largura_txt, UiTema.TAMANHO_FONTE)
		l["n"] = maxi(1, int(roundf(tam.y / fonte.get_height(UiTema.TAMANHO_FONTE))))
		altura += 9.0 * float(l.n) + 3.0
	altura -= 3.0
	_dica = Control.new()
	_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dica.z_index = 10
	UiTema.alinhar(_dica, "ignore")  # cartão que acompanha o nó: posição livre de propósito
	var x := cel.position.x + cel.size.x + 4.0
	if x + DICA_LARGURA > JANELA.end.x - 6.0:
		x = cel.position.x - 4.0 - DICA_LARGURA
	var y := clampf(cel.position.y, JANELA.position.y + 22.0, 280.0 - altura)  # não cobre o botão NOVA CARREIRA
	_dica.position = Vector2(roundf(x), roundf(y))
	_dica.size = Vector2(DICA_LARGURA, altura)
	painel.add_child(_dica)
	UiTema.nine_patch(_dica, "ui_card", Rect2(0, 0, DICA_LARGURA, altura))
	var yy := 6.0
	for l in linhas:
		var r := UiTema.rotulo(_dica, str(l.texto), l.cor, 7, yy - 1.0, largura_txt)
		r.size.y = 9.0 * float(l.n)
		yy += 9.0 * float(l.n) + 3.0


func _esconder_dica() -> void:
	if _dica != null:
		_dica.queue_free()
		_dica = null


# --- Compra: o nó acende, o Legado desce contando ---

func _ao_arvore_mudou() -> void:
	var agora := GameState.nos_comprados()
	var novo := ""
	for id in agora:
		if not _donos_antes.has(id):
			novo = str(id)
	_donos_antes = agora
	_reconstruir()
	_contar_legado(GameState.legado_disponivel())
	if novo == "":
		return
	sfx.no_aprendido()
	_festejar(novo)


func _contar_legado(alvo: int) -> void:
	if _tw_legado != null and _tw_legado.is_valid():
		_tw_legado.kill()
	var de := _legado_mostrado
	_legado_mostrado = alvo
	if de == alvo:
		_mostrar_legado(alvo)
		return
	_tw_legado = create_tween()
	_tw_legado.tween_method(func(p: float) -> void:
		_mostrar_legado(int(roundf(lerpf(float(de), float(alvo), p)))), 0.0, 1.0, 0.35)
	_tw_legado.tween_callback(func() -> void: _mostrar_legado(alvo))
	_legado_rotulo.modulate = Color(1.9, 1.9, 1.9)
	create_tween().tween_property(_legado_rotulo, "modulate", Color.WHITE, 0.4)
	# "-N" sobe do contador (some em 0,6 s).
	var gasto := de - alvo
	var flutuante := UiTema.rotulo(painel, "-%d" % gasto, UiTema.P2, _legado_rotulo.global_position.x - 4.0, FAIXA.end.y + 2.0, 0,
		HORIZONTAL_ALIGNMENT_LEFT, true)
	UiTema.alinhar(flutuante, "ignore")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(flutuante, "position:y", FAIXA.end.y + 12.0, 0.6)
	tw.tween_property(flutuante, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(flutuante.queue_free)


## O nó recém-aprendido dá um pulo, brilha, a plaquinha vira APRENDIDO com um flash e a janela dá uma tremidinha de 1 px.
func _festejar(id: String) -> void:
	if not _celulas.has(id):
		return
	var d: Dictionary = _celulas[id]
	var peca: Node2D = d.peca
	var y0 := peca.position.y
	peca.position.y = y0 - 5.0
	peca.modulate = Color(2.6, 2.6, 2.6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(peca, "position:y", y0, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(peca, "modulate", Color.WHITE, 0.45)
	var pl: Control = d.plaqueta
	pl.modulate = Color(2.2, 2.2, 1.6)
	create_tween().tween_property(pl, "modulate", Color.WHITE, 0.5)
	var treme := create_tween()
	for p in [Vector2(1, 0), Vector2(-1, 1), Vector2.ZERO]:
		treme.tween_property(painel, "position", p, 0.03)
