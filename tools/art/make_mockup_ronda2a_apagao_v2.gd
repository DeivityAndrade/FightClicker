extends SceneTree
## Ronda 2a (Artista de Personagens): APAGÃO V2 (o B, guardado para capítulo futuro), com antes (v1) x depois. Cópia do
## make_mockup_ronda2a_viloes.gd (que fica como está) + a seção "B v2" no fim. Saída: <saida>/ronda2a_apagao_v2.png.
## [v1, base desta cópia:] MOCKUPS dos 3 candidatos a supervilão.
##   A = rei do ferro-velho (armadura de calotas, câmara de pneu, "jura que é robô")
##   B = eletricista que apaga a luz do bairro (capacete com lanterna, bateria de carro nas costas, luva de borracha)
##   C = ex-mascote de time de várzea preso na fantasia gigante (capivara de espuma, camisa 10)
## Não é folha de animação: são 3 poses por vilão (guarda, antecipação, golpe) no quadro de luta 112x104, pivô (56,98),
## desenhados virados para a DIREITA no rig comum (personagem_lib.fight_frame + ganchos) e espelhados como os adversários.
## Padrão: .claude/skills/padrao-personagem. Cores: só a paleta de 45 (pixel_lib.gd).
##
## Rodar headless de uma pasta temporária com project.godot vazio, APPDATA temporário, um Godot por vez:
##   godot --headless --max-fps 30 --path <tmp> --script <repo>/tools/art/make_mockup_ronda2a_apagao_v2.gd -- <repo> <saida>
## Grava em <saida>: ronda2a_apagao_v2.png (copiar para docs/arte/mockups/) e b2_<pose>.png (5x, conferência).
## Lê (sem gravar) o vulto da Ronda: assets/sprites/minigame/ronda_vulto_scare_disc_body/head_short.png (quadro 6).

const FW := 112
const FH := 104
const PIV := Vector2(56, 98)
const PIV_FLIPX := 55            # pivô x depois do espelho (111 - 56)
const VFW := 96
const VPIV := Vector2i(50, 94)

var L
var P
var R := ""
var report: Array = []
var _hd := Vector2.ZERO          # centro da cabeça do último quadro (para FX)
var _hf := Vector2.ZERO
var _hb := Vector2.ZERO
var _elf := Vector2.ZERO
var _bat := Vector2.ZERO

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================================================ calçados (dados)
const BOTA_FLAT := ["..DMw......", ".DMMw......", ".DMMw......", ".DMMwL.....", ".DMMMwL....", "DMMMMMMLL..", "DMMMMMMMMMD", "ccccccccccc"]
const BOTA_BALL := [".DMw.......", ".DMMw......", ".DMMwL.....", "..DMMwL....", "..DDMMMML..", "....DMMMMMD", ".....cccccc"]
## Pé de fantasia (C): pata redonda gigante, 3 garras de feltro creme na frente, sola escura.
const PATA_FLAT := ["...DMMM.......", "..DMMMMMLL....", ".DMMMMMMMMLL..", "DMMMMMMMMMMMLw", "DMMMMMMMMMMMMw", "DDMMMMMMMMMMMw", ".cccccccccccc."]
const PATA_BALL := ["..DMM.........", "..DMMMLL......", "..DMMMMMMLL...", "...DMMMMMMMLw.", "...DDMMMMMMMMw", "....DDMMMMMMMw", ".....cccccccc."]

func shoes_of(flat: Array, ball: Array, tf: Vector2i, af: Vector2i, tb: Vector2i, ab: Vector2i) -> Dictionary:
	return {"flat": {"rows": flat, "toe": tf, "ankle": af, "ang": 0.0},
		"ball": {"rows": ball, "toe": tb, "ankle": ab, "ang": 0.0},
		"up": {"rows": flat, "toe": tf, "ankle": af, "ang": -90.0}}

# ================================================================================================ cabeças (dados)
## A: capacete feito de calota virada (domo prateado com furos), coroa de porcas de latão soldadas, visor de fresta com
## olho de olho-de-gato vermelho (o "robô"), barba grisalha cheia embaixo. Perfil virado para a direita. Âncora (8,9).
## K/k/j/W = calota (st1/st2/st3/white), Y/y = latão (y0/y1), V = fresta (d1), R/r = refletor (r2/r3),
## G/g/w = barba (g1/g2/g3), S/s/l = pele.
const HEAD_A := [
	"....y.y.y.y......",
	"...YyYyYyYyY.....",
	"...KkkjjjjWWj....",
	"..KkkdkjjdjjWj...",
	"..KkkkkjjjjjjjW..",
	".KKkdkkkkjdjjjjj.",
	"KKKKKkkkkkkkkjjjj",
	".GKKKKKKKKKKKKKKK",
	".GGKVVVVVVVVRrVk.",
	".GGKkkkkkkkkkkkk.",
	"..GGgggggsssll...",
	"..GGggwwgggggsl..",
	"..GGgggggwwggg...",
	"...GGgggggggg....",
	"....GGggwggg.....",
	".....GGgggg......",
]
## B: capacete amarelo de obra com aba comprida e LANTERNA na frente (O/o), óculos de proteção no capacete (q),
## rosto chupado, nariz comprido, sorriso de dentes à mostra (T), bigodinho fino (o). Âncora (8,9).
const HEAD_B := [
	".....JjjjjjJ......",
	"...JjjjjjiiijJ....",
	"..JjjjjjjjiiijjG..",
	"..JjjjjjjjjjjjjGOO",
	".JJJJJJJJJJJJJJGoO",
	"JJJJJJJJJJJJJJJJJ.",
	"..HHHHsssbbbbs....",
	"..HHEQQQQQqqiQL...",
	"..HHEsEssssssll...",
	"..HHEEssssssssl...",
	"...HSsssssssssss..",
	"...HSssssssUUUs...",
	"....SsssssTTTTx...",
	"....SSsssssxxS....",
	".....SSsssss......",
	"......SSSSs.......",
]

func head_a_build() -> Dictionary:
	return {"head_side": HEAD_A, "head_anchor_side": Vector2i(8, 9), "faces_side": {},
		"head_legend_extra": {"K": "st1", "k": "st2", "j": "st3", "W": "white", "d": "d2", "Y": "y0", "y": "y1",
			"V": "d1", "R": "r2", "r": "r3", "G": "g1", "g": "g2", "w": "g3", "H": "d2"}}

func head_b_build() -> Dictionary:
	return {"head_side": HEAD_B, "head_anchor_side": Vector2i(8, 9), "faces_side": {},
		"head_legend_extra": {"J": "y0", "j": "y1", "i": "y2", "G": "g1", "O": "white", "o": "y2", "q": "d1", "Q": "g0",
			"T": "white", "U": "br0", "L": "sk1", "H": "br0"}}

## C: cabeça de capivara de espuma, gigante (25x19 contra 14x14 de uma cabeça normal). Olho de desenho arregalado (E/e),
## remendo costurado (X), orelha pequena com o forro (P), focinho chato com narina (N) e a BOCA de tela (N/n) onde aparece
## o olho de verdade de quem está preso lá dentro (W/e). Dentes da frente amarelos (Y). Âncora (12,10).
const HEAD_C := [
	"....kkk..................",
	"...kPPmk.................",
	"...kPmmk...kkkkkk........",
	"...kmmmmMMMMMMMMMMk......",
	"..kmmmmmmMMMMMMMMMMMk....",
	".kmmmmmmmmMMMMMMMMMMMMk..",
	".kmmmmmmmEEEEmMMMMMMMMMk.",
	"kmmmmmmmEEEEEEmmmMMMMMMMk",
	"kmmmXmmmEEEEeeEmmmmmmmmNk",
	"kmmXmXmmEEEEeeEmmmmmmmmMk",
	"kmmmXmmmmEEEEEmmmmmmmmmMk",
	"kkmmmmmmmmmmmmmmmmmmmmmmk",
	".kmmmmmmmmmmmmNNNNNNNNNmk",
	".kkmmmmmmmmmmNnNnNWeNnNnk",
	"..kkmmmmmmmmmNNnNnNNnNNYk",
	"...kkkmmmmmmmmNNNNNNNNYYk",
	".....kkkkmmmmmmmmmmmmmmk.",
	"........kkkkkkkkkkkkkkk..",
]
const HEAD_C_LEG := {"k": "br1", "m": "br2", "M": "br3", "P": "sk1", "E": "white", "e": "ink", "X": "cream",
	"N": "d1", "n": "g0", "W": "white", "Y": "y0"}

# ================================================================================================ peças (primitivas)
## Elipse sombreada (luz de cima/frente, igual ao rig). ramp = [sombra, base, luz, (brilho)]. ang em graus.
func blob(id: int, c: Vector2, rx: float, ry: float, ramp: Array, ang := 0.0) -> void:
	var m := int(ceil(maxf(rx, ry))) + 1
	for y in range(int(floor(c.y)) - m, int(ceil(c.y)) + m + 1):
		for x in range(int(floor(c.x)) - m, int(ceil(c.x)) + m + 1):
			var q: Vector2 = P.rotv(Vector2(x + 0.5, y + 0.5) - c, -ang)
			var u := q.x / rx
			var v := q.y / ry
			var r2 := u * u + v * v
			if r2 > 1.0:
				continue
			var nw: Vector2 = P.rotv(Vector2(u, v), ang)
			var lv := nw.dot(P.LD)
			var col = ramp[1]
			if lv > 0.3:
				col = ramp[2]
			elif lv < -0.3:
				col = ramp[0]
			if ramp.size() > 3 and lv > 0.62 and r2 > 0.3:
				col = ramp[3]
			P.put(x, y, col, id)

