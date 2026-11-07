extends SceneTree
## QA Fase 4b: entrada sintética pela UI (Shift, SEGURAR, teclas 1/2/3, Espaço, marca no chão).
## Uso: godot --path . --resolution 1280x720 --script res://tests/qa_f4b_ui.gd -- --save-dir=user://test/qa_ui/

var gs: Node
var cena: Control
var sala
var fluxo
var barra
var faixa
var falhas := 0


func win(p: Vector2) -> Vector2:
	return root.get_final_transform() * p


func tecla(k: Key, pressed: bool, echo := false) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = pressed
	ev.echo = echo
	Input.parse_input_event(ev)


func mouse(p: Vector2, pressed: bool) -> void:
	var m := InputEventMouseMotion.new()
	m.position = win(p)
	m.global_position = m.position
	Input.parse_input_event(m)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = win(p)
	ev.global_position = ev.position
	ev.pressed = pressed
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(ev)


func frames(n: int) -> void:
	for i in n:
		await process_frame


func ok(c: bool, nome: String) -> void:
	if not c:
		falhas += 1
	print(("PASS  " if c else "FAIL  ") + nome)


func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	sala = cena.get_node("Sala")
	fluxo = cena.get_node("Fluxo")
	barra = cena.get_node("BarraBaixo")
	faixa = _achar(cena, "FaixaAssistido")
	await frames(20)
	gs.apagar_save()
	await frames(5)
	print("save dir: ", gs.store.pasta, " faixa=", faixa)
	await _testes()
	print("FALHAS: ", falhas)
	quit(1 if falhas > 0 else 0)


func _achar(n: Node, classe: String) -> Node:
	if n.get_script() != null and str(n.get_script().get_global_name()) == classe:
		return n
	for c in n.get_children():
		var r := _achar(c, classe)
		if r != null:
			return r
	return null


