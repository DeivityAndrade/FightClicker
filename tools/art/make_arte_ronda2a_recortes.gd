extends SceneTree
## Ronda 2a1, B1 (Diretor de Arte, 2026-11-26): o RECORTE DE JORNAL de cada bandido vencido, na parede dos 3 locais.
## Design §6.2: 1 recorte por bandido vencido, "ao lado do recorte do Gato Preto", 0 a 3 papéis empilhados; o hover mostra a
## manchete do mais recente (chave alley_<id>_clipping do data/ui_texts.json). O recorte de nível da lenda (Ronda 1) não muda.
##
## Cada recorte é um papel PEQUENO de 15x18 (o do Gato Preto tem 23x28: estes são notas de rodapé dele), sem texto legível em
## 1x (não cabe; o texto inteiro vai no hover, como o zoom/hover dos recortes da Ronda 1). Ele se reconhece pela FOTO, que mostra
## o que o bandido largou na rua (o estepe / a bicicleta / o portão), pelas 2 barras de manchete e pelo CARIMBO do gato em
## vermelho (orelhas redondas, como o capuz), que é a marca de que o Gato Preto passou ali.
## Papel creme na garagem (luz quente da lâmpada pela esquerda, como o recorte da Ronda 1), branco na academia e no centro.
##
## Pontos (canto de cima à esquerda, 1x): 3 por local, na ordem em que os bandidos abrem (tire -> bike -> gate); cada um é
## desenhado por cima do anterior (gate na frente) e eles se sobrepõem uns 3 px, como papéis pregados um em cima do outro.
## Conferência no fim: nenhum encosta no recorte do Gato Preto, no capuz no prego (352,95), na corrente do saco, na zona do
## alvo, nos cards e no painel, nem em nada que o manifest posiciona; e a parede embaixo de cada um é lisa nos 3 fundos.
##
## Rodar headless de uma pasta temporária com project.godot vazio, APPDATA temporário, um Godot por vez:
##   godot --headless --max-fps 30 --path <tmp> --script <repo>/tools/art/make_arte_ronda2a_recortes.gd -- --root <repo>
##        [--caps <pasta com f6d2_garagem_cheia.png, f6d2_academia_cheia.png, f8a2_centro_cheia_boxe.png do ui_audit>]
##        [--no-assets]
## Grava assets/sprites/garage/wall_clipping_alley_<id>.png, assets/sprites/gym/wall_clipping_alley_<id>_gym.png,
## tools/art/ronda2a_recortes.json (entradas do manifest + pontos, para mesclar) e docs/arte/mockups/ronda2a_recortes_*.png.

const IDS := ["tire", "bike", "gate"]
const CLIP := Vector2i(15, 18)
## Pontos (canto de cima à esquerda) por local e por bandido.
const SPOTS := {
	"garage": {"tire": [269, 108], "bike": [284, 112], "gate": [275, 127]},
	"gym": {"tire": [365, 39], "bike": [378, 43], "gate": [370, 55]},
	"center": {"tire": [365, 103], "bike": [378, 107], "gate": [370, 121]},
}
const POINT_NAME := {"garage": "alley_clipping_spot", "gym": "gym_alley_clipping_spot", "center": "center_alley_clipping_spot"}
const HOOD_SPOT := Vector2i(352, 95)
const HOOD_PIVOT := Vector2i(8, 1)

var ROOT := ""
var CAPS := ""
var NO_ASSETS := false
var L
var MAN := {}
var CLIPS := {}    # "garage"/"gym" -> id -> Image
var CHECKS := []

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--root" and i + 1 < args.size():
			ROOT = args[i + 1]
		if args[i] == "--caps" and i + 1 < args.size():
			CAPS = args[i + 1].replace("\\", "/").trim_suffix("/") + "/"
		if args[i] == "--no-assets":
			NO_ASSETS = true
	ROOT = ROOT.replace("\\", "/").trim_suffix("/") + "/"
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	MAN = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	for warm in [true, false]:
		var k := "garage" if warm else "gym"
		CLIPS[k] = {}
		for id in IDS:
			CLIPS[k][id] = clip(id, warm)
	if not NO_ASSETS:
		for id in IDS:
			save(CLIPS.garage[id], "garage/wall_clipping_alley_%s.png" % id)
			save(CLIPS.gym[id], "gym/wall_clipping_alley_%s_gym.png" % id)
		write_json()
	check()
	prancha()
	for c in CHECKS:
		print(c)
	quit()

