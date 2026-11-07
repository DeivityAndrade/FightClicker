extends SceneTree
## Sprites PLACEHOLDER da Fase 3 — Lutas e fim de carreira. Tudo gerado por código, paleta fechada
## de docs/arte/direcao-visual.md (fonte da verdade: tools/art/pixel_lib.gd).
## Rodar headless a partir de uma pasta com um project.godot vazio (não importa nada no projeto):
##   godot --headless --path <pasta_tmp> --quit-after 60 --script E:/Fightclicker/tools/art/make_sprites_fase3.gd
## Saída:
##   assets/sprites/fight/**      arena, lutador do jogador em vista de luta (+ variantes de luva), efeitos
##   assets/sprites/opponents/**  4 adversários (9 ações cada) e retratos 32x32
##   assets/sprites/ui/**         UI de luta, prévia, fim de carreira, ícones, luvas de loja, cursores
##   assets/sprites/characters/fighter_*_glove_lN.png  lutador da garagem com as luvas de loja
##   assets/sprites/manifest.json (ACRESCENTA as entradas da Fase 3; não apaga as da Fase 2)
##   docs/arte/mockups/fase3_sprites_x3.png, fase3_luta_x2.png, fase3_previa_x2.png, fase3_fim_x2.png
## Aparência dos adversários e das luvas: docs/fases/fase3-textos.md (Roteirista).

const ROOT := "E:/Fightclicker/"
const OUT := ROOT + "assets/sprites/"
const RES := "res://assets/sprites/"
const MOCK := ROOT + "docs/arte/mockups/"

# ---- quadro de luta (igual para TODOS os lutadores, para a UI trocar fácil)
const FW := 112
const FH := 104
const PV := Vector2i(56, 98)          # pivô = entre os pés, na sola
const ACTIONS := ["idle", "jab", "heavy", "hit", "dodge", "block", "tired", "victory", "ko"]

# ---- arena (640x360)
const P_PLAYER := Vector2i(296, 318)
const P_OPP := Vector2i(346, 318)
const FLOOR_Y := 240
const LAMP_POS := Vector2i(321, 52)
const HUD_H := 46

var L
var M := {}            # id -> entrada do manifest (só Fase 3)
var SHEETS := []       # [id, Image folha, largura do quadro] (folha de contato)
var F := {}            # id -> Array de quadros
var OLD := {}           # manifest existente (Fase 2), lido no início

# ================================================================ luvas
## Luva equipada do jogador. Cores-chave da troca de paleta: r0/r1/r2 (luva velha).
const GLOVES := {
	"glove_old": {"name": "Luva velha", "ramp": ["r0", "r1", "r2"], "style": "old"},
	"glove_l1": {"name": "Luva de lona", "ramp": ["br3", "cream", "white"], "style": "lona"},
	"glove_l2": {"name": "Luva de couro", "ramp": ["r0", "br1", "br2"], "style": "couro"},
	"glove_l3": {"name": "Luva de marca", "ramp": ["d1", "d2", "g0"], "style": "marca"},
}

func glove_def(id: String) -> Dictionary:
	return GLOVES[id]

## Desenha uma luva (canto superior esquerdo x,y; w x h). back = mão de trás (um tom abaixo).
func draw_glove(img: Image, x: int, y: int, w: int, h: int, g: Dictionary, back := false) -> void:
	var rp: Array = g.ramp
	var ramp: Array = rp
	if back:
		ramp = [L.shade(L.col(rp[0]), -1), rp[0], rp[1]]
	var st: String = g.get("style", "plain")
	if st == "old":
		L.glove2(img, x, y, w, h, ramp)
		return
	L.glove(img, x, y, w, h, ramp)
	match st:
		"lona":
			# lona bege: trama em pontinhos + fita branca larga no pulso
			for yy in range(y + 2, y + h - 3, 2):
				for xx in range(x + 2 + (yy / 2) % 2, x + w - 2, 3):
					L.P(img, xx, yy, ramp[0])
			L.R(img, x + 1, y + h - 3, w - 2, 1, "white")
			L.R(img, x + 1, y + h - 2, w - 2, 1, "white")
			L.R(img, x + 1, y + h - 1, w - 2, 1, "g3")
		"couro":
			# couro marrom-avermelhado com costura clara
			for yy in range(y + 2, y + h - 3, 2):
				L.P(img, x + w - 3, yy, "cream" if not back else "g3")
			L.P(img, x + 2, y + 1, ramp[2])
			L.R(img, x + 1, y + h - 2, w - 2, 1, "br3")
			L.R(img, x + 1, y + h - 1, w - 2, 1, "cream")
		"marca":
			# preta, listra amarela torta, punho escuro com friso
			L.line(img, x + 2, y + h - 4, x + w - 4, y + 4, "y0" if back else "y1")
			L.P(img, x + w - 3, y + 4, "y0")
			L.R(img, x + 1, y + h - 2, w - 2, 1, "g1")
			L.R(img, x + 1, y + h - 1, w - 2, 1, "white")
		"tape_red":
			# remendada com fita isolante vermelha (Brutão do Posto)
			L.R(img, x + 1, y + 3, w - 2, 2, "r1" if back else "r2")
			L.line(img, x + 3, y + 6, x + w - 3, y + h - 4, "r1" if back else "r2")
			L.R(img, x + 1, y + h - 2, w - 2, 1, "g2")
			L.R(img, x + 1, y + h - 1, w - 2, 1, "g3")
		"worn":
			L.P(img, x + 4, y + 3, ramp[0]); L.P(img, x + 6, y + 6, ramp[0])
			L.R(img, x + 1, y + h - 2, w - 2, 1, "g2")
			L.R(img, x + 1, y + h - 1, w - 2, 1, "g3")

# ================================================================ builds (aparência)
## Lutador do jogador = o mesmo da garagem (regata creme, calção azul, cabelo castanho), luva trocável.
func build_player(glove_id: String) -> Dictionary:
	return {"id": "player", "s": 1.0, "cw": 12, "ww": 10, "ua": 5, "fa": 4, "th": 7, "sh": 5,
		"hw": 11, "hh": 13, "neck": 0,
		"skin": ["sk0", "sk1", "sk2"], "hair": ["br0", "br1"], "head": "short",
		"top": "tank", "shirt": ["cream", "white", "white"],
		"bottom": "shorts", "shorts": ["b0", "b1", "b2"], "band": "b2",
		"shoes": ["d2", "g1", "cream"], "glove": glove_def(glove_id), "gw": 10, "gh": 11}

func build_opp(id: String) -> Dictionary:
	match id:
		"opp_warmup":   # Dudu Alongado: magro, médio, regata branca, calção de futebol verde-musgo, meião, faixa mole
			return {"id": id, "s": 0.98, "cw": 10, "ww": 8, "ua": 4, "fa": 4, "th": 6, "sh": 4,
				"hw": 10, "hh": 13, "neck": 0,
				"skin": ["sk1", "sk2", "y2"], "hair": ["br1", "br2"], "head": "messy", "headband": ["g2", "g3"],
				"top": "tank", "shirt": ["g3", "white", "white"],
				"bottom": "shorts", "shorts": ["gr0", "gr1", "gr2"], "band": "gr2", "socks": ["g3", "white", "white"],
				"shoes": ["d1", "d2", "g2"], "glove": {"ramp": ["st1", "st2", "st3"], "style": "worn"}, "gw": 10, "gh": 11}
		"opp_strong":   # Brutão do Posto: o mais largo, ombrão, pescoço curto, regata cinza com graxa, macacão azul amarrado, boné do posto
			return {"id": id, "s": 1.08, "cw": 19, "ww": 15, "ua": 8, "fa": 7, "th": 9, "sh": 7,
				"hw": 13, "hh": 12, "neck": 3,
				"skin": ["br0", "sk0", "sk1"], "hair": ["ink", "d1"], "head": "cap", "cap": ["r0", "r1", "r2"], "stubble": true,
				"top": "tank", "shirt": ["g1", "g2", "g3"], "grease": true,
				"bottom": "pants", "shorts": ["b0", "b1", "b2"], "band": "b2", "tied_sleeves": true,
				"shoes": ["br0", "br1", "br2"], "glove": {"ramp": ["d1", "d2", "g0"], "style": "tape_red"}, "gw": 11, "gh": 12}
		"opp_fast":     # Dinho Pulga: baixo, magro, ponta do pé, moletom azul com capuz para trás, bandana, tênis laranja, cadarço solto
			return {"id": id, "s": 0.92, "cw": 10, "ww": 8, "ua": 4, "fa": 4, "th": 5, "sh": 4,
				"hw": 10, "hh": 12, "neck": 0,
				"skin": ["sk0", "sk1", "sk2"], "hair": ["ink", "d2"], "head": "short", "bandana": ["g3", "white"],
				"top": "hoodie", "shirt": ["b1", "b2", "b3"],
				"bottom": "shorts", "shorts": ["d1", "d2", "g0"], "band": "b1",
				"shoes": ["br2", "br3", "y0"], "lace": true, "glove": {"ramp": ["d1", "d2", "g0"], "style": "plain"}, "gw": 9, "gh": 10}
		"opp_tank":     # Seu Muralha: alto, largo, barriga firme, bigode grisalho, camiseta amarela de várzea, cinturão de pano
			return {"id": id, "s": 1.12, "cw": 15, "ww": 16, "ua": 7, "fa": 6, "th": 9, "sh": 7,
				"hw": 12, "hh": 14, "neck": 1, "belly": 4,
				"skin": ["sk0", "sk1", "sk2"], "hair": ["g2", "g3"], "head": "gray", "mustache": "g3",
				"top": "tee", "shirt": ["y0", "y1", "y2"], "trim": "gr1",
				"bottom": "shorts", "shorts": ["d1", "d2", "g0"], "band": "g0", "belt": true,
				"shoes": ["d1", "d2", "g1"], "glove": {"ramp": ["br1", "br2", "br3"], "style": "worn"}, "gw": 11, "gh": 12}
	return {}

# ================================================================ poses (figura de referência ~79 px, x>0 = para a frente)
const UPPER := ["chest", "head", "sf", "sb", "ef", "eb", "hf", "hb"]

func G() -> Dictionary:
	return {"ff": Vector2(9, 0), "fb": Vector2(-10, 0), "kf": Vector2(8, -20), "kb": Vector2(-7, -20),
		"hip": Vector2(0, -38), "chest": Vector2(2, -60), "head": Vector2(5, -71),
		"sf": Vector2(4, -59), "sb": Vector2(0, -60), "ef": Vector2(9, -49), "hf": Vector2(16, -59),
		"eb": Vector2(3, -50), "hb": Vector2(12, -61), "face": "normal", "rot": 0, "lift": 0, "hx": Vector2.ZERO}

## over = pontos trocados; ux/uy = desloca o tronco para a frente/baixo; hx = desloca só a cabeça.
func pz(over := {}, ux := 0.0, uy := 0.0) -> Dictionary:
	var p := G()
	for k in over:
		p[k] = over[k]
	for k in UPPER:
		p[k] = p[k] + Vector2(ux, uy)
	p["hip"] = p["hip"] + Vector2(roundf(ux * 0.4), uy)
	p["head"] = p["head"] + p["hx"]
	return p

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

func poses_for(action: String, who: String) -> Array:
	var out := []
	match action:
		"idle":
			var bob := [0, 0, 1, 1]
			for i in 4:
				var o := {"hf": V(16, -59 + bob[i]), "hb": V(12, -61 + bob[i])}
				var lift := 0
				if who == "opp_fast":
					lift = [0, 1, 2, 1][i]
				if who == "opp_warmup" and i >= 2:   # alonga o ombro entre um golpe e outro
					o["eb"] = V(-4, -52 + i - 2); o["hb"] = V(-1, -43 + i - 2)
				if who == "opp_strong":
					o["sf"] = V(4, -59 + bob[i]); o["sb"] = V(0, -60 + bob[i])
				var p := pz(o, 0, bob[i] if who != "opp_tank" else (1 if i == 2 else 0))
				p["lift"] = lift
				out.append(p)
		"jab":
			out.append(pz({"hf": V(13, -61), "ef": V(8, -50)}, -1, 0))
			out.append(pz({"ff": V(12, 0), "sf": V(7, -59), "ef": V(18, -60), "hf": V(28, -61)}, 3, 0))
			out.append(pz({"ff": V(11, 0), "sf": V(6, -59), "ef": V(15, -58), "hf": V(23, -61)}, 2, 0))
			out.append(pz({"ff": V(10, 0)}, 1, 0))
		"heavy":
			out.append(pz({"hb": V(6, -63), "eb": V(0, -52), "kb": V(-8, -19)}, -2, 1))
			out.append(pz({"sb": V(1, -60), "eb": V(8, -58), "hb": V(15, -62), "hf": V(12, -63)}, 0, 0))
			out.append(pz({"ff": V(12, 0), "fb": V(-8, 0), "kb": V(-4, -19), "sb": V(4, -60), "eb": V(17, -61), "hb": V(31, -62),
				"sf": V(5, -59), "ef": V(8, -52), "hf": V(12, -64), "hx": V(1, 0)}, 5, 0))
			out.append(pz({"ff": V(12, 0), "fb": V(-8, 0), "kb": V(-4, -19), "sb": V(4, -60), "eb": V(16, -61), "hb": V(29, -62),
				"sf": V(5, -59), "ef": V(8, -52), "hf": V(12, -64), "hx": V(1, 0)}, 4, 0))
			out.append(pz({"ff": V(11, 0), "eb": V(7, -53), "hb": V(14, -64)}, 2, 0))
		"hit":
			out.append(pz({"hf": V(11, -58), "hb": V(8, -61), "ef": V(7, -49), "face": "hurt", "hx": V(-2, 1)}, -4, 0))
			out.append(pz({"hf": V(12, -59), "face": "hurt", "hx": V(-1, 1)}, -3, 1))
			out.append(pz({}, -1, 0))
		"dodge":
			out.append(pz({"kf": V(8, -18), "kb": V(-6, -18)}, -4, 2))
			out.append(pz({"kf": V(9, -16), "kb": V(-6, -17), "hx": V(-1, 0)}, -8, 5))
			out.append(pz({"kf": V(9, -16), "kb": V(-6, -17), "hx": V(-1, 0)}, -7, 4))
			out.append(pz({"kf": V(8, -19), "kb": V(-7, -19)}, -3, 1))
		"block":
			var bo := {"ef": V(8, -55), "hf": V(12, -67), "eb": V(5, -54), "hb": V(10, -70), "hx": V(-1, 1)}
			out.append(pz(bo, -1, 0))
			out.append(pz(bo, -3, 1))
			out.append(pz(bo, -2, 0))
		"tired":
			for i in 4:
				var d: int = [0, 1, 1, 0][i]
				out.append(pz({"hf": V(14, -54 + d), "ef": V(9, -46), "hb": V(9, -52 + d), "eb": V(3, -46),
					"hx": V(1, 2), "face": "tired", "kf": V(8, -19), "kb": V(-7, -19)}, 1, 2 + d))
		"victory":
			var v0 := {"hf": V(9, -83), "ef": V(8, -72), "hb": V(-1, -82), "eb": V(0, -71), "face": "shout"}
			var v2 := {"hf": V(13, -74), "ef": V(11, -65), "hb": V(-1, -82), "eb": V(0, -71), "face": "shout"}
			var a := pz(v0); var b := pz(v0); b["lift"] = 1
			var c := pz(v2); var d2 := pz(v0); d2["lift"] = 1
			out = [a, b, c, d2]
		"ko":
			out.append(pz({"ef": V(7, -50), "hf": V(10, -42), "eb": V(1, -50), "hb": V(4, -41), "face": "ko", "hx": V(-2, 1)}, -4, 1))
			var k1 := G()
			for kv in [["hip", V(-1, -30)], ["kf", V(6, -14)], ["kb", V(-6, -14)], ["ff", V(10, 0)], ["fb", V(-9, 0)],
					["chest", V(-4, -51)], ["head", V(-5, -62)], ["sf", V(-2, -50)], ["sb", V(-5, -51)],
					["ef", V(2, -41)], ["hf", V(6, -33)], ["eb", V(-4, -42)], ["hb", V(-1, -33)]]:
				k1[kv[0]] = kv[1]
			k1["face"] = "ko"
			out.append(k1)
			var k2 := G()
			for kv in [["ff", V(14, 0)], ["fb", V(8, 0)], ["kf", V(6, -10)], ["kb", V(2, -9)], ["hip", V(-8, -14)],
					["chest", V(-24, -30)], ["head", V(-31, -37)], ["sf", V(-22, -31)], ["sb", V(-25, -31)],
					["ef", V(-14, -40)], ["hf", V(-8, -48)], ["eb", V(-30, -40)], ["hb", V(-35, -47)]]:
				k2[kv[0]] = kv[1]
			k2["face"] = "ko"
			out.append(k2)
			for j in 2:
				var k3 := G()
				var yy := float(j)
				for kv in [["ff", V(22 + j, -3 + yy)], ["fb", V(17, -2 + yy)], ["kf", V(11 + j, -8 + yy + j * 2)], ["kb", V(8, -6 + yy)],
						["hip", V(-3, -5 + yy)], ["chest", V(-24, -6 + yy)], ["head", V(-34, -7 + yy)], ["sf", V(-22, -7 + yy)],
						["sb", V(-24, -6 + yy)], ["ef", V(-13, -3 + yy)], ["hf", V(-5, -3 + yy)], ["eb", V(-32, -12 + yy)], ["hb", V(-39, -16 + yy)]]:
					k3[kv[0]] = kv[1]
				k3["face"] = "ko"
				k3["rot"] = 1
				out.append(k3)
	return out

