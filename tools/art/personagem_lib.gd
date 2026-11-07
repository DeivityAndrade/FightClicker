extends RefCounted
## personagem_lib.gd — sistema de corpo reutilizável para TODOS os personagens do Fightclicker
## (lutador do jogador, adversários, ajudantes, figurantes). Artista de Personagens.
## Padrão: .claude/skills/padrao-personagem/SKILL.md (seções 1–5b). Diagnóstico: docs/arte/personagens-diagnostico.md.
##
## Uso (num script SceneTree rodado headless a partir de uma pasta temporária):
##   var L = load(".../pixel_lib.gd").new()             # paleta, rampas, fonte
##   var P = load(".../personagem_lib.gd").new(L)
##   var b: Dictionary = P.build({...parâmetros do personagem...})   # ver build()
##   var img: Image = P.fight_frame(b, {"hip": Vector2(0,-37), "top": Vector2(2,-61), "hf": ..., "hb": ...}, "tag")
##   var img2: Image = P.garage_frame(b, {...}, "tag")
##
## Como o corpo é montado:
##  1. Tela única com MAPA DE PARTES (id por pixel; id maior = mais na frente). Nada de contorno por peça.
##     finish(): sombra de contato onde uma parte da frente encosta numa de trás (exceto perto das juntas
##     ligadas: ombro, cotovelo, quadril, joelho, que se fundem) + contorno ink de 1 px SÓ na silhueta.
##  2. Comprimentos fixos (braço, antebraço, coxa, canela) + IK de 2 ossos; avisa no log se um alvo está
##     fora do alcance (log_lines).
##  3. Pé ancorado pela PONTA (tênis em mapa de pixels; "ball" = calcanhar levantado; "up" = deitado).
##  4. Cabeça, luvas e tênis = mapas de pixels desenhados à mão (dados), com rotação/espelho exatos em
##     múltiplos de 90° (e rotação livre por vizinho mais próximo, para a cabeça no meio da queda).
##     Luva em 5 orientações desenhadas (up/diag/side/diagdown/down) + espelhos, escolhida pela direção
##     do antebraço: gira com o corpo (inclusive no K.O.).
##  5. Tronco por fatias ao longo do eixo quadril->peito (qualquer ângulo: em pé, inclinado, deitado),
##     com giro (tw), largura de ombro/quadril, barriga e roupa parametrizáveis.
##  6. Uma luz só: de cima e da frente do personagem (já pintada nos mapas; membros usam LD).

const HALF := Vector2(0.5, 0.5)
const LD := Vector2(0.55, -0.83)

## ids de profundidade (espaçados de 10 para caber camadas extras)
const FAR_THIGH := 10
const FAR_SHIN := 11
const FAR_SHOE := 12
const G_LEG_L := 13              # garagem: perna esquerda (na frente da direita, atrás do tronco)
const FAR_UP := 20
const FAR_FORE := 21
const FAR_GLOVE := 22
const TORSO := 30
const HEAD := 40
const FAR_GLOVE_FRONT := 45
const NEAR_THIGH := 50
const NEAR_SHIN := 51
const NEAR_SHOE := 52
const NEAR_UP := 60
const NEAR_FORE := 61
const NEAR_GLOVE := 62
const NEAR_GLOVE_TOP := 70

var L
var log_lines: Array = []

var cw := 0
var ch := 0
var img: Image
var ids := PackedInt32Array()
var joints: Array = []

func _init(pixel_lib) -> void:
	L = pixel_lib

# ================================================================ tela com mapa de partes
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

## Sombra de contato + contorno externo. Devolve a imagem final.
func finish() -> Image:
	var out: Image = img.duplicate()
	var ink: Color = L.col("ink")
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in ch:
		for x in cw:
			var a := ids[y * cw + x]
			if a == 0:
				continue
			for d in dirs:
				var qx: int = x + d.x
				var qy: int = y + d.y
				if qx < 0 or qy < 0 or qx >= cw or qy >= ch:
					continue
				var b := ids[qy * cw + qx]
				# só sombreia entre PARTES diferentes (a/10 diferentes = grupos diferentes, ou ids diferentes)
				if b > a and not _joint_ok(a, b, Vector2(x + 0.5, y + 0.5)):
					var ca := img.get_pixel(x, y)
					var cb := img.get_pixel(qx, qy)
					var steps := -2 if _ramp_of(ca) == _ramp_of(cb) else -1
					if ca != ink:
						out.set_pixel(x, y, L.shade(ca, steps))
					break
	var res: Image = out.duplicate()
	for y in ch:
		for x in cw:
			if ids[y * cw + x] != 0:
				continue
			for d in dirs:
				var qx: int = x + d.x
				var qy: int = y + d.y
				if qx >= 0 and qy >= 0 and qx < cw and qy < ch and ids[qy * cw + qx] != 0:
					res.set_pixel(x, y, ink)
					break
	return res

# ================================================================ primitivas
## Membro afunilado a->b (raios ra/rb), com volume (bulge) e trecho de pano (cloth) no começo (até cloth_t).
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
	var hem: bool = o.get("hem", true)
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
				inside = (p - b).length() <= rb + (add if is_cloth else 0.0)
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
			if is_cloth and hem and cloth_t < 0.999 and ln > 0.001 and (cloth_t - tc) * ln < 1.0:
				c = o.get("hem_c", rp[0])
			put(x, y, c, id)

## Gira v por ang graus (positivo = horário na tela, y para baixo).
func rotv(v: Vector2, ang: float) -> Vector2:
	if is_zero_approx(fmod(ang, 360.0)):
		return v
	var r := deg_to_rad(ang)
	var c := cos(r)
	var s := sin(r)
	var x := v.x * c - v.y * s
	var y := v.x * s + v.y * c
	return Vector2(snappedf(x, 0.0001), snappedf(y, 0.0001))

