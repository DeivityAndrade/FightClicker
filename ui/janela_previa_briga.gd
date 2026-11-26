class_name JanelaPreviaBriga
extends JanelaBase
## Ronda 2a1: prévia da noite de briga (depois da aproximação). A janela da prévia de luta, com o bandido no lugar do adversário:
## retratos (ele em silhueta enquanto não venceu, o vulto sem nome), atributos lado a lado, o carimbo de risco e a % de vencer por
## tática, as 3 táticas, a linha nova "CHANCE DO DESAFIO: N%" (ou FEITO / PERDIDO no desafio de surpresa) e SAIR / LUTAR!.
## Só lê `GameState.briga_previa()`. A tática escolhida aqui vale só para a noite: a janela NÃO chama `definir_tatica`.

signal lutar_pedido(tatica_id: String)
signal sair_pedido

const X0 := 164.0
const X1 := 476.0
const ATRIBUTOS := ["strength", "agility", "endurance"]
const ALTURA := 290.0

var _dados: Dictionary = {}
var _tatica := ""
var _selo_area: Control
var _selo: Control
var _selo_rotulo := ""
var _percent: Label
var _rotulo_tatica: Dictionary = {}
var _dica: Label
var _desafio: Label
var _y_desafio := 0.0
var _cartao: CartaoPassiva
var _cartao_adv: CartaoAdversario
var _t := 0.0


func abrir_com(dados: Dictionary) -> void:
	_dados = dados
	_tatica = str(dados.get("tactic", ""))
	_montar()
	_escolher(_tatica, false)
	animar_entrada()


func _conhecido(id: String) -> bool:
	for f in GameState.dossie():
		if str(f.bandit) == id:
			return bool(f.known)
	return false


