extends SceneTree
## Ronda 2a2 (Artista de Personagens): AMOSTRA de arte do chefe APAGÃO (Nélson Volt) e da arena dele, para o dono aprovar
## antes do elenco completo. Parte do Apagão v2 aprovado (make_mockup_ronda2a_apagao_v2.gd, que fica como está): o corpo, a
## cabeça, a bateria com a coroa de cabos e as luvas de borracha foram copiados de lá e ganharam as poses que faltavam.
##
## Entrega (tudo na paleta de 45, skill padrao-personagem):
##  1. o Apagão no rig dos adversários (112x104, pivô 56,98, virado para a ESQUERDA, como as folhas da liga): guarda, jab,
##     choque (golpe forte), leva, passiva (adv_slippery: solta o clinche com faísca), apagão (puxa a alavanca), K.O. sem
##     sangue (o capacete sai rolando) e atordoado; retrato 32x32 (virado para a direita, como os outros) e a silhueta;
##  2. a arena do chefe (640x360, contrato das arenas): o beco com o poste, o transformador, a fiação e a caixa de luz;
##     versão normal e versão APAGÃO (tudo 2 passos abaixo, só a lanterna, as faíscas e a caixa acesas);
##  3. o troféu do Esconderijo (capacete com a lanterna quebrada), normal e raro (polido, lanterna ainda piscando: 2 quadros);
##  4. o cartaz do canto livre da parede do menu, "O VULTO QUE RELIGOU A LUZ", com a luz do menu já pintada;
##  5. o estilo raro "fio desencapado" (só cor: faixa amarela com a sombra preta da borracha);
##  e a prancha docs/arte/mockups/ronda2a2_amostra.png.
##
## Rodar headless de uma pasta temporária com project.godot vazio, APPDATA temporário, um Godot por vez:
##   godot --headless --max-fps 30 --path <tmp> --script <repo>/tools/art/make_amostra_ronda2a2_apagao.gd -- <repo> <saida>
## Grava em <saida>: ronda2a2_amostra.png (copiar para docs/arte/mockups/) e pecas/*.png (as peças em 1x, tamanho final).
## Só LÊ do repo (manifest, folhas do vulto e do discípulo, beco, parede do menu). Nada é gravado em assets/.

const FW := 112
const FH := 104
const PIV := Vector2(56, 98)
const DRAW_PIV := Vector2(55, 98)   # desenha virado para a direita com o pivô em 55: depois do espelho ele cai em 56
const AW := 640
const AH := 360
const OPP_X := 346
const VUL_X := 296
const FEET := 318

var L
var P
var R := ""
var OUT := ""
var M: Dictionary
var PAL: Dictionary
var report: Array = []

var _hd := Vector2.ZERO
var _hf := Vector2.ZERO
var _hb := Vector2.ZERO
var _elf := Vector2.ZERO
var _bat := Vector2.ZERO
var _lamp := Vector2.ZERO
var _piv := Vector2.ZERO
var _hip := Vector2.ZERO
var _top := Vector2.ZERO
var _helmet := Vector2.ZERO

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================================================ dados (do v2)
const BOTA_FLAT := ["..DMw......", ".DMMw......", ".DMMw......", ".DMMwL.....", ".DMMMwL....", "DMMMMMMLL..", "DMMMMMMMMMD", "ccccccccccc"]
const BOTA_BALL := [".DMw.......", ".DMMw......", ".DMMwL.....", "..DMMwL....", "..DDMMMML..", "....DMMMMMD", ".....cccccc"]

func shoes_of(flat: Array, ball: Array, tf: Vector2i, af: Vector2i, tb: Vector2i, ab: Vector2i) -> Dictionary:
	return {"flat": {"rows": flat, "toe": tf, "ankle": af, "ang": 0.0},
		"ball": {"rows": ball, "toe": tb, "ankle": ab, "ang": 0.0},
		"up": {"rows": flat, "toe": tf, "ankle": af, "ang": -90.0}}

## Cabeça do Apagão (v2): capacete amarelo de obra com aba comprida, óculos de proteção (Q/q/i), rosto chupado, nariz
## comprido, sorriso de dentes (T) e bigodinho. Âncora (8,9).
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
## Sem o capacete (K.O.): cabelo arrepiado do choque (z = br1, mecha clara).
const HAIR_KO := [
	"....H..H.H..H.....",
	"...H.HH.HzH.H.....",
	"....HHHHHHHHH.....",
	"...HHzHHHzHHHH....",
	"..HHHHHHHHHHHHH...",
	"..HHHHHHHHsssss...",
]
## Expressões (linhas trocadas do HEAD_B). Olho em x de 3x3 no K.O., óculos tortos no atordoado, boca aberta na dor.
const FACES := {
	"normal": {},
	"pain": {7: "..HHEQQQQQiqiQL...", 11: "...HSsssssssxxs...", 12: "....Ssssssxssxs...", 13: "....SSsssssxxS...."},
	"ko": {6: "..HHHHsssssssss...", 7: "..HHEssssxsxsll...", 8: "..HHEsEsssxssll...", 9: "..HHEEsssxsxssl...",
		11: "...HSsssssssssss..", 12: "....Ssssssxxxxs...", 13: "....SSsssssssS...."},
	"daze": {7: "..HHEQQQqiQqqQL...", 11: "...HSsssssssssss..", 12: "....SsssssxsxsT...", 13: "....SSssssssxS...."},
}

func head_rows_for(face: String, helmet: bool) -> Array:
	var rows: Array = HEAD_B.duplicate()
	if not helmet:
		for i in HAIR_KO.size():
			rows[i] = HAIR_KO[i]
	var ov: Dictionary = FACES.get(face, {})
	for k in ov:
		rows[int(k)] = ov[k]
	return rows

const HEAD_EXTRA := {"J": "y0", "j": "y1", "i": "y2", "G": "g1", "O": "white", "o": "y2", "q": "d1", "Q": "g0",
	"T": "white", "U": "br0", "L": "sk1", "H": "br0", "z": "br1"}

## faces_side vira as expressões; o rig troca as linhas pela chave "face" da pose.
func build_apagao(helmet := true) -> Dictionary:
	var s := 1.1
	var am := 1.3
	var faces := {}
	for f in FACES:
		var rows := head_rows_for(f, helmet)
		var ov := {}
		for i in rows.size():
			ov[i] = rows[i]
		faces[f] = ov
	var o := {"lu": 12.0 * s * am, "lf": 13.0 * s * am, "lt": 17.5 * s, "ls": 16.5 * s,
		"skin": ["sk1", "sk2", "y2"], "brow": "br0",
		"top": "tshirt", "sleeve_long": true, "shirt": ["st0", "st1", "st2"], "trim": "st0",
		"bottom": "pants", "shorts": ["st0", "st1", "st2"], "band": "st0", "pants_add": 0.6,
		"shoes": ["d1", "d2", "g0", "y0", "ink"], "shoe_maps": shoes_of(BOTA_FLAT, BOTA_BALL, Vector2i(10, 7), Vector2i(3, 3), Vector2i(10, 6), Vector2i(2, 1)),
		"glove": "none", "glove_ramp": ["y0", "y1", "y2"],
		"shoulder": 0.85, "hip_w": 0.76, "belly": 0.0, "arm_r": [2.6, 1.9, 2.1, 1.5], "leg_r": [3.4, 2.5, 2.3, 1.5],
		"head_side": head_rows_for("normal", helmet), "head_anchor_side": Vector2i(8, 9), "faces_side": faces,
		"head_legend_extra": HEAD_EXTRA}
	return P.build(o)

# ================================================================================================ primitivas (do v2)
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

func over_id(id: int, rect: Rect2i, fn: Callable) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if x < 0 or y < 0 or x >= P.cw or y >= P.ch or P.ids[y * P.cw + x] != id:
				continue
			var c = fn.call(x, y)
			if c != null:
				P.put(x, y, c, id)

func fx(img: Image, x: int, y: int, c) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, L.col(c))

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

## Fumaça cinza (dither), sem cor de sangue nem fogo: o K.O. é "a bateria pifou".
func puff(img: Image, c: Vector2, r: float) -> void:
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			var e := Vector2(x + 0.5 - c.x, (y + 0.5 - c.y) * 1.2).length() / r
			if e > 1.0:
				continue
			if e < 0.55:
				fx(img, x, y, "g2" if (x + y) % 3 else "g3")
			elif (x + y) % 2 == 0:
				fx(img, x, y, "g1")

