class_name UiTema
extends RefCounted
## Paleta, fontes, sprites do manifest e fábricas de widgets pixel (rótulos, botões, painéis).
## Só aparência: nenhuma regra de jogo aqui.

const CAMINHO_MANIFEST := "res://assets/sprites/manifest.json"
const CAMINHO_FONTE := "res://assets/sprites/font/fightclicker_5x7.fnt"
const CAMINHO_FONTE_CONTORNO := "res://assets/sprites/font/fightclicker_5x7_contorno.fnt"
const TAMANHO_FONTE := 11

# Paleta fechada (docs/arte/direcao-visual.md, seção 3).
const INK := Color("14101a")
const D1 := Color("2a2233")
const D2 := Color("3d3346")
const G0 := Color("4a4552")
const G1 := Color("6b6570")
const G2 := Color("8f8890")
const G3 := Color("b8b0aa")
const CREAM := Color("d9cdb4")
const WHITE := Color("f2ece0")
const Y0 := Color("e0a040")
const Y1 := Color("f5d26b")
const Y2 := Color("fff3c4")
const R0 := Color("5a1a22")
const R1 := Color("9c2a2a")
const R2 := Color("d4473a")
const R3 := Color("f07a5a")
const B2 := Color("4d7bb3")
const B3 := Color("8fbbe0")
const GR2 := Color("5aa25a")
const GR3 := Color("a6d86a")
const P0 := Color("4a2f6b")
const P1 := Color("7a4fa0")
const P2 := Color("b07ad8")

const STEEL2 := Color("7f8c9a")  # aço (perfil do Kid Navalha)
const F2 := Color("f59ac0")  # rosa da Fama (rampa nova f0/f1/f2, só de UI)

# Fase 5.1: tokens de hierarquia (manifest.ui_tokens). Uma cor por moeda, igual em todo lugar. Preço sem saldo = COL_TEXT_2.
const COL_TREINO := GR3
const COL_MONEY := Y1
const COL_FAME := F2
const COL_LEGACY := P2
const COL_TEXT_1 := WHITE
const COL_TEXT_2 := G2
const COL_DISABLED := G1
const COL_BUYABLE := Y2

static var _manifest: Dictionary = {}
static var _fonte: Font
static var _fonte_contorno: Font
static var _texturas: Dictionary = {}


static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(CAMINHO_MANIFEST)) == OK and json.data is Dictionary:
			_manifest = json.data
		else:
			push_error("UiTema: manifest de sprites ilegível.")
	return _manifest


static func sprite(nome: String) -> Dictionary:
	var s = manifest().get("sprites", {}).get(nome, {})
	return s if s is Dictionary else {}


static func textura(nome: String) -> Texture2D:
	if not _texturas.has(nome):
		var arquivo := str(sprite(nome).get("file", ""))
		# Sprite ausente no manifest (ex.: estado _disabled que não foi desenhado): sem textura, sem erro de load("").
		_texturas[nome] = (load(arquivo) as Texture2D) if arquivo != "" else null
	return _texturas[nome]


static func pivo(nome: String) -> Vector2:
	var p: Array = sprite(nome).get("pivot", [0, 0])
	return Vector2(float(p[0]), float(p[1]))


static func tamanho_quadro(nome: String) -> Vector2:
	var p: Array = sprite(nome).get("frame_size", [1, 1])
	return Vector2(float(p[0]), float(p[1]))


## Posição de um sprite: `chave` escolhe em "positions"; sem chave usa "pos".
static func pos(nome: String, chave: String = "") -> Vector2:
	var s := sprite(nome)
	var p: Array = []
	if chave != "" and s.has("positions") and s.positions.has(chave):
		p = s.positions[chave]
	else:
		p = s.get("pos", [0, 0])
	return Vector2(float(p[0]), float(p[1]))


static func fonte() -> Font:
	if _fonte == null:
		_fonte = load(CAMINHO_FONTE) as Font
	return _fonte


static func fonte_contorno() -> Font:
	if _fonte_contorno == null:
		_fonte_contorno = load(CAMINHO_FONTE_CONTORNO) as Font
	return _fonte_contorno


static func largura(texto: String) -> float:
	return fonte().get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, TAMANHO_FONTE).x


## Nome de sprite com o sufixo do local ("bag_l0_idle" -> "bag_l0_idle_gym" na academia). Sem a versão do local no
## manifest, usa a da garagem. (Fase 5)
static func com_local(nome: String) -> String:
	var sufixo := GameState.sufixo_aparelhos()
	if sufixo != "" and not sprite(nome + sufixo).is_empty():
		return nome + sufixo
	return nome


