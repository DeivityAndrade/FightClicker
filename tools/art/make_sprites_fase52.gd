extends SceneTree
## Fase 5.2 (Diretor de Arte) - PLACEHOLDER gerado por código.
##   assets/sprites/ui/event_golden_crew.png   Bolsa da torcida (variante da luva dourada), 22x21 x3, mesmo brilho
##   assets/sprites/ui/icon_crew_click.png     ícone da LOJA do Grito da equipe (16x16)
##   docs/arte/mockups/fase52_bolsa_x3.png     as duas luvas douradas lado a lado
## Rodar: Godot --headless --path E:/Fightclicker --script make52.gd -- [--final]
## Sem --final grava tudo em art52/out (prévia). Com --final grava no projeto e mexe no manifest
## SÓ nas chaves desta fase (relê o arquivo na hora de gravar: o Artista de Personagens edita em paralelo).

const ROOT := "E:/Fightclicker/"
const RES := "res://assets/sprites/"
var OUT := ""
var MOCK := ""
var FINAL := false
var L
var OLD := {}
var M := {}
var F := {}

# Ouro da luva dourada existente (fora da paleta de cena de propósito: é o evento que salta da sala)
const GOLD := {"o": "3b2410", "b": "fadc78", "c": "de9e1e", "d": "fff6c8", "e": "965c0c", "f": "f0eada", "g": "b0a896"}

func g(k: String) -> Color:
	return Color.html("#" + GOLD[k])

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

func put_k(dst: Image, img: Image, pos: Vector2i, k: int) -> void:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), pos)

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

func silhouette(src: Image, c: Color) -> Image:
	var o: Image = src.duplicate()
	for y in o.get_height():
		for x in o.get_width():
			if o.get_pixel(x, y).a > 0.0:
				o.set_pixel(x, y, c)
	return o

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

# ================================================================ Bolsa da torcida
## Sacola de pano dourada amarrada no gargalo: boca franzida em 3 abas EM CIMA, corpo largo EMBAIXO,
## moeda estampada no meio. É o contrário da luva (cúpula em cima,
## punho reto embaixo): de longe uma é "pera de cabeça para baixo" e a outra é "cogumelo".
func crew_bag(frame: int) -> Image:
	var W := 22
	var H := 21
	var b: Image = L.blank(W, H)
	var cx := 10.5
	# corpo
	var cy := 13.0
	var rx := 8.9
	var ry := 6.6
	for y in H:
		for x in W:
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0 and y <= 18:
				var c := "c"
				if nx > 0.6 or ny > 0.62:
					c = "e"
				elif (nx < -0.55 and ny < 0.35) or (ny < -0.62 and nx < 0.15):
					c = "b"
				L.P(b, x, y, g(c))
	# ombro do saco subindo para o gargalo
	for y in range(6, 9):
		var half := 3.0 + (y - 6) * 1.2
		for x in W:
			if absf(x + 0.5 - cx) <= half:
				var c2 := "c"
				if x + 0.5 - cx > half - 1.2:
					c2 = "e"
				elif x + 0.5 - cx < -half + 1.2:
					c2 = "b"
				L.P(b, x, y, g(c2))
	# boca franzida: 3 abas
	for y in range(1, 5):
		var w0: float = lerpf(5.6, 3.6, (y - 1) / 3.0)
		for x in W:
			var dx := x + 0.5 - cx
			if absf(dx) <= w0:
				if y == 1 and (absf(dx) > 1.0 and absf(dx) < 3.6):
					continue   # entalhes entre as abas
				var c3 := "c"
				if dx > w0 - 1.2:
					c3 = "e"
				elif dx < -w0 + 1.6 or (y == 1 and absf(dx) <= 1.0):
					c3 = "b"
				L.P(b, x, y, g(c3))
	# dobras da boca (vincos escuros entre as abas)
	L.P(b, 8, 3, g("e")); L.P(b, 13, 3, g("e")); L.P(b, 8, 2, g("e")); L.P(b, 13, 2, g("e"))
	# cordão do gargalo (mesmo creme do punho da luva) + ponta solta caindo para a direita
	for x in range(6, 16):
		L.P(b, x, 5, g("f"))
		L.P(b, x, 6, g("g"))
	L.P(b, 15, 7, g("f")); L.P(b, 16, 8, g("f")); L.P(b, 16, 9, g("g"))
	# moeda estampada no corpo
	L.ring(b, 10.5, 13.5, 2.9, 2.9, 1.0, g("e"))
	L.ellipse(b, 10.5, 13.5, 2.0, 2.0, g("b"))
	L.R(b, 10, 12, 1, 3, g("e"))
	var o: Image = ol(b, g("o"))
	# brilho passeando da esquerda para a direita (igual à luva: cruz de 5 px em d)
	var sp := [Vector2i(5, 11), Vector2i(11, 3), Vector2i(16, 12)]
	var p: Vector2i = sp[frame]
	for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var q: Vector2i = p + d
		if o.get_pixel(q.x, q.y).a > 0.0 and o.get_pixel(q.x, q.y) != g("o"):
			o.set_pixel(q.x, q.y, g("d"))
	return o

