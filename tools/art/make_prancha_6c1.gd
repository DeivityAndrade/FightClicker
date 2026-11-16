extends SceneTree
## Prancha de quadros-chave da 6c1 (Diretor de Cutscenes): "Primeira chegada à academia" e "Saída do John".
## NÃO é arte final: composição, luz, silhuetas e tempo. Poses novas = um quadro só, em rascunho
## (personagem_lib ou uma folha que já existe servindo de dublê). Nada entra em assets/ nem no manifest.
## Texto: docs/cutscenes/prancha-6c1.md.
## Rodar de uma pasta temporária com project.godot vazio (nunca no projeto):
##   Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_prancha_6c1.gd -- [pasta_de_saida]
## Sem argumento grava em docs/arte/mockups/:
##   prancha_6c1_chegada.png, prancha_6c1_saida.png (folhas 2 colunas, 640x360 por quadro, com legenda)
##   prancha_6c1_elenco.png (os 3 elencos da chegada, mesmo recorte em 2x)
##   prancha_6c1_chegada_A01..A08.png, prancha_6c1_saida_J01..J08.png (quadros soltos 640x360)

const ROOT := "E:/Fightclicker/"
const GPIV := Vector2(22, 67)
const SALA := Rect2i(128, 18, 384, 272)
const CUT_A := Rect2i(128, 118, 192, 136)     # plano 2x da chegada (Osmar, foto, caixote)
# porta da rua da academia (pintada no gym_bg): miolo x 404..451, y 120..219
const DX0 := 404
const DX1 := 451
const DY0 := 120
const DY1 := 219
# porta de enrolar da garagem
const GD_X0 := 382
const GD_X1 := 463
const GD_Y1 := 219
const GD_JAM := 171
const P_FIGHT := Vector2(303, 272)
const P_COACH := Vector2(196, 236)
const P_MENTOR := Vector2(254, 252)
const P_MENTOR2 := Vector2(150, 262)
const P_DOOR := Vector2(428, 224)
const P_WAIT := Vector2(352, 262)             # onde o lutador espera com o saco durante o plano 2x
const P_STOP := Vector2(380, 246)             # onde o John para e olha a sala
const PHOTO := Vector2(212, 158)              # gym_photo_spot (canto de cima à esquerda da foto)
const TREAD := Vector2(445, 267)

var L
var P
var M: Dictionary
var OUT := ROOT + "docs/arte/mockups/"
var cache := {}
var b_john_bare: Dictionary
var b_disc_bare: Dictionary
var b_last: Dictionary

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================ sprites do jogo
func folha(id: String) -> Array:
	if cache.has(id):
		return cache[id]
	var e: Dictionary = M.sprites[id]
	var path: String = ROOT + "assets/sprites/" + (e.file as String).replace("res://assets/sprites/", "")
	var fr: Array = P.frames_of(path, int(e.frame_size[0]))
	cache[id] = fr
	return fr

func quadro(id: String, q: int) -> Image:
	var fr := folha(id)
	return fr[clampi(q, 0, fr.size() - 1)]

func por(dst: Image, id: String, q: int, pos: Vector2) -> void:
	var e: Dictionary = M.sprites[id]
	P.paste(dst, quadro(id, q), int(pos.x) - int(e.pivot[0]), int(pos.y) - int(e.pivot[1]))

func colar_clip(dst: Image, src: Image, x: int, y: int, clip: Rect2i) -> void:
	var r := Rect2i(x, y, src.get_width(), src.get_height()).intersection(clip)
	if r.has_area():
		dst.blend_rect(src, Rect2i(r.position.x - x, r.position.y - y, r.size.x, r.size.y), r.position)

func girado(im: Image, horario := true) -> Image:
	var o: Image = im.duplicate()
	o.rotate_90(CLOCKWISE if horario else COUNTERCLOCKWISE)
	return o

# ================================================================ poses novas (rascunho, 1 quadro)
func gpose(o: Dictionary) -> Dictionary:
	var p := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47),
		"hl": V(-8, -50), "hr": V(10, -51), "toel": V(-1, 0), "toer": V(10, 0)}
	for k in o:
		p[k] = o[k]
	return p

func g(b: Dictionary, o: Dictionary, tag: String) -> Image:
	return P.garage_frame(b, gpose(o), tag)

const BARE := {"hl": Vector2(-9, -28), "hr": Vector2(11, -28), "gkl": "", "gkr": ""}

func pose_stand(b: Dictionary, face := "normal") -> Image:
	var o := BARE.duplicate()
	o["face"] = face
	o["head"] = V(2, -57)
	return g(b, o, "stand")

