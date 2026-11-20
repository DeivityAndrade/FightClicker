extends SceneTree
## Fase 7a2 (Diretor de Arte): "Treino fora de hora". Cenários dos dois minigames, peças de HUD, peça do convite,
## ícone do AQUECIDO e o recorte de jornal do vigilante (semente do Gato Preto).
## PLACEHOLDER gerado por código. Rodar a partir de uma pasta com um project.godot vazio (não dispara import no projeto):
##   godot --headless --path <pasta_vazia> --script E:/Fightclicker/tools/art/make_arte_fase7a2.gd [-- --assets <pasta>] [-- --no-assets]
## Depois: python tools/art/manifest_7a2.py (registra as peças no manifest sem apagar as dos outros).
##
## Grava (mockups):
## - docs/arte/mockups/fase7a2_choque_boxe.png, fase7a2_choque_jj.png  (tela inteira em 2x, com HUD)
## - docs/arte/mockups/fase7a2_choque_estados_x3.png                   (barra: normal, rajada, pausa x2, finta, ENCOSTOU, fôlego)
## - docs/arte/mockups/fase7a2_panfletagem.png                         (tela inteira em 2x, com HUD)
## - docs/arte/mockups/fase7a2_recorte_x3.png                          (recorte na garagem e na academia, 1x e 3x, e o zoom)
## - docs/arte/mockups/fase7a2_convite_x2.png                          (balão com IR na sala + AQUECIDO na prévia e no HUD)
## - docs/arte/mockups/fase7a2_pecas_x4.png                            (todas as peças soltas em 4x)
## Grava (assets): minigame/spar_bg.png, minigame/flyers_bg.png, ui/<peças>.png,
##   garage/wall_clipping_black_cat.png, gym/wall_clipping_black_cat_gym.png
## Personagens dos minigames (lutador, parceiro, pedestres, Osmar) são do Artista de Personagens: nos mockups entram
## folhas que já existem, só para medir tamanho e leitura.

const ROOT := "E:/Fightclicker/"
var ASSETS := ROOT + "assets/sprites/"
const MOCK := ROOT + "docs/arte/mockups/"
var WRITE_ASSETS := true
var L
const VPY := -28.0

## Contrato das telas (1x). Repetido no manifest (minigame_layout) pelo manifest_7a2.py: mudar nos dois.
const SPAR_FEET_Y := 318          # pés dos dois lutadores (igual à luta)
const SPAR_PLAYER_X := 296
const SPAR_PARTNER_X := 346
const SPAR_COACH := Vector2i(150, 262)   # Osmar na porta dos fundos (escala da sala, lá atrás)
const SPAR_HUD_H := 72            # y 0..71 céu escuro: HUD
const TUG := Rect2i(190, 28, 260, 16)    # barra do cabo de guerra (ui_tug_track)
const TUG_INNER := Vector2i(8, 251)      # x do marcador em -1 e +1 (relativo à barra)
const FLY_WALK_Y := 300           # pés dos pedestres (atravessam a tela inteira)
const FLY_FIGHTER := Vector2i(70, 324)
const FLY_COACH := Vector2i(604, 326)
const FLY_POSTER := Rect2i(26, 168, 36, 48)
const CLIP_GARAGE := Vector2i(304, 100)
const CLIP_GYM := Vector2i(340, 60)
const CLIP_SIZE := Vector2i(23, 28)

var SPR := {}   # cache de folhas carregadas do projeto

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--assets" and i + 1 < args.size():
			ASSETS = args[i + 1].trim_suffix("/") + "/"
		if args[i] == "--no-assets":
			WRITE_ASSETS = false
	var spar := spar_bg()
	var fly := flyers_bg()
	var ui := hud_pieces()
	var clip_g := clipping(false)
	var clip_y := clipping(true)
	var zoom := clipping_zoom()
	check_spots()
	x2(mock_spar(spar, ui, "boxe")).save_png(MOCK + "fase7a2_choque_boxe.png")
	x2(mock_spar(spar, ui, "jj")).save_png(MOCK + "fase7a2_choque_jj.png")
	board_states(spar, ui).save_png(MOCK + "fase7a2_choque_estados_x3.png")
	x2(mock_flyers(fly, ui)).save_png(MOCK + "fase7a2_panfletagem.png")
	board_clipping(clip_g, clip_y, zoom).save_png(MOCK + "fase7a2_recorte_x3.png")
	board_invite(ui).save_png(MOCK + "fase7a2_convite_x2.png")
	board_pieces(ui, clip_g, clip_y).save_png(MOCK + "fase7a2_pecas_x4.png")
	if WRITE_ASSETS:
		DirAccess.make_dir_recursive_absolute(ASSETS + "minigame")
		spar.save_png(ASSETS + "minigame/spar_bg.png")
		fly.save_png(ASSETS + "minigame/flyers_bg.png")
		for n in ui:
			sheet(ui[n]).save_png(ASSETS + "ui/%s.png" % n)
		clip_g.save_png(ASSETS + "garage/wall_clipping_black_cat.png")
		clip_y.save_png(ASSETS + "gym/wall_clipping_black_cat_gym.png")
		zoom.save_png(ASSETS + "ui/ui_clipping_black_cat_zoom.png")
	print("7a2: mockups em %s; assets %s" % [MOCK, (ASSETS if WRITE_ASSETS else "(não gravados)")])
	quit()

# ------------------------------------------------------------------ utilidades
func sheet(frames: Array) -> Image:
	var f0: Image = frames[0]
	var out: Image = L.blank(f0.get_width() * frames.size(), f0.get_height())
	for i in frames.size():
		out.blit_rect(frames[i], Rect2i(Vector2i.ZERO, f0.get_size()), Vector2i(i * f0.get_width(), 0))
	return out

func x2(img: Image) -> Image:
	return scaled(img, 2)

func scaled(img: Image, f: int) -> Image:
	var o: Image = img.duplicate()
	o.resize(img.get_width() * f, img.get_height() * f, Image.INTERPOLATE_NEAREST)
	return o

func bayer(x: int, y: int) -> float:
	return (L.BAYER[y % 4][x % 4] + 0.5) / 16.0

func rng_at(x: int, y: int, s := 0) -> float:
	## ruído fixo (sem sorteio de verdade: rodar de novo dá o mesmo PNG)
	var h := int(x * 73856093) ^ int(y * 19349663) ^ int(s * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h >> 8) & 0xFFFF) / 65535.0

func frame(rel: String, fw: int, fh: int, i := 0) -> Image:
	var key := "%s#%d" % [rel, i]
	if SPR.has(key):
		return SPR[key]
	var full := Image.load_from_file(ROOT + rel)
	var f: Image = L.blank(fw, fh)
	if full != null:
		full.convert(Image.FORMAT_RGBA8)
		f.blit_rect(full, Rect2i(i * fw, 0, fw, fh), Vector2i.ZERO)
	SPR[key] = f
	return f

func put(dst: Image, src: Image, feet: Vector2i, pivot: Vector2i, flip := false) -> void:
	var s: Image = L.flipped(src) if flip else src
	var px := pivot.x if not flip else src.get_width() - 1 - pivot.x
	L.blit(dst, s, feet.x - px, feet.y - pivot.y)

func nine(dst: Image, src: Image, x: int, y: int, w: int, h: int, l: int, t: int, r: int, b: int) -> void:
	var sw := src.get_width()
	var sh := src.get_height()
	for yy in h:
		var sy := yy if yy < t else (sh - (h - yy) if yy >= h - b else t + (yy - t) % maxi(sh - t - b, 1))
		for xx in w:
			var sx := xx if xx < l else (sw - (w - xx) if xx >= w - r else l + (xx - l) % maxi(sw - l - r, 1))
			var c := src.get_pixel(sx, sy)
			if c.a > 0.0:
				dst.set_pixel(x + xx, y + yy, c)

func floor_shadow(img: Image, cx: int, cy: int, rx: int) -> void:
	L.ellipse_dither(img, cx, cy, rx, 2.5, "ink")
	L.ellipse(img, cx, cy, rx - 4, 1.6, "ink")

## faixa vertical no ponto de fuga: x na linha y de uma reta que passa por xb em yb
func vx(xb: float, yb: float, y: float) -> float:
	return 320.0 + (xb - 320.0) * (y - VPY) / (yb - VPY)

# ------------------------------------------------------------------ céu e silhuetas
func night_sky(img: Image, y1: int, seed := 1) -> void:
	for y in y1:
		for x in 640:
			var t := float(y) / float(y1)
			var c := "ink"
			if t > 0.35:
				c = "b0" if (t - 0.35) * 2.2 > bayer(x, y) else "ink"
			img.set_pixel(x, y, L.col(c))
	for i in 34:
		var sx := int(rng_at(i, 7, seed) * 639)
		var sy := int(rng_at(i, 11, seed) * float(y1) * 0.6)
		L.P(img, sx, sy, "b2" if i % 3 else "b3")
	# lua minguante, pequena (luz fria que não compete com o poste)
	L.ellipse(img, 588, 22, 6, 6, "cream")
	L.ellipse(img, 591, 20, 5, 5, "ink")
	L.P(img, 584, 19, "white")

func skyline(img: Image, ybase: int, seed := 2, lit := 0.18, hmin := 22, hrange := 44) -> void:
	var x := 0
	var i := 0
	while x < 640:
		var w := 26 + int(rng_at(i, 1, seed) * 40)
		var h := hmin + int(rng_at(i, 2, seed) * hrange)
		L.R(img, x, ybase - h, w, h, "d1")
		L.R(img, x, ybase - h, w, 1, "d2")
		if rng_at(i, 3, seed) > 0.6:
			L.R(img, x + w / 2 - 1, ybase - h - 6, 1, 6, "d1")   # antena
			L.R(img, x + w / 2 - 3, ybase - h - 6, 5, 1, "d1")
		if rng_at(i, 9, seed) > 0.55:   # caixa d'água
			L.R(img, x + 4, ybase - h - 5, 8, 5, "d1")
		for wy in range(ybase - h + 5, ybase - 3, 6):
			for wx in range(x + 3, x + w - 4, 6):
				if rng_at(wx, wy, seed) < lit:
					L.R(img, wx, wy, 3, 3, "y0" if rng_at(wx, wy, seed + 5) > 0.4 else "br3")
					L.P(img, wx, wy, "y1")
		x += w + int(rng_at(i, 4, seed) * 4)
		i += 1

