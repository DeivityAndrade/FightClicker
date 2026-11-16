extends SceneTree
## Fase 6c1 — Primeira chegada à academia e saída do John. Artista de Personagens (skill padrao-personagem).
## Pedido: docs/cutscenes/pedidos-6c1.md §1 (prancha-6c1.md). Gera, de uma pasta temporária (nunca no projeto):
##  (1) Osmar: hold_photo, hang_photo, step_back, look_photo, nudge_photo + coach_idle_gym / coach_talk_gym (luz dos tubos);
##  (2) John (sem camadas, mãos nuas, sem luz pintada como as folhas da 6b1): carry_bag_left, carry_bag_idle_left,
##      hang_bag, carry_crate_left, put_crate, stand_up, pick_duffel, walk_duffel, look_room_left, nod_left, duck_out;
##  (3) discípulo EM CAMADAS (peças da 6b2: 4 cortes, regata/camiseta, faixa, meião, máscara): carry_bag_left,
##      carry_bag_idle_left, hang_bag, carry_crate_left, put_crate, sit_down, sit_rest;
##  (4) vizinho (roupa do neighbor_1; o helper_2 é a mesma folha com a regata trocada por paleta): carry_crate_left,
##      put_crate, stand, stand_left, treadmill_bump_left, treadmill_stuck_left, treadmill_turn_left,
##      treadmill_carry_left, treadmill_put_left;
##  (5) <saida>/manifest-6c1-personagens.json e mockups em <saida>/mock/.
## Quem anda/olha para a ESQUERDA tem folha "_left" desenhada assim (pose montada para a direita, pivô espelhado e a
## imagem virada no gerador, como a correção da 6b1); o jogo não espelha.
## Rodar: godot --headless --path <tmp_com_project.godot_vazio> --script <repo>/tools/art/make_sprites_fase6c1.gd -- <saida>

var ROOT := OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else "E:/Fightclicker/"
const GPIV := Vector2(22, 67)
const STD := [Vector2i(48, 72), Vector2(22, 67)]
const BAGF := [Vector2i(104, 88), Vector2(52, 83)]      # saco no ombro
const HANGF := [Vector2i(112, 104), Vector2(52, 99)]    # saco até o gancho
const PHOTOF := [Vector2i(64, 88), Vector2(22, 83)]     # moldura na parede
const TREADF := [Vector2i(112, 96), Vector2(56, 74)]    # esteira atravessada / deitada no chão
const DUFF := [Vector2i(56, 72), Vector2(22, 67)]       # pegar a bolsa (a mão chega à alça, 25 px à frente)
const P_COACH := Vector2(196, 236)
const P_COACH_BACK := Vector2(188, 240)
const P_MENTOR := Vector2(254, 252)
const P_HANG := Vector2(303, 272)
const HOOK := Vector2(336, 183)
const PHOTO_TL := Vector2(212, 158)
const DUFFEL_TL := Vector2(268, 242)
const TM_PIV := Vector2(445, 267)
const P_TM_END := Vector2(440, 250)
const TUBES := [Vector2i(218, 34), Vector2i(422, 34)]
const LIGHT_C := Vector2(305, 90)
const OLD := {"style": "old", "ramp": ["r0", "r1", "r2"]}
const ARM_REACH := 19.8
const ELB := Vector2(-0.6, 0.3)

var L
var P
var M: Dictionary
var out_dir := ""
var report: Array = []
var sprites := {}
var sheets := {}        # id -> frames (imagens inteiras, visual padrão)
var lay_caps := {}      # id -> capturas (discípulo)
var cam_store := {}
var img_bag_h: Image
var img_bag_full: Image
var img_crate: Image
var img_tm: Image
var img_tm_end: Image
var img_photo: Image
var img_duffel: Image

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================ poses-base (as mesmas da 6b1)
func G(o := {}) -> Dictionary:
	var p := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47),
		"hl": V(-8, -50), "hr": V(10, -51), "el": V(-9, -40), "er": V(10, -40), "toel": V(-1, 0), "toer": V(10, 0)}
	if o.has("hl") and not o.has("el"):
		p.erase("el")
	if o.has("hr") and not o.has("er"):
		p.erase("er")
	if o.has("hl") and not o.has("gkl"):
		p["gkl"] = ""
	if o.has("hr") and not o.has("gkr"):
		p["gkr"] = ""
	if o.get("stl", "") in ["open", "fist"] and not o.has("pl"):
		p["pl"] = V(0.6, 0.3)
	if o.get("str", "") in ["open", "fist"] and not o.has("pr"):
		p["pr"] = V(0.6, 0.3)
	for k in o:
		if o[k] == null:
			p.erase(k)
		else:
			p[k] = o[k]
	return p

func arm(sh: Vector2, deg: float) -> Vector2:
	var r := deg_to_rad(deg)
	return sh + Vector2(sin(r), cos(r)) * ARM_REACH

## Desloca o tronco (e o que vier junto) dy px.
func up(o: Dictionary, dy: float, keys := ["hip", "top", "head", "sl", "sr"]) -> Dictionary:
	for k in keys:
		if o.has(k):
			o[k] = (o[k] as Vector2) + V(0, dy)
	return o

## Ciclo de andar da 6b1 (disciple_walk_bare): 6 quadros, passada de 14 px, pernas e balanço do braço de longe (ar).
## A = perna de longe (toer), B = de perto (toel). 1 e 4 = pé pousa. lean = tronco para trás (px).
func walk_rows(lean := 0.0) -> Array:
	var hi := {"hip": V(0, -31), "top": V(2 - lean, -50), "head": V(2 - lean, -57), "sl": V(-6 - lean, -47), "sr": V(9 - lean, -47)}
	var lo := {"hip": V(0, -29.5), "top": V(2 - lean, -48.5), "head": V(2 - lean, -55.5), "sl": V(-6 - lean, -45.5), "sr": V(9 - lean, -45.5)}
	var md := {"hip": V(0, -30), "top": V(2 - lean, -49), "head": V(2 - lean, -56), "sl": V(-6 - lean, -46), "sr": V(9 - lean, -46)}
	var rows := [
		[hi, {"toer": V(4, -2), "toel": V(-3, 0)}, 4.0],
		[lo, {"toer": V(7, 0), "toel": V(-7, 0), "shoel": "34ball"}, -2.0],
		[md, {"toer": V(2, 0), "toel": V(-8, -1), "shoel": "34ball"}, 1.0],
		[hi, {"toel": V(1, -2), "toer": V(1, 0)}, 4.0],
		[lo, {"toel": V(7, 0), "toer": V(-2, 0), "shoer": "34ball"}, 16.0],
		[md, {"toel": V(2, 0), "toer": V(-3, -1), "shoer": "34ball"}, 11.0],
	]
	var out := []
	for r in rows:
		var o: Dictionary = {"kl": V(1, -0.1), "kr": V(1, -0.1)}
		o.merge((r[0] as Dictionary).duplicate(), true)
		o.merge(r[1], true)
		o["_ar"] = r[2]
		out.append(o)
	return out

func stand_base(dy := 0.0) -> Dictionary:
	var o := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47)}
	return up(o, dy)

## Mão de longe solta girando no ombro (ar graus) — mão aberta, cotovelo para trás.
func far_swing(o: Dictionary, deg: float) -> void:
	o["hr"] = arm(o.sr, deg)
	o["pr"] = ELB
	o["str"] = "open"

func near_swing(o: Dictionary, deg: float) -> void:
	o["hl"] = arm(o.sl, deg)
	o["pl"] = ELB
	o["stl"] = "open"

# ================================================================ adereços (imagens)
func load_props() -> void:
	var bag: Image = P.frames_of(ROOT + "assets/sprites/equipment/bag_l0_idle.png", 40)[0]
	img_bag_full = bag
	# corpo do saco sem argola e sem o fio de areia: linhas com 8+ pixels
	var y0 := -1
	var y1 := -1
	for y in bag.get_height():
		var n := 0
		for x in bag.get_width():
			if bag.get_pixel(x, y).a > 0.5:
				n += 1
		if n >= 8:
			if y0 < 0:
				y0 = y
			y1 = y
	var x0 := 99
	var x1 := -1
	for y in range(y0, y1 + 1):
		for x in bag.get_width():
			if bag.get_pixel(x, y).a > 0.5:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
	var body: Image = bag.get_region(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1))
	body.rotate_90(CLOCKWISE)   # tampa (topo) para a frente
	img_bag_h = body
	report.append("saco deitado: %dx%d (corpo do bag_l0_idle q0, sem argola)" % [body.get_width(), body.get_height()])
	img_crate = P.load_png(ROOT + "assets/sprites/garage/garage_crate.png")
	img_tm = P.load_png(ROOT + "assets/sprites/equipment/treadmill_l0_idle.png")
	img_tm_end = treadmill_end()
	img_photo = photo_straight()
	img_duffel = duffel()

## Foto antiga RETA (a da garagem tem a metade direita 1 px abaixo): sobe as colunas 9..17 em 1 px.
func photo_straight() -> Image:
	var s: Image = P.load_png(ROOT + "assets/sprites/garage/wall_photo_old.png")
	var o: Image = L.blank(18, 21)
	for y in 21:
		for x in 18:
			var sy := y + (1 if x >= 9 else 0)
			if sy < s.get_height():
				o.set_pixel(x, y, s.get_pixel(x, sy))
	return o

## Esteira vista de ponta (girada para passar pela porta): ponta do deque com o rolo embaixo, lona recuando, os dois
## montantes e o painel lá atrás. 24x30, mesmas cores da treadmill_l0 (enferrujada).
func treadmill_end() -> Image:
	var im: Image = L.blank(24, 30)
	# painel (longe = em cima)
	L.R(im, 3, 0, 18, 6, "ink")
	L.R(im, 4, 1, 16, 4, "d2")
	L.R(im, 7, 1, 10, 2, "d1")
	L.R(im, 4, 4, 16, 1, "st0")
	im.set_pixel(15, 2, L.col("br2"))
	# montantes
	for x in [5, 17]:
		L.R(im, x - 1, 6, 4, 10, "ink")
		L.R(im, x, 6, 2, 10, "st1")
		L.R(im, x, 6, 1, 10, "st2")
	im.set_pixel(18, 10, L.col("br2"))
	# lona recuando (trapézio)
	for y in range(14, 22):
		var t := float(y - 14) / 7.0
		var hw := int(round(lerpf(8.0, 11.0, t)))
		L.R(im, 12 - hw - 1, y, (hw + 1) * 2, 1, "ink")
		L.R(im, 12 - hw, y, hw * 2, 1, "d2" if (y % 3 != 0) else "g0")
	im.set_pixel(9, 17, L.col("br1"))
	im.set_pixel(14, 19, L.col("br2"))
	# ponta do deque com o rolo
	L.R(im, 0, 22, 24, 8, "ink")
	L.R(im, 1, 23, 22, 6, "st1")
	L.R(im, 1, 23, 22, 1, "st2")
	L.R(im, 1, 27, 22, 2, "st0")
	L.R(im, 9, 24, 6, 3, "d2")
	L.R(im, 10, 25, 4, 1, "st2")
	im.set_pixel(4, 25, L.col("br2"))
	im.set_pixel(19, 26, L.col("br1"))
	im.set_pixel(20, 24, L.col("br2"))
	return im

## Esteira de lado "apertada" na largura (meio giro), vizinho mais próximo.
func tm_squeezed(w: int) -> Image:
	var s: Image = img_tm.duplicate()
	s.resize(w, s.get_height(), Image.INTERPOLATE_NEAREST)
	return s

## Bolsa de lona do John (18x11), alças em cima. Lona cinza-esverdeada desbotada, alças e costura de couro.
func duffel() -> Image:
	var rows := [
		"......k....k......",
		".....kAk..kAk.....",
		"..kkkkAkkkkAkkkk..",
		".kLLLLALLLLALLLLk.",
		"kLLLLLALLLLALLLLMk",
		"kMLLLLLLLLLLLLLLMk",
		"kMLzzzzzzzzzzzzLMk",
		"kMMMMMMMMMMMMMMMMk",
		"kDMMMMMMMMMMMMMMDk",
		".kDDDDDDDDDDDDDDk.",
		"..kkkkkkkkkkkkkk..",
	]
	var lg := {"k": "ink", "A": "br1", "L": "g3", "M": "g2", "D": "g1", "z": "br2"}
	var im: Image = L.blank(18, 11)
	for y in rows.size():
		var r: String = rows[y]
		for x in r.length():
			if lg.has(r[x]):
				im.set_pixel(x, y, L.col(lg[r[x]]))
	return im

# ================================================================ desenho dos adereços dentro do quadro
func _edge(im: Image, x: int, y: int) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var qx: int = x + d.x
		var qy: int = y + d.y
		if qx < 0 or qy < 0 or qx >= im.get_width() or qy >= im.get_height() or im.get_pixel(qx, qy).a < 0.5:
			return true
	return false

