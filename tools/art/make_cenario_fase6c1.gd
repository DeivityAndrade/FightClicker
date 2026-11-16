extends SceneTree
## Fase 6c1 (Diretor de Arte) - PLACEHOLDER gerado por código. Cenário da chegada à academia e da saída do John
## (pedido: docs/cutscenes/pedidos-6c1.md §2). Gente é do Artista de Personagens (make_sprites_fase6c1.gd); os
## mockups usam as folhas dele (docs/arte/manifest-6c1-personagens.json, lido só em memória) e, onde faltar, dublê.
##   gym/gym_half_dark (384x272)          metade direita 1 passo mais escura (tubo da direita apagado), furo na porta
##   gym/gym_door (60x108, 6 quadros)     porta da rua: 0-2 fechada/meio/aberta com a rua no vão; 3-5 = o mesmo no escuro
##   gym/gym_daylight (146x70, 2)         luz do dia no piso de borracha (0 = porta aberta, 1 = meio aberta)
##   gym/wall_photo_old_gym (18x21, 2)    a foto antiga na academia: 0 = reta, 1 = torta (igual à da garagem)
##   characters/john_duffel (18x11)       bolsa de lona do John no chão (= docs/arte/mockups/fase6c1_bolsa_ref.png)
##   garage/garage_crate_gym (26x19)      o caixote com a luz dos tubos (regra do sufixo _gym)
##   docs/arte/mockups/fase6c1_*.png      academia cheia, conferência dos pontos, peças, quadros A1/A3/A6/A7
## Modos de estudo: -- --busca [--sem-m2] [--min] (pontos livres para o Osmar), --equipe (pontos da equipe sem
## sobreposição, com volta; grava mockups/fase6c1_academia_espaco_livre_x2.png), --capacidade [--sem-caixas] [--sem-saida].
## Confere os 4 pontos gym_* (faixa do alvo com folga, no_cover, caminho da porta ao centro, caixas, gente, aparelhos,
## balões) e só grava o manifest se não houver problema.
## Rodar de uma pasta temporária com project.godot vazio:
##   Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_cenario_fase6c1.gd -- [--final]
## Sem --final grava em <tmp>/out (prévia). Com --final grava no projeto e mexe no manifest SÓ nas chaves desta fase
## (relê o arquivo na hora de gravar). As folhas do Artista entram com tools/art/merge_manifest_6c1.gd.

var ROOT := ""
const RES := "res://assets/sprites/"
var OUT := ""
var MOCK := ""
var FINAL := false
var L
var OLD := {}
var M := {}
var F := {}
var BG: Image

const ROOM := Rect2i(128, 18, 384, 272)
const GPIV := Vector2i(22, 67)
const TUBES := [Vector2i(218, 34), Vector2i(422, 34)]
const DARK_X0 := 300           # começa o dither
const DARK_X1 := 340           # escuro cheio daqui em diante
# porta da rua pintada no gym_bg: batente x 401..454, y 117..220; vão x 404..451, y 120..219
const VAO := Rect2i(404, 120, 48, 100)
const DOOR_TL := Vector2i(401, 116)
const DOOR_SIZE := Vector2i(60, 108)       # x 401..460, y 116..223: batente + folha aberta de perfil
const DAY_TL := Vector2i(330, 220)
const DAY_SIZE := Vector2i(146, 70)
const PHOTO_SIZE := Vector2i(18, 21)
const DUFFEL_TL := Vector2i(268, 242)
const CRATE_OFF := Vector2i(-16, -20)
# ---- pontos da academia (direcao-visual.md §25)
const P_COACH := Vector2i(196, 236)
const P_SEAT := Vector2i(254, 252)
const P_STAND := Vector2i(150, 262)
const P_PHOTO := Vector2i(212, 158)
# ---- referências
const P_FIGHTER := Vector2i(303, 272)
const P_WAIT := Vector2i(352, 262)
const TARGET := [281, 362]
const FOLGA := 8
const NO_COVER := Rect2i(310, 180, 52, 94)
const USABLE := Rect2i(132, 22, 507 - 132, 285 - 22)
const CREW := ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2", "coach_1"]
const M2_LOOK := ["skin_4", "black", "blue"]
const CUR_LOOK := ["skin_1", "copper", "purple"]
var COACH_ID := "coach_idle"

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

func spr(id: String) -> Dictionary:
	if M.has(id):
		return M[id]
	return OLD.get("sprites", {}).get(id, {})

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

func frame_of(id: String, i := 0) -> Image:
	if F.has(id):
		return F[id][clampi(i, 0, F[id].size() - 1)]
	var e := spr(id)
	return frame_file(res_abs(str(e.file)), int(e.frame_size[0]), int(e.frame_size[1]), i)

func pivot_of(id: String) -> Vector2i:
	var e := spr(id)
	return Vector2i(int(e.pivot[0]), int(e.pivot[1])) if e.has("pivot") else GPIV