## Calota: aro claro/escuro, prato, 5 furos radiais, miolo de latão e um ponto de ferrugem. rx/ry = elipse (vista de
## lado fica estreita), ang = giro da elipse.
func hubcap(id: int, c: Vector2, rx: float, ry: float, ang := 0.0, spin := 0.0) -> void:
	var m := int(ceil(maxf(rx, ry))) + 1
	for y in range(int(floor(c.y)) - m, int(ceil(c.y)) + m + 1):
		for x in range(int(floor(c.x)) - m, int(ceil(c.x)) + m + 1):
			var q: Vector2 = P.rotv(Vector2(x + 0.5, y + 0.5) - c, -ang)
			var u := q.x / rx
			var v := q.y / ry
			var r2 := u * u + v * v
			if r2 > 1.0:
				continue
			var nw: Vector2 = P.rotv(Vector2(u, v), ang)
			var lv := nw.dot(P.LD)
			var col = "st2"
			if r2 > 0.62:                       # aro
				col = "st3" if lv > 0.0 else "st1"
				if lv > 0.65:
					col = "white"
			else:
				col = "st2" if lv > -0.25 else "st1"
				if lv > 0.45 and r2 > 0.25:
					col = "st3"
				var th := atan2(v, u) + deg_to_rad(spin)
				var k := fposmod(th * 5.0 / TAU, 1.0)
				if r2 > 0.14 and r2 < 0.44 and (k < 0.17):
					col = "d2"                  # furo
				if r2 <= 0.08:
					col = "y1" if lv > -0.1 else "y0"   # miolo de latão
			P.put(x, y, col, id)
	# ferrugem
	var rp: Vector2 = c + P.rotv(Vector2(-rx * 0.45, ry * 0.4), ang)
	P.put(int(rp.x), int(rp.y), "br2", id)
	P.put(int(rp.x) + 1, int(rp.y), "br1", id)

## Fio/cabo de 1 px em curva (bezier quadrática com barriga para baixo).
func wire(id: int, a: Vector2, b: Vector2, sag: float, col, col2 = null) -> void:
	var mid := (a + b) * 0.5 + Vector2(0, sag)
	var n := int((a - b).length() * 1.6) + 4
	var last := Vector2i(-999, -999)
	for i in range(n + 1):
		var t := float(i) / float(n)
		var p := a.lerp(mid, t).lerp(mid.lerp(b, t), t)
		var pi := Vector2i(int(floor(p.x)), int(floor(p.y)))
		if pi == last:
			continue
		last = pi
		P.put(pi.x, pi.y, col, id)
		if col2 != null:
			P.put(pi.x, pi.y + 1, col2, id)

## Retângulo girado (caixa) com 3 tons: sombra no lado de trás/baixo, luz em cima.
func box(id: int, c: Vector2, w: float, h: float, ang: float, ramp: Array) -> void:
	var m := int(ceil(maxf(w, h)))
	for y in range(int(floor(c.y)) - m, int(ceil(c.y)) + m + 1):
		for x in range(int(floor(c.x)) - m, int(ceil(c.x)) + m + 1):
			var q: Vector2 = P.rotv(Vector2(x + 0.5, y + 0.5) - c, -ang)
			if absf(q.x) > w * 0.5 or absf(q.y) > h * 0.5:
				continue
			var col = ramp[1]
			if q.y < -h * 0.5 + 1.5:
				col = ramp[2]
			elif q.x < -w * 0.5 + 1.6 or q.y > h * 0.5 - 1.2:
				col = ramp[0]
			P.put(x, y, col, id)

## Pinta só sobre os pixels de um id (roupa por cima do tronco): fn(x, y) -> cor ou null.
func over_id(id: int, rect: Rect2i, fn: Callable) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x < 0 or y < 0 or x >= P.cw or y >= P.ch or P.ids[y * P.cw + x] != id:
				continue
			var c = fn.call(x, y)
			if c != null:
				P.put(x, y, c, id)

# ================================================================================================ FX (sem contorno)
func fx(img: Image, x: int, y: int, c) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, L.col(c))

## Raio em zigue-zague de a até b: miolo branco, borda amarela, galhos curtos.
func bolt(img: Image, a: Vector2, b: Vector2, seed_: int, segs := 5, amp := 3.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var pts := [a]
	var d := b - a
	var n := Vector2(-d.y, d.x).normalized()
	for i in range(1, segs):
		pts.append(a + d * (float(i) / segs) + n * rng.randf_range(-amp, amp))
	pts.append(b)
	for i in range(pts.size() - 1):
		_seg(img, pts[i], pts[i + 1], "white", "y2")
		if i > 0 and rng.randf() < 0.5:
			var br: Vector2 = pts[i] + (d.normalized() * 3.0 + n * rng.randf_range(-4.0, 4.0))
			_seg(img, pts[i], br, "y2", null)

func _seg(img: Image, a: Vector2, b: Vector2, core, edge) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / n)
		if edge != null:
			fx(img, int(p.x), int(p.y) - 1, edge)
			fx(img, int(p.x), int(p.y) + 1, edge)
	for i in range(n + 1):
		var p := a.lerp(b, float(i) / n)
		fx(img, int(p.x), int(p.y), core)

func spark(img: Image, c: Vector2, r: int, big := false) -> void:
	fx(img, int(c.x), int(c.y), "white")
	for k in range(1, r + 1):
		var cc = "y2" if k < r else "y1"
		fx(img, int(c.x) + k, int(c.y), cc)
		fx(img, int(c.x) - k, int(c.y), cc)
		fx(img, int(c.x), int(c.y) + k, cc)
		fx(img, int(c.x), int(c.y) - k, cc)
		if big and k < r:
			fx(img, int(c.x) + k, int(c.y) + k, "y1")
			fx(img, int(c.x) - k, int(c.y) - k, "y1")
			fx(img, int(c.x) + k, int(c.y) - k, "y1")
			fx(img, int(c.x) - k, int(c.y) + k, "y1")

## Estrela de impacto (receita do K.O.: branco no meio, amarelo, borda vermelha), com 8 pontas.
func impact(img: Image, c: Vector2, r: float) -> void:
	for y in range(int(c.y - r - 1), int(c.y + r + 2)):
		for x in range(int(c.x - r - 1), int(c.x + r + 2)):
			var d := Vector2(x + 0.5, y + 0.5) - c
			var a := atan2(d.y, d.x)
			var rr := r * (0.55 + 0.45 * pow(absf(cos(a * 4.0)), 3.0))
			var l := d.length()
			if l > rr:
				continue
			var cc = "white"
			if l > rr * 0.45:
				cc = "y2"
			if l > rr * 0.72:
				cc = "y1"
			if l > rr * 0.9:
				cc = "r2"
			fx(img, x, y, cc)

# ================================================================================================ A: REI CALOTA
func build_a() -> Dictionary:
	var s := 1.14
	var o := {"lu": 12.0 * s, "lf": 13.0 * s, "lt": 17.5 * s, "ls": 16.5 * s,
		"skin": ["sk0", "sk1", "sk2"], "brow": "d1",
		"top": "tshirt", "sleeve_long": true, "shirt": ["d1", "d2", "g0"], "trim": "d1",
		"bottom": "pants", "shorts": ["br0", "br1", "br2"], "band": "br0", "pants_add": 1.2, "pants_shin_t": 0.8,
		"shoes": ["d1", "d2", "g0", "g1", "ink"], "shoe_maps": shoes_of(BOTA_FLAT, BOTA_BALL, Vector2i(10, 7), Vector2i(3, 3), Vector2i(10, 6), Vector2i(2, 1)),
		"glove": "couro", "glove_ramp": ["br2", "br3", "y0"],
		"shoulder": 1.5, "hip_w": 1.3, "belly": 5.0, "arm_r": [4.4, 3.6, 3.8, 2.6], "leg_r": [5.6, 4.3, 3.9, 2.5]}
	o.merge(head_a_build(), true)
	return P.build(o)

