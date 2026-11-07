extends SceneTree
## Sprites PLACEHOLDER da Fase 2 — Treino na garagem. Tudo gerado por código, paleta fechada
## de docs/arte/direcao-visual.md (fonte da verdade: tools/art/pixel_lib.gd).
## Rodar headless a partir de uma pasta com um project.godot vazio (não importa nada no projeto):
##   godot --headless --path <pasta_tmp> --quit-after 30 --script E:/Fightclicker/tools/art/make_sprites_fase2.gd
## Saída:
##   assets/sprites/**.png        (resolução base, 1x, um arquivo por sprite/folha de quadros)
##   assets/sprites/font/*.fnt    (fonte bitmap BMFont, carregada direto pelo Godot)
##   assets/sprites/manifest.json (quadro, nº de quadros, fps, pivô, posição na sala)
##   docs/arte/mockups/fase2_sprites_x3.png (folha de contato) e fase2_sala_x2.png (conferência)

const ROOT := "E:/Fightclicker/"
const OUT := ROOT + "assets/sprites/"
const RES := "res://assets/sprites/"
const MOCK := ROOT + "docs/arte/mockups/"
const LIGHT_C := Vector2(305, 90)

# ---- posições na sala (coordenadas da base 640x360). As mesmas vão para o manifest.
const P_ROOM := Vector2i(128, 18)
const P_LAMP := Vector2i(300, 32)
const P_ROPE_NAIL := Vector2i(352, 72)
const P_BAG_CENTER := Vector2i(336, 183)
const P_BAG_LEFT := Vector2i(258, 160)
const BEAM_BOTTOM := 33
const P_TM_CENTER := Vector2i(336, 280)
const P_TM_RIGHT := Vector2i(445, 267)
const P_FIGHTER_BAG := Vector2i(303, 272)
const P_FIGHTER_ROPE := Vector2i(336, 272)
const P_FIGHTER_TM := Vector2i(339, 269)
const P_FX_BAG := Vector2i(323, 222)
const CLICK_AREA := Rect2i(312, 182, 48, 90)
const P_NEIGHBOR := [Vector2i(176, 284), Vector2i(220, 258), Vector2i(488, 286)]
const P_UNCLE := [Vector2i(455, 236), Vector2i(398, 230)]

# geometria da sala (direcao-visual.md §4)
const VPX := 320.0
const VPY := -28.0
const K := 0.78
const BX0 := 170
const BX1 := 470
const FLOOR_Y := 220
const FRONT_Y := 289

var L
var M := {}            # manifest: id -> dados
var SHEETS := []       # [id, Image folha, largura do quadro]
var F := {}            # id -> Array de quadros (Image)

const O_FIGHTER := {"skin": ["sk0", "sk1", "sk2"], "shirt": ["cream", "white", "white"],
	"shorts": ["b0", "b1", "b2"], "gloves": ["r0", "r1", "r2"], "hair": ["br0", "br1"]}

func _init() -> void:
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	make_background()
	make_lamp()
	make_bag()
	make_rope()
	make_treadmill()
	make_fighter()
	make_people()
	make_glove_cursor()
	make_fx()
	make_ui()
	make_icons()
	make_font()
	write_manifest()
	make_contact_sheet()
	make_room_check()
	print("ok: sprites da fase 2 gerados")
	quit()

# ================================================================ utilidades
func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

func strip(frames: Array) -> Image:
	var fw: int = frames[0].get_width()
	var fh: int = frames[0].get_height()
	var s: Image = L.blank(fw * frames.size(), fh)
	for i in frames.size():
		s.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	return s

func save_sheet(id: String, rel: String, frames: Array, fps: float, pivot: Vector2i, info := {}) -> void:
	var s := strip(frames)
	var path := OUT + rel
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	s.save_png(path)
	var e := {"file": RES + rel, "frame_size": [frames[0].get_width(), frames[0].get_height()],
		"frames": frames.size(), "fps": fps, "pivot": [pivot.x, pivot.y]}
	for k in info:
		e[k] = info[k]
	M[id] = e
	F[id] = frames
	SHEETS.append([id, s, frames[0].get_width()])

func xy(v: Vector2i) -> Array:
	return [v.x, v.y]

## Aplica a luz da lâmpada (a mesma do fundo) num sprite que fica parado num ponto fixo.
func lit(img: Image, topleft: Vector2i, min_step := -2) -> Image:
	var c: Image = img.duplicate()
	L.light(c, Rect2i(0, 0, c.get_width(), c.get_height()), LIGHT_C - Vector2(topleft), 300.0, 1.1, 3.6, min_step, 1, 0.9)
	return c

func flip(img: Image) -> Image:
	var c: Image = img.duplicate()
	c.flip_x()
	return c

func outline_in_place(src: Image, c = "ink") -> Image:
	# contorno sem aumentar o quadro (o desenho precisa ter 1px de folga)
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

# ================================================================ fundo da garagem
func make_background() -> void:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	draw_room(img, rng)
	draw_props_back(img, rng)
	L.light(img, L.SCENE, LIGHT_C, 300.0, 1.1, 3.6, -3, 1, 0.9)
	draw_after_light(img)
	var bg: Image = img.get_region(Rect2i(P_ROOM, Vector2i(384, 272)))
	save_sheet("garage_bg", "garage/garage_bg.png", [bg], 0, Vector2i.ZERO, {
		"pos": xy(P_ROOM), "layer": "fundo", "z": -100,
		"note": "Sala inteira sem aparelhos nem pessoas: paredes, chão, viga, porta, carro com lona, prateleira, pôster, foto, prego da corda, marcas de giz. Luz da lâmpada já aplicada. Tudo o que é sprite fica por cima (ordem por y dos pés)."})
	# sombra de chão (personagens e aparelhos de chão)
	var sh: Image = L.blank(32, 8)
	L.ellipse_dither(sh, 16, 4, 16, 4, "g0")
	L.ellipse(sh, 16, 4, 12, 2.6, "g0")
	save_sheet("floor_shadow", "garage/floor_shadow.png", [sh], 0, Vector2i(16, 4), {
		"note": "Sombra elíptica no chão. Pivô no centro: pôr no ponto dos pés (mesmo x, y do pé - 1), atrás do personagem."})

func side_y(yb: float) -> float:
	return VPY + (yb - VPY) / K

func draw_room(img: Image, rng: RandomNumberGenerator) -> void:
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
	for yy in range(FLOOR_Y - 18, FLOOR_Y):
		for xx in range(BX0, BX1):
			var t := float(yy - (FLOOR_Y - 18)) / 18.0
			if (L.BAYER[yy % 4][xx % 4] + 0.5) / 16.0 < t * 0.7:
				img.set_pixel(xx, yy, L.shade(img.get_pixel(xx, yy), -1))
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
			var jx := (149 if band % 2 == 0 else 138) if side == 0 else (491 if band % 2 == 0 else 502)
			var tt := float(jx - ex) / float(fx - ex)
			var ytop := lerpf(yb2, yf, tt)
			var ybot := lerpf(yb2 + 10, side_y(yb2 + 10), tt)
			L.R(img, jx, int(ytop), 1, int(ybot - ytop), "d2")
			yb2 -= 10
			band += 1
		L.line(img, BX0 if side == 0 else BX1, 18, BX0 if side == 0 else BX1, FLOOR_Y, "d1")
	L.trap(img, FLOOR_Y, FRONT_Y, BX0, BX1, 128, 511, "g2")
	for i in 900:
		var yy := rng.randi_range(FLOOR_Y + 1, FRONT_Y)
		var t := float(yy - FLOOR_Y) / float(FRONT_Y - FLOOR_Y)
		var xl := lerpf(BX0, 128, t)
		var xr := lerpf(BX1, 511, t)
		L.P(img, rng.randi_range(int(xl), int(xr)), yy, "g1" if i % 3 else "g3")
	for i in range(1, 4):
		var bx := lerpf(BX0, BX1, i / 4.0)
		var fx := lerpf(128, 511, i / 4.0)
		L.line(img, int(bx), FLOOR_Y, int(fx), FRONT_Y, "g1")
	var yj := 248
	var sj := (yj - VPY) / (FRONT_Y - VPY)
	L.R(img, int(VPX - 192 * sj), yj, int(384 * sj), 1, "g1")
	L.trap(img, FLOOR_Y, FLOOR_Y + 2, BX0, BX1, BX0 - 1, BX1 + 1, "g1")
	L.R(img, BX0, FLOOR_Y, BX1 - BX0, 1, "d2")
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
	# ganchos na viga (centro e lado), onde a corrente do saco prende
	for hx in [P_BAG_CENTER.x, P_BAG_LEFT.x]:
		L.R(img, hx - 2, 31, 5, 2, "st1")
		L.R(img, hx - 2, 31, 5, 1, "st2")

