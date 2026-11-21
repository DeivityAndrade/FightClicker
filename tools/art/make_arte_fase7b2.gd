extends SceneTree
## Fase 7b2 (Diretor de Arte): 2ª passiva das 3 artes. PLACEHOLDER gerado por código, tudo original.
##   godot --headless --path <worktree> --script res://tools/art/make_arte_fase7b2.gd              (sprites + mockups)
##   godot --headless --path <worktree> --script res://tools/art/make_arte_fase7b2.gd -- --no-assets  (só mockups)
## Depois: python tools/art/manifest_7b2.py (lê tools/art/fase7b2_sprites.json, que este script grava).
## Grava em assets/sprites/ui/:
##   ui_passive_lock (cadeado da 2ª opção, 3 quadros), ui_passive_progress_bar|fill|tick (barra da meta {n}/3),
##   ui_passive_goal_pip (bolinha da meta, 3 quadros), passive_counter_punch|top_control|thai_clinch (16, _9, _locked),
##   ui_charge_pip (carga 0–3 do Contragolpista, 4 quadros), icon_charge,
##   ui_banner_counter_ko, ui_banner_ground_stop, ui_banner_knee_ko (letreiros grandes, família do K.O.!),
##   ui_banner_charge_full, ui_banner_stood_up, ui_banner_clinch (letreiros pequenos, família do PERNA CHEIA!)
##   docs/arte/mockups/fase7b2_*.png
## Textos = Roteirista (docs/fases/fase7b2-textos.md). Se mudarem: trocar as constantes abaixo e rodar de novo.
## Letreiro grande largo demais (> MAX_1LINE px em 1x, ou seja > 600 px em 2x) quebra sozinho em 2 linhas no espaço mais perto do meio.

const TXT_COUNTER_KO := "K.O. NO CONTRAGOLPE!"   # fight_counter_ko
const TXT_GROUND_STOP := "O JUIZ PAROU!"         # fight_ground_stop
const TXT_KNEE_KO := "JOELHADA!"                 # fight_knee_ko
const TXT_CHARGE_FULL := "CARGA!"                # fight_charge_full
const TXT_STOOD_UP := "LEVANTOU"                 # fight_stood_up
const TXT_CLINCH := "CLINCH!"                    # fight_clinch
const MAX_1LINE := 300

var ROOT := ""
var OUT := ""
var MOCK := ""
var NO_ASSETS := false
var L
var F := {}      # id -> Array[Image]
var META := {}   # id -> {rel, frame_size, frames, fps, pivot}

const LOCK_GOLD := ["br2", "y0", "y1"]
const LOCK_GRAY := ["g0", "g1", "g2"]
const LOCK_FLASH := ["y1", "y2", "white"]

func _init() -> void:
	ROOT = ProjectSettings.globalize_path("res://")
	if not ROOT.ends_with("/"):
		ROOT += "/"
	OUT = ROOT + "assets/sprites/"
	MOCK = ROOT + "docs/arte/mockups/"
	NO_ASSETS = OS.get_cmdline_user_args().has("--no-assets")
	L = load("res://tools/art/pixel_lib.gd").new()
	make_card_pieces()
	make_passive_icons()
	make_charge()
	make_banners()
	if not NO_ASSETS:
		var f := FileAccess.open(ROOT + "tools/art/fase7b2_sprites.json", FileAccess.WRITE)
		f.store_string(JSON.stringify(META, "\t", true))
		f.close()
	mock_pieces()
	mock_banners()
	mock_card()
	print("7b2: ", META.size(), " sprites", " (não gravados)" if NO_ASSETS else "", "; mockups em ", MOCK)
	quit()

# ================================================================== util (iguais aos da 7b1)
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
	var s := scaled(src, k)
	dst.blend_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(x, y))

func scaled(src: Image, k: int) -> Image:
	var s: Image = src.duplicate()
	s.resize(src.get_width() * k, src.get_height() * k, Image.INTERPOLATE_NEAREST)
	return s

func label(img: Image, s: String, x: int, y: int, c := "white") -> void:
	L.text(img, s, x, y, c, 1, "ink")

