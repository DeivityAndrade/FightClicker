extends SceneTree
## Fase 6d3 (Diretor de Arte): aplica o símbolo da escola aprovado pelo dono, o "R de raiz" (proposta D,
## docs/arte/fase6d3-simbolo.md), em todos os lugares. PLACEHOLDER gerado por código.
## Rodar a partir de uma pasta com project.godot vazio:
##   godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_arte_fase6d3_simbolo.gd -- [--camadas <pasta>] [--assets <pasta>]
## Parte sempre dos originais guardados em tools/art/fonte_6d3/simbolo/ (pode rodar de novo). Grava em assets/sprites:
##   ui/school_symbol_5/9/16/32           os 4 tamanhos (azul de carimbo b1 + b2)
##   box/box_big, box/box_small            a etiqueta da caixa da escola (o 9x9 e o 5x5 pintados no papel)
##   garage/wall_mural, gym/wall_mural_gym a plaquinha da escola no mural (9x9 sobre o papel)
##   ui/icon_honor_16                      a roseta da Honra (o 5x5 no miolo)
##   ui/icon_garage_saved                  o ícone ao lado de GARAGEM SALVA (carimbo redondo com o 5x5)
##   ui/seal_garage_saved(_text)           o carimbo redondo do selo GARAGEM SALVA (o 16 com falhas de tinta)
##   ui/mural/ui_mural_seal                o selo "saiu por cima" (9x9 na roseta)
##   garage/wall_school_symbol             o símbolo pintado na parede da garagem salva (16 em 2x, tinta b1 + creme, escorridos)
##   disciple/*_disc_symbol_*.png          (com --camadas) a camada school_symbol de TODAS as poses: copiada da pasta onde os
##       geradores de personagem gravaram (personagem_lib.gd já desenha o R), desvirando o carimbo nas folhas viradas
##       (o R não é simétrico), e o busto do mural (recorte 9,-1,28,30 do quadro 0 da disciple_stand_bare).
## Geradores de personagem (numa pasta temporária, nunca no projeto):
##   FC_LUTADOR=disc FC_CAMADAS=1 make_sprites_jogador.gd -- <tmp>/jog <tmp>/old
##   FC_LUTADOR=disc FC_CAMADAS=1 make_golpes_jogador.gd -- <tmp>/golpes
##   make_sprites_fase6b1.gd -- <tmp>/b1 <tmp>/jog ;  make_sprites_fase6c1.gd -- <tmp>/c1
##   e passar --camadas <tmp> (ele procura os *_disc_symbol_*.png em todas as subpastas).

const ROOT := "E:/Fightclicker/"
const FONTE := ROOT + "tools/art/fonte_6d3/simbolo/"
var ASSETS := ROOT + "assets/sprites/"
var CAMADAS := ""
var L
var MAN := {}

const S16 := [
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
	"...a..a..a.....a"]
const S9 := [
	"aaaaaa...",
	"aa...aa..",
	"aa...aa..",
	"aaaaaa...",
	"aa..aa...",
	"aa...aa..",
	"aa....aa.",
	"aaa..a.a.",
	"a.a.a...a"]
const S5 := [
	"aaaa.",
	"a..a.",
	"aaa..",
	"a.aa.",
	"aa.aa"]
