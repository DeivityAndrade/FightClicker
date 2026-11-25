extends SceneTree
## Identidade visual, direção C (cartaz de luta), escolhida pelo dono em 2026-11-25. Menu principal v2. Diretor de Arte.
## MOCKUP gerado por código (placeholder), tudo original. Não grava nada em assets/ nem mexe em ui/ ou scenes/.
## Rodar de uma pasta com project.godot vazio (não dispara import no projeto), headless:
##   godot --headless --max-fps 30 --path <pasta_vazia> --script <worktree>/tools/art/make_mockup_identidade_c2.gd -- --root <worktree>
## Grava em docs/arte/mockups/identidade/:
##   identidade_c_menu_v2_{garagem,arena,cartazes}_x2.png, identidade_c_menu_v2_comparativo.png
##   menu_c_anim/menu_c_anim_prancha.png (8 quadros-chave), menu_c_anim/seq/f###.png (1x) e menu_c_anim/tempos.txt
##   (o GIF de pré-visualização sai do ffmpeg a partir de seq/ + tempos.txt; comando no fim do tempos.txt).
## Composição v2 (resposta ao "ficou meio torto"): tudo num eixo só, x = 320.
##   - faixa vermelha HORIZONTAL de ponta a ponta (a inclinação fica só nas listras de dentro e no itálico do logo);
##   - logo centrado pela caixa real dos pixels (get_used_rect), subtítulo e botões no mesmo eixo;
##   - sombra dura RETA para baixo (0,3) nos botões e (0,4) no logo: nada puxa para o lado;
##   - a cena tem peso igual dos dois lados (lutador + saco à esquerda, espelhado por treinador / adversário à direita).
## O gerador mede e imprime: centro de cada botão e do texto (margens esq/dir e cima/baixo), centro do logo e do subtítulo,
## contraste texto/base, e se algum sprite da cena sai da tela ou entra na coluna dos botões. Meta: 0 problemas.

var ROOT := "E:/Fightclicker/.claude/worktrees/identidade-visual"
var OUT := ""
var ANIM := ""

const PAL := {
	"ink": "14101a", "d1": "2a2233", "d2": "3d3346",
	"g0": "4a4552", "g1": "6b6570", "g2": "8f8890", "g3": "b8b0aa",
	"cream": "d9cdb4", "white": "f2ece0",
	"br0": "3b2622", "br1": "6b3f2a", "br2": "9a5f36", "br3": "c98a4b",
	"y0": "e0a040", "y1": "f5d26b", "y2": "fff3c4",
	"r0": "5a1a22", "r1": "9c2a2a", "r2": "d4473a", "r3": "f07a5a",
	"b0": "1f2a44", "b1": "2f4a78", "b2": "4d7bb3", "b3": "8fbbe0",
	"st0": "3a4452", "st1": "5a6676", "st2": "7f8c9a", "st3": "a9b4bf",
}
const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
const MENU := ["CONTINUAR", "NOVO JOGO", "OPÇÕES", "SAIR"]
const SUB_MENU := "UM SOCO DE CADA VEZ"  # [ROT] provisório

# ---- grade do menu v2 (640x360). Eixo único x = 320.
const AXIS := 320
const BAND_Y0 := 26      # filete creme de cima (3) + ink (1)
const BAND_B0 := 30      # corpo vermelho
const BAND_B1 := 106     # fim do corpo (exclusivo)
const BAND_Y1 := 112     # ink (2) + creme (3) + ink (1) embaixo
const LOGO_Y := 48
const BTN_W := 152
const BTN_H := 22
const BTN_PITCH := 28
const BTN_Y := 164
const SHADOW_BTN := 3
const STRIPE := 16       # período das listras diagonais (px); correm 1 px a cada 80 ms

var G := {}
var cap_top := 2
var cap_h := 7
var problemas: Array = []
var medir := true
var logo_L: Image
var logo_used: Rect2i


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--root" and i + 1 < args.size():
			ROOT = args[i + 1].replace("\\", "/")
	OUT = ROOT + "/docs/arte/mockups/identidade/"
	ANIM = OUT + "menu_c_anim/"
	DirAccess.make_dir_recursive_absolute(ANIM + "seq")
	_load_font()
	logo_L = logo_layer("FIGHTCLICKER", 5, true, 4)
	logo_used = logo_L.get_used_rect()
	var fundos := {"garagem": bg_garagem(), "arena": bg_arena(), "cartazes": bg_cartazes()}
	var tiles := {}
	for k in ["garagem", "arena", "cartazes"]:
		var im: Image = fundos[k].img.duplicate()
		problemas.clear()
		menu_ui(im, {})
		_check_scene(k, fundos[k].boxes)
		_report(k)
		_save_x2(im, "identidade_c_menu_v2_%s" % k)
		tiles[k] = im
	_comparativo(tiles)
	_animacao(fundos["arena"].img, fundos["arena"].boxes)
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


