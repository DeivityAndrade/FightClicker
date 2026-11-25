class_name JanelaPremioTreino
extends JanelaBase
## Fase 7a2: tela de prêmio do treino fora de hora (Choque ou Panfletagem). Grande e sem pressa: não tem tempo mínimo na lógica,
## só um respiro de 0,5 s contra o clique dobrado de quem estava martelando o botão quando o tempo acabou.
## Choque: VENCEU!/NÃO DEU/EMPATE, placar, "+N FORÇA +N AGILIDADE +N RESISTÊNCIA" e a linha do AQUECIDO.
## Panfletagem: "N DE 10" aceitos e "+N FAMA". Só lê o prêmio que o GameState devolveu em `treino_concluir()`.

signal voltar_pedido

const RESPIRO := 0.5

var _t := 0.0


## `premio` = o que `GameState.treino_concluir()` devolveu; `meta` = aceitos para o prêmio cheio (Panfletagem).
func abrir_com(premio: Dictionary, meta: int = 10) -> void:
	if str(premio.get("kind", "")) == "spar":
		_montar_choque(premio)
	else:
		_montar_panfleto(premio, meta)
	animar_entrada()


func _process(delta: float) -> void:
	_t += delta


## Moldura centralizada na altura da tela, com a faixa de título; devolve o y do primeiro conteúdo.
func _moldura(altura: float, variante: String, titulo: String, cor: Color, escala: int) -> float:
	var topo := roundf((360.0 - altura) / 2.0)
	moldura("ui_window", Rect2(176, topo, 288, altura))
	faixa_titulo(variante, Rect2(182, topo + 6.0, 276, 22), titulo, cor, escala)
	return topo + 36.0


func _montar_choque(p: Dictionary) -> void:
	var venceu := bool(p.get("venceu", false))
	var pontos := int(p.get("pontos", 0))
	var dele := int(p.get("pontos_dele", 0))
	var titulo := UiTema.txt("spar_won", "VENCEU!")
	var variante := "victory"
	var cor := UiTema.Y2
	if not venceu:
		if pontos == dele:
			titulo = UiTema.txt("spar_draw", "EMPATE")
			variante = "neutral"
			cor = UiTema.WHITE
		else:
			titulo = UiTema.txt("spar_lost", "NÃO DEU")
			variante = "neutral"
			cor = UiTema.G3
	var attrs: Dictionary = p.get("atributos", {})
	var linhas_attr := maxi(1, attrs.size())
	var warm := bool(p.get("aquecido", false)) or bool(p.get("sem_luta", false))
	var altura := 36.0 + 12.0 + 12.0 + 8.0 + 9.0 + 20.0 * float(linhas_attr) + 8.0 + (24.0 if warm else 0.0) + 8.0 + 28.0 + 12.0
	var y := _moldura(altura, variante, titulo, cor, 2)
	# Subtítulo: o nome do treino (CHOQUE) e o placar.
	rotulo_c(UiTema.txt("spar_reward_title", "TREINO FEITO"), UiTema.CREAM, y)
	y += 12.0
	rotulo_c(UiTema.txt("spar_score", "VOCÊ {a} X {b} ELE", {"a": pontos, "b": dele}), UiTema.WHITE, y)
	y += 12.0
	rotulo_c(UiTema.txt("spar_result_line", "{n} PONTOS", {"n": pontos}), UiTema.G3, y)
	y += 12.0
	divisor(188, y, 264)
	y += 8.0
	# Os ganhos grandes (escala 2), um por atributo da divisão do aparelho da arte.
	var ordem := ["strength", "agility", "endurance"]
	var n_lin := 0
	for id in ordem:
		if not attrs.has(id):
			continue
		_linha_ganho("icon_" + id, UiTema.txt("spar_reward_attr", "+{n} {atributo}", {"n": NumberFormat.fmt(float(attrs[id]), NumberFormat.TRUNCAR),
			"atributo": str(GameState.dados.atributo_info(id).get("name", id))}), UiTema.cor_atributo(id), y)
		y += 20.0
		n_lin += 1
	if n_lin == 0:
		rotulo_c("+0", UiTema.G2, y)
		y += 20.0
	y += 8.0
	if warm:
		divisor(188, y - 4.0, 264)
		var texto := UiTema.txt("spar_warm_gain", "AQUECIDO PARA A PRÓXIMA LUTA")
		var icone := "icon_warm_16"
		var cor_w := UiTema.Y1
		if not bool(p.get("aquecido", false)):
			texto = UiTema.txt("spar_warm_none", "SEM LUTA MARCADA")
			icone = ""
			cor_w = UiTema.G2
		_linha_icone_centrada(icone, texto, cor_w, y, 16.0)
		y += 24.0
	_botao_voltar(y + 8.0)