# ================================================================================================ Apagão: peças próprias
## Luva de borracha gigante: cano largo + mão fechada + polegar, orientados pelo antebraço (v2).
func big_glove(id: int, el: Vector2, hand: Vector2, far: bool, open := false) -> void:
	var d := (hand - el).normalized()
	var n := Vector2(-d.y, d.x)
	if n.y > 0.0:
		n = -n
	var ang := rad_to_deg(atan2(d.y, d.x))
	var rp := ["y0", "y1", "y2", "white"] if not far else ["br3", "y0", "y1"]
	blob(id, hand - d * 5.0, 3.4, 4.4, ["br3", "y0", "y0"] if not far else ["br2", "br3", "br3"], ang)
	blob(id + 1, hand + d * 1.0, 5.6, 5.0, rp, ang)
	if open:
		# mão aberta (empurra o clinche): 3 dedos grossos para a frente, polegar para cima
		for k in [-2.2, 0.0, 2.2]:
			blob(id + 1, hand + d * 5.6 + n * k, 2.4, 1.3, rp, ang)
		blob(id + 1, hand + d * 1.5 + n * 5.0, 2.2, 1.6, rp, ang + 40.0)
	else:
		blob(id + 1, hand + d * 0.5 + n * 4.2, 2.4, 1.7, rp, ang)
	var c := hand - d * 2.2
	for k in range(-4, 5):
		var q := c + n * k * 0.9
		P.put(int(q.x), int(q.y), "br3" if not far else "br2", id + 1)

## Cabo em espiral subindo da bateria, com garra de jacaré na ponta (v2).
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

## Capacete solto (o mesmo mapa do HEAD_B, linhas 0..5) com a lanterna rachada: K.O. e troféu nascem do mesmo desenho.
const HELMET_ROWS := [
	".....JjjjjjJ......",
	"...JjjjjjiiijJ....",
	"..JjjjjjjjiiijjG..",
	"..JjjjjjjjjjjjjGkk",
	".JJJJJJJJJJJJJJGWk",
	"JJJJJJJJJJJJJJJJJ.",
	"..bbbbbbbbbbbbb...",
]

