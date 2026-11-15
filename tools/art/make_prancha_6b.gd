extends SceneTree
## Prancha de quadros-chave da 6b (Diretor de Cutscenes): "Primeira sucessão" e "Reencontro final".
## NÃO é arte final: composição, luz e silhuetas para o dono aprovar antes do escopo da 6b.
## Poses novas = um quadro só, em rascunho, feito com personagem_lib (não entram no manifest nem em assets/).
## Texto: docs/cutscenes/prancha-6b.md.
## Rodar de uma pasta temporária com project.godot vazio (nunca no projeto):
##   Godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_prancha_6b.gd -- [pasta_de_saida]
## Sem argumento grava em docs/arte/mockups/:
##   prancha_6b_sucessao.png, prancha_6b_reencontro.png (folhas 2 colunas, 640x360 por quadro, com legenda)
##   prancha_6b_pares.png (os 3 pares que ligam as duas cenas, recorte 192x136 em 2x)
##   prancha_6b_sucessao_S01..S10.png, prancha_6b_reencontro_R01..R10.png (quadros soltos 640x360)

const ROOT := "E:/Fightclicker/"
const GPIV := Vector2(22, 67)
const FPIV := Vector2(56, 98)
const LIGHT_C := Vector2(305, 90)
const SALA := Rect2i(128, 18, 384, 272)       # janela de cena na garagem
const JAN := Rect2i(128, 52, 384, 272)        # janela de cena na tela de luta
const CUT_G := Rect2i(222, 154, 192, 136)     # plano 2x da sucessão
const CUT_F := Rect2i(327, 123, 192, 136)     # plano 2x do reencontro
# porta de enrolar da garagem (pintada no garage_bg): miolo x 382..463, y 100..219
const GD_X0 := 382
const GD_X1 := 463
const GD_Y0 := 100
const GD_Y1 := 219
const GD_JAM := 171       # borda de baixo da porta emperrada (ombro de quem está de pé na soleira)
# porta de enrolar da última arena: mesmo x; base em y 253
const FD_Y0 := 154
const FD_Y1 := 253
const FD_JAM := 194
const P_JOHN := Vector2(303, 272)
const P_MENTOR := Vector2(268, 268)
const P_COACH := Vector2(196, 236)
const P_DISC_F := Vector2(296, 318)
const P_JOHN_F := Vector2(346, 318)
const P_DOOR_F := Vector2(423, 256)

var L
var P
var M: Dictionary
var OUT := ROOT + "docs/arte/mockups/"
var cache := {}
var b_john: Dictionary
var b_john_bare: Dictionary
var b_disc_bare: Dictionary
var b_old: Dictionary

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

func tom(im: Image, n: int) -> Image:
	var o: Image = im.duplicate()
	L.shade_rect(o, 0, 0, o.get_width(), o.get_height(), n)
	return o

func com_luz(im: Image, pos: Vector2) -> Image:
	var o: Image = im.duplicate()
	var tl := pos - GPIV
	L.light(o, Rect2i(0, 0, o.get_width(), o.get_height()), LIGHT_C - tl, 300.0, 1.1, 3.6, -1, 1, 0.9)
	return o

# ================================================================ poses novas (rascunho, 1 quadro)
func gpose(o: Dictionary) -> Dictionary:
	var p := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47),
		"hl": V(-8, -50), "hr": V(10, -51), "toel": V(-1, 0), "toer": V(10, 0)}
	for k in o:
		p[k] = o[k]
	return p

func fpose(o: Dictionary) -> Dictionary:
	var p := {"hip": V(0, -37), "top": V(2, -61), "toef": V(15, -1), "toeb": V(-3, -1), "head": V(5, -71),
		"hf": V(16, -59), "hb": V(12, -61)}
	for k in o:
		if o[k] == null:
			p.erase(k)
		else:
			p[k] = o[k]
	return p

func g(b: Dictionary, o: Dictionary, tag: String) -> Image:
	return P.garage_frame(b, gpose(o), tag)

func f(b: Dictionary, o: Dictionary, tag: String, flip := true) -> Image:
	var im: Image = P.fight_frame(b, fpose(o), tag, Vector2i(112, 104), FPIV)
	return L.flipped(im) if flip else im

func mao_aberta() -> Callable:
	return func(lib, _O: Vector2, ctx: Dictionary) -> void:
		var hr: Vector2 = ctx.hr
		var d: Vector2 = (hr - (ctx.elr as Vector2)).normalized()
		for k in range(2, 6):
			for s in [-1, 0, 1]:
				var q := (hr + d * float(k) + V(0, s)).round()
				lib.put(int(q.x), int(q.y), "sk2" if s < 1 else "sk1", 75)

const BARE := {"hl": Vector2(-9, -28), "hr": Vector2(11, -28), "gkl": "", "gkr": ""}

