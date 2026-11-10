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
		var dxg := float(p.get("dx", 0.0))
		frames.append(P.garage_frame(b, p, "fighter_%s%s[%d]" % [nome, suffix, i], Vector2i(48, 72), Vector2(22.0 + dxg, 67.0)))
		if i == int(g.hit_frame):
			contato = p[g.hit_hand] + Vector2(dxg, 0.0)
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


# ---------------------------------------------------------------- PULAR CORDA (6 quadros, corda em 2 camadas)
# Corpo: garage_frame com a pose do JSON. Corda: curva de Bézier entre as duas luvas cujo ápice depende do ângulo "phi"
# (0 = em cima, 90 = na frente na horizontal, 180 = embaixo dos pés, 270 = atrás). Entre 190 e 340 graus a corda passa
# ATRÁS do personagem (camada _back); nos outros quadros ela passa na FRENTE, por cima do corpo (camada da frente).
const ROPES := {
	"rope_l0_swing": [217, 205, 180], "rope_l1_swing": [77, 123, 179],
	"rope_l0_swing_gym": [212, 71, 58], "rope_l1_swing_gym": [90, 102, 118],
}
const INK := Color8(20, 16, 26)
const ROPE_PIVOT := Vector2(22, 75)


func corda_pose(q: Dictionary) -> Dictionary:
	var p := {}
	for k in GPOSE_BASE:
		p[k] = vec(GPOSE_BASE[k])
	p.erase("el")
	p.erase("er")
	p["toel"] = Vector2(-2, 0)
	p["toer"] = Vector2(7, 0)
	p["gkl"] = ""
	p["gkr"] = ""
	p["pl"] = Vector2(-1, 0.4)
	p["pr"] = Vector2(1, 0.4)
	p["kl"] = Vector2(0.4, 0)
	p["kr"] = Vector2(0.6, 0)
	for k in q:
		if (k as String).begins_with("_") or k in ["phi", "slack", "layer"]:
			continue
		var v: Variant = q[k]
		p[k] = vec(v) if (v is Array and (v as Array).size() == 2) else v
	return p


func corda_camada(q: Dictionary) -> String:
	if q.has("layer"):
		return str(q.layer)
	var c := fposmod(float(q.phi), 360.0)
	return "back" if (c > 190.0 and c < 340.0) else "front"


func gen_corda_corpo(b: Dictionary, g: Dictionary, suffix: String) -> Array:
	var frames := []
	var i := 0
	for q in g.frames:
		frames.append(P.garage_frame(b, corda_pose(q), "fighter_rope%s[%d]" % [suffix, i], Vector2i(48, 80), ROPE_PIVOT))
		i += 1
	return frames


func corda_sheet(g: Dictionary, rgb: Array, camada: String) -> Image:
	var n: int = g.frames.size()
	var sheet := Image.create(48 * n, 80, false, Image.FORMAT_RGBA8)
	var cor := Color8(rgb[0], rgb[1], rgb[2])
	for i in n:
		var q: Dictionary = g.frames[i]
		if corda_camada(q) != camada:
			continue
		var hl := ROPE_PIVOT + vec(q.hl)
		var hr := ROPE_PIVOT + vec(q.hr)
		var hm := (hl.y + hr.y) * 0.5
		var apex: float
		if q.has("slack"):
			apex = hm + float(q.slack)
		else:
			var c := cos(deg_to_rad(float(q.phi)))
			apex = hm - (37.0 if c > 0.0 else 29.0) * c
		# Bézier cúbica: o ápice fica em `apex` e a corda abre para os lados (mais atrás do corpo, para aparecer nas laterais).
		var bul := 6.0 if camada == "back" else 2.0
		var cy := (8.0 * apex - 2.0 * hm) / 6.0
		var c1 := Vector2(hl.x - bul, cy)
		var c2 := Vector2(hr.x + bul, cy)
		var pts := {}
		for k in 401:
			var t := float(k) / 400.0
			var u := 1.0 - t
			var pp := hl * (u * u * u) + c1 * (3.0 * u * u * t) + c2 * (3.0 * u * t * t) + hr * (t * t * t)
			pts[Vector2i(roundi(pp.x), roundi(pp.y))] = true
		var tinta := {}
		for pt in pts:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if not pts.has(pt + d):
					tinta[pt + d] = true
		for pt in tinta:
			_pixel(sheet, i * 48 + pt.x, pt.y, INK)
		for pt in pts:
			_pixel(sheet, i * 48 + pt.x, pt.y, cor)
	return sheet


