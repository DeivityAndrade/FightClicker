extends RefCounted
## Biblioteca de pixel art gerada por código (PLACEHOLDER) — Fightclicker.
## Usada pelos scripts make_mockup_*.gd. Paleta, rampas de sombra, formas,
## contorno automático, luz com dither ordenado e uma fonte bitmap 5x7.
## Tudo original. Ver docs/arte/direcao-visual.md.

# ---------------------------------------------------------------- paleta
const PAL_HEX := {
	"ink": "14101a", "d1": "2a2233", "d2": "3d3346",
	"g0": "4a4552", "g1": "6b6570", "g2": "8f8890", "g3": "b8b0aa",
	"cream": "d9cdb4", "white": "f2ece0",
	"br0": "3b2622", "br1": "6b3f2a", "br2": "9a5f36", "br3": "c98a4b",
	"y0": "e0a040", "y1": "f5d26b", "y2": "fff3c4",
	"r0": "5a1a22", "r1": "9c2a2a", "r2": "d4473a", "r3": "f07a5a",
	"sk0": "7a4632", "sk1": "b9744f", "sk2": "e3a275",
	"b0": "1f2a44", "b1": "2f4a78", "b2": "4d7bb3", "b3": "8fbbe0",
	"gr0": "1f3d33", "gr1": "2f6b4a", "gr2": "5aa25a", "gr3": "a6d86a",
	"st0": "3a4452", "st1": "5a6676", "st2": "7f8c9a", "st3": "a9b4bf",
	"p0": "4a2f6b", "p1": "7a4fa0", "p2": "b07ad8",
	# Fase 5.1: rampa só de UI para a moeda Fama (rosa de letreiro). Não usar em cenário.
	"f0": "7a2a52", "f1": "d4558f", "f2": "f59ac0",
}

# Rampas: escuro -> claro. Sombra/luz = andar na rampa (paleta fica fechada).
const RAMPS := [
	["ink", "d1", "d2", "g0", "g1", "g2", "g3", "cream", "white"],
	["ink", "br0", "br1", "br2", "br3", "y0", "y1", "y2"],
	["ink", "r0", "r1", "r2", "r3"],
	["br0", "sk0", "sk1", "sk2", "y2"],
	["ink", "b0", "b1", "b2", "b3", "white"],
	["ink", "gr0", "gr1", "gr2", "gr3", "y2"],
	["ink", "d1", "st0", "st1", "st2", "st3", "white"],
	["ink", "p0", "p1", "p2"],
	["ink", "f0", "f1", "f2"],
]

const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

var C := {}          # nome -> Color
var _lookup := {}    # hex -> [rampa, indice]
var _ink_hex := ""

func _init() -> void:
	for k in PAL_HEX:
		C[k] = Color.html("#" + PAL_HEX[k])
	for ri in RAMPS.size():
		var ramp: Array = RAMPS[ri]
		for i in ramp.size():
			var hx: String = PAL_HEX[ramp[i]]
			if not _lookup.has(hx):
				_lookup[hx] = [ri, i]
	_ink_hex = PAL_HEX["ink"]

func col(n) -> Color:
	if n is Color:
		return n
	return C[n]

## Anda n passos na rampa da cor (n<0 escurece, n>0 clareia).
func shade(c: Color, n: int) -> Color:
	var hx := c.to_html(false)
	if not _lookup.has(hx):
		return c
	if hx == _ink_hex:
		return c   # contorno nunca clareia
	var info: Array = _lookup[hx]
	var ramp: Array = RAMPS[info[0]]
	var i: int = clampi(info[1] + n, 0, ramp.size() - 1)
	return C[ramp[i]]

# ---------------------------------------------------------------- formas
func blank(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)

func R(img: Image, x: int, y: int, w: int, h: int, c) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	if r.has_area():
		img.fill_rect(r, col(c))

func P(img: Image, x: int, y: int, c) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, col(c))

