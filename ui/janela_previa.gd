class_name JanelaPrevia
extends JanelaBase
## Prévia ELE x VOCÊ: retratos, atributos lado a lado (o que ele tem de sobra em destaque), selo de risco
## (verde/amarelo/vermelho, sempre com ícone), 3 táticas (o risco recalcula ao trocar), o que está em jogo e
## os botões VOLTAR A TREINAR e LUTAR!. Não muda nada no jogo, a não ser a "última tática" (restaurada ao voltar).
## Na 1ª prévia da 1ª carreira o amarelo/vermelho ganha um aviso ("amarelo = pode perder").

signal lutar_pedido
signal voltar_pedido
signal passar_pedido  # só na prévia do dia (Fase 5.3): PASSAR O POSTO

const X0 := 164.0
const X1 := 476.0
const ATRIBUTOS := ["strength", "agility", "endurance"]

var tatica_original := ""
var _dados: Dictionary = {}
var _tatica := ""
var _selo_area: Control
var _selo: Control
var _selo_rotulo := ""
var _rotulo_tatica: Dictionary = {}  # tática -> {botao, sub}
var _dica: Label
var _aviso: Label
var _percent: Label
var _t := 0.0
var dia_da_luta := false  # Fase 5.3: prévia do dia (sem VOLTAR A TREINAR, sem X, sem Esc; com LUTAR e PASSAR O POSTO)


func abrir_com(dados: Dictionary, do_dia: bool = false) -> void:
	dia_da_luta = do_dia
	_dados = dados
	tatica_original = str(dados.tactic)
	_tatica = tatica_original
	_montar()
	_escolher(_tatica, false)
	animar_entrada()


