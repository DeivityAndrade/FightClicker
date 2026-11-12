extends SceneTree
## Arte PLACEHOLDER da Fase 5.1 — Garagem clara + caixa da escola.
## Tudo gerado por código, paleta de docs/arte/direcao-visual.md (fonte da verdade: tools/art/pixel_lib.gd).
## Rodar headless a partir de uma pasta com um project.godot vazio (não importa nada no projeto):
##   godot --headless --path <pasta_tmp> --quit-after 200 --script E:/Fightclicker/tools/art/make_sprites_fase51.gd
##   ... -- --teste=<pasta>/     grava tudo em <pasta>/sprites e <pasta>/mock, sem tocar no projeto (para conferir antes)
## RODAR POR ÚLTIMO (depois dos geradores das Fases 2 a 5): ele corrige o prego da corda nos fundos e as posições no manifest.
## Saída:
##   assets/sprites/garage/garage_bg.png, gym/gym_bg.png        RETOCADOS: some o prego antigo (352,72), entra o gancho novo (296,166)
##   assets/sprites/equipment/rope_lN_idle(_gym).png            corda pendurada com a luz do ponto novo
##   assets/sprites/garage/tape_mark_*(_hi|_dim), ghost_*(_dim), mark_padlock   marcas que se leem SEM plaquinha
##   assets/sprites/box/box_big|box_small, fx_box_*             caixa da escola (4 estados), lascas, estouro e brilho
##   assets/sprites/ui/school_symbol_*, ui_box_tag, ui_box_stamp, icon_fame*   etiqueta, carimbo, símbolo provisório, Fama em rosa
##   assets/sprites/manifest.json                               ACRESCENTA (relê o arquivo na hora de gravar)
##   docs/arte/mockups/fase51_*.png
## Não toca em personagens nem nos quadros rope_lN_swing / swing_back (Artista de Personagens).

const ROOT := "E:/Fightclicker/"
const RES := "res://assets/sprites/"
var OUT := ROOT + "assets/sprites/"
var MOCK := ROOT + "docs/arte/mockups/"
var TESTE := false

var L
var M := {}
var F := {}
var SHEETS := []
var OLD := {}

const P_ROOM := Vector2i(128, 18)
const OLD_NAIL := Vector2i(352, 72)        # prego do desenho original (Fase 2), perto do teto
const HOOK := Vector2i(296, 166)           # gancho novo: altura do ombro de quem está encostado na parede
const P_BAG_CENTER := Vector2i(336, 183)
const P_BAG_LEFT := Vector2i(258, 160)
const P_TM_RIGHT := Vector2i(445, 267)
const P_FIGHTER_BAG := Vector2i(303, 272)
const P_LAMP := Vector2i(300, 32)
const P_NEIGHBOR := [Vector2i(176, 284), Vector2i(220, 258), Vector2i(488, 286)]
const P_UNCLE := [Vector2i(455, 236), Vector2i(398, 230)]
const P_COACH := Vector2i(394, 280)
const SB_WALL := Vector2i(436, 46)
const GD_REST := Vector2i(228, 283)
const TUBES := [Vector2i(218, 34), Vector2i(422, 34)]
const VPX := 320.0

# Caixa: tamanho do corpo, quadro e pivô (meio da base, no chão)
const BOX := {
	"big": {"w": 52, "h": 32, "top": 9, "frame": Vector2i(76, 62), "pivot": Vector2i(38, 58)},
	"small": {"w": 28, "h": 19, "top": 6, "frame": Vector2i(48, 42), "pivot": Vector2i(24, 38)},
}
# Onde cada caixa espera (pivô = meio da base). Fora da faixa do alvo central (x 280..362).
const BOX_POS := {
	"treadmill": ["big", Vector2i(445, 268)],
	"jump_rope": ["small", Vector2i(258, 244)],
	"speed_bag": ["small", Vector2i(228, 283)],
	"grappling_dummy": ["big", Vector2i(228, 283)],
	"glove": ["small", Vector2i(386, 288)],
}

func xy(v: Vector2i) -> Array:
	return [v.x, v.y]

# ================================================================ util
func strip(frames: Array) -> Image:
	var fw: int = frames[0].get_width()
	var fh: int = frames[0].get_height()
	var s: Image = L.blank(fw * frames.size(), fh)
	for i in frames.size():
		s.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	return s

func save_sheet(id: String, rel: String, frames: Array, fps: float, pivot: Vector2i, info := {}, contact := true) -> void:
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
	if contact:
		SHEETS.append([id, s, frames[0].get_width()])

## Contorno ink sem crescer o quadro (o desenho precisa ter 1 px de folga).
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

func spr(id: String) -> Dictionary:
	if M.has(id):
		return M[id]
	return OLD.get("sprites", {}).get(id, {})

func load_png(res_path: String) -> Image:
	var img := Image.load_from_file(ROOT + res_path.replace("res://", ""))
	img.convert(Image.FORMAT_RGBA8)
	return img

func frame_of(id: String, i := 0) -> Image:
	if F.has(id):
		return F[id][i]
	var e := spr(id)
	var img := load_png(str(e.file))
	var fw: int = int(e.frame_size[0])
	var fh: int = int(e.frame_size[1])
	return img.get_region(Rect2i(i * fw, 0, fw, fh))

func put(dst: Image, id: String, i: int, pos: Vector2i) -> void:
	var fr: Image = frame_of(id, i)
	var pv: Array = spr(id).get("pivot", [0, 0])
	dst.blend_rect(fr, Rect2i(Vector2i.ZERO, fr.get_size()), pos - Vector2i(int(pv[0]), int(pv[1])))

func nine(dst: Image, src: Image, x: int, y: int, w: int, h: int, m: Dictionary) -> void:
	var sw := src.get_width()
	var sh := src.get_height()
	var l: int = int(m.left)
	var r: int = int(m.right)
	var t: int = int(m.top)
	var bo: int = int(m.bottom)
	for yy in h:
		var sy := yy
		if yy >= h - bo:
			sy = sh - (h - yy)
		elif yy >= t:
			sy = t + (yy - t) % maxi(sh - t - bo, 1)
		for xx in w:
			var sx := xx
			if xx >= w - r:
				sx = sw - (w - xx)
			elif xx >= l:
				sx = l + (xx - l) % maxi(sw - l - r, 1)
			var c := src.get_pixel(clampi(sx, 0, sw - 1), clampi(sy, 0, sh - 1))
			if c.a > 0.0 and x + xx >= 0 and y + yy >= 0 and x + xx < dst.get_width() and y + yy < dst.get_height():
				dst.set_pixel(x + xx, y + yy, c)

func ns(dst: Image, id: String, x: int, y: int, w: int, h: int) -> void:
	nine(dst, frame_of(id), x, y, w, h, spr(id).nine_slice)

func save_x(img: Image, path: String, k: int) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	b.save_png(path)

