extends SceneTree
## QA 6d3: folha de contato dos simbolos (peito vermelho, coxa azul) para olhar a orientacao do R.
func _initialize() -> void:
	var nomes := ["disciple_stand_bare", "disciple_stand_bare_left", "disciple_walk_bare", "disciple_walk_bare_left", "disciple_duck_under_left"]
	var _x := ["disciple_stand_bare", "disciple_stand_bare_left", "disciple_walk_bare", "disciple_walk_bare_left", "disciple_duck_under", "disciple_duck_under_left",
		"disciple_carry_bag_left", "disciple_take_gloves", "fight_player_idle", "fight_player_heavy", "fight_player_victory", "fight_player_ko", "fighter_idle", "mural_portrait", "portrait_player"]
	var Z := 6
	var RECORTE := Rect2i(0, 0, 192, 72)
	var linhas: Array = []
	var W := 0
	for n in nomes:
		var partes: Array = []
		for t in ["chest", "leg"]:
			var p := "res://assets/sprites/disciple/%s_disc_symbol_%s.png" % [n, t]
			if FileAccess.file_exists(p):
				var im := Image.load_from_file(p); im.convert(Image.FORMAT_RGBA8); partes.append([t, im])
		if partes.is_empty(): continue
		var base: Image = partes[0][1]
		var out := Image.create(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8)
		out.fill(Color(0.25, 0.25, 0.3))
		for pr in partes:
			var im: Image = pr[1]
			for y in im.get_height():
				for x in im.get_width():
					var c := im.get_pixel(x, y)
					if c.a > 0.1:
						out.set_pixel(x, y, Color(1, 0.3, 0.3) if pr[0] == "chest" else Color(0.4, 0.7, 1.0))
		out.resize(out.get_width() * Z / 2, out.get_height() * Z / 2, Image.INTERPOLATE_NEAREST) if false else null
		linhas.append([n, out]); W = maxi(W, out.get_width())
		print(n, " ", out.get_size())
	var H := 0
	for l in linhas: H += l[1].get_height() + 4
	var sheet := Image.create(144 * 8, H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	var y := 0
	for l in linhas:
		var im: Image = l[1]
		im = im.get_region(Rect2i(0, 0, mini(144, im.get_width()), im.get_height())); im.resize(im.get_width() * 8, im.get_height() * 8, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(0, y))
		y += im.get_height() + 4
	sheet.save_png("C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/simbolos2.png")
	print("sheet ", sheet.get_size())
	quit()
