class_name JanelaBase
extends Control
## Base das janelas centrais (prévia, vitória, fim de carreira, aposentadoria): cobre a tela toda,
## escurece o que está atrás com o dither 50% de ink, bloqueia o mouse (nada por baixo é clicável)
## e entra com um "pop" curto. Só desenho: as regras ficam no GameState.

const TELA := Vector2(640, 360)

var painel: Control  # tudo da janela fica aqui dentro (anima junto)
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
	tw.tween_property(painel, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Moldura 9-slice (ex.: "ui_window", "ui_end_frame_defeat") no `rect`. Declara ao verificador que a moldura
## fica no meio da tela (horizontal) e que o conteúdo tem margem esquerda = direita.
func moldura(nome: String, rect: Rect2) -> NinePatchRect:
	var m := UiTema.nine_patch(painel, nome, rect)
	m.set_meta("ui_pos", "center_h")
	m.set_meta("ui_margens", "h")
	return m


## Faixa de título (variante: neutral, defeat, retire, victory) com texto centralizado na área útil da faixa.
func faixa_titulo(variante: String, rect: Rect2, texto: String, cor: Color = UiTema.WHITE, escala: int = 1) -> void:
	var faixa := UiTema.nine_patch(painel, "ui_window_title_" + variante, rect)
	faixa.set_meta("ui_pos", "center_h")
	UiTema.rotulo_centrado(faixa, UiTema.area_nove("ui_window_title_" + variante, rect.size), texto, cor, escala)


## Botão com texto centralizado (escala 1 ou 2). `estilo_base` troca o sprite do estado normal;
## com `prefixo_estilizado` usa um conjunto próprio (ex.: "ui_button_fight"). Um botão no meio da janela
## é declarado `ui_pos = center_h`.
func botao_texto(rect: Rect2, texto: String, cor: Color = UiTema.WHITE, estilo_base: String = "ui_button_normal",
		escala: int = 1, prefixo_estilizado: String = "") -> Button:
	var b: Button
	if prefixo_estilizado != "":
		b = UiTema.botao_estilizado(painel, rect, prefixo_estilizado)
	else:
		b = UiTema.botao(painel, rect, estilo_base)
	UiTema.botao_conteudo(b, texto, cor, escala)
	if absf(rect.position.x + rect.size.x / 2.0 - TELA.x / 2.0) < 0.5:
		b.set_meta("ui_pos", "center_h")
	return b


## Linha divisória fina.
func divisor(x: float, y: float, w: float, cor: Color = UiTema.D2) -> ColorRect:
	var d := ColorRect.new()
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.color = cor
	d.position = Vector2(x, y)
	d.size = Vector2(w, 1)
	painel.add_child(d)
	return d


func fundo_cor(rect: Rect2, cor: Color) -> ColorRect:
	var c := ColorRect.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.color = cor
	c.position = rect.position
	c.size = rect.size
	painel.add_child(c)
	return c


## Retrato 32x32 numa moldura 36x36 (`espelhar` vira o rosto para o lado oposto).
func retrato(retrato_sprite: String, moldura_sprite: String, x: float, y: float, espelhar: bool) -> void:
	var quadro := UiTema.textura_rect(painel, moldura_sprite, x, y)
	var t := UiTema.textura_rect(quadro, retrato_sprite, 2, 2)  # o retrato fica DENTRO da moldura (não é sobreposição)
	t.flip_h = espelhar


## Ícone 9x9 + texto na mesma linha. Devolve o rótulo.
func linha_icone(icone: String, texto: String, cor: Color, x: float, y: float, largura: float = 0.0) -> Label:
	UiTema.textura_rect(painel, icone, x, y)
	return UiTema.rotulo(painel, texto, cor, x + 12.0, y, largura)
