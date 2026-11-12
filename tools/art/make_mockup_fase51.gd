extends SceneTree
## Fase 5.1 — conferência das 3 animações mais vistas (soco no saco, corrida na esteira, equipe) e da corda.
## Artista de Personagens. Não gera sprite do jogo: só folhas de contato ANTES x DEPOIS e os quadros das cenas na sala
## real (para virar GIF com o ffmpeg). Rodar headless a partir de uma pasta temporária com um project.godot vazio:
##   godot --headless --path <pasta_tmp> --script <repo>/tools/art/make_mockup_fase51.gd -- <antes> <depois> <saida>
##   <antes>  = pasta com characters/ e equipment/ ANTIGOS (cópia feita antes de trocar os sprites)
##   <depois> = pasta com characters/ e equipment/ NOVOS (pode ser <repo>/assets/sprites)
##   <saida>  = pasta onde gravar contato_x3.png, contato_x1.png e seq_<cena>/NNN.png
## O que não existir em <antes>/<depois> (fundo, saco, esteira, sombra) vem de assets/sprites pelo manifest.
## As cenas tocam os quadros como ui/sala.gd toca hoje (jab 1-2-3 a 18 fps; golpes novos inteiros a 24 fps; saco _hit a
## 14 fps; COMBO_SACO; corrida e esteira a 12 fps; corda 0-5 a 24 fps e quadro 6 parado; equipe 0-3 no fps do manifest).

var ROOT := OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else "E:/Fightclicker/"
const COMBO_SACO := ["fighter_punch", "fighter_punch_b", "fighter_punch", "fighter_punch_b", "fighter_uppercut",
	"fighter_punch", "fighter_punch_b", "fighter_hook"]
const EQUIPE := ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2", "coach_1"]
const SALA := Rect2i(128, 18, 384, 272)
const RECORTE := Rect2i(262, 150, 132, 142)   # lutador + aparelho do centro

var L
var P
var M: Dictionary
var dirs := {}
var cache := {}


func spr(id: String) -> Dictionary:
	return M.sprites[id]


## Folha do sprite `id` no conjunto `qual` ("antes"/"depois"); cai no projeto se o conjunto não tiver o arquivo.
func folha(id: String, qual: String) -> Array:
	var key := qual + "|" + id
	if cache.has(key):
		return cache[key]
	var e := spr(id)
	var rel: String = (e.file as String).replace("res://assets/sprites/", "")
	var path: String = dirs[qual] + rel
	if not FileAccess.file_exists(path):
		path = ROOT + "assets/sprites/" + rel
	var fr: Array = P.frames_of(path, int(e.frame_size[0]))
	cache[key] = fr
	return fr


func por(dst: Image, id: String, qual: String, quadro: int, pos: Vector2) -> void:
	var e := spr(id)
	var fr := folha(id, qual)
	var im: Image = fr[clampi(quadro, 0, fr.size() - 1)]
	P.paste(dst, im, int(pos.x) - int(e.pivot[0]), int(pos.y) - int(e.pivot[1]))


func pos_de(id: String, chave: String) -> Vector2:
	var e := spr(id)
	if chave == "":
		return Vector2(float(e.pos[0]), float(e.pos[1]))
	return Vector2(float(e.positions[chave][0]), float(e.positions[chave][1]))


func corrente(dst: Image, x: int, y_fim: int) -> void:
	var t: Image = folha("bag_chain_tile", "depois")[0]
	var y := 33
	while y < y_fim:
		P.paste(dst, t.get_region(Rect2i(0, 0, 4, mini(6, y_fim - y))), x - 1, y)
		y += 6


func fundo() -> Image:
	var im: Image = L.blank(640, 360)
	L.R(im, 0, 0, 640, 360, "ink")
	por(im, "garage_bg", "depois", 0, Vector2(128, 18))
	return im


func sombra(dst: Image, p: Vector2) -> void:
	por(dst, "floor_shadow", "depois", 0, p + Vector2(0, -1))


func descanso(dst: Image, saco_lado: bool, esteira_lado: bool, corda_prego: bool) -> void:
	if corda_prego:
		por(dst, "rope_l0_idle", "depois", 0, pos_de("rope_l0_idle", "prego"))
	if saco_lado:
		var ps := pos_de("bag_l0_side", "lado_esquerdo")
		corrente(dst, int(ps.x) - 1, int(ps.y))
		por(dst, "bag_l0_side", "depois", 0, ps)
	if esteira_lado:
		por(dst, "treadmill_l0_side", "depois", 0, pos_de("treadmill_l0_side", "lado_direito"))


