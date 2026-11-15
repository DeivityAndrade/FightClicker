extends SceneTree
## Fase 6b1 "Passar o posto" (Diretor de Arte) - PLACEHOLDER gerado por código. Cenário da cena da sucessão.
## (Gente - John, discípulo - é do Artista de Personagens. As poses que aparecem nos mockups são rascunho da prancha.)
##   garage/garage_door (84x56, 9 quadros)       porta de enrolar: fechada, fresta, 1/3, emperrada (borda em y 171)
##   garage/garage_door_outside (82x52)          o lado de fora visto pelo vão (luz do dia branca, calçada)
##   garage/garage_daylight (170x70, 3 quadros)  luz do dia no chão (o próprio chão 1 passo mais claro)
##   garage/garage_door_shadow (64x32, 4)        sombra dos pés na fresta e sombra comprida de quem entra
##   garage/garage_crate (26x19)                 caixote de madeira do mentor
##   garage/garage_hung_gloves_old (20x34, 4)    o par do John pendurado na argola do saco
##   docs/arte/mockups/fase6b1_garagem_*.png
## Rodar de uma pasta temporária com project.godot vazio:
##   Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_cenario_fase6b1.gd -- [--final]
## Sem --final grava em <tmp>/out (prévia). Com --final grava no projeto e mexe no manifest SÓ nas chaves desta
## fase (relê o arquivo na hora de gravar) e junta docs/arte/manifest-6b1-personagens.json, se existir.

const ROOT := "E:/Fightclicker/"
const RES := "res://assets/sprites/"
var OUT := ""
var MOCK := ""
var FINAL := false
var L
var P
var OLD := {}
var M := {}
var F := {}

const LIGHT_C := Vector2(305, 90)
const GPIV := Vector2i(22, 67)
# porta de enrolar pintada no garage_bg: trilhos x 380..381 e 464..465, lâminas x 382..463 (período 8 px), fresta de luz y 218..219
const DOOR_POS := Vector2i(381, 166)
const DOOR_SIZE := Vector2i(84, 68)
const DOOR_PIV := Vector2i(0, 12)          # pos (381,166) continua; o quadro sobe 12 px para cobrir a cabeça de quem está na soleira
const DOOR_TOP := 154
const DOOR_EDGES := [-1, 216, 209, 201, 193, 185, 178, 172, 171]   # -1 = fechada (igual ao fundo)
const OUTSIDE_POS := Vector2i(382, 168)
const OUTSIDE_SIZE := Vector2i(82, 52)
const DAY_POS := Vector2i(308, 220)
const DAY_SIZE := Vector2i(170, 70)
const SHADOW_POS := Vector2i(374, 214)
const SHADOW_SIZE := Vector2i(64, 32)
const RING := Vector2i(335, 186)
const GLOVES_PIV := Vector2i(17, 1)
# ---- pontos (decisão do Diretor de Arte, 6b1: ver direcao-visual.md §23.4)
const P_MENTOR := Vector2i(254, 252)          # pés do John sentado (era 268,268 na prancha)
const CRATE_OFF := Vector2i(-16, -20)         # canto de cima à esquerda do caixote em relação ao mentor_spot
const P_ROPE_BOX := Vector2i(424, 287)        # caixa da corda (era 258,244)
const P_JOHN := Vector2i(303, 272)
const P_COACH := Vector2i(196, 236)
const TARGET_X := [281, 362]

# ================================================================ util
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

func spr(id: String) -> Dictionary:
	if M.has(id):
		return M[id]
	return OLD.get("sprites", {}).get(id, {})

func load_abs(p: String) -> Image:
	var img := Image.load_from_file(p)
	img.convert(Image.FORMAT_RGBA8)
	return img

func frame_of(id: String, i := 0) -> Image:
	if F.has(id):
		return F[id][clampi(i, 0, F[id].size() - 1)]
	var e := spr(id)
	var img := load_abs(ROOT + str(e.file).replace("res://", ""))
	var fw: int = int(e.frame_size[0])
	var fh: int = int(e.frame_size[1])
	i = clampi(i, 0, int(e.frames) - 1)
	return img.get_region(Rect2i(i * fw, 0, fw, fh))