# ================================================================ rig de luta (partes com contorno próprio)
func taper(img: Image, a: Vector2, b: Vector2, wa: float, wb: float, ramp: Array, front: Vector2) -> void:
	a += Vector2(0.5, 0.5)
	b += Vector2(0.5, 0.5)
	var d := b - a
	var l2 := d.length_squared()
	var rm := maxf(wa, wb) / 2.0 + 1.0
	for y in range(int(floor(minf(a.y, b.y) - rm)), int(ceil(maxf(a.y, b.y) + rm))):
		for x in range(int(floor(minf(a.x, b.x) - rm)), int(ceil(maxf(a.x, b.x) + rm))):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := 0.0 if l2 < 0.0001 else clampf((p - a).dot(d) / l2, 0.0, 1.0)
			var r := lerpf(wa, wb, t) / 2.0
			var v := p - (a + d * t)
			if v.length() <= r:
				var s := v.dot(front)
				var c = ramp[1]
				if s < -r + 1.5:
					c = ramp[0]
				elif s > r - 1.2:
					c = ramp[2]
				L.P(img, x, y, c)

func dk(ramp: Array) -> Array:
	return [L.shade(L.col(ramp[0]), -1), L.shade(L.col(ramp[1]), -1), L.shade(L.col(ramp[2]), -1)]

func shoe(img: Image, knee: Vector2, foot: Vector2, b: Dictionary, far: bool, frame: int) -> void:
	var c: Array = b.shoes
	if far:
		c = dk(c)
	var d := foot - knee
	var x := int(foot.x)
	var y := int(foot.y)
	if absf(d.y) >= absf(d.x):
		L.R(img, x - 3, y - 4, 10, 4, c[1]); L.R(img, x - 3, y - 4, 10, 1, c[2]); L.R(img, x - 3, y - 1, 10, 1, c[0])
		L.R(img, x + 4, y - 3, 3, 1, c[2])
		if b.get("lace", false) and not far:
			var e := 1 if frame % 2 == 0 else -1
			L.line(img, x, y - 4, x - 2, y - 1, "cream"); L.P(img, x - 3 + e, y, "cream")
	else:   # deitado: bico para cima
		L.R(img, x - 1, y - 6, 4, 9, c[1]); L.R(img, x - 1, y - 6, 1, 9, c[2]); L.R(img, x + 2, y - 6, 1, 9, c[0])

func leg(img: Image, hip: Vector2, knee: Vector2, foot: Vector2, b: Dictionary, far: bool, frame: int) -> void:
	var skin: Array = b.skin
	var cloth: Array = b.shorts
	if far:
		skin = dk(skin); cloth = dk(cloth)
	var th: float = b.th
	var sh: float = b.sh
	if b.bottom == "pants":
		L.capsule(img, hip, knee, th + 1, cloth)
		L.capsule(img, knee, foot + Vector2(0, -2), th, cloth)
	else:
		var shin_c: Array = skin
		if b.has("socks"):
			shin_c = dk(b.socks) if far else b.socks
		L.capsule(img, knee, foot + Vector2(0, -2), sh, skin)
		if b.has("socks"):
			L.capsule(img, knee.lerp(foot, 0.25), foot + Vector2(0, -2), sh + 1, shin_c)
		L.capsule(img, hip, knee, th, skin)
		L.capsule(img, hip, hip.lerp(knee, 0.5), th + 1, cloth)
	shoe(img, knee, foot, b, far, frame)

func arm(img: Image, sh: Vector2, el: Vector2, hand: Vector2, b: Dictionary, far: bool) -> void:
	var skin: Array = b.skin
	var shirt: Array = b.shirt
	if far:
		skin = dk(skin); shirt = dk(shirt)
	var ua: float = b.ua
	var fa: float = b.fa
	if b.top == "hoodie":
		L.capsule(img, sh, el, ua + 1, shirt)
		L.capsule(img, el, hand, fa + 1, shirt)
	else:
		L.capsule(img, sh, el, ua, skin)
		L.capsule(img, el, hand, fa, skin)
		if b.top == "tee":
			L.capsule(img, sh, sh.lerp(el, 0.45), ua + 2, shirt)
			var tr: String = b.get("trim", "")
			if tr != "":
				var q := sh.lerp(el, 0.45)
				L.P(img, int(q.x), int(q.y), tr)

## Cabeça desenhada de pé, virada para a direita, numa imagem 28x28 (centro 14,14).
func head_img(b: Dictionary, face: String) -> Image:
	var img: Image = L.blank(28, 28)
	var skin: Array = b.skin
	var hair: Array = b.hair
	var hw: int = b.hw
	var hh: int = b.hh
	var x0 := 14 - hw / 2
	var y0 := 14 - hh / 2
	var x1 := x0 + hw - 1
	var my := y0 + hh / 2
	L.rrect(img, x0, y0, hw, hh, skin[1])
	L.R(img, x0, y0 + 2, 1, hh - 4, skin[0])
	L.R(img, x1, y0 + 2, 1, hh - 6, skin[2])
	L.R(img, x0 + 1, y0 + hh - 1, hw - 3, 1, skin[0])     # queixo
	L.P(img, x1 + 1, my, skin[1]); L.P(img, x1 + 1, my + 1, skin[0])   # nariz
	L.R(img, x0 + hw / 2 - 2, my - 1, 2, 3, skin[0]); L.P(img, x0 + hw / 2 - 1, my, skin[1])   # orelha
	var style: String = b.head
	match style:
		"short":
			L.R(img, x0 - 1, y0 - 1, hw + 1, 4, hair[0]); L.R(img, x0 - 1, y0 + 3, 3, 4, hair[0])
			L.R(img, x0 + 2, y0 - 1, 5, 1, hair[1])
		"messy":
			L.R(img, x0 - 1, y0 - 1, hw + 1, 4, hair[0]); L.R(img, x0 - 1, y0 + 3, 3, 5, hair[0])
			for i in 4:
				L.P(img, x0 + i * 3, y0 - 2, hair[0]); L.P(img, x0 + i * 3 + 1, y0 - 2, hair[1])
			L.P(img, x1 + 1, y0 + 1, hair[0])
		"gray":
			L.R(img, x0, y0 - 1, hw - 1, 3, hair[1]); L.R(img, x0 - 1, y0 + 1, 3, 6, hair[1])
			L.R(img, x0, y0 - 1, hw - 1, 1, hair[0])
		"cap":
			var cp: Array = b.cap
			L.R(img, x0 - 1, y0 + 2, 3, 4, hair[0])
			L.R(img, x0 - 1, y0 - 2, hw + 1, 4, cp[1]); L.R(img, x0, y0 - 3, hw - 2, 1, cp[1])
			L.R(img, x0, y0 - 3, hw - 3, 1, cp[2]); L.R(img, x0 - 1, y0 + 1, hw + 1, 1, cp[0])
			L.R(img, x1 - 1, y0 + 1, 5, 2, cp[0]); L.R(img, x1, y0 + 1, 4, 1, cp[1])   # aba para a frente
			L.R(img, x0 + 3, y0 - 1, 3, 2, "y1")                                         # escudo do posto
	if b.has("headband"):
		var hb: Array = b.headband
		L.R(img, x0, y0 + 2, hw, 2, hb[1]); L.R(img, x0, y0 + 3, hw, 1, hb[0])
		L.R(img, x0 - 3, y0 + 4, 3, 1, hb[1]); L.R(img, x0 - 3, y0 + 5, 2, 2, hb[0])   # faixa mole caindo atrás
	if b.has("bandana"):
		var bd: Array = b.bandana
		L.R(img, x0, y0 + 1, hw, 2, bd[1]); L.R(img, x0, y0 + 2, hw, 1, bd[0])
		L.R(img, x0 - 3, y0 + 2, 3, 2, bd[1]); L.P(img, x0 - 4, y0 + 4, bd[0])          # nó
	# sobrancelha
	if style != "cap" or true:
		L.R(img, x1 - 3, my - 3, 3, 1, hair[0] if style != "gray" else hair[1])
	# rosto
	match face:
		"hurt":
			L.R(img, x1 - 3, my - 1, 3, 1, "ink")
			L.R(img, x1 - 2, y0 + hh - 4, 2, 2, "ink")
		"tired":
			L.R(img, x1 - 2, my - 1, 2, 1, "ink"); L.P(img, x1 - 2, my, "ink")
			L.R(img, x1 - 2, y0 + hh - 4, 2, 2, "ink")
		"shout":
			L.R(img, x1 - 2, my - 2, 1, 2, "ink")
			L.R(img, x1 - 3, y0 + hh - 5, 3, 3, "ink"); L.P(img, x1 - 2, y0 + hh - 5, "white")
		"ko":
			L.P(img, x1 - 3, my - 2, "ink"); L.P(img, x1 - 1, my - 2, "ink"); L.P(img, x1 - 2, my - 1, "ink")
			L.P(img, x1 - 3, my, "ink"); L.P(img, x1 - 1, my, "ink")
			L.R(img, x1 - 2, y0 + hh - 3, 2, 1, "ink")
		_:
			L.R(img, x1 - 2, my - 1, 1, 2, "ink")
			L.R(img, x1 - 2, y0 + hh - 3, 2, 1, skin[0])
	if b.has("mustache"):
		L.R(img, x1 - 3, y0 + hh - 4, 4, 1, b.mustache); L.P(img, x1 - 3, y0 + hh - 3, b.mustache)
	if b.get("stubble", false):
		for xx in range(x0 + hw / 2, x1):
			if xx % 2 == 0:
				L.P(img, xx, y0 + hh - 2, skin[0])
		L.R(img, x0 + hw / 2 + 1, y0 + hh - 1, hw / 2 - 1, 1, skin[0])
	return img

func FP(b: Dictionary, v: Vector2) -> Vector2:
	var s: float = b.s
	return Vector2(PV) + v * s

## Desenha um quadro de luta 112x104 virado para a DIREITA.
func rig(b: Dictionary, p0: Dictionary, frame := 0) -> Image:
	var p := {}
	for k in ["ff", "fb", "kf", "kb", "hip", "chest", "head", "sf", "sb", "ef", "eb", "hf", "hb"]:
		p[k] = FP(b, p0[k])
	var neck: int = b.neck
	p["head"] = p["head"] + Vector2(0, neck) * (1.0 if p0.rot == 0 else 0.0) + (Vector2(neck, 0) if p0.rot == 1 else Vector2.ZERO)
	var face: String = p0.face
	var out: Image = L.blank(FW, FH)
	var axis: Vector2 = (p.chest - p.hip).normalized()
	var front := Vector2(-axis.y, axis.x)
	var Lr: Image
	# perna de trás
	Lr = L.blank(FW, FH)
	leg(Lr, p.hip - front * 2, p.kb, p.fb, b, true, frame)
	L.stamp(out, Lr, 0, 0)
	# braço de trás (sem a luva)
	Lr = L.blank(FW, FH)
	arm(Lr, p.sb, p.eb, p.hb, b, true)
	L.stamp(out, Lr, 0, 0)
	# tronco
	Lr = L.blank(FW, FH)
	var skin: Array = b.skin
	var shirt: Array = b.shirt
	var cw: float = b.cw
	var ww: float = b.ww
	L.capsule(Lr, p.chest, p.chest.lerp(p.head, 0.55), 5 + neck, skin)          # pescoço
	taper(Lr, p.hip, p.chest, ww, cw, skin, front)
	if b.has("belly"):
		var bc: Vector2 = p.hip.lerp(p.chest, 0.3) + front * (ww / 2.0 - 2.0)
		var bl: float = b.belly
		taper(Lr, bc - axis * 3, bc + axis * 3, bl * 2 + 2, bl * 2, shirt if b.top != "tank" else skin, front)
	var top: String = b.top
	if top == "tank" or top == "tee" or top == "hoodie":
		var t1 := 0.86 if top == "tank" else 1.0
		seg_box(Lr, p.hip.lerp(p.chest, 0.15), p.hip.lerp(p.chest, t1), ww + 1, cw + (0 if top == "tank" else 1), shirt, front)
		if b.has("belly"):
			var bc2: Vector2 = p.hip.lerp(p.chest, 0.3) + front * (ww / 2.0 - 2.0)
			var bl2: float = b.belly
			taper(Lr, bc2 - axis * 3, bc2 + axis * 3, bl2 * 2 + 2, bl2 * 2, shirt, front)
		if top == "tank":
			var q: Vector2 = p.hip.lerp(p.chest, 0.6) + front * 1
			L.P(Lr, int(q.x), int(q.y), shirt[0])
		if top == "hoodie":
			var hq: Vector2 = p.chest - front * (cw / 2.0) + axis * 1
			L.ellipse(Lr, hq.x, hq.y, 4, 3, shirt[0]); L.ellipse(Lr, hq.x + 1, hq.y, 2.5, 2, shirt[1])   # capuz para trás
			var dq: Vector2 = p.chest + front * (cw / 2.0 - 1) - axis * 4
			L.P(Lr, int(dq.x), int(dq.y), "cream"); L.P(Lr, int(dq.x), int(dq.y) + (1 if p0.rot == 0 else 0), "cream")
			var hem: Vector2 = p.hip.lerp(p.chest, 0.17)
			seg_box(Lr, hem - axis * 1, hem + axis * 1, ww + 1, ww + 1, ["b0", "b1", "b1"], front)
		if b.get("grease", false):
			for gp in [[0.4, 1.0], [0.62, -2.0], [0.5, 3.0]]:
				var g: Vector2 = p.hip.lerp(p.chest, gp[0]) + front * gp[1]
				L.P(Lr, int(g.x), int(g.y), "d2"); L.P(Lr, int(g.x) + 1, int(g.y), "g0")
		if top == "tee" and b.has("trim"):
			var nq: Vector2 = p.chest + front * 2
			L.R(Lr, int(nq.x) - 1, int(nq.y), 3, 1, b.trim)
			var num: Vector2 = p.hip.lerp(p.chest, 0.62) - front * 1
			L.R(Lr, int(num.x), int(num.y), 2, 1, "br1"); L.P(Lr, int(num.x) + 1, int(num.y) + 1, "br1"); L.P(Lr, int(num.x), int(num.y) + 2, "br1")
	# calção / calça
	var sh: Array = b.shorts
	seg_box(Lr, p.hip - axis * 3, p.hip.lerp(p.chest, 0.24), ww + 2, ww + 1, sh, front)
	var wb: Vector2 = p.hip.lerp(p.chest, 0.24)
	seg_box(Lr, wb - axis * 0.5, wb + axis * 0.5, ww + 1, ww + 1, [b.band, b.band, L.shade(L.col(b.band), 1)], front)
	if b.get("tied_sleeves", false):
		var kq: Vector2 = wb + front * (ww / 2.0)
		L.ellipse(Lr, kq.x, kq.y, 2.5, 2, sh[2])
		L.capsule(Lr, kq, kq - axis * 9 + front * 1, 3, sh)
	if b.get("belt", false):
		seg_box(Lr, wb - axis * 1.5, wb + axis * 1.5, ww + 3, ww + 3, ["r0", "r1", "r2"], front)
		var bq: Vector2 = wb + front * (ww / 2.0)
		L.R(Lr, int(bq.x) - 2, int(bq.y) - 2, 4, 4, "y0"); L.R(Lr, int(bq.x) - 2, int(bq.y) - 2, 3, 1, "y1")
		L.P(Lr, int(bq.x) + 2, int(bq.y) - 3, "y0")           # fivela torta
		L.P(Lr, int(bq.x) - 1, int(bq.y), "br2")
	L.stamp(out, Lr, 0, 0)
	# perna da frente
	Lr = L.blank(FW, FH)
	leg(Lr, p.hip + front * 2, p.kf, p.ff, b, false, frame)
	L.stamp(out, Lr, 0, 0)
	# cabeça
	var hi := head_img(b, face)
	if p0.rot == 1:
		hi.rotate_90(COUNTERCLOCKWISE)
	L.stamp(out, hi, int(p.head.x) - 14, int(p.head.y) - 14)
	# luva de trás (na frente da cabeça, atrás do braço da frente)
	var gw: int = b.gw
	var gh: int = b.gh
	Lr = L.blank(FW, FH)
	draw_glove(Lr, int(p.hb.x) - (gw - 1) / 2, int(p.hb.y) - gh / 2, gw - 1, gh - 1, b.glove, true)
	L.stamp(out, Lr, 0, 0)
	# braço da frente + luva
	Lr = L.blank(FW, FH)
	arm(Lr, p.sf, p.ef, p.hf, b, false)
	draw_glove(Lr, int(p.hf.x) - gw / 2, int(p.hf.y) - gh / 2, gw, gh, b.glove, false)
	L.stamp(out, Lr, 0, 0)
	var lift: int = p0.lift
	if lift != 0:
		var o2: Image = L.blank(FW, FH)
		o2.blit_rect(out, Rect2i(0, 0, FW, FH), Vector2i(0, -lift))
		out = o2
	return out

