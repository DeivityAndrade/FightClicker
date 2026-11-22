extends SceneTree
## Fase 8a1 (Diretor de Arte): Liga Regional do Vale. PLACEHOLDER gerado por código, tudo original.
##   godot --headless --path <worktree> --script res://tools/art/make_arte_fase8a1.gd              (sprites + mockups)
##   godot --headless --path <worktree> --script res://tools/art/make_arte_fase8a1.gd -- --no-assets  (só mockups)
## Depois: python tools/art/manifest_8a1.py (lê tools/art/fase8a1_sprites.json, que este script grava).
## Grava:
##   assets/sprites/fight/arena_regional_bg|crowd_back|crowd_front|ropes_side|spot.png  (Clube Ferroviário, à noite, ringue)
##   assets/sprites/fight/fx_guard_clink.png                                             (golpe batendo na guarda do Blindado)
##   assets/sprites/gym/wall_poster_league_regional_gym.png + ui/ui_poster_league_regional_zoom.png (cartaz da liga)
##   assets/sprites/ui/belt_regional_big|belt_regional_raised|icon_belt_regional|icon_belt_regional_9.png (Cinturão do Vale)
##   assets/sprites/ui/adv_iron_chin|adv_wide_base|adv_slippery|adv_blindado|adv_blindado_open (16 e _9)
##   assets/sprites/ui/ui_banner_opp_iron_chin|opp_wide_base|opp_slippery|guard_closed|guard_open.png (sinais da §3.2)
##   docs/arte/mockups/fase8a1_*.png
## Contrato da arena = o das outras (manifest fight_layout): 640x360, y 0..45 ink liso (HUD), pés em y 318, pivôs 296/346,
## chão livre x 200..440, público da frente só nos cantos. Textos = Roteirista (fase8a1-textos.md): constantes TXT_* abaixo.
## Retrato do James: se assets/sprites/opponents/portrait_opp_james.png existir, o cartaz usa ele (foto em 2 tons);
## senão, um busto provisório. Rodar de novo quando o Artista de Personagens entregar o retrato.

const TXT_LEAGUE := "LIGA REGIONAL DO VALE"
const TXT_ARENA := "CLUBE FERROVIÁRIO"
const TXT_SPONSOR := "AUTOPEÇAS VALE FORTE"
const TXT_BELT := "VALE"
const TXT_IRON_CHIN := "AGUENTOU!"        # fight_opp_block_adv_iron_chin
const TXT_WIDE_BASE := "NÃO CAIU"         # fight_opp_block_adv_wide_base
const TXT_SLIPPERY := "ESCAPOU!"          # fight_opp_block_adv_slippery
const TXT_GUARD_CLOSED := "GUARDA FECHADA"  # letreiro do Roteirista (opcional; pode ser texto)
const TXT_GUARD_OPEN := "A GUARDA ABRIU"  # fight_guard_open

var ROOT := ""
var OUT := ""
var MOCK := ""
var NO_ASSETS := false
var L
var F := {}      # id -> Array[Image]
var META := {}   # id -> {rel, frame_size, frames, fps, pivot}
var CHECKS := []

# ---------------------------------------------------------------- geometria do ringue (mesma câmera das outras arenas)
const VPY := -28.0                  # ponto de fuga (320,-28)
const CANVAS_TOP := 262             # borda de trás da lona
const CANVAS_BOT := 342             # borda da frente da lona
const XL_B := 104                   # cantos da frente (x) na borda da frente
const XR_B := 536
const POST_H := 66                  # altura do poste da frente (px); atrás escala pela perspectiva
const ROPE_F := [0.30, 0.61, 0.92]  # alturas das 3 cordas (fração do poste): de baixo para cima
const ROPE_C := [["b1", "b2"], ["g3", "white"], ["r1", "r2"]]  # azul embaixo, branca no meio, vermelha em cima
const SKIRT_BOT := 357
const CROWD_Y := 180                # mesmo pos do público das outras arenas
const ROPES_Y := 196                # recorte da camada das cordas da frente (ropes_side)
const SPOT_C := Vector2(320, 300)   # centro da luz do ringue

func _init() -> void:
	ROOT = ProjectSettings.globalize_path("res://")
	if not ROOT.ends_with("/"):
		ROOT += "/"
	OUT = ROOT + "assets/sprites/"
	MOCK = ROOT + "docs/arte/mockups/"
	NO_ASSETS = OS.get_cmdline_user_args().has("--no-assets")
	L = load("res://tools/art/pixel_lib.gd").new()
	make_arena()
	make_passive_icons()
	make_banners()
	make_fx()
	make_belt()
	make_poster()
	make_balloon_tag()
	if not NO_ASSETS:
		var f := FileAccess.open(ROOT + "tools/art/fase8a1_sprites.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(META, "\t", true))
		f.close()
	mock_arena()
	mock_letreiros()
	mock_entrada()
	mock_pecas()
	mock_cartaz()
	mock_cinturao_erguido()
	for c in CHECKS:
		print(c)
	print("8a1: ", META.size(), " sprites", " (não gravados)" if NO_ASSETS else "", "; mockups em ", MOCK)
	quit()

# ================================================================== util (mesmos da 7b2)
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

func bayer(x: int, y: int) -> float:
	return (L.BAYER[posmod(y, 4)][posmod(x, 4)] + 0.5) / 16.0

func load_png(p: String) -> Image:
	var im := Image.load_from_file(p)
	im.convert(Image.FORMAT_RGBA8)
	return im

func region_of(p: String, i: int, w: int, h: int) -> Image:
	return load_png(ROOT + p).get_region(Rect2i(i * w, 0, w, h))

func put(dst: Image, src: Image, pos: Vector2i, pivot: Vector2i) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), pos - pivot)

func put_k(dst: Image, src: Image, x: int, y: int, k: int) -> void:
	var s := scaled(src, k)
	dst.blend_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(x, y))

func scaled(src: Image, k: int) -> Image:
	var s: Image = src.duplicate()
	s.resize(src.get_width() * k, src.get_height() * k, Image.INTERPOLATE_NEAREST)
	return s

func label(img: Image, s: String, x: int, y: int, c := "white") -> void:
	L.text(img, s, x, y, c, 1, "ink")

func kf(y: float) -> float:
	## escala da perspectiva na linha y, relativa à borda da frente da lona
	return (y - VPY) / (CANVAS_BOT - VPY)

func x_at(xb: float, y: float) -> float:
	## x na linha y de uma reta do chão que passa por xb na borda da frente e vai para o ponto de fuga
	return 320.0 + (xb - 320.0) * kf(y)

func thick_line(img: Image, a: Vector2i, b: Vector2i, c, t: int) -> void:
	for k in t:
		L.line(img, a.x, a.y + k, b.x, b.y + k, c)

# ================================================================== ARENA: Clube Ferroviário, à noite
## Ginásio de clube antigo de ferroviários: tijolo, janelas em arco com a noite lá fora, nome do clube pintado na parede,
## relógio de estação, placa AO VIVO da TV, arquibancada de madeira com a torcida no escuro, treliça de luz em cima com a
## faixa da liga, câmera da TV regional num praticável à direita e o RINGUE de verdade no meio (lona, 4 postes, 3 cordas,
## saia com o patrocinador). Luz de noite: o ringue claro, o resto cai no escuro em faixas com dither.
var ARENA: Image
var RING_MASK: Image     # o que fica NA FRENTE do público de trás (ringue + câmera): o público é recortado por esta máscara
var ROPES_FRONT: Image   # cordas laterais + postes da frente (camada opcional por cima dos lutadores)

func make_arena() -> void:
	var img: Image = L.blank(640, 360)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8101
	L.R(img, 0, 0, 640, 360, "ink")
	hall_back(img, rng)
	bleachers(img, rng)
	ringside_floor(img, rng)
	tv_riser(img)
	judges_and_corner(img)
	# luz da noite: tudo o que está acima é escurecido longe do ringue
	night_light(img, Rect2i(0, 46, 640, 314), Vector2i.ZERO)
	# o ringue e a treliça recebem luz própria (desenhados depois da luz geral)
	var ring := ring_layer()
	img.blend_rect(ring, Rect2i(0, 0, 640, 360), Vector2i.ZERO)
	truss_and_banner(img)
	beams(img)
	ARENA = img
	# máscara do que fica na frente do público de trás
	RING_MASK = L.blank(640, 360)
	RING_MASK.blend_rect(ring, Rect2i(0, 0, 640, 360), Vector2i.ZERO)
	var cam: Image = L.blank(640, 360)
	tv_riser(cam)
	judges_and_corner(cam)
	RING_MASK.blend_rect(cam, Rect2i(0, 0, 640, 360), Vector2i.ZERO)
	check_contract(img)
	save_sheet("arena_regional_bg", "fight/arena_regional_bg.png", [img], 0.0, Vector2i.ZERO)
	# público de trás: o do Ginásio Alvorada com paleta de noite (torcida do Vale), recortado pelo ringue
	var crowd := crowd_back_night()
	save_sheet("arena_regional_crowd_back", "fight/arena_regional_crowd_back.png", crowd, 4.0, Vector2i.ZERO)
	save_sheet("arena_regional_crowd_front", "fight/arena_regional_crowd_front.png", crowd_front_night(), 4.0, Vector2i.ZERO)
	var ropes: Image = ROPES_FRONT.get_region(Rect2i(0, ROPES_Y, 640, SKIRT_BOT - ROPES_Y))
	save_sheet("arena_regional_ropes_side", "fight/arena_regional_ropes_side.png", [ropes], 0.0, Vector2i.ZERO)
	save_sheet("arena_regional_spot", "fight/arena_regional_spot.png", [spot_frame(0), spot_frame(1)], 8.0, Vector2i(48, 258))
	check_ropes_clear()

func check_contract(img: Image) -> void:
	var bad := 0
	for y in 46:
		for x in 640:
			if not img.get_pixel(x, y).is_equal_approx(L.C.ink):
				bad += 1
	CHECKS.append("arena_regional: faixa do HUD (y 0..45) px fora do ink = %d" % bad)

func check_ropes_clear() -> void:
	## a camada das cordas da frente não pode encostar na área dos lutadores (x 200..440)
	var bad := 0
	for y in ROPES_FRONT.get_height():
		for x in range(200, 441):
			if ROPES_FRONT.get_pixel(x, y).a > 0.0:
				bad += 1
	CHECKS.append("arena_regional_ropes_side: px dentro de x 200..440 = %d" % bad)