func _montar() -> void:
	var opp: Dictionary = _dados.opponent
	var topo := floorf((360.0 - (ALTURA + SOMBRA)) / 2.0)
	moldura("ui_window", Rect2(152, topo, 336, ALTURA))
	faixa_titulo("neutral", Rect2(154, topo + 2.0, 332, 16), UiTema.txt("night_alley_name", "BRIGA NO BECO"))
	var y := topo + 24.0
	# Como a aproximação terminou (PEGOU DE SURPRESA / ELE VIROU / ELE PERCEBEU), num chip escuro no meio.
	var ap := str(_dados.get("approach", {}).get("text", "")).to_upper()
	if ap != "":
		var w := roundf(UiTema.largura_visivel(ap)) + 14.0
		if int(w) % 2 != 0:
			w += 1.0
		var chip := UiTema.nine_patch(painel, "c_chip", Rect2(320.0 - w / 2.0, y, w, 13))
		chip.set_meta("ui_pos", "center_h")
		chip.set_meta("ui_fundo_escuro", true)
		UiTema.rotulo_centrado(chip, UiTema.area_nove("c_chip", Vector2(w, 13)), ap, UiTema.CREAM)
	y += 18.0

	# --- Retratos: ele (silhueta até vencer) à esquerda, o vulto à direita ---
	var by: Dictionary = UiTema.manifest().get("by_data_id", {})
	var info_opp: Dictionary = by.get("opp_alley_" + str(_dados.get("bandit", "")), {})
	var quadro := UiTema.textura_rect(painel, "c_retrato_moldura", X0, y)
	var ret := UiTema.textura_rect(quadro, str(info_opp.get("portrait", "")), 2, 2)
	if not _conhecido(str(_dados.get("bandit", ""))):
		ret.modulate = UiTema.INK  # silhueta: ele ainda não tem ficha
	UiTema.rotulo(painel, UiTema.txt("preview_him", "ELE"), UiTema.G2, X0 + 42, y + 2)
	var apelido := str(opp.get("nickname", ""))
	if not _conhecido(str(_dados.get("bandit", ""))):
		apelido = UiTema.txt("alley_%s_anon" % str(_dados.get("bandit", "")), apelido)  # 2a1 B2: sem nome até a 1ª vitória
		if UiTema.largura(apelido.to_upper()) > 94.0:  # "O LADRÃO DO ESTEPE" (101 px) bate no selo VS: cai para a versão curta do HUD
			apelido = UiTema.txt("alley_occ_%s_anon" % str(_dados.get("bandit", "")), apelido)
	UiTema.rotulo(painel, apelido.to_upper(), UiTema.WHITE, X0 + 42, y + 13)
	UiTema.rotulo(painel, str(opp.get("profile", "")).to_upper(), UiTema.cor_nome(str(info_opp.get("color", "g3"))), X0 + 42, y + 24)
	var vs := UiTema.textura_rect(painel, "ui_vs_badge", 304, y + 6)
	vs.pivot_offset = Vector2(16, 12)
	var q2 := UiTema.textura_rect(painel, "c_retrato_moldura", X1 - 36, y)
	UiTema.textura_rect(q2, str(by.get("vulto_fight", {}).get("portrait", "portrait_vulto")), 2, 2).flip_h = true
	var dir := X1 - 42
	_rotulo_dir(UiTema.txt("preview_you", "VOCÊ"), UiTema.G2, dir, y + 2)
	_rotulo_dir(UiTema.txt("fighter_name_hidden", "???"), UiTema.WHITE, dir, y + 13)
	y += 42.0

	# --- Atributos lado a lado ---
	for atr in ATRIBUTOS:
		_linha_atributo(atr, y)
		y += 15.0
	y += 5.0

	# --- Risco e % de vencer ---
	_selo_area = Control.new()
	_selo_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selo_area.position = Vector2(X0, y)
	painel.add_child(_selo_area)
	_percent = UiTema.rotulo(painel, "", UiTema.WHITE, X0, y + 4)
	y += 22.0

	# --- Táticas ---
	UiTema.rotulo(painel, UiTema.txt("tactic_label", "TÁTICA"), UiTema.G3, X0, y)
	y += 12.0
	var x := X0
	for t in GameState.lutas.taticas:
		_montar_tatica(t, x, y)
		x += 107.0
	y += 22.0 + 2.0 + 13.0 + 2.0
	_dica = UiTema.rotulo(painel, "", UiTema.G3, X0, y, X1 - X0, HORIZONTAL_ALIGNMENT_CENTER)
	y += 16.0

	# --- Desafio: a chance por tática (ou FEITO / PERDIDO) e o que pede ---
	divisor(X0, y, X1 - X0)
	y += 6.0
	_y_desafio = y
	_desafio = UiTema.rotulo(painel, "", UiTema.Y1, X0, y, X1 - X0, HORIZONTAL_ALIGNMENT_CENTER)
	UiTema.alinhar(_desafio, "center_h")
	var txt_desafio := str(_dados.get("challenge", {}).get("text", "")).to_upper()
	var l2 := UiTema.rotulo(painel, txt_desafio, UiTema.G3, X0, y + 11.0, X1 - X0, HORIZONTAL_ALIGNMENT_CENTER)
	UiTema.alinhar(l2, "center_h")

	_montar_cartao_passiva(topo)
	_montar_cartao_adversario(topo)

	# --- Botões: SAIR (papel) e LUTAR! (vermelho), 4 px entre eles ---
	var yb := topo + ALTURA - 12.0 - 26.0
	var larg := (X1 - X0 - 4.0) / 2.0
	var sair := botao_texto(Rect2(X0, yb, larg, 26), UiTema.txt("mini_exit", "SAIR"))
	sair.pressed.connect(func() -> void: sair_pedido.emit())
	var lutar := botao_texto(Rect2(X0 + larg + 4.0, yb, larg, 26), UiTema.txt("fight_button", "LUTAR!"), UiTema.Y2, "", 2, "ui_button_fight")
	lutar.pressed.connect(func() -> void: lutar_pedido.emit(_tatica))


func _montar_cartao_passiva(topo: float) -> void:
	var blocos: Dictionary = _dados.get("passive_tactics", {})
	if blocos.is_empty():
		return
	_cartao = CartaoPassiva.new()
	_cartao.name = "CartaoPassiva"
	_cartao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cartao.position = Vector2(X1 + 20.0, topo + 48.0)
	painel.add_child(_cartao)


func _montar_cartao_adversario(topo: float) -> void:
	if str(_dados.get("opp_passive_id", "")) == "":
		return
	_cartao_adv = CartaoAdversario.new()
	_cartao_adv.name = "CartaoAdversario"
	_cartao_adv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cartao_adv.position = Vector2(152.0 - 4.0 - CartaoAdversario.LARG, topo + 48.0)
	painel.add_child(_cartao_adv)
	_cartao_adv.montar(_dados)


func _rotulo_dir(texto: String, cor: Color, x_fim: float, y: float) -> void:
	var l := UiTema.rotulo(painel, texto, cor, 0, y)
	l.position.x = roundf(x_fim - UiTema.largura(texto))


