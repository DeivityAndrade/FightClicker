extends SceneTree
## Identidade visual: 3 direções (A vidro pixelado, B lona e placa de academia, C cartaz de luta). Diretor de Arte.
## MOCKUP gerado por código (placeholder), tudo original. Não grava nada em assets/ nem mexe em ui/ ou scenes/.
## Rodar de uma pasta com project.godot vazio (não dispara import no projeto), headless:
##   godot --headless --max-fps 30 --path <pasta_vazia> --script <worktree>/tools/art/make_mockup_identidade.gd -- --root <worktree>
## Grava docs/arte/mockups/identidade/identidade_{a,b,c}_{sala,janela,menu}_x2.png e identidade_comparativo.png.
## Fundo da sala = captura real do jogo (docs/arte/mockups/fase6d2_qa_tela_fechada.png, 1280x720 -> 640x360) com o HUD,
## a barra e os cartões antigos cobertos pelo garage_bg. Fonte = BMFont do projeto (assets/sprites/font/fightclicker_5x7.fnt).
## Textos = os do data/ (ui_texts.json, shop.json); o subtítulo do menu é provisório [ROT].

var ROOT := "E:/Fightclicker/.claude/worktrees/identidade-visual"
var OUT := ""

const PAL := {
	"ink": "14101a", "d1": "2a2233", "d2": "3d3346",
	"g0": "4a4552", "g1": "6b6570", "g2": "8f8890", "g3": "b8b0aa",
	"cream": "d9cdb4", "white": "f2ece0",
	"br0": "3b2622", "br1": "6b3f2a", "br2": "9a5f36", "br3": "c98a4b",
	"y0": "e0a040", "y1": "f5d26b", "y2": "fff3c4",
	"r0": "5a1a22", "r1": "9c2a2a", "r2": "d4473a", "r3": "f07a5a",
	"b0": "1f2a44", "b1": "2f4a78", "b2": "4d7bb3", "b3": "8fbbe0",
	"gr0": "1f3d33", "gr1": "2f6b4a", "gr2": "5aa25a", "gr3": "a6d86a",
	"st0": "3a4452", "st1": "5a6676", "st2": "7f8c9a", "st3": "a9b4bf",
	"p0": "4a2f6b", "p1": "7a4fa0", "p2": "b07ad8",
	"f0": "7a2a52", "f1": "d4558f", "f2": "f59ac0",
}
const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

var G := {}            # unicode -> {px: Array[Vector2i], xo, yo, adv, vw}
var cap_top := 2
var cap_h := 7
var icons := {}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--root" and i + 1 < args.size():
			ROOT = args[i + 1].replace("\\", "/")
	OUT = ROOT + "/docs/arte/mockups/identidade/"
	DirAccess.make_dir_recursive_absolute(OUT)
	_load_font()
	var sala := _room_bg()
	var rua := _img(ROOT + "/assets/sprites/minigame/ronda_bg.png")
	var lut := _img(ROOT + "/assets/sprites/characters/fighter_idle.png").get_region(Rect2i(0, 0, 48, 72))
	var tiles := {}
	for d in ["a", "b", "c"]:
		var s1: Image = sala.duplicate()
		call("sala_" + d, s1)
		var s2: Image = sala.duplicate()
		call("sala_" + d, s2)
		call("janela_" + d, s2)
		var s3: Image = rua.duplicate()
		call("menu_" + d, s3, lut)
		tiles[d] = [s1, s2, s3]
		_save_x2(s1, "identidade_%s_sala" % d)
		_save_x2(s2, "identidade_%s_janela" % d)
		_save_x2(s3, "identidade_%s_menu" % d)
	# conferência: a descrição mais longa da loja cabe antes da coluna de preço/botão (x+48 .. x+w-18-76-6)
	for it in LOJA:
		if tw(it[2]) > 380 - 48 - 20 - 76 - 6:
			print("AVISO loja: descrição longa demais: ", it[2])
	_comparativo(tiles)
	print("OK ", OUT)
	quit()


# ================================================================= base
func C(n) -> Color:
	if n is Color:
		return n
	return Color(PAL[n])


func _img(p: String) -> Image:
	var im := Image.load_from_file(p)
	if im.get_format() != Image.FORMAT_RGBA8:
		im.convert(Image.FORMAT_RGBA8)
	return im


func icon(n: String) -> Image:
	if not icons.has(n):
		var p := ROOT + "/assets/sprites/ui/" + n + ".png"
		if not FileAccess.file_exists(p):
			p = ROOT + "/assets/sprites/garage/" + n + ".png"
		icons[n] = _img(p)
	return icons[n]


func px(img: Image, x: int, y: int, c) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, C(c))


func pxa(img: Image, x: int, y: int, c, a: float) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		var o := img.get_pixel(x, y)
		var k := C(c)
		img.set_pixel(x, y, Color(lerpf(o.r, k.r, a), lerpf(o.g, k.g, a), lerpf(o.b, k.b, a), 1.0))


func rect(img: Image, x: int, y: int, w: int, h: int, c) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, C(c))


func rect_a(img: Image, x: int, y: int, w: int, h: int, c, a: float) -> void:
	for yy in h:
		for xx in w:
			pxa(img, x + xx, y + yy, c, a)


func hl(img: Image, x: int, y: int, w: int, c) -> void:
	rect(img, x, y, w, 1, c)


func vl(img: Image, x: int, y: int, h: int, c) -> void:
	rect(img, x, y, 1, h, c)


func frame(img: Image, x: int, y: int, w: int, h: int, c) -> void:
	hl(img, x, y, w, c); hl(img, x, y + h - 1, w, c); vl(img, x, y, h, c); vl(img, x + w - 1, y, h, c)


func blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))


func bayer(x: int, y: int) -> int:
	return BAYER[posmod(y, 4)][posmod(x, 4)]


## Dentro de um retângulo de cantos chanfrados (r = 0 reto, 2 = canto de 3 px, 3 = 6 px).
func inside_r(xx: int, yy: int, w: int, h: int, r: int) -> bool:
	if xx < 0 or yy < 0 or xx >= w or yy >= h:
		return false
	return mini(xx, w - 1 - xx) + mini(yy, h - 1 - yy) >= r


func is_border(xx: int, yy: int, w: int, h: int, r: int) -> bool:
	if not inside_r(xx, yy, w, h, r):
		return false
	return not (inside_r(xx - 1, yy, w, h, r) and inside_r(xx + 1, yy, w, h, r) and inside_r(xx, yy - 1, w, h, r) and inside_r(xx, yy + 1, w, h, r))


