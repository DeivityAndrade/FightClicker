extends SceneTree
## Fase 6d, item 4: mockups da TELA PRINCIPAL NOVA (sala grande, painéis por cima). PLACEHOLDER para o dono escolher.
## Nada aqui vai para o jogo: só gera imagens em docs/arte/mockups/fase6d_tela_*.png. Ver docs/arte/fase6d-tela-opcoes.md.
##
## Rodar a partir de uma pasta com um project.godot vazio (não dispara import no projeto):
##   godot --headless --path <pasta_vazia> --quit-after 30 --script E:/Fightclicker/tools/art/make_mockup_fase6d_tela.gd
##       [-- --capturas <pasta>]
## --capturas: pasta com as capturas 1280x720 do ui_audit (f6c2_mural_garagem.png, garagem_loja.png,
## f6c1_academia_cheia.png). Elas viram as referências 1x fase6d_ref_*.png. Sem o argumento, usa as referências já salvas.
##
## Como a sala cresce: a sala de hoje (384x272 em x 128, y 18) fica NO MESMO LUGAR (o alvo continua em x 281..362).
## O resto da tela é a mesma caixa continuada em perspectiva (ponto de fuga 320,-28): paredes laterais e chão
## repetidos a partir do fundo limpo (garage_bg / gym_bg). Isso é só para o mockup; o jogo precisa de fundos 640x360 desenhados.

const ROOT := "E:/Fightclicker/"
const OUT := ROOT + "docs/arte/mockups/"
const ROOM := Rect2i(128, 18, 384, 272)
const ALVO := Rect2i(273, 150, 98, 142)   # x 281..362 + 8 px de folga; do alto do número do clique até a base da sala

var L
var ref := {}
var bg := {}
var ext := {}

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var args := OS.get_cmdline_user_args()
	var cap_dir := ""
	for i in args.size():
		if args[i] == "--capturas" and i + 1 < args.size():
			cap_dir = args[i + 1]
	var nomes := {"garagem": "f6c2_mural_garagem.png", "garagem_loja": "garagem_loja.png", "academia": "f6c1_academia_cheia.png"}
	for k in nomes:
		var img: Image
		if cap_dir != "":
			img = Image.load_from_file(cap_dir.path_join(nomes[k]))
			img.convert(Image.FORMAT_RGBA8)
			img.resize(640, 360, Image.INTERPOLATE_NEAREST)
			img.save_png(OUT + "fase6d_ref_%s.png" % k)
		else:
			img = Image.load_from_file(OUT + "fase6d_ref_%s.png" % k)
			img.convert(Image.FORMAT_RGBA8)
		ref[k] = img
	bg["garagem"] = _load(ROOT + "assets/sprites/garage/garage_bg.png")
	bg["academia"] = _load(ROOT + "assets/sprites/gym/gym_bg.png")
	for k in ["garagem", "academia"]:
		ext[k] = extend_room(ref[k], bg[k], k)
	var feitas := {}
	for op in ["a", "b", "c"]:
		for local in ["garagem", "academia"]:
			for estado in ["fechado", "aberto"]:
				var img: Image = ext[local].duplicate()
				call("opcao_" + op, img, local, estado == "aberto")
				_save(img, "fase6d_tela_%s_%s_%s" % [op, local, estado])
				feitas["%s_%s_%s" % [op, local, estado]] = img
	for local in ["garagem", "academia"]:
		_comparacao(feitas, local)
	quit()

func _load(p: String) -> Image:
	var img := Image.load_from_file(p)
	img.convert(Image.FORMAT_RGBA8)
	return img

func _save(img: Image, nome: String) -> void:
	img.save_png(OUT + nome + ".png")
	var big := img.duplicate()
	big.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + nome + "_x2.png")

# ------------------------------------------------------------------ sala estendida
func _bgpx(b: Image, xs: float, ys: float) -> Color:
	var bx := clampi(int(floor(xs)) - ROOM.position.x, 0, ROOM.size.x - 1)
	var by := clampi(int(floor(ys)) - ROOM.position.y, 0, ROOM.size.y - 1)
	return b.get_pixel(bx, by)

