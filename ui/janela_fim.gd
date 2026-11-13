class_name JanelaFim
extends JanelaBase
## Tela de fim de carreira, em dois modos:
##  - derrota ("FIM DE CARREIRA", moldura de concreto com fita vermelha): quem venceu e quando, o motivo principal
##    com número ("FALTARAM {n} DE ..."), a estatística da luta, a dica de ação, o resumo, Legado ganho e total;
##  - aposentadoria ("SAIU POR CIMA", moldura roxa com cantos dourados): luvas penduradas (e o cinturão, se houver).
## Só mostra o que o GameState já decidiu (`fim`, `textos_fim()`). Dois botões: ÁRVORE (gastar o Legado, Fase 4) e NOVA CARREIRA.

signal nova_carreira_pedido
signal arvore_pedido

## Borda direita dos números (a moldura vai de 110 a 530: 20 px de margem dos dois lados do conteúdo).
const BORDA_DIR := 510.0

var sfx: Sfx
var _botao_arvore: Button
var _arvore_chamando := false  # há nó para comprar: o botão ÁRVORE respira para chamar o clique
var _t := 0.0
var _legado_ganho: Label
var _legado_total: Label
var _ganho := 0
var _contar := false
var _total := 0


func abrir_com(fim: Dictionary, tocar_som: bool) -> void:
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

func _montar_derrota(f: Dictionary, t: Dictionary) -> void:
	moldura("ui_end_frame_defeat", Rect2(110, 10, 420, 322))
	faixa_titulo("defeat", Rect2(150, 20, 340, 22), str(t.title).to_upper(), UiTema.WHITE, 2)
	UiTema.rotulo_centro(painel, str(t.support).to_upper(), UiTema.G2, 320.0, 48.0)
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
	var topo := 76.0 + altura + 8.0

	var mais := _resumo(f, topo, true)
	_rodape(f, topo + 78.0 + mais, false, "")


# --- Aposentadoria ---

func _montar_retire(f: Dictionary, t: Dictionary) -> void:
	moldura("ui_end_frame_retire", Rect2(110, 10, 420, 322))
	faixa_titulo("retire", Rect2(150, 20, 340, 22), str(t.title).to_upper(), UiTema.WHITE, 2)
	UiTema.rotulo_centro(painel, str(t.support).to_upper(), UiTema.P2, 320.0, 48.0)
	var cinturao := int(f.summary.get("belts", 0)) > 0
	var luvas := UiTema.nome_luvas_penduradas()
	if GameState.campanha_completa():
		# Passou o posto depois de vencer o Kid: o selo da campanha completa fica preso no canto da moldura (como a folhinha do dia).
		var selo := UiTema.textura_rect(painel, "seal_campaign_complete", 108.0, 4.0)
		selo.name = "SeloCampanha"
	if cinturao:
		# Luvas e cinturão lado a lado, o par centralizado na janela (o AnimSprite é desenhado a partir do pivô).
		var larg_luvas := UiTema.tamanho_quadro(luvas).x
		var larg_cint := UiTema.tamanho_quadro("belt_amateur_big").x
		var x_luvas := roundf(320.0 - (larg_luvas + 24.0 + larg_cint) / 2.0)
		UiTema.textura_rect(painel, luvas, x_luvas, 62)
		var cint := AnimSprite.new()
		cint.definir("belt_amateur_big")
		cint.position = Vector2(x_luvas + larg_luvas + 24.0 + UiTema.pivo("belt_amateur_big").x, 62 + 24)
		cint.tocar([0, 1, 2], 6.0, true)
		painel.add_child(cint)
	else:
		# Luvas no meio da janela.
		var luvas_rect := UiTema.textura_rect(painel, luvas, roundf(320.0 - UiTema.tamanho_quadro(luvas).x / 2.0), 62)
		luvas_rect.set_meta("ui_pos", "center_h")
	var mais_r := _resumo(f, 126.0, false)
	_rodape(f, 126.0 + 78.0 + mais_r, cinturao, str(t.get("tip_extra", "")))


# --- Partes comuns ---

func _resumo(f: Dictionary, y: float, com_retrato: bool) -> float:
	var s: Dictionary = f.summary
	var x := 172.0 if com_retrato else 150.0
	var borda := BORDA_DIR if com_retrato else BORDA_DIR - 20.0  # sem retrato o bloco é recuado 20 px dos dois lados
	if com_retrato:
		retrato(UiTema.nome_retrato_jogador(), "ui_portrait_frame", 130, y + 2, false)
	UiTema.rotulo(painel, UiTema.txt("sum_title", "RESUMO DA CAMPANHA {n}", {"n": int(f.career_number)}), UiTema.CREAM, x, y)
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


func _rodape(f: Dictionary, y: float, cinturao: bool, dica_extra: String) -> void:
	divisor(126, y, 388)
	UiTema.textura_rect(painel, "icon_legacy_16", 130, y + 6)
	UiTema.rotulo(painel, UiTema.txt("sum_legacy_gain", "LEGADO GANHO"), UiTema.P2, 152, y + 10)
	_legado_ganho = UiTema.rotulo(painel, "+0", UiTema.P2, 0, y + 8)
	_legado_ganho.scale = Vector2(2, 2)
	_ganho = int(f.legacy_gained)
	_total = int(f.legacy_total)
	# Ganhos pequenos (< 5) já aparecem no valor final; só os maiores contam de 0 até o valor.
	_contar = _ganho >= 5
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
	# Dois botões do mesmo tamanho, 4 px entre eles, ocupando a largura útil (130..510): ÁRVORE (gastar o Legado) e NOVA CARREIRA.
	# Quem não quer comprar nada clica 1 vez em NOVA CARREIRA e já está na garagem.
	var retire := str(f.kind) == "retire"
	_arvore_chamando = false
	for n in GameState.arvore_nos():
		if str(n.state) == "buyable":
			_arvore_chamando = true
			break
	_botao_arvore = botao_texto(Rect2(130, 286, 188, 32), UiTema.txt("tree_button", "ÁRVORE"),
		UiTema.Y1 if _arvore_chamando else UiTema.WHITE, "ui_button_normal", 2)
	_botao_arvore.pressed.connect(func() -> void: arvore_pedido.emit())
	var b := botao_texto(Rect2(322, 286, 188, 32), UiTema.txt("new_career_button", "NOVA CAMPANHA"),
		UiTema.P2 if retire else UiTema.WHITE, "ui_button_normal", 2, "ui_button_retire" if retire else "")
	b.pressed.connect(func() -> void: nova_carreira_pedido.emit())


func _process(delta: float) -> void:
	_t += delta
	if _botao_arvore != null and _arvore_chamando:
		var k := 0.5 + 0.5 * sin(_t * 4.0)
		_botao_arvore.modulate = Color.WHITE.lerp(Color(1.2, 1.15, 1.0), k)


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