const R3 := ["aa.", "a.a", "aa.", "a.a", "a.a"]

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--assets" and i + 1 < args.size():
			ASSETS = args[i + 1].trim_suffix("/") + "/"
		if args[i] == "--camadas" and i + 1 < args.size():
			CAMADAS = args[i + 1].trim_suffix("/") + "/"
	MAN = JSON.parse_string(FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.READ).get_as_text())
	# 1) os 4 tamanhos
	var s16 := sym(S16, "b1", "b2")
	s16.save_png(ASSETS + "ui/school_symbol_16.png")
	var s32: Image = s16.duplicate()
	s32.resize(32, 32, Image.INTERPOLATE_NEAREST)
	s32.save_png(ASSETS + "ui/school_symbol_32.png")
	sym(S9, "b1", "b2").save_png(ASSETS + "ui/school_symbol_9.png")
	sym(S5, "b1", "b2").save_png(ASSETS + "ui/school_symbol_5.png")
	# 2) etiquetas das caixas
	patch_sheet("box/box_big.png", 76, 9, 0.7)
	patch_sheet("box/box_small.png", 48, 5, 0.7)
	# 3) plaquinha do mural (garagem e academia)
	patch_sheet("garage/wall_mural.png", 55, 9, 0.7)
	patch_sheet("gym/wall_mural_gym.png", 55, 9, 0.7)
	# 3b) selo GARAGEM SALVA (aviso de cobrança com o carimbo redondo da escola): troca o miolo do carimbo
	ring_stamp("ui/seal_garage_saved.png")
	ring_stamp("ui/seal_garage_saved_text.png")
	# 3b2) ícone grande da Honra (roseta 16x16 com o 5x5 no miolo)
	patch_sheet("ui/icon_honor_16.png", 16, 5, 0.7)
	# 3c) ícone GARAGEM SALVA (16x16, na linha de prêmio da vitória): carimbo redondo pequeno, miolo = o 5x5
	var ic := _load(FONTE + "icon_garage_saved.png")
	L.ellipse(ic, 10.5, 10.5, 4.0, 4.0, "cream")
	var s5 := sym(S5, "b1", "")
	for y in 5:
		for x in 5:
			if s5.get_pixel(x, y).a > 0.0:
				ic.set_pixel(8 + x, 8 + y, s5.get_pixel(x, y))
	ic.save_png(ASSETS + "ui/icon_garage_saved.png")
	# 4) selo do mural
	seal().save_png(ASSETS + "ui/mural/ui_mural_seal.png")
	# 5) parede da garagem salva
	var bg := _load(ROOT + "assets/sprites/garage/garage_bg.png")
	wall_symbol(bg).save_png(ASSETS + "garage/wall_school_symbol.png")
	# 6) camadas do discípulo
	if CAMADAS != "":
		layers()
	print("6d3 símbolo: aplicado em ", ASSETS)
	quit()

func _load(p: String) -> Image:
	var i := Image.load_from_file(p)
	i.convert(Image.FORMAT_RGBA8)
	return i

func sym(rows: Array, ink: String, hi: String) -> Image:
	var h := rows.size()
	var w: int = (rows[0] as String).length()
	var img: Image = L.blank(w, h)
	for y in h:
		for x in w:
			var ch: String = (rows[y] as String)[x]
			if ch == "a":
				img.set_pixel(x, y, L.col(ink))
			elif ch == "c" and hi != "":
				img.set_pixel(x, y, L.col(hi))
	return img

## Acha o carimbo antigo (o school_symbol_9 ou _5 de fonte, pela forma: pixels azulados nos lugares da tinta) em cada quadro,
## apaga a tinta (vira a cor do papel em volta) e pinta o novo com a tinta mais comum do carimbo antigo (já com a luz da sala),
## só sobre o papel. size = 9 ou 5; minf = fração mínima dos pixels do carimbo antigo que batem.
func patch_sheet(rel: String, fw: int, size: int, minf: float) -> void:
	var img := _load(FONTE + rel.get_file())
	var hits := 0
	var old := _load(FONTE + "school_symbol_%d.png" % size)
	var nw: Array = S9 if size == 9 else S5
	var opx := []
	for y in size:
		for x in size:
			if old.get_pixel(x, y).a > 0.0:
				opx.append(Vector2i(x, y))
	for q in img.get_width() / fw:
		var best := 0.0
		var bo := Vector2i(-1, -1)
		for y in img.get_height() - size + 1:
			for x in range(q * fw, q * fw + fw - size + 1):
				var m := 0
				var out := 0
				for yy in size:
					for xx in size:
						var bl := bluish(img.get_pixel(x + xx, y + yy))
						var want := old.get_pixel(xx, yy).a > 0.0
						if want and bl:
							m += 1
						elif bl and not want:
							out += 1
				var f := float(m - out) / float(opx.size())
				if f > best:
					best = f
					bo = Vector2i(x, y)
		if best < minf:
			continue
		var cnt := {}
		for p: Vector2i in opx:
			var c := img.get_pixel(bo.x + p.x, bo.y + p.y)
			if bluish(c):
				cnt[c.to_html()] = cnt.get(c.to_html(), 0) + 1
		var ink_k := ""
		for k in cnt:
			if ink_k == "" or cnt[k] > cnt[ink_k]:
				ink_k = k
		var ink := Color.html(ink_k)
		var paper := most_common_around(img, Rect2i(bo, Vector2i(size, size)))
		for yy in size:
			for xx in size:
				if bluish(img.get_pixel(bo.x + xx, bo.y + yy)):
					img.set_pixel(bo.x + xx, bo.y + yy, paper)
		for yy in size:
			for xx in size:
				if (nw[yy] as String)[xx] == "a" and img.get_pixel(bo.x + xx, bo.y + yy).is_equal_approx(paper):
					img.set_pixel(bo.x + xx, bo.y + yy, ink)
		hits += 1
	img.save_png(ASSETS + rel)
	print("  ", rel, ": ", hits, " carimbo(s) trocado(s)")

