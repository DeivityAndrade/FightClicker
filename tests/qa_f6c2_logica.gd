extends "res://tests/test_base.gd"
## QA 6c2: cenarios extras (extremos, save corrompido, ordem de compra, idempotencia). So user://test/.

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


func _entrada(campanha: int, fim: String, wins: int, honra: int, oponente: String = "", belt: bool = false, nome: String = "") -> Dictionary:
	return {"campaign": campanha, "kind": "disciple", "name": nome if nome != "" else "Disc%d" % campanha, "look": null, "end": fim, "wins": wins,
		"belt": belt, "art": "", "opponent": oponente, "legacy_gained": 0, "honor": honra}


func rodar_testes() -> void:
	_formula_extrema()
	_saidas()
	_compra()
	_save_corrompido()
	_mural_extremo()
	_migracao_real_e_sintetica()


func _formula_extrema() -> void:
	var gs := _novo("qa_formula")
	var esperado := {0: 0, 1: 1, 2: 3, 3: 6, 4: 10, 5: 15, 6: 22, 7: 29, 20: 22 + 7 * 14}
	for w in esperado:
		checar_igual(gs.honra_da_saida(w, false), esperado[w], "sem cinturao, %d vitorias" % w)
	checar_igual(gs.honra_da_saida(4, true), 15, "4 + cinturao = 15")
	checar_igual(gs.honra_da_saida(5, true), 20, "5 + cinturao = 20")
	checar_igual(gs.honra_da_saida(6, true), 27, "6 + cinturao = 27")
	checar_igual(gs.honra_da_saida(-1, true), 0, "wins negativo = 0")
	checar_igual(gs.honra_da_saida(0, true), 0, "0 vitorias com cinturao = 0")
	_liberar(gs)


func _saidas() -> void:
	# Caderno do velho (+15% de Legado) nunca multiplica a Honra
	var gs := _novo("qa_saidas")
	gs.permanente["skill_nodes"] = ["camp_diary"]
	gs.nos_ativos_ids = ["camp_diary"]
	gs._recalcular_bonus()
	gs.fama = 100000
	gs.indice_escada = 6
	gs.cinturao = true
	var p: Dictionary = gs.previa_aposentar()
	checar_igual(p.honor, 27, "previa: Honra 27 mesmo com Caderno do velho")
	var f: Dictionary = gs.aposentar()
	checar_igual([f.honor_gained, gs.honra(), gs.honra_total()], [27, 27, 27], "Honra nao multiplicada pelo Caderno")
	var legado := int(gs.permanente.legacy_total)
	checar(gs.aposentar().is_empty(), "aposentar de novo com fim pendente: recusado")
	checar_igual([gs.honra(), int(gs.permanente.legacy_total)], [27, legado], "segundo aposentar nao duplica Honra nem Legado")
	# nova carreira e sair de novo acumula
	gs.nova_carreira()
	checar(not gs.nova_carreira(), "nova_carreira sem fim: recusado")
	gs.indice_escada = 1
	gs.aposentar()
	checar_igual([gs.honra(), gs.honra_total()], [28, 28], "acumula 27 + 1")
	# Mudanca de sinal
	_liberar(gs)

	# honra_mudou nunca dispara com 0 vitorias e derrota
	gs = _novo("qa_sinal")
	var chamadas := [0]
	gs.honra_mudou.connect(func(_h): chamadas[0] += 1)
	gs.indice_escada = 0
	gs.aposentar()
	checar_igual(chamadas[0], 0, "0 vitorias: sem sinal de Honra")
	_liberar(gs)

	# derrota com 5 vitorias: 0 Honra
	gs = _novo("qa_derrota")
	gs.indice_escada = 3
	gs.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	gs.lutar()
	var r: Dictionary = gs.concluir_luta()
	if not r.get("win", true):
		checar_igual([gs.fim.get("kind", ""), gs.fim.get("honor_gained", -1), gs.honra()], ["defeat", 0, 0], "derrota no Muralha (3 vitorias): Honra 0")
	else:
		checar(false, "esperava derrota com 0 atributos")
	_liberar(gs)