func shape(img: Image, x: int, y: int, w: int, h: int, r: int, fill, border = null) -> void:
	for yy in h:
		for xx in w:
			if inside_r(xx, yy, w, h, r):
				px(img, x + xx, y + yy, border if (border != null and is_border(xx, yy, w, h, r)) else fill)


func dim_dither(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if (x + y) % 2 == 0:
				img.set_pixel(x, y, C("ink"))


func dim_alpha(img: Image, a: float, c = "ink") -> void:
	for y in img.get_height():
		for x in img.get_width():
			pxa(img, x, y, c, a)


# ================================================================= fonte (BMFont do projeto)
func _load_font() -> void:
	var fimg := _img(ROOT + "/assets/sprites/font/fightclicker_5x7.png")
	var f := FileAccess.open(ROOT + "/assets/sprites/font/fightclicker_5x7.fnt", FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_line()
		if not line.begins_with("char "):
			continue
		var kv := {}
		for part in line.split(" ", false):
			var e := part.split("=")
			if e.size() == 2:
				kv[e[0]] = int(e[1])
		var pl: Array = []
		var vw := 0
		for gy in kv.height:
			for gx in kv.width:
				if fimg.get_pixel(kv.x + gx, kv.y + gy).a > 0.5:
					pl.append(Vector2i(gx, gy))
					vw = maxi(vw, gx + 1)
		G[kv.id] = {"px": pl, "xo": kv.xoffset, "yo": kv.yoffset, "adv": kv.xadvance, "vw": vw}
	# altura das maiúsculas medida no H
	var hy0 := 99
	var hy1 := -1
	for p in G[72].px:
		hy0 = mini(hy0, p.y + G[72].yo)
		hy1 = maxi(hy1, p.y + G[72].yo)
	cap_top = hy0
	cap_h = hy1 - hy0 + 1


func _g(code: int) -> Dictionary:
	return G.get(code, G[63])


func tw(s: String, sc := 1) -> int:
	var w := 0
	for i in s.length():
		var g := _g(s.unicode_at(i))
		w += (g.xo + g.vw) if i == s.length() - 1 else g.adv
	return w * sc


## Texto com o topo das maiúsculas em `ycap`. `sh` = deslocamento da sombra (Vector2i) ou null.
func tx(img: Image, s: String, x: int, ycap: int, c, sc := 1, sh = null, shc = "ink") -> int:
	if sh != null:
		tx(img, s, x + sh.x, ycap + sh.y, shc, sc)
	var pen := 0
	for i in s.length():
		var g := _g(s.unicode_at(i))
		for p in g.px:
			rect(img, x + (pen + g.xo + p.x) * sc, ycap + (g.yo + p.y - cap_top) * sc, sc, sc, c)
		pen += g.adv
	return tw(s, sc)


## Contorno de 1 px (8 vizinhos) em volta do texto.
func tx_o(img: Image, s: String, x: int, ycap: int, c, oc = "ink", sc := 1) -> void:
	for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
		tx(img, s, x + d.x, ycap + d.y, oc, sc)
	tx(img, s, x, ycap, c, sc)


func ycap_in(y: int, h: int, sc := 1) -> int:
	return y + int(floor((h - cap_h * sc) / 2.0))


## Conteúdo centralizado (ícone opcional + texto) num retângulo: regra do alinhamento (texto e grupo no meio).
func content_c(img: Image, x: int, y: int, w: int, h: int, s: String, c, sc := 1, ic = null, gap := 4, sh = null, shc = "ink") -> void:
	var iw := 0
	var ih := 0
	if ic != null:
		iw = (ic as Image).get_width()
		ih = (ic as Image).get_height()
	var gw := tw(s, sc) + (iw + gap if ic != null and s != "" else iw)
	var x0 := x + int(floor((w - gw) / 2.0))
	if gw > w - 4 or (s != "" and cap_h * sc > h - 4):
		print("AVISO alinhamento: '%s' não cabe com folga em %dx%d" % [s, w, h])
	if ic != null:
		blit(img, ic, x0, y + int(floor((h - ih) / 2.0)))
		x0 += iw + (gap if s != "" else 0)
	if s != "":
		tx(img, s, x0, ycap_in(y, h, sc), c, sc, sh, shc)


# ================================================================= logo (mesma fonte, ampliada e tratada)
## Máscara do texto em 1x (só as linhas das maiúsculas).
func logo_mask(s: String) -> Image:
	var m := Image.create(tw(s) + 2, cap_h, false, Image.FORMAT_RGBA8)
	tx(m, s, 0, 0, "white")
	return m


## Camada do logo: escala `sc`, `bold` engorda 1 px à direita, `shear` = quantas linhas por 1 px de itálico (0 = reto).
func logo_layer(s: String, sc: int, bold := false, shear := 0) -> Image:
	var m := logo_mask(s)
	var hh := cap_h * sc
	var extra := (hh / shear + 1) if shear > 0 else 0
	var L := Image.create(m.get_width() * sc + 2 + extra, hh, false, Image.FORMAT_RGBA8)
	for my in m.get_height():
		for mx in m.get_width():
			if m.get_pixel(mx, my).a < 0.5:
				continue
			for yy in sc:
				var Y := my * sc + yy
				var off := ((hh - 1 - Y) / shear) if shear > 0 else 0
				for xx in sc + (1 if bold else 0):
					L.set_pixel(mx * sc + xx + off, Y, Color.WHITE)
	return L


func layer_put(img: Image, L: Image, x: int, y: int, c, dx := 0, dy := 0) -> void:
	for yy in L.get_height():
		for xx in L.get_width():
			if L.get_pixel(xx, yy).a > 0.5:
				px(img, x + xx + dx, y + yy + dy, c)


func layer_outline(img: Image, L: Image, x: int, y: int, c, t := 1) -> void:
	for d in range(-t, t + 1):
		for e in range(-t, t + 1):
			if d != 0 or e != 0:
				layer_put(img, L, x, y, c, d, e)


# ================================================================= fundos
func _room_bg() -> Image:
	var cap := _img(ROOT + "/docs/arte/mockups/fase6d2_qa_tela_fechada.png")
	var bg := _img(ROOT + "/assets/sprites/garage/garage_bg.png")
	var o := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	for y in 360:
		for x in 640:
			o.set_pixel(x, y, cap.get_pixel(x * 2, y * 2))
	# cobre a UI antiga (HUD, barra, cartões da esquerda e aba da direita) com o fundo limpo da garagem
	for r in [Rect2i(0, 0, 640, 19), Rect2i(0, 326, 640, 34), Rect2i(0, 18, 143, 98), Rect2i(612, 118, 28, 64)]:
		o.blit_rect(bg, r, r.position)
	return o


func _save_x2(img: Image, nome: String) -> void:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	b.save_png(OUT + nome + "_x2.png")


# ================================================================= conteúdo comum (dados de exemplo iguais nas 3)
const T_TREINO := "TREINO"
const V_TREINO := "3.00K"
const V_PS := "+0/S"
const V_MONEY := "$ 5.00K"
const V_CARREIRA := "JOHN BULLET"
const V_LOCAL := "FUNDO DE GARAGEM"
const FOCOS := [["SACO", "icon_strength", "ativo"], ["ESTEIRA", "mark_padlock", "compravel"], ["CORDA", "mark_padlock", "trancado"]]
const X_FOCO := 92
const PASSO := 90
const LARG := 86
const LOJA := [
	["icon_glove_l2", "Luva de couro", "Costura dupla. Os dedos agradecem.", "CLIQUE x2", "$ 500", "COMPRAR"],
	["icon_coach", "Prof. Nelson", "Cobra por hora e confere o relógio.", "+25/S", "$ 50", "CONTRATAR"],
	["icon_metronome_l1", "Pêndulo lento", "Preguiçoso, mas não perde a hora.", "1 SOCO A CADA 1.2 S", "$ 80", "COMPRAR"],
]
const MENU := ["CONTINUAR", "NOVO JOGO", "OPÇÕES", "SAIR"]
const SUB_MENU := "UM SOCO DE CADA VEZ"  # [ROT] provisório


## Conteúdo do HUD em linha. cores = {lab, treino, money, fame, legacy, txt, txt2, sep}. Devolve x final.
func hud_left(img: Image, x: int, cores: Dictionary, sep: Callable) -> int:
	blit(img, icon("icon_treino"), x, 5)
	x += 12
	x += tx(img, T_TREINO, x, 6, cores.lab) + 5
	x += tx(img, V_TREINO, x, 2, cores.treino, 2) + 4
	x += tx(img, V_PS, x, 6, cores.treino2) + 7
	sep.call(x - 4)
	x += 4
	blit(img, icon("icon_money"), x, 5)
	x += 12
	x += tx(img, V_MONEY, x, 6, cores.money) + 7
	sep.call(x - 4)
	x += 4
	x += tx(img, V_CARREIRA, x, 6, cores.txt2)
	return x


func hud_right(img: Image, xr: int, cores: Dictionary, sep: Callable) -> int:
	# da direita para a esquerda: legado 0, fama 0, local
	var x := xr - tw("0")
	tx(img, "0", x, 6, cores.legacy)
	x -= 11
	blit(img, icon("icon_legacy"), x, 5)
	x -= 4 + tw("0")
	tx(img, "0", x, 6, cores.fame)
	x -= 11
	blit(img, icon("icon_fame"), x, 5)
	x -= 7
	sep.call(x + 3)
	x -= tw(V_LOCAL)
	tx(img, V_LOCAL, x, 6, cores.txt2)
	return x


# =================================================================================================== A: VIDRO
const A_TINT := "b0"
const A_ALPHA := 0.62


## Vidro: tinta azul-asfalto com alfa, borda de luz (branco em cima, b3 nos lados), reflexo diagonal em 2 filetes,
## sombra de 1 px. Sem blur: o que lê como vidro é a borda clara e o reflexo.
func glass(img: Image, x: int, y: int, w: int, h: int, r := 2, tint = A_TINT, a := A_ALPHA, edge = "b3", glint := true) -> void:
	for yy in h:
		for xx in w:
			if not inside_r(xx, yy, w, h, r):
				continue
			var X := x + xx
			var Y := y + yy
			pxa(img, X, Y, tint, a)
			if glint:
				# reflexo: 2 filetes diagonais (3 px e 1 px) + gelo em dither Bayer (o "fosco" sem blur)
				var k := posmod(xx - yy * 2 - 18, 160)
				if k < 3 or k == 6:
					pxa(img, X, Y, "white", 0.13)
				if bayer(X, Y) == 0:
					pxa(img, X, Y, "b3", 0.16)
			if is_border(xx, yy, w, h, r):
				if yy <= r and yy < h / 2:
					pxa(img, X, Y, "white", 0.85)
				elif yy >= h - 1 - r:
					pxa(img, X, Y, edge, 0.35)
				else:
					pxa(img, X, Y, edge, 0.6)
			elif yy == 1 or (yy == 2 and r >= 2 and inside_r(xx, yy - 2, w, h, r) == false):
				pxa(img, X, Y, "white", 0.14)
	for xx in range(r, w - r):
		pxa(img, x + xx, y + h, "ink", 0.45)


func sala_a(img: Image) -> void:
	var cores := {"lab": "b3", "treino": "gr3", "treino2": "gr3", "money": "y1", "fame": "f2", "legacy": "p2", "txt": "white", "txt2": "cream"}
	# HUD: duas cápsulas flutuantes
	var wl := 0
	var tmp := Image.create(640, 20, false, Image.FORMAT_RGBA8)
	wl = hud_left(tmp, 9, cores, func(_x): pass) + 7
	glass(img, 2, 1, wl - 2, 17)
	var sep := func(xs): vl(img, xs, 4, 11, Color(C("b3"), 1.0).lerp(C(A_TINT), 0.55))
	hud_left(img, 9, cores, sep)
	var xl := hud_right(tmp, 630, cores, func(_x): pass)
	glass(img, xl - 7, 1, 640 - 2 - (xl - 7), 17)
	hud_right(img, 630, cores, sep)
	# cartões da esquerda
	_cards_a(img)
	# aba da direita
	glass(img, 615, 121, 22, 56)
	_tab_content(img, 615, 121, "white", "b3")
	# DOCA de baixo
	glass(img, 2, 331, 636, 27, 3)
	tx(img, "+1", 9, 337, "gr3", 2)
	tx(img, "/CLIQUE", 9 + tw("+1", 2) + 1, 344, "b3")
	for i in FOCOS.size():
		var f: Array = FOCOS[i]
		var x: int = X_FOCO + i * PASSO
		match f[2]:
			"ativo":
				glass(img, x, 335, LARG, 20, 2, "r1", 0.88, "r3")
				content_c(img, x, 335, LARG, 20, f[0], "white", 1, icon(f[1]))
			"compravel":
				glass(img, x, 335, LARG, 20, 2, "b1", 0.55, "y1", false)
				frame_r(img, x - 1, 334, LARG + 2, 22, 2, "y2", 0.8)
				content_c(img, x, 335, LARG, 20, f[0], "white", 1, icon(f[1]))
			_:
				glass(img, x, 335, LARG, 20, 2, "ink", 0.35, "g2", false)
				content_c(img, x, 335, LARG, 20, f[0], "g2", 1, icon(f[1]))
	tx(img, "CLIQUE NO SACO", 366, 337, "cream")
	tx(img, "PARA TREINAR", 366, 347, "cream")
	glass(img, 464, 337, 18, 17, 2, "b1", 0.6)
	content_c(img, 464, 337, 18, 17, "", "white", 1, icon("icon_assist_wait"))
	glass(img, 486, 337, 17, 17, 2, "b1", 0.6)
	content_c(img, 486, 337, 17, 17, "?", "white")
	glass(img, 507, 333, 102, 23, 3, "r2", 0.9, "r3")
	content_c(img, 507, 333, 102, 23, "LUTAR!", "white", 2, null, 0, Vector2i(0, 1), "r0")
	glass(img, 613, 334, 22, 22, 2, "p0", 0.8, "p2")
	content_c(img, 613, 334, 22, 22, "", "white", 1, icon("icon_pass_post"))


## Contorno de cantos chanfrados com alfa (destaque do "comprável").
func frame_r(img: Image, x: int, y: int, w: int, h: int, r: int, c, a: float) -> void:
	for yy in h:
		for xx in w:
			if is_border(xx, yy, w, h, r):
				pxa(img, x + xx, y + yy, c, a)


func _tab_content(img: Image, x: int, y: int, c, c2) -> void:
	blit(img, icon("icon_treino"), x + 3, y + 6)
	tx(img, "4", x + 14, y + 7, "gr3")
	blit(img, icon("icon_money"), x + 3, y + 21)
	tx(img, "4", x + 14, y + 22, "y1")
	tx(img, "<", x + 9, y + 40, c2)


const ATR := [["icon_strength", "r2", "317", 0.8], ["icon_agility", "b3", "60", 0.3], ["icon_endurance", "y0", "200", 0.55]]


func _attr_rows(img: Image, x: int, y: int, track, val_c, fill_override := {}) -> void:
	for i in ATR.size():
		var a: Array = ATR[i]
		var yy := y + i * 12
		blit(img, icon(a[0]), x, yy)
		rect(img, x + 13, yy + 3, 62, 4, track)
		rect(img, x + 13, yy + 3, int(62 * a[3]), 4, fill_override.get(i, a[1]))
		hl(img, x + 13, yy + 3, int(62 * a[3]), C(fill_override.get(i, a[1])).lightened(0.25))
		var v: String = a[2]
		tx(img, v, x + 100 - tw(v), yy + 1, val_c)


func _cards_a(img: Image) -> void:
	glass(img, 3, 21, 112, 42)
	_attr_rows(img, 8, 26, Color(C("ink"), 1).lerp(C("b0"), 0.5), "white")
	glass(img, 119, 21, 22, 22)
	content_c(img, 119, 21, 22, 22, "", "white", 1, icon("icon_glove_l1"))
	glass(img, 3, 67, 124, 46)
	blit(img, icon("icon_calendar"), 9, 72)
	tx(img, "FALTAM 12 DIAS", 24, 74, "white")
	tx(img, "DUDU ALONGADO", 24, 84, "b3")
	glass(img, 28, 95, 74, 14, 2, "r1", 0.85, "r3")
	content_c(img, 28, 95, 74, 14, "PERIGOSO", "white", 1, icon("icon_risk_hard"))


func janela_a(img: Image) -> void:
	dim_alpha(img, 0.55)
	var x := 130
	var y := 60
	var w := 380
	var h := 240
	glass(img, x, y, w, h, 3, "b0", 0.88)  # janela = vidro mais fosco que o HUD (texto longo por cima da sala)
	# título
	tx(img, "LOJA", x + 12, y + 10, "white", 2)
	tx(img, "Dinheiro de luta, só aqui.", x + 12, y + 29, "b3")
	blit(img, icon("icon_money"), x + w - 12 - tw(V_MONEY) - 12, y + 13)
	tx(img, V_MONEY, x + w - 12 - tw(V_MONEY), y + 14, "y1")
	hl(img, x + 8, y + 42, w - 16, Color(C("b3")).lerp(C("b0"), 0.5))
	for i in LOJA.size():
		var it: Array = LOJA[i]
		var ry := y + 50 + i * 50
		glass(img, x + 8, ry, w - 16, 44, 2, "b1", 0.35, "b2", false)
		glass(img, x + 14, ry + 8, 26, 26, 2, "ink", 0.35, "b2", false)
		content_c(img, x + 14, ry + 8, 26, 26, "", "white", 1, icon(it[0]))
		tx(img, it[1].to_upper(), x + 48, ry + 8, "white")
		tx(img, it[2], x + 48, ry + 19, "b3")
		tx(img, it[3], x + 48, ry + 30, "gr3")
		# preço + botão (fileira igual: mesmas larguras nas 3 linhas)
		var bx := x + w - 16 - 76
		glass(img, bx, ry + 20, 76, 18, 2, "r2", 0.88, "r3")
		content_c(img, bx, ry + 20, 76, 18, it[5], "white")
		content_c(img, bx, ry + 6, 76, 11, it[4], "y1", 1, icon("icon_money"), 3)
	var fx := x + (w - 90) / 2
	glass(img, fx, y + h - 30, 90, 20, 2, "b1", 0.6)
	content_c(img, fx, y + h - 30, 90, 20, "FECHAR", "white")


func menu_a(img: Image, lut: Image) -> void:
	dim_alpha(img, 0.30, "b0")
	blit(img, lut, 170 - 22, 312 - 67)
	# logo: letras brancas com borda de luz b3 embaixo, contorno ink, faixa vermelha do vulto atravessando atrás
	var L := logo_layer("FIGHTCLICKER", 4, true)
	var lx := (640 - L.get_width()) / 2
	var ly := 40
	# placa de vidro do logo
	glass(img, lx - 16, ly - 12, L.get_width() + 32, L.get_height() + 44, 3, "b0", 0.6)
	rect(img, lx - 16 + 3, ly + L.get_height() + 9, L.get_width() + 32 - 6, 3, "r2")
	hl(img, lx - 16 + 3, ly + L.get_height() + 9, L.get_width() + 32 - 6, "r3")
	hl(img, lx - 16 + 3, ly + L.get_height() + 11, L.get_width() + 32 - 6, "r1")
	layer_outline(img, L, lx, ly, "ink")
	layer_put(img, L, lx, ly, "b3")
	layer_put(img, L, lx, ly - 1, "white")
	var sw := tw(SUB_MENU)
	tx(img, SUB_MENU, 320 - sw / 2, ly + L.get_height() + 15 + 2, "cream")
	# botões
	var bw := 140
	var bh := 22
	var bx := 320 - bw / 2
	glass(img, bx - 12, 160, bw + 24, 4 * 28 + 16, 3, "b0", 0.55)
	for i in MENU.size():
		var by := 170 + i * 28
		if i == 0:
			glass(img, bx, by, bw, bh, 2, "r2", 0.9, "r3")
		else:
			glass(img, bx, by, bw, bh, 2, "b1", 0.55)
		content_c(img, bx, by, bw, bh, MENU[i], "white", 1)
	tx(img, "v0.8", 634 - tw("v0.8"), 350, "b3")


# =================================================================================================== B: LONA E PLACA
## Lona: creme com trama em dither (g3), bainha costurada em cima e embaixo, sombra no que fica atrás.
func lona(img: Image, x: int, y: int, w: int, h: int, base = "cream", trama = "g3", hem := true) -> void:
	rect(img, x, y, w, h, base)
	for yy in h:
		for xx in w:
			var b := bayer(x + xx, y + yy)
			if b == 0 or ((x + xx) % 3 == 0 and (y + yy) % 4 == 1 and b < 6):
				px(img, x + xx, y + yy, trama)
	if hem:
		hl(img, x, y, w, "white")
		hl(img, x, y + h - 1, w, "g2")
		for xx in range(x + 3, x + w - 3, 4):
			hl(img, xx, y + 2, 2, "g2")
			hl(img, xx, y + h - 3, 2, "g2")
	vl(img, x, y, h, "white")
	vl(img, x + w - 1, y, h, "g2")


## Ilhós: anel de aço 5x5 com furo ink.
func ilhos(img: Image, cx: int, cy: int) -> void:
	for d in [Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -2), Vector2i(-2, -1), Vector2i(-2, 0), Vector2i(-2, 1), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, -1), Vector2i(2, 0), Vector2i(2, 1)]:
		px(img, cx + d.x, cy + d.y, "st3" if d.y < 0 or d.x < 0 else "st1")
	for d in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
		px(img, cx + d.x, cy + d.y, "st2")
	px(img, cx, cy, "ink")


