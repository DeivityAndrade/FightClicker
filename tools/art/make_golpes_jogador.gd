extends SceneTree
## Gera os GOLPES NOVOS do lutador do jogador (uppercut, ...) no mesmo padrão de make_sprites_jogador.gd
## (esqueleto + IK de personagem_lib.gd), com as 4 luvas. Não mexe nas folhas existentes.
## Rodar headless a partir de uma pasta temporária com um project.godot vazio (nunca no projeto):
##   godot --headless --path <pasta_tmp> --script <repo>/tools/art/make_golpes_jogador.gd -- <saida>
## Escreve em <saida>: fight/fight_player_<golpe>[_glove_lN].png e golpes_manifest.json (entradas prontas para o
## assets/sprites/manifest.json: quadros, fps, pivô, hit_frame, hit_point e MÃOS por quadro).
## Posições relativas ao pivô (56,98) = entre os pés, na sola; y negativo = para cima; lutador virado à direita.
## O golpe é desenhado como poses-chave autorais (carrega, sobe, CONTATO, segura, volta): ver padrao-personagem.

const FW := 112
const FH := 104
const PIVOT := [56, 98]

const GLOVES := {
	"": {"name": "Luva velha", "style": "old", "ramp": ["r0", "r1", "r2"]},
	"_glove_l1": {"name": "Luva de lona", "style": "lona", "ramp": ["br3", "cream", "white"]},
	"_glove_l2": {"name": "Luva de couro", "style": "couro", "ramp": ["r0", "br1", "br2"]},
	"_glove_l3": {"name": "Luva de marca", "style": "marca", "ramp": ["d1", "d2", "g0"]},
}

var L
var P
var out_dir := ""
var report: Array = []
var entradas := {}


func V(x: float, y: float) -> Vector2:
	return Vector2(x, y)


## Pose-base de luta (igual à de make_sprites_jogador.gd): só corpo/pés; as mãos entram por quadro.
func fpose(o := {}) -> Dictionary:
	var p := {"hip": V(0, -37), "top": V(2, -61), "toef": V(15, -1), "toeb": V(-3, -1)}
	for k in o:
		p[k] = o[k]
	return p


## Cada golpe: fps, quadro do contato, ponto do contato e a lista de quadros {pose, hf, hb}.
func golpes() -> Dictionary:
	return {
		# Uppercut da mão da frente: 0 agacha e carrega a mão na cintura, 1 empurra com as pernas e a mão sobe,
		# 2 CONTATO no queixo (corpo estica, calcanhar de trás sobe), 3 segura no alto, 4 volta à guarda.
		"uppercut": {"fps": 12.0, "hit_frame": 2, "hit_point": [30, -70],
			"frames": [
				{"hf": V(12, -45), "hb": V(7, -60),
					"pose": fpose({"hip": V(-1, -31), "top": V(-3, -54), "head": V(0, -64), "pf": V(0.2, 1.0), "gkf": "up"})},
				{"hf": V(20, -52), "hb": V(14, -62),
					"pose": fpose({"hip": V(2, -35), "top": V(4, -58), "head": V(7, -68), "tw": 1.0, "shoeb": "ball", "pf": V(0.2, 1.0), "gkf": "up", "far_glove_front": true})},
				{"hf": V(30, -69), "hb": V(15, -63),
					"pose": fpose({"hip": V(4, -38), "top": V(9, -62), "head": V(12, -72), "tw": 1.8, "shoeb": "ball", "pf": V(0.1, 1.0), "gkf": "up", "far_glove_front": true})},
				{"hf": V(30, -72), "hb": V(16, -63),
					"pose": fpose({"hip": V(4, -39), "top": V(9, -63), "head": V(12, -73), "tw": 1.6, "shoeb": "ball", "pf": V(0.1, 1.0), "gkf": "up", "far_glove_front": true})},
				{"hf": V(18, -60), "hb": V(6, -61),
					"pose": fpose({"hip": V(1, -37), "top": V(3, -61), "head": V(6, -71), "tw": 0.4})},
			]},
		# Gancho da mão da frente: 0 carrega girando o tronco para trás, 1 o cotovelo abre e sobe, 2 CONTATO na altura
		# do rosto (tronco gira de vez, luva de lado), 3 passa um pouco do alvo, 4 volta.
		"hook": {"fps": 12.0, "hit_frame": 2, "hit_point": [32, -67],
			"frames": [
				{"hf": V(8, -62), "hb": V(14, -62),
					"pose": fpose({"hip": V(-1, -36), "top": V(-3, -60), "head": V(0, -70), "tw": -0.8, "pf": V(0, -1.0), "gkf": "side", "far_glove_front": true})},
				{"hf": V(21, -66), "hb": V(15, -62),
					"pose": fpose({"hip": V(1, -37), "top": V(4, -61), "head": V(7, -71), "tw": 1.2, "shoeb": "ball", "pf": V(0, -1.0), "gkf": "side", "far_glove_front": true})},
				{"hf": V(32, -67), "hb": V(15, -62),
					"pose": fpose({"hip": V(3, -37), "top": V(9, -61), "head": V(11, -71), "tw": 2.2, "shoeb": "ball", "pf": V(0, -1.0), "gkf": "side", "far_glove_front": true})},
				{"hf": V(27, -65), "hb": V(15, -62),
					"pose": fpose({"hip": V(3, -37), "top": V(8, -60), "head": V(10, -70), "tw": 1.8, "shoeb": "ball", "pf": V(0, -1.0), "gkf": "side", "far_glove_front": true})},
				{"hf": V(18, -60), "hb": V(6, -61),
					"pose": fpose({"hip": V(1, -37), "top": V(3, -61), "head": V(6, -71), "tw": 0.4})},
			]},
		# Soco no estômago da mão da frente: 0 agacha, 1 desce o tronco para frente, 2 CONTATO na barriga (cabeça
		# protegida atrás da luva de trás), 3 segura, 4 volta.
		"body_shot": {"fps": 12.0, "hit_frame": 2, "hit_point": [32, -47],
			"frames": [
				{"hf": V(12, -46), "hb": V(7, -58),
					"pose": fpose({"hip": V(-1, -31), "top": V(-2, -53), "head": V(2, -63), "pf": V(0, 1.0), "gkf": "side"})},
				{"hf": V(22, -47), "hb": V(14, -60),
					"pose": fpose({"hip": V(1, -32), "top": V(6, -55), "head": V(10, -64), "tw": 1.0, "shoeb": "ball", "pf": V(0, 1.0), "gkf": "side", "far_glove_front": true})},
				{"hf": V(32, -47), "hb": V(15, -61),
					"pose": fpose({"hip": V(3, -32), "top": V(11, -55), "head": V(15, -65), "tw": 1.6, "shoeb": "ball", "pf": V(0, 1.0), "gkf": "side", "far_glove_front": true})},
				{"hf": V(31, -49), "hb": V(15, -61),
					"pose": fpose({"hip": V(3, -33), "top": V(10, -56), "head": V(14, -66), "tw": 1.4, "shoeb": "ball", "pf": V(0, 1.0), "gkf": "side", "far_glove_front": true})},
				{"hf": V(18, -60), "hb": V(6, -61),
					"pose": fpose({"hip": V(1, -37), "top": V(3, -61), "head": V(6, -71), "tw": 0.4})},
			]},
	}


