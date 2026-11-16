extends "res://tests/test_base.gd"
## Fase 6c2 (Mais longe que eu): Honra, árvore do hall, mural, símbolo, falas de mentor e save v13.
## Tudo em pastas de user://test/, nunca o save real. Janelas com --position 1950,40.

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
	g.free()


func _tickar(gs: Node, segundos: float, passo: float = 0.1) -> void:
	for i in int(round(segundos / passo)):
		gs.tick(passo)


func _passar_o_posto(gs: Node) -> void:
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()


func _chegar(g: Node) -> bool:
	g.cinturao = true
	g.dinheiro = 1.0e9
	return g.mudar()


func _assentar(g: Node) -> void:
	g.cena_sala_terminou()
	if g.escolha_arte_pendente():
		g.escolher_arte(g.academia.ids_artes()[0])


func _vencer(gs: Node) -> Dictionary:
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	gs.lutar()
	return gs.concluir_luta()


func rodar_testes() -> void:
	_teste_dados()
	_teste_save_v13()
	_teste_honor_gain()
	_teste_hall_buy()
	_teste_hall_buy_pre_req()
	_teste_hall_reset()
	_teste_simbolo_persiste()
	_teste_mural_estados()
	_teste_portrait_variant()
	_teste_balanco_inalterado()


func _teste_dados() -> void:
	var gs := _novo("f6c2_dados")
	checar_igual(SaveStore.VERSAO_ATUAL, 13, "save subiu para v13")
	checar(not gs.hall_tree.is_empty(), "data/skill_tree_hall.json carregado")
	var nodes = gs.hall_tree.get("nodes", [])
	checar(nodes is Array and nodes.size() == 20, "árvore do hall tem 20 nós")
	var branches = gs.hall_tree.get("branches", [])
	checar(branches is Array and branches.size() == 4, "árvore do hall tem 4 branches")
	var cfg6c2 = gs.escola_cfg.get("_6c2", {})
	checar(not cfg6c2.is_empty(), "bloco _6c2 presente em escola.json")
	checar(cfg6c2.has("honor_sources"), "honor_sources definido")
	checar(cfg6c2.has("portrait_variants"), "portrait_variants definido")
	checar(cfg6c2.has("symbol_spec"), "symbol_spec definido")
	_liberar(gs)


func _teste_save_v13() -> void:
	var gs := _novo("f6c2_save_v13")
	checar_igual(gs.honor_balance(), 0.0, "honor_balance inicia em 0")
	checar_igual(gs.hall_nodes_comprados(), [], "hall_nodes inicia vazio")
	gs.honor_gain("fight_won", 10.0)
	checar(gs.hall_buy("hall_echo"), "compra hall_echo (T1)")
	gs.salvar()
	var pasta: String = gs.store.pasta
	var gs2 := _novo("f6c2_save_v13_load", pasta)
	checar_igual(gs2.honor_balance(), gs.honor_balance(), "honor_balance persiste no save")
	checar_igual(gs2.hall_nodes_comprados(), gs.hall_nodes_comprados(), "hall_nodes persiste no save")
	_liberar(gs)
	_liberar(gs2)


func _teste_honor_gain() -> void:
	var gs := _novo("f6c2_honor_gain")
	var sinais: Array = []
	gs.honor_changed.connect(func(b: float) -> void: sinais.append(b))
	gs.honor_gain("fight_won", 3.0)
	checar_igual(gs.honor_balance(), 3.0, "ganhou 3 de honra")
	checar_igual(sinais, [3.0], "sinal honor_changed disparou")
	gs.honor_gain("revenge_win", 5.0)
	checar_igual(gs.honor_balance(), 8.0, "ganhou mais 5")
	checar_igual(sinais.size(), 2, "sinal disparou duas vezes")
	gs.honor_gain("x", -10.0)
	checar_igual(gs.honor_balance(), 8.0, "valor negativo ignorado")
	_liberar(gs)


func _teste_hall_buy() -> void:
	var gs := _novo("f6c2_hall_buy")
	var sinais_buy: Array = []
	var sinais_honor: Array = []
	gs.hall_node_bought.connect(func(id: String) -> void: sinais_buy.append(id))
	gs.honor_changed.connect(func(b: float) -> void: sinais_honor.append(b))
	gs.honor_gain("x", 20.0)
	checar(gs.hall_buy("hall_echo"), "compra hall_echo com saldo suficiente")
	checar_igual(gs.honor_balance(), 12.0, "saldo desceu 8")
	checar("hall_echo" in gs.hall_nodes_comprados(), "nó entra na lista")
	checar_igual(sinais_buy, ["hall_echo"], "sinal hall_node_bought disparou")
	checar(sinais_honor.size() >= 2, "sinal honor_changed disparou na compra")
	checar(not gs.hall_buy("hall_echo"), "não compra nó já comprado")
	checar_igual(gs.honor_balance(), 12.0, "saldo inalterado na recusa")
	_liberar(gs)


func _teste_hall_buy_pre_req() -> void:
	var gs := _novo("f6c2_hall_prereq")
	gs.honor_gain("x", 100.0)
	checar(not gs.hall_buy("hall_respect_street"), "T2 sem T1: recusa")
	checar_igual(gs.honor_balance(), 100.0, "saldo inalterado na recusa por pré-requisito")
	checar(gs.hall_buy("hall_echo"), "compra T1 primeiro")
	checar(gs.hall_buy("hall_respect_street"), "T2 com T1: aceita")
	checar_igual(gs.honor_balance(), 100.0 - 8.0 - 18.0, "saldo desceu T1 + T2")
	_liberar(gs)