func _sample(b: Image, x: int, y: int, local: String) -> Color:
	var dx := float(x) + 0.5 - 320.0
	var yy := float(y) + 0.5
	var hw := 150.0 * (yy + 28.0) / 248.0
	if yy >= 220.0 and absf(dx) <= hw:
		# chão: repete a faixa da frente (sem o pé da parede, que tem carro/banco)
		var D := (yy + 28.0) / 248.0
		var f0 := 1.12 if local == "garagem" else 1.0 + 0.278 * 0.5
		var f1 := 1.278
		var D2 := f0 + fposmod(D - f0, f1 - f0)
		return _bgpx(b, 320.0 + dx / D * D2, 248.0 * D2 - 28.0)
	if absf(dx) > 150.0 or yy >= 220.0:
		var D := absf(dx) / 150.0
		var Y := -28.0 + (yy + 28.0) / D
		var w0 := 1.0
		var w1 := 1.27
		var D2 := w0 + fposmod(D - w0, w1 - w0)
		var ys := maxf(-28.0 + (Y + 28.0) * D2, 18.0)
		return _bgpx(b, 320.0 + signf(dx) * 150.0 * D2, ys)
	return _bgpx(b, float(x), 18.0)

func extend_room(cap: Image, b: Image, local: String) -> Image:
	var out: Image = L.blank(640, 360)
	for y in 360:
		for x in 640:
			if ROOM.has_point(Vector2i(x, y)):
				out.set_pixel(x, y, cap.get_pixel(x, y))
			else:
				out.set_pixel(x, y, _sample(b, x, y, local))
	# os dois botões que hoje moram dentro da sala (mural e foto) saem: volta o fundo limpo
	for r in [Rect2i(130, 20, 26, 26), Rect2i(130, 272, 24, 18)]:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				out.set_pixel(x, y, b.get_pixel(x - ROOM.position.x, y - ROOM.position.y))
	# vinheta: um passo de rampa com dither Bayer, crescendo com a distância da sala de hoje
	for y in 360:
		for x in 640:
			var d := maxi(maxi(ROOM.position.x - x, x - (ROOM.end.x - 1)), maxi(ROOM.position.y - y, y - (ROOM.end.y - 1)))
			if d <= 4:
				continue
			var n := 0
			var t1 := clampi(int((d - 4) * 16 / 40), 0, 16)
			if L.BAYER[y % 4][x % 4] < t1:
				n -= 1
			var t2 := clampi(int((d - 60) * 16 / 60), 0, 16)
			if L.BAYER[(y + 2) % 4][(x + 1) % 4] < t2:
				n -= 1
			if n != 0:
				out.set_pixel(x, y, L.shade(out.get_pixel(x, y), n))
	return out

# ------------------------------------------------------------------ dados de cada local (iguais às capturas)
const DADOS := {
	"garagem": {"treino": "1.25K", "treino_s": "+28/S", "dinheiro": "$ 0", "clique": "+1",
		"attr": [317, 60, 200], "frac": [0.55, 0.12, 0.36],
		"focos": [["SACO", "ativo"], ["ESTEIRA", "compra"], ["CORDA", "trancado"]],
		"col_aberta": "garagem_loja", "titulo": "LOJA"},
	"academia": {"treino": "0", "treino_s": "+0/S", "dinheiro": "$ 999K", "clique": "+3",
		"attr": [0, 0, 0], "frac": [0.0, 0.0, 0.0],
		"focos": [["SACO", "ativo"], ["ESTEIRA", "compra"], ["CORDA", "trancado"], ["PERA", "trancado"]],
		"col_aberta": "academia", "titulo": "TREINO"},
}

var _icons := {}

func ic(nome: String) -> Image:
	if not _icons.has(nome):
		_icons[nome] = _load(ROOT + "assets/sprites/ui/" + nome + ".png")
	return _icons[nome]