func draw_props_back(img: Image, rng: RandomNumberGenerator) -> void:
	# porta de garagem
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
		if k == 6:
			L.R(img, dx + 50, y + 2, 9, 3, "st1")
			L.R(img, dx + 51, y + 2, 7, 1, "st0")
		y += 8
		k += 1
	L.R(img, dx + dw / 2 - 5, FLOOR_Y - 12, 10, 3, "d1")
	L.R(img, dx + dw / 2 - 5, FLOOR_Y - 12, 10, 1, "st3")
	for i in 40:
		L.P(img, rng.randi_range(dx, dx + dw - 1), rng.randi_range(FLOOR_Y - 22, FLOOR_Y - 3), "br2" if i % 2 else "br1")
	# carro velho coberto com lona
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
	# prateleira com latas
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
	# pôster (original) com canto rasgado — sem "LUTA" na Fase 2
	var pst: Image = L.blank(26, 36)
	L.R(pst, 0, 0, 26, 36, "cream")
	L.R(pst, 0, 0, 26, 20, "r1")
	L.ellipse(pst, 13, 7, 3, 3, "ink"); L.R(pst, 9, 10, 8, 9, "ink"); L.R(pst, 16, 9, 6, 3, "ink")
	L.R(pst, 0, 19, 26, 1, "y0")
	L.text(pst, "SOCO", 2, 23, "ink")
	L.R(pst, 3, 32, 20, 1, "g2")
	for i in 6:
		for j in 6 - i:
			pst.set_pixel(25 - j, i, Color(0, 0, 0, 0))
	L.stamp(img, pst, 270, 66)
	L.P(img, 270, 66, "g3"); L.P(img, 295, 101, "g3")
	# foto do mentor (só decoração na Fase 2)
	var ph: Image = L.blank(12, 14)
	L.R(ph, 0, 0, 12, 14, "br1"); L.R(ph, 2, 2, 8, 10, "g3")
	L.ellipse(ph, 6, 5, 2, 2, "g1"); L.R(ph, 3, 8, 6, 4, "g1")
	L.stamp(img, ph, 240, 70)
	# prego da corda (a corda é sprite)
	L.P(img, P_ROPE_NAIL.x, P_ROPE_NAIL.y, "d1"); L.P(img, P_ROPE_NAIL.x, P_ROPE_NAIL.y + 1, "g3")
	L.P(img, P_ROPE_NAIL.x + 1, P_ROPE_NAIL.y, "ink")
	# marcas de giz no chão
	for i in 2:
		var cx := 172 + i * 26
		L.line(img, cx, 266, cx + 8, 272, "cream")
		L.line(img, cx + 8, 266, cx, 272, "cream")
	L.ring(img, 230, 280, 10, 4, 1, "cream")
	L.dither(img, 160, 276, 16, 2, "g3")

func draw_after_light(img: Image) -> void:
	# luz do dia vazando por baixo da porta
	L.R(img, 382, FLOOR_Y - 2, 82, 2, "y2")
	for yy in range(FLOOR_Y, FLOOR_Y + 16):
		var t := float(yy - FLOOR_Y) / 16.0
		var xl := int(lerpf(382, 372, t))
		var xr := int(lerpf(463, 474, t))
		for xx in range(xl, xr):
			var thr: float = (L.BAYER[yy % 4][xx % 4] + 0.5) / 16.0
			if thr > t * 1.1:
				img.set_pixel(xx, yy, L.shade(img.get_pixel(xx, yy), 1))

# ================================================================ lâmpada
func make_lamp() -> void:
	var frames := []
	for f in 3:
		var img: Image = L.blank(29, 48)
		var sx := 1 if f == 1 else 0
		L.R(img, 14, 0, 1, 14, "d1")
		L.R(img, 14 + sx, 14, 1, 13, "d1")
		L.R(img, 12 + sx, 26, 5, 4, "d2"); L.R(img, 12 + sx, 26, 5, 1, "g1")
		L.rrect(img, 11 + sx, 30, 7, 8, "ink")
		if f == 2:
			L.rrect(img, 12 + sx, 30, 5, 7, "y0"); L.R(img, 13 + sx, 31, 2, 2, "br3")
		else:
			L.rrect(img, 12 + sx, 30, 5, 7, "y1"); L.R(img, 13 + sx, 31, 2, 3, "y2")
			for a in 28:
				var ang := a * TAU / 28.0
				var rr := 10.0 + (a % 2) * 2.0
				L.P(img, int(14.5 + sx + cos(ang) * rr), int(34 + sin(ang) * rr), "y0")
		frames.append(img)
	save_sheet("lamp", "garage/lamp.png", frames, 0, Vector2i(14, 0), {
		"pos": xy(P_LAMP), "layer": "frente_do_fundo", "z": -50,
		"frames_note": "0 = acesa parada; 1 = balanço (lâmpada 1px para a direita; usar flip_h para o outro lado); 2 = piscada fraca.",
		"anim": {"idle": [0], "flicker": [2, 0], "swing": [1, 0, 1, 0]},
		"note": "Pivô = ponto onde o fio sai da viga. Piscar 1 quadro (2) a cada ~8 s. Balançar (1, flip, 1, 0) a 10 fps quando o saco leva golpe forte (crítico)."})

# ================================================================ saco de pancada
func bag_body(level: int) -> Image:
	var bag: Image = L.blank(30, 62)
	if level == 0:
		L.rrect(bag, 0, 4, 30, 58, "r1")
		L.R(bag, 2, 0, 26, 6, "d2"); L.R(bag, 2, 0, 26, 1, "g1")
		L.R(bag, 0, 6, 6, 54, "r0"); L.R(bag, 20, 8, 3, 50, "r2"); L.R(bag, 21, 10, 1, 8, "r3")
		L.R(bag, 1, 60, 28, 2, "r0")
		for yy in range(10, 58, 3):
			L.P(bag, 9, yy, "r0")
		for t in [[16, 0], [38, 1]]:
			for xx in 30:
				var yy: int = t[0] + (xx / 10 if t[1] == 0 else 2 - xx / 10)
				L.P(bag, xx, yy, "g3"); L.P(bag, xx, yy + 1, "g3"); L.P(bag, xx, yy + 2, "g2")
				L.P(bag, xx, yy - 1, "cream" if xx > 18 and xx < 24 else "g3")
		L.line(bag, 5, 46, 12, 53, "g3"); L.line(bag, 12, 46, 5, 53, "g3")
		L.line(bag, 6, 46, 13, 53, "g2")
		L.P(bag, 15, 61, "br3")   # furinho de onde vaza areia
	else:
		L.rrect(bag, 0, 4, 30, 58, "r2")
		L.R(bag, 2, 0, 26, 6, "d1"); L.R(bag, 2, 0, 26, 1, "g0")
		for xx in range(4, 27, 3):
			L.P(bag, xx, 4, "g1")
		L.R(bag, 0, 6, 6, 54, "r1"); L.R(bag, 0, 8, 2, 50, "r0")
		L.R(bag, 19, 8, 4, 50, "r3"); L.R(bag, 20, 10, 1, 10, "y2")
		L.R(bag, 1, 58, 28, 4, "r1"); L.R(bag, 1, 61, 28, 1, "r0")
		for yy in range(8, 58, 3):
			L.P(bag, 10, yy, "r1")
		for ty in [13, 43]:
			L.R(bag, 0, ty, 30, 3, "white"); L.R(bag, 0, ty + 2, 30, 1, "cream"); L.R(bag, 0, ty, 6, 3, "g3")
			L.R(bag, 0, ty - 1, 30, 1, "r1")
	return bag

## Quadro 40x76 do saco. lean = deslocamento do fundo (px, + = para a direita); dent = afundamento à esquerda.
func bag_frame(level: int, lean: int, dent: int, sand := -1) -> Image:
	var out: Image = L.blank(40, 76)
	L.line(out, 20, 4, 8, 9, "g2"); L.line(out, 19, 4, 31, 9, "g2")
	L.ring(out, 20, 3, 3, 3, 1, "g3")
	var body := bag_body(level)
	var sh: Image = L.blank(38, 62)
	for y in 62:
		var off := int(round(lean * float(y) / 61.0))
		sh.blit_rect(body, Rect2i(0, y, 30, 1), Vector2i(4 + off, y))
	if dent > 0:
		for y in range(18, 42):
			var dd := int(round(dent * (1.0 - absf(y - 30) / 12.0)))
			if dd <= 0:
				continue
			var x0 := 0
			while x0 < 38 and sh.get_pixel(x0, y).a == 0.0:
				x0 += 1
			for x in range(x0, mini(x0 + dd, 38)):
				sh.set_pixel(x, y, Color(0, 0, 0, 0))
			if x0 + dd < 38:
				sh.set_pixel(x0 + dd, y, L.shade(sh.get_pixel(x0 + dd, y), -1))
	L.stamp(out, sh, 1, 7)
	if sand >= 0 and level == 0:
		var sx := 20 + lean
		L.P(out, sx, 70 + sand, "br3")
		L.P(out, sx - 1, 72 + sand, "y0")
	return out

