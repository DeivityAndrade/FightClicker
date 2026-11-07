extends SceneTree
## Sprites PLACEHOLDER da Fase 5 — Academia Boa Esquina, Boxe (pera veloz) e Jiu-jitsu (boneco de tatame).
## Tudo gerado por código, paleta fechada de docs/arte/direcao-visual.md (fonte da verdade: tools/art/pixel_lib.gd).
## Rodar headless a partir de uma pasta com um project.godot vazio (não importa nada no projeto):
##   godot --headless --path <pasta_tmp> --quit-after 120 --script E:/Fightclicker/tools/art/make_sprites_fase5.gd
## Saída:
##   assets/sprites/gym/gym_bg.png, gym_tube.png                 sala da academia (mesma caixa da garagem) + tubo que falha
##   assets/sprites/equipment/*_gym.png                          saco, esteira e corda na versão da academia (mesmos quadros e pivôs)
##   assets/sprites/equipment/speed_bag_*.png                    pera veloz: pedestal no centro (foco) e plataforma na parede (descanso)
##   assets/sprites/equipment/grappling_dummy_*.png              boneco de tatame: sentado no centro (foco) e deitado no tatame (descanso)
##   assets/sprites/garage/tape_mark_*, ghost_*, fx_arrive_dust_small   marcas de fita, silhuetas e chegada dos aparelhos das artes
##   assets/sprites/ui/...                                       ícones das artes, técnicas, nós ESTILO, janela de arte, MUDAR
##   assets/sprites/manifest.json                                ACRESCENTA as entradas da Fase 5 (não apaga as anteriores)
##   docs/arte/mockups/fase5_academia_x2.png, fase5_marcas_x2.png, fase5_sprites_x3.png
## Não toca em personagens (characters/, fight/, opponents/) nem em personagem_lib.gd.

const ROOT := "E:/Fightclicker/"
const OUT := ROOT + "assets/sprites/"
const RES := "res://assets/sprites/"
const MOCK := ROOT + "docs/arte/mockups/"

var L
var M := {}
var F := {}
var SHEETS := []
var OLD := {}

# ---------------------------------------------------------------- geometria (igual à garagem, direcao-visual §4)
const VPX := 320.0
const VPY := -28.0
const K := 0.78
const BX0 := 170
const BX1 := 470
const FLOOR_Y := 220
const FRONT_Y := 289
const WAIN_Y := 150
const P_ROOM := Vector2i(128, 18)

# Posições que já existem (manifest das Fases 2–4b)
const P_BAG_CENTER := Vector2i(336, 183)
const P_BAG_LEFT := Vector2i(258, 160)
const P_TM_CENTER := Vector2i(336, 280)
const P_TM_RIGHT := Vector2i(445, 267)
const NAIL := Vector2i(352, 72)
const P_FIGHTER_BAG := Vector2i(303, 272)
const P_FIGHTER_ROPE := Vector2i(336, 272)
const P_FIGHTER_TM := Vector2i(339, 269)
const P_METRO := Vector2i(240, 118)
const P_LAMP := Vector2i(300, 32)
const P_NEIGHBOR := [Vector2i(176, 284), Vector2i(220, 258), Vector2i(488, 286)]
const P_UNCLE := [Vector2i(455, 236), Vector2i(398, 230)]
const P_COACH := Vector2i(394, 280)

# Fase 5: aparelhos das artes
const SB_CENTER := Vector2i(330, 274)      # pedestal da pera em foco (pivô = chão, meio da base)
const SB_FRAME := Vector2i(44, 84)
const SB_PIVOT := Vector2i(22, 81)
const SB_WALL := Vector2i(436, 46)         # plataforma da pera na parede (pivô = meio de cima da tábua)
const SBW_FRAME := Vector2i(48, 52)
const SBW_PIVOT := Vector2i(24, 0)
const GD_CENTER := Vector2i(338, 279)      # boneco sentado em foco (pivô = meio da frente do tatame, no chão)
const GD_FRAME := Vector2i(66, 60)
const GD_PIVOT := Vector2i(32, 57)
const GD_REST := Vector2i(228, 283)        # boneco deitado no canto da frente à esquerda (descanso)
const GDR_FRAME := Vector2i(66, 30)
const GDR_PIVOT := Vector2i(32, 27)
const SIGN_SB_TOPCENTER := Vector2i(432, 102)   # plaquinha da pera: colada na parede/porta, abaixo da marca
const SIGN_GD_BOTTOM := Vector2i(230, 268)      # plaquinha do boneco: em pé no fundo da marca, no tijolo
const TUBES := [Vector2i(218, 34), Vector2i(422, 34)]
const FOCUS_W := 122
const FOCUS_H := 34

func V(x, y) -> Vector2:
	return Vector2(x, y)

func xy(v: Vector2i) -> Array:
	return [v.x, v.y]

# ================================================================ util (mesmo padrão da 4b)
func strip(frames: Array) -> Image:
	var fw: int = frames[0].get_width()
	var fh: int = frames[0].get_height()
	var s: Image = L.blank(fw * frames.size(), fh)
	for i in frames.size():
		s.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	return s

func save_sheet(id: String, rel: String, frames: Array, fps: float, pivot: Vector2i, info := {}, contact := true) -> void:
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
	if contact:
		SHEETS.append([id, s, frames[0].get_width()])

## Contorno ink sem crescer o quadro (o desenho precisa ter 1 px de folga).
func ol(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

func pmap(img: Image, x: int, y: int, rows: Array, leg: Dictionary) -> void:
	for j in rows.size():
		var r: String = rows[j]
		for i in r.length():
			var ch := r[i]
			if ch != "." and leg.has(ch):
				L.P(img, x + i, y + j, leg[ch])

func grayed(src: Image) -> Image:
	var out: Image = src.duplicate()
	var ramp := ["d1", "d2", "g0", "g1"]
	var ink_hex: String = L.C.ink.to_html(false)
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a == 0.0 or c.to_html(false) == ink_hex:
				continue
			var lum := c.r * 0.3 + c.g * 0.55 + c.b * 0.15
			var i := clampi(int(lum * ramp.size() * 1.05), 0, ramp.size() - 1)
			out.set_pixel(x, y, L.C[ramp[i]])
	return out

## Troca toda cor opaca que não seja ink por uma rampa (para recolorir a corda em uso).
func recolor(src: Image, base: String, dark: String) -> Image:
	var out: Image = src.duplicate()
	var ink_hex: String = L.C.ink.to_html(false)
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a == 0.0 or c.to_html(false) == ink_hex:
				continue
			var lum := c.r * 0.3 + c.g * 0.55 + c.b * 0.15
			out.set_pixel(x, y, L.C[base] if lum > 0.62 else L.C[dark])
	return out

## Cápsula grossa entre dois pontos (membro do boneco, haste), com luz em cima à esquerda.
func capsule(img: Image, a: Vector2, b: Vector2, r: float, ramp: Array) -> void:
	var n := int(ceil(a.distance_to(b))) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(maxi(n, 1)))
		L.ellipse(img, p.x, p.y, r, r, ramp[1])
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(maxi(n, 1)))
		L.ellipse(img, p.x - r * 0.35, p.y - r * 0.35, maxf(r * 0.45, 0.6), maxf(r * 0.45, 0.6), ramp[2])

# ================================================================ luz da academia (tubos frios)
## Passo de luz por ponto da tela: claro embaixo dos tubos, cai para os cantos e para a frente do chão.
func gym_step(x: int, y: int) -> int:
	var best := -9.0
	for t in TUBES:
		var d := Vector2(x - t.x, (y - t.y - 30) * 0.8).length() / 260.0
		best = maxf(best, 0.95 - d * 1.9)
	# a frente do chão fica um pouco mais escura (o tubo está longe)
	best -= clampf(float(y - 250) / 120.0, 0.0, 0.35)
	var base := floorf(best)
	var fr := clampf((best - base - 0.5) * 3.0 + 0.5, 0.0, 1.0)
	var b: float = (L.BAYER[y % 4][x % 4] + 0.5) / 16.0
	return clampi(int(base) + (1 if fr > b else 0), -2, 1)

func gym_light(img: Image, area: Rect2i, topleft: Vector2i, max_step := 1) -> void:
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var st := mini(gym_step(x + topleft.x, y + topleft.y), max_step)
			if st != 0:
				img.set_pixel(x, y, L.shade(c, st))

func gym_lit(img: Image, topleft: Vector2i) -> Image:
	var c: Image = img.duplicate()
	gym_light(c, Rect2i(0, 0, c.get_width(), c.get_height()), topleft, 0)
	return c

## A mesma luz da lâmpada da garagem (make_sprites_fase2.gd, lit()).
func garage_lit(img: Image, topleft: Vector2i, min_step := -2) -> Image:
	var c: Image = img.duplicate()
	L.light(c, Rect2i(0, 0, c.get_width(), c.get_height()), Vector2(305, 90) - Vector2(topleft), 300.0, 1.1, 3.6, min_step, 1, 0.9)
	return c

# ================================================================ sala da academia
func side_y(yb: float) -> float:
	return VPY + (yb - VPY) / K

func floor_half(y: float) -> float:
	return 192.0 * (y - VPY) / (FRONT_Y - VPY)

func make_gym_bg() -> void:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	gym_walls(img, rng)
	gym_floor(img, rng)
	gym_props(img, rng)
	gym_light(img, L.SCENE, Vector2i.ZERO)
	gym_after_light(img)
	var bg: Image = img.get_region(Rect2i(P_ROOM, Vector2i(384, 272)))
	save_sheet("gym_bg", "gym/gym_bg.png", [bg], 0, Vector2i.ZERO, {
		"pos": xy(P_ROOM), "layer": "fundo", "z": -100,
		"note": "Academia Boa Esquina inteira, sem aparelhos nem pessoas: parede creme com barrado verde descascado, viga de aço, 2 tubos, nome pintado, espelho trincado com fita, pôsteres desbotados, prateleira (Metrônomo em 240,118), quadro da mensalidade, banco, relógio de round, luvas penduradas, porta, piso de borracha e tatame gasto no canto da frente à esquerda. Luz fria já aplicada. Mesma caixa e mesmos pontos da garage_bg: troca só o fundo."}, false)
	# tubo (aceso / falhando), por cima do fundo nos 2 pontos
	var frames := []
	for f in 2:
		frames.append(tube_sprite(f == 1))
	save_sheet("gym_tube", "gym/gym_tube.png", frames, 0, Vector2i(24, 0), {
		"positions": {"tubo_esq": xy(TUBES[0]), "tubo_dir": xy(TUBES[1])}, "layer": "frente_do_fundo", "z": -50,
		"anim": {"idle": [0], "flicker": [1, 0, 1, 0]},
		"note": "Luminária de tubo. O fundo já tem os 2 tubos acesos: este sprite só é preciso para a falha (quadro 1 = apagado). De vez em quando (~10 s), um tubo faz flicker a 12 fps. Pivô = meio de cima (onde os fios saem da viga)."})

func gym_walls(img: Image, rng: RandomNumberGenerator) -> void:
	# fundo: creme em cima, barrado verde embaixo
	L.R(img, BX0, 18, BX1 - BX0, WAIN_Y - 18, "cream")
	L.R(img, BX0, WAIN_Y, BX1 - BX0, FLOOR_Y - WAIN_Y, "gr1")
	L.R(img, BX0, WAIN_Y - 3, BX1 - BX0, 2, "white")
	L.R(img, BX0, WAIN_Y - 1, BX1 - BX0, 1, "g3")
	L.R(img, BX0, WAIN_Y, BX1 - BX0, 1, "gr0")
	L.R(img, BX0, FLOOR_Y - 6, BX1 - BX0, 6, "gr0")       # rodapé
	L.R(img, BX0, FLOOR_Y - 6, BX1 - BX0, 1, "gr2")
	# sujeira da tinta creme (pontos) e umidade no barrado
	for i in 260:
		L.P(img, rng.randi_range(BX0, BX1 - 1), rng.randi_range(34, WAIN_Y - 4), "g3")
	for i in 120:
		L.P(img, rng.randi_range(BX0, BX1 - 1), rng.randi_range(WAIN_Y + 2, FLOOR_Y - 8), "gr0" if i % 3 else "gr2")
	# tinta descascando na borda do barrado (aparece o reboco) — em grupos
	for i in 16:
		var px := rng.randi_range(BX0 + 4, BX1 - 14)
		var w := rng.randi_range(3, 9)
		var h := rng.randi_range(2, 6)
		var yy := WAIN_Y + rng.randi_range(1, 5)
		L.R(img, px, yy, w, h, "g3")
		L.R(img, px, yy + h, w, 1, "g2")
		L.R(img, px + w, yy, 1, h, "gr0")
		if rng.randf() < 0.5:
			L.R(img, px + 1, yy - 3, w - 1, 2, "g3")
	# manchas de tinta caindo no creme (descascado)
	for c in [Vector2i(186, 100), Vector2i(352, 128), Vector2i(462, 64), Vector2i(258, 46)]:
		L.ellipse(img, c.x, c.y, 4, 2, "g3"); L.P(img, c.x - 2, c.y + 2, "g2"); L.P(img, c.x + 3, c.y - 1, "g2")
	# rachadura na parede (canto de cima à esquerda) e outra perto da porta
	var cr := [[172, 22], [176, 30], [175, 38], [181, 46], [184, 58], [182, 66]]
	for i in cr.size() - 1:
		L.line(img, cr[i][0], cr[i][1], cr[i + 1][0], cr[i + 1][1], "g1")
		L.line(img, cr[i][0] + 1, cr[i][1], cr[i + 1][0] + 1, cr[i + 1][1], "white")
	var cr2 := [[466, 98], [462, 108], [464, 118], [459, 128], [461, 140]]
	for i in cr2.size() - 1:
		L.line(img, cr2[i][0], cr2[i][1], cr2[i + 1][0], cr2[i + 1][1], "g1")
	# paredes laterais (mesma tinta em perspectiva, um passo mais escuras)
	for side in [0, 1]:
		var xa := 128 if side == 0 else BX1
		var xb := BX0 if side == 0 else 512
		for xx in range(xa, xb):
			var t := float(xx - 128) / float(BX0 - 128) if side == 0 else float(511 - xx) / float(511 - BX1)
			var yb := int(round(lerpf(FRONT_Y, FLOOR_Y, t)))
			var yw := int(round(lerpf(side_y(WAIN_Y), WAIN_Y, t)))
			var yr := int(round(lerpf(side_y(FLOOR_Y - 6), FLOOR_Y - 6, t)))
			L.R(img, xx, 18, 1, yw - 18, "g3")
			L.R(img, xx, yw - 2, 1, 2, "cream")
			L.R(img, xx, yw, 1, yb - yw, "gr0")
			L.R(img, xx, yr, 1, yb - yr, "d2")
			if (xx % 7) == 0:
				L.P(img, xx, rng.randi_range(30, yw - 6), "g2")
		L.line(img, BX0 if side == 0 else BX1, 18, BX0 if side == 0 else BX1, FLOOR_Y, "g2")
	# janela alta com grade na parede lateral esquerda (luz da rua)
	for xx in range(134, 160):
		var t := float(xx - 128) / float(BX0 - 128)
		var top := int(round(lerpf(side_y(56), 56, t)))
		var bot := int(round(lerpf(side_y(96), 96, t)))
		L.R(img, xx, top, 1, bot - top, "b2")
		if xx % 6 == 0:
			L.R(img, xx, top, 1, bot - top, "st0")
		L.P(img, xx, top, "ink"); L.P(img, xx, bot, "ink")
		L.P(img, xx, top + 1, "b3")
		var mid := (top + bot) / 2
		L.P(img, xx, mid, "st0")
	# viga de aço (I) atravessando o alto
	L.R(img, BX0, 18, BX1 - BX0, 6, "g3")
	L.R(img, BX0, 24, BX1 - BX0, 8, "st1")
	L.R(img, BX0, 24, BX1 - BX0, 1, "st3")
	L.R(img, BX0, 25, BX1 - BX0, 1, "st2")
	L.R(img, BX0, 30, BX1 - BX0, 1, "st0")
	L.R(img, BX0, 31, BX1 - BX0, 1, "ink")
	for i in range(BX0 + 6, BX1, 18):
		L.P(img, i, 27, "st3"); L.P(img, i, 28, "st0")
	# ganchos (centro e lado) onde a corrente do saco prende
	for hx in [P_BAG_CENTER.x, P_BAG_LEFT.x]:
		L.R(img, hx - 2, 31, 5, 2, "st0")
		L.R(img, hx - 2, 31, 5, 1, "st3")

func gym_floor(img: Image, rng: RandomNumberGenerator) -> void:
	# placas de borracha em xadrez (d2 / g0), grade em perspectiva
	var rows := [FLOOR_Y, 229, 240, 253, 269, FRONT_Y + 1]
	var cols := 8
	for r in rows.size() - 1:
		var y0: int = rows[r]
		var y1: int = rows[r + 1]
		for yy in range(y0, y1):
			var hw := floor_half(yy)
			for cidx in cols:
				var xa := VPX - hw + 2.0 * hw * cidx / cols
				var xb := VPX - hw + 2.0 * hw * (cidx + 1) / cols
				var tone := "d2" if (r + cidx) % 2 == 0 else "g0"
				# tatame azul gasto: canto da frente à esquerda (2 linhas x 3 colunas)
				var tatame := r >= 3 and cidx <= 2
				if tatame:
					tone = "b1" if (r + cidx) % 2 == 0 else "b2"
				L.R(img, int(round(xa)), yy, int(round(xb)) - int(round(xa)), 1, tone)
	# junta das placas
	for cidx in range(1, cols):
		var bx := lerpf(BX0, BX1, float(cidx) / cols)
		var fx := lerpf(128, 511, float(cidx) / cols)
		L.line(img, int(bx), FLOOR_Y, int(fx), FRONT_Y, "d1")
	for r in range(1, rows.size() - 1):
		var yy: int = rows[r]
		var hw := floor_half(yy)
		L.R(img, int(VPX - hw), yy, int(2 * hw), 1, "d1")
	# textura da borracha
	for i in 700:
		var yy := rng.randi_range(FLOOR_Y + 1, FRONT_Y)
		var hw := floor_half(yy)
		var xx := rng.randi_range(int(VPX - hw), int(VPX + hw))
		var c := img.get_pixel(xx, yy)
		if c.a > 0.0:
			img.set_pixel(xx, yy, L.shade(c, -1 if i % 3 else 1))
	# tatame: borda de cima mais clara, desgaste (cinza) e um rasgo com fita crepe
	var ty := 253
	var hw2 := floor_half(ty)
	var tx1 := VPX - hw2 + 2.0 * hw2 * 3 / cols
	L.R(img, int(VPX - hw2), ty, int(tx1 - (VPX - hw2)), 1, "b3")
	for i in 90:
		var yy := rng.randi_range(256, FRONT_Y)
		var hw := floor_half(yy)
		var xl := VPX - hw
		var xr := VPX - hw + 2.0 * hw * 3 / cols
		var xx := rng.randi_range(int(xl) + 1, int(xr) - 2)
		var c := img.get_pixel(xx, yy)
		if c.a > 0.0 and (c.to_html(false) == L.C.b1.to_html(false) or c.to_html(false) == L.C.b2.to_html(false)):
			img.set_pixel(xx, yy, L.C["g1"] if i % 4 == 0 else L.shade(c, -1))
	# rasgo remendado com fita (X) no tatame
	L.line(img, 150, 274, 158, 279, "cream"); L.line(img, 158, 274, 150, 279, "cream")
	L.line(img, 151, 274, 159, 279, "g3")
	L.line(img, 146, 284, 160, 286, "b0")
	# sombra/rodapé no encontro com a parede
	L.trap(img, FLOOR_Y, FLOOR_Y + 2, BX0, BX1, BX0 - 1, BX1 + 1, "d1")
	L.R(img, BX0, FLOOR_Y, BX1 - BX0, 1, "ink")
	# mancha de suor perto do centro e marca do saco no chão
	L.ellipse_dither(img, 336, 262, 16, 3, "d1")