# ================================================================== cartão: cadeado + meta {n}/3
## Cadeado da 2ª opção (9x12, pivô no meio). 0 trancado (cinza), 1 clarão (1 quadro, ao bater a meta), 2 aberto (ouro, arco
## levantado e a perna direita fora do corpo). Depois do 2, o UI/UX some com ele (fade) e a opção acende.
func lock_frame(state: int) -> Image:
	var im: Image = L.blank(9, 12)
	match state:
		0: padlock(im, 1, 2, LOCK_GRAY)
		1: padlock(im, 1, 1, LOCK_FLASH, "white")
		2:
			var body := LOCK_GOLD
			pmap(im, 1, 0, [
				"..kkk..",
				".kssskk",
				".ks.sk.",
				".ks.sk.",
				".ks.kk.",
				".ks....",
				"kkkkkkk",
				"khhhhbk",
				"kbbkbbk",
				"kbbkbdk",
				"kdddddk",
				"kkkkkkk"], {"k": "ink", "s": "y1", "h": body[2], "b": body[1], "d": body[0]})
	return im

func progress_bar() -> Image:
	# moldura 9-slice 8x6 (mesma medida da ui_grip_bar): contorno ink, fundo d1, borda d2 em cima
	var im: Image = L.blank(8, 6)
	L.R(im, 0, 0, 8, 6, "ink")
	L.R(im, 1, 1, 6, 4, "d1")
	L.R(im, 1, 1, 6, 1, "d2")
	return im

func progress_fill(full: bool) -> Image:
	# 4x4 repetido na horizontal dentro da moldura (área interna 4 px de altura)
	var im: Image = L.blank(4, 4)
	if full:
		L.R(im, 0, 0, 4, 4, "y1"); L.R(im, 0, 0, 4, 1, "y2"); L.R(im, 0, 3, 4, 1, "y0")
	else:
		L.R(im, 0, 0, 4, 4, "y0"); L.R(im, 0, 0, 4, 1, "y1"); L.R(im, 0, 3, 4, 1, "br2")
	return im

func goal_pip(state: int) -> Image:
	# estrelinha da meta (1 por vitória pela 1ª): 0 falta, 1 feita (ouro), 2 acendendo (clarão de 1 quadro)
	var leg := {}
	match state:
		0: leg = {"k": "ink", "x": "d2", "h": "g0"}
		1: leg = {"k": "ink", "x": "y0", "h": "y1"}
		2: leg = {"k": "y1", "x": "white", "h": "white"}
	var im: Image = L.blank(7, 7)
	pmap(im, 0, 0, [
		"...k...",
		"..kxk..",
		"kkxhxkk",
		"kxxhxxk",
		".kxxxk.",
		".kxkxk.",
		".kk.kk."], leg)
	return im

func make_card_pieces() -> void:
	save_sheet("ui_passive_lock", "ui/ui_passive_lock.png", [lock_frame(0), lock_frame(1), lock_frame(2)], 0.0, Vector2i(4, 6))
	save_sheet("ui_passive_progress_bar", "ui/ui_passive_progress_bar.png", [progress_bar()], 0.0, Vector2i.ZERO)
	save_sheet("ui_passive_progress_fill", "ui/ui_passive_progress_fill.png", [progress_fill(false), progress_fill(true)], 0.0, Vector2i.ZERO)
	var t: Image = L.blank(1, 4)
	L.R(t, 0, 0, 1, 4, "ink")
	save_sheet("ui_passive_progress_tick", "ui/ui_passive_progress_tick.png", [t], 0.0, Vector2i.ZERO)
	save_sheet("ui_passive_goal_pip", "ui/ui_passive_goal_pip.png", [goal_pip(0), goal_pip(1), goal_pip(2)], 0.0, Vector2i(3, 3))

# ================================================================== ícones das 2ªs passivas
## Regra: cada ícone mostra o que se VÊ na luta (§11.2), para não confundir com o da 1ª (bolinha de embalo, mão na gola, canela
## marcada). Boxe = luva em guarda alta + seta que volta (vermelho); Jiu-jitsu = seta azul pressionando quem está deitado no
## tatame; Muay Thai = braços fechando atrás da cabeça dele (faixa laranja no pulso) com o joelho subindo.

