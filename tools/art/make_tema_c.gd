extends SceneTree
## Identidade visual, direção C (cartaz de luta): ASSETS FINAIS em 1x (placeholder de qualidade, gerado por código). Diretor de Arte.
## Tudo original, tudo na paleta fechada (docs/arte/direcao-visual.md §3). Não mexe em ui/ nem em scenes/.
## Rodar de uma pasta com project.godot vazio (não dispara import no projeto), headless:
##   godot --headless --max-fps 30 --path <pasta_vazia> --script <worktree>/tools/art/make_tema_c.gd -- --root <worktree>
## Grava:
##   assets/sprites/ui/tema_c/   c_*.png  (HUD, barra, LUTAR!, botões, janela, título, cartão, chip, etiqueta, carimbos)
##   assets/sprites/menu/        menu_*.png + parede.json (parede de cartazes em camadas, faixa, logo, quadros da intro)
##   docs/arte/mockups/identidade/tema_c_final_*.png  (prancha de conferência montada COM as PNGs gravadas)
## Spec (margens, cores, onde vai cada peça, marcos da parede, tempos): docs/arte/tema-c-spec.md.
## O gerador mede e imprime: centro do texto em cada botão/faixa (margens esq/dir e cima/baixo, relativas à FACE, sem a sombra),
## contraste texto/base, e se algum item da parede sai da tela, encosta noutro, entra na faixa ou na coluna dos botões. Meta: 0 avisos.

var ROOT := "E:/Fightclicker/.claude/worktrees/identidade-visual"
var UI_OUT := ""
var MENU_OUT := ""
var MOCK_OUT := ""

const PAL := {
	"ink": "14101a", "d1": "2a2233", "d2": "3d3346",
	"g0": "4a4552", "g1": "6b6570", "g2": "8f8890", "g3": "b8b0aa",
	"cream": "d9cdb4", "white": "f2ece0",
	"br0": "3b2622", "br1": "6b3f2a", "br2": "9a5f36", "br3": "c98a4b",
	"y0": "e0a040", "y1": "f5d26b", "y2": "fff3c4",
	"r0": "5a1a22", "r1": "9c2a2a", "r2": "d4473a", "r3": "f07a5a",
	"b0": "1f2a44", "b1": "2f4a78", "b2": "4d7bb3", "b3": "8fbbe0",
	"st0": "3a4452", "st1": "5a6676", "st2": "7f8c9a", "st3": "a9b4bf",
	"gr0": "1f3d33", "gr1": "2f6b4a", "gr2": "5aa25a", "gr3": "a6d86a",
	"p0": "4a2f6b", "p1": "7a4fa0", "p2": "b07ad8",
	"f0": "7a2a52", "f1": "d4558f", "f2": "f59ac0",
	"sk0": "7a4632", "sk1": "b9744f", "sk2": "e3a275",
}
## Um passo mais escuro NA RAMPA (luz da parede do menu: nunca multiplicar cor).
const ESCURO := {
	"white": "cream", "cream": "g3", "g3": "g2", "g2": "g1", "g1": "g0", "g0": "d2", "d2": "d1", "d1": "ink", "ink": "ink",
	"y2": "y1", "y1": "y0", "y0": "br3", "br3": "br2", "br2": "br1", "br1": "br0", "br0": "ink",
	"r3": "r2", "r2": "r1", "r1": "r0", "r0": "ink", "b3": "b2", "b2": "b1", "b1": "b0", "b0": "ink",
	"st3": "st2", "st2": "st1", "st1": "st0", "st0": "ink", "gr3": "gr2", "gr2": "gr1", "gr1": "gr0", "gr0": "ink",
	"sk2": "sk1", "sk1": "sk0", "sk0": "br0", "p2": "p1", "p1": "p0", "p0": "ink", "f2": "f1", "f1": "f0", "f0": "ink",
}
const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
const MENU := ["CONTINUAR", "NOVO JOGO", "OPÇÕES", "SAIR"]
const SUB_MENU := "UM SOCO DE CADA VEZ"  # [ROT] provisório

# ---- grade do menu (640x360, 1x). Eixo único x = 320 (mesma do menu v2).
const AXIS := 320
const BAND_Y0 := 26
const BAND_B0 := 30
const BAND_B1 := 106
const BAND_Y1 := 112
const LOGO_Y := 48
const BTN_W := 152
const BTN_H := 22
const BTN_PITCH := 28
const BTN_Y := 164
const STRIPE := 16
## Zona proibida para os itens da parede: a coluna dos botões com as setas (e 4 px de folga).
const COLUNA := Rect2i(226, 156, 188, 128)

var G := {}
var cap_top := 2
var cap_h := 7
var avisos: Array = []
var icons := {}
var logo_L: Image
var logo_used: Rect2i
var pecas: Array = []  # [nome, tamanho, margens ou "", nota]
var nove_map := {}  # NOVE + as margens dos geradores irmãos


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--root" and i + 1 < args.size():
			ROOT = args[i + 1].replace("\\", "/")
	UI_OUT = ROOT + "/assets/sprites/ui/tema_c/"
	MENU_OUT = ROOT + "/assets/sprites/menu/"
	MOCK_OUT = ROOT + "/docs/arte/mockups/identidade/"
	for d in [UI_OUT, MENU_OUT, MOCK_OUT]:
		DirAccess.make_dir_recursive_absolute(d)
	_load_font()
	nove_map = NOVE.duplicate()
	_main()
	quit()


## Corpo do gerador. O gerador irmão (make_tema_c_id3.gd) herda deste arquivo e troca só esta função.
func _main() -> void:
	print("== TEMA C: peças da UI")
	_tema()
	print("== MENU: parede, faixa, logo, intro")
	logo_L = logo_layer("FIGHTCLICKER", 5, true, 4)
	logo_used = logo_L.get_used_rect()
	_menu_assets()
	print("== PRANCHAS")
	_pranchas()
	_manifest_tema()
	print("== peças gravadas:")
	for p in pecas:
		print("  %-34s %-9s %s %s" % [p[0], p[1], p[2], p[3]])
	print("== TOTAL: %d aviso(s) %s" % [avisos.size(), str(avisos) if avisos.size() > 0 else ""])


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


func novo(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


func px(img: Image, x: int, y: int, c) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, C(c))


func limpa(img: Image, x: int, y: int) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, Color(0, 0, 0, 0))


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


func disco(img: Image, cx: float, cy: float, r: float, c) -> void:
	for y in range(int(cy - r - 1), int(cy + r + 2)):
		for x in range(int(cx - r - 1), int(cx + r + 2)):
			if pow(x - cx, 2) + pow(y - cy, 2) <= r * r:
				px(img, x, y, c)


## Pinta por cima de tudo o que já é opaco no `L` (máscara) com a cor `c`.
func recolor(src: Image, mapa: Callable) -> Image:
	var o: Image = src.duplicate()
	for y in o.get_height():
		for x in o.get_width():
			var p := o.get_pixel(x, y)
			if p.a > 0.5:
				o.set_pixel(x, y, C(mapa.call(p)))
	return o


func salvar_ui(img: Image, nome: String, margens := "", nota := "") -> void:
	img.save_png(UI_OUT + nome + ".png")
	pecas.append(["ui/tema_c/" + nome, "%dx%d" % [img.get_width(), img.get_height()], margens, nota])


