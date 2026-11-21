extends SceneTree
## Fase 7b1 (Artista de Personagens): pranchas de conferência das poses do Muay Thai, na arena real, com os dois nos pivôs da
## luta (296 e 346, y 318), a reação do adversário começando no hit_frame do golpe (como o jogo faz).
## Rodar a partir de uma pasta com project.godot vazio, depois de gerar as folhas numa pasta temporária (ver poses_7b1.py):
##   godot --headless --path <tmp_proj> --script <repo>/tools/art/make_mockup_fase7b1_poses.gd -- <repo> <tmp>/out_j <tmp>/out_o <saida>
## Usa as folhas planas do discípulo (_disc). Não grava nada no projeto além de <saida>.

const FW := 112
const FH := 104
const PIV := Vector2i(56, 98)
const POS_J := Vector2i(296, 318)
const POS_O := Vector2i(346, 318)
const CROP := Rect2i(226, 200, 196, 122)
const OPPS := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]

var R := ""
var J := ""
var O := ""
var OUT := ""
var M: Dictionary
var cache := {}


func load_abs(p: String) -> Image:
	if cache.has(p):
		return cache[p]
	var img := Image.load_from_file(p)
	img.convert(Image.FORMAT_RGBA8)
	cache[p] = img
	return img


func nfr(path: String, fw: int) -> int:
	return maxi(load_abs(path).get_width() / fw, 1)


func frame(path: String, q: int, fw := FW, fh := FH) -> Image:
	var img := load_abs(path)
	var n := maxi(img.get_width() / fw, 1)
	return img.get_region(Rect2i(clampi(q, 0, n - 1) * fw, 0, fw, fh))


func scaled(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b


func blend_at(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))


func arena(prefix: String) -> Image:
	var bg: Image = load_abs(R + "assets/sprites/fight/%s_bg.png" % prefix).duplicate()
	return bg


func opp_file(oid: String, act: String) -> String:
	var p := O + "opponents/%s/%s_%s.png" % [oid, oid, act]
	if FileAccess.file_exists(p):
		return p
	return R + "assets/sprites/opponents/%s/%s_%s.png" % [oid, oid, act]


## Uma cena: jogador no quadro qj de pj, adversário no quadro qo de po; quem ataca por cima.
func cena(prefix: String, pj: String, qj: int, po: String, qo: int, j_top := true) -> Image:
	var bg := arena(prefix)
	var a := frame(pj, qj)
	var b := frame(po, qo)
	if j_top:
		blend_at(bg, b, POS_O.x - PIV.x, POS_O.y - PIV.y)
		blend_at(bg, a, POS_J.x - PIV.x, POS_J.y - PIV.y)
	else:
		blend_at(bg, a, POS_J.x - PIV.x, POS_J.y - PIV.y)
		blend_at(bg, b, POS_O.x - PIV.x, POS_O.y - PIV.y)
	return bg.get_region(CROP)


## Sequência golpe + reação: devolve os recortes (um por quadro do golpe; a reação continua depois se for mais longa).
func sequencia(prefix: String, golpe: String, hit: int, oid: String, reacao: String, hold_fim: bool) -> Array:
	var pj := J + "fight/fight_player_%s_disc.png" % golpe
	var po := opp_file(oid, reacao)
	var pi := opp_file(oid, "idle")
	var nj := nfr(pj, FW)
	var no := nfr(po, FW)
	var total := maxi(nj, hit + no)
	var out := []
	for i in total:
		var r := i - hit
		var img: Image
		if r < 0:
			img = cena(prefix, pj, i, pi, 0)
		elif r < no:
			img = cena(prefix, pj, mini(i, nj - 1), po, r)
		else:
			img = cena(prefix, pj, mini(i, nj - 1), po if hold_fim else pi, no - 1 if hold_fim else 0)
		out.append(img)
	return out


