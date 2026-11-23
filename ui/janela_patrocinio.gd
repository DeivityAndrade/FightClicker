class_name JanelaPatrocinio
extends JanelaBase
## Fase 8a2: o contrato do patrocinador (aberto pelo envelope PROPOSTA no chão da sala). ASSINAR e AGORA NÃO: fechar não tira o
## envelope e não custa nada (a oferta fica até o fim da campanha). A janela só desenha e emite pedidos; quem assina é o GameState.
## Textos: GameState.patrocinio() (Roteirista, data/center.json).

signal assinou
signal fechou

var sfx: Sfx
var _botao_sim: Button
var _botao_nao: Button
var _p: Dictionary = {}


func abrir_com(p: Dictionary) -> void:
	_p = p
	sfx = Sfx.new()
	add_child(sfx)
	moldura("ui_window", Rect2(170, 76, 300, 188))
	faixa_titulo("neutral", Rect2(178, 84, 284, 22), str(p.get("offer_title", "")).to_upper(), UiTema.Y2, 1)
	# Marca (selo + nome da empresa): a versão larga já traz o VALE FORTE escrito, centralizada na janela.
	var marca := "sponsor_vale_wide" if not UiTema.sprite("sponsor_vale_wide").is_empty() else str(p.get("brand", "sponsor_vale"))
	var q := UiTema.tamanho_quadro(marca)
	var m := UiTema.textura_rect(painel, marca, roundf(320.0 - q.x / 2.0), 116)
	m.set_meta("ui_pos", "center_h")
	UiTema.rotulo_centro(painel, str(p.get("name", "")).to_upper(), UiTema.CREAM, 320.0, 142.0)
	divisor(190, 158, 260)
	# A proposta em linhas centralizadas (largura útil 250).
	var y := 166.0
	for linha in _quebrar(str(p.get("offer_line", "")).to_upper(), 236.0):
		UiTema.rotulo_centro(painel, linha, UiTema.WHITE, 320.0, y)
		y += 12.0
	_botao_sim = botao_texto(Rect2(186, 220, 130, 30), str(p.get("accept", "ASSINAR")).to_upper(), UiTema.Y2, "", 1, "ui_button_move")
	_botao_sim.name = "Assinar"
	_botao_sim.pressed.connect(func() -> void: assinou.emit())
	_botao_nao = botao_texto(Rect2(324, 220, 130, 30), str(p.get("close", "AGORA NÃO")).to_upper())
	_botao_nao.name = "AgoraNao"
	_botao_nao.pressed.connect(func() -> void: fechou.emit())
	animar_entrada()


## Depois de assinar: os botões dão lugar ao carimbo "CONTRATO ASSINADO" (verde) por um instante e a janela fecha sozinha.
func mostrar_assinado() -> void:
	_botao_sim.visible = false
	_botao_nao.visible = false
	var texto := str(_p.get("signed_text", "CONTRATO ASSINADO")).to_upper()
	var l := UiTema.rotulo_centro(painel, texto, UiTema.GR3, 320.0, 228.0)
	l.scale = Vector2(2, 2)
	l.pivot_offset = l.size / 2.0
	l.scale = Vector2(3, 3)
	l.modulate.a = 0.0
	sfx.selo()
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(2, 2), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 1.0, 0.1)
	tw.tween_interval(0.7)
	tw.tween_callback(func() -> void: fechou.emit())


## Quebra por palavra em linhas de até `larg` px.
func _quebrar(texto: String, larg: float) -> Array[String]:
	var linhas: Array[String] = []
	var atual := ""
	for palavra in texto.split(" ", false):
		var tentativa: String = palavra if atual == "" else atual + " " + palavra
		if atual != "" and UiTema.largura_visivel(tentativa) > larg:
			linhas.append(atual)
			atual = palavra
		else:
			atual = tentativa
	if atual != "":
		linhas.append(atual)
	return linhas