func make_bag() -> void:
	# corrente (ladrilho vertical)
	var ch: Image = L.blank(4, 6)
	for yy in 6:
		if yy < 3:
			L.P(ch, 1, yy, "g2"); L.P(ch, 2, yy, "g1")
		else:
			L.P(ch, 0, yy, "g1"); L.P(ch, 3, yy, "g1")
	save_sheet("bag_chain_tile", "equipment/bag_chain_tile.png", [ch], 0, Vector2i(1, 0), {
		"tile": "vertical", "from_y": BEAM_BOTTOM,
		"note": "Repetir na vertical de y=%d (gancho da viga) até o pivô do saco, em x = pivô.x - 1. TextureRect com stretch_mode Tile, ou Sprite2D com region." % BEAM_BOTTOM})
	var positions := {"centro": xy(P_BAG_CENTER), "lado_esquerdo": xy(P_BAG_LEFT)}
	for lv in 2:
		var idle := []
		var leans := [0, 1, 0, -1]
		for i in 4:
			idle.append(bag_frame(lv, leans[i], 0, i))
		save_sheet("bag_l%d_idle" % lv, "equipment/bag_l%d_idle.png" % lv, idle, 3, Vector2i(20, 0), {
			"loop": true, "positions": positions, "sort_y_offset": 70,
			"note": ("Saco remendado (nível visual 0)" if lv == 0 else "Saco novo (nível visual 1: melhoria 'Fita nova no saco')") + ". Balanço leve ±1 px em loop. Pivô = argola do topo (fim da corrente)."})
		var hit := []
		var seq := [[4, 2], [2, 1], [-1, 0], [0, 0]]
		for i in 4:
			hit.append(bag_frame(lv, seq[i][0], seq[i][1], i))
		save_sheet("bag_l%d_hit" % lv, "equipment/bag_l%d_hit.png" % lv, hit, 12, Vector2i(20, 0), {
			"loop": false, "positions": {"centro": xy(P_BAG_CENTER)}, "sort_y_offset": 70,
			"note": "Reação ao clique: empurra 4 px e afunda do lado do golpe, volta com 1 px de sobra. Começar junto com o quadro 2 (golpe) do lutador. Depois volta para _idle."})
		# versão do lado esquerdo com a luz da sala aplicada (só parado)
		var side := []
		for fr in idle:
			side.append(lit(fr, P_BAG_LEFT - Vector2i(20, 0)))
		save_sheet("bag_l%d_side" % lv, "equipment/bag_l%d_side.png" % lv, side, 3, Vector2i(20, 0), {
			"loop": true, "positions": {"lado_esquerdo": xy(P_BAG_LEFT)}, "sort_y_offset": 70,
			"note": "Igual ao _idle, mas com a luz da lâmpada já aplicada para o ponto do lado esquerdo (quando o foco é corda ou esteira)."})

# ================================================================ corda
func rope_idle(level: int) -> Image:
	var img: Image = L.blank(18, 40)
	if level == 0:
		L.ring(img, 9, 16, 8, 14, 2, "cream")
		L.ring(img, 9, 16, 7, 13, 1, "g3")
		L.R(img, 2, 27, 2, 8, "cream"); L.R(img, 2, 27, 1, 8, "g3"); L.R(img, 1, 34, 3, 2, "g3")     # ponta com nó
		L.R(img, 14, 28, 2, 9, "cream"); L.R(img, 14, 28, 1, 9, "g3"); L.R(img, 14, 36, 3, 2, "g3")
		L.R(img, 0, 11, 3, 5, "br3"); L.R(img, 0, 11, 1, 5, "br2"); L.P(img, 1, 13, "st2")      # prendedor de roupa
	else:
		L.ring(img, 9, 15, 7, 13, 2, "b2")
		L.ring(img, 9, 15, 6, 12, 1, "b1")
		L.R(img, 3, 25, 2, 9, "b2"); L.R(img, 3, 25, 1, 9, "b1"); L.R(img, 2, 33, 3, 4, "d2")
		L.R(img, 13, 26, 2, 9, "b2"); L.R(img, 13, 26, 1, 9, "b1"); L.R(img, 13, 34, 3, 4, "d2")
	var o: Image = L.blank(18, 40)
	L.stamp(o, img.get_region(Rect2i(0, 1, 17, 38)), 1, 1)
	return o

func rope_pose(f: int) -> Dictionary:
	var base := {
		"bsh": V(15, 25), "belb": V(11, 34), "bhand": V(10, 42),
		"fsh": V(29, 24), "felb": V(33, 33), "fhand": V(34, 42),
		"bknee": V(18, 57), "bfoot": V(17, 63), "fknee": V(25, 57), "ffoot": V(25, 63)}
	match f:
		0:
			base["bhand"] = V(9, 40); base["fhand"] = V(35, 40)
		1:
			base["dy"] = 1; base["bknee"] = V(19, 58); base["fknee"] = V(27, 58)
			base["bhand"] = V(11, 43); base["fhand"] = V(35, 43)
		2:
			base["lift"] = 3; base["bfoot"] = V(18, 62); base["ffoot"] = V(26, 62)
			base["bknee"] = V(19, 56); base["fknee"] = V(27, 56)
			base["bhand"] = V(11, 44); base["fhand"] = V(33, 44)
		3:
			base["lift"] = 1; base["bhand"] = V(10, 42); base["fhand"] = V(34, 41)
	return L.pose(base)

## Corda em uso (camada por cima do lutador). cy = ponto de controle da curva.
func rope_overlay(level: int, p: Dictionary, cy: float, behind: bool, fighter: Image) -> Image:
	var lift: int = p.get("lift", 0)
	var dy: int = p.get("dy", 0)
	var hb: Vector2 = p.bhand + Vector2(0, dy - lift + 4)
	var hf: Vector2 = p.fhand + Vector2(0, dy - lift + 4)
	var c := Vector2((hb.x + hf.x) / 2.0, cy)
	var img: Image = L.blank(48, 72)
	var col0 := "cream" if level == 0 else "b2"
	var prev := hb
	for i in range(1, 41):
		var t := i / 40.0
		var q := hb * (1 - t) * (1 - t) + c * 2.0 * (1 - t) * t + hf * t * t
		L.line(img, int(round(prev.x)), int(round(prev.y)), int(round(q.x)), int(round(q.y)), col0)
		prev = q
	var o := outline_in_place(img)
	if behind:
		for y in 72:
			for x in 48:
				if fighter.get_pixel(x, y).a > 0.0:
					o.set_pixel(x, y, Color(0, 0, 0, 0))
	return o

func make_rope() -> void:
	for lv in 2:
		var im := rope_idle(lv)
		var tl := P_ROPE_NAIL - Vector2i(9, 0)
		save_sheet("rope_l%d_idle" % lv, "equipment/rope_l%d_idle.png" % lv, [lit(im, tl, -1)], 0, Vector2i(9, 0), {
			"positions": {"prego": xy(P_ROPE_NAIL)}, "layer": "frente_do_fundo", "z": -40,
			"note": ("Corda de varal com nó e prendedor (nível visual 0)" if lv == 0 else "Corda de verdade, sem nó (nível visual 1: 'Corda sem nó')") + ", pendurada no prego. Aparece quando a corda NÃO está em foco. Pivô = prego. Luz já aplicada."})