## Entradas prontas para o manifest (assets/sprites/manifest.json -> sprites): o UI/UX copia para lá ao aplicar o tema.
func _manifest_tema() -> void:
	# Junta com o que já está no arquivo: cada gerador (este e o make_tema_c_id3.gd) só reescreve as entradas dele.
	var sp := {}
	if FileAccess.file_exists(UI_OUT + "manifest_tema_c.json"):
		var velho = JSON.parse_string(FileAccess.get_file_as_string(UI_OUT + "manifest_tema_c.json"))
		if velho is Dictionary and velho.get("sprites") is Dictionary:
			sp = _inteiros(velho["sprites"])
	for p in pecas:
		var caminho: String = p[0]
		if not caminho.begins_with("ui/tema_c/"):
			continue
		var nome := caminho.get_file()
		var tam: PackedStringArray = str(p[1]).split("x")
		var e := {"file": "res://assets/sprites/" + caminho + ".png", "frame_size": [int(tam[0]), int(tam[1])], "frames": 1, "fps": 0.0,
			"pivot": [0, 0], "note": "Tema C (cartaz). " + str(p[3]) + ". Spec: docs/arte/tema-c-spec.md"}
		if nove_map.has(nome):
			var m: Array = nove_map[nome]
			e["nine_slice"] = {"left": m[0], "top": m[1], "right": m[2], "bottom": m[3]}
		sp[nome] = e
	var f := FileAccess.open(UI_OUT + "manifest_tema_c.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"_sobre": "Entradas do tema C para assets/sprites/manifest.json -> sprites. Gerado por tools/art/make_tema_c.gd e make_tema_c_id3.gd.", "sprites": sp}, "	"))
	f.close()


## O JSON lido volta com números em float (16.0): devolve os inteiros como int, menos o "fps" (que é float de propósito).
func _inteiros(v, chave_ := ""):
	if v is Dictionary:
		var o := {}
		for k in v:
			o[k] = _inteiros(v[k], str(k))
		return o
	if v is Array:
		var o: Array = []
		for e in v:
			o.append(_inteiros(e, chave_))
		return o
	if v is float and chave_ != "fps" and v == floorf(v):
		return int(v)
	return v


func salvar_menu(img: Image, nome: String, nota := "") -> void:
	img.save_png(MENU_OUT + nome + ".png")
	pecas.append(["menu/" + nome, "%dx%d" % [img.get_width(), img.get_height()], "", nota])


## Desenha uma textura 9-slice no retângulo (centro e bordas em LADRILHO, como o NinePatchRect com axis_stretch = TILE).
func nove(dst: Image, src: Image, r: Rect2i, l: int, t: int, ri: int, b: int) -> void:
	var sw := src.get_width()
	var sh := src.get_height()
	var cw := maxi(1, sw - l - ri)
	var ch := maxi(1, sh - t - b)
	for dy in r.size.y:
		var sy: int
		if dy < t:
			sy = dy
		elif dy >= r.size.y - b:
			sy = sh - (r.size.y - dy)
		else:
			sy = t + (dy - t) % ch
		for dx in r.size.x:
			var sx: int
			if dx < l:
				sx = dx
			elif dx >= r.size.x - ri:
				sx = sw - (r.size.x - dx)
			else:
				sx = l + (dx - l) % cw
			var c := src.get_pixel(sx, sy)
			if c.a > 0.0:
				var X := r.position.x + dx
				var Y := r.position.y + dy
				if X >= 0 and Y >= 0 and X < dst.get_width() and Y < dst.get_height():
					var o := dst.get_pixel(X, Y)
					dst.set_pixel(X, Y, o.blend(c))


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


## Largura VISÍVEL (sem a folga depois da última letra), como UiTema.largura_visivel.
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


## Caixa real dos pixels de um texto (só a altura das maiúsculas conta no centro vertical: centro óptico).
func tx_box(s: String, x: int, ycap: int, sc := 1) -> Rect2i:
	var x0 := 99999
	var x1 := -99999
	var y0 := 99999
	var y1 := -99999
	var pen := 0
	for i in s.length():
		var g := _g(s.unicode_at(i))
		for p in g.px:
			var yy: int = g.yo + p.y - cap_top
			if yy < 0 or yy >= cap_h:
				continue
			x0 = mini(x0, x + (pen + g.xo + p.x) * sc)
			x1 = maxi(x1, x + (pen + g.xo + p.x) * sc + sc - 1)
			y0 = mini(y0, ycap + yy * sc)
			y1 = maxi(y1, ycap + yy * sc + sc - 1)
		pen += g.adv
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


func ycap_in(y: int, h: int, sc := 1) -> int:
	return y + int(floor((h - cap_h * sc) / 2.0))


## Texto centrado numa área (regra do jogo: x = floor((w - largura visível) / 2)). Devolve a caixa real.
func tx_c(img: Image, s: String, area: Rect2i, c, sc := 1, sh = null, shc = "ink") -> Rect2i:
	var x0 := area.position.x + int(floor((area.size.x - tw(s, sc)) / 2.0))
	var yc := ycap_in(area.position.y, area.size.y, sc)
	tx(img, s, x0, yc, c, sc, sh, shc)
	return tx_box(s, x0, yc, sc)


# ================================================================= medidas
func medir(nome: String, face: Rect2i, t: Rect2i, min_lado := 2, min_cima := 2) -> void:
	var ml := t.position.x - face.position.x
	var mr := face.end.x - t.end.x
	var mt := t.position.y - face.position.y
	var mb := face.end.y - t.end.y
	var ok := absi(ml - mr) <= 1 and absi(mt - mb) <= 1 and ml >= min_lado and mt >= min_cima
	print("  %-30s esq %3d dir %3d | cima %2d baixo %2d  %s" % [nome, ml, mr, mt, mb, "ok" if ok else "AVISO"])
	if not ok:
		avisos.append(nome + " descentrado")


func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func contraste(a, b) -> float:
	var la := _lum(C(a))
	var lb := _lum(C(b))
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Texto 1x precisa de 4,5:1; texto 2x ou maior, 3:1 (regra de texto grande). `livre` = estado desabilitado (não conta).
func conferir_contraste(nome: String, fg, bg, sc := 1, livre := false) -> void:
	var k := contraste(fg, bg)
	var meta := 4.5 if sc == 1 else 3.0
	var ok := livre or k >= meta
	print("  %-30s %s sobre %s = %.1f:1 (meta %.1f)%s" % [nome, fg, bg, k, meta, "" if ok else "  AVISO"])
	if not ok:
		avisos.append("%s: contraste %.1f:1" % [nome, k])


# ================================================================= texturas
## Papel de cartaz: creme com manchas g3 ralas em dither (período `per`, para ladrilhar sem emenda).
func papel_px(u: int, v: int, per := 16) -> String:
	var U := posmod(u, per)
	var V := posmod(v, per)
	var n := (U * 7 + V * 13 + (U * V) % 11) % 23
	if n == 0 and bayer(U, V) < 8:
		return "g3"
	return "cream"


## Asfalto: d1 com grão d2 e raros pontos ink (período 16).
func asfalto_px(u: int, v: int) -> String:
	var U := posmod(u, 16)
	var V := posmod(v, 16)
	var n := (U * 5 + V * 11 + (U * V) % 7) % 19
	if n == 0:
		return "d2"
	if n == 9 and bayer(U, V) < 4:
		return "ink"
	return "d1"


# ================================================================= TEMA C
func _tema() -> void:
	# --- HUD: faixa de asfalto (16x21: 18 de faixa + ink + r1 + sombra em dither por cima da sala)
	var hud := novo(16, 21)
	for y in 18:
		for x in 16:
			px(hud, x, y, "d2" if y == 0 else asfalto_px(x, y - 1))
	hl(hud, 0, 18, 16, "ink")
	hl(hud, 0, 19, 16, "r1")
	for x in 16:
		if x % 2 == 0:
			px(hud, x, 20, "ink")
	salvar_ui(hud, "c_hud_faixa", "L0 T1 R0 B3", "ladrilho; painel 640x21 (área útil 18)")
	# separador diagonal entre os grupos: faixa r2 (3 px) + fio creme (1 px), inclinação 1:3
	var sep := novo(9, 18)
	for y in 18:
		var o := (17 - y) / 3
		hl(sep, o, y, 3, "r2")
		px(sep, o + 3, y, "cream")
	salvar_ui(sep, "c_hud_sep", "", "fixo; centro óptico x=4")
	# etiqueta de papel do local (canto esquerdo cortado em diagonal, altura fixa 18)
	var et := novo(24, 18)
	for y in 18:
		var o := (17 - y) / 3
		for x in range(o, 24):
			px(et, x, y, "ink" if x == o else ("g3" if y == 17 else papel_px(x - 7, y)))
	salvar_ui(et, "c_hud_etiqueta", "L7 T1 R1 B1", "altura fixa 18; ladrilho")

	# --- barra de baixo: papel de cartaz com borda grossa ink em cima
	var bar := novo(16, 30)
	for y in 30:
		for x in 16:
			var c := "ink" if y < 2 else ("white" if y == 2 else papel_px(x, y - 3))
			px(bar, x, y, c)
	salvar_ui(bar, "c_barra", "L0 T3 R0 B0", "ladrilho; 640x30")
	# faixa diagonal vermelha atrás do LUTAR! e do POSTO (fica em x 480 da barra)
	var fx := novo(160, 30)
	for y in range(2, 30):
		var o := (29 - y) / 2
		var e := 14 + o
		for x in range(e - 4, e - 1):
			px(fx, x, y, "ink")
		for x in range(e, 160):
			var k := posmod(x + y, STRIPE)
			px(fx, x, y, "r1" if (k < 6 and bayer(x, y) < 8) or k == 6 else "r2")
	salvar_ui(fx, "c_barra_faixa", "", "fixo 160x30 em (480, 0) da barra")

	# --- LUTAR!: chapa inclinada 102x24, 4 estados
	var lut_cfg := {
		"normal": {"face": "cream", "hi": "white", "lo": "g3", "sombra": true, "dy": 0},
		"hover": {"face": "y2", "hi": "white", "lo": "y1", "sombra": true, "dy": 0},
		"pressed": {"face": "cream", "hi": "g3", "lo": "cream", "sombra": false, "dy": 2},
		"disabled": {"face": "g3", "hi": "g3", "lo": "g3", "sombra": false, "dy": 0},
	}
	for st in lut_cfg:
		var cf: Dictionary = lut_cfg[st]
		var ch := _chapa(cf)
		salvar_ui(ch, "c_lutar_" + st, "L8 T%d R8 B%d" % [2 + cf.dy, 4 - cf.dy], "fixo 102x24 (rect LUTAR)")

	# --- botões 9-slice 12x16 (face 14 + sombra dura 2 RETA para baixo)
	var btns := {
		"c_btn_normal": ["d1", "d2", "r1", false, "ink"],
		"c_btn_foco": ["r1", "r2", "ink", false, "ink"],
		"c_btn_apertado": ["r1", "r0", "", true, "ink"],
		"c_btn_desabilitado": ["d2", "d2", "", false, "ink"],
		"c_btn_papel_normal": ["cream", "white", "r1", false, "ink"],
		"c_btn_papel_desabilitado": ["g3", "g3", "", false, "g1"],
	}
	for n in btns:
		var a: Array = btns[n]
		var im := _botao(a[0], a[1], a[2], a[3], a[4])
		salvar_ui(im, n, "L2 T4 R2 B2" if a[3] else "L2 T2 R2 B4", "ladrilho")

	# --- janela: papel creme, borda ink de 2, sombra dura de 3 para baixo (22x25)
	var jan := novo(22, 25)
	for y in 22:
		for x in 22:
			var c := papel_px(x - 3, y - 3)
			if x < 2 or y < 2 or x >= 20 or y >= 20:
				c = "ink"
			elif y == 2:
				c = "white"
			px(jan, x, y, c)
	rect(jan, 0, 22, 22, 3, "ink")
	salvar_ui(jan, "c_janela", "L3 T3 R3 B6", "ladrilho; rect +3 px de altura (sombra)")
	# cartão pequeno (painéis da sala): borda 1, sombra 2 (12x14)
	var car := novo(12, 14)
	for y in 12:
		for x in 12:
			var c := papel_px(x - 2, y - 2, 8)
			if x == 0 or y == 0 or x == 11 or y == 11:
				c = "ink"
			elif y == 1:
				c = "white"
			px(car, x, y, c)
	rect(car, 0, 12, 12, 2, "ink")
	salvar_ui(car, "c_cartao", "L2 T2 R2 B4", "ladrilho; rect +2 px (sombra)")
	# cabeçalho vermelho da janela, cortado em diagonal à direita (altura fixa)
	salvar_ui(_titulo(16), "c_janela_titulo", "L2 T1 R10 B2", "altura fixa 16 (texto 1x)")
	salvar_ui(_titulo(30), "c_janela_titulo_g", "L2 T1 R16 B2", "altura fixa 30 (texto 2x/3x)")

	# --- chip (ink) e etiqueta (papel)
	var chip := novo(8, 13)
	rect(chip, 0, 0, 8, 13, "ink")
	hl(chip, 1, 1, 6, "d2")
	salvar_ui(chip, "c_chip", "L2 T2 R2 B2", "ladrilho; altura 13 (texto creme)")
	# etiqueta de preço: face 11 (borda ink), cantos da esquerda cortados, furo do barbante, sombra d2 de 1
	var etq := novo(12, 12)
	for y in 11:
		for x in 12:
			px(etq, x, y, papel_px(x, y, 8))
	frame(etq, 0, 0, 12, 11, "ink")
	for p in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 10), Vector2i(1, 10), Vector2i(0, 9)]:
		limpa(etq, p.x, p.y)
	for p in [Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(0, 8), Vector2i(1, 9), Vector2i(2, 10)]:
		px(etq, p.x, p.y, "ink")
	px(etq, 3, 5, "ink")  # furo do barbante
	hl(etq, 2, 11, 10, "d2")
	salvar_ui(etq, "c_etiqueta", "L5 T1 R1 B2", "altura fixa 12 (face 11 + sombra 1; texto ink)")

	# --- carimbos
	salvar_ui(_carimbo_perigoso(), "c_carimbo_perigoso", "", "fixo 72x16")
	salvar_ui(_carimbo_moldura(), "c_carimbo_moldura", "L4 T4 R4 B4", "ladrilho; p/ outras palavras (texto r2)")
	salvar_ui(_carimbo_raizes(40, "school_symbol_16"), "c_carimbo_raizes", "", "fixo 40x40")
	salvar_ui(_carimbo_raizes(24, "school_symbol_9"), "c_carimbo_raizes_p", "", "fixo 24x24")

	# --- medidas das peças (texto no centro da FACE, sem a sombra) e contraste
	_medir_tema()


