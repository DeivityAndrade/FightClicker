extends "res://tests/test_base.gd"
## QA 6c2: efeitos do hall pelo caminho real da sucessao (receber_discipulo...), carga do save no meio da campanha, cartao de inicio.
const GameStateScript := preload("res://scripts/game_state.gd")

func _novo(nome: String, pasta: String = "") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta if pasta != "" else pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	return gs

func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.aguardar_falta()
	g.free()

func rodar_testes() -> void:
	var pasta := pasta_limpa("qa_ef")
	var gs := _novo("qa_ef", pasta)
	gs.indice_escada = 4
	gs.cinturao = true
	var cartao_antes: Dictionary = gs.cartao_inicio()
	var f: Dictionary = gs.aposentar()
	checar_igual(f.honor_gained, 15, "15 de Honra")
	gs.escola["honor"] = 190
	for id in ["hall_box", "hall_fund", "hall_notes", "hall_crew", "hall_glove", "hall_wall"]:
		checar(gs.comprar_hall(id), "comprou " + id)
	checar_igual(gs.honra(), 0, "190 gastos exatos")
	checar_igual(gs.treino, 0.0, "treino da campanha encerrada intacto")
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	print("treino ", gs.treino, " nivel_luva ", gs.nivel_luva, " gestos ", gs.gestos_calcados, " caixas ", gs.caixas_lista.size(), " cliques ", gs.cliques_para_abrir())
	checar_igual(gs.treino, 500.0, "sucessao real: 500 de treino")
	checar_igual([gs.nivel_luva, gs.luvas_abertas()], [1, 1], "sucessao real: luva de lona")
	checar_igual(gs.cliques_para_abrir(), 2, "sucessao real: caixa 2")
	checar_igual(gs.teto_retratos(), 8, "teto 8")
	var cartao: Dictionary = gs.cartao_inicio()
	print("cartao: ", JSON.stringify(cartao))
	# salvar e recarregar no meio da campanha: nada some, nada duplica
	gs.salvar()
	var t: float = gs.treino
	var nl: int = gs.nivel_luva
	_liberar(gs)
	var gs2 := _novo("qa_ef2", pasta)
	checar_igual([gs2.treino, gs2.nivel_luva, gs2.cliques_para_abrir(), gs2.honra(), gs2.escola.hall_nodes.size()], [t, nl, 2, 0, 6], "recarregar: efeitos e saldo estaveis")
	# comprar uma caixa e salvar com 1 clique, recarregar: hits preservado com hall_box
	gs2.dinheiro = 1.0e9
	var l = gs2.proxima_luva()
	if l != null and not l.is_empty():
		gs2.comprar_luva()
		gs2.bater_caixa(str(l.id))
		gs2.salvar()
		var gs3 := _novo("qa_ef3", pasta)
		checar_igual(gs3.cliques_faltando(str(l.id)), 1, "caixa com 1 clique salva e recarregada: falta 1 (hall_box)")
		_liberar(gs3)
	# vazio: com o hall vazio e sem retrato nada muda (campanha 2)
	_liberar(gs2)
	var gs4 := _novo("qa_ef4")
	gs4.indice_escada = 1
	gs4.aposentar()
	gs4.nova_carreira()
	checar_igual([gs4.treino, gs4.nivel_luva, gs4.cliques_para_abrir()], [0.0, 0, 3], "sem hall: campanha 2 igual a antes")
	checar(absf(gs4.mult_escola() - 1.02) < 1e-9, "1 selo: x1,02")
	_liberar(gs4)
