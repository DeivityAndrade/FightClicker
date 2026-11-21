class_name CartaoPassiva
extends Control
## Fase 7a1: cartão da passiva da arte, ao lado da janela da prévia (a janela já ocupa quase os 360 px de altura, então o
## cartão mora do lado e nunca mexe na altura dela). Mostra o nome (MÃO RÁPIDA / FINALIZAÇÃO), a linha da passiva, o
## desenho do estado (Boxe: 5 bolinhas de embalo apagadas + K.O. máximo; Muay Thai (7b1): 3 marcas da perna apagadas + o round em
## que enchem, com o ícone da perna (icon_shin) na linha; Jiu-jitsu: barra dos 3 rounds com a marca de onde
## a pegada enche) e "N EM 10 VITÓRIAS POR ...". Só lê o bloco que `GameState.previa()` entrega (`passive_tactics[tática]`);
## trocar de tática chama `montar()` de novo, sem recalcular nada. Sem arte nos assets, cai em retângulos de cor.

const LARG := 136.0
const PAD := 6.0
const INTERIOR := LARG - PAD * 2.0
const PASSO_LINHA := 9.0
const ALT_INDICADOR := 12.0

var _corpo: Control
var linha_rotulo: Label  # 7b1: a linha da Canela e a fileira das marcas (o verificador confere que o texto nao passa sobre as marcas)
var linha_altura := 0.0
var indicador: Control
var _altura := 0.0


## Altura que o cartão ocupa (para quem o posiciona).
func altura() -> float:
	return _altura


## (Re)monta o conteúdo com o bloco da tática. `bloco` = {name, kind, line, share, state}; `arte` = id da arte.
func montar(bloco: Dictionary, arte: String, animar: bool) -> void:
	if _corpo != null:
		_corpo.queue_free()
	_corpo = Control.new()
	_corpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_corpo)
	var shin := str(bloco.get("kind", "")) == "shin"
	var recuo := 12.0 if shin else 0.0  # Muay Thai: o ícone da perna fica na margem esquerda da linha
	var linha := _quebrar(str(bloco.get("line", "")).to_upper(), INTERIOR - recuo)
	var partilha := _quebrar(str(bloco.get("share", "")).to_upper(), INTERIOR)
	var y := 6.0
	var y_nome := y
	y += 9.0 + 5.0
	var y_linha := y
	var passo := 10.0 if shin else PASSO_LINHA  # o rotulo de verdade gasta 10 px por linha (fonte 12 - 2 de espacamento)
	y += float(linha.size()) * passo + 3.0
	var y_ind := y
	y += ALT_INDICADOR + 4.0
	var y_share := y
	y += float(partilha.size()) * PASSO_LINHA + 4.0
	_altura = y
	size = Vector2(LARG, _altura)
	_corpo.size = size
	var fundo := UiTema.nine_patch(_corpo, "ui_card", Rect2(0, 0, LARG, _altura))
	fundo.set_meta("ui_align", "ignore")
	var boxe := str(bloco.get("kind", "")) == "fast_hands"
	var cor_arte := UiTema.R3 if boxe else (UiTema.BR3 if shin else UiTema.B3)
	_cabecalho(arte, str(bloco.get("name", "")).to_upper(), cor_arte, y_nome)
	if shin:
		_linha_com_icone(linha, y_linha)
	else:
		_texto(linha.size(), "\n".join(linha), UiTema.CREAM, y_linha)
	var estado: Dictionary = bloco.get("state", {})
	if boxe:
		_indicador_boxe(estado, y_ind)
	elif shin:
		_indicador_shin(estado, y_ind)
	else:
		_indicador_jj(estado, y_ind)
	_texto(partilha.size(), "\n".join(partilha), UiTema.Y1, y_share)
	if animar:
		_corpo.modulate = Color(1.6, 1.6, 1.6)
		_corpo.create_tween().tween_property(_corpo, "modulate", Color.WHITE, 0.3)


## Quebra por palavra em linhas de até `larg` px (a mesma conta que o verificador faz).
func _quebrar(texto: String, larg: float) -> Array[String]:
	var linhas: Array[String] = []
	var atual := ""
	for palavra in texto.split(" ", false):
		var tentativa := palavra if atual == "" else atual + " " + palavra
		if atual != "" and UiTema.largura_visivel(tentativa) > larg:
			linhas.append(atual)
			atual = palavra
		else:
			atual = tentativa
	if atual != "":
		linhas.append(atual)
	return linhas


func _texto(n: int, texto: String, cor: Color, y: float) -> Label:
	var l := UiTema.rotulo(_corpo, texto, cor, PAD, y, 0.0, HORIZONTAL_ALIGNMENT_CENTER)
	l.size = Vector2(INTERIOR, float(n) * PASSO_LINHA + 2.0)
	UiTema.alinhar(l, "center_h")
	return l


