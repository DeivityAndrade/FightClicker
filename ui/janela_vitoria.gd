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
	if bool(resumo.get("regional_belt", false)):
		_montar_cinturao_regional(resumo)  # 8a1: o James caiu: Cinturão do Vale
	elif cinturao:
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
	# 7b2: uma linha a mais para a meta da 2ª passiva ("2/3 K.O. DE EMBALO") ou, quando abre, o aviso único NOVO JEITO DE LUTAR.
	var sp := _altura_patrocinio(r)  # 8a2: a linha PATROCÍNIO ...: +$n entra entre o Legado em jogo e o PRÓXIMO
	var extra := _altura_passiva(r) + _altura_liga(r) + sp
	var corr := -roundf(extra / 2.0)  # a janela cresce para os dois lados (continua no meio)
	var topo := (42.0 if revanche else 72.0) + corr
	var dy := (32.0 if revanche else 0.0) + corr  # deslocamento do miolo (posições originais + dy)
	moldura("ui_window", Rect2(xj, topo, lj, 210.0 + (62.0 if revanche else 0.0) + extra))  # 210: o botão fica a 12 px da borda de baixo, como nas outras janelas
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
	_linha_patrocinio(r, 209.0 + dy)
	if str(r.get("next_name", "")) != "":
		UiTema.rotulo_centro(painel, UiTema.txt("victory_next", "PRÓXIMO: {nome}", {"nome": str(r.next_name)}),
			UiTema.WHITE, 320.0, 212.0 + dy + sp)
	_bloco_passiva(r, xj, lj, 228.0 + dy + sp)
	_bloco_liga(r, xj, lj, 228.0 + dy + sp + _altura_passiva(r))
	var b := botao_texto(Rect2(240, 242.0 + dy + extra, 160, 28), UiTema.txt("victory_continue", "CONTINUAR"), UiTema.WHITE, "ui_button_normal", 1, "", true)
	b.pressed.connect(func() -> void: continuar_pedido.emit())


## 8a2: 14 px a mais na janela quando o contrato está assinado e esta vitória pagou o bônus (resumo.sponsor_money).
func _altura_patrocinio(r: Dictionary) -> float:
	return 14.0 if int(r.get("sponsor_money", 0)) > 0 and not GameState.patrocinio().is_empty() else 0.0


## 8a2: "[marca 9x9] PATROCÍNIO VALE FORTE: +$n" (ouro), o grupo centralizado na janela; o número sobe junto com os outros.
func _linha_patrocinio(r: Dictionary, y: float) -> void:
	var v := int(r.get("sponsor_money", 0))
	var p: Dictionary = GameState.patrocinio()
	if v <= 0 or p.is_empty():
		return
	var final := GameState.preencher(str(p.bonus_line), {"n": NumberFormat.fmt(float(v))}).to_upper()
	var marca := "sponsor_vale_9"
	var tem := not UiTema.sprite(marca).is_empty()
	var grupo := UiTema.largura_visivel(final) + (12.0 if tem else 0.0)
	var x0 := roundf(320.0 - grupo / 2.0)
	if tem:
		var ic := UiTema.textura_rect(painel, marca, x0, y - 1.0)
		UiTema.ignorar(ic, "marca do patrocinador ao lado do texto: o grupo marca + texto é que fica centralizado na janela")
	var l := UiTema.rotulo(painel, "", UiTema.Y1, x0 + (12.0 if tem else 0.0), y)
	UiTema.alinhar(l, "left")
	_contadores.append({"rotulo": l, "valor": float(v), "modelo": str(p.bonus_line)})


## 7b2: altura extra da janela para a linha da 2ª passiva (0 sem nada; 14 com a meta; 36 com o aviso de liberação).
func _altura_passiva(r: Dictionary) -> float:
	if str(r.get("passive2_line", "")) != "" and str(r.get("passive2_unlocked", "")) != "":
		return 36.0
	return 14.0 if _texto_meta(r) != "" else 0.0


