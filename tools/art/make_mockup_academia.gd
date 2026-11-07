extends SceneTree
## Mockup PLACEHOLDER da tela principal — local 2: Academia de bairro (versão mais simples).
## Mostra a evolução em relação à garagem: parede pintada, luz fria de tubo, piso de borracha,
## ringue pequeno, saco de couro, esteira que funciona, aparelho da arte (Muay Thai: saco longo),
## mais gente treinando (geradores).
## Rodar: godot --headless --path <dir_com_project.godot_vazio> --script E:/Fightclicker/tools/art/make_mockup_academia.gd

const OUT := "E:/Fightclicker/docs/arte/mockups/academia"
var L

const VPX := 320.0
const VPY := -28.0
const K := 0.78
const BX0 := 170
const BX1 := 470
const FLOOR_Y := 220
const FRONT_Y := 289
const WAIN_Y := 150

func _init() -> void:
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	draw_room(img, rng)
	draw_props(img, rng)
	draw_center(img)
	L.light(img, L.SCENE, Vector2(320, 40), 420.0, 1.0, 2.4, -2, 0, 1.0)
	draw_after_light(img)
	L.game_ui(img, {
		"money": "$ 2.40K", "treino": "TREINO 18.6K", "treino_s": "+142/S", "fama": "FAMA 85",
		"local": "ACADEMIA DE BAIRRO", "carreira": "CARREIRA 2",
		"attrs": [["FORÇA", "164", 0.70, "r3", "r2"], ["AGILIDADE", "98", 0.45, "b3", "b2"], ["RESISTÊNCIA", "121", 0.55, "y1", "y0"]],
		"legado": "340", "adv": "ADVERSÁRIO", "adv2": "REGIONAL 2/6", "risco": "FÁCIL", "risco_cor": "gr3",
		"cmp": [["FOR", 120, 164], ["AGI", 110, 98], ["RES", 90, 121]],
		"shop": [
			{"name": "PARCEIRO", "prod": "+3.00/S", "qty": "X6", "cost": "$ 61.0", "icon": "gr1", "icon2": "gr3"},
			{"name": "TREINADOR", "prod": "+24.0/S", "qty": "X2", "cost": "$ 264", "icon": "b1", "icon2": "b3"},
			{"name": "ALUNOS", "prod": "+0/S", "qty": "X0", "cost": "$ 3.50K", "can": false, "icon": "p0", "icon2": "p2"},
		],
		"ups": [["SACO COURO", "OK", "r1", "gr3"], ["LUVA 12OZ", "$ 800", "r2"], ["CANELEIRA", "$ 1.20K", "b2", "r2"]],
		"prox_local": "CENTRO DE TREINO", "prox_req": "PRECISA CINTURÃO",
		"clique": "+164", "dica": "CLIQUE NO SACO PARA TREINAR",
		"focos": [["FORÇA", "SACO", "r1", true], ["AGILIDADE", "CORDA", "b1", false], ["RESISTÊNCIA", "ESTEIRA", "y0", false], ["MUAY THAI", "SACO LONGO", "p1", false]],
	})
	L.save_scaled(img, OUT, 2)
	print("ok: ", OUT)
	quit()

func side_y(yb: float) -> float:
	return VPY + (yb - VPY) / K