func _chapa(cf: Dictionary) -> Image:
	var im := novo(102, 24)
	var dy: int = cf.dy
	if cf.sombra:
		for f in 22:
			var o := (21 - f) / 3
			hl(im, o, f + 2, 95, "ink")
	for f in 22:
		var o := (21 - f) / 3
		var y := f + dy
		for x in range(o, o + 95):
			var c: String = cf.face
			if x == o or x == o + 94 or f == 0 or f == 21:
				c = "ink"
			elif f == 1:
				c = cf.hi
			elif f == 20:
				c = cf.lo
			elif cf.face == "cream" and papel_px(x, f) == "g3":
				c = "g3"
			px(im, x, y, c)
	return im


func _botao(face: String, hi: String, sombra: String, apertado: bool, borda: String) -> Image:
	var im := novo(12, 16)
	var y0 := 2 if apertado else 0
	if sombra != "":
		rect(im, 0, 14, 12, 2, sombra)
	for y in 14:
		for x in 12:
			var c := face
			if x == 0 or x == 11 or y == 0 or y == 13:
				c = borda
			elif y == 1:
				c = hi
			elif face == "cream" and papel_px(x - 2, y - 2, 8) == "g3":
				c = "g3"
			px(im, x, y + y0, c)
	return im


func _titulo(h: int) -> Image:
	var fr := h - 2  # linhas da face (as 2 de baixo são o fio ink duplo)
	var maxo := (fr - 1) / 2
	var W := 2 + 16 + maxo + 3
	var im := novo(W, h)
	for y in fr:
		var o := (fr - 1 - y) / 2
		var xe := 18 + o
		for x in xe:
			px(im, x, y, "r2" if y == 0 else "r1")
		px(im, xe - 4, y, "r2")  # risco paralelo ao corte (velocidade de cartaz)
		px(im, xe, y, "ink")
		px(im, xe + 1, y, "ink")
	for y in range(fr, h):
		hl(im, 0, y, 20, "ink")
	return im


func _carimbo_perigoso() -> Image:
	var im := novo(72, 16)
	frame(im, 0, 0, 72, 16, "r2")
	frame(im, 2, 2, 68, 12, "r2")
	for y in 16:  # falhas de tinta (sorteio fixo) só na moldura: a palavra fica inteira
		for x in 72:
			if im.get_pixel(x, y).a > 0.5 and (x * 37 + y * 17 + 5) % 7 == 0:
				limpa(im, x, y)
	tx_c(im, "PERIGOSO", Rect2i(0, 0, 72, 16), "r2")
	return im


func _carimbo_moldura() -> Image:
	var im := novo(12, 12)
	frame(im, 0, 0, 12, 12, "r2")
	frame(im, 2, 2, 8, 8, "r2")
	for y in 12:
		for x in 12:
			if im.get_pixel(x, y).a > 0.5 and (posmod(x - 4, 4) * 3 + posmod(y - 4, 4) * 5) % 11 == 7:
				limpa(im, x, y)
	return im


func _carimbo_raizes(n: int, simbolo: String) -> Image:
	var im := novo(n, n)
	var r := n / 2.0 - 0.5
	var cx := (n - 1) / 2.0
	for y in n:
		for x in n:
			var d := sqrt(pow(x - cx, 2) + pow(y - cx, 2))
			var anel := d <= r and d > r - 2.0
			var anel2 := n >= 30 and d <= r - 4.0 and d > r - 5.0
			if (anel or anel2) and (x * 31 + y * 17 + 7) % 9 != 0:
				px(im, x, y, "b1")
	var s := recolor(icon(simbolo), func(c: Color) -> String: return "b0" if _lum(c) < 0.05 else "b1")
	blit(im, s, (n - s.get_width()) / 2, (n - s.get_height()) / 2)
	return im


func _medir_tema() -> void:
	print("-- centro do texto nos botões (face sem sombra)")
	var amostras := [["c_btn_normal", 86, 20, "ESTEIRA", "cream"], ["c_btn_foco", 86, 20, "SACO", "cream"],
		["c_btn_apertado", 86, 20, "SACO", "cream"], ["c_btn_desabilitado", 86, 20, "CORDA", "g2"],
		["c_btn_papel_normal", BTN_W, BTN_H, "NOVO JOGO", "ink"], ["c_btn_foco", BTN_W, BTN_H, "CONTINUAR", "cream"],
		["c_btn_papel_normal", 90, 20, "FECHAR", "ink"], ["c_btn_papel_desabilitado", 90, 20, "FECHAR", "g1"]]
	for a in amostras:
		var im := novo(a[1] + 4, a[2] + 4)
		var b := botao_em(im, a[0], Rect2i(2, 2, a[1], a[2]), a[3], a[4])
		medir("%s %dx%d %s" % [a[0], a[1], a[2], a[3]], b[0], b[1])
	print("-- LUTAR! (2x, centro da chapa na linha do meio do texto)")
	for st in ["normal", "hover", "pressed", "disabled"]:
		var im := novo(110, 30)
		var b := lutar_em(im, st, Vector2i(2, 2))
		medir("c_lutar_" + st, b[0], b[1])
	print("-- títulos, chip, etiqueta, carimbo")
	var tj := novo(200, 40)
	var t1 := titulo_em(tj, "c_janela_titulo", Rect2i(0, 0, 120, 16), "VITÓRIA", 1)
	medir("c_janela_titulo 120x16", t1[0], t1[1])
	var t2 := titulo_em(tj, "c_janela_titulo_g", Rect2i(0, 0, 160, 30), "VITÓRIA!", 2)
	medir("c_janela_titulo_g 160x30 (2x)", t2[0], t2[1])
	var ch := novo(160, 20)
	var c1 := chip_em(ch, "c_chip", Rect2i(0, 0, tw(SUB_MENU) + 14, 13), SUB_MENU, "cream")
	medir("c_chip subtítulo", c1[0], c1[1])
	var c2 := chip_em(ch, "c_etiqueta", Rect2i(0, 0, 60, 12), "NOVO", "ink")
	medir("c_etiqueta NOVO", c2[0], c2[1])
	var bx := tx_box("PERIGOSO", int(floor((72 - tw("PERIGOSO")) / 2.0)), ycap_in(0, 16))
	medir("c_carimbo_perigoso", Rect2i(0, 0, 72, 16), bx)
	print("-- contraste")
	conferir_contraste("HUD rótulo", "g3", "d1")
	conferir_contraste("HUD texto", "cream", "d1")
	conferir_contraste("HUD Treino", "gr3", "d1")
	conferir_contraste("HUD Dinheiro", "y1", "d1")
	conferir_contraste("HUD Fama (asfalto)", "f2", "d1")
	conferir_contraste("HUD Legado (asfalto)", "p2", "d1")
	conferir_contraste("etiqueta local", "ink", "cream")
	conferir_contraste("Fama sobre claro", "f0", "cream")
	conferir_contraste("Legado sobre claro", "p0", "cream")
	conferir_contraste("Dinheiro sobre claro", "br1", "cream")
	conferir_contraste("Treino sobre claro 1x", "gr0", "cream")
	conferir_contraste("Treino sobre claro 2x", "gr1", "cream", 2)
	conferir_contraste("botão asfalto", "cream", "d1")
	conferir_contraste("botão foco", "cream", "r1")
	conferir_contraste("botão papel", "ink", "cream")
	conferir_contraste("botão desabilitado", "g2", "d2", 1, true)
	conferir_contraste("LUTAR! 2x", "r1", "cream", 2)
	conferir_contraste("LUTAR! hover 2x", "r1", "y2", 2)
	conferir_contraste("título janela", "cream", "r1")
	conferir_contraste("chip", "cream", "ink")
	conferir_contraste("carimbo PERIGOSO", "r2", "cream", 1, true)
	print("  (proibido: white sobre r2 = %.1f:1, cream sobre r2 = %.1f:1)" % [contraste("white", "r2"), contraste("cream", "r2")])


# ---- usar as peças (a prancha e as medidas usam as PNGs gravadas, como o jogo vai usar)
func peca(nome: String) -> Image:
	return _img(UI_OUT + nome + ".png")


const NOVE := {
	"c_hud_faixa": [0, 1, 0, 3], "c_hud_etiqueta": [7, 1, 1, 1], "c_barra": [0, 3, 0, 0],
	"c_btn_normal": [2, 2, 2, 4], "c_btn_foco": [2, 2, 2, 4], "c_btn_apertado": [2, 4, 2, 2], "c_btn_desabilitado": [2, 2, 2, 4],
	"c_btn_papel_normal": [2, 2, 2, 4], "c_btn_papel_desabilitado": [2, 2, 2, 4],
	"c_janela": [3, 3, 3, 6], "c_cartao": [2, 2, 2, 4], "c_janela_titulo": [2, 1, 10, 2], "c_janela_titulo_g": [2, 1, 16, 2],
	"c_chip": [2, 2, 2, 2], "c_etiqueta": [5, 1, 1, 2], "c_carimbo_moldura": [4, 4, 4, 4],
}


func nove_peca(dst: Image, nome: String, r: Rect2i) -> void:
	var m: Array = nove_map[nome]
	nove(dst, peca(nome), r, m[0], m[1], m[2], m[3])


## Botão no rect (a sombra fica DENTRO do rect, como no jogo). Texto centrado na área de conteúdo (margens do 9-slice).
## Devolve [face, caixa do conteúdo].
func botao_em(img: Image, nome: String, r: Rect2i, s: String, cor, ic = null, gap := 4) -> Array:
	nove_peca(img, nome, r)
	var m: Array = nove_map[nome]
	var area := Rect2i(r.position.x + m[0], r.position.y + m[1], r.size.x - m[0] - m[2], r.size.y - m[1] - m[3])
	var face := Rect2i(r.position.x, r.position.y + (2 if nome == "c_btn_apertado" else 0), r.size.x, r.size.y - 2)
	var sombra_txt = Vector2i(0, 1) if nome in ["c_btn_foco", "c_btn_apertado"] else null
	var caixa: Rect2i
	if ic != null:
		var im: Image = ic
		var wt := im.get_width() + gap + tw(s)
		var x0 := area.position.x + int(floor((area.size.x - wt) / 2.0))
		var iy := area.position.y + int(floor((area.size.y - im.get_height()) / 2.0))
		blit(img, im, x0, iy)
		var yc := ycap_in(area.position.y, area.size.y)
		tx(img, s, x0 + im.get_width() + gap, yc, cor, 1, sombra_txt)
		var tb := tx_box(s, x0 + im.get_width() + gap, yc)
		caixa = Rect2i(x0, mini(iy, tb.position.y), tb.end.x - x0, maxi(iy + im.get_height(), tb.end.y) - mini(iy, tb.position.y))
	else:
		caixa = tx_c(img, s, area, cor, 1, sombra_txt)
	return [face, caixa]


