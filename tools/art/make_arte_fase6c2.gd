extends SceneTree
## Fase 6c2 "Mais longe que eu" (Diretor de Arte) - PLACEHOLDER gerado por código. Ver docs/arte/direcao-visual.md §26.
## Gera:
##   garage/wall_mural.png, gym/wall_mural_gym.png (55x23, 4 quadros = quantos retratos: 1 / 2-3 / 4-7 / 8+), recortados
##       sobre o fundo de cada sala (sombra de 1 px na parede). Ponto: layout.mural_spot / gym_mural_spot = (176,128).
##   ui/mural/ui_mural_portrait_frame(_first).png (62x66, furo 56x60 em 3,3), ui_mural_portrait_bg.png (56x60),
##   ui/mural/ui_mural_seal.png (20x24, selo "saiu por cima"), ui/icon_honor.png (9x9), icon_honor_16.png,
##   ui/ui_honor_chip.png (9-slice 12x11), ui/hall/hall_<nó>.png e _gray (16x16, 6 nós do hall).
##   disciple/mural_portrait_disc_<camada>.png: o busto = recorte (9,-1,28,30) do quadro 0 da disciple_stand_bare, em todas
##       as camadas (body, top_tank, top_tee, head_<corte>, band, front, symbol_chest). characters/mural_portrait_john.png:
##       o mesmo recorte do john_step_back q0. O jogo mostra o busto em 2x (56x60).
##   docs/arte/mockups/fase6c2_*.png e (com --manifest) as chaves desta fase no manifest.
## A camada school_symbol das poses do discípulo sai dos geradores de personagem (personagem_lib.gd, _capture_call_6b2):
##   FC_LUTADOR=disc FC_CAMADAS=1 make_sprites_jogador.gd + make_golpes_jogador.gd, make_sprites_fase6b1.gd, make_sprites_fase6c1.gd
##   numa pasta temporária; copiar só os *_disc_symbol_*.png para assets/sprites/disciple/ (as outras camadas saem idênticas).
## Rodar de uma pasta temporária com project.godot vazio:
##   Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_arte_fase6c2.gd -- [--final] [--manifest]
## Sem --final grava em <tmp>/out (prévia). --manifest relê o manifest e mexe só nas chaves da 6c2 (e não grava se a
## conferência do ponto do mural falhar).

var ROOT := OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else "E:/Fightclicker/"
var OUT := ""
var MOCK := ""
var FINAL := false
var L
var M := {}
var problems: Array = []
var notes: Array = []

const GPIV := Vector2i(22, 67)
const MURAL_POS := Vector2i(176, 128)
const MURAL_SIZE := Vector2i(55, 23)        # quadro 54x22 + 1 px de sombra à direita e embaixo
const MURAL_FRAMES := [1, 3, 6, 10]         # fotos desenhadas em cada quadro
const MURAL_COUNT_MIN := [1, 2, 4, 8]       # a partir de quantas entradas do roster usar o quadro
const BUST := Rect2i(9, -1, 28, 30)         # recorte no quadro 48x72 (pivô 22,67)
const PORTRAIT := Vector2i(56, 60)
const P_COACH := Vector2i(196, 236)
const P_MENTOR := Vector2i(254, 252)
const P_M2 := Vector2i(150, 262)
const P_FIGHTER := Vector2i(303, 272)
const P_ROPE := Vector2i(336, 272)
const PHOTO_GAR := Rect2i(237, 67, 18, 21)
const PHOTO_GYM := Rect2i(212, 158, 18, 21)
const TARGET_FOLGA := [273, 370]
const SIDE_BAG := Rect2i(238, 160, 40, 76)
const CHAIN_X := 257
const NO_COVER := Rect2i(310, 180, 52, 94)
const SHELF := Rect2i(180, 101, 80, 27)
const METRONOME := Rect2i(231, 93, 19, 26)
const CREW := ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2"]
const HALL := ["hall_box", "hall_fund", "hall_notes", "hall_crew", "hall_glove", "hall_wall"]

## Símbolo na roupa: cor por parte de cima (peito) e por calção (coxa). blue = carimbo b0/b1, yellow = tinta y0/y1.
const SYM_CHEST := {"white": "blue", "black": "yellow", "gray": "yellow", "blue": "yellow", "green": "yellow", "yellow": "blue"}
const SYM_LEG := {"green": "yellow", "blue": "yellow", "black": "yellow", "white": "blue", "purple": "yellow", "yellow": "blue"}
const SYM_RAMPS := {"blue": {"shadow": "#1f2a44", "base": "#2f4a78"}, "yellow": {"shadow": "#e0a040", "base": "#f5d26b"}}
const SYM_KEYS := {"shadow": "#1f2a45", "base": "#304a78"}

# ---------------------------------------------------------------- util
func spr(id: String) -> Dictionary:
	return M.sprites.get(id, {})

func load_abs(p: String) -> Image:
	var img := Image.load_from_file(p)
	img.convert(Image.FORMAT_RGBA8)
	return img

func res_abs(r: String) -> String:
	return ROOT + r.replace("res://", "")

func frame_file(path: String, fw: int, fh: int, q: int) -> Image:
	var img := load_abs(path)
	var n := maxi(img.get_width() / fw, 1)
	return img.get_region(Rect2i(clampi(q, 0, n - 1) * fw, 0, fw, fh))

func frame_of(id: String, q := 0) -> Image:
	var e := spr(id)
	return frame_file(res_abs(str(e.file)), int(e.frame_size[0]), int(e.frame_size[1]), q)

