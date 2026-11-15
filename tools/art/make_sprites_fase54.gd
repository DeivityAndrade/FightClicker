extends SceneTree
## Fase 5.4 (Diretor de Arte) - PLACEHOLDER gerado por código. Árvore grande (mapa que se revela).
##   ui/map/map_tile_{wall,center,garage,gym,boxing,bjj,campaign} (32x32, ladrilháveis)   materiais das regiões
##   ui/map/map_fog_{25,50,75,100} (32x32, ladrilháveis)                                    neblina em 4 degraus de dither
##   ui/map/map_node_s_*, map_node_b_*, map_node_l_*                                        nós pequeno, marco e ligação por estado
##   ui/map/map_node_link_owned_<a>_<b>                                                     ligação comprada (anel nas 2 cores)
##   ui/map/ui_map_frame, ui_map_topbar, ui_map_viewport_edge, ui_map_close_*               moldura da tela cheia
##   ui/map/ui_map_region_label_<região>, ui_map_price_ok|missing, ui_map_card, ui_map_card_next
##   ui/map/fx_map_reveal (6 quadros), fx_map_buy (5 quadros)
##   ui/ui_map_button_{normal,hover,pressed,glow}                                           botão da sala
##   ui/icon_skill_map, icon_skill_map_9, icon_region_<região>(_9), skill_rope_ready, skill_prep_day, skill_shout_loud
##   docs/arte/mockups/fase54_mapa_x2.png
## Rodar de uma pasta temporária com project.godot vazio:
##   Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_sprites_fase54.gd -- [--final]
## Sem --final grava em <tmp>/out (prévia). Com --final grava no projeto e mexe no manifest SÓ nas chaves desta
## fase (relê o arquivo na hora de gravar).

const ROOT := "E:/Fightclicker/"
const RES := "res://assets/sprites/"
const CAPS := "C:/Users/deivi/AppData/Roaming/Godot/app_userdata/Fightclicker/ui_audit_saida/"
var OUT := ""
var MOCK := ""
var FINAL := false
var L
var OLD := {}
var M := {}
var F := {}

const REGIONS := ["garage", "gym", "boxing", "bjj", "campaign"]
## anel do nó comprado: [tom médio, tom claro]
const TONES := {"red": ["r2", "r3"], "gold": ["y0", "y1"], "purple": ["p1", "p2"], "chalk": ["g3", "white"],
	"green": ["gr2", "gr3"], "blue": ["b2", "b3"]}
const TONE_BY := {"body": "red", "career": "gold", "style": "purple", "garage": "chalk", "gym": "green",
	"boxing": "red", "bjj": "blue", "campaign": "gold"}
const TILE_BY := {"center": "map_tile_center", "garage": "map_tile_garage", "gym": "map_tile_gym", "boxing": "map_tile_boxing",
	"bjj": "map_tile_bjj", "campaign": "map_tile_campaign", "wall": "map_tile_wall"}

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