func draw_room(img: Image, rng: RandomNumberGenerator) -> void:
	# parede pintada: creme em cima, barrado verde embaixo
	L.R(img, BX0, 18, BX1 - BX0, WAIN_Y - 18, "cream")
	L.R(img, BX0, WAIN_Y, BX1 - BX0, FLOOR_Y - WAIN_Y, "gr1")
	L.R(img, BX0, WAIN_Y - 2, BX1 - BX0, 2, "white")
	L.R(img, BX0, WAIN_Y, BX1 - BX0, 1, "gr0")
	for i in 60:   # tinta descascada
		var x := rng.randi_range(BX0, BX1 - 3)
		var y := rng.randi_range(36, WAIN_Y - 6)
		L.R(img, x, y, 2 + i % 2, 1, "g3")
	for i in 40:
		L.R(img, rng.randi_range(BX0, BX1 - 3), rng.randi_range(WAIN_Y + 3, FLOOR_Y - 3), 2, 1, "gr0")
	L.line(img, 420, 40, 426, 58, "g3"); L.line(img, 426, 58, 423, 70, "g3")   # rachadura
	# paredes laterais (mesma pintura, mais escura)
	for side in [0, 1]:
		var xa := 128 if side == 0 else BX1
		var xb := BX0 if side == 0 else 512
		for xx in range(xa, xb):
			var t := float(xx - 128) / float(BX0 - 128) if side == 0 else float(511 - xx) / float(511 - BX1)
			var yb := int(round(lerpf(FRONT_Y, FLOOR_Y, t)))
			var yw := int(round(lerpf(side_y(WAIN_Y), WAIN_Y, t)))
			L.R(img, xx, 18, 1, yw - 18, "g3")
			L.R(img, xx, yw, 1, 2, "cream")
			L.R(img, xx, yw + 2, 1, yb - yw - 2, "gr0")
		L.line(img, BX0 if side == 0 else BX1, 18, BX0 if side == 0 else BX1, FLOOR_Y, "g2")
	# piso de borracha em placas (perspectiva)
	for y in range(FLOOR_Y, FRONT_Y + 1):
		var s := (y - VPY) / (FRONT_Y - VPY)
		var row := int((s - K) / (1.0 - K) * 4.0)
		var xl := VPX - 192 * s
		var xr := VPX + 192 * s
		for x in range(int(round(xl)), int(round(xr)) + 1):
			var u := (x - VPX) / (192 * s)
			var colu := int(floor((u + 1.0) * 5.0))
			var c := "d2" if (row + colu) % 2 == 0 else "g0"
			L.P(img, x, y, c)
	for i in 500:
		var yy := rng.randi_range(FLOOR_Y + 1, FRONT_Y)
		var t := float(yy - FLOOR_Y) / float(FRONT_Y - FLOOR_Y)
		L.P(img, rng.randi_range(int(lerpf(BX0, 128, t)), int(lerpf(BX1, 511, t))), yy, "d1")
	L.R(img, BX0, FLOOR_Y, BX1 - BX0, 2, "d1")
	# viga metálica + calhas de lâmpada fluorescente
	L.R(img, BX0, 24, BX1 - BX0, 6, "st1"); L.R(img, BX0, 24, BX1 - BX0, 1, "st2"); L.R(img, BX0, 29, BX1 - BX0, 1, "st0")
	L.R(img, BX0, 30, BX1 - BX0, 1, "ink")

