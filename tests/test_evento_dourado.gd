extends "res://tests/test_base.gd"
## Testa o evento dourado e o FRENESI: o cinturão dourado aparece de tempos em tempos, expira se ninguém clicar, não conta
## com janela/luta aberta, e clicar nele liga o FRENESI (multiplicador e duração vêm de golden_event, sem tocar na renda da equipe).

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0  # sem crítico: o ganho do clique fica exato
	gs.dados.golden_crew_chance = 0.0  # só a luva x7 (a bolsa é testada em test_fase52)
	return gs


func _passar(gs: Node, segundos: float) -> void:
	for i in int(round(segundos * 10.0)):
		gs.tick(0.1)


## Avança até o cinturão aparecer (no máximo `limite` s) e devolve quantos segundos levou.
func _ate_aparecer(gs: Node, limite: float) -> float:
	var t := 0.0
	while gs.evento_dourado_restante <= 0.0 and t < limite:
		gs.tick(0.1)
		t += 0.1
	return t


func rodar_testes() -> void:
	_teste_aparece_e_expira()
	_teste_pegar_liga_frenesi()
	_teste_janela_aberta_nao_conta()


func _teste_aparece_e_expira() -> void:
	var gs := _novo("dourado_aparece")
	var vezes := []
	gs.evento_dourado.connect(func(d: float) -> void: vezes.append(d))
	var emin: float = gs.EVENTO_ESPERA_MIN
	var emax: float = gs.EVENTO_ESPERA_MAX
	_passar(gs, emin - 1.0)
	checar_igual(vezes.size(), 0, "antes do mínimo de espera nunca aparece")
	var t := emin - 1.0 + _ate_aparecer(gs, emax)  # sorteio entre o mínimo e o máximo dos dados
	checar(t >= emin - 0.1 and t <= emax + 0.2, "apareceu dentro da espera dos dados (%.1f s)" % t)
	checar_igual(vezes.size(), 1, "aparece uma vez")
	checar(gs.evento_dourado_restante > 0.0, "o cinturão está esperando o clique")
	_passar(gs, gs.EVENTO_DURACAO + 0.5)
	checar_igual(gs.evento_dourado_restante, 0.0, "ninguém clicou: o cinturão some após visible_seconds")
	checar(not gs.pegar_evento_dourado(), "sem cinturão, não dá para pegar")
	checar_igual(gs.mult_frenesi(), 1.0, "sem frenesi: x1")
	_liberar(gs)


func _teste_pegar_liga_frenesi() -> void:
	var gs := _novo("dourado_frenesi")
	_ate_aparecer(gs, gs.EVENTO_ESPERA_MAX + 1.0)
	checar(gs.evento_dourado_restante > 0.0, "cinturão na sala")
	var sinais := []
	gs.frenesi_mudou.connect(func(r: float) -> void: sinais.append(r))
	var base: float = gs.por_clique()
	checar(gs.pegar_evento_dourado(), "clicar no cinturão liga o frenesi")
	var fm: float = gs.FRENESI_MULT
	var fd: float = gs.FRENESI_DURACAO
	checar_igual(gs.mult_frenesi(), fm, "frenesi: multiplicador dos dados")
	var antes: float = gs.treino
	gs.clicar()
	checar_igual(gs.treino - antes, base * fm, "o clique rende o multiplicador dos dados")
	antes = gs.treino
	gs.auto_socar()
	checar_igual(gs.treino - antes, gs.por_auto_soco() * fm, "o auto-soco também rende o multiplicador")
	_passar(gs, fd - 0.5)
	checar_igual(gs.mult_frenesi(), fm, "meio segundo antes do fim ainda vale")
	_passar(gs, 1.0)
	checar_igual(gs.mult_frenesi(), 1.0, "depois de frenzy_seconds acaba")
	checar_igual(sinais.size(), 2, "sinal ao ligar e ao desligar")
	antes = gs.treino
	gs.clicar()
	checar_igual(gs.treino - antes, base, "voltou ao normal")
	# Nova carreira zera o evento
	gs.evento_dourado_restante = 3.0
	gs.frenesi_restante = 5.0
	gs._zerar_carreira()
	checar_igual([gs.evento_dourado_restante, gs.frenesi_restante], [0.0, 0.0], "nova carreira zera o evento e o frenesi")
	_liberar(gs)


func _teste_janela_aberta_nao_conta() -> void:
	var gs := _novo("dourado_janela")
	var vezes := []
	gs.evento_dourado.connect(func(d: float) -> void: vezes.append(d))
	gs.definir_modal(true)
	_passar(gs, 200.0)
	checar_igual(vezes.size(), 0, "com janela/luta aberta o relógio do evento espera")
	checar(not gs.pegar_evento_dourado(), "com janela aberta não dá para pegar")
	gs.definir_modal(false)
	_ate_aparecer(gs, gs.EVENTO_ESPERA_MAX + 1.0)
	checar_igual(vezes.size(), 1, "ao fechar a janela o evento volta a correr")
	_liberar(gs)


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()