func blend(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func scaled(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func save(img: Image, rel: String) -> void:
	var p := OUT + rel
	DirAccess.make_dir_recursive_absolute(p.get_base_dir())
	img.save_png(p)

func save_mock(img: Image, name: String, k: int) -> void:
	DirAccess.make_dir_recursive_absolute(MOCK)
	scaled(img, k).save_png(MOCK + name)

func region_pad(img: Image, r: Rect2i) -> Image:
	var out := Image.create_empty(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, r, Vector2i.ZERO)   # blit_rect recorta o que sai da imagem
	if r.position.y < 0 or r.position.x < 0:
		out = Image.create_empty(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
		var src := Rect2i(maxi(r.position.x, 0), maxi(r.position.y, 0), r.size.x, r.size.y).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		out.blit_rect(img, src, src.position - r.position)
	return out

func h(c: String) -> Color:
	return Color.html(c)

# ---------------------------------------------------------------- discípulo montado (igual ao jogo)
## look = {skin, hair_color, shorts_color, top: none|tank|tee, top_color, cut, band: none|<cor>, socks: bool, symbol: bool}
func recolor(look: Dictionary, sym_place: String) -> Dictionary:
	var pb: Dictionary = M.by_data_id.disciple_palette
	var m := {}
	var pairs := [["skin", look.skin], ["hair_color", look.hair_color], ["shorts_color", look.shorts_color],
		["top_color", look.get("top_color", "white")], ["headband_color", look.get("band", "red") if look.get("band", "none") != "none" else "red"],
		["socks", look.shorts_color]]
	for pr in pairs:
		var keys: Dictionary = pb["keys"][pr[0]]
		var ramp := {}
		for o in pb.options[pr[0]]:
			if o.id == pr[1]:
				ramp = o.ramp
		for slot in keys:
			if ramp.has(slot):
				m[(keys[slot] as String).substr(1).to_lower()] = h(ramp[slot])
	var sid: String = SYM_CHEST.get(look.get("top_color", "white"), "blue") if sym_place == "chest" else SYM_LEG.get(look.shorts_color, "yellow")
	for slot in SYM_KEYS:
		m[(SYM_KEYS[slot] as String).substr(1).to_lower()] = h(SYM_RAMPS[sid][slot])
	return m

func sym_file(e: Dictionary, place: String) -> String:
	var body: String = e.layers.body
	var own := body.replace("_disc_body.png", "_disc_symbol_" + place + ".png")
	if FileAccess.file_exists(res_abs(own)):
		return own
	var tank: String = e.layers.top.tank
	return tank.replace("_disc_top_tank.png", "_disc_symbol_" + place + ".png")

## Monta um quadro do discípulo. Camadas pela ordem do manifest + school_symbol depois do meião.
func disc(id: String, q: int, look: Dictionary) -> Image:
	var e := spr(id)
	var fw := int(e.frame_size[0])
	var fh := int(e.frame_size[1])
	var lay: Dictionary = e.layers
	var place := "chest" if look.get("top", "none") != "none" else "leg"
	var body := frame_file(res_abs(lay.body), fw, fh, q)
	var top = frame_file(res_abs(lay.top[look.top]), fw, fh, q) if look.get("top", "none") != "none" else null
	var socks = frame_file(res_abs(lay.socks), fw, fh, q) if look.get("socks", false) else null
	var sym = null
	if look.get("symbol", false):
		var sf := sym_file(e, place)
		if FileAccess.file_exists(res_abs(sf)):
			sym = frame_file(res_abs(sf), fw, fh, q)
	var head := frame_file(res_abs(lay.head[look.get("cut", "short")]), fw, fh, q)
	var band = frame_file(res_abs(lay.band), fw, fh, q) if look.get("band", "none") != "none" else null
	var mask := frame_file(res_abs(lay.front_mask), fw, fh, q)
	return compose(body, top, socks, sym, head, band, mask, recolor(look, place))

func compose(body: Image, top, socks, sym, head, band, mask, rc: Dictionary) -> Image:
	var w := body.get_width()
	var hh := body.get_height()
	var out := Image.create_empty(w, hh, false, Image.FORMAT_RGBA8)
	for y in hh:
		for x in w:
			var lo := body.get_pixel(x, y)
			for ly in [top, socks, sym]:
				if ly != null:
					var lc: Color = (ly as Image).get_pixel(x, y)
					if lc.a > 0.0:
						lo = lc
			var c := lo
			for ly in [head, band]:
				if ly != null:
					var lc: Color = (ly as Image).get_pixel(x, y)
					if lc.a > 0.0:
						c = lc
			if mask != null and (mask as Image).get_pixel(x, y).a > 0.0 and lo.a > 0.0:
				c = lo
			if c.a > 0.0:
				var hx := c.to_html(false).to_lower()
				if rc.has(hx):
					c = rc[hx]
			out.set_pixel(x, y, c)
	return out

func look(skin: String, hair: String, shorts: String, top := "none", top_color := "white", cut := "short", band := "none", socks := false, symbol := true) -> Dictionary:
	return {"skin": skin, "hair_color": hair, "shorts_color": shorts, "top": top, "top_color": top_color, "cut": cut,
		"band": band, "socks": socks, "symbol": symbol}

# ---------------------------------------------------------------- mural na parede
const SKINS := ["sk1", "sk2", "sk0", "sk1", "sk2", "sk0", "sk1", "sk2", "sk0", "sk1"]
const HAIRS := ["d1", "br1", "ink", "y0", "br0", "d1", "br2", "ink", "g3", "br1"]
const SHIRTS := ["g3", "r2", "b2", "gr2", "y1", "p1", "white", "d2", "b1", "r1"]
const SEALED := [true, false, true, true, false, true, false, true, true, false]

## Polaroid 6x7: borda cream (embaixo 2 px), foto 4x4 com cabeça e ombros; o 1º (John) em sépia.
func polaroid(img: Image, x: int, y: int, i: int) -> void:
	L.R(img, x, y, 6, 7, "cream")
	L.R(img, x + 5, y, 1, 7, "g3")
	L.R(img, x, y + 6, 6, 1, "g3")
	var sep := i == 0
	L.R(img, x + 1, y + 1, 4, 4, "br1" if sep else "d2")
	L.R(img, x + 1, y + 1, 4, 1, "br2" if sep else "g0")
	L.R(img, x + 2, y + 2, 2, 2, "br3" if sep else SKINS[i])
	L.R(img, x + 2, y + 1, 2, 1, "br0" if sep else HAIRS[i])
	L.R(img, x + 1, y + 4, 4, 1, "br2" if sep else SHIRTS[i])
	L.P(img, x + 2, y + 4, "br3" if sep else SKINS[i])
	L.P(img, x + 3, y + 4, "br3" if sep else SKINS[i])
	if SEALED[i] and i > 0:
		L.P(img, x + 4, y + 5, "st3")         # o selo, 1 px de prata no pé da foto
	L.P(img, x + 2, y, "r2")                 # alfinete
	L.P(img, x + 3, y, "r1")

func mural_board(n: int, gym: bool) -> Image:
	var bg: Image = frame_of("gym_bg" if gym else "garage_bg")
	var img: Image = bg.get_region(Rect2i(MURAL_POS - Vector2i(128, 18), MURAL_SIZE))
	# sombra na parede (direita e embaixo)
	L.shade_rect(img, 1, 22, 54, 1, -1)
	L.shade_rect(img, 54, 1, 1, 22, -1)
	var W := 54
	var H := 22
	L.R(img, 0, 0, W, H, "ink")
	L.R(img, 1, 1, W - 2, H - 2, "br1")
	L.R(img, 1, 1, W - 2, 1, "br2")
	L.R(img, 1, 1, 1, H - 2, "br2")
	L.R(img, 1, H - 2, W - 2, 1, "br0")
	L.R(img, W - 2, 1, 1, H - 2, "br0")
	L.R(img, 2, 2, W - 4, H - 4, "ink")
	# cortiça escura (a da academia pintada no fundo é mais clara: não confundem)
	L.R(img, 3, 3, W - 6, H - 6, "br2")
	for yy in range(3, H - 3):
		for xx in range(3, W - 3):
			var k := (xx * 7 + yy * 13) % 11
			if k == 0:
				L.P(img, xx, yy, "br1")
			elif k == 5:
				L.P(img, xx, yy, "br3")
	L.R(img, 3, 3, W - 6, 1, "br1")   # sombra da moldura na cortiça
	L.R(img, 3, 3, 1, H - 6, "br1")
	# plaquinha da escola: papel com o carimbo (school_symbol_9) e fita
	L.R(img, 5, 4, 11, 13, "cream")
	L.R(img, 15, 4, 1, 13, "g3")
	L.R(img, 5, 16, 11, 1, "g3")
	blend(img, load_abs(ROOT + "assets/sprites/ui/school_symbol_9.png"), 6, 5)
	L.R(img, 4, 3, 3, 2, "g3")
	L.R(img, 14, 3, 3, 2, "g3")
	# fotos: 2 fileiras de 5, da esquerda para a direita (a 1ª é o John)
	var slots := []
	for row in 2:
		for c in 5:
			slots.append(Vector2i(18 + c * 7, 4 + row * 8))
	for i in n:
		var p: Vector2i = slots[i]
		if i in [2, 6, 8]:
			p.y += 0 if p.y > 4 else 0
		if i in [1, 4, 7]:
			p.x += 0
		polaroid(img, p.x, p.y + (1 if i % 3 == 1 and p.y == 4 else 0), i)
	if not gym:
		# longe da lâmpada (à direita, x ~300): o lado esquerdo do quadro 1 passo mais escuro, com dither na transição
		for yy in range(0, 23):
			for xx in range(0, 55):
				var c := img.get_pixel(xx, yy)
				if c == L.col("ink") or c.a == 0.0:
					continue
				if xx < 14 or (xx < 22 and (xx + yy) % 2 == 0):
					img.set_pixel(xx, yy, L.shade(c, -1))
	return img

# ---------------------------------------------------------------- UI do mural e da Honra
func portrait_frame(first: bool) -> Image:
	var W := PORTRAIT.x + 6
	var H := PORTRAIT.y + 6
	var img: Image = L.blank(W, H)
	var hi := "br1" if first else "br2"
	var md := "br0" if first else "br1"
	var lo := "ink" if first else "br0"
	L.R(img, 0, 0, W, H, "ink")
	L.R(img, 1, 1, W - 2, H - 2, md)
	L.R(img, 1, 1, W - 2, 1, hi)
	L.R(img, 1, 1, 1, H - 2, hi)
	L.R(img, 1, H - 2, W - 2, 1, lo)
	L.R(img, W - 2, 1, 1, H - 2, lo)
	L.R(img, 2, 2, W - 4, H - 4, "ink")
	L.R(img, 3, 3, PORTRAIT.x, PORTRAIT.y, Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(3, 3, PORTRAIT.x, PORTRAIT.y), Color(0, 0, 0, 0))
	if first:
		# cantoneiras de latão: o primeiro retrato da escola
		for p in [Vector2i(0, 0), Vector2i(W - 4, 0), Vector2i(0, H - 4), Vector2i(W - 4, H - 4)]:
			L.R(img, p.x, p.y, 4, 4, "ink")
			L.R(img, p.x + 1, p.y + 1, 2, 2, "y0")
			L.P(img, p.x + 1, p.y + 1, "y1")
	return img

func portrait_bg() -> Image:
	var img: Image = L.blank(PORTRAIT.x, PORTRAIT.y)
	L.R(img, 0, 0, PORTRAIT.x, PORTRAIT.y, "d2")
	L.ellipse_dither(img, 28, 20, 24, 22, "g0")
	L.ellipse(img, 28, 20, 15, 14, "g0")
	L.dither(img, 0, 44, PORTRAIT.x, 4, "d1")
	L.R(img, 0, 48, PORTRAIT.x, 12, "d1")
	return img

## Roseta prateada (Honra) com o símbolo da escola no meio e duas fitas azuis da escola (atrás, saindo por baixo).
func rosette(size: int) -> Image:
	var big := size >= 20
	var W := 20 if big else 16
	var H := 24 if big else 16
	var img: Image = L.blank(W, H)
	var cx := W / 2.0
	var cy := 9.0 if big else 6.0
	var r := 8.0 if big else 5.5
	# fitas: duas tiras em V invertido, com corte em V na ponta
	var ty := int(cy + r * 0.4)
	for i in 2:
		var s_ := -1 if i == 0 else 1
		var x0 := int(cx) + (-4 if i == 0 else 1) if big else int(cx) + (-3 if i == 0 else 1)
		var wdt := 3 if big else 2
		for yy in range(ty, H):
			var dx := (yy - ty) / (5 if big else 4) * s_
			L.R(img, x0 + dx, yy, wdt, 1, "b2")
			L.P(img, x0 + dx + (wdt - 1 if i == 0 else 0), yy, "b1")
		var xe := x0 + (H - 1 - ty) / (5 if big else 4) * s_
		img.set_pixel(clampi(xe + wdt / 2, 0, W - 1), H - 1, Color(0, 0, 0, 0))
	# medalha: borda serrilhada (st1/st3 alternados), corpo st2 com luz em cima à esquerda
	var n := 14 if big else 10
	for yy in H:
		for xx in W:
			var d := Vector2(xx + 0.5 - cx, yy + 0.5 - cy)
			var ln := d.length()
			if ln > r:
				continue
			var c := "st2"
			if ln > r - 1.3:
				var k := int(floor((atan2(d.y, d.x) + PI) / (TAU / n))) % 2
				c = "st3" if k == 0 else "st1"
			elif d.x + d.y < -r * 0.4:
				c = "st3"
			L.P(img, xx, yy, c)
	L.ellipse(img, cx, cy, r - 2.0, r - 2.0, "white")
	L.ellipse(img, cx + 0.6, cy + 0.6, r - 2.4, r - 2.4, "cream")
	L.ellipse(img, cx - 0.2, cy - 0.2, r - 2.6, r - 2.6, "white")
	var sym := load_abs(ROOT + "assets/sprites/ui/school_symbol_%d.png" % (9 if big else 5))
	blend(img, sym, int(cx) - sym.get_width() / 2, int(cy) - sym.get_height() / 2)
	var o: Image = L.outlined(img)
	return o.get_region(Rect2i(1, 1, W, H))

func honor_icon_9() -> Image:
	var rows := [
		"..kkkkk..",
		".kSTTTSk.",
		"kSTWWWTSk",
		"kSTWbWTSk",
		"kSTWWWTSk",
		".kSTTTSk.",
		"..kBkBk..",
		"..kBkBk..",
		"...k.k...",
	]
	return from_rows(rows, {"k": "ink", "S": "st1", "T": "st3", "W": "white", "b": "b1", "B": "b2"})

func from_rows(rows: Array, leg: Dictionary) -> Image:
	var img: Image = L.blank((rows[0] as String).length(), rows.size())
	for y in rows.size():
		var s: String = rows[y]
		for x in s.length():
			if leg.has(s[x]):
				L.P(img, x, y, leg[s[x]])
	return img

func honor_chip() -> Image:
	var img: Image = L.blank(12, 11)
	L.R(img, 1, 0, 10, 11, "ink")
	L.R(img, 0, 1, 12, 9, "ink")
	L.R(img, 1, 1, 10, 9, "d1")
	L.R(img, 2, 1, 8, 1, "st1")
	L.R(img, 1, 2, 1, 7, "st0")
	L.R(img, 10, 2, 1, 7, "st0")
	L.R(img, 2, 9, 8, 1, "ink")
	return img

# ---------------------------------------------------------------- ícones do hall (16x16, contorno ink)
func hall_icon(id: String) -> Image:
	var img: Image = L.blank(14, 14)
	match id:
		"hall_box":     # Fita frouxa: caixa com a fita soltando
			L.R(img, 0, 6, 13, 8, "br3")
			L.R(img, 0, 4, 13, 2, "y0")
			L.R(img, 11, 6, 2, 8, "br2")
			L.R(img, 0, 13, 13, 1, "br2")
			L.R(img, 6, 4, 2, 10, "cream")
			L.R(img, 7, 6, 1, 8, "g3")
			L.P(img, 8, 3, "cream")
			L.P(img, 9, 2, "cream")
			L.R(img, 10, 1, 2, 1, "white")
			L.P(img, 12, 2, "g3")
			L.R(img, 2, 8, 3, 1, "br2")
		"hall_fund":    # Vaquinha: lata com fenda e moeda entrando
			L.R(img, 3, 5, 8, 9, "st2")
			L.R(img, 3, 5, 1, 9, "st3")
			L.R(img, 10, 5, 1, 9, "st1")
			L.R(img, 3, 8, 8, 3, "r2")
			L.R(img, 3, 10, 8, 1, "r1")
			L.R(img, 3, 4, 8, 1, "st3")
			L.R(img, 5, 4, 4, 1, "ink")
			L.ellipse(img, 7, 2, 2.5, 2.2, "y1")
			L.P(img, 8, 2, "y0")
			L.P(img, 6, 1, "y2")
		"hall_notes":   # Caderno de recordes: caderno azul, etiqueta, lápis
			L.R(img, 1, 1, 9, 12, "b1")
			L.R(img, 1, 1, 2, 12, "b0")
			L.R(img, 10, 2, 1, 11, "cream")
			L.R(img, 4, 3, 5, 3, "cream")
			L.R(img, 5, 4, 3, 1, "g1")
			L.R(img, 3, 12, 7, 1, "b0")
			for i in 5:
				L.P(img, 13 - i, 8 + i, "y1")
				L.P(img, 12 - i, 8 + i, "y0")
			L.P(img, 13, 7, "r2")
			L.P(img, 8, 13, "br1")
		"hall_crew":    # Turma da escola: três cabeças
			L.R(img, 0, 9, 5, 5, "gr2")
			L.ellipse(img, 2.5, 6.5, 2.5, 2.5, "sk2")
			L.R(img, 1, 4, 3, 1, "br1")
			L.R(img, 9, 9, 5, 5, "b2")
			L.ellipse(img, 11.5, 6.5, 2.5, 2.5, "sk0")
			L.R(img, 10, 4, 3, 1, "d1")
			L.R(img, 4, 10, 6, 4, "r2")
			L.ellipse(img, 7, 6.5, 3, 3, "sk1")
			L.R(img, 5, 3, 4, 2, "br2")
			L.P(img, 8, 7, "ink")
		"hall_glove":   # Luva do mural: luva de lona pendurada pelo cadarço num prego
			L.P(img, 7, 0, "g1")
			L.line(img, 7, 1, 5, 3, "cream")
			L.line(img, 7, 1, 9, 3, "cream")
			L.R(img, 4, 3, 6, 3, "white")       # punho
			L.R(img, 4, 4, 6, 1, "br3")
			L.ellipse(img, 7, 9.5, 5, 4.5, "cream")   # mão fechada
			L.ellipse(img, 7.5, 10, 4, 3.6, "cream")
			L.R(img, 3, 7, 2, 4, "white")       # polegar (lado claro)
			L.R(img, 4, 8, 1, 3, "br3")
			L.R(img, 6, 13, 6, 1, "br3")       # sombra embaixo
			L.R(img, 11, 8, 1, 5, "br3")
			L.R(img, 6, 7, 4, 1, "white")       # luz nos dedos
		"hall_wall":    # Parede maior: mural com fotos e setas para os lados
			L.R(img, 3, 3, 8, 8, "br1")
			L.R(img, 4, 4, 6, 6, "br2")
			L.R(img, 4, 4, 2, 3, "cream")
			L.R(img, 7, 4, 2, 3, "cream")
			L.R(img, 5, 7, 2, 3, "cream")
			L.P(img, 4, 5, "sk1")
			L.P(img, 7, 5, "sk2")
			L.P(img, 5, 8, "sk0")
			for s in [-1, 1]:
				var x := 1 if s < 0 else 12
				L.R(img, x, 6, 1, 2, "y1")
				L.R(img, x - s, 5, 1, 4, "y1")
				L.P(img, x + s, 6, "y1")
				L.P(img, x + s, 7, "y1")
			L.R(img, 0, 6, 1, 2, "y1")
			L.R(img, 13, 6, 1, 2, "y1")
	var out: Image = L.outlined(img)
	return out

func gray(img: Image) -> Image:
	var g: Image = img.duplicate()
	var ramp := ["ink", "d1", "d2", "g0", "g1"]
	for y in g.get_height():
		for x in g.get_width():
			var c := g.get_pixel(x, y)
			if c.a == 0.0 or c == L.col("ink"):
				continue
			var lum := 0.3 * c.r + 0.59 * c.g + 0.11 * c.b
			g.set_pixel(x, y, L.col(ramp[clampi(1 + int(lum * 4.0), 1, 4)]))
	return g

# ---------------------------------------------------------------- busto
func bust_layers() -> Dictionary:
	var e := spr("disciple_stand_bare")
	var lay: Dictionary = e.layers
	var files := {"body": lay.body, "top_tank": lay.top.tank, "top_tee": lay.top.tee, "band": lay.band, "front": lay.front_mask,
		"symbol_chest": (lay.top.tank as String).replace("_disc_top_tank.png", "_disc_symbol_chest.png")}
	for cut in lay.head:
		files["head_" + cut] = lay.head[cut]
	var out := {}
	for k in files:
		var src := frame_file(res_abs(files[k]), 48, 72, 0)
		out[k] = region_pad(src, BUST)
	return out

func bust(look_: Dictionary, bl: Dictionary) -> Image:
	var top = bl["top_" + look_.top] if look_.top != "none" else null
	var sym = bl.symbol_chest if (look_.symbol and look_.top != "none") else null
	var band = bl.band if look_.band != "none" else null
	return compose(bl.body, top, null, sym, bl["head_" + look_.cut], band, bl.front, recolor(look_, "chest"))

func john_bust() -> Image:
	return region_pad(frame_of("john_step_back", 0), BUST)

func portrait_card(b: Image, first: bool, sealed: bool) -> Image:
	var card: Image = L.blank(PORTRAIT.x + 6 + 8, PORTRAIT.y + 6 + 8)
	blend(card, portrait_bg(), 3, 3)
	blend(card, scaled(b, 2), 3, 3)
	blend(card, portrait_frame(first), 0, 0)
	if sealed:
		blend(card, rosette(20), PORTRAIT.x + 6 - 14, PORTRAIT.y + 6 - 18)
	return card

# ---------------------------------------------------------------- sala (mockups e conferência)
func it_spr(id: String, q: int, pos: Vector2i, sort_y: float, shadow := false) -> Dictionary:
	var e := spr(id)
	return {"y": sort_y, "img": frame_of(id, q), "at": pos - Vector2i(int(e.pivot[0]), int(e.pivot[1])), "shadow": shadow, "pos": pos, "name": id}

func it_img(name: String, img: Image, pos: Vector2i, piv := GPIV) -> Dictionary:
	return {"y": float(pos.y), "img": img, "at": pos - piv, "shadow": true, "pos": pos, "name": name}

func room(gym: bool, side_bag: bool, mural_q: int, with_mural := true) -> Dictionary:
	var sfx := "_gym" if gym else ""
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	blend(im, frame_of("gym_bg" if gym else "garage_bg"), 128, 18)
	if gym:
		blend(im, frame_of("wall_photo_old_gym", 0), PHOTO_GYM.position.x, PHOTO_GYM.position.y)
	else:
		for id in ["wall_form_named", "wall_photo_old", "wall_photo_team", "wall_clipping", "wall_school_symbol"]:
			var e := spr(id)
			blend(im, frame_of(id), int(e.pos[0]), int(e.pos[1]))
		var le := spr("lamp")
		blend(im, frame_of("lamp"), 300 - int(le.pivot[0]), 32 - int(le.pivot[1]))
	if with_mural:
		blend(im, mural_board(MURAL_FRAMES[mural_q], gym), MURAL_POS.x, MURAL_POS.y)
	var items := []
	var bag_pos := Vector2i(258, 160) if side_bag else Vector2i(336, 183)
	var t: Image = frame_of("bag_chain_tile")
	var y := 33
	while y < bag_pos.y:
		blend(im, t.get_region(Rect2i(0, 0, t.get_width(), mini(6, bag_pos.y - y))), bag_pos.x - 1, y)
		y += 6
	var bag_id := ("bag_l0_side" if side_bag else "bag_l0_idle") + sfx
	if spr(bag_id).is_empty():
		bag_id = "bag_l0_side" if side_bag else "bag_l0_idle"
	items.append(it_spr(bag_id, 0, bag_pos, float(bag_pos.y + 70)))
	var crate := "garage_crate_gym" if gym else "garage_crate"
	items.append({"y": float(P_MENTOR.y - 2), "img": frame_of(crate), "at": P_MENTOR + Vector2i(-16, -20), "shadow": false, "pos": P_MENTOR, "name": "caixote"})
	items.append(it_img("mentor_sentado", disc("disciple_sit_rest", 0, look("skin_2", "black", "blue", "tee", "gray", "buzz", "none", true)), P_MENTOR))
	items.append(it_img("osmar", frame_of("coach_idle_gym" if gym else "coach_idle", 0), P_COACH))
	items.append(it_img("mentor_2", disc("disciple_stand_bare", 0, look("skin_4", "dark_brown", "white", "tank", "blue", "volume", "white")), P_M2))
	var fp := P_ROPE if side_bag else P_FIGHTER
	items.append(it_img("lutador", disc("fighter_idle_glove_l1_disc_layered", 0, look("skin_1", "copper", "purple", "none", "white", "short", "red")), fp))
	for id in CREW:
		var e := spr(id)
		items.append(it_spr(id, 0, Vector2i(int(e.pos[0]), int(e.pos[1])), float(e.pos[1]), true))
	items.sort_custom(func(a, b): return a.y < b.y)
	var fs := spr("floor_shadow")
	for it in items:
		if it.shadow:
			blend(im, frame_of("floor_shadow"), it.pos.x - int(fs.pivot[0]), it.pos.y - 1 - int(fs.pivot[1]))
		blend(im, it.img, it.at.x, it.at.y)
	return {"img": im, "items": items}

func opaque(img: Image, at: Vector2i) -> Rect2i:
	var r := img.get_used_rect()
	return Rect2i(r.position + at, r.size)

func dashed(img: Image, r: Rect2i, c: String) -> void:
	for x in range(r.position.x, r.end.x):
		if x % 4 < 2:
			L.P(img, x, r.position.y, c)
			L.P(img, x, r.end.y - 1, c)
	for yy in range(r.position.y, r.end.y):
		if yy % 4 < 2:
			L.P(img, r.position.x, yy, c)
			L.P(img, r.end.x - 1, yy, c)

## Confere o retângulo do mural contra o que não pode cobrir nem ser coberto. Devolve a lista de problemas.
func check_mural(gym: bool) -> Array:
	var bad := []
	var mr := Rect2i(MURAL_POS, MURAL_SIZE)
	var photo := PHOTO_GYM if gym else PHOTO_GAR
	if mr.intersects(photo):
		bad.append("cobre a foto")
	if mr.end.x > TARGET_FOLGA[0] and mr.position.x < TARGET_FOLGA[1]:
		bad.append("entra na faixa do alvo")
	if mr.intersects(NO_COVER):
		bad.append("no_cover")
	if mr.intersects(SIDE_BAG) or (mr.position.x <= CHAIN_X and mr.end.x > CHAIN_X - 1):
		bad.append("saco de lado / corrente")
	if mr.intersects(SHELF) or mr.intersects(METRONOME):
		bad.append("prateleira / metrônomo")
	for side in [false, true]:
		var R_: Dictionary = room(gym, side, 3)
		for it in R_.items:
			var o := opaque(it.img, it.at)
			if o.intersects(mr):
				# só é problema se algum pixel opaco cair dentro do mural
				var hit := 0
				for yy in range(maxi(o.position.y, mr.position.y), mini(o.end.y, mr.end.y)):
					for xx in range(maxi(o.position.x, mr.position.x), mini(o.end.x, mr.end.x)):
						if (it.img as Image).get_pixel(xx - it.at.x, yy - it.at.y).a > 0.0:
							hit += 1
				if hit > 0:
					bad.append("%s encosta no mural (%d px)" % [it.name, hit])
	return bad

func room_mock(gym: bool) -> void:
	var tag := "academia" if gym else "garagem"
	var a: Image = room(gym, false, 3).img
	var b: Image = room(gym, true, 3).img
	var crop := Rect2i(128, 18, 384, 272)
	var out: Image = L.blank(384 * 2 + 8, 272 + 14)
	L.R(out, 0, 0, out.get_width(), out.get_height(), "d1")
	blend(out, a.get_region(crop), 0, 14)
	blend(out, b.get_region(crop), 392, 14)
	L.text(out, "FASE 6C2 - MURAL NA %s: FOCO NO SACO / SACO DE LADO (CORDA)" % tag.to_upper(), 2, 3, "y1")
	save_mock(out, "fase6c2_mural_%s_x2.png" % tag, 2)
	# conferência
	var c: Image = room(gym, true, 3).img
	var mr := Rect2i(MURAL_POS, MURAL_SIZE)
	L.R(c, TARGET_FOLGA[0], 18, 1, 272, "r2")
	L.R(c, TARGET_FOLGA[1], 18, 1, 272, "r2")
	dashed(c, NO_COVER, "r3")
	dashed(c, SIDE_BAG, "f1")
	L.R(c, CHAIN_X, 33, 1, 127, "f1")
	dashed(c, SHELF, "g3")
	dashed(c, METRONOME, "g3")
	dashed(c, PHOTO_GYM if gym else PHOTO_GAR, "b3")
	dashed(c, mr.grow(1), "y1")
	for it in room(gym, true, 3).items:
		if it.name in ["osmar", "mentor_sentado", "mentor_2"] or it.name in CREW:
			dashed(c, opaque(it.img, it.at), "gr3")
	dashed(c, Rect2i(132, 132, 154, 36), "p2")   # balão do Osmar (em cima)
	var cc: Image = c.get_region(Rect2i(128, 18, 240, 200))
	var o2: Image = L.blank(240, 214)
	L.R(o2, 0, 0, 240, 214, "d1")
	blend(o2, cc, 0, 14)
	L.text(o2, "AMARELO MURAL  AZUL FOTO  VERDE GENTE", 2, 3, "y1")
	save_mock(o2, "fase6c2_mural_%s_conferencia_x3.png" % tag, 3)

# ---------------------------------------------------------------- tela do mural (mockup)
func quebra(t: String, w: int) -> Array:
	var out := []
	var cur := ""
	for word in t.split(" "):
		var nx := word if cur == "" else cur + " " + word
		if L.text_w(nx) > w and cur != "":
			out.append(cur)
			cur = word
		else:
			cur = nx
	out.append(cur)
	return out

func nine(dst: Image, src: Image, r: Rect2i, m: int) -> void:
	var sw := src.get_width()
	var sh := src.get_height()
	for yy in r.size.y:
		var sy := yy if yy < m else (sh - (r.size.y - yy) if yy >= r.size.y - m else m + (yy - m) % (sh - 2 * m))
		for xx in r.size.x:
			var sx := xx if xx < m else (sw - (r.size.x - xx) if xx >= r.size.x - m else m + (xx - m) % (sw - 2 * m))
			var c := src.get_pixel(sx, sy)
			if c.a > 0.0:
				dst.set_pixel(r.position.x + xx, r.position.y + yy, c)

func screen_mock() -> void:
	var base: Image = room(false, false, 3).img
	var im: Image = base.duplicate()
	for yy in 360:
		for xx in 640:
			if (xx + yy) % 2 == 0:
				im.set_pixel(xx, yy, L.col("ink"))
	var win := Rect2i(20, 14, 600, 332)
	nine(im, load_abs(ROOT + "assets/sprites/ui/ui_window.png"), win, 5)
	L.text_center(im, "MURAL DA ESCOLA", 320, 22, "white", 2, "ink")
	blend(im, honor_icon_9(), 40, 44)
	L.text(im, "HONRA: 37", 52, 45, "st3", 1, "ink")
	L.text_right(im, "RETRATOS COM SELO: 5 (CONTAM 5 DE 5)   +10% DE TREINO", 600, 45, "gr3", 1, "ink")
	L.R(im, 32, 56, 576, 1, "g0")
	var bl := bust_layers()
	var people := [
		["JOHN", "CARREIRA 1", "BOXE", "4 VITORIAS", "SAIU POR CIMA", true, true, null],
		["TEO", "CARREIRA 2", "BOXE", "6 VITORIAS", "SAIU POR CIMA", true, false, look("skin_3", "brown", "green", "tee", "white", "short", "red")],
		["DUDA", "CARREIRA 3", "JIU-JITSU", "2 VITORIAS", "PAROU EM BRUTAO", false, false, look("skin_1", "blond", "blue", "tank", "black", "bun", "none")],
		["KAUE", "CARREIRA 4", "BOXE", "5 VITORIAS", "SAIU POR CIMA", true, false, look("skin_5", "black", "black", "none", "white", "buzz", "yellow")],
		["LIA", "CARREIRA 5", "JIU-JITSU", "0 VITORIAS", "PASSOU O POSTO", false, false, look("skin_2", "copper", "purple", "tee", "green", "volume", "white")],
		["RUI", "CARREIRA 6", "BOXE", "7 VITORIAS", "SAIU POR CIMA", true, false, look("skin_4", "dark_brown", "white", "tank", "blue", "short", "black")],
		["NINA", "CARREIRA 7", "JIU-JITSU", "3 VITORIAS", "PAROU EM MURALHA", false, false, look("skin_3", "platinum", "yellow", "tee", "yellow", "bun", "blue")],
		["BETO", "CARREIRA 8", "BOXE", "4 VITORIAS", "SAIU POR CIMA", true, false, look("skin_1", "dark_brown", "green", "none", "white", "volume", "green")],
		["?", "CARREIRA 9", "-", "? VITORIAS", "PASSOU O POSTO", false, false, look("skin_5", "brown", "blue", "tee", "black", "buzz", "none")],
	]
	# 5 x 2 por página: célula 76 x 116 (retrato 62x66 + 5 linhas)
	var x0 := 40
	var y0 := 62
	for i in people.size():
		var p: Array = people[i]
		var cx := x0 + (i % 5) * 76
		var cy := y0 + (i / 5) * 136
		var b: Image = john_bust() if p[6] else bust(p[7], bl)
		var card := portrait_card(b, p[6], p[5])
		blend(im, card, cx + 4, cy)
		var tx := cx + 4 + 31
		L.text_center(im, p[0], tx, cy + 70, "white", 1, "ink")
		L.text_center(im, p[1], tx, cy + 80, "g2", 1, "ink")
		L.text_center(im, p[2], tx, cy + 89, "p2", 1, "ink")
		L.text_center(im, p[3], tx, cy + 98, "y1", 1, "ink")
		var ly := cy + 107
		for ln in quebra(p[4], 70):
			L.text_center(im, ln, tx, ly, "st3" if p[5] else "g3", 1, "ink")
			ly += 9
		if p[6]:
			for ln in quebra("FOI SEGUIR O RUMO DELE", 70):
				L.text_center(im, ln, tx, ly, "cream", 1, "ink")
				ly += 9
	# rolagem
	L.R(im, 418, 62, 3, 260, "d2")
	L.R(im, 418, 62, 3, 150, "g1")
	# hall
	L.R(im, 428, 62, 1, 270, "g0")
	L.text(im, "HALL DA ESCOLA", 436, 64, "white", 1, "ink")
	var names := ["FITA FROUXA", "VAQUINHA DA ESCOLA", "CADERNO DE RECORDES", "TURMA DA ESCOLA", "LUVA DO MURAL", "PAREDE MAIOR"]
	var costs := [10, 20, 30, 35, 45, 50]
	for i in 6:
		var yy := 78 + i * 42
		var owned := i < 2
		var ic: Image = hall_icon(HALL[i])
		blend(im, ic if (owned or i == 2) else gray(ic), 436, yy)
		L.text(im, names[i], 456, yy + 1, "white" if owned or i == 2 else "g2", 1, "ink")
		var st: String = "COMPRADO" if owned else ("%d DE HONRA" % costs[i] if i == 2 else "FALTAM %d" % (costs[i] - 37 + 27))
		nine(im, honor_chip(), Rect2i(456, yy + 12, L.text_w(st) + 8, 11), 3)
		L.text(im, st, 460, yy + 14, "gr3" if owned else ("st3" if i == 2 else "r3"), 1)
	save_mock(im, "fase6c2_tela_mural_x2.png", 2)

# ---------------------------------------------------------------- pranchas
func symbol_mock() -> void:
	var tops := ["white", "black", "gray", "blue", "green", "yellow"]
	var shorts := ["green", "blue", "black", "white", "purple", "yellow"]
	var out: Image = L.blank(6 * 52 + 8, 4 * 76 + 120)
	L.R(out, 0, 0, out.get_width(), out.get_height(), "g0")
	L.text(out, "SIMBOLO: CAMISETA / REGATA (PEITO) E SEM PARTE DE CIMA (COXA)", 2, 2, "y1", 1, "ink")
	for i in 6:
		blend(out, disc("fighter_idle_disc_layered", 0, look("skin_3", "brown", "green", "tee", tops[i])), 4 + i * 52, 12)
		blend(out, disc("fighter_idle_glove_l2_disc_layered", 0, look("skin_1", "black", "blue", "tank", tops[i], "buzz", "red")), 4 + i * 52, 86)
		blend(out, disc("fighter_idle_glove_l4_disc_layered", 0, look("skin_5", "copper", shorts[i], "none", "white", "volume", "white")), 4 + i * 52, 160)
		blend(out, disc("disciple_sit_rest", 0, look("skin_2", "blond", shorts[i], "none", "white", "bun", "none", true)), 4 + i * 52, 234)
	# luta (perfil) e folhas _left / 5 luvas da corrida
	var fl := ["fight_player_idle_disc_layered", "fight_player_jab_glove_l3_disc_layered", "fight_player_block_glove_l1_disc_layered"]
	for i in 3:
		var f := disc(fl[i], 0, look("skin_4", "dark_brown", "purple", "tee" if i != 1 else "none", "black"))
		blend(out, f.get_region(Rect2i(20, 0, 80, 104)), 4 + i * 82, 306)
	var gl := ["", "_glove_l1", "_glove_l2", "_glove_l3", "_glove_l4"]
	for i in 2:
		blend(out, disc("disciple_walk_bare_left", 1, look("skin_3", "brown", "white", "tee" if i == 0 else "none", "blue")), 250 + i * 34, 330)
	save_mock(out, "fase6c2_simbolo_x3.png", 3)
	var run: Image = L.blank(5 * 50 + 4, 80)
	L.R(run, 0, 0, run.get_width(), 80, "g0")
	for i in 5:
		blend(run, disc("fighter_run" + gl[i] + "_disc_layered", 2, look("skin_3", "brown", "green", "tee", "white")), 2 + i * 50, 4)
	save_mock(run, "fase6c2_simbolo_luvas_x4.png", 4)

func busts_mock() -> void:
	var bl := bust_layers()
	var cuts := ["short", "buzz", "volume", "bun"]
	var skins := ["skin_1", "skin_2", "skin_3", "skin_4", "skin_5"]
	var hairs := ["blond", "copper", "black", "dark_brown", "platinum"]
	var bands := ["none", "red", "white", "black", "blue"]
	var tops := [["tee", "white"], ["tank", "black"], ["none", "white"], ["tee", "yellow"], ["tank", "green"]]
	var cw := 62 + 6
	var out: Image = L.blank(5 * cw + 6, 4 * 72 + 26)
	L.R(out, 0, 0, out.get_width(), out.get_height(), "d1")
	L.text(out, "BUSTO DO MURAL (2X): 4 CORTES X 5 PELES, FAIXA E PARTE DE CIMA. ULTIMA COLUNA: JOHN", 2, 2, "y1", 1, "ink")
	for r in 4:
		for c in 5:
			var lk := look(skins[c], hairs[(c + r) % 5], "green", tops[(c + r) % 5][0], tops[(c + r) % 5][1], cuts[r], bands[(c + 2 * r) % 5])
			var b: Image = john_bust() if (c == 4 and r == 3) else bust(lk, bl)
			blend(out, portrait_card(b, c == 4 and r == 3, (c + r) % 2 == 0), 4 + c * cw, 14 + r * 72)
	save_mock(out, "fase6c2_retratos_x2.png", 2)

func pieces_mock() -> void:
	var out: Image = L.blank(300, 190)
	L.R(out, 0, 0, 300, 190, "g0")
	L.text(out, "MURAL 1/3/6/10 FOTOS: GARAGEM E ACADEMIA", 2, 2, "y1", 1, "ink")
	for q in 4:
		blend(out, mural_board(MURAL_FRAMES[q], false), 4 + q * 60, 12)
		blend(out, mural_board(MURAL_FRAMES[q], true), 4 + q * 60, 38)
	L.text(out, "MOLDURA, MOLDURA DO JOHN, SELO, HONRA 9/16, PLAQUINHA", 2, 66, "y1", 1, "ink")
	blend(out, portrait_frame(false), 4, 76)
	blend(out, portrait_frame(true), 70, 76)
	blend(out, rosette(20), 138, 76)
	blend(out, honor_icon_9(), 164, 76)
	blend(out, rosette(16), 178, 76)
	nine(out, honor_chip(), Rect2i(200, 76, 60, 11), 3)
	L.text(out, "+12 HONRA", 206, 78, "st3", 1)
	L.text(out, "HALL: COR / CINZA", 138, 104, "y1", 1, "ink")
	for i in 6:
		blend(out, hall_icon(HALL[i]), 138 + i * 18, 114)
		blend(out, gray(hall_icon(HALL[i])), 138 + i * 18, 134)
	save_mock(out, "fase6c2_pecas_x4.png", 4)

# ---------------------------------------------------------------- manifest
func manifest_write(sym_bases: Array) -> void:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest ilegível; nada gravado")
		return
	var doc: Dictionary = j.data
	var S: Dictionary = doc.sprites
	var LY: Dictionary = doc.layout
	var D := "res://assets/sprites/"
	# pontos
	LY["mural_spot"] = [MURAL_POS.x, MURAL_POS.y]
	LY["gym_mural_spot"] = [MURAL_POS.x, MURAL_POS.y]
	var info := {"anchor": "canto de cima à esquerda", "size": [MURAL_SIZE.x, MURAL_SIZE.y], "click_rect": [MURAL_POS.x, MURAL_POS.y, 54, 22],
		"layer": "wall", "z": -45, "object_text": "mural",
		"frame_by_roster": {"rule": "quadro = o maior i com roster.size() >= min_entries[i]", "min_entries": MURAL_COUNT_MIN, "photos_drawn": MURAL_FRAMES},
		"_nota": "Fase 6c2 (Diretor de Arte, direcao-visual §26). Abaixo da prateleira, à esquerda do saco de lado (x 238..278) e da corrente (x 257), fora da faixa do alvo (273..370), acima da cabeça do Osmar (y 174) e longe da foto. O balão do Osmar passa por cima (aceito, como na foto da academia)."}
	var ig := info.duplicate(true)
	ig["location"] = "garage"
	ig["sprite"] = "wall_mural"
	ig["requires_milestone"] = ""
	LY["mural_spot_info"] = ig
	var iy := info.duplicate(true)
	iy["location"] = "gym"
	iy["sprite"] = "wall_mural_gym"
	iy["requires_milestone"] = "cena_primeira_academia"
	iy["_nota"] = str(info._nota) + " Na academia cobre inteiro o quadro de cortiça pintado no gym_bg (178..227, 128..145): o mural da escola toma o lugar do quadro da mensalidade. Foto reta em (212,158), 8 px abaixo."
	LY["gym_mural_spot_info"] = iy
	S["wall_mural"] = {"file": D + "garage/wall_mural.png", "frame_size": [MURAL_SIZE.x, MURAL_SIZE.y], "frames": 4, "fps": 0.0, "pivot": [0, 0],
		"pos": [MURAL_POS.x, MURAL_POS.y], "point": "mural_spot", "layer": "wall", "z": -45, "loop": false,
		"note": "Fase 6c2: MURAL DA ESCOLA na garagem (moldura de madeira, cortiça escura, papel com o carimbo da escola e polaroides presas com alfinete; a 1ª é o John, em sépia; as de quem saiu por cima têm 1 px de prata no pé). Quadro por quantidade de entradas no roster: ver layout.mural_spot_info.frame_by_roster. Recortado sobre o garage_bg com a luz da lâmpada (não mover). Clique/hover: object_text 'mural'."}
	S["wall_mural_gym"] = {"file": D + "gym/wall_mural_gym.png", "frame_size": [MURAL_SIZE.x, MURAL_SIZE.y], "frames": 4, "fps": 0.0, "pivot": [0, 0],
		"pos": [MURAL_POS.x, MURAL_POS.y], "point": "gym_mural_spot", "layer": "wall", "z": -45, "loop": false,
		"note": "Fase 6c2: o mesmo mural na academia (luz dos tubos), recortado sobre o gym_bg: cobre o quadro de cortiça pintado. Mesmos quadros do wall_mural."}
	S["ui_mural_portrait_frame"] = {"file": D + "ui/mural/ui_mural_portrait_frame.png", "frame_size": [62, 66], "frames": 1, "fps": 0.0, "pivot": [0, 0],
		"hole": [3, 3, PORTRAIT.x, PORTRAIT.y], "note": "Moldura de madeira do retrato no MURAL. Furo 56x60 em (3,3): desenhar ui_mural_portrait_bg e o busto em 2x ali, a moldura por cima."}
	S["ui_mural_portrait_frame_first"] = {"file": D + "ui/mural/ui_mural_portrait_frame_first.png", "frame_size": [62, 66], "frames": 1, "fps": 0.0, "pivot": [0, 0],
		"hole": [3, 3, PORTRAIT.x, PORTRAIT.y], "note": "Moldura do 1º retrato (o John): madeira mais escura com cantoneiras de latão. Mesmo furo."}
	S["ui_mural_portrait_bg"] = {"file": D + "ui/mural/ui_mural_portrait_bg.png", "frame_size": [PORTRAIT.x, PORTRAIT.y], "frames": 1, "fps": 0.0, "pivot": [0, 0],
		"note": "Fundo de estúdio do retrato (d2 com halo g0 atrás da cabeça, chão d1). Igual para todos."}
	S["ui_mural_seal"] = {"file": D + "ui/mural/ui_mural_seal.png", "frame_size": [20, 24], "frames": 1, "fps": 0.0, "pivot": [0, 0],
		"anchor_on_frame": [48, 48], "note": "SELO 'saiu por cima' (honor > 0): roseta prateada com o símbolo da escola e duas fitas azuis. Canto de cima à esquerda em (48,48) da moldura 62x66 (sai 6 px para fora embaixo, à direita). A linha '+{honor} HONRA' vai em col_honor."}
	S["icon_honor"] = {"file": D + "ui/icon_honor.png", "frame_size": [9, 9], "frames": 1, "fps": 0.0, "pivot": [0, 0],
		"note": "HONRA 9x9: roseta prateada com fitas azuis da escola (a mesma do selo, pequena). Cor do número: col_honor (st3). Nunca no HUD da sala."}
	S["icon_honor_16"] = {"file": D + "ui/icon_honor_16.png", "frame_size": [16, 16], "frames": 1, "fps": 0.0, "pivot": [0, 0],
		"note": "HONRA 16x16 (tela de fim '+N HONRA', ao lado do Legado; topo do MURAL)."}
	S["ui_honor_chip"] = {"file": D + "ui/ui_honor_chip.png", "frame_size": [12, 11], "frames": 1, "fps": 0.0, "pivot": [0, 0],
		"nine_slice": {"left": 3, "top": 2, "right": 3, "bottom": 2},
		"note": "Plaquinha 9-slice da Honra (d1 com filete de aço): 'HONRA: N' ao lado do botão MURAL e o custo/estado de cada nó do hall. Texto 1x: col_honor (custo), gr3 (comprado), r3 (falta), g1 (só no fim)."}
	var hn := {"hall_box": "Fita frouxa: a caixa com a fita soltando", "hall_fund": "Vaquinha da escola: lata com a moeda entrando",
		"hall_notes": "Caderno de recordes: caderno azul com lápis", "hall_crew": "Turma da escola: três cabeças",
		"hall_glove": "Luva do mural: a luva de lona pendurada no prego", "hall_wall": "Parede maior: o mural com setas para os lados"}
	for k in HALL:
		S["icon_" + k] = {"file": D + "ui/hall/%s.png" % k, "frame_size": [16, 16], "frames": 1, "fps": 0.0, "pivot": [0, 0],
			"note": "Fase 6c2, nó do hall (16x16): %s. Comprado ou dá para comprar." % hn[k]}
		S["icon_" + k + "_gray"] = {"file": D + "ui/hall/%s_gray.png" % k, "frame_size": [16, 16], "frames": 1, "fps": 0.0, "pivot": [0, 0],
			"note": "O mesmo em cinza (falta Honra ou fora da tela de fim)."}
	# busto do mural
	var bd := D + "disciple/mural_portrait_disc_"
	S["mural_portrait_disc"] = {"file": bd + "body.png", "frame_size": [BUST.size.x, BUST.size.y], "frames": 1, "fps": 0.0, "pivot": [0, 0],
		"display_scale": 2, "crop_of": "disciple_stand_bare quadro 0, recorte (%d,%d,%d,%d) do quadro 48x72 (pivô 22,67)" % [BUST.position.x, BUST.position.y, BUST.size.x, BUST.size.y],
		"layers": {"body": bd + "body.png", "top": {"tank": bd + "top_tank.png", "tee": bd + "top_tee.png"},
			"head": {"short": bd + "head_short.png", "buzz": bd + "head_buzz.png", "volume": bd + "head_volume.png", "bun": bd + "head_bun.png"},
			"band": bd + "band.png", "front_mask": bd + "front.png", "school_symbol": {"chest": bd + "symbol_chest.png"},
			"order": ["body", "top", "school_symbol", "head", "band", "front_mask"]},
		"palette_swap": "disciple_palette", "who": "discipulo",
		"note": "Fase 6c2: BUSTO do retrato do MURAL, das camadas do discípulo (mesma montagem e troca de cor de by_data_id.disciple_palette). Mostrar em 2x (56x60) sobre ui_mural_portrait_bg, dentro de ui_mural_portrait_frame. Sem meião (não aparece). Símbolo: só o do peito, se simbolo_na_entrada(e) e look.top != 'none'; sem parte de cima o símbolo fica na coxa e não entra no busto."}
	S["mural_portrait_john"] = {"file": D + "characters/mural_portrait_john.png", "frame_size": [BUST.size.x, BUST.size.y], "frames": 1, "fps": 0.0, "pivot": [0, 0],
		"display_scale": 2, "crop_of": "john_step_back quadro 0 (sorrindo), mesmo recorte do busto do discípulo", "who": "primeiro",
		"note": "Fase 6c2: busto do John no MURAL (1º retrato, moldura ui_mural_portrait_frame_first). Nunca tem símbolo."}
	# camada do símbolo em todas as poses do discípulo
	var n := 0
	for id in S:
		var e: Dictionary = S[id]
		if not (e.has("layers") and e.get("palette_swap", "") == "disciple_palette") or id == "mural_portrait_disc":
			continue
		var lay: Dictionary = e.layers
		var body: String = lay.body
		var base: String = (lay.top.tank as String).replace("_disc_top_tank.png", "")
		var sl := {}
		for place in ["chest", "leg"]:
			var own := body.replace("_disc_body.png", "_disc_symbol_" + place + ".png")
			var p: String = own if FileAccess.file_exists(res_abs(own)) else base + "_disc_symbol_" + place + ".png"
			if FileAccess.file_exists(res_abs(p)):
				sl[place] = p
		if sl.size() == 2:
			lay["school_symbol"] = sl
			lay["order"] = ["body", "top", "socks", "school_symbol", "head", "band", "front_mask"]
			n += 1
		else:
			problems.append("sem camada de símbolo: " + id)
	notes.append("school_symbol em %d entradas em camadas" % n)
	var pb: Dictionary = doc.by_data_id.disciple_palette
	pb.keys["school_symbol"] = SYM_KEYS.duplicate()
	pb.options["school_symbol"] = [{"id": "blue", "ramp": SYM_RAMPS.blue}, {"id": "yellow", "ramp": SYM_RAMPS.yellow}]
	pb["school_symbol_source"] = {"chest": {"field": "top_color", "map": SYM_CHEST}, "leg": {"field": "shorts_color", "map": SYM_LEG},
		"note": "Fase 6c2: a camada school_symbol só tem as chaves keys.school_symbol (shadow = sombra de contato do braço, base). Peito (look.top != 'none'): cor pelo top_color; coxa (sem parte de cima): pelo shorts_color, pelos mapas acima, em options.school_symbol. azul = carimbo da escola (b0/b1), amarelo = a tinta da parede (y0/y1)."}
	pb["compose"] = "Por quadro (mesmo tamanho e pivô), na ordem de layers.order: 1) body; 2) top.<tank|tee> se look.top != 'none'; 3) socks se look.socks == 'on'; 3b) school_symbol (Fase 6c2) se o lutador mostra o símbolo (simbolo_no_lutador / simbolo_na_entrada; nunca o John): school_symbol.chest se look.top != 'none', senão school_symbol.leg; 4) head.<look.hair_style>; 5) band se look.headband != 'none'; 6) front_mask: nos pixels brancos da máscara, desenhar de novo o resultado de 1+2+3+3b (body com parte de cima, meião e símbolo), só onde ele tem cor (alfa > 0). Trocar as cores-chave em todas as camadas (antes ou depois de montar: as chaves não se repetem; as do símbolo seguem school_symbol_source). Com a máscara vazia o passo 6 não faz nada."
	var dl: Dictionary = doc.by_data_id.disciple_layers
	dl["compose"] = pb.compose
	dl.layer_keys["school_symbol"] = "derivado (Fase 6c2): chest se look.top != 'none', leg se 'none'; não vai para o look nem para o save"
	dl["school_symbol_note"] = "Fase 6c2 (Diretor de Arte): <base>_disc_symbol_chest.png e _symbol_leg.png em todas as poses, folhas _left e retrato 32x32; não dependem da luva, exceto onde a luva da frente passa no peito (fighter_run: <base>_glove_lN_disc_symbol_chest.png). layers.school_symbol de cada entrada já aponta o arquivo certo. É o school_symbol_5 da 6a (3/4) e a mesma lâmpada com raiz em 3x5 (perfil e coxa). Gerado por personagem_lib.gd (_capture_call_6b2)."
	doc.ui_tokens.colors["col_honor"] = ["st3", "a9b4bf"]
	var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(_ints(doc, ""), "\t", false).replace("\n", "\r\n"))
	fa.close()

## O Godot lê todo número do JSON como float e o JSON.stringify do 4.7 grava "640.0": volta os inteiros para int
## (no manifest só o fps é float inteiro); grava com CRLF como a cópia de trabalho, para o diff ficar só nas chaves da fase.
func _ints(v, k: String):
	if v is Dictionary:
		var o := {}
		for kk in v:
			o[kk] = _ints(v[kk], str(kk))
		return o
	if v is Array:
		return (v as Array).map(func(x): return _ints(x, k))
	if v is float and k != "fps" and is_equal_approx(v, roundf(v)) and absf(v) < 1e9:
		return int(v)
	return v

# ---------------------------------------------------------------- main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	FINAL = args.has("--final")
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	M = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	var tmp := ProjectSettings.globalize_path("res://").trim_suffix("/") + "/out/"
	OUT = (ROOT + "assets/sprites/") if FINAL else tmp
	MOCK = (ROOT + "docs/arte/mockups/") if FINAL else tmp + "mock/"
	# sprites
	for gym in [false, true]:
		var sheet: Image = L.blank(MURAL_SIZE.x * 4, MURAL_SIZE.y)
		for q in 4:
			blend(sheet, mural_board(MURAL_FRAMES[q], gym), q * MURAL_SIZE.x, 0)
		save(sheet, "gym/wall_mural_gym.png" if gym else "garage/wall_mural.png")
	save(portrait_frame(false), "ui/mural/ui_mural_portrait_frame.png")
	save(portrait_frame(true), "ui/mural/ui_mural_portrait_frame_first.png")
	save(portrait_bg(), "ui/mural/ui_mural_portrait_bg.png")
	save(rosette(20), "ui/mural/ui_mural_seal.png")
	save(honor_icon_9(), "ui/icon_honor.png")
	save(rosette(16), "ui/icon_honor_16.png")
	save(honor_chip(), "ui/ui_honor_chip.png")
	for k in HALL:
		save(hall_icon(k), "ui/hall/%s.png" % k)
		save(gray(hall_icon(k)), "ui/hall/%s_gray.png" % k)
	var bl := bust_layers()
	for k in bl:
		save(bl[k], "disciple/mural_portrait_disc_%s.png" % k)
	save(john_bust(), "characters/mural_portrait_john.png")
	# conferência
	for gym in [false, true]:
		var bad := check_mural(gym)
		for b in bad:
			problems.append(("academia: " if gym else "garagem: ") + str(b))
	# mockups
	room_mock(false)
	room_mock(true)
	screen_mock()
	symbol_mock()
	busts_mock()
	pieces_mock()
	if args.has("--manifest"):
		if problems.is_empty():
			manifest_write([])
		else:
			print("manifest NÃO gravado")
	for p in problems:
		print("PROBLEMA: ", p)
	for nn in notes:
		print(nn)
	print("ok 6c2 (%s)" % ("final" if FINAL else "prévia em " + tmp))
	quit()
