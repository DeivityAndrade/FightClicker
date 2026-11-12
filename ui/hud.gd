class_name Hud
extends Control
## Barra do topo: Treino (+/s), Dinheiro, Fama, Legado em jogo, Carreira N e nome do local.
## Só lê o GameState. Os grupos se reposicionam em fila quando o texto muda de tamanho.

const FOLGA := 10.0

var _grupos: Array[Dictionary] = []  # {icone, rotulo, valor, extra, cor, ultimo}
var _carreira: Label
var _local: Label
var _local_icone: TextureRect  # Fase 5: ícone da academia ao lado de "ACADEMIA: TREINO x2"
var _ultimo := ""
var _ultimo_dinheiro := -1.0
var _tween_dinheiro: Tween
var _emblema: Control  # "LEGADO: N NÓS" (Fase 4): passar o mouse abre a lista dos nós ativos
var _emblema_rotulo: Label
var _emblema_fundo: NinePatchRect
var _dica_nos: Control
var _area_local: Control


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 18)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui: Dictionary = GameState.dados.ui
	UiTema.painel(self, "ui_panel", Rect2(0, 0, 640, 18))

	# Fase 5.1: Treino é o número-herói (txt_hero, verde); Dinheiro em dourado; Fama e Legado descem para o nível 3
	# (só ícone + número pequeno à direita; o texto aparece na dica ao passar o mouse).
	_grupos.append(_grupo("icon_treino", str(ui.get("hud_training", "TREINO")).to_upper(), UiTema.COL_TREINO, true))
	_grupos.append(_grupo("icon_money", "", UiTema.COL_MONEY, false))
	_grupos.append(_grupo("icon_fame", "", UiTema.COL_FAME, false))
	_grupos.append(_grupo("icon_legacy", "", UiTema.COL_LEGACY, false))
	_grupos[0].valor.scale = Vector2(2, 2)
	_grupos[0].valor.position.y = -2.0
	UiTema.alinhar(_grupos[0].valor, "ignore")  # número-herói em escala 2: o verificador não cobra a caixa do rótulo
	_carreira = UiTema.rotulo(self, "", UiTema.COL_TEXT_2, 0, 3)
	_local = UiTema.rotulo(self, str(ui.get("location_name", "")).to_upper(), UiTema.COL_TEXT_2, 400, 3, 234,
		HORIZONTAL_ALIGNMENT_RIGHT)

	_local.autowrap_mode = TextServer.AUTOWRAP_OFF  # a largura do rótulo acompanha o texto (calculada em _reposicionar)
	_local.custom_minimum_size = Vector2.ZERO
	_local_icone = UiTema.textura_rect(self, "icon_location_gym", 0, 4)
	_local_icone.visible = false
	_emblema = Control.new()
	_emblema.mouse_filter = Control.MOUSE_FILTER_PASS
	_emblema.size = Vector2(60, 11)
	_emblema.position = Vector2(0, 3)
	_emblema.visible = false
	_emblema.mouse_entered.connect(_abrir_dica_nos)
	_emblema.mouse_exited.connect(_fechar_dica_nos)
	add_child(_emblema)
	_emblema_fundo = UiTema.nine_patch(_emblema, "ui_legacy_nodes_badge", Rect2(0, 0, 60, 11))
	_emblema_rotulo = UiTema.rotulo(_emblema, "", UiTema.P2, 5, 0)

	_areas_dica()
	GameState.dinheiro_mudou.connect(_ao_dinheiro)
	GameState.permanente_mudou.connect(atualizar)
	GameState.local_mudou.connect(func(_l: String) -> void: atualizar())
	atualizar()


func _grupo(icone: String, titulo: String, cor: Color, com_taxa: bool) -> Dictionary:
	var g := {"cor": cor, "ultimo": ""}
	g["icone"] = UiTema.textura_rect(self, icone, 0, 4)
	g["rotulo"] = UiTema.rotulo(self, titulo, UiTema.COL_TEXT_2, 0, 3)
	g["valor"] = UiTema.rotulo(self, "0", cor, 0, 3)
	g["extra"] = UiTema.rotulo(self, "", UiTema.COL_TREINO, 0, 3) if com_taxa else null
	return g


