extends SceneTree
## Fase 6b2 (Artista de Personagens): mockups das camadas de personalização do discípulo, montadas EXATAMENTE como o
## jogo deve montar (by_data_id.disciple_palette.compose) a partir dos arquivos gerados.
##   godot --headless --path <tmp> --script E:/Fightclicker/tools/art/make_mockup_fase6b2_personagens.gd -- <pasta_sprites> <manifest-6b2.json> <saida_mock>
##   <pasta_sprites> = pasta que contém disciple/ (assets/sprites/ do projeto ou a saída do gerador)
## Grava: fase6b2_cortes_roupas_x3.png, fase6b2_poses_x2.png, fase6b2_faixa_luva_x3.png

var L
var P
var SPR := ""
var DOC: Dictionary
var PAL: Dictionary
var cache := {}

func frames(path: String, fw: int) -> Array:
	if cache.has(path):
		return cache[path]
	var f := SPR + path.replace("res://assets/sprites/", "")
	var out := []
	if FileAccess.file_exists(f):
		out = P.frames_of(f, fw)
	cache[path] = out
	return out

## {hex chave: Color} de um look (9 campos, como em data/disciples.json). band_override = [deep, dark, light] (teste).
func recolor(look: Dictionary, band_override := []) -> Dictionary:
	var m := {}
	var keys: Dictionary = PAL.keys
	for campo in ["skin", "hair_color", "shorts_color", "top_color", "headband_color", "socks"]:
		var id: String = look.get("shorts_color", "") if campo == "socks" else look.get(campo, "")
		for o in PAL.options[campo]:
			if o.id != id:
				continue
			var ks: Dictionary = keys[campo]
			for slot in o.ramp:
				if ks.has(slot):
					m[(ks[slot] as String).substr(1).to_lower()] = Color.html(o.ramp[slot])
	if band_override.size() == 3:
		var kb: Dictionary = keys.headband_color
		m[(kb.deep as String).substr(1).to_lower()] = Color.html(band_override[0])
		m[(kb.dark as String).substr(1).to_lower()] = Color.html(band_override[1])
		m[(kb.light as String).substr(1).to_lower()] = Color.html(band_override[2])
	return m

## Monta o quadro q da entrada `id` com o look (a mesma conta do jogo).
func disc(id: String, q: int, look: Dictionary, band_override := []) -> Image:
	var e: Dictionary = DOC.sprites[id]
	var lay: Dictionary = e.layers
	var fw: int = int(e.frame_size[0])
	var pick := func(path) -> Image:
		var fr: Array = frames(str(path), fw)
		return null if fr.is_empty() else fr[clampi(q, 0, fr.size() - 1)]
	var body: Image = pick.call(lay.body)
	var top = null if look.top == "none" else pick.call(lay.top[look.top])
	var socks = pick.call(lay.socks) if look.socks == "on" else null
	var head: Image = pick.call(lay.head[look.hair_style])
	var band = pick.call(lay.band) if look.headband != "none" else null
	var mask: Image = pick.call(lay.front_mask)
	return P.compose_full(body, top, socks, head, band, mask, recolor(look, band_override))

func look(sk, hc, hs, sh, tp, tc, hb, hbc, so) -> Dictionary:
	return {"skin": sk, "hair_color": hc, "hair_style": hs, "shorts_color": sh, "top": tp, "top_color": tc,
		"headband": hb, "headband_color": hbc, "socks": so}

func bg(im: Image, x: int, y: int, w: int, h: int, c := "g1") -> void:
	L.R(im, x, y, w, h, c)

func put(dst: Image, src: Image, x: int, y: int, s: int) -> void:
	P.paste(dst, P.scaled(src, s), x, y)

