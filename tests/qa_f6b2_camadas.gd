extends SceneTree
## QA 6b2: encaixe das camadas em todas as folhas do discipulo (headless). Escreve contact sheets em OUT.
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/camadas/"
var falhas := 0
var UT: GDScript
var DV: GDScript


func _init() -> void:
	_main.call_deferred()


func _main() -> void:
	UT = load("res://ui/ui_tema.gd")
	DV = load("res://ui/disc_visual.gd")
	DirAccess.make_dir_recursive_absolute(OUT)
	var man: Dictionary = UT.manifest()
	var sprites: Dictionary = man.get("sprites", {})
	var nomes: Array = []
	for n in sprites:
		var l = sprites[n].get("layers", null)
		if l is Dictionary and not l.is_empty():
			nomes.append(n)
	nomes.sort()
	print("folhas com camadas: ", nomes.size())
	var chaves: Dictionary = man["by_data_id"]["disciple_palette"]["keys"]
	var keyset := {}
	for campo in chaves:
		for slot in chaves[campo]:
			var k: int = Color(str(chaves[campo][slot])).to_rgba32()
			if keyset.has(k):
				print("FAIL chave repetida entre ", campo, "/", slot, " e ", keyset[k]); falhas += 1
			keyset[k] = "%s/%s" % [campo, slot]
	var look_a := {"skin": "skin_3", "hair_color": "brown", "shorts_color": "green", "hair_style": "volume", "top": "tee", "top_color": "gray", "headband": "band", "headband_color": "red", "socks": "on"}
	var look_b := {"skin": "skin_5", "hair_color": "platinum", "shorts_color": "yellow", "hair_style": "bun", "top": "tank", "top_color": "black", "headband": "band", "headband_color": "white", "socks": "on"}
	var cont := 0
	var estilos := ["buzz", "short", "volume", "bun"]
	for nome in nomes:
		var cam: Dictionary = sprites[nome]["layers"]
		var corpo: Image = _img(cam.get("body", ""))
		if corpo == null:
			print("FAIL sem body: ", nome); falhas += 1; continue
		var sz := corpo.get_size()
		var arqs: Array = [cam.get("band", ""), cam.get("socks", ""), cam.get("front_mask", "")]
		for t in cam.get("top", {}).values(): arqs.append(t)
		for h in cam.get("head", {}).values(): arqs.append(h)
		if cam.get("head", {}).size() != 4:
			print("FAIL ", nome, " cortes=", cam.get("head", {}).keys()); falhas += 1
		if cam.get("top", {}).size() != 2:
			print("FAIL ", nome, " tops=", cam.get("top", {}).keys()); falhas += 1
		for a in arqs:
			var im := _img(a)
			if im == null:
				print("FAIL arquivo ausente ", nome, " ", a); falhas += 1; continue
			if im.get_size() != sz:
				print("FAIL tamanho ", nome, " ", a, " ", im.get_size(), " vs ", sz); falhas += 1
		# cores-chave: nao devem repetir entre camadas diferentes (exceto head_* entre si, que sao alternativas)
		var uso := {}
		var camadas := {"body": cam.get("body", ""), "band": cam.get("band", ""), "socks": cam.get("socks", ""), "tank": cam.get("top", {}).get("tank", ""), "tee": cam.get("top", {}).get("tee", ""), "head": cam.get("head", {}).get("volume", "")}
		for cn in camadas:
			var im := _img(camadas[cn])
			if im == null: continue
			var vistos := {}
			for y in im.get_height():
				for x in im.get_width():
					var c := im.get_pixel(x, y)
					if c.a > 0.0:
						var k := c.to_rgba32()
						if keyset.has(k): vistos[keyset[k]] = true
			uso[cn] = vistos.keys()
		# cada chave de top/socks/band/cabelo so pode aparecer na sua camada
		for cn in uso:
			for kk in uso[cn]:
				var campo: String = str(kk).split("/")[0]
				var esp := {"body": ["skin", "shorts_color", "hair_color", "socks"], "band": ["headband_color"], "socks": ["socks", "skin"], "tank": ["top_color", "skin"], "tee": ["top_color", "skin"], "head": ["hair_color", "skin"]}
				if not (campo in esp[cn]):
					print("INFO ", nome, " camada ", cn, " usa chave de ", kk);
		# mascara: pixels brancos fora do corpo/top/socks
		var m := _img(cam.get("front_mask", ""))
		if m != null:
			var base := corpo.duplicate() as Image
			for t in cam.get("top", {}).values():
				var ti := _img(t); base.blend_rect(ti, Rect2i(Vector2i.ZERO, sz), Vector2i.ZERO)
			var si := _img(cam.get("socks", "")); base.blend_rect(si, Rect2i(Vector2i.ZERO, sz), Vector2i.ZERO)
			var fora := 0; var dentro := 0
			for y in sz.y:
				for x in sz.x:
					var p := m.get_pixel(x, y)
					if p.a > 0.5 and p.r > 0.5:
						if base.get_pixel(x, y).a > 0.0: dentro += 1
						else: fora += 1
			if fora > 0:
				print("INFO mascara com ", fora, " px sem corpo (inofensivo) em ", nome)
			if "guard" in nome or "idle" in nome or "block" in nome:
				if dentro == 0: print("WARN mascara vazia em ", nome)
		# combos
		for st in estilos:
			for top in ["none", "tank", "tee"]:
				for so in ["none", "on"]:
					for hb in ["none", "band"]:
						var lk := look_a.duplicate(); lk["hair_style"] = st; lk["top"] = top; lk["socks"] = so; lk["headband"] = hb
						DV.limpar()
						var tx = DV.textura(nome, lk)
						if tx == null or tx.get_size() != Vector2(sz):
							print("FAIL compose ", nome, " ", lk); falhas += 1
						cont += 1
		DV.limpar()
	print("combos compostos: ", cont)
	# contact sheets: frame 0 de poses chave, 2 looks x 4 cortes
	var alvo := ["fight_player_idle", "fight_player_block", "fight_player_jab", "fight_player_heavy", "fight_player_hit", "fight_player_hit_head", "fight_player_uppercut", "fight_player_hook", "fighter_idle", "fighter_punch", "portrait_player"]
	for variante in ["", "_glove_l1", "_glove_l2", "_glove_l3", "_glove_l4"]:
		for lkn in ["a", "b"]:
			var lk0: Dictionary = look_a if lkn == "a" else look_b
			var imgs: Array = []
			for base_n in alvo:
				for suf in ["_disc_layered", "_disc", ""]:
					var n: String = base_n + variante + suf
					if nomes.has(n):
						for st in estilos:
							var lk := lk0.duplicate(); lk["hair_style"] = st
							var t = DV.textura(n, lk)
							if t != null:
								var im: Image = t.get_image()
								var s2: Dictionary = sprites[n]
								var fw := int(s2.get("frame_w", s2.get("frame_size", [im.get_width(), im.get_height()])[0]))
								imgs.append([im, fw, n])
						break
			print("sheet ", variante, lkn, " n=", imgs.size())
			if imgs.is_empty(): continue
			var W := 0; var H := 0
			for e in imgs:
				var im: Image = e[0]; W = max(W, im.get_width()); H = max(H, im.get_height())
			var colunas := 4
			var linhas := int(ceil(imgs.size() / 4.0))
			var sheet := Image.create(colunas * 96, linhas * 96, false, Image.FORMAT_RGBA8)
			sheet.fill(Color(0.3, 0.3, 0.35))
			for i in imgs.size():
				var im: Image = imgs[i][0]
				var fw: int = imgs[i][1]
				var fr := im.get_region(Rect2i(0, 0, min(fw, im.get_width()), im.get_height()))
				sheet.blend_rect(fr, Rect2i(Vector2i.ZERO, fr.get_size()), Vector2i((i % colunas) * 96, (i / colunas) * 96))
			sheet.resize(sheet.get_width() * 3, sheet.get_height() * 3, Image.INTERPOLATE_NEAREST)
			sheet.save_png(OUT + "sheet%s_%s.png" % [variante, lkn])
	print("FALHAS: ", falhas)
	quit(1 if falhas > 0 else 0)


func _img(caminho: String) -> Image:
	if caminho == "" or not ResourceLoader.exists(caminho): return null
	var t := load(caminho) as Texture2D
	if t == null: return null
	var im: Image = t.get_image(); im.convert(Image.FORMAT_RGBA8); return im