func blend(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func scaled(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func bg_px(x: int, y: int) -> Color:
	return BG.get_pixel(x - ROOM.position.x, y - ROOM.position.y)

func bayer(x: int, y: int) -> float:
	return (float(L.BAYER[y & 3][x & 3]) + 0.5) / 16.0

## luz dos tubos (a mesma conta do make_sprites_fase5.gd, gym_step)
func gym_step(x: int, y: int) -> int:
	var best := -9.0
	for t in TUBES:
		var d := Vector2(x - t.x, (y - t.y - 30) * 0.8).length() / 260.0
		best = maxf(best, 0.95 - d * 1.9)
	best -= clampf(float(y - 250) / 120.0, 0.0, 0.35)
	var base := floorf(best)
	var fr := clampf((best - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
	var b: float = (L.BAYER[y % 4][x % 4] + 0.5) / 16.0
	return clampi(int(base) + (1 if fr > b else 0), -2, 1)

func gym_lit(img: Image, topleft: Vector2i) -> Image:
	var c: Image = img.duplicate()
	for y in c.get_height():
		for x in c.get_width():
			var p := c.get_pixel(x, y)
			if p.a == 0.0:
				continue
			var st := mini(gym_step(x + topleft.x, y + topleft.y), 0)
			if st != 0:
				c.set_pixel(x, y, L.shade(p, st))
	return c

# ================================================================ metade escura
func in_door(x: int, y: int) -> bool:
	return Rect2i(DOOR_TL, DOOR_SIZE).has_point(Vector2i(x, y))

func half_dark() -> Image:
	var img: Image = L.blank(ROOM.size.x, ROOM.size.y)
	for ly in ROOM.size.y:
		for lx in ROOM.size.x:
			var x := lx + ROOM.position.x
			var y := ly + ROOM.position.y
			if x < DARK_X0 or in_door(x, y):
				continue
			if x < DARK_X1:
				var t := float(x - DARK_X0 + 1) / float(DARK_X1 - DARK_X0 + 1)
				if bayer(x, y) >= t:
					continue
			img.set_pixel(lx, ly, L.shade(BG.get_pixel(lx, ly), -1))
	return img

# ================================================================ porta da rua
## a rua vista pelo vão (48x100, tela y 120..219): a mesma rua da garage_door_outside na mesma altura de tela
## (muro em y 198, calçada até 219), céu branco em cima e uma fachada clara do outro lado da rua
func street() -> Image:
	var w := VAO.size.x
	var img: Image = L.blank(w, VAO.size.y)
	L.R(img, 0, 0, w, VAO.size.y, "white")
	for ly in VAO.size.y:
		var y := ly + VAO.position.y
		for x in w:
			var sx := x + VAO.position.x
			if y >= 150 and y < 198 and sx >= 412 and sx <= 446:
				if y == 150 or (sx + y) % 2 == 0:
					img.set_pixel(x, ly, L.col("cream"))
			var t := clampf(float(y - 182) / 10.0, 0.0, 1.0)
			if y >= 182 and bayer(sx, y) < t:
				img.set_pixel(x, ly, L.col("y2"))
	L.R(img, 420 - VAO.position.x, 160 - VAO.position.y, 10, 12, "g3")
	L.R(img, 421 - VAO.position.x, 161 - VAO.position.y, 8, 10, "cream")
	L.R(img, 425 - VAO.position.x, 161 - VAO.position.y, 1, 10, "g3")
	L.R(img, 0, 198 - VAO.position.y, w, 1, "cream")
	for x in w:
		if (x + VAO.position.x) % 2 == 0:
			L.P(img, x, 199 - VAO.position.y, "cream")
		if (x + VAO.position.x + 211) % 2 == 0:
			L.P(img, x, 211 - VAO.position.y, "cream")
	L.R(img, 0, 212 - VAO.position.y, w, 8, "cream")
	L.R(img, 0, 213 - VAO.position.y, w, 1, "g3")
	for x in range(5, w, 16):
		L.R(img, x, 214 - VAO.position.y, 1, 6, "g3")
	return img

var door_street_mask := []

func door_frames() -> Array:
	var st := street()
	var base: Image = BG.get_region(Rect2i(DOOR_TL - ROOM.position, DOOR_SIZE))
	var out := []
	door_street_mask = []
	# 0 = fechada (recorte do fundo)
	out.append(base.duplicate())
	door_street_mask.append({})
	# 1 = meio aberta (45 graus): a mesma face pintada apertada em x 418..451, a ponta livre mais alta e mais baixa
	var f1: Image = base.duplicate()
	var m1 := {}
	var face: Image = BG.get_region(Rect2i(VAO.position - ROOM.position, VAO.size))
	for x in range(VAO.position.x, VAO.end.x):
		for y in range(VAO.position.y, VAO.end.y):
			f1.set_pixel(x - DOOR_TL.x, y - DOOR_TL.y, st.get_pixel(x - VAO.position.x, y - VAO.position.y))
			m1[Vector2i(x - DOOR_TL.x, y - DOOR_TL.y)] = true
	var fx0 := 418
	var fx1 := 451
	for x in range(fx0, fx1 + 1):
		var u := float(x - fx0) / float(fx1 - fx0)
		var top := int(round(lerpf(117.0, 120.0, u)))
		var bot := int(round(lerpf(222.0, 219.0, u)))
		var sx := int(round(u * float(VAO.size.x - 1)))
		for y in range(top, bot + 1):
			var v := float(y - top) / float(maxi(bot - top, 1))
			var sy := clampi(int(round(v * float(VAO.size.y - 1))), 0, VAO.size.y - 1)
			var k := Vector2i(x - DOOR_TL.x, y - DOOR_TL.y)
			f1.set_pixel(k.x, k.y, face.get_pixel(sx, sy))
			m1.erase(k)
		f1.set_pixel(x - DOOR_TL.x, top - DOOR_TL.y, L.col("ink"))
		f1.set_pixel(x - DOOR_TL.x, bot - DOOR_TL.y, L.col("ink"))
	for y in range(117, 223):
		f1.set_pixel(fx0 - DOOR_TL.x, y - DOOR_TL.y, L.col("ink"))
		f1.set_pixel(fx0 + 1 - DOOR_TL.x, y - DOOR_TL.y, L.col("br1") if y > 118 and y < 221 else L.col("ink"))
		m1.erase(Vector2i(fx0 - DOOR_TL.x, y - DOOR_TL.y))
		m1.erase(Vector2i(fx0 + 1 - DOOR_TL.x, y - DOOR_TL.y))
	out.append(f1)
	door_street_mask.append(m1)
	# 2 = aberta para dentro: a rua inteira no vão, a folha de perfil à direita (x 452..459)
	var f2: Image = base.duplicate()
	var m2 := {}
	for x in range(VAO.position.x, VAO.end.x):
		for y in range(VAO.position.y, VAO.end.y):
			f2.set_pixel(x - DOOR_TL.x, y - DOOR_TL.y, st.get_pixel(x - VAO.position.x, y - VAO.position.y))
			m2[Vector2i(x - DOOR_TL.x, y - DOOR_TL.y)] = true
	var lx0 := 452
	var lx1 := 459
	for x in range(lx0, lx1 + 1):
		var u := float(x - lx0) / float(lx1 - lx0)
		var top := int(round(lerpf(119.0, 116.0, u)))
		var bot := int(round(lerpf(220.0, 223.0, u)))
		for y in range(top, bot + 1):
			var c := "br2"
			var yy := y - top
			if yy >= 8 and yy <= 30:
				c = "st2" if x < lx1 - 1 else "st1"
			elif yy >= 86:
				c = "st1"
			elif yy % 10 == 0:
				c = "br1"
			if x == lx1 - 1 and c == "br2":
				c = "br1"
			f2.set_pixel(x - DOOR_TL.x, y - DOOR_TL.y, L.col(c))
			m2.erase(Vector2i(x - DOOR_TL.x, y - DOOR_TL.y))
		f2.set_pixel(x - DOOR_TL.x, top - DOOR_TL.y, L.col("ink"))
		f2.set_pixel(x - DOOR_TL.x, bot - DOOR_TL.y, L.col("ink"))
	for y in range(116, 224):
		f2.set_pixel(lx1 - DOOR_TL.x, y - DOOR_TL.y, L.col("ink"))
	f2.set_pixel(lx1 - 2 - DOOR_TL.x, 168 - DOOR_TL.y, L.col("y0"))
	f2.set_pixel(lx1 - 2 - DOOR_TL.x, 169 - DOOR_TL.y, L.col("br0"))
	out.append(f2)
	door_street_mask.append(m2)
	# 3..5 = os mesmos no escuro: tudo -1, menos a rua (luz do dia)
	for i in 3:
		var d: Image = out[i].duplicate()
		var mk: Dictionary = door_street_mask[i]
		for y in d.get_height():
			for x in d.get_width():
				if mk.has(Vector2i(x, y)):
					continue
				var c := d.get_pixel(x, y)
				if c.a > 0.0:
					d.set_pixel(x, y, L.shade(c, -1))
		out.append(d)
	return out

# ================================================================ luz do dia no chão
func light_mask(m: Dictionary, y0: int, y1: int, xl0: float, xr0: float, xl1: float, xr1: float, borda: int, n: int) -> void:
	for y in range(y0, y1 + 1):
		var t := 0.0 if y1 == y0 else float(y - y0) / float(y1 - y0)
		var a := int(round(lerpf(xl0, xl1, t)))
		var b := int(round(lerpf(xr0, xr1, t)))
		for x in range(a, b + 1):
			var d := mini(mini(x - a, b - x), (y1 - y) * 2)
			if d < borda and bayer(x, y) > float(d + 1) / float(borda + 1):
				continue
			var k := Vector2i(x, y)
			m[k] = maxi(int(m.get(k, 0)), n)

const DAY_TRAP := [   # [y0, y1, xl0, xr0, xl1, xr1, borda]; o 2º trapézio é o miolo (+1 passo)
	[[221, 289, 404, 451, 336, 470, 7], [221, 258, 410, 445, 378, 452, 6]],
	[[221, 262, 404, 417, 352, 424, 6]]]

func daylight(i: int) -> Image:
	var img: Image = L.blank(DAY_SIZE.x, DAY_SIZE.y)
	var m := {}
	var tr: Array = DAY_TRAP[i]
	for j in tr.size():
		var q: Array = tr[j]
		light_mask(m, q[0], q[1], q[2], q[3], q[4], q[5], q[6], j + 1)
	for k in m:
		var p: Vector2i = k
		var lx := p.x - DAY_TL.x
		var ly := p.y - DAY_TL.y
		if lx < 0 or ly < 0 or lx >= DAY_SIZE.x or ly >= DAY_SIZE.y or p.y >= ROOM.end.y:
			continue
		img.set_pixel(lx, ly, L.shade(bg_px(p.x, p.y), int(m[k])))
	return img

# ================================================================ foto, bolsa, caixote
func photo_straight() -> Image:
	var s: Image = frame_of("wall_photo_old")
	var o: Image = L.blank(18, 21)
	for y in 21:
		for x in 18:
			var sy := y + (1 if x >= 9 else 0)
			if sy < s.get_height():
				o.set_pixel(x, y, s.get_pixel(x, sy))
	return o

## a bolsa É a referência do Artista (fase6c1_bolsa_ref.png), para a troca no grab_frame não pular
func duffel() -> Image:
	var ref := ROOT + "docs/arte/mockups/fase6c1_bolsa_ref.png"
	if FileAccess.file_exists(ref):
		return load_abs(ref)
	push_error("fase6c1_bolsa_ref.png não existe: rode o make_sprites_fase6c1.gd antes")
	return L.blank(18, 11)

## o mesmo engradado do make_cenario_fase6b1.gd, com a luz dos tubos no lugar da lâmpada
func crate_gym() -> Image:
	var img: Image = L.blank(26, 19)
	L.R(img, 0, 0, 26, 18, "ink")
	L.R(img, 1, 1, 24, 3, "br2")
	L.R(img, 1, 1, 24, 1, "br3")
	L.R(img, 13, 1, 1, 3, "br1")
	L.R(img, 1, 4, 24, 1, "br0")
	for ry in [5, 9, 13]:
		L.R(img, 1, ry, 24, 3, "br1")
		L.R(img, 1, ry, 24, 1, "br2")
	for gy in [8, 12]:
		L.R(img, 1, gy, 24, 1, "d1")
		for gx in range(3, 23, 3):
			L.P(img, gx, gy, "ink")
	L.R(img, 1, 16, 24, 1, "br0")
	for mx in [1, 22]:
		L.R(img, mx, 5, 3, 12, "br1")
		L.R(img, mx, 5, 1, 12, "br2")
		L.R(img, mx + 2, 5, 1, 12, "br0")
	for p in [[2, 6], [2, 14], [23, 6], [23, 14], [7, 2], [19, 2]]:
		L.P(img, p[0], p[1], "g2")
	L.R(img, 9, 10, 4, 1, "br0")
	L.R(img, 15, 6, 3, 1, "br0")
	L.P(img, 24, 2, "br1")
	var out := gym_lit(img, P_SEAT + CRATE_OFF)
	for x in range(1, 26):
		if x % 2 == 1 or x > 18:
			out.set_pixel(x, 18, L.col("ink"))
	return out

# ================================================================ personagens (folhas que já existem)
func recolor_map(look: Array) -> Dictionary:
	var pb: Dictionary = OLD.by_data_id.disciple_palette
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

func sheet_rect(id: String, pos: Vector2i, look := []) -> Rect2i:
	var e := spr(id)
	var pv := pivot_of(id)
	var r := Rect2i()
	for q in int(e.frames):
		var im: Image = layered(id, q, look) if not look.is_empty() else frame_of(id, q)
		var rq := opaque_rect(im, pos - pv)
		r = rq if q == 0 else r.merge(rq)
	return r

# ================================================================ sala
func it_spr(name: String, id: String, q: int, pos: Vector2i, sort_y: float, shadow := false) -> Dictionary:
	var at := pos - pivot_of(id)
	return {"y": sort_y, "img": frame_of(id, q), "at": at, "shadow": pos + Vector2i(0, -1) if shadow else null, "name": name}

func it_img(name: String, img: Image, pos: Vector2i, piv := GPIV, shadow := true, sort_y := -1.0) -> Dictionary:
	return {"y": float(pos.y) if sort_y < 0 else sort_y, "img": img, "at": pos - piv, "shadow": pos + Vector2i(0, -1) if shadow else null, "name": name}

## o = {escuro, porta (0..2), foto (-1 sem, 0 reta, 1 torta), luz (-1, 0, 1), pera, corrente}
func room(o: Dictionary, items: Array) -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	blend(im, BG, ROOM.position.x, ROOM.position.y)
	var dark: bool = o.get("escuro", false)
	var porta := int(o.get("porta", -1))
	if porta >= 0:
		blend(im, frame_of("gym_door", porta + (3 if dark else 0)), DOOR_TL.x, DOOR_TL.y)
	var foto := int(o.get("foto", 1))
	if foto >= 0:
		blend(im, frame_of("wall_photo_old_gym", foto), P_PHOTO.x, P_PHOTO.y)
	if dark:
		blend(im, frame_of("gym_half_dark"), ROOM.position.x, ROOM.position.y)
	var luz := int(o.get("luz", -1))
	if luz >= 0:
		blend(im, frame_of("gym_daylight", luz), DAY_TL.x, DAY_TL.y)
	var te := spr("gym_tube")
	blend(im, frame_of("gym_tube", 0), TUBES[0].x - int(te.pivot[0]), TUBES[0].y)
	blend(im, frame_of("gym_tube", 1 if dark else 0), TUBES[1].x - int(te.pivot[0]), TUBES[1].y)
	if o.get("pera", false):
		blend(im, frame_of("speed_bag_l0_wall_gym"), 436 - 24, 46)
	if o.get("corrente", true):
		var t: Image = frame_of("bag_chain_tile")
		var y := 33
		while y < 183:
			blend(im, t.get_region(Rect2i(0, 0, t.get_width(), mini(6, 183 - y))), 335, y)
			y += 6
	var all := items.duplicate()
	all.sort_custom(func(a, b): return a.y < b.y)
	var fs := spr("floor_shadow")
	for it in all:
		if it.shadow != null:
			blend(im, frame_of("floor_shadow"), it.shadow.x - int(fs.pivot[0]), it.shadow.y - int(fs.pivot[1]))
		blend(im, it.img, it.at.x, it.at.y)
	return im

func crate_item() -> Dictionary:
	return {"y": float(P_SEAT.y - 2), "img": frame_of("garage_crate_gym"), "at": P_SEAT + CRATE_OFF, "shadow": null, "name": "caixote"}

## sala cheia: equipe máxima, Osmar, John no caixote, último em pé, lutador no saco.
## caixas = true: as 4 caixas fechadas; false: tudo comprado (esteira encostada, corda no prego, boneco de jiu-jitsu)
func cast(caixas: bool) -> Array:
	var items := []
	items.append(it_spr("saco", "bag_l0_idle_gym", 0, Vector2i(336, 183), 253.0))
	items.append(crate_item())
	items.append(it_img("john", frame_of("john_sit_rest", 0), P_SEAT))
	items.append(it_img("osmar", frame_of(COACH_ID, 0), P_COACH))
	items.append(it_img("lutador", layered("fighter_idle_disc_layered", 0, CUR_LOOK), P_FIGHTER))
	items.append(it_img("mentor2", layered("disciple_stand_bare", 0, M2_LOOK), P_STAND))
	for id in CREW:
		var e := spr(id)
		items.append(it_spr(id, id, 0, Vector2i(int(e.pos[0]), int(e.pos[1])), float(e.pos[1]), true))
	if caixas:
		var bs: Dictionary = OLD.layout.box_slots
		for k in ["treadmill", "jump_rope", "art", "glove"]:
			var p := Vector2i(int(bs[k][0]), int(bs[k][1]))
			items.append(it_spr("caixa_" + k, "box_big" if k == "treadmill" else "box_small", 0, p, float(p.y)))
	else:
		items.append(it_spr("esteira", "treadmill_l0_side_gym", 0, Vector2i(445, 267), 267.0))
		items.append(it_spr("corda", "rope_l0_idle_gym", 0, Vector2i(296, 166), 206.0))
		items.append(it_spr("boneco", "grappling_dummy_l0_rest_gym", 0, Vector2i(228, 283), 270.0))
	return items

## depois da saída do John (Carreira 3+): o último sentado no caixote, o ponto de pé vazio
func cast_after() -> Array:
	var items := cast(false)
	for i in range(items.size() - 1, -1, -1):
		if items[i].name in ["john", "mentor2"]:
			items.remove_at(i)
	if spr("disciple_sit_rest").has("layers"):
		items.append(it_img("ultimo", layered("disciple_sit_rest", 0, M2_LOOK), P_SEAT))
	return items

# ================================================================ conferência
func dashed(img: Image, r: Rect2i, c: String) -> void:
	for x in range(r.position.x, r.end.x):
		if x % 4 < 2:
			L.P(img, x, r.position.y, c)
			L.P(img, x, r.end.y - 1, c)
	for y in range(r.position.y, r.end.y):
		if y % 4 < 2:
			L.P(img, r.position.x, y, c)
			L.P(img, r.end.x - 1, y, c)

func balloon_rect(head: Vector2i, w := 154, h := 26) -> Rect2i:
	var tip_y := head.y - 6
	var by := tip_y - 3 - h
	var bx := clampi(head.x - w / 2, USABLE.position.x, USABLE.end.x - w)
	return Rect2i(bx, by - 6, w, h + 10)

func head_box(id: String, pos: Vector2i, q := 0) -> Rect2i:
	var e := spr(id)
	var pv := pivot_of(id)
	if e.has("anchors"):
		var hb: Array = e.anchors[q].head_box
		return Rect2i(pos.x - pv.x + int(hb[0]), pos.y - pv.y + int(hb[1]), int(hb[2]), int(hb[3]))
	var ha: Array = e.get("head_anchor", [1, -63])
	return Rect2i(pos.x + int(ha[0]) - 6, pos.y + int(ha[1]), 13, 13)

func label(img: Image, s: String, x: int, y: int, c := "white") -> void:
	L.text(img, s, x, y, c, 1, "ink")

## caminhos da porta da rua até o centro (faixa de 24 px = corpo andando): direto e passando pela espera
const PATHS := [[Vector2i(428, 224), Vector2i(352, 262)], [Vector2i(352, 262), Vector2i(303, 272)],
	[Vector2i(428, 224), Vector2i(303, 272)]]

func path_hits(r: Rect2i) -> bool:
	for pth in PATHS:
		var a := Vector2(pth[0])
		var b := Vector2(pth[1])
		for i in 41:
			var p := a.lerp(b, i / 40.0)
			if Rect2i(int(p.x) - 12, int(p.y) - 66, 24, 66).intersects(r):
				return true
	return false

func draw_paths(img: Image) -> void:
	for pth in PATHS:
		var a := Vector2(pth[0])
		var b := Vector2(pth[1])
		for i in 121:
			var p := a.lerp(b, i / 120.0)
			for s in [-12, 12]:
				if i % 4 < 2:
					L.P(img, int(p.x) + s, int(p.y), "gr3")
			L.P(img, int(p.x), int(p.y), "gr3")

func box_rects() -> Dictionary:
	var out := {}
	var bs: Dictionary = OLD.layout.box_slots
	for k in ["treadmill", "jump_rope", "art", "glove"]:
		var e := spr("box_big" if k == "treadmill" else "box_small")
		var cr: Array = e.click_rect
		out["caixa_" + k] = Rect2i(int(bs[k][0]) + int(cr[0]), int(bs[k][1]) + int(cr[1]), int(cr[2]), int(cr[3]))
	return out

func occupants() -> Dictionary:
	var o := {}
	for id in CREW:
		var e := spr(id)
		o[id] = sheet_rect(id, Vector2i(int(e.pos[0]), int(e.pos[1])))
	o["lutador"] = sheet_rect("fighter_idle_disc_layered", P_FIGHTER, CUR_LOOK)
	o["saco_centro"] = opaque_rect(frame_of("bag_l0_idle_gym"), Vector2i(336 - 20, 183))
	o["saco_de_lado"] = opaque_rect(frame_of("bag_l0_side_gym"), Vector2i(258 - 20, 160))
	o["esteira_encostada"] = opaque_rect(frame_of("treadmill_l0_side_gym"), Vector2i(445 - 43, 267 - 41))
	o["corda_prego"] = opaque_rect(frame_of("rope_l0_idle_gym"), Vector2i(296 - 9, 166))
	o["boneco_canto"] = opaque_rect(frame_of("grappling_dummy_l0_rest_gym"), Vector2i(228 - 32, 283 - 27))
	o["pera_parede"] = opaque_rect(frame_of("speed_bag_l0_wall_gym"), Vector2i(436 - 24, 46))
	o["corrente_centro"] = Rect2i(334, 33, 4, 150)
	o["corrente_lado"] = Rect2i(256, 33, 4, 127)
	var br := box_rects()
	for k in br:
		o[k] = br[k]
	return o

var SPOT_RECTS := {}
var AVISOS := []

func check() -> Array:
	var probs := []
	var spots := {
		"gym_coach_spot (Osmar)": sheet_rect(COACH_ID, P_COACH),
		"gym_mentor_spot (John sentado)": sheet_rect("john_sit_rest", P_SEAT),
		"gym_mentor_spot (caixote)": Rect2i(P_SEAT + CRATE_OFF, Vector2i(26, 19)),
		"gym_mentor_2_spot (último em pé)": sheet_rect("disciple_stand_bare", P_STAND, M2_LOOK),
		"gym_photo_spot (foto)": Rect2i(P_PHOTO, PHOTO_SIZE),
	}
	if spr("disciple_sit_rest").has("layers"):
		spots["gym_mentor_spot (último sentado)"] = sheet_rect("disciple_sit_rest", P_SEAT, M2_LOOK)
	SPOT_RECTS = spots
	var occ := occupants()
	var x0: int = TARGET[0] - FOLGA
	var x1: int = TARGET[1] + FOLGA
	for k in spots:
		var r: Rect2i = spots[k]
		print("%s ocupa %s (x %d..%d, y %d..%d)" % [k, str(r), r.position.x, r.end.x - 1, r.position.y, r.end.y - 1])
		if r.end.x - 1 >= x0 and r.position.x <= x1:
			probs.append(k + ": faixa do alvo")
		if r.intersects(NO_COVER):
			probs.append(k + ": no_cover")
		if not k.begins_with("gym_photo") and path_hits(r):
			probs.append(k + ": caminho da porta ao centro")
		for o in occ:
			var ro: Rect2i = occ[o]
			if ro.intersects(r):
				var inter := ro.intersection(r)
				var a := pixel_overlap(k, o, inter)
				print("   encosta em %s: %s, %d px opacos sobrepostos" % [o, str(inter), a])
				if a > 0 and (o.begins_with("caixa_") or k.begins_with("gym_photo")):
					probs.append("%s x %s: %d px" % [k, o, a])
				elif a > 20:
					# a mesma sobreposição já existe na garagem (mesmos pontos, mesma equipe): aviso, não trava
					AVISOS.append("%s x %s: %d px (igual na garagem)" % [k, o, a])
	var keys := spots.keys()
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			var a: String = keys[i]
			var b: String = keys[j]
			if a.begins_with("gym_mentor_spot") and b.begins_with("gym_mentor_spot"):
				continue
			var ra: Rect2i = spots[a]
			var rb: Rect2i = spots[b]
			if ra.intersects(rb):
				var n := pixel_overlap(a, b, ra.intersection(rb))
				print("   %s encosta em %s: %d px opacos" % [a, b, n])
				if n > 0:
					probs.append("%s x %s: %d px" % [a, b, n])
	var heads := {"osmar": head_box(COACH_ID, P_COACH), "mentor2": head_box("disciple_stand_bare", P_STAND),
		"john_sentado": Rect2i(P_SEAT.x - 5, P_SEAT.y - 57, 13, 13), "lutador": head_box("fighter_idle_disc_layered", P_FIGHTER)}
	for id in CREW:
		var e := spr(id)
		heads[id] = head_box(id, Vector2i(int(e.pos[0]), int(e.pos[1])))
	var speakers := {"osmar": P_COACH + Vector2i(1, -63), "john_sentado": P_SEAT + Vector2i(1, -56),
		"lutador": Vector2i(303, 210), "john_parado_porta": Vector2i(378, 176)}
	for s in speakers:
		var br := balloon_rect(speakers[s])
		var hit := []
		for h in heads:
			if h == s or (s.begins_with("john") and h == "john_sentado"):
				continue
			if br.intersects(heads[h]):
				hit.append(h)
		print("   balão %s %s cobre: %s" % [s, str(br), str(hit)])
		if s == "osmar" and not hit.is_empty():
			probs.append("balão de %s cobre %s" % [s, str(hit)])
		if br.intersects(spots["gym_photo_spot (foto)"]):
			print("      (o balão de %s passa por cima da foto: aceito, a foto não é cabeça)" % s)
	for a in AVISOS:
		print("AVISO " + a)
	print("=> %s" % ("OK" if probs.is_empty() else "; ".join(probs)))
	return probs

func pixel_overlap(a: String, b: String, inter: Rect2i) -> int:
	var ia := occ_image(a)
	var ib := occ_image(b)
	if ia.is_empty() or ib.is_empty():
		return inter.get_area()
	var n := 0
	for y in range(inter.position.y, inter.end.y):
		for x in range(inter.position.x, inter.end.x):
			if ia.has(Vector2i(x, y)) and ib.has(Vector2i(x, y)):
				n += 1
	return n

var occ_cache := {}

func occ_image(k: String) -> Dictionary:
	if occ_cache.has(k):
		return occ_cache[k]
	var px := {}
	var srcs := []
	if k.begins_with("gym_coach_spot"):
		for q in 4:
			srcs.append([frame_of(COACH_ID, q), P_COACH - pivot_of(COACH_ID)])
	elif k.begins_with("gym_mentor_spot (John"):
		for q in 4:
			srcs.append([frame_of("john_sit_rest", q), P_SEAT - GPIV])
	elif k.begins_with("gym_mentor_spot (último"):
		for q in 4:
			srcs.append([layered("disciple_sit_rest", q, M2_LOOK), P_SEAT - GPIV])
	elif k.begins_with("gym_mentor_spot (caixote"):
		srcs.append([frame_of("garage_crate_gym"), P_SEAT + CRATE_OFF])
	elif k.begins_with("gym_mentor_2_spot"):
		for q in 4:
			srcs.append([layered("disciple_stand_bare", q, M2_LOOK), P_STAND - GPIV])
	elif k.begins_with("gym_photo_spot"):
		srcs.append([frame_of("wall_photo_old_gym", 1), P_PHOTO])
	elif k in CREW:
		var e := spr(k)
		for q in int(e.frames):
			srcs.append([frame_of(k, q), Vector2i(int(e.pos[0]), int(e.pos[1])) - pivot_of(k)])
	elif k == "lutador":
		for q in 4:
			srcs.append([layered("fighter_idle_disc_layered", q, CUR_LOOK), P_FIGHTER - GPIV])
	elif k == "saco_de_lado":
		srcs.append([frame_of("bag_l0_side_gym"), Vector2i(238, 160)])
	elif k == "boneco_canto":
		srcs.append([frame_of("grappling_dummy_l0_rest_gym"), Vector2i(196, 256)])
	elif k == "esteira_encostada":
		srcs.append([frame_of("treadmill_l0_side_gym"), Vector2i(402, 226)])
	else:
		occ_cache[k] = {}
		return {}
	for s in srcs:
		var im: Image = s[0]
		var at: Vector2i = s[1]
		for y in im.get_height():
			for x in im.get_width():
				if im.get_pixel(x, y).a > 0.0:
					px[Vector2i(x, y) + at] = true
	occ_cache[k] = px
	return px

# ================================================================ mockups
func folha_titulo(w: int, h: int, t1: String, t2: String) -> Image:
	var s: Image = L.blank(w, h)
	L.R(s, 0, 0, w, h, "d1")
	label(s, t1, 8, 6, "y1")
	label(s, t2, 8, 16, "g3")
	return s

func mockups() -> void:
	DirAccess.make_dir_recursive_absolute(MOCK)
	var cheia := room({"porta": 0, "foto": 1}, cast(true))
	cheia.save_png(MOCK + "fase6c1_academia_cheia_x1.png")
	var comprada := room({"porta": 0, "foto": 1}, cast(false))
	var depois := room({"porta": 0, "foto": 1}, cast_after())
	var s: Image = folha_titulo(ROOM.size.x * 2 * 3 + 40, ROOM.size.y * 2 + 40,
		"FASE 6C1 - ACADEMIA CHEIA (2X): EQUIPE MAXIMA, OSMAR (coach_idle_gym), CAIXOTE COM MENTOR, ULTIMO EM PE, FOTO TORTA",
		"ESQ: AS 4 CAIXAS FECHADAS   MEIO: TUDO COMPRADO (ESTEIRA, CORDA, BONECO NO TATAME)   DIR: DEPOIS DA SAIDA (ULTIMO SENTADO, disciple_sit_rest)")
	blend(s, scaled(cheia.get_region(ROOM), 2), 10, 30)
	blend(s, scaled(comprada.get_region(ROOM), 2), 20 + ROOM.size.x * 2, 30)
	blend(s, scaled(depois.get_region(ROOM), 2), 30 + ROOM.size.x * 4, 30)
	s.save_png(MOCK + "fase6c1_academia_cheia_x2.png")
	# conferência
	var chk := room({"porta": 2, "foto": 1, "luz": 0}, cast(true))
	dashed(chk, Rect2i(TARGET[0] - FOLGA, 150, TARGET[1] - TARGET[0] + 2 * FOLGA + 1, 139), "r2")
	dashed(chk, NO_COVER, "r1")
	draw_paths(chk)
	var br := box_rects()
	for k in br:
		dashed(chk, br[k], "y1")
	for k in SPOT_RECTS:
		if str(k).contains("último sentado"):
			continue
		dashed(chk, (SPOT_RECTS[k] as Rect2i).grow(1), "b3" if not str(k).begins_with("gym_photo") else "f2")
	dashed(chk, balloon_rect(P_COACH + Vector2i(1, -63)), "cream")
	for p in [P_COACH, P_SEAT, P_STAND]:
		L.R(chk, p.x - 1, p.y, 3, 1, "white")
		L.R(chk, p.x, p.y - 1, 1, 3, "white")
	var big := scaled(chk.get_region(ROOM), 2)
	var sh: Image = L.blank(big.get_width(), big.get_height() + 34)
	L.R(sh, 0, 0, sh.get_width(), sh.get_height(), "d1")
	blend(sh, big, 0, 34)
	label(sh, "VERMELHO: ALVO + FOLGA 8 / NO_COVER   VERDE: PORTA > ESPERA > CENTRO   AMARELO: CAIXAS", 6, 4)
	label(sh, "AZUL: OSMAR 196,236 / CAIXOTE+JOHN 254,252 / ULTIMO 150,262   ROSA: FOTO 212,158   CREME: BALAO DO OSMAR", 6, 14)
	label(sh, "PORTA ABERTA + LUZ DO DIA (SAIDA DO JOHN). OS TRES PONTOS DE GENTE SAO OS MESMOS DA GARAGEM.", 6, 24)
	sh.save_png(MOCK + "fase6c1_academia_conferencia_x2.png")
	pecas()
	quadros()

func pecas() -> void:
	var s: Image = folha_titulo(1440, 1240, "FASE 6C1 - PECAS DE CENARIO DA ACADEMIA (PLACEHOLDER, GERADO POR CODIGO)",
		"gym_door 0-5 (3X)   gym_daylight 0-1 (2X)   gym_half_dark (1X)   foto reta/torta, bolsa, caixote x caixote_gym (4X)   pick_duffel com a bolsa (3X)")
	var y := 34
	var x := 10
	var nomes := ["0 FECHADA", "1 MEIO", "2 ABERTA", "3 FECHADA ESC.", "4 MEIO ESC.", "5 ABERTA ESC."]
	for i in 6:
		var ctx: Image = L.blank(DOOR_SIZE.x + 16, DOOR_SIZE.y + 16)
		var region := Rect2i(DOOR_TL - Vector2i(8, 8) - ROOM.position, DOOR_SIZE + Vector2i(16, 16))
		ctx.blit_rect(BG, region, Vector2i.ZERO)
		if i >= 3:
			L.shade_rect(ctx, 0, 0, ctx.get_width(), ctx.get_height(), -1)
		blend(ctx, frame_of("gym_door", i), 8, 8)
		blend(s, scaled(ctx, 3), x, y + 10)
		label(s, nomes[i], x, y)
		x += ctx.get_width() * 3 + 8
	y += (DOOR_SIZE.y + 16) * 3 + 20
	x = 10
	for i in 2:
		var c := room({"porta": 2 - i, "foto": -1, "luz": i, "escuro": true, "corrente": false}, [])
		var reg := Rect2i(320, 110, 192, 180)
		blend(s, scaled(c.get_region(reg), 2), x, y + 10)
		label(s, "gym_daylight %d no escuro (porta %d)" % [i, 5 - i], x, y)
		x += reg.size.x * 2 + 10
	var hd := room({"porta": 0, "foto": 1, "escuro": true}, [])
	blend(s, hd.get_region(ROOM), x, y + 10)
	label(s, "gym_half_dark + gym_door 3 (1x)", x, y)
	var y2 := y + ROOM.size.y + 24
	for i in 2:
		blend(s, scaled(frame_of("wall_photo_old_gym", i), 4), x + i * 90, y2 + 10)
		label(s, ["reta", "torta"][i], x + i * 90, y2)
	blend(s, scaled(frame_of("john_duffel"), 4), x + 180, y2 + 10)
	label(s, "bolsa", x + 180, y2)
	blend(s, scaled(frame_of("garage_crate"), 4), x + 270, y2 + 10)
	label(s, "caixote", x + 270, y2)
	blend(s, scaled(frame_of("garage_crate_gym"), 4), x + 390, y2 + 10)
	label(s, "caixote_gym", x + 390, y2)
	# o John pegando a bolsa no ponto do caixote: a bolsa (adereço) até o grab_frame, depois só a folha
	if spr("john_pick_duffel").has("file"):
		var e := spr("john_pick_duffel")
		var grab := int(e.get("grab_frame", 4))
		var yy := y + ROOM.size.y + 24
		label(s, "john_pick_duffel no gym_mentor_spot + john_duffel em (268,242) ate o grab_frame %d (3x)" % grab, 10, yy)
		for q in int(e.frames):
			var c := room({"foto": 1}, [crate_item(), it_spr("john", "john_pick_duffel", q, P_SEAT, float(P_SEAT.y))] +
				([{"y": 251.0, "img": frame_of("john_duffel"), "at": DUFFEL_TL, "shadow": null, "name": "bolsa"}] if q < grab else []))
			var reg := Rect2i(222, 176, 72, 82)
			blend(s, scaled(c.get_region(reg), 3), 10 + (q % 3) * 222, yy + 12 + (q / 3) * 250)
			label(s, "q%d" % q, 12 + (q % 3) * 222, yy + 14 + (q / 3) * 250)
	s.save_png(MOCK + "fase6c1_cenario_pecas_x3.png")

func quadros() -> void:
	var qs := []
	var hold := "coach_hold_photo" if spr("coach_hold_photo").has("file") else COACH_ID
	var nudge := "coach_nudge_photo" if spr("coach_nudge_photo").has("file") else COACH_ID
	var waitid := "john_carry_bag_idle_left" if spr("john_carry_bag_idle_left").has("file") else ""
	var a1 := room({"escuro": true, "porta": 0, "foto": -1}, [it_spr("osmar", hold, 0, P_COACH, float(P_COACH.y), true)])
	qs.append([a1, "A1  CASA VAZIA: METADE DIREITA ESCURA, PORTA FECHADA (gym_door 3)", "Osmar: " + hold])
	var a3items := [it_spr("osmar", hold, 0, P_COACH, float(P_COACH.y), true), crate_item(), it_img("john", frame_of("john_sit_rest", 0), P_SEAT)]
	if waitid != "":
		a3items.append(it_spr("lutador", waitid, 0, P_WAIT, float(P_WAIT.y), true))
	var a3 := room({"escuro": true, "porta": 2, "foto": -1, "luz": 0}, a3items)
	qs.append([a3, "A3  PORTA ABERTA NO ESCURO (gym_door 5 + gym_daylight 0), CAIXOTE NO PONTO", "John sentado; lutador esperando: " + (waitid if waitid != "" else "-")])
	var a6b := room({"escuro": true, "porta": 2, "foto": 1, "luz": 0},
		[it_spr("osmar", nudge, 3, P_COACH, float(P_COACH.y), true), crate_item(), it_img("john", frame_of("john_sit_rest", 0), P_SEAT)])
	var a6: Image = L.blank(640, 360)
	L.R(a6, 0, 0, 640, 360, "ink")
	blend(a6, scaled(a6b.get_region(Rect2i(128, 118, 192, 136)), 2), ROOM.position.x, ROOM.position.y)
	qs.append([a6, "A6  PLANO 2X (128,118,192,136): FOTO TORTA (wall_photo_old_gym 1)", "Osmar: " + nudge + " q3"])
	var a7 := room({"porta": 2, "foto": 1, "luz": 0},
		[it_spr("osmar", COACH_ID, 0, P_COACH, float(P_COACH.y), true), crate_item(), it_img("john", frame_of("john_sit_rest", 0), P_SEAT),
		it_spr("saco", "bag_l0_idle_gym", 0, Vector2i(336, 183), 253.0),
		it_img("lutador", layered("fighter_idle_disc_layered", 0, CUR_LOOK), P_FIGHTER),
		it_spr("esteira", "treadmill_l0_side_gym", 0, Vector2i(445, 267), 267.0)])
	qs.append([a7, "A7  O OUTRO TUBO ACENDE: SEM gym_half_dark, PORTA 2 CLARA, LUZ 0", "saco no gancho, esteira encostada (o vizinho fica de fora aqui)"])
	var s: Image = folha_titulo(ROOM.size.x * 2 + 30, (ROOM.size.y + 30) * 2 + 40, "FASE 6C1 - QUADROS A1, A3, A6, A7 COM AS PECAS FINAIS DE CENARIO (1X)",
		"folhas do Artista onde já existem; recorte = a sala 384x272")
	for i in qs.size():
		var cx := 10 + (i % 2) * (ROOM.size.x + 10)
		var cy := 30 + (i / 2) * (ROOM.size.y + 30)
		var img: Image = qs[i][0]
		blend(s, img.get_region(ROOM), cx, cy + 18)
		label(s, qs[i][1], cx, cy)
		label(s, qs[i][2], cx, cy + 9, "g3")
	s.save_png(MOCK + "fase6c1_cenario_quadros_x1.png")

# ================================================================ manifest
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

func rect_arr(r: Rect2i) -> Array:
	return [r.position.x, r.position.y, r.size.x, r.size.y]

func write_manifest() -> void:
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível na hora de gravar; nada foi escrito")
		return
	var doc: Dictionary = intify(j.data)
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 6c1 (Diretor de Arte)") < 0:
		doc["_sobre"] = sobre + " Fase 6c1 (Diretor de Arte): metade escura, porta da rua, luz do dia, foto antiga e caixote na academia, bolsa do John, pontos gym_* (direcao-visual.md §25)."
	var sp: Dictionary = doc.get("sprites", {})
	for id in M:
		sp[id] = intify(M[id])
	doc["sprites"] = sp
	var lay: Dictionary = doc.get("layout", {})
	var r_coach: Rect2i = SPOT_RECTS["gym_coach_spot (Osmar)"]
	var r_seat: Rect2i = (SPOT_RECTS["gym_mentor_spot (John sentado)"] as Rect2i).merge(SPOT_RECTS["gym_mentor_spot (caixote)"])
	var r_stand: Rect2i = SPOT_RECTS["gym_mentor_2_spot (último em pé)"]
	lay["gym_coach_spot"] = [P_COACH.x, P_COACH.y]
	lay["gym_coach_spot_info"] = {"location": "gym", "requires_milestone": "cena_primeira_academia", "who": "coach (Osmar)",
		"sprite": "coach_idle_gym / coach_talk_gym (luz dos tubos)", "facing": "direita", "head_anchor": [1, -63],
		"head_anchor_abs": [P_COACH.x + 1, P_COACH.y - 63], "sort_y": P_COACH.y, "occupies": rect_arr(r_coach),
		"_nota": "Pés do Osmar na academia: o mesmo ponto da garagem, em frente ao banco pintado. A foto fica à direita da cabeça dele. Detalhes: by_data_id.gym_arrival_scene e direcao-visual.md §25."}
	lay["gym_mentor_spot"] = [P_SEAT.x, P_SEAT.y]
	lay["gym_mentor_spot_info"] = {"location": "gym", "requires_milestone": "cena_primeira_academia", "role": "seat",
		"pose": "sit_rest", "facing": "direita", "head_anchor_hint": [5, -51], "sort_y": P_SEAT.y,
		"crate": {"sprite": "garage_crate_gym", "pos": [P_SEAT.x + CRATE_OFF.x, P_SEAT.y + CRATE_OFF.y], "pivot": [16, 20], "layer": "sorted", "sort_y": P_SEAT.y - 2,
			"visible": "a partir do marco cena_primeira_academia, com gente sentada ou não (substitui o banco do design §4.1)"},
		"occupies": rect_arr(r_seat),
		"_nota": "Pés de quem senta no caixote na academia: o mesmo ponto da garagem. Com o saco de lado (258,160) o saco passa atrás da cabeça dele pela ordem por y, como na garagem."}
	lay["gym_mentor_2_spot"] = [P_STAND.x, P_STAND.y]
	lay["gym_mentor_2_spot_info"] = {"location": "gym", "requires_milestone": "cena_primeira_academia", "role": "stand",
		"pose": "stand_bare", "sprite": "disciple_stand_bare", "facing": "direita", "head_anchor": [1, -65],
		"head_anchor_abs": [P_STAND.x + 1, P_STAND.y - 65], "sort_y": P_STAND.y, "occupies": rect_arr(r_stand),
		"_nota": "O último que passou o posto, de pé, encostado na parede esquerda, sobre o tatame. O mesmo ponto da garagem. O caminho até o caixote (104 px para a direita) não cruza a faixa do alvo."}
	lay["gym_photo_spot"] = [P_PHOTO.x, P_PHOTO.y]
	lay["gym_photo_spot_info"] = {"location": "gym", "requires_milestone": "cena_primeira_academia", "anchor": "canto de cima à esquerda",
		"sprite": "wall_photo_old_gym", "frame_in_game": 1, "layer": "wall", "size": [PHOTO_SIZE.x, PHOTO_SIZE.y],
		"object_text": "old_photo_gym", "click_rect": [P_PHOTO.x, P_PHOTO.y, PHOTO_SIZE.x, PHOTO_SIZE.y],
		"_nota": "No barrado verde, acima da mochila pintada no banco, à direita da cabeça do Osmar. Fora do saco de lado (x 238..278), da corrente e da faixa do alvo. No jogo, na academia, sempre o quadro 0 (reta)."}
	doc["layout"] = lay
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["gym_arrival_scene"] = {
		"half_dark": {"sprite": "gym_half_dark", "pos": [128, 18], "layer": "floor",
			"note": "Só enquanto o tubo da direita está apagado (A1..A6), junto com gym_tube quadro 1 no tubo da direita. Furo transparente no retângulo da porta (401,116,60,108): ali entra a gym_door escura (quadros 3..5)."},
		"door": {"sprite": "gym_door", "pos": [DOOR_TL.x, DOOR_TL.y], "layer": "wall",
			"frames_lit": {"closed": 0, "half": 1, "open": 2}, "frames_dark": {"closed": 3, "half": 4, "open": 5},
			"note": "Com o gym_half_dark na tela use as animações *_dark; quando o tubo acende (A7), trocar para o quadro claro equivalente no mesmo tique em que o gym_half_dark some. A rua no vão não escurece. Fora das cenas a porta não é desenhada (o gym_bg já tem a fechada)."},
		"daylight": {"sprite": "gym_daylight", "pos": [DAY_TL.x, DAY_TL.y], "layer": "floor", "frame_for_door": {"1": 1, "2": 0, "4": 1, "5": 0},
			"note": "Desenhar DEPOIS do gym_half_dark (os dois são floor): a luz é o próprio chão 1 passo mais claro, também na metade escura."},
		"photo": {"sprite": "wall_photo_old_gym", "pos": [P_PHOTO.x, P_PHOTO.y], "layer": "wall", "frames": {"0": "reta (do A6 em diante e no jogo)", "1": "torta (A4-A5)"}},
		"crate": {"sprite": "garage_crate_gym", "pos": [P_SEAT.x + CRATE_OFF.x, P_SEAT.y + CRATE_OFF.y], "layer": "sorted", "sort_y": P_SEAT.y - 2},
		"duffel": {"sprite": "john_duffel", "pos": [DUFFEL_TL.x, DUFFEL_TL.y], "layer": "sorted", "sort_y": 251,
			"note": "Só na saída do John, até o grab_frame do john_pick_duffel. Serve nos dois locais (o caixote está no mesmo ponto). Nunca fica na sala."},
		"draw_order": "gym_bg -> wall (gym_door, wall_photo_old_gym) -> floor (gym_half_dark, depois gym_daylight) -> gym_tube -> sorted por y (caixote 250, bolsa 251, gente)",
		"_nota": "Fase 6c1 (Diretor de Arte). Pedido: docs/cutscenes/pedidos-6c1.md §2. Tempos e coreografia: data/cutscenes/primeira_academia.json e saida_primeiro_mentor.json."}
	bd["_nota_fase6c1_arte"] = "Fase 6c1 (Diretor de Arte): layout.gym_coach_spot, gym_mentor_spot, gym_mentor_2_spot, gym_photo_spot (+ _info) e by_data_id.gym_arrival_scene. Conferência: docs/arte/mockups/fase6c1_academia_conferencia_x2.png; texto: direcao-visual.md §25."
	doc["by_data_id"] = bd
	var fa := FileAccess.open(ROOT + "assets/sprites/manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()
	print("manifest: %d sprites da 6c1 (cenário), 4 pontos gym_*, by_data_id.gym_arrival_scene" % M.size())


# ================================================================ busca de pontos (--busca)
func pxset(img: Image, at: Vector2i, into: Dictionary) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				into[Vector2i(x, y) + at] = true

func rectset(r: Rect2i, into: Dictionary) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			into[Vector2i(x, y)] = true

func overlap(a: Dictionary, b: Dictionary) -> int:
	var n := 0
	for k in a:
		if b.has(k):
			n += 1
	return n

func busca() -> void:
	var occ := {}
	for id in CREW:
		var e := spr(id)
		var d := {}
		for q in int(e.frames):
			pxset(frame_of(id, q), Vector2i(int(e.pos[0]), int(e.pos[1])) - pivot_of(id), d)
		occ[id] = d
	var br := box_rects()
	for k in br:
		var d := {}
		rectset(br[k], d)
		occ[k] = d
	var dm := {}
	pxset(frame_of("grappling_dummy_l0_rest_gym"), Vector2i(196, 256), dm)
	occ["boneco"] = dm
	var seat := {}
	for q in 4:
		pxset(frame_of("john_sit_rest", q), P_SEAT - GPIV, seat)
	pxset(frame_of("garage_crate_gym"), P_SEAT + CRATE_OFF, seat)
	occ["seat"] = seat
	var m2 := {}
	for q in 4:
		pxset(layered("disciple_stand_bare", q, M2_LOOK), P_STAND - GPIV, m2)
	if not OS.get_cmdline_user_args().has("--sem-m2"):
		occ["mentor2"] = m2
	var bag := {}
	pxset(frame_of("bag_l0_side_gym"), Vector2i(238, 160), bag)
	occ["saco_lado"] = bag
	for k in occ:
		var r := Rect2i()
		var first := true
		for p in occ[k]:
			r = Rect2i(p, Vector2i.ONE) if first else r.expand(p).merge(Rect2i(p, Vector2i.ONE))
			first = false
		print(k, " ", r)
	var cf := []
	for q in 4:
		var d := {}
		pxset(frame_of(COACH_ID, q), Vector2i.ZERO - pivot_of(COACH_ID), d)
		cf.append(d)
	var coach := {}
	for d in cf:
		for k in d:
			coach[k] = true
	var extra := {}
	for q in 4:
		pxset(layered("fighter_idle_disc_layered", q, CUR_LOOK), P_FIGHTER - GPIV, extra)
	pxset(frame_of("bag_l0_idle_gym"), Vector2i(316, 183), extra)
	pxset(frame_of("treadmill_l0_side_gym"), Vector2i(402, 226), extra)
	occ["centro"] = extra
	for y in range(222, 288, 2 if not OS.get_cmdline_user_args().has("--min") else 4):
		var line := "y %d: " % y
		for x in range(136, 506, 2):
			if x + 14 >= TARGET[0] - FOLGA and x - 12 <= TARGET[1] + FOLGA:
				continue
			if path_hits(Rect2i(x - 12, y - 64, 26, 64)):
				continue
			var tot := 0
			var who := []
			for k in occ:
				var n := 0
				for p in coach:
					if (occ[k] as Dictionary).has(p + Vector2i(x, y)):
						n += 1
				if n > 0:
					tot += n
					who.append(k)
			if tot == 0:
				line += "%d " % x
			elif tot < 60 and OS.get_cmdline_user_args().has("--min"):
				line += "%d(%d:%s) " % [x, tot, ",".join(who)]
		print(line)

# ================================================================ equipe na academia (--equipe)
## Pontos próprios da equipe na academia (by_data_id.gym.people_pos). Ninguém cobre ninguém: Osmar, mentores, caixote,
## foto, saco de lado, aparelhos e caixas (os dois estados), faixa do alvo, no_cover e caminhos da porta. Busca com volta.
var GYM_CREW := {}          # id -> [x, y]
var GYM_FLIP := {}          # id -> true se a folha precisa ser virada
var FIXED := {}             # pixels ocupados (tela)

func offs_of(id: String, flip: bool) -> Array:
	var e := spr(id)
	var pv := pivot_of(id)
	var fw := int(e.frame_size[0])
	var d := {}
	for q in int(e.frames):
		var im := frame_of(id, q)
		for y in im.get_height():
			for x in im.get_width():
				if im.get_pixel(x, y).a > 0.0:
					var ox := (fw - 1 - x) - (fw - 1 - pv.x) if flip else x - pv.x
					d[Vector2i(ox, y - pv.y)] = true
	return d.keys()

func bounds_of(offs: Array) -> Rect2i:
	var r := Rect2i(offs[0], Vector2i.ONE)
	for o in offs:
		r = r.merge(Rect2i(o, Vector2i.ONE))
	return r

func floor_ok(p: Vector2i) -> bool:
	if p.y < 224 or p.y > 288:
		return false
	return p.x >= 170 - 1.2 * (p.y - 220) + 4 and p.x <= 471 + 0.62 * (p.y - 220) - 4

func fixed_occupancy() -> Dictionary:
	var o := {}
	for q in 4:
		pxset(frame_of(COACH_ID, q), P_COACH - pivot_of(COACH_ID), o)
		pxset(frame_of("john_sit_rest", q), P_SEAT - GPIV, o)
		pxset(layered("disciple_stand_bare", q, M2_LOOK), P_STAND - GPIV, o)
		if spr("disciple_sit_rest").has("layers"):
			pxset(layered("disciple_sit_rest", q, M2_LOOK), P_SEAT - GPIV, o)
	pxset(frame_of("garage_crate_gym"), P_SEAT + CRATE_OFF, o)
	rectset(Rect2i(P_PHOTO, PHOTO_SIZE), o)
	pxset(frame_of("bag_l0_side_gym"), Vector2i(238, 160), o)
	pxset(frame_of("bag_l1_side_gym"), Vector2i(238, 160), o)
	pxset(frame_of("treadmill_l0_side_gym"), Vector2i(402, 226), o)
	pxset(frame_of("treadmill_l1_side_gym"), Vector2i(402, 226), o)
	pxset(frame_of("grappling_dummy_l0_rest_gym"), Vector2i(196, 256), o)
	pxset(frame_of("grappling_dummy_l1_rest_gym"), Vector2i(196, 256), o)
	pxset(frame_of("speed_bag_l0_wall_gym"), Vector2i(412, 46), o)
	var bs: Dictionary = OLD.layout.box_slots
	for k in ([] if OS.get_cmdline_user_args().has("--sem-caixas") else ["treadmill", "jump_rope", "art", "glove"]):
		var id := "box_big" if k == "treadmill" else "box_small"
		for q in 4:
			pxset(frame_of(id, q), Vector2i(int(bs[k][0]), int(bs[k][1])) - pivot_of(id), o)
	# faixa do alvo com folga e no_cover (o centro inteiro: lutador e aparelho em foco)
	rectset(Rect2i(TARGET[0] - FOLGA, 120, TARGET[1] - TARGET[0] + 2 * FOLGA + 1, 170), o)
	rectset(NO_COVER, o)
	return o

## caminhos: porta > espera > centro e a saída (parada 380,246 > porta)
const CREW_PATHS := [[Vector2i(428, 224), Vector2i(352, 262)], [Vector2i(352, 262), Vector2i(303, 272)],
	[Vector2i(428, 224), Vector2i(303, 272)], [Vector2i(380, 246), Vector2i(428, 224)]]

func crew_path_hits(r: Rect2i) -> bool:
	for pth in (CREW_PATHS.slice(0, 3) if OS.get_cmdline_user_args().has("--sem-saida") else CREW_PATHS):
		var a := Vector2(pth[0])
		var b := Vector2(pth[1])
		for i in 41:
			var p := a.lerp(b, i / 40.0)
			if Rect2i(int(p.x) - 12, int(p.y) - 66, 24, 66).intersects(r):
				return true
	return false

func fits(offs: Array, p: Vector2i, occ: Dictionary) -> bool:
	for o in offs:
		if occ.has(o + p):
			return false
	return true

func equipe() -> bool:
	FIXED = fixed_occupancy()
	var osmar_balloon := balloon_rect(P_COACH + Vector2i(1, -63))
	var order := ["neighbor_1", "uncle_1", "neighbor_3", "uncle_2", "coach_1", "neighbor_2"]
	var cands := {}
	var shapes := {}
	for id in order:
		var e := spr(id)
		var home := Vector2i(int(e.pos[0]), int(e.pos[1]))
		var list := []
		for flip in [false, true]:
			var offs := offs_of(id, flip)
			shapes[[id, flip]] = offs
			var b := bounds_of(offs)
			for y in range(224, 289, 1):
				for x in range(134, 506, 1):
					var p := Vector2i(x, y)
					if not floor_ok(p):
						continue
					var r := Rect2i(b.position + p, b.size)
					if r.position.x < ROOM.position.x or r.end.x > ROOM.end.x or r.end.y > ROOM.end.y:
						continue
					if crew_path_hits(r):
						continue
					var head := Rect2i(r.position, Vector2i(r.size.x, 14))
					if head.intersects(osmar_balloon):
						continue
					if not fits(offs, p, FIXED):
						continue
					# custo: distância ao ponto da garagem, virar custa caro
					list.append([(p - home).length() + (60.0 if flip else 0.0), p, flip])
		list.sort_custom(func(a, b): return a[0] < b[0])
		cands[id] = list
		print("%s: %d pontos livres sozinho" % [id, list.size()])
	var dbg := room({"porta": 0, "foto": 1}, [])
	for k in FIXED:
		if (k.x + k.y) % 2 == 0:
			L.P(dbg, k.x, k.y, "r2")
	for y in range(224, 289):
		for x in range(134, 506):
			if floor_ok(Vector2i(x, y)) and (x % 4 == 0 and y % 4 == 0):
				L.P(dbg, x, y, "gr3")
	for pth in CREW_PATHS:
		for i in 61:
			var pp := Vector2(pth[0]).lerp(Vector2(pth[1]), i / 60.0)
			L.R(dbg, int(pp.x) - 12, int(pp.y), 24, 1, "y1")
	dashed(dbg, osmar_balloon, "cream")
	var big := scaled(dbg.get_region(ROOM), 2)
	var sh: Image = L.blank(big.get_width(), big.get_height() + 34)
	L.R(sh, 0, 0, sh.get_width(), sh.get_height(), "d1")
	blend(sh, big, 0, 34)
	label(sh, "FASE 6C1 - ONDE A EQUIPE PODERIA FICAR NA ACADEMIA (2X)   VERMELHO: OCUPADO (OSMAR, MENTORES, CAIXOTE, FOTO, SACO DE LADO,", 6, 4)
	label(sh, "APARELHOS E CAIXAS NOS DOIS ESTADOS, ALVO+FOLGA, NO_COVER)   AMARELO: CAMINHOS DA PORTA   CREME: BALAO DO OSMAR   VERDE: CHAO", 6, 14)
	label(sh, "COM AS 4 CAIXAS CABEM NO MAXIMO 3 PESSOAS DE 25 PX; NEIGHBOR_1, NEIGHBOR_2 E UNCLE_1 NAO TEM NENHUM PONTO LIVRE NEM SOZINHOS", 6, 24, "y1")
	sh.save_png(MOCK + "fase6c1_academia_espaco_livre_x2.png")
	var sol := {}
	var ok := place(order, 0, cands, shapes, FIXED.duplicate(), sol)
	if ok:
		for id in order:
			GYM_CREW[id] = sol[id][0]
			GYM_FLIP[id] = sol[id][1]
			print("  %s -> %s%s" % [id, str(sol[id][0]), " VIRADO" if sol[id][1] else ""])
	else:
		print("sem solução com a equipe inteira")
	return ok


## quantos cabem ao mesmo tempo (guloso), com a forma real de cada um ou com uma pose estreita de 25 px (disciple_stand_bare)
func capacidade() -> void:
	FIXED = fixed_occupancy()
	var osmar_balloon := balloon_rect(P_COACH + Vector2i(1, -63))
	var formas := {"estreita": [], "neighbor_1": [], "uncle_1": [], "coach_1": [], "neighbor_3": [], "uncle_2": [], "neighbor_2": []}
	var d := {}
	for q in 4:
		var im := layered("disciple_stand_bare", q, M2_LOOK)
		for y in im.get_height():
			for x in im.get_width():
				if im.get_pixel(x, y).a > 0.0:
					d[Vector2i(x, y) - GPIV] = true
	formas["estreita"] = d.keys()
	for id in formas:
		if id != "estreita":
			formas[id] = offs_of(id, false)
	for id in formas:
		var offs: Array = formas[id]
		var b := bounds_of(offs)
		var occ := FIXED.duplicate()
		var placed := []
		for y in range(288, 223, -1):
			for x in range(134, 506):
				var p := Vector2i(x, y)
				if not floor_ok(p):
					continue
				var r := Rect2i(b.position + p, b.size)
				if r.position.x < ROOM.position.x or r.end.x > ROOM.end.x or r.end.y > ROOM.end.y:
					continue
				if crew_path_hits(r) or Rect2i(r.position, Vector2i(r.size.x, 14)).intersects(osmar_balloon):
					continue
				if fits(offs, p, occ):
					placed.append(p)
					for o in offs:
						occ[o + p] = true
		print("%s (%dx%d): cabem %d -> %s" % [id, b.size.x, b.size.y, placed.size(), str(placed)])

var tries := 0

func place(order: Array, i: int, cands: Dictionary, shapes: Dictionary, occ: Dictionary, sol: Dictionary) -> bool:
	if i == order.size():
		return true
	var id: String = order[i]
	var n := 0
	for c in cands[id]:
		tries += 1
		if tries > 400000:
			return false
		var offs: Array = shapes[[id, c[2]]]
		if not fits(offs, c[1], occ):
			continue
		n += 1
		if n > 60:
			break
		var occ2 := occ.duplicate()
		for o in offs:
			occ2[o + c[1]] = true
		sol[id] = [c[1], c[2]]
		if place(order, i + 1, cands, shapes, occ2, sol):
			return true
	return false

# ================================================================ main
func _init() -> void:
	ROOT = OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else (get_script().resource_path.get_base_dir().get_base_dir().get_base_dir() + "/")
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	FINAL = OS.get_cmdline_user_args().has("--final")
	var here: String = ProjectSettings.globalize_path("res://")
	OUT = (ROOT + "assets/sprites/") if FINAL else (here.trim_suffix("/") + "/out/")
	MOCK = (ROOT + "docs/arte/mockups/") if FINAL else (here.trim_suffix("/") + "/out/mock/")
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json")) != OK:
		push_error("manifest.json ilegível")
		quit(1)
		return
	OLD = j.data
	# folhas do Artista (só em memória, para conferir e montar os mockups; a junção é o merge_manifest_6c1.gd)
	var pj := ROOT + "docs/arte/manifest-6c1-personagens.json"
	if FileAccess.file_exists(pj):
		var jp := JSON.new()
		if jp.parse(FileAccess.get_file_as_string(pj)) == OK:
			var sin: Dictionary = jp.data.get("sprites", {})
			for id in sin:
				if not OLD.sprites.has(id):
					OLD.sprites[id] = sin[id]
	if spr("coach_idle_gym").has("file"):
		COACH_ID = "coach_idle_gym"
	BG = frame_of("gym_bg")

	save_sheet("gym_half_dark", "gym/gym_half_dark.png", [half_dark()], 0, Vector2i.ZERO, {
		"pos": [128, 18], "layer": "floor",
		"note": "Fase 6c1: a metade direita da academia 1 passo mais escura (tubo da direita apagado, A1..A6 da chegada). É o próprio gym_bg -1 de x 340 em diante, com borda em dither ordenado 4x4 de x 300 a 339; transparente à esquerda. Furo transparente no retângulo da porta da rua (401,116,60,108), onde a gym_door escura (quadros 3..5) desenha. Sem alpha parcial. Fica abaixo das pessoas."})
	save_sheet("gym_door", "gym/gym_door.png", door_frames(), 10, Vector2i.ZERO, {
		"pos": [DOOR_TL.x, DOOR_TL.y], "layer": "wall", "loop": false,
		"anim": {"closed": [0], "open": [0, 1, 2], "close": [2, 1, 0], "opened": [2],
			"closed_dark": [3], "open_dark": [3, 4, 5], "close_dark": [5, 4, 3], "opened_dark": [5]},
		"note": "Fase 6c1: porta da rua da academia por cima da pintada no gym_bg (batente 401..454, vão 404..451 x 120..219). 0 = fechada (recorte do fundo); 1 = meio aberta, a folha a 45 graus (a mesma face apertada em x 418..451) e a rua na fresta; 2 = aberta para dentro, folha de perfil à direita (x 452..459) e a rua clara no vão (céu branco, fachada cream, y2 em dither, muro e calçada cream na mesma altura da garage_door_outside). 3..5 = os mesmos 1 passo mais escuros, menos a rua: usar enquanto o gym_half_dark estiver na tela. Pedido era 3 quadros; os 3 escuros entraram por causa da metade escura."})
	save_sheet("gym_daylight", "gym/gym_daylight.png", [daylight(0), daylight(1)], 10, Vector2i.ZERO, {
		"pos": [DAY_TL.x, DAY_TL.y], "layer": "floor", "loop": false,
		"anim": {"full": [0], "half": [1], "open": [1, 0], "close": [0, 1]},
		"note": "Fase 6c1: luz do dia no piso de borracha. O próprio gym_bg 1 passo mais claro (miolo junto à porta 2 passos), trapézio que abre para a esquerda e para a frente (y 221..289, base x 336..470), borda em dither ordenado. 0 = porta aberta; 1 = meio aberta (só a fresta da esquerda). Desenhar depois do gym_half_dark."})
	save_sheet("wall_photo_old_gym", "gym/wall_photo_old_gym.png", [photo_straight(), frame_of("wall_photo_old")], 0, Vector2i.ZERO, {
		"pos": [P_PHOTO.x, P_PHOTO.y], "point": "gym_photo_spot", "layer": "wall", "z": -45, "loop": false,
		"anim": {"straight": [0], "tilt": [0, 1], "crooked": [1]},
		"note": "Fase 6c1: a foto antiga na academia (gym_photo_spot, no barrado verde acima da mochila do banco). 0 = reta (a metade direita 1 px acima; a mesma conta das folhas do Artista); 1 = torta, igual à wall_photo_old da garagem. Na academia, no jogo, sempre o quadro 0 (reta): o Osmar desentorta a foto no A6."})
	save_sheet("john_duffel", "characters/john_duffel.png", [duffel()], 0, Vector2i.ZERO, {
		"pos": [DUFFEL_TL.x, DUFFEL_TL.y], "layer": "sorted", "sort_y": 251,
		"note": "Fase 6c1: bolsa de lona do John no chão, atrás do caixote (268,242). É a docs/arte/mockups/fase6c1_bolsa_ref.png do Artista, pixel a pixel (a bolsa da folha john_pick_duffel não pula no grab_frame). Sem luz pintada, como as folhas do John. Só no começo da saída; nunca fica na sala."})
	save_sheet("garage_crate_gym", "garage/garage_crate_gym.png", [crate_gym()], 0, Vector2i(-CRATE_OFF.x, -CRATE_OFF.y), {
		"pos": [P_SEAT.x + CRATE_OFF.x, P_SEAT.y + CRATE_OFF.y], "layer": "sorted", "sort_y": P_SEAT.y - 2, "point": "gym_mentor_spot",
		"note": "Fase 6c1: o mesmo caixote do mentor com a luz dos tubos (sem o calor da lâmpada). Regra do sufixo _gym: na academia o jogo usa este no lugar do garage_crate. Visível na academia a partir do marco cena_primeira_academia."})
	if OS.get_cmdline_user_args().has("--capacidade"):
		capacidade()
		quit()
		return
	if OS.get_cmdline_user_args().has("--equipe"):
		equipe()
		quit()
		return
	if OS.get_cmdline_user_args().has("--busca"):
		busca()
		quit()
		return
	var probs := check()
	mockups()
	if FINAL:
		if probs.is_empty():
			write_manifest()
		else:
			push_error("pontos com problema; manifest NÃO gravado")
	print("ok fase 6c1 cenário (%s): %d sprites" % ["PROJETO" if FINAL else "previa", M.size()])
	quit()