func pose_hold_bag() -> Image:      # segura o saco com as duas luvas, cabeça um pouco baixa
	return g(b_john, {"top": V(3, -49), "head": V(5, -55), "sl": V(-5, -46), "sr": V(10, -46),
		"hl": V(13, -40), "hr": V(14, -51), "gkl": "side", "gkr": "side", "pl": V(-0.2, 1.0)}, "hold_bag")

func pose_john_bare(face := "normal") -> Image:   # mãos nuas, braços soltos, olhando a porta
	var o := BARE.duplicate()
	o["face"] = face
	o["head"] = V(2, -57)
	return g(b_john_bare, o, "look_door")

func pose_point() -> Image:         # mão aberta apontando o lugar em frente ao saco
	return g(b_john_bare, {"hl": V(-9, -28), "hr": V(20, -36), "pr": V(0.2, 1.0), "gkl": "", "gkr": "side",
		"face": "smile", "head": V(2, -57), "end": mao_aberta()}, "point_spot")

func pose_sit(taps: bool) -> Image: # sentado no caixote, antebraços nos joelhos; taps = dois toques de punho
	var o := {"hip": V(0, -18), "top": V(3, -36), "head": V(5, -43), "sl": V(-5, -33), "sr": V(10, -33),
		"hl": V(2, -19), "hr": V(13, -20), "toel": V(-3, 0), "toer": V(12, 0), "kl": V(1, -0.2), "kr": V(1, -0.2),
		"gkl": "", "gkr": "", "face": "smile"}
	if taps:
		o["hl"] = V(6, -26)
		o["hr"] = V(10, -27)
	return g(b_john_bare, o, "sit_rest")

func pose_disc_stand() -> Image:
	return g(b_disc_bare, BARE, "disc_stand")

func pose_disc_duck() -> Image:     # passa por baixo da porta: tronco dobrado, uma mão na borda
	return g(b_disc_bare, {"hip": V(0, -19), "top": V(9, -33), "head": V(13, -38), "sl": V(2, -33), "sr": V(15, -30),
		"hl": V(3, -14), "hr": V(19, -43), "pr": V(1, 0.3), "toel": V(-3, 0), "toer": V(11, 0), "kl": V(1, 0),
		"kr": V(1, 0), "gkl": "", "gkr": ""}, "duck_under")

func pose_disc_walk() -> Image:
	return g(b_disc_bare, {"top": V(2, -50), "head": V(3, -57), "sl": V(-6, -47), "sr": V(9, -47), "hl": V(-3, -29),
		"hr": V(13, -30), "toel": V(-5, 0), "toer": V(12, 0), "gkl": "", "gkr": ""}, "walk")

func pose_disc_reach() -> Image:    # estica o braço e pega as luvas no saco
	return g(b_disc_bare, {"hl": V(-8, -29), "hr": V(19, -60), "pr": V(1, 0.5), "gkl": "", "gkr": ""}, "take_gloves")

const OLD_LOW := {"hip": Vector2(0, -38), "top": Vector2(1, -62), "head": Vector2(3, -72), "toef": Vector2(10, -1),
	"toeb": Vector2(-4, -1), "hf": Vector2(7, -36), "hb": Vector2(-1, -37), "gkf": "down", "gkb": "down"}

func pose_old_low() -> Image:
	return f(b_old, OLD_LOW, "old_low")

func pose_old_bite() -> Image:      # quadro 2 do gesto (puxa o fecho)
	return f(b_old, {"head": V(5, -70), "face": "bite", "top": V(2, -60), "hf": V(19, -68), "hb": V(11, -57),
		"pf": V(0.3, 1.0), "gkf": "up"}, "old_bite")

func pose_old_tap() -> Image:       # quadro 5/7 do gesto (toque)
	return f(b_old, {"hf": V(17, -59), "hb": V(15, -52), "far_glove_front": true}, "old_tap")

func pose_old_duck() -> Image:
	return f(b_old, {"hip": V(-3, -25), "top": V(15, -41), "head": null, "hrot_auto": true, "toef": V(14, -1),
		"toeb": V(-9, -1), "hf": V(25, -57), "hb": V(10, -19), "gkf": "up", "gkb": "down"}, "old_duck")

func pose_old_look() -> Image:      # olha o símbolo: cabeça baixa um pouco
	var o := OLD_LOW.duplicate()
	o["head"] = V(4, -71)
	o["hrot"] = 14.0
	return f(b_old, o, "look_emblem")

func pose_old_guard() -> Image:
	return f(b_old, {"face": "smile"}, "old_guard")

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

func luvas_penduradas(dst: Image) -> void:
	# o par dele, amarrado pelo cadarço na argola do saco, caindo no ombro esquerdo do saco
	L.line(dst, 335, 186, 327, 200, "cream")
	L.line(dst, 335, 186, 331, 204, "g3")
	por(dst, "glove_old", 0, V(325, 206))
	por(dst, "glove_old", 0, V(331, 211))