func scaled(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

# ================================================================ luz (iguais às das Fases 2 e 5)
func garage_lit(img: Image, topleft: Vector2i, min_step := -2) -> Image:
	var c: Image = img.duplicate()
	L.light(c, Rect2i(0, 0, c.get_width(), c.get_height()), Vector2(305, 90) - Vector2(topleft), 300.0, 1.1, 3.6, min_step, 1, 0.9)
	return c

func gym_step(x: int, y: int) -> int:
	var best := -9.0
	for t in TUBES:
		var d := Vector2(x - t.x, (y - t.y - 30) * 0.8).length() / 260.0
		best = maxf(best, 0.95 - d * 1.9)
	best -= clampf(float(y - 250) / 120.0, 0.0, 0.35)
	var base := floorf(best)
	var fr := clampf((best - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
	var b: float = (L.BAYER[y % 4][x % 4] + 0.5) / 16.0
	return clampi(int(base) + (1 if fr > b else 0), -2, 1)

func gym_lit(img: Image, topleft: Vector2i) -> Image:
	var c: Image = img.duplicate()
	for y in c.get_height():
		for x in c.get_width():
			var px := c.get_pixel(x, y)
			if px.a == 0.0:
				continue
			var st := mini(gym_step(x + topleft.x, y + topleft.y), 0)
			if st != 0:
				c.set_pixel(x, y, L.shade(px, st))
	return c

# ================================================================ corda: gancho novo nos fundos + corda pendurada
## Apaga o prego antigo copiando a parede de 4 px ao lado e desenha o gancho novo. Pode rodar várias vezes.
func patch_bg(id: String, gym: bool) -> void:
	var img := load_png(str(OLD.sprites[id].file))
	var o := OLD_NAIL - P_ROOM
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			img.set_pixel(o.x + dx, o.y + dy, img.get_pixel(o.x + dx - 6, o.y + dy))
	var h := HOOK - P_ROOM
	if gym:
		# chapinha de aço parafusada no barrado, com gancho
		L.R(img, h.x - 3, h.y - 4, 7, 6, "ink")
		L.R(img, h.x - 2, h.y - 3, 5, 4, "st2")
		L.R(img, h.x - 2, h.y - 3, 5, 1, "st3")
		L.P(img, h.x - 2, h.y - 3, "white"); L.P(img, h.x + 2, h.y, "st0"); L.P(img, h.x - 2, h.y, "st0")
		L.R(img, h.x - 1, h.y - 1, 3, 3, "ink")
		L.P(img, h.x, h.y - 1, "st3"); L.P(img, h.x, h.y, "white")
	else:
		# prego grosso e torto, enferrujado, com a sombra dele na parede
		L.R(img, h.x - 2, h.y - 2, 5, 4, "ink")
		L.P(img, h.x - 1, h.y - 1, "br3"); L.P(img, h.x, h.y - 1, "st3"); L.P(img, h.x + 1, h.y - 1, "br2")
		L.P(img, h.x - 1, h.y, "br1"); L.P(img, h.x, h.y, "br2"); L.P(img, h.x + 1, h.y, "br1")
		L.P(img, h.x + 3, h.y, "d2"); L.P(img, h.x + 3, h.y + 1, "d2"); L.P(img, h.x + 2, h.y + 2, "d2")
		# três riscos de giz ao lado (contagem de pulos), desbotados
		for i in 3:
			L.R(img, h.x + 14 + i * 3, h.y + 2, 1, 5, "g3")
		L.line(img, h.x + 13, h.y + 6, h.x + 21, h.y + 2, "g3")
	var e: Dictionary = OLD.sprites[id]
	var rel := str(e.file).replace(RES, "")
	DirAccess.make_dir_recursive_absolute((OUT + rel).get_base_dir())
	img.save_png(OUT + rel)
	F[id] = [img]
	var e2: Dictionary = e.duplicate(true)
	e2["note"] = str(e.note).replace("prego da corda", "gancho da corda em (296,166)") + " Fase 5.1: o prego antigo (352,72) saiu; o gancho da corda fica em (296,166), na altura do ombro."
	if str(e.note).find("Fase 5.1") >= 0:
		e2["note"] = e.note
	M[id] = e2

func rope_idle(level: int) -> Image:
	var img: Image = L.blank(18, 40)
	if level == 0:
		L.ring(img, 9, 16, 8, 14, 2, "cream")
		L.ring(img, 9, 16, 7, 13, 1, "g3")
		L.R(img, 2, 27, 2, 8, "cream"); L.R(img, 2, 27, 1, 8, "g3"); L.R(img, 1, 34, 3, 2, "g3")
		L.R(img, 14, 28, 2, 9, "cream"); L.R(img, 14, 28, 1, 9, "g3"); L.R(img, 14, 36, 3, 2, "g3")
		L.R(img, 0, 11, 3, 5, "br3"); L.R(img, 0, 11, 1, 5, "br2"); L.P(img, 1, 13, "st2")
	else:
		L.ring(img, 9, 15, 7, 13, 2, "b2")
		L.ring(img, 9, 15, 6, 12, 1, "b1")
		L.R(img, 3, 25, 2, 9, "b2"); L.R(img, 3, 25, 1, 9, "b1"); L.R(img, 2, 33, 3, 4, "d2")
		L.R(img, 13, 26, 2, 9, "b2"); L.R(img, 13, 26, 1, 9, "b1"); L.R(img, 13, 34, 3, 4, "d2")
	var o: Image = L.blank(18, 40)
	L.stamp(o, img.get_region(Rect2i(0, 1, 17, 38)), 1, 1)
	return o

func rope_idle_gym(level: int) -> Image:
	var img: Image = L.blank(18, 40)
	var rc: Array = ["r1", "r2"] if level == 0 else ["st1", "st3"]
	L.ring(img, 9, 14, 7, 12, 2, rc[1])
	L.ring(img, 9, 14, 6, 11, 1, rc[0])
	var hc: Array = ["d1", "d2"] if level == 0 else ["br1", "br3"]
	L.R(img, 2, 24, 3, 11, hc[1]); L.R(img, 2, 24, 1, 11, hc[0]); L.R(img, 2, 33, 3, 1, "st2")
	L.R(img, 13, 25, 3, 11, hc[1]); L.R(img, 13, 25, 1, 11, hc[0]); L.R(img, 13, 34, 3, 1, "st2")
	var o: Image = L.blank(18, 40)
	L.stamp(o, img.get_region(Rect2i(0, 1, 17, 38)), 1, 1)
	return o

func make_rope() -> void:
	patch_bg("garage_bg", false)
	patch_bg("gym_bg", true)
	var tl := HOOK - Vector2i(9, 0)
	var n_g := ["Corda de varal com nó e prendedor (nível visual 0)", "Corda de verdade, sem nó (nível visual 1)"]
	var n_a := ["Corda de PVC vermelha com cabos pretos (academia, nível visual 0)", "Corda de aço encapada com cabos de madeira (academia, nível visual 1)"]
	for lv in 2:
		save_sheet("rope_l%d_idle" % lv, "equipment/rope_l%d_idle.png" % lv, [garage_lit(rope_idle(lv), tl, -1)], 0, Vector2i(9, 0), {
			"positions": {"prego": xy(HOOK)}, "layer": "frente_do_fundo", "z": -40,
			"note": n_g[lv] + ", pendurada no gancho da parede (296,166: altura do ombro de quem está encostado na parede). Aparece quando a corda NÃO está em foco. Pivô = gancho. Luz já aplicada para este ponto."})
		save_sheet("rope_l%d_idle_gym" % lv, "equipment/rope_l%d_idle_gym.png" % lv, [gym_lit(rope_idle_gym(lv), tl)], 0, Vector2i(9, 0), {
			"positions": {"prego": xy(HOOK)}, "layer": "frente_do_fundo", "z": -40,
			"note": n_a[lv] + ", no gancho de aço do barrado (mesmo ponto da garagem, 296,166). Luz dos tubos aplicada."})

# ================================================================ marcas sem texto
## Paletas da fita: [face, borda, sombra]. normal = crepe; hi = acesa (hover / dá para comprar); dim = apagada (trancada).
const TAPE := {"": ["cream", "g3", "g0"], "_hi": ["white", "y1", "g0"], "_dim": ["g1", "g0", "d1"]}
var TP: Array = TAPE[""]

func tape_h(img: Image, x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1 + 1):
		var torn := (x == x0 or x == x1)
		if not torn:
			L.P(img, x, y + 2, TP[2])
		for t in 2:
			if torn and t == (0 if (x + y) % 2 == 0 else 1):
				continue
			L.P(img, x, y + t, TP[0] if t == 0 else TP[1])

func tape_v(img: Image, x: int, y0: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		var torn := (y == y0 or y == y1)
		if not torn:
			L.P(img, x + 2, y, TP[2])
		for t in 2:
			if torn and t == (0 if (x + y) % 2 == 0 else 1):
				continue
			L.P(img, x + t, y, TP[0] if t == 0 else TP[1])

func tape_slant(img: Image, xa: float, ya: int, xb: float, yb: int) -> void:
	for y in range(ya, yb + 1):
		var t := float(y - ya) / float(maxi(yb - ya, 1))
		var x := int(round(lerpf(xa, xb, t)))
		var torn := (y == ya or y == yb)
		if not torn or (x + y) % 2 == 0:
			L.P(img, x, y, TP[0])
		L.P(img, x + 1, y, TP[1])

## Cantoneira de fita (canto reforçado): deixa o retângulo legível mesmo com os lados falhados.
func tape_corner(img: Image, x: int, y: int, sx: int, sy: int) -> void:
	for i in 5:
		L.P(img, x + i * sx, y, TP[0]); L.P(img, x + i * sx, y + sy, TP[1])
		L.P(img, x, y + i * sy, TP[0]); L.P(img, x + sx, y + i * sy, TP[1])

func mark_rope() -> Image:
	var r: Image = L.blank(26, 48)
	tape_h(r, 1, 9, 4)
	tape_h(r, 17, 24, 4)
	tape_v(r, 1, 3, 44)
	tape_v(r, 22, 3, 44)
	tape_h(r, 1, 24, 44)
	return r

func mark_treadmill() -> Image:
	var img: Image = L.blank(96, 18)
	var front := 14
	var back := 1
	var k := float(back + 254 + 28) / float(front + 254 + 28)
	var ox := P_TM_RIGHT.x - 48
	var fl := 402.0 - ox
	var fr := 488.0 - ox
	var bl := 320.0 + (402.0 - 320.0) * k - ox
	var br := 320.0 + (488.0 - 320.0) * k - ox
	tape_h(img, int(fl) - 1, int(fl + fr) / 2 + 2, front)
	tape_h(img, int(fl + fr) / 2 - 3, int(fr) + 1, front + 1)
	tape_h(img, int(bl), int(bl) + 30, back)
	tape_h(img, int(bl) + 36, int(br) + 1, back)
	tape_slant(img, bl, back + 1, fl, front)
	tape_slant(img, br - 1, back + 1, fr - 1, front)
	return img

func mark_speed_bag() -> Image:
	var w: Image = L.blank(56, 60)
	tape_h(w, 1, 20, 2); tape_h(w, 28, 54, 2)
	tape_v(w, 1, 1, 57); tape_v(w, 52, 1, 57)
	tape_h(w, 1, 30, 56); tape_h(w, 34, 54, 56)
	return w

func mark_dummy() -> Image:
	var pv := Vector2i(38, 19)
	var g: Image = L.blank(76, 22)
	var front := pv.y - 1
	var back := front - 16
	var k := float(GD_REST.y - 16 + 28) / float(GD_REST.y + 28)
	var x0s := GD_REST.x - pv.x
	var fl := float(GD_REST.x - 34 - x0s)
	var fr := float(GD_REST.x + 34 - x0s)
	var bl := VPX + (GD_REST.x - 34 - VPX) * k - x0s
	var brr := VPX + (GD_REST.x + 34 - VPX) * k - x0s
	tape_h(g, int(fl) - 1, int(fl + fr) / 2 + 2, front)
	tape_h(g, int(fl + fr) / 2 - 3, int(fr) + 1, front + 1)
	tape_h(g, int(bl), int(bl) + 24, back)
	tape_h(g, int(bl) + 30, int(brr) + 1, back)
	tape_slant(g, bl, back + 1, fl, front)
	tape_slant(g, brr - 1, back + 1, fr - 1, front)
	return g

## Silhueta "riscada": contorno do aparelho em tracejado claro com sombra escura (lê em parede clara e em chão escuro)
## + miolo em pontilhado ralo. Sem cadeado e sem texto: o desenho diz QUAL aparelho vai ali.
func ghost_of(src: Image, dimmed: bool) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out: Image = L.blank(w, h)
	var light: String = "g1" if dimmed else "white"
	var fill: String = "d1" if dimmed else "ink"
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a == 0.0:
				continue
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h or src.get_pixel(nx, ny).a == 0.0:
					edge = true
			if edge:
				if (x + y * 2) % 5 < 3:
					out.set_pixel(x, y, L.C[light])
				else:
					out.set_pixel(x, y, L.C["ink"])
			elif (x % 2 == 0) and (y % 2 == 0):
				out.set_pixel(x, y, L.C[fill])
	return out

func make_marks() -> void:
	var defs := [
		["tape_mark_rope", Callable(self, "mark_rope"), Vector2i(13, 2), {"positions": {"prego": xy(HOOK)}, "layer": "frente_do_fundo", "z": -40}, "na parede em volta do gancho da corda"],
		["tape_mark_treadmill", Callable(self, "mark_treadmill"), Vector2i(48, 13), {"positions": {"lado_direito": xy(P_TM_RIGHT)}, "layer": "chao", "z": -30, "sort_y": 255}, "no chão onde a esteira vai ficar"],
		["tape_mark_speed_bag", Callable(self, "mark_speed_bag"), Vector2i(28, 4), {"positions": {"parede": xy(SB_WALL)}, "layer": "frente_do_fundo", "z": -41}, "na parede onde a plataforma da pera vai ficar"],
		["tape_mark_grappling_dummy", Callable(self, "mark_dummy"), Vector2i(38, 19), {"positions": {"canto": xy(GD_REST)}, "layer": "chao", "z": -30, "sort_y": 266}, "no chão onde o tatame do boneco vai ficar"],
	]
	var sfx_note := {"": "Estado normal (dá para comprar, mouse fora).", "_hi": "Estado ACESO: mouse em cima (a dica aparece) ou pulso lento de 'dá para comprar' (alternar com o normal a 2 fps).", "_dim": "Estado APAGADO: trancado (pede outro aparelho antes). Usar com ghost_*_dim e o mark_padlock."}
	for d in defs:
		for suf in ["", "_hi", "_dim"]:
			TP = TAPE[suf]
			var img: Image = (d[1] as Callable).call()
			var info: Dictionary = (d[3] as Dictionary).duplicate(true)
			info["note"] = "Fase 5.1: contorno de fita crepe %s, SEM plaquinha e sem texto. %s O aparelho se lê pela silhueta ghost_* desenhada por cima. Mesmo quadro e pivô de antes." % [d[4], sfx_note[suf]]
			var folder := "garage/"
			save_sheet(str(d[0]) + suf, folder + str(d[0]) + suf + ".png", [img], 0, d[2], info)
	TP = TAPE[""]
	var gdefs := [
		["ghost_rope", rope_idle(0), Vector2i(9, 0), {"positions": {"prego": xy(HOOK)}, "layer": "frente_do_fundo", "z": -39}, "corda pendurada"],
		["ghost_treadmill", frame_of("treadmill_l0_idle"), Vector2i(43, 41), {"positions": {"lado_direito": xy(P_TM_RIGHT)}, "layer": "chao", "z": -29}, "esteira"],
		["ghost_speed_bag", frame_of("speed_bag_l0_wall"), Vector2i(24, 0), {"positions": {"parede": xy(SB_WALL)}, "layer": "frente_do_fundo", "z": -40}, "plataforma da pera"],
		["ghost_grappling_dummy", frame_of("grappling_dummy_l0_rest"), Vector2i(32, 27), {"positions": {"canto": xy(GD_REST)}, "layer": "chao", "z": -29, "sort_y": 267}, "boneco deitado no tatame"],
	]
	for g in gdefs:
		for dm in [false, true]:
			var info2: Dictionary = (g[3] as Dictionary).duplicate(true)
			info2["note"] = "Fase 5.1: silhueta riscada da %s (tracejado %s + miolo pontilhado), SEM cadeado e SEM texto. Desenhar por cima da tape_mark correspondente; é ela que diz qual aparelho falta. Some junto com a marca." % [g[4], "apagado, para o estado trancado" if dm else "claro"]
			var id: String = str(g[0]) + ("_dim" if dm else "")
			save_sheet(id, "garage/" + id + ".png", [ghost_of(g[1], dm)], 0, g[2], info2)
	# cadeado solto (só no estado trancado), 7x10
	var lk: Image = L.blank(7, 10)
	pmap(lk, 0, 0, [
		"..kkk..",
		".kssskk",
		".ks.sk.",
		".ks.sk.",
		"kkkkkkk",
		"khhhhbk",
		"kbbkbbk",
		"kbbkbdk",
		"kdddddk",
		"kkkkkkk"], {"k": "ink", "s": "st3", "h": "g2", "b": "g1", "d": "g0"})
	save_sheet("mark_padlock", "garage/mark_padlock.png", [lk], 0, Vector2i(3, 5), {
		"note": "Cadeado cinza 7x10 para a marca TRANCADA (pede outro aparelho antes). Pivô no centro; ponto de cada marca em by_data_id.unlock_*.lock_pos. Não usar na marca que dá para comprar."})

# ================================================================ símbolo provisório da escola
## PROVISÓRIO: a história diz que o símbolo nasce quando a garagem é salva. Até lá: um frontão de garagem (casa de 5 lados)
## com as ripas do portão de enrolar, em tinta de carimbo azul. Um arquivo por tamanho: trocar depois sem mexer em mais nada.
func school_symbol(size: int, c: String, c2: String) -> Image:
	var s: Image = L.blank(size, size)
	if size <= 5:
		pmap(s, 0, 0, ["..a..", ".aaa.", "a...a", "abbba", "aaaaa"], {"a": c, "b": c2})
	elif size <= 9:
		pmap(s, 0, 0, [
			"....a....",
			"...aaa...",
			"..aa.aa..",
			".aa...aa.",
			"aa.....aa",
			"a.bbbbb.a",
			"a.......a",
			"a.bbbbb.a",
			"aaaaaaaaa"], {"a": c, "b": c2})
	else:
		var k: int = size / 16
		var b: Image = L.blank(16, 16)
		pmap(b, 0, 0, [
			".......aa.......",
			"......aaaa......",
			".....aa..aa.....",
			"....aa....aa....",
			"...aa......aa...",
			"..aa........aa..",
			".aa..........aa.",
			"aa............aa",
			"aa.bbbbbbbbbb.aa",
			"aa............aa",
			"aa.bbbbbbbbbb.aa",
			"aa............aa",
			"aa.bbbbbbbbbb.aa",
			"aa............aa",
			"aaaaaaaaaaaaaaaa",
			"aaaaaaaaaaaaaaaa"], {"a": c, "b": c2})
		s = scaled(b, k) if k > 1 else b
	return s

# ================================================================ caixa da escola
## state: 0 fechada, 1 racha 1, 2 racha 2, 3 aberta. Luz de cima; papelão br3 (frente), y0 (tampa), fita crepe, etiqueta e carimbo.
func box_img(kind: String, state: int) -> Image:
	var b: Dictionary = BOX[kind]
	var fr: Vector2i = b.frame
	var pv: Vector2i = b.pivot
	var w: int = b.w
	var h: int = b.h
	var top: int = b.top
	var big := kind == "big"
	var img: Image = L.blank(fr.x, fr.y)
	var x0: int = pv.x - w / 2
	var x1: int = x0 + w - 1
	var y1: int = pv.y - 1          # última linha da frente
	var y0: int = y1 - h + 1        # primeira linha da frente
	var ins: int = 5 if big else 3
	var yt: int = y0 - top          # linha de trás da tampa
	var cx: int = pv.x
	# ---- frente
	L.R(img, x0, y0, w, h, "br3")
	L.R(img, x1 - 2, y0, 3, h, "br2")                    # lado direito na sombra
	L.R(img, x0, y1 - 2, w, 3, "br2")                    # base encardida
	L.R(img, x1 - 2, y1 - 2, 3, 3, "br1")
	L.R(img, x0, y0, w, 1, "y0")                         # quina de cima pegando luz
	for x in range(x0 + 2, x1 - 2, 3):                   # ondulado do papelão na base
		L.P(img, x, y1 - 1, "br1")
	# setas "este lado para cima"
	var ax: int = x0 + 3
	var ay: int = y0 + 4
	for i in 2:
		var px: int = ax + i * (6 if big else 5)
		pmap(img, px, ay, ["..a..", ".aaa.", "a.a.a", "..a..", "..a.."] if big else [".a.", "aaa", ".a.", ".a."], {"a": "br1"})
	# carimbo vermelho (ilegível de propósito: o texto de verdade vai na dica)
	if big:
		var sx: int = x0 + 4
		var sy: int = y1 - 13
		L.R(img, sx, sy, 17, 1, "r2"); L.R(img, sx, sy + 8, 17, 1, "r2"); L.R(img, sx, sy, 1, 9, "r2"); L.R(img, sx + 16, sy, 1, 9, "r2")
		L.R(img, sx + 3, sy + 3, 11, 1, "r1"); L.R(img, sx + 3, sy + 5, 8, 1, "r1")
		L.P(img, sx + 5, sy, "br3"); L.P(img, sx + 11, sy + 8, "br3"); L.P(img, sx, sy + 6, "br3")
	else:
		var sx2: int = x0 + 3
		var sy2: int = y1 - 7
		L.R(img, sx2, sy2, 9, 1, "r2"); L.R(img, sx2, sy2 + 4, 9, 1, "r2"); L.P(img, sx2, sy2 + 1, "r2"); L.P(img, sx2, sy2 + 3, "r2")
		L.P(img, sx2 + 8, sy2 + 1, "r2"); L.P(img, sx2 + 8, sy2 + 2, "r2"); L.R(img, sx2 + 2, sy2 + 2, 5, 1, "r1")
	# etiqueta da escola (papel branco, símbolo provisório, 2 linhas "escritas")
	var lw: int = 20 if big else 12
	var lh: int = 15 if big else 10
	var lx: int = x1 - lw - (4 if big else 2)
	var ly: int = y1 - lh - (5 if big else 3)
	L.R(img, lx, ly, lw, lh, "white")
	L.R(img, lx, ly + lh - 1, lw, 1, "g3"); L.R(img, lx + lw - 1, ly, 1, lh, "cream")
	if big:
		L.blit(img, school_symbol(9, "b1", "b2"), lx + 2, ly + 2)
		L.R(img, lx + 12, ly + 3, 6, 1, "g2"); L.R(img, lx + 12, ly + 5, 5, 1, "g2"); L.R(img, lx + 12, ly + 8, 6, 1, "g1")
		L.R(img, lx + 2, ly + 12, 14, 1, "g2")
	else:
		L.blit(img, school_symbol(5, "b1", "b2"), lx + 1, ly + 1)
		L.R(img, lx + 7, ly + 2, 4, 1, "g2"); L.R(img, lx + 7, ly + 4, 3, 1, "g2"); L.R(img, lx + 1, ly + 7, 9, 1, "g2")
	if state >= 2:   # canto da etiqueta descolando
		L.P(img, lx + lw - 1, ly, "br3"); L.P(img, lx + lw - 2, ly, "br3"); L.P(img, lx + lw - 1, ly + 1, "br3")
		L.P(img, lx + lw - 2, ly + 1, "g3")
	# ---- tampa (fechada / rachando) ou boca aberta
	var tw: int = 5 if big else 3      # largura da fita
	if state < 3:
		L.trap(img, yt, y0 - 1, x0 + ins, x1 - ins, x0, x1, "y0")
		L.trap(img, yt, yt, x0 + ins, x1 - ins, x0 + ins, x1 - ins, "y1")
		# emenda das duas abas (linha do meio) e fita por cima, descendo pela frente
		for y in range(yt, y0):
			L.P(img, cx, y, "br2")
		var tl: int = (12 if big else 7)
		if state == 0:
			L.trap(img, yt, y0 - 1, cx - tw / 2 - 0.0, cx + tw / 2 + 0.0, cx - tw / 2 - 1.0, cx + tw / 2 + 1.0, "cream")
			L.R(img, cx - tw / 2 - 1, y0, tw + 2, tl, "cream")
			L.R(img, cx + tw / 2, y0, 1, tl, "g3")
			L.R(img, cx - tw / 2 - 1, y0 + tl - 1, tw + 2, 1, "g3")
			L.P(img, cx - tw / 2 - 1, y0 + tl - 1, "br3"); L.P(img, cx + tw / 2 + 1, y0 + tl - 1, "br3")
		elif state == 1:
			# fita rasgou em cima: sobra a ponta de trás e a tira da frente, enrolando
			L.trap(img, yt, yt + top / 3, cx - tw / 2, cx + tw / 2, cx - tw / 2, cx + tw / 2, "cream")
			L.R(img, cx - tw / 2 - 1, y0 + 1, tw + 2, tl - 1, "cream")
			L.R(img, cx + tw / 2, y0 + 1, 1, tl - 1, "g3")
			L.R(img, cx - tw / 2 - 1, y0 + tl - 1, tw + 2, 1, "g3")
			L.P(img, cx - tw / 2 - 2, y0 + 1, "cream"); L.P(img, cx - tw / 2 - 3, y0, "cream"); L.P(img, cx + tw / 2 + 2, y0 + 2, "g3")
			# racha: da quina de cima à esquerda, descendo em zigue-zague
			var cr := [[x0 + 9, y0], [x0 + 7, y0 + 3], [x0 + 9, y0 + 5], [x0 + 6, y0 + 8]] if big else [[x0 + 6, y0], [x0 + 5, y0 + 2], [x0 + 6, y0 + 4]]
			for i in cr.size() - 1:
				L.line(img, cr[i][0], cr[i][1], cr[i + 1][0], cr[i + 1][1], "br0")
			# aba da esquerda levantou 1 px
			L.trap(img, yt - 1, yt - 1, x0 + ins + 1, cx - 3, x0 + ins + 1, cx - 3, "y1")
			L.R(img, x0 + ins + 1, yt, cx - 3 - (x0 + ins), 1, "br2")
			# amassado na frente
			L.R(img, x1 - (12 if big else 8), y0 + 3, 4 if big else 3, 2, "br2")
		else:
			# racha 2: abas entreabertas, luz saindo pela fresta, rasgo na frente, fita pendurada
			L.trap(img, yt + 1, y0 - 2, cx - 3.0, cx + 3.0, cx - 5.0, cx + 5.0, "br0")
			L.trap(img, yt + 2, y0 - 2, cx - 1.0, cx + 1.0, cx - 2.0, cx + 2.0, "y1")
			L.P(img, cx, y0 - 2, "y2"); L.P(img, cx, y0 - 3, "y2")
			L.trap(img, yt - 2, yt - 2, x0 + ins + 2, cx - 4, x0 + ins + 2, cx - 4, "y1")      # aba esq. levantada 2 px
			L.trap(img, yt - 1, yt - 1, x0 + ins + 1, cx - 4, x0 + ins + 1, cx - 4, "y0")
			L.R(img, x0 + ins + 1, yt, cx - 4 - (x0 + ins), 1, "br2")
			L.trap(img, yt - 1, yt - 1, cx + 5, x1 - ins - 1, cx + 5, x1 - ins - 1, "y1")      # aba dir. levantada 1 px
			L.R(img, cx + 5, yt, x1 - ins - cx - 5, 1, "br2")
			# fita partida, pendurada torta na frente
			L.R(img, cx - tw / 2, y0 + 2, tw, tl - 3, "cream"); L.R(img, cx + tw / 2, y0 + 2, 1, tl - 3, "g3")
			L.P(img, cx - tw / 2 - 1, y0 + 2, "cream"); L.P(img, cx + tw / 2 + 1, y0 + tl - 2, "cream"); L.P(img, cx + tw / 2 + 2, y0 + tl - 1, "g3")
			# rachas dos dois lados
			var c1 := [[x0 + 9, y0], [x0 + 7, y0 + 3], [x0 + 10, y0 + 6], [x0 + 6, y0 + 10], [x0 + 8, y0 + 13]] if big else [[x0 + 6, y0], [x0 + 5, y0 + 2], [x0 + 7, y0 + 4], [x0 + 5, y0 + 7]]
			var c2 := [[x1 - 8, y0], [x1 - 6, y0 + 3], [x1 - 9, y0 + 5]] if big else [[x1 - 5, y0], [x1 - 4, y0 + 2], [x1 - 6, y0 + 3]]
			for cc in [c1, c2]:
				for i in cc.size() - 1:
					L.line(img, cc[i][0], cc[i][1], cc[i + 1][0], cc[i + 1][1], "br0")
			# buraco na frente (dá para ver o escuro lá dentro)
			var hx: int = x0 + (12 if big else 8)
			var hy: int = y0 + (4 if big else 3)
			L.R(img, hx, hy, 4 if big else 3, 3 if big else 2, "br0"); L.P(img, hx + 1, hy + 1, "ink"); L.P(img, hx - 1, hy + 1, "br0")
			L.P(img, hx + (4 if big else 3), hy - 1, "y0")
			L.R(img, x1 - (12 if big else 8), y0 + 3, 4 if big else 3, 2, "br2")
	else:
		# ABERTA: boca escura, aba de trás em pé, abas dos lados caídas para fora, aba da frente dobrada para baixo
		var fh: int = top + 3                                    # altura das abas
		L.trap(img, yt - fh, yt - 1, x0 + ins + 2, x1 - ins - 2, x0 + ins, x1 - ins, "y0")       # aba de trás (face de dentro, clara)
		L.trap(img, yt - fh, yt - fh, x0 + ins + 2, x1 - ins - 2, x0 + ins + 2, x1 - ins - 2, "y1")
		L.R(img, cx, yt - fh + 1, 1, fh - 1, "br3")
		L.trap(img, yt, y0 - 1, x0 + ins, x1 - ins, x0, x1, "br0")                              # boca
		L.trap(img, yt, yt + 1, x0 + ins, x1 - ins, x0 + ins - 1, x1 - ins + 1, "ink")
		# papel de embrulho amassado aparecendo
		for i in (5 if big else 3):
			var px2: int = x0 + ins + 3 + i * (8 if big else 6)
			L.R(img, px2, y0 - 3 - (i % 2), 4, 2, "cream"); L.P(img, px2 + 1, y0 - 4 - (i % 2), "white"); L.P(img, px2 + 3, y0 - 2 - (i % 2), "g3")
		# abas laterais caídas para fora (paralelogramos)
		for i in fh:
			var yy: int = y0 - 1 - i / 2
			L.R(img, x0 - 1 - i, yy - (top - 2), 1, top - 1, "br3" if i < fh - 1 else "br2")
			L.R(img, x1 + 1 + i, yy - (top - 2), 1, top - 1, "br2" if i < fh - 1 else "br1")
		for i in fh:
			L.P(img, x0 - 1 - i, y0 - 1 - i / 2 - (top - 2), "y0")
		# aba da frente dobrada para baixo
		L.R(img, x0 + 1, y0, w - 2, top - 2, "br2")
		L.R(img, x0 + 1, y0 + top - 3, w - 2, 1, "br1")
		L.R(img, x0, y0, w, 1, "y0")
		L.R(img, cx - tw / 2, y0 + 1, tw, top - 3, "cream"); L.R(img, cx + tw / 2, y0 + 1, 1, top - 3, "g3")
	var o := ol(img)
	# sombra de contato no chão (por baixo do contorno)
	var out: Image = L.blank(fr.x, fr.y)
	L.ellipse_dither(out, pv.x, pv.y + 1, w / 2.0 + 4, 2.5, "ink")
	L.R(out, x0 - 1, pv.y, w + 2, 1, "ink")
	L.blit(out, o, 0, 0)
	return out

func make_boxes() -> void:
	var st_note := "Quadros: 0 = fechada, 1 = racha 1 (depois do 1º clique), 2 = racha 2 (depois do 2º), 3 = aberta e vazia (só durante o efeito de abrir). Pivô = meio da base, no chão. Sombra de contato já no quadro. SEM luz da sala aplicada, de propósito: é o objeto novo da cena e precisa saltar ao olho; a mesma arte vale na garagem e na academia."
	for kind in ["big", "small"]:
		var frames := []
		for s in 4:
			frames.append(box_img(kind, s))
		var b: Dictionary = BOX[kind]
		var who := "esteira e boneco de tatame" if kind == "big" else "corda, pera e luvas"
		save_sheet("box_" + kind, "box/box_%s.png" % kind, frames, 0, b.pivot, {
			"loop": false, "anim": {"closed": [0], "crack_1": [1], "crack_2": [2], "open": [3]},
			"body_size": [b.w, b.h + b.top], "top_center_offset": [0, -(b.h + b.top)],
			"click_rect": [-(b.w / 2) - 2, -(b.h + b.top) - 2, b.w + 4, b.h + b.top + 4],
			"note": "Caixa de papelão da escola, tamanho %s (%s). %s click_rect = área clicável sugerida, relativa ao pivô." % ["GRANDE" if kind == "big" else "PEQUENA", who, st_note]})

# ---------------------------------------------------------------- efeitos da caixa
func star(img: Image, x: int, y: int, s: int, c := "y2") -> void:
	L.P(img, x, y, "white")
	for i in range(1, s + 1):
		L.P(img, x + i, y, c); L.P(img, x - i, y, c); L.P(img, x, y + i, c); L.P(img, x, y - i, c)

## Pedaço de papelão ou fita voando. kind 0 = lasca 2x2, 1 = lasca 3x2, 2 = fita 3x1, 3 = aba grande 7x5
func chip(img: Image, x: int, y: int, kind: int, rot: int) -> void:
	match kind:
		0:
			L.R(img, x - 1, y - 1, 4, 4, "ink"); L.R(img, x, y, 2, 2, "br3"); L.P(img, x + (rot % 2), y, "y0")
		1:
			if rot % 2 == 0:
				L.R(img, x - 1, y - 1, 5, 4, "ink"); L.R(img, x, y, 3, 2, "br3"); L.P(img, x, y, "y0"); L.P(img, x + 2, y + 1, "br2")
			else:
				L.R(img, x - 1, y - 1, 4, 5, "ink"); L.R(img, x, y, 2, 3, "br3"); L.P(img, x, y, "y0"); L.P(img, x + 1, y + 2, "br2")
		2:
			if rot % 2 == 0:
				L.R(img, x - 1, y - 1, 5, 3, "ink"); L.R(img, x, y, 3, 1, "cream")
			else:
				L.R(img, x - 1, y - 1, 3, 5, "ink"); L.R(img, x, y, 1, 3, "cream")
		3:
			var sh: Array = [[7, 5], [5, 7], [7, 4], [4, 7]][rot % 4]
			L.R(img, x - 1, y - 1, sh[0] + 2, sh[1] + 2, "ink")
			L.R(img, x, y, sh[0], sh[1], "br3"); L.R(img, x, y, sh[0], 1, "y0"); L.R(img, x, y + sh[1] - 1, sh[0], 1, "br2")
			if rot % 2 == 0:
				L.R(img, x + 2, y + 1, 2, sh[1] - 2, "cream")

## Partículas com gravidade, saindo do ponto (ox, oy). parts = [[vx, vy, tipo, atraso]]
func particles(fw: int, fh: int, ox: int, oy: int, parts: Array, n: int, grav: float, flash: int, stars: Array) -> Array:
	var frames := []
	for f in n:
		var img: Image = L.blank(fw, fh)
		if f < flash:
			# risco de impacto: traços brancos em leque
			var r0 := 4 + f * 4
			var r1 := r0 + 5 - f
			for a in [200, 235, 270, 305, 340]:
				var rad := deg_to_rad(float(a))
				L.line(img, ox + int(cos(rad) * r0), oy + int(sin(rad) * r0 * 0.8), ox + int(cos(rad) * r1), oy + int(sin(rad) * r1 * 0.8), "white" if f == 0 else "y2")
		for p in parts:
			var t := float(f) - float(p[3])
			if t < 0.0:
				continue
			var px := ox + int(round(float(p[0]) * t))
			var py := oy + int(round(float(p[1]) * t + grav * t * t))
			if f >= n - 1 and int(p[2]) != 3:
				L.P(img, px, py, "br2")      # último quadro: vira pontinho
			elif f >= n - 2 and int(p[2]) < 2:
				L.R(img, px, py, 2, 1, "br3"); L.P(img, px, py + 1, "br2")
			else:
				chip(img, px, py, int(p[2]), f + int(p[3]))
		for s in stars:
			var ts: int = f - int(s[3])
			if ts >= 0 and ts < 3:
				star(img, ox + int(s[0]), oy + int(s[1]) - ts, [int(s[2]), int(s[2]) + 1, 1][ts], "y2" if ts < 2 else "y1")
		frames.append(img)
	return frames

func make_box_fx() -> void:
	# clique 1: poucas lascas, baixas
	var p1 := [[-3.0, -3.5, 0, 0], [2.5, -4.0, 1, 0], [4.0, -2.0, 2, 0], [-1.5, -5.0, 0, 1], [-4.5, -1.5, 0, 0]]
	save_sheet("fx_box_chips_1", "box/fx_box_chips_1.png", particles(72, 56, 36, 40, p1, 5, 0.75, 1, []), 14, Vector2i(36, 40), {
		"loop": false, "note": "1º clique na caixa: 5 lascas de papelão e um risco de impacto. 5 quadros a 14 fps (0,36 s). Pivô = meio de cima da caixa (pos da caixa + top_center_offset do box_*). Por cima da caixa."})
	# clique 2: mais lascas, mais alto, fita voando e uma estrelinha (a luz da fresta)
	var p2 := [[-4.0, -4.5, 1, 0], [3.5, -5.0, 1, 0], [5.5, -2.5, 2, 0], [-2.0, -6.5, 0, 0], [-6.0, -2.0, 0, 0], [1.0, -7.0, 2, 1],
		[6.5, -4.0, 0, 1], [-5.0, -5.5, 2, 1], [2.0, -3.0, 0, 0], [-0.5, -5.5, 1, 1]]
	save_sheet("fx_box_chips_2", "box/fx_box_chips_2.png", particles(88, 64, 44, 48, p2, 6, 0.8, 2, [[0, -6, 2, 1], [10, -12, 1, 2]]), 14, Vector2i(44, 48), {
		"loop": false, "note": "2º clique: 10 lascas e pedaços de fita, mais altos, e a 1ª faísca saindo da fresta. 6 quadros a 14 fps (0,43 s). Mesmo pivô do fx_box_chips_1."})
	# clique 3: estouro (o 'tchan') — clarão, abas voando, estrelas
	var p3 := [[-5.5, -6.0, 3, 0], [5.0, -7.0, 3, 0], [-8.0, -3.0, 3, 0], [8.0, -3.5, 3, 0], [-2.5, -8.5, 1, 0], [2.0, -9.0, 2, 0],
		[-6.5, -7.5, 0, 1], [7.0, -6.0, 1, 1], [0.5, -7.5, 0, 0], [-4.0, -4.0, 2, 1], [4.0, -4.5, 0, 1], [-9.5, -5.0, 1, 0], [10.0, -5.5, 0, 0]]
	var burst := particles(128, 96, 64, 72, p3, 7, 0.85, 0, [[-22, -20, 3, 1], [24, -26, 3, 1], [0, -40, 4, 2], [-34, -8, 2, 2], [36, -12, 2, 3], [-12, -34, 2, 3], [14, -18, 2, 4]])
	# clarão: estrela grande de 8 pontas nos 2 primeiros quadros + anel no 3º
	for f in 3:
		var img: Image = burst[f]
		var under: Image = L.blank(128, 96)
		if f < 2:
			var rr := 26 - f * 8
			for a in range(0, 360, 45):
				var rad := deg_to_rad(float(a) + 22.5 * f)
				var ex := 64 + int(cos(rad) * rr)
				var ey := 72 + int(sin(rad) * rr * 0.75)
				L.line(under, 64, 72, ex, ey, "y2")
				L.line(under, 64, 71, ex, ey - 1, "white" if f == 0 else "y1")
				L.line(under, 65, 72, ex + 1, ey, "y1")
			L.ellipse(under, 64, 72, 9 - f * 3, 7 - f * 2, "white")
			L.ring(under, 64, 72, 12 - f * 3, 9 - f * 2, 2, "y1")
		else:
			L.ring(under, 64, 70, 30, 20, 2, "y1")
			for y in 96:
				for x in 128:
					if under.get_pixel(x, y).a > 0.0 and (x + y) % 2 == 1:
						under.set_pixel(x, y, Color(0, 0, 0, 0))
		L.blit(under, img, 0, 0)
		burst[f] = under
	save_sheet("fx_box_burst", "box/fx_box_burst.png", burst, 14, Vector2i(64, 72), {
		"loop": false, "impact_frame": 0, "note": "3º clique, o 'tchan': clarão em estrela (quadros 0–1), anel, 4 abas e lascas voando, 7 estrelas. 7 quadros a 14 fps (0,5 s). Mesmo pivô dos fx_box_chips (meio de cima da caixa). Por cima de tudo da sala."})
	# brilho de espera (a caixa chama o clique sem texto)
	var gl := []
	for f in 4:
		var g: Image = L.blank(9, 9)
		var s: int = [1, 3, 2, 0][f]
		if s > 0:
			star(g, 4, 4, s, "y2")
			if s == 3:
				L.P(g, 3, 3, "y1"); L.P(g, 5, 3, "y1"); L.P(g, 3, 5, "y1"); L.P(g, 5, 5, "y1")
		else:
			L.P(g, 4, 4, "y1")
		gl.append(g)
	save_sheet("fx_box_glint", "box/fx_box_glint.png", gl, 8, Vector2i(4, 4), {
		"loop": false, "note": "Brilho de espera da caixa fechada: 4 quadros a 8 fps, tocar 1 vez a cada ~2,5 s numa quina de cima (pos da caixa + glint_offset do by_data_id.box). Com mais de uma caixa, defasar."})

# ================================================================ UI: etiqueta, carimbo, símbolo, Fama em rosa
func make_ui() -> void:
	for sz in [9, 16, 32]:
		var id := "school_symbol_%d" % sz
		save_sheet(id, "ui/%s.png" % id, [school_symbol(sz, "b1", "b2")], 0, Vector2i.ZERO, {
			"provisional": true,
			"note": "SÍMBOLO DA ESCOLA — PROVISÓRIO (%dx%d). A história diz que o símbolo nasce quando a garagem é salva; este é só um marcador: frontão de garagem com as ripas do portão, em tinta de carimbo azul (b1 + b2). Trocar o arquivo quando o símbolo de verdade existir; nada mais muda." % [sz, sz]})
	# etiqueta de papel (9-slice) para a dica da caixa: fundo branco, borda creme, picote em cima
	var t: Image = L.blank(16, 16)
	L.R(t, 0, 0, 16, 16, "ink")
	L.R(t, 1, 1, 14, 14, "white")
	L.R(t, 1, 14, 14, 1, "g3"); L.R(t, 14, 1, 1, 14, "cream")
	L.R(t, 1, 1, 14, 1, "cream")
	for x in range(2, 14, 2):
		L.P(t, x, 2, "g3")
	t.set_pixel(0, 0, Color(0, 0, 0, 0)); t.set_pixel(15, 0, Color(0, 0, 0, 0)); L.P(t, 1, 1, "ink"); L.P(t, 14, 1, "ink")
	save_sheet("ui_box_tag", "ui/ui_box_tag.png", [t], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 4, "top": 5, "right": 4, "bottom": 4}, "text_color": "d2", "text_color_secondary": "g1", "text_margin": [6, 6, 6, 5],
		"note": "Etiqueta de papel da caixa (9-slice) para a dica de hover: símbolo school_symbol_16 à esquerda, box_sender / box_to em g1, nome do item (box_label) em d2. Texto 1x SEM sombra (papel claro)."})
	# carimbo (9-slice): moldura vermelha dupla falhada, miolo transparente
	var s: Image = L.blank(14, 13)
	L.R(s, 0, 0, 14, 13, "r2")
	L.R(s, 1, 1, 12, 11, Color(0, 0, 0, 0))
	for y in range(1, 12):
		for x in range(1, 13):
			s.set_pixel(x, y, Color(0, 0, 0, 0))
	L.R(s, 2, 2, 10, 1, "r1"); L.R(s, 2, 10, 10, 1, "r1"); L.R(s, 2, 2, 1, 9, "r1"); L.R(s, 11, 2, 1, 9, "r1")
	for p in [[3, 0], [9, 12], [0, 8], [13, 4], [6, 2], [4, 10]]:
		s.set_pixel(p[0], p[1], Color(0, 0, 0, 0))
	save_sheet("ui_box_stamp", "ui/ui_box_stamp.png", [s], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 4, "top": 4, "right": 4, "bottom": 4}, "text_color": "r2", "text_margin": [5, 4, 5, 4],
		"note": "Carimbo vermelho (9-slice, miolo transparente) para o texto box_stamp (PESADO, PAR, NÃO MOLHAR...), em r2, 1x, sem sombra, por cima da etiqueta ou do canto dela."})
	# Fama troca de roxo para rosa (roxo fica só para Legado e arte marcial)
	for id in ["icon_fame", "icon_fame_16"]:
		var e: Dictionary = OLD.sprites[id]
		var src := load_png(str(e.file))
		var map := {L.C.p0.to_html(false): "f0", L.C.p1.to_html(false): "f1", L.C.p2.to_html(false): "f2"}
		for y in src.get_height():
			for x in src.get_width():
				var c := src.get_pixel(x, y)
				if c.a > 0.0 and map.has(c.to_html(false)):
					src.set_pixel(x, y, L.C[map[c.to_html(false)]])
		var rel := str(e.file).replace(RES, "")
		save_sheet(id, rel, [src], 0, Vector2i.ZERO, {"note": "Ícone de Fama (estrela) na cor da moeda Fama da Fase 5.1: rosa de letreiro (f1/f2). Era roxo; roxo agora é só Legado e arte marcial."})

