extends SceneTree
## Ronda Noturna (Artista de Personagens): o ELENCO da tela "Estátua no telhado".
##   VULTO (o discípulo da vez com o traje do Gato Preto), EM CAMADAS como o discípulo do jogo:
##     body (corpo em cores-chave + traje em cor fixa: capa, pontas da faixa), top.tank / top.tee, socks e head.<corte>
##     (o capuz: 4 variantes, uma por corte). Troca de cor = by_data_id.disciple_palette (a mesma do discípulo).
##     Montagem: body -> top (se look.top != none) -> socks (se on) -> school_symbol.leg (se o lutador mostra o símbolo e está
##     sem parte de cima) -> head.<look.hair_style>. O R de raiz sai do desenho virado para a direita e a folha nunca é
##     espelhada (§29.2). Sem chest (no perfil o carimbo fica nas costas, sob a capa), sem band e sem front_mask (braço na
##     frente do capuz já fica no body porque o head só tem o que a cabeça muda). A sombra que o colarinho do capuz faz no
##     corpo vai para body/top (vdraw), então montado == desenhado direto (o gerador confere e conta os px diferentes).
##   Cor da faixa: constante BAND (vermelha, APROVADA pelo dono em 2026-11-25).
##   3 LADRÕES (estepe, bicicleta, portão), paleta fixa, rosto/roupa/corpo próprios.
## Padrão: .claude/skills/padrao-personagem. Corpo = personagem_lib.gd (perfil, fight_frame) com as medidas da garagem
## (~64 px em pé), igual às pessoas da tela da Ronda. Contrato da tela: docs/arte/ronda-manifest.md (minigame_layout.ronda).
##
## Quadro de TODAS as folhas: 96x100, pivô (50,94) = chão entre os pés. Vulto virado para a DIREITA (anda para a direita);
## ladrão trabalhando virado para a DIREITA (de costas para o vulto); a queda (fall) já sai virada para a ESQUERDA (ele se
## vira para o vulto e cai de bunda para trás); a fuga (flee) virada para a DIREITA. Nada precisa de espelho no jogo.
##
## Rodar headless de uma pasta temporária com project.godot vazio, APPDATA temporário, um Godot por vez:
##   godot --headless --max-fps 30 --path <tmp> --script <repo>/tools/art/make_sprites_ronda.gd -- <repo> <saida> [<folha.png>]
## Grava em <saida>/minigame/ as folhas, <saida>/ronda_personagens.json (entradas do manifest, lidas por
## tools/art/manifest_ronda_personagens.py), <saida>/seq/ (quadros 4x) e a folha de conferência. Não grava no projeto.

const FW := 96
const FH := 100
const PIV := Vector2(50, 94)
const PIV_FLIP := Vector2(45, 94)   # desenhado assim e espelhado: o pivô volta a (50,94)
const CUTS := ["short", "buzz", "volume", "bun"]

var L
var P
var report: Array = []
var PAL := {}
var META := {}

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================================================ VULTO
## Capuz de perfil (virado à direita), 16x18, âncora (8,11) (= HEAD_SIDE (7,7) + 1 coluna e 4 linhas: orelhas e volume).
## K/k/j capuz (d1/d2/g0), n costura (g1), r = beira clara da abertura e da aba (g1: lê "pano" e não "cabelo" em 1x),
## F/G faixa da escola (r2/r1), w = olho de gato pela fresta (y2). S/s/l/m pele e boca, H/h cabelo (chaves do discípulo).
## Melhoria (2026-11-25): o capuz agora DESCE pela nuca e abre num colarinho de pano sobre os ombros (linhas 18-21), em vez
## de acabar no queixo: em 1x isso separa "capuz" de "capacete com orelhas" (o pescoço de pele sumiu atrás do pano). A beira
## da abertura do rosto (r, g1) desce até o queixo e encontra o colarinho; uma prega (k->K) na nuca marca o pano dobrando.
const HOOD := [
	"..K........j....",
	"..KK......jj....",
	"..KnK....kjnj...",
	"..KkkKKKkkjjjj..",
	".KkkkkkkkkjjjjK.",
	".Kkkkkkkkkkjjjj.",
	"KKkkkkkkkkkkjjj.",
	"KKkkkkkkkkkkkjr.",
	"KKkkkkkkkkkkrr..",
	"GGFFFFFFFFFFFF..",
	"GGGGGGGGGGwGGG..",
	".KkkkkkrSsssl...",
	".KkkkkkrSsssll..",
	".KkkKkkrSsssss..",
	".KkkKkkrSssss...",
	".KkkkKkrSsmSs...",
	".KkkkKkrSsss....",
	".KKkkkkrSSs.....",
	".KkkkkkkrK......",
	"KKkkkkkkkrK.....",
	"KkkkKkkkkkrK....",
	"KKkkkKkkkkkK....",
]
const HOOD_ANCHOR := Vector2i(8, 11)
const HOOD_CUTS := {
	"buzz": {},
	"short": {8: "KKkkkkkkkkkkrrH."},
	"volume": {6: "KKkkkkkkkkkkjjjh", 7: "KKkkkkkkkkkkkjHh", 8: "KKkkkkkkkkkkrrH."},
	"bun": {2: ".KKnK....kjnj...", 3: "KKkkkKKKkkjjjj..", 4: "KkkkkkkkkkjjjjK.", 5: "KKkkkkkkkkkjjjj."},
}
const HOOD_FACES := {
	"normal": {},
	"smirk": {15: "..KkkkkrSssxs..."},
	"scare": {15: "..KkkkkrSxxSs...", 16: "..KKkkkrSxs....."},
	"oops": {15: "..KkkkkrSsxSs...", 16: "..KKkkkrSxs....."},
}
## Cor da FAIXA da escola (máscara e pontas): [sombra, base, luz]. VERMELHA, aprovada pelo dono em 2026-11-25 (amostra do
## vulto). Se um dia mudar, trocar só aqui e rodar de novo: capuz, pontas e a conferência mudam juntos.
const BAND := ["r1", "r2", "r3"]
func hood_legend() -> Dictionary:
	return {"K": "d1", "k": "d2", "j": "g0", "n": "g1", "r": "g1", "F": BAND[1], "G": BAND[0], "w": "y2"}
const KNOT := Vector2(-8, -1)

## Garra do SUSTO (melhoria 2026-11-25): mão aberta GRANDE, 4 dedos abertos em leque e curvos na ponta, com a unha clara
## (w = cream) e a palma em 3 tons; 7x7, para cima, virada à direita; âncora = palma. A antiga (5x5, pontinhos) lia como punho.
const CLAW_UP := [
	".w.w.w.",
	"s.s.s.w",
	"s.s.s.s",
	"sssssss",
	"Sssslll",
	".Sssss.",
	"..SSs..",
]
const CLAW_ANCHOR := Vector2i(3, 4)

