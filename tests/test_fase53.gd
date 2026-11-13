extends "res://tests/test_base.gd"
## Fase 5.3: calendário da campanha, sala_ativa(), dia da luta, dica de passar o posto e save v9.
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


# Equipe e Metrônomo ligados, para qualquer relógio que ande aparecer no treino.
func _com_equipe(gs: Node) -> void:
	gs.geradores[gs.dados.geradores[0].id] = 10
	gs.nivel_metronomo = 1
	gs.foco = gs.dados.default_focus
	checar(gs.producao_total() > 0.0, "a equipe produz")


func _s() -> float:
	return 30.0


func rodar_testes() -> void:
	_teste_dados()
	_teste_relogio_e_tabela()
	_teste_relogio_para_onde_a_equipe_para()
	_teste_dia_da_luta()
	_teste_data_apos_lutar()
	_teste_passar_o_posto()
	_teste_avisos()
	_teste_avisos_b2_e_b3()
	_teste_campanha_completa()
	_teste_sem_calendario()
	_teste_prep_days_dos_dados()
	_teste_save_v9()
	_teste_migracao_8_para_9()


func _teste_dados() -> void:
	var gs := _novo("f53_dados")
	var c: Dictionary = gs.lutas.calendario
	checar_igual([c.seconds_per_day, c.warn_days, c.warn_sound_days, c.retire_hint_days, c.offline_stops_at_fight_day],
		[30.0, 3, 1, 3, true], "bloco calendar")
	var preps := []
	for o in gs.lutas.adversarios:
		preps.append(o.prep_days)
	checar_igual(preps, [12, 13, 10, 16, 24, 16], "prep_days dos 6 adversários")
	checar_igual([gs.dia_campanha(), gs.fight_day, gs.dias_para_luta()], [1, 13, 12], "campanha nova: Dia 1, data = 1 + 12")
	checar(not gs.no_dia_da_luta() and gs.sala_ativa(), "começa com a sala ativa")
	_liberar(gs)


# A sala anda e para junto com a equipe: tabela da seção 2 do design.
func _teste_relogio_e_tabela() -> void:
	var gs := _novo("f53_tabela")
	_com_equipe(gs)
	# "Andam": 10 s de relógio = 10 s de equipe.
	var t0: float = gs.treino
	var c0: float = gs.segundos_campanha
	var prod: float = gs.producao_total()
	gs.tick(10.0)
	checar_igual(gs.segundos_campanha - c0, 10.0, "sala livre: relógio anda 10 s")
	checar(gs.treino - t0 >= prod * 10.0 - 1.0e-6, "sala livre: equipe treinou os mesmos 10 s")
	gs.foco_mudou.emit(gs.foco)
	# Sem foco ou minimizado não existe no estado: o jogo só olha sala_ativa (Shift solta, o relógio não).
	gs._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	c0 = gs.segundos_campanha
	gs.tick(5.0)
	checar_igual(gs.segundos_campanha - c0, 5.0, "sem foco: o relógio continua")
	# "Param": cada estado congela relógio, equipe, Metrônomo, assistido, FRENESI, arte e tempo morto.
	var estados := {
		"janela aberta": func(g): g.definir_modal(true),
		"luta": func(g): g.luta = {"opponent": "x"},
		"fim de carreira": func(g): g.fim = {"kind": "retire"},
		"dia da luta": func(g): g.segundos_campanha = float(g.fight_day - 1) * 30.0,
	}
	for nome in estados:
		var g := _novo("f53_param")
		_com_equipe(g)
		g.arte_id = ""
		g.frenesi_restante = 5.0
		g.evento_dourado_restante = 3.0
		g._acc_metronomo = 0.5
		g.definir_assistido(true)
		estados[nome].call(g)
		checar(not g.sala_ativa(), "%s: sala parada" % nome)
		var antes := [g.segundos_campanha, g.treino, g.atributos.duplicate(), g._acc_metronomo, g.frenesi_restante,
			g.evento_dourado_restante, g.arte_segundos, g.auto_socos_total]
		g.tick(10.0)
		var depois := [g.segundos_campanha, g.treino, g.atributos.duplicate(), g._acc_metronomo, g.frenesi_restante,
			g.evento_dourado_restante, g.arte_segundos, g.auto_socos_total]
		checar_igual(depois, antes, "%s: nada anda em 10 s" % nome)
		checar(g.clicar().is_empty() and g.auto_socar().is_empty(), "%s: clique e auto-soco recusados" % nome)
		checar_igual(g.assistido_estado(), "metronome", "%s: Metrônomo >= 1 esconde o assistido" % nome)
		g.free()
	# Escolha da arte pendente: também congela.
	var ga := _novo("f53_arte")
	_com_equipe(ga)
	ga.permanente["arts_unlocked"] = ga.academia.ids_artes()
	ga.arte_id = ""
	if ga.escolha_arte_pendente():
		var s0: float = ga.segundos_campanha
		var t1: float = ga.treino
		ga.tick(10.0)
		checar_igual([ga.segundos_campanha, ga.treino], [s0, t1], "escolha da arte: relógio e equipe parados")
	_liberar(ga)
	# Assistido (Shift) sem Metrônomo: ativo na sala, parado na janela.
	var gh := _novo("f53_assist")
	gh.nivel_metronomo = 0
	gh.definir_assistido(true)
	gh.tick(gh.dados.assist_still_seconds + 0.5)
	checar_igual(gh.assistido_estado(), "active", "assistido ativo na sala")
	gh.definir_modal(true)
	checar_igual(gh.assistido_estado(), "off", "assistido parado com janela")
	gh.free()
	_liberar(gs)