func pose_walk(b: Dictionary) -> Image:
	return g(b, {"top": V(2, -50), "head": V(3, -57), "sl": V(-6, -47), "sr": V(9, -47), "hl": V(-3, -29),
		"hr": V(13, -30), "toel": V(-5, 0), "toer": V(12, 0), "gkl": "", "gkr": ""}, "walk")

func pose_carry_shoulder(b: Dictionary) -> Image:    # anda com uma mão erguida segurando a carga no ombro
	return g(b, {"top": V(2, -50), "head": V(4, -56), "sl": V(-6, -47), "sr": V(9, -47), "hl": V(-6, -58),
		"hr": V(12, -31), "toel": V(-5, 0), "toer": V(12, 0), "gkl": "", "gkr": ""}, "carry_bag")

func pose_carry_front(b: Dictionary) -> Image:       # anda com o caixote nos dois braços, à frente do peito
	return g(b, {"top": V(0, -50), "head": V(1, -57), "sl": V(-6, -47), "sr": V(9, -47), "hl": V(6, -38),
		"hr": V(15, -39), "toel": V(-5, 0), "toer": V(12, 0), "gkl": "", "gkr": ""}, "carry_crate")

func pose_lift(b: Dictionary) -> Image:              # ergue o saco para o gancho
	return g(b, {"top": V(2, -51), "head": V(2, -58), "hl": V(12, -62), "hr": V(18, -66), "pr": V(1, 0.5),
		"gkl": "", "gkr": ""}, "hang_bag")

func pose_sit(b: Dictionary) -> Image:
	return g(b, {"hip": V(0, -18), "top": V(3, -36), "head": V(5, -43), "sl": V(-5, -33), "sr": V(10, -33),
		"hl": V(2, -19), "hr": V(13, -20), "toel": V(-3, 0), "toer": V(12, 0), "kl": V(1, -0.2), "kr": V(1, -0.2),
		"gkl": "", "gkr": ""}, "sit_rest")

func pose_pick(b: Dictionary) -> Image:              # dobra o tronco e pega a bolsa no chão
	return g(b, {"hip": V(0, -27), "top": V(7, -43), "head": V(11, -48), "sl": V(1, -42), "sr": V(13, -40),
		"hl": V(-2, -22), "hr": V(16, -16), "kl": V(1, 0), "kr": V(1, 0), "gkl": "", "gkr": ""}, "pick_duffel")

func pose_duck(b: Dictionary) -> Image:              # passa por baixo da porta de enrolar
	return g(b, {"hip": V(0, -19), "top": V(9, -33), "head": V(13, -38), "sl": V(2, -33), "sr": V(15, -30),
		"hl": V(3, -14), "hr": V(19, -43), "pr": V(1, 0.3), "toel": V(-3, 0), "toer": V(11, 0), "kl": V(1, 0),
		"kr": V(1, 0), "gkl": "", "gkr": ""}, "duck_out")

# ================================================================ peças de cenário em rascunho
func caixote(dst: Image, pos: Vector2) -> void:
	var x := int(pos.x) - 14
	var y := int(pos.y) - 17
	L.R(dst, x - 1, y - 1, 26, 19, "ink")
	L.R(dst, x, y, 24, 17, "br1")
	L.R(dst, x, y, 24, 3, "br2")
	for i in [5, 10]:
		L.R(dst, x, y + i, 24, 1, "br0")
	L.R(dst, x + 2, y + 3, 2, 14, "br0")
	L.R(dst, x + 20, y + 3, 2, 14, "br0")

func caixote_img() -> Image:
	var im: Image = L.blank(26, 19)
	caixote(im, V(14, 18))
	return im

func bolsa_img() -> Image:                            # bolsa de lona do John (rascunho)
	var im: Image = L.blank(18, 11)
	L.rrect(im, 0, 2, 18, 9, "ink")
	L.rrect(im, 1, 3, 16, 7, "g1")
	L.R(im, 2, 4, 14, 1, "g2")
	L.R(im, 4, 3, 1, 7, "g0")
	L.R(im, 13, 3, 1, 7, "g0")
	L.R(im, 6, 0, 6, 1, "ink")
	L.R(im, 5, 1, 1, 2, "ink")
	L.R(im, 12, 1, 1, 2, "ink")
	return im

func corrente(dst: Image, x: int, y_fim: int) -> void:
	var t: Image = quadro("bag_chain_tile", 0)
	var y := 33
	while y < y_fim:
		P.paste(dst, t.get_region(Rect2i(0, 0, 4, mini(6, y_fim - y))), x - 1, y)
		y += 6