## Cor pelo nome usado no manifest (`color` dos adversários: r2, y1, b2, gr2, p1, st2...). Padrão: cinza claro.
static func cor_nome(nome: String, padrao: Color = G3) -> Color:
	match nome:
		"r2":
			return R2
		"r3":
			return R3
		"y1":
			return Y1
		"b2", "b3":
			return B3
		"gr2", "gr3":
			return GR3
		"p1", "p2":
			return P2  # o roxo do perfil do Tonhão sobe um tom: p1 sobre a moldura escura lê mal
		"st2":
			return STEEL2
		"white":
			return WHITE
	return padrao


static func cor_atributo(atributo: String) -> Color:
	match atributo:
		"strength":
			return R2
		"agility":
			return B3
		"endurance":
			return Y0  # Fase 5.1: Y1 é a cor do Dinheiro
	return WHITE


## Rótulo pixel. largura 0 = automático (uma linha). Com largura, quebra linha por palavra.
static func rotulo(pai: Node, texto: String, cor: Color, x: float, y: float, largura_: float = 0.0,
		alinhar: int = HORIZONTAL_ALIGNMENT_LEFT, sombra: bool = true, contorno: bool = false) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", fonte_contorno() if contorno else fonte())
	l.add_theme_font_size_override("font_size", TAMANHO_FONTE)
	l.add_theme_color_override("font_color", cor)
	if sombra and not contorno:
		l.add_theme_color_override("font_shadow_color", INK)
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", 1)
	l.add_theme_constant_override("line_spacing", -2)
	l.horizontal_alignment = alinhar as HorizontalAlignment
	l.position = Vector2(x, y)
	if largura_ > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(largura_, 0)
		l.size = Vector2(largura_, 10)
	l.text = texto
	pai.add_child(l)
	return l


static func textura_rect(pai: Node, nome: String, x: float, y: float) -> TextureRect:
	var t := TextureRect.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture = textura(nome)
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.position = Vector2(x, y)
	t.size = tamanho_quadro(nome)
	pai.add_child(t)
	return t


## StyleBox 9-slice a partir de um sprite do manifest.
static func estilo(nome: String, margem_extra: Vector4 = Vector4.ZERO) -> StyleBoxTexture:
	var e := StyleBoxTexture.new()
	e.texture = textura(nome)
	var ns: Dictionary = sprite(nome).get("nine_slice", {})
	e.texture_margin_left = float(ns.get("left", 2))
	e.texture_margin_top = float(ns.get("top", 2))
	e.texture_margin_right = float(ns.get("right", 2))
	e.texture_margin_bottom = float(ns.get("bottom", 2))
	e.content_margin_left = e.texture_margin_left + margem_extra.x
	e.content_margin_top = e.texture_margin_top + margem_extra.y
	e.content_margin_right = e.texture_margin_right + margem_extra.z
	e.content_margin_bottom = e.texture_margin_bottom + margem_extra.w
	return e


static func painel(pai: Node, nome_sprite: String, rect: Rect2) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", estilo(nome_sprite))
	p.position = rect.position
	p.size = rect.size
	pai.add_child(p)
	return p


## Botão pixel (sem texto próprio: o conteúdo é montado com rótulos por cima).
## `estilo_base` troca o sprite do estado normal (ex.: botão de foco selecionado).
static func botao(pai: Node, rect: Rect2, estilo_base: String = "ui_button_normal") -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_override("font", fonte())
	b.add_theme_font_size_override("font_size", TAMANHO_FONTE)
	aplicar_estilo_botao(b, estilo_base)
	pai.add_child(b)
	return b


static func aplicar_estilo_botao(b: Button, estilo_base: String) -> void:
	b.add_theme_stylebox_override("normal", estilo(estilo_base))
	b.add_theme_stylebox_override("hover", estilo("ui_button_hover" if estilo_base == "ui_button_normal" else estilo_base))
	b.add_theme_stylebox_override("pressed", estilo("ui_button_pressed"))
	b.add_theme_stylebox_override("disabled", estilo("ui_button_disabled"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, WHITE)
	b.add_theme_color_override("font_disabled_color", G1)


# --- Fase 3: textos, risco, formatação e widgets das telas de luta ---

## Texto de data/ui_texts.json já preenchido ({chave} -> valor) e em MAIÚSCULAS (a UI sempre mostra
## MAIÚSCULAS). `padrao` só vale se a chave faltar.
static func txt(chave: String, padrao: String = "", vars: Dictionary = {}) -> String:
	return GameState.preencher(GameState.texto_ui(chave, padrao), vars).to_upper()


static func cor_risco(rotulo: String) -> Color:
	match rotulo:
		"easy":
			return GR3
		"even":
			return Y1
		"hard":
			return R2
	return G2


static func nome_risco(rotulo: String) -> String:
	return txt("risk_" + rotulo) if rotulo != "" else ""


## "$ 120" (TRUNCAR: nunca mostra mais do que o jogador tem).
static func dinheiro(v: float) -> String:
	return "$ " + NumberFormat.fmt(v, NumberFormat.TRUNCAR)


## 754 -> "12:34"; 3700 -> "1:01:40".
static func tempo(segundos: float) -> String:
	var s := maxi(0, int(segundos))
	var h := s / 3600
	var m := (s % 3600) / 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s % 60]
	return "%d:%02d" % [m, s % 60]


