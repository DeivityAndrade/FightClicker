extends SceneTree
## Fase 5.2 — Luva L4 ("Luva de competição": azul b1/b2/b3, punho branco largo, friso e selo dourados).
## Fonte da verdade dos itens de UI da L4, no mesmo desenho/tamanho dos da L1–L3 (make_sprites_fase3.gd, make_gloves):
##   equipment/glove_l4.png (12x13), ui/cursor_glove_l4.png (+ _normal/_pressed _x2/_x3), ui/icon_glove_l4.png (16x16),
##   ui/art_hung_glove_l4.png (48x56).
## As folhas da sala e da luta (_glove_l4) saem de make_sprites_jogador.gd e make_golpes_jogador.gd (estilo "campeao"
## em personagem_lib.gd) — mesmas cores e detalhes desta UI.
## Rodar headless a partir de uma pasta temporária com um project.godot vazio (nunca no projeto):
##   godot --headless --path <pasta_tmp> --script <repo>/tools/art/make_luva_l4.gd -- <saida> [contato]
##   <saida>/equipment, <saida>/ui  e  <saida>/luva_l4_manifest.json (entradas prontas para o manifest)
##   "contato" = só monta docs/arte/mockups/fase52_luvas_x3.png (L1–L4 lado a lado) lendo assets/sprites/.

var ROOT := OS.get_environment("FIGHTCLICKER_ROOT") if OS.get_environment("FIGHTCLICKER_ROOT") != "" else "E:/Fightclicker/"
const RES := "res://assets/sprites/"
const GID := "glove_l4"
const NAME := "Luva de competição"
const RAMP := ["b1", "b2", "b3"]

var L
var out_dir := ""
var M := {}


## Luva solta, mesma construção de make_sprites_fase3.gd (draw_glove) com o estilo da L4.
## back = mão de trás (um tom abaixo).
func draw_glove(img: Image, x: int, y: int, w: int, h: int, back := false) -> void:
	var ramp: Array = RAMP
	if back:
		ramp = [L.shade(L.col(RAMP[0]), -1), RAMP[0], RAMP[1]]
	L.glove(img, x, y, w, h, ramp)
	var gold := "y0" if back else "y1"
	# punho branco largo com sombra embaixo e friso dourado em cima (como o punho das mãos na sala/luta)
	L.R(img, x + 1, y + h - 3, w - 2, 1, gold)
	L.R(img, x + 1, y + h - 2, w - 2, 1, "cream" if back else "white")
	L.R(img, x + 1, y + h - 1, w - 2, 1, "g2" if back else "g3")
	# selo dourado no lado do polegar (no lugar da fita da luva velha)
	var sz := 2 if w >= 12 else 1
	L.R(img, x + 3, y + 3, sz, sz, gold)
	# brilho do couro sintético (a L4 é a única luva com brilho branco na quina)
	if not back and w >= 10:
		L.P(img, x + w - 3, y + 2, "white")


func glove_small(w: int, h: int, pressed := false) -> Image:
	var g: Image = L.blank(w, h)
	if pressed:
		draw_glove(g, 0, 1, w, h - 1)
	else:
		draw_glove(g, 0, 0, w, h)
	return g


func save(id: String, rel: String, frames: Array, pivot: Vector2i, info := {}) -> void:
	var s: Image = L.blank(frames[0].get_width() * frames.size(), frames[0].get_height())
	for i in frames.size():
		s.blend_rect(frames[i], Rect2i(Vector2i.ZERO, frames[i].get_size()), Vector2i(i * frames[0].get_width(), 0))
	DirAccess.make_dir_recursive_absolute((out_dir + rel).get_base_dir())
	s.save_png(out_dir + rel)
	var e := {"file": RES + rel, "frame_size": [frames[0].get_width(), frames[0].get_height()],
		"frames": frames.size(), "fps": 0, "pivot": [pivot.x, pivot.y]}
	for k in info:
		e[k] = info[k]
	M[id] = e


