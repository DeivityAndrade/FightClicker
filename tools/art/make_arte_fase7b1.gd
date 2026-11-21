extends SceneTree
## Fase 7b1 (Diretor de Arte): arte do Muay Thai. PLACEHOLDER gerado por código, tudo original.
##   godot --headless --path <worktree> --script res://tools/art/make_arte_fase7b1.gd            (grava sprites + mockups)
##   godot --headless --path <worktree> --script res://tools/art/make_arte_fase7b1.gd -- --no-assets   (só mockups)
## Depois: python tools/art/manifest_7b1.py (lê tools/art/fase7b1_sprites.json, que este script grava).
## Grava:
##   assets/sprites/equipment/kick_bag_l0|l1_idle|hit.png      saco comprido de chute no CENTRO (foco), pendurado baixo
##   assets/sprites/equipment/kick_bag_l0|l1_rest(_gym).png    saco deitado no canto da frente à esquerda (descanso, luz pintada)
##   assets/sprites/ui/icon_kick_bag(_locked|_locked_buyable).png, art_muay_thai(_9).png, art_card_muay_thai.png,
##     ui_art_card_header_muay_thai.png, ui_shin_mark.png, icon_shin.png, ui_banner_spin_kick.png,
##     icon_region_muay_thai(_9).png, skill_style_muay_thai.png, skill_shin_kick.png, skill_thai_oil.png, skill_thai_rope.png
##   assets/sprites/ui/map/map_tile_muay_thai.png, map_node_s|b_owned_orange.png, ui_map_region_label_muay_thai.png
##   docs/arte/mockups/fase7b1_*.png
## Textos dos letreiros = finais do Roteirista (fase7b1-textos.md). Se mudarem: trocar BANNER_TEXT/MARKS_TEXT e rodar de novo.

const BANNER_TEXT := "CHUTE RODADO!"    # final do Roteirista (docs/fases/fase7b1-textos.md, fight_spin_kick)
const MARKS_TEXT := "PERNA CHEIA!"      # final do Roteirista (fight_marks_full)

var ROOT := ""
var OUT := ""
var MOCK := ""
var NO_ASSETS := false
var L
var F := {}      # id -> Array[Image] (quadros)
var META := {}   # id -> {rel, frame_size, frames, fps, pivot}

# ------------------------------------------------------------------ pontos (iguais aos da 6d2)
const P_BAG := Vector2i(336, 190)        # gancho do saco comprido em foco (o saco de pancada pendura em 336,183)
const KB_FRAME := Vector2i(34, 80)
const KB_PIVOT := Vector2i(17, 0)
const KB_BODY := Vector2i(22, 68)        # corpo: 22 de largura, 68 de altura (y 200..267 na sala)
const KB_BODY_Y := 10
const P_REST := Vector2i(192, 318)       # canto da frente à esquerda = slot "art" da caixa (o mesmo do boneco)
const KR_FRAME := Vector2i(80, 28)
const KR_PIVOT := Vector2i(40, 25)
const P_FIGHTER := Vector2i(303, 272)
const KICK_POINT := Vector2i(326, 250)   # onde a canela encosta no saco (pose de chute do Artista de Personagens)
const VPX := 320.0
const LIGHT_C := Vector2(305, 90)
const GARAGE_LIGHTS := [
	[LIGHT_C, 300.0, 1.1, 3.6, 0.9, 1],
	[Vector2(34, 176), 150.0, 0.9, 1.9, 0.35, 0],
	[Vector2(540, 70), 170.0, 1.0, 2.0, 0.25, 0],
]
const TUBES := [Vector2i(218, 34), Vector2i(422, 34), Vector2i(104, 34), Vector2i(536, 34)]
const LOCK_GOLD := ["br2", "y0", "y1"]
const LOCK_GRAY := ["g0", "g1", "g2"]
## tom do Muay Thai: laranja de couro (anel do mapa, faixa do cartão, sombra do letreiro)
const MT := ["br0", "br1", "br2", "br3", "y0"]

func _init() -> void:
	ROOT = ProjectSettings.globalize_path("res://")
	if not ROOT.ends_with("/"):
		ROOT += "/"
	OUT = ROOT + "assets/sprites/"
	MOCK = ROOT + "docs/arte/mockups/"
	NO_ASSETS = OS.get_cmdline_user_args().has("--no-assets")
	L = load("res://tools/art/pixel_lib.gd").new()
	make_kick_bag()
	make_icons()
	make_hud()
	make_tree()
	if not NO_ASSETS:
		var f := FileAccess.open(ROOT + "tools/art/fase7b1_sprites.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(META, "\t", true))
		f.close()
	mock_room()
	mock_pieces()
	mock_reach()
	print("7b1: ", META.size(), " sprites", " (não gravados)" if NO_ASSETS else "", "; mockups em ", MOCK)
	quit()

# ================================================================== util
func strip(frames: Array) -> Image:
	var fw: int = frames[0].get_width()
	var fh: int = frames[0].get_height()
	var s: Image = L.blank(fw * frames.size(), fh)
	for i in frames.size():
		s.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	return s

func save_sheet(id: String, rel: String, frames: Array, fps: float, pivot: Vector2i) -> void:
	F[id] = frames
	META[id] = {"rel": rel, "frame_size": [frames[0].get_width(), frames[0].get_height()], "frames": frames.size(),
		"fps": fps, "pivot": [pivot.x, pivot.y]}
	if NO_ASSETS:
		return
	var path := OUT + rel
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	strip(frames).save_png(path)

func ol(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

func pmap(img: Image, x: int, y: int, rows: Array, leg: Dictionary) -> void:
	for j in rows.size():
		var r: String = rows[j]
		for i in r.length():
			var ch := r[i]
			if ch != "." and leg.has(ch):
				L.P(img, x + i, y + j, leg[ch])

func V(x, y) -> Vector2:
	return Vector2(x, y)

func capsule(img: Image, a: Vector2, b: Vector2, r: float, ramp: Array) -> void:
	var n := int(ceil(a.distance_to(b))) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(maxi(n, 1)))
		L.ellipse(img, p.x, p.y, r, r, ramp[1])
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(maxi(n, 1)))
		L.ellipse(img, p.x - r * 0.35, p.y - r * 0.35, maxf(r * 0.45, 0.6), maxf(r * 0.45, 0.6), ramp[2])

func bayer(x: int, y: int) -> float:
	return (L.BAYER[posmod(y, 4)][posmod(x, 4)] + 0.5) / 16.0

func grayed(src: Image) -> Image:
	var out: Image = src.duplicate()
	var ramp := ["d1", "d2", "g0", "g1"]
	var ink_hex: String = L.C.ink.to_html(false)
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a == 0.0 or c.to_html(false) == ink_hex:
				continue
			var lum := c.r * 0.3 + c.g * 0.55 + c.b * 0.15
			out.set_pixel(x, y, L.C[ramp[clampi(int(lum * ramp.size() * 1.05), 0, ramp.size() - 1)]])
	return out