# ================================================================ Grito da equipe (LOJA)
## Megafone verde (a cor da equipe nos ícones de Corpo/equipe) gritando para a direita, com
## duas ondas de som amarelas. 16x16 como os outros ícones da LOJA.
func icon_crew_click() -> Image:
	var b: Image = L.blank(16, 16)
	# cabo + bocal
	L.R(b, 1, 7, 2, 3, "d2")
	L.P(b, 1, 7, "g0")
	# corpo cônico: de x 3 (altura 5) até x 9 (altura 11)
	for x in range(3, 10):
		var half := 2.0 + (x - 3) * 0.55
		for y in 16:
			var dy := y + 0.5 - 8.5
			if absf(dy) <= half:
				var c := "gr2"
				if dy < -half + 1.3:
					c = "gr3"
				elif dy > half - 1.3:
					c = "gr1"
				L.P(b, x, y, c)
	# alça embaixo
	L.R(b, 5, 11, 1, 2, "d2"); L.R(b, 5, 12, 2, 1, "d2")
	# borda da boca (anel creme) e o escuro de dentro
	L.R(b, 10, 3, 1, 11, "cream")
	L.P(b, 10, 3, "white"); L.P(b, 10, 4, "white")
	L.R(b, 10, 13, 1, 1, "g3")
	var o: Image = ol(b, "ink")
	# ondas de som (sem contorno, para não virarem grade)
	for p in [[12, 6], [13, 7], [13, 8], [13, 9], [12, 10]]:
		L.P(o, p[0], p[1], "y1")
	for p in [[13, 3], [14, 4], [15, 5], [15, 6], [15, 7], [15, 8], [15, 9], [15, 10], [15, 11], [14, 12], [13, 13]]:
		L.P(o, p[0], p[1], "y1")
	L.P(o, 15, 8, "y2"); L.P(o, 13, 8, "y2")
	return o

# ================================================================ Luva L4 (LOJA)
## Mesmo molde do icon_glove_l3 (a "marca" da academia), trocando as cores pela paleta da L4.
func icon_glove_l4(pal: Dictionary) -> Image:
	var src: Image = frame_of("icon_glove_l3")
	var map := {
		L.C.d1.to_html(false): pal.r0,   # lado da sombra
		L.C.d2.to_html(false): pal.r1,   # corpo
		L.C.g0.to_html(false): pal.r2,   # brilhos
		L.C.g1.to_html(false): pal.cuff,  # punho
	}
	var o: Image = src.duplicate()
	for y in o.get_height():
		for x in o.get_width():
			var c := o.get_pixel(x, y)
			if c.a > 0.0 and map.has(c.to_html(false)):
				o.set_pixel(x, y, L.col(map[c.to_html(false)]))
	return o

func l4_palette() -> Dictionary:
	# Se o Artista de Personagens já gravou a paleta da L4, usa a dele; senão, azul de competição.
	var p := {"r0": "b0", "r1": "b1", "r2": "b2", "cuff": "cream", "from": "padrão do Diretor de Arte (azul de competição)"}
	var bd: Dictionary = OLD.get("by_data_id", {})
	if bd.has("glove_l4") and bd.glove_l4.has("palette"):
		var q: Dictionary = bd.glove_l4.palette
		if L.C.has(str(q.get("r0", ""))) and L.C.has(str(q.get("r1", ""))) and L.C.has(str(q.get("r2", ""))):
			p.r0 = str(q.r0); p.r1 = str(q.r1); p.r2 = str(q.r2)
			p.from = "by_data_id.glove_l4.palette (Artista de Personagens)"
	return p

# ================================================================ mockup
func T(img: Image, s: String, x: int, y: int, c, scale := 1) -> int:
	return L.text(img, s, x, y, c, scale)

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