func make_items() -> void:
	save(GID, "equipment/%s.png" % GID, [L.outlined(glove_small(10, 11))], Vector2i(6, 6), {
		"note": "%s: item 12x13 (mesmo tamanho do glove_old). Mesma arte das mãos (garagem e luta) e do cursor." % NAME})
	var frames := []
	for pr in [false, true]:
		frames.append(L.outlined(L.outlined(glove_small(10, 10, pr), "white"), "ink"))
	save("cursor_" + GID, "ui/cursor_%s.png" % GID, frames, Vector2i(7, 6), {"hotspot": [7, 6],
		"frames_note": "0 normal, 1 pressionado.", "note": "Cursor-luva da %s (igual ao cursor_glove da luva velha)." % NAME})
	for s in [2, 3]:
		for i in 2:
			var b: Image = frames[i].duplicate()
			b.resize(b.get_width() * s, b.get_height() * s, Image.INTERPOLATE_NEAREST)
			var st := "normal" if i == 0 else "pressed"
			var rel := "ui/cursor_%s_%s_x%d.png" % [GID, st, s]
			b.save_png(out_dir + rel)
			M["cursor_%s_%s_x%d" % [GID, st, s]] = {"file": RES + rel, "frame_size": [b.get_width(), b.get_height()], "frames": 1, "fps": 0,
				"pivot": [7 * s, 6 * s], "hotspot": [7 * s, 6 * s], "note": "Cursor do sistema já ampliado %dx (Input.set_custom_mouse_cursor)." % s}
	var ic: Image = L.blank(16, 16)
	L.stamp(ic, glove_small(11, 12), 3, 2)
	save("icon_" + GID, "ui/icon_%s.png" % GID, [ic], Vector2i.ZERO, {"note": "Ícone 16x16 da %s para a LOJA (cartão do item)." % NAME})
	var hg: Image = L.blank(48, 56)
	L.R(hg, 23, 2, 3, 3, "st2"); L.P(hg, 23, 2, "st3"); L.R(hg, 24, 5, 1, 2, "st0")
	var gb: Image = L.blank(20, 24)
	draw_glove(gb, 0, 0, 16, 18, true)
	var gf: Image = L.blank(20, 24)
	draw_glove(gf, 0, 0, 16, 18, false)
	L.line(hg, 24, 5, 14, 30, "cream"); L.line(hg, 24, 5, 32, 32, "g3")
	L.stamp(hg, gb, 25, 31)
	L.stamp(hg, gf, 7, 28)
	save("art_hung_" + GID, "ui/art_hung_%s.png" % GID, [hg], Vector2i(24, 2), {
		"note": "Luvas penduradas no prego pelo cadarço ('pendurar as luvas'): ilustração da tela SAIU POR CIMA e da confirmação de aposentar. Usar a da luva equipada."})
	var f := FileAccess.open(out_dir + "luva_l4_manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(M, "\t"))
	f.close()


# ================================================================ folha de contato L1–L4 (lê assets/sprites)
func img(rel: String) -> Image:
	var im := Image.load_from_file(ROOT + "assets/sprites/" + rel)
	im.convert(Image.FORMAT_RGBA8)
	return im

func frame(rel: String, fw: int, i: int) -> Image:
	var s := img(rel)
	return s.get_region(Rect2i(fw * i, 0, fw, s.get_height()))

func checker(dst: Image, x: int, y: int, w: int, h: int) -> void:
	for yy in range(0, h, 4):
		for xx in range(0, w, 4):
			L.R(dst, x + xx, y + yy, mini(4, w - xx), mini(4, h - yy), "g1" if ((xx / 4 + yy / 4) % 2 == 0) else "g0")

func put(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i(x, y))

func contact() -> void:
	var gloves := [["glove_l1", "L1 LONA"], ["glove_l2", "L2 COURO"], ["glove_l3", "L3 MARCA"], ["glove_l4", "L4 COMPETICAO"]]
	# colunas: item, ícone, cursor (normal/pressionado), pendurada, sala (soco, corda), luta (guarda, jab, gancho, bloqueio, KO)
	var cw := 470
	var W := 8 + cw * gloves.size()
	var H := 206
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	L.text(out, "FASE 5.2 - LUVAS L1 A L4 (a mesma luva no item, icone, cursor, pendurada, sala e luta)", 6, 3, "y1", 1, "ink")
	var gi := 0
	for g in gloves:
		var gid: String = g[0]
		var suf: String = "_" + gid
		var x0 := 6 + gi * cw
		L.R(out, x0 - 3, 14, 1, H - 16, "d2")
		L.text(out, g[1], x0, 16, "white" if gid == GID else "cream", 1, "ink")
		# UI
		checker(out, x0, 28, 74, 78)
		put(out, img("equipment/%s.png" % gid), x0 + 2, 30)
		put(out, img("ui/icon_%s.png" % gid), x0 + 16, 30)
		put(out, frame("ui/cursor_%s.png" % gid, 14, 0), x0 + 34, 30)
		put(out, frame("ui/cursor_%s.png" % gid, 14, 1), x0 + 50, 30)
		put(out, img("ui/art_hung_%s.png" % gid), x0 + 13, 48)
		# sala 48x72
		var xs := x0 + 78
		for pr in [["fighter_punch", 48, 2], ["fighter_hook", 48, 2], ["fighter_rope", 48, 1]]:
			var e := frame("characters/%s%s.png" % [pr[0], suf], int(pr[1]), int(pr[2]))
			checker(out, xs, 28, e.get_width(), e.get_height())
			put(out, e, xs, 28)
			xs += e.get_width() + 2
		# luta 112x104 recortada
		var row2 := [["fight_player_idle", 0], ["fight_player_jab", 1], ["fight_player_hook", 2], ["fight_player_block", 1], ["fight_player_ko", 4]]
		var xf := x0
		for pr in row2:
			var fr := frame("fight/%s%s.png" % [pr[0], suf], 112, int(pr[1]))
			var reg := fr.get_region(Rect2i(14, 14, 86, 88))
			checker(out, xf, 114, 86, 88)
			put(out, reg, xf, 114)
			xf += 90
		gi += 1
	var b: Image = out.duplicate()
	b.resize(W * 3, H * 3, Image.INTERPOLATE_NEAREST)
	b.save_png(ROOT + "docs/arte/mockups/fase52_luvas_x3.png")


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	L = load(get_script().resource_path.get_base_dir() + "/pixel_lib.gd").new()
	if "contato" in args:
		contact()
	else:
		out_dir = args[0].trim_suffix("/") + "/"
		make_items()
	print("ok")
	quit()
