class_name JanelaFim
extends JanelaBase
## Tela de fim de carreira, em dois modos:
##  - derrota ("FIM DE CARREIRA", moldura de concreto com fita vermelha): quem venceu e quando, o motivo principal
##    com número ("FALTARAM {n} DE ..."), a estatística da luta, a dica de ação, o resumo, Legado ganho e total;
##  - aposentadoria ("SAIU POR CIMA", moldura roxa com cantos dourados): luvas penduradas (e o cinturão, se houver).
## Só mostra o que o GameState já decidiu (`fim`, `textos_fim()`). Dois botões: ÁRVORE (gastar o Legado, Fase 4) e NOVA CARREIRA.

signal nova_carreira_pedido
signal arvore_pedido
signal mural_pedido  # 6c2: o botão MURAL abre o mural (onde o hall compra)

## Borda direita dos números (a moldura vai de 110 a 530: 20 px de margem dos dois lados do conteúdo).
const BORDA_DIR := 510.0

var sfx: Sfx
var _botao_arvore: Button
var _arvore_chamando := false  # há nó para comprar: o botão ÁRVORE respira para chamar o clique
var _botao_mural: Button
var _mural_chamando := false  # há nó do hall que a Honra paga: o botão MURAL respira
var _t := 0.0
var _legado_ganho: Label
var _legado_total: Label
var _ganho := 0
var _contar := false
var _total := 0
var _reabrindo := false  # voltando do mapa da árvore: mostra os valores finais, sem contar de novo


func abrir_com(fim: Dictionary, tocar_som: bool, reabrindo: bool = false) -> void:
	_reabrindo = reabrindo
	sfx = Sfx.new()
	add_child(sfx)
	var retire := str(fim.kind) == "retire"
	var textos: Dictionary = GameState.textos_fim(fim)
	if retire:
		_montar_retire(fim, textos)
	else:
		_montar_derrota(fim, textos)
	animar_entrada()
	if tocar_som:
		if retire:
			sfx.vitoria()
		else:
			sfx.derrota()
	_animar_legado()


# --- Derrota ---