## Placa pintada (chapa azul de carimbo com parafusos e pinceladas).
func placa(img: Image, x: int, y: int, w: int, h: int, base = "b1", lo = "b0", hi = "b2", screws := true) -> void:
	rect(img, x, y, w, h, base)
	for yy in h:
		for xx in w:
			if (yy + (xx / 23) % 3) % 5 == 0 and bayer(x + xx, y + yy) < 5:
				px(img, x + xx, y + yy, lo)
	hl(img, x, y, w, hi)
	hl(img, x, y + h - 1, w, lo)
	if screws:
		for p in [Vector2i(x + 3, y + 3), Vector2i(x + w - 4, y + 3), Vector2i(x + 3, y + h - 4), Vector2i(x + w - 4, y + h - 4)]:
			px(img, p.x, p.y, "st3"); px(img, p.x + 1, p.y, "st1"); px(img, p.x, p.y + 1, "st1"); px(img, p.x + 1, p.y + 1, "st0")


## Fita: tira com as pontas rasgadas (dente de 1 px alternado).
func fita(img: Image, x: int, y: int, w: int, h: int, base, hi, lo) -> void:
	for yy in h:
		var cut_l := 1 if yy % 3 == 1 else 0
		var cut_r := 1 if yy % 3 == 2 else 0
		hl(img, x + cut_l, y + yy, w - cut_l - cut_r, base)
	hl(img, x + 1, y, w - 2, hi)
	hl(img, x + 1, y + h - 1, w - 2, lo)