func padlock(img: Image, x: int, y: int, body: Array, shackle := "st3") -> void:
	pmap(img, x, y, [
		"..kkk..",
		".kssskk",
		".ks.sk.",
		".ks.sk.",
		"kkkkkkk",
		"khhhhbk",
		"kbbkbbk",
		"kbbkbdk",
		"kdddddk",
		"kkkkkkk"], {"k": "ink", "s": shackle, "h": body[2], "b": body[1], "d": body[0]})

func load_png(p: String) -> Image:
	var im := Image.load_from_file(p)
	im.convert(Image.FORMAT_RGBA8)
	return im

func region_of(p: String, i: int, w: int, h: int) -> Image:
	return load_png(ROOT + p).get_region(Rect2i(i * w, 0, w, h))

func put(dst: Image, src: Image, pos: Vector2i, pivot: Vector2i) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), pos - pivot)

func put_k(dst: Image, src: Image, x: int, y: int, k: int) -> void:
	var s: Image = src.duplicate()
	s.resize(src.get_width() * k, src.get_height() * k, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(x, y))

func scaled(src: Image, k: int) -> Image:
	var s: Image = src.duplicate()
	s.resize(src.get_width() * k, src.get_height() * k, Image.INTERPOLATE_NEAREST)
	return s

# ------------------------------------------------------------------ luz (a mesma conta da 6d2)
func light_step(x: int, y: int, min_step: int) -> int:
	var best := -99
	for lt in GARAGE_LIGHTS:
		var cc: Vector2 = lt[0]
		var d := Vector2(x - cc.x, (y - cc.y) * float(lt[2])).length() / float(lt[1])
		var lf: float = float(lt[4]) - d * float(lt[3])
		var base := floorf(lf)
		var fr := clampf((lf - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
		var st := int(base) + (1 if fr > bayer(x, y) else 0)
		best = maxi(best, clampi(st, min_step, int(lt[5])))
	return best

func gym_step(x: int, y: int) -> int:
	var best := -9.0
	for t: Vector2i in TUBES:
		var d := Vector2(x - t.x, (y - t.y - 30) * 0.8).length() / 260.0
		best = maxf(best, 0.95 - d * 1.9)
	best -= clampf(float(y - 250) / 120.0, 0.0, 0.35)
	var base := floorf(best)
	var fr := clampf((best - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
	return clampi(int(base) + (1 if fr > bayer(x, y) else 0), -2, 1)

func lit(src: Image, topleft: Vector2i, kind: String) -> Image:
	var out: Image = src.duplicate()
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var st := light_step(x + topleft.x, y + topleft.y, -1) if kind == "garage" else mini(gym_step(x + topleft.x, y + topleft.y), 0)
			if st != 0:
				out.set_pixel(x, y, L.shade(c, st))
	return out

# ================================================================== saco comprido de chute
## Corpo 22x68. l0 = lona cor de couro cru remendada (feita em casa, chegou enrolada num tapete); l1 = vinil preto de
## academia com faixas laranja. Nos dois, a lona é GASTA na altura da canela (é ali que se chuta).
func kb_body(lv: int) -> Image:
	var w := KB_BODY.x
	var h := KB_BODY.y
	var b: Image = L.blank(w, h)
	if lv == 0:
		L.rrect(b, 0, 3, w, h - 3, "br3")
		L.R(b, 0, 5, 5, h - 9, "br2"); L.R(b, 0, 7, 2, h - 13, "br1")
		L.R(b, 15, 6, 3, h - 12, "y0"); L.R(b, 16, 8, 1, 12, "y1")
		L.R(b, 2, 0, w - 4, 4, "br1"); L.R(b, 2, 0, w - 4, 1, "br2"); L.R(b, 4, 1, 3, 1, "br3")
		L.R(b, 1, h - 4, w - 2, 3, "br2"); L.R(b, 3, h - 2, w - 6, 1, "br1")
		for yy in range(7, h - 5, 3):
			L.P(b, 9, yy, "br2")
		for ty in [9, 34]:
			L.R(b, 0, ty, w, 3, "cream"); L.R(b, 0, ty + 2, w, 1, "g3"); L.R(b, 0, ty, 4, 3, "g3")
			for xx in range(5, w, 4):
				L.P(b, xx, ty + 1, "g3")
		L.R(b, 11, 20, 7, 6, "st2"); L.R(b, 11, 20, 7, 1, "st3"); L.R(b, 11, 25, 7, 1, "st1"); L.P(b, 13, 22, "st3")
		for yy in range(44, 60):
			for xx in range(2, 15):
				if (xx * 3 + yy * 5) % 7 == 0:
					L.P(b, xx, yy, "y0")
				elif (xx + yy * 2) % 9 == 0:
					L.P(b, xx, yy, "br2")
	else:
		L.rrect(b, 0, 3, w, h - 3, "d2")
		L.R(b, 0, 5, 5, h - 9, "d1"); L.R(b, 0, 7, 2, h - 13, "ink")
		L.R(b, 15, 6, 3, h - 12, "g0"); L.R(b, 16, 8, 1, 14, "g2")
		L.R(b, 2, 0, w - 4, 4, "ink"); L.R(b, 2, 0, w - 4, 1, "d2")
		for xx in range(4, w - 3, 3):
			L.P(b, xx, 3, "g0")
		L.R(b, 1, h - 4, w - 2, 3, "d1")
		for ty in [8, 58]:
			L.R(b, 0, ty, w, 4, "br3"); L.R(b, 0, ty + 3, w, 1, "br2"); L.R(b, 0, ty, 5, 4, "br2"); L.R(b, 15, ty, 3, 1, "y0")
		# faixa vertical laranja com 3 marquinhas (as 3 marcas da perna)
		L.R(b, 10, 14, 3, 42, "br2"); L.R(b, 11, 14, 1, 42, "br3")
		for k in 3:
			L.R(b, 9, 22 + k * 9, 5, 2, "y0"); L.P(b, 9, 23 + k * 9, "br3")
		for yy in range(44, 57):
			for xx in range(2, 9):
				if (xx * 3 + yy * 5) % 7 == 0:
					L.P(b, xx, yy, "g0")
	return b

## lean = quanto o pé do saco vai para a direita (px); dent = afundado na altura da canela.
func kb_frame(lv: int, lean: int, dent: int) -> Image:
	var out: Image = L.blank(KB_FRAME.x, KB_FRAME.y)
	var px := KB_PIVOT.x
	L.ring(out, px, 3, 2.5, 2.5, 1, "st3")
	L.P(out, px, 0, "st2")
	var bx0 := px - KB_BODY.x / 2
	L.line(out, px, 5, bx0 + 3, KB_BODY_Y + 1, "st2")
	L.line(out, px, 5, bx0 + KB_BODY.x - 4, KB_BODY_Y + 1, "st2")
	var body := kb_body(lv)
	var sh: Image = L.blank(KB_BODY.x + 8, KB_BODY.y)
	for y in KB_BODY.y:
		var off := int(round(lean * float(y + KB_BODY_Y) / float(KB_BODY.y + KB_BODY_Y)))
		sh.blit_rect(body, Rect2i(0, y, KB_BODY.x, 1), Vector2i(2 + off, y))
	if dent > 0:
		for y in range(42, 62):
			var dd := int(round(dent * (1.0 - absf(y - 52) / 10.0)))
			if dd <= 0:
				continue
			var x0 := 0
			while x0 < sh.get_width() and sh.get_pixel(x0, y).a == 0.0:
				x0 += 1
			for x in range(x0, mini(x0 + dd, sh.get_width())):
				sh.set_pixel(x, y, Color(0, 0, 0, 0))
			if x0 + dd < sh.get_width():
				sh.set_pixel(x0 + dd, y, L.shade(sh.get_pixel(x0 + dd, y), -1))
	L.stamp(out, sh, bx0 - 2, KB_BODY_Y)
	return out

## Deitado de lado no chão (descanso): o topo de couro com as tiras e a corrente enrolada à esquerda.
func kb_lying(lv: int) -> Image:
	var img: Image = L.blank(KR_FRAME.x, KR_FRAME.y)
	L.ellipse_dither(img, 41, 25, 34, 2.6, "ink")
	var body := kb_body(lv)
	body.rotate_90(COUNTERCLOCKWISE)    # o brilho (lado direito) fica em cima
	var b2: Image = L.blank(KR_FRAME.x, KR_FRAME.y)
	b2.blit_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i(10, 3))
	# tiras do topo (à esquerda) caídas no chão
	L.line(b2, 9, 9, 5, 22, "st2"); L.line(b2, 9, 17, 6, 23, "st2")
	L.ring(b2, 5, 22, 2.0, 1.5, 1, "st3")
	var o: Image = L.outlined(b2)
	img.blend_rect(o, Rect2i(1, 1, KR_FRAME.x, KR_FRAME.y), Vector2i.ZERO)
	# corrente enrolada (sem contorno: elos soltos no chão)
	for p in [[1, 23], [3, 24], [5, 25], [8, 25], [10, 24], [12, 25], [2, 21], [4, 20]]:
		L.P(img, p[0], p[1], "st2")
		L.P(img, p[0] + 1, p[1], "st3")
	return img

func make_kick_bag() -> void:
	for lv in 2:
		var idle := []
		for le in [0, 1, 0, -1]:
			idle.append(kb_frame(lv, le, 0))
		save_sheet("kick_bag_l%d_idle" % lv, "equipment/kick_bag_l%d_idle.png" % lv, idle, 3.0, KB_PIVOT)
		var hit := []
		for s in [[5, 3], [3, 1], [-1, 0], [0, 0]]:
			hit.append(kb_frame(lv, s[0], s[1]))
		save_sheet("kick_bag_l%d_hit" % lv, "equipment/kick_bag_l%d_hit.png" % lv, hit, 12.0, KB_PIVOT)
		var rest := kb_lying(lv)
		save_sheet("kick_bag_l%d_rest" % lv, "equipment/kick_bag_l%d_rest.png" % lv, [lit(rest, P_REST - KR_PIVOT, "garage")], 0.0, KR_PIVOT)
		save_sheet("kick_bag_l%d_rest_gym" % lv, "equipment/kick_bag_l%d_rest_gym.png" % lv, [lit(rest, P_REST - KR_PIVOT, "gym")], 0.0, KR_PIVOT)

# ================================================================== ícones da arte e do aparelho
func icon_kick_bag() -> Image:
	var im: Image = L.blank(16, 16)
	L.R(im, 8, 0, 1, 2, "st2")
	L.line(im, 8, 2, 5, 4, "st2"); L.line(im, 8, 2, 11, 4, "st2")
	L.rrect(im, 5, 4, 7, 11, "br3")
	L.R(im, 5, 5, 2, 9, "br2"); L.R(im, 10, 5, 1, 8, "y0")
	L.R(im, 5, 4, 7, 1, "br1")
	L.R(im, 5, 6, 7, 1, "cream"); L.R(im, 5, 11, 7, 1, "cream")
	L.R(im, 6, 8, 3, 2, "y0")
	# risco de chute embaixo à esquerda
	L.P(im, 1, 12, "y1"); L.P(im, 2, 12, "y1"); L.P(im, 2, 10, "y1"); L.P(im, 3, 10, "y1")
	return ol(im)

## perna no chute de frente (teep): calção laranja, coxa subindo, canela deitada, faixa no tornozelo, pé em pé (sola para a frente)
func leg_kick(im: Image, ox: int, oy: int, shorts := true) -> void:
	var skin := ["sk0", "sk1", "sk2"]
	capsule(im, V(ox + 4, oy + 11), V(ox + 7, oy + 7), 2.0, skin)
	capsule(im, V(ox + 7, oy + 7), V(ox + 11, oy + 7), 1.7, skin)
	L.R(im, ox + 11, oy + 1, 2, 9, "sk1"); L.R(im, ox + 11, oy + 1, 1, 8, "sk2"); L.P(im, ox + 13, oy + 9, "sk0")
	L.R(im, ox + 13, oy + 8, 1, 2, "sk1"); L.P(im, ox + 12, oy + 1, "sk2")
	if shorts:
		capsule(im, V(ox + 1, oy + 14), V(ox + 4, oy + 11), 2.6, ["br1", "br3", "y0"])
		L.P(im, ox + 2, oy + 11, "y1")
	L.R(im, ox + 9, oy + 5, 2, 5, "cream"); L.R(im, ox + 9, oy + 9, 2, 1, "g3")

func art_muay_thai() -> Image:
	var im: Image = L.blank(16, 16)
	leg_kick(im, 0, 0)
	var o := ol(im)
	for p in [[15, 2], [15, 3], [15, 6], [15, 7], [15, 10], [15, 11]]:
		L.P(o, p[0], p[1], "y1")
	return o

func art_muay_thai_9() -> Image:
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		"......S..",
		"......s..",
		"......s..",
		"...SScss.",
		"..ssscs..",
		".as......",
		"aa.......",
		"a........",
		"........."], {"s": "sk1", "S": "sk2", "c": "cream", "a": "br3"})
	var big: Image = L.blank(11, 11)
	big.blit_rect(im, Rect2i(0, 0, 9, 9), Vector2i(1, 1))
	return L.outlined(big).get_region(Rect2i(2, 2, 9, 9))

func art_card() -> Image:
	var v: Image = L.blank(72, 56)
	L.R(v, 0, 0, 72, 56, "ink")
	L.R(v, 1, 1, 70, 54, "br0")
	for y in range(1, 55):
		for x in range(1, 71):
			var d := Vector2(x - 40, (y - 22) * 1.2).length()
			if d < 27 and bayer(x, y) < (1.0 - d / 27.0) * 1.2:
				v.set_pixel(x, y, L.C["br1"])
	L.R(v, 1, 46, 70, 9, "d1"); L.R(v, 1, 46, 70, 1, "d2")
	# corrente + saco comprido balançando depois do chute
	for y in range(1, 6):
		L.P(v, 46, y, "st2" if y % 2 == 0 else "st1")
	var kb := kb_frame(1, 4, 2)
	v.blend_rect(kb.get_region(Rect2i(0, 0, KB_FRAME.x, 52)), Rect2i(0, 0, KB_FRAME.x, 52), Vector2i(46 - KB_PIVOT.x, 4))
	# canela chegando da esquerda, com riscos (laranja = Muay Thai)
	var lg: Image = L.blank(16, 16)
	leg_kick(lg, 0, 0)
	var big := scaled(ol(lg), 2)
	v.blend_rect(big, Rect2i(0, 0, 32, 32), Vector2i(6, 18))
	for i in 3:
		L.R(v, 3, 40 - i * 4, 7 - i, 1, "y1")
	# a sombra do saco no chão
	L.ellipse_dither(v, 46, 50, 9, 1.5, "ink")
	return v

func card_header() -> Image:
	var hd: Image = L.blank(16, 14)
	L.R(hd, 0, 0, 16, 14, "ink")
	L.R(hd, 1, 1, 14, 12, "br1"); L.R(hd, 1, 1, 14, 1, "br2"); L.R(hd, 1, 11, 14, 2, "br0")
	return hd

func make_icons() -> void:
	var ik := icon_kick_bag()
	save_sheet("icon_kick_bag", "ui/icon_kick_bag.png", [ik], 0.0, Vector2i.ZERO)
	var base: Image = grayed(ik)
	for v in [["", LOCK_GRAY], ["_buyable", LOCK_GOLD]]:
		var img: Image = base.duplicate()
		L.R(img, 8, 6, 8, 10, Color(0, 0, 0, 0))
		padlock(img, 9, 6, v[1])
		save_sheet("icon_kick_bag_locked" + v[0], "ui/icon_kick_bag_locked%s.png" % v[0], [img], 0.0, Vector2i.ZERO)
	save_sheet("art_muay_thai", "ui/art_muay_thai.png", [art_muay_thai()], 0.0, Vector2i.ZERO)
	save_sheet("art_muay_thai_9", "ui/art_muay_thai_9.png", [art_muay_thai_9()], 0.0, Vector2i.ZERO)
	save_sheet("art_card_muay_thai", "ui/art_card_muay_thai.png", [art_card()], 0.0, Vector2i.ZERO)
	save_sheet("ui_art_card_header_muay_thai", "ui/ui_art_card_header_muay_thai.png", [card_header()], 0.0, Vector2i.ZERO)

# ================================================================== HUD: marcas na perna + letreiro
## Canela DELE (virado para a esquerda): joelho em cima, pé embaixo apontando para a esquerda, hematoma no meio.
const SHIN_ROWS := [
	"...kkkk..",
	"..kSSsdk.",
	"..kSssdk.",
	"..kssBdk.",
	"..ksBBdk.",
	"..kssBdk.",
	"..kssdk..",
	"..kssdk..",
	"kkkssdk..",
	"kSsssdk..",
	"kkkkkkk.."]

func shin_mark(state: int) -> Image:
	# 0 apagada, 1 acesa (marcou), 2 acendendo (clarão de 1 quadro), 3 cheia (piscar com PERNA CHEIA!)
	var im: Image = L.blank(11, 11)
	var leg := {}
	match state:
		0: leg = {"k": "ink", "S": "g0", "s": "d2", "d": "d1", "B": "d2"}
		1: leg = {"k": "ink", "S": "sk2", "s": "sk1", "d": "sk0", "B": "r1"}
		2: leg = {"k": "ink", "S": "white", "s": "y2", "d": "y1", "B": "y1"}
		3: leg = {"k": "r2", "S": "sk2", "s": "sk1", "d": "sk0", "B": "r2"}
	pmap(im, 1, 0, SHIN_ROWS, leg)
	if state == 1:
		L.P(im, 5, 4, "p0")
	if state == 3:
		L.P(im, 5, 4, "r3")
	return im

func icon_shin() -> Image:
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		"..kkkk...",
		"..kSsdk..",
		"..ksBdk..",
		"..kBBdk..",
		"..ksBdk..",
		"..kssdk..",
		"kkkssdk..",
		"kSsssdk..",
		"kkkkkkk.."], {"k": "ink", "S": "sk2", "s": "sk1", "d": "sk0", "B": "r1"})
	return im