# ================================================================ esteira
func treadmill(level: int, f: int, moving: bool) -> Image:
	var tm: Image = L.blank(86, 42)
	var m: Array = ["st0", "st1", "st2"] if level == 0 else ["st1", "st2", "st3"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	# lona
	L.R(tm, 8, 30, 76, 2, "d1")
	for x in range(9, 83):
		var ph := ((x - f * 2) % 8 + 8) % 8
		if ph < 2:
			L.P(tm, x, 30, "g0" if level == 0 else "d2")
	L.R(tm, 8, 32, 76, 6, m[1]); L.R(tm, 8, 32, 76, 1, m[2]); L.R(tm, 8, 37, 76, 1, m[0])
	for rx in [10, 82]:
		L.ellipse(tm, rx, 34, 3, 3, m[0])
		var a := f * PI / 2.0
		L.P(tm, rx + int(round(cos(a) * 1.5)), 34 + int(round(sin(a) * 1.5)), m[2])
	L.R(tm, 12, 38, 4, 3, "d2"); L.R(tm, 76, 38, 4, 3, "d2")
	L.line(tm, 12, 30, 6, 6, m[1]); L.line(tm, 13, 30, 7, 6, m[1]); L.line(tm, 14, 30, 8, 6, m[2])
	L.R(tm, 0, 0, 16, 8, m[0]); L.R(tm, 3, 2, 8, 4, "d1"); L.R(tm, 0, 0, 16, 1, m[1])
	L.R(tm, 7, 11, 24, 2, m[2])
	if level == 0:
		for i in 26:
			var px := rng.randi_range(30, 52) if i % 2 else rng.randi_range(62, 76)
			L.P(tm, px, rng.randi_range(32, 37), "br2" if i % 3 else "br1")
		for i in 6:
			L.P(tm, rng.randi_range(8, 28), rng.randi_range(11, 12), "br1")
		L.P(tm, 1, 5, "br2"); L.P(tm, 14, 6, "br1")
		if moving and f % 2 == 1:
			L.P(tm, 4, 3, "g0")       # visor quase apagado, pisca
	else:
		L.R(tm, 8, 33, 76, 1, "st3")
		L.R(tm, 7, 11, 24, 1, "white")
		L.R(tm, 3, 2, 8, 4, "gr1")
		if moving:
			var bars: Array = [[1, 3, 2, 4], [2, 4, 3, 1], [3, 1, 4, 2], [4, 2, 1, 3]][f % 4]
			for i in 4:
				L.R(tm, 4 + i * 2, 6 - bars[i], 1, bars[i], "gr3")
		else:
			L.R(tm, 4, 4, 6, 1, "gr2")
		L.P(tm, 81, 32, "y2")         # brilho do óleo no rolo
	var o: Image = L.blank(86, 42)
	L.stamp(o, tm.get_region(Rect2i(0, 0, 85, 41)), 1, 1)
	return o

func make_treadmill() -> void:
	for lv in 2:
		var nm := "Esteira enferrujada (nível visual 0)" if lv == 0 else "Esteira lubrificada (nível visual 1: 'Óleo de cozinha na esteira')"
		save_sheet("treadmill_l%d_idle" % lv, "equipment/treadmill_l%d_idle.png" % lv, [treadmill(lv, 0, false)], 0, Vector2i(43, 41), {
			"positions": {"centro": xy(P_TM_CENTER), "lado_direito": xy(P_TM_RIGHT)},
			"note": nm + ", parada. Pivô = meio da base (chão)."})
		var run := []
		for f in 4:
			run.append(treadmill(lv, f, true))
		save_sheet("treadmill_l%d_run" % lv, "equipment/treadmill_l%d_run.png" % lv, run, 12, Vector2i(43, 41), {
			"loop": true, "positions": {"centro": xy(P_TM_CENTER)},
			"note": nm + ", rolando: lona corre 2 px por quadro, rolos giram, visor pisca. Tocar 1 ciclo (4 quadros) por clique ou em loop enquanto o lutador corre."})
		save_sheet("treadmill_l%d_side" % lv, "equipment/treadmill_l%d_side.png" % lv, [lit(treadmill(lv, 0, false), P_TM_RIGHT - Vector2i(43, 41))], 0, Vector2i(43, 41), {
			"positions": {"lado_direito": xy(P_TM_RIGHT)},
			"note": nm + ", parada, com a luz da sala aplicada para o lado direito (foco no saco ou na corda)."})

# ================================================================ lutador
func make_fighter() -> void:
	var o := O_FIGHTER.duplicate()
	var pv := Vector2i(22, 67)
	# respiração
	var idle := []
	var dys := [0, 0, 1, 1]
	var gd := [0, 1, 1, 0]
	for i in 4:
		var g := V(0, gd[i])
		idle.append(L.character(o, L.pose({"dy": dys[i], "bhand": V(14, 16) + g, "fhand": V(32, 15) + g})))
	save_sheet("fighter_idle", "characters/fighter_idle.png", idle, 4, pv, {
		"loop": true, "positions": {"foco_saco": xy(P_FIGHTER_BAG), "foco_corda": xy(P_FIGHTER_ROPE)},
		"facing": "direita",
		"note": "Guarda com respiração (tronco/cabeça e luvas ±1 px). Pivô = entre os pés, na sola. Luvas = cores r0/r1/r2 (só a luva usa vermelho no lutador: trocar de luva = trocar essas 3 cores)."})
	# soco no saco
	var punch := [
		L.pose(),
		L.pose({"lean": -1, "felb": V(29, 31), "fhand": V(30, 17)}),
		L.pose({"lean": 1, "fsh": V(30, 24), "felb": V(36, 22), "fhand": V(41, 20), "fknee": V(27, 57), "bhand": V(15, 17)}),
		L.pose({"felb": V(34, 27), "fhand": V(37, 18)}),
	]
	var pf := []
	for p in punch:
		pf.append(L.character(o, p))
	save_sheet("fighter_punch", "characters/fighter_punch.png", pf, 12, pv, {
		"loop": false, "positions": {"foco_saco": xy(P_FIGHTER_BAG)}, "facing": "direita",
		"frames_note": "0 guarda, 1 antecipação, 2 golpe (luva encosta no saco: disparar saco _hit, impacto e número), 3 volta.",
		"hit_frame": 2, "hit_point": xy(P_FX_BAG)})
	# pular corda (lutador) + corda em uso (camada por cima)
	var rf := []
	var poses := []
	for f in 4:
		var p := rope_pose(f)
		poses.append(p)
		rf.append(L.character(o, p))
	save_sheet("fighter_rope", "characters/fighter_rope.png", rf, 10, pv, {
		"loop": false, "positions": {"foco_corda": xy(P_FIGHTER_ROPE)}, "facing": "direita",
		"frames_note": "0 corda em cima, 1 corda na frente (agacha), 2 corda embaixo (pés sobem 3 px), 3 aterrissa. Desenhar rope_lN_swing por cima, mesmo quadro e mesmo pivô.",
		"hit_frame": 2})
	var cys := [-41.0, 69.0, 95.0, -14.0]
	for lv in 2:
		var ov := []
		for f in 4:
			ov.append(rope_overlay(lv, poses[f], cys[f], f == 3, rf[f]))
		save_sheet("rope_l%d_swing" % lv, "equipment/rope_l%d_swing.png" % lv, ov, 10, pv, {
			"loop": false, "positions": {"foco_corda": xy(P_FIGHTER_ROPE)},
			"note": ("Corda de varal" if lv == 0 else "Corda de verdade") + " girando, sincronizada quadro a quadro com fighter_rope (desenhar POR CIMA do lutador; no quadro 3 a corda passa atrás e já vem recortada)."})
	# correr na esteira (virado para a esquerda, para o painel da esteira)
	var run_p := [
		L.pose({"lean": 1, "fhand": V(31, 25), "felb": V(33, 33), "bhand": V(19, 21), "belb": V(13, 29),
			"fknee": V(30, 55), "ffoot": V(32, 63), "bknee": V(15, 57), "bfoot": V(10, 60)}),
		L.pose({"dy": -1, "lean": 1, "fhand": V(30, 21), "felb": V(33, 29), "bhand": V(17, 25), "belb": V(11, 32),
			"fknee": V(27, 56), "ffoot": V(25, 63), "bknee": V(21, 55), "bfoot": V(15, 59)}),
		L.pose({"lean": 1, "fhand": V(28, 27), "felb": V(30, 33), "bhand": V(21, 19), "belb": V(14, 27),
			"bknee": V(27, 55), "bfoot": V(29, 63), "fknee": V(22, 57), "ffoot": V(16, 60)}),
		L.pose({"dy": -1, "lean": 1, "fhand": V(30, 23), "felb": V(32, 31), "bhand": V(18, 23), "belb": V(12, 30),
			"bknee": V(24, 56), "bfoot": V(22, 63), "fknee": V(27, 55), "ffoot": V(20, 59)}),
	]
	var runf := []
	for p in run_p:
		runf.append(flip(L.character(o, p)))
	save_sheet("fighter_run", "characters/fighter_run.png", runf, 12, Vector2i(25, 67), {
		"loop": true, "positions": {"foco_esteira": xy(P_FIGHTER_TM)}, "facing": "esquerda",
		"sort": "sempre desenhar DEPOIS da esteira (pés em cima da lona)",
		"note": "Corrida em cima da esteira do centro. Pivô = pés na lona (y da lona = pivô da esteira - 11)."})

# ================================================================ vizinho e tio
func make_people() -> void:
	var defs := [
		{"id": "neighbor_1", "o": {"skin": ["br0", "sk0", "sk1"], "shirt": ["gr0", "gr1", "gr2"], "shorts": ["d1", "d2", "g0"],
			"gloves": [], "hair": ["ink", "d2"], "shoes": "chinelo"},
			"poses": [L.pose(), L.pose({"lean": 1, "felb": V(35, 24), "fhand": V(39, 20)}), L.pose({"dy": 1}),
				L.pose({"lean": 1, "bhand": V(33, 19), "belb": V(24, 27)})],
			"fps": 6, "pos": P_NEIGHBOR[0], "left": false, "what": "Vizinho da casa 12 (1ª pessoa, com 1 comprado): boxe de sombra, de chinelo."},
		{"id": "neighbor_2", "o": {"skin": ["sk1", "sk2", "y2"], "shirt": ["b1", "b2", "b3"], "shorts": ["st0", "st1", "st2"],
			"gloves": [], "hair": ["br1", "br2"], "head": "tall", "shoes": "chinelo"},
			"poses": [
				L.pose({"belb": V(14, 35), "bhand": V(13, 43), "felb": V(31, 34), "fhand": V(31, 43), "bknee": V(18, 57), "bfoot": V(18, 63), "fknee": V(25, 57), "ffoot": V(25, 63)}),
				L.pose({"belb": V(9, 26), "bhand": V(4, 24), "felb": V(35, 24), "fhand": V(41, 22), "bknee": V(14, 56), "bfoot": V(11, 63), "fknee": V(29, 56), "ffoot": V(31, 63), "lift": 1}),
				L.pose({"belb": V(12, 15), "bhand": V(12, 7), "felb": V(32, 15), "fhand": V(32, 7), "bknee": V(14, 56), "bfoot": V(11, 63), "fknee": V(29, 56), "ffoot": V(31, 63), "lift": 2}),
				L.pose({"belb": V(9, 26), "bhand": V(4, 24), "felb": V(35, 24), "fhand": V(41, 22), "bknee": V(14, 56), "bfoot": V(11, 63), "fknee": V(29, 56), "ffoot": V(31, 63), "lift": 1})],
			"fps": 6, "pos": P_NEIGHBOR[1], "left": false, "what": "Vizinho (2ª pessoa, com 10): polichinelo."},
		{"id": "neighbor_3", "o": {"skin": ["sk0", "sk1", "sk2"], "shirt": ["br1", "br2", "br3"], "shorts": ["d2", "g0", "g1"],
			"gloves": [], "hair": ["ink", "d2"], "head": "cap", "cap": ["gr0", "gr1", "gr2"], "shoes": "chinelo"},
			"poses": [L.pose(), L.pose({"lift": 1}), L.pose(), L.pose({"dy": 1, "fhand": V(33, 16)})],
			"fps": 6, "pos": P_NEIGHBOR[2], "left": true, "what": "Vizinho (3ª pessoa, com 25): saltita na guarda, boné para trás."},
		{"id": "uncle_1", "o": {"skin": ["sk0", "sk1", "sk2"], "shirt": ["g3", "cream", "white"], "shorts": ["d2", "g0", "g1"],
			"gloves": ["br1", "br2", "br3"], "hair": ["g2", "g3"], "head": "bald", "mustache": "g3", "top": "social",
			"bottom": "pants", "shoes": "sapato", "belly": 3},
			"poses": [L.pose(), L.pose({"dy": 1}), L.pose({"dy": 1, "felb": V(33, 28), "fhand": V(36, 17)}), L.pose()],
			"fps": 4, "pos": P_UNCLE[0], "left": true, "what": "Tio aposentado (1ª pessoa, com 1): guarda lenta de camisa social, calça de tergal e luva velha marrom."},
		{"id": "uncle_2", "o": {"skin": ["br0", "sk0", "sk1"], "shirt": ["b2", "b3", "white"], "shorts": ["br0", "br1", "br2"],
			"gloves": ["br1", "br2", "br3"], "hair": ["g1", "g2"], "head": "bald", "mustache": "g2", "top": "social",
			"bottom": "pants", "shoes": "sapato", "belly": 4},
			"poses": [
				L.pose({"bhand": V(30, 31), "belb": V(20, 33), "fhand": V(35, 30), "felb": V(30, 33)}),
				L.pose({"dy": 2, "bhand": V(30, 31), "belb": V(20, 33), "fhand": V(35, 30), "felb": V(30, 33), "bknee": V(20, 57), "fknee": V(29, 57)}),
				L.pose({"dy": 4, "bhand": V(31, 30), "belb": V(21, 33), "fhand": V(36, 29), "felb": V(31, 33), "bknee": V(22, 56), "fknee": V(31, 56)}),
				L.pose({"dy": 2, "bhand": V(30, 31), "belb": V(20, 33), "fhand": V(35, 30), "felb": V(30, 33), "bknee": V(20, 57), "fknee": V(29, 57)})],
			"fps": 4, "pos": P_UNCLE[1], "left": true, "what": "Tio aposentado (2ª pessoa, com 10): agachamento lento, luvas para a frente."},
	]
	for d in defs:
		var frames := []
		var left: bool = d.left
		var pv := Vector2i(25, 67) if left else Vector2i(22, 67)
		var pos: Vector2i = d.pos
		for p in d.poses:
			var img: Image = L.character(d.o.duplicate(), p)
			if left:
				img = flip(img)
			frames.append(lit(img, pos - pv, -1))
		save_sheet(d.id, "characters/%s_idle.png" % d.id, frames, d.fps, pv, {
			"loop": true, "pos": xy(pos), "facing": "esquerda" if left else "direita",
			"note": d.what + " Luz já aplicada para este ponto (não mover para longe; para outro ponto, gerar de novo)."})

# ================================================================ luva / cursor
func make_glove_cursor() -> void:
	var gl := ["r0", "r1", "r2"]
	var hand: Image = L.blank(10, 11)
	L.glove2(hand, 0, 0, 10, 11, gl)
	save_sheet("glove_old", "equipment/glove_old.png", [L.outlined(hand)], 0, Vector2i(6, 6), {
		"note": "Luva velha da Fase 2 (fixa). Mesma arte e cores (r0/r1/r2 + punho encardido) das mãos do lutador e do cursor. Para caderno/inventário/ícone."})
	var frames := []
	for pressed in [false, true]:
		var g: Image = L.blank(10, 10)
		if pressed:
			L.glove2(g, 0, 1, 10, 9, gl)
		else:
			L.glove2(g, 0, 0, 10, 10, gl)
		var o1: Image = L.outlined(g, "white")
		var o2: Image = L.outlined(o1, "ink")
		frames.append(o2)
	save_sheet("cursor_glove", "ui/cursor_glove.png", frames, 0, Vector2i(7, 6), {
		"hotspot": [7, 6], "frames_note": "0 normal, 1 pressionado (luva achatada 1 px, enquanto o botão do mouse está apertado).",
		"note": "Cursor = a mesma luva do lutador, com contorno claro + ink. Recomendado: esconder o cursor do sistema sobre a sala e desenhar este sprite dentro do viewport (assim ele escala junto, 2x/3x). Se usar Input.set_custom_mouse_cursor, usar as versões _x2/_x3 (o cursor do sistema não escala)."})
	for s in [2, 3]:
		for i in 2:
			var b: Image = frames[i].duplicate()
			b.resize(b.get_width() * s, b.get_height() * s, Image.INTERPOLATE_NEAREST)
			var nm := "ui/cursor_glove_%s_x%d.png" % ["normal" if i == 0 else "pressed", s]
			b.save_png(OUT + nm)
			M["cursor_glove_%s_x%d" % ["normal" if i == 0 else "pressed", s]] = {"file": RES + nm,
				"frame_size": [b.get_width(), b.get_height()], "frames": 1, "fps": 0, "pivot": [7 * s, 6 * s],
				"hotspot": [7 * s, 6 * s], "note": "Cursor do sistema já ampliado %dx (Input.set_custom_mouse_cursor)." % s}

# ================================================================ efeitos
func make_fx() -> void:
	var frames := []
	var dirs := [V(1, -1), V(1, 1), V(1, 0), V(0, -1), V(0, 1), V(-1, -1), V(-1, 1)]
	var r0s := [2, 3, 6, 8]
	var r1s := [5, 8, 10, 11]
	var cols := ["white", "white", "cream", "g3"]
	for f in 4:
		var img: Image = L.blank(24, 24)
		for i in dirs.size():
			var d: Vector2 = dirs[i]
			if i >= 5 and f < 1:
				continue
			var a: Vector2 = V(12, 12) + d * (r0s[f] * (0.6 if i >= 5 else 1.0))
			var b: Vector2 = V(12, 12) + d * (r1s[f] * (0.6 if i >= 5 else 1.0))
			if f == 3:
				L.P(img, int(b.x), int(b.y), cols[f])
			else:
				L.line(img, int(a.x), int(a.y), int(b.x), int(b.y), cols[f])
		if f == 0:
			L.R(img, 11, 11, 2, 2, "y2"); L.P(img, 10, 11, "white"); L.P(img, 13, 12, "white")
		frames.append(img)
	save_sheet("fx_impact", "fx/fx_impact.png", frames, 15, Vector2i(12, 12), {
		"loop": false, "positions": {"saco": xy(P_FX_BAG)},
		"note": "Traços de impacto no ponto do golpe (sem contorno, brancos). Corda/esteira: usar fx_dust nos pés."})
	# faísca de crítico
	var cf := []
	for f in 4:
		var img: Image = L.blank(32, 32)
		var c := V(16, 16)
		if f == 0:
			L.ellipse(img, 16, 16, 4, 4, "y1"); L.ellipse(img, 16, 16, 2, 2, "y2")
		elif f == 1 or f == 2:
			var long := 11.0 if f == 1 else 14.0
			var short := 7.0 if f == 1 else 9.0
			var start := 0.0 if f == 1 else 6.0
			for k in 8:
				var ang := k * PI / 4.0
				var ln := long if k % 2 == 0 else short
				var d := V(cos(ang), sin(ang))
				var a := c + d * start
				var b := c + d * ln
				L.line(img, int(round(a.x)), int(round(a.y)), int(round(b.x)), int(round(b.y)), "y1" if f == 1 else "r3")
				L.P(img, int(round(b.x)), int(round(b.y)), "r3" if f == 1 else "y0")
			if f == 1:
				L.ellipse(img, 16, 16, 3.5, 3.5, "y2")
		else:
			for k in 8:
				var ang := k * PI / 4.0 + PI / 8.0
				var d := V(cos(ang), sin(ang))
				var b := c + d * 13.0
				L.P(img, int(round(b.x)), int(round(b.y)), "y1")
		cf.append(outline_in_place(img))
	save_sheet("fx_crit", "fx/fx_crit.png", cf, 15, Vector2i(16, 16), {
		"loop": false, "positions": {"saco": xy(P_FX_BAG)},
		"note": "Faísca de crítico (estrela que abre e some), por cima do fx_impact. Junto com o número 2x em r3 e '!'."})
	# poeira nos pés (corda e esteira)
	var df := []
	for f in 3:
		var img: Image = L.blank(24, 8)
		var rx := 5.0 + f * 3.0
		L.ellipse_dither(img, 12, 5, rx, 2.5, "g3" if f < 2 else "g2", f)
		if f < 2:
			L.ellipse_dither(img, 12, 5, rx - 2.0, 1.5, "cream", f + 1)
		df.append(img)
	save_sheet("fx_dust", "fx/fx_dust.png", df, 12, Vector2i(12, 6), {
		"loop": false, "positions": {"corda": xy(P_FIGHTER_ROPE), "esteira": xy(P_FIGHTER_TM)},
		"note": "Poeira nos pés ao aterrissar da corda / passada na esteira (o 'impacto' desses aparelhos)."})

# ================================================================ UI 9-slice
func make_ui() -> void:
	var p: Image = L.blank(12, 12)
	L.panel(p, 0, 0, 12, 12, "d1", "d2", "ink")
	save_sheet("ui_panel", "ui/ui_panel.png", [p], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 3},
		"note": "Painel principal (laterais, barra de baixo, HUD). StyleBoxTexture / NinePatchRect, axis_stretch = Tile ou Stretch (cor lisa, tanto faz)."})
	var cd: Image = L.blank(12, 12)
	L.panel(cd, 0, 0, 12, 12, "d2", "g0", "d1")
	save_sheet("ui_card", "ui/ui_card.png", [cd], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 3},
		"note": "Cartão dentro do painel (item de gerador/melhoria)."})
	var cdl: Image = L.blank(12, 12)
	L.panel(cdl, 0, 0, 12, 12, "d1", "d2", "d1")
	save_sheet("ui_card_dim", "ui/ui_card_dim.png", [cdl], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 3},
		"note": "Cartão apagado (item que ainda não dá para pagar, se a UI quiser diferenciar além do preço em r2)."})
	var states := {
		"normal": {"bg": "d2", "pressed": false, "flat": false},
		"hover": {"bg": "g0", "pressed": false, "flat": false},
		"pressed": {"bg": "d2", "pressed": true, "flat": false},
		"disabled": {"bg": "d1", "pressed": false, "flat": true},
		"focus_strength": {"bg": "r1", "pressed": false, "flat": false},
		"focus_agility": {"bg": "b1", "pressed": false, "flat": false},
		"focus_endurance": {"bg": "br2", "pressed": false, "flat": false},
	}
	for st in states:
		var s: Dictionary = states[st]
		var img: Image = L.blank(16, 17)
		var bg: String = s.bg
		var y0 := 1 if s.pressed else 0
		if not s.pressed and not s.flat:
			L.R(img, 1, 16, 15, 1, "ink")                 # sombra (botão "alto")
		L.R(img, 0, y0, 16, 16, "ink")
		L.R(img, 1, y0 + 1, 14, 14, bg)
		if s.pressed:
			L.R(img, 1, y0 + 1, 14, 1, L.shade(L.col(bg), -1))
		elif not s.flat:
			L.R(img, 1, 1, 14, 1, L.shade(L.col(bg), 1))
			L.R(img, 1, 13, 14, 2, L.shade(L.col(bg), -1))
		var mg := {"left": 2, "top": 3 if s.pressed else 2, "right": 2, "bottom": 3 if s.pressed else 4}
		var txt := {"normal": "white", "hover": "white", "pressed": "cream", "disabled": "g1",
			"focus_strength": "white", "focus_agility": "white", "focus_endurance": "y2"}
		save_sheet("ui_button_" + st, "ui/ui_button_%s.png" % st, [img], 0, Vector2i.ZERO, {"nine_slice": mg,
			"text_color": txt[st],
			"note": "Botão 9-slice. As margens já descem o texto 1 px no pressionado. Texto com sombra ink 1 px." + (" Foco selecionado (cor do atributo); a UI soma um sublinhado de 2 px na mesma cor." if st.begins_with("focus") else "")})
	# etiqueta de preço
	for nm in ["can", "cannot"]:
		var t: Image = L.blank(8, 9)
		L.R(t, 0, 0, 8, 9, "ink")
		L.R(t, 1, 1, 6, 7, "gr1" if nm == "can" else "d1")
		if nm == "can":
			L.R(t, 1, 1, 6, 1, "gr2")
		save_sheet("ui_price_" + nm, "ui/ui_price_%s.png" % nm, [t], 0, Vector2i.ZERO, {"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 2},
			"text_color": "y1" if nm == "can" else "r2", "note": "Etiqueta do preço em Treino: dá para pagar (texto y1) / não dá (texto r2)."})
	# barra de atributo
	var bb: Image = L.blank(6, 5)
	L.R(bb, 0, 0, 6, 5, "ink"); L.R(bb, 1, 1, 4, 3, "d2")
	save_sheet("ui_bar_bg", "ui/ui_bar_bg.png", [bb], 0, Vector2i.ZERO, {"nine_slice": {"left": 1, "top": 1, "right": 1, "bottom": 1},
		"note": "Fundo da barra de atributo (5 px de altura)."})
	for a in [["strength", "r2"], ["agility", "b2"], ["endurance", "y0"]]:
		var fb: Image = L.blank(3, 3)
		L.R(fb, 0, 0, 3, 3, a[1]); L.R(fb, 0, 0, 3, 1, L.shade(L.col(a[1]), 1))
		save_sheet("ui_bar_fill_" + a[0], "ui/ui_bar_fill_%s.png" % a[0], [fb], 0, Vector2i.ZERO, {"nine_slice": {"left": 1, "top": 1, "right": 1, "bottom": 1},
			"note": "Preenchimento da barra (esticar na horizontal dentro do ui_bar_bg, 1 px de borda)."})