## Ganchos do rig. mode: guard | jab | heavy | hit | sig | blackout | ko | daze.
func hooks(p: Dictionary, mode: String) -> Dictionary:
	var hot := mode in ["heavy", "blackout", "sig"]
	var lamp_state := "on"
	if mode in ["hit", "daze"]:
		lamp_state = "dim"
	if mode == "ko":
		lamp_state = "none"
	p["before_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hip: Vector2 = ctx.hip
		var top: Vector2 = ctx.top
		var dn: Vector2 = ctx.dn
		var fr: Vector2 = ctx.fr
		var ln := (top - hip).length()
		var ang := rad_to_deg(atan2(dn.x, -dn.y))
		_hip = hip
		_top = top
		# bateria grande nas costas: caixa escura, faixa amarela, tampa cinza, polos
		var bc := hip + dn * ln * 0.7 - fr * 10.0
		box(26, bc, 12.0, 17.0, ang, ["d1", "d2", "g0"])
		box(26, bc - dn * 1.0, 12.0, 2.0, ang, ["y0", "y0", "y1"])
		var tp := bc + dn * 9.0
		box(27, tp, 12.0, 2.0, ang, ["g0", "g1", "g2"])
		var pr := tp + dn * 1.5 + fr * 3.0
		var pn := tp + dn * 1.5 - fr * 3.5
		_bat = (pr + pn) * 0.5
		_piv = tp + dn * 1.0 + fr * 0.5
		# a coroa de cabos (no K.O. e no atordoado ela murcha: espiral mais curta)
		var hc := 13.0 if not mode in ["ko", "daze"] else 9.0
		coil(25, pr, (dn * 1.0 - fr * 0.25).normalized(), hc, "y2" if hot else "r1", "r2")
		coil(25, pn, (dn * 1.0 - fr * 0.7).normalized(), hc - 2.0, "y1" if hot else "d1", "g1")
		wire(24, pn + Vector2(0, 1), ctx.hb + (ctx.elb - ctx.hb).normalized() * 6.0, 8.0, "d1")
		if mode == "blackout":
			wire(27, _piv, ctx.hb, 0.0, "st2", "st1")
		big_glove(28, ctx.elb, ctx.hb, true, mode == "sig")
		if mode == "blackout":
			blob(29, ctx.hb + (ctx.hb - _piv).normalized() * 6.0, 2.4, 2.4, ["r1", "r2", "r3"])
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
		var hd: Vector2 = ctx.hd
		_hd = hd
		_lamp = hd + P.rotv(V(9, -6), ctx.hrot)
		if lamp_state != "none":
			blob(42, _lamp, 3.4, 3.6, ["g0", "g1", "g2"])
			if lamp_state == "on":
				blob(43, _lamp + V(0.6, 0), 2.0, 2.6, ["y1", "y2", "white"])
			else:
				blob(43, _lamp + V(0.6, 0), 2.0, 2.6, ["g0", "y0", "y1"])
	p["end"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		_hf = ctx.hf
		_hb = ctx.hb
		_elf = ctx.elf
		var a: Vector2 = ctx.top - ctx.fr * 6.0 - ctx.dn * 2.0
		var b: Vector2 = ctx.hf + (ctx.elf - ctx.hf).normalized() * 6.0
		if hot:
			wire(59, a, b, 8.0, "white", "y2")
		else:
			wire(59, a, b, 10.0, "r1")
		big_glove(64, ctx.elf, ctx.hf, false, mode == "sig")
		if mode == "ko":
			# o capacete saiu rolando e parou de lado no chão, perto da cabeça
			_helmet = O + V(-42, -5)
			P.pmap(80, HELMET_ROWS, {"J": "y0", "j": "y1", "i": "y2", "G": "g1", "k": "d1", "W": "white", "b": "br1"},
				_helmet, Vector2i(9, 6), -18.0)
	return p

## Poses-chave (virado para a direita; relativas ao pivô). Mesma base da guarda do v2, com o corpo inteiro no golpe.
func poses() -> Dictionary:
	return {
		"guard": hooks({"hip": V(0, -40), "top": V(8, -62), "head": V(17, -69), "toef": V(18, -1), "toeb": V(-8, -1),
			"sf": V(9, -60), "sb": V(4, -61), "hf": V(31, -48), "hb": V(24, -53), "pf": V(0.2, 1.0), "pb": V(0.2, 1.0)}, "guard"),
		# jab: o quadril vai 2 px, o ombro da frente avança; a luva de trás fica na guarda
		"jab": hooks({"hip": V(2, -40), "top": V(11, -62), "head": V(20, -69), "toef": V(20, -1), "toeb": V(-8, -1),
			"shoeb": "ball", "tw": 0.8, "sf": V(13, -60), "sb": V(7, -61), "hf": V(45, -58), "hb": V(25, -54),
			"pf": V(0.2, 1.0), "pb": V(0.2, 1.0), "gkf": "side"}, "jab"),
		# choque (golpe forte): o corpo inteiro avança, braço todo esticado, cabo incandescente
		"heavy": hooks({"hip": V(3, -40), "top": V(13, -61), "head": V(22, -68), "toef": V(22, -1), "toeb": V(-6, -1),
			"shoeb": "ball", "tw": 1.6, "sf": V(14, -59), "sb": V(9, -60), "hf": V(46, -61), "hb": V(1, -50)}, "heavy"),
		# leva: a cabeça vai para trás primeiro, o tronco acompanha, as luvas abrem
		"hit": hooks({"hip": V(-3, -40), "top": V(-5, -63), "head": V(1, -73), "hrot": -14.0, "face": "pain",
			"toef": V(16, -1), "toeb": V(-10, -1), "shoef": "ball", "sf": V(-4, -61), "sb": V(-9, -62),
			"hf": V(17, -57), "hb": V(10, -64), "pf": V(0.2, 1.0), "pb": V(0.0, 1.0)}, "hit"),
		# passiva (adv_slippery): empurra o clinche com as duas mãos abertas e a eletricidade estala no corpo todo
		"sig": hooks({"hip": V(-2, -40), "top": V(4, -63), "head": V(12, -71), "toef": V(17, -1), "toeb": V(-10, -1),
			"sf": V(5, -61), "sb": V(0, -62), "hf": V(37, -57), "hb": V(32, -62), "pf": V(0.2, 1.0), "pb": V(0.2, 1.0)}, "sig"),
		"blackout": hooks({"hip": V(-1, -39), "top": V(4, -62), "head": V(12, -71), "toef": V(17, -1), "toeb": V(-8, -1),
			"sf": V(5, -60), "sb": V(0, -61), "hf": V(26, -55), "hb": V(-7, -82), "pf": V(0.2, 1.0), "pb": V(-1.0, 0.0)}, "blackout"),
		# K.O. ("APAGOU"): caiu sentado e tombou para trás, encostado na própria bateria (ela vira encosto no chão);
		# pernas esticadas com a ponta da bota para cima, braços largados no chão, cabeça caída para trás
		"ko": hooks({"hip": V(0, -8), "top": V(-14, -26), "head": V(-17, -35), "hrot": -38.0, "face": "ko",
			"toef": V(29, -1), "toeb": V(23, -1), "shoef": "up", "shoeb": "up", "kf": V(0.2, -1), "kb": V(0.2, -1),
			"hf": V(13, -5), "hb": V(-27, -5), "pf": V(0.6, -0.4), "pb": V(-0.3, -1.0)}, "ko"),
		# atordoado: joelhos cedem, braços compridos pendurados quase nos joelhos, cabeça tombada
		"daze": hooks({"hip": V(-1, -36), "top": V(3, -59), "head": V(11, -66), "hrot": 12.0, "face": "daze",
			"toef": V(14, -1), "toeb": V(-9, -1), "sf": V(4, -57), "sb": V(-1, -58), "hf": V(15, -27), "hb": V(8, -30),
			"pf": V(-0.3, 1.0), "pb": V(-0.3, 1.0)}, "daze"),
	}

const ORDER := ["guard", "jab", "heavy", "hit", "sig", "blackout", "ko", "daze"]
const LABEL := {"guard": "GUARDA", "jab": "JAB", "heavy": "CHOQUE (FORTE)", "hit": "LEVA", "sig": "PASSIVA: SOLTA O CLINCHE",
	"blackout": "APAGÃO (ALAVANCA)", "ko": "K.O. (APAGOU)", "daze": "ATORDOADO"}

## Gera os quadros. Cada pose: base (corpo), fx (faíscas, sem contorno) e lamp; tudo ainda virado para a DIREITA.
func frames() -> Dictionary:
	var b := build_apagao(true)
	var bko := build_apagao(false)
	var ps := poses()
	var out := {}
	for k in ORDER:
		var base: Image = P.fight_frame(bko if k == "ko" else b, ps[k], "APAGAO " + k, Vector2i(FW, FH), DRAW_PIV)
		var f: Image = L.blank(FW, FH)
		if k != "ko":
			bolt(f, _bat + V(-3, -1), _bat + V(3, -5), 40 + k.length(), 2, 1.0)
		match k:
			"guard":
				bolt(f, _hb + V(3, 1), _hf + V(-3, -1), 11, 3, 2.0)
				bolt(f, _hb + V(2, 4), _hf + V(-3, 3), 12, 3, 2.0)
				spark(f, (_hb + _hf) * 0.5 + V(0, -5), 1)
			"jab":
				spark(f, _hf + V(6, -1), 1)
			"heavy":
				bolt(f, _hf + V(2, -5), _hf + V(6, -14), 33, 3, 2.0)
				bolt(f, _hf + V(2, 5), _hf + V(6, 11), 34, 2, 1.5)
				spark(f, _hf + V(7, 0), 2, true)
				spark(f, _lamp + V(1, 0), 2, true)
			"hit":
				bolt(f, _bat + V(-2, -2), _bat + V(-8, -7), 71, 2, 1.5)
				for d in [V(-7, -6), V(-9, -3), V(-5, -9)]:
					fx(f, int(_hd.x + d.x), int(_hd.y + d.y), "white")      # gota de suor
			"sig":
				bolt(f, _hf + V(6, -3), _hf + V(12, -10), 81, 3, 2.0)
				bolt(f, _hf + V(6, 3), _hf + V(12, 9), 82, 3, 2.0)
				bolt(f, _hb + V(6, -4), _hb + V(13, -12), 83, 3, 2.0)
				bolt(f, _bat + V(-6, 0), _hip + V(-8, 4), 84, 4, 2.5)        # arco descendo pelas costas
				bolt(f, _bat + V(0, -6), _hd + V(-6, -9), 85, 3, 2.0)        # arco até o capacete
				spark(f, _hf + V(8, 0), 2, true)
				spark(f, _hb + V(7, -3), 2, true)
				spark(f, _hip + V(-8, 4), 1)
			"blackout":
				spark(f, _piv, 2, true)
				bolt(f, _piv + V(-1, -1), _piv + V(-7, -6), 51, 3, 1.5)
				bolt(f, _hf + V(3, -4), _hf + V(9, -12), 52, 3, 2.0)
				bolt(f, _hf + V(5, 2), _hf + V(13, 6), 53, 3, 2.0)
				spark(f, _lamp + V(1, 0), 2, true)
			"ko":
				puff(f, _bat + V(-7, -4), 3.0)
				puff(f, _bat + V(-11, -10), 2.2)
				puff(f, _helmet + V(6, -7), 1.6)
				spark(f, _bat + V(-2, -1), 1)
			"daze":
				for i in 3:
					var a := TAU * float(i) / 3.0 + 0.6
					spark(f, _hd + V(-1, -12) + V(cos(a) * 9.0, sin(a) * 3.0), 1)
				bolt(f, _bat + V(-2, -1), _bat + V(-6, -5), 91, 2, 1.0)
		var full: Image = base.duplicate()
		full.blend_rect(f, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
		out[k] = flipped(full)
		out[k + "_base"] = flipped(base)
		out[k + "_fx"] = flipped(f)
		out[k + "_right"] = full
		out[k + "_lamp"] = V(FW - 1 - _lamp.x, _lamp.y)
		out[k + "_hf"] = V(FW - 1 - _hf.x, _hf.y) - PIV
		out[k + "_hb"] = V(FW - 1 - _hb.x, _hb.y) - PIV
		out[k + "_hd"] = V(FW - 1 - _hd.x, _hd.y) - PIV
		if k == "guard":
			out["guard_hd_right"] = _hd
	return out

func flipped(im: Image) -> Image:
	var c: Image = im.duplicate()
	c.flip_x()
	return c

## Conferência: pivô no chão (algum pixel opaco na linha da sola perto do pivô), nada encostando na borda.
func conferir(fr: Dictionary) -> void:
	for k in ORDER:
		var im: Image = fr[k]
		var borda := 0
		for y in FH:
			for x in [0, FW - 1]:
				if im.get_pixel(x, y).a > 0.0:
					borda += 1
		for x in FW:
			if im.get_pixel(x, 0).a > 0.0:
				borda += 1
		var sola := 0
		for x in range(20, 100):
			if im.get_pixel(x, int(PIV.y)).a > 0.0:
				sola += 1
		report.append("%s: %d px na borda, %d px na linha da sola (y 98); mão frente %s trás %s" % [k, borda, sola, fr[k + "_hf"], fr[k + "_hb"]])

# ================================================================================================ retrato e silhueta
func retrato(fr: Dictionary, sil := false) -> Image:
	var src: Image = fr.guard_right
	var hd: Vector2 = fr.guard_hd_right
	var im: Image = L.blank(32, 32)
	im.fill(L.col("d1"))
	for y in 32:
		for x in 32:
			if (x + y) % 2 == 0 and y > 20:
				im.set_pixel(x, y, L.col("st0"))
	var ox := int(hd.x) - 15
	var oy := int(hd.y) - 13
	for y in 32:
		for x in 32:
			var sx := ox + x
			var sy := oy + y
			if sx >= 0 and sy >= 0 and sx < FW and sy < FH:
				var c := src.get_pixel(sx, sy)
				if c.a > 0.0:
					im.set_pixel(x, y, L.col("ink") if sil else c)
	if sil:
		# só a lanterna acesa no escuro: o "???" do Dossiê ganha 1 pista sem mostrar o rosto
		var lp: Vector2 = V(FW - 1, 0) + V(-fr.guard_lamp.x, fr.guard_lamp.y)
		var lx := int(lp.x) - ox
		var ly := int(lp.y) - oy
		fx(im, lx, ly, "y2")
		fx(im, lx + 1, ly, "y1")
		fx(im, lx, ly + 1, "y1")
	return im

func silhueta(im: Image, c: String) -> Image:
	var out: Image = im.duplicate()
	for y in out.get_height():
		for x in out.get_width():
			if out.get_pixel(x, y).a > 0.0:
				out.set_pixel(x, y, L.col(c))
	return out

# ================================================================================================ arena do chefe
const BAY := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
const WALL_BASE := 262
const LAMP := Vector2(320, 104)

func bay(x: int, y: int) -> float:
	return (float(BAY[y % 4][x % 4]) + 0.5) / 16.0

## A mesma luz do beco (make_sprites_ronda2a.gd light_step): o que entra no cenário recebe a luz da arandela.
func light_step(x: int, y: int) -> int:
	var b := (bay(x, y) - 0.5) * 22.0
	if y < WALL_BASE:
		var d := Vector2(x - LAMP.x, (y - LAMP.y) * 0.8).length() + b
		if d < 72.0:
			return 1
		if d < 200.0:
			return 0
		if d < 300.0:
			return -1
		return -2
	var df := Vector2(x - LAMP.x, (y - 316.0) * 3.2).length() + b
	if df < 165.0:
		return 0
	if df < 270.0:
		return -1
	return -2

func put_l(im: Image, x: int, y: int, c: String) -> void:
	if x < 0 or y < 46 or x >= AW or y >= AH:
		return
	var col: Color = L.col(c)
	var st := light_step(x, y)
	var sc: Color = L.shade(col, st)
	while sc == L.col("ink") and c != "ink" and st < 0:
		st += 1
		sc = L.shade(col, st)
	im.set_pixel(x, y, sc)

func rect_l(im: Image, x: int, y: int, w: int, h: int, c: String) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			put_l(im, xx, yy, c)

func line_l(im: Image, a: Vector2, b: Vector2, c: String) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		put_l(im, int(p.x), int(p.y), c)

func sag_l(im: Image, a: Vector2, b: Vector2, sag: float, c: String) -> void:
	var n := int(absf(b.x - a.x)) + int(absf(b.y - a.y)) + 2
	var last := Vector2i(-99, -99)
	for i in n + 1:
		var t := float(i) / n
		var p := a.lerp(b, t) + V(0, sag * 4.0 * t * (1.0 - t))
		var q := Vector2i(int(p.x), int(p.y))
		if q != last:
			put_l(im, q.x, q.y, c)
			last = q

## Fundo do chefe: o beco da 2a1 + poste de concreto com transformador e a fiação embolada (o "gato") descendo até a
## CAIXA DE LUZ aberta na parede, com a alavanca grande. Tudo fora do chão livre (x 200..440) e acima das cabeças (y < 210).
func arena_bg() -> Image:
	var im: Image = P.load_png(R + "assets/sprites/ronda2a/arena/arena_alley_bg.png")
	# --- poste de concreto (x 170..177), da faixa do HUD até a calçada
	for y in range(46, WALL_BASE + 6):
		for x in range(170, 178):
			var c := "g2" if x < 172 else ("g1" if x < 176 else "g0")
			if (y * 7 + x) % 23 == 0:
				c = "g0"
			put_l(im, x, y, c)
		put_l(im, 169, y, "ink")
		put_l(im, 178, y, "ink")
	rect_l(im, 168, WALL_BASE + 6, 12, 2, "g0")
	# placa de número e degraus de ferro no poste
	rect_l(im, 171, 150, 6, 8, "cream")
	rect_l(im, 172, 152, 4, 1, "ink")
	rect_l(im, 172, 155, 3, 1, "ink")
	for y in range(170, 240, 12):
		rect_l(im, 166, y, 4, 1, "st2")
		rect_l(im, 178, y + 6, 4, 1, "st2")
	# cruzeta com isoladores
	rect_l(im, 150, 58, 50, 3, "br1")
	rect_l(im, 150, 58, 50, 1, "br2")
	for x in [153, 162, 186, 195]:
		rect_l(im, x, 55, 2, 3, "cream")
		put_l(im, x, 54, "white")
	# transformador (tambor de aço) pendurado do lado direito
	for y in range(64, 88):
		for x in range(180, 194):
			var c := "st2" if x < 183 else ("st1" if x < 190 else "st0")
			if (y - 64) % 5 == 0:
				c = "st0" if x > 182 else "st1"
			put_l(im, x, y, c)
	rect_l(im, 179, 63, 16, 1, "ink")
	rect_l(im, 179, 88, 16, 1, "ink")
	rect_l(im, 182, 60, 2, 3, "cream")
	rect_l(im, 190, 60, 2, 3, "cream")
	rect_l(im, 182, 78, 6, 5, "y0")   # placa amarela de perigo
	put_l(im, 184, 79, "ink")
	put_l(im, 185, 80, "ink")
	put_l(im, 184, 81, "ink")
	# fiação: da cruzeta até a direita (barriga), e o emaranhado do "gato" pendurado
	for w in [[V(153, 55), V(640, 64), 16.0, "ink"], [V(162, 55), V(640, 72), 20.0, "ink"], [V(195, 55), V(640, 52), 10.0, "d1"],
			[V(186, 55), V(0, 66), 12.0, "ink"], [V(153, 55), V(0, 74), 8.0, "d1"]]:
		sag_l(im, w[0], w[1], w[2], w[3])
	var rng := RandomNumberGenerator.new()
	rng.seed = 2202
	for i in 7:
		var a := V(200 + rng.randi_range(0, 40), 58 + rng.randi_range(0, 8))
		var b := V(380 + rng.randi_range(-6, 6), 128 + rng.randi_range(-4, 2))
		sag_l(im, a, b, rng.randf_range(8.0, 22.0), "ink" if i % 2 == 0 else "d1")
	# rolo de fio solto pendurado (laço)
	for i in 40:
		var t := TAU * float(i) / 40.0
		put_l(im, int(232 + cos(t) * 6.0), int(82 + sin(t) * 4.0), "ink")
	# --- CAIXA DE LUZ (x 372..405, y 132..186), porta aberta para a direita
	var bx := 372
	var by := 132
	rect_l(im, bx - 1, by - 1, 36, 56, "ink")
	rect_l(im, bx, by, 34, 54, "st1")
	rect_l(im, bx, by, 34, 2, "st2")
	rect_l(im, bx, by, 2, 54, "st2")
	rect_l(im, bx + 3, by + 4, 28, 47, "d1")           # dentro, escuro
	# 3 relógios (medidores) redondos
	for i in 3:
		var cx := bx + 8 + i * 9
		for y in range(by + 7, by + 14):
			for x in range(cx - 3, cx + 4):
				if Vector2(x - cx, y - (by + 10)).length() <= 3.2:
					put_l(im, x, y, "cream" if Vector2(x - cx, y - (by + 10)).length() < 2.2 else "g1")
		put_l(im, cx, by + 10, "ink")
		put_l(im, cx + 1, by + 9, "r1")
	# disjuntores
	for i in 6:
		rect_l(im, bx + 5 + i * 4, by + 19, 3, 6, "g2")
		put_l(im, bx + 6 + i * 4, by + 21 + (i % 2) * 2, "ink")
	# a ALAVANCA grande (chave faca) com o cabo vermelho, abaixada
	rect_l(im, bx + 6, by + 31, 22, 4, "st0")
	rect_l(im, bx + 8, by + 32, 2, 2, "st3")
	rect_l(im, bx + 24, by + 32, 2, 2, "st3")
	line_l(im, V(bx + 17, by + 33), V(bx + 17, by + 46), "st3")
	line_l(im, V(bx + 18, by + 33), V(bx + 18, by + 46), "st2")
	rect_l(im, bx + 15, by + 45, 6, 4, "r2")
	rect_l(im, bx + 15, by + 45, 6, 1, "r3")
	# porta aberta (em perspectiva) com o raio de perigo
	for y in range(by - 2, by + 57):
		var t := float(y - by) / 54.0
		for x in range(bx + 35, bx + 42):
			var top_y := by - 2 + int((x - bx - 35) * 0.6)
			var bot_y := by + 55 - int((x - bx - 35) * 0.6)
			if y < top_y or y > bot_y:
				continue
			put_l(im, x, y, "st2" if x < bx + 37 else "st1")
	for d in [V(2, 0), V(1, 1), V(0, 2), V(2, 2), V(1, 3), V(0, 4)]:
		put_l(im, bx + 37 + int(d.x), by + 20 + int(d.y), "y1")
	# eletroduto da caixa subindo até a fiação
	for y in range(118, by):
		put_l(im, bx + 16, y, "st0")
		put_l(im, bx + 17, y, "st2")
	rect_l(im, bx + 14, 116, 6, 2, "st1")
	return im

func darken(im: Image, n: int) -> void:
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a > 0.0:
				im.set_pixel(x, y, L.shade(c, -n))

func cone_light(im: Image, src: Vector2, dir: Vector2, half_ang: float, reach: float) -> void:
	var dn := dir.normalized()
	for y in range(46, im.get_height()):
		for x in im.get_width():
			var d := Vector2(x, y) - src
			var l := d.length()
			if l < 2.0 or l > reach:
				continue
			var a := absf(d.angle_to(dn))
			if a > half_ang:
				continue
			var k := (1.0 - l / reach) * (1.0 - pow(a / half_ang, 2.0)) * 1.4
			if k > bay(x, y):
				im.set_pixel(x, y, L.shade(im.get_pixel(x, y), 2 if k > 1.0 + bay(x, y) * 0.6 else 1))

## Faíscas fixas da caixa e do transformador no escuro (o que fica aceso no apagão, além da lanterna).
func faiscas_arena(im: Image, q: int) -> void:
	spark(im, V(389, 177), 2, q == 0)
	spark(im, V(186, 89), 1 + q, true)
	bolt(im, V(389, 176), V(396 + q * 2, 168), 300 + q, 3, 2.0)
	bolt(im, V(186, 89), V(181, 97), 310 + q, 2, 1.5)

func sombra_pes(im: Image, cx: int) -> void:
	for yy in range(315, 322):
		for xx in range(cx - 16, cx + 17):
			var e := Vector2((xx - cx) / 16.0, (yy - FEET) / 3.0).length()
			if e <= 1.0 and (xx + yy) % 2 == 0:
				im.set_pixel(xx, yy, L.col("ink"))

# ---- vulto lutando (as folhas da 2a1 montadas como o DiscVisual, look A)
func rel(res: String) -> String:
	return R + res.trim_prefix("res://")

func load_res(res: String) -> Image:
	return P.load_png(rel(res))

func recolor(im: Image, cmap: Dictionary) -> void:
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var k := c.to_html(false)
			if cmap.has(k):
				im.set_pixel(x, y, cmap[k])

## Estilo raro proposto: "fio desencapado" = faixa amarela viva com a sombra preta da borracha (só cor).
const LIVE_WIRE := {"headband_color": {"id": "live_wire", "ramp": {"light": "#fff3c4", "dark": "#f5d26b", "deep": "#2a2233"}},
	"shorts_color": {"id": "live_wire", "ramp": {"band": "#2a2233", "light": "#f5d26b", "mid": "#e0a040", "dark": "#2a2233", "deep": "#14101a"}}}

func opt_ramp(field: String, id: String) -> Dictionary:
	if LIVE_WIRE.has(field) and LIVE_WIRE[field].id == id:
		return LIVE_WIRE[field].ramp
	for o in PAL.options.get(field, []):
		if str(o.id) == id:
			return o.ramp
	return {}

func keymap(look: Dictionary) -> Dictionary:
	var m := {}
	var fields := {"skin": look.skin, "hair_color": look.hair_color, "shorts_color": look.shorts_color,
		"top_color": look.get("top_color", "white"), "headband_color": look.get("headband_color", "red"),
		"socks": look.get("socks_color", look.shorts_color)}
	for f in fields:
		var ramp := opt_ramp(f, str(fields[f]))
		var ks: Dictionary = PAL.keys[f]
		for slot in ks:
			if ramp.has(slot):
				m[(ks[slot] as String).trim_prefix("#").to_lower()] = Color.html(ramp[slot])
	var src: Dictionary = PAL.school_symbol_source.leg
	var sid: String = "blue" if look.shorts_color == "live_wire" else str(src.map.get(look.shorts_color, "yellow"))
	var sr := opt_ramp("school_symbol", sid)
	for slot in PAL.keys.school_symbol:
		if sr.has(slot):
			m[(PAL.keys.school_symbol[slot] as String).trim_prefix("#").to_lower()] = Color.html(sr[slot])
	return m

## Monta um quadro de folha em camadas (vulto ou discípulo) como o DiscVisual.
func compose(entry_id: String, q: int, look: Dictionary) -> Image:
	var e: Dictionary = M.sprites[entry_id]
	var lay: Dictionary = e.layers
	var r := Rect2i(q * FW, 0, FW, FH)
	var base: Image = load_res(str(lay.body)).get_region(r)
	if str(look.get("top", "none")) != "none" and lay.has("top"):
		base.blend_rect(load_res(str(lay.top[look.top])).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	if bool(look.get("symbol", false)) and str(look.get("top", "none")) == "none" and lay.has("school_symbol"):
		base.blend_rect(load_res(str(lay.school_symbol.leg)).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	var out: Image = base.duplicate()
	out.blend_rect(load_res(str(lay.head[look.get("hair_style", "short")])).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	if str(look.get("headband", "none")) != "none" and lay.has("band"):
		out.blend_rect(load_res(str(lay.band)).get_region(r), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	var mk := load_res(str(lay.front_mask)).get_region(r)
	for y in FH:
		for x in FW:
			var m := mk.get_pixel(x, y)
			if m.a > 0.5 and m.r > 0.5 and base.get_pixel(x, y).a > 0.0:
				out.set_pixel(x, y, base.get_pixel(x, y))
	recolor(out, keymap(look))
	return out

const LOOK_A := {"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "top": "none", "shorts_color": "green",
	"socks": "none", "symbol": true, "headband": "on", "headband_color": "red"}

## Cena de luta montada na posição do jogo. dark = apagão (tudo 2 passos abaixo; a lanterna e as faíscas ficam).
func cena(bg: Image, fr: Dictionary, pose: String, vact: String, vq: int, dark: bool) -> Image:
	var im: Image = bg.duplicate()
	var lamp: Image = P.load_png(R + "assets/sprites/ronda2a/arena/arena_alley_lamp.png")
	var lf := 2 if dark else 0
	im.blend_rect(lamp.get_region(Rect2i(lf * 40, 0, 40, 40)), Rect2i(0, 0, 40, 40), Vector2i(300, 84))
	var rain: Image = P.load_png(R + "assets/sprites/ronda2a/arena/arena_alley_crowd_back.png")
	im.blend_rect(rain.get_region(Rect2i(0, 0, AW, 314)), Rect2i(0, 0, AW, 314), Vector2i(0, 46))
	sombra_pes(im, VUL_X)
	sombra_pes(im, OPP_X)
	var v := compose("fight_vulto_" + vact, vq, LOOK_A)
	im.blend_rect(v, Rect2i(0, 0, FW, FH), Vector2i(VUL_X - 56, FEET - 98))
	var org := Vector2i(OPP_X - 56, FEET - 98)
	im.blend_rect(fr[pose + "_base"], Rect2i(0, 0, FW, FH), org)
	var front: Image = P.load_png(R + "assets/sprites/ronda2a/arena/arena_alley_crowd_front.png")
	im.blend_rect(front.get_region(Rect2i(0, 0, AW, 48)), Rect2i(0, 0, AW, 48), Vector2i(0, 312))
	if dark:
		darken(im, 2)
		var lp: Vector2 = fr[pose + "_lamp"]
		var src := V(org.x + lp.x, org.y + lp.y)
		cone_light(im, src, V(-1, 0.35), 0.32, 190.0)
		cone_light(im, src, V(-1, 0.35), 0.16, 130.0)
		faiscas_arena(im, 0)
	im.blend_rect(fr[pose + "_fx"], Rect2i(0, 0, FW, FH), org)
	if pose == "heavy":
		var fc := fx_choque()
		var hf: Vector2 = fr.heavy_hf
		paste(im, fc, org.x + 56 + int(hf.x) - 43 - 4, org.y + 98 + int(hf.y) - 10)
	return im

## Fundo do apagão como peça (para a tela trocar o fundo por ~1 s): fundo 2 passos abaixo, cone da lanterna na posição
## da pose do apagão (o chefe fica parado no pivô 346,318) e as faíscas fixas. Os lutadores a tela escurece por modulate.
func arena_dark_bg(bg: Image, fr: Dictionary) -> Image:
	var im: Image = bg.duplicate()
	var lamp: Image = P.load_png(R + "assets/sprites/ronda2a/arena/arena_alley_lamp.png")
	im.blend_rect(lamp.get_region(Rect2i(80, 0, 40, 40)), Rect2i(0, 0, 40, 40), Vector2i(300, 84))
	darken(im, 2)
	var lp: Vector2 = fr.blackout_lamp
	var src := V(OPP_X - 56 + lp.x, FEET - 98 + lp.y)
	cone_light(im, src, V(-1, 0.35), 0.32, 190.0)
	cone_light(im, src, V(-1, 0.35), 0.16, 130.0)
	faiscas_arena(im, 0)
	return im

# ================================================================================================ troféu (44x30, pivô 22,29)
## Capacete de obra em 3/4 com a lanterna na frente, amassado e com a jugular pendurada. raro = polido e a lanterna ainda
## acende (quadro 0 acesa com halo, quadro 1 fraca: "ainda piscando").
func trofeu(rare: bool, q: int) -> Image:
	P.canvas(44, 30)
	# normal = gasto (um passo mais escuro, sujo e amassado); raro = polido (rampa amarela cheia com brilho branco pontual)
	var dome_r := ["y0", "y1", "y2", "white"] if rare else ["br3", "y0", "y1"]
	var brim_top: String = "y1" if rare else "y0"
	var brim_dn: String = "y0" if rare else "br2"
	# jugular (atrás): laço de couro pendurado embaixo da aba
	for i in 16:
		var t := float(i) / 15.0
		var p := V(8, 22).lerp(V(27, 22), t) + V(0, 6.0 * 4.0 * t * (1.0 - t))
		P.put(int(p.x), int(p.y), "br1", 2)
		P.put(int(p.x), int(p.y) + 1, "br0", 2)
	# aba: curta atrás, COMPRIDA na frente (o bico do capacete de obra), fina
	for y in range(18, 25):
		for x in range(0, 44):
			var u := (x + 0.5 - 22.0) / (21.5 if x > 22 else 18.0)
			var v := (y + 0.5 - 21.0) / 2.4
			if u * u + v * v <= 1.0:
				P.put(x, y, brim_top if v < -0.2 else brim_dn, 1)
	# domo redondo
	for y in range(3, 21):
		for x in range(5, 36):
			var u := (x + 0.5 - 20.0) / 14.0
			var v := (y + 0.5 - 20.0) / 16.0
			if u * u + v * v > 1.0 or y > 20:
				continue
			var lv := Vector2(u, v * 1.2).normalized().dot(P.LD) * sqrt(u * u + v * v)
			var c = dome_r[1]
			if lv > 0.3:
				c = dome_r[2]
			elif lv < -0.25 or y >= 19:
				c = dome_r[0]
			if rare and lv > 0.72 and (x + y) % 3 != 0:
				c = dome_r[3]
			P.put(x, y, c, 1)
	# nervura do meio (crista)
	for y in range(5, 20):
		var x := 18 + int((y - 5) * 0.12)
		P.put(x, y, dome_r[2], 1)
		P.put(x + 1, y, dome_r[0], 1)
	if not rare:
		# amassado grande e arranhões
		for d in [V(9, 10), V(10, 11), V(11, 12), V(11, 13), V(12, 14), V(13, 14)]:
			P.put(int(d.x), int(d.y), "br3", 1)
		for d in [V(10, 10), V(11, 11), V(12, 13)]:
			P.put(int(d.x), int(d.y), "y2", 1)
		for d in [V(25, 9), V(26, 9), V(27, 15), V(8, 17), V(30, 18), V(23, 6)]:
			P.put(int(d.x), int(d.y), "br2", 1)
	# suporte e lanterna na frente do domo
	box(3, V(32.5, 12.5), 3.0, 4.0, 0.0, ["g0", "g1", "g2"])
	blob(3, V(37.0, 12.5), 5.0, 5.4, ["g0", "g1", "g2"])
	var lens := ["d1", "d2", "g0"]
	if rare:
		lens = ["y1", "y2", "white"] if q == 0 else ["y0", "y0", "y1"]
	blob(4, V(38.0, 12.5), 3.2, 3.6, lens)
	var im: Image = P.finish()
	if not rare:
		for d in [V(38, 12), V(37, 11), V(39, 13), V(39, 11), V(37, 14), V(40, 12), V(36, 10)]:
			fx(im, int(d.x), int(d.y), "g3" if d != V(38, 12) else "white")
	else:
		for d in [V(27, 5), V(7, 15)]:
			fx(im, int(d.x), int(d.y), "white")
		if q == 0:
			for y in 30:
				for x in 44:
					if im.get_pixel(x, y).a > 0.0:
						continue
					var dd := Vector2(x - 38.5, (y - 12.5) * 1.3).length()
					if dd < 7.0 and bay(x, y) < (7.0 - dd) / 3.5:
						im.set_pixel(x, y, L.col("y1" if dd < 5.5 else "y0"))
	return im

## Faísca longa do choque (o "choque de longe"), separada do quadro porque passa da borda: 44x20, virada para a ESQUERDA,
## ponto de ancoragem (43,10) = a luva da frente no quadro do hit_frame do golpe forte.
func fx_choque() -> Image:
	var im: Image = L.blank(44, 20)
	bolt(im, V(43, 10), V(2, 7), 931, 6, 3.0)
	bolt(im, V(43, 11), V(8, 16), 932, 4, 2.5)
	bolt(im, V(40, 9), V(16, 2), 933, 3, 2.0)
	spark(im, V(3, 7), 2, true)
	return im

# ================================================================================================ cartaz do menu
## Mesma luz da parede do menu (make_tema_c.gd luz): o eixo x 320 aceso, os lados 1 passo abaixo. Itens: teto 1.
const BAND_Y1 := 112
const POSTER_POS := Vector2i(444, 276)

func luz_menu(x: int, y: int) -> int:
	var n := 1
	if y >= BAND_Y1:
		var t := clampf(float(y - BAND_Y1) / float(360 - BAND_Y1), 0.0, 1.0)
		var hw := lerpf(74.0, 196.0, t)
		var d := absf(x - 320.0) / hw
		if d < 0.82 or (d < 1.0 and bay(x, y) * 16.0 >= 8.0):
			n = 0
	var dx := absf(x - 320.0) / 320.0
	var dy := float(y) / 360.0
	var e := dx * dx * 0.9 + dy * dy * 0.3
	if e > 0.78 or (e > 0.66 and bay(x, y) * 16.0 < 8.0):
		n += 1
	return mini(n, 2)

const VULTO_MINI := [
	".kk..kk.......",
	".kkkkkk....kk.",
	".kkkkkk....kk.",
	".krrrkk...kk..",
	".kkkkkk..kk...",
	"..kkkkkkkk....",
	".kkkkkkkk.....",
	"gkkkkkkk......",
	"ggkkkkkk......",
	"ggkkkkkk......",
	"gg.kkkkk......",
	"...kkkkk......",
	"...kk.kk......",
	"...kk.kk......",
	"..kkk.kkk.....",
]

## 56x67 de papel (+1 de sombra à direita, +2 embaixo: PNG 57x69). "O VULTO / [foto] / QUE / RELIGOU / A LUZ".
func cartaz() -> Image:
	var w := 56
	var h := 67
	var im: Image = L.blank(w + 1, h + 2)
	L.R(im, 1, 2, w, h, "d2")
	for y in h:
		for x in w:
			var c := "cream"
			if (x * 7 + y * 11) % 37 == 0:
				c = "g3"
			fx(im, x, y + 1, c)
	L.R(im, w - 1, 1, 1, h, "g3")
	L.R(im, 0, h, w, 1, "g3")
	# canto de baixo à esquerda rasgado
	for i in 5:
		for j in 5 - i:
			im.set_pixel(j, h - i, Color(0, 0, 0, 0))
		fx(im, 4 - i, h - i, "g3")
	L.text_center(im, "O VULTO", w / 2, 4, "ink")
	# foto: a lâmpada acesa no meio da noite e o vulto erguendo o braço; o capacete quebrado no chão
	var px0 := 3
	var py0 := 13
	var pw := w - 6
	var ph := 22
	var bc := V(px0 + pw * 0.5 + 2, py0 + 6)
	for y in range(py0, py0 + ph):
		for x in range(px0, px0 + pw):
			var d := Vector2(x + 0.5 - bc.x, (y + 0.5 - bc.y) * 1.1).length() + (bay(x, y) - 0.5) * 4.0
			var c := "b0"
			if d < 6.0:
				c = "y2"
			elif d < 10.0:
				c = "y1"
			elif d < 15.0:
				c = "y0"
			elif d < 20.0:
				c = "b1"
			fx(im, x, y, c)
	# fio e lâmpada
	for y in range(py0, int(bc.y) - 3):
		fx(im, int(bc.x), y, "ink")
	L.R(im, int(bc.x) - 1, int(bc.y) - 3, 3, 2, "g1")
	for d in [V(-1, -1), V(0, -1), V(1, -1), V(-2, 0), V(-1, 0), V(0, 0), V(1, 0), V(2, 0), V(-1, 1), V(0, 1), V(1, 1), V(0, 2)]:
		fx(im, int(bc.x + d.x), int(bc.y + d.y), "white")
	fx(im, int(bc.x), int(bc.y), "y0")
	# vulto (silhueta, faixa vermelha, capa cinza)
	var leg := {"k": "ink", "r": "r2", "g": "g1"}
	for j in VULTO_MINI.size():
		var row: String = VULTO_MINI[j]
		for i in row.length():
			if leg.has(row[i]):
				fx(im, int(bc.x) - 13 + i, py0 + ph - VULTO_MINI.size() + j, leg[row[i]])
	# capacete amarelo caído com a lente escura
	var hx := px0 + pw - 11
	var hy := py0 + ph - 4
	L.R(im, hx + 1, hy, 5, 1, "y1")
	L.R(im, hx, hy + 1, 7, 2, "y0")
	L.R(im, hx - 1, hy + 3, 9, 1, "br3")
	fx(im, hx + 7, hy + 1, "g1")
	fx(im, hx + 8, hy + 1, "d1")
	# moldura fina da foto
	for x in range(px0, px0 + pw):
		fx(im, x, py0 - 1, "ink")
		fx(im, x, py0 + ph, "ink")
	for y in range(py0 - 1, py0 + ph + 1):
		fx(im, px0 - 1, y, "ink")
		fx(im, px0 + pw, y, "ink")
	L.text_center(im, "QUE", w / 2, 38, "ink")
	L.text_center(im, "RELIGOU", w / 2, 46, "ink")
	# tarja r1 (escura: texto claro pode) com "A LUZ" em creme
	L.R(im, 2, 55, w - 4, 10, "r1")
	L.R(im, 2, 55, w - 4, 1, "r2")
	L.text_center(im, "A LUZ", w / 2, 57, "cream")
	# fita nos cantos de cima
	L.R(im, 0, 0, 6, 3, "g3")
	L.R(im, w - 6, 0, 6, 3, "g3")
	L.R(im, 0, 0, 6, 1, "white")
	L.R(im, w - 6, 0, 6, 1, "white")
	# luz do menu já pintada na posição
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a > 0.5:
				im.set_pixel(x, y, L.shade(c, -mini(1, luz_menu(POSTER_POS.x + x, POSTER_POS.y + y))))
	return im

## Parede do menu inteira (todas as camadas do parede.json + o cartaz novo), para conferir o lugar.
func parede_menu(poster: Image) -> Image:
	var im: Image = P.load_png(R + "assets/sprites/menu/menu_parede.png")
	var pj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(R + "assets/sprites/menu/parede.json"))
	var rects: Array = []
	for lay in pj.layers:
		var it: Image = load_res(str(lay.file))
		im.blend_rect(it, Rect2i(Vector2i.ZERO, it.get_size()), Vector2i(int(lay.pos[0]), int(lay.pos[1])))
		rects.append([str(lay.id), Rect2i(int(lay.pos[0]), int(lay.pos[1]), it.get_width(), it.get_height())])
	var pr := Rect2i(POSTER_POS, poster.get_size())
	im.blend_rect(poster, Rect2i(Vector2i.ZERO, poster.get_size()), POSTER_POS)
	var bad := 0
	for r in rects:
		if (r[1] as Rect2i).grow(2).intersects(pr):
			bad += 1
			report.append("cartaz encosta em " + str(r[0]))
	if Rect2i(226, 156, 188, 128).intersects(pr) or pr.end.y > 348:
		bad += 1
		report.append("cartaz fora da área livre")
	report.append("cartaz: %s em %s; %d problemas (coluna dos botões, piso y 348, 2 px de folga dos outros itens)" % [pr.size, pr.position, bad])
	return im

# ================================================================================================ prancha
func scaled(im: Image, k: int) -> Image:
	return P.scaled(im, k)

func cell(fr: Image, k: int, bg := "b0", crop := Rect2i(8, 2, 96, 100)) -> Image:
	var c: Image = L.blank(FW, FH)
	c.fill(L.col(bg))
	L.R(c, 0, int(PIV.y) + 1, FW, FH, "d1")
	c.blend_rect(fr, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	return scaled(c.get_region(crop), k)

func paste(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func titulo(im: Image, s: String, x: int, y: int, k := 2, c = "y1") -> void:
	L.text(im, s, x, y, c, k, "ink")

func nota(im: Image, lines: Array, x: int, y: int, k := 1) -> int:
	for ln in lines:
		L.text(im, ln, x, y, "cream", k, "ink")
		y += 10 * k
	return y

func prateleira(t: Image, slot: int) -> Image:
	var im: Image = L.blank(616, 56)
	im.fill(L.col("d1"))
	L.R(im, 0, 0, 616, 1, "d2")
	L.text(im, "TROFÉUS", 6, 6, "y1")
	var x0 := 162
	for i in 4:
		var nx := x0 + i * 76
		L.R(im, nx, 9, 64, 38, "ink")
		L.R(im, nx, 9, 64, 1, "d2")
		if i == slot:
			paste(im, t, nx + 32 - 22, 9 + 37 - 30)
	return im

func prancha(fr: Dictionary, bg: Image, dark_bg: Image, tro: Dictionary, poster: Image, wall: Image) -> Image:
	var W := 1340
	var im: Image = L.blank(W, 4200)
	im.fill(L.col("d1"))
	titulo(im, "RONDA 2A2 - AMOSTRA: O CHEFE APAGÃO (NÉLSON VOLT) E A ARENA DELE", 16, 12, 3)
	L.text(im, "GERADO POR CÓDIGO (tools/art/make_amostra_ronda2a2_apagao.gd). RIG DOS ADVERSÁRIOS: QUADRO 112x104, PIVÔ (56,98), VIRADO PARA A ESQUERDA. PALETA DE 45. NADA FOI PARA O JOGO AINDA.", 16, 44, "g2", 1)
	var y := 62
	# 1. arena
	titulo(im, "1. ARENA DO CHEFE: O BECO COM O POSTE, O TRANSFORMADOR, O GATO DE FIOS E A CAIXA DE LUZ (1X, POSIÇÃO DO JOGO)", 16, y)
	y += 24
	var s1 := cena(bg, fr, "guard", "idle", 0, false)
	var s2 := cena(bg, fr, "blackout", "idle", 0, true)
	paste(im, s1, 16, y)
	paste(im, s2, 16 + 660, y)
	L.text(im, "NORMAL", 22, y + 50, "white", 2, "ink")
	L.text(im, "APAGÃO (~1 S)", 22 + 660, y + 50, "white", 2, "ink")
	y += 372
	var s3 := cena(bg, fr, "heavy", "hit", 1, false)
	var s4 := cena(bg, fr, "ko", "victory", 0, false)
	var c3 := scaled(s3.get_region(Rect2i(180, 180, 320, 150)), 2)
	var c4 := scaled(s4.get_region(Rect2i(180, 180, 320, 150)), 2)
	paste(im, c3, 16, y)
	paste(im, c4, 16 + 660, y)
	L.text(im, "CHOQUE DE LONGE (2X)", 22, y + 6, "white", 2, "ink")
	L.text(im, "K.O.: APAGOU, O CAPACETE ROLOU (2X)", 22 + 660, y + 6, "white", 2, "ink")
	y += 310
	y = nota(im, ["CONTRATO: 640x360, Y 0..45 INK LISO (HUD), PÉS EM Y 318, CHÃO LIVRE X 200..440. O POSTE (X 166..200) E A CAIXA (X 371..413, Y 130..188) FICAM FORA DO",
		"CHÃO LIVRE E ACIMA DAS CABEÇAS; A PAREDE ATRÁS DOS LUTADORES CONTINUA NO MEIO-TOM DO BECO. NO APAGÃO: TUDO 2 PASSOS ABAIXO NA RAMPA, ARANDELA APAGADA,",
		"SÓ A LANTERNA (CONE), AS FAÍSCAS DA CAIXA E DO TRANSFORMADOR E AS DA BATERIA ACESAS. É SÓ APRESENTAÇÃO: A CHANCE NÃO MUDA."], 16, y) + 14
	# 2. poses
	titulo(im, "2. POSES-CHAVE NO RIG DE LUTA (3X), VIRADO PARA A ESQUERDA COMO NO JOGO", 16, y)
	y += 24
	var x := 16
	var row := 0
	for k in ORDER:
		var c: Image
		if k == "blackout":
			var base: Image = fr.blackout_base.duplicate()
			var tmp: Image = L.blank(FW, FH)
			tmp.fill(L.col("b0"))
			L.R(tmp, 0, int(PIV.y) + 1, FW, FH, "d1")
			tmp.blend_rect(base, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
			darken(tmp, 2)
			tmp.blend_rect(fr.blackout_fx, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
			c = scaled(tmp.get_region(Rect2i(8, 2, 96, 100)), 3)
		else:
			c = cell(fr[k], 3)
		paste(im, c, x, y)
		L.text(im, LABEL[k], x + 4, y + 4, "g3", 1, "ink")
		x += 298 + 30
		if x + 298 > W:
			x = 16
			y += 306
	y += 306 if x != 16 else 0
	titulo(im, "AS MESMAS EM 1X", 16, y)
	y += 22
	x = 16
	for k in ORDER:
		paste(im, cell(fr[k], 1, "b0", Rect2i(0, 0, FW, FH)), x, y)
		x += FW + 6
	# silhueta em 1x ao lado
	x += 20
	for k in ["guard", "heavy"]:
		paste(im, cell(silhueta(fr[k], "ink"), 1, "g1", Rect2i(0, 0, FW, FH)), x, y)
		x += FW + 6
	L.text(im, "SILHUETA CHAPADA", x - 2 * (FW + 6), y + FH + 4, "g3")
	y += FH + 20
	y = nota(im, ["CORPO: MAGRO E CORCUNDA, CABEÇA PROJETADA, BRAÇOS 30% MAIS COMPRIDOS QUE OS DO RIG (MESMO COMPRIMENTO EM TODOS OS QUADROS: IK DE 2 OSSOS),",
		"LUVAS DE BORRACHA GIGANTES COM CANO, BATERIA DE CARRO NAS COSTAS COM A COROA DE CABOS EM ESPIRAL E GARRAS DE JACARÉ, LANTERNA ENORME NO CAPACETE.",
		"PASSIVA (adv_slippery): MÃOS ABERTAS EMPURRANDO, ARCOS NO CORPO TODO E NAS LUVAS. K.O. SEM SANGUE: CAI DE COSTAS NA BATERIA, OLHO EM X, CABELO",
		"ARREPIADO, FUMACINHA CINZA DA BATERIA E O CAPACETE ROLA (O TROFÉU NASCE DAÍ). ATORDOADO: JOELHOS CEDEM, BRAÇOS PENDURADOS, ÓCULOS TORTOS, FAÍSCAS."], 16, y) + 14
	# 3. retrato
	titulo(im, "3. RETRATO 32X32 (HUD E DOSSIÊ, VIRADO PARA A DIREITA) E A SILHUETA DE ANTES DE VENCER", 16, y)
	y += 24
	var p1 := retrato(fr)
	var p2 := retrato(fr, true)
	paste(im, p1, 16, y)
	paste(im, p2, 56, y)
	paste(im, scaled(p1, 4), 110, y)
	paste(im, scaled(p2, 4), 250, y)
	paste(im, cell(silhueta(fr.guard_right, "ink"), 1, "d2", Rect2i(0, 0, FW, FH)), 400, y)
	L.text(im, "SILHUETA DO DOSSIÊ: SÓ A LANTERNA ACESA COMO PISTA.", 530, y + 10, "cream", 1, "ink")
	L.text(im, "CORPO INTEIRO CHAPADO (SE A FICHA USAR O CORPO).", 530, y + 22, "cream", 1, "ink")
	y += 140
	# 4. troféu
	titulo(im, "4. TROFÉU NA PRATELEIRA DO ESCONDERIJO (44X30, PIVÔ 22,29; NICHO 64X38)", 16, y)
	y += 24
	x = 16
	for k in ["normal", "rare0", "rare1"]:
		paste(im, tro[k], x, y + 50)
		paste(im, scaled(tro[k], 4), x + 54, y)
		x += 54 + 176 + 20
	L.text(im, "NORMAL: AMASSADO, LENTE RACHADA", 16, y + 124, "cream", 1, "ink")
	L.text(im, "RARO (Q0): POLIDO, LANTERNA ACESA", 16 + 250, y + 124, "cream", 1, "ink")
	L.text(im, "RARO (Q1): PISCANDO (FRACA)", 16 + 500, y + 124, "cream", 1, "ink")
	y += 140
	var sh1 := prateleira(tro.normal, 0)
	var sh2 := prateleira(tro.rare0, 1)
	paste(im, sh1, 16, y)
	paste(im, sh2, 16 + 640, y)
	y += 64
	paste(im, scaled(sh2.get_region(Rect2i(150, 0, 240, 56)), 2), 16, y)
	L.text(im, "PRATELEIRA EM 1X (MOCK DO CARTÃO; O DA TELA É O DA UI) E 2X COM O RARO NO 2º LUGAR.", 520, y + 10, "cream", 1, "ink")
	y += 126
	# 5. cartaz
	titulo(im, "5. CARTAZ NO CANTO LIVRE DA PAREDE DO MENU: 57X69 EM (444,276), LUZ DO MENU JÁ PINTADA", 16, y)
	y += 24
	paste(im, poster, 16, y)
	paste(im, scaled(poster, 4), 90, y)
	paste(im, wall, 340, y)
	L.text(im, "PAREDE COM TODOS OS MARCOS (SEM FAIXA, LOGO E BOTÕES)", 346, y + 4, "white", 1, "ink")
	y += 372
	# 6. estilo
	titulo(im, "6. ESTILO RARO \"FIO DESENCAPADO\" (SÓ COR): AMARELO COM PRETO, COMPARADO COM OS QUE JÁ EXISTEM (3X)", 16, y)
	y += 24
	x = 16
	for st in [[{}, "PADRÃO"], [{"shorts_color": "yellow"}, "CALÇÃO AMARELO (JÁ EXISTE)"], [{"shorts_color": "night"}, "CALÇÃO DA NOITE"],
			[{"shorts_color": "live_wire"}, "FIO DESENCAPADO (RECOMENDO)"], [{"headband_color": "live_wire"}, "ALTERNATIVA: SÓ NA FAIXA"]]:
		var lk := LOOK_A.duplicate()
		lk.merge(st[0], true)
		var f := compose("fight_player_idle_disc_layered", 0, lk)
		var cc := cell(f, 3, "b0", Rect2i(24, 4, 64, 96))
		paste(im, cc, x, y)
		L.text(im, st[1], x + 4, y + 4, "g3", 1, "ink")
		paste(im, cell(f, 1, "b0", Rect2i(24, 4, 64, 96)), x + 4, y + cc.get_height() + 6)
		x += cc.get_width() + 14
	y += 288 + 106
	y = nota(im, ["RECOMENDO O CALÇÃO: shorts_color live_wire = band d1 (cós preto), light y1, mid y0, dark d1, deep ink (amarelo com dobras pretas, o fio",
		"de alta-tensão), e o R da coxa em AZUL (school_symbol_source.leg.map.live_wire = blue). LÊ EM 1X E NÃO SE CONFUNDE COM O CALÇÃO AMARELO NEM COM O",
		"DA NOITE. NA FAIXA SÓ COR NÃO DÁ AS LISTRAS: FICA PERTO DA AMARELA. É UMA OPÇÃO A MAIS COM requires, COMO OS DA 2A1; NENHUM CÓDIGO NOVO."], 16, y) + 10
	return im.get_region(Rect2i(0, 0, W, y + 6))

# ================================================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	R = args[0].replace("\\", "/").trim_suffix("/") + "/"
	OUT = args[1].replace("\\", "/").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT + "pecas")
	L = load(R + "tools/art/pixel_lib.gd").new()
	P = load(R + "tools/art/personagem_lib.gd").new(L)
	M = JSON.parse_string(FileAccess.get_file_as_string(R + "assets/sprites/manifest.json"))
	PAL = M.by_data_id.disciple_palette
	var fr := frames()
	conferir(fr)
	var bg := arena_bg()
	var dbg := arena_dark_bg(bg, fr)
	var tro := {"normal": trofeu(false, 0), "rare0": trofeu(true, 0), "rare1": trofeu(true, 1)}
	var poster := cartaz()
	var wall := parede_menu(poster)
	# peças em 1x (tamanho final; ainda não vão para assets/)
	for k in ORDER:
		(fr[k] as Image).save_png(OUT + "pecas/opp_apagao_%s.png" % k)
	retrato(fr).save_png(OUT + "pecas/portrait_opp_apagao.png")
	retrato(fr, true).save_png(OUT + "pecas/portrait_opp_apagao_silhueta.png")
	bg.save_png(OUT + "pecas/arena_apagao_bg.png")
	dbg.save_png(OUT + "pecas/arena_apagao_dark_bg.png")
	tro.normal.save_png(OUT + "pecas/trophy_apagao.png")
	var rs: Image = L.blank(88, 30)
	paste(rs, tro.rare0, 0, 0)
	paste(rs, tro.rare1, 44, 0)
	rs.save_png(OUT + "pecas/trophy_apagao_rare.png")
	poster.save_png(OUT + "pecas/menu_item_apagao.png")
	fx_choque().save_png(OUT + "pecas/fx_apagao_choque.png")
	var hud := 0
	for yy in 46:
		for xx in AW:
			if bg.get_pixel(xx, yy) != L.col("ink") or dbg.get_pixel(xx, yy) != L.col("ink"):
				hud += 1
	report.append("arena: %d px fora do ink na faixa do HUD (normal + apagão)" % hud)
	prancha(fr, bg, dbg, tro, poster, wall).save_png(OUT + "ronda2a2_amostra.png")
	for k in ["guard", "heavy", "sig", "ko", "daze"]:
		cell(fr[k], 5, "b0", Rect2i(0, 0, FW, FH)).save_png(OUT + "z5_%s.png" % k)
	for l in P.log_lines:
		if String(l).begins_with("AVISO"):
			print(l)
	for l in report:
		print(l)
	print("ok ", OUT)
	quit()
