class_name JanelaVitoria
extends JanelaBase
## Vitória: prêmio (dinheiro, fama, Legado em jogo) com contagem subindo, Legado em jogo atual e o próximo
## adversário. Se foi o cinturão: cinturão amador grande e o aviso da mudança para a academia (só texto,
## nada clicável). O único botão é CONTINUAR. No cinturão a mudança para a academia é AUTOMÁTICA (o `Fluxo` a faz ao fechar):
## a janela só avisa "você se muda para a academia" e não tem botão MUDAR.

signal continuar_pedido

var sfx: Sfx
var _contadores: Array = []  # {rotulo, valor, formato}


func abrir_com(resumo: Dictionary, tocar_som: bool) -> void:
	sfx = Sfx.new()
	add_child(sfx)
	var cinturao := bool(resumo.get("belt", false))
	if cinturao:
		_montar_cinturao(resumo)
	else:
		_montar_normal(resumo)
	animar_entrada()
	if tocar_som:
		sfx.vitoria()
	if bool(resumo.get("revenge", false)):
		sfx.publico(-8.0)  # a revanche tem torcida
	sfx.moeda()
	_animar_contadores()


func _modelo_ganhos() -> Array:
	# victory_gain = "+${n}   +{n} FAMA   +{n} LEGADO": três trechos separados por 3 espaços.
	var texto := GameState.texto_ui("victory_gain", "+${n}   +{n} FAMA   +{n} LEGADO")
	var partes := texto.split("   ")
	while partes.size() < 3:
		partes.append("+{n}")
	return [partes[0], partes[1], partes[2]]


func _montar_normal(r: Dictionary) -> void:
	var revanche := bool(r.get("revenge", false))
	# A janela cresce para caber a linha "+N LEGADO EM JOGO" (3 linhas de ganhos em escala 2) e, na revanche, o letreiro.
	var bloco := 56.0 + 14.0 + _largura_ganhos(r, 2)
	var lj := maxf(288.0, roundf(bloco / 2.0) * 2.0 + 40.0)
	var xj := 320.0 - lj / 2.0
	var topo := 42.0 if revanche else 72.0
	var dy := 32.0 if revanche else 0.0  # deslocamento do miolo (posições originais + dy)
	moldura("ui_window", Rect2(xj, topo, lj, 222.0 + (62.0 if revanche else 0.0)))
	faixa_titulo("victory", Rect2(xj + 6.0, topo + 6.0, lj - 12.0, 22), UiTema.txt("victory_title", "VENCEU!"), UiTema.Y2, 2)
	if revanche:
		_letreiro_revanche(r, topo + 32.0)
	var by: Dictionary = UiTema.manifest().get("by_data_id", {})
	# Quem caiu (retrato dele, sem espelhar) e os ganhos ao lado.
	var info_o: Dictionary = by.get(str(r.opponent), {})
	# Bloco [coluna do retrato 56 px] [14 px] [ganhos], centralizado na janela (largura final dos ganhos).
	var x0 := roundf(320.0 - bloco / 2.0)
	retrato(str(info_o.get("portrait", "")), str(info_o.get("portrait_frame", "ui_portrait_frame")), x0 + 10.0, 114.0 + dy, false)
	UiTema.rotulo(painel, str(GameState.lutas.adversario(str(r.opponent)).get("name", "")).to_upper(),
		UiTema.G3, x0, 154.0 + dy, 56.0, HORIZONTAL_ALIGNMENT_CENTER)
	_linhas_ganhos(r, x0 + 70.0, 112.0 + dy, 2)
	divisor(190, 184.0 + dy, 260)
	linha_icone("icon_legacy", UiTema.txt("hud_legacy_run", "LEGADO EM JOGO"), UiTema.P2, 196, 192.0 + dy)
	var v := UiTema.rotulo(painel, str(int(r.legacy_run)), UiTema.P2, 0, 192.0 + dy)
	v.position.x = roundf(444.0 - UiTema.largura(v.text))
	if str(r.get("next_name", "")) != "":
		UiTema.rotulo_centro(painel, UiTema.txt("victory_next", "PRÓXIMO: {nome}", {"nome": str(r.next_name)}),
			UiTema.WHITE, 320.0, 212.0 + dy)
	var b := botao_texto(Rect2(240, 242.0 + dy, 160, 28), UiTema.txt("victory_continue", "CONTINUAR"), UiTema.WHITE, "ui_button_normal", 1)
	b.pressed.connect(func() -> void: continuar_pedido.emit())