func _montar_panfleto(p: Dictionary, meta: int) -> void:
	var altura := 36.0 + 12.0 + 8.0 + 12.0 + 28.0 + 8.0 + 28.0 + 12.0
	var y := _moldura(altura, "neutral", UiTema.txt("flyers_reward_title", "RUA CUMPRIDA"), UiTema.WHITE, 2)
	rotulo_c(UiTema.txt("flyers_name", "PANFLETAGEM"), UiTema.CREAM, y)
	y += 12.0
	rotulo_c(UiTema.txt("flyers_count", "{n} DE {goal}", {"n": int(p.get("aceitos", 0)), "goal": meta}), UiTema.G3, y)
	y += 12.0
	divisor(188, y, 264)
	y += 8.0
	_linha_icone_centrada("icon_fame_16", UiTema.txt("flyers_reward_fame", "+{n} FAMA", {"n": int(p.get("fama", 0))}), UiTema.COL_FAME, y, 16.0, 2)
	y += 28.0
	_botao_voltar(y + 8.0)


## Texto de uma linha centralizado na janela (escala 1).
func rotulo_c(texto: String, cor: Color, y: float) -> void:
	UiTema.rotulo_centro(painel, texto, cor, 320.0, y)


## Linha de ganho em escala 2: ícone 9 px + texto, o grupo no meio da janela.
func _linha_ganho(icone: String, texto: String, cor: Color, y: float) -> void:
	_linha_icone_centrada(icone, texto, cor, y, 9.0, 2)


## Ícone (de `alt` px) + texto numa linha só, o grupo centralizado na janela (largura par). Sem `icone`, só o texto.
func _linha_icone_centrada(icone: String, texto: String, cor: Color, y: float, alt: float, escala: int = 1) -> void:
	var lt := UiTema.largura_visivel(texto) * float(escala)
	var iw := UiTema.tamanho_quadro(icone).x if icone != "" else 0.0
	var gw := lt + (iw + 4.0 if icone != "" else 0.0)
	var w := ceilf(gw)
	if int(w) % 2 != 0:
		w += 1.0
	var linha := Control.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var altura := maxf(alt, 7.0 * float(escala))
	linha.position = Vector2(320.0 - w / 2.0, y)
	linha.size = Vector2(w, altura)
	UiTema.alinhar(linha, "center_h")
	painel.add_child(linha)
	var x := roundf((w - gw) / 2.0)
	if icone != "":
		UiTema.textura_rect(linha, icone, x, roundf((altura - UiTema.tamanho_quadro(icone).y) / 2.0))
		x += iw + 4.0
	var l := UiTema.rotulo(linha, texto, cor, x, roundf((altura - 7.0 * float(escala)) / 2.0) - 2.0 * float(escala))
	l.scale = Vector2(escala, escala)


func _botao_voltar(y: float) -> void:
	var b := botao_texto(Rect2(240, y, 160, 28), UiTema.txt("mini_back", "VOLTAR"), UiTema.WHITE, "ui_button_normal", 1, "", true)
	b.pressed.connect(func() -> void:
		if _t >= RESPIRO:
			voltar_pedido.emit())
