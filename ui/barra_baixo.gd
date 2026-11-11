class_name BarraBaixo
extends Control
## Barra de baixo: "por clique" e "auto /s", os 3 botões de foco, a dica de primeira vez e,
## à direita, os botões LUTAR! (vermelho = arriscar) e APOSENTAR (roxo = Legado).
## Os botões só pedem a ação (sinais): quem abre a prévia/confirmação é o Fluxo.

signal lutar_pedido
signal aposentar_pedido
signal compra_pedida(aparelho: String)  # clique no botão de foco trancado: a garagem abre a aba TREINO

const LARG_BOTAO := 122.0  # 3 botões de foco
const PASSO_BOTAO := 128.0
const LARG_BOTAO_4 := 90.0  # 4 botões de foco (Fase 5, com o aparelho da arte): largura 90, passo 94 (x 134, 228, 322, 416)
const PASSO_BOTAO_4 := 94.0
const X0 := 134.0
const X_CHIP := 506.0  # borda direita do chip da arte (alinhado à direita da área dos botões de foco)
const ABREVIACOES := {"RESISTÊNCIA": "RESIST."}  # só no botão estreito: "RESISTÊNCIA" tem 65 px e o texto cabe em 54

var _por_clique: Label
var _auto: Label
var _dica: Label
var _dica_espaco: Label
var _salvo: Label
var _botoes: Dictionary = {}  # aparelho -> {botao, sublinhado, estilo}
var _ids_botoes := ""  # aparelhos da carreira que têm botão agora (refaz os botões se a lista mudar)
var _larg := LARG_BOTAO
var _passo := PASSO_BOTAO
var _f11: Label
var _chip: Control  # Fase 5: HUD da arte
var _chip_fundo: NinePatchRect
var _chip_icone: TextureRect
var _chip_texto: Label
var _chip_chave := ""
var _dica_aposentar := false  # a dica da academia está no ar: APOSENTAR "respira" em roxo
var _t_poll := 0.0
var _lutar: Button
var _aposentar: Button
var _dica_ativa := false
var _janela_aberta := false
var _t := 0.0
var _ultimo := ""
var _pulso_foco := false


func _ready() -> void:
	position = Vector2(0, 290)
	size = Vector2(640, 70)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui: Dictionary = GameState.dados.ui
	UiTema.painel(self, "ui_panel", Rect2(0, 0, 640, 70))

	UiTema.rotulo(self, str(ui.get("per_click", "POR CLIQUE")).to_upper(), UiTema.G2, 8, 8)
	_por_clique = UiTema.rotulo(self, "+1", UiTema.Y1, 8, 22)
	_por_clique.scale = Vector2(2, 2)
	_auto = UiTema.rotulo(self, "", UiTema.GR3, 8, 44)
	_salvo = UiTema.rotulo(self, "", UiTema.G1, 8, 56, 118)

	UiTema.rotulo(self, str(ui.get("focus_label", "FOCO DE TREINO")).to_upper(), UiTema.G2, X0 + 2, 3)
	_f11 = UiTema.rotulo(self, str(ui.get("fullscreen_hint", "F11 TELA CHEIA")).to_upper(), UiTema.G1, X0, 3, 372, HORIZONTAL_ALIGNMENT_RIGHT)
	_montar_chip()
	_reconstruir_botoes()

	_dica = UiTema.rotulo(self, "", UiTema.Y1, X0, 56, 378, HORIZONTAL_ALIGNMENT_CENTER)
	# Lembrete fixo (some enquanto a dica da primeira vez pisca no mesmo lugar): Espaço treina como o clique.
	_dica_espaco = UiTema.rotulo(self, UiTema.txt("space_hint", "ESPAÇO OU CLIQUE PARA TREINAR"), UiTema.G1, X0, 56, 378,
		HORIZONTAL_ALIGNMENT_CENTER)
	_montar_lutar()
	_montar_aposentar()

	GameState.clicou.connect(func(_g: float, _c: bool, _a: String, _b: String, _t2: String) -> void: _dica_ativa = false)
	GameState.salvo.connect(func(h: String) -> void: _salvo.text = str(GameState.dados.ui.get("saved_footer", "SALVO {hora}")).to_upper().replace("{HORA}", h))
	GameState.carreira_mudou.connect(_checar_dica)
	GameState.arte_mudou.connect(func(_a: String) -> void: atualizar())
	_checar_dica()
	atualizar()