func lutar_em(img: Image, st: String, p: Vector2i) -> Array:
	blit(img, peca("c_lutar_" + st), p.x, p.y)
	var dy := 2 if st == "pressed" else 0
	var area := Rect2i(p.x + 8, p.y + 2 + dy, 86, 18)
	var cor := "g1" if st == "disabled" else "r1"
	var b := tx_c(img, "LUTAR!", area, cor, 2, null if st == "disabled" else Vector2i(0, 1))
	# face na linha do meio do texto: a chapa é inclinada, o centro dela anda 1 px a cada 3 linhas
	var f := (b.position.y + b.size.y / 2) - p.y - dy
	var o := (21 - f) / 3
	return [Rect2i(p.x + o, p.y + dy, 95, 22), b]


func titulo_em(img: Image, nome: String, r: Rect2i, s: String, sc: int) -> Array:
	nove_peca(img, nome, r)
	var m: Array = nove_map[nome]
	var area := Rect2i(r.position.x + m[0], r.position.y + m[1], r.size.x - m[0] - m[2], r.size.y - m[1] - m[3])
	return [area, tx_c(img, s, area, "cream", sc, Vector2i(0, 1))]


func chip_em(img: Image, nome: String, r: Rect2i, s: String, cor) -> Array:
	nove_peca(img, nome, r)
	if nome == "c_etiqueta":
		# área de conteúdo do 9-slice (L5 T1 R1 B2); a face que o olho lê vai do furo (x+4) até a borda direita
		var area := Rect2i(r.position.x + 5, r.position.y + 1, r.size.x - 6, r.size.y - 3)
		var face := Rect2i(r.position.x + 4, r.position.y, r.size.x - 4, r.size.y - 1)
		return [face, tx_c(img, s, area, cor)]
	var a := Rect2i(r.position.x, r.position.y, r.size.x, r.size.y)
	return [a, tx_c(img, s, a, cor)]


# ================================================================= MENU
## Luz da parede: 0 = luz da lâmpada (cone no eixo), 1 = um passo mais escuro, 2 = dois. Bordas em dither Bayer.
func luz(x: int, y: int) -> int:
	var n := 1
	if y >= BAND_Y1:
		var t := clampf(float(y - BAND_Y1) / float(360 - BAND_Y1), 0.0, 1.0)
		var hw := lerpf(74.0, 196.0, t)
		var d := absf(x - 320.0) / hw
		if d < 0.82 or (d < 1.0 and bayer(x, y) >= 8):
			n = 0
	var dx := absf(x - 320.0) / 320.0
	var dy := float(y) / 360.0
	var e := dx * dx * 0.9 + dy * dy * 0.3
	if e > 0.78 or (e > 0.66 and bayer(x, y) < 8):
		n += 1
	return mini(n, 2)


func escurecer(c: Color, passos: int) -> Color:
	if passos <= 0 or c.a < 0.5:
		return c
	var h := c.to_html(false)
	for k in PAL:
		if PAL[k] == h:
			var nome: String = k
			for i in passos:
				nome = ESCURO.get(nome, nome)
			return Color(C(nome), c.a)
	return c.lerp(C("ink"), 0.3 * passos)


## `teto`: os itens escurecem no máximo 1 passo (o cartaz tem de continuar legível); a parede vai até 2.
func iluminar(img: Image, ox: int, oy: int, teto := 2) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				img.set_pixel(x, y, escurecer(c, mini(teto, luz(ox + x, oy + y))))


func _parede_base() -> Image:
	var w := novo(640, 360)
	for y in 360:
		for x in 640:
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
	rect(w, 0, 348, 640, 12, "d1")
	hl(w, 0, 348, 640, "g0")
	for x in range(0, 640, 3):
		if bayer(x, 352) < 6:
			px(w, x, 352 + (x % 5), "d2")
	# restos de cartazes velhos (papel arrancado, grampos): a parede é gasta, mas não conta história
	for s in [[200, 300, 16, 12], [8, 296, 10, 22], [424, 296, 14, 16], [612, 286, 14, 20], [196, 118, 12, 8], [446, 228, 10, 12],
			[136, 300, 12, 10], [10, 140, 8, 14]]:
		_resto(w, s[0], s[1], s[2], s[3])
	return w


func _resto(w: Image, x: int, y: int, cw: int, ch: int) -> void:
	for yy in ch:
		for xx in cw:
			var borda := (xx * 5 + yy * 3) % 7
			if (yy == 0 and borda < 3) or (xx == cw - 1 and borda < 4) or (yy == ch - 1 and borda < 2):
				continue
			px(w, x + xx, y + yy, "g2" if (xx + yy * 3) % 9 != 0 else "g3")
	px(w, x + 1, y + 1, "st3")
	px(w, x + 2, y + 1, "st3")


# ---- itens da parede (cada um com sombra de 1 px e fita/prego próprios; fundo transparente)
func _cartaz_base(w: int, h: int, papel := "cream", rasgo := 1) -> Image:
	var im := novo(w + 1, h + 2)
	rect(im, 1, 2, w, h, "d2")  # sombra na parede
	for y in h:
		for x in w:
			var c := papel_px(x, y) if papel == "cream" else papel
			if papel == "white" and papel_px(x, y) == "g3":
				c = "cream"
			px(im, x, y + 1, c)
	vl(im, w - 1, 1, h, "g3")
	hl(im, 0, h, w, "g3")
	if rasgo == 1:  # canto de baixo à direita rasgado
		for i in 5:
			for j in 5 - i:
				limpa(im, w - 1 - j, h - i)
			px(im, w - 5 + i, h - i, "g3")
			px(im, w - 4 + i, h + 1 - i, "d2")
	elif rasgo == -1:  # canto de baixo à esquerda
		for i in 5:
			for j in 5 - i:
				limpa(im, j, h - i)
			px(im, 4 - i, h - i, "g3")
	# fita nos cantos de cima
	rect(im, 0, 0, 5, 3, "g3")
	rect(im, w - 5, 0, 5, 3, "g3")
	hl(im, 0, 0, 5, "white")
	hl(im, w - 5, 0, 5, "white")
	return im


func item_soco() -> Image:
	var W := 50
	var im := _cartaz_base(W, 64)
	rect(im, 3, 4, W - 6, 36, "r2")
	hl(im, 3, 4, W - 6, "r3")
	# lutador em silhueta dando o soco para a direita
	disco(im, 17, 14, 4.2, "ink")
	rect(im, 15, 18, 5, 3, "ink")
	for y in range(20, 40):
		var a := (y - 20) / 4
		hl(im, 11 - a / 2, y, 11 + a, "ink")
	rect(im, 19, 21, 16, 4, "ink")  # braço esticado
	rect(im, 34, 19, 7, 8, "ink")   # luva
	px(im, 40, 19, "r2"); px(im, 40, 26, "r2")
	rect(im, 20, 16, 4, 6, "ink")   # guarda
	for k in 3:  # traços de velocidade
		hl(im, 41 + 2, 18 + k * 4, 3, "cream")
	var b := tx_c(im, "SOCO", Rect2i(0, 42, W, 16), "ink", 2)
	hl(im, 8, 59, W - 16, "ink")
	hl(im, 14, 61, W - 28, "g1")
	medir("parede: SOCO no cartaz", Rect2i(0, 42, W, 16), b, 2, 1)
	return im


func item_generico() -> Image:
	var W := 50
	var im := _cartaz_base(W, 64, "cream", -1)
	rect(im, 3, 4, W - 6, 11, "ink")
	tx_c(im, "SÁBADO", Rect2i(3, 4, W - 6, 11), "cream")
	# dois filetes diagonais azuis (velocidade de cartaz)
	for y in range(17, 21):
		var o := 20 - y
		hl(im, 3 + o, y, W - 10, "b1" if y > 17 else "b2")
	var b := tx_c(im, "LUTA", Rect2i(0, 22, W, 16), "ink", 2)
	medir("parede: LUTA no cartaz", Rect2i(0, 22, W, 16), b, 1, 1)
	# dois lutadores genéricos frente a frente (sem rosto), em azul
	for s in [-1, 1]:
		var cx: int = W / 2 + s * 9
		disco(im, cx, 42, 2.6, "b1")
		rect(im, cx - 3, 45, 7, 7, "b1")
		rect(im, cx - s * 6 - (2 if s > 0 else 0), 46, 5, 3, "b1")
		rect(im, cx - 3, 52, 2, 3, "b0"); rect(im, cx + 2, 52, 2, 3, "b0")
	hl(im, 6, 56, W - 12, "g1")
	tx_c(im, "20H", Rect2i(0, 57, W, 8), "r1")
	return im


func item_recorte_vitoria() -> Image:
	var W := 48
	var H := 36
	var im := _cartaz_base(W, H, "white", 0)
	limpa_fita(im, W)
	rect(im, W / 2 - 3, 0, 7, 3, "g3"); hl(im, W / 2 - 3, 0, 7, "white")
	tx_c(im, "GARAGEM", Rect2i(0, 3, W, 9), "ink")
	hl(im, 3, 12, W - 6, "ink")
	rect(im, 3, 15, 18, 15, "g1")  # foto: braços erguidos
	disco(im, 12, 19, 1.8, "ink")
	rect(im, 10, 21, 5, 8, "ink")
	vl(im, 8, 16, 6, "ink"); vl(im, 16, 16, 6, "ink")
	hl(im, 3, 29, 18, "g0")
	for i in 6:
		hl(im, 24, 16 + i * 2 + 1, W - 28 - (i % 3) * 3, "g2")
	hl(im, 3, 32, W - 10, "g2")
	return im


func limpa_fita(im: Image, W: int) -> void:
	for y in 3:
		for x in range(0, W):
			if y == 0:
				limpa(im, x, y)
	rect(im, 0, 1, W, 2, "white")
	for x in W:
		if (x * 3) % 7 == 0:
			px(im, x, 1, "cream")


func item_foto_equipe() -> Image:
	var im := novo(33, 38)
	rect(im, 1, 3, 32, 35, "d2")
	rect(im, 0, 2, 32, 35, "white")
	vl(im, 31, 2, 35, "g3"); hl(im, 0, 36, 32, "g3")
	rect(im, 3, 5, 26, 22, "g0")
	rect(im, 3, 20, 26, 7, "d2")
	hl(im, 3, 5, 26, "g1")
	# três de pé: treinador (cinza), o primeiro lutador (calção vermelho) e o discípulo (calção azul)
	var gente := [[8, "g2", "g3"], [16, "r1", "sk1"], [24, "b1", "sk2"]]
	for g in gente:
		var x: int = g[0]
		disco(im, x, 11, 2.2, "sk1" if g[1] != "g2" else "sk0")
		rect(im, x - 2, 14, 5, 6, g[2] if g[1] != "g2" else "g2")
		rect(im, x - 2, 20, 5, 3, g[1])
		rect(im, x - 2, 23, 2, 3, "sk0"); rect(im, x + 1, 23, 2, 3, "sk0")
	for i in 3:
		hl(im, 6 + i * 7, 31, 5, "g1")
	disco(im, 16, 2, 1.5, "r2")
	px(im, 15, 1, "r3")
	return im