func banner(txt := BANNER_TEXT, sc := 3, hh := 40) -> Image:
	var kw: int = L.text_w(txt, sc) + 8
	var im: Image = L.blank(kw, hh)
	L.text(im, txt, 4, 8 + sc, "br1", sc)
	L.text(im, txt, 4, 8, "y1", sc)
	var out := ol(im)
	for y in range(8, hh - 1):
		for x in kw:
			if out.get_pixel(x, y).is_equal_approx(L.C.y1) and y >= 8 + 3 * sc:
				out.set_pixel(x, y, L.C.y0)
	return out

func make_hud() -> void:
	var fr := []
	for s in 4:
		fr.append(shin_mark(s))
	save_sheet("ui_shin_mark", "ui/ui_shin_mark.png", fr, 0.0, Vector2i(5, 5))
	save_sheet("icon_shin", "ui/icon_shin.png", [icon_shin()], 0.0, Vector2i.ZERO)
	save_sheet("ui_banner_spin_kick", "ui/ui_banner_spin_kick.png", [banner()], 0.0, Vector2i(0, 0))
	var b: Image = F["ui_banner_spin_kick"][0]
	META["ui_banner_spin_kick"]["pivot"] = [b.get_width() / 2, 20]
	var pc := banner(MARKS_TEXT, 2, 28)
	save_sheet("ui_banner_marks_full", "ui/ui_banner_marks_full.png", [pc], 0.0, Vector2i(pc.get_width() / 2, 14))

