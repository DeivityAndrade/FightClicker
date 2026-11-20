class_name BalaoConvite
extends Control
## Fase 7a2: balão do convite do seu Osmar ("depois do expediente tem sparring. vem?") com o botão IR.
## É o `ui_balloon` de sempre com a plaquinha dourada do Osmar e o botão `ui_invite_go` à direita do texto, na 2ª linha.
## Pequeno e quieto: aparece e some de uma vez (sem fade chamativo), nunca cobre a zona do alvo nem a cabeça de outro personagem.
## Só desenho: quem decide quando ele existe é o GameState (`convite_visivel()`); o clique em IR vira `ir_pedido`.

signal ir_pedido

const AVANCO := 6
const ALTURA := 28.0
const LARGURA_BOTAO := 21.0  # área útil 15 px (21 - 3 - 3): o texto IR (11 px) cabe e sobra 2 px de cada lado
const ALTURA_BOTAO := 13.0

var kind := ""
var corpo := Rect2()  # retângulo do balão (sem plaquinha nem rabicho), na base
var _raiz: Control
var _botao: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = Vector2(640, 360)
	z_index = 2350  # acima da sala, abaixo do balão de fala (2400) e de qualquer janela


func ativo() -> bool:
	return _raiz != null


## Retângulo que o balão inteiro ocupa (plaquinha em cima e rabicho embaixo), para a conferência da zona proibida.
func retangulo_total() -> Rect2:
	if _raiz == null:
		return Rect2()
	return Rect2(corpo.position.x, corpo.position.y - 6.0, corpo.size.x, corpo.size.y + 6.0 + 4.0)


## Mostra o balão preso à `cabeca` (ponto logo acima da cabeça do Osmar). false = não cabe sem cobrir alguém.
## `com_botao` false = só a fala (o boato do Osmar na rua, na Panfletagem), preso à cabeça sem a regra da sala (`Balao.calcular`):
## ali não há zona do alvo nem painel, só as bordas da tela.
func mostrar(tipo: String, texto: String, cabeca: Vector2, evitar: Array = [], com_botao: bool = true) -> bool:
	esconder()
	var linhas := texto.split("\n")
	var maior := 0
	for l in linhas:
		maior = maxi(maior, str(l).length())
	# O botão mora na última linha: ela precisa de 4 px + botão a mais que o texto.
	var ultima := str(linhas[linhas.size() - 1]).length()
	var largo := maxf(float(maior * AVANCO), float(ultima * AVANCO) + 4.0 + LARGURA_BOTAO) if com_botao else float(maior * AVANCO)
	var w := clampf(largo + 16.0, 60.0, 172.0)
	var h := ALTURA if com_botao else 26.0
	var ponta := Vector2.ZERO
	if com_botao:
		var c := Balao.calcular(cabeca, w, h, evitar)
		if not bool(c.ok):
			return false
		corpo = c.corpo
		ponta = Vector2(float(c.ponta_x), float(c.ponta_y))
	else:
		var bx := clampf(cabeca.x - floorf(w / 2.0), 4.0, 636.0 - w)
		var by := maxf(cabeca.y - h - 9.0, 28.0)
		corpo = Rect2(floorf(bx), floorf(by), w, h)
		ponta = Vector2(clampf(cabeca.x, corpo.position.x + 8.0, corpo.end.x - 8.0), corpo.position.y + h + 3.0)
	kind = tipo
	_montar(linhas, w, h, ponta, com_botao)
	return true


func esconder() -> void:
	if _raiz != null:
		_raiz.queue_free()
		_raiz = null
		_botao = null
	kind = ""


func _montar(linhas: PackedStringArray, _w: float, h: float, ponta: Vector2, com_botao: bool) -> void:
	_raiz = Control.new()
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.size = Vector2(640, 360)
	add_child(_raiz)
	var by_data: Dictionary = UiTema.manifest().get("by_data_id", {}).get("speech_bubble", {})
	UiTema.nine_patch(_raiz, "ui_balloon", corpo)
	# Rabicho: central, ou à esquerda/direita quando a ponta fica perto da borda (a mesma regra do balão de fala).
	var perto_e := ponta.x - corpo.position.x < 14.0
	var perto_d := corpo.end.x - ponta.x < 15.0
	var nome_t := str(by_data.get("tail_l", "ui_balloon_tail_l")) if perto_e else (str(by_data.get("tail_r", "ui_balloon_tail_r")) if perto_d else str(by_data.get("tail", "ui_balloon_tail")))
	var off: Array = by_data.get("tail_rule", {}).get("tip_offset", {}).get("l" if perto_e else ("r" if perto_d else "c"), [3, 5])
	UiTema.textura_rect(_raiz, nome_t, ponta.x - float(off[0]), corpo.position.y + h - 2.0)
	var topo_texto := 4.0 if com_botao else 3.0
	for i in linhas.size():
		UiTema.rotulo(_raiz, str(linhas[i]), UiTema.INK, corpo.position.x + 8.0, corpo.position.y + topo_texto + 9.0 * float(i), 0,
			HORIZONTAL_ALIGNMENT_LEFT, false)
	# Plaquinha do nome (a do Osmar, dourada).
	var p: Dictionary = GameState.dialogos.personagem("coach")
	var cor_nome := str(by_data.get("tag_by_speaker", {}).get("coach", "gold"))
	var nome := str(p.get("short", "osmar"))
	var tw := float(nome.length() * AVANCO + 6)
	var tag := UiTema.nine_patch(_raiz, str(by_data.get("tag_by_color", {}).get(cor_nome, "ui_balloon_tag_gold")),
		Rect2(corpo.position.x + 6.0, corpo.position.y - 6.0, tw, 10.0))
	var cor_txt := UiTema.WHITE if str(by_data.get("tag_text_color", {}).get(cor_nome, "ink")) == "white" else UiTema.INK
	UiTema.rotulo(tag, nome, cor_txt, 3.0, 0.0, 0, HORIZONTAL_ALIGNMENT_LEFT, false)
	if not com_botao:
		return
	# Botão IR: o 9-slice `ui_invite_go` (3 quadros lado a lado: normal, hover, apertado), na 2ª linha, à direita.
	var bx := corpo.end.x - 8.0 - LARGURA_BOTAO
	var by := corpo.position.y + 10.0
	_botao = Button.new()
	_botao.focus_mode = Control.FOCUS_NONE
	_botao.position = Vector2(bx, by)
	_botao.size = Vector2(LARGURA_BOTAO, ALTURA_BOTAO)
	_botao.add_theme_stylebox_override("normal", _estilo_ir(0))
	_botao.add_theme_stylebox_override("hover", _estilo_ir(1))
	_botao.add_theme_stylebox_override("pressed", _estilo_ir(2))
	_botao.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_botao.pressed.connect(func() -> void: ir_pedido.emit())
	_raiz.add_child(_botao)
	UiTema.botao_conteudo(_botao, UiTema.txt("invite_go", "IR"), UiTema.INK, 1)


## Um quadro do `ui_invite_go` como StyleBox 9-slice (a folha tem 3 quadros de 14x13 lado a lado).
func _estilo_ir(quadro: int) -> StyleBoxTexture:
	var e := UiTema.estilo("ui_invite_go")
	var q := UiTema.tamanho_quadro("ui_invite_go")
	e.region_rect = Rect2(q.x * float(quadro), 0.0, q.x, q.y)
	return e