func put(img: Image, nome: String, x: int, y: int) -> void:
	var s := ic(nome)
	img.blend_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(x, y))

## Pedaço da tela de hoje (referência 1x), colado igual: cartões, botões e textos que já existem no jogo.
func crop(img: Image, k: String, r: Rect2i, x: int, y: int) -> void:
	img.blit_rect(ref[k], r, Vector2i(x, y))

## Plaqueta flutuante sobre a sala: painel chanfrado d1 + sombra dura de 1 px.
func plate(img: Image, x: int, y: int, w: int, h: int, bg := "d1") -> void:
	L.R(img, x + 1, y + h, w, 1, "ink")
	L.R(img, x + w, y + 1, 1, h, "ink")
	L.panel(img, x, y, w, h, bg, "d2", "ink")

func outline(img: Image, x: int, y: int, w: int, h: int, c) -> void:
	L.R(img, x, y, w, 1, c)
	L.R(img, x, y + h - 1, w, 1, c)
	L.R(img, x, y, 1, h, c)
	L.R(img, x + w - 1, y, 1, h, c)

## Setinha 5x3 (a fonte não tem): "l", "r", "u".
func arrow(img: Image, x: int, y: int, dir: String, c := "g2") -> void:
	match dir:
		"l":
			for i in 3:
				L.R(img, x + i, y + 2 - i, 1, 1 + i * 2, c)
		"r":
			for i in 3:
				L.R(img, x + 2 - i, y + 2 - i, 1, 1 + i * 2, c)
		"u":
			for i in 3:
				L.R(img, x + 2 - i, y + i, 1 + i * 2, 1, c)

## Selo de "dá para comprar": quadradinho com o número, na cor da moeda (verde = Treino, ouro = Dinheiro).
func badge(img: Image, x: int, y: int, n: int, bg := "gr2") -> void:
	L.R(img, x, y, 9, 11, "ink")
	L.R(img, x + 1, y + 1, 7, 9, bg)
	L.text_center(img, str(n), x + 5, y + 2, "ink")

## Aba de gaveta presa na borda (ícones empilhados + seta). buy > 0 = contorno col_buyable (y2) + selo.
func tab(img: Image, x: int, y: int, w: int, h: int, icons: Array, dir: String, ativo: bool, buy := 0, buy_bg := "gr2") -> void:
	plate(img, x, y, w, h, "d2" if ativo else "d1")
	if buy > 0:
		outline(img, x + 1, y + 1, w - 2, h - 2, "y2")
	var cy := y + 4
	for n in icons:
		var s := ic(n)
		put(img, n, x + (w - s.get_width()) / 2, cy)
		cy += s.get_height() + 3
	arrow(img, x + w / 2 - 1, y + h - 9, dir, "white" if ativo else "g2")
	if buy > 0:
		badge(img, x - 3 if x > 320 else x + w - 6, y - 5, buy, buy_bg)

## Botão quadrado de ícone (opção B).
func icon_button(img: Image, x: int, y: int, nome: String, ativo := false, buy := 0, buy_bg := "gr2") -> void:
	L.button(img, x, y, 24, 22, "p0" if ativo else "d2", "")
	if ativo:
		outline(img, x, y, 24, 22, "white")
	if nome == "_atributos":
		# três barrinhas nas cores dos atributos (Força, Agilidade, Resistência)
		for i in 3:
			var hh: int = [12, 7, 9][i]
			var c: String = ["r2", "b3", "y0"][i]
			L.R(img, x + 6 + i * 5, y + 17 - hh, 4, hh, "ink")
			L.R(img, x + 7 + i * 5, y + 18 - hh, 2, hh - 2, c)
	else:
		var s := ic(nome)
		put(img, nome, x + (24 - s.get_width()) / 2, y + (20 - s.get_height()) / 2)
	if buy > 0:
		badge(img, x + 18, y - 5, buy, buy_bg)

