extends SceneTree
## Fase 8a1 (Artista de Personagens): folha de conferência dos 4 adversários da liga regional.
## Rodar a partir de uma pasta com project.godot vazio, depois do modo "regional" do make_sprites_elenco.gd:
##   godot --headless --path <tmp_proj> --script <repo>/tools/art/make_mockup_fase8a1_personagens.gd -- <repo> <out_regional> <saida.png>
## Lê as folhas de <out_regional> (ou do projeto, se já copiadas) e o lutador do projeto. Não grava nada além de <saida.png>.
## Seções: (1) todos lado a lado com o lutador, 1x e 3x; (2) cada um: guarda, assinatura, golpes, queda, 2x;
## (3) o sinal na luta: golpe do jogador + assinatura deles na arena, 2x; (4) James: guarda fechada, bloqueio, desprezo,
## retratos (HUD 32x32 em 3x e diálogo 48x48 em 2x).

const FW := 112
const FH := 104
const PIV := Vector2i(56, 98)
const POS_J := Vector2i(296, 318)
const POS_O := Vector2i(346, 318)
const CROP := Rect2i(226, 196, 196, 126)
const OPPS := ["opp_reg_1", "opp_reg_2", "opp_reg_3", "opp_james"]
const NOMES := {"opp_reg_1": "ZE BIGORNA - QUEIXO DURO", "opp_reg_2": "TIAO ESTACA - PE DE CIMENTO",
	"opp_reg_3": "RONY SABAO - O ESCORREGA", "opp_james": "JAMES BLINDADO"}
const ASSIN := {"opp_reg_1": "shake_head", "opp_reg_2": "plant_feet", "opp_reg_3": "slip_clinch", "opp_james": "scorn"}
## sinal na luta: golpe do jogador (discípulo) que dispara a assinatura, a partir do contato
const SINAL := {"opp_reg_1": ["fight_player_uppercut_disc", 4], "opp_reg_2": ["fight_player_takedown_disc", 3],
	"opp_reg_3": ["fight_player_thai_clinch_disc", 2], "opp_james": ["fight_player_jab_disc", 1]}

var R := ""
var O := ""
var L
var cache := {}


func load_abs(p: String) -> Image:
	if cache.has(p):
		return cache[p]
	var img := Image.load_from_file(p)
	img.convert(Image.FORMAT_RGBA8)
	cache[p] = img
	return img


func opp_file(oid: String, act: String) -> String:
	var p := O + "opponents/%s/%s_%s.png" % [oid, oid, act]
	if FileAccess.file_exists(p):
		return p
	return R + "assets/sprites/opponents/%s/%s_%s.png" % [oid, oid, act]


func nfr(path: String, fw := FW) -> int:
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


func checker(w: int, h: int) -> Image:
	var im := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			im.set_pixel(x, y, L.col("d2") if ((x / 4 + y / 4) % 2 == 0) else L.col("d1"))
	return im


## Recorte justo de um quadro (sem as bordas vazias de cima e dos lados), mantendo o chão.
func tira(path: String, quadros: Array, k: int, top := 12, lx := 18, rx := 94) -> Image:
	var w := rx - lx
	var h := FH - top
	var out := Image.create((w * k + 2) * quadros.size(), h * k, false, Image.FORMAT_RGBA8)
	var i := 0
	for q in quadros:
		var c := checker(w * k, h * k)
		var f := frame(path, q).get_region(Rect2i(lx, top, w, h))
		blend_at(c, scaled(f, k), 0, 0)
		out.blit_rect(c, Rect2i(0, 0, c.get_width(), c.get_height()), Vector2i(i * (w * k + 2), 0))
		i += 1
	return out


func cena(pj: String, qj: int, po: String, qo: int, j_top := true) -> Image:
	var bg: Image = load_abs(R + "assets/sprites/fight/arena_regional_bg.png").duplicate()
	var a := frame(pj, qj)
	var b := frame(po, qo)
	if j_top:
		blend_at(bg, b, POS_O.x - PIV.x, POS_O.y - PIV.y)
		blend_at(bg, a, POS_J.x - PIV.x, POS_J.y - PIV.y)
	else:
		blend_at(bg, a, POS_J.x - PIV.x, POS_J.y - PIV.y)
		blend_at(bg, b, POS_O.x - PIV.x, POS_O.y - PIV.y)
	return bg.get_region(CROP)


var folha: Image
var cy := 0


func titulo(s: String, k := 2) -> void:
	L.text(folha, s, 8, cy, L.col("y1"), k, L.col("ink"))
	cy += 8 * k + 6