func tube_sprite(off: bool) -> Image:
	var img: Image = L.blank(48, 10)
	L.R(img, 6, 0, 1, 4, "d2"); L.R(img, 41, 0, 1, 4, "d2")
	L.R(img, 1, 4, 46, 4, "ink")
	L.R(img, 2, 5, 44, 2, "st2")
	L.R(img, 2, 5, 44, 1, "st3")
	L.R(img, 3, 7, 42, 2, "ink")
	if off:
		L.R(img, 4, 7, 40, 2, "g1")
		L.R(img, 4, 7, 40, 1, "g2")
	else:
		L.R(img, 4, 7, 40, 2, "white")
		L.R(img, 4, 8, 40, 1, "b3")
	return img

func poster(w: int, h: int, bgc: String, fg: String, txt: String, rng: RandomNumberGenerator) -> Image:
	var p: Image = L.blank(w, h)
	L.R(p, 0, 0, w, h, "cream")
	L.R(p, 1, 1, w - 2, h * 5 / 9, bgc)
	# duas silhuetas em guarda (lutadores genéricos, desbotados)
	L.ellipse(p, w * 0.32, 7, 2.5, 2.5, fg); L.R(p, int(w * 0.32) - 3, 10, 6, 8, fg); L.R(p, int(w * 0.32) + 2, 10, 4, 2, fg)
	L.ellipse(p, w * 0.68, 7, 2.5, 2.5, fg); L.R(p, int(w * 0.68) - 3, 10, 6, 8, fg); L.R(p, int(w * 0.68) - 6, 10, 4, 2, fg)
	L.text(p, txt, 2, h * 5 / 9 + 3, "g2")
	L.R(p, 3, h - 6, w - 6, 1, "g3"); L.R(p, 3, h - 4, w - 10, 1, "g3")
	# desbotado: metade dos pixels de cor viram creme/g3
	for y in h:
		for x in w:
			var c := p.get_pixel(x, y)
			if c.a > 0.0 and (x * 7 + y * 3) % 5 < 2 and c.to_html(false) != L.C.cream.to_html(false):
				p.set_pixel(x, y, L.shade(c, 1))
	# canto de baixo à direita descolado
	for i in 4:
		for j in 4 - i:
			p.set_pixel(w - 1 - j, h - 1 - i, Color(0, 0, 0, 0))
	L.P(p, w - 4, h - 1, "g3"); L.P(p, w - 1, h - 4, "g3"); L.P(p, w - 3, h - 2, "g2")
	return p

func gym_props(img: Image, rng: RandomNumberGenerator) -> void:
	# nome pintado à mão acima do espelho (tinta descascando)
	var nm: Image = L.blank(80, 18)
	L.text_center(nm, "ACADEMIA", 40, 0, "gr1")
	L.text_center(nm, "BOA ESQUINA", 40, 9, "r1")
	for y in 18:
		for x in 80:
			if nm.get_pixel(x, y).a > 0.0 and rng.randf() < 0.14:
				nm.set_pixel(x, y, L.C["g3"])
	L.blit(img, nm, 257, 35)
	# espelho trincado (x 266..328, y 54..146)
	var mx := 266
	var my := 55
	var mw := 62
	var mh := 90
	L.R(img, mx - 2, my - 2, mw + 4, mh + 4, "ink")
	L.R(img, mx - 1, my - 1, mw + 2, mh + 2, "st2")
	L.R(img, mx - 1, my - 1, mw + 2, 1, "st3")
	L.R(img, mx, my, mw, mh, "g3")
	L.R(img, mx, my + mh - 30, mw, 30, "g2")    # reflexo do barrado/chão
	L.dither(img, mx, my + mh - 34, mw, 4, "g2")
	L.R(img, mx, my + mh - 30, mw, 1, "cream")
	for i in 3:
		L.line(img, mx + 8 + i * 6, my + mh - 32, mx + 34 + i * 6, my + 2, "white" if i != 1 else "cream")
	L.line(img, mx + 48, my + 40, mx + 60, my + 20, "white")
	# trinca: estrela a partir do ponto do golpe, com um caco faltando e fita crepe
	var hit := Vector2i(mx + 40, my + 50)
	var rays := [[-28, -30], [-36, 8], [-10, 38], [16, 36], [22, -6], [12, -46], [-6, -48]]
	for r in rays:
		var ex := clampi(hit.x + int(r[0]), mx, mx + mw - 1)
		var ey := clampi(hit.y + int(r[1]), my, my + mh - 1)
		L.line(img, hit.x, hit.y, ex, ey, "g1")
		L.line(img, hit.x + 1, hit.y, mini(ex + 1, mx + mw - 1), ey, "white")
	L.trap(img, hit.y - 3, hit.y + 3, hit.x - 2, hit.x + 1, hit.x - 4, hit.x + 3, "d2")
	L.P(img, hit.x, hit.y, "ink")
	L.ring(img, hit.x, hit.y, 9, 8, 1, "g1")
	# fita crepe em X segurando os cacos
	for i in 14:
		L.P(img, hit.x - 12 + i, hit.y - 10 + i, "cream"); L.P(img, hit.x - 12 + i, hit.y - 9 + i, "g3")
		L.P(img, hit.x + 4 - i, hit.y - 10 + i, "cream"); L.P(img, hit.x + 4 - i, hit.y - 9 + i, "g3")
	# pôsteres desbotados (originais)
	var p1 := poster(26, 36, "r2", "r0", "LUTA", rng)
	L.stamp(img, p1, 182, 56)
	var p2 := poster(22, 30, "b2", "b0", "SÁB", rng)
	L.stamp(img, p2, 212, 66)
	for c in [Vector2i(182, 56), Vector2i(206, 56), Vector2i(212, 66), Vector2i(232, 66)]:
		L.R(img, c.x, c.y - 1, 3, 2, "cream")
	# relógio de parede
	L.ellipse(img, 244, 46, 7, 7, "ink")
	L.ellipse(img, 244, 46, 6, 6, "white")
	L.ring(img, 244, 46, 6, 6, 1, "st1")
	L.R(img, 244, 41, 1, 5, "ink"); L.R(img, 244, 46, 3, 1, "ink"); L.P(img, 244, 46, "r2")
	# prateleira (o Metrônomo fica em 240,118, na ponta da direita)
	L.R(img, 190, 118, 64, 3, "br2"); L.R(img, 190, 118, 64, 1, "br3"); L.R(img, 190, 121, 64, 1, "br0")
	L.R(img, 196, 122, 2, 7, "st1"); L.line(img, 197, 128, 203, 122, "st1")
	L.R(img, 246, 122, 2, 7, "st1"); L.line(img, 247, 128, 241, 122, "st1")
	# troféu pequeno, rolo de fita, garrafas
	var tr: Image = L.blank(9, 14)
	L.R(tr, 1, 0, 7, 5, "y0"); L.R(tr, 2, 0, 2, 4, "y1"); L.R(tr, 0, 1, 1, 3, "y0"); L.R(tr, 8, 1, 1, 3, "y0")
	L.R(tr, 3, 5, 3, 3, "br3"); L.R(tr, 1, 8, 7, 2, "br1"); L.R(tr, 0, 10, 9, 4, "br0"); L.R(tr, 2, 11, 5, 1, "y0")
	L.stamp(img, tr, 194, 104)
	var tp: Image = L.blank(8, 6)
	L.ellipse(tp, 4, 3, 4, 3, "cream"); L.ellipse(tp, 4, 3, 1.5, 1.2, "br1"); L.R(tp, 0, 4, 8, 2, "g3")
	L.stamp(img, tp, 207, 112)
	for i in 2:
		var bt: Image = L.blank(5, 12)
		L.R(bt, 1, 0, 3, 3, "st3"); L.R(bt, 0, 3, 5, 9, "b2" if i == 0 else "gr2"); L.R(bt, 3, 4, 1, 6, "b3" if i == 0 else "gr3")
		L.stamp(img, bt, 218 + i * 7, 106)
	# quadro da mensalidade (cortiça com papéis; um com carimbo vermelho)
	L.R(img, 178, 128, 50, 18, "ink")
	L.R(img, 179, 129, 48, 16, "br3")
	L.R(img, 179, 129, 48, 1, "y0")
	for i in 30:
		L.P(img, rng.randi_range(179, 226), rng.randi_range(130, 144), "br2")
	L.R(img, 182, 131, 12, 12, "white"); L.R(img, 183, 133, 9, 1, "g2"); L.R(img, 183, 135, 8, 1, "g2"); L.R(img, 183, 137, 9, 1, "g2")
	L.R(img, 185, 139, 6, 3, "r2"); L.P(img, 188, 131, "r1")
	L.R(img, 197, 132, 11, 10, "cream"); L.R(img, 198, 134, 8, 1, "g2"); L.R(img, 198, 136, 7, 1, "g2"); L.P(img, 202, 132, "b1")
	L.R(img, 211, 130, 13, 8, "y1"); L.R(img, 212, 132, 10, 1, "br2"); L.R(img, 212, 134, 8, 1, "br2"); L.P(img, 217, 130, "gr1")
	# banco de madeira encostado no barrado, com toalha e mochila
	L.R(img, 176, 204, 64, 4, "br2"); L.R(img, 176, 204, 64, 1, "br3"); L.R(img, 176, 207, 64, 1, "br0")
	L.R(img, 180, 208, 3, 12, "br1"); L.R(img, 232, 208, 3, 12, "br1")
	L.R(img, 178, 205, 1, 1, "ink")
	L.R(img, 186, 198, 14, 6, "b2"); L.R(img, 186, 198, 14, 1, "b3"); L.R(img, 193, 204, 7, 8, "b2"); L.R(img, 193, 204, 1, 8, "b1")
	L.rrect(img, 214, 194, 18, 10, "r1"); L.R(img, 215, 195, 16, 1, "r2"); L.R(img, 214, 198, 18, 1, "r0"); L.R(img, 221, 192, 4, 2, "d1")
	L.ellipse_dither(img, 208, 221, 34, 2, "d1")
	# relógio de round (3 luzes) e luvas penduradas, entre o espelho e a porta
	L.R(img, 372, 78, 22, 18, "ink")
	L.R(img, 373, 79, 20, 16, "d1")
	L.R(img, 374, 80, 18, 7, "ink")
	L.text(img, "3:00", 375, 80, "r3")
	for i in 3:
		L.R(img, 375 + i * 6, 89, 4, 4, ["r2", "y0", "gr3"][i])
		L.P(img, 375 + i * 6, 89, "white" if i == 2 else ["r3", "y1", "y2"][i])
	L.R(img, 382, 96, 1, 6, "d2")
	# luvas de treino penduradas pelo cadarço (par)
	L.P(img, 382, 104, "st1"); L.P(img, 382, 105, "st2")
	L.line(img, 382, 105, 377, 112, "cream"); L.line(img, 382, 105, 388, 112, "cream")
	for gx in [372, 384]:
		var gl: Image = L.blank(10, 14)
		L.rrect(gl, 0, 0, 10, 11, "r1"); L.R(gl, 1, 1, 6, 1, "r2"); L.R(gl, 1, 8, 8, 2, "r0")
		L.R(gl, 1, 11, 8, 3, "white"); L.R(gl, 1, 13, 8, 1, "g3")
		L.stamp(img, gl, gx, 112)
	# extintor ao lado da porta
	L.rrect(img, 392, 172, 7, 18, "r1"); L.R(img, 393, 173, 2, 15, "r2"); L.R(img, 393, 170, 4, 2, "d2"); L.R(img, 393, 178, 5, 3, "cream")
	L.R(img, 394, 168, 1, 2, "ink")
	# porta da rua (madeira, vidro aramado no alto)
	var dx := 404
	var dy := 120
	var dw := 48
	L.R(img, dx - 3, dy - 3, dw + 6, FLOOR_Y - dy + 3, "ink")
	L.R(img, dx - 2, dy - 2, dw + 4, FLOOR_Y - dy + 2, "g3")
	L.R(img, dx, dy, dw, FLOOR_Y - dy, "br2")
	L.R(img, dx, dy, dw, 1, "br3")
	L.R(img, dx + dw - 2, dy, 2, FLOOR_Y - dy, "br1")
	for yy in range(dy + 4, FLOOR_Y, 9):
		L.R(img, dx + 2, yy, dw - 4, 1, "br1")
	L.R(img, dx + 8, dy + 6, dw - 16, 26, "ink")
	L.R(img, dx + 9, dy + 7, dw - 18, 24, "b3")
	for yy in range(dy + 9, dy + 31, 4):
		for xx in range(dx + 9, dx + dw - 9, 4):
			L.P(img, xx, yy, "b2")
	L.line(img, dx + 12, dy + 28, dx + 22, dy + 10, "white")
	L.R(img, dx + dw - 9, dy + 50, 4, 3, "y0"); L.P(img, dx + dw - 9, dy + 50, "y1")
	L.R(img, dx + 2, FLOOR_Y - 14, dw - 4, 12, "st1"); L.R(img, dx + 2, FLOOR_Y - 14, dw - 4, 1, "st3")
	# plaquinha "ABERTO" pendurada no vidro
	L.R(img, dx + 15, dy + 34, 18, 7, "ink"); L.R(img, dx + 16, dy + 35, 16, 5, "gr2")
	L.R(img, dx + 18, dy + 37, 12, 1, "white")
	# halteres no canto do fundo à direita
	for i in 2:
		var hx := 456 + i * 6
		L.R(img, hx, 214, 5, 5, "d1"); L.R(img, hx, 214, 5, 1, "st1"); L.R(img, hx + 2, 212, 1, 2, "st2")
	# prego da corda (a corda é sprite) — chapinha de gancho
	L.R(img, NAIL.x - 1, NAIL.y - 1, 3, 3, "st1"); L.P(img, NAIL.x, NAIL.y, "ink"); L.P(img, NAIL.x, NAIL.y + 1, "st3")

func gym_after_light(img: Image) -> void:
	# tubos acesos por cima da luz (não escurecem)
	for t in TUBES:
		L.blit(img, tube_sprite(false), t.x - 24, t.y)
		# brilho fino dos tubos na parede logo abaixo
		for xx in range(t.x - 20, t.x + 20):
			if xx % 2 == 0:
				L.P(img, xx, t.y + 10, "white")

# ================================================================ aparelhos básicos na versão da academia
func bag_body_gym(level: int) -> Image:
	var bag: Image = L.blank(30, 62)
	if level == 0:
		# couro marrom gasto com tiras creme
		L.rrect(bag, 0, 4, 30, 58, "br1")
		L.R(bag, 2, 0, 26, 6, "d1"); L.R(bag, 2, 0, 26, 1, "g0")
		L.R(bag, 0, 6, 6, 54, "br0"); L.R(bag, 19, 8, 4, 50, "br2"); L.R(bag, 20, 10, 1, 9, "br3")
		L.R(bag, 1, 59, 28, 3, "br0")
		for yy in range(9, 58, 4):
			L.P(bag, 10, yy, "br0"); L.P(bag, 25, yy + 2, "br0")
		for ty in [11, 46]:
			L.R(bag, 0, ty, 30, 3, "cream"); L.R(bag, 0, ty + 2, 30, 1, "g3"); L.R(bag, 0, ty, 6, 3, "g3")
			L.P(bag, 14, ty + 1, "st2")
		# couro rachado
		L.line(bag, 12, 24, 15, 30, "br0"); L.line(bag, 15, 30, 13, 34, "br0")
		L.P(bag, 22, 38, "br3")
	else:
		# couro preto com faixas vermelhas (saco de academia de verdade)
		L.rrect(bag, 0, 4, 30, 58, "d2")
		L.R(bag, 2, 0, 26, 6, "ink"); L.R(bag, 2, 0, 26, 1, "d2")
		for xx in range(4, 27, 3):
			L.P(bag, xx, 4, "g0")
		L.R(bag, 0, 6, 6, 54, "d1"); L.R(bag, 0, 8, 2, 50, "ink")
		L.R(bag, 19, 8, 4, 50, "g0"); L.R(bag, 20, 10, 1, 12, "g2")
		L.R(bag, 1, 58, 28, 4, "d1")
		for ty in [12, 44]:
			L.R(bag, 0, ty, 30, 4, "r2"); L.R(bag, 0, ty + 3, 30, 1, "r1"); L.R(bag, 0, ty, 6, 4, "r1"); L.R(bag, 20, ty, 2, 1, "r3")
		# emblema redondo
		L.ellipse(bag, 15, 30, 5, 5, "cream"); L.ellipse(bag, 15, 30, 3.5, 3.5, "r1"); L.R(bag, 14, 28, 2, 4, "y1")
	return bag

func bag_frame_gym(level: int, lean: int, dent: int) -> Image:
	var out: Image = L.blank(40, 76)
	L.line(out, 20, 4, 8, 9, "st2"); L.line(out, 19, 4, 31, 9, "st2")
	L.ring(out, 20, 3, 3, 3, 1, "st3")
	var body := bag_body_gym(level)
	var sh: Image = L.blank(38, 62)
	for y in 62:
		var off := int(round(lean * float(y) / 61.0))
		sh.blit_rect(body, Rect2i(0, y, 30, 1), Vector2i(4 + off, y))
	if dent > 0:
		for y in range(18, 42):
			var dd := int(round(dent * (1.0 - absf(y - 30) / 12.0)))
			if dd <= 0:
				continue
			var x0 := 0
			while x0 < 38 and sh.get_pixel(x0, y).a == 0.0:
				x0 += 1
			for x in range(x0, mini(x0 + dd, 38)):
				sh.set_pixel(x, y, Color(0, 0, 0, 0))
			if x0 + dd < 38:
				sh.set_pixel(x0 + dd, y, L.shade(sh.get_pixel(x0 + dd, y), -1))
	L.stamp(out, sh, 1, 7)
	return out