## Refaz os botões de foco quando a lista de aparelhos da carreira muda (escolha da arte, NOVA CARREIRA): 3 botões de 122 px,
## ou 4 de 90 px com o aparelho da arte.
func _reconstruir_botoes() -> void:
	var lista: Array = GameState.aparelhos_da_carreira()
	var ids: Array = lista.map(func(a: Dictionary) -> String: return str(a.id))
	var chave := ",".join(ids)
	if chave == _ids_botoes:
		return
	_ids_botoes = chave
	for id in _botoes:
		_botoes[id].botao.queue_free()
		_botoes[id].sub.queue_free()
	_botoes.clear()
	_larg = LARG_BOTAO_4 if lista.size() > 3 else LARG_BOTAO
	_passo = PASSO_BOTAO_4 if lista.size() > 3 else PASSO_BOTAO
	var i := 0
	for ap in lista:
		_botoes[ap.id] = _montar_botao(ap, i)
		i += 1
	_ultimo = ""


## Texto de uma linha do botão que cabe em `max` px: o texto inteiro, a abreviação conhecida ou cortado com ponto.
func _cabe(texto: String, max_: float) -> String:
	if UiTema.largura_visivel(texto) <= max_:
		return texto
	if ABREVIACOES.has(texto):
		return ABREVIACOES[texto]
	var t := texto
	while t.length() > 1 and UiTema.largura_visivel(t + ".") > max_:
		t = t.left(t.length() - 1)
	return t + "."


func _montar_botao(ap: Dictionary, i: int) -> Dictionary:
	var x := X0 + i * _passo
	var estreito := _larg < LARG_BOTAO
	var largura_texto := _larg - 36.0  # 20 px de ícone + 16 px do número da tecla
	var b := UiTema.botao(self, Rect2(x, 14, _larg, 34))
	UiTema.alinhar(b, "left")  # conteudo a esquerda (icone, duas linhas, numero da tecla): so confere o eixo vertical
	var cor := UiTema.P2 if str(ap.get("art", "")) != "" else UiTema.cor_atributo(ap.attribute)  # arte marcial = roxo
	var dono: Array = []  # conteúdo do botão montado (aparelho comprado)
	# Aparelho da arte: ícone da arte (art_boxing_9 / art_bjj_9) no lugar do ícone do atributo (ele treina os três).
	var arte_ap := str(ap.get("art", ""))
	var icone_foco := "art_%s_9" % arte_ap if arte_ap != "" else "icon_" + str(ap.attribute)
	if UiTema.sprite(icone_foco).is_empty():
		icone_foco = "icon_" + str(ap.attribute)
	dono.append(UiTema.textura_rect(b, icone_foco, 7, 11))
	var linhas: Array = ap.get("focus_label", ["", ""])
	dono.append(UiTema.rotulo(b, _cabe(str(linhas[0]).to_upper(), largura_texto), UiTema.WHITE, 20, 4))
	dono.append(UiTema.rotulo(b, _cabe(str(linhas[1]).to_upper(), largura_texto), UiTema.G3, 20, 15))
	dono.append(UiTema.rotulo(b, str(i + 1), UiTema.G1, _larg - 14, 4, 8, HORIZONTAL_ALIGNMENT_RIGHT))
	# Fase 4b, aparelho que ainda não chegou: cadeado 16x16 no lugar do ícone do atributo, nome, preço (ícone de
	# Treino + número) ou "DEPOIS DA ESTEIRA". Sem número de tecla (o teclado pula os trancados) e sem sublinhado.
	var trancado: Dictionary = {}
	var u: Dictionary = GameState.desbloqueio(str(ap.id))
	if not u.is_empty():
		var m: Dictionary = UiTema.manifest().get("by_data_id", {}).get(str(u.get("id", "")), {})
		trancado = {
			"m": m,
			"cadeado": UiTema.textura_rect(b, str(m.get("icon_locked", "icon_treadmill_locked")), 2, 9),
			"nome": UiTema.rotulo(b, GameState.nome_curto_aparelho(str(ap.id)).to_upper(), UiTema.WHITE, 20, 4),
			"moeda": UiTema.textura_rect(b, "icon_treino", 20, 16),
			"preco": UiTema.rotulo(b, "", UiTema.Y1, 32, 15),
			"depois": UiTema.rotulo(b, "", UiTema.G1, 20, 15),
			"estreito": estreito,
		}
		if estreito:
			# Botão de 90 px: "DEPOIS DA ESTEIRA" (101 px) quebra em duas linhas abaixo do nome (que sobe um pouco).
			var depois: Label = trancado["depois"]
			depois.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			depois.custom_minimum_size = Vector2(_larg - 24.0, 0)
			depois.size = Vector2(_larg - 24.0, 18)
			depois.position = Vector2(20, 11)
			trancado["nome"].position = Vector2(20, 2)
		for k in trancado:
			if trancado[k] is Control:
				UiTema.alinhar(trancado[k], "left")  # colado à esquerda do botão, como o conteúdo dos outros botões de foco
	var sub := ColorRect.new()
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.color = cor
	sub.position = Vector2(x + 3, 50)
	sub.size = Vector2(_larg - 6, 2)
	add_child(sub)
	var id: String = ap.id
	b.pressed.connect(func() -> void:
		if GameState.aparelho_montado(id):
			GameState.definir_foco(id)
			atualizar()
		else:
			compra_pedida.emit(id)  # trancado: não troca o foco, só aponta a compra na aba TREINO
	)
	return {"botao": b, "sub": sub, "estilo": "ui_button_normal", "dono": dono, "trancado": trancado, "id": id}