func _montar_derrota(f: Dictionary, t_: Dictionary) -> void:
	var t := t_
	# 8a1 (B3 do QA): "A GUARDA SEGUROU 0% ..." não diz nada: sem a nota do Blindado (e sem a dica dela) quando o número é 0.
	if str(t.get("opp_note_id", "")) == "adv_blindado" and not RegEx.create_from_string("(^|[^0-9])[1-9][0-9]*%").search(str(t.get("opp_note", ""))):
		t = t_.duplicate()
		for k in ["opp_note", "opp_note_tip", "opp_note_id", "passive_note", "passive_note_tip", "passive_note_id"]:
			t.erase(k)
	moldura("ui_end_frame_defeat", Rect2(110, 10, 420, 326))
	faixa_titulo("defeat", Rect2(150, 20, 340, 22), str(t.title).to_upper(), UiTema.WHITE, 2)
	var apoio := str(t.support)
	if bool(GameState.lutas.adversario(str(f.get("opponent", ""))).get("regional_belt", false)):
		apoio = UiTema.txt("belt_regional_lost", apoio)  # 8a1: perdeu para o dono do Cinturão do Vale
	UiTema.rotulo_centro(painel, apoio.to_upper(), UiTema.G2, 320.0, 48.0)
	UiTema.rotulo_centro(painel, UiTema.singular(str(t.who).to_upper()), UiTema.WHITE, 320.0, 62.0)

	# Motivo principal com número + estatística + dica (a dica sempre bate com o atributo decisivo).
	var linhas: Array = []
	linhas.append({"texto": UiTema.singular(str(t.reason).to_upper()), "cor": UiTema.WHITE})
	if str(t.stat) != "":
		linhas.append({"texto": UiTema.singular(str(t.stat).to_upper()), "cor": UiTema.G3})
	if str(t.tip) != "":
		linhas.append({"texto": str(t.tip).to_upper(), "cor": UiTema.Y1, "sep": 3})
	if str(t.tip_tactic) != "":
		var extra := str(t.tip_tactic).to_upper()
		if str(t.tactic_name) != "":
			extra += ": " + str(t.tactic_name).to_upper()
		linhas.append({"texto": extra, "cor": UiTema.Y1})
	# Quando lutar (Fase 4): "VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE". Vazio na derrota por azar.
	if str(t.get("wait_green", "")) != "":
		linhas.append({"texto": str(t.wait_green).to_upper(), "cor": UiTema.GR3, "sep": 3})
	# Fase 5: dica extra (derrota na academia / com arte): mais uma linha na caixa, só se o rodapé ainda couber nos botões.
	if str(t.get("tip_extra", "")) != "":
		linhas.append({"texto": str(t.tip_extra).to_upper(), "cor": UiTema.Y1})
	# 7a1: nota da passiva da arte (só com arte e quando a passiva pesou) + a dica dela, logo depois da estatística.
	# A caixa só tem espaço para ~6 linhas sem encostar nos botões: com a nota, a dica genérica de atributo e a dica extra da
	# arte (que dizem o mesmo por outro caminho) cedem o lugar; a nota e a dica dela são mais específicas.
	if str(t.get("passive_note", "")) != "":
		var nova: Array = []
		for l in linhas:
			if l.texto == UiTema.singular(str(t.reason).to_upper()) or l.texto == UiTema.singular(str(t.stat).to_upper()):
				nova.append(l)
		var nota := {"texto": str(t.passive_note).to_upper(), "cor": UiTema.CREAM, "sep": 3}
		nova.append(nota)
		if str(t.get("passive_note_tip", "")) != "":
			nova.append({"texto": str(t.passive_note_tip).to_upper(), "cor": UiTema.Y1})
		for l in linhas:
			if not (l in nova) and str(l.texto) != str(t.tip).to_upper() and str(l.texto) != str(t.get("tip_extra", "")).to_upper():
				nova.append(l)
		linhas = nova
	var altura := 10.0
	for l in linhas:
		altura += 11.0 + float(l.get("sep", 0))
	fundo_cor(Rect2(126, 76, 388, altura), Color(UiTema.R0, 0.85))
	fundo_cor(Rect2(126, 76, 3, altura), UiTema.R2)
	# Azar (attribute == ""): sem ícone de atributo; o texto continua vindo só de textos_fim().
	var atr := str(f.reason.get("attribute", ""))
	if atr != "":
		UiTema.textura_rect(painel, "icon_" + atr, 135, 81)
	var y := 81.0
	for l in linhas:
		y += float(l.get("sep", 0))
		UiTema.rotulo(painel, l.texto, l.cor, 149, y, 360)
		y += 11.0
	# Com 6 linhas ou mais (arte + nota da passiva) o respiro abaixo da caixa encolhe para o rodapé não encostar nos botões.
	var topo := 76.0 + altura + (3.0 if linhas.size() >= 6 else 8.0)

	var mais := _resumo(f, topo, true)
	_rodape(f, topo + 78.0 + mais, false, "")


# --- Aposentadoria ---