func make_bag_gym() -> void:
	var names := ["Saco de couro marrom (academia, nível visual 0)", "Saco preto com faixas vermelhas (academia, nível visual 1)"]
	for lv in 2:
		var idle := []
		var leans := [0, 1, 0, -1]
		for i in 4:
			idle.append(bag_frame_gym(lv, leans[i], 0))
		save_sheet("bag_l%d_idle_gym" % lv, "equipment/bag_l%d_idle_gym.png" % lv, idle, 3, Vector2i(20, 0), {
			"loop": true, "positions": {"centro": xy(P_BAG_CENTER), "lado_esquerdo": xy(P_BAG_LEFT)}, "sort_y_offset": 70,
			"note": names[lv] + ". Mesmo quadro, pivô e animação do bag_l%d_idle (sufixo _gym do locations.json)." % lv})
		var hit := []
		var seq := [[4, 2], [2, 1], [-1, 0], [0, 0]]
		for i in 4:
			hit.append(bag_frame_gym(lv, seq[i][0], seq[i][1]))
		save_sheet("bag_l%d_hit_gym" % lv, "equipment/bag_l%d_hit_gym.png" % lv, hit, 12, Vector2i(20, 0), {
			"loop": false, "positions": {"centro": xy(P_BAG_CENTER)}, "sort_y_offset": 70,
			"note": names[lv] + ", reação ao clique (igual ao bag_l%d_hit)." % lv})
		var side := []
		for fr in idle:
			side.append(gym_lit(fr, P_BAG_LEFT - Vector2i(20, 0)))
		save_sheet("bag_l%d_side_gym" % lv, "equipment/bag_l%d_side_gym.png" % lv, side, 3, Vector2i(20, 0), {
			"loop": true, "positions": {"lado_esquerdo": xy(P_BAG_LEFT)}, "sort_y_offset": 70,
			"note": names[lv] + ", no lado esquerdo com a luz dos tubos aplicada."}, false)

func treadmill_gym(level: int, f: int, moving: bool) -> Image:
	var tm: Image = L.blank(86, 42)
	var m: Array = ["g2", "g3", "white"]
	# lona
	L.R(tm, 8, 30, 76, 2, "ink")
	for x in range(9, 83):
		var ph := ((x - f * 2) % 8 + 8) % 8
		if ph < 2:
			L.P(tm, x, 30, "d2" if level == 0 else "g0")
	L.R(tm, 8, 32, 76, 6, m[1]); L.R(tm, 8, 32, 76, 1, m[2]); L.R(tm, 8, 37, 76, 1, m[0])
	L.R(tm, 8, 34, 76, 1, "gr2" if level == 1 else "g3")
	for rx in [10, 82]:
		L.ellipse(tm, rx, 34, 3, 3, "st1")
		var a := f * PI / 2.0
		L.P(tm, rx + int(round(cos(a) * 1.5)), 34 + int(round(sin(a) * 1.5)), "st3")
	L.R(tm, 12, 38, 4, 3, "d1"); L.R(tm, 76, 38, 4, 3, "d1")
	# coluna e corrimão
	L.line(tm, 12, 30, 6, 6, m[1]); L.line(tm, 13, 30, 7, 6, m[1]); L.line(tm, 14, 30, 8, 6, m[2])
	L.R(tm, 7, 11, 26, 2, "st3"); L.R(tm, 7, 11, 26, 1, "white")
	# painel com visor verde aceso
	L.R(tm, 0, 0, 17, 8, m[1]); L.R(tm, 0, 0, 17, 1, m[2]); L.R(tm, 0, 7, 17, 1, m[0])
	L.R(tm, 2, 2, 10, 4, "ink")
	if moving:
		var bars: Array = [[1, 3, 2, 4], [2, 4, 3, 1], [3, 1, 4, 2], [4, 2, 1, 3]][f % 4]
		for i in 4:
			L.R(tm, 3 + i * 2, 6 - bars[i], 1, bars[i], "gr3")
	else:
		L.R(tm, 3, 3, 8, 2, "gr1"); L.R(tm, 3, 4, 6, 1, "gr3")
	L.P(tm, 14, 3, "r2" if level == 1 else "g1")     # chave de segurança vermelha (nível 1)
	if level == 1:
		L.R(tm, 14, 4, 1, 3, "r1")
		L.P(tm, 81, 32, "white")
	var o: Image = L.blank(86, 42)
	L.stamp(o, tm.get_region(Rect2i(0, 0, 85, 41)), 1, 1)
	return o

func make_treadmill_gym() -> void:
	var names := ["Esteira branca com visor verde (academia, nível visual 0)", "Esteira branca com faixa verde e chave vermelha (academia, nível visual 1)"]
	for lv in 2:
		save_sheet("treadmill_l%d_idle_gym" % lv, "equipment/treadmill_l%d_idle_gym.png" % lv, [treadmill_gym(lv, 0, false)], 0, Vector2i(43, 41), {
			"positions": {"centro": xy(P_TM_CENTER), "lado_direito": xy(P_TM_RIGHT)},
			"note": names[lv] + ", parada. Mesmo quadro e pivô da treadmill_l%d_idle." % lv})
		var run := []
		for f in 4:
			run.append(treadmill_gym(lv, f, true))
		save_sheet("treadmill_l%d_run_gym" % lv, "equipment/treadmill_l%d_run_gym.png" % lv, run, 12, Vector2i(43, 41), {
			"loop": true, "positions": {"centro": xy(P_TM_CENTER)}, "note": names[lv] + ", rolando (igual à treadmill_l%d_run)." % lv})
		save_sheet("treadmill_l%d_side_gym" % lv, "equipment/treadmill_l%d_side_gym.png" % lv, [gym_lit(treadmill_gym(lv, 0, false), P_TM_RIGHT - Vector2i(43, 41))], 0, Vector2i(43, 41), {
			"positions": {"lado_direito": xy(P_TM_RIGHT)}, "note": names[lv] + ", parada no lado direito com a luz dos tubos."}, false)

func rope_idle_gym(level: int) -> Image:
	var img: Image = L.blank(18, 40)
	var rc: Array = ["r1", "r2"] if level == 0 else ["st1", "st3"]
	L.ring(img, 9, 14, 7, 12, 2, rc[1])
	L.ring(img, 9, 14, 6, 11, 1, rc[0])
	# cabos (pretos no nível 0, madeira no nível 1)
	var hc: Array = ["d1", "d2"] if level == 0 else ["br1", "br3"]
	L.R(img, 2, 24, 3, 11, hc[1]); L.R(img, 2, 24, 1, 11, hc[0]); L.R(img, 2, 33, 3, 1, "st2")
	L.R(img, 13, 25, 3, 11, hc[1]); L.R(img, 13, 25, 1, 11, hc[0]); L.R(img, 13, 34, 3, 1, "st2")
	var o: Image = L.blank(18, 40)
	L.stamp(o, img.get_region(Rect2i(0, 1, 17, 38)), 1, 1)
	return o

func make_rope_gym() -> void:
	var names := ["Corda de PVC vermelha com cabos pretos (academia, nível visual 0)", "Corda de aço encapada com cabos de madeira (academia, nível visual 1)"]
	for lv in 2:
		save_sheet("rope_l%d_idle_gym" % lv, "equipment/rope_l%d_idle_gym.png" % lv, [gym_lit(rope_idle_gym(lv), NAIL - Vector2i(9, 0))], 0, Vector2i(9, 0), {
			"positions": {"prego": xy(NAIL)}, "layer": "frente_do_fundo", "z": -40,
			"note": names[lv] + ", no gancho (mesmo ponto do prego da garagem). Luz dos tubos aplicada."})
		var src_id := "rope_l%d_swing" % lv
		var e := spr(src_id)
		var frames := []
		for i in int(e.frames):
			frames.append(recolor(frame_of(src_id, i), "r2" if lv == 0 else "st3", "r1" if lv == 0 else "st1"))
		save_sheet("rope_l%d_swing_gym" % lv, "equipment/rope_l%d_swing_gym.png" % lv, frames, float(e.fps), Vector2i(int(e.pivot[0]), int(e.pivot[1])), {
			"loop": false, "positions": {"foco_corda": xy(P_FIGHTER_ROPE)},
			"note": names[lv] + ", em uso: os mesmos quadros do %s recoloridos. Desenhar por cima do fighter_rope, mesmo quadro e pivô." % src_id})