func sala_b(img: Image) -> void:
	# HUD: lona esticada com ilhoses e abraçadeira subindo
	for x in 640:
		pxa(img, x, 18, "ink", 0.5)
		if x % 2 == 0:
			pxa(img, x, 19, "ink", 0.35)
	lona(img, 0, 0, 640, 18)
	var cores := {"lab": "b1", "treino": "gr1", "treino2": "gr1", "money": "br1", "fame": "f0", "legacy": "p0", "txt": "ink", "txt2": "b1"}
	var sep := func(xs):
		rect(img, xs - 1, 0, 3, 18, "r2"); vl(img, xs - 1, 0, 18, "r3"); vl(img, xs + 1, 0, 18, "r1")
	hud_left(img, 9, cores, sep)
	hud_right(img, 630, cores, sep)
	for xi in [3, 636]:
		ilhos(img, xi, 9)
	# cartões: lona pendurada
	_cards_b(img)
	# aba da direita: placa
	placa(img, 615, 121, 22, 56)
	_tab_content(img, 615, 121, "white", "b3")
	# BARRA: placa pintada azul de carimbo
	hl(img, 0, 329, 640, "ink")
	placa(img, 0, 330, 640, 30)
	tx(img, "+1", 9, 337, "gr3", 2, Vector2i(1, 1), "b0")
	tx(img, "/CLIQUE", 9 + tw("+1", 2) + 2, 344, "b3")
	for i in FOCOS.size():
		var f: Array = FOCOS[i]
		var x: int = X_FOCO + i * PASSO
		match f[2]:
			"ativo":
				fita(img, x, 335, LARG, 20, "r2", "r3", "r1")
				content_c(img, x, 335, LARG, 20, f[0], "white", 1, icon(f[1]), 4, Vector2i(0, 1), "r0")
			"compravel":
				frame(img, x - 1, 334, LARG + 2, 22, "y1")
				fita(img, x, 335, LARG, 20, "cream", "white", "g3")
				content_c(img, x, 335, LARG, 20, f[0], "ink", 1, icon(f[1]))
			_:
				fita(img, x, 335, LARG, 20, "g1", "g2", "g0")
				content_c(img, x, 335, LARG, 20, f[0], "d2", 1, icon(f[1]))
	tx(img, "CLIQUE NO SACO", 366, 337, "cream")
	tx(img, "PARA TREINAR", 366, 347, "cream")
	fita(img, 464, 337, 18, 17, "cream", "white", "g3")
	content_c(img, 464, 337, 18, 17, "", "ink", 1, icon("icon_assist_wait"))
	fita(img, 486, 337, 17, 17, "cream", "white", "g3")
	content_c(img, 486, 337, 17, 17, "?", "ink")
	# LUTAR: letreiro vermelho pintado com parafusos
	frame(img, 506, 332, 104, 26, "ink")
	placa(img, 507, 333, 102, 24, "r2", "r1", "r3")
	content_c(img, 507, 333, 102, 24, "LUTAR!", "white", 2, null, 0, Vector2i(1, 1), "r0")
	frame(img, 612, 333, 24, 24, "ink")
	lona(img, 613, 334, 22, 22, "cream", "g3", false)
	content_c(img, 613, 334, 22, 22, "", "white", 1, icon("icon_pass_post"))