func atualizar() -> void:
	var textos: Array[String] = [
		NumberFormat.fmt(GameState.treino, NumberFormat.TRUNCAR),
		NumberFormat.fmt(GameState.dinheiro, NumberFormat.TRUNCAR),
		str(GameState.fama),
		str(GameState.legado_em_jogo()),
	]
	var taxa := "+%s/S" % NumberFormat.fmt(GameState.producao_total())
	var carreira := UiTema.txt("hud_career", "CARREIRA {n}", {"n": GameState.numero_carreira()})
	var legado: Dictionary = GameState.resumo_legado()
	# Nome do local à direita: na academia vira "ACADEMIA: TREINO x2" (verde, com o ícone); na garagem, o nome de sempre.
	var texto_local := GameState.texto_hud_local().to_upper()
	var chave := "|".join(textos) + "|" + taxa + "|" + carreira + "|" + str(legado.label if int(legado.count) > 0 else "") + "|" + texto_local
	if chave == _ultimo:
		return
	_ultimo = chave
	var tem_nos := int(legado.count) > 0
	_emblema.visible = tem_nos
	if tem_nos:
		var texto := str(legado.label).to_upper()
		_emblema_rotulo.text = texto
		var w := roundf(UiTema.largura_visivel(texto)) + 10.0
		_emblema.size = Vector2(w, 11)
		_emblema_fundo.size = Vector2(w, 11)
	else:
		_fechar_dica_nos()
	for i in _grupos.size():
		_grupos[i].valor.text = ("$ " if i == 1 else "") + textos[i]
	_grupos[0].extra.text = taxa
	_carreira.text = carreira
	var na_academia := texto_local != ""
	_local.text = texto_local if na_academia else str(GameState.dados.ui.get("location_name", "")).to_upper()
	_local.add_theme_color_override("font_color", UiTema.GR3 if na_academia else UiTema.COL_TEXT_2)
	_reposicionar()


# Fila da esquerda para a direita: Treino (ícone, rótulo, número-herói, +X/s), Dinheiro (ícone + valor), Carreira e o
# emblema do Legado permanente. À direita (de fora para dentro): Legado em jogo, Fama (só ícone + número) e o nome do local.
func _reposicionar() -> void:
	var x := 6.0
	var t: Dictionary = _grupos[0]
	t.icone.position.x = x
	x += 12.0
	t.rotulo.position.x = x
	x += UiTema.largura(t.rotulo.text) + 5.0
	t.valor.position.x = x
	x += UiTema.largura(t.valor.text) * 2.0 + 6.0
	t.extra.position.x = x
	x += UiTema.largura(t.extra.text) + FOLGA
	var m: Dictionary = _grupos[1]
	m.icone.position.x = x
	x += 12.0
	m.valor.position.x = x
	x += UiTema.largura(m.valor.text) + FOLGA
	_carreira.position.x = x + 2.0
	var fim := _carreira.position.x + UiTema.largura(_carreira.text)
	if _emblema.visible:
		_emblema.position.x = fim + 8.0
		fim = _emblema.position.x + _emblema.size.x
	# Grupo de nível 3, colado à direita: Fama e Legado em jogo (ícone + número, sem palavras).
	var xr := 634.0
	for i in [3, 2]:
		var g: Dictionary = _grupos[i]
		var w := UiTema.largura_visivel(g.valor.text)
		xr -= w
		g.valor.position.x = xr
		xr -= 11.0
		g.icone.position.x = xr
		var area: Control = g.area
		area.position = Vector2(xr - 2.0, 0)
		area.size = Vector2(w + 13.0 + 2.0, 18)
		xr -= 10.0
	# O nome do local só aparece se couber (na academia, com o ícone de 9 px + 3 de folga à esquerda do texto).
	var na_academia := GameState.em_academia()
	var largura_local := UiTema.largura_visivel(_local.text) + (12.0 if na_academia else 0.0)
	_local.visible = fim + 8.0 < xr - largura_local
	_local_icone.visible = _local.visible and na_academia
	_local.position.x = roundf(xr + 4.0 - UiTema.largura_visivel(_local.text))
	_local.size.x = UiTema.largura_visivel(_local.text) + 1.0
	_local_icone.position.x = _local.position.x - 12.0
	_area_local.visible = _local.visible
	_area_local.position = Vector2(_local_icone.position.x if na_academia else _local.position.x - 2.0, 0)
	_area_local.size = Vector2(xr + 4.0 - _area_local.position.x + 2.0, 18)