## Luz de noite: centro no ringue, faixas com dither; offset = deslocamento da imagem em relação à tela (para as camadas).
func night_light(img: Image, area: Rect2i, off: Vector2i) -> void:
	L.light(img, area, SPOT_C - Vector2(off), 300.0, 1.5, 2.3, -2, 1, 1.25)

func brick_wall(img: Image, x0: int, y0: int, w: int, h: int) -> void:
	L.R(img, x0, y0, w, h, "br1")
	for y in range(y0, y0 + h):
		var row := (y - y0) / 6
		if (y - y0) % 6 == 5:
			L.R(img, x0, y, w, 1, "br0")
			continue
		for x in range(x0, x0 + w):
			if (x + (6 if row % 2 else 0)) % 12 == 0:
				L.P(img, x, y, "br0")
			elif (x * 7 + y * 13) % 29 == 0:
				L.P(img, x, y, "br2")

func arched_window(img: Image, x: int, y: int, w: int, h: int) -> void:
	## janela alta em arco, de noite: vidro azul escuro, caixilho de ferro, um reflexo de lua
	var r := w / 2
	for yy in range(y - 1, y + h + 1):
		for xx in range(x - 1, x + w + 1):
			var inside := false
			var edge := false
			if yy >= y + r:
				inside = xx >= x and xx < x + w and yy < y + h
				edge = not inside
			else:
				var d := Vector2(xx + 0.5 - (x + r), yy + 0.5 - (y + r)).length()
				inside = d <= r
				edge = d <= r + 1.2 and not inside
			if inside:
				L.P(img, xx, yy, "b0" if bayer(xx, yy) < 0.72 else "b1")
			elif edge:
				L.P(img, xx, yy, "ink")
	# caixilho
	L.R(img, x + r, y + 1, 1, h - 1, "d2")
	for gy in range(y + r, y + h, 9):
		L.R(img, x, gy, w, 1, "d2")
	# peitoril de pedra
	L.R(img, x - 3, y + h, w + 6, 3, "g1"); L.R(img, x - 3, y + h, w + 6, 1, "g2")
	# reflexo da lua (canto de cima)
	L.P(img, x + 3, y + r - 2, "b2"); L.P(img, x + 4, y + r - 3, "b2"); L.P(img, x + 4, y + r - 2, "b3")

func station_clock(img: Image, cx: int, cy: int) -> void:
	## relógio de estação (lembra o ferroviário): mostrador creme, ponteiros, braço de ferro na parede
	L.R(img, cx - 1, cy - 16, 3, 4, "ink")
	L.R(img, cx - 10, cy - 15, 21, 2, "ink"); L.R(img, cx - 9, cy - 15, 19, 1, "st1")
	L.ellipse(img, cx + 0.5, cy + 0.5, 11, 11, "ink")
	L.ellipse(img, cx + 0.5, cy + 0.5, 10, 10, "st1")
	L.ellipse(img, cx + 0.5, cy + 0.5, 8.5, 8.5, "cream")
	for a in 12:
		var ang := a * TAU / 12.0
		L.P(img, cx + int(round(cos(ang) * 7)), cy + int(round(sin(ang) * 7)), "d2")
	L.line(img, cx, cy, cx, cy - 6, "ink")       # 9 e meia da noite
	L.line(img, cx, cy, cx - 4, cy + 1, "ink")
	L.P(img, cx, cy, "r1")

func winged_wheel(img: Image, cx: int, cy: int, c: String, c2: String) -> void:
	## emblema do clube: roda com asas (pintado na parede, desbotado)
	L.ring(img, cx + 0.5, cy + 0.5, 5, 5, 1.5, c)
	L.P(img, cx, cy, c)
	for a in 4:
		var ang := a * TAU / 4.0 + 0.4
		L.P(img, cx + int(round(cos(ang) * 2.5)), cy + int(round(sin(ang) * 2.5)), c2)
	for side: int in [-1, 1]:
		for k in 3:
			var x0: int = cx + side * 6
			L.line(img, x0, cy - 2 + k * 2, x0 + side * (9 - k * 2), cy - 4 + k * 3, c)

func hall_back(img: Image, rng: RandomNumberGenerator) -> void:
	# forro escuro (y 46..61): vigas de madeira em contraluz
	L.R(img, 0, 46, 640, 16, "d1")
	for x in range(0, 640, 40):
		L.R(img, x, 46, 3, 16, "br0")
	L.R(img, 0, 61, 640, 1, "ink")
	# parede de tijolo
	brick_wall(img, 0, 62, 640, 90)
	# frisos de reboco (parede de clube antigo)
	L.R(img, 0, 62, 640, 3, "g1"); L.R(img, 0, 64, 640, 1, "g0")
	# janelas em arco (noite) nas laterais
	for wx in [18, 70, 534, 586]:
		arched_window(img, wx, 72, 36, 56)
	# nome do clube pintado na parede (desbotado: g2 sobre tijolo) + emblema dos dois lados
	var tw: int = L.text_w(TXT_ARENA, 2)
	L.R(img, 320 - tw / 2 - 8, 86, tw + 16, 22, "br0")
	L.R(img, 320 - tw / 2 - 7, 87, tw + 14, 20, "br1")
	L.text_center(img, TXT_ARENA, 320, 91, "g3", 2, "br0")
	for y in range(87, 107):
		for x in range(320 - tw / 2 - 7, 320 + tw / 2 + 7):
			if img.get_pixel(x, y).is_equal_approx(L.C.g3) and bayer(x, y) < 0.22:
				img.set_pixel(x, y, L.C.g2)       # tinta descascada
	winged_wheel(img, 320 - tw / 2 - 24, 96, "g2", "g1")
	winged_wheel(img, 320 + tw / 2 + 24, 96, "g2", "g1")
	# relógio de estação (esquerda) e placa AO VIVO da TV (direita), fora do miolo do letreiro
	station_clock(img, 150, 98)
	L.R(img, 472, 88, 44, 18, "ink"); L.R(img, 473, 89, 42, 16, "r0"); L.R(img, 474, 90, 40, 14, "r1")
	L.text_center(img, "AO VIVO", 494, 93, "y2", 1)
	L.ellipse(img, 478.5, 96.5, 1.5, 1.5, "r3")
	# galeria: guarda-corpo de ferro na frente da arquibancada de cima
	L.R(img, 0, 150, 640, 2, "st1"); L.R(img, 0, 150, 640, 1, "st2")
	for x in range(4, 640, 12):
		L.R(img, x, 152, 1, 6, "st0")
	L.R(img, 0, 157, 640, 1, "st0")

func seated_night(img: Image, x: int, y: int, rng: RandomNumberGenerator) -> void:
	var shirts := ["gr1", "b1", "r1", "br1", "st1", "gr0", "g1", "b0", "y0", "cream", "r0"]
	var skins := ["sk0", "sk1", "sk2"]
	var sc: String = shirts[rng.randi_range(0, shirts.size() - 1)]
	var sk: String = skins[rng.randi_range(0, 2)]
	var top := y - 10
	L.R(img, x - 3, top + 5, 7, 7, sc)
	L.P(img, x - 3, top + 5, L.shade(L.col(sc), -1)); L.P(img, x + 3, top + 5, L.shade(L.col(sc), -1))
	L.R(img, x + 3, top + 6, 1, 6, L.shade(L.col(sc), 1))     # a luz do ringue vem de baixo/centro
	L.R(img, x - 1, top, 3, 5, sk)
	L.P(img, x - 2, top + 1, sk); L.P(img, x + 2, top + 1, sk); L.P(img, x - 2, top + 2, sk); L.P(img, x + 2, top + 2, sk)
	var hair: String = ["ink", "d1", "br0", "br1", "g2"][rng.randi_range(0, 4)]
	L.R(img, x - 1, top - 1, 3, 2, hair); L.P(img, x - 2, top, hair); L.P(img, x + 2, top, hair)
	L.R(img, x - 3, top + 12, 7, 2, "d2")
	if rng.randf() < 0.07:                                   # celular filmando (tela acesa)
		L.R(img, x + 2, top - 3, 2, 3, "b3"); L.P(img, x + 2, top - 3, "white")

func bleachers(img: Image, rng: RandomNumberGenerator) -> void:
	# arquibancada de madeira (y 158..232), 5 degraus, com a torcida sentada no escuro
	var sy0 := 160
	var sh := 15
	for s in 5:
		var y := sy0 + s * sh
		L.R(img, 0, y, 640, 3, "br2"); L.R(img, 0, y, 640, 1, "br3")
		L.R(img, 0, y + 3, 640, sh - 3, "br1"); L.R(img, 0, y + 3, 640, 1, "br0")
		L.dither(img, 0, y + sh - 3, 640, 3, "br0")
	for s in 5:
		var y := sy0 + s * sh + 3
		var xx := rng.randi_range(2, 10)
		while xx < 636:
			if rng.randf() < 0.78:
				seated_night(img, xx, y, rng)
			xx += rng.randi_range(9, 13)
	# bandeiras da torcida penduradas no guarda-corpo (verde e amarelo do Vale; nada de time real)
	for fl in [[34, "gr1", "y0"], [196, "b1", "white"], [420, "gr1", "y0"], [600, "r1", "white"]]:
		var fx: int = fl[0]
		L.R(img, fx, 152, 26, 16, "ink"); L.R(img, fx + 1, 152, 24, 15, fl[1])
		L.R(img, fx + 1, 158, 24, 3, fl[2])
		L.P(img, fx + 1, 167, "ink"); L.P(img, fx + 24, 167, "ink")

func ringside_floor(img: Image, rng: RandomNumberGenerator) -> void:
	# grade baixa entre a torcida e a beira do ringue, e o chão de taco escuro do ginásio
	L.R(img, 0, 232, 640, 2, "st1"); L.R(img, 0, 232, 640, 1, "st2")
	for x in range(6, 640, 10):
		L.R(img, x, 234, 1, 10, "st0")
	L.R(img, 0, 243, 640, 1, "st0")
	L.R(img, 0, 244, 640, 116, "br1")
	for y in range(244, 360, 4):
		L.R(img, 0, y, 640, 1, "br0")
	for i in 240:
		L.P(img, rng.randi_range(0, 639), rng.randi_range(245, 359), "br2")

