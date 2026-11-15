extends SceneTree
## Fase 6b2 (Diretor de Arte) - escolha do mentor_2_spot (o último que passou o posto, parado, sem luvas, sem falar).
## PLACEHOLDER de conferência: monta a garagem na situação mais cheia (equipe cheia, 4 caixas, porta, Osmar, John no
## caixote, discípulo no saco) com o 2º mentor nas poses que o discípulo em camadas JÁ TEM (disciple_stand_bare/_left).
## Não gera sprite novo. Saída:
##   docs/arte/mockups/fase6b2_mentor2_garagem_x1.png / _x2.png        jogo normal (porta fechada, foco no saco)
##   docs/arte/mockups/fase6b2_mentor2_conferencia_x2.png              porta emperrada + luz, zonas, caminho, balões
##   docs/arte/mockups/fase6b2_mentor2_candidatos_x2.png               A (escolhido) x B (canto direito), recorte
## Rodar de uma pasta temporária com project.godot vazio:
##   Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_mockup_fase6b2_mentor2.gd -- [--final] [--manifest]
## Sem --final grava em <tmp>/out/mock. --manifest grava SÓ layout.mentor_2_spot e by_data_id.mentor_2_spot (relê o arquivo).

const ROOT := "E:/Fightclicker/"
var MOCK := ""
var L
var M := {}

const GPIV := Vector2i(22, 67)
const P_M2 := Vector2i(150, 262)        # ESCOLHIDO: pés do 2º mentor, encostado na parede esquerda, de pé, olhando o saco
const P_ALT := Vector2i(490, 250)       # alternativa do escopo (canto direito), só para comparar
const P_MENTOR := Vector2i(254, 252)
const P_COACH := Vector2i(196, 236)
const P_FIGHTER := Vector2i(303, 272)
const P_DOOR := Vector2i(423, 221)
const TARGET := [281, 362]
const NO_COVER := Rect2i(310, 180, 52, 94)
const USABLE := Rect2i(132, 22, 507 - 132, 285 - 22)
const CREW := ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2"]
# visual do 2º mentor no mockup (qualquer combinação vale; esta difere do discípulo atual de propósito)
const M2_LOOK := ["skin_4", "black", "blue"]
const CUR_LOOK := ["skin_1", "copper", "purple"]

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
	var n := img.get_width() / fw
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

func recolor_map(look: Array) -> Dictionary:
	var pb: Dictionary = M.by_data_id.disciple_palette
	var m := {}
	var fields := ["skin", "hair_color", "shorts_color"]
	for i in 3:
		var keys: Dictionary = pb["keys"][fields[i]]
		var ramp := {}
		for o in pb.options[fields[i]]:
			if o.id == look[i]:
				ramp = o.ramp
		for slot in keys:
			if ramp.has(slot):
				m[(keys[slot] as String).substr(1).to_lower()] = Color.html(ramp[slot])
	return m

## body -> head_short -> body pela front_mask, troca de cor-chave (igual ao jogo)
func layered(id: String, q: int, look: Array) -> Image:
	var e := spr(id)
	var fw := int(e.frame_size[0])
	var fh := int(e.frame_size[1])
	var lay: Dictionary = e.layers
	var body := frame_file(res_abs(lay.body), fw, fh, q)
	var head := frame_file(res_abs(lay.head.short), fw, fh, q)
	var mask := frame_file(res_abs(lay.front_mask), fw, fh, q)
	var rc := recolor_map(look)
	var out := Image.create_empty(fw, fh, false, Image.FORMAT_RGBA8)
	for y in fh:
		for x in fw:
			var c := body.get_pixel(x, y)
			var hc := head.get_pixel(x, y)
			if hc.a > 0.0:
				c = hc
			if mask.get_pixel(x, y).a > 0.0:
				c = body.get_pixel(x, y)
			if c.a > 0.0:
				var hx := c.to_html(false).to_lower()
				if rc.has(hx):
					c = rc[hx]
			out.set_pixel(x, y, c)
	return out

func opaque_rect(img: Image, at: Vector2i) -> Rect2i:
	var r := img.get_used_rect()
	return Rect2i(r.position + at, r.size)