func tira(frames: Array, k: int, gap := 2) -> Image:
	var w: int = frames[0].get_width() * k
	var h: int = frames[0].get_height() * k
	var im := Image.create(frames.size() * (w + gap) - gap, h, false, Image.FORMAT_RGBA8)
	im.fill(Color8(30, 26, 38))
	for i in frames.size():
		blend_at(im, scaled(frames[i], k), i * (w + gap), 0)
	return im


func empilha(tiras: Array, gap := 4) -> Image:
	var w := 0
	var h := 0
	for t in tiras:
		w = maxi(w, t.get_width())
		h += t.get_height() + gap
	var im := Image.create(w, h - gap, false, Image.FORMAT_RGBA8)
	im.fill(Color8(30, 26, 38))
	var y := 0
	for t in tiras:
		blend_at(im, t, 0, y)
		y += t.get_height() + gap
	return im


func folha_crua(path: String, fw: int, fh: int, k: int) -> Image:
	var n := nfr(path, fw)
	var fr := []
	for i in n:
		var c := Image.create(fw, fh, false, Image.FORMAT_RGBA8)
		c.fill(Color8(58, 52, 74))
		blend_at(c, frame(path, i, fw, fh), 0, 0)
		fr.append(c)
	return tira(fr, k, 1)


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	R = a[0].trim_suffix("/") + "/"
	J = a[1].trim_suffix("/") + "/"
	O = a[2].trim_suffix("/") + "/"
	OUT = a[3].trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(OUT)
	M = JSON.parse_string(FileAccess.get_file_as_string(R + "assets/sprites/manifest.json"))
	var hits := {}
	var gm: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(J + "golpes_manifest.json"))
	for g in ["low_kick", "knee", "thai_clinch", "spin_kick"]:
		hits[g] = int(gm["fight_player_%s_disc" % g].hit_frame)
	# 1) sequências com o Tonhão e o Kid na liga (o Muay Thai sai depois do Kid) e com o Dudu na borracharia
	var seqs := [["low_kick", "hit_leg", false], ["knee", "hit_body", false], ["thai_clinch", "held_clinch", false],
		["spin_kick", "hit_spin", false], ["spin_kick", "fall_spin", true]]
	for alvo in [["arena_league", "opp_gym_1"], ["arena_league", "opp_gym_2"], ["arena", "opp_warmup"], ["arena", "opp_tank"]]:
		var t1 := []
		var t2 := []
		for s in seqs:
			var fr := sequencia(alvo[0], s[0], hits[s[0]], alvo[1], s[1], s[2])
			t1.append(tira(fr, 1))
			t2.append(tira(fr, 2))
		empilha(t1).save_png(OUT + "fase7b1_poses_seq_%s_x1.png" % alvo[1])
		empilha(t2).save_png(OUT + "fase7b1_poses_seq_%s_x2.png" % alvo[1])
	# 2) contato de cada golpe com os 6 adversários (só o quadro do hit), 3x
	var lin := []
	for s in seqs:
		var fr := []
		for oid in OPPS:
			var pre := "arena_league" if oid.begins_with("opp_gym") else "arena"
			var sq := sequencia(pre, s[0], hits[s[0]], oid, s[1], s[2])
			fr.append(sq[hits[s[0]] + (1 if s[0] == "thai_clinch" else 0) * 3])
		lin.append(tira(fr, 2))
	empilha(lin).save_png(OUT + "fase7b1_poses_contato_6adv_x2.png")
	# 3) mancando (idle) dos 6 adversários + guarda tailandesa do discípulo, na arena
	var lm := []
	for act in ["limp", "limp_heavy"]:
		var fr := []
		for oid in OPPS:
			var pre := "arena_league" if oid.begins_with("opp_gym") else "arena"
			fr.append(cena(pre, J + "fight/fight_player_mt_idle_disc.png", 0, opp_file(oid, act), 0))
		lm.append(tira(fr, 2))
	empilha(lm).save_png(OUT + "fase7b1_poses_mancando_x2.png")
	# 4) folhas cruas do discípulo em 3x (todas as luvas do chute baixo, as outras com a luva velha)
	var cr := []
	for g in ["mt_idle", "low_kick", "knee", "thai_clinch", "spin_kick", "spar_mt_push", "spar_mt_kick", "spar_mt_guard"]:
		cr.append(folha_crua(J + "fight/fight_player_%s_disc.png" % g, FW, FH, 3))
	empilha(cr).save_png(OUT + "fase7b1_poses_discipulo_x3.png")
	var cr1 := []
	for g in ["mt_idle", "low_kick", "knee", "thai_clinch", "spin_kick", "spar_mt_push", "spar_mt_kick", "spar_mt_guard"]:
		cr1.append(folha_crua(J + "fight/fight_player_%s_disc.png" % g, FW, FH, 1))
	for gl in ["_glove_l1", "_glove_l2", "_glove_l3", "_glove_l4"]:
		cr1.append(folha_crua(J + "fight/fight_player_low_kick%s_disc.png" % gl, FW, FH, 1))
	empilha(cr1).save_png(OUT + "fase7b1_poses_discipulo_x1.png")
	var ca := []
	for oid in OPPS:
		for act in ["hit_leg", "limp", "held_clinch", "hit_spin", "fall_spin"]:
			ca.append(folha_crua(opp_file(oid, act), FW, FH, 1))
	empilha(ca, 2).save_png(OUT + "fase7b1_poses_adversarios_x1.png")
	# 5) Choque do Muay Thai com o parceiro do Boxe
	var ch := []
	var part := R + "assets/sprites/minigame/spar_partner_box_idle.png"
	var rec := R + "assets/sprites/minigame/spar_partner_box_recoil.png"
	for g in [["spar_mt_push", 2], ["spar_mt_kick", 3]]:
		var pj := J + "fight/fight_player_%s_disc.png" % g[0]
		var fr := []
		for i in nfr(pj, FW):
			var r: int = i - int(g[1])
			fr.append(cena_choque(pj, i, rec if r >= 0 else part, maxi(r, 0)))
		ch.append(tira(fr, 2))
	var fg := []
	for i in 2:
		fg.append(cena_choque(J + "fight/fight_player_spar_mt_guard_disc.png", i, part, i))
	fg.append(cena_choque(J + "fight/fight_player_mt_idle_disc.png", 0, part, 0))
	ch.append(tira(fg, 2))
	empilha(ch).save_png(OUT + "fase7b1_poses_choque_x2.png")
	# 6) treino: chute baixo no saco comprido, garagem e academia, 3x
	var tr := []
	for lugar in [["garage/garage_bg.png", "kick_bag_l0"], ["gym/gym_bg.png", "kick_bag_l1"]]:
		var fr := []
		var pk := J + "characters/fighter_low_kick_disc.png"
		var hf: int = int(gm["fighter_low_kick_disc"].hit_frame)
		for i in nfr(pk, 64):
			fr.append(cena_saco(lugar[0], lugar[1], pk, i, i - hf))
		tr.append(tira(fr, 3))
	empilha(tr).save_png(OUT + "fase7b1_poses_treino_x3.png")
	antes_depois(gm)
	print("ok: pranchas em ", OUT)
	quit()