func save(im: Image, rel: String) -> void:
	var p := ROOT + "assets/sprites/" + rel
	DirAccess.make_dir_recursive_absolute(p.get_base_dir())
	im.save_png(p)

# ================================================================== o recorte
func hsh(x: int, y: int, s: int) -> float:
	var n := (x * 374761393 + y * 668265263 + s * 2147483) & 0x7fffffff
	n = (n ^ (n >> 13)) * 1274126177 & 0x7fffffff
	return float(n % 1000) / 1000.0

const BAY := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
func bayer(x: int, y: int) -> float:
	return (float(BAY[y % 4][x % 4]) + 0.5) / 16.0

## Carimbo do gato (4x3, vermelho), ao lado da 2ª linha da manchete: cabeça com orelhas baixas (as do capuz), sem ponta.
const STAMP := ["r..r", "rrrr", ".rr."]

func clip(id: String, warm: bool) -> Image:
	var w := CLIP.x
	var h := CLIP.y
	var seed: int = {"tire": 3, "bike": 5, "gate": 7}[id] + (0 if warm else 11)
	var paper := "cream" if warm else "white"
	var paper_d := "g3" if warm else "cream"
	var im: Image = L.blank(w, h)
	# papel com borda picotada (pedacinhos arrancados nas laterais e embaixo)
	L.R(im, 0, 1, w, h - 1, "ink")
	L.R(im, 1, 2, w - 2, h - 3, paper)
	for y in range(4, h - 1):
		for side in [0, 1]:
			if hsh(y, side, seed) > 0.68:
				var xo: int = 0 if side == 0 else w - 1
				var xi: int = 1 if side == 0 else w - 2
				im.set_pixel(xo, y, Color(0, 0, 0, 0))
				im.set_pixel(xi, y, L.col("ink"))
	for x in range(2, w - 2):
		if hsh(x, 9, seed) > 0.62:
			im.set_pixel(x, h - 1, Color(0, 0, 0, 0))
			im.set_pixel(x, h - 2, L.col("ink"))
	# cabeçalho do jornal (fio cinza) e a manchete (2 barras de tinta, a 2ª mais curta: "palavras" com 1 px de vão)
	L.R(im, 2, 3, w - 4, 1, "g1")
	var cuts: Array = {"tire": [6, 4], "bike": [4, 6], "gate": [5, 5]}[id]
	L.R(im, 2, 5, w - 4, 2, "ink")
	im.set_pixel(2 + cuts[0], 5, L.col(paper)); im.set_pixel(2 + cuts[0], 6, L.col(paper))
	L.R(im, 2, 8, 5 + cuts[1] % 3, 1, "ink")
	# foto 11x6
	photo(im, id, Rect2i(2, 10, w - 4, 6))
	L.R(im, 2, 16, w - 4, 1, paper_d)
	# carimbo do gato no canto da foto
	for r in STAMP.size():
		var row: String = STAMP[r]
		for k in row.length():
			if row[k] == "r":
				im.set_pixel(w - 6 + k, 7 + r, L.col("r2"))
	# fita no alto (posição muda por recorte: papéis pregados à mão)
	var tx: int = {"tire": 4, "bike": 6, "gate": 5}[id]
	for y in range(0, 3):
		for x in range(tx, tx + 5):
			if (x + y) % 2 == 0 or y == 1:
				im.set_pixel(x, y, L.col("y2" if warm else "white"))
	if warm:
		# a lâmpada da garagem fica à esquerda (x 300): a borda de longe do papel escurece em dither, como o da Ronda 1
		for y in range(8, h):
			for x in range(w - 6, w - 1):
				var c := im.get_pixel(x, y)
				if c.a > 0.0 and c == L.col(paper) and bayer(x, y) < float(y - 8) / 14.0:
					im.set_pixel(x, y, L.shade(c, -1))
	return im