## Singular de "1 GOLPES", "1 CRÍTICOS" e "FALTARAM 1 DE" (os textos do Roteirista só têm o plural).
static func singular(texto: String) -> String:
	var r := RegEx.new()
	r.compile("\\b1 (GOLPE|CRÍTICO|VITÓRIA)S")
	var t := r.sub(texto, "1 $1", true)
	r.compile("\\bFALTARAM 1 DE\\b")
	return r.sub(t, "FALTOU 1 DE", true)


## Nome do sprite que depende da luva equipada: "fight_player_jab" + "_glove_l1".
static func com_luva(nome: String) -> String:
	return nome + GameState.sufixo_luva()


## Cursor-luva da luva equipada ("cursor_glove" ou "cursor_glove_lN").
static func nome_cursor() -> String:
	var suf := GameState.sufixo_luva()
	return "cursor_glove" if suf == "" else "cursor" + suf


## Ilustração "luvas penduradas" da luva equipada.
static func nome_luvas_penduradas() -> String:
	var suf := GameState.sufixo_luva()
	return "art_hung_glove_old" if suf == "" else "art_hung" + suf


## Ícone 16x16 de loja de uma luva (`id` = glove_l1...).
static func icone_luva(id: String) -> String:
	return str(manifest().get("by_data_id", {}).get(id, {}).get("icon", "icon_glove_old"))


static func nine_patch(pai: Node, nome: String, rect: Rect2) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.texture = textura(nome)
	var ns: Dictionary = sprite(nome).get("nine_slice", {})
	n.patch_margin_left = int(ns.get("left", 1))
	n.patch_margin_top = int(ns.get("top", 1))
	n.patch_margin_right = int(ns.get("right", 1))
	n.patch_margin_bottom = int(ns.get("bottom", 1))
	n.position = rect.position
	n.size = rect.size
	pai.add_child(n)
	return n


## Área útil (coordenadas locais) de um sprite 9-slice de tamanho `tam`: sem as bordas do 9-slice.
static func area_nove(nome: String, tam: Vector2) -> Rect2:
	var ns: Dictionary = sprite(nome).get("nine_slice", {})
	var e := float(ns.get("left", 1))
	var t := float(ns.get("top", 1))
	return Rect2(e, t, tam.x - e - float(ns.get("right", 1)), tam.y - t - float(ns.get("bottom", 1)))


## Largura do que realmente aparece: a fonte deixa 1 px de folga depois da última letra.
static func largura_visivel(texto: String) -> float:
	return largura(texto) - 1.0


## Declara para o verificador (tools/ui/ui_audit.gd) o que é intencional neste nó:
## center, center_h, center_v, left, right ou ignore (ignore vale para o nó e tudo abaixo dele).
static func alinhar(no: Node, modo: String) -> void:
	no.set_meta("ui_align", modo)


## Área útil do botão em coordenadas locais: sem as margens do estilo (o "degrau" de baixo não é conteúdo).
static func area_botao(b: Button) -> Rect2:
	var sb: StyleBox = b.get_theme_stylebox("normal")
	var e := sb.get_margin(SIDE_LEFT)
	var t := sb.get_margin(SIDE_TOP)
	var d := sb.get_margin(SIDE_RIGHT)
	var base := sb.get_margin(SIDE_BOTTOM)
	return Rect2(e, t, b.size.x - e - d, b.size.y - t - base)


## Topo do rótulo para o texto (7 px de altura x escala; o glifo começa 2 px x escala abaixo do topo) ficar
## centralizado na altura de "area". Sempre inteiro.
static func y_texto(area: Rect2, escala: int = 1) -> float:
	return roundf(area.position.y + (area.size.y - 7.0 * escala) / 2.0 - 2.0 * escala)


## Topo de uma imagem de altura "alt" centralizada na altura de "area".
static func y_imagem(area: Rect2, alt: float) -> float:
	return roundf(area.position.y + (area.size.y - alt) / 2.0)


