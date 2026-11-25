extends SceneTree
## QA Ronda: folha de conferencia do VULTO em 4 discipulos (4 cortes, cores e roupas diferentes) e dos 3 LADROES, em 2x,
## montadas pelas camadas (DiscVisual.textura). Grava PNGs em OUT. Headless, sem janela.

const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa/vulto/"

var LOOKS := [
	{"skin": "skin_1", "hair_color": "black", "hair_style": "buzz", "shorts_color": "blue", "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "shorts_color": "green", "top": "tank", "top_color": "gray", "headband": "band", "headband_color": "red", "socks": "on"},
	{"skin": "skin_5", "hair_color": "copper", "hair_style": "volume", "shorts_color": "purple", "top": "tee", "top_color": "yellow", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_2", "hair_color": "platinum", "hair_style": "bun", "shorts_color": "white", "top": "none", "top_color": "white", "headband": "band", "headband_color": "red", "socks": "on"},
]
const POSES := ["ronda_vulto_sneak_idle", "ronda_vulto_sneak_walk", "ronda_vulto_freeze", "ronda_vulto_seen", "ronda_vulto_scare", "ronda_vulto_roof"]


func _initialize() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(OUT)
	var DV = load("res://ui/disc_visual.gd")
	var UT = load("res://ui/ui_tema.gd")
	var gs = root.get_node("GameState")
	print("== qa_ronda_visual ==")
	# colunas: para cada pose, primeiro e um quadro do meio (scare: 0,2,5)
	if "--fix" in OS.get_cmdline_user_args():
		for nome in POSES:
			var sp: Dictionary = UT.sprite(nome)
			sp["layers"]["body"] = sp["file"]
		print("(simulando layers.body = file)")
	var cols: Array = []
	for nome in POSES:
		var s: Dictionary = UT.sprite(nome)
		print(nome, " frames=", s.get("frames", "?"), " tamanho=", s.get("frame_size", "?"), " layers=", s.get("layers", {}).keys() if s.get("layers", {}) is Dictionary else "-")
		var n := int(s.get("frames", 1))
		var pick: Array = [0] if n <= 2 else ([0, 2, 5] if nome == "ronda_vulto_scare" else [0, n / 2])
		for q in pick:
			cols.append([nome, q])
	var FW := 96
	var FH := 100
	var folha := Image.create(FW * cols.size(), FH * LOOKS.size(), false, Image.FORMAT_RGBA8)
	folha.fill(Color(0.16, 0.14, 0.22, 1.0))
	var r := 0
	for look in LOOKS:
		var c := 0
		for col in cols:
			var tex: Texture2D = DV.textura(col[0], look, true)
			var img: Image = tex.get_image()
			var fw := int(UT.sprite(col[0]).get("frame_size", [96, 100])[0])
			var q := int(col[1])
			var reg := img.get_region(Rect2i(q * fw, 0, fw, img.get_height()))
			folha.blend_rect(reg, Rect2i(0, 0, reg.get_width(), reg.get_height()), Vector2i(c * FW, r * FH))
			c += 1
		r += 1
	var grande := folha.duplicate()
	grande.resize(folha.get_width() * 2, folha.get_height() * 2, Image.INTERPOLATE_NEAREST)
	grande.save_png(OUT + "vulto_4_discipulos" + ("_fix" if "--fix" in OS.get_cmdline_user_args() else "") + ".png")
	print("colunas ", cols.size(), " folha ", folha.get_size())
	# ladroes: cada anim, 1 quadro
	var anims := ["work", "warn", "look", "fake", "fall", "flee"]
	var lad := Image.create(FW * anims.size(), FH * 3, false, Image.FORMAT_RGBA8)
	lad.fill(Color(0.16, 0.14, 0.22, 1.0))
	var rr := 0
	for id in ["tire", "bike", "gate"]:
		var cc := 0
		for a in anims:
			var nome := "ronda_thief_%s_%s" % [id, a]
			var s: Dictionary = UT.sprite(nome)
			if s.is_empty():
				print("FALTA a folha ", nome)
			else:
				var tex: Texture2D = UT.textura(nome)
				var img: Image = tex.get_image()
				var fw := int(s.get("frame_size", [96, 100])[0])
				var n := int(s.get("frames", 1))
				var q := n / 2 if a != "fall" else n - 1
				var reg := img.get_region(Rect2i(q * fw, 0, fw, img.get_height()))
				lad.blend_rect(reg, Rect2i(0, 0, reg.get_width(), reg.get_height()), Vector2i(cc * FW, rr * FH))
				print(nome, " frames=", n, " fps=", s.get("fps", "?"), " loop=", s.get("loop", "?"))
			cc += 1
		rr += 1
	lad.resize(lad.get_width() * 2, lad.get_height() * 2, Image.INTERPOLATE_NEAREST)
	lad.save_png(OUT + "ladroes.png")
	print("ok")
	quit(0)