func line(img: Image, x0: int, y0: int, x1: int, y1: int, c) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		P(img, x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

## Trapézio horizontal: linha y0 vai de xl0..xr0, linha y1 de xl1..xr1.
func trap(img: Image, y0: int, y1: int, xl0: float, xr0: float, xl1: float, xr1: float, c) -> void:
	for y in range(y0, y1 + 1):
		var t := 0.0 if y1 == y0 else float(y - y0) / float(y1 - y0)
		var a := int(round(lerpf(xl0, xl1, t)))
		var b := int(round(lerpf(xr0, xr1, t)))
		R(img, a, y, b - a + 1, 1, c)

func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				P(img, x, y, c)

func ellipse_dither(img: Image, cx: float, cy: float, rx: float, ry: float, c, phase := 0) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0 and (x + y + phase) % 2 == 0:
				P(img, x, y, c)

func ring(img: Image, cx: float, cy: float, rx: float, ry: float, t: float, c) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			var mx := (x + 0.5 - cx) / maxf(rx - t, 0.5)
			var my := (y + 0.5 - cy) / maxf(ry - t, 0.5)
			if nx * nx + ny * ny <= 1.0 and mx * mx + my * my > 1.0:
				P(img, x, y, c)

func dither(img: Image, x: int, y: int, w: int, h: int, c, phase := 0) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			if (xx + yy + phase) % 2 == 0:
				P(img, xx, yy, c)

func rrect(img: Image, x: int, y: int, w: int, h: int, c) -> void:
	R(img, x + 1, y, w - 2, h, c)
	R(img, x, y + 1, w, h - 2, c)

## Escurece/clareia uma área andando na rampa (respeita a paleta).
func shade_rect(img: Image, x: int, y: int, w: int, h: int, n: int, dith := false) -> void:
	for yy in range(maxi(y, 0), mini(y + h, img.get_height())):
		for xx in range(maxi(x, 0), mini(x + w, img.get_width())):
			if dith and (xx + yy) % 2 == 1:
				continue
			var c := img.get_pixel(xx, yy)
			if c.a > 0.0:
				img.set_pixel(xx, yy, shade(c, n))

func blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

## Contorno de 1px (4-vizinhos) em volta dos pixels opacos.
func outlined(src: Image, c = "ink") -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := blank(w + 2, h + 2)
	var oc := col(c)
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					out.set_pixel(x + 1 + d.x, y + 1 + d.y, oc)
	blit(out, src, 1, 1)
	return out

func stamp(dst: Image, src: Image, x: int, y: int, outline := true) -> void:
	if outline:
		blit(dst, outlined(src), x - 1, y - 1)
	else:
		blit(dst, src, x, y)

func flipped(src: Image) -> Image:
	var c := src.duplicate()
	c.flip_x()
	return c

# ---------------------------------------------------------------- luz
## Luz pontual com faixas e dither ordenado nas bordas das faixas.
func light(img: Image, area: Rect2i, center: Vector2, radius: float, ysq := 1.0,
		strength := 3.0, min_step := -2, max_step := 1, offset := 1.0) -> void:
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var d := Vector2(x - center.x, (y - center.y) * ysq).length() / radius
			var lf := offset - d * strength
			var base := floorf(lf)
			var fr := clampf((lf - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
			var b: float = (BAYER[y % 4][x % 4] + 0.5) / 16.0
			var step := int(base) + (1 if fr > b else 0)
			step = clampi(step, min_step, max_step)
			if step != 0:
				img.set_pixel(x, y, shade(c, step))

# ---------------------------------------------------------------- fonte 5x7
const GLYPHS := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": ["###", ".#.", ".#.", ".#.", ".#.", ".#.", "###"],
	"J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "#.#.#", ".#.#."],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": [".#.", "##.", ".#.", ".#.", ".#.", ".#.", "###"],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", "..#..", "..#..", "..#.."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
	".": [".", ".", ".", ".", ".", ".", "#"],
	",": ["..", "..", "..", "..", "..", ".#", "#."],
	":": [".", "#", ".", ".", ".", "#", "."],
	"!": ["#", "#", "#", "#", "#", ".", "#"],
	"?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	"/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
	"-": ["....", "....", "....", "####", "....", "....", "...."],
	"$": ["..#..", ".####", "#.#..", ".###.", "..#.#", "####.", "..#.."],
	# --- Fase 3: ordinais ("2º ROUND")
	"º": [".#.", "#.#", ".#.", "...", "###", "...", "..."],
	"ª": [".##", "#.#", ".##", "...", "###", "...", "..."],
	"%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
	"(": [".#", "#.", "#.", "#.", "#.", "#.", ".#"],
	")": ["#.", ".#", ".#", ".#", ".#", ".#", "#."],
	"<": ["...#", "..#.", ".#..", "#...", ".#..", "..#.", "...#"],
	">": ["#...", ".#..", "..#.", "...#", "..#.", ".#..", "#..."],
	# --- Fase 2: pontuação extra
	"_": ["....", "....", "....", "....", "....", "....", "....", "####"],
	"'": ["#", "#", ".", ".", ".", ".", "."],
	"\"": ["#.#", "#.#", "...", "...", "...", "...", "..."],
	";": ["..", "..", ".#", "..", "..", ".#", "#."],
	"=": ["....", "....", "####", "....", "####", "....", "...."],
	"*": [".....", "#.#.#", ".###.", "#####", ".###.", "#.#.#", "....."],
	"#": [".#.#.", ".#.#.", "#####", ".#.#.", "#####", ".#.#.", ".#.#."],
	"&": [".##..", "#..#.", "#.#..", ".#...", "#.#.#", "#..#.", ".##.#"],
	"[": ["##", "#.", "#.", "#.", "#.", "#.", "##"],
	"]": ["##", ".#", ".#", ".#", ".#", ".#", "##"],
	"×": [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#"],
	"°": [".#.", "#.#", ".#.", "...", "...", "...", "..."],
	# --- Fase 2: minúsculas (altura-x = linhas 2..6, descendentes 7..8)
	"a": [".....", ".....", ".###.", "....#", ".####", "#...#", ".####", ".....", "....."],
	"b": ["#....", "#....", "####.", "#...#", "#...#", "#...#", "####.", ".....", "....."],
	"c": [".....", ".....", ".####", "#....", "#....", "#....", ".####", ".....", "....."],
	"d": ["....#", "....#", ".####", "#...#", "#...#", "#...#", ".####", ".....", "....."],
	"e": [".....", ".....", ".###.", "#...#", "#####", "#....", ".####", ".....", "....."],
	"f": ["..##", ".#..", "###.", ".#..", ".#..", ".#..", ".#..", "....", "...."],
	"g": [".....", ".....", ".####", "#...#", "#...#", "#...#", ".####", "....#", ".###."],
	"h": ["#....", "#....", "####.", "#...#", "#...#", "#...#", "#...#", ".....", "....."],
	"i": [".#.", "...", "##.", ".#.", ".#.", ".#.", "###", "...", "..."],
	"j": ["..#", "...", ".##", "..#", "..#", "..#", "..#", "#.#", ".#."],
	"k": ["#...", "#...", "#..#", "#.#.", "##..", "#.#.", "#..#", "....", "...."],
	"l": ["##.", ".#.", ".#.", ".#.", ".#.", ".#.", "###", "...", "..."],
	"m": [".....", ".....", "####.", "#.#.#", "#.#.#", "#.#.#", "#.#.#", ".....", "....."],
	"n": [".....", ".....", "####.", "#...#", "#...#", "#...#", "#...#", ".....", "....."],
	"o": [".....", ".....", ".###.", "#...#", "#...#", "#...#", ".###.", ".....", "....."],
	"p": [".....", ".....", "####.", "#...#", "#...#", "#...#", "####.", "#....", "#...."],
	"q": [".....", ".....", ".####", "#...#", "#...#", "#...#", ".####", "....#", "....#"],
	"r": ["....", "....", "#.##", "##..", "#...", "#...", "#...", "....", "...."],
	"s": [".....", ".....", ".####", "#....", ".###.", "....#", "####.", ".....", "....."],
	"t": [".#..", ".#..", "###.", ".#..", ".#..", ".#..", "..##", "....", "...."],
	"u": [".....", ".....", "#...#", "#...#", "#...#", "#...#", ".####", ".....", "....."],
	"v": [".....", ".....", "#...#", "#...#", "#...#", ".#.#.", "..#..", ".....", "....."],
	"w": [".....", ".....", "#...#", "#...#", "#.#.#", "#.#.#", ".#.#.", ".....", "....."],
	"x": [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", ".....", "....."],
	"y": [".....", ".....", "#...#", "#...#", "#...#", "#...#", ".####", "....#", ".###."],
	"z": [".....", ".....", "#####", "...#.", "..#..", ".#...", "#####", ".....", "....."],
}
const ACCENTS := {
	"Ç": ["C", "ced"], "Ã": ["A", "til"], "Á": ["A", "agudo"], "Â": ["A", "circ"],
	"É": ["E", "agudo"], "Ê": ["E", "circ"], "Í": ["I", "agudo"], "Ó": ["O", "agudo"],
	"Ô": ["O", "circ"], "Õ": ["O", "til"], "Ú": ["U", "agudo"], "À": ["A", "grave"],
	# minúsculas: a marca desce 2 linhas (fica nas linhas 0..1, acima da altura-x)
	"á": ["a", "agudo"], "à": ["a", "grave"], "â": ["a", "circ"], "ã": ["a", "til"],
	"é": ["e", "agudo"], "ê": ["e", "circ"], "í": ["i", "agudo"], "ó": ["o", "agudo"],
	"ô": ["o", "circ"], "õ": ["o", "til"], "ú": ["u", "agudo"], "ç": ["c", "ced"],
}
const MARKS := {
	"agudo": {-2: "...#.", -1: "..#.."},
	"grave": {-2: ".#...", -1: "..#.."},
	"circ": {-2: "..#..", -1: ".#.#."},
	"til": {-2: ".##.#", -1: "#.##."},
	"ced": {7: "..#..", 8: ".##.."},
}

func _glyph_rows(ch: String) -> Dictionary:
	# devolve {linha: string}
	var out := {}
	var base := ch
	var mark := ""
	if ACCENTS.has(ch):
		base = ACCENTS[ch][0]
		mark = ACCENTS[ch][1]
	var g: Array = GLYPHS.get(base, [])
	for i in g.size():
		out[i] = g[i]
	if mark != "":
		var w: int = g[0].length()
		var off := (5 - w) / 2
		var m: Dictionary = MARKS[mark]
		var lower := base != base.to_upper()
		for row in m:
			var s: String = m[row]
			var r: int = row
			if lower and r < 0:
				r += 2
			out[r] = s.substr(off, w)
	return out

func glyph_w(ch: String) -> int:
	if ch == " ":
		return 3
	var base: String = ACCENTS[ch][0] if ACCENTS.has(ch) else ch
	if not GLYPHS.has(base):
		return 3
	return GLYPHS[base][0].length()

func text_w(s: String, scale := 1) -> int:
	var w := 0
	for i in s.length():
		w += (glyph_w(s[i]) + 1) * scale
	return maxi(w - scale, 0)

func _text_raw(img: Image, s: String, x: int, y: int, c: Color, scale: int) -> void:
	var cx := x
	for i in s.length():
		var ch := s[i]
		if ch != " ":
			var rows := _glyph_rows(ch)
			for row in rows:
				var line_s: String = rows[row]
				for j in line_s.length():
					if line_s[j] == "#":
						R(img, cx + j * scale, y + int(row) * scale, scale, scale, c)
		cx += (glyph_w(ch) + 1) * scale

## Escreve texto. shadow = sombra 1px embaixo; outline = contorno 8-vizinhos.
func text(img: Image, s: String, x: int, y: int, c, scale := 1, shadow = null, outline = null) -> int:
	if outline != null:
		for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
				Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]:
			_text_raw(img, s, x + d.x * scale / scale, y + d.y, col(outline), scale)
	elif shadow != null:
		_text_raw(img, s, x, y + 1, col(shadow), scale)
	_text_raw(img, s, x, y, col(c), scale)
	return text_w(s, scale)

func text_right(img: Image, s: String, xr: int, y: int, c, scale := 1, shadow = null) -> void:
	text(img, s, xr - text_w(s, scale), y, c, scale, shadow)

func text_center(img: Image, s: String, xc: int, y: int, c, scale := 1, shadow = null, outline = null) -> void:
	text(img, s, xc - text_w(s, scale) / 2, y, c, scale, shadow, outline)

# ---------------------------------------------------------------- UI
## Painel chanfrado: contorno ink, borda clara em cima/esquerda, escura embaixo/direita.
func panel(img: Image, x: int, y: int, w: int, h: int, bg = "d1", hi = "d2", lo = "ink") -> void:
	R(img, x, y, w, h, "ink")
	R(img, x + 1, y + 1, w - 2, h - 2, bg)
	R(img, x + 1, y + 1, w - 2, 1, hi)
	R(img, x + 1, y + 1, 1, h - 2, hi)
	R(img, x + 1, y + h - 2, w - 2, 1, lo)
	R(img, x + w - 2, y + 1, 1, h - 2, lo)

func button(img: Image, x: int, y: int, w: int, h: int, bg: String, label: String, fg = "white", scale := 1) -> void:
	R(img, x + 1, y + h, w - 1, 1, "ink")   # sombra de base (botão "alto")
	R(img, x, y, w, h, "ink")
	R(img, x + 1, y + 1, w - 2, h - 2, bg)
	R(img, x + 1, y + 1, w - 2, 1, shade(col(bg), 1))
	R(img, x + 1, y + h - 3, w - 2, 2, shade(col(bg), -1))
	var ty := y + (h - 7 * scale) / 2 - 1
	text_center(img, label, x + w / 2, ty, fg, scale, shade(col(bg), -2))

func bar(img: Image, x: int, y: int, w: int, h: int, frac: float, fill: String) -> void:
	R(img, x, y, w, h, "ink")
	R(img, x + 1, y + 1, w - 2, h - 2, "d2")
	var fw := int(round((w - 2) * clampf(frac, 0.0, 1.0)))
	if fw > 0:
		R(img, x + 1, y + 1, fw, h - 2, fill)
		R(img, x + 1, y + 1, fw, 1, shade(col(fill), 1))

func icon_coin(img: Image, x: int, y: int) -> void:
	ellipse(img, x + 4.5, y + 4.5, 4.5, 4.5, "ink")
	ellipse(img, x + 4.5, y + 4.5, 3.5, 3.5, "y0")
	ellipse(img, x + 4.0, y + 4.0, 2.5, 2.5, "y1")
	R(img, x + 4, y + 2, 1, 5, "br2")
	P(img, x + 3, y + 3, "y2")

func icon_star(img: Image, x: int, y: int, c := "p2") -> void:
	var rows := ["....#....", "...###...", "#########", ".#######.", "..#####..", ".###.###.", ".##...##."]
	for i in rows.size():
		for j in rows[i].length():
			if rows[i][j] == "#":
				P(img, x + j, y + i + 1, c)

func icon_bolt(img: Image, x: int, y: int, c := "gr3") -> void:
	var rows := ["...##", "..##.", ".##..", "#####", "..##.", ".##..", "##..."]
	for i in rows.size():
		for j in rows[i].length():
			if rows[i][j] == "#":
				P(img, x + j + 1, y + i + 1, c)

func icon_skull(img: Image, x: int, y: int, c := "cream") -> void:
	var rows := [".#####.", "#######", "#.###.#", "#######", ".#####.", ".#.#.#."]
	for i in rows.size():
		for j in rows[i].length():
			if rows[i][j] == "#":
				P(img, x + j + 1, y + i + 1, c)

# ---------------------------------------------------------------- sprites
## Luva de boxe (w x h) arredondada com brilho.
func glove(img: Image, x: int, y: int, w: int, h: int, ramp: Array) -> void:
	var dk = ramp[0]
	var md = ramp[1]
	var lt = ramp[2]
	rrect(img, x, y, w, h, md)
	R(img, x, y + h - 2, w, 1, dk)
	R(img, x + 1, y + h - 1, w - 2, 1, dk)
	R(img, x, y + 1, 1, h - 3, dk)
	R(img, x + w - 4, y + 1, 2, 1, lt)
	R(img, x + w - 2, y + 2, 1, 2, lt)
	R(img, x + 2, y + 3, 1, 3, dk)        # polegar
	R(img, x + 1, y + h - 1, w - 2, 1, "white")  # punho
	R(img, x + 1, y + h - 2, w - 2, 1, "cream")

## Lutador placeholder ~64px, de frente/3/4 virado para a direita, guarda alta.
## o: shirt=[d,m,l], shorts=[d,m,l], gloves=[d,m,l] ou [], hair=[d,l]
func fighter(o := {}) -> Image:
	var W := 44
	var H := 72
	var shirt: Array = o.get("shirt", ["cream", "white", "white"])
	var shorts: Array = o.get("shorts", ["b0", "b1", "b2"])
	var gl: Array = o.get("gloves", ["r0", "r1", "r2"])
	var hair: Array = o.get("hair", ["br0", "br1"])
	var out := blank(W, H)
	# perna de trás
	var L := blank(W, H)
	R(L, 13, 50, 6, 13, "sk1"); R(L, 13, 50, 2, 13, "sk0")
	R(L, 9, 63, 10, 4, "d2"); R(L, 9, 63, 10, 1, "g1"); R(L, 9, 67, 10, 1, "cream")
	stamp(out, L, 0, 0)
	# braço de trás
	L = blank(W, H)
	R(L, 10, 23, 5, 10, "sk0"); R(L, 12, 22, 4, 12, "sk0"); R(L, 13, 20, 3, 2, "cream")
	if gl.size() > 0:
		glove(L, 10, 11, 9, 10, [shade(col(gl[0]), -1), gl[0], gl[1]])
	else:
		rrect(L, 12, 15, 5, 5, "sk0")
	stamp(out, L, 0, 0)
	# corpo (regata + calção)
	L = blank(W, H)
	R(L, 11, 22, 18, 4, "sk1"); R(L, 26, 22, 3, 3, "sk2")
	R(L, 13, 22, 14, 18, shirt[1])
	R(L, 15, 22, 2, 2, "sk1"); R(L, 23, 22, 2, 2, "sk1")   # cava da regata
	R(L, 13, 24, 2, 16, shirt[0]); R(L, 26, 25, 1, 15, shirt[2])
	R(L, 18, 28, 1, 6, shirt[0])
	R(L, 12, 39, 17, 11, shorts[1]); R(L, 12, 39, 17, 2, shorts[2])
	R(L, 12, 41, 2, 9, shorts[0]); R(L, 27, 41, 1, 9, shorts[2])
	R(L, 20, 46, 1, 4, shorts[0])
	stamp(out, L, 0, 0)
	# perna da frente
	L = blank(W, H)
	R(L, 22, 50, 6, 13, "sk1"); R(L, 27, 51, 1, 10, "sk2"); R(L, 22, 50, 1, 13, "sk0")
	R(L, 22, 63, 11, 4, "d2"); R(L, 22, 63, 11, 1, "g2"); R(L, 22, 67, 11, 1, "cream")
	stamp(out, L, 0, 0)
	# cabeça
	L = blank(W, H)
	R(L, 18, 18, 5, 5, "sk0")
	R(L, 16, 7, 10, 11, "sk1"); R(L, 17, 18, 8, 1, "sk1"); R(L, 18, 19, 6, 1, "sk1")
	R(L, 16, 8, 1, 9, "sk0"); R(L, 25, 9, 1, 6, "sk2"); R(L, 24, 8, 1, 3, "sk2")
	R(L, 26, 12, 1, 2, "sk1")                      # nariz
	R(L, 15, 3, 11, 5, hair[0]); R(L, 14, 5, 3, 6, hair[0]); R(L, 17, 3, 6, 1, hair[1])
	R(L, 18, 4, 3, 1, hair[1])
	R(L, 17, 11, 2, 3, "sk0"); P(L, 18, 12, "sk1")  # orelha
	R(L, 22, 10, 3, 1, hair[0])                    # sobrancelha
	R(L, 23, 11, 1, 2, "ink")                      # olho
	R(L, 23, 16, 2, 1, "sk0")                      # boca
	stamp(out, L, 0, 0)
	# braço da frente
	L = blank(W, H)
	R(L, 27, 23, 5, 10, "sk1"); R(L, 31, 24, 1, 8, "sk2")
	R(L, 29, 21, 4, 12, "sk1"); R(L, 29, 20, 4, 2, "white")
	if gl.size() > 0:
		glove(L, 27, 10, 10, 11, gl)
	else:
		rrect(L, 29, 15, 5, 6, "sk1")
	stamp(out, L, 0, 0)
	return out

func save_scaled(img: Image, path_base: String, factor: int) -> void:
	DirAccess.make_dir_recursive_absolute(path_base.get_base_dir())
	img.save_png(path_base + "_base.png")
	var big := img.duplicate()
	big.resize(img.get_width() * factor, img.get_height() * factor, Image.INTERPOLATE_NEAREST)
	big.save_png(path_base + "_x%d.png" % factor)

# ---------------------------------------------------------------- UI da tela principal (mockup)
## Layout 640x360: HUD 0..17 | painel esquerdo 0..127 | sala 128..511 | painel direito 512..639 | barra 290..359.
const SCENE := Rect2i(128, 18, 384, 272)

func game_ui(img: Image, d: Dictionary) -> void:
	# ---- HUD de cima
	panel(img, 0, 0, 640, 18, "d1", "d2", "ink")
	icon_coin(img, 5, 4)
	text(img, d.money, 18, 6, "y1", 1, "ink")
	icon_bolt(img, 92, 4)
	var w := text(img, d.treino, 104, 6, "gr3", 1, "ink")
	text(img, d.treino_s, 104 + w + 6, 6, "gr2", 1, "ink")
	icon_star(img, 236, 3)
	text(img, d.fama, 249, 6, "p2", 1, "ink")
	text_right(img, d.local, 634, 6, "cream", 1, "ink")
	# ---- painel esquerdo: lutador
	panel(img, 0, 18, 128, 272)
	R(img, 2, 20, 124, 12, "d2")
	text(img, "LUTADOR", 6, 23, "cream", 1, "ink")
	text_right(img, d.carreira, 123, 23, "g3", 1, "ink")
	var y := 38
	var attrs: Array = d.attrs
	for a in attrs:
		text(img, a[0], 6, y, a[3] if a.size() > 3 else "white", 1, "ink")
		text_right(img, a[1], 122, y, "white", 1, "ink")
		bar(img, 6, y + 10, 116, 5, a[2], a[4] if a.size() > 4 else "r2")
		y += 22
	R(img, 6, y + 2, 116, 1, "d2")
	y += 8
	text(img, "LEGADO EM JOGO", 6, y, "g3", 1, "ink")
	icon_skull(img, 4, y + 10, "p2")
	text(img, d.legado, 16, y + 11, "p2", 1, "ink")
	y += 26
	# card da próxima luta
	panel(img, 4, y, 120, 286 - y, "d2", "g0", "d1")
	text(img, "PRÓXIMA LUTA", 9, y + 5, "cream", 1, "ink")
	var cy := y + 16
	# silhueta do adversário (placeholder)
	R(img, 9, cy, 30, 34, "d1")
	ellipse(img, 24, cy + 9, 6, 6, "ink")
	R(img, 15, cy + 15, 18, 19, "ink")
	text(img, "?", 22, cy + 6, "g1")
	text(img, d.adv, 44, cy + 1, "white", 1, "ink")
	text(img, d.adv2, 44, cy + 12, "g3", 1, "ink")
	var rw := text(img, "RISCO", 44, cy + 25, "g3", 1, "ink")
	R(img, 44, cy + 33, rw, 1, "d1")
	text(img, d.risco, 9, cy + 41, d.risco_cor, 1, "ink")
	# comparação ELE x VOCÊ (prévia da luta)
	var ty2 := cy + 55
	text(img, "ELE", 62, ty2, "g2", 1, "ink")
	text_right(img, "VOCÊ", 120, ty2, "g2", 1, "ink")
	ty2 += 11
	var cmp: Array = d.get("cmp", [])
	for c in cmp:
		text(img, c[0], 9, ty2, "g3", 1, "ink")
		var his: int = c[1]
		var mine: int = c[2]
		text(img, str(his), 62, ty2, "r2" if his > mine else "white", 1, "ink")
		text_right(img, str(mine), 120, ty2, "gr3" if mine >= his else "white", 1, "ink")
		ty2 += 11
	# ---- painel direito: loja
	panel(img, 512, 18, 128, 272)
	R(img, 514, 20, 62, 12, "d2"); R(img, 576, 20, 62, 12, "d1")
	R(img, 514, 31, 124, 1, "ink")
	text_center(img, "EQUIPE", 545, 23, "y1", 1, "ink")
	text_center(img, "ITENS", 607, 23, "g2", 1, "ink")
	y = 36
	var shop: Array = d.shop
	for it in shop:
		var locked: bool = it.get("locked", false)
		panel(img, 516, y, 120, 34, "d2" if not locked else "d1", "g0" if not locked else "d2", "d1")
		R(img, 520, y + 4, 18, 18, "ink"); R(img, 521, y + 5, 16, 16, it.get("icon", "g0"))
		if locked:
			text(img, "?", 527, y + 9, "g1")
			text(img, "BLOQUEADO", 542, y + 6, "g1", 1, "ink")
			text(img, it.get("req", ""), 542, y + 19, "g0", 1, "ink")
		else:
			ellipse(img, 529, y + 11, 4, 4, it.get("icon2", "g2"))
			R(img, 525, y + 15, 8, 6, it.get("icon2", "g2"))
			text(img, it.name, 542, y + 5, "white", 1, "ink")
			text(img, it.prod, 542, y + 15, "gr3", 1, "ink")
			text(img, it.qty, 523, y + 25, "g3", 1, "ink")
			var can: bool = it.get("can", true)
			var pw := text_w(it.cost) + 8
			R(img, 633 - pw, y + 23, pw, 9, "ink")
			R(img, 634 - pw, y + 24, pw - 2, 7, "gr1" if can else "d1")
			text(img, it.cost, 637 - pw, y + 24, "y1" if can else "r2")
		y += 37
	# melhorias de aparelho + mudança de local
	text(img, "MELHORIAS", 518, y + 2, "cream", 1, "ink")
	y += 12
	var ups: Array = d.ups
	for u in ups:
		R(img, 516, y, 120, 13, "d2")
		R(img, 518, y + 2, 9, 9, "ink"); R(img, 519, y + 3, 7, 7, u[2])
		text(img, u[0], 530, y + 3, "white", 1, "ink")
		text_right(img, u[1], 634, y + 3, u[3] if u.size() > 3 else "y1", 1, "ink")
		y += 15
	panel(img, 516, 252, 120, 34, "d1", "d2", "ink")
	text(img, "PRÓXIMO LOCAL", 521, 256, "g3", 1, "ink")
	text(img, d.prox_local, 521, 266, "cream", 1, "ink")
	text(img, d.prox_req, 521, 276, "r2", 1, "ink")
	# ---- barra de baixo
	panel(img, 0, 290, 640, 70)
	text(img, "POR CLIQUE", 8, 296, "g3", 1, "ink")
	text(img, d.clique, 8, 308, "y1", 2, "ink")
	text(img, "AUTO " + d.treino_s, 8, 330, "gr2", 1, "ink")
	text(img, "FOCO DE TREINO", 8, 342, "g2", 1, "ink")
	var focos: Array = d.focos
	var n := focos.size()
	var gap := 4
	var bw := (372 - gap * (n - 1)) / n
	var x := 134
	for i in n:
		var f: Array = focos[i]
		var sel: bool = f[3]
		var bg: String = f[2] if sel else "d2"
		R(img, x + 1, 330, bw - 1, 1, "ink")
		R(img, x, 296, bw, 34, "ink")
		R(img, x + 1, 297, bw - 2, 32, bg)
		R(img, x + 1, 297, bw - 2, 1, shade(col(bg), 1))
		R(img, x + 1, 327, bw - 2, 2, shade(col(bg), -1))
		text_center(img, f[0], x + bw / 2, 303, "white" if sel else "cream", 1, "ink")
		text_center(img, f[1], x + bw / 2, 315, "y2" if sel else "g2", 1, "ink")
		if sel:
			R(img, x + 2, 332, bw - 4, 2, f[2])
		x += bw + gap
	text_center(img, d.dica, 320, 342, "g2", 1, "ink")
	button(img, 518, 295, 116, 38, "r1", "LUTAR!", "y2", 2)
	button(img, 518, 338, 116, 16, "d2", "APOSENTAR", "g3", 1)

# ---------------------------------------------------------------- Fase 2: personagem por poses
## Personagem articulado PLACEHOLDER. Cada parte (perna de trás, braço de trás, tronco,
## perna da frente, cabeça, braço da frente) é desenhada numa camada própria e ganha
## contorno ink próprio, como um rig. Os membros são "cápsulas" entre pontos da pose
## (nada de rotação de sprite: cada quadro é redesenhado na grade).
## Quadro padrão: 48x72, virado para a direita, pés (sola) na linha 67, centro x=22.
const CHAR_W := 48
const CHAR_H := 72

## Pose de guarda (base). Pontos em pixels do quadro.
const POSE_GUARD := {
	"dy": 0, "hy": 0, "lean": 0, "lift": 0,
	"bhip": Vector2(17, 49), "fhip": Vector2(26, 49),
	"bknee": Vector2(16, 57), "bfoot": Vector2(15, 63),
	"fknee": Vector2(26, 57), "ffoot": Vector2(26, 63),
	"bsh": Vector2(15, 25), "belb": Vector2(12, 31), "bhand": Vector2(14, 16),
	"fsh": Vector2(29, 24), "felb": Vector2(31, 31), "fhand": Vector2(32, 15),
}

func pose(over := {}) -> Dictionary:
	var p := POSE_GUARD.duplicate()
	for k in over:
		p[k] = over[k]
	return p

## Cápsula (membro) de a até b, espessura w, rampa [escuro, base, claro]. Luz de cima/direita.
func capsule(img: Image, a: Vector2, b: Vector2, w: float, ramp: Array, lit := true) -> void:
	a += Vector2(0.5, 0.5)
	b += Vector2(0.5, 0.5)
	var r := w / 2.0
	var d := b - a
	var l2 := d.length_squared()
	var dn := d.normalized() if l2 > 0.0001 else Vector2(0, 1)
	var n := Vector2(-dn.y, dn.x)
	if n.x - n.y < 0.0:
		n = -n
	for y in range(int(floor(minf(a.y, b.y) - r - 1)), int(ceil(maxf(a.y, b.y) + r + 1))):
		for x in range(int(floor(minf(a.x, b.x) - r - 1)), int(ceil(maxf(a.x, b.x) + r + 1))):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := 0.0 if l2 < 0.0001 else clampf((p - a).dot(d) / l2, 0.0, 1.0)
			var v := p - (a + d * t)
			if v.length() <= r:
				var s := v.dot(n)
				var c = ramp[1]
				if s < -r + 1.25:
					c = ramp[0]
				elif lit and w >= 4.0 and s > r - 1.0:
					c = ramp[2]
				P(img, x, y, c)

## Luva (mesma arte na mão, no cursor e no ícone). old = luva velha: punho encardido e fita.
func glove2(img: Image, x: int, y: int, w: int, h: int, ramp: Array, old := true) -> void:
	glove(img, x, y, w, h, ramp)
	if old:
		R(img, x + 1, y + h - 2, w - 2, 1, "g3")          # punho encardido
		R(img, x + 1, y + h - 1, w - 2, 1, "cream")
		R(img, x + 3, y + 1, 1, 2, "g3")                  # fita de remendo no dorso
		R(img, x + 4, y + 1, 1, 2, "cream")

func _shoe(img: Image, foot: Vector2, style: String, skin: Array) -> void:
	var x := int(foot.x) - 3
	var y := int(foot.y)
	match style:
		"chinelo":
			R(img, x, y + 1, 9, 3, skin[1]); R(img, x, y + 1, 9, 1, skin[2]); R(img, x + 7, y + 2, 2, 2, skin[0])
			R(img, x - 1, y + 4, 11, 1, "b1")             # sola do chinelo
			R(img, x + 5, y + 1, 1, 3, "b2")              # tira
		"sapato":
			R(img, x, y, 10, 4, "br1"); R(img, x, y, 10, 1, "br2"); R(img, x + 7, y + 1, 2, 1, "br3")
			R(img, x, y + 4, 10, 1, "br0")
		_:
			R(img, x, y, 10, 4, "d2"); R(img, x, y, 10, 1, "g1"); R(img, x + 6, y + 1, 3, 1, "g0")
			R(img, x, y + 4, 10, 1, "cream")

## o: skin=[d,m,l], shirt=[d,m,l], shorts=[d,m,l], gloves=[d,m,l] ou [], hair=[d,l],
##    top="tank"|"social", bottom="shorts"|"pants", shoes="tenis"|"chinelo"|"sapato",
##    head="short"|"bald"|"cap"|"tall", cap=[d,m,l], belly=int, mustache=cor
func character(o: Dictionary, p: Dictionary) -> Image:
	var skin: Array = o.get("skin", ["sk0", "sk1", "sk2"])
	var shirt: Array = o.get("shirt", ["cream", "white", "white"])
	var shorts: Array = o.get("shorts", ["b0", "b1", "b2"])
	var gl: Array = o.get("gloves", ["r0", "r1", "r2"])
	var hair: Array = o.get("hair", ["br0", "br1"])
	var top: String = o.get("top", "tank")
	var bottom: String = o.get("bottom", "shorts")
	var shoes: String = o.get("shoes", "tenis")
	var belly: int = o.get("belly", 0)
	var dy: int = p.dy
	var lx: int = p.lean
	var U := Vector2(lx, dy)                    # deslocamento do tronco
	var skin_bk := [shade(col(skin[0]), -1), skin[0], skin[1]]
	var out := blank(CHAR_W, CHAR_H)
	var L: Image
	# ---- perna de trás
	L = blank(CHAR_W, CHAR_H)
	_leg(L, p.bhip + U, p.bknee, p.bfoot, skin_bk, [shade(col(shorts[0]), -1), shorts[0], shorts[1]], bottom)
	_shoe(L, p.bfoot, shoes, skin_bk)
	stamp(out, L, 0, 0)
	# ---- braço de trás (na sombra)
	L = blank(CHAR_W, CHAR_H)
	_arm(L, p.bsh + U, p.belb + U, p.bhand + U, skin_bk, shirt, top, true)
	if gl.size() > 0:
		if o.has("glove_fn"):   # Fase 3: luva de loja desenhada por função própria
			o.glove_fn.call(L, int(p.bhand.x + U.x) - 4, int(p.bhand.y + U.y) - 5, 9, 10, true)
		else:
			glove2(L, int(p.bhand.x + U.x) - 4, int(p.bhand.y + U.y) - 5, 9, 10, [shade(col(gl[0]), -1), gl[0], gl[1]])
	else:
		_fist(L, p.bhand + U, skin_bk)
	stamp(out, L, 0, 0)
	# ---- tronco + calção/calça
	L = blank(CHAR_W, CHAR_H)
	var tx := 13 + lx
	var ty := 22 + dy
	if top == "tank":
		R(L, tx - 2, ty, 18, 4, skin[1]); R(L, tx + 13, ty, 3, 3, skin[2])
		R(L, tx, ty, 14, 18, shirt[1])
		R(L, tx + 2, ty, 2, 2, skin[1]); R(L, tx + 10, ty, 2, 2, skin[1])
		R(L, tx, ty + 2, 2, 16, shirt[0]); R(L, tx + 13, ty + 3, 1, 15, shirt[2])
		R(L, tx + 5, ty + 6, 1, 6, shirt[0])
	else:   # camisa social: ombro coberto, gola, botões, barriga
		R(L, tx - 1, ty, 16, 18, shirt[1])
		R(L, tx - 1, ty, 2, 18, shirt[0])
		if belly > 0:
			R(L, tx + 15, ty + 7, belly, 10, shirt[1]); R(L, tx + 14 + belly, ty + 8, 1, 8, shirt[2])
		R(L, tx + 5, ty - 1, 5, 2, "white"); R(L, tx + 7, ty, 1, 2, skin[0])   # gola
		for i in 4:
			P(L, tx + 8 + (1 if i > 1 and belly > 0 else 0), ty + 4 + i * 3, shirt[0])
		R(L, tx - 1, ty + 16, 16 + belly, 2, shirt[0])
	if bottom == "pants":
		R(L, tx - 1, ty + 17, 17 + belly, 10 - dy, shorts[1]); R(L, tx - 1, ty + 17, 17 + belly, 1, "br0")  # cinto
		R(L, tx + 8, ty + 17, 3, 1, "y0")
		R(L, tx - 1, ty + 18, 2, 9 - dy, shorts[0])
	else:
		R(L, tx - 1, ty + 17, 17, 11 - dy, shorts[1]); R(L, tx - 1, ty + 17, 17, 2, shorts[2])
		R(L, tx - 1, ty + 19, 2, 9 - dy, shorts[0]); R(L, tx + 14, ty + 19, 1, 9 - dy, shorts[2])
		R(L, tx + 7, ty + 24, 1, 4 - dy, shorts[0])
	stamp(out, L, 0, 0)
	# ---- perna da frente
	L = blank(CHAR_W, CHAR_H)
	_leg(L, p.fhip + U, p.fknee, p.ffoot, skin, shorts, bottom)
	_shoe(L, p.ffoot, shoes, skin)
	stamp(out, L, 0, 0)
	# ---- cabeça
	L = blank(CHAR_W, CHAR_H)
	_head(L, lx, dy + int(p.hy), o, skin, hair)
	stamp(out, L, 0, 0)
	# ---- braço da frente
	L = blank(CHAR_W, CHAR_H)
	_arm(L, p.fsh + U, p.felb + U, p.fhand + U, skin, shirt, top, false)
	if gl.size() > 0:
		if o.has("glove_fn"):
			o.glove_fn.call(L, int(p.fhand.x + U.x) - 5, int(p.fhand.y + U.y) - 5, 10, 11, false)
		else:
			glove2(L, int(p.fhand.x + U.x) - 5, int(p.fhand.y + U.y) - 5, 10, 11, gl)
	else:
		_fist(L, p.fhand + U, skin)
	stamp(out, L, 0, 0)
	# ---- pulo: o corpo inteiro sobe
	var lift: int = p.lift
	if lift != 0:
		var o2 := blank(CHAR_W, CHAR_H)
		o2.blit_rect(out, Rect2i(0, 0, CHAR_W, CHAR_H), Vector2i(0, -lift))
		out = o2
	return out

func _leg(L: Image, hip: Vector2, knee: Vector2, foot: Vector2, skin: Array, cloth: Array, bottom: String) -> void:
	if bottom == "pants":
		capsule(L, hip, knee, 7, cloth)
		capsule(L, knee, foot + Vector2(0, 1), 6, cloth)
	else:
		capsule(L, knee, foot, 5, skin)
		capsule(L, hip, knee, 6, skin)
		capsule(L, hip, hip.lerp(knee, 0.55), 7, cloth)

func _arm(L: Image, sh: Vector2, el: Vector2, hand: Vector2, skin: Array, shirt: Array, top: String, back: bool) -> void:
	if top == "social":
		var sl: Array = [shade(col(shirt[0]), -1), shirt[0], shirt[1]] if back else shirt
		capsule(L, sh, el, 5, sl)
		capsule(L, el, hand, 5, sl)
		capsule(L, hand.lerp(el, 0.25), hand, 4, skin)
	else:
		capsule(L, sh, el, 5, skin)
		capsule(L, el, hand, 4, skin)

func _fist(L: Image, hand: Vector2, skin: Array) -> void:
	var x := int(hand.x) - 2
	var y := int(hand.y) - 2
	rrect(L, x, y, 6, 5, skin[1]); R(L, x, y + 3, 6, 1, skin[0]); R(L, x + 4, y, 1, 2, skin[2])
	R(L, x + 1, y + 4, 4, 1, "cream")   # faixa no pulso

func _head(L: Image, lx: int, dy: int, o: Dictionary, skin: Array, hair: Array) -> void:
	var x := lx
	var y := dy
	var style: String = o.get("head", "short")
	R(L, x + 18, y + 18, 5, 5, skin[0])                               # pescoço
	R(L, x + 16, y + 7, 10, 11, skin[1]); R(L, x + 17, y + 18, 8, 1, skin[1]); R(L, x + 18, y + 19, 6, 1, skin[1])
	R(L, x + 16, y + 8, 1, 9, skin[0]); R(L, x + 25, y + 9, 1, 6, skin[2]); R(L, x + 24, y + 8, 1, 3, skin[2])
	R(L, x + 26, y + 12, 1, 2, skin[1])                               # nariz
	match style:
		"bald":
			R(L, x + 16, y + 5, 9, 3, skin[1]); R(L, x + 18, y + 4, 6, 1, skin[1]); R(L, x + 20, y + 5, 3, 1, skin[2])
			R(L, x + 15, y + 8, 3, 6, hair[1]); R(L, x + 15, y + 8, 1, 6, hair[0])   # cabelo grisalho dos lados
			R(L, x + 21, y + 9, 3, 1, hair[1])                                       # sobrancelha grisalha
		"cap":
			R(L, x + 14, y + 6, 3, 5, hair[0])
			var cp: Array = o.get("cap", ["b0", "b1", "b2"])
			R(L, x + 15, y + 2, 11, 6, cp[1]); R(L, x + 15, y + 2, 11, 1, cp[2]); R(L, x + 15, y + 6, 11, 1, cp[0])
			R(L, x + 11, y + 6, 5, 2, cp[0])                                         # aba virada para trás
			R(L, x + 22, y + 10, 3, 1, hair[0])
		"tall":
			R(L, x + 15, y + 1, 11, 7, hair[0]); R(L, x + 14, y + 4, 3, 7, hair[0]); R(L, x + 17, y + 1, 7, 1, hair[1])
			R(L, x + 19, y + 2, 3, 1, hair[1])
			R(L, x + 22, y + 10, 3, 1, hair[0])
		_:
			R(L, x + 15, y + 3, 11, 5, hair[0]); R(L, x + 14, y + 5, 3, 6, hair[0]); R(L, x + 17, y + 3, 6, 1, hair[1])
			R(L, x + 18, y + 4, 3, 1, hair[1])
			R(L, x + 22, y + 10, 3, 1, hair[0])
	R(L, x + 17, y + 11, 2, 3, skin[0]); P(L, x + 18, y + 12, skin[1])  # orelha
	R(L, x + 23, y + 11, 1, 2, "ink")                                   # olho
	if o.has("mustache"):
		R(L, x + 22, y + 15, 4, 1, o.mustache)
		R(L, x + 23, y + 16, 2, 1, skin[0])
	else:
		R(L, x + 23, y + 16, 2, 1, skin[0])                             # boca