func face_left(img: Image) -> Image:
	var f: Image = img.duplicate()
	f.flip_x()
	var o: Image = L.blank(img.get_width(), img.get_height())
	o.blit_rect(f, Rect2i(0, 0, img.get_width() - 1, img.get_height()), Vector2i(1, 0))
	return o

# ================================================================ utilidades
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

func xy(v: Vector2i) -> Array:
	return [v.x, v.y]

func outline_in_place(src: Image, c = "ink") -> Image:
	var o: Image = L.outlined(src, c)
	var out: Image = L.blank(src.get_width(), src.get_height())
	out.blit_rect(o, Rect2i(1, 1, src.get_width(), src.get_height()), Vector2i.ZERO)
	return out

# ================================================================ lutadores de luta
const ACTION_META := {
	"idle": {"fps": 6.0, "loop": true, "note": "Guarda com respiração (loop). Estado neutro entre eventos."},
	"jab": {"fps": 14.0, "loop": false, "hit_frame": 1, "note": "0 antecipação, 1 braço da frente esticado (CONTATO: impacto, número, reação do outro), 2 recolhe, 3 volta. Depois idle."},
	"heavy": {"fps": 12.0, "loop": false, "hit_frame": 2, "note": "Golpe forte (direto de trás com o corpo): 0 carrega, 1 gira, 2 CONTATO, 3 segura, 4 volta. Usar também no crítico."},
	"hit": {"fps": 12.0, "loop": false, "note": "Recebeu golpe: 0 cabeça vai para trás (rosto de dor), 1 recua, 2 recupera. Começar no quadro de contato do outro."},
	"dodge": {"fps": 14.0, "loop": false, "note": "Esquiva para trás e para baixo: 0 inclina, 1-2 fundo (o golpe passa), 3 volta. Começar 1 quadro ANTES do contato do outro. Mostrar 'ESQUIVOU' e fx_whoosh."},
	"block": {"fps": 12.0, "loop": false, "note": "Defesa: 0 fecha a guarda, 1 absorve (empurrado 2 px), 2 segura. fx_block nas luvas."},
	"tired": {"fps": 6.0, "loop": true, "note": "Cansado (loop no lugar do idle quando a vida/fôlego estiver baixo): guarda baixa, boca aberta. Somar fx_sweat."},
	"victory": {"fps": 8.0, "loop": true, "note": "Vitória (loop): braços para cima, pulinho."},
	"ko": {"fps": 10.0, "loop": false, "hold_last": true, "note": "Queda (K.O.): 0 cambaleia, 1 joelhos cedem, 2 caindo de costas, 3 bate no chão (fx_dust_fall + tremida), 4 assenta (segurar este quadro). Somar fx_ko_stars na cabeça no chão."},
}

const FIGHT_FPS_MUL := {"player": 1.0, "opp_warmup": 1.0, "opp_strong": 0.9, "opp_fast": 1.25, "opp_tank": 0.8}

func make_fighter_sheets(b: Dictionary, prefix: String, rel_dir: String, left: bool, who: String, desc: String, contact := true, suffix := "") -> void:
	for act in ACTIONS:
		var poses := poses_for(act, who)
		var frames := []
		var pts := []
		for i in poses.size():
			var img := rig(b, poses[i], i)
			if left:
				img = face_left(img)
			frames.append(img)
			var hf: Vector2 = FP(b, poses[i].hf) - Vector2(PV)
			var hb: Vector2 = FP(b, poses[i].hb) - Vector2(PV)
			if left:
				hf.x = -hf.x; hb.x = -hb.x
			pts.append({"hand_front": [int(round(hf.x)), int(round(hf.y))], "hand_back": [int(round(hb.x)), int(round(hb.y))]})
		var meta: Dictionary = ACTION_META[act]
		var info := {"loop": meta.loop, "facing": "esquerda" if left else "direita", "action": act,
			"note": desc + " " + meta.note}
		if meta.has("hit_frame"):
			info["hit_frame"] = meta.hit_frame
			var hp: Array = pts[meta.hit_frame]["hand_back" if act == "heavy" else "hand_front"]
			info["hit_point"] = hp
			info["hit_point_note"] = "Ponto do contato relativo ao pivô (já no lado certo). fx_fight_hit/crit aqui."
		if meta.get("hold_last", false):
			info["hold_last"] = true
		info["hands"] = pts
		var fps: float = meta.fps * FIGHT_FPS_MUL[who]
		save_sheet(prefix + "_" + act + suffix, rel_dir + prefix + "_" + act + suffix + ".png", frames, snappedf(fps, 0.5), PV, info, contact)

func make_fighters() -> void:
	make_fighter_sheets(build_player("glove_old"), "fight_player", "fight/", false, "player",
		"Lutador do jogador em vista de luta (de lado, virado para a direita). Luva velha (cores r0/r1/r2).")
	for gid in ["glove_l1", "glove_l2", "glove_l3"]:
		make_fighter_sheets(build_player(gid), "fight_player", "fight/", false, "player",
			"Lutador do jogador com a %s (folha já pintada; mesmas poses, pivô e pontos da versão de luva velha)." % GLOVES[gid].name, false, "_" + gid)
		SHEETS.append(["fight_player_jab_" + gid, strip(F["fight_player_jab_" + gid]), FW])
	var descs := {
		"opp_warmup": "Dudu Alongado (aquecimento): magro, regata branca, calção verde-musgo, meião branco, faixa mole. Virado para a esquerda.",
		"opp_strong": "Brutão do Posto (forte): o mais largo, boné do posto, regata com graxa, macacão amarrado, luva com fita isolante vermelha. Virado para a esquerda.",
		"opp_fast": "Dinho Pulga (rápido): baixo e magro, moletom azul com capuz, bandana, tênis laranja de cadarço solto, saltita. Virado para a esquerda.",
		"opp_tank": "Seu Muralha (resistente, cinturão): alto, barriga firme, bigode grisalho, camiseta amarela de várzea, cinturão de pano. Virado para a esquerda.",
	}
	for oid in ["opp_warmup", "opp_strong", "opp_fast", "opp_tank"]:
		make_fighter_sheets(build_opp(oid), oid, "opponents/" + oid + "/", true, oid, descs[oid])

# ================================================================ folha de contato
func make_contact_sheet(path: String, title: String, only_prefix := "") -> void:
	var S := 3
	var W := 2600
	var gap := 18
	var x := gap
	var y := 50
	var row_h := 0
	var places := []
	for e in SHEETS:
		if only_prefix != "" and not str(e[0]).begins_with(only_prefix):
			continue
		var img: Image = e[1]
		var w: int = img.get_width() * S
		var h: int = img.get_height() * S + 22
		if x + w > W - gap:
			x = gap
			y += row_h + gap
			row_h = 0
		places.append([e, Vector2i(x, y)])
		x += maxi(w, L.text_w(str(e[0]), 2)) + gap
		row_h = maxi(row_h, h)
	var H := y + row_h + gap
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, title, gap, 14, "y1", 3, "ink")
	for pl in places:
		var e: Array = pl[0]
		var p: Vector2i = pl[1]
		var img: Image = e[1]
		var fw: int = e[2]
		L.text(out, str(e[0]), p.x, p.y, "cream", 2, "ink")
		var big: Image = img.duplicate()
		big.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
		var oy := p.y + 20
		for yy in range(0, big.get_height(), 6):
			for xx in range(0, big.get_width(), 6):
				L.R(out, p.x + xx, oy + yy, mini(6, big.get_width() - xx), mini(6, big.get_height() - yy), "d2" if ((xx + yy) / 6) % 2 == 0 else "g0")
		out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(p.x, oy))
		var nf := img.get_width() / fw
		for i in range(1, nf):
			L.R(out, p.x + i * fw * S, oy, 1, big.get_height(), "y0")
	out.save_png(path)

func debug_zoom(path: String, ids: Array, S := 4) -> void:
	var W := 0
	for it in ids:
		W += FW * S + 8
	var out: Image = L.blank(W, FH * S + 8)
	L.R(out, 0, 0, out.get_width(), out.get_height(), "g0")
	var x := 4
	for it in ids:
		var fr: Image = F[it[0]][it[1]].duplicate()
		fr.resize(fr.get_width() * S, fr.get_height() * S, Image.INTERPOLATE_NEAREST)
		out.blend_rect(fr, Rect2i(Vector2i.ZERO, fr.get_size()), Vector2i(x, 4))
		x += FW * S + 8
	out.save_png(path)

## Faixa reta (sem ponta redonda) ao longo do eixo a->b: para camisa, calção, cinto.
func seg_box(img: Image, a: Vector2, b: Vector2, wa: float, wb: float, ramp: Array, front: Vector2) -> void:
	a += Vector2(0.5, 0.5)
	b += Vector2(0.5, 0.5)
	var d := b - a
	var l2 := maxf(d.length_squared(), 0.0001)
	var rm := maxf(wa, wb) / 2.0 + 1.0
	for y in range(int(floor(minf(a.y, b.y) - rm)), int(ceil(maxf(a.y, b.y) + rm))):
		for x in range(int(floor(minf(a.x, b.x) - rm)), int(ceil(maxf(a.x, b.x) + rm))):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := (p - a).dot(d) / l2
			if t < 0.0 or t > 1.0:
				continue
			var r := lerpf(wa, wb, t) / 2.0
			var v := p - (a + d * t)
			var s := v.dot(front)
			if absf(s) <= r:
				var c = ramp[1]
				if s < -r + 1.5:
					c = ramp[0]
				elif s > r - 1.2:
					c = ramp[2]
				L.P(img, x, y, c)

# ================================================================ arena (estacionamento da borracharia, à noite)
func make_arena() -> void:
	var img: Image = L.blank(640, 360)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	L.R(img, 0, 0, 640, 360, "ink")
	# céu: noite, brilho fraco da cidade no horizonte
	L.dither(img, 0, 40, 640, 14, "b0")
	L.R(img, 0, 54, 640, 30, "b0")
	L.dither(img, 0, 70, 640, 10, "b1", 1)
	for i in 40:
		L.P(img, rng.randi_range(0, 639), rng.randi_range(2, 50), "g1" if i % 4 else "cream")
	# prédios ao longe (silhueta) dos dois lados
	for bx in [[0, 70, 44], [60, 62, 30], [560, 58, 40], [598, 66, 42]]:
		L.R(img, bx[0], bx[1], bx[2], 120, "d1")
		for k in 6:
			L.P(img, bx[0] + rng.randi_range(3, bx[2] - 4), bx[1] + rng.randi_range(4, 30), "y0" if k % 2 else "br2")
	# galpão: parede de chapa ondulada
	var wx0 := 88
	var wx1 := 556
	for x in range(wx0, wx1):
		var ph := (x - wx0) % 6
		var c := "st1"
		if ph == 0:
			c = "st0"
		elif ph == 3 or ph == 4:
			c = "st2"
		L.R(img, x, 70, 1, FLOOR_Y - 70, c)
	for i in 18:
		var cx := rng.randi_range(wx0 + 10, wx1 - 10)
		var cy := rng.randi_range(80, 225)
		L.ellipse_dither(img, cx, cy, rng.randi_range(4, 12), rng.randi_range(3, 9), "br1", i % 2)
	L.dither(img, wx0, FLOOR_Y - 12, wx1 - wx0, 12, "d2")
	L.R(img, wx0 - 4, 64, wx1 - wx0 + 8, 6, "d2"); L.R(img, wx0 - 4, 64, wx1 - wx0 + 8, 1, "g0"); L.R(img, wx0 - 4, 70, wx1 - wx0 + 8, 1, "ink")
	L.R(img, wx0 - 1, 70, 1, FLOOR_Y - 70, "d1"); L.R(img, wx1, 70, 1, FLOOR_Y - 70, "d1")
	# placa pintada à mão
	L.R(img, 150, 90, 150, 26, "ink"); L.R(img, 151, 91, 148, 24, "y0"); L.R(img, 151, 91, 148, 2, "y1")
	L.text(img, "BORRACHARIA", 160, 97, "br0", 2)
	for i in 60:
		L.P(img, rng.randi_range(151, 298), rng.randi_range(91, 114), "br3")
	L.R(img, 160, 116, 1, 4, "d1"); L.R(img, 290, 116, 1, 4, "d1")
	L.text(img, "24H", 304, 104, "cream", 1)
	# porta de enrolar fechada
	L.R(img, 382, 118, 124, FLOOR_Y - 118, "ink")
	var yy := 120
	while yy < FLOOR_Y:
		L.R(img, 384, yy, 120, 5, "st2"); L.R(img, 384, yy, 120, 1, "st3"); L.R(img, 384, yy + 4, 120, 1, "st0")
		yy += 6
	L.R(img, 438, FLOOR_Y - 14, 12, 3, "d1")
	L.text(img, "07", 432, 150, "cream", 2)
	L.dither(img, 384, 150, 120, 16, "st2", 1)
	# porta lateral com lâmpada pequena
	L.R(img, 124, 168, 30, FLOOR_Y - 168, "ink"); L.R(img, 126, 170, 26, FLOOR_Y - 170, "d2"); L.R(img, 146, 204, 3, 2, "g2")
	L.R(img, 136, 158, 6, 4, "y1"); L.P(img, 138, 158, "y2")
	# pilha de pneus e tambores (direita)
	for t in [[594, 246], [594, 232], [594, 218], [618, 248], [618, 234]]:
		L.ellipse(img, t[0], t[1], 13, 7, "d1"); L.ellipse(img, t[0], t[1] - 1, 12, 5, "d2"); L.ellipse(img, t[0], t[1] - 1, 5, 2, "ink")
	for dx in [522, 548]:
		L.R(img, dx, 212, 22, 40, "ink"); L.R(img, dx + 1, 213, 20, 38, "st1"); L.R(img, dx + 1, 213, 4, 38, "st0")
		L.R(img, dx + 1, 222, 20, 3, "r1"); L.R(img, dx + 1, 240, 20, 3, "r1"); L.R(img, dx + 14, 213, 2, 38, "st2")
		L.ellipse(img, dx + 11, 213, 10, 2, "st0")
	# cerca de alambrado + poste de luz de sódio (esquerda)
	for x in range(0, 86):
		for y in range(150, 250):
			if (x + y) % 6 == 0 or (x - y + 600) % 6 == 0:
				L.P(img, x, y, "g0")
	for px in [6, 46, 84]:
		L.R(img, px, 146, 2, 104, "st1")
	L.R(img, 28, 84, 3, 166, "st0"); L.R(img, 28, 84, 16, 3, "st0"); L.R(img, 38, 86, 9, 3, "y1")
	# chão: asfalto
	L.R(img, 0, FLOOR_Y, 640, 120, "d2")
	for i in 2600:
		L.P(img, rng.randi_range(0, 639), rng.randi_range(FLOOR_Y, 359), "g0" if i % 3 else "d1")
	L.R(img, 0, FLOOR_Y, 640, 1, "d1")
	# faixas de vaga apagadas, em perspectiva (ponto de fuga 320,-28)
	for xb in [40, 170, 470, 600]:
		var xf: float = 320 + (xb - 320) * (360.0 + 28.0) / (FLOOR_Y + 28.0)
		for k in range(0, 120):
			var t := k / 120.0
			if int(k / 6) % 3 != 2:
				L.P(img, int(lerpf(xb, xf, t)), FLOOR_Y + k, "g2")
	L.R(img, 0, 262, 640, 1, "g1")
	for i in 7:
		L.ellipse_dither(img, rng.randi_range(40, 600), rng.randi_range(270, 350), rng.randi_range(6, 16), rng.randi_range(2, 4), "d1", i % 2)
	# carro estacionado com o farol aceso
	var car: Image = L.blank(118, 44)
	L.R(car, 4, 18, 110, 18, "d1"); L.rrect(car, 22, 4, 62, 18, "d1")
	L.R(car, 30, 8, 22, 10, "b0"); L.R(car, 56, 8, 22, 10, "b0"); L.R(car, 31, 9, 6, 1, "b1")
	L.R(car, 4, 20, 110, 1, "g0")
	L.ellipse(car, 24, 36, 8, 7, "ink"); L.ellipse(car, 24, 36, 3, 3, "g0")
	L.ellipse(car, 92, 36, 8, 7, "ink"); L.ellipse(car, 92, 36, 3, 3, "g0")
	L.R(car, 108, 22, 6, 5, "y2"); L.R(car, 4, 22, 4, 4, "r1")
	L.stamp(img, car, 2, 210)
	# luz
	L.light(img, Rect2i(0, 60, 640, 300), Vector2(321, 250), 300.0, 1.5, 3.6, -3, 1, 1.0)
	# facho do farol no chão
	for y in range(236, 330):
		for x in range(118, 330):
			var dv := Vector2(x - 118, (y - 236) * 2.4)
			var ang := absf(atan2(dv.y, dv.x) - 0.35)
			if ang < 0.32 and dv.length() < 230.0:
				var thr: float = (L.BAYER[y % 4][x % 4] + 0.5) / 16.0
				if thr > dv.length() / 260.0 + ang * 1.5:
					img.set_pixel(x, y, L.shade(img.get_pixel(x, y), 1))
	# brilho das lâmpadas pequenas
	for g in [[42, 90, 12], [139, 160, 8]]:
		for a in 24:
			var an := a * TAU / 24.0
			L.P(img, int(g[0] + cos(an) * g[2]), int(g[1] + sin(an) * g[2] * 0.8), "y0" if a % 2 else "br3")
	# riscado de giz do "ringue" no chão
	for a in 180:
		if a % 3 == 2:
			continue
		var an := a * TAU / 180.0
		L.P(img, int(321 + cos(an) * 168), int(316 + sin(an) * 30), "g3")
	# cabo do refletor
	L.line(img, 92, 66, LAMP_POS.x, LAMP_POS.y, "ink"); L.line(img, LAMP_POS.x, LAMP_POS.y, 552, 66, "ink")
	save_sheet("arena_bg", "fight/arena_bg.png", [img], 0, Vector2i.ZERO, {"pos": [0, 0], "layer": "fundo", "z": -100,
		"note": "Arena única da Fase 3: estacionamento de uma borracharia à noite (galpão de chapa, placa pintada, porta de enrolar, pneus, carro com farol aceso, alambrado, poste de sódio). Chão com o 'ringue' riscado a giz. Luz já aplicada. y 0..45 é céu escuro: o HUD de luta fica por cima. Público e refletor são sprites à parte."}, false)
	SHEETS.append(["arena_bg (metade)", half(img), 320])
	make_arena_lamp()
	make_crowd()

