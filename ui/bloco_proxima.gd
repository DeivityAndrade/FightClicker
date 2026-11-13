class_name BlocoProxima
extends Control
## "PRÓXIMA: {nome}" + selo de risco + prêmio, no painel esquerdo. Fase 4: quando ele é quem te derrubou ganha a fita
## "VOCÊ PERDEU PRA ELE", e a linha "ESPERE FICAR VERDE" aparece nas lutas em que a regra L1 manda esperar.
## Fase 5 (academia Boa Esquina):
##  - depois do cinturão, na garagem, o próximo adversário só luta na academia: "PRÓXIMA: MUDE PARA A ACADEMIA" e o cartão
##    da mudança com o botão MUDAR e o preço (apagado, com o motivo, se falta dinheiro). O botão só chama `GameState.mudar()`;
##  - com a escada completa: o cinturão e "VOCÊ VENCEU A ACADEMIA. APOSENTAR VALE MAIS.";
##  - com o adversário da academia PERIGOSO há 5 min: "APOSENTAR AGORA LEVA {n} DE LEGADO" (`dica_aposentar()`).
## Fase 5.3 (calendário): no lugar do "PRÓXIMA:" entra a folhinha de parede: placa na cor do risco, o dia da campanha na
## folhinha, "Faltam X dias" na linha 1 e o adversário na linha 2, com o selo de risco logo abaixo. No dia da luta a placa
## fica vermelha-escura ("É HOJE!") e depois do Kid vira a folhinha dourada "CAMPANHA / COMPLETA". O dia virando rasga a
## folha (`fx_calendar_tear`). Com `seconds_per_day` = 0 (sem calendário) volta o "PRÓXIMA: {nome}" de antes.
## Só lê o GameState (sinais `risco_proxima_mudou`, `escada_mudou`, `carreira_mudou`, `tatica_mudou`, `permanente_mudou`,
## `local_mudou`, `dia_mudou`, `campanha_completa_mudou`) e chama as funções públicas dele.

signal altura_mudou(altura: int)  # quanto o bloco ocupa (a caixa de informação do painel desce junto)

const ALTURA_CARTAO := 123.0
const LARGURA_CARTAO := 120.0
const PLACA := Vector2(116, 26)  # placa 9-slice do calendário (by_data_id.campaign_calendar.hud.plate_rect)
const TEXTO_X := 28.0  # x do texto dentro da placa (text_x 35 - plate x 7)
const LARGURA_NOME := 85.0  # 116 - 28 - 3: o nome do adversário na linha 2 (abrevia se passar)

var _placa_area: Control
var _placa: NinePatchRect
var _pagina: Control  # folhinha 20x22
var _pagina_img: TextureRect
var _pagina_num: Label
var _linha1: Label
var _linha2: Label

var _caixa: VBoxContainer
var _nome: Label
var _marca_area: Control
var _marca: NinePatchRect
var _selo_area: Control
var _verde: Label
var _premio: Label
var _dica_ret: Label  # "APOSENTAR AGORA LEVA {n} DE LEGADO"
var _cartao_area: Control  # cartão da mudança (Fase 5)
var _cartao: Control
var _selo: Control
var _icone_cinturao: TextureRect
var _ultimo := ""
var _medindo := false
var _t_dica := 0.0
var _area_dica: Control