# Teste automático do critério 6: o relógio para exatamente onde a equipe para (estados sorteados, quadro a quadro).
func _teste_relogio_para_onde_a_equipe_para() -> void:
	var gs := _novo("f53_junto")
	_com_equipe(gs)
	gs.nivel_metronomo = 0  # só a equipe, para o ganho ser só dela
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	var divergiu := 0
	var andou := 0
	for i in 600:
		match rng.randi() % 5:
			0: gs.definir_modal(not gs.modal_aberto)
			1: gs.luta = {} if not gs.luta.is_empty() else {"opponent": "x"}
		var c0: float = gs.segundos_campanha
		var t0: float = gs.treino
		var dt := 0.1
		gs.tick(dt)
		var relogio: float = gs.segundos_campanha - c0
		var equipe: float = gs.treino - t0
		if (relogio > 0.0) != (equipe > 0.0):
			divergiu += 1
		elif relogio > 0.0:
			andou += 1
			if absf(equipe - gs.producao_total() * relogio) > 1.0e-6:
				divergiu += 1
		if gs.no_dia_da_luta():
			gs.segundos_campanha = 0.0  # volta o dia só para o sorteio continuar rodando
	checar_igual(divergiu, 0, "relógio e equipe nunca divergem")
	checar(andou > 50, "o sorteio exercitou a sala ativa")
	gs.luta = {}
	_liberar(gs)


func _teste_dia_da_luta() -> void:
	var gs := _novo("f53_dia")
	_com_equipe(gs)
	gs.nivel_metronomo = 0
	var chegou := []
	gs.dia_da_luta_chegou.connect(func(): chegou.append(1))
	var alvo: float = float(gs.fight_day - 1) * 30.0
	gs.segundos_campanha = alvo - 1.0
	var t0: float = gs.treino
	var prod: float = gs.producao_total()
	gs.tick(5.0)  # só 1 s é de sala; o resto não existe
	checar_igual(gs.segundos_campanha, alvo, "o relógio trava exatamente no dia")
	checar(absf((gs.treino - t0) - prod * 1.0) < 1.0e-6, "a equipe treinou só o 1 s até o dia")
	checar(gs.no_dia_da_luta() and not gs.sala_ativa(), "dia da luta: sala parada")
	checar_igual(chegou.size(), 1, "dia_da_luta_chegou emitido uma vez")
	checar_igual(gs.dias_para_luta(), 0, "dias_para_luta = 0 no dia")
	# 10 min parado: nada muda e nenhuma luta começa sozinha.
	var estado := [gs.segundos_campanha, gs.treino, gs.dinheiro, gs.indice_escada, gs.luta.is_empty()]
	for i in 600:
		gs.tick(1.0)
	checar_igual([gs.segundos_campanha, gs.treino, gs.dinheiro, gs.indice_escada, gs.luta.is_empty()], estado, "10 min no dia: nada muda")
	checar_igual(chegou.size(), 1, "sem repetir o sinal")
	# Loja, clique e caixa fechados; lutar e passar o posto abertos.
	gs.dinheiro = 1.0e9
	checar(gs.clicar().is_empty(), "sem clique no dia")
	checar(not gs.comprar_gerador_pago(gs.lutas.geradores_pagos[0].id) and not gs.comprar_luva() and not gs.comprar_melhoria(gs.foco), "LOJA fechada no dia")
	checar(gs.pode_lutar() and gs.pode_aposentar(), "LUTAR e PASSAR O POSTO funcionam no dia")
	# Lutar: a luta corre e a sala continua parada depois (sem no_dia, a janela é da UI).
	gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
	checar(not gs.lutar().is_empty(), "lutar no dia")
	gs.concluir_luta()
	checar(not gs.no_dia_da_luta(), "depois da vitória o dia acabou")
	checar_igual(gs.fight_day, 1 + int(alvo / 30.0) + 13, "próxima data = dia da luta + folga do Brutão")
	_liberar(gs)