func tree(img: Image, cx: int, base: int, h: int, r: int, c0 := "gr0", c1 := "gr1") -> void:
	L.R(img, cx - 2, base - h, 4, h, "br0")
	L.ellipse(img, cx, base - h - r * 0.4, r, r * 0.8, c0)
	L.ellipse(img, cx - r * 0.6, base - h + 2, r * 0.7, r * 0.55, c0)
	L.ellipse(img, cx + r * 0.6, base - h + 1, r * 0.7, r * 0.55, c0)
	for i in 40:
		var a := rng_at(i, cx, 3) * TAU
		var d := rng_at(i, base, 4) * r * 0.8
		L.P(img, int(cx + cos(a) * d), int(base - h - r * 0.4 + sin(a) * d * 0.8), c1)

func lamp_post(img: Image, x: int, top: int, base: int, arm: int) -> Vector2i:
	## poste de concreto com braço; devolve o centro da lâmpada
	L.R(img, x - 2, top, 5, base - top, "g0")
	L.R(img, x - 2, top, 1, base - top, "g1")
	L.R(img, x + 2, top, 1, base - top, "d2")
	L.R(img, x - 3, base - 4, 7, 4, "d2")
	for i in range(0, base - top - 10, 9):
		L.R(img, x - 2, top + 8 + i, 5, 1, "d2")   # emendas
	var dir := signi(arm)
	var ax := x + arm
	L.line(img, x, top + 4, ax, top - 2, "g0")
	L.line(img, x, top + 5, ax, top - 1, "d2")
	L.R(img, mini(x, ax) + 2, top + 4, 2, 6, "g0")    # mão-francesa
	var lx := ax
	var ly := top + 2
	L.R(img, lx - 6, ly - 3, 12, 4, "st0")
	L.R(img, lx - 6, ly - 3, 12, 1, "st1")
	L.R(img, lx - 4, ly + 1, 8, 2, "y1")
	L.R(img, lx - 2, ly + 1, 4, 2, "y2")
	# brilho pequeno: dither de 1 passo no fundo
	return Vector2i(lx, ly + 2)

func glow(img: Image, c: Vector2i, rx: int, ry: int) -> void:
	for y in range(c.y - ry, c.y + ry + 1):
		for x in range(c.x - rx, c.x + rx + 1):
			if x < 0 or y < 0 or x >= 640 or y >= 360:
				continue
			var d := Vector2(float(x - c.x) / rx, float(y - c.y) / ry).length()
			if d < 1.0 and (x + y) % 2 == 0 and d > 0.25:
				img.set_pixel(x, y, L.shade(img.get_pixel(x, y), 1))

# ------------------------------------------------------------------ cenário do Choque
## Fundos da Academia Boa Esquina depois do expediente: parede de trás com a porta aberta (luz quente), janela gradeada,
## ar-condicionado, alambrado da praça à direita, poste iluminando um tapete de tatame velho no meio.
func spar_bg() -> Image:
	var img: Image = L.blank(640, 360)
	night_sky(img, 130, 3)
	skyline(img, 104, 5, 0.08, 12, 16)
	tree(img, 520, 112, 30, 26)
	tree(img, 600, 110, 26, 22)
	# parede de trás da academia (x 0..430): reboco verde em baixo, creme em cima (a cor de dentro, de fora e gasta)
	var WALL_TOP := 92
	var WALL_BOT := 252
	L.R(img, 0, WALL_TOP, 432, WALL_BOT - WALL_TOP, "g3")
	L.R(img, 0, 186, 432, WALL_BOT - 186, "gr1")
	L.R(img, 0, 186, 432, 1, "gr2")
	for x in range(0, 432):        # reboco gasto: falhas que mostram tijolo
		for y in range(WALL_TOP + 4, WALL_BOT):
			var n := rng_at(x / 3, y / 2, 21)
			if n > 0.997 - (0.004 if y > 200 else 0.0):
				L.R(img, x, y, 6, 3, "br2")
				L.R(img, x, y + 3, 6, 1, "br1")
	L.R(img, 0, WALL_TOP - 4, 434, 4, "g1")        # platibanda
	L.R(img, 0, WALL_TOP - 4, 434, 1, "g2")
	L.R(img, 0, WALL_TOP, 432, 1, "d2")
	L.R(img, 430, WALL_TOP - 4, 4, WALL_BOT - WALL_TOP + 4, "g1")   # quina
	# escorridos da calha
	for cx in [58, 236, 402]:
		for y in range(WALL_TOP, WALL_TOP + 30 + int(rng_at(cx, 1, 2) * 30)):
			if (y + cx) % 3 != 0:
				L.P(img, cx, y, "g2")
	# porta dos fundos aberta (x 120..156, y 182..252): luz amarela de dentro
	var dx := 118
	L.R(img, dx - 3, 178, 44, 75, "d2")
	L.R(img, dx, 181, 38, 71, "y1")
	L.R(img, dx, 181, 38, 3, "y0")
	L.R(img, dx + 2, 186, 14, 20, "y2")            # janelinha da porta de dentro, bem clara
	for y in range(204, 252):                       # pedaço da academia lá dentro: barrado verde e o saco
		L.R(img, dx, y, 38, 1, "gr2" if y > 226 else "y1")
	L.R(img, dx + 22, 192, 7, 22, "r2")
	L.R(img, dx + 22, 192, 2, 22, "r3")
	L.R(img, dx + 25, 181, 1, 11, "g1")
	# folha da porta aberta para fora, de quina
	L.trap(img, 181, 251, dx + 38, dx + 47, dx + 38, dx + 47, "br1")
	L.R(img, dx + 38, 181, 1, 71, "br0")
	L.R(img, dx + 44, 214, 2, 3, "y0")
	# lâmpada da porta (arandela) e a placa
	L.R(img, dx + 14, 168, 10, 5, "st0")
	L.R(img, dx + 16, 173, 6, 2, "y1")
	glow(img, Vector2i(dx + 19, 175), 12, 7)
	L.R(img, dx - 4, 150, 46, 13, "b1")
	L.R(img, dx - 4, 150, 46, 1, "b2")
	L.text(img, "FUNDOS", dx + 1, 153, "cream")
	# janela gradeada apagada e o ar-condicionado pingando
	L.R(img, 214, 132, 40, 30, "d1")
	L.R(img, 214, 132, 40, 1, "g1")
	L.R(img, 212, 162, 44, 3, "g2")
	for gx in range(218, 254, 6):
		L.R(img, gx, 132, 1, 30, "st1")
	L.R(img, 214, 146, 40, 1, "st1")
	L.R(img, 280, 136, 34, 22, "g2")
	L.R(img, 280, 136, 34, 1, "white")
	for gy in range(140, 156, 2):
		L.R(img, 284, gy, 26, 1, "g1")
	L.R(img, 312, 158, 1, 18, "st1")               # cano do dreno
	L.R(img, 309, 174, 6, 1, "st1")
	# canos e relógio de luz
	L.R(img, 360, WALL_TOP, 3, 160, "g1")
	L.R(img, 360, WALL_TOP, 1, 160, "g2")
	L.R(img, 372, 196, 20, 26, "g1")
	L.R(img, 374, 198, 16, 12, "d2")
	L.R(img, 378, 202, 8, 4, "y0")
	# alambrado da praça (x 432..640): mourões e tela em losango, árvores atrás
	L.R(img, 432, 160, 208, 92, "ink")
	for y in range(112, 252):
		for x in range(432, 640):
			if img.get_pixel(x, y).a == 0.0:
				img.set_pixel(x, y, L.col("b0" if bayer(x, y) < 0.5 else "ink"))
	tree(img, 470, 250, 34, 24, "gr1", "gr2")
	tree(img, 560, 252, 40, 30, "gr1", "gr2")
	L.R(img, 432, 238, 208, 14, "gr0")             # grama da praça
	for x in range(432, 640, 2):
		L.P(img, x, 237 - int(rng_at(x, 1, 8) * 2), "gr1")
	for y in range(124, 252):
		for x in range(432, 640):
			var a := (x + y) % 8
			var b := (x - y + 800) % 8
			if a == 0 or b == 0:
				img.set_pixel(x, y, L.col("st1"))
	for mx in [436, 502, 568, 634]:
		L.R(img, mx, 118, 3, 134, "st2")
		L.R(img, mx, 118, 1, 134, "st3")
	L.R(img, 432, 122, 208, 2, "st1")
	# chão de cimento (y 252..360) em perspectiva + tatame de EVA no meio
	for y in range(252, 360):
		for x in 640:
			var c := "g1"
			if (y - 252) % 22 == 0:
				c = "g0"
			img.set_pixel(x, y, L.col(c))
	for xb in range(-400, 1100, 64):
		for y in range(252, 360):
			var x := int(round(vx(xb, 252.0, y)))
			if x >= 0 and x < 640:
				img.set_pixel(x, y, L.col("g0"))
	L.R(img, 0, 252, 640, 1, "d2")
	# rachaduras com forma (seguem a junta) e uma poça perto do dreno
	L.line(img, 60, 300, 92, 312, "g0")
	L.line(img, 92, 312, 104, 330, "g0")
	L.ellipse(img, 310, 262, 14, 3, "g0")
	L.ellipse(img, 312, 262, 9, 2, "st1")
	mats(img)
	# tralha nos cantos (fora de x 200..440)
	trash_can(img, 26, 252)
	tire_big(img, 556, 300)
	crates(img, 590, 252)
	bench_towel(img, 30, 320)
	# luz: poste da praça (fora do alambrado, braço para dentro) + porta
	var lc := lamp_post(img, 452, 100, 252, -60)
	L.light(img, Rect2i(0, 60, 640, 300), Vector2(330, 286), 300.0, 1.8, 3.0, -2, 1, 1.0)
	glow(img, lc, 18, 10)
	spill(img, Vector2i(dx + 19, 252), 30, 40)
	# faixa do HUD escura e lisa por cima (y 0..71): só céu
	for y in SPAR_HUD_H:
		for x in 640:
			var c := img.get_pixel(x, y)
			if c != L.col("ink") and c != L.col("b0"):
				img.set_pixel(x, y, L.shade(c, -1))
	return img

