class_name PainelAtributos
extends Control
## Atributos em miniatura (6d2): uma linha por atributo com ícone, barra de proporção e número (valor truncado). Sem título e sem
## nome: o ícone e a cor dizem qual é; o nome e a dica de cada atributo aparecem no balão ao passar o mouse.
## Fica no canto de cima à esquerda da sala. Só lê o GameState.

const LARGURA := 114.0
const Y := 20.0
const LINHA := 12.0
const Y_LINHAS := 3.0
const X_ICONE := 6.0
const X_BARRA := 18.0
const LARG_BARRA := 50.0
const X_NUMERO := 70.0  # o número ocupa x 70..108, alinhado à direita
const LARG_NUMERO := 38.0

var _linhas: Dictionary = {}  # atributo -> {fundo, valor, fill, bg}


func _ready() -> void:
	position = Vector2(0, Y)
	z_index = 1200
	size = Vector2(LARGURA, 43.0)
	mouse_filter = Control.MOUSE_FILTER_STOP  # a sala fica por baixo: o clique no painel não vai para ela
	set_meta("ui_margens", "h")  # conteúdo com a mesma margem à esquerda e à direita
	UiTema.painel(self, "ui_panel", Rect2(0, 0, LARGURA, size.y))

	var i := 0
	for id in GameState.dados.atributos:
		var y0 := Y_LINHAS + 2.0 + float(i) * LINHA
		var cor := UiTema.cor_atributo(id)
		var fundo := ColorRect.new()  # destaque do atributo que o foco atual treina
		fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fundo.color = Color(cor.r, cor.g, cor.b, 0.16)
		fundo.position = Vector2(4, y0 - 1)
		fundo.size = Vector2(LARGURA - 8.0, LINHA - 1.0)
		add_child(fundo)
		var area := Control.new()
		area.mouse_filter = Control.MOUSE_FILTER_PASS
		area.position = fundo.position
		area.size = fundo.size
		UiTema.alinhar(area, "ignore")
		var id_linha: String = id
		area.mouse_entered.connect(func() -> void: Dica.pedir(_texto_dica(id_linha), area))
		area.mouse_exited.connect(func() -> void: Dica.limpar())
		add_child(area)

		UiTema.textura_rect(self, "icon_" + id, X_ICONE, y0)
		var valor := UiTema.rotulo(self, "0", UiTema.WHITE, X_NUMERO, y0 - 1.0, LARG_NUMERO, HORIZONTAL_ALIGNMENT_RIGHT)
		UiTema.alinhar(valor, "right")
		var bg := NinePatchRect.new()
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.texture = UiTema.textura("ui_bar_bg")
		_margens_nove(bg, "ui_bar_bg")
		bg.position = Vector2(X_BARRA, y0 + 2.0)
		bg.size = Vector2(LARG_BARRA, 5)
		add_child(bg)
		var fill := NinePatchRect.new()
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.texture = UiTema.textura("ui_bar_fill_" + id)
		_margens_nove(fill, "ui_bar_fill_" + id)
		fill.position = Vector2(X_BARRA + 1.0, y0 + 3.0)
		fill.size = Vector2(2, 3)
		add_child(fill)
		_linhas[id] = {"fundo": fundo, "valor": valor, "fill": fill, "bg": bg}
		i += 1
	atualizar()


## Nome e dica do atributo (do JSON de dados) para o balão.
func _texto_dica(id: String) -> String:
	var inf: Dictionary = GameState.dados.atributo_info(id)
	return "%s\n%s" % [str(inf.get("name", id)).to_upper(), str(inf.get("hint", "")).to_upper()]


## O aparelho que treina o atributo ainda não chegou? (a barra fica apagada; o atributo vale na luta pelos 10% gerais)
func _trancado(atributo: String) -> bool:
	for ap in GameState.dados.aparelhos:
		if str(ap.attribute) == atributo and not GameState.aparelho_montado(str(ap.id)):
			return true
	return false


func _margens_nove(n: NinePatchRect, nome: String) -> void:
	var ns: Dictionary = UiTema.sprite(nome).get("nine_slice", {})
	n.patch_margin_left = int(ns.get("left", 1))
	n.patch_margin_top = int(ns.get("top", 1))
	n.patch_margin_right = int(ns.get("right", 1))
	n.patch_margin_bottom = int(ns.get("bottom", 1))


func atualizar() -> void:
	var total := 0.0
	for id in _linhas:
		total += float(GameState.atributos.get(id, 0.0))
	var foco_attr := GameState.atributo_do_aparelho(GameState.foco)
	for id in _linhas:
		var v := float(GameState.atributos.get(id, 0.0))
		var l: Dictionary = _linhas[id]
		l.valor.text = NumberFormat.fmt(v, NumberFormat.TRUNCAR)
		l.fundo.visible = id == foco_attr
		var trancado := _trancado(id)
		l.valor.add_theme_color_override("font_color", UiTema.COL_DISABLED if trancado else UiTema.WHITE)
		l.bg.modulate = Color(1, 1, 1, 0.45) if trancado else Color.WHITE
		# Barra = parte do treino total que foi para este atributo.
		var frac := v / total if total > 0.0 else 0.0
		var w := roundf((LARG_BARRA - 2.0) * frac)
		l.fill.visible = w >= 2.0 and not trancado
		l.fill.size = Vector2(maxf(w, 2.0), 3)