# ================================================================ ícones
func make_icons() -> void:
	var b: Image = L.blank(9, 9)
	L.icon_bolt(b, 0, 0, "gr3")
	save_sheet("icon_treino", "ui/icon_treino.png", [outline_in_place(b)], 0, Vector2i.ZERO, {"note": "Ícone de Treino (HUD), 9x9."})
	var s: Image = L.blank(9, 9)
	L.glove2(s, 1, 1, 7, 7, ["r0", "r1", "r2"], false)
	save_sheet("icon_strength", "ui/icon_strength.png", [outline_in_place(s)], 0, Vector2i.ZERO, {"note": "Força (luvinha), 9x9."})
	var a: Image = L.blank(9, 9)
	for i in 2:
		L.line(a, 1 + i * 3, 1, 4 + i * 3, 4, "b3"); L.line(a, 4 + i * 3, 4, 1 + i * 3, 7, "b2")
	save_sheet("icon_agility", "ui/icon_agility.png", [outline_in_place(a)], 0, Vector2i.ZERO, {"note": "Agilidade (setas), 9x9."})
	var e: Image = L.blank(9, 9)
	L.R(e, 1, 1, 7, 4, "y0"); L.R(e, 2, 5, 5, 1, "y0"); L.R(e, 3, 6, 3, 1, "y0"); L.P(e, 4, 7, "y0")
	L.R(e, 1, 1, 7, 1, "y1"); L.R(e, 4, 1, 1, 6, "y1")
	save_sheet("icon_endurance", "ui/icon_endurance.png", [outline_in_place(e)], 0, Vector2i.ZERO, {"note": "Resistência (escudo), 9x9."})
	# retratos 16x16 recortados dos próprios personagens
	for d in [["icon_neighbor", "neighbor_1", false], ["icon_uncle", "uncle_1", true]]:
		var fr: Image = F[d[1]][0]
		var src: Image = flip(fr) if d[2] else fr
		var face: Image = src.get_region(Rect2i(12, 2, 16, 16))
		save_sheet(d[0], "ui/%s.png" % d[0], [face], 0, Vector2i.ZERO, {"note": "Retrato 16x16 para o painel EQUIPE (recorte do sprite %s)." % d[1]})
	# aparelhos 16x16 (melhorias)
	var ib: Image = L.blank(16, 16)
	L.R(ib, 7, 1, 2, 3, "g2"); L.rrect(ib, 4, 3, 8, 11, "r1"); L.R(ib, 4, 4, 2, 9, "r0"); L.R(ib, 9, 4, 1, 8, "r2")
	L.R(ib, 4, 6, 8, 2, "g3"); L.R(ib, 4, 10, 8, 1, "g3")
	save_sheet("icon_bag", "ui/icon_bag.png", [outline_in_place(ib)], 0, Vector2i.ZERO, {"note": "Ícone da linha de melhorias do saco, 16x16."})
	var ir: Image = L.blank(16, 16)
	L.ring(ir, 8, 7, 5, 6, 1, "cream"); L.R(ir, 3, 11, 2, 4, "br2"); L.R(ir, 11, 11, 2, 4, "br2")
	save_sheet("icon_rope", "ui/icon_rope.png", [outline_in_place(ir)], 0, Vector2i.ZERO, {"note": "Ícone da linha de melhorias da corda, 16x16."})
	var it: Image = L.blank(16, 16)
	L.R(it, 2, 11, 12, 2, "d1"); L.R(it, 2, 13, 12, 1, "st1"); L.line(it, 4, 11, 2, 4, "st2"); L.R(it, 1, 2, 5, 3, "st0")
	L.R(it, 2, 3, 2, 1, "gr2"); L.R(it, 3, 14, 1, 1, "d2"); L.R(it, 12, 14, 1, 1, "d2")
	save_sheet("icon_treadmill", "ui/icon_treadmill.png", [outline_in_place(it)], 0, Vector2i.ZERO, {"note": "Ícone da linha de melhorias da esteira, 16x16."})