func tv_riser(img: Image) -> void:
	## praticável da TV regional à direita, na beira do ringue: caixa preta, tripé, câmera grande com luz vermelha e o câmera
	var x0 := 560
	L.R(img, x0, 226, 70, 38, "ink"); L.R(img, x0 + 1, 227, 68, 36, "d1"); L.R(img, x0 + 1, 227, 68, 2, "d2")
	L.text_center(img, "TV VALE", x0 + 35, 240, "g2", 1)
	L.R(img, x0 + 6, 251, 58, 1, "d2")
	# tripé
	L.line(img, 584, 225, 576, 210, "st1"); L.line(img, 590, 225, 590, 210, "st1"); L.line(img, 596, 225, 604, 210, "st1")
	L.R(img, 584, 206, 14, 4, "st0")
	# câmera (virada para a esquerda, para o ringue)
	L.R(img, 572, 190, 30, 16, "ink"); L.R(img, 573, 191, 28, 14, "st0"); L.R(img, 573, 191, 28, 2, "st1")
	L.R(img, 562, 193, 11, 10, "ink"); L.R(img, 563, 194, 9, 8, "d1"); L.R(img, 563, 196, 2, 4, "b2")   # lente
	L.R(img, 588, 186, 10, 5, "ink"); L.R(img, 589, 187, 8, 3, "d2")                                     # visor
	L.P(img, 598, 193, "r2"); L.P(img, 599, 193, "r3")                                                    # luz de gravando
	L.text(img, "TV", 579, 196, "y1", 1)
	# o câmera atrás (silhueta com fone)
	L.ellipse(img, 612, 192, 5, 6, "ink"); L.R(img, 604, 198, 18, 28, "ink")
	L.R(img, 606, 186, 12, 2, "d2"); L.P(img, 606, 190, "d2"); L.P(img, 617, 190, "d2")
	L.R(img, 600, 200, 6, 3, "ink")

func judges_and_corner(img: Image) -> void:
	# mesa dos juízes com sino à esquerda (na frente da grade) e o banco do corner à direita, fora do centro
	var x := 6
	var y := 262
	L.R(img, x, y + 6, 88, 3, "ink"); L.R(img, x + 1, y + 6, 86, 2, "g2")
	L.R(img, x + 2, y + 9, 84, 13, "d1"); L.R(img, x + 2, y + 9, 84, 1, "d2"); L.R(img, x + 2, y + 21, 84, 1, "ink")
	L.text(img, "MESA", x + 31, y + 12, "g3", 1)
	L.R(img, x + 6, y + 22, 2, 8, "st0"); L.R(img, x + 80, y + 22, 2, 8, "st0")
	L.R(img, x + 62, y - 2, 12, 8, "ink"); L.ellipse(img, x + 68, y + 2, 5, 4, "y0"); L.P(img, x + 66, y + 1, "y2"); L.R(img, x + 63, y + 5, 10, 1, "br1")
	L.R(img, x + 12, y + 1, 12, 6, "ink"); L.R(img, x + 13, y + 2, 10, 4, "cream")
	L.R(img, x + 44, y - 1, 6, 7, "ink"); L.R(img, x + 45, y, 4, 2, "st2"); L.P(img, x + 46, y + 2, "r2")      # microfone do locutor
	# banco do corner, balde e toalha (direita, fora da lona)
	L.R(img, 562, 276, 34, 4, "ink"); L.R(img, 563, 276, 32, 2, "r1"); L.R(img, 566, 280, 2, 12, "st0"); L.R(img, 590, 280, 2, 12, "st0")
	L.R(img, 600, 280, 14, 13, "ink"); L.R(img, 601, 281, 12, 11, "st1"); L.R(img, 601, 281, 12, 2, "st2")
	L.R(img, 566, 272, 14, 5, "ink"); L.R(img, 567, 273, 12, 3, "white")

## Ringue em camada própria (também vira a máscara do público): lona, saia, 4 postes, 3 cordas.
func ring_layer() -> Image:
	var img: Image = L.blank(640, 360)
	ROPES_FRONT = L.blank(640, 360)
	var xl_t := x_at(XL_B, CANVAS_TOP)
	var xr_t := x_at(XR_B, CANVAS_TOP)
	var h_back := int(round(POST_H * kf(CANVAS_TOP)))
	# saia da frente (y CANVAS_BOT+1..SKIRT_BOT): pano escuro com o patrocinador
	L.R(img, XL_B - 2, CANVAS_BOT + 1, XR_B - XL_B + 5, SKIRT_BOT - CANVAS_BOT, "ink")
	L.R(img, XL_B - 1, CANVAS_BOT + 2, XR_B - XL_B + 3, SKIRT_BOT - CANVAS_BOT - 2, "d1")
	L.R(img, XL_B - 1, CANVAS_BOT + 2, XR_B - XL_B + 3, 1, "d2")
	L.text_center(img, TXT_SPONSOR, 320, CANVAS_BOT + 4, "y1", 1, "br0")
	for sx in [196, 444]:
		L.text_center(img, "VALE", sx, CANVAS_BOT + 4, "g2", 1)
	# lona (trapézio): creme com sujeira, mais clara no meio (a luz é aplicada depois)
	for y in range(CANVAS_TOP, CANVAS_BOT + 1):
		var t := float(y - CANVAS_TOP) / float(CANVAS_BOT - CANVAS_TOP)
		var xl := lerpf(xl_t, float(XL_B), t)
		var xr := lerpf(xr_t, float(XR_B), t)
		for x in range(int(round(xl)), int(round(xr)) + 1):
			var c := "g3"
			if (x * 31 + y * 17) % 53 == 0:
				c = "g2"
			L.P(img, x, y, c)
	# beirada da lona (pano que dobra na borda) e o emblema da liga no meio
	L.R(img, XL_B, CANVAS_BOT, XR_B - XL_B + 1, 1, "g2")
	L.ring(img, 320.5, 300.5, 62, 13, 2.0, "b1")
	L.ring(img, 320.5, 300.5, 57, 10.5, 1.0, "b2")
	L.text_center(img, "LIGA DO VALE", 320, 297, "b1", 1)
	# luz do ringue (antes dos postes e cordas): centro claro, beiradas escurecem
	L.light(img, Rect2i(0, CANVAS_TOP, 640, SKIRT_BOT - CANVAS_TOP + 1), SPOT_C, 230.0, 1.6, 1.6, -2, 1, 1.35)
	# postes de trás (atrás das cordas de trás), cordas de trás, depois cordas laterais e postes da frente
	var posts := [[Vector2i(int(round(xl_t)), CANVAS_TOP), h_back, 3, "b2"], [Vector2i(int(round(xr_t)), CANVAS_TOP), h_back, 3, "r2"]]
	for p in posts:
		post(img, p[0], p[1], p[2], p[3], false)
	for i in 3:
		var yb := CANVAS_TOP - int(round(h_back * ROPE_F[i]))
		var c: Array = ROPE_C[i]
		L.R(img, int(round(xl_t)) + 2, yb, int(round(xr_t - xl_t)) - 3, 1, c[1])
		L.R(img, int(round(xl_t)) + 2, yb + 1, int(round(xr_t - xl_t)) - 3, 1, c[0])
		# luvas de pano na corda (amarras) a cada 1/4
		for q in [0.25, 0.5, 0.75]:
			var qx := int(round(lerpf(xl_t, xr_t, q)))
			L.R(img, qx - 1, yb, 2, 2, "g2")
	# cordas laterais (2 px na frente, 1 px atrás) e postes da frente: vão também na camada ROPES_FRONT
	for side in [[XL_B, xl_t, "b2"], [XR_B, xr_t, "r2"]]:
		var xf: int = side[0]
		var xb := int(round(float(side[1])))
		for tgt in [img, ROPES_FRONT]:
			for i in 3:
				var yf := CANVAS_BOT - int(round(POST_H * ROPE_F[i]))
				var yb := CANVAS_TOP - int(round(h_back * ROPE_F[i]))
				var c: Array = ROPE_C[i]
				L.line(tgt, xf, yf, xb, yb, c[1])
				L.line(tgt, xf, yf + 1, xb, yb + 1, c[0])
				L.line(tgt, xf, yf + 2, xb, yb + 1, "ink")
		for tgt in [img, ROPES_FRONT]:
			post(tgt, Vector2i(xf, CANVAS_BOT), POST_H, 5, "white", true)
	# cantos coloridos: azul à esquerda (o seu), vermelho à direita (o dele), brancos neutros na frente
	return img

func post(img: Image, base: Vector2i, h: int, w: int, pad: String, front: bool) -> void:
	## poste de aço com almofadas (protetores) cobrindo a altura das cordas
	var x0 := base.x - w / 2
	L.R(img, x0 - 1, base.y - h - 1, w + 2, h + 2, "ink")
	L.R(img, x0, base.y - h, w, h, "st1")
	L.R(img, x0, base.y - h, 1, h, "st2")
	L.R(img, x0 + w - 1, base.y - h, 1, h, "st0")
	var top := base.y - h + 2
	var pad_h := int(round(h * 0.78))
	var pw := w + (2 if front else 1)
	L.R(img, base.x - pw / 2 - 1, top - 1, pw + 2, pad_h + 2, "ink")
	var ramp_pad := {"white": ["g2", "g3", "white"], "b2": ["b0", "b1", "b2"], "r2": ["r0", "r1", "r2"]}
	var rp: Array = ramp_pad[pad]
	L.R(img, base.x - pw / 2, top, pw, pad_h, rp[1])
	L.R(img, base.x - pw / 2, top, 1, pad_h, rp[2])
	L.R(img, base.x - pw / 2 + pw - 1, top, 1, pad_h, rp[0])
	for k in range(1, 3):
		L.R(img, base.x - pw / 2, top + pad_h * k / 3, pw, 1, rp[0])
	# pé do poste
	L.R(img, x0 - 1, base.y - 1, w + 2, 2, "ink")

