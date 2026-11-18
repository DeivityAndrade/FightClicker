extends SceneTree
## QA 6d: sucessao retomada de um save (fechar na criacao -> confirmar -> chegada curta; fechar depois do confirmar).
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d_retomar.gd   (APPDATA temporario!)
const PASTA := "user://test/qa6dr/"
const CONFIG := "res://data/config.json"
const LOOK := {"skin": "skin_5", "hair_color": "blond", "hair_style": "bun", "shorts_color": "blue", "top": "tank", "top_color": "white", "headband": "band", "headband_color": "red", "socks": "on"}
var gs: Node
var cena: Node
var out := ""

func esperar(s: float) -> void:
	await create_timer(s).timeout

func fechar() -> void:
	if cena != null:
		for p in cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		cena.queue_free()
		cena = null
		await process_frame

func abrir() -> void:
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.8)

func cena_ui() -> Node:
	for c in cena.get_children():
		if c.get_script() != null and str(c.get_script().get_global_name()) == "CenaUi":
			return c
	return null

func janela_criar() -> Node:
	var fl: Node = cena.get_node("Fluxo")
	if fl.janela != null and fl.janela.get_script() != null and str(fl.janela.get_script().get_global_name()) == "TelaCriarDiscipulo":
		return fl.janela
	return null

func cap() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func folha(q: Array, nome: String) -> void:
	var w: int = q[0].get_width()
	var h: int = q[0].get_height()
	var s := Image.create(w * 2, h * int(ceil(q.size() / 2.0)), false, Image.FORMAT_RGBA8)
	for i in q.size():
		s.blit_rect(q[i], Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
	s.save_png(out + nome)

func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6d_qa_retomar_"
	await process_frame
	gs.definir_assistido(false)
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 5
	gs.pular_abertura()
	gs.treino = 500.0
	await abrir()
	gs.aposentar()
	await esperar(0.6)
	gs.receber_discipulo()
	await esperar(1.0)
	cena_ui().player.pular()
	await esperar(0.8)
	for c in LOOK:
		gs.definir_rascunho(c, str(LOOK[c]))
	gs.definir_rascunho("name", "Retomado")
	gs.salvar()
	await fechar()
	# --- R1: reabrir na criacao e confirmar -> chegada curta tocada ---
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	print("estado reaberto: ", gs.sucessao_estado(), " rascunho look skin=", gs.rascunho().get("look", {}).get("skin", "?"))
	await abrir()
	await esperar(0.8)
	var tl := janela_criar()
	print("tela criacao: ", tl != null)
	if tl != null:
		tl._confirmar()
	await esperar(0.05)
	var q: Array = []
	var t := 0.0
	while gs.sucessao_estado() != "none" and t < 8.0:
		var img: Image = await cap()
		var r := img.get_region(Rect2i(128, 96, 352, 192))
		r.resize(704, 384, Image.INTERPOLATE_NEAREST)
		q.append(r)
		await esperar(0.2)
		t += 0.2
	if not q.is_empty():
		folha(q.slice(0, 8), "r1_chegada.png")
	await esperar(0.6)
	var img2: Image = await cap()
	var r2 := img2.get_region(Rect2i(128, 96, 352, 192))
	r2.resize(704, 384, Image.INTERPOLATE_NEAREST)
	r2.save_png(out + "r1_depois.png")
	# --- R2: fechar apos o confirmar (arriving) ---
	await fechar()
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	gs.treino = 500.0
	await abrir()
	gs.aposentar()
	await esperar(0.6)
	gs.receber_discipulo()
	await esperar(1.0)
	cena_ui().player.pular()
	await esperar(0.8)
	for c in LOOK:
		gs.definir_rascunho(c, str(LOOK[c]))
	gs.definir_rascunho("name", "Retomado")
	janela_criar()._confirmar()
	await esperar(0.5)
	gs.salvar()
	await fechar()
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	print("R2 estado reaberto: ", gs.sucessao_estado())
	await abrir()
	await esperar(1.2)
	var img3: Image = await cap()
	var r3 := img3.get_region(Rect2i(0, 0, 640, 360))
	r3.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	r3.save_png(out + "r2_garagem.png")
	print("FIM")
	await fechar()
	quit(0)
