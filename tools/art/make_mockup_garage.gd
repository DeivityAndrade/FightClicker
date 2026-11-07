extends SceneTree
## Mockup PLACEHOLDER da tela principal — local 1: Fundo de garagem.
## Rodar (headless):
##   godot --headless --path <dir_com_project.godot_vazio> --script E:/Fightclicker/tools/art/make_mockup_garage.gd
## Saída: docs/arte/mockups/garagem_base.png (640x360) e garagem_x2.png (1280x720).

const OUT := "E:/Fightclicker/docs/arte/mockups/garagem"
var L

# geometria da sala (ver direcao-visual.md §4)
const VPX := 320.0
const VPY := -28.0
const K := 0.78
const BX0 := 170
const BX1 := 470
const FLOOR_Y := 220
const FRONT_Y := 289

func _init() -> void:
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	draw_room(img, rng)
	draw_props_back(img, rng)
	draw_center(img)
	L.light(img, L.SCENE, Vector2(305, 90), 300.0, 1.1, 3.6, -3, 1, 0.9)
	draw_after_light(img)
	draw_juice(img)
	L.game_ui(img, {
		"money": "$ 38.0", "treino": "TREINO 245", "treino_s": "+1.50/S", "fama": "FAMA 0",
		"local": "FUNDO DE GARAGEM", "carreira": "CARREIRA 1",
		"attrs": [["FORÇA", "12", 0.60, "r3", "r2"], ["AGILIDADE", "5", 0.25, "b3", "b2"], ["RESISTÊNCIA", "7", 0.35, "y1", "y0"]],
		"legado": "0", "adv": "ADVERSÁRIO", "adv2": "AMADOR 1/5", "risco": "EQUILIBRADO", "risco_cor": "y1",
		"cmp": [["FOR", 15, 12], ["AGI", 4, 5], ["RES", 9, 7]],
		"shop": [
			{"name": "PARCEIRO", "prod": "+0.50/S", "qty": "X1", "cost": "$ 15.0", "icon": "gr1", "icon2": "gr3"},
			{"name": "TREINADOR", "prod": "+4.00/S", "qty": "X0", "cost": "$ 120", "can": false, "icon": "b1", "icon2": "b3"},
			{"locked": true, "req": "CINTURÃO"},
		],
		"ups": [["SACO NOVO", "$ 60.0", "r1"], ["CORDA BOA", "$ 45.0", "br3", "r2"], ["ÓLEO ESTEIRA", "$ 30.0", "st2"]],
		"prox_local": "ACADEMIA", "prox_req": "PRECISA CINTURÃO",
		"clique": "+12", "dica": "CLIQUE NO SACO PARA TREINAR",
		"focos": [["FORÇA", "SACO", "r1", true], ["AGILIDADE", "CORDA", "b1", false], ["RESISTÊNCIA", "ESTEIRA", "y0", false]],
	})
	L.save_scaled(img, OUT, 2)
	print("ok: ", OUT)
	quit()

func side_y(yb: float) -> float:
	# projeta um ponto da borda da parede do fundo até a moldura da frente
	return VPY + (yb - VPY) / K