## Mapa de pixels desenhado à mão. anchor = pixel do mapa que vai no ponto p.
## ang = rotação em graus (exata em múltiplos de 90), flip = espelho horizontal do mapa antes de girar.
func pmap(id: int, rows: Array, legend: Dictionary, p: Vector2, anchor: Vector2i, ang := 0.0, flip := false) -> void:
	var h := rows.size()
	var w := 0
	for r in rows:
		w = maxi(w, (r as String).length())
	var ax := anchor.x
	if flip:
		ax = w - 1 - anchor.x
	var px := int(round(p.x))
	var py := int(round(p.y))
	if is_zero_approx(fmod(ang, 360.0)):
		for j in h:
			var r: String = rows[j]
			for i in w:
				var si := (w - 1 - i) if flip else i
				if si >= r.length():
					continue
				var k := r[si]
				if k == "." or not legend.has(k):
					continue
				put(px - ax + i, py - anchor.y + j, legend[k], id)
		return
	var rad := maxi(w, h) + 2
	for y in range(py - rad, py + rad + 1):
		for x in range(px - rad, px + rad + 1):
			var v := Vector2(x - px, y - py)
			var s := rotv(v, -ang)
			var i := int(round(s.x)) + ax
			var j := int(round(s.y)) + anchor.y
			if j < 0 or j >= h or i < 0 or i >= w:
				continue
			var r: String = rows[j]
			var si := (w - 1 - i) if flip else i
			if si < 0 or si >= r.length():
				continue
			var k := r[si]
			if k == "." or not legend.has(k):
				continue
			put(x, y, legend[k], id)

## IK de 2 ossos: devolve a junta do meio. prefer = para que lado a junta dobra.
func ik(a: Vector2, c: Vector2, l1: float, l2: float, prefer: Vector2, tag := "") -> Vector2:
	var d := c - a
	var dist := d.length()
	if dist > l1 + l2 + 0.05 and tag != "":
		log_lines.append("AVISO %s: alvo a %.1f px, membro alcança %.1f" % [tag, dist, l1 + l2])
	var dd := clampf(dist, absf(l1 - l2) + 0.01, l1 + l2 - 0.001)
	var dn := d.normalized() if dist > 0.001 else Vector2(0, 1)
	var ang := acos(clampf((l1 * l1 + dd * dd - l2 * l2) / (2.0 * l1 * dd), -1.0, 1.0))
	var e1 := a + dn.rotated(ang) * l1
	var e2 := a + dn.rotated(-ang) * l1
	return e1 if (e1 - a).dot(prefer) >= (e2 - a).dot(prefer) else e2

# ================================================================ mapas (dados de arte)
## Cabeça de perfil virada para a direita (luta). 14x14, âncora (7,7).
## H/h cabelo, S/s/l pele (sombra/base/luz), E orelha, e olho (ink), b sobrancelha, m boca, x pixel de expressão (ink)
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
## Expressões = linhas trocadas no mapa de perfil.
const FACES_SIDE := {
	"normal": {},
	"pain": {5: "HHHHHHsbbssl..", 6: "HHHEEssxxssl..", 10: "..HSsssssxss..", 11: "...SSsssxxSs.."},
	"tired": {5: "HHHHHHsssbbl..", 6: "HHHEEssssesl..", 11: "...SSssssxSs..", 12: "....SSsssxs..."},
	"ko": {5: "HHHHHHsssssl..", 6: "HHHEEsssxxsl..", 11: "...SSssssxSs..", 12: "....SSsssxs..."},
	"joy": {4: "HHHHHHHsbbbl..", 5: "HHHHHHssssll..", 11: "...SSsssxxxs..", 12: "....SSssxxs..."},
}
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
const FACES_34 := {
	"normal": {},
	"effort": {5: "HHHSsbbsslbbl", 10: "..Sssxxxxss..", 11: "...SSsssss..."},
}