func make_mockup() -> void:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "d2")
	L.R(img, 0, 0, 640, 13, "d1")
	T(img, "FIGHTCLICKER - FASE 5.2 - AS DUAS LUVAS DOURADAS (PLACEHOLDER, X3)", 6, 3, "white")
	# --- coluna 1: as duas, ampliadas x4, quadros 0..2
	var cols := [["event_golden_glove", "LUVA X7", "FRENESI: CLIQUE X7 POR 6 S", "y1", "COGUMELO:", "CUPULA EM CIMA,", "PUNHO RETO", "EMBAIXO"],
		["event_golden_crew", "BOLSA DA TORCIDA", "+45 S DA EQUIPE, DE UMA VEZ", "gr3", "PERA INVERTIDA:", "ABAS E CORDAO", "EM CIMA, BOJO", "EMBAIXO"]]
	for i in 2:
		var id: String = cols[i][0]
		var x0 := 10 + i * 160
		L.R(img, x0 - 4, 20, 152, 168, "d1")
		T(img, cols[i][1], x0, 25, "white")
		T(img, cols[i][2], x0, 35, cols[i][3])
		for f in 3:
			L.R(img, x0 + f * 49 - 1, 48, 48, 46, "g0")
			put_k(img, frame_of(id, f), Vector2i(x0 + f * 49 + 2, 50), 2)
		T(img, "QUADROS 0-1-2 (6 FPS, X2)", x0, 98, "g2")
		# silhueta grande
		L.R(img, x0, 110, 50, 48, "cream")
		put_k(img, silhouette(frame_of(id, 0), L.C.ink), Vector2i(x0 + 3, 113), 2)
		T(img, "SILHUETA (X2)", x0 + 56, 112, "white")
		for k in 4:
			T(img, cols[i][4 + k], x0 + 56, 124 + k * 10, "g3")
	# --- coluna 2: na sala, em 1x (tamanho de verdade)
	var bx := 330
	L.R(img, bx - 4, 20, 310, 168, "d1")
	T(img, "NA SALA, TAMANHO REAL (1X)", bx, 25, "white")
	var rooms := [["garage_bg", "GARAGEM"], ["gym_bg", "ACADEMIA"]]
	for r in 2:
		var bg: Image = frame_of(rooms[r][0])
		var crop := Rect2i(200, 60, 148, 120)
		var ry := 36
		var rx := bx + r * 152
		img.blit_rect(bg, crop, Vector2i(rx, ry))
		put(img, "event_golden_glove", 1, Vector2i(rx + 40, ry + 50))
		put(img, "event_golden_crew", 1, Vector2i(rx + 100, ry + 74))
		T(img, rooms[r][1], rx, ry + 124, "g3")
	T(img, "MESMO QUADRO 22X21, MESMO OURO E BRILHO DA X7", bx, 172, "g2")
	# --- linha de baixo: LOJA e caixas
	L.R(img, 6, 198, 628, 156, "d1")
	T(img, "LOJA (16X16, VISTO EM X2) E ETIQUETA DA CAIXA (DICA DE HOVER)", 10, 203, "white")
	var icons := [["icon_glove_l3", "LUVA L3"], ["icon_glove_l4", "LUVA L4"], ["icon_crew_click", "GRITO DA EQUIPE"]]
	for i in icons.size():
		var ix := 12 + i * 98
		L.R(img, ix, 216, 40, 40, "g0")
		put_k(img, frame_of(icons[i][0]), Vector2i(ix + 4, 220), 2)
		T(img, icons[i][1], ix, 262, "g3")
		put(img, icons[i][0], 0, Vector2i(ix + 48, 228))
		T(img, "1X", ix + 48, 247, "g2")
	tag_card(img, 320, 216, "LUVA MARCA", "ETIQUETA INTACTA")
	tag_card(img, 440, 216, "LUVA TORNEIO", "NAO EMPRESTAR")
	T(img, "CAIXA PEQUENA, SLOT GLOVE", 320, 278, "g3")
	T(img, "(IGUAL A L1 E L2)", 320, 288, "g2")
	T(img, "PLACEHOLDER GERADO POR CODIGO. VERSAO FINAL: ARTISTA DESENHA A BOLSA", 10, 312, "g2")
	T(img, "(TECIDO, VOLUME, BRILHO) E O MEGAFONE; MANTER 22X21, PIVO 11,10, 3 QUADROS.", 10, 322, "g2")
	DirAccess.make_dir_recursive_absolute(MOCK)
	var b: Image = img.duplicate()
	b.resize(640 * 3, 360 * 3, Image.INTERPOLATE_NEAREST)
	b.save_png(MOCK + "fase52_bolsa_x3.png")