func _ready() -> void:
	position = Vector2(4, 113)
	size = Vector2(120, 76)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_icone_cinturao = UiTema.textura_rect(self, "icon_belt_amateur_9", 4, 1)
	_icone_cinturao.visible = false
	_caixa = VBoxContainer.new()
	_caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caixa.position = Vector2(4, 1)
	_caixa.size = Vector2(112, 74)
	_caixa.add_theme_constant_override("separation", 2)
	add_child(_caixa)
	_nome = UiTema.rotulo(_caixa, "", UiTema.WHITE, 0, 0, 112)
	_montar_placa()
	# Fita da revanche: 120 px (a largura toda do bloco, 4 px de margem em cada lado do painel), vai 4 px além da caixa.
	_marca_area = Control.new()
	_marca_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marca_area.custom_minimum_size = Vector2(112, 13)
	_caixa.add_child(_marca_area)
	_marca = UiTema.nine_patch(_marca_area, "ui_seal_revenge", Rect2(-4, 0, 120, 13))
	UiTema.rotulo_centrado(_marca, UiTema.area_nove("ui_seal_revenge", Vector2(120, 13)), UiTema.txt("revenge_mark", "VOCÊ PERDEU PRA ELE"),
		UiTema.CREAM)
	_marca_area.visible = false
	_selo_area = Control.new()
	_selo_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selo_area.custom_minimum_size = Vector2(112, 13)
	_caixa.add_child(_selo_area)
	_verde = UiTema.rotulo(_caixa, UiTema.txt("preview_wait_green", "ESPERE FICAR VERDE"), UiTema.COL_TEXT_2, 0, 0, 112)
	_verde.visible = false
	_premio = UiTema.rotulo(_caixa, "", UiTema.G3, 0, 0, 112)
	_dica_ret = UiTema.rotulo(_caixa, "", UiTema.P2, 0, 0, 112)
	_dica_ret.visible = false
	# Cartão da mudança: 120 px (como a fita da revanche, 4 px além da caixa de cada lado).
	_cartao_area = Control.new()
	_cartao_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cartao_area.custom_minimum_size = Vector2(112, ALTURA_CARTAO)
	_cartao_area.visible = false
	_caixa.add_child(_cartao_area)

	# Fase 5.1: o prêmio da luta é nível 3: ao passar o mouse no bloco aparece a dica (continua inteiro na prévia).
	_area_dica = Control.new()
	_area_dica.mouse_filter = Control.MOUSE_FILTER_PASS
	_area_dica.size = Vector2(120, 26)
	UiTema.alinhar(_area_dica, "ignore")
	add_child(_area_dica)
	_area_dica.mouse_entered.connect(func() -> void: Dica.pedir(_texto_premio()))
	_area_dica.mouse_exited.connect(func() -> void: Dica.limpar())
	GameState.risco_proxima_mudou.connect(func(_a: String, _r: String) -> void: atualizar())
	GameState.escada_mudou.connect(atualizar)
	GameState.carreira_mudou.connect(atualizar)
	GameState.permanente_mudou.connect(atualizar)
	GameState.local_mudou.connect(func(_l: String) -> void: atualizar())
	GameState.economia_mudou.connect(_ao_economia)
	GameState.tatica_mudou.connect(func(_t: String) -> void: atualizar())
	GameState.dia_mudou.connect(_ao_dia_mudou)
	GameState.campanha_completa_mudou.connect(atualizar)
	# Garante um primeiro cálculo do risco (200 lutas, milissegundos).
	if GameState.risco_proxima().get("rotulo", "") == "":
		GameState.atualizar_risco_hud()
	atualizar()


func _process(delta: float) -> void:
	# A dica de aposentar da academia depende de um relógio (5 min de PERIGOSO): confere 1 vez por segundo.
	_t_dica += delta
	if _t_dica >= 1.0:
		_t_dica = 0.0
		atualizar()


## O dinheiro mudou (prêmio de luta, compra): o cartão da mudança acende ou apaga. `atualizar()` só refaz se a chave mudou.
func _ao_economia() -> void:
	if _cartao_area.visible:
		atualizar()


