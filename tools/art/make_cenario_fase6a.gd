extends SceneTree
## Fase 6a "Prólogo e voz" (Diretor de Arte) - PLACEHOLDER gerado por código. Cenário e interface.
## (Gente - Téo, Osmar, gesto - é do Artista de Personagens: tools/art/make_sprites_fase6a.gd.)
##   ui/ui_balloon (9-slice 16x16), ui_balloon_tail, _tail_l, _tail_r (7x6), ui_balloon_tag_<cor> (9-slice), ui_balloon_next
##   ui/ui_skip_chip, ui_skip_chip_active (9-slice), icon_key_esc, ui_skip_ring (9 quadros)    segurar ESC para pular a abertura
##   ui/seal_garage_saved (sem texto), seal_garage_saved_text, ui_seal_garage_band (9-slice), icon_garage_saved
##   ui/school_symbol_5/9/16/32 (lâmpada com raízes: Raízes Fight Club) + retoque da etiqueta dentro de box_big e box_small
##   garage/wall_notice_debt, wall_form_blank, wall_form_named, wall_photo_old, wall_clipping, wall_photo_team, wall_school_symbol
##   font/fightclicker_5x7(.png/.fnt) e _contorno: acentos das minúsculas descolados da letra, í sem bandeira, — e …
##   docs/arte/mockups/fase6a_garagem_x2.png
## Rodar de uma pasta temporária com project.godot vazio:
##   Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_cenario_fase6a.gd -- [--final]
## Sem --final grava em <tmp>/out (prévia). Com --final grava no projeto e mexe no manifest SÓ nas chaves desta
## fase (relê o arquivo na hora de gravar: o Artista de Personagens edita o mesmo arquivo em paralelo).

const ROOT := "E:/Fightclicker/"
const RES := "res://assets/sprites/"
var OUT := ""
var MOCK := ""
var FINAL := false
var L
var OLD := {}
var M := {}
var F := {}

# ---- posições na sala (base 640x360, canto de cima à esquerda do sprite; pivô 0,0)
# parede da memória (x 176..256, y 38..88): acima da prateleira, longe do metrônomo (231..249, y>=93)
const P_NOTICE := Vector2i(178, 52)      # aviso de cobrança (sai quando a garagem é salva)
const P_FORM := Vector2i(205, 62)        # ficha amassada (antes: escola nenhuma; depois: o nome escrito à mão)
const P_PHOTO_OLD := Vector2i(237, 67)   # cobre a foto pequena que já está pintada no garage_bg (239..252, 69..85)
const P_CLIPPING := Vector2i(236, 40)    # acima da foto antiga
const P_PHOTO_TEAM := Vector2i(176, 54)  # no lugar do aviso
const P_SYMBOL := Vector2i(344, 38)      # alto, à direita da corrente, longe da pera (408..464) e da porta (y>=97)
const P_COACH := Vector2i(196, 236)      # Osmar, encostado no carro (decisão do Produtor; Artista de Personagens regera ali)
const LIGHT_C := Vector2(305, 90)        # mesma luz do garage_bg (Fases 2, 5, 5.1)
const CLICK := Rect2i(312, 182, 48, 90)
const NO_COVER := Rect2i(310, 180, 52, 94)   # click_area + 2 px (balao-e-voz.md §3)
const ROOM := Rect2i(128, 18, 384, 272)
const USABLE := Rect2i(132, 22, 376, 264)    # x 132..507, y 22..285

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

## desenha um sprite pelo pivô
func put_pv(dst: Image, id: String, i: int, pos: Vector2i, off := Vector2i.ZERO) -> void:
	var e := spr(id)
	var pv := Vector2i(int(e.pivot[0]), int(e.pivot[1]))
	put(dst, id, i, pos.x - pv.x - off.x, pos.y - pv.y - off.y)

