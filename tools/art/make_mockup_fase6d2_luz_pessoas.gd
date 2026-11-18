extends SceneTree
## Fase 6d2 (Artista de Personagens): antes/depois da luz pintada da equipe (vizinhos, tios, Prof. Nelson) nos pontos novos.
## Rodar de uma pasta com project.godot vazio:
##   godot --headless --path <pasta_vazia> --script E:/Fightclicker/tools/art/make_mockup_fase6d2_luz_pessoas.gd -- <antes> <depois>
##   <antes>/<depois> = pastas com neighbor_1_idle.png ... coach_1_idle.png (saída do make_sprites_elenco.gd modo luz6d2).
## Fundo: docs/arte/mockups/fase6d2_fundo_garagem|academia.png (sala larga). Grava docs/arte/mockups/fase6d2_luz_pessoas_x2.png.

const ROOT := "E:/Fightclicker/"
const CREW := ["neighbor_1", "neighbor_2", "neighbor_3", "uncle_1", "uncle_2", "coach_1"]
const CROP := Rect2i(0, 168, 640, 164)
var L
var MAN := {}

func _load(p: String) -> Image:
	var img := Image.load_from_file(p)
	img.convert(Image.FORMAT_RGBA8)
	return img

func spr(id: String) -> Dictionary:
	return MAN.sprites.get(id, {})

func frame(sheet: Image, id: String, q: int) -> Image:
	var fw := int(spr(id).frame_size[0])
	return sheet.get_region(Rect2i(q * fw, 0, fw, int(spr(id).frame_size[1])))

func room(local: String, dir: String, q: int) -> Image:
	var im := _load(ROOT + "docs/arte/mockups/fase6d2_fundo_%s.png" % local)
	if local == "garagem":
		var lp := _load(ROOT + "assets/sprites/garage/lamp.png").get_region(Rect2i(0, 0, 29, 48))
		im.blend_rect(lp, Rect2i(Vector2i.ZERO, lp.get_size()), Vector2i(300 - 14, 32))
	var sh := _load(ROOT + "assets/sprites/garage/floor_shadow.png")
	var ids: Array = CREW.duplicate()
	ids.sort_custom(func(a, b): return int(spr(a).pos[1]) < int(spr(b).pos[1]))
	for id in ids:
		var e := spr(id)
		var pos := Vector2i(int(e.pos[0]), int(e.pos[1]))
		var piv := Vector2i(int(e.pivot[0]), int(e.pivot[1]))
		im.blend_rect(sh, Rect2i(Vector2i.ZERO, sh.get_size()), pos - Vector2i(16, 5))
		var f := frame(_load(dir + str(e.file).get_file()), id, q)
		im.blend_rect(f, Rect2i(Vector2i.ZERO, f.get_size()), pos - piv)
	return im

func scaled(img: Image, k: int) -> Image:
	var b: Image = img.duplicate()
	b.resize(img.get_width() * k, img.get_height() * k, Image.INTERPOLATE_NEAREST)
	return b

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var antes: String = args[0].trim_suffix("/") + "/"
	var depois: String = args[1].trim_suffix("/") + "/"
	L = load(ROOT + "tools/art/pixel_lib.gd").new()
	MAN = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/sprites/manifest.json"))
	var rows := []
	for local in ["garagem", "academia"]:
		for d in [["ANTES (luz do ponto antigo)", antes], ["DEPOIS (luz do ponto novo)", depois]]:
			rows.append([local.to_upper() + " - " + d[0], room(local, d[1], 0).get_region(CROP)])
	# close-ups 3x de cada pessoa, antes | depois, na garagem e na academia (recorte 56x80 em volta do ponto)
	var closes := []
	for local in ["garagem", "academia"]:
		var ra := room(local, antes, 0)
		var rd := room(local, depois, 0)
		for id in CREW:
			var e := spr(id)
			var r := Rect2i(clampi(int(e.pos[0]) - 28, 0, 640 - 56), int(e.pos[1]) - 74, 56, 80)
			closes.append([local, id, ra.get_region(r), rd.get_region(r)])
	var W := CROP.size.x * 2 + 16
	var H := 8 + rows.size() * (CROP.size.y * 2 + 22) + 4 * (80 * 3 + 18) + 2 * 12 + 10
	var out: Image = L.blank(W, H)
	L.R(out, 0, 0, W, H, "d1")
	var y := 8
	for r in rows:
		L.text(out, r[0], 8, y, "y1", 1, "ink")
		y += 12
		out.blit_rect(scaled(r[1], 2), Rect2i(0, 0, CROP.size.x * 2, CROP.size.y * 2), Vector2i(8, y))
		y += CROP.size.y * 2 + 10
	for li in 2:
		L.text(out, "%s 3x: ANTES | DEPOIS (quadro 0)" % ["GARAGEM", "ACADEMIA"][li], 8, y, "y1", 1, "ink")
		y += 12
		var lst := closes.filter(func(c): return c[0] == ["garagem", "academia"][li])
		for k in lst.size():
			var c: Array = lst[k]
			var x := 8 + (k % 3) * (170 * 2 + 70)
			out.blit_rect(scaled(c[2], 3), Rect2i(0, 0, 168, 240), Vector2i(x, y))
			out.blit_rect(scaled(c[3], 3), Rect2i(0, 0, 168, 240), Vector2i(x + 170, y))
			if k % 3 == 2:
				y += 240 + 18
	out.save_png(ROOT + "docs/arte/mockups/fase6d2_luz_pessoas_x2.png")
	print("ok ", out.get_size())
	quit()