func ol(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

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
		return F[id][i]
	var e := spr(id)
	var img := load_abs(ROOT + str(e.file).replace("res://", ""))
	var fw: int = int(e.frame_size[0])
	var fh: int = int(e.frame_size[1])
	return img.get_region(Rect2i(i * fw, 0, fw, fh))

func blend(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func put(dst: Image, id: String, i: int, x: int, y: int) -> void:
	blend(dst, frame_of(id, i), x, y)

## desenha centrado no pivô
func putc(dst: Image, id: String, i: int, x: int, y: int) -> void:
	var p: Array = spr(id).get("pivot", [0, 0])
	blend(dst, frame_of(id, i), x - int(p[0]), y - int(p[1]))

func put_k(dst: Image, img: Image, x: int, y: int, k: int) -> void:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	blend(dst, b, x, y)

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

func intify(v):
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = v[k] if str(k).ends_with("fps") else intify(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(intify(x))
		return a
	if v is float and v == floor(v) and absf(v) < 1e9:
		return int(v)
	return v

## ruído determinístico, periódico em 32 (para ladrilhar)
func hsh(x: int, y: int, s: int) -> float:
	var xx := posmod(x, 32)
	var yy := posmod(y, 32)
	var n: int = (xx * 374761393 + yy * 668265263 + s * 982451653) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	n = n ^ (n >> 16)
	return float(n % 10000) / 10000.0

## ruído de valor suave, periódico em 32 (grade de s px)
func vnoise(x: int, y: int, s: int, seed: int) -> float:
	var gx := x / s
	var gy := y / s
	var fx := float(x % s) / s
	var fy := float(y % s) / s
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := hsh(gx * s, gy * s, seed)
	var b := hsh((gx + 1) * s, gy * s, seed)
	var c := hsh(gx * s, (gy + 1) * s, seed)
	var d := hsh((gx + 1) * s, (gy + 1) * s, seed)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)

func bayer(x: int, y: int) -> int:
	return L.BAYER[posmod(y, 4)][posmod(x, 4)]

func oct(img: Image, x: int, y: int, w: int, h: int, cut: int, c) -> void:
	for yy in h:
		var ins := maxi(0, maxi(cut - yy, cut - (h - 1 - yy)))
		L.R(img, x + ins, y + yy, w - 2 * ins, 1, c)

func star_fill(img: Image, cx: float, cy: float, ro: float, ri: float, c, rot := -PI / 2.0) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := rot + i * PI / 5.0
		var r := ro if i % 2 == 0 else ri
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	for y in range(int(cy - ro) - 1, int(cy + ro) + 2):
		for x in range(int(cx - ro) - 1, int(cx + ro) + 2):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				L.P(img, x, y, c)

func edge_mask(src: Image, c) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out: Image = L.blank(w, h)
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a == 0.0:
				continue
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or src.get_pixel(q.x, q.y).a == 0.0:
					edge = true
			if edge:
				L.P(out, x, y, c)
	return out

# ================================================================ ladrilhos 32x32
func tile_wall() -> Image:
	var im: Image = L.blank(32, 32)
	L.R(im, 0, 0, 32, 32, "d1")
	for y in 32:
		for x in 32:
			var h := hsh(x, y, 1)
			if h > 0.94:
				L.P(im, x, y, "d2")
			elif h < 0.05:
				L.P(im, x, y, "ink")
	return im

func tile_center() -> Image:   # cortiça
	var im: Image = L.blank(32, 32)
	L.R(im, 0, 0, 32, 32, "br1")
	for y in 32:
		for x in 32:
			var h := hsh(x, y, 2)
			if h > 0.80:
				L.P(im, x, y, "br2")
			elif h < 0.13:
				L.P(im, x, y, "br0")
			if h > 0.992:
				L.P(im, x, y, "br3")
	return im

func tile_garage() -> Image:   # concreto em blocos 16x8, junta corrida
	var im: Image = L.blank(32, 32)
	L.R(im, 0, 0, 32, 32, "g0")
	for y in 32:
		for x in 32:
			var h := hsh(x, y, 3)
			if h > 0.90:
				L.P(im, x, y, "g1")
			elif h < 0.06:
				L.P(im, x, y, "d2")
	for row in 4:
		var y0 := row * 8
		L.R(im, 0, y0 + 7, 32, 1, "d2")
		var off := 0 if row % 2 == 0 else 8
		for k in 2:
			L.R(im, posmod(off + k * 16 + 15, 32), y0, 1, 7, "d2")
	# luz de cima em cada bloco
	for row in 4:
		for x in 32:
			if hsh(x, row, 9) > 0.55:
				L.P(im, x, row * 8, "g1")
	return im

func tile_gym() -> Image:   # azulejo verde 8x8
	var im: Image = L.blank(32, 32)
	L.R(im, 0, 0, 32, 32, "gr1")
	for k in 4:
		L.R(im, 0, k * 8 + 7, 32, 1, "gr0")
		L.R(im, k * 8 + 7, 0, 1, 32, "gr0")
	for ty in 4:
		for tx in 4:
			if hsh(tx, ty, 4) > 0.35:
				L.P(im, tx * 8 + 1, ty * 8 + 1, "gr2")
				L.P(im, tx * 8 + 2, ty * 8 + 1, "gr2")
				L.P(im, tx * 8 + 1, ty * 8 + 2, "gr2")
			if hsh(tx, ty, 14) > 0.85:
				L.P(im, tx * 8 + 5, ty * 8 + 4, "gr0")
	return im

func tile_boxing() -> Image:   # lona do ringue
	var im: Image = L.blank(32, 32)
	L.R(im, 0, 0, 32, 32, "r0")
	for y in 32:
		for x in 32:
			if (x + 2 * y) % 8 == 0 and hsh(x, y, 5) > 0.25:
				L.P(im, x, y, "r1")
			elif hsh(x, y, 15) < 0.05:
				L.P(im, x, y, "ink")
	return im

func tile_bjj() -> Image:   # tatame azul em placas 16x16
	var im: Image = L.blank(32, 32)
	L.R(im, 0, 0, 32, 32, "b1")
	for y in 32:
		for x in 32:
			if x % 3 == 1 and y % 3 == 1 and hsh(x, y, 6) > 0.4:
				L.P(im, x, y, "b0")
	for k in 2:
		L.R(im, 0, k * 16 + 15, 32, 1, "b0")
		L.R(im, k * 16 + 15, 0, 1, 32, "b0")
	for k in 2:
		for x in 32:
			if x % 16 != 15 and hsh(x, k, 16) > 0.5:
				L.P(im, x, k * 16, "b2")
	return im

func tile_campaign() -> Image:   # feltro roxo do mural das campanhas
	var im: Image = L.blank(32, 32)
	L.R(im, 0, 0, 32, 32, "p0")
	for y in 32:
		for x in 32:
			var h := hsh(x, y, 7)
			if h > 0.90:
				L.P(im, x, y, "p1")
				L.P(im, (x + 1) % 32, y, "p1")
			elif h < 0.06:
				L.P(im, x, y, "ink")
	return im

## neblina: ink com nuvens d1 de baixa frequência (periódica em 32), mascarada por Bayer
func fog_tile(level: int) -> Image:
	var im: Image = L.blank(32, 32)
	for y in 32:
		for x in 32:
			if bayer(x, y) >= level * 4:
				continue
			var v := vnoise(x, y, 8, 40) * 0.7 + vnoise(x, y, 4, 41) * 0.3
			var c := "ink"
			if (v > 0.62 and bayer(x, y) < 6) or (v > 0.5 and bayer(x, y) < 2):
				c = "d1"
			if v > 0.85 and bayer(x + 1, y + 2) < 1:
				c = "d2"
			L.P(im, x, y, c)
	return im

# ================================================================ nós
## frame de nó pequeno 24x24 / marco 38x38 / ligação 28x24
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

func add_pin(im: Image, x: int, y: int) -> void:
	L.ellipse(im, x + 2.5, y + 2.5, 3.0, 3.0, "ink")
	L.ellipse(im, x + 2.5, y + 2.5, 2.0, 2.0, "y0")
	L.P(im, x + 2, y + 2, "y1")
	L.P(im, x + 1, y + 1, "y2")
	L.P(im, x + 3, y + 3, "br2")

func node_big(ring_out, ring_in, fill, fill_hi, pin := false, spikes = null) -> Image:
	var im: Image = L.blank(38, 38)
	var sp = spikes if spikes != null else ring_in
	# pontas N/S/L/O (marco)
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

func node_link(ring_l_out, ring_l_in, ring_r_out, ring_r_in, fill, fill_hi, clasp_l, clasp_r, pin := false) -> Image:
	var im: Image = L.blank(28, 24)
	# elos laterais
	for side in [0, 1]:
		var x0 := 0 if side == 0 else 24
		L.R(im, x0, 8, 4, 8, "ink")
		L.R(im, x0 + 1, 9, 2, 6, clasp_l if side == 0 else clasp_r)
	var a: Image = node_small(ring_l_out, ring_l_in, fill, fill_hi, false)
	var b: Image = node_small(ring_r_out, ring_r_in, fill, fill_hi, false)
	var mix: Image = L.blank(24, 24)
	for y in 24:
		for x in 24:
			mix.set_pixel(x, y, a.get_pixel(x, y) if x + (23 - y) < 24 else b.get_pixel(x, y))
	blend(im, mix, 2, 0)
	if pin:
		add_pin(im, 20, 0)
	return im

func q_mark(im: Image, cx: int, cy: int, c) -> void:
	var rows := [".###.", "#...#", "...#.", "..#..", ".....", "..#.."]
	for i in rows.size():
		for j in 5:
			if rows[i][j] == "#":
				L.P(im, cx - 2 + j, cy - 3 + i, c)

func veil(w: int, h: int, level := 8) -> Image:
	var im: Image = L.blank(w, h)
	for y in h:
		for x in w:
			if bayer(x, y) < level:
				L.P(im, x, y, "ink")
	return im

# ================================================================ moldura / UI do mapa
func map_frame() -> Image:   # 9-slice 24x24, borda 5: quadro de madeira da escola
	var im: Image = L.blank(24, 24)
	L.R(im, 0, 0, 24, 24, "ink")
	L.R(im, 1, 1, 22, 22, "br1")
	L.R(im, 1, 1, 22, 1, "br2")
	L.R(im, 1, 1, 1, 22, "br2")
	L.R(im, 2, 2, 20, 1, "br3")
	L.R(im, 1, 3, 22, 1, "br1")
	for x in range(2, 22):
		if hsh(x, 5, 21) > 0.7:
			L.P(im, x, 2, "br2")
	L.R(im, 4, 4, 16, 16, "ink")
	L.R(im, 1, 21, 22, 2, "br0")
	L.R(im, 21, 1, 2, 22, "br0")
	# pregos nos cantos
	for p in [[2, 2], [19, 2], [2, 19], [19, 19]]:
		L.R(im, p[0], p[1], 2, 2, "g2")
		L.P(im, p[0], p[1], "g3")
		L.P(im, p[0] + 1, p[1] + 1, "g0")
	var c: Image = L.blank(24, 24)
	c.blit_rect(im, Rect2i(0, 0, 24, 24), Vector2i.ZERO)
	L.R(c, 5, 5, 14, 14, Color(0, 0, 0, 0))
	return c

func map_topbar() -> Image:   # 9-slice 16x20
	var im: Image = L.blank(16, 20)
	L.R(im, 0, 0, 16, 20, "d1")
	L.R(im, 0, 0, 16, 1, "d2")
	L.R(im, 0, 18, 16, 1, "g0")
	L.R(im, 0, 19, 16, 1, "ink")
	return im

func viewport_edge() -> Image:   # 9-slice 8x8 por cima da borda do mapa (miolo vazio)
	var im: Image = L.blank(8, 8)
	L.R(im, 0, 0, 8, 1, "ink")
	L.R(im, 0, 0, 1, 8, "ink")
	L.R(im, 7, 0, 1, 8, "ink")
	L.R(im, 0, 7, 8, 1, "ink")
	for x in range(1, 7):
		if x % 2 == 1:
			L.P(im, x, 1, "ink")
	for y in range(1, 7):
		if y % 2 == 1:
			L.P(im, 1, y, "ink")
	return im

func close_btn(state: String) -> Image:
	var im: Image = L.blank(16, 16)
	var dy := 1 if state == "pressed" else 0
	L.R(im, 0, dy, 16, 15, "ink")
	var bg := "r1" if state == "hover" else ("r0" if state == "pressed" else "d2")
	L.R(im, 1, 1 + dy, 14, 13, bg)
	if state != "pressed":
		L.R(im, 1, 1, 14, 1, L.shade(L.col(bg), 1))
		L.R(im, 1, 15, 15, 1, "ink")
	var fg := "white" if state != "normal" else "g3"
	for k in 6:
		L.R(im, 4 + k, 4 + k + dy, 2, 1, fg)
		L.R(im, 10 - k, 4 + k + dy, 2, 1, fg)
	return im

func region_label(tone: String) -> Image:   # 9-slice 16x13
	var im: Image = L.blank(16, 13)
	L.R(im, 0, 0, 16, 13, "ink")
	L.R(im, 1, 1, 14, 11, "d1")
	L.R(im, 1, 1, 14, 1, "d2")
	L.R(im, 1, 1, 3, 11, TONES[tone][0])
	L.R(im, 1, 1, 3, 1, TONES[tone][1])
	L.R(im, 1, 13 - 1, 15, 0, "ink")
	return im

func price_tag(ok: bool) -> Image:   # 9-slice 12x11
	var im: Image = L.blank(12, 11)
	L.R(im, 0, 0, 12, 11, "ink")
	L.R(im, 1, 1, 10, 9, "p0" if ok else "d1")
	L.R(im, 1, 1, 10, 1, "p1" if ok else "d2")
	return im

func card() -> Image:   # 9-slice 16x16
	var im: Image = L.blank(16, 16)
	L.R(im, 0, 0, 16, 16, "ink")
	L.R(im, 1, 1, 14, 14, "d1")
	L.R(im, 1, 1, 14, 1, "d2")
	L.R(im, 1, 14, 14, 1, "ink")
	return im

func card_next() -> Image:   # 9-slice 16x13: faixa 'VALE NA PRÓXIMA CAMPANHA'
	var im: Image = L.blank(16, 13)
	L.R(im, 0, 0, 16, 13, "p0")
	L.R(im, 0, 0, 16, 1, "p1")
	for x in 16:
		if x % 4 < 2:
			L.P(im, x, 12, "ink")
	return im

# ================================================================ ícones
func icon_skill_map(sz := 16) -> Image:
	if sz == 9:
		var s: Image = L.blank(9, 9)
		L.R(s, 0, 0, 9, 8, "ink")
		L.R(s, 1, 1, 7, 6, "br2")
		L.P(s, 2, 2, "br3")
		L.P(s, 5, 4, "br1")
		L.line(s, 2, 5, 4, 3, "cream")
		L.line(s, 4, 3, 6, 4, "cream")
		L.P(s, 2, 5, "r3")
		L.P(s, 4, 2, "y1")
		L.P(s, 6, 4, "gr3")
		L.R(s, 1, 8, 7, 1, "br0")
		return s
	var im: Image = L.blank(16, 16)
	L.R(im, 1, 2, 14, 12, "br1")
	L.R(im, 2, 3, 12, 10, "br2")
	for y in range(3, 13):
		for x in range(2, 14):
			if hsh(x, y, 31) > 0.78:
				L.P(im, x, y, "br3")
			elif hsh(x, y, 31) < 0.12:
				L.P(im, x, y, "br1")
	L.R(im, 1, 13, 14, 1, "br0")
	# barbante entre 3 tachinhas
	L.line(im, 4, 10, 8, 5, "cream")
	L.line(im, 8, 5, 12, 9, "cream")
	for p in [[4, 10, "r2", "r3"], [8, 5, "y0", "y2"], [12, 9, "gr2", "gr3"]]:
		L.R(im, p[0] - 1, p[1] - 1, 3, 3, p[2])
		L.P(im, p[0] - 1, p[1] - 1, p[3])
	return ol(im)

func icon_region(r: String) -> Image:
	var im: Image = L.blank(16, 16)
	match r:
		"garage":
			# fachada de garagem: telhado, portão de aço com ripas, marca de giz
			for k in 6:
				L.R(im, 7 - k, 1 + k, 2 + 2 * k, 1, "g1")
			L.R(im, 2, 6, 12, 9, "g0")
			L.R(im, 2, 6, 12, 1, "g1")
			L.R(im, 4, 8, 8, 7, "st1")
			for k in 3:
				L.R(im, 4, 9 + k * 2, 8, 1, "st2")
			L.R(im, 4, 8, 8, 1, "st3")
			L.P(im, 13, 13, "cream")
			L.P(im, 12, 12, "cream")
		"gym":
			# halter sobre azulejo verde
			L.R(im, 1, 2, 14, 12, "gr1")
			L.R(im, 1, 7, 14, 1, "gr0")
			L.R(im, 7, 2, 1, 12, "gr0")
			L.P(im, 2, 3, "gr2")
			L.P(im, 9, 3, "gr2")
			L.R(im, 3, 8, 10, 2, "st3")
			L.R(im, 1, 6, 3, 6, "st1")
			L.R(im, 12, 6, 3, 6, "st1")
			L.R(im, 1, 6, 3, 1, "st2")
			L.R(im, 12, 6, 3, 1, "st2")
		"boxing":
			# canto do ringue: poste e 3 cordas
			L.R(im, 1, 13, 14, 2, "b1")
			L.R(im, 2, 1, 3, 13, "r1")
			L.R(im, 3, 1, 1, 12, "r2")
			L.R(im, 2, 1, 3, 1, "r3")
			for k in 3:
				var c: String = ["white", "r2", "b2"][k]
				L.R(im, 5, 3 + k * 4, 10, 1, c)
				L.R(im, 5, 4 + k * 4, 10, 1, L.shade(L.col(c), -1) if c != "white" else "g3")
		"bjj":
			# nó da faixa sobre o tatame
			L.R(im, 1, 9, 14, 6, "b1")
			L.R(im, 1, 9, 14, 1, "b2")
			L.R(im, 2, 4, 12, 3, "p1")
			L.R(im, 2, 4, 12, 1, "p2")
			L.R(im, 6, 3, 4, 5, "p0")
			L.R(im, 7, 3, 2, 1, "p2")
			L.line(im, 7, 8, 5, 13, "p1")
			L.line(im, 8, 8, 10, 13, "p1")
			L.P(im, 4, 13, "p0")
			L.P(im, 11, 13, "p0")
			L.R(im, 11, 4, 1, 3, "ink")
		"campaign":
			# folhinha com estrela (mural das campanhas)
			L.R(im, 2, 2, 12, 13, "cream")
			L.R(im, 2, 2, 12, 4, "r2")
			L.R(im, 2, 2, 12, 1, "r3")
			L.P(im, 5, 1, "g2")
			L.P(im, 10, 1, "g2")
			L.R(im, 13, 6, 1, 9, "g3")
			star_fill(im, 8.0, 10.5, 4.0, 1.8, "y0")
			L.P(im, 7, 9, "y1")
	return ol(im)

func icon_region_9(r: String) -> Image:
	var im: Image = L.blank(9, 9)
	match r:
		"garage":
			L.R(im, 3, 1, 3, 1, "g1")
			L.R(im, 2, 2, 5, 1, "g1")
			L.R(im, 1, 3, 7, 5, "g0")
			L.R(im, 2, 4, 5, 4, "st1")
			L.R(im, 2, 5, 5, 1, "st2")
			L.R(im, 2, 7, 5, 1, "st2")
		"gym":
			L.R(im, 2, 4, 5, 1, "st3")
			L.R(im, 1, 2, 2, 5, "st1")
			L.R(im, 6, 2, 2, 5, "st1")
			L.R(im, 1, 2, 2, 1, "st2")
			L.R(im, 6, 2, 2, 1, "st2")
			L.R(im, 0, 7, 9, 1, "gr2")
		"boxing":
			L.R(im, 1, 1, 2, 7, "r2")
			L.R(im, 3, 2, 5, 1, "white")
			L.R(im, 3, 4, 5, 1, "r2")
			L.R(im, 3, 6, 5, 1, "b2")
		"bjj":
			L.R(im, 1, 2, 7, 2, "p1")
			L.R(im, 3, 1, 3, 3, "p0")
			L.line(im, 3, 4, 2, 7, "p1")
			L.line(im, 5, 4, 6, 7, "p1")
			L.R(im, 0, 7, 9, 1, "b2")
		"campaign":
			L.R(im, 1, 1, 7, 7, "cream")
			L.R(im, 1, 1, 7, 2, "r2")
			L.R(im, 3, 4, 3, 3, "y0")
			L.P(im, 4, 5, "y1")
	return ol(im)

func skill_rope_ready() -> Image:
	var im: Image = L.blank(16, 16)
	# prego no alto e corda pendurada pronta, com brilho
	L.R(im, 6, 1, 4, 2, "g2")
	L.P(im, 6, 1, "g3")
	L.R(im, 7, 3, 2, 1, "g1")
	# laço da corda
	for p in [[7, 4], [6, 5], [5, 6], [4, 7], [3, 8], [3, 9], [8, 4], [9, 5], [10, 6], [11, 7], [12, 8], [12, 9]]:
		L.P(im, p[0], p[1], "cream")
	L.R(im, 6, 4, 4, 1, "cream")
	L.line(im, 3, 10, 3, 12, "cream")
	L.line(im, 12, 10, 12, 12, "cream")
	L.P(im, 4, 9, "g3")
	L.P(im, 11, 9, "g3")
	# punhos
	L.R(im, 2, 12, 3, 3, "br2")
	L.R(im, 11, 12, 3, 3, "br2")
	L.P(im, 2, 12, "br3")
	L.P(im, 11, 12, "br3")
	var o := ol(im)
	# brilho de "já montada"
	for p in [[13, 2], [13, 4], [12, 3], [14, 3]]:
		L.P(o, p[0], p[1], "y1")
	L.P(o, 13, 3, "y2")
	return o

func skill_prep_day() -> Image:
	var im: Image = L.blank(16, 16)
	L.R(im, 1, 2, 13, 13, "cream")
	L.R(im, 1, 2, 13, 4, "r2")
	L.R(im, 1, 2, 13, 1, "r3")
	L.P(im, 4, 1, "g2")
	L.P(im, 10, 1, "g2")
	L.R(im, 13, 6, 1, 9, "g3")
	# "+1" verde
	L.R(im, 3, 9, 5, 1, "gr1")
	L.R(im, 5, 7, 1, 5, "gr1")
	L.R(im, 9, 7, 2, 1, "d1")
	L.R(im, 10, 7, 1, 6, "d1")
	L.R(im, 9, 12, 3, 1, "d1")
	return ol(im)

func skill_shout_loud() -> Image:
	var im: Image = L.blank(16, 16)
	# megafone verde maior, virado para a direita
	L.R(im, 1, 6, 3, 4, "gr1")
	L.R(im, 1, 6, 3, 1, "gr2")
	for k in 6:
		L.R(im, 4 + k, 6 - k / 2 - (1 if k > 2 else 0), 1, 4 + k + (2 if k > 2 else 0), "gr2")
	L.R(im, 4, 6, 6, 1, "gr3")
	L.R(im, 9, 2, 1, 12, "gr1")
	L.R(im, 2, 10, 2, 3, "g1")
	var o := ol(im)
	# 3 ondas fortes
	for k in 3:
		var x := 11 + k * 2
		var h := 3 + k * 2
		L.R(o, x, 8 - h / 2 - 1, 1, h + 1, "y1" if k < 2 else "y0")
	L.P(o, 15, 2, "y2")
	L.P(o, 15, 13, "y2")
	return o

# ---------------------------------------------------------------- 2ª passada: ícones dos marcos (fase5.4-design.md §9)
const MILESTONE_ICONS := {"gar_metro": "skill_home_metronome", "gar_crew_start": "skill_crew_regulars",
	"camp_diary": "skill_coach_notebook", "gym_fan": "skill_standing_fan", "box_counter": "skill_counter_punch",
	"bjj_guard": "skill_firm_base"}

func skill_home_metronome() -> Image:   # gar_metro "Pêndulo de casa": metrônomo de madeira em cima de um tijolo
	var im: Image = L.blank(16, 16)
	L.R(im, 2, 12, 12, 3, "r1")
	L.R(im, 2, 12, 12, 1, "r2")
	L.R(im, 2, 14, 12, 1, "r0")
	L.R(im, 7, 13, 1, 1, "r0")
	L.trap(im, 2, 11, 7, 8, 3, 12, "br2")
	L.line(im, 7, 2, 3, 11, "br3")
	L.line(im, 8, 2, 12, 11, "br1")
	L.trap(im, 4, 10, 7, 8, 5, 10, "br0")
	L.line(im, 8, 10, 12, 1, "g3")
	L.R(im, 10, 5, 2, 2, "y0")
	L.P(im, 10, 5, "y1")
	L.P(im, 8, 10, "y1")
	return ol(im)

func slipper(im: Image, x: int, y: int, rp: Array) -> void:   # chinelo 4x7 visto de cima
	L.rrect(im, x, y, 4, 7, rp[0])
	L.R(im, x + 1, y + 1, 2, 5, rp[2])
	L.P(im, x + 1, y + 5, rp[3])
	L.R(im, x + 1, y + 2, 2, 1, "white")
	L.P(im, x, y + 3, "white")
	L.P(im, x + 3, y + 3, "white")

func skill_crew_regulars() -> Image:   # gar_crew_start "Turma de sempre": três chinelos na porta da garagem
	var im: Image = L.blank(16, 16)
	L.R(im, 1, 1, 14, 6, "st1")
	L.R(im, 1, 1, 14, 1, "st3")
	L.R(im, 1, 3, 14, 1, "st2")
	L.R(im, 1, 5, 14, 1, "st2")
	L.R(im, 1, 7, 14, 8, "g1")
	L.R(im, 1, 7, 14, 1, "g0")
	slipper(im, 1, 8, ["b0", "b1", "b2", "b3"])
	slipper(im, 6, 7, ["gr0", "gr1", "gr2", "gr3"])
	slipper(im, 11, 8, ["r0", "r1", "r2", "r3"])
	return ol(im)

func skill_coach_notebook() -> Image:   # camp_diary "Caderno do velho": capa dura com elástico
	var im: Image = L.blank(16, 16)
	L.R(im, 3, 2, 11, 13, "cream")
	for y in range(3, 14, 2):
		L.P(im, 13, y, "g3")
	L.R(im, 3, 14, 11, 1, "g3")
	L.R(im, 2, 1, 10, 13, "p1")
	L.R(im, 2, 1, 10, 1, "p2")
	L.R(im, 2, 1, 2, 13, "p0")
	L.R(im, 5, 4, 5, 3, "cream")
	L.R(im, 6, 5, 3, 1, "g1")
	L.R(im, 10, 1, 1, 14, "d1")
	L.P(im, 6, 14, "r2")
	return ol(im)

func skill_standing_fan() -> Image:   # gym_fan "Ventilador novo": ventilador de coluna
	var im: Image = L.blank(16, 16)
	L.ellipse(im, 8.0, 6.5, 5.0, 5.0, "st1")
	L.ring(im, 8.0, 6.5, 5.0, 5.0, 1.0, "st3")
	for d in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		for k in range(1, 4):
			var bx: int = (8 if d.x > 0 else 7) + d.x * k
			var by: int = (7 if d.y > 0 else 6) + d.y * k
			L.P(im, bx, by, "b3")
			L.P(im, bx - d.x, by, "white" if k == 1 else "b3")
	L.R(im, 7, 6, 2, 2, "y0")
	L.P(im, 7, 6, "y1")
	L.R(im, 7, 11, 2, 2, "st2")
	L.R(im, 4, 13, 8, 2, "st1")
	L.R(im, 4, 13, 8, 1, "st2")
	var o := ol(im)
	L.P(o, 14, 4, "b3")
	L.P(o, 14, 8, "b3")
	return o

func skill_counter_punch() -> Image:   # box_counter "Contragolpe": luva vermelha com seta curva
	var im: Image = L.blank(16, 16)
	L.rrect(im, 1, 4, 9, 8, "r1")
	L.R(im, 2, 5, 6, 5, "r2")
	L.R(im, 2, 5, 2, 1, "r3")
	L.P(im, 2, 6, "r3")
	L.R(im, 2, 8, 5, 1, "r1")
	L.R(im, 6, 9, 3, 2, "r3")
	L.R(im, 2, 12, 7, 3, "white")
	L.R(im, 2, 14, 7, 1, "g3")
	L.P(im, 5, 12, "r1")
	for p in [[12, 12], [13, 11], [14, 10], [14, 9], [14, 8], [14, 7], [14, 6], [13, 5], [13, 4], [12, 3], [11, 2]]:
		L.P(im, p[0], p[1], "y1")
	for p in [[9, 2], [10, 1], [10, 2], [10, 3]]:
		L.P(im, p[0], p[1], "y1")
	L.P(im, 9, 2, "y2")
	return ol(im)

func skill_firm_base() -> Image:   # bjj_guard "Base firme": dois pés firmes no tatame
	var im: Image = L.blank(16, 16)
	L.R(im, 1, 11, 14, 4, "b1")
	L.R(im, 1, 11, 14, 1, "b2")
	L.R(im, 8, 12, 1, 3, "b0")
	L.trap(im, 1, 9, 5, 7, 2, 4, "white")
	L.trap(im, 1, 9, 8, 10, 11, 13, "white")
	L.line(im, 7, 2, 4, 9, "g3")
	L.line(im, 8, 2, 11, 9, "g3")
	L.R(im, 4, 1, 8, 2, "p1")
	L.R(im, 7, 1, 2, 2, "p0")
	L.R(im, 1, 10, 4, 2, "sk1")
	L.R(im, 1, 10, 3, 1, "sk2")
	L.R(im, 11, 10, 4, 2, "sk1")
	L.R(im, 12, 10, 3, 1, "sk2")
	L.P(im, 5, 12, "b3")
	L.P(im, 10, 12, "b3")
	return ol(im)

# ================================================================ botão da sala
func map_button(state: String, glow_fr := -1) -> Image:
	var im: Image = L.blank(22, 22)
	var dy := 1 if state == "pressed" else 0
	L.R(im, 0, dy, 22, 21, "ink")
	var border := "g0"
	var fill := "d1"
	if state == "hover":
		border = "g2"
		fill = "d2"
	if glow_fr >= 0:
		border = "y2" if glow_fr == 0 else "y1"
		fill = "d2" if glow_fr == 0 else "d1"
	L.R(im, 1, 1 + dy, 20, 19, border)
	L.R(im, 2, 2 + dy, 18, 17, fill)
	L.R(im, 2, 2 + dy, 18, 1, L.shade(L.col(fill), 1))
	if state != "pressed":
		L.R(im, 1, 21, 21, 1, "ink")
	blend(im, icon_skill_map(), 3, 3 + dy)
	if glow_fr >= 0:
		# faísca no canto, alterna de lado
		var sx := 18 if glow_fr == 0 else 2
		var sy := 2 if glow_fr == 0 else 17
		L.P(im, sx, sy, "white")
		L.P(im, sx - 1, sy, "y2")
		L.P(im, sx + 1, sy, "y2")
		L.P(im, sx, sy - 1, "y2")
		L.P(im, sx, sy + 1, "y2")
	return im

# ================================================================ efeitos
func fx_reveal(i: int) -> Image:   # 40x40, 6 quadros: a neblina se abre
	var im: Image = L.blank(40, 40)
	var cx := 20.0
	var cy := 20.0
	if i == 0:
		L.ellipse(im, cx, cy, 14, 13, "d1")
		L.ellipse_dither(im, cx, cy, 16, 15, "d2")
		L.ellipse(im, cx, cy, 9, 9, "d2")
		q_mark(im, 20, 20, "g1")
		return im
	var r := 10.0 + i * 3.0
	var n := 10
	for k in n:
		var a := TAU * k / n + i * 0.25
		var len_k := 3 if i < 4 else 2
		if i >= 3 and k % 2 == 1:
			continue
		if i == 5 and k % 4 != 0:
			continue
		for t in len_k:
			var rr := r + t
			var x := int(cx + cos(a) * rr)
			var y := int(cy + sin(a) * rr * 0.9)
			L.P(im, x, y, "g0" if i < 3 else "d2")
			if i < 3:
				L.P(im, x + 1, y, "d2")
	if i <= 2:
		L.ring(im, cx, cy, r - 1, (r - 1) * 0.9, 2.0, "d2" if i == 1 else "d1")
	# faíscas
	if i >= 2:
		var rs := 8.0 + i * 2.0
		for k in 4:
			var a2 := PI / 4.0 + k * PI / 2.0
			var x2 := int(cx + cos(a2) * rs)
			var y2 := int(cy + sin(a2) * rs)
			L.P(im, x2, y2, "white" if i < 5 else "y1")
			if i < 5:
				L.P(im, x2 - 1, y2, "y2")
				L.P(im, x2 + 1, y2, "y2")
				L.P(im, x2, y2 - 1, "y2")
				L.P(im, x2, y2 + 1, "y2")
	return im

func fx_buy(i: int) -> Image:   # 40x40, 5 quadros: o nó acende
	var im: Image = L.blank(40, 40)
	var cx := 20.0
	var cy := 20.0
	match i:
		0:
			oct(im, 7, 7, 26, 26, 7, "white")
			oct(im, 10, 10, 20, 20, 5, Color(0, 0, 0, 0))
		1:
			L.ring(im, cx, cy, 15, 15, 2, "y2")
		2:
			L.ring(im, cx, cy, 18, 18, 1, "y1")
		3:
			for k in 8:
				var a := TAU * k / 8.0
				if k % 2 == 0:
					L.P(im, int(cx + cos(a) * 19), int(cy + sin(a) * 19), "y1")
		4:
			pass
	if i >= 1:
		var rs := 10.0 + i * 3.0
		for k in 4:
			var a2 := k * PI / 2.0 + PI / 4.0 * (i % 2)
			var x2 := int(cx + cos(a2) * rs)
			var y2 := int(cy + sin(a2) * rs)
			L.P(im, x2, y2, "white" if i < 4 else "y1")
			if i < 4:
				for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					L.P(im, x2 + d[0], y2 + d[1], "y2")
	return im

# ================================================================ linhas (procedural, mesma regra da UI)
func draw_link(img: Image, a: Vector2i, b: Vector2i, state: String, phase := 0) -> void:
	var pts := bres(a, b)
	var horiz: bool = absi(b.x - a.x) >= absi(b.y - a.y)
	var off := Vector2i(0, 1) if horiz else Vector2i(1, 0)
	match state:
		"lit":
			for i in pts.size():
				var p: Vector2i = pts[i]
				L.P(img, p.x + off.x * 2, p.y + off.y * 2, "ink")
			for i in pts.size():
				var p: Vector2i = pts[i]
				L.P(img, p.x, p.y, "p2")
				L.P(img, p.x + off.x, p.y + off.y, "p1")
				if (i + phase) % 8 == 0:
					L.P(img, p.x, p.y, "white")
		"open":
			for p in pts:
				L.P(img, p.x + off.x, p.y + off.y, "ink")
			for p in pts:
				L.P(img, p.x, p.y, "g2")
		"dim":
			for i in pts.size():
				if i % 4 < 2:
					L.P(img, pts[i].x, pts[i].y, "g0")

func bres(a: Vector2i, b: Vector2i) -> Array:
	var out := []
	var x0 := a.x
	var y0 := a.y
	var dx := absi(b.x - x0)
	var dy := -absi(b.y - y0)
	var sx := 1 if x0 < b.x else -1
	var sy := 1 if y0 < b.y else -1
	var err := dx + dy
	while true:
		out.append(Vector2i(x0, y0))
		if x0 == b.x and y0 == b.y:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy
	return out

# ================================================================ mapa de exemplo (ILUSTRATIVO: posições e ids do Designer mandam)
var WORLD := Vector2i(1024, 704)
var NODES := {}   # id -> {pos, region, kind(s|b|l), tone, icon, links:[]}
var EDGES := []

func n(id: String, x: int, y: int, region: String, kind: String, icon: String, tone := "") -> void:
	NODES[id] = {"pos": Vector2i(x, y), "region": region, "kind": kind, "icon": icon,
		"tone": tone if tone != "" else TONE_BY.get(region, "chalk")}

func e(a: String, b: String) -> void:
	EDGES.append([a, b])

func build_example() -> void:
	n("body_jab", 464, 352, "center", "s", "skill_body_jab", "red")
	n("body_muscle_memory", 424, 314, "center", "s", "skill_body_muscle_memory", "red")
	n("body_heavy_hands", 384, 286, "center", "s", "skill_body_heavy_hands", "red")
	n("body_crew", 424, 390, "center", "s", "skill_body_crew", "red")
	n("body_crew_2", 384, 418, "center", "s", "skill_body_crew_2", "red")
	n("career_purse", 560, 352, "center", "s", "skill_career_purse", "gold")
	n("career_scouting", 600, 314, "center", "s", "skill_career_scouting", "gold")
	n("career_purse_2", 640, 286, "center", "s", "skill_career_purse_2", "gold")
	n("career_crowd", 600, 390, "center", "s", "skill_career_crowd", "gold")
	n("career_good_loser", 640, 418, "center", "s", "skill_career_good_loser", "gold")
	n("style_boxing", 548, 270, "center", "s", "skill_style_boxing", "purple")
	n("style_bjj", 476, 434, "center", "s", "skill_style_bjj", "purple")
	e("body_jab", "body_muscle_memory"); e("body_muscle_memory", "body_heavy_hands")
	e("body_jab", "body_crew"); e("body_crew", "body_crew_2")
	e("career_purse", "career_scouting"); e("career_scouting", "career_purse_2")
	e("career_purse", "career_crowd"); e("career_crowd", "career_good_loser")
	# Garagem (oeste)
	n("g1", 330, 352, "garage", "s", "icon_bag")
	n("g2", 290, 310, "garage", "s", "skill_body_jab")
	n("g3", 290, 396, "garage", "s", "skill_body_crew")
	n("g_rope", 236, 352, "garage", "b", "skill_rope_ready")
	n("g5", 190, 310, "garage", "s", "icon_treadmill")
	n("g6", 190, 396, "garage", "s", "skill_career_purse")
	e("body_heavy_hands", "g1"); e("body_crew_2", "g1"); e("g1", "g2"); e("g1", "g3")
	e("g2", "g_rope"); e("g3", "g_rope"); e("g_rope", "g5"); e("g_rope", "g6")
	# Academia (norte)
	n("a1", 430, 232, "gym", "s", "skill_body_crew")
	n("a2", 400, 186, "gym", "s", "skill_career_purse")
	n("a_big", 456, 150, "gym", "b", "icon_region_gym")
	n("a4", 400, 112, "gym", "s", "icon_speed_bag")
	n("a5", 510, 112, "gym", "s", "skill_career_crowd")
	e("body_heavy_hands", "a1"); e("a1", "a2"); e("a2", "a_big"); e("a_big", "a4"); e("a_big", "a5")
	# Boxe (nordeste)
	n("x1", 600, 226, "boxing", "s", "skill_body_jab")
	n("x2", 646, 190, "boxing", "s", "skill_body_heavy_hands")
	n("x_big", 704, 160, "boxing", "b", "icon_region_boxing")
	n("x4", 640, 140, "boxing", "s", "skill_career_crowd")
	e("style_boxing", "x1"); e("x1", "x2"); e("x2", "x_big"); e("x2", "x4")
	# Campanha (leste)
	n("c1", 700, 352, "campaign", "s", "icon_legacy_16")
	n("c2", 748, 308, "campaign", "s", "skill_career_scouting")
	n("c3", 748, 400, "campaign", "s", "skill_career_purse")
	n("c_day", 808, 352, "campaign", "b", "skill_prep_day")
	e("career_purse_2", "c1"); e("career_good_loser", "c1"); e("c1", "c2"); e("c1", "c3"); e("c2", "c_day"); e("c3", "c_day")
	# Jiu-jitsu (sul)
	n("j1", 460, 486, "bjj", "s", "skill_body_crew")
	n("j2", 414, 526, "bjj", "s", "skill_body_crew_2")
	n("j_big", 480, 574, "bjj", "b", "icon_region_bjj")
	n("j4", 534, 530, "bjj", "s", "skill_career_good_loser")
	e("style_bjj", "j1"); e("j1", "j2"); e("j1", "j4"); e("j2", "j_big"); e("j4", "j_big")
	# Ligações
	n("L_shout", 318, 470, "link", "l", "skill_shout_loud")
	NODES["L_shout"]["pair"] = ["garage", "bjj"]
	e("g3", "L_shout"); e("L_shout", "j2")
	n("L_click", 560, 150, "link", "l", "skill_body_jab")
	NODES["L_click"]["pair"] = ["gym", "boxing"]
	e("a_big", "L_click"); e("L_click", "x4")
	n("L_bc", 744, 238, "link", "l", "skill_career_crowd")
	NODES["L_bc"]["pair"] = ["boxing", "campaign"]
	e("x_big", "L_bc"); e("L_bc", "c2")
	n("L_cj", 640, 500, "link", "l", "skill_career_purse")
	NODES["L_cj"]["pair"] = ["bjj", "campaign"]
	e("c3", "L_cj"); e("L_cj", "j4")

## pinta o fundo: células de 8 px, região = nó mais perto até 44 px (ligação = xadrez das duas regiões)
const CELL := 8
const REG_R := 44.0

func region_grid(allowed: Dictionary) -> Array:
	var gw := WORLD.x / CELL
	var gh := WORLD.y / CELL
	var grid := []
	for cy in gh:
		var row := []
		for cx in gw:
			var c := Vector2((cx + 0.5) * CELL, (cy + 0.5) * CELL)
			var best := ""
			var bd := REG_R
			for id in NODES:
				var nd: Dictionary = NODES[id]
				var reg: String = nd.region
				if reg != "center" and reg != "link" and not allowed.get(reg, true):
					continue
				var d := c.distance_to(Vector2(nd.pos))
				if d < bd:
					bd = d
					best = id
			var key := "wall"
			if best != "":
				var nd2: Dictionary = NODES[best]
				if nd2.region == "link":
					var pr: Array = nd2.pair
					key = pr[(cx + cy) % 2]
					if not allowed.get(key, true):
						key = pr[(cx + cy + 1) % 2]
					if not allowed.get(key, true):
						key = "wall"
				else:
					key = nd2.region
			row.append(key)
		grid.append(row)
	return grid

func paint_regions(allowed: Dictionary) -> Image:
	var img: Image = L.blank(WORLD.x, WORLD.y)
	var grid := region_grid(allowed)
	var gh := grid.size()
	var gw: int = grid[0].size()
	for cy in gh:
		for cx in gw:
			var t: Image = frame_of(TILE_BY[grid[cy][cx]])
			img.blit_rect(t, Rect2i((cx * CELL) % 32, (cy * CELL) % 32, CELL, CELL), Vector2i(cx * CELL, cy * CELL))
	# costura: 1 px ink na borda entre materiais diferentes (do lado que não é parede), luz de 1 px no topo do recorte
	for cy in gh:
		for cx in gw:
			var k: String = grid[cy][cx]
			if k == "wall":
				continue
			var x0 := cx * CELL
			var y0 := cy * CELL
			if cx + 1 < gw and grid[cy][cx + 1] != k:
				L.R(img, x0 + CELL - 1, y0, 1, CELL, "ink")
			if cx > 0 and grid[cy][cx - 1] != k:
				L.R(img, x0, y0, 1, CELL, "ink")
			if cy + 1 < gh and grid[cy + 1][cx] != k:
				L.R(img, x0, y0 + CELL - 1, CELL, 1, "ink")
				if grid[cy + 1][cx] == "wall":
					L.R(img, x0 + 1, y0 + CELL, CELL, 1, "ink")   # sombra na parede
			if cy > 0 and grid[cy - 1][cx] != k:
				L.R(img, x0, y0, CELL, 1, "ink")
				var lit: Color = L.shade(img.get_pixel(x0 + 2, y0 + 2), 1)
				L.R(img, x0 + 1, y0 + 1, CELL - 2, 1, lit)
	return img

func fog_layer(img: Image, revealed: Array) -> void:
	var gw := WORLD.x / CELL
	var gh := WORLD.y / CELL
	for cy in gh:
		for cx in gw:
			var c := Vector2((cx + 0.5) * CELL, (cy + 0.5) * CELL)
			var bd := 9999.0
			for id in revealed:
				bd = minf(bd, c.distance_to(Vector2(NODES[id].pos)))
			var lv := fog_level(bd)
			if lv == 0:
				continue
			var t: Image = frame_of("map_fog_%d" % [0, 25, 50, 75, 100][lv])
			blend(img, t.get_region(Rect2i((cx * CELL) % 32, (cy * CELL) % 32, CELL, CELL)), cx * CELL, cy * CELL)

func fog_level(d: float) -> int:
	if d < 40.0:
		return 0
	if d < 48.0:
		return 1
	if d < 56.0:
		return 2
	if d < 64.0:
		return 3
	return 4

func node_sprite(id: String, state: String) -> String:
	var nd: Dictionary = NODES[id]
	var k: String = nd.kind
	if state == "owned":
		if k == "l":
			return "map_node_link_owned_%s_%s" % [nd.pair[0], nd.pair[1]]
		return "map_node_%s_owned_%s" % [k, nd.tone]
	return "map_node_%s_%s" % [k, state]

func draw_node(img: Image, id: String, state: String, cam: Vector2i, fr := 0) -> void:
	var nd: Dictionary = NODES[id]
	var p: Vector2i = nd.pos - cam
	var sid := node_sprite(id, state)
	putc(img, sid, fr if state == "buyable" else 0, p.x, p.y)
	if state == "hidden":
		return
	var ic: String = nd.icon
	blend(img, frame_of(ic), p.x - 8, p.y - 8)
	if state == "missing":
		putc(img, "map_node_veil", 0, p.x, p.y)

func price(img: Image, id: String, cost: int, ok: bool, cam: Vector2i) -> void:
	var nd: Dictionary = NODES[id]
	var p: Vector2i = nd.pos - cam
	var half := 12 if nd.kind != "b" else 19
	var s := str(cost)
	var w: int = 9 + 2 + L.text_w(s) + 5
	var x := p.x - w / 2
	var y := p.y + half + 1
	ns(img, "ui_map_price_ok" if ok else "ui_map_price_missing", x, y, w, 11)
	put(img, "icon_legacy", 0, x + 2, y + 1)
	L.text(img, s, x + 12, y + 2, "p2" if ok else "g2")

func region_tag(img: Image, r: String, name: String, at: Vector2i) -> void:
	var w: int = 5 + 9 + 3 + L.text_w(name) + 4
	ns(img, "ui_map_region_label_" + r, at.x - w / 2, at.y, w, 13)
	put(img, "icon_region_%s_9" % r, 0, at.x - w / 2 + 5, at.y + 2)
	L.text(img, name, at.x - w / 2 + 17, at.y + 3, "white")

# ================================================================ mockup
const VP := Rect2i(5, 26, 630, 329)

func screen_map(state: Dictionary, legacy: String, cam_center: Vector2i, allowed: Dictionary, extras: Callable) -> Image:
	var scr: Image = L.blank(640, 360)
	L.R(scr, 0, 0, 640, 360, "ink")
	var world := paint_regions(allowed)
	var cam := cam_center - Vector2i(VP.size.x / 2, VP.size.y / 2)
	# linhas
	for ed in EDGES:
		var sa: String = state.get(ed[0], "hidden")
		var sb: String = state.get(ed[1], "hidden")
		if sa == "hidden" and sb == "hidden":
			continue
		var st := "dim"
		if sa == "owned" and sb == "owned":
			st = "lit"
		elif sa != "hidden" and sb != "hidden":
			st = "open"
		draw_link(world, NODES[ed[0]].pos, NODES[ed[1]].pos, st, 3)
	var revealed := []
	for id in state:
		if state[id] != "hidden":
			revealed.append(id)
	fog_layer(world, revealed)
	var view: Image = world.get_region(Rect2i(cam, VP.size))
	scr.blit_rect(view, Rect2i(Vector2i.ZERO, VP.size), VP.position)
	var vcam := cam - VP.position
	for id in state:
		if state[id] != "hidden":
			draw_node(scr, id, state[id], vcam)
	extras.call(scr, vcam)
	# moldura e barra
	ns(scr, "ui_map_viewport_edge", VP.position.x - 1, VP.position.y - 1, VP.size.x + 2, VP.size.y + 2)
	ns(scr, "ui_map_frame", 0, 0, 640, 360)
	ns(scr, "ui_map_topbar", 5, 5, 630, 20)
	put(scr, "icon_skill_map", 0, 9, 7)
	L.text(scr, "ÁRVORE DA ESCOLA", 29, 11, "white", 1, "ink")
	L.text(scr, "ARRASTE OU USE A RODA", 29 + L.text_w("ÁRVORE DA ESCOLA") + 12, 11, "g2")
	var lw: int = L.text_w(legacy, 2)
	L.text(scr, legacy, 610 - lw, 8, "p2", 2, "ink")
	put(scr, "icon_legacy_16", 0, 610 - lw - 20, 7)
	put(scr, "ui_map_close_normal", 0, 616, 7)
	return scr

func start_state() -> Dictionary:
	return {"body_jab": "owned", "body_muscle_memory": "missing", "body_crew": "missing", "career_purse": "buyable"}

func mid_state() -> Dictionary:
	var s := {}
	for id in ["body_jab", "body_muscle_memory", "body_heavy_hands", "body_crew", "body_crew_2", "career_purse", "career_scouting",
			"career_purse_2", "career_crowd", "style_boxing", "g1", "g2", "g_rope", "x1", "c1"]:
		s[id] = "owned"
	for id in ["g3", "x2"]:
		s[id] = "buyable"
	for id in ["career_good_loser", "g5", "g6", "a1", "c2", "c3"]:
		s[id] = "missing"
	return s

func make_mockup() -> void:
	build_example()
	var H := 18
	var cap: Image = load_abs(CAPS + "f53_hud_12_dias.png")
	cap.resize(640, 360, Image.INTERPOLATE_NEAREST)
	var total_h := (H + 360) * 3 + H + 330
	var img: Image = L.blank(640, total_h)
	L.R(img, 0, 0, 640, total_h, "ink")
	var y := 0
	# A: começo
	header(img, y, "A. COMEÇO: 1 NÓ COMPRADO, 3 À VISTA, O RESTO NA NEBLINA (NOMES DE REGIÃO AINDA NÃO APARECEM)")
	y += H
	var allowed_start := {"gym": false, "boxing": false, "bjj": false}
	var a := screen_map(start_state(), "14", Vector2i(512, 352), allowed_start, func(scr: Image, cam: Vector2i) -> void:
		price(scr, "career_purse", 10, true, cam)
		price(scr, "body_muscle_memory", 30, false, cam)
		price(scr, "body_crew", 150, false, cam)
		putc(scr, "map_node_s_hover", 0, NODES["career_purse"].pos.x - cam.x, NODES["career_purse"].pos.y - cam.y)
		putc(scr, "fx_map_reveal", 2, NODES["body_crew"].pos.x - cam.x, NODES["body_crew"].pos.y - cam.y)
		)
	img.blit_rect(a, Rect2i(0, 0, 640, 360), Vector2i(0, y))
	y += 360
	# B: meio
	header(img, y, "B. MEIO: GARAGEM, BOXE E CAMPANHA ABERTAS; ACADEMIA ACABOU DE APARECER; JIU-JITSU TRANCADO (FICA NA NEBLINA)")
	y += H
	var allowed_mid := {"bjj": false}
	var ms := mid_state()
	var b := screen_map(ms, "1.240", Vector2i(500, 330), allowed_mid, func(scr: Image, cam: Vector2i) -> void:
		price(scr, "g3", 300, true, cam)
		price(scr, "x2", 450, true, cam)
		for pid in [["g5", 2400], ["g6", 1800], ["a1", 2000], ["c2", 2600], ["c3", 1500], ["career_good_loser", 800]]:
			price(scr, pid[0], pid[1], false, cam)
		region_tag(scr, "garage", "GARAGEM", NODES["g2"].pos - cam + Vector2i(-10, -40))
		region_tag(scr, "gym", "ACADEMIA", NODES["a1"].pos - cam + Vector2i(-40, -30))
		region_tag(scr, "boxing", "BOXE", NODES["x1"].pos - cam + Vector2i(-40, -30))
		region_tag(scr, "campaign", "CAMPANHA", NODES["c2"].pos - cam + Vector2i(0, -40))
		putc(scr, "fx_map_reveal", 3, NODES["a1"].pos.x - cam.x, NODES["a1"].pos.y - cam.y)
		putc(scr, "fx_map_buy", 1, NODES["c1"].pos.x - cam.x, NODES["c1"].pos.y - cam.y)
		# cartão no g3
		var gp: Vector2i = NODES["g3"].pos - cam
		putc(scr, "map_node_s_hover", 0, gp.x, gp.y)
		var cx := gp.x + 16
		var cyy := gp.y - 2
		ns(scr, "ui_map_card", cx, cyy, 150, 52)
		L.text(scr, "VIZINHANÇA FIEL", cx + 6, cyy + 5, "white")
		L.text(scr, "+10% TREINO/S DA EQUIPE", cx + 6, cyy + 15, "gr3")
		put(scr, "icon_legacy", 0, cx + 6, cyy + 24)
		L.text(scr, "300", cx + 18, cyy + 25, "p2")
		ns(scr, "ui_map_card_next", cx + 1, cyy + 37, 148, 13)
		put(scr, "icon_calendar", 0, cx + 4, cyy + 38)
		L.text(scr, "VALE NA PRÓXIMA CAMPANHA", cx + 18, cyy + 40, "white")
		)
	img.blit_rect(b, Rect2i(0, 0, 640, 360), Vector2i(0, y))
	y += 360
	# C: sala com o botão brilhando
	header(img, y, "C. SALA: BOTÃO DA ÁRVORE NO CANTO DE CIMA À ESQUERDA DA SALA (132,22), BRILHANDO PORQUE HÁ NÓ QUE O LEGADO PAGA")
	y += H
	var room: Image = cap.duplicate()
	put(room, "ui_map_button_glow", 0, 132, 22)
	# lupa 3x do botão nos estados
	var zx := 150
	var zy := 60
	L.R(room, zx - 3, zy - 3, 5 * 26 * 2 + 6 + 30, 2 * 22 + 22, "ink")
	var k := 0
	for sid in [["ui_map_button_normal", 0, "QUIETO"], ["ui_map_button_hover", 0, "MOUSE"], ["ui_map_button_pressed", 0, "CLIQUE"],
			["ui_map_button_glow", 0, "BRILHO 0"], ["ui_map_button_glow", 1, "BRILHO 1"]]:
		put_k(room, frame_of(sid[0], sid[1]), zx + k * 58, zy, 2)
		L.text(room, sid[2], zx + k * 58, zy + 48, "g3")
		k += 1
	L.line(room, 143, 34, zx - 3, zy + 10, "y2")
	img.blit_rect(room, Rect2i(0, 0, 640, 360), Vector2i(0, y))
	y += 360
	# D: peças
	header(img, y, "D. PEÇAS (2X): ESTADOS DO NÓ, LINHAS, REVELAÇÃO, REGIÕES E ÍCONES NOVOS")
	y += H
	pieces(img, y)
	MOCK_IMG = img

var MOCK_IMG: Image

func header(img: Image, y: int, s: String) -> void:
	L.R(img, 0, y, 640, 18, "d1")
	L.R(img, 0, y + 17, 640, 1, "g0")
	L.text(img, s, 6, y + 6, "y1")

func pieces(img: Image, y0: int) -> void:
	var x := 8
	var y := y0 + 6
	L.text(img, "NÓ PEQUENO", x, y, "g3")
	L.text(img, "MARCO", x + 300, y, "g3")
	y += 10
	var sm := [["map_node_s_owned_red", "skill_body_jab", "COMPRADO"], ["map_node_s_buyable", "skill_body_jab", "PAGA"],
		["map_node_s_missing", "skill_body_jab", "SEM LEGADO"], ["map_node_s_hidden", "", "ESCONDIDO"]]
	for i in sm.size():
		var t: Image = L.blank(24, 24)
		blend(t, frame_of(sm[i][0]), 0, 0)
		if sm[i][1] != "":
			blend(t, frame_of(sm[i][1]), 4, 4)
		if sm[i][0] == "map_node_s_missing":
			blend(t, frame_of("map_node_veil"), 4, 4)
		put_k(img, t, x + i * 70, y, 2)
		L.text(img, sm[i][2], x + i * 70, y + 52, "g2")
	var bg := [["map_node_b_owned_chalk", "skill_rope_ready"], ["map_node_b_buyable", "skill_prep_day"], ["map_node_b_missing", "icon_region_boxing"], ["map_node_b_hidden", ""]]
	for i in bg.size():
		var t2: Image = L.blank(38, 38)
		blend(t2, frame_of(bg[i][0]), 0, 0)
		if bg[i][1] != "":
			blend(t2, frame_of(bg[i][1]), 11, 11)
		if bg[i][0] == "map_node_b_missing":
			blend(t2, frame_of("map_node_veil"), 11, 11)
		put_k(img, t2, x + 300 + i * 82, y - 6, 2)
	y += 66
	# tons
	L.text(img, "ANEL DO COMPRADO:", x, y, "g3")
	var tx := x + 100
	for tn in ["red", "gold", "purple", "chalk", "green", "blue"]:
		put_k(img, frame_of("map_node_s_owned_" + tn), tx, y - 6, 1)
		tx += 30
	L.text(img, "LIGAÇÃO:", tx + 6, y, "g3")
	put_k(img, frame_of("map_node_link_owned_garage_bjj"), tx + 50, y - 10, 2)
	var lk: Image = L.blank(28, 24)
	blend(lk, frame_of("map_node_link_owned_garage_bjj"), 0, 0)
	blend(lk, frame_of("skill_shout_loud"), 6, 4)
	put_k(img, lk, tx + 50, y - 10, 2)
	var lk2: Image = L.blank(28, 24)
	blend(lk2, frame_of("map_node_l_buyable"), 0, 0)
	blend(lk2, frame_of("skill_body_jab"), 6, 4)
	put_k(img, lk2, tx + 112, y - 10, 2)
	y += 46
	# linhas
	L.text(img, "LINHAS:", x, y, "g3")
	var ln: Image = L.blank(240, 14)
	L.R(ln, 0, 0, 240, 14, "br1")
	draw_link(ln, Vector2i(4, 4), Vector2i(70, 9), "lit", 0)
	draw_link(ln, Vector2i(84, 4), Vector2i(150, 9), "open", 0)
	draw_link(ln, Vector2i(164, 4), Vector2i(234, 9), "dim", 0)
	put_k(img, ln, x + 50, y - 6, 2)
	L.text(img, "ACESA", x + 60, y + 22, "g2")
	L.text(img, "À VISTA", x + 220, y + 22, "g2")
	L.text(img, "APAGADA", x + 380, y + 22, "g2")
	y += 36
	# revelação
	L.text(img, "REVELAÇÃO 12 FPS (0,5 S):", x, y, "g3")
	for i in 6:
		var fbg: Image = L.blank(40, 40)
		L.R(fbg, 0, 0, 40, 40, "br1")
		blend(fbg, frame_of("fx_map_reveal", i), 0, 0)
		blend(img, fbg, x + 140 + i * 44, y - 4)
	y += 44
	L.text(img, "COMPRA 12 FPS:", x, y, "g3")
	for i in 5:
		var fbg2: Image = L.blank(40, 40)
		L.R(fbg2, 0, 0, 40, 40, "br1")
		blend(fbg2, frame_of("map_node_s_owned_gold"), 8, 8)
		blend(fbg2, frame_of("skill_career_purse"), 12, 12)
		blend(fbg2, frame_of("fx_map_buy", i), 0, 0)
		blend(img, fbg2, x + 140 + i * 44, y - 4)
	L.text(img, "NEBLINA 100/75/50/25:", x + 380, y, "g3")
	for i in 4:
		var fz: Image = L.blank(24, 24)
		blend(fz, frame_of("map_tile_center").get_region(Rect2i(0, 0, 24, 24)), 0, 0)
		blend(fz, frame_of("map_fog_%d" % [100, 75, 50, 25][i]).get_region(Rect2i(0, 0, 24, 24)), 0, 0)
		blend(img, fz, x + 380 + i * 28, y + 10)
	y += 50
	L.text(img, "MATERIAIS:", x, y, "g3")
	var mx := x + 60
	for tid in ["map_tile_wall", "map_tile_center", "map_tile_garage", "map_tile_gym", "map_tile_boxing", "map_tile_bjj", "map_tile_campaign"]:
		blend(img, frame_of(tid), mx, y - 4)
		mx += 36
	mx += 6
	for r in REGIONS:
		blend(img, frame_of("icon_region_" + r), mx, y - 4)
		blend(img, frame_of("icon_region_%s_9" % r), mx + 4, y + 16)
		mx += 20
	y += 40
	L.text(img, "ÍCONES NOVOS:", x, y, "g3")
	var ix := x + 80
	for iid in ["skill_rope_ready", "skill_prep_day", "skill_shout_loud", "icon_skill_map", "icon_skill_map_9"] + MILESTONE_ICONS.values():
		put_k(img, frame_of(iid), ix, y - 8, 2)
		ix += 40

# ================================================================ mapa REAL (data/skill_tree.json v2)
const REAL_MARGIN := 64
const CENTER_REGIONS := ["body", "career", "style"]
const KIND_BY := {"small": "s", "milestone": "b", "link": "l"}
const RADIUS_BY := {"s": 12, "b": 19, "l": 14}
const PROPOSAL := {"link_mat": [-6, 4], "link_shout": [-6, -4]}
var TREE := {}
var TN := {}              # id -> nó do JSON
var ICON_BY_NODE := {}
var REAL_ORIGIN := Vector2i.ZERO
var MAP_CHECK := {}

func load_tree() -> bool:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "data/skill_tree.json")) != OK:
		push_error("data/skill_tree.json ilegível")
		return false
	TREE = j.data
	TN = {}
	ICON_BY_NODE = {}
	for nd in TREE.nodes:
		TN[nd.id] = nd
		ICON_BY_NODE[nd.id] = MILESTONE_ICONS.get(nd.id, str(nd.get("icon", "")))
	return true