# ---------------------------------------------------------------- 1) cortes e roupas, 3 peles
func cortes_roupas(path: String) -> void:
	var S := 3
	var GW := 48
	var GH := 72
	var FR := Rect2i(28, 12, 56, 90)   # recorte do quadro da luta (112x104)
	var cellw := (GW + FR.size.x) * S + 10
	var cellh := maxi(GH, FR.size.y) * S + 18
	var skins := [["skin_1", "copper", "purple"], ["skin_3", "black", "green"], ["skin_5", "platinum", "blue"]]
	var cells := [
		["buzz", {"hair_style": "buzz"}], ["short", {"hair_style": "short"}], ["volume", {"hair_style": "volume"}], ["bun", {"hair_style": "bun"}],
		["sem parte de cima", {}], ["regata", {"top": "tank", "top_color": "white"}], ["camiseta", {"top": "tee", "top_color": "gray"}],
		["faixa", {"headband": "band", "headband_color": "red"}], ["meiao", {"socks": "on"}],
		["regata amarela + faixa azul", {"top": "tank", "top_color": "yellow", "headband": "band", "headband_color": "blue", "hair_style": "volume"}],
		["camiseta preta + faixa branca", {"top": "tee", "top_color": "black", "headband": "band", "headband_color": "white", "hair_style": "bun", "socks": "on"}],
		["camiseta verde + faixa amarela", {"top": "tee", "top_color": "green", "headband": "band", "headband_color": "yellow", "hair_style": "buzz", "socks": "on"}],
	]
	var cols := 6
	var rows_per_skin := (cells.size() + cols - 1) / cols
	var W := 12 + cols * cellw
	var H := 40 + skins.size() * (rows_per_skin * cellh + 26)
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "FASE 6B2 - CORTES, PARTE DE CIMA, FAIXA E MEIAO EM 3 PELES (3x; garagem fighter_idle q0 | luta fight_player_idle q0)", 8, 8, "y1", 1, "ink")
	L.text(out, "Montado como o jogo: body > top > socks > head_<corte> > band > body+top+socks pela front_mask, cores-chave trocadas pela paleta do manifest.", 8, 22, "g3", 1, "ink")
	var y := 40
	for sk in skins:
		L.text(out, "%s / cabelo %s / calcao %s" % sk, 8, y, "cream", 1, "ink")
		y += 14
		for i in cells.size():
			var c: Array = cells[i]
			var lk := look(sk[0], sk[1], "short", sk[2], "none", "white", "none", "red", "none")
			lk.merge(c[1], true)
			var x := 8 + (i % cols) * cellw
			var yy := y + (i / cols) * cellh
			L.text(out, c[0], x, yy, "g3", 1, "ink")
			bg(out, x, yy + 12, GW * S, GH * S, "g1")
			put(out, disc("fighter_idle_disc_layered", 0, lk), x, yy + 12, S)
			bg(out, x + GW * S + 4, yy + 12, FR.size.x * S, FR.size.y * S, "st0")
			put(out, disc("fight_player_idle_disc_layered", 0, lk).get_region(FR), x + GW * S + 4, yy + 12, S)
		y += rows_per_skin * cellh + 12
	out.save_png(path)