func mats(img: Image) -> void:
	## tatame de EVA (placas de quebra-cabeça) velho, azul e verde, gasto onde se pisa
	var y0 := 280
	var y1 := 344
	var cols := [130.0, 194.0, 258.0, 322.0, 386.0, 450.0, 514.0]
	var rows := [y0, 301, 322, y1]
	for ri in rows.size() - 1:
		for ci in cols.size() - 1:
			var ya: int = rows[ri]
			var yb: int = rows[ri + 1]
			var c := "b1" if (ri + ci) % 2 == 0 else "gr1"
			for y in range(ya, yb):
				var xl := int(round(vx(cols[ci], y0, y)))
				var xr := int(round(vx(cols[ci + 1], y0, y)))
				L.R(img, xl, y, xr - xl, 1, c)
			# dentes do encaixe
			var xm := int(round(vx((cols[ci] + cols[ci + 1]) / 2.0, y0, ya)))
			if ri > 0:
				L.R(img, xm - 3, ya - 2, 6, 2, c)
	# borda e desgaste
	for y in range(y0, y1):
		var xl := int(round(vx(cols[0], y0, y)))
		var xr := int(round(vx(cols[-1], y0, y)))
		L.P(img, xl - 1, y, "ink")
		L.P(img, xr, y, "ink")
		for x in range(xl, xr):
			var n := rng_at(x / 2, y, 31)
			var cx := absf(x - 320.0) / 120.0
			if n > 0.72 + cx * 0.2:
				img.set_pixel(x, y, L.shade(img.get_pixel(x, y), 1 if n > 0.93 else -1))
	L.R(img, int(vx(cols[0], y0, y1)), y1, int(vx(cols[-1], y0, y1) - vx(cols[0], y0, y1)), 2, "ink")
	L.R(img, int(vx(cols[0], y0, y0)), y0, int(vx(cols[-1], y0, y0) - vx(cols[0], y0, y0)), 1, "b2")

func trash_can(img: Image, x: int, base: int) -> void:
	L.R(img, x, base - 34, 26, 34, "st1")
	L.R(img, x, base - 34, 3, 34, "st2")
	L.R(img, x + 22, base - 34, 4, 34, "st0")
	for y in [base - 28, base - 16, base - 5]:
		L.R(img, x, y, 26, 2, "st0")
	L.R(img, x - 2, base - 37, 30, 4, "st2")
	L.R(img, x - 2, base - 37, 30, 1, "st3")
	L.R(img, x + 9, base - 40, 8, 3, "st1")
	L.R(img, x - 1, base, 28, 2, "ink")

func tire_big(img: Image, cx: int, cy: int) -> void:
	## pneu de trator deitado (treino de virar pneu)
	L.ellipse(img, cx, cy + 6, 40, 13, "ink")
	L.ellipse(img, cx, cy, 40, 13, "d1")
	L.ellipse(img, cx, cy - 2, 38, 11, "d2")
	L.ellipse(img, cx, cy - 2, 18, 5, "d1")
	L.ellipse(img, cx, cy - 1, 16, 4, "ink")
	for i in 22:
		var a := float(i) / 22.0 * TAU
		var px := int(cx + cos(a) * 30)
		var py := int(cy - 2 + sin(a) * 8)
		L.R(img, px, py, 2, 1, "g0")

func crates(img: Image, x: int, base: int) -> void:
	for b in [[0, 0, 30, 20], [4, -20, 24, 20]]:
		var bx: int = x + b[0]
		var by: int = base + b[1] - b[3]
		L.R(img, bx, by, b[2], b[3], "br1")
		L.R(img, bx, by, b[2], 1, "br2")
		for yy in range(by + 4, by + b[3], 5):
			L.R(img, bx + 1, yy, b[2] - 2, 1, "br0")
		L.R(img, bx, by, 1, b[3], "br0")
		L.R(img, bx + b[2] - 1, by, 1, b[3], "br0")

func bench_towel(img: Image, x: int, base: int) -> void:
	## caixote com garrafa d'água e toalha (canto da frente, à esquerda)
	L.R(img, x, base - 18, 40, 18, "br1")
	L.R(img, x, base - 18, 40, 2, "br2")
	L.R(img, x, base - 9, 40, 1, "br0")
	L.R(img, x - 1, base, 42, 2, "ink")
	L.R(img, x + 6, base - 32, 7, 14, "b2")         # garrafa
	L.R(img, x + 6, base - 32, 2, 14, "b3")
	L.R(img, x + 8, base - 35, 3, 3, "r2")
	L.R(img, x + 18, base - 22, 18, 5, "cream")     # toalha dobrada caindo
	L.R(img, x + 30, base - 17, 6, 10, "cream")
	L.R(img, x + 18, base - 22, 18, 1, "white")
	L.R(img, x + 30, base - 9, 6, 1, "g3")

func spill(img: Image, at: Vector2i, w: int, h: int) -> void:
	## luz da porta no chão: trapézio que abre para a frente, 1 passo mais claro com dither nas bordas
	for y in range(at.y, at.y + h):
		var t := float(y - at.y) / float(h)
		var hw := w * 0.5 + t * w * 0.6
		for x in range(int(at.x - hw), int(at.x + hw)):
			if x < 0 or x >= 640:
				continue
			var edge := absf(x - at.x) / hw
			if 1.0 - maxf(edge, t) > bayer(x, y) * 0.9:
				img.set_pixel(x, y, L.shade(img.get_pixel(x, y), 1))

# ------------------------------------------------------------------ cenário da Panfletagem
## Rua do bairro da Raízes, a mesma noite: muro com lambe-lambe (o cartaz da escola com o R de raiz), padaria fechada,
## lanchonete acesa, casa com portão, ponto de ônibus. Calçada larga onde passa gente; o lutador fica à esquerda.
func flyers_bg() -> Image:
	var img: Image = L.blank(640, 360)
	night_sky(img, 262, 9)
	skyline(img, 122, 11, 0.12, 30, 30)
	# fachadas (y 60..262)
	var TOP := 66
	var BOT := 262
	# muro (x 0..108): reboco, lambe-lambes
	L.R(img, 0, 120, 108, BOT - 120, "g2")
	L.R(img, 0, 116, 110, 4, "g3")
	L.R(img, 0, 120, 108, 1, "g1")
	for i in 6:   # cartazes velhos rasgados em volta do da escola
		var px := 4 + int(rng_at(i, 1, 3) * 80)
		var py := 130 + int(rng_at(i, 2, 3) * 100)
		var c: String = ["y0", "b2", "r2", "cream", "gr2", "st3"][i]
		L.R(img, px, py, 16, 20, c)
		L.R(img, px, py, 16, 1, L.shade(L.col(c), 1).to_html(false) if false else c)
		for k in 4:
			L.R(img, px + 2, py + 4 + k * 4, 12, 1, L.shade(L.col(c), -1).to_html(false) if false else "g1")
		L.R(img, px + 10, py + 14, 6, 6, "g2")   # canto rasgado
	raizes_poster(img, FLY_POSTER.position.x, FLY_POSTER.position.y, true)
	# padaria fechada (x 108..252): porta de aço e letreiro apagado
	L.R(img, 108, TOP + 20, 144, BOT - TOP - 20, "cream")
	L.R(img, 108, TOP + 16, 146, 4, "g3")
	L.R(img, 116, 100, 128, 18, "br1")
	L.text(img, "PADARIA", 140, 105, "br3")
	L.R(img, 118, 128, 124, BOT - 128, "st1")
	for y in range(130, BOT, 4):
		L.R(img, 118, y, 124, 1, "st0")
	L.R(img, 118, 128, 124, 2, "st2")
	L.R(img, 174, BOT - 6, 12, 3, "st3")             # cadeado
	L.R(img, 120, 160, 34, 22, "white")              # pichação limpa: só um "aluga-se" colado
	L.text(img, "ALUGA", 122, 164, "r1")
	L.R(img, 123, 174, 22, 1, "g2")
	# lanchonete acesa (x 252..402)
	L.R(img, 252, TOP, 150, BOT - TOP, "r1")
	L.R(img, 252, TOP, 150, 2, "r2")
	L.R(img, 262, 76, 130, 22, "ink")
	L.R(img, 264, 78, 126, 18, "d1")
	L.text(img, "LANCHES", 300, 81, "y1", 1, "br1")
	L.text(img, "DA NENA", 302, 89, "r3")
	L.R(img, 262, 108, 130, 92, "br2")               # janela grande acesa com balcão
	L.R(img, 264, 110, 126, 88, "y1")
	L.R(img, 264, 110, 126, 6, "y2")
	L.R(img, 264, 168, 126, 30, "br1")
	L.R(img, 264, 168, 126, 2, "br3")
	for sx in [282, 330, 372]:                        # banquetas e garrafas
		L.R(img, sx, 160, 6, 8, "br0")
	for gx in range(272, 386, 7):
		L.R(img, gx, 124, 3, 8, "gr1" if gx % 2 else "br3")
	L.R(img, 340, 130, 26, 18, "st0")                 # tevê ligada
	L.R(img, 342, 132, 22, 14, "b3")
	L.R(img, 342, 140, 22, 6, "gr2")
	L.R(img, 262, 206, 130, 56, "r1")
	L.R(img, 262, 206, 130, 2, "r2")
	for y in range(214, 262, 8):
		L.R(img, 296, y, 96, 1, "r0")   # azulejo vermelho do rodapé
	L.R(img, 268, 212, 26, 50, "y0")                  # porta de vidro
	L.R(img, 268, 212, 26, 2, "y1")
	# toldo listrado
	for x in range(256, 398):
		var c := "r2" if (x / 8) % 2 == 0 else "cream"
		L.R(img, x, 100, 1, 6, c)
		L.P(img, x, 106, "r1" if (x / 4) % 2 == 0 else "ink")
	# casa com portão (x 402..530)
	L.R(img, 402, TOP + 28, 128, BOT - TOP - 28, "b1")
	L.R(img, 400, TOP + 22, 132, 6, "br1")
	L.R(img, 400, TOP + 22, 132, 1, "br2")
	L.R(img, 420, 120, 30, 30, "y0")                  # janela acesa com cortina
	L.R(img, 420, 120, 30, 2, "y1")
	L.R(img, 420, 120, 8, 30, "r2")
	L.R(img, 442, 120, 8, 30, "r2")
	L.R(img, 418, 150, 34, 3, "g3")
	L.R(img, 466, 160, 56, BOT - 160, "st0")          # portão de grade
	for gx in range(468, 522, 5):
		L.R(img, gx, 160, 2, BOT - 160, "st2")
	L.R(img, 466, 160, 56, 3, "st2")
	L.R(img, 466, 200, 56, 2, "st2")
	L.R(img, 406, 190, 12, 4, "g3")                   # número
	L.text(img, "27", 407, 179, "white")
	# ponto de ônibus (x 530..640): abrigo e placa
	L.R(img, 530, TOP + 40, 110, BOT - TOP - 40, "g1")
	L.R(img, 530, TOP + 40, 110, 1, "g2")
	for y in range(TOP + 50, BOT, 16):
		L.R(img, 530, y, 110, 1, "g0")
	L.R(img, 546, 150, 80, 6, "st1")                  # cobertura do abrigo
	L.R(img, 546, 150, 80, 1, "st3")
	L.R(img, 550, 156, 3, 100, "st1")
	L.R(img, 620, 156, 3, 100, "st1")
	L.R(img, 556, 226, 60, 4, "br2")                  # banco
	L.R(img, 556, 226, 60, 1, "br3")
	L.R(img, 560, 230, 2, 24, "st0")
	L.R(img, 610, 230, 2, 24, "st0")
	L.R(img, 566, 164, 40, 50, "b2")                  # vidro com propaganda
	L.R(img, 568, 166, 36, 46, "b3")
	L.R(img, 572, 172, 28, 6, "white")
	L.R(img, 572, 184, 20, 3, "b2")
	L.R(img, 0, BOT - 2, 640, 2, "d2")
	# calçada (y 262..330), meio-fio, asfalto
	for y in range(BOT, 330):
		for x in 640:
			img.set_pixel(x, y, L.col("g2"))
	for y in range(BOT + 12, 330, 16):
		L.R(img, 0, y, 640, 1, "g1")
	for xb in range(-600, 1300, 48):
		for y in range(BOT, 330):
			var x := int(round(vx(xb, BOT, y)))
			if x >= 0 and x < 640:
				img.set_pixel(x, y, L.col("g1"))
	L.R(img, 0, 330, 640, 4, "g3")
	L.R(img, 0, 330, 640, 1, "white")
	L.R(img, 0, 334, 640, 2, "g1")
	L.R(img, 0, 336, 640, 24, "d2")
	for x in range(0, 640, 40):
		L.R(img, x + 8, 350, 22, 2, "y0")             # faixa amarela do meio-fio? não: a do meio da rua, tracejada
	L.R(img, 0, 336, 640, 1, "d1")
	# bueiro (com forma: grade) e uma árvore de calçada com canteiro
	L.R(img, 430, 331, 18, 4, "d1")
	for gx in range(432, 448, 3):
		L.R(img, gx, 331, 1, 4, "g1")
	# postes (luz) e lixeira
	var l1 := lamp_post(img, 104, 52, 330, 34)
	var l2 := lamp_post(img, 494, 52, 330, -30)
	trash_small(img, 124, 330)
	L.light(img, Rect2i(0, 50, 640, 310), Vector2(150, 300), 210.0, 1.4, 3.0, -1, 1, 1.0)
	L.light(img, Rect2i(300, 50, 340, 310), Vector2(464, 300), 150.0, 1.4, 2.4, 0, 1, 0.6)
	glow(img, l1, 16, 9)
	glow(img, l2, 16, 9)
	spill(img, Vector2i(327, 262), 120, 36)          # luz da lanchonete na calçada
	raizes_poster(img, 95, 214, false)              # lambe-lambe pequeno no poste, perto do lutador
	return img

