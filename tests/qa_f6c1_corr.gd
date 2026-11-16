extends SceneTree
## QA da correcao da 6c1 (carga e foto). Capturas quadro a quadro da chegada (A1-A5) e da saida do John, foto torta->reta.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6c1_corr.gd   (APPDATA temporario!)
const PASTA := "user://test/qa6c1c/"
const CONFIG := "res://data/config.json"
var gs: Node
var cena: Node
var out := ""
var falhas := 0

func ok(c: bool, n: String) -> void:
	if not c: falhas += 1
	print("PASS  " if c else "FAIL  ", n)

func esperar(s: float) -> void:
	await create_timer(s).timeout

func fechar() -> void:
	if cena != null:
		for p in cena.find_children("*", "AudioStreamPlayer", true, false):
			(p as AudioStreamPlayer).stop()
		cena.queue_free()
		cena = null
		await process_frame

func novo_jogo(carreira: int) -> void:
	await fechar()
	gs.definir_assistido(false)
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 7
	gs.pular_abertura()
	gs.treino = 500.0
	while gs.numero_carreira() < carreira:
		gs.aposentar(); gs.receber_discipulo(); gs.sucessao_tela_aberta(); gs.confirmar_discipulo(); gs.sucessao_terminou()
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.6)

func abrir_existente() -> void:
	await fechar()
	gs.definir_assistido(false)
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.8)

func sala() -> Node:
	return cena.get_node("Sala")

func frame_foto(chave: String) -> int:
	var d = sala()._parede.get(chave, null)
	if d == null: return -99
	return int(d.sprite.frame) if d.sprite.visible else -1

func cap() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func recorte(img: Image, r: Rect2i, k: int) -> Image:
	var c := img.get_region(r)
	c.resize(r.size.x * k, r.size.y * k, Image.INTERPOLATE_NEAREST)
	return c

func folha(quadros: Array, cols: int, nome: String) -> void:
	if quadros.is_empty(): return
	var w: int = quadros[0].get_width()
	var h: int = quadros[0].get_height()
	var rows := int(ceil(quadros.size() / float(cols)))
	var s := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	s.fill(Color(0.1, 0.1, 0.1))
	for i in quadros.size():
		s.blit_rect(quadros[i], Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	s.save_png(out + nome)

func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6c1_qa_"
	await process_frame
	# --- chegada ---
	await novo_jogo(3)
	print("garagem: foto garagem frame=", frame_foto("photo_old"), " visivel=", sala()._parede.has("photo_old") and sala()._parede["photo_old"].sprite.visible)
	var g_antes := frame_foto("photo_old")
	var g_img: Image = await cap()
	gs.cinturao = true
	gs.dinheiro = 1.0e9
	gs.mudar()
	ok(gs.cena_sala == "primeira_academia", "cena pedida")
	var t := 0.0
	var passo := 0.2
	var A: Array = []
	var B: Array = []
	var n := 0
	while t < 9.0:
		var img: Image = await cap()
		var rotulo := "%.1f" % t
		A.append(recorte(img, Rect2i(128, 100, 320, 170), 2))
		B.append(recorte(img, Rect2i(300, 190, 150, 85), 4))
		await esperar(passo)
		t += passo
	var i := 0
	var lote := 8
	while i < A.size():
		folha(A.slice(i, i + lote), 2, "chegada_t%03d_geral.png" % int(i * passo * 10))
		i += lote
	i = 0
	while i < B.size():
		folha(B.slice(i, i + 12), 3, "chegada_t%03d_carga_x4.png" % int(i * passo * 10))
		i += 12
	await esperar(5.0)
	print("fim da cena: cena_sala='", gs.cena_sala, "'")
	ok(gs.cena_sala == "", "cena terminou")
	ok(frame_foto("photo_old_gym") == 0, "foto da academia reta depois da cena")
	var fl: Node = cena.get_node("Fluxo")
	if fl.janela != null and fl.janela.has_method("_escolher"):
		fl.janela._escolher(gs.academia.ids_artes()[0])
	await esperar(2.0)
	gs.salvar() if gs.has_method("salvar") else null
	await esperar(0.5)
	var ac: Image = await cap()
	ac.get_region(Rect2i(128, 18, 384, 272)).save_png(out + "academia_foto_reta.png")
	recorte(ac, Rect2i(180, 120, 110, 80), 4).save_png(out + "academia_foto_reta_x4.png")
	# --- reabrir ---
	print("salvando e reabrindo; marcos: ", gs.tem_marco("cena_primeira_academia") if gs.has_method("tem_marco") else "?")
	await abrir_existente()
	print("reaberto: local=", gs.local_atual() if gs.has_method("local_atual") else "?", " frame foto gym=", frame_foto("photo_old_gym"))
	ok(frame_foto("photo_old_gym") == 0, "reaberto: foto reta")
	var r: Image = await cap()
	recorte(r, Rect2i(180, 120, 110, 80), 4).save_png(out + "academia_reaberto_foto_x4.png")
	# --- saida na academia ---
	await novo_jogo(3)
	gs.cinturao = true; gs.dinheiro = 1.0e9; gs.mudar()
	await esperar(0.5)
	await pular_e_escolher()
	gs._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
	t = 0.0
	while not gs.saida_tocando() and t < 30.0:
		await esperar(0.25); t += 0.25
	ok(gs.saida_tocando(), "saida na academia tocando")
	await capturar_saida("saida_gym")
	# --- saida na garagem ---
	await novo_jogo(3)
	gs._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
	t = 0.0
	while not gs.saida_tocando() and t < 40.0:
		await esperar(0.25); t += 0.25
	print("garagem saida tocando=", gs.saida_tocando(), " t=", t)
	ok(gs.saida_tocando(), "saida na garagem tocando")
	await capturar_saida("saida_gar")
	await fechar()
	print("FALHAS ", falhas)
	quit(1 if falhas > 0 else 0)

func capturar_saida(nome: String) -> void:
	var Q: Array = []
	var t := 0.0
	while gs.saida_tocando() and t < 16.0:
		var img: Image = await cap()
		Q.append(recorte(img, Rect2i(128, 100, 320, 170), 2))
		await esperar(0.35)
		t += 0.35
	var i := 0
	while i < Q.size():
		folha(Q.slice(i, i + 8), 2, "%s_t%03d.png" % [nome, int(i * 0.35 * 10)])
		i += 8

func pular_e_escolher() -> void:
	for c in cena.get_children():
		if c.get_script() != null and str(c.get_script().get_global_name()) == "CenaUi":
			c.player.pular()
	await esperar(0.8)
	var fl: Node = cena.get_node("Fluxo")
	if fl.janela != null and fl.janela.has_method("_escolher"):
		fl.janela._escolher(gs.academia.ids_artes()[0])
	await esperar(1.0)