func passive_counter_16() -> Image:
	var im: Image = L.blank(16, 16)
	# luva em guarda alta (vertical), punho creme embaixo
	L.ellipse(im, 6.0, 5.5, 4.0, 4.5, "r1")
	L.ellipse(im, 5.2, 4.6, 2.6, 3.0, "r2")
	L.P(im, 4, 3, "r3"); L.P(im, 5, 3, "r3"); L.P(im, 4, 4, "r3")
	L.ellipse(im, 9.4, 7.6, 1.4, 2.0, "r1")      # polegar
	L.P(im, 9, 7, "r2")
	L.R(im, 3, 10, 7, 3, "cream"); L.R(im, 3, 12, 7, 1, "g3")
	# seta em L: desce e volta para a frente (esquiva e contragolpe)
	pmap(im, 9, 9, [
		"y.....",
		"y..y..",
		"y..yy.",
		"yyyyyy",
		"oooyo.",
		"...o..",
		], {"y": "y1", "o": "y0"})
	return ol(im)

func passive_counter_9() -> Image:
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		".kkkk....",
		"kRhRRk...",
		"kRRRRk...",
		"kRRRRk...",
		".kRRk.y..",
		".kcck.yy.",
		".kcck.yyy",
		".kkkk.yo.",
		"........."], {"k": "ink", "R": "r1", "h": "r3", "c": "cream", "y": "y1", "o": "y0"})
	# luva com brilho: a coluna da frente mais clara
	for p in [[2, 2], [2, 3], [3, 2]]:
		L.P(im, p[0], p[1], "r2")
	return im

func passive_top_16() -> Image:
	var im: Image = L.blank(16, 16)
	# tatame azul embaixo
	L.R(im, 1, 13, 14, 2, "b1"); L.R(im, 1, 13, 14, 1, "b2")
	# ele deitado de costas: cabeça à esquerda, quimono creme
	L.ellipse(im, 3.5, 10.5, 1.8, 1.8, "sk1")
	L.P(im, 3, 9, "sk2")
	L.R(im, 5, 10, 9, 3, "cream"); L.R(im, 5, 12, 9, 1, "g3"); L.R(im, 9, 10, 1, 3, "b0")   # faixa
	# seta grossa pressionando de cima (por cima)
	pmap(im, 4, 1, [
		"..bbbb..",
		"..bBBb..",
		"..bBBb..",
		"bbbBBbbb",
		".bBBBBb.",
		"..bBBb..",
		"...bb...",
		], {"b": "b2", "B": "b3"})
	return ol(im)

func passive_top_9() -> Image:
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		"..kkkkk..",
		"..kBbk...",
		"kkkBbkkk.",
		".kBBBbk..",
		"..kBbk...",
		"kk.kk....",
		"ksskcbcck",
		"kkkkkkkkk",
		"MMMMMMMMM"], {"k": "ink", "B": "b3", "b": "b2", "s": "sk1", "c": "cream", "M": "b1"})
	L.P(im, 2, 0, "ink"); L.P(im, 6, 0, "ink")
	return im

func passive_clinch_16() -> Image:
	var im: Image = L.blank(16, 16)
	# cabeça dele (de frente): cabelo escuro em cima, rosto pele
	L.ellipse(im, 8.0, 8.6, 2.6, 3.0, "sk1")
	L.R(im, 6, 6, 5, 2, "d2"); L.P(im, 7, 9, "sk0"); L.P(im, 9, 9, "sk0")
	# os dois antebraços (2 px) subindo dos cantos e fechando atrás da nuca; mãos entrelaçadas em cima
	for side: int in [-1, 1]:
		for t in 11:
			var x: int = 8 + side * (7 - int(round(t * 0.45)))
			var y: int = 15 - t
			L.R(im, x - 1 if side < 0 else x, y, 2, 1, "sk1")
			L.P(im, x if side < 0 else x + 1, y, "sk0")
		var wx: int = 8 + side * 5
		L.R(im, wx - 1 if side < 0 else wx, 9, 2, 2, "br3")   # faixa laranja no pulso
	L.R(im, 5, 3, 6, 2, "sk2"); L.P(im, 7, 3, "sk1"); L.P(im, 9, 4, "sk1")
	# joelho subindo (seta curta ouro embaixo do queixo)
	pmap(im, 7, 12, [".y.", "yyy", ".o."], {"y": "y1", "o": "y0"})
	return ol(im)