## Foto granulada (cinzas) do que o bandido largou: tire = o estepe caído; bike = a bicicleta de volta; gate = o portão com o
## pé de cabra no chão. Cada uma com a silhueta lida em 1x pela forma, não pelo detalhe.
func photo(im: Image, id: String, r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var t := float(y - r.position.y) / float(r.size.y)
			im.set_pixel(x, y, L.col("g1" if bayer(x, y) < 0.5 - t * 0.3 else "g0"))
	var x0 := r.position.x
	var y0 := r.position.y
	L.R(im, x0, y0 + 5, r.size.x, 1, "g2")     # calçada
	match id:
		"tire":
			# estepe em pé (anel escuro com o aro claro) e a chave de roda caída
			for p in [[1, 1], [2, 1], [3, 1], [0, 2], [4, 2], [0, 3], [4, 3], [1, 4], [2, 4], [3, 4]]:
				L.P(im, x0 + 1 + p[0], y0 + p[1], "ink")
			L.R(im, x0 + 2, y0 + 2, 2, 2, "g3")
			L.R(im, x0 + 7, y0 + 4, 4, 1, "g3"); L.P(im, x0 + 7, y0 + 3, "g3")
		"bike":
			# duas rodas e o quadro
			for cx in [x0 + 2, x0 + 7]:
				for p in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
					L.P(im, cx + p[0], y0 + 3 + p[1], "ink")
			L.R(im, x0 + 3, y0 + 2, 4, 1, "g3")
			L.P(im, x0 + 4, y0 + 1, "g3"); L.P(im, x0 + 7, y0 + 1, "g3"); L.P(im, x0 + 8, y0 + 1, "g3")
		"gate":
			# o portão de grade (barras) e o pé de cabra no chão
			L.R(im, x0, y0, r.size.x, 1, "ink")
			for bx in range(x0 + 1, x0 + 7, 2):
				L.R(im, bx, y0, 1, 5, "ink")
			L.P(im, x0 + 7, y0 + 4, "g3"); L.P(im, x0 + 8, y0 + 4, "g3"); L.P(im, x0 + 9, y0 + 4, "g3"); L.P(im, x0 + 10, y0 + 3, "g3")

# ================================================================== manifest
func sprite_id(id: String, loc: String) -> String:
	return "wall_clipping_alley_%s" % id + ("" if loc == "garage" else "_" + loc)

func write_json() -> void:
	var sprites := {}
	var lay := {}
	var txt := {}
	for id in IDS:
		txt[id] = "alley_%s_clipping" % id
	for loc in ["garage", "gym", "center"]:
		var pts := {}
		var spr_by := {}
		var u := Rect2i()
		for i in IDS.size():
			var id: String = IDS[i]
			var p: Array = SPOTS[loc][id]
			pts[id] = p
			var sid := sprite_id(id, loc)
			spr_by[id] = sid
			var file := "res://assets/sprites/garage/wall_clipping_alley_%s.png" % id if loc == "garage" else "res://assets/sprites/gym/wall_clipping_alley_%s_gym.png" % id
			var r := Rect2i(int(p[0]), int(p[1]), CLIP.x, CLIP.y)
			u = r if i == 0 else u.merge(r)
			sprites[sid] = {"file": file, "frame_size": [CLIP.x, CLIP.y], "frames": 1, "fps": 0.0, "pivot": [0, 0],
				"pos": p, "point": POINT_NAME[loc] + "." + id, "layer": "wall", "z": -45,
				"note": ("Ronda 2a1 (B1): recorte de jornal do bandido '%s' vencido, %s (15x18). Sem texto em 1x: foto do que ele largou "
					+ "(%s), 2 barras de manchete e o carimbo vermelho do gato. Hover: o texto %s (manchete do mais recente). Gerador: "
					+ "tools/art/make_arte_ronda2a_recortes.gd. docs/arte/ronda2a-manifest.md §B1.") % [id,
					{"garage": "na GARAGEM (papel creme, luz da lâmpada pela esquerda)", "gym": "na ACADEMIA (papel branco)", "center": "no CENTRO (mesmo arquivo da academia)"}[loc],
					{"tire": "o estepe e a chave de roda", "bike": "a bicicleta", "gate": "o portão e o pé de cabra"}[id], txt[id]]}
		lay[POINT_NAME[loc]] = pts
		lay[POINT_NAME[loc] + "_info"] = {"location": loc, "anchor": "canto de cima à esquerda (cada ponto)", "size": [CLIP.x, CLIP.y],
			"layer": "wall", "z": -45, "order": IDS, "sprite_by_id": spr_by, "object_text_by_id": txt,
			"click_rect": [u.position.x, u.position.y, u.size.x, u.size.y],
			"when": "um por bandido vencido (permanent.alley); desenhar na ordem de order (o último fica por cima)",
			"hover": "o texto object_text_by_id do bandido vencido mais recente (o último de order que já foi vencido)",
			"_nota": {"garage": "Ronda 2a1 (B1): embaixo do pôster SOCO (até y 104) e à esquerda do recorte do Gato Preto (x 304); acima da corda no gancho (296,166) e da zona do alvo (y 150). Parede lisa embaixo (conferido no gerador).",
				"gym": "Ronda 2a1 (B1): à direita do recorte do Gato Preto (até x 363), acima do relógio de rounds (y 74), antes do cartaz da liga (x 394) e embaixo do teto. Parede lisa embaixo (conferido no gerador).",
				"center": "Ronda 2a1 (B1): à direita do capuz no prego (até x 362), embaixo do relógio de rounds (até y 100), antes da porta de vidro (x 399). Parede lisa embaixo (conferido no gerador)."}[loc]}
	var out := {"_sobre": "Ronda 2a1 B1 (Diretor de Arte): recortes dos bandidos vencidos. sprites -> manifest.sprites (todas novas); layout -> manifest.layout (todas novas). Doc: docs/arte/ronda2a-manifest.md §B1.",
		"sprites": sprites, "layout": lay}
	var f := FileAccess.open(ROOT + "tools/art/ronda2a_recortes.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t", false))
	f.close()