# ================================================================== árvore: região MUAY THAI
func oct(img: Image, x: int, y: int, w: int, h: int, cut: int, c) -> void:
	for yy in h:
		var ins := maxi(0, maxi(cut - yy, cut - (h - 1 - yy)))
		L.R(img, x + ins, y + yy, w - 2 * ins, 1, c)

func add_pin(im: Image, x: int, y: int) -> void:
	L.ellipse(im, x + 2.5, y + 2.5, 3.0, 3.0, "ink")
	L.ellipse(im, x + 2.5, y + 2.5, 2.0, 2.0, "y0")
	L.P(im, x + 2, y + 2, "y1")
	L.P(im, x + 1, y + 1, "y2")
	L.P(im, x + 3, y + 3, "br2")

## cópias exatas de node_small / node_big da 5.4 (make_sprites_fase54.gd), só com o tom novo
func node_small(ring_out, ring_in, fill, fill_hi, pin := false) -> Image:
	var im: Image = L.blank(24, 24)
	oct(im, 0, 0, 24, 24, 6, "ink")
	oct(im, 1, 1, 22, 22, 5, ring_out)
	oct(im, 2, 2, 20, 20, 5, ring_in)
	oct(im, 3, 3, 18, 18, 4, fill)
	if fill_hi != null:
		L.R(im, 7, 3, 10, 1, fill_hi)
	if pin:
		add_pin(im, 18, 0)
	return im