func luz_chao(dst: Image, y0: int, y1: int, xl0: float, xr0: float, xl1: float, xr1: float, n: int, borda := 5) -> void:
	for y in range(y0, y1 + 1):
		var t := 0.0 if y1 == y0 else float(y - y0) / float(y1 - y0)
		var a := int(round(lerpf(xl0, xl1, t)))
		var b := int(round(lerpf(xr0, xr1, t)))
		for x in range(a, b + 1):
			if x < SALA.position.x or y < 0 or x >= SALA.end.x or y >= SALA.end.y:
				continue
			var d := mini(x - a, b - x)
			if d < borda and (x + y) % 2 == 1:
				continue
			var c := dst.get_pixel(x, y)
			if c.a > 0.0:
				dst.set_pixel(x, y, L.shade(c, n))

func foto_reta() -> Image:
	var s: Image = quadro("wall_photo_old", 0)
	var o: Image = L.blank(18, 21)
	o.blit_rect(s, Rect2i(0, 0, 9, 21), Vector2i(0, 0))
	o.blit_rect(s, Rect2i(9, 1, 9, 20), Vector2i(9, 0))
	return o

func sombra_metade(im: Image) -> void:
	# o tubo da direita está apagado: a metade direita da sala fica 1 passo mais escura, com borda em dither
	L.shade_rect(im, 300, 18, 40, 272, -1, true)
	L.shade_rect(im, 340, 18, 172, 272, -1)
	L.shade_rect(im, 400, 18, 112, 272, -1, true)

func porta_aberta(im: Image, com_luz := true) -> void:
	# a porta da rua aberta para dentro: luz do dia branca no vão, folha da porta de perfil à direita
	L.R(im, DX0, DY0, DX1 - DX0 + 1, DY1 - DY0 + 1, "white")
	L.R(im, DX0, DY0 + 46, DX1 - DX0 + 1, DY1 - DY0 - 45, "y2")
	L.dither(im, DX0, DY0 + 40, DX1 - DX0 + 1, 6, "y2")
	L.R(im, DX0, DY1 - 6, DX1 - DX0 + 1, 7, "cream")
	L.dither(im, DX0, DY1 - 8, DX1 - DX0 + 1, 2, "cream")
	L.R(im, DX1 - 4, DY0, 5, DY1 - DY0 + 1, "br1")
	L.R(im, DX1 - 5, DY0, 1, DY1 - DY0 + 1, "ink")
	L.R(im, DX1 - 3, DY0 + 50, 2, 3, "y0")
	if com_luz:
		luz_chao(im, 221, 289, DX0 - 2, DX1 - 4, DX0 - 70, DX1 - 30, 1, 7)
		luz_chao(im, 221, 250, DX0 + 4, DX1 - 10, DX0 - 22, DX1 - 22, 1, 5)

## opções: escuro (tubo direito apagado), porta (aberta), foto (0 sem, 1 reta, 2 torta), tubo_esq_pisca
func academia_base(o := {}) -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	por(im, "gym_bg", 0, V(128, 18))
	if o.get("tubo_esq_pisca", false):
		por(im, "gym_tube", 1, V(218, 34))
	if o.get("escuro", false):
		por(im, "gym_tube", 1, V(422, 34))
		sombra_metade(im)
	if o.get("porta", false):
		porta_aberta(im)
	var f := int(o.get("foto", 0))
	if f == 1:
		P.paste(im, foto_reta(), int(PHOTO.x), int(PHOTO.y))
	elif f == 2:
		P.paste(im, quadro("wall_photo_old", 0), int(PHOTO.x), int(PHOTO.y))
	return im

func garagem_base() -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	por(im, "garage_bg", 0, V(128, 18))
	for id in ["wall_form_named", "wall_photo_old"]:
		var e: Dictionary = M.sprites[id]
		por(im, id, 0, V(e.pos[0], e.pos[1]))
	por(im, "lamp", 0, V(300, 32))
	return im

func porta_garagem_emperrada(dst: Image) -> void:
	L.R(dst, GD_X0, GD_JAM, GD_X1 - GD_X0 + 1, GD_Y1 - GD_JAM + 1, "white")
	L.R(dst, GD_X0, GD_JAM + 18, GD_X1 - GD_X0 + 1, GD_Y1 - GD_JAM - 17, "y2")
	L.dither(dst, GD_X0, GD_JAM + 14, GD_X1 - GD_X0 + 1, 4, "y2")
	L.R(dst, GD_X0, GD_Y1 - 6, GD_X1 - GD_X0 + 1, 7, "cream")
	L.R(dst, GD_X0 - 1, GD_JAM - 3, GD_X1 - GD_X0 + 3, 3, "st0")
	L.R(dst, GD_X0 - 1, GD_JAM, GD_X1 - GD_X0 + 3, 1, "ink")
	luz_chao(dst, 220, 289, GD_X0 - 2, GD_X1 + 1, GD_X0 - 74, GD_X1 + 14, 1, 7)

