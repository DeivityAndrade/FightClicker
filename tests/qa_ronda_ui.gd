extends SceneTree
## QA Ronda: a TELA (TelaRonda) em headless, com entradas de verdade (Espaco e mouse empurrados no viewport), 4 roteiros:
## (A) jogador perfeito, (B) segura sempre, (C) SAIR no meio, (D) perde o foco com o botao apertado, (E) clique do mouse.
## Usa o autoload GameState reiniciado numa pasta de teste (nunca o save real; rode com APPDATA temporario).

var gs: Node
var falhas := 0
var total := 0


func checar(c: bool, n: String) -> void:
	total += 1
	if not c:
		falhas += 1
	print(("PASS  " if c else "FAIL  ") + n)


func _novo(nome: String) -> void:
	var pasta := "user://test/%s/" % nome
	DirAccess.make_dir_recursive_absolute(pasta)
	for f in DirAccess.get_files_at(pasta):
		DirAccess.remove_absolute(pasta + f)
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.baloes_escondidos = true
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	gs.permanente["career_number"] = 3
	gs.escola.milestones["black_cat_rumor_heard"] = {"campaign": 2, "version": 1}
	gs.escola.milestones["garage_saved"] = {"version": 1}
	for _i in 181:
		gs.tick(1.0)


func _tecla(pressionada: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.physical_keycode = KEY_SPACE
	e.pressed = pressionada
	root.push_input(e)


func _mouse(pressionado: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressionado
	e.position = Vector2(300, 200)
	e.global_position = e.position
	root.push_input(e)


func _abrir() -> Control:
	var info: Dictionary = gs.ronda_ir()
	var TR = load("res://ui/tela_ronda.gd")
	var tela: Control = TR.new()
	root.add_child(tela)
	tela.abrir(info)
	return tela


func _quadro(dt: float = 1.0 / 30.0) -> void:
	gs.tick(dt)
	await process_frame


func _fim(tela: Control) -> void:
	tela.queue_free()
	await process_frame


func _initialize() -> void:
	await process_frame
	gs = root.get_node("GameState")
	print("== qa_ronda_ui ==")
	await _roteiro_a()
	await _roteiro_b()
	await _roteiro_c()
	await _roteiro_d()
	await _roteiro_e()
	print("%d/%d PASS" % [total - falhas, total])
	quit(1 if falhas > 0 else 0)


# (A) jogador perfeito: segura enquanto o ladrao trabalha, solta no aviso/olhando, aperta de novo quando perto
func _roteiro_a() -> void:
	_novo("qa_ui_a")
	var treino0: float = gs.treino
	var camp0: float = gs.segundos_campanha
	var tela := await _abrir()
	checar(gs.ronda_ativa == "scare" and not gs.sala_ativa(), "A: Ronda aberta e a sala parada")
	var segurando := false
	var eventos := []
	var n := 0
	while gs.ronda_jogo() != null and n < 3000:
		n += 1
		var j: RondaLogica = gs.ronda_jogo()
		var e: Dictionary = j.estado()
		if tela.janela == null and e.fase == "jogando" and e.oc_fase == "jogando":
			if e.perto and e.ladrao != "olhando":
				if segurando:
					_tecla(false)
					segurando = false
				_tecla(true)  # o aperto do SUSTO
				await _quadro()
				_tecla(false)
				continue
			var quer: bool = e.ladrao == "trabalha"
			if quer and not segurando:
				_tecla(true)
				segurando = true
			elif not quer and segurando:
				_tecla(false)
				segurando = false
		elif segurando and e.oc_fase != "jogando":
			_tecla(false)
			segurando = false
		await _quadro()
		if tela.janela != null:
			break
	var j2 = gs.ronda_jogo()
	checar(tela.janela != null and not tela.premio.is_empty(), "A: prêmio apareceu (%d quadros)" % n)
	checar(int(tela.premio.get("scares", 0)) == 3 and tela.premio.get("clean", false), "A: 3 sustos, ronda limpa (obtido %s)" % str(tela.premio.get("scares", "?")))
	checar(gs.treino == treino0 and gs.segundos_campanha == camp0, "A: treino e relógio parados durante a Ronda")
	checar(int(gs.lenda().legend) == 5 and int(gs.lenda().level) == 1, "A: lenda 5, nível 1")
	# ESPACO ainda apertado depois do prêmio nao mexe em nada; VOLTAR
	_tecla(true)
	_tecla(false)
	await _quadro()
	tela._voltar()
	await _quadro()
	checar(gs.ronda_ativa == "" and gs.sala_ativa(), "A: VOLTAR devolve a sala")
	await _fim(tela)


# (B) segura o Espaco o tempo todo: ESCAPOU nas 3, depois prêmio por "fim"
func _roteiro_b() -> void:
	_novo("qa_ui_b")
	var tela := await _abrir()
	_tecla(true)
	for _k in 90:
		await _quadro()
	print("  B apos 3 s: ", gs.ronda_jogo().estado())
	var n := 0
	while tela.janela == null and n < 4000:
		n += 1
		await _quadro()
	checar(tela.janela != null, "B: segurando sempre: a ronda acaba e mostra o prêmio (%d quadros)" % n)
	print("  B premio: ", tela.premio)
	print("  B n=", n, " tela.janela=", tela.janela != null)
	checar(int(tela.premio.get("scares", -1)) == 0 and int(tela.premio.get("seen", -1)) == 3, "B: 0 sustos, 3 ESCAPOU (obtido %s/%s)" % [str(tela.premio.get("scares")), str(tela.premio.get("seen"))])
	checar(int(tela.premio.get("legend_gain", -1)) == 1, "B: só ir dá +1 de lenda")
	_tecla(false)
	tela._voltar()
	await _quadro()
	await _fim(tela)


# (C) SAIR no meio
func _roteiro_c() -> void:
	_novo("qa_ui_c")
	var tela := await _abrir()
	for _i in 120:
		await _quadro()
	tela._sair()
	await _quadro()
	checar(tela.janela != null and str(tela.premio.get("ended", "")) == "exit" and int(tela.premio.get("legend_gain", 0)) == 1, "C: SAIR no meio: prêmio com +1 (ended=%s)" % str(tela.premio.get("ended")))
	tela._sair()  # de novo: nada
	checar(int(gs.lenda().rounds) == 1, "C: SAIR duas vezes nao conta duas rondas")
	tela._voltar()
	await _quadro()
	checar(gs.ronda_ativa == "", "C: voltou")
	await _fim(tela)


# (D) perde o foco com o botao apertado: o vulto nao anda sozinho
func _roteiro_d() -> void:
	_novo("qa_ui_d")
	var tela := await _abrir()
	for _i in 100:  # contagem (2 s) + intro (0,8 s)
		await _quadro()
	_tecla(true)
	for _i in 15:
		await _quadro()
	var d1: float = gs.ronda_jogo().estado().distancia
	tela.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	for _i in 15:
		await _quadro()
	var d2: float = gs.ronda_jogo().estado().distancia
	checar(d1 > 0.0 and absf(d2 - d1) < 0.02, "D: perdeu o foco: o vulto para de andar (%.3f -> %.3f)" % [d1, d2])
	_tecla(false)
	gs.ronda_voltar()
	await _quadro()
	await _fim(tela)


# (E) mouse: clique no corpo da tela segura/solta
func _roteiro_e() -> void:
	_novo("qa_ui_e")
	var tela := await _abrir()
	for _i in 100:
		await _quadro()
	_mouse(true)
	await _quadro()
	var seg: bool = gs.ronda_jogo().estado().segurando
	_mouse(false)
	await _quadro()
	var seg2: bool = gs.ronda_jogo().estado().segurando
	print("  mouse: segurando depois do clique = %s; depois de soltar = %s (clique empurrado no viewport, sem passar pelo foco da janela)" % [str(seg), str(seg2)])
	checar(not seg2, "E: soltar o mouse solta o vulto")
	gs.ronda_voltar()
	await _quadro()
	await _fim(tela)