func corrente(dst: Image, x: int, y_fim: int) -> void:
	var t: Image = quadro("bag_chain_tile", 0)
	var y := 33
	while y < y_fim:
		P.paste(dst, t.get_region(Rect2i(0, 0, 4, mini(6, y_fim - y))), x - 1, y)
		y += 6

func luz_chao(dst: Image, y0: int, y1: int, xl0: float, xr0: float, xl1: float, xr1: float, n: int, borda := 5) -> void:
	# mancha de luz em trapézio: anda n passos na rampa; a borda entra em dither
	for y in range(y0, y1 + 1):
		var t := 0.0 if y1 == y0 else float(y - y0) / float(y1 - y0)
		var a := int(round(lerpf(xl0, xl1, t)))
		var b := int(round(lerpf(xr0, xr1, t)))
		for x in range(a, b + 1):
			if x < 0 or y < 0 or x >= dst.get_width() or y >= dst.get_height():
				continue
			var d := mini(x - a, b - x)
			if d < borda and (x + y) % 2 == 1:
				continue
			var c := dst.get_pixel(x, y)
			if c.a > 0.0:
				dst.set_pixel(x, y, L.shade(c, n))

func porta_garagem_emperrada(dst: Image, dentro: Image, dentro_pos: Vector2) -> void:
	# abre o miolo da porta de GD_JAM até a soleira: luz do dia branca; quem está fora aparece do ombro para baixo
	L.R(dst, GD_X0, GD_JAM, GD_X1 - GD_X0 + 1, GD_Y1 - GD_JAM + 1, "white")
	L.R(dst, GD_X0, GD_JAM + 18, GD_X1 - GD_X0 + 1, GD_Y1 - GD_JAM - 17, "y2")
	L.dither(dst, GD_X0, GD_JAM + 14, GD_X1 - GD_X0 + 1, 4, "y2")
	L.R(dst, GD_X0, GD_Y1 - 6, GD_X1 - GD_X0 + 1, 7, "cream")       # calçada
	L.dither(dst, GD_X0, GD_Y1 - 8, GD_X1 - GD_X0 + 1, 2, "cream")
	if dentro != null:
		var clip := Rect2i(GD_X0, GD_JAM, GD_X1 - GD_X0 + 1, GD_Y1 - GD_JAM + 3)
		colar_clip(dst, tom(dentro, -1), int(dentro_pos.x) - 22, int(dentro_pos.y) - 67, clip)
	L.R(dst, GD_X0 - 1, GD_JAM - 3, GD_X1 - GD_X0 + 3, 3, "st0")       # barra de baixo da porta
	L.R(dst, GD_X0 - 1, GD_JAM, GD_X1 - GD_X0 + 3, 1, "ink")
	L.R(dst, GD_X0 + 36, GD_JAM - 2, 10, 1, "st2")

func luz_do_dia(dst: Image) -> void:
	luz_chao(dst, 220, 289, GD_X0 - 2, GD_X1 + 1, GD_X0 - 74, GD_X1 + 14, 1, 7)
	luz_chao(dst, 220, 262, GD_X0 + 6, GD_X1 - 6, GD_X0 - 26, GD_X1 - 2, 1, 6)

func sombra_longa(dst: Image, pe: Vector2, comp: int) -> void:
	# sombra das pernas de quem entra, esticada para dentro da sala (para a esquerda e para a frente)
	for i in comp:
		var x := int(pe.x) - 4 - i
		var y := int(pe.y) + 1 + i / 2
		L.shade_rect(dst, x, y, 9, 1, -1, i > comp - 8)

# ================================================================ GARAGEM
func garagem_base(lamp_q := 0) -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	por(im, "garage_bg", 0, V(128, 18))
	for id in ["wall_notice_debt", "wall_form_blank", "wall_photo_old"]:
		var e: Dictionary = M.sprites[id]
		por(im, id, 0, V(e.pos[0], e.pos[1]))
	por(im, "lamp", lamp_q, V(300, 32))
	return im

## itens = [[y de ordem, Image, canto de cima à esquerda], ...]
func monta(im: Image, itens: Array) -> void:
	itens.sort_custom(func(a, b): return a[0] < b[0])
	for it in itens:
		if it.size() > 3 and it[3]:
			por(im, "floor_shadow", 0, it[3])
		P.paste(im, it[1], int((it[2] as Vector2).x), int((it[2] as Vector2).y))

func it_g(im: Image, pos: Vector2) -> Array:      # personagem da garagem pelo ponto dos pés
	return [pos.y, im, pos - GPIV, pos + V(0, -1)]

func it_saco(q: int, hit := false) -> Array:
	return [253.0, quadro("bag_l0_hit" if hit else "bag_l0_idle", q), V(336 - 20, 183)]

