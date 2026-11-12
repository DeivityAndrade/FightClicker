class_name PainelLoja
extends Control
## Painel direito, com duas abas:
##  - TREINO: EQUIPE (geradores, botão CHAMAR) e MELHORIAS (próximo nível por aparelho), pagos em Treino;
##  - LOJA: Prof. Nelson (gerador pago) e luvas, pagos em DINHEIRO (só vem das lutas).
## Preços e "pode comprar" vêm do GameState; botão desabilitado quando não dá para pagar (ou durante a luta).

signal info_mudou(info: Dictionary)  # {} = limpar; senão {titulo, texto, extra}

const ALTURA_CARTAO := 44.0
const PASSO := 45.0
const ALTURA_BOTAO := 13.0
const ALTURA_CARTAO_LOJA := 60.0
const ABA_TREINO := "treino"
const ABA_LOJA := "loja"
const ALTURA_JANELA := 250.0  # altura útil da aba (a aba TREINO rola quando o aparelho da arte entra: 4 aparelhos + equipe)
const PASSO_ROLAGEM := 24.0

var _gens: Dictionary = {}  # gerador -> item
var _ups: Dictionary = {}  # aparelho -> item
var _unl: Dictionary = {}  # aparelho (com unlock) -> item do cartão de compra (Fase 4b)
var _pagos: Dictionary = {}  # gerador pago -> item
var _luva: Dictionary = {}  # item da luva de loja
var _metro: Dictionary = {}  # item do Metrônomo (Fase 4)
var _hover := ""  # "g:<id>", "u:<id>", "p:<id>" ou "l" do item sob o mouse
var _primeira := true
var _aba := ABA_TREINO
var _aba_treino: Control  # conteúdo da aba TREINO (dentro de _janela_treino, que recorta e rola)
var _janela_treino: Control
var _rolagem := 0.0
var _rolagem_max := 0.0
var _altura_treino := 0.0
var _seta_cima: SetaRolagem
var _seta_baixo: SetaRolagem
var _sub_loja: Label
var _aba_loja: Control
var _tab: Dictionary = {}  # nome -> {botao, rotulo}
var _alerta_loja: Label
var _t := 0.0
var _janela_loja: Control
var _altura_loja := 0.0
var _crew: Dictionary = {}  # Grito da equipe (Fase 5.2); {} = a melhoria não existe nos dados
var _luva_atual: Label
var _luva_atual_icone: TextureRect
var _rot_melhorias: Label
var _div_melhorias: ColorRect
var _y_melhorias := 0.0


func _ready() -> void:
	position = Vector2(512, 18)
	size = Vector2(128, 272)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_meta("ui_margens", "h")  # conteúdo com a mesma margem à esquerda e à direita
	var ui: Dictionary = GameState.dados.ui
	UiTema.painel(self, "ui_panel", Rect2(0, 0, 128, 272))

	_montar_abas()
	_janela_treino = _novo_container()
	_janela_treino.clip_contents = true  # Fase 5: o conteúdo rola com a roda do mouse quando passa de 250 px
	_aba_treino = Control.new()
	_aba_treino.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aba_treino.size = Vector2(128, ALTURA_JANELA)
	_janela_treino.add_child(_aba_treino)
	# Fase 5.2: a aba LOJA também rola (5 cartões não cabem em 250 px): mesma janela recortada da aba TREINO.
	_janela_loja = _novo_container()
	_janela_loja.clip_contents = true
	_aba_loja = Control.new()
	_aba_loja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aba_loja.size = Vector2(128, ALTURA_JANELA)  # cresce no fim do _ready (_altura_loja)
	_janela_loja.add_child(_aba_loja)

	# --- Aba TREINO ---
	UiTema.rotulo(_aba_treino, str(ui.get("panel_team", "EQUIPE")).to_upper(), UiTema.COL_TEXT_1, 8, 0)  # txt_title
	_divisor(_aba_treino, 9, UiTema.G0)
	var y := 12.0
	for g in GameState.dados.geradores:
		_gens[g.id] = _montar_gerador(g, y)
		y += PASSO
	_rot_melhorias = UiTema.rotulo(_aba_treino, str(ui.get("panel_upgrades", "MELHORIAS")).to_upper(), UiTema.COL_TEXT_1, 8, y)
	_div_melhorias = _divisor(_aba_treino, y + 9, UiTema.G0)
	y += 12.0
	_y_melhorias = y - 12.0
	# Fase 5: os aparelhos das artes (pera, boneco) ocupam o 4º lugar (só um existe por carreira): o cartão de compra
	# enquanto não chega, as técnicas depois.
	var y_aparelhos := y
	var i_slot := 0
	for ap in GameState.dados.todos_aparelhos():
		var da_arte := str(ap.get("art", "")) != ""
		var ya := y_aparelhos + float(GameState.dados.aparelhos.size() if da_arte else i_slot) * PASSO
		_ups[ap.id] = _montar_melhoria(ap, ya)
		var unl := _montar_unlock(ap, ya)  # Fase 4b: no mesmo lugar, o cartão de compra enquanto o aparelho não chegou
		if not unl.is_empty():
			_unl[ap.id] = unl
		if not da_arte:
			i_slot += 1
	y = y_aparelhos + float(GameState.dados.aparelhos.size()) * PASSO
	_altura_treino = y
	_seta_cima = SetaRolagem.new(true)
	_seta_baixo = SetaRolagem.new(false)
	for seta in [_seta_cima, _seta_baixo]:
		seta.position = Vector2(60, 18 if seta == _seta_cima else 266)
		seta.visible = false
		UiTema.alinhar(seta, "ignore")  # indicador por cima do conteúdo: posição livre de propósito
		add_child(seta)

	# --- Aba LOJA ---
	UiTema.rotulo(_aba_loja, UiTema.txt("shop_title", "LOJA"), UiTema.COL_TEXT_1, 8, 0)
	_sub_loja = UiTema.rotulo(_aba_loja, UiTema.txt("shop_sub", "Dinheiro de luta, só aqui."), UiTema.COL_TEXT_2, 8, 10, 112)
	_divisor(_aba_loja, 29, UiTema.G0)
	y = 33.0
	for g in GameState.lutas.geradores_pagos:
		_pagos[g.id] = _montar_gerador_pago(g, y)
		y += ALTURA_CARTAO_LOJA + 3.0
	_luva = _montar_luva(y)
	y += ALTURA_CARTAO_LOJA + 3.0
	_metro = _montar_metronomo(y)
	y += ALTURA_CARTAO_LOJA + 3.0
	if not GameState.lutas.crew_click.is_empty():
		_crew = _montar_crew(y)
		y += ALTURA_CARTAO_LOJA + 1.0
	_luva_atual_icone = UiTema.textura_rect(_aba_loja, "icon_glove_old", 6, y - 1)
	_luva_atual = UiTema.rotulo(_aba_loja, "", UiTema.G3, 26, y + 3, 96)
	_altura_loja = y + 18.0
	_aba_loja.size.y = _altura_loja

	GameState.crew_click_mudou.connect(func(_c: bool) -> void: atualizar())
	GameState.nova_carreira_iniciada.connect(func(_c: Dictionary) -> void: atualizar())
	GameState.carregado.connect(func(_s: int) -> void: atualizar())
	GameState.melhoria_comprada.connect(func(_a: String, _m: String, _n: int) -> void: atualizar())
	GameState.economia_mudou.connect(atualizar)
	GameState.luva_mudou.connect(func(_n: int, _s: String) -> void: atualizar())
	GameState.metronomo_mudou.connect(func(_n: int) -> void: atualizar())
	_trocar_aba(ABA_TREINO)
	atualizar()
	_primeira = false


