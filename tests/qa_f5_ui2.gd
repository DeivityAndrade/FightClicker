extends SceneTree
## QA Fase 5 (rodada 2): vitoria do cinturao (MUDAR x CONTINUAR x automatica), fechar com a vitoria aberta, rounds/especial
## na luta real, corda girando. Janela real. Uso:
##   godot --path . --resolution 1280x720 --script res://tests/qa_f5_ui2.gd -- --save-dir=user://test/qa_f5_ui2/
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa5b/"
var gs: Node
var cena: Node
var falhas := 0


func chk(c: bool, msg: String) -> void:
	print(("PASS  " if c else "FAIL  ") + msg)
	if not c:
		falhas += 1


func esperar(s: float) -> void:
	await create_timer(s, true, false, true).timeout


func abrir() -> void:
	if cena != null:
		cena.queue_free()
		cena = null
		await process_frame
		await process_frame
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await esperar(0.5)


func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + n + ".png")


func achar_botao(raiz: Node, parte: String) -> Button:
	if raiz is Button and raiz.visible:
		var b := raiz as Button
		if b.text.contains(parte):
			return b
		for c in b.find_children("*", "Label", true, false):
			if c.text.contains(parte):
				return b
	for c in raiz.get_children():
		var r := achar_botao(c, parte)
		if r != null:
			return r
	return null


func nome_janela(j) -> String:
	return j.get_script().get_global_name() if j != null and j.get_script() != null else "null"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	gs = root.get_node("GameState")
	await process_frame
	await rodar()
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)