func draw_room(img: Image, rng: RandomNumberGenerator) -> void:
	# --- parede do fundo: blocos de concreto em amarração
	L.R(img, BX0, 18, BX1 - BX0, FLOOR_Y - 18, "g1")
	var row := 0
	var y := FLOOR_Y - 10
	while y > 8:
		var off := 0 if row % 2 == 0 else 10
		var x := BX0 - off
		while x < BX1:
			var x0 := maxi(x, BX0)
			var x1 := mini(x + 20, BX1)
			var tone := "g1"
			var r := rng.randf()
			if r < 0.12:
				tone = "g0"
			elif r > 0.92:
				tone = "g2"
			L.R(img, x0, y, x1 - x0, 10, tone)
			if tone == "g2":
				L.R(img, x0, y, x1 - x0, 1, "g3")
			L.R(img, x0, y + 9, x1 - x0, 1, "g0")
			if x + 19 < BX1:
				L.R(img, x + 19, y, 1, 10, "g0")
			for i in 3:
				L.P(img, rng.randi_range(x0, x1 - 1), rng.randi_range(y + 1, y + 8), "g0")
			x += 20
		y -= 10
		row += 1
	# umidade na base da parede
	for yy in range(FLOOR_Y - 18, FLOOR_Y):
		for xx in range(BX0, BX1):
			var t := float(yy - (FLOOR_Y - 18)) / 18.0
			if (L.BAYER[yy % 4][xx % 4] + 0.5) / 16.0 < t * 0.7:
				img.set_pixel(xx, yy, L.shade(img.get_pixel(xx, yy), -1))
	# --- paredes laterais (mais escuras, linhas de argamassa em perspectiva)
	for side in [0, 1]:
		var xa := 128 if side == 0 else BX1
		var xb := BX0 if side == 0 else 512
		for xx in range(xa, xb):
			var t := float(xx - 128) / float(BX0 - 128) if side == 0 else float(511 - xx) / float(511 - BX1)
			var yb := int(round(lerpf(FRONT_Y, FLOOR_Y, t)))
			L.R(img, xx, 18, 1, yb - 18, "g0")
		var yb2 := FLOOR_Y - 10
		var band := 0
		while yb2 > -40:
			var yf := side_y(yb2)
			var ex := BX0 if side == 0 else BX1
			var fx := 128 if side == 0 else 511
			L.line(img, ex, yb2, fx, int(round(yf)), "d2")
			# junta vertical intercalada
			var jx := (149 if band % 2 == 0 else 138) if side == 0 else (491 if band % 2 == 0 else 502)
			var tt := float(jx - ex) / float(fx - ex)
			var ytop := lerpf(yb2, yf, tt)
			var ybot := lerpf(yb2 + 10, side_y(yb2 + 10), tt)
			L.R(img, jx, int(ytop), 1, int(ybot - ytop), "d2")
			yb2 -= 10
			band += 1
		# quina
		L.line(img, BX0 if side == 0 else BX1, 18, BX0 if side == 0 else BX1, FLOOR_Y, "d1")
	# --- chão de concreto
	L.trap(img, FLOOR_Y, FRONT_Y, BX0, BX1, 128, 511, "g2")
	for i in 900:
		var yy := rng.randi_range(FLOOR_Y + 1, FRONT_Y)
		var t := float(yy - FLOOR_Y) / float(FRONT_Y - FLOOR_Y)
		var xl := lerpf(BX0, 128, t)
		var xr := lerpf(BX1, 511, t)
		L.P(img, rng.randi_range(int(xl), int(xr)), yy, "g1" if i % 3 else "g3")
	# juntas de dilatação
	for i in range(1, 4):
		var bx := lerpf(BX0, BX1, i / 4.0)
		var fx := lerpf(128, 511, i / 4.0)
		L.line(img, int(bx), FLOOR_Y, int(fx), FRONT_Y, "g1")
	var yj := 248
	var sj := (yj - VPY) / (FRONT_Y - VPY)
	L.R(img, int(VPX - 192 * sj), yj, int(384 * sj), 1, "g1")
	# sombra no pé da parede
	L.trap(img, FLOOR_Y, FLOOR_Y + 2, BX0, BX1, BX0 - 1, BX1 + 1, "g1")
	L.R(img, BX0, FLOOR_Y, BX1 - BX0, 1, "d2")
	# manchas de óleo
	L.ellipse_dither(img, 442, 278, 22, 5, "g0")
	L.ellipse(img, 446, 278, 9, 2, "g0")
	L.ellipse_dither(img, 214, 238, 14, 3, "g1", 1)
	L.ellipse_dither(img, 380, 284, 8, 2, "g1")
	# viga de madeira
	L.R(img, BX0, 25, BX1 - BX0, 7, "br1")
	L.R(img, BX0, 25, BX1 - BX0, 1, "br2")
	L.R(img, BX0, 31, BX1 - BX0, 1, "br0")
	L.R(img, BX0, 32, BX1 - BX0, 1, "ink")
	for i in 14:
		L.R(img, BX0 + 6 + i * 21, 27 + (i % 3), 7 + (i % 4), 1, "br0")