func _teste_data_apos_lutar() -> void:
	var gs := _novo("f53_antes")
	gs.tick(95.0)  # 3,17 dias: Dia 4
	checar_igual(gs.dia_campanha(), 4, "Dia 4 aos 95 s")
	gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
	gs.lutar()
	gs.concluir_luta()
	checar_igual(gs.fight_day, 4 + 13, "lutar antes: data = dia da luta + prep_days do Brutão")
	checar_igual(gs.dias_para_luta(), 13, "Faltam 13")
	_liberar(gs)


func _teste_passar_o_posto() -> void:
	var gs := _novo("f53_posto")
	gs.fama = 80
	gs.segundos_campanha = float(gs.fight_day - 1) * 30.0
	gs.tick(1.0)
	var esperado: int = int(gs.previa_aposentar().total)
	checar(esperado > 0, "há Legado a levar")
	var legado0: int = int(gs.permanente.legacy_total)
	var fim: Dictionary = gs.aposentar()
	checar_igual([fim.kind, int(fim.legacy_gained)], ["retire", esperado], "passar o posto no dia leva o Legado de aposentar()")
	checar_igual(int(gs.permanente.legacy_total), legado0 + esperado, "Legado somado")
	# Depois do fim o relógio fica parado e a nova campanha zera a data.
	var s0: float = gs.segundos_campanha
	gs.tick(10.0)
	checar_igual(gs.segundos_campanha, s0, "tela de fim congela o relógio")
	checar(gs.nova_carreira(), "nova campanha")
	checar_igual([gs.segundos_campanha, gs.dia_campanha(), gs.fight_day], [0.0, 1, 13], "nova campanha: Dia 1 e data cheia")
	_liberar(gs)


func _teste_avisos() -> void:
	var gs := _novo("f53_avisos")
	var avisos := []
	gs.aviso_data.connect(func(d): avisos.append(d))
	var dias_mudou := []
	gs.dia_mudou.connect(func(d): dias_mudou.append(d))
	gs.segundos_campanha = float(gs.fight_day - 5) * 30.0 + 29.9  # Faltam 4
	gs.tick(0.05)
	checar(avisos.is_empty(), "faltando 4: sem aviso")
	gs.tick(0.2)  # vira Faltam 3
	checar_igual(avisos, [3], "aviso de 3 dias")
	for i in 5:
		gs.tick(15.0)  # passa o dia 2, vira Faltam 1
	checar_igual(avisos, [3, 1], "aviso de 1 dia, depois do de 3")
	for i in 5:
		gs.tick(1.0)
	checar_igual(avisos, [3, 1], "cada aviso dispara uma vez")
	checar(dias_mudou.size() >= 3, "dia_mudou emitido a cada dia")
	# Lutar antes de chegar: nada dispara para a data velha.
	gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
	gs.lutar()
	gs.concluir_luta()
	checar_igual(avisos, [3, 1], "lutar antes: sem aviso novo")
	# Reabrir o jogo com Faltam <= 3: faixa uma vez.
	var pasta := pasta_limpa("f53_avisos_save")
	var g2 := _reabrir(pasta)
	g2.segundos_campanha = float(g2.fight_day - 4) * 30.0 + 1.0
	g2.salvar()
	g2.free()
	var g3: Node = GameStateScript.new()
	var recebidos := []
	g3.aviso_data.connect(func(d): recebidos.append(d))
	g3.inicializar(pasta, "res://data/config.json")
	g3.autosave_ativo = false
	checar_igual(recebidos, [3], "reabrir com Faltam 3: uma faixa")
	g3.free()
	_liberar(gs)