## 8a1: altura extra da janela para o convite da liga regional (só ao vencer o Kid): 40 com o título, 30 se a janela já tem o aviso da
## 2ª passiva (a janela não passa dos 360 px mesmo com a revanche).
func _altura_liga(r: Dictionary) -> float:
	if not bool(r.get("league_opened", false)):
		return 0.0
	return 30.0 if _altura_passiva(r) >= 36.0 else 40.0


## 8a1: "CONVITE: LIGA REGIONAL DO VALE" + a linha do convite, com o ícone do cinturão do Vale, numa caixa (a mesma do aviso da 2ª passiva).
func _bloco_liga(r: Dictionary, xj: float, lj: float, y: float) -> void:
	var alt := _altura_liga(r)
	if alt <= 0.0:
		return
	var caixa := fundo_cor(Rect2(xj + 14.0, y - 1.0, lj - 28.0, alt), UiTema.INK, true)
	var x_txt := 6.0
	var icone := "icon_belt_regional"
	if not UiTema.sprite(icone).is_empty():
		UiTema.textura_rect(caixa, icone, x_txt, roundf((alt - 16.0) / 2.0))
		x_txt += 22.0
	var larg := lj - 28.0 - 6.0 - x_txt
	var linhas: Array = []
	if alt >= 40.0:
		linhas.append(UiTema.txt("league_regional_invite_title", "CONVITE: LIGA REGIONAL DO VALE").to_upper())
	var frases := _quebrar(UiTema.txt("league_regional_invite_line", "O KID PERDEU. O VALE QUER CONHECER A RAÍZES").to_upper(), larg)
	var yy := roundf((alt - 10.0 * float(linhas.size() + frases.size())) / 2.0)
	for t in linhas:
		var lt := UiTema.rotulo(caixa, str(t), UiTema.Y2, x_txt, yy, larg, HORIZONTAL_ALIGNMENT_LEFT)
		UiTema.alinhar_motivo(lt, "left", "texto de várias linhas ao lado do ícone, na caixa escura")
		yy += 10.0
	for t in frases:
		var lf := UiTema.rotulo(caixa, str(t), UiTema.CREAM, x_txt, yy, larg, HORIZONTAL_ALIGNMENT_LEFT)
		UiTema.alinhar_motivo(lf, "left", "texto de várias linhas ao lado do ícone, na caixa escura")
		yy += 10.0


## Quebra por palavra em linhas de até `larg` px.
func _quebrar(texto: String, larg: float) -> Array[String]:
	var linhas: Array[String] = []
	var atual := ""
	for palavra in texto.split(" ", false):
		var tentativa: String = palavra if atual == "" else atual + " " + palavra
		if atual != "" and UiTema.largura_visivel(tentativa) > larg:
			linhas.append(atual)
			atual = palavra
		else:
			atual = tentativa
	if atual != "":
		linhas.append(atual)
	return linhas


## "2/3 K.O. DE EMBALO" (de n, m e do nome do fim; o `text` do resumo só vem preenchido no aviso de liberação).
func _texto_meta(r: Dictionary) -> String:
	var meta: Dictionary = r.get("passive_goal", {})
	if meta.is_empty() or not bool(meta.get("counted", false)) or int(meta.get("m", 0)) <= 0:
		return ""
	return UiTema.txt("art_card_passive_progress", "{n}/{m} {fim}", {"n": int(meta.n), "m": int(meta.m), "fim": str(meta.get("finish_text", ""))}).to_upper()