func _init() -> void:
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	for a in OS.get_cmdline_user_args():
		if (a as String).begins_with("--teste="):
			var d := (a as String).substr(8)
			OUT = d + "sprites/"
			MOCK = d + "mock/"
			TESTE = true
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.make_dir_recursive_absolute(MOCK)
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível")
		quit()
		return
	OLD = j.data
	make_rope()
	make_marks()
	make_boxes()
	make_box_fx()
	make_ui()
	make_contact_sheet(MOCK + "fase51_sprites_x3.png")
	make_mockups()
	write_manifest()
	print("ok: fase 5.1 (%s)" % ("TESTE em " + OUT if TESTE else "projeto"))
	quit()

#__TAIL__
func make_contact_sheet(path: String) -> void:
	var W := 912
	var x := 6
	var y := 16
	var rowh := 0
	var places := []
	for sh in SHEETS:
		var s: Image = sh[1]
		var w: int = s.get_width()
		var h: int = s.get_height()
		if x + w + 6 > W:
			x = 6
			y += rowh + 14
			rowh = 0
		places.append([sh[0], s, x, y])
		x += maxi(w, L.text_w(str(sh[0]))) + 10
		rowh = maxi(rowh, h)
	var img: Image = L.blank(W, y + rowh + 16)
	L.R(img, 0, 0, W, img.get_height(), "d2")
	L.text(img, "FIGHTCLICKER - FASE 5.1 - SPRITES PLACEHOLDER (X3)", 6, 4, "white", 1, "ink")
	for p in places:
		var s2: Image = p[1]
		L.R(img, p[2] - 1, p[3] - 1, s2.get_width() + 2, s2.get_height() + 2, "g0")
		L.dither(img, p[2], p[3], s2.get_width(), s2.get_height(), "g1")
		L.blit(img, s2, p[2], p[3])
		L.text(img, str(p[0]), p[2], p[3] + s2.get_height() + 3, "g3")
	save_x(img, path, 3)

