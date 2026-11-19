extends SceneTree
## QA 7a1: folhas do jogador de Jiu-jitsu em camadas (clinch, queda, chao, pressao, finalizacao) com 4 visuais bem diferentes.
## Confere por codigo: toda camada existe e tem pixels; o visual muda a textura; o simbolo R aparece no peito. Grava uma folha de contato
## em PASTA TEMPORARIA (argumento --out=...), nunca em docs/arte.
## godot --headless --path . --script res://tests/qa_f7a1_folhas.gd -- --out=C:\caminho\

const POSES := ["clinch_push", "takedown", "ground_top_idle", "ground_pressure", "submission", "ground_top_hit"]
const LOOKS := [
	{"skin": "skin_1", "hair_color": "platinum", "hair_style": "buzz", "shorts_color": "white", "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_5", "hair_color": "black", "hair_style": "bun", "shorts_color": "purple", "top": "tank", "top_color": "black", "headband": "band", "headband_color": "blue", "socks": "on"},
	{"skin": "skin_3", "hair_color": "blond", "hair_style": "volume", "shorts_color": "yellow", "top": "tee", "top_color": "green", "headband": "band", "headband_color": "red", "socks": "none"},
	{"skin": "skin_2", "hair_color": "copper", "hair_style": "short", "shorts_color": "blue", "top": "tee", "top_color": "white", "headband": "band", "headband_color": "green", "socks": "on"},
]
var falhas := 0


func ok(c: bool, m: String) -> void:
	if not c:
		falhas += 1
	print(("PASS  " if c else "FAIL  ") + m)


func _initialize() -> void:
	await process_frame
	var out := "user://test/"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var UT: GDScript = load("res://ui/ui_tema.gd")
	var DV: GDScript = load("res://ui/disc_visual.gd")
	var man: Dictionary = UT.manifest()
	var S: Dictionary = man.sprites
	var fw := 112
	var fh := 104
	var colunas := []
	for p in POSES:
		var nome := "fight_player_%s_disc_layered" % p
		ok(S.has(nome), "manifest tem %s" % nome)
		if not S.has(nome):
			continue
		var s: Dictionary = S[nome]
		var L: Dictionary = s.layers
		var arquivos := []
		for k in L:
			if k == "order":
				continue
			var v = L[k]
			if v is String:
				arquivos.append(v)
			elif v is Dictionary:
				for k2 in v:
					arquivos.append(str(v[k2]))
		var faltam := []
		for f in arquivos:
			if not ResourceLoader.exists(f):
				faltam.append(f)
		ok(faltam.is_empty(), "%s: %d arquivos de camada existem (faltam %s)" % [nome, arquivos.size(), str(faltam)])
		# imagens do mesmo tamanho do corpo
		var corpo: Image = (load(str(L.body)) as Texture2D).get_image()
		var tam_ruim := []
		for f in arquivos:
			if ResourceLoader.exists(f):
				var im: Image = (load(f) as Texture2D).get_image()
				if im.get_size() != corpo.get_size():
					tam_ruim.append("%s %s" % [f.get_file(), str(im.get_size())])
		ok(tam_ruim.is_empty(), "%s: camadas do mesmo tamanho do corpo %s (%s)" % [nome, str(corpo.get_size()), str(tam_ruim)])
		var n := int(s.frames)
		colunas.append({"nome": nome, "frames": n})
	# folhas de contato: 2 arquivos (3 poses cada); linhas = looks, colunas = primeiro / meio / ultimo quadro de cada pose (com simbolo R)
	DirAccess.make_dir_recursive_absolute(out)
	for parte in 2:
		var folha := Image.create(9 * fw, LOOKS.size() * fh, false, Image.FORMAT_RGBA8)
		folha.fill(Color(0.35, 0.45, 0.35, 1.0))
		for li in LOOKS.size():
			var look: Dictionary = LOOKS[li]
			var ci := 0
			for pi in range(parte * 3, parte * 3 + 3):
				if pi >= colunas.size():
					continue
				var c: Dictionary = colunas[pi]
				var tx: Texture2D = DV.textura(c.nome, look, true)
				var tx_sem: Texture2D = DV.textura(c.nome, look, false)
				var im: Image = tx.get_image()
				im.convert(Image.FORMAT_RGBA8)
				var im2: Image = tx_sem.get_image()
				im2.convert(Image.FORMAT_RGBA8)
				var n: int = c.frames
				ok(im.get_width() == n * fw, "%s look %d: largura da folha %d = %d quadros" % [c.nome, li, im.get_width(), n])
				var dif := 0
				for y in im.get_height():
					for x in im.get_width():
						if im.get_pixel(x, y) != im2.get_pixel(x, y):
							dif += 1
				print("    %s look %d: pixels do simbolo R (com - sem): %d" % [c.nome, li, dif])
				for q in [0, n / 2, n - 1]:
					var recorte := im.get_region(Rect2i(q * fw, 0, fw, fh))
					folha.blend_rect(recorte, Rect2i(0, 0, fw, fh), Vector2i(ci * fw, li * fh))
					ci += 1
		var big := folha.duplicate() as Image
		big.resize(folha.get_width() * 2, folha.get_height() * 2, Image.INTERPOLATE_NEAREST)
		big.save_png(out.path_join("folhas_jj_%d.png" % parte))
		print("folha gravada: %s" % out.path_join("folhas_jj_%d.png" % parte))
	print("%d falhas" % falhas)
	quit(1 if falhas > 0 else 0)