# ================================================================ fonte bitmap (BMFont)
func make_font() -> void:
	var chars := [" "]
	for k in L.GLYPHS:
		chars.append(k)
	for k in L.ACCENTS:
		chars.append(k)
	chars.sort_custom(func(a, b): return a.unicode_at(0) < b.unicode_at(0))
	var dir := OUT + "font/"
	DirAccess.make_dir_recursive_absolute(dir)
	for variant in ["fightclicker_5x7", "fightclicker_5x7_contorno"]:
		var outline: bool = variant.ends_with("contorno")
		var pad := 1 if outline else 0
		var cell_h := 11 + (3 if outline else 0)
		var cols := 16
		var rows := int(ceil(chars.size() / float(cols)))
		var atlas: Image = L.blank(cols * 8, rows * 14)
		var lines := []
		for i in chars.size():
			var ch: String = chars[i]
			var w: int = L.glyph_w(ch)
			var sx := (i % cols) * 8
			var sy := (i / cols) * 14
			if ch != " ":
				var rows_d: Dictionary = L._glyph_rows(ch)
				if outline:
					for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0),
							Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]:
						_glyph_draw(atlas, rows_d, sx + pad + d.x, sy + pad + d.y, "ink")
				_glyph_draw(atlas, rows_d, sx + pad, sy + pad, "white")
			lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=%d yoffset=%d xadvance=%d page=0 chnl=15" % [
				ch.unicode_at(0), sx, sy, w + 2 * pad + (1 if outline else 0), cell_h, -pad, -pad, w + 1])
		atlas.save_png(dir + variant + ".png")
		var txt := "info face=\"Fightclicker 5x7%s\" size=11 bold=0 italic=0 charset=\"\" unicode=1 stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=1,1 outline=0\n" % (" contorno" if outline else "")
		txt += "common lineHeight=12 base=9 scaleW=%d scaleH=%d pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0\n" % [atlas.get_width(), atlas.get_height()]
		txt += "page id=0 file=\"%s.png\"\n" % variant
		txt += "chars count=%d\n" % chars.size()
		txt += "\n".join(lines) + "\n"
		txt += "kernings count=0\n"
		var fa := FileAccess.open(dir + variant + ".fnt", FileAccess.WRITE)
		fa.store_string(txt)
		fa.close()
		M["font_" + variant] = {"file": RES + "font/" + variant + ".fnt", "atlas": RES + "font/" + variant + ".png",
			"font_size": 11, "line_height": 12, "cap_height": 7, "glyphs": chars.size(),
			"note": ("Fonte bitmap 5x7 com contorno ink já desenhado (números flutuantes sobre a sala). Cor do texto = modulate/font_color (só o miolo branco muda)." if outline else
				"Fonte bitmap 5x7: A-Z, a-z, 0-9, pontuação e acentos do português (ÁÀÂÃÉÊÍÓÔÕÚÇ e minúsculas). Usar font_size = 11 (tamanho nativo) ou 22 para 2x. Sombra: font_shadow_color = ink, offset (0,1).")}
		SHEETS.append(["font/" + variant, atlas, atlas.get_width()])