func atualizar() -> void:
	var opp: Dictionary = GameState.proximo_adversario()
	var rotulo := ""
	if not opp.is_empty():
		var r: Dictionary = GameState.risco_proxima()
		if str(r.get("adversario", "")) == str(opp.id):
			rotulo = str(r.get("rotulo", ""))
	var info: Dictionary = GameState.info_proxima()
	var revanche := bool(info.get("revenge", false))
	var espere := bool(info.get("wait_green", false)) and not GameState.no_dia_da_luta()
	var estado := GameState.estado_escada()
	var mud: Dictionary = GameState.mudanca() if opp.is_empty() and estado == "move" else {}
	var dica: Dictionary = GameState.dica_aposentar() if not opp.is_empty() else {}
	var texto_dica := _texto_dica_posto(dica) if bool(dica.get("show", false)) else ""
	# Fase 5.3: a folhinha do calendário (data da luta) ou, depois do Kid, a folhinha dourada.
	var cal := GameState.calendario_ligado()
	var dias := GameState.dias_para_luta() if cal and not opp.is_empty() else -1
	var completa := cal and opp.is_empty() and estado == "end"
	var placa := (dias >= 0) or completa
	var dia := mini(GameState.dia_campanha(), 99) if dias >= 0 else 0
	var chave := "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [opp.get("id", "fim"), rotulo, revanche, espere,
		GameState.texto_stake_win(opp) if not opp.is_empty() else "", estado, str(mud.get("state", "")), texto_dica,
		dias, dia, completa]
	if chave == _ultimo:
		return
	var mudou_rotulo := _ultimo != "" and _ultimo.split("|")[0] == chave.split("|")[0]
	_ultimo = chave

	if _selo != null:
		_selo.queue_free()
		_selo = null
	_cartao_area.visible = false
	if _cartao != null:
		_cartao.queue_free()
		_cartao = null
	_area_dica.visible = false
	_placa_area.visible = false
	_ordenar(placa)
	if opp.is_empty():
		_mostrar_sem_luta(estado, mud, completa)
		return

	_icone_cinturao.visible = false
	_caixa.position.x = 4.0
	_largura_caixa(112.0)
	_nome.visible = not placa
	if placa:
		_mostrar_placa(dias, rotulo, str(opp.name))
	_nome.text = UiTema.txt("hud_next_fight", "PRÓXIMA: {nome}", {"nome": str(opp.name)})
	_nome.add_theme_color_override("font_color", UiTema.WHITE)
	_marca_area.visible = revanche
	_selo_area.visible = rotulo != ""
	if rotulo != "":
		_selo = UiTema.selo_risco(_selo_area, rotulo, TEXTO_X - 2.0 if placa else 0.0, 0)
		if mudou_rotulo:
			_selo.modulate = Color(2.2, 2.2, 2.2)
			_selo.create_tween().tween_property(_selo, "modulate", Color.WHITE, 0.4)
	_verde.visible = espere
	# Fase 5.1: o prêmio saiu do bloco (nível 3); ele aparece na dica do bloco e inteiro na prévia.
	_premio.visible = false
	_area_dica.visible = true
	_premio.add_theme_color_override("font_color", UiTema.G3)
	_dica_ret.visible = texto_dica != ""
	_dica_ret.text = texto_dica.to_upper()
	_medir()


## Folhinha (20x22) + placa 9-slice + as duas linhas de texto. Montada uma vez; `_mostrar_placa` só troca sprites e textos.
func _montar_placa() -> void:
	_placa_area = Control.new()
	_placa_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placa_area.custom_minimum_size = Vector2(112, PLACA.y)
	_placa_area.visible = false
	_caixa.add_child(_placa_area)
	# A placa tem 116 px: 2 px além da caixa de cada lado (margem 6 | 6 no painel de 128).
	_placa = UiTema.nine_patch(_placa_area, "ui_countdown_plate_even", Rect2(-2, 0, PLACA.x, PLACA.y))
	_pagina = Control.new()
	_pagina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pagina.size = Vector2(20, 22)
	_placa.add_child(_pagina)
	_pagina.position = Vector2(4, 2)  # folhinha em (4, 2) da placa
	var recorte := Control.new()  # a folha tem 2 quadros lado a lado: o recorte mostra um só
	recorte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recorte.size = Vector2(20, 22)
	recorte.clip_contents = true
	_pagina.add_child(recorte)
	_pagina_img = UiTema.textura_rect(recorte, "ui_calendar_page", 0, 0)
	_pagina_num = UiTema.rotulo_centrado(_pagina, Rect2(2, 10, 15, 9), "", UiTema.D1, 1, false, "center_h")
	_pagina_num.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))  # número sobre papel claro: sem sombra
	_linha1 = UiTema.rotulo(_placa, "", UiTema.COL_TEXT_1, TEXTO_X, 5)
	_linha2 = UiTema.rotulo(_placa, "", UiTema.COL_TEXT_2, TEXTO_X, 15)
	UiTema.alinhar(_linha1, "left")
	UiTema.alinhar(_linha2, "left")


## Selo de risco logo abaixo da placa (a fita da revanche vem depois); sem calendário, a ordem de antes.
func _ordenar(placa: bool) -> void:
	if placa:
		_caixa.move_child(_placa_area, _nome.get_index() + 1)
		_caixa.move_child(_selo_area, _placa_area.get_index() + 1)
	else:
		_caixa.move_child(_selo_area, _marca_area.get_index() + 1)