# ================================================================ pera veloz (Boxe)
## Plataforma (tábua redonda vista de cima) com a pera pendurada. ang = inclinação da pera (graus, + = para a direita),
## up = quanto ela sobe/encurta (pera batida indo para trás). ox, oy = meio de cima da tábua.
func speed_bag_parts(img: Image, ox: int, oy: int, level: int, ang: float, up: float, blur := false) -> void:
	var wood: Array = ["br1", "br2", "br3"] if level == 0 else ["br0", "br1", "br2"]
	# tábua: elipse achatada (tampo) + borda grossa
	L.ellipse(img, ox, oy + 5, 18, 4, "ink")
	L.ellipse(img, ox, oy + 4, 17, 3.2, wood[2] if level == 0 else wood[1])
	L.R(img, ox - 16, oy + 5, 33, 3, wood[0])
	L.ellipse(img, ox, oy + 7, 17, 2, wood[0])
	L.ellipse(img, ox, oy + 8, 17, 1.6, "ink")
	if level == 1:
		L.R(img, ox - 12, oy + 3, 10, 1, "y0")      # verniz
		L.P(img, ox + 9, oy + 4, "y1")
	else:
		L.P(img, ox - 8, oy + 4, wood[1]); L.P(img, ox + 6, oy + 3, wood[1]); L.P(img, ox + 11, oy + 5, wood[1])
	# girador
	L.R(img, ox - 1, oy + 9, 3, 2, "st1"); L.P(img, ox, oy + 9, "st3")
	# pera: gota (pescoço fino em cima, barriga embaixo), desenhada ao longo do eixo
	var a := deg_to_rad(ang)
	var dirv := Vector2(sin(a), cos(a))
	var top := Vector2(ox + 0.5, oy + 11)
	var length := 20.0 - up
	var col: Array = ["r0", "r1", "r2"] if level == 0 else ["r1", "r2", "r3"]
	var shape := Image.create_empty(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var steps := int(length * 2)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var p := top + dirv * (t * length)
		var r := lerpf(1.2, 6.2, smoothstep(0.0, 0.62, t))
		if t > 0.78:
			r = lerpf(6.2, 3.0, (t - 0.78) / 0.22)
		L.ellipse(shape, p.x, p.y, r, r * (0.85 if up > 4.0 else 1.0), col[1])
	# sombra do lado esquerdo e luz à direita (luz vem de cima)
	var sh2: Image = shape.duplicate()
	for y in shape.get_height():
		for x in shape.get_width():
			if shape.get_pixel(x, y).a == 0.0:
				continue
			var lft := x - 2 >= 0 and shape.get_pixel(x - 2, y).a == 0.0
			var rgt := x + 2 < shape.get_width() and shape.get_pixel(x + 2, y).a == 0.0
			var bot := y + 2 < shape.get_height() and shape.get_pixel(x, y + 2).a == 0.0
			if lft or bot:
				sh2.set_pixel(x, y, L.C[col[0]])
			elif rgt and y % 2 == 0:
				sh2.set_pixel(x, y, L.C[col[2]])
	var mid := top + dirv * (length * 0.55)
	L.P(sh2, int(mid.x) + 2, int(mid.y) - 3, "white" if level == 1 else col[2])
	L.P(sh2, int(mid.x) + 2, int(mid.y) - 2, col[2])
	if level == 0:
		# remendo de fita crepe na barriga
		L.R(sh2, int(mid.x) - 3, int(mid.y) + 1, 5, 2, "g3"); L.P(sh2, int(mid.x) - 3, int(mid.y) + 1, "cream")
	else:
		# costura branca no meio
		for i in range(2, int(length) - 2, 2):
			var q := top + dirv * float(i)
			L.P(sh2, int(q.x), int(q.y), "cream")
	L.blit(img, L.outlined(sh2), -1, -1)
	if blur:
		# riscos de velocidade do lado de onde veio o soco
		for i in 3:
			L.R(img, int(mid.x) - 12 - i * 2, int(mid.y) - 4 + i * 4, 5, 1, "white")

func speed_bag_stand(level: int, ang: float, up: float, blur := false) -> Image:
	var img: Image = L.blank(SB_FRAME.x, SB_FRAME.y)
	var ox := SB_PIVOT.x
	var oy := 4
	# haste atrás da pera, do tampo até o pé
	var post: Image = L.blank(SB_FRAME.x, SB_FRAME.y)
	L.R(post, ox, oy + 8, 4, SB_PIVOT.y - oy - 10, "st1")
	L.R(post, ox + 1, oy + 8, 1, SB_PIVOT.y - oy - 10, "st3")
	L.R(post, ox + 3, oy + 8, 1, SB_PIVOT.y - oy - 10, "st0")
	# braço que segura a tábua (de trás)
	L.R(post, ox - 2, oy + 6, 8, 3, "st0")
	# pé em H com peso
	L.R(post, ox - 14, SB_PIVOT.y - 3, 32, 3, "st0"); L.R(post, ox - 14, SB_PIVOT.y - 3, 32, 1, "st2")
	if level == 0:
		L.rrect(post, ox - 8, SB_PIVOT.y - 8, 20, 6, "br3"); L.R(post, ox - 7, SB_PIVOT.y - 8, 18, 1, "y0"); L.R(post, ox - 7, SB_PIVOT.y - 4, 18, 1, "br2")   # saco de areia
	else:
		L.rrect(post, ox - 7, SB_PIVOT.y - 7, 18, 5, "d1"); L.R(post, ox - 6, SB_PIVOT.y - 7, 16, 1, "g0"); L.P(post, ox + 2, SB_PIVOT.y - 5, "st3")  # anilha
	L.blit(img, ol(post), 0, 0)
	speed_bag_parts(img, ox, oy, level, ang, up, blur)
	return img

func speed_bag_wall(level: int, ang: float, up: float) -> Image:
	var img: Image = L.blank(SBW_FRAME.x, SBW_FRAME.y)
	var ox := SBW_PIVOT.x
	# tábua de fundo parafusada na parede
	var b: Image = L.blank(SBW_FRAME.x, SBW_FRAME.y)
	var wood: Array = ["br1", "br2", "br3"] if level == 0 else ["br0", "br1", "br2"]
	L.R(b, ox - 20, 1, 41, 9, wood[1]); L.R(b, ox - 20, 1, 41, 1, wood[2]); L.R(b, ox - 20, 9, 41, 1, wood[0])
	for sx in [ox - 17, ox + 17]:
		L.P(b, sx, 4, "st3"); L.P(b, sx, 5, "st0")
	# mãos-francesas
	L.line(b, ox - 14, 10, ox - 8, 16, "st1"); L.line(b, ox - 13, 10, ox - 7, 16, "st0")
	L.line(b, ox + 14, 10, ox + 8, 16, "st1"); L.line(b, ox + 15, 10, ox + 9, 16, "st0")
	L.blit(img, ol(b), 0, 0)
	speed_bag_parts(img, ox, 8, level, ang, up)
	return img

func make_speed_bag() -> void:
	var names := ["Pera vermelha remendada, tábua de compensado, pé com saco de areia (nível visual 0)", "Pera de couro vermelho com costura, tábua envernizada, pé com anilha (nível visual 1: 'Jab duplo')"]
	for lv in 2:
		var idle := [speed_bag_stand(lv, 0.0, 0.0), speed_bag_stand(lv, 3.0, 0.0)]
		save_sheet("speed_bag_l%d_idle" % lv, "equipment/speed_bag_l%d_idle.png" % lv, idle, 2, SB_PIVOT, {
			"loop": true, "positions": {"centro": xy(SB_CENTER)}, "sort_y": 268,
			"note": names[lv] + ". No CENTRO (foco = pera): pedestal em pé, tábua na altura do rosto do lutador, pera na altura do soco (y 215–226). Balanço leve de 1 px. Pivô = meio do pé, no chão. Ordenar como y 268 (o lutador, y 272, fica na frente)."})
		var hit := [speed_bag_stand(lv, 10.0, 9.0, true), speed_bag_stand(lv, 38.0, 2.0), speed_bag_stand(lv, -26.0, 1.0), speed_bag_stand(lv, 12.0, 0.0), speed_bag_stand(lv, -4.0, 0.0)]
		save_sheet("speed_bag_l%d_hit" % lv, "equipment/speed_bag_l%d_hit.png" % lv, hit, 18, SB_PIVOT, {
			"loop": false, "positions": {"centro": xy(SB_CENTER)}, "sort_y": 268,
			"hit_point": [325, 218],
			"note": names[lv] + ". Reação ao clique: a pera vai para trás e sobe (0), bate na tábua e volta para a direita (1), esquerda (2) e assenta (3, 4). 18 fps: é bem mais rápida que o saco (é a graça da pera). Começar junto com o quadro de golpe do fighter_punch. Efeito de impacto em hit_point."})
		var wall := speed_bag_wall(lv, 0.0, 0.0)
		save_sheet("speed_bag_l%d_wall" % lv, "equipment/speed_bag_l%d_wall.png" % lv, [garage_lit(wall, SB_WALL - SBW_PIVOT, -1)], 0, SBW_PIVOT, {
			"positions": {"parede": xy(SB_WALL)}, "layer": "frente_do_fundo", "z": -40,
			"note": names[lv] + ". DESCANSO (foco em outro aparelho): plataforma presa na parede, acima da porta, com a luz da lâmpada da garagem. Pivô = meio de cima da tábua."})
		save_sheet("speed_bag_l%d_wall_gym" % lv, "equipment/speed_bag_l%d_wall_gym.png" % lv, [gym_lit(wall, SB_WALL - SBW_PIVOT)], 0, SBW_PIVOT, {
			"positions": {"parede": xy(SB_WALL)}, "layer": "frente_do_fundo", "z": -40,
			"note": names[lv] + ". Descanso na academia (mesmo ponto, luz dos tubos)."}, false)
	# balanço depois de chegar (pendurada agora): 6 quadros, só o nível 0 (sempre chega no 0)
	var angs := [24.0, -18.0, 12.0, -7.0, 3.0, 0.0]
	for suf in ["", "_gym"]:
		var fr := []
		for a in angs:
			var w := speed_bag_wall(0, a, 0.0)
			fr.append(garage_lit(w, SB_WALL - SBW_PIVOT, -1) if suf == "" else gym_lit(w, SB_WALL - SBW_PIVOT))
		save_sheet("speed_bag_l0_wall_swing" + suf, "equipment/speed_bag_l0_wall_swing%s.png" % suf, fr, 12, SBW_PIVOT, {
			"loop": false, "positions": {"parede": xy(SB_WALL)}, "layer": "frente_do_fundo", "z": -40,
			"note": "Chegada da pera: depois da queda (offsets do unlock_speed_bag), a pera balança e assenta. 6 quadros a 12 fps, sem loop; depois volta para speed_bag_l0_wall%s." % suf}, suf == "")

# ================================================================ boneco de tatame (Jiu-jitsu)
func mat_piece(img: Image, cx: int, front: int, half_front: float, depth: int, level: int, rng_seed: int) -> void:
	var k := float(front - depth + 28) / float(front + 28)
	var bl := VPX + (cx - half_front - VPX) * k
	var br := VPX + (cx + half_front - VPX) * k
	var top := front - depth
	var c: Array = ["b0", "b1", "b2"] if level == 0 else ["b1", "b2", "b3"]
	# espessura (frente)
	L.R(img, int(cx - half_front), front - 2, int(half_front * 2) + 1, 3, c[0])
	L.trap(img, top, front - 2, bl, br, cx - half_front, cx + half_front, c[1])
	L.trap(img, top, top, bl, br, bl, br, c[2])
	# costura da borda
	for x in range(int(cx - half_front) + 2, int(cx + half_front) - 1, 3):
		L.P(img, x, front - 3, c[2])
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	if level == 0:
		for i in 18:
			L.P(img, rng.randi_range(int(bl) + 2, int(br) - 2), rng.randi_range(top + 1, front - 4), "g1" if i % 3 == 0 else c[0])
		# canto descascado com fita
		L.R(img, int(cx + half_front) - 9, front - 6, 6, 2, "g3"); L.R(img, int(cx + half_front) - 9, front - 6, 6, 1, "cream")
	else:
		L.R(img, int(bl) + 3, top + 1, int(br - bl) - 6, 1, "white")

## Boneco sentado de perfil, olhando para a esquerda (para o lutador). squash = afunda (px), lean = topo vai para a direita.
func dummy_body_sit(img: Image, hx: int, hy: int, level: int, squash: int, lean: int) -> void:
	var cl: Array = ["g2", "g3", "cream"] if level == 0 else ["b1", "b2", "b3"]
	var body: Image = L.blank(img.get_width(), img.get_height())
	var hip := Vector2(hx, hy)
	var sh := Vector2(hx + 2 + lean, hy - 28 + squash)
	var head := Vector2(hx + 1 + lean * 1.4, hy - 38 + squash)
	# perna de trás (dobrada), tronco, cabeça, braço e perna da frente
	capsule(body, hip + V(-1, 1), V(hx - 13, hy - 6 + squash / 2), 4.0, [cl[0], cl[0], cl[1]])
	capsule(body, V(hx - 13, hy - 6 + squash / 2), V(hx - 20, hy + 3), 3.4, [cl[0], cl[0], cl[1]])
	capsule(body, hip, sh, 7.0 + squash * 0.3, cl)
	L.ellipse(body, head.x, head.y, 6.0 + squash * 0.2, 6.0 - squash * 0.3, cl[1])
	L.ellipse(body, head.x - 1.5, head.y - 2, 3, 2.4, cl[2])
	capsule(body, sh + V(-3, 3), sh + V(-13, 9 + squash / 2), 2.8, cl)
	capsule(body, hip + V(-2, 2), V(hx - 16, hy - 8 + squash / 2), 4.4, cl)
	capsule(body, V(hx - 16, hy - 8 + squash / 2), V(hx - 23, hy + 2), 3.6, cl)
	# costuras / alças
	if level == 0:
		for i in range(0, 22, 3):
			L.P(body, int(hip.x + (sh.x - hip.x) * i / 28.0) - 4, int(hip.y + (sh.y - hip.y) * i / 28.0), "g1")
		L.R(body, int(sh.x) - 3, int(sh.y) + 8, 6, 3, "st2"); L.R(body, int(sh.x) - 3, int(sh.y) + 8, 6, 1, "st3")    # fita prata
		L.P(body, int(head.x) - 3, int(head.y) + 3, "g1")
	else:
		L.R(body, int(sh.x) + 3, int(sh.y) + 1, 2, 10, "white"); L.R(body, int(sh.x) + 3, int(sh.y) + 1, 1, 10, "g3")   # alça
		L.R(body, int(hip.x) - 6, int(hip.y) - 8, 13, 2, "ink"); L.R(body, int(hip.x) - 6, int(hip.y) - 8, 13, 1, "d1")   # faixa preta
		L.R(body, int(hip.x) - 9, int(hip.y) - 7, 3, 5, "d1")
	L.blit(img, L.outlined(body), -1, -1)

func dummy_sit(level: int, squash: int, lean: int) -> Image:
	var img: Image = L.blank(GD_FRAME.x, GD_FRAME.y)
	mat_piece(img, GD_PIVOT.x, GD_PIVOT.y, 31.0, 13, level, 9)
	L.ellipse_dither(img, GD_PIVOT.x + 4, GD_PIVOT.y - 6, 16, 3, "ink")
	dummy_body_sit(img, GD_PIVOT.x + 8, GD_PIVOT.y - 7, level, squash, lean)
	return img

## Boneco deitado de costas (descanso): cabeça à direita, joelhos para cima.
func dummy_lying(level: int) -> Image:
	var img: Image = L.blank(GDR_FRAME.x, GDR_FRAME.y)
	mat_piece(img, GDR_PIVOT.x, GDR_PIVOT.y, 31.0, 13, level, 4)
	var cl: Array = ["g2", "g3", "cream"] if level == 0 else ["b1", "b2", "b3"]
	var body: Image = L.blank(GDR_FRAME.x, GDR_FRAME.y)
	var y := GDR_PIVOT.y - 9
	capsule(body, V(22, y), V(44, y - 1), 5.0, cl)          # tronco
	L.ellipse(body, 51, y - 2, 5.2, 4.6, cl[1]); L.ellipse(body, 50, y - 4, 2.6, 1.6, cl[2])
	capsule(body, V(22, y), V(14, y - 9), 3.8, cl)          # coxa (joelho para cima)
	capsule(body, V(14, y - 9), V(7, y - 1), 3.0, cl)       # canela
	capsule(body, V(38, y - 4), V(42, y - 11), 2.4, cl)     # braço para o alto
	if level == 0:
		L.R(body, 30, y - 3, 5, 3, "st2"); L.R(body, 30, y - 3, 5, 1, "st3")
	else:
		L.R(body, 23, y - 4, 2, 8, "ink"); L.R(body, 36, y - 5, 2, 7, "white")
	L.blit(img, L.outlined(body), -1, -1)
	return img

func make_grappling_dummy() -> void:
	var names := ["Boneco de lona crua com remendo de fita prata, num tatame azul velho (nível visual 0)", "Boneco de couro azul com alças e faixa preta, num tatame novo (nível visual 1: 'Guarda fechada')"]
	for lv in 2:
		save_sheet("grappling_dummy_l%d_idle" % lv, "equipment/grappling_dummy_l%d_idle.png" % lv, [dummy_sit(lv, 0, 0)], 0, GD_PIVOT, {
			"positions": {"centro": xy(GD_CENTER)}, "sort_y": 266,
			"note": names[lv] + ". No CENTRO (foco = boneco): sentado de perfil, de frente para o lutador, sobre o pedaço de tatame. Pivô = meio da frente do tatame, no chão. Ordenar como y 266 (o lutador fica na frente e pisa na ponta do tatame)."})
		save_sheet("grappling_dummy_l%d_hit" % lv, "equipment/grappling_dummy_l%d_hit.png" % lv,
			[dummy_sit(lv, 2, 0), dummy_sit(lv, 1, 2), dummy_sit(lv, 0, -1)], 12, GD_PIVOT, {
			"loop": false, "positions": {"centro": xy(GD_CENTER)}, "sort_y": 266, "hit_point": [330, 232],
			"note": names[lv] + ". Reação ao clique: amassa 2 px (0), tomba 2 px para trás (1), volta com 1 px de sobra (2), depois _idle. Efeito em hit_point."})
		var rest := dummy_lying(lv)
		save_sheet("grappling_dummy_l%d_rest" % lv, "equipment/grappling_dummy_l%d_rest.png" % lv, [garage_lit(rest, GD_REST - GDR_PIVOT, -1)], 0, GDR_PIVOT, {
			"positions": {"canto": xy(GD_REST)}, "sort_y": 270,
			"note": names[lv] + ". DESCANSO (foco em outro aparelho): deitado de costas no tatame, no canto da frente à esquerda, com a luz da garagem. Ordenar como y 270."})
		save_sheet("grappling_dummy_l%d_rest_gym" % lv, "equipment/grappling_dummy_l%d_rest_gym.png" % lv, [gym_lit(rest, GD_REST - GDR_PIVOT)], 0, GDR_PIVOT, {
			"positions": {"canto": xy(GD_REST)}, "sort_y": 270,
			"note": names[lv] + ". Descanso na academia (em cima do tatame gasto do canto, luz dos tubos)."}, false)

# ================================================================ marcas de fita, silhuetas, plaquinhas
func padlock(img: Image, x: int, y: int, body: Array, shackle := "st3") -> void:
	pmap(img, x, y, [
		"..kkk..",
		".kssskk",
		".ks.sk.",
		".ks.sk.",
		"kkkkkkk",
		"khhhhbk",
		"kbbkbbk",
		"kbbkbdk",
		"kdddddk",
		"kkkkkkk"], {"k": "ink", "s": shackle, "h": body[2], "b": body[1], "d": body[0]})

const LOCK_GOLD := ["br2", "y0", "y1"]
const LOCK_GRAY := ["g0", "g1", "g2"]

func tape_h(img: Image, x0: int, x1: int, y: int, thick := 2) -> void:
	for x in range(x0, x1 + 1):
		var torn := (x == x0 or x == x1)
		for t in thick:
			if torn and t == (0 if (x + y) % 2 == 0 else thick - 1):
				continue
			L.P(img, x, y + t, "cream" if t < thick - 1 else "g3")

func tape_v(img: Image, x: int, y0: int, y1: int, thick := 2) -> void:
	for y in range(y0, y1 + 1):
		var torn := (y == y0 or y == y1)
		for t in thick:
			if torn and t == (0 if (x + y) % 2 == 0 else thick - 1):
				continue
			L.P(img, x + t, y, "cream" if t < thick - 1 else "g3")

func tape_slant(img: Image, xa: float, ya: int, xb: float, yb: int) -> void:
	for y in range(ya, yb + 1):
		var t := float(y - ya) / float(maxi(yb - ya, 1))
		var x := int(round(lerpf(xa, xb, t)))
		var torn := (y == ya or y == yb)
		if not torn or (x + y) % 2 == 0:
			L.P(img, x, y, "cream")
		L.P(img, x + 1, y, "g3")

func ghost_of(src: Image, lock_at: Vector2i) -> Image:
	var out: Image = L.blank(src.get_width(), src.get_height())
	for y in src.get_height():
		for x in src.get_width():
			if src.get_pixel(x, y).a > 0.0 and (x + y) % 2 == 0:
				out.set_pixel(x, y, L.C.ink)
	padlock(out, lock_at.x, lock_at.y, LOCK_GRAY)
	return out

func make_marks() -> void:
	# --- pera: quadro de fita na parede em volta da plataforma, com o contorno a caneta
	var w: Image = L.blank(56, 60)
	var ox := 4   # quadro começa 4 px antes da plataforma (x 432-28 = 408)
	tape_h(w, 1, 20, 2); tape_h(w, 28, 54, 2)
	tape_v(w, 1, 1, 57); tape_v(w, 53, 1, 57)
	tape_h(w, 1, 30, 57); tape_h(w, 34, 54, 57)
	# caneta: tábua, tampo e a gota
	var pen := [[ox + 6, 6], [ox + 46, 6], [ox + 46, 14], [ox + 6, 14]]
	for i in pen.size():
		if i % 2 == 0:
			var a: Array = pen[i]
			var b: Array = pen[(i + 1) % pen.size()]
			L.line(w, a[0], a[1], b[0], b[1], "d2")
	L.line(w, ox + 6, 14, ox + 6, 6, "d2")
	for i in range(0, 34, 3):
		L.P(w, ox + 7 + i, 18, "d2")
	var drop := [[28, 22], [25, 27], [23, 33], [24, 39], [28, 43], [32, 39], [33, 33], [31, 27]]
	for i in drop.size():
		if i % 2 == 0:
			var a2: Array = drop[i]
			var b2: Array = drop[(i + 1) % drop.size()]
			L.line(w, a2[0], a2[1], b2[0], b2[1], "d2")
	save_sheet("tape_mark_speed_bag", "garage/tape_mark_speed_bag.png", [w], 0, Vector2i(28, 4), {
		"positions": {"parede": xy(SB_WALL)}, "layer": "frente_do_fundo", "z": -41,
		"note": "Quadro de fita crepe na parede onde a plataforma da pera vai ficar (acima da porta), com a tábua e a gota desenhadas a caneta. Mesmo ponto da speed_bag_lN_wall. Vale na garagem e na academia. Some na chegada."})
	# --- boneco: contorno no chão em volta do tatame (perspectiva)
	var fw := 76
	var fh := 22
	var pv := Vector2i(38, 19)
	var g: Image = L.blank(fw, fh)
	var front := pv.y
	var back := front - 16
	var k := float(GD_REST.y - 16 + 28) / float(GD_REST.y + 28)
	var x0s := GD_REST.x - pv.x
	var fl := float(GD_REST.x - 34 - x0s)
	var fr := float(GD_REST.x + 34 - x0s)
	var bl := VPX + (GD_REST.x - 34 - VPX) * k - x0s
	var brr := VPX + (GD_REST.x + 34 - VPX) * k - x0s
	tape_h(g, int(fl) - 1, int(fl + fr) / 2 + 2, front)
	tape_h(g, int(fl + fr) / 2 - 3, int(fr) + 1, front + 1)
	tape_h(g, int(bl), int(bl) + 24, back)
	tape_h(g, int(bl) + 30, int(brr) + 1, back)
	tape_slant(g, bl, back + 1, fl, front)
	tape_slant(g, brr - 1, back + 1, fr - 1, front)
	for i in 5:
		L.P(g, 33 + i * 2, 7 + i, "cream"); L.P(g, 34 + i * 2, 7 + i, "g3")
		L.P(g, 41 - i * 2, 7 + i, "cream"); L.P(g, 42 - i * 2, 7 + i, "g3")
	save_sheet("tape_mark_grappling_dummy", "garage/tape_mark_grappling_dummy.png", [g], 0, pv, {
		"positions": {"canto": xy(GD_REST)}, "layer": "chao", "z": -30, "sort_y": 266,
		"note": "Contorno de fita crepe no chão onde o tatame do boneco vai ficar (canto da frente à esquerda). Mesmo pivô e ponto da grappling_dummy_lN_rest. Desenhar logo depois do fundo (é chão). Some na chegada."})
	# silhuetas apagadas com cadeado
	save_sheet("ghost_speed_bag", "garage/ghost_speed_bag.png", [ghost_of(speed_bag_wall(0, 0.0, 0.0), Vector2i(30, 24))], 0, SBW_PIVOT, {
		"positions": {"parede": xy(SB_WALL)}, "layer": "frente_do_fundo", "z": -40,
		"note": "Opcional: sombra pontilhada da plataforma com cadeado, por cima da tape_mark_speed_bag. Some junto com a marca."})
	save_sheet("ghost_grappling_dummy", "garage/ghost_grappling_dummy.png", [ghost_of(dummy_lying(0), Vector2i(40, 6))], 0, GDR_PIVOT, {
		"positions": {"canto": xy(GD_REST)}, "layer": "chao", "z": -29, "sort_y": 267,
		"note": "Opcional: sombra pontilhada do boneco deitado com cadeado, por cima da tape_mark_grappling_dummy. Some junto com a marca."})

# poeira pequena (o tatame é mais leve que a esteira)
func dust_blob(img: Image, cx: float, cy: float, r: float, fade: int, ph: int) -> void:
	if r < 1.0:
		return
	if fade == 0:
		L.ellipse(img, cx, cy, r, r * 0.7, "g2")
		L.ellipse_dither(img, cx, cy - r * 0.2, r * 0.8, r * 0.5, "g3", ph)
		L.ellipse(img, cx - r * 0.2, cy - r * 0.3, r * 0.4, r * 0.25, "g3")
	elif fade == 1:
		L.ellipse_dither(img, cx, cy, r, r * 0.7, "g2", ph)
		L.ellipse_dither(img, cx, cy - r * 0.2, r * 0.5, r * 0.35, "g3", ph + 1)
	else:
		L.ellipse_dither(img, cx, cy, r * 0.8, r * 0.5, "g2", ph)

func star(img: Image, x: int, y: int, s: int, c := "y2") -> void:
	L.P(img, x, y, "white")
	for i in range(1, s + 1):
		var cc: String = c if i < s else "y0"
		L.P(img, x + i, y, cc); L.P(img, x - i, y, cc); L.P(img, x, y + i, cc); L.P(img, x, y - i, cc)

func make_arrival_small() -> void:
	var W := 80
	var H := 28
	var cx := 40.0
	var by := 25.0
	var frames := []
	for f in 6:
		var img: Image = L.blank(W, H)
		var fade := 0 if f < 3 else (1 if f < 5 else 2)
		var inner: float = [0.0, 6.0, 12.0, 17.0, 21.0, 24.0][f]
		var outer: float = [8.0, 18.0, 25.0, 29.0, 31.0, 33.0][f]
		var rad: float = [4.0, 5.5, 5.5, 5.0, 4.0, 3.0][f]
		for side in [-1.0, 1.0]:
			var d := inner
			var kk := 0
			while d <= outer:
				var hgt: float = rad * (0.55 + 0.45 * float((kk * 7 + f * 3) % 5) / 4.0)
				dust_blob(img, cx + side * d, by - hgt * 0.6 - f * 0.4, hgt, fade, kk + f)
				d += 4.0
				kk += 1
		if f == 0:
			L.R(img, int(cx) - 22, int(by), 44, 1, "g3")
		if f >= 1 and f <= 4:
			var st := [[12, 8], [68, 6], [40, 1], [26, 3], [56, 2]]
			for i in st.size():
				if (i + f) % 2 == 0 or f == 2:
					star(img, st[i][0], st[i][1] + f, 2 if f < 4 else 1)
		frames.append(img)
	save_sheet("fx_arrive_dust_small", "garage/fx_arrive_dust_small.png", frames, 12.0, Vector2i(40, 25), {
		"loop": false, "impact_frame": 0, "positions": {"canto": xy(GD_REST)},
		"note": "Chegada do boneco: poeira baixa que abre para os lados + estrelinhas. 6 quadros a 12 fps, sem loop. Mesmo uso do fx_arrive_dust, em tamanho de tatame."})

# ================================================================ ícones e UI
func make_icons() -> void:
	# --- ícones dos aparelhos das artes (16x16, linha da aba TREINO)
	var isb: Image = L.blank(16, 16)
	L.ellipse(isb, 8, 3, 7, 1.6, "br3"); L.R(isb, 1, 3, 15, 2, "br1")
	L.R(isb, 7, 5, 2, 2, "st2")
	L.ellipse(isb, 8, 10.5, 3.6, 4.6, "r2"); L.R(isb, 7, 6, 2, 2, "r1"); L.ellipse(isb, 7, 11, 1.8, 3, "r1")
	L.P(isb, 10, 9, "r3"); L.P(isb, 10, 10, "white")
	isb = ol(isb)
	save_sheet("icon_speed_bag", "ui/icon_speed_bag.png", [isb], 0, Vector2i.ZERO, {"note": "Pera veloz 16x16 (linha da aba TREINO e cartão de técnica)."})
	var igd: Image = L.blank(16, 16)
	L.R(igd, 1, 12, 14, 3, "b2"); L.R(igd, 1, 12, 14, 1, "b3"); L.R(igd, 1, 14, 14, 1, "b1")
	capsule(igd, V(9, 11), V(10, 5), 2.6, ["g3", "g3", "cream"])
	L.ellipse(igd, 10, 3, 2.2, 2.2, "g3"); L.P(igd, 9, 2, "cream")
	capsule(igd, V(8, 11), V(4, 8), 1.6, ["g3", "g3", "cream"])
	capsule(igd, V(4, 8), V(2, 11), 1.3, ["g3", "g3", "cream"])
	capsule(igd, V(9, 6), V(5, 7), 1.0, ["g2", "g2", "g3"])
	igd = ol(igd)
	save_sheet("icon_grappling_dummy", "ui/icon_grappling_dummy.png", [igd], 0, Vector2i.ZERO, {"note": "Boneco de tatame 16x16 (linha da aba TREINO e cartão de técnica)."})
	for ap in [["speed_bag", "pera"], ["grappling_dummy", "boneco"]]:
		var base: Image = grayed(frame_of("icon_" + ap[0]))
		for v in [["", LOCK_GRAY, "cadeado cinza: trancado ou sem Treino"], ["_buyable", LOCK_GOLD, "cadeado dourado: dá para comprar agora"]]:
			var img: Image = base.duplicate()
			L.R(img, 8, 6, 8, 10, Color(0, 0, 0, 0))
			padlock(img, 9, 6, v[1])
			save_sheet("icon_%s_locked%s" % [ap[0], v[0]], "ui/icon_%s_locked%s.png" % [ap[0], v[0]], [img], 0, Vector2i.ZERO, {
				"note": "Silhueta da %s com %s (mesmo uso dos icon_*_locked da 4b: cartão de compra e botão de foco trancado)." % [ap[1], v[2]]})

	# --- ícones das artes
	var ab: Image = L.blank(16, 16)   # Boxe: luva vermelha com punho branco, de frente
	L.rrect(ab, 3, 1, 10, 10, "r2"); L.R(ab, 4, 2, 4, 2, "r3"); L.R(ab, 3, 8, 10, 3, "r1")
	L.rrect(ab, 10, 4, 5, 6, "r2"); L.R(ab, 13, 5, 1, 4, "r1")
	L.R(ab, 4, 11, 8, 4, "white"); L.R(ab, 4, 14, 8, 1, "g3"); L.R(ab, 7, 11, 1, 3, "g3")
	ab = ol(ab)
	var aj: Image = L.blank(16, 16)   # Jiu-jitsu: nó da faixa (azul) com pontas caídas
	L.R(aj, 0, 5, 16, 4, "b2"); L.R(aj, 0, 5, 16, 1, "b3"); L.R(aj, 0, 8, 16, 1, "b1")
	L.rrect(aj, 5, 3, 6, 7, "b2"); L.R(aj, 6, 4, 3, 1, "b3"); L.R(aj, 5, 8, 6, 1, "b1")
	capsule(aj, V(6, 10), V(3, 14), 1.4, ["b1", "b1", "b2"]); capsule(aj, V(10, 10), V(12, 14), 1.4, ["b1", "b1", "b2"])
	L.R(aj, 2, 14, 2, 1, "ink"); L.R(aj, 12, 14, 2, 1, "ink")
	aj = ol(aj)
	save_sheet("art_boxing", "ui/art_boxing.png", [ab], 0, Vector2i.ZERO, {"note": "Ícone da arte Boxe 16x16 (luva vermelha). Janela de arte, cartão de início, resumo."})
	save_sheet("art_bjj", "ui/art_bjj.png", [aj], 0, Vector2i.ZERO, {"note": "Ícone da arte Jiu-jitsu 16x16 (nó da faixa azul). Janela de arte, cartão de início, resumo."})
	var ab9: Image = L.blank(9, 9)
	L.rrect(ab9, 1, 0, 6, 6, "r2"); L.P(ab9, 2, 1, "r3"); L.R(ab9, 6, 2, 2, 3, "r2"); L.R(ab9, 1, 5, 6, 1, "r1"); L.R(ab9, 2, 6, 4, 2, "white")
	var aj9: Image = L.blank(9, 9)
	L.R(aj9, 0, 2, 9, 3, "b2"); L.R(aj9, 0, 2, 9, 1, "b3"); L.R(aj9, 3, 1, 3, 5, "b2"); L.P(aj9, 4, 2, "b3")
	L.P(aj9, 3, 6, "b1"); L.P(aj9, 2, 7, "b1"); L.P(aj9, 5, 6, "b1"); L.P(aj9, 6, 7, "b1")
	save_sheet("art_boxing_9", "ui/art_boxing_9.png", [outline_keep(ab9)], 0, Vector2i.ZERO, {"note": "Boxe 9x9: HUD da arte e botão de foco da pera (no lugar do icon_<atributo>)."})
	save_sheet("art_bjj_9", "ui/art_bjj_9.png", [outline_keep(aj9)], 0, Vector2i.ZERO, {"note": "Jiu-jitsu 9x9: HUD da arte e botão de foco do boneco."})

	# --- técnicas (16x16, mesmo tamanho do icon_bag das melhorias)
	var t1: Image = L.blank(16, 16)   # Jab duplo: duas luvas em fila com riscos
	for gx in [[1, ["r0", "r1", "r1"]], [6, ["r1", "r2", "r3"]]]:
		var x0: int = gx[0]
		var c: Array = gx[1]
		L.rrect(t1, x0 + 2, 5, 8, 7, c[1]); L.R(t1, x0 + 3, 6, 3, 1, c[2]); L.R(t1, x0 + 2, 10, 8, 2, c[0])
		L.rrect(t1, x0 + 8, 7, 3, 4, c[1])
		L.R(t1, x0, 6, 2, 5, "white")
	t1 = ol(t1)
	for i in 3:
		L.R(t1, 0, 2 + i * 5, 3, 1, "y1")
	L.text(t1, "2", 11, 0, "y1")
	var t2: Image = L.blank(16, 16)   # Esquiva e volta: cabeça em arco + seta curva + luva
	L.ellipse(t2, 5, 6, 3, 3, "sk1"); L.P(t2, 4, 5, "sk2"); L.R(t2, 3, 3, 5, 2, "d1")
	t2 = ol(t2)
	for i in 9:
		var a := PI * (0.15 + 0.85 * i / 8.0)
		L.P(t2, int(8 + cos(a) * 6), int(9 + sin(a) * 4), "b3")
	L.P(t2, 13, 9, "b3"); L.P(t2, 13, 10, "white"); L.P(t2, 12, 8, "b3")
	var gl: Image = L.blank(7, 6)
	L.rrect(gl, 0, 0, 7, 6, "r2"); L.R(gl, 1, 1, 3, 1, "r3"); L.R(gl, 0, 4, 7, 2, "r1")
	L.stamp(t2, gl, 9, 1)
	var t3: Image = L.blank(16, 16)   # Guarda fechada: duas pernas (calça de quimono) fechadas em anel, tornozelos cruzados
	L.ring(t3, 8, 7, 7, 6, 2.6, "cream")
	L.ring(t3, 8, 7, 7, 6, 1, "g3")
	L.R(t3, 5, 11, 6, 3, "cream")
	L.line(t3, 5, 11, 10, 14, "g2"); L.line(t3, 10, 11, 5, 14, "g2")
	L.R(t3, 6, 5, 4, 4, "b2"); L.P(t3, 7, 6, "b3")
	t3 = ol(t3)
	var t4: Image = L.blank(16, 16)   # Raspagem: seta circular sobre o tatame
	L.R(t4, 0, 12, 16, 3, "b1"); L.R(t4, 0, 12, 16, 1, "b2")
	for i in 14:
		var a := PI * (1.05 + 1.35 * i / 13.0)
		L.P(t4, int(8 + cos(a) * 6), int(8 + sin(a) * 5), "white")
		L.P(t4, int(8 + cos(a) * 5), int(8 + sin(a) * 4), "b3")
	L.R(t4, 13, 5, 1, 4, "white"); L.R(t4, 11, 8, 3, 1, "white")
	L.ellipse(t4, 7, 9, 2, 2, "cream")
	t4 = outline_keep(t4)
	var techs := [["tech_boxing_1", t1, "Jab duplo: duas luvas em fila com o '2'"], ["tech_boxing_2", t2, "Esquiva e volta: cabeça que sai em arco e a luva que fica"],
		["tech_bjj_1", t3, "Guarda fechada: pernas fechadas em anel, tornozelos cruzados"], ["tech_bjj_2", t4, "Raspagem: giro em cima do tatame"]]
	for t in techs:
		save_sheet("icon_" + t[0], "ui/icon_%s.png" % t[0], [t[1]], 0, Vector2i.ZERO, {"note": "Técnica %s (16x16, mesmo tamanho dos ícones de melhoria). Linha da técnica na aba TREINO." % t[2]})

	# --- mudança (caixa de papelão com fita) e local
	var mv: Image = L.blank(16, 16)
	L.R(mv, 1, 5, 14, 10, "br3"); L.R(mv, 1, 5, 14, 1, "y0"); L.R(mv, 1, 13, 14, 2, "br2")
	L.trap(mv, 2, 4, 3, 13, 1, 15, "br2")
	L.R(mv, 7, 2, 2, 13, "cream"); L.R(mv, 8, 2, 1, 13, "g3")
	L.R(mv, 3, 8, 3, 1, "br1"); L.R(mv, 3, 10, 2, 1, "br1")
	mv = ol(mv)
	save_sheet("icon_move", "ui/icon_move.png", [mv], 0, Vector2i.ZERO, {"note": "Mudança 16x16: caixa de papelão com fita (botão MUDAR e cartão da mudança)."})
	var mv9: Image = L.blank(9, 9)
	L.R(mv9, 0, 2, 9, 7, "br3"); L.R(mv9, 0, 2, 9, 1, "y0"); L.R(mv9, 0, 7, 9, 2, "br2"); L.R(mv9, 4, 1, 1, 8, "cream")
	save_sheet("icon_move_9", "ui/icon_move_9.png", [outline_keep(mv9)], 0, Vector2i.ZERO, {"note": "Mudança 9x9 (bloco PRÓXIMA e dicas)."})
	var lg: Image = L.blank(9, 9)
	L.R(lg, 1, 3, 7, 6, "cream"); L.R(lg, 0, 2, 9, 2, "gr2"); L.R(lg, 0, 2, 9, 1, "gr3"); L.R(lg, 3, 5, 3, 4, "br2"); L.P(lg, 2, 5, "b3"); L.P(lg, 6, 5, "b3")
	save_sheet("icon_location_gym", "ui/icon_location_gym.png", [outline_keep(lg)], 0, Vector2i.ZERO, {"note": "Academia 9x9 (fachada com toldo verde): HUD 'ACADEMIA: TREINO x2'."})
	var lga: Image = L.blank(9, 9)
	L.R(lga, 0, 2, 9, 7, "g1"); L.R(lga, 0, 2, 9, 1, "g2"); L.R(lga, 1, 4, 7, 5, "st2")
	for yy in range(4, 9, 2):
		L.R(lga, 1, yy, 7, 1, "st1")
	save_sheet("icon_location_garage", "ui/icon_location_garage.png", [outline_keep(lga)], 0, Vector2i.ZERO, {"note": "Garagem 9x9 (porta de enrolar), para o resumo/cartão de início."})

func outline_keep(src: Image) -> Image:
	var big: Image = L.blank(src.get_width() + 2, src.get_height() + 2)
	big.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(1, 1))
	var o: Image = L.outlined(big)
	return o.get_region(Rect2i(2, 2, src.get_width(), src.get_height()))

