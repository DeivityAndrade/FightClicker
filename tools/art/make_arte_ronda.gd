extends SceneTree
## Ronda Noturna do Gato Preto (Diretor de Arte). PLACEHOLDER gerado por código, tudo original.
## Rodar de uma pasta com project.godot vazio (não dispara import no projeto), headless:
##   godot --headless --max-fps 30 --path <pasta_vazia> --script <worktree>/tools/art/make_arte_ronda.gd -- --root <worktree>
##   ... -- --root <worktree> --no-assets          (só os mockups)
##   ... -- --root <worktree> --caps <pasta>        (opcional: capturas do ui_audit com a sala cheia; o mockup do capuz cola nelas)
## Depois: python tools/art/manifest_ronda.py (lê tools/art/ronda_sprites.json, que este script grava).
## Grava:
##   assets/sprites/minigame/ronda_bg.png + ronda_layer_graffiti|banner|kid_ears|whole_street.png (camadas da lenda, 640x360)
##   assets/sprites/minigame/ronda_prop_tire|pliers|crowbar.png (o que o ladrão larga no SUSTO)
##   assets/sprites/garage/hood_on_nail.png, gym/hood_on_nail_gym.png (capuz no prego; o centro usa o da academia)
##   assets/sprites/garage/wall_clipping_black_cat_l1..l5.png, gym/wall_clipping_black_cat_gym_l1..l5.png (recorte por nível)
##   assets/sprites/ui/ui_clipping_black_cat_zoom_l1..l5.png (recorte grande do hover)
##   assets/sprites/ui/ HUD da Ronda, letreiros, ícone da LENDA; ui/ e ui/map/ região GATO PRETO e os 3 nós
##   docs/arte/mockups/ronda_*.png
## Pontos e contrato da tela: constantes abaixo = minigame_layout.ronda no manifest (manifest_ronda.py). Mudar nos dois.

# ---------------------------------------------------------------- textos provisórios [ROT] (o Roteirista confirma)
const TXT_SMALL := [["VULTO", ""], ["GATO", "PRETO"], ["GATO", "VOLTA"], ["VALEU", "GATO"], ["GATO", "MANIA"], ["UMA", "MÃO!"]]
const TXT_ZOOM := [
	["", ""],
	["O VULTO TEM NOME:", "GATO PRETO"],
	["3 LADRÕES, 1 NOITE:", "VOLTOU!"],
	["O BAIRRO AGRADECE:", "VALEU!"],
	["CRIANÇADA DE ORELHA:", "GATOMANIA"],
	["PAROU ÔNIBUS COM", "UMA MÃO!"],
]
const TXT_MAST := "CORREIO DA ESQUINA"
const TXT_BANNER_STREET := "VALEU, GATO PRETO"     # faixa da rua (escopo §4, nível 3)
const TXT_SCARE := "SUSTO!"
const TXT_ESCAPED := "ESCAPOU"
## cor da faixa do vulto (a mesma da folha do Artista de Personagens: vermelha). Trocar aqui troca em tudo (capuz, ícones, camadas).
const BAND := "r2"
const BAND_HI := "r3"
const BAND_LO := "r1"

var ROOT := ""
var OUT := ""
var MOCK := ""
var CAPS := ""
var NO_ASSETS := false
var SO_CAPUZ := false   # B5 (Ronda 2a1): refaz só hood_on_nail / hood_on_nail_gym (nada mais é gravado)
var L
var MAN := {}
var F := {}      # id -> Array[Image]
var META := {}   # id -> {rel, frame_size, frames, fps, pivot}
var CHECKS := []

# ---------------------------------------------------------------- contrato da tela (1x, 640x360)
const HUD_H := 36                 # y 0..35: céu escuro, HUD
const WALK_Y := 196               # pés do vulto em cima do muro/marquise (os 3 trechos)
const BASE_Y := 262               # pé das fachadas (começo da calçada)
const THIEF_Y := 314              # pés dos ladrões na calçada
const CURB_Y := 330               # meio-fio; y 336..359 asfalto (SAIR e a instrução ficam aqui)
const TRACK_Y := 206              # barra de distância: logo embaixo da capa do muro (6 px)
## Trechos: vulto anda de start a end (pés, y WALK_Y); ladrão em thief (pés), de costas = virado para a direita;
## land = onde o vulto cai no SUSTO; prop = onde fica o objeto que voa (estepe no chão; alicate e pé de cabra na mão).
const OCC := {
	"tire": {"start": 26, "end": 146, "thief": Vector2i(192, THIEF_Y), "land": Vector2i(166, THIEF_Y), "prop": Vector2i(212, 314),
		"light": Vector2i(196, 308), "name": "borracharia"},
	"bike": {"start": 256, "end": 346, "thief": Vector2i(392, THIEF_Y), "land": Vector2i(366, THIEF_Y), "prop": Vector2i(408, 288),
		"light": Vector2i(400, 306), "name": "bicicleta"},
	"gate": {"start": 494, "end": 546, "thief": Vector2i(592, THIEF_Y), "land": Vector2i(566, THIEF_Y), "prop": Vector2i(606, 282),
		"light": Vector2i(590, 306), "name": "portao"},
}
const OCC_ORDER := ["tire", "bike", "gate"]
const MOON := Vector2i(552, 70)
const MOON_R := 24
const ROOF_POSE := Vector2i(552, 114)   # pés do vulto em pé no telhado da casa 3, contra a lua (pose do Artista)
const LAMP_X := 226                      # poste (calçada): entre o trecho 1 e o 2, fora do caminho do vulto
# fachadas (x)
const A_END := 176        # muro do terreno baldio x 0..175
const B_END := 372        # borracharia x 176..371 (marquise x 228..371)
const MARQ_X := 228
const C_END := 470        # casa 2 (sobrado) x 372..469
const PILLAR := Rect2i(572, 184, 10, 78)   # pilar do portão (com a luminária em cima)
const GATE := Rect2i(582, 198, 58, 64)

# ---------------------------------------------------------------- sala (capuz)
const HOOD_SIZE := Vector2i(16, 22)
const HOOD_PIVOT := Vector2i(8, 1)            # cabeça do prego
const HOOD_SPOT := Vector2i(352, 95)          # garagem, academia e centro: o mesmo prego (pivô)
const CLIP_SIZE := Vector2i(23, 28)
const ZOOM_SIZE := Vector2i(128, 96)

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	ROOT = ProjectSettings.globalize_path("res://")
	for i in args.size():
		if args[i] == "--root" and i + 1 < args.size():
			ROOT = args[i + 1]
		if args[i] == "--caps" and i + 1 < args.size():
			CAPS = args[i + 1].trim_suffix("/") + "/"
		if args[i] == "--no-assets":
			NO_ASSETS = true
		if args[i] == "--so-capuz":
			SO_CAPUZ = true
	ROOT = ROOT.replace("\\", "/")
	if not ROOT.ends_with("/"):
		ROOT += "/"
	OUT = ROOT + "assets/sprites/"
	MOCK = ROOT + "docs/arte/mockups/"
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var f := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.READ)
	MAN = JSON.parse_string(f.get_as_text())
	f.close()
	if SO_CAPUZ:
		make_hood()
		print("ronda: só o capuz no prego ", META.keys())
		quit()
		return
	make_street()
	make_props()
	make_hud()
	make_hood()
	make_clippings()
	make_map()
	if not NO_ASSETS:
		var fo := FileAccess.open(ROOT + "tools/art/ronda_sprites.json", FileAccess.WRITE)
		fo.store_string(JSON.stringify(META, "\t", true))
		fo.close()
	mock_screens()
	mock_levels()
	mock_points()
	mock_hood_rooms()
	mock_clippings()
	mock_pieces()
	check_street()
	check_hood()
	for c in CHECKS:
		print(c)
	print("ronda: ", META.size(), " sprites", " (não gravados)" if NO_ASSETS else "", "; mockups em ", MOCK)
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

func load_png(p: String) -> Image:
	var im := Image.load_from_file(p)
	if im == null:
		return null
	im.convert(Image.FORMAT_RGBA8)
	return im

func spr(id: String) -> Dictionary:
	return MAN.sprites.get(id, {})

func res_abs(r: String) -> String:
	return ROOT + r.replace("res://", "")

var _cache := {}
func frame_of(id: String, q := 0) -> Image:
	var key := "%s#%d" % [id, q]
	if _cache.has(key):
		return _cache[key]
	var out: Image
	if F.has(id):
		out = F[id][clampi(q, 0, F[id].size() - 1)]
	else:
		var e := spr(id)
		var img := load_png(res_abs(str(e.file)))
		var fw := int(e.frame_size[0])
		var fh := int(e.frame_size[1])
		var n := maxi(img.get_width() / fw, 1)
		out = img.get_region(Rect2i(clampi(q, 0, n - 1) * fw, 0, fw, fh))
	_cache[key] = out
	return out

func pivot_of(id: String) -> Vector2i:
	if META.has(id):
		return Vector2i(int(META[id].pivot[0]), int(META[id].pivot[1]))
	var e := spr(id)
	return Vector2i(int(e.pivot[0]), int(e.pivot[1])) if e.has("pivot") else Vector2i.ZERO

func blend(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func put(dst: Image, src: Image, pos: Vector2i, pivot: Vector2i) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), pos - pivot)

func scaled(src: Image, k: int) -> Image:
	var s: Image = src.duplicate()
	s.resize(src.get_width() * k, src.get_height() * k, Image.INTERPOLATE_NEAREST)
	return s

func label(img: Image, s: String, x: int, y: int, c := "white") -> void:
	L.text(img, s, x, y, c, 1, "ink")

func color_name(c: Color) -> String:
	var hx := c.to_html(false)
	for k in L.PAL_HEX:
		if L.PAL_HEX[k] == hx:
			return k
	return ""

func bayer(x: int, y: int) -> float:
	return (L.BAYER[posmod(y, 4)][posmod(x, 4)] + 0.5) / 16.0

func hsh(x: int, y: int, s: int) -> float:
	var n: int = (x * 374761393 + y * 668265263 + s * 982451653) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	n = n ^ (n >> 16)
	return float(n % 10000) / 10000.0

## contorno 1 px ink por fora, mantendo o tamanho (o desenho precisa de 1 px de folga em volta)
func ol(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

## desenho por linhas de caracteres (cada letra = uma cor da paleta)
func rows_img(rows: Array, cmap: Dictionary) -> Image:
	var w := 0
	for r in rows:
		w = maxi(w, (r as String).length())
	var im: Image = L.blank(w, rows.size())
	for y in rows.size():
		var r: String = rows[y]
		for x in r.length():
			var ch := r[x]
			if cmap.has(ch):
				L.P(im, x, y, cmap[ch])
	return im

# ---------------------------------------------------------------- fonte 3x5 (a do recorte; letras novas desta fase)
const MINI := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."], "C": ["###", "#..", "#..", "#..", "###"],
	"D": ["##.", "#.#", "#.#", "#.#", "##."], "E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
	"G": ["###", "#..", "#.#", "#.#", "###"], "H": ["#.#", "#.#", "###", "#.#", "#.#"], "I": ["###", ".#.", ".#.", ".#.", "###"],
	"L": ["#..", "#..", "#..", "#..", "###"], "M": ["#.#", "###", "#.#", "#.#", "#.#"], "N": ["#.#", "###", "###", "#.#", "#.#"],
	"O": ["###", "#.#", "#.#", "#.#", "###"], "P": ["##.", "#.#", "##.", "#..", "#.."], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": ["###", "#..", "###", "..#", "###"], "T": ["###", ".#.", ".#.", ".#.", ".#."], "U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."], "Z": ["###", "..#", ".#.", "#..", "###"], "!": [".#.", ".#.", ".#.", "...", ".#."],
	"Ã": ["###", "#.#", "###", "#.#", "#.#"], "1": [".#.", "##.", ".#.", ".#.", "###"], "3": ["###", "..#", ".##", "..#", "###"],
}

func mini_text(img: Image, s: String, x: int, y: int, c) -> void:
	var cx := x
	for i in s.length():
		var ch := s[i]
		if ch == " " or not MINI.has(ch):
			cx += 2
			continue
		var g: Array = MINI[ch]
		for r in 5:
			for k in 3:
				if g[r][k] == "#":
					L.P(img, cx + k, y + r, c)
		cx += 4

func mini_w(s: String) -> int:
	var w := 0
	for i in s.length():
		w += 2 if s[i] == " " else 4
	return maxi(w - 1, 0)

# ================================================================== A RUA (ronda_bg 640x360)
var BG: Image
var LAYERS := {}

func vx(xb: float, yb: float, y: float) -> float:
	return 320.0 + (xb - 320.0) * (y + 28.0) / (yb + 28.0)

func make_street() -> void:
	var img: Image = L.blank(640, 360)
	paint_sky(img)
	paint_far(img)
	paint_back_a(img)
	paint_house3_back(img)
	paint_wall_a(img)
	paint_borracharia(img)
	paint_house2(img)
	paint_wall_d(img)
	paint_sidewalk(img)
	bike(img, 420, 288)                                          # bicicleta encostada na casa 2 (depois da calçada)
	L.line(img, 436, 270, 440, 238, "g2")                        # corrente até a grade da janela
	L.line(img, 437, 270, 441, 238, "g1")
	night_light(img)
	paint_lamp_post(img)
	paint_glows(img)
	BG = img
	save_sheet("ronda_bg", "minigame/ronda_bg.png", [img], 0.0, Vector2i.ZERO)
	LAYERS["graffiti"] = layer_graffiti()
	LAYERS["banner"] = layer_banner()
	LAYERS["kid_ears"] = layer_kid_ears()
	LAYERS["whole_street"] = layer_whole_street()
	for k in LAYERS:
		save_sheet("ronda_layer_" + k, "minigame/ronda_layer_%s.png" % k, [LAYERS[k]], 0.0, Vector2i.ZERO)

func paint_sky(img: Image) -> void:
	for y in 262:
		for x in 640:
			var t := float(y) / 220.0
			var c := "ink"
			if t > 0.3:
				c = "b0" if (t - 0.3) * 1.8 > bayer(x, y) else "ink"
			img.set_pixel(x, y, L.col(c))
	for i in 46:
		var sx := int(hsh(i, 7, 3) * 639)
		var sy := int(4 + hsh(i, 11, 3) * 120)
		if Vector2(sx - MOON.x, sy - MOON.y).length() < MOON_R + 10:
			continue
		L.P(img, sx, sy, "b2" if i % 3 else "b3")
		if i % 11 == 0:
			L.P(img, sx - 1, sy, "b1"); L.P(img, sx + 1, sy, "b1"); L.P(img, sx, sy - 1, "b1"); L.P(img, sx, sy + 1, "b1")
	# lua cheia (a da pose do telhado): halo em dither, disco creme, mares g3, borda clara em cima à esquerda
	for y in range(MOON.y - MOON_R - 14, MOON.y + MOON_R + 15):
		for x in range(MOON.x - MOON_R - 14, MOON.x + MOON_R + 15):
			var d := Vector2(x - MOON.x, y - MOON.y).length()
			if d > MOON_R and d < MOON_R + 14:
				var k := 1.0 - (d - MOON_R) / 14.0
				if k * 0.9 > bayer(x, y):
					img.set_pixel(x, y, L.shade(img.get_pixel(x, y), 1))
	L.ellipse(img, MOON.x, MOON.y, MOON_R, MOON_R, "cream")
	for y in range(MOON.y - MOON_R, MOON.y + MOON_R + 1):
		for x in range(MOON.x - MOON_R, MOON.x + MOON_R + 1):
			var dx := x + 0.5 - MOON.x
			var dy := y + 0.5 - MOON.y
			var d := sqrt(dx * dx + dy * dy)
			if d > MOON_R:
				continue
			# sombra suave do lado de baixo à direita (dither), luz em cima à esquerda
			var lit := (-dx - dy) / MOON_R
			if lit > 0.75 and d > MOON_R - 3:
				L.P(img, x, y, "white")
			elif lit < -0.55 and bayer(x, y) < (-lit - 0.55) * 2.0:
				L.P(img, x, y, "g3")
	for m in [[-8, -6, 6, 4], [5, 2, 7, 5], [-3, 10, 4, 3], [9, -11, 3, 2], [-13, 5, 3, 3]]:
		var cx: float = MOON.x + m[0]
		var cy: float = MOON.y + m[1]
		for y in range(int(cy - m[3]), int(cy + m[3]) + 1):
			for x in range(int(cx - m[2]), int(cx + m[2]) + 1):
				var nx = (x + 0.5 - cx) / m[2]
				var ny = (y + 0.5 - cy) / m[3]
				if nx * nx + ny * ny <= 1.0 and img.get_pixel(x, y) != L.col("white"):
					L.P(img, x, y, "g3" if (x + y) % 3 else "g2")

