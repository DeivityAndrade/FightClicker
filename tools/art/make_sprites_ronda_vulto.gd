extends SceneTree
## Ronda Noturna (Artista de Personagens): AMOSTRA do vulto (Gato Preto) para o dono aprovar.
## O vulto é o DISCÍPULO DA VEZ com o traje: capuz preto com orelhas de gato largas e baixas (costuradas), a faixa vermelha
## da escola amarrada nos olhos com as duas pontas voando, capa de lona (remendada) caindo reta, nunca aberta em asa.
## Sem símbolo no peito, sem cinto. Por baixo, a roupa de treino dele (calção, regata/camiseta, meião, tênis).
##
## Como "veste qualquer discípulo": o corpo sai do MESMO rig do lutador (personagem_lib.gd, perfil) em CORES-CHAVE do
## discípulo (pele, cabelo, calção, parte de cima, meião) e é trocado pela paleta do manifest (disciple_palette), igual ao
## jogo. O traje é pintado em cores fixas da paleta (não é chave: nunca troca). O capuz tem 4 variantes, uma por corte
## (curto: franja sob a aba; volume: topete escapando na frente; coque: o capuz estufa atrás; raspado: justo).
##
## Escala: perfil com as medidas do corpo da GARAGEM/Panfletagem (~64 px, a mesma altura das pessoas na tela da Ronda).
## Quadro 96x100, pivô (50,94) = chão entre os pés. Virado para a DIREITA.
##   ronda_vulto_roof  (4 q, loop, 6 fps): agachado na beira do telhado, contra a lua; só as pontas da faixa e a capa mexem.
##   ronda_vulto_scare (7 q, 12 fps, sem loop; 5-6 seguram): 0 antecipa no muro, 1 impulso, 2 ápice, 3 descendo (capa
##                     sobe reta), 4 aterrissa, 5 SUSTO (garras para cima, boca aberta), 6 segura (pontas mexem).
##   O pulo de verdade (do muro até a calçada) é deslocamento do nó na tela nos quadros 1-3; o quadro só levanta o corpo.
##
## Rodar headless de uma pasta temporária com project.godot vazio, APPDATA temporário:
##   godot --headless --max-fps 30 --path <tmp> --script <repo>/tools/art/make_sprites_ronda_vulto.gd -- <repo> <saida> [<folha.png>]
## Grava <saida>/ronda_vulto_<anim>_<look>.png (folhas montadas, 3 discípulos), <saida>/ronda_personagens.json (entradas
## propostas do manifest, lidas por tools/art/manifest_ronda_personagens.py) e a folha de conferência. Não grava no projeto.

const FW := 96
const FH := 100
const PIV := Vector2(50, 94)

var L
var P
var report: Array = []
var PAL := {}   # disciple_palette do manifest

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================ capuz (perfil, virado à direita; dado desenhado à mão)
## 16x17, âncora (8,10) = o mesmo centro do HEAD_SIDE (7,7) com 1 coluna e 3 linhas a mais (orelhas e volume do capuz).
## K/k/j = capuz sombra/base/luz (d1/d2/g0), n = costura (g1), F/G = faixa vermelha da escola (r2/r1), w = olho que brilha
## pela fresta da faixa (y2, olho de gato). S/s/l/m = pele e boca (chaves do discípulo), H/h = cabelo (chaves).
const HOOD := [
	"..K........j....",
	"..KkK.....kjj...",
	"..KknkKKkkjnjj..",
	".KkkkkkkkkjjjjK.",
	".Kkkkkkkkkkjjjj.",
	"KKkkkkkkkkkkjjj.",
	"KKkkkkkkkkkkkkj.",
	"KKkkkkkkkkkkkk..",
	"GGFFFFFFFFFFFF..",
	"GGGGGGGGGGwGGG..",
	".KkkkkkjSsssl...",
	".KkkkkkjSsssll..",
	".KkkkkkjSsssss..",
	"..KkkkkjSssss...",
	"..KkkkkjSsmSs...",
	"..KKkkkjSsss....",
	"...KKkkjSSs.....",
]
const HOOD_ANCHOR := Vector2i(8, 10)
const HOOD_CUTS := {
	"buzz": {},
	"short": {7: "KKkkkkkkkkkkkkH."},
	"volume": {5: "KKkkkkkkkkkkjjjh", 6: "KKkkkkkkkkkkkkHh", 7: "KKkkkkkkkkkkkkH."},
	"bun": {1: ".KKkK.....kjj...", 2: "KKknkKKkkjnjj...", 3: "KkkkkkkkkkjjjjK.", 4: "KKkkkkkkkkkjjjj."},
}
const HOOD_FACES := {
	"normal": {},
	"smirk": {14: "..KkkkkjSssxs..."},
	"scare": {14: "..KkkkkjSxxSs...", 15: "..KKkkkjSxs....."},
}
const HOOD_LEGEND := {"K": "d1", "k": "d2", "j": "g0", "n": "g1", "F": "r2", "G": "r1", "w": "y2"}
const KNOT := Vector2(-8, -1)   # nó da faixa (atrás do capuz), relativo ao centro da cabeça

