extends SceneTree
## PROTÓTIPO do novo lutador do jogador (Artista de Personagens). NÃO substitui nada do jogo.
## Diagnóstico e regras: docs/arte/personagens-diagnostico.md.
## Rodar headless a partir de uma pasta temporária com um project.godot vazio:
##   godot --headless --path <pasta_tmp> --quit-after 120 --script E:/Fightclicker/tools/art/proto_personagem.gd
## Lê (só leitura): tools/art/pixel_lib.gd (paleta/fonte), assets/sprites/** (sprites atuais, arena).
## Escreve SÓ em: docs/arte/prototipo/*.png|json e docs/arte/mockups/personagem_*.png.
##
## Como o personagem é montado (o que muda em relação a pixel_lib.character() e ao rig() da Fase 3):
##  1. Todas as partes são pintadas numa ÚNICA tela com um mapa "qual parte está em cada pixel".
##     Nada de contorno por parte. No fim: (a) onde uma parte da frente encosta numa parte de trás,
##     o pixel de trás escurece (sombra de contato), EXCETO perto das juntas ligadas (ombro, cotovelo,
##     quadril, joelho) — ali as peças se fundem; (b) contorno ink de 1 px só na silhueta externa.
##  2. Comprimentos de membro FIXOS (braço, antebraço, coxa, canela). Cotovelo e joelho saem de IK de
##     2 ossos a partir do ombro/quadril e do ponto da mão/pé — o membro nunca encolhe ou estica.
##  3. Pé ancorado pela PONTA no chão: o pé de trás levanta o calcanhar no golpe sem escorregar.
##  4. Cabeça, luvas e tênis são mapas de pixels desenhados à mão (dados). A luva tem 3 orientações
##     (para cima / diagonal / de lado) escolhidas pela direção do antebraço.
##  5. Tronco por fatias (costas/frente ao longo do eixo quadril→peito): peito, cintura, quadril,
##     regata com cava e calção com cós; giro do tronco (tw) no golpe.

const ROOT := "E:/Fightclicker/"
const SPR := ROOT + "assets/sprites/"
const OUTP := ROOT + "docs/arte/prototipo/"
const MOCK := ROOT + "docs/arte/mockups/"
const HALF := Vector2(0.5, 0.5)
const LD := Vector2(0.55, -0.83)        # luz: de cima e da frente do lutador (virado p/ direita)

var L

# ================================================================ tela com mapa de partes
var cw := 0
var ch := 0
var img: Image
var ids := PackedInt32Array()
var joints := []                         # [id_a, id_b, ponto, raio]
var log_lines := []

func canvas(w: int, h: int) -> void:
	cw = w
	ch = h
	img = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	ids = PackedInt32Array()
	ids.resize(w * h)
	ids.fill(0)
	joints = []

func put(x: int, y: int, c, id: int) -> void:
	if x < 0 or y < 0 or x >= cw or y >= ch:
		return
	img.set_pixel(x, y, L.col(c))
	ids[y * cw + x] = id

func joint(a: int, b: int, p: Vector2, r: float) -> void:
	joints.append([a, b, p + HALF, r])

func _joint_ok(a: int, b: int, p: Vector2) -> bool:
	for j in joints:
		if (j[0] == a and j[1] == b) or (j[0] == b and j[1] == a):
			if (p - j[2]).length() <= j[3]:
				return true
	return false

func _ramp_of(c: Color) -> int:
	var hx := c.to_html(false)
	if L._lookup.has(hx):
		return L._lookup[hx][0]
	return -1

## Sombra de contato entre partes + contorno externo. Devolve a imagem final.
func finish() -> Image:
	var out: Image = img.duplicate()
	var ink: Color = L.col("ink")
	for y in ch:
		for x in cw:
			var a := ids[y * cw + x]
			if a == 0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var qx: int = x + d.x
				var qy: int = y + d.y
				if qx < 0 or qy < 0 or qx >= cw or qy >= ch:
					continue
				var b := ids[qy * cw + qx]
				if b > a and not _joint_ok(a, b, Vector2(x + 0.5, y + 0.5)):
					var ca := img.get_pixel(x, y)
					var cb := img.get_pixel(qx, qy)
					var steps := -2 if _ramp_of(ca) == _ramp_of(cb) else -1
					if ca != ink:
						out.set_pixel(x, y, L.shade(ca, steps))
					break
	# contorno externo
	var res: Image = out.duplicate()
	for y in ch:
		for x in cw:
			if ids[y * cw + x] != 0:
				continue
			var hit := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var qx: int = x + d.x
				var qy: int = y + d.y
				if qx >= 0 and qy >= 0 and qx < cw and qy < ch and ids[qy * cw + qx] != 0:
					hit = true
					break
			if hit:
				res.set_pixel(x, y, ink)
	return res

