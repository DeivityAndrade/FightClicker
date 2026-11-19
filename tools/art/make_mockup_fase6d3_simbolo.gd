extends SceneTree
## Fase 6d3 (Diretor de Arte): PROPOSTAS de símbolo da escola Raízes Fight Club (raiz + luta, sem lâmpada). Só mockup:
## não grava nada em assets/. Saída: docs/arte/mockups/fase6d3_simbolo_opcoes.png. Nota: docs/arte/fase6d3-simbolo.md.
##   godot --headless --path <pasta_vazia> --script E:/Fightclicker/tools/art/make_mockup_fase6d3_simbolo.gd
## Cada proposta tem 3 desenhos feitos à mão (não reduzidos): 16x16 (UI, base da parede em 2x), 9x9 (selo do mural, carimbos)
## e 5x5 (peito do discípulo). 'a' = a tinta (uma cor), 'c' = creme (na estampa de uma cor vira vazio: aparece o pano).

const ROOT := "E:/Fightclicker/"
const SPR := ROOT + "assets/sprites/"
var L
var MAN := {}

const OPTS := [
	{"id": "A", "nome": "PUNHO-RAIZ", "s16": [
		".........aaa....",
		"........aaaaaa..",
		"........aaaaaaa.",
		"........acccaaaa",
		"aaaaaaaaaaaaaaaa",
		"aaaaaaaaacccaaaa",
		"aaaaaaaaaaaaaaaa",
		"aaaaaaaaacccaaaa",
		"aaaaaaaaaaaaaaa.",
		".aa.aa..aaaaaa..",
		".a..a.a.........",
		"a..a...a........",
		"a..a....a.......",
		"..a.....a.......",
		".a.......a......",
		"a........a......"],
	 "s9": [
		".....aaa.",
		"....aaaaa",
		"aaaaaccaa",
		"aaaaaaaaa",
		"aaaaaccaa",
		"....aaaa.",
		".a.a.....",
		"a.a.a....",
		"a..a....."],
	 "s5": [
		"...aa",
		"aaaaa",
		"aaaaa",
		".a.a.",
		"a.a.."]},
	{"id": "B", "nome": "LUVA NA RAIZ", "s16": [
		"aa..a....a...aa.",
		".aa.aa..aa..aa..",
		"aaaaaaaaaaaaaaaa",
		"......a.a.......",
		"......a..a......",
		".....aaaaaa.....",
		".....acacaa.....",
		"....aaaaaaaaa...",
		"...aaaaaaaaaaa..",
		"..aaaaaaaaaaaaa.",
		"..aacaaaaaaacaaa",
		"..aaaaaaaaacaaaa",
		"..aaaaaaaaacaaaa",
		"...aaaaaaaaaaaa.",
		"....aaaaaaaaa...",
		"......aaaaa....."],
	 "s9": [
		"a.a.a.a.a",
		"aaaaaaaaa",
		"...a.a...",
		"..aaaaa..",
		".aaaaaaa.",
		".aaaaacaa",
		".aaaaacaa",
		".aaaaaaa.",
		"..aaaaa.."],
	 "s5": [
		"aaaaa",
		"..a..",
		".aaa.",
		"aaaaa",
		".aaa."]},
	{"id": "C", "nome": "BRASAO DA RAIZ", "s16": [
		".aaaaaaaaaaaaaa.",
		".aaaacaaaacaaaa.",
		".aaaaacaacaaaaa.",
		".aaaaaaccaaaaaa.",
		".acccccccccccca.",
		".aaaaaaccaaaaaa.",
		".aaaaaaccaaaaaa.",
		".aaaaacaacaaaaa.",
		".aaaacaaaacaaaa.",
		".aaacaacaaacaaa.",
		"..acaacaacaaca..",
		"..aacaaccaacaa..",
		"...aacaaaacaa...",
		"....aaaaaaaa....",
		".....aaaaaa.....",
		".......aa......."],
	 "s9": [
		"aaaaaaaaa",
		"aacaaacaa",
		"aaaacaaaa",
		"accccccca",
		"aaaacaaaa",
		"aacacacaa",
		".acaaaca.",
		"..aaaaa..",
		"....a...."],
	 "s5": [
		"aaaaa",
		"a...a",
		"aa.aa",
		".a.a.",
		"..a.."]},
	{"id": "D", "nome": "R DE RAIZ", "s16": [
		".aaaaaaaa.......",
		".aaaaaaaaaa.....",
		".aac.....aaa....",
		".aa.......aa....",
		".aa.......aa....",
		".aa......aaa....",
		".aaaaaaaaaa.....",
		".aacaaaaaa......",
		".aa....aaa......",
		".aa.....aaa.....",
		".aa......aaa....",
		".aa.......aaa...",
		"aaaa.......aaa..",
		"a.a.a......a.aa.",
		"a..a.a....a...a.",
		"...a..a..a.....a"],
	 "s9": [
		"aaaaaa...",
		"aa...aa..",
		"aa...aa..",
		"aaaaaa...",
		"aa..aa...",
		"aa...aa..",
		"aa....aa.",
		"aaa..a.a.",
		"a.a.a...a"],
	 "s5": [
		"aaaa.",
		"a..a.",
		"aaa..",
		"a.aa.",
		"aa.aa"]},
	{"id": "E", "nome": "SELO DO TOCO", "s16": [
		".....aaaaaa.....",
		"...aaaaaaaaaa...",
		"..aaaaaaaaaaaa..",
		".aaaaccccccaaaa.",
		".aaaacaaaacaaaa.",
		"aaaaaccccccaaaaa",
		"aaaaaccccccaaaaa",
		"aaaaaccccccaaaaa",
		"aaaaccccccccaaaa",
		"aaacccaccacccaaa",
		".accaacaacaacca.",
		".acaaacaacaaaca.",
		"..aacaaaaaacaa..",
		"...aaaaaaaaaa...",
		".....aaaaaa.....",
		"................"],
	 "s9": [
		"..aaaaa..",
		".aacccaa.",
		"aaacacaaa",
		"aaacccaaa",
		"aaacccaaa",
		"aacccccaa",
		"acacacaca",
		".aaaaaaa.",
		"..aaaaa.."],
	 "s5": [
		".aaa.",
		"a...a",
		"aa.aa",
		"a...a",
		".aaa."]},
]

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	MAN = JSON.parse_string(FileAccess.open(SPR + "manifest.json", FileAccess.READ).get_as_text())
	var pad := 10
	var rowh := 200
	var W := 1100
	var H := 40 + OPTS.size() * rowh
	var img: Image = L.blank(W, H)
	L.R(img, 0, 0, W, H, "d1")
	L.text(img, "SIMBOLO DA ESCOLA RAIZES FIGHT CLUB: PROPOSTAS (MOCKUP, NADA APLICADO NO JOGO)", pad, 8, "white", 1, "ink")
	L.text(img, "AMPLIADO X8 (16, 9, 5)   PAREDE DA GARAGEM, TAMANHO REAL X3   PEITO: REGATA E CAMISETA (REAL E X4)   SELO DO MURAL (REAL E X4)", pad, 22, "g3", 1, "ink")
	var bg := _load(SPR + "garage/garage_bg.png")
	var lamp := _load(SPR + "garage/lamp.png").get_region(Rect2i(0, 0, 29, 48))
	var seal := _load(SPR + "ui/mural/ui_mural_seal.png")
	var y := 40
	for o in OPTS:
		L.R(img, 0, y, W, 1, "d2")
		L.text(img, o.id, pad, y + 8, "y1", 3, "ink")
		L.text(img, o.nome, pad, y + 34, "white", 1, "ink")
		var x := pad + 4
		# ampliados
		var s16 := sym(o.s16, "b1", "cream")
		blit(img, scaled(on(s16, "white"), 8), x, y + 50)
		x += 128 + 10
		blit(img, scaled(on(sym(o.s9, "b1", "cream"), "white"), 8), x, y + 10)
		blit(img, scaled(on(sym(o.s5, "b1", ""), "white"), 8), x + 16, y + 92)
		x += 72 + 14
		# parede
		var wall := bg.get_region(Rect2i(290, 24, 120, 60))
		var lp := 300 - 14 - 290
		wall.blend_rect(lamp, Rect2i(0, 0, 29, 48), Vector2i(lp, 32 - 24))
		var ws := wall_symbol(o.s16, bg)
		wall.blend_rect(ws, Rect2i(0, 0, 32, 40), Vector2i(344 - 290, 38 - 24))
		blit(img, scaled(wall, 3), x, y + 10)
		x += 360 + 14
		# peito
		for top in [["tank", "white", "blue"], ["tee", "black", "yellow"]]:
			var f := fighter(top[0], top[1], top[2], sym(o.s5, "SYM", ""))
			blit(img, f, x, y + 10)
			blit(img, scaled(f.get_region(Rect2i(14, 14, 22, 24)), 4), x + 52, y + 10)
			L.text(img, "REGATA" if top[0] == "tank" else "CAMISETA", x, y + 112, "g3", 1, "ink")
			x += 52 + 88 + 10
		# selo
		var sl := seal_with(seal, o.s9)
		blit(img, sl, x, y + 10)
		blit(img, scaled(sl, 4), x + 26, y + 10)
		y += rowh
	img.save_png(ROOT + "docs/arte/mockups/fase6d3_simbolo_opcoes.png")
	print("ok ", img.get_size())
	quit()