## Placa da próxima luta: cor do risco, dia na folhinha, "Faltam X dias" / "Falta 1 dia" / "É HOJE!" e o adversário.
func _mostrar_placa(dias: int, rotulo: String, nome: String) -> void:
	var hud: Dictionary = UiTema.manifest().get("by_data_id", {}).get("campaign_calendar", {}).get("hud", {})
	var hoje := dias <= 0
	var por_risco: Dictionary = hud.get("plate_by_risk", {})
	var placa_nome := str(hud.get("plate_fight_day", "ui_countdown_plate_today")) if hoje \
		else str(por_risco.get("risk_" + rotulo, "ui_countdown_plate_even"))
	_placa.texture = UiTema.textura(placa_nome)
	_placa_area.visible = true
	_pagina_img.texture = _quadro_pagina(str(hud.get("page", "ui_calendar_page")), 1 if hoje else 0)  # quadro 1 = o dia circulado de caneta
	_pagina_num.visible = true
	_pagina_num.text = str(mini(GameState.dia_campanha(), 99))
	if hoje:
		_linha1.text = UiTema.txt("hud_fight_today", "É HOJE!")
		_linha1.add_theme_color_override("font_color", UiTema.Y2)
	else:
		_linha1.text = UiTema.txt("hud_fight_date_one" if dias == 1 else "hud_fight_date", "Faltam {n} dias", {"n": dias})
		_linha1.add_theme_color_override("font_color", UiTema.COL_TEXT_1)
	_linha2.text = _nome_curto(nome.to_upper(), LARGURA_NOME)
	_linha2.add_theme_color_override("font_color", UiTema.COL_TEXT_2)


## Depois do Kid: folhinha dourada com estrela (sem número) e "CAMPANHA / COMPLETA" em dourado nas duas linhas.
func _mostrar_placa_completa() -> void:
	var hud: Dictionary = UiTema.manifest().get("by_data_id", {}).get("campaign_calendar", {}).get("hud", {})
	_placa.texture = UiTema.textura(str(hud.get("plate_done", "ui_countdown_plate_done")))
	_placa_area.visible = true
	_pagina_img.texture = UiTema.textura(str(hud.get("page_done", "icon_campaign_complete")))
	_pagina_num.visible = false
	var partes := UiTema.txt("hud_campaign_complete", "CAMPANHA\nCOMPLETA").split("\n")  # o \n do texto vira quebra de linha
	_linha1.text = partes[0]
	_linha2.text = partes[1] if partes.size() > 1 else ""
	_linha1.add_theme_color_override("font_color", UiTema.COL_MONEY)
	_linha2.add_theme_color_override("font_color", UiTema.COL_MONEY)


## Nome que cabe na linha 2: tira palavras do fim ("BRUTÃO DO POSTO" -> "BRUTÃO") até caber; nunca termina em "DO"/"DA"/"DE".
func _nome_curto(nome: String, max_: float) -> String:
	var palavras := nome.split(" ")
	while palavras.size() > 1 and UiTema.largura_visivel(" ".join(palavras)) > max_:
		palavras.remove_at(palavras.size() - 1)
	while palavras.size() > 1 and palavras[palavras.size() - 1].length() <= 2:
		palavras.remove_at(palavras.size() - 1)
	return " ".join(palavras)


## "PASSAR O POSTO AGORA LEVA {n} DE LEGADO" em até 2 linhas na caixa de 112 px; com mais que isso, a versão curta.
func _texto_dica_posto(dica: Dictionary) -> String:
	var n := int(dica.get("legacy", 0))
	var longo := str(dica.get("text", "")).to_upper()
	if _linhas_do_texto(longo, 112.0) <= 2:
		return longo
	return UiTema.txt("retire_hint_short", "PASSAR O POSTO LEVA {n} DE LEGADO", {"n": n})


func _linhas_do_texto(texto: String, largura_: float) -> int:
	var tp := TextParagraph.new()
	tp.add_string(texto, UiTema.fonte(), UiTema.TAMANHO_FONTE)
	tp.width = largura_
	tp.break_flags = TextServer.BREAK_WORD_BOUND | TextServer.BREAK_MANDATORY
	return tp.get_line_count()