# ---------------------------------------------------------------- cenas (devolvem os quadros 640x360)
func cena_saco(qual: String, fps: float, cliques_s: float) -> Array:
	var out := []
	var dur := float(COMBO_SACO.size()) / cliques_s
	for k in int(dur * fps):
		var t := float(k) / fps
		var i := int(t * cliques_s)
		var tl := t - float(i) / cliques_s
		var golpe: String = COMBO_SACO[i]
		var im := fundo()
		descanso(im, false, true, true)
		var pb := pos_de("bag_l0_idle", "centro")
		corrente(im, int(pb.x) - 1, int(pb.y))
		var qb := int(tl * 14.0)
		if qb < 4:
			por(im, "bag_l0_hit", "depois", qb, pb)
		else:
			por(im, "bag_l0_idle", "depois", 0, pb)
		var pf := pos_de("fighter_idle", "foco_saco")
		sombra(im, pf)
		var seq: Array = [1, 2, 3] if golpe == "fighter_punch" else range(int(spr(golpe).frames))
		var gf := 18.0 if golpe == "fighter_punch" else float(spr(golpe).fps)
		var q := int(tl * gf)
		if q < seq.size():
			por(im, golpe, qual, seq[q], pf)
		else:
			por(im, "fighter_idle", qual, 0, pf)
		var qi := int(tl * 15.0)
		if qi < 4:
			var hp: Array = spr(golpe).hit_point
			por(im, "fx_impact", "depois", qi, Vector2(float(hp[0]), float(hp[1])))
		out.append(im)
	return out


func cena_esteira(qual: String) -> Array:
	var out := []
	for k in 4:
		var im := fundo()
		descanso(im, true, false, true)
		por(im, "treadmill_l0_run", "depois", k, pos_de("treadmill_l0_run", "centro"))
		por(im, "fighter_run", qual, k, pos_de("fighter_run", "foco_esteira"))
		out.append(im)
	return out


func cena_corda(qual: String) -> Array:
	var out := []
	var seq := []
	for v in 4:
		seq.append_array([0, 1, 2, 3, 4, 5])
	for r in 16:
		seq.append(6)
	for q in seq:
		var im := fundo()
		descanso(im, true, true, false)
		var pf := pos_de("fighter_rope", "foco_corda")
		sombra(im, pf)
		por(im, "rope_l0_swing_back", qual, q, pf)
		por(im, "fighter_rope", qual, q, pf)
		por(im, "rope_l0_swing", qual, q, pf)
		out.append(im)
	return out


func cena_equipe(qual: String, fps: float, dur: float) -> Array:
	var out := []
	var ordem := EQUIPE.duplicate()
	ordem.sort_custom(func(a, b): return float(spr(a).pos[1]) < float(spr(b).pos[1]))
	for k in int(dur * fps):
		var t := float(k) / fps
		var im := fundo()
		descanso(im, false, true, true)
		var pb := pos_de("bag_l0_idle", "centro")
		corrente(im, int(pb.x) - 1, int(pb.y))
		var desenhou_centro := false
		for hid in ordem:
			var p := pos_de(hid, "")
			if p.y > 272.0 and not desenhou_centro:
				_centro(im, t)
				desenhou_centro = true
			sombra(im, p)
			por(im, hid, qual, int(t * float(spr(hid).fps)) % 4, p)
		if not desenhou_centro:
			_centro(im, t)
		out.append(im)
	return out


func _centro(im: Image, t: float) -> void:
	por(im, "bag_l0_idle", "depois", int(t * 3.0) % 4, pos_de("bag_l0_idle", "centro"))
	var pf := pos_de("fighter_idle", "foco_saco")
	sombra(im, pf)
	por(im, "fighter_idle", "depois", int(t * 4.0) % 4, pf)