func it_coach(id: String) -> Array:
	return it_g(quadro(id, 0), P_COACH)

func corte_2x(im: Image, reg: Rect2i, jan: Rect2i) -> Image:
	var o: Image = L.blank(640, 360)
	L.R(o, 0, 0, 640, 360, "ink")
	P.paste(o, P.scaled(im.get_region(reg), 2), jan.position.x, jan.position.y)
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
func ui_sala(im: Image, apagando := false) -> void:
	var c := "d1"
	for r in [Rect2i(0, 0, 640, 18), Rect2i(0, 18, 128, 272), Rect2i(512, 18, 128, 272), Rect2i(0, 290, 640, 70)]:
		L.panel(im, r.position.x, r.position.y, r.size.x, r.size.y, c)
	L.text(im, "TREINO   $   FAMA", 8, 6, "g2")
	L.text_center(im, "PAINEL", 64, 30, "g1")
	L.text_center(im, "EQUIPE", 576, 30, "g1")
	for i in 5:
		L.R(im, 8, 46 + i * 22, 112, 16, "d2")
		L.R(im, 520, 46 + i * 22, 112, 16, "d2")
	for i in 3:
		L.button(im, 180 + i * 96, 304, 88, 30, "d2", "FOCO", "g2")
	L.button(im, 520, 302, 104, 34, "r1", "LUTAR!", "white")
	L.text_center(im, "(a interface volta: rascunho)", 320, 344, "g1")
	if apagando:
		L.dither(im, 0, 0, 640, 18, "ink")

func tela_criacao(im: Image) -> void:
	L.dither(im, SALA.position.x, SALA.position.y, SALA.size.x, SALA.size.y, "ink")
	var x := 200
	var y := 46
	L.panel(im, x, y, 240, 216, "d1")
	L.R(im, x + 2, y + 2, 236, 14, "p0")
	L.text_center(im, "RECEBER NOVO DISCÍPULO", 320, y + 6, "white")
	L.R(im, x + 12, y + 26, 72, 96, "d2")
	P.paste(im, P.scaled(quadro("fighter_idle_disc", 0).get_region(Rect2i(4, 2, 40, 68)), 1), x + 28, y + 40)
	var rot := ["NOME", "PELE", "CABELO", "CALÇÃO"]
	for i in 4:
		L.text(im, rot[i], x + 96, y + 32 + i * 24, "g2")
		L.R(im, x + 96, y + 42 + i * 24, 132, 10, "d2")
		L.text(im, "<", x + 100, y + 44 + i * 24, "cream")
		L.text(im, ">", x + 220, y + 44 + i * 24, "cream")
	L.text(im, "LUVA: O PAR DO JOHN", x + 12, y + 134, "r3")
	L.text(im, "(tela do UI/UX: só o lugar dela na cena)", x + 12, y + 150, "g1")
	L.button(im, x + 64, y + 176, 112, 26, "gr1", "CONFIRMAR", "white")