func preparar_muralha() -> void:
	gs.inicializar("user://test/qa_f5_ui2/", "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.indice_escada = 3
	gs.cinturao = false
	gs.fama = 100
	gs.dinheiro = 123.0
	gs.atributos = {"strength": 8.0e6, "agility": 8.0e6, "endurance": 8.0e7}
	gs.rng.seed = 3


## Luta e espera a janela de vitoria (ou o tempo limite). Devolve a janela.
func lutar_ate_vitoria() -> Node:
	var fluxo: Node = cena.get_node("Fluxo")
	gs.lutar()
	var t := 0.0
	var snaps := 0
	while t < 40.0:
		await esperar(0.25)
		t += 0.25
		if t > 2.0 and snaps < 4 and int(t * 4) % 16 == 0:
			await shot("luta_t%d" % int(t))
			snaps += 1
		if fluxo.janela != null and nome_janela(fluxo.janela) == "JanelaVitoria":
			await esperar(1.0)
			return fluxo.janela
	return null


func rodar() -> void:
	Engine.time_scale = 1.0
	# --- A1: vitoria sem botao MUDAR ---
	preparar_muralha()
	await abrir()
	var fluxo: Node = cena.get_node("Fluxo")
	var jan: Node = await lutar_ate_vitoria()
	chk(jan != null, "A1: janela de vitoria abriu")
	if jan != null:
		await shot("a1_vitoria")
		print("INFO A1 dinheiro=%s cinturao=%s local=%s" % [gs.dinheiro, gs.cinturao, gs.local_id])
		# O botao MUDAR foi removido de proposito: so existe CONTINUAR.
		chk(achar_botao(jan, "MUDAR") == null, "A1: nao existe botao MUDAR")
		chk(achar_botao(jan, "CONTINUAR") != null, "A1: existe o botao CONTINUAR")
		await shot("a1_depois")
	# A1 single press variant is covered by A2
	# --- A2: CONTINUAR ---
	preparar_muralha()
	await abrir()
	fluxo = cena.get_node("Fluxo")
	jan = await lutar_ate_vitoria()
	chk(jan != null, "A2: janela de vitoria abriu")
	if jan != null:
		var d0: float = gs.dinheiro
		var bc := achar_botao(jan, "CONTINUAR")
		chk(bc != null, "A2: botao CONTINUAR existe")
		bc.pressed.emit()
		await esperar(0.8)
		chk(gs.local_id == "gym", "A2: CONTINUAR tambem muda (automatico)")
		chk(absf(gs.dinheiro - (d0 - 1000.0)) < 0.01, "A2: cobrou 1000 uma vez (%s -> %s)" % [d0, gs.dinheiro])
		chk(fluxo.janela != null and nome_janela(fluxo.janela) == "JanelaArte", "A2: janela de arte abriu")
		print("INFO A2 Treino x2 HUD: ", gs.texto_hud_local())
	# --- A3: CONTINUAR e MUDAR na mesma hora ---
	preparar_muralha()
	await abrir()
	fluxo = cena.get_node("Fluxo")
	jan = await lutar_ate_vitoria()
	if jan != null:
		var d0: float = gs.dinheiro
		var bc := achar_botao(jan, "CONTINUAR")
		var bm := achar_botao(jan, "MUDAR")
		bc.pressed.emit()
		if is_instance_valid(bm):
			bm.pressed.emit()
		await esperar(0.8)
		chk(absf(gs.dinheiro - (d0 - 1000.0)) < 0.01, "A3: CONTINUAR+MUDAR cobram uma vez (%s -> %s)" % [d0, gs.dinheiro])
		var n_janelas := 0
		for f in cena.get_children():
			if f.get_script() != null and str(f.get_script().get_global_name()).begins_with("Janela"):
				n_janelas += 1
		chk(n_janelas <= 1, "A3: no maximo uma janela (%d)" % n_janelas)
		print("INFO A3 pendente=%s janela=%s acoes_bloqueadas=%s modal=%s" % [gs.escolha_arte_pendente(), nome_janela(fluxo.janela), gs.acoes_bloqueadas(), gs.modal_aberto])
	# --- A4: fechar o jogo com a vitoria aberta ---
	preparar_muralha()
	await abrir()
	fluxo = cena.get_node("Fluxo")
	jan = await lutar_ate_vitoria()
	if jan != null:
		var d0: float = gs.dinheiro
		gs.salvar()
		await abrir()  # recria a cena sem fechar a vitoria (simula quit)
		gs.inicializar("user://test/qa_f5_ui2/", "res://data/config.json")
		await esperar(0.3)
		print("INFO A4 reaberto: local=%s cinturao=%s dinheiro=%s estado_mudanca=%s janela=%s" % [gs.local_id, gs.cinturao, gs.dinheiro, gs.estado_mudanca(), nome_janela(cena.get_node("Fluxo").janela)])
		chk(gs.cinturao and gs.estado_mudanca() == "ready", "A4: reaberto com cinturao e MUDAR pronto (premio ficou)")
		await shot("a4_reaberto")
	# --- B: corda girando ---
	gs.inicializar("user://test/qa_f5_ui2/", "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.treino = 1.0e7
	gs.comprar_aparelho("treadmill")
	gs.comprar_aparelho("jump_rope")
	gs.definir_foco("jump_rope")
	await abrir()
	await esperar(1.5)
	gs.clicar()
	for i in 14:
		await RenderingServer.frame_post_draw
		if i % 2 == 0:
			await shot("corda_%02d" % i)
	# academia + corda
	gs.indice_escada = 4
	gs.cinturao = true
	gs.dinheiro = 1000.0
	gs.mudar()
	gs.escolher_arte("boxing")
	await esperar(0.8)
	gs.clicar()
	for i in 14:
		await RenderingServer.frame_post_draw
		if i % 2 == 0:
			await shot("corda_gym_%02d" % i)
	# --- C: luta na academia (Tonhao) com arte, 3 rounds ---
	gs.indice_escada = 4
	gs.atributos = {"strength": 2.0e5, "agility": 1.0e5, "endurance": 1.0e6}
	await esperar(0.3)
	gs.rng.seed = 21
	gs.lutar()
	var t := 0.0
	var f2: Node = cena.get_node("Fluxo")
	var n := 0
	while t < 40.0 and not (f2.janela != null and nome_janela(f2.janela) in ["JanelaVitoria", "JanelaFim"]):
		await esperar(0.5)
		t += 0.5
		if n < 10 and int(t * 2) % 5 == 0:
			await shot("tonhao_t%02d" % int(t))
			n += 1
	chk(t < 40.0, "C: luta do Tonhao terminou (%.1f s)" % t)
	print("INFO C janela=%s" % nome_nome(f2))


func nome_nome(f) -> String:
	return nome_janela(f.janela)
