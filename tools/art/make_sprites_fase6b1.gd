extends SceneTree
## Fase 6b1 — Passar o posto. Artista de Personagens (skill padrao-personagem).
## Gera:
##  (1) as 9 folhas novas do John (sem camadas, luva velha / mãos nuas), 48x72, pivô (22,67), virado à direita;
##  (2) as 4 folhas novas do discípulo EM CAMADAS (body / head_short / front, cores-chave para troca de paleta);
##  (3) docs/arte/manifest-6b1-personagens.json: entradas do John, do discípulo (novas + camadas de TODAS as poses que
##      já existiam, lidas de <camadas>/disciple/camadas_*.json) e a paleta-base com as rampas das 5 peles, 6 cabelos e
##      6 calções (by_data_id.disciple_palette);
##  (4) mockups em <saida>/mock/ (folhas de contato, peles x cabelos/calções, John sentado na sala, antes/depois).
## As camadas das poses antigas do discípulo saem dos geradores de sempre com FC_LUTADOR=disc FC_CAMADAS=1:
##   make_sprites_jogador.gd e make_golpes_jogador.gd (gravam <saida>/disciple/ e camadas_jogador/golpes.json).
## Rodar headless de uma pasta temporária com project.godot vazio (nunca no projeto):
##   godot --headless --path <tmp> --script <repo>/tools/art/make_sprites_fase6b1.gd -- <saida> <camadas>
##   <saida>   = onde gravar characters/, disciple/, mock/ e manifest-6b1-personagens.json
##   <camadas> = pasta onde os dois geradores acima gravaram disciple/ (pode ser a mesma <saida>)

var ROOT := OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else "E:/Fightclicker/"
const GPIV := Vector2(22, 67)
const P_JOHN := Vector2(303, 272)
const P_MENTOR := Vector2(254, 252)      # mentor_spot final (Diretor de Arte, 6b1); a prancha usava (268,268)
const P_DOOR := Vector2(423, 221)
const P_COACH := Vector2(196, 236)
const OLD := {"style": "old", "ramp": ["r0", "r1", "r2"]}

## Paletas finais (docs/arte/paletas-6b1.md). deep = tom abaixo da sombra (pele de trás, sombra de contato);
## é o br0 na pele padrão, e o tom 1 passo abaixo do escuro na rampa do calção (ink nos escuros, como o John).
const PALETTE := {
	"skin": [
		{"id": "skin_1", "colors": ["#a8684e", "#e0a888", "#f4d0b4"], "deep": "#6e3e2e"},
		{"id": "skin_2", "colors": ["#8f5238", "#cc8c62", "#eebd94"], "deep": "#5a3022"},
		{"id": "skin_3", "colors": ["#7a4632", "#b9744f", "#e3a275"], "deep": "#3b2622"},
		{"id": "skin_4", "colors": ["#5a3029", "#8c5545", "#b8806a"], "deep": "#3a1d1a"},
		{"id": "skin_5", "colors": ["#422529", "#73453f", "#a06a5a"], "deep": "#2a1519"},
	],
	"hair_color": [
		{"id": "black", "colors": ["#2a2233", "#4a4552", "#14101a"]},
		{"id": "dark_brown", "colors": ["#3b2622", "#6b3f2a", "#14101a"]},
		{"id": "brown", "colors": ["#6b3f2a", "#9a5f36", "#3b2622"]},
		{"id": "copper", "colors": ["#9a5f36", "#c98a4b", "#3b2622"]},
		{"id": "blond", "colors": ["#e0a040", "#f5d26b", "#3b2622"]},
		{"id": "platinum", "colors": ["#b8b0aa", "#d9cdb4", "#6b6570"]},
	],
	"shorts_color": [
		{"id": "green", "colors": ["#1f3d33", "#2f6b4a", "#5aa25a", "#a6d86a"], "deep": "#14101a"},
		{"id": "blue", "colors": ["#1f2a44", "#2f4a78", "#4d7bb3", "#8fbbe0"], "deep": "#14101a"},
		{"id": "black", "colors": ["#2a2233", "#3d3346", "#4a4552", "#8f8890"], "deep": "#14101a"},
		{"id": "white", "colors": ["#8f8890", "#b8b0aa", "#d9cdb4", "#f2ece0"], "deep": "#6b6570"},
		{"id": "purple", "colors": ["#4a2f6b", "#7a4fa0", "#b07ad8", "#d9cdb4"], "deep": "#14101a"},
		{"id": "yellow", "colors": ["#9a5f36", "#e0a040", "#f5d26b", "#fff3c4"], "deep": "#6b3f2a"},
	],
}

var L
var P
var M: Dictionary
var out_dir := ""
var cam_dir := ""
var report: Array = []
var sprites := {}
var cam_store := {}
var john_frames := {}
var disc_caps := {}

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)

# ================================================================ poses (3/4, virado à direita)
## Pose-base da garagem (a mesma de make_sprites_jogador.gd). Chave com null = tirar. Mexeu na mão sem dizer o
## cotovelo = o IK acha (braço com comprimento constante); mexeu na mão sem dizer a orientação = automática.
func G(o := {}) -> Dictionary:
	var p := {"hip": V(0, -31), "top": V(1, -50), "head": V(1, -57), "sl": V(-7, -47), "sr": V(8, -47),
		"hl": V(-8, -50), "hr": V(10, -51), "el": V(-9, -40), "er": V(10, -40), "toel": V(-1, 0), "toer": V(10, 0)}
	if o.has("hl") and not o.has("el"):
		p.erase("el")
	if o.has("hr") and not o.has("er"):
		p.erase("er")
	if o.has("hl") and not o.has("gkl"):
		p["gkl"] = ""
	if o.has("hr") and not o.has("gkr"):
		p["gkr"] = ""
	# mão nua sem lado dito: o cotovelo dobra para a frente (braço solto), nunca para fora (virava "mão na cintura")
	if o.get("stl", "") in ["open", "fist"] and not o.has("pl"):
		p["pl"] = V(0.6, 0.3)
	if o.get("str", "") in ["open", "fist"] and not o.has("pr"):
		p["pr"] = V(0.6, 0.3)
	for k in o:
		if o[k] == null:
			p.erase(k)
		else:
			p[k] = o[k]
	return p

## Corpo inteiro sobe/desce dy (respiração, ponta do pé).
func up(o: Dictionary, dy: int, keys := ["hip", "top", "head", "sl", "sr"]) -> Dictionary:
	for k in keys:
		if o.has(k):
			o[k] = (o[k] as Vector2) + V(0, dy)
	return o

func hooks(list: Array) -> Callable:
	return func(lib, O: Vector2, ctx: Dictionary) -> void:
		for h in list:
			(h as Callable).call(lib, O, ctx)

## Par de luvas pendurado pelo cadarço na mão direita da tela (ou num ponto rel ao pivô).
func pair_hook(off := V(0, 0), at = null) -> Callable:
	return func(lib, O: Vector2, ctx: Dictionary) -> void:
		var hand: Vector2 = (O + (at as Vector2)) if at != null else (ctx.hr as Vector2)
		hand += off
		var bb: Dictionary = lib.build_ref
		var g1 := hand + V(-2, 9)
		var g2 := hand + V(3, 10)
		lib.lace(74, hand + V(0, 1), g2 + V(0, -5))
		lib.loose_glove(74, bb, "down", g2, false, true, "old")
		lib.lace(75, hand + V(0, 1), g1 + V(0, -5))
		lib.loose_glove(75, bb, "down", g1, false, false, "old")

## Uma luva solta num ponto rel ao pivô (orientação, espelho, profundidade).
func glove_at(rel: Vector2, kind: String, flip: bool, id := 35, far := false) -> Callable:
	return func(lib, O: Vector2, ctx: Dictionary) -> void:
		lib.loose_glove(id, lib.build_ref, kind, O + rel, flip, far, "old")

## Luva segura pelo punho na mão direita (a mão fica por cima: usar no gancho after_left).
func glove_in_hand(off: Vector2, kind: String, flip := false) -> Callable:
	return func(lib, O: Vector2, ctx: Dictionary) -> void:
		lib.loose_glove(69, lib.build_ref, kind, (ctx.hr as Vector2) + off, flip, false, "old")

func with_strap(p: Dictionary, b: Dictionary, n: int) -> Dictionary:
	var mo: Vector2 = P.mouth_offset(b, "34")
	var prev = p.get("end", null)
	p["end"] = func(lib, O: Vector2, ctx: Dictionary) -> void:
		if prev != null:
			(prev as Callable).call(lib, O, ctx)
		var tooth := ((ctx.hd as Vector2) + mo + V(2, 0)).round()
		var cuff := ((ctx.hr as Vector2) + V(-4, 4)).round()
		lib.strap_tip(b, tooth, cuff, n)
	return p