# ================================================================ SUCESSÃO
func sucessao() -> Array:
	var out := []
	# S1 últimos socos
	var im := garagem_base(1)
	corrente(im, 337, 183)
	monta(im, [it_coach("coach_idle"), it_saco(1, true), it_g(quadro("fighter_punch", 2), P_JOHN)])
	por(im, "fx_impact", 0, V(323, 222)) if M.sprites.has("fx_impact") else null
	out.append([im, "S1  ÚLTIMOS SOCOS", "0,0-1,8 s  sala 1x, interface apagada  som: 3 socos, corrente rangendo, lâmpada balança"])
	# S2 segura o saco
	im = garagem_base(0)
	corrente(im, 335, 183)
	monta(im, [it_coach("coach_idle"), it_saco(0), it_g(pose_hold_bag(), P_JOHN)])
	out.append([im, "S2  SEGURA O SACO", "1,8-3,6 s  sala 1x  o saco e a lâmpada param juntos  som: bag_catch, depois só o zumbido"])
	# S3 2x: abre o fecho
	var base := garagem_base(0)
	corrente(base, 335, 183)
	monta(base, [it_coach("coach_idle"), it_saco(0), it_g(quadro("fighter_gesture", 2), P_JOHN)])
	var s3 := corte_2x(base, CUT_G, SALA)
	out.append([s3, "S3  ABRE O FECHO COM OS DENTES", "3,6-6,6 s  CORTE 2x (único da cena)  o gesto dele ao contrário  som: strap_open, couro"])
	# S4 luvas penduradas, olha a porta, sombra de pés
	im = garagem_base(0)
	corrente(im, 335, 183)
	L.R(im, GD_X0, GD_Y1 - 3, GD_X1 - GD_X0 + 1, 4, "white")
	L.R(im, 412, GD_Y1 - 3, 7, 4, "d1")
	L.R(im, 425, GD_Y1 - 3, 7, 4, "d1")
	luz_chao(im, 220, 236, GD_X0, GD_X1, GD_X0 - 14, GD_X1 + 2, 1, 4)
	sombra_longa(im, V(415, 220), 14)
	sombra_longa(im, V(428, 220), 14)
	monta(im, [it_coach("coach_look"), it_saco(0), it_g(pose_john_bare(), P_JOHN)])
	luvas_penduradas(im)
	out.append([im, "S4  ALGUÉM NA PORTA", "6,6-9,0 s  sala 1x  luvas no saco; sombra de dois pés na fresta; ele e o Osmar olham  som: door_shake"])
	# S5 tela de criação
	var s5: Image = im.duplicate()
	tela_criacao(s5)
	out.append([s5, "S5  RECEBER NOVO DISCÍPULO (tela)", "sem tempo: espera o jogador  a cena fica parada atrás, John olhando a porta"])
	# S6 porta emperra, discípulo do ombro para baixo
	im = garagem_base(0)
	corrente(im, 335, 183)
	porta_garagem_emperrada(im, L.flipped(pose_disc_stand()), V(423 + 4, 219))
	luz_do_dia(im)
	sombra_longa(im, V(423, 221), 34)
	monta(im, [it_coach("coach_look"), it_saco(0), it_g(pose_john_bare(), P_JOHN)])
	luvas_penduradas(im)
	out.append([im, "S6  A PORTA EMPERRA", "parte 2: 0,0-1,3 s  sala 1x  a luz do dia entra pela 1ª vez; só o corpo de quem chega  som: door_roll, door_jam (tranco 1 px)"])
	# S7 passa por baixo
	im = garagem_base(0)
	corrente(im, 335, 183)
	porta_garagem_emperrada(im, null, V(0, 0))
	luz_do_dia(im)
	var pd := V(414, 228)
	sombra_longa(im, pd, 30)
	monta(im, [it_coach("coach_look"), it_saco(0), it_g(pose_john_bare("smile"), P_JOHN),
		[pd.y, L.flipped(pose_disc_duck()), pd - V(48 - 22, 67), pd + V(0, -1)]])
	luvas_penduradas(im)
	out.append([im, "S7  PASSA POR BAIXO", "parte 2: 1,3-2,6 s  sala 1x  o gesto de chegar nesta escola; John sorri de leve  som: 2 passos"])
	# S8 aponta o lugar + fala
	im = garagem_base(0)
	corrente(im, 335, 183)
	porta_garagem_emperrada(im, null, V(0, 0))
	luz_do_dia(im)
	var pw := V(378, 258)
	monta(im, [it_coach("coach_idle"), it_saco(0), it_g(pose_point(), P_MENTOR),
		[pw.y, L.flipped(pose_disc_walk()), pw - V(48 - 22, 67), pw + V(0, -1)]])
	luvas_penduradas(im)
	balao(im, ["vamos ver sua guarda."], "john", "red", P_MENTOR + V(1, -65), SALA, 214)
	out.append([im, "S8  \"VAMOS VER SUA GUARDA.\"", "parte 2: 2,6-4,6 s  sala 1x  John sai do lugar dele e aponta com a mão aberta  som: passos, voz do John"])
	# S9 pega as luvas
	im = garagem_base(0)
	corrente(im, 335, 183)
	porta_garagem_emperrada(im, null, V(0, 0))
	luz_do_dia(im)
	monta(im, [it_coach("coach_idle"), it_saco(0), it_g(pose_john_bare("smile"), P_MENTOR),
		it_g(pose_disc_reach(), P_JOHN)])
	L.line(im, 335, 186, 327, 200, "cream")
	por(im, "glove_old", 0, V(331, 211))
	out.append([im, "S9  PEGA O PAR DELE", "parte 2: 4,6-6,2 s  sala 1x  o discípulo ocupa o lugar e calça a luva velha  som: couro; a interface volta"])
	# S10 controle devolvido: John sentado, dois toques
	im = garagem_base(0)
	corrente(im, 335, 183)
	L.R(im, GD_X0, GD_Y1 - 1, GD_X1 - GD_X0 + 1, 2, "white")
	caixote(im, P_MENTOR + V(-1, -2))
	monta(im, [it_coach("coach_idle"), it_saco(1, true), it_g(pose_sit(true), P_MENTOR),
		it_g(quadro("fighter_punch_disc", 2), P_JOHN)])
	ui_sala(im)
	balao(im, ["isso."], "john", "red", P_MENTOR + V(5, -51), SALA)
	out.append([im, "S10  1º CLIQUE: \"ISSO.\"", "jogador no controle  John senta no caixote e bate dois toques de punho  som: tap_fist x2 (0,22 s)"])
	return out