func item_raizes() -> Image:
	var W := 52
	var H := 46
	var im := novo(W + 1, H + 9)
	# barbante até o prego
	for i in 14:
		px(im, W / 2 - 1 - i * 2, 2 + i / 2 + 1, "g2")
		px(im, W / 2 + 1 + i * 2, 2 + i / 2 + 1, "g2")
	rect(im, W / 2 - 1, 0, 3, 3, "st2"); px(im, W / 2, 0, "st3")
	var y0 := 9
	rect(im, 1, y0 + 1, W, H, "d2")
	rect(im, 0, y0, W, H, "br1")
	hl(im, 0, y0, W, "br2"); vl(im, 0, y0, H, "br2")
	hl(im, 0, y0 + H - 1, W, "br0"); vl(im, W - 1, y0, H, "br0")
	frame(im, 2, y0 + 2, W - 4, H - 4, "br0")
	for y in range(y0 + 3, y0 + H - 3):
		for x in range(3, W - 3):
			px(im, x, y, papel_px(x, y))
	tx_c(im, "RAÍZES", Rect2i(3, y0 + 3, W - 6, 12), "ink")
	var car := _carimbo_raizes(24, "school_symbol_9")
	blit(im, car, (W - 24) / 2, y0 + 15)
	hl(im, 10, y0 + H - 6, W - 20, "g1")
	return im


func item_capuz() -> Image:
	var im := novo(30, 44)
	var m := novo(30, 44)  # máscara do pano (para o contorno sair certo)
	for y in range(3, 42):
		var hw: float
		if y < 11:
			hw = 2.0 + (y - 3) * 1.2
		elif y < 27:
			hw = 11.5
		elif y < 31:
			hw = 10.0
		else:
			hw = 10.0 + (y - 31) * 0.4
		for x in range(int(round(15 - hw)), int(round(15 + hw)) + 1):
			if y == 41 and x % 2 == 0:
				continue  # barra desfiada
			m.set_pixel(x, y, Color.WHITE)
	for y in 44:
		for x in 30:
			if m.get_pixel(x, y).a < 0.5:
				continue
			var borda := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= 30 or q.y >= 44 or m.get_pixel(q.x, q.y).a < 0.5:
					borda = true
			var c := "d2"
			if borda:
				c = "ink"
			elif x < 9:
				c = "g0"
			elif x > 22:
				c = "d1"
			elif y > 30 and (x + y) % 4 == 0:
				c = "d1"  # dobras do caimento
			px(im, x, y, c)
	# abertura do rosto: oval escuro com debrum vermelho
	for y in range(10, 28):
		for x in range(7, 24):
			var e := pow((x - 15.0) / 6.0, 2) + pow((y - 18.5) / 8.5, 2)
			if e <= 1.0:
				px(im, x, y, "ink")
			elif e <= 1.45:
				px(im, x, y, "r1")
	for x in range(11, 20):  # sombra do capuz dentro da abertura
		px(im, x, 11, "b0")
	vl(im, 12, 27, 7, "cream"); vl(im, 18, 27, 6, "cream")
	px(im, 12, 34, "g3"); px(im, 18, 33, "g3")
	rect(im, 14, 0, 3, 3, "st2"); px(im, 15, 0, "st3")
	return im


func item_liga() -> Image:
	var W := 62
	var H := 80
	var im := _cartaz_base(W, H)
	rect(im, 2, 3, W - 4, 18, "r1")
	hl(im, 2, 3, W - 4, "r2")
	var b := tx_c(im, "LIGA", Rect2i(2, 3, W - 4, 18), "cream", 2, Vector2i(0, 1))
	medir("parede: LIGA no cartaz", Rect2i(2, 3, W - 4, 18), b, 2)
	tx_c(im, "DO VALE", Rect2i(0, 22, W, 9), "r1")
	frame(im, 4, 31, W - 8, 30, "ink")
	rect(im, 5, 32, W - 10, 28, "b0")
	# o rival em busto (sombra azul, sem rosto): cabelo, cabeça, pescoço e ombros largos
	var cx := W / 2
	for y in range(50, 60):
		var hw := 9 + (y - 50) * 1.4
		for x in range(int(cx - hw), int(cx + hw) + 1):
			px(im, x, y, "b2" if x < cx else "b1")
	hl(im, cx - 4, 50, 9, "b0")  # gola
	rect(im, cx - 2, 46, 5, 4, "b1")
	disco(im, cx, 39.5, 6.2, "ink")  # cabelo
	disco(im, cx, 42.0, 5.4, "b2")
	disco(im, cx - 2, 41.5, 2.0, "b3")
	hl(im, cx - 5, 38, 11, "ink")
	var j := tx_c(im, "JAMES", Rect2i(0, 63, W, 16), "ink", 2)
	medir("parede: JAMES no cartaz", Rect2i(0, 63, W, 16), j, 1, 1)
	return im


## Tira CAMPEÕES colada sobre o cartaz da Liga (12 de altura + 1 de sombra), 2 px para fora de cada lado.
func item_campeoes() -> Image:
	var im := novo(67, 13)
	rect(im, 1, 1, 66, 12, "d2")
	rect(im, 0, 0, 66, 12, "white")
	hl(im, 0, 0, 66, "r2"); hl(im, 0, 11, 66, "r2")
	var b := tx_c(im, "CAMPEÕES", Rect2i(0, 0, 66, 12), "r1")
	medir("parede: CAMPEÕES na tira", Rect2i(0, 0, 66, 12), b, 2)
	return im


func item_recorte_vale() -> Image:
	var W := 52
	var H := 50
	var im := novo(W + 1, H + 1)
	rect(im, 1, 1, W, H, "d2")
	rect(im, 0, 0, W, H, "st2")
	hl(im, 0, 0, W, "st3"); vl(im, 0, 0, H, "st3")
	hl(im, 0, H - 1, W, "st1"); vl(im, W - 1, 0, H, "st1")
	rect(im, 2, 2, W - 4, H - 4, "d1")
	rect(im, 4, 4, W - 8, H - 8, "white")
	for y in range(4, H - 4):
		for x in range(4, W - 4):
			if papel_px(x, y) == "g3":
				px(im, x, y, "cream")
	tx_c(im, "DERRUBA", Rect2i(4, 5, W - 8, 9), "ink")
	hl(im, 6, 14, W - 12, "ink")
	rect(im, 7, 17, 22, 16, "g1")
	# o cinturão na foto
	rect(im, 8, 23, 20, 5, "br1")
	rect(im, 13, 21, 10, 9, "y0")
	frame(im, 13, 21, 10, 9, "br0")
	rect(im, 16, 23, 4, 5, "y1")
	for i in 7:
		hl(im, 31, 17 + i * 2, W - 38 - (i % 2) * 3, "g2")
	hl(im, 7, 36, W - 14, "g2")
	hl(im, 7, 39, W - 20, "g2")
	return im


func item_vulto() -> Image:
	var W := 36
	var H := 44
	var im := _cartaz_base(W, H, "cream", 0)
	limpa_fita(im, W)
	for y in range(1, H + 1):  # papel amarelado
		for x in W:
			if im.get_pixel(x, y).a > 0.5 and (x * 3 + y * 5) % 7 == 0 and bayer(x, y) < 6:
				px(im, x, y, "g3")
	rect(im, 1, 0, 6, 3, "g3"); hl(im, 1, 0, 6, "white")
	tx_c(im, "VULTO", Rect2i(0, 3, W, 9), "ink")
	hl(im, 3, 12, W - 6, "ink")
	rect(im, 4, 15, W - 8, 18, "b2")  # céu da noite (claro o bastante para a silhueta)
	for x in range(4, W - 4):
		if (x * 5) % 7 == 0:
			px(im, x, 15 + (x * 3) % 6, "b3")
	disco(im, W - 10, 19, 2.5, "cream")
	for x in range(4, W - 4):  # telhado em duas águas
		var t := 29 - mini(x - 4, W - 5 - x) / 4
		rect(im, x, maxi(t, 25), 1, 33 - maxi(t, 25), "ink")
	# o vulto de capuz na cumeeira
	disco(im, 15, 18, 2.6, "ink")
	rect(im, 13, 20, 5, 6, "ink")
	px(im, 14, 18, "r1")
	for i in 3:
		hl(im, 4, 35 + i * 3, W - 8 - (i % 2) * 6, "g2")
	return im


func item_foto_antiga() -> Image:
	var im := novo(43, 31)
	rect(im, 1, 1, 42, 30, "d2")
	rect(im, 0, 0, 42, 30, "white")
	vl(im, 41, 0, 30, "g3"); hl(im, 0, 29, 42, "g3")
	rect(im, 3, 3, 36, 20, "br2")
	rect(im, 3, 17, 36, 6, "br1")
	for y in range(3, 23):
		for x in range(3, 39):
			if (x + y) % 5 == 0 and bayer(x, y) < 6:
				px(im, x, y, "br3" if y < 17 else "br0")
	# o treinador jovem posando de guarda (sépia)
	disco(im, 21, 8, 2.6, "br0")
	rect(im, 18, 11, 7, 7, "br0")
	rect(im, 15, 10, 3, 3, "br0"); rect(im, 25, 10, 3, 3, "br0")
	rect(im, 18, 18, 2, 5, "br0"); rect(im, 23, 18, 2, 5, "br0")
	hl(im, 6, 26, 14, "g2")
	disco(im, 38, 3, 1.4, "r2")
	return im


func item_faixas_john() -> Image:
	var im := novo(27, 46)
	# as duas faixas de mão penduradas no prego, cada uma terminando num rolo
	for s in [0, 1]:
		var x0: int = 8 + s * 8
		var fim: int = 31 + s * 5
		for y in range(3, fim):
			var x: int = x0 + int(round(sin(y * 0.3 + s * 2.0)))
			px(im, x - 1, y, "g3")
			px(im, x, y, "white")
			px(im, x + 1, y, "cream")
			px(im, x + 2, y, "g2")
		disco(im, x0 + 0.5, fim + 2.5, 3.0, "g2")
		disco(im, x0 + 0.5, fim + 2.0, 2.6, "cream")
		disco(im, x0 + 0.5, fim + 2.0, 1.0, "g3")
	rect(im, 11, 0, 4, 3, "st2"); px(im, 12, 0, "st3")
	# etiqueta de papel com as iniciais, num barbante
	vl(im, 4, 3, 22, "g2")
	rect(im, 1, 26, 15, 11, "d2")
	rect(im, 0, 25, 15, 11, "cream")
	frame(im, 0, 25, 15, 11, "ink")
	var b := tx_c(im, "JB", Rect2i(0, 25, 15, 11), "ink")
	medir("parede: JB na etiqueta", Rect2i(0, 25, 15, 11), b, 2)
	return im