# ================================================================== conferência
func load_png(p: String) -> Image:
	var im := Image.load_from_file(p)
	if im != null:
		im.convert(Image.FORMAT_RGBA8)
	return im

func spr(id: String) -> Dictionary:
	return MAN.sprites.get(id, {})

func frame_of(id: String, q := 0) -> Image:
	var e := spr(id)
	var img := load_png(ROOT + str(e.file).replace("res://", ""))
	var fw := int(e.frame_size[0])
	var fh := int(e.frame_size[1])
	var n := maxi(img.get_width() / fw, 1)
	return img.get_region(Rect2i(clampi(q, 0, n - 1) * fw, 0, fw, fh))

func color_name(c: Color) -> String:
	var hx := c.to_html(false)
	for k in L.PAL_HEX:
		if L.PAL_HEX[k] == hx:
			return k
	return hx

func check() -> void:
	var problems := 0
	var hood := Rect2i(342, 94, 20, 24)   # click_rect do capuz
	var busy := {
		"garage": {"recorte do Gato Preto": Rect2i(304, 100, 23, 28), "capuz no prego": hood, "pôster SOCO": Rect2i(266, 62, 33, 42),
			"lâmpada": Rect2i(286, 32, 30, 48), "corrente do saco": Rect2i(334, 33, 3, 150), "corda no gancho": Rect2i(286, 160, 22, 50),
			"porta da garagem": Rect2i(378, 96, 92, 126), "símbolo da escola": Rect2i(344, 38, 32, 40), "parede da memória": Rect2i(176, 60, 81, 100)},
		"gym": {"recorte do Gato Preto": Rect2i(340, 60, 23, 28), "capuz no prego": hood, "relógio de rounds": Rect2i(370, 74, 28, 54),
			"espelho": Rect2i(262, 50, 70, 98), "corrente do saco": Rect2i(334, 33, 3, 150), "cartaz da liga (vencido 42x58)": Rect2i(394, 54, 42, 58),
			"tubo de luz": Rect2i(399, 34, 48, 10), "porta": Rect2i(401, 116, 60, 104)},
		"center": {"recorte do Gato Preto": Rect2i(340, 60, 23, 28), "capuz no prego": hood, "relógio de rounds": Rect2i(370, 74, 28, 26),
			"espelho": Rect2i(268, 50, 68, 98), "corrente do saco": Rect2i(334, 33, 3, 150), "porta de vidro": Rect2i(399, 106, 66, 114),
			"tubo de luz": Rect2i(372, 40, 44, 9)},
	}
	var zone := Rect2i(273, 150, 98, 142)
	var bgs := {"garage": "garage_bg", "gym": "gym_bg", "center": "center_bg"}
	for loc in SPOTS:
		var bg := load_png(ROOT + str(spr(bgs[loc]).file).replace("res://", ""))
		for id in IDS:
			var p: Array = SPOTS[loc][id]
			var r := Rect2i(int(p[0]), int(p[1]), CLIP.x, CLIP.y)
			for k in busy[loc]:
				if r.intersects(busy[loc][k]):
					problems += 1
					CHECKS.append("PROBLEMA: recorte %s em %s encosta em %s %s" % [id, loc, k, str(busy[loc][k])])
			if r.intersects(zone):
				problems += 1
				CHECKS.append("PROBLEMA: recorte %s em %s na zona do alvo" % [id, loc])
			if r.intersects(Rect2i(0, 18, 128, 115)) or r.end.x > 506 or r.position.y < 30:
				problems += 1
				CHECKS.append("PROBLEMA: recorte %s em %s embaixo de painel/teto" % [id, loc])
			# o que o manifest posiciona (pos/positions), menos fundos, arena, luta e minigame
			for sid in MAN.sprites:
				var e: Dictionary = MAN.sprites[sid]
				var s := str(sid)
				if not e.has("frame_size") or s.ends_with("_bg") or s.begins_with("arena") or s.begins_with("fight") or s.begins_with("ronda_") \
						or s.begins_with("minigame") or s.begins_with("wall_clipping_alley") or s == "gym_half_dark":
					continue
				var ps := []
				if e.has("pos") and e.pos is Array and e.pos.size() == 2:
					ps.append(e.pos)
				if e.has("positions") and e.positions is Dictionary:
					for kk in e.positions:
						var pp = e.positions[kk]
						if pp is Array and pp.size() == 2 and (pp[0] is float or pp[0] is int):
							ps.append(pp)
				var pv: Array = e.get("pivot", [0, 0])
				for pp in ps:
					var rr := Rect2i(int(pp[0]) - int(pv[0]), int(pp[1]) - int(pv[1]), int(e.frame_size[0]), int(e.frame_size[1]))
					if rr.size.x < 400 and rr.intersects(r):
						var where := s
						# só conta o que é do mesmo local (sufixo _gym/_center ou o ponto do local)
						var tag := "garage"
						if s.contains("_gym") or s.begins_with("gym"):
							tag = "gym"
						elif s.contains("_center") or s.begins_with("center"):
							tag = "center"
						if tag != loc and not (loc == "garage" and tag == "garage"):
							continue
						if s == "wall_school_symbol" and loc != "garage":
							continue
						problems += 1
						CHECKS.append("PROBLEMA: recorte %s em %s encosta em %s %s" % [id, loc, where, str(rr)])
			var hist := {}
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					var n := color_name(bg.get_pixel(x, y))
					hist[n] = hist.get(n, 0) + 1
			CHECKS.append("parede embaixo do recorte %s em %s: %s" % [id, loc, str(hist)])
	CHECKS.append("CONFERÊNCIA DOS RECORTES DOS BANDIDOS: %d problema(s)" % problems)