func gpos(id: String, over: Dictionary) -> Vector2i:
	var p: Array = over.get(id, TN[id].pos)
	return Vector2i(int(p[0]), int(p[1]))

func build_real(over := {}) -> void:
	NODES = {}
	EDGES = []
	var u: int = int(TREE.map.unit_px)
	var mn := Vector2i(999, 999)
	var mx := Vector2i(-999, -999)
	for id in TN:
		var g := gpos(id, over)
		mn = Vector2i(mini(mn.x, g.x), mini(mn.y, g.y))
		mx = Vector2i(maxi(mx.x, g.x), maxi(mx.y, g.y))
	REAL_ORIGIN = Vector2i(-mn.x * u + REAL_MARGIN, -mn.y * u + REAL_MARGIN)
	var w := (mx.x - mn.x) * u + 2 * REAL_MARGIN
	var h := (mx.y - mn.y) * u + 2 * REAL_MARGIN
	WORLD = Vector2i(int(ceil(w / 32.0)) * 32, int(ceil(h / 32.0)) * 32)
	for id in TN:
		var nd: Dictionary = TN[id]
		var reg: String = nd.region
		var paint: String = "center" if reg in CENTER_REGIONS else reg
		var p: Vector2i = REAL_ORIGIN + gpos(id, over) * u
		n(id, p.x, p.y, paint, KIND_BY[nd.kind], ICON_BY_NODE[id], TONE_BY.get(reg, "chalk"))
		NODES[id]["data_region"] = reg
		if reg == "link":
			var pr := []
			for v in nd.neighbors:
				pr.append(TN[v].region)
			pr.sort_custom(func(a, b): return REGIONS.find(a) < REGIONS.find(b))
			NODES[id]["pair"] = pr
	var seen := {}
	for id in TN:
		for v in TN[id].neighbors:
			var key: String = (id + "|" + v) if id < v else (v + "|" + id)
			if not seen.has(key):
				seen[key] = true
				e(id, v)