func _novo_container() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = Vector2(0, 19)
	c.size = Vector2(128, 250)
	add_child(c)
	return c


func _divisor(pai: Control, y: float, cor: Color = UiTema.D2) -> ColorRect:
	var d := ColorRect.new()
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.color = cor
	d.position = Vector2(8, y)
	d.size = Vector2(112, 1)
	pai.add_child(d)
	return d


# --- Abas ---

func _montar_abas() -> void:
	var nomes := {ABA_TREINO: str(GameState.dados.ui.get("hud_training", "TREINO")).to_upper(),
		ABA_LOJA: UiTema.txt("shop_title", "LOJA")}
	var x := 4.0
	for id in [ABA_TREINO, ABA_LOJA]:
		var b := UiTema.botao(self, Rect2(x, 3, 58, 14))
		var r := UiTema.botao_conteudo(b, nomes[id], UiTema.COL_TEXT_2, 1, "icon_treino" if id == ABA_TREINO else "icon_money", 3.0)
		var icone: TextureRect = b.get_meta("icone")
		var aba_id: String = id
		b.pressed.connect(func() -> void: _trocar_aba(aba_id))
		_tab[id] = {"botao": b, "rotulo": r, "icone": icone, "y_rotulo": r.position.y, "y_icone": icone.position.y}
		x += 62.0
	# O "!" pisca no canto da aba: enfeite de propósito (fora do alinhamento do conteúdo).
	_alerta_loja = UiTema.rotulo(_tab[ABA_LOJA].botao, "!", UiTema.Y2, 50, 2)
	UiTema.alinhar(_alerta_loja, "ignore")
	_alerta_loja.visible = false


func _trocar_aba(nome: String) -> void:
	_aba = nome
	_janela_treino.visible = nome == ABA_TREINO
	_janela_loja.visible = nome == ABA_LOJA
	_rolagem = 0.0
	_aba_treino.position.y = 0.0
	_aba_loja.position.y = 0.0
	for id in _tab:
		var ativa: bool = id == nome
		UiTema.aplicar_estilo_botao(_tab[id].botao, "ui_button_pressed" if ativa else "ui_button_normal")
		_tab[id].rotulo.add_theme_color_override("font_color", UiTema.COL_TEXT_1 if ativa else UiTema.COL_TEXT_2)
		# Aba apertada: o botão afunda 1 px (o estilo "pressed" não tem o degrau de baixo), o conteúdo afunda junto.
		_tab[id].rotulo.position.y = float(_tab[id].y_rotulo) + (1.0 if ativa else 0.0)
		_tab[id].icone.position.y = float(_tab[id].y_icone) + (1.0 if ativa else 0.0)
	_hover = ""
	_emitir_info()
	atualizar()


## A loja tem algo que dá para comprar agora? (a aba LOJA pisca um "!" quando não está aberta)
func _loja_tem_compra() -> bool:
	if GameState.acoes_bloqueadas():
		return false
	for g in GameState.lutas.geradores_pagos:
		if GameState.pode_comprar_gerador_pago(g.id):
			return true
	return GameState.pode_comprar_luva() or GameState.pode_comprar_metronomo() or GameState.pode_comprar_crew_click()


# --- Montagem dos cartões ---

func _cartao(pai: Control, y: float, altura: float = ALTURA_CARTAO) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = Vector2(4, y)
	c.size = Vector2(120, altura)
	pai.add_child(c)
	UiTema.painel(c, "ui_card", Rect2(0, 0, 120, altura))
	if altura == ALTURA_CARTAO_LOJA:
		c.set_meta("ui_indent", "card")  # linhas da coluna esquerda alinhadas com o texto do botão
	return c


func _botao_compra(cartao: Control, texto: String, y_botao: float, icone_preco: String = "icon_treino") -> Dictionary:
	var b := UiTema.botao(cartao, Rect2(4, y_botao, 112, ALTURA_BOTAO))
	# Texto à esquerda, preço + ícone à direita; os dois centralizados na vertical na face do botão.
	var a := UiTema.area_botao(b)
	var esq := UiTema.rotulo(b, texto, UiTema.WHITE, 6, UiTema.y_texto(a))
	var icone := UiTema.textura_rect(b, icone_preco, 0, UiTema.y_imagem(a, UiTema.tamanho_quadro(icone_preco).y))
	var preco := UiTema.rotulo(b, "", UiTema.COL_MONEY if icone_preco == "icon_money" else UiTema.COL_TREINO, 0, UiTema.y_texto(a))
	UiTema.alinhar(b, "left")
	# Fase 5.1: o item comprável mais barato da aba ganha um contorno claro (col_buyable).
	var destaque := ReferenceRect.new()
	destaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	destaque.border_color = UiTema.COL_BUYABLE
	destaque.border_width = 1.0
	destaque.editor_only = false
	destaque.size = b.size
	destaque.visible = false
	UiTema.alinhar(destaque, "ignore")
	b.add_child(destaque)
	return {"botao": b, "esq": esq, "icone": icone, "preco": preco, "texto": texto, "destaque": destaque, "moeda": icone_preco}


