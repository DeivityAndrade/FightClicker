extends SceneTree
## Fase 6d3 (Diretor de Arte): peças refeitas na varredura de arte. PLACEHOLDER gerado por código.
## Rodar a partir de uma pasta com um project.godot vazio (não dispara import no projeto):
##   godot --headless --path <pasta_vazia> --script E:/Fightclicker/tools/art/make_arte_fase6d3.gd [-- --assets <pasta>]
## Grava em assets/sprites (ou em --assets, para testar). Tamanhos, pivôs e pontos não mudam: trocar a arte é trocar o arquivo.
##
## - (até o símbolo aprovado; hoje é o make_arte_fase6d3_simbolo.gd) garage/wall_school_symbol.png (32x40, em 344,38): o símbolo da escola pintado na parede. Antes era o school_symbol_16
##   ampliado 2x em amarelo vivo com raízes marrons: lia como um borrão aceso no alto da parede. Agora é um emblema pintado a
##   estêncil, de uma cor só da escola (azul b1/b2, a mesma tinta de carimbo do school_symbol_*), com a lâmpada em creme dentro
##   do disco e as raízes descendo para fora, 2 escorridos. A tinta afunda no rejunte e falha em alguns pontos.

const ROOT := "E:/Fightclicker/"
var ASSETS := ROOT + "assets/sprites/"
var L
const LIGHT_C := Vector2(305, 90)
const FLOOR_Y := 240                 # da arena (Fase 3)
const LAMP_POS := Vector2i(321, 52)
const P_SYMBOL := Vector2i(344, 38)

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--assets" and i + 1 < args.size():
			ASSETS = args[i + 1].trim_suffix("/") + "/"
	var bg := Image.load_from_file(ROOT + "assets/sprites/garage/garage_bg.png")
	bg.convert(Image.FORMAT_RGBA8)
	# o wall_school_symbol saiu daqui: desde o símbolo aprovado (R de raiz) quem grava é make_arte_fase6d3_simbolo.gd
	# arena: confere que a cópia é fiel (sem correção = arquivo de antes) e grava a corrigida
	var orig := Image.load_from_file(ROOT + "tools/art/fonte_6d3/arena_bg.png")
	orig.convert(Image.FORMAT_RGBA8)
	var same := arena(false)
	var diff := 0
	for y in 360:
		for x in 640:
			if not same.get_pixel(x, y).is_equal_approx(orig.get_pixel(x, y)):
				diff += 1
	print("arena: cópia fiel? px diferentes = ", diff)
	arena(true).save_png(ASSETS + "fight/arena_bg.png")
	lamp().save_png(ASSETS + "garage/lamp.png")
	print("6d3: arena_bg e lamp gravados em ", ASSETS)
	quit()

func hsh(x: int, y: int, s := 0) -> int:
	var v := (x * 73856093) ^ (y * 19349663) ^ (s * 83492791)
	return absi(v) % 100

func wall_symbol(bg: Image) -> Image:
	var under := bg.get_region(Rect2i(P_SYMBOL.x, P_SYMBOL.y, 32, 40))
	var m: Image = L.blank(32, 40)     # máscara de tinta: b1 (disco), cream/white (lâmpada e raízes)
	var cx := 16.0
	var cy := 15.0
	L.ellipse(m, cx, cy, 14.5, 14.5, "b1")
	L.ring(m, cx, cy, 14.5, 14.5, 1.0, "b2")
	# lâmpada: vidro, pescoço, rosca
	L.ellipse(m, cx, 11.5, 7.5, 7.5, "cream")
	L.trap(m, 17, 20, 11.5, 20.5, 13, 19, "cream")
	for y in range(21, 26):
		L.R(m, 13, y, 7, 1, "cream" if y % 2 == 1 else "b1")
	L.R(m, 14, 26, 5, 1, "cream")
	# filamento e brilho
	L.line(m, 14, 13, 15, 11, "b1"); L.line(m, 15, 11, 16, 13, "b1"); L.line(m, 16, 13, 17, 11, "b1"); L.line(m, 17, 11, 18, 13, "b1")
	L.R(m, 14, 14, 1, 4, "b1"); L.R(m, 18, 14, 1, 4, "b1")
	L.P(m, 11, 9, "white"); L.P(m, 11, 10, "white"); L.P(m, 12, 8, "white"); L.P(m, 13, 7, "white")
	# raízes saindo da rosca (dentro do disco e para fora dele)
	L.R(m, 16, 27, 1, 9, "cream")
	L.line(m, 15, 28, 9, 34, "cream"); L.line(m, 9, 34, 6, 37, "cream")
	L.line(m, 17, 28, 23, 34, "cream"); L.line(m, 23, 34, 26, 37, "cream")
	L.line(m, 13, 30, 11, 32, "cream"); L.line(m, 19, 30, 21, 32, "cream")
	L.P(m, 15, 36, "cream"); L.P(m, 17, 37, "cream")
	# escorridos do disco
	for d: Array in [[8, 27, 4], [24, 26, 3]]:
		for k in d[2]:
			L.P(m, d[0], d[1] + k, "b1")
	# tinta sobre a parede: afunda no rejunte (1 passo mais escura) e falha em alguns pontos
	var out: Image = L.blank(32, 40)
	for y in 40:
		for x in 32:
			var c := m.get_pixel(x, y)
			if c.a == 0.0:
				continue
			if hsh(x, y, 23) < 3:
				continue
			var u := under.get_pixel(x, y)
			var lum := u.r * 0.3 + u.g * 0.59 + u.b * 0.11
			if lum < 0.28:
				c = L.shade(c, -1)
			out.set_pixel(x, y, c)
	L.light(out, Rect2i(0, 0, 32, 40), LIGHT_C - Vector2(P_SYMBOL), 300.0, 1.1, 3.6, -1, 1, 0.9)
	return out