func cena_choque(pj: String, qj: int, pp: String, qp: int) -> Image:
	var bgp := R + "assets/sprites/minigame/spar_bg.png"
	var bg: Image = load_abs(bgp).duplicate()
	var b := frame(pp, qp)
	blend_at(bg, b, POS_O.x - PIV.x, POS_O.y - PIV.y)
	blend_at(bg, frame(pj, qj), POS_J.x - PIV.x, POS_J.y - PIV.y)
	return bg.get_region(CROP)


func cena_saco(bgrel: String, saco: String, pk: String, q: int, r: int) -> Image:
	var bgp := R + "assets/sprites/" + bgrel
	var bg: Image
	if FileAccess.file_exists(bgp):
		bg = load_abs(bgp).duplicate()
	else:
		bg = Image.create(640, 360, false, Image.FORMAT_RGBA8)
		bg.fill(Color8(70, 64, 80))
	var sp := R + "assets/sprites/equipment/%s_%s.png" % [saco, "hit" if r >= 0 else "idle"]
	var sb := frame(sp, maxi(r, 0), 34, 80)
	var chain := R + "assets/sprites/equipment/bag_chain_tile.png"
	blend_at(bg, sb, 336 - 17, 190)
	blend_at(bg, frame(pk, q, 64, 72), 303 - 22, 272 - 67)
	return bg.get_region(Rect2i(270, 180, 90, 100))