func truss_and_banner(img: Image) -> void:
	# treliça de luz (y 46..53) atravessando o alto, com 4 refletores apontados para o ringue
	L.R(img, 40, 46, 560, 2, "st1"); L.R(img, 40, 52, 560, 2, "st0")
	var x := 40
	while x < 600:
		L.line(img, x, 48, x + 4, 51, "st0"); L.line(img, x + 4, 51, x + 8, 48, "st0")
		x += 8
	for lx in [118, 212, 428, 522]:
		L.R(img, lx - 1, 54, 2, 3, "ink")
		L.R(img, lx - 6, 56, 12, 9, "ink"); L.R(img, lx - 5, 57, 10, 6, "d2"); L.R(img, lx - 5, 57, 10, 1, "g0")
		L.R(img, lx - 4, 63, 8, 2, "y2"); L.R(img, lx - 3, 65, 6, 1, "y1")
	# faixa da liga pendurada na treliça (pano creme, letras vermelhas, faixa verde do Vale)
	var fw: int = L.text_w(TXT_LEAGUE, 2) + 20
	var fx := 320 - fw / 2
	L.line(img, fx + 4, 53, fx + 4, 56, "d2"); L.line(img, fx + fw - 5, 53, fx + fw - 5, 56, "d2")
	L.R(img, fx, 56, fw, 22, "ink"); L.R(img, fx + 1, 57, fw - 2, 20, "cream")
	L.R(img, fx + 1, 57, fw - 2, 2, "gr1"); L.R(img, fx + 1, 75, fw - 2, 1, "g3"); L.R(img, fx + 1, 76, fw - 2, 1, "gr1")
	L.text_center(img, TXT_LEAGUE, 320, 61, "r1", 2)
	for k in [fx + 3, fx + fw - 4]:
		L.P(img, k, 59, "st1")

func beams(img: Image) -> void:
	## fachos dos 4 refletores descendo até a lona: 1 passo mais claro em dither, sumindo para baixo
	for lx in [118, 212, 428, 522]:
		var tx: float = 320.0 + (lx - 320.0) * 0.35
		for y in range(66, CANVAS_TOP + 20):
			var t := float(y - 66) / float(CANVAS_TOP + 20 - 66)
			var cx := lerpf(lx, tx, t)
			var hw := lerpf(4.0, 30.0, t)
			for xx in range(int(cx - hw), int(cx + hw) + 1):
				if xx < 0 or xx >= 640:
					continue
				var edge := absf(xx - cx) / hw
				if bayer(xx, y) < 0.16 * (1.0 - edge) * (1.0 - t * 0.5):
					img.set_pixel(xx, y, L.shade(img.get_pixel(xx, y), 1))

## Público de trás: as MESMAS figuras do Ginásio Alvorada (arena_league_crowd_back), com troca de paleta para a torcida do
## Vale (verde, azul, vermelho escuro; bandeiras verdes), a luz de noite por cima e recortadas onde o ringue fica na frente.
const CROWD_SWAP := {"r1": "gr1", "b1": "r1", "gr1": "b1", "r2": "y0", "b2": "gr2", "y0": "r2", "p1": "st1", "cream": "g3",
	"st2": "gr1", "br2": "br1"}

func crowd_back_night() -> Array:
	var src := load_png(ROOT + "assets/sprites/fight/arena_league_crowd_back.png")
	var frames := []
	for f in 2:
		var im: Image = src.get_region(Rect2i(f * 640, 0, 640, 100))
		for y in 100:
			for x in 640:
				var c := im.get_pixel(x, y)
				if c.a == 0.0:
					continue
				var cn := color_name(c)
				if CROWD_SWAP.has(cn):
					im.set_pixel(x, y, L.col(CROWD_SWAP[cn]))
		night_light(im, Rect2i(0, 0, 640, 100), Vector2i(0, CROWD_Y))
		# recorte: tudo o que o ringue/câmera cobre na tela some do público
		for y in 100:
			for x in 640:
				if RING_MASK.get_pixel(x, y + CROWD_Y).a > 0.0:
					im.set_pixel(x, y, Color(0, 0, 0, 0))
		frames.append(im)
	return frames

func color_name(c: Color) -> String:
	var hx := c.to_html(false)
	for k in L.PAL_HEX:
		if L.PAL_HEX[k] == hx:
			return k
	return ""

func crowd_front_night() -> Array:
	## a frente do Ginásio (silhuetas nos cantos) com boné e bandeira verdes, e um câmera de mão da TV no canto direito
	var src := load_png(ROOT + "assets/sprites/fight/arena_league_crowd_front.png")
	var frames := []
	for f in 2:
		var im: Image = src.get_region(Rect2i(f * 640, 0, 640, 48))
		for y in 48:
			for x in 640:
				var c := im.get_pixel(x, y)
				if c.a == 0.0:
					continue
				var n := color_name(c)
				if n == "r0":
					im.set_pixel(x, y, L.C.gr0)
				elif n == "b0":
					im.set_pixel(x, y, L.C.gr0)
		# câmera de mão (canto direito, sobre a silhueta de x 596): corpo ink, lente e luz vermelha de gravando
		var bob := 1 if f == 1 else 0
		L.R(im, 566, 14 - bob, 22, 12, "ink"); L.R(im, 560, 17 - bob, 7, 7, "ink")
		L.R(im, 568, 16 - bob, 10, 1, "d2"); L.P(im, 561, 19 - bob, "b1")
		L.P(im, 584, 16 - bob, "r2" if f == 0 else "r3")
		frames.append(im)
	return frames

func spot_frame(f: int) -> Image:
	## luz de entrada (opcional): facho em dither que segue o lutador na entrada no ringue; pivô = pés (48,258)
	var w := 96
	var h := 262
	var im: Image = L.blank(w, h)
	var dens := 0.20 if f == 0 else 0.14
	for y in h:
		var t := float(y) / float(h - 8)
		var hw := lerpf(5.0, 34.0, minf(t, 1.0))
		for x in w:
			var d := absf(x + 0.5 - 48.0) / hw
			if d <= 1.0 and y < h - 8 and bayer(x, y) < dens * (1.0 - d * 0.6):
				L.P(im, x, y, "y2")
	# poça de luz no chão (elipse 40x7)
	for y in range(h - 9, h):
		for x in w:
			var nx := (x + 0.5 - 48.0) / 40.0
			var ny := (y + 0.5 - (h - 4.5)) / 4.5
			if nx * nx + ny * ny <= 1.0 and bayer(x, y) < dens * 1.6:
				L.P(im, x, y, "y2")
	return im

# ================================================================== ícones das passivas dos adversários
## Regra de leitura: as 4 são do ADVERSÁRIO, então moram num escudinho de borda vermelha (o lado dele no HUD) e o desenho
## é de material/defesa (bigorna, pé de cimento, sabão, chapa), nunca de golpe. Ficam ao lado da vida dele.

func badge16(inner: Image) -> Image:
	## base comum 16x16: miolo d1 com borda r1 (vermelho = do adversário) e o desenho por cima
	var im: Image = L.blank(16, 16)
	pmap(im, 0, 0, [
		".kkkkkkkkkkkkkk.",
		"kRRRRRRRRRRRRRRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		"kRddddddddddddRk",
		".kRddddddddddRk.",
		"..kRRRRRRRRRRk..",
		"...kkkkkkkkkk...",
		], {"k": "ink", "R": "r1", "d": "d1"})
	im.blend_rect(inner, Rect2i(0, 0, 16, 16), Vector2i.ZERO)
	return im

func icon_iron_chin_16() -> Image:
	var im: Image = L.blank(16, 16)
	# bigorna de aço (chifre à esquerda), com faísca: "bate e não cai"
	pmap(im, 2, 4, [
		"kkkkkkkkkkk.",
		"kHHHHHHHHHHk",
		".kSSSSSSSSk.",
		"...kSSSSk...",
		"...kSDDSk...",
		"..kSSSSSSk..",
		"..kkkkkkkk..",
		], {"k": "ink", "H": "st3", "S": "st2", "D": "st1"})
	L.P(im, 2, 5, "ink"); L.P(im, 3, 6, "st1")
	pmap(im, 9, 1, [".y.", "yWy", ".y."], {"y": "y1", "W": "white"})
	return badge16(im)

func icon_iron_chin_9() -> Image:
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		"......y..",
		".....yWy.",
		"kkkkkkky.",
		"kHHHHHHHk",
		".kSSSSSk.",
		"..kSSSk..",
		"..kSDSk..",
		".kSSSSSk.",
		".kkkkkkk."], {"k": "ink", "H": "st3", "S": "st2", "D": "st1", "y": "y1", "W": "white"})
	return im

func icon_wide_base_16() -> Image:
	var im: Image = L.blank(16, 16)
	# homenzinho de base aberta: cabeça, tronco, pernas bem abertas e os pés enterrados em 2 blocos de cimento
	pmap(im, 2, 2, [
		".....kk.....",
		"....kSSk....",
		"...kkSSkk...",
		"...kTTTTk...",
		"...kTTTTk...",
		"...kBBBBk...",
		"..kBBkkBBk..",
		".kBBk..kBBk.",
		"kCCCk..kCCCk",
		"kCcCk..kCcCk",
		"kkkkk..kkkkk",
		], {"k": "ink", "S": "sk1", "T": "st2", "B": "b1", "C": "g2", "c": "g1"})
	return badge16(im)

func icon_wide_base_9() -> Image:
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		"...kkk...",
		"...kSk...",
		"..kTTTk..",
		"..kBBBk..",
		".kBkkkBk.",
		"kBk...kBk",
		"kCCk.kCCk",
		"kCCk.kCCk",
		"kkkk.kkkk"], {"k": "ink", "S": "sk1", "T": "st2", "B": "b1", "C": "g2"})
	return im

func icon_slippery_16() -> Image:
	var im: Image = L.blank(16, 16)
	# sabão (barra azul-clara com brilho) e bolhas subindo
	pmap(im, 2, 7, [
		".kkkkkkkk.",
		"kWHHHHHHBk",
		"kHHHHHHBBk",
		"kBBBBBBBDk",
		".kkkkkkkk.",
		], {"k": "ink", "W": "white", "H": "b3", "B": "b2", "D": "b1"})
	L.ring(im, 11.5, 4.5, 2.5, 2.5, 1.0, "b3"); L.P(im, 11, 3, "white")
	L.ring(im, 6.5, 3.5, 1.5, 1.5, 1.0, "b3")
	L.P(im, 13, 9, "white")
	return badge16(ol_keep(im))

func ol_keep(src: Image) -> Image:
	return src

func icon_slippery_9() -> Image:
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		"......W..",
		".W...W.W.",
		"W.W...W..",
		".W.......",
		".kkkkkkk.",
		"kWHHHHHBk",
		"kHHHHHBBk",
		"kBBBBBBDk",
		".kkkkkkk."], {"k": "ink", "W": "b3", "H": "b3", "B": "b2", "D": "b1"})
	L.P(im, 1, 5, "white")
	return im