func _glyph_draw(img: Image, rows_d: Dictionary, x: int, y: int, c) -> void:
	for row in rows_d:
		var s: String = rows_d[row]
		for j in s.length():
			if s[j] == "#":
				L.P(img, x + j, y + int(row) + 2, c)

# ================================================================ manifest
func write_manifest() -> void:
	var doc := {
		"_sobre": "Sprites PLACEHOLDER da Fase 2 (garagem), gerados por tools/art/make_sprites_fase2.gd. Tudo 1x na resolução base 640x360, filtro nearest. Folhas = quadros lado a lado, da esquerda para a direita.",
		"_como_usar": "Sprite2D/AnimatedSprite2D com centered=false e offset = -pivot; position = posição na sala (coordenadas da tela base 640x360). Ordem de desenho: pelo y dos pés (sort_y = pos.y, ou pos.y + sort_y_offset nos sacos pendurados). Nunca escalar por fator não-inteiro nem rodar.",
		"base_resolution": [640, 360],
		"room_rect": [P_ROOM.x, P_ROOM.y, 384, 272],
		"click_area": [CLICK_AREA.position.x, CLICK_AREA.position.y, CLICK_AREA.size.x, CLICK_AREA.size.y],
		"layout": {
			"_regra": "O aparelho em foco vai para o CENTRO; o ponto de clique não muda. Os outros ficam no lugar de descanso.",
			"foco_saco": {"saco": "bag_lN_idle/hit em centro", "corda": "rope_lN_idle no prego", "esteira": "treadmill_lN_side em lado_direito", "lutador": "fighter_idle/punch em foco_saco"},
			"foco_corda": {"saco": "bag_lN_side em lado_esquerdo", "corda": "fighter_rope + rope_lN_swing em foco_corda (prego fica vazio)", "esteira": "treadmill_lN_side em lado_direito", "lutador": "fighter_idle/rope em foco_corda"},
			"foco_esteira": {"saco": "bag_lN_side em lado_esquerdo", "corda": "rope_lN_idle no prego", "esteira": "treadmill_lN_idle/run em centro", "lutador": "fighter_run em foco_esteira (desenhado depois da esteira)"},
			"nivel_visual": "N = maior visual_level comprado do aparelho (0 ou 1). Nível 2 da melhoria não troca sprite.",
			"pessoas": {"neighbor_kid": ["neighbor_1 (qtd >= 1)", "neighbor_2 (qtd >= 10)", "neighbor_3 (qtd >= 25)"],
				"retired_uncle": ["uncle_1 (qtd >= 1)", "uncle_2 (qtd >= 10)"],
				"_nota": "Pontos fixos, nunca cobrem o alvo central nem os aparelhos do centro. Cada uma com floor_shadow nos pés."},
			"chain": "bag_chain_tile repetido de y=%d até o pivô do saco, em x = pivô.x - 1" % BEAM_BOTTOM,
		},
		"by_data_id": {
			"_nota": "Ponte entre os ids de data/ (docs/fases/fase2-api.md) e os sprites. N = GameState.nivel_visual(aparelho).",
			"punching_bag": {"idle": "bag_lN_idle", "click": "bag_lN_hit", "side": "bag_lN_side", "fighter": "fighter_punch", "fx": "fx_impact", "icon": "icon_bag", "foco": "foco_saco", "attribute": "strength"},
			"jump_rope": {"idle": "rope_lN_idle", "click": "rope_lN_swing", "fighter": "fighter_rope", "fx": "fx_dust", "icon": "icon_rope", "foco": "foco_corda", "attribute": "agility"},
			"treadmill": {"idle": "treadmill_lN_idle", "click": "treadmill_lN_run", "side": "treadmill_lN_side", "fighter": "fighter_run", "fx": "fx_dust", "icon": "icon_treadmill", "foco": "foco_esteira", "attribute": "endurance"},
			"neighbor_kid": {"people": ["neighbor_1", "neighbor_2", "neighbor_3"], "icon": "icon_neighbor", "_nota": "pessoa i aparece se GameState.pessoas_desenhadas('neighbor_kid') > i"},
			"retired_uncle": {"people": ["uncle_1", "uncle_2"], "icon": "icon_uncle", "_nota": "pessoa i aparece se GameState.pessoas_desenhadas('retired_uncle') > i"},
			"strength": {"icon": "icon_strength", "bar": "ui_bar_fill_strength", "focus_button": "ui_button_focus_strength"},
			"agility": {"icon": "icon_agility", "bar": "ui_bar_fill_agility", "focus_button": "ui_button_focus_agility"},
			"endurance": {"icon": "icon_endurance", "bar": "ui_bar_fill_endurance", "focus_button": "ui_button_focus_endurance"},
		},
		"palette_swap_glove": {"r0": "#5a1a22", "r1": "#9c2a2a", "r2": "#d4473a",
			"_nota": "No lutador, só a luva usa vermelho. Uma luva nova = trocar essas 3 cores (shader de paleta) ou gerar folhas novas."},
		"sprites": M,
	}
	var fa := FileAccess.open(OUT + "manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()

# ================================================================ folha de contato
func make_contact_sheet() -> void:
	var S := 3
	var W := 2400
	var gap := 18
	var x := gap
	var y := 50
	var row_h := 0
	var places := []
	for e in SHEETS:
		var img: Image = e[1]
		var w: int = img.get_width() * S
		var h: int = img.get_height() * S + 22
		if x + w > W - gap:
			x = gap
			y += row_h + gap
			row_h = 0
		places.append([e, Vector2i(x, y)])
		x += maxi(w, L.text_w(str(e[0]), 2)) + gap
		row_h = maxi(row_h, h)
	var H := y + row_h + gap
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "FIGHTCLICKER - FASE 2 - SPRITES PLACEHOLDER (x3)", gap, 14, "y1", 3, "ink")
	for pl in places:
		var e: Array = pl[0]
		var p: Vector2i = pl[1]
		var img: Image = e[1]
		var fw: int = e[2]
		L.text(out, str(e[0]), p.x, p.y, "cream", 2, "ink")
		var big: Image = img.duplicate()
		big.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
		var oy := p.y + 20
		# xadrez para mostrar a transparência
		for yy in range(0, big.get_height(), 6):
			for xx in range(0, big.get_width(), 6):
				L.R(out, p.x + xx, oy + yy, mini(6, big.get_width() - xx), mini(6, big.get_height() - yy), "d2" if ((xx + yy) / 6) % 2 == 0 else "g0")
		out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(p.x, oy))
		var nf := img.get_width() / fw
		for i in range(1, nf):
			L.R(out, p.x + i * fw * S, oy, 1, big.get_height(), "y0")
	out.save_png(MOCK + "fase2_sprites_x3.png")