func node_big(ring_out, ring_in, fill, fill_hi, pin := false, spikes = null) -> Image:
	var im: Image = L.blank(38, 38)
	var sp = spikes if spikes != null else ring_in
	for d in [[19, 0, 0, 1], [19, 37, 0, -1], [0, 19, 1, 0], [37, 19, -1, 0]]:
		for k in 4:
			var w := 7 - k * 2 if k < 3 else 1
			if d[2] == 0:
				L.R(im, d[0] - w / 2 - 1, d[1] + d[3] * k, w + 1, 1, "ink")
			else:
				L.R(im, d[0] + d[2] * k, d[1] - w / 2 - 1, 1, w + 1, "ink")
		for k in range(1, 3):
			var w2 := 5 - (k - 1) * 2
			if d[2] == 0:
				L.R(im, d[0] - w2 / 2 - 1 + 1, d[1] + d[3] * k, w2 - 1, 1, sp)
			else:
				L.R(im, d[0] + d[2] * k, d[1] - w2 / 2 - 1 + 1, 1, w2 - 1, sp)
	oct(im, 2, 2, 34, 34, 9, "ink")
	oct(im, 3, 3, 32, 32, 8, ring_out)
	oct(im, 4, 4, 30, 30, 8, ring_out)
	oct(im, 5, 5, 28, 28, 7, "ink")
	oct(im, 6, 6, 26, 26, 7, ring_in)
	oct(im, 7, 7, 24, 24, 6, fill)
	if fill_hi != null:
		L.R(im, 13, 7, 12, 1, fill_hi)
	if pin:
		add_pin(im, 28, 3)
	return im

func region_label() -> Image:
	var im: Image = L.blank(16, 13)
	L.R(im, 0, 0, 16, 13, "ink")
	L.R(im, 1, 1, 14, 11, "d1")
	L.R(im, 1, 1, 14, 1, "d2")
	L.R(im, 1, 1, 3, 11, "br2")
	L.R(im, 1, 1, 3, 1, "br3")
	return im

func hsh(x: int, y: int, s: int) -> float:
	var xx := posmod(x, 32)
	var yy := posmod(y, 32)
	var n: int = (xx * 374761393 + yy * 668265263 + s * 982451653) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	n = n ^ (n >> 16)
	return float(n % 10000) / 10000.0

## Ladrilho 32x32 da região: corda de cânhamo trançada (a das mãos do Muay Thai antigo), em fileiras que emendam.
func tile_muay_thai() -> Image:
	var im: Image = L.blank(32, 32)
	L.R(im, 0, 0, 32, 32, "br0")
	for row in 4:
		var y0 := row * 8
		for x in 32:
			for dy in 7:
				# trança: dois fios em S que se cruzam a cada 8 px (deslocados nas fileiras pares)
				var ph := posmod(x + (4 if row % 2 == 1 else 0), 8)
				var a := absf(float(dy) - 3.0 - 2.4 * sin(float(ph) / 8.0 * TAU))
				if a < 1.6:
					var c := "br2" if dy < 3 else "br1"
					if a < 0.6 and dy <= 3:
						c = "br3"
					L.P(im, x, y0 + dy, c)
				elif a < 2.6:
					L.P(im, x, y0 + dy, "br1")
		L.R(im, 0, y0 + 7, 32, 1, "ink")
	for y in 32:
		for x in 32:
			if hsh(x, y, 21) < 0.03:
				L.P(im, x, y, "br3")
	return im

## Região MUAY THAI: o mongkol (o cordão trançado da cabeça) em cima da corda da região
func icon_region() -> Image:
	var im: Image = L.blank(16, 16)
	L.R(im, 1, 11, 14, 4, "br1"); L.R(im, 1, 11, 14, 1, "br2")
	for x in range(1, 15, 3):
		L.P(im, x, 13, "br3"); L.P(im, x + 1, 12, "br2")
	L.ring(im, 8, 6, 6.0, 3.6, 1.6, "cream")
	L.ring(im, 8, 6, 6.0, 3.6, 0.7, "white")
	for p in [[3, 5], [5, 3], [8, 2], [11, 3], [13, 5], [12, 8], [4, 8], [8, 9]]:
		L.P(im, p[0], p[1], "br3")
	# as duas pontas caídas atrás
	L.line(im, 12, 8, 14, 13, "cream"); L.line(im, 13, 8, 15, 12, "g3")
	return ol(im)

func icon_region_9() -> Image:
	var im: Image = L.blank(9, 9)
	L.ring(im, 4, 3, 3.6, 2.3, 1.2, "cream")
	L.P(im, 1, 3, "br3"); L.P(im, 4, 1, "br3"); L.P(im, 7, 3, "br3"); L.P(im, 4, 5, "br3")
	L.P(im, 7, 5, "cream"); L.P(im, 8, 6, "cream")
	L.R(im, 0, 7, 9, 1, "br2")
	var big: Image = L.blank(11, 11)
	big.blit_rect(im, Rect2i(0, 0, 9, 9), Vector2i(1, 1))
	return L.outlined(big).get_region(Rect2i(2, 2, 9, 9))

## style_muay_thai "Canela de ferro" (crítico do clique cresce): canela de aço que estala no saco
func skill_style() -> Image:
	var im: Image = L.blank(16, 16)
	var steel := ["st1", "st2", "st3"]
	capsule(im, V(4, 13), V(10, 6), 2.1, steel)
	capsule(im, V(10, 6), V(13, 3), 1.3, ["sk0", "sk1", "sk2"])
	L.R(im, 9, 5, 2, 2, "cream")
	L.P(im, 6, 10, "white"); L.P(im, 8, 8, "white")
	L.R(im, 1, 13, 4, 2, "br3")
	var o := ol(im)
	# estalo (estrela de crítico) na ponta
	for p in [[13, 9], [14, 8], [12, 8], [13, 7], [13, 10], [11, 11], [15, 11]]:
		L.P(o, p[0], p[1], "y1")
	L.P(o, 13, 8, "y2")
	return o

## mt_shin "Chute na coxa" (marca a perna mais rápido): perna dele com 3 marcas e o risco do chute chegando
func skill_shin_kick() -> Image:
	var im: Image = L.blank(16, 16)
	L.R(im, 7, 0, 7, 5, "b1"); L.R(im, 7, 0, 2, 5, "b2")
	capsule(im, V(10, 6), V(10, 13), 2.6, ["sk0", "sk1", "sk2"])
	L.R(im, 6, 13, 6, 2, "sk1"); L.R(im, 6, 13, 6, 1, "sk2")
	for k in 3:
		L.R(im, 9, 6 + k * 3, 3, 2, "r1"); L.P(im, 10, 6 + k * 3, "r2")
	var o := ol(im)
	for p in [[1, 8], [2, 8], [3, 8], [4, 8], [2, 6], [3, 6], [4, 6], [2, 10], [3, 10], [4, 10]]:
		L.P(o, p[0], p[1], "y1")
	L.P(o, 5, 8, "y2")
	return o