## Carimbo redondo (anel + desenho no meio, com falhas de tinta) sobre papel pautado: apaga o desenho de dentro do anel
## (cada pixel volta a ser o papel/linha da mesma fileira) e carimba o R 16x16 no meio, com as mesmas falhas.
func ring_stamp(rel: String) -> void:
	var img := _load(FONTE + rel.get_file())
	var pts := []
	var sum := Vector2.ZERO
	for y in img.get_height():
		for x in img.get_width():
			if bluish(img.get_pixel(x, y)):
				pts.append(Vector2i(x, y))
				sum += Vector2(x, y)
	if pts.is_empty():
		print("  ", rel, ": sem carimbo")
		return
	var cen := sum / float(pts.size())
	var rmax := 0.0
	for p: Vector2i in pts:
		rmax = maxf(rmax, (Vector2(p) - cen).length())
	var inner := rmax * 0.72
	var ink := Color(0, 0, 0, 0)
	var ink2 := Color(0, 0, 0, 0)
	var cnt := {}
	for p: Vector2i in pts:
		var k := img.get_pixel(p.x, p.y).to_html()
		cnt[k] = cnt.get(k, 0) + 1
	var ks := cnt.keys()
	ks.sort_custom(func(a, b): return cnt[a] > cnt[b])
	ink = Color.html(ks[0])
	ink2 = Color.html(ks[1]) if ks.size() > 1 else ink
	for p: Vector2i in pts:
		if (Vector2(p) - cen).length() < inner:
			img.set_pixel(p.x, p.y, row_paper(img, p))
	var o := Vector2i(int(round(cen.x - 8.0)), int(round(cen.y - 8.0)))
	for y in 16:
		for x in 16:
			if (S16[y] as String)[x] == ".":
				continue
			var h := absi((x * 73856093) ^ (y * 19349663) ^ 4421) % 100
			if h < 12:
				continue
			img.set_pixel(o.x + x, o.y + y, ink2 if h > 80 else ink)
	img.save_png(ASSETS + rel)
	print("  ", rel, ": carimbo redondo trocado (centro ", cen, ", raio ", rmax, ")")

## cor do papel/linha na mesma fileira, perto de p, sem tinta azul
func row_paper(img: Image, p: Vector2i) -> Color:
	for d in range(1, 20):
		for sx in [-1, 1]:
			var x: int = p.x + d * sx
			if x >= 0 and x < img.get_width():
				var c := img.get_pixel(x, p.y)
				if c.a > 0.0 and not bluish(c):
					return c
	return img.get_pixel(p.x, p.y)

func bluish(c: Color) -> bool:
	return c.a > 0.0 and c.b > c.r + 0.12 and c.b > c.g + 0.04