## itens = [[y de ordem, Image, canto de cima à esquerda, ponto da sombra ou null], ...]
func monta(im: Image, itens: Array) -> void:
	itens.sort_custom(func(a, b): return a[0] < b[0])
	for it in itens:
		if it.size() > 3 and it[3]:
			por(im, "floor_shadow", 0, it[3])
		P.paste(im, it[1], int((it[2] as Vector2).x), int((it[2] as Vector2).y))

func it_g(im: Image, pos: Vector2, esquerda := false) -> Array:    # personagem pelo ponto dos pés
	if esquerda:
		return [pos.y, L.flipped(im), pos - V(48 - 22, 67), pos + V(0, -1)]
	return [pos.y, im, pos - GPIV, pos + V(0, -1)]

func it_spr(id: String, q: int, pos: Vector2) -> Array:
	var e: Dictionary = M.sprites[id]
	return [pos.y, quadro(id, q), pos - V(e.pivot[0], e.pivot[1]), pos + V(0, -1)]

func it_obj(im: Image, tl: Vector2, sort_y: float) -> Array:
	return [sort_y, im, tl, null]

func it_caixote() -> Array:
	return it_obj(caixote_img(), V(238, 232), 250.0)

func it_saco() -> Array:
	return [253.0, quadro("bag_l0_idle_gym", 0), V(336 - 20, 183), null]

func equipe() -> Array:
	return [it_spr("neighbor_1", 0, V(176, 284)), it_spr("neighbor_2", 0, V(220, 258)),
		it_spr("uncle_1", 0, V(455, 236)), it_spr("uncle_2", 0, V(398, 230))]

func com_carga(pers: Image, carga: Image, off: Vector2, atras := false) -> Image:
	# junta personagem (48x72, pivô 22,67) e carga num quadro maior 96x96 com o pivô em (46,91)
	var o: Image = L.blank(96, 96)
	if atras:
		P.paste(o, carga, 46 + int(off.x), 91 + int(off.y))
	P.paste(o, pers, 24, 24)
	if not atras:
		P.paste(o, carga, 46 + int(off.x), 91 + int(off.y))
	return o

func it_c(im: Image, pos: Vector2, esquerda := false) -> Array:    # item de com_carga
	if esquerda:
		return [pos.y, L.flipped(im), pos - V(96 - 46, 91), pos + V(0, -1)]
	return [pos.y, im, pos - V(46, 91), pos + V(0, -1)]

func saco_deitado() -> Image:
	return girado(quadro("bag_l0_idle", 0).get_region(Rect2i(8, 6, 26, 64)))    # 64x26

func corte_2x(im: Image, reg: Rect2i) -> Image:
	var o: Image = L.blank(640, 360)
	L.R(o, 0, 0, 640, 360, "ink")
	P.paste(o, P.scaled(im.get_region(reg), 2), SALA.position.x, SALA.position.y)
	return o

# ================================================================ balão (peças reais da 6a)
func nove(dst: Image, id: String, x: int, y: int, w: int, h: int, m: int) -> void:
	var s: Image = quadro(id, 0)
	var sw := s.get_width()
	var sh := s.get_height()
	for yy in h:
		var sy := yy if yy < m else (sh - (h - yy) if yy >= h - m else m + (yy - m) % (sh - 2 * m))
		for xx in w:
			var sx := xx if xx < m else (sw - (w - xx) if xx >= w - m else m + (xx - m) % (sw - 2 * m))
			var c := s.get_pixel(sx, sy)
			if c.a > 0.0 and x + xx >= 0 and y + yy >= 0 and x + xx < dst.get_width() and y + yy < dst.get_height():
				dst.set_pixel(x + xx, y + yy, c)

func balao(dst: Image, linhas: Array, nome: String, cor: String, cabeca: Vector2, jan: Rect2i, min_x := 0) -> void:
	var mw := 0
	for l in linhas:
		mw = maxi(mw, L.text_w(l))
	var w := maxi(mw + 17, 40)
	var h := 17 if linhas.size() == 1 else 26
	var bx := clampi(int(cabeca.x) - w / 2, maxi(jan.position.x + 4, min_x), jan.end.x - 4 - w)
	var by := maxi(int(cabeca.y) - 5 - h, jan.position.y + 10)
	nove(dst, "ui_balloon", bx, by, w, h, 5)
	P.paste(dst, quadro("ui_balloon_tail", 0), int(cabeca.x) - 3, by + h - 2)
	var y := by + 5
	for l in linhas:
		L.text(dst, l, bx + (w - mw) / 2, y, "ink")
		y += 9
	if nome != "":
		var tw: int = L.text_w(nome) + 6
		nove(dst, "ui_balloon_tag_" + cor, bx + 6, by - 6, tw, 10, 2)
		L.text(dst, nome, bx + 9, by - 4, "white" if cor == "red" else "ink")