## silhuetas longe (bairro de cima do morro): só d1 com janelas raras
func paint_far(img: Image) -> void:
	var x := 0
	var i := 0
	while x < 640:
		var w := 22 + int(hsh(i, 1, 9) * 34)
		var h := 26 + int(hsh(i, 2, 9) * 40)
		var top := 200 - h
		var near_moon: bool = x + w > MOON.x - MOON_R - 4 and x < MOON.x + MOON_R + 4
		if near_moon:
			top = maxi(top, MOON.y + MOON_R + 6)
		L.R(img, x, top, w, 200 - top + 62, "d1")
		L.R(img, x, top, w, 1, "d2")
		if hsh(i, 3, 9) > 0.55 and not near_moon:
			L.R(img, x + 4, top - 6, 9, 6, "d1")         # caixa d'água
			L.R(img, x + 4, top - 6, 9, 1, "d2")
		if hsh(i, 5, 9) > 0.7 and not near_moon:
			L.R(img, x + w - 6, top - 9, 1, 9, "d1")     # antena
			L.R(img, x + w - 9, top - 7, 7, 1, "d1")
		for wy in range(top + 5, 196, 7):
			for wx in range(x + 3, x + w - 4, 7):
				if hsh(wx, wy, 13) < 0.09:
					L.R(img, wx, wy, 3, 3, "y0" if hsh(wx, wy, 17) > 0.4 else "br2")
					L.P(img, wx, wy, "y1")
		x += w + int(hsh(i, 4, 9) * 3)
		i += 1

## atrás do muro do terreno: casa de fundos (parede iluminada pela lua = meio-tom atrás do vulto) e uma mangueira
func paint_back_a(img: Image) -> void:
	# mangueira atrás da casa de fundos: só a copa aparece acima do telhado
	var tx := 150
	L.ellipse(img, tx, 112, 30, 20, "gr0")
	L.ellipse(img, tx - 20, 122, 16, 10, "gr0")
	L.ellipse(img, tx + 18, 120, 16, 10, "gr0")
	for k in 120:
		var a := hsh(k, 1, 21) * TAU
		var d := hsh(k, 2, 21) * 26.0
		var px := int(tx + cos(a) * d)
		var py := int(112 + sin(a) * d * 0.7)
		if img.get_pixel(px, py) == L.col("gr0"):
			L.P(img, px, py, "gr1" if py < 116 else "gr0")
	# casa de fundos x 0..178, telhado y 124, parede st1 lisa de y 140 a 196 (o meio-tom atrás do trecho 1)
	L.R(img, 0, 140, 180, 60, "st1")
	L.R(img, 0, 140, 180, 1, "st2")
	for yy in range(146, 196, 9):
		L.R(img, 0, yy, 180, 1, "st0")                    # fiadas de bloco aparentes, bem leves
	L.trap(img, 124, 139, 8, 172, 0, 182, "br0")        # telhado visto de frente (beiral)
	for yy in range(126, 139, 3):
		var t := float(yy - 124) / 15.0
		L.R(img, int(lerpf(8, 0, t)), yy, int(lerpf(164, 182, t)), 1, "br1")
	L.R(img, 0, 139, 182, 2, "d2")                       # beiral escuro
	L.R(img, 136, 154, 24, 18, "ink")                    # 3ª janela (basculante, apagada)
	L.R(img, 137, 155, 22, 16, "b0")
	for yy in range(158, 171, 4):
		L.R(img, 137, yy, 22, 1, "st0")
	L.R(img, 26, 156, 18, 16, "ink")                     # janela de fundos acesa (cortina)
	L.R(img, 27, 157, 16, 14, "y0")
	L.R(img, 27, 157, 16, 2, "y1")
	L.R(img, 27, 157, 5, 14, "r1")
	L.R(img, 34, 157, 1, 14, "br1")
	L.R(img, 70, 154, 22, 18, "ink")                     # janela apagada
	L.R(img, 71, 155, 20, 16, "b0")
	L.R(img, 80, 155, 1, 16, "d2")
	L.R(img, 71, 155, 20, 1, "b1")
	# varal com roupa (história pequena), longe do caminho do vulto (y < 160)
	L.line(img, 96, 150, 160, 146, "g1")
	for c in [[104, "r1", 6, 9], [114, "b1", 7, 11], [126, "cream", 5, 7], [138, "gr1", 6, 10]]:
		var cx: int = c[0]
		var yy := 150 - int((cx - 96) / 16)
		L.R(img, cx, yy, c[2], c[3], c[1])
		L.R(img, cx, yy, c[2], 1, L.shade(L.col(c[1]), 1))

## casa 3 atrás do muro verde: fachada clara (lua), janelas, telhado de telha e caixa d'água; a lua por trás
func paint_house3_back(img: Image) -> void:
	L.R(img, 476, 128, 164, 72, "g3")
	L.R(img, 476, 128, 164, 1, "cream")
	for yy in range(134, 196, 6):
		for xx in range(476, 640):
			if hsh(xx, yy, 33) < 0.05:
				L.P(img, xx, yy, "g2")                       # reboco gasto
	# telhado (beiral) y 112..127
	L.trap(img, 112, 127, 492, 630, 470, 640, "br1")
	for yy in range(114, 127, 3):
		L.R(img, 470, yy, 170, 1, "br0")
	for xx in range(472, 640, 6):
		L.R(img, xx, 113, 1, 14, "br0")
	L.R(img, 470, 127, 170, 2, "d2")
	L.R(img, 492, 111, 138, 1, "br2")                      # cumeeira pega a lua
	# caixa d'água azul de fibra no telhado (x 596..622)
	L.R(img, 596, 94, 26, 18, "ink")
	L.R(img, 597, 95, 24, 16, "b2")
	L.R(img, 597, 95, 24, 2, "b3")
	L.R(img, 597, 107, 24, 4, "b1")
	L.R(img, 594, 92, 30, 3, "ink")
	L.R(img, 595, 92, 28, 2, "b3")
	# janelas da casa 3 (uma acesa, uma apagada com grade)
	L.R(img, 496, 144, 24, 22, "ink")
	L.R(img, 497, 145, 22, 20, "b0")
	L.R(img, 497, 145, 22, 1, "b1")
	L.R(img, 507, 145, 1, 20, "d2")
	L.R(img, 600, 144, 26, 22, "ink")
	L.R(img, 601, 145, 24, 20, "y0")
	L.R(img, 601, 145, 24, 3, "y1")
	L.R(img, 601, 152, 24, 1, "br2")
	L.R(img, 612, 145, 1, 20, "br1")
	for gx in range(603, 625, 4):
		L.R(img, gx, 145, 1, 20, "st0")
	L.R(img, 598, 166, 30, 2, "g2")

## muro do terreno baldio (x 0..175): reboco caindo, tijolo à mostra, capa de concreto em cima (o caminho do vulto)
func paint_wall_a(img: Image) -> void:
	L.R(img, 0, WALK_Y, A_END, BASE_Y - WALK_Y, "g1")
	# tijolo aparecendo onde o reboco caiu (manchas com forma: borda irregular, tijolos inteiros dentro)
	for p in [[2, 236, 22, 16], [128, 208, 22, 12], [150, 244, 18, 12]]:
		var bx: int = p[0]
		var by: int = p[1]
		for y in range(by, by + p[3]):
			for x in range(bx, bx + p[2]):
				var nx = (x - bx - p[2] * 0.5) / (p[2] * 0.5)
				var ny = (y - by - p[3] * 0.5) / (p[3] * 0.5)
				if nx * nx + ny * ny + hsh(x, y, 41) * 0.35 < 1.0:
					var row := (y - by) / 4
					var brick_x := (x + (2 if row % 2 else 0)) % 8
					var c := "br1"
					if (y - by) % 4 == 3 or brick_x == 7:
						c = "br0"
					elif (y - by) % 4 == 0:
						c = "br2"
					L.P(img, x, y, c)
	# rachadura e escorrido embaixo da capa
	L.line(img, 66, 202, 70, 214, "g0")
	L.line(img, 70, 214, 68, 224, "g0")
	for xx in range(4, A_END, 13):
		L.R(img, xx, 203, 1, 3 + int(hsh(xx, 1, 43) * 5), "g0")
	# capa (coping): topo g3 (lua), frente g2, sombra ink embaixo
	L.R(img, 0, WALK_Y - 2, A_END + 2, 2, "g3")
	L.R(img, 0, WALK_Y, A_END + 2, 4, "g2")
	L.R(img, 0, WALK_Y + 4, A_END + 2, 1, "g0")
	L.R(img, 0, WALK_Y + 5, A_END, 1, "d2")
	# cacos de vidro só na ponta esquerda (antes do começo do caminho; o vulto começa em x 26)
	for k in 6:
		var gx := 1 + k * 2
		L.R(img, gx, WALK_Y - 4 - (k % 2), 1, 2 + (k % 2), "gr2" if k % 2 else "b3")
	# mato na base
	for xx in range(0, A_END, 3):
		var hgt := int(hsh(xx, 2, 47) * 6)
		if hgt > 1:
			L.R(img, xx, BASE_Y - hgt, 1, hgt, "gr1" if xx % 2 else "gr0")
	# placa velha "VENDE-SE" desbotada (história, longe da pichação do nível 2)
	L.R(img, 142, 226, 26, 14, "ink")
	L.R(img, 143, 227, 24, 12, "cream")
	L.R(img, 143, 227, 24, 1, "white")
	L.R(img, 146, 230, 18, 1, "r1")
	L.R(img, 146, 233, 12, 1, "g2")
	L.R(img, 146, 235, 16, 1, "g2")

## borracharia (x 176..371): chapa ondulada, letreiro laranja com 24H aceso, marquise de concreto (caminho do trecho 2),
## porta de enrolar "07" (a mesma da arena), pilha de pneus à esquerda (onde o ladrão do estepe trabalha)
func paint_borracharia(img: Image) -> void:
	var top := 118
	for y in range(top, BASE_Y):
		for x in range(A_END, B_END):
			var rib := (x - A_END) % 4
			var c := "st1"
			if rib == 0:
				c = "st2"
			elif rib == 3:
				c = "st0"
			img.set_pixel(x, y, L.col(c))
	L.R(img, A_END - 2, top - 3, B_END - A_END + 4, 3, "st3")      # rufo
	L.R(img, A_END - 2, top, B_END - A_END + 4, 1, "st0")
	# ferrugem escorrendo dos parafusos
	for x in range(A_END + 6, B_END - 4, 22):
		L.P(img, x, top + 4, "st3")
		for y in range(top + 5, top + 12 + int(hsh(x, 3, 51) * 10)):
			if (y + x) % 3 != 0:
				L.P(img, x, y, "br1")
	# letreiro
	var sx := 204
	var sy := 128
	var sw := 92
	L.R(img, sx - 1, sy - 1, sw + 2, 18, "ink")
	L.R(img, sx, sy, sw, 16, "br2")
	L.R(img, sx, sy, sw, 1, "br3")
	L.R(img, sx, sy + 15, sw, 1, "br1")
	L.text_center(img, "BORRACHARIA", sx + sw / 2, sy + 4, "ink")
	L.R(img, sx + sw + 4, sy + 2, 20, 12, "ink")
	L.R(img, sx + sw + 5, sy + 3, 18, 10, "d1")
	L.text(img, "24H", sx + sw + 6, sy + 4, "y1")
	# pneu pintado (logo) na chapa, à direita do letreiro
	L.ring(img, 338, 136, 8, 8, 3, "ink")
	L.ring(img, 338, 136, 7, 7, 2, "d2")
	L.ellipse(img, 338, 136, 3, 3, "st3")
	# marquise (o caminho do trecho 2): laje de concreto y 194..205 de x MARQ_X..B_END+2
	L.R(img, MARQ_X, WALK_Y - 2, B_END - MARQ_X + 2, 2, "g3")
	L.R(img, MARQ_X, WALK_Y, B_END - MARQ_X + 2, 6, "g2")
	L.R(img, MARQ_X, WALK_Y + 6, B_END - MARQ_X + 2, 1, "g0")
	L.R(img, MARQ_X, WALK_Y + 7, B_END - MARQ_X, 3, "ink")         # sombra da laje na chapa
	for x in range(MARQ_X + 2, B_END, 9):
		L.R(img, x, WALK_Y + 1, 1, 4, "g1")                       # marcas de forma no concreto
	# mão-francesa da marquise
	for bx in [MARQ_X + 6, B_END - 10]:
		L.line(img, bx, WALK_Y + 7, bx + 6, WALK_Y + 17, "st0")
		L.line(img, bx + 1, WALK_Y + 7, bx + 7, WALK_Y + 17, "g0")
	# porta de enrolar 07, fechada, embaixo da marquise
	var dx := 252
	var dw := 96
	L.R(img, dx - 2, 212, dw + 4, BASE_Y - 212, "ink")
	L.R(img, dx, 214, dw, BASE_Y - 214, "st1")
	for y in range(216, BASE_Y, 3):
		L.R(img, dx, y, dw, 1, "st0")
	L.R(img, dx, 214, dw, 2, "st2")
	L.R(img, dx + dw / 2 - 6, BASE_Y - 5, 12, 3, "st3")              # puxador
	L.text_center(img, "07", dx + dw / 2, 226, "st3")
	# pilha de pneus à esquerda (x 182..226) e um aro solto
	for k in 4:
		var ty := BASE_Y - 9 - k * 9
		var tx := 186 + (k % 2)
		L.R(img, tx - 1, ty - 1, 40, 10, "ink")
		L.R(img, tx, ty, 38, 8, "d2")
		L.R(img, tx, ty, 38, 1, "g0")
		for x in range(tx + 1, tx + 37, 3):
			L.P(img, x, ty + 3 + (x / 3) % 2, "d1")
	L.R(img, 191, BASE_Y - 46, 28, 3, "ink")                         # face do pneu de cima (furo)
	L.R(img, 196, BASE_Y - 45, 18, 1, "d1")
	# compressor (história) à direita da porta
	L.R(img, 352, 238, 16, 24, "ink")
	L.R(img, 353, 239, 14, 22, "r1")
	L.R(img, 353, 239, 14, 2, "r2")
	L.R(img, 356, 244, 8, 6, "st2")
	L.line(img, 366, 246, 372, 258, "ink")