func _montar_gerador(g: Dictionary, y: float) -> Dictionary:
	var c := _cartao(_aba_treino, y)
	var ids: Dictionary = UiTema.manifest().get("by_data_id", {}).get(g.id, {})
	UiTema.rotulo(c, str(g.get("name", g.id)).to_upper(), UiTema.WHITE, 5, 1, 112)
	UiTema.textura_rect(c, str(ids.get("icon", "icon_neighbor")), 5, 11)
	var qtd := UiTema.rotulo(c, "X0", UiTema.COL_TEXT_1, 26, 11)
	var prod := UiTema.rotulo(c, "", UiTema.COL_TREINO, 26, 11)
	var parte := _botao_compra(c, str(GameState.dados.ui.get("buy_generator", "CHAMAR")).to_upper(), 28)
	var item := {"cartao": c, "qtd": qtd, "prod": prod, "pode": false, "tween": null}
	item.merge(parte)
	var id: String = g.id
	parte.botao.pressed.connect(func() -> void: _comprar_gerador(id))
	parte.botao.mouse_entered.connect(func() -> void: _sobre("g:" + id))
	parte.botao.mouse_exited.connect(func() -> void: _sobre(""))
	return item


func _montar_melhoria(ap: Dictionary, y: float) -> Dictionary:
	var c := _cartao(_aba_treino, y)
	var ids: Dictionary = UiTema.manifest().get("by_data_id", {}).get(ap.id, {})
	# Fase 5.2: ícone 2 px mais alto e o contador "0/4" 1 px abaixo dele (sem encostar no botão) (folga em cima e embaixo, sem encostar no botão).
	var icone_ap := UiTema.textura_rect(c, str(ids.get("icon", "icon_bag")), 5, 1)
	var nivel := UiTema.rotulo(c, "", UiTema.COL_TEXT_2, 4, 18, 18, HORIZONTAL_ALIGNMENT_CENTER)
	# Aparelho da arte (Fase 5): a linha de cima traz o nome da técnica (Jab duplo, Guarda fechada...), a de baixo o efeito.
	var da_arte := str(ap.get("art", "")) != ""
	var nome_tecnica: Label = UiTema.rotulo(c, "", UiTema.WHITE, 26, 2, 92) if da_arte else null
	var efeito := UiTema.rotulo(c, "", UiTema.COL_TEXT_2, 26, 12 if da_arte else 2, 92)
	var parte := _botao_compra(c, str(GameState.dados.ui.get("upgrade_button", "MELHORAR")).to_upper(), 28)
	var item := {"cartao": c, "nivel": nivel, "efeito": efeito, "pode": false, "tween": null, "icone_ap": icone_ap,
		"tecnica": nome_tecnica}
	item.merge(parte)
	var id: String = ap.id
	parte.botao.pressed.connect(func() -> void: _comprar_melhoria(id))
	parte.botao.mouse_entered.connect(func() -> void: _sobre("u:" + id))
	parte.botao.mouse_exited.connect(func() -> void: _sobre(""))
	return item


# Cartão de compra do aparelho (Fase 4b): borda de papelão (liga à plaquinha da sala), silhueta com cadeado, nome,
# atributo que ele treina e o botão COMPRAR com o preço em Treino. Aparelho que pede o anterior: botão apagado com
# "DEPOIS DA ESTEIRA". Mesmo tamanho e mesma posição do cartão de melhorias que vai ocupar o lugar depois da compra.
func _montar_unlock(ap: Dictionary, y: float) -> Dictionary:
	var u: Dictionary = GameState.desbloqueio(str(ap.id))
	if u.is_empty():
		return {}
	var m: Dictionary = UiTema.manifest().get("by_data_id", {}).get(str(u.get("id", "")), {})
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = Vector2(4, y)
	c.size = Vector2(120, ALTURA_CARTAO)
	_aba_treino.add_child(c)
	var fundo := UiTema.painel(c, str(m.get("card", "ui_card_unlock")), Rect2(0, 0, 120, ALTURA_CARTAO))
	var icone := UiTema.textura_rect(c, str(m.get("icon_locked", "icon_treadmill_locked")), 5, 3)
	var nome := UiTema.rotulo(c, GameState.nome_curto_aparelho(str(ap.id)).to_upper(), UiTema.WHITE, 26, 2, 92)
	var atributo := str(GameState.dados.atributo_info(str(ap.attribute)).get("name", ap.attribute)).to_upper()
	if str(ap.get("art", "")) != "":
		atributo = _atributos_da_arte(ap)  # a pera e o boneco treinam os três: "FOR AGI RES"
	var rotulo_atr := UiTema.rotulo(c, atributo, UiTema.G2, 26, 12, 92)
	var parte := _botao_compra(c, UiTema.txt("unlock_buy", "COMPRAR"), 28)
	var item := {"cartao": c, "fundo": fundo, "icone_item": icone, "nome": nome, "atributo": rotulo_atr, "m": m,
		"pode": false, "tween": null, "tween_estilo": null, "id": str(ap.id)}
	item.merge(parte)
	var id: String = ap.id
	parte.botao.pressed.connect(func() -> void: _comprar_aparelho(id))
	parte.botao.mouse_entered.connect(func() -> void: _sobre("a:" + id))
	parte.botao.mouse_exited.connect(func() -> void: _sobre(""))
	# Recolhido (trancado ou na caixa), o cartão vira 1 linha e o detalhe vem na dica de hover.
	var hov := Control.new()
	hov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hov.size = c.size
	UiTema.alinhar(hov, "ignore")
	c.add_child(hov)
	hov.mouse_entered.connect(func() -> void: Dica.pedir(_texto_recolhido(id)))
	hov.mouse_exited.connect(func() -> void: Dica.limpar())
	item["hover"] = hov
	item["colapsado"] = false
	return item


