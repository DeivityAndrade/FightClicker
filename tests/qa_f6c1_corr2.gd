extends SceneTree
## QA correcao 6c1: chegada COM esteira (o vizinho da esteira dobrada) em capturas ampliadas.
const PASTA := "user://test/qa6c1c2/"
const CONFIG := "res://data/config.json"
var gs: Node
var cena: Node
var out := ""
func esperar(s: float) -> void:
	await create_timer(s).timeout
func cap() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func recorte(img: Image, r: Rect2i, k: int) -> Image:
	var c := img.get_region(r)
	c.resize(r.size.x * k, r.size.y * k, Image.INTERPOLATE_NEAREST)
	return c
func folha(q: Array, cols: int, nome: String) -> void:
	var w: int = q[0].get_width()
	var h: int = q[0].get_height()
	var rows := int(ceil(q.size() / float(cols)))
	var s := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	s.fill(Color(0.1, 0.1, 0.1))
	for i in q.size():
		s.blit_rect(q[i], Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	s.save_png(out + nome)
func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6c1_qa_"
	await process_frame
	gs.definir_assistido(false)
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 7
	gs.pular_abertura()
	gs.treino = 5000.0

	while gs.numero_carreira() < 3:
		gs.aposentar(); gs.receber_discipulo(); gs.sucessao_tela_aberta(); gs.confirmar_discipulo(); gs.sucessao_terminou()
	gs.treino = 5000.0
	print("comprou esteira: ", gs.comprar_aparelho("treadmill"))
	gs._montar_aparelho("treadmill")
	print("montada: ", gs.aparelho_montado("treadmill"))
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.6)
	print("esteira estado: ", gs.estado_aparelho("treadmill"))
	gs.cinturao = true
	gs.dinheiro = 1.0e9
	gs.mudar()
	var q: Array = []
	var t := 0.0
	while t < 7.0:
		if t >= 1.4:
			var img: Image = await cap()
			q.append(recorte(img, Rect2i(300, 120, 212, 160), 3))
		await esperar(0.3)
		t += 0.3
	var i := 0
	while i < q.size():
		folha(q.slice(i, i + 6), 2, "chegada_esteira_t%02d.png" % (i * 3 + 14))
		i += 6
	for p in cena.find_children("*", "AudioStreamPlayer", true, false):
		(p as AudioStreamPlayer).stop()
	quit(0)