func item_luvas() -> Image:
	var im := novo(50, 58)
	var m := novo(50, 58)
	var luvas := [[13, 18, 1], [36, 22, -1]]  # [centro x, topo do punho, lado do polegar (para dentro)]
	for g in luvas:
		var cx: int = g[0]
		var cy: int = g[1]
		rect(m, cx - 6, cy + 5, 13, 12, "white")
		disco(m, cx, cy + 22, 9.0, "white")
		disco(m, cx + g[2] * 7, cy + 14, 3.2, "white")  # polegar
	for g in luvas:
		var cx: int = g[0]
		var cy: int = g[1]
		var lado: int = g[2]
		for y in range(cy + 5, cy + 33):
			for x in range(cx - 12, cx + 13):
				if x < 0 or x >= 50 or y >= 58 or m.get_pixel(x, y).a < 0.5:
					continue
				var borda := false
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = Vector2i(x, y) + d
					if q.x < 0 or q.y < 0 or q.x >= 50 or q.y >= 58 or m.get_pixel(q.x, q.y).a < 0.5:
						borda = true
				var c := "r1"
				if borda:
					c = "ink"
				elif (x - cx) * -1 > 3 and y < cy + 20 and (x - cx) * lado < 0:
					c = "r2"
				elif (x - cx) * -lado > 5 and y > cy + 14:
					c = "r0"
				elif (x * 7 + y * 3) % 23 == 0:
					c = "br2"  # couro gasto
				px(im, x, y, c)
		# a costura do polegar e o brilho
		for k in 6:
			px(im, cx + lado * (4 + k / 3), cy + 11 + k, "ink")
		px(im, cx - 4, cy + 9, "r3")
		# punho
		rect(im, cx - 6, cy, 13, 6, "g3")
		frame(im, cx - 6, cy, 13, 6, "ink")
		hl(im, cx - 5, cy + 1, 11, "cream")
		hl(im, cx - 5, cy + 3, 11, "g2")
	# cadarços até o prego
	for i in 16:
		px(im, 24 - i * 10 / 16 - 1, 3 + i, "g3")
		px(im, 26 + i * 9 / 16, 3 + i + (i * 3) / 16, "g3")
	rect(im, 24, 0, 3, 3, "st2"); px(im, 25, 0, "st3")
	return im


## Papel de ALUGA-SE com as tirinhas de telefone embaixo (duas já arrancadas): coisa de rua, não conta história.
func item_aluga() -> Image:
	var W := 54
	var H := 40
	var im := _cartaz_base(W, H, "white", 0)
	var b := tx_c(im, "ALUGA-SE", Rect2i(0, 3, W, 10), "ink")
	medir("parede: ALUGA-SE", Rect2i(0, 3, W, 10), b, 2, 1)
	hl(im, 4, 14, W - 8, "g1")
	hl(im, 6, 17, W - 14, "g2")
	hl(im, 6, 20, W - 20, "g2")
	# tirinhas
	for i in 8:
		var x := 3 + i * 6
		if i == 2 or i == 5:
			for y in range(25, H + 1):
				limpa(im, x, y); limpa(im, x + 1, y); limpa(im, x + 2, y); limpa(im, x + 3, y); limpa(im, x + 4, y)
			hl(im, x, 25, 5, "g3")
			continue
		vl(im, x + 5, 25, H - 24, "g3")
		vl(im, x + 2, 28, 8, "g1")
	hl(im, 0, 24, W, "g2")
	return im


## Lista das camadas da parede (ordem = ordem de desenho). `quando`: "sempre", {"marco": id} ou {"rondas_min": n}.
func _camadas() -> Array:
	return [
		{"id": "soco", "img": item_soco(), "pos": Vector2i(22, 126), "quando": "sempre",
			"nota": "o cartaz SOCO da garagem (o começo)"},
		{"id": "luta_sabado", "img": item_generico(), "pos": Vector2i(567, 126), "quando": "sempre",
			"nota": "cartaz genérico de luta de bairro"},
		{"id": "luvas_velhas", "img": item_luvas(), "pos": Vector2i(295, 288), "quando": "sempre",
			"nota": "as luvas velhas do mentor no prego, no eixo"},
		{"id": "aluga_se", "img": item_aluga(), "pos": Vector2i(46, 288), "quando": "sempre",
			"nota": "papel de ALUGA-SE com tirinhas (rua; parede gasta)"},
		{"id": "recorte_vitoria", "img": item_recorte_vitoria(), "pos": Vector2i(88, 132), "quando": {"marco": "first_school_win"},
			"nota": "recorte GARAGEM FAZ BARULHO (1ª vitória)"},
		{"id": "raizes", "img": item_raizes(), "pos": Vector2i(26, 204), "quando": {"marco": "garage_saved"},
			"nota": "quadro RAÍZES com o carimbo (garagem salva)"},
		{"id": "foto_equipe", "img": item_foto_equipe(), "pos": Vector2i(152, 136), "quando": {"marco": "cena_primeira_sucessao"},
			"nota": "foto da equipe: treinador, o 1º lutador e o discípulo"},
		{"id": "foto_antiga", "img": item_foto_antiga(), "pos": Vector2i(436, 140), "quando": {"marco": "cena_primeira_academia"},
			"nota": "foto antiga do treinador (chegada à academia)"},
		{"id": "faixas_john", "img": item_faixas_john(), "pos": Vector2i(164, 214), "quando": {"marco": "cena_saida_primeiro_mentor"},
			"nota": "as faixas de mão do 1º lutador com etiqueta JB (saída dele)"},
		{"id": "liga", "img": item_liga(), "pos": Vector2i(489, 122), "quando": {"marco": "regional_league_opened"},
			"nota": "cartaz LIGA DO VALE / JAMES"},
		{"id": "liga_campeoes", "img": item_campeoes(), "pos": Vector2i(487, 172), "quando": {"marco": "regional_belt_first"},
			"nota": "tira CAMPEÕES colada sobre o cartaz da Liga (por cima do liga)", "sobre": "liga"},
		{"id": "recorte_vale", "img": item_recorte_vale(), "pos": Vector2i(560, 212), "quando": {"marco": "center_arrival"},
			"nota": "recorte emoldurado DERRUBA (o cinturão do Vale; chegada ao centro)"},
		{"id": "recorte_vulto", "img": item_vulto(), "pos": Vector2i(508, 222), "quando": {"marco": "black_cat_rumor_heard"},
			"nota": "recorte VULTO (o boato do vulto de capuz)"},
		{"id": "capuz", "img": item_capuz(), "pos": Vector2i(104, 214), "quando": {"rondas_min": 1},
			"nota": "o capuz no prego (depois da 1ª Ronda Noturna)"},
	]