# ================================================================ ÚLTIMA ARENA (rascunho)
func arena_final(aceso: bool) -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	L.R(im, 0, 46, 640, 208, "g1")                     # parede de concreto
	for x in range(32, 640, 96):
		L.R(im, x, 46, 1, 208, "g0")
	L.R(im, 0, 148, 640, 1, "g0")
	for x in range(80, 640, 96):
		for y in [96, 200]:
			L.R(im, x, y, 2, 2, "g0")
	L.dither(im, 0, 238, 640, 16, "g0")                 # umidade no pé da parede
	L.R(im, 0, 254, 640, 106, "g0")                    # chão
	L.R(im, 0, 254, 640, 1, "d2")
	for y in [272, 300, 338]:
		L.R(im, 0, y, 640, 1, "d2")
	for k in range(-6, 7):
		L.line(im, 320 + k * 46, 254, 320 + k * 110, 359, "d2")
	# porta de enrolar: mesmo x da garagem
	L.R(im, GD_X0 - 3, FD_Y0 - 3, GD_X1 - GD_X0 + 7, FD_Y1 - FD_Y0 + 4, "ink")
	L.R(im, GD_X0 - 1, FD_Y0 - 1, GD_X1 - GD_X0 + 3, FD_Y1 - FD_Y0 + 2, "d1")
	porta_final_laminas(im, FD_Y1)
	# círculo de giz
	L.ring(im, 321, 322, 124, 25, 1.4, "cream")
	L.dither(im, 197, 297, 250, 52, "g0", 1)
	# luz: uma lâmpada só
	if aceso:
		L.light(im, Rect2i(0, 46, 640, 314), V(320, 170), 330.0, 1.25, 4.4, -4, 1, 1.25)
	else:
		L.light(im, Rect2i(0, 46, 640, 314), V(320, 170), 330.0, 1.25, 2.0, -4, -2, -1.2)
	L.R(im, 320, 46, 1, 20, "d1")
	por(im, "lamp", 0, V(320, 62))
	return im

func porta_final_laminas(im: Image, ate_y: int) -> void:
	var y := FD_Y0
	while y <= ate_y:
		L.R(im, GD_X0, y, GD_X1 - GD_X0 + 1, mini(6, ate_y - y + 1), "st1")
		L.R(im, GD_X0, y, GD_X1 - GD_X0 + 1, 1, "st2")
		if y + 6 <= ate_y:
			L.R(im, GD_X0, y + 6, GD_X1 - GD_X0 + 1, 2, "st0")
		y += 8

func porta_final_emperrada(im: Image, dentro: Image, pos: Vector2) -> void:
	# abre de FD_JAM até o chão: lá fora é escuro; ele aparece do ombro para baixo
	L.R(im, GD_X0, FD_JAM, GD_X1 - GD_X0 + 1, FD_Y1 - FD_JAM + 1, "ink")
	L.dither(im, GD_X0, FD_Y1 - 10, GD_X1 - GD_X0 + 1, 11, "d1")
	if dentro != null:
		var clip := Rect2i(GD_X0, FD_JAM, GD_X1 - GD_X0 + 1, 70)
		colar_clip(im, dentro, int(pos.x) - 56, int(pos.y) - 98, clip)
	L.R(im, GD_X0 - 1, FD_JAM - 3, GD_X1 - GD_X0 + 3, 3, "st0")
	L.R(im, GD_X0 - 1, FD_JAM, GD_X1 - GD_X0 + 3, 1, "ink")
	L.R(im, GD_X0 + 36, FD_JAM - 2, 10, 1, "st2")

func feixe(im: Image, x0: float, x1: float, meia: float) -> void:
	for y in range(46, 330):
		var t := float(y - 46) / 284.0
		var cx := lerpf(x0, x1, t)
		var hw := lerpf(5.0, meia, t)
		for x in range(int(cx - hw), int(cx + hw) + 1):
			if x < 0 or x >= 640:
				continue
			var d := hw - absf(x - cx)
			if d < 5.0 and (x + y) % 2 == 1:
				continue
			im.set_pixel(x, y, L.shade(im.get_pixel(x, y), 2 if d > hw * 0.5 else 1))

func janela(im: Image) -> void:
	L.R(im, 0, 0, 640, JAN.position.y, "ink")
	L.R(im, 0, JAN.end.y, 640, 360 - JAN.end.y, "ink")
	L.R(im, 0, 0, JAN.position.x, 360, "ink")
	L.R(im, JAN.end.x, 0, 640 - JAN.end.x, 360, "ink")

func discipulo_luta(im: Image, brilho := false) -> void:
	por(im, "fight_shadow", 0, P_DISC_F + V(0, -1))
	por(im, "fight_player_idle_disc", 0, P_DISC_F)
	var s := V(P_DISC_F.x + 1, P_DISC_F.y - 56)
	P.paste(im, quadro("school_symbol_5", 0), int(s.x), int(s.y))
	if brilho:
		for d in [V(-3, 2), V(7, 2), V(2, -3), V(2, 7), V(-2, -2), V(6, 6)]:
			L.P(im, int(s.x + d.x), int(s.y + d.y), "y2")