func _cards_b(img: Image) -> void:
	for r in [Rect2i(3, 21, 112, 42), Rect2i(119, 21, 22, 22), Rect2i(3, 67, 124, 46)]:
		for xx in range(r.position.x + 2, r.end.x + 1):
			pxa(img, xx, r.end.y, "ink", 0.5)
		for yy in range(r.position.y + 2, r.end.y + 1):
			pxa(img, r.end.x, yy, "ink", 0.5)
		lona(img, r.position.x, r.position.y, r.size.x, r.size.y)
	ilhos(img, 7, 25); ilhos(img, 111, 25)
	_attr_rows(img, 12, 30, "g3", "ink", {1: "b1"})
	placa(img, 119, 21, 22, 22, "b1", "b0", "b2", false)
	content_c(img, 119, 21, 22, 22, "", "white", 1, icon("icon_glove_l1"))
	ilhos(img, 7, 71); ilhos(img, 123, 71)
	blit(img, icon("icon_calendar"), 13, 75)
	tx(img, "FALTAM 12 DIAS", 28, 77, "ink")
	tx(img, "DUDU ALONGADO", 28, 87, "b1")
	fita(img, 26, 97, 78, 13, "r2", "r3", "r1")
	content_c(img, 26, 97, 78, 13, "PERIGOSO", "white", 1, icon("icon_risk_hard"))


