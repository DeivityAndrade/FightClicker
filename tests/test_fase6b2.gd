extends "res://tests/test_base.gd"
## Fase 6b2 (Cara de lutador): sorteio com pesos, pares evitados, meião, linhas da tela, segundo mentor,
## save da 6b1 e balanço inalterado. As opções novas ficam ligadas por contexto de teste (ligar_todas_as_opcoes),
## sem depender da arte. Tudo em user://test/, nunca o save real.

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


# Discípulo jogando, John sentado na garagem (roster só com o John), opções da 6b2 ligadas.
func _com_mentor(nome: String) -> Node:
	var gs := _novo(nome)
	gs.disciples.ligar_todas_as_opcoes()
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	_tickar(gs, 3.0)
	return gs


func _entrada(camp: int, fim: String, cor_calcao: String = "blue", nome: String = "") -> Dictionary:
	var look := {"skin": "skin_2", "hair_color": "black", "hair_style": "bun", "shorts_color": cor_calcao,
		"top": "tee", "top_color": "gray", "headband": "band", "headband_color": "white", "socks": "on"}
	return {"campaign": camp, "kind": "disciple", "name": nome if nome != "" else "Disc%d" % camp, "look": look, "end": fim,
		"wins": 3, "belt": false, "art": "", "opponent": "", "legacy_gained": 0}


func rodar_testes() -> void:
	_teste_dados()
	_teste_sorteio()
	_teste_pares()
	_teste_meiao_e_cores()
	_teste_linhas_tela()
	_teste_segundo_mentor()
	_teste_save_6b1()
	_teste_balanco()


func _teste_dados() -> void:
	var d := DiscipulosData.carregar()
	checar_igual(d.erros, [], "disciples.json v2 carrega sem erro")
	checar_igual(SaveStore.VERSAO_ATUAL, 13, "save continua v12, sem migração nova")
	checar_igual(d.sorteio_cfg.get("avoid_pairs", []).size(), 8, "8 pares evitados")
	checar_igual(int(d.sorteio_cfg.get("max_rerolls", 0)), 8, "máximo de 8 rodadas")
	checar_igual(d.passagem_tela.get("rows", []).size(), 10, "10 linhas na tela")
	d.ligar_todas_as_opcoes()
	checar_igual([d.opcoes_ativas("hair_style").size(), d.opcoes_ativas("top").size(), d.opcoes_ativas("top_color").size(),
		d.opcoes_ativas("headband_color").size(), d.opcoes_ativas("socks").size()], [4, 3, 6, 6, 2], "contexto de teste liga as opções novas")


func _teste_sorteio() -> void:
	var d := DiscipulosData.carregar()
	d.ligar_todas_as_opcoes()
	var rng := RandomNumberGenerator.new()
	rng.seed = 62
	var n := 10000
	var cont := {"none": 0, "tank": 0, "tee": 0, "band": 0, "on": 0}
	var cortes := {"buzz": 0, "short": 0, "volume": 0, "bun": 0}
	for i in n:
		var l: Dictionary = d.sortear(rng, []).look
		cont[l.top] += 1
		if l.headband == "band":
			cont["band"] += 1
		if l.socks == "on":
			cont["on"] += 1
		cortes[l.hair_style] += 1
	var pct := func(x: int) -> float: return 100.0 * x / n
	checar(absf(pct.call(cont["none"]) - 40.0) <= 2.0, "peso: ~40%% sem parte de cima (%.1f)" % pct.call(cont["none"]))
	checar(absf(pct.call(cont["tank"]) - 30.0) <= 2.0, "peso: ~30%% regata (%.1f)" % pct.call(cont["tank"]))
	checar(absf(pct.call(cont["tee"]) - 30.0) <= 2.0, "peso: ~30%% camiseta (%.1f)" % pct.call(cont["tee"]))
	checar(absf(pct.call(cont["band"]) - 40.0) <= 2.0, "peso: ~40%% com faixa (%.1f)" % pct.call(cont["band"]))
	checar(absf(pct.call(cont["on"]) - 50.0) <= 2.0, "peso: ~50%% com meião (%.1f)" % pct.call(cont["on"]))
	var ok := true
	for k in cortes:
		ok = ok and absf(pct.call(cortes[k]) - 25.0) <= 2.0
	checar(ok, "cortes uniformes (~25%% cada)")
	# Calção e cabeça diferentes do último discípulo (1 novo sorteio: sobra uma chance pequena de repetir).
	var ultimo := {"kind": "disciple", "name": "X", "look": d.look_padrao.duplicate()}
	var mesmo_calcao := 0
	var mesma_cabeca := 0
	for i in n:
		var l: Dictionary = d.sortear(rng, [ultimo]).look
		mesmo_calcao += 1 if l.shorts_color == ultimo.look.shorts_color else 0
		mesma_cabeca += 1 if l.hair_style == ultimo.look.hair_style and l.hair_color == ultimo.look.hair_color else 0
	checar_igual(mesmo_calcao, 0, "calção nunca repete o do último")
	checar_igual(mesma_cabeca, 0, "cabeça nunca repete a do último")
	# Só opções ligadas: com a arte desligada (padrão do JSON) nada novo sai.
	var d2 := DiscipulosData.carregar()
	var vazou := false
	for i in 300:
		var l: Dictionary = d2.sortear(rng, []).look
		for campo in ["hair_style", "top", "headband", "socks"]:
			vazou = vazou or not (l[campo] in d2.opcoes_ativas(campo))
	checar(not vazou, "só sorteia opções ligadas")


