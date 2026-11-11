class_name CartaoInicio
extends Control
## Cartão "CARREIRA N — O QUE VOCÊ TROUXE:" (Fase 4): lista os nós da árvore que estão valendo, com o efeito em número.
## Aparece no começo da carreira (some sozinho em 1,8 s ou com 1 clique, e depois não bloqueia o alvo) e, com o mesmo
## desenho, como "dica" ao passar o mouse no rótulo LEGADO: N NÓS da garagem (`montar`).
## O Fluxo chama `GameState.definir_modal(true)` enquanto o cartão está aberto (o Metrônomo pausa) e solta ao `fechou`.

signal fechou

const LARGURA := 260.0
const TEMPO_VISIVEL := 1.5
const TEMPO_SAIDA := 0.3

var _fechado := false


## Monta o cartão em `pai` na posição (x, y) e devolve o Control raiz (tamanho em `size`).
## dados = `GameState.cartao_inicio()`: {title, career, nodes:[{id, name, effect_text, icon}]}.
static func montar(pai: Node, dados: Dictionary, x: float, y: float) -> Control:
	var nos: Array = dados.get("nodes", [])
	var arte_texto := str(dados.get("art_text", ""))  # Fase 5: "ARTE: BOXE" como 1ª linha
	var altura := 26.0 + 14.0 * (nos.size() + (1 if arte_texto != "" else 0))
	var c := Control.new()
	c.position = Vector2(x, y)
	c.size = Vector2(LARGURA, altura)
	pai.add_child(c)
	UiTema.nine_patch(c, "ui_career_card", Rect2(0, 0, LARGURA, altura))
	var larg_int := LARGURA - 10.0
	# Faixa do título: [ícone do Legado + título] como grupo centralizado na faixa.
	UiTema.nine_patch(c, "ui_career_card_title", Rect2(5, 5, larg_int, 14))
	# A fonte pixel não tem o travessão longo (—): o separador vira ":" (e o ":" final some, para não ficar dois).
	var titulo := str(dados.get("title", "")).to_upper().replace(" — ", ": ").replace("—", ":").trim_suffix(":")
	var area_t := UiTema.area_nove("ui_career_card_title", Vector2(larg_int, 14))
	var ic := UiTema.tamanho_quadro("icon_legacy")
	var grupo := ic.x + 4.0 + UiTema.largura_visivel(titulo)
	var gx := roundf(5.0 + area_t.position.x + (area_t.size.x - grupo) / 2.0)
	UiTema.textura_rect(c, "icon_legacy", gx, 5.0 + UiTema.y_imagem(Rect2(area_t.position, area_t.size), ic.y))
	UiTema.rotulo(c, titulo, UiTema.CREAM, gx + ic.x + 4.0, 5.0 + UiTema.y_texto(area_t))
	# Uma linha por nó: ícone 16x16 à esquerda, efeito na cor do ramo (Corpo vermelho, Carreira ouro).
	var yy := 21.0
	if arte_texto != "":
		var la := Control.new()
		la.mouse_filter = Control.MOUSE_FILTER_IGNORE
		la.position = Vector2(5, yy)
		la.size = Vector2(larg_int, 14)
		c.add_child(la)
		UiTema.nine_patch(la, "ui_career_card_row", Rect2(0, 0, larg_int, 14))
		UiTema.textura_rect(la, "art_" + str(dados.get("art", "")), 2, -1)
		UiTema.rotulo(la, arte_texto.to_upper(), UiTema.P2, 22, UiTema.y_texto(Rect2(0, 0, larg_int, 14)))
		yy += 14.0
	for n in nos:
		# Cada linha é um Control: o ícone de 16 px "encosta 1 px acima" (a arte pede) e não se sobrepõe ao da linha vizinha.
		var linha := Control.new()
		linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		linha.position = Vector2(5, yy)
		linha.size = Vector2(larg_int, 14)
		c.add_child(linha)
		UiTema.nine_patch(linha, "ui_career_card_row", Rect2(0, 0, larg_int, 14))
		UiTema.textura_rect(linha, str(n.get("icon", "")), 2, -1)
		var ramo := str(GameState.lutas.no_da_arvore(str(n.get("id", ""))).get("branch", ""))
		var cor := UiTema.R3 if ramo == "body" else UiTema.Y1
		UiTema.rotulo(linha, str(n.get("effect_text", "")).to_upper(), cor, 22, UiTema.y_texto(Rect2(0, 0, larg_int, 14)))
		yy += 14.0
	return c


## Abre o cartão no meio de cima da sala e programa a saída (1,5 s parado + 0,3 s de fade = 1,8 s).
func abrir_com(dados: Dictionary) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var c := montar(self, dados, 0.0, 0.0)
	size = c.size
	position = Vector2(roundf((640.0 - size.x) / 2.0), 26.0)
	UiTema.alinhar(self, "center_h")
	z_index = 3
	modulate.a = 0.0
	position.y += 4.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.12)
	tw.tween_property(self, "position:y", 26.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var sai := create_tween()
	sai.tween_interval(TEMPO_VISIVEL)
	sai.tween_property(self, "modulate:a", 0.0, TEMPO_SAIDA)
	sai.tween_callback(fechar)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		fechar()
		accept_event()


func fechar() -> void:
	if _fechado:
		return
	_fechado = true
	fechou.emit()
	queue_free()