# ================================================================ mockups
const LOCK_POS := {"jump_rope": Vector2i(296, 187), "treadmill": Vector2i(445, 249), "speed_bag": Vector2i(436, 68), "grappling_dummy": Vector2i(228, 271)}
const MARK := {
	"jump_rope": ["tape_mark_rope", "ghost_rope", HOOK],
	"treadmill": ["tape_mark_treadmill", "ghost_treadmill", P_TM_RIGHT],
	"speed_bag": ["tape_mark_speed_bag", "ghost_speed_bag", SB_WALL],
	"grappling_dummy": ["tape_mark_grappling_dummy", "ghost_grappling_dummy", GD_REST],
}

func T(img: Image, s: String, x: int, y: int, c, scale := 1) -> int:
	return L.text(img, s, x, y, c, scale, "ink")

func draw_mark(img: Image, ap: String, st: String) -> void:
	var m: Array = MARK[ap]
	var suf: String = {"normal": "", "hi": "_hi", "dim": "_dim"}[st]
	put(img, str(m[0]) + suf, 0, m[2])
	put(img, str(m[1]) + ("_dim" if st == "dim" else ""), 0, m[2])
	if st == "dim":
		put(img, "mark_padlock", 0, LOCK_POS[ap])

## o = {room, crew, lv, rope: "owned", treadmill: "owned", marks: {aparelho: estado}, boxes: {lugar: quadro}, fighter_frame}
func room(o: Dictionary) -> Image:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	var gym: bool = o.get("room", "garage") == "gym"
	var suf := "_gym" if gym else ""
	var lv: int = o.get("lv", 0)
	img.blit_rect(frame_of("gym_bg" if gym else "garage_bg"), Rect2i(0, 0, 384, 272), P_ROOM)
	var marks: Dictionary = o.get("marks", {})
	for ap in marks:
		draw_mark(img, ap, marks[ap])
	if o.get("rope", "") == "owned":
		put(img, "rope_l%d_idle%s" % [lv, suf], 0, HOOK)
	if not gym:
		put(img, "lamp", 0, P_LAMP)
	for yy in range(33, P_BAG_CENTER.y, 4):
		put(img, "bag_chain_tile", 0, Vector2i(P_BAG_CENTER.x - 1, yy))
	var items := []
	items.append([P_BAG_CENTER.y + 70, "bag_l%d_idle%s" % [lv, suf], 0, P_BAG_CENTER])
	if o.get("treadmill", "") == "owned":
		items.append([P_TM_RIGHT.y, "treadmill_l%d_side%s" % [lv, suf], 0, P_TM_RIGHT])
	var people := [["neighbor_1", P_NEIGHBOR[0]], ["uncle_1", P_UNCLE[0]], ["neighbor_2", P_NEIGHBOR[1]], ["uncle_2", P_UNCLE[1]], ["coach_1", P_COACH], ["neighbor_3", P_NEIGHBOR[2]]]
	for i in mini(int(o.get("crew", 0)), people.size()):
		var pp: Vector2i = people[i][1]
		items.append([pp.y - 1, "floor_shadow", 0, pp + Vector2i(0, -1)])
		items.append([pp.y, people[i][0], 1, pp])
	items.append([P_FIGHTER_BAG.y - 1, "floor_shadow", 0, Vector2i(303, 271)])
	items.append([P_FIGHTER_BAG.y, "fighter_punch", int(o.get("fighter_frame", 0)), P_FIGHTER_BAG])
	var boxes: Dictionary = o.get("boxes", {})
	for slot in boxes:
		var bp: Array = BOX_POS[slot]
		items.append([(bp[1] as Vector2i).y, "box_" + str(bp[0]), int(boxes[slot]), bp[1]])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		put(img, it[1], it[2], it[3])
	return img