func frame_of(p: String, fw: int, fh: int, i: int) -> Image:
	return _img(ROOT + p).get_region(Rect2i(fw * i, 0, fw, fh))


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


func _save_x2(img: Image, nome: String, dir := "") -> void:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	b.save_png((OUT if dir == "" else dir) + nome + "_x2.png")


## Caixa dos pixels opacos de um sprite colado em (x,y).
func opaque_box(s: Image, x: int, y: int) -> Rect2i:
	var u := s.get_used_rect()
	return Rect2i(u.position + Vector2i(x, y), u.size)


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


## Caixa real dos pixels de um texto (com acentos), para medir o alinhamento.
func tx_box(s: String, x: int, ycap: int, sc := 1, so_maiusculas := true) -> Rect2i:
	var x0 := 99999
	var x1 := -99999
	var y0 := 99999
	var y1 := -99999
	var pen := 0
	for i in s.length():
		var g := _g(s.unicode_at(i))
		for p in g.px:
			var yy: int = g.yo + p.y - cap_top
			if so_maiusculas and (yy < 0 or yy >= cap_h):
				continue  # acento / descendente não conta no centro vertical (centro óptico = altura das maiúsculas)
			x0 = mini(x0, x + (pen + g.xo + p.x) * sc)
			x1 = maxi(x1, x + (pen + g.xo + p.x) * sc + sc - 1)
			y0 = mini(y0, ycap + yy * sc)
			y1 = maxi(y1, ycap + yy * sc + sc - 1)
		pen += g.adv
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


func ycap_in(y: int, h: int, sc := 1) -> int:
	return y + int(floor((h - cap_h * sc) / 2.0))


# ================================================================= logo
func logo_mask(s: String) -> Image:
	var m := Image.create(tw(s) + 2, cap_h, false, Image.FORMAT_RGBA8)
	tx(m, s, 0, 0, "white")
	return m


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


# ================================================================= luz (noite): escurece tudo e devolve a luz nos cones
## Nível de luz em degraus (0 / 0,5 / 1) com borda em dither Bayer: é pixel art, não degradê.
func cone_level(x: int, y: int, cx: int, top: int, bot: int, w_top: int, w_bot: int, fx: int, fy: int, frx: int, fry: int) -> float:
	var lv := 0.0
	if y >= top and y <= bot:
		var t := float(y - top) / float(bot - top)
		var hw := lerpf(w_top, w_bot, t)
		var d := absf(x - cx) / hw
		if d < 0.8:
			lv = 0.5
		elif d < 1.0 and bayer(x, y) < 8:
			lv = 0.5
	var e := pow(float(x - fx) / frx, 2) + pow(float(y - fy) / fry, 2)
	if e < 0.7:
		lv = 1.0
	elif e < 1.0 and bayer(x, y) < 8:
		lv = maxf(lv, 1.0)
	elif e < 1.4 and bayer(x, y) < 4:
		lv = maxf(lv, 0.5)
	return lv


func night(img: Image, cones: Array, dark := 0.55, tint = "b0", warm = "y1") -> void:
	for y in img.get_height():
		for x in img.get_width():
			var lv := 0.0
			var wc = warm
			for c in cones:
				var l := cone_level(x, y, c.cx, c.top, c.bot, c.wt, c.wb, c.fx, c.fy, c.frx, c.fry)
				if l > lv:
					lv = l
					wc = c.get("warm", warm)
			pxa(img, x, y, tint, dark * (1.0 - lv * 0.8))
			if lv > 0.0 and wc != null:
				pxa(img, x, y, wc, 0.07 * lv)
	# vinheta: cantos de baixo um passo mais escuros (dither), segura o olho no meio
	for y in img.get_height():
		for x in img.get_width():
			var dx := absf(x - 320.0) / 320.0
			var dy := float(y) / 360.0
			if dx * dx * 0.9 + dy * dy * 0.25 > 0.62 and bayer(x, y) < 8:
				pxa(img, x, y, "ink", 0.35)


func cone(cx: int, fy: int, warm = "y1", top := 112, wt := 16, wb := 70, frx := 70, fry := 14) -> Dictionary:
	return {"cx": cx, "top": top, "bot": fy, "wt": wt, "wb": wb, "fx": cx, "fy": fy, "frx": frx, "fry": fry, "warm": warm}