## Antes/depois: sem as folhas do Muay Thai o jogo cai no golpe antigo (jab -> hit; heavy -> hit) e no fighter_punch no saco.
func antes_depois(gm: Dictionary) -> void:
	var fr_a := []
	var fr_d := []
	var jab := R + "assets/sprites/fight/fight_player_jab_disc.png"
	var heavy := R + "assets/sprites/fight/fight_player_heavy_disc.png"
	var idle := R + "assets/sprites/fight/fight_player_idle_disc.png"
	var hit := opp_file("opp_gym_1", "hit")
	var oidle := opp_file("opp_gym_1", "idle")
	# antes: guarda, jab no contato, heavy no contato, idle dele (sem mancar), soco no saco
	fr_a.append(cena("arena_league", idle, 0, oidle, 0))
	fr_a.append(cena("arena_league", jab, 1, hit, 0))
	fr_a.append(cena("arena_league", heavy, 2, hit, 0))
	fr_a.append(cena("arena_league", heavy, 2, hit, 0))
	fr_a.append(cena("arena_league", idle, 0, oidle, 0))
	var lk := J + "fight/fight_player_low_kick_disc.png"
	var kn := J + "fight/fight_player_knee_disc.png"
	var sk := J + "fight/fight_player_spin_kick_disc.png"
	var mi := J + "fight/fight_player_mt_idle_disc.png"
	fr_d.append(cena("arena_league", mi, 0, oidle, 0))
	fr_d.append(cena("arena_league", lk, int(gm["fight_player_low_kick_disc"].hit_frame), opp_file("opp_gym_1", "hit_leg"), 1))
	fr_d.append(cena("arena_league", kn, int(gm["fight_player_knee_disc"].hit_frame), opp_file("opp_gym_1", "hit_body"), 1))
	fr_d.append(cena("arena_league", sk, int(gm["fight_player_spin_kick_disc"].hit_frame), opp_file("opp_gym_1", "fall_spin"), 0))
	fr_d.append(cena("arena_league", mi, 0, opp_file("opp_gym_1", "limp_heavy"), 0))
	# saco: antes = fighter_punch no contato; depois = fighter_low_kick no contato
	var sa := cena_saco_com("garage/garage_bg.png", "kick_bag_l0", R + "assets/sprites/characters/fighter_punch_disc.png", 2, 0, 48)
	var sd := cena_saco_com("garage/garage_bg.png", "kick_bag_l0", J + "characters/fighter_low_kick_disc.png", 2, 0, 64)
	for k in [1, 3]:
		var ta := tira(fr_a, k)
		var td := tira(fr_d, k)
		var im := Image.create(ta.get_width() + 4 + 90 * k, (122 * k) * 2 + 4, false, Image.FORMAT_RGBA8)
		im.fill(Color8(30, 26, 38))
		blend_at(im, ta, 0, 0)
		blend_at(im, td, 0, 122 * k + 4)
		blend_at(im, scaled(sa, k), ta.get_width() + 4, 0)
		blend_at(im, scaled(sd, k), ta.get_width() + 4, 122 * k + 4)
		im.save_png(OUT + "fase7b1_antes_depois_x%d.png" % k)


func cena_saco_com(bgrel: String, saco: String, pk: String, q: int, r: int, fw: int) -> Image:
	var bg: Image = load_abs(R + "assets/sprites/" + bgrel).duplicate()
	var sb := frame(R + "assets/sprites/equipment/%s_hit.png" % saco, r, 34, 80)
	blend_at(bg, sb, 336 - 17, 190)
	blend_at(bg, frame(pk, q, fw, 72), 303 - 22, 272 - 67)
	return bg.get_region(Rect2i(270, 190, 90, 122))
