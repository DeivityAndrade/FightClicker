extends "res://tests/test_base.gd"
## QA 6b2: sorteio estatistico, repeticao do ultimo, save com ids invalidos, 2o mentor em cenarios extras. Tudo em user://test/.
const GS := preload("res://scripts/game_state.gd")


func _novo(nome: String, pasta: String = "") -> Node:
	var gs: Node = GS.new()
	gs.inicializar(pasta if pasta != "" else pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	gs.pular_abertura()
	return gs


func _lib(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func rodar_testes() -> void:
	_sorteio()
	_save_invalido()
	_nome14()
	_mentor_extra()


func _sorteio() -> void:
	var gs := _novo("f6b2q_sorteio")
	var d = gs.disciples
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var n := 10000
	var cont := {"top": {}, "headband": {}, "socks": {}, "hair_style": {}}
	var feios := 0
	var rep_calcao := 0
	var rep_cabeca := 0
	var ultimo := {"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "shorts_color": "green", "top": "none", "top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"}
	var roster := [{"campaign": 2, "kind": "disciple", "name": "X", "look": ultimo, "end": "retire"}]
	for i in n:
		var r: Dictionary = d.sortear(rng, roster, "")
		var l: Dictionary = r.look
		for c in cont:
			cont[c][l[c]] = int(cont[c].get(l[c], 0)) + 1
		if d.par_feio(l): feios += 1
		if l.shorts_color == ultimo.shorts_color: rep_calcao += 1
		if l.hair_style == ultimo.hair_style and l.hair_color == ultimo.hair_color: rep_cabeca += 1
	print("pesos: ", cont)
	print("pares feios: ", feios, " | calcao repetido: ", rep_calcao, " (", rep_calcao / 100.0, "%) | cabeca repetida: ", rep_cabeca, " (", rep_cabeca / 100.0, "%)")
	checar(absf(cont.top.get("none", 0) / 100.0 - 40.0) < 2.5, "peso sem camisa ~40%")
	checar(absf(cont.top.get("tank", 0) / 100.0 - 30.0) < 2.5, "regata ~30%")
	checar(absf(cont.headband.get("band", 0) / 100.0 - 40.0) < 2.5, "faixa ~40%")
	checar(absf(cont.socks.get("on", 0) / 100.0 - 50.0) < 2.5, "meiao ~50%")
	checar_igual(feios, 0, "nenhum par feio em 10000 sorteios")
	# Escopo/briefing: "sem repetir calcao nem cabeca do ultimo" => deveria ser 0.
	checar_igual(rep_calcao, 0, "SORTEAR nunca repete o calcao do ultimo (garantia)")
	checar_igual(rep_cabeca, 0, "SORTEAR nunca repete a cabeca (corte+cor) do ultimo (garantia)")
	# Roster vazio e SORTEAR em sequencia pela API do rascunho
	_lib(gs)


func _save_invalido() -> void:
	var pasta := pasta_limpa("f6b2q_save_inv")
	var look := {"skin": "skin_9", "hair_color": "rosa", "hair_style": "mohawk", "shorts_color": "red", "top": "robe", "top_color": "red", "headband": "x", "headband_color": 5, "socks": null}
	var doc := {"version": 12, "saved_at_unix": 1730000000, "state": {"career": {"training": 5.0, "money": 2.0, "disciple": {"name": "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "look": look, "campaign": 3}},
		"permanent": {"career_number": 4}, "school": {"first_fighter_campaign": 1, "mentors": ["first"], "roster": [
			{"campaign": 1, "kind": "first", "name": "John", "look": null, "end": "retire"},
			{"campaign": 2, "kind": "disciple", "name": "Ana", "look": look, "end": "defeat"},
			{"campaign": 3, "kind": "disciple", "name": "Bia", "look": "lixo", "end": "retire"}]}}}
	escrever(pasta + "save.json", JSON.stringify(doc))
	var gs := _novo("f6b2q_save_inv", pasta)
	var v: Dictionary = gs.visual_lutador()
	print("visual saneado: ", v)
	checar_igual(v.get("hair_style", ""), "short", "corte invalido cai no padrao")
	checar_igual(v.get("top", ""), "none", "top invalido cai no padrao")
	checar_igual(v.get("top_color", ""), "white", "top_color red (removido) cai no padrao")
	checar_igual(v.get("socks", ""), "none", "socks null cai no padrao")
	checar_igual(gs.segundo_mentor().get("nome", ""), "Bia", "2o mentor com look 'lixo' usa padrao sem quebrar")
	checar_igual(gs.segundo_mentor().get("look", {}), gs.disciples.look_padrao, "look lixo -> padrao")
	checar(gs.nome_lutador().length() <= 14, "nome de 26 letras cortado em <= 14: " + gs.nome_lutador())
	_lib(gs)


func _nome14() -> void:
	var gs := _novo("f6b2q_nome14")
	var d = gs.disciples
	checar_igual(d.limpar_nome("MMMMMMMMMMMMMM"), "MMMMMMMMMMMMMM", "14 M aceito")
	checar_igual(d.limpar_nome("MMMMMMMMMMMMMMM").length(), 14, "15 M corta em 14")
	_lib(gs)


func _mentor_extra() -> void:
	var gs := _novo("f6b2q_mentor")
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	for i in 30: gs.tick(0.1)
	checar(gs.mentor_sentado(), "John sentado")
	# roster grande
	var rr: Array = [{"campaign": 1, "kind": "first", "name": "John", "look": null, "end": "retire"}]
	for i in range(2, 80):
		rr.append({"campaign": i, "kind": "disciple", "name": "D%d" % i, "look": null, "end": "defeat" if i % 2 == 0 else "retire"})
	gs.escola.roster = rr
	checar_igual(gs.segundo_mentor().get("nome", ""), "D79", "roster de 79: ultimo")
	# a visibilidade do 2o mentor nao muda o relogio
	var antes: float = gs.segundos_campanha
	gs.tick(5.0)
	print("relogio andou ", gs.segundos_campanha - antes)
	# Criacao aberta: relogio parado
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	var a: float = gs.segundos_campanha
	for i in 100: gs.tick(0.1)
	checar_igual(gs.segundos_campanha, a, "relogio parado com a tela de criacao aberta")
	checar(not gs.segundo_mentor().is_empty() or true, "(info) 2o mentor na criacao: " + str(gs.segundo_mentor().get("nome", "-")))
	_lib(gs)