# ---------------------------------------------------------------- sala
## item = {y, img, at (canto sup. esq.), shadow (pés) ou null, name}
func it_spr(name: String, id: String, q: int, pos: Vector2i, sort_y: float, shadow := false) -> Dictionary:
	var e := spr(id)
	var at := pos - Vector2i(int(e.pivot[0]), int(e.pivot[1]))
	return {"y": sort_y, "img": frame_of(id, q), "at": at, "shadow": pos + Vector2i(0, -1) if shadow else null, "name": name}

func it_img(name: String, img: Image, pos: Vector2i, piv := GPIV, shadow := true, sort_y := -1.0) -> Dictionary:
	return {"y": float(pos.y) if sort_y < 0 else sort_y, "img": img, "at": pos - piv, "shadow": pos + Vector2i(0, -1) if shadow else null, "name": name}

func room(door_open: bool, items: Array) -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	blend(im, frame_of("garage_bg"), 128, 18)
	for id in ["wall_notice_debt", "wall_form_blank", "wall_photo_old"]:
		var e := spr(id)
		blend(im, frame_of(id), int(e.pos[0]), int(e.pos[1]))
	var le := spr("lamp")
	blend(im, frame_of("lamp"), 300 - int(le.pivot[0]), 32 - int(le.pivot[1]))
	if door_open:
		blend(im, frame_of("garage_door_outside"), 382, 168)
		blend(im, frame_of("garage_daylight", 2), 308, 220)
		blend(im, frame_of("garage_door_shadow", 1), 374, 214)
	var t: Image = frame_of("bag_chain_tile")
	var y := 33
	while y < 183:
		blend(im, t.get_region(Rect2i(0, 0, t.get_width(), mini(6, 183 - y))), 335, y)
		y += 6
	var all := items.duplicate()
	all.append({"y": 222.0, "img": frame_of("garage_door", 8 if door_open else 0), "at": Vector2i(381, 154), "shadow": null, "name": "porta"})
	all.sort_custom(func(a, b): return a.y < b.y)
	var fs := spr("floor_shadow")
	for it in all:
		if it.shadow != null:
			blend(im, frame_of("floor_shadow"), it.shadow.x - int(fs.pivot[0]), it.shadow.y - int(fs.pivot[1]))
		blend(im, it.img, it.at.x, it.at.y)
	return im

func cast(m2: Vector2i, m2_id: String, door_open: bool) -> Array:
	var items := []
	items.append(it_spr("saco", "bag_l0_idle", 0, Vector2i(336, 183), 253.0))
	items.append({"y": float(P_MENTOR.y - 2), "img": frame_of("garage_crate"), "at": P_MENTOR + Vector2i(-16, -20), "shadow": null, "name": "caixote"})
	items.append(it_img("john", frame_of("john_sit_rest", 0), P_MENTOR))
	items.append(it_img("osmar", frame_of("coach_idle", 0), P_COACH))
	items.append(it_img("lutador", layered("fighter_idle_disc_layered", 0, CUR_LOOK), P_FIGHTER))
	for id in CREW:
		var e := spr(id)
		items.append(it_spr(id, id, 0, Vector2i(int(e.pos[0]), int(e.pos[1])), float(e.pos[1]), true))
	var bs: Dictionary = M.layout.box_slots
	for k in ["treadmill", "jump_rope", "art", "glove"]:
		var p := Vector2i(int(bs[k][0]), int(bs[k][1]))
		items.append(it_spr("caixa_" + k, "box_big" if k == "treadmill" else "box_small", 0, p, float(p.y)))
	items.append(it_img("mentor2", layered(m2_id, 0, M2_LOOK), m2))
	if door_open:
		# quem entra pela porta (cena): na soleira, contra a luz
		var d := layered("disciple_stand_bare_left", 0, CUR_LOOK)
		L.shade_rect(d, 0, 0, d.get_width(), d.get_height(), -1)
		items.append(it_img("entrando", d, P_DOOR, GPIV, false))
	return items