func _teste_avisos_b2_e_b3() -> void:
	# B2: reabrir com Faltam 1 emite um aviso só.
	var pasta := pasta_limpa("f53_b2_save")
	var g2 := _reabrir(pasta)
	g2.segundos_campanha = float(g2.fight_day - 2) * 30.0 + 1.0  # Faltam 1
	g2.salvar()
	g2.free()
	var g3: Node = GameStateScript.new()
	var rec := []
	g3.aviso_data.connect(func(d): rec.append(d))
	g3.inicializar(pasta, "res://data/config.json")
	g3.autosave_ativo = false
	checar_igual(rec, [1], "B2: reabrir com Faltam 1: um aviso só")
	g3.free()
	# B2: um tick gigante de Faltam > 3 até o dia emite o aviso do limiar alcançado, uma vez.
	var gs := _novo("f53_b2_gigante")
	var av := []
	gs.aviso_data.connect(func(d): av.append(d))
	gs.tick(1.0)
	gs.tick(100000.0)
	checar(gs.no_dia_da_luta(), "B2: tick gigante chegou no dia")
	checar_igual(av, [1], "B2: tick gigante emite um aviso (limiar de 1 dia)")
	gs.tick(10.0)
	checar_igual(av, [1], "B2: sem repetir")
	_liberar(gs)
	# B3: próxima luta em outro local e jogador na garagem: relógio não conta; ao chegar, folga cheia.
	var g := _novo("f53_b3")
	var i_out := -1
	for i in g.lutas.adversarios.size():
		if str(g.lutas.adversarios[i].location) != g.academia.local_padrao:
			i_out = i
			break
	checar(i_out >= 0, "B3: existe adversário de outro local")
	g.indice_escada = i_out
	g.cinturao = true
	g.dinheiro = 1.0e12
	g.fight_day = g._data_da_proxima_luta()
	checar_igual(g.estado_escada(), "move", "B3: precisa mudar")
	var s0: float = g.segundos_campanha
	var fd0: int = g.fight_day
	g.tick(5000.0)
	checar_igual([g.segundos_campanha, g.fight_day], [s0, fd0], "B3: relógio parado enquanto a luta é em outro local")
	checar(not g.no_dia_da_luta(), "B3: não cai no dia da luta")
	g.segundos_campanha = 60.0  # Dia 3, simula tempo passado antes
	checar(g.mudar(), "B3: mudar de local")
	checar_igual(g.fight_day, 3 + int(g.lutas.adversarios[i_out].prep_days), "B3: data com folga cheia a partir da chegada")
	checar(not g.no_dia_da_luta(), "B3: depois de mudar, fora do dia da luta")
	_liberar(g)


func _teste_campanha_completa() -> void:
	var gs := _novo("f53_completa")
	gs.indice_escada = gs.lutas.adversarios.size() - 1
	gs.aplicar_save(gs.para_save())
	gs.fight_day = gs._data_da_proxima_luta()
	gs.atributos = {"strength": 1.0e15, "agility": 1.0e15, "endurance": 1.0e15}
	var sinais := []
	gs.campanha_completa_mudou.connect(func(): sinais.append(1))
	gs.lutar()
	gs.concluir_luta()
	checar(gs.campanha_completa() and gs.fight_day == -1, "depois do Kid: campanha completa, sem data")
	checar_igual(gs.dias_para_luta(), -1, "sem dias para luta")
	checar_igual(sinais.size(), 1, "campanha_completa_mudou emitido")
	var s0: float = gs.segundos_campanha
	_com_equipe(gs)
	var t0: float = gs.treino
	gs.tick(300.0)
	checar_igual(gs.segundos_campanha, s0, "o relógio some: segundos congelados")
	checar(gs.treino > t0, "mas a equipe segue treinando")
	checar(not gs.no_dia_da_luta(), "sem dia da luta")
	_liberar(gs)