# ================================================================= fundos (cenários reais do jogo)
## 1) Garagem à noite: o saco pendurado e o lutador batendo (esquerda), o primeiro treinador olhando (direita, espelhado).
func bg_garagem() -> Dictionary:
	var g := _img(ROOT + "/assets/sprites/garage/garage_bg.png")
	var chain_x := 150
	night(g, [cone(chain_x - 14, 300, "y1"), cone(640 - chain_x, 300, "y1")], 0.58)
	var boxes := []
	# saco + corrente (mesma relação do jogo: lutador 32 px à esquerda da corrente, saco 20 px acima dos pés)
	var chain := _img(ROOT + "/assets/sprites/equipment/bag_chain_tile.png")
	var bag := frame_of("/assets/sprites/equipment/bag_l1_idle.png", 40, 76, 0)
	var bag_y := 210
	var cy := BAND_Y1
	while cy < bag_y + 4:
		blit(g, chain, chain_x - 2, cy)
		cy += chain.get_height()
	blit(g, bag, chain_x - 20, bag_y)
	var lut := frame_of("/assets/sprites/characters/fighter_punch.png", 48, 72, 2)
	blit(g, _shadow(48), chain_x - 56, 300 - 3)
	blit(g, lut, chain_x - 56, 230)
	boxes.append(["saco", opaque_box(bag, chain_x - 20, bag_y)])
	boxes.append(["lutador", opaque_box(lut, chain_x - 56, 230)])
	var coach := frame_of("/assets/sprites/characters/coach_idle.png", 48, 72, 0)
	coach.flip_x()
	var cx := 640 - chain_x - 24 + 10
	blit(g, _shadow(48), cx, 300 - 3)
	blit(g, coach, cx, 230)
	boxes.append(["treinador", opaque_box(coach, cx, 230)])
	return {"img": g, "boxes": boxes}


func _shadow(w: int) -> Image:
	var s := Image.create(w, 6, false, Image.FORMAT_RGBA8)
	for y in 6:
		for x in w:
			var e := pow((x - w / 2.0) / (w * 0.42), 2) + pow((y - 3.0) / 3.0, 2)
			if e < 1.0 and (bayer(x, y) < 10):
				s.set_pixel(x, y, Color(C("ink"), 0.75))
	return s


## 2) Ginásio Alvorada (arena da liga): dois refletores, o lutador e o adversário frente a frente no tatame.
func bg_arena() -> Dictionary:
	var g := _img(ROOT + "/assets/sprites/fight/arena_league_bg.png")
	night(g, [cone(150, 326, "y2", 112, 14, 60, 64, 12), cone(490, 326, "y2", 112, 14, 60, 64, 12)], 0.55, "ink")
	# a faixa GINÁSIO ALVORADA (nome do lugar) volta a acender: é o "local" do cartaz, logo abaixo do subtítulo
	var src := _img(ROOT + "/assets/sprites/fight/arena_league_bg.png")
	var r := Rect2i(218, 121, 204, 28)
	for y in r.size.y:
		for x in r.size.x:
			var c := src.get_pixel(r.position.x + x, r.position.y + y)
			g.set_pixel(r.position.x + x, r.position.y + y, c.lerp(C("ink"), 0.12))
	var boxes := []
	var p := frame_of("/assets/sprites/fight/fight_player_idle_glove_l1.png", 112, 104, 0)
	var o := frame_of("/assets/sprites/opponents/opp_gym_2/opp_gym_2_idle.png", 112, 104, 0)
	blit(g, _shadow(56), 150 - 28, 326 - 3)
	blit(g, _shadow(56), 490 - 28, 326 - 3)
	blit(g, p, 150 - 56, 326 - 98)
	blit(g, o, 490 - 56, 326 - 98)
	boxes.append(["lutador", opaque_box(p, 150 - 56, 326 - 98)])
	boxes.append(["adversário", opaque_box(o, 490 - 56, 326 - 98)])
	return {"img": g, "boxes": boxes, "faixa_local": r}