## Grava ANTES | DEPOIS lado a lado, recortado e ampliado, um PNG por quadro.
func gravar_seq(nome: String, antes: Array, depois: Array, rec: Rect2i, S: int, out_dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(out_dir + "seq_" + nome)
	var gap := 4
	var topo := 14
	for i in antes.size():
		var W := rec.size.x * S * 2 + gap
		var im: Image = L.blank(W, rec.size.y * S + topo)
		L.R(im, 0, 0, W, rec.size.y * S + topo, "d1")
		P.paste(im, P.scaled((antes[i] as Image).get_region(rec), S), 0, topo)
		P.paste(im, P.scaled((depois[i] as Image).get_region(rec), S), rec.size.x * S + gap, topo)
		L.text(im, "ANTES", 4, 3, "r3", 1, "ink")
		L.text(im, "DEPOIS", rec.size.x * S + gap + 4, 3, "gr3", 1, "ink")
		im.save_png(out_dir + "seq_%s/%03d.png" % [nome, i])


# ---------------------------------------------------------------- folha de contato
func xadrez(dst: Image, x: int, y: int, w: int, h: int, cell: int) -> void:
	for yy in range(0, h, cell):
		for xx in range(0, w, cell):
			var c = "g1" if ((xx / cell + yy / cell) % 2 == 0) else "g0"
			L.R(dst, x + xx, y + yy, mini(cell, w - xx), mini(cell, h - yy), c)


func corda_montada(qual: String) -> Array:
	var out := []
	var a := folha("rope_l0_swing_back", qual)
	var b := folha("fighter_rope", qual)
	var c := folha("rope_l0_swing", qual)
	for i in b.size():
		var im: Image = L.blank(48, 80)
		P.paste(im, a[i], 0, 0)
		P.paste(im, b[i], 0, 0)
		P.paste(im, c[i], 0, 0)
		out.append(im)
	return out


func contato(S: int, path: String) -> void:
	var linhas := [
		["CORDA (fighter_rope + rope_l0_swing)", "7 quadros: 0-5 giro a 24 fps, 6 repouso", corda_montada("antes"), corda_montada("depois")],
		["SACO: fighter_punch", "jab da frente, toca 1-2-3 a 18 fps, contato no 2", folha("fighter_punch", "antes"), folha("fighter_punch", "depois")],
		["SACO: fighter_punch_b", "direto de tras, 6 quadros a 24 fps, contato no 2", folha("fighter_punch_b", "antes"), folha("fighter_punch_b", "depois")],
		["SACO: fighter_uppercut", "6 quadros a 24 fps, contato no 2", folha("fighter_uppercut", "antes"), folha("fighter_uppercut", "depois")],
		["SACO: fighter_hook", "golpe lateral, 6 quadros a 24 fps, contato no 2", folha("fighter_hook", "antes"), folha("fighter_hook", "depois")],
		["ESTEIRA: fighter_run", "4 quadros a 12 fps (0 = parado na esteira)", folha("fighter_run", "antes"), folha("fighter_run", "depois")],
	]
	for hid in EQUIPE:
		linhas.append(["EQUIPE: " + hid, "4 quadros a %s fps" % str(spr(hid).fps), folha(hid, "antes"), folha(hid, "depois")])
	var gap := 2 + S * 2
	var mini_x := S > 1
	var W := 0
	var H := 30 * (2 if S > 1 else 1) + 8
	var tx := 2 if S > 1 else 1
	var lab := 70 if S > 1 else 40
	for r in linhas:
		var fw: int = (r[2][0] as Image).get_width()
		var fh: int = (r[2][0] as Image).get_height()
		var n: int = (r[2] as Array).size()
		var w := lab + n * (fw * S + gap) + ((20 + n * (fw + 2)) if mini_x else 0) + 10
		W = maxi(W, w)
		H += 12 * tx + 2 * (fh * S + 4) + 10
	W = maxi(W, 520)
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "FASE 5.1 - ANIMACOES: ANTES x DEPOIS (%dx%s)" % [S, "; a direita, 1x" if mini_x else ""], 8, 6, "y1", tx, "ink")
	var y := 12 * tx + 14
	for r in linhas:
		var fw: int = (r[2][0] as Image).get_width()
		var fh: int = (r[2][0] as Image).get_height()
		L.text(out, r[0], 8, y, "cream", tx, "ink")
		if S > 1:
			L.text(out, r[1], 8 + L.text_w(r[0], tx) + 10, y + 4, "g2", 1, "ink")
		y += 12 * tx
		for linha in 2:
			var fr: Array = r[2] if linha == 0 else r[3]
			L.text(out, "ANTES" if linha == 0 else "DEPOIS", 4, y + fh * S / 2 - 4, "r3" if linha == 0 else "gr3", 1, "ink")
			var x := lab
			for i in fr.size():
				xadrez(out, x, y, fw * S, fh * S, 4 * S)
				P.paste(out, P.scaled(fr[i], S), x, y)
				if S > 1:
					L.text(out, str(i), x + 2, y + 2, "white", 1, "ink")
				x += fw * S + gap
			if mini_x:
				x += 20
				for i in fr.size():
					L.R(out, x, y, fw, fh, "g1")
					P.paste(out, fr[i], x, y)
					x += fw + 2
			y += fh * S + 4
		y += 10
	out.save_png(path)


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	dirs["antes"] = args[0].trim_suffix("/") + "/"
	dirs["depois"] = args[1].trim_suffix("/") + "/"
	var out_dir: String = args[2].trim_suffix("/") + "/"
	var base: String = get_script().resource_path.get_base_dir()
	L = load(base + "/pixel_lib.gd").new()
	P = load(base + "/personagem_lib.gd").new(L)
	M = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	contato(3, out_dir + "contato_x3.png")
	contato(1, out_dir + "contato_x1.png")
	gravar_seq("saco", cena_saco("antes", 24.0, 3.0), cena_saco("depois", 24.0, 3.0), RECORTE, 3, out_dir)
	gravar_seq("saco_lento", cena_saco("antes", 24.0, 3.0), cena_saco("depois", 24.0, 3.0), RECORTE, 3, out_dir)
	gravar_seq("esteira", cena_esteira("antes"), cena_esteira("depois"), RECORTE, 3, out_dir)
	gravar_seq("corda", cena_corda("antes"), cena_corda("depois"), RECORTE, 3, out_dir)
	gravar_seq("equipe", cena_equipe("antes", 12.0, 4.0), cena_equipe("depois", 12.0, 4.0), SALA, 2, out_dir)
	print("ok: mockups da fase 5.1 em ", out_dir)
	quit()
