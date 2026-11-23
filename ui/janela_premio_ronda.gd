class_name JanelaPremioRonda
extends JanelaBase
## Ronda Noturna: tela de prêmio. Grande e sem pressa: só um respiro de 0,5 s contra o clique dobrado de quem estava martelando o botão
## quando a noite acabou. Mostra "+N LENDA", os SUSTOS (ou RONDA LIMPA), a linha do Roteirista pelo resultado e as 5 bolinhas da lenda.
## Subiu de nível: o título vira A LENDA CRESCEU e o recorte do jornal do dia seguinte aparece em grande, com a manchete nova.
## Depois do nível 5 a tela mostra "OCORRÊNCIAS: N". Só lê o prêmio que o GameState devolveu em `ronda_concluir()`.

signal voltar_pedido

const RESPIRO := 0.5
const JANELA_X := 176.0
const JANELA_L := 288.0
const TEXTO_L := 264.0

var _t := 0.0
var _premio: Dictionary = {}
var _pip_novo: TextureRect


func abrir_com(premio: Dictionary, _info: Dictionary = {}) -> void:
	_premio = premio
	var sobe := bool(premio.get("level_up", false)) and int(premio.get("level", 0)) >= 1
	var linhas: Array = _linhas(sobe)
	var altura := 36.0 + 12.0
	for l in linhas:
		altura += float(l.h)
	var topo := roundf((360.0 - altura) / 2.0)
	moldura("ui_window", Rect2(JANELA_X, topo, JANELA_L, altura))
	var titulo := UiTema.txt("ronda_level_up", "A LENDA CRESCEU") if sobe else UiTema.txt("ronda_reward_title", "RONDA FEITA")
	faixa_titulo("victory" if sobe else "neutral", Rect2(182, topo + 6.0, 276, 22), titulo, UiTema.Y2 if sobe else UiTema.WHITE, 2)
	var y := topo + 36.0
	for l in linhas:
		l.f.call(y)
		y += float(l.h)
	animar_entrada()
	if _pip_novo != null:
		var tw := create_tween()
		tw.tween_interval(0.45)
		tw.tween_callback(func() -> void:
			(_pip_novo.texture as AtlasTexture).region = Rect2(7.0, 0, 7, 7))  # acendendo -> acesa
	set_process(true)


func _process(delta: float) -> void:
	_t += delta


## Linhas do prêmio de cima para baixo: {h: altura com o espaço de baixo, f: desenha no y}.
func _linhas(sobe: bool) -> Array:
	var p := _premio
	var r: Array = []
	var nivel := int(p.get("level", 0))
	if sobe:
		var zoom := "ui_clipping_black_cat_zoom_l%d" % nivel
		if UiTema.sprite(zoom).is_empty():
			zoom = "ui_clipping_black_cat_zoom"
		r.append({"h": UiTema.tamanho_quadro(zoom).y + 6.0, "f": func(y: float) -> void: _recorte(zoom, y)})
		var manchete := str(p.get("clipping_text", "")).to_upper()
		if manchete != "":
			var n := _linhas_de(manchete)
			r.append({"h": 9.0 * float(n) + 5.0, "f": func(y: float) -> void: _texto(manchete, UiTema.CREAM, y, n)})
		var sube := str(p.get("level_up_line", "")).to_upper()
		if sube != "":
			var n2 := _linhas_de(sube)
			r.append({"h": 9.0 * float(n2) + 7.0, "f": func(y: float) -> void: _texto(sube, UiTema.Y1, y, n2)})
		r.append({"h": 20.0, "f": func(y: float) -> void: _ganho(y, 1)})
	else:
		r.append({"h": 28.0, "f": func(y: float) -> void: _ganho(y, 2)})
	var clean := bool(p.get("clean", false))
	var tx := UiTema.txt("ronda_reward_clean", "RONDA LIMPA") if clean else UiTema.txt("ronda_reward_scares", "SUSTOS: {a} DE 3", {"a": int(p.get("scares", 0))})
	r.append({"h": 17.0, "f": func(y: float) -> void: _linha_centrada(tx, UiTema.Y2 if clean else UiTema.WHITE, y)})
	if not sobe:
		var linha := str(p.get("line", "")).to_upper()
		if linha != "":
			var n3 := _linhas_de(linha)
			r.append({"h": 9.0 * float(n3) + 8.0, "f": func(y: float) -> void: _texto(linha, UiTema.G3, y, n3)})
	r.append({"h": 28.0, "f": func(y: float) -> void: _bolinhas(y, nivel, sobe)})
	r.append({"h": 36.0, "f": func(y: float) -> void: _botao_voltar(y + 4.0)})
	return r