func lock_open(nd: Dictionary, locks: Dictionary) -> bool:
	var lk: String = str(nd.get("lock", ""))
	return lk == "" or locks.get(lk, false)

## estados pela regra do design §1.1 (comprado / à vista / escondido)
func real_state(owned: Array, legacy: int, locks: Dictionary) -> Dictionary:
	var s := {}
	for id in TN:
		var nd: Dictionary = TN[id]
		if id in owned:
			s[id] = "owned"
			continue
		if not lock_open(nd, locks):
			continue
		var vis: bool = bool(nd.get("root", false))
		for v in nd.neighbors:
			if v in owned:
				vis = true
		if vis:
			s[id] = "buyable" if legacy >= int(nd.cost) else "missing"
	return s

func region_first_nodes() -> Dictionary:   # região -> nó mais perto das raízes (BFS), onde a plaquinha aparece primeiro
	var depth := {}
	var q := []
	for id in TN:
		if TN[id].get("root", false) and TN[id].region in CENTER_REGIONS:
			depth[id] = 0
			q.append(id)
	while q.size() > 0:
		var c: String = q.pop_front()
		for v in TN[c].neighbors:
			if not depth.has(v):
				depth[v] = depth[c] + 1
				q.append(v)
	var best := {}
	for id in TN:
		var reg: String = TN[id].region
		if reg in CENTER_REGIONS or reg == "link":
			continue
		if not best.has(reg) or depth[id] < depth[best[reg]] or (depth[id] == depth[best[reg]] and NODES[id].pos.y < NODES[best[reg]].pos.y):
			best[reg] = id
	return best