## Põe a imagem no mapa de partes (id = profundidade para sombra de contato); o contorno de fora sai e o finish()
## refaz o contorno da silhueta junta.
func put_img(lib, im: Image, tl: Vector2, id: int) -> void:
	var ink: String = (L.col("ink") as Color).to_html(false)
	var bx := int(round(tl.x))
	var by := int(round(tl.y))
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if c.to_html(false) == ink and _edge(im, x, y):
				continue
			lib.put(bx + x, by + y, c, id)

## Adereço ATRÁS de tudo: só onde o quadro está vazio (o contorno do adereço fica).
func under_img(dst: Image, im: Image, tl: Vector2) -> void:
	var bx := int(round(tl.x))
	var by := int(round(tl.y))
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var X := bx + x
			var Y := by + y
			if X < 0 or Y < 0 or X >= dst.get_width() or Y >= dst.get_height():
				continue
			if dst.get_pixel(X, Y).a < 0.5:
				dst.set_pixel(X, Y, c)

func flipped(im: Image) -> Image:
	var c: Image = im.duplicate()
	c.flip_x()
	return c

# ================================================================ render
## p = pose da garagem + chaves privadas:
##  _props: [[estágio, imagem, canto rel. ao pivô, id]] (estágio "after_torso" | "after_left" | "end" | "under")
##  _head_redraw: redesenha pescoço+cabeça depois dos adereços do after_torso (saco atrás da cabeça)
##  _fingers: [Vector2 rel] dedos da mão de perto por cima do adereço; _strap: [[a, b]] alça (1 px, couro)
##  _pre: Callable (toalha do Osmar); _head_rot: graus (cabeça inclinada); _finger: dedo esticado da mão da frente
func render(b: Dictionary, p0: Dictionary, tag: String, fr: Array, left: bool) -> Dictionary:
	var size: Vector2i = fr[0]
	var piv: Vector2 = fr[1]
	var rpiv := Vector2(size.x - 1 - piv.x, piv.y) if left else piv
	var p := {}
	for k in p0:
		if not (k as String).begins_with("_"):
			p[k] = p0[k]
	var props: Array = p0.get("_props", [])
	var fl: bool = left and p0.get("_keep_screen", false)
	var stage := {"after_torso": [], "after_left": [], "end": []}
	for pr in props:
		if pr[0] == "under":
			continue
		var im: Image = flipped(pr[1]) if fl else pr[1]
		var rel: Vector2 = pr[2]
		var id: int = pr[3]
		(stage[pr[0]] as Array).append(func(lib, O: Vector2, ctx: Dictionary) -> void: put_img(lib, im, O + rel, id))
	var face: String = p0.get("face", "normal")
	var pre = p0.get("_pre", null)
	var redraw: bool = p0.get("_head_redraw", false)
	var hrot: float = p0.get("_head_rot", 0.0)
	var straps: Array = p0.get("_strap", [])
	var fingers: Array = p0.get("_fingers", [])
	var finger: bool = p0.get("_finger", false)
	p["after_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		if pre != null:
			(pre as Callable).call(lib, O, ctx)
		for s in straps:
			var a: Vector2 = O + (s[0] as Vector2)
			var c: Vector2 = O + (s[1] as Vector2)
			var n := int(maxf(absf(c.x - a.x), absf(c.y - a.y)))
			for i in range(n + 1):
				var q := a.lerp(c, float(i) / float(maxi(n, 1))).round()
				lib.put(int(q.x), int(q.y), "br1", 36)
		for f in stage.after_torso:
			(f as Callable).call(lib, O, ctx)
		if (redraw and not lib.skip_head) or hrot != 0.0:
			var hd: Vector2 = ctx.hd
			lib.limb(lib.TORSO, (ctx.top as Vector2) + V(0, 1), hd + V(0, 4), 2.3, 2.2, b.skin)
			lib.pmap(lib.HEAD, lib.head_rows(b, "34", face), lib.head_legend(b), hd, b.head_anchor_34, hrot)
	if not stage.after_left.is_empty():
		p["after_left"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
			for f in stage.after_left:
				(f as Callable).call(lib, O, ctx)
	p["end"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		for f in stage.end:
			(f as Callable).call(lib, O, ctx)
		var sk: Array = b.skin
		for fp in fingers:
			var q: Vector2 = O + (fp as Vector2)
			lib.put(int(q.x) - 1, int(q.y), sk[1], 74)
			lib.put(int(q.x), int(q.y), sk[2], 74)
			lib.put(int(q.x) + 1, int(q.y), sk[1], 74)
			lib.put(int(q.x), int(q.y) + 1, sk[0], 74)
		if finger:
			var hr: Vector2 = ctx.hr
			var d: Vector2 = (hr - (ctx.elr as Vector2)).normalized()
			for k in range(2, 5):
				var q := (hr + d * float(k) + V(0, -1)).round()
				lib.put(int(q.x), int(q.y), sk[1] if k < 4 else sk[0], 75)
	var skip_keep: bool = P.skip_head
	if hrot != 0.0:
		P.skip_head = true
	P.build_ref = b
	var im: Image = P.garage_frame(b, p, tag, size, rpiv)
	P.skip_head = skip_keep
	var anc: Dictionary = P.last_anchor.duplicate(true)
	# adereços atrás de tudo
	for pr in props:
		if pr[0] != "under":
			continue
		var pim: Image = flipped(pr[1]) if fl else pr[1]
		var tl: Vector2 = rpiv + (pr[2] as Vector2)
		under_img(im, pim, tl)
		if P.capture and not P.captured.is_empty():
			var c: Dictionary = P.captured[-1]
			under_img(c.full, pim, tl)
			under_img(c.body, pim, tl)
	if left:
		im.flip_x()
		if P.capture:
			P.capture_flip_last()
	var hands := {"hand_front": [p.hr.x, p.hr.y], "hand_back": [p.hl.x, p.hl.y]}
	if left:
		hands = {"hand_front": [-p.hl.x, p.hl.y], "hand_back": [-p.hr.x, p.hr.y]}
		for k in ["head", "hip", "top"]:
			anc[k] = [-float(anc[k][0]), anc[k][1]]
		anc["view"] = "34_left"
	return {"im": im, "hands": hands, "anchor": anc}

# ================================================================ quem
func john_build() -> Dictionary:
	var o: Dictionary = P.identidade("primeiro")
	o.merge({"glove": OLD.style, "glove_ramp": OLD.ramp}, true)
	return P.build(o)

func disc_build() -> Dictionary:
	var o: Dictionary = P.identidade("disc")
	o.merge({"glove": OLD.style, "glove_ramp": OLD.ramp}, true)
	return P.build(o)

const H34_N1 := [
	"...HHHHHHH...",
	".HHHhhhhhHHH.",
	"HHHhhhhhhhHHH",
	"HHHHHHHHHHHHH",
	"HHHSsslllllll",
	"HHSSsbbsslbbl",
	"HESSsesssles.",
	"HEsSssssslll.",
	".ESsssssssss.",
	".SSsssssssSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]
const CHINELO_34 := ["..DMM....", ".DMMwL...", ".DMMMwLL.", "DMMMMMMLM", "ccccccccc"]
const CHINELO_34_BALL := [".DM......", ".DMMw....", "..DMMwL..", "..DMMMMM.", "...cDMMML", ".....cccc"]

func transfer_faces(base: Array, faces: Dictionary, custom: Array) -> Dictionary:
	var out := {}
	var face_chars := ["s", "S", "l", "e", "b", "m", "x", "E", "u", "o"]
	for f in faces:
		var ov: Dictionary = faces[f]
		var nd := {}
		for k in ov:
			var pr: String = base[int(k)]
			var fr: String = ov[k]
			var cr: String = custom[int(k)]
			var nr := ""
			for i in cr.length():
				var c := cr[i]
				if i < pr.length() and i < fr.length() and pr[i] != fr[i] and c in face_chars:
					c = fr[i]
				nr += c
			nd[int(k)] = nr
		out[f] = nd
	return out

func _mirror_row(r: String, w: int) -> String:
	var s := r
	while s.length() < w:
		s += "."
	var o := ""
	for i in range(s.length() - 1, -1, -1):
		o += s[i]
	return o

func _mirror_rows(rows: Array) -> Array:
	var w := 0
	for r in rows:
		w = maxi(w, (r as String).length())
	var out := []
	for r in rows:
		out.append(_mirror_row(r, w))
	return out

## Vizinho da casa 12 (a mesma roupa do neighbor_1: regata verde, bermuda escura, chinelo). look = cabeça virada.
func helper_build(look := false) -> Dictionary:
	var chinelo := {"34": {"rows": CHINELO_34, "toe": Vector2i(8, 4), "ankle": Vector2i(3, 0), "ang": 0.0},
		"34ball": {"rows": CHINELO_34_BALL, "toe": Vector2i(8, 5), "ankle": Vector2i(2, 0), "ang": 0.0}}
	var head: Array = H34_N1
	if look:
		head = _mirror_rows(head)
	var o := {"head_34": head, "hair": ["ink", "d2"], "brow": "ink", "skin": ["sk0", "sk1", "sk2"],
		"top": "tank", "shirt": ["gr0", "gr1", "gr2"], "shorts": ["d1", "d2", "g0"], "band": "g0",
		"shoes": ["sk0", "sk1", "sk2", "b2", "b1"], "shoe_maps": chinelo, "glove": "fist", "shoulder": 0.95, "hip_w": 0.92,
		"g_arm_r": [2.3, 1.8, 2.0, 1.5], "g_leg_r": [3.3, 2.4, 2.3, 1.4]}
	var b: Dictionary = P.build(o)
	b["faces_34"] = {} if look else transfer_faces(P.HEAD_34, P.FACES_34, b.head_34)
	return b

## Osmar (make_sprites_fase6a.gd): mesma cabeça, roupa, toalha e corpo.
const TRAINER_HEAD_34 := [
	"....SSsss....",
	"..SSsssllls..",
	".SSssssllllS.",
	".SSsssssssss.",
	"HHSsssslllll.",
	"HHSsbbbsslbbb",
	"HHESsesssles.",
	"HEsSssssslll.",
	".HESssssssss.",
	".HSssooooSss.",
	"..SsooooooS..",
	"...SSsssss...",
	".....SSSs....",
]
const TRAINER_FACES_34 := {
	"normal": {},
	"talk_a": {11: "...SSsxxss...", 12: ".....SSSs...."},
	"talk_b": {11: "...SSsxss....", 12: ".....SSSs...."},
}

func trainer_build(glove := "fist") -> Dictionary:
	return P.build({"head_34": TRAINER_HEAD_34, "faces_34": TRAINER_FACES_34, "head_anchor_34": Vector2i(6, 6),
		"hair": ["g2", "g3"], "brow": "white", "mustache": "white", "skin": ["sk0", "sk1", "sk2"],
		"top": "tshirt", "shirt": ["st1", "st2", "st3"], "sleeve_t": 0.5, "trim": "white",
		"bottom": "pants", "shorts": ["g0", "g1", "g2"], "band": "d1", "belt": ["d1", "d2", "d2", "g3"],
		"shoes": ["br0", "br0", "br1", "br2", "ink"], "glove": glove,
		"belly": 3.5, "shoulder": 0.96, "hip_w": 1.05,
		"head_legend_extra": {"o": "white"}})

func towel_hook() -> Callable:
	return func(lib, O: Vector2, ctx: Dictionary) -> void:
		var s: Vector2 = ctx.sr
		var x0 := int(round(s.x)) - 2
		var y0 := int(round(s.y)) - 1
		for yy in range(0, 10):
			for xx in range(0, 3):
				var c := "white" if xx < 2 else "cream"
				if yy == 0 and xx == 2:
					continue
				if yy == 7:
					c = "b2"
				if yy == 9 and xx == 0:
					c = "cream"
				lib.put(x0 + xx - (1 if yy < 2 else 0), y0 + yy, c, 35)

func tpose(o := {}) -> Dictionary:
	var p := {"hip": V(1, -30), "top": V(0, -48), "head": V(1, -55), "sl": V(-6, -45), "sr": V(7, -45),
		"toel": V(-2, 0), "toer": V(9, 0), "kl": V(0.5, 0), "kr": V(0.6, 0), "gkl": "", "gkr": ""}
	for k in o:
		if o[k] == null:
			p.erase(k)
		else:
			p[k] = o[k]
	p["_pre"] = towel_hook()
	return p

## Luz dos tubos da academia (make_sprites_fase5.gd, gym_step/gym_light).
func gym_step(x: int, y: int) -> int:
	var best := -9.0
	for t in TUBES:
		var d := Vector2(x - t.x, (y - t.y - 30) * 0.8).length() / 260.0
		best = maxf(best, 0.95 - d * 1.9)
	best -= clampf(float(y - 250) / 120.0, 0.0, 0.35)
	var base := floorf(best)
	var fr := clampf((best - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
	var bb: float = (L.BAYER[y % 4][x % 4] + 0.5) / 16.0
	return clampi(int(base) + (1 if fr > bb else 0), -2, 1)

func gym_light(img: Image, topleft: Vector2i) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var st := gym_step(x + topleft.x, y + topleft.y)
			if st != 0:
				img.set_pixel(x, y, L.shade(c, st))

# ================================================================ OSMAR
func coach_poses(id: String) -> Array:
	match id:
		"coach_idle_gym", "coach_idle_check":   # = coach_idle (braços cruzados, respiração)
			var out := []
			for dy in [0, 0, 1, 1]:
				var p := tpose({"hl": V(4, -39 + dy), "el": V(-7, -37 + dy), "hr": V(-4, -41 + dy), "er": V(8, -37 + dy)})
				up(p, dy)
				p["_bh"] = true
				out.append(p)
			return out
		"coach_talk_gym":
			var hand := [V(13, -44), V(13, -47), V(14, -45), V(13, -46)]
			var faces := ["talk_a", "normal", "talk_b", "talk_a"]
			var hy := [0, -1, 0, 0]
			var out := []
			for i in 4:
				var p := tpose({"hl": V(5, -39), "el": V(-6, -37), "hr": hand[i], "pr": V(0.6, 1.0), "face": faces[i]})
				p["head"] = (p["head"] as Vector2) + V(0, hy[i])
				out.append(p)
			return out
		"coach_hold_photo":   # moldura nas duas mãos na altura do peito, meio de lado (virada para a parede)
			var out := []
			var nar := tm_like_squeeze(img_photo, 10)
			for dy in [0, 0, 1, 1]:
				var p := tpose({"hl": V(5, -36 + dy), "pl": V(-0.3, 1), "stl": "fist", "gkl": "side",
					"hr": V(15, -37 + dy), "pr": V(0.2, 1), "str": "fist", "gkr": "side"})
				up(p, dy)
				p["_props"] = [["after_torso", nar, V(6, -47 + dy), 33]]
				out.append(p)
			return out
		"coach_hang_photo":
			var o := []
			var lean := {"hip": V(2, -30), "top": V(3, -49), "head": V(3, -56), "sl": V(-3, -46), "sr": V(10, -47)}
			var toe := {"hip": V(3, -32), "top": V(6, -52), "head": V(6, -59), "sl": V(0, -50), "sr": V(13, -51), "shoel": "34ball", "shoer": "34ball",
				"toel": V(-1, 0), "toer": V(9, 0)}
			# 0 começa a erguer (moldura meio de lado, na altura do peito alto)
			var p0 := tpose({"hl": V(7, -44), "pl": V(-0.2, 1), "stl": "fist", "gkl": "side", "hr": V(19, -45), "pr": V(0.2, 1), "str": "fist", "gkr": "side"})
			p0.merge({"hip": V(1, -30), "top": V(1, -48), "head": V(2, -55), "sl": V(-5, -45), "sr": V(8, -46)}, true)
			p0["_props"] = [["after_torso", tm_like_squeeze(img_photo, 12), V(8, -55), 33]]
			o.append(p0)
			# 1 na altura do rosto, girando para a parede
			var p1 := tpose(lean.merged({"hl": V(11, -54), "pl": V(-0.2, 1), "stl": "fist", "gkl": "side", "hr": V(25, -55), "pr": V(0.3, 1), "str": "fist", "gkr": "side"}, true))
			p1["_props"] = [["under", tm_like_squeeze(img_photo, 15), V(11, -68), 0]]
			o.append(p1)
			# 2 na ponta dos pés, a moldura quase na parede (2 px abaixo do ponto)
			var p2 := tpose(toe.merged({"hl": V(17, -56), "pl": V(-0.3, 1), "stl": "fist", "gkl": "up", "hr": V(30, -57), "pr": V(0.2, 1), "str": "fist", "gkr": "up"}, true))
			p2["_props"] = [["under", img_photo, V(16, -76), 0]]
			o.append(p2)
			# 3 encosta (no ponto final)
			var p3 := tpose(toe.merged({"hl": V(17, -59), "pl": V(-0.3, 1), "stl": "fist", "gkl": "up", "hr": V(30, -60), "pr": V(0.2, 1), "str": "fist", "gkr": "up"}, true))
			p3["_props"] = [["under", img_photo, V(16, -78), 0]]
			o.append(p3)
			# 4 BATE O PREGO com a palma (uma vez): a mão da frente espalma no meio da moldura
			var t4 := toe.duplicate()
			up(t4, -1)
			var p4 := tpose(t4.merged({"hl": V(17, -59), "pl": V(-0.3, 1), "stl": "fist", "gkl": "up", "hr": V(25, -68), "pr": V(0.4, 1), "str": "open", "gkr": "up"}, true))
			p4["_props"] = [["under", img_photo, V(16, -78), 0]]
			o.append(p4)
			# 5 SOLTA (a foto vira adereço): mãos abertas se afastando
			var p5 := tpose(toe.merged({"hl": V(14, -55), "pl": V(-0.3, 1), "stl": "open", "gkl": "up", "hr": V(24, -60), "pr": V(0.4, 1), "str": "open", "gkr": "up"}, true))
			o.append(p5)
			# 6 desce dos pés, braços descendo
			var p6 := tpose(lean.merged({"hl": V(6, -40), "pl": V(-0.3, 1), "stl": "open", "hr": V(16, -42), "pr": V(0.3, 1), "str": "open"}, true))
			o.append(p6)
			# 7 braços soltos
			var p7 := tpose({"hl": V(-7, -27), "pl": ELB, "stl": "open", "hr": V(10, -27), "pr": ELB, "str": "open"})
			o.append(p7)
			return o
		"coach_step_back":   # passo curto para trás, sem dar as costas à foto (anda para a esquerda virado para a direita)
			var arms := {"hl": V(-7, -28), "pl": ELB, "stl": "open", "hr": V(11, -28), "pr": ELB, "str": "open"}
			var a := tpose(arms.merged({"toel": V(-1, 0), "toer": V(9, 0)}, true))
			var b2 := tpose(arms.merged({"toel": V(-8, 0), "toer": V(10, 0), "shoer": "34ball", "hip": V(0, -29), "top": V(-1, -47),
				"head": V(0, -54), "sl": V(-7, -44), "sr": V(6, -44), "hl": V(-9, -27), "hr": V(10, -27), "kl": V(-0.3, 0), "kr": V(1, 0)}, true))
			var c := tpose(arms.merged({"toel": V(-5, 0), "toer": V(5, -2), "shoer": "34ball", "hip": V(0, -30), "top": V(-1, -48),
				"head": V(0, -55), "sl": V(-7, -45), "sr": V(6, -45), "hl": V(-8, -28), "hr": V(10, -28)}, true))
			var d := tpose(arms.merged({"toel": V(-2, 0), "toer": V(8, 0), "hip": V(1, -29.5), "top": V(0, -47.5), "head": V(1, -54.5),
				"sl": V(-6, -44.5), "sr": V(7, -44.5)}, true))
			return [a, b2, c, d]
		"coach_look_photo":   # 0 braços soltos; 1 mão no queixo; 2 cabeça inclinada olhando a foto
			var p0 := tpose({"hl": V(-7, -27), "pl": ELB, "stl": "open", "hr": V(10, -27), "pr": ELB, "str": "open", "head": V(2, -55)})
			var chin := {"hl": V(7, -39), "el": V(-5, -36), "stl": "fist", "gkl": "side", "hr": V(5, -48), "pr": V(0.4, 1), "str": "fist", "gkr": "up"}
			var p1 := tpose(chin.merged({"head": V(2, -55)}, true))
			var p2 := tpose(chin.merged({"head": V(2, -55), "hr": V(5, -47)}, true))
			p2["_head_rot"] = 14.0
			return [p0, p1, p2]
		"coach_nudge_photo":   # o dedo da frente empurra o canto de baixo da moldura (a foto entorta no quadro 2)
			var lean := {"hip": V(2, -30), "top": V(5, -49), "head": V(5, -56), "sl": V(-2, -46), "sr": V(13, -48)}
			var waist := {"hl": V(-6, -31), "el": V(-10, -38), "stl": "fist", "gkl": "side"}
			var p0 := tpose(waist.merged({"hr": V(17, -53), "pr": V(0.3, 1), "str": "fist", "gkr": "up", "head": V(2, -55)}, true))
			var p1 := tpose(lean.merged(waist, true).merged({"hr": V(29, -60), "pr": V(0.3, 1), "str": "fist", "gkr": "side"}, true))
			p1["_finger"] = true
			var p2 := tpose(lean.merged(waist, true).merged({"hr": V(29, -59), "pr": V(0.3, 1), "str": "fist", "gkr": "side", "head": V(5, -55)}, true))
			p2["_finger"] = true
			var p3 := tpose(waist.merged({"hr": V(13, -44), "pr": V(0.4, 1), "str": "fist", "gkr": "up", "head": V(1, -55)}, true))
			return [p0, p1, p2, p3]
	return []

## Moldura vista meio de lado: largura apertada (vizinho mais próximo).
func tm_like_squeeze(im: Image, w: int) -> Image:
	var s: Image = im.duplicate()
	s.resize(w, s.get_height(), Image.INTERPOLATE_NEAREST)
	return s

const COACH := {
	"coach_hold_photo": {"fps": 4, "loop": true, "pos": "P_COACH", "fr": "STD", "scene": "hold_photo",
		"note": "Osmar parado com a moldura da foto antiga nas duas mãos na altura do peito, meio de lado (virada para a parede), olhando a parede à frente. Respiração de 1 px (quadros 2-3)."},
	"coach_hang_photo": {"fps": 8, "loop": false, "pos": "P_COACH", "fr": "PHOTOF", "scene": "hang_photo", "knock_frame": 4, "release_frame": 5,
		"note": "0 começa a erguer a moldura; 1 na altura do rosto, girando para a parede; 2 na ponta dos pés, moldura 2 px abaixo do ponto; 3 ENCOSTA (moldura exatamente no gym_photo_spot 212,158 = canto de cima à esquerda; mãos nos cantos de baixo); 4 BATE O PREGO com a palma, uma vez (knock_frame, som nail_knock); 5 SOLTA: a foto vira adereço NESTE quadro (release_frame; a folha não desenha mais a moldura); 6 desce dos pés; 7 braços soltos. A moldura dos quadros 1-4 é desenhada ATRÁS das mãos e do braço (está na parede)."},
	"coach_step_back": {"fps": 8, "loop": true, "pos": "P_COACH", "fr": "STD", "scene": "step_back", "step_frames": [1, 3],
		"note": "Passo curto para trás sem dar as costas à foto: virado para a DIREITA enquanto anda para a esquerda/baixo (196,236)->(188,240). Também serve para voltar (a cena move o ponto). 1 = pé de trás pousa atrás; 3 = pé da frente pousa."},
	"coach_look_photo": {"fps": 10, "loop": false, "pos": "P_COACH_BACK", "fr": "STD", "scene": "look_photo", "hold_frame": 2,
		"note": "0 braços soltos; 1 mão da frente no queixo, a outra apoia o cotovelo; 2 CABEÇA INCLINADA (14 graus para a foto) olhando a foto. Segurar o quadro 2."},
	"coach_nudge_photo": {"fps": 10, "loop": false, "pos": "P_COACH", "fr": "PHOTOF", "scene": "nudge_photo", "nudge_frame": 2,
		"note": "Outra mão na cintura. 0 braço da frente sobe; 1 dedo esticado no canto de baixo à direita da moldura (ponta do dedo perto de 229,177); 2 EMPURRA 1 px para baixo: a foto entorta NESTE quadro (nudge_frame: trocar wall_photo_old_gym para crooked); 3 recolhe o braço, satisfeito. A moldura NÃO está na folha (é o adereço da parede)."},
	"coach_idle_gym": {"fps": 3, "loop": true, "pos": "P_COACH", "fr": "STD", "scene": "idle@gym",
		"note": "= coach_idle (braços cruzados, respiração lenta) com a LUZ DOS TUBOS da academia aplicada no ponto (196,236) no lugar da lâmpada da garagem. Usar no lugar do coach_idle quando ele está na academia."},
	"coach_talk_gym": {"fps": 6, "loop": true, "pos": "P_COACH", "fr": "STD", "scene": "talk@gym",
		"note": "= coach_talk (um braço cruzado, a outra mão acompanha a fala, boca abre e fecha) com a LUZ DOS TUBOS da academia no ponto (196,236)."},
}

func gen_coach() -> void:
	var b := trainer_build("fist")
	var bh := trainer_build("none")
	for id in COACH:
		var e: Dictionary = COACH[id]
		var fr: Array = STD if e.fr == "STD" else PHOTOF
		var pos: Vector2 = P_COACH if e.pos == "P_COACH" else P_COACH_BACK
		var frames := []
		var hands := []
		var anchors := []
		var i := 0
		for p in coach_poses(id):
			var r := render(bh if p.get("_bh", false) else b, p, "%s[%d]" % [id, i], fr, false)
			var im: Image = r.im
			var tl := pos - (fr[1] as Vector2)
			gym_light(im, Vector2i(int(tl.x), int(tl.y)))
			frames.append(im)
			hands.append(r.hands)
			anchors.append(r.anchor)
			i += 1
		var extra := {"who": "treinador", "light": "academia (tubos)"}
		for k in ["knock_frame", "release_frame", "nudge_frame", "step_frames", "hold_frame"]:
			if e.has(k):
				extra[k] = e[k]
		if id == "coach_hang_photo":
			extra["photo_rect_rel"] = [16, -78, 18, 21]
			extra["photo_note"] = "Canto de cima à esquerda da moldura relativo ao pivô no quadro 3-4 (= gym_photo_spot 212,158 com o Osmar em 196,236)."
		if id == "coach_nudge_photo":
			extra["finger_tip_rel"] = [33, -60]
		save_plain(id, frames, hands, anchors, fr, pos, e, "characters/", extra, "direita")
	# conferência: o coach_idle da garagem, desenhado por este gerador com a luz da lâmpada, tem de bater com o atual
	var chk := []
	for p in coach_poses("coach_idle_check"):
		var r := render(bh, p, "coach_idle_check", STD, false)
		var im: Image = r.im
		L.light(im, Rect2i(0, 0, 48, 72), LIGHT_C - (P_COACH - GPIV), 300.0, 1.1, 3.6, -1, 1, 0.9)
		chk.append(im)
	var cur: Image = P.load_png(ROOT + "assets/sprites/characters/coach_idle.png")
	var mine: Image = P.strip(chk)
	var nd := 0
	for y in cur.get_height():
		for x in cur.get_width():
			if cur.get_pixel(x, y) != mine.get_pixel(x, y):
				nd += 1
	report.append("conferência Osmar: coach_idle refeito com a lâmpada difere do atual em %d px (0 = mesmo corpo)" % nd)

# ================================================================ JOHN e DISCÍPULO (mesmo corpo)
## Saco deitado no ombro de perto (o de trás de quem anda), atrás da cabeça; a mão de perto segura por cima.
func with_bag(o: Dictionary) -> Dictionary:
	var sl: Vector2 = o.sl
	var bw := img_bag_h.get_width()
	var bh := img_bag_h.get_height()
	var tl := V(sl.x + 19 - bw, sl.y - 13 - bh / 2.0).round()
	o["hl"] = V(sl.x - 2, sl.y - 19)
	o["pl"] = V(-1, 0.4)
	o["stl"] = "fist"
	o["gkl"] = "up"
	o["_props"] = [["after_torso", img_bag_h, tl, 35]]
	o["_head_redraw"] = true
	return o

func carry_bag_poses() -> Array:
	var out := []
	for r in walk_rows(0.0):
		var o: Dictionary = r
		far_swing(o, float(o._ar))
		out.append(G(with_bag(o)))
	return out

func carry_bag_idle_poses() -> Array:
	var out := []
	for dy in [0.0, 1.0]:
		var o := stand_base(dy)
		o.merge({"toel": V(-2, 0), "toer": V(9, 0), "kl": V(1, 0), "kr": V(1, 0)}, true)
		far_swing(o, 4.0)
		out.append(G(with_bag(o)))
	return out

## Saco do gancho: o bag_l0_idle q0 inteiro com a argola em (ring_rel).
func bag_at(ring_rel: Vector2) -> Array:
	return ["under", img_bag_full, ring_rel - V(20, 0), 0]

func hang_bag_poses() -> Array:
	var ring := HOOK - P_HANG   # (33, -89)
	var o := []
	# 0 vira para o gancho (saco ainda no ombro)
	var f0 := stand_base()
	f0.merge({"toel": V(-2, 0), "toer": V(9, 0)}, true)
	far_swing(f0, 6.0)
	o.append(G(with_bag(f0)))
	# 1 tira do ombro: saco deitado por cima da cabeça, as duas mãos embaixo
	var f1 := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-6, -48), "sr": V(9, -48), "toel": V(-3, 0), "toer": V(10, 0),
		"hl": V(1, -63), "pl": V(-1, 0.3), "stl": "fist", "gkl": "up", "hr": V(16, -63), "pr": V(1, 0.3), "str": "fist", "gkr": "up", "face": "effort",
		"kl": V(1, 0), "kr": V(1, 0)}
	f1["_props"] = [["after_torso", img_bag_h, V(10 - img_bag_h.get_width() / 2.0, -64 - img_bag_h.get_height()).round(), 35]]
	f1["_head_redraw"] = true
	o.append(G(f1))
	# 2 de pé: o saco (já em pé) sobe na frente, abraçado pelo lado de perto; 9 px abaixo do gancho
	var lean := {"hip": V(2, -31), "top": V(5, -50), "head": V(6, -57), "sl": V(-1, -48), "sr": V(11, -48), "toel": V(-2, 0), "toer": V(11, 0),
		"tw": 0.6, "face": "effort", "kl": V(1, 0), "kr": V(1, 0)}
	var f2 := lean.duplicate()
	f2.merge({"hl": V(16, -56), "pl": V(-0.3, 1), "stl": "fist", "gkl": "side", "hr": V(18, -48), "pr": V(0.2, 1), "str": "fist", "gkr": "side"}, true)
	f2["_props"] = [bag_at(ring + V(0, 9))]
	o.append(G(f2))
	# 3 ponta dos pés: argola 2 px acima do gancho
	var tip := {"hip": V(2, -33), "top": V(5, -52), "head": V(6, -59), "sl": V(0, -50), "sr": V(12, -50), "toel": V(-2, 0), "toer": V(11, 0),
		"shoel": "34ball", "shoer": "34ball", "tw": 0.6, "face": "effort", "kl": V(1, 0), "kr": V(1, 0)}
	var f3 := tip.duplicate()
	f3.merge({"hl": V(16, -64), "pl": V(-0.3, 1), "stl": "fist", "gkl": "up", "hr": V(18, -56), "pr": V(0.2, 1), "str": "fist", "gkr": "side"}, true)
	f3["_props"] = [bag_at(ring + V(0, -2))]
	o.append(G(f3))
	# 4 ENGANCHA: o saco vira o objeto da sala (não está na folha); as mãos descem 2 px com ele
	var f4 := tip.duplicate()
	f4.merge({"hl": V(16, -62), "pl": V(-0.3, 1), "stl": "fist", "gkl": "up", "hr": V(18, -54), "pr": V(0.2, 1), "str": "fist", "gkr": "side"}, true)
	o.append(G(f4))
	# 5 solta: mãos abertas se afastando, calcanhares descem
	var f5 := lean.duplicate()
	f5.merge({"hl": V(12, -52), "pl": V(-0.3, 1), "stl": "open", "gkl": "up", "hr": V(15, -45), "pr": V(0.3, 1), "str": "open", "gkr": "side", "face": "normal"}, true)
	o.append(G(f5))
	# 6 baixa os braços
	var f6 := stand_base()
	f6.merge({"hl": V(-4, -31), "pl": ELB, "stl": "open", "hr": V(13, -33), "pr": ELB, "str": "open", "toel": V(-1, 0), "toer": V(9, 0)}, true)
	o.append(G(f6))
	# 7 parado (= disciple_stand_bare q0)
	var f7 := stand_base()
	near_swing(f7, 3.0)
	far_swing(f7, 5.0)
	o.append(G(f7))
	return o

## Caixote nos dois braços, à frente do peito (por cima do tronco, por baixo dos braços).
func with_crate(o: Dictionary) -> Dictionary:
	var top: Vector2 = o.top
	var tl := V(-3 - (2.0 - top.x), top.y + 5).round()
	o["hl"] = V(tl.x + 1, tl.y + 9)
	o["pl"] = V(-0.4, 1)
	o["stl"] = "fist"
	o["gkl"] = "side"
	o["hr"] = V(tl.x + 24, tl.y + 8)
	o["pr"] = V(0.3, 1)
	o["str"] = "fist"
	o["gkr"] = "side"
	o["_props"] = [["after_torso", img_crate, tl, 55]]
	return o

func carry_crate_poses() -> Array:
	var out := []
	for r in walk_rows(1.0):
		out.append(G(with_crate(r)))
	return out

func put_crate_poses(who: String) -> Array:
	var crate_tl := V(-16, -20)
	var face := "smile" if who == "john" else "normal"
	var f0 := stand_base()
	f0.merge({"top": V(0, -50), "head": V(0, -57), "sl": V(-8, -47), "sr": V(7, -47), "toel": V(-2, 0), "toer": V(9, 0)}, true)
	with_crate(f0)
	# 1 dobra os joelhos e pousa o caixote atrás de si (2 px acima do chão)
	var f1 := {"hip": V(-5, -24), "top": V(-1, -42), "head": V(2, -49), "sl": V(-8, -39), "sr": V(6, -39), "toel": V(0, 0), "toer": V(9, 0),
		"kl": V(1, -0.2), "kr": V(1, -0.2), "hl": V(-14, -23), "pl": V(-0.3, 1), "stl": "fist", "gkl": "side", "hr": V(7, -23), "pr": V(0.4, 1),
		"str": "fist", "gkr": "side"}
	f1["_props"] = [["under", img_crate, crate_tl + V(0, -2), 0]]
	# 2 SOLTA (o caixote vira adereço): meio agachado, mãos abertas saindo de cima do caixote
	var f2 := {"hip": V(-3, -27), "top": V(0, -45), "head": V(2, -52), "sl": V(-7, -42), "sr": V(7, -42), "toel": V(0, 0), "toer": V(9, 0),
		"kl": V(1, -0.2), "kr": V(1, -0.2), "hl": V(-9, -26), "pl": V(-0.3, 1), "stl": "open", "hr": V(9, -26), "pr": V(0.4, 1), "str": "open", "face": face}
	return [G(f0), G(f1), G(f2)]

## Sentar (as mesmas poses do john_sit_down / john_sit_rest da 6b1).
func sit_poses(id: String) -> Array:
	var BL := V(-8, -27)
	match id:
		"sit_down":
			var sit: Array = sit_poses("sit_rest")
			return [
				G({"hl": BL, "stl": "open", "hr": V(12, -31), "str": "open", "head": V(2, -57), "face": "smile"}),
				G({"hip": V(-3, -27), "top": V(0, -45), "head": V(2, -52), "sl": V(-7, -42), "sr": V(7, -42), "toel": V(0, 0), "toer": V(9, 0),
					"kl": V(1, -0.2), "kr": V(1, -0.2), "hl": V(-4, -26), "stl": "open", "hr": V(10, -26), "str": "open", "face": "smile"}),
				G({"hip": V(-5, -23), "top": V(-1, -41), "head": V(2, -48), "sl": V(-8, -38), "sr": V(6, -38), "toel": V(0, 0), "toer": V(9, 0),
					"kl": V(1, -0.2), "kr": V(1, -0.2), "hl": V(0, -22), "stl": "open", "hr": V(9, -23), "str": "open", "face": "smile"}),
				sit[0],
			]
		"sit_rest":
			var out := []
			for dy in [0, -1, -1, 0]:
				var o := {"hip": V(-6, -22), "top": V(-2, -40), "head": V(1, -47), "sl": V(-9, -37), "sr": V(5, -37),
					"hl": V(1, -21), "hr": V(9, -21), "toel": V(0, 0), "toer": V(9, 0), "kl": V(1, -0.2), "kr": V(1, -0.2),
					"stl": "open", "str": "open", "pl": V(0.2, 1), "pr": V(0.4, 1), "face": "smile"}
				var g := G(o)
				up(g, dy, ["top", "head", "sl", "sr"])
				out.append(g)
			return out
	return []

## Bolsa no ombro de trás (o de perto): alça do ombro até a bolsa, que pende atrás do quadril; a mão de perto segura
## a alça na frente do ombro.
func with_duffel(o: Dictionary, sway := 0.0) -> Dictionary:
	var sl: Vector2 = o.sl
	var hip: Vector2 = o.hip
	var tl := V(sl.x - 13 + sway, hip.y - 6).round()
	o["hl"] = V(sl.x + 2, sl.y + 6)
	o["pl"] = V(-0.2, 1)
	o["stl"] = "fist"
	o["gkl"] = "up"
	var props: Array = o.get("_props", [])
	props.append(["under", img_duffel, tl, 0])
	o["_props"] = props
	o["_strap"] = [[V(sl.x + 1, sl.y - 1), V(sl.x + 2, sl.y + 6)], [V(sl.x + 2, sl.y + 6), tl + V(6, 1)]]
	return o

func walk_duffel_poses() -> Array:
	var out := []
	var sw := [0.0, 0.0, 1.0, 0.0, 0.0, -1.0]
	var i := 0
	for r in walk_rows(0.0):
		var o: Dictionary = r
		far_swing(o, float(o._ar))
		with_duffel(o, sw[i])
		i += 1
		out.append(G(o))
	return out

func pick_duffel_poses() -> Array:
	var bag_tl := DUFFEL_TL - P_MENTOR   # (14,-10)
	var handle := bag_tl + V(11, -1)
	var o := []
	# 0 vira para a bolsa e começa a dobrar o tronco
	o.append(G({"hip": V(0, -30), "top": V(3, -48), "head": V(5, -55), "sl": V(-4, -45), "sr": V(10, -46), "tw": 0.5,
		"hl": V(-6, -27), "stl": "open", "pl": ELB, "hr": V(14, -31), "str": "open", "pr": V(0.3, 1), "toel": V(-1, 0), "toer": V(10, 0)}))
	# 1 dobra mais, a mão da frente desce
	o.append(G({"hip": V(-1, -26), "top": V(5, -42), "head": V(8, -48), "sl": V(-1, -40), "sr": V(12, -40), "tw": 0.8,
		"hl": V(1, -24), "stl": "open", "pl": V(0.3, 1), "hr": V(18, -24), "str": "open", "gkr": "diagdown", "pr": V(0.3, 1),
		"toel": V(-1, 0), "toer": V(11, 0), "kl": V(1, -0.2), "kr": V(1, -0.2)}))
	# 2 agachado, mão na alça
	var crouch := {"hip": V(0, -20), "top": V(10, -32), "head": V(13, -38), "sl": V(5, -30), "sr": V(17, -29), "tw": 0.9,
		"hl": V(4, -21), "stl": "open", "pl": V(0.3, 1), "toel": V(-1, 0), "toer": V(13, 0), "kl": V(1, -0.3), "kr": V(1, -0.3)}
	o.append(G(crouch.merged({"hr": handle + V(0, -1), "str": "open", "gkr": "diagdown", "pr": V(0.3, 1)}, true)))
	# 3 fecha a mão na alça (o adereço ainda está no chão)
	o.append(G(crouch.merged({"hr": handle, "str": "fist", "gkr": "side", "pr": V(0.3, 1)}, true)))
	# 4 PEGA (grab_frame): a bolsa sai do chão pendurada na mão
	var f4 := G({"hip": V(0, -28), "top": V(4, -46), "head": V(6, -53), "sl": V(-3, -43), "sr": V(11, -44), "tw": 0.5,
		"hl": V(-5, -26), "stl": "open", "pl": ELB, "hr": V(17, -33), "str": "fist", "gkr": "side", "pr": V(0.3, 1),
		"toel": V(-1, 0), "toer": V(11, 0), "kl": V(1, 0), "kr": V(1, 0)})
	f4["_props"] = [["end", img_duffel, V(17 - 9, -33 + 2), 76]]
	o.append(f4)
	# 5 bolsa no ombro de trás (= walk_duffel q0 parado)
	var f5 := stand_base()
	far_swing(f5, 4.0)
	with_duffel(f5)
	o.append(G(f5))
	return o

func look_room_poses() -> Array:
	var o := []
	var a := stand_base()
	a.merge({"toel": V(-2, 0), "toer": V(9, 0), "tw": -0.5}, true)
	far_swing(a, 2.0)
	o.append(G(with_duffel(a)))
	var b := stand_base()
	b.merge({"head": V(0, -58), "top": V(0, -50), "toel": V(-2, 0), "toer": V(9, 0)}, true)
	far_swing(b, 4.0)
	o.append(G(with_duffel(b)))
	var c := stand_base()
	c.merge({"head": V(1, -57), "toel": V(-2, 0), "toer": V(9, 0), "face": "smile"}, true)
	far_swing(c, 4.0)
	o.append(G(with_duffel(c)))
	return o

func nod_poses() -> Array:
	var o := []
	for dy in [0.0, 1.0, 2.0, 1.0]:
		var c := stand_base()
		c.merge({"head": V(1, -57 + dy), "toel": V(-2, 0), "toer": V(9, 0), "face": "smile"}, true)
		far_swing(c, 4.0)
		o.append(G(with_duffel(c)))
	return o

## Passar por baixo da porta de enrolar SAINDO (silhueta do disciple_duck_under, virado à direita), com a bolsa: a mão
## de perto segura a alça (sem mão na borda).
func duck_out_poses() -> Array:
	var q := [
		{"hip": V(0, -27), "top": V(2, -46), "head": V(3, -53), "sl": V(-5, -43), "sr": V(9, -43), "toel": V(-3, 0), "toer": V(9, 0), "ar": 10.0},
		{"hip": V(0, -24), "top": V(5, -41), "head": V(8, -47), "sl": V(-1, -39), "sr": V(11, -38), "toel": V(-4, 0), "toer": V(8, 0), "ar": 2.0},
		{"hip": V(0, -23), "top": V(6, -39), "head": V(10, -44), "sl": V(0, -37), "sr": V(12, -36), "toel": V(-5, 0), "toer": V(7, 0), "ar": 0.0},
		{"hip": V(1, -25), "top": V(4, -42), "head": V(8, -47), "sl": V(-2, -40), "sr": V(10, -39), "toel": V(-7, 0), "toer": V(12, 0), "ar": 4.0},
		{"hip": V(2, -27), "top": V(4, -45), "head": V(6, -52), "sl": V(-2, -42), "sr": V(10, -42), "toel": V(-9, 0), "toer": V(10, 0), "shoel": "34ball", "ar": 14.0},
		{"hip": V(1, -30), "top": V(2, -49), "head": V(3, -56), "sl": V(-5, -46), "sr": V(9, -46), "toel": V(-5, -2), "toer": V(9, 0), "shoel": "34ball", "ar": 9.0},
		{"hip": V(0, -31), "top": V(2, -50), "head": V(2, -57), "sl": V(-6, -47), "sr": V(9, -47), "toel": V(-2, 0), "toer": V(7, 0), "ar": 4.0},
	]
	var out := []
	for d in q:
		var o: Dictionary = d.duplicate()
		o["kl"] = V(1, 0)
		o["kr"] = V(1, 0)
		far_swing(o, float(o.ar))
		o.erase("ar")
		with_duffel(o)
		out.append(G(o))
	return out

## Tabela das folhas do lutador (John e discípulo). who = "john" | "disc".
const FIGHTER := {
	"carry_bag": {"left": true, "fps": 10, "loop": true, "fr": "BAGF", "step_frames": [1, 4], "who": ["john", "disc"],
		"note": "Andar para a ESQUERDA com o saco remendado (bag_l0, sempre o da garagem) deitado no ombro de trás, atrás da cabeça (a cabeça aparece inteira); a mão de perto segura o saco por cima, o outro braço balança oposto à perna. Passada de 14 px, 48 px/s. 1 e 4 = pé pousa. Sem espelho."},
	"carry_bag_idle": {"left": true, "fps": 3, "loop": true, "fr": "BAGF", "who": ["john", "disc"],
		"note": "Parado em (352,262) virado para a ESQUERDA (para o Osmar) com o saco no ombro; quadro 1 = ajeita o peso, corpo e saco 1 px abaixo."},
	"hang_bag": {"left": false, "fps": 10, "loop": false, "fr": "HANGF", "release_frame": 4, "who": ["john", "disc"],
		"note": "Em (303,272), termina virado para a DIREITA. 0 virou para o gancho, saco ainda no ombro; 1 tira do ombro: saco deitado por cima da cabeça, as duas mãos embaixo; 2 o saco já em pé sobe na frente (argola 9 px abaixo do gancho), mãos no lado de perto; 3 na ponta dos pés, argola 2 px acima do gancho (336,183); 4 ENGANCHA: o saco vira o objeto da sala NESTE quadro (release_frame; a folha não desenha o saco), poeira; 5 solta, mãos abertas; 6 baixa os braços; 7 parado (= disciple_stand_bare q0). Nos quadros 2-3 o saco é o bag_l0_idle q0 inteiro, desenhado atrás dele, na posição exata do gancho."},
	"carry_crate": {"left": true, "fps": 10, "loop": true, "fr": "STD", "step_frames": [1, 4], "who": ["john", "disc", "helper"],
		"note": "Andar para a ESQUERDA com o caixote (garage_crate) nos dois braços, à frente do peito, tronco 1 px para trás. Passada de 14 px, 48 px/s. 1 e 4 = pé pousa. Sem espelho."},
	"put_crate": {"left": false, "fps": 10, "loop": false, "fr": "STD", "release_frame": 2, "who": ["john", "disc", "helper"],
		"note": "Em (254,252), termina virado para a DIREITA. 0 girou o corpo (caixote ainda no peito); 1 dobra os joelhos e pousa o caixote atrás de si (2 px acima do lugar final, desenhado atrás das pernas); 2 SOLTA: o caixote vira adereço NESTE quadro (garage_crate em 238,232), meio agachado, mãos abertas. Depois: sit_down a partir do QUADRO 1 (o quadro 0 do sit_down é em pé) ou, para o vizinho, stand."},
	"sit_down": {"left": false, "fps": 10, "loop": false, "fr": "STD", "who": ["disc"],
		"note": "Discípulo em camadas: as mesmas poses do john_sit_down. 0 baixa o braço; 1 dobra os joelhos; 2 quadril encosta no caixote; 3 sentado (= sit_rest q0). O caixote é adereço, atrás."},
	"sit_rest": {"left": false, "fps": 3, "loop": true, "fr": "STD", "who": ["disc"],
		"note": "Discípulo em camadas: a pose parada de mentor sentado no caixote (assento a 17 px do chão), antebraços nos joelhos, mãos nuas, olhando o saco. Respiração de 1 px nos ombros (quadros 1-2). Mesmas poses do john_sit_rest."},
	"stand_up": {"left": false, "fps": 10, "loop": false, "fr": "STD", "who": ["john"],
		"note": "Levanta do caixote: o john_sit_down de trás para frente (0 sentado ... 3 em pé)."},
	"pick_duffel": {"left": false, "fps": 10, "loop": false, "fr": "DUFF", "grab_frame": 4, "who": ["john"],
		"note": "No ponto de sentar (254,252), virado para a DIREITA. 0-1 vira e dobra o tronco; 2 agachado, mão da frente na alça da bolsa (john_duffel em 268,242, atrás do caixote); 3 fecha a mão na alça; 4 PEGA (grab_frame: o adereço some; daqui em diante a bolsa está na folha), a bolsa pendurada na mão; 5 bolsa no ombro de trás (= walk_duffel parado). Segurar o quadro 5."},
	"walk_duffel": {"left": false, "fps": 10, "loop": true, "fr": "STD", "step_frames": [1, 4], "who": ["john"],
		"note": "Andar para a DIREITA sem luvas com a bolsa de lona no ombro de trás: a mão de perto segura a alça na frente do ombro, a bolsa balança 1 px atrás do quadril, o outro braço balança oposto à perna. Passada de 14 px, 48 px/s. 1 e 4 = pé pousa. O 'walk sem luvas' do John. Serve na academia e na garagem."},
	"look_room": {"left": true, "fps": 10, "loop": false, "fr": "STD", "hold_frame": 2, "who": ["john"],
		"note": "Em (380,246) virado para a ESQUERDA (folha própria, sem espelho), bolsa no ombro. 0 vira o corpo; 1 a cabeça percorre a sala (queixo 1 px acima); 2 parado olhando a sala, rosto smile leve. Segurar o quadro 2 durante as falas."},
	"nod": {"left": true, "fps": 10, "loop": false, "fr": "STD", "who": ["john"],
		"note": "Em (380,246) virado para a ESQUERDA, bolsa no ombro. UM aceno: a cabeça desce 1, 2, volta 1 (e o jogo volta ao look_room q2). Punhos parados."},
	"duck_out": {"left": false, "fps": 10, "loop": false, "fr": "STD", "step_frames": [3, 6], "who": ["john"],
		"note": "Só na garagem: passar por baixo da porta de enrolar SAINDO, virado para a DIREITA, de (410,236) a (423,221). Mesma silhueta do disciple_duck_under (0 dobra os joelhos; 1-3 cabeça passa embaixo da borda, topo da cabeça abaixo de y 171; 4 passo; 5 endireita; 6 de pé), sem mão na borda: a mão de perto segura a alça da bolsa."},
}

func fighter_poses(id: String, who: String) -> Array:
	match id:
		"carry_bag": return carry_bag_poses()
		"carry_bag_idle": return carry_bag_idle_poses()
		"hang_bag": return hang_bag_poses()
		"carry_crate": return carry_crate_poses()
		"put_crate": return put_crate_poses(who)
		"sit_down": return sit_poses("sit_down")
		"sit_rest": return sit_poses("sit_rest")
		"pick_duffel": return pick_duffel_poses()
		"walk_duffel": return walk_duffel_poses()
		"look_room": return look_room_poses()
		"nod": return nod_poses()
		"duck_out": return duck_out_poses()
	return []

func frame_spec(n: String) -> Array:
	match n:
		"BAGF": return BAGF
		"HANGF": return HANGF
		"PHOTOF": return PHOTOF
		"TREADF": return TREADF
		"DUFF": return DUFF
	return STD

func sheet_id(prefix: String, id: String, left: bool) -> String:
	return prefix + "_" + id + ("_left" if left else "")

func gen_john() -> void:
	var b := john_build()
	var sd_frames := []
	for id in FIGHTER:
		var e: Dictionary = FIGHTER[id]
		if not ("john" in e.who):
			continue
		var fr := frame_spec(e.fr)
		var sid := sheet_id("john", id, e.left)
		var frames := []
		var hands := []
		var anchors := []
		if id == "stand_up":
			var src: Array = sit_poses("sit_down")
			src.reverse()
			var i := 0
			for p in src:
				var r := render(b, p, "%s[%d]" % [sid, i], fr, false)
				frames.append(r.im)
				hands.append(r.hands)
				anchors.append(r.anchor)
				i += 1
		else:
			var i := 0
			for p in fighter_poses(id, "john"):
				var r := render(b, p, "%s[%d]" % [sid, i], fr, e.left)
				frames.append(r.im)
				hands.append(r.hands)
				anchors.append(r.anchor)
				i += 1
		var extra := {"who": "primeiro", "glove": "none", "light": "sem luz pintada (regra das folhas do John da 6b1: servem na academia e na garagem)"}
		for k in ["release_frame", "grab_frame", "step_frames", "hold_frame"]:
			if e.has(k):
				extra[k] = e[k]
		save_plain(sid, frames, hands, anchors, fr, Vector2.ZERO, e, "characters/", extra, "esquerda" if e.left else "direita")

func gen_disc() -> void:
	P.capture = true
	var b := disc_build()
	for id in FIGHTER:
		var e: Dictionary = FIGHTER[id]
		if not ("disc" in e.who):
			continue
		var fr := frame_spec(e.fr)
		var sid := sheet_id("disciple", id, e.left)
		var hands := []
		var frames := []
		var i := 0
		for p in fighter_poses(id, "disc"):
			var r := render(b, p, "%s[%d]" % [sid, i], fr, e.left)
			hands.append(r.hands)
			frames.append(r.im)
			i += 1
		var caps: Array = P.capture_take()
		if e.left:
			for c in caps:
				var a: Dictionary = c.anchor
				for k in ["head", "hip", "top"]:
					a[k] = [-float(a[k][0]), a[k][1]]
				a["head_rot"] = -float(a.head_rot)
				a["view"] = "34_left"
				a.erase("flipped")
				var W: int = (fr[0] as Vector2i).x
				for hk in ["head_box", "head_box_max"]:
					var hb: Array = a.get(hk, [])
					if hb.size() == 4:
						a[hk] = [W - 1 - (int(hb[0]) + int(hb[2]) - 1), hb[1], hb[2], hb[3]]
		lay_caps[sid] = caps
		sheets[sid] = frames
		var meta: Dictionary = P.save_layer_sheet(caps, out_dir + "disciple/", sid, "", cam_store, report)
		var piv: Vector2 = fr[1]
		var ent := layered_entry(sid, meta, {"fps": e.fps, "loop": e.loop, "pivot": [piv.x, piv.y], "facing": "esquerda" if e.left else "direita"})
		ent["action"] = id
		ent["scene_name"] = id
		ent["hands"] = hands
		ent["glove"] = "none"
		ent["mirror_ok"] = false
		ent["light"] = "sem luz pintada (como todas as folhas do discípulo)"
		ent["frames_note"] = ("VERSÃO VIRADA PARA A ESQUERDA (desenhada assim; não espelhar). " if e.left else "") + e.note
		for k in ["release_frame", "grab_frame", "step_frames", "hold_frame"]:
			if e.has(k):
				ent[k] = e[k]
		sprites[sid] = ent
	P.capture = false

func layered_entry(base: String, meta: Dictionary, extra: Dictionary) -> Dictionary:
	var d := "res://assets/sprites/disciple/"
	var top := 999
	var hx := 0.0
	for a in meta.anchors:
		var hb: Array = a.get("head_box_max", a.get("head_box", []))
		if hb.size() == 4 and int(hb[1]) < top:
			top = int(hb[1])
			hx = float(a.head[0])
	var heads := {}
	for cut in P.CUT_ORDER:
		heads[cut] = d + base + "_disc_head_" + cut + ".png"
	var ent := {
		"file": d + base + "_disc_body.png",
		"frame_size": meta.frame_size, "frames": meta.frames, "who": "discipulo",
		"layers": {"body": d + base + "_disc_body.png",
			"top": {"tank": d + base + "_disc_top_tank.png", "tee": d + base + "_disc_top_tee.png"},
			"socks": d + base + "_disc_socks.png",
			"head": heads,
			"band": d + base + "_disc_band.png",
			"front_mask": d + base + "_disc_front.png",
			"order": ["body", "top", "socks", "head", "band", "front_mask"]},
		"palette_swap": "disciple_palette",
		"anchors": meta.anchors.map(func(a): return {"head": a.head, "head_rot": a.head_rot, "hip": a.hip, "top": a.top,
			"tw": a.tw, "view": a.view, "face": a.face, "head_box": a.get("head_box", []), "head_box_max": a.get("head_box_max", []),
			"flipped": false}),
	}
	for k in extra:
		ent[k] = extra[k]
	if top < 999:
		var piv: Array = ent.get("pivot", [22, 67])
		ent["head_anchor"] = [hx, float(top - int(piv[1]) - 1)]
	return ent

## Entrada de folha inteira (sem camadas).
func save_plain(sid: String, frames: Array, hands: Array, anchors: Array, fr: Array, pos: Vector2, e: Dictionary, sub: String,
		extra: Dictionary, facing: String) -> void:
	sheets[sid] = frames
	P.strip(frames).save_png(out_dir + sub + sid + ".png")
	var piv: Vector2 = fr[1]
	var size: Vector2i = fr[0]
	var top := 999.0
	var hx := 0.0
	for a in anchors:
		if float(a.head[1]) < top:
			top = float(a.head[1])
			hx = float(a.head[0])
	var ent := {"file": "res://assets/sprites/%s%s.png" % [sub, sid], "frame_size": [size.x, size.y], "frames": frames.size(),
		"fps": e.fps, "pivot": [piv.x, piv.y], "loop": e.loop, "facing": facing, "action": e.get("scene", sid),
		"scene_name": e.get("scene", sid.trim_prefix("john_").trim_prefix("helper_").trim_suffix("_left")),
		"hands": hands, "head_anchor": [hx, top - 8.0],
		"head_by_frame": anchors.map(func(a): return [a.head[0], a.head[1]]),
		"mirror_ok": false,
		"frames_note": ("VERSÃO VIRADA PARA A ESQUERDA (desenhada assim; não espelhar). " if facing == "esquerda" else "") + str(e.note)}
	if pos != Vector2.ZERO:
		ent["pos"] = [pos.x, pos.y]
	for k in extra:
		ent[k] = extra[k]
	sprites[sid] = ent

# ================================================================ VIZINHO
const HELPER := {
	"carry_crate": {"left": true, "fps": 10, "loop": true, "fr": "STD", "step_frames": [1, 4],
		"note": "Vizinho (helper_2, na Carreira 1) andando para a ESQUERDA com o caixote nos dois braços. Mesmas poses do john_carry_crate_left."},
	"put_crate": {"left": false, "fps": 10, "loop": false, "fr": "STD", "release_frame": 2,
		"note": "Vizinho pousa o caixote em (254,252) e termina virado para a DIREITA. 0 girou; 1 dobra os joelhos e pousa atrás de si; 2 SOLTA (o caixote vira adereço). Depois: helper_stand (corte 4 do pedido: o vizinho não senta)."},
	"stand": {"left": false, "fps": 4, "loop": true, "fr": "STD",
		"note": "Parado virado para a DIREITA, mãos na cintura, respirando (ombros 1 px nos quadros 1-2). Para o helper_2 ao lado do caixote."},
	"stand_left": {"left": true, "fps": 4, "loop": true, "fr": "STD",
		"note": "Parado virado para a ESQUERDA, mãos na cintura, respirando. Para o vizinho da esteira em (440,250) (stand do pedido)."},
	"treadmill_bump": {"left": true, "fps": 10, "loop": false, "fr": "TREADF", "bump_frame": 3,
		"note": "Na soleira (430,222), virado para a ESQUERDA, esteira velha (treadmill_l0) ATRAVESSADA na frente do corpo, 86 px. 0-2 avança 1 px por quadro; 3 BATE nos dois batentes (bump_frame: esteira 1 px acima, tremida, rosto de esforço); 4-5 recua 3 px. O vizinho não sai do ponto: o avanço está dentro da folha. As pontas da esteira passam do vão da porta (404..451): quem cobre as pontas é o batente (ver relatório)."},
	"treadmill_stuck": {"left": true, "fps": 4, "loop": true, "fr": "TREADF",
		"note": "Parado atrás da esteira atravessada, olha um batente (q1), olha o outro (q2-q3, cabeça virada). Quase sem movimento."},
	"treadmill_turn": {"left": true, "fps": 10, "loop": false, "fr": "TREADF",
		"note": "Gira a esteira para passar de ponta: 0 atravessada (86 px); 1 meio giro (60); 2 (36); 3 de ponta, estreita (24 px, rolo na frente, painel lá atrás)."},
	"treadmill_carry": {"left": true, "fps": 10, "loop": true, "fr": "TREADF", "step_frames": [1, 4],
		"note": "Anda com a esteira de ponta na frente do corpo, de (430,222) a (440,250), virado para a ESQUERDA. 1 e 4 = pé pousa."},
	"treadmill_put": {"left": true, "fps": 10, "loop": false, "fr": "TREADF", "release_frame": 2,
		"note": "Em (440,250): 0 abaixa a esteira de ponta dobrando os joelhos; 1 ela gira de volta e encosta no chão no lugar (pivô 445,267); 2 a esteira vira o adereço da sala NESTE quadro (não está na folha), ele endireita."},
}

func helper_stand(dy: float) -> Dictionary:
	var o := stand_base(dy)
	o.merge({"toel": V(-2, 0), "toer": V(10, 0), "hl": V(-9, -32 + dy), "pl": V(-1, -0.2), "stl": "fist", "gkl": "side",
		"hr": V(11, -32 + dy), "pr": V(1, -0.2), "str": "fist", "gkr": "side", "kl": V(0.5, 0), "kr": V(0.6, 0)}, true)
	return G(o)

## Esteira atravessada: na frente do corpo, base 14 px acima do chão. dx = avanço; dy = tremida.
func tm_hold(o: Dictionary, im: Image, dx: float, dy: float, bottom := -14.0) -> Dictionary:
	var w := im.get_width()
	var h := im.get_height()
	var cx := 2.0 + dx
	var tl := V(cx - w / 2.0, bottom - h + dy).round()
	o["_props"] = [["after_left", im, tl, 65]]
	o["_keep_screen"] = true
	return o

func helper_poses(id: String) -> Array:
	match id:
		"carry_crate": return carry_crate_poses()
		"put_crate": return put_crate_poses("helper")
		"stand", "stand_left":
			var out := []
			for dy in [0.0, -1.0, -1.0, 0.0]:
				var g := helper_stand(0)
				up(g, dy, ["top", "head", "sl", "sr"])
				out.append(g)
			return out
		"treadmill_bump", "treadmill_stuck":
			var out := []
			var seq: Array = [[0, 0, ""], [1, 0, ""], [2, 0, ""], [3, -1, "effort"], [1, 0, ""], [0, 0, ""]] if id == "treadmill_bump" \
				else [[0, 0, ""], [0, 0, "front"], [0, 0, "back"], [0, 0, "back"]]
			for s in seq:
				var dx: float = s[0]
				var o := stand_base()
				o.merge({"hip": V(dx, -31), "top": V(1 + dx, -50), "head": V(1 + dx, -57), "sl": V(-7 + dx, -47), "sr": V(8 + dx, -47),
					"toel": V(-2 + (dx if dx < 2 else 2.0), 0), "toer": V(10 + dx, 0), "kl": V(1, 0), "kr": V(1, 0)}, true)
				if s[2] == "effort":
					o["face"] = "effort"
					o["head"] = (o.head as Vector2) + V(-1, 1)
				if s[2] == "front":
					o["head"] = (o.head as Vector2) + V(1, 0)
				if s[2] == "back":
					o["_look"] = true
				o.merge({"hl": V(-6 + dx, -28 + s[1]), "pl": V(-0.3, 1), "stl": "fist", "gkl": "up",
					"hr": V(10 + dx, -28 + s[1]), "pr": V(0.3, 1), "str": "fist", "gkr": "up"}, true)
				tm_hold(o, flipped(img_tm), dx, s[1])
				o["_fingers"] = [V(-6 + dx, -27 + s[1])]
				out.append(G(o))
			return out
		"treadmill_turn":
			var out := []
			var ims := [img_tm, tm_squeezed(60), tm_squeezed(36), img_tm_end]
			var hx := [[-6, 10], [-5, 9], [-4, 8], [-7, 12]]
			for i in 4:
				var o := stand_base()
				o.merge({"toel": V(-2, 0), "toer": V(10, 0), "kl": V(1, 0), "kr": V(1, 0), "tw": [0.0, -0.3, -0.5, 0.0][i]}, true)
				var bottom := -14.0 if i < 3 else -21.0
				var hy := -28.0 if i < 3 else -27.0
				o.merge({"hl": V(hx[i][0], hy), "pl": V(-0.3, 1), "stl": "fist", "gkl": "up",
					"hr": V(hx[i][1], hy), "pr": V(0.3, 1), "str": "fist", "gkr": "up"}, true)
				tm_hold(o, flipped(ims[i]), 0, 0, bottom)
				o["_fingers"] = [V(hx[i][0], hy + 1)]
				out.append(G(o))
			return out
		"treadmill_carry":
			var out := []
			for r in walk_rows(0.5):
				var o: Dictionary = r
				var top: Vector2 = o.top
				var bob := top.y + 50.0
				o.merge({"hl": V(-7, -27 + bob), "pl": V(-0.3, 1), "stl": "fist", "gkl": "up",
					"hr": V(12, -27 + bob), "pr": V(0.3, 1), "str": "fist", "gkr": "up"}, true)
				o.erase("_ar")
				tm_hold(o, flipped(img_tm_end), 0, bob, -21.0)
				o["_fingers"] = [V(-7, -26 + bob)]
				out.append(G(o))
			return out
		"treadmill_put":
			var rel := TM_PIV - P_TM_END   # (5,17) na tela; na pose montada para a direita, x troca de sinal
			var f0 := {"hip": V(-1, -26), "top": V(1, -44), "head": V(2, -51), "sl": V(-6, -41), "sr": V(8, -41), "toel": V(-2, 0), "toer": V(10, 0),
				"kl": V(1, -0.2), "kr": V(1, -0.2), "hl": V(-7, -22), "pl": V(-0.3, 1), "stl": "fist", "gkl": "up", "hr": V(12, -22), "pr": V(0.3, 1), "str": "fist", "gkr": "up"}
			tm_hold(f0, flipped(img_tm_end), 0, 0, -15.0)
			f0["_fingers"] = [V(-7, -21)]
			var f1 := {"hip": V(-2, -24), "top": V(2, -41), "head": V(4, -48), "sl": V(-4, -38), "sr": V(10, -38), "toel": V(-2, 0), "toer": V(10, 0),
				"kl": V(1, -0.2), "kr": V(1, -0.2), "hl": V(-6, -21), "pl": V(-0.3, 1), "stl": "open", "gkl": "diagdown", "hr": V(13, -21), "pr": V(0.3, 1), "str": "open", "gkr": "diagdown"}
			var sq := tm_squeezed(70)
			var tl := V(-rel.x - 35, rel.y - 2 - 42)   # 2 px acima do chão final, centro no pivô da esteira
			f1["_props"] = [["under", flipped(sq), tl, 0]]
			f1["_keep_screen"] = true
			var f2 := stand_base()
			f2.merge({"toel": V(-2, 0), "toer": V(10, 0), "hl": V(-7, -29), "pl": ELB, "stl": "open", "hr": V(12, -30), "pr": ELB, "str": "open"}, true)
			return [G(f0), G(f1), G(f2)]
	return []

func gen_helper() -> void:
	var b := helper_build(false)
	var bl := helper_build(true)
	for id in HELPER:
		var e: Dictionary = HELPER[id]
		var fr := frame_spec(e.fr)
		var sid: String = "helper_" + id + ("_left" if e.left and not id.ends_with("_left") else "")
		var frames := []
		var hands := []
		var anchors := []
		var i := 0
		for p in helper_poses(id):
			var r := render(bl if p.get("_look", false) else b, p, "%s[%d]" % [sid, i], fr, e.left)
			frames.append(r.im)
			hands.append(r.hands)
			anchors.append(r.anchor)
			i += 1
		var extra := {"who": "vizinho", "glove": "none", "palette_variants": "helper_2",
			"light": "sem luz pintada (anda pela sala; como as folhas do John)"}
		for k in ["release_frame", "step_frames", "bump_frame"]:
			if e.has(k):
				extra[k] = e[k]
		if (id as String).begins_with("treadmill"):
			extra["carried"] = "treadmill_l0 (a esteira enferrujada da garagem), na orientação da treadmill_l0_side: painel à esquerda da tela"
		var e2 := e.duplicate()
		e2["scene"] = id.trim_suffix("_left")
		save_plain(sid, frames, hands, anchors, fr, Vector2.ZERO, e2, "characters/", extra, "esquerda" if e.left else "direita")

# ================================================================ conferências
func check_colors() -> void:
	# o helper_2 troca só a regata (gr0/gr1/gr2 -> r0/r1/r2): nenhuma outra coisa das folhas do vizinho pode usar gr*
	var grs := {}
	for n in ["gr0", "gr1", "gr2", "gr3"]:
		grs[(L.col(n) as Color).to_html(false)] = n
	var reds := {}
	for n in ["r0", "r1", "r2", "r3"]:
		reds[(L.col(n) as Color).to_html(false)] = n
	for sid in sheets:
		if not (sid as String).begins_with("helper_"):
			continue
		var bad := 0
		for im in sheets[sid]:
			for y in (im as Image).get_height():
				for x in (im as Image).get_width():
					var hx := (im as Image).get_pixel(x, y).to_html(false)
					if reds.has(hx):
						bad += 1
		if bad > 0:
			report.append("AVISO %s: %d px vermelhos (a troca do helper_2 ficaria ambígua)" % [sid, bad])

func helper2_swap() -> Dictionary:
	return {"#" + (L.col("gr0") as Color).to_html(false): "#" + (L.col("r0") as Color).to_html(false),
		"#" + (L.col("gr1") as Color).to_html(false): "#" + (L.col("r1") as Color).to_html(false),
		"#" + (L.col("gr2") as Color).to_html(false): "#" + (L.col("r2") as Color).to_html(false)}

func swap_img(im: Image, m: Dictionary) -> Image:
	var c: Image = im.duplicate()
	for y in c.get_height():
		for x in c.get_width():
			var hx := "#" + c.get_pixel(x, y).to_html(false)
			if m.has(hx):
				c.set_pixel(x, y, Color.html(m[hx]))
	return c

# ================================================================ mockups
var PAL6B2 := {}

func recolor(sel: Dictionary) -> Dictionary:
	var pb: Dictionary = PAL6B2
	var m := {}
	for fld in sel:
		var keys: Dictionary = pb["keys"][fld]
		var ramp := {}
		for o in pb.options[fld]:
			if o.id == sel[fld]:
				ramp = o.ramp
		for slot in keys:
			if ramp.has(slot):
				m[(keys[slot] as String).substr(1)] = Color.html(ramp[slot])
	return m

## Discípulo montado (o mesmo que o jogo faz). look: cut, top ("none"|"tank"|"tee"), socks, band, cores.
func disc_compose(sid: String, look: Dictionary) -> Array:
	var d := out_dir + "disciple/"
	var fw: int = int(sprites[sid].frame_size[0])
	var body: Array = P.frames_of(d + sid + "_disc_body.png", fw)
	var head: Array = P.frames_of(d + sid + "_disc_head_" + str(look.cut) + ".png", fw)
	var mask: Array = P.frames_of(d + sid + "_disc_front.png", fw)
	var top = P.frames_of(d + sid + "_disc_top_" + str(look.top) + ".png", fw) if look.top != "none" else null
	var socks = P.frames_of(d + sid + "_disc_socks.png", fw) if look.socks else null
	var band = P.frames_of(d + sid + "_disc_band.png", fw) if look.band else null
	var rc := recolor(look.colors)
	var out := []
	for q in body.size():
		out.append(P.compose_full(body[q], top[q] if top != null else null, socks[q] if socks != null else null, head[q],
			band[q] if band != null else null, mask[q], rc))
	return out

const LOOK_DEF := {"cut": "short", "top": "none", "socks": false, "band": false,
	"colors": {"skin": "skin_3", "hair_color": "brown", "shorts_color": "green"}}
const LOOK_ALT := {"cut": "bun", "top": "tee", "socks": true, "band": true,
	"colors": {"skin": "skin_5", "hair_color": "black", "shorts_color": "purple", "top_color": "yellow", "headband_color": "blue", "socks": "purple"}}
const LOOK_ALT2 := {"cut": "volume", "top": "tank", "socks": false, "band": false,
	"colors": {"skin": "skin_1", "hair_color": "copper", "shorts_color": "blue", "top_color": "black"}}

func xadrez(dst: Image, x: int, y: int, w: int, h: int, cell: int) -> void:
	for yy in range(0, h, cell):
		for xx in range(0, w, cell):
			L.R(dst, x + xx, y + yy, mini(cell, w - xx), mini(cell, h - yy), "g1" if ((xx / cell + yy / cell) % 2 == 0) else "g0")

## linhas: [titulo, nota, frames]; marca o pivô com um pixel amarelo.
func contato(linhas: Array, titulo: String, S: int, path: String) -> void:
	var gap := 6 + S
	var W := 600
	var H := 40
	for r in linhas:
		var fr: Array = r[2]
		var fw: int = (fr[0] as Image).get_width()
		var fh: int = (fr[0] as Image).get_height()
		W = maxi(W, 16 + fr.size() * (fw * S + gap) + 24 + fr.size() * (fw + 3))
		H += 22 + fh * S + 14
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, titulo, 10, 8, "y1", 2 if S > 1 else 1, "ink")
	var y := 34
	for r in linhas:
		var fr: Array = r[2]
		var fw: int = (fr[0] as Image).get_width()
		var fh: int = (fr[0] as Image).get_height()
		L.text(out, r[0], 10, y, "cream", 1, "ink")
		L.text(out, r[1], 14 + L.text_w(r[0], 1), y, "g2", 1, "ink")
		y += 14
		var x := 10
		for i in fr.size():
			xadrez(out, x, y, fw * S, fh * S, 4 * S)
			P.paste(out, P.scaled(fr[i], S), x, y)
			L.text(out, str(i), x + 2, y + 2, "white", 1, "ink")
			x += fw * S + gap
		x += 16
		for i in fr.size():
			L.R(out, x, y, fw, fh, "g1")
			P.paste(out, fr[i], x, y)
			x += fw + 3
		y += fh * S + 14
	out.save_png(path)

func row(sid: String) -> Array:
	var e: Dictionary = sprites[sid]
	return [sid, "  %d q, %d fps, quadro %dx%d, pivo (%d,%d)" % [int(e.frames), int(e.fps), int(e.frame_size[0]), int(e.frame_size[1]),
		int(e.pivot[0]), int(e.pivot[1])], sheets[sid]]

func mockups() -> void:
	var md := out_dir + "mock/"
	DirAccess.make_dir_recursive_absolute(md)
	var lo := []
	for sid in sprites:
		if (sid as String).begins_with("coach_"):
			lo.append(row(sid))
	contato(lo, "FASE 6C1 - OSMAR (3x; a direita 1x; luz dos tubos)", 3, md + "fase6c1_contato_osmar_x3.png")
	var lj := []
	for sid in sprites:
		if (sid as String).begins_with("john_"):
			lj.append(row(sid))
	contato(lj, "FASE 6C1 - JOHN (3x; a direita 1x; maos nuas)", 3, md + "fase6c1_contato_john_x3.png")
	var ld := []
	for sid in sprites:
		if (sid as String).begins_with("disciple_"):
			var e: Dictionary = sprites[sid]
			var info := "  %d q, %d fps, quadro %dx%d, pivo (%d,%d)" % [int(e.frames), int(e.fps), int(e.frame_size[0]), int(e.frame_size[1]), int(e.pivot[0]), int(e.pivot[1])]
			ld.append([sid, info + "  padrao (short, sem camisa)", disc_compose(sid, LOOK_DEF)])
			ld.append(["", "coque, camiseta amarela, faixa azul, meiao, skin_5", disc_compose(sid, LOOK_ALT)])
			ld.append(["", "volume, regata preta, skin_1, ruivo", disc_compose(sid, LOOK_ALT2)])
	contato(ld, "FASE 6C1 - DISCIPULO EM CAMADAS (3x; a direita 1x; 3 visuais montados como no jogo)", 3, md + "fase6c1_contato_discipulo_x3.png")
	var lh := []
	var sw := helper2_swap()
	for sid in sprites:
		if (sid as String).begins_with("helper_"):
			lh.append(row(sid))
			if not (sid as String).begins_with("helper_treadmill"):
				lh.append(["", "helper_2 (troca de paleta: regata vermelha)", (sheets[sid] as Array).map(func(im): return swap_img(im, sw))])
	contato(lh, "FASE 6C1 - VIZINHO (3x; a direita 1x)", 3, md + "fase6c1_contato_vizinho_x3.png")
	andar_esquerda(md)
	cena(md)

## Andar para a esquerda, 4x: as folhas _left novas lado a lado com o disciple_walk_bare_left de referência.
func andar_esquerda(md: String) -> void:
	var S := 4
	var linhas := [
		["disciple_walk_bare_left (referencia 6b1)", walk_ref()],
		["john_carry_bag_left", sheets["john_carry_bag_left"]],
		["disciple_carry_bag_left (coque, camiseta, faixa, meiao)", disc_compose("disciple_carry_bag_left", LOOK_ALT)],
		["john_carry_crate_left", sheets["john_carry_crate_left"]],
		["disciple_carry_crate_left (padrao)", disc_compose("disciple_carry_crate_left", LOOK_DEF)],
		["helper_carry_crate_left (helper_2)", (sheets["helper_carry_crate_left"] as Array).map(func(im): return swap_img(im, helper2_swap()))],
		["helper_treadmill_carry_left", sheets["helper_treadmill_carry_left"]],
	]
	var W := 0
	var H := 30
	for l in linhas:
		var fr: Array = l[1]
		W = maxi(W, 10 + fr.size() * ((fr[0] as Image).get_width() * S + 6))
		H += 14 + (fr[0] as Image).get_height() * S + 10
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "ANDAR PARA A ESQUERDA (4x), folhas _left desenhadas viradas (sem espelho no jogo). Braco solto oposto a perna; 1 e 4 = pe pousa", 6, 6, "y1", 1, "ink")
	var y := 26
	for l in linhas:
		var fr: Array = l[1]
		L.text(out, l[0], 6, y, "cream", 1, "ink")
		y += 12
		var x := 6
		for q in fr.size():
			var im: Image = fr[q]
			xadrez(out, x, y, im.get_width() * S, im.get_height() * S, 4 * S)
			P.paste(out, P.scaled(im, S), x, y)
			L.text(out, str(q), x + 3, y + 3, "white", 1, "ink")
			x += im.get_width() * S + 6
		y += (fr[0] as Image).get_height() * S + 10
	out.save_png(md + "fase6c1_andar_esquerda_x4.png")

func walk_ref() -> Array:
	var d := ROOT + "assets/sprites/disciple/"
	var body: Array = P.frames_of(d + "disciple_walk_bare_left_disc_body.png", 48)
	var head: Array = P.frames_of(d + "disciple_walk_bare_left_disc_head_short.png", 48)
	var mask: Array = P.frames_of(d + "disciple_walk_bare_left_disc_front.png", 48)
	var rc := recolor(LOOK_DEF.colors)
	var out := []
	for q in body.size():
		out.append(P.compose_full(body[q], null, null, head[q], null, mask[q], rc))
	return out

## Quadros da cena no fundo real (gym_bg), 1x e recorte 2x: A3 (chegada), A4/A6 (foto), A7, J3 (saída).
func cena(md: String) -> void:
	var bg: Image = P.load_png(ROOT + "assets/sprites/gym/gym_bg.png")
	var shadow: Image = P.load_png(ROOT + "assets/sprites/garage/floor_shadow.png")
	var mk := func() -> Image:
		var im: Image = L.blank(640, 360)
		L.R(im, 0, 0, 640, 360, "ink")
		P.paste(im, bg, 128, 18)
		return im
	var put := func(im: Image, sid: String, q: int, pos: Vector2, sh := true) -> void:
		var e: Dictionary = sprites[sid]
		var fr: Image = sheets[sid][q]
		if sid.begins_with("disciple_"):
			fr = disc_compose(sid, LOOK_ALT)[q]
		if sh:
			P.paste(im, shadow, int(pos.x) - 16, int(pos.y) - 5)
		P.paste(im, fr, int(pos.x) - int(e.pivot[0]), int(pos.y) - int(e.pivot[1]))
	var crate := func(im: Image) -> void:
		P.paste(im, img_crate, 238, 232)
	var quadros := []
	# A3: Osmar segurando a foto, John com o saco parado, discípulo não; caixote pousando; vizinho com a esteira
	var a3: Image = mk.call()
	put.call(a3, "coach_hold_photo", 0, P_COACH)
	put.call(a3, "helper_treadmill_bump_left", 3, V(430, 222))
	put.call(a3, "john_put_crate", 1, P_MENTOR)
	put.call(a3, "disciple_carry_bag_idle_left", 0, V(352, 262))
	quadros.append([a3, "A3 bump q3 + put_crate q1 + carry_bag_idle (disc)", Rect2i(150, 120, 330, 170)])
	var a4: Image = mk.call()
	put.call(a4, "coach_hang_photo", 4, P_COACH)
	crate.call(a4)
	put.call(a4, "disciple_sit_rest", 0, P_MENTOR, false)
	quadros.append([a4, "A4 hang_photo q4 (bate o prego) + disciple sit_rest", Rect2i(128, 118, 192, 136)])
	var a6: Image = mk.call()
	P.paste(a6, img_photo, int(PHOTO_TL.x), int(PHOTO_TL.y))
	put.call(a6, "coach_nudge_photo", 2, P_COACH)
	crate.call(a6)
	put.call(a6, "john_put_crate", 2, P_MENTOR, false)
	quadros.append([a6, "A6 nudge_photo q2 (foto reta de referencia)", Rect2i(128, 118, 192, 136)])
	var a5: Image = mk.call()
	P.paste(a5, img_photo, int(PHOTO_TL.x), int(PHOTO_TL.y))
	put.call(a5, "coach_look_photo", 2, P_COACH_BACK)
	quadros.append([a5, "A5 look_photo q2", Rect2i(128, 118, 192, 136)])
	var a7: Image = mk.call()
	put.call(a7, "coach_idle_gym", 0, P_COACH)
	put.call(a7, "john_hang_bag", 3, P_HANG)
	put.call(a7, "helper_treadmill_turn_left", 3, V(430, 222))
	quadros.append([a7, "A7 hang_bag q3 (argola no gancho) + treadmill_turn q3", Rect2i(200, 110, 300, 180)])
	var a7b: Image = mk.call()
	P.paste(a7b, img_bag_full, int(HOOK.x) - 20, int(HOOK.y))
	put.call(a7b, "john_hang_bag", 4, P_HANG)
	put.call(a7b, "helper_treadmill_put_left", 1, P_TM_END)
	quadros.append([a7b, "A7 hang_bag q4 (saco = objeto) + treadmill_put q1", Rect2i(200, 110, 300, 180)])
	var j1: Image = mk.call()
	crate.call(j1)
	P.paste(j1, img_duffel, int(DUFFEL_TL.x), int(DUFFEL_TL.y))
	put.call(j1, "john_pick_duffel", 3, P_MENTOR, false)
	quadros.append([j1, "J1 pick_duffel q3 (mao na alca da bolsa)", Rect2i(200, 160, 160, 100)])
	var j3: Image = mk.call()
	put.call(j3, "coach_talk_gym", 0, P_COACH)
	put.call(j3, "john_look_room_left", 2, V(380, 246))
	put.call(j3, "john_walk_duffel", 1, V(330, 248))
	quadros.append([j3, "J3 look_room_left q2 + walk_duffel q1", Rect2i(280, 150, 160, 110)])
	var cols := 2
	var cw := 340 * 2
	var chh := 180 * 2
	var rows := (quadros.size() + cols - 1) / cols
	var out: Image = L.blank(cols * (cw + 8), rows * (chh + 20))
	L.R(out, 0, 0, out.get_width(), out.get_height(), "d1")
	for i in quadros.size():
		var q: Array = quadros[i]
		var x := (i % cols) * (cw + 8)
		var y := (i / cols) * (chh + 20)
		L.text(out, q[1], x + 4, y + 4, "y1", 1, "ink")
		var r: Rect2i = q[2]
		var k := mini(cw / r.size.x, chh / r.size.y)
		P.paste(out, P.scaled((q[0] as Image).get_region(r), maxi(k, 1)), x, y + 16)
	out.save_png(md + "fase6c1_cena_x2.png")

# ================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0].trim_suffix("/") + "/"
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	P.use_keys()
	M = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	var m6: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "docs/arte/manifest-6b2-personagens.json"))
	PAL6B2 = m6.by_data_id.disciple_palette
	for d in ["characters", "disciple", "mock"]:
		DirAccess.make_dir_recursive_absolute(out_dir + d)
	load_props()
	gen_coach()
	gen_john()
	gen_disc()
	gen_helper()
	check_colors()
	var anims := {
		"coach": {"hold_photo": "coach_hold_photo", "hang_photo": "coach_hang_photo", "step_back": "coach_step_back",
			"look_photo": "coach_look_photo", "nudge_photo": "coach_nudge_photo", "idle@gym": "coach_idle_gym", "talk@gym": "coach_talk_gym"},
		"first_fighter": {"carry_bag": "john_carry_bag_left", "carry_bag_idle": "john_carry_bag_idle_left", "hang_bag": "john_hang_bag",
			"carry_crate": "john_carry_crate_left", "put_crate": "john_put_crate", "sit_down": "john_sit_down", "sit_rest": "john_sit_rest",
			"stand_up": "john_stand_up", "pick_duffel": "john_pick_duffel", "walk_duffel": "john_walk_duffel",
			"look_room": "john_look_room_left", "nod": "john_nod_left", "duck_out": "john_duck_out"},
		"disciple (current_player / mentor:seat / mentor:last)": {"carry_bag": "disciple_carry_bag_left", "carry_bag_idle": "disciple_carry_bag_idle_left",
			"hang_bag": "disciple_hang_bag", "carry_crate": "disciple_carry_crate_left", "put_crate": "disciple_put_crate",
			"sit_down": "disciple_sit_down", "sit_rest": "disciple_sit_rest", "walk_bare": "disciple_walk_bare (já existe)", "stand_bare": "disciple_stand_bare (já existe)"},
		"helper (esteira)": {"treadmill_bump": "helper_treadmill_bump_left", "treadmill_stuck": "helper_treadmill_stuck_left",
			"treadmill_turn": "helper_treadmill_turn_left", "treadmill_carry": "helper_treadmill_carry_left",
			"treadmill_put": "helper_treadmill_put_left", "stand": "helper_stand_left"},
		"helper_2 (caixote, Carreira 1; mesma folha com palette_variants.helper_2)": {"carry_crate": "helper_carry_crate_left",
			"put_crate": "helper_put_crate", "stand": "helper_stand",
			"sit_down": "CORTE 4 do pedido: o vizinho não senta (put_crate termina e ele fica em helper_stand)", "sit_rest": "CORTE 4"},
	}
	var doc := {
		"_sobre": "Fase 6c1 (Artista de Personagens): folhas de personagem da chegada à academia e da saída do John (docs/cutscenes/pedidos-6c1.md §1). Gerador: tools/art/make_sprites_fase6c1.gd + personagem_lib.gd. Todas sem luvas (mãos nuas), vista 3/4. Folhas '_left' são desenhadas viradas para a esquerda (não espelhar). Folhas com carga grande usam quadro maior: ver frame_size e pivot de cada uma (o pivô continua sendo o ponto dos pés). O discípulo segue o formato da 6b2 (camadas e paleta em by_data_id.disciple_palette / disciple_layers do manifest). A junção no manifest fica com o Diretor de Arte.",
		"sprites": sprites,
		"scene_anims_sugestao": anims,
		"palette_variants": {"helper_2": {"applies_to": "todas as folhas helper_* (só o helper_2 usa carry_crate/put_crate/stand)",
			"how": "Troca exata de cor por pixel (from -> to). Só a regata muda: verde (neighbor_1) -> vermelha. Nenhuma outra cor das folhas helper_* é verde ou vermelha (o gerador confere).",
			"swap": helper2_swap()}},
		"props_in_sheets": {
			"saco": "bag_l0_idle q0 (saco remendado), sempre, em qualquer nível comprado. Deitado = o corpo sem a argola girado 90 graus (tampa para a frente).",
			"caixote": "garage_crate (mesmas cores); em put_crate q1 está 2 px acima do lugar final (238,232).",
			"esteira": "treadmill_l0_idle (enferrujada, da garagem); meio giro = a mesma apertada na largura; de ponta = desenho próprio 24x30 com as mesmas cores.",
			"foto": "wall_photo_old endireitada (metade direita 1 px acima = a versão 'reta'). O Diretor de Arte pode usar a mesma conta para o quadro 0 do wall_photo_old_gym.",
			"bolsa": "Bolsa de lona do John 18x11 (mock/fase6c1_bolsa_ref.png): o john_duffel do Diretor de Arte deve ser este mesmo desenho para a troca do grab_frame não pular.",
		},
	}
	var f := FileAccess.open(out_dir + "manifest-6c1-personagens.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(doc, "\t"))
	f.close()
	img_duffel.save_png(out_dir + "mock/fase6c1_bolsa_ref.png")
	mockups()
	var fl := FileAccess.open(out_dir + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		fl.store_line(l)
	fl.store_line("---- conferência")
	for l in report:
		fl.store_line(l)
	fl.close()
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	for l in report:
		print(l)
	print("ok: %d folhas" % sprites.size())
	quit()