# ================================================================== arena (fundo da luta)
## Cópia fiel do make_arena da Fase 3 (fix=false sai pixel a pixel igual ao arena_bg de antes) com as correções da 6d3.
func arena(fix: bool) -> Image:
	var img: Image = L.blank(640, 360)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	L.R(img, 0, 0, 640, 360, "ink")
	# céu: noite, brilho fraco da cidade no horizonte
	L.dither(img, 0, 40, 640, 14, "b0")
	L.R(img, 0, 54, 640, 30, "b0")
	L.dither(img, 0, 70, 640, 10, "b1", 1)
	for i in 40:
		L.P(img, rng.randi_range(0, 639), rng.randi_range(2, 50), "g1" if i % 4 else "cream")
	# prédios ao longe (silhueta) dos dois lados
	for bx in [[0, 70, 44], [60, 62, 30], [560, 58, 40], [598, 66, 42]]:
		L.R(img, bx[0], bx[1], bx[2], 120, "d1")
		for k in 6:
			L.P(img, bx[0] + rng.randi_range(3, bx[2] - 4), bx[1] + rng.randi_range(4, 30), "y0" if k % 2 else "br2")
	# galpão: parede de chapa ondulada
	var wx0 := 88
	var wx1 := 556
	for x in range(wx0, wx1):
		var ph := (x - wx0) % 6
		var c := "st1"
		if ph == 0:
			c = "st0"
		elif ph == 3 or ph == 4:
			c = "st2"
		L.R(img, x, 70, 1, FLOOR_Y - 70, c)
	for i in 18:
		var cx := rng.randi_range(wx0 + 10, wx1 - 10)
		var cy := rng.randi_range(80, 225)
		var erx := rng.randi_range(4, 12)
		var ery := rng.randi_range(3, 9)
		if not fix:
			L.ellipse_dither(img, cx, cy, erx, ery, "br1", i % 2)
	if fix:
		rust_streaks(img, wx0, wx1)
	L.dither(img, wx0, FLOOR_Y - 12, wx1 - wx0, 12, "d2")
	L.R(img, wx0 - 4, 64, wx1 - wx0 + 8, 6, "d2"); L.R(img, wx0 - 4, 64, wx1 - wx0 + 8, 1, "g0"); L.R(img, wx0 - 4, 70, wx1 - wx0 + 8, 1, "ink")
	L.R(img, wx0 - 1, 70, 1, FLOOR_Y - 70, "d1"); L.R(img, wx1, 70, 1, FLOOR_Y - 70, "d1")
	# placa pintada à mão
	L.R(img, 150, 90, 150, 26, "ink"); L.R(img, 151, 91, 148, 24, "y0"); L.R(img, 151, 91, 148, 2, "y1")
	L.text(img, "BORRACHARIA", 160, 97, "br0", 2)
	for i in 60:
		L.P(img, rng.randi_range(151, 298), rng.randi_range(91, 114), "br3")
	L.R(img, 160, 116, 1, 4, "d1"); L.R(img, 290, 116, 1, 4, "d1")
	L.text(img, "24H", 304, 104, "cream", 1)
	# porta de enrolar fechada
	L.R(img, 382, 118, 124, FLOOR_Y - 118, "ink")
	var yy := 120
	while yy < FLOOR_Y:
		L.R(img, 384, yy, 120, 5, "st2"); L.R(img, 384, yy, 120, 1, "st3"); L.R(img, 384, yy + 4, 120, 1, "st0")
		yy += 6
	L.R(img, 438, FLOOR_Y - 14, 12, 3, "d1")
	if fix:
		L.text(img, "07", 432, 148, "g3", 2, "st0")
	else:
		L.text(img, "07", 432, 150, "cream", 2)
		L.dither(img, 384, 150, 120, 16, "st2", 1)
	# porta lateral com lâmpada pequena
	L.R(img, 124, 168, 30, FLOOR_Y - 168, "ink"); L.R(img, 126, 170, 26, FLOOR_Y - 170, "d2"); L.R(img, 146, 204, 3, 2, "g2")
	L.R(img, 136, 158, 6, 4, "y1"); L.P(img, 138, 158, "y2")
	# pilha de pneus e tambores (direita)
	for t in [[594, 246], [594, 232], [594, 218], [618, 248], [618, 234]]:
		L.ellipse(img, t[0], t[1], 13, 7, "d1"); L.ellipse(img, t[0], t[1] - 1, 12, 5, "d2"); L.ellipse(img, t[0], t[1] - 1, 5, 2, "ink")
	for dx in [522, 548]:
		L.R(img, dx, 212, 22, 40, "ink"); L.R(img, dx + 1, 213, 20, 38, "st1"); L.R(img, dx + 1, 213, 4, 38, "st0")
		L.R(img, dx + 1, 222, 20, 3, "r1"); L.R(img, dx + 1, 240, 20, 3, "r1"); L.R(img, dx + 14, 213, 2, 38, "st2")
		L.ellipse(img, dx + 11, 213, 10, 2, "st0")
	# cerca de alambrado + poste de luz de sódio (esquerda)
	for x in range(0, 86):
		for y in range(150, 250):
			if (x + y) % 6 == 0 or (x - y + 600) % 6 == 0:
				L.P(img, x, y, "g0")
	for px in [6, 46, 84]:
		L.R(img, px, 146, 2, 104, "st1")
	L.R(img, 28, 84, 3, 166, "st0"); L.R(img, 28, 84, 16, 3, "st0"); L.R(img, 38, 86, 9, 3, "y1")
	# chão: asfalto
	L.R(img, 0, FLOOR_Y, 640, 120, "d2")
	for i in 2600:
		L.P(img, rng.randi_range(0, 639), rng.randi_range(FLOOR_Y, 359), "g0" if i % 3 else "d1")
	L.R(img, 0, FLOOR_Y, 640, 1, "d1")
	# faixas de vaga apagadas, em perspectiva (ponto de fuga 320,-28)
	for xb in [40, 170, 470, 600]:
		var xf: float = 320 + (xb - 320) * (360.0 + 28.0) / (FLOOR_Y + 28.0)
		for k in range(0, 120):
			var t := k / 120.0
			if int(k / 6) % 3 != 2:
				L.P(img, int(lerpf(xb, xf, t)), FLOOR_Y + k, "g2")
	L.R(img, 0, 262, 640, 1, "g1")
	for i in 7:
		L.ellipse_dither(img, rng.randi_range(40, 600), rng.randi_range(270, 350), rng.randi_range(6, 16), rng.randi_range(2, 4), "d1", i % 2)
	# carro estacionado com o farol aceso
	var car: Image = L.blank(118, 44)
	L.R(car, 4, 18, 110, 18, "d1"); L.rrect(car, 22, 4, 62, 18, "d1")
	L.R(car, 30, 8, 22, 10, "b0"); L.R(car, 56, 8, 22, 10, "b0"); L.R(car, 31, 9, 6, 1, "b1")
	L.R(car, 4, 20, 110, 1, "g0")
	L.ellipse(car, 24, 36, 8, 7, "ink"); L.ellipse(car, 24, 36, 3, 3, "g0")
	L.ellipse(car, 92, 36, 8, 7, "ink"); L.ellipse(car, 92, 36, 3, 3, "g0")
	L.R(car, 108, 22, 6, 5, "y2"); L.R(car, 4, 22, 4, 4, "r1")
	L.stamp(img, car, 2, 210)
	# luz
	L.light(img, Rect2i(0, 60, 640, 300), Vector2(321, 250), 300.0, 1.5, 3.6, -3, 1, 1.0)
	# facho do farol no chão
	for y in range(236, 330):
		for x in range(118, 330):
			var dv := Vector2(x - 118, (y - 236) * 2.4)
			var ang := absf(atan2(dv.y, dv.x) - 0.35)
			if ang < 0.32 and dv.length() < 230.0:
				var thr: float = (L.BAYER[y % 4][x % 4] + 0.5) / 16.0
				if thr > dv.length() / 260.0 + ang * 1.5:
					img.set_pixel(x, y, L.shade(img.get_pixel(x, y), 1))
	# brilho das lâmpadas pequenas
	for g in [[42, 90, 12], [139, 160, 8]]:
		if fix:
			halo(img, Vector2(g[0], g[1]), float(g[2]) * 1.4)
			continue
		for a in 24:
			var an := a * TAU / 24.0
			L.P(img, int(g[0] + cos(an) * g[2]), int(g[1] + sin(an) * g[2] * 0.8), "y0" if a % 2 else "br3")
	# riscado de giz do "ringue" no chão
	for a in 180:
		if a % 3 == 2:
			continue
		var an := a * TAU / 180.0
		L.P(img, int(321 + cos(an) * 168), int(316 + sin(an) * 30), "g3")
	# cabo do refletor
	L.line(img, 92, 66, LAMP_POS.x, LAMP_POS.y, "ink"); L.line(img, LAMP_POS.x, LAMP_POS.y, 552, 66, "ink")
	return img