# ---------------------------------------------------------------- zonas
func dashed(img: Image, r: Rect2i, c: String) -> void:
	for x in range(r.position.x, r.end.x):
		if x % 4 < 2:
			L.P(img, x, r.position.y, c)
			L.P(img, x, r.end.y - 1, c)
	for y in range(r.position.y, r.end.y):
		if y % 4 < 2:
			L.P(img, r.position.x, y, c)
			L.P(img, r.end.x - 1, y, c)

## retângulo do balão "em cima" (rule da speech_bubble), com plaquinha (6 acima) e rabicho (4 abaixo)
func balloon_rect(head: Vector2i, w := 154, h := 26) -> Rect2i:
	var tip_y := head.y - 6
	var by := tip_y - 3 - h
	var bx := clampi(head.x - w / 2, USABLE.position.x, USABLE.end.x - w)
	return Rect2i(bx, by - 6, w, h + 10)

func head_box(id: String, pos: Vector2i, q := 0) -> Rect2i:
	var e := spr(id)
	if e.has("anchors"):
		var hb: Array = e.anchors[q].head_box
		return Rect2i(pos.x - int(e.pivot[0]) + int(hb[0]), pos.y - int(e.pivot[1]) + int(hb[1]), int(hb[2]), int(hb[3]))
	var ha: Array = e.head_anchor
	return Rect2i(pos.x + int(ha[0]) - 6, pos.y + int(ha[1]), 13, 13)

func label(img: Image, s: String, x: int, y: int, c := "white") -> void:
	L.text(img, s, x, y, c, 1, "ink")

## caminho da porta até o saco: faixa de 24 px (largura do corpo andando) de (423,221) a (303,272)
func path_hits(r: Rect2i) -> bool:
	var a := Vector2(P_DOOR)
	var b := Vector2(P_FIGHTER)
	for i in 41:
		var p := a.lerp(b, i / 40.0)
		var body := Rect2i(int(p.x) - 12, int(p.y) - 66, 24, 66)
		if body.intersects(r):
			return true
	return false

func draw_path(img: Image) -> void:
	var a := Vector2(P_DOOR)
	var b := Vector2(P_FIGHTER)
	for i in 121:
		var p := a.lerp(b, i / 120.0)
		for s in [-12, 12]:
			if i % 4 < 2:
				L.P(img, int(p.x) + s, int(p.y), "gr3")
		L.P(img, int(p.x), int(p.y), "gr3")

func report(m2: Vector2i, m2_id: String, tag: String) -> Array:
	var probs := []
	var m2img := layered(m2_id, 0, M2_LOOK)
	var r := Rect2i()
	for q in 4:
		var rq := opaque_rect(layered(m2_id, q, M2_LOOK), m2 - GPIV)
		r = rq if q == 0 else r.merge(rq)
	print("[%s] mentor2 %s ocupa %s" % [tag, str(m2), str(r)])
	if r.end.x > TARGET[0] - 8 and r.position.x < TARGET[1] + 8:
		probs.append("faixa do alvo")
	if r.intersects(NO_COVER):
		probs.append("no_cover")
	if path_hits(r):
		probs.append("caminho porta-saco")
	# vizinhos (corpo opaco)
	var others := {"osmar": ["coach_idle", P_COACH], "john": ["john_sit_rest", P_MENTOR]}
	for id in CREW:
		others[id] = [id, Vector2i(int(spr(id).pos[0]), int(spr(id).pos[1]))]
	for k in others:
		var e := spr(others[k][0])
		var pv := Vector2i(int(e.pivot[0]), int(e.pivot[1]))
		var ro := opaque_rect(frame_of(others[k][0]), others[k][1] - pv)
		if ro.intersects(r):
			var inter := ro.intersection(r)
			print("   encosta em %s: %s (%d px2)" % [k, str(inter), inter.get_area()])
			if inter.get_area() > 20:
				probs.append("cobre/é coberto por " + k)
	var bs: Dictionary = M.layout.box_slots
	for k in ["treadmill", "jump_rope", "art", "glove"]:
		var e := spr("box_big" if k == "treadmill" else "box_small")
		var cr: Array = e.click_rect
		var rb := Rect2i(int(bs[k][0]) + int(cr[0]), int(bs[k][1]) + int(cr[1]), int(cr[2]), int(cr[3]))
		if rb.intersects(r):
			probs.append("caixa " + k)
	# balões de quem fala sobre a cabeça do mentor2, e balão hipotético dele sobre os outros
	var hb := head_box(m2_id, m2)
	print("   cabeça do mentor2: %s" % str(hb))
	var speakers := {"osmar": P_COACH + Vector2i(1, -63), "john_sentado": P_MENTOR + Vector2i(1, -56),
		"john_de_pe": P_MENTOR + Vector2i(1, -65), "discipulo_saco": Vector2i(303, 210)}
	for k in speakers:
		var br := balloon_rect(speakers[k])
		if br.intersects(hb):
			probs.append("balão de %s cobre a cabeça" % k)
		print("   balão %s %s" % [k, str(br)])
	print("   => %s" % ("OK" if probs.is_empty() else ", ".join(probs)))
	return probs