## Chip da arte (Fase 5): ícone da arte + "BOXE: +50% NO SEU CLIQUE" / "JIU-JITSU: EQUIPE +48%". Alinhado à direita em x 506,
## sobre a linha do "FOCO DE TREINO" (no lugar do aviso F11, que some enquanto o chip está na tela). Some sem arte.
func _montar_chip() -> void:
	_chip = Control.new()
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.position = Vector2(X_CHIP - 40.0, -1)  # y 289 da tela: encosta na borda de cima da barra
	_chip.size = Vector2(40, 13)
	_chip.visible = false
	_chip.set_meta("ui_margens", "h")
	add_child(_chip)
	_chip_fundo = UiTema.nine_patch(_chip, "ui_art_chip", Rect2(0, 0, 40, 13))
	_chip_icone = UiTema.textura_rect(_chip, "art_boxing_9", 3, 2)
	_chip_texto = UiTema.rotulo(_chip, "", UiTema.P2, 15, 3)
	UiTema.alinhar(_chip, "right")


func _atualizar_chip() -> void:
	var texto := GameState.texto_hud_arte().to_upper()
	var max_ := GameState.arte_no_teto()
	var chave := "%s|%s|%s" % [GameState.arte_id, texto, max_]
	if chave == _chip_chave:
		return
	_chip_chave = chave
	_chip.visible = texto != ""
	_f11.visible = texto == ""
	if texto == "":
		return
	_chip_texto.text = texto
	_chip_texto.add_theme_color_override("font_color", UiTema.Y1 if max_ else UiTema.P2)
	_chip_icone.texture = UiTema.textura("art_%s_9" % GameState.arte_id)
	var w := roundf(UiTema.largura_visivel(texto)) + 18.0  # 3 de folga + 9 do ícone + 3 + texto + 3 de folga (margens iguais)
	_chip.size = Vector2(w, 13)
	_chip_fundo.size = Vector2(w, 13)
	_chip.position = Vector2(X_CHIP - w, -1)