# ---------------------------------------------------------------- John
## Mãos nuas soltas ao lado do corpo (mão aberta, dedos para baixo).
const BARE_L := Vector2(-8, -27)
const BARE_R := Vector2(11, -27)

func john_poses(id: String) -> Array:
	match id:
		"john_hold_bag":   # 0 = quadro 2 do fighter_punch; 1 a outra luva sobe; 2 as duas no saco, cabeça 2 px abaixo
			var f0 := G({"hip": V(2, -30), "top": V(4, -49), "head": V(5, -55), "sl": V(-4, -47), "sr": V(11, -48), "face": "effort",
				"hl": V(-5, -49), "hr": V(20, -50), "el": V(-7, -39.5), "fs": 0.56, "pr": V(0.2, 1), "shoel": "34ball", "tw": 1.2,
				"gkr": "side", "kl": V(1, 0), "kr": V(1, 0)})
			f0.erase("er")
			var f1 := G({"hip": V(2, -30), "top": V(4, -49), "head": V(5, -55), "sl": V(-3, -47), "sr": V(11, -48), "face": "effort",
				"hl": V(9, -44), "pl": V(-0.3, 1), "hr": V(20, -50), "fs": 0.6, "pr": V(0.2, 1), "shoel": "34ball", "tw": 1.4,
				"gkr": "side", "kl": V(1, 0), "kr": V(1, 0)})
			var f2 := G({"hip": V(2, -30), "top": V(4, -48), "head": V(5, -53), "sl": V(-3, -46), "sr": V(11, -47),
				"hl": V(16, -42), "pl": V(-0.2, 1), "gkl": "side", "hr": V(20, -51), "fs": 0.62, "pr": V(0.2, 1), "tw": 1.4,
				"gkr": "side", "kl": V(1, 0), "kr": V(1, 0)})
			return [f0, f1, f2]
		"john_gloves_off":
			var q := []
			q.append(G({"hl": V(-6, -42), "hr": V(9, -44)}))                                                # 0 solta o saco, guarda baixa
			q.append({"strap": 2, "p": G({"head": V(2, -56), "face": "bite", "hr": V(12, -57), "pr": V(1.0, 0.7), "gkr": "up"})})  # 1 morde
			q.append({"strap": 3, "p": G({"head": V(1, -56), "face": "bite", "top": V(1, -49), "hr": V(13, -55), "pr": V(1.0, 0.9), "gkr": "up"})})  # 2 puxa
			# 3 luva direita presa debaixo do braço esquerdo; a mão sai nua
			q.append(G({"hl": V(-2, -37), "el": V(-8, -38), "gkl": "side", "hr": V(13, -44), "pr": V(1, 0.6), "str": "open",
				"after_torso": glove_at(V(-3, -42), "side", true)}))
			# 4 a mão nua abre o fecho da luva esquerda (na frente do peito); a outra luva continua presa
			q.append(G({"hl": V(2, -44), "el": V(-6, -38), "gkl": "up", "hr": V(6, -39), "pr": V(1, 0.8), "str": "fist", "gkr": "side",
				"after_torso": glove_at(V(-4, -42), "side", true)}))
			# 5 a 2ª luva sai: a mão direita puxa a luva pelo punho; a esquerda sai nua
			q.append(G({"hl": V(1, -42), "el": V(-6, -38), "stl": "open", "gkl": "up", "hr": V(12, -42), "pr": V(1, 0.8), "str": "fist", "gkr": "side",
				"after_torso": glove_at(V(-4, -42), "side", true), "after_left": glove_in_hand(V(5, 1), "side")}))
			# 6 as duas luvas pelo cadarço na mão da frente
			q.append(G({"hl": V(-8, -31), "stl": "open", "hr": V(11, -38), "pr": V(1, 0.8), "str": "fist", "after_left": pair_hook()}))
			# 7 amarra os cadarços: mãos juntas na altura do peito
			q.append(G({"hl": V(4, -42), "stl": "fist", "gkl": "side", "hr": V(8, -43), "pr": V(1, 0.8), "str": "fist", "gkr": "side",
				"after_left": pair_hook(V(-2, 0))}))
			return q
		"john_hang_gloves":
			return [
				G({"hl": BARE_L, "stl": "open", "hr": V(12, -35), "str": "fist", "after_left": pair_hook()}),                     # 0 baixa o par
				up(G({"hl": V(-10, -30), "stl": "open", "hr": V(15, -55), "pr": V(1, 0.4), "str": "fist", "gkr": "up",
					"shoel": "34ball", "shoer": "34ball", "head": V(2, -57), "after_left": pair_hook(V(-3, 1))}), -1),          # 1 balança para cima
				up(G({"hl": V(-10, -30), "stl": "open", "hr": V(19, -62), "pr": V(1, 0.3), "str": "open", "gkr": "up",
					"shoel": "34ball", "shoer": "34ball", "head": V(2, -57)}), -1),                                             # 2 SOLTA
				G({"hl": BARE_L, "stl": "open", "hr": V(14, -46), "pr": V(1, 0.7), "str": "open"}),                              # 3 braço desce
				G({"hl": BARE_L, "stl": "open", "hr": BARE_R, "str": "open"}),                                                    # 4 mãos nuas
				G({"hl": BARE_L, "stl": "open", "hr": V(9, -45), "pr": V(1, 0.6), "str": "open", "gkr": "up", "head": V(2, -56)}), # 5 olha a mão aberta
				G({"hl": BARE_L, "stl": "open", "hr": V(9, -45), "pr": V(1, 0.6), "str": "fist", "gkr": "up", "head": V(2, -56)}), # 6 fecha o punho
				G({"hl": BARE_L, "stl": "open", "hr": V(10, -40), "pr": V(1, 0.7), "str": "open", "gkr": "diag", "head": V(2, -56)}), # 7 abre e relaxa
			]
		"john_look_door":
			return [
				G({"hl": BARE_L, "stl": "open", "hr": V(10, -40), "pr": V(1, 0.7), "str": "open", "gkr": "diag", "head": V(2, -56)}),
				G({"hl": BARE_L, "stl": "open", "hr": V(11, -31), "str": "open", "head": V(1, -57)}),
				G({"hl": BARE_L, "stl": "open", "hr": BARE_R, "str": "open", "head": V(0, -58), "top": V(0, -50)}),
				G({"hl": BARE_L, "stl": "open", "hr": BARE_R, "str": "open", "head": V(0, -58), "top": V(0, -50), "face": "smile"}),
			]
		"john_step_back":   # passo de boxeador para trás (o corpo anda para a esquerda virado para a direita)
			var hands := {"hl": V(-3, -40), "stl": "fist", "gkl": "up", "hr": V(12, -42), "str": "fist", "gkr": "up", "pr": V(0.3, 1), "pl": V(-0.3, 1), "face": "smile"}
			var a := G(hands.merged({"toel": V(1, 0), "toer": V(9, 0)}))
			var b2 := G(hands.merged({"toel": V(-9, 0), "toer": V(12, 0), "shoer": "34ball", "hip": V(-1, -29.5), "top": V(0, -48.5),
				"head": V(0, -56), "sl": V(-8, -46), "sr": V(7, -46), "hl": V(-4, -39), "hr": V(11, -41), "kl": V(-0.3, 0), "kr": V(1, 0)}))
			var c := G(hands.merged({"toel": V(-5, 0), "toer": V(5, -2), "shoer": "34ball", "hip": V(-1, -30), "top": V(0, -50),
				"head": V(0, -57), "sl": V(-8, -47), "sr": V(7, -47), "hl": V(-4, -40), "hr": V(11, -42)}))
			var d := G(hands.merged({"toel": V(-1, 0), "toer": V(8, 0), "hip": V(0, -30), "top": V(1, -49), "head": V(1, -56),
				"sl": V(-7, -46), "sr": V(8, -46), "hl": V(-3, -39), "hr": V(12, -41)}))
			return [a, b2, c, d]
		"john_point_spot":
			return [
				G({"hl": BARE_L, "stl": "open", "hr": V(13, -33), "pr": V(1, 0.8), "str": "open"}),
				G({"hl": BARE_L, "stl": "open", "hr": V(14, -44), "pr": V(1, 0.6), "str": "open", "gkr": "up", "head": V(2, -57)}),
				G({"hl": BARE_L, "stl": "open", "hr": V(20, -36), "pr": V(0.2, 1), "str": "open", "gkr": "diagdown", "head": V(2, -57), "face": "smile"}),
			]
		"john_sit_down":
			var sit: Array = john_poses("john_sit_rest")
			return [
				G({"hl": BARE_L, "stl": "open", "hr": V(12, -31), "str": "open", "head": V(2, -57), "face": "smile"}),
				G({"hip": V(-3, -27), "top": V(0, -45), "head": V(2, -52), "sl": V(-7, -42), "sr": V(7, -42), "toel": V(0, 0), "toer": V(9, 0),
					"kl": V(1, -0.2), "kr": V(1, -0.2), "hl": V(-4, -26), "stl": "open", "hr": V(10, -26), "str": "open", "face": "smile"}),
				G({"hip": V(-5, -23), "top": V(-1, -41), "head": V(2, -48), "sl": V(-8, -38), "sr": V(6, -38), "toel": V(0, 0), "toer": V(9, 0),
					"kl": V(1, -0.2), "kr": V(1, -0.2), "hl": V(0, -22), "stl": "open", "hr": V(9, -23), "str": "open", "face": "smile"}),
				sit[0],
			]
		"john_sit_rest", "mentor_first_taps":
			var out := []
			var dys := [0, -1, -1, 0] if id == "john_sit_rest" else [0, 0, 0, 0]
			for i in 4:
				var o := {"hip": V(-6, -22), "top": V(-2, -40), "head": V(1, -47), "sl": V(-9, -37), "sr": V(5, -37),
					"hl": V(1, -21), "hr": V(9, -21), "toel": V(0, 0), "toer": V(9, 0), "kl": V(1, -0.2), "kr": V(1, -0.2),
					"stl": "open", "str": "open", "pl": V(0.2, 1), "pr": V(0.4, 1), "face": "smile"}
				if id == "mentor_first_taps":
					var hr: Array = [V(10, -33), V(7, -30), V(9, -32), V(7, -30)]
					o.merge({"hl": V(3, -29), "stl": "fist", "gkl": "side", "hr": hr[i], "str": "fist", "gkr": "side", "pr": V(0.3, 1)}, true)
				var g := G(o)
				up(g, dys[i], ["top", "head", "sl", "sr"])
				out.append(g)
			return out
	return []