func _teste_pares() -> void:
	var d := DiscipulosData.carregar()
	d.ligar_todas_as_opcoes()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var ruins := 0
	for i in 10000:
		if d.par_feio(d.sortear(rng, []).look):
			ruins += 1
	checar_igual(ruins, 0, "nenhum par feio em 10.000 sorteios")
	# A escolha manual é livre: o par existe e é detectado, mas nada impede o rascunho de aceitá-lo.
	var feio := d.look_padrao.duplicate()
	feio["hair_color"] = "black"
	feio["headband_color"] = "black"
	checar(d.par_feio(feio), "par da tabela é reconhecido (cabelo preto + faixa preta)")
	# Nunca trava: se o reroll não resolve (só uma cor de faixa ligada), o sorteio termina.
	var d3 := DiscipulosData.carregar()
	d3.ligar_todas_as_opcoes()
	for o in d3.opcoes("headband_color"):
		o["enabled"] = str(o.id) == "black"
	for o in d3.opcoes("hair_color"):
		o["enabled"] = str(o.id) == "black"
	var r: Dictionary = d3.sortear(rng, [])
	checar(r.look.headband_color == "black" and r.look.hair_color == "black", "par impossível de evitar: fica, sem travar")
	# Gs: o rascunho aceita o par feio na tela.
	var gs := _com_mentor("f6b2_pares")
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	checar(gs.definir_rascunho("hair_color", "black") and gs.definir_rascunho("headband_color", "black"), "tela aceita qualquer combinação")
	_liberar(gs)


func _teste_meiao_e_cores() -> void:
	var d := DiscipulosData.carregar()
	d.ligar_todas_as_opcoes()
	var l := d.look_padrao.duplicate()
	l["skin"] = "skin_2"
	l["shorts_color"] = "blue"
	l["socks"] = "none"
	var c := d.cores(l)
	checar_igual(c.size(), 9, "cores_visual cobre as 9 peças")
	checar_igual(c.socks.colors, ["#8f5238", "#cc8c62", "#cc8c62"], "meião 'sem' vira a pele [shadow, base, base]")
	l["socks"] = "on"
	c = d.cores(l)
	checar_igual(c.socks.colors, ["#1f2a44", "#2f4a78", "#8fbbe0"], "meião 'com' copia o calção [dark, mid, band]")
	checar_igual(c.socks.tokens, ["b0", "b1", "b3"], "tokens do meião vêm do calção")
	l["shorts_color"] = "green"
	checar_igual(d.cores(l).socks.colors[1], "#2f6b4a", "trocar o calção troca o meião")
	l["top"] = "tank"
	l["top_color"] = "gray"
	l["headband"] = "band"
	l["headband_color"] = "blue"
	c = d.cores(l)
	checar_igual([c.top_color.colors, c.headband_color.tokens, c.top.id, c.headband.id, c.hair_style.id],
		[["#6b6570", "#8f8890", "#b8b0aa"], ["b1", "b2"], "tank", "band", "short"], "cores da parte de cima e da faixa, ids das formas")