## O dia virou: a folha é arrancada por cima da folhinha (uma vez, 12 fps); o número novo já aparece embaixo.
func _ao_dia_mudou(_dia: int) -> void:
	atualizar()
	if _placa_area == null or not _placa_area.visible or not _pagina_num.visible:
		return
	var fx := AnimSprite.new()
	fx.definir("fx_calendar_tear")
	fx.z_index = 2
	_pagina.add_child(fx)  # pivô (6,10) no canto de cima à esquerda da folhinha
	fx.tocar([0, 1, 2, 3], 12.0, false, fx.queue_free)


## Sem adversário agora: "move" (só luta na academia: cartão da mudança), "end" (escada completa) ou o aviso antigo.
func _mostrar_sem_luta(estado: String, mud: Dictionary, completa: bool = false) -> void:
	_marca_area.visible = false
	_selo_area.visible = false
	_verde.visible = false
	_dica_ret.visible = false
	_nome.visible = true
	if completa:
		# Depois do Kid: a folhinha dourada "CAMPANHA / COMPLETA" e, embaixo, o aviso de que passar o posto vale mais.
		_icone_cinturao.visible = false
		_caixa.position.x = 4.0
		_largura_caixa(112.0)
		_nome.visible = false
		_mostrar_placa_completa()
		_premio.visible = true
		_premio.text = UiTema.txt("no_more_fights_gym", "CAMPANHA COMPLETA. PASSAR O POSTO VALE MAIS.")
		_premio.add_theme_color_override("font_color", UiTema.P2)
		_medir()
		return
	if estado == "move" and str(mud.get("state", "")) in ["ready", "missing"]:
		_icone_cinturao.visible = false
		_caixa.position.x = 4.0
		_largura_caixa(112.0)
		_nome.text = UiTema.txt("hud_next_move", "PRÓXIMA: MUDE PARA A ACADEMIA")
		_nome.add_theme_color_override("font_color", UiTema.COL_TEXT_1)
		_premio.visible = false
		_montar_cartao_mudanca(mud)
		_medir()
		return
	_icone_cinturao.visible = true
	# O título recua 12 px com espaços (abaixo) e a caixa mantém 112 px: o texto longo da academia cabe sem sair do painel.
	_caixa.position.x = 4.0
	_largura_caixa(112.0)
	_premio.visible = true
	# O ícone do cinturão fica à esquerda do título (a caixa mantém os 112 px: o texto longo da academia não sai do painel).
	var recuo := " ".repeat(int(ceil(12.0 / maxf(1.0, UiTema.largura(" ")))))
	_nome.text = recuo + UiTema.txt("belt_title", "CINTURÃO AMADOR")
	_nome.add_theme_color_override("font_color", UiTema.COL_TEXT_1)
	if estado == "end":
		_premio.text = UiTema.txt("no_more_fights_gym", "VOCÊ VENCEU A ACADEMIA. APOSENTAR VALE MAIS.")
		_premio.add_theme_color_override("font_color", UiTema.P2)
	else:
		_premio.text = UiTema.txt("no_more_fights", "SEM MAIS ADVERSÁRIOS POR ENQUANTO")
		_premio.add_theme_color_override("font_color", UiTema.G2)
	_medir()


func _largura_textos(w: float) -> void:
	_caixa.size.x = w
	for l in [_nome, _premio]:
		l.custom_minimum_size = Vector2(w, 0)
		l.size = Vector2(w, l.size.y)