const JOHN := {
	"john_hold_bag": {"fps": 10, "loop": false, "pos": "P_JOHN", "action": "hold_bag", "catch_frame": 2,
		"note": "Com luvas. 0 = braço do soco ainda esticado (= quadro 2 do fighter_punch); 1 = a outra luva sobe para o saco; 2 = as duas luvas no saco, cabeça 2 px mais baixa (segurar). catch_frame 2 = som bag_catch."},
	"john_gloves_off": {"fps": 4, "loop": false, "pos": "P_JOHN", "action": "gloves_off", "bite_frame": 1,
		"note": "O avesso do gesto, cada quadro é uma pose segurada 0,25 s. 0 solta o saco, guarda baixa; 1 luva da frente na boca, rosto bite (= quadro 1 do fighter_gesture); 2 puxa o fecho, cabeça recua 1 px, fita esticada; 3 prende a luva debaixo do braço esquerdo e tira a mão: 1ª mão nua; 4 a mão nua abre o fecho da outra luva; 5 a 2ª luva sai; 6 as duas luvas pelo cadarço na mão da frente; 7 amarra os cadarços, mãos juntas no peito."},
	"john_hang_gloves": {"fps": 8, "loop": false, "pos": "P_JOHN", "action": "hang_gloves", "release_frame": 2,
		"note": "Arremesso curto do par pelo cadarço (a argola em (335,186) fica fora do alcance: a mão chega no máximo a ~(322,210) na ponta dos pés). 0 baixa o par; 1 balança o braço para cima, calcanhares sobem; 2 SOLTA (o par vira o adereço garage_hung_gloves_old, quadro 0, a ~4 px da mão); 3 braço desce; 4 mãos nuas ao lado do corpo; 5 olha a mão aberta; 6 fecha o punho; 7 abre e relaxa."},
	"john_look_door": {"fps": 10, "loop": false, "pos": "P_JOHN", "action": "look_door",
		"note": "Sem luvas, braços soltos. 0 olhando a mão (= quadro 7 do hang_gloves); 1 cabeça vira para a porta; 2 olhando a porta, queixo um pouco erguido (quadro parado atrás da tela de criação); 3 = 2 com o rosto smile."},
	"john_step_back": {"fps": 8, "loop": true, "pos": "P_JOHN", "action": "step_back", "step_frames": [1, 3],
		"note": "Passo de boxeador para trás, sem luvas, punhos soltos na altura da cintura, rosto smile. Virado para a DIREITA enquanto anda para a esquerda (não espelhar). 1 = pé de trás pousa atrás; 3 = pé da frente pousa."},
	"john_point_spot": {"fps": 10, "loop": false, "pos": "P_MENTOR", "action": "point_spot",
		"note": "0 braço da frente começa a subir; 1 antecipação; 2 mão aberta apontando o chão em frente ao saco, rosto smile (segurar enquanto fala)."},
	"john_sit_down": {"fps": 10, "loop": false, "pos": "P_MENTOR", "action": "sit_down",
		"note": "0 baixa o braço; 1 dobra os joelhos; 2 quadril encosta no caixote; 3 sentado (= quadro 0 do john_sit_rest). O caixote (garage_crate) é adereço, desenhado atrás."},
	"john_sit_rest": {"fps": 3, "loop": true, "pos": "P_MENTOR", "action": "sit_rest",
		"note": "A pose parada do mentor: sentado no caixote (assento a 17 px do chão), antebraços nos joelhos, mãos nuas, olhando o saco, smile leve. Respiração de 1 px nos ombros (quadros 1-2)."},
	"mentor_first_taps": {"fps": 9, "loop": false, "pos": "P_MENTOR", "action": "mentor_first_taps", "tap_frames": [1, 3],
		"note": "Sentado, sem luvas: os dois toques de punho. 0 punho de trás recua; 1 1º TOQUE; 2 separa 2 px; 3 2º TOQUE. Mesmos tempos do fighter_gesture_short (2 quadros a 9 fps = 0,22 s). Depois volta ao quadro 0 do john_sit_rest. Só o John usa esta folha."},
}

# ---------------------------------------------------------------- Discípulo (cenas)
## Braço solto: cotovelo levemente para trás (nunca para fora: virava "mão na cintura" e o antebraço cruzava o corpo).
const ELB := Vector2(-0.6, 0.3)
const ARM_REACH := 19.8   # de 20,5 px do braço: quase esticado

## Mão de um braço solto girando no ombro: graus > 0 = para a frente (para onde ele olha).
func arm(sh: Vector2, deg: float) -> Vector2:
	var r := deg_to_rad(deg)
	return sh + Vector2(sin(r), cos(r)) * ARM_REACH

## "al"/"ar" (ângulo do braço esquerdo/direito da tela) viram mãos abertas no arco do ombro.
func bare_arms(o: Dictionary) -> Dictionary:
	var p := o.duplicate()
	if p.has("al"):
		p["hl"] = arm(p.sl, float(p.al))
		p.erase("al")
		if not p.has("pl"):
			p["pl"] = ELB
	if p.has("ar"):
		p["hr"] = arm(p.sr, float(p.ar))
		p.erase("ar")
		if not p.has("pr"):
			p["pr"] = ELB
	if not p.has("stl"):
		p["stl"] = "open"
	if not p.has("str"):
		p["str"] = "open"
	return G(p)

## Folhas que a cena usa andando para a ESQUERDA: ganham versão própria "<id>_left" (sem espelho no jogo).
const LEFT_IDS := ["disciple_stand_bare", "disciple_duck_under", "disciple_walk_bare"]