func _montar_retire(f: Dictionary, t: Dictionary) -> void:
	moldura("ui_end_frame_retire", Rect2(110, 10, 420, 326))
	faixa_titulo("retire", Rect2(150, 20, 340, 22), str(t.title).to_upper(), UiTema.WHITE, 2)
	UiTema.rotulo_centro(painel, str(t.support).to_upper(), UiTema.P2, 320.0, 48.0)
	var belts := int(f.summary.get("belts", 0))
	var cinturao := belts > 0
	var regional := GameState.cinturao_regional()
	var amador := belts - (1 if regional else 0) > 0
	var luvas := UiTema.nome_luvas_penduradas()
	if GameState.campanha_completa():
		# Passou o posto depois de vencer o Kid: o selo da campanha completa fica preso no canto da moldura (como a folhinha do dia).
		var selo := UiTema.textura_rect(painel, "seal_campaign_complete", 108.0, 4.0)
		selo.name = "SeloCampanha"
	if amador or regional:
		# Luvas e cinturões lado a lado (8a1: o Cinturão do Vale também), o grupo centralizado na janela (o AnimSprite é desenhado a partir do pivô).
		var itens: Array = [{"nome": luvas, "anim": false}]
		if amador:
			itens.append({"nome": "belt_amateur_big", "anim": true})
		if regional:
			itens.append({"nome": "belt_regional_big", "anim": true})
		var folga := 24.0 if itens.size() < 3 else 16.0
		var total := folga * float(itens.size() - 1)
		for it in itens:
			total += UiTema.tamanho_quadro(str(it.nome)).x
		var x := roundf(320.0 - total / 2.0)
		for it in itens:
			var nome_it := str(it.nome)
			var q := UiTema.tamanho_quadro(nome_it)
			if bool(it.anim):
				var cint := AnimSprite.new()
				cint.definir(nome_it)
				cint.position = Vector2(x + UiTema.pivo(nome_it).x, 62.0 + 24.0 + (UiTema.pivo(nome_it).y - 24.0))
				cint.tocar([0, 1, 2], 6.0, true)
				painel.add_child(cint)
			else:
				UiTema.textura_rect(painel, nome_it, x, 62)
			x += q.x + folga
		if regional:
			UiTema.rotulo_centro(painel, UiTema.txt("belt_regional_unlock_done" if bool(GameState.permanente.get("center_reached", false)) else "belt_regional_unlock", "CENTRO DE TREINAMENTO LIBERADO").to_upper(), UiTema.Y1, 320.0, 115.0)
	else:
		# Luvas no meio da janela.
		var luvas_rect := UiTema.textura_rect(painel, luvas, roundf(320.0 - UiTema.tamanho_quadro(luvas).x / 2.0), 62)
		luvas_rect.set_meta("ui_pos", "center_h")
	var mais_r := _resumo(f, 126.0, false)
	_rodape(f, 126.0 + 78.0 + mais_r, cinturao, str(t.get("tip_extra", "")), regional)


# --- Partes comuns ---

func _resumo(f: Dictionary, y: float, com_retrato: bool) -> float:
	var s: Dictionary = f.summary
	var x := 172.0 if com_retrato else 150.0
	var borda := BORDA_DIR if com_retrato else BORDA_DIR - 20.0  # sem retrato o bloco é recuado 20 px dos dois lados
	if com_retrato:
		retrato(UiTema.nome_retrato_jogador(), "ui_portrait_frame", 130, y + 2, false)
	UiTema.rotulo(painel, GameState.titulo_resumo(), UiTema.CREAM, x, y)  # Fase 6b1: "RESUMO DE {NOME}"
	var linhas := [
		[UiTema.txt("sum_wins", "VITÓRIAS"), str(int(s.wins)), UiTema.WHITE],
		[UiTema.txt("sum_belts", "CINTURÕES"), str(int(s.belts)), UiTema.WHITE],
		[UiTema.txt("sum_fame", "FAMA"), str(int(s.fame)), UiTema.P2],
		[UiTema.txt("sum_money", "DINHEIRO GANHO"), UiTema.dinheiro(float(s.money_earned)), UiTema.Y1],
		[UiTema.txt("sum_time", "TEMPO DE JOGO"), UiTema.tempo(float(s.play_seconds)), UiTema.WHITE],
	]
	var yy := y + 14.0
	for l in linhas:
		UiTema.rotulo(painel, l[0], UiTema.G3, x, yy)
		var v := UiTema.rotulo(painel, l[1], l[2], 0, yy)
		v.position.x = roundf(borda - UiTema.largura_visivel(l[1]))
		yy += 11.0
	# Fase 5: a arte da carreira (sum_art), só quando houve uma. Devolve os px a mais que o resumo ocupou.
	var arte := str(s.get("art", ""))
	if arte != "":
		UiTema.rotulo(painel, UiTema.txt("sum_art", "ARTE"), UiTema.G3, x, yy)
		var nome_arte := GameState.nome_arte(arte).to_upper()
		var va := UiTema.rotulo(painel, nome_arte, UiTema.P2, 0, yy)
		va.position.x = roundf(borda - UiTema.largura_visivel(nome_arte))
		return 11.0
	return 0.0


