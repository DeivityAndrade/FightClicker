extends SceneTree
## QA 6d2: tela C (painel pela direita, atalhos, so a sala, cenas) e balao perto do cursor ao vivo.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d2_tela.gd   (APPDATA temporario!)
const PASTA := "user://test/qa6d2tela/"
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

func foto(nome: String, r: Rect2i = Rect2i(0, 0, 640, 360), k: int = 2) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image().get_region(r)
	img.resize(r.size.x * k, r.size.y * k, Image.INTERPOLATE_NEAREST)
	img.save_png(out + nome + ".png")

func tecla(k: int) -> void:
	for p in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
		Input.parse_input_event(e)
		await process_frame
	await esperar(0.35)

func mover(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p * 2.0
	e.global_position = p * 2.0
	Input.parse_input_event(e)
	await process_frame
	await process_frame

func clicar_em(p: Vector2) -> void:
	await mover(p)
	for d in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = p * 2.0
		e.global_position = p * 2.0
		e.pressed = d
		Input.parse_input_event(e)
		await process_frame
	await esperar(0.35)

func novo() -> void:
	gs.definir_assistido(false)
	gs.inicializar(PASTA, CONFIG)
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 5
	gs.pular_abertura()
	gs.treino = 3000.0
	gs.dinheiro = 5000.0

func _initialize() -> void:
	gs = root.get_node("GameState")
	out = ProjectSettings.globalize_path("res://docs/arte/mockups/") + "fase6d2_qa_"
	await process_frame
	await novo()
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(1.0)
	var dir: Node = cena.get_node("PainelLoja")
	await foto("tela_fechada")
	ok(not dir.esta_aberto(), "painel comeca fechado")
	await tecla(KEY_L)
	ok(dir.esta_aberto(), "L abre")
	ok(dir._aba == "loja", "L abre a aba loja (%s)" % dir._aba)
	await foto("tela_L")
	await tecla(KEY_E)
	ok(dir.esta_aberto() and dir._aba == "treino", "E troca para equipe com painel aberto (%s %s)" % [dir.esta_aberto(), dir._aba])
	await foto("tela_E")
	await tecla(KEY_E)
	ok(not dir.esta_aberto(), "E de novo fecha")
	await tecla(KEY_L)
	await tecla(KEY_L)
	ok(not dir.esta_aberto(), "L de novo fecha")
	# so a sala
	await tecla(KEY_L)
	await tecla(KEY_H)
	ok(cena.esta_so_sala(), "H liga so a sala")
	await foto("tela_H_com_painel_aberto")
	print("H: painel visivel=", dir.visible, " corpo=", dir._corpo.visible, " aberto=", dir.esta_aberto(), " alca=", dir._alca.visible)
	await tecla(KEY_L)
	print("H + L: painel aberto=", dir.esta_aberto(), " visivel=", dir.visible)
	ok(not cena.esta_so_sala() and dir.esta_aberto(), "O1: L tira do so a sala e abre o painel")  # decisao do Produtor (6d2)
	await tecla(KEY_H)
	await tecla(KEY_H)
	ok(not cena.esta_so_sala(), "H desliga so a sala")
	print("apos H off: painel aberto=", dir.esta_aberto(), " visivel=", dir.visible, " corpo=", dir._corpo.visible)
	await foto("tela_H_volta")
	dir.definir_estado(false)
	await esperar(0.3)
	# so a sala sem painel
	await tecla(KEY_H)
	await foto("tela_H_sem_painel")
	var sala_nome: Array = []
	for n in cena.get_children():
		if n is CanvasItem and (n as CanvasItem).visible:
			sala_nome.append(n.name)
	print("visiveis em so_sala: ", sala_nome)
	await tecla(KEY_H)
	# 6d3: clique na sala NAO fecha o painel; so a aba/seta ou L/E na mesma aba
	await tecla(KEY_L)
	ok(dir.esta_aberto(), "aberto antes do clique na sala")
	await clicar_em(Vector2(200, 200))
	await clicar_em(Vector2(200, 200))
	await esperar(0.4)
	ok(dir.esta_aberto(), "clique na sala (duas vezes) nao fecha o painel")
	await foto("tela_aberto_apos_clique")
	var ab: Rect2 = dir._alca.get_global_rect()
	await clicar_em(ab.get_center())
	await esperar(0.4)
	ok(not dir.esta_aberto(), "clique na aba/seta fecha (centro %s)" % ab.get_center())
	await tecla(KEY_L)
	await tecla(KEY_E)
	ok(dir.esta_aberto() and dir._aba == "treino", "E com a loja aberta so troca a aba")
	await tecla(KEY_E)
	ok(not dir.esta_aberto(), "E na mesma aba fecha")
	dir.definir_estado(true)
	await esperar(0.3)
	# cena: o painel fecha e volta
	gs.atributos = {"strength": 50.0, "agility": 50.0, "endurance": 50.0}
	gs.aposentar()
	await esperar(0.8)
	gs.receber_discipulo()
	var visto_fechado := false
	var t := 0.0
	var tirou_foto := false
	while gs.sucessao_estado() != "none" and t < 45.0:
		if gs.sucessao_estado() == "scene_1":
			if dir.esta_aberto(): print("ERRO painel aberto em cena", t)
			else: visto_fechado = true
			if not tirou_foto and t > 3.0:
				tirou_foto = true
				await foto("tela_cena_painel")
		if gs.sucessao_estado() == "creating":
			var tl: Node = cena.get_node("Fluxo").janela
			gs.definir_rascunho("name", "Teste")
			tl._confirmar()
		await esperar(0.2)
		t += 0.2
	ok(visto_fechado, "painel fechado durante a cena")
	await esperar(1.2)
	ok(dir.esta_aberto(), "painel volta aberto depois da cena (%s)" % dir.esta_aberto())
	await foto("tela_pos_cena")
	# atalhos durante cena
	dir.definir_estado(false)
	gs.cinturao = true
	gs.dinheiro = 1.0e9
	gs.mudar()
	await esperar(0.5)
	await tecla(KEY_L)
	print("L durante cena da academia: aberto=", dir.esta_aberto(), " corpo=", dir._corpo.visible, " cena_sala=", gs.cena_sala)
	ok(not dir._corpo.visible, "L durante cena nao mostra o painel")
	var t2 := 0.0
	while gs.cena_sala != "" and t2 < 60.0:
		await esperar(0.5); t2 += 0.5
	await esperar(1.0)
	var fl: Node = cena.get_node("Fluxo")
	if fl.janela != null and fl.janela.has_method("_escolher"):
		fl.janela._escolher(gs.academia.ids_artes()[0])
	await esperar(2.0)
	print("apos cena: aberto=", dir.esta_aberto(), " corpo=", dir._corpo.visible)
	await foto("tela_academia")
	print("FALHAS ", falhas)
	quit(1 if falhas > 0 else 0)