func disc_poses(id: String) -> Array:
	match id:
		"disciple_stand_bare":
			var out := []
			for dy in [0, -1, -1, 0]:
				var sl := V(-7, -47 + dy)
				var sr := V(8, -47 + dy)
				out.append(up(G({"sl": sl, "sr": sr, "hl": arm(sl, 3), "stl": "open", "hr": arm(sr, 5), "str": "open", "pl": ELB, "pr": ELB,
					"head": V(1, -57)}), dy, ["top", "head"]))
			return out
		"disciple_duck_under":   # virado à direita; a versão _left (que a cena usa) sai destas mesmas poses, desenhada para a esquerda
			var q := [
				{"hip": V(0, -27), "top": V(2, -46), "head": V(3, -53), "sl": V(-5, -43), "sr": V(9, -43), "toel": V(-3, 0), "toer": V(9, 0),
					"kl": V(1, 0), "kr": V(1, 0), "al": 8.0, "ar": 10.0},
				{"hip": V(0, -24), "top": V(5, -41), "head": V(8, -47), "sl": V(-1, -39), "sr": V(11, -38), "toel": V(-4, 0), "toer": V(8, 0),
					"kl": V(1, 0), "kr": V(1, 0), "hl": V(-10, -50), "pl": V(-1, 0.2), "stl": "fist", "gkl": "up", "ar": 2.0},
				{"hip": V(0, -23), "top": V(6, -39), "head": V(10, -44), "sl": V(0, -37), "sr": V(12, -36), "toel": V(-5, 0), "toer": V(7, 0),
					"kl": V(1, 0), "kr": V(1, 0), "hl": V(-11, -52), "pl": V(-1, 0.2), "stl": "fist", "gkl": "up", "ar": 0.0},
				{"hip": V(1, -25), "top": V(4, -42), "head": V(8, -47), "sl": V(-2, -40), "sr": V(10, -39), "toel": V(-7, 0), "toer": V(12, 0),
					"kl": V(1, 0), "kr": V(1, 0), "hl": V(-13, -55), "pl": V(-1, 0.2), "stl": "fist", "gkl": "up", "ar": 4.0},
				{"hip": V(2, -27), "top": V(4, -45), "head": V(6, -52), "sl": V(-2, -42), "sr": V(10, -42), "toel": V(-9, 0), "toer": V(10, 0),
					"shoel": "34ball", "kl": V(1, 0), "kr": V(1, 0), "al": -22.0, "ar": 14.0},
				{"hip": V(1, -30), "top": V(2, -49), "head": V(3, -56), "sl": V(-5, -46), "sr": V(9, -46), "toel": V(-5, -2), "toer": V(9, 0),
					"shoel": "34ball", "al": -8.0, "ar": 9.0},
				{"hip": V(0, -31), "top": V(2, -50), "head": V(2, -57), "sl": V(-6, -47), "sr": V(9, -47), "toel": V(-2, 0), "toer": V(7, 0),
					"al": 2.0, "ar": 4.0},
			]
			return q.map(func(o): return bare_arms(o))
		"disciple_walk_bare":   # 6 quadros, passada de 14 px; A = perna direita da tela (toer, a de longe), B = esquerda (toel, a de perto)
			# braço oposto à perna: A na frente (1) -> braço de perto (hl) na frente e o de longe (hr) atrás; B na frente (4) -> o contrário.
			# braço quase esticado (19,8 de 20,5 px), cotovelo para trás, girando no ombro como pêndulo (+ = para a frente).
			var hi := {"hip": V(0, -31), "top": V(2, -50), "head": V(2, -57), "sl": V(-6, -47), "sr": V(9, -47)}
			var lo := {"hip": V(0, -29.5), "top": V(2, -48.5), "head": V(2, -55.5), "sl": V(-6, -45.5), "sr": V(9, -45.5)}
			var md := {"hip": V(0, -30), "top": V(2, -49), "head": V(2, -56), "sl": V(-6, -46), "sr": V(9, -46)}
			var rows := [
				[hi, {"toer": V(4, -2), "toel": V(-3, 0), "al": 2.0, "ar": 4.0}],
				[lo, {"toer": V(7, 0), "toel": V(-7, 0), "shoel": "34ball", "al": 12.0, "ar": -2.0}],
				[md, {"toer": V(2, 0), "toel": V(-8, -1), "shoel": "34ball", "al": 7.0, "ar": 1.0}],
				[hi, {"toel": V(1, -2), "toer": V(1, 0), "al": 2.0, "ar": 4.0}],
				[lo, {"toel": V(7, 0), "toer": V(-2, 0), "shoer": "34ball", "al": -14.0, "ar": 16.0}],
				[md, {"toel": V(2, 0), "toer": V(-3, -1), "shoer": "34ball", "al": -8.0, "ar": 11.0}],
			]
			var out := []
			for r in rows:
				var o: Dictionary = {"kl": V(1, -0.1), "kr": V(1, -0.1)}
				o.merge(r[0], true)
				o.merge(r[1], true)
				out.append(bare_arms(o))
			return out
		"disciple_take_gloves":
			var gp := V(19, -53)
			return [
				G({"hl": BARE_L, "stl": "open", "hr": BARE_R, "str": "open", "head": V(2, -57), "tw": -0.6}),                    # 0 vira para o saco
				up(G({"hl": V(-9, -29), "stl": "open", "hr": V(20, -62), "pr": V(1, 0.4), "str": "open", "gkr": "up", "shoer": "34ball",
					"head": V(3, -57), "top": V(2, -50)}), 0),                                                                   # 1 estica o braço
				up(G({"hl": V(-9, -29), "stl": "open", "hr": V(20, -62), "pr": V(1, 0.4), "str": "fist", "gkr": "up", "shoer": "34ball",
					"head": V(3, -57), "top": V(2, -50), "after_left": pair_hook()}), 0),                                       # 2 PEGA o par
				G({"hl": V(-8, -30), "stl": "open", "hr": V(11, -43), "pr": V(1, 0.7), "str": "fist", "after_left": pair_hook()}),  # 3 par no peito
				G({"hl": V(2, -45), "el": V(-6, -39), "gkl": "up", "hr": V(6, -40), "pr": V(1, 0.8), "str": "fist", "gkr": "side",
					"after_left": glove_in_hand(V(1, 8), "down")}),                                                               # 4 calça a mão de trás
				G({"hl": V(1, -44), "el": V(-6, -39), "gkl": "up", "hr": V(8, -47), "pr": V(1, 0.8), "gkr": "up"}),              # 5 calça a da frente
				G({"hl": V(1, -45), "el": V(-6, -39), "gkl": "up", "hr": V(5, -48), "pr": V(1, 0.9), "gkr": "up"}),              # 6 aperta o fecho
				G(),                                                                                                               # 7 guarda
			]
	return []

const DISC := {
	"disciple_stand_bare": {"fps": 4, "loop": true, "action": "stand_bare",
		"note": "Parado, sem luvas, braços soltos, respiração de 1 px. Virado à DIREITA; para a cena (facing left) usar a folha disciple_stand_bare_left, sem espelho. Na porta só aparece do ombro para baixo. Base da pose de mentor da 6b2."},
	"disciple_duck_under": {"fps": 10, "loop": false, "action": "duck_under", "step_frames": [3, 6],
		"note": "Entrar por baixo da porta (de (423,221) a (410,236); na cena usar disciple_duck_under_left, sem espelho). 0 dobra os joelhos; 1 tronco inclina, mão de trás sobe para a borda; 2-3 cabeça passa embaixo da borda (topo da cabeça abaixo de y 171 com a posição interpolada), mão na borda perto de (431,172); 4 solta a borda, passo à frente; 5 endireita; 6 de pé (encaixa no walk_bare)."},
	"disciple_walk_bare": {"fps": 10, "loop": true, "action": "walk_bare", "step_frames": [1, 4],
		"note": "Andar sem luvas, passada de 14 px (6 quadros a 10 fps = 2 passos em 0,6 s = 48 px/s). Braço oposto à perna (1: perna de longe na frente, braço de perto na frente; 4: o contrário), braços quase esticados em pêndulo, cotovelo para trás. Virado à direita; para andar para a esquerda usar disciple_walk_bare_left, sem espelho. 1 e 4 = pé pousa."},
	"disciple_take_gloves": {"fps": 10, "loop": false, "action": "take_gloves", "grab_frame": 2,
		"note": "Pegar as luvas e armar a guarda, virado à DIREITA (sem espelho). 0 vira para o saco; 1 estica o braço (mão perto de (323,210)); 2 PEGA o par (o adereço some); 3 par no peito; 4 calça a mão de trás (luva velha a partir daqui); 5 calça a da frente; 6 aperta o fecho contra a outra luva (sem dentes, sem toque); 7 guarda (= quadro 0 do fighter_idle)."},
}

# ================================================================ geração
func john_build() -> Dictionary:
	var o: Dictionary = P.identidade("primeiro")
	o.merge({"glove": OLD.style, "glove_ramp": OLD.ramp}, true)
	return P.build(o)

func disc_build() -> Dictionary:
	var o: Dictionary = P.identidade("disc")
	o.merge({"glove": OLD.style, "glove_ramp": OLD.ramp}, true)
	return P.build(o)

