extends "res://tests/test_base.gd"
## Fase 5.2: luvas L3/L4, bolsa da torcida (evento dourado), Grito da equipe e save v8.
## Tudo em pastas de user://test/, nunca o save real. Números lidos de data/.

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	return gs


func _reabrir(pasta: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func rodar_testes() -> void:
	_teste_luvas()
	_teste_tipo_do_evento()
	_teste_bolsa()
	_teste_grito()
	_teste_save_v8()


func _teste_luvas() -> void:
	var gs := _novo("f52_luvas")
	var l: Array = gs.lutas.luvas
	checar_igual(l.size(), 4, "4 luvas no dado")
	checar_igual([l[2].id, l[3].id], ["glove_l3", "glove_l4"], "L3 e L4 depois de L2")
	var mult := 1.0
	for i in 4:
		gs.dinheiro = 1.0e6
		checar(gs.comprar_luva(), "compra a luva %d" % (i + 1))
		checar(gs.luva_em_caixa(), "luva %d chega na caixa" % (i + 1))
		checar(not gs.pode_comprar_luva() or i == 3 and false, "próxima luva trancada com a anterior na caixa")
		gs.bater_caixa(l[i].id)
		gs.bater_caixa(l[i].id)
		gs.bater_caixa(l[i].id)
		mult *= float(l[i].click_multiplier)
		checar_igual(gs.multiplicador_luva(), mult, "multiplicador acumulado depois da luva %d" % (i + 1))
	checar(gs.proxima_luva().is_empty() and not gs.pode_comprar_luva(), "linha completa")
	_liberar(gs)


func _teste_tipo_do_evento() -> void:
	for chance in [0.0, 1.0]:
		var gs := _novo("f52_tipo")
		gs.dados.golden_crew_chance = chance
		var tipos := {}
		for n in 12:
			gs.evento_dourado_restante = 0.0
			gs._evento_espera = 0.01
			gs.tick(0.1)
			checar(gs.evento_dourado_restante > 0.0, "evento apareceu")
			tipos[gs.evento_dourado_tipo] = true
		checar_igual(tipos.keys(), ["crew"] if chance >= 1.0 else ["frenzy"], "crew_chance %s sorteia só um tipo" % str(chance))
		_liberar(gs)
	# Padrão sem os campos: 5.1 (sem bolsa).
	var td := TrainingData.new()
	td._ler_evento_dourado({"wait_min": 60, "wait_max": 100})
	checar_igual([td.golden_crew_chance, td.golden_crew_seconds, td.golden_crew_floor_clicks],
		[0.0, 45.0, 40.0], "padrões dos campos novos do golden_event")


func _teste_bolsa() -> void:
	var gs := _novo("f52_bolsa")
	gs.dados.golden_crew_chance = 1.0
	gs.treino = 0.0
	var pagos: Array = []
	gs.bolsa_paga.connect(func(g: float) -> void: pagos.append(g))
	var seg: float = gs.dados.golden_crew_seconds
	var piso: float = gs.dados.golden_crew_floor_clicks
	# Equipe zero: vale o piso em cliques.
	gs.evento_dourado_tipo = "crew"
	gs.evento_dourado_restante = 5.0
	checar_igual(gs.valor_bolsa(), piso * gs.por_clique(), "sem equipe: paga o piso de cliques")
	checar(gs.pegar_evento_dourado(), "pega a bolsa")
	checar_igual([gs.treino, gs.atributos.strength, gs.frenesi_restante], [piso * gs.por_clique(), piso * gs.por_clique(), 0.0],
		"piso cai no saldo e no atributo do foco, sem FRENESI")
	checar_igual(pagos.size(), 1, "sinal bolsa_paga")
	# Equipe grande: vale crew_seconds x renda sem mão.
	gs.geradores[gs.dados.geradores[0].id] = 1000
	gs.nivel_metronomo = 1
	var renda: float = gs.producao_total() + gs.socos_por_segundo_metronomo() * gs.por_auto_soco()
	checar_igual(gs.renda_sem_mao(), renda, "renda_sem_mao = equipe + Metrônomo")
	checar(seg * renda > piso * gs.por_clique(), "neste cenário vale o lado do tempo")
	var antes: float = gs.treino
	gs.evento_dourado_tipo = "crew"
	gs.evento_dourado_restante = 5.0
	gs.pegar_evento_dourado()
	checar(absf(gs.treino - antes - seg * renda) < 1e-6 * seg * renda, "bolsa paga crew_seconds x renda_sem_mao")
	checar_igual(gs.evento_dourado_restante, 0.0, "evento some depois do clique")
	# A luva x7 continua igual.
	gs.evento_dourado_tipo = "frenzy"
	gs.evento_dourado_restante = 5.0
	gs.pegar_evento_dourado()
	checar(gs.frenesi_restante > 0.0, "tipo frenzy liga o FRENESI")
	_liberar(gs)


func _teste_grito() -> void:
	var gs := _novo("f52_grito")
	var def: Dictionary = gs.lutas.crew_click
	checar(not def.is_empty(), "crew_click existe em shop.json")
	gs.geradores[gs.dados.geradores[0].id] = 50
	var sem: float = gs.por_clique()
	var auto_sem: float = gs.por_auto_soco()
	var equipe: float = gs.producao_total()
	checar(equipe > 0.0, "equipe produz")
	gs.dinheiro = float(def.cost) - 1.0
	checar(not gs.comprar_crew_click(), "sem dinheiro não compra")
	gs.dinheiro = float(def.cost) + gs.reserva_mudanca()
	var menor_antes: float = gs.menor_preco_loja()
	checar(gs.comprar_crew_click(), "compra o Grito da equipe")
	checar(not gs.pode_comprar_crew_click() and not gs.comprar_crew_click(), "só uma vez")
	checar(absf(gs.por_clique() - (sem + float(def.crew_share) * equipe)) < 1e-9, "clique soma crew_share x equipe/s")
	checar_igual(gs.por_auto_soco(), auto_sem, "auto-soco (Metrônomo e assistido) não ganha")
	checar_igual(gs.clicar().ganho, gs.por_clique(), "o clique rende o novo valor")
	checar(gs.menor_preco_loja() >= menor_antes, "comprado, sai do menor preço da loja")
	# Nova carreira zera
	gs.crew_click_comprado = false
	checar_igual(gs.por_clique(), sem, "sem a melhoria, valor antigo")
	_liberar(gs)


func _teste_save_v8() -> void:
	checar_igual(SaveStore.VERSAO_ATUAL, 9, "versão do save é 8")
	var pasta := pasta_limpa("f52_save")
	var gs := _reabrir(pasta)
	gs.crew_click_comprado = true
	gs.salvar()
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual([int(doc.version), doc.state.career.crew_click], [9, true], "gravado v8 com crew_click")
	_liberar(gs)
	var g2 := _reabrir(pasta)
	checar(g2.crew_click_comprado, "recarrega crew_click")
	g2.aplicar_save({"career": {"crew_click": "sim"}})
	checar(not g2.crew_click_comprado, "valor inválido vira false")
	_liberar(g2)
	# Migração v7 -> v8
	var p2 := pasta_limpa("f52_mig7")
	var v7 := {"version": 7, "saved_at_unix": 1730000000, "state": {
		"career": {"training": 55.0, "glove_level": 2, "boxes": []}, "permanent": {}, "ending": null}}
	escrever(p2 + "save.json", JSON.stringify(v7))
	var g3 := _reabrir(p2)
	checar_igual([g3.treino, g3.nivel_luva, g3.crew_click_comprado], [55.0, 2, false], "v7 -> v8: nada se perde, Grito não comprado")
	checar(g3.avisos.is_empty(), "migração sem avisos")
	g3.salvar()
	checar_igual(int(JSON.parse_string(ler(p2 + "save.json")).version), 9, "regravado como v9")
	_liberar(g3)