## Luvas (5 orientações). D/M/L = r0/r1/r2 da luva (a troca de paleta continua valendo),
## c/g = punho (claro/escuro), t/T = fita de remendo (só a luva velha; nas outras vira detalhe do estilo).
const GLOVE_UP := [   # antebraço subindo (guarda): punho embaixo
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
const GLOVE_DIAG := [  # antebraço subindo na diagonal para a frente
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
const GLOVE_SIDE := [  # antebraço na horizontal para a frente: punho atrás, nós dos dedos à frente
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
const GLOVE_DIAGDOWN := [  # antebraço descendo na diagonal para a frente
	"..cg.......",
	".cgMMLL....",
	"cgMMMMLLM..",
	"gMMMMMMMLM.",
	"DMMMMMMMMLD",
	"DMMtTMMMMMD",
	".MMtTMMMMMD",
	".DMMMMDMMMD",
	"..DMMMMMMD.",
	"...DDMMMD..",
	"....DDDD...",
]
const GLOVE_DOWN := [  # braço caído: punho em cima, punho fechado embaixo
	".gggggggg.",
	".gccccccg.",
	".MMMMMLLM.",
	"MMMMMMMLLM",
	"DMtTMMMMLM",
	"DMtTMMMMMM",
	"DMMMMMMMMM",
	"DMMDDMMMMD",
	"DDMMMMMMMD",
	".DDMMMMDD.",
	"..DDDDDD..",
]
const GLOVES_MAPS := {"up": GLOVE_UP, "diag": GLOVE_DIAG, "side": GLOVE_SIDE, "diagdown": GLOVE_DIAGDOWN, "down": GLOVE_DOWN}
const GLOVE_ANCHOR := {"up": Vector2i(5, 5), "diag": Vector2i(5, 5), "side": Vector2i(6, 4), "diagdown": Vector2i(5, 5), "down": Vector2i(5, 5)}

## Estilos de luva (mesmas cores e detalhes da loja/cursor de make_sprites_fase3.gd).
const GLOVE_STYLES := {
	"old": {"c": "cream", "g": "g3"},
	"lona": {"c": "white", "g": "g3"},
	"couro": {"c": "cream", "g": "br3"},
	"marca": {"c": "white", "g": "g1"},
	"tape": {"c": "g3", "g": "g2"},
	"worn": {"c": "g3", "g": "g2"},
	"tape_red": {"c": "g2", "g": "g1", "w": "r2"},   # Brutão: luva preta remendada com fita isolante vermelha
	"plain": {"c": "g3", "g": "g1"},
}

## Punho nu (ajudantes sem luva). S/s/l = pele sombra/base/luz. Âncora (2,2). "up" = nós dos dedos para cima,
## "side" = nós dos dedos para a frente (soco). Escolhido pela direção do antebraço como a luva.
const FIST_UP := [".sll.", "sslll", "Sssss", "SSsss", ".SSS."]
const FIST_SIDE := [".ssl.", "Sssll", "Ssssl", "SSsss", ".SSS."]

## Tênis de perfil. toe = ponta do pé na sola (âncora); ankle = onde a canela encaixa.
const SHOE_FLAT := ["..DMM......", ".DMMMLw....", "DMMMMMMLLD.", "DMMMMMMMMMD", "ccccccccccc"]
const SHOE_BALL := [".DM........", ".DMMw......", "..DMMMLL...", "..DDMMMMLD.", "...ccDMMMMD", ".....cccccc"]
const SHOE_34 := ["..DMM....", ".DMMLw...", "DMMMMMLD.", "DMMMMMMMD", "ccccccccc"]
const SHOE_34_BALL := [".DM......", ".DMMw....", "..DMMML..", "..DMMMMD.", "...cDMMMD", ".....cccc"]
const SHOES := {
	"flat": {"rows": SHOE_FLAT, "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0), "ang": 0.0},
	"ball": {"rows": SHOE_BALL, "toe": Vector2i(10, 5), "ankle": Vector2i(2, 0), "ang": 0.0},
	"up": {"rows": SHOE_FLAT, "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0), "ang": -90.0},   # deitado, ponta para cima
	"34": {"rows": SHOE_34, "toe": Vector2i(8, 4), "ankle": Vector2i(3, 0), "ang": 0.0},
	"34ball": {"rows": SHOE_34_BALL, "toe": Vector2i(8, 5), "ankle": Vector2i(2, 0), "ang": 0.0},
}

## Fatias do tronco [t, costas(-), frente(+)] (t=0 quadril, t=1 base do pescoço) — corpo do lutador do jogador.
const SL_SIDE := [[-0.2, -5.4, 3.6], [-0.1, -6.2, 4.6], [0.08, -6.0, 4.8], [0.3, -4.8, 4.2], [0.55, -5.4, 5.6],
	[0.75, -6.2, 7.0], [0.9, -6.0, 6.2], [1.0, -5.0, 4.6], [1.07, -3.5, 2.6]]
const SL_34 := [[-0.16, -4.4, 4.8], [-0.04, -5.0, 5.4], [0.15, -4.9, 5.1], [0.32, -4.4, 4.8], [0.6, -5.8, 6.3],
	[0.82, -7.4, 7.6], [0.95, -7.2, 7.2], [1.02, -5.0, 5.2], [1.1, -2.6, 3.0]]

# ================================================================ personagem (parâmetros)
## build(o): devolve o dicionário completo do personagem. Chaves aceitas (todas opcionais):
##  medidas LUTA (perfil):  lu, lf (braço/antebraço até o centro da luva), lt, ls (coxa/canela),
##                          arm_r [ombro, cotovelo, cotovelo, punho], leg_r [quadril, joelho, joelho, tornozelo]
##  medidas GARAGEM (3/4):  glu, glf, glt, gls, g_arm_r, g_leg_r
##  silhueta:               shoulder (x largura do peito/ombro), hip_w (x largura do quadril), belly (px a mais
##                          na barriga), sl_side/sl_34 (fatias próprias, substitui as do jogador)
##  cabeça:                 head_side/head_34 (mapas próprios), faces_side, faces_34, head_anchor_side/_34,
##                          hair [escuro, claro], brow, skin [sombra, base, luz], stubble (cor), mustache (cor),
##                          headband (cor), cap [d, m, l]
##  roupa:                  top "tank"|"tshirt"|"none", shirt [sombra, base, luz], sleeve_t (0..1 do braço),
##                          bottom "shorts"|"pants", shorts [d, m, l], band (cós), shorts_t (0..1 da coxa),
##                          shoes [D, M, L, w, c] (sola = c), socks (cor da meia; "" = sem)
##                          sleeve_long (manga até o punho), trim (cor da gola/barra da manga), belt [d, m, l, fivela]
##                          (cinturão de pano na cintura), grease (manchas na roupa), shirt_detail "social"|"zip"
##                          (botões+colarinho / zíper do agasalho), shoe_maps {tipo: {rows, toe, ankle, ang}} (calçado
##                          próprio: chinelo, bota, tênis de cadarço solto)
##  luva:                   glove "old"|"lona"|"couro"|"marca"|"tape"|"worn"|"tape_red"|"plain"|"fist"(punho nu)|"none",
##                          glove_ramp [r0, r1, r2]
##  quimono (Fase 5, opcionais; ausentes = resultado idêntico aos anteriores): shirt_detail "gi" (lapela),
##                          neck_v (0..0,3: decote em V), sleeve_add / sleeve_add_fore (manga larga),
##                          pants_add (calça larga), pants_shin_t (0..1: barra da calça na canela)
##  cabeça extra:           head_legend_extra {letra: cor} (chaves livres nos mapas próprios; Q/q = capuz na cor da roupa)
## Ganchos de pose (adereços desenhados na ordem certa de profundidade): "after_torso", "after_near_leg", "end" =
##  Callable(lib, O, ctx) — ctx traz hip, top, dn, fr, hd, sf, sb, hf, hb, elf, elb (luta) ou equivalentes da garagem.
func build(o := {}) -> Dictionary:
	var b := {
		"lu": 12.0, "lf": 13.0, "lt": 17.5, "ls": 16.5,
		"arm_r": [3.0, 2.2, 2.4, 1.7], "leg_r": [4.2, 3.0, 2.7, 1.6],
		"glu": 10.0, "glf": 10.5, "glt": 14.2, "gls": 13.2,
		"g_arm_r": [2.6, 2.0, 2.4, 1.9], "g_leg_r": [3.6, 2.7, 2.5, 1.5],
		"shoulder": 1.0, "hip_w": 1.0, "belly": 0.0,
		"sl_side": SL_SIDE, "sl_34": SL_34,
		"head_side": HEAD_SIDE, "head_34": HEAD_34, "faces_side": FACES_SIDE, "faces_34": FACES_34,
		"head_anchor_side": Vector2i(7, 7), "head_anchor_34": Vector2i(6, 6),
		"hair": ["br0", "br1"], "brow": "br0", "skin": ["sk0", "sk1", "sk2"],
		"stubble": "", "mustache": "", "headband": "", "cap": [],
		"top": "tank", "shirt": ["g3", "cream", "white"], "sleeve_t": 0.45,
		"bottom": "shorts", "shorts": ["b0", "b1", "b2"], "band": "b2", "shorts_t": 0.42,
		"shoes": ["d1", "d2", "g1", "g3", "cream"], "socks": "",
		"glove": "old", "glove_ramp": ["r0", "r1", "r2"],
		"head_legend_extra": {}, "sleeve_long": false, "trim": "", "belt": [], "grease": false,
		"shirt_detail": "", "shoe_maps": {},
	}
	for k in o:
		b[k] = o[k]
	# rampas derivadas (lado de trás = um tom abaixo)
	var sk: Array = b.skin
	b["skin_far"] = [L.shade(L.col(sk[0]), -1), sk[0], sk[1]]
	var shr: Array = b.shorts
	b["shorts_far"] = [L.shade(L.col(shr[0]), -1), shr[0], shr[1]]
	var sh: Array = b.shirt
	b["shirt_far"] = [L.shade(L.col(sh[0]), -1), sh[0], sh[1]]
	var so: Array = b.shoes
	b["shoe_near"] = {"D": so[0], "M": so[1], "L": so[2], "w": so[3], "c": so[4]}
	b["shoe_far"] = {"D": so[0], "M": so[0], "L": so[1], "w": so[2], "c": L.shade(L.col(so[4]), -1)}
	b["sl_side_eff"] = _shape_slices(b.sl_side, b, false)
	b["sl_34_eff"] = _shape_slices(b.sl_34, b, true)
	b["_glove_cache"] = {}
	return b

func _shape_slices(sl: Array, b: Dictionary, sym: bool) -> Array:
	var out := []
	var shm: float = b.shoulder
	var hpm: float = b.hip_w
	var bel: float = b.belly
	for e in sl:
		var t: float = e[0]
		var m := lerpf(hpm, shm, smoothstep(0.3, 0.75, t))
		var bk: float = e[1] * m
		var fr: float = e[2] * m
		var bb := bel * exp(-pow((t - 0.3) / 0.2, 2.0))
		if sym:
			fr += bb * 0.7
			bk -= bb * 0.3
		else:
			fr += bb
		out.append([t, bk, fr])
	return out

# ---------------------------------------------------------------- legendas
func head_legend(b: Dictionary) -> Dictionary:
	var sk: Array = b.skin
	var hr: Array = b.hair
	var lg := {"H": hr[0], "h": hr[1], "S": sk[0], "s": sk[1], "l": sk[2], "e": "ink", "b": b.brow, "E": sk[0], "m": sk[0], "x": "ink",
		"B": b.headband if b.headband != "" else hr[0], "u": b.stubble if b.stubble != "" else sk[0],
		"o": b.mustache if b.mustache != "" else sk[1]}
	if (b.cap as Array).size() == 3:
		lg["C"] = b.cap[0]; lg["c"] = b.cap[1]; lg["k"] = b.cap[2]
	# capuz/gola atrás da nuca (Q/q = roupa sombra/base) e chaves livres do personagem
	lg["Q"] = b.shirt[0]
	lg["q"] = b.shirt[1]
	var ex: Dictionary = b.head_legend_extra
	for k in ex:
		lg[k] = ex[k]
	return lg

## Linhas da cabeça com expressão + acessórios (faixa, barba, bigode).
func head_rows(b: Dictionary, view: String, face: String) -> Array:
	var base: Array = (b.head_side if view == "side" else b.head_34).duplicate()
	var faces: Dictionary = b.faces_side if view == "side" else b.faces_34
	var ov: Dictionary = faces.get(face, {})
	for k in ov:
		base[int(k)] = ov[k]
	if b.headband != "":
		var row := 3 if view == "side" else 3
		var r: String = base[row]
		var nr := ""
		for ch2 in r:
			nr += "B" if ch2 in ["H", "h", "s", "l", "S"] else ch2
		base[row] = nr
	if b.stubble != "":
		for j in range(base.size() - 4, base.size()):
			var r: String = base[j]
			var nr := ""
			for i in r.length():
				var c := r[i]
				nr += "u" if (c in ["s", "S"] and (i + j) % 2 == 0) else c
			base[j] = nr
	if b.mustache != "" and view == "side":
		var r: String = base[10]
		base[10] = r.substr(0, 9) + "oo" + r.substr(11)
	return base

func glove_legend(style: String, ramp: Array, far: bool) -> Dictionary:
	var st: Dictionary = GLOVE_STYLES.get(style, GLOVE_STYLES["old"])
	var lg := {"D": ramp[0], "M": ramp[1], "L": ramp[2], "c": st.c, "g": st.g, "t": "g3", "T": "cream",
		"s": "cream", "y": "y1", "w": st.get("w", "white"), "Q": ramp[0]}
	if far:
		lg["L"] = ramp[1]
		for k in ["c", "g", "t", "T", "s", "y", "w"]:
			lg[k] = L.shade(L.col(lg[k]), -1)
	return lg

## Linhas da luva já com o detalhe do estilo (fita, trama de lona, costura, listra da marca).
func glove_rows(kind: String, style: String) -> Array:
	var src: Array = GLOVES_MAPS[kind]
	var out := []
	var h := src.size()
	var w := 0
	for r in src:
		w = maxi(w, (r as String).length())
	for j in h:
		var r: String = src[j]
		var nr := ""
		for i in r.length():
			var c := r[i]
			if style != "old" and c in ["t", "T"]:
				c = "M"
			var body := c in ["M", "L"]
			match style:
				"lona":
					if body and j % 3 == 1 and (i + j) % 3 == 0:
						c = "Q"
				"couro":
					if body and i == w - 4 and j % 2 == 0 and j > 0:
						c = "s"
				"marca":
					if body and (i + j == (w + h) / 2 - 1 or i + j == (w + h) / 2):
						c = "y"
				"tape":
					if body and (j == 3 or j == 4):
						c = "w"
				"tape_red":   # duas tiras de fita, uma torta, sem cobrir a luva inteira
					if body and ((j == 3 and i > 1 and i < w - 2) or (j == 4 and i > 2 and i < w - 3) or (i + j == w - 1 and j > 4 and j < h - 3)):
						c = "w"
			nr += c
		out.append(nr)
	return out

## Escolhe a orientação da luva pela direção do antebraço (cotovelo -> mão). Devolve [tipo, espelho].
func glove_kind(el: Vector2, hand: Vector2) -> Array:
	var d := hand - el
	var a := rad_to_deg(atan2(-d.y, d.x))
	var flip := false
	if a > 90.0 or a < -90.0:
		flip = true
		a = 180.0 - a if a > 0.0 else -180.0 - a
	if a > 62.0:
		return ["up", flip]
	if a > 24.0:
		return ["diag", flip]
	if a > -24.0:
		return ["side", flip]
	if a > -62.0:
		return ["diagdown", flip]
	return ["down", flip]

func draw_glove(id: int, b: Dictionary, el: Vector2, hand: Vector2, far: bool, force := "") -> String:
	if b.glove == "none":
		return "none"
	var kf := glove_kind(el, hand)
	var k: String = kf[0]
	var flip: bool = kf[1]
	if force != "":
		var parts := force.split(":")
		k = parts[0]
		flip = parts.size() > 1 and parts[1] == "f"
	if b.glove == "fist":
		var sk: Array = b.skin_far if far else b.skin
		var fk := "side" if k in ["side", "diagdown", "diag"] else "up"
		pmap(id, FIST_SIDE if fk == "side" else FIST_UP, {"S": sk[0], "s": sk[1], "l": sk[2]}, hand, Vector2i(2, 2), 0.0, flip)
		return "fist_" + fk + (":f" if flip else "")
	var key := "%s|%s" % [k, b.glove]
	var cache: Dictionary = b._glove_cache
	if not cache.has(key):
		cache[key] = glove_rows(k, b.glove)
	pmap(id, cache[key], glove_legend(b.glove, b.glove_ramp, far), hand, GLOVE_ANCHOR[k], 0.0, flip)
	return k + (":f" if flip else "")

## Luva solta (para ícones/testes): imagem com contorno.
func glove_image(b: Dictionary, kind: String, far := false) -> Image:
	canvas(16, 16)
	pmap(1, glove_rows(kind, b.glove), glove_legend(b.glove, b.glove_ramp, far), Vector2(8, 8), GLOVE_ANCHOR[kind])
	return finish()

# ================================================================ peças do corpo
## Braço: ombro -> (IK) cotovelo -> punho; o antebraço termina embaixo do punho da luva.
func arm(b: Dictionary, id_up: int, sh: Vector2, hand: Vector2, lu: float, lf: float, far: bool, tag: String, prefer: Vector2, r: Array, elbow = null) -> Vector2:
	var el: Vector2 = elbow if elbow != null else ik(sh, hand, lu, lf, prefer, tag)
	var ramp: Array = b.skin_far if far else b.skin
	var wr := el + (hand - el).normalized() * maxf((hand - el).length() - 3.5, 1.0)
	var o := {"bulge": 0.9, "bulge_t": 0.12, "bulge_w": 0.25, "bulge_dir": Vector2(0, -1)}
	if b.top == "tshirt":
		o["cloth"] = b.shirt_far if far else b.shirt
		o["cloth_t"] = 1.0 if b.sleeve_long else b.sleeve_t
		o["cloth_add"] = b.get("sleeve_add", 0.6)   # manga larga (quimono); padrão 0,6 = todos os anteriores
		o["hem"] = not b.sleeve_long
		if b.trim != "":
			o["hem_c"] = b.trim
	limb(id_up, sh, el, r[0], r[1], ramp, o)
	var long_sleeve: bool = b.top == "tshirt" and b.sleeve_long
	# Manga comprida (moletom): o pano não afina como o pulso e entra inteiro no punho da luva. Sem isso a
	# ponta do antebraço (pele, 1-2 px mais fina) aparecia entre a manga e o punho e a sombra de contato
	# desenhava uma linha escura ali: a luva parecia descolada da manga (QA fase 4, O3).
	var rw: float = maxf(r[3], r[2] * 0.95) if long_sleeve else r[3]
	limb(id_up + 1, el, wr, r[2], rw, ramp, forearm_opts(b, far))
	joint(id_up, id_up + 1, el, 3.2)
	if long_sleeve:
		# manga e punho da luva se encostam sem sombra de contato (o punho já tem a borda escura dele)
		joint(id_up + 1, id_up + 2, wr, 4.5)
		if far:
			joint(id_up + 1, FAR_GLOVE_FRONT, wr, 4.5)
	return el

## Antebraço: pele, ou manga comprida até o punho da luva (inclusive a ponta arredondada).
func forearm_opts(b: Dictionary, far: bool) -> Dictionary:
	var o := {"bulge": 0.5, "bulge_t": 0.2, "bulge_w": 0.3}
	if b.top == "tshirt" and b.sleeve_long:
		o = {"bulge": 0.3, "bulge_t": 0.3, "bulge_w": 0.3, "cloth": b.shirt_far if far else b.shirt, "cloth_t": 1.0, "cloth_add": b.get("sleeve_add_fore", 0.5)}
	return o

## Perna: quadril -> (IK) joelho -> tornozelo do tênis. Tênis ancorado pela ponta (não escorrega).
func leg(b: Dictionary, id_th: int, hip: Vector2, toe: Vector2, shoe: String, lt: float, ls: float, far: bool, tag: String, r: Array, kp: Vector2) -> Vector2:
	var sm: Dictionary = b.shoe_maps
	var sd: Dictionary = sm[shoe] if sm.has(shoe) else SHOES[shoe]
	var tv: Vector2i = sd.toe
	var av: Vector2i = sd.ankle
	var ang: float = sd.ang
	var ankle := toe + rotv(Vector2(av - tv), ang)
	var knee := ik(hip, ankle, lt, ls, kp, tag)
	var skin: Array = b.skin_far if far else b.skin
	var cl: Array = b.shorts_far if far else b.shorts
	var pants: bool = b.bottom == "pants"
	limb(id_th, hip, knee, r[0], r[1], skin, {"bulge": 0.7, "bulge_t": 0.45, "bulge_w": 0.3, "bulge_dir": Vector2(1, 0),
		"cloth": cl, "cloth_t": 1.0 if pants else float(b.shorts_t), "cloth_add": b.get("pants_add", 0.6)})
	var down := rotv(Vector2(0, 1), ang)
	var so := {"bulge": 1.1, "bulge_t": 0.3, "bulge_w": 0.25, "bulge_dir": Vector2(-1, 0)}
	if pants:
		# pants_shin_t < 1 = barra acima do tornozelo (calça de quimono); padrão 1,0 e 0,6 = todos os anteriores
		so = {"cloth": cl, "cloth_t": b.get("pants_shin_t", 1.0), "cloth_add": b.get("pants_add", 0.6)}
	elif b.socks != "":
		so["cloth"] = [L.shade(L.col(b.socks), -1), b.socks, b.socks]
		so["cloth_t"] = 2.0
	limb(id_th + 1, knee, ankle + down, r[2], r[3], skin, so)
	if b.socks != "" and not pants:
		pass
	pmap(id_th + 2, sd.rows, b.shoe_far if far else b.shoe_near, toe, tv, ang)
	joint(id_th, id_th + 1, knee, 3.6)
	return knee

func _interp_slices(sl: Array, t: float) -> Vector2:
	for i in range(sl.size() - 1):
		var a: Array = sl[i]
		var c: Array = sl[i + 1]
		if t >= a[0] and t <= c[0]:
			var k: float = (t - a[0]) / maxf(c[0] - a[0], 0.0001)
			return Vector2(lerpf(a[1], c[1], k), lerpf(a[2], c[2], k))
	return Vector2(sl[0][1], sl[0][2])

## Tronco por fatias ao longo do eixo quadril->topo (qualquer ângulo). view = "side" | "34".
## A "frente" é sempre o eixo girado 90° no sentido horário (em pé virado à direita = direita; deitado de
## costas com a cabeça à esquerda = para cima).
func torso(b: Dictionary, id: int, hip: Vector2, top: Vector2, view: String, tw := 0.0) -> void:
	var sl: Array = b.sl_side_eff if view == "side" else b.sl_34_eff
	hip += HALF
	top += HALF
	var d := top - hip
	var ln := d.length()
	var dn := d / ln
	var fr := Vector2(-dn.y, dn.x)
	var t0: float = sl[0][0]
	var t1: float = sl[sl.size() - 1][0]
	var ext := 14.0
	var p0 := hip + d * t0
	var p1 := hip + d * t1
	var bx0 := int(floor(minf(p0.x, p1.x) - ext))
	var bx1 := int(ceil(maxf(p0.x, p1.x) + ext))
	var by0 := int(floor(minf(p0.y, p1.y) - ext))
	var by1 := int(ceil(maxf(p0.y, p1.y) + ext))
	var waist := 0.24
	var shirt: Array = b.shirt
	var skn: Array = b.skin
	var sho: Array = b.shorts
	var top_kind: String = b.top
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
			if t < waist:
				c = sho[1]
				if db < 2.0:
					c = sho[0]
				elif df < 1.2:
					c = sho[2]
				if view == "34" and absf(s - 0.5) < 0.6 and t < waist - 0.12:
					c = sho[0]
			elif t < waist + 0.05:
				c = b.band
				if db < 1.5:
					c = sho[1]
			else:
				var skin := false
				if top_kind == "none":
					skin = true
				elif view == "side":
					if top_kind == "tank":
						skin = (t > 0.83 and df < 4.5) or t > 0.98
					else:
						skin = (t > 0.93 and df < 3.0) or t > 1.0
						var nv: float = b.get("neck_v", 0.0)   # decote em V (quimono aberto no peito); 0 = todos os anteriores
						if nv > 0.0 and t > 1.0 - nv and df < (t - (1.0 - nv)) / nv * 4.0:
							skin = true
				else:
					var mid := (back + front) * 0.5 + 0.8
					if top_kind == "tank":
						skin = (t > 0.84 and absf(s - mid) < 3.0) or t > 1.0 or (t > 0.74 and (db < 2.2 or df < 2.2))
					else:
						skin = (t > 0.92 and absf(s - mid) < 2.4) or t > 1.02
				if skin:
					c = skn[1]
					if db < 1.6:
						c = skn[0]
					elif df < 1.4 or (top_kind == "none" and t > 0.55 and t < 0.8 and df < 3.0):
						c = skn[2]
					if top_kind == "none" and t > 0.5 and t < 0.54 and df < 4.0:
						c = skn[0]                                  # linha do peitoral
				else:
					# regata/camiseta: sombra nas costas, base creme, luz no peito (nada de bloco branco)
					c = shirt[1]
					if db < 2.4:
						c = shirt[0]
					elif view == "side" and df < 3.2 and t > 0.55 and t < 0.86:
						c = shirt[2]                                # peito pegando luz
					elif view == "34" and s > mid_34(back, front) and t > 0.55 and t < 0.84 and df > 1.5:
						c = shirt[2]
					if view == "side" and t > 0.5 and t < 0.555 and df < 3.5:
						c = shirt[0]                                # dobra embaixo do peito
					if view == "side" and t > 0.32 and t < 0.5 and absf(df - 2.5) < 0.5:
						c = shirt[0]                                # vinco lateral
					if view == "34" and t > 0.57 and t < 0.6 and s > 1.5 and s < front - 1.5:
						c = shirt[0]
					if t < waist + 0.1 and fmod(s + 20.0, 3.0) < 1.0 and top_kind == "tank":
						c = shirt[0]                                # regata franzida no cós
					elif t < waist + 0.1 and fmod(s + 20.0, 3.0) < 1.0 and b.belt.is_empty():
						c = shirt[0]
					c = _shirt_detail(b, view, t, s, back, front, db, df, c)
			if not (b.belt as Array).is_empty() and t > waist - 0.05 and t < waist + 0.12:
				c = _belt_px(b, view, t, s, back, front, db, df, waist)
			put(x, y, c, id)

## Detalhes da roupa por cima da cor base (gola colorida, botões, zíper, manchas de graxa).
func _shirt_detail(b: Dictionary, view: String, t: float, s: float, back: float, front: float, db: float, df: float, c):
	var shirt: Array = b.shirt
	var mid := mid_34(back, front)
	if b.trim != "":
		if view == "side" and t > 0.9 and t < 0.97 and df < 4.0:
			return b.trim
		if view == "34" and t > 0.9 and t < 0.96 and absf(s - mid) < 3.4:
			return b.trim
	match b.shirt_detail:
		"social":   # carcela com botões + colarinho
			if view == "34":
				if absf(s - (mid - 0.5)) < 0.55 and t > 0.3 and t < 0.92:
					return shirt[0] if int(t * 40.0) % 3 != 0 else "g3"
				if t > 0.9 and absf(s - mid) < 3.6 and absf(s - mid) > 1.6:
					return shirt[2]
			elif df < 1.0 and t > 0.3 and t < 0.9 and int(t * 40.0) % 3 == 0:
				return "g3"
		"zip":      # agasalho: zíper claro no meio, gola alta
			if view == "34" and absf(s - (mid - 0.5)) < 0.55 and t > 0.28:
				return "g3"
			if view == "side" and df < 1.0 and t > 0.28:
				return "g3"
		"gi":       # quimono (perfil): lapela grossa descendo da nuca até a faixa, na frente do peito
			if view == "side":
				var nv: float = b.get("neck_v", 0.0)
				var t_top := 1.0 - nv
				var w := front - back
				# a lapela acompanha a borda do decote e depois desce em diagonal até a faixa
				var lt := clampf((t - 0.27) / maxf(t_top - 0.27, 0.01), 0.0, 1.0)
				var edge := lerpf(w * 0.42, 0.0, lt) if t <= t_top else (t - t_top) / maxf(nv, 0.01) * 4.0
				var dd := df - edge
				if t > 0.27 and dd >= 0.0 and dd < 1.0:
					return shirt[2]                      # borda da lapela pegando luz
				if t > 0.27 and dd >= 1.0 and dd < 2.6:
					return shirt[1] if dd < 2.0 else shirt[0]   # espessura da lapela e a sombra que ela faz
				if t > 0.27 and dd < 0.0 and t < t_top:
					return shirt[1]                      # aba de dentro (cruzada)
	if b.grease:
		# manchas fixas no corpo (coordenadas do tronco, não da tela: acompanham a pose)
		for sp in [[0.62, 0.35, 1.3], [0.44, 0.7, 0.9], [0.75, -0.2, 0.8], [0.36, 0.1, 0.7]]:
			var ss := lerpf(back, front, sp[1])
			if absf(t - sp[0]) * 26.0 < sp[2] and absf(s - ss) < sp[2]:
				return L.shade(L.col(shirt[0]), -1)
	return c

## Cinturão de pano (vermelho, fivela dourada torta) — o mesmo do ícone do cinturão.
func _belt_px(b: Dictionary, view: String, t: float, s: float, back: float, front: float, db: float, df: float, waist: float):
	var bl: Array = b.belt
	var u := (t - (waist - 0.05)) / 0.17
	var c = bl[1]
	if u > 0.78:
		c = bl[2]
	elif u < 0.2:
		c = bl[0]
	if db < 1.2:
		c = bl[0]
	var buckle := false
	if view == "side":
		buckle = df < 4.0 and u > 0.05 and u < 1.0
	else:
		var mid := mid_34(back, front)
		buckle = absf(s - (mid + 0.5)) < 2.6 and u > 0.0 and u < 1.05
	if buckle:
		c = bl[3]
		if u < 0.3 or (view == "34" and absf(s - (mid_34(back, front) + 0.5)) > 1.9):
			c = L.shade(L.col(bl[3]), -1)
	return c

func mid_34(back: float, front: float) -> float:
	return (back + front) * 0.5 + 0.8

# ================================================================ LUTA (perfil)
## Pose de luta (todas as posições relativas ao pivô = entre os pés, na sola):
##  hip, top (ou lean em graus + torso_len), head (opcional), hrot (graus, opcional), face, tw (giro),
##  sf/sb (ombros, opcionais), hf/hb (centros das luvas, obrigatórios), ef/eb (cotovelo forçado, opcional),
##  pf/pb (lado para onde o cotovelo dobra), toef/toeb + shoef/shoeb ("flat"|"ball"|"up"),
##  kf/kb (lado para onde o joelho dobra), gkf/gkb (orientação forçada da luva, ex. "side:f"),
##  far_glove_front (luva de trás desenhada na frente da cabeça — defesa).
func fight_frame(b: Dictionary, p: Dictionary, tag: String, size := Vector2i(112, 104), pivot := Vector2(56, 98)) -> Image:
	canvas(size.x, size.y)
	var O := pivot
	var hip: Vector2 = O + p.hip
	var top: Vector2
	if p.has("top"):
		top = O + p.top
	else:
		var tl: float = p.get("torso_len", 24.0)
		var lr := deg_to_rad(float(p.get("lean", 0.0)))
		top = hip + Vector2(sin(lr), -cos(lr)) * tl
	var dn := (top - hip).normalized()
	var fr := Vector2(-dn.y, dn.x)
	var nh := hip + fr * 1.5 - dn * 1.0
	var fh := hip - fr * 1.5 - dn * 1.0
	var sf: Vector2 = (O + p.sf) if p.has("sf") else top + fr * 2.0 - dn * 3.0
	var sb: Vector2 = (O + p.sb) if p.has("sb") else top - fr * 2.0 - dn * 2.0
	var hd: Vector2 = (O + p.head) if p.has("head") else top + fr * 3.0 + dn * 10.0
	var hrot: float = p.get("hrot", rad_to_deg(atan2(dn.x, -dn.y)) if p.get("hrot_auto", false) else 0.0)
	var lu: float = b.lu
	var lf: float = b.lf
	var lt: float = b.lt
	var ls: float = b.ls
	var kp_def := fr * 1.0 - dn * 0.1
	leg(b, FAR_THIGH, fh, O + p.get("toeb", Vector2(-3, -1)), p.get("shoeb", "flat"), lt, ls, true, tag + " perna de trás", b.leg_r, p.get("kb", kp_def))
	var hb: Vector2 = O + p.hb
	var pdef := -fr * 0.35 - dn * 1.0
	var elb := arm(b, FAR_UP, sb, hb, lu, lf, true, tag + " braço de trás", p.get("pb", pdef), b.arm_r, (O + p.eb) if p.has("eb") else null)
	var gkb := draw_glove(FAR_GLOVE_FRONT if p.get("far_glove_front", false) else FAR_GLOVE, b, elb, hb, true, p.get("gkb", ""))
	torso(b, TORSO, hip, top, "side", p.get("tw", 0.0))
	limb(TORSO, top - dn * 1.0, hd + rotv(Vector2(-1, 4), hrot), 2.6, 2.4, b.skin)   # pescoço (mesma peça do tronco)
	pmap(HEAD, head_rows(b, "side", p.get("face", "normal")), head_legend(b), hd, b.head_anchor_side, hrot)
	var ctx := {"hip": hip, "top": top, "dn": dn, "fr": fr, "hd": hd, "sf": sf, "sb": sb, "hb": hb, "elb": elb, "nh": nh, "fh": fh, "hrot": hrot}
	_hook(p, "after_torso", O, ctx)
	leg(b, NEAR_THIGH, nh, O + p.get("toef", Vector2(15, -1)), p.get("shoef", "flat"), lt, ls, false, tag + " perna da frente", b.leg_r, p.get("kf", kp_def))
	_hook(p, "after_near_leg", O, ctx)
	var hf: Vector2 = O + p.hf
	var elf := arm(b, NEAR_UP, sf, hf, lu, lf, false, tag + " braço da frente", p.get("pf", pdef), b.arm_r, (O + p.ef) if p.has("ef") else null)
	var gkf := draw_glove(NEAR_GLOVE, b, elf, hf, false, p.get("gkf", ""))
	ctx["hf"] = hf
	ctx["elf"] = elf
	_hook(p, "end", O, ctx)
	joint(TORSO, NEAR_UP, sf, 4.5)
	joint(TORSO, FAR_UP, sb, 4.5)
	joint(TORSO, NEAR_THIGH, nh, 5.5)
	joint(TORSO, FAR_THIGH, fh, 5.5)
	var im := finish()
	log_lines.append("%s: luvas frente '%s' trás '%s'; braço frente %.1f+%.1f, trás %.1f+%.1f" % [tag, gkf, gkb,
		(elf - sf).length(), (hf - elf).length(), (elb - sb).length(), (hb - elb).length()])
	return im

# ================================================================ GARAGEM (3/4)
## Pose da garagem (relativa ao pivô): hip, top, head, face, sl/sr (ombros esq./dir. da tela),
##  hl/hr (centros das luvas), el/er (cotovelos autorais, opcionais: escorço), fs (escala do braço direito
##  quando ele vai para dentro da cena), toel/toer + shoel/shoer ("34"|"34ball"), gkl/gkr, tw.
## Lado ESQUERDO da tela = mão de trás (mais escura); DIREITO = mão da frente (a que soca o saco).
func garage_frame(b: Dictionary, p: Dictionary, tag: String, size := Vector2i(48, 72), pivot := Vector2(22, 67)) -> Image:
	canvas(size.x, size.y)
	var O := pivot
	var hip: Vector2 = O + p.hip
	var top: Vector2 = O + p.top
	var hl := hip + Vector2(-3, 0)
	var hr := hip + Vector2(3, 0)
	var shl: Vector2 = O + p.sl
	var shr: Vector2 = O + p.sr
	var hdl: Vector2 = O + p.hl
	var hdr: Vector2 = O + p.hr
	var fs: float = p.get("fs", 1.0)
	var glu: float = b.glu
	var glf: float = b.glf
	var ar: Array = b.g_arm_r
	var lr: Array = b.g_leg_r
	var skin: Array = b.skin
	# braço direito: parte de cima atrás do tronco
	var elr: Vector2 = (O + p.er) if p.has("er") else ik(shr, hdr, glu * fs, glf * fs, p.get("pr", Vector2(0.3, 1.0)), tag + " braço direito")
	var o_up := {"bulge": 0.8, "bulge_t": 0.12, "bulge_w": 0.25, "bulge_dir": Vector2(1, -1)}
	if b.top == "tshirt":
		o_up["cloth"] = b.shirt
		o_up["cloth_t"] = 1.0 if b.sleeve_long else b.sleeve_t
		if b.trim != "":
			o_up["hem_c"] = b.trim
	limb(FAR_UP, shr, elr, ar[0], ar[1], skin, o_up)
	# pernas
	leg(b, FAR_THIGH, hr, O + p.get("toer", Vector2(10, 0)), p.get("shoer", "34"), b.glt, b.gls, false, tag + " perna direita", lr, p.get("kr", Vector2(0.6, 0)))
	leg(b, G_LEG_L, hl, O + p.get("toel", Vector2(-1, 0)), p.get("shoel", "34"), b.glt, b.gls, false, tag + " perna esquerda", lr, p.get("kl", Vector2(0.5, 0)))
	torso(b, TORSO, hip, top, "34", p.get("tw", 0.0))
	var hd: Vector2 = O + p.head
	limb(TORSO, top + Vector2(0, 1), hd + Vector2(0, 4), 2.3, 2.2, skin)
	pmap(HEAD, head_rows(b, "34", p.get("face", "normal")), head_legend(b), hd, b.head_anchor_34)
	var gctx := {"hip": hip, "top": top, "hd": hd, "sl": shl, "sr": shr, "hl": hdl, "hr": hdr, "elr": elr}
	_hook(p, "after_torso", O, gctx)
	# braço esquerdo por cima do tronco
	var ell: Vector2 = (O + p.el) if p.has("el") else ik(shl, hdl, glu, glf, p.get("pl", Vector2(-0.3, 1.0)), tag + " braço esquerdo")
	var o_ul := {"bulge": 0.8, "bulge_t": 0.12, "bulge_w": 0.25, "bulge_dir": Vector2(-1, -1)}
	if b.top == "tshirt":
		o_ul["cloth"] = b.shirt
		o_ul["cloth_t"] = 1.0 if b.sleeve_long else b.sleeve_t
		if b.trim != "":
			o_ul["hem_c"] = b.trim
	limb(NEAR_UP, shl, ell, ar[0], ar[1], skin, o_ul)
	var wl := ell + (hdl - ell).normalized() * maxf((hdl - ell).length() - 3.5, 1.0)
	limb(NEAR_FORE, ell, wl, ar[2], ar[3], skin, _g_fore(b))
	var gkl := draw_glove(NEAR_GLOVE, b, ell, hdl, true, p.get("gkl", "up"))
	# antebraço + luva direitos na frente
	var wr := elr + (hdr - elr).normalized() * maxf((hdr - elr).length() - 3.5, 1.0)
	limb(NEAR_GLOVE_TOP, elr, wr, ar[2], ar[3], skin, _g_fore(b))
	var gkr := draw_glove(NEAR_GLOVE_TOP + 1, b, elr, hdr, false, p.get("gkr", "up"))
	gctx["ell"] = ell
	_hook(p, "end", O, gctx)
	joint(TORSO, NEAR_UP, shl, 4.0)
	joint(TORSO, FAR_UP, shr, 4.0)
	joint(NEAR_UP, NEAR_FORE, ell, 2.6)
	joint(FAR_UP, NEAR_GLOVE_TOP, elr, 2.6)
	joint(TORSO, G_LEG_L, hl, 5.0)
	joint(TORSO, FAR_THIGH, hr, 5.0)
	var im := finish()
	log_lines.append("%s: luvas esq '%s' dir '%s'; braço dir. %.1f+%.1f (fs %.2f), esq. %.1f+%.1f" % [tag, gkl, gkr,
		(elr - shr).length(), (hdr - elr).length(), fs, (ell - shl).length(), (hdl - ell).length()])
	return im

func _g_fore(b: Dictionary) -> Dictionary:
	if b.top == "tshirt" and b.sleeve_long:
		return {"bulge": 0.3, "bulge_t": 0.3, "bulge_w": 0.3, "cloth": b.shirt, "cloth_t": 0.88, "cloth_add": 0.5}
	return {"bulge": 0.4, "bulge_t": 0.2, "bulge_w": 0.3}

func _hook(p: Dictionary, name: String, O: Vector2, ctx: Dictionary) -> void:
	if p.has(name):
		(p[name] as Callable).call(self, O, ctx)

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