func trash_small(img: Image, x: int, base: int) -> void:
	L.R(img, x, base - 22, 14, 18, "gr1")
	L.R(img, x, base - 22, 14, 1, "gr2")
	L.R(img, x + 6, base - 4, 2, 4, "st1")
	L.R(img, x + 2, base - 18, 10, 1, "gr0")

func raizes_poster(img: Image, x: int, y: int, big: bool) -> void:
	## cartaz da escola: papel creme, R de raiz azul (o símbolo aprovado), "RAÍZES" e uma faixa "AULA GRÁTIS"
	var sym := Image.load_from_file(ASSETS_SRC("ui/school_symbol_16.png"))
	if big:
		L.R(img, x - 1, y - 1, 38, 50, "ink")
		L.R(img, x, y, 36, 48, "cream")
		L.R(img, x, y, 36, 1, "white")
		L.R(img, x + 1, y + 47, 35, 1, "g3")
		if sym != null:
			sym.convert(Image.FORMAT_RGBA8)
			L.blit(img, sym, x + 10, y + 3)
		L.text(img, "RAÍZES", x + 1, y + 22, "b1")
		L.R(img, x + 2, y + 32, 32, 9, "r2")
		L.text(img, "AULA", x + 7, y + 33, "white")
		L.R(img, x + 4, y + 43, 28, 1, "g2")
		L.R(img, x + 12, y - 2, 12, 3, "g3")         # fita
		L.R(img, x + 33, y + 40, 3, 7, "g3")          # ponta descolando
		L.P(img, x + 35, y + 47, "g2")
	else:
		L.R(img, x - 1, y - 1, 12, 16, "ink")
		L.R(img, x, y, 10, 14, "cream")
		L.R(img, x + 2, y + 2, 6, 6, "b1")
		L.R(img, x + 3, y + 3, 2, 4, "cream")
		L.R(img, x + 1, y + 10, 8, 2, "r2")

func ASSETS_SRC(rel: String) -> String:
	return ROOT + "assets/sprites/" + rel

# ------------------------------------------------------------------ fonte 3x5 (só para o recorte em 1x)
const MINI := {
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."], "U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"L": ["#..", "#..", "#..", "#..", "###"], "T": ["###", ".#.", ".#.", ".#.", ".#."],
	"O": ["###", "#.#", "#.#", "#.#", "###"],
}

func mini_text(img: Image, s: String, x: int, y: int, c) -> void:
	for i in s.length():
		var g: Array = MINI[s[i]]
		for r in 5:
			for k in 3:
				if g[r][k] == "#":
					L.P(img, x + i * 4 + k, y + r, c)

# ------------------------------------------------------------------ recorte de jornal do vigilante
func paper_sheet(img: Image, x0: int, y0: int, w: int, h: int, paper: String, seed: int) -> void:
	## papel com contorno ink contínuo e borda picotada: em cada mordida o contorno entra 1 px (nunca abre buraco)
	L.R(img, x0, y0, w, h, "ink")
	L.R(img, x0 + 1, y0 + 1, w - 2, h - 2, paper)
	for y in range(y0 + 3, y0 + h - 1):
		for side in [0, 1]:
			if rng_at(y, side, seed) > 0.62:
				var xo := x0 if side == 0 else x0 + w - 1
				var xi := x0 + 1 if side == 0 else x0 + w - 2
				img.set_pixel(xo, y, Color(0, 0, 0, 0))
				img.set_pixel(xi, y, L.col("ink"))
	for x in range(x0 + 2, x0 + w - 2):
		if rng_at(x, 7, seed) > 0.6:
			img.set_pixel(x, y0 + h - 1, Color(0, 0, 0, 0))
			img.set_pixel(x, y0 + h - 2, L.col("ink"))

## Silhueta do vigilante (original): capuz com orelhas de gato costuradas (triângulos largos, nas quinas da cabeça),
## faixa da escola amarrada nos olhos com as duas pontas voando para o lado, capa de lona CAINDO reta até o telhado
## (nunca aberta em asa), agachado com a mão no joelho. 'g' = faixa, 'w' = olho pela fresta, 'p' = remendo da lona.
const VIGIA_SMALL := [
	"#...#..",
	"#####..",
	"#g#g#gg",
	"#####.g",
	".###...",
	"#####..",
	"######.",
	"######.",
]
const VIGIA_BIG := [
	"..##.....##.......",
	"..###...###.......",
	"..#########.......",
	"..#########.......",
	"..#gwgggwg#ggg....",
	"..#ggggggg#.ggg...",
	"..#########...gg..",
	"...#######........",
	"..#########.......",
	".###########......",
	".############.....",
	"#####.###.###.....",
	"####..###.####....",
	"####.#####.###....",
	"###p######.###....",
	"###pp#####..##....",
	"##########..##....",
	"###########.##....",
	"############......",
]

func vigia(img: Image, rows: Array, x: int, y: int, band: String) -> void:
	for r in rows.size():
		var row: String = rows[r]
		for k in row.length():
			var ch := row[k]
			var c := ""
			match ch:
				"#": c = "ink"
				"g": c = band
				"w": c = "white"
				"p": c = "d2"
			if c != "":
				L.P(img, x + k, y + r, c)

## 23x28. Manchete "VULTO" legível em 1x (fonte 3x5), foto granulada com a silhueta pequena do vigilante, colunas de texto,
## borda picotada e fita. gym = luz fria dos tubos (papel mais claro); garagem = lâmpada quente (papel creme, sombra à esquerda).
func clipping(gym: bool) -> Image:
	var w := CLIP_SIZE.x
	var h := CLIP_SIZE.y
	var img: Image = L.blank(w, h)
	var paper := "white" if gym else "cream"
	var paper_d := "cream" if gym else "g3"
	paper_sheet(img, 0, 1, w, h - 1, paper, 41 if gym else 43)
	L.R(img, 2, h - 3, w - 4, 1, paper_d)            # papel amarelado embaixo
	# cabeçalho do jornal: nome em pontinhos e linha
	for x in range(4, w - 4, 2):
		L.P(img, x, 3, "g2")
	L.R(img, 2, 4, w - 4, 1, "g1")
	mini_text(img, "VULTO", 2, 6, "ink")
	# foto (x 2..12, y 13..23): noite granulada, lua, beira do telhado e o vigilante
	for y in range(13, 24):
		for x in range(2, 13):
			img.set_pixel(x, y, L.col("g1" if bayer(x, y) < 0.45 else "g0"))
	L.R(img, 10, 14, 2, 2, "cream")
	L.P(img, 11, 15, "g3")
	vigia(img, VIGIA_SMALL, 3, 14, "g3")
	L.R(img, 2, 22, 11, 2, "d2")
	L.R(img, 2, 22, 11, 1, "ink")
	# colunas de texto e legenda
	for y in range(13, 24, 2):
		L.R(img, 14, y, (6 if y != 21 else 4), 1, "g2")
	L.R(img, 2, 25, 12, 1, "g2")
	# fita adesiva no alto (meio transparente: dither)
	for y in range(0, 3):
		for x in range(8, 15):
			if (x + y) % 2 == 0 or y == 1:
				img.set_pixel(x, y, L.col("y2" if not gym else "white"))
	if not gym:
		# lâmpada à direita e em cima: canto de baixo à esquerda 1 passo mais escuro (dither)
		for y in range(12, h):
			for x in range(1, 7):
				var c := img.get_pixel(x, y)
				if c.a > 0.0 and c == L.col(paper) and bayer(x, y) < float(y - 12) / 16.0:
					img.set_pixel(x, y, L.shade(c, -1))
	return img