func _montar() -> void:
	var opp: Dictionary = _dados.opponent
	var ids: Dictionary = UiTema.manifest().get("by_data_id", {})
	var info_opp: Dictionary = ids.get(str(opp.id), {})

	# Revanche (Fase 4): a fita "VOCÊ PERDEU PRA ELE" ganha 17 px de altura; a janela cresce junto (8 px para cima, 9 para baixo).
	# Fase 5: com arte, a linha do traço de luta ("BOXE: +10% DE DANO") ganha 11 px; a janela cresce metade para cada lado.
	var revanche := bool(_dados.get("revenge", false))
	var traco := str(_dados.get("art_fight_text", ""))
	var ex := (17.0 if revanche else 0.0) + (11.0 if traco != "" else 0.0)
	var oy := -floorf(ex / 2.0)
	# Fase 5.1: a janela ganha até 10 px de altura (metade para cada lado) para os blocos respirarem; com a fita da
	# revanche e a linha da arte juntas, o respiro encolhe para a janela caber na tela (358 px).
	var folga := int(clampf(30.0 - ex, 0.0, 10.0))
	if dia_da_luta:
		folga = 0  # a folhinha do dia pede o topo da janela livre (não cobre o retrato): layout compacto
	var topo := floorf(float(folga) / 2.0)
	var g1 := floorf(float(folga) * 0.2)  # quem é quem -> atributos
	var g2 := floorf(float(folga) * 0.3)  # atributos -> risco
	var g3 := floorf(float(folga) * 0.2)  # risco -> táticas
	var g4 := floorf(float(folga) * 0.3)  # dica da tática -> o que está em jogo
	moldura("ui_window", Rect2(152, 16 + oy - topo, 336, 328 + ex + folga))
	var titulo := UiTema.txt("fight_day_title", "DIA DA LUTA") if dia_da_luta else UiTema.txt("preview_title", "PRÓXIMA LUTA")
	faixa_titulo("neutral", Rect2(158, 22 + oy - topo, 324, 17), titulo)
	if dia_da_luta:
		_folhinha_do_dia(152.0, 16.0 + oy - topo)

	# --- Retratos: ELE à esquerda, VOCÊ à direita (espelhado, olha para ele) ---
	var y := 46.0 + oy - topo
	retrato(str(info_opp.get("portrait", "")), str(info_opp.get("portrait_frame", "ui_portrait_frame")), X0, y, false)
	UiTema.rotulo(painel, UiTema.txt("preview_him", "ELE"), UiTema.G2, X0 + 42, y + 2)
	UiTema.rotulo(painel, str(opp.name).to_upper(), UiTema.WHITE, X0 + 42, y + 13)
	UiTema.rotulo(painel, str(opp.profile).to_upper(), UiTema.cor_nome(str(info_opp.get("color", "g3"))), X0 + 42, y + 24)

	var vs := UiTema.textura_rect(painel, "ui_vs_badge", 304, y + 6)
	vs.pivot_offset = Vector2(16, 12)

	retrato(UiTema.nome_retrato_jogador(), "ui_portrait_frame", X1 - 36, y, true)
	var dir := X1 - 42
	_rotulo_dir(UiTema.txt("preview_you", "VOCÊ"), UiTema.G2, dir, y + 2)
	_rotulo_dir(UiTema.txt("hud_career", "CARREIRA {n}", {"n": GameState.numero_carreira()}), UiTema.WHITE, dir, y + 13)
	_rotulo_dir(UiTema.singular("%d %s" % [GameState.indice_escada, UiTema.txt("sum_wins", "VITÓRIAS")]), UiTema.G3, dir, y + 24)

	if revanche:
		_fita_revanche(y + 40.0)
		y += 17.0

	# Respiro: a regra do tempo (2 linhas) só aparece na 1ª luta da carreira; nas outras, esse espaço vira ar entre as seções.
	var regra := GameState.indice_escada == 0
	var ar := 0.0 if regra else 1.0
	# Descrição dele
	y += 42.0
	if dia_da_luta:
		# No dia, a linha de baixo dos retratos diz o que fazer ("{nome} chegou. Lutar ou passar o posto?"); a descrição fica na LUTAR.
		UiTema.rotulo_centro(painel, UiTema.txt("fight_day_line", "{nome} chegou. Lutar ou passar o posto?",
			{"nome": str(opp.name)}), UiTema.Y1, 320.0, y)
	else:
		UiTema.rotulo_centro(painel, str(opp.description).to_upper(), UiTema.CREAM, 320.0, y)

	# --- Atributos lado a lado ---
	y += 13.0 + g1 + 2.0 * ar  # respiro entre quem é quem e os atributos
	for atr in ATRIBUTOS:
		_linha_atributo(atr, y)
		y += 16.0 + ar
	y += 1.0
	var lead := str(_dados.lead)
	if lead != "":
		UiTema.rotulo_centro(painel, UiTema.txt("lead_" + lead), UiTema.R3, 320.0, y)
	y += 12.0 + g2 + 2.0 * ar  # respiro antes do risco

	# --- Risco ---
	UiTema.rotulo(painel, UiTema.txt("risk_label", "RISCO"), UiTema.G3, X0, y + 3)
	_selo_area = Control.new()
	_selo_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selo_area.position = Vector2(X0 + UiTema.largura(UiTema.txt("risk_label")) + 8, y)
	painel.add_child(_selo_area)
	_aviso = UiTema.rotulo(painel, "", UiTema.Y1, X0 + 130, y + 3, X1 - X0 - 130, HORIZONTAL_ALIGNMENT_RIGHT)
	# Porcentagem de vitória (só com o nó "Olho clínico"): ao lado do selo, na cor do risco.
	_percent = UiTema.rotulo(painel, "", UiTema.WHITE, X0, y + 3)
	_percent.visible = false
	y += 19.0 + g3 + 2.0 * ar  # respiro antes das táticas

	# --- Táticas ---
	UiTema.rotulo(painel, UiTema.txt("tactic_label", "TÁTICA"), UiTema.G3, X0, y)
	y += 10.0 + ar
	var x := X0
	for t in GameState.lutas.taticas:
		_montar_tatica(t, x, y)
		x += 107.0
	y += 22.0 + 2.0 + 13.0 + 4.0  # 4 px de respiro entre a linha de risco e a dica
	_dica = UiTema.rotulo(painel, "", UiTema.G3, X0, y, X1 - X0, HORIZONTAL_ALIGNMENT_CENTER)
	y += 14.0 + g4 + 2.0 * ar  # respiro antes do que está em jogo
	if traco != "":
		_linha_traco(str(_dados.get("art", "")), traco, y)
		y += 11.0

	# --- Em jogo ---
	divisor(X0, y, X1 - X0)
	y += 5.0 + 2.0 * ar
	if bool(_dados.stake_belt):
		linha_icone("icon_belt_amateur_9", UiTema.txt("stake_belt", "SE VENCER: O CINTURÃO AMADOR"), UiTema.Y1, X0, y)
	else:
		linha_icone("icon_money", str(_dados.stake_win).to_upper(), UiTema.Y1, X0, y)
	y += 13.0
	# O texto vem pronto do GameState: "METADE DO LEGADO" ou o percentual real (com o nó "Saber cair").
	linha_icone("icon_legacy", str(_dados.get("stake_lose", UiTema.txt("stake_lose"))).to_upper(), UiTema.R3, X0, y)
	y += 15.0
	if regra:
		UiTema.rotulo_centro(painel, UiTema.txt("time_rule", "SEM K.O. NO TEMPO: VENCE QUEM TEM MAIS VIDA"), UiTema.G2, 320.0, y)
		y += 9.0
		UiTema.rotulo_centro(painel, UiTema.txt("time_rule_tie", "EMPATE EXATO: FICA COM ELE"), UiTema.G2, 320.0, y)

	# --- Botões ---
	# Dois botões do mesmo tamanho, com 4 px entre eles, ocupando a largura útil da janela.
	var yb := 310.0 + ex + oy + float(folga) - topo
	if dia_da_luta:
		# Prévia do dia: PASSAR O POSTO (contorno roxo, menos peso) e LUTAR! (vermelho cheio), 12 px entre eles para não
		# apertar um pelo outro. Sem botão de voltar.
		var larg_dia := (X1 - X0 - 12.0) / 2.0
		var passar := UiTema.botao_estilizado(painel, Rect2(X0, yb, larg_dia, 26), "ui_button_pass")
		UiTema.botao_conteudo(passar, UiTema.txt("fight_day_pass", "PASSAR O POSTO"), UiTema.P2, 1, "icon_pass_post", 4.0)
		passar.pressed.connect(func() -> void: passar_pedido.emit())
		var lutar_dia := botao_texto(Rect2(X0 + larg_dia + 12.0, yb, larg_dia, 26), UiTema.txt("fight_day_fight", "LUTAR") + "!",
			UiTema.Y2, "", 2, "ui_button_fight")
		lutar_dia.pressed.connect(func() -> void: lutar_pedido.emit())
		return
	var larg_botao := (X1 - X0 - 4.0) / 2.0
	var voltar := botao_texto(Rect2(X0, yb, larg_botao, 26), UiTema.txt("back_button", "VOLTAR A TREINAR"))
	voltar.pressed.connect(func() -> void: voltar_pedido.emit())
	var lutar := botao_texto(Rect2(X0 + larg_botao + 4.0, yb, larg_botao, 26), UiTema.txt("fight_button", "LUTAR!"),
		UiTema.Y2, "", 2, "ui_button_fight")
	lutar.pressed.connect(func() -> void: lutar_pedido.emit())


