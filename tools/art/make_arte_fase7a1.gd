extends SceneTree
## Fase 7a1 (Diretor de Arte): arena da liga da academia, letreiro FINALIZOU! e peças do HUD da passiva.
## PLACEHOLDER gerado por código. Rodar a partir de uma pasta com um project.godot vazio (não dispara import no projeto):
##   godot --headless --path <pasta_vazia> --script E:/Fightclicker/tools/art/make_arte_fase7a1.gd [-- --assets <pasta>]
## Depois: python tools/art/manifest_7a1.py (registra as peças no manifest sem apagar as dos outros).
##
## Grava:
## - docs/arte/mockups/fase7a1_arena_A.png e _B.png (as 2 opções montadas: em pé com K.O. / deitados com FINALIZOU!)
## - docs/arte/mockups/fase7a1_hud_icones_x4.png (ícones em 4x + HUD montado + letreiros nas duas arenas)
## - assets/sprites/fight/arena_league_bg|crowd_back|crowd_front.png  (opção RECOMENDADA)
## - assets/sprites/ui/ui_banner_submission.png, ui_streak_pip.png, icon_tired.png, icon_grip.png,
##   ui_grip_bar.png, ui_grip_fill.png, ui_grip_tick.png, ui_grip_mark.png
## Contrato da arena (design 7a1 §11): 640x360, y 0..45 lisa e escura (HUD), pés em y 318, chão livre x 250..400 para os
## dois deitados, mesmo nome de camadas da borracharia com o prefixo arena_league_. Sem lâmpada (é de dia).

const ROOT := "E:/Fightclicker/"
var ASSETS := ROOT + "assets/sprites/"
const MOCK := ROOT + "docs/arte/mockups/"
var L
var DEBUG := ""                    # --debug <pasta>: grava as cenas montadas em 2x para conferir
var SCENES := {}
const FLOOR_Y := 240
const VPY := -28.0                 # ponto de fuga (320,-28), o mesmo da borracharia e da sala
const RECOMENDADA := "A"
## Texto da faixa: trocar aqui quando o Roteirista der o nome do lugar e rodar de novo.
const FAIXA := "GINÁSIO ALVORADA"

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--assets" and i + 1 < args.size():
			ASSETS = args[i + 1].trim_suffix("/") + "/"
		if args[i] == "--debug" and i + 1 < args.size():
			DEBUG = args[i + 1].trim_suffix("/") + "/"
	var bgs := {"A": arena_a(), "B": arena_b()}
	var crowd := crowd_back()
	var front := crowd_front()
	var ui := hud_pieces()
	for k in bgs:
		check_contract(bgs[k], k)
		mockup(k, bgs[k], crowd, front, ui).save_png(MOCK + "fase7a1_arena_%s.png" % k)
	icons_board(bgs, crowd, front, ui).save_png(MOCK + "fase7a1_hud_icones_x4.png")
	# assets
	bgs[RECOMENDADA].save_png(ASSETS + "fight/arena_league_bg.png")
	sheet(crowd).save_png(ASSETS + "fight/arena_league_crowd_back.png")
	sheet(front).save_png(ASSETS + "fight/arena_league_crowd_front.png")
	for n in ui:
		sheet(ui[n]).save_png(ASSETS + "ui/%s.png" % n)
	if DEBUG != "":
		for n in SCENES:
			var im: Image = SCENES[n]
			im.resize(im.get_width() * 2, im.get_height() * 2, Image.INTERPOLATE_NEAREST)
			im.save_png(DEBUG + n + ".png")
	print("7a1: arena (opção %s), letreiro e HUD gravados em %s; mockups em %s" % [RECOMENDADA, ASSETS, MOCK])
	quit()

# ------------------------------------------------------------------ utilidades
func sheet(frames: Array) -> Image:
	var f0: Image = frames[0]
	var out: Image = L.blank(f0.get_width() * frames.size(), f0.get_height())
	for i in frames.size():
		out.blit_rect(frames[i], Rect2i(Vector2i.ZERO, f0.get_size()), Vector2i(i * f0.get_width(), 0))
	return out

func px(xb: float, y: float) -> float:
	## x na linha y de uma reta do chão que passa por xb na linha FLOOR_Y e vai para o ponto de fuga
	return 320.0 + (xb - 320.0) * (y - VPY) / (FLOOR_Y - VPY)