# --- botões no padrão do ui_button_* (16x17)
func button_tex(bg: String, pressed := false, flat := false, border = null) -> Image:
	var img: Image = L.blank(16, 17)
	var y0 := 1 if pressed else 0
	if not pressed and not flat:
		L.R(img, 1, 16, 15, 1, "ink")
	L.R(img, 0, y0, 16, 16, "ink")
	L.R(img, 1, y0 + 1, 14, 14, bg)
	if pressed:
		L.R(img, 1, y0 + 1, 14, 1, L.shade(L.col(bg), -1))
	elif not flat:
		L.R(img, 1, 1, 14, 1, L.shade(L.col(bg), 1))
		L.R(img, 1, 13, 14, 2, L.shade(L.col(bg), -1))
	if border != null:
		L.R(img, 1, y0 + 1, 14, 1, border); L.R(img, 1, y0 + 1, 1, 12, border); L.R(img, 14, y0 + 1, 1, 12, border)
	return img

func make_buttons() -> void:
	var mg := {"left": 2, "top": 2, "right": 2, "bottom": 4}
	var mgp := {"left": 2, "top": 3, "right": 2, "bottom": 3}
	save_sheet("ui_button_focus_art", "ui/ui_button_focus_art.png", [button_tex("p1")], 0, Vector2i.ZERO, {"nine_slice": mg, "text_color": "white",
		"note": "Botão de foco SELECIONADO do aparelho da arte (pera ou boneco): roxo = arte marcial (direcao-visual §2). Sublinhado de 2 px em p2. Ícone 9x9: art_boxing_9 / art_bjj_9. Não selecionado = ui_button_normal; trancado = ui_button_focus_locked_* da 4b."})
	var mv := {"normal": [button_tex("gr1"), "y2", mg, "Aceso (cinturão + dinheiro): verde = 'dá para comprar', como no resto do jogo. Conteúdo: icon_move + 'MUDAR' + preço em y1."],
		"hover": [button_tex("gr2"), "white", mg, "Mouse em cima."],
		"pressed": [button_tex("gr1", true), "y1", mgp, "Pressionado (afunda 1 px)."],
		"disabled": [button_tex("d1", false, true), "g1", mg, "Apagado (falta dinheiro): sem sombra, texto g1, preço em r2 (move_no_money). Nunca some: o jogador vê quanto falta."]}
	for st in mv:
		var d: Array = mv[st]
		save_sheet("ui_button_move_" + st, "ui/ui_button_move_%s.png" % st, [d[0]], 0, Vector2i.ZERO, {"nine_slice": d[2], "text_color": d[1],
			"note": "Botão MUDAR (9-slice). " + d[3]})
	var ab := {"normal": [button_tex("p1"), "white", mg, "ESCOLHER no cartão da arte."], "hover": [button_tex("p2"), "white", mg, "Mouse em cima."],
		"pressed": [button_tex("p1", true), "cream", mgp, "Pressionado."]}
	for st in ab:
		var d2: Array = ab[st]
		save_sheet("ui_button_art_" + st, "ui/ui_button_art_%s.png" % st, [d2[0]], 0, Vector2i.ZERO, {"nine_slice": d2[2], "text_color": d2[1],
			"note": "Botão roxo da janela de arte (9-slice). " + d2[3]})

func make_panels() -> void:
	# --- cartão da mudança (bloco PRÓXIMA): caixa de papelão com fita nos cantos (cantos fixos)
	for v in [["ui_move_card", "br2", "br3", "br1", "d2", "Cartão da mudança no bloco PRÓXIMA (no lugar do adversário, depois do cinturão): borda de papelão e pedaços de fita nos cantos de cima. Conteúdo: icon_move, move_title, move_effect, move_keeps, botão MUDAR."],
			["ui_move_card_ready", "br3", "y0", "br2", "d2", "Mesmo cartão quando dá para pagar: papelão claro (chama o olho junto com o botão verde)."],
			["ui_move_card_dim", "br1", "br2", "br0", "d1", "Cartão sem dinheiro: papelão escuro."]]:
		var c: Image = L.blank(20, 20)
		L.R(c, 0, 0, 20, 20, "ink")
		L.R(c, 1, 1, 18, 18, v[1])
		L.R(c, 1, 1, 18, 1, v[2]); L.R(c, 1, 18, 18, 1, v[3])
		L.R(c, 3, 3, 14, 14, "ink"); L.R(c, 4, 4, 12, 12, v[4])
		# fita nos cantos de cima (diagonal)
		for i in 4:
			L.P(c, i, 3 - i, "cream"); L.P(c, i + 1, 3 - i, "cream"); L.P(c, i + 1, 4 - i, "g3")
			L.P(c, 19 - i, 3 - i, "cream"); L.P(c, 18 - i, 3 - i, "cream"); L.P(c, 18 - i, 4 - i, "g3")
		save_sheet(v[0], "ui/%s.png" % v[0], [c], 0, Vector2i.ZERO, {"nine_slice": {"left": 5, "top": 5, "right": 5, "bottom": 5}, "note": v[5]})
	# --- janela de arte: cartões
	var cards := {"ui_art_card": ["d2", "p0", "p1", "Cartão de uma arte na janela 'QUE TIPO DE LUTADOR VOCÊ QUER SER?' (9-slice). Faixa de cima: ui_art_card_header_<arte>."],
		"ui_art_card_hover": ["d2", "p1", "p2", "Mouse em cima do cartão (borda acende)."],
		"ui_art_card_last": ["d2", "br2", "y1", "Arte da carreira anterior, já marcada (R6): borda dourada + selo ui_art_tag_last 'ÚLTIMA: {nome}'."]}
	for id in cards:
		var d: Array = cards[id]
		var c2: Image = L.blank(24, 24)
		L.rrect(c2, 0, 0, 24, 24, "ink")
		L.rrect(c2, 1, 1, 22, 22, d[1])
		L.R(c2, 2, 1, 20, 1, d[2]); L.R(c2, 1, 2, 1, 20, d[2])
		L.R(c2, 3, 3, 18, 18, "ink")
		L.R(c2, 4, 4, 16, 16, d[0])
		L.R(c2, 4, 4, 16, 1, "g0")
		if id == "ui_art_card_last":
			for cc in [Vector2i(1, 1), Vector2i(21, 1), Vector2i(1, 21), Vector2i(21, 21)]:
				L.R(c2, cc.x, cc.y, 2, 2, "y2")
		save_sheet(id, "ui/%s.png" % id, [c2], 0, Vector2i.ZERO, {"nine_slice": {"left": 5, "top": 5, "right": 5, "bottom": 5}, "note": d[3]})
	for h in [["boxing", "r1", "r2", "r0"], ["bjj", "b1", "b2", "b0"]]:
		var hd: Image = L.blank(16, 14)
		L.R(hd, 0, 0, 16, 14, "ink")
		L.R(hd, 1, 1, 14, 12, h[1]); L.R(hd, 1, 1, 14, 1, h[2]); L.R(hd, 1, 11, 14, 2, h[3])
		save_sheet("ui_art_card_header_" + h[0], "ui/ui_art_card_header_%s.png" % h[0], [hd], 0, Vector2i.ZERO, {"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 3},
			"text_color": "white", "note": "Faixa do nome da arte no alto do cartão (%s). Nome 2x branco com sombra ink, art_%s à esquerda." % ["Boxe = vermelho e madeira" if h[0] == "boxing" else "Jiu-jitsu = azul de tatame", h[0]]})
	var tag: Image = L.blank(12, 11)
	L.rrect(tag, 0, 0, 12, 11, "ink"); L.R(tag, 1, 1, 10, 9, "y0"); L.R(tag, 1, 1, 10, 1, "y1"); L.R(tag, 1, 9, 10, 1, "br2")
	save_sheet("ui_art_tag_last", "ui/ui_art_tag_last.png", [tag], 0, Vector2i.ZERO, {"nine_slice": {"left": 2, "top": 2, "right": 2, "bottom": 2}, "text_color": "br0",
		"note": "Selo 'ÚLTIMA: {nome}' (art_last) no canto de cima do cartão da arte anterior. Texto 1x em br0, sem sombra."})
	# moldura da ilustração do aparelho no cartão (vinheta 72x56)
	save_sheet("art_card_boxing", "ui/art_card_boxing.png", [art_vignette("boxing")], 0, Vector2i.ZERO, {"note": "Ilustração do aparelho assinatura no cartão do Boxe (72x56): a pera no pedestal com riscos de velocidade, fundo vermelho escuro."})
	save_sheet("art_card_bjj", "ui/art_card_bjj.png", [art_vignette("bjj")], 0, Vector2i.ZERO, {"note": "Ilustração do aparelho assinatura no cartão do Jiu-jitsu (72x56): o boneco sentado no tatame, fundo azul escuro."})
	# chip do HUD da arte (perto dos botões de foco)
	var chip: Image = L.blank(12, 13)
	L.R(chip, 0, 0, 12, 13, "ink"); L.R(chip, 1, 1, 10, 11, "p1"); L.R(chip, 2, 2, 8, 9, "p0"); L.R(chip, 2, 10, 8, 1, "ink")
	L.P(chip, 0, 0, Color(0, 0, 0, 0)); L.P(chip, 11, 0, Color(0, 0, 0, 0)); L.P(chip, 0, 12, Color(0, 0, 0, 0)); L.P(chip, 11, 12, Color(0, 0, 0, 0))
	save_sheet("ui_art_chip", "ui/ui_art_chip.png", [chip], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 3}, "text_color": "p2",
		"note": "HUD da arte (hud_art_boxing / hud_art_bjj / hud_art_bjj_max), 9-slice altura 13 igual ao chip do assistido: ícone art_<arte>_9 em (3,2), texto 1x p2 em (15,3). No teto do Jiu-jitsu ('(MÁX.)') o texto pode ir para y1."})
	# --- árvore: coluna/aba ESTILO
	var col: Image = L.blank(20, 32)
	L.R(col, 0, 0, 20, 32, "ink")
	L.R(col, 1, 1, 18, 30, "d1")
	L.R(col, 1, 1, 18, 13, "p0"); L.R(col, 1, 1, 18, 1, "p1"); L.R(col, 1, 13, 18, 1, "ink")
	L.R(col, 1, 14, 18, 1, "ink")
	L.R(col, 1, 15, 1, 15, "d2"); L.R(col, 18, 15, 1, 15, "ink")
	save_sheet("ui_tree_column_style", "ui/ui_tree_column_style.png", [col], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 16, "right": 3, "bottom": 3},
		"note": "Coluna/página do ramo ESTILO (9-slice, mesmo formato das colunas CORPO/CARREIRA): faixa roxa (arte marcial) com tree_branch_style + icon_branch_style."})
	var ibs: Image = L.blank(9, 9)
	L.R(ibs, 0, 3, 9, 2, "p2"); L.R(ibs, 3, 2, 3, 4, "p1"); L.P(ibs, 4, 3, "p2"); L.P(ibs, 3, 6, "p1"); L.P(ibs, 2, 7, "p1"); L.P(ibs, 5, 6, "p1"); L.P(ibs, 6, 7, "p1")
	save_sheet("icon_branch_style", "ui/icon_branch_style.png", [outline_keep(ibs)], 0, Vector2i.ZERO, {"note": "Ícone 9x9 do ramo ESTILO (nó de faixa roxo)."})
	for t in [["normal", "d1", "d2", "g2", "Aba não selecionada."], ["active", "p0", "p1", "white", "Aba selecionada (ESTILO roxo; para CORPO/CARREIRA usar a mesma peça — o roxo aqui é o do Legado/árvore)."]]:
		var tb: Image = L.blank(12, 13)
		L.R(tb, 0, 0, 12, 13, "ink"); L.R(tb, 1, 1, 10, 12, t[1]); L.R(tb, 1, 1, 10, 1, t[2])
		L.P(tb, 0, 0, Color(0, 0, 0, 0)); L.P(tb, 11, 0, Color(0, 0, 0, 0))
		save_sheet("ui_tree_tab_" + t[0], "ui/ui_tree_tab_%s.png" % t[0], [tb], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 1}, "text_color": t[3],
			"note": "Aba da árvore, se o UI/UX escolher abas em vez de 3 colunas (9-slice, sem borda embaixo: encosta na coluna). " + t[4]})