# ================================================================ manifest
func write_manifest(pal: Dictionary) -> void:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível na hora de gravar; nada foi escrito")
		return
	var doc: Dictionary = intify(j.data)
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 5.2") < 0:
		doc["_sobre"] = sobre + " Fase 5.2 (Diretor de Arte): event_golden_crew, icon_crew_click, caixa da L3/L4 (gerador no scratchpad do Diretor de Arte; ver direcao-visual.md §19)."
	var sp: Dictionary = doc.get("sprites", {})
	for id in M:
		sp[id] = intify(M[id])
	doc["sprites"] = sp
	var bd: Dictionary = doc.get("by_data_id", {})
	if bd.has("box"):
		var bx: Dictionary = bd.box
		for it in ["glove_l3", "glove_l4"]:
			bx.sprite_by_item[it] = "box_small"
			bx.slot_by_item[it] = "glove"
		bd["box"] = bx
	bd["golden_event"] = {"frenzy_sprite": "event_golden_glove", "crew_sprite": "event_golden_crew",
		"anim": [0, 1, 2], "fps": 6.0, "click_rect": [-18, -18, 36, 34],
		"note": "Fase 5.2: as duas variantes têm o mesmo quadro (22x21), pivô (11,10), fps, flutuação e sons; só muda o sprite, sorteado quando o evento aparece (training.json golden_event.crew_sprite / frenzy_sprite). Mesmo jeito de aparecer e sumir da luva x7 (sala.gd)."}
	var cc: Dictionary = bd.get("crew_click", {})
	cc["icon"] = "icon_crew_click"
	bd["crew_click"] = cc
	bd["_nota_fase52_arte"] = "Fase 5.2 (Diretor de Arte): golden_event (bolsa da torcida), crew_click (ícone da LOJA), box.sprite_by_item/slot_by_item de glove_l3 e glove_l4 (caixa pequena, slot glove)."
	doc["by_data_id"] = bd
	var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()

func _init() -> void:
	L = load("res://tools/art/pixel_lib.gd").new()
	var here: String = get_script().resource_path.get_base_dir()
	FINAL = OS.get_cmdline_user_args().has("--final")
	OUT = (ROOT + "assets/sprites/") if FINAL else (here + "/out/sprites/")
	MOCK = (ROOT + "docs/arte/mockups/") if FINAL else (here + "/out/mock/")
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível")
		quit()
		return
	OLD = j.data
	save_sheet("event_golden_crew", "ui/event_golden_crew.png", [crew_bag(0), crew_bag(1), crew_bag(2)], 6.0, Vector2i(11, 10), {
		"loop": true,
		"note": "Bolsa da torcida (Fase 5.2): variante da luva dourada que dá treino de uma vez (+45 s da equipe). Sacola de pano dourada amarrada com cordão creme, moeda estampada; silhueta oposta à da luva (abas em cima, bojo embaixo). Mesmo quadro, pivô, ouro, brilho passeando (loop 0-1-2 a 6 fps) e flutuação da event_golden_glove. Usar em 1x."})
	save_sheet("icon_crew_click", "ui/icon_crew_click.png", [icon_crew_click()], 0, Vector2i.ZERO, {
		"note": "Ícone 16x16 da LOJA do Grito da equipe (crew_click): megafone verde da equipe gritando, ondas amarelas."})
	var pal := l4_palette()
	# icon_glove_l4 agora é do Artista de Personagens (gravou o dele em 16:36): só uso o arquivo dele no mockup
	var l4 := Image.load_from_file(ROOT + "assets/sprites/ui/icon_glove_l4.png")
	l4.convert(Image.FORMAT_RGBA8)
	F["icon_glove_l4"] = [l4]
	if false: save_sheet("icon_glove_l4", "ui/icon_glove_l4.png", [icon_glove_l4(pal)], 0, Vector2i.ZERO, {
		"note": "Ícone 16x16 da luva L4 (Luva de torneio) para a LOJA: mesmo molde do icon_glove_l3, cores %s/%s/%s com punho creme e listra dourada. Paleta: %s. Se a luva da L4 nas mãos usar outras cores, regerar." % [pal.r0, pal.r1, pal.r2, pal.from]})
	make_mockup()
	if FINAL:
		write_manifest(pal)
	print("ok fase 5.2 arte (%s), paleta L4: %s" % ["PROJETO" if FINAL else "previa", pal.from])
	quit()