## Cartão da mudança: ícone + nome da academia, o efeito, "tudo o que você comprou vai junto", "vale até o fim desta carreira"
## (ou "falta dinheiro") e o botão MUDAR com o preço. Papelão claro quando dá para pagar, escuro quando não.
func _montar_cartao_mudanca(d: Dictionary) -> void:
	var pronto := str(d.state) == "ready"
	var info: Dictionary = UiTema.manifest().get("by_data_id", {}).get("move_gym", {})
	var nome_cartao := str(info.get("card", {}).get("ready" if pronto else "dim", "ui_move_card"))
	_cartao_area.visible = true
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = Vector2(-4, 0)
	c.size = Vector2(LARGURA_CARTAO, ALTURA_CARTAO)
	_cartao_area.add_child(c)
	_cartao = c
	UiTema.nine_patch(c, nome_cartao, Rect2(0, 0, LARGURA_CARTAO, ALTURA_CARTAO))
	UiTema.textura_rect(c, str(info.get("icon", "icon_move")), 6, 5)
	UiTema.rotulo(c, str(d.title).to_upper(), UiTema.WHITE if pronto else UiTema.G3, 26, 3, 88)
	UiTema.rotulo(c, str(d.effect_text).to_upper(), UiTema.GR3 if pronto else UiTema.GR2, 7, 27, 106)
	UiTema.rotulo(c, str(d.keeps_text).to_upper(), UiTema.CREAM if pronto else UiTema.G2, 7, 49, 106)
	if pronto:
		UiTema.rotulo(c, str(d.per_career_text).to_upper(), UiTema.G2, 7, 71, 106)
	else:
		UiTema.rotulo(c, UiTema.txt("move_no_money", "Falta dinheiro"), UiTema.COL_TEXT_2, 7, 71, 106)
	var b := UiTema.botao_estilizado(c, Rect2(7, 92, 106, 26), "ui_button_move")
	b.disabled = not pronto
	_conteudo_botao_mudar(b, str(d.button).to_upper(), str(d.price_text), pronto)
	b.pressed.connect(func() -> void:
		GameState.mudar()
		atualizar())
	UiTema.alinhar(b, "center")


## Ícone + "MUDAR" + preço como um grupo centralizado na face do botão (o preço em dourado; apagado: texto cinza, preço vermelho).
func _conteudo_botao_mudar(b: Button, texto: String, preco: String, pronto: bool) -> void:
	var a := UiTema.area_botao(b)
	var iw := UiTema.tamanho_quadro("icon_move").x
	var ih := UiTema.tamanho_quadro("icon_move").y
	var lt := UiTema.largura_visivel(texto)
	var lp := UiTema.largura_visivel(preco)
	var total := iw + 4.0 + lt + 8.0 + lp
	var x0 := roundf(a.position.x + (a.size.x - total) / 2.0)
	UiTema.textura_rect(b, "icon_move", x0, UiTema.y_imagem(a, ih))
	UiTema.rotulo(b, texto, UiTema.Y2 if pronto else UiTema.G1, x0 + iw + 4.0, UiTema.y_texto(a))
	UiTema.rotulo(b, preco, UiTema.COL_MONEY if pronto else UiTema.COL_TEXT_2, x0 + iw + 4.0 + lt + 8.0, UiTema.y_texto(a))


## Largura dos rótulos da caixa. Com a caixa deslocada para dar lugar ao ícone, a largura diminui junto (fim em x=120).
func _largura_caixa(w: float) -> void:
	for c: Control in [_nome, _verde, _premio, _dica_ret, _marca_area, _selo_area, _cartao_area, _placa_area]:
		c.custom_minimum_size.x = w
		c.size.x = w
	_caixa.size.x = w  # depois dos filhos: a caixa nunca fica menor que o mínimo deles


## Mede a caixa depois que os rótulos quebraram linha (2 quadros) e avisa o painel.
func _medir() -> void:
	if _medindo:
		return
	_medindo = true
	await get_tree().process_frame
	await get_tree().process_frame
	_medindo = false
	if not is_inside_tree():
		return
	var h := int(ceil(_caixa.get_combined_minimum_size().y)) + 2
	size.y = float(h)
	altura_mudou.emit(h)


## Dica do prêmio (hint_prize / hint_prize_belt): o que antes ficava fixo no bloco.
func _texto_premio() -> String:
	var opp: Dictionary = GameState.proximo_adversario()
	if opp.is_empty():
		return ""
	if bool(opp.belt):
		return GameState.texto_ui("hint_prize_belt")
	return GameState.preencher(GameState.texto_ui("hint_prize"), {"dinheiro": NumberFormat.fmt(GameState.premio_dinheiro(opp)),
		"fama": NumberFormat.fmt(float(GameState.premio_fama(opp)))})


## Um quadro (20x22) da folha da folhinha, que tem os quadros lado a lado.
func _quadro_pagina(nome: String, quadro: int) -> Texture2D:
	var a := AtlasTexture.new()
	a.atlas = UiTema.textura(nome)
	var q := UiTema.tamanho_quadro(nome)
	a.region = Rect2(q.x * quadro, 0, q.x, q.y)
	return a
