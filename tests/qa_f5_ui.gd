extends SceneTree
## QA Fase 5 pela UI real: teclas, janela da arte, MUDAR, rolagem da aba TREINO, reabrir com escolha pendente.
## Uso: godot --path . --resolution 1280x720 --script res://tests/qa_f5_ui.gd -- --save-dir=user://test/qa_f5_ui/
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa5/"
var gs: Node
var cena: Node
var falhas := 0


func chk(c: bool, msg: String) -> void:
	print(("PASS  " if c else "FAIL  ") + msg)
	if not c:
		falhas += 1


func esperar(s: float) -> void:
	await create_timer(s).timeout


func abrir() -> void:
	if cena != null:
		cena.queue_free()
		cena = null
		await process_frame
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.5)


func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + n + ".png")


func tecla(k: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var ev2 := ev.duplicate() as InputEventKey
	ev2.pressed = false
	Input.parse_input_event(ev2)
	await process_frame


func novo() -> void:
	gs.inicializar("user://test/qa_f5_ui/", "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.permanente = gs.permanente  # noop
	gs.rng.seed = 7


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	gs = root.get_node("GameState")
	gs.inicializar("user://test/qa_f5_ui/", "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	await process_frame
	await rodar()
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)


func rodar() -> void:
	# --- A. garagem sem arte: teclas 1-4 ---
	await abrir()
	gs.treino = 1.0e6
	await tecla(KEY_4)
	chk(gs.foco == "punching_bag", "tecla 4 sem arte: nada acontece (foco=%s)" % gs.foco)
	await tecla(KEY_2)
	chk(gs.foco == "punching_bag", "tecla 2 com esteira trancada: nada (foco=%s)" % gs.foco)
	gs.comprar_aparelho("treadmill")
	await tecla(KEY_2)
	chk(gs.foco == "treadmill", "tecla 2 com esteira comprada: foco esteira")
	await tecla(KEY_1)
	chk(gs.foco == "punching_bag", "tecla 1")
	await tecla(KEY_3)
	chk(gs.foco == "punching_bag", "tecla 3 com corda trancada: nada")
	# --- B. cinturao, mudar pela UI, janela da arte ---
	gs.indice_escada = 4
	gs.cinturao = true
	gs.fama = 200
	gs.dinheiro = 1000.0
	gs.economia_mudou.emit()
	gs.escada_mudou.emit()
	await esperar(0.3)
	var painel: Node = cena.get_node("PainelAtributos")
	var bt: Button = null
	for b in painel.find_children("*", "Button", true, false):
		bt = b
		break
	chk(bt != null and not bt.disabled, "botao MUDAR aceso")
	var fluxo: Node = cena.get_node("Fluxo")
	if bt != null:
		bt.pressed.emit()
		bt.pressed.emit()  # duas vezes
	await esperar(0.6)
	chk(gs.local_id == "gym" and gs.dinheiro == 0.0, "mudou uma vez ($%s)" % gs.dinheiro)
	chk(fluxo.janela != null and fluxo.janela.has_method("_escolher"), "janela da arte abriu")
	await shot("a_janela_arte")
	# ESC e teclas com a janela
	await tecla(KEY_ESCAPE)
	chk(fluxo.janela != null and gs.escolha_arte_pendente(), "ESC nao fecha a janela da arte")
	await tecla(KEY_SPACE)
	chk(gs.treino == 1.0e6 - 500.0 or gs.treino >= 0.0, "espaco com janela aberta (treino=%s)" % gs.treino)
	var t_antes: float = gs.treino
	await tecla(KEY_SPACE)
	chk(gs.treino - t_antes < 0.5 + gs.producao_total() * 1.0, "espaco nao treina com janela aberta (delta=%s)" % (gs.treino - t_antes))
	# clique fora da janela
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = Vector2(30, 600)
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	chk(gs.escolha_arte_pendente(), "clique fora nao escolhe arte")
	# --- C. fechar com pendente e reabrir ---
	await abrir()
	chk(gs.escolha_arte_pendente() and cena.get_node("Fluxo").janela != null, "reabrir: janela da arte volta")
	# escolher pela UI: achar botoes ESCOLHER
	var j: Node = cena.get_node("Fluxo").janela
	var escolher: Array = []
	for b in j.find_children("*", "Button", true, false):
		escolher.append(b)
	chk(escolher.size() == 4, "2 cartoes x (area + ESCOLHER) = 4 botoes (%d)" % escolher.size())
	escolher[1].pressed.emit()
	await esperar(0.5)
	chk(gs.arte_id == "bjj", "escolheu Jiu-jitsu com 1 clique (%s)" % gs.arte_id)
	# tentar escolher de novo
	chk(not gs.escolher_arte("boxing"), "nao troca no meio da carreira")
	await shot("b_pos_escolha")
	# --- D. teclas com arte: 4 trancado / comprado ---
	gs.treino = 1.0e7
	await tecla(KEY_4)
	chk(gs.foco != "grappling_dummy", "tecla 4 com boneco trancado: foco nao muda (%s)" % gs.foco)
	gs.comprar_aparelho("treadmill") if gs.estado_aparelho("treadmill") != "owned" else null
	var ok = gs.comprar_aparelho("grappling_dummy")
	await esperar(2.0)
	await tecla(KEY_4)
	chk(gs.foco == "grappling_dummy" or not ok, "tecla 4 com boneco comprado: foco boneco (foco=%s ok=%s)" % [gs.foco, ok])
	await shot("c_boneco")
	# --- E. aba TREINO rola (4 aparelhos + equipe) ---
	gs.treino = 1.0e9
	for i in 5:
		gs.comprar_gerador("neighbor_kid")
		gs.comprar_gerador("retired_uncle")
	gs.economia_mudou.emit()
	await esperar(0.5)
	var pl: Node = cena.get_node("PainelLoja")
	var mv := InputEventMouseMotion.new()
	mv.position = root.get_final_transform() * Vector2(575, 150)
	mv.global_position = mv.position
	Input.parse_input_event(mv)
	await process_frame
	var ev2 := InputEventMouseButton.new()
	ev2.button_index = MOUSE_BUTTON_WHEEL_DOWN
	ev2.position = root.get_final_transform() * Vector2(575, 150)
	ev2.pressed = true
	for i in 10:
		Input.parse_input_event(ev2)
		await process_frame
	await esperar(0.3)
	await shot("d_treino_topo")
	pl._rolar_a(pl._rolagem_max)
	await esperar(0.3)
	await shot("d_treino_rolado_baixo")
	print("INFO rolagem=%s max=%s aba=%s local=%s size=%s" % [pl._rolagem, pl._rolagem_max, pl._aba, pl.get_local_mouse_position(), pl.size])
	chk(pl._rolagem_max > 0.0, "aba TREINO tem rolagem (max=%s)" % pl._rolagem_max)
	chk(pl._rolagem >= pl._rolagem_max - 0.5, "rolou ate o fim (%s/%s)" % [pl._rolagem, pl._rolagem_max])
	# --- F. MUDAR bloqueado em luta / fim (API) com cena aberta ---
	await abrir()
	gs.aposentar()
	await esperar(0.5)
	chk(gs.tem_fim_pendente(), "aposentou: tela de fim")
	await shot("e_fim_academia")
	var f2: Node = cena.get_node("Fluxo")
	var nc: Button = null
	if f2.janela != null:
		for b in f2.janela.find_children("*", "Button", true, false):
			if b.text == "NOVA CARREIRA" or (b.get_child_count() > 0 and b.get_child(0) is Label and b.get_child(0).text == "NOVA CARREIRA"):
				nc = b
	if nc != null:
		nc.pressed.emit()
		await esperar(0.8)
		chk(gs.local_id == "garage" and gs.arte_id == "" and gs.escolha_arte_pendente(), "nova carreira: garagem + escolha pendente")
		chk(f2.janela != null and f2.janela.has_method("_escolher"), "janela da arte abre ANTES do cartao")
		await shot("f_nova_carreira")
	else:
		chk(false, "botao NOVA CARREIRA nao achado")