func render(b: Dictionary, q, tag: String, piv := GPIV) -> Array:
	var p: Dictionary
	var strap := 0
	if q is Dictionary and (q as Dictionary).has("p"):
		p = (q.p as Dictionary).duplicate()
		strap = int(q.get("strap", 0))
	else:
		p = (q as Dictionary).duplicate()
	if strap > 0:
		p = with_strap(p, b, strap)
	P.build_ref = b
	var im: Image = P.garage_frame(b, p, tag, Vector2i(48, 72), piv)
	return [im, p, P.last_anchor.duplicate(true)]

func gen_john() -> void:
	var b := john_build()
	for id in JOHN:
		var e: Dictionary = JOHN[id]
		var frames := []
		var hands := []
		var anchors := []
		var i := 0
		for q in john_poses(id):
			var r := render(b, q, "%s[%d]" % [id, i])
			frames.append(r[0])
			var p: Dictionary = r[1]
			hands.append({"hand_front": [p.hr.x, p.hr.y], "hand_back": [p.hl.x, p.hl.y]})
			anchors.append(r[2])
			i += 1
		john_frames[id] = frames
		P.strip(frames).save_png(out_dir + "characters/" + id + ".png")
		var pos: Vector2 = P_JOHN if e.pos == "P_JOHN" else P_MENTOR
		var top := 999.0
		var hx := 0.0
		for a in anchors:
			if float(a.head[1]) < top:
				top = float(a.head[1])
				hx = float(a.head[0])
		var ent := {"file": "res://assets/sprites/characters/%s.png" % id, "frame_size": [48, 72], "frames": frames.size(),
			"fps": e.fps, "pivot": [22, 67], "loop": e.loop, "facing": "direita", "who": "primeiro", "action": e.action,
			"glove": "glove_old", "pos": [pos.x, pos.y], "hands": hands, "head_anchor": [hx, top - 8.0],
			"head_by_frame": anchors.map(func(a): return [a.head[0], a.head[1]]),
			"frames_note": e.note + " Luz: sem luz pintada, igual às folhas fighter_* do centro (a cena passa direto do fighter_punch para estas folhas)."}
		for k in ["catch_frame", "bite_frame", "release_frame", "step_frames", "tap_frames"]:
			if e.has(k):
				ent[k] = e[k]
		if id == "mentor_first_taps":
			var tp := []
			for t in e.tap_frames:
				var h: Dictionary = hands[t]
				tp.append([roundi((float(h.hand_front[0]) + float(h.hand_back[0])) * 0.5), roundi((float(h.hand_front[1]) + float(h.hand_back[1])) * 0.5)])
			ent["tap_points"] = tp
		if id == "john_point_spot":
			ent["point_hand"] = [pos.x + 20 + 4, pos.y - 36 + 3]
		sprites[id] = ent

func gen_disc() -> void:
	P.capture = true
	var b := disc_build()
	for id in DISC:
		var e: Dictionary = DISC[id]
		var hands := []
		var i := 0
		for q in disc_poses(id):
			var r := render(b, q, "%s[%d]" % [id, i])
			var p: Dictionary = r[1]
			hands.append({"hand_front": [p.hr.x, p.hr.y], "hand_back": [p.hl.x, p.hl.y]})
			i += 1
		var caps: Array = P.capture_take()
		disc_caps[id] = caps
		var meta: Dictionary = P.save_layer_sheet(caps, out_dir + "disciple/", id, "", cam_store, report)
		var ent := layered_entry(id, "", meta, {"fps": e.fps, "loop": e.loop, "pivot": [22, 67], "facing": "direita"})
		ent["action"] = e.action
		ent["hands"] = hands
		ent["frames_note"] = e.note
		ent["glove"] = "glove_old" if id == "disciple_take_gloves" else "none"
		for k in ["step_frames", "grab_frame"]:
			if e.has(k):
				ent[k] = e[k]
		ent["mirror_ok"] = false
		sprites[id] = ent
		if id in LEFT_IDS:
			ent["left_variant"] = id + "_left"
			gen_left(b, id, e)
	P.capture = false

## Versão VIRADA PARA A ESQUERDA de uma folha do discípulo (o jogo não espelha): mesmas poses, corpo montado para a
## esquerda (o braço de perto da câmera fica do lado de trás do movimento, o de longe passa atrás do tronco) e a luz da
## lâmpada vindo de cima/à esquerda, que é onde ela fica para quem entra pela porta. Pivô (22,67) igual ao das outras.
func gen_left(b: Dictionary, id: String, e: Dictionary) -> void:
	var lid: String = id + "_left"
	var hands := []
	var i := 0
	for q in disc_poses(id):
		var r := render(b, q, "%s[%d]" % [lid, i], Vector2(47 - GPIV.x, GPIV.y))
		P.capture_flip_last()
		var p: Dictionary = r[1]
		# virado para a esquerda: x relativo ao pivô troca de sinal; mão "da frente" continua a do lado para onde ele anda
		hands.append({"hand_front": [-p.hl.x, p.hl.y], "hand_back": [-p.hr.x, p.hr.y]})
		i += 1
	var caps: Array = P.capture_take()
	for c in caps:
		var a: Dictionary = c.anchor
		for k in ["head", "hip", "top"]:
			a[k] = [-float(a[k][0]), a[k][1]]
		a["head_rot"] = -float(a.head_rot)
		a["view"] = "34_left"
		a.erase("flipped")
		var hb: Array = a.get("head_box", [])
		if hb.size() == 4:
			a["head_box"] = [47 - (int(hb[0]) + int(hb[2]) - 1), hb[1], hb[2], hb[3]]
	disc_caps[lid] = caps
	var meta: Dictionary = P.save_layer_sheet(caps, out_dir + "disciple/", lid, "", cam_store, report)
	var ent := layered_entry(lid, "", meta, {"fps": e.fps, "loop": e.loop, "pivot": [22, 67], "facing": "esquerda"})
	ent["action"] = e.action
	ent["hands"] = hands
	ent["mirror_ok"] = false
	ent["right_variant"] = id
	ent["frames_note"] = "VERSÃO VIRADA PARA A ESQUERDA (desenhada assim; não espelhar). " + e.note
	ent["glove"] = "none"
	for k in ["step_frames", "grab_frame"]:
		if e.has(k):
			ent[k] = e[k]
	sprites[lid] = ent

## Entrada do manifest de uma folha em camadas. base = id sem luva; gsuf = sufixo de luva.
func layered_entry(base: String, gsuf: String, meta: Dictionary, extra: Dictionary) -> Dictionary:
	var d := "res://assets/sprites/disciple/"
	var top := 999
	var hx := 0.0
	for a in meta.anchors:
		var hb: Array = a.get("head_box", [])
		if hb.size() == 4 and int(hb[1]) < top:
			top = int(hb[1])
			hx = float(a.head[0])
	var ent := {
		"file": d + base + gsuf + "_disc_body.png",
		"frame_size": meta.frame_size, "frames": meta.frames, "who": "discipulo",
		"layers": {"body": d + base + gsuf + "_disc_body.png", "head": {"short": d + base + "_disc_head_short.png"},
			"front_mask": d + base + "_disc_front.png"},
		"palette_swap": "disciple_palette",
		"anchors": meta.anchors.map(func(a): return {"head": a.head, "head_rot": a.head_rot, "hip": a.hip, "top": a.top,
			"tw": a.tw, "view": a.view, "face": a.face, "head_box": a.get("head_box", []), "flipped": a.get("flipped", false)}),
	}
	for k in extra:
		ent[k] = extra[k]
	if top < 999:
		var piv: Array = ent.get("pivot", [22, 67])
		ent["head_anchor"] = [hx, float(top - int(piv[1]) - 1)]
	return ent

## Camadas das poses que já existiam (lidas das metas dos geradores de sempre).
func merge_old_layers() -> Array:
	var bases := []
	for fn in ["camadas_jogador.json", "camadas_golpes.json"]:
		var path: String = cam_dir + "disciple/" + fn
		if not FileAccess.file_exists(path):
			report.append("AVISO: falta " + path + " (rode os geradores com FC_LUTADOR=disc FC_CAMADAS=1)")
			continue
		var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for base in j:
			if not (base in bases):
				bases.append(base)
			for gsuf in ["", "_glove_l1", "_glove_l2", "_glove_l3", "_glove_l4"]:
				var old_id: String = base + gsuf + "_disc"
				if base == "portrait_player":
					sprites[base + gsuf + "_disc_layered"] = layered_entry(base, gsuf, j[base], {"pivot": [0, 0],
						"same_as": "res://assets/sprites/fight/portrait_player%s_disc.png" % gsuf,
						"note": "Retrato 32x32 do HUD da luta em camadas (fundo vai no body)."})
					continue
				if not M.sprites.has(old_id):
					report.append("AVISO: %s não existe no manifest (camadas geradas mesmo assim)" % old_id)
				var src: Dictionary = M.sprites.get(old_id, {})
				var extra := {}
				for k in src:
					if not (k in ["file", "note", "note_disc"]):
						extra[k] = src[k]
				extra["same_as"] = old_id
				extra["note"] = "Discípulo EM CAMADAS (Fase 6b1): mesmos quadros, fps, pivô, mãos e hit de %s; montar body -> head_<corte> -> body pela front_mask e trocar as cores-chave (by_data_id.disciple_palette)." % old_id
				sprites[base + gsuf + "_disc_layered"] = layered_entry(base, gsuf, j[base], extra)
	return bases