func cursor(img: Image, x: int, y: int) -> void:
	var s := ic("cursor_glove_l1")
	img.blend_rect(s, Rect2i(0, 0, 14, 14), Vector2i(x, y))

## Botão de foco compacto (uma linha, 20 px), opção C.
func focus_button(img: Image, x: int, y: int, w: int, nome: String, estado: String) -> void:
	match estado:
		"ativo":
			L.button(img, x, y, w, 20, "r1", "")
			put(img, "icon_strength", x + 5, y + 5)
			L.text(img, nome, x + 18, y + 6, "white", 1, "r0")
		"compra":
			L.button(img, x, y, w, 20, "d2", "")
			outline(img, x, y, w, 20, "gr3")
			_lock(img, x + 6, y + 4)
			L.text(img, nome, x + 18, y + 6, "white", 1, "ink")
		_:
			L.button(img, x, y, w, 20, "d1", "")
			_lock(img, x + 6, y + 4, "g1")
			L.text(img, nome, x + 18, y + 6, "g1", 1, "ink")

func _lock(img: Image, x: int, y: int, c := "y1") -> void:
	L.R(img, x + 2, y, 3, 1, c)
	L.R(img, x + 1, y + 1, 1, 3, c)
	L.R(img, x + 5, y + 1, 1, 3, c)
	L.R(img, x, y + 4, 7, 6, "ink")
	L.R(img, x + 1, y + 5, 5, 4, c)
	L.P(img, x + 3, y + 6, "ink")

# Recortes da tela de hoje (1x)
const R_HUD := Rect2i(0, 0, 640, 18)
const R_ESQ := Rect2i(0, 18, 128, 160)         # atributos + calendário + risco
const R_CAL := Rect2i(5, 130, 119, 45)         # calendário + risco
const R_DIR := Rect2i(512, 18, 128, 272)       # coluna direita inteira (abas TREINO/LOJA + cartões)
const R_DIR_CORPO := {"garagem": Rect2i(512, 47, 128, 243), "academia": Rect2i(512, 36, 128, 254)}  # sem as abas (e sem o título repetido)
const R_MAPA := Rect2i(132, 22, 22, 22)
const R_LUTAR := Rect2i(518, 293, 118, 37)
const R_LUTAR_PASSAR := Rect2i(516, 291, 124, 66)

# ------------------------------------------------------------------ OPÇÃO A: gavetas
func opcao_a(img: Image, local: String, aberto: bool) -> void:
	var d: Dictionary = DADOS[local]
	crop(img, local, R_HUD, 0, 0)
	# canto de cima à esquerda: próxima luta + botão do mapa
	plate(img, 2, 20, 123, 49)
	crop(img, local, R_CAL, 4, 22)
	crop(img, local, R_MAPA, 4, 72)
	# embaixo à esquerda: o foco atual (abre a gaveta dos focos)
	plate(img, 2, 326, 140, 32)
	put(img, "icon_bag", 8, 334)
	L.text(img, d.focos[0][0], 30, 332, "r2", 1, "ink")
	L.text(img, d.clique + " POR CLIQUE", 30, 344, "gr3", 1, "ink")
	arrow(img, 130, 340, "u", "white")
	# embaixo à direita: LUTAR e Passar o posto (iguais aos de hoje)
	crop(img, local, R_LUTAR_PASSAR, 516, 291)
	var t_atr := ["icon_strength", "icon_agility", "icon_endurance"]
	var t_dir := ["icon_neighbor", "icon_money_16"]
	if not aberto:
		tab(img, 0, 100, 22, 46, t_atr, "r", false)
		tab(img, 616, 120, 24, 56, t_dir, "l", false, 2, "gr2")
		return
	if local == "garagem":
		# gaveta da direita aberta na LOJA (os cartões são os de hoje, mesma largura de 128)
		plate(img, 506, 18, 136, 274)
		crop(img, d.col_aberta, R_DIR, 510, 19)
		tab(img, 484, 120, 24, 56, t_dir, "r", true)
		tab(img, 0, 100, 22, 46, t_atr, "r", false)
		cursor(img, 600, 230)
	else:
		# gaveta da esquerda aberta: atributos + próxima luta (o painel de hoje)
		plate(img, -2, 18, 134, 162)
		crop(img, local, R_ESQ, 1, 19)
		tab(img, 130, 100, 22, 46, t_atr, "l", true)
		tab(img, 616, 120, 24, 56, t_dir, "l", false, 2, "gr2")
		cursor(img, 100, 56)