func _testes() -> void:
	ok(gs.store.pasta.begins_with("user://test"), "pasta de teste ativa")
	ok(gs.aparelhos_montados() == ["punching_bag"], "começa só com o saco")
	# --- teclas 1/2/3 e Espaço com tudo trancado ---
	for k in [KEY_2, KEY_3, KEY_1, KEY_2]:
		tecla(k, true)
		tecla(k, false)
		await frames(2)
	ok(gs.foco == "punching_bag", "teclas 1/2/3 com trancados: foco continua no saco (foco=%s)" % gs.foco)
	var t0: float = gs.treino
	var n0 := 0
	var att0: Dictionary = gs.atributos.duplicate()
	tecla(KEY_SPACE, true)
	tecla(KEY_SPACE, false)
	await frames(2)
	ok(gs.treino > t0, "Espaço treina o saco")
	ok(gs.atributos.agility == att0.agility and gs.atributos.endurance == att0.endurance, "Espaço não treina atributo de trancado")
	# Shift+Espaço, Shift+1
	tecla(KEY_SHIFT, true)
	await frames(2)
	var t1: float = gs.treino
	tecla(KEY_SPACE, true)
	tecla(KEY_SPACE, false)
	tecla(KEY_3, true)
	tecla(KEY_3, false)
	await frames(2)
	ok(gs.treino > t1 and gs.foco == "punching_bag", "Shift+Espaço treina; Shift+3 não troca para trancado")
	tecla(KEY_SHIFT, false)
	await frames(2)
	# --- Shift ---
	ok(not gs.assistido_segurando(), "solto: não segurando")
	tecla(KEY_SHIFT, true)
	await frames(2)
	ok(gs.assistido_segurando(), "Shift pressionado: segurando")
	tecla(KEY_SHIFT, true, true)  # eco
	tecla(KEY_SHIFT, true, true)
	await frames(2)
	ok(gs.assistido_segurando(), "eco do Shift não desliga")
	tecla(KEY_SHIFT, false)
	await frames(2)
	ok(not gs.assistido_segurando(), "Shift solto: não segurando")
	# Soltar Shift não deve "ligar" depois: toque curto
	tecla(KEY_SHIFT, true)
	tecla(KEY_SHIFT, false)
	await frames(2)
	ok(not gs.assistido_segurando(), "toque curto não deixa ligado")
	# --- botão SEGURAR ---
	var b: Button = faixa._botao
	var centro: Vector2 = (b.get_global_rect().get_center())
	var cen_base: Vector2 = centro  # coordenadas do viewport base
	mouse(cen_base, true)
	await frames(2)
	ok(gs.assistido_segurando(), "botão SEGURAR pressionado: segurando")
	# Shift + botão juntos, solta o Shift: continua
	tecla(KEY_SHIFT, true)
	await frames(2)
	tecla(KEY_SHIFT, false)
	await frames(2)
	ok(gs.assistido_segurando(), "Shift solto com botão ainda pressionado: continua segurando")
	mouse(cen_base, false)
	await frames(2)
	ok(not gs.assistido_segurando(), "soltou os dois: não segurando")
	# Shift + botão, solta o botão: continua
	tecla(KEY_SHIFT, true)
	mouse(cen_base, true)
	await frames(2)
	mouse(cen_base, false)
	await frames(2)
	ok(gs.assistido_segurando(), "botão solto com Shift ainda pressionado: continua segurando")
	# Perde o foco da janela com Shift apertado
	faixa.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	gs.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await frames(2)
	ok(not gs.assistido_segurando(), "perda de foco solta o Shift")
	# Depois de voltar o foco, o Shift continua fisicamente apertado: o jogo não soca até novo aperto (esperado)
	tecla(KEY_SHIFT, false)
	await frames(2)
	# Botão apertado, perde foco (mouse preso)
	mouse(cen_base, true)
	await frames(2)
	faixa.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await frames(2)
	ok(not gs.assistido_segurando(), "perda de foco solta o botão")
	mouse(cen_base, false)
	await frames(2)
	# --- soca de verdade pela UI: Shift 7 s sem clicar ---
	var s0: int = gs.assist_socos_total
	tecla(KEY_SHIFT, true)
	var t_ini := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t_ini < 7500:
		await process_frame
	var s1: int = gs.assist_socos_total - s0
	tecla(KEY_SHIFT, false)
	print("   socos do assistido em 7,5 s reais: ", s1)
	ok(s1 >= 2 and s1 <= 3, "assistido pela UI: 2-3 socos em 7,5 s (obtido %d)" % s1)
	# --- clique na marca do chão: não treina, não troca foco, abre aba TREINO ---
	var marcas: Dictionary = sala._marcas
	var r: Rect2 = marcas["treadmill"].rect
	var t2: float = gs.treino
	var cnt: int = gs.auto_socos_total
	var cliques := [0]
	gs.clicou.connect(func(_a, _b, _c, _d, _e): cliques[0] += 1)
	var alvo: Vector2 = r.get_center() + sala.position  # a sala trata event.position + position
	# sala._gui_input recebe posição local
	mouse(r.get_center() - Vector2(0, 0) + Vector2(0, 0), true)
	mouse(r.get_center(), false)
	await frames(3)
	print("   cliques gerados pela marca: ", cliques[0], " foco=", gs.foco, " rect=", r)
	ok(cliques[0] == 0 and gs.foco == "punching_bag", "clique na marca da esteira: sem treino, foco igual")
	# --- compra pelo jogo e verifica UI/foco ---
	gs.treino = 600.0
	await frames(3)
	gs.comprar_aparelho("treadmill")
	await frames(30)
	ok(gs.foco == "treadmill" and gs.treino == 100.0, "compra: foco na esteira, treino 100")
	tecla(KEY_3, true)
	tecla(KEY_3, false)
	await frames(2)
	ok(gs.foco == "treadmill", "tecla 3 com corda trancada: foco continua na esteira")
	tecla(KEY_1, true)
	tecla(KEY_1, false)
	await frames(2)
	ok(gs.foco == "punching_bag", "tecla 1 volta ao saco")
	tecla(KEY_2, true)
	tecla(KEY_2, false)
	await frames(2)
	ok(gs.foco == "treadmill", "tecla 2 (esteira montada) troca para a esteira")
	# --- Shift durante prévia/luta ---
	gs.treino = 1.0e6
	tecla(KEY_SHIFT, true)
	await frames(2)
	var s2: int = gs.assist_socos_total
	# abre a prévia clicando em LUTAR via barra
	var lutar: Button = barra._lutar
	var pc: Vector2 = lutar.get_global_rect().get_center()
	mouse(pc, true)
	mouse(pc, false)
	await frames(10)
	print("   janela da prévia aberta: ", fluxo.janela != null, " estado assist: ", gs.assistido_estado())
	var t_ini2 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t_ini2 < 4500:
		await process_frame
	ok(gs.assist_socos_total == s2, "Shift apertado com a prévia aberta: 0 socos (%d)" % (gs.assist_socos_total - s2))
	tecla(KEY_SHIFT, false)
	await frames(2)
	# fecha janelas com ESC
	for i in 3:
		tecla(KEY_ESCAPE, true)
		tecla(KEY_ESCAPE, false)
		await frames(5)
	print("   janela depois do ESC: ", fluxo.janela != null)