func janela_b(img: Image) -> void:
	dim_dither(img)
	var x := 130
	var y := 58
	var w := 380
	var h := 244
	# cordas saindo dos ilhoses para fora da janela
	for p in [[Vector2i(x + 6, y + 6), Vector2i(x - 30, y - 40)], [Vector2i(x + w - 7, y + 6), Vector2i(x + w + 30, y - 40)],
			[Vector2i(x + 6, y + h - 7), Vector2i(x - 30, y + h + 40)], [Vector2i(x + w - 7, y + h - 7), Vector2i(x + w + 30, y + h + 40)]]:
		_rope(img, p[0], p[1])
	for xx in range(x + 3, x + w + 3):
		pxa(img, xx, y + h, "ink", 0.6)
		pxa(img, xx, y + h + 1, "ink", 0.4)
	for yy in range(y + 3, y + h + 2):
		pxa(img, x + w, yy, "ink", 0.6)
	lona(img, x, y, w, h)
	for p in [Vector2i(x + 6, y + 6), Vector2i(x + w - 7, y + 6), Vector2i(x + 6, y + h - 7), Vector2i(x + w - 7, y + h - 7), Vector2i(x + w / 2, y + 6)]:
		ilhos(img, p.x, p.y)
	# letreiro do título: fita vermelha atravessada com o nome pintado
	fita(img, x + 14, y + 13, 92, 22, "r2", "r3", "r1")
	content_c(img, x + 14, y + 13, 92, 22, "LOJA", "white", 2, null, 0, Vector2i(1, 1), "r0")
	tx(img, "Dinheiro de luta, só aqui.", x + 114, y + 21, "b1")
	blit(img, icon("icon_money"), x + w - 14 - tw(V_MONEY) - 12, y + 41)
	tx(img, V_MONEY, x + w - 14 - tw(V_MONEY), y + 42, "br1")
	for i in LOJA.size():
		var it: Array = LOJA[i]
		var ry := y + 54 + i * 50
		for xx in range(x + 10, x + w - 10, 3):
			hl(img, xx, ry - 3, 2, "g2")
		placa(img, x + 14, ry + 7, 26, 26, "b1", "b0", "b2", false)
		content_c(img, x + 14, ry + 7, 26, 26, "", "white", 1, icon(it[0]))
		tx(img, it[1].to_upper(), x + 48, ry + 7, "ink")
		tx(img, it[2], x + 48, ry + 18, "g0")
		tx(img, it[3], x + 48, ry + 29, "gr1")
		var bx := x + w - 18 - 76
		fita(img, bx, ry + 20, 76, 18, "b1", "b2", "b0")
		content_c(img, bx, ry + 20, 76, 18, it[5], "white", 1, null, 0, Vector2i(0, 1), "b0")
		content_c(img, bx, ry + 6, 76, 11, it[4], "br1", 1, icon("icon_money"), 3)
	var fx := x + (w - 90) / 2
	fita(img, fx, y + h - 32, 90, 20, "g1", "g2", "g0")
	content_c(img, fx, y + h - 32, 90, 20, "FECHAR", "white", 1, null, 0, Vector2i(0, 1), "d1")


func _rope(img: Image, a: Vector2i, b: Vector2i) -> void:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var t := float(i) / n
		var p := Vector2(a).lerp(Vector2(b), t)
		px(img, int(p.x), int(p.y), "br3" if (i / 2) % 2 == 0 else "br2")
		px(img, int(p.x) + 1, int(p.y), "br1")


func menu_b(img: Image, lut: Image) -> void:
	dim_alpha(img, 0.15, "b0")
	blit(img, lut, 170 - 22, 312 - 67)
	# faixa de lona pendurada por cordas
	var L := logo_layer("FIGHTCLICKER", 4, true)
	var bw := L.get_width() + 44
	var bx := (640 - bw) / 2
	var by := 22
	var bh := L.get_height() + 46
	for xi in [bx + 7, bx + bw - 8]:
		_rope(img, Vector2i(xi, by + 5), Vector2i(xi + (-20 if xi < 320 else 20), -2))
	for xx in range(bx + 3, bx + bw + 3):
		pxa(img, xx, by + bh, "ink", 0.6)
	lona(img, bx, by, bw, bh)
	for xi in [bx + 7, bx + bw / 2, bx + bw - 8]:
		ilhos(img, xi, by + 6)
	var lx := (640 - L.get_width()) / 2
	var ly := by + 15
	layer_put(img, L, lx, ly, "b1", 2, 2)
	layer_outline(img, L, lx, ly, "ink")
	layer_put(img, L, lx, ly, "r2")
	# pincelada: 1 linha clara no alto das letras
	for xx in L.get_width():
		if L.get_pixel(xx, 0).a > 0.5:
			px(img, lx + xx, ly, "r3")
	var sw := tw(SUB_MENU)
	tx(img, SUB_MENU, 320 - sw / 2, ly + L.get_height() + 10, "b1")
	# placa do menu com fitas
	var pw := 172
	var px0 := 320 - pw / 2
	frame(img, px0 - 1, 157, pw + 2, 4 * 28 + 22, "ink")
	placa(img, px0, 158, pw, 4 * 28 + 20)
	var bw2 := 140
	for i in MENU.size():
		var yy := 168 + i * 28
		var xb := 320 - bw2 / 2
		if i == 0:
			fita(img, xb, yy, bw2, 22, "r2", "r3", "r1")
			content_c(img, xb, yy, bw2, 22, MENU[i], "white", 1, null, 0, Vector2i(0, 1), "r0")
		else:
			fita(img, xb, yy, bw2, 22, "cream", "white", "g3")
			content_c(img, xb, yy, bw2, 22, MENU[i], "ink", 1)
	tx(img, "v0.8", 634 - tw("v0.8"), 350, "cream")