func john_luta(im: Image, pose: Image, pos: Vector2) -> void:
	por(im, "fight_shadow", 0, pos + V(0, -1))
	P.paste(im, pose, int(pos.x) - 56, int(pos.y) - 98)

func faisca(im: Image, p: Vector2) -> void:
	for d in [V(1, 0), V(-1, 0), V(0, 1), V(0, -1)]:
		for s in range(2, 5):
			L.P(im, int(p.x + d.x * s), int(p.y + d.y * s), "y2")
	L.P(im, int(p.x), int(p.y), "white")

func hud_luta(im: Image) -> void:
	L.R(im, 0, 0, 640, 46, "ink")
	L.panel(im, 5, 5, 34, 34, "d2")
	P.paste(im, quadro("portrait_player_disc", 0), 6, 6)
	L.panel(im, 597, 5, 34, 34, "d2")
	L.R(im, 606, 12, 16, 20, "g0")
	L.text(im, "DISCÍPULO", 46, 6, "white")
	L.text_right(im, "JOHN BULLET", 594, 6, "white")
	L.bar(im, 46, 16, 236, 12, 1.0, "r2")
	L.bar(im, 358, 16, 236, 12, 1.0, "r2")
	L.panel(im, 292, 4, 56, 32, "d1")
	L.text_center(im, "1º", 320, 10, "y1", 2)

# ================================================================ REENCONTRO
func reencontro() -> Array:
	var out := []
	# R1 holofotes procuram, ninguém
	var im := arena_final(false)
	feixe(im, 150, 400, 44)
	feixe(im, 330, 440, 40)
	feixe(im, 560, 470, 44)
	discipulo_luta(im)
	L.text_center(im, "E AGORA... O ÚLTIMO DESAFIO!", 320, 20, "y1", 2, "r1")
	out.append([im, "R1  MAIS UMA ENTRADA EXAGERADA?", "0,0-1,6 s  tela inteira  holofotes varrem a porta, tambor... e não entra ninguém  som: intro_drums que murcha"])
	# R2 apagam; janela fecha; lâmpada e discípulo
	im = arena_final(true)
	discipulo_luta(im)
	janela(im)
	out.append([im, "R2  SOBRA UMA LÂMPADA", "1,6-3,0 s  a imagem fecha na janela 384x272 (a da garagem)  discípulo sozinho, no lugar que era do John  som: 3 estalos, zumbido"])
	# R3 porta emperra; ele do ombro para baixo
	im = arena_final(true)
	porta_final_emperrada(im, pose_old_low(), P_DOOR_F)
	discipulo_luta(im)
	janela(im)
	out.append([im, "R3  A PORTA EMPERRA", "3,0-5,0 s  janela 1x  passos, couro raspando; a porta sobe e trava no mesmo lugar  som: door_roll, door_jam"])
	# R4 2x: luva sobe atrás da porta (o fecho)
	var base := arena_final(true)
	porta_final_emperrada(base, pose_old_bite(), P_DOOR_F)
	out.append([corte_2x(base, CUT_F, JAN), "R4  O FECHO (SEM ROSTO)", "5,0-6,6 s  CORTE 2x  a luva sobe e some atrás da porta  som: strap_rip (o jogador ouviu isso a Carreira 1 inteira)"])
	# R5 2x: dois toques
	base = arena_final(true)
	porta_final_emperrada(base, pose_old_tap(), P_DOOR_F)
	faisca(base, P_DOOR_F + V(-16, -56))
	out.append([corte_2x(base, CUT_F, JAN), "R5  DOIS TOQUES", "6,6-8,2 s  mesmo plano 2x  toc, toc (0,22 s) e 0,6 s de nada  é aqui que o jogador reconhece"])
	# R6 passa por baixo
	im = arena_final(true)
	porta_final_emperrada(im, null, V(0, 0))
	discipulo_luta(im)
	john_luta(im, pose_old_duck(), V(410, 262))
	janela(im)
	out.append([im, "R6  PASSA POR BAIXO", "8,2-11,0 s  volta ao 1x  a mesma pose do discípulo na sucessão; anda até a luz  som: passos"])
	# R7 rosto + nome, pausa
	im = arena_final(true)
	porta_final_emperrada(im, null, V(0, 0))
	discipulo_luta(im)
	john_luta(im, pose_old_low(), P_JOHN_F)
	janela(im)
	L.text_center(im, "John Bullet", 346, 331, "cream")
	out.append([im, "R7  O ROSTO E O NOME", "11,0-13,6 s  janela 1x  mais velho; só o nome, pequeno, na faixa preta  2,6 s sem fala e sem som novo"])
	# R8 fala 1 + olha o símbolo
	im = arena_final(true)
	porta_final_emperrada(im, null, V(0, 0))
	discipulo_luta(im, true)
	john_luta(im, pose_old_look(), P_JOHN_F)
	janela(im)
	balao(im, ["então vocês chegaram."], "john", "red", P_JOHN_F + V(-4, -82), JAN)
	out.append([im, "R8  \"ENTÃO VOCÊS CHEGARAM.\"", "13,6-17,6 s  janela 1x  depois da fala ele baixa os olhos para o símbolo da escola, que brilha 2 quadros"])
	# R9 guarda + fala 2
	im = arena_final(true)
	porta_final_emperrada(im, null, V(0, 0))
	discipulo_luta(im)
	john_luta(im, pose_old_guard(), P_JOHN_F)
	janela(im)
	balao(im, ["quero ver o que", "aprenderam."], "", "red", P_JOHN_F + V(-4, -82), JAN)
	out.append([im, "R9  \"QUERO VER O QUE APRENDERAM.\"", "17,6-20,4 s  janela 1x  ele arma a guarda e sorri de leve; ecoa \"vamos ver sua guarda\""])
	# R10 janela abre, HUD, sino
	im = arena_final(true)
	porta_final_emperrada(im, null, V(0, 0))
	discipulo_luta(im)
	john_luta(im, pose_old_guard(), P_JOHN_F)
	hud_luta(im)
	out.append([im, "R10  A JANELA ABRE: LUTA", "20,4-21,6 s  tela inteira  barras de vida com o retrato e o nome dele  som: bell_start"])
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