## Folhinha grande do dia ("HOJE" + número do dia em 2x), presa no canto de cima à esquerda da janela por cima da borda
## (offset -34,-12 da moldura; no máximo até o topo da tela).
func _folhinha_do_dia(x_janela: float, y_janela: float) -> void:
	# Fica pendurada no canto: 34 px para a esquerda da borda (6 px da folhinha sobre a moldura), assim o canto direito dela
	# (x 158) nunca chega no retrato (x 164), mesmo com a janela subida pela fita da revanche + linha da arte.
	var f := UiTema.textura_rect(painel, "ui_day_badge", x_janela - 34.0, maxf(0.0, y_janela - 12.0))
	var cab := UiTema.rotulo_centrado(f, Rect2(1, 5, 37, 7), UiTema.txt("day_badge_header", "HOJE"), UiTema.WHITE, 1, false, "center_h")
	cab.name = "Cabecalho"
	var num := UiTema.rotulo_centrado(f, Rect2(5, 18, 29, 14), str(mini(GameState.dia_campanha(), 99)), UiTema.D1, 2, false, "center_h")
	num.name = "Numero"
	num.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))  # sem sombra: o número vai sobre papel claro


## Fita vermelha "VOCÊ PERDEU PRA ELE" (esparadrapo em X + texto), centralizada na janela.
func _fita_revanche(y: float) -> void:
	var texto := UiTema.txt("revenge_mark", "VOCÊ PERDEU PRA ELE")
	var ic := UiTema.tamanho_quadro("icon_revenge")
	var area0 := UiTema.area_nove("ui_seal_revenge", Vector2(100, 15))
	var grupo := ic.x + 4.0 + UiTema.largura_visivel(texto)
	var w := roundf(grupo + area0.position.x * 2.0)
	if int(w) % 2 != 0:
		w += 1.0  # largura par: a fita fica no meio exato da janela (320)
	var fita := UiTema.nine_patch(painel, "ui_seal_revenge", Rect2(320.0 - w / 2.0, y, w, 15))
	fita.set_meta("ui_pos", "center_h")
	var area := UiTema.area_nove("ui_seal_revenge", Vector2(w, 15))
	var gx := roundf(area.position.x + (area.size.x - grupo) / 2.0)
	UiTema.textura_rect(fita, "icon_revenge", gx, UiTema.y_imagem(area, ic.y))
	UiTema.rotulo(fita, texto, UiTema.CREAM, gx + ic.x + 4.0, UiTema.y_texto(area))


