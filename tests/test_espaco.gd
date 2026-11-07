extends "res://tests/test_base.gd"
## Espaço treina na garagem (mesmo efeito do clique no alvo): só no aperto, sem repetir ao segurar, e nunca com janela
## aberta, durante a luta ou com F12 por cima; o Espaço também não pode apertar nenhum botão (nem o focado).
## Usa a cena principal com o autoload GameState apontando para user://test/ (nunca o save real).

var gs: Node
var cena: Control
var cliques := 0


func _tecla(codigo: Key, apertada: bool, eco: bool = false) -> void:
	var ev := InputEventKey.new()
	ev.keycode = codigo
	ev.physical_keycode = codigo
	ev.pressed = apertada
	ev.echo = eco
	root.push_input(ev)


func _espaco_apertar_e_soltar() -> void:
	_tecla(KEY_SPACE, true)
	_tecla(KEY_SPACE, false)


## Para os sons (um som ainda tocando segura o recurso de áudio ao sair do jogo), solta a cena e espera o áudio esvaziar.
func _soltar_cena() -> void:
	if cena == null:
		return
	for p in cena.find_children("*", "AudioStreamPlayer", true, false):
		(p as AudioStreamPlayer).stop()
	cena.queue_free()
	cena = null
	await process_frame
	await create_timer(0.25).timeout


func _novo_jogo() -> void:
	await _soltar_cena()
	gs.inicializar(pasta_limpa("espaco"), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0  # sem crítico: o ganho de cada clique fica exato
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	for i in 4:
		await process_frame


func _numeros_ativos() -> int:
	var n := 0
	for num in cena.get_node("Sala")._numeros:
		if num.ativo:
			n += 1
	return n


func rodar_testes() -> void:
	gs = root.get_node("GameState")
	gs.clicou.connect(func(_g: float, _c: bool, _a: String, _b: String, _t: String) -> void: cliques += 1)

	# 1) Espaço treina: soma `por_clique()`, emite `clicou` e a sala mostra o número flutuante.
	await _novo_jogo()
	var esperado: float = gs.por_clique()
	var t0: float = gs.treino
	var c0 := cliques
	_espaco_apertar_e_soltar()
	await process_frame
	checar_igual(gs.treino, t0 + esperado, "Espaço soma um clique de treino")
	checar_igual(cliques, c0 + 1, "Espaço emite o sinal clicou uma vez")
	checar(_numeros_ativos() >= 1, "Espaço mostra o número flutuante na sala")

	# 2) Segurar não repete: o aperto vale 1; as repetições (echo) são ignoradas.
	var t1: float = gs.treino
	_tecla(KEY_SPACE, true)
	for i in 12:
		_tecla(KEY_SPACE, true, true)
	_tecla(KEY_SPACE, false)
	checar_igual(gs.treino, t1 + esperado, "segurar Espaço rende só 1 clique (echo ignorado)")

	# 3) Cada aperto novo conta.
	var t2: float = gs.treino
	for i in 3:
		_espaco_apertar_e_soltar()
	checar_igual(gs.treino, t2 + 3.0 * esperado, "3 apertos = 3 cliques")

	# 4) Nenhum botão da garagem aceita foco, então Espaço (ui_accept) não aperta nenhum.
	var botoes := cena.find_children("*", "Button", true, false)
	var focaveis := 0
	for b in botoes:
		if (b as Button).focus_mode != Control.FOCUS_NONE:
			focaveis += 1
	checar_igual(focaveis, 0, "todos os botões da garagem têm focus_mode = NONE")

	# 5) Com a prévia aberta: Espaço não treina e não aperta LUTAR!/VOLTAR (mesmo tentando focar o botão).
	await _novo_jogo()
	var fluxo: Node = cena.get_node("Fluxo")
	var t3: float = gs.treino
	fluxo.abrir_previa()
	await process_frame
	checar(fluxo.janela != null, "a prévia abriu")
	var apertos := [0]
	fluxo.janela.lutar_pedido.connect(func() -> void: apertos[0] += 1)
	fluxo.janela.voltar_pedido.connect(func() -> void: apertos[0] += 1)
	for b in fluxo.janela.find_children("*", "Button", true, false):
		checar_igual((b as Button).focus_mode, Control.FOCUS_NONE, "botão da prévia não aceita foco")
	_espaco_apertar_e_soltar()
	_tecla(KEY_ENTER, true)
	_tecla(KEY_ENTER, false)
	await process_frame
	checar_igual(gs.treino, t3, "Espaço com a prévia aberta não treina")
	checar_igual(apertos[0], 0, "Espaço/Enter com a prévia aberta não apertam botão")
	checar(fluxo.janela != null and gs.luta.is_empty(), "a prévia continua aberta e nenhuma luta começou")

	# 6) Durante a luta Espaço não treina.
	fluxo.janela.lutar_pedido.emit()
	await process_frame
	checar(fluxo.tela.visible and gs.tem_luta_pendente(), "a luta começou")
	var t4: float = gs.treino
	_espaco_apertar_e_soltar()
	checar_igual(gs.treino, t4, "Espaço durante a luta não treina")

	# 7) Com F12 aberto Espaço não treina.
	await _novo_jogo()
	var am: Node = root.get_node("AppControls")
	_tecla(KEY_F12, true)
	_tecla(KEY_F12, false)
	await process_frame
	checar(am.debug_visivel, "F12 abriu a depuração")
	var t5: float = gs.treino
	_espaco_apertar_e_soltar()
	checar_igual(gs.treino, t5, "Espaço com F12 aberto não treina")
	_tecla(KEY_F12, true)
	_tecla(KEY_F12, false)
	await process_frame
	_espaco_apertar_e_soltar()
	checar_igual(gs.treino, t5 + esperado, "fechando o F12, Espaço volta a treinar")

	# 8) Tela de fim: Espaço não treina.
	await _novo_jogo()
	gs.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
	gs.lutar()
	gs.aguardar_motivo()
	gs.concluir_luta()
	await process_frame
	checar(gs.tem_fim_pendente(), "a carreira acabou (tela de fim)")
	var t6: float = gs.treino
	_espaco_apertar_e_soltar()
	checar_igual(gs.treino, t6, "Espaço na tela de fim não treina")

	await _soltar_cena()
	load("res://ui/ui_tema.gd").liberar_cache()  # (sem citar a classe: ela depende do autoload GameState na compilação)