## Muay Thai: linha da passiva alinhada à esquerda, com o ícone da perna (9x9) na margem.
func _linha_com_icone(linhas: Array[String], y: float) -> void:
	UiTema.textura_rect(_corpo, "icon_shin", PAD, y)
	var l := UiTema.rotulo(_corpo, "\n".join(linhas), UiTema.CREAM, PAD + 12.0, y, 0.0, HORIZONTAL_ALIGNMENT_LEFT)
	l.size = Vector2(INTERIOR - 12.0, float(linhas.size()) * 10.0 + 2.0)
	linha_rotulo = l
	linha_altura = float(linhas.size()) * 10.0
	UiTema.alinhar(l, "left")


## Ícone da arte + nome, o grupo centralizado no cartão.
func _cabecalho(arte: String, nome: String, cor: Color, y: float) -> void:
	var faixa := Control.new()
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.position = Vector2(PAD, y)
	faixa.size = Vector2(INTERIOR, 9)
	faixa.set_meta("ui_margens", "h")
	_corpo.add_child(faixa)
	var icone := "art_%s_9" % arte
	var tem := not UiTema.sprite(icone).is_empty()
	var grupo := UiTema.largura_visivel(nome) + (12.0 if tem else 0.0)
	var gx := roundf((INTERIOR - grupo) / 2.0)
	if tem:
		UiTema.textura_rect(faixa, icone, gx, 0)
	UiTema.rotulo(faixa, nome, cor, gx + (12.0 if tem else 0.0), 0)


## Boxe: 5 bolinhas de embalo apagadas + o K.O. máximo por golpe ("20%"), o grupo centralizado.
func _indicador_boxe(est: Dictionary, y: float) -> void:
	var n := int(est.get("streak_max", 5))
	var pct := "%d%%" % int(round(100.0 * float(est.get("ko_max", 0.0))))
	var faixa := Control.new()
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.position = Vector2(PAD, y)
	faixa.size = Vector2(INTERIOR, ALT_INDICADOR)
	faixa.set_meta("ui_margens", "h")
	_corpo.add_child(faixa)
	var passo := 9.0
	var largura_bolas := passo * float(n) - 2.0
	var grupo := largura_bolas + 6.0 + UiTema.largura_visivel(pct)
	var gx := roundf((INTERIOR - grupo) / 2.0)
	for i in n:
		bolinha(faixa, gx + passo * float(i), 2.0, 0)
	UiTema.rotulo(faixa, pct, UiTema.WHITE, gx + largura_bolas + 6.0, 2.0)


## Muay Thai: as 3 marcas da perna apagadas e, ao lado, o round em que enchem ("2º ROUND"); perna que não enche a tempo: só as marcas.
func _indicador_shin(est: Dictionary, y: float) -> void:
	var n := int(est.get("marks_max", 3))
	var rodada := int(est.get("full_round", 0))
	var texto := UiTema.txt("fight_round", "{n}º ROUND", {"n": rodada}).to_upper() if rodada > 0 and not bool(est.get("late", false)) else ""
	var faixa := Control.new()
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.position = Vector2(PAD, y)
	faixa.size = Vector2(INTERIOR, ALT_INDICADOR)
	faixa.set_meta("ui_margens", "h")
	_corpo.add_child(faixa)
	indicador = faixa
	var largura_marcas := 12.0 * float(n) - 1.0
	var grupo := largura_marcas + (6.0 + UiTema.largura_visivel(texto) if texto != "" else 0.0)
	var gx := roundf((INTERIOR - grupo) / 2.0)
	for i in n:
		marca_perna(faixa, gx + 12.0 * float(i), 0.0, 0)
	if texto != "":
		UiTema.rotulo(faixa, texto, UiTema.WHITE, gx + largura_marcas + 6.0, 2.0)


## Jiu-jitsu: barra dos 3 rounds (marcas em 1/3 e 2/3) com a seta de onde a pegada enche e o trecho até lá preenchido.
func _indicador_jj(est: Dictionary, y: float) -> void:
	var faixa := Control.new()
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.position = Vector2(PAD, y)
	faixa.size = Vector2(INTERIOR, ALT_INDICADOR)
	faixa.set_meta("ui_margens", "h")
	_corpo.add_child(faixa)
	var larg := 100.0
	var bx := roundf((INTERIOR - larg) / 2.0)
	var by := 6.0
	barra(faixa, bx, by, larg)
	var interior := larg - 2.0
	var limite := float(GameState.lutas.combate.time_limit)
	var cheia := float(est.get("grip_full_at", -1.0))
	var no_tempo := bool(est.get("grip_in_time", false)) and cheia > 0.0 and limite > 0.0
	var frac := clampf(cheia / limite, 0.0, 1.0) if no_tempo else 0.0
	var w_fill := roundf(interior * frac)
	if w_fill >= 1.0:
		enchimento(faixa, bx + 1.0, by + 1.0, w_fill, 0)
	for k in [1, 2]:
		marca_round(faixa, bx + 1.0 + roundf(interior * float(k) / 3.0), by + 1.0)
	if no_tempo:
		var seta := UiTema.textura_rect(faixa, "ui_grip_mark", bx + 1.0 + w_fill - 3.0, 0.0)
		if UiTema.sprite("ui_grip_mark").is_empty():
			seta.queue_free()
			var q := ColorRect.new()
			q.mouse_filter = Control.MOUSE_FILTER_IGNORE
			q.color = UiTema.Y1
			q.position = Vector2(bx + w_fill - 1.0, 1.0)
			q.size = Vector2(3, 4)
			faixa.add_child(q)


