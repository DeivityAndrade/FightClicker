extends "res://tests/test_base.gd"
## Testa o evento dourado e o FRENESI: o cinturão dourado aparece de tempos em tempos, expira se ninguém clicar, não conta
## com janela/luta aberta, e clicar nele liga o FRENESI (x7 nos cliques e auto-socos por 12 s, sem tocar na renda da equipe).

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0  # sem crítico: o ganho do clique fica exato
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
	_passar(gs, 44.0)
	checar_igual(vezes.size(), 0, "antes de 45 s nunca aparece")
	var t := 44.0 + _ate_aparecer(gs, 60.0)  # o sorteio é entre 45 e 90 s
	checar(t >= 44.9 and t <= 90.2, "apareceu entre 45 e 90 s (%.1f s)" % t)
	checar_igual(vezes.size(), 1, "aparece uma vez")
	checar(gs.evento_dourado_restante > 0.0, "o cinturão está esperando o clique")
	_passar(gs, 7.5)
	checar_igual(gs.evento_dourado_restante, 0.0, "ninguém clicou: o cinturão some em 7 s")
	checar(not gs.pegar_evento_dourado(), "sem cinturão, não dá para pegar")
	checar_igual(gs.mult_frenesi(), 1.0, "sem frenesi: x1")
	_liberar(gs)


func _teste_pegar_liga_frenesi() -> void:
	var gs := _novo("dourado_frenesi")
	_ate_aparecer(gs, 100.0)
	checar(gs.evento_dourado_restante > 0.0, "cinturão na sala")
	var sinais := []
	gs.frenesi_mudou.connect(func(r: float) -> void: sinais.append(r))
	var base: float = gs.por_clique()
	checar(gs.pegar_evento_dourado(), "clicar no cinturão liga o frenesi")
	checar_igual(gs.mult_frenesi(), 7.0, "frenesi: x7")
	var antes: float = gs.treino
	gs.clicar()
	checar_igual(gs.treino - antes, base * 7.0, "o clique rende 7 vezes")
	antes = gs.treino
	gs.auto_socar()
	checar_igual(gs.treino - antes, gs.por_auto_soco() * 7.0, "o auto-soco também rende 7 vezes")
	_passar(gs, 11.5)
	checar_igual(gs.mult_frenesi(), 7.0, "aos 11,5 s ainda vale")
	_passar(gs, 1.0)
	checar_igual(gs.mult_frenesi(), 1.0, "depois de 12 s acaba")
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
	_ate_aparecer(gs, 100.0)
	checar_igual(vezes.size(), 1, "ao fechar a janela o evento volta a correr")
	_liberar(gs)


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()