# ================================================================ interface em rascunho
func ui_sala(im: Image) -> void:
	var c := "d1"
	for r in [Rect2i(0, 0, 640, 18), Rect2i(0, 18, 128, 272), Rect2i(512, 18, 128, 272), Rect2i(0, 290, 640, 70)]:
		L.panel(im, r.position.x, r.position.y, r.size.x, r.size.y, c)
	L.text(im, "TREINO   $   FAMA", 8, 6, "g2")
	L.text_right(im, "ACADEMIA BOA ESQUINA", 632, 6, "g2")
	L.text_center(im, "PAINEL", 64, 30, "g1")
	L.text_center(im, "EQUIPE", 576, 30, "g1")
	for i in 5:
		L.R(im, 8, 46 + i * 22, 112, 16, "d2")
		L.R(im, 520, 46 + i * 22, 112, 16, "d2")
	for i in 3:
		L.button(im, 180 + i * 96, 304, 88, 30, "d2", "FOCO", "g2")
	L.button(im, 520, 302, 104, 34, "r1", "LUTAR!", "white")
	L.text_center(im, "(interface ligada: rascunho)", 320, 344, "g1")

func janela_arte(im: Image) -> void:
	L.dither(im, SALA.position.x, SALA.position.y, SALA.size.x, SALA.size.y, "ink")
	L.panel(im, 150, 40, 340, 250, "d1")
	L.R(im, 152, 42, 336, 14, "p0")
	L.text_center(im, "QUE TIPO DE LUTADOR VOCÊ QUER SER?", 320, 46, "white")
	L.panel(im, 164, 70, 150, 190, "d2")
	L.panel(im, 326, 70, 150, 190, "d2")
	L.text_center(im, "BOXE", 239, 80, "r3", 2)
	L.text_center(im, "JIU-JITSU", 401, 80, "b3", 2)
	L.text_center(im, "(janela que já existe: abre logo depois da cena)", 320, 272, "g1")

# ================================================================ CHEGADA À ACADEMIA
## elenco: "disc_john" (discípulo com o saco, John com o caixote), "john_viz" (Carreira 1), "disc_ultimo"
func lutador_b(elenco: String) -> Dictionary:
	return b_john_bare if elenco == "john_viz" else b_disc_bare

func carregador(elenco: String, pose: String) -> Image:
	if elenco == "john_viz":
		return quadro("neighbor_2", 0)
	var b: Dictionary = b_john_bare if elenco == "disc_john" else b_last
	if pose == "sit":
		return quadro("john_sit_rest", 0) if elenco == "disc_john" else pose_sit(b)
	return pose_carry_front(b)

func quadro_a2(elenco: String) -> Image:
	var im := academia_base({"escuro": true, "porta": true})
	var pl := V(372, 254)
	var pc := V(416, 232)
	monta(im, [it_spr("coach_idle", 0, P_COACH),
		it_c(com_carga(pose_carry_shoulder(lutador_b(elenco)), saco_deitado(), V(-30, -70), true), pl, true),
		it_c(com_carga(carregador(elenco, "carry"), caixote_img(), V(4, -44)), pc, true)])
	foto_na_mao(im)
	return im

func foto_na_mao(im: Image) -> void:
	# a foto ainda na mão do Osmar (rascunho: a moldura na altura do peito)
	P.paste(im, foto_reta(), 201, 190)