func _compra() -> void:
	var gs := _novo("qa_compra")
	gs.indice_escada = 6
	gs.cinturao = true
	gs.aposentar()
	# Honra 27: comprar exatamente 10+... ordem inversa (cara primeiro nao cabe)
	checar(not gs.comprar_hall("hall_wall"), "50 com 27: nao cabe")
	checar(gs.comprar_hall("hall_fund"), "20 cabe")
	checar_igual(gs.honra(), 7, "27-20")
	checar(not gs.comprar_hall("hall_box") or gs.honra() == -3, "hall_box 10 com 7: nao cabe")
	gs.escola["honor"] = 10
	checar(gs.comprar_hall("hall_box"), "exato: 10 com 10")
	checar_igual(gs.honra(), 0, "saldo 0 exato")
	checar(gs.honra_total() == 27, "honra_total nao desce na compra")
	# salvo imediatamente?
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://test/qa_compra/save.json"))
	checar_igual([int(doc.state.school.honor), doc.state.school.hall_nodes], [0, ["hall_fund", "hall_box"]], "compra gravada no save")
	# comprar depois de nova carreira: recusado
	gs.nova_carreira()
	checar(not gs.comprar_hall("hall_notes"), "compra fora do fim recusada")
	checar_igual(gs.hall_lista()[2].state, "closed", "estado closed fora do fim")
	_liberar(gs)

	# retrato com selo e teto 5/8: 12 selos
	gs = _novo("qa_teto")
	for i in 12:
		gs.escola.roster.append(_entrada(i + 1, "retire", 1, 1))
	checar(absf(gs.mult_escola() - 1.10) < 1e-9, "12 selos sem nó: x1,10")
	gs.escola.hall_nodes.append("hall_wall")
	checar(absf(gs.mult_escola() - 1.16) < 1e-9, "12 selos com hall_wall: x1,16")
	gs.escola.roster.clear()
	checar(absf(gs.mult_escola() - 1.0) < 1e-9, "0 selos: x1")
	# 0 selos, hall_wall: ainda x1
	var base: float = gs.por_clique()
	for i in 8:
		gs.escola.roster.append(_entrada(i + 1, "retire", 1, 1))
	checar(absf(gs.por_clique() / base - 1.16) < 1e-9, "8 selos: clique x1,16 (um fator so)")
	# derrota e retire 0 nao contam
	gs.escola.roster.clear()
	gs.escola.roster.append(_entrada(1, "defeat", 5, 0, "tank"))
	gs.escola.roster.append(_entrada(2, "retire", 0, 0))
	checar_igual(gs.retratos_com_selo(), 0, "derrota e retire 0 vit: sem selo")
	_liberar(gs)


func _save_corrompido() -> void:
	var pasta := pasta_limpa("qa_corrompido")
	var doc := {"version": 13, "saved_at_unix": 1730000000, "state": {
		"career": {"training": 5.0}, "permanent": {"career_number": 3, "legacy_total": 10},
		"school": {"honor": -50, "honor_total": "abc", "hall_nodes": "oi",
			"roster": [{"campaign": 1, "kind": "first", "name": "John", "look": null, "end": "retire", "wins": 2, "belt": false, "art": "", "opponent": "", "honor": -3},
				{"campaign": 2, "kind": "disciple", "name": "X", "look": null, "end": "retire", "wins": 1, "belt": false, "art": "", "opponent": "", "honor": "muito"}],
			"mentors": ["first"], "milestones": {}, "lines_seen": {}}}}
	var f := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(doc))
	f.close()
	var gs := _novo("qa_corrompido", pasta)
	checar(gs.honra() >= 0 and gs.honra_total() >= gs.honra(), "honra negativa/string saneada: %d/%d" % [gs.honra(), gs.honra_total()])
	checar(gs.escola.hall_nodes is Array, "hall_nodes saneado")
	for e in gs.escola.roster:
		checar(int(e.get("honor", 0)) >= 0, "honor da entrada saneado: " + str(e.get("honor")))
	var m: Dictionary = gs.mural()
	checar_igual(m.entries.size(), 2, "mural com 2 entradas apesar do save corrompido")
	_liberar(gs)

	# hall_nodes com id repetido e desconhecido; honor > total
	pasta = pasta_limpa("qa_corrompido2")
	doc.state.school = {"honor": 99, "honor_total": 5, "hall_nodes": ["hall_box", "hall_box", "xx", "hall_wall"], "roster": [], "mentors": [], "milestones": {}, "lines_seen": {}}
	f = FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(doc))
	f.close()
	gs = _novo("qa_corrompido2", pasta)
	checar_igual([gs.honra(), gs.honra_total(), gs.escola.hall_nodes], [99, 99, ["hall_box", "hall_wall"]], "honor>total e nos repetidos/desconhecidos")
	_liberar(gs)

	# v13 sem campos (v13 incompleto)
	pasta = pasta_limpa("qa_corrompido3")
	doc.state.school = {"roster": [], "mentors": [], "milestones": {}, "lines_seen": {}}
	f = FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(doc))
	f.close()
	gs = _novo("qa_corrompido3", pasta)
	checar_igual([gs.honra(), gs.honra_total(), gs.escola.hall_nodes], [0, 0, []], "v13 sem campos: padrao")
	_liberar(gs)


