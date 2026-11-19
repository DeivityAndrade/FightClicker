extends SceneTree
## Fase 7a1 (Artista de Personagens): prancha das poses de Jiu-jitsu, o discípulo montado das CAMADAS (3 visuais, como o jogo
## monta: by_data_id.disciple_palette) e os 6 adversários, na arena real, com os dois nos pivôs da luta (296 e 346, y 318).
## Rodar a partir de uma pasta com project.godot vazio, depois de gerar as folhas numa pasta temporária:
##   FC_LUTADOR=disc FC_CAMADAS=1 FC_GOLPES=tools/art/golpes_7a1.json make_golpes_jogador.gd -- <tmp>/out_j
##   FC_GOLPES=tools/art/golpes_7a1_adv.json make_golpes_jogador.gd -- <tmp>/out_a      (só para expandir as reações)
##   make_sprites_elenco.gd -- <tmp>/out_o <tmp>/old reacoes <tmp>/out_a/reacoes_expandidas.json
##   godot --headless --path <tmp_proj> --script E:/Fightclicker/tools/art/make_mockup_fase7a1_poses.gd -- <tmp>/out_j <tmp>/out_o <saida>
## Lê o manifest só para a paleta do discípulo e as folhas que já existem (idle de pé). Não grava nada no projeto além de <saida>.
## Ordem de desenho usada (recomendação ao Programador): de pé, quem ataca por cima (como hoje); NO CHÃO, o jogador por cima,
## menos no ground_punch do adversário (quem ataca por cima).

const ROOT := "E:/Fightclicker/"
const FW := 112
const FH := 104
const PIV := Vector2i(56, 98)
const POS_J := Vector2i(296, 318)
const POS_O := Vector2i(346, 318)
const CROP := Rect2i(232, 206, 184, 116)   # recorte da arena em volta dos dois
const OPPS := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
const NOMES := {"opp_warmup": "DUDU", "opp_strong": "BRUTAO", "opp_fast": "DINHO", "opp_tank": "MURALHA", "opp_gym_1": "TONHAO", "opp_gym_2": "KID"}
const GLOVES := ["", "_glove_l1", "_glove_l2", "_glove_l3", "_glove_l4"]
const SYM_CHEST := {"white": "blue", "yellow": "blue", "black": "yellow", "red": "yellow", "blue": "yellow", "green": "yellow", "gray": "yellow"}
const SYM_LEG := {"green": "yellow", "blue": "yellow", "black": "yellow", "white": "blue", "purple": "yellow", "yellow": "blue", "red": "yellow"}
const SYM_RAMPS := {"blue": {"shadow": "#1f2a44", "base": "#2f4a78"}, "yellow": {"shadow": "#e0a040", "base": "#f5d26b"}}
const SYM_KEYS := {"shadow": "#1f2a45", "base": "#304a78"}

var L
var M: Dictionary
var J := ""     # pasta do jogador gerado (fight/, disciple/)
var O := ""     # pasta dos adversários gerados (opponents/)
var OUT := ""
var cache := {}
var expand := {}   # reações/golpes expandidos (fps, quadros, hit)

# ---------------------------------------------------------------- util
func load_abs(p: String) -> Image:
	if cache.has(p):
		return cache[p]
	var img := Image.load_from_file(p)
	img.convert(Image.FORMAT_RGBA8)
	cache[p] = img
	return img

func frame_file(path: String, q: int) -> Image:
	var img := load_abs(path)
	var n := maxi(img.get_width() / FW, 1)
	return img.get_region(Rect2i(clampi(q, 0, n - 1) * FW, 0, FW, FH))

func n_frames(path: String) -> int:
	return maxi(load_abs(path).get_width() / FW, 1)