func icon_blindado_16(open: bool) -> Image:
	var im: Image = L.blank(16, 16)
	if not open:
		# chapa de aço fechada (escudo) com 4 rebites e a faixa vermelha do meio
		pmap(im, 3, 2, [
			"kkkkkkkkkk",
			"kHHHHHHHSk",
			"kHrSSSSrSk",
			"kHSSRRSSSk",
			"kHSSRRSSSk",
			"kHSSRRSSDk",
			"kHSSRRSSDk",
			".kSrRRrDk.",
			"..kSSSDk..",
			"...kkkk...",
			], {"k": "ink", "H": "st3", "S": "st2", "D": "st1", "r": "white", "R": "r1"})
	else:
		# a guarda abriu: as duas metades da chapa afastadas, cinza apagado
		pmap(im, 1, 3, [
			"kkkkk....kkkkk",
			"kHHSk....kHSSk",
			"kHSSk....kSSDk",
			"kHSSk....kSSDk",
			"kHSSk....kSSDk",
			".kSSk....kSDk.",
			"..kSk....kDk..",
			"...kk....kk...",
			], {"k": "ink", "H": "g2", "S": "g1", "D": "g0"})
		pmap(im, 6, 4, ["y.y.", ".y..", "y.y."], {"y": "y1"})
	return badge16(im)

func icon_blindado_9(open: bool) -> Image:
	var im: Image = L.blank(9, 9)
	if not open:
		pmap(im, 0, 0, [
			"kkkkkkkkk",
			"kHHHHHHSk",
			"kHrSRSrSk",
			"kHSSRSSSk",
			"kHSSRSSDk",
			".kSSRSDk.",
			"..kSRDk..",
			"...kSk...",
			"....k...."], {"k": "ink", "H": "st3", "S": "st2", "D": "st1", "r": "white", "R": "r1"})
	else:
		pmap(im, 0, 0, [
			"kkkk.kkkk",
			"kHSk.kSDk",
			"kHSk.kSDk",
			"kHSk.kSDk",
			".kSk.kDk.",
			"..kk.kk..",
			".........",
			"...y.y...",
			"....y...."], {"k": "ink", "H": "g2", "S": "g1", "D": "g0", "y": "y1"})
	return im

func make_passive_icons() -> void:
	var defs := [["adv_iron_chin", icon_iron_chin_16(), icon_iron_chin_9()],
		["adv_wide_base", icon_wide_base_16(), icon_wide_base_9()],
		["adv_slippery", icon_slippery_16(), icon_slippery_9()],
		["adv_blindado", icon_blindado_16(false), icon_blindado_9(false)],
		["adv_blindado_open", icon_blindado_16(true), icon_blindado_9(true)]]
	for d in defs:
		var id: String = d[0]
		save_sheet(id, "ui/%s.png" % id, [d[1]], 0.0, Vector2i.ZERO)
		save_sheet(id + "_9", "ui/%s_9.png" % id, [d[2]], 0.0, Vector2i.ZERO)

# ================================================================== sinais (letreiros pequenos, família do PERNA CHEIA!)
## Sinal do ADVERSÁRIO (a passiva dele segurou): letra branca/aço com sombra vermelha r1 (o lado dele). Não é ouro: ouro é
## conquista sua. "A GUARDA ABRIU" é boa notícia para você: ouro com sombra aço (st0).
func banner_small(txt: String, top: String, bottom: String, shadow: String) -> Image:
	var sc := 2
	var hh := 28
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

func make_banners() -> void:
	for d in [["ui_banner_opp_iron_chin", TXT_IRON_CHIN, "white", "st3", "r1"],
			["ui_banner_opp_wide_base", TXT_WIDE_BASE, "white", "st3", "r1"],
			["ui_banner_opp_slippery", TXT_SLIPPERY, "white", "st3", "r1"],
			["ui_banner_guard_closed", TXT_GUARD_CLOSED, "white", "st3", "r1"],
			["ui_banner_guard_open", TXT_GUARD_OPEN, "y1", "y0", "st0"]]:
		var b := banner_small(d[1], d[2], d[3], d[4])
		save_sheet(d[0], "ui/%s.png" % d[0], [b], 0.0, Vector2i(b.get_width() / 2, 14))

# ================================================================== fx: golpe batendo na guarda fechada
func make_fx() -> void:
	## "tilinta no braço": estrela de aço pequena e seca (o fx_block de sempre é de pano). 15x15, 3 quadros a 18 fps, pivô no meio.
	var frames := []
	for f in 3:
		var im: Image = L.blank(15, 15)
		match f:
			0:
				pmap(im, 4, 4, ["...W...", "...W...", "..WSW..", "WWSWSWW", "..WSW..", "...W...", "...W..."], {"W": "white", "S": "st3"})
			1:
				pmap(im, 1, 1, [
					"W.....S.....W",
					".W....S....W.",
					"..S...W...S..",
					"......W......",
					"....SWWWS....",
					"......W......",
					"SSWWW...WWWSS",
					"......W......",
					"....SWWWS....",
					"......W......",
					"..S...W...S..",
					".W....S....W.",
					"W.....S.....W"], {"W": "white", "S": "st2"})
			2:
				pmap(im, 1, 1, [
					"S...........S",
					".............",
					"......S......",
					".............",
					".....S.S.....",
					".............",
					"S.S.......S.S",
					".............",
					".....S.S.....",
					".............",
					"......S......",
					".............",
					"S...........S"], {"S": "st1"})
		frames.append(im)
	save_sheet("fx_guard_clink", "fight/fx_guard_clink.png", frames, 18.0, Vector2i(7, 7))

# ================================================================== Cinturão do Vale
## Degrau acima do amador (pano vermelho + caixinha de ouro): couro PRETO com costura, placa central grande de ouro com
## esmalte azul (o vale entre dois morros) e VALE escrito, 2 placas laterais de cada lado. Brilho correndo na placa (loop).
const GOLD := ["br2", "y0", "y1", "y2"]

func belt_strap(im: Image, x0: int, x1: int, cy: int, h: int) -> void:
	L.R(im, x0, cy - h / 2 - 1, x1 - x0, h + 2, "ink")
	L.R(im, x0, cy - h / 2, x1 - x0, h, "d1")
	L.R(im, x0, cy - h / 2, x1 - x0, 1, "d2")
	L.R(im, x0, cy + h / 2 - 1, x1 - x0, 1, "ink")
	for x in range(x0 + 1, x1 - 1, 3):                 # costura
		L.P(im, x, cy - h / 2 + 2, "g0")
		L.P(im, x, cy + h / 2 - 3, "g0")

func side_plate(im: Image, cx: int, cy: int, w: int, h: int, mark: String) -> void:
	L.R(im, cx - w / 2 - 1, cy - h / 2 - 1, w + 2, h + 2, "ink")
	L.R(im, cx - w / 2, cy - h / 2, w, h, GOLD[1])
	L.R(im, cx - w / 2, cy - h / 2, w, 1, GOLD[2])
	L.R(im, cx - w / 2, cy - h / 2, 1, h, GOLD[2])
	L.R(im, cx - w / 2, cy + h / 2 - 1, w, 1, GOLD[0])
	L.R(im, cx + w / 2 - 1, cy - h / 2, 1, h, GOLD[0])
	L.R(im, cx - w / 2 + 2, cy - h / 2 + 2, w - 4, h - 4, "b1")
	match mark:
		"glove":
			L.ellipse(im, cx + 0.5, cy - 0.5, 2.5, 2.5, "r2"); L.R(im, cx - 1, cy + 2, 3, 2, "cream")
		"star":
			pmap(im, cx - 2, cy - 2, ["..y..", ".yyy.", "yyyyy", ".y.y.", "....."], {"y": GOLD[2]})

func center_plate(im: Image, cx: int, cy: int, w: int, h: int, small := false) -> void:
	## octógono de ouro com esmalte azul: dois morros e o vale no meio, VALE embaixo
	var cut := 5 if not small else 3
	for y in range(-h / 2 - 1, h / 2 + 2):
		for x in range(-w / 2 - 1, w / 2 + 2):
			var ax := absi(x)
			var ay := absi(y)
			var lim := w / 2 + h / 2 - cut
			if ax <= w / 2 + 1 and ay <= h / 2 + 1 and ax + ay <= lim + 1:
				var inside := ax <= w / 2 and ay <= h / 2 and ax + ay <= lim
				var c := "ink"
				if inside:
					c = GOLD[1]
					if y < -h / 2 + 2 or (x < -w / 2 + 2):
						c = GOLD[2]
					elif y > h / 2 - 2 or x > w / 2 - 2:
						c = GOLD[0]
				L.P(im, cx + x, cy + y, c)
	# esmalte
	var ew := w - 10 if not small else w - 6
	var eh := h - 12 if not small else h - 6
	L.R(im, cx - ew / 2 - 1, cy - eh / 2 - 1, ew + 2, eh + 2, GOLD[0])
	L.R(im, cx - ew / 2, cy - eh / 2, ew, eh, "b1")
	L.R(im, cx - ew / 2, cy - eh / 2, ew, 2, "b2")
	if not small:
		# dois morros verdes e o vale; sol de ouro no meio
		for x in range(-ew / 2, ew / 2):
			var hl := int(eh * 0.55 - absf(absf(x) - ew * 0.28) * 0.7)
			for y in range(maxi(hl, 0)):
				L.P(im, cx + x, cy + eh / 2 - 1 - y - 6, "gr1" if y < hl - 1 else "gr2")
		L.ellipse(im, cx + 0.5, cy - 2.5, 2.5, 2.5, GOLD[2])
		L.R(im, cx - ew / 2, cy + eh / 2 - 7, ew, 7, "b0")
		L.text_center(im, TXT_BELT, cx + 1, cy + eh / 2 - 7, GOLD[2], 1)
	else:
		L.R(im, cx - ew / 2, cy + 1, ew, eh / 2, "gr1")
		L.P(im, cx, cy - 1, GOLD[2])

func glint(im: Image, cx: int, cy: int, w: int, h: int, f: int) -> void:
	## brilho diagonal correndo na placa (quadro 0 parado; 1 e 2 o brilho passa)
	if f == 0:
		return
	var off := -10 if f == 1 else 8
	for y in range(cy - h / 2, cy + h / 2 + 1):
		for x in range(cx - w / 2, cx + w / 2 + 1):
			var c := im.get_pixel(x, y)
			if c.a == 0.0 or c.is_equal_approx(L.C.ink):
				continue
			var d := (x - cx) + (y - cy) - off
			if d >= 0 and d <= 2:
				im.set_pixel(x, y, L.C.white if d == 1 else L.col(GOLD[3]))