func scaled(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func ol(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

func garage_lit(img: Image, topleft: Vector2i, min_step := -2) -> Image:
	var c: Image = img.duplicate()
	L.light(c, Rect2i(0, 0, c.get_width(), c.get_height()), LIGHT_C - Vector2(topleft), 300.0, 1.1, 3.6, min_step, 1, 0.9)
	return c

## 9-slice desenhado por código (para os mockups), centro esticado em bloco
func nine(dst: Image, id: String, x: int, y: int, w: int, h: int, frame := 0) -> void:
	var e := spr(id)
	var ns: Dictionary = e.nine_slice
	var src := frame_of(id, frame)
	var sw := src.get_width()
	var sh := src.get_height()
	var l: int = int(ns.left)
	var t: int = int(ns.top)
	var r: int = int(ns.right)
	var b: int = int(ns.bottom)
	var cols := [[0, l, x, l], [l, sw - l - r, x + l, w - l - r], [sw - r, r, x + w - r, r]]
	var rows := [[0, t, y, t], [t, sh - t - b, y + t, h - t - b], [sh - b, b, y + h - b, b]]
	for rr in rows:
		for cc in cols:
			if cc[3] <= 0 or rr[3] <= 0:
				continue
			var piece := src.get_region(Rect2i(cc[0], rr[0], cc[1], rr[1]))
			piece.resize(cc[3], rr[3], Image.INTERPOLATE_NEAREST)
			blend(dst, piece, cc[2], rr[2])

func hsh(x: int, y: int, s := 0) -> int:
	var v := (x * 73856093) ^ (y * 19349663) ^ (s * 83492791)
	return absi(v) % 100

func T(img: Image, s: String, x: int, y: int, c, shadow = null) -> int:
	return L.text(img, s, x, y, c, 1, shadow)

# ================================================================ símbolo da escola: a lâmpada com raízes
## Raízes Fight Club: a única lâmpada da garagem, de pé, com o soquete virando raiz. Bulbo (a) com brilho (b).
## Na UI fica em tinta de carimbo azul (b1/b2), como o provisório (vai em papel: etiqueta da caixa, selo).
const SYM5 := [".aaa.", ".aaa.", "..a..", "rrrrr", "r.r.r"]
const SYM9 := [
	"..aaaaa..",
	".abaaaaa.",
	".abaaaaa.",
	"..aaaaa..",
	"...a.a...",
	"...aaa...",
	"rrrrrrrrr",
	"..r.r.r..",
	".r..r..r."]
const SYM16 := [
	".....aaaaaa.....",
	"....aaaaaaaa....",
	"...aabbaaaaaa...",
	"...abaaaaaaaa...",
	"...abaaaaaaaa...",
	"...aaaaaaaaaa...",
	"....aaaaaaaa....",
	".....aaaaaa.....",
	"......aaaa......",
	"......a..a......",
	"......aaaa......",
	".rrrrrrrrrrrrrr.",
	"......r..r......",
	".....r.rr.r.....",
	"...rr..rr..rr...",
	"..r...r..r...r.."]

func school_symbol(size: int, c = "b1", c2 = "b2") -> Image:
	var s: Image
	if size <= 5:
		s = L.blank(5, 5); pmap(s, 0, 0, SYM5, {"a": c, "b": c2, "r": c})
	elif size <= 9:
		s = L.blank(9, 9); pmap(s, 0, 0, SYM9, {"a": c, "b": c2, "r": c})
	else:
		var b: Image = L.blank(16, 16)
		pmap(b, 0, 0, SYM16, {"a": c, "b": c2, "r": c})
		s = scaled(b, size / 16) if size >= 32 else b
	return s

# símbolos antigos (frontão), para achar e trocar dentro da etiqueta das caixas
const OLD5 := ["..a..", ".aaa.", "a...a", "abbba", "aaaaa"]
const OLD9 := ["....a....", "...aaa...", "..aa.aa..", ".aa...aa.", "aa.....aa", "a.bbbbb.a", "a.......a", "a.bbbbb.a", "aaaaaaaaa"]

func patch_box(id: String) -> void:
	var e := spr(id)
	var n: int = int(e.frames)
	var frames := []
	var hits := 0
	var cb1: Color = L.col("b1")
	var cb2: Color = L.col("b2")
	var cw: Color = L.col("white")
	for i in n:
		var fr := frame_of(id, i).duplicate()
		for pat in [[OLD9, SYM9], [OLD5, SYM5]]:
			var old: Array = pat[0]
			var w: int = old[0].length()
			var h: int = old.size()
			for y in fr.get_height() - h + 1:
				for x in fr.get_width() - w + 1:
					if _match(fr, x, y, old):
						# apaga só o que era tinta azul (a fita por cima continua) e pinta o novo só sobre o papel
						for yy in h:
							for xx in w:
								var c: Color = fr.get_pixel(x + xx, y + yy)
								if c.is_equal_approx(cb1) or c.is_equal_approx(cb2):
									fr.set_pixel(x + xx, y + yy, cw)
						var nw: Array = pat[1]
						for yy in nw.size():
							for xx in nw[yy].length():
								var ch: String = nw[yy][xx]
								if ch != "." and fr.get_pixel(x + xx, y + yy).is_equal_approx(cw):
									fr.set_pixel(x + xx, y + yy, cb2 if ch == "b" else cb1)
						hits += 1
		frames.append(fr)
	var keep := {}
	for k in e:
		if not (k in ["file", "frame_size", "frames", "fps", "pivot"]):
			keep[k] = e[k]
	keep["note"] = str(e.get("note", "")).split(" Fase 6a:")[0] + " Fase 6a: a etiqueta mostra o símbolo da escola (lâmpada com raízes, school_symbol_9/5)."
	var rel: String = str(e.file).replace(RES, "")
	save_sheet(id, rel, frames, float(e.fps), Vector2i(int(e.pivot[0]), int(e.pivot[1])), keep)
	print("  %s: %d símbolos trocados em %d quadros" % [id, hits, n])

## acha o símbolo antigo: as células de tinta batem (até 2 cobertas pela fita) e as vazias não são tinta
func _match(img: Image, x: int, y: int, pat: Array) -> bool:
	var a: Color = L.col("b1")
	var b: Color = L.col("b2")
	var miss := 0
	for j in pat.size():
		var r: String = pat[j]
		for i in r.length():
			var c := img.get_pixel(x + i, y + j)
			match r[i]:
				"a":
					if not c.is_equal_approx(a): miss += 1
				"b":
					if not c.is_equal_approx(b): miss += 1
				_:
					if c.is_equal_approx(a) or c.is_equal_approx(b) or c.a == 0.0: return false
	return miss <= 2

# ================================================================ balão de fala (balao-e-voz.md §1)
## Corpo 9-slice 16x16, cantos de 5: fundo cream, contorno ink com canto arredondado de 2 px, sombra dura d1 de 1 px
## embaixo e à direita (dentro do retângulo: o balão w x h já inclui a sombra).
func balloon_body() -> Image:
	var img: Image = L.blank(16, 16)
	var rows := []
	for y in 15:
		var r := ""
		for x in 15:
			var edge := x == 0 or y == 0 or x == 14 or y == 14
			var corner := (x < 2 and y < 2) or (x > 12 and y < 2) or (x < 2 and y > 12) or (x > 12 and y > 12)
			var cut := (x == 0 and y == 0) or (x == 0 and y == 1) or (x == 1 and y == 0) or (x == 14 and y == 0) or (x == 14 and y == 1) or (x == 13 and y == 0) or (x == 0 and y == 14) or (x == 0 and y == 13) or (x == 1 and y == 14) or (x == 14 and y == 14) or (x == 14 and y == 13) or (x == 13 and y == 14)
			if cut:
				r += "."
			elif edge or (corner and (x == 1 or x == 13) and (y == 1 or y == 13)):
				r += "#"
			else:
				r += "c"
		rows.append(r)
	pmap(img, 0, 0, rows, {"#": "ink", "c": "cream"})
	# sombra dura: 1 px embaixo e à direita, seguindo o canto
	for y in 16:
		for x in 16:
			if img.get_pixel(x, y).a == 0.0 and x >= 1 and y >= 1 and img.get_pixel(x - 1, y - 1).a > 0.0:
				L.P(img, x, y, "d1")
	return img

## Rabicho 7x6. A linha 0 cai na linha de contorno de baixo do corpo (y = by + h - 2) e é cream: apaga o contorno.
## c = reto (ponta em x 3); l = ponta à esquerda (x 0); r = ponta à direita (x 6). Sombra d1 à direita da borda.
func balloon_tail(kind: String) -> Image:
	var rows: Array
	if kind == "c":
		rows = ["#ccccc#", ".#ccc#.", ".#ccc#.", "..#c#..", "..#c#..", "...#..."]
	else:
		rows = ["#ccccc#", "#ccc##.", "#cc#...", "#c#....", "##.....", "#......"]
	var img: Image = L.blank(7, 6)
	pmap(img, 0, 0, rows, {"#": "ink", "c": "cream"})
	if kind == "r":
		img.flip_x()
	for y in range(1, 6):
		var last := -1
		for x in 7:
			if img.get_pixel(x, y).a > 0.0:
				last = x
		if last >= 0 and last < 6:
			L.P(img, last + 1, y, "d1")
	return img

## Plaquinha do nome (9-slice 8x10, cantos de 2): cor do personagem, filete claro em cima, contorno ink.
## 10 px e não 9: com 9 o acento da minúscula (é de téo) caía em cima do contorno.
func balloon_tag(c: String) -> Image:
	var img: Image = L.blank(8, 10)
	L.R(img, 1, 0, 6, 10, "ink"); L.R(img, 0, 1, 8, 8, "ink")
	L.R(img, 1, 1, 6, 8, c)
	L.R(img, 2, 1, 4, 1, L.shade(L.col(c), 1))
	return img

func balloon_next(on: bool) -> Image:
	var img: Image = L.blank(5, 4)
	if on:
		pmap(img, 0, 0, ["#####", "#####", ".###.", "..#.."], {"#": "ink"})
		L.R(img, 1, 0, 3, 1, "d2")
	return img

# ================================================================ segurar ESC
func skip_chip(active: bool) -> Image:
	var img: Image = L.blank(12, 16)
	var edge := "y0" if active else "g0"
	L.R(img, 1, 0, 10, 16, "ink"); L.R(img, 0, 1, 12, 14, "ink")
	L.R(img, 1, 1, 10, 14, edge)
	L.R(img, 2, 2, 8, 12, "d1")
	L.R(img, 2, 2, 8, 1, "d2")
	return img

func key_esc() -> Image:
	var img: Image = L.blank(21, 12)
	L.R(img, 1, 0, 19, 12, "ink"); L.R(img, 0, 1, 21, 10, "ink")
	L.R(img, 1, 1, 19, 8, "cream")
	L.R(img, 1, 1, 19, 1, "white")
	L.R(img, 1, 9, 19, 2, "g2"); L.R(img, 1, 10, 19, 1, "g1")
	L.text(img, "ESC", 2, 2, "d1")
	return img

func skip_ring(step: int, total: int) -> Image:
	var img: Image = L.blank(11, 11)
	var cx := 5.0
	var cy := 5.0
	for y in 11:
		for x in 11:
			var dx := x + 0.5 - 5.5
			var dy := y + 0.5 - 5.5
			var d := sqrt(dx * dx + dy * dy)
			if d <= 5.5 and d >= 3.2:
				var ang := fposmod(atan2(dx, -dy), TAU) / TAU   # 0 em cima, horário
				var filled := ang < float(step) / float(total) - 0.0001
				L.P(img, x, y, "y1" if filled else "g0")
			elif d < 5.5 + 0.9 and d > 5.5:
				pass
	# contorno ink de fora e de dentro
	var o := ol(img)
	if step >= total:
		L.R(o, 5, 5, 1, 1, "y2")
	return o

# ================================================================ selo "garagem salva"
## O aviso de cobrança, despregado da parede, com o carimbo da escola (a lâmpada) por cima. A conquista é da escola.
func notice_paper(w: int, h: int, big: bool) -> Image:
	var img: Image = L.blank(w, h)
	L.R(img, 0, 0, w, h, "ink")
	L.R(img, 1, 1, w - 2, h - 2, "cream")
	L.R(img, 1, 1, w - 2, 1, "white")
	# cabeçalho vermelho com "texto" ilegível
	var hh: int = 7 if big else 5
	L.R(img, 2, 2, w - 4, hh, "r1")
	L.R(img, 2, 2, w - 4, 1, "r2")
	if big:
		L.R(img, 4, 4, w / 2 - 2, 2, "white"); L.R(img, w / 2 + 4, 4, w / 2 - 10, 2, "r3")
	else:
		L.R(img, 3, 4, w - 8, 1, "white")
	# linhas de texto
	var y := hh + 4
	var i := 0
	while y < h - 4:
		var ln: int = (w - 6) - ((i * 7) % 9)
		L.R(img, 3, y, ln, 1, "g2")
		y += 2 if big else 3
		i += 1
	# canto de baixo à direita dobrado
	L.P(img, w - 2, h - 2, "g3"); L.P(img, w - 3, h - 2, "g3"); L.P(img, w - 2, h - 3, "g3")
	L.P(img, w - 1, h - 1, Color(0, 0, 0, 0)); L.P(img, w - 2, h - 1, "ink"); L.P(img, w - 1, h - 2, "ink")
	return img

func stamp_ring(img: Image, cx: float, cy: float, r: float, seed: int) -> void:
	var tmp: Image = L.blank(img.get_width(), img.get_height())
	L.ring(tmp, cx, cy, r, r, 2.0, "b1")
	L.ring(tmp, cx, cy, r - 3.0, r - 3.0, 1.0, "b1")
	var sym := school_symbol(16, "b1", "b2")
	# o brilho do bulbo vira papel aparecendo
	for y in 16:
		for x in 16:
			if sym.get_pixel(x, y).is_equal_approx(L.col("b2")) and y > 5:
				sym.set_pixel(x, y, Color(0, 0, 0, 0))
	blend(tmp, sym, int(cx) - 8, int(cy) - 8)
	# falhas de tinta (carimbo de borracha)
	for y in tmp.get_height():
		for x in tmp.get_width():
			var c := tmp.get_pixel(x, y)
			if c.a > 0.0:
				var hv := hsh(x, y, seed)
				if hv < 10:
					continue
				if hv < 24:
					c = L.col("b2")
				img.set_pixel(x, y, c)

func tape(img: Image, x: int, y: int, w: int, h: int) -> void:
	L.R(img, x, y, w, h, "cream")
	L.R(img, x, y + h - 1, w, 1, "g3")
	L.P(img, x, y, "g3"); L.P(img, x + w - 1, y + h - 1, "g2")

func seal_garage(with_band: bool, text := "") -> Image:
	var W := 96 if with_band else 52
	var H := 64 if with_band else 54
	var img: Image = L.blank(W, H)
	var px: int = (W - 48) / 2
	var paper := notice_paper(48, 50, true)
	blend(img, paper, px, 1)
	L.R(img, px + 1, 51, 47, 1, "ink")     # sombra
	tape(img, px - 2, 0, 8, 4)
	tape(img, px + 42, 0, 8, 4)
	stamp_ring(img, px + 25.5, 31.5, 15.0, 7)
	if with_band:
		band(img, 2, 46, W - 4, 15)
		if text != "":
			L.text_center(img, text, W / 2, 50, "d1")
	return img

## Fita dourada com pontas em V (9-slice: pontas de 8 px)
func band(img: Image, x: int, y: int, w: int, h: int) -> void:
	for yy in h:
		var notch := absi(yy - h / 2)          # V nas pontas
		var inset: int = 4 - mini(notch, 4)
		for xx in range(inset, w - inset):
			var c := "y1"
			if yy == 0 or yy == h - 1 or xx == inset or xx == w - inset - 1:
				c = "ink"
			elif yy == 1:
				c = "y2"
			elif yy >= h - 3:
				c = "y0"
			L.P(img, x + xx, y + yy, c)
	# dobra da fita atrás das pontas
	L.R(img, x + 7, y + 1, 1, h - 2, "br3"); L.R(img, x + w - 8, y + 1, 1, h - 2, "br3")

func band_tex() -> Image:
	var img: Image = L.blank(24, 15)
	band(img, 0, 0, 24, 15)
	return img

func icon_garage_saved() -> Image:
	var img: Image = L.blank(16, 16)
	var p := notice_paper(11, 14, false)
	blend(img, p, 1, 1)
	# carimbo redondo pequeno com a lâmpada de 5 px
	L.ring(img, 10.5, 10.5, 5.0, 5.0, 1.0, "b1")
	L.ellipse(img, 10.5, 10.5, 4.0, 4.0, "cream")
	pmap(img, 8, 8, SYM5, {"a": "b1", "b": "b2", "r": "b1"})
	return img

# ================================================================ objetos do Arco 1 (parede da garagem)
## Aviso de cobrança: folha branca com borda e cabeçalho vermelhos, "texto" ilegível, valor circulado, fita crepe.
func wall_notice() -> Image:
	var img: Image = L.blank(22, 28)
	L.R(img, 1, 2, 20, 25, "ink")
	L.R(img, 2, 3, 18, 23, "white")
	L.R(img, 2, 3, 18, 1, "r2"); L.R(img, 2, 25, 18, 1, "r2"); L.R(img, 2, 3, 1, 23, "r2"); L.R(img, 19, 3, 1, 23, "r2")
	L.R(img, 4, 5, 14, 5, "r1"); L.R(img, 4, 5, 14, 1, "r2")
	L.R(img, 5, 7, 6, 1, "white"); L.R(img, 12, 7, 4, 1, "r3")
	for i in 4:
		L.R(img, 4, 12 + i * 2, 14 - (i * 3) % 5, 1, "g2")
	# valor devido circulado de vermelho
	L.R(img, 9, 21, 7, 1, "d2")
	L.ring(img, 12.5, 21.5, 5.0, 2.5, 1.0, "r2")
	L.R(img, 4, 21, 3, 1, "g2")
	# canto de baixo descolando
	L.P(img, 19, 25, "cream"); L.P(img, 18, 25, "g3"); L.P(img, 19, 24, "g3"); L.P(img, 20, 26, Color(0, 0, 0, 0)); L.P(img, 20, 25, Color(0, 0, 0, 0))
	L.P(img, 19, 26, "ink"); L.P(img, 20, 24, "ink")
	# fita crepe nos cantos de cima
	tape(img, 0, 0, 6, 4)
	tape(img, 16, 0, 6, 4)
	return garage_lit(img, P_NOTICE)

## Foto antiga: o treinador jovem, de luva e cinturão, em sépia; moldura de madeira, TORTA (como ficava na garagem).
func wall_photo_old() -> Image:
	var w := 18
	var h := 21
	var flat: Image = L.blank(w, h - 1)
	L.R(flat, 0, 0, w, h - 1, "ink")
	L.R(flat, 1, 1, w - 2, h - 3, "br1")
	L.R(flat, 1, 1, w - 2, 1, "br2"); L.R(flat, 1, 1, 1, h - 3, "br2")
	L.R(flat, 3, 3, w - 6, h - 7, "cream")              # passe-partout
	L.R(flat, 4, 4, w - 8, h - 9, "y2")                  # foto sépia clara
	L.R(flat, 4, 12, w - 8, 3, "br3")                    # chão
	# o treinador jovem: braços para cima, cinturão dourado
	pmap(flat, 5, 4, [
		".#....#.",
		".#.##.#.",
		"..####..",
		"...##...",
		"..####..",
		"..#yy#..",
		"..#..#..",
		"..#..#.."], {"#": "br1", "y": "y0"})
	L.P(flat, 5, 4, "br2"); L.P(flat, 10, 4, "br2")       # luvas
	L.R(flat, 4, 4, 1, h - 9, "y1")                      # foto desbotada na borda
	# torto: a metade direita desce 1 px
	var img: Image = L.blank(w, h)
	blend(img, flat.get_region(Rect2i(0, 0, w / 2, h - 1)), 0, 0)
	blend(img, flat.get_region(Rect2i(w / 2, 0, w / 2, h - 1)), w / 2, 1)
	L.P(img, w / 2 - 1, 0, "ink")
	# prego e barbante
	L.P(img, w / 2, 0, "g3")
	return garage_lit(img, P_PHOTO_OLD)

## Recorte de jornal: papel de jornal (g3/cream), manchete, foto da luta, colunas; bordas picotadas; uma fita.
func wall_clipping() -> Image:
	var img: Image = L.blank(20, 24)
	L.R(img, 1, 2, 18, 21, "ink")
	L.R(img, 2, 3, 16, 19, "g3")
	L.R(img, 2, 3, 16, 1, "cream")
	L.R(img, 3, 5, 14, 2, "d1")                         # manchete
	L.R(img, 3, 8, 7, 7, "g1")                          # foto
	pmap(img, 4, 9, ["..#..", ".###.", "#.#.#", "..#..", ".#.#."], {"#": "d1"})
	L.R(img, 3, 8, 7, 1, "g2")
	for i in 4:
		L.R(img, 11, 8 + i * 2, 6, 1, "g1")
	for i in 3:
		L.R(img, 3, 16 + i * 2, 14 - (i * 4) % 6, 1, "g1")
	# borda picotada (pixels comidos)
	for x in range(1, 19):
		if hsh(x, 0, 3) < 35:
			L.P(img, x, 2, Color(0, 0, 0, 0)); L.P(img, x, 3, "ink")
		if hsh(x, 1, 3) < 35:
			L.P(img, x, 22, Color(0, 0, 0, 0)); L.P(img, x, 21, "ink")
	tape(img, 7, 0, 6, 4)
	return garage_lit(img, P_CLIPPING)

## Foto da equipe: moldura preta nova, 5 pessoas e o cinturão no meio, a lâmpada no alto da foto.
func wall_photo_team() -> Image:
	var w := 26
	var h := 21
	var img: Image = L.blank(w, h)
	L.R(img, 0, 0, w, h - 1, "ink")
	L.R(img, 1, 1, w - 2, h - 3, "st0")
	L.R(img, 1, 1, w - 2, 1, "st1")
	L.R(img, 3, 3, w - 6, h - 7, "g1")                   # parede da garagem na foto
	L.R(img, 3, 12, w - 6, 2, "g0")                      # chão
	L.P(img, 12, 3, "g3"); L.P(img, 12, 4, "y1"); L.P(img, 13, 4, "y2")   # a lâmpada na foto
	var skins := ["sk2", "sk1", "sk0", "sk2", "sk1"]
	var shirts := ["gr2", "b2", "r2", "cream", "st2"]
	for i in 5:
		var x: int = 4 + i * 4
		var tall: int = 1 if i == 2 else 0
		L.R(img, x, 6 - tall, 2, 2, skins[i])            # cabeça
		L.R(img, x - 1 + (1 if i == 4 else 0), 8 - tall, 3, 5 + tall, shirts[i])     # corpo
	L.R(img, 11, 9, 5, 2, "y1"); L.P(img, 13, 9, "y2")   # o cinturão erguido
	L.R(img, 11, 9, 1, 2, "r1"); L.R(img, 15, 9, 1, 2, "r1")
	L.R(img, 1, h - 3, w - 2, 1, "d1")
	L.R(img, 1, h - 1, w - 1, 1, Color(0, 0, 0, 0))
	return garage_lit(img, P_PHOTO_TEAM)

## Símbolo pintado na parede: o SYM16 em 2x, tinta amarela que segue a textura do bloco (rejunte mais escuro) e 2 escorridos.
func wall_symbol() -> Image:
	var bg := frame_of("garage_bg").get_region(Rect2i(P_SYMBOL.x - 128, P_SYMBOL.y - 18, 32, 40))
	var mask: Image = L.blank(16, 16)
	pmap(mask, 0, 0, SYM16, {"a": "y1", "b": "white", "r": "br3"})
	var img: Image = L.blank(32, 40)
	for y in 32:
		for x in 32:
			var m := mask.get_pixel(x / 2, y / 2)
			if m.a == 0.0:
				continue
			var under := bg.get_pixel(x, y)
			var lum := under.r * 0.3 + under.g * 0.59 + under.b * 0.11
			var c := "y1"
			var root := m.is_equal_approx(L.col("br3"))
			if m.is_equal_approx(L.col("white")):
				c = "y2"                        # brilho do bulbo
			elif root:
				c = "br2" if lum < 0.28 else "br3"   # raízes em tinta marrom
			elif lum < 0.28:
				c = "y0"                        # rejunte: a tinta afunda
			if hsh(x, y, 11) < 6:
				c = "br3"                       # falha da tinta
			L.P(img, x, y, c)
	# escorridos
	for d in [[13, 18, 3], [21, 18, 2], [5, 32, 4], [27, 32, 3]]:
		for k in d[2]:
			L.P(img, d[0], d[1] + k, ("y0" if d[1] < 24 else "br2") if k < d[2] - 1 else "br1")
	return garage_lit(img, P_SYMBOL, -1)

## Ficha de inscrição amassada, presa num prego. Sem texto legível (o texto vai na dica: ESCOLA: NENHUMA / ESCOLA: RAÍZES FIGHT CLUB).
## Antes: o campo ESCOLA com um rabisco curto a lápis ("nenhuma", letra do fiscal). Depois: o rabisco riscado de vermelho
## e o nome escrito à mão por cima, em caneta azul, grande e torto, passando da linha.
func wall_form(named: bool) -> Image:
	var img: Image = L.blank(22, 24)
	# papel com bordas amassadas
	L.R(img, 1, 1, 20, 22, "ink")
	L.R(img, 2, 2, 18, 20, "white")
	for p in [[1, 1], [20, 1], [1, 22], [20, 22], [1, 9], [20, 14], [8, 22], [14, 1]]:
		L.P(img, p[0], p[1], Color(0, 0, 0, 0))
	L.P(img, 2, 9, "ink"); L.P(img, 19, 14, "ink"); L.P(img, 8, 21, "ink"); L.P(img, 14, 2, "ink")
	# vincos do amassado (diagonais em g3/cream)
	L.line(img, 3, 6, 9, 3, "cream"); L.line(img, 10, 20, 18, 12, "g3"); L.line(img, 4, 16, 8, 19, "cream")
	L.line(img, 12, 4, 18, 9, "g3")
	# cabeçalho e campos
	L.R(img, 4, 4, 9, 1, "d2"); L.R(img, 4, 5, 6, 1, "g2")
	for i in 3:
		L.R(img, 4, 8 + i * 3, 3, 1, "g1"); L.R(img, 8, 8 + i * 3, 10, 1, "g3")
	# campo ESCOLA (o último, mais embaixo)
	L.R(img, 4, 18, 4, 1, "d2"); L.R(img, 9, 18, 9, 1, "g2")
	pmap(img, 9, 16, ["#.#.##.#", ".#.#..#."], {"#": "g1"})            # "nenhuma" a lápis
	if named:
		L.line(img, 8, 17, 17, 16, "r2")                                    # riscado
		pmap(img, 3, 12, ["..##...#..##.#..##.", ".#..#.#.##..#.##..#", "#....#.....#.....#."], {"#": "b1"})
		L.R(img, 4, 19, 15, 1, "b2")                                         # sublinhado com força
	# prego
	L.P(img, 11, 0, "g3"); L.P(img, 11, 1, "ink")
	return garage_lit(img, P_FORM)

# ================================================================ fonte (só regrava os 2 BMFont; mesmo atlas e mesma ordem)
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
	print("  fonte: %d caracteres" % chars.size())

func _glyph_draw(img: Image, rows_d: Dictionary, x: int, y: int, c) -> void:
	for row in rows_d:
		var s: String = rows_d[row]
		for j in s.length():
			if s[j] == "#":
				L.P(img, x + j, y + int(row) + 2, c)

# ================================================================ balão montado (regra de balao-e-voz.md §2-3, para mockup e UI)
const BUBBLE_MAX_W := 172
const TAG_COL := {"red": "r2", "gold": "y0", "blue": "b3", "green": "gr2", "purple": "p2", "gray": "g2"}
const TAG_TEXT := {"red": "white", "gold": "ink", "blue": "ink", "green": "ink", "purple": "ink", "gray": "ink"}

## head = ponto da cabeça (head_anchor). Devolve o retângulo w x h (com sombra), o rabicho e a plaquinha.
func bubble_layout(lines: Array, head: Vector2i, name := "", avoid: Array = []) -> Dictionary:
	var n := 0
	for l in lines:
		n = maxi(n, l.length())
	var w: int = clampi(n * 6 + 16, 40, BUBBLE_MAX_W)
	var h: int = 17 if lines.size() == 1 else 26
	var tag_h := 10 if name != "" else 0
	var by: int = head.y - 6 - 3 - h          # ponta do rabicho (by + h + 3) 6 px acima da cabeça
	var bx: int = head.x - w / 2
	var mode := "em_cima"
	bx = clampi(bx, USABLE.position.x, USABLE.end.x - w)
	var r := Rect2i(bx, by - (6 if tag_h > 0 else 0), w, h + 4 + (6 if tag_h > 0 else 0))
	if r.intersects(NO_COVER):
		var bx2: int = (NO_COVER.position.x - 2 - w) if head.x < 336 else (NO_COVER.end.x + 2)
		bx2 = clampi(bx2, USABLE.position.x, USABLE.end.x - w)
		var tx2: int = clampi(head.x, bx2 + 8, bx2 + w - 8)
		var hits_other := false
		for p in avoid:
			if Rect2i(bx2, r.position.y, w, r.size.y).has_point(p):
				hits_other = true
		if absi(tx2 - head.x) <= 6 and not hits_other and not Rect2i(bx2, r.position.y, w, r.size.y).intersects(NO_COVER):
			bx = bx2; mode = "desliza"
		else:
			by = mini(by, NO_COVER.position.y - 2 - 3 - h); mode = "sobe"
	by = maxi(by, USABLE.position.y + (6 if tag_h > 0 else 0))
	var tip_x: int = clampi(head.x, bx + 8, bx + w - 8)
	var kind := "c"
	var tx: int = tip_x - 3
	if tip_x - bx < 14:
		kind = "l"; tx = tip_x
	elif bx + w - tip_x < 15:
		kind = "r"; tx = tip_x - 6
	return {"x": bx, "y": by, "w": w, "h": h, "tail": kind, "tail_x": tx, "tail_y": by + h - 2, "tip": [tip_x, by + h + 3], "mode": mode}

func draw_bubble(img: Image, lines: Array, head: Vector2i, name: String, tcol: String, avoid: Array = []) -> Dictionary:
	var b := bubble_layout(lines, head, name, avoid)
	nine(img, "ui_balloon", b.x, b.y, b.w, b.h)
	put(img, "ui_balloon_tail" + ("" if b.tail == "c" else "_" + b.tail), 0, b.tail_x, b.tail_y)
	var n := 0
	for l in lines:
		n = maxi(n, l.length())
	var tx: int = b.x + (b.w - (n * 6 - 1)) / 2
	for i in lines.size():
		L.text(img, lines[i], tx, b.y + 5 + i * 9, "ink")
	if name != "":
		var pw: int = name.length() * 6 + 6
		nine(img, "ui_balloon_tag_" + tcol, b.x + 6, b.y - 6, pw, 10)
		L.text(img, name, b.x + 6 + 3, b.y - 6 + 2, TAG_TEXT[tcol])
	return b

# ================================================================ mockup
func head_of(id: String, pos: Vector2i, frame := 0, flip := false) -> Vector2i:
	var e := spr(id)
	var fr := frame_of(id, frame)
	var pv := Vector2i(int(e.pivot[0]), int(e.pivot[1]))
	for y in fr.get_height():
		var xs := []
		for x in fr.get_width():
			if fr.get_pixel(x, y).a > 0.0:
				xs.append(x)
		if xs.size() > 0:
			var cx: int = (xs[0] + xs[xs.size() - 1]) / 2
			if flip:
				cx = fr.get_width() - 1 - cx
				pv.x = fr.get_width() - 1 - pv.x
			return Vector2i(pos.x + cx - pv.x, pos.y + y - pv.y)
	return pos

func silhouette(id: String, frame: int, flip: bool) -> Image:
	var fr := frame_of(id, frame).duplicate()
	if flip:
		fr.flip_x()
	var out: Image = L.blank(fr.get_width(), fr.get_height())
	for y in fr.get_height():
		for x in fr.get_width():
			var c: Color = fr.get_pixel(x, y)
			if c.a > 0.0:
				out.set_pixel(x, y, L.col("ink") if c.is_equal_approx(L.col("ink")) else (L.col("g1") if (x + y) % 2 == 0 else L.col("d2")))
	return out

func room(saved: bool, show_marks: bool, crew: bool) -> Image:
	var img: Image = L.blank(640, 360)
	img.fill(L.col("ink"))
	put(img, "garage_bg", 0, 128, 18)
	if show_marks:
		for m in [["tape_mark_rope", Vector2i(296, 166)], ["ghost_rope", Vector2i(296, 166)], ["tape_mark_speed_bag_dim", Vector2i(436, 46)],
				["ghost_speed_bag_dim", Vector2i(436, 46)], ["tape_mark_treadmill", Vector2i(445, 267)], ["ghost_treadmill", Vector2i(445, 267)]]:
			put_pv(img, m[0], 0, m[1])
	else:
		put_pv(img, "rope_l0_idle", 0, Vector2i(296, 166))
	# parede da memória (Arco 1)
	put(img, "wall_photo_old", 0, P_PHOTO_OLD.x, P_PHOTO_OLD.y)
	if saved:
		put(img, "wall_clipping", 0, P_CLIPPING.x, P_CLIPPING.y)
		put(img, "wall_photo_team", 0, P_PHOTO_TEAM.x, P_PHOTO_TEAM.y)
		put(img, "wall_form_named", 0, P_FORM.x, P_FORM.y)
		put(img, "wall_school_symbol", 0, P_SYMBOL.x, P_SYMBOL.y)
	else:
		put(img, "wall_notice_debt", 0, P_NOTICE.x, P_NOTICE.y)
		put(img, "wall_form_blank", 0, P_FORM.x, P_FORM.y)
	put(img, "metronome_l1", 0, 240 - 9, 118 - 25)
	put_pv(img, "lamp", 0, Vector2i(300, 32))
	for y in range(33, 183, 4):
		put(img, "bag_chain_tile", 0, 335, y)
	if crew:
		put_pv(img, "treadmill_l0_side", 0, Vector2i(445, 267))
	# gente por ordem de y dos pés
	var people := []
	people.append(["coach", P_COACH])
	people.append(["fighter_idle", Vector2i(303, 272)])
	if crew:
		for id in ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2", "coach_1"]:
			var e := spr(id)
			people.append([id, Vector2i(int(e.pos[0]), int(e.pos[1]))])
	people.append(["bag", Vector2i(336, 183 + 70)])
	people.sort_custom(func(p, q): return p[1].y < q[1].y)
	for p in people:
		if p[0] == "bag":
			put_pv(img, "bag_l0_idle", 0, Vector2i(336, 183))
		elif p[0] == "coach":
			put(img, "floor_shadow", 0, P_COACH.x - 12, P_COACH.y - 3)
			if spr(COACH_SHEET).is_empty():
				blend(img, coach_img(), P_COACH.x - (48 - 1 - 25), P_COACH.y - 67)   # placeholder se o Osmar ainda não existe
			else:
				put_pv(img, COACH_SHEET, 0, P_COACH)
		else:
			put_pv(img, p[0], 0, p[1])
	return img

var _coach: Image
var CHECKED := {}
var COACH_SHEET := "coach_look"
func coach_img() -> Image:
	if _coach == null:
		_coach = silhouette("uncle_1", 0, true)
	return _coach

func dashed(img: Image, r: Rect2i, ox: int, oy: int, c: String) -> void:
	for x in range(r.position.x, r.end.x):
		for y in [r.position.y, r.end.y - 1]:
			if x % 2 == 0: L.P(img, x + ox, y + oy, c)
	for y in range(r.position.y, r.end.y):
		for x in [r.position.x, r.end.x - 1]:
			if y % 2 == 0: L.P(img, x + ox, y + oy, c)

func make_mockup() -> void:
	var W := 792
	var H := 716
	var img: Image = L.blank(W, H)
	img.fill(L.col("ink"))
	var fighter_pos := Vector2i(303, 272)
	var fh := Vector2i(303, 210)                        # head_anchor (0,-62) do 1º lutador
	var ch := P_COACH + Vector2i(1, -63)                # head_anchor do Osmar (coach_idle)
	# ---- ANTES: aviso + ficha em branco + foto antiga; o Téo fala (desliza para a esquerda)
	var a := room(false, true, false)
	var ba := draw_bubble(a, ["o muralha riu da ficha:", "escola: nenhuma."], fh, "téo", "red", [ch + Vector2i(0, 4)])
	# ---- DEPOIS: equipe cheia; Osmar fala (em cima)
	COACH_SHEET = "coach_talk"
	var b := room(true, false, true)
	var bb := draw_bubble(b, ["o aviso saiu da parede.", "ainda é nossa, viu?"], ch, "osmar", "gold")
	blend(img, a.get_region(ROOM), 8, 14)
	blend(img, b.get_region(ROOM), 400, 14)
	T(img, "ANTES: AVISO, FICHA EM BRANCO, FOTO ANTIGA", 8, 4, "cream")
	T(img, "DEPOIS DE GARAGEM SALVA (EQUIPE CHEIA)", 400, 4, "cream")
	CHECKED["first_foco_saco"] = {"head": [fh.x, fh.y], "rect": [ba.x, ba.y, ba.w, ba.h], "tail": ba.tail, "tip": ba.tip, "mode": ba.mode}
	CHECKED["coach_196_236"] = {"head": [ch.x, ch.y], "rect": [bb.x, bb.y, bb.w, bb.h], "tail": bb.tail, "tip": bb.tip, "mode": bb.mode, "note": "head_anchor do coach_idle (1,-63)"}
	print("  balão téo: ", ba)
	print("  balão osmar: ", bb, " cabeça ", ch)
	dashed(img, NO_COVER, 8 - 128, 14 - 18, "r3")
	dashed(img, Rect2i(174, 36, 84, 54), 8 - 128, 14 - 18, "y1")
	# ---- linha 2: vitória com o selo | peças
	var y2 := 296
	T(img, "VITÓRIA DO CINTURÃO + SELO (POSIÇÃO PROPOSTA)", 8, y2, "cream")
	var vx := 8
	var vy := y2 + 12
	nine(img, "ui_window", vx, vy, 336, 236)
	nine(img, "ui_window_title_victory", vx + 4, vy + 5, 328, 21)
	L.text_center(img, "CINTURÃO AMADOR", vx + 168, vy + 9, "y1", 2, "ink")
	var belt := scaled(frame_of("belt_amateur_big", 0), 2)
	blend(img, belt, vx + 168 - 112, vy + 26)
	L.text_center(img, "O BAIRRO VIU. UNS QUINZE.", vx + 168, vy + 120, "cream")
	put(img, "icon_money_16", 0, vx + 105, vy + 134); T(img, "+$2.50K", vx + 125, vy + 138, "y1")
	put(img, "icon_fame_16", 0, vx + 105, vy + 150); T(img, "+100 FAMA", vx + 125, vy + 154, "f2")
	put(img, "icon_legacy_16", 0, vx + 105, vy + 166); T(img, "+300 LEGADO EM JOGO", vx + 125, vy + 170, "p2")
	put(img, "icon_garage_saved", 0, vx + 105, vy + 182); T(img, "GARAGEM SALVA", vx + 125, vy + 182, "white")
	T(img, "O LUGAR CONTINUA NOSSO", vx + 125, vy + 191, "g2")
	put(img, "seal_garage_saved", 0, vx + 266, vy + 123)
	L.R(img, vx + 14, vy + 206, 308, 1, "g0")
	T(img, "(LEGADO, MUDANÇA E CONTINUAR SEGUEM IGUAIS)", vx + 14, vy + 214, "g1")
	# ---- peças (x 356..784)
	var wx := 356
	T(img, "PEÇAS EM 2X", wx, y2, "cream")
	var wy := y2 + 12
	blend(img, scaled(frame_of("garage_bg").get_region(Rect2i(46, 18, 214, 36)), 2), wx, wy)
	var objs := [["wall_notice_debt", 4], ["wall_form_blank", 52], ["wall_form_named", 100], ["wall_photo_old", 148], ["wall_clipping", 188], ["wall_photo_team", 232], ["wall_school_symbol", 288]]
	for o in objs:
		blend(img, scaled(frame_of(o[0]), 2), wx + o[1], wy + 2)
	var sy := wy + 80
	var sx := wx + 2
	for sz in [5, 9, 16, 32]:
		var simg := scaled(frame_of("school_symbol_%d" % sz), 2)
		L.R(img, sx - 2, sy - 2, simg.get_width() + 4, simg.get_height() + 4, "white")
		blend(img, simg, sx, sy)
		sx += simg.get_width() + 10
	blend(img, frame_of("seal_garage_saved_text"), sx + 4, sy)
	blend(img, frame_of("icon_garage_saved"), sx + 106, sy)
	var py := sy + 72
	var sb: Image = L.blank(214, 40)
	sb.fill(L.col("g0"))
	nine(sb, "ui_balloon", 4, 12, 60, 17); put(sb, "ui_balloon_tail_l", 0, 12, 27)
	nine(sb, "ui_balloon", 74, 12, 60, 17); put(sb, "ui_balloon_tail", 0, 101, 27)
	put(sb, "ui_balloon_next", 0, 124, 21)
	nine(sb, "ui_balloon", 144, 12, 60, 17); put(sb, "ui_balloon_tail_r", 0, 190, 27)
	nine(sb, "ui_balloon_tag_red", 10, 6, 24, 10); L.text(sb, "téo", 13, 8, "white")
	nine(sb, "ui_balloon_tag_gold", 80, 6, 36, 10); L.text(sb, "osmar", 83, 8, "ink")
	nine(sb, "ui_balloon_tag_blue", 150, 6, 12, 10)
	blend(img, scaled(sb, 2), wx, py)
	var ry := py + 84
	var skip: Image = L.blank(214, 18)
	skip.fill(L.col("g0"))
	for i in 5:
		put(skip, "ui_skip_ring", i * 2, 2 + i * 13, 4)
	var cw: int = 41 + L.text_w("esc: pular") + 5
	nine(skip, "ui_skip_chip_active", 70, 1, cw, 16)
	put(skip, "ui_skip_ring", 5, 73, 4)
	put(skip, "icon_key_esc", 0, 86, 3)
	T(skip, "esc: pular", 111, 6, "white")
	blend(img, scaled(skip, 2), wx, ry)
	var gy := ry + 42
	T(img, "ACADEMIA (1X): BALÃO NA PAREDE CREME", wx, gy, "cream")
	var gym: Image = L.blank(640, 360)
	put(gym, "gym_bg", 0, 128, 18)
	put_pv(gym, "fighter_idle", 0, fighter_pos)
	draw_bubble(gym, ["ação, você, lâmpada, aí…", "RAÍZES — está lá."], fh, "téo", "red")
	blend(img, gym.get_region(Rect2i(132, 150, 214, 80)), wx, gy + 10)
	var g2: Image = L.blank(640, 360)
	put(g2, "gym_bg", 0, 128, 18)
	draw_bubble(g2, ["fala curta."], Vector2i(430, 120), "osmar", "gold")
	blend(img, g2.get_region(Rect2i(370, 70, 120, 80)), wx + 222, gy + 10)
	DirAccess.make_dir_recursive_absolute(MOCK)
	img.resize(W * 2, H * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(MOCK + "fase6a_garagem_x2.png")

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

func xy(v: Vector2i) -> Array:
	return [v.x, v.y]

func write_manifest() -> void:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível na hora de gravar; nada foi escrito")
		return
	var doc: Dictionary = intify(j.data)
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 6a") < 0:
		doc["_sobre"] = sobre + " Fase 6a (Diretor de Arte): balão de fala, segurar ESC, selo garagem salva, objetos do Arco 1 na parede da garagem, símbolo da lâmpada, acentos das minúsculas (direcao-visual.md §22)."
	var sp: Dictionary = doc.get("sprites", {})
	for id in M:
		sp[id] = intify(M[id])
	doc["sprites"] = sp
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["speech_bubble"] = {
		"spec": "docs/cutscenes/balao-e-voz.md (valores) + direcao-visual.md §22 (peças)",
		"body": "ui_balloon", "tail": "ui_balloon_tail", "tail_l": "ui_balloon_tail_l", "tail_r": "ui_balloon_tail_r", "next": "ui_balloon_next",
		"tag_by_color": {"red": "ui_balloon_tag_red", "gold": "ui_balloon_tag_gold", "blue": "ui_balloon_tag_blue", "green": "ui_balloon_tag_green", "purple": "ui_balloon_tag_purple", "gray": "ui_balloon_tag_gray"},
		"tag_text_color": TAG_TEXT,
		"tag_by_speaker": {"first": "red", "coach": "gold", "disciple": "blue"},
		"size": {"w": "maior linha x 6 + 16 (mín 40, máx 172)", "h_1_line": 17, "h_2_lines": 26,
			"note": "w x h é o retângulo do 9-slice INTEIRO, já com a sombra de 1 px (última coluna e última linha). Margens 8/8 e 5/5 contam a borda e a sombra."},
		"text": {"first_cap_top": [0, 5], "line_pitch": 9, "align": "linhas à esquerda, bloco centrado: x = bx + (w - (maior_linha x 6 - 1)) / 2", "color": "ink", "shadow": false,
			"bmfont_note": "Com o BMFont (lineHeight 12) a célula começa 2 px acima do topo da maiúscula: Label em y = by + 3 e line_spacing -3 (ou 2 Labels a 9 px)."},
		"tail_rule": {"frame_top_y": "by + h - 2 (a linha 0 do rabicho cai no contorno de baixo e o apaga)", "tip_offset": {"c": [3, 5], "l": [0, 5], "r": [6, 5]},
			"tip_x": "limitar(cabeça.x, bx + 8, bx + w - 8)", "which": "ui_balloon_tail (c) no meio; tail_l se a ponta está a menos de 14 px da borda esquerda, tail_r a menos de 15 px da direita",
			"tip_y": "by + h + 3 (5 px para fora do corpo visível)"},
		"tag": {"pos": "(bx + 6, by - 6)", "h": 10, "w": "nome x 6 + 6", "text_offset_cap_top": [3, 2], "bmfont_cell_offset": [3, 0], "case": "minúsculas, até 12 caracteres",
			"note": "10 px (não 9): o acento da minúscula (téo) precisa de 1 linha entre o contorno e a letra. Fica 6 px acima do balão e cobre as 3 primeiras linhas da borda."},
		"next_arrow": {"pos": "(bx + w - 12, by + h - 9)", "frames": [0, 1], "fps": 2.0, "mode": "cena (6b)"},
		"placement": {"no_cover": [NO_COVER.position.x, NO_COVER.position.y, NO_COVER.size.x, NO_COVER.size.y], "usable": [132, 22, 507, 285],
			"rule": "balao-e-voz.md §3: em cima (ponta 6 px acima do head_anchor) > desliza para o lado do personagem até 2 px fora da no_cover > sobe até a ponta ficar em y <= 178. O retângulo testado inclui plaquinha (6 px acima) e rabicho (4 px abaixo).",
			"checked": CHECKED},
		"anim": "entra em 2 quadros (metade do tamanho, depois inteiro; 9-slice redimensionado em px inteiro); some em 1 quadro. Sem alpha.",
		"_nota": "Fase 6a (Diretor de Arte). Fundo cream conforme balao-e-voz.md: na parede creme da academia ele se separa pelo contorno ink + sombra d1 (conferido no mockup)."}
	bd["skip_hold"] = {"chip": "ui_skip_chip", "chip_active": "ui_skip_chip_active", "ring": "ui_skip_ring", "ring_frames": 9, "key": "icon_key_esc",
		"height": 16, "ring_offset": [3, 3], "key_offset": [16, 3], "text_offset_cap_top": [41, 5], "text_color": "white", "text_color_idle": "g2",
		"width_rule": "41 + texto + 5", "rect_right_bottom": [507, 285], "text_suggestion": "esc: pular (balao-e-voz.md §5)",
		"rule": "Só na abertura. Apagado (ui_skip_chip, texto g2, anel 0) desde o começo. Segurando ESC: ui_skip_chip_active e o anel enche (quadro = round(8 x tempo / 0,5 s)). Soltou antes: volta ao 0. Encheu: pula. A versão mínima do DC (só texto + filete) cabe no mesmo chip.",
		"_nota": "Fase 6a. Canto de baixo à direita da sala (borda direita em x 507, base em y 285). O botão PULAR da 6b reaproveita o anel."}
	bd["garage_saved_seal"] = {"seal": "seal_garage_saved", "seal_with_text": "seal_garage_saved_text", "band": "ui_seal_garage_band", "icon": "icon_garage_saved",
		"victory_pos": [418, 146],
		"victory_note": "Tela de vitória do cinturão (janela em 152,23): selo 52x54 à direita das linhas de prêmio, canto de cima à esquerda em (418,146); não encosta no texto (termina em x ~385) nem na linha do Legado (y 208). Linha extra nos prêmios, igual às de $/Fama/Legado: icon_garage_saved + 'GARAGEM SALVA' (white) e embaixo 'O LUGAR CONTINUA NOSSO' (col_text_2), textos do Roteirista.",
		"entry": "aparece 0,3 s depois da janela: 2 quadros em 2x (px inteiro, mesmo centro) e depois 1x, tremida de 1 px e um som que já existe (hit_heavy.wav). Sem alpha.",
		"band_text_rect": [8, 50, 80, 7], "band_text_color": "d1",
		"_nota": "Fase 6a. O selo é o próprio aviso de cobrança, despregado da parede, com o carimbo azul da escola (a lâmpada com raízes). A versão com fita (96x64, texto embutido GARAGEM SALVA) é para espaços maiores (fim de carreira, cartão da campanha)."}
	bd["garage_story_wall"] = {
		"objects": {
			"notice_debt": {"sprite": "wall_notice_debt", "pos": xy(P_NOTICE), "when": "desde o começo", "until": "garage_saved_seen", "hover_text": "aviso_cobranca"},
			"form": {"sprite_before": "wall_form_blank", "sprite_after": "wall_form_named", "pos": xy(P_FORM), "when": "sempre", "swap": "garage_saved_seen", "hover_text": "ficha_antes / ficha_depois (ESCOLA: NENHUMA / ESCOLA: RAÍZES FIGHT CLUB)"},
			"photo_old": {"sprite": "wall_photo_old", "pos": xy(P_PHOTO_OLD), "when": "sempre", "hover_text": "foto_antiga", "note": "cobre a fotinho pintada no garage_bg"},
			"clipping": {"sprite": "wall_clipping", "pos": xy(P_CLIPPING), "when": "first_school_win", "hover_text": "recorte"},
			"photo_team": {"sprite": "wall_photo_team", "pos": xy(P_PHOTO_TEAM), "when": "garage_saved_seen", "hover_text": "foto_equipe", "note": "no lugar do aviso"},
			"school_symbol": {"sprite": "wall_school_symbol", "pos": xy(P_SYMBOL), "when": "garage_saved_seen", "note": "fora da parede da memória: alto, à direita da corrente"}},
		"states": {"antes": ["notice_debt", "form(blank)", "photo_old", "clipping se first_school_win"], "depois": ["form(named)", "photo_old", "clipping", "photo_team", "school_symbol"]},
		"memory_wall": [176, 38, 81, 50],
		"memory_wall_note": "Parede da memória: x 176..256, y 38..87 (ajuste da proposta do DC x 180..262, y 56..104: abaixo de y 92 bate no metrônomo (231..249, y 93) e a prateleira começa em y 101). É para onde Osmar olha. A mesma faixa serve de mural na 6c.",
		"layer": "frente_do_fundo", "z": -45, "pivot": "0,0 (pos = canto de cima à esquerda)", "only_location": "garage",
		"keep_clear": {"rope_hook_tape": [283, 164, 27, 48], "shelf": [180, 101, 80, 27], "metronome": [231, 93, 19, 26], "poster": [269, 65, 29, 38],
			"lamp": [286, 32, 30, 48], "bag_chain_x": 335, "speed_bag_wall": [408, 42, 57, 61], "door": [379, 97, 91, 123]},
		"_nota": "Fase 6a (Diretor de Arte). Luz da lâmpada já aplicada para estes pontos (não mover para longe). Só na garagem. Troca de estado sem animação. Nenhum objeto tem texto legível na sala: o texto vai na dica de hover (data/ do Roteirista)."}
	bd["coach_point"] = {"pos": xy(P_COACH), "facing": "direita",
		"note": "Ponto do Osmar na garagem: (196,236), encostado no carro, longe do saco (decisão do Produtor; o DC tinha proposto 236,238). Conferido no mockup com a equipe cheia: longe do alvo e da no_cover; o balão dele fica em cima, sem ajuste, e não cobre a parede da memória. Os vizinhos 1 (176,284) e 2 (220,258) passam na frente das pernas dele (ordem por y): aceito."}
	var sym: Dictionary = {"provisional": false, "design": "Raízes Fight Club: a lâmpada da garagem, de pé, com o soquete virando raiz", "files": ["school_symbol_5", "school_symbol_9", "school_symbol_16", "school_symbol_32"],
		"wall": "wall_school_symbol", "note": "Fase 6a: símbolo definitivo do placeholder (o dono valida). Também pintado na etiqueta de box_big/box_small (trocado pelo gerador da 6a)."}
	if bd.has("box") and bd["box"] is Dictionary:
		var bx: Dictionary = bd["box"]
		bx["symbol"] = sym
		bd["box"] = bx
	bd["school_symbol"] = sym
	bd["_nota_fase6a_arte"] = "Fase 6a (Diretor de Arte): speech_bubble, skip_hold, garage_saved_seal, garage_story_wall, school_symbol. Fonte 5x7 regravada (acentos das minúsculas, — e …)."
	doc["by_data_id"] = bd
	for fk in ["font_fightclicker_5x7", "font_fightclicker_5x7_contorno"]:
		if sp.has(fk):
			var fe: Dictionary = sp[fk]
			fe["glyphs"] = 117
			fe["note"] = str(fe.get("note", "")).split(" Fase 6a:")[0] + " Fase 6a: acentos das minúsculas 1 linha acima (não encostam mais na letra), í sem bandeira, travessão — e reticências … novos."
			sp[fk] = fe
	var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()

# ================================================================ main
func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	FINAL = OS.get_cmdline_user_args().has("--final")
	var here: String = OS.get_environment("ART6A_OUT")
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
	# ---- balão
	save_sheet("ui_balloon", "ui/ui_balloon.png", [balloon_body()], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 5, "top": 5, "right": 5, "bottom": 5}, "text_color": "ink",
		"note": "Balão de fala (9-slice 16x16, cantos de 5): fundo cream, contorno ink com canto de 2 px, sombra dura d1 de 1 px embaixo e à direita. O retângulo w x h (17 ou 26 de altura) já inclui a sombra. Texto 1x ink sem sombra, topo da maiúscula em by+5. Regras em by_data_id.speech_bubble e docs/cutscenes/balao-e-voz.md."})
	for kind in ["c", "l", "r"]:
		var tip: Array = {"c": [3, 5], "l": [0, 5], "r": [6, 5]}[kind]
		var id: String = "ui_balloon_tail" + ("" if kind == "c" else "_" + kind)
		save_sheet(id, "ui/%s.png" % id, [balloon_tail(kind)], 0, Vector2i(tip[0], tip[1]), {
			"tip": tip,
			"note": "Rabicho 7x6 (%s). A linha 0 é cream e cai em cima do contorno de baixo do corpo (y = by + h - 2): apaga o contorno. A ponta fica em by + h + 3. Pivô = ponta." % {"c": "reto, para baixo", "l": "ponta à esquerda: quando a ponta está perto da borda esquerda do balão", "r": "ponta à direita: quando a ponta está perto da borda direita"}[kind]})
	for c in TAG_COL:
		save_sheet("ui_balloon_tag_" + c, "ui/ui_balloon_tag_%s.png" % c, [balloon_tag(TAG_COL[c])], 0, Vector2i.ZERO, {
			"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 2}, "text_color": TAG_TEXT[c],
			"note": "Plaquinha do nome (%s, %s). Altura 10, largura = nome x 6 + 6, em (bx + 6, by - 6). Nome em minúsculas 1x %s, topo da letra em (3,2) (célula do BMFont em (3,0))." % [c, TAG_COL[c], TAG_TEXT[c]]})
	save_sheet("ui_balloon_next", "ui/ui_balloon_next.png", [balloon_next(true), balloon_next(false)], 2.0, Vector2i.ZERO, {
		"loop": true, "note": "Seta ▼ de fim de fala (modo cena, 6b). 5x4, 2 quadros a 2 fps (aceso, apagado), em (bx + w - 12, by + h - 9). A fonte não tem ▼: usar este sprite."})
	# ---- segurar ESC
	save_sheet("ui_skip_chip", "ui/ui_skip_chip.png", [skip_chip(false)], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 3}, "text_color": "g2",
		"note": "Indicador 'segure ESC para pular' (abertura), apagado. Altura 16: anel em (3,3), tecla em (16,3), texto 1x em (41,5). Largura = 41 + texto + 5."})
	save_sheet("ui_skip_chip_active", "ui/ui_skip_chip_active.png", [skip_chip(true)], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 3}, "text_color": "white",
		"note": "Mesmo indicador enquanto o ESC está seguro (borda âmbar y0, texto white)."})
	save_sheet("icon_key_esc", "ui/icon_key_esc.png", [key_esc()], 0, Vector2i.ZERO, {"note": "Tecla ESC 21x12 (mesmo estilo de tecla clara). Vai no indicador de pular."})
	var rings := []
	for i in 9:
		rings.append(skip_ring(i, 8))
	save_sheet("ui_skip_ring", "ui/ui_skip_ring.png", rings, 0, Vector2i.ZERO, {
		"note": "Anel 11x11 que enche no sentido horário enquanto segura ESC: quadro 0 vazio ... 8 cheio (miolo acende). Quadro = round(8 * tempo_segurado / 0,5 s). A 6b reusa no botão PULAR."})
	# ---- selo
	save_sheet("seal_garage_saved", "ui/seal_garage_saved.png", [seal_garage(false)], 0, Vector2i.ZERO, {
		"note": "Selo GARAGEM SALVA sem texto (52x54): o aviso de cobrança despregado, com o carimbo azul da escola (a lâmpada). Tela de vitória do cinturão em (418,146). O texto vai na linha de prêmio (icon_garage_saved + Label)."})
	save_sheet("seal_garage_saved_text", "ui/seal_garage_saved_text.png", [seal_garage(true, "GARAGEM SALVA")], 0, Vector2i.ZERO, {
		"note": "Selo 96x64 com a fita dourada e o texto padrão 'GARAGEM SALVA' embutido. Só usar se o texto do Roteirista for igual; senão seal_garage_saved_text_blank? Não: montar com seal_garage_saved + ui_seal_garage_band + Label."})
	save_sheet("ui_seal_garage_band", "ui/ui_seal_garage_band.png", [band_tex()], 0, Vector2i.ZERO, {
		"nine_slice": {"left": 8, "top": 3, "right": 8, "bottom": 3}, "text_color": "d1",
		"note": "Fita dourada 9-slice (pontas em V) para escrever o texto do selo. Altura 15, texto 1x d1 com o topo da maiúscula em y 4."})
	save_sheet("icon_garage_saved", "ui/icon_garage_saved.png", [icon_garage_saved()], 0, Vector2i.ZERO, {
		"note": "Ícone 16x16 da linha 'garagem salva' nos prêmios da vitória (mesmo tamanho dos ícones de $, Fama e Legado): o aviso com o carimbo da lâmpada."})
	# ---- símbolo
	for sz in [5, 9, 16, 32]:
		var id := "school_symbol_%d" % sz
		save_sheet(id, "ui/%s.png" % id, [school_symbol(sz)], 0, Vector2i.ZERO, {
			"provisional": false,
			"note": "SÍMBOLO DA ESCOLA Raízes Fight Club (%dx%d): a lâmpada da garagem de pé, com o soquete virando raiz, em tinta de carimbo azul b1 + b2. Fase 6a: substitui o frontão provisório. Pintado na parede: wall_school_symbol." % [sz, sz]})
	patch_box("box_big")
	patch_box("box_small")
	# ---- parede
	save_sheet("wall_notice_debt", "garage/wall_notice_debt.png", [wall_notice()], 0, Vector2i.ZERO, {
		"pos": xy(P_NOTICE), "layer": "frente_do_fundo", "z": -45,
		"note": "Arco 1: AVISO DE COBRANÇA preso com fita crepe na parede da memória (borda e cabeçalho vermelhos, valor circulado, sem texto legível). Desde o começo até a garagem ser salva. Luz da lâmpada aplicada para este ponto."})
	save_sheet("wall_form_blank", "garage/wall_form_blank.png", [wall_form(false)], 0, Vector2i.ZERO, {
		"pos": xy(P_FORM), "layer": "frente_do_fundo", "z": -45,
		"note": "Arco 1 (humilhação A): FICHA DE INSCRIÇÃO amassada, presa num prego, campo ESCOLA com um rabisco curto a lápis. Sem texto legível: na dica vai ESCOLA: NENHUMA. Desde o começo até garage_saved_seen; depois troca por wall_form_named no mesmo ponto."})
	save_sheet("wall_form_named", "garage/wall_form_named.png", [wall_form(true)], 0, Vector2i.ZERO, {
		"pos": xy(P_FORM), "layer": "frente_do_fundo", "z": -45,
		"note": "Arco 1: a mesma ficha depois da garagem salva: o rabisco riscado de vermelho e o nome escrito à mão em caneta azul, grande, passando da linha, sublinhado. Na dica: ESCOLA: RAÍZES FIGHT CLUB."})
	save_sheet("wall_photo_old", "garage/wall_photo_old.png", [wall_photo_old()], 0, Vector2i.ZERO, {
		"pos": xy(P_PHOTO_OLD), "layer": "frente_do_fundo", "z": -45,
		"note": "Arco 1: FOTO ANTIGA do treinador jovem (sépia, luvas para cima, cinturão), moldura de madeira TORTA (a metade direita 1 px abaixo; é assim que ela fica na garagem). Sempre na parede. Cobre a fotinho pintada no garage_bg."})
	save_sheet("wall_clipping", "garage/wall_clipping.png", [wall_clipping()], 0, Vector2i.ZERO, {
		"pos": xy(P_CLIPPING), "layer": "frente_do_fundo", "z": -45,
		"note": "Arco 1: RECORTE DE JORNAL (manchete, foto de luta, colunas, borda picotada, fita no meio). Aparece na 1ª vitória da escola depois da 6a e fica."})
	save_sheet("wall_photo_team", "garage/wall_photo_team.png", [wall_photo_team()], 0, Vector2i.ZERO, {
		"pos": xy(P_PHOTO_TEAM), "layer": "frente_do_fundo", "z": -45,
		"note": "Arco 1: FOTO DA EQUIPE (moldura preta nova, 5 pessoas, cinturão erguido no meio, a lâmpada no alto da foto). Entra no lugar do aviso quando a garagem é salva. As pessoas são genéricas de propósito (servem para qualquer discípulo que ganhe o cinturão)."})
	save_sheet("wall_school_symbol", "garage/wall_school_symbol.png", [wall_symbol()], 0, Vector2i.ZERO, {
		"pos": xy(P_SYMBOL), "layer": "frente_do_fundo", "z": -46,
		"note": "Arco 1: SÍMBOLO DA ESCOLA pintado na parede (school_symbol_16 em 2x, tinta amarela que afunda no rejunte, 3 escorridos). Aparece quando a garagem é salva. Recortado sobre o garage_bg deste ponto (não mover)."})
	make_font()
	make_mockup()
	if FINAL:
		write_manifest()
	print("ok fase 6a arte (%s): %d sprites" % ["PROJETO" if FINAL else "previa", M.size()])
	quit()