func _teste_linhas_tela() -> void:
	var d := DiscipulosData.carregar()
	d.ligar_todas_as_opcoes()
	var l := d.look_padrao.duplicate()
	var linhas := d.linhas_tela(l)
	var campos: Array = []
	for x in linhas:
		campos.append(x.field)
	checar_igual(campos, ["name", "skin", "hair_style", "hair_color", "headband", "headband_color", "top", "top_color", "shorts_color", "socks"], "ordem das linhas")
	var colunas: Array = []
	for x in linhas:
		colunas.append(x.coluna)
	checar_igual(colunas, [1, 1, 1, 1, 1, 1, 2, 2, 2, 2], "coluna 1 = cabeça, coluna 2 = corpo")
	var apagadas := {}
	for x in linhas:
		apagadas[x.field] = x.apagada
	checar(apagadas.headband_color and apagadas.top_color and not apagadas.skin, "cor apagada com a peça em 'sem'")
	l["top"] = "tee"
	l["headband"] = "band"
	apagadas = {}
	for x in d.linhas_tela(l):
		apagadas[x.field] = x.apagada
	checar(not apagadas.headband_color and not apagadas.top_color, "ligando a peça, a cor volta")
	checar_igual(linhas[2].opcoes, ["buzz", "short", "volume", "bun"], "linha de texto passa pelas opções na ordem do JSON")


func _teste_segundo_mentor() -> void:
	# Só o John no roster (ou vazio): ninguém.
	var gs := _com_mentor("f6b2_m_john")
	checar_igual(gs.segundo_mentor(), {}, "roster só com o John: sem 2º mentor")
	checar_igual(gs.mentores_na_sala().size(), 1, "só o John na sala")
	gs.escola.roster = []
	checar_igual(gs.segundo_mentor_entrada(), {}, "roster vazio: sem 2º mentor")
	# John + 1.
	gs.escola.roster = [{"campaign": 1, "kind": "first", "name": "John Bullet", "look": null, "end": "retire"}, _entrada(2, "retire")]
	var m: Dictionary = gs.segundo_mentor()
	checar_igual([m.get("nome", ""), m.get("pose", ""), m.get("glove", ""), m.get("facing", ""), m.get("ponto", [])],
		["Disc2", "stand_bare", "none", "right", [26, 304]], "John + 1: 2º mentor parado, sem luvas, virado ao saco, no mentor_2_spot")  # 6d3 (bug B1): mentor_2_spot fora da frente do carro
	checar_igual(m.look, _entrada(2, "retire").look, "visual gravado no roster, os 9 campos")
	var na_sala: Array = gs.mentores_na_sala()
	checar_igual([na_sala.size(), na_sala[0].id, na_sala[1].id, na_sala[1].spot], [2, "first", "last", "mentor_2_spot"], "mentores_na_sala devolve os 2")
	# John + 3: pega o último.
	gs.escola.roster = [{"campaign": 1, "kind": "first", "name": "John", "look": null, "end": "retire"},
		_entrada(2, "retire"), _entrada(3, "defeat"), _entrada(4, "retire")]
	checar_igual(gs.segundo_mentor().nome, "Disc4", "John + 3: o último")
	# Quem perdeu conta.
	gs.escola.roster = [{"campaign": 1, "kind": "first", "name": "John", "look": null, "end": "retire"}, _entrada(2, "retire"), _entrada(3, "defeat")]
	checar_igual(gs.segundo_mentor().nome, "Disc3", "quem perdeu (defeat) também é o 2º mentor")
	gs.escola.roster[2]["end"] = "unknown"
	checar_igual(gs.segundo_mentor().nome, "Disc3", "fim unknown (migração) conta")
	gs.escola.roster[2]["end"] = "lixo"
	gs.escola.roster[2]["end"] = "em_andamento"
	checar_igual(gs.segundo_mentor().nome, "Disc2", "fim fora de passed_ends não conta: cai para o anterior")
	# look ausente: visual padrão.
	gs.escola.roster = [{"campaign": 1, "kind": "first", "name": "John", "look": null, "end": "retire"},
		{"campaign": 2, "kind": "disciple", "name": "Novato", "look": null, "end": "unknown"}]
	checar_igual(gs.segundo_mentor().look, gs.disciples.look_padrao, "entrada sem look: visual padrão")
	# Academia: ninguém.
	gs.escola.roster = [{"campaign": 1, "kind": "first", "name": "John", "look": null, "end": "retire"}, _entrada(2, "retire")]
	gs.local_id = "gym"
	checar_igual(gs.segundo_mentor(), {}, "academia: sem 2º mentor (6c)")
	gs.local_id = "garage"
	# mentors == []: o John não está sentado, o 2º também não.
	var guardado: Array = gs.escola.mentors.duplicate()
	gs.escola.mentors = []
	checar_igual([gs.segundo_mentor(), gs.mentores_na_sala()], [{}, []], "sem o John na sala, o 2º mentor também não aparece")
	gs.escola.mentors = guardado
	checar(not gs.segundo_mentor().is_empty(), "com o John de volta, ele volta")
	# Durante a primeira_sucessao: some. Durante a chegada_discipulo: aparece (já é o novo último).
	gs.escola["handover"] = {"stage": "creating", "campaign": 9, "scene": "primeira_sucessao", "draft": {}}
	gs.sucessao = "creating"
	checar_igual(gs.segundo_mentor(), {}, "durante a cena grande: escondido")
	gs.escola["handover"]["scene"] = "chegada_discipulo"
	checar(not gs.segundo_mentor().is_empty(), "durante a chegada curta: aparece")
	gs.escola["handover"] = null
	gs.sucessao = "none"
	_liberar(gs)
	# Campanha do John: ninguém.
	var j := _novo("f6b2_m_campanha_john")
	j.escola.roster = [_entrada(2, "retire")]
	checar_igual([j.segundo_mentor(), j.mentores_na_sala()], [{}, []], "campanha do John: sem 2º mentor")
	_liberar(j)
	# Troca no RECEBER: quem acabou de passar o posto já é o 2º mentor na criação seguinte.
	var g := _com_mentor("f6b2_m_troca")
	g.aposentar()
	var nome_saindo: String = g.nome_lutador()
	g.receber_discipulo()
	g.sucessao_tela_aberta()
	g.confirmar_discipulo()
	checar_igual(g.segundo_mentor().get("nome", ""), nome_saindo, "no RECEBER o 2º mentor é quem acabou de passar o posto")
	g.sucessao_terminou()
	checar_igual(g.segundo_mentor().get("nome", ""), nome_saindo, "continua depois da chegada")
	_liberar(g)