func outline_in_place(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

func bayer(x: int, y: int) -> float:
	return (L.BAYER[y % 4][x % 4] + 0.5) / 16.0

## faixa de sol entrando pela janela: paralelogramo que desce inclinado, 1 passo mais claro em dither que some no fim
func sun_shaft(img: Image, x0: int, y0: int, w: int, y1: int, slope: float, strength := 0.5) -> void:
	for y in range(y0, y1):
		var t := float(y - y0) / float(y1 - y0)
		var xs := int(x0 + (y - y0) * slope)
		for x in range(xs, xs + w):
			if x < 0 or x >= 640:
				continue
			if bayer(x, y) < strength * (1.0 - t * 0.7):
				img.set_pixel(x, y, L.shade(img.get_pixel(x, y), 1))

func check_contract(img: Image, k: String) -> void:
	var ink: Color = L.C.ink
	var bad := 0
	for y in 46:
		for x in 640:
			if not img.get_pixel(x, y).is_equal_approx(ink):
				bad += 1
	print("opção %s: faixa do HUD (y 0..45) px fora do ink = %d" % [k, bad])

# ------------------------------------------------------------------ peças comuns de cenário
func blocks_wall(img: Image, x0: int, y0: int, w: int, h: int, base: String, mortar: String) -> void:
	L.R(img, x0, y0, w, h, base)
	for y in range(y0, y0 + h):
		var row := (y - y0) / 8
		if (y - y0) % 8 == 7:
			L.R(img, x0, y, w, 1, mortar)
			continue
		for x in range(x0, x0 + w):
			if (x + (8 if row % 2 else 0)) % 16 == 0:
				L.P(img, x, y, mortar)

func window_basculante(img: Image, x: int, y: int, w: int, h: int) -> void:
	L.R(img, x - 1, y - 1, w + 2, h + 2, "ink")
	L.R(img, x, y, w, h, "st1")
	var cols := maxi(2, w / 17)
	var cw := float(w - 2) / cols
	for c in cols:
		var cx := x + 1 + int(c * cw)
		var cx1 := x + 1 + int((c + 1) * cw) - 1
		var yy := y + 1
		while yy < y + h - 1:
			var hh := mini(6, y + h - 1 - yy)
			# vidro: céu claro em cima, mais azul embaixo
			L.R(img, cx, yy, cx1 - cx, hh, "b3")
			L.R(img, cx, yy, cx1 - cx, 1, "white")
			L.dither(img, cx, yy + hh - 2, cx1 - cx, 2, "b2")
			L.R(img, cx, yy + hh - 1, cx1 - cx, 1, "st2")
			yy += 7
		L.R(img, cx1, y + 1, 1, h - 2, "st2")
	# reflexo em diagonal
	for k in 3:
		L.line(img, x + 6 + k * 22, y + h - 3, x + 12 + k * 22, y + 2, "white")

func sponsor_board(img: Image, x: int, y: int, w: int, h: int, bg: String, fg: String, label: String) -> void:
	L.R(img, x, y, w, h, "ink")
	L.R(img, x + 1, y + 1, w - 2, h - 2, bg)
	L.R(img, x + 1, y + 1, w - 2, 1, L.shade(L.col(bg), 1))
	L.text_center(img, label, x + w / 2, y + (h - 7) / 2 + 1, fg, 1)

func mat(img: Image, top: int, bot: int, xl_b: int, xr_b: int, c_a: String, c_b: String, border: String, puzzle := false) -> void:
	## tatame em perspectiva: borda de baixo xl_b..xr_b em y=bot; os lados vão para o ponto de fuga
	var k_top := (top - VPY) / (bot - VPY)
	var xl_t := 320.0 + (xl_b - 320.0) * k_top
	var xr_t := 320.0 + (xr_b - 320.0) * k_top
	var ncol := 6
	var rows_y := [top, top + int((bot - top) * 0.30), top + int((bot - top) * 0.62), bot]
	for y in range(top, bot + 1):
		var t := float(y - top) / float(bot - top)
		var xl := lerpf(xl_t, float(xl_b), t)
		var xr := lerpf(xr_t, float(xr_b), t)
		var ri := 0
		for i in 3:
			if y >= rows_y[i]:
				ri = i
		for x in range(int(round(xl)), int(round(xr)) + 1):
			var u := (x - xl) / maxf(xr - xl, 1.0)
			var ci := int(u * ncol)
			var c := c_a
			if puzzle:
				c = c_a if (ci + ri) % 2 == 0 else c_b
			# borda colorida (6 px de lado, 4 em cima/embaixo na tela)
			if u * (xr - xl) < 7 or (1.0 - u) * (xr - xl) < 7 or y < top + 4 or y > bot - 4:
				c = border
			L.P(img, x, y, c)
		# emendas das placas (linhas de perspectiva)
		for i in range(1, ncol):
			var xs := int(round(lerpf(xl, xr, float(i) / ncol)))
			if not puzzle and y > top + 4 and y < bot - 4:
				L.P(img, xs, y, L.shade(L.col(c_a), -1))
	if not puzzle:
		for i in range(1, 3):
			var y: int = rows_y[i]
			var t := float(y - top) / float(bot - top)
			var xl := lerpf(xl_t, float(xl_b), t)
			var xr := lerpf(xr_t, float(xr_b), t)
			L.R(img, int(xl) + 7, y, int(xr - xl) - 13, 1, L.shade(L.col(c_a), -1))
	else:
		# dentes do quebra-cabeça na borda de cima e de baixo
		for x in range(int(xl_t) + 2, int(xr_t) - 2):
			if x % 8 < 3:
				L.P(img, x, top - 1, border)
		for x in range(xl_b + 2, xr_b - 2):
			if x % 10 < 4:
				L.P(img, x, bot + 1, border)
	# brilho da borda de cima e espessura da frente
	L.R(img, int(xl_t), top, int(xr_t - xl_t) + 1, 1, L.shade(L.col(border), 1))
	L.R(img, xl_b, bot + 1 + (1 if puzzle else 0), xr_b - xl_b + 1, 3, L.shade(L.col(border), -1))
	L.R(img, xl_b, bot + 4 + (1 if puzzle else 0), xr_b - xl_b + 1, 1, "ink")

func judges_table(img: Image, x: int, y: int) -> void:
	# mesa dos juízes com toalha, sino de luta e prancheta (x..x+84, y..y+28)
	L.R(img, x, y + 6, 84, 3, "ink")
	L.R(img, x + 1, y + 6, 82, 2, "g3")
	L.R(img, x + 2, y + 9, 80, 12, "r1"); L.R(img, x + 2, y + 9, 80, 1, "r2"); L.R(img, x + 2, y + 20, 80, 1, "r0")
	L.text(img, "MESA", x + 30, y + 11, "cream", 1)
	L.R(img, x + 6, y + 21, 2, 8, "st0"); L.R(img, x + 76, y + 21, 2, 8, "st0")
	# sino
	L.R(img, x + 60, y - 2, 12, 8, "ink"); L.ellipse(img, x + 66, y + 2, 5, 4, "y0"); L.P(img, x + 64, y + 1, "y2"); L.R(img, x + 61, y + 5, 10, 1, "br1")
	# prancheta e garrafinha
	L.R(img, x + 12, y + 2, 10, 5, "ink"); L.R(img, x + 13, y + 3, 8, 3, "cream")
	L.R(img, x + 40, y - 3, 4, 9, "ink"); L.R(img, x + 41, y - 2, 2, 7, "b3")

func bench(img: Image, x: int, y: int) -> void:
	# banco do corner com toalha, balde e garrafas (x..x+72, y..y+22)
	L.R(img, x, y + 6, 72, 4, "ink"); L.R(img, x + 1, y + 6, 70, 2, "br3"); L.R(img, x + 1, y + 8, 70, 1, "br1")
	L.R(img, x + 4, y + 10, 3, 12, "br0"); L.R(img, x + 65, y + 10, 3, 12, "br0")
	L.R(img, x + 10, y + 1, 18, 6, "ink"); L.R(img, x + 11, y + 2, 16, 4, "cream"); L.R(img, x + 11, y + 5, 16, 1, "g3")
	for k in 3:
		L.R(img, x + 36 + k * 6, y - 3, 4, 9, "ink"); L.R(img, x + 37 + k * 6, y - 2, 2, 7, ["b3", "gr3", "b3"][k])
	L.R(img, x + 74, y + 8, 12, 14, "ink"); L.R(img, x + 75, y + 9, 10, 12, "b1"); L.R(img, x + 75, y + 9, 10, 2, "b2")

# ------------------------------------------------------------------ OPÇÃO A: quadra coberta do bairro
## Ginásio poliesportivo de bairro, sábado de manhã: treliça do telhado, janelões basculantes com sol, placar,
## faixa da liga, arquibancada de concreto com gente sentada, placas de patrocinador da vizinhança, quadra de
## madeira com as linhas pintadas e o tatame oficial (azul com borda vermelha) no meio.
func arena_a() -> Image:
	var img: Image = L.blank(640, 360)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7101
	L.R(img, 0, 0, 640, 360, "ink")
	# telhado: treliça metálica em contraluz (y 46..71)
	L.R(img, 0, 46, 640, 26, "d1")
	for x in range(-8, 648, 4):
		L.R(img, x, 46, 1, 8, "d2")    # telhas onduladas vistas por baixo
	L.R(img, 0, 54, 640, 1, "st0"); L.R(img, 0, 69, 640, 2, "st0")
	var x := 0
	while x < 640:
		L.line(img, x, 55, x + 10, 68, "st0"); L.line(img, x + 10, 68, x + 20, 55, "st0")
		x += 20
	# refletores da quadra (acesos, de dia ficam brancos)
	for lx in [96, 236, 404, 544]:
		L.R(img, lx - 1, 60, 2, 10, "ink")
		L.R(img, lx - 7, 70, 14, 4, "ink"); L.R(img, lx - 6, 70, 12, 2, "st1"); L.R(img, lx - 6, 72, 12, 1, "y2")
	# parede de bloco
	blocks_wall(img, 0, 72, 640, FLOOR_Y - 72, "g1", "g0")
	# janelões basculantes (luz do dia) dos dois lados; o meio fica para o placar (atrás do letreiro de K.O.)
	for wx in [10, 86, 162]:
		window_basculante(img, wx, 78, 68, 34)
	for wx in [410, 486, 562]:
		window_basculante(img, wx, 78, 68, 34)
	# placar
	L.R(img, 268, 74, 104, 40, "ink"); L.R(img, 270, 76, 100, 36, "d1"); L.R(img, 270, 76, 100, 1, "d2")
	L.text_center(img, "LIGA", 320, 79, "y1", 1)
	L.R(img, 278, 89, 32, 18, "ink"); L.R(img, 330, 89, 32, 18, "ink")
	L.text_center(img, "SÁB", 294, 94, "r2", 1)
	L.text_center(img, "10:30", 346, 94, "r2", 1)
	L.R(img, 266, 114, 2, 6, "st0"); L.R(img, 372, 114, 2, 6, "st0")
	# arquibancada de concreto (5 degraus) com corrimão
	var steps := 5
	var sy0 := 148
	var sh := 17
	L.R(img, 0, sy0 - 8, 640, 1, "st2"); L.R(img, 0, sy0 - 7, 640, 1, "st0")
	for px0 in range(8, 640, 40):
		L.R(img, px0, sy0 - 7, 1, 7, "st0")
	for s in steps:
		var y := sy0 + s * sh
		L.R(img, 0, y, 640, 4, "g2"); L.R(img, 0, y, 640, 1, "g3")
		L.R(img, 0, y + 4, 640, sh - 4, "g1"); L.R(img, 0, y + 4, 640, 1, "g0")
		L.dither(img, 0, y + sh - 4, 640, 4, "g0")
	# gente sentada na arquibancada (pequena, longe); menos gente no meio, onde passa o letreiro
	for s in 4:
		var y := sy0 + s * sh + 3
		var xx := rng.randi_range(2, 10)
		while xx < 636:
			var mid := absf(xx - 320.0) < 70.0
			if rng.randf() < (0.35 if mid else 0.72):
				seated(img, xx, y, rng)
			xx += rng.randi_range(9, 14)
	# faixa da liga (pano com ilhós e corda), presa no corrimão: na frente da arquibancada
	var fw: int = L.text_w(FAIXA, 1) * 2 + 24
	var fx := 320 - fw / 2
	L.line(img, fx - 12, 118, fx, 124, "d2"); L.line(img, fx + fw + 12, 118, fx + fw, 124, "d2")
	# 24 px de altura: o acento do Á (2 linhas acima da letra) não encosta na barra vermelha de cima
	L.R(img, fx, 122, fw, 24, "ink"); L.R(img, fx + 1, 123, fw - 2, 22, "cream"); L.R(img, fx + 1, 143, fw - 2, 1, "g3")
	L.R(img, fx + 1, 123, fw - 2, 2, "r1")
	L.text_center(img, FAIXA, 320, 130, "r1", 2)
	for k in [fx + 3, fx + fw - 4]:
		L.P(img, k, 126, "st1")
	# mureta da quadra com placas de patrocinador da vizinhança (atrás do público em pé)
	var my := 226
	L.R(img, 0, my, 640, FLOOR_Y - my, "st1"); L.R(img, 0, my, 640, 1, "st3")
	var boards := [["y1", "br0", "DISK GÁS"], ["b1", "white", "AUTO PEÇAS ZÉ"], ["cream", "r1", "PADARIA ÁGUIA"],
		["gr1", "y2", "BOA ESQUINA"], ["r1", "white", "AÇOUGUE 2 IRMÃOS"], ["st0", "y1", "CHAVEIRO 24H"]]
	var bx := 2
	var bi := 0
	while bx < 640:
		var b: Array = boards[bi % boards.size()]
		var bw: int = L.text_w(b[2], 1) + 14
		sponsor_board(img, bx, my + 1, bw, 12, b[0], b[1], b[2])
		bx += bw + 3
		bi += 1
	L.R(img, 0, FLOOR_Y - 1, 640, 1, "ink")
	# quadra de madeira
	L.R(img, 0, FLOOR_Y, 640, 120, "br2")
	for i in range(-40, 41):
		var xb := 320 + i * 14
		for y in range(FLOOR_Y, 360):
			var xx := int(round(px(xb, y)))
			if (y / 3 + i) % 9 != 0:
				L.P(img, xx, y, "br1")
	for i in 260:
		var y := rng.randi_range(FLOOR_Y + 1, 359)
		var xx := rng.randi_range(0, 639)
		L.R(img, xx, y, 1, 1, "br1")
	# linhas pintadas da quadra (de outros esportes)
	L.R(img, 0, 250, 640, 1, "cream")
	L.ellipse(img, 320, 304, 120, 30, "cream"); L.ellipse(img, 320, 304, 119, 29, "br2")
	L.line(img, 0, 300, 70, 251, "y1"); L.line(img, 640, 300, 570, 251, "y1")
	L.line(img, 0, 330, 34, 251, "b2"); L.line(img, 640, 330, 606, 251, "b2")
	# tatame oficial: azul, borda vermelha
	mat(img, 272, 350, 112, 528, "b1", "b1", "r1")
	# mesa dos juízes e banco do corner (na frente do público, longe do centro)
	judges_table(img, 8, 272)
	bench(img, 548, 276)
	# luz: dia claro no meio, cantos e telhado mais escuros
	L.light(img, Rect2i(0, 46, 640, 314), Vector2(320, 250), 330.0, 1.3, 2.4, -2, 1, 1.15)
	# sol entrando pelos janelões da esquerda
	for k in 3:
		sun_shaft(img, 14 + k * 76, 112, 52, 236, 1.05, 0.45)
	return img

func seated(img: Image, x: int, y: int, rng: RandomNumberGenerator) -> void:
	var shirts := ["r1", "b1", "gr1", "br2", "st1", "p1", "g1", "r2", "b2", "y0", "cream"]
	var skins := ["sk0", "sk1", "sk2"]
	var sc: String = shirts[rng.randi_range(0, shirts.size() - 1)]
	var sk: String = skins[rng.randi_range(0, 2)]
	var top := y - 10
	L.R(img, x - 3, top + 5, 7, 7, sc)                 # tronco com ombros
	L.P(img, x - 3, top + 5, L.shade(L.col(sc), -1)); L.P(img, x + 3, top + 5, L.shade(L.col(sc), -1))
	L.R(img, x - 3, top + 6, 1, 6, L.shade(L.col(sc), 1))
	L.R(img, x - 1, top, 3, 5, sk)                      # cabeça
	L.P(img, x - 2, top + 1, sk); L.P(img, x + 2, top + 1, sk); L.P(img, x - 2, top + 2, sk); L.P(img, x + 2, top + 2, sk)
	var hair: String = ["ink", "d1", "br0", "br1", "g3"][rng.randi_range(0, 4)]
	L.R(img, x - 1, top - 1, 3, 2, hair); L.P(img, x - 2, top, hair); L.P(img, x + 2, top, hair)
	L.R(img, x - 3, top + 12, 7, 2, "d2")               # joelhos no degrau

# ------------------------------------------------------------------ OPÇÃO B: salão do clube do bairro
## Salão de festas do clube da vizinhança, sábado à tarde: forro de lambri, bandeirinhas, ventiladores de teto,
## palco com cortina vinho e a mesa dos troféus, janelas com grade e sol, cadeiras de plástico empilhadas,
## chão de taco e tatame de EVA (azul e verde) emprestado da academia.
func arena_b() -> Image:
	var img: Image = L.blank(640, 360)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7102
	L.R(img, 0, 0, 640, 360, "ink")
	# forro de lambri
	L.R(img, 0, 46, 640, 16, "br1")
	for x in range(0, 640, 5):
		L.R(img, x, 46, 1, 16, "br0")
	L.R(img, 0, 62, 640, 2, "br2"); L.R(img, 0, 64, 640, 1, "ink")
	# parede: bege em cima, barrado azul embaixo
	L.R(img, 0, 65, 640, FLOOR_Y - 65, "g3")
	for i in 500:
		L.P(img, rng.randi_range(0, 639), rng.randi_range(66, 180), "g2")
	L.R(img, 0, 182, 640, FLOOR_Y - 182, "b1"); L.R(img, 0, 182, 640, 2, "b2"); L.R(img, 0, 184, 640, 1, "b0")
	# janelas com grade e sol
	for wx in [22, 488]:
		L.R(img, wx - 2, 88, 134, 74, "ink"); L.R(img, wx, 90, 130, 70, "cream")
		L.R(img, wx + 3, 93, 124, 64, "b3"); L.dither(img, wx + 3, 140, 124, 17, "b2")
		L.R(img, wx + 3, 93, 124, 1, "white")
		# grade de ferro com losangos
		for gx in range(wx + 3, wx + 127, 12):
			L.R(img, gx, 93, 1, 64, "d1")
		for gy in [108, 125, 142]:
			L.R(img, wx + 3, gy, 124, 1, "d1")
		for gx in range(wx + 9, wx + 127, 12):
			for gy in [116, 133]:
				L.P(img, gx, gy - 1, "d1"); L.P(img, gx - 1, gy, "d1"); L.P(img, gx + 1, gy, "d1"); L.P(img, gx, gy + 1, "d1")
		L.R(img, wx - 4, 162, 138, 3, "g2"); L.R(img, wx - 4, 162, 138, 1, "white")
	# palco com cortina vinho
	var sx0 := 172
	var sx1 := 468
	L.R(img, sx0 - 6, 84, sx1 - sx0 + 12, FLOOR_Y - 84, "ink")
	L.R(img, sx0 - 5, 85, sx1 - sx0 + 10, 10, "br2"); L.R(img, sx0 - 5, 85, sx1 - sx0 + 10, 1, "br3")
	L.R(img, sx0 - 5, 95, 6, 112, "br2"); L.R(img, sx1 - 1, 95, 6, 112, "br2")
	for x in range(sx0 + 1, sx1 - 1):
		var ph := (x - sx0) % 12
		var c := "r1"
		if ph < 2:
			c = "r0"
		elif ph == 5 or ph == 6:
			c = "r2"
		L.R(img, x, 95, 1, 112, c)
	# bandô com franja
	L.R(img, sx0 + 1, 95, sx1 - sx0 - 2, 12, "r1"); L.R(img, sx0 + 1, 95, sx1 - sx0 - 2, 1, "r2")
	for x in range(sx0 + 1, sx1 - 1):
		L.P(img, x, 107, "y0" if x % 2 == 0 else "br2")
		if x % 4 == 0:
			L.P(img, x, 108, "y0")
	# faixa da liga presa no bandô
	var fw: int = L.text_w(FAIXA, 1) * 2 + 24
	var fx := 320 - fw / 2
	L.R(img, fx, 114, fw, 22, "ink"); L.R(img, fx + 1, 115, fw - 2, 20, "cream"); L.R(img, fx + 1, 133, fw - 2, 1, "g3")
	L.R(img, fx + 1, 115, fw - 2, 2, "b1")
	L.text_center(img, FAIXA, 320, 121, "b1", 2)
	# mesa dos troféus no palco
	L.R(img, 266, 186, 108, 4, "ink"); L.R(img, 267, 186, 106, 2, "cream"); L.R(img, 268, 190, 104, 17, "cream"); L.R(img, 268, 205, 104, 2, "g3")
	for t in [[284, 6], [304, 9], [320, 12], [336, 9], [356, 6]]:
		var tx: int = t[0]
		var th: int = t[1]
		L.R(img, tx - 4, 185 - 3, 9, 3, "ink"); L.R(img, tx - 3, 184, 7, 1, "br1")
		L.R(img, tx - 1, 182 - th + 4, 3, th - 4, "y0")
		L.ellipse(img, tx, 182 - th + 2, 4, 3.5, "y0"); L.P(img, tx - 2, 182 - th + 1, "y2")
	# frente do palco (madeira)
	L.R(img, sx0 - 5, 207, sx1 - sx0 + 10, FLOOR_Y - 207, "br2"); L.R(img, sx0 - 5, 207, sx1 - sx0 + 10, 2, "br3")
	for y in range(212, FLOOR_Y, 6):
		L.R(img, sx0 - 5, y, sx1 - sx0 + 10, 1, "br1")
	# bandeirinhas (3 varais)
	for v in 3:
		var yb := 70 + v * 6
		var sag := 10 + v * 2
		var x := 0
		var ci := v
		while x < 640:
			var t := fposmod(x, 213.0) / 213.0
			var y := int(yb + sin(t * PI) * sag)
			L.P(img, x, y, "d2")
			if x % 9 == 0:
				var fc: String = ["r2", "y1", "b2", "gr2", "cream", "p1"][ci % 6]
				ci += 1
				for k in 5:
					L.R(img, x - 2 + k / 2, y + 1 + k, 5 - k, 1, fc)
			x += 1
	# ventiladores de teto
	for vx in [120, 520]:
		L.R(img, vx, 46, 1, 18, "ink")
		L.ellipse(img, vx + 0.5, 66, 4, 3, "st1")
		L.ellipse_dither(img, vx + 0.5, 67, 26, 2.5, "st0")
		L.R(img, vx - 3, 68, 7, 1, "st0")
	# cadeiras de plástico brancas empilhadas (esquerda) e mesas encostadas (direita)
	L.R(img, 38, 176, 30, 64, "ink")
	L.R(img, 40, 178, 26, 22, "white"); L.R(img, 43, 181, 20, 3, "g3"); L.R(img, 43, 187, 20, 3, "g3")   # encosto com vãos
	for k in 8:
		var cy := 200 + k * 4
		L.R(img, 39, cy, 28, 3, "white"); L.R(img, 39, cy + 2, 28, 1, "g2")
	L.R(img, 40, 232, 3, 8, "g3"); L.R(img, 63, 232, 3, 8, "g3"); L.R(img, 43, 232, 20, 8, "ink")
	for k in 3:
		L.R(img, 548 + k * 7, 188, 5, 52, "ink"); L.R(img, 549 + k * 7, 189, 3, 50, "white"); L.R(img, 551 + k * 7, 189, 1, 50, "g3")
	L.R(img, 0, FLOOR_Y - 1, 640, 1, "ink")
	# chão de taco (parquet em cesto: quadrados alternando ripas em pé e deitadas)
	L.R(img, 0, FLOOR_Y, 640, 120, "br2")
	var y := FLOOR_Y
	var row := 0
	while y < 360:
		var cs := 10 + int((y - FLOOR_Y) / 14)
		var chh := 5 + int((y - FLOOR_Y) / 22)
		var xx := -((row * cs) / 2) % cs
		var col_i := 0
		while xx < 640:
			var vert := (col_i + row) % 2 == 0
			for yy in range(y, mini(y + chh, 360)):
				for x2 in range(maxi(xx, 0), mini(xx + cs, 640)):
					var c := "br2"
					if vert and (x2 - xx) % 3 == 2:
						c = "br1"
					elif not vert and (yy - y) % 2 == 1 and chh > 3:
						c = "br1" if (yy - y) < chh - 1 else "br2"
					if x2 == xx or yy == y:
						c = "br0"
					L.P(img, x2, yy, c)
			xx += cs
			col_i += 1
		y += chh
		row += 1
	# tatame de EVA (azul e verde, borda amarela)
	mat(img, 272, 350, 112, 528, "b1", "gr1", "y0", true)
	judges_table(img, 8, 272)
	# caixa de som no chão (direita)
	L.R(img, 566, 262, 34, 38, "ink"); L.R(img, 567, 263, 32, 36, "d1")
	L.ellipse(img, 583, 288, 9, 9, "ink"); L.ellipse(img, 583, 288, 7, 7, "d2"); L.ellipse(img, 583, 288, 3, 3, "ink")
	L.ellipse(img, 583, 271, 4, 4, "ink"); L.ellipse(img, 583, 271, 2, 2, "d2")
	L.R(img, 567, 263, 32, 1, "g0")
	L.light(img, Rect2i(0, 46, 640, 314), Vector2(320, 250), 330.0, 1.3, 2.4, -2, 1, 1.15)
	for k in 2:
		sun_shaft(img, 30 + k * 64, 162, 40, 300, 0.9, 0.4)
	return img

# ------------------------------------------------------------------ público (de dia, com cor)
func person_day(img: Image, x: int, fy: int, h: int, w: int, arms: int, shirt: String, skin: String, hair: String, extra: String) -> void:
	var hy := fy - h
	var pants := "d2" if (x / 7) % 3 else "b0"
	L.R(img, x - w / 2 + 1, fy - 9, w - 2, 9, pants)
	L.R(img, x, fy - 7, 1, 7, "ink")
	L.rrect(img, x - w / 2, hy + 8, w, h - 16, shirt)
	L.R(img, x - w / 2, hy + 9, 1, h - 18, L.shade(L.col(shirt), 1))   # luz da janela vem da esquerda
	L.R(img, x + w / 2 - 1, hy + 9, 1, h - 18, L.shade(L.col(shirt), -1))
	L.ellipse(img, x, hy + 4, 3.5, 4.5, skin)
	L.R(img, x - 3, hy, 7, 2, hair)
	L.P(img, x - 3, hy + 2, hair)
	if extra == "cap":
		L.R(img, x - 4, hy - 1, 8, 2, shirt); L.R(img, x + 2, hy + 1, 4, 1, shirt)
	if arms >= 1:
		L.R(img, x + w / 2 - 2, hy - 5, 3, 14, shirt); L.R(img, x + w / 2 - 2, hy - 8, 3, 3, skin)
		if extra == "flag":
			L.R(img, x + w / 2 - 1, hy - 20, 1, 13, "br1")
			L.R(img, x + w / 2, hy - 20, 9, 6, "b2"); L.R(img, x + w / 2, hy - 17, 9, 1, "white")
		if extra == "phone":
			L.R(img, x + w / 2 - 2, hy - 12, 3, 4, "ink"); L.P(img, x + w / 2 - 1, hy - 11, "b3")
	if arms >= 2:
		L.R(img, x - w / 2 - 1, hy - 5, 3, 14, shirt); L.R(img, x - w / 2 - 1, hy - 8, 3, 3, skin)

func crowd_back() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7177
	var shirts := ["r1", "b1", "gr1", "br2", "st1", "p1", "g1", "r2", "b2", "y0", "cream", "st2"]
	var skins := ["sk0", "sk1", "sk2"]
	var hairs := ["ink", "d1", "br0", "br1", "g2"]
	var specs := []
	var x := 12
	while x < 632:
		var kid := rng.randf() < 0.15
		specs.append({"x": x, "dy": rng.randi_range(-2, 2), "h": rng.randi_range(22, 26) if kid else rng.randi_range(31, 38),
			"w": rng.randi_range(11, 13) if kid else rng.randi_range(14, 17), "shirt": shirts[rng.randi_range(0, shirts.size() - 1)],
			"skin": skins[rng.randi_range(0, 2)], "hair": hairs[rng.randi_range(0, hairs.size() - 1)], "r": rng.randf(), "s": rng.randi()})
		x += rng.randi_range(15, 22)
	var frames := []
	for f in 2:
		var im: Image = L.blank(640, 100)
		# de trás para a frente: os mais altos primeiro, para as crianças ficarem na frente
		var order := specs.duplicate()
		order.sort_custom(func(a, b): return a.h > b.h)
		for s in order:
			var r: float = s.r
			var arms := 0
			if f == 1:
				arms = 2 if r < 0.35 else (1 if r < 0.75 else 0)
			elif r < 0.10:
				arms = 1
			var ex := ""
			match int(s.s) % 9:
				0, 4: ex = "flag"
				2: ex = "phone"
				6: ex = "cap"
			if ex == "flag" or ex == "phone":
				arms = maxi(arms, 1)
			var bob := 1 if (f == 1 and int(s.s) % 2 == 0) else 0
			person_day(im, s.x, 88 + s.dy - bob, s.h, s.w, arms, s.shirt, s.skin, s.hair, ex)
		frames.append(im)
	return frames

func crowd_front() -> Array:
	# na frente da câmera, fora de foco: silhuetas escuras com um toque de cor (bandeira, boné); só nos cantos
	var frames := []
	var fx := [10, 46, 84, 120, 520, 556, 596, 632]
	for f in 2:
		var im: Image = L.blank(640, 48)
		for i in fx.size():
			var bob := 1 if (f == 1 and i % 2 == 0) else 0
			var arms := 1 if (f == 1 and i % 3 == 0) else 0
			L.ellipse(im, fx[i], 20 - bob, 9, 10, "ink")
			L.rrect(im, fx[i] - 17, 30 - bob, 34, 20, "ink")
			L.R(im, fx[i] - 4, 10 - bob, 9, 1, "d2"); L.R(im, fx[i] - 15, 30 - bob, 30, 1, "d2")
			if i == 2 or i == 5:
				L.R(im, fx[i] - 9, 10 - bob, 18, 3, "r0"); L.R(im, fx[i] + 5, 12 - bob, 7, 1, "r0")   # boné
			if arms == 1:
				L.R(im, fx[i] + 10, 4 - bob, 6, 30, "ink"); L.R(im, fx[i] + 9, 0, 8, 6, "ink")
			if f == 1 and i == 6:
				L.R(im, fx[i] - 14, 0, 2, 30, "d1"); L.R(im, fx[i] - 12, 0, 14, 9, "b0"); L.R(im, fx[i] - 12, 4, 14, 1, "d2")
		frames.append(im)
	return frames

# ------------------------------------------------------------------ HUD da passiva e letreiro
func hud_pieces() -> Dictionary:
	var d := {}
	# letreiro FINALIZOU! (mesma receita do K.O.!: amarelo com contorno ink e sombra de 1 px de fonte; sombra azul do Jiu-jitsu)
	var s := "FINALIZOU!"
	var sc := 3
	var kw: int = L.text_w(s, sc) + 8
	var im: Image = L.blank(kw, 40)
	L.text(im, s, 4, 8 + sc, "b1", sc)
	L.text(im, s, 4, 8, "y1", sc)
	var out := outline_in_place(im)
	for y in range(8, 34):
		for x in kw:
			if out.get_pixel(x, y).is_equal_approx(L.C.y1) and y >= 8 + 3 * sc:
				out.set_pixel(x, y, L.C.y0)
	d["ui_banner_submission"] = [out]
	# bolinha do embalo 7x7: 0 apagada, 1 acesa (vermelho do Boxe), 2 acendendo (clarão de 1 quadro)
	var pips := []
	for f in 3:
		var p: Image = L.blank(7, 7)
		L.ellipse(p, 3.5, 3.5, 3.5, 3.5, "ink")
		var fill: Array = [["d2", "d1", "g0"], ["r2", "r1", "r3"], ["y2", "y1", "white"]][f]
		L.ellipse(p, 3.5, 3.5, 2.5, 2.5, fill[0])
		L.R(p, 2, 4, 3, 1, fill[1]); L.P(p, 3, 5, fill[1])
		L.P(p, 2, 2, fill[2])
		pips.append(p)
	d["ui_streak_pip"] = pips
	# CANSADO: gota de suor 9x9
	var t: Image = L.blank(7, 7)
	L.P(t, 3, 0, "b3"); L.R(t, 2, 1, 3, 1, "b3"); L.R(t, 1, 2, 5, 1, "b3"); L.R(t, 1, 3, 5, 2, "b2"); L.R(t, 2, 5, 3, 1, "b1"); L.R(t, 1, 4, 1, 1, "b1")
	L.P(t, 2, 2, "white"); L.P(t, 2, 3, "white")
	d["icon_tired"] = [L.outlined(t)]
	# pegada: mão fechando na gola do quimono 9x9
	var g: Image = L.blank(7, 7)
	L.line(g, 0, 0, 3, 6, "cream"); L.line(g, 1, 0, 4, 6, "cream"); L.line(g, 6, 0, 3, 6, "g3"); L.line(g, 5, 0, 4, 2, "g3")
	L.R(g, 2, 2, 4, 3, "sk1"); L.R(g, 2, 2, 4, 1, "sk2"); L.P(g, 5, 4, "sk0"); L.P(g, 3, 3, "sk0")
	d["icon_grip"] = [L.outlined(g)]
	# barra fina da pegada (azul do Jiu-jitsu): moldura 9-slice 8x6, enchimento 4x4 em 2 quadros, marca de round e marca de "enche aqui"
	var bar: Image = L.blank(8, 6)
	L.R(bar, 0, 0, 8, 6, "ink"); L.R(bar, 1, 1, 6, 4, "d2"); L.R(bar, 1, 1, 6, 1, "d1")
	d["ui_grip_bar"] = [bar]
	var fills := []
	for f in 2:
		var fl: Image = L.blank(4, 4)
		var rows: Array = [["b3", "b2", "b2", "b1"], ["white", "b3", "b3", "b2"]][f]
		for y in 4:
			L.R(fl, 0, y, 4, 1, rows[y])
		fills.append(fl)
	d["ui_grip_fill"] = fills
	var tick: Image = L.blank(1, 4)
	L.R(tick, 0, 0, 1, 4, "g2")
	d["ui_grip_tick"] = [tick]
	var mk: Image = L.blank(5, 3)
	L.R(mk, 0, 0, 5, 1, "y1"); L.R(mk, 1, 1, 3, 1, "y1"); L.P(mk, 2, 2, "y0")
	d["ui_grip_mark"] = [L.outlined(mk)]
	return d

# ------------------------------------------------------------------ mockups
func load_png(p: String) -> Image:
	var im := Image.load_from_file(p)
	im.convert(Image.FORMAT_RGBA8)
	return im

func frame_of(p: String, i: int, w := 112, h := 104) -> Image:
	return load_png(p).get_region(Rect2i(i * w, 0, w, h))

func put_fighter(img: Image, fr: Image, pivot: Vector2i, flip: bool) -> void:
	var f := fr
	if flip:
		f = fr.duplicate()
		f.flip_x()
	img.blend_rect(f, Rect2i(Vector2i.ZERO, f.get_size()), pivot - Vector2i(56, 98))

func put_center(img: Image, src: Image, c: Vector2i, scale := 1) -> void:
	var s := src
	if scale != 1:
		s = src.duplicate()
		s.resize(src.get_width() * scale, src.get_height() * scale, Image.INTERPOLATE_NEAREST)
	img.blend_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), c - s.get_size() / 2)