func draw_props(img: Image, rng: RandomNumberGenerator) -> void:
	# janela alta com grade (luz do dia)
	L.R(img, 384, 46, 70, 34, "ink")
	L.R(img, 385, 47, 68, 32, "b3")
	L.dither(img, 385, 64, 68, 15, "b2")
	for i in range(0, 6):
		L.R(img, 390 + i * 12, 47, 2, 32, "d1")
	L.R(img, 385, 62, 68, 2, "d1")
	L.R(img, 382, 80, 74, 3, "g3")
	# relógio
	L.ellipse(img, 352, 58, 8, 8, "ink"); L.ellipse(img, 352, 58, 7, 7, "white")
	L.R(img, 352, 53, 1, 5, "ink"); L.R(img, 352, 58, 4, 1, "ink")
	# pôsteres desbotados
	for p in [[186, 46, "b1"], [214, 52, "r1"]]:
		var pst: Image = L.blank(22, 30)
		L.R(pst, 0, 0, 22, 30, "cream"); L.R(pst, 0, 0, 22, 16, p[2])
		L.ellipse(pst, 11, 6, 3, 3, "d1"); L.R(pst, 7, 9, 8, 7, "d1")
		L.R(pst, 3, 20, 16, 2, "g2"); L.R(pst, 3, 24, 12, 2, "g2")
		L.stamp(img, pst, p[0], p[1])
	# espelho
	L.R(img, 262, 70, 60, 64, "ink")
	L.R(img, 263, 71, 58, 62, "st3")
	L.dither(img, 263, 71, 58, 62, "b3")
	L.line(img, 270, 128, 300, 76, "white"); L.line(img, 276, 128, 306, 76, "white")
	L.R(img, 260, 134, 64, 2, "g2")
	# ringue pequeno ao fundo-esquerda
	var rx0 := 176
	var rx1 := 262
	L.R(img, rx0, 196, rx1 - rx0, 22, "b1")
	L.R(img, rx0, 196, rx1 - rx0, 2, "b2")
	L.R(img, rx0, 210, rx1 - rx0, 8, "b0")
	for px in [rx0, rx1 - 4]:
		L.R(img, px, 140, 4, 60, "st2"); L.R(img, px, 140, 1, 60, "st3"); L.R(img, px, 138, 4, 4, "r1")
	for i in 3:
		var ry := 152 + i * 14
		var rc: String = ["r2", "white", "b2"][i]
		L.R(img, rx0 + 4, ry, rx1 - rx0 - 8, 2, rc)
		L.R(img, rx0 + 4, ry + 2, rx1 - rx0 - 8, 1, L.shade(L.col(rc), -2))
	# corda num gancho, com cabos
	L.P(img, 248, 92, "d1")
	L.ring(img, 248, 106, 7, 13, 1, "r2")
	L.R(img, 242, 116, 3, 9, "r1"); L.R(img, 252, 117, 3, 9, "r1")
	# saco longo de Muay Thai (aparelho da arte) — fundo-esquerda, na frente do ringue
	L.R(img, 210, 31, 1, 62, "g2")
	var ban: Image = L.blank(22, 112)
	L.rrect(ban, 0, 0, 22, 112, "d1")
	L.R(ban, 0, 2, 5, 108, "ink"); L.R(ban, 15, 4, 3, 104, "d2"); L.R(ban, 16, 6, 1, 30, "g0")
	L.R(ban, 0, 8, 22, 5, "r1"); L.R(ban, 0, 98, 22, 5, "r1"); L.R(ban, 0, 8, 22, 1, "r2")
	L.stamp(img, ban, 200, 94)
	L.ellipse_dither(img, 211, 238, 13, 3, "ink")
	# esteira que funciona (direita) + parceiro correndo
	var tm: Image = L.blank(86, 42)
	L.R(tm, 8, 30, 76, 2, "ink")
	L.R(tm, 8, 32, 76, 6, "st3"); L.R(tm, 8, 32, 76, 1, "white"); L.R(tm, 8, 37, 76, 1, "st2")
	L.R(tm, 30, 33, 30, 3, "r1")
	L.ellipse(tm, 10, 34, 3, 3, "st1"); L.ellipse(tm, 82, 34, 3, 3, "st1")
	L.R(tm, 12, 38, 4, 3, "d2"); L.R(tm, 76, 38, 4, 3, "d2")
	L.R(tm, 6, 6, 4, 25, "st2"); L.R(tm, 6, 6, 1, 25, "st3")
	L.R(tm, 0, 0, 18, 8, "d1"); L.R(tm, 3, 2, 10, 4, "gr1"); L.R(tm, 4, 3, 5, 1, "gr3"); L.R(tm, 0, 0, 18, 1, "st2")
	L.R(tm, 8, 11, 26, 2, "st3")
	L.ellipse_dither(img, 446, 266, 42, 4, "ink")
	L.stamp(img, tm, 402, 226)
	L.stamp(img, L.flipped(L.fighter({"shirt": ["gr0", "gr1", "gr2"], "shorts": ["d1", "d2", "g0"], "gloves": [], "hair": ["ink", "d2"]})), 424, 189)
	# treinador de agasalho, de braços para trás, olhando o lutador
	L.ellipse_dither(img, 244, 284, 14, 3, "ink")
	L.stamp(img, L.fighter({"shirt": ["b0", "b1", "b2"], "shorts": ["b0", "b1", "b2"], "gloves": [], "hair": ["g2", "g3"]}), 222, 217)
	# banco + garrafa d'água
	var bench: Image = L.blank(40, 14)
	L.R(bench, 0, 0, 40, 4, "br2"); L.R(bench, 0, 0, 40, 1, "br3"); L.R(bench, 0, 4, 40, 1, "br0")
	L.R(bench, 3, 5, 3, 9, "st1"); L.R(bench, 34, 5, 3, 9, "st1")
	L.stamp(img, bench, 140, 262)
	var btl: Image = L.blank(5, 10)
	L.R(btl, 1, 0, 3, 2, "b2"); L.R(btl, 0, 2, 5, 8, "b3"); L.R(btl, 3, 3, 1, 6, "white")
	L.stamp(img, btl, 172, 251)