## "FOR AGI RES": as 3 primeiras letras dos atributos que o aparelho da arte treina (os da divisão `split`), na ordem do jogo.
func _atributos_da_arte(ap: Dictionary) -> String:
	var partes: Array[String] = []
	var split: Dictionary = ap.get("split", {})
	for id in GameState.dados.atributos:
		if float(split.get(id, 0.0)) > 0.0:
			partes.append(str(GameState.dados.atributo_info(id).get("name", id)).to_upper().left(3))
	return " ".join(partes)


# Cartão da loja: ícone 16x16, nome, quantidade/nível, efeito, aviso de saldo e botão com o preço em $.
func _montar_gerador_pago(g: Dictionary, y: float) -> Dictionary:
	var c := _cartao(_aba_loja, y, ALTURA_CARTAO_LOJA)
	var ids: Dictionary = UiTema.manifest().get("by_data_id", {}).get(g.id, {})
	UiTema.textura_rect(c, str(ids.get("icon", "icon_coach")), 5, 4)
	UiTema.rotulo(c, str(g.get("name", g.id)).to_upper(), UiTema.WHITE, 26, 3, 92)
	var qtd := UiTema.rotulo(c, "X0", UiTema.COL_TEXT_1, 26, 12)
	var efeito := UiTema.rotulo(c, GameState.texto_efeito_loja(g).to_upper(), UiTema.COL_TEXT_2, 26, 21)
	var aviso := UiTema.rotulo(c, "", UiTema.COL_TEXT_2, 10, 31, 104)
	var parte := _botao_compra(c, UiTema.txt("shop_hire", "CONTRATAR"), 43, "icon_money")
	var item := {"cartao": c, "qtd": qtd, "efeito": efeito, "aviso": aviso, "pode": false, "tween": null}
	item.merge(parte)
	var id: String = g.id
	parte.botao.pressed.connect(func() -> void: _comprar_gerador_pago(id))
	parte.botao.mouse_entered.connect(func() -> void: _sobre("p:" + id))
	parte.botao.mouse_exited.connect(func() -> void: _sobre(""))
	return item


func _montar_luva(y: float) -> Dictionary:
	var c := _cartao(_aba_loja, y, ALTURA_CARTAO_LOJA)
	var icone := UiTema.textura_rect(c, "icon_glove_l1", 5, 4)
	var nome := UiTema.rotulo(c, "", UiTema.WHITE, 26, 3, 92)
	var nivel := UiTema.rotulo(c, "", UiTema.COL_TEXT_1, 26, 12)
	var efeito := UiTema.rotulo(c, "", UiTema.COL_TEXT_2, 26, 21)
	var aviso := UiTema.rotulo(c, "", UiTema.COL_TEXT_2, 10, 31, 104)
	var parte := _botao_compra(c, UiTema.txt("shop_buy", "COMPRAR"), 43, "icon_money")
	var item := {"cartao": c, "icone_item": icone, "nome": nome, "nivel": nivel, "efeito": efeito, "aviso": aviso,
		"pode": false, "tween": null}
	item.merge(parte)
	parte.botao.pressed.connect(_comprar_luva)
	parte.botao.mouse_entered.connect(func() -> void: _sobre("l"))
	parte.botao.mouse_exited.connect(func() -> void: _sobre(""))
	return item


# Grito da equipe (Fase 5.2, dinheiro): ícone, nome, o efeito (CLIQUE +N (1 S DA EQUIPE), em 2 linhas) e o botão com o preço.
func _montar_crew(y: float) -> Dictionary:
	var d: Dictionary = GameState.lutas.crew_click
	var c := _cartao(_aba_loja, y, ALTURA_CARTAO_LOJA)
	UiTema.textura_rect(c, str(d.get("icon", "icon_crew_click")), 5, 4)
	UiTema.rotulo(c, str(d.get("name", "")).to_upper(), UiTema.WHITE, 26, 3, 92)
	var efeito := UiTema.rotulo(c, "", UiTema.COL_TEXT_2, 26, 12, 92)
	var aviso := UiTema.rotulo(c, "", UiTema.COL_TEXT_2, 10, 31, 104)
	var parte := _botao_compra(c, UiTema.txt("shop_buy", "COMPRAR"), 43, "icon_money")
	var item := {"cartao": c, "efeito": efeito, "aviso": aviso, "pode": false, "tween": null}
	item.merge(parte)
	parte.botao.pressed.connect(_comprar_crew)
	parte.botao.mouse_entered.connect(func() -> void: _sobre("c"))
	parte.botao.mouse_exited.connect(func() -> void: _sobre(""))
	return item


# Metrônomo (Fase 4, dinheiro): ícone do nível à venda, nome do nível, X/3, "1 SOCO A CADA 2.0 S" e o botão com o preço.
# O efeito é largo (98 px), por isso fica embaixo do ícone, na largura toda do cartão.
func _montar_metronomo(y: float) -> Dictionary:
	var c := _cartao(_aba_loja, y, ALTURA_CARTAO_LOJA)
	var icone := UiTema.textura_rect(c, "icon_metronome_l1", 5, 4)
	var nome := UiTema.rotulo(c, "", UiTema.WHITE, 26, 3, 92)
	var nivel := UiTema.rotulo(c, "", UiTema.COL_TEXT_1, 26, 12)
	var efeito := UiTema.rotulo(c, "", UiTema.COL_TEXT_2, 10, 21, 104)
	var aviso := UiTema.rotulo(c, "", UiTema.COL_TEXT_2, 10, 31, 104)
	var parte := _botao_compra(c, UiTema.txt("shop_buy", "COMPRAR"), 43, "icon_money")
	var item := {"cartao": c, "icone_item": icone, "nome": nome, "nivel": nivel, "efeito": efeito, "aviso": aviso,
		"pode": false, "tween": null}
	item.merge(parte)
	parte.botao.pressed.connect(_comprar_metronomo)
	parte.botao.mouse_entered.connect(func() -> void: _sobre("m"))
	parte.botao.mouse_exited.connect(func() -> void: _sobre(""))
	return item


# --- Ações ---