func region_name(r: String) -> String:
	for rg in TREE.regions:
		if rg.id == r:
			return str(rg.name)
	return r.to_upper()

func label_rect(r: String, at: Vector2i) -> Rect2i:
	var w: int = 5 + 9 + 3 + L.text_w(region_name(r)) + 4
	return Rect2i(at.x - w / 2, at.y, w, 13)

func label_at(id: String) -> Vector2i:   # topo da plaquinha 36 px acima do centro do nó
	return NODES[id].pos + Vector2i(0, -36 - (7 if NODES[id].kind == "b" else 0))

func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

## confere §21: distância mínima, linha passando por baixo de nó, plaquinha em cima de nó
func check_map() -> Dictionary:
	var ids: Array = NODES.keys()
	var worst := 9999.0
	var worst_pair := []
	var fails := []
	for i in ids.size():
		for k in range(i + 1, ids.size()):
			var a: Dictionary = NODES[ids[i]]
			var b: Dictionary = NODES[ids[k]]
			var d := Vector2(a.pos).distance_to(Vector2(b.pos))
			var need := 52.0 if (a.kind == "b" or b.kind == "b") else 40.0
			if d < worst:
				worst = d
				worst_pair = [ids[i], ids[k]]
			if d < need:
				fails.append("%s-%s %.0f px (mín. %d)" % [ids[i], ids[k], d, need])
	var near := []
	var near_ids := []
	for ed in EDGES:
		for c in ids:
			if c == ed[0] or c == ed[1]:
				continue
			var d2 := seg_dist(Vector2(NODES[c].pos), Vector2(NODES[ed[0]].pos), Vector2(NODES[ed[1]].pos))
			if d2 < RADIUS_BY[NODES[c].kind] + 8:
				near.append("linha %s-%s passa a %.0f px do centro de %s" % [ed[0], ed[1], d2, c])
				near_ids.append(c)
	var lab := []
	var firsts := region_first_nodes()
	for r in firsts:
		var lr := label_rect(r, label_at(firsts[r]))
		for c in ids:
			var rad: int = RADIUS_BY[NODES[c].kind]
			var nr := Rect2i(NODES[c].pos - Vector2i(rad, rad), Vector2i(rad * 2, rad * 2 + 12))   # nó + etiqueta de preço
			if lr.intersects(nr):
				lab.append("plaquinha %s cobre %s" % [r, c])
	return {"pairs": ids.size() * (ids.size() - 1) / 2, "min_px": snappedf(worst, 0.1), "min_pair": worst_pair,
		"spacing_fails": fails, "line_under_node": near, "line_under_ids": near_ids, "label_overlaps": lab,
		"world_px": [WORLD.x, WORLD.y]}