func belt_big(f: int) -> Image:
	var w := 120
	var h := 52
	var im: Image = L.blank(w, h)
	var cy := 26
	belt_strap(im, 1, w - 1, cy, 18)
	# pontas com furos (esquerda) e passador (direita)
	for x in [6, 11, 16]:
		L.P(im, x, cy, "ink")
	L.R(im, w - 12, cy - 9, 4, 18, "ink"); L.R(im, w - 11, cy - 8, 2, 16, "g1")
	for pl in [[22, "star"], [37, "glove"], [83, "glove"], [98, "star"]]:
		side_plate(im, pl[0], cy, 12, 16, pl[1])
	center_plate(im, 60, cy, 40, 44)
	glint(im, 60, cy, 40, 44, f)
	return im

func belt_raised(f: int) -> Image:
	## Erguido acima da cabeça, em ESCALA DE CORPO (2026-11-22: a versão 80x48 cobria cabeça e tronco). 40x22.
	## A tira passa reta entre as duas luvas (linha y 15) e cai só um pouco nas pontas, para os lados; a placa (13x14) fica
	## EM CIMA das luvas, nunca na frente do rosto. Pivô (20,15) = meio das mãos; pegadas GRIP_L/GRIP_R a 10 px, a distância
	## entre hand_back e hand_front do fight_player_victory (-1,-82) e (9,-83).
	var w := 40
	var h := 22
	var im: Image = L.blank(w, h)
	var gy := 15
	for x in w:
		var dx := absi(x * 2 + 1 - w) / 2
		var d := 0 if dx <= 12 else int(round((dx - 12) * 0.75))
		var y := gy - 1 + d
		L.P(im, x, y, "ink")
		L.P(im, x, y + 1, "d2")
		L.P(im, x, y + 2, "d1")
		L.P(im, x, y + 3, "ink")
		if x % 3 == 0 and dx > 8:
			L.P(im, x, y + 1, "g0")
	# pontas cortadas (furo na esquerda, ponteira de metal na direita)
	L.P(im, 1, gy + 5, "ink"); L.R(im, w - 2, gy + 3, 2, 3, "g1")
	# plaquinhas laterais na tira
	for sx in [7, 32]:
		var dx2 := absi(sx * 2 + 1 - w) / 2
		var yy := gy - 1 + (0 if dx2 <= 12 else int(round((dx2 - 12) * 0.75)))
		L.R(im, sx - 2, yy, 5, 4, "ink"); L.R(im, sx - 1, yy + 1, 3, 2, GOLD[1]); L.P(im, sx - 1, yy + 1, GOLD[2])
	# placa central em cima das luvas
	center_plate(im, 20, 7, 12, 13, true)
	glint(im, 20, 7, 12, 13, f)
	# as luvas ficam NA FRENTE da tira: vão transparente de 4 px em cada pegada (a tela desenha o cinturão por cima do lutador)
	for g in [GRIP_L, GRIP_R]:
		for y in range(gy - 1, gy + 3):
			for x in range(g.x - 2, g.x + 2):
				im.set_pixel(x, y, Color(0, 0, 0, 0))
	return im

const GRIP_L := Vector2i(15, 15)
const GRIP_R := Vector2i(25, 15)
const RAISED_PIVOT := Vector2i(20, 15)

func icon_belt_16() -> Image:
	var im: Image = L.blank(16, 16)
	belt_strap(im, 0, 16, 9, 6)
	center_plate(im, 8, 8, 9, 11, true)
	L.R(im, 1, 8, 2, 2, GOLD[1]); L.R(im, 13, 8, 2, 2, GOLD[1])
	return im

func icon_belt_9() -> Image:
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		"...kkk...",
		"..kYYYk..",
		"kkkYbYkkk",
		"dddYbYddd",
		"dydYgYdyd",
		"kkkYOYkkk",
		"..kOOOk..",
		"...kkk...",
		"........."], {"k": "ink", "Y": GOLD[2], "O": GOLD[0], "b": "b1", "g": "gr1", "d": "d2", "y": GOLD[1]})
	return im

func make_belt() -> void:
	save_sheet("belt_regional_big", "ui/belt_regional_big.png", [belt_big(0), belt_big(1), belt_big(2)], 6.0, Vector2i(60, 26))
	save_sheet("belt_regional_raised", "fight/belt_regional_raised.png", [belt_raised(0), belt_raised(1), belt_raised(2)], 6.0, RAISED_PIVOT)
	save_sheet("icon_belt_regional", "ui/icon_belt_regional.png", [icon_belt_16()], 0.0, Vector2i.ZERO)
	save_sheet("icon_belt_regional_9", "ui/icon_belt_regional_9.png", [icon_belt_9()], 0.0, Vector2i.ZERO)

# ================================================================== cartaz da liga (academia) + zoom
const POSTER := Vector2i(38, 54)
const POSTER_SPOT := Vector2i(412, 54)     # canto de cima à esquerda, na parede da academia, em cima da porta

## Fonte 3x5 só para o cartaz em 1x (mesma ideia do recorte do vulto da 7a2).
const MINI := {
	"D": ["##.", "#.#", "#.#", "#.#", "##."], "O": ["###", "#.#", "#.#", "#.#", "###"],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."], "A": [".#.", "#.#", "###", "#.#", "#.#"],
	"L": ["#..", "#..", "#..", "#..", "###"], "E": ["###", "#..", "##.", "#..", "###"],
	"B": ["##.", "#.#", "##.", "#.#", "##."], "I": ["###", ".#.", ".#.", ".#.", "###"],
	"N": ["#.#", "###", "###", "#.#", "#.#"], "C": ["###", "#..", "#..", "#..", "###"],
	"P": ["##.", "#.#", "##.", "#..", "#.."], "M": ["#.#", "###", "#.#", "#.#", "#.#"],
	"Ã": ["###", "#.#", "###", "#.#", "#.#"], ":": ["...", ".#.", "...", ".#.", "..."],
}

func mini_text(img: Image, s: String, x: int, y: int, c) -> void:
	for i in s.length():
		if s[i] == " ":
			continue
		var g: Array = MINI[s[i]]
		for r in 5:
			for k in 3:
				if g[r][k] == "#":
					L.P(img, x + i * 4 + k, y + r, c)

func mini_w(s: String) -> int:
	return s.length() * 4 - 1

## Foto em 2 tons (impressão barata): ink nas sombras, a cor de papel nas luzes, meio-tom em dither.
func duotone(src: Image, w: int, h: int, dark: String, mid: String, light: String) -> Image:
	var im: Image = L.blank(w, h)
	for y in h:
		for x in w:
			var sx := int(float(x) * src.get_width() / w)
			var sy := int(float(y) * src.get_height() / h)
			var c := src.get_pixel(sx, sy)
			if c.a == 0.0:
				L.P(im, x, y, light)
				continue
			var lum := c.r * 0.3 + c.g * 0.55 + c.b * 0.15
			var v := lum * 1.5
			if v < 0.33:
				L.P(im, x, y, dark)
			elif v < 0.62:
				L.P(im, x, y, mid if bayer(x, y) < 0.7 else dark)
			elif v < 0.85:
				L.P(im, x, y, mid if bayer(x, y) < 0.5 else light)
			else:
				L.P(im, x, y, light)
	return im

## Busto provisório do James (até o Artista entregar o retrato): ombros largos, braços cruzados, cabelo penteado para
## trás, o cinturão no ombro. Desenhado em 2 tons, como foto impressa.
func james_placeholder(w: int, h: int) -> Image:
	var im: Image = L.blank(w, h)
	L.R(im, 0, 0, w, h, "white")
	var cx := w / 2
	var k := float(h) / 24.0
	# tronco e braços cruzados
	L.ellipse(im, cx, h + 2 * k, 13 * k, 12 * k, "d2")
	L.R(im, int(cx - 9 * k), int(h - 7 * k), int(18 * k), int(3 * k), "ink")
	# cinturão no ombro (faixa diagonal)
	for t in int(14 * k):
		L.P(im, int(cx - 8 * k) + t, int(h - 11 * k) + int(t * 0.5), "ink")
	# pescoço e cabeça
	L.R(im, int(cx - 2 * k), int(9 * k), int(4 * k), int(4 * k), "d2")
	L.ellipse(im, cx, 7.5 * k, 4.5 * k, 5.5 * k, "d2")
	L.R(im, int(cx - 4 * k), int(2 * k), int(8 * k), int(2.5 * k), "ink")
	L.P(im, int(cx - 2 * k), int(7 * k), "ink"); L.P(im, int(cx + 1.5 * k), int(7 * k), "ink")
	L.R(im, int(cx - 1.5 * k), int(10 * k), int(3 * k), 1, "ink")
	return im

func james_photo(w: int, h: int, dark: String, mid: String, light: String) -> Image:
	var p := ROOT + "assets/sprites/opponents/portrait_opp_james.png"
	if FileAccess.file_exists(p):
		var src := load_png(p)
		return duotone(src.get_region(Rect2i(0, 0, mini(src.get_width(), 32), mini(src.get_height(), 32))), w, h, dark, mid, light)
	var ph := james_placeholder(w, h)
	return duotone(ph, w, h, dark, mid, light)

func poster_small() -> Image:
	## 38x54 na parede da academia (luz fria dos tubos: papel branco). Lê em 1x: faixa vermelha com LIGA (5x7), DO VALE
	## (3x5), foto do James em 2 tons, o nome JAMES (5x7), o cinturão e fita nos cantos. O texto inteiro vai no zoom/hover.
	var w := POSTER.x
	var h := POSTER.y
	var im: Image = L.blank(w, h)
	L.R(im, 0, 1, w, h - 1, "ink")
	L.R(im, 1, 2, w - 2, h - 3, "white")
	L.R(im, 1, h - 3, w - 2, 1, "cream")
	# faixa vermelha do alto
	L.R(im, 1, 2, w - 2, 11, "r1"); L.R(im, 1, 12, w - 2, 1, "r0")
	L.text_center(im, "LIGA", w / 2, 4, "white", 1)
	mini_text(im, "DO VALE", (w - mini_w("DO VALE")) / 2, 14, "r1")
	# foto
	var ph := james_photo(30, 22, "ink", "b1", "b3")
	L.R(im, 3, 20, 32, 24, "ink")
	im.blit_rect(ph, Rect2i(0, 0, 30, 22), Vector2i(4, 21))
	# nome
	L.text_center(im, "JAMES", w / 2, 45, "ink", 1)
	# fita adesiva nos 2 cantos de cima (meio transparente)
	for p in [[0, 0], [w - 6, 0]]:
		for y in range(0, 3):
			for x in range(p[0], p[0] + 6):
				if (x + y) % 2 == 0 or y == 1:
					im.set_pixel(x, y, L.C.white)
	return im