## Linha de baixo do botão de foco: com o aparelho da arte em foco mostra a divisão do treino ("FOR 40% / AGI 45% / RES 15%");
## com os outros, o lembrete do Espaço.
func _atualizar_dica_foco() -> void:
	var divisao := GameState.texto_divisao(GameState.foco).to_upper()
	if divisao != "":
		_dica_espaco.text = divisao
		_dica_espaco.add_theme_color_override("font_color", UiTema.P2)
	else:
		_dica_espaco.text = UiTema.txt("space_hint", "ESPAÇO OU CLIQUE PARA TREINAR")
		_dica_espaco.add_theme_color_override("font_color", UiTema.G1)


func _montar_lutar() -> void:
	_lutar = UiTema.botao_estilizado(self, Rect2(520, 5, 112, 34), "ui_button_fight")
	UiTema.botao_conteudo(_lutar, UiTema.txt("fight_button", "LUTAR!"), UiTema.Y2, 2, "icon_fight", 4.0)
	_lutar.pressed.connect(func() -> void: lutar_pedido.emit())


func _montar_aposentar() -> void:
	_aposentar = UiTema.botao_estilizado(self, Rect2(520, 43, 112, 22), "ui_button_retire")
	UiTema.botao_conteudo(_aposentar, UiTema.txt("retire_button", "APOSENTAR"), UiTema.P2, 1, "icon_retire", 3.0)
	_aposentar.pressed.connect(func() -> void: aposentar_pedido.emit())


func _checar_dica() -> void:
	var soma := 0.0
	for id in GameState.atributos:
		soma += float(GameState.atributos[id])
	_dica_ativa = soma <= 0.0


## Para o garçom da sala (seta que aponta o alvo).
func dica_ativa() -> bool:
	return _dica_ativa


## O Fluxo avisa quando uma janela (prévia, confirmação, vitória...) está aberta por cima.
func definir_janela_aberta(aberta: bool) -> void:
	_janela_aberta = aberta
	atualizar()


func atualizar() -> void:
	_reconstruir_botoes()
	_atualizar_chip()
	# LUTAR! e APOSENTAR só entre lutas: desabilitados durante a luta, com a tela de fim e depois do cinturão.
	var pode_lutar := GameState.pode_lutar() and not _janela_aberta
	var pode_aposentar := GameState.pode_aposentar() and not _janela_aberta
	_lutar.disabled = not pode_lutar
	_aposentar.disabled = not pode_aposentar
	UiTema.escurecer(_aposentar, pode_aposentar)
	if not pode_lutar:
		_lutar.modulate = Color(0.62, 0.6, 0.66)

	var foco := GameState.foco
	var texto_auto := "%s +%s/S" % [str(GameState.dados.ui.get("auto", "AUTO")).to_upper(),
		NumberFormat.fmt(GameState.producao_total())]
	var estados := ""
	for id in _botoes:
		estados += GameState.estado_aparelho(id).left(1)  # o(wned) b(uyable) m(issing) l(ocked)
	var chave := "%s|%s|%s|%s" % [NumberFormat.fmt(GameState.por_clique()), texto_auto, foco, estados]
	if chave != _ultimo:
		_ultimo = chave
		_por_clique.text = "+%s" % NumberFormat.fmt(GameState.por_clique())
		_por_clique.add_theme_color_override("font_color",
			UiTema.cor_atributo(GameState.atributo_do_aparelho(foco)).lerp(UiTema.WHITE, 0.3))
		_auto.text = texto_auto
		for id in _botoes:
			_aplicar_botao(_botoes[id], foco)
	_atualizar_dica_foco()