func crop_room(img: Image) -> Image:
	return img.get_region(Rect2i(P_ROOM, Vector2i(384, 272)))

func caption(img: Image, s: String, x: int, y: int, w: int, c := "white") -> void:
	L.R(img, x, y, w, 11, "ink")
	L.R(img, x, y, w, 10, "d1")
	T(img, s, x + 4, y + 1, c)

func make_mock_rooms() -> void:
	var a := room({"room": "garage", "crew": 2, "marks": {"jump_rope": "dim", "treadmill": "hi", "grappling_dummy": "normal"}})
	var b := room({"room": "gym", "crew": 3, "rope": "owned", "treadmill": "owned", "marks": {"speed_bag": "normal"}})
	var c := room({"room": "garage", "crew": 6, "rope": "owned", "boxes": {"treadmill": 0, "glove": 1, "grappling_dummy": 0}})
	var d := room({"room": "gym", "crew": 6, "treadmill": "owned", "lv": 1, "boxes": {"jump_rope": 2, "speed_bag": 0, "glove": 0}, "marks": {"jump_rope": "normal", "speed_bag": "hi"}})
	var W := 384 * 2 + 12
	var img: Image = L.blank(W, (272 + 14) * 2 + 4)
	L.R(img, 0, 0, W, img.get_height(), "ink")
	var caps := ["GARAGEM: MARCAS SEM TEXTO (TRANCADA, ACESA, NORMAL)", "ACADEMIA: CORDA NO GANCHO NOVO + MARCA DA PERA",
		"GARAGEM: CORDA NO GANCHO + CAIXAS ESTEIRA, BONECO, LUVA", "ACADEMIA: CAIXAS DA CORDA, DA PERA E DA LUVA"]
	var rs := [a, b, c, d]
	for i in 4:
		var x := 4 + (i % 2) * 388
		var y := 2 + (i / 2) * 286
		caption(img, caps[i], x, y, 384)
		img.blit_rect(crop_room(rs[i]), Rect2i(0, 0, 384, 272), Vector2i(x, y + 12))
	save_x(img, MOCK + "fase51_corda_marcas_x2.png", 2)
	F["_room_c"] = [c]
	F["_room_d"] = [d]