func _comprar_metronomo() -> void:
	if GameState.comprar_metronomo():
		_piscar(_metro)
	atualizar()


func _comprar_crew() -> void:
	if GameState.comprar_crew_click():
		_piscar(_crew)
	atualizar()


func _comprar_gerador(id: String) -> void:
	if GameState.comprar_gerador(id):
		_piscar(_gens[id])
	atualizar()


func _comprar_melhoria(id: String) -> void:
	if GameState.comprar_melhoria(id):
		_piscar(_ups[id])
	atualizar()


## Comprar o aparelho: o cartão de compra dá lugar ao cartão de melhorias dele (que pisca). Num lugar só.
func _comprar_aparelho(id: String) -> void:
	if GameState.comprar_aparelho(id):
		atualizar()
		_piscar(_ups[id])
		return
	atualizar()


## Clique na marca do chão/parede ou no botão de foco trancado: abre a aba TREINO e o cartão de compra pisca 3 vezes.
func destacar_compra(id: String) -> void:
	_trocar_aba(ABA_TREINO)
	if _unl.has(id) and _unl[id].cartao.visible:
		_rolar_para(_unl[id].cartao)
		_piscar_unlock(_unl[id])


## Três piscadas da borda de papelão (ui_card_unlock <-> ui_card_unlock_flash a 6 fps, 1 s). `ao_fim` só repõe o normal.
func _piscar_unlock(item: Dictionary) -> void:
	var antigo = item.get("tween_estilo")
	if antigo is Tween and antigo.is_valid():
		antigo.kill()
	var normal := str(item.m.get("card", "ui_card_unlock"))
	var brilho := str(item.m.get("card_flash", "ui_card_unlock_flash"))
	var fundo: Panel = item.fundo
	var tw := (item.cartao as Control).create_tween()
	for i in 6:
		var aceso := i % 2 == 0
		tw.tween_callback(func() -> void: fundo.add_theme_stylebox_override("panel", UiTema.estilo(brilho if aceso else normal)))
		tw.tween_interval(1.0 / 6.0)
	tw.tween_callback(func() -> void: fundo.add_theme_stylebox_override("panel", UiTema.estilo(normal)))
	item.tween_estilo = tw


func _comprar_gerador_pago(id: String) -> void:
	if GameState.comprar_gerador_pago(id):
		_piscar(_pagos[id])
	atualizar()


func _comprar_luva() -> void:
	if GameState.comprar_luva():
		_piscar(_luva)
	atualizar()


func _sobre(chave: String) -> void:
	_hover = chave
	_emitir_info()


func _emitir_info() -> void:
	if _hover == "":
		info_mudou.emit({})
		return
	if _hover == "l":
		var l: Dictionary = GameState.proxima_luva()
		if l.is_empty():
			l = GameState.luva_equipada()
			info_mudou.emit({"titulo": l.get("name", ""), "texto": l.get("description", ""),
				"extra": str(GameState.dados.ui.get("maxed", "MÁXIMO"))})
		else:
			info_mudou.emit({"titulo": l.get("name", ""), "texto": l.get("description", ""),
				"extra": GameState.texto_efeito_loja(l)})
		return
	if _hover == "c":
		var cd: Dictionary = GameState.lutas.crew_click
		info_mudou.emit({"titulo": cd.get("name", ""), "texto": cd.get("description", ""),
			"extra": str(GameState.dados.ui.get("maxed", "MÁXIMO")) if GameState.crew_click_comprado else GameState.texto_efeito_crew_click()})
		return
	if _hover == "m":
		var def: Dictionary = GameState.proximo_metronomo()
		if def.is_empty():
			def = GameState.metronomo_atual()
			info_mudou.emit({"titulo": def.get("name", ""), "texto": def.get("description", ""),
				"extra": str(GameState.dados.ui.get("maxed", "MÁXIMO"))})
		else:
			var extra := GameState.texto_efeito_metronomo(def)
			if GameState.nivel_metronomo == 0 and GameState.assistido_disponivel():
				# O modo assistido é o "nível 0" do Metrônomo: mostra o que o jogador tem agora.
				extra += "\n" + UiTema.txt("shop_metronome_now", "", {"s": "%.1f" % GameState.assistido_intervalo()})
			info_mudou.emit({"titulo": def.get("name", ""), "texto": def.get("description", ""), "extra": extra})
		return
	var id := _hover.substr(2)
	if _hover.begins_with("p:"):
		var gp: Dictionary = GameState.lutas.gerador_pago(id)
		info_mudou.emit({"titulo": gp.get("name", id), "texto": gp.get("description", ""),
			"extra": GameState.texto_efeito_loja(gp)})
	elif _hover.begins_with("g:"):
		var g: Dictionary = GameState.dados.gerador(id)
		info_mudou.emit({"titulo": g.get("name", id), "texto": g.get("description", ""),
			"extra": "+%s/S CADA" % NumberFormat.fmt(float(g.get("production", 0.0)))})
	elif _hover.begins_with("a:") or not GameState.aparelho_montado(id):
		# Aparelho que ainda não chegou: nome, descrição e de onde ele vem.
		var u: Dictionary = GameState.desbloqueio(id)
		var extra := str(u.get("arrives_as", ""))
		var divisao := GameState.texto_divisao(id)
		if divisao != "":
			extra += "\n" + divisao  # aparelho da arte: como o treino se divide nos atributos
		info_mudou.emit({"titulo": GameState.dados.aparelho(id).get("name", id), "texto": u.get("description", ""),
			"extra": extra})
	else:
		var m: Dictionary = GameState.proxima_melhoria(id)
		if m.is_empty():
			var ap: Dictionary = GameState.dados.aparelho(id)
			# No máximo, mostra o aparelho do nível atual (última melhoria), não o do nível 0.
			var ups: Array = ap.get("upgrades", [])
			var atual: Dictionary = ups[ups.size() - 1] if not ups.is_empty() else {}
			info_mudou.emit({"titulo": atual.get("name", ap.get("name", id)), "texto": "", "extra": str(GameState.dados.ui.get("maxed", "MÁXIMO"))})
		else:
			info_mudou.emit({"titulo": m.get("name", ""), "texto": m.get("description", ""),
				"extra": GameState.texto_efeito_melhoria(m)})