func hud(img: Image, ui: Dictionary, mode: String) -> void:
	# HUD aproximado (o de verdade é do UI/UX): retratos, nomes, vidas, relógio; embalo (Boxe) ou pegada (JJ)
	L.panel(img, 6, 6, 34, 34, "b0"); L.panel(img, 600, 6, 34, 34, "r0")
	L.text(img, "VOCÊ", 46, 6, "cream", 1)
	L.text_right(img, "TONHÃO DO TATAME", 594, 6, "cream", 1)
	L.bar(img, 46, 16, 236, 12, 0.72 if mode == "box" else 0.48, "gr2")
	L.bar(img, 358, 16, 236, 12, 0.41, "r2")
	L.panel(img, 292, 4, 56, 32, "d1")
	L.text_center(img, "2º", 320, 9, "g2", 1)
	L.text_center(img, "31", 320, 19, "y1", 2)
	var spr = load_png(ROOT + "assets/sprites/fight/portrait_player.png")
	img.blend_rect(spr, Rect2i(0, 0, 32, 32), Vector2i(7, 7))
	if mode == "box":
		L.text(img, "AGRESSIVO", 46, 33, "r3", 1)
		for i in 5:
			var fr: Image = ui["ui_streak_pip"][1 if i < 4 else 2]
			img.blend_rect(fr, Rect2i(0, 0, 7, 7), Vector2i(108 + i * 9, 33))
	else:
		# barra da pegada logo abaixo da vida (x 46..281, y 29..34), com as marcas dos rounds
		var bw := 236
		var bar: Image = ui["ui_grip_bar"][0]
		L.R(img, 46, 29, bw, 6, "ink"); L.R(img, 47, 30, bw - 2, 4, "d2"); L.R(img, 47, 30, bw - 2, 1, "d1")
		var fill: Image = ui["ui_grip_fill"][1]
		for xx in range(47, 47 + bw - 2, 4):
			img.blend_rect(fill, Rect2i(0, 0, mini(4, 47 + bw - 2 - xx), 4), Vector2i(xx, 30))
		for k in [1, 2]:
			L.R(img, 47 + (bw - 2) * k / 3, 30, 1, 4, "g2")
		img.blend_rect(ui["icon_grip"][0], Rect2i(0, 0, 9, 9), Vector2i(286, 27))
		L.text(img, "PEGADA!", 46, 37, "b3", 1)