## casa 2 (sobrado estreito x 372..469): ocre, janela de cima acesa (a criança do nível 4), porta, janela com grade,
## arandela acesa (luz do ladrão da bicicleta)
func paint_house2(img: Image) -> void:
	var x0 := B_END
	var x1 := C_END
	L.R(img, x0, 100, x1 - x0, BASE_Y - 100, "br2")
	L.R(img, x0, 100, x1 - x0, 1, "br3")
	for yy in range(104, BASE_Y, 5):
		for xx in range(x0, x1):
			if hsh(xx, yy, 61) < 0.04:
				L.P(img, xx, yy, "br1")
	# platibanda + telhado
	L.R(img, x0 - 2, 92, x1 - x0 + 4, 8, "br1")
	L.R(img, x0 - 2, 92, x1 - x0 + 4, 1, "br3")
	L.R(img, x0 - 2, 99, x1 - x0 + 4, 1, "br0")
	# divisão dos andares
	L.R(img, x0, 176, x1 - x0, 3, "br1")
	L.R(img, x0, 176, x1 - x0, 1, "br3")
	# janela de cima acesa com cortina (x 400..435, y 120..156)
	var wx := 400
	var wy := 120
	L.R(img, wx - 2, wy - 2, 40, 40, "ink")
	L.R(img, wx, wy, 36, 36, "y0")
	L.R(img, wx, wy, 36, 3, "y1")
	L.R(img, wx, wy, 6, 36, "r1")
	L.R(img, wx + 30, wy, 6, 36, "r1")
	L.R(img, wx + 6, wy, 1, 36, "r0")
	L.R(img, wx + 29, wy, 1, 36, "r0")
	L.R(img, wx, wy + 18, 36, 1, "br1")
	L.R(img, wx - 4, wy + 36, 44, 3, "g3")                          # peitoril
	L.R(img, wx - 4, wy + 39, 44, 1, "g1")
	# vaso no peitoril
	L.R(img, wx + 30, wy + 30, 6, 6, "br1")
	L.ellipse(img, wx + 33, wy + 28, 4, 3, "gr1")
	# porta (x 380..398) e janela de baixo com grade (x 416..460)
	L.R(img, 378, 204, 22, BASE_Y - 204, "ink")
	L.R(img, 380, 206, 18, BASE_Y - 206, "br1")
	L.R(img, 380, 206, 18, 1, "br2")
	L.R(img, 384, 210, 10, 14, "br0")
	L.R(img, 384, 230, 10, 14, "br0")
	L.P(img, 395, 236, "y1")
	L.R(img, 414, 206, 48, 32, "ink")
	L.R(img, 416, 208, 44, 28, "b0")
	L.R(img, 416, 208, 44, 1, "b1")
	for gx in range(418, 460, 5):
		L.R(img, gx, 208, 1, 28, "st1")
	L.R(img, 416, 221, 44, 1, "st1")
	L.R(img, 412, 238, 52, 2, "g3")
	# arandela (luz) entre a porta e a janela
	L.R(img, 404, 196, 6, 7, "ink")
	L.R(img, 405, 197, 4, 5, "y1")
	L.P(img, 406, 198, "y2")
	# número
	L.R(img, 380, 192, 14, 9, "ink")
	L.R(img, 381, 193, 12, 7, "cream")
	L.text(img, "9", 385, 193, "b1")
	# bicicleta encostada embaixo da janela (rodas no chão perto da parede), com corrente na grade

func bike(img: Image, x: int, base: int) -> void:
	## bicicleta de lado, virada para a direita, ~46x26, pés das rodas em y = base
	var r := 9
	var rw := Vector2i(x + 8, base - r)
	var fw := Vector2i(x + 38, base - r)
	for w in [rw, fw]:
		L.ring(img, w.x, w.y, r, r, 2, "ink")
		L.ring(img, w.x, w.y, r - 1, r - 1, 1, "g1")
		L.P(img, w.x, w.y, "st3")
		for a in 6:
			var ang := a * PI / 3.0
			L.line(img, w.x, w.y, w.x + int(cos(ang) * (r - 2)), w.y + int(sin(ang) * (r - 2)), "g0")
	var seat := Vector2i(x + 18, base - 24)
	var crank := Vector2i(x + 20, base - r)
	var head := Vector2i(x + 33, base - 25)
	for seg in [[rw, crank], [crank, head], [rw, seat], [seat, head], [crank, seat], [head, fw]]:
		L.line(img, seg[0].x, seg[0].y, seg[1].x, seg[1].y, "r2")
		L.line(img, seg[0].x, seg[0].y + 1, seg[1].x, seg[1].y + 1, "r1")
	L.R(img, seat.x - 4, seat.y - 2, 8, 2, "ink")                   # selim
	L.R(img, head.x - 1, head.y - 4, 2, 4, "g2")                    # guidão
	L.R(img, head.x - 3, head.y - 5, 7, 2, "ink")
	L.ellipse(img, crank.x, crank.y, 2, 2, "g2")

## muro verde da casa 3 (x 470..571; caminho do trecho 3), pilar com luminária e portão de chapa
func paint_wall_d(img: Image) -> void:
	L.R(img, C_END, WALK_Y, PILLAR.position.x - C_END, BASE_Y - WALK_Y, "gr1")
	for yy in range(WALK_Y + 8, BASE_Y, 10):
		L.R(img, C_END, yy, PILLAR.position.x - C_END, 1, "gr0")        # emenda de bloco pintado
	for xx in range(C_END + 6, PILLAR.position.x, 22):
		for yy in range(WALK_Y + 8, BASE_Y, 20):
			L.R(img, xx + ((yy / 10) % 2) * 11, yy, 1, 10, "gr0")
	L.R(img, C_END, BASE_Y - 10, PILLAR.position.x - C_END, 10, "gr0")   # barrado sujo
	L.R(img, C_END, WALK_Y - 2, PILLAR.position.x - C_END + 1, 2, "g3")
	L.R(img, C_END, WALK_Y, PILLAR.position.x - C_END + 1, 4, "g2")
	L.R(img, C_END, WALK_Y + 4, PILLAR.position.x - C_END + 1, 1, "g0")
	# pilar
	var p := PILLAR
	L.R(img, p.position.x - 1, p.position.y, p.size.x + 2, p.size.y, "ink")
	L.R(img, p.position.x, p.position.y + 1, p.size.x, p.size.y - 1, "g2")
	L.R(img, p.position.x, p.position.y + 1, 2, p.size.y - 1, "g3")
	L.R(img, p.position.x - 2, p.position.y - 2, p.size.x + 4, 3, "g3")
	# luminária em cima do pilar
	L.R(img, p.position.x + 1, p.position.y - 10, 8, 8, "ink")
	L.R(img, p.position.x + 2, p.position.y - 9, 6, 6, "y1")
	L.R(img, p.position.x + 3, p.position.y - 8, 2, 2, "y2")
	L.R(img, p.position.x, p.position.y - 12, 10, 2, "ink")
	# portão de chapa com grade em cima
	var g := GATE
	L.R(img, g.position.x, g.position.y, g.size.x, g.size.y, "ink")
	L.R(img, g.position.x + 1, g.position.y + 20, g.size.x - 1, g.size.y - 20, "st1")
	for xx in range(g.position.x + 3, g.end.x, 7):
		L.R(img, xx, g.position.y + 20, 1, g.size.y - 20, "st0")
	L.R(img, g.position.x + 1, g.position.y + 20, g.size.x - 1, 2, "st2")
	for xx in range(g.position.x + 3, g.end.x, 5):
		L.R(img, xx, g.position.y + 2, 1, 18, "st2")
		L.P(img, xx, g.position.y + 1, "st3")
	L.R(img, g.position.x + 1, g.position.y + 2, g.size.x - 1, 1, "st2")
	L.R(img, g.position.x + 1, g.position.y + 11, g.size.x - 1, 1, "st2")
	L.R(img, g.position.x + 6, g.position.y + 38, 6, 4, "st3")      # fechadura
	L.R(img, g.position.x + 8, g.position.y + 39, 2, 2, "ink")
	L.R(img, 486, 220, 14, 9, "ink")                                # número 15 no muro
	L.R(img, 487, 221, 12, 7, "cream")
	L.text(img, "15", 488, 221, "gr0")

## calçada (y 262..329) de cimento em placas, meio-fio, asfalto com faixa tracejada
func paint_sidewalk(img: Image) -> void:
	for y in range(BASE_Y, CURB_Y):
		for x in 640:
			img.set_pixel(x, y, L.col("g1"))
	for y in range(BASE_Y + 12, CURB_Y, 16):
		L.R(img, 0, y, 640, 1, "g0")
	for xb in range(-600, 1300, 48):
		for y in range(BASE_Y, CURB_Y):
			var x := int(round(vx(xb, BASE_Y, y)))
			if x >= 0 and x < 640:
				img.set_pixel(x, y, L.col("g0"))
	L.R(img, 0, BASE_Y, 640, 2, "d2")
	L.R(img, 0, CURB_Y, 640, 4, "g2")
	L.R(img, 0, CURB_Y, 640, 1, "g3")
	L.R(img, 0, CURB_Y + 4, 640, 2, "g0")
	L.R(img, 0, CURB_Y + 6, 640, 24, "d2")
	L.R(img, 0, CURB_Y + 6, 640, 1, "d1")
	for x in range(0, 640, 40):
		L.R(img, x + 8, 350, 22, 2, "y0")
	# bueiro com grade
	L.R(img, 300, CURB_Y + 1, 18, 4, "d1")
	for gx in range(302, 318, 3):
		L.R(img, gx, CURB_Y + 1, 1, 4, "g1")