func draw_props_back(img: Image, rng: RandomNumberGenerator) -> void:
	# --- porta de garagem (parede do fundo, direita)
	var dx := 382
	var dw := 82
	var dy := 100
	L.R(img, dx - 3, dy - 3, dw + 6, FLOOR_Y - dy + 3, "ink")
	L.R(img, dx - 2, dy - 2, dw + 4, FLOOR_Y - dy + 2, "d2")
	var y := dy
	var k := 0
	while y < FLOOR_Y - 2:
		var h := mini(8, FLOOR_Y - 2 - y)
		L.R(img, dx, y, dw, h, "st2")
		L.R(img, dx, y, dw, 1, "st3")
		L.R(img, dx, y + h - 2, dw, 1, "st1")
		L.R(img, dx, y + h - 1, dw, 1, "st0")
		if k == 6:   # amassado
			L.R(img, dx + 50, y + 2, 9, 3, "st1")
			L.R(img, dx + 51, y + 2, 7, 1, "st0")
		y += 8
		k += 1
	L.R(img, dx + dw / 2 - 5, FLOOR_Y - 12, 10, 3, "d1")
	L.R(img, dx + dw / 2 - 5, FLOOR_Y - 12, 10, 1, "st3")
	for i in 40:   # ferrugem na base
		L.P(img, rng.randi_range(dx, dx + dw - 1), rng.randi_range(FLOOR_Y - 22, FLOOR_Y - 3), "br2" if i % 2 else "br1")
	# --- carro velho coberto com lona (fundo, esquerda)
	var car: Image = L.blank(98, 54)
	L.ellipse(car, 20, 45, 9, 8, "d1"); L.ellipse(car, 20, 45, 4, 4, "g1")
	L.ellipse(car, 78, 45, 9, 8, "d1"); L.ellipse(car, 78, 45, 4, 4, "g1")
	L.rrect(car, 2, 20, 94, 24, "st1")
	L.ellipse(car, 50, 20, 30, 15, "st1")
	L.ellipse_dither(car, 50, 15, 25, 9, "st2")
	L.ellipse(car, 54, 11, 14, 4, "st2")
	L.R(car, 4, 21, 90, 2, "st2")
	for fx in [12, 28, 44, 66, 84]:
		for yy in range(24, 42):
			L.P(car, fx + (1 if (yy / 4) % 2 == 0 else 0), yy, "st0")
	for xx in range(2, 96):
		L.P(car, xx, 42 + (xx / 3) % 2, "st0")
	L.line(car, 3, 31, 95, 29, "br3")
	L.ellipse_dither(img, 228, 226, 50, 5, "d2")
	L.stamp(img, car, 178, 174)
	# --- prateleira com latas
	L.R(img, 180, 118, 72, 3, "br2"); L.R(img, 180, 120, 72, 1, "br0")
	L.R(img, 186, 121, 2, 6, "d2"); L.R(img, 244, 121, 2, 6, "d2")
	var can: Image = L.blank(12, 14)
	L.R(can, 0, 0, 12, 14, "st2"); L.R(can, 0, 0, 12, 2, "st3"); L.R(can, 0, 5, 12, 5, "r1"); L.R(can, 0, 0, 2, 14, "st1")
	L.stamp(img, can, 184, 104)
	var can2: Image = L.blank(10, 10)
	L.R(can2, 0, 0, 10, 10, "b1"); L.R(can2, 0, 0, 10, 1, "b2"); L.R(can2, 0, 3, 10, 3, "cream")
	L.stamp(img, can2, 200, 108)
	var bottle: Image = L.blank(6, 16)
	L.R(bottle, 2, 0, 2, 4, "gr1"); L.R(bottle, 0, 4, 6, 12, "gr1"); L.R(bottle, 4, 5, 1, 9, "gr2")
	L.stamp(img, bottle, 215, 102)
	var box: Image = L.blank(22, 12)
	L.R(box, 0, 0, 22, 12, "br3"); L.R(box, 0, 0, 22, 2, "y0"); L.R(box, 10, 0, 2, 12, "br2")
	L.stamp(img, box, 226, 106)
	# --- pôster de luta (original) com canto rasgado
	var pst: Image = L.blank(26, 36)
	L.R(pst, 0, 0, 26, 36, "cream")
	L.R(pst, 0, 0, 26, 20, "r1")
	L.ellipse(pst, 13, 7, 3, 3, "ink"); L.R(pst, 9, 10, 8, 9, "ink"); L.R(pst, 16, 9, 6, 3, "ink")
	L.R(pst, 0, 19, 26, 1, "y0")
	L.text(pst, "LUTA", 1, 23, "ink")
	L.R(pst, 3, 32, 20, 1, "g2")
	for i in 6:
		for j in 6 - i:
			pst.set_pixel(25 - j, i, Color(0, 0, 0, 0))
	L.stamp(img, pst, 270, 66)
	L.P(img, 270, 66, "g3"); L.P(img, 295, 101, "g3")
	# --- foto do mentor (detalhe de narrativa)
	var ph: Image = L.blank(12, 14)
	L.R(ph, 0, 0, 12, 14, "br1"); L.R(ph, 2, 2, 8, 10, "g3")
	L.ellipse(ph, 6, 5, 2, 2, "g1"); L.R(ph, 3, 8, 6, 4, "g1")
	L.stamp(img, ph, 240, 70)
	# --- corda de varal num prego
	L.P(img, 352, 72, "d1"); L.P(img, 352, 73, "g3")
	L.ring(img, 352, 88, 8, 14, 2, "cream")
	L.ring(img, 352, 88, 7, 13, 1, "g3")
	L.R(img, 345, 99, 3, 9, "br2"); L.R(img, 345, 99, 1, 9, "br1")
	L.R(img, 356, 101, 3, 9, "br2"); L.R(img, 356, 101, 1, 9, "br1")
	# --- marcas de giz no chão (pular corda)
	for i in 2:
		var cx := 172 + i * 26
		L.line(img, cx, 266, cx + 8, 272, "cream")
		L.line(img, cx + 8, 266, cx, 272, "cream")
	L.ring(img, 230, 280, 10, 4, 1, "cream")
	L.dither(img, 160, 276, 16, 2, "g3")
	# --- esteira velha (direita) + parceiro de treino correndo nela
	var tm: Image = L.blank(86, 42)
	L.R(tm, 8, 30, 76, 2, "d1")
	L.R(tm, 8, 32, 76, 6, "st1"); L.R(tm, 8, 32, 76, 1, "st2"); L.R(tm, 8, 37, 76, 1, "st0")
	L.ellipse(tm, 10, 34, 3, 3, "st0"); L.ellipse(tm, 82, 34, 3, 3, "st0")
	for i in 22:
		L.P(tm, rng.randi_range(30, 52) if i % 2 else rng.randi_range(62, 76), rng.randi_range(32, 37), "br2" if i % 3 else "br1")
	L.R(tm, 12, 38, 4, 3, "d2"); L.R(tm, 76, 38, 4, 3, "d2")
	L.line(tm, 12, 30, 6, 6, "st1"); L.line(tm, 13, 30, 7, 6, "st1"); L.line(tm, 14, 30, 8, 6, "st2")
	L.R(tm, 0, 0, 16, 8, "st0"); L.R(tm, 3, 2, 8, 4, "d1"); L.P(tm, 4, 3, "gr2"); L.R(tm, 0, 0, 16, 1, "st1")
	L.R(tm, 7, 11, 24, 2, "st2")
	L.ellipse_dither(img, 446, 266, 42, 4, "d2")
	L.stamp(img, tm, 402, 226)
	var partner: Image = L.flipped(L.fighter({"shirt": ["gr0", "gr1", "gr2"], "shorts": ["d1", "d2", "g0"], "gloves": [], "hair": ["ink", "d2"]}))
	L.stamp(img, partner, 424, 189)