func _teste_save_6b1() -> void:
	var pasta := pasta_limpa("f6b2_save6b1")
	var look_6b1 := {"skin": "skin_4", "hair_color": "copper", "hair_style": "short", "shorts_color": "purple", "top": "none",
		"top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"}
	var roster := [
		{"campaign": 1, "kind": "first", "name": "John Bullet", "look": null, "end": "retire", "wins": 5},
		{"campaign": 2, "kind": "disciple", "name": "Ana", "look": look_6b1, "end": "defeat", "wins": 2},
		{"campaign": 3, "kind": "disciple", "name": "Beto", "look": look_6b1, "end": "retire", "wins": 4}]
	var doc := {"version": 12, "saved_at_unix": 1730000000, "state": {"career": {"training": 5.0, "money": 2.0},
		"permanent": {"career_number": 4}, "school": {"first_fighter_campaign": 1, "mentors": ["first"], "roster": roster,
		"handover": {"stage": "creating", "campaign": 4, "scene": "chegada_discipulo", "draft": {"name": "Caio", "look": look_6b1}}}}}
	escrever(pasta + "save.json", JSON.stringify(doc))
	var gs := _novo("f6b2_save6b1", pasta)
	checar_igual(gs.sucessao_estado(), "creating", "save da 6b1 abre na criação")
	checar_igual([gs.rascunho().name, gs.rascunho().look], ["Caio", look_6b1], "rascunho aberto mantém os valores")
	checar_igual(gs.segundo_mentor_entrada().name, "Beto", "2º mentor = último do roster")
	gs.disciples.ligar_todas_as_opcoes()
	var variou := false
	for i in 40:
		gs.sortear_rascunho()
		var l: Dictionary = gs.rascunho().look
		variou = variou or l.hair_style != "short" or l.top != "none" or l.headband != "none" or l.socks != "none"
	checar(variou, "SORTEAR passa a variar os campos novos")
	gs.salvar()
	var lido = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual(int(lido.version), SaveStore.VERSAO_ATUAL, "continua v12 depois de salvar")
	_liberar(gs)


func _teste_balanco() -> void:
	# Mesma campanha com e sem 2º mentor e com visuais diferentes: números idênticos.
	var a := _com_mentor("f6b2_bal_a")
	var b := _com_mentor("f6b2_bal_b")
	b.escola.roster = [{"campaign": 1, "kind": "first", "name": "John", "look": null, "end": "retire"}, _entrada(2, "defeat")]
	b.discipulo["look"] = _entrada(9, "retire").look
	checar(a.segundo_mentor().is_empty() and not b.segundo_mentor().is_empty(), "a sem 2º mentor, b com")
	for g in [a, b]:
		g.lutas.calendario["seconds_per_day"] = 60.0
		for i in 300:
			if i % 3 == 0:
				g.clicar()
			g.tick(0.1)
	checar_igual([b.segundos_campanha, b.treino, b.dinheiro, b.dia_campanha(), b.fight_day],
		[a.segundos_campanha, a.treino, a.dinheiro, a.dia_campanha(), a.fight_day], "visual e 2º mentor não mudam relógio, treino, ouro, dia nem luta")
	_liberar(a)
	_liberar(b)