func _teste_sem_calendario() -> void:
	var gs := _novo("f53_sem")
	gs.lutas.calendario["seconds_per_day"] = 0.0
	_com_equipe(gs)
	var t0: float = gs.treino
	gs.tick(1000.0)
	checar_igual([gs.segundos_campanha, gs.dia_campanha(), gs.dias_para_luta(), gs.no_dia_da_luta()], [0.0, 1, -1, false],
		"seconds_per_day 0: sem relógio, sem dia")
	checar(gs.treino > t0 and gs.sala_ativa(), "o jogo roda como na 5.2")
	_liberar(gs)


func _teste_prep_days_dos_dados() -> void:
	var gs := _novo("f53_prep")
	gs.lutas.adversarios[0]["prep_days"] = 5
	checar_igual(gs._data_da_proxima_luta(), 1 + 5, "mudar prep_days muda a data sem código")
	var f := FightData.carregar()
	checar_igual(f.adversario("opp_fast").prep_days, 10, "Dinho: 10 dias")
	_liberar(gs)


func _teste_save_v9() -> void:
	checar_igual(SaveStore.VERSAO_ATUAL, 9, "versão do save é 9")
	var pasta := pasta_limpa("f53_save")
	var gs := _reabrir(pasta)
	gs.segundos_campanha = 123.5
	gs.fight_day = 17
	gs.salvar()
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual([int(doc.version), doc.state.career.campaign_seconds, int(doc.state.career.fight_day)], [9, 123.5, 17], "gravado v9")
	_liberar(gs)
	var g2 := _reabrir(pasta)
	checar_igual([g2.segundos_campanha, g2.fight_day], [123.5, 17], "recarrega relógio e data")
	# Data inválida: folga cheia a partir do dia de hoje (Dia 5 = 123,5 s).
	g2.aplicar_save({"career": {"campaign_seconds": 123.5, "fight_day": -5}})
	checar_igual(g2.fight_day, 5 + 12, "fight_day inválido: recalcula")
	g2.aplicar_save({"career": {"fight_day": 99999}})
	checar_igual(g2.fight_day, 1 + 12, "fight_day absurdo: recalcula")
	g2.aplicar_save({"career": {"campaign_seconds": "x"}})
	checar_igual(g2.segundos_campanha, 0.0, "campaign_seconds inválido vira 0")
	# Fechou o jogo no dia: reabre no dia da luta.
	g2.aplicar_save({"career": {"campaign_seconds": 330.0, "fight_day": 12}})
	checar(g2.no_dia_da_luta(), "save no dia reabre no dia")
	_liberar(g2)


func _teste_migracao_8_para_9() -> void:
	# Carreira em andamento: Dia 1 e folga cheia do próximo adversário.
	var p1 := pasta_limpa("f53_mig_a")
	var v8 := {"version": 8, "saved_at_unix": 1730000000, "state": {
		"career": {"training": 77.0, "ladder_index": 2, "glove_level": 1, "boxes": [], "crew_click": true,
			"money": 55.0, "play_seconds": 900.0}, "permanent": {}, "ending": null}}
	escrever(p1 + "save.json", JSON.stringify(v8))
	var g := _reabrir(p1)
	checar_igual([g.treino, g.indice_escada, g.nivel_luva, g.crew_click_comprado, g.dinheiro], [77.0, 2, 1, true, 55.0],
		"v8 -> v9: nada se perde")
	checar_igual([g.segundos_campanha, g.dia_campanha(), g.fight_day], [0.0, 1, 1 + 10], "em andamento: Dia 1, data = 1 + folga do Dinho")
	checar(g.avisos.is_empty(), "migração sem avisos")
	g.salvar()
	checar_igual(int(JSON.parse_string(ler(p1 + "save.json")).version), 9, "regravado como v9")
	_liberar(g)
	# Kid já vencido: campanha completa.
	var p2 := pasta_limpa("f53_mig_b")
	var v8b := {"version": 8, "saved_at_unix": 1730000000, "state": {
		"career": {"ladder_index": 6, "belt": true, "location": "gym"}, "permanent": {}, "ending": null}}
	escrever(p2 + "save.json", JSON.stringify(v8b))
	var g2 := _reabrir(p2)
	checar_igual([g2.fight_day, g2.campanha_completa()], [-1, true], "Kid vencido: fight_day -1")
	_liberar(g2)