func passive_clinch_9() -> Image:
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		"..kSSSk..",
		".ks.k.sk.",
		"ks.kkk.sk",
		"ks.kHk.sk",
		"ka.kHk.ak",
		"ks..k..sk",
		"ks..y..sk",
		"ks.yyy.sk",
		"kk..o..kk"], {"k": "ink", "S": "sk2", "s": "sk1", "H": "sk1", "a": "br3", "y": "y1", "o": "y0"})
	return im

func locked_icon(src: Image) -> Image:
	var img: Image = grayed(src)
	L.R(img, 8, 6, 8, 10, Color(0, 0, 0, 0))
	padlock(img, 9, 6, LOCK_GRAY)
	return img

func make_passive_icons() -> void:
	var defs := [["counter_punch", passive_counter_16(), passive_counter_9()],
		["top_control", passive_top_16(), passive_top_9()],
		["thai_clinch", passive_clinch_16(), passive_clinch_9()]]
	for d in defs:
		var id := "passive_" + str(d[0])
		save_sheet(id, "ui/%s.png" % id, [d[1]], 0.0, Vector2i.ZERO)
		save_sheet(id + "_9", "ui/%s_9.png" % id, [d[2]], 0.0, Vector2i.ZERO)
		save_sheet(id + "_locked", "ui/%s_locked.png" % id, [locked_icon(d[1])], 0.0, Vector2i.ZERO)

# ================================================================== carga do Contragolpista
## Losango 9x9 (o embalo da 1ª é bolinha redonda 7x7; forma diferente para ler sem depender de cor). 3 com passo 11 px.
## 0 vazia, 1 carregada (miolo ouro, borda vermelha do Boxe), 2 acendendo (clarão 1 quadro), 3 cheia (piscar 1/3 com CARGA!).
func charge_pip(state: int) -> Image:
	var leg := {}
	match state:
		0: leg = {"k": "ink", "X": "d2", "x": "d1", "h": "d2"}
		1: leg = {"k": "ink", "X": "r2", "x": "y0", "h": "y2"}
		2: leg = {"k": "y1", "X": "white", "x": "y2", "h": "white"}
		3: leg = {"k": "r2", "X": "y1", "x": "y1", "h": "white"}
	var im: Image = L.blank(9, 9)
	pmap(im, 0, 0, [
		"....k....",
		"...kXk...",
		"..kXxXk..",
		".kXxhxXk.",
		"kXxhhhxXk",
		".kXxhxXk.",
		"..kXxXk..",
		"...kXk...",
		"....k...."], leg)
	return im

func make_charge() -> void:
	save_sheet("ui_charge_pip", "ui/ui_charge_pip.png", [charge_pip(0), charge_pip(1), charge_pip(2), charge_pip(3)], 0.0, Vector2i(4, 4))
	save_sheet("icon_charge", "ui/icon_charge.png", [charge_pip(1)], 0.0, Vector2i.ZERO)

# ================================================================== letreiros (receita do K.O.!/FINALIZOU!/CHUTE RODADO!)
func banner_line(txt: String, sc: int, hh: int, shadow: String) -> Image:
	var kw: int = L.text_w(txt, sc) + 8
	var im: Image = L.blank(kw, hh)
	L.text(im, txt, 4, 8 + sc, shadow, sc)
	L.text(im, txt, 4, 8, "y1", sc)
	var out := ol(im)
	for y in range(8, hh - 1):
		for x in kw:
			if out.get_pixel(x, y).is_equal_approx(L.C.y1) and y >= 8 + 3 * sc:
				out.set_pixel(x, y, L.C.y0)
	return out