## 3) Parede de cartazes (a parede da garagem de perto, 320x180 ampliada 2x): os cartazes de luta que o jogador
##    vai colando, o recorte do jornal, o capuz no prego e, no eixo, as luvas velhas do mentor penduradas.
func bg_cartazes() -> Dictionary:
	var W := 320
	var H := 180
	var w := Image.create(W, H, false, Image.FORMAT_RGBA8)
	# blocos de concreto (16x8, junta d2), 3 tons por sorteio fixo
	for y in H:
		for x in W:
			var row := y / 8
			var xx := x + (8 if row % 2 == 1 else 0)
			var bid := (xx / 16) * 7 + row * 13
			var base: String = ["st1", "g1", "st1", "g0", "st1"][posmod(bid * 31 + row, 5)]
			if y % 8 == 7 or xx % 16 == 15:
				base = "d2"
			elif y % 8 == 0 or xx % 16 == 0:
				base = "st2" if base == "st1" else "g2" if base == "g1" else base
			px(w, x, y, base)
			if (x * 7 + y * 13) % 29 == 0 and bayer(x, y) < 6:
				px(w, x, y, "g0")
	# rodapé: piso
	rect(w, 0, 174, W, 6, "d1")
	hl(w, 0, 174, W, "g0")
	var boxes := []
	# cartazes (posição na meia escala). Lados espelhados: 2 colunas de cada lado, centro livre para a UI.
	var soco := _img(ROOT + "/assets/sprites/garage/garage_bg.png").get_region(Rect2i(268, 64, 31, 40))
	_colado(w, soco, 14, 66, boxes, "cartaz SOCO")
	_cartaz_listras(w, 52, 58, 40, 54, "r2", boxes)
	var liga := _img(ROOT + "/assets/sprites/gym/wall_poster_league_regional_gym.png")
	_colado(w, liga, 320 - 52 - 40, 58, boxes, "cartaz LIGA")
	_cartaz_listras(w, 320 - 14 - 31, 66, 31, 40, "b1", boxes)
	var rec := _img(ROOT + "/assets/sprites/gym/wall_clipping_black_cat_gym.png")
	_colado(w, rec, 26, 118, boxes, "recorte do jornal")
	var hood := _img(ROOT + "/assets/sprites/garage/hood_on_nail.png").get_region(Rect2i(0, 0, 16, 22))
	blit(w, hood, 58, 120)
	boxes.append(["capuz", opaque_box(hood, 58, 120)])
	var foto := _img(ROOT + "/assets/sprites/gym/wall_photo_old_gym.png")
	_colado(w, foto, 320 - 26 - 36, 122, boxes, "foto antiga")
	var fr := _img(ROOT + "/assets/sprites/center/wall_clipping_regional_framed.png")
	blit(w, fr, 320 - 66 - 36 + 2, 116)
	# no eixo, embaixo dos botões: as luvas velhas do mentor no prego (o começo da história)
	var luv := _img(ROOT + "/assets/sprites/garage/garage_hung_gloves_old.png").get_region(Rect2i(0, 0, 40, 34))
	var lux := 160 - 20
	blit(w, luv, lux, 139)
	boxes.append(["luvas", opaque_box(luv, lux, 139)])
	# lâmpada no alto (escondida pela faixa) -> cone de luz que desce no eixo; o resto é noite
	var big: Image = w.duplicate()
	big.resize(640, 360, Image.INTERPOLATE_NEAREST)
	night(big, [cone(320, 340, "y1", 112, 40, 150, 150, 18)], 0.6)
	var bx := []
	for b in boxes:
		var r: Rect2i = b[1]
		bx.append([b[0], Rect2i(r.position * 2, r.size * 2)])
	return {"img": big, "boxes": bx}


func _colado(w: Image, s: Image, x: int, y: int, boxes: Array, nome: String) -> void:
	# sombra de 1 px e fita nos cantos de cima
	rect(w, x + 1, y + 1, s.get_width(), s.get_height(), "d2")
	blit(w, s, x, y)
	rect(w, x - 1, y - 1, 4, 2, "g3")
	rect(w, x + s.get_width() - 3, y - 1, 4, 2, "g3")
	boxes.append([nome, opaque_box(s, x, y)])


## Cartaz de lambe-lambe genérico: papel creme, faixa diagonal colorida, "texto" em barras (sem palavra: só forma).
func _cartaz_listras(w: Image, x: int, y: int, cw: int, ch: int, cor, boxes: Array) -> void:
	rect(w, x + 1, y + 1, cw, ch, "d2")
	rect(w, x, y, cw, ch, "cream")
	frame(w, x, y, cw, ch, "g3")
	for yy in range(y + 4, y + 18):
		var o := (y + 17 - yy) / 2
		hl(w, x + 2 + o, yy, mini(14, cw - 4 - o), cor)
	rect(w, x + 4, y + 22, cw - 8, 3, "ink")
	rect(w, x + 6, y + 27, cw - 12, 2, "g1")
	for i in 3:
		rect(w, x + 5, y + 32 + i * 4, cw - 10 - (i % 2) * 6, 1, "g2")
	# canto rasgado embaixo à direita
	for i in 4:
		hl(w, x + cw - 4 + i, y + ch - 4 + i, 4 - i, "d2")
	rect(w, x - 1, y - 1, 4, 2, "g3")
	boxes.append(["cartaz", Rect2i(x, y, cw, ch)])