func tag_card(img: Image, x: int, y: int, item: String, stamp: String) -> void:
	var w := 104
	ns(img, "ui_box_tag", x, y, w, 40)
	put(img, "school_symbol_16", 0, Vector2i(x + 6, y + 8))
	L.text(img, "DA ESCOLA", x + 26, y + 8, "g1")
	L.text(img, "PARA O NOVATO", x + 26, y + 17, "g1")
	L.text(img, item, x + 6, y + 28, "d2")
	var sw: int = L.text_w(stamp) + 10
	ns(img, "ui_box_stamp", x + w - sw - 2, y + 37, sw, 15)
	L.text(img, stamp, x + w - sw + 3, y + 41, "r2")

func make_mock_box() -> void:
	var img: Image = L.blank(520, 372)
	L.R(img, 0, 0, 520, 372, "d2")
	L.R(img, 0, 0, 520, 13, "d1")
	T(img, "FIGHTCLICKER - FASE 5.1 - A CAIXA DA ESCOLA (PLACEHOLDER, X3)", 6, 3, "white")
	var names := ["FECHADA", "RACHA 1", "RACHA 2", "ABERTA"]
	var sub := ["espera o clique", "após 1 clique", "após 2 cliques", "3º clique"]
	for s in 4:
		var x := 14 + s * 92
		L.R(img, x - 6, 20, 86, 100, "g0")
		L.R(img, x - 6, 92, 86, 28, "d1")
		L.R(img, x - 6, 134, 86, 46, "g0")
		put(img, "box_big", s, Vector2i(x + 37, 88))
		T(img, names[s], x - 2, 96, "white")
		L.text(img, sub[s], x - 2, 107, "g2")
		put(img, "box_small", s, Vector2i(x + 37, 176))
	# efeitos por cima dos estados (como a UI vai montar)
	put(img, "fx_box_glint", 1, Vector2i(14 + 37 + 22, 88 - 40))
	put(img, "fx_box_chips_1", 2, Vector2i(14 + 92 + 37, 88 - 41))
	put(img, "fx_box_chips_2", 3, Vector2i(14 + 184 + 37, 88 - 41))
	put(img, "fx_box_burst", 2, Vector2i(14 + 276 + 37, 88 - 41))
	T(img, "CAIXA GRANDE (ESTEIRA, BONECO)", 8, 123, "y1")
	T(img, "CAIXA PEQUENA (CORDA, PERA, LUVAS)", 8, 183, "y1")
	# coluna da direita: etiqueta, símbolo, carimbo
	var rx := 388
	T(img, "ETIQUETA (NO HOVER)", rx, 20, "y1")
	tag_card(img, rx, 32, "ESTEIRA", "PESADO")
	tag_card(img, rx, 88, "LUVA COURO", "NÃO MOLHAR")
	T(img, "SÍMBOLO PROVISÓRIO", rx, 146, "y1")
	put(img, "school_symbol_32", 0, Vector2i(rx, 158)); put(img, "school_symbol_16", 0, Vector2i(rx + 40, 174)); put(img, "school_symbol_9", 0, Vector2i(rx + 64, 181))
	L.text(img, "trocar quando a", rx + 44, 158, "g2")
	L.text(img, "história criar", rx + 44, 166, "g2")
	# tiras dos efeitos, com a caixa pequena de referência
	var y := 198
	var fxs := [["fx_box_chips_1", "1º CLIQUE: TREMIDA 1 PX + 5 LASCAS (0,36 S)", 1], ["fx_box_chips_2", "2º CLIQUE: TREMIDA 2 PX + 10 LASCAS E FAÍSCA (0,43 S)", 2], ["fx_box_burst", "3º CLIQUE: TREMIDA 3 PX + ESTOURO, ABAS E ESTRELAS (0,5 S)", 3]]
	for fx in fxs:
		var e := spr(fx[0])
		var n: int = int(e.frames)
		var fw: int = int(e.frame_size[0])
		var fh: int = int(e.frame_size[1])
		var pv: Array = e.pivot
		T(img, str(fx[1]), 8, y, "white")
		var cw := 50
		var chh := 44
		for f in n:
			var cell: Image = L.blank(cw, chh)
			L.R(cell, 0, 0, cw, chh, "g0")
			var bx: Image = frame_of("box_small", int(fx[2]))
			cell.blend_rect(bx, Rect2i(0, 0, 48, 42), Vector2i(cw / 2 - 24, chh - 41))
			var fr: Image = frame_of(fx[0], f)
			cell.blend_rect(fr, Rect2i(0, 0, fw, fh), Vector2i(cw / 2 - int(pv[0]), chh - 3 - 25 - int(pv[1])))
			img.blit_rect(cell, Rect2i(0, 0, cw, chh), Vector2i(8 + f * (cw + 2), y + 10))
		y += 58
	# linha do tempo do 3º clique
	var ty := 198
	T(img, "3º CLIQUE: 1,2 S", rx, ty, "y1")
	var bars := [["tremida 3 px", 0.0, 0.15, "r2"], ["fx_box_burst", 0.0, 0.5, "y1"], ["item aparece", 0.15, 0.6, "gr3"], ["caixa aberta some", 0.6, 0.9, "br3"], ["assenta + foco", 0.9, 1.2, "b3"]]
	for i in bars.size():
		var by := ty + 13 + i * 17
		L.text(img, str(bars[i][0]), rx, by, "g3")
		L.R(img, rx, by + 9, 122, 4, "d1")
		L.R(img, rx + int(float(bars[i][1]) * 80.0), by + 9, int((float(bars[i][2]) - float(bars[i][1])) * 80.0), 4, bars[i][3])
	L.R(img, rx + 120, ty + 13, 1, 86, "r2")
	L.text(img, "limite 1,5 s", rx + 62, ty + 102, "r3")
	T(img, "0", rx, ty + 102, "g2")
	save_x(img, MOCK + "fase51_caixa_x3.png", 3)

func make_mockups() -> void:
	make_mock_rooms()
	make_mock_box()
	make_mock_before_after()

#__MOCK3__
# ---------------------------------------------------------------- garagem: hoje x os 3 níveis
## Tokens da hierarquia (docs/fases/fase5.1-design.md §3 + direcao-visual.md §18): nome -> cor da paleta.
const TOK := {
	"col_treino": "gr3", "col_money": "y1", "col_fame": "f2", "col_legacy": "p2",
	"col_text_1": "white", "col_text_2": "g2", "col_disabled": "g1", "col_buyable": "y2",
	"col_strength": "r2", "col_agility": "b3", "col_endurance": "y0", "col_art": "p1",
}

func tooltip(img: Image, x: int, y: int, lines: Array) -> void:
	var w := 0
	for ln in lines:
		w = maxi(w, L.text_w(str(ln)))
	var h: int = lines.size() * 9 + 7
	L.R(img, x + 1, y + 1, w + 12, h, "ink")
	L.R(img, x, y, w + 12, h, "ink")
	L.R(img, x + 1, y + 1, w + 10, h - 2, "d1")
	L.R(img, x + 1, y + 1, w + 10, 1, "g0")
	for i in lines.size():
		L.text(img, str(lines[i]), x + 6, y + 4 + i * 9, TOK.col_text_1 if i == 0 else TOK.col_text_2)