func half(img: Image) -> Image:
	var h: Image = img.duplicate()
	h.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_NEAREST)
	return h

func make_arena_lamp() -> void:
	var frames := []
	for f in 3:
		var im: Image = L.blank(40, 40)
		var sx := 1 if f == 1 else 0
		L.R(im, 20, 0, 1, 8, "ink")
		L.trap(im, 8, 16, 16 + sx, 24 + sx, 10 + sx, 30 + sx, "st1")
		L.R(im, 10 + sx, 16, 21, 1, "st0"); L.R(im, 16 + sx, 8, 9, 1, "st2")
		var lc := "y0" if f == 2 else "y1"
		L.R(im, 14 + sx, 17, 13, 2, lc); L.R(im, 17 + sx, 17, 7, 1, "y2" if f != 2 else "y1")
		if f != 2:
			for a in 30:
				var an := PI * 0.1 + a * PI * 0.8 / 29.0
				L.P(im, int(20.5 + sx + cos(an) * 16), int(18 + sin(an) * 14), "y0" if a % 2 else "br3")
		frames.append(im)
	save_sheet("arena_lamp", "fight/arena_lamp.png", frames, 0, Vector2i(20, 0), {"pos": xy(LAMP_POS), "layer": "frente_do_fundo", "z": -50,
		"anim": {"idle": [0], "flicker": [2, 0], "swing": [1, 0, 1, 0]},
		"frames_note": "0 acesa, 1 balanço 1 px (usar flip_h para o outro lado), 2 piscada.",
		"note": "Refletor de obra pendurado no cabo, em cima do ringue. Balançar no golpe forte/crítico e no K.O."})

func person(img: Image, x: int, fy: int, h: int, w: int, arms: int, body: String, rim: String, extra := "") -> void:
	var hy := fy - h
	L.ellipse(img, x, hy + 4, 4, 4.5, body)
	L.rrect(img, x - w / 2, hy + 8, w, h - 8, body)
	L.R(img, x - w / 2 + 1, hy + 8, w - 2, 1, rim)
	L.P(img, x - 1, hy, rim); L.P(img, x, hy, rim); L.P(img, x + 1, hy, rim)
	if arms >= 1:
		L.R(img, x + w / 2 - 2, hy - 6, 3, 15, body); L.R(img, x + w / 2 - 3, hy - 9, 5, 4, body)
		L.P(img, x + w / 2 - 1, hy - 9, rim)
		if extra == "cash":
			L.R(img, x + w / 2 - 3, hy - 12, 5, 3, "gr2"); L.R(img, x + w / 2 - 3, hy - 12, 5, 1, "gr3")
		if extra == "phone":
			L.R(img, x + w / 2 - 2, hy - 13, 3, 4, "b3"); L.P(img, x + w / 2 - 1, hy - 12, "white")
	if arms >= 2:
		L.R(img, x - w / 2 - 1, hy - 6, 3, 15, body); L.R(img, x - w / 2 - 2, hy - 9, 5, 4, body)
		L.P(img, x - w / 2, hy - 9, rim)
	if extra == "cap":
		L.R(img, x - 4, hy - 1, 9, 3, rim); L.R(img, x + 3, hy + 1, 4, 1, rim)

func make_crowd() -> void:
	var specs := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var x := 14
	while x < 630:
		specs.append([x, rng.randi_range(-3, 3), rng.randi_range(30, 38), rng.randi_range(14, 18), rng.randi(), rng.randf()])
		x += rng.randi_range(16, 24)
	var frames := []
	for f in 2:
		var im: Image = L.blank(640, 100)
		for s in specs:
			var dist := absf(float(s[0]) - 321.0)
			var rim := "g0" if dist < 200 else "d2"
			var arms := 0
			var r: float = s[5]
			if f == 1:
				arms = 2 if r < 0.35 else (1 if r < 0.75 else 0)
			elif r < 0.12:
				arms = 1
			var ex := ""
			if int(s[4]) % 7 == 0:
				ex = "phone"
			elif int(s[4]) % 7 == 3:
				ex = "cash"
			elif int(s[4]) % 5 == 1:
				ex = "cap"
			if ex == "phone" or ex == "cash":
				arms = maxi(arms, 1)
			var bob := 1 if (f == 1 and int(s[4]) % 2 == 0) else 0
			person(im, s[0], 88 + s[1] - bob, s[2], s[3], arms, "d1", rim, ex)
		frames.append(im)
	save_sheet("arena_crowd_back", "fight/arena_crowd_back.png", frames, 4, Vector2i.ZERO, {"pos": [0, 180], "layer": "fundo", "z": -60, "loop": true,
		"anim": {"idle": [0], "cheer": [1, 0, 1, 0]},
		"note": "Público em silhueta atrás do ringue (pés em y≈268). 0 parado, 1 vibrando (braços para cima, celular, dinheiro de aposta). Tocar 'cheer' no golpe forte, crítico e K.O."}, false)
	SHEETS.append(["arena_crowd_back", frames[0].duplicate(), 640])
	var ff := []
	for f in 2:
		var im: Image = L.blank(640, 48)
		var fx := [10, 46, 84, 120, 520, 556, 596, 632]
		for i in fx.size():
			var bob := 1 if (f == 1 and i % 2 == 0) else 0
			var arms := 1 if (f == 1 and i % 3 == 0) else 0
			L.ellipse(im, fx[i], 20 - bob, 9, 10, "ink")
			L.rrect(im, fx[i] - 17, 30 - bob, 34, 20, "ink")
			L.R(im, fx[i] - 4, 10 - bob, 9, 1, "d1"); L.R(im, fx[i] - 15, 30 - bob, 30, 1, "d1")
			if arms == 1:
				L.R(im, fx[i] + 10, 4 - bob, 6, 30, "ink"); L.R(im, fx[i] + 9, 0, 8, 6, "ink"); L.R(im, fx[i] + 10, 0, 6, 1, "d1")
		ff.append(im)
	save_sheet("arena_crowd_front", "fight/arena_crowd_front.png", ff, 4, Vector2i.ZERO, {"pos": [0, 312], "layer": "frente", "z": 50, "loop": true,
		"anim": {"idle": [0], "cheer": [1, 0, 1, 0]},
		"note": "Público na frente da câmera, só nos cantos de baixo (nunca cobre os lutadores no centro). Desenhar por cima de tudo menos do HUD."}, false)
	SHEETS.append(["arena_crowd_front", ff[0].duplicate(), 640])

# ================================================================ efeitos
func make_fx() -> void:
	var c16 := V(16, 16)
	var hf := []
	for f in 4:
		var im: Image = L.blank(32, 32)
		if f == 0:
			L.ellipse(im, 16, 16, 5, 5, "white"); L.ellipse(im, 16, 16, 2.5, 2.5, "y2")
		else:
			var dirs := [V(1, 0), V(0.8, -0.6), V(0.8, 0.6), V(0.2, -1), V(0.2, 1), V(1, -0.25), V(1, 0.25)]
			var r0: float = [0, 3, 7, 11][f]
			var r1: float = [0, 11, 14, 15][f]
			for d in dirs:
				var dn: Vector2 = d.normalized()
				var a: Vector2 = c16 + dn * r0 - V(4, 0)
				var b: Vector2 = c16 + dn * r1 - V(4, 0)
				if f == 3:
					L.P(im, int(b.x), int(b.y), "g3")
				else:
					L.line(im, int(a.x), int(a.y), int(b.x), int(b.y), "white" if f == 1 else "cream")
			if f == 1:
				L.ellipse(im, 12, 16, 3, 3, "y2")
		hf.append(im)
	save_sheet("fx_fight_hit", "fight/fx_fight_hit.png", hf, 15, Vector2i(16, 16), {"loop": false,
		"note": "Impacto do golpe na luta. Pôr no ponto de contato (pivô do atacante + hit_point). Desenhado para golpe do jogador (traços para a direita); golpe do adversário = flip_h."})
	var cf := []
	for f in 5:
		var im: Image = L.blank(48, 48)
		var c := V(24, 24)
		match f:
			0:
				L.ellipse(im, 24, 24, 7, 7, "white"); L.ellipse(im, 24, 24, 4, 4, "y2")
			1, 2:
				var lo := 15.0 if f == 1 else 21.0
				var sh := 9.0 if f == 1 else 12.0
				var st := 0.0 if f == 1 else 8.0
				for k in 8:
					var an := k * PI / 4.0
					var ln := lo if k % 2 == 0 else sh
					var d := V(cos(an), sin(an))
					var a := c + d * st
					var b := c + d * ln
					L.line(im, int(round(a.x)), int(round(a.y)), int(round(b.x)), int(round(b.y)), "y1" if f == 1 else "r3")
					L.line(im, int(round(a.x)) + 1, int(round(a.y)), int(round(b.x)) + 1, int(round(b.y)), "y2" if f == 1 else "r2")
				if f == 1:
					L.ellipse(im, 24, 24, 5, 5, "y2")
				L.ring(im, 24, 24, 10 + f * 4, 10 + f * 4, 1, "r3" if f == 1 else "y0")
			3:
				for k in 16:
					var an := k * TAU / 16.0
					if k % 2 == 0:
						L.P(im, int(24 + cos(an) * 21), int(24 + sin(an) * 21), "y1")
						L.P(im, int(24 + cos(an) * 20), int(24 + sin(an) * 20), "r3")
			4:
				for k in 8:
					var an := k * PI / 4.0 + PI / 8.0
					L.P(im, int(24 + cos(an) * 22), int(24 + sin(an) * 22), "y0")
		cf.append(outline_in_place(im) if (f == 1 or f == 2) else im)
	save_sheet("fx_fight_crit", "fight/fx_fight_crit.png", cf, 15, Vector2i(24, 24), {"loop": false,
		"note": "Crítico: estrela grande por cima do fx_fight_hit, junto com o número 2x em r3 com '!', tremida de 2 px e o refletor balançando."})
	var wf := []
	for f in 3:
		var im: Image = L.blank(40, 24)
		for k in 3:
			var off := f * 6 - k * 4
			for a in 14:
				var t := a / 13.0
				var x := int(36 - t * 30 - off)
				var y := int(12 - sin(t * PI) * (6 - k * 2) + k * 3)
				if x >= 0 and x < 40 and (f < 2 or a % 2 == 0):
					L.P(im, x, y, "cream" if k == 0 else "g3")
		wf.append(im)
	save_sheet("fx_whoosh", "fight/fx_whoosh.png", wf, 14, Vector2i(20, 12), {"loop": false,
		"note": "Esquiva: arcos de vento onde o soco passou (na altura da cabeça de quem esquivou). Desenhado para o soco do adversário que erra o jogador; flip_h quando o adversário esquiva. Junto com o texto ESQUIVOU."})
	var bf := []
	for f in 3:
		var im: Image = L.blank(24, 24)
		var r := 5.0 + f * 3.0
		for a in 12:
			var an := -PI / 2.0 + a * PI / 11.0
			if f == 2 and a % 2 == 1:
				continue
			L.P(im, int(10 + cos(an) * r), int(12 + sin(an) * r), "b3" if f < 2 else "st3")
		if f == 0:
			L.R(im, 9, 10, 3, 4, "white")
		bf.append(im)
	save_sheet("fx_block", "fight/fx_block.png", bf, 14, Vector2i(10, 12), {"loop": false,
		"note": "Defesa: faísca curta nas luvas de quem defendeu (pivô + hands[i].hand_front). Para quem está à direita, flip_h."})
	var sf := []
	for f in 4:
		var im: Image = L.blank(24, 16)
		for side in [-1, 1]:
			var x: int = 12 + side * (3 + f * 2)
			var y: int = 8 - (2 if f < 2 else 0) + (f - 2 if f >= 2 else 0) * 2
			if f < 3:
				L.P(im, x, y, "white"); L.P(im, x, y + 1, "b3"); L.P(im, x + side, y + 1, "b2")
			else:
				L.P(im, x, y + 2, "b2")
		sf.append(im)
	save_sheet("fx_sweat", "fight/fx_sweat.png", sf, 8, Vector2i(12, 12), {"loop": true,
		"note": "Suor saindo da cabeça (cansado). Pôr em pivô + head_point do lutador (ver fight_layout.head_point). Loop enquanto estiver em 'tired'."})
	var kf := []
	for f in 6:
		var im: Image = L.blank(32, 16)
		for k in 3:
			var an := f * TAU / 6.0 + k * TAU / 3.0
			var x := int(16 + cos(an) * 12)
			var y := int(8 + sin(an) * 4)
			var big := sin(an) > -0.2
			L.P(im, x, y, "y2" if big else "y0")
			if big:
				L.P(im, x - 1, y, "y1"); L.P(im, x + 1, y, "y1"); L.P(im, x, y - 1, "y1"); L.P(im, x, y + 1, "y1")
		kf.append(outline_in_place(im))
	save_sheet("fx_ko_stars", "fight/fx_ko_stars.png", kf, 10, Vector2i(16, 8), {"loop": true,
		"note": "Estrelinhas girando em cima da cabeça de quem caiu (último quadro do 'ko'; posição em fight_layout.ko_head_point)."})
	var df := []
	for f in 4:
		var im: Image = L.blank(64, 12)
		var rx := 12.0 + f * 7.0
		L.ellipse_dither(im, 32, 8, rx, 3.0, "g2" if f < 3 else "g1", f)
		if f < 2:
			L.ellipse_dither(im, 32, 8, rx - 5, 2.0, "g3", f + 1)
		df.append(im)
	save_sheet("fx_dust_fall", "fight/fx_dust_fall.png", df, 12, Vector2i(32, 10), {"loop": false,
		"note": "Poeira quando o corpo bate no chão (quadro 3 do 'ko'). Pôr no pivô de quem caiu, deslocado 14 px para o lado da queda (para trás)."})

# ================================================================ luvas: item, ícone, cursor, mãos na garagem
func glove_small(gid: String, w: int, h: int, pressed := false) -> Image:
	var g: Image = L.blank(w, h)
	if pressed:
		draw_glove(g, 0, 1, w, h - 1, GLOVES[gid])
	else:
		draw_glove(g, 0, 0, w, h, GLOVES[gid])
	return g