func world_full(state: Dictionary, allowed: Dictionary, labels: bool, phase := 3) -> Image:
	var world := paint_regions(allowed)
	for ed in EDGES:
		var sa: String = state.get(ed[0], "hidden")
		var sb: String = state.get(ed[1], "hidden")
		var st := "dim"
		if sa == "owned" and sb == "owned":
			st = "lit"
		elif sa != "hidden" and sb != "hidden":
			st = "open"
		draw_link(world, NODES[ed[0]].pos, NODES[ed[1]].pos, st, phase)
	for id in state:
		draw_node(world, id, state[id], Vector2i.ZERO)
	if labels:
		var firsts := region_first_nodes()
		for r in firsts:
			region_tag(world, r, region_name(r), label_at(firsts[r]))
	return world

func mark(img: Image, c: Vector2i, r: int) -> void:   # anel tracejado y1 = "olhar aqui"
	for a in 48:
		if a % 2 == 0:
			var t := a * TAU / 48.0
			L.R(img, c.x + int(round(cos(t) * r)), c.y + int(round(sin(t) * r)), 2, 2, "y1")

func all_owned() -> Dictionary:
	var s := {}
	for id in TN:
		s[id] = "owned"
	return s

func unit_px(g: Vector2i) -> Vector2i:
	return REAL_ORIGIN + g * int(TREE.map.unit_px)

func make_mockup_real() -> Image:
	var H := 18
	var parts := []   # [título, imagem]
	# A: mapa inteiro, tudo comprado
	build_real()
	MAP_CHECK = check_map()
	var a := world_full(all_owned(), {}, true)
	var a_mark: Image = a.duplicate()
	for c in MAP_CHECK.line_under_ids:
		mark(a_mark, NODES[c].pos, 20)
	# eixo: cruz no (0,0)
	L.R(a_mark, REAL_ORIGIN.x - 3, REAL_ORIGIN.y, 7, 1, "y2")
	L.R(a_mark, REAL_ORIGIN.x, REAL_ORIGIN.y - 3, 1, 7, "y2")
	parts.append(["A. MAPA REAL (skill_tree.json, 1 UNIDADE = 40 PX), TUDO COMPRADO. %d NÓS, MENOR DISTÂNCIA %.0f PX. AMARELO = LINHA PASSANDO POR BAIXO DE NÓ" % [TN.size(), MAP_CHECK.min_px], a_mark])
	# B: atual x proposta na Garagem (recorte)
	var crop := Rect2i(unit_px(Vector2i(-10, -5)), Vector2i(6 * 40 + 40, 10 * 40))
	var b: Image = L.blank(WORLD.x, crop.size.y + 14)
	L.R(b, 0, 0, b.get_width(), b.get_height(), "ink")
	var cur: Image = a_mark.get_region(crop)
	build_real(PROPOSAL)
	var prop := world_full(all_owned(), {}, false)
	var crop2 := Rect2i(unit_px(Vector2i(-10, -5)), crop.size)
	var pv: Image = prop.get_region(crop2)
	b.blit_rect(cur, Rect2i(Vector2i.ZERO, crop.size), Vector2i(8, 14))
	b.blit_rect(pv, Rect2i(Vector2i.ZERO, crop.size), Vector2i(8 + crop.size.x + 24, 14))
	L.text(b, "ATUAL: link_mat (-4,4) / link_shout (-4,-4)", 8, 3, "g3")
	L.text(b, "PROPOSTA: link_mat (-6,4) / link_shout (-6,-4)", 8 + crop.size.x + 24, 3, "gr3")
	parts.append(["B. GARAGEM: A LINHA RÁDIO-COLCHÃO E A CORDA-GRITO PASSAM POR BAIXO DE GARAGEM LOTADA E MÃO PESADA (11 PX DO CENTRO)", b])
	build_real()
	# C: começo da 2ª campanha (2 raízes compradas, artes e academia trancadas)
	var locks0 := {}
	var st0 := real_state(["body_jab", "career_purse"], 30, locks0)
	var c := screen_map(st0, "30", unit_px(Vector2i(0, 0)), {"gym": false, "boxing": false, "bjj": false}, func(scr: Image, cam: Vector2i) -> void:
		for id in st0:
			if st0[id] != "owned":
				price(scr, id, int(TN[id].cost), st0[id] == "buyable", cam)
		)
	parts.append(["C. TELA REAL, COMEÇO: 2 RAÍZES COMPRADAS, LEGADO 30. A JANELA 630X329 MOSTRA O CENTRO INTEIRO E A BEIRA DA GARAGEM", c])
	# D: meio do jogo, câmera na Academia/Boxe
	var locks1 := {"gym": true, "art:boxing": true, "art:bjj": true}
	var own1 := ["body_jab", "body_muscle_memory", "career_purse", "career_scouting", "career_purse_2", "career_crowd", "gar_tape",
		"gar_rope", "camp_poster", "gym_membership", "gym_mirror", "style_boxing", "box_counter"]
	var st1 := real_state(own1, 400, locks1)
	var d := screen_map(st1, "400", unit_px(Vector2i(4, -4)), {}, func(scr: Image, cam: Vector2i) -> void:
		for id in st1:
			if st1[id] != "owned":
				price(scr, id, int(TN[id].cost), st1[id] == "buyable", cam)
		var firsts := region_first_nodes()
		for r in firsts:
			var fid: String = firsts[r]
			if st1.has(fid):
				region_tag(scr, r, region_name(r), label_at(fid) - cam)
		)
	parts.append(["D. TELA REAL, MEIO: ACADEMIA E ARTES ABERTAS, LEGADO 400, CÂMERA EM (4,-4). PLAQUINHAS 36 PX ACIMA DO 1º NÓ DA REGIÃO", d])
	# E: os 6 ícones dos marcos
	var ei: Image = L.blank(WORLD.x, 150)
	L.R(ei, 0, 0, ei.get_width(), ei.get_height(), "ink")
	var x := 10
	for nid in MILESTONE_ICONS:
		var iid: String = MILESTONE_ICONS[nid]
		var tone: String = TONE_BY.get(TN[nid].region, "chalk")
		var t: Image = L.blank(38, 38)
		blend(t, frame_of("map_node_b_owned_" + tone), 0, 0)
		blend(t, frame_of(iid), 11, 11)
		put_k(ei, t, x, 6, 3)
		put_k(ei, frame_of(iid), x + 118, 6, 2)
		blend(ei, frame_of(iid), x + 124, 44)
		L.text(ei, str(TN[nid].name).to_upper(), x, 122, "white")
		L.text(ei, iid, x, 134, "g2")
		x += 152
	parts.append(["E. 2ª PASSADA: OS 6 ÍCONES DOS MARCOS (3X NA PEÇA COMPRADA, 2X E 1X)", ei])
	var total := 0
	for p in parts:
		total += H + p[1].get_height()
	var img: Image = L.blank(WORLD.x, total)
	L.R(img, 0, 0, WORLD.x, total, "ink")
	var y := 0
	for p in parts:
		L.R(img, 0, y, WORLD.x, 18, "d1")
		L.R(img, 0, y + 17, WORLD.x, 1, "g0")
		L.text(img, p[0], 6, y + 6, "y1")
		y += H
		img.blit_rect(p[1], Rect2i(Vector2i.ZERO, p[1].get_size()), Vector2i(0, y))
		y += p[1].get_height()
	return img

# ================================================================ manifest
func write_manifest() -> void:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível na hora de gravar; nada foi escrito")
		return
	var doc: Dictionary = intify(j.data)
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 5.4") < 0:
		doc["_sobre"] = sobre + " Fase 5.4 (Diretor de Arte): mapa da árvore grande (materiais por região, neblina, nós pequeno/marco/ligação por estado, linhas, botão da sala, revelação) — direcao-visual.md §21."
	var sp: Dictionary = doc.get("sprites", {})
	for id in M:
		sp[id] = intify(M[id])
	doc["sprites"] = sp
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["skill_map"] = intify(skill_map_info())
	bd["_nota_fase54_arte"] = "Fase 5.4 (Diretor de Arte): skill_map (mapa da árvore grande). direcao-visual.md §21."
	doc["by_data_id"] = bd
	var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()