func palette_block() -> Dictionary:
	var keys := {}
	for k in P.KEYS:
		var d := {}
		for i in (P.KEYS[k].names as Array).size():
			var n: String = P.KEYS[k].names[i]
			if n == "ink":
				continue
			d[P.KEYS[k].slots[i]] = "#" + (L.col(n) as Color).to_html(false)
		keys[k] = d
	var opts := {"skin": [], "hair_color": [], "shorts_color": []}
	for o in PALETTE.skin:
		var c: Array = o.colors
		opts.skin.append({"id": o.id, "ramp": {"deep": o.deep, "shadow": c[0], "base": c[1], "light": c[2], "highlight": c[2]}})
	for o in PALETTE.hair_color:
		var c: Array = o.colors
		opts.hair_color.append({"id": o.id, "ramp": {"brow": c[2], "dark": c[0], "light": c[1], "shine": c[1]}})
	for o in PALETTE.shorts_color:
		var c: Array = o.colors
		opts.shorts_color.append({"id": o.id, "ramp": {"deep": o.deep, "dark": c[0], "mid": c[1], "light": c[2], "band": c[3]}})
	return {
		"keys": {"skin": keys.skin, "hair_color": keys.hair, "shorts_color": keys.shorts},
		"options": opts,
		"default": {"skin": "skin_3", "hair_color": "brown", "shorts_color": "green"},
		"how": "Troca exata de cor nas camadas do discípulo (body, head_*): cada pixel com a cor de keys.<campo>.<slot> vira options.<campo>[id].ramp.<slot>. Qualquer outra cor (luva, tênis, olho, contorno ink, fita) não muda. As chaves são o visual padrão (skin_3/brown/green) com +1 num canal, para não coincidir com nenhuma cor da paleta de 45 (o br0/br1/br2 do cabelo castanho também aparece na luva de couro e o br0 é a sombra funda da pele). Hex final: docs/arte/paletas-6b1.md; 'deep' = tom abaixo da sombra (pele do lado de trás e sombra de contato), escolhido pelo Artista; 'highlight'/'shine' não são usados nas folhas da 6b1.",
		"compose": "Ordem por quadro (mesmo tamanho e pivô): body -> [parte de cima, 6b2] -> head_<corte> -> body (e a parte de cima) recortado pela front_mask (branco = desenhar). Com a máscara vazia o 3º passo não faz nada.",
	}

# ================================================================ mockups
func recolor_map(skin: String, hair: String, shorts: String) -> Dictionary:
	var pb := palette_block()
	var m := {}
	for fld in [["skin", skin], ["hair_color", hair], ["shorts_color", shorts]]:
		var keys: Dictionary = pb["keys"][fld[0]]
		var ramp: Dictionary = {}
		for o in pb.options[fld[0]]:
			if o.id == fld[1]:
				ramp = o.ramp
		for slot in keys:
			m[(keys[slot] as String).substr(1)] = Color.html(ramp[slot])
	return m

func spr_frames(id: String) -> Array:
	var e: Dictionary = M.sprites[id]
	return P.frames_of(ROOT + "assets/sprites/" + (e.file as String).replace("res://assets/sprites/", ""), int(e.frame_size[0]))

func por(dst: Image, id: String, q: int, pos: Vector2) -> void:
	var e: Dictionary = M.sprites[id]
	var fr := spr_frames(id)
	P.paste(dst, fr[clampi(q, 0, fr.size() - 1)], int(pos.x) - int(e.pivot[0]), int(pos.y) - int(e.pivot[1]))

func layer_frames(dir: String, base: String, gsuf: String, fw: int) -> Array:
	var bo: Array = P.frames_of(dir + base + gsuf + "_disc_body.png", fw)
	var he: Array = P.frames_of(dir + base + "_disc_head_short.png", fw)
	var ma: Array = P.frames_of(dir + base + "_disc_front.png", fw)
	return [bo, he, ma]

func disc_img(lf: Array, q: int, rc: Dictionary) -> Image:
	return P.compose_layers(lf[0][q], lf[1][q], lf[2][q], rc)

func garagem_base() -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	por(im, "garage_bg", 0, V(128, 18))
	for id in ["wall_notice_debt", "wall_form_blank", "wall_photo_old"]:
		if M.sprites.has(id):
			var e: Dictionary = M.sprites[id]
			por(im, id, 0, V(e.pos[0], e.pos[1]))
	por(im, "lamp", 0, V(300, 32))
	var t: Image = spr_frames("bag_chain_tile")[0]
	var y := 33
	while y < 183:
		P.paste(im, t.get_region(Rect2i(0, 0, 4, mini(6, 183 - y))), 335, y)
		y += 6
	return im

func paste_at(im: Image, fr: Image, pos: Vector2, piv := GPIV, shadow := true) -> void:
	if shadow:
		por(im, "floor_shadow", 0, pos + V(0, -1))
	P.paste(im, fr, int(pos.x) - int(piv.x), int(pos.y) - int(piv.y))

func xadrez(dst: Image, x: int, y: int, w: int, h: int, cell: int) -> void:
	for yy in range(0, h, cell):
		for xx in range(0, w, cell):
			L.R(dst, x + xx, y + yy, mini(cell, w - xx), mini(cell, h - yy), "g1" if ((xx / cell + yy / cell) % 2 == 0) else "g0")

## linhas: [titulo, nota, frames]
func contato(linhas: Array, titulo: String, S: int, path: String) -> void:
	var gap := 6 + S
	var W := 600
	var H := 40
	for r in linhas:
		var fr: Array = r[2]
		var fw: int = (fr[0] as Image).get_width()
		var fh: int = (fr[0] as Image).get_height()
		W = maxi(W, 16 + fr.size() * (fw * S + gap) + 24 + fr.size() * (fw + 3))
		H += 22 + fh * S + 14
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, titulo, 10, 8, "y1", 2 if S > 1 else 1, "ink")
	var y := 34
	for r in linhas:
		var fr: Array = r[2]
		var fw: int = (fr[0] as Image).get_width()
		var fh: int = (fr[0] as Image).get_height()
		L.text(out, r[0], 10, y, "cream", 1, "ink")
		L.text(out, r[1], 14 + L.text_w(r[0], 1), y, "g2", 1, "ink")
		y += 14
		var x := 10
		for i in fr.size():
			xadrez(out, x, y, fw * S, fh * S, 4 * S)
			P.paste(out, P.scaled(fr[i], S), x, y)
			L.text(out, str(i), x + 2, y + 2, "white", 1, "ink")
			x += fw * S + gap
		x += 16
		for i in fr.size():
			L.R(out, x, y, fw, fh, "g1")
			P.paste(out, fr[i], x, y)
			x += fw + 3
		y += fh * S + 14
	out.save_png(path)

