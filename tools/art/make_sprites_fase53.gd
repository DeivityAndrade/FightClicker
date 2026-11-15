extends SceneTree
## Fase 5.3 (Diretor de Arte) - PLACEHOLDER gerado por código. Calendário da campanha.
##   ui/icon_calendar, icon_calendar_alert (11x11)        ícone em linha (HUD, faixas)
##   ui/ui_calendar_page (20x22, 2 quadros)               folhinha do HUD: 0 normal, 1 dia circulado (dia da luta)
##   ui/fx_calendar_tear (32x32, 4 quadros)               folha arrancada quando o dia vira
##   ui/ui_countdown_plate_{easy,even,hard,today,done}    plaquinha 9-slice do "Faltam X dias" (faixa na cor do risco)
##   ui/ui_warn_strip_3d, _1d, _1d_hi                     faixas de aviso 9-slice (3 dias calma; 1 dia urgente, pulso)
##   ui/ui_day_badge (32x34)                              folhinha grande com o dia circulado, presa na prévia do dia
##   ui/ui_button_pass_{normal,hover,pressed,disabled}    botão PASSAR O POSTO (contorno roxo, ação secundária)
##   ui/icon_pass_post (16x16)                            luva -> Legado
##   ui/icon_campaign_complete (20x22), seal_campaign_complete (40x44)
##   docs/arte/mockups/fase53_calendario_x2.png
## Retratos da luta por luva (portrait_player_glove_lN): make_sprites_jogador.gd -- <saida> --so-retratos.
## Rodar de uma pasta temporária com project.godot vazio:
##   Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_sprites_fase53.gd -- [--final]
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
			d[k] = v[k] if str(k) == "fps" else intify(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(intify(x))
		return a
	if v is float and v == floor(v) and absf(v) < 1e9:
		return int(v)
	return v

func star_fill(img: Image, cx: float, cy: float, ro: float, ri: float, c, rot := -PI / 2.0) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := rot + i * PI / 5.0
		var r := ro if i % 2 == 0 else ri
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	for y in img.get_height():
		for x in img.get_width():
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				L.P(img, x, y, c)

# ================================================================ calendário
func icon_calendar(alert: bool) -> Image:
	var im: Image = L.blank(11, 11)
	L.R(im, 0, 1, 11, 10, "ink")
	L.R(im, 1, 2, 9, 1, "r3")
	L.R(im, 1, 3, 9, 1, "r2")
	L.R(im, 1, 4, 9, 5, "white")
	L.R(im, 9, 4, 1, 5, "cream")
	L.R(im, 1, 9, 9, 1, "cream")
	for x in [3, 7]:
		L.P(im, x, 0, "g2")
		L.P(im, x, 1, "g3")
		L.P(im, x, 2, "ink")
	if alert:
		L.R(im, 4, 4, 2, 3, "r2")
		L.R(im, 4, 4, 1, 3, "r1")
		L.R(im, 4, 8, 2, 1, "r2")
	else:
		for p in [[2, 5], [4, 5], [6, 5], [2, 7], [4, 7], [6, 7]]:
			L.P(im, p[0], p[1], "g2")
		L.P(im, 8, 7, "r2")
		L.P(im, 8, 5, "g2")
	return im

## Folhinha 20x22: argolas, cabeçalho vermelho, picote, corpo branco, folhas de baixo (2 linhas de borda).
func page_base(head := ["r3", "r2", "r1"]) -> Image:
	var im: Image = L.blank(20, 22)
	L.R(im, 1, 3, 19, 19, "ink")          # folhas de baixo
	L.R(im, 2, 4, 17, 17, "g3")
	L.R(im, 0, 2, 19, 19, "ink")          # folha da frente x0..18, y2..20
	L.R(im, 1, 3, 17, 1, head[0])
	L.R(im, 1, 4, 17, 3, head[1])
	L.R(im, 1, 7, 17, 1, head[2])
	L.R(im, 1, 8, 17, 12, "white")
	for x in range(1, 18, 2):
		L.P(im, x, 8, "cream")               # picote da folha arrancada
	L.R(im, 17, 9, 1, 11, "cream")
	L.R(im, 1, 19, 17, 1, "cream")
	for x in [5, 13]:
		L.R(im, x - 1, 0, 3, 4, "ink")
		L.R(im, x, 0, 1, 4, "g3")
		L.P(im, x, 0, "g2")
		L.P(im, x, 4, "ink")
	return im

func calendar_page(circled: bool) -> Image:
	var im := page_base()
	if circled:
		marker_ring(im, 9.0, 14.5, 8.2, 5.4)
	return im

## Caneta vermelha: anel irregular (mais grosso em cima à esquerda) e a ponta que passa do começo.
func marker_ring(im: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in im.get_height():
		for x in im.get_width():
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			var d := sqrt(dx * dx + dy * dy)
			var ang := atan2(dy, dx)
			var t := 0.16 + 0.10 * clampf(-sin(ang + 0.6), 0.0, 1.0)
			if absf(d - 1.0) < t and ang > -2.35 or (absf(d - 1.08) < 0.13 and ang <= -2.35 and ang > -2.9):
				L.P(im, x, y, "r2")

func tear_frame(i: int) -> Image:
	var im: Image = L.blank(32, 32)
	var poses := [[Vector2(15.5, 24.0), -0.06, 1.0], [Vector2(18.0, 19.0), -0.26, 0.95],
		[Vector2(22.0, 12.5), -0.62, 0.75], [Vector2(25.0, 6.5), -1.05, 0.5]]
	var c: Vector2 = poses[i][0]
	var ang: float = poses[i][1]
	var sc: float = poses[i][2]
	var w := 17.0
	var h := 12.0
	for y in 32:
		for x in 32:
			var d := (Vector2(x + 0.5, y + 0.5) - c).rotated(-ang) / sc + Vector2(w / 2.0, h / 2.0)
			if d.x < 0 or d.y < 0 or d.x >= w or d.y >= h:
				continue
			if d.y < 1.0 and int(d.x) % 2 == 1:
				continue                     # picote rasgado
			if i == 3 and (x + y) % 2 == 1:
				continue                     # some em pontilhado
			var col := "white"
			if d.x > w - 1.5 or d.y > h - 1.5:
				col = "cream"
			if i == 0 and d.x + d.y > w + h - 6.0:
				col = "g3" if d.x + d.y > w + h - 4.0 else "cream"   # canto levantando
			L.P(im, x, y, col)
	return ol(im, "ink") if i < 3 else im

func plate(stripe: Array, bg := "d1", hi := "d2") -> Image:
	var im: Image = L.blank(16, 16)
	L.R(im, 0, 0, 16, 16, "ink")
	L.R(im, 1, 1, 14, 14, bg)
	L.R(im, 3, 1, 12, 1, hi)
	L.R(im, 1, 14, 14, 1, L.shade(L.col(bg), -1))
	L.R(im, 1, 1, 2, 14, stripe[1])
	L.R(im, 1, 1, 2, 1, stripe[0])
	L.R(im, 1, 14, 2, 1, stripe[2])
	return im

func warn_3d() -> Image:
	var im: Image = L.blank(40, 18)
	L.R(im, 0, 0, 40, 18, "ink")
	L.R(im, 1, 1, 38, 16, "d1")
	L.R(im, 1, 1, 38, 1, "d2")
	L.R(im, 1, 16, 38, 1, "ink")
	L.R(im, 4, 2, 35, 1, "br2")
	L.R(im, 4, 15, 35, 1, "br2")
	L.R(im, 1, 1, 3, 16, "y0")
	L.R(im, 1, 1, 3, 1, "y1")
	L.R(im, 1, 16, 3, 1, "br2")
	return im

func warn_1d(hi: bool) -> Image:
	var im: Image = L.blank(40, 18)
	L.R(im, 0, 0, 40, 18, "ink")
	L.R(im, 1, 1, 38, 16, "r1")
	L.R(im, 1, 1, 38, 1, "r2")
	L.R(im, 1, 16, 38, 1, "r0")
	var a := "r3" if hi else "r2"
	var b := "r1" if hi else "r0"
	for side in [1, 31]:
		for y in range(1, 17):
			for x in range(side, side + 8):
				L.P(im, x, y, a if ((x + y) / 3) % 2 == 0 else b)
	L.R(im, 9, 1, 1, 16, "ink")
	L.R(im, 30, 1, 1, 16, "ink")
	var trim := "y2" if hi else "y1"
	L.R(im, 10, 2, 20, 1, trim)
	L.R(im, 10, 15, 20, 1, "y0" if not hi else "y1")
	return im

func day_badge() -> Image:
	var im: Image = L.blank(40, 40)
	L.R(im, 1, 4, 39, 36, "ink")          # folhas de baixo
	L.R(im, 2, 5, 37, 34, "g3")
	L.R(im, 0, 3, 39, 36, "ink")          # folha da frente x0..38, y3..38
	L.R(im, 1, 4, 37, 1, "r3")
	L.R(im, 1, 5, 37, 7, "r2")
	L.R(im, 1, 12, 37, 1, "r1")
	L.R(im, 1, 13, 37, 25, "white")
	for x in range(1, 38, 2):
		L.P(im, x, 13, "cream")
	L.R(im, 37, 14, 1, 24, "cream")
	L.R(im, 1, 37, 37, 1, "cream")
	marker_ring(im, 19.0, 25.5, 15.6, 9.8)
	L.line(im, 31, 16, 34, 14, "r2")
	# fita crepe segurando
	L.R(im, 13, 0, 13, 6, "cream")
	L.R(im, 13, 0, 13, 1, "y2")
	L.dither(im, 14, 1, 11, 5, "g3")
	L.P(im, 13, 0, Color(0, 0, 0, 0))
	L.P(im, 25, 5, Color(0, 0, 0, 0))
	return im

func button_pass(state: String) -> Image:
	var im: Image = L.blank(16, 17)
	if state == "pressed":
		L.R(im, 0, 1, 16, 16, "ink")
		L.R(im, 1, 3, 14, 13, "p1")
		L.R(im, 2, 4, 12, 11, "p0")
		return im
	L.R(im, 0, 0, 16, 16, "ink")
	L.R(im, 1, 16, 15, 1, "ink")
	if state == "disabled":
		L.R(im, 1, 1, 14, 14, "d1")
		return im
	var border := "p2" if state == "hover" else "p1"
	var fill := "p0" if state == "hover" else "d1"
	L.R(im, 1, 1, 14, 12, border)
	L.R(im, 2, 2, 12, 10, fill)
	L.R(im, 2, 2, 12, 1, L.shade(L.col(fill), 1))
	return im

func icon_pass_post() -> Image:
	var im: Image = L.blank(16, 16)
	L.glove(im, 1, 1, 8, 7, ["r0", "r1", "r2"])
	# seta roxa da luva para a estrela
	for p in [[9, 3], [10, 3], [11, 4], [12, 5], [11, 6], [12, 6], [13, 6]]:
		L.P(im, p[0], p[1], "p2")
	star_fill(im, 10.5, 11.0, 4.6, 2.0, "p2")
	L.P(im, 10, 9, "white")
	return ol(im)

func icon_campaign_complete() -> Image:
	var im := page_base(["y2", "y1", "y0"])
	star_fill(im, 9.0, 13.8, 5.4, 2.4, "y0")
	star_fill(im, 9.0, 13.2, 4.2, 1.8, "y1")
	L.P(im, 8, 11, "y2")
	return im

func seal_campaign_complete() -> Image:
	var im: Image = L.blank(40, 44)
	var c := Vector2(20, 19)
	# fitas (vermelhas, como a faixa do cinturão)
	L.trap(im, 26, 42, 11.0, 18.0, 6.0, 13.0, "r1")
	L.trap(im, 26, 42, 22.0, 29.0, 27.0, 34.0, "r1")
	L.trap(im, 26, 42, 14.0, 18.0, 9.0, 13.0, "r2")
	L.trap(im, 26, 42, 25.0, 29.0, 30.0, 34.0, "r2")
	for k in 3:   # bico em V no pé das fitas
		for x in range(8 - k + 2, 12 + k - 1):
			L.P(im, x, 42 - k, Color(0, 0, 0, 0))
		for x in range(29 - k + 2, 33 + k - 1):
			L.P(im, x, 42 - k, Color(0, 0, 0, 0))
	# roseta dentada
	for i in 20:
		var a := i * TAU / 20.0
		L.ellipse(im, c.x + cos(a) * 15.0, c.y + sin(a) * 15.0, 2.6, 2.6, "y0")
	L.ellipse(im, c.x, c.y, 15.5, 15.5, "y0")
	L.ellipse(im, c.x, c.y, 12.5, 12.5, "br2")
	L.ellipse(im, c.x, c.y, 11.5, 11.5, "y1")
	L.ellipse_dither(im, c.x + 3, c.y + 3, 9.0, 9.0, "y0")
	star_fill(im, c.x, c.y + 0.5, 8.0, 3.4, "br2")
	star_fill(im, c.x, c.y, 7.0, 2.9, "y2")
	L.P(im, int(c.x) - 1, int(c.y) - 4, "white")
	L.P(im, 9, 9, "y2")
	L.P(im, 10, 8, "y2")
	return ol(im)

# ================================================================ mockup
var FC := {}   # cores amostradas da captura

func base_cap(name: String) -> Image:
	var im := load_abs(CAPS + name)
	im.resize(640, 360, Image.INTERPOLATE_NEAREST)
	return im

func T(img: Image, s: String, x: int, y: int, c, shadow = null) -> int:
	return L.text(img, s, x, y, c, 1, shadow)

## Bloco do calendário na coluna da esquerda (1x): plaquinha (7,131) 116x26, folhinha (11,133), texto x 35.
func hud_block(img: Image, plate_id: String, page_id: String, page_fr: int, l1: String, c1: String, l2: String, c2: String, risk_id: String, risk_txt: String) -> void:
	var bg: Color = img.get_pixel(60, 200)
	L.R(img, 4, 129, 122, 46, bg)
	ns(img, plate_id, 7, 131, 116, 26)
	put(img, page_id, page_fr, 11, 133)
	T(img, l1, 35, 136, c1, "ink")
	if l2 != "":
		T(img, l2, 35, 146, c2, "ink")
	if risk_id != "":
		var w: int = 9 + 4 + L.text_w(risk_txt) + 6
		ns(img, risk_id, 35, 160, w, 13)
		var ic := "icon_risk_" + risk_id.trim_prefix("ui_risk_")
		put(img, ic, 0, 38, 162)
		T(img, risk_txt, 50, 163, "white", "ink")

func day_number(img: Image, n: String, px: int, py: int) -> void:
	# número 1x no meio da folhinha (área [2,10,15,9])
	T(img, n, px + 2 + (15 - L.text_w(n)) / 2, py + 11, "d1")

func pass_button_off(img: Image) -> void:
	# botão da sala fora do dia: mesmo roxo, texto novo, ícone novo (sugestão)
	ns(img, "ui_button_retire_normal", 520, 333, 115, 21)
	var tw: int = L.text_w("PASSAR O POSTO")
	var x0 := 520 + (115 - (16 + 4 + tw)) / 2
	put(img, "icon_pass_post", 0, x0, 334)
	T(img, "PASSAR O POSTO", x0 + 20, 339, "p2", "ink")

func strip_on(img: Image, id: String, icon: String, txt: String, num_col: String, x: int, w: int, cap: int) -> void:
	ns(img, id, x, 22, w, 18)
	put(img, icon, 0, x + cap + 3, 25)
	T(img, txt, x + cap + 3 + 11 + 5, 27, num_col, "ink")

func panel_title(out: Image, s: String, x: int, y: int) -> void:
	T(out, s, x, y, "y1", "ink")

func make_mockup() -> void:
	var W := 8 + 640 + 8 + 640 + 8
	var H := 30 + 3 * (16 + 360 + 8)
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	T(out, "FASE 5.3 - CALENDARIO DA CAMPANHA (placeholder, 1x ampliado 2x). Textos: provisorios, o Roteirista fecha.", 8, 8, "white", "ink")
	var cells := []
	for r in 3:
		for c in 2:
			cells.append(Vector2i(8 + c * 648, 30 + r * 384))
	# A: HUD normal
	var a := base_cap("f52_l4_sala.png")
	hud_block(a, "ui_countdown_plate_easy", "ui_calendar_page", 0, "FALTAM 6 DIAS", "white", "DUDU ALONGADO", "g2", "ui_risk_easy", "FÁCIL")
	day_number(a, "4", 11, 133)
	pass_button_off(a)
	# B: 3 dias
	var b := base_cap("f52_l4_sala.png")
	hud_block(b, "ui_countdown_plate_even", "ui_calendar_page", 0, "FALTAM 3 DIAS", "white", "DUDU ALONGADO", "g2", "ui_risk_even", "EQUILIBRADO")
	day_number(b, "7", 11, 133)
	strip_on(b, "ui_warn_strip_3d", "icon_calendar", "FALTAM 3 DIAS - DUDU ALONGADO", "white", 214, 212, 4)
	pass_button_off(b)
	# C: 1 dia
	var c := base_cap("f52_l4_sala.png")
	hud_block(c, "ui_countdown_plate_hard", "ui_calendar_page", 0, "FALTA 1 DIA", "white", "DUDU ALONGADO", "g2", "ui_risk_hard", "PERIGOSO")
	day_number(c, "9", 11, 133)
	strip_on(c, "ui_warn_strip_1d_hi", "icon_calendar_alert", "AMANHA TEM LUTA - DUDU ALONGADO", "y2", 196, 248, 10)
	pass_button_off(c)
	# D: dia da luta
	var d := base_cap("f51_previa.png")
	hud_block(d, "ui_countdown_plate_today", "ui_calendar_page", 1, "HOJE É O DIA", "y2", "DUDU ALONGADO", "g2", "ui_risk_hard", "PERIGOSO")
	day_number(d, "12", 11, 133)
	pass_button_off(d)
	L.dither(d, 4, 129, 122, 46, "ink")
	L.dither(d, 520, 333, 115, 22, "ink")
	var tb: Color = d.get_pixel(200, 25)
	L.R(d, 230, 19, 180, 12, tb)
	L.text_center(d, "DIA DA LUTA", 320, 22, "white", 1, "ink")
	L.R(d, 162, 313, 158, 30, d.get_pixel(240, 306))
	ns(d, "ui_button_pass_normal", 164, 315, 153, 25)
	var tw: int = L.text_w("PASSAR O POSTO")
	var x0 := 164 + (153 - (16 + 4 + tw)) / 2
	put(d, "icon_pass_post", 0, x0, 318)
	T(d, "PASSAR O POSTO", x0 + 20, 323, "p2", "ink")
	badge_at(d, 143, 0, "12")
	# E: campanha completa
	var e := base_cap("f52_l4_sala.png")
	hud_block(e, "ui_countdown_plate_done", "icon_campaign_complete", 0, "CAMPANHA", "y1", "COMPLETA", "y1", "", "")
	pass_button_off(e)
	# F: folha de contato
	var f: Image = L.blank(640, 360)
	L.R(f, 0, 0, 640, 360, "d2")
	contact(f)
	var panels := [[a, "A. SALA: FALTAM X DIAS NA COLUNA DA ESQUERDA (FAIXA DA PLAQUINHA = COR DO RISCO)"],
		[b, "B. FALTAM 3 DIAS: FAIXA CALMA NO TOPO DA SALA (SOME SOZINHA)"],
		[c, "C. FALTA 1 DIA: FAIXA URGENTE (PULSA _1d / _1d_hi A 2 FPS) + SOM"],
		[d, "D. DIA DA LUTA: SALA PARADA + PREVIA COM LUTAR! E PASSAR O POSTO"],
		[e, "E. DEPOIS DO KID: CAMPANHA COMPLETA, SEM DATA"],
		[f, "F. SPRITES (2x DENTRO DO PAINEL) E RETRATOS POR LUVA"]]
	for i in 6:
		var p: Vector2i = cells[i]
		panel_title(out, panels[i][1], p.x, p.y + 2)
		L.R(out, p.x - 1, p.y + 13, 642, 362, "ink")
		blend(out, panels[i][0], p.x, p.y + 14)
	var big: Image = out.duplicate()
	big.resize(W * 2, H * 2, Image.INTERPOLATE_NEAREST)
	DirAccess.make_dir_recursive_absolute(MOCK)
	big.save_png(MOCK + "fase53_calendario_x2.png")

func badge_at(img: Image, x: int, y: int, n: String) -> void:
	put(img, "ui_day_badge", 0, x, y)
	L.text_center(img, "HOJE", x + 1 + 37 / 2 + 1, y + 5, "white", 1, "r1")
	L.text(img, n, x + 5 + (29 - L.text_w(n, 2)) / 2 + 1, y + 18, "d1", 2)

func lbl(f: Image, s: String, x: int, y: int) -> void:
	T(f, s, x, y, "g3", "ink")

func contact(f: Image) -> void:
	lbl(f, "ICONES 11x11", 8, 6)
	put_k(f, frame_of("icon_calendar"), 8, 18, 2)
	put_k(f, frame_of("icon_calendar_alert"), 34, 18, 2)
	lbl(f, "FOLHINHA 0 / 1 / COMPLETA", 86, 6)
	put_k(f, frame_of("ui_calendar_page", 0), 86, 18, 2)
	put_k(f, frame_of("ui_calendar_page", 1), 132, 18, 2)
	put_k(f, frame_of("icon_campaign_complete"), 178, 18, 2)
	lbl(f, "FOLHA ARRANCADA (4 QUADROS, 12 FPS)", 232, 6)
	for i in 4:
		var cell: Image = L.blank(32, 32)
		blend(cell, frame_of("ui_calendar_page", 0), 6, 10)
		blend(cell, frame_of("fx_calendar_tear", i), 0, 0)
		put_k(f, cell, 232 + i * 68, 16, 2)
	lbl(f, "SELO", 540, 6)
	put_k(f, frame_of("seal_campaign_complete"), 540, 16, 2)
	# plaquinhas
	lbl(f, "PLAQUINHAS 9-SLICE (116x26)", 8, 100)
	var pl := [["easy", "FALTAM 6 DIAS"], ["even", "FALTAM 3 DIAS"], ["hard", "FALTA 1 DIA"], ["today", "HOJE E O DIA"], ["done", "COMPLETA"]]
	for i in 5:
		var x := 8 + i * 126
		ns(f, "ui_countdown_plate_" + pl[i][0], x, 112, 116, 26)
		put(f, "icon_campaign_complete" if pl[i][0] == "done" else "ui_calendar_page", 1 if pl[i][0] == "today" else 0, x + 4, 114)
		T(f, pl[i][1], x + 28, 122, "y2" if pl[i][0] == "today" else ("y1" if pl[i][0] == "done" else "white"), "ink")
	lbl(f, "FAIXAS 9-SLICE (18 DE ALTURA)", 8, 146)
	strip_on_f(f, "ui_warn_strip_3d", "icon_calendar", "FALTAM 3 DIAS", 8, 158, 120, 4, "white")
	strip_on_f(f, "ui_warn_strip_1d", "icon_calendar_alert", "AMANHA TEM LUTA", 136, 158, 150, 10, "y2")
	strip_on_f(f, "ui_warn_strip_1d_hi", "icon_calendar_alert", "AMANHA TEM LUTA", 294, 158, 150, 10, "y2")
	lbl(f, "_1d E _1d_hi ALTERNAM A 2 FPS", 452, 163)
	lbl(f, "PASSAR O POSTO: NORMAL / HOVER / APERTADO / DESLIGADO", 8, 186)
	var st := ["normal", "hover", "pressed", "disabled"]
	for i in 4:
		var x := 8 + i * 116
		ns(f, "ui_button_pass_" + st[i], x, 198, 110, 22)
		var dy := 2 if st[i] == "pressed" else 0
		var tw: int = L.text_w("PASSAR O POSTO")
		put(f, "icon_pass_post", 0, x + 2, 199 + dy)
		T(f, "PASSAR O POSTO", x + 20 + (88 - tw) / 2, 204 + dy, "g1" if st[i] == "disabled" else "p2", "ink")
	lbl(f, "SELO DO DIA", 476, 186)
	badge_at(f, 480, 196, "12")
	badge_at(f, 530, 196, "4")
	lbl(f, "RETRATO DA LUTA POR LUVA (VELHA, L1, L2, L3, L4) - SEMPRE A LUVA EQUIPADA", 8, 240)
	var sfx := ["", "_glove_l1", "_glove_l2", "_glove_l3", "_glove_l4"]
	for i in 5:
		var x := 8 + i * 84
		put_k(f, frame_of("ui_portrait_frame"), x, 254, 2)
		var p := load_abs(OUT + "fight/portrait_player" + sfx[i] + ".png") if FileAccess.file_exists(OUT + "fight/portrait_player" + sfx[i] + ".png") else load_abs(ROOT + "assets/sprites/fight/portrait_player" + sfx[i] + ".png")
		put_k(f, p, x + 4, 258, 2)
	lbl(f, "ANTES: L4 COM LUVA VERMELHA", 432, 270)
	put_k(f, frame_of("ui_portrait_frame"), 440, 284, 1)
	put_k(f, load_abs(ROOT + "assets/sprites/fight/portrait_player.png"), 442, 286, 1)
	lbl(f, "->", 482, 296)
	put_k(f, frame_of("ui_portrait_frame"), 500, 284, 1)
	var p4 := OUT + "fight/portrait_player_glove_l4.png"
	put_k(f, load_abs(p4 if FileAccess.file_exists(p4) else ROOT + "assets/sprites/fight/portrait_player_glove_l4.png"), 502, 286, 1)

func strip_on_f(f: Image, id: String, icon: String, txt: String, x: int, y: int, w: int, cap: int, col: String) -> void:
	ns(f, id, x, y, w, 18)
	put(f, icon, 0, x + cap + 3, y + 3)
	T(f, txt, x + cap + 3 + 11 + 5, y + 5, col, "ink")

# ================================================================ manifest
func write_manifest() -> void:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível na hora de gravar; nada foi escrito")
		return
	var doc: Dictionary = intify(j.data)
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 5.3") < 0:
		doc["_sobre"] = sobre + " Fase 5.3 (Diretor de Arte): calendário da campanha (folhinha, plaquinhas, faixas de aviso, selo do dia, PASSAR O POSTO, campanha completa) e retrato da luta por luva (direcao-visual.md §20)."
	var sp: Dictionary = doc.get("sprites", {})
	for id in M:
		sp[id] = intify(M[id])
	for sfx in ["_glove_l1", "_glove_l2", "_glove_l3", "_glove_l4"]:
		var e: Dictionary = (sp.get("portrait_player", {}) as Dictionary).duplicate(true)
		e["file"] = RES + "fight/portrait_player" + sfx + ".png"
		e["note"] = "Retrato 32x32 do jogador com a luva %s (Fase 5.3, B1). Mesmo recorte, fundo e virada do portrait_player; escolha pela luva equipada (by_data_id.player_portrait)." % sfx.trim_prefix("_")
		sp["portrait_player" + sfx] = e
	doc["sprites"] = sp
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["player_portrait"] = {"base": "portrait_player", "by_glove": {"glove_old": "portrait_player", "glove_l1": "portrait_player_glove_l1",
		"glove_l2": "portrait_player_glove_l2", "glove_l3": "portrait_player_glove_l3", "glove_l4": "portrait_player_glove_l4"},
		"rule": "Igual às folhas de luta: id = 'portrait_player' + sufixo da luva equipada ('' para a velha, '_glove_lN' para a LN). Vale para o topo da luta E para a prévia (inclusive a do dia). Se o id não existir, cair no portrait_player.",
		"frame": "ui_portrait_frame"}
	bd["campaign_calendar"] = {
		"hud": {"plate_rect": [7, 131, 116, 26], "page_pos": [11, 133], "page_number_rect": [2, 10, 15, 9], "text_x": 35, "line1_y": 136, "line2_y": 146,
			"risk_chip_pos": [35, 160], "page": "ui_calendar_page", "page_frame_normal": 0, "page_frame_fight_day": 1,
			"plate_by_risk": {"risk_easy": "ui_countdown_plate_easy", "risk_even": "ui_countdown_plate_even", "risk_hard": "ui_countdown_plate_hard"},
			"plate_fight_day": "ui_countdown_plate_today", "plate_done": "ui_countdown_plate_done", "page_done": "icon_campaign_complete",
			"colors": {"line1": "col_text_1", "line2": "col_text_2", "page_number": "d1", "today_line1": "y2", "done_lines": "col_money"},
			"note": "Coluna da esquerda, no lugar do 'PRÓXIMA:' de hoje (1x, base 640x360). Folhinha = DIA da campanha (número 1x em d1 no meio da área branca); linha 1 = 'Faltam X dias' (txt_body), linha 2 = nome do adversário (col_text_2), embaixo o selo de risco que já existe (ui_risk_* + icon_risk_*). Nada em txt_hero: é informação de nível 2."},
		"day_turn": {"fx": "fx_calendar_tear", "pos_rule": "pivô do fx no canto de cima à esquerda da folhinha", "fps": 12.0, "frames": [0, 1, 2, 3],
			"note": "Quando o dia vira: troca o número da folhinha e toca o fx por cima, uma vez (0,33 s). Sem som novo (fase 13)."},
		"warn_3d": {"sprite": "ui_warn_strip_3d", "icon": "icon_calendar", "rect": [214, 22, 212, 18], "icon_offset": [7, 3], "text_offset": [23, 5],
			"text_color": "col_text_1", "nine_slice_cap": 4,
			"note": "Faixa calma no topo da sala, centrada em x 320 (largura = conteúdo + 10 px; exemplo de 212 px). Entra descendo 18 px em 0,2 s, fica ~6 s e sobe. Não cobre lutador nem alvo."},
		"warn_1d": {"sprite": "ui_warn_strip_1d", "sprite_pulse": "ui_warn_strip_1d_hi", "pulse_fps": 2.0, "icon": "icon_calendar_alert",
			"rect": [196, 22, 248, 18], "icon_offset": [13, 3], "text_offset": [29, 5], "text_color": "y2", "nine_slice_cap": 10,
			"note": "Faixa urgente: mesmo lugar, alterna _1d/_1d_hi a 2 fps (sem alpha, sem tremer). Toca o som que já existe ao entrar. Pode ficar até a luta ou até o jogador clicar nela (UI/UX decide)."},
		"fight_day": {"badge": "ui_day_badge", "badge_offset_in_preview": [-10, -12], "badge_header_text_rect": [1, 5, 37, 7], "badge_number_rect": [5, 18, 29, 14],
			"badge_header_color": "white", "badge_number_color": "d1", "badge_number_size": "txt_hero",
			"fight_button": "fight_button (o LUTAR! de sempre)", "pass_button": "pass_post_button",
			"dim": "o mesmo pontilhado que já escurece a sala atrás da prévia",
			"note": "Prévia do dia: a folhinha grande fica presa (fita crepe) no canto de cima à esquerda da janela, por cima da borda; cabeçalho 'HOJE' 1x, número do dia em 2x dentro do círculo de caneta. Sem botão de voltar. O HUD atrás usa plate_fight_day e a folhinha no quadro 1 (dia circulado)."},
		"campaign_complete": {"hud_page": "icon_campaign_complete", "hud_plate": "ui_countdown_plate_done", "seal": "seal_campaign_complete",
			"note": "Depois do Kid: a folhinha vira a página dourada com estrela (sem número, o relógio some), 2 linhas 'CAMPANHA' / 'COMPLETA' em col_money. O selo 40x44 é para o fim de carreira/cartão (pode ampliar 2x inteiro)."},
		"_nota": "Fase 5.3 (Diretor de Arte), direcao-visual.md §20. Posições em 1x (base 640x360). Textos provisórios: quem fecha é o Roteirista; quem fecha o layout é o UI/UX pela alinhamento-ui."}
	bd["pass_post_button"] = {"normal": "ui_button_pass_normal", "hover": "ui_button_pass_hover", "pressed": "ui_button_pass_pressed",
		"disabled": "ui_button_pass_disabled", "icon": "icon_pass_post", "text_color": "p2", "text_color_disabled": "g1",
		"note": "PASSAR O POSTO na prévia do dia: botão de contorno (ação secundária, menos peso que o LUTAR! vermelho), mesmo 9-slice dos botões da Fase 2. Na sala, fora do dia, o botão roxo de sempre (retire_button) só troca o texto; sugestão: trocar também o ícone para icon_pass_post."}
	bd["_nota_fase53_arte"] = "Fase 5.3 (Diretor de Arte): campaign_calendar, pass_post_button, player_portrait (retrato por luva)."
	doc["by_data_id"] = bd
	var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()

# ================================================================ main
func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	FINAL = OS.get_cmdline_user_args().has("--final")
	var here: String = OS.get_environment("ART53_OUT")
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
	save_sheet("icon_calendar", "ui/icon_calendar.png", [icon_calendar(false)], 0, Vector2i.ZERO, {
		"note": "Ícone 11x11 de calendário de parede (argolas, cabeçalho vermelho, um dia marcado). Em linha com texto 1x: HUD, faixa de 3 dias, dicas."})
	save_sheet("icon_calendar_alert", "ui/icon_calendar_alert.png", [icon_calendar(true)], 0, Vector2i.ZERO, {
		"note": "Ícone 11x11 do calendário com '!' vermelho: faixa de 1 dia."})
	save_sheet("ui_calendar_page", "ui/ui_calendar_page.png", [calendar_page(false), calendar_page(true)], 0, Vector2i.ZERO, {
		"number_rect": [2, 10, 15, 9], "number_color": "d1",
		"note": "Folhinha 20x22 do HUD (dia da campanha). Quadro 0 normal, 1 dia circulado de caneta (dia da luta). Número 1x em d1 centrado em number_rect (até 2 dígitos). Folhas de baixo = 1 px de borda à direita e embaixo."})
	save_sheet("fx_calendar_tear", "ui/fx_calendar_tear.png", [tear_frame(0), tear_frame(1), tear_frame(2), tear_frame(3)], 12.0, Vector2i(6, 10), {
		"loop": false,
		"note": "Folha arrancada quando o dia vira (uma vez, 12 fps). Pôr o pivô (6,10) no canto de cima à esquerda da ui_calendar_page, por cima dela; o número novo já aparece embaixo."})
	var plates := {"easy": [["gr3", "gr2", "gr1"], "d1", "d2"], "even": [["y1", "y0", "br2"], "d1", "d2"], "hard": [["r3", "r2", "r1"], "d1", "d2"],
		"today": [["y2", "y1", "y0"], "r0", "r1"], "done": [["y2", "y1", "y0"], "d1", "d2"]}
	for k in plates:
		save_sheet("ui_countdown_plate_" + k, "ui/ui_countdown_plate_%s.png" % k, [plate(plates[k][0], plates[k][1], plates[k][2])], 0, Vector2i.ZERO, {
			"nine_slice": {"left": 4, "top": 2, "right": 2, "bottom": 2},
			"text_color": "y2" if k == "today" else ("y1" if k == "done" else "white"),
			"note": "Plaquinha 9-slice do 'Faltam X dias' no HUD (%s): fundo %s, faixa de 2 px à esquerda na cor %s. Tamanho de uso 116x26 (by_data_id.campaign_calendar.hud)." % [k, plates[k][1], plates[k][0][1]]})
	save_sheet("ui_warn_strip_3d", "ui/ui_warn_strip_3d.png", [warn_3d()], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 5, "top": 4, "right": 2, "bottom": 4}, "text_color": "white",
		"note": "Faixa de aviso de 3 dias (calma): painel d1 com filetes br2 e ponta âmbar à esquerda. 18 px de altura; ícone icon_calendar em (7,3), texto em (23,5)."})
	save_sheet("ui_warn_strip_1d", "ui/ui_warn_strip_1d.png", [warn_1d(false)], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 10, "top": 4, "right": 10, "bottom": 4}, "text_color": "y2",
		"note": "Faixa de aviso de 1 dia (urgente): vermelho r1, pontas com listras diagonais r0/r2 (fita de aviso vermelha, sem amarelo-e-preto), filetes dourados. Alterna com ui_warn_strip_1d_hi a 2 fps. Ícone icon_calendar_alert em (13,3), texto em (29,5)."})
	save_sheet("ui_warn_strip_1d_hi", "ui/ui_warn_strip_1d_hi.png", [warn_1d(true)], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 10, "top": 4, "right": 10, "bottom": 4}, "text_color": "y2",
		"note": "Quadro aceso da faixa de 1 dia (listras r1/r3, filete y2). Mesmo 9-slice da ui_warn_strip_1d."})
	save_sheet("ui_day_badge", "ui/ui_day_badge.png", [day_badge()], 0, Vector2i.ZERO, {
		"header_text_rect": [1, 5, 37, 7], "number_rect": [5, 18, 29, 14],
		"note": "Folhinha grande do dia da luta, presa com fita crepe na prévia do dia (offset (-10,-12) do canto de cima à esquerda da janela). Cabeçalho para 'HOJE' 1x branco; número do dia em txt_hero (2x) d1 dentro do círculo de caneta vermelha."})
	for st in ["normal", "hover", "pressed", "disabled"]:
		save_sheet("ui_button_pass_" + st, "ui/ui_button_pass_%s.png" % st, [button_pass(st)], 0, Vector2i.ZERO, {
			"nine_slice": {"left": 2, "top": 4 if st == "pressed" else 2, "right": 2, "bottom": 2 if st == "pressed" else 5},
			"text_color": "g1" if st == "disabled" else "p2",
			"note": "Botão PASSAR O POSTO da prévia do dia: contorno roxo (p1, p2 no hover) sobre d1, ação secundária ao lado do LUTAR! vermelho. Texto 1x p2 + icon_pass_post. Mesma base dos ui_button_* da Fase 2."})
	save_sheet("icon_pass_post", "ui/icon_pass_post.png", [icon_pass_post()], 0, Vector2i.ZERO, {
		"note": "Ícone 16x16 de PASSAR O POSTO: a luva velha passa (seta roxa) e vira Legado (estrela p2)."})
	save_sheet("icon_campaign_complete", "ui/icon_campaign_complete.png", [icon_campaign_complete()], 0, Vector2i.ZERO, {
		"note": "Folhinha dourada com estrela (20x22, mesmo lugar da ui_calendar_page): campanha completa, sem número."})
	save_sheet("seal_campaign_complete", "ui/seal_campaign_complete.png", [seal_campaign_complete()], 0, Vector2i.ZERO, {
		"note": "Selo 40x44 de CAMPANHA COMPLETA (Kid vencido): roseta dourada com estrela e duas fitas vermelhas. Fim de carreira/cartão; pode ampliar 2x inteiro."})
	make_mockup()
	if FINAL:
		write_manifest()
	print("ok fase 5.3 arte (%s): %d sprites" % ["PROJETO" if FINAL else "previa", M.size()])
	quit()