func recorte(im: Image, reg: Rect2i) -> Image:
	return P.scaled(im.get_region(reg), 2)

func pares(s: Array, r: Array, path: String) -> void:
	var W := 12 + 3 * (384 + 12)
	var H := 44 + 2 * (272 + 30)
	var o: Image = L.blank(W, H)
	L.R(o, 0, 0, W, H, "d1")
	L.text(o, "PRANCHA 6B - COMO AS DUAS CENAS CONVERSAM", 12, 8, "y1", 2, "ink")
	L.text(o, "em cima: primeira sucessão (garagem)   embaixo: reencontro final (última arena)   mesmo recorte de 192x136, em 2x", 12, 28, "g2", 1, "ink")
	var rg := Rect2i(327, 123, 192, 136)       # garagem: porta no mesmo ponto do recorte
	var rf := Rect2i(327, 157, 192, 136)
	var cel := [
		[recorte(s[5][0], rg), "A PORTA EMPERRA (S6): quem chega vem da luz do dia"],
		[s[2][0].get_region(SALA), "O GESTO (S3): ele ABRE o fecho e tira as luvas"],
		[recorte(s[6][0], rg), "PASSAR POR BAIXO (S7)"],
		[recorte(r[2][0], rf), "A PORTA EMPERRA (R3): quem chega vem do escuro"],
		[r[3][0].get_region(JAN), "O GESTO (R4): ele APERTA o fecho"],
		[recorte(r[5][0], rf), "PASSAR POR BAIXO (R6): a mesma pose"],
	]
	for i in 6:
		var x := 12 + (i % 3) * 396
		var y := 44 + (i / 3) * 302
		P.paste(o, cel[i][0], x, y)
		L.text(o, cel[i][1], x, y + 277, "cream", 1, "ink")
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
	b_john = P.build(oj)
	var ob: Dictionary = oj.duplicate()
	ob["glove"] = "fist"
	b_john_bare = P.build(ob)
	var od: Dictionary = P.identidade("disc")
	od["glove"] = "fist"
	b_disc_bare = P.build(od)
	var oo: Dictionary = oj.duplicate()
	oo.merge({"hair": ["g0", "g2"], "brow": "g0", "stubble": "g2", "shoulder": 1.06}, true)
	b_old = P.build(oo)
	var s := sucessao()
	var r := reencontro()
	for i in s.size():
		(s[i][0] as Image).save_png(OUT + "prancha_6b_sucessao_S%02d.png" % (i + 1))
	for i in r.size():
		(r[i][0] as Image).save_png(OUT + "prancha_6b_reencontro_R%02d.png" % (i + 1))
	folha_prancha(s, "PRANCHA 6B - PRIMEIRA SUCESSÃO", "rascunho de composição (não é arte final)   garagem, câmera fixa, 1 corte   controle preso: 9 s + 6 s", OUT + "prancha_6b_sucessao.png")
	folha_prancha(r, "PRANCHA 6B - REENCONTRO FINAL", "rascunho de composição (não é arte final)   última arena simples, a mesma janela da garagem   21,6 s", OUT + "prancha_6b_reencontro.png")
	pares(s, r, OUT + "prancha_6b_pares.png")
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	print("ok: %d + %d quadros em %s" % [s.size(), r.size(), OUT])
	quit()