func mockups(old_bases: Array) -> void:
	var md := out_dir + "mock/"
	DirAccess.make_dir_recursive_absolute(md)
	var dd := out_dir + "disciple/"
	# ---- contato John
	var lj := []
	for id in JOHN:
		lj.append([id, "%d q, %d fps" % [john_frames[id].size(), JOHN[id].fps], john_frames[id]])
	contato(lj, "FASE 6B1 - JOHN (3x; a direita 1x)", 3, md + "fase6b1_contato_john_x3.png")
	# ---- contato discípulo (padrão + 2 visuais) com as camadas
	var ld := []
	var rc_def := recolor_map("skin_3", "brown", "green")
	var rc_a := recolor_map("skin_5", "black", "white")
	var rc_b := recolor_map("skin_1", "copper", "purple")
	for id in DISC:
		var lf := layer_frames(dd, id, "", 48)
		var a := []
		var b2 := []
		var c := []
		var body := []
		var head := []
		for q in (lf[0] as Array).size():
			a.append(disc_img(lf, q, rc_def))
			b2.append(disc_img(lf, q, rc_a))
			c.append(disc_img(lf, q, rc_b))
			body.append(lf[0][q])
			head.append(lf[1][q])
		ld.append([id, "padrao (skin_3, castanho, verde)", a])
		ld.append(["", "skin_5, preto, branco", b2])
		ld.append(["", "skin_1, ruivo, roxo", c])
		ld.append(["", "camada body (cores-chave)", body])
		ld.append(["", "camada head_short", head])
	contato(ld, "FASE 6B1 - DISCIPULO EM CAMADAS (3x; a direita 1x)", 3, md + "fase6b1_contato_discipulo_x3.png")
	# ---- todas as poses antigas do discípulo montadas em camadas (1 visual alternativo) x folha _disc atual
	var lo := []
	for base in old_bases:
		if base == "portrait_player":
			continue
		var e: Dictionary = M.sprites.get(base + "_disc", {})
		if e.is_empty():
			continue
		var fw: int = int(e.frame_size[0])
		var lf := layer_frames(cam_dir + "disciple/", base, "", fw)
		var atual := spr_frames(base + "_disc")
		var novo := []
		for q in (lf[0] as Array).size():
			novo.append(disc_img(lf, q, rc_a))
		lo.append([base + "_disc", "folha atual", atual])
		lo.append(["", "camadas: skin_5, preto, branco", novo])
	contato(lo, "FASE 6B1 - POSES DE SEMPRE: FOLHA _disc ATUAL x CAMADAS COM OUTRO VISUAL (1x)", 1, md + "fase6b1_poses_antigas_camadas_x1.png")
	# ---- 5 peles x 6 combinações de cabelo/calção (guarda da garagem e da luta)
	var combos := [["brown", "green"], ["black", "blue"], ["dark_brown", "black"], ["copper", "white"], ["blond", "purple"], ["platinum", "yellow"]]
	var gl := layer_frames(cam_dir + "disciple/", "fighter_idle", "", 48)
	var fl := layer_frames(cam_dir + "disciple/", "fight_player_idle", "", 112)
	var cw := 52
	var chh := 76
	var pw := 44 + combos.size() * cw * 2 + 20
	var ph := 40 + 5 * (chh + 10) + 20 + 5 * 80
	var sheet: Image = L.blank(pw, ph)
	L.R(sheet, 0, 0, pw, ph, "d1")
	var bg := garagem_base()
	L.text(sheet, "FASE 6B1 - 5 PELES x CABELO/CALCAO (garagem 2x; luta 1x)", 8, 6, "y1", 1, "ink")
	for j in combos.size():
		L.text(sheet, "%s/%s" % combos[j], 44 + j * cw * 2, 22, "cream", 1, "ink")
	var skins := ["skin_1", "skin_2", "skin_3", "skin_4", "skin_5"]
	for i in skins.size():
		L.text(sheet, skins[i], 2, 40 + i * (chh + 10) + 2, "g3", 1, "ink")
		for j in combos.size():
			var rc := recolor_map(skins[i], combos[j][0], combos[j][1])
			var cell: Image = bg.get_region(Rect2i(303 - 22 - 2, 272 - 67 - 2, cw, chh))
			P.paste(cell, disc_img(gl, 0, rc), 2, 2)
			P.paste(sheet, P.scaled(cell.get_region(Rect2i(0, 0, cw, chh / 2 + 4)), 2), 44 + j * cw * 2, 40 + i * (chh + 10))
	var yf := 40 + 5 * (chh + 10) + 10
	for i in skins.size():
		for j in combos.size():
			var rc := recolor_map(skins[i], combos[j][0], combos[j][1])
			var fr := disc_img(fl, 0, rc)
			L.R(sheet, 44 + j * cw * 2, yf + i * 80, 96, 78, "st0")
			P.paste(sheet, fr.get_region(Rect2i(16, 22, 96, 78)), 44 + j * cw * 2, yf + i * 80)
	sheet.save_png(md + "fase6b1_peles_cabelos_calcoes.png")
	# ---- John sentado no caixote na sala (S10 sem UI) + discípulo na guarda; 1x e recorte 3x
	var im := garagem_base()
	var items := []
	items.append([P_COACH.y, spr_frames("coach_idle")[0], P_COACH, GPIV])
	items.append([253.0, spr_frames("bag_l0_idle")[0], V(336, 183), V(20, 0)])
	if M.sprites.has("garage_hung_gloves_old"):
		pass
	items.append([P_MENTOR.y - 2, spr_frames("garage_crate")[0], P_MENTOR, V(16, 20)])
	items.append([P_MENTOR.y, john_frames["john_sit_rest"][0], P_MENTOR, GPIV])
	items.append([P_JOHN.y, disc_img(gl, 0, rc_b), P_JOHN, GPIV])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		if it[3] == GPIV:
			paste_at(im, it[1], it[2], it[3], true)
		else:
			paste_at(im, it[1], it[2], it[3], false)
	var reg: Image = im.get_region(Rect2i(128, 18, 384, 272))
	var big: Image = P.scaled(im.get_region(Rect2i(200, 170, 160, 100)), 3)
	var out: Image = L.blank(384 + 8 + 480, 300)
	L.R(out, 0, 0, out.get_width(), out.get_height(), "d1")
	P.paste(out, reg, 0, 20)
	P.paste(out, big, 392, 20)
	L.text(out, "John sentado no caixote (mentor_spot 254,252), sit_rest q0; discipulo skin_1/ruivo/roxo na guarda (camadas)", 4, 4, "y1", 1, "ink")
	out.save_png(md + "fase6b1_john_sentado_sala.png")
	# ---- cena: quadros da sucessão com as folhas novas (S2, S3 1x, S7, S8, S9, S10)
	cena_quadros(md, gl, rc_b)

func cena_quadros(md: String, gl: Array, rc: Dictionary) -> void:
	var dd := out_dir + "disciple/"
	var duck := layer_frames(dd, "disciple_duck_under", "", 48)
	var walk := layer_frames(dd, "disciple_walk_bare", "", 48)
	var take := layer_frames(dd, "disciple_take_gloves", "", 48)
	var quadros := []
	var legs := []
	# S2 segura o saco
	var im := garagem_base()
	paste_at(im, spr_frames("coach_idle")[0], P_COACH)
	paste_at(im, spr_frames("bag_l0_idle")[0], V(336, 183), V(20, 0), false)
	paste_at(im, john_frames["john_hold_bag"][2], P_JOHN)
	quadros.append(im)
	legs.append("S2 hold_bag q2")
	# S3 gloves_off q1, q3, q6 e hang q2 (sem corte)
	for k in [["john_gloves_off", 1], ["john_gloves_off", 3], ["john_gloves_off", 6], ["john_hang_gloves", 2]]:
		im = garagem_base()
		paste_at(im, spr_frames("coach_idle")[0], P_COACH)
		paste_at(im, spr_frames("bag_l0_idle")[0], V(336, 183), V(20, 0), false)
		if k[0] == "john_hang_gloves" and M.sprites.has("garage_hung_gloves_old"):
			paste_at(im, spr_frames("garage_hung_gloves_old")[0], V(335, 186), V(17, 1), false)
		paste_at(im, john_frames[k[0]][k[1]], P_JOHN)
		quadros.append(im)
		legs.append("%s q%d" % k)
	# S7 passa por baixo (posição interpolada do quadro 2), John look_door q3
	im = garagem_base()
	if M.sprites.has("garage_door_outside"):
		por(im, "garage_door_outside", 0, V(382, 168))
	var pd := V(418, 226)
	var d2: Image = disc_img(layer_frames(dd, "disciple_duck_under_left", "", 48), 2, rc)
	paste_at(im, d2, pd)
	if M.sprites.has("garage_door"):
		por(im, "garage_door", 8, V(381, 166))
	paste_at(im, spr_frames("coach_look")[0], P_COACH)
	paste_at(im, spr_frames("bag_l0_idle")[0], V(336, 183), V(20, 0), false)
	if M.sprites.has("garage_hung_gloves_old"):
		paste_at(im, spr_frames("garage_hung_gloves_old")[3], V(335, 186), V(17, 1), false)
	paste_at(im, john_frames["john_look_door"][3], P_JOHN)
	quadros.append(im)
	legs.append("S7 duck_under_left q2 + look_door q3")
	# S8 aponta + discípulo andando
	im = garagem_base()
	paste_at(im, spr_frames("coach_idle")[0], P_COACH)
	paste_at(im, spr_frames("garage_crate")[0], P_MENTOR, V(16, 20), false)
	paste_at(im, spr_frames("bag_l0_idle")[0], V(336, 183), V(20, 0), false)
	if M.sprites.has("garage_hung_gloves_old"):
		paste_at(im, spr_frames("garage_hung_gloves_old")[3], V(335, 186), V(17, 1), false)
	paste_at(im, john_frames["john_point_spot"][2], P_MENTOR)
	var w1: Image = disc_img(layer_frames(dd, "disciple_walk_bare_left", "", 48), 1, rc)
	paste_at(im, w1, V(360, 262))
	quadros.append(im)
	legs.append("S8 point_spot q2 + walk_bare_left q1")
	# S9 pega o par
	for q in [1, 2, 5]:
		im = garagem_base()
		paste_at(im, spr_frames("coach_idle")[0], P_COACH)
		paste_at(im, spr_frames("garage_crate")[0], P_MENTOR, V(16, 20), false)
		paste_at(im, spr_frames("bag_l0_idle")[0], V(336, 183), V(20, 0), false)
		if q < 2 and M.sprites.has("garage_hung_gloves_old"):
			paste_at(im, spr_frames("garage_hung_gloves_old")[3], V(335, 186), V(17, 1), false)
		paste_at(im, john_frames["john_point_spot"][2], P_MENTOR)
		paste_at(im, disc_img(take, q, rc), P_JOHN)
		quadros.append(im)
		legs.append("S9 take_gloves q%d" % q)
	# S10 toques
	im = garagem_base()
	paste_at(im, spr_frames("coach_idle")[0], P_COACH)
	paste_at(im, spr_frames("garage_crate")[0], P_MENTOR, V(16, 20), false)
	paste_at(im, john_frames["mentor_first_taps"][1], P_MENTOR)
	paste_at(im, spr_frames("bag_l0_idle")[0], V(336, 183), V(20, 0), false)
	paste_at(im, disc_img(gl, 0, rc), P_JOHN)
	quadros.append(im)
	legs.append("S10 mentor_first_taps q1")
	var n := quadros.size()
	var cols := 3
	var rows := (n + cols - 1) / cols
	var rw := 230
	var rh := 150
	var out: Image = L.blank(cols * (rw * 2 + 6), rows * (rh * 2 + 18))
	L.R(out, 0, 0, out.get_width(), out.get_height(), "d1")
	for i in n:
		var x := (i % cols) * (rw * 2 + 6)
		var y := (i / cols) * (rh * 2 + 18)
		L.text(out, legs[i], x + 4, y + 4, "y1", 1, "ink")
		P.paste(out, P.scaled((quadros[i] as Image).get_region(Rect2i(200, 140, rw, rh)), 2), x, y + 16)
	out.save_png(md + "fase6b1_cena_quadros_x2.png")