func make_gloves() -> void:
	for gid in ["glove_old", "glove_l1", "glove_l2", "glove_l3"]:
		var nm: String = GLOVES[gid].name
		if gid != "glove_old":
			save_sheet(gid, "equipment/%s.png" % gid, [L.outlined(glove_small(gid, 10, 11))], 0, Vector2i(6, 6), {
				"note": "%s: item 12x13 (mesmo tamanho do glove_old). Mesma arte das mãos (garagem e luta) e do cursor." % nm})
			# cursor
			var frames := []
			for pr in [false, true]:
				frames.append(L.outlined(L.outlined(glove_small(gid, 10, 10, pr), "white"), "ink"))
			save_sheet("cursor_" + gid, "ui/cursor_%s.png" % gid, frames, 0, Vector2i(7, 6), {"hotspot": [7, 6],
				"frames_note": "0 normal, 1 pressionado.", "note": "Cursor-luva da %s (igual ao cursor_glove da luva velha)." % nm})
			for s in [2, 3]:
				for i in 2:
					var b: Image = frames[i].duplicate()
					b.resize(b.get_width() * s, b.get_height() * s, Image.INTERPOLATE_NEAREST)
					var st := "normal" if i == 0 else "pressed"
					var rel := "ui/cursor_%s_%s_x%d.png" % [gid, st, s]
					b.save_png(OUT + rel)
					M["cursor_%s_%s_x%d" % [gid, st, s]] = {"file": RES + rel, "frame_size": [b.get_width(), b.get_height()], "frames": 1, "fps": 0,
						"pivot": [7 * s, 6 * s], "hotspot": [7 * s, 6 * s], "note": "Cursor do sistema já ampliado %dx (Input.set_custom_mouse_cursor)." % s}
		# ícone da loja 16x16
		var ic: Image = L.blank(16, 16)
		L.stamp(ic, glove_small(gid, 11, 12), 3, 2)
		save_sheet("icon_" + gid, "ui/icon_%s.png" % gid, [ic], 0, Vector2i.ZERO, {"note": "Ícone 16x16 da %s para a LOJA (cartão do item)." % nm})
		# luvas penduradas no prego (tela de aposentadoria)
		var hg: Image = L.blank(48, 56)
		L.R(hg, 23, 2, 3, 3, "st2"); L.P(hg, 23, 2, "st3"); L.R(hg, 24, 5, 1, 2, "st0")
		var gb: Image = L.blank(20, 24)
		draw_glove(gb, 0, 0, 16, 18, GLOVES[gid], true)
		var gf: Image = L.blank(20, 24)
		draw_glove(gf, 0, 0, 16, 18, GLOVES[gid], false)
		L.line(hg, 24, 5, 14, 30, "cream"); L.line(hg, 24, 5, 32, 32, "g3")
		L.stamp(hg, gb, 25, 31)
		L.stamp(hg, gf, 7, 28)
		save_sheet("art_hung_" + gid, "ui/art_hung_%s.png" % gid, [hg], 0, Vector2i(24, 2), {
			"note": "Luvas penduradas no prego pelo cadarço ('pendurar as luvas'): ilustração da tela SAIU POR CIMA e da confirmação de aposentar. Usar a da luva equipada."})
	make_garage_glove_variants()

## O lutador da garagem com cada luva de loja (mesmas poses da Fase 2: make_sprites_fase2.gd).
func make_garage_glove_variants() -> void:
	var base := {"skin": ["sk0", "sk1", "sk2"], "shirt": ["cream", "white", "white"],
		"shorts": ["b0", "b1", "b2"], "gloves": ["r0", "r1", "r2"], "hair": ["br0", "br1"]}
	var idle := []
	var dys := [0, 0, 1, 1]
	var gd := [0, 1, 1, 0]
	for i in 4:
		var g := V(0, gd[i])
		idle.append(L.pose({"dy": dys[i], "bhand": V(14, 16) + g, "fhand": V(32, 15) + g}))
	var punch := [L.pose(), L.pose({"lean": -1, "felb": V(29, 31), "fhand": V(30, 17)}),
		L.pose({"lean": 1, "fsh": V(30, 24), "felb": V(36, 22), "fhand": V(41, 20), "fknee": V(27, 57), "bhand": V(15, 17)}),
		L.pose({"felb": V(34, 27), "fhand": V(37, 18)})]
	var rope := []
	for f in 4:
		var b := {"bsh": V(15, 25), "belb": V(11, 34), "bhand": V(10, 42), "fsh": V(29, 24), "felb": V(33, 33), "fhand": V(34, 42),
			"bknee": V(18, 57), "bfoot": V(17, 63), "fknee": V(25, 57), "ffoot": V(25, 63)}
		match f:
			0:
				b["bhand"] = V(9, 40); b["fhand"] = V(35, 40)
			1:
				b["dy"] = 1; b["bknee"] = V(19, 58); b["fknee"] = V(27, 58); b["bhand"] = V(11, 43); b["fhand"] = V(35, 43)
			2:
				b["lift"] = 3; b["bfoot"] = V(18, 62); b["ffoot"] = V(26, 62); b["bknee"] = V(19, 56); b["fknee"] = V(27, 56)
				b["bhand"] = V(11, 44); b["fhand"] = V(33, 44)
			3:
				b["lift"] = 1; b["bhand"] = V(10, 42); b["fhand"] = V(34, 41)
		rope.append(L.pose(b))
	var run := [
		L.pose({"lean": 1, "fhand": V(31, 25), "felb": V(33, 33), "bhand": V(19, 21), "belb": V(13, 29), "fknee": V(30, 55), "ffoot": V(32, 63), "bknee": V(15, 57), "bfoot": V(10, 60)}),
		L.pose({"dy": -1, "lean": 1, "fhand": V(30, 21), "felb": V(33, 29), "bhand": V(17, 25), "belb": V(11, 32), "fknee": V(27, 56), "ffoot": V(25, 63), "bknee": V(21, 55), "bfoot": V(15, 59)}),
		L.pose({"lean": 1, "fhand": V(28, 27), "felb": V(30, 33), "bhand": V(21, 19), "belb": V(14, 27), "bknee": V(27, 55), "bfoot": V(29, 63), "fknee": V(22, 57), "ffoot": V(16, 60)}),
		L.pose({"dy": -1, "lean": 1, "fhand": V(30, 23), "felb": V(32, 31), "bhand": V(18, 23), "belb": V(12, 30), "bknee": V(24, 56), "bfoot": V(22, 63), "fknee": V(27, 55), "ffoot": V(20, 59)})]
	var sets := {"fighter_idle": [idle, false, 4.0], "fighter_punch": [punch, false, 12.0], "fighter_rope": [rope, false, 10.0], "fighter_run": [run, true, 12.0]}
	for gid in ["glove_l1", "glove_l2", "glove_l3"]:
		var gdef: Dictionary = GLOVES[gid]
		var o := base.duplicate()
		o["glove_fn"] = func(img: Image, x: int, y: int, w: int, h: int, back: bool) -> void: draw_glove(img, x, y, w, h, gdef, back)
		for sid in sets:
			var frames := []
			for p in sets[sid][0]:
				var im: Image = L.character(o, p)
				if sets[sid][1]:
					im.flip_x()
				frames.append(im)
			var src: Dictionary = OLD.get("sprites", {}).get(sid, {})
			var info := {}
			for k in src:
				if k not in ["file", "frame_size", "frames", "fps", "pivot"]:
					info[k] = src[k]
			info["note"] = "Igual a %s (mesmo quadro, pivô e posições), com a %s nas mãos." % [sid, gdef.name]
			var pv: Array = src.get("pivot", [22, 67])
			save_sheet(sid + "_" + gid, "characters/%s_%s.png" % [sid, gid], frames, sets[sid][2], Vector2i(int(pv[0]), int(pv[1])), info, gid == "glove_l1" and sid == "fighter_punch")

# ================================================================ UI
func btn(bg: String, pressed: bool, flat: bool) -> Image:
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
	return img

func icon9(draw: Callable) -> Image:
	var im: Image = L.blank(9, 9)
	draw.call(im)
	return outline_in_place(im)

