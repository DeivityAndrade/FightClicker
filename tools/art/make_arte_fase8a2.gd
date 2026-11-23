extends SceneTree
## Fase 8a2 (Diretor de Arte): Centro de Treinamento Raízes. PLACEHOLDER gerado por código, tudo original.
##   godot --headless --path <worktree> --script res://tools/art/make_arte_fase8a2.gd              (sprites + mockups)
##   godot --headless --path <worktree> --script res://tools/art/make_arte_fase8a2.gd -- --no-assets  (só mockups)
## Depois: python tools/art/manifest_8a2.py (lê tools/art/fase8a2_sprites.json, que este script grava).
## Grava:
##   assets/sprites/center/center_bg.png, center_led.png                     (sala larga do centro, padrão da 6d2)
##   assets/sprites/center/wall_clipping_regional_framed.png                  (recorte emoldurado, D10)
##   assets/sprites/center/sponsor_envelope.png                               (envelope PROPOSTA; vale nos 3 locais)
##   assets/sprites/equipment/<aparelho>_l0|l1_<quadro>_center.png            (37 folhas: saco, corda, esteira, pera, boneco, saco comprido)
##   assets/sprites/gym/wall_poster_league_regional_won_gym.png               (cartaz vencido: adesivo do R + recorte; quadro 1 = com a marca)
##   assets/sprites/ui/ui_poster_league_regional_won_zoom.png, ui_clipping_regional_zoom.png
##   assets/sprites/ui/sponsor_vale.png, sponsor_vale_wide.png, sponsor_vale_9.png, sponsor_vale_patch.png
##   assets/sprites/ui/icon_region_center(_9).png, ui/map/ui_map_region_label_center.png, map_tile_center_region.png,
##   map_node_s|b_owned_steel.png
##   docs/arte/mockups/fase8a2_*.png
## Pontos (pés = pivô) iguais aos da academia (6d2) para Osmar, mentores, equipe antiga, aparelhos e caixas. Novos: alunos,
## foto torta + recorte emoldurado (canto da memória), envelope. Conferência pixel a pixel no fim (CHECKS).
## Alunos: se o Artista de Personagens já gravou a folha (STUDENT_SHEETS), a conferência usa ela; senão um dublê
## (o lutador em guarda com camiseta preta e o R). Rodar de novo quando a folha chegar.

const TXT_BRAND := "VALE FORTE"           # short_name do patrocinador (fase8a2-textos.md §2)
const TXT_CLIP_HEAD := "RAÍZES"           # manchete curta legível em 1x (o título inteiro vai no zoom/hover)
const TXT_CLIP_Z1 := "ESCOLA DE GARAGEM"
const TXT_CLIP_Z2 := "DERRUBA O BLINDADO"
const TXT_PROPOSAL := "PROPOSTA"

var ROOT := ""
var OUT := ""
var MOCK := ""
var NO_ASSETS := false
var L
var MAN := {}
var F := {}      # id -> Array[Image]
var META := {}   # id -> {rel, frame_size, frames, fps, pivot}
var CHECKS := []

# ---------------------------------------------------------------- geometria (a mesma da 6d2)
const VPX := 320.0
const VPY := -28.0
const FLOOR_Y := 220
const BW0 := 70
const BW1 := 570
const STRIP_Y := 330
const PANEL_X := 506
const ALVO := Rect2i(273, 150, 98, 142)
const BEAM_Y := 26                 # viga de aço y 26..33 (ganchos em x 258 e 336; a corrente começa em y 33)
const WAIN_Y := 150                # barrado azul da escola y 150..219
const PIL_L := Rect2i(164, 18, 11, 202)
const PIL_R := Rect2i(468, 18, 11, 202)
const DOOR := Rect2i(401, 116, 60, 104)
const LEDS := [Vector2i(118, 46), Vector2i(230, 40), Vector2i(392, 40), Vector2i(522, 46)]  # pivô = meio de cima

# ---------------------------------------------------------------- pontos
const P_FIGHTER := Vector2i(303, 272)
const P_BAG := Vector2i(336, 183)
const P_BAG_SIDE := Vector2i(258, 160)
const P_ROPE := Vector2i(296, 166)
const P_PERA_WALL := Vector2i(436, 46)
const P_TREAD := Vector2i(466, 324)
const P_ART_REST := Vector2i(192, 318)
const P_COACH := Vector2i(196, 236)
const P_MENTOR := Vector2i(132, 254)
const P_CRATE := Vector2i(116, 234)
const P_MENTOR2 := Vector2i(62, 256)
const P_METRO := Vector2i(240, 118)
const P_MURAL := Vector2i(176, 128)
const P_CAT := Vector2i(340, 60)
const CREW_P := {"neighbor_1": Vector2i(72, 322), "neighbor_2": Vector2i(126, 322), "neighbor_3": Vector2i(590, 322),
	"uncle_1": Vector2i(400, 324), "uncle_2": Vector2i(484, 262), "coach_1": Vector2i(548, 250)}
# novos da 8a2
const P_CLIP_FRAMED := Vector2i(78, 96)       # canto de cima à esquerda (36x36): canto da memória, parede da ala esquerda
const P_PHOTO := Vector2i(120, 104)           # foto torta (wall_photo_old_gym quadro 1), ao lado do recorte
const P_ENVELOPE := Vector2i(250, 302)        # pivô = meio da base; no chão, à esquerda dos pés do lutador, entre o tatame e a caixa da luva (igual nos 3 locais)
# alunos: [pés, virado para] na ordem em que aparecem (1, 5, 12, 25 unidades)
# (folhas do Artista: student_1 sombra/direita, student_2 corda/esquerda, student_3 corrida/esquerda, student_4 joelhada/direita;
#  cada ponto respeita o lado da folha, sem espelhar: o R do peito continua legível)
const STUDENTS := [[Vector2i(390, 250), "direita"], [Vector2i(436, 257), "esquerda"], [Vector2i(530, 316), "esquerda"],
	[Vector2i(24, 300), "direita"]]
const STUDENT_SHEETS := ["student_1", "student_2", "student_3", "student_4"]
const GPIV := Vector2i(22, 67)

func _init() -> void:
	ROOT = ProjectSettings.globalize_path("res://")
	if not ROOT.ends_with("/"):
		ROOT += "/"
	OUT = ROOT + "assets/sprites/"
	MOCK = ROOT + "docs/arte/mockups/"
	NO_ASSETS = OS.get_cmdline_user_args().has("--no-assets")
	L = load("res://tools/art/pixel_lib.gd").new()
	var f := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.READ)
	MAN = JSON.parse_string(f.get_as_text())
	f.close()
	make_bg()
	make_apparatus()
	make_clipping()
	make_poster_won()
	make_sponsor()
	make_map()
	make_student_icon()
	if not NO_ASSETS:
		var fo := FileAccess.open(ROOT + "tools/art/fase8a2_sprites.json", FileAccess.WRITE)
		fo.store_string(JSON.stringify(META, "\t", true))
		fo.close()
	mock_sala()
	mock_pecas()
	mock_cartaz()
	mock_patrocinio()
	check_sala()
	check_envelope_outros()
	check_cartaz()
	for c in CHECKS:
		print(c)
	print("8a2: ", META.size(), " sprites", " (não gravados)" if NO_ASSETS else "", "; mockups em ", MOCK)
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

func nframes(id: String) -> int:
	if F.has(id):
		return F[id].size()
	return int(spr(id).get("frames", 1))

func pivot_of(id: String) -> Vector2i:
	if META.has(id):
		return Vector2i(int(META[id].pivot[0]), int(META[id].pivot[1]))
	var e := spr(id)
	return Vector2i(int(e.pivot[0]), int(e.pivot[1])) if e.has("pivot") else GPIV

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