func blend(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func put(dst: Image, id: String, i: int, x: int, y: int) -> void:
	blend(dst, frame_of(id, i), x, y)

func put_pv(dst: Image, id: String, i: int, pos: Vector2i) -> void:
	var e := spr(id)
	put(dst, id, i, pos.x - int(e.pivot[0]), pos.y - int(e.pivot[1]))

func scaled(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func lit(img: Image, topleft: Vector2i, min_step := -2) -> Image:
	var c: Image = img.duplicate()
	L.light(c, Rect2i(0, 0, c.get_width(), c.get_height()), LIGHT_C - Vector2(topleft), 300.0, 1.1, 3.6, min_step, 1, 0.9)
	return c

func bg_px(x: int, y: int) -> Color:
	return BG.get_pixel(x - 128, y - 18)

var BG: Image

## limiar de Bayer 4x4 (0..1)
func bayer(x: int, y: int) -> float:
	return (float(L.BAYER[y & 3][x & 3]) + 0.5) / 16.0

# ================================================================ porta
func door_frame(i: int) -> Image:
	var img: Image = L.blank(DOOR_SIZE.x, DOOR_SIZE.y)
	var edge: int = DOOR_EDGES[i]
	if edge < 0:
		img.blit_rect(BG, Rect2i(DOOR_POS.x - 128, DOOR_TOP - 18, DOOR_SIZE.x, DOOR_SIZE.y), Vector2i.ZERO)
		return img
	var x0 := DOOR_POS.x
	# lâminas: textura do fundo no mesmo y (o rolo esconde em cima; parado por cima evita costura em y 166)
	for y in range(DOOR_TOP, edge - 3):
		for x in range(x0, x0 + DOOR_SIZE.x):
			var sy := y
			if y >= 205:   # linhas de baixo do fundo têm o puxador e a ferrugem da borda: usa a lâmina limpa 8 px acima
				sy = y - 8 * int(ceil((y - 204) / 8.0))
			img.set_pixel(x - x0, y - DOOR_TOP, bg_px(x, sy))
	# puxador (anda com a borda): 9x2 ink + brilho st2, logo acima da barra
	var hy := edge - 6
	if hy >= DOOR_TOP:
		L.R(img, 418 - x0, hy - DOOR_TOP, 9, 2, "ink")
		L.R(img, 419 - x0, hy - DOOR_TOP, 7, 1, "st2")
	# barra de baixo (3 px st0, passa 1 px de cada lado do miolo) + linha ink da borda
	L.R(img, 0, edge - 3 - DOOR_TOP, DOOR_SIZE.x, 3, "st0")
	L.R(img, 0, edge - 3 - DOOR_TOP, DOOR_SIZE.x, 1, "st1")
	L.R(img, 36, edge - 2 - DOOR_TOP, 10, 1, "st2")
	L.R(img, 0, edge - DOOR_TOP, DOOR_SIZE.x, 1, "ink")
	# borda de borracha gasta: 3 falhas de 1 px no ink (lê como uso, não como furo)
	for fx in [12, 47, 70]:
		L.P(img, fx, edge - DOOR_TOP, "d1")
	return lit_door(img)

## a barra/puxador novos recebem a mesma luz da lâmpada que o fundo já tem nas lâminas
func lit_door(img: Image) -> Image:
	return img

# ================================================================ lado de fora
func outside() -> Image:
	var img: Image = L.blank(OUTSIDE_SIZE.x, OUTSIDE_SIZE.y)
	var w := OUTSIDE_SIZE.x
	# céu/claridade branca: dia claro (escolha A do dono), sem amarelo da lâmpada
	L.R(img, 0, 0, w, 52, "white")
	# a luz baixa: y2 em dither (Bayer) do local 14 ao 24, sólido abaixo
	for y in range(14, 45):
		for x in w:
			var t := clampf(float(y - 14) / 10.0, 0.0, 1.0)
			if bayer(x, y) < t:
				img.set_pixel(x, y, L.col("y2"))
	# muro do outro lado da rua (cream claro, 1 faixa) para o vão não parecer vazio
	L.R(img, 0, 30, w, 1, "cream")
	for x in range(0, w, 2):
		L.P(img, x, 31, "cream")
	# calçada cream de 7 px (y 213..219 = local 45..51), meio-fio g3, juntas a cada 16 px
	for x in w:
		if (x + 43) % 2 == 0:
			L.P(img, x, 43, "cream")
		L.P(img, x, 44, "cream")
	L.R(img, 0, 45, w, 7, "cream")
	L.R(img, 0, 45, w, 1, "g3")
	for x in range(5, w, 16):
		L.R(img, x, 46, 1, 6, "g3")
	return img

# ================================================================ luz do dia no chão
## n passos na rampa dentro do trapézio; borda em dither ordenado de 'borda' px
func light_mask(m: Dictionary, y0: int, y1: int, xl0: float, xr0: float, xl1: float, xr1: float, borda: int, n: int) -> void:
	for y in range(y0, y1 + 1):
		var t := 0.0 if y1 == y0 else float(y - y0) / float(y1 - y0)
		var a := int(round(lerpf(xl0, xl1, t)))
		var b := int(round(lerpf(xr0, xr1, t)))
		for x in range(a, b + 1):
			var d := mini(mini(x - a, b - x), (y1 - y) * 2)
			if d < borda and bayer(x, y) > float(d + 1) / float(borda + 1):
				continue
			var k := Vector2i(x, y)
			m[k] = maxi(int(m.get(k, 0)), n)

const DAY_TRAP := [   # [y0, y1, xl0, xr0, xl1, xr1, borda] por quadro; 2º trapézio = miolo (+1 passo)
	[[220, 236, 380, 465, 366, 467, 5]],
	[[220, 262, 380, 465, 336, 472, 6], [220, 244, 388, 457, 372, 460, 6]],
	[[220, 289, 380, 465, 308, 477, 7], [220, 262, 388, 457, 356, 461, 6]]]

func day_mask(i: int) -> Dictionary:
	var m := {}
	var tr: Array = DAY_TRAP[i]
	for j in tr.size():
		var q: Array = tr[j]
		light_mask(m, q[0], q[1], q[2], q[3], q[4], q[5], q[6], j + 1)
	return m

func daylight(i: int) -> Image:
	var img: Image = L.blank(DAY_SIZE.x, DAY_SIZE.y)
	var m := day_mask(i)
	for k in m:
		var p: Vector2i = k
		var lx := p.x - DAY_POS.x
		var ly := p.y - DAY_POS.y
		if lx < 0 or ly < 0 or lx >= DAY_SIZE.x or ly >= DAY_SIZE.y:
			continue
		img.set_pixel(lx, ly, L.shade(bg_px(p.x, p.y), int(m[k])))
	return img

## chão já com a luz do quadro q (para assar a sombra por cima)
func floor_lit(x: int, y: int, q: int) -> Color:
	var c := bg_px(x, y)
	var d: Image = F["garage_daylight"][q]
	var lx := x - DAY_POS.x
	var ly := y - DAY_POS.y
	if lx >= 0 and ly >= 0 and lx < DAY_SIZE.x and ly < DAY_SIZE.y:
		var dc := d.get_pixel(lx, ly)
		if dc.a > 0.0:
			c = dc
	return c

# ================================================================ sombras de quem está na porta
func shadow_frame(i: int) -> Image:
	var img: Image = L.blank(SHADOW_SIZE.x, SHADOW_SIZE.y)
	var q := 0 if i == 0 else 2
	var marks := {}
	var strips := []   # [pé, comprimento]
	if i == 0:
		strips = [[Vector2i(415, 220), 14], [Vector2i(428, 220), 14]]
	else:
		strips = [[[Vector2i(423, 221), 34], [Vector2i(414, 228), 30], [Vector2i(410, 236), 16]][i - 1]]
	for s in strips:
		var pe: Vector2i = s[0]
		var comp: int = s[1]
		for k in comp:
			var x := pe.x - 4 - k
			var y := pe.y + 1 + k / 2
			for w in 9:
				var fade := k > comp - 8
				if fade and bayer(x + w, y) < float(k - (comp - 8)) / 8.0:
					continue
				if (w == 0 or w == 8) and (x + w + y) % 2 == 0:
					continue    # borda lateral em dither
				marks[Vector2i(x + w, y)] = true
	for k in marks:
		var p: Vector2i = k
		var lx := p.x - SHADOW_POS.x
		var ly := p.y - SHADOW_POS.y
		if lx >= 0 and ly >= 0 and lx < SHADOW_SIZE.x and ly < SHADOW_SIZE.y:
			img.set_pixel(lx, ly, L.shade(floor_lit(p.x, p.y, q), -1))
	if i == 0:
		for fx in [412, 425]:
			L.R(img, fx - SHADOW_POS.x, 216 - SHADOW_POS.y, 7, 4, "d1")
			L.R(img, fx - SHADOW_POS.x, 216 - SHADOW_POS.y, 7, 1, "ink")   # bico do tênis contra a luz
	return img

# ================================================================ caixote
## Engradado de feira: 3 ripas horizontais com fresta escura (vê-se o vazio de dentro), 2 montantes,
## pregos, tampo de 2 ripas visto de cima. Não tem fita, etiqueta nem símbolo (≠ caixa de papelão da escola).
func crate() -> Image:
	var img: Image = L.blank(26, 19)
	# contorno
	L.R(img, 0, 0, 26, 18, "ink")
	# tampo (assento) visto de cima: y 1..3
	L.R(img, 1, 1, 24, 3, "br2")
	L.R(img, 1, 1, 24, 1, "br3")
	L.R(img, 13, 1, 1, 3, "br1")          # junta entre as 2 tábuas do tampo
	L.R(img, 1, 4, 24, 1, "br0")          # quina do tampo
	# frente: 3 ripas (y 5..7, 9..11, 13..15) com fresta em 8 e 12
	for ry in [5, 9, 13]:
		L.R(img, 1, ry, 24, 3, "br1")
		L.R(img, 1, ry, 24, 1, "br2")
	for gy in [8, 12]:
		L.R(img, 1, gy, 24, 1, "d1")
		for gx in range(3, 23, 3):
			L.P(img, gx, gy, "ink")        # vazio de dentro aparecendo
	L.R(img, 1, 16, 24, 1, "br0")
	# montantes dos cantos (por cima das ripas)
	for mx in [1, 22]:
		L.R(img, mx, 5, 3, 12, "br1")
		L.R(img, mx, 5, 1, 12, "br2")
		L.R(img, mx + 2, 5, 1, 12, "br0")
	# pregos
	for p in [[2, 6], [2, 14], [23, 6], [23, 14], [7, 2], [19, 2]]:
		L.P(img, p[0], p[1], "g2")
	# uma lasca e um veio para não ficar liso
	L.R(img, 9, 10, 4, 1, "br0")
	L.R(img, 15, 6, 3, 1, "br0")
	L.P(img, 24, 2, "br1")
	var out := lit(img, Vector2i(P_MENTOR) + CRATE_OFF, -2)
	# sombra de contato no chão (linha 18, dither ink), fora da luz
	for x in range(1, 26):
		if x % 2 == 1 or x > 18:
			out.set_pixel(x, 18, L.col("ink"))
	return out

# ================================================================ luvas penduradas
func hung_gloves(i: int) -> Image:
	var img: Image = L.blank(20, 34)
	var offs := [Vector2i(-1, -4), Vector2i(-1, 0), Vector2i(1, -1), Vector2i(0, 0)]   # o quadro tem 20 px: a esquerda só cabe 1 px
	var o: Vector2i = offs[i]
	var c1 := Vector2i(7, 21) + o
	var c2 := Vector2i(13, 26) + o
	var g: Image = frame_of("glove_old")
	# cadarço: da argola até o punho de cada luva (cream na frente, g3 atrás)
	L.line(img, GLOVES_PIV.x, GLOVES_PIV.y, c2.x + 1, c2.y - 6, "g3")
	blend(img, g, c1.x - 6, c1.y - 6)
	L.line(img, GLOVES_PIV.x, GLOVES_PIV.y, c1.x + 2, c1.y - 6, "cream")
	blend(img, g, c2.x - 6, c2.y - 6)
	L.P(img, GLOVES_PIV.x, GLOVES_PIV.y, "cream")
	L.P(img, GLOVES_PIV.x - 1, GLOVES_PIV.y + 1, "cream")   # nó na argola
	return lit(img, RING - GLOVES_PIV, -1)

# ================================================================ mockups
var PJ = null
var b_john_bare
var b_disc_bare

func gpose(o: Dictionary) -> Dictionary:
	var p := {"hip": Vector2(0, -31), "top": Vector2(1, -50), "head": Vector2(1, -57), "sl": Vector2(-7, -47), "sr": Vector2(8, -47),
		"hl": Vector2(-8, -50), "hr": Vector2(10, -51), "toel": Vector2(-1, 0), "toer": Vector2(10, 0)}
	for k in o:
		p[k] = o[k]
	return p

const BARE := {"hl": Vector2(-9, -28), "hr": Vector2(11, -28), "gkl": "", "gkr": ""}

## pose do John sentado: folha do Artista se já existir, senão o rascunho da prancha
func john_sit() -> Image:
	if spr("john_sit_rest").has("file") and FileAccess.file_exists(ROOT + str(spr("john_sit_rest").file).replace("res://", "")):
		return frame_of("john_sit_rest", 0)
	var o := {"hip": Vector2(0, -18), "top": Vector2(3, -36), "head": Vector2(5, -43), "sl": Vector2(-5, -33), "sr": Vector2(10, -33),
		"hl": Vector2(2, -19), "hr": Vector2(13, -20), "toel": Vector2(-3, 0), "toer": Vector2(12, 0), "kl": Vector2(1, -0.2), "kr": Vector2(1, -0.2),
		"gkl": "", "gkr": "", "face": "smile"}
	return lit(PJ.garage_frame(b_john_bare, gpose(o), "sit_rest"), P_MENTOR - GPIV, -1)

func john_look() -> Image:
	var o := BARE.duplicate()
	o["head"] = Vector2(2, -57)
	return lit(PJ.garage_frame(b_john_bare, gpose(o), "look_door"), P_JOHN - GPIV, -1)

func disc_stand() -> Image:
	var im: Image = L.flipped(PJ.garage_frame(b_disc_bare, gpose(BARE), "disc_stand"))
	L.shade_rect(im, 0, 0, im.get_width(), im.get_height(), -1)    # contra a luz
	return im

func coach(id: String) -> Image:
	return frame_of(id, 0)

## monta a sala: itens = [[sort_y, Image, canto sup. esq., sombra?]]
func room(door_q: int, day_q: int, shadow_q: int, outside_on: bool, items: Array, extras := {}) -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	blend(im, BG, 128, 18)
	for id in ["wall_notice_debt", "wall_form_blank", "wall_photo_old"]:
		var e := spr(id)
		put(im, id, 0, int(e.pos[0]), int(e.pos[1]))
	put_pv(im, "lamp", 0, Vector2i(300, 32))
	if extras.get("rope", false):
		put_pv(im, "rope_l0_idle", 0, Vector2i(296, 166))
	if outside_on:
		blend(im, F["garage_door_outside"][0], OUTSIDE_POS.x, OUTSIDE_POS.y)
	if day_q >= 0:
		blend(im, F["garage_daylight"][day_q], DAY_POS.x, DAY_POS.y)
	if shadow_q >= 0:
		blend(im, F["garage_door_shadow"][shadow_q], SHADOW_POS.x, SHADOW_POS.y)
	# corrente do saco
	var t: Image = frame_of("bag_chain_tile")
	var y := 33
	while y < 183:
		blend(im, t.get_region(Rect2i(0, 0, t.get_width(), mini(6, 183 - y))), 335, y)
		y += 6
	var all := items.duplicate()
	all.append([222.0, F["garage_door"][door_q], Vector2(DOOR_POS - DOOR_PIV), false])
	all.sort_custom(func(a, b): return a[0] < b[0])
	for it in all:
		if it.size() > 3 and it[3] is Vector2:
			put_pv(im, "floor_shadow", 0, Vector2i(it[3]))
		blend(im, it[1], int(it[2].x), int(it[2].y))
	return im

func it_g(img: Image, pos: Vector2i) -> Array:
	return [float(pos.y), img, Vector2(pos - GPIV), Vector2(pos + Vector2i(0, -1))]

func it_spr(id: String, q: int, pos: Vector2i, sort_y: float, shadow := false) -> Array:
	var e := spr(id)
	var pv := Vector2i(int(e.pivot[0]), int(e.pivot[1]))
	return [sort_y, frame_of(id, q), Vector2(pos - pv), Vector2(pos + Vector2i(0, -1)) if shadow else false]

func it_bag() -> Array:
	return it_spr("bag_l0_idle", 0, Vector2i(336, 183), 253.0)

func it_crate() -> Array:
	return [float(P_MENTOR.y - 2), F["garage_crate"][0], Vector2(P_MENTOR + CRATE_OFF), false]

func it_gloves(q: int) -> Array:
	return [254.0, F["garage_hung_gloves_old"][q], Vector2(RING - GLOVES_PIV), false]

func label(img: Image, s: String, x: int, y: int) -> void:
	L.text(img, s, x, y, "white", 1, "ink")

func crop2x(img: Image, r: Rect2i) -> Image:
	return scaled(img.get_region(r), 2)

func make_mockups() -> void:
	DirAccess.make_dir_recursive_absolute(MOCK)
	var look := john_look()
	# ---- 1) porta nos 3 estados (recorte da direita da sala, 2x)
	var states := [
		[room(0, -1, -1, false, [it_bag(), it_g(look, P_JOHN), it_g(coach("coach_look"), P_COACH)]), "FECHADA (QUADRO 0)"],
		[room(1, 0, 0, true, [it_bag(), it_gloves(3), it_g(look, P_JOHN), it_g(coach("coach_look"), P_COACH)]), "FRESTA (QUADRO 1) + PÉS"],
		[room(8, 2, 1, true, [it_bag(), it_gloves(3), it_g(look, P_JOHN), it_g(coach("coach_look"), P_COACH),
			it_g(disc_stand(), Vector2i(423, 221))]), "EMPERRADA (QUADRO 8) + LUZ"]]
	var reg := Rect2i(232, 90, 270, 200)
	var sheet: Image = L.blank(reg.size.x * 2 * 3 + 40, reg.size.y * 2 + 40)
	L.R(sheet, 0, 0, sheet.get_width(), sheet.get_height(), "d1")
	for i in 3:
		var c := crop2x(states[i][0], reg)
		blend(sheet, c, 10 + i * (reg.size.x * 2 + 10), 26)
		label(sheet, states[i][1], 12 + i * (reg.size.x * 2 + 10), 10)
	sheet.save_png(MOCK + "fase6b1_garagem_porta_x2.png")
	for i in 3:
		(states[i][0] as Image).save_png(MOCK + "fase6b1_garagem_porta_%d_x1.png" % i)
	# ---- 2) caixote no lugar final: S10 (discípulo no saco, John sentado, porta fechada) com a equipe cheia e as 4 caixas
	var fighter := "fighter_idle_disc" if spr("fighter_idle_disc").has("file") else "fighter_idle"
	var crew := []
	for id in ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2"]:
		var e := spr(id)
		crew.append(it_spr(id, 0, Vector2i(int(e.pos[0]), int(e.pos[1])), float(e.pos[1]), true))
	var base_items := [it_bag(), it_crate(), it_g(john_sit(), P_MENTOR), it_g(coach("coach_idle"), P_COACH),
		it_spr(fighter, 0, P_JOHN, 272.0, true)]
	var full: Image = room(0, -1, -1, false, base_items + crew + [
		it_spr("box_small", 0, P_ROPE_BOX, float(P_ROPE_BOX.y)),
		it_spr("box_big", 0, Vector2i(445, 268), 268.0),
		it_spr("box_small", 0, Vector2i(204, 283), 283.0),
		it_spr("box_small", 0, Vector2i(386, 280), 280.0)], {"rope": false})
	full.save_png(MOCK + "fase6b1_garagem_caixote_x1.png")
	scaled(full.get_region(Rect2i(128, 18, 384, 272)), 2).save_png(MOCK + "fase6b1_garagem_caixote_x2.png")
	# ---- 3) conferência: zonas (alvo + folga, caixas, mentor), com os aparelhos de lado (foco na corda)
	var chk: Image = room(0, -1, -1, false, base_items + crew + [
		it_spr("box_small", 0, P_ROPE_BOX, float(P_ROPE_BOX.y)),
		it_spr("box_small", 0, Vector2i(386, 280), 280.0),
		it_spr("treadmill_l0_side", 0, Vector2i(445, 267), 267.0),
		it_spr("grappling_dummy_l0_rest", 0, Vector2i(228, 283), 270.0)], {"rope": true})
	dashed(chk, Rect2i(TARGET_X[0] - 8, 150, TARGET_X[1] - TARGET_X[0] + 17, 139), "r2")
	var sb := spr("box_small")
	var cr: Array = sb.click_rect
	dashed(chk, Rect2i(P_ROPE_BOX.x + int(cr[0]), P_ROPE_BOX.y + int(cr[1]), int(cr[2]), int(cr[3])), "y1")
	dashed(chk, Rect2i(258 + int(cr[0]), 244 + int(cr[1]), int(cr[2]), int(cr[3])), "g2")
	dashed(chk, mentor_rect(), "b3")
	scaled(chk.get_region(Rect2i(128, 18, 384, 272)), 2).save_png(MOCK + "fase6b1_garagem_conferencia_x2.png")
	# ---- 4) peças soltas em 3x
	var ids := ["garage_door", "garage_door_outside", "garage_daylight", "garage_door_shadow", "garage_crate", "garage_hung_gloves_old"]
	var w := 0
	var h := 0
	for id in ids:
		var st := strip(F[id])
		w = maxi(w, st.get_width() * 3 + 20)
		h += st.get_height() * 3 + 24
	var pcs: Image = L.blank(w, h + 10)
	L.R(pcs, 0, 0, w, h + 10, "g0")
	var yy := 6
	for id in ids:
		var st := strip(F[id])
		label(pcs, id, 10, yy)
		blend(pcs, scaled(st, 3), 10, yy + 12)
		yy += st.get_height() * 3 + 24
	pcs.save_png(MOCK + "fase6b1_garagem_pecas_x3.png")

## John sentado + caixote (caixa que ocupa no chão e na parede)
func mentor_rect() -> Rect2i:
	return Rect2i(P_MENTOR.x - 16, P_MENTOR.y - 52, 33, 53)

func dashed(img: Image, r: Rect2i, c: String) -> void:
	for x in range(r.position.x, r.end.x):
		if x % 4 < 2:
			L.P(img, x, r.position.y, c)
			L.P(img, x, r.end.y - 1, c)
	for y in range(r.position.y, r.end.y):
		if y % 4 < 2:
			L.P(img, r.position.x, y, c)
			L.P(img, r.end.x - 1, y, c)

# ================================================================ manifest
func intify(v):
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = v[k] if str(k) == "fps" else intify(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(intify(x))
		return a
	if v is float and is_equal_approx(v, roundf(v)) and absf(v) < 1e9:
		return int(v)
	return v

func write_manifest() -> void:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível na hora de gravar; nada foi escrito")
		return
	var doc: Dictionary = intify(j.data)
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 6b1") < 0:
		doc["_sobre"] = sobre + " Fase 6b1 (Diretor de Arte): porta de enrolar animada, lado de fora, luz do dia, sombra na porta, caixote do mentor, luvas penduradas, mentor_spot (direcao-visual.md §23)."
	var sp: Dictionary = doc.get("sprites", {})
	for id in M:
		sp[id] = intify(M[id])
	# personagens da 6b1 (Artista), se ele deixou as entradas
	var extra := ROOT + "docs/arte/manifest-6b1-personagens.json"
	var merged := []
	if FileAccess.file_exists(extra):
		var je := JSON.new()
		if je.parse(FileAccess.get_file_as_string(extra)) == OK and je.data is Dictionary:
			var src: Dictionary = je.data
			var sprites_in: Dictionary = src.get("sprites", src)
			for id in sprites_in:
				if str(id).begins_with("_"):
					continue
				sp[id] = intify(sprites_in[id])
				merged.append(id)
			var bdin: Dictionary = src.get("by_data_id", {})
			var bd0: Dictionary = doc.get("by_data_id", {})
			for k in bdin:
				bd0[k] = intify(bdin[k])
			doc["by_data_id"] = bd0
		else:
			push_error("manifest-6b1-personagens.json ilegível: não juntei")
	# Fase 6b2 (Artista): as mesmas entradas do discípulo com cortes, faixa, parte de cima e meião; vem depois da 6b1
	var extra2 := ROOT + "docs/arte/manifest-6b2-personagens.json"
	if FileAccess.file_exists(extra2):
		var j2 := JSON.new()
		if j2.parse(FileAccess.get_file_as_string(extra2)) == OK and j2.data is Dictionary:
			var s2: Dictionary = j2.data.get("sprites", {})
			for id in s2:
				sp[id] = intify(s2[id])
			var bd2: Dictionary = doc.get("by_data_id", {})
			var b2in: Dictionary = j2.data.get("by_data_id", {})
			for k in b2in:
				bd2[k] = intify(b2in[k])
			doc["by_data_id"] = bd2
		else:
			push_error("manifest-6b2-personagens.json ilegível: não juntei")
	doc["sprites"] = sp
	var lay: Dictionary = doc.get("layout", {})
	var bs: Dictionary = lay.get("box_slots", {})
	bs["jump_rope"] = [P_ROPE_BOX.x, P_ROPE_BOX.y]
	bs["_nota"] = str(bs.get("_nota", "")).split(" Fase 6b1:")[0].replace("A da corda fica no pé da parede, embaixo do gancho; a da luva na frente, à direita do alvo.", "A da luva e a da corda ficam na frente, à direita do alvo, lado a lado.") + " Fase 6b1: a caixa da corda saiu de (258,244) para (%d,%d), na frente, à direita da caixa da luva, para o John sentado no mentor_spot não tapar a caixa." % [P_ROPE_BOX.x, P_ROPE_BOX.y]
	lay["box_slots"] = bs
	lay["mentor_spot"] = [P_MENTOR.x, P_MENTOR.y]
	doc["layout"] = lay
	var bd: Dictionary = doc.get("by_data_id", {})
	if bd.has("unlock_jump_rope") and bd["unlock_jump_rope"] is Dictionary and bd["unlock_jump_rope"].has("box"):
		var uj: Dictionary = bd["unlock_jump_rope"]
		var bx: Dictionary = uj["box"]
		bx["pos"] = [P_ROPE_BOX.x, P_ROPE_BOX.y]
		uj["box"] = bx
		bd["unlock_jump_rope"] = uj
	bd["mentor_spot"] = {"pos": [P_MENTOR.x, P_MENTOR.y], "facing": "direita", "location": "garage",
		"crate": {"sprite": "garage_crate", "pos": [P_MENTOR.x + CRATE_OFF.x, P_MENTOR.y + CRATE_OFF.y], "layer": "sorted", "sort_y": P_MENTOR.y - 2},
		"pose": "sit_rest", "head_anchor_hint": [5, -51],
		"occupies": [P_MENTOR.x - 16, P_MENTOR.y - 52, 33, 53],
		"note": "Ponto dos pés do mentor sentado (6b1: John). Era (268,268) na prancha; mudou para (254,252) porque em 268 o John sentado entrava na faixa do alvo (x 281..362 com 8 px de folga = 273..370) e tapava a caixa da corda. Aqui ele fica encostado no fim do carro, olhando o saco, com a caixa ocupando x 238..270, y 200..252. A caixa da corda foi para (424,287), na frente à direita (6 px da caixa da luva; cobre 5 px da base da esteira encostada, que fica atrás pela ordem por y). Com foco na corda/esteira o saco de lado (lado_esquerdo 258,160) fica atrás da cabeça dele (ordem por y): aceito, como já era na prancha."}
	bd["garage_door_scene"] = {
		"door": {"sprite": "garage_door", "pos": [DOOR_POS.x, DOOR_POS.y], "pivot": [0, 12], "layer": "sorted", "sort_y": 222,
			"edge_y_by_frame": [219, 216, 209, 201, 193, 185, 178, 172, 171],
			"note": "Quadro 0 = fechada, igual ao garage_bg (opaco). Quadros 1..8: lâminas até a barra, barra st0 de 3 px e linha ink na borda; abaixo da borda é transparente (aparece o garage_door_outside). Quem está na soleira (y 221) fica atrás da porta (sort 222): a porta cobre dele de y 171 para cima no quadro 8."},
		"outside": {"sprite": "garage_door_outside", "pos": [OUTSIDE_POS.x, OUTSIDE_POS.y], "layer": "wall",
			"note": "Só visível com a porta aberta (quadros 1..8). Quem está lá fora contra a luz: desenhar 1 passo mais escuro (tom -1), como na prancha."},
		"daylight": {"sprite": "garage_daylight", "pos": [DAY_POS.x, DAY_POS.y], "layer": "floor", "frame_for_door": {"1": 0, "8": 2},
			"note": "Chão iluminado (o próprio garage_bg 1 passo mais claro; miolo perto da porta 2 passos), borda em dither ordenado, sem alpha parcial. Quadro 0 com a porta no quadro 1; quadro 2 com a porta emperrada."},
		"door_shadow": {"sprite": "garage_door_shadow", "pos": [SHADOW_POS.x, SHADOW_POS.y], "layer": "floor",
			"frames": {"0": "pés na fresta (porta no quadro 1, luz no quadro 0)", "1": "na soleira (423,221)", "2": "passando por baixo (414,228)", "3": "já dentro (410,236)"},
			"note": "Assada por cima da luz do dia (quadro 0 sobre a luz 0; quadros 1..3 sobre a luz 2): desenhar SEMPRE depois do garage_daylight."},
		"hung_gloves": {"sprite": "garage_hung_gloves_old", "pivot_at": [RING.x, RING.y], "layer": "sorted", "sort_y": 254,
			"note": "Pivô (17,1) = argola do saco. Se o saco balança (bag_l0_idle ±1 px), somar o mesmo deslocamento do saco. Some no grab_frame do take_gloves."},
		"draw_order": "fundo -> wall (door_outside) -> floor (daylight, depois door_shadow) -> sorted por sort_y/pés (porta 222, caixote, luvas 254, gente)",
		"_nota": "Fase 6b1 (Diretor de Arte). Valores dos tempos e da coreografia: data/cutscenes/primeira_sucessao.json (Diretor de Cutscenes)."}
	bd["_nota_fase6b1_arte"] = "Fase 6b1 (Diretor de Arte): garage_door_scene, mentor_spot, layout.mentor_spot, caixa da corda movida (layout.box_slots.jump_rope). Paletas do discípulo: docs/arte/paletas-6b1.md." + (" Juntadas do Artista: " + ", ".join(merged) if merged.size() > 0 else "")
	doc["by_data_id"] = bd
	var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()
	print("manifest: %d sprites da 6b1, %d juntados do Artista" % [M.size(), merged.size()])

# ================================================================ main
func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	PJ = load(ROOT + "tools/art/personagem_lib.gd").new(L)
	FINAL = OS.get_cmdline_user_args().has("--final")
	var here: String = ProjectSettings.globalize_path("res://")
	OUT = (ROOT + "assets/sprites/") if FINAL else (here.trim_suffix("/") + "/out/")
	MOCK = (ROOT + "docs/arte/mockups/") if FINAL else (here.trim_suffix("/") + "/out/mock/")
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível")
		quit()
		return
	OLD = j.data
	BG = frame_of("garage_bg")
	var oj: Dictionary = PJ.identidade("primeiro")
	oj["glove"] = "fist"
	b_john_bare = PJ.build(oj)
	var od: Dictionary = PJ.identidade("disc")
	od["glove"] = "fist"
	b_disc_bare = PJ.build(od)

	var doors := []
	for i in DOOR_EDGES.size():
		doors.append(door_frame(i))
	save_sheet("garage_door", "garage/garage_door.png", doors, 10, DOOR_PIV, {
		"pos": [DOOR_POS.x, DOOR_POS.y], "layer": "sorted", "sort_y": 222, "loop": false,
		"anim": {"closed": [0], "ajar": [1], "jammed": [8], "shake_ajar": [0, 1, 0, 1], "open_jam": [1, 2, 3, 4, 5, 6, 7, 8],
			"open_jam_fast": [1, 4, 8], "close": [8, 6, 4, 2, 1, 0]},
		"edge_y_by_frame": [219, 216, 209, 201, 193, 185, 178, 172, 171],
		"draw_at": "pos - pivot = (381,154)", "note": "Fase 6b1: porta de enrolar da garagem por cima da pintada no garage_bg. Quadro 84x68 com pivô (0,12): o pos (381,166) do pedido continua valendo, mas o quadro começa em y 154 para cobrir a cabeça de quem está na soleira (o discípulo em 423,221 tem o topo do quadro em y 154). 0 = fechada (recorte do fundo); 1 = fresta de 3 px; 4 = 1/3; 8 = emperrada na altura do ombro (borda ink em y 171). Lâminas paradas (o rolo recolhe em cima), barra st0 de 3 px e puxador andam com a borda; abaixo da borda é transparente."})
	save_sheet("garage_door_outside", "garage/garage_door_outside.png", [outside()], 0, Vector2i.ZERO, {
		"pos": [OUTSIDE_POS.x, OUTSIDE_POS.y], "layer": "wall",
		"note": "Fase 6b1: o lado de fora visto pelo vão da porta. Dia claro (escolha A do dono): branco em cima, passando a y2 em dither, muro cream do outro lado da rua, calçada cream de 7 px (y 213..219) com meio-fio g3. Só aparece com a porta aberta."})
	var days := []
	for i in 3:
		days.append(daylight(i))
	save_sheet("garage_daylight", "garage/garage_daylight.png", days, 10, Vector2i.ZERO, {
		"pos": [DAY_POS.x, DAY_POS.y], "layer": "floor", "loop": false,
		"anim": {"sliver": [0], "open": [0, 0, 0, 1, 1, 1, 2, 2], "open_fast": [0, 1, 2], "close": [2, 1, 1, 0, 0, 0]},
		"note": "Fase 6b1: luz do dia no chão. Recortada do garage_bg 1 passo mais clara na rampa (miolo junto à porta 2 passos), trapézio que abre para a esquerda e para a frente, borda em dither ordenado 4x4. 0 = fresta (y 220..236); 1 = meio (220..262); 2 = cheia (220..289, x 308..477 na base). As marcas do chão continuam (é o próprio chão)."})
	var shs := []
	for i in 4:
		shs.append(shadow_frame(i))
	save_sheet("garage_door_shadow", "garage/garage_door_shadow.png", shs, 0, Vector2i.ZERO, {
		"pos": [SHADOW_POS.x, SHADOW_POS.y], "layer": "floor",
		"note": "Fase 6b1: 0 = dois pés contra a luz na fresta (blocos d1 7x4 em x 412..418 e 425..431, y 216..219) e as sombras deles esticadas 14 px; 1 = sombra comprida de quem está na soleira, 34 px de (423,221); 2 = 30 px de (414,228); 3 = 16 px de (410,236). Para a esquerda e para a frente. Assada sobre a luz do dia: desenhar depois do garage_daylight."})
	save_sheet("garage_crate", "garage/garage_crate.png", [crate()], 0, Vector2i(-CRATE_OFF.x, -CRATE_OFF.y), {
		"pos": [P_MENTOR.x + CRATE_OFF.x, P_MENTOR.y + CRATE_OFF.y], "layer": "sorted", "sort_y": P_MENTOR.y - 2, "point": "mentor_spot",
		"note": "Fase 6b1: caixote de madeira do mentor (engradado de feira: ripas br1/br2 com fresta escura, montantes, pregos, tampo visto de cima). Assento a 17 px do chão. Pivô = mentor_spot (pés de quem senta). Luz da lâmpada aplicada para este ponto. Sem fita, etiqueta nem símbolo: não é a caixa de papelão da escola e não é clicável. Fica na garagem para sempre a partir da cena."})
	var gl := []
	for i in 4:
		gl.append(hung_gloves(i))
	save_sheet("garage_hung_gloves_old", "garage/garage_hung_gloves_old.png", gl, 10, GLOVES_PIV, {
		"pos": [RING.x, RING.y], "layer": "sorted", "sort_y": 254, "loop": false,
		"anim": {"land": [0, 1, 2, 1, 3], "rest": [3]},
		"glove_centers": [[325, 206], [331, 211]],
		"note": "Fase 6b1: o par do John pendurado pelo cadarço (cream) na argola do saco, luvas velhas (glove_old) encostadas no ombro esquerdo do saco. Pivô (17,1) = argola em (335,186). 0 = chegando (4 px acima, 1 à esquerda: o quadro de 20 px não deixa mais); 1 = balança à esquerda (1 px); 2 = à direita; 3 = parado."})
	make_mockups()
	if FINAL:
		write_manifest()
	print("ok fase 6b1 cenário (%s): %d sprites" % ["PROJETO" if FINAL else "previa", M.size()])
	quit()