func art_vignette(art: String) -> Image:
	var v: Image = L.blank(72, 56)
	var bgc: Array = ["r0", "r1"] if art == "boxing" else ["b0", "b1"]
	L.R(v, 0, 0, 72, 56, "ink")
	L.R(v, 1, 1, 70, 54, bgc[0])
	for y in range(1, 55):
		for x in range(1, 71):
			var d := Vector2(x - 36, (y - 20) * 1.2).length()
			if d < 26 and (L.BAYER[y % 4][x % 4] + 0.5) / 16.0 < (1.0 - d / 26.0) * 1.2:
				v.set_pixel(x, y, L.C[bgc[1]])
	L.R(v, 1, 46, 70, 9, "d1"); L.R(v, 1, 46, 70, 1, "d2")
	if art == "boxing":
		var s := speed_bag_stand(1, 30.0, 2.0, true)
		v.blend_rect(s.get_region(Rect2i(0, 0, 44, 60)), Rect2i(0, 0, 44, 52), Vector2i(26, 2))
		var gl: Image = frame_of("glove_l2")
		L.blit(v, gl, 14, 18)
		for i in 3:
			L.R(v, 4, 20 + i * 4, 8, 1, "y1")
	else:
		var d2 := dummy_sit(0, 0, 0)
		v.blend_rect(d2.get_region(Rect2i(0, 6, 66, 52)), Rect2i(0, 0, 66, 50), Vector2i(3, 4))
	return v

# --- nós da aba ESTILO (mesma peça 24x24 da Fase 4, ramo roxo)
const BRANCH_STYLE := ["p0", "p1", "p2"]

func node_tile(icon: Image, state: String, frame := 0) -> Image:
	var t: Image = L.blank(24, 24)
	var br: Array = BRANCH_STYLE
	match state:
		"owned":
			L.rrect(t, 0, 0, 24, 24, "ink")
			L.rrect(t, 1, 1, 22, 22, br[1])
			L.R(t, 2, 1, 20, 1, br[2]); L.R(t, 1, 2, 1, 20, br[2])
			L.R(t, 2, 22, 20, 1, br[0]); L.R(t, 22, 2, 1, 20, br[0])
			L.R(t, 3, 3, 18, 18, "ink")
			L.R(t, 4, 4, 16, 16, "d2")
			L.R(t, 4, 4, 16, 1, "g0")
			t.blend_rect(icon, Rect2i(0, 0, 16, 16), Vector2i(4, 4))
			L.R(t, 15, 15, 9, 9, "ink"); L.R(t, 16, 16, 7, 7, "gr1"); L.R(t, 16, 16, 7, 1, "gr2")
			pmap(t, 17, 17, [".....", "....#", "...#.", "#.#..", ".#..."], {"#": "gr3"})
		"buyable":
			var edge: String = "gr3" if frame == 0 else "white"
			var edge2: String = "gr2" if frame == 0 else "gr3"
			L.rrect(t, 0, 0, 24, 24, "ink")
			L.rrect(t, 1, 1, 22, 22, edge)
			L.R(t, 2, 22, 20, 1, edge2); L.R(t, 22, 2, 1, 20, edge2)
			L.R(t, 2, 2, 20, 20, "ink")
			L.R(t, 3, 3, 18, 18, "gr1" if frame == 1 else "d2")
			L.R(t, 4, 4, 16, 16, "d1")
			L.dither(t, 4, 4, 16, 16, "gr0", frame)
			t.blend_rect(icon, Rect2i(0, 0, 16, 16), Vector2i(4, 4))
			for c in [Vector2i(0, 0), Vector2i(21, 0), Vector2i(0, 21), Vector2i(21, 21)]:
				L.R(t, c.x + 1, c.y + 1, 2, 2, "white" if frame == 1 else "y2")
		"missing":
			L.rrect(t, 0, 0, 24, 24, "ink")
			L.rrect(t, 1, 1, 22, 22, "g0")
			L.R(t, 2, 1, 20, 1, "g1")
			L.R(t, 2, 2, 20, 20, "ink")
			L.R(t, 3, 3, 18, 18, "d1")
			t.blend_rect(icon, Rect2i(0, 0, 16, 16), Vector2i(4, 4))
			for y in range(4, 20):
				for x in range(4, 20):
					if (x + y) % 2 == 0 and t.get_pixel(x, y).a > 0.0:
						t.set_pixel(x, y, L.shade(t.get_pixel(x, y), -1))
			L.R(t, 16, 16, 7, 7, "ink"); L.R(t, 17, 17, 5, 5, "p0"); L.R(t, 19, 18, 1, 3, "r2")
		"locked":
			L.rrect(t, 0, 0, 24, 24, "ink")
			L.rrect(t, 1, 1, 22, 22, "d2")
			L.R(t, 2, 2, 20, 20, "ink")
			L.R(t, 3, 3, 18, 18, "d1")
			t.blend_rect(grayed(icon), Rect2i(0, 0, 16, 16), Vector2i(4, 4))
			var lk: Image = L.blank(9, 10)
			pmap(lk, 0, 0, ["..kkkkk..", ".kgg.ggk.", ".kg...gk.", "kkkkkkkkk", "kGGGGGGGk", "kGGGkGGGk", "kGGGkGGGk", "kgggggggk", "kkkkkkkkk"],
				{"k": "ink", "g": "g1", "G": "g2"})
			t.blend_rect(lk, Rect2i(0, 0, 9, 9), Vector2i(15, 15))
	return t

func icon_style_boxing() -> Image:
	# Mão de sino: luva + sininho dourado com ondas
	var img: Image = L.blank(16, 16)
	L.rrect(img, 1, 5, 8, 8, "r2"); L.R(img, 2, 6, 3, 1, "r3"); L.R(img, 1, 11, 8, 2, "r1"); L.rrect(img, 7, 7, 3, 4, "r2")
	L.R(img, 1, 13, 7, 2, "white")
	img = ol(img)
	var bell: Image = L.blank(7, 8)
	L.R(bell, 3, 0, 1, 1, "br2"); L.trap(bell, 1, 5, 2, 4, 0, 6, "y0"); L.R(bell, 2, 2, 1, 3, "y1"); L.R(bell, 0, 5, 7, 1, "br2"); L.P(bell, 3, 6, "br1")
	L.stamp(img, bell, 9, 1)
	L.P(img, 15, 2, "y2"); L.P(img, 15, 5, "y2"); L.P(img, 14, 0, "y1")
	return img

func icon_style_bjj() -> Image:
	# Peso do tempo: ampulheta sobre a faixa azul
	var img: Image = L.blank(16, 16)
	L.R(img, 0, 10, 16, 3, "b2"); L.R(img, 0, 10, 16, 1, "b3"); L.R(img, 0, 12, 16, 1, "b1")
	img = outline_keep(img)
	var hg: Image = L.blank(9, 13)
	L.R(hg, 0, 0, 9, 2, "br2"); L.R(hg, 0, 11, 9, 2, "br2"); L.R(hg, 0, 0, 9, 1, "br3")
	L.trap(hg, 2, 5, 1, 7, 3, 5, "b3"); L.trap(hg, 6, 10, 3, 5, 1, 7, "b3")
	L.trap(hg, 3, 5, 2, 6, 3, 5, "y1"); L.trap(hg, 8, 10, 3, 5, 2, 6, "y0"); L.P(hg, 4, 6, "y1"); L.P(hg, 4, 7, "y1")
	L.stamp(img, hg, 4, 1)
	return img

func make_style_nodes() -> void:
	var nodes := [["style_boxing", icon_style_boxing(), "Mão de sino (luva + sininho)"], ["style_bjj", icon_style_bjj(), "Peso do tempo (ampulheta sobre a faixa)"]]
	var notes := {"owned": "COMPRADO: moldura roxa (ramo ESTILO) e ✓ verde.", "buyable": "COMPRÁVEL: borda verde pulsando (2 quadros).",
		"missing": "FALTA LEGADO: meio apagado, moeda roxa riscada.", "locked": "TRANCADO (arte ainda não desbloqueada): cinza e cadeado."}
	for n in nodes:
		var sid: String = "skill_" + n[0]
		save_sheet(sid, "ui/%s.png" % sid, [n[1]], 0, Vector2i.ZERO, {"note": "Ícone 16x16 do nó %s (ramo ESTILO)." % n[2]})
		save_sheet(sid + "_gray", "ui/%s_gray.png" % sid, [grayed(n[1])], 0, Vector2i.ZERO, {"note": "Ícone 16x16 do nó %s trancado." % n[2]}, false)
		for st in ["owned", "buyable", "missing", "locked"]:
			var frames := [node_tile(n[1], st, 0)]
			var fps := 0.0
			if st == "buyable":
				frames.append(node_tile(n[1], st, 1))
				fps = 3.0
			var info := {"note": "Peça 24x24 do nó %s. %s" % [n[2], notes[st]]}
			if st == "buyable":
				info["loop"] = true
			save_sheet(sid + "_" + st, "ui/%s_%s.png" % [sid, st], frames, fps, Vector2i.ZERO, info)

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