## Discípulos da conferência (opções reais do data/disciples.json).
const LOOKS := [
	{"id": "a", "nome": "A: PADRAO (PELE 3, CURTO CASTANHO, SEM CAMISA, CALCAO VERDE, R DA ESCOLA NA COXA)",
		"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "top": "none", "top_color": "white", "shorts_color": "green", "socks": "none", "symbol": true},
	{"id": "b", "nome": "B: PELE 1, VOLUME RUIVO, REGATA AMARELA, CALCAO ROXO",
		"skin": "skin_1", "hair_color": "copper", "hair_style": "volume", "top": "tank", "top_color": "yellow", "shorts_color": "purple", "socks": "none"},
	{"id": "c", "nome": "C: PELE 5, COQUE PRETO, CAMISETA BRANCA, CALCAO AZUL, MEIAO",
		"skin": "skin_5", "hair_color": "black", "hair_style": "bun", "top": "tee", "top_color": "white", "shorts_color": "blue", "socks": "on"},
	{"id": "d", "nome": "D: PELE 4, RASPADO PLATINADO, CAMISETA PRETA, CALCAO BRANCO",
		"skin": "skin_4", "hair_color": "platinum", "hair_style": "buzz", "top": "tee", "top_color": "black", "shorts_color": "white", "socks": "on"},
]

## Vulto: corpo do discípulo em cores-chave, medidas da garagem em perfil. top/socks/cut = variante a desenhar.
var SYM_ON := false   # desenhar o símbolo da escola na coxa (camada school_symbol.leg)

func vbuild(cut: String, top: String, socks: bool, hood := true) -> Dictionary:
	var o: Dictionary = P.identidade("disc")
	o.merge({"lu": 10.0, "lf": 10.5, "lt": 14.2, "ls": 13.2, "arm_r": [2.6, 2.0, 2.2, 1.7], "leg_r": [3.6, 2.7, 2.5, 1.5],
		"shoulder": 0.86, "hip_w": 0.86, "shorts_t": 0.45, "shoe_maps": {"flat": P.SHOES["34"], "ball": P.SHOES["34ball"]}}, true)
	match top:
		"tank": o["top"] = "tank"
		"tee": o["top"] = "tshirt"; o["sleeve_t"] = 0.45; o["sleeve_add"] = 0.0
		_: o["top"] = "none"
	o["sock_on"] = socks
	if SYM_ON:
		o["school_symbol"] = "leg"   # R de raiz na coxa da frente (sem parte de cima); nunca espelhado
	if hood:
		var rows: Array = HOOD.duplicate()
		var c: Dictionary = HOOD_CUTS[cut]
		for k in c:
			rows[int(k)] = c[k]
		o["head_side"] = rows
		o["faces_side"] = HOOD_FACES
		o["head_anchor_side"] = HOOD_ANCHOR
		o["head_legend_extra"] = hood_legend()
	else:
		var dc: Dictionary = P.DISC_CUTS[cut]
		o["head_side"] = dc.side
		o["head_anchor_side"] = Vector2i(7 + int(dc.pad[0]), 7 + int(dc.pad[1]))
		o["faces_side"] = P._cut_faces(P.HEAD_SIDE, P.FACES_SIDE, dc.side, int(dc.pad[0]), int(dc.pad[1]))
	return P.build(o)

# ------------------------------------------------------------------------------------------------ capa
## Faixa de pano presa na nuca. A borda de dentro encosta nas costas; a capa cresce para fora. Cai reta, ou estica para
## trás/para cima no ar, sempre UMA faixa (nunca asa). Dobras irregulares (2 vincos longos que somem e voltam + ruído),
## barra escura desfiada de forma irregular, remendo costurado. No chão amontoa para trás.
const CAPE := ["d1", "st0", "st1"]

func h01(a: int, b: int) -> float:
	var n := (a * 374761393 + b * 668265263) & 0x7fffffff
	n = (n ^ (n >> 13)) * 1274126177 & 0x7fffffff
	return float(n % 1000) / 1000.0

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
	var w1: float = cp.get("w1", 7.0)
	var gy: float = O.y - 1.0
	var side: float = cp.get("side", 1.0)   # -1 = a capa vai para a frente (recuando)
	var Nn := Vector2(-D.y, D.x)
	if (Nn.x > 0.0 or (is_zero_approx(Nn.x) and Nn.y > 0.0)):
		Nn = -Nn
	Nn *= side
	var steps := int(ln * 4.0)
	var done := {}
	for i in steps + 1:
		var t := float(i) / float(steps)
		var off := bend * t * t + wave * sin(t * PI * 2.2 + ph) * t + float(cp.get("bulge", 0.0)) * sin(PI * pow(t, 0.6))
		var w := lerpf(w0, w1, pow(t, 0.8))
		var C: Vector2 = A + D * ln * t + Nn * (off + (w - w0) * 0.8)
		var u := -w
		while u <= w:
			var un := u / w
			var p := C + Nn * u
			u += 0.35
			if cp.get("ground", true) and p.y > gy:
				p = Vector2(p.x - (p.y - gy) * 0.9 * side, gy)
			var q := Vector2i(int(floor(p.x)), int(floor(p.y)))
			var key := q.x * 1000 + q.y
			if done.has(key):
				continue
			done[key] = true
			var c: String = CAPE[1]
			# Melhoria (2026-11-25): PREGAS de verdade. O pano sai franzido do colarinho e abre em 3 pregas que descem em
			# leque (posição fixa na largura, que só ondula devagar com o vento): crista clara (st1) com o lado de baixo da
			# luz escuro (d1) logo atrás, como pano grosso dobrado. Perto da nuca as pregas somem (pano esticado nos ombros).
			# A barra acompanha as pregas: sobe nos vales e desce nas cristas (barra recortada, não serrilhado aleatório).
			var pl := sin((un + 1.0) * PI * 1.5 + 0.5 * sin(t * 2.0 + ph) + 0.6)
			var fold_on := smoothstep(0.08, 0.3, t)
			if pl * fold_on > 0.62:
				c = CAPE[2]
			elif pl * fold_on < -0.55:
				c = CAPE[0]
			elif pl * fold_on > 0.35 and un > 0.3 and t < 0.6:
				c = CAPE[2]   # a luz da lua pega mais nas pregas de fora, em cima
			if un < -0.74:
				c = CAPE[0]   # junto das costas: sombra de contato
			var hem := 0.9 + 1.6 * maxf(0.0, -pl) * fold_on
			var left := (1.0 - t) * ln
			if left < hem - 0.9:
				continue      # vale da prega: a barra sobe
			if left < hem + 0.4:
				c = CAPE[0]   # barra (1 px escuro, segue o recorte)
			if t > 0.46 and t < 0.6 and un > 0.05 and un < 0.6:
				c = "d2"
				if (absf(un - 0.05) < 0.12 or absf(un - 0.6) < 0.12 or absf(t - 0.46) * ln < 0.6) and (q.x + q.y) % 2 == 0:
					c = "g1"
			lib.put(q.x, q.y, c, 25)

func draw_tips(lib, O: Vector2, ctx: Dictionary, tp: Dictionary) -> void:
	var K: Vector2 = (ctx.hd as Vector2) + KNOT + Vector2(0.5, 0.5)
	var specs := [[tp.a0, tp.get("l0", 8.0), BAND[1], 0.0], [tp.a1, tp.get("l1", 6.0), BAND[0], 1.7]]
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
				lib.put(int(floor(p2.x)), int(floor(p2.y)), BAND[0], 42)
			d += 0.3

## Garra: palma no ponto da mão; para cima se o antebraço sobe, deitada (dedos para a frente) se vai para a frente.
func draw_claw(lib, el: Vector2, hand: Vector2, id: int, far: bool, b: Dictionary) -> void:
	var d := hand - el
	var ang := 0.0
	if d.y > -absf(d.x) * 0.6:
		ang = 90.0
	var sk: Array = b.skin_far if far else b.skin
	lib.pmap(id, CLAW_UP, {"S": sk[0], "s": sk[1], "l": sk[2], "w": "cream"}, hand, CLAW_ANCHOR, ang)

func vpose(o: Dictionary, cape: Dictionary, tips: Dictionary) -> Dictionary:
	var p := o.duplicate()
	var claws: bool = p.get("claws", false)
	p["before_torso"] = func(lib, O, ctx):
		if claws:
			draw_claw(lib, ctx.elb, ctx.hb, P.FAR_GLOVE, true, lib.build_ref)
		if not cape.is_empty():
			draw_cape(lib, O, ctx, cape)
	if not tips.is_empty():
		p["after_torso"] = func(lib, O, ctx): draw_tips(lib, O, ctx, tips)
	if claws:
		p["end"] = func(lib, O, ctx): draw_claw(lib, ctx.elf, ctx.hf, P.NEAR_GLOVE, false, lib.build_ref)
	return p

func cape_down(ph: float, len := 34.0, bulge := 3.0) -> Dictionary:
	return {"dir": V(-0.22, 1), "len": len, "w0": 2.6, "w1": 7.5, "wave": 0.5, "phase": ph, "bulge": bulge}

func tips_wind(i: int, base0 := 186.0, base1 := 172.0) -> Dictionary:
	return {"a0": base0 + [0, -6, -3, 3, -4, 2, 0][i % 7], "a1": base1 + [0, 5, 8, 3, 6, 2, 4][i % 7], "l0": 9.0, "l1": 7.0,
		"phase": i * PI * 0.5, "amp": 1.2}

func vulto_poses() -> Dictionary:
	var A := {}
	# --- espreitar parado (4 q, loop 5 fps): agachado baixo na capa do muro, cabeça à frente, a mão da frente apoiada
	# no joelho e a de trás no muro; respira 1 px; o vento mexe a faixa e a barra.
	var idle := []
	for i in 4:
		var br := 0.0 if i in [0, 3] else -1.0
		idle.append(vpose({"hip": V(-3, -15), "top": V(8, -29 + br), "head": V(14, -37 + br), "face": "smirk",
			"toef": V(9, -1), "shoef": "flat", "kf": V(0.6, -1), "toeb": V(-9, -1), "shoeb": "ball", "kb": V(1, 0.4),
			"hf": V(15, -19), "pf": V(-0.3, 1), "hb": V(2, -10), "pb": V(-1, 0.3), "glove": "open"},
			cape_down(i * PI * 0.5, 33.0), tips_wind(i)))
	A["sneak_idle"] = idle
	# --- avançar agachado (6 q, loop 10 fps): passo na ponta dos pés de desenho animado, joelho alto, as mãos como
	# patas na frente do peito; o corpo sobe 2 px na passagem. Anda no lugar (a tela move o x).
	var legs := [[V(10, -1), "flat", V(-8, -3), "ball"], [V(5, -1), "flat", V(-1, -8), "ball"], [V(0, -1), "flat", V(8, -6), "ball"],
		[V(-8, -3), "ball", V(10, -1), "flat"], [V(-1, -8), "ball", V(5, -1), "flat"], [V(8, -6), "ball", V(0, -1), "flat"]]
	var walk := []
	for i in 6:
		var up := -2.0 if i in [1, 4] else 0.0
		var sw := 1.0 if i < 3 else -1.0
		walk.append(vpose({"hip": V(-1, -21 + up), "top": V(8, -37 + up), "head": V(13, -45 + up), "face": "smirk",
			"toef": legs[i][0], "shoef": legs[i][1], "kf": V(1, -0.5), "toeb": legs[i][2], "shoeb": legs[i][3], "kb": V(1, -0.5),
			"hf": V(17 + sw, -33 + up), "pf": V(0, 1), "hb": V(14 - sw, -35 + up), "pb": V(0, 1), "glove": "fist"},
			{"dir": V(-0.45, 1), "len": 28.0, "w0": 2.6, "w1": 6.5, "wave": 0.9, "phase": i * PI / 3.0, "bulge": 2.5, "ground": true},
			tips_wind(i, 190.0, 176.0)))
	A["sneak_walk"] = walk
	# --- congelar (2 q, loop 4 fps): estátua no meio do passo, num pé só, patas no alto; só o pé no ar treme 1 px.
	var frz := []
	for i in 2:
		frz.append(vpose({"hip": V(-1, -25), "top": V(5, -43), "head": V(9, -51), "face": "oops",
			"toef": V(7, -9 - i), "shoef": "ball", "kf": V(1, -0.6), "toeb": V(-2, -1), "shoeb": "ball", "kb": V(1, 0),
			"hf": V(15, -40), "pf": V(0, 1), "hb": V(11, -44), "pb": V(0, 1), "glove": "fist"},
			{"dir": V(-0.15, 1), "len": 30.0, "w0": 2.6, "w1": 6.5, "bulge": 2.0, "phase": 1.0},
			{"a0": 200.0, "a1": 190.0, "l0": 8.0, "l1": 6.0, "phase": 1.0 + i * 0.4, "amp": 1.0}))
	A["freeze"] = frz
	# --- visto / recuar (4 q, 10 fps, sem loop, segura o 3): susto do próprio vulto, pulo para trás, cai agachado e se
	# encolhe atrás da capa. A tela recua o x nos quadros 1-2.
	A["seen"] = [
		vpose({"hip": V(-2, -31), "top": V(-1, -49), "head": V(1, -58), "face": "scare", "toef": V(3, -3), "shoef": "ball", "kf": V(1, 0),
			"toeb": V(-6, -3), "shoeb": "ball", "kb": V(1, 0), "hf": V(10, -60), "pf": V(1, 0.5), "hb": V(-4, -61), "pb": V(-1, 0.5), "claws": true},
			{"dir": V(-0.1, 1), "len": 26.0, "w0": 2.6, "w1": 6.0, "wave": 0.8, "bulge": 1.5, "ground": false},
			{"a0": 250.0, "a1": 236.0, "l0": 8.0, "l1": 6.0, "phase": 0.5}),
		vpose({"hip": V(-4, -28), "top": V(-7, -46), "head": V(-4, -55), "face": "scare", "toef": V(8, -8), "shoef": "ball", "kf": V(1, -0.3),
			"toeb": V(2, -6), "shoeb": "ball", "kb": V(1, -0.3), "hf": V(6, -48), "pf": V(0, 1), "hb": V(2, -50), "pb": V(0, 1), "glove": "open"},
			{"dir": V(0.5, 0.6), "len": 24.0, "w0": 2.6, "w1": 5.5, "wave": 1.0, "ground": false, "side": -1.0},
			{"a0": 120.0, "a1": 140.0, "l0": 8.0, "l1": 6.0, "phase": 1.5}),
		vpose({"hip": V(-6, -15), "top": V(1, -30), "head": V(6, -38), "face": "oops", "toef": V(6, -1), "shoef": "flat", "kf": V(0.6, -1),
			"toeb": V(-12, -2), "shoeb": "ball", "kb": V(1, -0.7), "hf": V(11, -24), "pf": V(0, 1), "hb": V(8, -26), "pb": V(0, 1), "glove": "fist"},
			{"dir": V(-0.3, 1), "len": 30.0, "w0": 2.6, "w1": 7.0, "wave": 0.8, "bulge": 3.0, "phase": 2.0},
			{"a0": 196.0, "a1": 180.0, "l0": 8.0, "l1": 6.0, "phase": 2.5}),
		vpose({"hip": V(-6, -13), "top": V(0, -27), "head": V(4, -34), "face": "oops", "toef": V(5, -1), "shoef": "flat", "kf": V(0.6, -1),
			"toeb": V(-12, -2), "shoeb": "ball", "kb": V(1, -0.7), "hf": V(9, -21), "pf": V(0, 1), "hb": V(6, -23), "pb": V(0, 1), "glove": "fist"},
			{"dir": V(-0.3, 1), "len": 28.0, "w0": 2.6, "w1": 7.5, "wave": 0.6, "bulge": 4.0, "phase": 2.6},
			{"a0": 192.0, "a1": 178.0, "l0": 8.0, "l1": 6.0, "phase": 3.0}),
	]
	# --- pose no telhado com a lua (4 q, loop 6 fps)
	var roof := []
	for i in 4:
		var br := 0.0 if i in [0, 3] else -1.0
		roof.append(vpose({"hip": V(-3, -16), "top": V(8, -32 + br), "head": V(12, -41 + br), "face": "smirk",
			"toef": V(9, -1), "shoef": "flat", "kf": V(0.6, -1), "toeb": V(-9, -1), "shoeb": "ball", "kb": V(1, 0.4),
			"hf": V(14, -21), "pf": V(-0.3, 1), "hb": V(3, -15), "pb": V(-1, 0.2), "glove": "fist"},
			cape_down(i * PI * 0.5, 35.0), tips_wind(i)))
	A["roof"] = roof
	# --- SUSTO (7 q, 12 fps, sem loop; 5-6 seguram). Garras de verdade nos quadros 2-6.
	A["scare"] = [
		vpose({"hip": V(-4, -14), "top": V(5, -30), "head": V(10, -38), "toef": V(8, -1), "shoef": "flat", "kf": V(0.6, -1),
			"toeb": V(-10, -1), "shoeb": "ball", "kb": V(1, 0.3), "hf": V(-6, -19), "pf": V(-1, -0.2), "hb": V(-8, -21), "pb": V(-1, -0.2), "glove": "fist"},
			cape_down(0.0, 33.0), {"a0": 184.0, "a1": 170.0, "l0": 8.0, "l1": 6.0}),
		vpose({"hip": V(1, -28), "top": V(12, -43), "head": V(18, -50), "toef": V(12, -13), "shoef": "ball", "kf": V(1, -0.2),
			"toeb": V(-13, -4), "shoeb": "ball", "kb": V(0.5, 1), "hf": V(23, -42), "pf": V(0, 1), "hb": V(20, -46), "pb": V(0, 1), "glove": "open"},
			{"dir": V(-0.85, 0.55), "len": 26.0, "w0": 2.6, "w1": 5.0, "wave": 1.0, "ground": false, "bend": 2.0},
			{"a0": 196.0, "a1": 182.0, "l0": 9.0, "l1": 7.0, "phase": 1.0}),
		vpose({"hip": V(0, -38), "top": V(5, -56), "head": V(9, -64), "toef": V(10, -26), "shoef": "ball", "kf": V(1, -0.3),
			"toeb": V(-3, -24), "shoeb": "ball", "kb": V(1, 0.2), "hf": V(14, -64), "pf": V(1, 0.6), "hb": V(8, -67), "pb": V(1, 0.6), "claws": true},
			{"dir": V(-1, -0.15), "len": 26.0, "w0": 2.6, "w1": 4.6, "wave": 1.4, "phase": 0.8, "ground": false, "bend": -3.0},
			{"a0": 200.0, "a1": 188.0, "l0": 9.0, "l1": 7.0, "phase": 2.0}),
		vpose({"hip": V(0, -34), "top": V(3, -53), "head": V(6, -62), "toef": V(8, -8), "shoef": "ball", "kf": V(1, 0),
			"toeb": V(-6, -6), "shoeb": "ball", "kb": V(1, 0), "hf": V(12, -67), "pf": V(1, 0.4), "hb": V(5, -69), "pb": V(1, 0.4), "claws": true},
			{"dir": V(-0.35, -1), "len": 25.0, "w0": 2.6, "w1": 4.4, "wave": 1.2, "phase": 2.0, "ground": false, "bend": -3.0},
			{"a0": 240.0, "a1": 222.0, "l0": 9.0, "l1": 7.0, "phase": 3.0}),
		vpose({"hip": V(-2, -16), "top": V(6, -33), "head": V(11, -41), "toef": V(12, -1), "shoef": "flat", "kf": V(0.7, -0.6),
			"toeb": V(-11, -1), "shoeb": "ball", "kb": V(0.6, 0.6), "hf": V(18, -28), "pf": V(0, 1), "hb": V(14, -31), "pb": V(0, 1), "claws": true},
			{"dir": V(-0.8, -0.45), "len": 24.0, "w0": 2.6, "w1": 4.8, "wave": 1.0, "phase": 3.0, "ground": false, "bend": 4.0},
			{"a0": 214.0, "a1": 198.0, "l0": 8.0, "l1": 6.0, "phase": 4.0}),
		vpose({"hip": V(1, -30), "top": V(9, -47), "head": V(14, -55), "face": "scare", "toef": V(14, -1), "shoef": "flat", "kf": V(1, -0.2),
			"toeb": V(-7, -1), "shoeb": "ball", "kb": V(1, 0.2), "hf": V(26, -56), "pf": V(0.2, 1), "hb": V(25, -45), "pb": V(0, 1), "claws": true},
			{"dir": V(-0.15, 1), "len": 33.0, "w0": 2.6, "w1": 7.5, "wave": 0.8, "phase": 4.0, "bulge": 2.0},
			{"a0": 222.0, "a1": 204.0, "l0": 9.0, "l1": 7.0, "phase": 5.0, "amp": 1.4}),
		vpose({"hip": V(1, -30), "top": V(9, -48), "head": V(14, -56), "face": "scare", "toef": V(14, -1), "shoef": "flat", "kf": V(1, -0.2),
			"toeb": V(-7, -1), "shoeb": "ball", "kb": V(1, 0.2), "hf": V(26, -57), "pf": V(0.2, 1), "hb": V(25, -46), "pb": V(0, 1), "claws": true},
			{"dir": V(-0.13, 1), "len": 33.0, "w0": 2.6, "w1": 7.5, "wave": 0.8, "phase": 5.6, "bulge": 2.0},
			{"a0": 214.0, "a1": 198.0, "l0": 9.0, "l1": 7.0, "phase": 6.6, "amp": 1.4}),
	]
	return A

const VULTO_ANIMS := {
	"sneak_idle": {"fps": 5, "loop": true, "note": "espreitar parado (agachado na capa do muro; respira, o vento mexe a faixa e a capa)"},
	"sneak_walk": {"fps": 10, "loop": true, "note": "avançar agachado (passo na ponta dos pés, no lugar: a tela move o x de start a end enquanto segura)"},
	"freeze": {"fps": 4, "loop": true, "note": "congelar (estátua num pé só quando o ladrão olha; só o pé no ar treme 1 px)"},
	"seen": {"fps": 10, "loop": false, "hold": [3], "note": "visto/recuar (ESCAPOU: o vulto se assusta, pula para trás e se encolhe; a tela recua o x nos quadros 1-2)"},
	"roof": {"fps": 6, "loop": true, "note": "pose no telhado com a lua (pés em rooftop_pose.feet)"},
	"scare": {"fps": 12, "loop": false, "hold": [5, 6], "air": [1, 2, 3], "note": "SUSTO: 0 antecipa no muro, 1 impulso, 2 ápice, 3 descendo, 4 aterrissa em land, 5 SUSTO!, 6 segura (5-6 em loop no letreiro). A tela leva o nó de (end, walk_y) até land nos quadros 1-3."},
}
const VULTO_ORDER := ["sneak_idle", "sneak_walk", "freeze", "seen", "roof", "scare"]

## Desenha uma variante do vulto e devolve [imagem, ids].
func vdraw(p: Dictionary, cut: String, top: String, socks: bool, no_head: bool, tag: String) -> Array:
	var b := vbuild(cut, top, socks)
	b["glove"] = "none" if p.get("claws", false) else p.get("glove", "fist")
	P.build_ref = b
	P.skip_head = no_head
	var im: Image = P.fight_frame(b, p, tag, Vector2i(FW, FH), PIV)
	P.skip_head = false
	var idn: PackedInt32Array = P.ids.duplicate()
	if not no_head:
		return [im, idn]
	# Sem cabeça, mas COM a sombra de contato que o capuz (colarinho) faz no corpo: desenha de novo com o capuz e copia só os
	# pixels de corpo (não capuz, não o contorno do capuz no vazio). Assim a sombra cai na cor certa de cada camada (pele,
	# regata, camiseta), e a camada head fica só com o capuz e o contorno dele.
	var nlog: int = P.log_lines.size()
	var full: Image = P.fight_frame(b, p, tag, Vector2i(FW, FH), PIV)
	P.log_lines.resize(nlog)
	var idh: PackedInt32Array = P.ids.duplicate()
	for y in FH:
		for x in FW:
			var i := y * FW + x
			if idh[i] != P.HEAD and idn[i] != 0:
				im.set_pixel(x, y, full.get_pixel(x, y))
	return [im, idn]

func keyset() -> Dictionary:
	return P._key_set()

## Camadas de um quadro do vulto: body, tops, socks, heads.
func vlayers(p: Dictionary, tag: String) -> Dictionary:
	var B: Array = vdraw(p, "short", "none", false, true, tag + " body")
	var body: Image = B[0]
	var ids_b: PackedInt32Array = B[1]
	var w := FW
	var tz := PackedByteArray()
	tz.resize(w * FH)
	tz.fill(0)
	var tops := {}
	for tk in ["tank", "tee"]:
		var T: Array = vdraw(p, "short", tk, false, true, tag + " " + tk)
		var im: Image = T[0]
		var lay: Image = L.blank(FW, FH)
		var ti: PackedInt32Array = T[1]
		for y in FH:
			for x in FW:
				var c := im.get_pixel(x, y)
				if c != body.get_pixel(x, y) and not (ti[y * w + x] in P.LEG_IDS):
					lay.set_pixel(x, y, c)
					tz[y * w + x] = 1
		tops[tk] = lay
	var S: Array = vdraw(p, "short", "none", true, true, tag + " socks")
	var socks: Image = L.blank(FW, FH)
	for y in FH:
		for x in FW:
			var c: Color = (S[0] as Image).get_pixel(x, y)
			if c != body.get_pixel(x, y) and ((S[1] as PackedInt32Array)[y * w + x] in P.LEG_IDS):
				socks.set_pixel(x, y, c)
	# símbolo da escola (6c2/6d3): só a coxa. O R de perfil (3x5) sai do desenho virado para a direita e a folha NUNCA é
	# espelhada (§29.2), então ele lê certo. Peito: no perfil o carimbo fica nas costas, que a capa cobre -> sem camada chest.
	SYM_ON = true
	var Y: Array = vdraw(p, "short", "none", false, true, tag + " symbol")
	SYM_ON = false
	var sym: Image = L.blank(FW, FH)
	for y in FH:
		for x in FW:
			var c: Color = (Y[0] as Image).get_pixel(x, y)
			if c != body.get_pixel(x, y):
				sym.set_pixel(x, y, c)
	var keys := keyset()
	var heads := {}
	var moved := 0
	for cut in CUTS:
		var Hh: Array = vdraw(p, cut, "none", false, false, tag + " " + cut)
		var im: Image = Hh[0]
		var hi: PackedInt32Array = Hh[1]
		var lay: Image = L.blank(FW, FH)
		for y in FH:
			for x in FW:
				var c := im.get_pixel(x, y)
				if c == body.get_pixel(x, y):
					continue
				var i := y * w + x
				# sombra que a cabeça faz numa peça que a parte de cima cobre: fica fora (a roupa decide a cor ali)
				if hi[i] != P.HEAD and hi[i] != 0 and tz[i] == 1 and keys.has(c.to_html(false)):
					moved += 1
					continue
				lay.set_pixel(x, y, c)
		heads[cut] = lay
	return {"body": body, "tops": tops, "socks": socks, "sym": sym, "heads": heads, "shadow_px": moved}

func compose(ly: Dictionary, look: Dictionary) -> Image:
	var top = null
	if look.top == "tank":
		top = ly.tops.tank
	elif look.top == "tee":
		top = ly.tops.tee
	var socks = ly.socks if look.socks == "on" else null
	var base: Image = ly.body
	if look.get("symbol", false) and look.top == "none":
		base = ly.body.duplicate()
		var sm := symmap(look)
		for y in FH:
			for x in FW:
				var c: Color = (ly.sym as Image).get_pixel(x, y)
				if c.a > 0.0:
					base.set_pixel(x, y, sm.get(c.to_html(false), c))
	return P.compose_full(base, top, socks, ly.heads[look.hair_style], null, null, keymap(look))

## Cor do R na coxa pela disciple_palette.school_symbol_source.leg (como o DiscVisual faz).
func symmap(look: Dictionary) -> Dictionary:
	var src: Dictionary = PAL.school_symbol_source.leg
	var oid: String = src.map.get(look.shorts_color, "yellow")
	var ramp := {}
	for o in PAL.options.school_symbol:
		if o.id == oid:
			ramp = o.ramp
	var m := {}
	for slot in PAL.keys.school_symbol:
		if ramp.has(slot):
			m[(PAL.keys.school_symbol[slot] as String).trim_prefix("#").to_lower()] = Color.html(ramp[slot])
	return m

# ------------------------------------------------------------------------------------------------ paleta
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

# ================================================================================================ LADRÕES
## Cabeças de perfil (viradas à direita) desenhadas à mão, na grade do HEAD_SIDE (olho em [6,9+px], boca em [11,9+px]).
## C/c/k = gorro/boné (escuro/base/luz), o = bigode, u = barba rala, w = branco do olho (susto).
const TH_HEAD := {
	"tire": {"px": 0, "anchor": Vector2i(7, 7), "rows": [   # baixinho largo: gorro de lã com a barra dobrada, bigode
		"....cckkkc....",
		"..cccckkkkcc..",
		".Cccccckkkccc.",
		".CCCCCCCCCCCC.",
		"HHHHHHHsssll..",
		"HHHHHHssbbbl..",
		"HHHEEssssesl..",
		"HHHEsEsssssl..",
		".HHEEssssssll.",
		".HHHsssssssss.",
		"..HSssssoooo..",
		"...SSssssmSs..",
		"....SSuuuuu...",
		".....SSSuu....",
	]},
	"bike": {"px": 2, "anchor": Vector2i(9, 7), "rows": [   # magrelo comprido: boné virado para trás, cavanhaque
		"......CCCCCC....",
		"....CCcccckkCC..",
		"...CCccccckkkCC.",
		"CCCCCCCCCCCCCCC.",
		"..HHHHHHHsssll..",
		"..HHHHHHssbbbl..",
		"..HHHEEssssesl..",
		"..HHHEsEsssssl..",
		"...HHEEssssssll.",
		"...HHHsssssssss.",
		"....HSssssssss..",
		".....SSssssmSs..",
		"......SSsuuuu...",
		".......SSuuu....",
	]},
	"gate": {"px": 0, "anchor": Vector2i(7, 7), "rows": [   # médio barrigudo: careca com coroa de cabelo, bigodão
		"....SSssss....",
		"..SSsssllsss..",
		".SSssssslllls.",
		".SSsssssssslS.",
		"HHSssssssssl..",
		"HHHSsssbbbbl..",
		"HHHEEssssesl..",
		"HHHEsEsssssl..",
		".HHEEssssssll.",
		".HHHsssssssss.",
		"..HSsssoooooo.",
		"...SSssssmSs..",
		"....SSsssss...",
		".....SSSss....",
	]},
}

const CHINELO := {"rows": ["..DM.....", ".DMMw....", "DMMMMwLL.", "DMMMMMMMD", "ccccccccc"], "toe": Vector2i(8, 4), "ankle": Vector2i(3, 0), "ang": 0.0}
const CHINELO_BALL := {"rows": [".DM......", ".DMMw....", "..DMMwL..", "..DMMMMD.", "...cDMMMD", ".....cccc"], "toe": Vector2i(8, 5), "ankle": Vector2i(2, 0), "ang": 0.0}

const THIEVES := ["tire", "bike", "gate"]
const TH_NOTE := {
	"tire": "ladrão do estepe: baixinho e largo, gorro de lã, bigode, regata encardida, bermuda jeans e chinelo; chave de roda em cruz",
	"bike": "ladrão da bicicleta: magrelo comprido, boné para trás, cavanhaque, corta-vento roxo, calça de moletom; alicate",
	"gate": "ladrão do portão: barrigudo, careca de bigodão, camisa social marrom, calça jeans e botina; pé de cabra",
}

func tbuild(tid: String, face: String, look_back: bool) -> Dictionary:
	var o := {}
	match tid:
		"tire":
			o = {"lu": 9.0, "lf": 9.5, "lt": 11.5, "ls": 10.5, "arm_r": [3.0, 2.4, 2.6, 2.0], "leg_r": [4.0, 3.2, 3.0, 1.8],
				"shoulder": 1.12, "hip_w": 1.1, "belly": 1.5, "hair": ["d1", "g0"], "brow": "ink", "skin": ["sk0", "sk1", "sk2"],
				"cap": ["gr0", "gr1", "gr2"], "mustache": "d1", "stubble": "sk0",
				"top": "tank", "shirt": ["g2", "g3", "cream"], "grease": true, "shorts": ["b0", "b1", "b2"], "band": "b1", "shorts_t": 0.72,
				"shoes": ["sk0", "sk1", "sk2", "b2", "y0"], "shoe_maps": {"flat": CHINELO, "ball": CHINELO_BALL}}
		"bike":
			o = {"lu": 11.5, "lf": 12.0, "lt": 16.0, "ls": 15.0, "arm_r": [2.1, 1.7, 1.8, 1.4], "leg_r": [2.9, 2.2, 2.1, 1.3],
				"shoulder": 0.76, "hip_w": 0.74, "hair": ["br0", "br1"], "brow": "br0", "skin": ["sk1", "sk2", "y2"],
				"cap": ["b0", "b1", "b2"], "stubble": "br1",
				"top": "tshirt", "sleeve_long": true, "shirt_detail": "zip", "shirt": ["p0", "p1", "p2"],
				"bottom": "pants", "shorts": ["g0", "g1", "g2"], "band": "g2",
				"shoes": ["g2", "g3", "white", "r2", "g1"], "shoe_maps": {"flat": P.SHOES["34"], "ball": P.SHOES["34ball"]}}
		"gate":
			o = {"lu": 10.0, "lf": 10.5, "lt": 13.5, "ls": 12.5, "arm_r": [2.7, 2.1, 2.3, 1.8], "leg_r": [3.8, 2.9, 2.6, 1.6],
				"shoulder": 1.0, "hip_w": 1.0, "belly": 3.2, "hair": ["d1", "d2"], "brow": "d1", "skin": ["br0", "sk0", "sk1"],
				"mustache": "ink",
				"top": "tshirt", "sleeve_t": 0.42, "shirt_detail": "social", "shirt": ["st1", "st2", "st3"],
				"bottom": "pants", "shorts": ["b0", "b1", "b2"], "band": "br0",
				"shoes": ["br0", "br1", "br2", "y0", "ink"], "shoe_maps": {"flat": P.SHOES["34"], "ball": P.SHOES["34ball"]}}
	var hd: Dictionary = TH_HEAD[tid]
	var rows := face_rows(hd.rows, face, int(hd.px))
	var an: Vector2i = hd.anchor
	if look_back:
		var fl := []
		for r in rows:
			fl.append((r as String).reverse())
		rows = fl
		an = Vector2i((rows[0] as String).length() - 1 - an.x, an.y)
	o["head_side"] = rows
	o["faces_side"] = {"normal": {}}
	o["head_anchor_side"] = an
	o["head_legend_extra"] = {"w": "white"}
	o["glove"] = "fist"
	return P.build(o)

## Expressões por troca de pixel na grade do HEAD_SIDE (px = colunas a mais à esquerda).
func face_rows(base: Array, face: String, px: int) -> Array:
	var r := base.duplicate()
	var setc := func(row: int, col: int, ch: String):
		var s: String = r[row]
		var c := col + px
		if c < s.length() and s[c] != ".":
			r[row] = s.substr(0, c) + ch + s.substr(c + 1)
	match face:
		"alert":
			setc.call(6, 9, "w"); setc.call(6, 10, "e")
			for c in [8, 9, 10]:
				setc.call(5, c, "s"); setc.call(4, c, "b")
		"fright":
			setc.call(6, 9, "w"); setc.call(6, 10, "e")
			for c in [8, 9, 10]:
				setc.call(5, c, "s"); setc.call(4, c, "b")
			setc.call(11, 9, "x"); setc.call(11, 10, "x"); setc.call(12, 9, "x"); setc.call(12, 10, "x")
		"effort":
			setc.call(6, 9, "x"); setc.call(6, 10, "x")
			setc.call(11, 8, "x"); setc.call(11, 9, "x"); setc.call(11, 10, "x")
		"squint":
			setc.call(6, 9, "x"); setc.call(6, 10, "x"); setc.call(6, 8, "s")
			setc.call(5, 11, "b")
		"wince":
			setc.call(6, 8, "x"); setc.call(6, 9, "x"); setc.call(6, 10, "x")
			setc.call(11, 9, "x"); setc.call(11, 10, "x")
		"daze":
			setc.call(6, 9, "x"); setc.call(5, 9, "x"); setc.call(6, 10, "s")
			setc.call(11, 8, "x"); setc.call(12, 9, "x"); setc.call(11, 10, "x")
	return r

# ------------------------------------------------------------------------------------------------ ferramentas
## Desenhadas no gancho "end" (na frente da mão da frente), em cor fixa.
func line_px(lib, a: Vector2, b: Vector2, c: String, id: int) -> void:
	var d := b - a
	var n := maxi(int(ceil(maxf(absf(d.x), absf(d.y)))), 1)
	for k in range(n + 1):
		var q := (a + d * (float(k) / float(n))).floor()
		lib.put(int(q.x), int(q.y), c, id)

func draw_tool(lib, O: Vector2, ctx: Dictionary, tool: Dictionary) -> void:
	var id: int = P.NEAR_GLOVE_TOP + 6
	match tool.kind:
		"wrench":   # chave de roda em cruz girando no cubo do estepe
			var hub: Vector2 = O + (tool.hub as Vector2) + Vector2(0.5, 0.5)
			var a := deg_to_rad(float(tool.ang))
			var u := Vector2(cos(a), sin(a)) * 5.0
			var v := Vector2(-u.y, u.x)
			line_px(lib, hub - u, hub + u, "st2", id)
			line_px(lib, hub - v, hub + v, "st1", id)
			lib.put(int(floor(hub.x)), int(floor(hub.y)), "st3", id)
		"pliers":  # alicate: cabos vermelhos saindo da mão, bico de aço na corrente
			var h: Vector2 = ctx.hf
			var tip: Vector2 = O + (tool.tip as Vector2)
			var gap: float = tool.get("gap", 1.0)
			line_px(lib, h + Vector2(0, -gap * 0.5), tip, "r1", id)
			line_px(lib, h + Vector2(0, gap * 0.5 + 1.0), tip + Vector2(0, 1), "r2", id)
			lib.put(int(tip.x) + 1, int(tip.y), "st3", id)
			lib.put(int(tip.x) + 1, int(tip.y) + 1, "st2", id)
			lib.put(int(tip.x) + 2, int(tip.y), "st2", id)
		"crowbar":  # pé de cabra: da ponta enfiada no portão, passando pelas mãos, até o cabo (gancho na ponta)
			var tip: Vector2 = O + (tool.tip as Vector2)
			var hf: Vector2 = ctx.hf
			var dirv := (hf - tip).normalized()
			var end := hf + dirv * 4.0
			line_px(lib, tip, end, "st1", id)
			line_px(lib, tip + Vector2(0, -1), end + Vector2(0, -1), "st2", id)
			lib.put(int(tip.x) + 1, int(tip.y) - 1, "st1", id)
			lib.put(int(tip.x) + 1, int(tip.y) - 2, "st2", id)
			lib.put(int(end.x), int(end.y), "r1", id)

func tpose(o: Dictionary, tool: Dictionary) -> Dictionary:
	var p := o.duplicate()
	if not tool.is_empty():
		p["end"] = func(lib, O, ctx): draw_tool(lib, O, ctx, tool)
	return p

## Poses dos ladrões. Coordenadas no corpo de cada um (medidas próprias).
func thief_poses(tid: String) -> Dictionary:
	var A := {}
	match tid:
		"tire":
			var base := {"hip": V(3, -10), "top": V(12, -22), "head": V(17, -28), "toef": V(12, -1), "shoef": "flat", "kf": V(0.5, -1),
				"toeb": V(-6, -1), "shoeb": "ball", "kb": V(0.4, 1), "pf": V(0, 1), "pb": V(0, 1)}
			var hub := V(20, -10)
			var work := []
			var angs := [-90.0, -60.0, -30.0, -60.0]
			for i in 4:
				var a := deg_to_rad(angs[i])
				var u := Vector2(cos(a), sin(a)) * 4.0
				var p := base.duplicate()
				p.merge({"hb": hub + V(-2, 3), "face": "effort" if i in [1, 2] else "normal"}, true)
				p["hf"] = hub + u * 0.9 + V(-1, 0)
				work.append(tpose(p, {"kind": "wrench", "hub": hub, "ang": angs[i]}))
			A["work"] = work
			var still := base.duplicate()
			still.merge({"hf": hub + V(-1, -4), "hb": hub + V(-2, 3)}, true)
			A["warn"] = [tpose(_m(still, {"face": "alert", "head": V(16, -29), "top": V(11, -23)}), {"kind": "wrench", "hub": hub, "ang": -90.0}),
				tpose(_m(still, {"face": "alert", "head": V(15, -31), "top": V(10, -24)}), {"kind": "wrench", "hub": hub, "ang": -90.0})]
			A["look"] = [tpose(_m(still, {"face": "squint", "look_back": true, "head": V(12, -31), "top": V(9, -24), "tw": -1.0}), {"kind": "wrench", "hub": hub, "ang": -90.0}),
				tpose(_m(still, {"face": "alert", "look_back": true, "head": V(12, -31), "top": V(9, -24), "tw": -1.0}), {"kind": "wrench", "hub": hub, "ang": -90.0})]
			A["fake"] = [tpose(_m(still, {"face": "alert", "head": V(16, -29), "top": V(11, -23)}), {"kind": "wrench", "hub": hub, "ang": -90.0}),
				tpose(_m(still, {"face": "wince", "hb": V(12, -27), "pb": V(-1, 0.5)}), {"kind": "wrench", "hub": hub, "ang": -90.0}),
				tpose(_m(still, {"face": "normal", "hb": V(13, -25), "pb": V(-1, 0.5)}), {"kind": "wrench", "hub": hub, "ang": -90.0}),
				work[0]]
		"bike":
			var base := {"hip": V(-2, -29), "top": V(9, -49), "head": V(15, -57), "toef": V(9, -1), "shoef": "flat", "kf": V(1, -0.2),
				"toeb": V(-7, -1), "shoeb": "flat", "kb": V(1, 0), "pf": V(0.2, 1), "pb": V(0.2, 1)}
			var tip := V(19, -27)
			var work := []
			var hs := [[V(15, -26), V(13, -30), 2.0, "normal"], [V(15, -27), V(13, -28), 0.0, "effort"], [V(16, -27), V(14, -28), 0.0, "effort"], [V(15, -26), V(13, -29), 1.5, "normal"]]
			for i in 4:
				work.append(tpose(_m(base, {"hf": hs[i][0], "hb": hs[i][1], "face": hs[i][3]}), {"kind": "pliers", "tip": tip, "gap": hs[i][2]}))
			A["work"] = work
			var still := _m(base, {"hf": V(15, -26), "hb": V(13, -29)})
			var pl := {"kind": "pliers", "tip": tip, "gap": 2.0}
			A["warn"] = [tpose(_m(still, {"face": "alert", "top": V(8, -50), "head": V(13, -59)}), pl),
				tpose(_m(still, {"face": "alert", "top": V(8, -51), "head": V(12, -60)}), pl)]
			A["look"] = [tpose(_m(still, {"face": "squint", "look_back": true, "top": V(7, -51), "head": V(10, -60), "tw": -1.0}), pl),
				tpose(_m(still, {"face": "alert", "look_back": true, "top": V(7, -51), "head": V(10, -60), "tw": -1.0}), pl)]
			A["fake"] = [tpose(_m(still, {"face": "alert", "top": V(8, -50), "head": V(13, -59)}), pl),
				tpose(_m(still, {"face": "wince", "hb": V(9, -56), "pb": V(-1, 0.4)}), pl),
				tpose(_m(still, {"face": "normal", "hb": V(10, -54), "pb": V(-1, 0.4)}), pl),
				work[0]]
		"gate":
			var base := {"hip": V(-4, -25), "top": V(-6, -44), "head": V(-3, -53), "toef": V(9, -1), "shoef": "flat", "kf": V(1, -0.3),
				"toeb": V(-9, -1), "shoeb": "flat", "kb": V(1, 0), "pf": V(0, 1), "pb": V(0, 1)}
			var tip := V(15, -33)
			var work := []
			var st := [[V(-6, -44), V(-3, -53), V(8, -30), V(4, -29), "normal"], [V(-8, -43), V(-5, -52), V(7, -30), V(3, -29), "effort"],
				[V(-9, -43), V(-6, -52), V(6, -30), V(2, -29), "effort"], [V(-6, -44), V(-3, -53), V(8, -30), V(4, -29), "normal"]]
			for i in 4:
				work.append(tpose(_m(base, {"top": st[i][0], "head": st[i][1], "hf": st[i][2], "hb": st[i][3], "face": st[i][4]}), {"kind": "crowbar", "tip": tip}))
			A["work"] = work
			var still := _m(base, {"hf": V(8, -30), "hb": V(4, -29)})
			var cb := {"kind": "crowbar", "tip": tip}
			A["warn"] = [tpose(_m(still, {"face": "alert", "top": V(-5, -45), "head": V(-2, -54)}), cb),
				tpose(_m(still, {"face": "alert", "top": V(-5, -46), "head": V(-2, -55)}), cb)]
			A["look"] = [tpose(_m(still, {"face": "squint", "look_back": true, "top": V(-6, -45), "head": V(-5, -54), "tw": -1.0}), cb),
				tpose(_m(still, {"face": "alert", "look_back": true, "top": V(-6, -45), "head": V(-5, -54), "tw": -1.0}), cb)]
			A["fake"] = [tpose(_m(still, {"face": "alert", "top": V(-5, -45), "head": V(-2, -54)}), cb),
				tpose(_m(still, {"face": "wince", "hb": V(-11, -50), "pb": V(-1, 0.6)}), cb),
				tpose(_m(still, {"face": "normal", "hb": V(-10, -48), "pb": V(-1, 0.6)}), cb),
				work[0]]
	A["fall"] = fall_poses(tid)
	A["flee"] = flee_poses(tid)
	return A

func _m(a: Dictionary, b: Dictionary) -> Dictionary:
	var r := a.duplicate()
	r.merge(b, true)
	return r

## Medidas de cada ladrão para adaptar as poses de corpo inteiro (queda e fuga) desenhadas no corpo médio.
## [pernas, tronco, braços] (braços = alcance do ladrão / alcance do corpo médio 20,5, com 5% de folga)
const TH_SCALE := {"tire": [0.8, 0.88, 0.86], "bike": [1.13, 1.15, 1.09], "gate": [0.95, 1.0, 0.95]}

func fit(tid: String, p: Dictionary) -> Dictionary:
	var fl: float = TH_SCALE[tid][0]
	var ft: float = TH_SCALE[tid][1]
	var q := p.duplicate()
	var hip: Vector2 = p.hip
	var nh := Vector2(hip.x, hip.y * fl)
	q["hip"] = nh
	var nt: Vector2 = nh + ((p.top as Vector2) - hip) * ft
	q["top"] = nt
	var dtop: Vector2 = nt - (p.top as Vector2)
	var fa: float = TH_SCALE[tid][2] if (TH_SCALE[tid] as Array).size() > 2 else 1.0
	for k in ["head", "ef", "eb"]:
		if p.has(k):
			q[k] = (p[k] as Vector2) + dtop
	for k in ["hf", "hb"]:
		if p.has(k):
			q[k] = nt + ((p[k] as Vector2) - (p.top as Vector2)) * fa
	for k in ["toef", "toeb"]:
		if p.has(k):
			var t: Vector2 = p[k]
			q[k] = Vector2(t.x, t.y * fl)
	return q

## SUSTO do ladrão (desenhado virado para o vulto e espelhado: na tela ele olha para a ESQUERDA e cai para a DIREITA).
## 0 pula de susto (duro, braços para cima, olho branco), 1 tropeça para trás no ar, 2 bate de bunda (pernas para cima),
## 3 quica, 4 sentado tonto, 5 segura (treme 1 px). Poeira = fx_dust_fall no quadro 2.
func fall_poses(tid: String) -> Array:
	var raw := [
		{"hip": V(0, -36), "top": V(-1, -55), "head": V(0, -64), "face": "fright", "toef": V(4, -5), "shoef": "ball", "toeb": V(-4, -5), "shoeb": "ball",
			"kf": V(1, 0), "kb": V(1, 0), "hf": V(7, -67), "pf": V(1, 0.3), "hb": V(-6, -66), "pb": V(-1, 0.3), "glove": "open"},
		{"hip": V(-5, -26), "top": V(-12, -43), "head": V(-11, -52), "face": "fright", "toef": V(9, -12), "shoef": "ball", "toeb": V(3, -7), "shoeb": "ball",
			"kf": V(1, -0.4), "kb": V(1, -0.4), "hf": V(8, -46), "pf": V(0, 1), "hb": V(3, -52), "pb": V(0, 1), "glove": "open"},
		{"hip": V(-6, -6), "top": V(-14, -22), "head": V(-14, -31), "face": "fright", "toef": V(13, -17), "shoef": "ball", "toeb": V(9, -10), "shoeb": "ball",
			"kf": V(0.3, -1), "kb": V(0.3, -1), "hf": V(-17, -3), "pf": V(-0.5, -1), "hb": V(-19, -4), "pb": V(-0.5, -1), "glove": "open"},
		{"hip": V(-6, -8), "top": V(-12, -25), "head": V(-11, -34), "face": "fright", "toef": V(14, -21), "shoef": "ball", "toeb": V(11, -14), "shoeb": "ball",
			"kf": V(0.3, -1), "kb": V(0.3, -1), "hf": V(-16, -5), "pf": V(-0.5, -1), "hb": V(-18, -6), "pb": V(-0.5, -1), "glove": "open"},
		{"hip": V(-6, -6), "top": V(-9, -24), "head": V(-7, -33), "face": "daze", "toef": V(14, -2), "shoef": "flat", "toeb": V(10, -1), "shoeb": "flat",
			"kf": V(0.3, -1), "kb": V(0.3, -1), "hf": V(-16, -2), "pf": V(-0.5, -1), "hb": V(-18, -3), "pb": V(-0.5, -1), "glove": "open"},
		{"hip": V(-6, -6), "top": V(-9, -25), "head": V(-7, -34), "face": "daze", "toef": V(14, -2), "shoef": "flat", "toeb": V(10, -1), "shoeb": "flat",
			"kf": V(0.3, -1), "kb": V(0.3, -1), "hf": V(-16, -2), "pf": V(-0.5, -1), "hb": V(-18, -3), "pb": V(-0.5, -1), "glove": "open"},
	]
	var out := []
	for p in raw:
		var q := fit(tid, p)
		q["flip"] = true
		out.append(q)
	return out

## Fuga (4 q, loop 12 fps): corrida de pânico virada para a direita, braços para cima, passada larga, olho branco.
func flee_poses(tid: String) -> Array:
	var raw := [
		{"hip": V(0, -30), "top": V(6, -48), "head": V(10, -57), "toef": V(12, -6), "shoef": "ball", "toeb": V(-11, -3), "shoeb": "ball",
			"kf": V(1, -0.3), "kb": V(1, 0.3), "hf": V(7, -62), "pf": V(1, 0.3), "hb": V(-5, -60), "pb": V(-1, 0.3)},
		{"hip": V(0, -32), "top": V(6, -50), "head": V(10, -59), "toef": V(2, -1), "shoef": "flat", "toeb": V(-3, -12), "shoeb": "ball",
			"kf": V(1, -0.3), "kb": V(1, -0.4), "hf": V(13, -58), "pf": V(1, 0.3), "hb": V(-1, -63), "pb": V(-1, 0.3)},
		{"hip": V(0, -30), "top": V(6, -48), "head": V(10, -57), "toef": V(-11, -3), "shoef": "ball", "toeb": V(12, -6), "shoeb": "ball",
			"kf": V(1, 0.3), "kb": V(1, -0.3), "hf": V(-4, -59), "pf": V(-1, 0.3), "hb": V(10, -62), "pb": V(1, 0.3)},
		{"hip": V(0, -32), "top": V(6, -50), "head": V(10, -59), "toef": V(-3, -12), "shoef": "ball", "toeb": V(2, -1), "shoeb": "flat",
			"kf": V(1, -0.4), "kb": V(1, -0.3), "hf": V(2, -64), "pf": V(-1, 0.3), "hb": V(13, -57), "pb": V(1, 0.3)},
	]
	var out := []
	for p in raw:
		var q := fit(tid, p)
		q["face"] = "fright"
		q["glove"] = "open"
		out.append(q)
	return out

const THIEF_ANIMS := {
	"work": {"fps": 6, "loop": true, "note": "trabalha de costas para o vulto (estado 'trabalha')"},
	"warn": {"fps": 4, "loop": true, "note": "AVISO: para, endireita e levanta a cabeça (estado 'aviso'; o ui_thief_warn ? fica em cima)"},
	"look": {"fps": 3, "loop": true, "note": "OLHANDO: vira a cabeça para trás, desconfiado (estado 'olhando'; não precisa espelhar)"},
	"fake": {"fps": 6, "loop": false, "note": "aviso falso: estava no AVISO, dá um tapa no mosquito na nuca, coça e volta ao trabalho (o último quadro = work[0])"},
	"fall": {"fps": 10, "loop": false, "hold": [4, 5], "dust_frame": 2, "note": "SUSTO: pula de susto, vira para o vulto e cai de bunda para trás (já vem virado para a ESQUERDA); 4-5 seguram sentado e tonto; fx_dust_fall nos pés no quadro 2. O prop (ronda_prop_*) sai voando no quadro 0."},
	"flee": {"fps": 12, "loop": true, "note": "fuga em pânico para a DIREITA (a tela move o x até sair); começa depois do fall"},
}
const THIEF_ORDER := ["work", "warn", "look", "fake", "fall", "flee"]

func tdraw(tid: String, p: Dictionary, tag: String) -> Image:
	var b := tbuild(tid, p.get("face", "normal"), p.get("look_back", false))
	b["glove"] = p.get("glove", "fist")
	P.build_ref = b
	var flip: bool = p.get("flip", false)
	var im: Image = P.fight_frame(b, p, tag, Vector2i(FW, FH), PIV_FLIP if flip else PIV)
	if flip:
		im.flip_x()
	return im

# ================================================================================================ conferência
func check_border(im: Image, tag: String) -> void:
	for y in FH:
		for x in FW:
			if im.get_pixel(x, y).a > 0.0 and (x == 0 or y == 0 or x == FW - 1 or y == FH - 1):
				report.append("AVISO %s: pixel na borda (%d,%d)" % [tag, x, y])
				return

func sky(w: int, h: int) -> Image:
	var im: Image = L.blank(w, h)
	im.fill(L.col("b0"))
	for y in h:
		for x in w:
			if ((x * 73 + y * 151) % 997) == 0:
				im.set_pixel(x, y, L.col("g3"))
	return im

func ground_strip(im: Image, y: int, c1: String, c2: String) -> void:
	if y < 0 or y >= im.get_height():
		return   # quadro no ar: o recorte não chega ao chão
	L.R(im, 0, y, im.get_width(), 1, c1)
	L.R(im, 0, y + 1, im.get_width(), im.get_height() - y - 1, c2)

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
	return Rect2i(maxi(x0 - 2, 0), maxi(y0 - 2, 0), mini(x1 - x0 + 5, FW), mini(y1 - y0 + 5, FH))

func cell(f: Image, crop: Rect2i, k: int, ground: bool) -> Image:
	var bg := sky(crop.size.x, crop.size.y)
	if ground:
		ground_strip(bg, int(PIV.y) - crop.position.y, "g1", "d2")
	paste(bg, f.get_region(crop), 0, 0)
	return P.scaled(bg, k)

func row_anim(out: Image, frames: Array, crop: Rect2i, x: int, y: int, k: int, label: String) -> int:
	L.text(out, label, x, y, "y1")
	y += 9
	var cx := x
	for i in frames.size():
		var c := cell(frames[i], crop, k, true)
		paste(out, c, cx, y)
		L.text(out, str(i), cx + 2, y + 2, "white")
		cx += c.get_width() + 2
	return y + crop.size.y * k + 6

func sheet(V_: Dictionary, VL: Dictionary, T_: Dictionary, path: String, repo: String, checks: Dictionary, before_dir := "") -> void:
	var W := 2200
	var out: Image = L.blank(W, 9000)
	out.fill(L.col("d1"))
	var y := 6
	L.text(out, "RONDA NOTURNA - ELENCO (VULTO EM CAMADAS + 3 LADROES)   quadro 96x100, pivo (50,94) = chao.  Perfil, ~64 px em pe (escala da tela da Ronda).", 6, y, "white")
	y += 10
	L.text(out, "Vulto montado pelo jogo: body + top + socks + head.<corte>, trocado pela disciple_palette. Conferencia camadas x desenho direto: %s" % checks.text, 6, y, "g3")
	y += 16
	if before_dir != "":
		y = before_after(out, y, VL, T_, before_dir)
	# VULTO: look A em 3x, B/C/D em 1x
	L.text(out, "VULTO (discipulo A em 3x; ao lado, B, C e D em 1x)", 6, y, "white")
	y += 12
	for an in VULTO_ORDER:
		var all := []
		for lid in VL:
			all += VL[lid][an]
		var cr := bbox(all)
		var meta: Dictionary = VULTO_ANIMS[an]
		var lab := "ronda_vulto_%s  %d q, %d fps%s - %s" % [an, (VL.a[an] as Array).size(), meta.fps, " loop" if meta.loop else "", meta.note]
		var yy := row_anim(out, VL.a[an], cr, 6, y, 3, lab.substr(0, 200))
		# 1x dos outros
		var x1 := 6 + ((VL.a[an] as Array).size()) * (cr.size.x * 3 + 2) + 12
		var ty := y + 9
		for lid in ["b", "c", "d"]:
			var cx := x1
			for f in VL[lid][an]:
				var c := cell(f, cr, 1, true)
				paste(out, c, cx, ty)
				cx += c.get_width() + 1
			ty += cr.size.y + 2
		y = maxi(yy, ty + 4)
	# camadas de um quadro
	L.text(out, "CAMADAS (scare q5, 3x): body (chaves) | top.tank | top.tee | socks | head.short | head.buzz | head.volume | head.bun | montado A | B | C | D", 6, y, "y1")
	y += 9
	var lf: Dictionary = V_.layers_demo
	var cr5 := bbox([lf.body])
	cr5 = cr5.grow(4)
	var parts := [lf.body, lf.tops.tank, lf.tops.tee, lf.socks, lf.heads.short, lf.heads.buzz, lf.heads.volume, lf.heads.bun]
	for lid in ["a", "b", "c", "d"]:
		parts.append(V_.demo_looks[lid])
	var cx := 6
	for im in parts:
		var bg: Image = L.blank(cr5.size.x, cr5.size.y)
		bg.fill(L.col("g1"))
		paste(bg, (im as Image).get_region(cr5), 0, 0)
		var s: Image = P.scaled(bg, 3)
		paste(out, s, cx, y)
		cx += s.get_width() + 3
	y += cr5.size.y * 3 + 12
	# LADRÕES
	for tid in THIEVES:
		L.text(out, "LADRAO %s - %s" % [tid.to_upper(), TH_NOTE[tid]], 6, y, "white")
		y += 11
		var all := []
		for an in THIEF_ORDER:
			all += T_[tid][an]
		var cr := bbox(all)
		var x := 6
		var ybase := y
		var ymax := y
		for an in THIEF_ORDER:
			var meta: Dictionary = THIEF_ANIMS[an]
			var n: int = (T_[tid][an] as Array).size()
			var wneed := n * (cr.size.x * 3 + 2)
			if x + wneed > W - 6:
				x = 6
				ybase = ymax + 4
			var yy := row_anim(out, T_[tid][an], cr, x, ybase, 3, "%s %dq %dfps%s" % [an, n, meta.fps, " loop" if meta.loop else ""])
			ymax = maxi(ymax, yy)
			x += wneed + 14
		y = ymax + 8
	# NO FUNDO
	var bgp := repo + "docs/arte/mockups/ronda_fundo.png"
	if FileAccess.file_exists(bgp):
		L.text(out, "NA RUA (fundo do Diretor de Arte), 1x e 2x: vulto avancando no muro (tire), congelado (bike), SUSTO no portao com o ladrao caindo; ladroes nos pontos; telhado em (552,114)", 6, y, "y1")
		y += 10
		var sc: Image = P.load_png(bgp)
		_put(sc, VL.a.sneak_walk[1], V(90, 196))
		_put(sc, T_.tire.look[0], V(192, 314))
		_put(sc, VL.c.freeze[0], V(320, 196))
		_put(sc, T_.bike.work[0], V(392, 314))
		_put(sc, VL.b.scare[5], V(566, 314))
		_put(sc, T_.gate.fall[2], V(592, 314))
		_put(sc, VL.d.roof[0], V(552, 114))
		paste(out, sc, 6, y)
		y += 366
		var big: Image = P.scaled(sc.get_region(Rect2i(40, 90, 600, 240)), 2)
		paste(out, big, 6, y)
		y += big.get_height() + 6
	out.crop(W, y)
	out.save_png(path)

## ANTES (folha parcial do WIP 63bedab, seq 4x) x DEPOIS, 1x e 3x, nos quadros onde as melhorias aparecem.
func before_after(out: Image, y: int, VL: Dictionary, T_: Dictionary, bdir: String) -> int:
	var picks := [["vulto", "roof", 0, "capuz desce p/ os ombros"], ["vulto", "sneak_walk", 1, "capuz + R na coxa"],
		["vulto", "scare", 2, "garras + pregas"], ["vulto", "scare", 5, "garras do SUSTO"], ["vulto", "seen", 0, "garras"],
		["tire", "work", 0, "perto do estepe"], ["gate", "work", 0, "camisa (antes sumia na pele)"]]
	L.text(out, "ANTES (parcial do WIP, commit 63bedab) x DEPOIS - cada par: antes | depois, em 3x e embaixo em 1x", 6, y, "y1")
	y += 10
	var x := 6
	var h3 := 0
	var row1: Array = []
	for pk in picks:
		var nm: String = ("vulto_%s_a_%d.png" % [pk[1], pk[2]]) if pk[0] == "vulto" else ("thief_%s_%s_%d.png" % [pk[0], pk[1], pk[2]])
		if not FileAccess.file_exists(bdir + nm):
			continue
		var b4: Image = P.load_png(bdir + nm)
		b4.resize(FW, FH, Image.INTERPOLATE_NEAREST)
		var now: Image = (VL.a[pk[1]][pk[2]] if pk[0] == "vulto" else T_[pk[0]][pk[1]][pk[2]])
		var cr := bbox([b4, now])
		L.text(out, pk[3], x, y, "g3")
		var cx := x
		for im in [b4, now]:
			var c := cell(im, cr, 3, true)
			paste(out, c, cx, y + 9)
			cx += c.get_width() + 2
		L.text(out, "ANTES", x + 2, y + 11, "white")
		L.text(out, "DEPOIS", x + cr.size.x * 3 + 4, y + 11, "y1")
		row1.append([b4, now, cr, x])
		h3 = maxi(h3, cr.size.y * 3)
		x = cx + 10
	y += 9 + h3 + 4
	var h1 := 0
	for r in row1:
		var cx: int = r[3]
		for im in [r[0], r[1]]:
			var c := cell(im, r[2], 1, true)
			paste(out, c, cx, y)
			cx += c.get_width() + 1
		h1 = maxi(h1, (r[2] as Rect2i).size.y)
	return y + h1 + 12

func _put(dst: Image, f: Image, feet: Vector2) -> void:
	paste(dst, f, int(feet.x - PIV.x), int(feet.y - PIV.y))

# ================================================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var repo: String = args[0].replace("\\", "/").trim_suffix("/") + "/"
	var out_dir: String = args[1].replace("\\", "/").trim_suffix("/") + "/"
	L = load(repo + "tools/art/pixel_lib.gd").new()
	P = load(repo + "tools/art/personagem_lib.gd").new(L)
	P.use_keys()
	var man = JSON.parse_string(FileAccess.get_file_as_string(repo + "assets/sprites/manifest.json"))
	PAL = man.by_data_id.disciple_palette
	DirAccess.make_dir_recursive_absolute(out_dir + "minigame")
	DirAccess.make_dir_recursive_absolute(out_dir + "seq")
	var sprites := {}
	# ---------------- vulto
	var VA := vulto_poses()
	var VL := {}   # look -> anim -> frames montados
	for lk in LOOKS:
		VL[lk.id] = {}
	var bad_total := 0
	var shadow_total := 0
	var nframes := 0
	var demo := {}
	for an in VULTO_ORDER:
		var poses: Array = VA[an]
		var lay := {"body": [], "tank": [], "tee": [], "socks": [], "sym": [], "short": [], "buzz": [], "volume": [], "bun": []}
		for lk in LOOKS:
			VL[lk.id][an] = []
		for i in poses.size():
			var tag := "vulto_%s[%d]" % [an, i]
			var ly := vlayers(poses[i], tag)
			shadow_total += int(ly.shadow_px)
			nframes += 1
			lay.body.append(ly.body); lay.tank.append(ly.tops.tank); lay.tee.append(ly.tops.tee); lay.socks.append(ly.socks); lay.sym.append(ly.sym)
			for c in CUTS:
				lay[c].append(ly.heads[c])
			for lk in LOOKS:
				var comp := compose(ly, lk)
				# conferência: o mesmo look desenhado direto
				SYM_ON = lk.get("symbol", false) and lk.top == "none"
				var d: Array = vdraw(poses[i], lk.hair_style, lk.top, lk.socks == "on", false, tag + " direto " + lk.id)
				SYM_ON = false
				var full: Image = d[0]
				var km := keymap(lk)
				km.merge(symmap(lk))
				var nd := 0
				for yy in FH:
					for xx in FW:
						var c0 := full.get_pixel(xx, yy)
						if c0.a > 0.0 and km.has(c0.to_html(false)):
							c0 = km[c0.to_html(false)]
						if c0 != comp.get_pixel(xx, yy):
							nd += 1
				bad_total += nd
				if nd > 0:
					report.append("NOTA camadas %s %s: %d px montado x desenhado" % [tag, lk.id, nd])
				(VL[lk.id][an] as Array).append(comp)
				check_border(comp, tag + " " + lk.id)
			if an == "scare" and i == 5:
				demo = ly
		var base := "ronda_vulto_%s" % an
		P.strip(lay.body).save_png(out_dir + "minigame/%s_disc_body.png" % base)
		P.strip(lay.tank).save_png(out_dir + "minigame/%s_disc_top_tank.png" % base)
		P.strip(lay.tee).save_png(out_dir + "minigame/%s_disc_top_tee.png" % base)
		P.strip(lay.socks).save_png(out_dir + "minigame/%s_disc_socks.png" % base)
		P.strip(lay.sym).save_png(out_dir + "minigame/%s_disc_symbol_leg.png" % base)
		for c in CUTS:
			P.strip(lay[c]).save_png(out_dir + "minigame/%s_disc_head_%s.png" % [base, c])
		var meta: Dictionary = VULTO_ANIMS[an]
		var e := {"file": "res://assets/sprites/minigame/%s_disc_body.png" % base, "frame_size": [FW, FH], "frames": poses.size(),
			"fps": meta.fps, "pivot": [int(PIV.x), int(PIV.y)], "loop": meta.loop, "facing": "direita", "who": "vulto",
			"palette_swap": "disciple_palette", "action": an, "mirror_ok": false,
			# body é obrigatório: DiscVisual.textura() monta a partir de layers.body (sem ele devolve a folha crua, sem capuz).
			"layers": {"order": ["body", "top", "socks", "school_symbol", "head"],
				"body": "res://assets/sprites/minigame/%s_disc_body.png" % base,
				"top": {"tank": "res://assets/sprites/minigame/%s_disc_top_tank.png" % base, "tee": "res://assets/sprites/minigame/%s_disc_top_tee.png" % base},
				"socks": "res://assets/sprites/minigame/%s_disc_socks.png" % base,
				"school_symbol": {"leg": "res://assets/sprites/minigame/%s_disc_symbol_leg.png" % base},
				"head": {}},
			"note": "Vulto (Gato Preto) = o discípulo da vez com o traje. " + meta.note + " Montagem: body -> top.<tank|tee> se look.top != none -> socks se look.socks == on -> head.<look.hair_style>; trocar as cores-chave pela disciple_palette (como o discípulo). school_symbol.leg (o R de raiz, chaves keys.school_symbol, cor pela school_symbol_source.leg) só quando o lutador mostra o símbolo E está sem parte de cima (com parte de cima não há camada: no perfil o carimbo do peito fica nas costas, sob a capa). Nunca espelhar (o R não é simétrico, §29.2). Sem band e sem front_mask."}
		for c in CUTS:
			e.layers.head[c] = "res://assets/sprites/minigame/%s_disc_head_%s.png" % [base, c]
		for k in ["hold", "air"]:
			if meta.has(k):
				e[k + "_frames"] = meta[k]
		sprites[base] = e
		for i in poses.size():
			P.scaled(VL.a[an][i], 4).save_png(out_dir + "seq/vulto_%s_a_%d.png" % [an, i])
	var demo_looks := {}
	for lk in LOOKS:
		demo_looks[lk.id] = compose(demo, lk)
	# ---------------- ladrões
	var TT := {}
	for tid in THIEVES:
		TT[tid] = {}
		var A := thief_poses(tid)
		for an in THIEF_ORDER:
			var fr := []
			for i in (A[an] as Array).size():
				var im := tdraw(tid, A[an][i], "%s_%s[%d]" % [tid, an, i])
				check_border(im, "%s_%s[%d]" % [tid, an, i])
				fr.append(im)
				P.scaled(im, 4).save_png(out_dir + "seq/thief_%s_%s_%d.png" % [tid, an, i])
			TT[tid][an] = fr
			var base := "ronda_thief_%s_%s" % [tid, an]
			P.strip(fr).save_png(out_dir + "minigame/%s.png" % base)
			var meta: Dictionary = THIEF_ANIMS[an]
			var e := {"file": "res://assets/sprites/minigame/%s.png" % base, "frame_size": [FW, FH], "frames": fr.size(), "fps": meta.fps,
				"pivot": [int(PIV.x), int(PIV.y)], "loop": meta.loop, "facing": "esquerda" if an == "fall" else "direita",
				"who": "ladrao_" + tid, "action": an, "note": TH_NOTE[tid] + ". " + meta.note}
			if meta.has("hold"):
				e["hold_frames"] = meta.hold
			if meta.has("dust_frame"):
				e["dust_frame"] = meta.dust_frame
			sprites[base] = e
	var chk_text := "%d quadros x 4 discipulos, %d px diferentes (sombra da cabeca sob a roupa fica de fora em %d px)" % [nframes, bad_total, shadow_total]
	report.append("camadas: " + chk_text)
	var by := {"ronda_characters": {
		"_nota": "Ronda (Artista de Personagens): elenco da tela. Quadro 96x100, pivô (50,94) = chão (pés do vulto em walk_y/land/rooftop_pose.feet; do ladrão em occurrences.<id>.thief). Nada precisa de espelho. Vulto em camadas pela disciple_palette (ver o 'note' de cada ronda_vulto_*). Detalhes: docs/arte/ronda-personagens-manifest.md.",
		"vulto": {"sneak_idle": "ronda_vulto_sneak_idle", "sneak_walk": "ronda_vulto_sneak_walk", "freeze": "ronda_vulto_freeze",
			"seen": "ronda_vulto_seen", "roof": "ronda_vulto_roof", "scare": "ronda_vulto_scare"},
		"vulto_by_state": {"parado": "sneak_idle", "segurando": "sneak_walk", "ladrao_olhando_parado": "freeze", "visto": "seen", "susto": "scare", "fim": "roof"},
		"thieves": {},
		"thief_by_state": {"trabalha": "work", "aviso": "warn", "olhando": "look", "aviso_falso": "fake", "susto": "fall", "fuga": "flee"},
	}}
	for tid in THIEVES:
		var m := {}
		for an in THIEF_ORDER:
			m[an] = "ronda_thief_%s_%s" % [tid, an]
		by.ronda_characters.thieves[tid] = m
	META = {"sprites": sprites, "by_data_id": by}
	var f := FileAccess.open(out_dir + "ronda_personagens.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(META, "\t"))
	f.close()
	if args.size() > 2:
		sheet({"layers_demo": demo, "demo_looks": demo_looks}, VL, TT, args[2], repo, {"text": chk_text},
			(args[3].replace("\\", "/").trim_suffix("/") + "/") if args.size() > 3 else "")
	var rf := FileAccess.open(out_dir + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		rf.store_line(l)
	for l in report:
		rf.store_line(l)
	rf.close()
	for l in P.log_lines + report:
		if (l as String).begins_with("AVISO") or (l as String).begins_with("camadas"):
			print(l)
	print("ok ronda elenco: %d folhas" % sprites.size())
	quit()