func make_build(suffix: String) -> Dictionary:
	var g: Dictionary = GLOVES[suffix]
	return P.build({"glove": g.style, "glove_ramp": g.ramp})


func gen(b: Dictionary, nome: String, g: Dictionary, suffix: String) -> Array:
	var frames := []
	var i := 0
	var piv := Vector2(PIVOT[0], PIVOT[1])
	for f in g.frames:
		var p: Dictionary = (f.pose as Dictionary).duplicate()
		p["hf"] = f.hf
		p["hb"] = f.hb
		var tag := "fight_player_%s%s[%d]" % [nome, suffix, i]
		var im: Image = P.fight_frame(b, p, tag, Vector2i(FW, FH), piv)
		var hfp: Vector2 = piv + f.hf
		var idf: int = P.ids[int(hfp.y) * FW + int(hfp.x)]
		if idf != P.NEAR_GLOVE:
			report.append("AVISO %s: mão da frente %s não cai na luva (id %d)" % [tag, str(f.hf), idf])
		frames.append(im)
		i += 1
	return frames


func entrada(nome: String, g: Dictionary, suffix: String) -> Dictionary:
	var maos := []
	for f in g.frames:
		maos.append({"hand_front": [f.hf.x, f.hf.y], "hand_back": [f.hb.x, f.hb.y]})
	return {
		"file": "res://assets/sprites/fight/fight_player_%s%s.png" % [nome, suffix],
		"frame_size": [FW, FH], "frames": g.frames.size(), "fps": g.fps, "pivot": PIVOT, "loop": false,
		"facing": "direita", "action": nome, "hit_frame": g.hit_frame, "hit_point": g.hit_point, "hands": maos,
	}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0].trim_suffix("/") + "/"
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	DirAccess.make_dir_recursive_absolute(out_dir + "fight")
	var todos := golpes()
	for suffix in GLOVES:
		var b := make_build(suffix)
		for nome in todos:
			var g: Dictionary = todos[nome]
			var fr := gen(b, nome, g, suffix)
			P.strip(fr).save_png(out_dir + "fight/fight_player_%s%s.png" % [nome, suffix])
			entradas["fight_player_%s%s" % [nome, suffix]] = entrada(nome, g, suffix)
	var f := FileAccess.open(out_dir + "golpes_manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(entradas, "\t"))
	f.close()
	var r := FileAccess.open(out_dir + "relatorio.txt", FileAccess.WRITE)
	for l in P.log_lines:
		r.store_line(l)
	r.store_line("---- conferência")
	for l in report:
		r.store_line(l)
	r.close()
	for l in report:
		print(l)
	print("ok: %d folhas" % entradas.size())
	quit()
