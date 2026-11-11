class_name BlocoProxima
extends Control
## "PRÓXIMA: {nome}" + selo de risco + prêmio, no painel esquerdo. Fase 4: quando ele é quem te derrubou ganha a fita
## "VOCÊ PERDEU PRA ELE", e a linha "ESPERE FICAR VERDE" aparece nas lutas em que a regra L1 manda esperar.
## Fase 5 (academia Boa Esquina):
##  - depois do cinturão, na garagem, o próximo adversário só luta na academia: "PRÓXIMA: MUDE PARA A ACADEMIA" e o cartão
##    da mudança com o botão MUDAR e o preço (apagado, com o motivo, se falta dinheiro). O botão só chama `GameState.mudar()`;
##  - com a escada completa: o cinturão e "VOCÊ VENCEU A ACADEMIA. APOSENTAR VALE MAIS.";
##  - com o adversário da academia PERIGOSO há 5 min: "APOSENTAR AGORA LEVA {n} DE LEGADO" (`dica_aposentar()`).
## Só lê o GameState (sinais `risco_proxima_mudou`, `escada_mudou`, `carreira_mudou`, `tatica_mudou`, `permanente_mudou`,
## `local_mudou`) e chama as funções públicas dele.

signal altura_mudou(altura: int)  # quanto o bloco ocupa (a caixa de informação do painel desce junto)

const ALTURA_CARTAO := 123.0
const LARGURA_CARTAO := 120.0

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
	_verde = UiTema.rotulo(_caixa, UiTema.txt("preview_wait_green", "ESPERE FICAR VERDE"), UiTema.Y1, 0, 0, 112)
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

	GameState.risco_proxima_mudou.connect(func(_a: String, _r: String) -> void: atualizar())
	GameState.escada_mudou.connect(atualizar)
	GameState.carreira_mudou.connect(atualizar)
	GameState.permanente_mudou.connect(atualizar)
	GameState.local_mudou.connect(func(_l: String) -> void: atualizar())
	GameState.economia_mudou.connect(_ao_economia)
	GameState.tatica_mudou.connect(func(_t: String) -> void: atualizar())
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
	var espere := bool(info.get("wait_green", false))
	var estado := GameState.estado_escada()
	var mud: Dictionary = GameState.mudanca() if opp.is_empty() and estado == "move" else {}
	var dica: Dictionary = GameState.dica_aposentar() if not opp.is_empty() else {}
	var texto_dica := str(dica.get("text", "")) if bool(dica.get("show", false)) else ""
	var chave := "%s|%s|%s|%s|%s|%s|%s|%s" % [opp.get("id", "fim"), rotulo, revanche, espere,
		GameState.texto_stake_win(opp) if not opp.is_empty() else "", estado, str(mud.get("state", "")), texto_dica]
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
	if opp.is_empty():
		_mostrar_sem_luta(estado, mud)
		return

	_icone_cinturao.visible = false
	_caixa.position.x = 4.0
	_largura_caixa(112.0)
	_nome.text = UiTema.txt("hud_next_fight", "PRÓXIMA: {nome}", {"nome": str(opp.name)})
	_nome.add_theme_color_override("font_color", UiTema.WHITE)
	_marca_area.visible = revanche
	_selo_area.visible = rotulo != ""
	if rotulo != "":
		_selo = UiTema.selo_risco(_selo_area, rotulo, 0, 0)
		if mudou_rotulo:
			_selo.modulate = Color(2.2, 2.2, 2.2)
			_selo.create_tween().tween_property(_selo, "modulate", Color.WHITE, 0.4)
	_verde.visible = espere
	# Prêmio com o bônus da árvore ("SE VENCER: $75 (+50%) + 15 FAMA (+50%)"): o texto vem pronto do GameState.
	_premio.visible = true
	_premio.text = GameState.texto_stake_win(opp).to_upper() if not bool(opp.belt) \
		else UiTema.txt("stake_belt", "SE VENCER: O CINTURÃO AMADOR")
	_premio.add_theme_color_override("font_color", UiTema.G3)
	_dica_ret.visible = texto_dica != ""
	_dica_ret.text = texto_dica.to_upper()
	_medir()


## Sem adversário agora: "move" (só luta na academia: cartão da mudança), "end" (escada completa) ou o aviso antigo.
func _mostrar_sem_luta(estado: String, mud: Dictionary) -> void:
	_marca_area.visible = false
	_selo_area.visible = false
	_verde.visible = false
	_dica_ret.visible = false
	if estado == "move" and str(mud.get("state", "")) in ["ready", "missing"]:
		_icone_cinturao.visible = false
		_caixa.position.x = 4.0
		_largura_caixa(112.0)
		_nome.text = UiTema.txt("hud_next_move", "PRÓXIMA: MUDE PARA A ACADEMIA")
		_nome.add_theme_color_override("font_color", UiTema.Y1)
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
	_nome.add_theme_color_override("font_color", UiTema.Y1)
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
		UiTema.rotulo(c, UiTema.txt("move_no_money", "Falta dinheiro"), UiTema.R3, 7, 71, 106)
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
	UiTema.rotulo(b, preco, UiTema.Y1 if pronto else UiTema.R2, x0 + iw + 4.0 + lt + 8.0, UiTema.y_texto(a))


## Largura dos rótulos da caixa. Com a caixa deslocada para dar lugar ao ícone, a largura diminui junto (fim em x=120).
func _largura_caixa(w: float) -> void:
	for c: Control in [_nome, _verde, _premio, _dica_ret, _marca_area, _selo_area, _cartao_area]:
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