func chegada() -> Array:
	var out := []
	# A1 casa vazia
	var im := academia_base({"escuro": true, "porta": true, "tubo_esq_pisca": true})
	monta(im, [it_spr("coach_idle", 0, P_COACH)])
	foto_na_mao(im)
	out.append([im, "A1  CASA VAZIA", "0,0-1,2 s  sala 1x, interface apagada  um tubo só; o Osmar já está lá, com a foto na mão; a porta da rua abre"])
	# A2 a mudança entra
	im = quadro_a2("disc_john")
	out.append([im, "A2  A MUDANÇA ENTRA", "1,2-3,0 s  sala 1x  primeiro quem traz o caixote, depois o lutador com o saco remendado no ombro  som: passos"])
	# A3 a esteira não passa
	im = academia_base({"escuro": true, "porta": true})
	var est: Image = quadro("treadmill_l0_side", 0)
	monta(im, [it_spr("coach_look", 0, P_COACH),
		it_c(com_carga(pose_carry_shoulder(b_disc_bare), saco_deitado(), V(-30, -70), true), P_WAIT, true),
		it_c(com_carga(pose_carry_front(b_john_bare), caixote_img(), V(4, -44)), V(292, 250), true),
		it_spr("neighbor_1", 1, V(432, 224)),
		it_obj(est, V(428 - 43, 224 - 52), 225.0)])
	foto_na_mao(im)
	for d in [V(398, 186), V(458, 190)]:
		por(im, "fx_impact", 1, d)
	out.append([im, "A3  A ESTEIRA NÃO PASSA", "3,0-5,8 s  sala 1x  ao fundo: bate na porta, recua, bate de novo (2x)  o caixote chega ao lugar e quem trouxe senta"])
	# A4 2x: pendura a foto
	var base := academia_base({"escuro": true, "porta": true, "foto": 1})
	monta(base, [it_spr("coach_point", 2, P_COACH), it_caixote(), it_spr("john_sit_rest", 0, P_MENTOR),
		it_c(com_carga(pose_carry_shoulder(b_disc_bare), saco_deitado(), V(-30, -70), true), P_WAIT, true)])
	out.append([corte_2x(base, CUT_A), "A4  PENDURA A FOTO", "5,8-6,8 s  CORTE 2x (único da cena)  o Osmar encosta a moldura no prego: ela fica reta  som: uma batida só, moldura raspando"])
	# A5 2x: passo atrás, olha
	base = academia_base({"escuro": true, "porta": true, "foto": 1})
	monta(base, [it_spr("coach_look", 0, P_COACH + V(-8, 4)), it_caixote(), it_spr("john_sit_rest", 0, P_MENTOR),
		it_c(com_carga(pose_carry_shoulder(b_disc_bare), saco_deitado(), V(-30, -70), true), P_WAIT, true)])
	out.append([corte_2x(base, CUT_A), "A5  PASSO ATRÁS", "6,8-8,2 s  mesmo plano 2x  recua 8 px, inclina a cabeça e olha  0,9 s sem som novo: reta não é a foto deles"])
	# A6 2x: entorta + fala
	base = academia_base({"escuro": true, "porta": true, "foto": 2})
	monta(base, [it_spr("coach_talk", 1, P_COACH), it_caixote(), it_spr("john_sit_rest", 0, P_MENTOR),
		it_c(com_carga(pose_carry_shoulder(b_disc_bare), saco_deitado(), V(-30, -70), true), P_WAIT, true)])
	var a6 := corte_2x(base, CUT_A)
	balao(a6, ["agora sim."], "osmar", "gold", V(128 + (197 - 128) * 2, 18 + (173 - 118) * 2 - 4), SALA)
	out.append([a6, "A6  ENTORTA: \"AGORA SIM.\"", "8,2-10,4 s  mesmo plano 2x  volta, empurra o canto com um dedo: torta como na garagem  fala: aca_agora_sim"])
	# A7 1x: o tubo acende, o saco no gancho, a esteira de lado
	im = academia_base({"porta": true, "foto": 2})
	corrente(im, 335, 183)
	monta(im, [it_spr("coach_idle", 0, P_COACH), it_caixote(), it_spr("john_sit_rest", 0, P_MENTOR), it_saco(),
		it_g(pose_lift(b_disc_bare), P_FIGHT),
		it_spr("neighbor_1", 2, V(430, 240)),
		it_obj(girado(est), V(440, 158), 241.0)])
	por(im, "fx_arrive_dust_small", 2, V(336, 262))
	out.append([im, "A7  O OUTRO TUBO ACENDE", "10,4-12,9 s  volta ao 1x  a sala clareia; o saco vai para o gancho (poeira); a esteira passa de lado  som: tubo, argola"])
	# A8 controle: escolha da arte
	im = academia_base({"foto": 2})
	corrente(im, 335, 183)
	var itens := equipe()
	itens.append_array([it_spr("coach_idle", 0, P_COACH), it_caixote(), it_spr("john_sit_rest", 0, P_MENTOR), it_saco(),
		it_spr("fighter_idle_disc", 0, P_FIGHT), it_obj(quadro("treadmill_l0_side_gym", 0), TREAD - V(43, 41), 267.0)])
	monta(im, itens)
	por(im, "rope_l0_idle_gym", 0, V(296, 166))
	ui_sala(im)
	janela_arte(im)
	out.append([im, "A8  A INTERFACE VOLTA", "12,9 s  a academia inteira, a equipe e os aparelhos; a escolha da arte abre por cima (se pendente)  pular cai aqui em 0,3 s"])
	return out