## Botão de foco do aparelho: normal (montado) ou trancado (comprável / sem Treino / depois do anterior).
func _aplicar_botao(d: Dictionary, foco: String) -> void:
	var id: String = d.id
	var estado := GameState.estado_aparelho(id)
	var montado := estado == "owned"
	for n in d.dono:
		n.visible = montado
	var tr: Dictionary = d.trancado
	for k in ["cadeado", "nome", "moeda", "preco", "depois"]:
		if tr.has(k):
			tr[k].visible = not montado and (k in ["cadeado", "nome"] or (k == "depois") == (estado == "locked"))
	if montado or tr.is_empty():
		var ativo: bool = id == foco
		var atributo := GameState.atributo_do_aparelho(id)
		var estilo := "ui_button_focus_" + atributo if ativo else "ui_button_normal"
		if ativo and str(GameState.dados.aparelho(id).get("art", "")) != "":
			estilo = "ui_button_focus_art"  # aparelho da arte: botão roxo (treina os 3 atributos)
		if estilo != d.estilo:
			d.estilo = estilo
			UiTema.aplicar_estilo_botao(d.botao, estilo)
		d.sub.visible = ativo
		return
	d.sub.visible = false
	var m: Dictionary = tr.m
	var t: Dictionary = GameState.textos_trancado(id)
	var cor_nome := UiTema.WHITE if estado == "buyable" else (UiTema.G3 if estado == "missing" else UiTema.G1)
	tr.nome.add_theme_color_override("font_color", cor_nome)
	if bool(tr.get("estreito", false)):
		tr.nome.position.y = 2.0 if estado == "locked" else 4.0  # trancado: o nome sobe para caber "DEPOIS DA / ESTEIRA" embaixo
	tr.cadeado.texture = UiTema.textura(str(m.get("icon_locked_buyable" if estado == "buyable" else "icon_locked", "")))
	var texto := str(t.get("focus_locked", "")).to_upper()
	if estado == "locked":
		tr.depois.text = texto
	else:
		tr.preco.text = texto
		tr.preco.add_theme_color_override("font_color", UiTema.Y1 if estado == "buyable" else UiTema.R2)
	_estilo_trancado(d, estado, false)


## Moldura do botão trancado. O comprável alterna com o quadro de pulso (3 fps) para chamar a atenção.
func _estilo_trancado(d: Dictionary, estado: String, pulso: bool) -> void:
	var m: Dictionary = d.trancado.m
	var fotos: Dictionary = m.get("focus_button", {})
	var chave_estilo := "buyable_pulse" if estado == "buyable" and pulso else estado
	var estilo := str(fotos.get(chave_estilo, "ui_button_focus_locked_" + chave_estilo))
	if estilo == d.estilo:
		return
	d.estilo = estilo
	UiTema.aplicar_estilo_botao(d.botao, estilo)
	d.botao.add_theme_stylebox_override("pressed", UiTema.estilo(estilo))  # clicar não "afunda": não treina nem troca foco


func _process(delta: float) -> void:
	_t += delta
	var ap := GameState.dados.aparelho(GameState.foco)
	_dica.visible = _dica_ativa
	_dica_espaco.visible = not _dica_ativa
	# O HUD da arte do Jiu-jitsu sobe com o tempo (1 leitura por segundo) e a dica de aposentar da academia depende de relógio.
	_t_poll += delta
	if _t_poll >= 1.0:
		_t_poll = 0.0
		_atualizar_chip()
		_dica_aposentar = bool(GameState.dica_aposentar().get("show", false))
	if _dica_aposentar and not _aposentar.disabled:
		_aposentar.modulate = Color.WHITE.lerp(Color(1.3, 1.15, 1.45), 0.5 + 0.5 * sin(_t * 4.0))  # APOSENTAR respira em roxo
	if _dica_ativa:
		_dica.text = str(ap.get("first_hint", "")).to_upper()
		_dica.modulate.a = 0.65 + 0.35 * (0.5 + 0.5 * sin(_t * 5.0))
	# Botões de foco prontos para comprar piscam a borda (verde / verde claro, 3 fps).
	var pulso := int(_t * 3.0) % 2 == 1
	if pulso != _pulso_foco:
		_pulso_foco = pulso
		for id in _botoes:
			var d: Dictionary = _botoes[id]
			if not d.trancado.is_empty() and GameState.estado_aparelho(id) == "buyable":
				_estilo_trancado(d, "buyable", pulso)
	# LUTAR! "respira" de leve quando está disponível (convite sem gritar).
	if not _lutar.disabled:
		var k := 0.5 + 0.5 * sin(_t * 3.0)
		_lutar.modulate = Color.WHITE.lerp(Color(1.18, 1.1, 1.1), k)