## Texto centralizado numa área (coordenadas locais de "pai"): o alinhamento horizontal é do próprio Label
## (preenche a largura da área, horizontal_alignment = CENTER); na vertical o topo vem de y_texto.
## Escala inteira: pixel nítido. Serve para títulos de janela e qualquer texto de uma linha numa caixa.
static func rotulo_centrado(pai: Node, area: Rect2, texto: String, cor: Color, escala: int = 1,
		contorno: bool = false, modo: String = "center") -> Label:
	var l := rotulo(pai, texto, cor, area.position.x + folga_centro(escala), y_texto(area, escala), 0,
		HORIZONTAL_ALIGNMENT_CENTER, true, contorno)
	l.scale = Vector2(escala, escala)
	l.size = Vector2(area.size.x / escala, 12.0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alinhar(l, modo)
	return l


## O Label centraliza contando a folga de 1 px (x escala) depois da última letra; este deslocamento devolve
## metade dessa folga para o desenho ficar no meio de verdade (escala 1: nada; 2: 1 px; 3: 1 px; 4: 2 px).
static func folga_centro(escala: int) -> float:
	return floorf(escala / 2.0)


## Conteúdo do botão (ícone opcional + texto) centralizado como grupo na face do botão. Devolve o Label;
## o ícone (se houver) fica em b.get_meta("icone"). Texto fixo: se o texto mudar, monte o botão de novo.
static func botao_conteudo(b: Button, texto: String, cor: Color, escala: int = 1, icone: String = "",
		folga: float = 3.0, contorno: bool = false) -> Label:
	var a := area_botao(b)
	var lt := largura_visivel(texto) * escala
	var iw := 0.0
	var ih := 0.0
	if icone != "":
		var q := tamanho_quadro(icone)
		iw = q.x
		ih = q.y
	var total := lt + (iw + folga if icone != "" else 0.0)
	var x0 := a.position.x + (a.size.x - total) / 2.0
	if icone != "":
		var t := textura_rect(b, icone, roundf(x0), y_imagem(a, ih))
		b.set_meta("icone", t)
	var l := rotulo(b, texto, cor, roundf(x0 + (iw + folga if icone != "" else 0.0)), y_texto(a, escala), 0,
		HORIZONTAL_ALIGNMENT_LEFT, true, contorno)
	l.scale = Vector2(escala, escala)
	return l


## Rótulo de uma linha centralizado em cx (sem quebra). O Label ocupa a faixa simétrica em torno de cx e
## centraliza o texto sozinho; quando cx é o meio do pai o verificador confere (ui_align = center_h).
static func rotulo_centro(pai: Node, texto: String, cor: Color, cx: float, y: float) -> Label:
	var largura_pai: float = (pai as Control).size.x if pai is Control else 640.0
	var meia := minf(cx, largura_pai - cx)
	var l := rotulo(pai, texto, cor, cx - meia, y, 0, HORIZONTAL_ALIGNMENT_CENTER)
	l.size = Vector2(meia * 2.0, 12.0)
	if absf(cx - largura_pai / 2.0) < 0.5:
		alinhar(l, "center_h")
	return l

## Selo de risco: fundo 9-slice + ícone (reforça a cor) + texto. Devolve o Control raiz (largura em `size.x`).
static func selo_risco(pai: Node, rotulo_risco: String, x: float, y: float) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = Vector2(x, y)
	var texto := nome_risco(rotulo_risco)
	var w := largura(texto) + 24.0
	c.size = Vector2(w, 13)
	pai.add_child(c)
	nine_patch(c, "ui_risk_" + rotulo_risco, Rect2(0, 0, w, 13))
	textura_rect(c, "icon_risk_" + rotulo_risco, 3, 2)
	rotulo(c, texto, WHITE, 15, 3)
	return c


## Botão com sprites próprios (normal/hover/pressed/disabled): ex. prefixo "ui_button_fight".
static func botao_estilizado(pai: Node, rect: Rect2, prefixo: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.position = rect.position
	b.size = rect.size
	b.add_theme_stylebox_override("normal", estilo(prefixo + "_normal"))
	b.add_theme_stylebox_override("hover", estilo(prefixo + "_hover"))
	b.add_theme_stylebox_override("pressed", estilo(prefixo + "_pressed"))
	b.add_theme_stylebox_override("disabled", estilo(prefixo + "_disabled"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pai.add_child(b)
	return b


## Marca/tira o botão como "desligado" sem perder o aspecto: texto cinza.
static func escurecer(no: CanvasItem, ligado: bool) -> void:
	no.modulate = Color.WHITE if ligado else Color(0.62, 0.6, 0.66)


## Solta fontes e texturas guardadas em variáveis estáticas (testes que montam a cena chamam isto no fim,
## para o Godot não reclamar de recursos ainda em uso ao sair).
static func liberar_cache() -> void:
	_manifest = {}
	_fonte = null
	_fonte_contorno = null
	_texturas.clear()
