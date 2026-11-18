extends SceneTree
## QA 6d2: academia, momento da esteira (helper, treadmill_put_right) em quadros rapidos, regiao do canto direito da frente.
const PASTA := "user://test/qa6d2gh/"
var gs: Node
var cena: Node
func esperar(s: float) -> void:
	await create_timer(s).timeout
func _initialize() -> void:
	gs = root.get_node("GameState")
	var out := ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6d2_qa_gymhelper_"
	await process_frame
	gs.definir_assistido(false)
	gs.inicializar(PASTA, "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.8)
	gs.treino = 1.0e9
	print("compra esteira ", gs.comprar_aparelho("treadmill"), " caixa ", gs.abrir_caixa("treadmill"), " montado ", gs.aparelho_montado("treadmill"))
	gs.cinturao = true
	gs.dinheiro = 1.0e9
	gs.mudar()
	var t0 := Time.get_ticks_msec()
	var Q: Array = []
	var n := 0
	while gs.cena_sala != "" and n < 400:
		await process_frame
		await RenderingServer.frame_post_draw
		var el := (Time.get_ticks_msec() - t0) / 1000.0
		if el > 5.0:
			var img: Image = root.get_texture().get_image().get_region(Rect2i(0, 0, 640, 360))
			pass
			Q.append(img)
		n += 1
		await esperar(0.1)
	print("quadros ", Q.size(), " cena_sala=", gs.cena_sala)
	var w := 640
	var h := 360
	var i := 0
	var k := 0
	while i < Q.size():
		var s := Image.create(w * 2, h * 3, false, Image.FORMAT_RGBA8)
		for j in 6:
			if i + j < Q.size():
				s.blit_rect(Q[i + j], Rect2i(0, 0, w, h), Vector2i((j % 2) * w, (j / 2) * h))
		s.save_png(out + "%02d.png" % k)
		i += 6
		k += 1
	quit()