## 7b2: a meta batida na luta ("2/3 K.O. DE EMBALO", com o ícone da passiva) ou, na luta que libera, o aviso único
## "NOVO JEITO DE LUTAR: {NOME}. ESCOLHA NA PRÓXIMA CARREIRA" numa caixa de 2 linhas com o ícone 16x16. `y` = topo do bloco.
func _bloco_passiva(r: Dictionary, xj: float, lj: float, y: float) -> void:
	var por_arte: Dictionary = UiTema.manifest().get("by_data_id", {})
	var linha := str(r.get("passive2_line", ""))
	var liberou := str(r.get("passive2_unlocked", ""))
	if linha != "" and liberou != "":
		var icone := str(por_arte.get(liberou, {}).get("passive_2_icon", ""))
		var caixa := fundo_cor(Rect2(xj + 14.0, y - 4.0, lj - 28.0, 30.0), UiTema.INK, true)
		var x_txt := 6.0
		if icone != "" and not UiTema.sprite(icone).is_empty():
			UiTema.textura_rect(caixa, icone, x_txt, 7.0)
			x_txt += 22.0
		var larg := lj - 28.0 - 6.0 - x_txt
		var l := UiTema.rotulo(caixa, linha.to_upper(), UiTema.Y1, x_txt, 5.0, larg, HORIZONTAL_ALIGNMENT_LEFT)
		UiTema.alinhar_motivo(l, "left", "aviso de 2 linhas ao lado do ícone, na caixa escura")
		return
	var texto := _texto_meta(r)
	if texto == "":
		return
	var meta: Dictionary = r.get("passive_goal", {})
	var icone9 := str(por_arte.get(str(meta.get("art", "")), {}).get("passive_2_icon_9", ""))
	var tem := icone9 != "" and not UiTema.sprite(icone9).is_empty()
	var grupo := UiTema.largura_visivel(texto) + (12.0 if tem else 0.0)
	var gx := roundf(320.0 - grupo / 2.0)
	if tem:
		UiTema.textura_rect(painel, icone9, gx, y - 1.0)
	var lt := UiTema.rotulo(painel, texto, UiTema.Y1, gx + (12.0 if tem else 0.0), y)
	UiTema.alinhar_motivo(lt, "left", "o grupo ícone + texto é que está centralizado; o texto começa depois do ícone")


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
	# Fase 6a: o 1º cinturão da escola salva a garagem. Entra uma 4ª linha de prêmio (ícone + GARAGEM SALVA) e o selo à direita.
	var salva := bool(r.get("garage_saved", false))
	var patrocinio := int(r.get("sponsor_money", 0)) > 0 and not GameState.patrocinio().is_empty()
	var ds := 20.0 if salva else (18.0 if patrocinio else 0.0)  # o miolo de baixo desce para caber a linha extra (8a2: ou o patrocínio); GARAGEM SALVA tem 2 linhas com ar entre elas
	# ID3: o aviso da mudança é uma etiqueta do tamanho do texto (não mais a caixa preta alta), então a janela encolhe e se recentraliza.
	var alt := 282.0 + ds
	var topo := roundf((360.0 - alt) / 2.0)
	var oy := topo - 22.0  # tudo abaixo estava desenhado para a janela em y 22
	moldura("ui_window", Rect2(150, topo, 340, alt))
	faixa_titulo("victory", Rect2(156, 28 + oy, 328, 22), UiTema.txt("belt_title", "CINTURÃO AMADOR"), UiTema.Y1, 2)
	var cint := AnimSprite.new()
	cint.definir("belt_amateur_big")
	cint.position = Vector2(320, 100 + oy)
	cint.scale = Vector2(2, 2)
	cint.tocar([0, 1, 2], 6.0, true)
	painel.add_child(cint)
	if bool(r.get("revenge", false)):
		# Cinturão e revanche juntos: a linha do bairro dá lugar a "REVANCHE! ... NÃO ESPERAVA ESSA." (a janela já está cheia).
		UiTema.rotulo_centro(painel, (UiTema.txt("victory_revenge", "REVANCHE!") + " " + str(r.get("revenge_line", ""))).to_upper(),
			UiTema.Y1, 320.0, 140.0 + oy)
	else:
		UiTema.rotulo_centro(painel, UiTema.txt("belt_line", "O bairro viu. Uns quinze."), UiTema.CREAM, 320.0, 140.0 + oy)
	var larg := _largura_ganhos(r, 1)
	var titulo_selo := ""
	var sub_selo := ""
	if salva:
		var d: DialogosData = GameState.dialogos
		titulo_selo = d.texto_objeto("garage_saved_seal", "title").to_upper()
		sub_selo = d.texto_objeto("garage_saved_seal", "text").to_upper()
		larg = maxf(larg, 20.0 + UiTema.largura_visivel(sub_selo))
	var x_linhas := roundf(320.0 - larg / 2.0)
	_linhas_ganhos(r, x_linhas, 158.0 + oy, 1, true)
	if salva:
		_linha_selo(x_linhas, 206.0 + oy, titulo_selo, sub_selo)
		_selo_garagem(oy)
	if patrocinio:
		_linha_patrocinio(r, 206.0 + oy)
	divisor(166, 208 + ds + (2.0 if salva else 0.0) + oy, 308)
	linha_icone("icon_legacy", UiTema.txt("hud_legacy_run", "LEGADO EM JOGO"), UiTema.P2, 172, 215 + ds + oy)
	var v := UiTema.rotulo(painel, str(int(r.legacy_run)), UiTema.P2, 0, 215 + ds + oy)
	v.position.x = roundf(468.0 - UiTema.largura(v.text))
	# Academia de bairro: aviso de que a mudança é automática (NÃO é botão). Etiqueta c_chip do tamanho do texto, no meio da janela.
	var aviso_txt := UiTema.txt("belt_unlock", "VOCÊ SE MUDA PARA A ACADEMIA BOA ESQUINA")
	var aw := 5.0 + 9.0 + 4.0 + UiTema.largura_visivel(aviso_txt) + 5.0
	aw = ceilf(aw)
	if int(aw) % 2 != 0:
		aw += 1.0
	var aviso := UiTema.nine_patch(painel, "c_chip", Rect2(320.0 - aw / 2.0, 236.0 + ds + oy, aw, 13))
	aviso.set_meta("ui_fundo_escuro", true)
	UiTema.alinhar(aviso, "center_h")
	UiTema.textura_rect(aviso, "icon_belt_amateur_9", 5, 2)
	var la := UiTema.rotulo(aviso, aviso_txt, UiTema.Y1, 18, UiTema.y_texto(Rect2(0, 2, 1, 9)))
	UiTema.alinhar_motivo(la, "left", "aviso de 1 linha ao lado do ícone, na etiqueta escura")
	# 6d2: a linha "A MUDANÇA SAI DO PRÊMIO..." saiu (o aviso da reserva já diz isso depois).
	var b := botao_texto(Rect2(240, 263.0 + ds + oy, 160, 28), UiTema.txt("victory_continue", "CONTINUAR"), UiTema.WHITE, "ui_button_normal", 1, "", true)
	b.pressed.connect(func() -> void: continuar_pedido.emit())