func attr_row(img: Image, y: int, icon: String, name: String, val: String, frac: float, col: String, fill: String, on := true) -> void:
	put(img, icon, 0, Vector2i(8, y))
	T(img, name, 20, y + 1, col if on else TOK.col_disabled)
	L.text_right(img, val, 120, y + 1, TOK.col_text_1 if on else TOK.col_disabled, 1, "ink")
	ns(img, "ui_bar_bg", 8, y + 12, 112, 5)
	if on and frac > 0.0:
		ns(img, fill, 9, y + 13, maxi(int(110 * frac), 3), 3)

func shop_card(img: Image, y: int, icon: String, name: String, eff: String, price: String, state: String) -> void:
	# state: "best" (comprável mais barato: brilha), "can" (dá para pagar), "cannot" (sem saldo: apagado, sem vermelho)
	ns(img, "ui_card" if state != "cannot" else "ui_card_dim", 516, y, 120, 34)
	if state == "best":
		for i in 120:
			L.P(img, 516 + i, y, TOK.col_buyable); L.P(img, 516 + i, y + 33, TOK.col_buyable)
		for i in 34:
			L.P(img, 516, y + i, TOK.col_buyable); L.P(img, 635, y + i, TOK.col_buyable)
	put(img, icon, 0, Vector2i(520, y + 4))
	T(img, name, 540, y + 4, TOK.col_text_1 if state != "cannot" else TOK.col_text_2)
	L.text(img, eff, 540, y + 14, TOK.col_text_2 if state != "cannot" else TOK.col_disabled)
	var pc: String = TOK.col_treino if state != "cannot" else TOK.col_text_2
	var pw: int = L.text_w(price)
	if state == "cannot":
		var ic: Image = frame_of("icon_treino").duplicate()
		for yy in 9:
			for xx in 9:
				var c := ic.get_pixel(xx, yy)
				if c.a > 0.0 and c.to_html(false) != L.C.ink.to_html(false):
					ic.set_pixel(xx, yy, L.C.g1)
		L.blit(img, ic, 630 - pw - 12, y + 22)
	else:
		put(img, "icon_treino", 0, Vector2i(630 - pw - 12, y + 22))
	L.text_right(img, price, 630, y + 23, pc, 1, "ink")

func after_screen() -> Image:
	var img := room({"room": "garage", "crew": 2, "marks": {"jump_rope": "dim", "grappling_dummy": "dim"}, "boxes": {"treadmill": 0}, "fighter_frame": 2})
	put(img, "fx_box_glint", 1, Vector2i(445 + 20, 268 - 38))
	# número do clique (efeito, não é texto de interface)
	L.text(img, "+1", 352, 196, "y1", 2, null, "ink")
	# dica de hover na marca da corda (nível 3): sem plaquinha na sala
	put(img, "tape_mark_rope_hi", 0, HOOK)
	put(img, "ghost_rope_dim", 0, HOOK)
	put(img, "mark_padlock", 0, LOCK_POS["jump_rope"])
	tooltip(img, 316, 150, ["Corda", "Depois da esteira."])
	put(img, "cursor_glove", 0, Vector2i(306, 198))
	# ---- HUD: Treino grande (N1), Dinheiro discreto (N2), Fama e Legado pequenos no canto (N3: valor cheio na dica)
	ns(img, "ui_panel", 0, 0, 640, 18)
	put(img, "icon_treino", 0, Vector2i(6, 5))
	var x := 18 + T(img, "816", 18, 2, TOK.col_treino, 2) + 6
	x += T(img, "+35/s", x, 6, TOK.col_treino) + 40
	put(img, "icon_money", 0, Vector2i(x, 5))
	T(img, "$ 120", x + 12, 6, TOK.col_money)
	L.text_right(img, "FUNDO DE GARAGEM", 634, 6, TOK.col_text_2, 1, "ink")
	put(img, "icon_fame", 0, Vector2i(486, 5)); T(img, "0", 497, 6, TOK.col_fame)
	put(img, "icon_legacy", 0, Vector2i(510, 5)); T(img, "0", 521, 6, TOK.col_legacy)
	# ---- coluna esquerda: próxima luta + atributos; sem descrição do local, sem "compre a corda"
	ns(img, "ui_panel", 0, 18, 128, 272)
	T(img, "PRÓXIMA LUTA", 8, 26, TOK.col_text_1)
	L.R(img, 8, 35, 112, 1, "g0")
	T(img, "Dudu Alongado", 8, 41, TOK.col_text_1)
	ns(img, "ui_risk_hard", 8, 53, 70, 11)
	put(img, "icon_risk_hard", 0, Vector2i(11, 54))
	T(img, "PERIGOSO", 23, 55, "white")
	T(img, "ATRIBUTOS", 8, 92, TOK.col_text_1)
	L.R(img, 8, 101, 112, 1, "g0")
	attr_row(img, 108, "icon_strength", "FORÇA", "321", 0.55, TOK.col_strength, "ui_bar_fill_strength")
	attr_row(img, 134, "icon_agility", "AGILIDADE", "60", 0.0, TOK.col_agility, "ui_bar_fill_agility", false)
	attr_row(img, 160, "icon_endurance", "RESISTÊNCIA", "200", 0.0, TOK.col_endurance, "ui_bar_fill_endurance", false)
	# ---- coluna direita: o comprável mais barato brilha; sem saldo fica apagado; trancado em 1 linha
	ns(img, "ui_panel", 512, 18, 128, 272)
	ns(img, "ui_button_hover", 516, 22, 58, 16)
	L.R(img, 519, 39, 52, 1, TOK.col_treino)
	put(img, "icon_treino", 0, Vector2i(521, 25)); T(img, "TREINO", 533, 26, TOK.col_text_1)
	ns(img, "ui_button_disabled", 578, 22, 58, 16)
	T(img, "LOJA", 596, 26, TOK.col_text_2)
	T(img, "EQUIPE", 518, 46, TOK.col_text_1)
	L.R(img, 518, 55, 116, 1, "g0")
	shop_card(img, 60, "icon_neighbor", "Vizinho", "x3  +1/s cada", "118", "best")
	shop_card(img, 98, "icon_uncle", "Tio", "x3  +8/s cada", "4.89K", "cannot")
	T(img, "APARELHOS", 518, 142, TOK.col_text_1)
	L.R(img, 518, 151, 116, 1, "g0")
	shop_card(img, 156, "icon_bag", "Saco", "clique x3", "300", "can")
	# trancados: 1 linha cada
	for i in 2:
		var yy := 196 + i * 14
		ns(img, "ui_card_dim", 516, yy, 120, 12)
		put(img, "mark_padlock", 0, Vector2i(523, yy + 6))
		L.text(img, ["Corda", "Boneco"][i], 532, yy + 3, TOK.col_disabled)
	# ---- barra de baixo: por clique grande, LUTAR com a cor do risco; sem "segure shift", sem "espaço ou clique", sem F11
	ns(img, "ui_panel", 0, 290, 640, 70)
	L.text(img, "por clique", 8, 298, TOK.col_text_2)
	T(img, "+1", 8, 310, TOK.col_treino, 2)
	L.text(img, "auto +35/s", 8, 332, TOK.col_text_2)
	L.text(img, "foco de treino", 134, 297, TOK.col_text_2)
	var fx := [134, 228, 322, 416]
	ns(img, "ui_button_focus_strength", fx[0], 308, 90, 34)
	put(img, "icon_strength", 0, Vector2i(fx[0] + 6, 319)); T(img, "FORÇA", fx[0] + 18, 313, "white"); L.text(img, "Saco", fx[0] + 18, 324, "cream")
	L.R(img, fx[0] + 3, 344, 84, 2, TOK.col_strength)
	var locked := [["ESTEIRA", "na caixa"], ["CORDA", ""], ["BONECO", ""]]
	for i in 3:
		ns(img, "ui_button_focus_locked_locked", fx[i + 1], 308, 90, 34)
		if i == 0:
			var mini_box: Image = frame_of("box_small", 0).get_region(Rect2i(9, 11, 30, 28))
			img.blend_rect(mini_box, Rect2i(0, 0, 30, 28), Vector2i(fx[1] + 4, 310))
			L.text(img, "ESTEIRA", fx[1] + 38, 313, TOK.col_text_2)
			L.text(img, "na caixa", fx[1] + 38, 324, TOK.col_disabled)
		else:
			put(img, "mark_padlock", 0, Vector2i(fx[i + 1] + 10, 324))
			L.text(img, str(locked[i][0]), fx[i + 1] + 20, 318, TOK.col_disabled)
	ns(img, "ui_button_fight_normal", 516, 296, 118, 38)
	put(img, "icon_fight", 0, Vector2i(526, 305))
	L.text(img, "LUTAR!", 548, 306, "white", 2, "r0")
	ns(img, "ui_button_retire_normal", 516, 338, 118, 18)
	L.text_center(img, "APOSENTAR", 575, 342, "white", 1, "p0")
	return img

func badge(img: Image, n: String, x: int, y: int, c: String) -> void:
	L.R(img, x - 1, y - 1, 11, 11, "ink")
	L.R(img, x, y, 9, 9, c)
	L.text(img, n, x + 2, y + 1, "ink")