## "REVANCHE!" (letreiro com estouro, 2 quadros) e a linha do Roteirista logo abaixo. Entra com um "pop" e a tremida de 2 px
## do manifest. Se o texto `victory_revenge` mudar, usa só o estouro e escreve o texto novo por cima (3x, ouro).
func _letreiro_revanche(r: Dictionary, y: float) -> void:
	var texto := UiTema.txt("victory_revenge", "REVANCHE!")
	var padrao := texto == "REVANCHE!"
	var banner := AnimSprite.new()
	banner.definir("ui_banner_revenge" if padrao else "ui_banner_revenge_burst")
	banner.position = Vector2(320, y + 26.0)  # o pivô fica no meio do letreiro (84, 26)
	if padrao:
		banner.tocar([0, 1], 4.0, true)
	painel.add_child(banner)
	var escrito: Label = null
	if not padrao:
		escrito = UiTema.rotulo_centrado(painel, Rect2(0, y, 640, 52), texto, UiTema.Y1, 3, true, "center")
	var alvo: Node2D = banner
	alvo.scale = Vector2(2, 2)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(alvo, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if escrito != null:
		escrito.modulate.a = 0.0
		tw.tween_property(escrito, "modulate:a", 1.0, 0.18)
	var treme := create_tween()
	treme.tween_interval(0.22)
	for d in [Vector2(2, 0), Vector2(-2, 1), Vector2(1, -2), Vector2(-1, 1), Vector2.ZERO]:
		treme.tween_property(painel, "position", d, 0.04)
	var linha := str(r.get("revenge_line", ""))
	if linha != "":
		UiTema.rotulo_centro(painel, linha.to_upper(), UiTema.Y1, 320.0, y + 56.0)


func _montar_cinturao(r: Dictionary) -> void:
	moldura("ui_window", Rect2(150, 22, 340, 316))
	faixa_titulo("victory", Rect2(156, 28, 328, 22), UiTema.txt("belt_title", "CINTURÃO AMADOR"), UiTema.Y1, 2)
	var cint := AnimSprite.new()
	cint.definir("belt_amateur_big")
	cint.position = Vector2(320, 100)
	cint.scale = Vector2(2, 2)
	cint.tocar([0, 1, 2], 6.0, true)
	painel.add_child(cint)
	if bool(r.get("revenge", false)):
		# Cinturão e revanche juntos: a linha do bairro dá lugar a "REVANCHE! ... NÃO ESPERAVA ESSA." (a janela já está cheia).
		UiTema.rotulo_centro(painel, (UiTema.txt("victory_revenge", "REVANCHE!") + " " + str(r.get("revenge_line", ""))).to_upper(),
			UiTema.Y1, 320.0, 140.0)
	else:
		UiTema.rotulo_centro(painel, UiTema.txt("belt_line", "O bairro viu. Uns quinze."), UiTema.CREAM, 320.0, 140.0)
	_linhas_ganhos(r, roundf(320.0 - _largura_ganhos(r, 1) / 2.0), 158.0, 1, true)
	divisor(166, 208, 308)
	linha_icone("icon_legacy", UiTema.txt("hud_legacy_run", "LEGADO EM JOGO"), UiTema.P2, 172, 215)
	var v := UiTema.rotulo(painel, str(int(r.legacy_run)), UiTema.P2, 0, 215)
	v.position.x = roundf(468.0 - UiTema.largura(v.text))
	# Academia de bairro: aviso de que a mudança é automática (NÃO é botão).
	fundo_cor(Rect2(166, 232, 308, 42), Color(UiTema.P0, 0.55))
	UiTema.textura_rect(painel, "icon_belt_amateur_9", 174, 238)
	UiTema.rotulo(painel, UiTema.txt("belt_unlock", "VOCÊ SE MUDA PARA A ACADEMIA BOA ESQUINA"), UiTema.Y1, 188, 238, 280)
	UiTema.rotulo(painel, UiTema.txt("belt_hint", "A MUDANÇA SAI DO PRÊMIO E SOBRA DINHEIRO PARA GASTAR."), UiTema.G3, 174, 252, 292)
	var b := botao_texto(Rect2(240, 296, 160, 28), UiTema.txt("victory_continue", "CONTINUAR"), UiTema.WHITE, "ui_button_normal", 1)
	b.pressed.connect(func() -> void: continuar_pedido.emit())


# Três ganhos com ícone: dinheiro (y1), fama (p2), Legado em jogo (p2). Os números "sobem" ao abrir.
func _linhas_ganhos(r: Dictionary, x: float, y: float, escala: int, centrado: bool = false) -> void:
	var modelo := _modelo_ganhos()
	var dados := [
		{"icone": "icon_money_16", "valor": float(r.money), "cor": UiTema.Y1, "modelo": modelo[0], "fmt": 0},
		{"icone": "icon_fame_16", "valor": float(r.fame), "cor": UiTema.P2, "modelo": modelo[1], "fmt": 1},
		{"icone": "icon_legacy_16", "valor": float(r.legacy_gain), "cor": UiTema.P2, "modelo": modelo[2], "fmt": 1},
	]
	var i := 0
	for d in dados:
		var yy := y + i * (22.0 if escala == 2 else 12.0)
		var xx := x
		if centrado:
			# Em coluna única (tela do cinturão); `x` já vem centralizado pelo chamador.
			yy = y + i * 16.0
		var ty := yy + (2.0 if escala == 2 else 0.0)
		# O ícone (16 px) fica centralizado na altura do texto (glifo de 7 px x escala, 2 px x escala abaixo do topo).
		UiTema.textura_rect(painel, d.icone, xx, roundf(ty + 5.5 * escala - 8.0))
		var l := UiTema.rotulo(painel, "", d.cor, xx + 20.0, ty)
		l.scale = Vector2(escala, escala)
		_contadores.append({"rotulo": l, "valor": d.valor, "modelo": d.modelo})
		i += 1


## Largura do bloco de ganhos com os números FINAIS (ícone 16 + 4 px + o texto mais largo): o bloco se centraliza
## na janela de uma vez, sem andar enquanto os números sobem.
func _largura_ganhos(r: Dictionary, escala: int) -> float:
	var modelo := _modelo_ganhos()
	var valores := [float(r.money), float(r.fame), float(r.legacy_gain)]
	var maior := 0.0
	for i in 3:
		var t := GameState.preencher(modelo[i], {"n": NumberFormat.fmt(valores[i])}).to_upper()
		maior = maxf(maior, UiTema.largura_visivel(t) * escala)
	return 20.0 + maior


func _animar_contadores() -> void:
	var tw := create_tween()
	tw.tween_method(func(p: float) -> void:
		for c in _contadores:
			c.rotulo.text = GameState.preencher(c.modelo, {"n": NumberFormat.fmt(floorf(c.valor * p + 0.0001))}).to_upper(),
		0.0, 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		for c in _contadores:
			c.rotulo.text = GameState.preencher(c.modelo, {"n": NumberFormat.fmt(float(c.valor))}).to_upper()
			c.rotulo.modulate = Color(1.8, 1.8, 1.8)
			c.rotulo.create_tween().tween_property(c.rotulo, "modulate", Color.WHITE, 0.3))