func split_lines(txt: String, sc: int) -> Array:
	if L.text_w(txt, sc) + 8 <= MAX_1LINE or txt.find(" ") < 0:
		return [txt]
	var best := -1
	for i in txt.length():
		if txt[i] == " " and (best < 0 or absi(i - txt.length() / 2) < absi(best - txt.length() / 2)):
			best = i
	return [txt.substr(0, best), txt.substr(best + 1)]

## Letreiro grande (fonte 3x, alto 40 por linha como o CHUTE RODADO!). 2 linhas: cada linha centrada, a 2ª sobe 8 px
## (corta o vazio de cima dela). Pivô = meio.
func banner_big(txt: String, shadow: String) -> Image:
	var lines := split_lines(txt, 3)
	if lines.size() == 1:
		return banner_line(txt, 3, 40, shadow)
	var a := banner_line(lines[0], 3, 40, shadow)
	var b := banner_line(lines[1], 3, 40, shadow)
	var w := maxi(a.get_width(), b.get_width())
	var step := 28
	var im: Image = L.blank(w, 40 + step)
	im.blend_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i((w - a.get_width()) / 2, 0))
	im.blend_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i((w - b.get_width()) / 2, step))
	return im

func make_banners() -> void:
	for d in [["ui_banner_counter_ko", TXT_COUNTER_KO, "r1"], ["ui_banner_ground_stop", TXT_GROUND_STOP, "b1"],
			["ui_banner_knee_ko", TXT_KNEE_KO, "br1"]]:
		var b := banner_big(d[1], d[2])
		save_sheet(d[0], "ui/%s.png" % d[0], [b], 0.0, Vector2i(b.get_width() / 2, b.get_height() / 2))
	for d in [["ui_banner_charge_full", TXT_CHARGE_FULL, "r1"], ["ui_banner_stood_up", TXT_STOOD_UP, "b1"],
			["ui_banner_clinch", TXT_CLINCH, "br1"]]:
		var s := banner_line(d[1], 2, 28, d[2])
		save_sheet(d[0], "ui/%s.png" % d[0], [s], 0.0, Vector2i(s.get_width() / 2, 14))

# ================================================================== mockups
func mock_pieces() -> void:
	var W := 640
	var H := 520
	var b: Image = L.blank(W, H)
	L.R(b, 0, 0, W, H, "d1")
	label(b, "FASE 7B2 - PECAS (4X). PLACEHOLDER GERADO POR CODIGO", 8, 6, "y1")
	var y := 24
	label(b, "ICONES DAS 2AS PASSIVAS: 16 / 9 / TRANCADO", 8, y, "cream")
	label(b, "COMPARAR COM A 1A: EMBALO / PEGADA / CANELA", 340, y, "cream")
	y += 14
	var x := 8
	for id in ["passive_counter_punch", "passive_top_control", "passive_thai_clinch"]:
		put_k(b, F[id][0], x, y, 4)
		put_k(b, F[id + "_9"][0], x + 70, y + 14, 4)
		put_k(b, F[id + "_locked"][0], x + 112, y, 4)
		y += 70
	var y1 := 38
	var first := [load_png(ROOT + "assets/sprites/ui/ui_streak_pip.png").get_region(Rect2i(7, 0, 7, 7)),
		load_png(ROOT + "assets/sprites/ui/icon_grip.png"), load_png(ROOT + "assets/sprites/ui/icon_shin.png")]
	for im in first:
		put_k(b, im, 360, y1 + 14, 4)
		y1 += 70
	y = 24 + 14 + 210 + 6
	label(b, "CADEADO: FECHADO / CLARAO / ABERTO", 8, y, "cream")
	for i in 3:
		put_k(b, F["ui_passive_lock"][i], 8 + i * 48, y + 14, 4)
	label(b, "META: FALTA / FEITA / ACENDE", 200, y, "cream")
	for i in 3:
		put_k(b, F["ui_passive_goal_pip"][i], 200 + i * 40, y + 20, 4)
	label(b, "CARGA: VAZIA/CARGA/ACENDE/CHEIA", 380, y, "cream")
	for i in 4:
		put_k(b, F["ui_charge_pip"][i], 380 + i * 44, y + 18, 4)
	y += 70
	label(b, "BARRA DA META (1/3 E 3/3), 1X E 4X", 8, y, "cream")
	for k in 2:
		var bar := bar_img(60, [1, 3][k], 3)
		b.blend_rect(bar, Rect2i(Vector2i.ZERO, bar.get_size()), Vector2i(8, y + 16 + k * 10))
		put_k(b, bar, 80, y + 14 + k * 28, 4)
	y += 76
	label(b, "LETREIROS PEQUENOS (1X)", 8, y, "cream")
	var xx := 8
	for id in ["ui_banner_charge_full", "ui_banner_stood_up", "ui_banner_clinch"]:
		b.blend_rect(F[id][0], Rect2i(Vector2i.ZERO, F[id][0].get_size()), Vector2i(xx, y + 12))
		xx += F[id][0].get_width() + 16
	y += 44
	label(b, "LETREIROS GRANDES (1X; NO JOGO 2X)", 8, y, "cream")
	xx = 8
	for id in ["ui_banner_counter_ko", "ui_banner_ground_stop", "ui_banner_knee_ko"]:
		b.blend_rect(F[id][0], Rect2i(Vector2i.ZERO, F[id][0].get_size()), Vector2i(xx, y + 12))
		xx += F[id][0].get_width() + 10
	b.save_png(MOCK + "fase7b2_pecas_x4.png")