func _load(p: String) -> Image:
	var i := Image.load_from_file(p)
	i.convert(Image.FORMAT_RGBA8)
	return i

func blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func scaled(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func on(src: Image, c: String) -> Image:
	var b: Image = L.blank(src.get_width() + 2, src.get_height() + 2)
	L.R(b, 0, 0, b.get_width(), b.get_height(), c)
	blit(b, src, 1, 1)
	return b

## mapa -> imagem. ink = cor da tinta ("SYM" = cor-chave da camada school_symbol); cream = cor do creme ("" = vazio)
func sym(rows: Array, ink: String, cream: String) -> Image:
	var h := rows.size()
	var w: int = (rows[0] as String).length()
	var img: Image = L.blank(w, h)
	for y in h:
		for x in w:
			var ch: String = (rows[y] as String)[x]
			if ch == "a":
				img.set_pixel(x, y, Color.html("#304a78") if ink == "SYM" else L.col(ink))
			elif ch == "c" and cream != "":
				img.set_pixel(x, y, L.col(cream))
	return img

## 16x16 em 2x, pintado: tinta b1 que afunda no rejunte, creme, 2 escorridos, luz da lâmpada (como o wall_school_symbol)
func wall_symbol(rows: Array, bg: Image) -> Image:
	var under := bg.get_region(Rect2i(344, 38, 32, 40))
	var out: Image = L.blank(32, 40)
	var s := sym(rows, "b1", "cream")
	for y in 32:
		for x in 32:
			var c := s.get_pixel(x / 2, y / 2)
			if c.a == 0.0:
				continue
			var u := under.get_pixel(x, y)
			if u.r * 0.3 + u.g * 0.59 + u.b * 0.11 < 0.28:
				c = L.shade(c, -1)
			out.set_pixel(x, y, c)
	# escorridos: das 2 colunas de tinta mais baixas
	var n := 0
	for x in range(4, 28, 3):
		var yb := -1
		for y in range(31, -1, -1):
			if out.get_pixel(x, y).a > 0.0 and s.get_pixel(x / 2, y / 2).is_equal_approx(L.col("b1")):
				yb = y
				break
		if yb >= 22 and n < 2 and (x * 7) % 5 < 2:
			for k in 3 + n:
				if yb + 1 + k < 40:
					out.set_pixel(x, yb + 1 + k, L.col("b1") if k < 2 + n else L.col("b0"))
			n += 1
	L.light(out, Rect2i(0, 0, 32, 40), Vector2(305, 90) - Vector2(344, 38), 300.0, 1.1, 3.6, -1, 1, 0.9)
	return out

## discípulo parado (quadro 0), cabelo curto, com a estampa 5x5 no lugar da de hoje (23,24), só onde há pano
func fighter(top: String, top_color: String, ink: String, s5: Image) -> Image:
	var e: Dictionary = MAN.sprites.fighter_idle_disc_layered
	var lay: Dictionary = e.layers
	var body := part(lay.body)
	var topi := part(lay.top[top])
	var head := part(lay.head.short)
	var mask := part(lay.front_mask)
	var pb: Dictionary = MAN.by_data_id.disciple_palette
	var rc := {}
	for o in pb.options.top_color:
		if o.id == top_color:
			for slot in pb["keys"].top_color:
				rc[(pb["keys"].top_color[slot] as String).substr(1).to_lower()] = Color.html(o.ramp[slot])
	for o in pb.options.school_symbol:
		if o.id == ink:
			rc["304a78"] = Color.html(o.ramp.base)
	var under: Image = body.duplicate()
	blit(under, topi, 0, 0)
	var symb: Image = L.blank(48, 72)
	for y in 5:
		for x in 5:
			var c := s5.get_pixel(x, y)
			if c.a > 0.0 and topi.get_pixel(23 + x, 24 + y).a > 0.0:
				symb.set_pixel(23 + x, 24 + y, c)
	blit(under, symb, 0, 0)
	var out: Image = under.duplicate()
	blit(out, head, 0, 0)
	for y in 72:
		for x in 48:
			if mask.get_pixel(x, y).a > 0.0 and under.get_pixel(x, y).a > 0.0:
				out.set_pixel(x, y, under.get_pixel(x, y))
	for y in 72:
		for x in 48:
			var c := out.get_pixel(x, y)
			if c.a > 0.0:
				var hx := c.to_html(false).to_lower()
				if rc.has(hx):
					out.set_pixel(x, y, rc[hx])
	return out

func part(res: String) -> Image:
	return _load(ROOT + res.replace("res://", "")).get_region(Rect2i(0, 0, 48, 72))

## selo do mural: apaga o símbolo de hoje (miolo prateado) e carimba o 9x9 em azul
func seal_with(seal: Image, rows9: Array) -> Image:
	var s: Image = seal.duplicate()
	var silver := s.get_pixel(5, 2)
	var hi := s.get_pixel(7, 1)
	for y in range(2, 15):
		for x in range(2, 18):
			if Vector2(x + 0.5 - 10.0, y + 0.5 - 8.0).length() <= 6.6:
				s.set_pixel(x, y, silver)
	var m := sym(rows9, "b1", "")
	for y in 9:
		for x in 9:
			if m.get_pixel(x, y).a > 0.0:
				s.set_pixel(5 + x + 1, 3 + y + 0, m.get_pixel(x, y))
			elif rows9[y][x] == "c":
				s.set_pixel(5 + x + 1, 3 + y, hi)
	return s