func _linhas_de(texto: String) -> int:
	var fonte := UiTema.fonte()
	var tam := fonte.get_multiline_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, TEXTO_L, UiTema.TAMANHO_FONTE)
	return maxi(1, int(roundf(tam.y / fonte.get_height(UiTema.TAMANHO_FONTE))))


## Texto quebrado, centralizado na janela (largura 264, as margens iguais dos dois lados).
func _texto(texto: String, cor: Color, y: float, n: int) -> void:
	var l := UiTema.rotulo(painel, texto, cor, JANELA_X + (JANELA_L - TEXTO_L) / 2.0, y, TEXTO_L, HORIZONTAL_ALIGNMENT_CENTER)
	l.size.y = 9.0 * float(n)
	UiTema.alinhar(l, "center_h")


func _linha_centrada(texto: String, cor: Color, y: float) -> void:
	UiTema.rotulo_centro(painel, texto, cor, 320.0, y)


## O recorte do jornal do dia seguinte, em grande, no meio da janela.
func _recorte(nome: String, y: float) -> void:
	var q := UiTema.tamanho_quadro(nome)
	var t := UiTema.textura_rect(painel, nome, roundf(320.0 - q.x / 2.0), y)
	UiTema.alinhar(t, "center_h")


## Ícone da lenda + "+N LENDA" numa linha só, o grupo no meio da janela (largura par).
func _ganho(y: float, escala: int) -> void:
	var texto := UiTema.txt("ronda_reward_legend", "+{n} LENDA", {"n": int(_premio.get("legend_gain", 0))})
	var icone := "icon_legend_16"
	var lt := UiTema.largura_visivel(texto) * float(escala)
	var iw := UiTema.tamanho_quadro(icone).x
	var gw := lt + iw + 4.0
	var w := ceilf(gw)
	if int(w) % 2 != 0:
		w += 1.0
	var linha := Control.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var altura := maxf(16.0, 7.0 * float(escala))
	linha.position = Vector2(320.0 - w / 2.0, y)
	linha.size = Vector2(w, altura)
	UiTema.alinhar(linha, "center_h")
	painel.add_child(linha)
	var x := roundf((w - gw) / 2.0)
	UiTema.textura_rect(linha, icone, x, roundf((altura - 16.0) / 2.0))
	var l := UiTema.rotulo(linha, texto, UiTema.Y1, x + iw + 4.0, roundf((altura - 7.0 * float(escala)) / 2.0) - 2.0 * float(escala))
	l.scale = Vector2(escala, escala)


## 5 bolinhas do nível da lenda e, embaixo, o nível (ou as OCORRÊNCIAS depois do 5).
func _bolinhas(y: float, nivel: int, sobe: bool) -> void:
	var passo := 11.0
	var gw := 7.0 + 4.0 * passo + 1.0  # largura par: o grupo cai no meio da janela
	var grupo := Control.new()
	grupo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grupo.position = Vector2(320.0 - gw / 2.0, y)
	grupo.size = Vector2(gw, 9.0)
	UiTema.alinhar(grupo, "center_h")
	painel.add_child(grupo)
	for i in 5:
		var quadro := 1 if i < nivel else 0
		if sobe and i == nivel - 1:
			quadro = 2
		var pip := TelaTreino.imagem_quadro(grupo, "ui_legend_pip", quadro, passo * float(i), 1.0)
		if sobe and i == nivel - 1:
			_pip_novo = pip
	var texto := ""
	if bool(_premio.get("max_level", false)):
		texto = UiTema.txt("ronda_count", "OCORRÊNCIAS: {n}", {"n": int(_premio.get("scares_total", 0))})
	elif nivel >= 1:
		texto = UiTema.txt("ronda_level_label", "NÍVEL {n}", {"n": nivel})
	else:
		texto = UiTema.txt("legend_label", "LENDA") + " " + NumberFormat.fmt(float(_premio.get("legend", 0)))
	UiTema.rotulo_centro(painel, texto, UiTema.G3, 320.0, y + 14.0)


func _botao_voltar(y: float) -> void:
	var b := botao_texto(Rect2(240, y, 160, 28), UiTema.txt("mini_back", "VOLTAR"), UiTema.WHITE, "ui_button_normal", 1)
	b.pressed.connect(func() -> void:
		if _t >= RESPIRO:
			voltar_pedido.emit())