## Barra montada como o UI/UX montaria: moldura 9-slice (2 px de canto) + fill repetido + ticks.
func bar_img(w: int, n: int, m: int) -> Image:
	var im: Image = L.blank(w, 6)
	L.R(im, 0, 0, w, 6, "ink")
	L.R(im, 1, 1, w - 2, 4, "d1"); L.R(im, 1, 1, w - 2, 1, "d2")
	var inner := w - 2
	var fill_w := int(round(float(inner) * float(n) / float(m)))
	var tile: Image = F["ui_passive_progress_fill"][1 if n >= m else 0]
	var xx := 1
	while xx < 1 + fill_w:
		var cw := mini(4, 1 + fill_w - xx)
		im.blit_rect(tile, Rect2i(0, 0, cw, 4), Vector2i(xx, 1))
		xx += 4
	for k in range(1, m):
		im.blit_rect(F["ui_passive_progress_tick"][0], Rect2i(0, 0, 1, 4), Vector2i(1 + inner * k / m, 1))
	return im

func mock_banners() -> void:
	var arenas := [["BORRACHARIA", "arena"], ["LIGA DA ACADEMIA", "arena_league"]]
	var ids := ["ui_banner_counter_ko", "ui_banner_ground_stop", "ui_banner_knee_ko"]
	var W := 8 + 2 * 648
	var H := 24 + 3 * 376
	var board: Image = L.blank(W, H)
	L.R(board, 0, 0, W, H, "d1")
	var ply := region_of("assets/sprites/fight/fight_player_block.png", 0, 112, 104)
	var opp := region_of("assets/sprites/opponents/opp_gym_1/opp_gym_1_idle.png", 0, 112, 104)
	var shadow := load_png(ROOT + "assets/sprites/fight/fight_shadow.png")
	for j in 3:
		for i in 2:
			var pre: String = arenas[i][1]
			var sc := load_png(ROOT + "assets/sprites/fight/%s_bg.png" % pre)
			var crowd := load_png(ROOT + "assets/sprites/fight/%s_crowd_back.png" % pre).get_region(Rect2i(0, 0, 640, 100))
			sc.blend_rect(crowd, Rect2i(0, 0, 640, 100), Vector2i(0, 180))
			for p in [Vector2i(296, 318), Vector2i(346, 318)]:
				sc.blend_rect(shadow, Rect2i(0, 0, 48, 8), p - Vector2i(24, 4))
			put(sc, ply, Vector2i(296, 318), Vector2i(56, 98))
			put(sc, opp, Vector2i(346, 318), Vector2i(56, 98))
			var front := load_png(ROOT + "assets/sprites/fight/%s_crowd_front.png" % pre).get_region(Rect2i(0, 0, 640, 48))
			sc.blend_rect(front, Rect2i(0, 0, 640, 48), Vector2i(0, 312))
			var bn: Image = scaled(F[ids[j]][0], 2)
			sc.blend_rect(bn, Rect2i(Vector2i.ZERO, bn.get_size()), Vector2i(320, 118) - bn.get_size() / 2)
			# pips de carga cheios na fileira do Contragolpista (sugestão: abaixo da sua vida, x 46, y 31)
			if j == 0:
				for k in 3:
					put(sc, F["ui_charge_pip"][3], Vector2i(50 + k * 11, 35), Vector2i(4, 4))
			var x := 8 + i * 648
			board.blit_rect(sc, Rect2i(0, 0, 640, 360), Vector2i(x, 24 + j * 376))
			label(board, "%s - %s 2X EM (320,118)" % [arenas[i][0], ids[j].to_upper()], x, 10 + j * 376, "y1")
	board.save_png(MOCK + "fase7b2_letreiros.png")