# ================================================================= UI do menu (com estado de animação)
## st: band (0..1), logo (bool), logo_dy, shake (Vector2i), flash (bool), speed (bool), sub (bool), nbtn (0..4),
##     btn_dy (deslocamento do último botão que entra), off (listras), glint (-1 ou 0..1), bob (0/1), dust (bool)
func menu_ui(img: Image, st: Dictionary) -> void:
	var band: float = st.get("band", 1.0)
	var show_logo: bool = st.get("logo", true)
	var sh: Vector2i = st.get("shake", Vector2i.ZERO)
	var off: int = st.get("off", 0)
	if band > 0.0:
		_band(img, band, off, sh, st.get("band_flash", false))
	if show_logo:
		_logo(img, sh + Vector2i(0, st.get("logo_dy", 0)), st.get("flash", false), st.get("speed", false), st.get("glint", -1.0))
		if st.get("dust", false):
			_dust(img, sh)
	if st.get("sub", true):
		_sub(img, sh)
	var nb: int = st.get("nbtn", 4)
	for i in nb:
		var dy: int = st.get("btn_dy", 0) if i == nb - 1 else 0
		_button(img, i, dy, i == 0, st.get("bob", 0) if nb == 4 else -1)
	if st.get("ver", true):
		tx(img, "v0.8", 634 - tw("v0.8"), 349, "g2")


func _band(img: Image, p: float, off: int, sh: Vector2i, flash: bool) -> void:
	# borda da frente da faixa: diagonal "/" (sobe para a direita), anda da esquerda para a direita
	var E := int(lerpf(-60.0, 700.0, p))
	var ymid := (BAND_Y0 + BAND_Y1) / 2
	for y0 in range(BAND_Y0, BAND_Y1 + 2):
		var y := y0 + sh.y
		var xe := E + (ymid - y0) / 2
		for x0 in range(0, 640):
			if x0 >= xe:
				break
			var x := x0 + sh.x
			var c := "r2"
			if y0 < BAND_Y0 + 3:
				c = "cream"
			elif y0 == BAND_Y0 + 3:
				c = "ink"
			elif y0 >= BAND_B1 and y0 < BAND_B1 + 2:
				c = "ink"
			elif y0 >= BAND_B1 + 2 and y0 < BAND_B1 + 5:
				c = "cream"
			elif y0 == BAND_B1 + 5:
				c = "ink"
			elif y0 >= BAND_Y1:
				# sombra dura da faixa (1 px em dither)
				if bayer(x0, y0) < 8:
					pxa(img, x, y, "ink", 0.6)
				continue
			else:
				# listras diagonais "/" correndo para a direita: meio-tom r1 em dither sobre r2
				var k := posmod(x0 + (y0 - BAND_B0) - off, STRIPE)
				if k < 6 and bayer(x0, y0) < 8:
					c = "r1"
				elif k == 6:
					c = "r1"
			if x0 >= xe - 2 and p < 1.0:
				c = "white" if flash else "cream"  # fio de luz na borda que entra
			px(img, x, y, c)


func logo_pos() -> Vector2i:
	# centro pela caixa REAL dos pixels (o itálico desloca a caixa; centraliza o que se vê)
	var cx := logo_used.position.x + (logo_used.size.x - 1) / 2.0
	return Vector2i(AXIS - int(floor(cx)), LOGO_Y)


func _logo(img: Image, d: Vector2i, flash: bool, speed: bool, glint: float) -> void:
	var p := logo_pos() + d
	var L := logo_L
	if speed:
		# linhas de velocidade acima (o título caindo)
		for xx in range(logo_used.position.x, logo_used.end.x, 9):
			vl(img, p.x + xx + 3, p.y - 12, 8, "r3")
	layer_put(img, L, p.x, p.y, "ink", 0, 4)
	layer_put(img, L, p.x, p.y, "ink", 1, 4)
	layer_outline(img, L, p.x, p.y, "white" if flash else "ink")
	layer_put(img, L, p.x, p.y, "white" if flash else "cream")
	if flash:
		return
	for xx in L.get_width():
		for yy in [L.get_height() - 1, L.get_height() - 2]:
			if L.get_pixel(xx, yy).a > 0.5:
				px(img, p.x + xx, p.y + yy, "g3")
		if L.get_pixel(xx, 0).a > 0.5:
			px(img, p.x + xx, p.y, "white")
	if glint >= 0.0:
		# brilho: faixa diagonal de 4 px (white) + 2 px de rastro (y2), só dentro das letras
		var gx := int(lerpf(-40.0, L.get_width() + 20.0, glint))
		for yy in L.get_height():
			for xx in L.get_width():
				if L.get_pixel(xx, yy).a < 0.5:
					continue
				var k := xx + yy / 2 - gx
				if k >= 4 and k < 6:
					px(img, p.x + xx, p.y + yy, "y2")
				elif k >= 1 and k < 4:
					px(img, p.x + xx, p.y + yy, "white")
				elif k >= -3 and k < 1:
					px(img, p.x + xx, p.y + yy, "y1")


