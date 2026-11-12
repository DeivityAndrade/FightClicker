extends SceneTree
## QA 5.1: teste de cena (teclas, janelas, geometria das caixas). Save em user://test/autoload/.
var gs: Node
var cena: Control
var sala
var fluxo
const ALVO := Rect2(312, 182, 48, 90)

func win(p: Vector2) -> Vector2:
	return root.get_final_transform() * p

func clicar(p: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = win(p); m.global_position = m.position
	Input.parse_input_event(m)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = win(p); ev.global_position = ev.position
	ev.pressed = true; ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(ev)
	var e2 := ev.duplicate() as InputEventMouseButton
	e2.pressed = false; e2.button_mask = 0
	Input.parse_input_event(e2)

func tecla(k: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k; ev.physical_keycode = k; ev.pressed = true
	Input.parse_input_event(ev)
	var e2 := ev.duplicate() as InputEventKey
	e2.pressed = false
	Input.parse_input_event(e2)

func frames(n: int) -> void:
	for i in n:
		await process_frame

func p(s: String) -> void:
	print("QA| ", s)

func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	sala = cena.get_node("Sala")
	fluxo = cena.get_node("Fluxo")
	await frames(20)
	gs.apagar_save()
	await frames(3)
	gs.treino = 1e6
	gs.dinheiro = 1e6
	# --- teclas 1-4 e Espaco com esteira e corda em caixa ---
	gs.comprar_aparelho("treadmill")
	await frames(5)
	for k in [KEY_2, KEY_3, KEY_4]:
		tecla(k)
		await frames(2)
	p("foco depois de 2,3,4 com esteira na caixa: %s (esperado punching_bag)" % gs.foco)
	var hits0 := int(gs.caixa("treadmill").hits)
	for i in 10:
		tecla(KEY_SPACE)
		await frames(1)
	p("hits depois de 10x Espaco: %d (esperado 0)" % int(gs.caixa("treadmill").hits))
	# --- clique no alvo nao bate na caixa; clique na caixa nao treina ---
	var cx = sala._caixas.get("treadmill")
	p("area da caixa esteira: %s ; ALVO %s ; intersecta=%s" % [str(cx.area()), str(ALVO), str(cx.area().intersects(ALVO))])
	var antes: float = gs.treino
	var n_clic := [0]
	gs.clicou.connect(func(_a, _b, _c, _d, _e): n_clic[0] += 1)
	clicar(cx.area().get_center())
	await frames(3)
	p("clique na caixa: hits=%d clicou=%d (esperado 1/0)" % [int(gs.caixa("treadmill").hits), n_clic[0]])
	clicar(ALVO.get_center())
	await frames(3)
	p("clique no alvo: hits=%d clicou=%d (esperado 1/1)" % [int(gs.caixa("treadmill").hits), n_clic[0]])
	# --- janela aberta: clique ignorado ---
	fluxo.abrir_previa() if gs.pode_lutar() else null
	await frames(5)
	p("previa aberta=%s ocupado=%s" % [fluxo.janela != null, fluxo.ocupado()])
	if fluxo.ocupado():
		var h1 := int(gs.caixa("treadmill").hits)
		await frames(3)
		sala.janela_aberta = true
		clicar(cx.area().get_center())
		await frames(3)
		p("com janela: hits=%d (esperado %d)" % [int(gs.caixa("treadmill").hits), h1])
	# --- mudar tela: usa fluxo diretamente
	if fluxo.janela != null:
		fluxo.janela.queue_free()
		fluxo.janela = null
	sala.janela_aberta = false
	# --- geometria: todas as caixas ao mesmo tempo ---
	gs.caixas_lista.clear()
	for it in ["treadmill", "jump_rope", "speed_bag", "grappling_dummy"]:
		gs._criar_caixa(it, "apparatus")
	gs._criar_caixa("glove_l1", "glove")
	gs._criar_caixa("glove_l2", "glove")
	gs.caixas_mudaram.emit()
	await frames(5)
	var lutador := Rect2(281, 150, 82, 125)
	var itens: Array = sala._caixas.keys()
	for a in itens:
		var ra: Rect2 = sala._caixas[a].area()
		var tela: Rect2 = Rect2(0, 0, 384, 272)
		p("caixa %s area=%s dentro_da_sala=%s alvo=%s lutador=%s" % [a, str(ra), str(tela.encloses(ra)), str(ra.intersects(ALVO)), str(ra.intersects(lutador))])
		for b in itens:
			if a < b and ra.intersects(sala._caixas[b].area()):
				p("SOBREPOE %s x %s" % [a, b])
	await frames(2)
	quit(0)