# Pisca o cartão (compra feita ou item que acabou de ficar pagável).
func _piscar(item: Dictionary, forte: bool = true) -> void:
	var c: Control = item.cartao
	var antigo = item.get("tween")
	if antigo is Tween and antigo.is_valid():
		antigo.kill()
	c.modulate = Color(2.0, 2.0, 1.6) if forte else Color(1.5, 1.5, 1.3)
	var tw := c.create_tween()
	tw.tween_property(c, "modulate", Color.WHITE, 0.35)
	item.tween = tw


# --- Atualização (chamada em economia_mudou e a ~10 Hz) ---

func atualizar() -> void:
	var bloqueado := GameState.acoes_bloqueadas()
	for g in GameState.dados.geradores:
		var item: Dictionary = _gens[g.id]
		item.qtd.text = "X%d" % GameState.quantidade_gerador(g.id)
		item.prod.text = "+%s/S CADA" % NumberFormat.fmt(float(g.production) * (1.0 + GameState.bonus_ativos().passive_bonus))
		item.prod.position.x = 26.0 + UiTema.largura(item.qtd.text) + 6.0
		_preco(item, GameState.custo_gerador(g.id), GameState.pode_comprar_gerador(g.id) and not bloqueado)
	var existe_arte := false
	for ap in GameState.dados.todos_aparelhos():
		var item: Dictionary = _ups[ap.id]
		var estado := GameState.estado_aparelho(ap.id)
		var montado := estado == "owned"
		# "absent" (aparelho de outra arte, ou carreira sem arte): não existe aqui, nenhum dos dois cartões aparece.
		var existe := estado != "absent"
		existe_arte = existe_arte or (existe and str(ap.get("art", "")) != "")
		item.cartao.visible = montado
		if _unl.has(ap.id):
			_unl[ap.id].cartao.visible = existe and not montado
			if existe and not montado:
				_atualizar_unlock(ap, estado, bloqueado)
		if not montado:
			continue  # as melhorias dele só aparecem depois da compra
		var m: Dictionary = GameState.proxima_melhoria(ap.id)
		var total: int = ap.upgrades.size()
		var nivel := GameState.nivel_melhoria(ap.id)
		var tecnica: Dictionary = m if not m.is_empty() else ap.upgrades[total - 1]
		if item.tecnica != null:
			item.tecnica.text = str(tecnica.get("name", "")).to_upper()
			var icone_tecnica: Dictionary = UiTema.manifest().get("by_data_id", {}).get(str(tecnica.get("id", "")), {})
			if not icone_tecnica.is_empty() and not UiTema.sprite(str(icone_tecnica.get("icon", ""))).is_empty():
				item.icone_ap.texture = UiTema.textura(str(icone_tecnica.icon))
		if m.is_empty():
			item.nivel.text = "%d/%d" % [nivel, total]
			var efeito := {"id": ap.upgrades[total - 1].id, "multiplier": GameState.multiplicador_aparelho(ap.id)}
			item.efeito.text = _efeito_curto(item, GameState.texto_efeito_melhoria(efeito).to_upper())
			_maximo(item)
		else:
			item.nivel.text = "%d/%d" % [nivel, total]
			item.efeito.text = _efeito_curto(item, GameState.texto_efeito_melhoria(m).to_upper())
			_preco(item, float(m.cost), GameState.pode_comprar_melhoria(ap.id) and not bloqueado)
	_reposicionar_treino()
	_ajustar_rolagem(existe_arte)

	# LOJA (em dinheiro). Fase 5: entre o cinturão e a mudança, o que deixaria menos que o preço da mudança é recusado,
	# e o cartão diz o motivo (GUARDE $1.00K), nunca só o botão apagado.
	var reserva := GameState.reserva_mudanca() > 0.0
	_sub_loja.text = GameState.texto_reserva().to_upper() if reserva else UiTema.txt("shop_sub", "Dinheiro de luta, só aqui.")
	_sub_loja.add_theme_color_override("font_color", UiTema.COL_MONEY if reserva else UiTema.COL_TEXT_2)
	for g in GameState.lutas.geradores_pagos:
		var item: Dictionary = _pagos[g.id]
		var custo := GameState.custo_gerador_pago(g.id)
		var pode := GameState.pode_comprar_gerador_pago(g.id) and not bloqueado
		item.qtd.text = "X%d" % GameState.quantidade_gerador(g.id)
		_preco(item, custo, pode, true)
		item.aviso.text = _aviso_loja(custo, GameState.pode_comprar_gerador_pago(g.id))
	_atualizar_luva(bloqueado)
	_atualizar_metronomo(bloqueado)
	_atualizar_crew(bloqueado)
	_alerta_loja.visible = _loja_tem_compra() and _aba != ABA_LOJA
	_destacar_mais_barato()
	if _hover != "":
		_emitir_info()


## Cartão de técnica da arte: a linha do efeito perde o "...: PERA" (113 px não cabem em 92; o nome do aparelho está no ícone e no hover).
func _efeito_curto(item: Dictionary, texto: String) -> String:
	if item.tecnica != null and texto.contains(":"):
		return texto.get_slice(":", 0)
	return texto


## Aviso do cartão da LOJA: vazio (dá para comprar), a reserva da mudança (curto: cabe em 104 px) ou "Falta dinheiro".
func _aviso_loja(custo: float, pode: bool) -> String:
	if pode:
		return ""
	if GameState.loja_estado(custo) == "reserve":
		return GameState.texto_reserva(true).to_upper()
	return UiTema.txt("shop_no_money", "Falta dinheiro")


# --- Rolagem da aba TREINO (Fase 5) ---

## A altura do conteúdo cresce 1 cartão quando o aparelho da arte existe. Reajusta o limite e as setas.
func _ajustar_rolagem(existe_arte: bool) -> void:
	var altura := _altura_treino if _aba == ABA_TREINO else _altura_loja
	_rolagem_max = maxf(0.0, altura - ALTURA_JANELA + 2.0)
	_rolar_a(_rolagem)


