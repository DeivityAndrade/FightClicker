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


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(640, 18)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui: Dictionary = GameState.dados.ui
	UiTema.painel(self, "ui_panel", Rect2(0, 0, 640, 18))

	_grupos.append(_grupo("icon_treino", str(ui.get("hud_training", "TREINO")).to_upper(), UiTema.WHITE, true))
	_grupos.append(_grupo("icon_money", UiTema.txt("hud_money", "DINHEIRO"), UiTema.Y1, false))
	_grupos.append(_grupo("icon_fame", UiTema.txt("hud_fame", "FAMA"), UiTema.P2, false))
	_grupos.append(_grupo("icon_legacy", UiTema.txt("hud_legacy_run", "LEGADO EM JOGO"), UiTema.P2, false))
	_carreira = UiTema.rotulo(self, "", UiTema.G3, 0, 3)
	_local = UiTema.rotulo(self, str(ui.get("location_name", "")).to_upper(), UiTema.G1, 400, 3, 234,
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

	GameState.dinheiro_mudou.connect(_ao_dinheiro)
	GameState.permanente_mudou.connect(atualizar)
	GameState.local_mudou.connect(func(_l: String) -> void: atualizar())
	atualizar()


func _grupo(icone: String, titulo: String, cor: Color, com_taxa: bool) -> Dictionary:
	var g := {"cor": cor, "ultimo": ""}
	g["icone"] = UiTema.textura_rect(self, icone, 0, 4)
	g["rotulo"] = UiTema.rotulo(self, titulo, UiTema.G3, 0, 3)
	g["valor"] = UiTema.rotulo(self, "0", cor if not com_taxa else UiTema.WHITE, 0, 3)
	g["extra"] = UiTema.rotulo(self, "", UiTema.GR3, 0, 3) if com_taxa else null
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
	_local.add_theme_color_override("font_color", UiTema.GR3 if na_academia else UiTema.G1)
	_reposicionar()


# Fila da esquerda para a direita: ícone, título, valor (e a taxa do Treino).
func _reposicionar() -> void:
	var x := 6.0
	for i in _grupos.size():
		var g: Dictionary = _grupos[i]
		g.icone.position.x = x
		x += 12.0
		g.rotulo.position.x = x
		x += UiTema.largura(g.rotulo.text) + 5.0
		g.valor.position.x = x
		x += UiTema.largura(g.valor.text) + 6.0
		if g.extra != null:
			g.extra.position.x = x
			x += UiTema.largura(g.extra.text)
		x += FOLGA
	_carreira.position.x = x + 2.0
	var fim := _carreira.position.x + UiTema.largura(_carreira.text)
	if _emblema.visible:
		_emblema.position.x = fim + 8.0
		fim = _emblema.position.x + _emblema.size.x
	# O nome do local só aparece se couber (na academia, com o ícone de 9 px + 3 de folga à esquerda do texto).
	var na_academia := GameState.em_academia()
	var largura_local := UiTema.largura_visivel(_local.text) + (12.0 if na_academia else 0.0)
	_local.visible = fim + 8.0 < 640.0 - 6.0 - largura_local
	_local_icone.visible = _local.visible and na_academia
	_local.position.x = roundf(634.0 - UiTema.largura_visivel(_local.text))
	_local.size.x = UiTema.largura_visivel(_local.text) + 1.0
	_local_icone.position.x = _local.position.x - 12.0


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
		v.add_theme_color_override("font_color", UiTema.Y2 if subiu else UiTema.R3)
		v.position.y = 2.0 if subiu else 4.0
		_tween_dinheiro = create_tween()
		_tween_dinheiro.set_parallel(true)
		_tween_dinheiro.tween_property(v, "position:y", 3.0, 0.25)
		_tween_dinheiro.tween_method(func(t: float) -> void:
			v.add_theme_color_override("font_color", (UiTema.Y2 if subiu else UiTema.R3).lerp(UiTema.Y1, t)), 0.0, 1.0, 0.5)
	_ultimo_dinheiro = valor