## Zoom do recorte para a dica (opcional, 100x84): o mesmo jornal grande, com o vigilante desenhado.
const ZOOM_MAST := "CORREIO DA ESQUINA"
const ZOOM_HEAD := ["VULTO", "MASCARADO"]

func clipping_zoom() -> Image:
	var w := 100
	var h := 84
	var img: Image = L.blank(w, h)
	L.R(img, 1, 3, w - 2, h - 4, "cream")
	for y in range(3, h - 1):
		for x in [1, w - 2]:
			if rng_at(x, y, 51) > 0.6:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	for x in range(1, w - 1):
		if rng_at(x, 0, 52) > 0.6:
			img.set_pixel(x, h - 2, Color(0, 0, 0, 0))
	var o: Image = L.outlined(img.get_region(Rect2i(1, 3, w - 2, h - 4)), "ink")
	var out: Image = L.blank(w, h)
	out.blit_rect(o, Rect2i(0, 0, w, h - 2), Vector2i(0, 2))
	img = out
	L.text_center(img, ZOOM_MAST, w / 2, 6, "g0")
	L.R(img, 4, 14, w - 8, 1, "ink")
	L.R(img, 4, 16, w - 8, 1, "g1")
	L.text(img, ZOOM_HEAD[0], 5, 19, "ink", 2)
	L.text(img, ZOOM_HEAD[1], 5, 35, "ink")
	# foto 44x36 em (5,45)
	var fx := 5
	var fy := 45
	for y in range(fy, fy + 34):
		for x in range(fx, fx + 44):
			var t := float(y - fy) / 34.0
			var c := "g1" if bayer(x, y) < 0.55 - t * 0.3 else "g0"
			img.set_pixel(x, y, L.col(c))
	L.ellipse(img, fx + 35, fy + 8, 5, 5, "cream")
	L.ellipse(img, fx + 36, fy + 7, 3, 3, "white")
	# telhados
	L.R(img, fx, fy + 27, 44, 7, "d2")
	L.line(img, fx, fy + 27, fx + 14, fy + 22, "d2")
	L.trap(img, fy + 22, fy + 27, fx + 14, fx + 14, fx, fx + 14, "d2")
	L.R(img, fx + 30, fy + 20, 3, 7, "d2")            # chaminé
	# o vigilante agachado na beira do telhado, de frente, capa caindo
	vigia(img, VIGIA_BIG, fx + 12, fy + 8, "g3")
	for p in [Vector2i(fx + 15, fy + 9), Vector2i(fx + 21, fy + 9)]:
		img.set_pixel(p.x, p.y, L.col("g1"))   # costura das orelhas
	L.R(img, fx, fy + 34, 44, 1, "ink")
	L.R(img, fx, fy - 1, 44, 1, "ink")
	L.R(img, fx - 1, fy, 1, 34, "ink")
	L.R(img, fx + 44, fy, 1, 34, "ink")
	# colunas de texto
	for y in range(fy, h - 6, 3):
		L.R(img, 54, y, 41 - (7 if y % 9 == 0 else 0), 1, "g2")
	L.R(img, 5, h - 5, 30, 1, "g2")
	# fita
	for y in range(0, 5):
		for x in range(40, 60):
			if (x + y) % 2 == 0 or y == 2:
				img.set_pixel(x, y, L.col("y2"))
	return img

# ------------------------------------------------------------------ peças de HUD
func hud_pieces() -> Dictionary:
	var d := {}
	d["ui_tug_track"] = [tug_track()]
	d["ui_tug_marker"] = [tug_marker(0), tug_marker(1), tug_marker(2)]
	d["ui_tug_touch"] = [touch_burst(0), touch_burst(1), touch_burst(2)]
	d["ui_point_pip"] = [pip("d2"), pip("y1"), pip("r2")]
	d["ui_breath_bar"] = [breath_frame()]
	d["ui_breath_fill"] = [fill4("gr2", "gr3"), fill4("y0", "y1"), fill4("r1", "r2")]
	d["icon_breath"] = [icon_breath()]
	d["ui_warn_burst"] = [warn(0, 0), warn(0, 1)]
	d["ui_warn_pause"] = [warn(2, 0), warn(2, 1)]
	d["ui_warn_feint"] = [warn(0, 0), warn(1, 0), warn(2, 0)]
	d["ui_counter_x2"] = [badge_x2(0), badge_x2(1)]
	d["icon_warm"] = [icon_warm(9)]
	d["icon_warm_16"] = [icon_warm(16)]
	d["icon_spar_16"] = [icon_spar()]
	d["icon_flyers_16"] = [icon_flyers()]
	d["ui_invite_go"] = [invite_go(0), invite_go(1), invite_go(2)]
	d["icon_flyer"] = [icon_flyer()]
	d["ui_flyer_fly"] = [flyer_fly(0), flyer_fly(1), flyer_fly(2)]
	d["ui_tell_mark"] = [tell_mark(0), tell_mark(1), tell_mark(2)]
	return d

## Barra do cabo de guerra, 260x16. Esquerda = o seu lado (azul), direita = o lado dele (vermelho).
## O marcador anda de x 8 (-1, ele te encostou) a x 251 (+1, você encostou ele). Marcas em 1/4, meio e 3/4.
func tug_track() -> Image:
	var w := TUG.size.x
	var h := TUG.size.y
	var img: Image = L.blank(w, h)
	L.R(img, 0, 1, w, h - 2, "ink")
	L.R(img, 1, 0, w - 2, h, "ink")
	L.R(img, 2, 2, w - 4, h - 4, "d1")
	# metade sua e metade dele, em dither escuro (não briga com o marcador)
	for y in range(3, h - 3):
		for x in range(3, w - 3):
			var mine := x < w / 2
			if (x + y) % 2 == 0:
				img.set_pixel(x, y, L.col("b0" if mine else "r0"))
	# pontas: "parede" de cada lado (onde encosta)
	L.R(img, 2, 2, 6, h - 4, "b1")
	L.R(img, 2, 2, 6, 1, "b2")
	L.R(img, 2, 2, 1, h - 4, "b2")
	L.R(img, w - 8, 2, 6, h - 4, "r1")
	L.R(img, w - 8, 2, 6, 1, "r2")
	L.R(img, w - 3, 2, 1, h - 4, "r0")
	L.R(img, 8, 2, 1, h - 4, "ink")
	L.R(img, w - 9, 2, 1, h - 4, "ink")
	# marcas
	L.R(img, w / 2 - 1, 1, 2, h - 2, "g2")
	L.R(img, w / 2 - 1, 1, 2, 1, "g3")
	for q in [w / 4, 3 * w / 4]:
		L.R(img, q, 3, 1, 2, "g0")
		L.R(img, q, h - 5, 1, 2, "g0")
	L.R(img, 3, h - 3, w - 6, 1, "ink")
	return img

## Marcador 11x22 (pivô 5,11, o meio da barra): 0 normal, 1 empurrado (claro, 1 quadro na tremida), 2 contragolpe (ouro).
func tug_marker(state: int) -> Image:
	var img: Image = L.blank(11, 22)
	var body: String = ["y0", "y2", "y1"][state]
	var hi: String = ["y1", "white", "y2"][state]
	# agulha: cabeça em triângulo que aponta para a barra, haste de 3 px atravessando a barra, ponta embaixo
	var shape := [
		"###########",
		"#ooooooooo#",
		".#ooooooo#.",
		"..#ooooo#..",
		"...#ooo#...",
		"....#o#....",
	]
	for r in shape.size():
		for k in 11:
			var ch: String = shape[r][k]
			if ch == "#":
				img.set_pixel(k, r, L.col("ink"))
			elif ch == "o":
				img.set_pixel(k, r, L.col(body))
	L.R(img, 4, 5, 3, 15, "ink")
	L.R(img, 5, 5, 1, 14, body)
	L.R(img, 3, 19, 5, 3, "ink")
	L.R(img, 4, 19, 3, 2, body)
	L.R(img, 2, 1, 6, 1, hi)
	if state == 2:
		L.R(img, 1, 1, 9, 1, "white")
	return img

## ENCOSTOU: estalo 24x24 na ponta da barra (3 quadros, ~0,06 s cada; depois some).
func touch_burst(f: int) -> Image:
	var img: Image = L.blank(24, 24)
	var r: float = [5.0, 9.0, 11.0][f]
	var n := 8
	for i in n:
		var a := float(i) / n * TAU + (0.2 if f == 1 else 0.0)
		var len: float = r if i % 2 == 0 else r * 0.6
		var x1 := int(round(12 + cos(a) * len))
		var y1 := int(round(12 + sin(a) * len))
		L.line(img, 12, 12, x1, y1, "y2" if f < 2 else "y1")
	if f == 0:
		L.ellipse(img, 12, 12, 4, 4, "white")
	elif f == 1:
		L.ellipse(img, 12, 12, 3, 3, "y2")
	else:
		L.ring(img, 12, 12, 7, 7, 1, "y0")
	return L.outlined(img.get_region(Rect2i(1, 1, 22, 22)), "ink") if f < 2 else img