# ---------------------------------------------------------------- mockups
func mockups() -> void:
	DirAccess.make_dir_recursive_absolute(MOCK)
	var crop := Rect2i(128, 18, 384, 272)
	# 1) jogo normal
	var game := room(false, cast(P_M2, "disciple_stand_bare", false))
	game.save_png(MOCK + "fase6b2_mentor2_garagem_x1.png")
	scaled(game.get_region(crop), 2).save_png(MOCK + "fase6b2_mentor2_garagem_x2.png")
	# 2) conferência: porta emperrada + luz + quem entra, zonas
	var chk := room(true, cast(P_M2, "disciple_stand_bare", true))
	dashed(chk, Rect2i(TARGET[0] - 8, 150, TARGET[1] - TARGET[0] + 17, 139), "r2")
	dashed(chk, NO_COVER, "r1")
	draw_path(chk)
	var bs: Dictionary = M.layout.box_slots
	for k in ["treadmill", "jump_rope", "art", "glove"]:
		var e := spr("box_big" if k == "treadmill" else "box_small")
		var cr: Array = e.click_rect
		dashed(chk, Rect2i(int(bs[k][0]) + int(cr[0]), int(bs[k][1]) + int(cr[1]), int(cr[2]), int(cr[3])), "y1")
	var r := Rect2i()
	for q in 4:
		var rq := opaque_rect(layered("disciple_stand_bare", q, M2_LOOK), P_M2 - GPIV)
		r = rq if q == 0 else r.merge(rq)
	dashed(chk, r.grow(1), "b3")
	dashed(chk, balloon_rect(P_COACH + Vector2i(1, -63)), "cream")
	dashed(chk, head_box("disciple_stand_bare", P_M2), "white")
	var big := scaled(chk.get_region(crop), 2)
	label(big, "VERMELHO: ALVO+FOLGA / NO_COVER   VERDE: CAMINHO PORTA-SACO   AMARELO: CAIXAS", 6, 4)
	label(big, "AZUL: 2O MENTOR (150,262)   CREME: BALAO DO OSMAR   BRANCO: CABECA", 6, 14)
	big.save_png(MOCK + "fase6b2_mentor2_conferencia_x2.png")
	# 3) candidatos lado a lado (recortes 2x)
	var a := room(false, cast(P_M2, "disciple_stand_bare", false))
	var b := room(false, cast(P_ALT, "disciple_stand_bare_left", false))
	var ra := Rect2i(128, 150, 200, 140)
	var rb := Rect2i(312, 150, 200, 140)
	var sheet: Image = L.blank(ra.size.x * 4 + 30, ra.size.y * 2 + 30)
	L.R(sheet, 0, 0, sheet.get_width(), sheet.get_height(), "d1")
	blend(sheet, scaled(a.get_region(ra), 2), 10, 22)
	blend(sheet, scaled(b.get_region(rb), 2), 20 + ra.size.x * 2, 22)
	label(sheet, "A (150,262) ESCOLHIDO: PAREDE ESQUERDA, DE PE", 12, 6)
	label(sheet, "B (490,250) CANTO DIREITO: ATRAS DO VIZINHO 3 E DO TIO 1", 22 + ra.size.x * 2, 6)
	sheet.save_png(MOCK + "fase6b2_mentor2_candidatos_x2.png")

# ---------------------------------------------------------------- manifest
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