# =================================================================================================== C: CARTAZ
## Papel de cartaz: creme com manchas de envelhecimento em dither (g3) e borda ink grossa.
func papel(img: Image, x: int, y: int, w: int, h: int, borda := 2) -> void:
	rect(img, x, y, w, h, "cream")
	for yy in h:
		for xx in w:
			var X := x + xx
			var Y := y + yy
			var n := (X * 7 + Y * 13 + (X * Y) % 11) % 23
			if n == 0 and bayer(X, Y) < 8:
				px(img, X, Y, "g3")
	for i in borda:
		frame(img, x + i, y + i, w - 2 * i, h - 2 * i, "ink")


## Faixa diagonal (paralelogramo inclinado 1 px por linha) entre x0 e x1 na base, subindo para a direita.
func diag(img: Image, x0: int, x1: int, y0: int, y1: int, c, slope := 1) -> void:
	for y in range(y0, y1):
		var off := (y1 - 1 - y) * slope
		hl(img, x0 + off, y, x1 - x0, c)


## Carimbo redondo (azul Raízes) com falhas de tinta por sorteio fixo.
func carimbo(img: Image, cx: int, cy: int, r: int, sym: Image, c = "b1", c2 = "b2") -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			var d := sqrt(x * x + y * y)
			if (d <= r and d > r - 2) or (d <= r - 4 and d > r - 5):
				if (x * 31 + y * 17 + 7) % 9 != 0:
					px(img, cx + x, cy + y, c)
	blit(img, sym, cx - sym.get_width() / 2, cy - sym.get_height() / 2)


## Botão de cartaz: chapa com sombra dura deslocada (2 px), texto no meio.
func bot_c(img: Image, x: int, y: int, w: int, h: int, s: String, base, fg, sombra = "r2", ic = null, sc := 1) -> void:
	rect(img, x + 2, y + 2, w, h, sombra)
	rect(img, x, y, w, h, base)
	frame(img, x, y, w, h, "ink")
	content_c(img, x, y, w, h, s, fg, sc, ic)


func sala_c(img: Image) -> void:
	# HUD: tira de asfalto com faixas diagonais vermelha e creme separando os grupos; etiqueta de papel no local
	rect(img, 0, 0, 640, 18, "d1")
	hl(img, 0, 18, 640, "ink")
	hl(img, 0, 19, 640, "r1")
	for x in range(0, 640, 2):
		pxa(img, x, 20, "ink", 0.4)
	var cores := {"lab": "g3", "treino": "gr3", "treino2": "gr3", "money": "y1", "fame": "f2", "legacy": "p2", "txt": "cream", "txt2": "cream"}
	var sep2 := func(xs):
		for y in 18:
			var o := (17 - y) / 3
			hl(img, xs - 4 + o, y, 3, "r2")
			hl(img, xs - 1 + o, y, 1, "cream")
	hud_left(img, 9, cores, sep2)
	# etiqueta de papel do local, com o lado esquerdo cortado em diagonal
	var tmp := Image.create(640, 20, false, Image.FORMAT_RGBA8)
	var xl := hud_right(tmp, 630, cores, func(_x): pass)
	var ex := xl - 10
	for y in 18:
		var o := (17 - y) / 3
		hl(img, ex + o, y, 640 - ex - o, "cream")
		px(img, ex + o, y, "ink")
	hl(img, ex, 17, 640 - ex, "g3")
	var cores2 := {"fame": "f0", "legacy": "p0", "txt2": "ink"}
	hud_right(img, 630, cores2, func(xs): vl(img, xs, 3, 12, "r2"))
	# cartões: papel de cartaz
	_cards_c(img)
	papel(img, 615, 121, 22, 56, 1)
	blit(img, icon("icon_treino"), 618, 127)
	tx(img, "4", 629, 128, "gr1")
	blit(img, icon("icon_money"), 618, 142)
	tx(img, "4", 629, 143, "br1")
	tx(img, "<", 624, 161, "ink")
	# BARRA: papel creme com borda grossa e faixa diagonal vermelha atrás do LUTAR
	papel(img, 0, 329, 640, 31, 0)
	rect(img, 0, 329, 640, 2, "ink")
	for y in range(331, 360):
		var o := (359 - y) / 2
		hl(img, 494 + o, y, 640, "r2")
		hl(img, 494 + o - 4, y, 3, "ink")
	tx(img, "+1", 8, 338, "gr1", 2)
	tx(img, "/CLIQUE", 8 + tw("+1", 2) + 1, 345, "g0")
	for i in FOCOS.size():
		var f: Array = FOCOS[i]
		var x: int = X_FOCO + i * PASSO
		match f[2]:
			"ativo":
				bot_c(img, x, 335, LARG - 2, 19, f[0], "r2", "white", "ink", icon(f[1]))
			"compravel":
				bot_c(img, x, 335, LARG - 2, 19, f[0], "d1", "cream", "y0", icon(f[1]))
			_:
				for xx in range(x, x + LARG - 2):
					if xx % 2 == 0:
						px(img, xx, 335, "g1"); px(img, xx, 353, "g1")
				for yy in range(335, 354):
					if yy % 2 == 0:
						px(img, x, yy, "g1"); px(img, x + LARG - 3, yy, "g1")
				content_c(img, x, 335, LARG - 2, 19, f[0], "g1", 1, icon(f[1]))
	tx(img, "CLIQUE NO SACO", 366, 338, "ink")
	tx(img, "PARA TREINAR", 366, 348, "ink")
	bot_c(img, 462, 337, 17, 16, "", "cream", "ink", "ink", icon("icon_assist_wait"))
	bot_c(img, 483, 337, 16, 16, "?", "cream", "ink", "ink")
	# LUTAR: chapa creme sobre a faixa vermelha, letra de cartaz com sombra
	for y in range(333, 357):
		var o := (356 - y) / 3
		hl(img, 510 + o, y, 94, "ink")
	for y in range(332, 355):
		var o := (354 - y) / 3
		hl(img, 508 + o, y, 92, "cream")
	content_c(img, 512, 332, 92, 23, "LUTAR!", "r2", 2, null, 0, Vector2i(1, 1), "ink")
	carimbo(img, 624, 345, 11, icon("icon_pass_post"), "cream", "cream")


