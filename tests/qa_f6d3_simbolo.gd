extends SceneTree
## QA 6d3: confere a orientacao do R nas camadas do peito/coxa de todas as poses (nenhum glifo espelhado).
func _alpha_cols(img: Image) -> Array:
	var cols: Array = []
	for x in img.get_width():
		var any := false
		for y in img.get_height():
			if img.get_pixel(x, y).a > 0.1:
				any = true
				break
		cols.append(any)
	return cols
func _crop_bbox(img: Image, x0: int, x1: int) -> Image:
	var minx := 9999; var maxx := -1; var miny := 9999; var maxy := -1
	for x in range(x0, x1):
		for y in img.get_height():
			if img.get_pixel(x, y).a > 0.1:
				minx = mini(minx, x); maxx = maxi(maxx, x); miny = mini(miny, y); maxy = maxi(maxy, y)
	return img.get_region(Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1))
func _bits(img: Image) -> String:
	var s := ""
	for y in img.get_height():
		for x in img.get_width():
			s += "#" if img.get_pixel(x, y).a > 0.1 else "."
		s += "/"
	return s
func _flip(img: Image) -> Image:
	var c := img.duplicate()
	c.flip_x()
	return c
func _initialize() -> void:
	var ref5 := Image.load_from_file("res://assets/sprites/ui/school_symbol_5.png")
	print("ref5 ", _bits(ref5))
	var ref9 := Image.load_from_file("res://assets/sprites/ui/school_symbol_9.png")
	var d := DirAccess.open("res://assets/sprites/disciple/")
	var nomes: Array = []
	for f in d.get_files():
		if f.ends_with("symbol_chest.png") or f.ends_with("symbol_leg.png"):
			nomes.append(f)
	nomes.sort()
	var ruins := 0
	var resumo := {}
	for f in nomes:
		var img := Image.load_from_file("res://assets/sprites/disciple/" + f)
		img.convert(Image.FORMAT_RGBA8)
		var cols := _alpha_cols(img)
		var grupos: Array = []
		var ini := -1
		for x in cols.size():
			if cols[x] and ini < 0: ini = x
			if (not cols[x] or x == cols.size() - 1) and ini >= 0:
				grupos.append([ini, x if not cols[x] else x + 1]); ini = -1
		var assin := {}
		for g in grupos:
			var c := _crop_bbox(img, g[0], g[1])
			assin[_bits(c)] = assin.get(_bits(c), 0) + 1
		resumo[f] = assin
		print(f, " grupos=", grupos.size(), " distintos=", assin.size())
	# Imprime os padroes distintos por tipo (chest/leg, right/left)
	var padroes := {}
	for f in resumo:
		var tipo := ("leg" if f.ends_with("leg.png") else "chest") + ("_L" if "_left_" in f else "_R")
		for b in resumo[f]:
			if not padroes.has(tipo): padroes[tipo] = {}
			padroes[tipo][b] = padroes[tipo].get(b, 0) + resumo[f][b]
	for t in padroes:
		print("== ", t, " ", padroes[t].size(), " padroes distintos")
		var ks: Array = padroes[t].keys()
		ks.sort_custom(func(a, b): return padroes[t][a] > padroes[t][b])
		for k in ks.slice(0, 4):
			print(padroes[t][k], "x  ", k)
	quit()