## mt_oil "Óleo de massagem": frasco âmbar com rótulo e uma gota
func skill_oil() -> Image:
	var im: Image = L.blank(16, 16)
	L.R(im, 6, 1, 4, 2, "r1"); L.R(im, 6, 1, 4, 1, "r2")
	L.R(im, 7, 3, 2, 2, "br2")
	L.rrect(im, 4, 5, 8, 10, "br2")
	L.R(im, 5, 6, 2, 8, "br3"); L.R(im, 5, 6, 1, 3, "y1")
	L.R(im, 4, 9, 8, 4, "cream"); L.R(im, 4, 12, 8, 1, "g3")
	L.R(im, 6, 10, 4, 1, "r1")
	L.R(im, 13, 10, 2, 3, "y0"); L.P(im, 13, 9, "y0"); L.P(im, 13, 10, "y2")
	return ol(im)

## mt_rope "Corda na ponta do pé": corda de pular passando embaixo do pé na ponta
func skill_rope() -> Image:
	var im: Image = L.blank(16, 16)
	# corda (arco por cima) e manoplas
	for x in range(2, 14):
		var y := int(round(3.0 + pow((x - 7.5) / 5.5, 2.0) * 6.0))
		L.P(im, x, y, "r2")
	L.R(im, 1, 9, 2, 4, "d2"); L.R(im, 13, 9, 2, 4, "d2"); L.P(im, 1, 9, "g1"); L.P(im, 13, 9, "g1")
	# pé na ponta (tênis), calcanhar alto
	L.R(im, 7, 7, 3, 4, "sk1"); L.P(im, 7, 7, "sk2")
	L.R(im, 5, 10, 5, 3, "white"); L.R(im, 5, 12, 5, 1, "g3"); L.R(im, 8, 10, 2, 1, "br3")
	L.R(im, 4, 13, 3, 1, "g2")
	L.R(im, 2, 14, 12, 1, "r1")
	return ol(im)

func make_tree() -> void:
	var D := "ui/map/"
	save_sheet("map_tile_muay_thai", D + "map_tile_muay_thai.png", [tile_muay_thai()], 0.0, Vector2i.ZERO)
	save_sheet("map_node_s_owned_orange", D + "map_node_s_owned_orange.png", [node_small("br2", "br3", "d2", "g0", true)], 0.0, Vector2i(12, 12))
	save_sheet("map_node_b_owned_orange", D + "map_node_b_owned_orange.png", [node_big("br2", "br3", "d2", "g0", true)], 0.0, Vector2i(19, 19))
	save_sheet("ui_map_region_label_muay_thai", D + "ui_map_region_label_muay_thai.png", [region_label()], 0.0, Vector2i.ZERO)
	save_sheet("icon_region_muay_thai", "ui/icon_region_muay_thai.png", [icon_region()], 0.0, Vector2i.ZERO)
	save_sheet("icon_region_muay_thai_9", "ui/icon_region_muay_thai_9.png", [icon_region_9()], 0.0, Vector2i.ZERO)
	save_sheet("skill_style_muay_thai", "ui/skill_style_muay_thai.png", [skill_style()], 0.0, Vector2i.ZERO)
	save_sheet("skill_shin_kick", "ui/skill_shin_kick.png", [skill_shin_kick()], 0.0, Vector2i.ZERO)
	save_sheet("skill_thai_oil", "ui/skill_thai_oil.png", [skill_oil()], 0.0, Vector2i.ZERO)
	save_sheet("skill_thai_rope", "ui/skill_thai_rope.png", [skill_rope()], 0.0, Vector2i.ZERO)

# ================================================================== mockups
func chain(img: Image, pivot: Vector2i) -> void:
	var t := load_png(ROOT + "assets/sprites/equipment/bag_chain_tile.png")
	var y := 33
	while y < pivot.y:
		var hh := mini(6, pivot.y - y)
		img.blend_rect(t, Rect2i(0, 0, 4, hh), Vector2i(pivot.x - 1 - 1, y))
		y += 6

func person(img: Image, file: String, pos: Vector2i, pivot := Vector2i(22, 67)) -> void:
	var sh := load_png(ROOT + "assets/sprites/garage/floor_shadow.png")
	img.blend_rect(sh, Rect2i(0, 0, 32, 8), pos - Vector2i(16, 4))
	put(img, region_of(file, 0, 48, 72), pos, pivot)

func room(kind: String, focus: bool, lv: int, box := false) -> Image:
	var sfx := "_gym" if kind == "gym" else ""
	var img := load_png(ROOT + "assets/sprites/%s/%s_bg.png" % [kind, kind])
	if box:
		put(img, load_png(ROOT + "assets/sprites/box/box_big.png").get_region(Rect2i(0, 0, 76, 62)), P_REST, Vector2i(38, 58))
	elif not focus:
		put(img, F["kick_bag_l%d_rest%s" % [lv, sfx]][0], P_REST, KR_PIVOT)
	person(img, "assets/sprites/characters/neighbor_1_idle.png", Vector2i(72, 322))
	person(img, "assets/sprites/characters/neighbor_2_idle.png", Vector2i(126, 322))
	if focus:
		chain(img, P_BAG)
		put(img, F["kick_bag_l%d_idle" % lv][0], P_BAG, KB_PIVOT)
		person(img, "assets/sprites/characters/fighter_idle.png", P_FIGHTER)
	else:
		# foco no saco de pancada de sempre
		chain(img, Vector2i(336, 183))
		put(img, load_png(ROOT + "assets/sprites/equipment/bag_l%d_idle%s.png" % [lv, sfx]).get_region(Rect2i(0, 0, 40, 76)), Vector2i(336, 183), Vector2i(20, 0))
		person(img, "assets/sprites/characters/fighter_idle.png", P_FIGHTER)
	return img

func label(img: Image, s: String, x: int, y: int, c := "white") -> void:
	L.text(img, s, x, y, c, 1, "ink")

func mock_room() -> void:
	# 4 salas 1x: garagem foco / garagem descanso / academia foco (l1) / academia descanso (l1) + 2 com a caixa
	var W := 8 + 3 * 648
	var H := 8 + 2 * 384
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	var cells := [["GARAGEM: SACO COMPRIDO EM FOCO (L0)", room("garage", true, 0)],
		["GARAGEM: DESCANSO, DEITADO NO CANTO (L0)", room("garage", false, 0)],
		["GARAGEM: CHEGOU EM CAIXA GRANDE (SLOT ART 192,318)", room("garage", false, 0, true)],
		["ACADEMIA: EM FOCO (L1 - CHUTE BAIXO)", room("gym", true, 1)],
		["ACADEMIA: DESCANSO (L1)", room("gym", false, 1)],
		["ACADEMIA: CAIXA", room("gym", false, 1, true)]]
	for i in cells.size():
		var x := 8 + (i % 3) * 648
		var y := 8 + (i / 3) * 384
		board.blit_rect(cells[i][1], Rect2i(0, 0, 640, 360), Vector2i(x, y + 16))
		label(board, cells[i][0], x, y + 4, "y1")
	board.save_png(MOCK + "fase7b1_saco_sala.png")
	# zoom 3x do centro e do canto
	var z: Image = L.blank(8 + 4 * 300, 8 + 2 * 340)
	L.R(z, 0, 0, z.get_width(), z.get_height(), "d1")
	var crops := [[cells[0][1], Rect2i(260, 150, 100, 130), "GARAGEM FOCO 3X"], [cells[3][1], Rect2i(260, 150, 100, 130), "ACADEMIA FOCO 3X"],
		[cells[1][1], Rect2i(96, 270, 150, 60), "GARAGEM DESCANSO 2X"], [cells[4][1], Rect2i(96, 270, 150, 60), "ACADEMIA DESCANSO 2X"]]
	for i in crops.size():
		var r: Rect2i = crops[i][1]
		var k := 3 if i < 2 else 2
		var c: Image = (crops[i][0] as Image).get_region(r)
		var x := 8 + i * 300
		put_k(z, c, x, 24, k)
		label(z, crops[i][2], x, 8, "y1")
	# folha de contato 4x dos quadros do saco
	var y0 := 440
	var x := 8
	for id in ["kick_bag_l0_idle", "kick_bag_l0_hit", "kick_bag_l1_idle", "kick_bag_l1_hit"]:
		var s := strip(F[id])
		put_k(z, s, x, y0 + 14, 2)
		label(z, id.to_upper(), x, y0, "cream")
		x += s.get_width() * 2 + 12
	z.save_png(MOCK + "fase7b1_saco_zoom.png")