func _rodape(f: Dictionary, y: float, cinturao: bool, dica_extra: String, regional: bool = false) -> void:
	divisor(126, y, 388)
	UiTema.textura_rect(painel, "icon_legacy_16", 130, y + 6)
	UiTema.rotulo(painel, UiTema.txt("sum_legacy_gain", "LEGADO GANHO"), UiTema.P2, 152, y + 10)
	_legado_ganho = UiTema.rotulo(painel, "+0", UiTema.P2, 0, y + 8)
	_legado_ganho.scale = Vector2(2, 2)
	_ganho = int(f.legacy_gained)
	_total = int(f.legacy_total)
	# Ganhos pequenos (< 5) já aparecem no valor final; só os maiores contam de 0 até o valor.
	_contar = _ganho >= 5 and not _reabrindo
	_posicionar_ganho("+%d" % (0 if _contar else _ganho))
	var yy := y + 28.0
	UiTema.rotulo(painel, UiTema.txt("sum_legacy_total", "LEGADO TOTAL"), UiTema.WHITE, 152, yy)
	var total_ini := _total - _ganho if _contar else _total
	_legado_total = UiTema.rotulo(painel, str(total_ini), UiTema.WHITE, 0, yy)
	_posicionar_total(str(total_ini))
	yy += 12.0
	if cinturao:
		var bonus := int(GameState.previa_aposentar().get("bonus", 0))
		if bonus > 0:
			UiTema.rotulo(painel, UiTema.txt("retire_confirm_bonus", "INCLUI +{n} POR SAIR COM O CINTURÃO", {"n": bonus}),
				UiTema.Y1, 152, yy)
			yy += 11.0
	if dica_extra != "":
		UiTema.rotulo(painel, dica_extra.to_upper(), UiTema.Y1, 152, yy)
		yy += 11.0
	# 8a2: a linha "a mudança chega na próxima versão" saiu da tela de fim: o texto agora é "USE O MUDAR" (vale só no HUD, antes de passar o posto).
	var retire := str(f.kind) == "retire"
	if retire:
		_linha_honra(f, yy)  # 6c2: "+N HONRA" (nunca na derrota; nunca no HUD)
	# Três botões na largura útil (130..510), 4 px entre eles: ÁRVORE (gastar o Legado) e MURAL (gastar a Honra no hall), pequenos,
	# e o principal RECEBER NOVO DISCÍPULO, maior. Quem não quer comprar nada clica 1 vez no principal e já está na garagem.
	# A fileira tem 1 botão largo de propósito (ui_align_row = free).
	painel.set_meta("ui_align_row", "free")
	_arvore_chamando = GameState.ha_no_compravel()
	_botao_arvore = UiTema.botao(painel, Rect2(130, 290, 94, 32))
	_botao_arvore.name = "BotaoArvore"
	UiTema.botao_conteudo(_botao_arvore, UiTema.txt("tree_button", "ÁRVORE"), UiTema.Y1 if _arvore_chamando else UiTema.WHITE, 1,
		"icon_skill_map", 5.0)
	_botao_arvore.pressed.connect(func() -> void: arvore_pedido.emit())
	for n in GameState.hall_lista():
		if str(n.state) == "buyable":
			_mural_chamando = true
	_botao_mural = UiTema.botao(painel, Rect2(228, 290, 94, 32))
	_botao_mural.name = "BotaoMural"
	UiTema.botao_conteudo(_botao_mural, UiTema.txt("mural_button", "MURAL"), UiTema.COL_HONOR if _mural_chamando else UiTema.WHITE, 1,
		"icon_honor_16", 5.0)
	_botao_mural.pressed.connect(func() -> void: mural_pedido.emit())
	# Fase 6b1: RECEBER NOVO DISCÍPULO (22 letras). Em escala 2 não cabe nos 184 px do botão: usa NOVO DISCÍPULO (plano B do Roteirista).
	var texto_botao := UiTema.txt("new_disciple_button", "RECEBER NOVO DISCÍPULO")
	if UiTema.largura_visivel(texto_botao) * 2.0 > 184.0 - 12.0:
		texto_botao = UiTema.txt("new_disciple_button_short", "NOVO DISCÍPULO")
	var b := botao_texto(Rect2(326, 290, 184, 32), texto_botao,
		UiTema.P2 if retire else UiTema.WHITE, "ui_button_normal", 2, "ui_button_retire" if retire else "")
	b.name = "BotaoNovoDiscipulo"
	b.pressed.connect(func() -> void: nova_carreira_pedido.emit())