## Áreas de hover do nível 3: Fama, Legado em jogo e o nome do local (descrição do local + arte da carreira).
func _areas_dica() -> void:
	var textos := {2: "hint_fame", 3: "hint_legacy"}
	for i in [2, 3]:
		var a := Control.new()
		a.mouse_filter = Control.MOUSE_FILTER_PASS
		UiTema.alinhar(a, "ignore")
		add_child(a)
		var chave: String = textos[i]
		var idx: int = i
		a.mouse_entered.connect(func() -> void: Dica.pedir(_texto_dica(chave, idx)))
		a.mouse_exited.connect(func() -> void: Dica.limpar())
		_grupos[i]["area"] = a
	_area_local = Control.new()
	_area_local.mouse_filter = Control.MOUSE_FILTER_PASS
	UiTema.alinhar(_area_local, "ignore")
	add_child(_area_local)
	_area_local.mouse_entered.connect(func() -> void: Dica.pedir(texto_dica_local()))
	_area_local.mouse_exited.connect(func() -> void: Dica.limpar())


func _texto_dica(chave: String, i: int) -> String:
	return "%s\n%s" % [GameState.texto_ui(chave), _grupos[i].valor.text]


## Descrição do local (saiu da coluna esquerda) e, com arte, o efeito dela.
func texto_dica_local() -> String:
	var amb := str(GameState.local_atual().get("ambience", ""))
	if amb == "":
		amb = str(GameState.dados.ui.get("location_ambience", ""))
	var arte := GameState.texto_hud_arte()
	return amb + ("\n" + arte if arte != "" else "")


## Lista dos nós ativos (o mesmo cartão do início da carreira), logo abaixo do rótulo. Não cobre o alvo central.
func _abrir_dica_nos() -> void:
	_fechar_dica_nos()
	var dados: Dictionary = GameState.cartao_inicio()
	if dados.is_empty():
		return
	var x := clampf(roundf(_emblema.position.x), 4.0, 640.0 - CartaoInicio.LARGURA - 4.0)
	_dica_nos = CartaoInicio.montar(self, dados, x, 20.0)
	_dica_nos.z_index = 3500  # acima da sala (os números flutuantes chegam a ~2900)
	_dica_nos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTema.alinhar(_dica_nos, "ignore")


func _fechar_dica_nos() -> void:
	if _dica_nos != null:
		_dica_nos.queue_free()
		_dica_nos = null


# Dinheiro mudou: o número "pula" 1 px e brilha (prêmio de luta, compra na loja).
func _ao_dinheiro(valor: float) -> void:
	atualizar()
	if _ultimo_dinheiro >= 0.0 and valor != _ultimo_dinheiro:
		var v: Label = _grupos[1].valor
		if _tween_dinheiro != null and _tween_dinheiro.is_valid():
			_tween_dinheiro.kill()
		var subiu := valor > _ultimo_dinheiro
		v.add_theme_color_override("font_color", UiTema.Y2 if subiu else UiTema.G3)
		v.position.y = 2.0 if subiu else 4.0
		_tween_dinheiro = create_tween()
		_tween_dinheiro.set_parallel(true)
		_tween_dinheiro.tween_property(v, "position:y", 3.0, 0.25)
		_tween_dinheiro.tween_method(func(t: float) -> void:
			v.add_theme_color_override("font_color", (UiTema.Y2 if subiu else UiTema.G3).lerp(UiTema.COL_MONEY, t)), 0.0, 1.0, 0.5)
	_ultimo_dinheiro = valor