## Andar para a esquerda: folha antiga espelhada (o que o dono viu) x folha nova _left, 4x, com o visual padrão e um
## alternativo. old_dir = pasta com os disciple_walk_bare_disc_*.png antigos.
func andar_esquerda(md: String, old_dir: String) -> void:
	var S := 4
	var old := layer_frames(old_dir, "disciple_walk_bare", "", 48)
	var nw := layer_frames(out_dir + "disciple/", "disciple_walk_bare_left", "", 48)
	var rcs := [recolor_map("skin_3", "brown", "green"), recolor_map("skin_5", "black", "white")]
	var W := 6 * (48 * S + 6) + 10
	var H := 4 * (72 * S + 22) + 30
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "ANDAR PARA A ESQUERDA (4x): ANTES = walk_bare espelhado pelo jogo | DEPOIS = walk_bare_left, sem espelho", 6, 6, "y1", 1, "ink")
	var y := 26
	for k in 2:
		for row in 2:
			var lf: Array = old if row == 0 else nw
			L.text(out, ("ANTES (espelhado)" if row == 0 else "DEPOIS (_left)") + ("  padrao" if k == 0 else "  skin_5/preto/branco"), 6, y, "cream", 1, "ink")
			y += 12
			for q in 6:
				var im := disc_img(lf, q, rcs[k])
				if row == 0:
					im.flip_x()
				var x := 6 + q * (48 * S + 6)
				xadrez(out, x, y, 48 * S, 72 * S, 4 * S)
				P.paste(out, P.scaled(im, S), x, y)
				L.text(out, str(q), x + 3, y + 3, "white", 1, "ink")
			y += 72 * S + 10
	out.save_png(md + "fase6b1_andar_esquerda_x4.png")

## Antes (prancha aprovada, rascunho de 1 quadro) x depois (folhas novas) no mesmo recorte.
func antes_depois(md: String) -> void:
	var pares := [
		["prancha_6b_sucessao_S02.png", P_JOHN, john_frames["john_hold_bag"][2], "S2 hold_bag"],
		["prancha_6b_sucessao_S04.png", P_JOHN, john_frames["john_look_door"][2], "S4 look_door"],
		["prancha_6b_sucessao_S08.png", V(268, 268), john_frames["john_point_spot"][2], "S8 point_spot"],
		["prancha_6b_sucessao_S10.png", V(268, 268), john_frames["mentor_first_taps"][1], "S10 taps"],
	]
	var S := 3
	var out: Image = L.blank(pares.size() * (48 * S * 2 + 20) + 10, 72 * S + 40)
	L.R(out, 0, 0, out.get_width(), out.get_height(), "d1")
	L.text(out, "ANTES (prancha, rascunho) x DEPOIS (folha nova), 3x, sem fundo", 6, 4, "y1", 1, "ink")
	var x := 6
	for pr in pares:
		var src: Image = P.load_png(ROOT + "docs/arte/mockups/" + pr[0])
		var a: Image = src.get_region(Rect2i(int(pr[1].x) - 22, int(pr[1].y) - 67, 48, 72))
		xadrez(out, x, 30, 48 * S, 72 * S, 4 * S)
		P.paste(out, P.scaled(a, S), x, 30)
		xadrez(out, x + 48 * S + 4, 30, 48 * S, 72 * S, 4 * S)
		P.paste(out, P.scaled(pr[2], S), x + 48 * S + 4, 30)
		L.text(out, pr[3], x, 18, "cream", 1, "ink")
		x += 48 * S * 2 + 20
	out.save_png(md + "fase6b1_antes_depois_x3.png")

# ================================================================ main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0].trim_suffix("/") + "/"
	cam_dir = (args[1].trim_suffix("/") + "/") if args.size() > 1 else out_dir
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	P.use_keys()
	M = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	for d in ["characters", "disciple", "mock"]:
		DirAccess.make_dir_recursive_absolute(out_dir + d)
	gen_john()
	gen_disc()
	var old_bases := merge_old_layers()
	var doc := {
		"_sobre": "Fase 6b1 (Artista de Personagens): 9 folhas do John e 4 do discípulo em camadas, mais as camadas de todas as poses do discípulo que já existiam. Gerador: tools/art/make_sprites_fase6b1.gd (+ make_sprites_jogador.gd e make_golpes_jogador.gd com FC_LUTADOR=disc FC_CAMADAS=1). As folhas _disc inteiras continuam valendo até o jogo montar as camadas.",
		"sprites": sprites,
		"by_data_id": {"disciple_palette": palette_block(),
			"disciple_layers": {"note": "Discípulo em camadas (escopo 6b §4.4). Arquivos em assets/sprites/disciple/: <base>[_glove_lN]_disc_body.png (corpo sem cabeça, por luva), <base>_disc_head_<corte>.png (só 'short' na 6b1), <base>_disc_front.png (máscara: corpo que passa na frente do rosto). Mesmo quadro e pivô da folha da pose. Entrada '<base>[_glove_lN]_disc_layered' (poses que já existiam, com same_as = a folha inteira) ou o próprio id (poses novas da 6b1). anchors[q] = cabeça (centro), quadril, peito, giro, vista e rosto do quadro, relativos ao pivô (para a 6b2 gerar cortes, faixa e parte de cima pelo mesmo gerador). head_anchor = topo da cabeça (corte atual) relativo ao pivô.",
				"compose": palette_block().compose, "bases_existentes": old_bases, "cuts": ["short"]}},
	}
	var f := FileAccess.open(out_dir + "manifest-6b1-personagens.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(doc, "\t"))
	f.close()
	mockups(old_bases)
	antes_depois(out_dir + "mock/")
	if args.size() > 2:
		andar_esquerda(out_dir + "mock/", args[2].trim_suffix("/") + "/")
	var fl := FileAccess.open(out_dir + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		fl.store_line(l)
	fl.store_line("---- conferência")
	for l in report:
		fl.store_line(l)
	fl.close()
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	for l in report:
		print(l)
	print("ok: %d entradas" % sprites.size())
	quit()