func _pixel(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func entrada_corda(arquivo: String, g: Dictionary, nota: String) -> Dictionary:
	return {
		"file": arquivo, "frame_size": g.frame_size, "frames": g.frames.size(), "fps": g.fps, "pivot": g.pivot,
		"loop": false, "positions": {"foco_corda": g.foco_corda}, "facing": "direita", "hit_frame": g.hit_frame,
		"frames_note": nota,
	}


# ---------------------------------------------------------------- quadros-chave -> quadros (interpolação suavizada)
func suave(u: float, modo: String) -> float:
	match modo:
		"in":
			return u * u
		"out":
			return 1.0 - (1.0 - u) * (1.0 - u)
		"inout":
			return u * u * (3.0 - 2.0 * u)
	return u


## Se o golpe tem "keys" + "n", cria g.frames com n quadros: entre dois chaves, números e pares [x, y] são interpolados com a
## suavização do chave de chegada; o resto (texto, verdadeiro/falso) vale o do chave de partida até chegar ao próximo.
func expandir(g: Dictionary) -> void:
	if not g.has("keys"):
		return
	var keys: Array = g.keys
	var n := int(g.n)
	var frames := []
	for i in n:
		var k0: Dictionary = keys[0]
		for kk in keys:
			if float(kk.at) <= float(i):
				k0 = kk
		var k1: Dictionary = k0
		for kk in keys:
			if float(kk.at) > float(k0.at):
				k1 = kk
				break
		var u := 0.0
		if k1 != k0:
			u = suave((float(i) - float(k0.at)) / (float(k1.at) - float(k0.at)), str(k1.get("ease", "inout")))
		var q := {}
		if float(k0.at) == float(i):
			q["_hold"] = int(k0.get("hold", 0))  # quadro-chave com "hold": o quadro se repete (impacto segurado)
		for key in k0:
			if key in ["at", "ease", "hold"]:
				continue
			var a: Variant = k0[key]
			var b: Variant = k1.get(key, a)
			if a is Array and b is Array and (a as Array).size() == 2:
				q[key] = [lerpf(float(a[0]), float(b[0]), u), lerpf(float(a[1]), float(b[1]), u)]
			elif (a is float or a is int) and (b is float or b is int):
				q[key] = lerpf(float(a), float(b), u)
			else:
				q[key] = a
		frames.append(q)
	# Segura os quadros pedidos (hold = repetições extras, como o `len` por quadro do Punch Club) e refaz o índice do contato.
	var final := []
	var mapa := {}
	for i in frames.size():
		mapa[i] = final.size()
		var rep := 1 + int(frames[i].get("_hold", 0))
		var q2: Dictionary = (frames[i] as Dictionary).duplicate()
		q2.erase("_hold")
		for r in rep:
			final.append(q2.duplicate())
	g["frames"] = final
	g["hit_frame"] = mapa[int(g.hit_frame)]
	if g.has("hit_hand"):
		pass
	elif final.size() > int(g.hit_frame) and final[int(g.hit_frame)].has("hf"):
		var fq: Dictionary = final[int(g.hit_frame)]
		g["hit_point"] = [float(fq.hf[0]) + float(fq.get("dx", 0.0)), float(fq.hf[1])]  # onde a luva está no contato (com o deslize do corpo)


## Rastro (smear) do golpe: faixa clara entre a posição da luva no quadro anterior e a atual, só onde o quadro está vazio
## (nunca por cima do corpo). Para antes da luva, para ela continuar legível.
func rastro(im: Image, a: Vector2, b: Vector2) -> void:
	var d := b - a
	var comp := d.length() - 5.0
	if comp < 5.0:
		return
	var dir := d.normalized()
	var passos := int(comp)
	for st in passos:
		var t := float(st) / float(passos)
		var pos := a + dir * (comp * t)
		var alfa := 0.2 + 0.7 * t
		for off in [0, 1]:
			var x := roundi(pos.x)
			var y := roundi(pos.y) + int(off)
			if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height() and im.get_pixel(x, y).a < 0.5:
				im.set_pixel(x, y, Color(1, 1, 1, alfa))


func make_build(suffix: String) -> Dictionary:
	var g: Dictionary = GLOVES[suffix]
	return P.build({"glove": g.style, "glove_ramp": g.ramp})


func gen(b: Dictionary, nome: String, g: Dictionary, suffix: String) -> Array:
	var frames := []
	var piv := Vector2(PIVOT[0], PIVOT[1])
	var i := 0
	var mao_antes := Vector2.ZERO
	for q in g.frames:
		var p := pose_do_quadro(q)
		var tag := "fight_player_%s%s[%d]" % [nome, suffix, i]
		var origem := piv + Vector2(float(p.get("dx", 0.0)), 0.0)  # o corpo todo desliza (como o x/y por quadro do Punch Club)
		var im: Image = P.fight_frame(b, p, tag, Vector2i(FW, FH), origem)
		var hfp: Vector2 = origem + p.hf
		if bool(p.get("smear", false)) and i > 0:
			rastro(im, mao_antes, hfp)
		mao_antes = hfp
		var idf: int = P.ids[int(hfp.y) * FW + int(hfp.x)]
		if idf != P.NEAR_GLOVE:
			report.append("AVISO %s: mão da frente %s não cai na luva (id %d)" % [tag, str(p.hf), idf])
		frames.append(im)
		i += 1
	return frames


func entrada(nome: String, g: Dictionary, suffix: String) -> Dictionary:
	var maos := []
	for q in g.frames:
		var dx := float(q.get("dx", 0.0))
		maos.append({"hand_front": [float(q.hf[0]) + dx, float(q.hf[1])], "hand_back": [float(q.hb[0]) + dx, float(q.hb[1])]})
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
	for nm in todos:
		expandir(todos[nm])
	for nm in dados.get("garage", {}):
		expandir(dados.garage[nm])
	var garagem: Dictionary = dados.get("garage", {})
	var corda: Dictionary = dados.get("rope", {}).get("corda", {})
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
		if not corda.is_empty() and (so_estes.is_empty() or "corda" in so_estes):
			var frc := gen_corda_corpo(b, corda, suffix)
			P.strip(frc).save_png(out_dir + "characters/fighter_rope%s.png" % suffix)
			entradas["fighter_rope%s" % suffix] = entrada_corda("res://assets/sprites/characters/fighter_rope%s.png" % suffix, corda,
				"6 quadros, um giro por clique (ver tools/art/golpes.json, bloco rope). Desenhar rope_lN_swing_back ATRÁS e rope_lN_swing NA FRENTE, mesmo quadro e mesmo pivô. Quadro 5 = repouso.")
		for nome in garagem:
			if not so_estes.is_empty() and not (nome in so_estes):
				continue
			var g: Dictionary = garagem[nome]
			var r := gen_garage(b, nome, g, suffix)
			P.strip(r[0]).save_png(out_dir + "characters/fighter_%s%s.png" % [nome, suffix])
			entradas["fighter_%s%s" % [nome, suffix]] = entrada_garage(nome, g, suffix, r[1])
	if not corda.is_empty() and (so_estes.is_empty() or "corda" in so_estes):
		DirAccess.make_dir_recursive_absolute(out_dir + "equipment")
		for nome in ROPES:
			var frente := corda_sheet(corda, ROPES[nome], "front")
			var atras := corda_sheet(corda, ROPES[nome], "back")
			var nome_costas: String = (nome as String).replace("_swing", "_swing_back")
			frente.save_png(out_dir + "equipment/%s.png" % nome)
			atras.save_png(out_dir + "equipment/%s.png" % nome_costas)
			entradas[nome] = entrada_corda("res://assets/sprites/equipment/%s.png" % nome, corda,
				"Corda NA FRENTE do personagem (desenhar POR CIMA do lutador), 6 quadros sincronizados com fighter_rope.")
			entradas[nome_costas] = entrada_corda("res://assets/sprites/equipment/%s.png" % nome_costas, corda,
				"Corda ATRÁS do personagem (desenhar POR BAIXO do lutador), 6 quadros sincronizados com fighter_rope.")
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