# ================================================================== prancha
func blend(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func scaled(src: Image, k: int) -> Image:
	var s: Image = src.duplicate()
	s.resize(src.get_width() * k, src.get_height() * k, Image.INTERPOLATE_NEAREST)
	return s

func label(img: Image, s: String, x: int, y: int, c := "white") -> void:
	L.text(img, s, x, y, c, 1, "ink")

## A sala: a captura do ui_audit com a sala cheia (se veio em --caps) ou o fundo puro; por cima o recorte do Gato Preto
## (nível 3), o capuz no prego e os recortes dos bandidos que já foram vencidos (n = 0..3).
func room(loc: String, n: int) -> Image:
	var caps := {"garage": "f6d2_garagem_cheia.png", "gym": "f6d2_academia_cheia.png", "center": "f8a2_centro_cheia_boxe.png"}
	var im: Image
	var p: String = CAPS + caps[loc]
	if CAPS != "" and FileAccess.file_exists(p):
		im = load_png(p)
		if im.get_width() == 1280:
			im.resize(640, 360, Image.INTERPOLATE_NEAREST)
	else:
		im = load_png(ROOT + str(spr({"garage": "garage_bg", "gym": "gym_bg", "center": "center_bg"}[loc]).file).replace("res://", ""))
	var gp := "wall_clipping_black_cat_l3" if loc == "garage" else "wall_clipping_black_cat_gym_l3"
	blend(im, frame_of(gp), 304 if loc == "garage" else 340, 100 if loc == "garage" else 60)
	var hood := "hood_on_nail" if loc == "garage" else "hood_on_nail_gym"
	blend(im, frame_of(hood), HOOD_SPOT.x - HOOD_PIVOT.x, HOOD_SPOT.y - HOOD_PIVOT.y)
	for i in n:
		var id: String = IDS[i]
		var p2: Array = SPOTS[loc][id]
		blend(im, CLIPS["garage" if loc == "garage" else "gym"][id], int(p2[0]), int(p2[1]))
	return im

func prancha() -> void:
	var locs := ["garage", "gym", "center"]
	var nomes := {"garage": "GARAGEM", "gym": "ACADEMIA", "center": "CENTRO RAÍZES"}
	var crop := Rect2i(256, 28, 160, 128)
	var K := 3
	var W := 12 + 3 * (crop.size.x * K + 12)
	var H := 4000
	var b: Image = L.blank(W, H)
	b.fill(L.col("d1"))
	var y := 8
	L.text(b, "RONDA 2A1 - B1: RECORTE DE CADA BANDIDO VENCIDO NA PAREDE (3 LOCAIS)", 12, y, "y1", 3)
	y += 30
	label(b, "1 RECORTE POR BANDIDO VENCIDO (15X18), AO LADO DO RECORTE DO GATO PRETO E DO CAPUZ NO PREGO. ORDEM: ESTEPE, BICICLETA, PORTÃO (O ÚLTIMO POR CIMA).", 12, y, "g3")
	y += 12
	label(b, "SEM TEXTO EM 1X: A FOTO (O QUE ELE LARGOU), 2 BARRAS DE MANCHETE E O CARIMBO DO GATO. O HOVER MOSTRA A MANCHETE DO MAIS RECENTE (ALLEY_<ID>_CLIPPING).", 12, y, "g3")
	y += 18
	# as peças
	label(b, "AS PEÇAS: GARAGEM (CREME) E ACADEMIA/CENTRO (BRANCO), 1X E 6X", 12, y, "y1")
	y += 14
	var x := 12
	for k in ["garage", "gym"]:
		for id in IDS:
			var c: Image = CLIPS[k][id]
			var bgc: Image = L.blank(CLIP.x * 6 + 8, CLIP.y * 6 + 30)
			bgc.fill(L.col("g0" if k == "garage" else "g2"))
			blend(bgc, c, 4, 4)
			blend(bgc, scaled(c, 6), 4, 26)
			blend(b, bgc, x, y)
			label(b, id.to_upper(), x + 24, y + 6, "cream")
			x += bgc.get_width() + 10
	y += CLIP.y * 6 + 40
	# os 3 locais com 0..3 recortes (3x), e a sala inteira 1x com os 3
	label(b, "OS 3 LOCAIS (3X, TRECHO X %d..%d, Y %d..%d): 1, 2 E 3 BANDIDOS VENCIDOS" % [crop.position.x, crop.end.x, crop.position.y, crop.end.y], 12, y, "y1")
	y += 14
	for n in [1, 2, 3]:
		for i in 3:
			var im := room(locs[i], n)
			var xx := 12 + i * (crop.size.x * K + 12)
			blend(b, scaled(im.get_region(crop), K), xx, y)
			label(b, "%s - %d VENCIDO%s" % [nomes[locs[i]], n, "S" if n > 1 else ""], xx + 4, y + 4, "y1")
		y += crop.size.y * K + 10
	label(b, "A SALA INTEIRA EM 1X COM OS 3 RECORTES (%s)" % ("CAPTURAS DO UI_AUDIT COM A SALA CHEIA" if CAPS != "" else "SÓ O FUNDO"), 12, y, "y1")
	y += 14
	for i in 3:
		var im := room(locs[i], 3)
		var xx := 12 + i * (crop.size.x * K + 12)
		var part := im.get_region(Rect2i(0, 0, mini(640, crop.size.x * K), 360))
		blend(b, part, xx, y)
	y += 360 + 10
	label(b, "PLACEHOLDER POR CÓDIGO. UM PIXEL ARTIST FARIA A FOTO COM MAIS VIDA E O PAPEL LEVEMENTE TORTO (AQUI É RETO PARA CABER EM 15X18 SEM SERRILHADO).", 12, y, "g3")
	y += 16
	b.get_region(Rect2i(0, 0, W, y)).save_png(ROOT + "docs/arte/mockups/ronda2a_recortes_locais.png")
	# a sala inteira em 2x de cada local (para o dono ver o tamanho real)
	for i in 3:
		scaled(room(locs[i], 3), 2).save_png(ROOT + "docs/arte/mockups/ronda2a_recortes_%s_x2.png" % ["garagem", "academia", "centro"][i])