func make_ui() -> void:
	var NS2 := {"left": 2, "top": 2, "right": 2, "bottom": 2}
	# ---- botões LUTAR! e APOSENTAR (mesma geometria/margens dos ui_button_* da Fase 2)
	for kind in [["fight", "r1", "r2", "y2"], ["retire", "p0", "p1", "p2"]]:
		var states := {"normal": [kind[1], false, false], "hover": [kind[2], false, false], "pressed": [kind[1], true, false], "disabled": ["d1", false, true]}
		for st in states:
			var s: Array = states[st]
			var mg := {"left": 2, "top": 3 if s[1] else 2, "right": 2, "bottom": 3 if s[1] else 4}
			save_sheet("ui_button_%s_%s" % [kind[0], st], "ui/ui_button_%s_%s.png" % [kind[0], st], [btn(s[0], s[1], s[2])], 0, Vector2i.ZERO,
				{"nine_slice": mg, "text_color": "g1" if st == "disabled" else kind[3],
				"note": ("Botão LUTAR! (vermelho = arriscar). Texto 2x." if kind[0] == "fight" else "Botão APOSENTAR (roxo = Legado). Texto 1x.") + " 9-slice igual aos ui_button_* da Fase 2; sombra ink 1 px no texto."})
	# ícones dos botões
	var ifi: Image = L.blank(16, 16)
	var gb: Image = L.blank(10, 11); draw_glove(gb, 0, 0, 9, 10, GLOVES.glove_old, true)
	var gf: Image = L.blank(10, 11); draw_glove(gf, 0, 0, 9, 10, GLOVES.glove_old)
	gf.flip_x()
	L.stamp(ifi, gb, 1, 2); L.stamp(ifi, gf, 6, 4)
	save_sheet("icon_fight", "ui/icon_fight.png", [ifi], 0, Vector2i.ZERO, {"note": "Ícone 16x16 para o botão LUTAR! (duas luvas se encontrando)."})
	var ire: Image = L.blank(16, 16)
	L.R(ire, 7, 0, 2, 2, "st2"); L.line(ire, 8, 2, 4, 8, "cream"); L.line(ire, 8, 2, 12, 8, "g3")
	var g1: Image = L.blank(7, 8); draw_glove(g1, 0, 0, 6, 7, GLOVES.glove_old, true)
	var g2: Image = L.blank(7, 8); draw_glove(g2, 0, 0, 6, 7, GLOVES.glove_old)
	L.stamp(ire, g1, 9, 8); L.stamp(ire, g2, 1, 7)
	save_sheet("icon_retire", "ui/icon_retire.png", [ire], 0, Vector2i.ZERO, {"note": "Ícone 16x16 para APOSENTAR (luvas penduradas)."})
	# ---- barras de vida
	var hpf: Image = L.blank(16, 12)
	L.R(hpf, 0, 0, 16, 12, "ink"); L.R(hpf, 1, 1, 14, 10, "d2"); L.R(hpf, 1, 1, 14, 1, "g0"); L.R(hpf, 1, 10, 14, 1, "d1")
	L.R(hpf, 2, 2, 12, 8, "d1")
	for x in range(2, 14):
		for y in range(2, 10):
			if (x + y) % 2 == 0:
				L.P(hpf, x, y, "ink")
	save_sheet("ui_hp_frame", "ui/ui_hp_frame.png", [hpf], 0, Vector2i.ZERO, {"nine_slice": NS2,
		"note": "Moldura + fundo vazio da barra de vida (12 px de altura). O preenchimento fica dentro, 2 px de margem (área útil = altura 8). Jogador: enche da esquerda; adversário: fill_mode da direita para a esquerda (a barra encolhe para o lado do retrato)."})
	for f in [["ui_hp_fill", ["gr1", "gr2", "gr3"], "Vida normal."], ["ui_hp_fill_low", ["r1", "r2", "r3"], "Vida baixa (<= 25%): troca de textura e pisca 2 quadros."],
			["ui_hp_trail", ["y0", "y1", "y2"], "Rastro do dano: fica atrás do preenchimento e encolhe 0,4 s depois do golpe (mostra o tamanho do golpe)."]]:
		var im: Image = L.blank(3, 8)
		var rp: Array = f[1]
		L.R(im, 0, 0, 3, 8, rp[1]); L.R(im, 0, 0, 3, 2, rp[2]); L.R(im, 0, 7, 3, 1, rp[0])
		save_sheet(f[0], "ui/%s.png" % f[0], [im], 0, Vector2i.ZERO, {"nine_slice": {"left": 1, "top": 0, "right": 1, "bottom": 0}, "note": f[2] + " Esticar na horizontal dentro do ui_hp_frame."})
	# ---- moldura de retrato 36x36
	for v in [["ui_portrait_frame", "g0", "g1"], ["ui_portrait_frame_gold", "y0", "y1"]]:
		var pf: Image = L.blank(36, 36)
		L.R(pf, 0, 0, 36, 36, "ink"); L.R(pf, 1, 1, 34, 34, v[1]); L.R(pf, 1, 1, 34, 1, v[2]); L.R(pf, 1, 1, 1, 34, v[2])
		L.R(pf, 2, 2, 32, 32, "ink")
		pf.fill_rect(Rect2i(2, 2, 32, 32), Color(0, 0, 0, 0))
		for c in [V(1, 1), V(34, 1), V(1, 34), V(34, 34)]:
			L.P(pf, int(c.x), int(c.y), "white" if v[1] == "y0" else "g2")
		save_sheet(v[0], "ui/%s.png" % v[0], [pf], 0, Vector2i.ZERO, {"inner": [2, 2, 32, 32],
			"note": "Moldura 36x36 do retrato 32x32 (furo em 2,2). " + ("Dourada: luta do cinturão / campeão." if v[1] == "y0" else "Padrão.")})
	# ---- táticas 16x16 e 9x9 (cores = atributo que a tática puxa)
	var ta: Image = L.blank(16, 16)
	L.R(ta, 0, 5, 4, 1, "r1"); L.R(ta, 1, 8, 3, 1, "r2"); L.R(ta, 0, 11, 4, 1, "r1")
	L.stamp(ta, glove_small_ramp(["r1", "r2", "r3"], 10, 11), 5, 2)
	save_sheet("icon_tactic_aggressive", "ui/icon_tactic_aggressive.png", [ta], 0, Vector2i.ZERO, {"note": "Tática AGRESSIVO (vermelho = Força): luva com traços de velocidade."})
	var td: Image = L.blank(16, 16)
	var shd: Image = L.blank(12, 13)
	L.R(shd, 0, 0, 12, 7, "y0"); L.R(shd, 1, 7, 10, 2, "y0"); L.R(shd, 2, 9, 8, 2, "y0"); L.R(shd, 4, 11, 4, 1, "y0"); L.R(shd, 5, 12, 2, 1, "y0")
	L.R(shd, 0, 0, 12, 1, "y1"); L.R(shd, 6, 0, 1, 12, "y1"); L.R(shd, 0, 1, 1, 6, "br3")
	L.stamp(td, shd, 2, 1)
	save_sheet("icon_tactic_defensive", "ui/icon_tactic_defensive.png", [td], 0, Vector2i.ZERO, {"note": "Tática DEFENSIVO (amarelo = Resistência): escudo."})
	var tc: Image = L.blank(16, 16)
	var arr: Image = L.blank(14, 13)
	L.ring(arr, 7, 6.5, 6, 6, 2, "b2")
	arr.fill_rect(Rect2i(0, 7, 7, 6), Color(0, 0, 0, 0))
	L.R(arr, 0, 5, 5, 2, "b3"); L.R(arr, 1, 7, 3, 1, "b3"); L.P(arr, 2, 8, "b3")
	L.R(arr, 8, 9, 3, 2, "b3")
	L.stamp(tc, arr, 1, 1)
	save_sheet("icon_tactic_counter", "ui/icon_tactic_counter.png", [tc], 0, Vector2i.ZERO, {"note": "Tática CONTRA-ATAQUE (azul = Agilidade): seta que volta."})
	for t in ["aggressive", "defensive", "counter"]:
		var big: Image = F["icon_tactic_" + t][0]
		var sm: Image = big.duplicate()
		sm.resize(9, 9, Image.INTERPOLATE_NEAREST)
		save_sheet("icon_tactic_%s_9" % t, "ui/icon_tactic_%s_9.png" % t, [sm], 0, Vector2i.ZERO, {"note": "Versão 9x9 (HUD da luta, ao lado do nome)."})
	# ---- risco: fundo 9-slice, ícone 9x9 e selo pronto
	var risks := {"easy": ["gr1", "gr2", "FÁCIL", "white"], "even": ["y0", "y1", "EQUILIBRADO", "ink"], "hard": ["r1", "r2", "PERIGOSO", "white"]}
	for rk in risks:
		var r: Array = risks[rk]
		var bgi: Image = L.blank(12, 11)
		L.R(bgi, 1, 0, 10, 11, "ink"); L.R(bgi, 0, 1, 12, 9, "ink")
		L.R(bgi, 1, 1, 10, 9, r[0]); L.R(bgi, 1, 1, 10, 1, r[1])
		save_sheet("ui_risk_" + rk, "ui/ui_risk_%s.png" % rk, [bgi], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 2, "right": 3, "bottom": 2},
			"text_color": r[3], "note": "Fundo do selo de risco %s (texto da fonte 5x7 por cima, cor %s)." % [r[2], r[3]]})
		var ico: Image = L.blank(9, 9)
		match rk:
			"easy":
				L.line(ico, 1, 4, 3, 6, "gr3"); L.line(ico, 3, 6, 7, 2, "gr3"); L.line(ico, 1, 5, 3, 7, "gr2"); L.line(ico, 3, 7, 7, 3, "gr2")
			"even":
				L.R(ico, 1, 2, 7, 2, "y1"); L.R(ico, 1, 5, 7, 2, "y1")
			"hard":
				L.icon_skull(ico, 0, 0, "cream")
		save_sheet("icon_risk_" + rk, "ui/icon_risk_%s.png" % rk, [outline_in_place(ico)], 0, Vector2i.ZERO, {"note": "Ícone 9x9 do risco %s (reforça a cor para quem não distingue verde/vermelho)." % r[2]})
		var w: int = L.text_w(r[2]) + 18
		var seal: Image = L.blank(w, 13)
		L.R(seal, 1, 0, w - 2, 13, "ink"); L.R(seal, 0, 1, w, 11, "ink")
		L.R(seal, 1, 1, w - 2, 11, r[0]); L.R(seal, 1, 1, w - 2, 1, r[1]); L.R(seal, 1, 11, w - 2, 1, L.shade(L.col(r[0]), -1))
		var ic2: Image = F["icon_risk_" + rk][0]
		seal.blend_rect(ic2, Rect2i(0, 0, 9, 9), Vector2i(3, 2))
		L.text(seal, r[2], 14, 3, r[3], 1, null if r[3] == "ink" else "ink")
		save_sheet("seal_risk_" + rk, "ui/seal_risk_%s.png" % rk, [seal], 0, Vector2i.ZERO, {"note": "Selo de risco pronto (ícone + texto %s). Usar este ou montar com ui_risk_%s + icon_risk_%s + texto." % [r[2], rk, rk]})
	# ---- dinheiro, fama, Legado (9x9 e 16x16)
	var mo: Image = L.blank(9, 9)
	L.ellipse(mo, 4.5, 4.5, 4.5, 4.5, "y0"); L.ellipse(mo, 4.0, 4.0, 3.5, 3.5, "y1")
	L.R(mo, 4, 1, 1, 7, "br1"); L.R(mo, 3, 2, 3, 1, "br1"); L.P(mo, 3, 3, "br1"); L.R(mo, 3, 4, 3, 1, "br1"); L.P(mo, 5, 5, "br1"); L.R(mo, 3, 6, 3, 1, "br1")
	save_sheet("icon_money", "ui/icon_money.png", [outline_in_place(mo)], 0, Vector2i.ZERO, {"note": "Dinheiro ($) 9x9, HUD (cor do número: y1)."})
	var mo16: Image = L.blank(16, 16)
	L.R(mo16, 1, 7, 11, 6, "gr1"); L.R(mo16, 1, 7, 11, 1, "gr2"); L.R(mo16, 5, 9, 3, 2, "gr2")
	L.R(mo16, 2, 5, 11, 6, "gr2"); L.R(mo16, 2, 5, 11, 1, "gr3"); L.R(mo16, 6, 7, 3, 2, "gr3")
	var coin: Image = mo.duplicate()
	L.stamp(mo16, coin, 6, 6)
	save_sheet("icon_money_16", "ui/icon_money_16.png", [outline_in_place(mo16)], 0, Vector2i.ZERO, {"note": "Dinheiro 16x16 (notas + moeda) para prêmio e loja."})
	var fa: Image = L.blank(9, 9)
	L.icon_star(fa, 0, 0, "p2")
	L.P(fa, 4, 2, "white")
	save_sheet("icon_fame", "ui/icon_fame.png", [outline_in_place(fa)], 0, Vector2i.ZERO, {"note": "Fama (estrela) 9x9, cor p2. Número da fama em p2."})
	var fa16: Image = fa.duplicate()
	fa16 = L.blank(16, 16)
	var rows := ["......##......", ".....####.....", ".....####.....", "##############", ".############.", "..##########..", "...########...", "...###..###...", "..###....###..", "..##......##.."]
	for i in rows.size():
		for j in rows[i].length():
			if rows[i][j] == "#":
				L.P(fa16, j + 1, i + 3, "p2" if i < 4 else "p1")
	L.R(fa16, 7, 4, 2, 2, "white")
	save_sheet("icon_fame_16", "ui/icon_fame_16.png", [outline_in_place(fa16)], 0, Vector2i.ZERO, {"note": "Fama 16x16 (tela de fim e prévia)."})
	var lg: Image = L.blank(9, 9)
	var flame := ["....#....", "...##....", "..###.#..", "..#####..", ".######..", ".###.##..", "..#..#...", "........."]
	for i in flame.size():
		for j in 9:
			if flame[i][j] == "#":
				L.P(lg, j, i + 1, "p1")
	L.P(lg, 3, 5, "p2"); L.P(lg, 4, 4, "p2"); L.P(lg, 4, 6, "white"); L.P(lg, 3, 6, "p2")
	save_sheet("icon_legacy", "ui/icon_legacy.png", [outline_in_place(lg)], 0, Vector2i.ZERO, {"note": "Legado 9x9: chama roxa (a que passa de um lutador para o próximo da linhagem). Cor p2."})
	var lg16: Image = L.blank(16, 16)
	var fl := ["......#.......", ".....##.......", "....###...#...", "....####.##...", "...########...", "..#########...", "..####.####...", "..###...###...", "..###...###...", "...##...##....", "....#####.....", "..##########..", ".############."]
	for i in fl.size():
		for j in fl[i].length():
			if fl[i][j] == "#":
				L.P(lg16, j + 1, i + 1, "p1" if i < 11 else "br1")
	L.R(lg16, 6, 8, 3, 3, "p2"); L.P(lg16, 7, 9, "white"); L.R(lg16, 2, 12, 11, 1, "br2")
	save_sheet("icon_legacy_16", "ui/icon_legacy_16.png", [outline_in_place(lg16)], 0, Vector2i.ZERO, {"note": "Legado 16x16 (chama num pires): tela de fim e confirmação de aposentar."})
	# ---- cinturão amador (o mesmo que o Seu Muralha usa: pano vermelho, fivela torta)
	var bi: Image = L.blank(16, 16)
	L.R(bi, 0, 6, 16, 5, "r1"); L.R(bi, 0, 6, 16, 1, "r2"); L.R(bi, 0, 10, 16, 1, "r0")
	L.P(bi, 0, 11, "r1"); L.P(bi, 15, 11, "r1"); L.P(bi, 2, 11, "r0")
	L.R(bi, 5, 3, 7, 10, "y0"); L.R(bi, 5, 3, 6, 1, "y1"); L.R(bi, 6, 2, 5, 1, "y0")
	L.R(bi, 7, 6, 3, 3, "br2"); L.P(bi, 8, 5, "br2"); L.P(bi, 12, 4, "y0")
	save_sheet("icon_belt_amateur", "ui/icon_belt_amateur.png", [outline_in_place(bi)], 0, Vector2i.ZERO, {"note": "Cinturão amador 16x16 (HUD, resumo, carreira com cinturão). Pano vermelho e fivela torta, o mesmo do Seu Muralha."})
	var b9: Image = bi.duplicate()
	b9.resize(9, 9, Image.INTERPOLATE_NEAREST)
	save_sheet("icon_belt_amateur_9", "ui/icon_belt_amateur_9.png", [b9], 0, Vector2i.ZERO, {"note": "Cinturão amador 9x9."})
	var bfr := []
	for f in 3:
		var bb: Image = L.blank(112, 48)
		var strap: Image = L.blank(110, 20)
		for x in 110:
			var sag := int(round(sin(x / 109.0 * PI) * 3))
			L.R(strap, x, 2 + sag, 1, 14, "r1"); L.P(strap, x, 2 + sag, "r2"); L.P(strap, x, 3 + sag, "r2"); L.P(strap, x, 15 + sag, "r0")
			if x % 4 == 0:
				L.P(strap, x, 9 + sag, "r0")   # costura do pano
			if x % 7 == 3:
				L.P(strap, x, 16 + sag, "r1")  # pano desfiado
		L.stamp(bb, strap, 1, 14)
		var plate: Image = L.blank(40, 34)
		L.rrect(plate, 0, 2, 38, 30, "y0"); L.R(plate, 2, 0, 34, 3, "y0")
		L.R(plate, 0, 2, 38, 2, "y1"); L.R(plate, 1, 28, 37, 2, "br3")
		L.ring(plate, 19, 16, 11, 10, 1, "br3")
		L.icon_star(plate, 15, 11, "br2")
		L.R(plate, 37, 0, 2, 4, "y0")    # canto torto
		for k in 3:
			L.P(plate, 4 + k * 13, 4, "y2")
		bfr.append(bb)
		L.stamp(bb, plate, 36, 6)
		var sx: int = [10, 20, 30][f]
		L.P(bb, 36 + sx, 12, "white"); L.P(bb, 35 + sx, 13, "y2"); L.P(bb, 37 + sx, 13, "y2"); L.P(bb, 36 + sx, 14, "white")
		L.P(bb, 36 + sx, 11, "y2"); L.P(bb, 36 + sx, 15, "y2")
	save_sheet("belt_amateur_big", "ui/belt_amateur_big.png", bfr, 6, Vector2i(56, 24), {"loop": true,
		"note": "Cinturão amador grande para a tela de conquista (CINTURÃO AMADOR). Brilho correndo na fivela (loop). Centralizar, pode ampliar 2x inteiro."})
	# ---- prévia ELE x VOCÊ
	var vs: Image = L.blank(32, 24)
	for y in 24:
		var hw := 12 - absi(y - 12)
		L.R(vs, 16 - hw - 4, y, (hw + 4) * 2, 1, "ink")
		if y > 0 and y < 23:
			L.R(vs, 16 - hw - 3, y, (hw + 3) * 2, 1, "r1" if y > 12 else "r2")
	L.text(vs, "X", 11, 6, "y2", 2, "ink")
	save_sheet("ui_vs_badge", "ui/ui_vs_badge.png", [vs], 0, Vector2i(16, 12), {"note": "Selo 'X' entre os retratos ELE x VOCÊ."})
	var win: Image = L.blank(16, 16)
	L.R(win, 0, 0, 16, 16, "ink"); L.R(win, 1, 1, 14, 14, "g0"); L.R(win, 2, 2, 12, 12, "d1"); L.R(win, 1, 1, 14, 1, "g1")
	for c in [V(3, 3), V(12, 3), V(3, 12), V(12, 12)]:
		L.P(win, int(c.x), int(c.y), "g1")
	save_sheet("ui_window", "ui/ui_window.png", [win], 0, Vector2i.ZERO, {"nine_slice": {"left": 5, "top": 5, "right": 5, "bottom": 5},
		"note": "Janela central (prévia da luta, confirmação de aposentar, vitória). Abre sobre a sala escurecida (ui_dim_dither)."})
	for t in [["neutral", "d2", "g0"], ["defeat", "r0", "r1"], ["retire", "p0", "p1"], ["victory", "br2", "y0"]]:
		var rb: Image = L.blank(16, 14)
		L.R(rb, 0, 0, 16, 14, "ink"); L.R(rb, 1, 1, 14, 12, t[1]); L.R(rb, 1, 1, 14, 1, t[2]); L.R(rb, 1, 11, 14, 2, L.shade(L.col(t[1]), -1))
		L.P(rb, 0, 0, Color(0, 0, 0, 0)); L.P(rb, 15, 0, Color(0, 0, 0, 0))
		save_sheet("ui_window_title_" + t[0], "ui/ui_window_title_%s.png" % t[0], [rb], 0, Vector2i.ZERO, {"nine_slice": {"left": 3, "top": 3, "right": 3, "bottom": 4},
			"note": "Faixa do título da janela (%s). Texto 1x ou 2x com sombra ink." % t[0]})
	for t in [["ui_stat_row", "d2", "g0"], ["ui_stat_row_lead", "r0", "r1"]]:
		var sr: Image = L.blank(12, 11)
		L.R(sr, 0, 0, 12, 11, t[1]); L.R(sr, 0, 0, 12, 1, t[2]); L.R(sr, 0, 10, 12, 1, "d1")
		save_sheet(t[0], "ui/%s.png" % t[0], [sr], 0, Vector2i.ZERO, {"nine_slice": {"left": 1, "top": 1, "right": 1, "bottom": 1},
			"note": "Linha de atributo da prévia (ELE | atributo | VOCÊ)." + (" Versão destaque: o atributo em que ELE está muito à frente." if t[1] == "r0" else "")})
	var ld: Image = L.blank(7, 7)
	L.R(ld, 3, 0, 1, 7, "r2"); L.R(ld, 2, 1, 3, 1, "r2"); L.R(ld, 1, 2, 5, 1, "r2"); L.R(ld, 0, 3, 7, 1, "r2"); L.R(ld, 2, 4, 3, 3, "r2"); L.P(ld, 3, 1, "r3")
	save_sheet("icon_lead", "ui/icon_lead.png", [L.outlined(ld)], 0, Vector2i.ZERO, {"note": "Seta 9x9 'ele está muito à frente' ao lado do número dele."})
	var dd: Image = L.blank(4, 4)
	for y in 4:
		for x in 4:
			if (x + y) % 2 == 0:
				L.P(dd, x, y, "ink")
	save_sheet("ui_dim_dither", "ui/ui_dim_dither.png", [dd], 0, Vector2i.ZERO, {"tile": "both",
		"note": "Escurecer a sala atrás das janelas: TextureRect em tela cheia, stretch_mode Tile (dither 50% ink, direção visual §2)."})
	# ---- molduras das telas de fim de carreira e aposentadoria
	for t in [["ui_end_frame_defeat", "g0", "g1", "r1", "FIM DE CARREIRA (derrota): concreto rachado com fita vermelha nos cantos."],
			["ui_end_frame_retire", "p0", "p1", "y0", "SAIU POR CIMA (aposentadoria): roxo do Legado com cantos dourados."]]:
		var ef: Image = L.blank(24, 24)
		L.R(ef, 0, 0, 24, 24, "ink"); L.R(ef, 1, 1, 22, 22, t[1]); L.R(ef, 1, 1, 22, 1, t[2]); L.R(ef, 1, 1, 1, 22, t[2])
		L.R(ef, 5, 5, 14, 14, "ink"); L.R(ef, 6, 6, 12, 12, "d1")
		if t[1] == "g0":
			L.line(ef, 2, 3, 4, 4, "d2"); L.line(ef, 19, 20, 21, 22, "d2")
			for c in [[0, 0], [17, 0], [0, 17], [17, 17]]:
				L.line(ef, c[0] + 1, c[1] + 5, c[0] + 5, c[1] + 1, t[3]); L.line(ef, c[0] + 2, c[1] + 5, c[0] + 5, c[1] + 2, "r2")
		else:
			for c in [[1, 1], [19, 1], [1, 19], [19, 19]]:
				L.R(ef, c[0], c[1], 4, 4, t[3]); L.P(ef, c[0] + 1, c[1] + 1, "y2")
		save_sheet(t[0], "ui/%s.png" % t[0], [ef], 0, Vector2i.ZERO, {"nine_slice": {"left": 6, "top": 6, "right": 6, "bottom": 6}, "note": "Moldura 9-slice da tela " + t[4]})
	# ---- banner K.O.!
	var kw: int = L.text_w("K.O.!", 4) + 8
	var ko: Image = L.blank(kw, 40)
	L.text(ko, "K.O.!", 4, 8, "r1", 4)
	L.text(ko, "K.O.!", 4, 4, "y1", 4)
	var ko2: Image = outline_in_place(ko)
	for y in range(4, 18):
		for x in kw:
			if ko2.get_pixel(x, y).to_html(false) == L.C.y1.to_html(false) and y >= 14:
				ko2.set_pixel(x, y, L.C.y0)
	save_sheet("ui_banner_ko", "ui/ui_banner_ko.png", [ko2], 0, Vector2i(kw / 2, 20), {"note": "Letreiro K.O.! no centro da arena quando alguém cai (entra com tremida de 2 px; pode ampliar 2x inteiro)."})

func glove_small_ramp(ramp: Array, w: int, h: int) -> Image:
	var g: Image = L.blank(w, h)
	L.glove(g, 0, 0, w, h, ramp)
	return g

# ================================================================ retratos 32x32
const PORTRAIT_BG := {"player": ["b0", "b1"], "opp_warmup": ["gr0", "gr1"], "opp_strong": ["r0", "r1"], "opp_fast": ["b0", "b2"], "opp_tank": ["br1", "y0"]}

func make_portraits() -> void:
	for who in ["player", "opp_warmup", "opp_strong", "opp_fast", "opp_tank"]:
		var b: Dictionary = build_player("glove_old") if who == "player" else build_opp(who)
		var p := pz({"hf": V(16, -55), "hb": V(12, -53)})
		var fr := rig(b, p, 0)
		var hc: Vector2 = FP(b, p.head) + Vector2(0, b.neck)
		var crop: Image = fr.get_region(Rect2i(int(hc.x) - 15, int(hc.y) - 13, 32, 32))
		var bg: Image = L.blank(32, 32)
		var cb: Array = PORTRAIT_BG[who]
		L.R(bg, 0, 0, 32, 32, "d1")
		L.dither(bg, 0, 18, 32, 6, cb[0])
		L.R(bg, 0, 24, 32, 8, cb[0])
		L.dither(bg, 0, 28, 32, 4, cb[1], 1)
		bg.blend_rect(crop, Rect2i(0, 0, 32, 32), Vector2i.ZERO)
		var pid: String = "portrait_" + who
		var rel: String = ("fight/" if who == "player" else "opponents/") + pid + ".png"
		save_sheet(pid, rel, [bg], 0, Vector2i.ZERO, {"facing": "direita",
			"note": "Retrato 32x32 (recorte do próprio sprite de luta, com fundo na cor do lutador). Virado para a DIREITA: no HUD da luta o adversário usa flip_h (olha para o centro); na prévia, ELE fica à esquerda sem flip e VOCÊ à direita com flip_h. Moldura: ui_portrait_frame."})
	# o jogador também ganha retrato com cada luva de loja? Não: a luva não aparece no recorte (mãos abaixadas).