func make_mock_before_after() -> void:
	var before: Image = null
	var cap := OS.get_environment("APPDATA") + "/Godot/app_userdata/Fightclicker/ui_audit_saida/f5_garagem_boneco_depois.png"
	if FileAccess.file_exists(cap):
		before = Image.load_from_file(cap)
	var W := 660
	var H := 14 + 12 + 360 + 8 + 12 + 360 + 8 + 112
	var img: Image = L.blank(W, H)
	L.R(img, 0, 0, W, H, "ink")
	L.R(img, 0, 0, W, 13, "d1")
	T(img, "FIGHTCLICKER - FASE 5.1 - GARAGEM CLARA: HOJE X OS 3 NÍVEIS (MOCKUP, X2)", 10, 3, "white")
	caption(img, "ANTES (CAPTURA DE HOJE): TUDO COM O MESMO PESO, 3 PLAQUINHAS NA SALA, CUSTO REPETIDO", 10, 15, 640, "r3")
	if before != null:
		before.convert(Image.FORMAT_RGBA8)
		before.resize(640, 360, Image.INTERPOLATE_NEAREST)
		img.blit_rect(before, Rect2i(0, 0, 640, 360), Vector2i(10, 27))
	var y2 := 27 + 360 + 8
	caption(img, "DEPOIS: 1 = SEMPRE VISÍVEL E GRANDE    2 = VISÍVEL E DISCRETO    3 = SÓ NO HOVER", 10, y2, 640, "gr3")
	var aft := after_screen()
	img.blit_rect(aft, Rect2i(0, 0, 640, 360), Vector2i(10, y2 + 12))
	var oy := y2 + 12
	# selos de nível por cima do "depois"
	for b in [["1", 100, 4, "gr3"], ["1", 44, 310, "gr3"], ["1", 366, 228, "gr3"], ["1", 506, 300, "gr3"], ["1", 478, 222, "gr3"],
			["2", 180, 4, "y1"], ["2", 112, 40, "y1"], ["2", 112, 92, "y1"], ["2", 502, 62, "y1"], ["2", 122, 312, "y1"],
			["3", 474, 4, "b3"], ["3", 400, 150, "b3"], ["3", 502, 198, "b3"]]:
		badge(img, str(b[0]), 10 + int(b[1]), oy + int(b[2]), str(b[3]))
	# ---- legenda: tokens
	var ly := oy + 360 + 8
	L.R(img, 10, ly, 640, 104, "d1")
	var cols := [["MOEDAS", ["col_treino", "col_money", "col_fame", "col_legacy"]], ["ATRIBUTOS (JÁ EXISTEM)", ["col_strength", "col_agility", "col_endurance", "col_art"]], ["TEXTO", ["col_text_1", "col_text_2", "col_disabled", "col_buyable"]]]
	var samp := {"col_treino": "816  +35/s", "col_money": "$ 120", "col_fame": "12 fama", "col_legacy": "100 legado", "col_strength": "FORÇA", "col_agility": "AGILIDADE", "col_endurance": "RESISTÊNCIA", "col_art": "arte (fundo)",
		"col_text_1": "Texto principal", "col_text_2": "rótulo, sem saldo", "col_disabled": "trancado", "col_buyable": "contorno comprável"}
	for ci in cols.size():
		var cx := 16 + ci * 150
		T(img, str(cols[ci][0]), cx, ly + 5, "white")
		var names: Array = cols[ci][1]
		for i in names.size():
			var yy := ly + 18 + i * 20
			var pal: String = TOK[names[i]]
			L.R(img, cx, yy, 12, 12, "ink"); L.R(img, cx + 1, yy + 1, 10, 10, pal)
			L.text(img, "%s = %s" % [names[i], pal], cx + 16, yy - 1, "g2")
			L.text(img, str(samp[names[i]]), cx + 16, yy + 8, pal)
	var sx := 16 + 3 * 150
	T(img, "TAMANHOS (FONTE 5X7)", sx, ly + 5, "white")
	T(img, "816", sx, ly + 18, "gr3", 2)
	L.text(img, "txt_hero = x2 (14 px)", sx + 44, ly + 22, "g2")
	T(img, "ATRIBUTOS", sx, ly + 40, "white"); L.R(img, sx, ly + 49, 56, 1, "g0")
	L.text(img, "txt_title = x1 + filete", sx + 64, ly + 40, "g2")
	L.text(img, "por clique", sx, ly + 58, "g2")
	L.text(img, "txt_body = x1", sx + 64, ly + 58, "g2")
	L.text(img, "Sem fonte nova. Sem vermelho", sx, ly + 76, "cream")
	L.text(img, "em preço: sem saldo = apagado.", sx, ly + 86, "cream")
	save_x(img, MOCK + "fase51_garagem_antes_depois_x2.png", 2)

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
	# relê o manifest NA HORA de gravar: o Artista de Personagens edita o mesmo arquivo em paralelo
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível na hora de gravar; nada foi escrito")
		return
	var doc: Dictionary = intify(j.data)
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 5.1") < 0:
		doc["_sobre"] = sobre + " Fase 5.1 (garagem clara, caixa da escola, gancho da corda): tools/art/make_sprites_fase51.gd (rodar por último)."
	var sp: Dictionary = doc.get("sprites", {})
	for id in M:
		sp[id] = intify(M[id])
	# o efeito de chegada da corda acompanha o gancho
	if sp.has("fx_arrive_sparkle"):
		sp["fx_arrive_sparkle"]["positions"] = {"prego": xy(HOOK)}
	doc["sprites"] = sp
	var lay: Dictionary = doc.get("layout", {})
	lay["box_slots"] = {"treadmill": xy(BOX_POS.treadmill[1]), "jump_rope": xy(BOX_POS.jump_rope[1]), "art": xy(BOX_POS.grappling_dummy[1]), "glove": xy(BOX_POS.glove[1]),
		"_nota": "Pivô da caixa (meio da base, no chão), igual na garagem e na academia. Fora da faixa do lutador e do alvo (x 281..362) com 8 px de folga; nenhuma caixa encosta na outra. A da corda fica no pé da parede, embaixo do gancho; a da luva na frente, à direita do alvo. Ordenar por y do pivô, como as pessoas."}
	lay["rope_hook"] = xy(HOOK)
	doc["layout"] = lay
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["_nota_fase51"] = "Fase 5.1: caixa da escola (by_data_id.box), marcas sem texto (unlock_*.mark_states / lock_pos), gancho da corda em (296,166) e tokens de cor (ui_tokens na raiz)."
	bd["box"] = {
		"sprite_by_item": {"treadmill": "box_big", "grappling_dummy": "box_big", "jump_rope": "box_small", "speed_bag": "box_small", "glove_l1": "box_small", "glove_l2": "box_small"},
		"slot_by_item": {"treadmill": "treadmill", "jump_rope": "jump_rope", "speed_bag": "art", "grappling_dummy": "art", "glove_l1": "glove", "glove_l2": "glove"},
		"slots": "layout.box_slots",
		"frame_by_hits": [0, 1, 2],
		"idle": {"wobble_x": [1, 0, -1, 0], "wobble_fps": 12, "every_s": 4.0, "glint": "fx_box_glint", "glint_offset": {"box_big": [20, -38], "box_small": [11, -22]},
			"note": "Parada: a cada 4 s balança 1 px e toca o fx_box_glint na quina de cima à direita. É o que chama o clique, sem texto."},
		"clicks": [
			{"hit": 1, "frame_after": 1, "shake_x": [-1, 1, -1, 0], "shake_fps": 30, "fx": "fx_box_chips_1", "sfx_sugerido": "block.wav"},
			{"hit": 2, "frame_after": 2, "shake_x": [-2, 2, -2, 1, 0], "shake_fps": 30, "fx": "fx_box_chips_2", "sfx_sugerido": "hit_heavy.wav"},
			{"hit": 3, "frame_after": 3, "shake_x": [-3, 3, -2, 2, 0], "shake_fps": 30, "fx": "fx_box_burst", "screen_shake_px": 1, "sfx_sugerido": "punch_crit.wav + buy.wav"}],
		"fx_pos": "pos da caixa + top_center_offset do sprite (meio de cima da caixa)",
		"open_timeline_s": {"shake": [0.0, 0.15], "burst": [0.0, 0.5], "item_appears": [0.15, 0.6], "open_box_fades": [0.6, 0.9], "settle_and_focus": [0.9, 1.2], "total": 1.2,
			"note": "3º clique: troca para o quadro 3 (aberta) na hora. Aparelho de chão (esteira, boneco): o item nasce dentro da caixa e sobe 8 px e pousa no lugar dele (offsets y -8,-12,-6,0,1,0 a 24 fps), a caixa aberta fica atrás. Aparelho de parede (corda, pera) e luva: o item aparece direto no lugar dele com a animação de pendurar que já existe (fx_arrive_sparkle). Caixa aberta some em 0,3 s piscando (visível/invisível a cada 2 quadros; sem alpha). Total 1,2 s, abaixo do limite de 1,5 s."},
		"tag": {"frame": "ui_box_tag", "stamp": "ui_box_stamp", "symbol": "school_symbol_16", "text_keys": ["box_sender", "box_to", "box_label", "box_stamp"],
			"layout_sugerido": {"size": [104, 40], "symbol": [6, 8], "sender": [26, 8], "to": [26, 17], "item": [6, 28], "stamp_right_bottom": [102, 52]},
			"note": "Etiqueta de papel só na dica de hover da caixa (na sala a etiqueta é ilegível de propósito: nenhum texto fixo sobre a cena). O carimbo passa 12 px da borda de baixo da etiqueta."},
		"symbol": {"provisional": true, "files": ["school_symbol_9", "school_symbol_16", "school_symbol_32"], "note": "Símbolo da escola PROVISÓRIO. Também está pintado dentro de box_big/box_small (9 e 5 px): ao trocar, rodar o gerador de novo."},
		"light": "A caixa não tem a luz da sala aplicada (igual na garagem e na academia): é o objeto novo da cena e precisa saltar ao olho.",
	}
	var locks := {"unlock_jump_rope": "jump_rope", "unlock_treadmill": "treadmill", "unlock_speed_bag": "speed_bag", "unlock_grappling_dummy": "grappling_dummy"}
	for uid in locks:
		if not bd.has(uid):
			continue
		var u: Dictionary = bd[uid]
		var ap: String = locks[uid]
		var m: Array = MARK[ap]
		u["mark_states"] = {"normal": str(m[0]), "hover_or_pulse": str(m[0]) + "_hi", "locked": str(m[0]) + "_dim"}
		u["ghost_dim"] = str(m[1]) + "_dim"
		u["lock"] = "mark_padlock"
		u["lock_pos"] = xy(LOCK_POS[ap])
		u["box"] = {"sprite": "box_" + str(BOX_POS[ap][0]), "pos": xy(BOX_POS[ap][1])}
		u["mark_note_fase51"] = "Fase 5.1: SEM plaquinha (o bloco 'sign' ficou só por compatibilidade e não deve mais ser desenhado). Dá para comprar = marca normal + ghost; com o mouse em cima (ou pulso lento) = marca _hi; trancado = marca _dim + ghost _dim + mark_padlock em lock_pos. Com a caixa esperando, a marca continua embaixo dela e some quando a caixa abre. Texto só na dica (tape_open / tape_locked / tape_short)."
		if ap == "jump_rope":
			u["mark_pos"] = xy(HOOK)
			var arr: Dictionary = u.get("arrive", {})
			arr["fx_pos"] = xy(HOOK)
			u["arrive"] = arr
			var sg: Dictionary = u.get("sign", {})
			sg["top_center"] = [HOOK.x, HOOK.y - 39]
			u["sign"] = sg
		bd[uid] = u
	for cur in [["money", "y1", "col_money"], ["fame", "f2", "col_fame"], ["legacy", "p2", "col_legacy"]]:
		if bd.has(cur[0]):
			bd[cur[0]]["color"] = cur[1]
			bd[cur[0]]["token"] = cur[2]
	doc["by_data_id"] = bd
	doc["ui_tokens"] = {
		"_nota": "Fase 5.1, direcao-visual.md §18. Nomes iguais aos do fase5.1-design.md §3. Valor = nome da cor na paleta (hex ao lado).",
		"colors": {
			"col_treino": ["gr3", "a6d86a"], "col_money": ["y1", "f5d26b"], "col_fame": ["f2", "f59ac0"], "col_legacy": ["p2", "b07ad8"],
			"col_text_1": ["white", "f2ece0"], "col_text_2": ["g2", "8f8890"], "col_disabled": ["g1", "6b6570"], "col_buyable": ["y2", "fff3c4"],
			"col_strength": ["r2", "d4473a"], "col_agility": ["b3", "8fbbe0"], "col_endurance": ["y0", "e0a040"], "col_art": ["p1", "7a4fa0"],
			"col_risk_green": ["gr2", "5aa25a"], "col_risk_yellow": ["y0", "e0a040"], "col_risk_red": ["r2", "d4473a"]},
		"sizes": {"txt_hero": {"font": "fightclicker_5x7", "scale": 2, "font_size": 22}, "txt_title": {"font": "fightclicker_5x7", "scale": 1, "font_size": 11, "extra": "caixa alta, col_text_1, filete g0 de 1 px embaixo"}, "txt_body": {"font": "fightclicker_5x7", "scale": 1, "font_size": 11}},
		"new_palette": {"f0": "7a2a52", "f1": "d4558f", "f2": "f59ac0", "note": "Rampa nova, só de UI, para a Fama. Não usar em cenário nem em personagem."},
	}
	DirAccess.make_dir_recursive_absolute(OUT)
	var fa := FileAccess.open(OUT + "manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()