func write_manifest() -> void:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível na hora de gravar; nada foi escrito")
		return
	var doc: Dictionary = intify(j.data)
	var r := Rect2i()
	for q in 4:
		var rq := opaque_rect(layered("disciple_stand_bare", q, M2_LOOK), P_M2 - GPIV)
		r = rq if q == 0 else r.merge(rq)
	var lay: Dictionary = doc.get("layout", {})
	# layout.<nome> tem de ser [x, y]: é assim que cena_dados.ponto() lê pontos nomeados (como mentor_spot).
	lay["mentor_2_spot"] = [P_M2.x, P_M2.y]
	lay["mentor_2_spot_info"] = {"pose": "stand_bare", "sprite": "disciple_stand_bare", "facing": "direita",
		"head_anchor": [1, -65], "head_anchor_abs": [P_M2.x + 1, P_M2.y - 65], "sort_y": P_M2.y, "location": "garage",
		"occupies": [r.position.x, r.position.y, r.size.x, r.size.y],
		"_nota": "Ponto em layout.mentor_2_spot ([x, y], formato dos pontos nomeados). Detalhes completos: by_data_id.mentor_2_spot."}
	doc["layout"] = lay
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["mentor_2_spot"] = {"pos": [P_M2.x, P_M2.y], "location": "garage", "from_campaign": 3,
		"pose": "stand_bare", "sprite": "disciple_stand_bare", "facing": "direita", "mirror": false,
		"head_anchor": [1, -65], "head_anchor_abs": [P_M2.x + 1, P_M2.y - 65],
		"layer": "sorted", "sort_y": P_M2.y, "floor_shadow": true, "light": "nenhuma (igual às folhas do discípulo)",
		"look": "visual gravado do lutador (palette_swap disciple_palette, corte da cabeça dele); sem luvas, sem faixa na mão",
		"anim": {"idle": "disciple_stand_bare quadros 0-3 a 4 fps (respira 1 px)", "olha_o_saco": "nenhuma folha nova: ele já está virado para o saco; o olhar é o próprio facing"},
		"occupies": [r.position.x, r.position.y, r.size.x, r.size.y],
		"clickable": false, "speaks": false,
		"checked": {"alvo_folga": "x 273..370: livre (ocupa até x %d)" % (r.end.x - 1), "no_cover": "livre",
			"caminho_porta_saco": "livre (faixa de 24 px de (423,221) a (303,272))",
			"vizinho_1": "não se cobrem: ele ocupa até x 162 e o vizinho 1 (176,284) começa em x 163 (em (152,262) o punho do vizinho encostava na coxa)",
			"baloes": "balão do Osmar (132,132,154,36), do John sentado/de pé e do discípulo no saco não chegam na cabeça dele (y %d..%d)" % [P_M2.y - 66, P_M2.y - 52]},
		"note": "Fase 6b2 (Diretor de Arte): o último que passou o posto, da Carreira 3 em diante, enquanto o John está no caixote. De pé, encostado na parede esquerda, atrás do vizinho 1 e à esquerda do Osmar, olhando o saco. Usa a folha que o discípulo em camadas já tem (disciple_stand_bare, virado à direita): nenhuma arte nova. Escolhido em vez de (490,250): lá ficaria atrás do vizinho 3 e do tio 1 e colado na caixa da esteira. Mockup: docs/arte/mockups/fase6b2_mentor2_*.png; texto: direcao-visual.md §24."}
	doc["by_data_id"] = bd
	var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()
	print("manifest: layout.mentor_2_spot e by_data_id.mentor_2_spot gravados")

func _init() -> void:
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	var args := OS.get_cmdline_user_args()
	var here: String = ProjectSettings.globalize_path("res://")
	MOCK = (ROOT + "docs/arte/mockups/") if args.has("--final") else (here.trim_suffix("/") + "/out/mock/")
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível")
		quit()
		return
	M = j.data
	var pa := report(P_M2, "disciple_stand_bare", "A")
	report(P_ALT, "disciple_stand_bare_left", "B")
	mockups()
	if args.has("--manifest"):
		if pa.is_empty():
			write_manifest()
		else:
			push_error("A tem problema; manifest não gravado")
	print("ok fase 6b2 mentor2")
	quit()