func _dust(img: Image, sh: Vector2i) -> void:
	var p := logo_pos() + sh
	var y := p.y + logo_L.get_height() + 2
	for s in [-1, 1]:
		var x0 := p.x + (logo_used.position.x - 6 if s < 0 else logo_used.end.x + 4)
		for i in 5:
			rect(img, x0 + s * i * 4, y - i * 3 - (i % 2) * 2, 2, 2, "cream" if i % 2 == 0 else "white")


func _sub(img: Image, sh: Vector2i) -> void:
	var sw := tw(SUB_MENU)
	var w := sw + 14
	var x := AXIS - w / 2 + sh.x
	var y := BAND_B1 - 3 + sh.y
	rect(img, x, y, w, 13, "ink")
	hl(img, x + 1, y + 1, w - 2, "d2")
	var tx0 := x + (w - sw) / 2
	tx(img, SUB_MENU, tx0, ycap_in(y, 13), "cream")
	if sh == Vector2i.ZERO and medir:
		_check_centro("subtítulo", Rect2i(x, y, w, 13), tx_box(SUB_MENU, tx0, ycap_in(y, 13)))
		if absi((x + w / 2.0) - AXIS) > 0.5:
			problemas.append("subtítulo fora do eixo")


func btn_rect(i: int) -> Rect2i:
	return Rect2i(AXIS - BTN_W / 2, BTN_Y + i * BTN_PITCH, BTN_W, BTN_H)


func _button(img: Image, i: int, dy: int, foco: bool, bob: int) -> void:
	var r := btn_rect(i)
	r.position.y += dy
	var base := "r1" if foco else "cream"
	var fg := "cream" if foco else "ink"
	var sombra := "ink" if foco else "r1"
	rect(img, r.position.x, r.position.y + SHADOW_BTN, r.size.x, r.size.y, sombra)   # sombra dura RETA (não puxa para o lado)
	rect(img, r.position.x, r.position.y, r.size.x, r.size.y, base)
	hl(img, r.position.x + 1, r.position.y + 1, r.size.x - 2, "r2" if foco else "white")
	frame(img, r.position.x, r.position.y, r.size.x, r.size.y, "ink")
	var s: String = MENU[i]
	var x0 := r.position.x + int(floor((r.size.x - tw(s)) / 2.0))
	var yc := ycap_in(r.position.y, r.size.y)
	if foco:
		tx(img, s, x0, yc + 1, "ink")  # sombra de 1 px: creme sobre r1 já dá 6:1, a sombra segura o r2 da animação
	tx(img, s, x0, yc, fg)
	if dy == 0 and medir:
		_check_centro("botão " + s, r, tx_box(s, x0, yc))
		_check_contraste("botão " + s, fg, base)
		if r.position.x + r.size.x / 2.0 != AXIS:
			problemas.append("botão %s fora do eixo" % s)
	if foco and bob >= 0:
		# setas de foco espelhadas, apontando para dentro; balançam 1 px (loop)
		var ay := r.position.y + r.size.y / 2
		for k in 4:
			var xl := r.position.x - 10 + k + bob
			var xr := r.end.x + 9 - k - bob
			vl(img, xl, ay - 3 + k, 7 - 2 * k, "cream")
			vl(img, xr, ay - 3 + k, 7 - 2 * k, "cream")
		vl(img, r.position.x - 11 + bob, ay - 4, 9, "ink")
		vl(img, r.end.x + 10 - bob, ay - 4, 9, "ink")


# ================================================================= medidas
func _check_centro(nome: String, caixa: Rect2i, t: Rect2i) -> void:
	var ml := t.position.x - caixa.position.x
	var mr := caixa.end.x - t.end.x
	var mt := t.position.y - caixa.position.y
	var mb := caixa.end.y - t.end.y
	var ok := absi(ml - mr) <= 1 and absi(mt - mb) <= 1 and ml >= 3 and mt >= 2
	print("  %-22s margens esq %d dir %d | cima %d baixo %d  %s" % [nome, ml, mr, mt, mb, "ok" if ok else "PROBLEMA"])
	if not ok:
		problemas.append(nome + " descentrado")