func _rolar_a(valor: float) -> void:
	_rolagem = clampf(roundf(valor), 0.0, _rolagem_max)
	var conteudo := _aba_treino if _aba == ABA_TREINO else _aba_loja
	conteudo.position.y = -_rolagem
	_seta_cima.visible = _rolagem > 0.0
	_seta_baixo.visible = _rolagem < _rolagem_max


## Leva o cartão para dentro da janela (clique na marca de fita ou no botão de foco trancado).
func _rolar_para(cartao: Control) -> void:
	var topo := cartao.position.y
	var base := topo + cartao.size.y
	if topo - _rolagem < 0.0:
		_rolar_a(topo - 2.0)
	elif base - _rolagem > ALTURA_JANELA:
		_rolar_a(base - ALTURA_JANELA + 2.0)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or not event.pressed or _rolagem_max <= 0.0:
		return
	if event.button_index != MOUSE_BUTTON_WHEEL_UP and event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
		return
	if not Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position()):
		return
	_rolar_a(_rolagem + (-PASSO_ROLAGEM if event.button_index == MOUSE_BUTTON_WHEEL_UP else PASSO_ROLAGEM))
	get_viewport().set_input_as_handled()


## Cartão de compra: comprável (preço em destaque), sem Treino (apagado, sem vermelho), ou RECOLHIDO em 1 linha quando
## está trancado (depois do anterior) ou esperando na caixa. O detalhe dos recolhidos vem na dica de hover.
func _atualizar_unlock(ap: Dictionary, estado: String, bloqueado: bool) -> void:
	var item: Dictionary = _unl[ap.id]
	var m: Dictionary = item.m
	var recolher := estado == "locked" or estado == "boxed"
	_recolher(item, recolher)
	item.icone_item.texture = UiTema.textura(str(m.get("icon_locked_buyable" if estado == "buyable" else "icon_locked", "")))
	item.nome.add_theme_color_override("font_color", UiTema.COL_DISABLED if estado == "locked" else (UiTema.COL_TEXT_2 if recolher or estado == "missing" else UiTema.COL_TEXT_1))
	UiTema.escurecer(item.cartao, estado != "locked")
	if recolher:
		item.pode = false
		return
	var antes: bool = item.pode
	_preco(item, float(GameState.desbloqueio(ap.id).cost), estado == "buyable" and not bloqueado)
	if item.pode and not antes and not _primeira:
		_piscar_unlock(item)  # acabou de ficar comprável: borda de papelão pisca


## Recolhe/expande o cartão de compra do aparelho (1 linha só com o nome, ou o cartão inteiro).
func _recolher(item: Dictionary, recolher: bool) -> void:
	item.colapsado = recolher
	var h := 16.0 if recolher else ALTURA_CARTAO
	item.cartao.size.y = h
	item.fundo.size.y = h
	item.hover.size.y = h
	item.hover.mouse_filter = Control.MOUSE_FILTER_STOP if recolher else Control.MOUSE_FILTER_IGNORE
	item.icone_item.visible = not recolher
	item.atributo.visible = not recolher
	item.botao.visible = not recolher
	item.nome.position = Vector2(6, 4) if recolher else Vector2(26, 2)


## Dica do cartão recolhido: trancado = hint_locked_item (pede o anterior), na caixa = tape_boxed.
func _texto_recolhido(id: String) -> String:
	if GameState.estado_aparelho(id) == "boxed":
		return GameState.texto_ui("tape_boxed")
	var req := str(GameState.desbloqueio(id).get("requires", ""))
	var nome_req := GameState.nome_curto_aparelho(req).to_lower() if req != "" else ""
	return GameState.preencher(GameState.texto_ui("hint_locked_item"), {"requisito": nome_req})


## Empilha os cartões da aba TREINO na ordem do jogo: equipe, depois um cartão por aparelho (inteiro ou recolhido).
func _reposicionar_treino() -> void:
	var y := _y_melhorias + 12.0
	for ap in GameState.dados.todos_aparelhos():
		var estado := GameState.estado_aparelho(ap.id)
		var cartao: Control = null
		if estado == "owned":
			cartao = _ups[ap.id].cartao
		elif _unl.has(ap.id) and estado != "absent":
			cartao = _unl[ap.id].cartao
		if cartao == null:
			continue
		cartao.position.y = y
		y += cartao.size.y + 1.0
	_altura_treino = y


## O item comprável mais barato de cada aba ganha o contorno col_buyable (os outros, não).
func _destacar_mais_barato() -> void:
	var treino: Array = []
	treino.append_array(_gens.values())
	for id in _ups:
		if _ups[id].cartao.visible:
			treino.append(_ups[id])
	for id in _unl:
		if _unl[id].cartao.visible and not _unl[id].colapsado:
			treino.append(_unl[id])
	var loja: Array = _pagos.values()
	loja.append(_luva)
	loja.append(_metro)
	if not _crew.is_empty():
		loja.append(_crew)
	# Fase 5.2: um destaque só. O cartão de aparelho novo já tem a borda de papelão (laranja): quando ele está
	# comprável, é ele o destaque e o contorno do "mais barato" não aparece em mais nenhum cartão.
	var aparelho_novo := false
	for id in _unl:
		if _unl[id].cartao.visible and not _unl[id].colapsado and bool(_unl[id].pode):
			aparelho_novo = true
	for grupo in [treino, loja]:
		if grupo == treino and aparelho_novo:
			for it in grupo:
				it.destaque.visible = false
			continue
		var melhor: Dictionary = {}
		for it in grupo:
			it.destaque.visible = false
			if bool(it.pode) and (melhor.is_empty() or float(it.get("custo", INF)) < float(melhor.get("custo", INF))):
				melhor = it
		if not melhor.is_empty():
			melhor.destaque.visible = true


## Botão apagado com um texto centralizado (ex.: "DEPOIS DA ESTEIRA"): mesmo jeito do "MÁXIMO".
func _botao_texto_central(item: Dictionary, texto: String, cor: Color) -> void:
	item.botao.disabled = true
	item.icone.visible = false
	item.preco.visible = false
	item.esq.text = texto
	item.esq.add_theme_color_override("font_color", cor)
	item.esq.position.x = 0
	item.esq.size.x = 112
	item.esq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTema.alinhar(item.botao, "center")
	item.pode = false