func pip(c: String) -> Image:
	var img: Image = L.blank(7, 7)
	L.rrect(img, 0, 0, 7, 7, "ink")
	L.rrect(img, 1, 1, 5, 5, c)
	if c != "d2":
		L.R(img, 2, 2, 2, 1, L.shade(L.col(c), 1))
	else:
		L.R(img, 2, 4, 3, 1, "d1")
	return img

func breath_frame() -> Image:
	var img: Image = L.blank(8, 6)
	L.R(img, 0, 0, 8, 6, "ink")
	L.R(img, 1, 1, 6, 4, "d1")
	L.R(img, 1, 4, 6, 1, "ink")
	return img

func fill4(base: String, hi: String) -> Image:
	var img: Image = L.blank(4, 4)
	L.R(img, 0, 0, 4, 4, base)
	L.R(img, 0, 0, 4, 1, hi)
	L.P(img, 0, 3, L.shade(L.col(base), -1))
	return img

func icon_breath() -> Image:
	## sopro: três linhas de ar curvas saindo para a direita
	var img: Image = L.blank(9, 9)
	var rows := [
		"..##.....",
		".#..#....",
		"....#####",
		".........",
		"#######..",
		".........",
		"...#####.",
		".......#.",
		".....##..",
	]
	for r in 9:
		for k in 9:
			if rows[r][k] == "#":
				img.set_pixel(k, r, L.col("b3"))
	var o: Image = L.outlined(img.get_region(Rect2i(0, 0, 9, 9)), "ink")
	return o.get_region(Rect2i(1, 1, 9, 9)) if false else _fit(o, 9)

func _fit(o: Image, s: int) -> Image:
	## recorta uma imagem contornada (s+2) para s mantendo o contorno de dentro
	var out: Image = L.blank(s, s)
	out.blit_rect(o, Rect2i(1, 1, s, s), Vector2i.ZERO)
	return out

## Aviso 17x17 acima da cabeça do parceiro.
## kind 0 = rajada/puxada: estrela pontuda VERMELHA com "!" branco. kind 2 = pausa ("ELE ABRIU!"): balão REDONDO BRANCO
## com "!" escuro. kind 1 = o meio da finta (pontas recolhendo, metade branca). Forma e cor mudam juntas (lê sem cor).
func warn(kind: int, pulse: int) -> Image:
	var img: Image = L.blank(17, 17)
	var c := Vector2(8.5, 8.5)
	for y in 17:
		for x in 17:
			var d := Vector2(x + 0.5, y + 0.5) - c
			var a := atan2(d.y, d.x)
			var spikes := 0.5 + 0.5 * cos(a * 8.0)
			var rr: float
			if kind == 0:
				rr = 5.2 + spikes * 3.2 + pulse * 0.6
			elif kind == 1:
				rr = 6.2 + spikes * 1.6
			else:
				rr = 6.6 + pulse * 0.8
			if d.length() <= rr:
				var col := "r2"
				if kind == 2:
					col = "white"
				elif kind == 1:
					col = "white" if (x + y) % 2 == 0 or d.length() < 4.0 else "r2"
				img.set_pixel(x, y, L.col(col))
	var o := _fit(L.outlined(img, "ink"), 17)
	# realce e sombra
	for y in 17:
		for x in 17:
			var p := o.get_pixel(x, y)
			if p.a > 0.0 and p != L.col("ink") and y > 11 and (kind != 1):
				o.set_pixel(x, y, L.shade(p, -1))
	var bang: Color = L.col("white") if kind == 0 else L.col("ink")
	if kind == 1:
		bang = L.col("r1")
	o.fill_rect(Rect2i(7, 3 + (0 if pulse == 0 else 0), 3, 7), bang)
	o.fill_rect(Rect2i(7, 11, 3, 3), bang)
	o.set_pixel(7, 9, Color(0, 0, 0, 0) if false else o.get_pixel(6, 9))
	return o

func badge_x2(f: int) -> Image:
	var img: Image = L.blank(19, 13)
	L.rrect(img, 0, 0, 19, 13, "ink")
	L.rrect(img, 1, 1, 17, 11, "y1" if f == 0 else "y2")
	L.R(img, 2, 10, 15, 1, "y0")
	L.text(img, "X2", 4, 3, "ink")
	return img

func icon_warm(s: int) -> Image:
	## AQUECIDO: chama laranja com miolo claro (corpo quente, pronto para lutar). 9x9 (HUD/prévia) e 16x16.
	var img: Image = L.blank(s, s)
	var f := float(s) / 9.0
	var shapes := []
	for y in s:
		for x in s:
			var u := (x + 0.5) / f
			var v := (y + 0.5) / f
			# chama: gota invertida com uma lambida à esquerda
			var cx := 4.5 + sin(v * 0.9) * 0.6
			var wdt := 3.6 * clampf((v - 1.0) / 6.0, 0.0, 1.0)
			if v > 7.6:
				wdt = maxf(0.0, 3.6 - (v - 7.6) * 3.0)
			var inside := absf(u - cx) <= wdt
			var tongue := Vector2(u - 2.6, v - 3.2).length() < 1.0
			if inside or tongue:
				var core := absf(u - cx) <= wdt * 0.45 and v > 4.4
				img.set_pixel(x, y, L.col("y1" if core else ("r2" if v < 4.0 else "y0")))
				if core and v > 6.0:
					img.set_pixel(x, y, L.col("y2"))
	return _fit(L.outlined(img, "ink"), s)

func icon_spar() -> Image:
	## Choque: duas luvas frente a frente com um estalo no meio
	var img: Image = L.blank(16, 16)
	L.glove(img, 0, 5, 7, 7, ["r0", "r1", "r2", "r3"])
	var g2: Image = L.blank(16, 16)
	L.glove(g2, 0, 5, 7, 7, ["b0", "b1", "b2", "b3"])
	L.blit(img, L.flipped(g2), 0, 0)
	L.R(img, 7, 2, 2, 3, "y1")
	L.P(img, 6, 3, "y1")
	L.P(img, 9, 3, "y1")
	return _fit(L.outlined(img.get_region(Rect2i(0, 0, 16, 16)), "ink"), 16)

func icon_flyers() -> Image:
	## Panfletagem: maço de panfletos creme em leque, o de cima com o R azul da escola
	var img: Image = L.blank(16, 16)
	for i in 3:
		var ox := 2 + i * 2
		var oy := 4 - i
		L.R(img, ox, oy, 9, 11, ["g3", "cream", "white"][i])
	L.R(img, 8, 5, 4, 5, "b1")
	L.R(img, 9, 6, 1, 3, "white")
	L.R(img, 10, 6, 1, 1, "white")
	L.R(img, 7, 11, 6, 1, "r2")
	L.R(img, 7, 13, 5, 1, "g2")
	return _fit(L.outlined(img.get_region(Rect2i(0, 0, 16, 16)), "ink"), 16)

## Botão IR dentro do balão do convite: 9-slice 14x13 (3/3/3/4). 0 normal, 1 hover, 2 apertado. Ouro do Osmar (y0), texto ink.
func invite_go(state: int) -> Image:
	var img: Image = L.blank(14, 13)
	var bg: String = ["y0", "y1", "y0"][state]
	var top := 0 if state < 2 else 1
	L.R(img, 1, 12, 13, 1, "ink")
	L.rrect(img, 0, top, 14, 12, "ink")
	L.R(img, 1, top + 1, 12, 10, bg)
	if state < 2:
		L.R(img, 1, top + 1, 12, 1, L.shade(L.col(bg), 1))
		L.R(img, 1, top + 9, 12, 2, L.shade(L.col(bg), -1))
	return img

func icon_flyer() -> Image:
	var img: Image = L.blank(9, 9)
	L.R(img, 1, 0, 7, 9, "ink")
	L.R(img, 2, 1, 5, 7, "cream")
	L.R(img, 3, 2, 3, 3, "b1")
	L.P(img, 4, 3, "cream")
	L.R(img, 3, 6, 3, 1, "r2")
	return img

func flyer_fly(f: int) -> Image:
	## panfleto saindo da mão até a pessoa (gira: de frente, de quina, de frente)
	var img: Image = L.blank(9, 7)
	if f == 1:
		L.R(img, 3, 0, 3, 7, "ink")
		L.R(img, 4, 1, 1, 5, "cream")
	else:
		L.R(img, 0, 1, 9, 5, "ink")
		L.R(img, 1, 2, 7, 3, "cream" if f == 0 else "white")
		L.R(img, 2, 2, 2, 2, "b1")
	return img

## "?" do sinal (acima da cabeça de quem quer o panfleto), 7x11. 0 aparecendo, 1 cheio, 2 sumindo (o sinal falso termina assim).
func tell_mark(f: int) -> Image:
	var img: Image = L.blank(7, 11)
	var q := [
		".###.",
		"#...#",
		"....#",
		"...#.",
		"..#..",
		".....",
		"..#..",
	]
	var c: String = ["y1", "y2", "g2"][f]
	var yoff: int = [2, 0, 1][f]
	var core: Image = L.blank(5, 7)
	for r in 7:
		for k in 5:
			if q[r][k] == "#":
				core.set_pixel(k, r, L.col(c))
	var o: Image = L.outlined(core, "ink")
	if f == 2:
		for y in o.get_height():
			for x in o.get_width():
				if (x + y) % 2 == 1:
					o.set_pixel(x, y, Color(0, 0, 0, 0))
	L.blit(img, o, 0, yoff)
	return img

# ------------------------------------------------------------------ montagem dos mockups
func draw_tug(img: Image, ui: Dictionary, v: float, marker_state := 0) -> int:
	L.blit(img, ui["ui_tug_track"][0], TUG.position.x, TUG.position.y)
	var mx := TUG.position.x + int(round(lerpf(TUG_INNER.x, TUG_INNER.y, (v + 1.0) * 0.5)))
	L.blit(img, ui["ui_tug_marker"][marker_state], mx - 5, TUG.position.y + 8 - 11)
	return mx

