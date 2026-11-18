extends SceneTree
## QA 6d item 1 (auditoria de arquivo): toda folha em camadas do discipulo tem todas as camadas, do mesmo tamanho, com pixels.
## Tambem: toda folha "_disc" tem a "_disc_layered"; o visual muda a textura (camada realmente desenhada).
## godot --headless --path . --script res://tests/qa_f6d_camadas.gd   (APPDATA temporario)
var falhas := 0

func caminhos(o: Variant) -> Array:
	var r: Array = []
	if o is String:
		r.append(o)
	elif o is Dictionary:
		for v in o.values():
			r.append_array(caminhos(v))
	return r

func opacos(img: Image) -> int:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				n += 1
	return n

func img_de(c: String) -> Image:
	var t := load(c) as Texture2D
	if t == null:
		return null
	var i := t.get_image()
	i.convert(Image.FORMAT_RGBA8)
	return i

func _initialize() -> void:
	var gs = root.get_node("GameState")
	await process_frame
	var UT: GDScript = load("res://ui/ui_tema.gd")
	var DV: GDScript = load("res://ui/disc_visual.gd")
	var man: Dictionary = UT.manifest()
	var S: Dictionary = man.sprites
	var vazias := []
	var tam := []
	var faltam := []
	var n := 0
	for k in S:
		var s: Dictionary = S[k]
		if not s.has("layers") or not (s.layers is Dictionary):
			continue
		n += 1
		var L: Dictionary = s.layers
		var corpo := img_de(str(L.get("body", "")))
		if corpo == null:
			faltam.append(k + ":body")
			continue
		var tem_tank := true
		for grupo in ["head", "top", "school_symbol"]:
			pass
		for nome in ["band", "front_mask", "socks"]:
			var c := str(L.get(nome, ""))
			if c == "" or not ResourceLoader.exists(c):
				faltam.append("%s:%s" % [k, nome]); continue
			var im := img_de(c)
			if im.get_size() != corpo.get_size(): tam.append("%s:%s %s vs %s" % [k, nome, im.get_size(), corpo.get_size()])
			if opacos(im) == 0: vazias.append("%s:%s" % [k, nome])
		for grupo in ["head", "top", "school_symbol"]:
			var d = L.get(grupo, {})
			if not (d is Dictionary) or d.is_empty():
				faltam.append("%s:%s(grupo)" % [k, grupo]); continue
			for id in d:
				var c := str(d[id])
				if not ResourceLoader.exists(c):
					faltam.append("%s:%s.%s" % [k, grupo, id]); continue
				var im := img_de(c)
				if im.get_size() != corpo.get_size(): tam.append("%s:%s.%s %s vs %s" % [k, grupo, id, im.get_size(), corpo.get_size()])
				if opacos(im) == 0: vazias.append("%s:%s.%s" % [k, grupo, id])
	print("folhas em camadas: ", n)
	print("FALTAM arquivos/grupos: ", faltam.size(), " ", faltam.slice(0, 40))
	print("TAMANHO diferente: ", tam.size(), " ", tam.slice(0, 40))
	print("CAMADAS VAZIAS: ", vazias.size())
	for v in vazias:
		print("  vazia ", v)
	# o visual muda a textura: para cada folha, topo/faixa/meiao/simbolo mudam pixels
	var base: Dictionary = gs.disciples.look_padrao.duplicate()
	var sem_efeito := {"top": [], "band": [], "socks": [], "symbol_chest": [], "symbol_leg": [], "head": []}
	for k in S:
		var s: Dictionary = S[k]
		if not s.has("layers"):
			continue
		var t0: Texture2D = DV.textura(k, base, false)
		var h0: int = hash(t0.get_image().get_data())
		var l1 := base.duplicate(); l1.top = "tank"
		if hash(DV.textura(k, l1, false).get_image().get_data()) == h0: sem_efeito.top.append(k)
		var l2 := base.duplicate(); l2.headband = "band"; l2.headband_color = "yellow"
		if hash(DV.textura(k, l2, false).get_image().get_data()) == h0: sem_efeito.band.append(k)
		var l3 := base.duplicate(); l3.socks = "on"; l3.shorts_color = "purple"
		if hash(DV.textura(k, l3, false).get_image().get_data()) == h0: sem_efeito.socks.append(k)
		var l4 := base.duplicate(); l4.top = "tank"
		var a: int = hash(DV.textura(k, l4, false).get_image().get_data())
		if hash(DV.textura(k, l4, true).get_image().get_data()) == a: sem_efeito.symbol_chest.append(k)
		if hash(DV.textura(k, base, true).get_image().get_data()) == h0: sem_efeito.symbol_leg.append(k)
		var cortes := {}
		for c in ["buzz", "short", "volume", "bun"]:
			var l5 := base.duplicate(); l5.hair_style = c
			cortes[hash(DV.textura(k, l5, false).get_image().get_data())] = 1
		if cortes.size() < 4: sem_efeito.head.append(k)
	for g in sem_efeito:
		print("SEM EFEITO ", g, ": ", sem_efeito[g].size(), " ", sem_efeito[g].slice(0, 60))
	quit(0)
