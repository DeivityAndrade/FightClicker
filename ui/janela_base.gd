class_name JanelaBase
extends Control
## Base das janelas centrais (prévia, vitória, fim de carreira, aposentadoria): cobre a tela toda,
## escurece o que está atrás com o dither 50% de ink, bloqueia o mouse (nada por baixo é clicável)
## e entra com um "pop" curto. Só desenho: as regras ficam no GameState.

const TELA := Vector2(640, 360)

const SOMBRA := 3.0  # a sombra ink da c_janela (a peça é 3 px mais alta que o retângulo da janela)

var texto_em_papel := true  # falso: a janela é de fundo escuro (o mapa) e quem monta escolhe a cor de cada texto
var painel: Control  # tudo da janela fica aqui dentro (anima junto)
var _rect_moldura := Rect2()
var _dim: TextureRect


func _init() -> void:
	position = Vector2.ZERO
	size = TELA
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = TextureRect.new()
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.texture = UiTema.textura("ui_dim_dither")
	_dim.stretch_mode = TextureRect.STRETCH_TILE
	_dim.size = TELA
	add_child(_dim)
	painel = Control.new()
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.size = TELA
	z_index = 2000  # acima de tudo da arena (HUD z 500, letreiros e números z ~1000)
	add_child(painel)


## Entrada: o fundo escurece e a janela sobe 6 px com um fade rápido.
func animar_entrada() -> void:
	_dim.modulate.a = 0.0
	painel.modulate.a = 0.0
	painel.position = Vector2(0, 6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 1.0, 0.18)
	tw.tween_property(painel, "modulate:a", 1.0, 0.14)
	# Pixel inteiro a cada quadro (a regra do alinhamento vale também no meio da animação).
	tw.tween_method(func(y: float) -> void: painel.position = Vector2(0, roundf(y)), 6.0, 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Moldura da janela no tema C (c_janela: papel, borda ink de 2, sombra ink de 3 embaixo). O `nome` antigo ("ui_window",
## "ui_end_frame_*") é ignorado: toda janela é a mesma peça. O `rect` é o da janela SEM a sombra; a peça ganha +3 px de altura.
## Declara ao verificador que a moldura fica no meio da tela (horizontal) e que o conteúdo tem margem esquerda = direita.
func moldura(_nome: String, rect: Rect2) -> NinePatchRect:
	_rect_moldura = rect
	var m := UiTema.nine_patch(painel, "c_janela", Rect2(rect.position, rect.size + Vector2(0, SOMBRA)))
	m.set_meta("ui_pos", "center_h")
	m.set_meta("ui_margens", "h")
	return m


## Faixa de título vermelha (c_janela_titulo 16 px de altura em escala 1; c_janela_titulo_g 30 px em escala 2 ou mais),
## encostada em (moldura.x + 2, moldura.y + 2) e na largura da janela menos as bordas. O texto é `cream` (a cor pedida é ignorada)
## e fica centralizado na parte reta da faixa (a diagonal da direita não conta). `rect` só vale se não houver moldura antes.
func faixa_titulo(_variante: String, rect: Rect2, texto: String, _cor: Color = UiTema.WHITE, escala: int = 1) -> void:
	var nome := "c_janela_titulo" if escala <= 1 else "c_janela_titulo_g"
	var alt := 16.0 if escala <= 1 else 30.0
	var r := rect
	if _rect_moldura.size.x > 0.0:
		r = Rect2(_rect_moldura.position + Vector2(2, 2), Vector2(_rect_moldura.size.x - 4.0, alt))
	else:
		r.size.y = alt
	var faixa := UiTema.nine_patch(painel, nome, r)
	faixa.set_meta("ui_pos", "center_h")
	faixa.set_meta("ui_fundo_escuro", true)
	# O texto centraliza na parte reta (sem a diagonal): um Control do tamanho dessa área faz de "pai" para o verificador.
	var area := UiTema.area_nove(nome, r.size)
	var reta := Control.new()
	reta.name = "ParteReta"
	reta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reta.position = area.position
	reta.size = area.size
	faixa.add_child(reta)
	UiTema.rotulo_centrado(reta, Rect2(Vector2.ZERO, area.size), texto, UiTema.CREAM, escala)


## Altura da faixa de título para quem monta o layout embaixo dela (a faixa começa 2 px abaixo do topo da moldura).
static func altura_titulo(escala: int) -> float:
	return 16.0 if escala <= 1 else 30.0


## Botão com texto centralizado (escala 1 ou 2). `principal` = o botão que a janela quer que o jogador aperte (CONTINUAR, LUTAR!,
## PASSAR): vermelho de foco (c_btn_foco, texto cream). Os outros são de papel (c_btn_papel_normal, texto ink). Passar
## `prefixo_estilizado` (os conjuntos antigos ui_button_fight/move/retire) também vale como principal. Um botão no meio da janela
## é declarado `ui_pos = center_h`.
func botao_texto(rect: Rect2, texto: String, _cor: Color = UiTema.WHITE, estilo_base: String = "ui_button_normal",
		escala: int = 1, prefixo_estilizado: String = "", principal: bool = false) -> Button:
	var vermelho := principal or prefixo_estilizado != "" or estilo_base == "c_btn_foco"
	var base := "c_btn_foco" if vermelho else ("c_btn_normal" if estilo_base == "c_btn_normal" else "c_btn_papel_normal")
	var b := UiTema.botao(painel, rect, base)
	UiTema.botao_conteudo(b, texto, UiTema.INK if base == "c_btn_papel_normal" else UiTema.CREAM, escala)
	if absf(rect.position.x + rect.size.x / 2.0 - TELA.x / 2.0) < 0.5:
		b.set_meta("ui_pos", "center_h")
	return b


## Linha divisória fina.
func divisor(x: float, y: float, w: float, cor: Color = UiTema.G3) -> ColorRect:
	var d := ColorRect.new()
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.color = cor
	d.position = Vector2(x, y)
	d.size = Vector2(w, 1)
	painel.add_child(d)
	return d


## Retângulo de cor. `escuro` marca uma caixa de fundo escuro (ink, asfalto): o texto dentro dela segue com as cores de fundo escuro.
func fundo_cor(rect: Rect2, cor: Color, escuro: bool = false) -> ColorRect:
	var c := ColorRect.new()
	if escuro:
		c.set_meta("ui_fundo_escuro", true)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.color = cor
	c.position = rect.position
	c.size = rect.size
	painel.add_child(c)
	return c


## Retrato 32x32 numa moldura 36x36 (`espelhar` vira o rosto para o lado oposto).
func retrato(retrato_sprite: String, moldura_sprite: String, x: float, y: float, espelhar: bool) -> void:
	moldura_sprite = UiTema.moldura_retrato(moldura_sprite)  # tema C: mesma moldura 36x36 com o furo 32x32 em (2,2)
	var quadro := UiTema.textura_rect(painel, moldura_sprite, x, y)
	var t := UiTema.textura_rect(quadro, retrato_sprite, 2, 2)  # o retrato fica DENTRO da moldura (não é sobreposição)
	t.texture = UiTema.textura_disc(retrato_sprite)
	t.flip_h = espelhar


## Ícone 9x9 + texto na mesma linha. Devolve o rótulo.
func linha_icone(icone: String, texto: String, cor: Color, x: float, y: float, largura: float = 0.0) -> Label:
	UiTema.textura_rect(painel, icone, x, y)
	return UiTema.rotulo(painel, texto, cor, x + 12.0, y, largura)