func mockup(k: String, bg: Image, crowd: Array, front: Array, ui: Dictionary) -> Image:
	var titles := {"A": "OPÇÃO A (RECOMENDADA) - QUADRA COBERTA DO BAIRRO, SÁBADO DE MANHÃ",
		"B": "OPÇÃO B - SALÃO DO CLUBE DO BAIRRO, SÁBADO À TARDE"}
	var board: Image = L.blank(1296, 400)
	L.R(board, 0, 0, 1296, 400, "d1")
	L.text(board, titles[k], 8, 6, "y1", 1)
	L.text(board, "EM PÉ: BOXE, EMBALO NO HUD, LETREIRO K.O.!", 8, 20, "g3", 1)
	L.text(board, "NO CHÃO: JIU-JITSU, PEGADA CHEIA, FINALIZOU! (OS DOIS DEITADOS: POSES DO ARTISTA DE PERSONAGENS ENTRAM DEPOIS)", 656, 20, "g3", 1)
	var shadow := load_png(ROOT + "assets/sprites/fight/fight_shadow.png")
	var opp := ROOT + "assets/sprites/opponents/opp_gym_1/opp_gym_1_"
	var ply := ROOT + "assets/sprites/fight/fight_player_"
	for panel in 2:
		var sc: Image = bg.duplicate()
		sc.blend_rect(crowd[panel], Rect2i(0, 0, 640, 100), Vector2i(0, 180))
		if panel == 0:
			for p in [Vector2i(296, 318), Vector2i(346, 318)]:
				sc.blend_rect(shadow, Rect2i(0, 0, 48, 8), p - Vector2i(24, 3))
			put_fighter(sc, frame_of(ply + "idle.png", 0), Vector2i(296, 318), false)
			put_fighter(sc, frame_of(opp + "ko.png", 4), Vector2i(346, 318), true)
			sc.blend_rect(front[1], Rect2i(0, 0, 640, 48), Vector2i(0, 312))
			hud(sc, ui, "box")
			put_center(sc, load_png(ROOT + "assets/sprites/ui/ui_banner_ko.png"), Vector2i(320, 118), 2)
		else:
			for p in [Vector2i(284, 318), Vector2i(358, 318)]:
				sc.blend_rect(shadow, Rect2i(0, 0, 48, 8), p - Vector2i(24, 3))
			put_fighter(sc, frame_of(ply + "ko.png", 4), Vector2i(300, 318), true)
			put_fighter(sc, frame_of(opp + "ko.png", 4), Vector2i(342, 318), false)
			sc.blend_rect(front[0], Rect2i(0, 0, 640, 48), Vector2i(0, 312))
			hud(sc, ui, "bjj")
			put_center(sc, ui["ui_banner_submission"][0], Vector2i(320, 118), 2)
		board.blit_rect(sc, Rect2i(0, 0, 640, 360), Vector2i(8 + panel * 648, 34))
		SCENES["%s_%d" % [k, panel]] = sc
	return board