func _linha_atributo(atr: String, y: float) -> void:
	divisor(X0, y + 14.0, X1 - X0)
	var dele := float(_dados.opponent[atr])
	var seu := float(_dados.you[atr])
	var t_dele := NumberFormat.fmt(dele, NumberFormat.TRUNCAR)
	var t_seu := NumberFormat.fmt(seu, NumberFormat.TRUNCAR)
	UiTema.rotulo(painel, t_dele, UiTema.R3 if dele > seu else UiTema.G3, X0 + 6, y + 3)
	var nome := str(GameState.dados.atributo_info(atr).get("name", atr)).to_upper()
	var w := 12.0 + UiTema.largura(nome)
	var xc := 320.0 - w / 2.0
	UiTema.textura_rect(painel, "icon_" + atr, roundf(xc), y + 3)
	UiTema.rotulo(painel, nome, UiTema.cor_atributo(atr), roundf(xc) + 12, y + 3)
	var rs := UiTema.rotulo(painel, t_seu, UiTema.GR3 if seu > dele else UiTema.G3, 0, y + 3)
	rs.position.x = roundf(X1 - 6 - UiTema.largura(t_seu))


func _montar_tatica(t: Dictionary, x: float, y: float) -> void:
	var id: String = t.id
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get(id, {})
	var b := UiTema.botao(painel, Rect2(x, y, 98, 22))
	UiTema.botao_conteudo(b, str(t.name).to_upper(), UiTema.WHITE, 1, str(info.get("icon_9", "icon_tactic_" + id + "_9")), 3.0)
	b.pressed.connect(func() -> void: _escolher(id, true))
	var sub := ColorRect.new()
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.color = UiTema.R1
	sub.position = Vector2(x + 3, y + 23)
	sub.size = Vector2(92, 2)
	painel.add_child(sub)
	var rot := str(_dados.risks.get(id, {}).get("label", ""))
	if rot != "":
		var faixa := Control.new()
		faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		faixa.position = Vector2(x, y + 27)
		faixa.size = Vector2(98, 10)
		faixa.set_meta("ui_margens", "h")
		painel.add_child(faixa)
		var gx := roundf((98.0 - UiTema.tamanho_quadro("icon_risk_" + rot).x) / 2.0)
		UiTema.textura_rect(faixa, "icon_risk_" + rot, gx, 1)
	_rotulo_tatica[id] = {"botao": b, "sub": sub}


func _escolher(id: String, tocou: bool) -> void:
	_tatica = id
	for tid in _rotulo_tatica:
		var d: Dictionary = _rotulo_tatica[tid]
		var ativo: bool = tid == id
		UiTema.aplicar_estilo_botao(d.botao, "c_btn_foco" if ativo else "c_btn_normal")
		d.sub.visible = ativo
	_dica.text = str(GameState.lutas.tatica(id).get("hint", "")).to_upper()
	_mostrar_risco(str(_dados.risks.get(id, {}).get("label", "")), tocou)
	_mostrar_desafio(id)
	if _cartao != null:
		var bloco: Dictionary = _dados.get("passive_tactics", {}).get(id, {})
		if not bloco.is_empty():
			_cartao.montar(bloco, str(_dados.get("art", "")), tocou)


## A linha do desafio por tática. `surprise` não tem porcentagem: FEITO se houve SUSTO na aproximação, senão PERDIDO.
func _mostrar_desafio(id: String) -> void:
	var ch: Dictionary = _dados.get("challenge", {})
	if str(ch.get("type", "")) == "surprise":
		var feito := bool(ch.get("done", false))
		_desafio.text = UiTema.txt("alley_ch_done", "DESAFIO: FEITO") if feito else UiTema.txt("alley_ch_lost", "DESAFIO: PERDIDO")
		UiTema.pintar(_desafio, UiTema.GR3 if feito else UiTema.R3)
	else:
		_desafio.text = str(ch.get("line_by_tactic", {}).get(id, "")).to_upper()
		UiTema.pintar(_desafio, UiTema.Y1)


func _mostrar_risco(rot: String, animar: bool) -> void:
	var mudou := rot != _selo_rotulo
	_selo_rotulo = rot
	if _selo != null:
		_selo.queue_free()
		_selo = null
	if rot == "":
		return
	_selo = UiTema.selo_carimbo(_selo_area, rot, 0, 0)
	if animar and mudou:
		_selo.modulate = Color(2.4, 2.4, 2.4)
		_selo.create_tween().tween_property(_selo, "modulate", Color.WHITE, 0.35)
	_percent.visible = true
	_percent.text = UiTema.txt("preview_percent", "{n}%", {"n": int(_dados.risks.get(_tatica, {}).get("percent", 0))})
	UiTema.pintar(_percent, UiTema.cor_risco(rot))
	_percent.position.x = _selo_area.position.x + _selo.size.x + 8.0
