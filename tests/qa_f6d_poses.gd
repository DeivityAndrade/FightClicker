extends SceneTree
## QA 6d: todas as poses da luta (17) x 3 luvas x visuais, pelo mesmo caminho do jogo (TelaLuta._nome + aplicar_visual_disc).
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_poses.gd   (APPDATA temporario!)
const PASTA := "user://test/qa6dp/"
const CONFIG := "res://data/config.json"
const LOOKS := [
	{"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "shorts_color": "green", "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_1", "hair_color": "black", "hair_style": "buzz", "shorts_color": "green", "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"},
	{"skin": "skin_5", "hair_color": "blond", "hair_style": "bun", "shorts_color": "blue", "top": "tank", "top_color": "white", "headband": "band", "headband_color": "red", "socks": "on"},
	{"skin": "skin_1", "hair_color": "platinum", "hair_style": "volume", "shorts_color": "black", "top": "tee", "top_color": "black", "headband": "band", "headband_color": "black", "socks": "on"},
	{"skin": "skin_5", "hair_color": "black", "hair_style": "short", "shorts_color": "white", "top": "tee", "top_color": "white", "headband": "band", "headband_color": "white", "socks": "on"},
	{"skin": "skin_3", "hair_color": "copper", "hair_style": "bun", "shorts_color": "purple", "top": "none", "top_color": "white", "headband": "band", "headband_color": "yellow", "socks": "on"},
	{"skin": "skin_2", "hair_color": "dark_brown", "hair_style": "volume", "shorts_color": "yellow", "top": "tank", "top_color": "yellow", "headband": "none", "headband_color": "red", "socks": "none"},
]
const POSES := ["idle", "jab", "heavy", "hook", "uppercut", "body_shot", "dodge", "block", "tired", "victory", "hit", "hit_head", "hit_up", "hit_body", "ko", "ko_back", "ko_knees"]
var gs: Node
var cena: Node
var out := ""
var falhas := 0

func esperar(s: float) -> void:
	await create_timer(s).timeout

func cap() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6d_qa_poses_"
	await process_frame
	gs.definir_assistido(false)
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	gs.treino = 500.0
	while gs.numero_carreira() < 2:
		gs.aposentar(); gs.receber_discipulo(); gs.sucessao_tela_aberta(); gs.confirmar_discipulo(); gs.sucessao_terminou()
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.8)
	var fl: Node = cena.get_node("Fluxo")
	gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
	fl.abrir_previa()
	await esperar(0.5)
	fl.janela.lutar_pedido.emit()
	await esperar(0.6)
	var tl: Node = fl.tela
	tl.ativa = false  # congela o relogio e os cues; so mexemos na pose
	var spr = tl._l[0].spr
	print("pos spr ", spr.global_position, " scale ", spr.global_scale, " escala ", tl._l[0].escala)
	var UT: GDScript = load("res://ui/ui_tema.gd")
	var cw := 100
	var ch := 110
	for li in LOOKS.size():
		gs.discipulo = {"name": "T", "look": LOOKS[li].duplicate(), "campaign": 2}
		var cels: Array = []
		for nivel in [0, 2, 4]:
			gs.nivel_luva = nivel
			for p in POSES:
				var nome: String = tl._nome(0, p)
				var sp0 = UT.sprite(nome)
				if sp0.is_empty():
					print("SEM FOLHA ", nome)
					falhas += 1
					cels.append(null)
					continue
				spr.definir(nome)
				spr.parar(0)
				UT.aplicar_visual_disc(spr)
				if not nome.ends_with("_disc"):
					print("AVISO: pose sem versao _disc: ", nome)
					falhas += 1
				elif UT.sprite(nome + "_layered").is_empty():
					print("AVISO: sem _layered: ", nome)
					falhas += 1
				await process_frame
				var img: Image = await cap()
				var c: Vector2 = spr.global_position
				var s: float = float(spr.global_scale.x)
				var r := Rect2i(int(c.x - 50.0 * s), int(c.y - 90.0 * s), int(100.0 * s), int(110.0 * s))
				var rec := img.get_region(r)
				rec.resize(cw, ch, Image.INTERPOLATE_NEAREST)
				cels.append(rec)
		var cols := 9
		var rows := 6
		var sheet := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0.15, 0.15, 0.2))
		for i in cels.size():
			if cels[i] == null: continue
			var gi := i / POSES.size()
			var pi := i % POSES.size()
			var rr := gi * 2 + pi / 9
			var cc := pi % 9
			sheet.blit_rect(cels[i], Rect2i(0, 0, cw, ch), Vector2i(cc * cw, rr * ch))
		sheet = sheet
		var big := sheet
		big.resize(cw * cols * 2, ch * rows * 2, Image.INTERPOLATE_NEAREST)
		big.save_png(out + "look%d.png" % li)
		print("sheet look", li)
	print("FALHAS ", falhas)
	quit(0)
