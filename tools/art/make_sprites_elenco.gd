extends SceneTree
## Gera o ELENCO no padrão novo (personagem_lib.gd): os 4 adversários da luta (9 ações, virados para a esquerda),
## os retratos 32x32 deles e os ajudantes da garagem (vizinhos, tios, Prof. Nelson). Artista de Personagens.
## Padrão: .claude/skills/padrao-personagem/SKILL.md. Aparência: docs/fases/fase3-textos.md.
## Rodar headless a partir de uma pasta temporária com um project.godot vazio (nunca no projeto):
##   godot --headless --path <pasta_tmp> --script E:/Fightclicker/tools/art/make_sprites_elenco.gd -- <saida> <antigos>
##   <saida>   = pasta onde gravar opponents/..., characters/... e relatorio.txt
##   <antigos> = pasta com as folhas antigas (backup), usada só na folha de contato antes/depois
## Lê (só leitura): assets/sprites/manifest.json (quadros, fps, pivô, hit_point, MÃOS por quadro, pos na sala).
## Escreve: <saida>/... e docs/arte/mockups/elenco_completo_x3.png. O manifest NÃO é alterado.
##
## MODO ACADEMIA (Fase 5): acrescente "gym" depois de <antigos>. Gera só Tonhão do Tatame (opp_gym_1, escala 1,04)
## e Kid Navalha (opp_gym_2, 1,08), os retratos, docs/arte/mockups/academia_adversarios_x3.png (contato 3x e 1x),
## academia_adversarios_arena_x2.png (na arena real) e <saida>/seq/ (quadros do ciclo para GIF). As entradas
## deles no manifest (mãos = mãos do jogador x escala, espelhadas) precisam existir antes de rodar.
##
## Como cada adversário é feito: as poses-chave da luta são as do jogador (make_sprites_jogador.gd), passadas
## pela ESCALA do corpo (Dinho 0,92 · Dudu 0,98 · Brutão 1,08 · Muralha 1,12) e por ajustes de personalidade
## (inclinação, base, pescoço, ombros, ponta do pé). As mãos vêm do manifest, espelhadas; o quadro é desenhado
## virado para a direita com pivô (55,98) e espelhado no fim, o que devolve o pivô exato (56,98).

var ROOT := OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else "E:/Fightclicker/"
var MANIFEST := ROOT + "assets/sprites/manifest.json"
var MOCK := ROOT + "docs/arte/mockups/elenco_completo_x3.png"
const FW := 112
const FH := 104
const ACTIONS := ["idle", "jab", "heavy", "hit", "dodge", "block", "tired", "victory", "ko"]
const OPPS := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank"]
const OPPS_GYM := ["opp_gym_1", "opp_gym_2"]   # Fase 5: academia (modo "gym")
var MOCK_GYM := ROOT + "docs/arte/mockups/academia_adversarios_x3.png"
var MOCK_GYM_ARENA := ROOT + "docs/arte/mockups/academia_adversarios_arena_x2.png"
const HELPERS := ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2", "coach_1"]
const LIGHT_C := Vector2(305, 90)   # lâmpada da garagem (mesma do fundo)
const PORTRAIT_BG := {"opp_warmup": ["gr0", "gr1"], "opp_strong": ["r0", "r1"], "opp_fast": ["b0", "b2"], "opp_tank": ["br1", "y0"],
	"opp_gym_1": ["p0", "p1"], "opp_gym_2": ["st0", "st2"]}

var L
var P
var M: Dictionary
var out_dir := ""
var old_dir := ""
var report: Array = []

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================ cabeças (dados de arte, desenhadas à mão)
## Perfil virado para a direita, 14x14, âncora (7,7), mesma geometria de rosto do jogador (olho 9,6; boca 9,11).
## W/B (legenda extra) = faixa/bandana luz/sombra; C/c/k = boné; Q/q = capuz; o = bigode.
const HEAD_DUDU := [   # cabelo bagunçado, faixa de cabeça mole com a ponta caída atrás
	"...HH.hHH.H...",
	"..HHhHHhhHHH..",
	".HHhhhhhhhHHH.",
	".BWWWWWWWWWWW.",
	"BBHHHHHsssll..",
	"BHHHHHssbbbl..",
	"BBHEEssssesl..",
	".BHEsEsssssl..",
	".HHEEssssssll.",
	".HHHsssssssss.",
	"..HSssssssss..",
	"...SSssssmSs..",
	"....SSsssss...",
	".....SSSss....",
]
const HEAD_BRUTAO := [  # boné do posto com aba para a frente, nuca raspada, queixo largo
	"....CCCCCC....",
	"..CCcckkkcC...",
	".CcccckkkkcC..",
	".CcccccccccC..",
	"HCCCCCCCCCCCCC",
	"HHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	".HHEEssssssll.",
	".HHSsssssssss.",
	"..SSssssssss..",
	"..SSSssssmSs..",
	"...SSSsssss...",
	"....SSSSSs....",
]
const HEAD_DINHO := [   # cabelo curto, bandana com nó atrás, capuz amontoado na nuca
	"....HHHHH.....",
	"..HHHHhhHHH...",
	".HHHHhhhhHHHH.",
	"WWWWWWWWWWWWW.",
	"BWBBHHHBBBBl..",
	"BHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	".HHEEssssssll.",
	"QHHHsssssssss.",
	"QqHSssssssss..",
	"QqqSSssssmSs..",
	"QqqqSSsssss...",
	".QqqqSSSss....",
]
const HEAD_MURALHA := [  # grisalho com entradas, queixo pesado (bigode entra pelo parâmetro mustache)
	"....HHHHH.....",
	"..HHHhhhhHs...",
	".HHHHhhhssll..",
	".HHHHHHsssssl.",
	"HHHHHHssssll..",
	"HHHHHHssbbbl..",
	"HHHEEssssesl..",
	"HHHEsEsssssl..",
	".HHEEssssssll.",
	".HHSsssssssss.",
	"..SSssssssss..",
	"..SSSssssmSs..",
	"..SSSSsssss...",
	"...SSSSSss....",
]
const HEAD_TONHAO := [   # cabeça redonda raspada (máquina), orelha de couve-flor, barba curta, queixo largo
	"....HHHHHH....",
	"..HHhHhhHhHH..",
	".HHhHhhhhHhHH.",
	".HHHhHHhHHHsl.",
	"HHHHHHHsssll..",
	"HHHHHHsbbbbl..",
	"HHEEEssssesl..",
	"HElEEEsssssl..",
	"HEEElEssssslll",
	".HEEEssssssss.",
	".HuSssssssss..",
	".uuuSssssmSu..",
	"..uuuussuuu...",
	"...uuuuuuu....",
]
const HEAD_KID := [   # degradê baixo com risco de navalha (R) no lado, topo curto penteado para a frente,
	"...HHHHHHH....",  # sobrancelha cortada, queixo fino
	"..HHhhhhhhHH..",
	".HHhhhhhhhhHH.",
	".HHHHHHHHHHHHl",
	"HHHRHHHHssll..",
	"HHRHHHHsbsbl..",
	"HfHEEssssesl..",
	"fHfEsEsssssl..",
	".fHEEssssssll.",
	".fffsssssssss.",
	"..fSssssssss..",
	"...SSssssmSs..",
	"....SSsssss...",
	".....SSSs.....",
]
## Pé descalço (Tonhão, tatame): mesma legenda do tênis (D/M/L/w/c), cores de pele no build. Mesmo deslocamento
## ponta->tornozelo do tênis, para a perna ter o mesmo alcance.
const PE_FLAT := ["..DMM......", "..DMMM.....", ".DMMMMLL...", "DMMMMMMMMLw", ".DDD..DDDDD"]
const PE_BALL := [".DM........", ".DMM.......", "..DMMM.....", "...DMMMLL..", "....DDMMMLw", "......DDDDD"]
## Bota de boxe (Kid): cano alto por cima da canela (linhas acima do tornozelo), cadarço claro.
const BOTA_FLAT := ["..DMw......", ".DMMw......", ".DMMw......", ".DMMwL.....", ".DMMMwL....", "DMMMMMMLL..", "DMMMMMMMMMD", "ccccccccccc"]
const BOTA_BALL := [".DMw.......", ".DMMw......", ".DMMwL.....", "..DMMwL....", "..DDMMMML..", "....DMMMMMD", ".....cccccc"]

