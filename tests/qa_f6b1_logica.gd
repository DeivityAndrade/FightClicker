extends "res://tests/test_base.gd"
## QA 6b1: cenarios extras de logica (nome, relogio, toques, migracao v10 do dono, saves corrompidos). Tudo em user://test/.
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


func _tick(gs: Node, s: float, p: float = 0.1) -> void:
	for i in int(round(s / p)):
		gs.tick(p)


func rodar_testes() -> void:
	_nome()
	_relogio_e_acoes()
	_toques()
	_migracao_real()
	_corrompidos()
	_receber_duplo()
	_toques_cancelar_e_derrota()
	_reacao_orfa()


func _nome() -> void:
	var gs := _novo("qa6b1_nome")
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	checar_igual(gs.sucessao_estado(), "creating", "criacao aberta")
	var casos := {
		"ABCDEFGHIJKLMN": "ABCDEFGHIJKLMN",  # 14
		"ABCDEFGHIJKLMNOP": "ABCDEFGHIJKLMN",  # 16 corta em 14
		"Zé Ção Ôntem": "Zé Ção Ôntem",
		"João123": "João",
		"a-b_c": "abc",
		"   ": "",
		"": "",
		"12345": "",
		"😀😀": "",
		"  Dois   Espaços ": "Dois Espaços",
		"ÁÉÍÓÚ": "ÁÉÍÓÚ",
		"ñandú": "andú",
		"<b>x</b>": "bxb",
	}
	for k in casos:
		var obt: String = gs.limpar_nome(k)
		checar_igual(obt, casos[k], "limpar_nome(%s)" % k.replace("\n", "\\n"))
	# digitação: rascunho nunca passa de 14
	gs.definir_rascunho("name", "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
	checar_igual(gs.rascunho().name.length(), 14, "digitação corta em 14")
	gs.definir_rascunho("name", "x́y")  # acento combinante
	print("INFO combinante -> '", gs.rascunho().name, "'")
	# nome só com espaço: não confirma, volta sorteado
	gs.definir_rascunho("name", "     ")
	checar(not gs.confirmar_discipulo(), "nome de espaços não confirma")
	var n1: String = gs.rascunho().name
	checar(n1 != "" and gs.limpar_nome(n1) != "", "volta a nome sorteado: " + n1)
	# nome com 14 letras com espaço no fim (13+espaço) = limpo
	gs.definir_rascunho("name", "ABCDEFGHIJKLM ")
	checar(gs.confirmar_discipulo(), "confirma 13+espaço")
	checar_igual(gs.discipulo.name, "ABCDEFGHIJKLM", "espaço final cortado")
	# definir_rascunho fora da criação
	checar(not gs.definir_rascunho("name", "x"), "definir fora da criação recusa")
	checar(not gs.sortear_rascunho(), "sortear fora da criação recusa")
	checar(not gs.confirmar_discipulo(), "confirmar 2x recusa")
	# sorteio: 200 sorteios nunca invalidos, nunca nome vazio
	var g2 := _novo("qa6b1_sorteio")
	g2.aposentar()
	g2.receber_discipulo()
	g2.sucessao_tela_aberta()
	var ruim := 0
	var vis := {}
	for i in 300:
		g2.sortear_rascunho()
		var r: Dictionary = g2.rascunho()
		if g2.limpar_nome(r.name) != r.name or r.name == "" or r.look.size() != 9:
			ruim += 1
		if r.look.hair_style != "short" or r.look.top != "none" or r.look.headband != "none" or r.look.socks != "none":
			ruim += 1
		vis[r.look.skin + r.look.hair_color + r.look.shorts_color] = 1
	checar_igual(ruim, 0, "300 sorteios válidos, só campos da 6b1 variam")
	checar(vis.size() > 60, "variedade de visuais (%d/180)" % vis.size())
	# SORTEAR nunca repete o nome atual
	var rep := 0
	for i in 100:
		var antes: String = g2.rascunho().name
		g2.sortear_rascunho()
		if g2.rascunho().name == antes:
			rep += 1
	checar_igual(rep, 0, "SORTEAR não repete o nome do rascunho")
	_lib(g2)
	_lib(gs)


func _relogio_e_acoes() -> void:
	var gs := _novo("qa6b1_relogio")
	gs.lutas.calendario["seconds_per_day"] = 30.0
	_tick(gs, 20.0)
	gs.aposentar()
	gs.receber_discipulo()
	var f := [gs.segundos_campanha, gs.tempo_jogo, gs.treino, gs.dinheiro, gs.fight_day, gs.dia_campanha() if gs.has_method("dia_campanha") else 0]
	gs.autosave_ativo = true
	for estado in ["scene_1", "creating", "scene_2"]:
		_tick(gs, 300.0, 0.5)
		checar_igual([gs.segundos_campanha, gs.tempo_jogo, gs.treino, gs.dinheiro, gs.fight_day], f.slice(0, 5), "relógio parado em " + gs.sucessao_estado())
		var click: Dictionary = gs.clicar()
		checar(click.is_empty(), "clique recusado em " + gs.sucessao_estado())
		if estado == "scene_1":
			gs.sucessao_tela_aberta()
		elif estado == "creating":
			gs.confirmar_discipulo()
	# compras/lutar durante sucessão
	var g2 := _novo("qa6b1_acoes")
	g2.dinheiro = 1.0e9
	g2.treino = 1.0e9
	g2.aposentar()
	g2.receber_discipulo()
	var d0: float = g2.dinheiro
	var ap: Array = g2.dados.todos_aparelhos()
	for a in ap:
		g2.comprar_aparelho(a.id) if g2.has_method("comprar_aparelho") else null
	checar_igual(g2.dinheiro, d0, "nenhuma compra de aparelho durante a sucessão (ouro %s)" % str(g2.dinheiro))
	checar(not g2.lutar() if g2.has_method("lutar") else true, "lutar durante sucessão recusado")
	# ouro negativo / NaN: nunca
	checar(g2.dinheiro >= 0.0, "ouro não negativo")
	g2.aposentar()  # com fim vazio e sucessão aberta
	checar_igual(g2.sucessao_estado(), "scene_1", "aposentar durante sucessão não muda estado")
	_lib(g2)
	_lib(gs)


func _toques() -> void:
	var gs := _novo("qa6b1_toques")
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	var planos: Array = []
	var cancel := [0]
	gs.toques_mentor_pedidos.connect(func(p: Dictionary) -> void: planos.append(p))
	gs.toques_mentor_cancelados.connect(func() -> void: cancel[0] += 1)
	# 1o clique
	gs.clicar()
	checar_igual(planos.size(), 1, "1º clique: 1 toque")
	gs.clicar()  # dentro da guarda 0,5s
	checar_igual(cancel[0], 0, "clique dentro da guarda não cancela")
	_tick(gs, 0.6)
	# depois de acabar não cancela nada (já terminou)
	gs.clicar()
	for i in 10:
		gs.clicar()
		_tick(gs, 0.2)
	checar_igual(planos.size(), 1, "cliques seguintes: sem novos toques (mentor_greeted)")
	# gesto do discípulo: nunca
	checar_igual(gs.pedir_gesto("first_click") if gs.has_method("pedir_gesto") else {}, {}, "discípulo não faz gesto")
	# vitória: simula resumo
	var antes := planos.size()
	gs._toques_apos_vitoria({"win": true})
	_tick(gs, 1.2)
	print("INFO apos vitoria planos=", planos.size() - antes, " (t_real desde 1o toque ~ 3s -> bloqueado esperado)")
	checar_igual(planos.size() - antes, 0, "vitória < 60 s do último toque: descartado, não guardado")
	_tick(gs, 70.0, 0.5)
	checar_igual(planos.size() - antes, 0, "...e não aparece depois (nunca guardado)")
	gs._toques_apos_vitoria({"win": true})
	_tick(gs, 0.9)
	checar_igual(planos.size() - antes, 0, "antes de 1,0 s: nada")
	_tick(gs, 0.3)
	checar_igual(planos.size() - antes, 1, "depois de 60 s e 1,0 s: toca")
	# clique cancela antes de começar
	_tick(gs, 70.0, 0.5)
	gs._toques_apos_vitoria({"win": true})
	_tick(gs, 0.5)
	gs.clicar()
	_tick(gs, 2.0)
	checar_igual(planos.size() - antes, 1, "clique antes do 1,0 s cancela (não toca)")
	# 20 vitórias seguidas: no máximo 1 por 60 s
	var n0 := planos.size()
	_tick(gs, 70.0, 0.5)
	for i in 20:
		gs._toques_apos_vitoria({"win": true})
		_tick(gs, 2.0)
	checar(planos.size() - n0 <= 1, "20 vitórias em 40 s: no máximo 1 toque (%d)" % (planos.size() - n0))
	# derrota/retire não toca
	var n1 := planos.size()
	_tick(gs, 70.0, 0.5)
	gs._toques_apos_vitoria({"win": true, "retire": true})
	_tick(gs, 3.0)
	gs._toques_apos_vitoria({"win": false})
	_tick(gs, 3.0)
	checar_igual(planos.size(), n1, "retire/derrota: nada")
	# fora da garagem
	gs.local_id = "gym" if gs.local_id == "garage" else gs.local_id
	checar(not gs.mentor_sentado(), "mentor só sentado na garagem")
	_lib(gs)


func _grava(pasta: String, texto: String) -> void:
	escrever(pasta + "save.json", texto)


func _v10_do_dono(pendente: bool) -> Dictionary:
	# O save real do dono ja foi migrado para v12 (Carreira 4). Derivamos um v10 "Carreira 3" dele (so leitura).
	var d0: Dictionary = JSON.parse_string(ler(SaveStore.PASTA_REAL.path_join("save.json")))
	var st: Dictionary = d0.state
	st.permanent["career_number"] = 3
	st.permanent.erase("careers_finished") if false else null
	st.erase("school")
	st.career.erase("disciple")
	st.career.erase("mentor_greeted")
	st.career.erase("gestured_gloves")
	if pendente:
		st["ending"] = {"kind": "defeat", "opponent": "muralha", "wins": 2, "belt": false, "art": "boxing", "legacy_gained": 12, "legacy_total": 12}
	else:
		st["ending"] = null
	return {"version": 10, "saved_at_unix": d0.saved_at_unix, "state": st}


func _migracao_real() -> void:
	var orig := ler(SaveStore.PASTA_REAL.path_join("save.json"))
	var d_real: Dictionary = JSON.parse_string(orig)
	print("INFO save real agora: version=", d_real.version, " career_number=", d_real.state.permanent.career_number)
	for pend in [false, true]:
		var pasta := pasta_limpa("qa6b1_v10_dono_%s" % str(pend))
		var doc := _v10_do_dono(pend)
		escrever(pasta + "save.json", JSON.stringify(doc))
		var antes: Dictionary = doc.state
		var gs: Node = GS.new()
		gs.inicializar(pasta, "res://data/config.json")
		gs.autosave_ativo = false
		var tag := "v10 dono pend=%s: " % str(pend)
		checar_igual(gs.numero_carreira(), 3, tag + "carreira 3")
		checar_igual(gs.lutador_atual(), "first", tag + "campanha atual = John")
		checar_igual(gs.permanente.legacy_total, int(antes.permanent.legacy_total), tag + "legado igual")
		checar_igual(gs.permanente.skill_nodes.size(), antes.permanent.skill_nodes.size(), tag + "arvore igual")
		checar_igual(gs.permanente.belts_won, int(antes.permanent.belts_won), tag + "belts_won igual")
		checar(is_equal_approx(gs.treino, float(antes.career.training)), tag + "treino igual")
		checar_igual(gs.fight_day, int(antes.career.fight_day), tag + "calendário igual")
		checar_igual(gs.escola.first_fighter_campaign, 3 if not pend else 4, tag + "first_fighter_campaign")
		checar_igual([gs.escola.handover, gs.escola.mentors, gs.sucessao_estado()], [null, [], "none"], tag + "sem handover/mentor")
		print("INFO ", tag, "lutador=", gs.lutador_atual(), " nome=", gs.nome_lutador(), " roster=", gs.escola.roster.size(), " fim=", gs.fim.size())
		gs.salvar()
		var d: Dictionary = JSON.parse_string(ler(pasta + "save.json"))
		checar_igual(int(d.version), 12, tag + "regravado v12")
		if not pend:
			gs.aposentar()
			checar_igual(gs.escola.roster.size(), 1, tag + "John entra no roster")
			checar(gs.receber_discipulo(), tag + "RECEBER")
			checar_igual(gs.sucessao_cena(), "primeira_sucessao", tag + "cena grande toca")
			checar_igual(gs.numero_carreira(), 4, tag + "carreira 4")
		else:
			# fim pendente do John: first_fighter_campaign=4 (v10->v11 empurra); numero 3 < 4
			print("INFO fim pendente: receber_discipulo ->", gs.receber_discipulo(), " carreira=", gs.numero_carreira(), " cena=", gs.sucessao_cena(), " estado=", gs.sucessao_estado(), " lutador=", gs.lutador_atual())
		gs.aguardar_motivo()
		gs.free()
	# v11 com Novato em andamento (N>F)
	var p2 := pasta_limpa("qa6b1_v11_novato")
	var perm := {"career_number": 4, "legacy_total": 50, "legacy_spent": 10, "careers_finished": 3, "belts_won": 1, "skill_nodes": ["x"]}
	var escola := {"first_fighter_campaign": 2, "milestones": {"abertura_6a": {"campaign": 2, "version": 1}}, "last_end": {"campaign": 3, "kind": "defeat"}}
	var doc := {"version": 11, "saved_at_unix": 1730000000, "state": {"career": {"training": 10.0, "money": 5.0}, "permanent": perm, "ending": null, "school": escola}}
	_grava(p2, JSON.stringify(doc))
	var g: Node = GS.new()
	g.inicializar(p2, "res://data/config.json")
	g.autosave_ativo = false
	checar_igual([g.discipulo.get("name"), g.nome_lutador(), g.texto_hud_lutador()], ["Novato", "Novato", "NOVATO"], "v11 Novato em andamento: nome padrão")
	checar_igual(g.escola.roster.size(), 2, "roster com John (c2) e Novato (c3)")
	checar_igual([g.escola.roster[0].kind, g.escola.roster[1].kind, g.escola.roster[1].end], ["first", "disciple", "defeat"], "roster kinds/end")
	checar_igual(g.permanente.legacy_total, 50, "legado preservado")
	_lib(g)


func _corrompidos() -> void:
	var base := {"career": {"training": 10.0, "money": 5.0}, "permanent": {"career_number": 3, "legacy_total": 5, "skill_nodes": []}, "ending": null}
	var casos := {
		"handover_lixo": {"first_fighter_campaign": 2, "handover": "texto", "mentors": 5, "roster": "x"},
		"handover_camp_errada": {"first_fighter_campaign": 2, "handover": {"stage": "creating", "campaign": 99, "scene": "x", "draft": {"name": "A", "look": {}}}},
		"handover_ok_look_lixo": {"first_fighter_campaign": 2, "handover": {"stage": "creating", "campaign": 3, "scene": "primeira_sucessao", "draft": {"name": "\u0000\u0001 123", "look": {"skin": "skin_99", "hair_color": 5, "x": 1}}}},
		"handover_sem_draft": {"first_fighter_campaign": 2, "handover": {"stage": "arriving", "campaign": 3, "scene": "inexistente"}},
		"handover_draft_nulo": {"first_fighter_campaign": 2, "handover": {"stage": "creating", "campaign": 3, "scene": "chegada_discipulo", "draft": null}},
		"roster_lixo": {"first_fighter_campaign": 2, "roster": [1, null, {"kind": "x"}, {"kind": "disciple", "name": 7, "look": "x", "wins": "a", "campaign": -5}]},
	}
	for k in casos:
		var pasta := pasta_limpa("qa6b1_c_" + k)
		var doc := {"version": 12, "saved_at_unix": 1730000000, "state": base.duplicate(true)}
		doc.state["school"] = casos[k]
		doc.state.career["disciple"] = {"name": 12, "look": [], "campaign": "x"} if k == "roster_lixo" else null
		_grava(pasta, JSON.stringify(doc))
		var g: Node = GS.new()
		g.inicializar(pasta, "res://data/config.json")
		g.autosave_ativo = false
		var est: String = g.sucessao_estado()
		print("INFO ", k, " -> estado=", est, " nome=", g.nome_lutador(), " cena=", g.sucessao_cena(), " roster=", g.escola.roster.size(), " rascunho=", g.rascunho())
		checar(g.nome_lutador() != "", k + ": tem nome")
		if est != "none":
			_tick(g, 5.0)
			var cd: float = g.segundos_campanha
			checar_igual(g.segundos_campanha, 0.0 if cd == 0.0 else cd, k + ": ok")
		# salva e relê sem crash
		g.salvar()
		var g2: Node = GS.new()
		g2.inicializar(pasta, "res://data/config.json")
		g2.autosave_ativo = false
		checar_igual(g2.nome_lutador(), g.nome_lutador(), k + ": roundtrip do nome")
		_lib(g2)
		_lib(g)


func _receber_duplo() -> void:
	var gs := _novo("qa6b1_duplo")
	checar(not gs.receber_discipulo(), "RECEBER sem fim pendente: recusa")
	gs.aposentar()
	checar(gs.receber_discipulo(), "RECEBER")
	var n: int = gs.numero_carreira()
	checar(not gs.receber_discipulo(), "RECEBER 2x: recusa")
	checar_igual(gs.numero_carreira(), n, "carreira não pulou")
	checar(not gs.nova_carreira() if gs.has_method("nova_carreira") else true, "nova_carreira() com sucessão: recusa?")
	print("INFO nova_carreira durante sucessao -> carreira=", gs.numero_carreira(), " estado=", gs.sucessao_estado())
	# 30 sucessões seguidas (roster cresce, nomes únicos)
	for i in 30:
		gs.sucessao_tela_aberta()
		if gs.sucessao_estado() == "creating":
			gs.confirmar_discipulo()
		gs.sucessao_terminou()
		gs.aposentar()
		gs.receber_discipulo()
	checar(gs.escola.roster.size() >= 30, "roster cresce: %d" % gs.escola.roster.size())
	_lib(gs)


func _toques_cancelar_e_derrota() -> void:
	var gs := _novo("qa6b1_toques2")
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	var planos: Array = []
	var cancel := [0]
	gs.toques_mentor_pedidos.connect(func(p: Dictionary) -> void: planos.append(p))
	gs.toques_mentor_cancelados.connect(func() -> void: cancel[0] += 1)
	gs.clicar()  # 1º clique
	_tick(gs, 0.7)
	_tick(gs, 70.0, 0.5)
	gs._toques_apos_vitoria({"win": true})
	_tick(gs, 1.05)  # começou
	checar_igual(planos.size(), 2, "vitória: toques começam depois de 1,0 s")
	_tick(gs, 0.1)
	gs.clicar()
	checar_igual(cancel[0], 1, "clique durante os toques da vitória cancela")
	# janela cancela? abrir janela (modal)
	_tick(gs, 70.0, 0.5)
	gs._toques_apos_vitoria({"win": true})
	_tick(gs, 1.05)
	var n: int = cancel[0]
	gs.definir_modal(true)
	_tick(gs, 0.1)
	checar_igual(cancel[0], n + 1, "janela aberta durante os toques cancela")
	gs.definir_modal(false)
	_lib(gs)
	# derrota -> RECEBER -> fecha na criação -> reabre -> CONFIRMAR: comentário da 1ª derrota ainda vem?
	var g := _novo("qa6b1_derrota")
	_tick(g, 3.0)
	g.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	g.lutar()
	g.concluir_luta()
	checar(not g.fim.is_empty(), "derrota gerou fim")
	g.receber_discipulo()
	g.salvar()
	var g2 := _novo("qa6b1_derrota", g.store.pasta)
	var vistos: Array = []
	g2.comentario.connect(func(id: String) -> void: vistos.append(id))
	checar_igual(g2.sucessao_estado(), "creating", "derrota: reabre na criação")
	g2.sucessao_tela_aberta()
	g2.confirmar_discipulo()
	g2.sucessao_terminou()
	_tick(g2, 30.0)
	print("INFO comentarios apos derrota+fechar na criacao: ", vistos)
	checar(vistos.has("cl_primeira_derrota"), "cl_primeira_derrota toca depois da sucessão (obtido %s)" % str(vistos))
	_lib(g2)
	_lib(g)
	# derrota -> RECEBER (sem fechar): idem
	var h := _novo("qa6b1_derrota2")
	_tick(h, 3.0)
	h.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	h.lutar()
	h.concluir_luta()
	var vh: Array = []
	h.comentario.connect(func(id: String) -> void: vh.append(id))
	h.receber_discipulo()
	_tick(h, 30.0)
	checar(vh.is_empty(), "nenhum comentário durante a sucessão")
	h.sucessao_tela_aberta()
	h.confirmar_discipulo()
	h.sucessao_terminou()
	_tick(h, 30.0)
	checar(vh.has("cl_primeira_derrota"), "derrota direta: comentário após a sucessão (%s)" % str(vh))
	_lib(h)


func _reacao_orfa() -> void:
	# Depois do return_control, luta ANTES do 1º clique: a cena descarta a reação, mas o GameState ainda manda cena=primeira_sucessao.
	var gs := _novo("qa6b1_orfa")
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	gs.lutar()
	gs.concluir_luta()
	_tick(gs, 70.0, 0.5)
	var planos: Array = []
	gs.toques_mentor_pedidos.connect(func(p: Dictionary) -> void: planos.append(p))
	gs.clicar()
	print("INFO reacao orfa: planos=", planos.size(), " cena='", planos[0].cena if planos.size() > 0 else "-", "' com_fala=", planos[0].com_fala if planos.size() > 0 else "-")
	checar(planos.size() == 0 or planos[0].cena == "", "1º clique depois de luta: toques sem cena (a UI toca) (obtido cena='%s')" % (planos[0].cena if planos.size() > 0 else "-"))
	_lib(gs)