# ================================================================ SAÍDA DO JOHN (jogador no controle)
func sala_viva(john_item, extra := [], ultimo_no_caixote := false, com_ultimo := true, soco := 0) -> Image:
	var im := academia_base({"foto": 2})
	corrente(im, 337 if soco == 1 else 335, 183)
	var itens := equipe()
	itens.append_array([it_spr("coach_idle", 0, P_COACH), it_caixote(),
		[253.0, quadro("bag_l0_hit_gym" if soco == 1 else "bag_l0_idle_gym", 1 if soco == 1 else 0), V(336 - 20, 183), null],
		it_spr("fighter_punch_disc" if soco == 1 else "fighter_idle_disc", 2 if soco == 1 else 0, P_FIGHT),
		it_obj(quadro("treadmill_l0_side_gym", 0), TREAD - V(43, 41), 267.0)])
	if com_ultimo:
		itens.append(it_g(pose_sit(b_last), P_MENTOR) if ultimo_no_caixote else it_g(pose_stand(b_last), P_MENTOR2))
	if john_item != null:
		itens.append(john_item)
	itens.append_array(extra)
	monta(im, itens)
	por(im, "rope_l0_idle_gym", 0, V(296, 166))
	if soco == 1:
		por(im, "fx_impact", 1, V(323, 222))
		L.text(im, "+1.2K", 300, 190, "y1", 1, "ink")
	return im

func john_bolsa(pose: Image, esquerda: bool) -> Image:
	# bolsa no ombro de trás (rascunho)
	return com_carga(pose, bolsa_img(), V(-17, -49) if not esquerda else V(-17, -49))

func saida() -> Array:
	var out := []
	# J1 levanta e pega a bolsa
	var im := sala_viva(it_g(pose_pick(b_john_bare), P_MENTOR), [it_obj(bolsa_img(), V(268, 242), 253.0)], false, true, 1)
	ui_sala(im)
	out.append([im, "J1  LEVANTA E PEGA A BOLSA", "0,0-1,6 s  jogador no controle (o soco vale)  o John sai do caixote e pega uma bolsa que estava atrás dele"])
	# J2 anda por trás do saco
	im = sala_viva(it_c(john_bolsa(pose_walk(b_john_bare), false), V(322, 247)), [], false, true, 0)
	ui_sala(im)
	out.append([im, "J2  ATRAVESSA A SALA", "1,6-4,3 s  anda a 48 px/s por trás do saco e do lutador (y 246): nunca cobre o alvo  som: passos"])
	# J3 para e olha a sala
	im = sala_viva(it_c(john_bolsa(pose_stand(b_john_bare), true), P_STOP, true), [], false, true, 1)
	ui_sala(im)
	out.append([im, "J3  OLHA A SALA", "4,3-5,6 s  para perto da porta, vira e olha (1,3 s)  sem close, sem música; o treino segue na frente dele"])
	# J4 fala
	im = sala_viva(it_c(john_bolsa(pose_stand(b_john_bare), true), P_STOP, true), [], false, true, 0)
	ui_sala(im)
	balao(im, ["vou procurar meu rumo."], "john", "red", P_STOP + V(-2, -70), SALA, 372)
	out.append([im, "J4  \"VOU PROCURAR MEU RUMO.\"", "5,6-10,0 s  2 balões passivos seguidos: saida_rumo_1 e saida_rumo_2 (\"cuidem bem disso aqui.\")  empurrados para fora do alvo"])
	# J5 resposta do Osmar + aceno
	im = sala_viva(it_c(john_bolsa(pose_stand(b_john_bare, "smile"), true), P_STOP + V(0, 0), true), [], false, true, 1)
	ui_sala(im)
	balao(im, ["vê se manda notícia."], "osmar", "gold", V(197, 173), SALA)
	out.append([im, "J5  \"VÊ SE MANDA NOTÍCIA.\"", "10,0-12,4 s  o Osmar responde sem sair do lugar (saida_resposta, passivo)  o John acena com a cabeça, uma vez"])
	# J6 sai pela porta
	im = sala_viva(null, [], false, true, 0)
	porta_aberta(im, false)
	monta(im, [it_c(john_bolsa(pose_walk(b_john_bare), false), V(424, 226)), it_spr("uncle_1", 0, V(455, 236))])
	ui_sala(im)
	out.append([im, "J6  SAI PELA PORTA DA RUA", "12,4-13,9 s  vira, abre a porta e sai; a porta fecha sozinha  som: porta. Nenhum objeto fica para trás"])
	# J7 o último senta no caixote
	im = sala_viva(null, [], true, true, 1)
	ui_sala(im)
	out.append([im, "J7  O CAIXOTE TEM OUTRO DONO", "13,9-16,5 s  o último que passou o posto anda até o caixote e senta. Na Carreira 2 não há ninguém: o caixote fica vazio"])
	# J8 variante da garagem
	im = garagem_base()
	porta_garagem_emperrada(im)
	corrente(im, 335, 183)
	monta(im, [it_spr("coach_idle", 0, P_COACH), it_obj(caixote_img(), V(238, 232), 250.0),
		[253.0, quadro("bag_l0_idle", 0), V(336 - 20, 183), null], it_spr("fighter_idle_disc", 0, P_FIGHT),
		it_g(pose_stand(b_last), P_MENTOR2),
		it_c(john_bolsa(pose_duck(b_john_bare), false), V(408, 232))])
	ui_sala(im)
	out.append([im, "J8  NA GARAGEM (RESERVA: CARREIRA 4)", "mesmos tempos  a única diferença é o J6: a porta de enrolar sobe, emperra, e ele passa por baixo, como sempre fez"])
	return out