# ================================================================ primitivas
## Membro afunilado a->b (raios ra/rb), com volume (bulge) de um lado e trecho de pano (cloth) no começo.
func limb(id: int, a: Vector2, b: Vector2, ra: float, rb: float, ramp: Array, o := {}) -> void:
	a += HALF
	b += HALF
	var d := b - a
	var ln := d.length()
	var dn := d / ln if ln > 0.001 else Vector2(0, 1)
	var n := Vector2(-dn.y, dn.x)
	if n.dot(LD) < 0.0:
		n = -n
	var nl := absf(n.dot(LD))
	var bul: float = o.get("bulge", 0.0)
	var bt: float = o.get("bulge_t", 0.4)
	var bw: float = o.get("bulge_w", 0.3)
	var bdir: Vector2 = o.get("bulge_dir", n)
	var bsign := 1.0 if bdir.dot(n) >= 0.0 else -1.0
	var cloth: Array = o.get("cloth", [])
	var cloth_t: float = o.get("cloth_t", -1.0)
	var cadd: float = o.get("cloth_add", 0.7)
	var rm := maxf(ra, rb) + absf(bul) + cadd + 2.0
	for y in range(int(floor(minf(a.y, b.y) - rm)), int(ceil(maxf(a.y, b.y) + rm)) + 1):
		for x in range(int(floor(minf(a.x, b.x) - rm)), int(ceil(maxf(a.x, b.x) + rm)) + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := (p - a).dot(dn) / ln if ln > 0.001 else 0.0
			var tc := clampf(t, 0.0, 1.0)
			var s := (p - a).dot(n)
			var r0 := lerpf(ra, rb, tc)
			var bump := bul * exp(-pow((tc - bt) / bw, 2.0))
			var is_cloth := cloth.size() > 0 and tc <= cloth_t
			var add := cadd if is_cloth else 0.0
			var rpos := r0 + add + (bump if bsign > 0.0 else 0.0)
			var rneg := r0 + add + (bump if bsign < 0.0 else 0.0)
			var inside := false
			if t < 0.0:
				inside = (p - a).length() <= ra + add
			elif t > 1.0:
				inside = (p - b).length() <= rb
			else:
				inside = s <= rpos and s >= -rneg
			if not inside:
				continue
			var rr := rpos if s >= 0.0 else rneg
			var u := s / maxf(rr, 0.5)
			var rp: Array = cloth if is_cloth else ramp
			var c = rp[1]
			var lv := u * (0.45 + nl)
			if lv < -0.40:
				c = rp[0]
			elif lv > 0.62 and rpos + rneg >= 4.5:
				c = rp[2]
			if is_cloth and ln > 0.001 and (cloth_t - tc) * ln < 1.0:
				c = rp[0]                                   # bainha do calção
			put(x, y, c, id)

## Mapa de pixels desenhado à mão. anchor = pixel do mapa que vai no ponto p.
func pmap(id: int, rows: Array, legend: Dictionary, p: Vector2, anchor: Vector2i) -> void:
	var x0 := int(round(p.x)) - anchor.x
	var y0 := int(round(p.y)) - anchor.y
	for j in rows.size():
		var r: String = rows[j]
		for i in r.length():
			var k := r[i]
			if k == "." or not legend.has(k):
				continue
			put(x0 + i, y0 + j, legend[k], id)

## IK de 2 ossos: devolve a junta do meio. prefer = para que lado a junta dobra.
func ik(a: Vector2, c: Vector2, l1: float, l2: float, prefer: Vector2, tag := "") -> Vector2:
	var d := c - a
	var dist := d.length()
	if dist > l1 + l2 + 0.01 and tag != "":
		log_lines.append("AVISO %s: alvo a %.1f px, membro alcança %.1f" % [tag, dist, l1 + l2])
	var dd := clampf(dist, absf(l1 - l2) + 0.01, l1 + l2 - 0.001)
	var dn := d.normalized()
	var ang := acos(clampf((l1 * l1 + dd * dd - l2 * l2) / (2.0 * l1 * dd), -1.0, 1.0))
	var e1 := a + dn.rotated(ang) * l1
	var e2 := a + dn.rotated(-ang) * l1
	return e1 if (e1 - a).dot(prefer) >= (e2 - a).dot(prefer) else e2

# ================================================================ mapas (dados de arte)
## Cabeça de perfil, virada para a direita (luta). 14x14, âncora no centro (7,7).
const HEAD_SIDE := [
	"....HHHHHH....",
	"..HHHHhhHHHH..",
	".HHHHhhhhHHHH.",
	".HHHHHHHHHHHH.",
	"HHHHHHHsssll..",
	"HHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	".HHEEssssssll.",
	".HHHsssssssss.",
	"..HSssssssss..",
	"...SSssssmSs..",
	"....SSsssss...",
	".....SSSss....",
]
## Cabeça 3/4 virada para a direita (garagem). 13x13, âncora (6,6).
const HEAD_34 := [
	"...HHHHHHH...",
	".HHHHhhhHHHH.",
	"HHHHhhhhhHHHH",
	"HHHHHHHHHHHHs",
	"HHHHsslllllll",
	"HHHSsbbsslbbl",
	"HHESsesssles.",
	"HEsSssssslll.",
	".HESssssssss.",
	".HSsssssssSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]
const HEAD_LEG := {"H": "br0", "h": "br1", "S": "sk0", "s": "sk1", "l": "sk2", "e": "ink", "b": "br0", "E": "sk0", "m": "sk0"}

## Luva velha em 3 orientações. D/M/L = r0/r1/r2 (troca de paleta continua valendo), c/g = punho, t/T = fita.
const GLOVE_UP := [   # punho para baixo, dedos para cima (guarda)
	"..MMMMM...",
	".MMMMLLLM.",
	"MMMMMMMLLM",
	"MtTMMMMMLM",
	"MtTMMMMMMM",
	"DMMMMMMMMM",
	"DMMDDDMMMM",
	"DMMMMMDMMD",
	".DDMMMMDD.",
	".gccccccg.",
	".gggggggg.",
]
const GLOVE_DIAG := [  # antebraço subindo na diagonal
	"....MMMMM..",
	"...MMMMLLM.",
	"..MMMMMMLLM",
	".MtTMMMMMLM",
	".MtTMMMMMMM",
	"DMMMMMMMMMD",
	"DMMDDDMMMD.",
	"gDMMMMDMD..",
	"cgDDMMMD...",
	".cgDDDD....",
	"..cg.......",
]
const GLOVE_SIDE := [  # braço esticado para a direita: punho à esquerda, nós dos dedos à frente
	"...MMMMMM...",
	"..MMMMMLLLM.",
	"gcMMMMMMMLLM",
	"gcMtTMMMMMLM",
	"gcMtTMMMMMMM",
	"gcMMMDDMMMMD",
	"gcDMMMMDMMMD",
	"..DDMMMMMMD.",
	"....DDDDDD..",
]
const GLOVE_ANCHOR := {"up": Vector2i(5, 5), "diag": Vector2i(5, 5), "side": Vector2i(6, 4)}

## Tênis de perfil (11 de comprimento). Âncora = ponta do pé na sola. ankle = onde a canela encaixa.
const SHOE_FLAT := ["..DMM......", ".DMMMLw....", "DMMMMMMLLD.", "DMMMMMMMMMD", "ccccccccccc"]
const SHOE_BALL := [".DM........", ".DMMw......", "..DMMMLL...", "..DDMMMMLD.", "...ccDMMMMD", ".....cccccc"]
const SHOE_34 := ["..DMM....", ".DMMLw...", "DMMMMMLD.", "DMMMMMMMD", "ccccccccc"]
const SHOE_34_BALL := [".DM......", ".DMMw....", "..DMMML..", "..DMMMMD.", "...cDMMMD", ".....cccc"]
const SHOES := {
	"flat": {"rows": SHOE_FLAT, "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0)},
	"ball": {"rows": SHOE_BALL, "toe": Vector2i(10, 5), "ankle": Vector2i(2, 0)},
	"34": {"rows": SHOE_34, "toe": Vector2i(8, 4), "ankle": Vector2i(3, 0)},
	"34ball": {"rows": SHOE_34_BALL, "toe": Vector2i(8, 5), "ankle": Vector2i(2, 0)},
}

# ================================================================ o lutador
const SKIN := ["sk0", "sk1", "sk2"]
const SKIN_FAR := ["br0", "sk0", "sk1"]
const SHIRT := ["cream", "white", "white"]
const SHORTS := ["b0", "b1", "b2"]
const SHORTS_FAR := ["b0", "b0", "b1"]
const GLOVE_NEAR := {"D": "r0", "M": "r1", "L": "r2", "c": "cream", "g": "g3", "t": "g3", "T": "cream"}
const GLOVE_FAR := {"D": "r0", "M": "r1", "L": "r1", "c": "g3", "g": "g2", "t": "g2", "T": "g3"}
const SHOE_NEAR := {"D": "d1", "M": "d2", "L": "g1", "w": "g3", "c": "cream"}
const SHOE_FAR := {"D": "d1", "M": "d1", "L": "d2", "w": "g1", "c": "g3"}

## ids = ordem de desenho (maior = mais na frente)
enum {FAR_THIGH = 1, FAR_SHIN, FAR_SHOE, FAR_UP, FAR_FORE, FAR_GLOVE, TORSO, HEAD, NEAR_THIGH, NEAR_SHIN, NEAR_SHOE, NEAR_UP, NEAR_FORE, NEAR_GLOVE}

func glove_kind(el: Vector2, hand: Vector2) -> String:
	var d := hand - el
	var ang := rad_to_deg(atan2(-d.y, d.x))
	if ang > 62.0:
		return "up"
	if ang > 24.0:
		return "diag"
	return "side"

func glove(id: int, el: Vector2, hand: Vector2, far: bool, force := "") -> String:
	var k := force if force != "" else glove_kind(el, hand)
	var rows: Array = GLOVE_UP if k == "up" else (GLOVE_DIAG if k == "diag" else GLOVE_SIDE)
	pmap(id, rows, GLOVE_FAR if far else GLOVE_NEAR, hand, GLOVE_ANCHOR[k])
	return k

## Braço: ombro -> (IK) cotovelo -> punho; o antebraço termina embaixo do punho da luva.
func arm(id_up: int, sh: Vector2, hand: Vector2, lu: float, lf: float, far: bool, tag: String, prefer := Vector2(-0.35, 1.0), r := [3.0, 2.2, 2.4, 1.7]) -> Vector2:
	var el := ik(sh, hand, lu, lf, prefer, tag)
	var ramp: Array = SKIN_FAR if far else SKIN
	var wr := el + (hand - el).normalized() * maxf((hand - el).length() - 3.5, 1.0)
	limb(id_up, sh, el, r[0], r[1], ramp, {"bulge": 0.9, "bulge_t": 0.12, "bulge_w": 0.25, "bulge_dir": Vector2(0, -1)})
	limb(id_up + 1, el, wr, r[2], r[3], ramp, {"bulge": 0.5, "bulge_t": 0.2, "bulge_w": 0.3})
	joint(id_up, id_up + 1, el, 3.2)
	return el

## Perna: quadril -> (IK) joelho -> tornozelo do tênis. Tênis ancorado pela ponta (não escorrega).
func leg(id_th: int, hip: Vector2, toe: Vector2, shoe: String, lt: float, ls: float, far: bool, tag: String, r := [4.2, 3.0, 2.7, 1.6], cloth_t := 0.42, kp := Vector2(1, -0.1)) -> void:
	var sd: Dictionary = SHOES[shoe]
	var tv: Vector2i = sd.toe
	var av: Vector2i = sd.ankle
	var ankle := toe + Vector2(av - tv)
	var knee := ik(hip, ankle, lt, ls, kp, tag)
	var skin: Array = SKIN_FAR if far else SKIN
	var cl: Array = SHORTS_FAR if far else SHORTS
	limb(id_th, hip, knee, r[0], r[1], skin, {"bulge": 0.7, "bulge_t": 0.45, "bulge_w": 0.3, "bulge_dir": Vector2(1, 0),
		"cloth": cl, "cloth_t": cloth_t, "cloth_add": 0.6})
	limb(id_th + 1, knee, ankle + Vector2(0, 1), r[2], r[3], skin, {"bulge": 1.1, "bulge_t": 0.3, "bulge_w": 0.25, "bulge_dir": Vector2(-1, 0)})
	pmap(id_th + 2, sd.rows, SHOE_FAR if far else SHOE_NEAR, toe, tv)
	joint(id_th, id_th + 1, knee, 3.6)

func _interp_slices(sl: Array, t: float) -> Vector2:
	for i in range(sl.size() - 1):
		var a: Array = sl[i]
		var b: Array = sl[i + 1]
		if t >= a[0] and t <= b[0]:
			var k: float = (t - a[0]) / maxf(b[0] - a[0], 0.0001)
			return Vector2(lerpf(a[1], b[1], k), lerpf(a[2], b[2], k))
	return Vector2(sl[0][1], sl[0][2])

## Tronco por fatias [t, costas(-), frente(+)] ao longo do eixo quadril->topo. view = "side" | "34".
func torso(id: int, hip: Vector2, top: Vector2, sl: Array, view: String, tw := 0.0) -> void:
	hip += HALF
	top += HALF
	var d := top - hip
	var ln := d.length()
	var dn := d / ln
	var fr := Vector2(-dn.y, dn.x)
	if fr.x < 0.0:
		fr = -fr
	var t0: float = sl[0][0]
	var t1: float = sl[sl.size() - 1][0]
	var ext := 12.0
	var bx0 := int(floor(minf(hip.x, top.x) - ext))
	var bx1 := int(ceil(maxf(hip.x, top.x) + ext))
	var by0 := int(floor(minf(hip.y + d.y * t1, hip.y + d.y * t0) - 4))
	var by1 := int(ceil(maxf(hip.y + d.y * t1, hip.y + d.y * t0) + 4))
	var waist := 0.24
	for y in range(by0, by1 + 1):
		for x in range(bx0, bx1 + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := (p - hip).dot(dn) / ln
			if t < t0 or t > t1:
				continue
			var s := (p - hip).dot(fr)
			var bf := _interp_slices(sl, t)
			var k := smoothstep(0.45, 0.9, t)
			var back := bf.x
			var front := bf.y
			if view == "side":
				front += tw * k
				back -= tw * 0.5 * k
			else:
				back += tw * 1.5 * k
				front += tw * 0.5 * k
			if s < back or s > front:
				continue
			var db := s - back
			var df := front - s
			var c
			if t < waist:                                    # calção
				c = SHORTS[1]
				if db < 2.0:
					c = SHORTS[0]
				elif df < 1.2:
					c = SHORTS[2]
				if view == "34" and absf(s - 0.5) < 0.6 and t < waist - 0.12:
					c = SHORTS[0]                               # costura do meio
			elif t < waist + 0.05:
				c = "b2"                                        # cós
				if db < 1.5:
					c = "b1"
			else:
				var skin := false
				if view == "side":
					skin = (t > 0.83 and df < 4.5) or t > 0.98
				else:
					var mid := (back + front) * 0.5 + 0.8
					skin = (t > 0.84 and absf(s - mid) < 3.0) or t > 1.0 or (t > 0.74 and (db < 2.2 or df < 2.2))
				if skin:
					c = SKIN[1]
					if db < 1.6:
						c = SKIN[0]
					elif df < 1.4:
						c = SKIN[2]
				else:
					c = SHIRT[1]
					if db < 2.2:
						c = SHIRT[0]
					if view == "side" and t > 0.5 and t < 0.57 and df < 3.0:
						c = SHIRT[0]                            # dobra embaixo do peito
					if view == "34" and t > 0.57 and t < 0.6 and s > 1.5 and s < front - 1.5:
						c = SHIRT[0]
					if t < waist + 0.1 and fmod(s + 20.0, 3.0) < 1.0:
						c = SHIRT[0]                            # regata franzida no cós
			put(x, y, c, id)

# ---------------------------------------------------------------- lutador de LUTA (perfil), 112x104, pivô (56,98)
const FW := 112
const FH := 104
const FPV := Vector2(56, 98)
const SL_SIDE := [[-0.2, -5.4, 3.6], [-0.1, -6.2, 4.6], [0.08, -6.0, 4.8], [0.3, -4.8, 4.2], [0.55, -5.4, 5.6],
	[0.75, -6.2, 7.0], [0.9, -6.0, 6.2], [1.0, -5.0, 4.6], [1.07, -3.5, 2.6]]
const LU := 12.0
const LF := 12.5
const LT := 17.5
const LS := 16.5

## p: hip, top(peito), head, sf, sb, hf, hb (relativos ao pivô), toef, toeb, shoeb, tw
func fight_frame(p: Dictionary, tag: String) -> Image:
	canvas(FW, FH)
	var O := FPV
	var hip: Vector2 = O + p.hip
	var top: Vector2 = O + p.top
	var nh := hip + Vector2(1.5, 1.0)
	var fh := hip + Vector2(-1.5, 1.0)
	leg(FAR_THIGH, fh, O + p.get("toeb", Vector2(-3, -1)), p.get("shoeb", "flat"), LT, LS, true, tag + " perna de trás")
	var sb: Vector2 = O + p.sb
	var hb: Vector2 = O + p.hb
	var elb := arm(FAR_UP, sb, hb, LU, LF, true, tag + " braço de trás")
	glove(FAR_GLOVE, elb, hb, true, p.get("gkb", "up"))
	torso(TORSO, hip, top, SL_SIDE, "side", p.get("tw", 0.0))
	var hd: Vector2 = O + p.head
	limb(TORSO, top + Vector2(0, 1), hd + Vector2(-1, 4), 2.6, 2.4, SKIN)   # pescoço (mesma peça do tronco)
	pmap(HEAD, HEAD_SIDE, HEAD_LEG, hd, Vector2i(7, 7))
	leg(NEAR_THIGH, nh, O + p.get("toef", Vector2(15, -1)), "flat", LT, LS, false, tag + " perna da frente")
	var sf: Vector2 = O + p.sf
	var hf: Vector2 = O + p.hf
	var elf := arm(NEAR_UP, sf, hf, LU, LF, false, tag + " braço da frente")
	var gk := glove(NEAR_GLOVE, elf, hf, false, p.get("gkf", "up"))
	joint(TORSO, NEAR_UP, sf, 4.5)
	joint(TORSO, FAR_UP, sb, 4.5)
	joint(TORSO, NEAR_THIGH, nh, 5.5)
	joint(TORSO, FAR_THIGH, fh, 5.5)
	var im := finish()
	log_lines.append("%s: luva da frente '%s', braço %.1f+%.1f, cotovelo %s" % [tag, gk, (elf - sf).length(), (hf - elf).length(), str(elf - O)])
	return im

func fpose(over: Dictionary) -> Dictionary:
	var p := {"hip": Vector2(0, -37), "top": Vector2(2, -61), "head": Vector2(5, -71),
		"sf": Vector2(4, -58), "sb": Vector2(0, -59), "hf": Vector2(16, -59), "hb": Vector2(12, -61),
		"toef": Vector2(15, -1), "toeb": Vector2(-3, -1), "shoeb": "flat", "tw": 0.0}
	for k in over:
		p[k] = over[k]
	return p

func fight_idle() -> Array:
	# mãos IGUAIS ao manifest: frente [16,-59]x2,[16,-57]x2 ; trás [12,-61]x2,[12,-59]x2
	return [
		fpose({}),
		fpose({"top": Vector2(2, -62), "head": Vector2(5, -72), "sf": Vector2(4, -59), "sb": Vector2(0, -60)}),
		fpose({"hip": Vector2(0, -36), "top": Vector2(2, -60), "head": Vector2(5, -70), "sf": Vector2(4, -57), "sb": Vector2(0, -58),
			"hf": Vector2(16, -57), "hb": Vector2(12, -59)}),
		fpose({"hip": Vector2(0, -36), "top": Vector2(2, -61), "head": Vector2(5, -71), "sf": Vector2(4, -58), "sb": Vector2(0, -59),
			"hf": Vector2(16, -57), "hb": Vector2(12, -59)}),
	]

func fight_jab() -> Array:
	# mãos IGUAIS ao manifest: frente [12,-61],[31,-61],[25,-61],[17,-59] ; trás [11,-61],[15,-61],[14,-61],[13,-61]
	return [
		fpose({"top": Vector2(1, -61), "head": Vector2(4, -71), "sf": Vector2(3, -58), "sb": Vector2(-1, -59),
			"hf": Vector2(12, -61), "hb": Vector2(11, -61), "hip": Vector2(0, -36), "gkf": "up"}),
		fpose({"hip": Vector2(1, -37), "top": Vector2(5, -61), "head": Vector2(7, -70), "sf": Vector2(6.5, -60), "sb": Vector2(2, -59), "gkf": "side",
			"hf": Vector2(31, -61), "hb": Vector2(15, -61), "shoeb": "ball", "tw": 1.2}),
		fpose({"hip": Vector2(1, -37), "top": Vector2(4, -61), "head": Vector2(6, -71), "sf": Vector2(6, -58), "sb": Vector2(1, -59),
			"hf": Vector2(25, -61), "hb": Vector2(14, -61), "shoeb": "ball", "tw": 0.6, "gkf": "diag"}),
		fpose({"top": Vector2(3, -61), "head": Vector2(5, -71), "sf": Vector2(5, -58), "sb": Vector2(0, -59),
			"hf": Vector2(17, -59), "hb": Vector2(13, -61)}),
	]

# ---------------------------------------------------------------- lutador da GARAGEM (3/4), 48x72, pivô (22,67)
const GW := 48
const GH := 72
const GPV := Vector2(22, 67)
const SL_34 := [[-0.16, -4.4, 4.8], [-0.04, -5.0, 5.4], [0.15, -4.9, 5.1], [0.32, -4.4, 4.8], [0.6, -5.8, 6.3],
	[0.82, -7.4, 7.6], [0.95, -7.2, 7.2], [1.02, -5.0, 5.2], [1.1, -2.6, 3.0]]
const GLU := 10.0
const GLF := 10.5
const GLT := 14.2
const GLS := 13.2

## Garagem: lado ESQUERDO da tela = lado perto (braço/perna de trás do golpe); DIREITO = mão da frente (soca o saco).
func garage_frame(p: Dictionary, tag: String) -> Image:
	canvas(GW, GH)
	var O := GPV
	var hip: Vector2 = O + p.hip
	var top: Vector2 = O + p.top
	var hl := hip + Vector2(-3, 0)
	var hr := hip + Vector2(3, 0)
	var shl: Vector2 = O + p.sl
	var shr: Vector2 = O + p.sr
	var hdl: Vector2 = O + p.hl
	var hdr: Vector2 = O + p.hr
	var fs: float = p.get("fs", 1.0)
	# braço direito (o da frente): parte de cima atrás do tronco
	var elr: Vector2 = (O + p.er) if p.has("er") else ik(shr, hdr, GLU * fs, GLF * fs, Vector2(0.3, 1.0), tag + " braço direito")
	limb(FAR_UP, shr, elr, 2.6, 2.0, SKIN, {"bulge": 0.8, "bulge_t": 0.12, "bulge_w": 0.25, "bulge_dir": Vector2(1, -1)})
	# pernas
	leg(FAR_THIGH, hr, O + p.get("toer", Vector2(10, 0)), "34", GLT, GLS, false, tag + " perna direita", [3.6, 2.7, 2.5, 1.5], 0.4, Vector2(0.6, 0))
	leg(NEAR_THIGH, hl, O + p.get("toel", Vector2(-1, 0)), p.get("shoel", "34"), GLT, GLS, false, tag + " perna esquerda", [3.6, 2.7, 2.5, 1.5], 0.4, Vector2(0.5, 0))
	torso(TORSO, hip, top, SL_34, "34", p.get("tw", 0.0))
	var hd: Vector2 = O + p.head
	limb(TORSO, top + Vector2(0, 1), hd + Vector2(0, 4), 2.3, 2.2, SKIN)
	pmap(HEAD, HEAD_34, HEAD_LEG, hd, Vector2i(6, 6))
	# braço esquerdo (perto da câmera) por cima do tronco
	var ell: Vector2 = (O + p.el) if p.has("el") else ik(shl, hdl, GLU, GLF, Vector2(-0.3, 1.0), tag + " braço esquerdo")
	limb(NEAR_UP, shl, ell, 2.6, 2.0, SKIN, {"bulge": 0.8, "bulge_t": 0.12, "bulge_w": 0.25, "bulge_dir": Vector2(-1, -1)})
	var wl := ell + (hdl - ell).normalized() * maxf((hdl - ell).length() - 3.5, 1.0)
	limb(NEAR_FORE, ell, wl, 2.4, 1.9, SKIN, {"bulge": 0.4, "bulge_t": 0.2, "bulge_w": 0.3})
	glove(NEAR_GLOVE, ell, hdl, true, p.get("gkl", "up"))
	# antebraço + luva direitos na frente do rosto (guarda) / esticado (golpe)
	var wr := elr + (hdr - elr).normalized() * maxf((hdr - elr).length() - 3.5, 1.0)
	limb(NEAR_GLOVE + 1, elr, wr, 2.4, 1.9, SKIN, {"bulge": 0.4, "bulge_t": 0.2, "bulge_w": 0.3})
	var gk := glove(NEAR_GLOVE + 2, elr, hdr, false, p.get("gkr", "up"))
	joint(TORSO, NEAR_UP, shl, 4.0)
	joint(TORSO, FAR_UP, shr, 4.0)
	joint(NEAR_UP, NEAR_FORE, ell, 2.6)
	joint(FAR_UP, NEAR_GLOVE + 1, elr, 2.6)
	joint(TORSO, NEAR_THIGH, hl, 5.0)
	joint(TORSO, FAR_THIGH, hr, 5.0)
	var im := finish()
	log_lines.append("%s: luva direita '%s', braço dir. %.1f+%.1f (fs %.2f)" % [tag, gk, (elr - shr).length(), (hdr - elr).length(), fs])
	return im

func gpose(over: Dictionary) -> Dictionary:
	var p := {"hip": Vector2(0, -31), "top": Vector2(1, -50), "head": Vector2(1, -57),
		"sl": Vector2(-7, -47), "sr": Vector2(8, -47), "hl": Vector2(-6, -50), "hr": Vector2(8, -51),
		"toel": Vector2(-1, 0), "toer": Vector2(10, 0), "shoel": "34", "tw": 0.0, "fs": 1.0}
	for k in over:
		p[k] = over[k]
	return p

func garage_punch() -> Array:
	# 0 guarda, 1 antecipação, 2 CONTATO (luva no saco; hit_point da sala = (323,222) = (42,17) no quadro), 3 volta
	return [
		gpose({"el": Vector2(-8, -39), "er": Vector2(8, -39)}),
		gpose({"top": Vector2(0, -49), "head": Vector2(0, -56), "sl": Vector2(-8, -46), "sr": Vector2(7, -46),
			"hl": Vector2(-6, -49), "hr": Vector2(6, -49), "el": Vector2(-8, -38), "er": Vector2(7, -38)}),
		gpose({"hip": Vector2(1, -31), "top": Vector2(2, -50), "head": Vector2(2, -56), "sl": Vector2(-6, -47), "sr": Vector2(10, -48),
			"hl": Vector2(-5, -50), "hr": Vector2(19, -49), "shoel": "34ball", "tw": 1.0, "el": Vector2(-7, -39), "er": Vector2(14, -46), "gkr": "side"}),
		gpose({"top": Vector2(1, -50), "head": Vector2(1, -57), "sr": Vector2(9, -47), "hl": Vector2(-6, -50), "hr": Vector2(15, -50), "el": Vector2(-8, -39), "er": Vector2(12, -42), "gkr": "diag"}),
	]

# ================================================================ utilidades de imagem
func strip(frames: Array) -> Image:
	var fw: int = frames[0].get_width()
	var fh: int = frames[0].get_height()
	var s: Image = L.blank(fw * frames.size(), fh)
	for i in frames.size():
		s.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	return s

func load_png(path: String) -> Image:
	var im := Image.load_from_file(path)
	im.convert(Image.FORMAT_RGBA8)
	return im

func frames_of(path: String, fw: int) -> Array:
	var s := load_png(path)
	var out := []
	for i in s.get_width() / fw:
		out.append(s.get_region(Rect2i(i * fw, 0, fw, s.get_height())))
	return out

func scaled(im: Image, k: int) -> Image:
	var b: Image = im.duplicate()
	b.resize(im.get_width() * k, im.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func paste(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func checker(dst: Image, x: int, y: int, w: int, h: int, cell: int) -> void:
	for yy in range(0, h, cell):
		for xx in range(0, w, cell):
			var c = "g1" if ((xx / cell + yy / cell) % 2 == 0) else "g0"
			L.R(dst, x + xx, y + yy, mini(cell, w - xx), mini(cell, h - yy), c)

# ================================================================ mockups
func make_before_after(new_sets: Array) -> void:
	# new_sets: [nome, frames_novos, caminho_antigo, largura_quadro, notas]
	var S := 3
	var gap := 16
	var W := 0
	var H := 70
	for e in new_sets:
		var fw: int = e[3]
		var fh: int = e[1][0].get_height()
		W = maxi(W, 150 + e[1].size() * (fw * S + gap) + 40 + e[1].size() * (fw + 4))
		H += 30 + 2 * (fh * S + 26) + 20
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "LUTADOR DO JOGADOR - ANTES x DEPOIS (3x; à direita, 1x)", 16, 14, "y1", 2, "ink")
	L.text(out, "Prototipo: tools/art/proto_personagem.gd. Mesmos quadros, pivo, hit_frame/hit_point e maos do manifest.", 16, 40, "g3", 1, "ink")
	var y := 62
	for e in new_sets:
		var nm: String = e[0]
		var nf: Array = e[1]
		var of: Array = frames_of(e[2], e[3])
		var fw: int = e[3]
		var fh: int = nf[0].get_height()
		L.text(out, nm, 16, y, "cream", 2, "ink")
		L.text(out, e[4], 16 + L.text_w(nm, 2) + 12, y + 4, "g2", 1, "ink")
		y += 26
		for row in 2:
			var fr: Array = of if row == 0 else nf
			L.text(out, "ANTES" if row == 0 else "DEPOIS", 16, y + fh * S / 2 - 6, "r3" if row == 0 else "gr3", 2, "ink")
			var x := 130
			for i in fr.size():
				checker(out, x, y, fw * S, fh * S, 12)
				paste(out, scaled(fr[i], S), x, y)
				L.text(out, str(i), x + 3, y + 3, "white", 1, "ink")
				x += fw * S + gap
			x += 20
			for i in fr.size():
				L.R(out, x, y, fw, fh, "g1")
				paste(out, fr[i], x, y)
				x += fw + 4
			y += fh * S + 26
		y += 10
	out.save_png(MOCK + "personagem_antes_depois_x3.png")

func arena_scene(pl: Image, op: Image) -> Image:
	var bg := load_png(SPR + "fight/arena_bg.png")
	var crowd := frames_of(SPR + "fight/arena_crowd_back.png", 640)
	paste(bg, crowd[0], 0, 180)
	var lamp := frames_of(SPR + "fight/arena_lamp.png", 40)
	paste(bg, lamp[0], 321 - 20, 52)
	var sh := load_png(SPR + "fight/fight_shadow.png")
	paste(bg, sh, 296 - 24, 318 - 1 - 4)
	paste(bg, sh, 346 - 24, 318 - 1 - 4)
	paste(bg, op, 346 - 56, 318 - 98)
	paste(bg, pl, 296 - 56, 318 - 98)
	var front := frames_of(SPR + "fight/arena_crowd_front.png", 640)
	paste(bg, front[0], 0, 312)
	return bg

func make_arena(new_idle: Array, new_jab: Array) -> void:
	var old_idle := frames_of(SPR + "fight/fight_player_idle.png", FW)
	var old_jab := frames_of(SPR + "fight/fight_player_jab.png", FW)
	var op_idle := frames_of(SPR + "opponents/opp_strong/opp_strong_idle.png", FW)
	var op_hit := frames_of(SPR + "opponents/opp_strong/opp_strong_hit.png", FW)
	var crop := Rect2i(206, 196, 230, 134)
	var S := 2
	var cwid := crop.size.x * S
	var chei := crop.size.y * S
	var W := 40 + 2 * cwid + 20
	var H := 60 + 2 * (chei + 40)
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "NA ARENA (2x) - contra Brutao do Posto (adversario atual)", 20, 14, "y1", 2, "ink")
	var cells := [["ANTES - guarda", old_idle[0], op_idle[0]], ["DEPOIS - guarda", new_idle[0], op_idle[0]],
		["ANTES - jab, quadro de contato", old_jab[1], op_hit[0]], ["DEPOIS - jab, quadro de contato", new_jab[1], op_hit[0]]]
	for i in 4:
		var cx := 20 + (i % 2) * (cwid + 20)
		var cy := 50 + (i / 2) * (chei + 40)
		var sc := arena_scene(cells[i][1], cells[i][2])
		var reg := sc.get_region(crop)
		paste(out, scaled(reg, S), cx, cy + 18)
		L.text(out, cells[i][0], cx, cy, "gr3" if i % 2 == 1 else "r3", 2, "ink")
		if i >= 2:   # marca o hit_point do manifest (31,-61)
			var hx := (296 + 31 - crop.position.x) * S + cx
			var hy := (318 - 61 - crop.position.y) * S + cy + 18
			L.R(out, hx - 6, hy, 4, 1, "y1"); L.R(out, hx + 3, hy, 4, 1, "y1")
			L.R(out, hx, hy - 6, 1, 4, "y1"); L.R(out, hx, hy + 3, 1, 4, "y1")
	out.save_png(MOCK + "personagem_na_arena_x2.png")

func make_jab_strip(new_idle: Array, new_jab: Array) -> void:
	var seq := [["GUARDA", new_idle[0]], ["0 ANTECIPA", new_jab[0]], ["1 CONTATO", new_jab[1]], ["2 RECOLHE", new_jab[2]],
		["3 VOLTA", new_jab[3]], ["GUARDA", new_idle[0]]]
	var S := 3
	var crop := Rect2i(26, 8, 70, 96)           # dentro do quadro 112x104
	var bg := load_png(SPR + "fight/arena_bg.png")
	var pw := crop.size.x * S
	var ph := crop.size.y * S
	var W := 20 + seq.size() * (pw + 10) + 10
	var H := 60 + ph + 30
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "JAB - tira de quadros (3x) no fundo da arena. Marcas amarelas = pontas dos pes (nao deslizam).", 20, 14, "y1", 2, "ink")
	for i in seq.size():
		var x := 20 + i * (pw + 10)
		var panel: Image = bg.get_region(Rect2i(296 - 56, 318 - 98, FW, FH))
		paste(panel, seq[i][1], 0, 0)
		var reg := panel.get_region(crop)
		paste(out, scaled(reg, S), x, 50)
		for tx in [56 + 15, 56 - 3]:
			var px: int = (tx - crop.position.x) * S + x
			L.R(out, px, 50 + ph + 2, S, 6, "y1")
		L.text(out, seq[i][0], x, 50 + ph + 12, "y1" if i == 2 else "cream", 1, "ink")
	out.save_png(MOCK + "personagem_jab_tira_x3.png")

func make_parts_debug(frame_fn: Callable) -> void:
	pass

# ================================================================ main
func _init() -> void:
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	DirAccess.make_dir_recursive_absolute(OUTP)
	var idle := []
	var i := 0
	for p in fight_idle():
		idle.append(fight_frame(p, "idle%d" % i))
		i += 1
	var jab := []
	i = 0
	for p in fight_jab():
		jab.append(fight_frame(p, "jab%d" % i))
		i += 1
	var punch := []
	i = 0
	for p in garage_punch():
		punch.append(garage_frame(p, "soco%d" % i))
		i += 1
	strip(idle).save_png(OUTP + "fight_player_idle.png")
	strip(jab).save_png(OUTP + "fight_player_jab.png")
	strip(punch).save_png(OUTP + "fighter_punch.png")
	# dados para conferência (mãos = alvos exatos usados no desenho)
	var info := {"_nota": "Protótipo. Mesmos frame_size/pivot/hit_frame/hit_point do manifest atual; mãos = centros das luvas.",
		"fight_player_idle": {"frame_size": [FW, FH], "pivot": [56, 98], "hands": []},
		"fight_player_jab": {"frame_size": [FW, FH], "pivot": [56, 98], "hit_frame": 1, "hit_point": [31, -61], "hands": []},
		"fighter_punch": {"frame_size": [GW, GH], "pivot": [22, 67], "hit_frame": 2, "hit_point_sala": [323, 222]}}
	for p in fight_idle():
		info.fight_player_idle.hands.append({"hand_front": [int(p.hf.x), int(p.hf.y)], "hand_back": [int(p.hb.x), int(p.hb.y)]})
	for p in fight_jab():
		info.fight_player_jab.hands.append({"hand_front": [int(p.hf.x), int(p.hf.y)], "hand_back": [int(p.hb.x), int(p.hb.y)]})
	var f := FileAccess.open(OUTP + "prototipo.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))
	f.close()
	make_before_after([
		["fight_player_idle", idle, SPR + "fight/fight_player_idle.png", FW, "guarda/respiração da luta (4 quadros, 6 fps)"],
		["fight_player_jab", jab, SPR + "fight/fight_player_jab.png", FW, "jab da luta (hit_frame 1)"],
		["fighter_punch", punch, SPR + "characters/fighter_punch.png", GW, "soco no saco da garagem (hit_frame 2)"],
	])
	make_arena(idle, jab)
	make_jab_strip(idle, jab)
	for l in log_lines:
		print(l)
	print("ok: protótipo gerado")
	quit()