# ================================================================ gerador pago: Prof. Nelson (aparece na garagem)
const P_COACH := Vector2i(394, 280)
const LIGHT_C := Vector2(305, 90)

func make_coach() -> void:
	var o := {"skin": ["sk0", "sk1", "sk2"], "shirt": ["gr0", "gr1", "gr2"], "shorts": ["gr0", "gr1", "gr2"], "gloves": [],
		"hair": ["g1", "g2"], "head": "short", "top": "social", "bottom": "pants", "shoes": "tenis", "belly": 2, "mustache": "g2"}
	var poses := [
		L.pose({"bhand": V(24, 34), "belb": V(16, 34), "fhand": V(31, 33), "felb": V(30, 34)}),
		L.pose({"bhand": V(24, 34), "belb": V(16, 34), "fhand": V(29, 20), "felb": V(33, 28)}),     # olha o relógio
		L.pose({"bhand": V(24, 34), "belb": V(16, 34), "fhand": V(27, 22), "felb": V(32, 29), "dy": 0}),  # apito
		L.pose({"bhand": V(24, 34), "belb": V(16, 34), "fhand": V(31, 33), "felb": V(30, 34), "dy": 1}),
	]
	var frames := []
	for i in poses.size():
		var im: Image = L.character(o, poses[i])
		var p: Dictionary = poses[i]
		var cl := blank_layer()
		# prancheta na mão de trás
		var bh: Vector2 = p.bhand + Vector2(p.lean, p.dy)
		L.R(cl, int(bh.x) - 2, int(bh.y) - 9, 9, 12, "br2"); L.R(cl, int(bh.x) - 1, int(bh.y) - 8, 7, 10, "white")
		L.R(cl, int(bh.x), int(bh.y) - 6, 5, 1, "g2"); L.R(cl, int(bh.x), int(bh.y) - 4, 4, 1, "g2"); L.R(cl, int(bh.x), int(bh.y) - 2, 5, 1, "g2")
		L.R(cl, int(bh.x) + 1, int(bh.y) - 10, 3, 2, "st2")
		L.stamp(im, cl, 0, 0)
		# apito no pescoço (cordão + apito)
		L.P(im, 21, 24 + p.dy, "y1"); L.P(im, 22, 25 + p.dy, "y1"); L.R(im, 22, 26 + p.dy, 2, 2, "st3")
		if i == 1:
			L.P(im, 29, 22, "st3"); L.P(im, 30, 22, "ink")   # relógio
		if i == 2:
			L.R(im, 26, 17, 2, 1, "st3")                       # apito na boca
		im.flip_x()
		frames.append(lit(im, P_COACH - Vector2i(25, 67)))
	save_sheet("coach_1", "characters/coach_1_idle.png", frames, 3, Vector2i(25, 67), {"loop": true, "pos": xy(P_COACH), "facing": "esquerda",
		"note": "Prof. Nelson (gerador pago gen_paid_1): moletom verde do clube do bairro, apito no pescoço, prancheta. 0 parado, 1 confere o relógio, 2 apita, 3 parado. Fica perto do aparelho em foco, sem cobrir a área de clique. Luz já aplicada para este ponto. Sombra: floor_shadow nos pés."})
	var src: Image = frames[0]
	var ic: Image = src.duplicate()
	ic.flip_x()
	save_sheet("icon_coach", "ui/icon_coach.png", [ic.get_region(Rect2i(14, 2, 16, 16))], 0, Vector2i.ZERO, {"note": "Retrato 16x16 do Prof. Nelson para o cartão da LOJA."})

func blank_layer() -> Image:
	return L.blank(48, 72)

func lit(img: Image, topleft: Vector2i, min_step := -1) -> Image:
	var c: Image = img.duplicate()
	L.light(c, Rect2i(0, 0, c.get_width(), c.get_height()), LIGHT_C - Vector2(topleft), 300.0, 1.1, 3.6, min_step, 1, 0.9)
	return c