# ================================================================ folhas
func folha_prancha(quadros: Array, titulo: String, sub: String, path: String) -> void:
	var cols := 2
	var cw := 640
	var chh := 360 + 30
	var rows := int(ceil(quadros.size() / float(cols)))
	var W := 12 + cols * (cw + 12)
	var H := 44 + rows * (chh + 10)
	var o: Image = L.blank(W, H)
	L.R(o, 0, 0, W, H, "d1")
	L.text(o, titulo, 12, 8, "y1", 2, "ink")
	L.text(o, sub, 12, 28, "g2", 1, "ink")
	for i in quadros.size():
		var x := 12 + (i % cols) * (cw + 12)
		var y := 44 + (i / cols) * (chh + 10)
		L.R(o, x - 1, y - 1, cw + 2, 362, "g0")
		P.paste(o, quadros[i][0], x, y)
		L.text(o, quadros[i][1], x, y + 366, "cream", 1, "ink")
		L.text(o, quadros[i][2], x, y + 378, "g2", 1, "ink")
	o.save_png(path)

func elenco(path: String) -> void:
	var reg := Rect2i(320, 154, 192, 136)
	var W := 12 + 3 * (384 + 12)
	var H := 44 + 272 + 30
	var o: Image = L.blank(W, H)
	L.R(o, 0, 0, W, H, "d1")
	L.text(o, "PRANCHA 6C1 - QUEM CARREGA O QUÊ NA CHEGADA (QUADRO A2)", 12, 8, "y1", 2, "ink")
	L.text(o, "a cena é a mesma; só muda quem entra. O lutador da campanha traz o saco; o caixote vem com quem senta nele. Recorte de 192x136 em 2x", 12, 28, "g2", 1, "ink")
	var cel := [
		["john_viz", "CARREIRA 1: o John traz o saco; um vizinho traz o caixote"],
		["disc_john", "DISCÍPULO, COM O JOHN NA ESCOLA: o John traz o caixote dele"],
		["disc_ultimo", "DEPOIS DA SAÍDA: o último que passou o posto traz o caixote"],
	]
	for i in 3:
		var x := 12 + i * 396
		P.paste(o, P.scaled(quadro_a2(cel[i][0]).get_region(reg), 2), x, 44)
		L.text(o, cel[i][1], x, 44 + 277, "cream", 1, "ink")
	o.save_png(path)

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		OUT = args[0].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	M = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	var oj: Dictionary = P.identidade("primeiro")
	oj["glove"] = "fist"
	b_john_bare = P.build(oj)
	var od: Dictionary = P.identidade("disc")
	od["glove"] = "fist"
	b_disc_bare = P.build(od)
	var ou: Dictionary = P.identidade("disc")
	ou.merge({"glove": "fist", "hair": ["d1", "d2"], "brow": "ink", "shorts": ["b1", "b2", "b3"], "band": "b3"}, true)
	b_last = P.build(ou)
	var a := chegada()
	var j := saida()
	for i in a.size():
		(a[i][0] as Image).save_png(OUT + "prancha_6c1_chegada_A%02d.png" % (i + 1))
	for i in j.size():
		(j[i][0] as Image).save_png(OUT + "prancha_6c1_saida_J%02d.png" % (i + 1))
	folha_prancha(a, "PRANCHA 6C1 - PRIMEIRA CHEGADA À ACADEMIA", "rascunho de composição (não é arte final)   academia, câmera fixa, 1 corte   controle preso: 12,9 s (teto 15 s)", OUT + "prancha_6c1_chegada.png")
	folha_prancha(j, "PRANCHA 6C1 - SAÍDA DO JOHN", "rascunho de composição (não é arte final)   ação no cenário, jogador no controle o tempo todo   0 s presos, sem barras, sem corte", OUT + "prancha_6c1_saida.png")
	elenco(OUT + "prancha_6c1_elenco.png")
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	print("ok: %d + %d quadros em %s" % [a.size(), j.size(), OUT])
	quit()
