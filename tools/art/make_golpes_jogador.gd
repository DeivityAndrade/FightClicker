extends SceneTree
## Gera os GOLPES do lutador do jogador a partir de tools/art/golpes.json (poses em dados), pelo mesmo esqueleto
## com IK de make_sprites_jogador.gd (personagem_lib.gd), com as 4 luvas. Não mexe nas folhas existentes.
## Para criar ou ajustar um golpe: edite golpes.json e rode de novo (nada de código).
## Rodar headless a partir de uma pasta temporária com um project.godot vazio (nunca no projeto):
##   godot --headless --path <pasta_tmp> --script <repo>/tools/art/make_golpes_jogador.gd -- <saida> [golpe ...]
## Escreve em <saida>: fight/fight_player_<golpe>[_glove_lN].png e golpes_manifest.json (entradas prontas para o
## assets/sprites/manifest.json: quadros, fps, pivô, hit_frame, hit_point e MÃOS por quadro).
## Convenções e chaves de pose: ver "_sobre" em golpes.json. Os adversários reaproveitam as mesmas poses.

const FW := 112
const FH := 104
const PIVOT := [56, 98]
const POSE_BASE := {"hip": [0, -37], "top": [2, -61], "toef": [15, -1], "toeb": [-3, -1]}
# Garagem (3/4, 48x72, pivô (22,67)): pose-base de make_sprites_jogador.gd (gpose). Cada quadro do JSON só diz o que muda.
const GPOSE_BASE := {"hip": [0, -31], "top": [1, -50], "head": [1, -57], "sl": [-7, -47], "sr": [8, -47],
	"hl": [-8, -50], "hr": [10, -51], "el": [-9, -40], "er": [10, -40], "toel": [-1, 0], "toer": [10, 0]}

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


## Quadro do JSON -> pose do rig (pares [x, y] viram Vector2; o resto passa direto).
func pose_do_quadro(q: Dictionary) -> Dictionary:
	var p := {}
	for k in POSE_BASE:
		p[k] = vec(POSE_BASE[k])
	for k in q:
		if (k as String).begins_with("_"):
			continue
		var v: Variant = q[k]
		p[k] = vec(v) if (v is Array and (v as Array).size() == 2) else v
	return p


func vec(a: Variant) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


func gpose_do_quadro(q: Dictionary) -> Dictionary:
	var p := {}
	for k in GPOSE_BASE:
		p[k] = vec(GPOSE_BASE[k])
	for k in q:
		if (k as String).begins_with("_"):
			continue
		var v: Variant = q[k]
		p[k] = vec(v) if (v is Array and (v as Array).size() == 2) else v
	# Luva da garagem: o rig usa "up" (de pé) quando ninguém diz nada. Se a pose mexe na mão, a luva tem que acompanhar o
	# antebraço ("" = automático, pela direção cotovelo -> mão); só a guarda parada fica com a luva de pé.
	if q.has("hl") and not q.has("gkl"):
		p["gkl"] = ""
	if q.has("hr") and not q.has("gkr"):
		p["gkr"] = ""
	# Cotovelo: se a pose mexe na mão e não diz o cotovelo, o IK acha (comprimento do braço sempre constante).
	# Cotovelo fixo com a mão longe dele esticava o antebraço (30 px em vez de ~10).
	if q.has("hl") and not q.has("el"):
		p.erase("el")
	if q.has("hr") and not q.has("er"):
		p.erase("er")
	return p


## Golpes do TREINO (garagem): mesma ideia, visão 3/4. Devolve [quadros, ponto de contato relativo ao pivô].
func gen_garage(b: Dictionary, nome: String, g: Dictionary, suffix: String) -> Array:
	var frames := []
	var contato := Vector2.ZERO
	var i := 0
	for q in g.frames:
		var p := gpose_do_quadro(q)
		frames.append(P.garage_frame(b, p, "fighter_%s%s[%d]" % [nome, suffix, i]))
		if i == int(g.hit_frame):
			contato = p[g.hit_hand]
		i += 1
	return [frames, contato]


func entrada_garage(nome: String, g: Dictionary, suffix: String, contato: Vector2) -> Dictionary:
	var fs: Array = g.foco_saco
	return {
		"file": "res://assets/sprites/characters/fighter_%s%s.png" % [nome, suffix],
		"frame_size": [48, 72], "frames": g.frames.size(), "fps": g.fps, "pivot": g.pivot, "loop": false,
		"positions": {"foco_saco": fs}, "facing": "direita", "hit_frame": g.hit_frame,
		"hit_point": [fs[0] + contato.x, fs[1] + contato.y],
	}


func make_build(suffix: String) -> Dictionary:
	var g: Dictionary = GLOVES[suffix]
	return P.build({"glove": g.style, "glove_ramp": g.ramp})


func gen(b: Dictionary, nome: String, g: Dictionary, suffix: String) -> Array:
	var frames := []
	var piv := Vector2(PIVOT[0], PIVOT[1])
	var i := 0
	for q in g.frames:
		var p := pose_do_quadro(q)
		var tag := "fight_player_%s%s[%d]" % [nome, suffix, i]
		var im: Image = P.fight_frame(b, p, tag, Vector2i(FW, FH), piv)
		var hfp: Vector2 = piv + p.hf
		var idf: int = P.ids[int(hfp.y) * FW + int(hfp.x)]
		if idf != P.NEAR_GLOVE:
			report.append("AVISO %s: mão da frente %s não cai na luva (id %d)" % [tag, str(p.hf), idf])
		frames.append(im)
		i += 1
	return frames


func entrada(nome: String, g: Dictionary, suffix: String) -> Dictionary:
	var maos := []
	for q in g.frames:
		maos.append({"hand_front": q.hf, "hand_back": q.hb})
	return {
		"file": "res://assets/sprites/fight/fight_player_%s%s.png" % [nome, suffix],
		"frame_size": [FW, FH], "frames": g.frames.size(), "fps": g.fps, "pivot": PIVOT, "loop": false,
		"facing": "direita", "action": nome, "hit_frame": g.hit_frame, "hit_point": g.hit_point, "hands": maos,
	}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0].trim_suffix("/") + "/"
	var so_estes := args.slice(1)
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	DirAccess.make_dir_recursive_absolute(out_dir + "fight")
	var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "/golpes.json"))
	var todos: Dictionary = dados.moves
	var garagem: Dictionary = dados.get("garage", {})
	DirAccess.make_dir_recursive_absolute(out_dir + "characters")
	for suffix in GLOVES:
		var b := make_build(suffix)
		for nome in todos:
			if not so_estes.is_empty() and not (nome in so_estes):
				continue
			var g: Dictionary = todos[nome]
			var fr := gen(b, nome, g, suffix)
			P.strip(fr).save_png(out_dir + "fight/fight_player_%s%s.png" % [nome, suffix])
			entradas["fight_player_%s%s" % [nome, suffix]] = entrada(nome, g, suffix)
		for nome in garagem:
			if not so_estes.is_empty() and not (nome in so_estes):
				continue
			var g: Dictionary = garagem[nome]
			var r := gen_garage(b, nome, g, suffix)
			P.strip(r[0]).save_png(out_dir + "characters/fighter_%s%s.png" % [nome, suffix])
			entradas["fighter_%s%s" % [nome, suffix]] = entrada_garage(nome, g, suffix, r[1])
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
	for l in P.log_lines:
		if (l as String).begins_with("AVISO"):
			print(l)
	for l in report:
		print(l)
	print("ok: %d folhas" % entradas.size())
	quit()