## Honra da saída (design 6c2 §2.3): "+N HONRA" com a roseta e o saldo à direita; com 0 vitórias, o aviso `retire_no_honor`.
func _linha_honra(f: Dictionary, y: float) -> void:
	var ganho := int(f.get("honor_gained", 0))
	if ganho <= 0:
		UiTema.rotulo(painel, UiTema.txt("retire_no_honor", "HONRA SÓ COM 1 VITÓRIA"), UiTema.G2, 152, y)
		return
	var icone := UiTema.textura_rect(painel, "icon_honor", 152, y)
	icone.name = "IconeHonra"
	var texto := UiTema.txt("end_honor_gain", "+{n} HONRA", {"n": NumberFormat.fmt(float(ganho))})
	var l := UiTema.rotulo(painel, texto, UiTema.COL_HONOR, 164, y)
	l.name = "HonraGanha"
	var saldo := UiTema.txt("mural_honor_balance", "HONRA: {n}", {"n": NumberFormat.fmt(float(GameState.honra()))})
	var s := UiTema.rotulo(painel, saldo, UiTema.G3, 0, y)
	s.position.x = roundf(BORDA_DIR - UiTema.largura_visivel(saldo))
	if not _reabrindo:
		l.modulate = Color(1.8, 1.8, 1.8)
		l.create_tween().tween_property(l, "modulate", Color.WHITE, 0.5)


func _process(delta: float) -> void:
	_t += delta
	if _botao_arvore != null and _arvore_chamando:
		var k := 0.5 + 0.5 * sin(_t * 4.0)
		_botao_arvore.modulate = Color.WHITE.lerp(Color(1.2, 1.15, 1.0), k)
	if _botao_mural != null and _mural_chamando:
		_botao_mural.modulate = Color.WHITE.lerp(Color(1.2, 1.2, 1.25), 0.5 + 0.5 * sin(_t * 4.0))


func _posicionar_ganho(texto: String) -> void:
	_legado_ganho.text = texto
	_legado_ganho.position.x = roundf(BORDA_DIR - UiTema.largura_visivel(texto) * 2.0)


func _posicionar_total(texto: String) -> void:
	_legado_total.text = texto
	_legado_total.position.x = roundf(BORDA_DIR - UiTema.largura_visivel(texto))


# Contagem: o Legado ganho sobe até o valor e o total acompanha (já foi somado pelo GameState).
func _animar_legado() -> void:
	if not _contar:
		return
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_method(func(p: float) -> void:
		var parte := int(floorf(_ganho * p + 0.0001))
		_posicionar_ganho("+%d" % parte)
		_posicionar_total(str(_total - _ganho + parte)), 0.0, 1.0, 0.7)
	tw.tween_callback(func() -> void:
		_posicionar_ganho("+%d" % _ganho)
		_posicionar_total(str(_total))
		if _ganho > 0:
			_legado_ganho.modulate = Color(1.8, 1.8, 1.8)
			_legado_ganho.create_tween().tween_property(_legado_ganho, "modulate", Color.WHITE, 0.35)
			sfx.moeda())