## 3/4 virado para a direita (garagem), 13 de largura, âncora (6,6) salvo indicação.
const H34_N1 := [   # cabelo crespo baixinho
	"...HHHHHHH...",
	".HHHhhhhhHHH.",
	"HHHhhhhhhhHHH",
	"HHHHHHHHHHHHH",
	"HHHSsslllllll",
	"HHSSsbbsslbbl",
	"HESSsesssles.",
	"HEsSssssslll.",
	".ESsssssssss.",
	".SSsssssssSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]
const H34_N2 := [   # topete alto (âncora 6,8)
	"...HHhHH.....",
	"..HHhhhhHH...",
	".HHHhhhhhHHH.",
	"HHHHhhhhhhHHH",
	"HHHHHHHHHHHHH",
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
const H34_N3 := [   # boné virado para trás (aba atrás, à esquerda) — 14 de largura, âncora (7,6)
	"....CCCCCCC...",
	"..CCcccckkcC..",
	".CCccccccckkC.",
	"CCCCCCCCCCCCCs",
	"CCCHHsslllllll",
	".HHHSsbbsslbbl",
	".HHESsesssles.",
	".HEsSssssslll.",
	"..HESssssssss.",
	"..HSsssssssSs.",
	"...SsssmmmSs..",
	"....SSsssss...",
	"......SSSs....",
]
const H34_UNCLE := [  # careca com cabelo grisalho dos lados, bigode
	"....sslll....",
	"..sssslllll..",
	".Sssssslllll.",
	"SSsssssslllll",
	"HHSssslllllll",
	"HHSSsbbsslbbl",
	"HESSsesssles.",
	"HEsSssssslll.",
	".HSsssssssss.",
	".HSssoooosSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]
const H34_COACH := [  # grisalho penteado, bigode
	"...HHHHHHH...",
	".HHHHhhhHHHH.",
	"HHHHhhhhhHHHH",
	"HHHHHHHHHHHHs",
	"HHHSsslllllll",
	"HHSSsbbsslbbl",
	"HESSsesssles.",
	"HEsSssssslll.",
	".HSsssssssss.",
	".HSssoooosSs.",
	"..SsssmmmSs..",
	"...SSsssss...",
	".....SSSs....",
]

## Calçados próprios (mesma legenda D/M/L/w/c do tênis; no chinelo D/M/L = pele e w = tira).
const CHINELO_34 := ["..DMM....", ".DMMwL...", ".DMMMwLL.", "DMMMMMMLM", "ccccccccc"]
const CHINELO_34_BALL := [".DM......", ".DMMw....", "..DMMwL..", "..DMMMMM.", "...cDMMML", ".....cccc"]
const TENIS_CADARCO := ["..DMM......", ".DMwwLw....", "DMMMwMMLLD.", "DMwMMMMMMMD", "ccwcccccccc"]   # cadarço solto caindo
const TENIS_CADARCO_BALL := [".DM........", ".DMwwL.....", "..DMwMLL...", "..DwMMMMLD.", "..wccDMMMMD", ".....cccccc"]

# ================================================================ personagens
## Diferenças de face do jogador transplantadas para outra cabeça (só onde a outra cabeça tem rosto).
func transfer_faces(base: Array, faces: Dictionary, custom: Array) -> Dictionary:
	var out := {}
	var face_chars := ["s", "S", "l", "e", "b", "m", "x", "E", "u", "o"]
	for f in faces:
		var ov: Dictionary = faces[f]
		var nd := {}
		for k in ov:
			var pr: String = base[int(k)]
			var fr: String = ov[k]
			var cr: String = custom[int(k)]
			var nr := ""
			for i in cr.length():
				var c := cr[i]
				if i < pr.length() and i < fr.length() and pr[i] != fr[i] and c in face_chars:
					c = fr[i]
				nr += c
			nd[int(k)] = nr
		out[f] = nd
	return out

## Ficha de cada adversário: build (silhueta e roupa) + ajustes de pose.
##  s = escala do corpo; am = braço a mais (Dudu "Alongado"); lean = tronco à frente (px, espaço do jogador);
##  head_d = cabeça (px); neck_k = pescoço; shk = afastamento dos ombros; stance = [pé da frente, pé de trás];
##  toes = sempre na ponta do pé de trás (Dinho).
func opp_def(oid: String) -> Dictionary:
	match oid:
		"opp_warmup":   # Dudu Alongado: magro, médio, braços compridos, regata branca, calção verde-musgo, meião, faixa mole
			return {"s": 0.98, "am": 1.06, "lean": -0.5, "head_d": V(0, 0), "neck_k": 1.15, "shk": 0.9, "stance": [0, 0], "toes": false,
				"build": {"head_side": HEAD_DUDU, "head_legend_extra": {"W": "white", "B": "g3"},
				"hair": ["br1", "br2"], "brow": "br1", "skin": ["sk1", "sk2", "y2"],
				"top": "tank", "shirt": ["g3", "white", "white"], "shorts": ["gr0", "gr1", "gr2"], "band": "gr2", "shorts_t": 0.52,
				"socks": "white", "shoes": ["d1", "d2", "g1", "white", "g3"],
				"glove": "worn", "glove_ramp": ["st1", "st2", "st3"],
				"shoulder": 0.84, "hip_w": 0.86, "arm_r": [2.5, 1.8, 2.0, 1.4], "leg_r": [3.6, 2.5, 2.3, 1.4]}}
		"opp_strong":   # Brutão do Posto: o mais largo, ombrão, pescoço curto, curvado para a frente
			return {"s": 1.08, "am": 1.02, "lean": 2.0, "head_d": V(1, 1), "neck_k": 0.72, "shk": 1.5, "stance": [1, -1], "toes": false,
				"build": {"head_side": HEAD_BRUTAO, "cap": ["r0", "r1", "r2"], "stubble": "br0",
				"hair": ["ink", "d1"], "brow": "ink", "skin": ["br0", "sk0", "sk1"],
				"top": "tank", "shirt": ["g1", "g2", "g3"], "grease": true,
				"bottom": "pants", "shorts": ["b0", "b1", "b2"], "band": "b2", "belt": ["b0", "b1", "b2", "b1"],
				"shoes": ["br0", "br1", "br2", "br2", "d1"],
				"glove": "tape_red", "glove_ramp": ["d1", "d2", "g0"],
				"shoulder": 1.75, "hip_w": 1.15, "belly": 1.5, "arm_r": [4.4, 3.4, 3.6, 2.4], "leg_r": [5.2, 3.9, 3.4, 2.0]}}
		"opp_fast":     # Dinho Pulga: baixo, leve, sempre na ponta do pé, moletom com capuz, bandana, tênis laranja
			return {"s": 0.92, "am": 1.0, "lean": 1.0, "head_d": V(0, 0), "neck_k": 0.9, "shk": 0.9, "stance": [-1, 0], "toes": true,
				"build": {"head_side": HEAD_DINHO, "head_legend_extra": {"W": "white", "B": "g3"},
				"hair": ["ink", "d2"], "brow": "ink", "skin": ["sk0", "sk1", "sk2"],
				"top": "tshirt", "shirt": ["b1", "b2", "b3"], "sleeve_long": true,
				"shorts": ["d1", "d2", "g0"], "band": "b1", "shorts_t": 0.4,
				"shoes": ["br2", "br3", "y0", "white", "g2"],
				"shoe_maps": {"flat": {"rows": TENIS_CADARCO, "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0), "ang": 0.0},
					"ball": {"rows": TENIS_CADARCO_BALL, "toe": Vector2i(10, 5), "ankle": Vector2i(2, 0), "ang": 0.0}},
				"glove": "plain", "glove_ramp": ["br2", "br3", "y0"],
				"shoulder": 0.88, "hip_w": 0.86, "arm_r": [2.6, 1.9, 2.1, 1.5], "leg_r": [3.6, 2.6, 2.4, 1.4]}}
		"opp_tank":     # Seu Muralha: alto, largo, barriga firme, bigode grisalho, camiseta amarela, cinturão de pano
			return {"s": 1.12, "am": 1.02, "lean": 0.0, "head_d": V(-1, 0), "neck_k": 1.0, "shk": 1.15, "stance": [2, -2], "toes": false,
				"build": {"head_side": HEAD_MURALHA, "mustache": "g2",
				"hair": ["g2", "g3"], "brow": "g3", "skin": ["sk1", "sk2", "y2"],
				"top": "tshirt", "shirt": ["y0", "y1", "y2"], "sleeve_t": 0.5, "trim": "gr1",
				"shorts": ["d1", "d2", "g0"], "band": "g0", "shorts_t": 0.45, "belt": ["r0", "r1", "r2", "y0"],
				"shoes": ["d1", "d2", "g1", "g2", "g3"],
				"glove": "worn", "glove_ramp": ["br1", "br2", "br3"],
				"shoulder": 1.2, "hip_w": 1.3, "belly": 7.0, "arm_r": [3.8, 3.0, 3.1, 2.2], "leg_r": [5.0, 3.7, 3.3, 2.0]}}
		"opp_gym_1":    # Tonhão do Tatame: o mais LARGO e baixo do elenco, base de jiu-jitsu (agachado, pés bem
						# afastados), quimono velho amarelado, faixa roxa desbotada com ponta preta, descalço, orelha de couve-flor
			return {"s": 1.04, "am": 1.0, "lean": 1.5, "head_d": V(1, 2), "neck_k": 0.62, "shk": 1.45, "stance": [3, -3], "toes": false,
				"crouch": 2.0,
				"build": {"head_side": HEAD_TONHAO, "stubble": "br0",
				"hair": ["d1", "d2"], "brow": "ink", "skin": ["sk1", "sk2", "y2"],
				"top": "tshirt", "shirt": ["g2", "cream", "white"], "sleeve_long": true, "shirt_detail": "gi", "neck_v": 0.2,
				"sleeve_add": 1.4, "sleeve_add_fore": 1.0,
				"bottom": "pants", "shorts": ["g2", "g3", "cream"], "band": "p1", "pants_add": 1.5, "pants_shin_t": 0.84,
				"belt": ["p0", "p1", "p1", "p0"],
				"shoes": ["sk1", "sk2", "y2", "y2", "sk1"],
				"shoe_maps": {"flat": {"rows": PE_FLAT, "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0), "ang": 0.0},
					"ball": {"rows": PE_BALL, "toe": Vector2i(10, 5), "ankle": Vector2i(2, 0), "ang": 0.0},
					"up": {"rows": PE_FLAT, "toe": Vector2i(10, 4), "ankle": Vector2i(3, 0), "ang": -90.0}},
				"glove": "plain", "glove_ramp": ["b0", "b1", "b2"],
				"shoulder": 2.3, "hip_w": 1.85, "belly": 9.0, "arm_r": [5.0, 4.0, 4.0, 2.7], "leg_r": [6.0, 4.6, 3.9, 2.2]}}
		"opp_gym_2":    # Kid Navalha: o mais MAGRO e comprido, braços longos, tronco jogado para trás (queixo
						# guardado), sem camisa, calção de cetim prateado comprido com cós dourado, bota de boxe, luva branca
			return {"s": 1.08, "am": 1.07, "lean": -1.5, "head_d": V(-1, 1), "neck_k": 1.12, "shk": 0.8, "stance": [1, -1], "toes": true,
				"build": {"head_side": HEAD_KID, "head_legend_extra": {"R": "br2", "f": "br1"},
				"hair": ["ink", "d2"], "brow": "ink", "skin": ["br1", "br2", "sk1"],
				"top": "none", "shorts": ["st0", "st1", "st2"], "band": "y1", "shorts_t": 0.62,
				"shoes": ["d1", "d2", "g0", "g3", "g1"],
				"shoe_maps": {"flat": {"rows": BOTA_FLAT, "toe": Vector2i(10, 7), "ankle": Vector2i(3, 3), "ang": 0.0},
					"ball": {"rows": BOTA_BALL, "toe": Vector2i(10, 6), "ankle": Vector2i(2, 1), "ang": 0.0},
					"up": {"rows": BOTA_FLAT, "toe": Vector2i(10, 7), "ankle": Vector2i(3, 3), "ang": -90.0}},
				"glove": "plain", "glove_ramp": ["g2", "g3", "white"],
				"shoulder": 0.8, "hip_w": 0.78, "arm_r": [2.4, 1.8, 2.0, 1.4], "leg_r": [3.3, 2.4, 2.2, 1.3]}}
	return {}

func make_opp_build(oid: String) -> Dictionary:
	var d := opp_def(oid)
	var o: Dictionary = d.build.duplicate()
	var s: float = d.s
	var am: float = d.am
	o["lu"] = 12.0 * s * am
	o["lf"] = 13.0 * s * am
	o["lt"] = 17.5 * s
	o["ls"] = 16.5 * s
	o["faces_side"] = transfer_faces(P.HEAD_SIDE, P.FACES_SIDE, o.head_side)
	return P.build(o)

# ================================================================ poses de LUTA (as do jogador, espaço do jogador)
func fpose(o := {}) -> Dictionary:
	var p := {"hip": V(0, -37), "top": V(2, -61), "toef": V(15, -1), "toeb": V(-3, -1)}
	for k in o:
		p[k] = o[k]
	return p

## Cópia fiel de make_sprites_jogador.gd/fight_poses (mesmos números): é a base de todos os adversários.
func player_poses(action: String) -> Array:
	match action:
		"idle":
			return [fpose({"head": V(5, -71)}), fpose({"top": V(2, -62), "head": V(5, -72)}),
				fpose({"hip": V(0, -36), "top": V(2, -60), "head": V(5, -70)}), fpose({"hip": V(0, -36), "top": V(2, -61), "head": V(5, -71)})]
		"jab":
			return [fpose({"hip": V(0, -36), "top": V(1, -61), "head": V(4, -71), "sf": V(3, -58), "sb": V(-1, -59), "gkf": "up"}),
				fpose({"hip": V(1, -37), "top": V(5, -61), "head": V(7, -70), "sf": V(6.5, -60), "sb": V(2, -59), "shoeb": "ball", "tw": 1.2, "gkf": "side"}),
				fpose({"hip": V(1, -37), "top": V(3, -61), "head": V(5, -71), "sf": V(4, -58.5), "sb": V(1, -59), "shoeb": "ball", "tw": 0.4, "pf": V(-0.6, 1.0), "gkf": "side"}),
				fpose({"top": V(3, -61), "head": V(5, -71), "sf": V(5, -58), "sb": V(0, -59)})]
		"heavy":
			return [fpose({"hip": V(-1, -36), "top": V(-2, -60), "head": V(1, -70)}),
				fpose({"hip": V(1, -37), "top": V(4, -61), "head": V(7, -71), "tw": 1.0, "shoeb": "ball"}),
				fpose({"hip": V(3, -37), "top": V(8, -60), "head": V(11, -70), "tw": 2.0, "shoeb": "ball", "sb": V(12, -59), "sf": V(7, -57), "gkb": "side"}),
				fpose({"hip": V(3, -37), "top": V(7, -60), "head": V(10, -70), "tw": 1.6, "shoeb": "ball", "sb": V(10, -59), "sf": V(6, -57), "gkb": "side"}),
				fpose({"hip": V(1, -37), "top": V(3, -61), "head": V(6, -71), "tw": 0.4})]
		"hit":
			return [fpose({"hip": V(-1, -37), "top": V(-3, -60), "head": V(-2, -69), "face": "pain"}),
				fpose({"hip": V(-2, -36), "top": V(-3, -60), "head": V(0, -70), "face": "pain"}),
				fpose({"hip": V(0, -37), "top": V(1, -61), "head": V(4, -71)})]
		"dodge":
			return [fpose({"hip": V(-1, -36), "top": V(-3, -59)}), fpose({"hip": V(-3, -33), "top": V(-8, -55)}),
				fpose({"hip": V(-3, -34), "top": V(-7, -56)}), fpose({"hip": V(-1, -36), "top": V(0, -60)})]
		"block":
			return [fpose({"head": V(5, -70), "far_glove_front": true}),
				fpose({"hip": V(-2, -37), "top": V(0, -61), "head": V(3, -70), "far_glove_front": true}),
				fpose({"hip": V(-1, -37), "top": V(1, -61), "head": V(4, -70), "far_glove_front": true})]
		"tired":
			return [fpose({"hip": V(0, -36), "top": V(3, -59), "head": V(7, -68), "face": "tired"}),
				fpose({"hip": V(0, -35), "top": V(3, -58), "head": V(7, -67), "face": "tired"}),
				fpose({"hip": V(0, -35), "top": V(3, -58), "head": V(7, -66), "face": "tired"}),
				fpose({"hip": V(0, -36), "top": V(3, -59), "head": V(7, -67), "face": "tired"})]
		"victory":
			var up := {"top": V(1, -61), "head": V(7, -72), "sf": V(5, -59), "sb": V(0, -61), "face": "joy", "pf": V(-1, 0.1), "pb": V(-1, 0.1)}
			var f1 := up.duplicate()
			f1.merge({"hip": V(0, -39), "top": V(1, -63), "head": V(7, -74), "sf": V(5, -61), "sb": V(0, -63), "shoef": "ball", "shoeb": "ball"}, true)
			var f3 := up.duplicate()
			f3.merge({"head": V(7, -71)}, true)
			return [fpose(up), fpose(f1), fpose(up), fpose(f3)]
		"ko":
			var dn := V(-0.64, -0.77)
			return [fpose({"hip": V(-1, -36), "top": V(-2, -60), "face": "ko", "toef": V(14, -1), "pf": V(-1, 0.3), "pb": V(-1, 0.3)}),
				fpose({"hip": V(-2, -28), "top": V(-3, -52), "face": "ko", "shoeb": "ball", "kf": V(1, 0), "kb": V(1, 0.1), "pf": V(-1, 0.3), "pb": V(-1, 0.3)}),
				fpose({"hip": V(-8, -17), "top": V(-8, -17) + dn * 24.0, "face": "ko", "hrot_auto": true,
					"toef": V(17, -1), "toeb": V(8, -1), "shoeb": "ball", "kf": V(0.4, -1), "kb": V(0.4, -1), "pf": V(0, -1), "pb": V(0, -1)}),
				fpose({"hip": V(0, -7), "top": V(-24, -7), "head": V(-34, -8), "hrot": -90.0, "face": "ko",
					"toef": V(30, -1), "toeb": V(36, -1), "kf": V(0, -1), "kb": V(0, -1), "pf": V(0, -1), "pb": V(0, -1)}),
				fpose({"hip": V(0, -6), "top": V(-24, -6), "head": V(-34, -7), "hrot": -90.0, "face": "ko",
					"toef": V(32, -1), "toeb": V(37, -12), "shoeb": "up", "kf": V(0, -1), "kb": V(0, -1), "pf": V(0, -1), "pb": V(0, -1)})]
	return []

## Ajustes de personalidade por quadro (espaço do jogador, antes da escala).
func personality(oid: String, action: String, i: int) -> Dictionary:
	match oid:
		"opp_fast":
			if action == "idle":   # saltita: sobe na ponta dos dois pés, aterrissa dobrando os joelhos
				return [{"head": V(5, -71)}, {"hip": V(0, -38), "top": V(2, -62), "head": V(5, -72), "shoef": "ball"},
					{"hip": V(0, -35), "top": V(2, -59), "head": V(5, -69)}, {"hip": V(0, -36), "top": V(2, -60), "head": V(5, -70)}][i]
			if action == "tired" and i in [1, 2]:
				return {"shoef": "ball"}
		"opp_warmup":
			if action == "idle" and i >= 2:   # entre um golpe e outro, solta o braço de trás e "alonga o ombro"
				return {"sb": V(-1, -61 + i - 2), "pb": V(-1, 0.2)}
		"opp_tank":
			if action == "idle":              # respira pela barriga, quase parado
				return [{}, {}, {"hip": V(0, -36), "top": V(2, -60), "head": V(5, -70)}, {"hip": V(0, -37), "top": V(2, -61), "head": V(5, -71)}][i]
		"opp_gym_1":
			if action == "idle":              # balança o peso de um pé para o outro, devagar (base de tatame)
				return [{}, {"hip": V(-1, -37), "top": V(1, -61), "head": V(4, -71)},
					{"hip": V(0, -36), "top": V(2, -60), "head": V(5, -70)}, {"hip": V(1, -37), "top": V(3, -61), "head": V(6, -71)}][i]
			if action == "victory":           # braços grossos subiriam na frente do rosto: ele joga o queixo para a frente
				return [{"head": V(15, -71)}, {"head": V(15, -73)}, {"head": V(15, -71)}, {"head": V(15, -70)}][i]   # e grita (rosto visível)
		"opp_gym_2":
			if action == "idle":              # quica curto na ponta do pé de trás, ombro da frente sobe (queixo escondido)
				return [{}, {"hip": V(0, -38), "top": V(2, -62), "head": V(5, -72), "sf": V(4, -60)},
					{"hip": V(0, -36), "top": V(2, -60), "head": V(5, -70)}, {"hip": V(0, -37), "top": V(2, -61), "head": V(5, -71), "sf": V(4, -59)}][i]
	return {}

## Transforma uma pose do jogador para o adversário (escala + personalidade). Devolve a pose virada à direita.
func opp_pose(oid: String, action: String, i: int, base: Dictionary) -> Dictionary:
	var d := opp_def(oid)
	var s: float = d.s
	var p: Dictionary = base.duplicate()
	p.merge(personality(oid, action, i), true)
	var lying: bool = bool(base.get("lying", false)) or (action == "ko" and i >= 2)
	var hip: Vector2 = p.hip
	var top: Vector2 = p.top
	var dn := (top - hip).normalized()
	var fr := Vector2(-dn.y, dn.x)
	var sf: Vector2 = p.get("sf", top + fr * 2.0 - dn * 3.0)
	var sb: Vector2 = p.get("sb", top - fr * 2.0 - dn * 2.0)
	var head: Vector2 = p.get("head", top + fr * 3.0 + dn * 10.0)
	var toef: Vector2 = p.toef
	var toeb: Vector2 = p.toeb
	if not lying:
		var ln := Vector2(float(d.lean), 0.0)
		var cr := Vector2(0.0, 0.0 if action == "victory" else float(d.get("crouch", 0.0)))   # base mais baixa (Tonhão; na vitória ele se levanta); 0 nos anteriores
		hip += cr
		top += ln + cr
		sf += ln + cr
		sb += ln + cr
		head += ln + cr + (d.head_d as Vector2)
		toef.x += float(d.stance[0])
		toeb.x += float(d.stance[1])
		if d.toes and not p.has("shoeb"):
			p["shoeb"] = "ball"
	var q := p
	q["hip"] = hip * s
	q["top"] = top * s
	var ts: Vector2 = q.top
	q["sf"] = ts + (sf * s - ts) * float(d.shk)
	q["sb"] = ts + (sb * s - ts) * float(d.shk)
	if not p.get("hrot_auto", false):
		q["head"] = ts + (head * s - ts) * float(d.neck_k)
	q["toef"] = Vector2(toef.x * s, toef.y if toef.y > -2.0 else toef.y * s)
	q["toeb"] = Vector2(toeb.x * s, toeb.y if toeb.y > -2.0 else toeb.y * s)
	return q

# ================================================================ adereços (ganchos da lib)
## Brutão: mangas do macacão amarradas na frente da cintura, pendendo sobre a coxa.
func hook_sleeves(lib, O: Vector2, ctx: Dictionary) -> void:
	var hip: Vector2 = ctx.hip
	var top: Vector2 = ctx.top
	var dn: Vector2 = ctx.dn
	var fr: Vector2 = ctx.fr
	var ln := (top - hip).length()
	var knot := hip + dn * (ln * 0.27) + fr * 5.2
	var ramp := ["b0", "b1", "b2"]
	var down := -dn
	lib.limb(56, knot, knot + down * 7.0 + fr * 1.2, 1.5, 1.2, ramp)
	lib.limb(57, knot + fr * 0.5, knot + down * 4.5 + fr * 2.2, 1.4, 1.1, ["b0", "b1", "b1"])
	lib.limb(58, knot - dn * 0.3, knot + fr * 0.6, 1.8, 1.6, ramp)
	lib.joint(56, 58, knot, 2.5)
	lib.joint(57, 58, knot, 2.5)

## Tonhão: nó da faixa roxa na frente da cintura e as duas pontas caindo sobre a coxa da frente, a de cima com a
## barra preta de graduação na ponta. Desenhado depois da perna da frente (a faixa fica por cima da calça).
func hook_belt(lib, O: Vector2, ctx: Dictionary) -> void:
	var hip: Vector2 = ctx.hip
	var top: Vector2 = ctx.top
	var dn: Vector2 = ctx.dn
	var fr: Vector2 = ctx.fr
	var ln := (top - hip).length()
	var b: Dictionary = ctx.get("b", {})
	var t := 0.255
	var front: float = lib._interp_slices(b.sl_side_eff, t).y if not b.is_empty() else 6.0
	var knot := hip + dn * (ln * t) + fr * (front - 0.8)
	var down := -dn
	var ramp := ["p0", "p1", "p1"]
	var e1 := knot + down * 7.0 + fr * 1.6
	var e2 := knot + down * 5.5 + fr * 0.2
	lib.limb(56, knot, e2, 1.3, 1.1, ["p0", "p0", "p1"])
	lib.limb(57, knot, e1, 1.3, 1.2, ramp)
	lib.limb(57, knot + (e1 - knot) * 0.72, e1, 1.25, 1.2, ["d1", "d1", "d2"])   # barra preta da faixa
	lib.limb(58, knot - dn * 0.2, knot + fr * 0.4, 1.7, 1.6, ["p0", "p1", "p2"])   # nó
	lib.joint(56, 58, knot, 2.6)
	lib.joint(57, 58, knot, 2.6)

# ================================================================ geração da LUTA
func spr(id: String) -> Dictionary:
	return M.sprites[id]

func v2(a) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))

func mir(v: Vector2) -> Vector2:
	return Vector2(-v.x, v.y)

func gen_fight(oid: String, b: Dictionary, action: String) -> Array:
	var id := oid + "_" + action
	var e := spr(id)
	var hands: Array = e.hands
	var poses := player_poses(action)
	var piv := v2(e.pivot)
	var fs := Vector2i(int(e.frame_size[0]), int(e.frame_size[1]))
	var gpiv := Vector2(fs.x - 1 - piv.x, piv.y)   # pivô do desenho virado à direita (espelho exato)
	if poses.size() != int(e.frames) or hands.size() != int(e.frames):
		report.append("DIVERGÊNCIA %s: %d poses, %d mãos, manifest %d quadros" % [id, poses.size(), hands.size(), int(e.frames)])
	var frames := []
	for i in poses.size():
		var p := opp_pose(oid, action, i, poses[i])
		p["hf"] = mir(v2(hands[i].hand_front))
		p["hb"] = mir(v2(hands[i].hand_back))
		if oid == "opp_strong":
			p["after_near_leg"] = hook_sleeves
		elif oid == "opp_gym_1":
			p["after_near_leg"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
				ctx["b"] = b
				hook_belt(lib, O, ctx)
		var im: Image = P.fight_frame(b, p, "%s[%d]" % [id, i], fs, gpiv)
		var hfp: Vector2 = gpiv + p.hf
		var idf: int = P.ids[int(hfp.y) * fs.x + int(hfp.x)]
		if idf != P.NEAR_GLOVE:
			report.append("AVISO %s[%d]: mão da frente %s não cai na luva (id %d)" % [id, i, str(p.hf), idf])
		_check_bounds(im, id, i)
		im.flip_x()
		frames.append(im)
	if e.has("hit_point"):
		var hf: int = int(e.hit_frame)
		var hp := v2(e.hit_point)
		if hp.distance_to(v2(hands[hf].hand_front)) > 0.5 and hp.distance_to(v2(hands[hf].hand_back)) > 0.5:
			report.append("AVISO %s: hit_point %s não coincide com nenhuma mão do quadro %d" % [id, str(hp), hf])
	return frames

func _check_bounds(im: Image, id: String, i: int) -> void:
	for x in im.get_width():
		if im.get_pixel(x, 0).a > 0.0:
			report.append("AVISO %s[%d]: encosta na borda de cima (x %d)" % [id, i, x])
			return
	for y in im.get_height():
		if im.get_pixel(0, y).a > 0.0 or im.get_pixel(im.get_width() - 1, y).a > 0.0:
			report.append("AVISO %s[%d]: encosta na borda lateral (y %d)" % [id, i, y])
			return

func make_portrait(oid: String, b: Dictionary) -> Image:
	var s: float = opp_def(oid).s
	var p := opp_pose(oid, "idle", 0, player_poses("idle")[0])
	p["hf"] = V(16, -55) * s
	p["hb"] = V(12, -53) * s
	var fr: Image = P.fight_frame(b, p, "retrato " + oid)
	var hc := V(56, 98) + (p.head as Vector2)
	var crop: Image = fr.get_region(Rect2i(int(hc.x) - 15, int(hc.y) - 13, 32, 32))
	var bg: Image = L.blank(32, 32)
	var cb: Array = PORTRAIT_BG[oid]
	L.R(bg, 0, 0, 32, 32, "d1")
	L.dither(bg, 0, 18, 32, 6, cb[0])
	L.R(bg, 0, 24, 32, 8, cb[0])
	L.dither(bg, 0, 28, 32, 4, cb[1], 1)
	bg.blend_rect(crop, Rect2i(0, 0, 32, 32), Vector2i.ZERO)
	return bg

# ================================================================ AJUDANTES da garagem (3/4)
func helper_build(hid: String) -> Dictionary:
	var chinelo := {"34": {"rows": CHINELO_34, "toe": Vector2i(8, 4), "ankle": Vector2i(3, 0), "ang": 0.0},
		"34ball": {"rows": CHINELO_34_BALL, "toe": Vector2i(8, 5), "ankle": Vector2i(2, 0), "ang": 0.0}}
	var thin := {"g_arm_r": [2.3, 1.8, 2.0, 1.5], "g_leg_r": [3.3, 2.4, 2.3, 1.4]}
	var o := {}
	match hid:
		"neighbor_1":   # vizinho da casa 12: boxe de sombra de chinelo, regata verde
			o = {"head_34": H34_N1, "hair": ["ink", "d2"], "brow": "ink", "skin": ["sk0", "sk1", "sk2"],
				"top": "tank", "shirt": ["gr0", "gr1", "gr2"], "shorts": ["d1", "d2", "g0"], "band": "g0",
				"shoes": ["sk0", "sk1", "sk2", "b2", "b1"], "shoe_maps": chinelo, "glove": "fist", "shoulder": 0.95, "hip_w": 0.92}
			o.merge(thin)
		"neighbor_2":   # polichinelo, topete, regata azul
			o = {"head_34": H34_N2, "head_anchor_34": Vector2i(6, 8), "hair": ["br1", "br2"], "brow": "br1", "skin": ["sk1", "sk2", "y2"],
				"top": "tank", "shirt": ["b1", "b2", "b3"], "shorts": ["st0", "st1", "st2"], "band": "st2",
				"shoes": ["sk1", "sk2", "y2", "r2", "r1"], "shoe_maps": chinelo, "glove": "fist", "shoulder": 0.9, "hip_w": 0.9}
			o.merge(thin)
		"neighbor_3":   # saltita na guarda, boné para trás, camiseta
			o = {"head_34": H34_N3, "head_anchor_34": Vector2i(7, 6), "cap": ["gr0", "gr1", "gr2"], "hair": ["ink", "d2"], "brow": "ink",
				"skin": ["br0", "sk0", "sk1"], "top": "tshirt", "shirt": ["r0", "r1", "r2"], "sleeve_t": 0.42,
				"shorts": ["d2", "g0", "g1"], "band": "g1", "shoes": ["br0", "sk0", "sk1", "y1", "y0"], "shoe_maps": chinelo,
				"glove": "fist", "shoulder": 0.95, "hip_w": 0.92}
			o.merge(thin)
		"uncle_1":      # tio aposentado: camisa social de manga comprida, calça de tergal, luva velha marrom
			o = {"head_34": H34_UNCLE, "hair": ["g2", "g3"], "brow": "g2", "mustache": "g3", "skin": ["sk0", "sk1", "sk2"],
				"top": "tshirt", "shirt": ["g3", "cream", "white"], "sleeve_long": true, "shirt_detail": "social",
				"bottom": "pants", "shorts": ["d2", "g0", "g1"], "band": "br0", "shoes": ["br0", "br1", "br2", "br2", "d1"],
				"glove": "worn", "glove_ramp": ["br1", "br2", "br3"], "belly": 3.0, "shoulder": 1.0, "hip_w": 1.05}
		"uncle_2":      # tio aposentado: camisa social azul de manga curta, agachamento com as luvas à frente
			o = {"head_34": H34_UNCLE, "hair": ["g1", "g2"], "brow": "g1", "mustache": "g2", "skin": ["br0", "sk0", "sk1"],
				"top": "tshirt", "shirt": ["b2", "b3", "white"], "sleeve_t": 0.55, "shirt_detail": "social",
				"bottom": "pants", "shorts": ["st0", "st1", "st2"], "band": "d1", "shoes": ["d1", "d2", "g0", "g1", "ink"],
				"glove": "worn", "glove_ramp": ["br1", "br2", "br3"], "belly": 4.0, "shoulder": 1.05, "hip_w": 1.1}
		"coach_1":      # Prof. Nelson: agasalho verde do clube, apito, prancheta
			o = {"head_34": H34_COACH, "hair": ["g1", "g2"], "brow": "g1", "mustache": "g2", "skin": ["sk0", "sk1", "sk2"],
				"top": "tshirt", "shirt": ["gr0", "gr1", "gr2"], "sleeve_long": true, "shirt_detail": "zip",
				"bottom": "pants", "shorts": ["gr0", "gr1", "gr2"], "band": "gr2", "shoes": ["d2", "g1", "g3", "white", "cream"],
				"glove": "fist", "belly": 2.0, "shoulder": 1.0, "hip_w": 1.0}
	var b: Dictionary = P.build(o)
	b["faces_34"] = transfer_faces(P.HEAD_34, P.FACES_34, b.head_34)
	return b

func gpose(o := {}) -> Dictionary:
	var p := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47),
		"hl": V(-8, -50), "hr": V(10, -51), "el": V(-9, -40), "er": V(10, -40), "toel": V(-1, 0), "toer": V(10, 0)}
	for k in o:
		p[k] = o[k]
	return p

## Desloca o corpo inteiro (pulo/agachamento). feet = os pés vão junto (pulo) ou ficam (agachamento).
func shifted(p: Dictionary, dy: float, feet: bool) -> Dictionary:
	var q := p.duplicate()
	for k in ["hip", "top", "head", "sl", "sr", "hl", "hr", "el", "er"]:
		if q.has(k):
			q[k] = (q[k] as Vector2) + V(0, dy)
	if feet:
		for k in ["toel", "toer"]:
			q[k] = (q[k] as Vector2) + V(0, dy)
	return q

func helper_poses(hid: String) -> Array:
	match hid:
		"neighbor_1":   # boxe de sombra: guarda, jab, guarda (respira), direto cruzado
			var g := gpose({"hl": V(-7, -51), "hr": V(10, -52), "el": V(-9, -41), "er": V(10, -41)})
			return [g,
				gpose({"hip": V(1, -31), "top": V(2, -50), "head": V(2, -56), "sl": V(-6, -47), "sr": V(10, -48), "face": "effort",
					"hl": V(-7, -51), "hr": V(21, -50), "el": V(-8, -41), "er": V(13, -48.5), "shoel": "34ball", "tw": 1.0, "gkr": "side"}),
				shifted(g, 1.0, false),
				gpose({"hip": V(1, -31), "top": V(2, -50), "head": V(3, -56), "sl": V(-4, -47), "sr": V(9, -47), "face": "effort", "tw": 1.5,
					"hl": V(15, -50), "el": V(3, -46), "hr": V(9, -53), "er": V(10, -42), "shoel": "34ball", "gkl": "side"})]
		"neighbor_2":   # polichinelo: braços embaixo/pés juntos -> braços abertos/pés afastados -> braços em cima
			var f0 := gpose({"head": V(1, -56), "hl": V(-10, -33), "hr": V(11, -33), "el": V(-10, -40), "er": V(11, -40), "toel": V(1, 0), "toer": V(8, 0), "gkl": "down", "gkr": "down"})
			var open := {"head": V(1, -56), "hl": V(-17, -51), "hr": V(18, -51), "el": V(-13, -49), "er": V(14, -49), "toel": V(-4, 0), "toer": V(13, 0),
				"shoel": "34ball", "shoer": "34ball", "gkl": "up", "gkr": "up", "kl": V(-0.3, 0), "kr": V(0.6, 0)}
			var f1 := shifted(gpose(open), -1.0, true)
			var upd := open.duplicate()
			upd.merge({"hl": V(-10, -61), "hr": V(11, -61), "el": V(-10, -54), "er": V(11, -54)}, true)
			var f2 := shifted(gpose(upd), -1.0, true)
			return [f0, f1, f2, f1.duplicate()]
		"neighbor_3":   # saltita na guarda
			var g := gpose({"hl": V(-7, -51), "hr": V(10, -52), "el": V(-9, -41), "er": V(10, -41)})
			var up := shifted(g, -1.0, true)
			up["shoel"] = "34ball"
			up["shoer"] = "34ball"
			var low := shifted(g, 1.0, false)
			low["hr"] = V(12, -53)
			low["er"] = V(11, -42)
			return [g, up, g.duplicate(), low]
		"uncle_1":      # guarda lenta e baixa; no 3º quadro solta um jab devagar
			var g := gpose({"hl": V(-7, -47), "hr": V(9, -48), "el": V(-9, -38), "er": V(10, -38), "toel": V(-2, 0), "toer": V(10, 0)})
			var d1 := shifted(g, 1.0, false)
			var jab := d1.duplicate()
			jab.merge({"hr": V(17, -48), "er": V(12, -45), "sr": V(9, -46), "gkr": "side", "tw": 0.6}, true)
			return [g, d1, jab, g.duplicate()]
		"uncle_2":      # agachamento lento com as luvas para a frente
			var g := gpose({"hl": V(5, -45), "hr": V(14, -46), "el": V(-7, -39), "er": V(11, -40), "toel": V(-3, 0), "toer": V(11, 0),
				"gkl": "side", "gkr": "side", "kl": V(1, 0), "kr": V(1, 0)})
			return [g, shifted(g, 2.0, false), shifted(g, 4.0, false), shifted(g, 2.0, false)]
		"coach_1":      # 0 parado, 1 confere o relógio, 2 apita, 3 parado
			var g := gpose({"hl": V(-2, -38), "el": V(-9, -40), "hr": V(11, -34), "er": V(10, -41), "gkl": "up", "gkr": "down",
				"toel": V(-2, 0), "toer": V(9, 0)})
			var watch := g.duplicate()
			watch.merge({"hr": V(4, -45), "er": V(11, -40), "gkr": "side"}, true)
			var whistle := g.duplicate()
			whistle.merge({"hr": V(5, -52), "er": V(10, -44), "gkr": "up"}, true)
			return [g, watch, whistle, shifted(g, 1.0, false)]
	return []

## Prancheta (na mão esquerda da tela, por baixo dos dedos) e apito (no peito ou na boca).
func coach_hooks(p: Dictionary, frame: int) -> void:
	p["after_torso"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var top: Vector2 = ctx.top
		# cordão do apito + apito no peito (no quadro 2 ele está na boca)
		lib.put(int(top.x) - 2, int(top.y) + 1, "y1", 31)
		lib.put(int(top.x) - 1, int(top.y) + 2, "y1", 31)
		lib.put(int(top.x) + 2, int(top.y) + 1, "y1", 31)
		lib.put(int(top.x) + 1, int(top.y) + 2, "y1", 31)
		if frame != 2:
			lib.put(int(top.x), int(top.y) + 3, "st3", 31)
			lib.put(int(top.x) + 1, int(top.y) + 3, "st2", 31)
		var h: Vector2 = ctx.hl
		var bx := int(h.x) - 1
		var by := int(h.y) - 7
		for yy in 10:
			for xx in 8:
				var c = "br2"
				if xx >= 1 and xx <= 6 and yy >= 1 and yy <= 8:
					c = "white" if not (yy in [3, 5, 7] and xx >= 2 and xx <= 5) else "g2"
				if xx == 0 or yy == 9:
					c = "br1"
				lib.put(bx + xx, by + yy, c, 35)
		lib.put(bx + 3, by - 1, "st2", 35)
		lib.put(bx + 4, by - 1, "st3", 35)
	p["end"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hd: Vector2 = ctx.hd
		var hr: Vector2 = ctx.hr
		if frame == 1:   # relógio no pulso
			var w: Vector2 = hr + (ctx.elr - hr).normalized() * 3.0
			lib.put(int(round(w.x)), int(round(w.y)), "st3", 72)
			lib.put(int(round(w.x)), int(round(w.y)) - 1, "ink", 72)
		if frame == 2:   # apito na boca
			lib.put(int(hd.x) + 3, int(hd.y) + 4, "st3", 73)
			lib.put(int(hd.x) + 4, int(hd.y) + 4, "st2", 73)

func gen_helper(hid: String) -> Array:
	var e := spr(hid)
	var piv := v2(e.pivot)
	var fs := Vector2i(int(e.frame_size[0]), int(e.frame_size[1]))
	var left: bool = e.get("facing", "direita") == "esquerda"
	var gpiv := Vector2(fs.x - 1 - piv.x, piv.y) if left else piv
	var pos := v2(e.pos)
	var b := helper_build(hid)
	var poses := helper_poses(hid)
	if poses.size() != int(e.frames):
		report.append("DIVERGÊNCIA %s: %d poses, manifest %d quadros" % [hid, poses.size(), int(e.frames)])
	var frames := []
	for i in poses.size():
		var p: Dictionary = poses[i]
		if hid == "coach_1":
			coach_hooks(p, i)
		var im: Image = P.garage_frame(b, p, "%s[%d]" % [hid, i], fs, gpiv)
		_check_bounds(im, hid, i)
		if left:
			im.flip_x()
		# luz da lâmpada já aplicada para o ponto fixo da sala (igual aos ajudantes antigos)
		var tl := pos - piv
		L.light(im, Rect2i(0, 0, im.get_width(), im.get_height()), LIGHT_C - tl, 300.0, 1.1, 3.6, -1, 1, 0.9)
		frames.append(im)
	return frames

# ================================================================ saída
func save_sheet(path: String, id: String, frames: Array) -> void:
	var e := spr(id)
	var s: Image = P.strip(frames)
	var want := Vector2i(int(e.frame_size[0]) * int(e.frames), int(e.frame_size[1]))
	if s.get_size() != want or frames.size() != int(e.frames):
		report.append("DIVERGÊNCIA %s: folha %s, manifest pede %s (%d quadros)" % [id, str(s.get_size()), str(want), int(e.frames)])
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	s.save_png(path)

func res_to_rel(res: String) -> String:
	return res.trim_prefix("res://assets/sprites/")

# ================================================================ folha de contato
func checker(dst: Image, x: int, y: int, w: int, h: int, cell: int) -> void:
	for yy in range(0, h, cell):
		for xx in range(0, w, cell):
			var c = "g1" if ((xx / cell + yy / cell) % 2 == 0) else "g0"
			L.R(dst, x + xx, y + yy, mini(cell, w - xx), mini(cell, h - yy), c)

func put_frames(out: Image, frames: Array, cr: Rect2i, x: int, y: int, S: int, gap: int, labels := []) -> int:
	for i in frames.size():
		checker(out, x, y, cr.size.x * S, cr.size.y * S, 12)
		P.paste(out, P.scaled((frames[i] as Image).get_region(cr), S), x, y)
		if labels.size() > i:
			L.text(out, labels[i], x + 3, y + 3, "white", 1, "ink")
		x += cr.size.x * S + gap
	return x

func contact_sheet(newf: Dictionary, portraits: Dictionary, player_idle: Image) -> void:
	var S := 3
	var crf := Rect2i(4, 0, 104, 104)
	var crg := Rect2i(0, 0, 48, 72)
	var key := {"idle": 0, "jab": 1, "heavy": 2, "hit": 0, "dodge": 1, "block": 1, "tired": 1, "victory": 1, "ko": 4}
	var W := 140 + 9 * (crf.size.x * S + 8)
	var H := 80 + 330 + 4 * (34 + 2 * (crf.size.y * S + 10) + 2 * (crf.size.y + 6) + 30) + 50 + 6 * (crg.size.y * S + 30) + 60 + 140
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "ELENCO - ADVERSARIOS E AJUDANTES, ANTES x DEPOIS (3x; tiras completas em 1x)", 14, 12, "y1", 2, "ink")
	L.text(out, "Gerado por tools/art/make_sprites_elenco.gd + personagem_lib.gd. Mesmos quadros, fps, pivo, hit_frame/hit_point, maos e posicoes do manifest.", 14, 38, "g3", 1, "ink")
	var y := 60
	# escalação lado a lado (mesmo jogo?): jogador + 4 adversários no quadro 0 do idle
	L.text(out, "ESCALACAO (quadro 0 da guarda, mesma escala do jogo): jogador 1,00 - Dinho 0,92 - Dudu 0,98 - Bruto 1,08 - Muralha 1,12", 14, y, "cream", 1, "ink")
	y += 16
	L.R(out, 14, y, W - 28, 104 * S + 6, "d2")
	var x := 20
	P.paste(out, P.scaled(player_idle.get_region(crf), S), x, y + 3)
	x += crf.size.x * S - 40
	for oid in ["opp_fast", "opp_warmup", "opp_strong", "opp_tank"]:
		P.paste(out, P.scaled((newf[oid + "_idle"][0] as Image).get_region(crf), S), x, y + 3)
		x += crf.size.x * S - 40
	# retratos
	var px := x + 30
	L.text(out, "RETRATOS 32x32 (antes / depois)", px, y + 6, "cream", 1, "ink")
	var ry := y + 24
	for oid in OPPS:
		var old: Image = P.load_png(old_dir + "opponents/portrait_" + oid + ".png")
		P.paste(out, P.scaled(old, S), px, ry)
		P.paste(out, P.scaled(portraits[oid], S), px + 32 * S + 6, ry)
		P.paste(out, old, px + 2 * (32 * S + 6), ry)
		P.paste(out, portraits[oid], px + 2 * (32 * S + 6) + 36, ry)
		ry += 32 * S + 6
		if ry > y + 104 * S - 90:
			ry = y + 24
			px += 2 * (32 * S + 6) + 90
	y += 104 * S + 24
	# adversários: quadro-chave de cada ação, antes x depois, e as tiras completas novas em 1x
	var names := {"opp_warmup": "DUDU ALONGADO (opp_warmup)", "opp_strong": "BRUTAO DO POSTO (opp_strong)", "opp_fast": "DINHO PULGA (opp_fast)", "opp_tank": "SEU MURALHA (opp_tank)"}
	for oid in OPPS:
		L.text(out, names[oid], 14, y, "cream", 2, "ink")
		L.text(out, "quadro-chave de cada acao (idle0 jab1 heavy2 hit0 dodge1 block1 tired1 victory1 ko4)", 14 + L.text_w(names[oid], 2) + 12, y + 4, "g2", 1, "ink")
		y += 26
		for row in 2:
			var fr := []
			var lab := []
			for a in ACTIONS:
				var k: int = key[a]
				if row == 0:
					fr.append(P.frames_of(old_dir + "opponents/%s/%s_%s.png" % [oid, oid, a], FW)[k])
				else:
					fr.append(newf[oid + "_" + a][k])
				lab.append("%s %d" % [a, k])
			L.text(out, "ANTES" if row == 0 else "DEPOIS", 14, y + crf.size.y * S / 2 - 6, "r3" if row == 0 else "gr3", 2, "ink")
			put_frames(out, fr, crf, 120, y, S, 8, lab)
			y += crf.size.y * S + 10
		# tiras completas em 1x (todas as ações)
		var xx := 120
		var line := 0
		for a in ACTIONS:
			var fr: Array = newf[oid + "_" + a]
			var need: int = fr.size() * (crf.size.x + 2) + 8
			if xx + need > W - 10:
				xx = 120
				line += 1
			for im in fr:
				L.R(out, xx, y + line * (crf.size.y + 6), crf.size.x, crf.size.y, "g1")
				P.paste(out, (im as Image).get_region(crf), xx, y + line * (crf.size.y + 6))
				xx += crf.size.x + 2
			xx += 8
		L.text(out, "1x", 14, y + 10, "g2", 2, "ink")
		y += 2 * (crf.size.y + 6) + 30
	# ajudantes
	L.text(out, "AJUDANTES DA GARAGEM (3x, luz da lampada ja aplicada no ponto da sala)", 14, y, "y1", 2, "ink")
	y += 30
	for hid in HELPERS:
		var e := spr(hid)
		L.text(out, hid, 14, y + 4, "cream", 2, "ink")
		L.text(out, "%d quadros, %s fps" % [int(e.frames), str(e.fps)], 14, y + 26, "g2", 1, "ink")
		var oldf: Array = P.frames_of(old_dir + res_to_rel(e.file), 48)
		L.text(out, "ANTES", 120, y - 10 + 8, "r3", 1, "ink")
		var x2: int = put_frames(out, oldf, crg, 160, y, S, 6)
		L.text(out, "DEPOIS", x2 + 14, y - 2, "gr3", 1, "ink")
		x2 = put_frames(out, newf[hid], crg, x2 + 60, y, S, 6)
		for im in newf[hid]:
			L.R(out, x2 + 10, y, 48, 72, "g1")
			P.paste(out, im, x2 + 10, y)
			x2 += 50
		y += crg.size.y * S + 30
	out.crop(W, mini(H, y + 20))
	out.save_png(MOCK)

# ================================================================ academia (Fase 5): folha de contato e ciclo na arena
const GYM_NAMES := {"opp_gym_1": "TONHAO DO TATAME (opp_gym_1) - resistente, escala 1,04", "opp_gym_2": "KID NAVALHA (opp_gym_2) - rapido, escala 1,08"}

func gym_contact_sheet(newf: Dictionary, portraits: Dictionary, player_idle: Image) -> void:
	var S := 3
	var crf := Rect2i(4, 0, 104, 104)
	var cell := crf.size.x * S + 6
	var W := 120 + 5 * cell + 20
	var H := 9000
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "ACADEMIA - ADVERSARIOS NOVOS (3x e 1x). Mesmo quadro 112x104, pivo (56,98), hit_frame/hit_point e maos do manifest.", 14, 12, "y1", 1, "ink")
	L.text(out, "Gerado por tools/art/make_sprites_elenco.gd (modo gym) + personagem_lib.gd.", 14, 26, "g3", 1, "ink")
	var y := 46
	# escalação no quadro 0 da guarda, 3x: jogador, os 4 da garagem e os 2 da academia (silhuetas lado a lado)
	L.text(out, "ESCALACAO (quadro 0 da guarda, 3x, mesma escala do jogo): jogador - Dinho - Dudu - Bruto - Muralha | TONHAO - KID", 14, y, "cream", 1, "ink")
	y += 14
	var lineup := [player_idle]
	for oid in ["opp_fast", "opp_warmup", "opp_strong", "opp_tank"]:
		lineup.append(P.frames_of(ROOT + "assets/sprites/opponents/%s/%s_idle.png" % [oid, oid], FW)[0])
	for oid in OPPS_GYM:
		lineup.append(newf[oid + "_idle"][0])
	var step := 70 * 2
	L.R(out, 14, y, W - 28, 104 * 2 + 6, "d2")
	var x := 10
	for i in lineup.size():
		if i == 5:
			L.R(out, x + 60, y + 4, 2, 104 * 2 - 2, "p1")
			x += 30
		P.paste(out, P.scaled((lineup[i] as Image).get_region(crf), 2), x, y + 3)
		x += step
	y += 104 * 2 + 20
	for oid in OPPS_GYM:
		L.text(out, GYM_NAMES[oid], 14, y, "cream", 2, "ink")
		y += 24
		# retratos 32x32 (3x e 1x)
		P.paste(out, P.scaled(portraits[oid], S), 14, y)
		P.paste(out, portraits[oid], 14 + 32 * S + 8, y)
		L.text(out, "retrato 32x32 (3x / 1x)", 14 + 32 * S + 48, y + 4, "g2", 1, "ink")
		y += 32 * S + 10
		for a in ACTIONS:
			var fr: Array = newf[oid + "_" + a]
			var e := spr(oid + "_" + a)
			var lab := []
			for i in fr.size():
				var l := "%s %d" % [a, i]
				if e.has("hit_frame") and int(e.hit_frame) == i:
					l += " CONTATO"
				lab.append(l)
			L.text(out, a, 14, y + 8, "cream", 2, "ink")
			L.text(out, "%d q, %s fps" % [fr.size(), str(e.fps)], 14, y + 30, "g2", 1, "ink")
			put_frames(out, fr, crf, 120, y, S, 6, lab)
			# marca do hit_point (sobre o quadro de contato), para conferir que cai na luva
			if e.has("hit_point"):
				var hp := v2(e.hit_point) + v2(e.pivot) - Vector2(crf.position)
				var hx := 120 + int(e.hit_frame) * cell + int(hp.x) * S
				var hy := y + int(hp.y) * S
				L.R(out, hx - 1, hy + 1, 3, 1, "gr3")
				L.R(out, hx + 1, hy - 1, 1, 3, "gr3")
			y += crf.size.y * S + 8
		# tiras 1x de todas as ações
		L.text(out, "1x", 14, y + 10, "g2", 2, "ink")
		var xx := 120
		var line := 0
		for a in ACTIONS:
			var fr: Array = newf[oid + "_" + a]
			var need: int = fr.size() * (crf.size.x + 2) + 8
			if xx + need > W - 10:
				xx = 120
				line += 1
			for im in fr:
				L.R(out, xx, y + line * (crf.size.y + 6), crf.size.x, crf.size.y, "g1")
				P.paste(out, (im as Image).get_region(crf), xx, y + line * (crf.size.y + 6))
				xx += crf.size.x + 2
			xx += 8
		y += (line + 1) * (crf.size.y + 6) + 24
	out.crop(W, y + 10)
	out.save_png(MOCK_GYM)

## Cena da luta (arena real, 640x360) com o jogador e o adversário nas posições do manifest. Devolve a imagem 1x.
func arena_scene(bg: Image, pl: Image, op: Image) -> Image:
	var sc: Image = bg.duplicate()
	var bp := spr("fight_player_idle")
	var ppos := v2(M.by_data_id.player_fight.pos)
	P.paste(sc, pl, int(ppos.x - float(bp.pivot[0])), int(ppos.y - float(bp.pivot[1])))
	P.paste(sc, op, int(346 - 56), int(318 - 98))
	return sc

func gym_arena(newf: Dictionary, seq_dir: String) -> void:
	var bg: Image = P.load_png(ROOT + "assets/sprites/fight/arena_bg.png")
	var crowd: Image = P.load_png(ROOT + "assets/sprites/fight/arena_crowd_front.png") if FileAccess.file_exists(ROOT + "assets/sprites/fight/arena_crowd_front.png") else null
	var pf := {}
	for a in ["idle", "block", "hit", "victory"]:
		pf[a] = P.frames_of(ROOT + "assets/sprites/fight/fight_player_%s.png" % a, FW)
	var crop := Rect2i(200, 150, 240, 180)
	var S := 2
	# quadros-chave lado a lado: guarda, contato do jab (jogador defende), contato do forte, K.O. no chão
	var keys := [["idle", 0, "idle", 0, "guarda"], ["jab", 1, "block", 1, "jab: contato"], ["heavy", 2, "hit", 0, "forte: contato"],
		["ko", 4, "victory", 1, "K.O."]]
	var W := 14 + keys.size() * (crop.size.x * S + 10)
	var H := 40 + OPPS_GYM.size() * (crop.size.y * S + 34)
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "ACADEMIA - ADVERSARIOS NA ARENA (2x, fundo e posicoes reais da luta)", 14, 12, "y1", 2, "ink")
	var y := 40
	for oid in OPPS_GYM:
		L.text(out, GYM_NAMES[oid], 14, y, "cream", 1, "ink")
		var x := 14
		for k in keys:
			var sc := arena_scene(bg, pf[k[2]][k[3]], newf[oid + "_" + k[0]][k[1]])
			P.paste(out, P.scaled(sc.get_region(crop), S), x, y + 14)
			L.text(out, k[4], x + 4, y + 18, "white", 1, "ink")
			x += crop.size.x * S + 10
		y += crop.size.y * S + 34
	out.save_png(MOCK_GYM_ARENA)
	# sequência do ciclo (para GIF): guarda x2, jab, guarda, forte, apanha, esquiva, defesa, cansado, K.O.
	DirAccess.make_dir_recursive_absolute(seq_dir)
	for oid in OPPS_GYM:
		var n := 0
		var order := ["idle", "idle", "jab", "idle", "heavy", "hit", "dodge", "block", "tired", "victory", "ko"]
		for a in order:
			var fr: Array = newf[oid + "_" + a]
			for i in fr.size():
				var reps := 1
				if a == "ko" and i == fr.size() - 1:
					reps = 6
				for r in reps:
					var sc := arena_scene(bg, pf["idle"][n % 4 if a in ["idle", "tired", "victory"] else 0], fr[i])
					var im: Image = P.scaled(sc.get_region(crop), 3)
					im.save_png(seq_dir + "/%s_%03d.png" % [oid, n])
					n += 1

func run_gym() -> void:
	var newf := {}
	var portraits := {}
	for oid in OPPS_GYM:
		var b := make_opp_build(oid)
		for a in ACTIONS:
			var id: String = oid + "_" + a
			if not M.sprites.has(id):
				report.append("FALTA no manifest: %s (rode o script do manifest antes)" % id)
				continue
			var fr := gen_fight(oid, b, a)
			save_sheet(out_dir + res_to_rel(spr(id).file), id, fr)
			newf[id] = fr
		portraits[oid] = make_portrait(oid, b)
		portraits[oid].save_png(out_dir + "opponents/portrait_%s.png" % oid)
	var pl: Image = P.frames_of(ROOT + "assets/sprites/fight/fight_player_idle.png", FW)[0]
	gym_contact_sheet(newf, portraits, pl)
	gym_arena(newf, out_dir + "seq")

# ================================================================ REAÇÕES de quem apanha (poses em tools/art/golpes.json)
## Modo "reacoes": gera hit_head / hit_up / hit_body de cada adversário a partir das poses do jogador (as MESMAS de
## make_golpes_jogador.gd, já expandidas em reacoes_expandidas.json), espelhadas e na escala de cada corpo (opp_pose).
## Uso: ... make_sprites_elenco.gd -- <saida> <antigos> reacoes <reacoes_expandidas.json>
## Escreve <saida>/opponents/... e reacoes_adv_manifest.json (entradas e ações para o manifest.json).
func vet(a: Variant) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func pose_da_reacao(q: Dictionary) -> Dictionary:
	var p := fpose()
	for k in q:
		var v: Variant = q[k]
		p[k] = vet(v) if (v is Array and (v as Array).size() == 2) else v
	return p


func gen_reacao(oid: String, b: Dictionary, nome: String, rea: Dictionary, base: Dictionary) -> Array:
	var s: float = opp_def(oid).s
	var piv := v2(base.pivot)
	var fs := Vector2i(int(base.frame_size[0]), int(base.frame_size[1]))
	var gpiv := Vector2(fs.x - 1 - piv.x, piv.y)
	var frames := []
	var i := 0
	for q in rea.frames:
		var p := opp_pose(oid, nome, i, pose_da_reacao(q))
		# A pose é desenhada virada à DIREITA (e o quadro é espelhado no fim): as mãos entram sem espelhar. (Espelhar aqui jogava
		# as luvas para o lado das costas em todas as reações dos adversários.)
		p["hf"] = vet(q.get("hf", [14, -58])) * s
		p["hb"] = vet(q.get("hb", [5, -61])) * s
		if oid == "opp_strong":
			p["after_near_leg"] = hook_sleeves
		elif oid == "opp_gym_1":
			p["after_near_leg"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
				ctx["b"] = b
				hook_belt(lib, O, ctx)
		var im: Image = P.fight_frame(b, p, "%s_%s[%d]" % [oid, nome, i], fs, gpiv)
		_check_bounds(im, oid + "_" + nome, i)
		im.flip_x()
		frames.append(im)
		i += 1
	return frames


func run_reacoes(caminho: String) -> void:
	var rea: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	var entradas := {}
	var acoes := {}
	for oid in OPPS + OPPS_GYM:
		var b := make_opp_build(oid)
		var base := spr(oid + "_hit")
		var s: float = opp_def(oid).s
		for nome in rea:
			var fr := gen_reacao(oid, b, nome, rea[nome], base)
			var arquivo: String = str(base.file).replace("_hit.png", "_%s.png" % nome)
			var strip: Image = P.strip(fr)
			DirAccess.make_dir_recursive_absolute((out_dir + res_to_rel(arquivo)).get_base_dir())
			strip.save_png(out_dir + res_to_rel(arquivo))
			var maos := []
			for q in rea[nome].frames:
				var hf: Vector2 = mir(vet(q.get("hf", [14, -58])) * s)
				var hb: Vector2 = mir(vet(q.get("hb", [5, -61])) * s)
				maos.append({"hand_front": [hf.x, hf.y], "hand_back": [hb.x, hb.y]})
			var e: Dictionary = (base as Dictionary).duplicate(true)
			e["file"] = arquivo
			e["frames"] = fr.size()
			e["fps"] = float(rea[nome].fps)
			e["loop"] = false
			e["action"] = nome
			e["hands"] = maos
			e.erase("hit_frame")
			e.erase("hit_point")
			if rea[nome].has("ground_frame"):
				e["ground_frame"] = rea[nome].ground_frame
			entradas[oid + "_" + nome] = e
			if not acoes.has(oid):
				acoes[oid] = {}
			acoes[oid][nome] = oid + "_" + nome
	var f := FileAccess.open(out_dir + "reacoes_adv_manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"sprites": entradas, "actions": acoes}, "\t"))
	f.close()
	print("ok: %d folhas de reação" % entradas.size())


# ================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0].trim_suffix("/") + "/"
	old_dir = args[1].trim_suffix("/") + "/"
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	M = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if args.size() > 3 and args[2] == "reacoes":
		run_reacoes(args[3])
		_write_report()
		quit()
		return
	if args.size() > 2 and args[2] == "gym":
		run_gym()
		_write_report()
		quit()
		return
	var newf := {}
	var portraits := {}
	for oid in OPPS:
		var b := make_opp_build(oid)
		for a in ACTIONS:
			var id: String = oid + "_" + a
			var fr := gen_fight(oid, b, a)
			save_sheet(out_dir + res_to_rel(spr(id).file), id, fr)
			newf[id] = fr
		portraits[oid] = make_portrait(oid, b)
		portraits[oid].save_png(out_dir + res_to_rel(spr("portrait_" + oid).file))
	for hid in HELPERS:
		var fr := gen_helper(hid)
		save_sheet(out_dir + res_to_rel(spr(hid).file), hid, fr)
		newf[hid] = fr
	var pl: Image = P.frames_of(ROOT + "assets/sprites/fight/fight_player_idle.png", FW)[0]
	contact_sheet(newf, portraits, pl)
	_write_report()
	print("ok: %d folhas + %d retratos" % [newf.size(), portraits.size()])
	quit()

func _write_report() -> void:
	var f := FileAccess.open(out_dir + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		f.store_line(l)
	f.store_line("---- conferência")
	for l in report:
		f.store_line(l)
	f.close()
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	for l in report:
		print(l)