func _cards_c(img: Image) -> void:
	for r in [Rect2i(3, 21, 112, 42), Rect2i(119, 21, 22, 22), Rect2i(3, 67, 124, 46)]:
		rect(img, r.position.x + 2, r.position.y + 2, r.size.x, r.size.y, "ink")
		papel(img, r.position.x, r.position.y, r.size.x, r.size.y, 1)
	_attr_rows(img, 8, 26, "g3", "ink", {1: "b1"})
	rect(img, 120, 22, 20, 20, "d1")
	content_c(img, 119, 21, 22, 22, "", "white", 1, icon("icon_glove_l1"))
	rect(img, 4, 68, 122, 11, "ink")
	blit(img, icon("icon_calendar"), 7, 68)
	tx(img, "FALTAM 12 DIAS", 22, 70, "cream")
	tx(img, "DUDU ALONGADO", 9, 84, "ink")
	# carimbo PERIGOSO: retângulo de borda dupla vermelha, falhado
	var sx := 30
	var sy := 94
	frame(img, sx, sy, 72, 16, "r2")
	frame(img, sx + 2, sy + 2, 68, 12, "r2")
	for i in 12:
		px(img, sx + (i * 37) % 72, sy + (i % 2) * 15, "cream")
	content_c(img, sx, sy, 72, 16, "PERIGOSO", "r2")


func janela_c(img: Image) -> void:
	dim_dither(img)
	var x := 130
	var y := 56
	var w := 380
	var h := 248
	rect(img, x + 4, y + 4, w, h, "ink")
	papel(img, x, y, w, h, 2)
	# faixa vermelha do título com o lado direito cortado em diagonal
	for yy in range(y + 2, y + 42):
		var o := (y + 41 - yy) / 2
		hl(img, x + 2, yy, 120 + o, "r2")
		hl(img, x + 2 + 120 + o, yy, 3, "ink")
	hl(img, x + 2, y + 42, w - 4, "ink")
	hl(img, x + 2, y + 43, w - 4, "ink")
	tx(img, "LOJA", x + 14, y + 11, "cream", 3, Vector2i(2, 2), "ink")
	tx(img, "Dinheiro de luta, só aqui.", x + 146, y + 12, "ink")
	blit(img, icon("icon_money"), x + w - 14 - tw(V_MONEY) - 12, y + 25)
	tx(img, V_MONEY, x + w - 14 - tw(V_MONEY), y + 26, "br1")
	for i in LOJA.size():
		var it: Array = LOJA[i]
		var ry := y + 52 + i * 50
		rect(img, x + 14, ry + 7, 26, 26, "d1")
		frame(img, x + 14, ry + 7, 26, 26, "ink")
		content_c(img, x + 14, ry + 7, 26, 26, "", "white", 1, icon(it[0]))
		tx(img, it[1].to_upper(), x + 48, ry + 7, "ink", 1)
		tx(img, it[2], x + 48, ry + 18, "g0")
		tx(img, it[3], x + 48, ry + 29, "gr1")
		var bx := x + w - 20 - 76
		bot_c(img, bx, ry + 19, 76, 18, it[5], "d1", "cream", "r2")
		content_c(img, bx, ry + 5, 76, 11, it[4], "br1", 1, icon("icon_money"), 3)
		if i < LOJA.size() - 1:
			hl(img, x + 10, ry + 45, w - 20, "g3")
	var fx := x + (w - 90) / 2
	bot_c(img, fx, y + h - 34, 90, 20, "FECHAR", "cream", "ink", "ink")
	carimbo(img, x + w - 34, y + h - 30, 17, icon("school_symbol_16"))


func menu_c(img: Image, lut: Image) -> void:
	dim_alpha(img, 0.35, "ink")
	blit(img, lut, 170 - 22, 312 - 67)
	# faixa diagonal vermelha atravessando a tela atrás do logo (sobe 1 px a cada 12 colunas), filetes creme e ink
	for x in 640:
		var yc := 92 - (x - 320) / 12
		for y in range(yc - 52, yc + 53):
			px(img, x, y, "r2")
		for y in range(yc - 57, yc - 54):
			px(img, x, y, "cream")
		for y in range(yc + 55, yc + 58):
			px(img, x, y, "cream")
		px(img, x, yc + 53, "ink"); px(img, x, yc + 54, "ink")
		px(img, x, yc + 58, "ink")
	# logo de cartaz: bold, itálico (1 px a cada 4 linhas), creme com contorno ink e sombra dura
	var L := logo_layer("FIGHTCLICKER", 5, true, 4)
	var lx := (640 - L.get_width()) / 2
	var ly := 52
	layer_put(img, L, lx, ly, "ink", 4, 4)
	layer_outline(img, L, lx, ly, "ink")
	layer_put(img, L, lx, ly, "cream")
	for xx in L.get_width():
		for yy in [L.get_height() - 1, L.get_height() - 2]:
			if L.get_pixel(xx, yy).a > 0.5:
				px(img, lx + xx, ly + yy, "g3")
	var sw := tw(SUB_MENU)
	rect(img, 320 - sw / 2 - 6, ly + L.get_height() + 10, sw + 12, 13, "ink")
	tx(img, SUB_MENU, 320 - sw / 2, ly + L.get_height() + 13, "cream")
	# carimbo azul da escola no canto do cartaz
	carimbo(img, 556, 236, 26, icon("school_symbol_32"), "b2")
	# botões
	var bw := 140
	var bx := 320 - bw / 2
	for i in MENU.size():
		var by := 172 + i * 30
		if i == 0:
			bot_c(img, bx, by, bw, 22, MENU[i], "r2", "cream", "ink")
		else:
			bot_c(img, bx, by, bw, 22, MENU[i], "cream", "ink", "r2")
	tx(img, "v0.8", 634 - tw("v0.8"), 350, "cream")


# =================================================================================================== prancha
func _comparativo(tiles: Dictionary) -> void:
	var m := 10
	var head := 22
	var lab := 18
	var W := m + 3 * (640 + m)
	var H := head + 3 * (360 + lab + m) + m
	var b := Image.create(W, H, false, Image.FORMAT_RGBA8)
	b.fill(C("ink"))
	var nomes := {"a": "A  VIDRO PIXELADO", "b": "B  LONA E PLACA DE ACADEMIA", "c": "C  CARTAZ DE LUTA"}
	var telas := ["SALA (HUD E BARRA)", "JANELA (LOJA)", "MENU PRINCIPAL"]
	var col := 0
	for d in ["a", "b", "c"]:
		var x := m + col * (640 + m)
		tx(b, nomes[d], x, 6, "white", 2)
		for r in 3:
			var y := head + r * (360 + lab + m)
			tx(b, telas[r], x, y + 5, "g3")
			blit(b, tiles[d][r], x, y + lab)
		col += 1
	b.save_png(OUT + "identidade_comparativo.png")