func _rotulo_dir(texto: String, cor: Color, x_fim: float, y: float) -> void:
	var l := UiTema.rotulo(painel, texto, cor, 0, y)
	l.position.x = roundf(x_fim - UiTema.largura(texto))


func _linha_traco(arte: String, texto: String, y: float) -> void:
	# Traço de luta da arte (Fase 5): ícone da arte + texto como um grupo centralizado na largura útil da janela.
	var faixa := Control.new()
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.position = Vector2(X0, y)
	faixa.size = Vector2(X1 - X0, 10)
	faixa.set_meta("ui_margens", "h")
	painel.add_child(faixa)
	var icone := "art_%s_9" % arte
	var tem_icone := not UiTema.sprite(icone).is_empty()
	var grupo := UiTema.largura_visivel(texto.to_upper()) + (13.0 if tem_icone else 0.0)
	var gx := roundf((faixa.size.x - grupo) / 2.0)
	if tem_icone:
		UiTema.textura_rect(faixa, icone, gx, 0)
	UiTema.rotulo(faixa, texto.to_upper(), UiTema.P2, gx + (13.0 if tem_icone else 0.0), 0)


# Uma linha: [número dele] [ícone + atributo] [número seu]. Destaque quando ele está muito à frente.
func _linha_atributo(atr: String, y: float) -> void:
	var eh_lead: bool = str(_dados.lead) == atr
	UiTema.nine_patch(painel, "ui_stat_row_lead" if eh_lead else "ui_stat_row", Rect2(X0, y, X1 - X0, 15))
	var dele := float(_dados.opponent[atr])
	var seu := float(_dados.you[atr])
	var t_dele := NumberFormat.fmt(dele, NumberFormat.TRUNCAR)
	var t_seu := NumberFormat.fmt(seu, NumberFormat.TRUNCAR)
	var maior_dele := dele > seu
	var maior_seu := seu > dele
	UiTema.rotulo(painel, t_dele, UiTema.R3 if maior_dele else UiTema.G3, X0 + 6, y + 3)
	if eh_lead:
		UiTema.textura_rect(painel, "icon_lead", X0 + 10 + UiTema.largura(t_dele), y + 3)
	var cor := UiTema.cor_atributo(atr)
	var nome := str(GameState.dados.atributo_info(atr).get("name", atr)).to_upper()
	var w := 12.0 + UiTema.largura(nome)
	var xc := 320.0 - w / 2.0
	UiTema.textura_rect(painel, "icon_" + atr, roundf(xc), y + 3)
	UiTema.rotulo(painel, nome, cor, roundf(xc) + 12, y + 3)
	var rs := UiTema.rotulo(painel, t_seu, UiTema.GR3 if maior_seu else UiTema.G3, 0, y + 3)
	rs.position.x = roundf(X1 - 6 - UiTema.largura(t_seu))