# ================================================================ sombra de luta
func make_fight_shadow() -> void:
	var sh: Image = L.blank(48, 8)
	L.ellipse_dither(sh, 24, 4, 24, 4, "ink")
	L.ellipse(sh, 24, 4, 17, 2.6, "ink")
	save_sheet("fight_shadow", "fight/fight_shadow.png", [sh], 0, Vector2i(24, 4), {"note": "Sombra no chão da arena, embaixo de cada lutador (pivô = pés, y - 1). Durante o 'ko' deitado, deslocar 12 px para o lado da queda."})

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
	var doc: Dictionary = intify(OLD)
	doc["_sobre"] = "Sprites PLACEHOLDER das Fases 2 (garagem) e 3 (lutas), gerados por tools/art/make_sprites_fase2.gd e make_sprites_fase3.gd. Tudo 1x na resolução base 640x360, filtro nearest. Folhas = quadros lado a lado, da esquerda para a direita."
	var spr: Dictionary = doc.get("sprites", {})
	for k in M:
		spr[k] = M[k]
	doc["sprites"] = spr
	var acts := {}
	for a in ACTIONS:
		acts[a] = "fight_player_" + a
	var bd: Dictionary = doc.get("by_data_id", {})
	bd["_nota_fase3"] = "Fase 3: lutador de luta, adversários (ids de data/ propostos em docs/fases/fase3-textos.md), luvas, táticas, risco, ícones de dinheiro/fama/Legado/cinturão."
	bd["player_fight"] = {"actions": acts, "portrait": "portrait_player", "portrait_frame": "ui_portrait_frame", "pos": xy(P_PLAYER), "facing": "direita",
		"glove_note": "Com luva de loja equipada, somar o sufixo da luva ao id: fight_player_jab_glove_l2. Luva velha = sem sufixo."}
	var opp_info := {"opp_warmup": ["Dudu Alongado", "EQUILIBRADO", "gr2", "ui_portrait_frame"], "opp_strong": ["Brutão do Posto", "FORTE", "r2", "ui_portrait_frame"],
		"opp_fast": ["Dinho Pulga", "RÁPIDO", "b2", "ui_portrait_frame"], "opp_tank": ["Seu Muralha", "RESISTENTE", "y1", "ui_portrait_frame_gold"]}
	for oid in opp_info:
		var oa := {}
		for a in ACTIONS:
			oa[a] = oid + "_" + a
		var inf: Array = opp_info[oid]
		bd[oid] = {"actions": oa, "portrait": "portrait_" + oid, "portrait_frame": inf[3], "pos": xy(P_OPP), "facing": "esquerda",
			"name_hint": inf[0], "profile": inf[1], "color": inf[2], "scale": build_opp(oid).s,
			"_nota": "Mesmo quadro 112x104 e pivô (56,98) do jogador: trocar o adversário = trocar o prefixo do id."}
	for gid in GLOVES:
		var suf: String = "" if gid == "glove_old" else "_" + gid
		var e := {"name_hint": GLOVES[gid].name, "item": gid, "icon": "icon_" + gid, "hung_art": "art_hung_" + gid,
			"cursor": "cursor_glove" if gid == "glove_old" else "cursor_" + gid,
			"cursor_x2": ["cursor_glove_normal_x2", "cursor_glove_pressed_x2"] if gid == "glove_old" else ["cursor_%s_normal_x2" % gid, "cursor_%s_pressed_x2" % gid],
			"cursor_x3": ["cursor_glove_normal_x3", "cursor_glove_pressed_x3"] if gid == "glove_old" else ["cursor_%s_normal_x3" % gid, "cursor_%s_pressed_x3" % gid],
			"sprite_suffix": suf,
			"garage_sheets": ["fighter_idle" + suf, "fighter_punch" + suf, "fighter_rope" + suf, "fighter_run" + suf],
			"palette": {"r0": GLOVES[gid].ramp[0], "r1": GLOVES[gid].ramp[1], "r2": GLOVES[gid].ramp[2]}}
		bd[gid] = e
	bd["glove_shop"] = {"levels": ["glove_l1", "glove_l2", "glove_l3"], "_nota": "Trocar a luva = trocar AO MESMO TEMPO: cursor, folhas da garagem (sufixo) e folhas de luta (sufixo). Tudo pelo mesmo sprite_suffix."}
	bd["aggressive"] = {"icon": "icon_tactic_aggressive", "icon_9": "icon_tactic_aggressive_9", "button_selected": "ui_button_focus_strength", "color": "r2"}
	bd["defensive"] = {"icon": "icon_tactic_defensive", "icon_9": "icon_tactic_defensive_9", "button_selected": "ui_button_focus_endurance", "color": "y1"}
	bd["counter"] = {"icon": "icon_tactic_counter", "icon_9": "icon_tactic_counter_9", "button_selected": "ui_button_focus_agility", "color": "b3"}
	bd["risk_easy"] = {"seal": "seal_risk_easy", "bg": "ui_risk_easy", "icon": "icon_risk_easy", "color": "gr3"}
	bd["risk_even"] = {"seal": "seal_risk_even", "bg": "ui_risk_even", "icon": "icon_risk_even", "color": "y1"}
	bd["risk_hard"] = {"seal": "seal_risk_hard", "bg": "ui_risk_hard", "icon": "icon_risk_hard", "color": "r2"}
	bd["money"] = {"icon": "icon_money", "icon_16": "icon_money_16", "color": "y1"}
	bd["fame"] = {"icon": "icon_fame", "icon_16": "icon_fame_16", "color": "p2"}
	bd["legacy"] = {"icon": "icon_legacy", "icon_16": "icon_legacy_16", "color": "p2"}
	bd["belt_amateur"] = {"icon": "icon_belt_amateur", "icon_9": "icon_belt_amateur_9", "big": "belt_amateur_big"}
	bd["gen_paid_1"] = {"people": ["coach_1"], "icon": "icon_coach", "_nota": "Prof. Nelson aparece na sala com 1 comprado."}
	bd["fight_button"] = {"normal": "ui_button_fight_normal", "hover": "ui_button_fight_hover", "pressed": "ui_button_fight_pressed", "disabled": "ui_button_fight_disabled", "icon": "icon_fight"}
	bd["retire_button"] = {"normal": "ui_button_retire_normal", "hover": "ui_button_retire_hover", "pressed": "ui_button_retire_pressed", "disabled": "ui_button_retire_disabled", "icon": "icon_retire"}
	doc["by_data_id"] = bd
	var pal: Dictionary = doc.get("palette_swap_glove", {})
	var vars := {}
	for gid in GLOVES:
		vars[gid] = {"r0": "#" + L.PAL_HEX[GLOVES[gid].ramp[0]], "r1": "#" + L.PAL_HEX[GLOVES[gid].ramp[1]], "r2": "#" + L.PAL_HEX[GLOVES[gid].ramp[2]]}
	pal["variants"] = vars
	pal["_nota_fase3"] = "Recomendado: usar as folhas já pintadas (sufixo _glove_lN), que trazem os detalhes de cada luva (fita, costura, listra). O shader de paleta (trocar r0/r1/r2 por variants[luva]) também funciona, mas mantém a fita e o punho encardido da luva velha."
	doc["palette_swap_glove"] = pal
	doc["fight_layout"] = {
		"_regra": "Tela de luta 640x360. Arena atrás, público atrás e na frente, lutadores no chão (ordem: arena_bg, arena_lamp, arena_crowd_back, sombras, lutadores, efeitos, arena_crowd_front, HUD).",
		"player_pos": xy(P_PLAYER), "opponent_pos": xy(P_OPP),
		"distance_note": "Pivôs a 50 px: o jab/golpe forte encosta no rosto do outro sem mover o lutador. Para K.O. e vitória podem andar à vontade em px inteiros.",
		"hud_band": [0, 0, 640, HUD_H],
		"player_portrait_frame": [6, 6], "player_name": [46, 6], "player_hp_bar": [46, 16, 236, 12], "player_tactic": [46, 32],
		"opponent_portrait_frame": [598, 6], "opponent_name_right": [594, 6], "opponent_hp_bar": [358, 16, 236, 12], "opponent_profile_right": [594, 32],
		"timer_box": [292, 4, 56, 32],
		"damage_number": "Sai do hit_point e sobe 20 px em 0,6 s (normal y1 1x; crítico r3 2x com '!'). ESQUIVOU: cream 1x sobre a cabeça de quem esquivou.",
		"head_point": [4, -80], "ko_head_point": [-36, -12],
		"head_note": "Relativos ao pivô, lutador virado para a direita, escala 1.0. Multiplicar por by_data_id.<id>.scale e espelhar x para o adversário.",
		"shake": "Golpe forte: tremida de 1 px por 2 quadros. Crítico: 2 px. K.O.: 2 px + arena_lamp swing + crowd cheer."}
	var fa := FileAccess.open(OUT + "manifest.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(doc, "\t", false))
	fa.close()

# ================================================================ montagem dos mockups
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
	var fw: int = int(e.frame_size[0])
	var fh: int = int(e.frame_size[1])
	return img.get_region(Rect2i(i * fw, 0, fw, fh))

func put(dst: Image, id: String, i: int, pos: Vector2i, flip := false) -> void:
	var fr: Image = frame_of(id, i).duplicate()
	var pv: Array = spr(id).get("pivot", [0, 0])
	var px := int(pv[0])
	if flip:
		fr.flip_x()
		if not (px == 0 and int(pv[1]) == 0):
			px = fr.get_width() - 1 - px
	dst.blend_rect(fr, Rect2i(Vector2i.ZERO, fr.get_size()), pos - Vector2i(px, int(pv[1])))

func ns(dst: Image, id: String, x: int, y: int, w: int, h: int) -> void:
	nine(dst, frame_of(id), x, y, w, h, spr(id).nine_slice)

func hp_bar(dst: Image, x: int, y: int, w: int, frac: float, trail: float, right := false) -> void:
	ns(dst, "ui_hp_frame", x, y, w, 12)
	var iw := w - 4
	var tw := int(iw * trail)
	var fw := int(iw * frac)
	var fill := "ui_hp_fill_low" if frac <= 0.25 else "ui_hp_fill"
	if right:
		ns(dst, "ui_hp_trail", x + 2 + iw - tw, y + 2, tw, 8)
		ns(dst, fill, x + 2 + iw - fw, y + 2, fw, 8)
	else:
		ns(dst, "ui_hp_trail", x + 2, y + 2, tw, 8)
		ns(dst, fill, x + 2, y + 2, fw, 8)
	for k in range(1, 10):
		L.P(dst, x + 2 + iw * k / 10, y + 9, "ink")

func button9(dst: Image, id: String, x: int, y: int, w: int, h: int, label: String, scale := 1, icon := "") -> void:
	ns(dst, id, x, y, w, h)
	var tc = spr(id).get("text_color", "white")
	var tw: int = L.text_w(label, scale) + (12 if icon != "" else 0)
	var tx := x + (w - tw) / 2
	if icon != "":
		put(dst, icon, 0, Vector2i(tx - 3, y + (h - 16) / 2 - 1))
		tx += 14
	L.text(dst, label, tx, y + (h - 7 * scale) / 2 - 1, tc, scale, "ink")

func dim(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if (x + y) % 2 == 0:
				img.set_pixel(x, y, L.C.ink)

func save_x2(img: Image, path: String) -> void:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	b.save_png(path)

func fight_scene(pl_act: String, pl_f: int, op: String, op_act: String, op_f: int, crowd_f: int) -> Image:
	var img: Image = F.arena_bg[0].duplicate()
	put(img, "arena_lamp", 0, LAMP_POS)
	put(img, "arena_crowd_back", crowd_f, Vector2i(0, 180))
	put(img, "fight_shadow", 0, P_PLAYER + Vector2i(0, -1))
	put(img, "fight_shadow", 0, P_OPP + Vector2i(0, -1))
	put(img, op + "_" + op_act, op_f, P_OPP)
	put(img, "fight_player_" + pl_act, pl_f, P_PLAYER)
	return img

func fight_hud(img: Image, op: String, pl_hp: float, pl_tr: float, op_hp: float, op_tr: float, opname: String, profile: String, tactic: String, tlabel: String) -> void:
	for y in HUD_H:
		for x in 640:
			if y < HUD_H - 4 or (x + y) % 2 == 0:
				img.set_pixel(x, y, L.C.ink)
	put(img, "ui_portrait_frame", 0, Vector2i(6, 6))
	put(img, "portrait_player", 0, Vector2i(8, 8))
	L.text(img, "VOCÊ", 46, 6, "white", 1, "ink")
	hp_bar(img, 46, 16, 236, pl_hp, pl_tr)
	put(img, "icon_tactic_%s_9" % tactic, 0, Vector2i(46, 31))
	L.text(img, tlabel, 58, 32, bd_color(tactic), 1, "ink")
	var fr: String = OLD_BD_FRAME.get(op, "ui_portrait_frame")
	put(img, fr, 0, Vector2i(598, 6))
	put(img, "portrait_" + op, 0, Vector2i(600, 8), true)
	L.text_right(img, opname, 594, 6, "white", 1, "ink")
	hp_bar(img, 358, 16, 236, op_hp, op_tr, true)
	L.text_right(img, profile, 594, 32, "r2", 1, "ink")
	ns(img, "ui_panel", 292, 4, 56, 32)
	L.text_center(img, "2º ROUND", 320, 8, "g3", 1, "ink")
	L.text_center(img, "0:09", 320, 19, "y1", 2, "ink")

const OLD_BD_FRAME := {"opp_tank": "ui_portrait_frame_gold"}

func bd_color(t: String) -> String:
	return {"aggressive": "r2", "defensive": "y1", "counter": "b3"}[t]

func make_mock_fight() -> void:
	# quadro principal: jogador acerta o golpe forte (crítico) no Brutão
	var img := fight_scene("heavy", 2, "opp_strong", "hit", 0, 1)
	var hp: Array = M.fight_player_heavy.hit_point
	var cp := P_PLAYER + Vector2i(int(hp[0]), int(hp[1]))
	put(img, "fx_fight_hit", 1, cp)
	put(img, "fx_fight_crit", 1, cp)
	L.text(img, "57!", cp.x + 6, cp.y - 34, "r3", 2, null, "ink")
	put(img, "arena_crowd_front", 1, Vector2i(0, 312))
	fight_hud(img, "opp_strong", 0.72, 0.72, 0.41, 0.60, "BRUTÃO DO POSTO", "FORTE", "counter", "CONTRA-ATAQUE")
	# tira de quadros-chave embaixo (mesma cena, outros eventos)
	var keys := [
		["jab", 1, "opp_strong", "block", 1, "DEFESA"],
		["dodge", 1, "opp_strong", "heavy", 2, "ESQUIVOU"],
		["tired", 1, "opp_strong", "jab", 1, "CANSADO / LEVA JAB"],
		["victory", 0, "opp_strong", "ko", 4, "K.O.!"],
	]
	var S := 2
	var out: Image = L.blank(1280, 720 + 214)
	L.R(out, 0, 0, out.get_width(), out.get_height(), "d1")
	var big: Image = img.duplicate()
	big.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	out.blit_rect(big, Rect2i(0, 0, 1280, 720), Vector2i.ZERO)
	for i in keys.size():
		var k: Array = keys[i]
		var sc := fight_scene(k[0], k[1], k[2], k[3], k[4], i % 2)
		if k[5] == "ESQUIVOU":
			var hb: Array = M.opp_strong_heavy.hit_point
			var p := P_OPP + Vector2i(int(hb[0]), int(hb[1]))
			put(sc, "fx_whoosh", 1, p)
			L.text_center(sc, "ESQUIVOU", P_PLAYER.x - 6, 222, "cream", 1, null, "ink")
		elif k[5] == "DEFESA":
			var h1: Array = M.fight_player_jab.hit_point
			put(sc, "fx_block", 0, P_PLAYER + Vector2i(int(h1[0]), int(h1[1])), true)
		elif k[5] == "K.O.!":
			put(sc, "fx_ko_stars", 1, P_OPP + Vector2i(int(round(36 * 1.08)), -12))
			put(sc, "ui_banner_ko", 0, Vector2i(320, 200))
		else:
			put(sc, "fx_sweat", 1, P_PLAYER + Vector2i(5, -80))
			var h2: Array = M.opp_strong_jab.hit_point
			put(sc, "fx_fight_hit", 2, P_OPP + Vector2i(int(h2[0]), int(h2[1])), true)
			L.text(sc, "12", P_PLAYER.x + 4, 236, "y1", 1, null, "ink")
		var crop: Image = sc.get_region(Rect2i(176, 150, 290, 190))
		var px := 12 + i * 316
		out.blit_rect(crop, Rect2i(0, 0, 290, 190), Vector2i(px, 732))
		L.text(out, k[5], px, 724, "y1", 1, "ink")
	out.save_png(MOCK + "fase3_luta_x2.png")
	img.save_png(MOCK + "fase3_luta_base.png")

func make_mock_preview() -> void:
	var img: Image = L.blank(640, 360)
	L.R(img, 0, 0, 640, 360, "ink")
	img.blit_rect(frame_of("garage_bg"), Rect2i(0, 0, 384, 272), Vector2i(128, 18))
	L.game_ui(img, {"money": "$ 45", "treino": "8.420", "treino_s": "+36/S", "fama": "12", "local": "FUNDO DA GARAGEM",
		"carreira": "CARREIRA 1", "attrs": [["FORÇA", "95", 0.4, "r2", "r2"], ["AGILIDADE", "70", 0.3, "b3", "b2"], ["RESISTÊNCIA", "88", 0.35, "y1", "y0"]],
		"legado": "30", "adv": "BRUTÃO", "adv2": "FORTE", "risco": "PERIGOSO", "risco_cor": "r2", "cmp": [["FOR", 180, 95], ["AGI", 40, 70], ["RES", 120, 88]],
		"shop": [], "ups": [], "prox_local": "ACADEMIA", "prox_req": "CINTURÃO", "clique": "+12", "focos": [["SACO", "FORÇA", "r1", true], ["CORDA", "AGILIDADE", "b1", false], ["ESTEIRA", "RESISTÊNCIA", "br2", false]],
		"dica": ""})
	dim(img)
	var wx := 150
	var wy := 22
	var ww := 340
	var wh := 318
	ns(img, "ui_window", wx, wy, ww, wh)
	ns(img, "ui_window_title_neutral", wx + 6, wy + 6, ww - 12, 16)
	L.text_center(img, "PRÓXIMA LUTA", 320, wy + 10, "cream", 1, "ink")
	# retratos
	put(img, "ui_portrait_frame", 0, Vector2i(wx + 14, wy + 30))
	put(img, "portrait_opp_strong", 0, Vector2i(wx + 16, wy + 32))
	put(img, "ui_portrait_frame", 0, Vector2i(wx + ww - 50, wy + 30))
	put(img, "portrait_player", 0, Vector2i(wx + ww - 48, wy + 32), true)
	put(img, "ui_vs_badge", 0, Vector2i(320, wy + 48))
	L.text(img, "ELE", wx + 56, wy + 31, "g2", 1, "ink")
	L.text(img, "BRUTÃO DO POSTO", wx + 56, wy + 42, "white", 1, "ink")
	L.text(img, "FORTE", wx + 56, wy + 53, "r2", 1, "ink")
	L.text_right(img, "VOCÊ", wx + ww - 56, wy + 31, "g2", 1, "ink")
	L.text_right(img, "CARREIRA 1", wx + ww - 56, wy + 42, "white", 1, "ink")
	L.text_right(img, "0 VITÓRIAS", wx + ww - 56, wy + 53, "g3", 1, "ink")
	L.text_center(img, "CARREGA BOTIJÃO NO BRAÇO. DERRUBA PAREDE.", 320, wy + 72, "g3", 1, "ink")
	# atributos
	var ry := wy + 86
	var rows := [["FORÇA", 180, 95, "r2", true], ["AGILIDADE", 40, 70, "b3", false], ["RESISTÊNCIA", 120, 88, "y1", false]]
	for r in rows:
		ns(img, "ui_stat_row_lead" if r[4] else "ui_stat_row", wx + 12, ry, ww - 24, 13)
		L.text(img, str(r[1]), wx + 20, ry + 3, "r3" if r[1] > r[2] else "white", 1, "ink")
		if r[4]:
			put(img, "icon_lead", 0, Vector2i(wx + 22 + L.text_w(str(r[1])), ry + 2))
		L.text_center(img, r[0], 320, ry + 3, r[3], 1, "ink")
		L.text_right(img, str(r[2]), wx + ww - 20, ry + 3, "gr3" if r[2] >= r[1] else "white", 1, "ink")
		ry += 15
	L.text_center(img, "ELE É MUITO MAIS FORTE", 320, ry + 2, "r2", 1, "ink")
	ry += 14
	# risco
	L.text(img, "RISCO", wx + 14, ry + 3, "g3", 1, "ink")
	put(img, "seal_risk_hard", 0, Vector2i(wx + 48, ry))
	ry += 18
	# táticas
	L.text(img, "TÁTICA", wx + 14, ry, "cream", 1, "ink")
	ry += 10
	var tacs := [["AGRESSIVO", "aggressive", "ui_button_focus_strength"], ["DEFENSIVO", "defensive", "ui_button_focus_endurance"], ["CONTRA-ATAQUE", "counter", "ui_button_focus_agility"]]
	var bw := (ww - 24 - 8) / 3
	for i in 3:
		var t: Array = tacs[i]
		var sel := i == 1
		var bx := wx + 12 + i * (bw + 4)
		ns(img, t[2] if sel else "ui_button_normal", bx, ry, bw, 22)
		put(img, "icon_tactic_" + t[1], 0, Vector2i(bx + 4, ry + 2))
		L.text(img, t[0], bx + 22, ry + 7, "white" if sel else "cream", 1, "ink")
		if sel:
			L.R(img, bx + 2, ry + 24, bw - 4, 2, "br2")
	ry += 30
	L.text_center(img, "APANHA MENOS. BATE MENOS.", 320, ry, "g3", 1, "ink")
	ry += 14
	# em jogo
	R2(img, wx + 12, ry, ww - 24, 1, "d2")
	ry += 6
	put(img, "icon_money", 0, Vector2i(wx + 14, ry - 1))
	L.text(img, "SE VENCER: $ 60 + 5 FAMA", wx + 27, ry, "y1", 1, "ink")
	put(img, "icon_fame", 0, Vector2i(wx + 27 + L.text_w("SE VENCER: $ 60 + 5 FAMA") + 4, ry - 1))
	ry += 12
	put(img, "icon_legacy", 0, Vector2i(wx + 14, ry - 1))
	L.text(img, "PERDER ENCERRA A CARREIRA (METADE DO LEGADO)", wx + 27, ry, "r2", 1, "ink")
	# botões
	button9(img, "ui_button_normal", wx + 12, wy + wh - 34, 150, 24, "VOLTAR A TREINAR")
	button9(img, "ui_button_fight_normal", wx + ww - 162, wy + wh - 34, 150, 24, "LUTAR!", 2)
	save_x2(img, MOCK + "fase3_previa_x2.png")

func R2(img: Image, x: int, y: int, w: int, h: int, c) -> void:
	L.R(img, x, y, w, h, c)

func make_mock_end() -> void:
	var out: Image = L.blank(1280, 360)
	for mode in [0, 1]:
		var img: Image
		if mode == 0:
			img = fight_scene("ko", 4, "opp_strong", "victory", 0, 1)
		else:
			img = L.blank(640, 360)
			L.R(img, 0, 0, 640, 360, "ink")
			img.blit_rect(frame_of("garage_bg"), Rect2i(0, 0, 384, 272), Vector2i(128, 18))
		dim(img)
		var fx := 110
		var fy := 16
		var fw := 420
		var fh := 330
		ns(img, "ui_end_frame_defeat" if mode == 0 else "ui_end_frame_retire", fx, fy, fw, fh)
		ns(img, "ui_window_title_defeat" if mode == 0 else "ui_window_title_retire", fx + 40, fy + 8, fw - 80, 22)
		L.text_center(img, "FIM DE CARREIRA" if mode == 0 else "SAIU POR CIMA", 320, fy + 12, "white", 2, "ink")
		var y := fy + 40
		if mode == 0:
			L.text_center(img, "BRUTÃO DO POSTO VENCEU NO 2º ROUND", 320, y, "white", 1, "ink")
			y += 14
			ns(img, "ui_stat_row_lead", fx + 30, y, fw - 60, 26)
			put(img, "icon_endurance", 0, Vector2i(fx + 36, y + 3))
			L.text(img, "ELE TIROU 60% DA SUA VIDA EM 4 GOLPES", fx + 50, y + 4, "white", 1, "ink")
			L.text(img, "TREINE NA ESTEIRA ANTES DA PRÓXIMA", fx + 50, y + 15, "y1", 1, "ink")
			y += 34
			put(img, "portrait_player", 0, Vector2i(fx + 30, y + 2))
			put(img, "ui_portrait_frame", 0, Vector2i(fx + 28, y))
		else:
			L.text_center(img, "O SACO FICA PRO PRÓXIMO.", 320, y, "cream", 1, "ink")
			y += 14
			put(img, "art_hung_glove_l2", 0, Vector2i(fx + 52, y))
			put(img, "belt_amateur_big", 0, Vector2i(fx + fw - 90, y + 26))
			y += 48
		var rows := [["RESUMO DA CARREIRA 1", "", "cream"], ["VITÓRIAS", "1" if mode == 0 else "4", "white"], ["CINTURÕES", "0" if mode == 0 else "1", "white"],
			["FAMA", "5" if mode == 0 else "60", "p2"], ["DINHEIRO GANHO", "$ 60" if mode == 0 else "$ 820", "y1"], ["TEMPO DE JOGO", "12:40" if mode == 0 else "34:10", "white"]]
		y += 4
		for r in rows:
			L.text(img, r[0], fx + 80, y, "g3" if r[1] != "" else "cream", 1, "ink")
			L.text_right(img, r[1], fx + fw - 80, y, r[2], 1, "ink")
			y += 11
		y += 4
		L.R(img, fx + 70, y, fw - 140, 1, "d2")
		y += 7
		put(img, "icon_legacy_16", 0, Vector2i(fx + 74, y - 3))
		L.text(img, "LEGADO GANHO", fx + 94, y, "p2", 1, "ink")
		L.text_right(img, "15 (50%)" if mode == 0 else "+240 (100% + CINTURÃO)", fx + fw - 80, y, "p2", 1, "ink")
		y += 13
		L.text(img, "LEGADO TOTAL", fx + 94, y, "g3", 1, "ink")
		L.text_right(img, "15" if mode == 0 else "255", fx + fw - 80, y, "p2", 1, "ink")
		y += 14
		L.text_center(img, "O LEGADO FICA GUARDADO. VAI SERVIR NA PRÓXIMA VERSÃO.", 320, y, "g2", 1, "ink")
		button9(img, "ui_button_retire_normal" if mode == 1 else "ui_button_normal", 320 - 80, fy + fh - 34, 160, 24, "NOVA CARREIRA")
		out.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i(mode * 640, 0))
	save_x2(out, MOCK + "fase3_fim_x2.png")

# ================================================================ main
func _init() -> void:
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(OUT + "manifest.json")) == OK:
		OLD = j.data
	make_arena()
	make_fighters()
	make_fight_shadow()
	make_fx()
	make_gloves()
	make_coach()
	make_ui()
	make_portraits()
	write_manifest()
	make_contact_sheet(MOCK + "fase3_sprites_x3.png", "FIGHTCLICKER - FASE 3 - SPRITES PLACEHOLDER (x3)")
	if "debug" in OS.get_cmdline_user_args():
		var keep := []
		for e in SHEETS:
			if not (str(e[0]).begins_with("fight_player") or str(e[0]).begins_with("opp_") or str(e[0]).begins_with("arena")):
				keep.append(e)
		SHEETS = keep
		make_contact_sheet("C:/Users/deivi/AppData/Local/Temp/claude/d03e7314839aa25e/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/art3/ui_x3.png", "UI")
	make_mock_fight()
	make_mock_preview()
	make_mock_end()
	make_mock_gloves()
	print("ok: sprites da fase 3 gerados")
	quit()

## Conferência da regra "a mesma luva em todo lugar": ícone, cursor, garagem e luta lado a lado.
func make_mock_gloves() -> void:
	var cw := 300
	var img: Image = L.blank(cw * 4, 120)
	L.R(img, 0, 0, img.get_width(), img.get_height(), "d1")
	var i := 0
	for gid in GLOVES:
		var x := i * cw
		var suf: String = "" if gid == "glove_old" else "_" + gid
		L.R(img, x, 0, 1, 120, "d2")
		L.text(img, str(GLOVES[gid].name).to_upper(), x + 6, 4, "y1", 1, "ink")
		put(img, "icon_" + gid, 0, Vector2i(x + 6, 18))
		put(img, "cursor_glove" if gid == "glove_old" else "cursor_" + gid, 0, Vector2i(x + 34, 26))
		put(img, "fighter_punch" + suf, 2, Vector2i(x + 76, 112))
		put(img, "fight_player_jab" + suf, 1, Vector2i(x + 160, 116))
		put(img, "art_hung_" + gid, 0, Vector2i(x + 262, 40))
		i += 1
	var b: Image = img.duplicate()
	b.resize(img.get_width() * 3, img.get_height() * 3, Image.INTERPOLATE_NEAREST)
	b.save_png(MOCK + "fase3_luvas_x3.png")