func draw_center(img: Image) -> void:
	# sombras no chão
	L.ellipse(img, 303, 272, 15, 3, "g1")
	L.ellipse_dither(img, 303, 272, 19, 4, "g1", 1)
	L.ellipse_dither(img, 336, 266, 14, 3, "g1")
	# corrente do saco
	for yy in range(33, 186):
		if (yy / 3) % 2 == 0:
			L.P(img, 336, yy, "g2"); L.P(img, 337, yy, "g1")
		else:
			L.P(img, 335, yy, "g1"); L.P(img, 338, yy, "g1")
	L.line(img, 336, 186, 324, 192, "g2"); L.line(img, 336, 186, 348, 192, "g2")
	L.ring(img, 336, 186, 3, 3, 1, "g3")
	# saco remendado
	var bag: Image = L.blank(30, 62)
	L.rrect(bag, 0, 4, 30, 58, "r1")
	L.R(bag, 2, 0, 26, 6, "d2"); L.R(bag, 2, 0, 26, 1, "g1")
	L.R(bag, 0, 6, 6, 54, "r0"); L.R(bag, 20, 8, 3, 50, "r2"); L.R(bag, 21, 10, 1, 8, "r3")
	L.R(bag, 1, 60, 28, 2, "r0")
	for yy in range(10, 58, 3):
		L.P(bag, 9, yy, "r0")
	# fitas (tortas)
	for t in [[16, 0], [38, 1]]:
		for xx in 30:
			var yy: int = t[0] + (xx / 10 if t[1] == 0 else 2 - xx / 10)
			L.P(bag, xx, yy, "g3"); L.P(bag, xx, yy + 1, "g3"); L.P(bag, xx, yy + 2, "g2")
			L.P(bag, xx, yy - 1, "cream" if xx > 18 and xx < 24 else "g3")
	# remendo em X
	L.line(bag, 5, 46, 12, 53, "g3"); L.line(bag, 12, 46, 5, 53, "g3")
	L.line(bag, 6, 46, 13, 53, "g2")
	L.stamp(img, bag, 321, 190)
	# lutador
	var f: Image = L.fighter()
	L.stamp(img, f, 281, 205)