func _menu_assets() -> void:
	# --- parede (fundo) com a luz já aplicada
	var parede := _parede_base()
	iluminar(parede, 0, 0)
	salvar_menu(parede, "menu_parede", "640x360 em (0,0); luz da lâmpada já pintada")
	# --- camadas
	var camadas := _camadas()
	var lista := []
	var caixas := {}
	for c in camadas:
		var im: Image = c.img
		var p: Vector2i = c.pos
		iluminar(im, p.x, p.y, 1)
		salvar_menu(im, "menu_item_" + c.id, str(c.quando))
		var box := Rect2i(p, im.get_size())
		caixas[c.id] = box
		var q = c.quando
		var req := {}
		if q is Dictionary and q.has("marco"):
			req = {"milestone": q.marco}
		elif q is Dictionary and q.has("rondas_min"):
			req = {"black_cat_rounds_min": q.rondas_min}
		lista.append({"id": c.id, "file": "res://assets/sprites/menu/menu_item_%s.png" % c.id, "pos": [p.x, p.y],
			"size": [im.get_width(), im.get_height()], "requires": req, "note": c.nota})
		c["box"] = box
	# conferência da parede: na tela, fora da faixa e do subtítulo, fora da coluna dos botões, sem encostar em outro item
	print("-- parede: caixas dos itens")
	var tela := Rect2i(4, BAND_Y1 + 4, 632, 348 - BAND_Y1 - 4)
	var versao := Rect2i(600, 344, 40, 16)
	for c in camadas:
		var r: Rect2i = c.box
		var prob := []
		if not tela.encloses(r):
			prob.append("fora da área livre da parede")
		if r.intersects(COLUNA):
			prob.append("entra na coluna dos botões")
		if r.intersects(versao):
			prob.append("cobre a versão")
		for d in camadas:
			if d.id == c.id or c.get("sobre", "") == d.id or d.get("sobre", "") == c.id:
				continue
			var r2: Rect2i = d.box
			if r.grow(2).intersects(r2):
				prob.append("encosta em " + d.id)
		print("  %-16s x %3d..%3d  y %3d..%3d  %s" % [c.id, r.position.x, r.end.x - 1, r.position.y, r.end.y - 1, "ok" if prob.is_empty() else "AVISO " + str(prob)])
		if not prob.is_empty():
			avisos.append("parede %s: %s" % [c.id, str(prob)])
	var js := {"_sobre": "Parede de cartazes do menu (direção C). Fundo menu_parede.png em (0,0); desenhar as camadas NA ORDEM desta lista, por cima do fundo e por baixo da faixa. Cada camada só aparece se 'requires' for verdade no save carregado; requires vazio = sempre. Save novo ou sem save = só as de requires vazio. Gerador: tools/art/make_tema_c.gd. Spec: docs/arte/tema-c-spec.md.",
		"requires_legenda": {"milestone": "GameState.marco(id) (school.milestones no save)", "black_cat_rounds_min": "GameState.lenda().rounds >= n (permanent.black_cat.rounds)"},
		"layers": lista}
	var f := FileAccess.open(MENU_OUT + "parede.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(js, "\t"))
	f.close()

	# --- faixa: moldura (16x88, ladrilho) + listras (16x76, ladrilho com scroll)
	var mold := novo(16, 88)
	for y in 88:
		var y0 := BAND_Y0 + y
		for x in 16:
			var c := ""
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
				c = "ink" if bayer(x, y0) < 8 else ""
			if c != "":
				px(mold, x, y, c)
	salvar_menu(mold, "menu_faixa_moldura", "ladrilho horizontal, em (0,26), 640 de largura")
	var lis := novo(16, 76)
	for y in 76:
		for x in 16:
			var k := posmod(x + y, STRIPE)
			px(lis, x, y, "r1" if (k < 6 and bayer(x, y) < 8) or k == 6 else "r2")
	salvar_menu(lis, "menu_faixa_listras", "ladrilho, em (0,30); scroll +1 px x a cada 80 ms")
	# --- quadros da faixa entrando (intro): 30% e 65%, com a ponta cortada e o fio de luz
	for p in [[0.30, "30"], [0.65, "65"]]:
		var im := novo(640, 88)
		_faixa_parcial(im, p[0])
		salvar_menu(im, "menu_faixa_entra_" + p[1], "640x88 em (0,26)")
	# --- logo (sprite separado), flash, máscara do brilho e linhas de velocidade
	var Lw := logo_L.get_width()
	var Lh := logo_L.get_height()
	var logo := novo(Lw + 2, Lh + 5)
	var flash := novo(Lw + 2, Lh + 5)
	_logo_em(logo, 1, 1, false)
	_logo_em(flash, 1, 1, true)
	salvar_menu(logo, "menu_logo", "em (%d,%d) [PROVISÓRIO]" % [logo_pos().x - 1, logo_pos().y - 1])
	salvar_menu(flash, "menu_logo_flash", "mesmo lugar; 1 quadro no IMPACTO")
	var mask := novo(Lw + 2, Lh + 5)
	for y in Lh:
		for x in Lw:
			if logo_L.get_pixel(x, y).a > 0.5:
				mask.set_pixel(x + 1, y + 1, Color.WHITE)
	salvar_menu(mask, "menu_logo_mascara", "mesmo lugar; recorte das letras p/ o brilho")
	var vel := novo(Lw, 8)
	for xx in range(logo_used.position.x, logo_used.end.x, 9):
		vl(vel, xx + 3, 0, 8, "r3")
	salvar_menu(vel, "menu_logo_velocidade", "em logo + (1,-11), só no quadro do título caindo")
	var poeira := _poeira()
	salvar_menu(poeira[0], "menu_lascas", "em (%d,%d), quadros IMPACTO e tremor 1" % [poeira[1].x, poeira[1].y])
	var seta := novo(6, 9)
	for k in 4:
		vl(seta, 1 + k, 1 + k, 7 - 2 * k, "cream")
	vl(seta, 0, 0, 9, "ink")
	salvar_menu(seta, "menu_seta", "seta do foco (esq.); a da direita = flip_h")


func logo_pos() -> Vector2i:
	var cx := logo_used.position.x + (logo_used.size.x - 1) / 2.0
	return Vector2i(AXIS - int(floor(cx)), LOGO_Y)


func logo_layer(s: String, sc: int, bold := false, shear := 0) -> Image:
	var m := novo(tw(s) + 2, cap_h)
	tx(m, s, 0, 0, "white")
	var hh := cap_h * sc
	var extra := (hh / shear + 1) if shear > 0 else 0
	var L := novo(m.get_width() * sc + 2 + extra, hh)
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


func _logo_em(img: Image, x: int, y: int, flash: bool) -> void:
	var L := logo_L
	layer_put(img, L, x, y, "ink", 0, 4)
	layer_put(img, L, x, y, "ink", 1, 4)
	for d in range(-1, 2):
		for e in range(-1, 2):
			if d != 0 or e != 0:
				layer_put(img, L, x, y, "white" if flash else "ink", d, e)
	layer_put(img, L, x, y, "white" if flash else "cream")
	if flash:
		return
	for xx in L.get_width():
		for yy in [L.get_height() - 1, L.get_height() - 2]:
			if L.get_pixel(xx, yy).a > 0.5:
				px(img, x + xx, y + yy, "g3")
		if L.get_pixel(xx, 0).a > 0.5:
			px(img, x + xx, y, "white")


func _poeira() -> Array:
	var p := logo_pos()
	var pts := []
	var y := p.y + logo_L.get_height() + 2
	for s in [-1, 1]:
		var x0 := p.x + (logo_used.position.x - 6 if s < 0 else logo_used.end.x + 4)
		for i in 5:
			pts.append([x0 + s * i * 4, y - i * 3 - (i % 2) * 2, "cream" if i % 2 == 0 else "white"])
	var mn := Vector2i(9999, 9999)
	var mx := Vector2i(-9999, -9999)
	for q in pts:
		mn = Vector2i(mini(mn.x, q[0]), mini(mn.y, q[1]))
		mx = Vector2i(maxi(mx.x, q[0] + 2), maxi(mx.y, q[1] + 2))
	var im := novo(mx.x - mn.x, mx.y - mn.y)
	for q in pts:
		rect(im, q[0] - mn.x, q[1] - mn.y, 2, 2, q[2])
	return [im, mn]


func _faixa_parcial(im: Image, p: float) -> void:
	var E := int(lerpf(-60.0, 700.0, p))
	var ymid := (BAND_Y0 + BAND_Y1) / 2
	for y in 88:
		var y0 := BAND_Y0 + y
		var xe := E + (ymid - y0) / 2
		for x in range(0, mini(640, xe)):
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
				if bayer(x, y0) < 8:
					px(im, x, y, "ink")
				continue
			else:
				var k := posmod(x + (y0 - BAND_B0), STRIPE)
				if (k < 6 and bayer(x, y0) < 8) or k == 6:
					c = "r1"
			if x >= xe - 2:
				c = "white"
			px(im, x, y, c)


# ================================================================= PRANCHAS (montadas com as PNGs gravadas)
func mimg(nome: String) -> Image:
	return _img(MENU_OUT + nome + ".png")


func _menu_tela(ativos: Array) -> Image:
	var im := mimg("menu_parede")
	var js = JSON.parse_string(FileAccess.get_file_as_string(MENU_OUT + "parede.json"))
	for l in js.layers:
		var req: Dictionary = l.requires
		var ok := req.is_empty()
		if req.has("milestone"):
			ok = ativos.has(str(req.milestone))
		elif req.has("black_cat_rounds_min"):
			ok = ativos.has("ronda")
		if ok:
			blit(im, _img(ROOT + "/" + str(l.file).replace("res://", "")), int(l.pos[0]), int(l.pos[1]))
	# faixa: listras em ladrilho + moldura em ladrilho
	var lis := mimg("menu_faixa_listras")
	var mol := mimg("menu_faixa_moldura")
	for x in range(0, 640, 16):
		blit(im, mol, x, BAND_Y0)
		blit(im, lis, x, BAND_B0)
	blit(im, mimg("menu_logo"), logo_pos().x - 1, logo_pos().y - 1)
	# subtítulo no chip
	var sw := tw(SUB_MENU) + 14
	var r := Rect2i(AXIS - sw / 2, BAND_B1 - 3, sw, 13)
	var c := chip_em(im, "c_chip", r, SUB_MENU, "cream")
	if ativos.is_empty():
		medir("menu: subtítulo", c[0], c[1])
		var cx := logo_pos().x + logo_used.position.x + (logo_used.size.x - 1) / 2.0
		print("  menu: logo x %d..%d centro %.1f (eixo %d)" % [logo_pos().x + logo_used.position.x, logo_pos().x + logo_used.end.x - 1, cx, AXIS])
		if absf(cx - AXIS) > 0.5:
			avisos.append("logo fora do eixo")
		if absf(r.position.x + r.size.x / 2.0 - AXIS) > 0.5:
			avisos.append("subtítulo fora do eixo")
	# botões (foco no CONTINUAR) e setas
	for i in MENU.size():
		var br := Rect2i(AXIS - BTN_W / 2, BTN_Y + i * BTN_PITCH, BTN_W, BTN_H)
		var nome := "c_btn_foco" if i == 0 else "c_btn_papel_normal"
		var b := botao_em(im, nome, br, MENU[i], "cream" if i == 0 else "ink")
		if ativos.is_empty():
			medir("menu: " + MENU[i], b[0], b[1])
			if absf(br.position.x + br.size.x / 2.0 - AXIS) > 0.5:
				avisos.append("botão %s fora do eixo" % MENU[i])
		if i == 0:
			var seta := mimg("menu_seta")
			var ay := br.position.y + (BTN_H - 2) / 2 - 4
			blit(im, seta, br.position.x - 11, ay)
			var sd: Image = seta.duplicate()
			sd.flip_x()
			blit(im, sd, br.end.x + 5, ay)
	tx(im, "v0.8", 634 - tw("v0.8"), 349, "g2")
	return im


func _sala() -> Image:
	var cap := _img(ROOT + "/docs/arte/mockups/fase6d2_qa_tela_fechada.png")
	var bg := _img(ROOT + "/assets/sprites/garage/garage_bg.png")
	var o := novo(640, 360)
	for y in 360:
		for x in 640:
			o.set_pixel(x, y, cap.get_pixel(x * 2, y * 2))
	for r in [Rect2i(0, 0, 640, 21), Rect2i(0, 326, 640, 34), Rect2i(0, 18, 143, 98), Rect2i(612, 118, 28, 64)]:
		o.blit_rect(bg, r, r.position)
	# HUD
	nove_peca(o, "c_hud_faixa", Rect2i(0, 0, 640, 21))
	var sep := peca("c_hud_sep")
	var x := 9
	blit(o, icon("icon_treino"), x, 5); x += 12
	x += tx(o, "TREINO", x, 6, "g3") + 5
	x += tx(o, "3.00K", x, 2, "gr3", 2) + 4
	x += tx(o, "+0/S", x, 6, "gr3") + 6
	blit(o, sep, x - 2, 0); x += 10
	blit(o, icon("icon_money"), x, 5); x += 12
	x += tx(o, "$ 5.00K", x, 6, "y1") + 6
	blit(o, sep, x - 2, 0); x += 10
	tx(o, "JOHN BULLET", x, 6, "cream")
	# etiqueta do local (da direita para a esquerda)
	var w_dir := tw("0") + 11 + 4 + tw("0") + 11 + 7 + tw("FUNDO DE GARAGEM") + 10
	var ex := 640 - 10 - w_dir
	nove_peca(o, "c_hud_etiqueta", Rect2i(ex, 0, 640 - ex, 18))
	var p := ex + 10
	p += tx(o, "FUNDO DE GARAGEM", p, 6, "ink") + 6
	vl(o, p, 4, 10, "r2"); p += 4
	blit(o, icon("icon_fame"), p, 5); p += 11
	p += tx(o, "0", p, 6, "f0") + 4
	blit(o, icon("icon_legacy"), p, 5); p += 11
	tx(o, "0", p, 6, "p0")
	# cartões da esquerda
	nove_peca(o, "c_cartao", Rect2i(3, 24, 112, 44))
	var atr := [["icon_strength", "r2", "317", 0.8], ["icon_agility", "b1", "60", 0.3], ["icon_endurance", "y0", "200", 0.55]]
	for i in 3:
		var a: Array = atr[i]
		var yy := 29 + i * 12
		blit(o, icon(a[0]), 8, yy)
		rect(o, 21, yy + 3, 56, 3, "g3")
		rect(o, 21, yy + 3, int(56 * a[3]), 3, a[1])
		tx(o, a[2], 108 - tw(a[2]), yy + 1, "ink")
	nove_peca(o, "c_cartao", Rect2i(3, 72, 124, 46))
	nove_peca(o, "c_chip", Rect2i(4, 73, 122, 13))
	blit(o, icon("icon_calendar"), 7, 75)
	tx(o, "FALTAM 12 DIAS", 20, ycap_in(73, 13), "cream")
	tx(o, "DUDU ALONGADO", 9, 90, "ink")
	blit(o, peca("c_carimbo_perigoso"), 29, 98)
	nove_peca(o, "c_cartao", Rect2i(614, 121, 24, 58))
	blit(o, icon("icon_treino"), 618, 127)
	tx(o, "4", 630, 128, "gr0")
	blit(o, icon("icon_money"), 618, 142)
	tx(o, "4", 630, 143, "br1")
	tx(o, "<", 625, 161, "ink")
	# barra de baixo
	var by := 330
	nove_peca(o, "c_barra", Rect2i(0, by, 640, 30))
	blit(o, peca("c_barra_faixa"), 480, by)
	tx(o, "+1", 6, ycap_in(by + 3, 27, 2), "gr1", 2)
	tx(o, "/CLIQUE", 6 + tw("+1", 2) + 2, ycap_in(by + 3, 27, 2) + 7, "g0")
	var focos := [["c_btn_foco", "SACO", "cream", "icon_strength"], ["c_btn_normal", "ESTEIRA", "cream", "mark_padlock"],
		["c_btn_desabilitado", "CORDA", "g2", "mark_padlock"]]
	for i in 3:
		var f: Array = focos[i]
		var b := botao_em(o, f[0], Rect2i(92 + i * 90, by + 5, 86, 20), f[1], f[2], icon(f[3]))
		medir("sala: foco " + f[1], b[0], b[1])
	tx(o, "CLIQUE NO SACO", 364, by + 7, "ink")
	tx(o, "PARA TREINAR", 364, by + 17, "ink")
	botao_em(o, "c_btn_normal", Rect2i(462, by + 7, 18, 18), "", "cream", icon("icon_assist_wait"), 0)
	var ba := botao_em(o, "c_btn_normal", Rect2i(486, by + 7, 16, 18), "?", "cream")
	medir("sala: ?", ba[0], ba[1])
	var bl := lutar_em(o, "normal", Vector2i(507, by + 3))
	medir("sala: LUTAR!", bl[0], bl[1])
	nove_peca(o, "c_btn_normal", Rect2i(613, by + 4, 22, 22))
	blit(o, icon("icon_pass_post"), 616, by + 6)
	return o


func _janela(base: Image) -> Image:
	var o: Image = base.duplicate()
	for y in 360:  # escurecer atrás (dither 50% ink, como o ui_dim_dither)
		for x in 640:
			if (x + y) % 2 == 0:
				o.set_pixel(x, y, C("ink"))
	var r := Rect2i(170, 64, 300, 226)
	nove_peca(o, "c_janela", Rect2i(r.position.x, r.position.y, r.size.x, r.size.y + 3))
	var t := titulo_em(o, "c_janela_titulo_g", Rect2i(r.position.x + 2, r.position.y + 2, 170, 30), "VITÓRIA!", 2)
	medir("janela: título VITÓRIA!", t[0], t[1])
	rect(o, r.position.x + 2, r.position.y + 32, r.size.x - 4, 2, "ink")
	blit(o, peca("c_carimbo_raizes"), r.end.x - 48, r.position.y + 6)
	tx(o, "DUDU ALONGADO CAIU NO 2º ROUND", r.position.x + 14, r.position.y + 44, "ink")
	var linhas := [["icon_money", "PRÊMIO", "$ 1.20K", "br1"], ["icon_fame", "FAMA", "+3", "f0"], ["icon_treino", "TREINO", "+15%", "gr0"]]
	for i in 3:
		var l: Array = linhas[i]
		var yy := r.position.y + 62 + i * 16
		blit(o, icon(l[0]), r.position.x + 14, yy)
		tx(o, l[1], r.position.x + 28, yy + 1, "ink")
		tx(o, l[2], r.end.x - 16 - tw(l[2]), yy + 1, l[3])
		hl(o, r.position.x + 12, yy + 12, r.size.x - 24, "g3")
	var ce := chip_em(o, "c_etiqueta", Rect2i(r.position.x + 14, r.position.y + 118, 54, 12), "RECORDE", "ink")
	medir("janela: etiqueta RECORDE", ce[0], ce[1])
	var cc := chip_em(o, "c_chip", Rect2i(r.position.x + 74, r.position.y + 117, 72, 13), "PRÓXIMO: KID", "cream")
	medir("janela: chip", cc[0], cc[1])
	nove_peca(o, "c_carimbo_moldura", Rect2i(r.position.x + 160, r.position.y + 115, 60, 16))
	var cm := tx_c(o, "FÁCIL", Rect2i(r.position.x + 160, r.position.y + 115, 60, 16), "r2")
	medir("janela: carimbo FÁCIL", Rect2i(r.position.x + 160, r.position.y + 115, 60, 16), cm)
	var b1 := botao_em(o, "c_btn_papel_normal", Rect2i(r.position.x + 30, r.end.y - 34, 110, 20), "VER LUTA", "ink")
	var b2 := botao_em(o, "c_btn_foco", Rect2i(r.end.x - 140, r.end.y - 34, 110, 20), "CONTINUAR", "cream")
	medir("janela: VER LUTA", b1[0], b1[1])
	medir("janela: CONTINUAR", b2[0], b2[1])
	return o


func _pecas_prancha() -> Image:
	var b := novo(640, 360)
	b.fill(C("d1"))
	tx(b, "TEMA C: PEÇAS EM 1X (9-SLICE ESTICADO NO TAMANHO DE USO)", 8, 6, "cream")
	var y := 20
	nove_peca(b, "c_hud_faixa", Rect2i(8, y, 300, 21))
	var sep := peca("c_hud_sep")
	blit(b, sep, 120, y)
	nove_peca(b, "c_hud_etiqueta", Rect2i(200, y, 108, 18))
	tx(b, "FUNDO DE GARAGEM", 210, y + 6, "ink")
	nove_peca(b, "c_barra", Rect2i(320, y - 4, 312, 30))
	blit(b, peca("c_barra_faixa"), 472, y - 4)
	lutar_em(b, "normal", Vector2i(500, y - 1))
	y = 60
	var est := [["normal", "c_btn_normal", "cream"], ["foco", "c_btn_foco", "cream"], ["apertado", "c_btn_apertado", "cream"], ["desab.", "c_btn_desabilitado", "g2"]]
	for i in 4:
		tx(b, est[i][0].to_upper(), 8 + i * 92, y, "g3")
		botao_em(b, est[i][1], Rect2i(8 + i * 92, y + 10, 86, 20), "BOTÃO", est[i][2])
	var est2 := [["papel", "c_btn_papel_normal", "ink"], ["papel desab.", "c_btn_papel_desabilitado", "g1"]]
	for i in 2:
		tx(b, est2[i][0].to_upper(), 380 + i * 128, y, "g3")
		botao_em(b, est2[i][1], Rect2i(380 + i * 128, y + 10, 120, 20), "BOTÃO", est2[i][2])
	y = 100
	var stl := ["normal", "hover", "pressed", "disabled"]
	for i in 4:
		tx(b, ("LUTAR " + stl[i]).to_upper(), 8 + i * 116, y, "g3")
		lutar_em(b, stl[i], Vector2i(8 + i * 116, y + 10))
	y = 146
	nove_peca(b, "c_janela", Rect2i(8, y, 220, 130))
	titulo_em(b, "c_janela_titulo_g", Rect2i(10, y + 2, 140, 30), "TÍTULO", 2)
	rect(b, 10, y + 32, 216, 2, "ink")
	titulo_em(b, "c_janela_titulo", Rect2i(10, y + 44, 100, 16), "TÍTULO 1X", 1)
	tx(b, "TEXTO INK SOBRE PAPEL", 16, y + 70, "ink")
	tx(b, "$ 1.20K  +3  +15%", 16, y + 82, "br1")
	nove_peca(b, "c_cartao", Rect2i(240, y, 90, 40))
	chip_em(b, "c_chip", Rect2i(240, y + 50, 90, 13), "CHIP", "cream")
	chip_em(b, "c_etiqueta", Rect2i(240, y + 70, 60, 12), "ETIQUETA", "ink")
	blit(b, peca("c_carimbo_perigoso"), 340, y)
	nove_peca(b, "c_carimbo_moldura", Rect2i(340, y + 24, 72, 16))
	tx_c(b, "DIFÍCIL", Rect2i(340, y + 24, 72, 16), "r2")
	blit(b, peca("c_carimbo_raizes"), 424, y)
	blit(b, peca("c_carimbo_raizes_p"), 470, y + 8)
	# menu: logo e faixa
	var fy := 290
	for x in range(240, 632, 16):
		blit(b, mimg("menu_faixa_moldura").get_region(Rect2i(0, 0, mini(16, 632 - x), 88)), x, fy - 30)
		blit(b, mimg("menu_faixa_listras").get_region(Rect2i(0, 0, mini(16, 632 - x), 76)), x, fy - 26)
	var bx: Image = b.duplicate()
	bx.resize(640 * 2, 360 * 2, Image.INTERPOLATE_NEAREST)
	return bx


func _pranchas() -> void:
	print("-- menu: medidas (parede vazia)")
	var vazio := _menu_tela([])
	vazio.save_png(MOCK_OUT + "tema_c_final_menu_vazio.png")
	var meio := _menu_tela(["first_school_win", "garage_saved", "cena_primeira_sucessao", "cena_primeira_academia", "regional_league_opened"])
	meio.save_png(MOCK_OUT + "tema_c_final_menu_meio.png")
	var cheio := _menu_tela(["first_school_win", "garage_saved", "cena_primeira_sucessao", "cena_primeira_academia",
		"cena_saida_primeiro_mentor", "regional_league_opened", "regional_belt_first", "center_arrival", "black_cat_rumor_heard", "ronda"])
	cheio.save_png(MOCK_OUT + "tema_c_final_menu_cheio.png")
	print("-- sala e janela")
	var sala := _sala()
	sala.save_png(MOCK_OUT + "tema_c_final_sala.png")
	_janela(sala).save_png(MOCK_OUT + "tema_c_final_janela.png")
	_pecas_prancha().save_png(MOCK_OUT + "tema_c_final_pecas_x2.png")
	# prancha 2x2 (1x cada) para comparar os 3 estados da parede e a sala
	var m := 10
	var lab := 16
	var P := novo(m + 2 * (640 + m), 24 + 2 * (360 + lab + m))
	P.fill(C("ink"))
	tx(P, "TEMA C FINAL (1X): PAREDE VAZIA / NO MEIO / CHEIA E A SALA", m, 8, "cream")
	var it := [["SAVE NOVO: PAREDE QUASE VAZIA", vazio], ["NO MEIO: LIGA ABERTA", meio], ["CHEIA: TODOS OS MARCOS", cheio], ["SALA COM O TEMA C", sala]]
	for i in 4:
		var x := m + (i % 2) * (640 + m)
		var y := 24 + (i / 2) * (360 + lab + m)
		tx(P, it[i][0], x, y + 4, "g3")
		blit(P, it[i][1], x, y + lab)
	P.save_png(MOCK_OUT + "tema_c_final_prancha.png")