## noite: tudo cai 1–2 passos longe das luzes; poças de luz quente embaixo do poste, da arandela e do pilar
func night_light(img: Image) -> void:
	var lights := [[Vector2(196, 308), 120.0, 1.2], [Vector2(400, 306), 110.0, 1.2], [Vector2(590, 306), 106.0, 1.2]]
	for y in range(96, 360):
		# luz ambiente (lua): até o caminho do vulto fica no tom pintado (meio-tom atrás dele); de y ~210 para baixo cai 1
		# passo, em dither (sem emenda reta)
		var amb := clampf(0.2 - float(y - 200) / 70.0, -1.2, 0.2)
		for x in 640:
			var c := img.get_pixel(x, y)
			var n := color_name(c)
			if n in ["ink", "b0", "d1", "white", "y1", "y2", "y0"]:
				continue
			var best := amb
			for li in lights:
				var d = Vector2(x - li[0].x, (y - li[0].y) * 2.0).length() / li[1]
				var lf: float = li[2] - d * 2.4
				best = maxf(best, lf)
			var base := floorf(best)
			var fr := clampf((best - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
			var step := int(base) + (1 if fr > bayer(x, y) else 0)
			step = clampi(step, -1, 1)
			if step != 0:
				img.set_pixel(x, y, L.shade(c, step))

func paint_lamp_post(img: Image) -> void:
	var x := LAMP_X
	var top := 102
	var base := CURB_Y - 2
	L.R(img, x - 2, top, 5, base - top, "g0")
	L.R(img, x - 2, top, 1, base - top, "g1")
	L.R(img, x + 2, top, 1, base - top, "d2")
	L.R(img, x - 3, base - 4, 7, 4, "d2")
	for i in range(0, base - top - 10, 9):
		L.R(img, x - 2, top + 8 + i, 5, 1, "d2")
	L.line(img, x, top + 4, x - 24, top - 2, "g0")
	L.line(img, x, top + 5, x - 24, top - 1, "d2")
	var lx := x - 24
	var ly := top
	L.R(img, lx - 6, ly - 3, 12, 4, "st0")
	L.R(img, lx - 6, ly - 3, 12, 1, "st1")
	L.R(img, lx - 4, ly + 1, 8, 2, "y1")
	L.R(img, lx - 2, ly + 1, 4, 2, "y2")
	# lambe-lambe velho no poste
	L.R(img, x - 3, 236, 7, 10, "cream")
	L.R(img, x - 3, 236, 7, 1, "white")
	L.R(img, x - 2, 239, 5, 1, "r1")

func paint_glows(img: Image) -> void:
	for g in [[Vector2i(LAMP_X - 24, 104), 16, 9], [Vector2i(407, 200), 12, 9], [Vector2i(PILLAR.position.x + 5, PILLAR.position.y - 6), 12, 9],
			[Vector2i(312, 135), 14, 8]]:
		var c: Vector2i = g[0]
		for y in range(c.y - g[2], c.y + g[2] + 1):
			for x in range(c.x - g[1], c.x + g[1] + 1):
				if x < 0 or y < 0 or x >= 640 or y >= 360:
					continue
				var d := Vector2(float(x - c.x) / g[1], float(y - c.y) / g[2]).length()
				if d < 1.0 and d > 0.3 and (x + y) % 2 == 0:
					var cc := img.get_pixel(x, y)
					if not (color_name(cc) in ["y1", "y2", "white"]):
						img.set_pixel(x, y, L.shade(cc, 1))

# ---------------------------------------------------------------- camadas da lenda (640x360, transparentes, em 0,0)
## Nível 2: pichação do gato no muro do terreno, colado na borracharia. Estêncil branco: capuz com as orelhas largas,
## a faixa nos olhos com as pontas voando, escorridos, e a assinatura "GP" de spray. Fica embaixo da barra (y > 213).
func layer_graffiti() -> Image:
	var im: Image = L.blank(640, 360)
	var cx := 74
	var cy := 238
	var paint := "cream"
	# cabeça (capuz) + orelhas largas e baixas
	L.ellipse(im, cx, cy, 15, 12, paint)
	for s in [-1, 1]:
		# orelha larga e baixa: triângulo de base larga no alto da cabeça, ponta baixa puxada para fora
		for k in 12:
			var hh := 1 + int((6 - absf(k - 7.0)) * 0.9) if k <= 11 else 1
			var xx = cx + s * (2 + k)
			L.R(im, xx, cy - 9 - maxi(hh, 1), 1, maxi(hh, 1) + 3, paint)
	# faixa nos olhos (vazada: deixa o muro aparecer) com as pontas voando para a direita
	L.R(im, cx - 15, cy - 3, 31, 6, Color(0, 0, 0, 0))
	for y in range(cy - 3, cy + 3):
		for x in range(cx - 15, cx + 16):
			im.set_pixel(x, y, Color(0, 0, 0, 0))
	for x in range(cx - 14, cx + 15):
		L.P(im, x, cy - 4, paint)
		L.P(im, x, cy + 3, paint)
	L.R(im, cx - 9, cy - 1, 5, 2, paint)                        # olhos (fresta)
	L.R(im, cx + 4, cy - 1, 5, 2, paint)
	for k in 12:
		L.R(im, cx + 16 + k, cy - 3 + k / 3, 2, 2, paint)       # pontas da faixa
		L.R(im, cx + 16 + k, cy + 1 + k / 2, 1, 2, paint)
	# escorridos (curtos: tinta de estêncil)
	for d in [[cx - 6, 4], [cx + 5, 6]]:
		L.R(im, d[0], cy + 11, 1, d[1], paint)
		L.P(im, d[0], cy + 11 + d[1], "g3")
	# boca: sorrisinho de canto (o bairro desenha o gato simpático)
	L.R(im, cx - 3, cy + 6, 1, 1, "g2"); L.R(im, cx - 2, cy + 7, 5, 1, "g2"); L.R(im, cx + 3, cy + 6, 1, 1, "g2")
	# "GP" de spray, vermelho
	L.text(im, "GP", cx + 26, cy + 4, "r2")
	L.R(im, cx + 26, cy + 12, 12, 1, "r2")
	# luz: a mesma do muro (o poste fica à direita): 1 passo mais escuro na ponta esquerda
	for y in range(cy - 24, cy + 24):
		for x in range(cx - 20, cx - 4):
			var c := im.get_pixel(x, y)
			if c.a > 0.0 and bayer(x, y) < float(cx - 4 - x) / 18.0:
				im.set_pixel(x, y, L.shade(c, -1))
	return im

## Nível 3: faixa de pano "VALEU, GATO PRETO" pendurada na chapa da borracharia, embaixo do letreiro e acima da marquise.
## Pano creme pintado à mão (vermelho e preto), cordinhas nas pontas, 1 dobra. Atrás do vulto (y 150..176): pano claro lê bem.
func layer_banner() -> Image:
	var im: Image = L.blank(640, 360)
	var w = L.text_w(TXT_BANNER_STREET) + 14
	var x0 = 290 - w / 2
	var y0 := 152
	var h := 18
	for x in range(x0, x0 + w):
		var sag := int(round(2.0 * sin(PI * float(x - x0) / float(w))))
		for y in range(y0 + sag, y0 + sag + h):
			var c := "cream"
			if y == y0 + sag:
				c = "white"
			elif y == y0 + sag + h - 1:
				c = "g3"
			L.P(im, x, y, c)
	# dobra
	for y in range(y0 + 1, y0 + h + 1):
		L.P(im, x0 + w / 3, y + 1, "g3")
	var o := ol_keep(im)
	im = o
	L.text(im, TXT_BANNER_STREET, x0 + 7, y0 + 7, "r1")
	L.text(im, "VALEU,", x0 + 7, y0 + 7, "ink")
	# cordinhas até a chapa
	L.line(im, x0, y0 + 2, x0 - 6, y0 - 6, "br3")
	L.line(im, x0 + w - 1, y0 + 2, x0 + w + 5, y0 - 6, "br3")
	return im

## contorno ink 1 px por fora sem mudar o tamanho (a imagem tem folga)
func ol_keep(src: Image) -> Image:
	var out: Image = src.duplicate()
	var w := src.get_width()
	var h := src.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var px: int = x + d.x
				var py: int = y + d.y
				if px >= 0 and py >= 0 and px < w and py < h and src.get_pixel(px, py).a > 0.0:
					out.set_pixel(x, y, L.col("ink"))
					break
	return out

## Nível 4: criança na janela de cima do sobrado com orelhinhas de gato de papelão e a faixa azul, acenando;
## desenho de gato colado no vidro. Silhueta em contraluz (a luz é de dentro).
func layer_kid_ears() -> Image:
	var im: Image = L.blank(640, 360)
	var wx := 400
	var wy := 120
	var cx := wx + 17
	var k: Image = L.blank(640, 360)
	# camiseta (contraluz: a luz é de dentro, então o lado de cá fica 1 passo escuro) até o peitoril
	L.ellipse(k, cx, wy + 35, 7, 6, "b1")
	L.R(k, cx - 6, wy + 31, 13, 5, "b1")
	L.R(k, cx - 6, wy + 31, 13, 1, "b2")
	# cabeça: cabelo e rosto em meia-sombra
	L.ellipse(k, cx, wy + 23, 5, 5, "sk0")
	L.R(k, cx - 5, wy + 18, 11, 3, "br0")
	L.P(k, cx - 5, wy + 21, "br0"); L.P(k, cx + 5, wy + 21, "br0")
	# orelhinhas de papelão (largas e baixas, como as do capuz), presas numa tiara
	for s in [-1, 1]:
		var ex = cx + s * 4
		L.trap(k, wy + 13, wy + 17, ex - (2 if s < 0 else 0), ex + (0 if s < 0 else 2), ex - 3, ex + 3, "br2")
		L.P(k, ex, wy + 15, "br3")
	# faixa azul nos olhos, pontas para o lado
	L.R(k, cx - 5, wy + 22, 11, 2, BAND)
	L.R(k, cx - 5, wy + 22, 11, 1, BAND_HI)
	L.R(k, cx + 6, wy + 23, 3, 1, BAND)
	L.R(k, cx + 7, wy + 24, 3, 1, BAND_LO)
	L.R(k, cx - 1, wy + 26, 3, 1, "sk1")                    # sorriso
	# braço acenando, dentro da janela (x <= wx+29)
	L.line(k, cx + 6, wy + 32, cx + 9, wy + 25, "sk0")
	L.line(k, cx + 7, wy + 32, cx + 10, wy + 25, "sk0")
	L.R(k, cx + 9, wy + 22, 3, 3, "sk1")
	blend(im, ol_keep(k), 0, 0)
	# desenho de gato colado no vidro (folha branca com a carinha de capuz)
	L.R(im, wx + 2, wy + 4, 10, 12, "white")
	L.R(im, wx + 2, wy + 4, 10, 1, "cream")
	L.R(im, wx + 4, wy + 8, 6, 5, "ink")
	L.P(im, wx + 4, wy + 7, "ink"); L.P(im, wx + 9, wy + 7, "ink")
	L.R(im, wx + 4, wy + 9, 6, 1, BAND)
	L.R(im, wx + 6, wy + 3, 2, 2, "y2")                     # fita
	return im

## Nível 5: o bairro inteiro com o gato desenhado: varal de bandeirinhas com o capuz, gatos de giz na calçada,
## adesivo no poste, gato pintado na caixa d'água, orelhas recortadas na janela da casa 3, e o "GP" no portão.
func layer_whole_street() -> Image:
	var im: Image = L.blank(640, 360)
	# bandeirinhas: do rufo da borracharia (178,116) até a platibanda do sobrado (468,94); fora da lua e do HUD
	var a := Vector2(178, 116)
	var b := Vector2(468, 94)
	var prev := a
	var n := 15
	for i in range(1, n + 1):
		var t := float(i) / n
		var p := a.lerp(b, t) + Vector2(0, 10.0 * sin(PI * t))
		L.line(im, int(prev.x), int(prev.y), int(p.x), int(p.y), "g2")
		prev = p
		if i < n:
			var fx := int(p.x)
			var fy := int(p.y) + 1
			var col: String = ["d1", BAND, "cream"][i % 3]
			for k in 7:
				L.R(im, fx - 3 + k / 2, fy + k, 7 - k, 1, col)
			if col == "d1":
				L.P(im, fx - 2, fy, "d1"); L.P(im, fx + 2, fy, "d1")
				L.R(im, fx - 2, fy + 2, 5, 1, BAND)
			else:
				L.P(im, fx - 2, fy - 1, "ink"); L.P(im, fx + 2, fy - 1, "ink")
				L.R(im, fx - 2, fy, 5, 3, "ink")
	# gatos de giz na calçada (fora dos pés dos ladrões, entre y 270 e 300)
	for p in [Vector2i(70, 286), Vector2i(300, 294), Vector2i(500, 280)]:
		chalk_cat(im, p.x, p.y)
	# adesivo no poste
	L.R(im, LAMP_X - 2, 252, 5, 5, "ink")
	L.R(im, LAMP_X - 1, 253, 3, 3, "cream")
	L.P(im, LAMP_X - 1, 253, "ink"); L.P(im, LAMP_X + 1, 253, "ink")
	# gato pintado na caixa d'água
	L.R(im, 603, 99, 12, 7, "d1")
	L.P(im, 603, 98, "d1"); L.P(im, 614, 98, "d1")
	L.R(im, 604, 101, 10, 1, "cream")
	# orelhas recortadas na janela acesa da casa 3
	for s in [606, 616]:
		L.R(im, s, 156, 6, 9, "d1")
		L.P(im, s, 155, "d1"); L.P(im, s + 5, 155, "d1")
	# "GP" no portão e um gatinho de giz no muro verde
	L.text(im, "GP", GATE.position.x + 24, GATE.position.y + 30, "cream")
	chalk_cat(im, 520, 244)
	return im

func chalk_cat(im: Image, x: int, y: int) -> void:
	## carinha de capuz em giz (só traço creme, 13x10)
	L.line(im, x - 6, y - 4, x - 4, y - 8, "cream")
	L.line(im, x - 4, y - 8, x - 2, y - 5, "cream")
	L.line(im, x + 6, y - 4, x + 4, y - 8, "cream")
	L.line(im, x + 4, y - 8, x + 2, y - 5, "cream")
	L.line(im, x - 2, y - 5, x + 2, y - 5, "cream")
	L.line(im, x - 6, y - 4, x - 6, y + 1, "cream")
	L.line(im, x + 6, y - 4, x + 6, y + 1, "cream")
	L.line(im, x - 6, y + 1, x - 3, y + 4, "cream")
	L.line(im, x + 6, y + 1, x + 3, y + 4, "cream")
	L.line(im, x - 3, y + 4, x + 3, y + 4, "cream")
	L.R(im, x - 5, y - 2, 11, 2, BAND_HI)
	L.R(im, x + 7, y - 2, 4, 1, BAND_HI)

# ================================================================== PROPS (o que o ladrão larga no SUSTO)
func make_props() -> void:
	# estepe: roda de aço com pneu, de lado (20x20 com contorno), pivô no meio da base (no chão, à direita do ladrão do trecho 1)
	var t: Image = L.blank(20, 20)
	L.ellipse(t, 10, 10, 8.5, 8.5, "d2")
	L.ring(t, 10, 10, 8.5, 8.5, 1, "g0")
	L.ellipse(t, 10, 10, 4.5, 4.5, "st2")
	L.ellipse(t, 10, 10, 3, 3, "st1")
	L.ellipse(t, 10, 10, 1.2, 1.2, "st3")
	for a in 5:
		var ang := a * TAU / 5.0
		L.P(t, 10 + int(round(cos(ang) * 3)), 10 + int(round(sin(ang) * 3)), "st0")
	for a in 16:
		var ang := a * TAU / 16.0
		L.P(t, 10 + int(round(cos(ang) * 7)), 10 + int(round(sin(ang) * 7)), "d1")
	L.P(t, 6, 5, "g1"); L.P(t, 7, 4, "g1")
	t = ol(t)
	save_sheet("ronda_prop_tire", "minigame/ronda_prop_tire.png", [t], 0.0, Vector2i(10, 19))
	# alicate (12x8, pivô no meio): cabos vermelhos
	var p := rows_img([
		"............",
		".ss.........",
		"..sss.......",
		"...ssxrrrr..",
		"...ssxrrrr..",
		"..sss.......",
		".ss.........",
		"............"], {"s": "st2", "x": "st3", "r": "r2"})
	L.P(p, 6, 3, "r3"); L.P(p, 7, 4, "r1"); L.P(p, 8, 4, "r1")
	save_sheet("ronda_prop_pliers", "minigame/ronda_prop_pliers.png", [ol(p)], 0.0, Vector2i(6, 4))
	# pé de cabra (18x7): barra de aço com a ponta curva
	var c := rows_img([
		"..................",
		".cc...............",
		"..c...............",
		"..ccccccccccccccc.",
		"..ssssssssssssssc.",
		"................c.",
		".................."], {"c": "st3", "s": "st1"})
	L.P(c, 16, 6, "st2")
	save_sheet("ronda_prop_crowbar", "minigame/ronda_prop_crowbar.png", [ol(c)], 0.0, Vector2i(9, 3))

# ================================================================== HUD DA RONDA
## A cor da Ronda é a NOITE: azul-marinho b0/b1 + o creme da lua. Nunca o roxo do Legado, nunca o azul vivo do Jiu-jitsu.
func make_hud() -> void:
	save_sheet("icon_legend", "ui/icon_legend.png", [legend_icon(9)], 0.0, Vector2i.ZERO)
	save_sheet("icon_legend_16", "ui/icon_legend_16.png", [legend_icon(16)], 0.0, Vector2i.ZERO)
	save_sheet("ui_legend_pip", "ui/ui_legend_pip.png", [legend_pip(0), legend_pip(1), legend_pip(2)], 0.0, Vector2i(3, 3))
	# barra de distância (no muro): moldura 9-slice 8x6, enchimento 4x4 (0 = andando, 1 = PERTO), zona do SUSTO 4x4 (2 quadros)
	var tr: Image = L.blank(8, 6)
	L.R(tr, 0, 0, 8, 6, "ink")
	L.R(tr, 1, 1, 6, 4, "d1")
	L.R(tr, 1, 4, 6, 1, "b0")
	save_sheet("ui_ronda_track", "ui/ui_ronda_track.png", [tr], 0.0, Vector2i.ZERO)
	var fills := []
	for k in 2:
		var fl: Image = L.blank(4, 4)
		var base := "b2" if k == 0 else "y1"
		var hi := "b3" if k == 0 else "y2"
		var lo := "b1" if k == 0 else "y0"
		L.R(fl, 0, 0, 4, 4, base)
		L.R(fl, 0, 0, 4, 1, hi)
		L.R(fl, 0, 3, 4, 1, lo)
		fills.append(fl)
	save_sheet("ui_ronda_fill", "ui/ui_ronda_fill.png", fills, 0.0, Vector2i.ZERO)
	var zones := []
	for k in 2:
		var z: Image = L.blank(4, 4)
		L.R(z, 0, 0, 4, 4, "d2")
		for y in 4:
			for x in 4:
				if (x + y) % 2 == 0:
					L.P(z, x, y, "y0" if k == 1 else "g0")
		zones.append(z)
	save_sheet("ui_ronda_zone", "ui/ui_ronda_zone.png", zones, 6.0, Vector2i.ZERO)
	# aviso do ladrão (em cima da cabeça): 0 = AVISO começando (? cinza), 1 = AVISO (? branco), 2 = OLHANDO (! vermelho)
	save_sheet("ui_thief_warn", "ui/ui_thief_warn.png", [thief_warn(0), thief_warn(1), thief_warn(2)], 0.0, Vector2i(6, 13))
	# letreiros
	var big := banner_line(TXT_SCARE, 3, 40, "y1", "y0", "b0")
	save_sheet("ui_banner_scare", "ui/ui_banner_scare.png", [big], 0.0, Vector2i(big.get_width() / 2, 20))
	var near0 := banner_line(TXT_SCARE, 2, 28, "y1", "y0", "b0")
	var near1 := banner_line(TXT_SCARE, 2, 28, "cream", "g3", "b0")
	save_sheet("ui_banner_scare_near", "ui/ui_banner_scare_near.png", [near0, near1], 6.0, Vector2i(near0.get_width() / 2, 14))
	var esc := banner_line(TXT_ESCAPED, 2, 28, "g3", "g2", "d2")
	save_sheet("ui_banner_escaped", "ui/ui_banner_escaped.png", [esc], 0.0, Vector2i(esc.get_width() / 2, 14))
	# ícones de prêmio e contador
	save_sheet("icon_ronda_16", "ui/icon_ronda_16.png", [hood_icon16()], 0.0, Vector2i.ZERO)
	save_sheet("icon_occurrence", "ui/icon_occurrence.png", [occurrence_icon()], 0.0, Vector2i.ZERO)

## lua cheia com o capuz de orelhas na frente (a lenda = o que o bairro vê de longe)
func legend_icon(s: int) -> Image:
	var im: Image = L.blank(s, s)
	if s == 9:
		L.ellipse(im, 4.5, 4.5, 4.5, 4.5, "ink")
		L.ellipse(im, 4.5, 4.5, 3.5, 3.5, "cream")
		L.P(im, 2, 2, "white"); L.P(im, 3, 2, "white"); L.P(im, 2, 3, "white")
		L.P(im, 5, 2, "g3"); L.P(im, 6, 4, "g3")
		L.R(im, 2, 6, 5, 3, "ink")
		L.P(im, 2, 5, "ink"); L.P(im, 6, 5, "ink")
		L.R(im, 3, 7, 3, 1, BAND)
		return im
	L.ellipse(im, 8, 7.5, 7.5, 7.5, "ink")
	L.ellipse(im, 8, 7.5, 6.5, 6.5, "cream")
	for p in [[4, 3], [5, 3], [4, 4], [3, 5], [5, 2]]:
		L.P(im, p[0], p[1], "white")
	for p in [[10, 4], [11, 4], [10, 5], [7, 6], [12, 8], [11, 9]]:
		L.P(im, p[0], p[1], "g3")
	var h := rows_img([
		"o.......o.",
		"oo.....oo.",
		"ohooooohho",
		"ohhhhhhhho",
		"obbbbbbbbbb",
		"ohhhhhhhho.",
		"ohhhhhhhho."], {"o": "ink", "h": "d1", "b": BAND})
	L.P(h, 2, 3, "d2"); L.P(h, 3, 3, "d2")
	L.P(h, 2, 4, BAND_HI)
	blend(im, h, 3, 9)
	return im

func legend_pip(k: int) -> Image:
	var im: Image = L.blank(7, 7)
	L.ellipse(im, 3.5, 3.5, 3.5, 3.5, "ink")
	if k == 0:
		L.ellipse(im, 3.5, 3.5, 2.5, 2.5, "d2")
		L.P(im, 2, 2, "g0")
	elif k == 1:
		L.ellipse(im, 3.5, 3.5, 2.5, 2.5, "cream")
		L.P(im, 2, 2, "white"); L.P(im, 4, 4, "g3")
	else:
		L.ellipse(im, 3.5, 3.5, 2.5, 2.5, "y2")
		L.P(im, 3, 0, "y1"); L.P(im, 3, 6, "y1"); L.P(im, 0, 3, "y1"); L.P(im, 6, 3, "y1")
	return im

func thief_warn(k: int) -> Image:
	var im: Image = L.blank(13, 14)
	if k == 2:
		# ! branco num balão redondo vermelho (perigo: ele está olhando)
		L.ellipse(im, 6.5, 6, 6, 6, "ink")
		L.ellipse(im, 6.5, 6, 5, 5, "r2")
		L.R(im, 5, 11, 3, 3, "ink"); L.P(im, 6, 11, "r2"); L.P(im, 6, 12, "r1")
		L.R(im, 6, 2, 2, 5, "white"); L.R(im, 6, 8, 2, 2, "white")
		L.P(im, 4, 3, "r3"); L.P(im, 4, 4, "r3")
		return im
	var c := "g3" if k == 0 else "white"
	var sh := "g1" if k == 0 else "g3"
	var q := rows_img([
		".ccc.",
		"cc.cc",
		"...cc",
		"..cc.",
		"..c..",
		".....",
		"..c.."], {"c": c})
	if k == 1:
		q = scaled(q, 1)
	var big: Image = L.blank(13, 14)
	blend(big, q, 4, 5 if k == 0 else 3)
	var o := ol_keep(big)
	for y in 14:
		for x in 13:
			if o.get_pixel(x, y).is_equal_approx(L.col(c)) and y >= (9 if k == 0 else 7):
				o.set_pixel(x, y, L.col(sh))
	return o

## receita do K.O.!/FINALIZOU!: fonte grande, metade de baixo um tom abaixo, contorno ink, sombra de fonte na cor da noite
func banner_line(txt: String, sc: int, hh: int, top: String, bottom: String, shadow: String) -> Image:
	var kw: int = L.text_w(txt, sc) + 8
	var im: Image = L.blank(kw, hh)
	L.text(im, txt, 4, 8 + sc, shadow, sc)
	L.text(im, txt, 4, 8, top, sc)
	var out := ol(im)
	for y in range(8, hh - 1):
		for x in kw:
			if out.get_pixel(x, y).is_equal_approx(L.col(top)) and y >= 8 + 3 * sc:
				out.set_pixel(x, y, L.col(bottom))
	return out

func hood_icon16() -> Image:
	var im: Image = L.blank(16, 16)
	var h := hood_shape(false)
	im.blit_rect(h, Rect2i(0, 2, 16, 16), Vector2i(0, 0))
	return im

func occurrence_icon() -> Image:
	## OCORRÊNCIAS: o estepe solto que o ladrão largou (9x9)
	var im: Image = L.blank(9, 9)
	L.ellipse(im, 4.5, 4.5, 4.5, 4.5, "ink")
	L.ellipse(im, 4.5, 4.5, 3.5, 3.5, "d2")
	L.ellipse(im, 4.5, 4.5, 2, 2, "st2")
	L.P(im, 4, 4, "st3")
	L.P(im, 2, 2, "g1")
	return im

# ================================================================== CAPUZ NO PREGO
## 16x22, pivô (8,1) = cabeça do prego. Capuz preto pendurado pela nuca: orelhas largas e baixas costuradas nas quinas,
## abertura do rosto, a faixa azul da escola enrolada no prego com as pontas caindo do lado. Quadro 1 = hover.
func hood_shape(gym: bool) -> Image:
	var rows := [
		"................",
		".......nn.......",
		".......NN.......",
		".ee...hNNh...ee.",
		".eee.hhHHhh.eee.",
		".eeeehHHHHheeee.",
		"..hhhHHHHHHhhh..",
		"..hhhhhhhhhhhh..",
		"..hhhRRRRRRhhh..",
		"..hhRffffffRhhb.",
		"..hhffffffffhhbb",
		"..hhhffffffhhh.b",
		"..hhhhffffhhhh.b",
		"...hhhhhhhhhh.bb",
		"...hhhhhhhhhh.b.",
		"...hhhhhhhhhh...",
		"....hhhhhhhh....",
		"....hhhhhhhh....",
		"....hhhh.hhh....",
		"....hhh...hh....",
		".....h..........",
		"................",
	]
	var cm := {"n": "st3", "N": "st1", "e": "d1", "h": "d1", "H": "d2", "R": "d2", "f": "ink", "b": BAND}
	var im := rows_img(rows, cm)
	# a faixa enrolada no prego, com as pontas descendo pelo lado direito
	L.R(im, 6, 3, 4, 1, BAND)
	L.P(im, 6, 3, BAND_HI); L.P(im, 7, 3, BAND_HI)
	L.P(im, 10, 4, BAND_LO); L.P(im, 11, 5, BAND); L.P(im, 12, 6, BAND); L.P(im, 13, 7, BAND); L.P(im, 14, 8, BAND)
	L.P(im, 15, 10, BAND_LO); L.P(im, 15, 11, BAND_LO)
	if gym:
		# tubo frio em cima: o alto da cabeça e das orelhas 1 passo mais claro
		for p in [[1, 3], [14, 3], [6, 4], [9, 4], [5, 5], [10, 5], [2, 6], [13, 6]]:
			L.P(im, p[0], p[1], "g0")
	else:
		# lâmpada à esquerda (x 300): borda esquerda das orelhas e da cabeça mais clara
		for p in [[1, 3], [1, 4], [1, 5], [2, 6], [2, 7], [2, 8], [6, 4], [3, 13], [4, 16]]:
			L.P(im, p[0], p[1], "g0" if p[1] < 9 else "d2")
	# B5 da Ronda 2a1 (2026-11-26): orelhas de GATO COSTURADAS, baixas e de ponta arredondada (sem a ponta de 1 px da linha 2,
	# que lia como morcego), com a linha de costura na base (pontos alternados), como no capuz do vulto
	for p in [[2, 5], [4, 5], [11, 5], [13, 5]]:
		L.P(im, p[0], p[1], "g1")
	L.P(im, 7, 14, "ink"); L.P(im, 7, 15, "ink"); L.P(im, 9, 16, "ink"); L.P(im, 6, 17, "d2")   # dobras
	return ol_keep(im)

func make_hood() -> void:
	for gym in [false, true]:
		var a := hood_shape(gym)
		var b: Image = a.duplicate()
		for y in b.get_height():
			for x in b.get_width():
				if a.get_pixel(x, y).a > 0.0:
					continue
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var px: int = x + d.x
					var py: int = y + d.y
					if px >= 0 and py >= 0 and px < a.get_width() and py < a.get_height() and a.get_pixel(px, py).is_equal_approx(L.col("ink")):
						b.set_pixel(x, y, L.col("cream"))
						break
		if gym:
			save_sheet("hood_on_nail_gym", "gym/hood_on_nail_gym.png", [a, b], 0.0, HOOD_PIVOT)
		else:
			save_sheet("hood_on_nail", "garage/hood_on_nail.png", [a, b], 0.0, HOOD_PIVOT)

# ================================================================== RECORTES DE JORNAL (níveis 1..5)
## O nível 0 é o da 7a2 (wall_clipping_black_cat / _gym / ui_clipping_black_cat_zoom), que não muda.
## Pequeno 23x28 no mesmo ponto de cada local; a escalada se lê em 1x pela FOTO (cada nível mostra a camada da rua
## daquele nível) e pela tinta: 1–3 manchete preta; 4 manchete vermelha; 5 tarja vermelha de EXTRA em cima.
func paper_sheet(img: Image, x0: int, y0: int, w: int, h: int, paper: String, seed: int) -> void:
	L.R(img, x0, y0, w, h, "ink")
	L.R(img, x0 + 1, y0 + 1, w - 2, h - 2, paper)
	for y in range(y0 + 3, y0 + h - 1):
		for side in [0, 1]:
			if hsh(y, side, seed) > 0.62:
				var xo: int = x0 if side == 0 else x0 + w - 1
				var xi: int = x0 + 1 if side == 0 else x0 + w - 2
				img.set_pixel(xo, y, Color(0, 0, 0, 0))
				img.set_pixel(xi, y, L.col("ink"))
	for x in range(x0 + 2, x0 + w - 2):
		if hsh(x, 7, seed) > 0.6:
			img.set_pixel(x, y0 + h - 1, Color(0, 0, 0, 0))
			img.set_pixel(x, y0 + h - 2, L.col("ink"))

## silhueta do vigilante (a mesma do recorte da 7a2: capuz com orelhas, faixa com as pontas voando, capa reta)
const VIGIA_SMALL := ["#...#..", "#####..", "#g#g#gg", "#####.g", ".###...", "#####..", "######.", "######."]
const VIGIA_BIG := [
	"..##.....##.......", "..###...###.......", "..#########.......", "..#########.......", "..#gwgggwg#ggg....",
	"..#ggggggg#.ggg...", "..#########...gg..", "...#######........", "..#########.......", ".###########......",
	".############.....", "#####.###.###.....", "####..###.####....", "####.#####.###....", "###p######.###....",
	"###pp#####..##....", "##########..##....", "###########.##....", "############......"]

func vigia(img: Image, rows: Array, x: int, y: int, band: String) -> void:
	for r in rows.size():
		var row: String = rows[r]
		for k in row.length():
			var c := ""
			match row[k]:
				"#": c = "ink"
				"g": c = band
				"w": c = "white"
				"p": c = "d2"
			if c != "":
				L.P(img, x + k, y + r, c)

func photo_bg(img: Image, r: Rect2i, night := true) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var t := float(y - r.position.y) / float(r.size.y)
			var c := "g1" if bayer(x, y) < (0.5 - t * 0.3 if night else 0.75 - t * 0.2) else "g0"
			img.set_pixel(x, y, L.col(c))

## foto pequena 11x8 em (x,y): o que o jornal mostra em cada nível
func photo_small(img: Image, level: int, x: int, y: int) -> void:
	photo_bg(img, Rect2i(x, y, 11, 8))
	match level:
		1:
			L.R(img, x + 8, y + 1, 2, 2, "cream"); L.P(img, x + 9, y + 2, "g3")
			vigia(img, VIGIA_SMALL, x + 1, y, "g3")
		2:
			# o gato pichado no muro (creme) e um ladrão fugindo
			L.R(img, x, y + 5, 11, 3, "g2")
			L.R(img, x + 1, y + 1, 5, 4, "cream"); L.P(img, x + 1, y, "cream"); L.P(img, x + 5, y, "cream")
			L.R(img, x + 1, y + 2, 5, 1, "g1")
			L.R(img, x + 8, y + 2, 2, 3, "ink"); L.P(img, x + 8, y + 1, "ink"); L.P(img, x + 7, y + 5, "ink"); L.P(img, x + 10, y + 5, "ink")
		3:
			# a faixa e o povo embaixo, braços para cima
			L.R(img, x + 1, y + 1, 9, 2, "cream"); L.R(img, x + 2, y + 1, 1, 2, "g1"); L.R(img, x + 5, y + 1, 1, 2, "g1"); L.R(img, x + 8, y + 1, 1, 2, "g1")
			for hx in [x + 1, x + 4, x + 7, x + 9]:
				L.R(img, hx, y + 5, 2, 3, "ink"); L.P(img, hx, y + 4, "ink")
		4:
			# janela acesa com a criança de orelhinha
			L.R(img, x + 2, y + 1, 7, 7, "g3")
			L.R(img, x + 4, y + 3, 3, 5, "ink"); L.P(img, x + 4, y + 2, "ink"); L.P(img, x + 6, y + 2, "ink")
			L.R(img, x + 4, y + 4, 3, 1, "g2")
		5:
			# o ônibus erguido e o vulto embaixo com um braço só
			L.R(img, x + 1, y, 9, 4, "g3"); L.R(img, x + 2, y + 1, 7, 1, "ink"); L.P(img, x + 2, y + 4, "ink"); L.P(img, x + 8, y + 4, "ink")
			L.P(img, x + 5, y + 4, "ink")
			L.R(img, x + 4, y + 5, 3, 3, "ink"); L.P(img, x + 4, y + 5, "g2")

func clip_small(level: int, gym: bool) -> Image:
	var w := CLIP_SIZE.x
	var h := CLIP_SIZE.y
	var img: Image = L.blank(w, h)
	var paper := "white" if gym else "cream"
	var paper_d := "cream" if gym else "g3"
	paper_sheet(img, 0, 1, w, h - 1, paper, 141 + level * 7 + (1 if gym else 0))
	L.R(img, 2, h - 3, w - 4, 1, paper_d)
	if level >= 5:
		L.R(img, 1, 2, w - 2, 2, "r2")                     # tarja EXTRA
		for x in range(3, w - 3, 2):
			L.P(img, x, 2, "r3")
	else:
		L.R(img, 2, 3, w - 4, 1, "g1")
	var head := "r1" if level >= 4 else "ink"
	var l1: String = TXT_SMALL[level][0]
	var l2: String = TXT_SMALL[level][1]
	mini_text(img, l1, (w - mini_w(l1)) / 2, 5, "ink")
	mini_text(img, l2, (w - mini_w(l2)) / 2, 11, head)
	if level == 3:
		L.R(img, (w - mini_w(l2)) / 2, 16, mini_w(l2), 1, "r2")   # sublinhado
	photo_small(img, level, 2, 17)
	L.R(img, 2, 25, 11, 1, "ink")
	for y in range(17, 25, 2):
		L.R(img, 14, y, (6 if y != 23 else 4), 1, "g2")
	# fita no alto
	for y in range(0, 3):
		for x in range(8, 15):
			if (x + y) % 2 == 0 or y == 1:
				img.set_pixel(x, y, L.col("y2" if not gym else "white"))
	if not gym:
		for y in range(12, h):
			for x in range(1, 7):
				var c := img.get_pixel(x, y)
				if c.a > 0.0 and c == L.col(paper) and bayer(x, y) < float(y - 12) / 16.0:
					img.set_pixel(x, y, L.shade(c, -1))
	return img

## zoom 128x96 (hover): o mesmo jornal grande. Manchete de 2 linhas (chamada 1x + título 2x), foto 56x44, colunas.
func clip_zoom(level: int) -> Image:
	var w := ZOOM_SIZE.x
	var h := ZOOM_SIZE.y
	var img: Image = L.blank(w, h)
	L.R(img, 1, 3, w - 2, h - 4, "cream")
	for y in range(3, h - 1):
		for x in [1, w - 2]:
			if hsh(x, y, 51 + level) > 0.6:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	for x in range(1, w - 1):
		if hsh(x, 0, 52 + level) > 0.6:
			img.set_pixel(x, h - 2, Color(0, 0, 0, 0))
	var o: Image = L.outlined(img.get_region(Rect2i(1, 3, w - 2, h - 4)), "ink")
	var out: Image = L.blank(w, h)
	out.blit_rect(o, Rect2i(0, 0, w, h - 2), Vector2i(0, 2))
	img = out
	if level >= 5:
		L.R(img, 2, 4, w - 4, 10, "r2")
		L.R(img, 2, 4, w - 4, 1, "r3")
		L.text_center(img, "EDIÇÃO EXTRA", w / 2, 6, "white")
	else:
		L.text_center(img, TXT_MAST, w / 2, 6, "g0")
	L.R(img, 4, 15, w - 8, 1, "ink")
	L.R(img, 4, 17, w - 8, 1, "g1")
	var kick: String = TXT_ZOOM[level][0]
	var main: String = TXT_ZOOM[level][1]
	L.text_center(img, kick, w / 2, 20, "g0")
	L.text_center(img, main, w / 2, 29, "r1" if level >= 4 else "ink", 2)
	if L.text_w(kick) > w - 8 or L.text_w(main, 2) > w - 8:
		CHECKS.append("PROBLEMA: manchete do zoom %d não cabe (%d / %d px)" % [level, L.text_w(kick), L.text_w(main, 2)])
	var pr := Rect2i(5, 47, 56, 42)
	photo_zoom(img, level, pr)
	L.R(img, pr.position.x, pr.end.y, pr.size.x, 1, "ink")
	L.R(img, pr.position.x, pr.position.y - 1, pr.size.x, 1, "ink")
	L.R(img, pr.position.x - 1, pr.position.y, 1, pr.size.y, "ink")
	L.R(img, pr.end.x, pr.position.y, 1, pr.size.y, "ink")
	for y in range(pr.position.y, h - 6, 3):
		L.R(img, 66, y, 56 - (9 if (y / 3) % 4 == 0 else 0), 1, "g2")
	# fita
	for y in range(0, 5):
		for x in range(54, 74):
			if (x + y) % 2 == 0 or y == 2:
				img.set_pixel(x, y, L.col("y2"))
	return img

func photo_zoom(img: Image, level: int, r: Rect2i) -> void:
	var fx := r.position.x
	var fy := r.position.y
	photo_bg(img, r, level != 3)
	match level:
		1:
			L.ellipse(img, fx + 44, fy + 9, 6, 6, "cream")
			L.ellipse(img, fx + 45, fy + 8, 4, 4, "white")
			L.R(img, fx, fy + 33, 56, 9, "d2")
			L.line(img, fx, fy + 33, fx + 18, fy + 27, "d2")
			L.trap(img, fy + 27, fy + 33, fx + 18, fx + 18, fx, fx + 18, "d2")
			L.R(img, fx + 38, fy + 25, 3, 8, "d2")
			vigia(img, VIGIA_BIG, fx + 16, fy + 14, "g3")
			L.P(img, fx + 19, fy + 15, "g1"); L.P(img, fx + 25, fy + 15, "g1")
		2:
			# o muro com o gato pichado; o ladrão fugindo e o estepe rolando
			L.R(img, fx, fy + 6, 56, 30, "g2")
			for yy in range(fy + 10, fy + 36, 6):
				L.R(img, fx, yy, 56, 1, "g1")
			L.ellipse(img, fx + 16, fy + 20, 9, 7, "cream")
			L.trap(img, fy + 9, fy + 14, fx + 9, fx + 11, fx + 8, fx + 15, "cream")
			L.trap(img, fy + 9, fy + 14, fx + 21, fx + 23, fx + 17, fx + 24, "cream")
			L.R(img, fx + 7, fy + 18, 19, 3, "g1")
			L.R(img, fx, fy + 36, 56, 6, "g1")
			# ladrão correndo (silhueta)
			L.ellipse(img, fx + 44, fy + 17, 3, 3, "ink")
			L.line(img, fx + 43, fy + 20, fx + 40, fy + 29, "ink"); L.line(img, fx + 44, fy + 20, fx + 41, fy + 29, "ink")
			L.line(img, fx + 40, fy + 29, fx + 36, fy + 35, "ink"); L.line(img, fx + 41, fy + 29, fx + 47, fy + 35, "ink")
			L.line(img, fx + 42, fy + 22, fx + 49, fy + 19, "ink"); L.line(img, fx + 42, fy + 22, fx + 36, fy + 25, "ink")
			L.ring(img, fx + 28, fy + 35, 4, 4, 2, "ink")
			for k in 3:
				L.R(img, fx + 50 + k * 2, fy + 21 + k * 4, 3, 1, "g3")
		3:
			# a fachada da borracharia com a faixa e o povo
			L.R(img, fx, fy, 56, 30, "g1")
			for xx in range(fx, fx + 56, 3):
				L.R(img, xx, fy, 1, 30, "g0")
			L.R(img, fx + 4, fy + 6, 48, 9, "cream")
			L.R(img, fx + 4, fy + 6, 48, 1, "white")
			mini_text(img, "VALEU", fx + 18, fy + 8, "ink")
			for k in 6:
				var hx := fx + 5 + k * 9
				L.ellipse(img, hx, fy + 30, 3, 3, "ink" if k % 2 else "d2")
				L.R(img, hx - 3, fy + 33, 7, 9, "ink" if k % 2 else "d2")
				L.line(img, hx + 3, fy + 33, hx + 5, fy + 26, "ink" if k % 2 else "d2")
		4:
			# 3 crianças de orelhinha e faixa (foto da escola)
			L.R(img, fx, fy + 32, 56, 10, "g2")
			for k in 3:
				var hx := fx + 11 + k * 17
				L.ellipse(img, hx, fy + 22, 6, 6, "g3")
				L.trap(img, fy + 12, fy + 17, hx - 5, hx - 3, hx - 7, hx - 1, "ink")
				L.trap(img, fy + 12, fy + 17, hx + 3, hx + 5, hx + 1, hx + 7, "ink")
				L.R(img, hx - 6, fy + 20, 13, 3, "ink")
				L.R(img, hx - 2, fy + 25, 5, 1, "g1")
				L.R(img, hx - 7, fy + 29, 15, 13, "g1" if k != 1 else "g0")
		5:
			# o vulto erguendo um ônibus com uma mão (a lenda absurda)
			L.R(img, fx, fy + 36, 56, 6, "g2")
			L.R(img, fx + 6, fy + 3, 44, 15, "g3")
			L.R(img, fx + 6, fy + 3, 44, 1, "white")
			for wx in range(fx + 9, fx + 47, 7):
				L.R(img, wx, fy + 6, 5, 5, "g0")
			L.ring(img, fx + 15, fy + 18, 3, 3, 2, "ink")
			L.ring(img, fx + 41, fy + 18, 3, 3, 2, "ink")
			L.R(img, fx + 6, fy + 13, 44, 1, "g1")
			vigia(img, VIGIA_BIG, fx + 20, fy + 20, "g3")
			L.R(img, fx + 26, fy + 18, 2, 4, "ink")                # o braço erguido
			for k in 4:
				L.R(img, fx + 2, fy + 4 + k * 4, 3, 1, "white")    # tremida

func make_clippings() -> void:
	for lv in range(1, 6):
		save_sheet("wall_clipping_black_cat_l%d" % lv, "garage/wall_clipping_black_cat_l%d.png" % lv, [clip_small(lv, false)], 0.0, Vector2i.ZERO)
		save_sheet("wall_clipping_black_cat_gym_l%d" % lv, "gym/wall_clipping_black_cat_gym_l%d.png" % lv, [clip_small(lv, true)], 0.0, Vector2i.ZERO)
		save_sheet("ui_clipping_black_cat_zoom_l%d" % lv, "ui/ui_clipping_black_cat_zoom_l%d.png" % lv, [clip_zoom(lv)], 0.0, Vector2i.ZERO)

# ================================================================== MAPA: região GATO PRETO
func badge() -> Image:
	## o carimbo do gato (8x7 + contorno): capuz com orelhas e a faixa azul. Vai no canto de cima à direita dos ícones dos nós.
	var b := rows_img([
		"..........",
		".h......h.",
		".hh....hh.",
		".hhhhhhhh.",
		".bbbbbbbbb",
		".hhhhhhhh.",
		"..hhhhhh..",
		".........."], {"h": "d1", "b": BAND})
	L.P(b, 2, 3, "d2"); L.P(b, 3, 3, "d2")
	L.P(b, 1, 4, BAND_HI); L.P(b, 2, 4, BAND_HI)
	return ol_keep(b)

func with_badge(base_id: String, plus2 := false) -> Image:
	var im: Image = frame_of(base_id).duplicate()
	if plus2:
		# o calendário diz +1 no desenho de origem; aqui a ajuda é +2: troca o 1 por um 2 (o +1 ocupa x 4..12, y 7..13)
		var paper := im.get_pixel(13, 12)
		var ink := Color()
		for y in range(5, 15):
			for x in range(9, 15):
				var c := im.get_pixel(x, y)
				if c.a > 0.0 and c.v < 0.35 and c.g > c.r:
					ink = c
		L.R(im, 9, 6, 5, 8, paper)
		var two := rows_img(["####", "...#", "...#", "####", "#...", "#...", "####"], {"#": ink})
		blend(im, two, 9, 7)
	var bd := badge()
	blend(im, bd, 16 - bd.get_width() + 1, -1)
	return im

func make_map() -> void:
	# ícone 16 da região: telhado de telha à noite, a lua e o vulto sentado na cumeeira (silhueta)
	var im: Image = L.blank(16, 16)
	L.ellipse(im, 10.5, 5.5, 5.5, 5.5, "ink")
	L.ellipse(im, 10.5, 5.5, 4.5, 4.5, "cream")
	L.P(im, 9, 3, "white"); L.P(im, 8, 4, "white"); L.P(im, 12, 6, "g3"); L.P(im, 11, 8, "g3")
	L.trap(im, 10, 15, 6, 9, 0, 15, "ink")
	L.trap(im, 11, 14, 6, 9, 1, 14, "br1")
	for y in [12, 14]:
		L.R(im, 1, y, 14, 1, "br0")
	L.R(im, 5, 10, 6, 1, "br2")
	# vulto na cumeeira (contra a lua)
	L.R(im, 7, 6, 4, 4, "ink")
	L.P(im, 7, 5, "ink"); L.P(im, 10, 5, "ink")
	L.R(im, 6, 8, 6, 2, "ink")
	L.R(im, 7, 7, 4, 1, BAND)
	save_sheet("icon_region_black_cat", "ui/icon_region_black_cat.png", [im], 0.0, Vector2i.ZERO)
	var i9: Image = L.blank(9, 9)
	L.ellipse(i9, 5.5, 3.5, 3.5, 3.5, "cream")
	L.trap(i9, 6, 8, 3, 5, 0, 8, "ink")
	L.trap(i9, 7, 8, 3, 5, 1, 7, "br1")
	L.R(i9, 3, 2, 3, 4, "ink"); L.P(i9, 3, 1, "ink"); L.P(i9, 5, 1, "ink")
	L.R(i9, 3, 3, 3, 1, BAND)
	save_sheet("icon_region_black_cat_9", "ui/icon_region_black_cat_9.png", [i9], 0.0, Vector2i.ZERO)
	# plaquinha 16x13 (9-slice 4,1,1,1): faixa da noite (b1) com o pontinho da lua
	var lb: Image = L.blank(16, 13)
	L.R(lb, 0, 0, 16, 13, "ink"); L.R(lb, 1, 1, 14, 11, "d1"); L.R(lb, 1, 1, 14, 1, "d2")
	L.R(lb, 1, 1, 3, 11, "b1"); L.R(lb, 1, 1, 3, 1, "b2"); L.P(lb, 2, 2, "cream")
	save_sheet("ui_map_region_label_black_cat", "ui/map/ui_map_region_label_black_cat.png", [lb], 0.0, Vector2i.ZERO)
	# ladrilho 32x32: telhado de telha capa-canal à noite (azul-marinho), com reflexo de lua aqui e ali
	var t: Image = L.blank(32, 32)
	for y in 32:
		for x in 32:
			var row := y / 8
			var xx := (x + (4 if row % 2 else 0)) % 8
			var yy := y % 8
			var c := "b0"
			if yy == 7:
				c = "ink"
			elif xx == 0 or xx == 7:
				c = "d1"
			elif yy == 0 and xx >= 2 and xx <= 5:
				c = "b1"
			if c == "b1" and hsh(x / 8, y / 8, 71) < 0.15:
				c = "st2"
			L.P(t, x, y, c)
	save_sheet("map_tile_black_cat_region", "ui/map/map_tile_black_cat_region.png", [t], 0.0, Vector2i.ZERO)
	# anel "noite" dos nós comprados (troca do anel azul): marinho com o brilho creme da lua
	var ring_swap := {"b0": "ink", "b1": "b0", "b2": "b1", "b3": "cream"}
	for k in ["s", "b"]:
		var e := spr("map_node_%s_owned_blue" % k)
		var src := load_png(res_abs(str(e.file)))
		var fw := int(e.frame_size[0])
		var fh := int(e.frame_size[1])
		var frames := []
		for i in maxi(src.get_width() / fw, 1):
			frames.append(swap(src.get_region(Rect2i(i * fw, 0, fw, fh)), ring_swap))
		var pv: Array = e.get("pivot", [0, 0])
		save_sheet("map_node_%s_owned_night" % k, "ui/map/map_node_%s_owned_night.png" % k, frames, float(e.get("fps", 0.0)),
			Vector2i(int(pv[0]), int(pv[1])))
		# nó lacrado (D7 do design): o "faltando" com um lacre da lua com o capuz no meio; sem preço, sem ícone
		var miss := load_png(res_abs(str(spr("map_node_%s_missing" % k).file)))
		var s: Image = miss.get_region(Rect2i(0, 0, fw, fh))
		var r := 4.5 if k == "s" else 6.5
		var c := Vector2(fw / 2.0, fh / 2.0)
		L.ellipse(s, c.x, c.y, r + 1, r + 1, "ink")
		L.ellipse(s, c.x, c.y, r, r, "g2")
		L.P(s, int(c.x) - 2, int(c.y) - 2, "g3")
		var hx := int(c.x)
		var hy := int(c.y) + 1
		L.R(s, hx - 2, hy - 1, 4, 3, "d1")
		L.P(s, hx - 2, hy - 2, "d1"); L.P(s, hx + 1, hy - 2, "d1")
		L.R(s, hx - 2, hy, 4, 1, BAND_LO)
		save_sheet("map_node_%s_sealed" % k, "ui/map/map_node_%s_sealed.png" % k, [s], 0.0, Vector2i(int(pv[0]), int(pv[1])))
	# ícones dos 3 nós: o desenho de hoje do mesmo tipo de efeito + o carimbo do gato no canto
	save_sheet("skill_black_cat_roof", "ui/skill_black_cat_roof.png", [with_badge("skill_crew_regulars")], 0.0, Vector2i.ZERO)
	save_sheet("skill_black_cat_watch", "ui/skill_black_cat_watch.png", [with_badge("skill_prep_day", true)], 0.0, Vector2i.ZERO)
	save_sheet("skill_black_cat_thanks", "ui/skill_black_cat_thanks.png", [with_badge("skill_body_crew")], 0.0, Vector2i.ZERO)

## troca de cores por nome da paleta
func swap(src: Image, m: Dictionary) -> Image:
	var im: Image = src.duplicate()
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var n := color_name(c)
			if m.has(n):
				var to: Color = L.col(m[n])
				to.a = c.a
				im.set_pixel(x, y, to)
	return im

# ================================================================== MOCKUPS: níveis, pontos, capuz, recortes, peças
func mock_levels() -> void:
	var W := 1300
	var H := 3 * 384 + 30
	var b: Image = L.blank(W, H)
	L.R(b, 0, 0, W, H, "d1")
	label(b, "RONDA - A RUA EM CADA NÍVEL DA LENDA (1X). CAMADAS: 2 PICHAÇÃO, 3 FAIXA, 4 CRIANÇA NA JANELA, 5 O BAIRRO INTEIRO", 8, 8, "y1")
	var names := ["NÍVEL 0: RUA NORMAL", "NÍVEL 1: SÓ O JORNAL MUDA", "NÍVEL 2: + PICHAÇÃO (GRAFFITI)", "NÍVEL 3: + FAIXA (BANNER)",
		"NÍVEL 4: + CRIANÇA DE ORELHINHA (KID_EARS)", "NÍVEL 5: + O BAIRRO INTEIRO (WHOLE_STREET)"]
	for lv in 6:
		var x := 8 + (lv % 2) * 648
		var y := 26 + (lv / 2) * 384
		blend(b, compose_street(lv), x, y + 16)
		label(b, names[lv], x, y + 4, "cream")
	b.save_png(MOCK + "ronda_camadas_niveis.png")
	# o mesmo, só as camadas em 2x (recorte do miolo de cada uma), para o Artista e o UI/UX conferirem o acabamento
	var z: Image = L.blank(1280, 720)
	L.R(z, 0, 0, 1280, 720, "d1")
	blend(z, scaled(compose_street(5).get_region(Rect2i(0, 88, 640, 180)), 2), 0, 0)
	blend(z, scaled(compose_street(0).get_region(Rect2i(0, 88, 640, 180)), 2), 0, 360)
	label(z, "NÍVEL 5 (EM CIMA) X NÍVEL 0 (EMBAIXO), Y 88..267, 2X", 6, 6, "y1")
	z.save_png(MOCK + "ronda_camadas_zoom_x2.png")

func cross(img: Image, p: Vector2i, c: String, r := 3) -> void:
	for k in range(-r, r + 1):
		L.P(img, p.x + k, p.y, c)
		L.P(img, p.x, p.y + k, c)

func rect_outline(img: Image, r: Rect2i, c: String) -> void:
	for x in range(r.position.x, r.end.x):
		L.P(img, x, r.position.y, c); L.P(img, x, r.end.y - 1, c)
	for y in range(r.position.y, r.end.y):
		L.P(img, r.position.x, y, c); L.P(img, r.end.x - 1, y, c)

func mock_points() -> void:
	var im: Image = BG.duplicate()
	# faixas de HUD
	rect_outline(im, Rect2i(0, 0, 640, HUD_H), "y1")
	rect_outline(im, Rect2i(0, CURB_Y + 6, 640, 360 - CURB_Y - 6), "y1")
	var v := vulto_standin()
	for occ in OCC_ORDER:
		var o: Dictionary = OCC[occ]
		for x in range(o.start, o.end + 1):
			L.P(im, x, WALK_Y, "y1")
			L.P(im, x, WALK_Y + 1, "y1")
		cross(im, Vector2i(o.start, WALK_Y), "y2")
		cross(im, Vector2i(o.end, WALK_Y), "y2")
		var zx := int(lerpf(o.start, o.end, 0.8))
		L.R(im, zx, WALK_Y - 8, 1, 10, "r3")
		# caixa do vulto no começo e no fim do trecho
		rect_outline(im, Rect2i(Vector2i(o.start, WALK_Y) - VPIV, v.get_size()), "b3")
		rect_outline(im, Rect2i(Vector2i(o.end, WALK_Y) - VPIV, v.get_size()), "b3")
		cross(im, o.thief, "r2", 4)
		rect_outline(im, Rect2i(o.thief - Vector2i(24, 71), Vector2i(48, 76)), "r2")
		cross(im, o.land, "gr3")
		cross(im, o.prop, "f2", 2)
		L.line(im, o.end, WALK_Y, o.land.x, o.land.y, "gr3")
		rect_outline(im, Rect2i(o.start - 4, TRACK_Y, o.end - o.start + 8, 6), "y2")
		label(im, str(occ).to_upper(), o.start, WALK_Y - 64, "y1")
	cross(im, ROOF_POSE, "b3", 5)
	label(im, "POSE NO TELHADO", ROOF_POSE.x - 52, ROOF_POSE.y + 4, "b3")
	var big := scaled(im, 2)
	var board: Image = L.blank(1280, 720 + 60)
	L.R(board, 0, 0, 1280, 780, "d1")
	blend(board, big, 0, 60)
	label(board, "RONDA - PONTOS (X2). AMARELO: CAMINHO DO VULTO (PÉS, Y %d) E BARRA (Y %d); VERMELHO: ZONA 0,8 E LADRÃO (PÉS, Y %d, QUADRO 48X76)" % [WALK_Y, TRACK_Y, THIEF_Y], 6, 6, "y1")
	label(board, "AZUL: CAIXA DO VULTO 52X50 NO COMEÇO E NO FIM; VERDE: QUEDA DO SUSTO; ROSA: OBJETO QUE VOA; FAIXAS DE HUD: Y 0..%d E Y %d..359" % [HUD_H - 1, CURB_Y + 6], 6, 22, "g3")
	label(board, "LADRÃO DE COSTAS = VIRADO PARA A DIREITA; OLHANDO = VIRADO PARA A ESQUERDA (ESPELHAR). LUZ: CADA LADRÃO NUMA POÇA DE LUZ, O VULTO NA SOMBRA DO ALTO.", 6, 38, "g3")
	board.save_png(MOCK + "ronda_pontos_x2.png")

## sala de cada local montada com o fundo + objetos de parede vizinhos (para ver o capuz no lugar)
func room_basic(loc: String, level: int) -> Image:
	var bgid: String = {"garage": "garage_bg", "gym": "gym_bg", "center": "center_bg"}[loc]
	var im := load_png(res_abs(str(spr(bgid).file)))
	if loc == "garage":
		for o in [["wall_school_symbol", 0], ["lamp", 0]]:
			var e := spr(o[0])
			if not e.is_empty() and e.has("pos"):
				put(im, frame_of(o[0], o[1]), Vector2i(int(e.pos[0]), int(e.pos[1])), pivot_of(o[0]))
	var clip_id := ("wall_clipping_black_cat_l%d" % level) if loc == "garage" else ("wall_clipping_black_cat_gym_l%d" % level)
	var cp: Vector2i = Vector2i(304, 100) if loc == "garage" else Vector2i(340, 60)
	blend(im, frame_of(clip_id), cp.x, cp.y)
	# corrente e saco no centro (o alvo)
	var chain := frame_of("bag_chain_tile")
	for y in range(33, 183, 6):
		blend(im, chain.get_region(Rect2i(0, 0, 4, mini(6, 183 - y))), 334, y)
	var bag := "bag_l1_idle" + ("_gym" if loc == "gym" and not spr("bag_l1_idle_gym").is_empty() else ("_center" if loc == "center" else ""))
	if not spr(bag).is_empty():
		put(im, frame_of(bag), Vector2i(336, 183), pivot_of(bag))
	put(im, frame_of("hood_on_nail" if loc == "garage" else "hood_on_nail_gym"), HOOD_SPOT, HOOD_PIVOT)
	return im

func mock_hood_rooms() -> void:
	var crop := Rect2i(262, 30, 176, 124)
	var W := 3 * (crop.size.x * 3 + 12) + 12
	var H := crop.size.y * 3 + 40 + 360 + 40
	var b: Image = L.blank(W, H)
	L.R(b, 0, 0, W, H, "d1")
	label(b, "CAPUZ NO PREGO (16X22, PIVÔ 8,1 NO PREGO) EM %s NOS 3 LOCAIS, AO LADO DO RECORTE (NÍVEL 3). 3X" % str(HOOD_SPOT), 8, 6, "y1")
	var locs := ["garage", "gym", "center"]
	for i in 3:
		var room := room_basic(locs[i], 3)
		var x := 12 + i * (crop.size.x * 3 + 12)
		blend(b, scaled(room.get_region(crop), 3), x, 24)
		label(b, ["GARAGEM", "ACADEMIA", "CENTRO"][i], x, 24 + crop.size.y * 3 + 2, "cream")
	# capturas da sala cheia (ui_audit), se vieram: capuz e recorte colados por cima, 1x
	var caps := {"garage": "f6d2_garagem_cheia.png", "gym": "f6d2_academia_cheia.png", "center": "f8a2_centro_cheia_boxe.png"}
	var yy := crop.size.y * 3 + 44
	var used := 0
	for i in 3:
		var p: String = CAPS + caps[locs[i]]
		if CAPS == "" or not FileAccess.file_exists(p):
			continue
		var cap := load_png(p)
		if cap.get_width() == 1280:
			cap.resize(640, 360, Image.INTERPOLATE_NEAREST)
		if locs[i] == "garage":
			blend(cap, frame_of("wall_clipping_black_cat_l3"), 304, 100)
		put(cap, frame_of("hood_on_nail" if locs[i] == "garage" else "hood_on_nail_gym"), HOOD_SPOT, HOOD_PIVOT)
		var x := 12 + i * (crop.size.x * 3 + 12)
		blend(b, cap.get_region(Rect2i(0, 0, mini(640, crop.size.x * 3), 360)), x, yy)
		used += 1
	label(b, "EMBAIXO: CAPTURAS DO UI_AUDIT COM A SALA CHEIA (CORTADAS EM X 0..%d), CAPUZ COLADO POR CIMA" % (crop.size.x * 3) if used > 0 else "SEM CAPTURAS (--caps): SÓ A MONTAGEM", 8, yy - 14, "g3")
	b.save_png(MOCK + "ronda_capuz_locais_x3.png")
	# a sala inteira de cada local em 2x com o capuz (para o dono ver o tamanho de verdade)
	for i in 3:
		var p: String = CAPS + caps[locs[i]]
		var room: Image
		if CAPS != "" and FileAccess.file_exists(p):
			room = load_png(p)
			if room.get_width() == 1280:
				room.resize(640, 360, Image.INTERPOLATE_NEAREST)
			if locs[i] == "garage":
				blend(room, frame_of("wall_clipping_black_cat_l3"), 304, 100)
			put(room, frame_of("hood_on_nail" if locs[i] == "garage" else "hood_on_nail_gym"), HOOD_SPOT, HOOD_PIVOT)
		else:
			room = room_basic(locs[i], 3)
		scaled(room, 2).save_png(MOCK + "ronda_capuz_%s_x2.png" % ["garagem", "academia", "centro"][i])

func mock_clippings() -> void:
	var W := 1240
	var H := 560
	var b: Image = L.blank(W, H)
	L.R(b, 0, 0, W, H, "d1")
	label(b, "RECORTE DO GATO PRETO POR NÍVEL. EM CIMA: GARAGEM E ACADEMIA/CENTRO EM 1X E 4X (23X28). EMBAIXO: ZOOM DO HOVER (128X96) EM 1X", 8, 6, "y1")
	for lv in 6:
		var x := 8 + lv * 204
		var g: Image = frame_of("wall_clipping_black_cat", 0) if lv == 0 else frame_of("wall_clipping_black_cat_l%d" % lv)
		var y: Image = frame_of("wall_clipping_black_cat_gym", 0) if lv == 0 else frame_of("wall_clipping_black_cat_gym_l%d" % lv)
		label(b, "NÍVEL %d" % lv + (" (7A2)" if lv == 0 else ""), x, 22, "cream")
		blend(b, g, x, 36)
		blend(b, y, x + 28, 36)
		blend(b, scaled(g, 4), x, 70)
		blend(b, scaled(y, 4), x + 96, 70)
		var z: Image = frame_of("ui_clipping_black_cat_zoom") if lv == 0 else frame_of("ui_clipping_black_cat_zoom_l%d" % lv)
		blend(b, z, x + (0 if lv > 0 else 14), 200)
	# zooms em 2x numa 2ª linha (só os novos)
	for lv in range(1, 6):
		var z2 := scaled(frame_of("ui_clipping_black_cat_zoom_l%d" % lv), 2)
		var zx := 8 + (lv - 1) * 246
		blend(b, z2.get_region(Rect2i(0, 0, 240, 192)), zx, 306)
	label(b, "ZOOM 2X (CORTADO EM 120 PX DE LARGURA)", 8, 296, "g3")
	b.save_png(MOCK + "ronda_recortes_x4.png")

func mock_pieces() -> void:
	var W := 900
	var H := 520
	var b: Image = L.blank(W, H)
	L.R(b, 0, 0, W, H, "d1")
	label(b, "RONDA - PEÇAS (4X). PLACEHOLDER GERADO POR CÓDIGO", 8, 6, "y1")
	var x := 8
	var y := 24
	var row := func(ids: Array, k: int, y: int) -> int:
		var cx := 8
		var hmax := 0
		for id in ids:
			var n: int = F[id].size() if F.has(id) else 1
			for q in n:
				var im := scaled(frame_of(id, q), k)
				blend(b, im, cx, y + 12)
				cx += im.get_width() + 6
				hmax = maxi(hmax, im.get_height())
			cx += 8
		return hmax + 18
	label(b, "CAPUZ NO PREGO (GARAGEM: NORMAL, HOVER | ACADEMIA/CENTRO: NORMAL, HOVER), ÍCONE 16, ESTEPE, ALICATE, PÉ DE CABRA", 8, y, "cream")
	y += row.call(["hood_on_nail", "hood_on_nail_gym", "icon_ronda_16", "ronda_prop_tire", "ronda_prop_pliers", "ronda_prop_crowbar"], 4, y)
	label(b, "LENDA: ÍCONE 9 E 16, BOLINHA DO NÍVEL (APAGADA, ACESA, ACENDENDO), OCORRÊNCIA 9, AVISO DO LADRÃO (? COMEÇANDO, ?, ! OLHANDO)", 8, y, "cream")
	y += row.call(["icon_legend", "icon_legend_16", "ui_legend_pip", "icon_occurrence", "ui_thief_warn"], 4, y)
	label(b, "BARRA DE DISTÂNCIA: MOLDURA 9-SLICE, ENCHIMENTO (ANDANDO / PERTO), ZONA DO SUSTO (2 QUADROS)", 8, y, "cream")
	y += row.call(["ui_ronda_track", "ui_ronda_fill", "ui_ronda_zone"], 4, y)
	label(b, "MAPA: REGIÃO 16 E 9, PLAQUINHA, LADRILHO, ANEL NOITE (PEQUENO E MARCO), LACRADO, NÓS: ATALHO / O BAIRRO DE OLHO / O BAIRRO AGRADECE", 8, y, "cream")
	y += row.call(["icon_region_black_cat", "icon_region_black_cat_9", "ui_map_region_label_black_cat", "map_tile_black_cat_region"], 3, y)
	label(b, "", 8, y, "cream")
	y += row.call(["map_node_s_owned_night", "map_node_b_owned_night", "map_node_s_sealed", "map_node_b_sealed",
		"skill_black_cat_roof", "skill_black_cat_watch", "skill_black_cat_thanks"], 3, y) - 10
	b.save_png(MOCK + "ronda_pecas_x4.png")
	# letreiros na rua (1x da tela em 2x)
	var s := compose_street(3)
	put(s, frame_of("ui_banner_scare"), Vector2i(320, 118), pivot_of("ui_banner_scare"))
	put(s, frame_of("ui_banner_scare_near", 0), Vector2i(150, 140), pivot_of("ui_banner_scare_near"))
	put(s, frame_of("ui_banner_scare_near", 1), Vector2i(300, 70), pivot_of("ui_banner_scare_near"))
	put(s, frame_of("ui_banner_escaped"), Vector2i(500, 140), pivot_of("ui_banner_escaped"))
	for i in 3:
		put(s, frame_of("ui_thief_warn", i), Vector2i(OCC[OCC_ORDER[i]].thief.x + 2, THIEF_Y - 70), pivot_of("ui_thief_warn"))
	scaled(s, 2).save_png(MOCK + "ronda_letreiros_x2.png")
	# mapa: a região montada (ladrilho + 3 nós + linhas + plaquinha), x2
	var m: Image = L.blank(320, 200)
	L.R(m, 0, 0, 320, 200, "d1")
	var tile := frame_of("map_tile_black_cat_region")
	for ty in range(20, 180, 32):
		for tx in range(60, 260, 32):
			blend(m, tile, tx, ty)
	var np := {"cat_rooftop": Vector2i(160, 60), "cat_watch": Vector2i(222, 140), "cat_thanks": Vector2i(98, 140)}
	L.line(m, 160, 60, 222, 140, "g2"); L.line(m, 160, 60, 98, 140, "g2"); L.line(m, 98, 140, 222, 140, "g2")
	L.line(m, 160, 60, 20, 30, "g2")
	put(m, frame_of("map_node_s_owned_night"), np.cat_rooftop, pivot_of("map_node_s_owned_night"))
	blend(m, frame_of("skill_black_cat_roof"), np.cat_rooftop.x - 8, np.cat_rooftop.y - 8)
	put(m, frame_of("map_node_b_owned_night"), np.cat_watch, pivot_of("map_node_b_owned_night"))
	blend(m, frame_of("skill_black_cat_watch"), np.cat_watch.x - 8, np.cat_watch.y - 8)
	put(m, frame_of("map_node_b_sealed"), np.cat_thanks, pivot_of("map_node_b_sealed"))
	var lbx := 120
	var lby := 22
	var lbw: int = 21 + L.text_w("GATO PRETO")
	var lbl := frame_of("ui_map_region_label_black_cat")
	L.R(m, lbx, lby, lbw, 13, "ink"); L.R(m, lbx + 1, lby + 1, lbw - 2, 11, "d1"); L.R(m, lbx + 1, lby + 1, lbw - 2, 1, "d2")
	blend(m, lbl.get_region(Rect2i(0, 0, 4, 13)), lbx, lby)
	blend(m, frame_of("icon_region_black_cat_9"), lbx + 5, lby + 2)
	L.text(m, "GATO PRETO", lbx + 17, lby + 3, "cream")
	L.text(m, "PRECISA DA LENDA NÍVEL 5", 30, 166, "g3")
	scaled(m, 2).save_png(MOCK + "ronda_mapa_x2.png")

# ================================================================== CONFERÊNCIAS
func check_street() -> void:
	var problems := 0
	# 1) faixa do HUD (y 0..35) só céu; faixa de baixo (y 336..359) só asfalto
	var bad := 0
	for y in HUD_H:
		for x in 640:
			if not (color_name(BG.get_pixel(x, y)) in ["ink", "b0", "b1", "b2", "b3"]):
				bad += 1
	CHECKS.append("HUD de cima (y 0..%d): %d px que não são céu" % [HUD_H - 1, bad])
	problems += 1 if bad > 0 else 0
	# 2) atrás do caminho do vulto: meio-tom (nada de ink/d1/b0 chapado atrás da cabeça e do tronco)
	var v := vulto_standin()
	for occ in OCC_ORDER:
		var o: Dictionary = OCC[occ]
		var dark := 0
		var tot := 0
		for y in range(WALK_Y - 46, WALK_Y - 4):
			for x in range(o.start - 20, o.end + 20):
				tot += 1
				if color_name(BG.get_pixel(x, y)) in ["ink", "d1", "b0"]:
					dark += 1
		var pct := 100.0 * dark / tot
		CHECKS.append("fundo atrás do vulto no trecho %s: %.1f%% escuro (ink/d1/b0)" % [occ, pct])
		if pct > 12.0:
			problems += 1
			CHECKS.append("PROBLEMA: o vulto vai sumir no fundo do trecho %s" % occ)
		# 3) o caminho é pisável: há capa/marquise (g3) na linha de cima em todo o trecho
		for x in range(o.start - 20, o.end + 21):
			if color_name(BG.get_pixel(x, WALK_Y - 1)) != "g3" and color_name(BG.get_pixel(x, WALK_Y - 2)) != "g3":
				problems += 1
				CHECKS.append("PROBLEMA: trecho %s sem chão em x %d" % [occ, x])
				break
		# 4) o poste não corta o vulto em nenhum ponto do trecho
		if LAMP_X + 3 > o.start - VPIV.x and LAMP_X - 3 < o.end - VPIV.x + v.get_width():
			problems += 1
			CHECKS.append("PROBLEMA: o poste (x %d) corta o vulto no trecho %s" % [LAMP_X, occ])
		# 5) o ladrão fica numa poça de luz (o chão embaixo dele é mais claro que o resto da calçada)
		var lit := 0
		for x in range(o.thief.x - 10, o.thief.x + 11):
			if color_name(BG.get_pixel(x, o.thief.y - 2)) in ["g2", "g3"]:
				lit += 1
		CHECKS.append("chão aceso embaixo do ladrão %s: %d/21 px" % [occ, lit])
		if lit < 8:
			problems += 1
			CHECKS.append("PROBLEMA: ladrão %s fora da luz" % occ)
	CHECKS.append("CONFERÊNCIA DA RUA: %d problema(s)" % problems)

func check_hood() -> void:
	var problems := 0
	var r := Rect2i(HOOD_SPOT - HOOD_PIVOT, HOOD_SIZE)
	# ocupação conhecida das 3 salas (7a2/8a2 + manifest): recorte, símbolo, relógio, espelho, cartaz, porta, corrente, zona do alvo
	var busy := {
		"garage": {"recorte do vulto": Rect2i(304, 100, 23, 28), "símbolo da escola": Rect2i(344, 38, 32, 40), "corrente do saco": Rect2i(334, 33, 3, 150),
			"lâmpada": Rect2i(286, 32, 30, 48), "pôster SOCO": Rect2i(266, 62, 33, 42), "porta da garagem": Rect2i(378, 96, 92, 126)},
		"gym": {"recorte do vulto": Rect2i(340, 60, 23, 28), "relógio de rounds": Rect2i(370, 74, 28, 54), "espelho": Rect2i(262, 50, 70, 98),
			"corrente do saco": Rect2i(334, 33, 3, 150), "cartaz da liga": Rect2i(394, 54, 38, 54), "porta": Rect2i(401, 116, 60, 104)},
		"center": {"recorte do vulto": Rect2i(340, 60, 23, 28), "relógio de rounds": Rect2i(370, 74, 28, 26), "espelho": Rect2i(268, 50, 68, 98),
			"corrente do saco": Rect2i(334, 33, 3, 150), "porta de vidro": Rect2i(399, 106, 66, 114)},
	}
	var zone := Rect2i(273, 150, 98, 142)
	for loc in busy:
		for k in busy[loc]:
			if r.intersects(busy[loc][k]):
				problems += 1
				CHECKS.append("PROBLEMA: capuz em %s encosta em %s %s" % [loc, k, str(busy[loc][k])])
		if r.intersects(zone):
			problems += 1
			CHECKS.append("PROBLEMA: capuz na zona do alvo")
	# tudo o que o manifest posiciona (pos/positions) nas salas
	for sid in MAN.sprites:
		var e: Dictionary = MAN.sprites[sid]
		if not e.has("frame_size") or str(sid).ends_with("_bg") or str(sid) in ["gym_half_dark"] or str(sid).begins_with("hood_on_nail") or str(sid).begins_with("ronda_") or str(sid).begins_with("minigame"):
			continue
		var ps := []
		if e.has("pos") and e.pos is Array and e.pos.size() == 2:
			ps.append(e.pos)
		if e.has("positions") and e.positions is Dictionary:
			for k in e.positions:
				var p = e.positions[k]
				if p is Array and p.size() == 2 and (p[0] is float or p[0] is int):
					ps.append(p)
		var pv: Array = e.get("pivot", [0, 0])
		for p in ps:
			var rr := Rect2i(int(p[0]) - int(pv[0]), int(p[1]) - int(pv[1]), int(e.frame_size[0]), int(e.frame_size[1]))
			if rr.intersects(r) and not str(sid).begins_with("arena") and not str(sid).begins_with("fight"):
				problems += 1
				CHECKS.append("PROBLEMA: capuz encosta em %s %s" % [sid, str(rr)])
	# parede lisa embaixo do capuz nos 3 fundos (cores do fundo dentro do retângulo)
	for bgid in ["garage_bg", "gym_bg", "center_bg"]:
		var bg := load_png(res_abs(str(spr(bgid).file)))
		var hist := {}
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var n := color_name(bg.get_pixel(x, y))
				hist[n] = hist.get(n, 0) + 1
		CHECKS.append("parede embaixo do capuz em %s: %s" % [bgid, str(hist)])
	# painéis da tela (cards da esquerda até x 127 / y 114; painel fixado x >= 506)
	if r.intersects(Rect2i(0, 18, 128, 97)) or r.end.x > 506:
		problems += 1
		CHECKS.append("PROBLEMA: capuz embaixo de painel")
	CHECKS.append("CONFERÊNCIA DO CAPUZ %s: %d problema(s)" % [str(r), problems])

# ================================================================== MOCKUP DA TELA
## dublê do vulto agachado (a folha é do Artista de Personagens): 52x50, pivô VPIV = pés; virado para a direita.
## Agachado ~46 px (gente em pé = ~64). Só para medir o cenário: a folha de verdade é do Artista.
const VPIV := Vector2i(26, 49)
func vulto_standin(look_up := false) -> Image:
	var im: Image = L.blank(52, 50)
	# capa de lona caindo reta das costas até o muro (nunca aberta)
	L.trap(im, 18, 48, 17, 30, 7, 31, "d2")
	for x in [12, 17, 22, 27]:
		L.line(im, x + 3, 24, x, 48, "d1")
	L.R(im, 10, 36, 5, 5, "g0")                                   # remendo
	L.P(im, 10, 36, "g1"); L.P(im, 14, 40, "g1")
	# perna de trás (pé no muro) e a da frente dobrada
	L.R(im, 26, 44, 12, 5, "d1")
	L.ellipse(im, 36, 37, 8, 6, "d1")
	L.R(im, 37, 37, 7, 12, "d1")
	L.R(im, 40, 46, 8, 3, "ink")
	L.R(im, 40, 45, 6, 1, "d2")
	# tronco curvado + braço apoiado no joelho
	L.ellipse(im, 29, 28, 11, 10, "d1")
	L.line(im, 33, 25, 41, 34, "d2")
	L.line(im, 34, 25, 42, 34, "d1")
	L.line(im, 34, 26, 42, 35, "d1")
	L.R(im, 41, 33, 4, 4, "sk1")
	L.P(im, 44, 36, "sk0")
	# cabeça (capuz) + orelhas largas e baixas, costuradas
	var hx := 37
	var hy := 15 if not look_up else 14
	L.ellipse(im, hx, hy, 8.5, 8, "d1")
	for s in [-1, 1]:
		var ex = hx + s * 5
		L.trap(im, hy - 12, hy - 6, ex - (3 if s < 0 else 0), ex + (0 if s < 0 else 3), ex - 4, ex + 4, "d1")
	L.P(im, hx - 5, hy - 8, "g1"); L.P(im, hx - 6, hy - 7, "g1")
	L.P(im, hx + 5, hy - 8, "g1"); L.P(im, hx + 6, hy - 7, "g1")
	# rosto (boca/queixo) e a faixa nos olhos com as pontas voando para trás
	L.R(im, hx + 2, hy + 2, 6, 4, "sk1")
	L.R(im, hx + 2, hy + 5, 6, 1, "sk0")
	L.R(im, hx - 7, hy - 3, 16, 4, BAND)
	L.R(im, hx - 7, hy - 3, 16, 1, BAND_HI)
	L.R(im, hx + 4, hy - 2, 2, 1, "white")
	L.R(im, hx - 8, hy - 3, 3, 4, BAND_LO)                           # nó
	for k in 13:
		L.R(im, hx - 9 - k, hy - 4 + k / 3 + (1 if k % 5 == 2 else 0), 1, 2, BAND if k % 3 else BAND_LO)
	for k in 9:
		L.R(im, hx - 9 - k, hy + 1 + k / 2, 1, 1 + (k % 2), BAND_LO)
	# luz da lua por trás (borda de cima, 1 passo)
	var o := ol_keep(im)
	for y in 50:
		for x in 52:
			var c := o.get_pixel(x, y)
			if c.a == 0.0 or c.is_equal_approx(L.col("ink")):
				continue
			if y > 0 and o.get_pixel(x, y - 1).is_equal_approx(L.col("ink")) and color_name(c) in ["d1", "d2"]:
				o.set_pixel(x, y, L.col("g0"))
	return o

## dublê de ladrão: pedestre da Panfletagem com o moletom escurecido (a folha é do Artista)
func thief_standin(look: bool, q := 0) -> Array:
	var id := "ped_trabalhador_walk"
	var fr: Image = frame_of(id, q).duplicate()
	for y in fr.get_height():
		for x in fr.get_width():
			var c := fr.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var n := color_name(c)
			var m := {"b1": "d2", "b2": "g0", "b3": "g1", "b0": "d1", "gr1": "d2", "gr2": "g0", "gr0": "d1"}
			if m.has(n):
				fr.set_pixel(x, y, L.col(m[n]))
	var pv := pivot_of(id)
	if look:
		fr.flip_x()
		pv = Vector2i(fr.get_width() - 1 - pv.x, pv.y)
	return [fr, pv]

func compose_street(level: int) -> Image:
	var im: Image = BG.duplicate()
	var lay: Array = MAN_LAYERS[level]
	for k in lay:
		blend(im, LAYERS[k], 0, 0)
	return im

const MAN_LAYERS := [[], [], ["graffiti"], ["graffiti", "banner"], ["graffiti", "banner", "kid_ears"],
	["graffiti", "banner", "kid_ears", "whole_street"]]

func vulto_at(im: Image, occ: String, d: float, look_up := false) -> Vector2i:
	var o: Dictionary = OCC[occ]
	var x := int(round(lerpf(o.start, o.end, d)))
	var v := vulto_standin(look_up)
	put(im, v, Vector2i(x, WALK_Y), VPIV)
	return Vector2i(x, WALK_Y)

func draw_track(im: Image, occ: String, d: float, near: bool) -> void:
	var o: Dictionary = OCC[occ]
	var x0: int = o.start - 4
	var x1: int = o.end + 4
	var w := x1 - x0
	var tr := frame_of("ui_ronda_track")
	# 9-slice simples (1 px de borda)
	L.R(im, x0, TRACK_Y, w, 6, "ink")
	L.R(im, x0 + 1, TRACK_Y + 1, w - 2, 4, "d1")
	L.R(im, x0 + 1, TRACK_Y + 4, w - 2, 1, "b0")
	var zx := x0 + 1 + int((w - 2) * 0.8)
	var z := frame_of("ui_ronda_zone", 1 if near else 0)
	for x in range(zx, x1 - 1, 4):
		blend(im, z.get_region(Rect2i(0, 0, mini(4, x1 - 1 - x), 4)), x, TRACK_Y + 1)
	var fw := int((w - 2) * d)
	var fl := frame_of("ui_ronda_fill", 1 if near else 0)
	for x in range(x0 + 1, x0 + 1 + fw, 4):
		blend(im, fl.get_region(Rect2i(0, 0, mini(4, x0 + 1 + fw - x), 4)), x, TRACK_Y + 1)
	L.R(im, zx, TRACK_Y - 1, 1, 8, "y1" if near else "g3")

func hud(im: Image, level: int, occ_i: int, scares: int, secs: int, tip: bool) -> void:
	# topo (céu): LENDA + bolinhas do nível | OCORRÊNCIA n/3 + sustos | tempo
	blend(im, frame_of("icon_legend_16"), 8, 8)
	L.text(im, "LENDA", 28, 8, "cream", 1, "ink")
	for i in 5:
		blend(im, frame_of("ui_legend_pip", 1 if i < level else 0), 28 + i * 9, 18)
	L.panel(im, 252, 4, 136, 22, "d1", "d2", "ink")
	L.text_center(im, "OCORRÊNCIA %d DE 3" % (occ_i + 1), 320, 8, "white")
	for i in 3:
		if i < scares:
			blend(im, frame_of("icon_occurrence"), 302 + i * 12, 16)
		else:
			L.R(im, 304 + i * 12, 18, 5, 5, "d2")
	L.panel(im, 586, 4, 48, 18, "d1", "d2", "ink")
	L.text_center(im, "%d S" % secs, 610, 9, "white")
	L.button(im, 8, 334, 48, 18, "d2", "SAIR")
	if tip:
		L.text_center(im, "SEGURE PARA ANDAR. SOLTE QUANDO ELE OLHAR. PERTO, CLIQUE!", 340, 343, "cream", 1, "ink")

func mock_screens() -> void:
	# 1) trecho 1, andando (AVISO: o ladrão parou e o ? apareceu), nível 0
	var a := compose_street(0)
	var o: Dictionary = OCC.tire
	put(a, frame_of("ronda_prop_tire"), o.prop, pivot_of("ronda_prop_tire"))
	var th := thief_standin(false)
	put(a, th[0], o.thief, th[1])
	vulto_at(a, "tire", 0.45)
	draw_track(a, "tire", 0.45, false)
	put(a, frame_of("ui_thief_warn", 1), Vector2i(o.thief.x + 2, o.thief.y - 70), pivot_of("ui_thief_warn"))
	hud(a, 0, 0, 0, 27, true)
	scaled(a, 2).save_png(MOCK + "ronda_tela_aviso_x2.png")
	# 2) trecho 2, PERTO (letreiro piscando), nível 3 (pichação + faixa); 1 susto já feito
	var b := compose_street(3)
	o = OCC.bike
	var th2 := thief_standin(false, 3)
	put(b, th2[0], o.thief, th2[1])
	vulto_at(b, "bike", 0.9)
	draw_track(b, "bike", 0.9, true)
	var nb := frame_of("ui_banner_scare_near")
	put(b, nb, Vector2i(int(lerpf(o.start, o.end, 0.9)), WALK_Y - 50), pivot_of("ui_banner_scare_near"))
	hud(b, 3, 1, 1, 17, false)
	scaled(b, 2).save_png(MOCK + "ronda_tela_perto_x2.png")
	# 3) trecho 3, SUSTO! (vulto caiu atrás do ladrão, pé de cabra voando, poeira), nível 5
	var c := compose_street(5)
	o = OCC.gate
	var th3 := thief_standin(true, 5)
	put(c, th3[0], o.thief + Vector2i(8, 0), th3[1])
	var v := vulto_standin()
	put(c, v, o.land, VPIV)
	var cb := frame_of("ronda_prop_crowbar")
	put(c, cb, Vector2i(o.thief.x + 20, o.thief.y - 78), pivot_of("ronda_prop_crowbar"))
	var dust := frame_of("fx_dust_fall", 1)
	put(c, dust, Vector2i(o.land.x, o.land.y + 2), pivot_of("fx_dust_fall"))
	put(c, frame_of("ui_banner_scare"), Vector2i(320, 118), pivot_of("ui_banner_scare"))
	hud(c, 5, 2, 3, 6, false)
	var c2 := scaled(c, 2)
	c2.save_png(MOCK + "ronda_tela_susto_x2.png")
	# 4) fundo puro
	BG.save_png(MOCK + "ronda_fundo.png")
	scaled(BG, 2).save_png(MOCK + "ronda_fundo_x2.png")