func mock_pieces() -> void:
	var W := 1200
	var H := 420
	var b: Image = L.blank(W, H)
	L.R(b, 0, 0, W, H, "d1")
	L.text(b, "FASE 7B1 - MUAY THAI: ICONES (4X), MARCAS NA PERNA, CARTAO E NOS DA ARVORE", 8, 6, "y1", 1)
	var items := [["art_muay_thai", "ARTE 16"], ["art_muay_thai_9", "ARTE 9"], ["icon_kick_bag", "SACO 16"], ["icon_kick_bag_locked", "TRANCADO"],
		["icon_kick_bag_locked_buyable", "DA PRA COMPRAR"], ["icon_shin", "PERNA 9"], ["icon_region_muay_thai", "REGIAO 16"],
		["icon_region_muay_thai_9", "REGIAO 9"], ["skill_style_muay_thai", "CANELA FERRO"], ["skill_shin_kick", "CHUTE COXA"],
		["skill_thai_oil", "OLEO"], ["skill_thai_rope", "CORDA PE"]]
	var x := 10
	for it in items:
		var im: Image = F[it[0]][0]
		L.R(b, x - 2, 22, im.get_width() * 4 + 4, im.get_height() * 4 + 4, "d2")
		put_k(b, im, x, 24, 4)
		L.text(b, it[1], x, 92, "g3", 1)
		x += maxi(im.get_width() * 4, L.text_w(it[1], 1)) + 18
	# marcas na perna: 4 quadros + HUD de 3 marcas (0,1,2,3 marcadas, cheia)
	var y := 110
	L.text(b, "UI_SHIN_MARK 11X11: APAGADA / ACESA / ACENDENDO / CHEIA (PISCAR)", 10, y, "cream", 1)
	x = 10
	for f in 4:
		put_k(b, F["ui_shin_mark"][f], x, y + 12, 4)
		x += 52
	L.text(b, "HUD 2X (PASSO 12 PX):", 230, y + 14, "g3", 1)
	for n in 5:
		var row: Image = L.blank(40, 11)
		for k in 3:
			var st := 0
			if n == 4:
				st = 3
			elif k < n:
				st = 1
			if n == 3 and k == 2:
				st = 2
			row.blend_rect(F["ui_shin_mark"][st], Rect2i(0, 0, 11, 11), Vector2i(k * 12, 0))
		put_k(b, row, 230 + n * 96, y + 26, 2)
	L.text(b, "0 MARCAS     1 MARCA      2 (MANCA)    3 (ACENDENDO)  CHEIA", 230, y + 52, "g3", 1)
	# cartão + faixa
	y = 196
	L.text(b, "CARTAO DA ARTE (72X56) E FAIXA", 10, y, "cream", 1)
	put_k(b, F["art_card_muay_thai"][0], 10, y + 12, 2)
	var hd: Image = L.blank(150, 18)
	var h0: Image = F["ui_art_card_header_muay_thai"][0]
	# 9-slice simples da faixa
	for yy in 14:
		for xx in 150:
			var sx: int = xx if xx < 2 else (15 if xx >= 148 else 2 + (xx - 2) % 12)
			var sy := yy
			hd.set_pixel(xx, yy, h0.get_pixel(clampi(sx, 0, 15), sy))
	L.text(hd, "MUAY THAI", 20, 4, "white", 1, "ink")
	hd.blend_rect(F["art_muay_thai_9"][0], Rect2i(0, 0, 9, 9), Vector2i(5, 2))
	put_k(b, hd, 170, y + 12, 2)
	L.text(b, "UI_BANNER_MARKS_FULL (1X E 2X)", 520, y, "cream", 1)
	var pcf: Image = F["ui_banner_marks_full"][0]
	put_k(b, pcf, 520, y + 12, 1)
	put_k(b, pcf, 520 + pcf.get_width() + 12, y + 12, 2)
	# nós da árvore
	y = 330
	L.text(b, "NOS DA REGIAO MUAY THAI (COMPRADO, ANEL LARANJA) E O CHAO DE CORDA", 10, y - 14, "cream", 1)
	var tile: Image = F["map_tile_muay_thai"][0]
	var ground: Image = L.blank(420, 80)
	for yy in 80:
		for xx in 420:
			ground.set_pixel(xx, yy, tile.get_pixel(xx % 32, yy % 32))
	var nodes := [["map_node_b_owned_orange", "skill_style_muay_thai", Vector2i(30, 40)], ["map_node_b_owned_orange", "skill_shin_kick", Vector2i(110, 40)],
		["map_node_s_owned_orange", "skill_thai_oil", Vector2i(190, 40)], ["map_node_s_owned_orange", "skill_thai_rope", Vector2i(260, 40)]]
	for nd in nodes:
		var fr: Image = F[nd[0]][0]
		ground.blend_rect(fr, Rect2i(Vector2i.ZERO, fr.get_size()), nd[2] - fr.get_size() / 2)
		ground.blend_rect(F[nd[1]][0], Rect2i(0, 0, 16, 16), nd[2] - Vector2i(8, 8))
	# plaquinha
	var lab: Image = F["ui_map_region_label_muay_thai"][0]
	var lw: int = 21 + L.text_w("MUAY THAI", 1) + 4
	var pl: Image = L.blank(lw, 13)
	for yy in 13:
		for xx in lw:
			var sx: int = xx if xx < 4 else (15 if xx >= lw - 1 else 4 + (xx - 4) % 11)
			pl.set_pixel(xx, yy, lab.get_pixel(sx, yy))
	pl.blend_rect(F["icon_region_muay_thai_9"][0], Rect2i(0, 0, 9, 9), Vector2i(5, 2))
	L.text(pl, "MUAY THAI", 17, 3, "white", 1)
	ground.blend_rect(pl, Rect2i(Vector2i.ZERO, pl.get_size()), Vector2i(310, 10))
	put_k(b, ground.get_region(Rect2i(0, 0, 420, 80)), 10, y - 2, 1)
	put_k(b, ground.get_region(Rect2i(0, 0, 210, 40)), 440, y - 2, 2)
	b.save_png(MOCK + "fase7b1_pecas_x4.png")