# --- Peças do desenho (também usadas pela tela de luta): a arte entra sozinha quando existe; sem ela, retângulos de cor ---

## Bolinha de embalo. estado: 0 apagada, 1 acesa, 2 acendendo (clarão de 1 quadro).
static func bolinha(pai: Control, x: float, y: float, estado: int) -> Control:
	if not UiTema.sprite("ui_streak_pip").is_empty():
		var t := TextureRect.new()
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var at := AtlasTexture.new()
		at.atlas = UiTema.textura("ui_streak_pip")
		at.region = Rect2(7.0 * float(estado), 0, 7, 7)
		t.texture = at
		t.stretch_mode = TextureRect.STRETCH_KEEP
		t.position = Vector2(x, y)
		t.size = Vector2(7, 7)
		pai.add_child(t)
		return t
	var q := ColorRect.new()
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	q.color = UiTema.G1 if estado == 0 else (UiTema.R3 if estado == 1 else UiTema.Y2)
	q.position = Vector2(x, y)
	q.size = Vector2(7, 7)
	pai.add_child(q)
	return q


static func definir_bolinha(b: Control, estado: int) -> void:
	if b is TextureRect and (b as TextureRect).texture is AtlasTexture:
		((b as TextureRect).texture as AtlasTexture).region = Rect2(7.0 * float(estado), 0, 7, 7)
	elif b is ColorRect:
		(b as ColorRect).color = UiTema.G1 if estado == 0 else (UiTema.R3 if estado == 1 else UiTema.Y2)


## Marca na perna dele (Muay Thai, 11x11). estado: 0 apagada, 1 acesa, 2 acendendo (clarão de 1 quadro), 3 cheia (pisca com a 1).
static func marca_perna(pai: Control, x: float, y: float, estado: int) -> Control:
	if not UiTema.sprite("ui_shin_mark").is_empty():
		var t := TextureRect.new()
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var at := AtlasTexture.new()
		at.atlas = UiTema.textura("ui_shin_mark")
		at.region = Rect2(11.0 * float(estado), 0, 11, 11)
		t.texture = at
		t.stretch_mode = TextureRect.STRETCH_KEEP
		t.position = Vector2(x, y)
		t.size = Vector2(11, 11)
		pai.add_child(t)
		return t
	var q := ColorRect.new()
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	q.color = UiTema.G1 if estado == 0 else UiTema.BR3
	q.position = Vector2(x, y)
	q.size = Vector2(11, 11)
	pai.add_child(q)
	return q


static func definir_marca_perna(b: Control, estado: int) -> void:
	if b is TextureRect and (b as TextureRect).texture is AtlasTexture:
		((b as TextureRect).texture as AtlasTexture).region = Rect2(11.0 * float(estado), 0, 11, 11)
	elif b is ColorRect:
		(b as ColorRect).color = UiTema.G1 if estado == 0 else UiTema.BR3


## Moldura da barra de pegada (altura 6, por dentro 4 px).
static func barra(pai: Control, x: float, y: float, larg: float) -> Control:
	if not UiTema.sprite("ui_grip_bar").is_empty():
		return UiTema.nine_patch(pai, "ui_grip_bar", Rect2(x, y, larg, 6))
	var q := ColorRect.new()
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	q.color = UiTema.D2
	q.position = Vector2(x, y)
	q.size = Vector2(larg, 6)
	pai.add_child(q)
	return q


## Enchimento da pegada (4 px de altura, repete na horizontal). quadro: 0 enchendo, 1 cheia.
static func enchimento(pai: Control, x: float, y: float, larg: float, quadro: int) -> TextureRect:
	var t := TextureRect.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not UiTema.sprite("ui_grip_fill").is_empty():
		var at := AtlasTexture.new()
		at.atlas = UiTema.textura("ui_grip_fill")
		at.region = Rect2(4.0 * float(quadro), 0, 4, 4)
		t.texture = at
		t.stretch_mode = TextureRect.STRETCH_TILE
	else:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(UiTema.B2 if quadro == 0 else UiTema.B3)
		t.texture = ImageTexture.create_from_image(img)
		t.stretch_mode = TextureRect.STRETCH_TILE
	t.position = Vector2(x, y)
	t.size = Vector2(larg, 4)
	pai.add_child(t)
	return t


static func definir_enchimento(t: TextureRect, quadro: int) -> void:
	if t.texture is AtlasTexture:
		(t.texture as AtlasTexture).region = Rect2(4.0 * float(quadro), 0, 4, 4)


static func marca_round(pai: Control, x: float, y: float) -> void:
	if not UiTema.sprite("ui_grip_tick").is_empty():
		UiTema.textura_rect(pai, "ui_grip_tick", x, y)
		return
	var q := ColorRect.new()
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	q.color = UiTema.G2
	q.position = Vector2(x, y)
	q.size = Vector2(1, 4)
	pai.add_child(q)