func draw_after_light(img: Image) -> void:
	# lâmpada pendurada (fica acesa: desenhada depois da luz)
	L.R(img, 300, 32, 1, 28, "d1")
	L.R(img, 298, 58, 5, 4, "d2"); L.R(img, 298, 58, 5, 1, "g1")
	L.rrect(img, 297, 62, 7, 8, "ink")
	L.rrect(img, 298, 62, 5, 7, "y1")
	L.R(img, 299, 63, 2, 3, "y2")
	for a in 28:
		var ang := a * TAU / 28.0
		var rr := 10.0 + (a % 2) * 2.0
		L.P(img, int(300.5 + cos(ang) * rr), int(66 + sin(ang) * rr), "y0")
	# luz do dia vazando por baixo da porta
	L.R(img, 382, FLOOR_Y - 2, 82, 2, "y2")
	for yy in range(FLOOR_Y, FLOOR_Y + 16):
		var t := float(yy - FLOOR_Y) / 16.0
		var xl := int(lerpf(382, 372, t))
		var xr := int(lerpf(463, 474, t))
		for xx in range(xl, xr):
			var thr: float = (L.BAYER[yy % 4][xx % 4] + 0.5) / 16.0
			if thr > t * 1.1:
				var c := img.get_pixel(xx, yy)
				img.set_pixel(xx, yy, L.shade(c, 1))

func draw_juice(img: Image) -> void:
	# impacto da luva no saco
	var cx := 321
	var cy := 220
	for d in [Vector2i(1, -1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		L.line(img, cx + d.x * 3, cy + d.y * 3, cx + d.x * 8, cy + d.y * 8, "white")
	L.P(img, cx, cy, "y2")
	# número flutuando
	L.text_center(img, "+12 FORÇA", 336, 168, "y1", 1, null, "ink")
	L.text_center(img, "+12", 360, 150, "y0", 1, null, "ink")
	# cursor = luva equipada
	var cur: Image = L.blank(10, 10)
	L.glove(cur, 0, 0, 9, 10, ["r0", "r1", "r2"])
	var curo: Image = L.outlined(cur, "white")
	L.stamp(img, curo, 352, 236)