# ------------------------------------------------------------------ OPÇÃO B: HUD mínimo + ícones
func opcao_b(img: Image, local: String, aberto: bool) -> void:
	var d: Dictionary = DADOS[local]
	# treino (herói) e dinheiro
	plate(img, 2, 2, 120, 34)
	put(img, "icon_treino", 7, 9)
	var w: int = L.text(img, d.treino, 20, 6, "gr3", 2, "ink")
	L.text(img, d.treino_s, 20 + w + 5, 13, "gr2", 1, "ink")
	put(img, "icon_money", 7, 23)
	L.text(img, d.dinheiro, 20, 24, "y1", 1, "ink")
	# próxima luta
	plate(img, 515, 2, 123, 49)
	crop(img, local, R_CAL, 517, 4)
	# LUTAR
	plate(img, 515, 291, 123, 41)
	crop(img, local, R_LUTAR, 518, 293)
	# barra de ícones: foco, atributos, equipe, loja, mapa, passar o posto
	plate(img, 2, 328, 164, 30)
	var nomes := ["icon_bag", "_atributos", "icon_neighbor", "icon_money_16", "icon_skill_map", "icon_pass_post"]
	var ativo := -1
	if aberto:
		ativo = 3 if local == "garagem" else 2
	for i in nomes.size():
		var buy := 0
		var bb := "gr2"
		if i == 2:
			buy = 1
		if i == 3:
			buy = 1
			bb = "y1"
		icon_button(img, 6 + i * 26, 332, nomes[i], i == ativo, buy, bb)
	if not aberto:
		return
	# pop-up preso ao ícone que abriu (fica na metade esquerda, longe do alvo)
	var bx := 6 + ativo * 26 + 12
	var x0 := 18 if local == "academia" else 40
	var rc: Rect2i = R_DIR_CORPO[local]
	var y0 := 324 - rc.size.y - 18
	plate(img, x0, y0, 140, 324 - y0)
	L.R(img, x0 + 2, y0 + 2, 136, 12, "d2")
	L.text(img, d.titulo, x0 + 6, y0 + 5, "white", 1, "ink")
	L.button(img, x0 + 124, y0 + 2, 13, 11, "d1", "X", "g3")
	crop(img, d.col_aberta, rc, x0 + 6, y0 + 16)
	# rabicho apontando o ícone
	for i in 4:
		L.R(img, bx - 4 + i, 324 + i, 9 - i * 2, 1, "ink")
		if i < 3:
			L.R(img, bx - 3 + i, 324 + i, 7 - i * 2, 1, "d1")
	cursor(img, x0 + 112, 236 if local == "garagem" else 156)