func skill_map_info() -> Dictionary:
	var owned_small := {}
	var owned_big := {}
	for t in TONES:
		owned_small[t] = "map_node_s_owned_" + t
		owned_big[t] = "map_node_b_owned_" + t
	return {
		"screen": {"frame": "ui_map_frame", "frame_rect": [0, 0, 640, 360], "topbar": "ui_map_topbar", "topbar_rect": [5, 5, 630, 20],
			"viewport_rect": [VP.position.x, VP.position.y, VP.size.x, VP.size.y], "viewport_edge": "ui_map_viewport_edge",
			"viewport_edge_rect": [VP.position.x - 1, VP.position.y - 1, VP.size.x + 2, VP.size.y + 2],
			"title_icon": "icon_skill_map", "title_icon_pos": [9, 7], "title_text_pos": [29, 11], "title_color": "col_text_1",
			"hint_text_pos": "título + 12 px (y 11)", "hint_color": "col_text_2",
			"legacy_icon": "icon_legacy_16", "legacy_text_right": 610, "legacy_text_y": 8, "legacy_size": "txt_hero", "legacy_color": "col_legacy",
			"close": {"normal": "ui_map_close_normal", "hover": "ui_map_close_hover", "pressed": "ui_map_close_pressed", "pos": [616, 7]},
			"note": "Tela cheia por cima da sala (base 640x360). Moldura de madeira 9-slice, barra do topo com título, dica de navegação, Legado em txt_hero (o número herói desta tela) e o X. O mapa fica recortado em viewport_rect; a viewport_edge (9-slice de miolo vazio) vai por cima dele. Arrastar e roda do mouse movem a câmera em pixel inteiro; sem zoom. Esc e o X fecham."},
		"world": {"cell": CELL, "region_radius": REG_R, "tiles": TILE_BY, "tile_size": 32,
			"rule": "Fundo pintado UMA vez ao abrir (Image do tamanho do mundo): para cada célula de 8x8, procurar o nó mais perto até region_radius px. Nó de região -> ladrilho dela; nó de ligação -> xadrez das duas regiões do par (célula (cx+cy)%2); nó do centro -> map_tile_center; nada perto -> map_tile_wall. Copiar do ladrilho a área (x%32, y%32, 8, 8) para ele emendar. Região trancada (Academia antes de algum discípulo chegar lá; arte não liberada) conta como parede. Costura: 1 px ink na borda entre células de materiais diferentes (do lado que não é parede), 1 px de luz (rampa +1) logo abaixo da costura de cima e 1 px de sombra ink na parede embaixo do recorte. Referência em tools/art/make_sprites_fase54.gd: region_grid() e paint_regions().",
			"spacing": "Distância mínima entre centros: 40 px (nó pequeno), 52 px (marco). Assim a etiqueta de preço e o anel não se tocam.",
			"note": "Os materiais dizem a região sem texto: cortiça = centro (os 12 de sempre), concreto = Garagem, azulejo verde = Academia, lona vermelha = Boxe, tatame azul = Jiu-jitsu, feltro roxo = Campanha. A parede escura é o que sobra."},
		"fog": {"tiles": {"25": "map_fog_25", "50": "map_fog_50", "75": "map_fog_75", "100": "map_fog_100"},
			"levels_by_distance": [[40, 0], [48, 25], [56, 50], [64, 75], [9999, 100]],
			"rule": "Camada por cima do fundo e das linhas, por baixo dos nós. Para cada célula de 8x8: distância até o nó revelado (comprado ou à vista) mais perto -> nível pela tabela (menor que 40 px = sem neblina). Desenhar a área (x%32, y%32, 8, 8) do ladrilho do nível. Nó escondido não é desenhado: a neblina e a linha apagada que entra nela já dizem 'tem mais coisa ali'.",
			"reveal_anim": "Quando um nó fica à vista: as células em volta descem um nível a cada 0,1 s (100 -> 75 -> 50 -> 25 -> 0 = 0,4 s), sem alpha. Junto, fx_map_reveal toca uma vez no centro do nó (6 quadros a 12 fps = 0,5 s) e o nó aparece no quadro 2 do fx, já no estado certo.",
			"note": "Neblina = ink com nuvens d1/d2, em dither Bayer (nada de transparência parcial)."},
		"node": {
			"small": {"size": [24, 24], "pivot": [12, 12], "icon_offset": [-8, -8], "owned_by_tone": owned_small, "buyable": "map_node_s_buyable",
				"missing": "map_node_s_missing", "hidden": "map_node_s_hidden", "hover": "map_node_s_hover"},
			"big": {"size": [38, 38], "pivot": [19, 19], "icon_offset": [-8, -8], "owned_by_tone": owned_big, "buyable": "map_node_b_buyable",
				"missing": "map_node_b_missing", "hidden": "map_node_b_hidden", "hover": "map_node_b_hover"},
			"link": {"size": [28, 24], "pivot": [14, 12], "icon_offset": [-8, -8], "owned_by_pair": "map_node_link_owned_<a>_<b> (a e b na ordem de region_order)",
				"buyable": "map_node_l_buyable", "missing": "map_node_l_missing", "hidden": "map_node_l_hidden", "hover": "map_node_l_hover"},
			"region_order": REGIONS,
			"tone_by_branch_or_region": TONE_BY,
			"veil": "map_node_veil", "veil_offset": [-8, -8],
			"buyable_fps": 2.0,
			"rule": "Ordem: frame do estado -> ícone 16x16 no centro (pivô + icon_offset) -> se 'missing', map_node_veil por cima do ícone -> hover por cima de tudo. Comprado = anel na cor do ramo/região + tachinha dourada no canto (pregado no quadro). À vista e o Legado paga = anel ouro claro piscando 2 quadros a 2 fps (col_buyable). À vista sem Legado = anel escuro, ícone com véu pontilhado; o preço fica em col_text_2. Escondido = não desenhar (o 'hidden' com '?' é só o quadro 0 da revelação e a opção de 'espiar' se o Designer quiser).",
			"price_tag": {"ok": "ui_map_price_ok", "missing": "ui_map_price_missing", "height": 11, "gap_below_node": 1, "icon": "icon_legacy", "icon_offset": [2, 1], "text_offset": [12, 2],
				"text_color_ok": "col_legacy", "text_color_missing": "col_text_2",
				"note": "Etiqueta 9-slice centrada embaixo de cada nó À VISTA (não nos comprados). Largura = 12 + texto + 5."}},
		"lines": {
			"lit": {"when": "os dois nós comprados", "core": ["p2", "p1"], "shadow": "ink", "spark": "white", "spark_every": 8, "spark_fps": 8.0},
			"open": {"when": "os dois à vista ou comprados (pelo menos um ainda não comprado)", "core": ["g2"], "shadow": "ink"},
			"dim": {"when": "um lado escondido", "core": ["g0"], "dash": [2, 2], "under_fog": true},
			"rule": "Linha reta de centro a centro, em pixels de Bresenham (draw_rect 1x1 por ponto; nada de Line2D com antialias nem textura girada). Se |dx| >= |dy| a 2ª camada vai 1 px para baixo, senão 1 px para a direita. Acesa: p2 na linha, p1 na 2ª camada, ink na 3ª, um pixel branco a cada 8 que anda 1 px por quadro a 8 fps (o 'Legado correndo'). À vista: g2 + sombra ink. Apagada: g0 tracejada 2/2, sem sombra, desenhada ANTES da neblina (some aos poucos dentro dela). Desenhar as linhas antes dos nós.",
			"reference": "tools/art/make_sprites_fase54.gd: draw_link()"},
		"region_label": {"sprites": {"garage": "ui_map_region_label_garage", "gym": "ui_map_region_label_gym", "boxing": "ui_map_region_label_boxing",
				"bjj": "ui_map_region_label_bjj", "campaign": "ui_map_region_label_campaign"},
			"height": 13, "icon": "icon_region_<região>_9", "icon_offset": [5, 2], "text_offset": [17, 3], "text_color": "col_text_1",
			"rule": "Aparece quando o 1º nó da região fica à vista, no mundo (anda com o mapa), uns 30-40 px acima do 1º nó da região, sem cobrir nó. Largura = 21 + texto. Sem plaquinha para o centro (os 12 já se explicam pela cortiça)."},
		"region_icons": {"garage": "icon_region_garage", "gym": "icon_region_gym", "boxing": "icon_region_boxing", "bjj": "icon_region_bjj", "campaign": "icon_region_campaign"},
		"card": {"panel": "ui_map_card", "next_strip": "ui_map_card_next", "next_icon": "icon_calendar", "next_text_color": "col_text_1",
			"lines": ["nome col_text_1", "efeito na cor do tipo (Treino gr3, dinheiro y1, Fama f2, Legado p2, arte p1)", "preço: icon_legacy + número col_legacy (col_text_2 sem saldo)"],
			"rule": "Cartão ao passar o mouse: 9-slice d1; a faixa roxa de baixo (1 px dentro da borda) diz 'VALE NA PRÓXIMA CAMPANHA' com a folhinha. Abre à direita do nó (ou à esquerda se não couber), sempre inteiro dentro da viewport_rect."},
		"icon_by_effect": {"click_bonus": "skill_body_jab", "passive_bonus": "skill_body_crew", "money_bonus": "skill_career_purse",
			"fame_bonus": "skill_career_crowd", "preview_percent": "skill_career_scouting", "defeat_share_bonus": "skill_career_good_loser",
			"metronome_start": "skill_body_muscle_memory", "art_rule_bonus": {"boxing": "skill_style_boxing", "bjj": "skill_style_bjj"},
			"art_fight_bonus": {"boxing": "skill_counter_punch", "bjj": "skill_firm_base"},
			"legacy_bonus": "skill_coach_notebook", "rope_installed": "skill_rope_ready", "prep_days_bonus": "skill_prep_day",
			"crew_click_bonus": "skill_shout_loud", "start_generator": "skill_crew_regulars", "gym_training_bonus": "skill_standing_fan",
			"equipment_bonus": "ícone da LOJA do aparelho (icon_bag, icon_rope, icon_treadmill, icon_speed_bag, icon_grappling_dummy)",
			"_nota": "Reserva por tipo de efeito (objeto = escolher pela requires_art do nó). Tipos com os nomes reais do skill_tree.json v2. Quem manda é icon_by_node."},
		"icon_by_node": ICON_BY_NODE,
		"icon_rule": "Ícone 16x16 de um nó do mapa: icon_by_node[id] -> senão icon_by_effect[effect.type] (objeto: pela requires_art) -> senão o campo icon do nó. icon_by_node cobre os 39 nós do skill_tree.json v2: os 12 do centro com os skill_body_*/skill_career_*/skill_style_* de sempre, os pequenos novos com o ícone do tipo, os 6 marcos da 2ª passada com ícone próprio e as ligações com o ícone do tipo dentro da peça de ligação. O campo icon do JSON ainda aponta para icon_region_*/icon_legacy_16 nesses 6 marcos (dado do Designer); pela regra acima o manifest ganha.",
		"milestone_icons": MILESTONE_ICONS,
		"map_check": MAP_CHECK,
		"room_button": {"normal": "ui_map_button_normal", "hover": "ui_map_button_hover", "pressed": "ui_map_button_pressed", "glow": "ui_map_button_glow",
			"glow_fps": 2.0, "rect": [132, 22, 22, 22], "tooltip": "dica padrão (d1): 'ÁRVORE' + 2ª linha col_text_2 com quantos nós dá para comprar",
			"note": "Canto de cima à esquerda da sala, na parede lateral (garagem e academia), longe do alvo (x 281..362) e das faixas de aviso (centradas em x 320). Sem compra possível: normal, sem animação. Com nó à vista que o Legado paga: alterna glow 0/1 a 2 fps (borda ouro, faísca no canto). Sem alpha, sem tremer, sem som. Plano B se o dono não achar o botão: mesma peça com texto 'ÁRVORE' no fim da coluna da esquerda, (7,264) 116x22."},
		"fx": {"reveal": {"sprite": "fx_map_reveal", "fps": 12.0, "loop": false, "pivot": "centro do nó"},
			"buy": {"sprite": "fx_map_buy", "fps": 12.0, "loop": false, "pivot": "centro do nó",
				"order": "compra: fx_map_buy no nó (0,42 s) e o anel troca para comprado no quadro 1; no quadro 2 começam as revelações dos vizinhos (fx_map_reveal + neblina recuando), todas juntas. Total até o último vizinho assentar: ~0,6 s; cada revelação dura 0,5 s."}},
		"_nota": "Fase 5.4 (Diretor de Arte), direcao-visual.md §21. Posições em 1x (base 640x360). Posições, vizinhos e ids são do Designer (data/skill_tree.json, map.unit_px). Mockups: fase54_mapa_x2.png (peças) e fase54_mapa_real_x2.png (mapa real, 2ª passada)."}