func spar_hud(img: Image, ui: Dictionary, o: Dictionary) -> void:
	# tempo
	L.panel(img, 296, 4, 48, 18, "d1", "d2", "ink")
	L.text_center(img, o.get("time", "24 S"), 320, 9, "white")
	# placar e pips: você à esquerda (azul), ele à direita (vermelho)
	L.text(img, "VOCÊ", TUG.position.x, 8, "b3", 1, "ink")
	L.text(img, "%d" % o.get("you", 1), TUG.position.x + 28, 8, "white", 1, "ink")
	for i in 3:
		L.blit(img, ui["ui_point_pip"][1 if i < o.get("you", 1) else 0], TUG.position.x + 38 + i * 9, 8)
	var right := TUG.end.x
	L.text_right(img, "ELE", right, 8, "r3", 1, "ink")
	L.text_right(img, "%d" % o.get("him", 0), right - 22, 8, "white", 1, "ink")
	for i in 3:
		L.blit(img, ui["ui_point_pip"][2 if i < o.get("him", 0) else 0], right - 58 + i * 9, 8)
	var mx := draw_tug(img, ui, o.get("v", 0.2), o.get("marker", 0))
	# fôlego (só o seu), embaixo da barra à esquerda
	var by := TUG.end.y + 6
	L.blit(img, ui["icon_breath"][0], TUG.position.x, by - 1)
	var bw := 96
	nine(img, ui["ui_breath_bar"][0], TUG.position.x + 12, by, bw, 6, 1, 1, 1, 1)
	var fr: float = o.get("breath", 0.8)
	var fi := 0 if fr > 0.5 else (1 if fr > 0.25 else 2)
	var fw := int((bw - 2) * fr)
	for x in range(0, fw, 4):
		var tile: Image = ui["ui_breath_fill"][fi]
		L.blit(img, tile.get_region(Rect2i(0, 0, mini(4, fw - x), 4)), TUG.position.x + 13 + x, by + 1)
	L.text(img, "FÔLEGO", TUG.position.x + 12 + bw + 4, by - 1, "g3", 1, "ink")
	if o.get("x2", false):
		L.blit(img, ui["ui_counter_x2"][0], mx - 9, TUG.position.y - 15)
	if o.get("touch", false):
		L.blit(img, ui["ui_tug_touch"][1], TUG.end.x - 18, TUG.position.y - 4)
		L.text_center(img, "ENCOSTOU!", TUG.end.x - 6, TUG.end.y + 4, "y1", 1, null, "ink")
	# SAIR e dica
	button_small(img, 8, 334, 48, 18, "SAIR")
	if o.has("tip"):
		L.text_center(img, o["tip"], 320, 343, "cream", 1, "ink")

func button_small(img: Image, x: int, y: int, w: int, h: int, label: String) -> void:
	var src := Image.load_from_file(ASSETS_SRC("ui/ui_button_normal.png"))
	if src == null:
		L.button(img, x, y, w, h, "g0", label)
		return
	src.convert(Image.FORMAT_RGBA8)
	nine(img, src, x, y, w, h, 2, 2, 2, 4)
	L.text_center(img, label, x + w / 2, y + (h - 7) / 2 - 1, "white", 1, "ink")

func mock_spar(bg: Image, ui: Dictionary, variant: String) -> Image:
	var img: Image = bg.duplicate()
	# Osmar lá atrás, na porta (escala da sala)
	floor_shadow(img, SPAR_COACH.x, SPAR_COACH.y, 10)
	put(img, frame("assets/sprites/characters/coach_idle.png", 48, 72), SPAR_COACH, Vector2i(22, 67))
	floor_shadow(img, SPAR_PLAYER_X, SPAR_FEET_Y, 18)
	floor_shadow(img, SPAR_PARTNER_X, SPAR_FEET_Y, 18)
	var p := frame("assets/sprites/fight/fight_player_idle.png", 112, 104)
	var e := frame("assets/sprites/opponents/opp_gym_1/opp_gym_1_idle.png", 112, 104)
	if variant == "boxe":
		e = frame("assets/sprites/opponents/opp_gym_1/opp_gym_1_block.png", 112, 104, 1)
	else:
		p = frame("assets/sprites/fight/fight_player_block.png", 112, 104)
		e = frame("assets/sprites/opponents/opp_gym_1/opp_gym_1_hit_clinch.png", 112, 104)
	put(img, p, Vector2i(SPAR_PLAYER_X, SPAR_FEET_Y), Vector2i(56, 98))
	put(img, e, Vector2i(SPAR_PARTNER_X, SPAR_FEET_Y), Vector2i(56, 98))
	# aviso acima da cabeça do parceiro
	var wk := "ui_warn_burst"
	L.blit(img, ui[wk][0], SPAR_PARTNER_X - 8, 196)
	if variant == "boxe":
		L.text_center(img, "RAJADA!", SPAR_PARTNER_X, 186, "r3", 1, null, "ink")
		spar_hud(img, ui, {"v": 0.35, "you": 1, "him": 0, "breath": 0.7, "time": "21 S",
			"tip": "CLIQUE PARA EMPURRAR. SEGURE NA RAJADA."})
	else:
		L.text_center(img, "PUXADA!", SPAR_PARTNER_X, 186, "r3", 1, null, "ink")
		spar_hud(img, ui, {"v": -0.4, "you": 0, "him": 1, "breath": 0.22, "time": "12 S",
			"tip": "SEGURE PARA PUXAR. SOLTE QUANDO ELE PUXAR."})
	L.text(img, "CHOQUE: TROCA FRANCA" if variant == "boxe" else "CHOQUE: DISPUTA DE PEGADA", 8, 8, "y1", 1, "ink")
	return img

func board_states(bg: Image, ui: Dictionary) -> Image:
	## Estados da barra em 3x: cada faixa é o topo da tela (0..72) com o parceiro e o aviso ao lado
	var states := [
		["NORMAL", {"v": 0.1, "breath": 0.9}, "", 0],
		["AVISO DE RAJADA", {"v": 0.0, "breath": 0.8}, "ui_warn_burst", 0],
		["PAUSA: ELE ABRIU (X2)", {"v": 0.3, "breath": 0.9, "x2": true, "marker": 2}, "ui_warn_pause", 0],
		["FINTA: O ! VIRA BRANCO", {"v": -0.1, "breath": 0.6}, "ui_warn_feint", -1],
		["ENCOSTOU!", {"v": 1.0, "breath": 0.5, "touch": true, "marker": 1, "you": 2}, "", 0],
		["FÔLEGO BAIXO (AFOBADO)", {"v": -0.5, "breath": 0.12, "him": 1}, "", 0],
	]
	var cw := 300
	var chh := 76
	var out: Image = L.blank(cw * 2 + 12, (chh + 12) * 3 + 4)
	out.fill(L.col("ink"))
	for i in states.size():
		var st: Array = states[i]
		var cell: Image = bg.get_region(Rect2i(170, 0, cw, chh))
		var full: Image = bg.get_region(Rect2i(0, 0, 640, 360))
		var o: Dictionary = st[1].duplicate()
		o["time"] = "18 S"
		spar_hud(full, ui, o)
		cell = full.get_region(Rect2i(170, 0, cw, chh))
		if st[2] != "":
			var fr: Array = ui[st[2]]
			if st[3] == -1:
				for k in fr.size():
					L.blit(cell, fr[k], 232 + k * 20, 48 - 1)
			else:
				L.blit(cell, fr[0], 262, 47)
		L.text(cell, st[0], 4, 64, "white", 1, "ink")
		var cx := (i % 2) * (cw + 6) + 3
		var cy := (i / 2) * (chh + 12) + 3
		out.blit_rect(cell, Rect2i(0, 0, cw, chh), Vector2i(cx, cy))
	return scaled(out, 3)

func mock_flyers(bg: Image, ui: Dictionary) -> Image:
	var img: Image = bg.duplicate()
	# pedestres (folhas da sala só para medir): passando na calçada, pés em FLY_WALK_Y
	var walkers := [
		["neighbor_2_idle", 196, true, false], ["uncle_1_idle", 300, false, true],
		["neighbor_3_idle", 404, true, false], ["uncle_2_idle", 520, false, false],
	]
	for w in walkers:
		floor_shadow(img, w[1], FLY_WALK_Y, 9)
	for w in walkers:
		var piv := Vector2i(25 if String(w[0]).begins_with("uncle") else 22, 67)
		put(img, frame("assets/sprites/characters/%s.png" % w[0], 48, 72), Vector2i(w[1], FLY_WALK_Y), piv, w[2])
		if w[3]:
			L.blit(img, ui["ui_tell_mark"][1], w[1] - 3, FLY_WALK_Y - 80)
	# o lutador na frente, à esquerda, e o Osmar no canto direito
	floor_shadow(img, FLY_FIGHTER.x, FLY_FIGHTER.y, 10)
	put(img, frame("assets/sprites/characters/fighter_idle.png", 48, 72), FLY_FIGHTER, Vector2i(22, 67))
	L.blit(img, ui["ui_flyer_fly"][0], FLY_FIGHTER.x + 16, FLY_FIGHTER.y - 40)
	floor_shadow(img, FLY_COACH.x, FLY_COACH.y, 10)
	put(img, frame("assets/sprites/characters/coach_idle.png", 48, 72), FLY_COACH, Vector2i(22, 67), true)
	# HUD
	L.panel(img, 264, 4, 112, 20, "d1", "d2", "ink")
	L.blit(img, ui["icon_flyer"][0], 272, 9)
	L.text(img, "4 DE 10", 286, 10, "white")
	L.panel(img, 584, 4, 48, 18, "d1", "d2", "ink")
	L.text_center(img, "17 S", 608, 9, "white")
	L.text(img, "PANFLETAGEM", 8, 8, "y1", 1, "ink")
	L.text_center(img, "ACEITOU!", 300, FLY_WALK_Y - 94, "gr3", 1, null, "ink")
	L.text_center(img, "NÃO, VALEU", 520, FLY_WALK_Y - 84, "g3", 1, null, "ink")
	button_small(img, 8, 334, 48, 18, "SAIR")
	L.text_center(img, "ENTREGUE PARA QUEM OLHAR O CARTAZ.", 320, 343, "cream", 1, "ink")
	return img

func room_with(bg_rel: String, objs: Array) -> Image:
	var img := Image.load_from_file(ASSETS_SRC(bg_rel))
	img.convert(Image.FORMAT_RGBA8)
	for o in objs:
		var s := Image.load_from_file(ASSETS_SRC(o[0]))
		if s == null:
			continue
		s.convert(Image.FORMAT_RGBA8)
		var fw: int = o[2]
		var fh: int = o[3]
		L.blit(img, s.get_region(Rect2i(fw * int(o[4]), 0, fw, fh)), o[1].x, o[1].y)
	return img