## 8a1: o James caiu. Cinturão do Vale grande (2x, brilho em 3 quadros), a frase do Roteirista, os prêmios e o aviso "CENTRO DE TREINAMENTO
## LIBERADO" (a mudança chega na próxima versão). Mesma janela do cinturão amador, com o cinturão maior.
func _montar_cinturao_regional(r: Dictionary) -> void:
	var sp := 14.0 if int(r.get("sponsor_money", 0)) > 0 and not GameState.patrocinio().is_empty() else 0.0  # 8a2: linha do patrocínio
	moldura("ui_window", Rect2(150, 22, 340, 316 + sp))
	faixa_titulo("victory", Rect2(156, 28, 328, 22), UiTema.txt("belt_regional_title", "CINTURÃO DO VALE"), UiTema.Y1, 2)
	var cint := AnimSprite.new()
	cint.definir("belt_regional_big")
	cint.position = Vector2(320, 106)  # o pivô fica no meio do cinturão (60, 26)
	cint.scale = Vector2(2, 2)
	cint.tocar([0, 1, 2], 6.0, true)
	painel.add_child(cint)
	UiTema.rotulo_centro(painel, UiTema.txt("belt_regional_line", "O BLINDADO CAIU. A RAÍZES É DO VALE").to_upper(), UiTema.CREAM, 320.0, 164.0)
	var larg := _largura_ganhos(r, 1)
	var x_linhas := roundf(320.0 - larg / 2.0)
	_linhas_ganhos(r, x_linhas, 180.0, 1, true)
	_linha_patrocinio(r, 232.0)
	divisor(166, 232 + sp, 308)
	linha_icone("icon_legacy", UiTema.txt("hud_legacy_run", "LEGADO EM JOGO"), UiTema.P2, 172, 239 + sp)
	var v := UiTema.rotulo(painel, str(int(r.legacy_run)), UiTema.P2, 0, 239 + sp)
	v.position.x = roundf(468.0 - UiTema.largura(v.text))
	# Aviso (NÃO é botão): o centro de treinamento abre e o MUDAR espera no HUD (8a2).
	var caixa := fundo_cor(Rect2(166, 256 + sp, 308, 30), UiTema.INK, true)
	UiTema.textura_rect(caixa, "icon_belt_regional_9", 8, 6)
	var l1 := UiTema.rotulo(caixa, UiTema.txt("belt_regional_unlock_done" if bool(GameState.permanente.get("center_reached", false)) else "belt_regional_unlock", "CENTRO DE TREINAMENTO LIBERADO").to_upper(), UiTema.Y1, 22, 6, 280)
	var l2 := UiTema.rotulo(caixa, UiTema.txt("belt_regional_soon", "O CENTRO ESPERA: USE O MUDAR").to_upper(), UiTema.G3, 22, 17, 280)
	UiTema.alinhar_motivo(l1, "left", "aviso de 2 linhas ao lado do ícone, na caixa escura")
	UiTema.alinhar_motivo(l2, "left", "aviso de 2 linhas ao lado do ícone, na caixa escura")
	var b := botao_texto(Rect2(240, 298 + sp, 160, 28), UiTema.txt("victory_continue", "CONTINUAR"), UiTema.WHITE, "ui_button_normal", 1, "", true)
	b.pressed.connect(func() -> void: continuar_pedido.emit())