# ================================================================ discípulos da amostra (opções reais do data/disciples.json)
const LOOKS := [
	{"id": "a", "nome": "PADRAO: PELE 3, CURTO CASTANHO, SEM CAMISA, CALCAO VERDE",
		"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "top": "none", "top_color": "white", "shorts_color": "green", "socks": "none"},
	{"id": "b", "nome": "PELE 1, VOLUME RUIVO, REGATA AMARELA, CALCAO ROXO",
		"skin": "skin_1", "hair_color": "copper", "hair_style": "volume", "top": "tank", "top_color": "yellow", "shorts_color": "purple", "socks": "none"},
	{"id": "c", "nome": "PELE 5, COQUE PRETO, CAMISETA BRANCA, CALCAO AZUL, MEIAO",
		"skin": "skin_5", "hair_color": "black", "hair_style": "bun", "top": "tee", "top_color": "white", "shorts_color": "blue", "socks": "on"},
]

func build(look: Dictionary, costume: bool) -> Dictionary:
	var o: Dictionary = P.identidade("disc")
	o.merge({"lu": 10.0, "lf": 10.5, "lt": 14.2, "ls": 13.2, "arm_r": [2.6, 2.0, 2.2, 1.7], "leg_r": [3.6, 2.7, 2.5, 1.5],
		"shoulder": 0.86, "hip_w": 0.86, "shorts_t": 0.45,
		"shoe_maps": {"flat": P.SHOES["34"], "ball": P.SHOES["34ball"]}}, true)
	match look.top:
		"tank": o["top"] = "tank"
		"tee": o["top"] = "tshirt"; o["sleeve_t"] = 0.45; o["sleeve_add"] = 0.6
		_: o["top"] = "none"
	o["sock_on"] = look.socks == "on"
	if costume:
		var rows: Array = HOOD.duplicate()
		var cut: Dictionary = HOOD_CUTS[look.hair_style]
		for k in cut:
			rows[int(k)] = cut[k]
		o["head_side"] = rows
		o["faces_side"] = HOOD_FACES
		o["head_anchor_side"] = HOOD_ANCHOR
		o["head_legend_extra"] = HOOD_LEGEND
	else:
		var c: Dictionary = P.DISC_CUTS[look.hair_style]
		o["head_side"] = c.side
		o["head_anchor_side"] = Vector2i(7 + int(c.pad[0]), 7 + int(c.pad[1]))
		o["faces_side"] = P._cut_faces(P.HEAD_SIDE, P.FACES_SIDE, c.side, int(c.pad[0]), int(c.pad[1]))
	return P.build(o)

# ================================================================ capa de lona
## Faixa de pano que sai da nuca: linha central A + dir*len*t (+ curva e onda), meia-largura w0 -> w1. Cai reta ou fica
## para trás no vento, sempre como UMA faixa (nunca aberta em asa). Dobras verticais, barra escura desfiada, remendo.
## No chão (y > ground) a barra amontoa para trás. Desenhada entre o lado de trás e o tronco (id 25).
const CAPE := ["d1", "st0", "st1"]

func draw_cape(lib, O: Vector2, ctx: Dictionary, cp: Dictionary) -> void:
	var fr: Vector2 = ctx.fr
	var dn: Vector2 = ctx.dn
	var A: Vector2 = (ctx.top as Vector2) - fr * 3.0 - dn * 1.0 + Vector2(0.5, 0.5)
	var D: Vector2 = (cp.dir as Vector2).normalized()
	var ln: float = cp.len
	var bend: float = cp.get("bend", 0.0)
	var wave: float = cp.get("wave", 0.0)
	var ph: float = cp.get("phase", 0.0)
	var w0: float = cp.get("w0", 2.6)
	var w1: float = cp.get("w1", 5.5)
	var gy: float = O.y - 1.0
	var Nn := Vector2(-D.y, D.x)
	if Nn.x > 0.0 or (is_zero_approx(Nn.x) and Nn.y > 0.0):
		Nn = -Nn   # +u = lado de fora (atrás/em cima)
	var steps := int(ln * 4.0)
	var done := {}
	for i in steps + 1:
		var t := float(i) / float(steps)
		var off := bend * t * t + wave * sin(t * PI * 2.2 + ph) * t + float(cp.get("bulge", 0.0)) * sin(PI * pow(t, 0.6))
		var w := lerpf(w0, w1, pow(t, 0.8))
		# a borda de dentro fica encostada nas costas; a capa cresce para fora (atrás), como pano pendurado nos ombros
		var C: Vector2 = A + D * ln * t + Nn * (off + (w - w0) * 0.8)
		var u := -w
		while u <= w:
			var p := C + Nn * u
			if cp.get("ground", true) and p.y > gy:
				p = Vector2(p.x - (p.y - gy) * 0.9, gy)   # barra amontoada no chão, para trás
			var q := Vector2i(int(floor(p.x)), int(floor(p.y)))
			var key := q.x * 1000 + q.y
			u += 0.35
			if done.has(key):
				continue
			done[key] = true
			var un := (u - 0.35) / w
			var c: String = CAPE[1]
			var fold := sin(un * PI * 1.7 + t * 2.4 + ph)
			if fold > 0.62:
				c = CAPE[2]
			elif fold < -0.7:
				c = CAPE[0]
			if un < -0.72:
				c = CAPE[0]   # junto do corpo: sombra das costas
			if (1.0 - t) * ln < 1.1:
				c = CAPE[0]   # barra
				if (q.x * 7 + q.y * 3) % 5 == 0:
					continue  # desfiado
			if t > 0.48 and t < 0.64 and un > 0.0 and un < 0.62:
				c = "d2"   # remendo
				if (absf(un - 0.0) < 0.12 or absf(un - 0.62) < 0.12 or absf(t - 0.48) * ln < 0.6) and (q.x + q.y) % 2 == 0:
					c = "g1"   # pontos da costura
			lib.put(q.x, q.y, c, 25)

# ================================================================ pontas da faixa
## Duas pontas saindo do nó atrás do capuz: 2 px de largura no começo, 1 px no fim, onda que corre com a fase.
func draw_tips(lib, O: Vector2, ctx: Dictionary, tp: Dictionary) -> void:
	var K: Vector2 = (ctx.hd as Vector2) + KNOT + Vector2(0.5, 0.5)
	var specs := [[tp.a0, tp.get("l0", 8.0), "r2", 0.0], [tp.a1, tp.get("l1", 6.0), "r1", 1.7]]
	var ph: float = tp.get("phase", 0.0)
	var amp: float = tp.get("amp", 1.1)
	for s in specs:
		var ang := deg_to_rad(float(s[0]))
		var D := Vector2(cos(ang), sin(ang))
		var N := Vector2(-D.y, D.x)
		var Ln: float = s[1]
		var d := 0.0
		while d <= Ln:
			var p := K + D * d + N * sin(d * 0.85 + ph + float(s[3])) * amp * (d / Ln)
			lib.put(int(floor(p.x)), int(floor(p.y)), s[2], 42)
			if d < Ln * 0.45:
				var p2 := p + N * 0.9
				lib.put(int(floor(p2.x)), int(floor(p2.y)), "r1", 42)
			d += 0.3

# ================================================================ poses
func pose(o: Dictionary, cape: Dictionary, tips: Dictionary) -> Dictionary:
	var p := o.duplicate()
	if not cape.is_empty():
		p["before_torso"] = func(lib, O, ctx): draw_cape(lib, O, ctx, cape)
	if not tips.is_empty():
		p["after_torso"] = func(lib, O, ctx): draw_tips(lib, O, ctx, tips)
	return p

## Agachado na beira do telhado (contra a lua): pé da frente na beira com o joelho alto, o antebraço apoiado nele; o de trás
## na ponta do pé. A capa cai reta até o telhado e amontoa; o vento mexe só as pontas da faixa e a barra. Respira 1 px.
func roof_poses() -> Array:
	var out := []
	for i in 4:
		var br := 0.0 if i in [0, 3] else -1.0
		var p := {"hip": V(-3, -16), "top": V(8, -32 + br), "head": V(12, -41 + br), "face": "smirk",
			"toef": V(9, -1), "shoef": "flat", "kf": V(0.6, -1), "toeb": V(-9, -1), "shoeb": "ball", "kb": V(1, 0.4),
			"hf": V(14, -21 + br * 0.0), "pf": V(-0.3, 1), "hb": V(3, -15), "pb": V(-1, 0.2), "glove": "fist"}
		out.append(pose(p,
			{"dir": V(-0.22, 1), "len": 35.0, "w0": 2.6, "w1": 7.5, "wave": 0.5, "phase": i * PI * 0.5, "bulge": 3.0},
			{"a0": 186.0 + [0, -6, -3, 3][i], "a1": 172.0 + [0, 5, 8, 3][i], "l0": 9.0, "l1": 7.0, "phase": i * PI * 0.5, "amp": 1.2}))
	return out

func scare_poses() -> Array:
	return [
		# 0 antecipa: agacha mais fundo na beira do muro, braços para trás, cabeça à frente
		pose({"hip": V(-4, -14), "top": V(5, -30), "head": V(10, -38), "toef": V(8, -1), "shoef": "flat", "kf": V(0.6, -1),
			"toeb": V(-10, -1), "shoeb": "ball", "kb": V(1, 0.3), "hf": V(-6, -19), "pf": V(-1, -0.2), "hb": V(-8, -21), "pb": V(-1, -0.2), "glove": "fist"},
			{"dir": V(-0.22, 1), "len": 33.0, "w0": 2.6, "w1": 7.5, "bulge": 3.0},
			{"a0": 184.0, "a1": 170.0, "l0": 8.0, "l1": 6.0}),
		# 1 impulso: as pernas estendem, o corpo vai para a frente e para cima, as mãos à frente; a capa fica para trás
		pose({"hip": V(1, -28), "top": V(12, -43), "head": V(18, -50), "toef": V(12, -13), "shoef": "ball", "kf": V(1, -0.2),
			"toeb": V(-13, -4), "shoeb": "ball", "kb": V(0.5, 1), "hf": V(23, -42), "pf": V(0, 1), "hb": V(20, -46), "pb": V(0, 1), "glove": "open"},
			{"dir": V(-0.85, 0.55), "len": 26.0, "w0": 2.6, "w1": 5.0, "wave": 1.0, "ground": false, "bend": 2.0},
			{"a0": 196.0, "a1": 182.0, "l0": 9.0, "l1": 7.0, "phase": 1.0}),
		# 2 ápice: joelhos encolhidos, as garras subindo; a capa corre reta para trás
		pose({"hip": V(0, -38), "top": V(5, -56), "head": V(9, -64), "toef": V(10, -26), "shoef": "ball", "kf": V(1, -0.3),
			"toeb": V(-3, -24), "shoeb": "ball", "kb": V(1, 0.2), "hf": V(13, -64), "pf": V(1, 0.6), "hb": V(7, -66), "pb": V(1, 0.6), "glove": "open"},
			{"dir": V(-1, -0.15), "len": 26.0, "w0": 2.6, "w1": 4.6, "wave": 1.4, "phase": 0.8, "ground": false, "bend": -3.0},
			{"a0": 200.0, "a1": 188.0, "l0": 9.0, "l1": 7.0, "phase": 2.0}),
		# 3 descendo: pernas esticam para o pouso, garras no alto; a capa sobe reta atrás (o ar empurra)
		pose({"hip": V(0, -34), "top": V(3, -53), "head": V(6, -62), "toef": V(8, -8), "shoef": "ball", "kf": V(1, 0),
			"toeb": V(-6, -6), "shoeb": "ball", "kb": V(1, 0), "hf": V(11, -67), "pf": V(1, 0.4), "hb": V(4, -69), "pb": V(1, 0.4), "glove": "open"},
			{"dir": V(-0.35, -1), "len": 25.0, "w0": 2.6, "w1": 4.4, "wave": 1.2, "phase": 2.0, "ground": false, "bend": -3.0},
			{"a0": 240.0, "a1": 222.0, "l0": 9.0, "l1": 7.0, "phase": 3.0}),
		# 4 aterrissa: agacha largo (amortece), mãos à frente; a capa ainda no ar, descendo atrás
		pose({"hip": V(-2, -16), "top": V(6, -33), "head": V(11, -41), "toef": V(12, -1), "shoef": "flat", "kf": V(0.7, -0.6),
			"toeb": V(-11, -1), "shoeb": "ball", "kb": V(0.6, 0.6), "hf": V(17, -27), "pf": V(0, 1), "hb": V(13, -30), "pb": V(0, 1), "glove": "open"},
			{"dir": V(-0.8, -0.45), "len": 24.0, "w0": 2.6, "w1": 4.8, "wave": 1.0, "phase": 3.0, "ground": false, "bend": 4.0},
			{"a0": 214.0, "a1": 198.0, "l0": 8.0, "l1": 6.0, "phase": 4.0}),
		# 5 SUSTO: sobe na ponta do pé de trás, inclina sobre o ladrão, garras para cima e boca aberta; a capa cai reta
		pose({"hip": V(1, -30), "top": V(9, -47), "head": V(14, -55), "face": "scare", "toef": V(14, -1), "shoef": "flat", "kf": V(1, -0.2),
			"toeb": V(-7, -1), "shoeb": "ball", "kb": V(1, 0.2), "hf": V(26, -55), "pf": V(0.2, 1), "hb": V(25, -44), "pb": V(0, 1), "glove": "open"},
			{"dir": V(-0.15, 1), "len": 33.0, "w0": 2.6, "w1": 7.5, "wave": 0.8, "phase": 4.0, "bulge": 2.0},
			{"a0": 222.0, "a1": 204.0, "l0": 9.0, "l1": 7.0, "phase": 5.0, "amp": 1.4}),
		# 6 segura o SUSTO (ombros 1 px acima, pontas e barra mexem)
		pose({"hip": V(1, -30), "top": V(9, -48), "head": V(14, -56), "face": "scare", "toef": V(14, -1), "shoef": "flat", "kf": V(1, -0.2),
			"toeb": V(-7, -1), "shoeb": "ball", "kb": V(1, 0.2), "hf": V(26, -56), "pf": V(0.2, 1), "hb": V(25, -45), "pb": V(0, 1), "glove": "open"},
			{"dir": V(-0.13, 1), "len": 33.0, "w0": 2.6, "w1": 7.5, "wave": 0.8, "phase": 5.6, "bulge": 2.0},
			{"a0": 214.0, "a1": 198.0, "l0": 9.0, "l1": 7.0, "phase": 6.6, "amp": 1.4}),
	]

## O mesmo discípulo sem o traje, em guarda (comparação).
func normal_pose() -> Dictionary:
	return {"hip": V(0, -30), "top": V(2, -49), "head": V(5, -58), "toef": V(12, -1), "toeb": V(-3, -1),
		"hf": V(12, -45), "hb": V(9, -47), "glove": "old"}

# ================================================================ troca de paleta (como o jogo)
func keymap(look: Dictionary) -> Dictionary:
	var m := {}
	var keys: Dictionary = PAL.keys
	var opts: Dictionary = PAL.options
	var fields := {"skin": look.skin, "hair_color": look.hair_color, "shorts_color": look.shorts_color, "top_color": look.top_color,
		"socks": look.shorts_color}
	for f in fields:
		var ramp := {}
		for o in opts[f]:
			if o.id == fields[f]:
				ramp = o.ramp
		for slot in keys[f]:
			if ramp.has(slot):
				m[(keys[f][slot] as String).trim_prefix("#").to_lower()] = Color.html(ramp[slot])
	return m

func recolor(im: Image, m: Dictionary) -> void:
	for y in im.get_height():
		for x in im.get_width():
			var c := im.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var hx := c.to_html(false)
			if m.has(hx):
				im.set_pixel(x, y, m[hx])

func frame(look: Dictionary, p: Dictionary, tag: String, costume := true) -> Image:
	var b := build(look, costume)
	b["glove"] = p.get("glove", "fist")
	var im: Image = P.fight_frame(b, p, tag, Vector2i(FW, FH), PIV)
	recolor(im, keymap(look))
	for y in FH:
		for x in FW:
			if im.get_pixel(x, y).a > 0.0 and (x == 0 or y == 0 or x == FW - 1 or y == FH - 1):
				report.append("AVISO %s: pixel na borda (%d,%d)" % [tag, x, y])
				return im
	return im

# ================================================================ folha de conferência
func sky(w: int, h: int) -> Image:
	var im: Image = L.blank(w, h)
	im.fill(L.col("b0"))
	for y in h:
		for x in w:
			if y > h * 0.55 and (x + y) % 2 == 0 and float(y) / h > 0.55 + 0.25 * (float((x * 7) % 13) / 13.0):
				im.set_pixel(x, y, L.col("d1"))
			if ((x * 73 + y * 151) % 997) == 0:
				im.set_pixel(x, y, L.col("g3"))
	return im

func moon(im: Image, cx: int, cy: int, r: int) -> void:
	for y in range(cy - r - 3, cy + r + 4):
		for x in range(cx - r - 3, cx + r + 4):
			var d := Vector2(x - cx, y - cy).length()
			if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
				continue
			if d <= r:
				var c := "cream"
				if Vector2(x - cx + r * 0.3, y - cy - r * 0.2).length() < r * 0.28 or Vector2(x - cx - r * 0.35, y - cy + r * 0.35).length() < r * 0.18:
					c = "g3"
				if d > r - 1.2 and x > cx:
					c = "g3"
				im.set_pixel(x, y, L.col(c))
			elif d <= r + 2.5 and (x + y) % 2 == 0:
				im.set_pixel(x, y, L.col("b1"))

func roof(im: Image, y: int) -> void:
	L.R(im, 0, y, im.get_width(), 1, "br3")
	L.R(im, 0, y + 1, im.get_width(), 2, "br2")
	for yy in range(y + 3, im.get_height()):
		for x in im.get_width():
			im.set_pixel(x, yy, L.col("br1" if ((x / 6 + (yy - y) / 3) % 2 == 0) else "br0"))
			if (yy - y) % 3 == 0:
				im.set_pixel(x, yy, L.col("br0"))

func paste(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func bbox(frames: Array) -> Rect2i:
	var x0 := FW
	var y0 := FH
	var x1 := 0
	var y1 := 0
	for f in frames:
		var im: Image = f
		for y in FH:
			for x in FW:
				if im.get_pixel(x, y).a > 0.0:
					x0 = mini(x0, x); y0 = mini(y0, y); x1 = maxi(x1, x); y1 = maxi(y1, y)
	return Rect2i(x0 - 2, y0 - 2, x1 - x0 + 5, y1 - y0 + 5)

func night_cell(f: Image, crop: Rect2i, k: int, with_moon: bool, roof_y_in_frame: int) -> Image:
	var c: Image = f.get_region(crop)
	var bg := sky(crop.size.x, crop.size.y)
	if with_moon:
		moon(bg, int(crop.size.x * 0.5) + 6, int(crop.size.y * 0.30), 13)
	if roof_y_in_frame >= 0:
		roof(bg, roof_y_in_frame - crop.position.y)
	paste(bg, c, 0, 0)
	return P.scaled(bg, k)

func sheet(anims: Dictionary, normals: Dictionary, path: String, repo: String) -> void:
	var W := 2140
	var out: Image = L.blank(W, 3200)
	out.fill(L.col("d1"))
	var y := 6
	L.text(out, "RONDA NOTURNA - AMOSTRA DO VULTO (GATO PRETO)   perfil, escala da Panfletagem/garagem (~64 px), quadro 96x100, pivo (50,94) = chao", 6, y, "white")
	y += 10
	L.text(out, "o traje (capuz com orelhas largas e baixas, faixa da escola nos olhos com as pontas voando, capa de lona caindo reta) vestido em 3 discipulos reais (troca de paleta do jogo)", 6, y, "g3")
	y += 16
	# ---- 1) 1x e 3x: telhado + lua, os 3 discípulos, ao lado do lutador normal (mesmo discípulo sem traje)
	L.text(out, "1) POSE NO TELHADO COM A LUA - quadro 0.  Em cada par: O MESMO DISCIPULO SEM O TRAJE (guarda) | COM O TRAJE.  Ao fim: fighter_idle (garagem) para a altura", 6, y, "y1")
	y += 10
	var cr := bbox(anims.roof.a + anims.roof.b + anims.roof.c + [normals.a, normals.b, normals.c])
	cr = cr.merge(Rect2i(cr.position.x, int(PIV.y) - 70, cr.size.x, 2))
	var x := 6
	for k in [1, 3]:
		x = 6
		for lid in ["a", "b", "c"]:
			var n: Image = night_cell(normals[lid], cr, k, false, int(PIV.y))
			paste(out, n, x, y)
			x += n.get_width() + 2 * k
			var r: Image = night_cell(anims.roof[lid][0], cr, k, true, int(PIV.y))
			paste(out, r, x, y)
			x += r.get_width() + 8 * k
		# referência: fighter_idle (garagem) no mesmo chão
		var fi: Image = P.load_png(repo + "assets/sprites/characters/fighter_idle.png").get_region(Rect2i(0, 0, 48, 72))
		var ref: Image = L.blank(cr.size.x, cr.size.y)
		paste(ref, sky(cr.size.x, cr.size.y), 0, 0)
		roof(ref, int(PIV.y) - cr.position.y)
		paste(ref, fi, int(cr.size.x / 2) - 22, int(PIV.y) - cr.position.y - 67)
		var rs: Image = P.scaled(ref, k)
		paste(out, rs, x, y)
		y += cr.size.y * k + 4
	for i in 3:
		L.text(out, "%s: %s" % [["A", "B", "C"][i], LOOKS[i].nome], 6, y + i * 9, "white")
	y += 32
	# ---- 2) telhado em loop, 4 quadros 3x (os 3)
	L.text(out, "2) TELHADO EM LOOP (4 quadros, 6 fps): so as pontas da faixa, a barra da capa e 1 px de respiracao mexem", 6, y, "y1")
	y += 10
	var cr2 := bbox(anims.roof.a + anims.roof.b + anims.roof.c)
	x = 6
	for lid in ["a", "b", "c"]:
		for q in 4:
			var cell: Image = night_cell(anims.roof[lid][q], cr2, 3, q == 0, int(PIV.y))
			paste(out, cell, x, y)
			x += cell.get_width() + 3
		x += 14
	y += cr2.size.y * 3 + 12
	# ---- 3) SUSTO 7 quadros 3x, os 3 discípulos
	L.text(out, "3) SUSTO (7 quadros, 12 fps, sem loop; 5-6 seguram): 0 antecipa no muro, 1 impulso, 2 apice, 3 descendo (a capa sobe reta), 4 aterrissa, 5 SUSTO!, 6 segura", 6, y, "y1")
	y += 10
	var cr3 := bbox(anims.scare.a + anims.scare.b + anims.scare.c)
	for lid in ["a", "b", "c"]:
		x = 6
		for q in 7:
			var cell: Image = night_cell(anims.scare[lid][q], cr3, 3, false, int(PIV.y) if q in [0, 4, 5, 6] else -1)
			paste(out, cell, x, y)
			L.text(out, str(q), x + 3, y + 3, "white")
			x += cell.get_width() + 3
		y += cr3.size.y * 3 + 6
	# 1x em fila
	L.text(out, "1x (os 3 discipulos, quadros 0-6):", 6, y, "white")
	y += 10
	for lid in ["a", "b", "c"]:
		x = 6
		for q in 7:
			var cell: Image = night_cell(anims.scare[lid][q], cr3, 1, false, -1)
			paste(out, cell, x, y)
			x += cell.get_width() + 2
		y += cr3.size.y + 3
	y += 8
	# ---- 4) no fundo real da Ronda (Diretor de Arte), 1x e 2x
	var bgp := repo + "docs/arte/mockups/ronda_fundo.png"
	if FileAccess.file_exists(bgp):
		L.text(out, "4) NO FUNDO DA RONDA (mockup do Diretor de Arte) 1x e 2x: SUSTO do muro (y 196) ate a calcada (y 314), quadros 0-5 sobrepostos no arco; pose no telhado em (552,114)", 6, y, "y1")
		y += 10
		var bg: Image = P.load_png(bgp)
		var scene: Image = bg.duplicate()
		var arc := [V(140, 196), V(150, 186), V(156, 214), V(162, 262), V(166, 314), V(166, 314)]
		for q in [0, 1, 2, 3, 5]:
			var f: Image = anims.scare.a[q]
			paste(scene, f, int(arc[q].x - PIV.x), int(arc[q].y - PIV.y))
		var rf: Image = anims.roof.c[0]
		paste(scene, rf, int(552 - PIV.x), int(114 - PIV.y))
		paste(out, scene, 6, y)
		var big: Image = P.scaled(scene.get_region(Rect2i(60, 60, 560, 280)), 2)
		y += scene.get_height() + 6
		paste(out, big, 6, y)
		y += big.get_height() + 6
	out.crop(W, y)
	out.save_png(path)

# ================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var repo: String = args[0].replace("\\", "/").trim_suffix("/") + "/"
	var out_dir: String = args[1].replace("\\", "/").trim_suffix("/") + "/"
	L = load(repo + "tools/art/pixel_lib.gd").new()
	P = load(repo + "tools/art/personagem_lib.gd").new(L)
	P.use_keys()
	var man = JSON.parse_string(FileAccess.get_file_as_string(repo + "assets/sprites/manifest.json"))
	PAL = man.by_data_id.disciple_palette
	DirAccess.make_dir_recursive_absolute(out_dir + "seq")
	var anims := {"roof": {}, "scare": {}}
	var normals := {}
	for look in LOOKS:
		var lid: String = look.id
		var rp := roof_poses()
		var fr := []
		for i in rp.size():
			fr.append(frame(look, rp[i], "roof_%s[%d]" % [lid, i]))
		anims.roof[lid] = fr
		var sp := scare_poses()
		var fs := []
		for i in sp.size():
			fs.append(frame(look, sp[i], "scare_%s[%d]" % [lid, i]))
		anims.scare[lid] = fs
		normals[lid] = frame(look, normal_pose(), "normal_%s" % lid, false)
		P.strip(fr).save_png(out_dir + "ronda_vulto_roof_%s.png" % lid)
		P.strip(fs).save_png(out_dir + "ronda_vulto_scare_%s.png" % lid)
		for i in fs.size():
			P.scaled(fs[i], 4).save_png(out_dir + "seq/scare_%s_%d.png" % [lid, i])
		for i in fr.size():
			P.scaled(fr[i], 4).save_png(out_dir + "seq/roof_%s_%d.png" % [lid, i])
	var meta := {"sprites": {
		"ronda_vulto_roof": {"file": "res://assets/sprites/minigame/ronda_vulto_roof.png", "frame_size": [FW, FH], "frames": 4, "fps": 6,
			"pivot": [int(PIV.x), int(PIV.y)], "loop": true, "facing": "direita", "palette_swap": "disciple_palette",
			"note": "AMOSTRA (aguarda o dono). Vulto agachado na beira do telhado contra a lua; o traje por cima do discípulo da vez."},
		"ronda_vulto_scare": {"file": "res://assets/sprites/minigame/ronda_vulto_scare.png", "frame_size": [FW, FH], "frames": 7, "fps": 12,
			"pivot": [int(PIV.x), int(PIV.y)], "loop": false, "hold_frames": [5, 6], "air_frames": [1, 2, 3], "facing": "direita",
			"palette_swap": "disciple_palette",
			"note": "AMOSTRA (aguarda o dono). SUSTO: 0 antecipa, 1 impulso, 2 ápice, 3 descendo, 4 aterrissa, 5 SUSTO, 6 segura. A tela move o nó do muro à calçada nos quadros 1-3."},
	}}
	var f := FileAccess.open(out_dir + "ronda_personagens.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "\t"))
	f.close()
	if args.size() > 2:
		sheet(anims, normals, args[2], repo)
	var rf := FileAccess.open(out_dir + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		rf.store_line(l)
	for l in report:
		rf.store_line(l)
	rf.close()
	for l in P.log_lines + report:
		if (l as String).begins_with("AVISO"):
			print(l)
	print("ok ronda vulto")
	quit()