func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func contraste(a, b) -> float:
	var la := _lum(C(a))
	var lb := _lum(C(b))
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _check_contraste(nome: String, fg, bg) -> void:
	var k := contraste(fg, bg)
	if k < 4.5:
		problemas.append("%s: contraste %.1f:1" % [nome, k])
	print("  %-22s contraste %s/%s = %.1f:1" % [nome, fg, bg, k])


func _check_scene(nome: String, boxes: Array) -> void:
	var col := Rect2i(AXIS - BTN_W / 2 - 12, BTN_Y - 2, BTN_W + 24, 4 * BTN_PITCH + 4)
	var tela := Rect2i(0, 0, 640, 360)
	var cx := logo_pos().x + logo_used.position.x + (logo_used.size.x - 1) / 2.0
	print("  logo: caixa x %d..%d, centro %.1f (eixo %d)" % [logo_pos().x + logo_used.position.x, logo_pos().x + logo_used.end.x - 1, cx, AXIS])
	if absf(cx - AXIS) > 0.5:
		problemas.append("logo fora do eixo")
	if logo_pos().x + logo_used.position.x < 8 or logo_pos().x + logo_used.end.x > 632:
		problemas.append("logo encosta na borda")
	for b in boxes:
		var r: Rect2i = b[1]
		if not tela.encloses(r):
			problemas.append("%s cortado pela borda da tela" % b[0])
		if r.intersects(col):
			problemas.append("%s entra na coluna dos botões" % b[0])


func _report(nome: String) -> void:
	print("== %s: %d problema(s) %s" % [nome, problemas.size(), str(problemas) if problemas.size() > 0 else ""])


# ================================================================= prancha comparativa
func _comparativo(tiles: Dictionary) -> void:
	var antes := _img(OUT + "identidade_c_menu_x2.png")
	antes.resize(640, 360, Image.INTERPOLATE_NEAREST)
	var m := 12
	var lab := 20
	var W := m + 2 * (640 + m)
	var H := 30 + 2 * (360 + lab + m)
	var b := Image.create(W, H, false, Image.FORMAT_RGBA8)
	b.fill(C("ink"))
	tx(b, "MENU C v2: 3 FUNDOS (RECOMENDADO: ARENA)", m, 9, "cream", 2)
	var itens := [["ANTES (v1): FAIXA TORTA, LUTADOR SOLTO", antes, "g2"], ["1) GARAGEM À NOITE: SACO, LUTADOR E TREINADOR", tiles.garagem, "cream"],
			["2) GINÁSIO ALVORADA: FRENTE A FRENTE NO REFLETOR (RECOMENDADO)", tiles.arena, "y1"], ["3) PAREDE DE CARTAZES: CAPUZ, RECORTE E LUVAS DO MENTOR", tiles.cartazes, "cream"]]
	for i in 4:
		var x := m + (i % 2) * (640 + m)
		var y := 30 + (i / 2) * (360 + lab + m)
		tx(b, itens[i][0], x, y + 6, itens[i][2])
		blit(b, itens[i][1], x, y + lab)
		if i == 2:
			frame(b, x - 2, y + lab - 2, 644, 364, "y1")
	b.save_png(OUT + "identidade_c_menu_v2_comparativo.png")


# ================================================================= animação
## Linha do tempo (ms). INTRO toca 1 vez ao abrir o menu; LOOP roda enquanto o menu estiver aberto.
## A cena de fundo (lutadores) segue o idle dela por cima disso, no fps do manifest (6 fps).
func _intro() -> Array:
	var none := {"band": 0.0, "logo": false, "sub": false, "nbtn": 0, "ver": false}
	return [
		["cena escura", 120, none.merged({"dark": 0.75})],
		["faixa entra 30%", 50, {"band": 0.30, "logo": false, "sub": false, "nbtn": 0, "ver": false, "band_flash": true}],
		["faixa entra 65%", 50, {"band": 0.65, "logo": false, "sub": false, "nbtn": 0, "ver": false, "band_flash": true}],
		["faixa completa", 60, {"band": 1.0, "logo": false, "sub": false, "nbtn": 0, "ver": false}],
		["título cai", 50, {"logo_dy": -16, "speed": true, "sub": false, "nbtn": 0, "ver": false}],
		["IMPACTO: flash + 3 px", 60, {"logo_dy": 0, "shake": Vector2i(0, 3), "flash": true, "dust": true, "sub": false, "nbtn": 0, "ver": false}],
		["tremor -2", 50, {"shake": Vector2i(-2, 1), "dust": true, "sub": false, "nbtn": 0, "ver": false}],
		["tremor +1", 50, {"shake": Vector2i(1, -1), "sub": false, "nbtn": 0, "ver": false}],
		["repouso + subtítulo", 90, {"sub": true, "nbtn": 0, "ver": false}],
		["botão 1", 40, {"nbtn": 1, "btn_dy": 6, "ver": false}],
		["botão 2", 40, {"nbtn": 2, "btn_dy": 6, "ver": false}],
		["botão 3", 40, {"nbtn": 3, "btn_dy": 6, "ver": false}],
		["botão 4", 40, {"nbtn": 4, "btn_dy": 6, "ver": false}],
		["pronto", 120, {"nbtn": 4}],
	]


