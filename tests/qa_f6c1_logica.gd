extends "res://tests/test_base.gd"
## QA 6c1: cenarios extras (so lógica, headless). godot --headless --script res://tests/qa_f6c1_logica.gd
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


func _tickar(gs: Node, s: float, passo: float = 0.1) -> void:
	for i in int(round(s / passo)):
		gs.tick(passo)


func _posto(gs: Node) -> void:
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()


func _com_mentor(nome: String, c: int = 2) -> Node:
	var gs := _novo(nome)
	while gs.numero_carreira() < c:
		_posto(gs)
	_tickar(gs, 0.5)
	return gs


func _chegar(g: Node) -> bool:
	g.cinturao = true
	g.dinheiro = 1.0e9
	return g.mudar()


func _assentar(g: Node) -> void:
	g.cena_sala_terminou()
	if g.escolha_arte_pendente():
		g.escolher_arte(g.academia.ids_artes()[0])


func _vencer(g: Node) -> Dictionary:
	g.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	g.lutar()
	return g.concluir_luta()


func rodar_testes() -> void:
	# A) Fluxo real: vitoria de verdade na academia arma a saida; saida so depois do calmo.
	var g := _com_mentor("qa_a")
	_chegar(g)
	_assentar(g)
	var falas: Array = []
	var pedidos := [0]
	g.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: falas.append(id))
	g.saida_mentor_pedida.connect(func() -> void: pedidos[0] += 1)
	checar(not g.marco("disciple_gym_win"), "A: sem vitoria ainda")
	_vencer(g)
	checar(g.marco("disciple_gym_win"), "A: vitoria real na academia arma a saida")
	_tickar(g, 20.0)
	print("   falas até agora: ", falas, " pedidos saida: ", pedidos[0])
	checar(pedidos[0] == 1, "A: saida pedida depois da vitoria real")
	_tickar(g, 3.0)
	g.saida_terminou()
	_tickar(g, 600.0, 0.5)
	checar(falas.count("cl_primeira_academia") <= 1, "A: cl_primeira_academia no max 1x")
	checar(pedidos[0] == 1, "A: saida nunca repete")
	_liberar(g)

	# B) Derrota na academia nao arma.
	var b := _com_mentor("qa_b")
	_chegar(b)
	_assentar(b)
	b.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
	b.lutar()
	var rb: Dictionary = b.concluir_luta()
	print("   B resultado luta: ", rb.get("vitoria", rb.get("venceu", "?")), " marco=", b.marco("disciple_gym_win"))
	_liberar(b)

	# C) Vitoria na garagem nao arma; vitoria na Carreira 1 (John jogando) na academia nao arma.
	var c := _novo("qa_c")
	_chegar(c)
	_assentar(c)
	_vencer(c)
	checar(not c.marco("disciple_gym_win"), "C: John lutando na academia (Carreira 1) nao arma")
	checar(not c.saida_devida(), "C: saida nao devida na Carreira 1")
	checar(c.mentores_na_sala().is_empty(), "C: Carreira 1 sem mentores na sala")
	checar(c.coach_presente(), "C: Osmar na academia na Carreira 1")
	_tickar(c, 300.0, 0.5)
	checar(not c.saida_tocando(), "C: nada de saida na Carreira 1")
	_liberar(c)

	# D) Interrupcao pelo dia da luta.
	var d := _com_mentor("qa_d")
	d._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
	d.lutas.calendario["seconds_per_day"] = 10.0
	var pd := [0, 0]
	d.saida_mentor_pedida.connect(func() -> void: pd[0] += 1)
	d.saida_mentor_interrompida.connect(func() -> void: pd[1] += 1)
	_tickar(d, 2.6)
	var tocou: bool = d.saida_tocando()
	print("   D: tocando=", tocou, " fight_day=", d.fight_day, " seg=", d.segundos_campanha)
	if tocou:
		d.segundos_campanha = d._alvo_relogio() if d.fight_day > 0 else d.segundos_campanha
		_tickar(d, 0.5)
		print("   D: apos dia da luta: tocando=", d.saida_tocando(), " interrompidas=", pd[1], " no_dia=", d.no_dia_da_luta())
	_liberar(d)

	# E) Save antigo Carreira 5, John ainda na escola, aberto na academia sem marco: sem cena na carga; MUDAR toca cena e depois a saida.
	var e := _com_mentor("qa_e", 5)
	checar(e.saida_devida(), "E: Carreira 5 com John: saida devida (reserva)")
	e.saida_terminou()
	_tickar(e, 5.0)
	print("   E: saida ja ocorreu na garagem? marco=", e.marco("cena_saida_primeiro_mentor"), " John em mentors=", "first" in e.escola.mentors)
	_liberar(e)

	# F) Carreira 4 em diante na academia com John ainda: saida pedida ANTES do fim da arte/cena?
	var f := _com_mentor("qa_f", 3)
	_chegar(f)
	var pf := [0]
	var ff: Array = []
	f.saida_mentor_pedida.connect(func() -> void: pf[0] += 1)
	f.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: ff.append(id))
	f._gravar_marco("disciple_gym_win", {"opponent": "x"}, false)
	_tickar(f, 40.0)
	checar(pf[0] == 0, "F: durante a cena da academia nao sai (cena_sala=%s)" % f.cena_sala)
	f.cena_sala_terminou()
	_tickar(f, 40.0)
	checar(pf[0] == 0, "F: com a escolha da arte pendente nao sai")
	f.escolher_arte(f.academia.ids_artes()[0])
	_tickar(f, 10.0)
	print("   F: pedidos=", pf[0], " falas=", ff)
	_liberar(f)

	# G) Falas do coach: nenhuma sem localidade que cite coisas da garagem, e so quem esta desenhado fala.
	var gg := _com_mentor("qa_g")
	var fg: Array = []
	gg.fala_pedida.connect(func(q: String, _t: String, id: String) -> void: fg.append([q, id, gg.local_id, gg.coach_presente()]))
	_chegar(gg)
	# durante a cena
	_tickar(gg, 30.0)
	checar(fg.is_empty(), "G: nenhuma fala durante a cena da chegada")
	gg.cena_sala_terminou()
	_tickar(gg, 30.0)
	checar(fg.is_empty(), "G: nenhuma fala com arte pendente")
	gg.escolher_arte(gg.academia.ids_artes()[0])
	_tickar(gg, 600.0, 0.25)
	var ruins := 0
	for x in fg:
		if x[0] == "coach" and not x[3]:
			ruins += 1
	print("   G: falas na academia: ", fg.map(func(x): return x[1]))
	checar(ruins == 0, "G: coach so fala com Osmar desenhado")
	checar(fg.size() > 0 and fg[0][1] == "cl_primeira_academia", "G: a primeira fala do Osmar na academia e cl_primeira_academia")
	var art := 0
	for x in fg:
		if str(x[1]).begins_with("cl_arte"):
			art += 1
	checar(art <= 1, "G: comentario da arte no max 1x por campanha (%d)" % art)
	_liberar(gg)