func write_manifest() -> void:
	# relê o manifest na hora de gravar (o Artista de Personagens pode ter gravado entradas novas enquanto isto rodava)
	var j := JSON.new()
	var doc: Dictionary = {}
	if j.parse(FileAccess.get_file_as_string(OUT + "manifest.json")) == OK:
		doc = intify(j.data)
	else:
		doc = intify(OLD)
	var sobre: String = str(doc.get("_sobre", ""))
	if sobre.find("Fase 5") < 0:
		doc["_sobre"] = sobre + " Fase 5 (Academia Boa Esquina, Boxe e Jiu-jitsu): tools/art/make_sprites_fase5.gd."
	var spr_d: Dictionary = doc.get("sprites", {})
	for k in M:
		spr_d[k] = intify(M[k])
	doc["sprites"] = spr_d
	var lay: Dictionary = doc.get("layout", {})
	lay["foco_pera"] = {"saco": "bag_lN_side em lado_esquerdo", "corda": "rope_lN_idle no prego", "esteira": "treadmill_lN_side em lado_direito",
		"pera": "speed_bag_lN_idle/hit em centro", "lutador": "fighter_idle/punch em foco_saco (303,272)", "boneco": "—"}
	lay["foco_boneco"] = {"saco": "bag_lN_side em lado_esquerdo", "corda": "rope_lN_idle no prego", "esteira": "treadmill_lN_side em lado_direito",
		"boneco": "grappling_dummy_lN_idle/hit em centro", "lutador": "fighter_idle/punch em foco_saco (303,272)", "pera": "—"}
	lay["_nota_fase5"] = "Fase 5: com foco em saco/corda/esteira, a pera fica na parede (speed_bag_lN_wall em 'parede') e o boneco deitado no canto (grappling_dummy_lN_rest em 'canto'). Só existe o aparelho da arte da carreira. Na academia, somar o sufixo _gym ao nome do sprite (bag_l1_idle -> bag_l1_idle_gym); se não existir no manifest, usar o da garagem."
	doc["layout"] = lay
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["_nota_fase5"] = "Fase 5: locations.json (garage, gym), arts.json (boxing, bjj), aparelhos speed_bag e grappling_dummy em training.json, técnicas tech_*, nós style_* em skill_tree.json, move_gym. Ids conferidos em data/ (2026-11-06)."
	bd["garage"] = {"bg": "garage_bg", "light": "lamp", "icon": "icon_location_garage", "suffix": ""}
	bd["gym"] = {
		"bg": "gym_bg", "light": "gym_tube", "light_positions": {"tubo_esq": xy(TUBES[0]), "tubo_dir": xy(TUBES[1])},
		"icon": "icon_location_gym", "suffix": "_gym",
		"sprite_rule": "nome do sprite + suffix (bag_l0_idle -> bag_l0_idle_gym). Sem _gym no manifest = usa o da garagem (pessoas, corrente, fx, marcas de fita, plaquinhas, lutador).",
		"no_lamp": "Na academia não existe a lâmpada (lamp): os tubos já estão no gym_bg. O balanço da lâmpada no crítico vira gym_tube flicker no tubo da direita (opcional).",
		"fighter": {"foco_saco": xy(P_FIGHTER_BAG), "foco_corda": xy(P_FIGHTER_ROPE), "foco_esteira": xy(P_FIGHTER_TM), "foco_pera": xy(P_FIGHTER_BAG), "foco_boneco": xy(P_FIGHTER_BAG),
			"note": "O lutador fica nos MESMOS pontos da garagem. Com a pera ou o boneco em foco, usa o fighter_idle/punch no ponto do saco (303,272)."},
		"metronome": {"pos": xy(P_METRO), "note": "Mesmo ponto da garagem (240,118): a prateleira da academia foi desenhada para ele (na ponta da direita, depois das garrafas)."},
		"people_pos": {"neighbor_1": xy(P_NEIGHBOR[0]), "neighbor_2": xy(P_NEIGHBOR[1]), "neighbor_3": xy(P_NEIGHBOR[2]),
			"uncle_1": xy(P_UNCLE[0]), "uncle_2": xy(P_UNCLE[1]), "coach_1": xy(P_COACH),
			"note": "Os mesmos pontos da garagem: a academia foi montada em volta deles (banco atrás do neighbor_2, porta atrás dos tios, tatame livre para o boneco). As pessoas têm a luz da lâmpada pintada: na academia ficam um pouco mais quentes que a sala (placeholder aceitável)."},
		"chain": "bag_chain_tile (mesmo da garagem): os ganchos da viga de aço estão em x 336 e 258.",
		"move_arrive": "Ao mudar: trocar o fundo com um corte seco + fx_arrive_dust no saco (o saco 'chega' como a esteira da 4b, offsets -20,-10,-3,0,1,0) — opcional; o mínimo é trocar garage_bg por gym_bg e os sprites pelo sufixo."}
	for ap in [["punching_bag", "bag"], ["treadmill", "treadmill"], ["jump_rope", "rope"]]:
		var base: Dictionary = bd.get(ap[0], {})
		var g := {}
		for kk in base:
			var vv = base[kk]
			if vv is String and str(vv).find("_lN_") >= 0:
				g[kk] = str(vv) + "_gym"
			else:
				g[kk] = vv
		bd[ap[0] + "_gym"] = g
	bd["speed_bag"] = {"art": "boxing", "idle": "speed_bag_lN_idle", "click": "speed_bag_lN_hit", "side": "speed_bag_lN_wall", "side_pos": "parede",
		"fighter": "fighter_punch", "fighter_pos": xy(P_FIGHTER_BAG), "fx": "fx_impact", "fx_pos": [325, 218], "icon": "icon_speed_bag", "focus_icon": "art_boxing_9",
		"focus_button": "ui_button_focus_art", "foco": "foco_pera", "split_note": "Treina os 3 atributos (split do training.json): o botão de foco usa art_boxing_9 e a linha focus_split.",
		"gym_suffix_note": "Na academia: side = speed_bag_lN_wall_gym. idle/hit são os mesmos (sem luz pintada)."}
	bd["grappling_dummy"] = {"art": "bjj", "idle": "grappling_dummy_lN_idle", "click": "grappling_dummy_lN_hit", "side": "grappling_dummy_lN_rest", "side_pos": "canto",
		"fighter": "fighter_punch", "fighter_pos": xy(P_FIGHTER_BAG), "fx": "fx_impact", "fx_pos": [330, 232], "icon": "icon_grappling_dummy", "focus_icon": "art_bjj_9",
		"focus_button": "ui_button_focus_art", "foco": "foco_boneco",
		"placeholder_note": "Sem animação nova de personagem nesta fase: o lutador usa o fighter_punch (soco no boneco sentado). Uma pose de grappling por cima do boneco é trabalho do Artista de Personagens numa fase futura.",
		"gym_suffix_note": "Na academia: side = grappling_dummy_lN_rest_gym."}
	bd["unlock_speed_bag"] = {
		"apparatus": "speed_bag", "requires": "treadmill",
		"floor_mark": "tape_mark_speed_bag", "ghost": "ghost_speed_bag", "mark_pos": xy(SB_WALL),
		"sign": {"frame": "sign_cardboard", "mode": "parede", "top_center": xy(SIGN_SB_TOPCENTER), "tape": "sign_tape_bit",
			"note": "Plaquinha colada na parede (na garagem fica na porta de enrolar) logo abaixo da marca, centrada em x 432 a partir de y 102, com 2 sign_tape_bit nos cantos de cima. 2 linhas (PERA / 2.5K TREINO) ou 3 (PERA / DEPOIS DA / ESTEIRA)."},
		"icon_locked": "icon_speed_bag_locked", "icon_locked_buyable": "icon_speed_bag_locked_buyable",
		"focus_button": {"buyable": "ui_button_focus_locked_buyable", "buyable_pulse": "ui_button_focus_locked_buyable_pulse", "missing": "ui_button_focus_locked_missing", "locked": "ui_button_focus_locked_locked"},
		"card": "ui_card_unlock", "card_flash": "ui_card_unlock_flash",
		"arrive": {"sprite": "speed_bag_l0_wall", "drop": {"offsets_y": [-8, -3, 0, 1, 0], "fps": 24, "shake_px": 0},
			"fx": "fx_arrive_sparkle", "fx_pos": [436, 52], "after": "speed_bag_l0_wall_swing (6 quadros, 12 fps) e depois speed_bag_l0_wall",
			"note": "A plataforma é presa na parede: desenhar speed_bag_l0_wall deslocada em y pelos offsets (24 fps). No 0: some a marca, toca o fx_arrive_sparkle e começa o balanço da pera. Na academia, sufixo _gym nos sprites da parede."},
		"text_keys": {"sign_price": "floor_mark_price", "sign_after": "floor_mark_after", "focus_price": "focus_locked_price", "focus_after": "focus_locked_after", "arrived": "unlock_arrived"}}
	bd["unlock_grappling_dummy"] = {
		"apparatus": "grappling_dummy", "requires": "treadmill",
		"floor_mark": "tape_mark_grappling_dummy", "ghost": "ghost_grappling_dummy", "mark_pos": xy(GD_REST),
		"sign": {"frame": "sign_cardboard", "mode": "chao", "bottom_center": xy(SIGN_GD_BOTTOM), "brick": "sign_brick", "brick_pos": [SIGN_GD_BOTTOM.x, SIGN_GD_BOTTOM.y + 3],
			"note": "Plaquinha em pé no fundo da marca, apoiada no tijolo (igual à da esteira)."},
		"icon_locked": "icon_grappling_dummy_locked", "icon_locked_buyable": "icon_grappling_dummy_locked_buyable",
		"focus_button": {"buyable": "ui_button_focus_locked_buyable", "buyable_pulse": "ui_button_focus_locked_buyable_pulse", "missing": "ui_button_focus_locked_missing", "locked": "ui_button_focus_locked_locked"},
		"card": "ui_card_unlock", "card_flash": "ui_card_unlock_flash",
		"arrive": {"sprite": "grappling_dummy_l0_rest", "drop": {"offsets_y": [-18, -8, -2, 0, 1, 0], "fps": 24, "shake_px": 1, "shake_frames": 2},
			"fx": "fx_arrive_dust_small", "fx_pos": xy(GD_REST),
			"note": "O tatame com o boneco cai no canto: desenhar grappling_dummy_l0_rest deslocado pelos offsets. No 0: some a marca, fx_arrive_dust_small e tremida de 1 px. Na academia, sufixo _gym."},
		"text_keys": {"sign_price": "floor_mark_price", "sign_after": "floor_mark_after", "focus_price": "focus_locked_price", "focus_after": "focus_locked_after", "arrived": "unlock_arrived"}}
	bd["tech_boxing_1"] = {"icon": "icon_tech_boxing_1", "apparatus": "speed_bag", "visual_level": 1}
	bd["tech_boxing_2"] = {"icon": "icon_tech_boxing_2", "apparatus": "speed_bag"}
	bd["tech_bjj_1"] = {"icon": "icon_tech_bjj_1", "apparatus": "grappling_dummy", "visual_level": 1}
	bd["tech_bjj_2"] = {"icon": "icon_tech_bjj_2", "apparatus": "grappling_dummy"}
	bd["boxing"] = {"icon": "art_boxing", "icon_9": "art_boxing_9", "card_art": "art_card_boxing", "card_header": "ui_art_card_header_boxing", "apparatus": "speed_bag", "color": "r1"}
	bd["bjj"] = {"icon": "art_bjj", "icon_9": "art_bjj_9", "card_art": "art_card_bjj", "card_header": "ui_art_card_header_bjj", "apparatus": "grappling_dummy", "color": "b1"}
	bd["art_window"] = {
		"card": {"normal": "ui_art_card", "hover": "ui_art_card_hover", "last": "ui_art_card_last"}, "tag_last": "ui_art_tag_last",
		"button": {"normal": "ui_button_art_normal", "hover": "ui_button_art_hover", "pressed": "ui_button_art_pressed"},
		"window": "ui_window", "title": "ui_window_title_retire",
		"layout_sugerido": {"window": [110, 34, 420, 268], "cards": [[124, 70, 190, 220], [326, 70, 190, 220]],
			"inside_card": {"header": [6, 6, 178, 18], "art": [59, 28, 72, 56], "tagline": [8, 90, 174, 18], "rule": [8, 116], "fight": [8, 130], "whole_career": [8, 150], "button": [35, 190, 120, 20]},
			"note": "Janela no meio da tela sobre a sala escurecida (ui_dim_dither). Título art_title, subtítulo art_sub_first / art_sub_career. Sem X. tagline em 2 linhas (174 px). Quem decide é o UI/UX (alinhamento-ui)."}}
	bd["style"] = {"column": "ui_tree_column_style", "icon": "icon_branch_style", "tabs": {"normal": "ui_tree_tab_normal", "active": "ui_tree_tab_active"}}
	for sid in ["style_boxing", "style_bjj"]:
		bd[sid] = {"icon": "skill_" + sid, "icon_gray": "skill_%s_gray" % sid,
			"tile": {"owned": "skill_%s_owned" % sid, "buyable": "skill_%s_buyable" % sid, "missing": "skill_%s_missing" % sid, "locked": "skill_%s_locked" % sid}}
	bd["move_gym"] = {"icon": "icon_move", "icon_9": "icon_move_9",
		"button": {"normal": "ui_button_move_normal", "hover": "ui_button_move_hover", "pressed": "ui_button_move_pressed", "disabled": "ui_button_move_disabled"},
		"card": {"normal": "ui_move_card", "ready": "ui_move_card_ready", "dim": "ui_move_card_dim"},
		"layout_sugerido": {"card": [4, 138, 120, 148], "icon": [9, 143], "title": [29, 145], "effect": [9, 166], "keeps": [9, 190], "per_career": [9, 214], "button": [10, 252, 108, 26],
			"note": "No bloco PRÓXIMA (painel esquerdo), no lugar do adversário, depois do cinturão. Textos de ui_texts (move_*), quebrados em até 2 linhas de 110 px. Botão: icon_move + MUDAR + preço."}}
	bd["art_hud"] = {"chip": "ui_art_chip", "icons": {"boxing": "art_boxing_9", "bjj": "art_bjj_9"}, "text_keys": ["hud_art_boxing", "hud_art_bjj", "hud_art_bjj_max"],
		"layout_sugerido": {"chip_right": [506, 291], "height": 13, "note": "Na linha do 'FOCO DE TREINO' da barra de baixo, alinhado à direita da área dos botões de foco (x 506). Some sem arte."}}
	bd["focus_4_layout"] = {"note": "Com o 4º foco, os 4 botões cabem em 372 px (x 134..506): largura 90, passo 94 (134, 228, 322, 416). Texto do botão: linha 1 focus_label[0], linha 2 focus_label[1]; 'JIU-JITSU' tem 53 px e cabe. Quem fecha é o UI/UX (alinhamento-ui)."}
	doc["by_data_id"] = bd
	var fa := FileAccess.open(OUT + "manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()

# ================================================================ helpers de mockup
func nine(dst: Image, src: Image, x: int, y: int, w: int, h: int, m: Dictionary) -> void:
	var sw := src.get_width()
	var sh := src.get_height()
	var l: int = m.left
	var r: int = m.right
	var t: int = m.top
	var bo: int = m.bottom
	for yy in h:
		var sy := yy
		if yy >= h - bo:
			sy = sh - (h - yy)
		elif yy >= t:
			sy = t + (yy - t) % maxi(sh - t - bo, 1)
		for xx in w:
			var sx := xx
			if xx >= w - r:
				sx = sw - (w - xx)
			elif xx >= l:
				sx = l + (xx - l) % maxi(sw - l - r, 1)
			var c := src.get_pixel(clampi(sx, 0, sw - 1), clampi(sy, 0, sh - 1))
			if c.a > 0.0 and x + xx >= 0 and y + yy >= 0 and x + xx < dst.get_width() and y + yy < dst.get_height():
				dst.set_pixel(x + xx, y + yy, c)

func spr(id: String) -> Dictionary:
	if M.has(id):
		return M[id]
	return OLD.get("sprites", {}).get(id, {})

func frame_of(id: String, i := 0) -> Image:
	if F.has(id):
		return F[id][i]
	var e := spr(id)
	var img := Image.load_from_file(ROOT + str(e.file).replace("res://", ""))
	img.convert(Image.FORMAT_RGBA8)
	var fw: int = int(e.frame_size[0])
	var fh: int = int(e.frame_size[1])
	return img.get_region(Rect2i(i * fw, 0, fw, fh))

func put(dst: Image, id: String, i: int, pos: Vector2i) -> void:
	var fr: Image = frame_of(id, i)
	var pv: Array = spr(id).get("pivot", [0, 0])
	dst.blend_rect(fr, Rect2i(Vector2i.ZERO, fr.get_size()), pos - Vector2i(int(pv[0]), int(pv[1])))

func ns(dst: Image, id: String, x: int, y: int, w: int, h: int) -> void:
	nine(dst, frame_of(id), x, y, w, h, spr(id).nine_slice)

func save_x(img: Image, path: String, k: int) -> void:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	b.save_png(path)

func sign_box(lines: Array) -> Vector2i:
	var w := 0
	for ln in lines:
		w = maxi(w, L.text_w(str(ln)))
	return Vector2i(w + 10, lines.size() * 7 + (lines.size() - 1) * 2 + 9)

func draw_sign(dst: Image, x: int, y: int, lines: Array) -> Vector2i:
	var sz := sign_box(lines)
	ns(dst, "sign_cardboard", x, y, sz.x, sz.y)
	var ty := y + 4
	for ln in lines:
		L.text_center(dst, str(ln), x + sz.x / 2, ty, "br0")
		ty += 9
	return sz

func dim(img: Image, r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if (x + y) % 2 == 0:
				img.set_pixel(x, y, L.C.ink)

## Monta a sala. room = "garage"/"gym"; focus = "bag"/"speed_bag"/"dummy"; art = ""/"boxing"/"bjj";
## art_state = "owned"/"mark"; crew = nº de pessoas (0..6).
func room(roomid: String, focus: String, art: String, art_state: String, crew: int, metro := 0, lv := 1, sign_lines := []) -> Image:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	var suf := "_gym" if roomid == "gym" else ""
	img.blit_rect(frame_of(roomid + "_bg"), Rect2i(0, 0, 384, 272), P_ROOM)
	var items := []   # [sort_y, id, frame, pos]
	if art == "bjj":
		if art_state == "mark":
			put(img, "tape_mark_grappling_dummy", 0, GD_REST)
			put(img, "ghost_grappling_dummy", 0, GD_REST)
		elif focus != "dummy":
			items.append([270, "grappling_dummy_l%d_rest%s" % [lv, suf], 0, GD_REST])
	if art == "boxing":
		if art_state == "mark":
			put(img, "tape_mark_speed_bag", 0, SB_WALL)
			put(img, "ghost_speed_bag", 0, SB_WALL)
		elif focus != "speed_bag":
			put(img, "speed_bag_l%d_wall%s" % [lv, suf], 0, SB_WALL)
	if metro > 0:
		put(img, "metronome_l%d" % metro, 0, P_METRO)
	put(img, "rope_l%d_idle%s" % [lv, suf], 0, NAIL)
	if roomid == "garage":
		put(img, "lamp", 0, P_LAMP)
	var bag_pos := P_BAG_CENTER if focus == "bag" else P_BAG_LEFT
	for yy in range(33, bag_pos.y, 4):
		put(img, "bag_chain_tile", 0, Vector2i(bag_pos.x - 1, yy))
	if art == "boxing" and art_state == "mark":
		var sz := sign_box(sign_lines)
		var sx := SIGN_SB_TOPCENTER.x - sz.x / 2
		draw_sign(img, sx, SIGN_SB_TOPCENTER.y, sign_lines)
		put(img, "sign_tape_bit", 0, Vector2i(sx + 2, SIGN_SB_TOPCENTER.y + 1))
		put(img, "sign_tape_bit", 0, Vector2i(sx + sz.x - 3, SIGN_SB_TOPCENTER.y + 1))
	items.append([bag_pos.y + 70, ("bag_l%d_idle%s" if focus == "bag" else "bag_l%d_side%s") % [lv, suf], 0, bag_pos])
	items.append([P_TM_RIGHT.y, "treadmill_l%d_side%s" % [lv, suf], 0, P_TM_RIGHT])
	if focus == "speed_bag":
		items.append([268, "speed_bag_l%d_idle" % lv, 0, SB_CENTER])
	if focus == "dummy":
		items.append([266, "grappling_dummy_l%d_idle" % lv, 0, GD_CENTER])
	var people := [["neighbor_1", P_NEIGHBOR[0]], ["coach_1", P_COACH], ["uncle_2", P_UNCLE[1]], ["neighbor_2", P_NEIGHBOR[1]], ["uncle_1", P_UNCLE[0]], ["neighbor_3", P_NEIGHBOR[2]]]
	for i in mini(crew, people.size()):
		items.append([people[i][1].y - 1, "floor_shadow", 0, people[i][1] + Vector2i(0, -1)])
		items.append([people[i][1].y, people[i][0], 1, people[i][1]])
	items.append([P_FIGHTER_BAG.y - 1, "floor_shadow", 0, Vector2i(303, 271)])
	items.append([P_FIGHTER_BAG.y, "fighter_punch", 1, P_FIGHTER_BAG])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		put(img, it[1], it[2], it[3])
	if art == "bjj" and art_state == "mark":
		var sz2 := sign_box(sign_lines)
		draw_sign(img, SIGN_GD_BOTTOM.x - sz2.x / 2, SIGN_GD_BOTTOM.y - sz2.y, sign_lines)
		put(img, "sign_brick", 0, Vector2i(SIGN_GD_BOTTOM.x, SIGN_GD_BOTTOM.y + 3))
	return img

func focus_btn(img: Image, x: int, y: int, w: int, st: String, l1: String, l2: String, icon: String, num := "", sel_col := "r2") -> void:
	if st.begins_with("owned"):
		var id := "ui_button_normal"
		if st == "owned_sel":
			id = {"r2": "ui_button_focus_strength", "p2": "ui_button_focus_art", "b2": "ui_button_focus_agility", "y0": "ui_button_focus_endurance"}[sel_col]
		ns(img, id, x, y, w, FOCUS_H)
		put(img, icon, 0, Vector2i(x + 6, y + 11))
		L.text(img, l1, x + 18, y + 4, "white", 1, "ink")
		L.text(img, l2, x + 18, y + 15, "g3", 1, "ink")
		if num != "":
			L.text_right(img, num, x + w - 5, y + 4, "g1", 1, "ink")
		if st == "owned_sel":
			L.R(img, x + 3, y + 36, w - 6, 2, sel_col)
		return
	var key := "ui_button_focus_locked_" + st
	ns(img, key, x, y, w, FOCUS_H)
	put(img, icon, 0, Vector2i(x + 2, y + 9))
	var e := spr(key)
	L.text(img, l1, x + 20, y + 4, e.text_color, 1, "ink")
	if st == "locked":
		L.text(img, l2, x + 20, y + 15, "g1", 1, "ink")
	else:
		put(img, "icon_treino", 0, Vector2i(x + 20, y + 14))
		L.text(img, l2, x + 31, y + 15, e.price_color, 1, "ink")

func bottom_bar4(img: Image, art: String, art_st: String, sel: int) -> void:
	L.panel(img, 0, 290, 640, 70)
	L.text(img, "POR CLIQUE", 8, 298, "g2", 1, "ink")
	L.text(img, "+1.2K", 8, 312, "y1", 2, "ink")
	L.text(img, "AUTO +3.4K/S", 8, 334, "gr3", 1, "ink")
	L.text(img, "FOCO DE TREINO", 136, 293, "g2", 1, "ink")
	var bw := 90
	var xs := [134, 228, 322, 416]
	focus_btn(img, xs[0], 304, bw, "owned_sel" if sel == 0 else "owned", "FORÇA", "SACO", "icon_strength", "1", "r2")
	focus_btn(img, xs[1], 304, bw, "owned", "AGILIDADE", "CORDA", "icon_agility", "2")
	focus_btn(img, xs[2], 304, bw, "owned", "RESIST.", "ESTEIRA", "icon_endurance", "3")
	var l1 := "BOXE" if art == "boxing" else "JIU-JITSU"
	var l2 := "PERA" if art == "boxing" else "BONECO"
	if art_st == "owned":
		focus_btn(img, xs[3], 304, bw, "owned_sel" if sel == 3 else "owned", l1, l2, "art_%s_9" % art, "4", "p2")
	else:
		focus_btn(img, xs[3], 304, bw, art_st, l2, "2.5K", "icon_%s_locked_buyable" % ("speed_bag" if art == "boxing" else "grappling_dummy"))
	# HUD da arte
	var txt := "BOXE: +50% NO SEU CLIQUE" if art == "boxing" else "JIU-JITSU: EQUIPE +48%"
	var cw: int = L.text_w(txt) + 19
	ns(img, "ui_art_chip", 506 - cw, 289, cw, 13)
	put(img, "art_%s_9" % art, 0, Vector2i(506 - cw + 3, 291))
	L.text(img, txt, 506 - cw + 15, 292, "p2", 1, "ink")
	L.text_center(img, "ESPAÇO OU CLIQUE PARA TREINAR", 320, 346, "g1", 1, "ink")
	ns(img, "ui_button_fight_normal", 520, 295, 112, 34)
	L.text_center(img, "LUTAR!", 576, 304, "y2", 2, "ink")
	ns(img, "ui_button_retire_normal", 520, 333, 112, 22)
	L.text_center(img, "APOSENTAR", 576, 340, "p2", 1, "ink")

func card_row(img: Image, y: int, icon: String, name: String, eff: String, effc: String, btn: String, price: String, can := true) -> void:
	ns(img, "ui_card", 516, y, 120, 44)
	put(img, icon, 0, Vector2i(521, y + 3))
	L.text(img, name, 541, y + 4, "white", 1, "ink")
	L.text(img, eff, 541, y + 14, effc, 1, "ink")
	ns(img, "ui_button_normal" if can else "ui_button_disabled", 520, y + 28, 112, 13)
	L.text(img, btn, 525, y + 31, "white" if can else "g1", 1, "ink")
	var pw: int = L.text_w(price)
	put(img, "icon_treino", 0, Vector2i(630 - pw - 11, y + 30))
	L.text(img, price, 630 - pw, y + 31, "y1" if can else "r2", 1, "ink")

func right_panel_gym(img: Image, art: String) -> void:
	L.panel(img, 512, 18, 128, 272)
	ns(img, "ui_button_focus_endurance", 515, 21, 58, 14)
	L.text(img, "TREINO", 530, 24, "y2", 1, "ink")
	ns(img, "ui_button_normal", 576, 21, 58, 14)
	L.text(img, "LOJA", 594, 24, "g3", 1, "ink")
	L.text(img, "TÉCNICAS", 518, 41, "cream", 1, "ink")
	if art == "boxing":
		card_row(img, 51, "icon_tech_boxing_1", "JAB DUPLO", "PERA X3", "p2", "APRENDIDA", "", false)
		card_row(img, 98, "icon_tech_boxing_2", "ESQUIVA E VOLTA", "PERA X5", "p2", "APRENDER", "15K")
	else:
		card_row(img, 51, "icon_tech_bjj_1", "GUARDA FECHADA", "BONECO X3", "p2", "APRENDER", "1.5K")
		card_row(img, 98, "icon_tech_bjj_2", "RASPAGEM", "BONECO X5", "p2", "APRENDER", "15K", false)
	L.text(img, "MELHORIAS", 518, 148, "cream", 1, "ink")
	card_row(img, 158, "icon_bag", "AREIA PENEIRADA", "SACO X5", "r3", "COMPRAR", "5K")
	card_row(img, 205, "icon_treadmill", "CORREIA EMENDADA", "ESTEIRA X5", "y1", "COMPRAR", "5K")

func hud_gym(art: String) -> Dictionary:
	return {"money": "$ 2.3K", "treino": "18.6K", "treino_s": "+3.4K/S", "fama": "430", "local": "ACADEMIA BOA ESQUINA",
		"carreira": "CARREIRA 3", "attrs": [["FORÇA", "182K", 0.62, "r2", "r2"], ["AGILIDADE", "71K", 0.4, "b3", "b2"], ["RESISTÊNCIA", "640K", 0.7, "y1", "y0"]],
		"legado": "1.1K", "adv": "TONHÃO", "adv2": "DO TATAME", "risco": "EQUILIBRADO", "risco_cor": "y1", "cmp": [["FOR", 260, 182], ["AGI", 100, 71], ["RES", 1100, 640]],
		"shop": [], "ups": [], "prox_local": "", "prox_req": "", "clique": "+1.2K", "focos": [["", "", "d2", false]], "dica": ""}

func make_mock_academia() -> void:
	var out: Image = L.blank(1280, 360)
	# ---- esquerda: academia, carreira de Boxe, saco em foco, pera na parede, equipe toda, Metrônomo
	var img := room("gym", "bag", "boxing", "owned", 6, 2, 1)
	put(img, "fx_impact", 1, Vector2i(323, 222))
	L.text(img, "+1.2K", 300, 186, "y1", 1, "ink")
	L.game_ui(img, hud_gym("boxing"))
	right_panel_gym(img, "boxing")
	bottom_bar4(img, "boxing", "owned", 0)
	# HUD: ícone do local
	put(img, "icon_location_gym", 0, Vector2i(634 - L.text_w("ACADEMIA BOA ESQUINA") - 12, 5))
	out.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i.ZERO)
	# ---- direita: janela de arte (1ª chegada) por cima da academia escurecida
	var w := room("gym", "bag", "", "owned", 3, 2, 0)
	L.game_ui(w, hud_gym(""))
	dim(w, Rect2i(0, 0, 640, 360))
	var lay: Dictionary = {"window": [110, 34, 420, 268], "cards": [[124, 70, 190, 220], [326, 70, 190, 220]]}
	ns(w, "ui_window", 110, 34, 420, 268)
	ns(w, "ui_window_title_retire", 116, 40, 408, 14)
	L.text_center(w, "QUE TIPO DE LUTADOR VOCÊ QUER SER?", 320, 43, "white", 1, "ink")
	L.text_center(w, "AS DUAS ARTES FICAM LIBERADAS PARA SEMPRE", 320, 58, "g3", 1, "ink")
	var arts := [["boxing", "BOXE", ["MÃO RÁPIDA, CABEÇA FRIA.", "QUEM CLICA, MANDA."], "+50% TREINO NO CLIQUE", "DA SUA MÃO", "BOXE: +10% DE DANO", "ui_art_card_last"],
		["bjj", "JIU-JITSU", ["SEM PRESSA. QUANTO MAIS", "TEMPO, MAIS APERTA."], "EQUIPE +20% (SOBE 12%", "POR MINUTO ATÉ 100%)", "JIU-JITSU: -10% DE DANO", "ui_art_card_hover"]]
	for i in 2:
		var a: Array = arts[i]
		var c: Array = lay.cards[i]
		var cx: int = c[0]
		var cy: int = c[1]
		ns(w, a[6], cx, cy, c[2], c[3])
		ns(w, "ui_art_card_header_" + a[0], cx + 6, cy + 6, 178, 18)
		put(w, "art_" + a[0], 0, Vector2i(cx + 9, cy + 7))
		L.text_center(w, a[1], cx + 95, cy + 9, "white", 2, "ink")
		put(w, "art_card_" + a[0], 0, Vector2i(cx + 59, cy + 28))
		L.text_center(w, a[2][0], cx + 95, cy + 90, "cream", 1, "ink")
		L.text_center(w, a[2][1], cx + 95, cy + 100, "cream", 1, "ink")
		L.text_center(w, a[3], cx + 95, cy + 116, "p2", 1, "ink")
		L.text_center(w, a[4], cx + 95, cy + 126, "p2", 1, "ink")
		L.text_center(w, a[5], cx + 95, cy + 142, "r3" if i == 0 else "b3", 1, "ink")
		L.text_center(w, "VALE A CARREIRA INTEIRA", cx + 95, cy + 162, "g2", 1, "ink")
		ns(w, "ui_button_art_hover" if i == 1 else "ui_button_art_normal", cx + 35, cy + 186, 120, 22)
		L.text_center(w, "ESCOLHER", cx + 95, cy + 193, "white", 1, "ink")
		if i == 0:
			var tw: int = L.text_w("ÚLTIMA: BOXE") + 8
			ns(w, "ui_art_tag_last", cx + c[2] - tw - 6, cy - 5, tw, 11)
			L.text(w, "ÚLTIMA: BOXE", cx + c[2] - tw - 2, cy - 3, "br0")
	out.blit_rect(w, Rect2i(0, 0, 640, 360), Vector2i(640, 0))
	save_x(out, MOCK + "fase5_academia_x2.png", 2)

func move_card(img: Image, x: int, y: int, st: String) -> void:
	var card: String = {"ready": "ui_move_card_ready", "dim": "ui_move_card_dim"}[st]
	ns(img, card, x, y, 120, 148)
	put(img, "icon_move", 0, Vector2i(x + 6, y + 6))
	L.text(img, "ACADEMIA", x + 26, y + 7, "white", 1, "ink")
	L.text(img, "BOA ESQUINA", x + 26, y + 16, "cream", 1, "ink")
	L.text(img, "TREINO X2 /", x + 8, y + 32, "gr3", 1, "ink")
	L.text(img, "2 LUTAS DA CASA", x + 8, y + 41, "gr3", 1, "ink")
	L.text(img, "TUDO O QUE VOCÊ", x + 8, y + 56, "g3", 1, "ink")
	L.text(img, "COMPROU VAI JUNTO", x + 8, y + 65, "g3", 1, "ink")
	L.text(img, "VALE ATÉ O FIM", x + 8, y + 80, "g2", 1, "ink")
	L.text(img, "DESTA CARREIRA", x + 8, y + 89, "g2", 1, "ink")
	var bid := "ui_button_move_normal" if st == "ready" else "ui_button_move_disabled"
	ns(img, bid, x + 6, y + 114, 108, 26)
	put(img, "icon_move_9", 0, Vector2i(x + 12, y + 122))
	L.text(img, "MUDAR", x + 25, y + 123, spr(bid).text_color, 1, "ink")
	put(img, "icon_money", 0, Vector2i(x + 72, y + 122))
	L.text(img, "1.000", x + 83, y + 123, "y1" if st == "ready" else "r2", 1, "ink")

func make_mock_marcas() -> void:
	var out: Image = L.blank(1280, 360)
	# ---- esquerda: garagem, carreira de Boxe (3ª), esteira comprada, pera em marca de fita, cinturão: cartão MUDAR
	var g := room("garage", "bag", "boxing", "mark", 2, 1, 0, ["PERA", "2.5K TREINO"])
	var hud := hud_gym("boxing")
	hud.local = "FUNDO DA GARAGEM"
	hud.money = "$ 1.4K"
	L.game_ui(g, hud)
	L.panel(g, 4, 138, 120, 148, "d1", "d1", "d1")
	move_card(g, 4, 138, "ready")
	L.panel(g, 512, 18, 128, 272)
	ns(g, "ui_button_focus_endurance", 515, 21, 58, 14)
	L.text(g, "TREINO", 530, 24, "y2", 1, "ink")
	ns(g, "ui_button_normal", 576, 21, 58, 14)
	L.text(g, "LOJA", 594, 24, "g3", 1, "ink")
	L.text(g, "APARELHOS", 518, 41, "cream", 1, "ink")
	ns(g, "ui_card_unlock", 516, 51, 120, 44)
	put(g, "icon_speed_bag_locked_buyable", 0, Vector2i(521, 54))
	L.text(g, "PERA", 541, 55, "white", 1, "ink")
	L.text(g, "FOR AGI RES", 541, 65, "g2", 1, "ink")
	ns(g, "ui_button_normal", 520, 79, 112, 13)
	L.text(g, "COMPRAR", 525, 82, "white", 1, "ink")
	put(g, "icon_treino", 0, Vector2i(597, 81)); L.text(g, "2.5K", 608, 82, "y1", 1, "ink")
	bottom_bar4(g, "boxing", "buyable", 0)
	out.blit_rect(g, Rect2i(0, 0, 640, 360), Vector2i.ZERO)

	# ---- direita: prancha
	var p: Image = L.blank(640, 360)
	L.R(p, 0, 0, 640, 360, "d1")
	L.text(p, "JIU-JITSU NA ACADEMIA: MARCA, FOCO E DESCANSO", 6, 4, "y1", 1, "ink")
	var a1 := room("gym", "bag", "bjj", "mark", 1, 2, 0, ["BONECO", "DEPOIS DA", "ESTEIRA"])
	p.blit_rect(a1.get_region(Rect2i(150, 196, 190, 94)), Rect2i(0, 0, 190, 94), Vector2i(6, 14))
	var a2 := room("gym", "dummy", "bjj", "owned", 1, 2, 1)
	p.blit_rect(a2.get_region(Rect2i(250, 176, 150, 114)), Rect2i(0, 0, 150, 114), Vector2i(202, 14))
	var a3 := room("gym", "bag", "bjj", "owned", 1, 2, 0)
	p.blit_rect(a3.get_region(Rect2i(150, 196, 140, 94)), Rect2i(0, 0, 140, 94), Vector2i(358, 14))
	L.text(p, "MARCA + PLAQUINHA", 6, 110, "cream", 1, "ink"); L.text(p, "FOCO (CENTRO)", 202, 130, "cream", 1, "ink"); L.text(p, "DESCANSO NO TATAME", 358, 110, "cream", 1, "ink")
	# pera em foco (recorte) e técnicas
	var b2 := room("gym", "speed_bag", "boxing", "owned", 0, 0, 1)
	put(b2, "speed_bag_l1_hit", 1, SB_CENTER)
	p.blit_rect(b2.get_region(Rect2i(272, 180, 90, 110)), Rect2i(0, 0, 90, 110), Vector2i(504, 14))
	L.text(p, "PERA EM FOCO", 506, 126, "cream", 1, "ink")
	# chegada da pera (parede) e do boneco (chão)
	L.text(p, "CHEGADA DA PERA (PRESA NA PAREDE + BALANÇO)", 6, 142, "y1", 1, "ink")
	var drops := [-8, -3, 0, 0, 0, 0]
	for f in 6:
		var gg := room("gym", "bag", "", "owned", 0, 0, 0)
		if f == 0:
			put(gg, "tape_mark_speed_bag", 0, SB_WALL)
		elif f < 3:
			put(gg, "speed_bag_l0_wall_gym", 0, SB_WALL + Vector2i(0, drops[f]))
			put(gg, "fx_arrive_sparkle", f - 1, Vector2i(436, 52))
		else:
			put(gg, "speed_bag_l0_wall_swing_gym", f - 2, SB_WALL)
		p.blit_rect(gg.get_region(Rect2i(400, 36, 70, 68)), Rect2i(0, 0, 70, 68), Vector2i(6 + f * 74, 152))
	L.text(p, "CHEGADA DO BONECO (CAI NO CANTO + POEIRA)", 6, 226, "y1", 1, "ink")
	var gdrops := [-18, -8, 0, 0, 0, 0]
	for f in 6:
		var gg2 := room("gym", "bag", "", "owned", 0, 0, 0)
		if f == 0:
			put(gg2, "tape_mark_grappling_dummy", 0, GD_REST)
		else:
			put(gg2, "grappling_dummy_l0_rest_gym", 0, GD_REST + Vector2i(0, gdrops[f]))
			if f >= 2:
				put(gg2, "fx_arrive_dust_small", f - 2, GD_REST)
		p.blit_rect(gg2.get_region(Rect2i(186, 244, 86, 46)), Rect2i(0, 0, 86, 46), Vector2i(6 + f * 74, 236))
	# MUDAR apagado + ESTILO
	L.text(p, "MUDAR SEM DINHEIRO", 452, 142, "y1", 1, "ink")
	move_card(p, 452, 152, "dim")
	L.text(p, "ABA ESTILO", 6, 288, "y1", 1, "ink")
	ns(p, "ui_tree_column_style", 6, 298, 226, 58)
	put(p, "icon_branch_style", 0, Vector2i(10, 300))
	L.text_center(p, "ESTILO", 119, 301, "white", 1, "ink")
	put(p, "skill_style_boxing_owned", 0, Vector2i(30, 318))
	put(p, "skill_style_bjj_buyable", 0, Vector2i(140, 318))
	L.text(p, "MÃO DE SINO", 58, 322, "white", 1, "ink"); L.text(p, "PESO DO", 168, 318, "white", 1, "ink"); L.text(p, "TEMPO", 168, 327, "white", 1, "ink")
	L.text(p, "TÉCNICAS", 240, 288, "y1", 1, "ink")
	var tx := 240
	for t in ["icon_tech_boxing_1", "icon_tech_boxing_2", "icon_tech_bjj_1", "icon_tech_bjj_2", "art_boxing", "art_bjj", "icon_move", "skill_style_boxing", "skill_style_bjj"]:
		put(p, t, 0, Vector2i(tx, 300))
		tx += 22
	L.text(p, "FOCO DA ARTE", 240, 322, "y1", 1, "ink")
	focus_btn(p, 240, 322 + 8, 90, "owned_sel", "BOXE", "PERA", "art_boxing_9", "4", "p2")
	focus_btn(p, 336, 330, 90, "locked", "BONECO", "DEPOIS DA", "icon_grappling_dummy_locked")
	out.blit_rect(p, Rect2i(0, 0, 640, 360), Vector2i(640, 0))
	save_x(out, MOCK + "fase5_marcas_x2.png", 2)

# ================================================================ folha de contato
func make_contact_sheet(path: String, title: String) -> void:
	var S := 3
	var W := 1900
	var gap := 18
	var x := gap
	var y := 50
	var row_h := 0
	var places := []
	for e in SHEETS:
		var img: Image = e[1]
		var w: int = img.get_width() * S
		var lw: int = L.text_w(str(e[0]), 2)
		var h: int = img.get_height() * S + 22
		if x + maxi(w, lw) > W - gap:
			x = gap
			y += row_h + gap
			row_h = 0
		places.append([e, Vector2i(x, y)])
		x += maxi(w, lw) + gap
		row_h = maxi(row_h, h)
	var H := y + row_h + gap
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, title, gap, 14, "y1", 3, "ink")
	for pl in places:
		var e: Array = pl[0]
		var pp: Vector2i = pl[1]
		var img: Image = e[1]
		var fw: int = e[2]
		L.text(out, str(e[0]), pp.x, pp.y, "cream", 2, "ink")
		var big: Image = img.duplicate()
		big.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
		var oy := pp.y + 20
		for yy in range(0, big.get_height(), 6):
			for xx in range(0, big.get_width(), 6):
				L.R(out, pp.x + xx, oy + yy, mini(6, big.get_width() - xx), mini(6, big.get_height() - yy), "d2" if ((xx + yy) / 6) % 2 == 0 else "g0")
		out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(pp.x, oy))
		var nf := img.get_width() / fw
		for i in range(1, nf):
			L.R(out, pp.x + i * fw * S, oy, 1, big.get_height(), "y0")
	out.save_png(path)

# ================================================================ main
func _init() -> void:
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(OUT + "manifest.json")) == OK:
		OLD = j.data
	make_gym_bg()
	make_bag_gym()
	make_treadmill_gym()
	make_rope_gym()
	make_speed_bag()
	make_grappling_dummy()
	make_marks()
	make_arrival_small()
	make_icons()
	make_buttons()
	make_panels()
	make_style_nodes()
	write_manifest()
	make_contact_sheet(MOCK + "fase5_sprites_x3.png", "FIGHTCLICKER - FASE 5 - SPRITES PLACEHOLDER (x3)")
	make_mock_academia()
	make_mock_marcas()
	# sala da academia limpa (conferência) no scratch
	for s in ["PERA", "2.5K TREINO", "DEPOIS DA", "BONECO", "JIU-JITSU", "RESIST.", "BOXE: +50% NO SEU CLIQUE", "JIU-JITSU: EQUIPE +100% (MÁX.)", "ÚLTIMA: BOXE", "ACADEMIA BOA ESQUINA", "2 LUTAS DA CASA", "COMPROU VAI JUNTO"]:
		print("largura '%s' = %d px" % [s, L.text_w(s)])
	print("ok: sprites da fase 5 gerados")
	quit()