func _teste_hall_reset() -> void:
	var gs := _novo("f6c2_hall_reset")
	gs.honor_gain("x", 100.0)
	checar(gs.hall_buy("hall_echo"), "compra nó antes do reset")
	checar(gs.hall_buy("hall_floor_creak"), "compra prereq T1 do simbolo")
	checar(gs.hall_buy("hall_crew_rhythm"), "compra prereq T2 do simbolo")
	checar(gs.hall_buy("hall_symbol_chest"), "compra símbolo antes do reset")
	gs.hall_reset()
	checar_igual(gs.honor_balance(), 0.0, "saldo zerou no reset")
	var nodes: Array = gs.hall_nodes_comprados()
	checar_igual(nodes, ["hall_symbol_chest"], "só símbolo persiste no reset")
	checar(gs.simbolo_desbloqueado(), "simbolo_desbloqueado continua true")
	_liberar(gs)


func _teste_simbolo_persiste() -> void:
	var gs := _novo("f6c2_simbolo")
	gs.honor_gain("x", 100.0)
	checar(gs.hall_buy("hall_floor_creak"), "compra prereq do simbolo")
	checar(gs.hall_buy("hall_crew_rhythm"), "compra prereq T2")
	checar(gs.hall_buy("hall_symbol_chest"), "compra simbolo")
	checar(gs.simbolo_desbloqueado(), "simbolo desbloqueado")
	gs.hall_reset()
	checar(gs.simbolo_desbloqueado(), "simbolo persiste apos reset")
	_passar_o_posto(gs)
	checar(gs.simbolo_desbloqueado(), "simbolo persiste apos passar o posto")
	_liberar(gs)


func _teste_mural_estados() -> void:
	var gs := _novo("f6c2_mural")
	checar_igual(gs.mural_estado(), "empty", "inicio: empty")
	checar_igual(gs.mural_texto(), gs.texto_ui("mural_empty_text", ""), "texto empty")
	gs._gravar_marco("cena_primeira_academia", {}, false)
	checar_igual(gs.mural_estado(), "john_only", "apos cena academia: john_only")
	gs._gravar_marco("cena_saida_primeiro_mentor", {}, false)
	checar_igual(gs.mural_estado(), "john_left", "apos saida sem discipulo: john_left")
	gs.escola["roster"] = [{"kind": "disciple", "name": "Novato", "campaign": 2}]
	checar_igual(gs.mural_estado(), "with_disciple", "com discipulo no roster: with_disciple")
	gs.honor_gain("x", 200.0)
	gs.hall_buy("hall_floor_creak")
	gs.hall_buy("hall_crew_rhythm")
	gs.hall_buy("hall_symbol_chest")
	checar_igual(gs.mural_estado(), "symbol_unlocked", "apos comprar simbolo: symbol_unlocked")
	gs.hall_buy("hall_echo")
	gs.hall_buy("hall_respect_street")
	gs.hall_buy("hall_voice_school")
	gs.hall_buy("hall_mural_update")
	checar_igual(gs.mural_estado(), "mural_upgraded", "apos comprar mural_update: mural_upgraded")
	_liberar(gs)


func _teste_portrait_variant() -> void:
	var gs := _novo("f6c2_portrait")
	gs.local_id = "garage"
	checar_igual(gs.portrait_variant(), "old_photo", "garagem: old_photo")
	gs.local_id = "gym"
	checar_igual(gs.portrait_variant(), "old_photo", "gym sem marco: old_photo (fallback)")
	gs._gravar_marco("cena_primeira_academia", {}, false)
	checar_igual(gs.portrait_variant(), "old_photo_gym", "gym com marco: old_photo_gym")
	gs._gravar_marco("cena_saida_primeiro_mentor", {}, false)
	checar_igual(gs.portrait_variant(), "old_photo_john", "apos saida: old_photo_john (prioridade maior)")
	gs.honor_gain("x", 200.0)
	gs.hall_buy("hall_name_wall")
	# Node-based variants (name_wall=30) beat milestone-only (john_left=20) per design §4.
	checar_igual(gs.portrait_variant(), "old_photo_name", "name_wall (node) tem prioridade sobre john_left (marco)")
	gs.hall_buy("hall_photo_story")
	checar_igual(gs.portrait_variant(), "old_photo_story", "story (prio 40) vence name_wall (prio 30)")
	gs.hall_buy("hall_floor_creak")
	gs.hall_buy("hall_crew_rhythm")
	gs.hall_buy("hall_symbol_chest")
	gs.hall_buy("hall_legacy_whisper")
	checar_igual(gs.portrait_variant(), "old_photo_legacy", "legacy (prio 50) tem maior prioridade")
	_liberar(gs)


func _teste_balanco_inalterado() -> void:
	var a := _novo("f6c2_bal_a")
	var b := _novo("f6c2_bal_b")
	for g in [a, b]:
		g.cinturao = true
		g.dinheiro = 1.0e9
		_tickar(g, 5.0)
		g.mudar()
	for g in [a, b]:
		_assentar(g)
	# a ganha honra e compra nos; b nao
	a.honor_gain("fight_won", 30.0)
	a.hall_buy("hall_echo")
	a.hall_buy("hall_floor_creak")
	for g in [a, b]:
		for i in 300:
			if i % 3 == 0:
				g.clicar()
			g.tick(0.1)
	# Bônus da honra (+5% clique, +5% passivo) afetam treino mas NAO dinheiro, dia, fight_day ou arte_segundos.
	# O teste verifica que o relógio e o calendário são idênticos.
	checar_igual([a.segundos_campanha, a.dia_campanha(), a.fight_day, a.arte_segundos],
		[b.segundos_campanha, b.dia_campanha(), b.fight_day, b.arte_segundos],
		"balanço: relógio, dia, luta e arte iguais com e sem honra")
	_liberar(a)
	_liberar(b)