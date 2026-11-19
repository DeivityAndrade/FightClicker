extends SceneTree
## QA 6d3: botao SEGURAR na faixa de baixo, clique no saco com painel aberto, sobreposicoes.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f6d3_botao.gd  (APPDATA temporario)
var gs: Node
var cena: Node
var falhas := 0
var out := ""
func ok(c: bool, n: String) -> void:
	if not c: falhas += 1
	print("PASS  " if c else "FAIL  ", n)
func esperar(s: float) -> void:
	await create_timer(s).timeout
func foto(nome: String, r: Rect2i, k: int) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image().get_region(r)
	img.resize(r.size.x * k, r.size.y * k, Image.INTERPOLATE_NEAREST)
	img.save_png(out + nome + ".png")
func mover(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p * 2.0
	e.global_position = p * 2.0
	Input.parse_input_event(e)
	await process_frame
	await process_frame
func botao(p: Vector2, d: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = p * 2.0
	e.global_position = p * 2.0
	e.pressed = d
	Input.parse_input_event(e)
	await process_frame
	await process_frame
func tecla(k: int) -> void:
	for p in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = p
		Input.parse_input_event(e)
		await process_frame
	await esperar(0.35)
func _initialize() -> void:
	gs = root.get_node("GameState")
	out = "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/botao_"
	await process_frame
	gs.definir_assistido(false)
	gs.inicializar("user://test/qa6d3btn/", "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.pular_abertura()
	gs.treino = 3000.0
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(1.0)
	var dir: Node = cena.get_node("PainelLoja")
	var fx: Node = cena.get_node("FaixaAssistido")
	var br: Control = fx._botao
	var rb: Rect2 = br.get_global_rect()
	print("botao global (px de janela/2): ", Rect2(rb.position / 2.0, rb.size / 2.0), " vis=", br.visible, " pai=", br.get_parent().name)
	var rect := Rect2(rb.position / 2.0, rb.size / 2.0) if rb.position.x > 700 else rb
	print("rect em coords do jogo: ", rect)
	# --- clique no saco com painel aberto ---
	await tecla(KEY_L)
	ok(dir.esta_aberto(), "painel aberto")
	var t0: float = gs.treino
	var a0: float = gs.atributos.get("strength", 0.0)
	await mover(Vector2(336, 222)); await botao(Vector2(336, 222), true); await botao(Vector2(336, 222), false)
	await esperar(0.3)
	ok(gs.atributos.get("strength", 0.0) > a0 or gs.treino > t0, "clicar no saco treina (forca %s -> %s)" % [a0, gs.atributos.get("strength", 0.0)])
	ok(dir.esta_aberto(), "painel continua aberto depois do clique no saco")
	# --- botao SEGURAR ---
	await foto("barra_aberto", Rect2i(380, 326, 260, 34), 4)
	var c := rect.get_center()
	await mover(c)
	await foto("barra_hover", Rect2i(380, 300, 260, 60), 4)
	await botao(c, true)
	await esperar(0.2)
	ok(gs.assistido_segurando(), "clique no botao SEGURAR segura (estado %s)" % gs.assistido_estado())
	await foto("barra_segurando", Rect2i(0, 200, 640, 160), 2)
	await botao(c, false)
	await esperar(0.2)
	ok(not gs.assistido_segurando(), "soltar o mouse solta o assistido")
	ok(dir.esta_aberto(), "painel continua aberto depois do SEGURAR")
	# cliques nas bordas do botao (cantos)
	for off in [Vector2(1, 1), Vector2(rect.size.x - 1, 1), Vector2(1, rect.size.y - 1), Vector2(rect.size.x - 1, rect.size.y - 1)]:
		var p: Vector2 = rect.position + off
		await mover(p); await botao(p, true); await esperar(0.1)
		ok(gs.assistido_segurando(), "canto %s do botao funciona" % off)
		await botao(p, false); await esperar(0.1)
	# vizinhos
	var ajuda = cena.get_node("BarraBaixo")._ajuda
	var ra: Rect2 = ajuda.get_global_rect()
	if ra.position.x > 700: ra = Rect2(ra.position / 2.0, ra.size / 2.0)
	print("ajuda: ", ra, " botao: ", rect, " lutar: ", cena.get_node("BarraBaixo").LUTAR)
	ok(not ra.intersects(rect), "botao nao cobre o ?")
	ok(not cena.get_node("BarraBaixo").LUTAR.intersects(rect), "botao nao cobre o LUTAR")
	ok(ra.size == Vector2(16, 16), "? em 16x16 (%s)" % ra.size)
	var salvo = cena.get_node("BarraBaixo")._salvo
	var rs := Rect2(salvo.global_position, salvo.size)
	print("salvo label: ", rs, " texto='", salvo.text, "' vis=", salvo.visible)
	# ? clicavel e hover
	await mover(ra.get_center())
	await esperar(0.3)
	await foto("barra_ajuda_hover", Rect2i(300, 240, 340, 120), 3)
	# --- 4 aparelhos: dica ---
	gs.aparelhos_montados_ids = ["punching_bag", "speed_bag", "treadmill", "jump_rope"]
	gs.cinturao = true; gs.local_id = "gym"
	gs.mudar() if false else null
	await esperar(0.5)
	await foto("barra_varios", Rect2i(0, 326, 640, 34), 3)
	print("FALHAS ", falhas)
	quit(1 if falhas > 0 else 0)