# ================================================================ main
func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	FINAL = OS.get_cmdline_user_args().has("--final")
	var here: String = OS.get_environment("ART54_OUT")
	if here == "":
		here = ProjectSettings.globalize_path("res://")
	OUT = (ROOT + "assets/sprites/") if FINAL else (here.trim_suffix("/") + "/out/")
	MOCK = (ROOT + "docs/arte/mockups/") if FINAL else (here.trim_suffix("/") + "/out/mock/")
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível")
		quit()
		return
	OLD = j.data
	if not load_tree():
		quit()
		return
	gen_all()
	make_mockup()
	DirAccess.make_dir_recursive_absolute(MOCK)
	var big: Image = MOCK_IMG.duplicate()
	big.resize(MOCK_IMG.get_width() * 2, MOCK_IMG.get_height() * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(MOCK + "fase54_mapa_x2.png")
	var real := make_mockup_real()
	real.resize(real.get_width() * 2, real.get_height() * 2, Image.INTERPOLATE_NEAREST)
	real.save_png(MOCK + "fase54_mapa_real_x2.png")
	print("checagem do mapa real: ", JSON.stringify(MAP_CHECK))
	if FINAL:
		write_manifest()
	print("ok fase 5.4 arte (%s): %d sprites" % ["PROJETO" if FINAL else "previa", M.size()])
	quit()

func gen_all() -> void:
	var D := "ui/map/"
	var tiles := {"map_tile_wall": [tile_wall(), "Parede escura da escola (reboco d1): o que sobra entre as regiões."],
		"map_tile_center": [tile_center(), "Cortiça (br1/br2/br0): o quadro do centro, onde ficam os 12 nós de sempre."],
		"map_tile_garage": [tile_garage(), "Concreto em blocos 16x8 (g0/g1/d2): região Garagem."],
		"map_tile_gym": [tile_gym(), "Azulejo verde 8x8 (gr1/gr0/gr2), o barrado da academia: região Academia."],
		"map_tile_boxing": [tile_boxing(), "Lona do ringue (r0/r1): região Boxe."],
		"map_tile_bjj": [tile_bjj(), "Tatame azul em placas 16x16 (b1/b0/b2): região Jiu-jitsu."],
		"map_tile_campaign": [tile_campaign(), "Feltro roxo do mural das campanhas (p0/p1): região Campanha."]}
	for id in tiles:
		save_sheet(id, D + id + ".png", [tiles[id][0]], 0, Vector2i.ZERO, {"tileable": true,
			"note": "Ladrilho 32x32 que emenda nos 4 lados (Fase 5.4). " + tiles[id][1] + " Ver by_data_id.skill_map.world."})
	for lv in [25, 50, 75, 100]:
		save_sheet("map_fog_%d" % lv, D + "map_fog_%d.png" % lv, [fog_tile(lv / 25)], 0, Vector2i.ZERO, {"tileable": true,
			"note": "Neblina %d%% (Bayer 4x4, ink com nuvens d1/d2), ladrilho 32x32. Ver by_data_id.skill_map.fog." % lv})
	# nós pequenos
	for t in TONES:
		save_sheet("map_node_s_owned_" + t, D + "map_node_s_owned_%s.png" % t, [node_small(TONES[t][0], TONES[t][1], "d2", "g0", true)], 0, Vector2i(12, 12), {
			"note": "Nó pequeno COMPRADO, anel %s (%s/%s), miolo d2, tachinha dourada. Ícone 16x16 no centro." % [t, TONES[t][0], TONES[t][1]]})
		save_sheet("map_node_b_owned_" + t, D + "map_node_b_owned_%s.png" % t, [node_big(TONES[t][0], TONES[t][1], "d2", "g0", true)], 0, Vector2i(19, 19), {
			"note": "MARCO comprado, anel duplo %s com 4 pontas, tachinha dourada. Ícone 16x16 no centro." % t})
	save_sheet("map_node_s_buyable", D + "map_node_s_buyable.png", [node_small("y1", "y2", "d1", "d2"), node_small("y0", "y1", "d1", "d2")], 2.0, Vector2i(12, 12), {
		"note": "Nó pequeno À VISTA que o Legado paga: anel ouro claro (col_buyable), 2 quadros a 2 fps."})
	save_sheet("map_node_s_missing", D + "map_node_s_missing.png", [node_small("g0", "d2", "ink", null)], 0, Vector2i(12, 12), {
		"note": "Nó pequeno À VISTA sem Legado: anel escuro, miolo ink. Pôr map_node_veil por cima do ícone."})
	var hid: Image = node_small("d2", "d1", "ink", null)
	q_mark(hid, 12, 12, "g1")
	save_sheet("map_node_s_hidden", D + "map_node_s_hidden.png", [hid], 0, Vector2i(12, 12), {
		"note": "Nó pequeno ESCONDIDO ('?'): quadro de partida da revelação. No mapa parado o escondido não é desenhado."})
	save_sheet("map_node_s_hover", D + "map_node_s_hover.png", [edge_mask(node_small("ink", "ink", "ink", null), "white")], 0, Vector2i(12, 12), {
		"note": "Contorno branco do nó pequeno (mouse em cima), por cima do frame."})
	save_sheet("map_node_b_buyable", D + "map_node_b_buyable.png", [node_big("y1", "y2", "d1", "d2"), node_big("y0", "y1", "d1", "d2")], 2.0, Vector2i(19, 19), {
		"note": "MARCO à vista que o Legado paga: 2 quadros a 2 fps."})
	save_sheet("map_node_b_missing", D + "map_node_b_missing.png", [node_big("g0", "d2", "ink", null, false, "g0")], 0, Vector2i(19, 19), {
		"note": "MARCO à vista sem Legado. map_node_veil por cima do ícone."})
	var hidb: Image = node_big("d2", "d1", "ink", null, false, "d2")
	q_mark(hidb, 19, 19, "g1")
	save_sheet("map_node_b_hidden", D + "map_node_b_hidden.png", [hidb], 0, Vector2i(19, 19), {"note": "MARCO escondido ('?'), quadro de partida da revelação."})
	save_sheet("map_node_b_hover", D + "map_node_b_hover.png", [edge_mask(node_big("ink", "ink", "ink", null), "white")], 0, Vector2i(19, 19), {
		"note": "Contorno branco do marco (mouse em cima)."})
	# ligação
	save_sheet("map_node_l_buyable", D + "map_node_l_buyable.png", [node_link("y1", "y2", "y1", "y2", "d1", "d2", "g1", "g1"), node_link("y0", "y1", "y0", "y1", "d1", "d2", "g1", "g1")], 2.0, Vector2i(14, 12), {
		"note": "Nó de LIGAÇÃO à vista que o Legado paga (2 quadros a 2 fps). Os elos dos lados dizem 'liga duas regiões'."})
	save_sheet("map_node_l_missing", D + "map_node_l_missing.png", [node_link("g0", "d2", "g0", "d2", "ink", null, "g0", "g0")], 0, Vector2i(14, 12), {
		"note": "Nó de ligação à vista sem Legado. map_node_veil por cima do ícone."})
	var hidl: Image = node_link("d2", "d1", "d2", "d1", "ink", null, "d2", "d2")
	q_mark(hidl, 14, 12, "g1")
	save_sheet("map_node_l_hidden", D + "map_node_l_hidden.png", [hidl], 0, Vector2i(14, 12), {"note": "Ligação escondida ('?'), quadro de partida da revelação."})
	save_sheet("map_node_l_hover", D + "map_node_l_hover.png", [edge_mask(node_link("ink", "ink", "ink", "ink", "ink", null, "ink", "ink"), "white")], 0, Vector2i(14, 12), {
		"note": "Contorno branco da ligação (mouse em cima)."})
	for i in REGIONS.size():
		for k in range(i + 1, REGIONS.size()):
			var a: String = REGIONS[i]
			var b: String = REGIONS[k]
			var ta: Array = TONES[TONE_BY[a]]
			var tb: Array = TONES[TONE_BY[b]]
			save_sheet("map_node_link_owned_%s_%s" % [a, b], D + "map_node_link_owned_%s_%s.png" % [a, b],
				[node_link(ta[0], ta[1], tb[0], tb[1], "d2", "g0", ta[1], tb[1], true)], 0, Vector2i(14, 12), {
				"note": "Ligação COMPRADA %s + %s: anel cortado na diagonal (metade de cima/esquerda %s, de baixo/direita %s), elos nas duas cores, tachinha." % [a, b, a, b]})
	save_sheet("map_node_veil", D + "map_node_veil.png", [veil(16, 16, 6)], 0, Vector2i(8, 8), {
		"note": "Véu pontilhado (37% ink, Bayer 6/16) por cima do ícone do nó sem Legado. Pivô no centro do ícone."})
	# moldura e UI do mapa
	save_sheet("ui_map_frame", D + "ui_map_frame.png", [map_frame()], 0, Vector2i.ZERO, {"nine_slice": {"left": 5, "top": 5, "right": 5, "bottom": 5},
		"note": "Moldura 9-slice do mapa em tela cheia (640x360): quadro de madeira com pregos, miolo vazio. Por cima do mapa."})
	save_sheet("ui_map_topbar", D + "ui_map_topbar.png", [map_topbar()], 0, Vector2i.ZERO, {"nine_slice": {"left": 1, "top": 1, "right": 1, "bottom": 2},
		"note": "Barra do topo do mapa (9-slice, 630x20 em (5,5)): título, dica de navegação, Legado em txt_hero e o X."})
	save_sheet("ui_map_viewport_edge", D + "ui_map_viewport_edge.png", [viewport_edge()], 0, Vector2i.ZERO, {"nine_slice": {"left": 2, "top": 2, "right": 1, "bottom": 1},
		"note": "Borda da janela do mapa (9-slice, miolo vazio): 1 px ink + sombra pontilhada em cima e à esquerda (o mapa parece rebaixado dentro do quadro)."})
	for st in ["normal", "hover", "pressed"]:
		save_sheet("ui_map_close_" + st, D + "ui_map_close_%s.png" % st, [close_btn(st)], 0, Vector2i.ZERO, {"note": "Botão X 16x16 do mapa (%s). Em (616,7)." % st})
	for r in REGIONS:
		save_sheet("ui_map_region_label_" + r, D + "ui_map_region_label_%s.png" % r, [region_label(TONE_BY[r])], 0, Vector2i.ZERO, {
			"nine_slice": {"left": 5, "top": 2, "right": 2, "bottom": 2},
			"note": "Plaquinha 9-slice do nome da região %s (13 px de altura), faixa à esquerda na cor do anel. Ícone icon_region_%s_9 em (5,2), texto 1x col_text_1 em (17,3)." % [r, r]})
	save_sheet("ui_map_price_ok", D + "ui_map_price_ok.png", [price_tag(true)], 0, Vector2i.ZERO, {"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 1},
		"note": "Etiqueta de preço embaixo do nó à vista que o Legado paga: fundo p0, número col_legacy (p2), icon_legacy em (2,1)."})
	save_sheet("ui_map_price_missing", D + "ui_map_price_missing.png", [price_tag(false)], 0, Vector2i.ZERO, {"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 1},
		"note": "Etiqueta de preço do nó à vista sem Legado: fundo d1, número col_text_2 (nunca vermelho)."})
	save_sheet("ui_map_card", D + "ui_map_card.png", [card()], 0, Vector2i.ZERO, {"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 2},
		"note": "Cartão do nó (9-slice d1, igual à dica). Linhas: nome, efeito, preço; embaixo a faixa ui_map_card_next."})
	save_sheet("ui_map_card_next", D + "ui_map_card_next.png", [card_next()], 0, Vector2i.ZERO, {"nine_slice": {"left": 1, "top": 1, "right": 1, "bottom": 1},
		"note": "Faixa roxa 'VALE NA PRÓXIMA CAMPANHA' no pé do cartão: icon_calendar em (3,1), texto 1x col_text_1 em (17,3)."})
	# fx
	var rv := []
	for i in 6:
		rv.append(fx_reveal(i))
	save_sheet("fx_map_reveal", D + "fx_map_reveal.png", rv, 12.0, Vector2i(20, 20), {"loop": false,
		"note": "Revelação de um nó (6 quadros, 12 fps = 0,5 s): a nuvem com '?' se abre em fiapos e sobram 4 faíscas. Pivô no centro do nó; o nó aparece por baixo a partir do quadro 2."})
	var bv := []
	for i in 5:
		bv.append(fx_buy(i))
	save_sheet("fx_map_buy", D + "fx_map_buy.png", bv, 12.0, Vector2i(20, 20), {"loop": false,
		"note": "Compra de um nó (5 quadros, 12 fps = 0,42 s): clarão branco no formato do nó, anel ouro abrindo, faíscas. Pivô no centro do nó."})
	# botão da sala
	for st in ["normal", "hover", "pressed"]:
		save_sheet("ui_map_button_" + st, "ui/ui_map_button_%s.png" % st, [map_button(st)], 0, Vector2i.ZERO, {
			"note": "Botão da árvore na sala (22x22, %s), em (132,22). Ver by_data_id.skill_map.room_button." % st})
	save_sheet("ui_map_button_glow", "ui/ui_map_button_glow.png", [map_button("normal", 0), map_button("normal", 1)], 2.0, Vector2i.ZERO, {
		"note": "Botão da árvore com BRILHO (há nó à vista que o Legado paga): borda ouro y2/y1 e faísca trocando de canto, 2 quadros a 2 fps. Mesmo lugar do normal."})
	# ícones
	save_sheet("icon_skill_map", "ui/icon_skill_map.png", [icon_skill_map()], 0, Vector2i.ZERO, {
		"note": "Ícone 16x16 da árvore/mapa: quadro de cortiça com 3 tachinhas ligadas por barbante. Botão da sala, título do mapa, botão ÁRVORE da tela de fim."})
	save_sheet("icon_skill_map_9", "ui/icon_skill_map_9.png", [icon_skill_map(9)], 0, Vector2i.ZERO, {"note": "Ícone 9x9 da árvore/mapa, em linha com texto 1x (dicas)."})
	for r in REGIONS:
		save_sheet("icon_region_" + r, "ui/icon_region_%s.png" % r, [icon_region(r)], 0, Vector2i.ZERO, {
			"note": "Ícone 16x16 da região %s do mapa. Também é o ícone provisório dos marcos da região até a 2ª passada." % r})
		save_sheet("icon_region_%s_9" % r, "ui/icon_region_%s_9.png" % r, [icon_region_9(r)], 0, Vector2i.ZERO, {
			"note": "Ícone 9x9 da região %s (plaquinha do nome da região)." % r})
	save_sheet("skill_rope_ready", "ui/skill_rope_ready.png", [skill_rope_ready()], 0, Vector2i.ZERO, {
		"note": "Ícone 16x16 do nó 'Corda montada': a corda já pendurada no prego, com brilho de pronta."})
	save_sheet("skill_prep_day", "ui/skill_prep_day.png", [skill_prep_day()], 0, Vector2i.ZERO, {
		"note": "Ícone 16x16 do nó '+1 dia de preparo': folhinha com '+1'."})
	save_sheet("skill_shout_loud", "ui/skill_shout_loud.png", [skill_shout_loud()], 0, Vector2i.ZERO, {
		"note": "Ícone 16x16 do nó 'Grito mais alto': o megafone verde do Grito, maior e com 3 ondas."})
	# 2ª passada: ícones próprios dos 6 marcos (fase5.4-design.md §9)
	var mi := {"skill_home_metronome": [skill_home_metronome(), "gar_metro 'Pêndulo de casa': metrônomo de madeira em cima de um tijolo."],
		"skill_crew_regulars": [skill_crew_regulars(), "gar_crew_start 'Turma de sempre': três chinelos (azul, verde, vermelho) na porta da garagem."],
		"skill_coach_notebook": [skill_coach_notebook(), "camp_diary 'Caderno do velho': caderno de capa dura roxa com elástico e fitinha."],
		"skill_standing_fan": [skill_standing_fan(), "gym_fan 'Ventilador novo': ventilador de coluna com grade e pás."],
		"skill_counter_punch": [skill_counter_punch(), "box_counter 'Contragolpe': luva vermelha com seta curva voltando."],
		"skill_firm_base": [skill_firm_base(), "bjj_guard 'Base firme': pernas de kimono em base larga, pés firmes no tatame."]}
	for iid in mi:
		save_sheet(iid, "ui/%s.png" % iid, [mi[iid][0]], 0, Vector2i.ZERO, {
			"note": "Ícone 16x16 de MARCO (Fase 5.4, 2ª passada). " + mi[iid][1] + " Dentro da peça 38x38 do marco (pivô 19,19 + icon_offset -8,-8)."})