# ---------------------------------------------------------------- 2) um visual cheio em várias poses
func poses(path: String) -> void:
	var S := 2
	var lk := look("skin_4", "copper", "bun", "black", "tee", "blue", "band", "white", "on")
	var lk2 := look("skin_2", "black", "volume", "yellow", "tank", "gray", "band", "red", "on")
	var lista := [
		["fighter_idle_disc_layered", [0, 2]], ["fighter_punch_disc_layered", [0, 1, 2]], ["fighter_run_disc_layered", [0, 3]],
		["fighter_uppercut_glove_l2_disc_layered", [0, 2]], ["fighter_rope_glove_l1_disc_layered", [0, 3]],
		["disciple_stand_bare", [0]], ["disciple_stand_bare_left", [0]], ["disciple_walk_bare", [1]], ["disciple_walk_bare_left", [1, 4]],
		["disciple_duck_under_left", [2]], ["disciple_take_gloves", [2, 5, 7]],
		["fight_player_idle_disc_layered", [0]], ["fight_player_jab_glove_l3_disc_layered", [1]], ["fight_player_heavy_disc_layered", [2]],
		["fight_player_block_glove_l4_disc_layered", [0]], ["fight_player_hit_head_disc_layered", [0]], ["fight_player_uppercut_disc_layered", [2]],
		["fight_player_dodge_disc_layered", [1]], ["fight_player_victory_disc_layered", [1]], ["fight_player_ko_disc_layered", [3]],
		["portrait_player_disc_layered", [0]], ["portrait_player_glove_l2_disc_layered", [0]],
	]
	var items := []
	for it in lista:
		if not DOC.sprites.has(it[0]):
			print("AVISO mockup: falta ", it[0])
			continue
		for q in it[1]:
			items.append([it[0], q])
	var cols := 8
	var cw := 112 * S + 8
	var chh := 104 * S + 18
	var rows := (items.size() + cols - 1) / cols
	var W := 8 + cols * cw
	var H := 30 + 2 * (rows * chh + 20)
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "FASE 6B2 - VISUAL CHEIO EM VARIAS POSES (2x): skin_4/ruivo/coque/camiseta azul/faixa branca/meiao (calcao preto) e skin_2/preto/volume/regata cinza/faixa vermelha/meiao (calcao amarelo)", 8, 8, "y1", 1, "ink")
	var y0 := 28
	for v in 2:
		var lv: Dictionary = lk if v == 0 else lk2
		for i in items.size():
			var id: String = items[i][0]
			var q: int = items[i][1]
			var e: Dictionary = DOC.sprites[id]
			var fw: int = int(e.frame_size[0])
			var fh: int = int(e.frame_size[1])
			var x := 8 + (i % cols) * cw
			var y := y0 + (i / cols) * chh
			var nm := id.replace("_disc_layered", "").replace("fight_player_", "f_").replace("disciple_", "d_").replace("fighter_", "g_")
			L.text(out, "%s q%d" % [nm, q], x, y, "g3", 1, "ink")
			bg(out, x, y + 12, fw * S, fh * S, "st0" if fw == 112 else "g1")
			put(out, disc(id, q, lv), x, y + 12, S)
		y0 += rows * chh + 20
	out.save_png(path)

# ---------------------------------------------------------------- 3) faixa vermelha x luva vermelha (ponto em aberto 3)
func faixa_luva(path: String) -> void:
	var S := 3
	var alts := [["red do manifest r2/r3 (deep r1)", []], ["antigo r1/r2 (deep r0)", ["#5a1a22", "#9c2a2a", "#d4473a"]], ["design: r0/r1 (deep ink)", ["#14101a", "#5a1a22", "#9c2a2a"]]]
	var quadros := [["fight_player_block_disc_layered", 0], ["fight_player_idle_disc_layered", 0], ["fighter_idle_disc_layered", 0], ["fighter_punch_disc_layered", 1], ["fight_player_block_glove_l2_disc_layered", 0]]
	var FR := Rect2i(36, 10, 44, 40)
	var GR := Rect2i(4, 0, 40, 30)
	var W := 8 + quadros.size() * (44 * S + 8) + 180
	var H := 30 + alts.size() * (40 * S + 18) * 2
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "FASE 6B2 - FAIXA VERMELHA x LUVA VERMELHA (3x, cabeca e luvas): 3 linhas de cima skin_3 / cabelo castanho; 3 de baixo skin_1 / preto", 8, 8, "y1", 1, "ink")
	var y := 28
	for sk in [["skin_3", "brown"], ["skin_1", "black"]]:
		for a in alts:
			var lk := look(sk[0], sk[1], "short", "blue", "none", "white", "band", "red", "none")
			L.text(out, a[0], 8, y + 2, "cream", 1, "ink")
			var x := 180
			for qd in quadros:
				var e: Dictionary = DOC.sprites[qd[0]]
				var r: Rect2i = FR if int(e.frame_size[0]) == 112 else GR
				bg(out, x, y, r.size.x * S, r.size.y * S, "st0")
				put(out, disc(qd[0], qd[1], lk, a[1]).get_region(r), x, y, S)
				x += 44 * S + 8
			y += 40 * S + 18
	out.save_png(path)

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	SPR = args[0].trim_suffix("/") + "/"
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	DOC = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	PAL = DOC.by_data_id.disciple_palette
	var md: String = args[2].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(md)
	cortes_roupas(md + "fase6b2_cortes_roupas_x3.png")
	poses(md + "fase6b2_poses_x2.png")
	faixa_luva(md + "fase6b2_faixa_luva_x3.png")
	print("ok mockups 6b2")
	quit()