func _atualizar_luva(bloqueado: bool) -> void:
	var prox: Dictionary = GameState.proxima_luva()
	var eq: Dictionary = GameState.luva_equipada()
	var item := _luva
	var total: int = GameState.lutas.luvas.size()
	_luva_atual_icone.texture = UiTema.textura(UiTema.icone_luva(str(eq.get("id", "glove_old"))))
	_luva_atual.text = str(eq.get("name", "")).to_upper()
	if prox.is_empty():
		item.icone_item.texture = UiTema.textura(UiTema.icone_luva(str(eq.get("id", ""))))
		item.nome.text = str(eq.get("name", "")).to_upper()
		item.nivel.text = "%d/%d" % [GameState.nivel_luva, total]
		item.efeito.text = GameState.texto_efeito_loja(eq).to_upper()
		item.aviso.text = ""
		_maximo(item)
		return
	item.icone_item.texture = UiTema.textura(UiTema.icone_luva(str(prox.id)))
	item.nome.text = str(prox.name).to_upper()
	item.nivel.text = "%d/%d" % [GameState.nivel_luva + 1, total]
	item.efeito.text = GameState.texto_efeito_loja(prox).to_upper()
	var pode := GameState.pode_comprar_luva()
	_preco(item, float(prox.cost), pode and not bloqueado, true)
	# Fase 5.1: a luva anterior ainda está na caixa: a próxima só abre a venda depois de abrir a caixa.
	item.aviso.text = GameState.texto_ui("shop_glove_boxed").to_upper() if GameState.luva_em_caixa() else _aviso_loja(float(prox.cost), pode)


func _atualizar_metronomo(bloqueado: bool) -> void:
	var prox: Dictionary = GameState.proximo_metronomo()
	var item := _metro
	var total: int = GameState.metronomo_niveis()
	var def: Dictionary = prox if not prox.is_empty() else GameState.metronomo_atual()
	var icone_nivel := clampi(int(def.get("level", total)), 1, 3)
	item.icone_item.texture = UiTema.textura("icon_metronome_l%d" % icone_nivel)
	item.nome.text = str(def.get("name", "")).to_upper()
	if prox.is_empty():
		item.nivel.text = "%d/%d" % [total, total]
		item.efeito.text = GameState.texto_efeito_metronomo(def).to_upper()
		item.aviso.text = ""
		_maximo(item)
		return
	item.nivel.text = "%d/%d" % [GameState.nivel_metronomo + 1, total]
	item.efeito.text = GameState.texto_efeito_metronomo(prox).to_upper()
	var pode := GameState.pode_comprar_metronomo()
	_preco(item, float(prox.cost), pode and not bloqueado, true)
	item.aviso.text = _aviso_loja(float(prox.cost), pode)


func _atualizar_crew(bloqueado: bool) -> void:
	if _crew.is_empty():
		return
	var item := _crew
	item.efeito.text = GameState.texto_efeito_crew_click().to_upper()
	if GameState.crew_click_comprado:
		item.aviso.text = ""
		_botao_texto_central(item, UiTema.txt("shop_crew_click_bought", "COMPRADO"), UiTema.GR3)
		return
	var custo := float(GameState.lutas.crew_click.cost)
	var pode := GameState.pode_comprar_crew_click()
	_preco(item, custo, pode and not bloqueado, true)
	item.aviso.text = _aviso_loja(custo, pode)


func _maximo(item: Dictionary) -> void:
	item.botao.disabled = true
	item.icone.visible = false
	item.preco.visible = false
	item.esq.text = str(GameState.dados.ui.get("maxed", "MÁXIMO")).to_upper()
	item.esq.add_theme_color_override("font_color", UiTema.GR3)
	item.esq.position.x = 0
	item.esq.size.x = 112
	item.esq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTema.alinhar(item.botao, "center")  # "MÁXIMO" ocupa o botão todo, centralizado
	item.pode = false


func _preco(item: Dictionary, custo: float, pode: bool, em_dinheiro: bool = false) -> void:
	# Em dinheiro o ícone ($) já diz a moeda; a loja mostra o preço exato (TRUNCAR não se aplica a custo).
	var texto := NumberFormat.fmt(custo)
	item.preco.text = texto
	var larg := UiTema.largura(texto)
	item.preco.position.x = 112.0 - 6.0 - larg
	item.icone.position.x = item.preco.position.x - 11.0
	item.icone.visible = true
	item.preco.visible = true
	item.esq.position.x = 6
	item.esq.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiTema.alinhar(item.botao, "left")
	item.esq.text = item.texto
	item.esq.reset_size()  # volta à largura do texto (o "MÁXIMO"/"DEPOIS DA..." centralizado alargou o rótulo)
	item.custo = custo
	item.preco.add_theme_color_override("font_color", (UiTema.COL_MONEY if em_dinheiro else UiTema.COL_TREINO) if pode else UiTema.COL_TEXT_2)
	item.esq.add_theme_color_override("font_color", UiTema.COL_TEXT_1 if pode else UiTema.COL_TEXT_2)
	item.botao.disabled = not pode
	if pode and not item.pode and not _primeira:
		_piscar(item, false)
	item.pode = pode


func _process(delta: float) -> void:
	_t += delta
	if _alerta_loja.visible:
		_alerta_loja.modulate.a = 0.4 + 0.6 * (0.5 + 0.5 * sin(_t * 6.0))


## Seta pequena (7x4 px) que avisa que a aba TREINO tem mais conteúdo para cima ou para baixo (roda do mouse).
class SetaRolagem extends Control:
	var _cima := false

	func _init(cima: bool) -> void:
		_cima = cima
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size = Vector2(9, 6)
		z_index = 5

	func _draw() -> void:
		var larguras: Array = [1, 3, 5, 7] if _cima else [7, 5, 3, 1]
		for i in 4:
			var w: int = larguras[i]
			draw_rect(Rect2(4 - w / 2 - 1, i, w + 2, 1), UiTema.INK)
		for i in 4:
			var w: int = larguras[i]
			draw_rect(Rect2(4 - w / 2, i, w, 1), UiTema.Y1)