func _montar_tatica(t: Dictionary, x: float, y: float) -> void:
	var id: String = t.id
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get(id, {})
	var b := UiTema.botao(painel, Rect2(x, y, 98, 22))
	UiTema.botao_conteudo(b, str(t.name).to_upper(), UiTema.WHITE, 1, str(info.get("icon_9", "icon_tactic_" + id + "_9")), 3.0)
	b.pressed.connect(func() -> void: _escolher(id, true))
	# Risco de cada tática, em miniatura, embaixo do botão: dá para comparar sem clicar.
	var rot := str(_dados.risks.get(id, {}).get("label", ""))
	var sub := ColorRect.new()
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.color = UiTema.cor_atributo({"aggressive": "strength", "counter": "agility", "defensive": "endurance"}.get(id, ""))
	sub.position = Vector2(x + 3, y + 23)
	sub.size = Vector2(92, 2)
	painel.add_child(sub)
	if rot != "":
		# Ícone + risco como um grupo centralizado embaixo do botão (a faixa tem a largura do botão; o verificador
		# confere que as margens esquerda e direita do grupo são iguais).
		var faixa := Control.new()
		faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		faixa.position = Vector2(x, y + 27)
		faixa.size = Vector2(98, 10)
		faixa.set_meta("ui_margens", "h")
		painel.add_child(faixa)
		var gx := roundf((98.0 - UiTema.tamanho_quadro("icon_risk_" + rot).x) / 2.0)
		UiTema.textura_rect(faixa, "icon_risk_" + rot, gx, 1)
	_rotulo_tatica[id] = {"botao": b, "sub": sub, "info": info}


func _escolher(id: String, tocou: bool) -> void:
	_tatica = id
	if tocou:
		GameState.definir_tatica(id)  # guarda como "última tática" (o Fluxo restaura ao voltar)
	for tid in _rotulo_tatica:
		var d: Dictionary = _rotulo_tatica[tid]
		var ativo: bool = tid == id
		var estilo := str(d.info.get("button_selected", "ui_button_normal")) if ativo else "ui_button_normal"
		UiTema.aplicar_estilo_botao(d.botao, estilo)
		d.sub.visible = ativo
	var t: Dictionary = GameState.lutas.tatica(id)
	_dica.text = str(t.get("hint", "")).to_upper()
	var rot := str(_dados.risks.get(id, {}).get("label", ""))
	_mostrar_risco(rot, tocou)


func _mostrar_risco(rot: String, animar: bool) -> void:
	var mudou := rot != _selo_rotulo
	_selo_rotulo = rot
	if _selo != null:
		_selo.queue_free()
		_selo = null
	if rot == "":
		return
	_selo = UiTema.selo_risco(_selo_area, rot, 0, 0)
	if animar and mudou:
		_selo.modulate = Color(2.4, 2.4, 2.4)
		_selo.create_tween().tween_property(_selo, "modulate", Color.WHITE, 0.35)
	# Aviso só na 1ª prévia da 1ª carreira: o amarelo é "pode perder", não "vai ganhar".
	var primeira := GameState.indice_escada == 0 and GameState.numero_carreira() == 1 \
		and int(GameState.permanente.get("careers_finished", 0)) == 0
	_aviso.text = ""
	if primeira and rot == "even":
		_aviso.text = UiTema.txt("risk_even_warn", "AMARELO = PODE PERDER")
		_aviso.add_theme_color_override("font_color", UiTema.Y1)
	elif primeira and rot == "hard":
		_aviso.text = UiTema.txt("risk_hard_warn", "VERMELHO = VAI PERDER")
		_aviso.add_theme_color_override("font_color", UiTema.R3)
	elif GameState.esperar_verde(str(_dados.opponent.id), rot) and not GameState.no_dia_da_luta():
		# No dia da luta o treino está parado: não dá para esperar, então a dica some.
		# Regra L1 (decisão D2): contra o algoz e quem vem antes dele, enquanto não estiver verde. Só texto: a cor não mente.
		_aviso.text = UiTema.txt("preview_wait_green", "ESPERE FICAR VERDE")
		_aviso.add_theme_color_override("font_color", UiTema.Y1)
	# Porcentagem ao lado do selo (a decisão 11 da Fase 3: só com o nó que a libera).
	_percent.visible = bool(_dados.get("show_percent", false))
	if _percent.visible:
		var pct := int(_dados.risks.get(_tatica, {}).get("percent", 0))
		_percent.text = UiTema.txt("preview_percent", "{n}%", {"n": pct})
		_percent.add_theme_color_override("font_color", UiTema.cor_risco(rot))
		_percent.position.x = _selo_area.position.x + _selo.size.x + 8.0


func _process(delta: float) -> void:
	_t += delta
	if _aviso != null and _aviso.text != "":
		_aviso.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 6.0))