func most_common_around(img: Image, r: Rect2i) -> Color:
	var cnt := {}
	for y in range(r.position.y - 1, r.end.y + 1):
		for x in range(r.position.x - 1, r.end.x + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			if bluish(c):
				continue
			var k := c.to_html()
			cnt[k] = cnt.get(k, 0) + 1
	var best := ""
	for k in cnt:
		if best == "" or cnt[k] > cnt[best]:
			best = k
	return Color.html(best)

## selo do mural: apaga o miolo da roseta (prata) e carimba o 9x9 em azul
func seal() -> Image:
	var s := _load(FONTE + "ui_mural_seal.png")
	var silver := s.get_pixel(5, 2)
	for y in range(2, 15):
		for x in range(2, 18):
			if Vector2(x + 0.5 - 10.0, y + 0.5 - 8.0).length() <= 6.6:
				s.set_pixel(x, y, silver)
	var m := sym(S9, "b1", "")
	for y in 9:
		for x in 9:
			if m.get_pixel(x, y).a > 0.0:
				s.set_pixel(6 + x, 3 + y, m.get_pixel(x, y))
	return s

## 16 em 2x, pintado: tinta b1 que afunda no rejunte, creme nos realces, 2 escorridos, luz da lâmpada da garagem
func wall_symbol(bg: Image) -> Image:
	var under := bg.get_region(Rect2i(344, 38, 32, 40))
	var out: Image = L.blank(32, 40)
	var s := sym(S16, "b1", "cream")
	for y in 32:
		for x in 32:
			var c := s.get_pixel(x / 2, y / 2)
			if c.a == 0.0:
				continue
			var u := under.get_pixel(x, y)
			if u.r * 0.3 + u.g * 0.59 + u.b * 0.11 < 0.28:
				c = L.shade(c, -1)
			out.set_pixel(x, y, c)
	for d: Array in [[4, 3], [23, 4]]:
		var x: int = d[0]
		var yb := -1
		for y in range(31, -1, -1):
			if out.get_pixel(x, y).a > 0.0:
				yb = y
				break
		for k in int(d[1]):
			if yb >= 0 and yb + 1 + k < 40:
				out.set_pixel(x, yb + 1 + k, L.col("b1") if k < int(d[1]) - 1 else L.col("b0"))
	L.light(out, Rect2i(0, 0, 32, 40), Vector2(305, 90) - Vector2(344, 38), 300.0, 1.1, 3.6, -1, 1, 0.9)
	return out

# ------------------------------------------------------------------ camadas do discípulo
func layers() -> void:
	# tamanho de quadro de cada arquivo de camada (pelo manifest)
	var fsize := {}
	for k in MAN.sprites:
		var e: Dictionary = MAN.sprites[k]
		var ss = e.get("layers", {}).get("school_symbol", null)
		if ss is Dictionary:
			for part in ss:
				fsize[str(ss[part]).get_file()] = Vector2i(int(e.frame_size[0]), int(e.frame_size[1]))
	var found := {}
	_walk(CAMADAS, found)
	var n := 0
	var flipped := 0
	var missing := []
	for f in fsize:
		if not found.has(f):
			missing.append(f)
			continue
		var img := _load(found[f])
		var cur := _load(ROOT + "assets/sprites/disciple/" + f)
		if img.get_size() != cur.get_size():
			# a folha do jogo veio de outra rodada (ex.: fighter_rope 48x80): troca o carimbo no lugar
			var fs0: Vector2i = fsize[f]
			var rs: Image = _load(FONTE + f) if FileAccess.file_exists(FONTE + f) else cur.duplicate()
			var nr := 0
			for q in rs.get_width() / fs0.x:
				nr += restamp(rs, Rect2i(q * fs0.x, 0, fs0.x, fs0.y))
			rs.save_png(ASSETS + "disciple/" + f)
			print("  ", f, ": folha de outra rodada, ", nr, " carimbo(s) trocado(s) no lugar")
			continue
		var fs: Vector2i = fsize[f]
		for q in img.get_width() / fs.x:
			if unflip(img, Rect2i(q * fs.x, 0, fs.x, fs.y)):
				flipped += 1
		check_same_frames(f, img, cur, fs)
		img.save_png(ASSETS + "disciple/" + f)
		n += 1
	print("  camadas do discípulo: ", n, " arquivos; carimbos desvirados: ", flipped)
	if not missing.is_empty():
		print("  SEM ARQUIVO NOVO (ficou o antigo): ", missing)
	# busto do mural: recorte (9,-1,28,30) do quadro 0 da disciple_stand_bare
	var sb := _load(ASSETS + "disciple/" + str(MAN.sprites.disciple_stand_bare.layers.school_symbol.chest).get_file())
	var bust: Image = L.blank(28, 30)
	bust.blit_rect(sb, Rect2i(9, 0, 28, 29), Vector2i(0, 1))
	var old_bust := _load(FONTE + "mural_portrait_disc_symbol_chest.png")
	print("  busto do mural: antes tinha ", old_bust.get_used_rect(), ", agora ", bust.get_used_rect())
	bust.save_png(ASSETS + "disciple/mural_portrait_disc_symbol_chest.png")

func _walk(d: String, found: Dictionary) -> void:
	for sd in DirAccess.get_directories_at(d):
		_walk(d + sd + "/", found)
	for f in DirAccess.get_files_at(d):
		if f.find("_disc_symbol_") >= 0 and f.ends_with(".png"):
			found[f] = d + f

## Quadros com e sem símbolo devem ser os mesmos de antes (o carimbo só mudou de desenho).
func check_same_frames(f: String, a: Image, b: Image, fs: Vector2i) -> void:
	for q in a.get_width() / fs.x:
		var r := Rect2i(q * fs.x, 0, fs.x, fs.y)
		var ua := a.get_region(r).get_used_rect().has_area()
		var ub := b.get_region(r).get_used_rect().has_area()
		if ua != ub:
			print("  AVISO ", f, " quadro ", q, ": antes ", ub, " agora ", ua)

const OLD34 := [".aaa.", ".aaa.", "..a..", "aaaaa", "a.a.a"]
const OLD3 := ["aaa", "aaa", ".a.", "aaa", "a.a"]

## Troca no lugar o carimbo antigo (lâmpada 5x5 ou 3x5) pelo R do mesmo tamanho. Onde o antigo estava tapado (braço),
## o novo também fica tapado; pixels novos fora do desenho antigo só entram se o carimbo antigo estava inteiro.
func restamp(img: Image, fr: Rect2i) -> int:
	var pts := []
	for y in range(fr.position.y, fr.end.y):
		for x in range(fr.position.x, fr.end.x):
			if img.get_pixel(x, y).a > 0.0:
				pts.append(Vector2i(x, y))
	if pts.is_empty():
		return 0
	var best := -999
	var bo := Vector2i.ZERO
	var bt := []
	var bn := []
	for pair: Array in [[OLD34, S5], [OLD3, R3]]:
		var t: Array = pair[0]
		var w: int = (t[0] as String).length()
		for p0: Vector2i in pts:
			for oy in t.size():
				for ox in w:
					var o := p0 - Vector2i(ox, oy)
					var sc := 0
					for p: Vector2i in pts:
						var lx := p.x - o.x
						var ly := p.y - o.y
						sc += 1 if lx >= 0 and ly >= 0 and lx < w and ly < t.size() and (t[ly] as String)[lx] == "a" else -2
					if sc > best:
						best = sc
						bo = o
						bt = t
						bn = pair[1]
	var w2: int = (bt[0] as String).length()
	var whole := true
	for yy in bt.size():
		for xx in w2:
			if (bt[yy] as String)[xx] == "a" and img.get_pixel(bo.x + xx, bo.y + yy).a == 0.0:
				whole = false
	var base := Color.html("#304a78")
	var old_px := {}
	for yy in bt.size():
		for xx in w2:
			var c := img.get_pixel(bo.x + xx, bo.y + yy)
			if c.a > 0.0:
				old_px[Vector2i(xx, yy)] = c
			img.set_pixel(bo.x + xx, bo.y + yy, Color(0, 0, 0, 0))
	for yy in bn.size():
		for xx in (bn[yy] as String).length():
			if (bn[yy] as String)[xx] != "a":
				continue
			var k := Vector2i(xx, yy)
			if old_px.has(k):
				img.set_pixel(bo.x + xx, bo.y + yy, old_px[k])
			elif whole:
				img.set_pixel(bo.x + xx, bo.y + yy, base)
	return 1

## Se o carimbo do quadro está espelhado (folha virada), desvira no lugar. Devolve true se desvirou.
func unflip(img: Image, fr: Rect2i) -> bool:
	var pts := []
	for y in range(fr.position.y, fr.end.y):
		for x in range(fr.position.x, fr.end.x):
			if img.get_pixel(x, y).a > 0.0:
				pts.append(Vector2i(x, y))
	if pts.size() < 4:
		return false
	var best := -999
	var best_m := false
	var best_o := Vector2i.ZERO
	var best_t := []
	for t: Array in [S5, R3]:
		for mir in [false, true]:
			var rows := mirror(t) if mir else t
			var w: int = (rows[0] as String).length()
			var h: int = rows.size()
			for p0: Vector2i in pts:
				for oy in h:
					for ox in w:
						var o := p0 - Vector2i(ox, oy)
						var sc := 0
						for p: Vector2i in pts:
							var lx := p.x - o.x
							var ly := p.y - o.y
							if lx >= 0 and ly >= 0 and lx < w and ly < h and (rows[ly] as String)[lx] == "a":
								sc += 1
							else:
								sc -= 2
						if sc > best or (sc == best and best_m and not mir):
							best = sc
							best_m = mir
							best_o = o
							best_t = rows
	if not best_m:
		return false
	var w2: int = (best_t[0] as String).length()
	var h2: int = best_t.size()
	var reg := img.get_region(Rect2i(best_o, Vector2i(w2, h2)))
	reg.flip_x()
	img.fill_rect(Rect2i(best_o, Vector2i(w2, h2)), Color(0, 0, 0, 0))
	img.blend_rect(reg, Rect2i(Vector2i.ZERO, reg.get_size()), best_o)
	return true

func mirror(rows: Array) -> Array:
	var out := []
	for r in rows:
		var s := ""
		for i in range((r as String).length() - 1, -1, -1):
			s += (r as String)[i]
		out.append(s)
	return out