func icons_board(bgs: Dictionary, crowd: Array, front: Array, ui: Dictionary) -> Image:
	var board: Image = L.blank(1296, 560)
	L.R(board, 0, 0, 1296, 560, "d1")
	L.text(board, "FASE 7A1 - PEÇAS DO HUD DA PASSIVA (4X) E LETREIROS EM 2X (COMO NO JOGO) NAS TRÊS ARENAS", 8, 6, "y1", 1)
	var x := 12
	var items := [["ui_streak_pip", "EMBALO 7X7 (APAGADA / ACESA / ACENDENDO)"], ["icon_tired", "CANSADO 9X9"],
		["icon_grip", "PEGADA 9X9"], ["ui_grip_bar", "MOLDURA 8X6 (9-SLICE 1)"], ["ui_grip_fill", "ENCHE 4X4 (ENCHENDO / CHEIA)"],
		["ui_grip_tick", "ROUND 1X4"], ["ui_grip_mark", "ENCHE AQUI 7X5"]]
	for it in items:
		var fr: Array = ui[it[0]]
		var sh: Image = sheet(fr)
		var big: Image = sh.duplicate()
		big.resize(sh.get_width() * 4 + (fr.size() - 1) * 0, sh.get_height() * 4, Image.INTERPOLATE_NEAREST)
		L.R(board, x - 2, 28, big.get_width() + 4, big.get_height() + 4, "d2")
		board.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(x, 30))
		L.text(board, it[0].to_upper(), x, 72, "cream", 1)
		var lw: int = L.text_w(it[0].to_upper(), 1)
		var lines: PackedStringArray = it[1].split(" (")
		L.text(board, lines[0], x, 82, "g3", 1)
		if lines.size() > 1:
			L.text(board, "(" + lines[1], x, 92, "g3", 1)
		x += maxi(big.get_width(), maxi(lw, L.text_w(it[1], 1) / 2)) + 30
	# HUD montado em 2x (só a faixa de cima): Boxe e Jiu-jitsu
	var y := 112
	for mode in ["box", "bjj"]:
		var sc: Image = bgs[RECOMENDADA].duplicate()
		hud(sc, ui, mode)
		var band := sc.get_region(Rect2i(0, 0, 320, 48))
		band.resize(640, 96, Image.INTERPOLATE_NEAREST)
		board.blit_rect(band, Rect2i(0, 0, 640, 96), Vector2i(8 + (0 if mode == "box" else 648), y))
	L.text(board, "HUD EM 2X (SÓ A METADE DO JOGADOR). POSIÇÃO DAS BOLINHAS E DA BARRA: DECISÃO DO UI/UX.", 8, 212, "g3", 1)
	# letreiros nas duas arenas (borracharia e liga), recorte do meio
	var arenas := [["BORRACHARIA (AMADORES)", load_png(ROOT + "assets/sprites/fight/arena_bg.png")], ["LIGA - OPÇÃO A", bgs["A"]], ["LIGA - OPÇÃO B", bgs["B"]]]
	var ko := load_png(ROOT + "assets/sprites/ui/ui_banner_ko.png")
	for i in arenas.size():
		for j in 2:
			var sc: Image = (arenas[i][1] as Image).duplicate()
			put_center(sc, ko if j == 0 else ui["ui_banner_submission"][0], Vector2i(320, 118), 2)
			var crop := sc.get_region(Rect2i(110, 62, 420, 112))
			board.blit_rect(crop, Rect2i(0, 0, 420, 112), Vector2i(8 + i * 428, 232 + j * 132))
		L.text(board, arenas[i][0], 8 + i * 428, 500, "cream", 1)
	return board