## Ganchos da armadura. shield: "hand" (calota na mão da frente), "back" (atrás, armando), "" (arremessada)
func a_hooks(p: Dictionary, shield: String) -> Dictionary:
	p["before_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hip: Vector2 = ctx.hip
		var top: Vector2 = ctx.top
		var dn: Vector2 = ctx.dn
		var fr: Vector2 = ctx.fr
		var ln := (top - hip).length()
		# casco: calota nas costas (silhueta de tartaruga/robô)
		hubcap(29, hip + dn * ln * 0.68 - fr * 9.0, 3.2, 8.5, rad_to_deg(atan2(dn.x, -dn.y)))
		# ombreira de trás espiando
		hubcap(28, ctx.sb + Vector2(-1, -2), 4.5, 3.6)
	p["after_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hip: Vector2 = ctx.hip
		var top: Vector2 = ctx.top
		var dn: Vector2 = ctx.dn
		var fr: Vector2 = ctx.fr
		var ln := (top - hip).length()
		var ang := rad_to_deg(atan2(dn.x, -dn.y))
		# peitoral: a calota grande do peito, vista de lado (elipse estreita)
		hubcap(32, hip + dn * ln * 0.4 + fr * 7.5, 6.0, 8.6, ang, 8.0)
		# alças de câmara de pneu segurando o peitoral (por cima do ombro)
		wire(33, top + fr * 1.0 - dn * 1.5, hip + dn * ln * 0.78 + fr * 9.0, 0.0, "d2", "d1")
		# cinturão: câmara de pneu enrolada na cintura (borracha), com o bico da válvula
		var wc := hip + dn * ln * 0.2 + fr * 1.5
		blob(34, wc, 11.5, 3.4, ["d1", "d2", "g0", "g1"], ang)
		P.put(int(wc.x + fr.x * 10.0), int(wc.y - 3.0), "st3", 34)
		P.put(int(wc.x + fr.x * 10.0), int(wc.y - 4.0), "st2", 34)
		# antena de carro no capacete, com a ponta torta e a bolinha vermelha
		var hd: Vector2 = ctx.hd
		var a0 := hd + Vector2(-5, -8)
		var a1 := hd + Vector2(-9, -15)
		var a2 := hd + Vector2(-7, -18)
		wire(41, a0, a1, 0.0, "st2")
		wire(41, a1, a2, 0.0, "st2")
		P.put(int(a2.x), int(a2.y) - 1, "r2", 41)
		P.put(int(a2.x) + 1, int(a2.y) - 1, "r3", 41)
		P.put(int(a2.x), int(a2.y) - 2, "r3", 41)
		_hd = hd
	p["end"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		# ombreira da frente: calota sobre o ombro
		hubcap(63, ctx.sf + Vector2(0, -1.5), 5.6, 4.4, -8.0)
		var hf: Vector2 = ctx.hf
		_hf = hf
		_elf = ctx.elf
		if shield == "hand":
			hubcap(72, hf + Vector2(3.5, -0.5), 5.4, 11.0, 6.0)
		elif shield == "back":
			hubcap(72, hf + Vector2(-2, 0), 7.0, 8.0, -20.0, 20.0)
	return p

func poses_a() -> Dictionary:
	var g := a_hooks({"hip": V(0, -42), "top": V(4, -69), "head": V(8, -80), "toef": V(19, -1), "toeb": V(-7, -1),
		"hf": V(26, -67), "hb": V(15, -70), "pb": V(-0.5, 1.0), "pf": V(1.0, 0.3)}, "hand")
	var an := a_hooks({"hip": V(-1, -41), "top": V(-3, -68), "head": V(0, -79), "toef": V(19, -1), "toeb": V(-7, -1),
		"hf": V(-11, -63), "hb": V(14, -60), "tw": -1.0, "pf": V(0.3, 1.0), "gkf": "side:f"}, "back")
	var hi := a_hooks({"hip": V(3, -42), "top": V(10, -68), "head": V(14, -79), "toef": V(20, -1), "toeb": V(-6, -1),
		"shoeb": "ball", "tw": 2.0, "hf": V(36, -64), "hb": V(-3, -58), "gkf": "side"}, "")
	return {"guard": g, "antic": an, "hit": hi}

func frames_a() -> Dictionary:
	var b := build_a()
	var ps := poses_a()
	var out := {}
	for k in ["guard", "antic", "hit"]:
		var im: Image = P.fight_frame(b, ps[k], "A " + k)
		if k == "hit":
			# a calota voando (disco deitado girando) com rastro
			var c := PIV + V(52, -67)
			P.canvas(FW, FH)
			hubcap(1, c, 9.5, 3.4, -6.0)
			var disc: Image = P.finish()
			im.blend_rect(disc, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
			for i in 3:
				for xx in range(int(c.x) - 22 + i * 2, int(c.x) - 11 - i):
					fx(im, xx, int(c.y) - 2 + i * 2, "st3" if i != 1 else "white")
		out[k] = im
	return out

# ================================================================================================ B: APAGÃO
func build_b() -> Dictionary:
	var s := 1.1
	var am := 1.12
	var o := {"lu": 12.0 * s * am, "lf": 13.0 * s * am, "lt": 17.5 * s, "ls": 16.5 * s,
		"skin": ["sk1", "sk2", "y2"], "brow": "br0",
		"top": "tshirt", "sleeve_long": true, "shirt": ["st0", "st1", "st2"], "trim": "st0",
		"bottom": "pants", "shorts": ["st0", "st1", "st2"], "band": "st0", "pants_add": 0.8,
		"shoes": ["d1", "d2", "g0", "y0", "ink"], "shoe_maps": shoes_of(BOTA_FLAT, BOTA_BALL, Vector2i(10, 7), Vector2i(3, 3), Vector2i(10, 6), Vector2i(2, 1)),
		"glove": "plain", "glove_ramp": ["y0", "y1", "y2"],
		"shoulder": 0.92, "hip_w": 0.82, "belly": 0.0, "arm_r": [2.9, 2.2, 2.4, 1.7], "leg_r": [3.7, 2.7, 2.5, 1.6]}
	o.merge(head_b_build(), true)
	return P.build(o)

func b_hooks(p: Dictionary) -> Dictionary:
	p["before_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hip: Vector2 = ctx.hip
		var top: Vector2 = ctx.top
		var dn: Vector2 = ctx.dn
		var fr: Vector2 = ctx.fr
		var ln := (top - hip).length()
		var ang := rad_to_deg(atan2(dn.x, -dn.y))
		# bateria de carro nas costas (caixa escura, tampa cinza, polos vermelho e preto)
		var bc := hip + dn * ln * 0.66 - fr * 8.0
		box(26, bc, 9.0, 13.0, ang, ["d1", "d2", "g0"])
		var tp := bc + dn * 7.0
		box(27, tp, 9.0, 2.0, ang, ["g0", "g1", "g2"])
		var pr := tp + dn * 1.5 + fr * 2.0
		P.put(int(pr.x), int(pr.y), "r2", 27)
		P.put(int(pr.x), int(pr.y) - 1, "r3", 27)
		var pn := tp + dn * 1.5 - fr * 2.5
		P.put(int(pn.x), int(pn.y), "g1", 27)
		P.put(int(pn.x), int(pn.y) - 1, "g2", 27)
		# cabo PRETO até a luva de trás
		wire(24, pn + Vector2(0, -1), ctx.hb + Vector2(-3, 3), 9.0, "d1")
		_bat = (pr + pn) * 0.5
	p["after_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hip: Vector2 = ctx.hip
		var top: Vector2 = ctx.top
		var dn: Vector2 = ctx.dn
		var fr: Vector2 = ctx.fr
		var ln := (top - hip).length()
		# faixas refletivas no macacão (peito e cintura) e alça da bateria
		var r := Rect2i(0, 0, FW, FH)
		over_id(30, r, func(x: int, y: int):
			var t := (Vector2(x + 0.5, y + 0.5) - hip).dot(dn) / ln
			if absf(t - 0.62) < 0.035 or absf(t - 0.34) < 0.035:
				return "y1"
			return null)
		wire(31, top - fr * 2.0 - dn * 2.0, hip + dn * ln * 0.45 + fr * 4.0, 0.0, "d1")
		# cinto de ferramentas: alicate e rolo de fita
		var bt := hip + dn * ln * 0.24
		box(32, bt + fr * 3.0, 4.0, 3.0, 0.0, ["d1", "d2", "g0"])
		P.put(int(bt.x + fr.x * 3.0), int(bt.y + 2), "st3", 32)
		P.put(int(bt.x + fr.x * 3.0) + 1, int(bt.y + 3), "st3", 32)
		_hd = ctx.hd
	p["end"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		_hf = ctx.hf
		_hb = ctx.hb
		_elf = ctx.elf
		# cabo VERMELHO da bateria até a luva da frente (passa por baixo do braço)
		wire(59, ctx.top - ctx.fr * 6.0 + ctx.dn * -2.0, ctx.hf + Vector2(-4, 3), 10.0, "r1")
	return p

func poses_b() -> Dictionary:
	var g := b_hooks({"hip": V(0, -40), "top": V(5, -64), "head": V(11, -75), "toef": V(18, -1), "toeb": V(-8, -1),
		"hf": V(25, -57), "hb": V(17, -66), "gkf": "diag", "gkb": "diag"})
	var an := b_hooks({"hip": V(-1, -39), "top": V(1, -63), "head": V(6, -75), "toef": V(18, -1), "toeb": V(-8, -1),
		"shoeb": "ball", "hf": V(10, -55), "hb": V(7, -58), "gkf": "up", "gkb": "up"})
	var hi := b_hooks({"hip": V(3, -40), "top": V(11, -63), "head": V(17, -73), "toef": V(21, -1), "toeb": V(-7, -1),
		"shoeb": "ball", "tw": 1.6, "hf": V(41, -61), "hb": V(4, -55), "gkf": "side"})
	return {"guard": g, "antic": an, "hit": hi}

## posição da lanterna do capacete no quadro (virado para a direita)
func lamp_b() -> Vector2:
	return _hd + V(9, -6)

func frames_b() -> Dictionary:
	var b := build_b()
	var ps := poses_b()
	var out := {}
	for k in ["guard", "antic", "hit"]:
		var im: Image = P.fight_frame(b, ps[k], "B " + k)
		var lamp := lamp_b()
		out[k + "_lamp"] = lamp
		bolt(im, _bat + V(-2, -1), _bat + V(2, -4), 40 + k.length(), 2, 1.0)   # arco entre os polos da bateria
		match k:
			"guard":
				bolt(im, _hb + V(3, 2), _hf + V(-2, -3), 11, 3, 1.5)
				spark(im, (_hb + _hf) * 0.5 + V(1, -6), 1)
			"antic":
				bolt(im, _hb + V(3, -6), _hb + V(-4, -14), 21, 3, 2.0)
				bolt(im, _hf + V(4, -5), _hf + V(10, -13), 22, 3, 2.0)
				bolt(im, _hf + V(-3, 0), _hb + V(3, 1), 23, 2, 1.5)
				spark(im, _hf + V(5, -8), 2, true)
			"hit":
				bolt(im, _hf + V(5, -1), _hf + V(22, -6), 31, 5, 3.0)
				bolt(im, _hf + V(5, 1), _hf + V(20, 5), 32, 4, 3.0)
				bolt(im, _hf + V(4, -3), _hf + V(15, -12), 33, 3, 2.0)
				spark(im, _hf + V(7, 0), 3, true)
				spark(im, lamp, 2, true)     # lanterna estoura no golpe
		out[k] = im
	return out

# ================================================================================================ C: CAPIVARÃO
func build_c() -> Dictionary:
	var o := {"lu": 12.5, "lf": 12.5, "lt": 16.5, "ls": 15.0,
		"skin": ["br1", "br2", "br3"],
		"top": "tshirt", "sleeve_t": 0.45, "shirt": ["g3", "cream", "white"], "trim": "r1",
		"bottom": "shorts", "shorts": ["d1", "d2", "g0"], "band": "g0", "shorts_t": 0.5,
		"shoes": ["br0", "br1", "br2", "cream", "d1"], "shoe_maps": shoes_of(PATA_FLAT, PATA_BALL, Vector2i(13, 5), Vector2i(4, 0), Vector2i(13, 5), Vector2i(3, 0)),
		"glove": "tape", "glove_ramp": ["br1", "br2", "br3"],
		"shoulder": 1.35, "hip_w": 1.45, "belly": 8.0, "arm_r": [4.4, 3.6, 3.8, 2.8], "leg_r": [5.6, 4.6, 4.2, 3.0]}
	return P.build(o)

func c_hooks(p: Dictionary, hrot := 0.0) -> Dictionary:
	p["after_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hip: Vector2 = ctx.hip
		var top: Vector2 = ctx.top
		var dn: Vector2 = ctx.dn
		var fr: Vector2 = ctx.fr
		var ln := (top - hip).length()
		# camisa do time: listras vermelhas (aros) e o 10 nas costas
		over_id(30, Rect2i(0, 0, FW, FH), func(x: int, y: int):
			var q := Vector2(x + 0.5, y + 0.5) - hip
			var t := q.dot(dn) / ln
			var sv := q.dot(fr)
			if t > 0.3 and t < 0.92 and fposmod(t * 100.0, 15.0) < 4.5:
				return "r1" if sv < -2.0 else "r2"
			return null)
		var nb := hip + dn * ln * 0.55 - fr * 5.0
		for d in [V(0, 0), V(0, 1), V(0, 2), V(0, 3), V(2, 0), V(3, 0), V(2, 3), V(3, 3), V(2, 1), V(2, 2), V(3, 1), V(3, 2)]:
			P.put(int(nb.x + d.x) - 2, int(nb.y + d.y) - 1, "r0", 30)
		for d in [V(3, 1), V(3, 2)]:
			P.put(int(nb.x + d.x) - 2, int(nb.y + d.y) - 1, "cream", 30)
		# gola da fantasia: a pelúcia cobre a junção da cabeça
		blob(35, top + dn * 1.5 + fr * 1.0, 7.0, 3.6, ["br1", "br2", "br3"], rad_to_deg(atan2(dn.x, -dn.y)))
		# a cabeça gigante de espuma
		var hd: Vector2 = ctx.hd
		P.pmap(P.HEAD, HEAD_C, HEAD_C_LEG, hd, Vector2i(12, 10), hrot)
		# zíper aberto na nuca (um dente de metal aparecendo)
		var z: Vector2 = hd + P.rotv(V(-11, 6), hrot)
		P.put(int(z.x), int(z.y), "st3", P.HEAD)
		P.put(int(z.x) + 1, int(z.y) + 1, "st2", P.HEAD)
		_hd = hd
	p["end"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		_hf = ctx.hf
	return p

func poses_c() -> Dictionary:
	var g := c_hooks({"hip": V(0, -34), "top": V(4, -56), "head": V(11, -67), "toef": V(15, -1), "toeb": V(-7, -1),
		"hf": V(20, -53), "hb": V(15, -56), "gkf": "up", "gkb": "up"})
	var an := c_hooks({"hip": V(-2, -35), "top": V(-6, -56), "head": V(-3, -69), "toef": V(15, -1), "toeb": V(-9, -1),
		"hf": V(13, -47), "hb": V(9, -50), "gkf": "diag", "gkb": "diag", "pf": V(0, 1)}, 0.0)
	var hi := c_hooks({"hip": V(4, -30), "top": V(19, -48), "head": V(30, -55), "toef": V(21, -1), "toeb": V(-7, -1),
		"shoeb": "ball", "tw": 1.0, "hf": V(7, -35), "hb": V(1, -38), "gkf": "down", "gkb": "down", "pf": V(-1, 0), "pb": V(-1, 0)}, 0.0)
	return {"guard": g, "antic": an, "hit": hi}

func frames_c() -> Dictionary:
	P.skip_head = true
	var b := build_c()
	var ps := poses_c()
	var out := {}
	for k in ["guard", "antic", "hit"]:
		var im: Image = P.fight_frame(b, ps[k], "C " + k)
		if k == "hit":
			impact(im, _hd + V(16, -1), 7.0)
			# lascas de espuma soltando
			for d in [V(4, -12), V(7, -14), V(10, -11), V(1, -15)]:
				fx(im, int(_hd.x + d.x), int(_hd.y + d.y), "br3")
		if k == "antic":
			for d in [V(-14, -12), V(-12, -14), V(-16, -14)]:
				fx(im, int(_hd.x + d.x), int(_hd.y + d.y), "white")   # gota de suor da fantasia (calor lá dentro)
		out[k] = im
	P.skip_head = false
	return out

# ================================================================================================ beco
func bayer(x: int, y: int) -> float:
	return (float(BAY[y % 4][x % 4]) + 0.5) / 16.0

const BAY := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
const SW := 320
const SH := 180
const FLOOR := 160

func beco(lamp_on: bool) -> Image:
	var im: Image = L.blank(SW, SH)
	var lamp := V(160, 46)
	# céu na fresta entre os prédios
	L.R(im, 0, 0, SW, 16, "b0")
	for st in [V(30, 4), V(88, 9), V(141, 3), V(222, 7), V(287, 5)]:
		fx(im, int(st.x), int(st.y), "cream")
	# parede de tijolo (luz da arandela: br2 perto, br1, br0 longe), argamassa 1 tom abaixo
	for y in range(16, 142):
		for x in range(SW):
			var d := (Vector2(x, y) - lamp)
			d.y *= 1.25
			var lv := (1.0 - d.length() / 130.0) if lamp_on else 0.25 - absf(x - 160.0) / 900.0
			if not lamp_on:
				pass
			var lvl := 0
			if lv > 0.42 + 0.2 * (bayer(x, y) - 0.5):
				lvl = 2
			elif lv > 0.05 + 0.25 * (bayer(x, y) - 0.5):
				lvl = 1
			var row := (y - 16) / 5
			var off := (row % 2) * 6
			var mortar := (y - 16) % 5 == 4 or (x + off) % 12 == 0
			var cols := [["br0", "d1"], ["br1", "br0"], ["br2", "br1"]]
			var c = cols[lvl][1] if mortar else cols[lvl][0]
			if not mortar and lvl == 2 and (y - 16) % 5 == 0 and (x + off) % 12 < 10:
				c = "br3" if lv > 0.7 else "br2"     # borda de cima do tijolo pega luz
			im.set_pixel(x, y, L.col(c))
	# reboco caído (manchas) e pichação genérica
	for sp in [Rect2i(64, 30, 18, 9), Rect2i(250, 52, 22, 12), Rect2i(110, 100, 12, 7)]:
		for y in range(sp.position.y, sp.end.y):
			for x in range(sp.position.x, sp.end.x):
				var e: float = Vector2(x - sp.get_center().x, (y - sp.get_center().y) * 1.6).length() / (sp.size.x * 0.5)
				if e < 1.0 - 0.3 * bayer(x, y):
					im.set_pixel(x, y, L.col("g1" if lamp_on else "g0"))
	L.text(im, "VILA", 220, 74, "r1", 2)
	L.line(im, 216, 90, 262, 86, "r1")
	# porta de ferro (esquerda)
	L.R(im, 18, 78, 34, 64, "st0")
	L.R(im, 20, 80, 30, 62, "st1")
	for k in 5:
		L.R(im, 21, 83 + k * 11, 28, 1, "st0")
		L.R(im, 21, 84 + k * 11, 28, 1, "st2")
	L.R(im, 44, 110, 3, 2, "st3")
	L.R(im, 16, 76, 38, 2, "d1")
	# caixas de papelão e sacos de lixo (esquerda, perto da porta)
	L.R(im, 56, 124, 18, 18, "br2")
	L.R(im, 56, 124, 18, 2, "br3")
	L.R(im, 56, 124, 1, 18, "br1")
	L.R(im, 64, 124, 2, 18, "y0")
	L.R(im, 60, 112, 13, 12, "br3")
	L.R(im, 60, 112, 13, 1, "y0")
	L.R(im, 60, 112, 1, 12, "br2")
	L.ellipse(im, 82, 136, 9, 7, "d2")
	L.ellipse(im, 80, 134, 6, 4, "g0")
	L.P(im, 78, 131, "g1")
	# caçamba (direita)
	L.R(im, 244, 106, 66, 36, "gr0")
	L.R(im, 246, 108, 62, 32, "gr1")
	for k in 4:
		L.R(im, 252 + k * 15, 110, 2, 28, "gr0")
		L.R(im, 254 + k * 15, 110, 1, 28, "gr2")
	L.R(im, 240, 100, 74, 6, "gr0")
	L.R(im, 241, 101, 72, 2, "gr2")
	L.R(im, 241, 103, 72, 1, "gr3" if lamp_on else "gr1")
	L.text(im, "07", 266, 124, "gr0")
	L.ellipse(im, 232, 136, 9, 7, "d2")
	L.ellipse(im, 230, 134, 6, 4, "g0")
	L.ellipse(im, 300, 98, 8, 5, "d2")
	# fios por cima
	for w in [[V(0, 22), V(320, 18), 10.0], [V(0, 30), V(320, 34), 7.0]]:
		var a: Vector2 = w[0]
		var b2: Vector2 = w[1]
		for x in range(SW):
			var t := float(x) / SW
			var y: float = a.y + (b2.y - a.y) * t + w[2] * 4.0 * t * (1.0 - t)
			im.set_pixel(x, int(y), L.col("ink"))
	# arandela
	L.R(im, 156, 34, 9, 3, "st1")
	L.R(im, 159, 30, 3, 5, "st0")
	if lamp_on:
		L.R(im, 157, 37, 7, 3, "y2")
		L.R(im, 158, 40, 5, 1, "y1")
	else:
		L.R(im, 157, 37, 7, 3, "g1")
		L.R(im, 158, 40, 5, 1, "g0")
		for s in [V(166, 39), V(168, 37), V(153, 41)]:
			fx(im, int(s.x), int(s.y), "y2")
	# chão: asfalto molhado
	for y in range(142, SH):
		for x in range(SW):
			var dx := absf(x - 160.0) / 150.0
			var lv := (1.0 - dx) * (1.0 if lamp_on else 0.5) - (y - 142) * 0.004
			var c = "d2"
			if lv > 0.55 + 0.3 * (bayer(x, y) - 0.5):
				c = "g0"
			elif lv < 0.15 + 0.3 * (bayer(x, y) - 0.5):
				c = "d1"
			im.set_pixel(x, y, L.col(c))
	L.R(im, 0, 142, SW, 1, "d1")
	# poças com reflexo
	for pz in [[V(96, 170), 22.0, 4.0], [V(214, 166), 18.0, 3.0], [V(30, 174), 16.0, 3.0]]:
		var c0: Vector2 = pz[0]
		for y in range(int(c0.y - pz[2]), int(c0.y + pz[2]) + 1):
			for x in range(int(c0.x - pz[1]), int(c0.x + pz[1]) + 1):
				var e: float = Vector2((x - c0.x) / pz[1], (y - c0.y) / pz[2]).length()
				if e <= 1.0:
					im.set_pixel(x, y, L.col("b0" if e > 0.7 or (x + y) % 3 else "b1"))
		if lamp_on:
			L.R(im, int(c0.x) - 2, int(c0.y) - 1, 5, 1, "y1")
	# ralo
	L.R(im, 150, 168, 20, 5, "d1")
	for k in 5:
		L.R(im, 151 + k * 4, 169, 2, 3, "g0")
	return im

## Chuva: traços finos inclinados. front = menos e mais claros (passam na frente).
func chuva(im: Image, seed_: int, n: int, c) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	for i in n:
		var x := rng.randi_range(0, SW + 20)
		var y := rng.randi_range(0, FLOOR + 10)
		for k in 3:
			fx(im, x - k / 2, y + k, c)

## Sombra no chão (elipse em dither) sob o pivô.
func sombra(im: Image, cx: int, rx: int) -> void:
	for y in range(FLOOR - 2, FLOOR + 3):
		for x in range(cx - rx, cx + rx + 1):
			var e := Vector2((x - cx) / float(rx), (y - FLOOR) / 2.5).length()
			if e <= 1.0 and (x + y) % 2 == 0:
				im.set_pixel(x, y, L.col("ink"))

func vulto() -> Image:
	var body: Image = P.load_png(R + "assets/sprites/minigame/ronda_vulto_scare_disc_body.png")
	var head: Image = P.load_png(R + "assets/sprites/minigame/ronda_vulto_scare_disc_head_short.png")
	var f := body.get_region(Rect2i(6 * VFW, 0, VFW, 100))
	f.blend_rect(head.get_region(Rect2i(6 * VFW, 0, VFW, 100)), Rect2i(0, 0, VFW, 100), Vector2i.ZERO)
	return f

func flipped(im: Image) -> Image:
	var c: Image = im.duplicate()
	c.flip_x()
	return c

## Luz que clareia tudo que está num cone (lanterna do B): +1 tom na rampa, com dither que some na distância.
func cone_light(im: Image, src: Vector2, dir: Vector2, half_ang: float, reach: float) -> void:
	var dn := dir.normalized()
	for y in range(SH):
		for x in range(SW):
			var d := Vector2(x, y) - src
			var l := d.length()
			if l < 2.0 or l > reach:
				continue
			var a := absf(d.angle_to(dn))
			if a > half_ang:
				continue
			var k := (1.0 - l / reach) * (1.0 - pow(a / half_ang, 2.0)) * 1.4
			if k > bayer(x, y):
				var c := im.get_pixel(x, y)
				im.set_pixel(x, y, L.shade(c, 2 if k > 1.0 + bayer(x, y) * 0.6 else 1))

func cena(vil: Image, kind: String, lamp = null) -> Image:
	var im := beco(kind != "B")
	chuva(im, 7, 140, "st1")
	var vx := 128
	var ox := 190
	sombra(im, vx, 13)
	sombra(im, ox, 16)
	im.blend_rect(vulto(), Rect2i(0, 0, VFW, 100), Vector2i(vx - VPIV.x, FLOOR - VPIV.y))
	var fl := flipped(vil)
	im.blend_rect(fl, Rect2i(0, 0, FW, FH), Vector2i(ox - PIV_FLIPX, FLOOR - int(PIV.y)))
	if lamp != null:
		var lp: Vector2 = lamp
		var src := V(ox - PIV_FLIPX + (FW - 1 - lp.x), FLOOR - PIV.y + lp.y)
		cone_light(im, src, V(-1, 0.32), 0.3, 150.0)
		spark(im, src, 1)
	chuva(im, 99, 30, "st2")
	return im

# ================================================================================================ pranchas
func scaled(im: Image, k: int) -> Image:
	return P.scaled(im, k)

func painel(w: int, h: int) -> Image:
	var im: Image = L.blank(w, h)
	im.fill(L.col("b0"))
	return im

## Quadro sobre fundo noturno liso, com linha do chão; k = ampliação; corta 4 px no topo.
func cartao(fr: Image, k: int, flip := true) -> Image:
	var bg := painel(FW, FH - 2)
	L.R(bg, 0, int(PIV.y) + 1, FW, FH, "d1")
	var f := flipped(fr) if flip else fr
	bg.blend_rect(f, Rect2i(0, 2, FW, FH - 2), Vector2i(0, 0))
	return scaled(bg, k)

func titulo(im: Image, s: String, x: int, y: int, k := 2, c = "y1") -> void:
	L.text(im, s, x, y, c, k, "ink")

const INFO := {
	"A": {"nome": "A - REI CALOTA", "tag": "nome provisório: o Roteirista dá o final",
		"linhas": ["O REI DO FERRO-VELHO. JURA QUE É ROBÔ: CAPACETE DE CALOTA COM COROA DE PORCAS,",
			"OLHO DE OLHO-DE-GATO, PEITO E OMBROS DE CALOTA, CÂMARA DE PNEU NA CINTURA.",
			"LUTA: LENTO E PESADO, FECHA A GUARDA ATRÁS DA CALOTA E ARREMESSA OUTRA DE LONGE.",
			"PASSIVA: adv_blindado (a do JAMES): GUARDA FECHADA NO 1º ROUND, DANO NELE x0,6.",
			"TROFÉU NATURAL: O CAPACETE DE CALOTA AMASSADO."],
		"golpe": "ARREMESSO DE CALOTA"},
	"B": {"nome": "B - APAGÃO", "tag": "nome provisório: o Roteirista dá o final",
		"linhas": ["O ELETRICISTA QUE APAGA A LUZ DO BAIRRO: CAPACETE DE OBRA COM LANTERNA, MACACÃO",
			"COM FAIXA REFLETIVA, BATERIA DE CARRO NAS COSTAS E CABOS ATÉ AS LUVAS DE BORRACHA.",
			"LUTA: COMPRIDO E NERVOSO, APAGA O POSTE, CEGA COM A LANTERNA E DÁ CHOQUE NO SOCO.",
			"PASSIVA: adv_slippery (a do RONY SABÃO): QUEM AGARRA LEVA CHOQUE E SOLTA O CLINCHE.",
			"TROFÉU NATURAL: O CAPACETE COM A LANTERNA QUEBRADA."],
		"golpe": "CHOQUE"},
	"C": {"nome": "C - CAPIVARÃO", "tag": "nome provisório: o Roteirista dá o final",
		"linhas": ["EX-MASCOTE DO BREJO F.C. (TIME DE VÁRZEA INVENTADO), PRESO NA FANTASIA GIGANTE:",
			"CABEÇA DE ESPUMA REMENDADA, CAMISA DO TIME, PATAS COM FITA. PELA BOCA DE TELA APARECE",
			"O OLHO DE VERDADE DE QUEM ESTÁ LÁ DENTRO. LUTA: TORTO, EMPURRA E DÁ CABEÇADA.",
			"PASSIVA: adv_iron_chin (a do ZÉ BIGORNA): SOCO NA CARA BATE NA ESPUMA, SEGURA O NOCAUTE.",
			"TROFÉU NATURAL: A CABEÇA DA CAPIVARA (OU SÓ O OLHO DE BOTÃO, NA RARA)."],
		"golpe": "CABEÇADA DE ESPUMA"},
}

func prancha_vilao(id: String, fr: Dictionary, cena_img: Image) -> Image:
	var inf: Dictionary = INFO[id]
	var W := 1340
	var H := 1300
	var im: Image = L.blank(W, H)
	im.fill(L.col("d1"))
	titulo(im, inf.nome, 16, 12, 3)
	L.text(im, "(" + String(inf.tag) + ")", 16 + L.text_w(inf.nome, 3) + 16, 22, "g3", 2)
	L.text(im, "MOCKUP RONDA 2A - QUADRO DE LUTA 112x104, PIVÔ (56,98), VIRADO PARA A ESQUERDA COMO OS ADVERSÁRIOS. NÃO É A FOLHA FINAL.", 16, 44, "g2", 1)
	# linha 1: guarda 1x | guarda 3x | antecipação 3x | golpe 3x | 1x dos 3
	var y := 64
	titulo(im, "GUARDA 1X", 16, y)
	titulo(im, "GUARDA 3X", 150, y)
	titulo(im, "ANTECIPAÇÃO 3X", 150 + 340, y)
	titulo(im, String(inf.golpe) + " 3X", 150 + 680, y)
	y += 22
	im.blend_rect(cartao(fr.guard, 1), Rect2i(0, 0, FW, FH - 2), Vector2i(16, y))
	var x := 150
	for k in ["guard", "antic", "hit"]:
		var c := cartao(fr[k], 3)
		im.blend_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, y))
		x += 340
	# 1x de antecipação e golpe embaixo do 1x da guarda
	im.blend_rect(cartao(fr.antic, 1), Rect2i(0, 0, FW, FH - 2), Vector2i(16, y + 108))
	im.blend_rect(cartao(fr.hit, 1), Rect2i(0, 0, FW, FH - 2), Vector2i(16, y + 216))
	y += 3 * (FH - 2) + 18
	for ln in inf.linhas:
		L.text(im, ln, 16, y, "cream", 2, "ink")
		y += 20
	y += 10
	titulo(im, "FRENTE A FRENTE COM O VULTO NO BECO - 2X (E 1X À DIREITA)", 16, y)
	y += 22
	var c2 := scaled(cena_img, 2)
	im.blend_rect(c2, Rect2i(Vector2i.ZERO, c2.get_size()), Vector2i(16, y))
	im.blend_rect(cena_img, Rect2i(Vector2i.ZERO, cena_img.get_size()), Vector2i(16 + 640 + 20, y))
	var used := y + 360 + 16
	return im.get_region(Rect2i(0, 0, W, mini(used, H)))

func comparativo(all_fr: Dictionary, cenas: Dictionary) -> Image:
	var colw := 660
	var W := 16 + colw * 3 + 16
	var H := 2000
	var im: Image = L.blank(W, H)
	im.fill(L.col("d1"))
	titulo(im, "RONDA 2A - CANDIDATOS A SUPERVILÃO (MOCKUP PARA O DONO ESCOLHER)", 16, 12, 3)
	L.text(im, "NOMES PROVISÓRIOS. MESMO RIG E PALETA DOS ADVERSÁRIOS DA LIGA. O VULTO (QUADRO DO SUSTO) E O JAMES ENTRAM SÓ PARA A ESCALA.", 16, 44, "g2", 1)
	# escalação 3x: vulto, James, A, B, C
	var y := 62
	titulo(im, "ESCALA EM 3X: VULTO | JAMES (LIGA, 1,12) | A | B | C", 16, y)
	y += 22
	var strip_h := 300
	var bgw := W - 32
	var lineup := painel(bgw / 3, strip_h / 3)
	L.R(lineup, 0, strip_h / 3 - 6, bgw / 3, 6, "d1")
	var gy := strip_h / 3 - 6
	var v := vulto()
	lineup.blend_rect(v, Rect2i(0, 0, VFW, 100), Vector2i(20 + 30 - VPIV.x, gy - VPIV.y))
	var jam: Image = P.load_png(R + "assets/sprites/opponents/opp_james/opp_james_idle.png").get_region(Rect2i(0, 0, FW, FH))
	var px := [150, 260, 370, 490]
	lineup.blend_rect(jam, Rect2i(0, 0, FW, FH), Vector2i(px[0] - PIV_FLIPX, gy - int(PIV.y)))
	var ids := ["A", "B", "C"]
	for i in 3:
		var f := flipped(all_fr[ids[i]].guard)
		lineup.blend_rect(f, Rect2i(0, 0, FW, FH), Vector2i(px[i + 1] - PIV_FLIPX, gy - int(PIV.y)))
	var l3 := scaled(lineup, 3)
	im.blend_rect(l3, Rect2i(Vector2i.ZERO, l3.get_size()), Vector2i(16, y))
	for i in 5:
		var lab: String = ["VULTO", "JAMES", "A", "B", "C"][i]
		var cx: int = [50, 150, 260, 370, 490][i] * 3
		L.text_center(im, lab, 16 + cx, y + strip_h - 14, "white", 2, "ink")
	# 1x da escalação ao lado
	im.blend_rect(lineup, Rect2i(Vector2i.ZERO, lineup.get_size()), Vector2i(16 + l3.get_width() + 20, y))
	L.text(im, "1X", 16 + l3.get_width() + 20, y + lineup.get_height() + 6, "g3", 2)
	y += strip_h + 20
	# colunas
	for i in 3:
		var id: String = ids[i]
		var inf: Dictionary = INFO[id]
		var x0 := 16 + i * colw
		var yy := y
		titulo(im, inf.nome, x0, yy, 3)
		yy += 30
		var fr: Dictionary = all_fr[id]
		var g := cartao(fr.guard, 3)
		var h := cartao(fr.hit, 3)
		var gr := g.get_region(Rect2i(36, 0, 270, g.get_height()))
		var hr := h.get_region(Rect2i(0, 0, 330, h.get_height()))
		im.blend_rect(gr, Rect2i(Vector2i.ZERO, gr.get_size()), Vector2i(x0, yy))
		im.blend_rect(hr, Rect2i(Vector2i.ZERO, hr.get_size()), Vector2i(x0 + 276, yy))
		L.text(im, "GUARDA", x0 + 4, yy + 4, "g3", 2)
		L.text(im, String(inf.golpe), x0 + 280, yy + 4, "g3", 2)
		yy += g.get_height() + 10
		var c2 := scaled(cenas[id], 2)
		im.blend_rect(c2, Rect2i(Vector2i.ZERO, c2.get_size()), Vector2i(x0, yy))
		yy += 370
		for ln in inf.linhas:
			L.text(im, ln, x0, yy, "cream", 1, "ink")
			yy += 12
		H = yy + 20
	return im.get_region(Rect2i(0, 0, W, mini(H, 2000)))

# ================================================================================================ B v2: APAGÃO (guardado para capítulo futuro)
## Mais exagero de supervilão, mesmo acabamento:
##  - silhueta: bateria de carro GRANDE nas costas com 2 cabos em espiral subindo como antenas (coroa de cabos com garras
##    de jacaré na ponta), capacete com lanterna enorme, braços MUITO compridos terminando em luvas de borracha gigantes
##    (desenhadas aqui: punho + cano largo, girando com o antebraço), corpo corcunda e magro, cabeça projetada para a frente;
##  - eletricidade como assinatura: faíscas entre as luvas na guarda, o cabo vermelho fica incandescente no ataque;
##  - pose nova "apagão": puxa a alavanca que sai da bateria; o beco escurece e só a lanterna e as faíscas ficam acesas.
var _lamp := Vector2.ZERO
var _piv := Vector2.ZERO

func build_b2() -> Dictionary:
	var s := 1.1
	var am := 1.3
	var o := {"lu": 12.0 * s * am, "lf": 13.0 * s * am, "lt": 17.5 * s, "ls": 16.5 * s,
		"skin": ["sk1", "sk2", "y2"], "brow": "br0",
		"top": "tshirt", "sleeve_long": true, "shirt": ["st0", "st1", "st2"], "trim": "st0",
		"bottom": "pants", "shorts": ["st0", "st1", "st2"], "band": "st0", "pants_add": 0.6,
		"shoes": ["d1", "d2", "g0", "y0", "ink"], "shoe_maps": shoes_of(BOTA_FLAT, BOTA_BALL, Vector2i(10, 7), Vector2i(3, 3), Vector2i(10, 6), Vector2i(2, 1)),
		"glove": "none", "glove_ramp": ["y0", "y1", "y2"],
		"shoulder": 0.85, "hip_w": 0.76, "belly": 0.0, "arm_r": [2.6, 1.9, 2.1, 1.5], "leg_r": [3.4, 2.5, 2.3, 1.5]}
	o.merge(head_b_build(), true)
	return P.build(o)

## Luva de borracha gigante: cano largo (y0) + mão fechada (y1/y2) + polegar, orientados pelo antebraço.
func big_glove(id: int, el: Vector2, hand: Vector2, far: bool) -> void:
	var d := (hand - el).normalized()
	var n := Vector2(-d.y, d.x)
	if n.y > 0.0:
		n = -n
	var ang := rad_to_deg(atan2(d.y, d.x))
	var rp := ["y0", "y1", "y2", "white"] if not far else ["br3", "y0", "y1"]
	blob(id, hand - d * 5.0, 3.4, 4.4, ["br3", "y0", "y0"] if not far else ["br2", "br3", "br3"], ang)
	blob(id + 1, hand + d * 1.0, 5.6, 5.0, rp, ang)
	blob(id + 1, hand + d * 0.5 + n * 4.2, 2.4, 1.7, rp, ang)
	# friso do cano (onde a borracha dobra)
	var c := hand - d * 2.2
	for k in range(-4, 5):
		var q := c + n * k * 0.9
		P.put(int(q.x), int(q.y), "br3" if not far else "br2", id + 1)

## Cabo em espiral subindo da bateria (antena), com garra de jacaré na ponta.
func coil(id: int, base: Vector2, up: Vector2, h: float, col: String, clip_c: String) -> void:
	var side := Vector2(-up.y, up.x)
	var steps := int(h * 3.0)
	for i in steps + 1:
		var t := float(i) / steps
		var p := base + up * (t * h) + side * (2.0 * sin(t * h * 1.15))
		P.put(int(p.x), int(p.y), col, id)
	var tip := base + up * (h + 1.0) + side * (2.0 * sin(h * 1.15))
	for d in [V(0, 0), V(1, 0), V(-1, 0), V(0, -1), V(1, -1), V(-1, -2), V(1, -2)]:
		P.put(int(tip.x + d.x), int(tip.y + d.y), clip_c, id)
	P.put(int(tip.x), int(tip.y) - 1, "st3", id)

func b2_hooks(p: Dictionary, mode: String) -> Dictionary:
	p["before_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hip: Vector2 = ctx.hip
		var top: Vector2 = ctx.top
		var dn: Vector2 = ctx.dn
		var fr: Vector2 = ctx.fr
		var ln := (top - hip).length()
		var ang := rad_to_deg(atan2(dn.x, -dn.y))
		# luva de trás (o rig não desenha: glove none)
		pass
		# bateria grande nas costas: caixa escura, faixa amarela, tampa cinza, polos
		var bc := hip + dn * ln * 0.7 - fr * 10.0
		box(26, bc, 12.0, 17.0, ang, ["d1", "d2", "g0"])
		var band := bc - dn * 1.0
		box(26, band, 12.0, 2.0, ang, ["y0", "y0", "y1"])
		var tp := bc + dn * 9.0
		box(27, tp, 12.0, 2.0, ang, ["g0", "g1", "g2"])
		var pr := tp + dn * 1.5 + fr * 3.0
		var pn := tp + dn * 1.5 - fr * 3.5
		_bat = (pr + pn) * 0.5
		_piv = tp + dn * 1.0 + fr * 0.5
		# a coroa de cabos: espirais subindo e abrindo para trás
		var hot := mode == "hit" or mode == "blackout"
		coil(25, pr, (dn * 1.0 - fr * 0.25).normalized(), 13.0, "y2" if hot else "r1", "r2")
		coil(25, pn, (dn * 1.0 - fr * 0.7).normalized(), 11.0, "y1" if hot else "d1", "g1")
		# cabo PRETO até a luva de trás
		wire(24, pn + Vector2(0, 1), ctx.hb + (ctx.elb - ctx.hb).normalized() * 6.0, 8.0, "d1")
		if mode == "blackout":
			# alavanca saindo da bateria até a mão de TRÁS (que alcança por cima do ombro), punho de borracha vermelho
			wire(27, _piv, ctx.hb, 0.0, "st2", "st1")
		big_glove(28, ctx.elb, ctx.hb, true)
		if mode == "blackout":
			blob(29,ctx.hb + (ctx.hb - _piv).normalized() * 6.0, 2.4, 2.4, ["r1", "r2", "r3"])
	p["after_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hip: Vector2 = ctx.hip
		var top: Vector2 = ctx.top
		var dn: Vector2 = ctx.dn
		var fr: Vector2 = ctx.fr
		var ln := (top - hip).length()
		over_id(30, Rect2i(0, 0, FW, FH), func(x: int, y: int):
			var t := (Vector2(x + 0.5, y + 0.5) - hip).dot(dn) / ln
			if absf(t - 0.62) < 0.035 or absf(t - 0.34) < 0.035:
				return "y1"
			return null)
		wire(31, top - fr * 2.0 - dn * 2.0, hip + dn * ln * 0.45 + fr * 3.0, 0.0, "d1")
		# lanterna ENORME no capacete (aro cinza, lente acesa)
		var hd: Vector2 = ctx.hd
		_lamp = hd + V(9, -6)
		blob(42, _lamp, 3.4, 3.6, ["g0", "g1", "g2"])
		blob(43, _lamp + V(0.6, 0), 2.0, 2.6, ["y1", "y2", "white"])
		_hd = hd
	p["end"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		_hf = ctx.hf
		_hb = ctx.hb
		_elf = ctx.elf
		var a: Vector2 = ctx.top - ctx.fr * 6.0 - ctx.dn * 2.0
		var b: Vector2 = ctx.hf + (ctx.elf - ctx.hf).normalized() * 6.0
		# cabo VERMELHO até a luva da frente; no ataque ele fica incandescente
		if mode == "hit" or mode == "blackout":
			wire(59, a, b, 8.0, "white", "y2")
		else:
			wire(59, a, b, 10.0, "r1")
		big_glove(64, ctx.elf, ctx.hf, false)
	return p

func poses_b2() -> Dictionary:
	var g := b2_hooks({"hip": V(0, -40), "top": V(8, -62), "head": V(17, -69), "toef": V(18, -1), "toeb": V(-8, -1),
		"sf": V(9, -60), "sb": V(4, -61),
		"hf": V(31, -48), "hb": V(24, -53), "pf": V(0.2, 1.0), "pb": V(0.2, 1.0)}, "guard")
	var hi := b2_hooks({"hip": V(3, -40), "top": V(13, -61), "head": V(22, -68), "toef": V(22, -1), "toeb": V(-6, -1),
		"shoeb": "ball", "tw": 1.6, "sf": V(14, -59), "sb": V(9, -60), "hf": V(46, -61), "hb": V(1, -50)}, "hit")
	var bo := b2_hooks({"hip": V(-1, -39), "top": V(4, -62), "head": V(12, -71), "toef": V(17, -1), "toeb": V(-8, -1),
		"sf": V(5, -60), "sb": V(0, -61), "hf": V(26, -55), "hb": V(-7, -82), "pf": V(0.2, 1.0), "pb": V(-1.0, 0.0)}, "blackout")
	return {"guard": g, "hit": hi, "blackout": bo}

func frames_b2() -> Dictionary:
	var b := build_b2()
	var ps := poses_b2()
	var out := {}
	for k in ["guard", "hit", "blackout"]:
		var base: Image = P.fight_frame(b, ps[k], "B2 " + k)
		var fxi: Image = L.blank(FW, FH)
		bolt(fxi, _bat + V(-3, -1), _bat + V(3, -5), 40 + k.length(), 2, 1.0)
		match k:
			"guard":
				bolt(fxi, _hb + V(3, 1), _hf + V(-3, -1), 11, 3, 2.0)
				bolt(fxi, _hb + V(2, 4), _hf + V(-3, 3), 12, 3, 2.0)
				spark(fxi, (_hb + _hf) * 0.5 + V(0, -5), 1)
			"hit":
				bolt(fxi, _hf + V(5, -1), _hf + V(18, -5), 31, 4, 3.0)
				bolt(fxi, _hf + V(5, 1), _hf + V(17, 6), 32, 4, 3.0)
				bolt(fxi, _hf + V(3, -4), _hf + V(10, -14), 33, 3, 2.0)
				spark(fxi, _hf + V(7, 0), 3, true)
				spark(fxi, _lamp + V(1, 0), 2, true)
			"blackout":
				spark(fxi, _piv, 2, true)
				bolt(fxi, _piv + V(-1, -1), _piv + V(-7, -6), 51, 3, 1.5)
				bolt(fxi, _hf + V(3, -4), _hf + V(9, -12), 52, 3, 2.0)
				bolt(fxi, _hf + V(5, 2), _hf + V(13, 6), 53, 3, 2.0)
				spark(fxi, _lamp + V(1, 0), 2, true)
		var im: Image = base.duplicate()
		im.blend_rect(fxi, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
		out[k] = im
		out[k + "_base"] = base
		out[k + "_fx"] = fxi
		out[k + "_lamp"] = _lamp
	return out

## Cartão escuro (apagão): o quadro todo 2 tons abaixo, só a lanterna e as faíscas acesas.
func cartao_apagao(fr: Dictionary, k: int) -> Image:
	var bg := painel(FW, FH - 2)
	L.R(bg, 0, int(PIV.y) + 1, FW, FH, "d1")
	var f := flipped(fr.blackout_base)
	bg.blend_rect(f, Rect2i(0, 2, FW, FH - 2), Vector2i.ZERO)
	_darken(bg, 2)
	var fx2 := flipped(fr.blackout_fx)
	bg.blend_rect(fx2, Rect2i(0, 2, FW, FH - 2), Vector2i.ZERO)
	return scaled(bg, k)

func _darken(im: Image, n: int) -> void:
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a > 0.0:
				im.set_pixel(x, y, L.shade(c, -n))

## Beco no apagão: tudo 2 tons abaixo (personagens também), o facho da lanterna devolve a luz, faíscas por cima.
func cena_apagao(fr: Dictionary) -> Image:
	var im := beco(false)
	chuva(im, 7, 140, "st1")
	var vx := 128
	var ox := 190
	sombra(im, vx, 13)
	sombra(im, ox, 16)
	im.blend_rect(vulto(), Rect2i(0, 0, VFW, 100), Vector2i(vx - VPIV.x, FLOOR - VPIV.y))
	var org := Vector2i(ox - PIV_FLIPX, FLOOR - int(PIV.y))
	im.blend_rect(flipped(fr.blackout_base), Rect2i(0, 0, FW, FH), org)
	_darken(im, 2)
	var lp: Vector2 = fr.blackout_lamp
	var src := V(org.x + (FW - 1 - lp.x), org.y + lp.y)
	cone_light(im, src, V(-1, 0.35), 0.32, 170.0)
	cone_light(im, src, V(-1, 0.35), 0.16, 120.0)
	im.blend_rect(flipped(fr.blackout_fx), Rect2i(0, 0, FW, FH), org)
	chuva(im, 99, 30, "d2")
	return im

func prancha_b2(v1: Dictionary, v2: Dictionary) -> Image:
	var W := 1420
	var im: Image = L.blank(W, 2400)
	im.fill(L.col("d1"))
	titulo(im, "B - APAGÃO V2 (GUARDADO PARA UM CAPÍTULO FUTURO)", 16, 12, 3)
	L.text(im, "MOCKUP. MESMO RIG, PALETA E QUADRO DE LUTA (112x104, PIVÔ 56,98, VIRADO PARA A ESQUERDA). NÃO É A FOLHA FINAL. NOME PROVISÓRIO.", 16, 44, "g2", 1)
	var y := 62
	titulo(im, "1. ANTES (V1) X DEPOIS (V2) - GUARDA 3X E 1X", 16, y)
	y += 24
	var a3 := cartao(v1.guard, 3)
	var b3 := cartao(v2.guard, 3)
	im.blend_rect(a3, Rect2i(Vector2i.ZERO, a3.get_size()), Vector2i(16, y))
	im.blend_rect(b3, Rect2i(Vector2i.ZERO, b3.get_size()), Vector2i(16 + 346, y))
	L.text(im, "ANTES", 22, y + 6, "g3", 2, "ink")
	L.text(im, "DEPOIS", 22 + 346, y + 6, "y1", 2, "ink")
	var a1 := cartao(v1.guard, 1)
	var b1 := cartao(v2.guard, 1)
	im.blend_rect(a1, Rect2i(Vector2i.ZERO, a1.get_size()), Vector2i(16 + 700, y))
	im.blend_rect(b1, Rect2i(Vector2i.ZERO, b1.get_size()), Vector2i(16 + 700 + 120, y))
	var ly := y + 116
	for ln in ["V2: BATERIA GRANDE COM A COROA DE CABOS EM ESPIRAL (GARRAS DE JACARÉ NA PONTA),",
			"LANTERNA ENORME NO CAPACETE, BRAÇOS 16% MAIS COMPRIDOS, LUVAS DE BORRACHA GIGANTES",
			"COM CANO, CORPO CORCUNDA E MAGRO, CABEÇA PROJETADA PARA A FRENTE, GUARDA BAIXA E",
			"ABERTA COM FAÍSCA ENTRE AS LUVAS. NO CHOQUE O CABO VERMELHO FICA INCANDESCENTE."]:
		L.text(im, ln, 16 + 700, ly, "cream", 1, "ink")
		ly += 12
	y += a3.get_height() + 20
	titulo(im, "2. V2 - GUARDA / CHOQUE / APAGÃO (3X E 1X)", 16, y)
	y += 24
	var x := 16
	for k in ["guard", "hit", "blackout"]:
		var c := cartao_apagao(v2, 3) if k == "blackout" else cartao(v2[k], 3)
		im.blend_rect(c, Rect2i(Vector2i.ZERO, c.get_size()), Vector2i(x, y))
		var c1 := cartao_apagao(v2, 1) if k == "blackout" else cartao(v2[k], 1)
		im.blend_rect(c1, Rect2i(Vector2i.ZERO, c1.get_size()), Vector2i(x + 4, y + c.get_height() + 6))
		x += 346
	var ty := y + 10
	for ln in ["APAGÃO: ELE PUXA A ALAVANCA", "QUE SAI DA BATERIA. O BECO", "ESCURECE E SÓ A LANTERNA E", "AS FAÍSCAS FICAM ACESAS."]:
		L.text(im, ln, 16 + 1050, ty, "cream", 1, "ink")
		ty += 12
	y += (FH - 2) * 3 + FH + 16
	titulo(im, "3. FRENTE A FRENTE COM O VULTO NO BECO - V2 EM 2X (GUARDA E APAGÃO); ANTES EM 1X", 16, y)
	y += 24
	var sg := cena(v2.guard, "B", v2.guard_lamp)
	var sa := cena_apagao(v2)
	var s1 := cena(v1.guard, "B", v1.guard_lamp)
	var g2 := scaled(sg, 2)
	var a2 := scaled(sa, 2)
	im.blend_rect(g2, Rect2i(Vector2i.ZERO, g2.get_size()), Vector2i(16, y))
	im.blend_rect(a2, Rect2i(Vector2i.ZERO, a2.get_size()), Vector2i(16 + 660, y))
	L.text(im, "GUARDA", 22, y + 22, "white", 2, "ink")
	L.text(im, "APAGÃO", 22 + 660, y + 22, "white", 2, "ink")
	y += 372
	im.blend_rect(s1, Rect2i(Vector2i.ZERO, s1.get_size()), Vector2i(16, y))
	im.blend_rect(sg, Rect2i(Vector2i.ZERO, sg.get_size()), Vector2i(16 + 330, y))
	im.blend_rect(sa, Rect2i(Vector2i.ZERO, sa.get_size()), Vector2i(16 + 660, y))
	L.text(im, "ANTES 1X", 22, y + 22, "g3", 2, "ink")
	L.text(im, "DEPOIS 1X", 22 + 330, y + 22, "y1", 2, "ink")
	L.text(im, "APAGÃO 1X", 22 + 660, y + 22, "y1", 2, "ink")
	y += 192
	var lines := ["PASSIVA (SE ELE VOLTAR): adv_slippery (a do RONY SABÃO): QUEM AGARRA LEVA CHOQUE E SOLTA O CLINCHE.",
		"LUTA: COMPRIDO E NERVOSO, GUARDA BAIXA COM OS BRAÇOS LONGOS, CHOQUE DE LONGE E O APAGÃO COMO ENTRADA/ESPECIAL."]
	for ln in lines:
		L.text(im, ln, 16, y, "cream", 2, "ink")
		y += 20
	return im.get_region(Rect2i(0, 0, W, y + 12))

# ================================================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	R = args[0].replace("\\", "/").trim_suffix("/") + "/"
	var out_dir: String = args[1].replace("\\", "/").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(out_dir)
	L = load(R + "tools/art/pixel_lib.gd").new()
	P = load(R + "tools/art/personagem_lib.gd").new(L)
	var v1 := frames_b()
	var v2 := frames_b2()
	prancha_b2(v1, v2).save_png(out_dir + "ronda2a_apagao_v2.png")
	for k in ["guard", "hit", "blackout"]:
		scaled(cartao(v2[k], 1, false), 5).save_png(out_dir + "b2_%s.png" % k)
	for l in P.log_lines:
		if String(l).begins_with("AVISO"):
			print(l)
	print("ok ", out_dir)
	quit()