func draw_center(img: Image) -> void:
	L.ellipse(img, 303, 272, 15, 3, "ink")
	L.ellipse_dither(img, 336, 266, 14, 3, "ink")
	# corrente curta + mola
	for yy in range(31, 186):
		L.P(img, 336, yy, "st2" if (yy / 3) % 2 == 0 else "st1")
	L.line(img, 336, 186, 324, 192, "st3"); L.line(img, 336, 186, 348, 192, "st3")
	L.ring(img, 336, 186, 3, 3, 1, "st3")
	# saco de couro novo (upgrade comprado)
	var bag: Image = L.blank(30, 62)
	L.rrect(bag, 0, 4, 30, 58, "r1")
	L.R(bag, 2, 0, 26, 6, "d1"); L.R(bag, 2, 0, 26, 1, "g0")
	L.R(bag, 0, 6, 5, 54, "r0"); L.R(bag, 19, 8, 4, 50, "r2"); L.R(bag, 21, 10, 1, 20, "r3"); L.R(bag, 21, 34, 1, 6, "r3")
	L.R(bag, 0, 22, 30, 12, "d1"); L.R(bag, 0, 22, 30, 1, "g0"); L.R(bag, 0, 33, 30, 1, "ink")
	L.text(bag, "FC", 9, 25, "white")
	L.R(bag, 1, 60, 28, 2, "r0")
	L.stamp(img, bag, 321, 190)
	L.stamp(img, L.fighter({"gloves": ["r0", "r1", "r2"], "shirt": ["d1", "d2", "g0"], "shorts": ["r0", "r1", "r2"]}), 281, 205)

func draw_after_light(img: Image) -> void:
	# tubos fluorescentes acesos
	for lx in [220, 380]:
		L.R(img, lx, 31, 1, 6, "st1"); L.R(img, lx + 40, 31, 1, 6, "st1")
		L.R(img, lx - 2, 36, 46, 5, "ink")
		L.R(img, lx - 1, 37, 44, 3, "st1")
		L.R(img, lx, 38, 42, 2, "white")
		L.dither(img, lx - 2, 42, 46, 2, "b3")
	# juice
	for d in [Vector2i(1, -1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		L.line(img, 321 + d.x * 3, 220 + d.y * 3, 321 + d.x * 8, 220 + d.y * 8, "white")
	L.text_center(img, "+164 FORÇA", 336, 168, "y1", 1, null, "ink")
	L.text_center(img, "+492!", 368, 148, "r3", 2, null, "ink")
	var cur: Image = L.blank(10, 10)
	L.glove(cur, 0, 0, 9, 10, ["r0", "r1", "r2"])
	L.stamp(img, L.outlined(cur, "white"), 352, 236)