func _mural_extremo() -> void:
	var gs := _novo("qa_mural")
	var longo := "ABCDEFGHIJKLMNOPQRSTUVWXYZ ABCDEFGHIJKLMNOP"
	gs.escola.roster.append({"campaign": 1, "kind": "first", "name": "John Bullet", "look": null, "end": "retire", "wins": 3, "belt": false, "art": "", "opponent": "", "legacy_gained": 1, "honor": 6})
	for i in 29:
		var fim: String = ["retire", "defeat", "unknown"][i % 3]
		gs.escola.roster.append(_entrada(i + 2, fim, [-1, 0, 6, 3][i % 4], 0, "nao_existe" if fim == "defeat" else "", i % 2 == 0, longo if i % 5 == 0 else ""))
	var m: Dictionary = gs.mural()
	checar_igual(m.entries.size(), 30, "30 entradas")
	checar_igual(m.entries[0].name, "John Bullet", "John primeiro")
	for e in m.entries:
		checar(str(e.end_text) != "" and not str(e.end_text).contains("{"), "end_text sem marcador cru: " + str(e.end_text))
		checar(str(e.wins_text) != "" and str(e.art_text) != "", "textos preenchidos")
	checar_igual(m.columns * m.rows_per_page, 10, "10 por pagina (5x2)")
	# mural com roster com campaign duplicada? (nao deve quebrar)
	gs.escola.roster.append(_entrada(2, "retire", 1, 1))
	checar_igual(gs.mural().entries.size(), 31, "31 entradas")
	# mural_na_sala
	var ms: Dictionary = gs.mural_na_sala()
	checar(ms.has("spot_name"), "mural_na_sala na garagem")
	_liberar(gs)


func _migracao_real_e_sintetica() -> void:
	# copia do save real (v12) vem em QA_REAL (pasta temporaria, so leitura do original)
	var real := OS.get_environment("QA_REAL_SAVE")
	if real == "" or not FileAccess.file_exists(real):
		checar(false, "QA_REAL_SAVE nao definido")
		return
	var pasta := pasta_limpa("qa_real")
	DirAccess.copy_absolute(real, pasta + "save.json")
	var antes := FileAccess.get_md5(real)
	var gs := _novo("qa_real", pasta)
	checar_igual([gs.honra(), gs.honra_total(), gs.escola.hall_nodes], [0, 0, []], "save real: so derrotas = 0 de Honra")
	checar_igual([int(gs.permanente.legacy_total), int(gs.permanente.career_number), int(gs.permanente.best_wins)], [450, 6, 6], "save real: Legado, carreira, recorde")
	checar_igual(gs.escola.roster.size(), 3, "roster 3")
	checar_igual(gs.permanente.skill_nodes.size(), 9, "arvore 9 nos")
	checar(gs.marco("garage_saved"), "marco garage_saved preservado")
	gs.salvar()
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pasta + "save.json"))
	checar_igual(int(doc.version), 13, "regravado v13")
	var m: Dictionary = gs.mural()
	checar_igual(m.entries.size(), 3, "mural com 3")
	print("  mural real: ", JSON.stringify(m.entries.map(func(e): return [e.name, e.end_text, e.wins_text, e.symbol, e.extra_key])))
	print("  simbolo campanha: ", gs.campanha_do_simbolo(), " mentor: ", gs.mentor_do_caixote())
	_liberar(gs)
	var gs2 := _novo("qa_real2", pasta)
	checar_igual([gs2.honra(), gs2.honra_total()], [0, 0], "reabrir nao duplica")
	_liberar(gs2)
	checar_igual(FileAccess.get_md5(real), antes, "arquivo original da copia nao mudou")