func garage_room(clip: Image) -> Image:
	var img := room_with("garage/garage_bg.png", [
		["garage/wall_form_named.png", Vector2i(205, 62), 22, 24, 0],
		["garage/wall_photo_old.png", Vector2i(237, 67), 18, 21, 0],
		["garage/wall_clipping.png", Vector2i(236, 40), 20, 24, 0],
		["garage/wall_photo_team.png", Vector2i(176, 54), 26, 21, 0],
		["garage/wall_school_symbol.png", Vector2i(344, 38), 32, 40, 0],
		["garage/wall_mural.png", Vector2i(176, 128), 55, 23, 1],
		["garage/lamp.png", Vector2i(286, 32), 30, 48, 0],
	])
	L.blit(img, clip, CLIP_GARAGE.x, CLIP_GARAGE.y)
	return img

func gym_room(clip: Image) -> Image:
	var img := room_with("gym/gym_bg.png", [
		["gym/wall_photo_old_gym.png", Vector2i(212, 158), 18, 21, 1],
		["gym/wall_mural_gym.png", Vector2i(176, 128), 55, 23, 1],
	])
	L.blit(img, clip, CLIP_GYM.x, CLIP_GYM.y)
	return img

func check_spots() -> void:
	## o recorte não pode encostar em nada da parede nem nas correntes (x 257 do saco de lado, x 335 do saco no centro)
	var busy := {
		"garage": [Rect2i(205, 62, 22, 24), Rect2i(237, 67, 18, 21), Rect2i(236, 40, 20, 24), Rect2i(176, 54, 26, 21),
			Rect2i(344, 38, 32, 40), Rect2i(176, 128, 55, 23), Rect2i(286, 32, 30, 48), Rect2i(231, 93, 18, 26),
			Rect2i(256, 33, 3, 130), Rect2i(334, 33, 3, 150), Rect2i(273, 150, 98, 141), Rect2i(266, 62, 33, 42)],
		"gym": [Rect2i(212, 158, 18, 21), Rect2i(176, 128, 55, 23), Rect2i(174, 169, 48, 72), Rect2i(256, 33, 3, 130),
			Rect2i(334, 33, 3, 150), Rect2i(273, 150, 98, 141), Rect2i(178, 112, 80, 14), Rect2i(262, 50, 70, 70),
			Rect2i(180, 52, 56, 44), Rect2i(236, 36, 16, 18), Rect2i(262, 30, 76, 22), Rect2i(370, 74, 28, 54)],
	}
	var spots := {"garage": Rect2i(CLIP_GARAGE, CLIP_SIZE), "gym": Rect2i(CLIP_GYM, CLIP_SIZE)}
	var bad := 0
	for k in spots:
		for r in busy[k]:
			if spots[k].intersects(r):
				print("CONFERÊNCIA: recorte %s encosta em %s" % [k, r])
				bad += 1
	print("conferência do recorte: %d problema(s)" % bad)

func board_clipping(cg: Image, cy: Image, zoom: Image) -> Image:
	var g := garage_room(cg)
	var y := gym_room(cy)
	var out: Image = L.blank(1300, 600)
	out.fill(L.col("ink"))
	# salas inteiras em 1x (tamanho real) em cima
	out.blit_rect(g, Rect2i(0, 0, 640, 360), Vector2i(4, 4))
	out.blit_rect(y, Rect2i(0, 0, 640, 360), Vector2i(652, 4))
	L.text(out, "GARAGEM 1X (RECORTE EM %d,%d)" % [CLIP_GARAGE.x, CLIP_GARAGE.y], 8, 368, "white")
	L.text(out, "ACADEMIA 1X (RECORTE EM %d,%d)" % [CLIP_GYM.x, CLIP_GYM.y], 656, 368, "white")
	# recortes em 3x com a parede em volta
	var gc := scaled(g.get_region(Rect2i(CLIP_GARAGE.x - 34, CLIP_GARAGE.y - 14, 90, 60)), 3)
	var yc := scaled(y.get_region(Rect2i(CLIP_GYM.x - 34, CLIP_GYM.y - 14, 90, 60)), 3)
	out.blit_rect(gc, Rect2i(0, 0, 270, 180), Vector2i(4, 384))
	out.blit_rect(yc, Rect2i(0, 0, 270, 180), Vector2i(282, 384))
	L.text(out, "3X", 8, 570, "white")
	# zoom (dica opcional) em 2x
	var z := scaled(zoom, 2)
	out.blit_rect(z, Rect2i(0, 0, 200, 168), Vector2i(570, 390))
	L.text(out, "ZOOM DA DICA 2X (OPCIONAL)", 570, 566, "white")
	# recorte sozinho em 6x
	var s := scaled(cg, 6)
	out.blit_rect(s, Rect2i(0, 0, 138, 168), Vector2i(800, 390))
	var s2 := scaled(cy, 6)
	out.blit_rect(s2, Rect2i(0, 0, 138, 168), Vector2i(950, 390))
	L.text(out, "GARAGEM 6X", 800, 566, "white")
	L.text(out, "ACADEMIA 6X", 950, 566, "white")
	return out

func board_invite(ui: Dictionary) -> Image:
	## sala da garagem com o Osmar no ponto dele (52,258) e o balão do convite com IR; ao lado, AQUECIDO na prévia/HUD
	var img := Image.load_from_file(ASSETS_SRC("garage/garage_bg.png"))
	img.convert(Image.FORMAT_RGBA8)
	var coach := Vector2i(52, 258)
	floor_shadow(img, coach.x, coach.y, 10)
	put(img, frame("assets/sprites/characters/coach_idle.png", 48, 72), coach, Vector2i(22, 67))
	var bal := Image.load_from_file(ASSETS_SRC("ui/ui_balloon.png"))
	bal.convert(Image.FORMAT_RGBA8)
	var tail := Image.load_from_file(ASSETS_SRC("ui/ui_balloon_tail_l.png"))
	tail.convert(Image.FORMAT_RGBA8)
	var tag := Image.load_from_file(ASSETS_SRC("ui/ui_balloon_tag_gold.png"))
	tag.convert(Image.FORMAT_RGBA8)
	var bx := 6
	var by := 150
	var bw: int = L.text_w("depois do expediente") + 5 + 4 + 22 + 5
	var bh := 26
	nine(img, bal, bx, by, bw, bh, 5, 5, 5, 5)
	L.blit(img, tail, coach.x - 14, by + bh - 2)
	var tw: int = L.text_w("osmar") + 6
	nine(img, tag, bx + 6, by - 6, tw, 10, 2, 2, 2, 2)
	L.text(img, "osmar", bx + 9, by - 5, "ink")
	L.text(img, "depois do expediente", bx + 5, by + 5, "ink")
	L.text(img, "tem sparring. vem?", bx + 5, by + 14, "ink")
	# IR: 22x13 à direita dentro do balão, alinhado com a 2ª linha
	nine(img, ui["ui_invite_go"][0], bx + bw - 27, by + 8, 22, 13, 3, 3, 3, 4)
	L.text_center(img, "IR", bx + bw - 16, by + 10, "ink")
	var crop := img.get_region(Rect2i(0, 120, 320, 220))
	var out: Image = L.blank(640 + 8, 440 + 8)
	out.fill(L.col("ink"))
	out.blit_rect(scaled(crop, 2), Rect2i(0, 0, 640, 440), Vector2i(4, 4))
	# AQUECIDO: linha da prévia e o ícone no risco do HUD (amostras, posição final é do UI/UX)
	var side: Image = L.blank(160, 220)
	side.fill(L.col("ink"))
	L.panel(side, 4, 4, 152, 60, "d1", "d2", "ink")
	L.text(side, "PRÓXIMA LUTA", 10, 9, "g3")
	L.blit(side, ui["icon_warm"][0], 10, 22)
	L.text(side, "AQUECIDO:", 22, 23, "y1")
	L.text(side, "+3% NOS ATRIBUTOS", 10, 34, "white")
	L.text(side, "(+2 NA CHANCE)", 10, 44, "g3")
	L.panel(side, 4, 72, 90, 18, "d1", "d2", "ink")
	L.text(side, "RISCO", 10, 77, "g3")
	L.blit(side, ui["icon_warm"][0], 80, 76)
	L.blit(side, ui["icon_warm_16"][0], 10, 100)
	L.blit(side, ui["icon_spar_16"][0], 34, 100)
	L.blit(side, ui["icon_flyers_16"][0], 58, 100)
	L.text(side, "16X16: PRÊMIO", 10, 120, "g3")
	var s2 := scaled(side, 2)
	var big: Image = L.blank(out.get_width() + s2.get_width() + 4, out.get_height())
	big.fill(L.col("ink"))
	big.blit_rect(out, Rect2i(Vector2i.ZERO, out.get_size()), Vector2i.ZERO)
	big.blit_rect(s2, Rect2i(0, 0, s2.get_width(), mini(s2.get_height(), out.get_height())), Vector2i(out.get_width() + 2, 4))
	return big

func board_pieces(ui: Dictionary, cg: Image, cy: Image) -> Image:
	var names := ui.keys()
	var out: Image = L.blank(420, 300)
	out.fill(L.col("d1"))
	var x := 6
	var y := 6
	var rowh := 0
	for n in names:
		var fr: Array = ui[n]
		var w: int = fr[0].get_width()
		var h: int = fr[0].get_height()
		var tot := (w + 3) * fr.size()
		var lw := maxi(tot, L.text_w(String(n).replace("_", " ").to_upper()) + 2)
		if x + lw > 414:
			x = 6
			y += rowh + 14
			rowh = 0
		for i in fr.size():
			L.blit(out, fr[i], x + i * (w + 3), y)
		L.text(out, String(n).replace("_", " ").to_upper(), x, y + h + 2, "g3")
		rowh = maxi(rowh, h)
		x += lw + 8
	L.blit(out, cg, 6, y + rowh + 16)
	L.blit(out, cy, 34, y + rowh + 16)
	L.text(out, "RECORTE", 62, y + rowh + 26, "g3")
	return scaled(out, 4)