## ferrugem que escorre pelos vales da chapa (no lugar das manchas redondas marrons, que liam como borrão)
func rust_streaks(img: Image, wx0: int, wx1: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6303
	for i in 16:
		var x := wx0 + 6 * rng.randi_range(2, (wx1 - wx0) / 6 - 2)
		var y0 := 71 if i % 3 != 0 else rng.randi_range(110, 170)
		var n := rng.randi_range(14, 44)
		for k in n:
			var y := y0 + k
			if y >= FLOOR_Y - 12:
				break
			var t := float(k) / float(n)
			if t > 0.6 and L.BAYER[y % 4][x % 4] / 16.0 < (t - 0.6) * 2.5:
				continue
			L.P(img, x, y, "br1" if t < 0.35 else "br0")
			if k < n / 3:
				L.P(img, x + 1, y, "br0")
	# ferrugem no pé da chapa (onde a água fica)
	for x in range(wx0, wx1):
		for y in range(FLOOR_Y - 16, FLOOR_Y - 12):
			if (x * 7 + y * 3) % 5 == 0 and (x / 23) % 3 != 1:
				L.P(img, x, y, "br0")

## brilho discreto de lâmpada pequena (1 passo mais claro em dither), no lugar do anel tracejado
func halo(img: Image, c: Vector2, r: float) -> void:
	for y in range(int(c.y - r), int(c.y + r) + 1):
		for x in range(int(c.x - r), int(c.x + r) + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var d := Vector2(x - c.x, (y - c.y) / 0.8).length() / r
			if d < 1.0 and (L.BAYER[y % 4][x % 4] + 0.5) / 16.0 < (1.0 - d) * 0.85:
				img.set_pixel(x, y, L.shade(img.get_pixel(x, y), 1))

## lâmpada da garagem (29x48, 3 quadros): sai o anel de pontinhos laranja em volta (lia como borrão/faísca); fica a lâmpada
## no fio. O brilho discreto já está pintado no garage_bg (a luz da sala parte dela). Parte do original em fonte_6d3/lamp.png.
func lamp() -> Image:
	var src := Image.load_from_file(ROOT + "tools/art/fonte_6d3/lamp.png")
	src.convert(Image.FORMAT_RGBA8)
	var out: Image = L.blank(src.get_width(), src.get_height())
	for q in 3:
		var ox := q * 29
		# começa no fio (linha 0) e segue pelos 8 vizinhos (o fio do quadro 1 tem um degrau na diagonal)
		var keep := {}
		var stack: Array[Vector2i] = []
		for x in 29:
			if src.get_pixel(ox + x, 0).a > 0.0:
				stack.append(Vector2i(x, 0))
		while not stack.is_empty():
			var p: Vector2i = stack.pop_back()
			if keep.has(p) or p.x < 0 or p.y < 0 or p.x >= 29 or p.y >= 48:
				continue
			if src.get_pixel(ox + p.x, p.y).a == 0.0:
				continue
			keep[p] = true
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					stack.append(p + Vector2i(dx, dy))
		var wire := Color(0, 0, 0, 0)
		for x in 29:
			if src.get_pixel(ox + x, 0).a > 0.0:
				wire = src.get_pixel(ox + x, 0)
		for p: Vector2i in keep:
			var c := src.get_pixel(ox + p.x, p.y)
			# pontinho do anel que caiu em cima do fio volta a ser fio (fio = 1 px de largura acima do soquete)
			var row := 0
			for x in 29:
				if keep.has(Vector2i(x, p.y)):
					row += 1
			if row == 1 and not c.is_equal_approx(wire):
				c = wire
			out.set_pixel(ox + p.x, p.y, c)
	return out