const LOOP_N := 48     # 48 x 80 ms = 3840 ms; listras: 3 voltas de 16 px; brilho nos quadros 0..7; setas a cada 4
const LOOP_MS := 80


func _loop_state(i: int) -> Dictionary:
	return {"off": i % STRIPE, "glint": (i / 7.0) if i < 8 else -1.0, "bob": (i / 4) % 2}


func _render(bg: Image, st: Dictionary) -> Image:
	var im: Image = bg.duplicate()
	if st.has("dark"):
		for y in 360:
			for x in 640:
				pxa(im, x, y, "ink", st.dark)
	menu_ui(im, st)
	return im


func _animacao(bg: Image, _boxes: Array) -> void:
	medir = false
	var seq := []
	for it in _intro():
		seq.append([it[0], it[1], _render(bg, it[2]), "intro"])
	for i in LOOP_N:
		seq.append(["loop %d" % i, LOOP_MS, _render(bg, _loop_state(i)), "loop"])
	# sequência PNG 1x + roteiro do ffmpeg (concat com duração por quadro)
	var d := DirAccess.open(ANIM + "seq")
	for f in d.get_files():
		if f.ends_with(".png"):
			d.remove(f)
	var lst := ""
	var lst_loop := ""
	var t := 0
	var txt := "Menu C v2: tempos da animação (ms). Quadros em seq/f###.png (1x, 640x360).\n\n"
	for i in seq.size():
		var nome := "f%03d.png" % i
		(seq[i][2] as Image).save_png(ANIM + "seq/" + nome)
		lst += "file 'seq/%s'\nduration %.3f\n" % [nome, seq[i][1] / 1000.0]
		if seq[i][3] == "loop":
			lst_loop += "file 'seq/%s'\nduration %.3f\n" % [nome, seq[i][1] / 1000.0]
		txt += "%s  %5d ms  +%3d ms  [%s] %s\n" % [nome, t, seq[i][1], seq[i][3], seq[i][0]]
		t += seq[i][1]
	# o concat do ffmpeg ignora a duração do último: repete o último arquivo
	lst += "file 'seq/f%03d.png'\n" % (seq.size() - 1)
	lst_loop += "file 'seq/f%03d.png'\n" % (seq.size() - 1)
	_write(ANIM + "concat_preview.txt", lst)
	_write(ANIM + "concat_loop.txt", lst_loop)
	txt += "\nGIF (na pasta menu_c_anim):\n  ffmpeg -y -f concat -safe 0 -i concat_preview.txt -vf \"scale=1280:720:flags=neighbor,split[a][b];[a]palettegen=stats_mode=full[p];[b][p]paletteuse=dither=none\" menu_c_anim_preview_x2.gif\n"
	_write(ANIM + "tempos.txt", txt)
	# prancha de 8 quadros-chave (1x) com rótulo e tempo
	var chaves := [1, 2, 4, 5, 6, 8, 13, 14 + 4]
	var rot := ["1  FAIXA ENTRA (50 MS)", "2  FAIXA 65% (50 MS)", "3  TÍTULO CAI (50 MS)", "4  IMPACTO: FLASH (60 MS)",
			"5  TREMOR (50+50 MS)", "6  SUBTÍTULO (90 MS)", "7  PRONTO: BOTÕES ENTRARAM", "8  LOOP: BRILHO + LISTRAS"]
	var m := 10
	var lab := 18
	var W := m + 4 * (640 + m)
	var H := 30 + 2 * (360 + lab + m)
	var b := Image.create(W, H, false, Image.FORMAT_RGBA8)
	b.fill(C("ink"))
	tx(b, "MENU C v2: QUADROS-CHAVE DA FAIXA (INTRO 1 VEZ = 860 MS; LOOP = 3840 MS)", m, 9, "cream", 2)
	for k in 8:
		var x := m + (k % 4) * (640 + m)
		var y := 30 + (k / 4) * (360 + lab + m)
		tx(b, rot[k], x, y + 5, "y1" if k == 7 else "cream")
		blit(b, seq[chaves[k]][2], x, y + lab)
	b.save_png(ANIM + "menu_c_anim_prancha.png")


func _write(p: String, s: String) -> void:
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(s)
	f.close()