func ol(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

## troca de cores por nome da paleta (só os pixels opacos com cor no mapa)
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

# ---------------------------------------------------------------- fonte 3x5 (a do cartaz da 8a1 + letras novas)
const MINI := {
	"D": ["##.", "#.#", "#.#", "#.#", "##."], "O": ["###", "#.#", "#.#", "#.#", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."], "A": [".#.", "#.#", "###", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"], "E": ["###", "#..", "##.", "#..", "###"],
	"B": ["##.", "#.#", "##.", "#.#", "##."], "I": ["###", ".#.", ".#.", ".#.", "###"],
	"N": ["#.#", "###", "###", "#.#", "#.#"], "C": ["###", "#..", "#..", "#..", "###"],
	"P": ["##.", "#.#", "##.", "#..", "#.."], "M": ["#.#", "###", "#.#", "#.#", "#.#"],
	"Ã": ["###", "#.#", "###", "#.#", "#.#"], ":": ["...", ".#.", "...", ".#.", "..."],
	"R": ["##.", "#.#", "##.", "#.#", "#.#"], "Z": ["###", "..#", ".#.", "#..", "###"],
	"S": ["###", "#..", "###", "..#", "###"], "Í": [".#.", "...", ".#.", ".#.", ".#."],
	"F": ["###", "#..", "##.", "#..", "#.."], "T": ["###", ".#.", ".#.", ".#.", ".#."],
	"G": ["###", "#..", "#.#", "#.#", "###"], "U": ["#.#", "#.#", "#.#", "#.#", "###"],
}

func mini_text(img: Image, s: String, x: int, y: int, c) -> void:
	for i in s.length():
		if s[i] == " " or not MINI.has(s[i]):
			continue
		var g: Array = MINI[s[i]]
		for r in 5:
			for k in 3:
				if g[r][k] == "#":
					L.P(img, x + i * 4 + k, y + r, c)

func mini_w(s: String) -> int:
	return s.length() * 4 - 1

# ================================================================== FUNDO: center_bg (640x360)
func floor_hw(y: float) -> float:
	return 250.0 * (y - VPY) / (FLOOR_Y - VPY)

func side_s(x: float) -> float:
	return absf(VPX - x) / (VPX - BW0)

func side_y(x: float, yb: float) -> float:
	return VPY + (yb - VPY) * side_s(x)

func on_floor(x: int, y: int) -> bool:
	return y >= FLOOR_Y and absf(x + 0.5 - VPX) <= floor_hw(y + 0.5)

var BG: Image

func make_bg() -> void:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	paint_back_wall(img)
	paint_side_walls(img)
	paint_floor(img)
	paint_left_bay(img)
	paint_center_bay(img)
	paint_right_bay(img)
	paint_pillars(img)
	paint_beam(img)
	for p in LEDS:
		blend(img, led(true), p.x - 20, p.y)
	center_light(img)
	L.R(img, 0, 0, 640, 18, "ink")
	BG = img
	save_sheet("center_bg", "center/center_bg.png", [img], 0.0, Vector2i.ZERO)
	save_sheet("center_led", "center/center_led.png", [led(true), led(false)], 0.0, Vector2i(20, 0))

## painel de LED pendurado (40x8): 2 cabos, corpo de aço, difusor branco. Quadro 1 = apagado (falha opcional).
func led(on: bool) -> Image:
	var im: Image = L.blank(40, 8)
	L.R(im, 6, 0, 1, 4, "g0"); L.R(im, 33, 0, 1, 4, "g0")
	L.R(im, 0, 4, 40, 4, "ink")
	L.R(im, 1, 4, 38, 1, "st2")
	L.R(im, 1, 5, 38, 2, "white" if on else "g2")
	L.R(im, 1, 6, 38, 1, "y2" if on else "g1")
	return im

func paint_back_wall(img: Image) -> void:
	# alto: concreto pintado de branco em blocos 20x10 (juntas leves); embaixo, o barrado azul da escola
	for y in range(18, FLOOR_Y):
		for x in range(BW0, BW1):
			var c := "cream"
			if y < WAIN_Y:
				var row := (y - 18) / 10
				var off := 10 if row % 2 == 1 else 0
				if (y - 18) % 10 == 9 or (x + off - BW0) % 20 == 19:
					c = "g3"
				elif hsh(x, y, 3) < 0.04:
					c = "white"
			else:
				c = "b1"
				if y == WAIN_Y or y == WAIN_Y + 1:
					c = "white" if y == WAIN_Y else "b2"
				elif y >= FLOOR_Y - 5:
					c = "d1" if y >= FLOOR_Y - 4 else "ink"
				elif hsh(x, y, 5) < 0.05:
					c = "b0"
			L.P(img, x, y, c)
	# alto da parede: sombra do forro (pé-direito alto: a parede sobe para o escuro)
	for y in range(18, 26):
		for x in range(BW0, BW1):
			if y < 22 or bayer(x, y) < float(26 - y) / 6.0:
				L.P(img, x, y, "d2" if y >= 20 else "d1")

func paint_side_walls(img: Image) -> void:
	for x in range(0, BW0):
		var yt := side_y(x, 18.0)
		var yw := side_y(x, float(WAIN_Y))
		var yf := side_y(x + 0.5, float(FLOOR_Y))
		for y in range(18, mini(int(yf), 360)):
			var c := "d1"
			if y >= int(yt):
				c = "g3" if y < int(yw) else "b0"
				if y == int(yw):
					c = "g3"
				if y >= int(yf) - 3:
					c = "ink"
			L.P(img, x, y, c)
	for x in range(BW1, 640):
		var yt := side_y(x, 18.0)
		var yw := side_y(x, float(WAIN_Y))
		var yf := side_y(x + 0.5, float(FLOOR_Y))
		for y in range(18, mini(int(yf), 360)):
			var c := "d1"
			if y >= int(yt):
				c = "g3" if y < int(yw) else "b0"
				if y == int(yw):
					c = "g3"
				if y >= int(yf) - 3:
					c = "ink"
			L.P(img, x, y, c)
	# janelões nas paredes laterais (luz do dia de lado): quadro de aço, vidro azul-claro, travessas
	for side in [0, 1]:
		var xa := 10 if side == 0 else 582
		var xb := 58 if side == 0 else 630
		for x in range(xa, xb):
			var y0 := int(side_y(x, 40.0))
			var y1 := int(side_y(x, 128.0))
			for y in range(y0, y1):
				var c := "b3"
				var u := float(y - y0) / float(maxi(y1 - y0, 1))
				if x == xa or x == xb - 1 or y == y0 or y == y1 - 1:
					c = "st0"
				elif (x - xa) % 16 == 0 or absf(u - 0.5) < 0.5 / float(maxi(y1 - y0, 1)):
					c = "st1"
				elif ((x + y) % 11 == 0) or ((x + y + 1) % 11 == 0 and u < 0.6):
					c = "white"
				elif u > 0.55:
					c = "b2" if bayer(x, y) < (u - 0.55) * 3.0 else "b3"
				L.P(img, x, y, c)
			L.P(img, x, y1, "ink")
	# protetor de parede azul na parede direita (embaixo do janelão)
	for x in range(586, 628):
		var y0 := int(side_y(x, 156.0))
		var y1 := int(side_y(x, 212.0))
		for y in range(y0, y1):
			var c := "b2"
			if x == 586 or x == 627 or y == y0 or y == y1 - 1:
				c = "ink"
			elif (x - 586) % 14 == 0:
				c = "b1"
			elif y == y0 + 1:
				c = "b3"
			L.P(img, x, y, c)

func paint_floor(img: Image) -> void:
	# piso de borracha: placas grandes (seams fracos na perspectiva), salpicado de grânulos; tatame vermelho na frente à esquerda
	for y in range(FLOOR_Y, 360):
		var hw := floor_hw(y + 0.5)
		var t := (float(y) - VPY)
		for x in range(0, 640):
			if not on_floor(x, y) and y < 300:
				continue
			var c := "d2"
			# seams: linhas para o ponto de fuga a cada 50 px na linha do fundo; horizontais em profundidade igual
			var u := (x + 0.5 - VPX) / hw * 250.0     # coordenada x na linha do fundo
			var du := posmod(int(floor(u + 1000.0)), 50)
			var depth := 248.0 * 248.0 / t           # proporcional à distância
			var dv := posmod(int(floor(depth * 0.9)), 40)
			if du == 0 or dv == 0:
				c = "d1"
			elif hsh(x, y, 9) < 0.05:
				c = "g0"
			elif hsh(x, y, 11) < 0.02:
				c = "d1"
			L.P(img, x, y, c)
	# tatame vermelho (frente à esquerda, embaixo do boneco / saco comprido deitado em 192,318)
	for y in range(292, 330):
		var hw := floor_hw(y + 0.5)
		for x in range(0, 640):
			var u := (x + 0.5 - VPX) / hw * 250.0
			if u < -228.0 or u > -78.0:
				continue
			var c := "r1"
			var cell := posmod(int(floor((u + 228.0) / 50.0)), 2)
			if cell == 1:
				c = "r0"
			if absf(u + 228.0) < 1.2 or absf(u + 78.0) < 1.2 or y == 292:
				c = "ink"
			elif y == 293:
				c = "r2"
			elif hsh(x, y, 13) < 0.03:
				c = "r2"
			L.P(img, x, y, c)
	# linha amarela de área de treino (fita no chão) em volta do alvo, só no fundo e nas laterais, discreta
	for y in range(236, 292):
		var hw := floor_hw(y + 0.5)
		for uu in [-90.0, 92.0]:
			var x := int(round(VPX + uu * hw / 250.0))
			if y % 4 != 3:
				L.P(img, x, y, "br2")
	for x in range(int(VPX - 90.0 * floor_hw(236.5) / 250.0), int(VPX + 92.0 * floor_hw(236.5) / 250.0) + 1):
		if x % 4 != 3:
			L.P(img, x, 236, "br2")

func window_back(img: Image, r: Rect2i) -> void:
	L.R(img, r.position.x - 1, r.position.y - 1, r.size.x + 2, r.size.y + 2, "ink")
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var u := float(y - r.position.y) / float(r.size.y)
			var c := "b3"
			if u > 0.6 and bayer(x, y) < (u - 0.6) * 2.5:
				c = "b2"
			if (x - r.position.x + y) % 13 == 0 and u < 0.7:
				c = "white"
			L.P(img, x, y, c)
	for x in range(r.position.x, r.end.x, 18):
		L.R(img, x, r.position.y, 2, r.size.y, "st1")
		L.P(img, x, r.position.y, "st2")
	L.R(img, r.position.x, r.position.y + r.size.y / 2, r.size.x, 2, "st1")
	L.R(img, r.position.x, r.end.y - 1, r.size.x, 1, "st0")
	L.R(img, r.position.x - 1, r.end.y, r.size.x + 2, 2, "g3")   # peitoril
	L.R(img, r.position.x - 1, r.end.y + 2, r.size.x + 2, 1, "g2")

func paint_left_bay(img: Image) -> void:
	window_back(img, Rect2i(80, 40, 78, 44))
	# canto da memória: plaquinha de madeira embaixo (o recorte e a foto são sprites por cima; a parede fica lisa atrás)
	# caixotes de pliometria empilhados no pé da parede (entre o 2º mentor e o caixote do John)
	var bx := [[78, 198, 22, 22, "br2"], [81, 186, 16, 12, "br3"]]
	for b in bx:
		L.R(img, b[0], b[1], b[2], b[3], "ink")
		L.R(img, b[0] + 1, b[1] + 1, b[2] - 2, b[3] - 2, b[4])
		L.R(img, b[0] + 1, b[1] + 1, b[2] - 2, 1, "y0" if b[4] == "br3" else "br3")
		L.R(img, b[0] + b[2] / 2 - 2, b[1] + b[3] / 2 - 1, 4, 2, "br1")
	# bolas medicinais no chão do canto (encostadas no barrado)
	for p in [[146, 214], [156, 215]]:
		L.ellipse(img, p[0], p[1], 5, 5, "ink")
		L.ellipse(img, p[0], p[1], 4, 4, "gr1")
		L.P(img, p[0] - 2, p[1] - 2, "gr2"); L.P(img, p[0] - 1, p[1] - 2, "gr2")
		L.R(img, p[0] - 4, p[1], 8, 1, "gr0")

func paint_center_bay(img: Image) -> void:
	# R da escola pintado grande na parede (o school_symbol_32 em azul da escola, contorno creme)
	var sym := load_png(ROOT + "assets/sprites/ui/school_symbol_32.png")
	var paint: Image = L.blank(32, 32)
	for y in 32:
		for x in 32:
			var c := sym.get_pixel(x, y)
			if c.a > 0.0:
				var n := color_name(c)
				paint.set_pixel(x, y, L.col("b2" if n in ["b2", "b3", "white", "cream"] else "b1"))
	var big := scaled(paint, 1)
	blend(img, big, 188, 46)
	# prateleira de aço do Metrônomo (240,118) com garrafinha e medalha
	L.R(img, 218, 118, 50, 3, "ink")
	L.R(img, 219, 118, 48, 1, "st3"); L.R(img, 219, 119, 48, 1, "st1")
	for bxx in [222, 262]:
		L.R(img, bxx, 121, 1, 6, "st0"); L.line(img, bxx, 126, bxx + (4 if bxx == 222 else -4), 121, "st0")
	L.R(img, 254, 110, 4, 8, "ink"); L.R(img, 255, 111, 2, 7, "b2"); L.P(img, 255, 110, "white")
	L.ellipse(img, 262.5, 113.5, 3, 3, "ink"); L.ellipse(img, 262.5, 113.5, 2, 2, "y1"); L.R(img, 262, 108, 1, 3, "r2")
	# quadro de cortiça (o mural cobre: 176,128 55x23)
	L.R(img, 176, 128, 55, 23, "ink")
	L.R(img, 177, 129, 53, 21, "br2")
	# espelho inteiro (o da academia era trincado): x 270..332, y 52..146
	var mr := Rect2i(270, 52, 62, 94)
	L.R(img, mr.position.x - 2, mr.position.y - 2, mr.size.x + 4, mr.size.y + 4, "ink")
	L.R(img, mr.position.x - 1, mr.position.y - 1, mr.size.x + 2, mr.size.y + 2, "st2")
	for y in range(mr.position.y, mr.end.y):
		for x in range(mr.position.x, mr.end.x):
			var c := "g3"
			var k := (x - mr.position.x) + (y - mr.position.y) * 0.5
			if posmod(int(k), 46) < 2 or posmod(int(k) + 9, 46) < 1:
				c = "white"
			elif y > mr.end.y - 30 and bayer(x, y) < float(y - (mr.end.y - 30)) / 40.0:
				c = "g2"
			L.P(img, x, y, c)
	# relógio de round (digital, sem texto além dos números)
	L.R(img, 372, 78, 24, 17, "ink")
	L.R(img, 373, 79, 22, 15, "d1")
	L.text(img, "3:00", 373, 80, "r2", 1)
	for i in 3:
		L.R(img, 376 + i * 6, 90, 4, 2, ["gr2", "y1", "r2"][i])
	# porta de vidro dupla (x 401..460, y 116..219): quadro de aço, vidro com o dia lá fora, barras de empurrar
	L.R(img, DOOR.position.x - 2, DOOR.position.y - 2, DOOR.size.x + 4, DOOR.size.y + 2, "ink")
	L.R(img, DOOR.position.x - 1, DOOR.position.y - 1, DOOR.size.x + 2, DOOR.size.y + 1, "st1")
	for half in 2:
		var gx := DOOR.position.x + 2 + half * 29
		var gr := Rect2i(gx, DOOR.position.y + 2, 26, DOOR.size.y - 10)
		for y in range(gr.position.y, gr.end.y):
			for x in range(gr.position.x, gr.end.x):
				var u := float(y - gr.position.y) / float(gr.size.y)
				var c := "b3"
				if u > 0.55:
					c = "gr2" if bayer(x, y) < 0.5 else "b3"      # calçada / mato lá fora
				if u > 0.75:
					c = "g2" if bayer(x, y) < 0.6 else "g3"
				if (x - gr.position.x + y) % 17 == 0 and u < 0.5:
					c = "white"
				L.P(img, x, y, c)
		L.R(img, gx, DOOR.position.y + 50, 26, 3, "ink")
		L.R(img, gx + 1, DOOR.position.y + 50, 24, 1, "st3"); L.R(img, gx + 1, DOOR.position.y + 51, 24, 1, "st2")
	L.R(img, DOOR.position.x + 29, DOOR.position.y, 2, DOOR.size.y, "st0")
	L.R(img, DOOR.position.x, DOOR.end.y - 6, DOOR.size.x, 6, "st0")
	# luz verde de saída (sem texto) e extintor
	L.R(img, 424, 107, 14, 6, "ink"); L.R(img, 425, 108, 12, 4, "gr2"); L.R(img, 427, 109, 8, 2, "gr3")
	L.R(img, 386, 172, 7, 18, "ink"); L.R(img, 387, 174, 5, 15, "r1"); L.R(img, 387, 174, 2, 15, "r2"); L.R(img, 388, 171, 3, 2, "d1")
	# gancho da corda no barrado (296,166) e o banco atrás do Osmar
	L.R(img, 294, 162, 5, 2, "ink"); L.R(img, 295, 162, 3, 1, "st3"); L.R(img, 296, 164, 1, 3, "st2")
	L.R(img, 178, 200, 70, 4, "ink"); L.R(img, 179, 200, 68, 1, "br3"); L.R(img, 179, 201, 68, 2, "br2")
	for lx in [182, 242]:
		L.R(img, lx, 204, 3, 15, "ink"); L.R(img, lx + 1, 204, 1, 15, "st1")
	# mochila e toalha no banco
	L.R(img, 222, 191, 14, 9, "ink"); L.R(img, 223, 192, 12, 8, "b0"); L.R(img, 223, 192, 12, 1, "b2"); L.R(img, 227, 195, 4, 2, "y1")
	L.R(img, 186, 196, 12, 4, "ink"); L.R(img, 187, 196, 10, 3, "white"); L.R(img, 187, 198, 10, 1, "g3")
	# tomada e rodapé
	L.R(img, 360, 196, 6, 6, "ink"); L.R(img, 361, 197, 4, 4, "cream")

func paint_right_bay(img: Image) -> void:
	window_back(img, Rect2i(486, 40, 76, 44))
	# vitrine de troféus: o cinturão amador (vermelho) e o do Vale (preto e ouro), troféus e medalhas
	var v := Rect2i(490, 108, 56, 96)
	L.R(img, v.position.x - 1, v.position.y - 1, v.size.x + 2, v.size.y + 2, "ink")
	L.R(img, v.position.x, v.position.y, v.size.x, v.size.y, "br1")
	L.R(img, v.position.x, v.position.y, v.size.x, 1, "br2")
	var gl := Rect2i(v.position.x + 3, v.position.y + 3, v.size.x - 6, v.size.y - 10)
	L.R(img, gl.position.x, gl.position.y, gl.size.x, gl.size.y, "d1")
	for s in 3:
		var sy := gl.position.y + 26 + s * 28
		L.R(img, gl.position.x, sy, gl.size.x, 2, "g2"); L.R(img, gl.position.x, sy + 2, gl.size.x, 1, "d2")
	# prateleira 1: cinturão do Vale aberto (preto, placa de ouro, esmalte azul)
	L.R(img, 498, 124, 38, 6, "ink"); L.R(img, 499, 125, 36, 4, "d2")
	L.ellipse(img, 517, 126.5, 7, 5, "ink"); L.ellipse(img, 517, 126.5, 6, 4, "y0"); L.ellipse(img, 517, 126.5, 3, 2, "b2"); L.P(img, 516, 125, "y2")
	# prateleira 2: cinturão amador (vermelho, caixinha de ouro) e um troféu
	L.R(img, 497, 154, 26, 5, "ink"); L.R(img, 498, 155, 24, 3, "r1"); L.R(img, 506, 153, 8, 7, "ink"); L.R(img, 507, 154, 6, 5, "y1")
	L.R(img, 529, 146, 8, 2, "y0"); L.R(img, 531, 148, 4, 6, "y1"); L.R(img, 530, 154, 6, 2, "br2")
	# prateleira 3: medalhas e uma luva velha (a da garagem)
	for i in 3:
		L.line(img, 500 + i * 7, 168, 502 + i * 7, 176, "r2")
		L.ellipse(img, 502.5 + i * 7, 178.5, 2.5, 2.5, ["y1", "g3", "br3"][i])
	L.R(img, 524, 172, 12, 10, "ink"); L.R(img, 525, 173, 10, 8, "r1"); L.R(img, 525, 173, 4, 3, "r2")
	# reflexo do vidro
	for k in 8:
		L.P(img, gl.position.x + 4 + k, gl.position.y + 2 + k * 2, "g1")
	# bebedouro de aço (à direita da vitrine)
	L.R(img, 552, 176, 14, 43, "ink"); L.R(img, 553, 177, 12, 41, "st2"); L.R(img, 553, 177, 12, 2, "st3")
	L.R(img, 555, 182, 8, 4, "st0"); L.R(img, 558, 181, 2, 1, "b3")

func paint_pillars(img: Image) -> void:
	# viga I de aço pintada de azul-escuro (as emendas da sala de 3 vãos)
	for p: Rect2i in [PIL_L, PIL_R]:
		for y in range(p.position.y, p.end.y):
			for x in range(p.position.x, p.end.x):
				var k := x - p.position.x
				var c := "st1"
				if k == 0 or k == p.size.x - 1:
					c = "ink"
				elif k == 1 or k == p.size.x - 2:
					c = "st2"
				elif k == 5:
					c = "st0"
				elif k == 2:
					c = "st3"
				L.P(img, x, y, c)
		for y in range(p.position.y + 40, p.end.y, 46):
			L.P(img, p.position.x + 3, y, "st3"); L.P(img, p.position.x + 7, y, "st3")

func paint_beam(img: Image) -> void:
	L.R(img, BW0, BEAM_Y - 1, BW1 - BW0, 9, "ink")
	L.R(img, BW0, BEAM_Y, BW1 - BW0, 1, "st3")
	L.R(img, BW0, BEAM_Y + 1, BW1 - BW0, 5, "st1")
	L.R(img, BW0, BEAM_Y + 6, BW1 - BW0, 1, "st0")
	for x in range(BW0 + 6, BW1, 24):
		L.P(img, x, BEAM_Y + 3, "st2")
	# treliça acima da viga (pé-direito alto): diagonais escuras
	for x in range(BW0, BW1, 20):
		L.line(img, x, BEAM_Y - 2, x + 10, 19, "d2")
		L.line(img, x + 20, BEAM_Y - 2, x + 10, 19, "d2")
	# ganchos (corrente do saco em x 336 e do saco de lado em x 258)
	for gx in [257, 335]:
		L.R(img, gx - 1, BEAM_Y + 7, 4, 1, "ink"); L.R(img, gx, BEAM_Y + 7, 2, 1, "st3")

## luz do centro: dia claro pelos janelões + 4 painéis de LED. Quase tudo no passo 0; cantos e chão da frente −1.
func center_step(x: int, y: int) -> int:
	var best := -9.0
	for p in LEDS:
		var d := Vector2(x - p.x, (y - p.y - 30) * 0.8).length() / 300.0
		best = maxf(best, 1.05 - d * 1.9)
	for wpos in [Vector2(34, 90), Vector2(606, 90)]:
		var d2 := Vector2(x - wpos.x, (y - wpos.y) * 0.7).length() / 200.0
		best = maxf(best, 0.8 - d2 * 1.6)
	best -= clampf(float(y - 260) / 140.0, 0.0, 0.3)
	var base := floorf(best)
	var fr := clampf((best - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
	return clampi(int(base) + (1 if fr > bayer(x, y) else 0), -2, 0)

func center_light(img: Image) -> void:
	for y in range(18, 360):
		for x in range(0, 640):
			var c := img.get_pixel(x, y)
			if c.a == 0.0 or color_name(c) in ["ink", "white", "y2"]:
				continue
			var st := center_step(x, y)
			if st != 0:
				img.set_pixel(x, y, L.shade(c, st))
	# janela de sol no chão (da parede esquerda), dither de +1
	for y in range(236, 300):
		for x in range(0, 640):
			if not on_floor(x, y):
				continue
			var u := float(x) + float(y - 236) * 0.9
			if u > 36.0 and u < 120.0 and bayer(x, y) < 0.5:
				var c := img.get_pixel(x, y)
				img.set_pixel(x, y, L.shade(c, 1))

# ================================================================== APARELHOS _center (forma igual, material novo)
## Base: a versão da academia (luz dos tubos) quando existe; senão a da garagem. Mesmo quadro, pivô, fps e anim.
## Material por aparelho e por nível visual (n0 = antes da melhoria que troca o sprite, n1 = depois).
const MAT := {
	# Saco de competição: couro azul-marinho da escola com faixas brancas (l1); couro vinho (l0)
	"bag_l1": {"d1": "b0", "d2": "b1", "g0": "b2", "g2": "b3", "r1": "g3", "r2": "cream", "r3": "white"},
	"bag_l0": {"br0": "r0", "br1": "r1", "br2": "r2", "br3": "r3"},
	# Corda de rolamento: cabo azul com punhos pretos de borracha (l1); cabo preto com punhos amarelos (l0)
	"rope_l1": {"st1": "b2", "st3": "b3", "br1": "d1", "br3": "g1"},
	"rope_l0": {"r1": "br3", "r2": "y1", "d1": "ink", "d2": "d1"},
	# Esteira com painel: grafite com painel azul (l1); grafite com faixas amarelas (l0)
	"treadmill_l1": {"white": "st3", "g3": "st2", "g2": "st1", "g1": "st0", "g0": "d2", "gr1": "b1", "gr2": "b2", "gr3": "b3"},
	"treadmill_l0": {"white": "st3", "g3": "st2", "g2": "st1", "g1": "st0", "gr1": "br2", "gr3": "y1"},
	# Plataforma de pera: madeira clara (maple) e pera de couro caramelo
	"speed_bag_l1": {"br0": "br1", "br1": "br2", "br2": "br3", "r1": "br2", "r2": "br3", "r3": "y0", "r0": "br1"},
	"speed_bag_l0": {"br1": "br2", "br2": "br3", "br3": "y0", "r0": "br0", "r1": "br1", "r2": "br2"},
	# Boneco de competição: couro vermelho com alças pretas (l1); lona grafite com remendo vermelho (l0)
	"grappling_dummy_l1": {"b0": "r0", "b1": "r1", "b2": "r2", "b3": "r3"},
	"grappling_dummy_l0": {"g1": "d2", "g2": "g0", "g3": "g1", "cream": "g2", "b0": "r0", "b1": "r1", "b2": "r2"},
	# Saco de lona dupla: lona crua com alças de couro (l1); lona verde-oliva (l0)
	"kick_bag_l1": {"d1": "g2", "d2": "g3", "g0": "cream", "g2": "white", "br2": "br1", "br3": "br2", "y0": "br3"},
	"kick_bag_l0": {"br1": "gr0", "br2": "gr0", "br3": "gr1", "y0": "gr2", "y1": "gr3"},
}
const APP_SHEETS := {
	"bag": ["idle", "hit", "side"],
	"rope": ["idle", "swing", "swing_back"],
	"treadmill": ["idle", "run", "side"],
	"speed_bag": ["idle", "hit", "wall", "wall_swing"],
	"grappling_dummy": ["idle", "hit", "rest"],
	"kick_bag": ["idle", "hit", "rest"],
}
var APP_IDS := []   # [id_center, id_base]

func make_apparatus() -> void:
	for base in APP_SHEETS:
		for lv in [0, 1]:
			for q in APP_SHEETS[base]:
				var plain := "%s_l%d_%s" % [base, lv, q]
				var src_id := plain + "_gym" if not spr(plain + "_gym").is_empty() else plain
				if spr(src_id).is_empty():
					continue
				var e := spr(src_id)
				var sheet := load_png(res_abs(str(e.file)))
				var fw := int(e.frame_size[0])
				var fh := int(e.frame_size[1])
				var frames := []
				var n := maxi(sheet.get_width() / fw, 1)
				for i in n:
					frames.append(swap(sheet.get_region(Rect2i(i * fw, 0, fw, fh)), MAT["%s_l%d" % [base, lv]]))
				var cid := plain + "_center"
				var pv: Array = e.get("pivot", [0, 0])
				save_sheet(cid, "equipment/" + cid + ".png", frames, float(e.get("fps", 0.0)), Vector2i(int(pv[0]), int(pv[1])))
				META[cid]["from"] = src_id
				APP_IDS.append([cid, src_id])

# ================================================================== RECORTE (D10) e foto
## Recorte do jornal: papel creme, manchete RAÍZES (3x5), foto granulada do lutador erguendo o cinturão, colunas, picote.
func clipping(w: int, h: int, head := true, paper := "cream") -> Image:
	var im: Image = L.blank(w, h)
	for y in h:
		for x in w:
			var edge := (x == 0 or x == w - 1 or y == h - 1) and hsh(x, y, 4) < 0.45
			if not edge:
				L.P(im, x, y, paper)
	if head and mini_w(TXT_CLIP_HEAD) <= w - 2:
		mini_text(im, TXT_CLIP_HEAD, (w - mini_w(TXT_CLIP_HEAD)) / 2, 2, "ink")
	else:
		L.R(im, 2, 3, w - 4, 3, "d2")   # manchete grande demais para 1x: barra escura (o texto vai no hover)
	L.R(im, 2, 8, w - 4, 1, "g2")
	# foto granulada: o vencedor de braços para cima com o cinturão (silhueta 2 tons)
	var ph := Rect2i(2, 10, w - 4, 11)
	L.R(im, ph.position.x, ph.position.y, ph.size.x, ph.size.y, "g2")
	for y in range(ph.position.y, ph.end.y):
		for x in range(ph.position.x, ph.end.x):
			if bayer(x, y) < 0.35:
				L.P(im, x, y, "g1")
	var cx := w / 2
	L.R(im, cx - 1, 12, 3, 3, "ink")                        # cabeça
	L.R(im, cx - 2, 15, 5, 5, "ink")                        # tronco
	L.line(im, cx - 2, 15, cx - 5, 11, "ink"); L.line(im, cx + 2, 15, cx + 5, 11, "ink")   # braços para cima
	L.R(im, cx - 6, 10, 13, 2, "ink"); L.P(im, cx, 10, "y1")                               # cinturão erguido
	# colunas de texto
	for y in range(ph.end.y + 2, h - 2, 2):
		L.R(im, 2, y, w / 2 - 3, 1, "g3")
		L.R(im, w / 2 + 1, y, w / 2 - 3, 1, "g3")
	return im

func make_clipping() -> void:
	# emoldurado (centro): 28x34, moldura preta com filete de ouro, vidro com reflexo, plaquinha de latão
	var w := 36
	var h := 36
	var im: Image = L.blank(w, h)
	L.R(im, 0, 0, w, h, "ink")
	L.R(im, 1, 1, w - 2, h - 2, "d1")
	L.R(im, 1, 1, w - 2, 1, "d2")
	L.R(im, 3, 3, w - 6, h - 6, "y0")
	L.R(im, 4, 4, w - 8, h - 8, "white")
	var c := clipping(26, 26)
	blend(im, c, 5, 4)
	for k in 6:
		L.P(im, 25 + k, 5 + k, "white")
	L.R(im, 15, h - 4, 6, 2, "y1")
	# preso por um fio num prego (o fio fica fora do quadro: o quadro é só a moldura)
	save_sheet("wall_clipping_regional_framed", "center/wall_clipping_regional_framed.png", [im], 0.0, Vector2i.ZERO)
	# o mesmo recorte solto (para o cartaz; 18x24 com fita em cima)
	var loose := clipping(18, 24, false)
	var tape: Image = L.blank(18, 24)
	blend(tape, loose, 0, 0)
	for x in range(6, 12):
		for y in range(0, 3):
			if (x + y) % 2 == 0 or y == 1:
				tape.set_pixel(x, y, L.C.white)
	F["clip_loose"] = [tape]
	# zoom (dica/janela, opcional): título inteiro
	var zw := 124
	var zh := 92
	var z: Image = L.blank(zw, zh)
	for y in zh:
		for x in zw:
			if not ((x == 0 or x == zw - 1 or y == zh - 1) and hsh(x, y, 6) < 0.5):
				L.P(z, x, y, "cream")
	L.text_center(z, "CORREIO DA ESQUINA", zw / 2, 3, "g1", 1)
	L.R(z, 4, 12, zw - 8, 1, "g2")
	L.text_center(z, TXT_CLIP_Z1, zw / 2, 16, "ink", 1)
	L.text_center(z, TXT_CLIP_Z2, zw / 2, 26, "ink", 1)
	var big := scaled(clipping(18, 24, false).get_region(Rect2i(2, 10, 14, 11)), 3)
	L.R(z, 6, 38, 44, 35, "ink")
	blend(z, big, 7, 39)
	for y in range(40, 84, 3):
		L.R(z, 56, y, zw - 62, 1, "g3")
	L.R(z, 6, 78, 44, 1, "g3"); L.R(z, 6, 82, 44, 1, "g3")
	save_sheet("ui_clipping_regional_zoom", "ui/ui_clipping_regional_zoom.png", [z], 0.0, Vector2i.ZERO)

# ================================================================== CARTAZ VENCIDO (academia)
const POSTER := Vector2i(38, 54)
const POSTER_SPOT := Vector2i(412, 54)
const WON := Vector2i(42, 58)     # o recorte passa um pouco da borda do cartaz (direita e embaixo)

## Adesivo redondo do R (branco com o R da escola), 13x13, um pouco torto (canto descolando)
func sticker(d: int) -> Image:
	var im: Image = L.blank(d, d)
	L.ellipse(im, d / 2.0, d / 2.0, d / 2.0, d / 2.0, "ink")
	L.ellipse(im, d / 2.0, d / 2.0, d / 2.0 - 1, d / 2.0 - 1, "white")
	var s := load_png(ROOT + "assets/sprites/ui/school_symbol_9.png")
	blend(im, s, (d - 9) / 2, (d - 9) / 2)
	# canto descolando (sombra embaixo à direita)
	L.P(im, d - 3, d - 4, "g3"); L.P(im, d - 4, d - 3, "g3")
	return im

func sponsor_corner() -> Image:
	## a marca no canto de cima à esquerda do cartaz (8x8): engrenagem amarela no quadrado preto
	var im: Image = L.blank(9, 9)
	L.R(im, 0, 0, 9, 9, "ink")
	L.R(im, 1, 1, 7, 7, "d1")
	gear(im, 4, 4, 3, "y1", "y0")
	return im

func gear(im: Image, cx: int, cy: int, r: int, c: String, cdark: String) -> void:
	L.ellipse(im, cx + 0.5, cy + 0.5, r, r, c)
	for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		L.P(im, cx + d.x * (r + 1), cy + d.y * (r + 1), c)
	if r >= 3:
		for d in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			L.P(im, cx + d.x * r, cy + d.y * r, c)
	L.P(im, cx, cy, cdark)
	if r >= 3:
		L.P(im, cx + 1, cy, cdark); L.P(im, cx, cy + 1, cdark); L.P(im, cx + 1, cy + 1, cdark)

func make_poster_won() -> void:
	var src := load_png(ROOT + "assets/sprites/gym/wall_poster_league_regional_gym.png")
	var frames := []
	for with_brand in [false, true]:
		var im: Image = L.blank(WON.x, WON.y)
		blend(im, src, 0, 0)
		# adesivo do R em cima da cara do James (a foto fica em 4..33 x 21..42)
		blend(im, sticker(13), 14, 22)
		# recorte preso com fita no canto de baixo à direita, passando da borda
		blend(im, F["clip_loose"][0], WON.x - 19, WON.y - 25)
		if with_brand:
			blend(im, sponsor_corner(), 1, 1)
		frames.append(im)
	save_sheet("wall_poster_league_regional_won_gym", "gym/wall_poster_league_regional_won_gym.png", frames, 0.0, Vector2i.ZERO)
	# zoom: o cartaz grande da 8a1 com o adesivo, o recorte e (quadro 1) a marca
	var zsrc := load_png(ROOT + "assets/sprites/ui/ui_poster_league_regional_zoom.png")
	var zf := []
	for with_brand in [false, true]:
		var z: Image = L.blank(124, 160)
		blend(z, zsrc, 0, 0)
		blend(z, scaled(sticker(13), 2), 43, 33)
		# faixa VENCIDO? não: o adesivo e o recorte contam sozinhos. O recorte em 2x no canto
		blend(z, scaled(F["clip_loose"][0], 2), 124 - 38, 34)  # 8a2 QA B4: no canto de cima da lateral, sem cobrir o texto
		if with_brand:
			blend(z, scaled(sponsor_corner(), 2), 3, 3)
		zf.append(z)
	save_sheet("ui_poster_league_regional_won_zoom", "ui/ui_poster_league_regional_won_zoom.png", zf, 0.0, Vector2i.ZERO)

# ================================================================== PATROCINADOR: Autopeças Vale Forte
## Marca original: engrenagem amarela com os dois morros do Vale no meio, sobre preto. Amarelo y1 = a cor da faixa da 8a1.
func logo(s: int) -> Image:
	## s = lado (16 ou 20): selo quadrado com a engrenagem e os morros
	var im: Image = L.blank(s, s)
	L.rrect(im, 0, 0, s, s, "ink")
	L.rrect(im, 1, 1, s - 2, s - 2, "d1")
	var c := s / 2
	var r := s / 2 - 3
	L.ellipse(im, c, c, r + 0.5, r + 0.5, "y1")
	for k in 8:
		var a := TAU * k / 8.0
		var px := int(round(c - 0.5 + cos(a) * (r + 1)))
		var py := int(round(c - 0.5 + sin(a) * (r + 1)))
		L.R(im, px - 1 + (1 if cos(a) < -0.5 else 0), py - 1 + (1 if sin(a) < -0.5 else 0), 2, 2, "y1")
	L.ellipse(im, c, c, r - 1.5, r - 1.5, "d1")
	# morros do Vale (dois montes) dentro da engrenagem
	for x in range(c - r + 2, c + r - 1):
		var hgt := maxf(2.5 - absf(x - (c - 2)) * 0.8, 0.0) + maxf(2.0 - absf(x - (c + 2)) * 0.8, 0.0)
		for y in range(int(c + 2 - hgt), c + 2):
			L.P(im, x, y, "gr2")
	L.R(im, c - r + 2, c + 2, 2 * r - 3, 1, "y0")
	return im

func make_sponsor() -> void:
	save_sheet("sponsor_vale", "ui/sponsor_vale.png", [logo(20)], 0.0, Vector2i.ZERO)
	# versão larga para a janela do contrato e a linha da vitória: selo + VALE FORTE (5x7) em amarelo sobre preto
	var tw: int = L.text_w(TXT_BRAND, 1)
	var wide: Image = L.blank(20 + 6 + tw + 6, 20)
	L.rrect(wide, 0, 0, wide.get_width(), 20, "ink")
	L.rrect(wide, 1, 1, wide.get_width() - 2, 18, "d1")
	L.R(wide, 2, 1, wide.get_width() - 4, 1, "d2")
	blend(wide, logo(20), 0, 0)
	L.text(wide, TXT_BRAND, 24, 6, "y1", 1, "br0")
	save_sheet("sponsor_vale_wide", "ui/sponsor_vale_wide.png", [wide], 0.0, Vector2i.ZERO)
	# 9x9 (linha da vitória, cartão)
	var s9: Image = L.blank(9, 9)
	L.R(s9, 0, 0, 9, 9, "ink"); L.R(s9, 1, 1, 7, 7, "d1")
	gear(s9, 4, 4, 2, "y1", "d1")
	save_sheet("sponsor_vale_9", "ui/sponsor_vale_9.png", [s9], 0.0, Vector2i.ZERO)
	# remendo do calção (5x3, sem contorno: o calção já é o contorno): etiqueta amarela com o miolo escuro da engrenagem (lê como "marca" a 1x)
	var pt: Image = L.blank(5, 3)
	L.R(pt, 0, 0, 5, 3, "y1")
	L.R(pt, 0, 2, 5, 1, "y0")
	L.P(pt, 2, 1, "d1")
	L.P(pt, 0, 0, "y2")
	save_sheet("sponsor_vale_patch", "ui/sponsor_vale_patch.png", [pt], 0.0, Vector2i(2, 0))
	# envelope PROPOSTA no chão (16x11): papel pardo, selo amarelo; 3 quadros: parado, brilho, brilho forte
	var env := []
	for k in 3:
		var e: Image = L.blank(16, 11)
		L.R(e, 0, 2, 16, 9, "ink")
		L.R(e, 1, 3, 14, 7, "cream")
		L.R(e, 1, 9, 14, 1, "g3")
		L.line(e, 1, 3, 7, 7, "g3"); L.line(e, 14, 3, 8, 7, "g3")
		L.R(e, 6, 6, 4, 3, "ink"); L.R(e, 7, 6, 2, 2, "y1")       # selo de cera com a cor da marca
		if k >= 1:
			L.P(e, 13, 1, "y2"); L.P(e, 13, 0, "white"); L.P(e, 12, 1, "white"); L.P(e, 14, 1, "white")
		if k == 2:
			L.P(e, 3, 4, "white"); L.P(e, 2, 1, "y2")
		env.append(e)
	save_sheet("sponsor_envelope", "center/sponsor_envelope.png", env, 4.0, Vector2i(8, 10))

# ================================================================== MAPA (região CENTRO)
func make_map() -> void:
	# ícone 16: fachada do centro (telhado de 2 águas, porta, o R na empena)
	var im: Image = L.blank(16, 16)
	for y in range(1, 7):
		var hw := y + 1
		L.R(im, 8 - hw, y, hw * 2, 1, "ink")
	for y in range(2, 7):
		var hw := y
		L.R(im, 8 - hw, y, hw * 2, 1, "st1")
	L.R(im, 2, 7, 12, 8, "ink")
	L.R(im, 3, 7, 10, 7, "cream")
	L.R(im, 3, 11, 10, 3, "b1")
	L.R(im, 6, 9, 4, 5, "ink"); L.R(im, 7, 10, 2, 4, "b3")
	var s5 := load_png(ROOT + "assets/sprites/ui/school_symbol_5.png")
	blend(im, s5, 6, 1)
	L.R(im, 1, 15, 14, 1, "ink")
	save_sheet("icon_region_center", "ui/icon_region_center.png", [im], 0.0, Vector2i.ZERO)
	var i9: Image = L.blank(9, 9)
	for y in range(0, 4):
		L.R(i9, 4 - y, y, y * 2 + 1, 1, "ink")
	for y in range(1, 4):
		L.R(i9, 5 - y, y, y * 2 - 1, 1, "st2")
	L.R(i9, 1, 4, 7, 5, "ink"); L.R(i9, 2, 4, 5, 4, "cream"); L.R(i9, 2, 6, 5, 2, "b1"); L.R(i9, 4, 6, 1, 3, "ink")
	save_sheet("icon_region_center_9", "ui/icon_region_center_9.png", [i9], 0.0, Vector2i.ZERO)
	# plaquinha 16x13 (mesmo 9-slice da do Muay Thai: 4,1,1,1), faixa azul da escola
	var lb: Image = L.blank(16, 13)
	L.R(lb, 0, 0, 16, 13, "ink"); L.R(lb, 1, 1, 14, 11, "d1"); L.R(lb, 1, 1, 14, 1, "d2")
	L.R(lb, 1, 1, 3, 11, "b2"); L.R(lb, 1, 1, 3, 1, "b3")
	save_sheet("ui_map_region_label_center", "ui/map/ui_map_region_label_center.png", [lb], 0.0, Vector2i.ZERO)
	# ladrilho 32x32: piso de borracha do centro (placas com grânulos) — chave própria porque "center" já é a cortiça do miolo
	var t: Image = L.blank(32, 32)
	for y in 32:
		for x in 32:
			var c := "d2"
			if x % 16 == 15 or y % 16 == 15:
				c = "d1"
			elif hsh(x, y, 31) < 0.08:
				c = "g0"
			elif hsh(x, y, 37) < 0.03:
				c = "b1"
			L.P(t, x, y, c)
	save_sheet("map_tile_center_region", "ui/map/map_tile_center_region.png", [t], 0.0, Vector2i.ZERO)
	# anel "aço" dos nós comprados da região (troca de cor do anel azul)
	var ring_swap := {"b0": "st0", "b1": "st1", "b2": "st2", "b3": "st3"}
	for k in ["s", "b"]:
		var srcp := ROOT + "assets/sprites/ui/map/map_node_%s_owned_blue.png" % k
		var e := spr("map_node_%s_owned_blue" % k)
		var src := load_png(srcp)
		var fw := int(e.frame_size[0]) if not e.is_empty() else src.get_width()
		var fh := int(e.frame_size[1]) if not e.is_empty() else src.get_height()
		var frames := []
		for i in maxi(src.get_width() / fw, 1):
			frames.append(swap(src.get_region(Rect2i(i * fw, 0, fw, fh)), ring_swap))
		var pv: Array = e.get("pivot", [0, 0])
		save_sheet("map_node_%s_owned_steel" % k, "ui/map/map_node_%s_owned_steel.png" % k, frames, float(e.get("fps", 0.0)), Vector2i(int(pv[0]), int(pv[1])))

## Retrato 16x16 do gerador (painel EQUIPE), como o icon_neighbor: recorte de cabeça e ombros da folha student_1,
## com o R amarelo do peito aparecendo no pé do ícone.
func make_student_icon() -> void:
	if spr("student_1").is_empty():
		CHECKS.append("AVISO: sem a folha student_1; icon_students não gerado")
		return
	var fr := frame_of("student_1", 0)
	var u := fr.get_used_rect()
	var top := u.position.y
	var xs := 0
	var nx := 0
	for y in range(top, top + 12):
		for x in fr.get_width():
			if fr.get_pixel(x, y).a > 0.0:
				xs += x
				nx += 1
	var cx := int(round(float(xs) / maxf(nx, 1)))
	var im := fr.get_region(Rect2i(cx - 8, top - 1, 16, 16))
	save_sheet("icon_students", "ui/icon_students.png", [im], 0.0, Vector2i.ZERO)

# ================================================================== MONTAGEM DA SALA (mockups + conferência)
const CUR_LOOK := ["skin_1", "copper", "purple"]
const M2_LOOK := ["skin_4", "black", "blue"]
const ST_LOOKS := [["skin_3", "black", "black"], ["skin_5", "black", "black"], ["skin_2", "brown", "black"], ["skin_4", "dark_brown", "black"]]

func _region(path: String, fw: int, fh: int, q: int) -> Image:
	var img := load_png(path)
	var n := maxi(img.get_width() / fw, 1)
	return img.get_region(Rect2i(clampi(q, 0, n - 1) * fw, 0, fw, fh))

func recolor_map(look: Array, tee := false) -> Dictionary:
	var pb: Dictionary = MAN.by_data_id.disciple_palette
	var m := {}
	var fields := ["skin", "hair_color", "shorts_color"]
	for i in 3:
		var keys: Dictionary = pb["keys"][fields[i]]
		var ramp := {}
		for o in pb.options[fields[i]]:
			if o.id == look[i]:
				ramp = o.ramp
		for slot in keys:
			if ramp.has(slot):
				m[(keys[slot] as String).substr(1).to_lower()] = Color.html(ramp[slot])
	if tee:
		# camiseta preta da escola, R em creme no peito
		var tk: Dictionary = pb["keys"]["top_color"]
		var tmap := {"light": "g0", "mid": "d2", "dark": "d1", "deep": "ink"}
		for slot in tk:
			m[(tk[slot] as String).substr(1).to_lower()] = L.col(tmap.get(slot, "d1"))
		var sk: Dictionary = pb["keys"]["school_symbol"]
		m[(sk["base"] as String).substr(1).to_lower()] = L.col("cream")
		m[(sk["shadow"] as String).substr(1).to_lower()] = L.col("g3")
	return m

func layered(id: String, q: int, look: Array, tee := false) -> Image:
	var key := "L%s#%d#%s#%s" % [id, q, str(look), str(tee)]
	if _cache.has(key):
		return _cache[key]
	var e := spr(id)
	var fw := int(e.frame_size[0])
	var fh := int(e.frame_size[1])
	var lay: Dictionary = e.layers
	var body := _region(res_abs(lay.body), fw, fh, q)
	var top: Image = _region(res_abs(lay.top.tee), fw, fh, q) if tee and lay.has("top") else null
	var sym: Image = _region(res_abs(lay.school_symbol.chest), fw, fh, q) if tee and lay.has("school_symbol") else null
	var head := _region(res_abs(lay.head.short), fw, fh, q)
	var mask := _region(res_abs(lay.front_mask), fw, fh, q)
	var rc := recolor_map(look, tee)
	var out := Image.create_empty(fw, fh, false, Image.FORMAT_RGBA8)
	for y in fh:
		for x in fw:
			var c := body.get_pixel(x, y)
			if top != null and top.get_pixel(x, y).a > 0.0:
				c = top.get_pixel(x, y)
			if sym != null and sym.get_pixel(x, y).a > 0.0:
				c = sym.get_pixel(x, y)
			var hc := head.get_pixel(x, y)
			if hc.a > 0.0:
				c = hc
			if mask.get_pixel(x, y).a > 0.0:
				c = body.get_pixel(x, y)
			if c.a > 0.0:
				var hx := c.to_html(false).to_lower()
				if rc.has(hx):
					c = rc[hx]
			out.set_pixel(x, y, c)
	_cache[key] = out
	return out

## aluno i (0..3): folha do Artista se existir; senão o dublê (lutador em guarda com a camiseta preta do R)
func student_frames(i: int) -> Array:
	var sid: String = STUDENT_SHEETS[i]
	var out := []
	var flip: bool = STUDENTS[i][1] == "esquerda"
	if not spr(sid).is_empty() and FileAccess.file_exists(res_abs(str(spr(sid).file))):
		for q in nframes(sid):
			var fr: Image = frame_of(sid, q).duplicate()
			if flip and str(spr(sid).get("facing", "direita")) != "esquerda":
				fr.flip_x()
			out.append([fr, pivot_of(sid)])
		return out
	for q in 4:
		var fr: Image = layered("fighter_idle_disc_layered", q, ST_LOOKS[i], true).duplicate()
		var pv := GPIV
		if flip:
			fr.flip_x()
			pv = Vector2i(fr.get_width() - 1 - GPIV.x, GPIV.y)
		out.append([fr, pv])
	return out

func student_is_standin() -> bool:
	return spr(STUDENT_SHEETS[0]).is_empty()

## Itens da sala: {id, frames: [[img, topleft]], sort, kind}. kind: fundo (parede), aparelho, gente, alvo, chao
func items(state: Dictionary) -> Array:
	var it := []
	var art: String = state.get("art", "boxing")
	var nst: int = state.get("students", 4)
	var add := func(id: String, sheet: String, pos: Vector2i, kind: String, sort: float, qs := []):
		var fr := []
		var n := nframes(sheet)
		var list: Array = qs if not qs.is_empty() else range(n)
		for q in list:
			fr.append([frame_of(sheet, q), pos - pivot_of(sheet)])
		it.append({"id": id, "frames": fr, "sort": sort, "kind": kind})
	# parede
	add.call("metronomo", "metronome_l1", P_METRO, "parede", -60.0, [0])
	add.call("mural", "wall_mural_gym", P_MURAL, "parede", -45.0, [3])
	add.call("foto_torta", "wall_photo_old_gym", P_PHOTO, "parede", -45.0, [1])
	add.call("recorte_emoldurado", "wall_clipping_regional_framed", P_CLIP_FRAMED, "parede", -45.0)
	add.call("recorte_vulto", "wall_clipping_black_cat_gym", P_CAT, "parede", -45.0)
	if art == "boxing":
		add.call("pera_parede", "speed_bag_l1_wall_center", P_PERA_WALL, "parede", -40.0, [0])
	# aparelhos
	add.call("corda_gancho", "rope_l1_idle_center", P_ROPE, "aparelho", 206.0)
	add.call("saco_de_lado", "bag_l1_side_center", P_BAG_SIDE, "aparelho", 236.0) if state.get("focus", "bag") != "bag" else null
	if state.get("focus", "bag") == "bag":
		add.call("saco_centro", "bag_l1_idle_center", P_BAG, "alvo", 253.0)
	add.call("esteira", "treadmill_l1_side_center", P_TREAD, "aparelho", 324.0)
	if art == "bjj":
		add.call("boneco", "grappling_dummy_l1_rest_center", P_ART_REST, "aparelho", 270.0)
	elif art == "muay_thai":
		add.call("saco_comprido", "kick_bag_l1_rest_center", P_ART_REST, "aparelho", 306.0)
	# gente
	var lf := []
	for q in 4:
		lf.append([layered("fighter_idle_disc_layered", q, CUR_LOOK), P_FIGHTER - GPIV])
	it.append({"id": "lutador", "frames": lf, "sort": 272.0, "kind": "alvo", "shadow": P_FIGHTER})
	add.call("osmar", "coach_idle_gym", P_COACH, "gente", float(P_COACH.y))
	it[-1]["shadow"] = P_COACH
	add.call("caixote", "garage_crate_gym", P_CRATE, "aparelho", 250.0)
	add.call("john_sentado", "john_sit_rest", P_MENTOR, "gente", float(P_MENTOR.y))
	var m2 := []
	for q in 4:
		m2.append([layered("disciple_stand_bare", q, M2_LOOK), P_MENTOR2 - GPIV])
	it.append({"id": "mentor_2", "frames": m2, "sort": float(P_MENTOR2.y), "kind": "gente", "shadow": P_MENTOR2})
	for cid in CREW_P:
		var sheet := str(spr(cid).file).get_file().get_basename()
		add.call(cid, cid, CREW_P[cid], "gente", float(CREW_P[cid].y))
		it[-1]["shadow"] = CREW_P[cid]
	for i in mini(nst, 4):
		var sf := student_frames(i)
		var fr := []
		var p: Vector2i = STUDENTS[i][0]
		for pair in sf:
			fr.append([pair[0], p - pair[1]])
		it.append({"id": "aluno_%d" % (i + 1), "frames": fr, "sort": float(p.y), "kind": "gente", "shadow": p})
	if state.get("envelope", false):
		add.call("envelope", "sponsor_envelope", P_ENVELOPE, "chao", float(P_ENVELOPE.y) - 30.0)
	return it

func compose(state: Dictionary, q := 0) -> Image:
	var im: Image = BG.duplicate()
	var its := items(state)
	its.sort_custom(func(a, b): return a.sort < b.sort)
	# corrente do saco (do gancho até o pivô)
	var chain := frame_of("bag_chain_tile")
	var tops := [P_BAG_SIDE] if state.get("focus", "bag") != "bag" else [P_BAG]
	for p in tops:
		for y in range(33, p.y, 6):
			blend(im, chain.get_region(Rect2i(0, 0, 4, mini(6, p.y - y))), p.x - 2, y)
	var fs := frame_of("floor_shadow")
	for it in its:
		if it.has("shadow"):
			blend(im, fs, it.shadow.x - 16, it.shadow.y - 1 - 4)
	for it in its:
		var fr: Array = it.frames[clampi(q, 0, it.frames.size() - 1)]
		blend(im, fr[0], fr[1].x, fr[1].y)
	return im

func hud_strip(im: Image, panel: bool) -> void:
	## HUD aproximado (o de verdade é do UI/UX): topo e faixa de baixo, para ver a sala com a moldura de verdade
	L.R(im, 0, 0, 640, 18, "d1")
	L.text(im, "TREINO 12,4M  +38,2K/S   $ 31.200", 6, 5, "gr3", 1)
	L.text_right(im, "CENTRO RAÍZES: TREINO X4", 634, 5, "b3", 1)
	L.R(im, 0, STRIP_Y, 640, 30, "d1")
	L.R(im, 0, STRIP_Y, 640, 1, "d2")
	for i in 4:
		L.button(im, 92 + i * 92, STRIP_Y + 6, 86, 18, "r1" if i == 0 else "d2", ["SACO", "ESTEIRA", "CORDA", "PERA"][i])
	L.button(im, 510, STRIP_Y + 4, 100, 22, "r2", "PASSAR O POSTO")
	if panel:
		L.panel(im, PANEL_X, 22, 640 - PANEL_X - 2, STRIP_Y - 26)
		L.text(im, "EQUIPE", PANEL_X + 6, 28, "cream", 1)
		L.text(im, "ALUNOS DA RAÍZES", PANEL_X + 6, 42, "white", 1)
		L.text(im, "X12   2,9M", PANEL_X + 6, 52, "y1", 1)

func mock_sala() -> void:
	# 1) proposta (antes de gravar): cheia (Boxe, 4 alunos), chegada (1 aluno) e Jiu-jitsu com o envelope; painel solto e fixado
	var states := [
		{"name": "cheia_boxe", "art": "boxing", "students": 4, "focus": "bag"},
		{"name": "chegada", "art": "muay_thai", "students": 1, "focus": "bag"},
		{"name": "cheia_jiujitsu_envelope", "art": "bjj", "students": 4, "focus": "bag", "envelope": true},
	]
	for st in states:
		var im := compose(st)
		var a: Image = im.duplicate()
		hud_strip(a, false)
		a.save_png(MOCK + "fase8a2_centro_%s.png" % st.name)
		scaled(a, 2).save_png(MOCK + "fase8a2_centro_%s_x2.png" % st.name)
		if st.name == "cheia_boxe":
			var b: Image = im.duplicate()
			hud_strip(b, true)
			scaled(b, 2).save_png(MOCK + "fase8a2_centro_cheia_boxe_fixado_x2.png")
	var v: Image = BG.duplicate()
	v.save_png(MOCK + "fase8a2_fundo_centro.png")
	scaled(v, 2).save_png(MOCK + "fase8a2_fundo_centro_x2.png")
	# 2) conferência: retângulos de ocupação (todos os quadros), zona do alvo, painel fixado, pontos novos
	var c := compose(states[0])
	var its := items(states[0])
	its.append_array(items({"art": "bjj", "students": 0, "envelope": true}).filter(func(x): return x.id in ["boneco", "envelope"]))
	for it in its:
		var r := occ_rect(it)
		var col: String = {"gente": "gr3", "aparelho": "y1", "alvo": "r3", "parede": "b3", "chao": "f2"}.get(it.kind, "white")
		if str(it.id).begins_with("aluno") or it.id in ["recorte_emoldurado", "foto_torta", "envelope"]:
			col = "f2"
		rect_outline(c, r, col)
	rect_outline(c, ALVO, "r2")
	for y in range(18, STRIP_Y):
		if y % 3 == 0:
			L.P(c, PANEL_X, y, "white")
	var cx2 := scaled(c, 2)
	var board: Image = L.blank(1280, 720 + 44)
	L.R(board, 0, 0, 1280, 764, "d1")
	board.blit_rect(cx2, Rect2i(0, 0, 1280, 720), Vector2i(0, 44))
	label(board, "FASE 8A2 - CONFERÊNCIA DO CENTRO (X2): ROSA = NOVO (ALUNOS, RECORTE, FOTO, ENVELOPE); VERDE = GENTE; AMARELO = APARELHO; VERMELHO = ZONA DO ALVO", 6, 6, "y1")
	label(board, "PONTILHADO = BORDA DO PAINEL FIXADO (X 506). ALUNO 4 E O PROF. NELSON FICAM ATRÁS DELE COM O PAINEL FIXADO (COMO NA 6D2)." + (" ALUNOS = DUBLÊ." if student_is_standin() else ""), 6, 22, "g3")
	board.save_png(MOCK + "fase8a2_centro_conferencia_x2.png")

func occ_rect(it: Dictionary) -> Rect2i:
	var r := Rect2i()
	var first := true
	for pair in it.frames:
		var img: Image = pair[0]
		var u := img.get_used_rect()
		if not u.has_area():
			continue
		var rr := Rect2i(u.position + pair[1], u.size)
		r = rr if first else r.merge(rr)
		first = false
	return r

func rect_outline(img: Image, r: Rect2i, c: String) -> void:
	for x in range(r.position.x, r.end.x):
		L.P(img, x, r.position.y, c); L.P(img, x, r.end.y - 1, c)
	for y in range(r.position.y, r.end.y):
		L.P(img, r.position.x, y, c); L.P(img, r.end.x - 1, y, c)

## máscara opaca (união de todos os quadros) em coordenadas da tela
func mask_of(it: Dictionary) -> Dictionary:
	var m := {}
	for pair in it.frames:
		var img: Image = pair[0]
		var tl: Vector2i = pair[1]
		var u := img.get_used_rect()
		for y in range(u.position.y, u.end.y):
			for x in range(u.position.x, u.end.x):
				if img.get_pixel(x, y).a > 0.0:
					m[Vector2i(x + tl.x, y + tl.y)] = true
	return m

func check_sala() -> void:
	var problems := 0
	for st in [{"art": "boxing", "students": 4, "focus": "bag", "envelope": true}, {"art": "bjj", "students": 4, "focus": "rope", "envelope": true},
			{"art": "muay_thai", "students": 4, "focus": "bag", "envelope": true}]:
		var its := items(st)
		var masks := {}
		for it in its:
			masks[it.id] = mask_of(it)
		var ids := masks.keys()
		for i in ids.size():
			for j in range(i + 1, ids.size()):
				var a: String = ids[i]
				var b: String = ids[j]
				var ka: String = its.filter(func(x): return x.id == a)[0].kind
				var kb: String = its.filter(func(x): return x.id == b)[0].kind
				# só interessa quem é novo nesta fase contra todo o resto (o resto já foi conferido na 6d2)
				var novo := ["aluno_1", "aluno_2", "aluno_3", "aluno_4", "recorte_emoldurado", "foto_torta", "envelope"]
				if not (a in novo or b in novo):
					continue
				if ka == "parede" and kb != "parede" and not (a in novo):
					pass
				var n := 0
				var ma: Dictionary = masks[a]
				var mb: Dictionary = masks[b]
				var small: Dictionary = ma if ma.size() < mb.size() else mb
				var big: Dictionary = mb if ma.size() < mb.size() else ma
				for k in small:
					if big.has(k):
						n += 1
				if n > 0:
					problems += 1
					CHECKS.append("SOBREPÕE (%s): %s x %s = %d px" % [st.art, a, b, n])
		# zona do alvo, faixa de baixo e painel
		for it in its:
			if not (str(it.id).begins_with("aluno") or it.id in ["recorte_emoldurado", "foto_torta", "envelope"]):
				continue
			var r := occ_rect(it)
			if r.intersects(ALVO):
				problems += 1
				CHECKS.append("NA ZONA DO ALVO: %s %s" % [it.id, str(r)])
			if r.end.y > STRIP_Y:
				problems += 1
				CHECKS.append("PASSA DA FAIXA DE BAIXO: %s %s" % [it.id, str(r)])
			if r.end.x > PANEL_X and it.id != "aluno_4":
				CHECKS.append("ATRÁS DO PAINEL FIXADO: %s %s" % [it.id, str(r)])
	# balão do Osmar (120,132 154x36) x peças novas de parede
	var bal := Rect2i(120, 132, 154, 36)
	for it in items({"art": "boxing", "students": 4, "envelope": true}):
		if it.id in ["recorte_emoldurado", "foto_torta"] and occ_rect(it).intersects(bal):
			CHECKS.append("AVISO: o balão do Osmar cobre %s" % it.id)
	# parede lisa atrás das peças novas de parede (nada pintado no fundo embaixo delas)
	for p in [[P_CLIP_FRAMED, Vector2i(36, 36)], [P_PHOTO, Vector2i(18, 21)]]:
		var other := 0
		for y in range(p[0].y - 1, p[0].y + p[1].y + 1):
			for x in range(p[0].x - 1, p[0].x + p[1].x + 1):
				if not (color_name(BG.get_pixel(x, y)) in ["cream", "white", "g3", "g2"]):
					other += 1
		CHECKS.append("parede atrás de %s: %d px que não são parede lisa" % [str(p[0]), other])
		if other > 0:
			problems += 1
	for it in items({"art": "boxing", "students": 4}):
		if str(it.id).begins_with("aluno") or it.id in ["uncle_2", "coach_1", "uncle_1", "osmar", "saco_de_lado"]:
			CHECKS.append("  ocupa %s: %s" % [it.id, str(occ_rect(it))])
	CHECKS.append("CONFERÊNCIA DO CENTRO: %d problema(s)%s" % [problems, " (alunos = dublê; rodar de novo com a folha do Artista)" if student_is_standin() else ""])

func check_envelope_outros() -> void:
	## o envelope cai em chão livre na garagem e na academia também (o patrocínio é oferecido antes do centro)
	for bgid in ["garage_bg", "gym_bg", "center_bg"]:
		var bg: Image = BG if bgid == "center_bg" else load_png(res_abs(str(spr(bgid).file)))
		var r := Rect2i(P_ENVELOPE - Vector2i(8, 10), Vector2i(16, 11))
		var bad := 0
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var n := color_name(bg.get_pixel(x, y))
				if not on_floor(x, y):
					bad += 1
		CHECKS.append("envelope em %s %s: %d px fora do chão" % [bgid, str(P_ENVELOPE), bad])

func check_cartaz() -> void:
	## o cartaz vencido (42x58) cai só em parede lisa da academia; e a pera na parede (Boxe) x cartaz (8a1 e 8a2)
	var gym := load_png(res_abs(str(spr("gym_bg").file)))
	var other := 0
	var src: Image = F["wall_poster_league_regional_won_gym"][1]
	for y in WON.y:
		for x in WON.x:
			if src.get_pixel(x, y).a == 0.0:
				continue
			var n := color_name(gym.get_pixel(POSTER_SPOT.x + x, POSTER_SPOT.y + y))
			if not (n in ["cream", "white", "g3", "g2"]):
				other += 1
	CHECKS.append("cartaz vencido em %s %dx%d: %d px em cima de outra coisa que não parede" % [str(POSTER_SPOT), WON.x, WON.y, other])
	for pid in ["speed_bag_l0_wall_gym", "speed_bag_l1_wall_gym"]:
		var pera := frame_of(pid)
		var tl := P_PERA_WALL - pivot_of(pid)
		var n8a1 := 0
		var n8a2 := 0
		var p8a1 := load_png(res_abs(str(spr("wall_poster_league_regional_gym").file)))
		for y in pera.get_height():
			for x in pera.get_width():
				if pera.get_pixel(x, y).a == 0.0:
					continue
				var sx := tl.x + x - POSTER_SPOT.x
				var sy := tl.y + y - POSTER_SPOT.y
				if sx >= 0 and sy >= 0 and sx < POSTER.x and sy < POSTER.y and p8a1.get_pixel(sx, sy).a > 0.0:
					n8a1 += 1
				if sx >= 0 and sy >= 0 and sx < WON.x and sy < WON.y and src.get_pixel(sx, sy).a > 0.0:
					n8a2 += 1
		CHECKS.append("AVISO academia: %s (Boxe) x cartaz da liga: %d px (8a1), %d px (cartaz vencido)" % [pid, n8a1, n8a2])

# ================================================================== outros mockups
func mock_pecas() -> void:
	## academia x centro, lado a lado, em 3x: todos os aparelhos l0 e l1 (1º quadro)
	var rows := []
	for base in APP_SHEETS:
		for lv in [0, 1]:
			var row := []
			for q in APP_SHEETS[base]:
				var cid := "%s_l%d_%s_center" % [base, lv, q]
				if F.has(cid):
					var src_id: String = META[cid]["from"]
					row.append([src_id, cid])
			rows.append(row)
	var k := 2
	var W := 1500
	var y := 40
	var heights := []
	for row in rows:
		var hmax := 0
		for pair in row:
			hmax = maxi(hmax, frame_of(pair[1]).get_height())
		heights.append(hmax * k + 16)
	var H := 40
	for hh in heights:
		H += hh
	var board: Image = L.blank(W, H + 10)
	L.R(board, 0, 0, W, H + 10, "d1")
	label(board, "FASE 8A2 - APARELHOS DO CENTRO (2X): EM CADA PAR, ACADEMIA (OU GARAGEM) À ESQUERDA E CENTRO À DIREITA. MESMA FORMA, PIVÔ E QUADROS; MATERIAL NOVO", 6, 6, "y1")
	label(board, "SACO: COURO AZUL-MARINHO, FAIXAS BRANCAS | CORDA: CABO AZUL | ESTEIRA: GRAFITE, PAINEL AZUL | PERA: MADEIRA CLARA, COURO CARAMELO | BONECO: COURO VERMELHO | SACO COMPRIDO: LONA CRUA", 6, 20, "g3")
	for ri in rows.size():
		var x := 6
		for pair in rows[ri]:
			for id in pair:
				var fr := frame_of(id)
				if fr.get_width() * k > 300:
					fr = fr.get_region(Rect2i(0, 0, mini(fr.get_width(), 150), fr.get_height()))
				L.R(board, x - 1, y - 1, fr.get_width() * k + 2, fr.get_height() * k + 2, "d2")
				blend(board, scaled(fr, k), x, y)
				x += fr.get_width() * k + 4
			x += 14
		y += heights[ri]
	board.save_png(MOCK + "fase8a2_aparelhos_x2.png")

func mock_cartaz() -> void:
	var gym := load_png(res_abs(str(spr("gym_bg").file)))
	var a: Image = gym.duplicate()
	var b: Image = gym.duplicate()
	blend(a, F["wall_poster_league_regional_won_gym"][0], POSTER_SPOT.x, POSTER_SPOT.y)
	blend(b, F["wall_poster_league_regional_won_gym"][1], POSTER_SPOT.x, POSTER_SPOT.y)
	var crop := Rect2i(330, 30, 160, 110)
	var W := 8 + crop.size.x * 3 * 2 + 12 + 124 * 2 + 8
	var H := 40 + maxi(crop.size.y * 3, 320) + 8
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	label(board, "CARTAZ VENCIDO NA ACADEMIA (3X): ADESIVO DO R NA CARA DO JAMES + RECORTE COM FITA. À DIREITA: COM O PATROCÍNIO (MARCA NO CANTO). ZOOM 2X/1X.", 6, 6, "y1")
	label(board, "SÓ A PARTIR DO 1º CINTURÃO DO VALE DA LINHAGEM. MESMO PONTO DO CARTAZ DA 8A1 (412,54).", 6, 20, "g3")
	board.blit_rect(scaled(a.get_region(crop), 3), Rect2i(0, 0, crop.size.x * 3, crop.size.y * 3), Vector2i(8, 36))
	board.blit_rect(scaled(b.get_region(crop), 3), Rect2i(0, 0, crop.size.x * 3, crop.size.y * 3), Vector2i(8 + crop.size.x * 3 + 6, 36))
	var zx := 8 + crop.size.x * 6 + 12
	blend(board, scaled(F["ui_poster_league_regional_won_zoom"][1], 2), zx, 36) if false else null
	blend(board, F["ui_poster_league_regional_won_zoom"][0], zx, 36)
	blend(board, F["ui_poster_league_regional_won_zoom"][1], zx + 124 + 4, 36)
	blend(board, F["ui_clipping_regional_zoom"][0], zx, 36 + 166)
	board.save_png(MOCK + "fase8a2_cartaz_vencido.png")
	# recorte emoldurado + foto torta no centro (zoom 4x da parede)
	var c: Image = compose({"art": "boxing", "students": 4})
	var cr := Rect2i(60, 84, 120, 70)
	var b2: Image = L.blank(cr.size.x * 4 + 16, cr.size.y * 4 + 40)
	L.R(b2, 0, 0, b2.get_width(), b2.get_height(), "d1")
	label(b2, "CENTRO (4X): CANTO DA MEMÓRIA - RECORTE EMOLDURADO E A FOTO DA GARAGEM, TORTA DE PROPÓSITO", 6, 6, "y1")
	b2.blit_rect(scaled(c.get_region(cr), 4), Rect2i(0, 0, cr.size.x * 4, cr.size.y * 4), Vector2i(8, 30))
	b2.save_png(MOCK + "fase8a2_canto_memoria_x4.png")

func mock_patrocinio() -> void:
	## marca (selo, larga, 9), remendo no calção (lutador da sala e de luta), envelope nos 3 locais
	var W := 900
	var H := 420
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	label(board, "PATROCÍNIO AUTOPEÇAS VALE FORTE (ORIGINAL): SELO 20, LARGA, 9 E O REMENDO DO CALÇÃO (5X3). TUDO EM 4X, MENOS AS SALAS", 6, 6, "y1")
	blend(board, scaled(F["sponsor_vale"][0], 4), 10, 30)
	blend(board, scaled(F["sponsor_vale_wide"][0], 3), 110, 34)
	blend(board, scaled(F["sponsor_vale_9"][0], 4), 110, 110)
	blend(board, scaled(F["sponsor_vale_patch"][0], 4), 160, 114)
	# remendo no calção: lutador da sala (hip do quadro + (−2,+3)) e de luta
	var x := 10
	for sid in ["fighter_idle_disc_layered", "fight_player_idle_disc_layered"]:
		var e := spr(sid)
		if e.is_empty():
			continue
		for q in 2:
			var fr: Image = layered(sid, q, CUR_LOOK).duplicate()
			var anc = e.anchors[q] if e.anchors is Array else e.anchors
			var hip: Array = anc.get("hip", [0, -31])
			var pv := pivot_of(sid)
			var p := Vector2i(pv.x + int(hip[0]) - 2, pv.y + int(hip[1]) + 3)
			blend(fr, F["sponsor_vale_patch"][0], p.x - 2, p.y)
			var s := scaled(fr, 3)
			blend(board, s, x, 150)
			x += s.get_width() + 6
	label(board, "REMENDO = HIP DO QUADRO + (-2,+3), PERNA DA FRENTE. O ARTISTA DE PERSONAGENS CONFERE QUADRO A QUADRO (É A 1ª PEÇA A CORTAR).", 10, 400, "g3")
	board.save_png(MOCK + "fase8a2_patrocinio.png")
	# envelope nos 3 locais (recorte 2x em volta do ponto)
	var b3: Image = L.blank(3 * 260 + 32, 200)
	L.R(b3, 0, 0, b3.get_width(), b3.get_height(), "d1")
	label(b3, "ENVELOPE PROPOSTA NO CHÃO, LOGO DEPOIS DA PORTA (414,238), IGUAL NA GARAGEM, NA ACADEMIA E NO CENTRO (2X)", 6, 6, "y1")
	var bx := 8
	for bgid in ["garage_bg", "gym_bg", "center_bg"]:
		var bg: Image = BG.duplicate() if bgid == "center_bg" else load_png(res_abs(str(spr(bgid).file)))
		blend(bg, F["sponsor_envelope"][2], P_ENVELOPE.x - 8, P_ENVELOPE.y - 10)
		var cr := Rect2i(P_ENVELOPE.x - 65, P_ENVELOPE.y - 75, 130, 85)
		b3.blit_rect(scaled(bg.get_region(cr), 2), Rect2i(0, 0, 260, 170), Vector2i(bx, 24))
		bx += 268
	b3.save_png(MOCK + "fase8a2_envelope_locais_x2.png")