# ================================================================ sala de conferência (monta com os sprites e as posições do manifest)
func put(items: Array, id: String, frame: int, pos: Vector2i, sort_y: int) -> void:
	var fr: Image = F[id][frame]
	var pv: Array = M[id].pivot
	items.append([sort_y, fr, pos - Vector2i(pv[0], pv[1])])

func compose(focus: String, lv: int, frame: int) -> Image:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	img.blit_rect(F.garage_bg[0], Rect2i(0, 0, 384, 272), P_ROOM)
	var items := []
	put(items, "lamp", 0, P_LAMP, -50)
	var bag_pos := P_BAG_CENTER if focus == "bag" else P_BAG_LEFT
	for yy in range(BEAM_BOTTOM, bag_pos.y, 6):
		items.append([-45, F.bag_chain_tile[0], Vector2i(bag_pos.x - 1, yy)])
	if focus == "bag":
		put(items, "bag_l%d_hit" % lv, frame, bag_pos, bag_pos.y + 70)
	else:
		put(items, "bag_l%d_side" % lv, 0, bag_pos, bag_pos.y + 70)
	if focus != "rope":
		put(items, "rope_l%d_idle" % lv, 0, P_ROPE_NAIL, -40)
	if focus == "treadmill":
		put(items, "treadmill_l%d_run" % lv, frame, P_TM_CENTER, P_TM_CENTER.y)
		put(items, "floor_shadow", 0, P_FIGHTER_TM + Vector2i(0, -1), P_TM_CENTER.y + 1)
		put(items, "fighter_run", frame, P_FIGHTER_TM, P_TM_CENTER.y + 2)
	else:
		put(items, "treadmill_l%d_side" % lv, 0, P_TM_RIGHT, P_TM_RIGHT.y)
	if focus == "bag":
		put(items, "floor_shadow", 0, P_FIGHTER_BAG + Vector2i(0, -1), P_FIGHTER_BAG.y - 1)
		put(items, "fighter_punch", 2 if frame == 0 else frame, P_FIGHTER_BAG, P_FIGHTER_BAG.y)
		put(items, "fx_impact", 1, P_FX_BAG, 999)
		if lv == 1:
			put(items, "fx_crit", 1, P_FX_BAG, 998)
	if focus == "rope":
		put(items, "floor_shadow", 0, P_FIGHTER_ROPE + Vector2i(0, -1), P_FIGHTER_ROPE.y - 1)
		put(items, "fighter_rope", frame, P_FIGHTER_ROPE, P_FIGHTER_ROPE.y)
		put(items, "rope_l%d_swing" % lv, frame, P_FIGHTER_ROPE, P_FIGHTER_ROPE.y + 1)
	for i in 3:
		put(items, "floor_shadow", 0, P_NEIGHBOR[i] + Vector2i(0, -1), P_NEIGHBOR[i].y - 1)
		put(items, "neighbor_%d" % (i + 1), (frame + i) % 4, P_NEIGHBOR[i], P_NEIGHBOR[i].y)
	for i in 2:
		put(items, "floor_shadow", 0, P_UNCLE[i] + Vector2i(0, -1), P_UNCLE[i].y - 1)
		put(items, "uncle_%d" % (i + 1), (frame + i) % 4, P_UNCLE[i], P_UNCLE[i].y)
	put(items, "cursor_glove", 0, CLICK_AREA.position + Vector2i(30, 50), 1000)
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		var fr: Image = it[1]
		img.blend_rect(fr, Rect2i(Vector2i.ZERO, fr.get_size()), it[2])
	return img.get_region(Rect2i(P_ROOM, Vector2i(384, 272)))

func make_room_check() -> void:
	var S := 2
	var cw := 384 * S
	var chh := 272 * S
	var gap := 12
	var out: Image = L.blank(gap + 3 * (cw + gap), 40 + 2 * (chh + 34))
	L.R(out, 0, 0, out.get_width(), out.get_height(), "d1")
	L.text(out, "FASE 2 - SALA MONTADA COM OS SPRITES E AS POSIÇÕES DO MANIFEST (x2)", gap, 10, "y1", 2, "ink")
	var focs := [["bag", "FOCO SACO", 0], ["rope", "FOCO CORDA", 2], ["treadmill", "FOCO ESTEIRA", 1]]
	for lv in 2:
		for i in 3:
			var fc: Array = focs[i]
			var room := compose(fc[0], lv, fc[2])
			room.resize(cw, chh, Image.INTERPOLATE_NEAREST)
			var px := gap + i * (cw + gap)
			var py := 40 + lv * (chh + 34)
			L.text(out, "%s - NÍVEL VISUAL %d" % [fc[1], lv], px, py, "cream", 2, "ink")
			out.blit_rect(room, Rect2i(Vector2i.ZERO, room.get_size()), Vector2i(px, py + 18))
			# área de clique
			var ca := Rect2i((CLICK_AREA.position - P_ROOM) * S + Vector2i(px, py + 18), CLICK_AREA.size * S)
			for xx in range(ca.position.x, ca.end.x, 4):
				L.P(out, xx, ca.position.y, "gr3"); L.P(out, xx, ca.end.y - 1, "gr3")
			for yy in range(ca.position.y, ca.end.y, 4):
				L.P(out, ca.position.x, yy, "gr3"); L.P(out, ca.end.x - 1, yy, "gr3")
	out.save_png(MOCK + "fase2_sala_x2.png")