## Sugestão para o UI/UX (2x): as 2 opções no cartão da arte. Liberada = ícone colorido + nome; trancada = ícone cinza
## com cadeado, nome apagado e a meta "{n}/3 {fim}" com a barra ou as estrelas. Medidas do inside_card (174 px úteis).
func mock_card() -> void:
	var W := 3 * 196 + 8
	var H := 120
	var b: Image = L.blank(W, H)
	L.R(b, 0, 0, W, H, "d1")
	var cases := [["BOXE", "passive_counter_punch", "CONTRAGOLPISTA", "1/3 K.O. DE EMBALO", 1, "r1"],
		["JIU-JITSU", "passive_top_control", "POR CIMA", "3/3 FINALIZACOES", 3, "b1"],
		["MUAY THAI", "passive_thai_clinch", "CLINCH", "0/3 CHUTES RODADOS", 0, "br1"]]
	var first := ["MAO RAPIDA", "FINALIZACAO", "CANELA"]
	for i in 3:
		var c: Array = cases[i]
		var x := 8 + i * 196
		label(b, c[0], x, 4, "y1")
		# opção 1 (marcada)
		L.panel(b, x, 16, 186, 24, "d2", "g0")
		L.R(b, x, 16, 3, 24, c[5])
		L.text(b, first[i], x + 26, 20, "white", 1, "ink")
		L.text(b, "1A PASSIVA (MARCADA)", x + 26, 30, "g3", 1)
		var a9: Image = load_png(ROOT + "assets/sprites/ui/art_%s_9.png" % ["boxing", "bjj", "muay_thai"][i])
		put_k(b, a9, x + 8, 20, 2)
		# opção 2
		var open: bool = int(c[4]) >= 3
		L.panel(b, x, 44, 186, 40, "d1" if not open else "d2", "d2")
		var ic: Image = F[c[1]][0] if open else F[c[1] + "_locked"][0]
		b.blend_rect(ic, Rect2i(0, 0, 16, 16), Vector2i(x + 6, 48))
		L.text(b, c[2], x + 26, 50, "white" if open else "g1", 1, "ink")
		if open:
			L.text(b, "LIBERADA: PROXIMA CARREIRA", x + 26, 60, "gr3", 1)
			put(b, F["ui_passive_lock"][2], Vector2i(x + 176, 54), Vector2i(4, 6))
		else:
			L.text(b, c[3], x + 26, 60, "y1", 1)
			put(b, F["ui_passive_lock"][0], Vector2i(x + 176, 54), Vector2i(4, 6))
		var bar := bar_img(120, c[4], 3)
		b.blend_rect(bar, Rect2i(Vector2i.ZERO, bar.get_size()), Vector2i(x + 26, 72))
		for k in 3:
			put(b, F["ui_passive_goal_pip"][1 if k < c[4] else 0], Vector2i(x + 156 + k * 9, 75), Vector2i(3, 3))
		label(b, "BARRA OU ESTRELAS (UI/UX ESCOLHE)", x, 90, "g2")
	var big := scaled(b, 2)
	big.save_png(MOCK + "fase7b2_cartao_x2.png")
