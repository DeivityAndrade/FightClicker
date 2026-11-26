extends SceneTree
## Aperta o menu principal (ID4) por teclado/controle simulado e confere os sinais. Headless: `--headless --script res://tools/ui/verificar_menu.gd`.
## Usa `dados_teste`: não toca o save, as opções nem a janela.

var falhas := 0
var ultimo := ""


func _ok(cond: bool, nome: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", nome])
	if not cond:
		falhas += 1


func _acao(a: String) -> void:
	var e := InputEventAction.new()
	e.action = a
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	await process_frame


func _menu(tem_save: bool, animar: bool = false) -> Control:
	var m: Control = load("res://ui/menu_principal.gd").new()
	m.dados_teste = {"tem_save": tem_save, "camadas": ["soco"], "volume_geral": 0.8, "volume_efeitos": 0.5}
	m.animar = animar
	ultimo = ""
	m.escolheu.connect(func(a: String) -> void: ultimo = a)
	root.add_child(m)
	await process_frame
	if not animar:
		m.ir_para_ms(860.0)
	return m


func _initialize() -> void:
	await process_frame
	var gs := root.get_node("GameState")
	gs.inicializar("user://test/verificar_menu/", "res://data/config.json")
	gs.autosave_ativo = false

	# intro: uma tecla pula
	var m = await _menu(true, true)
	_ok(m._ms < 860.0, "intro começa antes de 860 ms")
	var k := InputEventKey.new()
	k.keycode = KEY_SPACE
	k.pressed = true
	Input.parse_input_event(k)
	await process_frame
	await process_frame
	_ok(m._ms >= 860.0, "tecla pula a intro")
	m.queue_free()

	# CONTINUAR
	m = await _menu(true)
	_ok(m._ids == ["continuar", "novo_jogo", "opcoes", "sair"], "com save: 4 botões, CONTINUAR primeiro")
	await _acao("ui_accept")
	_ok(ultimo == "continuar", "Enter em CONTINUAR emite continuar")
	m.queue_free()

	# sem save: sem CONTINUAR, NOVO JOGO direto
	m = await _menu(false)
	_ok(m._ids == ["novo_jogo", "opcoes", "sair"], "sem save: 3 botões")
	await _acao("ui_accept")
	_ok(ultimo == "novo_jogo", "sem save, NOVO JOGO não pede confirmação")
	m.queue_free()

	# confirmação dupla
	m = await _menu(true)
	await _acao("ui_down")
	_ok(m._foco == 1, "seta para baixo vai a NOVO JOGO")
	await _acao("ui_accept")
	_ok(m._jan_tipo == "confirma1", "NOVO JOGO com save abre a 1ª pergunta")
	await _acao("ui_cancel")
	_ok(m._jan_tipo == "" and ultimo == "", "Esc volta sem emitir")
	await _acao("ui_accept")
	await _acao("ui_accept")  # foco inicial em VOLTAR
	_ok(m._jan_tipo == "" and ultimo == "", "Enter no foco inicial (VOLTAR) não avança")
	await _acao("ui_accept")
	await _acao("ui_right")
	await _acao("ui_accept")
	_ok(m._jan_tipo == "confirma2", "SIM abre a 2ª pergunta")
	await _acao("ui_cancel")
	_ok(ultimo == "", "Esc na 2ª pergunta não apaga nada")
	await _acao("ui_accept")
	await _acao("ui_right")
	await _acao("ui_accept")
	await _acao("ui_right")
	await _acao("ui_accept")
	_ok(ultimo == "novo_jogo", "só depois das duas confirmações emite novo_jogo")
	m.queue_free()

	# opções
	m = await _menu(true)
	await _acao("ui_down")
	await _acao("ui_down")
	await _acao("ui_accept")
	_ok(m._jan_tipo == "opcoes", "OPÇÕES abre a janela")
	await _acao("ui_left")
	_ok(is_equal_approx(m._barras[0].valor, 0.75), "seta para a esquerda baixa o volume em 5%")
	await _acao("ui_down")
	await _acao("ui_down")
	await _acao("ui_accept")
	_ok(m._op_tela_cheia, "Enter alterna tela cheia (só em memória no teste)")
	await _acao("ui_cancel")
	_ok(m._jan_tipo == "", "Esc fecha as opções")
	m.queue_free()

	# SAIR
	m = await _menu(true)
	await _acao("ui_up")
	_ok(m._ids[m._foco] == "sair", "seta para cima no primeiro vai ao último")
	await _acao("ui_accept")
	_ok(ultimo == "sair", "SAIR emite sair")

	print("MENU: %s (%d falhas)" % ["OK" if falhas == 0 else "FALHOU", falhas])
	quit(1 if falhas > 0 else 0)