## 4ª linha de prêmio: ícone da garagem salva + "GARAGEM SALVA" (branco) e embaixo a frase do Roteirista (cinza).
func _linha_selo(x: float, y: float, titulo: String, sub: String) -> void:
	UiTema.textura_rect(painel, "icon_garage_saved", x, y)
	UiTema.rotulo(painel, titulo, UiTema.WHITE, x + 20.0, y + 1.0)
	UiTema.rotulo(painel, sub, UiTema.COL_TEXT_2, x + 20.0, y + 11.0)  # 2 px a mais que antes: as duas linhas não ficam coladas


## Selo 52x54 em (418,146): entra 0,3 s depois da janela (2 quadros em 2x, depois 1x), tremida de 1 px e o som do hit_heavy.
func _selo_garagem(oy: float = 0.0) -> void:
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("garage_saved_seal", {})
	var p: Array = (info.get("victory_pos", [418, 146]) as Array).duplicate()
	p[1] = float(p[1]) + oy
	var selo := UiTema.textura_rect(painel, str(info.get("seal", "seal_garage_saved")), float(p[0]), float(p[1]))
	selo.visible = false
	UiTema.ignorar(selo, "selo animado: posição do manifest (victory_pos), à direita das linhas de prêmio; escala e tremida no meio da animação")
	var centro := Vector2(float(p[0]), float(p[1])) + selo.size / 2.0
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(func() -> void:
		selo.visible = true
		selo.scale = Vector2(2, 2)
		selo.position = centro - selo.size  # 2x com o mesmo centro
		sfx.selo())
	tw.tween_interval(1.0 / 30.0)
	tw.tween_callback(func() -> void:
		selo.scale = Vector2(2, 2))
	tw.tween_interval(1.0 / 30.0)
	tw.tween_callback(func() -> void:
		selo.scale = Vector2.ONE
		selo.position = Vector2(float(p[0]), float(p[1])) + Vector2(1, 0))
	tw.tween_interval(0.04)
	tw.tween_callback(func() -> void:
		selo.position = Vector2(float(p[0]), float(p[1])) + Vector2(-1, 1))
	tw.tween_interval(0.04)
	tw.tween_callback(func() -> void:
		selo.position = Vector2(float(p[0]), float(p[1])))


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