func poster_zoom() -> Image:
	## 112x148 para a dica/janela (opcional): o cartaz grande com todas as linhas do Roteirista.
	var w := 112
	var h := 148
	var im: Image = L.blank(w, h)
	L.R(im, 0, 0, w, h, "ink")
	L.R(im, 1, 1, w - 2, h - 2, "white")
	L.R(im, 1, h - 4, w - 2, 3, "cream")
	L.R(im, 1, 1, w - 2, 24, "r1"); L.R(im, 1, 24, w - 2, 1, "r0")
	L.text_center(im, "LIGA REGIONAL", w / 2, 4, "white", 1)
	L.text_center(im, "DO VALE", w / 2, 14, "y1", 1)
	var ph := james_photo(64, 48, "ink", "b1", "b3")
	L.R(im, w / 2 - 33, 29, 66, 50, "ink")
	im.blit_rect(ph, Rect2i(0, 0, 64, 48), Vector2i(w / 2 - 32, 30))
	L.text_center(im, "CAMPEÃO:", w / 2, 85, "r1", 1)
	L.text_center(im, "JAMES BLINDADO", w / 2, 96, "ink", 1)
	L.R(im, 12, 107, w - 24, 1, "g3")
	L.text_center(im, "\"O QUE A BALA", w / 2, 111, "d2", 1)
	L.text_center(im, "NÃO FURA\"", w / 2, 121, "d2", 1)
	L.R(im, 1, 133, w - 2, 11, "d1")
	L.text_center(im, TXT_ARENA, w / 2, 135, "y1", 1)
	return im

func make_poster() -> void:
	save_sheet("wall_poster_league_regional_gym", "gym/wall_poster_league_regional_gym.png", [poster_small()], 0.0, Vector2i.ZERO)
	save_sheet("ui_poster_league_regional_zoom", "ui/ui_poster_league_regional_zoom.png", [poster_zoom()], 0.0, Vector2i.ZERO)
	# conferência: o cartaz cai só em parede lisa (creme) da academia, longe do tubo (y até 44) e da porta (y 117+)
	var gym := load_png(ROOT + "assets/sprites/gym/gym_bg.png")
	var wall := 0
	var other := 0
	for y in range(POSTER_SPOT.y - 2, POSTER_SPOT.y + POSTER.y + 2):
		for x in range(POSTER_SPOT.x - 2, POSTER_SPOT.x + POSTER.x + 2):
			var n := color_name(gym.get_pixel(x, y))
			if n in ["cream", "white", "g3", "g2"]:
				wall += 1
			else:
				other += 1
	CHECKS.append("cartaz na academia em (%d,%d) %dx%d: px de parede = %d, px de outra coisa embaixo = %d" % [POSTER_SPOT.x, POSTER_SPOT.y, POSTER.x, POSTER.y, wall, other])

# ================================================================== plaquinha do balão do James (Diretor de Cutscenes)
## Mesma peça 8x10 (9-slice 2) das outras plaquinhas, em AÇO ESCURO (st0) com texto branco: o azul é do discípulo, o cinza
## de figurante. Aço = "blindado". Gerada trocando as cores da ui_balloon_tag_gray (mesmo desenho, mesmo 9-slice).
const TAG_SWAP := {"g2": "st0", "g3": "st1", "g1": "d1", "g0": "d1", "cream": "st2", "white": "st2"}

func make_balloon_tag() -> void:
	var src := load_png(ROOT + "assets/sprites/ui/ui_balloon_tag_gray.png")
	var im: Image = src.duplicate()
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var n := color_name(c)
			if TAG_SWAP.has(n):
				im.set_pixel(x, y, L.col(TAG_SWAP[n]))
	save_sheet("ui_balloon_tag_steel", "ui/ui_balloon_tag_steel.png", [im], 0.0, Vector2i.ZERO)

# ================================================================== mockups
const PIV := Vector2i(56, 98)

func opp_sheet(pose: String, id := "opp_james") -> String:
	## a folha do adversário (Artista de Personagens) se existir; senão o Kid (opp_gym_2) como dublê
	var p := "assets/sprites/opponents/%s/%s_%s.png" % [id, id, pose]
	if FileAccess.file_exists(ROOT + p):
		return p
	return "assets/sprites/opponents/opp_gym_2/opp_gym_2_%s.png" % pose

func scene_base(crowd_f: int, front_f: int) -> Image:
	var sc: Image = ARENA.duplicate()
	sc.blend_rect(F["arena_regional_crowd_back"][crowd_f], Rect2i(0, 0, 640, 100), Vector2i(0, CROWD_Y))
	return sc

func scene_front(sc: Image, front_f: int, ropes := true) -> void:
	if ropes:
		var r: Image = F["arena_regional_ropes_side"][0]
		sc.blend_rect(r, Rect2i(Vector2i.ZERO, r.get_size()), Vector2i(0, ROPES_Y))
	sc.blend_rect(F["arena_regional_crowd_front"][front_f], Rect2i(0, 0, 640, 48), Vector2i(0, 312))

func shadow_at(sc: Image, p: Vector2i) -> void:
	var shadow := load_png(ROOT + "assets/sprites/fight/fight_shadow.png")
	sc.blend_rect(shadow, Rect2i(0, 0, 48, 8), p - Vector2i(24, 4))

func fighter_at(sc: Image, path: String, frame: int, p: Vector2i, flip: bool) -> void:
	var fr := region_of(path, frame, 112, 104)
	if flip:
		fr.flip_x()
	put(sc, fr, p, PIV)

func hud(img: Image, opp_name: String, icon_id: String, opp_id := "") -> void:
	## HUD aproximado (o de verdade é do UI/UX): o ícone da passiva dele fica colado na vida dele, do lado de dentro
	L.panel(img, 6, 6, 34, 34, "b0"); L.panel(img, 600, 6, 34, 34, "r0")
	L.text(img, "VOCÊ", 46, 6, "cream", 1)
	L.text_right(img, opp_name, 594, 6, "cream", 1)
	L.bar(img, 46, 16, 236, 12, 0.62, "gr2")
	L.bar(img, 358, 16, 236, 12, 0.48, "r2")
	L.panel(img, 292, 4, 56, 32, "d1")
	L.text_center(img, "1º", 320, 9, "g2", 1)
	L.text_center(img, "44", 320, 19, "y1", 2)
	var spr = load_png(ROOT + "assets/sprites/fight/portrait_player.png")
	img.blend_rect(spr, Rect2i(0, 0, 32, 32), Vector2i(7, 7))
	var op := ROOT + "assets/sprites/opponents/portrait_%s.png" % opp_id
	if opp_id != "" and FileAccess.file_exists(op):
		img.blend_rect(load_png(op), Rect2i(0, 0, 32, 32), Vector2i(601, 7))
	if icon_id != "":
		var ic: Image = F[icon_id + "_9"][0]
		img.blend_rect(ic, Rect2i(0, 0, 9, 9), Vector2i(346, 17))
		L.text_right(img, "AGRESSIVO", 594, 32, "r3", 1)

func mock_arena() -> void:
	var W := 8 + 2 * 648
	var H := 34 + 360 + 8
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	label(board, "FASE 8A1 - ARENA REGIONAL: CLUBE FERROVIÁRIO, À NOITE (RINGUE, FAIXA DA LIGA, TV VALE). PLACEHOLDER POR CÓDIGO", 8, 6, "y1")
	label(board, "EM PÉ: ZÉ BIGORNA SEGURA O K.O. DE EMBALO (AGUENTOU!) - ÍCONE DA PASSIVA DELE COLADO NA VIDA DELE", 8, 20, "g3")
	label(board, "NO CHÃO: JIU-JITSU, FINALIZOU! (OS DOIS DEITADOS CABEM ENTRE AS CORDAS)", 656, 20, "g3")
	var ply := "assets/sprites/fight/fight_player_"
	for panel in 2:
		var sc := scene_base(panel, panel)
		if panel == 0:
			shadow_at(sc, Vector2i(296, 318)); shadow_at(sc, Vector2i(346, 318))
			fighter_at(sc, ply + "heavy.png", 2, Vector2i(296, 318), false)
			fighter_at(sc, opp_sheet("hit_head", "opp_reg_1"), 1, Vector2i(346, 318), true)
			scene_front(sc, 1)
			hud(sc, "ZÉ BIGORNA", "adv_iron_chin", "opp_reg_1")
			var b: Image = scaled(F["ui_banner_opp_iron_chin"][0], 2)
			put(sc, b, Vector2i(346, 196), b.get_size() / 2)
		else:
			shadow_at(sc, Vector2i(284, 318)); shadow_at(sc, Vector2i(358, 318))
			fighter_at(sc, ply + "ko.png", 4, Vector2i(300, 318), true)
			fighter_at(sc, opp_sheet("ko", "opp_reg_2"), 4, Vector2i(342, 318), false)
			scene_front(sc, 0)
			hud(sc, "TIÃO ESTACA", "adv_wide_base", "opp_reg_2")
			var bn := scaled(load_png(ROOT + "assets/sprites/ui/ui_banner_submission.png"), 2)
			put(sc, bn, Vector2i(320, 118), bn.get_size() / 2)
		board.blit_rect(sc, Rect2i(0, 0, 640, 360), Vector2i(8 + panel * 648, 34))
	board.save_png(MOCK + "fase8a1_arena_regional.png")
	var solo: Image = scene_base(0, 0)
	scene_front(solo, 0)
	solo.save_png(MOCK + "fase8a1_arena_regional_vazia.png")