## Conferência: o chute rodado cabe entre os pivôs (296 / 346, pés em y 318) nas duas arenas, e o letreiro lê.
func mock_reach() -> void:
	var arenas := [["BORRACHARIA (AMADORES)", "arena"], ["LIGA DA ACADEMIA (TONHAO, KID)", "arena_league"]]
	var W := 8 + 3 * 456
	var H := 24 + 368 + 270 + 150
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	var ply := region_of("assets/sprites/fight/fight_player_idle.png", 0, 112, 104)
	var opp := region_of("assets/sprites/opponents/opp_gym_1/opp_gym_1_idle.png", 0, 112, 104)
	var used := ply.get_used_rect()
	var tall := 98 - used.position.y          # altura do lutador (pés no pivô y 98)
	var hip := Vector2i(296, 318 - int(round(tall * 0.50)))
	var leg := int(round(tall * 0.50))         # quadril até a sola
	var head := Vector2i(346 - int(round(4 * 1.04)), 318 - int(round(80 * 1.04)))
	var jaw := head + Vector2i(-2, 8)
	var ribs := Vector2i(346 - 12, 318 - int(round(tall * 0.62)))
	var dist := Vector2(hip).distance_to(Vector2(jaw))
	print("chute rodado: altura ", tall, " quadril ", hip, " perna ", leg, " queixo dele ", jaw, " distância ", dist)
	var bn: Image = F["ui_banner_spin_kick"][0]
	for i in 2:
		var pre: String = arenas[i][1]
		var sc := load_png(ROOT + "assets/sprites/fight/%s_bg.png" % pre)
		var crowd := load_png(ROOT + "assets/sprites/fight/%s_crowd_back.png" % pre).get_region(Rect2i(0, 0, 640, 100))
		sc.blend_rect(crowd, Rect2i(0, 0, 640, 100), Vector2i(0, 180))
		var shadow := load_png(ROOT + "assets/sprites/fight/fight_shadow.png")
		for p in [Vector2i(296, 318), Vector2i(346, 318)]:
			sc.blend_rect(shadow, Rect2i(0, 0, 48, 8), p - Vector2i(24, 4))
		put(sc, ply, Vector2i(296, 318), Vector2i(56, 98))
		put(sc, opp, Vector2i(346, 318), Vector2i(56, 98))
		var front := load_png(ROOT + "assets/sprites/fight/%s_crowd_front.png" % pre).get_region(Rect2i(0, 0, 640, 48))
		sc.blend_rect(front, Rect2i(0, 0, 640, 48), Vector2i(0, 312))
		var clean: Image = sc.duplicate()
		# letreiro em 2x no mesmo ponto do K.O.! e do FINALIZOU! (320,118)
		var b2 := scaled(bn, 2)
		sc.blend_rect(b2, Rect2i(Vector2i.ZERO, b2.get_size()), Vector2i(320, 118) - b2.get_size() / 2)
		var x := 8 + i * 648
		board.blit_rect(sc, Rect2i(0, 0, 640, 360), Vector2i(x, 24))
		label(board, arenas[i][0] + " - LETREIRO 2X EM (320,118)", x, 10, "y1")
		# diagrama 2x do alcance
		var dg: Image = clean.get_region(Rect2i(216, 200, 200, 130))
		var g: Image = scaled(dg, 2)
		var o := Vector2i(216, 200)
		# quadros 112x104 (pontilhado) dos dois
		for fr in [Vector2i(296, 318), Vector2i(346, 318)]:
			var r := Rect2i(fr - Vector2i(56, 98) - o, Vector2i(112, 104))
			for t in range(0, 112, 2):
				dot(g, (r.position.x + t) * 2, r.position.y * 2, "g2"); dot(g, (r.position.x + t) * 2, (r.end.y - 1) * 2, "g2")
			for t in range(0, 104, 2):
				dot(g, r.position.x * 2, (r.position.y + t) * 2, "g2"); dot(g, (r.end.x - 1) * 2, (r.position.y + t) * 2, "g2")
		# arco do alcance da perna a partir do quadril (perna + 6 px de quadril que sobe/gira)
		var reach := leg + 6
		for a in range(-90, 20):
			var p := Vector2(hip) + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * reach
			dot(g, int((p.x - o.x) * 2), int((p.y - o.y) * 2), "y1")
		for a in range(-90, 20, 3):
			var p := Vector2(hip) + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * leg
			dot(g, int((p.x - o.x) * 2), int((p.y - o.y) * 2), "g3")
		# alvos: queixo e costela dele; quadril do jogador
		for t in [[jaw, "r3"], [ribs, "r3"], [hip, "gr3"]]:
			var tv: Vector2i = t[0]
			var q: Vector2i = (tv - o) * 2
			L.R(g, q.x - 3, q.y - 3, 7, 7, "ink"); L.R(g, q.x - 2, q.y - 2, 5, 5, t[1])
		# pivôs
		for pv in [296, 346]:
			L.R(g, (pv - o.x) * 2 - 1, (318 - o.y) * 2 - 8, 2, 16, "white")
		board.blit_rect(g, Rect2i(0, 0, 400, 260), Vector2i(x, 24 + 368))
		var lx := x + 410
		var ly := 24 + 372
		var lines := ["ALCANCE (2X)", "PONTILHADO: QUADROS 112X104", "BRANCO: PIVOS 296 E 346", "VERDE: QUADRIL DO JOGADOR",
			"CINZA: PERNA ESTICADA (%d PX)" % leg, "AMARELO: PERNA + 6 PX DE QUADRIL", "VERMELHO: QUEIXO E COSTELA DELE",
			"QUADRIL ATE O QUEIXO: %d PX" % int(round(dist))]
		for k in lines.size():
			label(board, lines[k], lx, ly + k * 12, "cream" if k > 0 else "y1")
	# recorte do letreiro 2x nas duas arenas, lado a lado, com o K.O.! e o FINALIZOU! para comparar
	var y := 24 + 368 + 270
	label(board, "LETREIROS 2X NAS DUAS ARENAS (RECORTE): K.O.! / FINALIZOU! / " + BANNER_TEXT, 8, y, "y1")
	var ko := load_png(ROOT + "assets/sprites/ui/ui_banner_ko.png")
	var sub := load_png(ROOT + "assets/sprites/ui/ui_banner_submission.png")
	for i in 2:
		var bg := load_png(ROOT + "assets/sprites/fight/%s_bg.png" % arenas[i][1])
		for j in 3:
			var s: Image = bg.duplicate()
			var bb: Image = scaled([ko, sub, bn][j], 2)
			s.blend_rect(bb, Rect2i(Vector2i.ZERO, bb.get_size()), Vector2i(320, 118) - bb.get_size() / 2)
			var crop := s.get_region(Rect2i(96, 88, 448, 60))
			board.blit_rect(crop, Rect2i(0, 0, 448, 60), Vector2i(8 + j * 456, y + 14 + i * 66))
	board.save_png(MOCK + "fase7b1_chute_rodado_alcance.png")

func dot(img: Image, x: int, y: int, c) -> void:
	L.R(img, x, y, 2, 2, c)