func scaled(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func h(c: String) -> Color:
	return Color.html(c)

# ---------------------------------------------------------------- discípulo montado das camadas (igual ao jogo)
func recolor(look: Dictionary, sym_place: String) -> Dictionary:
	var pb: Dictionary = M.by_data_id.disciple_palette
	var m := {}
	var pairs := [["skin", look.skin], ["hair_color", look.hair_color], ["shorts_color", look.shorts_color],
		["top_color", look.get("top_color", "white")], ["headband_color", look.get("band", "red") if look.get("band", "none") != "none" else "red"],
		["socks", look.shorts_color]]
	for pr in pairs:
		var keys: Dictionary = pb["keys"][pr[0]]
		var ramp := {}
		for o in pb.options[pr[0]]:
			if o.id == pr[1]:
				ramp = o.ramp
		for slot in keys:
			if ramp.has(slot):
				m[(keys[slot] as String).substr(1).to_lower()] = h(ramp[slot])
	var sid: String = SYM_CHEST.get(look.get("top_color", "white"), "blue") if sym_place == "chest" else SYM_LEG.get(look.shorts_color, "yellow")
	for slot in SYM_KEYS:
		m[(SYM_KEYS[slot] as String).substr(1).to_lower()] = h(SYM_RAMPS[sid][slot])
	return m

## Arquivo da camada: base "fight_player_<anim>", luva gsuf. Corpo/meião por luva; o resto é o mesmo da luva velha.
func layer_path(anim: String, gsuf: String, part: String) -> String:
	var own := J + "disciple/fight_player_%s%s_disc_%s.png" % [anim, gsuf, part]
	if FileAccess.file_exists(own):
		return own
	return J + "disciple/fight_player_%s_disc_%s.png" % [anim, part]

func disc(anim: String, gsuf: String, q: int, look: Dictionary) -> Image:
	var place := "chest" if look.get("top", "none") != "none" else "leg"
	var body := frame_file(layer_path(anim, gsuf, "body"), q)
	var top = frame_file(layer_path(anim, gsuf, "top_" + str(look.top)), q) if look.get("top", "none") != "none" else null
	var socks = frame_file(layer_path(anim, gsuf, "socks"), q) if look.get("socks", false) else null
	var sym = frame_file(layer_path(anim, gsuf, "symbol_" + place), q)
	var head := frame_file(layer_path(anim, gsuf, "head_" + str(look.get("cut", "short"))), q)
	var band = frame_file(layer_path(anim, gsuf, "band"), q) if look.get("band", "none") != "none" else null
	var mask := frame_file(layer_path(anim, gsuf, "front"), q)
	return compose(body, top, socks, sym, head, band, mask, recolor(look, place))

func compose(body: Image, top, socks, sym, head, band, mask, rc: Dictionary) -> Image:
	var out := Image.create_empty(FW, FH, false, Image.FORMAT_RGBA8)
	for y in FH:
		for x in FW:
			var lo := body.get_pixel(x, y)
			for ly in [top, socks, sym]:
				if ly != null:
					var lc: Color = (ly as Image).get_pixel(x, y)
					if lc.a > 0.0:
						lo = lc
			var c := lo
			for ly in [head, band]:
				if ly != null:
					var lc: Color = (ly as Image).get_pixel(x, y)
					if lc.a > 0.0:
						c = lc
			if mask != null and (mask as Image).get_pixel(x, y).a > 0.0 and lo.a > 0.0:
				c = lo
			if c.a > 0.0:
				var hx := c.to_html(false).to_lower()
				if rc.has(hx):
					c = rc[hx]
			out.set_pixel(x, y, c)
	return out

func look(skin: String, hair: String, shorts: String, top := "none", top_color := "white", cut := "short", band := "none", socks := false) -> Dictionary:
	return {"skin": skin, "hair_color": hair, "shorts_color": shorts, "top": top, "top_color": top_color, "cut": cut, "band": band, "socks": socks}

## Folha que já existe no projeto (idle de pé), montada pelo manifest.
func disc_existente(id: String, q: int, lk: Dictionary) -> Image:
	var e: Dictionary = M.sprites[id]
	var lay: Dictionary = e.layers
	var place := "chest" if lk.get("top", "none") != "none" else "leg"
	var f := func(r: String) -> Image: return frame_file(ROOT + r.replace("res://", ""), q)
	var top = f.call(lay.top[lk.top]) if lk.get("top", "none") != "none" else null
	var socks = f.call(lay.socks) if lk.get("socks", false) else null
	var sym = f.call(lay.school_symbol[place]) if lay.has("school_symbol") else null
	var band = f.call(lay.band) if lk.get("band", "none") != "none" else null
	return compose(f.call(lay.body), top, socks, sym, f.call(lay.head[lk.get("cut", "short")]), band, f.call(lay.front_mask), recolor(lk, place))

# ---------------------------------------------------------------- quadros por personagem
var LOOK := {}
var GSUF := ""

func jog(anim: String, q: int) -> Image:
	if anim == "idle":
		return disc_existente("fight_player_idle%s_disc_layered" % GSUF, q, LOOK)
	return disc(anim, GSUF, q, LOOK)

func adv(oid: String, anim: String, q: int) -> Image:
	var p := O + "opponents/%s/%s_%s.png" % [oid, oid, anim]
	if not FileAccess.file_exists(p):
		p = ROOT + "assets/sprites/opponents/%s/%s_%s.png" % [oid, oid, anim]
	return frame_file(p, q)

func cena(bg: Image, pj: Image, po: Image, jog_por_cima: bool) -> Image:
	var c: Image = bg.duplicate()
	var a := [po, pj] if jog_por_cima else [pj, po]
	var at := [POS_O, POS_J] if jog_por_cima else [POS_J, POS_O]
	for i in 2:
		c.blend_rect(a[i], Rect2i(0, 0, FW, FH), at[i] - PIV)
	return c.get_region(CROP)

# ---------------------------------------------------------------- sequências (golpe x reação, no tempo do jogo)
## [nome, quem ataca (j/o), anim do atacante, anim da reação, pose de antes do defensor, chão?]
const SEQS := [
	["EMPURRAO NO CLINCH", "j", "clinch_push", "hit_clinch", "idle", false],
	["QUEDA", "j", "takedown", "fall", "idle", false],
	["CHAO PARADO", "j", "ground_top_idle", "ground_bottom_idle", "", true],
	["PRESSAO NO CHAO", "j", "ground_pressure", "ground_hit", "ground_bottom_idle", true],
	["SOCO DE BAIXO", "o", "ground_punch", "ground_top_hit", "ground_top_idle", true],
	["FINALIZACAO", "j", "submission", "tap_out", "ground_bottom_idle", true],
]

func info(anim: String) -> Dictionary:
	return expand.get(anim, {"fps": 12.0, "n": 1, "hit": 0})

func seq_quadros(oid: String, s: Array, bg: Image) -> Array:
	var quem: String = s[1]
	var ia := info(s[2])
	var ir := info(s[3])
	var fa: float = ia.fps
	var fr: float = ir.fps
	var t_hit: float = float(ia.hit) / fa
	var dur := maxf(float(ia.n) / fa, t_hit + float(ir.n) / fr)
	if s[2] == "ground_top_idle":
		dur = float(ia.n) / fa
	var out := []
	var passo := 1.0 / 12.0
	var t := 0.0
	while t < dur - 0.0001:
		var qa := mini(int(floor(t * fa + 0.0001)), int(ia.n) - 1)
		var rea: String = s[3]
		var qr := 0
		if s[2] == "ground_top_idle":
			qr = mini(int(floor(t * fr + 0.0001)), int(ir.n) - 1)
		elif t < t_hit - 0.0001:
			rea = s[4]
			qr = 0
		else:
			qr = mini(int(floor((t - t_hit) * fr + 0.0001)), int(ir.n) - 1)
		var pj: Image
		var po: Image
		if quem == "j":
			pj = jog(s[2], qa)
			po = adv(oid, rea, qr)
		else:
			po = adv(oid, s[2], qa)
			pj = jog(rea, qr)
		var por_cima := false
		if s[5]:
			por_cima = quem == "j"
		else:
			por_cima = quem == "j" and t >= 0.0   # de pé: o atacante por cima (z 320)
		out.append(cena(bg, pj, po, por_cima))
		t += passo
	return out

func faixa(frames: Array, k: int, gap: int, fundo: Color) -> Image:
	var w := frames.size() * (CROP.size.x * k + gap) - gap
	var img := Image.create_empty(maxi(w, 1), CROP.size.y * k, false, Image.FORMAT_RGBA8)
	img.fill(fundo)
	for i in frames.size():
		img.blit_rect(scaled(frames[i], k), Rect2i(0, 0, CROP.size.x * k, CROP.size.y * k), Vector2i(i * (CROP.size.x * k + gap), 0))
	return img

# ---------------------------------------------------------------- main
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	J = args[0].trim_suffix("/") + "/"
	O = args[1].trim_suffix("/") + "/"
	OUT = args[2].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	M = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	var gm: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(J + "golpes_manifest.json"))
	for id in gm:
		var e: Dictionary = gm[id]
		var an: String = e.action
		expand[an] = {"fps": float(e.fps), "n": int(e.frames), "hit": int(e.get("hit_frame", 0))}
	var om: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(O + "reacoes_adv_manifest.json"))
	for id in om.sprites:
		var e: Dictionary = om.sprites[id]
		expand[str(e.action)] = {"fps": float(e.fps), "n": int(e.frames), "hit": int(e.get("hit_frame", 0))}
	var bg := load_abs(ROOT + "assets/sprites/fight/arena_bg.png")
	var fundo := h("#14101a")
	var looks := [
		[look("skin_3", "brown", "green", "tee", "white", "short"), ""],
		[look("skin_5", "black", "blue", "tank", "black", "buzz", "red", true), "_glove_l2"],
		[look("skin_1", "copper", "purple", "none", "white", "bun", "none", true), "_glove_l4"],
	]
	_ajusta_looks(looks)
	var modo := args[3] if args.size() > 3 else "tudo"
	# 1) sequências: uma linha por par golpe/reação, cada uma com um adversário e um visual
	var linhas := []
	var i := 0
	for s in SEQS:
		var oid: String = OPPS[i % OPPS.size()]
		LOOK = looks[i % 3][0]
		GSUF = looks[i % 3][1]
		linhas.append([("%s - %s" % [s[0], NOMES[oid]]), seq_quadros(oid, s, bg)])
		i += 1
	_salva_linhas(linhas, 2, OUT + "fase7a1_poses_sequencias_x2.png")
	_salva_linhas(linhas, 1, OUT + "fase7a1_poses_sequencias_x1.png")
	if modo == "seq":
		quit()
		return
	# 2) os 6 adversários nas mesmas sequências de chão (quadros-chave), com o visual 1
	var chave := []
	for oid in OPPS:
		var fr := []
		for s in SEQS:
			var q := seq_quadros(oid, s, bg)
			var pegar: Array = {"EMPURRAO NO CLINCH": [2, 4], "QUEDA": [3, 6, 7, 11], "CHAO PARADO": [0], "PRESSAO NO CHAO": [4],
				"SOCO DE BAIXO": [3], "FINALIZACAO": [6, 9]}[s[0]]
			for p in pegar:
				fr.append(q[mini(p, q.size() - 1)])
		chave.append([NOMES[oid], fr])
		LOOK = looks[OPPS.find(oid) % 3][0]
		GSUF = looks[OPPS.find(oid) % 3][1]
	_salva_linhas(chave, 1, OUT + "fase7a1_poses_adversarios_x1.png")
	_salva_linhas(chave, 2, OUT + "fase7a1_poses_adversarios_x2.png")
	# 3) o discípulo em 3 visuais: todas as folhas novas, quadro a quadro, fundo liso, 3x
	var anims := ["clinch_push", "takedown", "ground_top_idle", "ground_pressure", "submission", "ground_top_hit"]
	var blocos := []
	for lk in looks:
		LOOK = lk[0]
		GSUF = lk[1]
		var fr := []
		for an in anims:
			var n := n_frames(J + "fight/fight_player_%s%s_disc.png" % [an, GSUF])
			for q in n:
				var c := Image.create_empty(FW, FH, false, Image.FORMAT_RGBA8)
				c.fill(h("#3a3550"))
				c.blend_rect(jog(an, q), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
				fr.append(c)
		blocos.append(fr)
	_salva_grade(blocos, 3, 18, OUT + "fase7a1_poses_discipulo_x3.png")
	_salva_grade(blocos, 1, 18, OUT + "fase7a1_poses_discipulo_x1.png")
	# 4) adversários: todas as folhas novas, quadro a quadro, 3x
	var ablocos := []
	for oid in OPPS:
		var fr := []
		for an in ["hit_clinch", "fall", "ground_bottom_idle", "ground_hit", "ground_punch", "tap_out"]:
			var p := O + "opponents/%s/%s_%s.png" % [oid, oid, an]
			for q in n_frames(p):
				var c := Image.create_empty(FW, FH, false, Image.FORMAT_RGBA8)
				c.fill(h("#3a3550"))
				c.blend_rect(frame_file(p, q), Rect2i(0, 0, FW, FH), Vector2i.ZERO)
				fr.append(c)
		ablocos.append(fr)
	_salva_grade(ablocos, 2, 21, OUT + "fase7a1_poses_adversarios_folhas_x2.png")
	print("ok")
	quit()

func _ajusta_looks(looks: Array) -> void:
	# confere que as opções existem na paleta (se não, cai na 1ª opção)
	var pb: Dictionary = M.by_data_id.disciple_palette
	for lk in looks:
		var d: Dictionary = lk[0]
		for par in [["skin", "skin"], ["hair_color", "hair_color"], ["shorts_color", "shorts_color"], ["top_color", "top_color"]]:
			var ok := false
			for o in pb.options[par[1]]:
				if o.id == d[par[0]]:
					ok = true
			if not ok:
				print("AVISO look: %s=%s não existe; usando %s" % [par[0], d[par[0]], pb.options[par[1]][0].id])
				d[par[0]] = pb.options[par[1]][0].id
		if d.band != "none":
			var okb := false
			for o in pb.options.headband_color:
				if o.id == d.band:
					okb = true
			if not okb:
				d.band = pb.options.headband_color[0].id

func _salva_linhas(linhas: Array, k: int, path: String) -> void:
	var gap := 2 * k
	var w := 0
	for ln in linhas:
		w = maxi(w, (ln[1] as Array).size() * (CROP.size.x * k + gap))
	var lh := CROP.size.y * k + 12 * k
	var img := Image.create_empty(w + 8, linhas.size() * lh + 8, false, Image.FORMAT_RGBA8)
	img.fill(h("#14101a"))
	var y := 4
	for ln in linhas:
		L.text(img, str(ln[0]), 4, y + 2 * k, "y1", k, "ink")
		img.blit_rect(faixa(ln[1], k, gap, h("#14101a")), Rect2i(0, 0, w, CROP.size.y * k), Vector2i(4, y + 10 * k))
		y += lh
	img.save_png(path)

func _salva_grade(blocos: Array, k: int, por_linha: int, path: String) -> void:
	var cw := FW * k + 2
	var linhas_tot := 0
	for b in blocos:
		linhas_tot += int(ceil(float((b as Array).size()) / por_linha))
	var img := Image.create_empty(por_linha * cw + 4, linhas_tot * (FH * k + 2) + blocos.size() * 6 + 4, false, Image.FORMAT_RGBA8)
	img.fill(h("#14101a"))
	var y := 2
	for b in blocos:
		var arr: Array = b
		for i in arr.size():
			var x := 2 + (i % por_linha) * cw
			var yy := y + int(i / por_linha) * (FH * k + 2)
			img.blit_rect(scaled(arr[i], k), Rect2i(0, 0, FW * k, FH * k), Vector2i(x, yy))
		y += int(ceil(float(arr.size()) / por_linha)) * (FH * k + 2) + 6
	img.save_png(path)