func mock_letreiros() -> void:
	## os letreiros de sempre (2x, em 320,118) sobre a arena nova: têm de ler no fundo escuro
	var ids := ["ui_banner_ko", "ui_banner_submission", "ui_banner_spin_kick", "ui_banner_counter_ko", "ui_banner_ground_stop", "ui_banner_knee_ko"]
	var W := 8 + 3 * 428
	var H := 24 + 2 * 150
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	label(board, "LETREIROS DAS 3 ARTES E DAS 6 PASSIVAS EM 2X (320,118) NA ARENA REGIONAL - RECORTE DO MEIO", 8, 6, "y1")
	for i in ids.size():
		var sc := scene_base(0, 0)
		var bn := scaled(load_png(ROOT + "assets/sprites/ui/%s.png" % ids[i]), 2)
		put(sc, bn, Vector2i(320, 118), bn.get_size() / 2)
		var crop := sc.get_region(Rect2i(110, 46, 420, 140))
		board.blit_rect(crop, Rect2i(0, 0, 420, 140), Vector2i(8 + (i % 3) * 428, 22 + (i / 3) * 150))
	board.save_png(MOCK + "fase8a1_letreiros_arena.png")

func hands_mid(frame: int) -> Vector2i:
	## igual à tela de luta: meio de hand_front/hand_back do fight_player_victory (manifest), relativo ao pivô
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	var hs: Array = m["sprites"]["fight_player_victory"].get("hands", [])
	if hs.is_empty():
		return Vector2i(4, -83)
	var e: Dictionary = hs[clampi(frame, 0, hs.size() - 1)]
	var a: Array = e["hand_front"]
	var b: Array = e["hand_back"]
	return Vector2i(int(floor((float(a[0]) + float(b[0])) / 2.0)), int(floor((float(a[1]) + float(b[1])) / 2.0)))

func mock_cinturao_erguido() -> void:
	## o lutador segurando: os 4 quadros da vitória com o cinturão no meio das mãos (como a tela de luta), 1x e 4x
	var W := 8 + 4 * 120
	var H := 30 + 104 + 12 + 104 * 4 + 8
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	label(board, "CINTURÃO ERGUIDO 40X22 NAS LUVAS DA VITÓRIA (1X E 2X); PIVÔ NO MEIO DE HAND_FRONT/HAND_BACK, COMO A TELA DE LUTA", 8, 6, "y1")
	var ply := "assets/sprites/fight/fight_player_victory.png"
	for i in 4:
		var cell: Image = L.blank(112, 104)
		L.R(cell, 0, 0, 112, 104, "g1")
		put(cell, region_of(ply, i, 112, 104), PIV, PIV)
		put(cell, F["belt_regional_raised"][i % 3], PIV + hands_mid(i), RAISED_PIVOT)
		board.blit_rect(cell, Rect2i(0, 0, 112, 104), Vector2i(8 + i * 120, 22))
		label(board, "QUADRO %d" % i, 8 + i * 120, 128, "cream")
		var crop := cell.get_region(Rect2i(30, 0, 52, 40))
		put_k(board, crop, 8 + i * 120, 140, 2)
	var sc := scene_base(0, 0)
	var p := Vector2i(310, 318)
	shadow_at(sc, p)
	fighter_at(sc, ply, 1, p, false)
	put(sc, F["belt_regional_raised"][1], p + hands_mid(1), RAISED_PIVOT)
	scene_front(sc, 0)
	put_k(board, sc.get_region(Rect2i(250, 200, 120, 130)), 8, 230, 2)
	label(board, "NA ARENA (2X)", 8, 222, "cream")
	board.save_png(MOCK + "fase8a1_cinturao_erguido.png")

func top_of_fists(path: String, frame: int) -> Vector2i:
	## ponto mais alto opaco do quadro (as luvas na vitória), relativo ao pivô
	var fr := region_of(path, frame, 112, 104)
	for y in 104:
		for x in 112:
			if fr.get_pixel(x, y).a > 0.0:
				return Vector2i(x, y) - PIV
	return Vector2i(0, -90)

func mock_entrada() -> void:
	## Entrada no ringue (animação principal do dono): 4 tempos + o cinturão erguido. As cordas laterais vêm da camada
	## arena_regional_ropes_side (por cima do lutador), então ele "passa entre as cordas" sem quadro especial de recorte.
	var W := 8 + 3 * 428
	var H := 40 + 2 * 250
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	label(board, "ENTRADA NO RINGUE (SUGESTÃO DE TEMPOS) E CINTURÃO DO VALE ERGUIDO. CORDAS DA FRENTE = CAMADA ROPES_SIDE POR CIMA DO LUTADOR", 8, 6, "y1")
	var ply := "assets/sprites/fight/fight_player_"
	var steps := [
		["1. ENTRA PELA TORCIDA (X -30 -> 90), LUZ SEGUE", ply + "idle.png", 0, Vector2i(80, 318), true],
		["2. PASSA ENTRE AS CORDAS (X 118): POSE DO ARTISTA", ply + "dodge.png", 1, Vector2i(122, 318), true],
		["3. DENTRO: BRAÇO PARA A TORCIDA (GESTO)", ply + "victory.png", 0, Vector2i(190, 318), true],
		["4. CANTO DELE: O JAMES JÁ ESPERA EM 346", ply + "idle.png", 0, Vector2i(296, 318), false],
	]
	for i in 6:
		var x := 8 + (i % 3) * 428
		var y := 40 + (i / 3) * 250
		var sc := scene_base(i % 2, i % 2)
		var txt := ""
		if i < 4:
			var s: Array = steps[i]
			txt = s[0]
			var spot: Image = F["arena_regional_spot"][i % 2]
			put(sc, spot, s[3], Vector2i(48, 258))
			shadow_at(sc, s[3])
			fighter_at(sc, s[1], s[2], s[3], false)
			if i == 3:
				shadow_at(sc, Vector2i(346, 318))
				fighter_at(sc, opp_sheet("scorn"), 0, Vector2i(346, 318), true)
		elif i == 4:
			txt = "5. CINTURÃO ERGUIDO (VITÓRIA + BELT_REGIONAL_RAISED)"
			var p := Vector2i(310, 318)
			var spot: Image = F["arena_regional_spot"][0]
			put(sc, spot, p, Vector2i(48, 258))
			shadow_at(sc, p)
			fighter_at(sc, ply + "victory.png", 1, p, false)
			put(sc, F["belt_regional_raised"][1], p + hands_mid(1), RAISED_PIVOT)
		else:
			txt = "6. SÓ AS CAMADAS: FUNDO + PÚBLICO (SEM CORDAS DA FRENTE)"
		scene_front(sc, i % 2, i != 5)
		var crop := sc.get_region(Rect2i(0, 110, 420, 230))
		board.blit_rect(crop, Rect2i(0, 0, 420, 230), Vector2i(x, y + 14))
		label(board, txt, x, y, "cream")
	board.save_png(MOCK + "fase8a1_entrada_cinturao.png")

func mock_pecas() -> void:
	var W := 700
	var H := 600
	var b: Image = L.blank(W, H)
	L.R(b, 0, 0, W, H, "d1")
	label(b, "FASE 8A1 - PEÇAS (4X). PLACEHOLDER GERADO POR CÓDIGO", 8, 6, "y1")
	var y := 24
	label(b, "PASSIVAS DOS ADVERSÁRIOS: 16 / 9 (BORDA VERMELHA = DELE)", 8, y, "cream")
	y += 14
	var x := 8
	for id in ["adv_iron_chin", "adv_wide_base", "adv_slippery", "adv_blindado", "adv_blindado_open"]:
		put_k(b, F[id][0], x, y, 4)
		put_k(b, F[id + "_9"][0], x + 70, y + 14, 4)
		label(b, id.replace("adv_", "").to_upper(), x, y + 70, "g3")
		x += 136
	y += 88
	label(b, "SINAIS (1X; NO JOGO 2X SOBRE A CABEÇA DELE) E FX DA GUARDA (4X)", 8, y, "cream")
	y += 14
	x = 8
	for id in ["ui_banner_opp_iron_chin", "ui_banner_opp_wide_base", "ui_banner_opp_slippery", "ui_banner_guard_closed", "ui_banner_guard_open"]:
		var im: Image = F[id][0]
		b.blend_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(x, y))
		x += im.get_width() + 8
		if x > 520:
			x = 8
			y += 32
	y += 34
	for i in 3:
		put_k(b, F["fx_guard_clink"][i], 8 + i * 70, y, 4)
	y += 70
	label(b, "CINTURÃO DO VALE: GRANDE (3 QUADROS, 2X) / ERGUIDO (2X) / ÍCONES 16 E 9 (4X)", 8, y, "cream")
	y += 14
	put_k(b, F["belt_regional_big"][0], 8, y, 2)
	put_k(b, F["belt_regional_big"][1], 256, y, 2)
	var amador := load_png(ROOT + "assets/sprites/ui/belt_amateur_big.png").get_region(Rect2i(0, 0, 112, 48))
	label(b, "AMADOR (2X), PARA COMPARAR", 504, y - 2, "g2")
	put_k(b, amador, 480, y + 10, 2)
	y += 112
	put_k(b, F["belt_regional_raised"][0], 8, y, 2)
	put_k(b, F["belt_regional_raised"][2], 180, y, 2)
	put_k(b, F["icon_belt_regional"][0], 360, y, 4)
	put_k(b, F["icon_belt_regional_9"][0], 440, y + 14, 4)
	put_k(b, load_png(ROOT + "assets/sprites/ui/icon_belt_amateur.png"), 500, y, 4)
	label(b, "AMADOR 16", 500, y + 70, "g2")
	b.save_png(MOCK + "fase8a1_pecas_x4.png")

func mock_cartaz() -> void:
	## academia com o cartaz no ponto (2x) + o cartaz em 4x + o zoom
	var gym := load_png(ROOT + "assets/sprites/gym/gym_bg.png")
	gym.blend_rect(F["wall_poster_league_regional_gym"][0], Rect2i(Vector2i.ZERO, POSTER), POSTER_SPOT)
	var crop := gym.get_region(Rect2i(160, 18, 330, 220))
	var W := 8 + 660 + 12 + 160 + 12 + 112 * 2 + 8
	var H := 30 + 440 + 8
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	label(board, "CARTAZ DA LIGA NA ACADEMIA (2X), EM CIMA DA PORTA, A PARTIR DA ABERTURA DA LIGA. AO LADO: 4X E O ZOOM (2X)", 8, 6, "y1")
	put_k(board, crop, 8, 26, 2)
	put_k(board, F["wall_poster_league_regional_gym"][0], 8 + 660 + 12, 26, 4)
	put_k(board, F["ui_poster_league_regional_zoom"][0], 8 + 660 + 12 + 160 + 12, 26, 2)
	board.save_png(MOCK + "fase8a1_cartaz_academia.png")