func cola(im: Image, x := 8) -> void:
	if cy + im.get_height() > folha.get_height():
		return
	blend_at(folha, im, x, cy)
	cy += im.get_height() + 8


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	R = a[0].trim_suffix("/") + "/"
	O = a[1].trim_suffix("/") + "/"
	var saida: String = a[2]
	L = load(R + "tools/art/pixel_lib.gd").new()
	folha = Image.create(1700, 5600, false, Image.FORMAT_RGBA8)
	folha.fill(L.col("ink"))
	cy = 8
	titulo("FASE 8A1 - LIGA REGIONAL: ADVERSARIOS NO RIG COMUM (CONFERENCIA)", 3)
	L.text(folha, "Quadro 112x104, pivo (56,98), virados para a esquerda. Lutador (discipulo) a esquerda para comparar altura e silhueta.", 8, cy, L.col("g3"), 1)
	cy += 16

	# (1) lado a lado: lutador + 4, guarda (quadro 0), 1x e 3x, mesmo chão
	titulo("1. TODOS LADO A LADO (GUARDA) - 3X E 1X")
	var pl := R + "assets/sprites/fight/fight_player_idle_disc.png"
	var linha := Image.create(76 * 5 * 3 + 40, 92 * 3, false, Image.FORMAT_RGBA8)
	linha.fill(L.col("d1"))
	var lin1 := Image.create(76 * 5 + 10, 92, false, Image.FORMAT_RGBA8)
	lin1.fill(L.col("d1"))
	var quem := [pl] + OPPS.map(func(o): return opp_file(o, "idle"))
	for i in quem.size():
		var f := frame(quem[i], 0).get_region(Rect2i(18, 12, 76, 92))
		blend_at(linha, scaled(f, 3), i * (76 * 3 + 8), 0)
		blend_at(lin1, f, i * 78, 0)
	cola(linha)
	cola(lin1)
	var gx := 8
	for nm in ["LUTADOR", "BIGORNA 1,02", "ESTACA 1,08", "SABAO 1,00", "JAMES 1,12"]:
		L.text(folha, nm, gx, cy - 8 - 92 - 8 - 16, L.col("white"), 2, L.col("ink"))
		gx += 76 * 3 + 8

	# (2) cada um: guarda, assinatura, golpes, queda
	for oid in OPPS:
		titulo("2. " + NOMES[oid])
		var acts := ["idle", ASSIN[oid]]
		if oid == "opp_james":
			acts = ["guard", "idle", "scorn", "block"]
		for act in acts:
			var p := opp_file(oid, act)
			L.text(folha, act.to_upper() + " (%d)" % nfr(p), 8, cy, L.col("g3"), 1)
			cy += 10
			var qs := range(nfr(p))
			cola(tira(p, qs, 2))
		L.text(folha, "JAB / HEAVY (CONTATO) / HIT_BODY / FALL / KO (FIM) / VICTORY / TIRED", 8, cy, L.col("g3"), 1)
		cy += 10
		var misto := Image.create(1690, (FH - 12) * 2, false, Image.FORMAT_RGBA8)
		var x := 0
		for par in [["jab", 1], ["heavy", 2], ["hit_body", 2], ["fall", 5], ["ko", 4], ["victory", 1], ["tired", 0]]:
			var t := tira(opp_file(oid, par[0]), [par[1]], 2)
			blend_at(misto, t, x, 0)
			x += t.get_width() + 4
		cola(misto)

	# (3) o sinal na luta: golpe do jogador + assinatura, na arena, 2x
	titulo("3. O SINAL NA LUTA (GOLPE DO JOGADOR + ASSINATURA DELE, ARENA REGIONAL, 2X)")
	for oid in OPPS:
		var sp: String = R + "assets/sprites/fight/" + SINAL[oid][0] + ".png"
		var hit: int = SINAL[oid][1]
		var po := opp_file(oid, ASSIN[oid])
		var n := nfr(po)
		var passo := 1 if n <= 7 else 2
		var cenas := []
		var q := 0
		while q < n:
			cenas.append(cena(sp, mini(hit + q, nfr(sp) - 1), po, q, oid != "opp_reg_2"))
			q += passo
		var w := CROP.size.x * 2 + 4
		var tir := Image.create(mini(w * cenas.size(), 1690), CROP.size.y * 2, false, Image.FORMAT_RGBA8)
		for i in cenas.size():
			if i * w + CROP.size.x * 2 <= tir.get_width():
				blend_at(tir, scaled(cenas[i], 2), i * w, 0)
		L.text(folha, NOMES[oid] + ": " + ASSIN[oid], 8, cy, L.col("g3"), 1)
		cy += 10
		cola(tir)

	# (4) retratos
	titulo("4. RETRATOS: HUD 32X32 (3X) E DIALOGO DO JAMES 48X48 (2X: SMIRK / SNEER / LAUGH)")
	var rx := 8
	for oid in OPPS:
		var pp := O + "opponents/portrait_%s.png" % oid
		var im := load_abs(pp)
		blend_at(folha, scaled(im, 3), rx, cy)
		rx += 32 * 3 + 8
	var dlg := load_abs(O + "opponents/portrait_opp_james_dialog.png")
	var fundo := Image.create(dlg.get_width() * 2, dlg.get_height() * 2, false, Image.FORMAT_RGBA8)
	fundo.fill(L.col("d2"))
	blend_at(fundo, scaled(dlg, 2), 0, 0)
	blend_at(folha, fundo, rx + 16, cy)
	blend_at(folha, dlg, rx + 16 + fundo.get_width() + 16, cy)
	cy += maxi(96, fundo.get_height()) + 12

	var final := folha.get_region(Rect2i(0, 0, 1700, mini(cy + 8, folha.get_height())))
	final.save_png(saida)
	print("ok: ", saida, " ", final.get_size())
	quit()