# ------------------------------------------------------------------ OPÇÃO C: híbrido
func opcao_c(img: Image, local: String, aberto: bool) -> void:
	var d: Dictionary = DADOS[local]
	crop(img, local, R_HUD, 0, 0)
	# atributos em miniatura, sempre visíveis
	plate(img, 2, 20, 110, 41)
	var icons := ["icon_strength", "icon_agility", "icon_endurance"]
	var cores := ["r2", "b3", "y0"]
	for i in 3:
		var y := 24 + i * 12
		put(img, icons[i], 6, y)
		L.bar(img, 18, y + 2, 56, 5, d.frac[i], cores[i])
		L.text_right(img, str(d.attr[i]), 107, y + 1, "white", 1, "ink")
	crop(img, local, R_MAPA, 116, 20)
	plate(img, 2, 64, 123, 49)
	crop(img, local, R_CAL, 4, 66)
	# faixa fina de baixo: por clique, focos, LUTAR, passar o posto
	L.R(img, 0, 329, 640, 1, "ink")
	L.panel(img, 0, 330, 640, 30, "d1", "d2", "ink")
	var w: int = L.text(img, d.clique, 6, 338, "gr3", 2, "ink")
	L.text(img, "/CLIQUE", 6 + w + 3, 345, "g2", 1, "ink")
	var fx := 92
	for f in d.focos:
		focus_button(img, fx, 335, 86, f[0], f[1])
		fx += 90
	L.button(img, 508, 333, 102, 24, "r2", "LUTAR!", "white", 2)
	L.button(img, 614, 333, 24, 24, "p1", "")
	put(img, "icon_pass_post", 618, 336)
	if not aberto:
		tab(img, 616, 120, 24, 56, ["icon_neighbor", "icon_money_16"], "l", false, 2, "gr2")
		return
	plate(img, 506, 18, 136, 296)
	crop(img, d.col_aberta, R_DIR, 510, 20)
	L.button(img, 512, 296, 124, 15, "d2", "FIXAR ABERTO")
	tab(img, 484, 120, 24, 56, ["icon_neighbor", "icon_money_16"], "r", true)
	cursor(img, 600, 230 if local == "garagem" else 158)

# ------------------------------------------------------------------ prancha de comparação (1x, com a zona do alvo)
func _alvo(img: Image, ox: int, oy: int) -> void:
	for x in range(ALVO.position.x, ALVO.end.x):
		if (x / 3) % 2 == 0:
			L.P(img, ox + x, oy + ALVO.position.y, "r3")
			L.P(img, ox + x, oy + ALVO.end.y - 1, "r3")
	for y in range(ALVO.position.y, ALVO.end.y):
		if (y / 3) % 2 == 0:
			L.P(img, ox + ALVO.position.x, oy + y, "r3")
			L.P(img, ox + ALVO.end.x - 1, oy + y, "r3")

func _comparacao(feitas: Dictionary, local: String) -> void:
	var cw := 640
	var ch := 360
	var pad := 8
	var lab := 14
	var linhas := [["HOJE", ref[local], null],
		["A  GAVETAS", feitas["a_%s_fechado" % local], feitas["a_%s_aberto" % local]],
		["B  HUD MÍNIMO", feitas["b_%s_fechado" % local], feitas["b_%s_aberto" % local]],
		["C  HÍBRIDO", feitas["c_%s_fechado" % local], feitas["c_%s_aberto" % local]]]
	var img: Image = L.blank(pad * 3 + cw * 2, pad + linhas.size() * (lab + ch + pad))
	L.R(img, 0, 0, img.get_width(), img.get_height(), "d1")
	var y := pad
	for ln in linhas:
		var t: String = ln[0] + ("  FECHADO" if ln[2] != null else "")
		L.text(img, t, pad, y + 3, "white", 1, "ink")
		if ln[2] != null:
			L.text(img, ln[0] + "  ABERTO", pad * 2 + cw, y + 3, "white", 1, "ink")
		img.blit_rect(ln[1], Rect2i(0, 0, cw, ch), Vector2i(pad, y + lab))
		_alvo(img, pad, y + lab)
		if ln[2] != null:
			img.blit_rect(ln[2], Rect2i(0, 0, cw, ch), Vector2i(pad * 2 + cw, y + lab))
			_alvo(img, pad * 2 + cw, y + lab)
		else:
			L.text(img, "TRACEJADO: ZONA DO ALVO (X 273..370, Y 150..291).", pad * 2 + cw, y + lab + 10, "g3", 1, "ink")
			L.text(img, "NENHUM PAINEL FECHADO ENCOSTA NELA.", pad * 2 + cw, y + lab + 22, "g3", 1, "ink")
		y += lab + ch + pad
	img.save_png(OUT + "fase6d_tela_comparacao_%s.png" % local)
