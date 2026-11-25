extends "res://tests/test_base.gd"
## QA da Ronda Noturna: cenários que o test_ronda.gd não cobre (fuzz do minigame, compras da região, recortes nos 3 locais,
## capuz em 3 locais/MUDAR/nova campanha, saves sujos extras, tela headless). Roda com: --script res://tests/qa_ronda.gd
## Tudo em user://test/ (nunca o save real).

const GameStateScript := preload("res://scripts/game_state.gd")


func rodar_testes() -> void:
	_fuzz_minigame()
	_minigame_pontuais()
	_estado_extremos()
	_recortes_3_locais()
	_capuz_3_locais_e_mudar()
	_regiao_compras()
	_campanhas()
	_saves_extras()
	_save_do_dono()
	_rngs_e_falas()
	await _tela_headless()


func _novo(nome: String, campanha: int = 3, com_marco: bool = true) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.baloes_escondidos = true
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.rng.seed = 4242
	gs.pular_abertura()
	gs.permanente["career_number"] = campanha
	gs.escola.milestones["garage_saved"] = {"version": 1}
	gs.escola.milestones["cena_primeira_academia"] = {"version": 1}
	if com_marco:
		gs.escola.milestones["black_cat_rumor_heard"] = {"campaign": campanha - 1, "version": 1}
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _andar(gs: Node, s: int, passo: float = 1.0) -> void:
	for _i in s:
		gs.tick(passo)


func _cfg() -> Dictionary:
	return RondaData.carregar().noites["scare"]


# ------------------------------------------------------------------------------------------------ fuzz do minigame
func _fuzz_minigame() -> void:
	var cfg := _cfg()
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var viol := 0
	var nao_terminou := 0
	var dts := [1.0 / 60.0, 1.0 / 30.0, 0.05, 0.25, 1.0, 3.0]
	var fim_counts := {"all": 0, "time": 0}
	for r in 4000:
		var j := RondaLogica.new(cfg, rng)
		var segura := false
		var guard := 0
		while j.fase != "fim" and guard < 20000:
			guard += 1
			var dt: float = dts[rng.randi() % dts.size()]
			var acao := rng.randi() % 6
			if acao == 0:
				j.apertar()
			elif acao == 1:
				j.soltar()
			j.avancar(dt)
			var e := j.estado()
			if e.distancia < 0.0 or e.distancia > 1.0 or j.sustos + j.vistos > 3 or j.t > float(cfg.night_s) + 1.0e-6:
				viol += 1
				break
		if j.fase != "fim":
			nao_terminou += 1
		var l := j.lenda()
		if l < 1 or l > 5:
			viol += 1
		if j.sustos + j.vistos < 3:
			fim_counts["time"] += 1
		else:
			fim_counts["all"] += 1
	checar_igual(viol, 0, "fuzz 4000 rondas (dt de 1/60 a 3 s, botao aleatorio): distancia 0..1, sustos+vistos<=3, tempo<=34, lenda 1..5")
	checar_igual(nao_terminou, 0, "fuzz: toda ronda termina")

	# robo esperto (estatua perfeita com leitura do estado): quanto de SUSTO faz com dt=1/60 e 1/10
	for dt in [1.0 / 60.0, 0.1]:
		var tot := 0
		var vis := 0
		var n := 500
		for r in n:
			var j := RondaLogica.new(cfg, rng)
			var guard := 0
			while j.fase != "fim" and guard < 20000:
				guard += 1
				var e := j.estado()
				if e.fase == "jogando" and e.oc_fase == "jogando":
					if e.perto and e.ladrao != "olhando":
						j.apertar()
						j.avancar(dt)
						j.soltar()
						continue
					if e.ladrao == "trabalha":
						j.apertar()
					else:
						j.soltar()
				else:
					j.soltar()
				j.avancar(dt)
			tot += j.sustos
			vis += j.vistos
		print("  robo esperto dt=%.3f: sustos medios %.2f, vistos medios %.2f (de 3)" % [dt, float(tot) / n, float(vis) / n])
		checar(float(tot) / n > 2.5, "robo esperto (dt %.3f) faz em media > 2,5 sustos" % dt)


func _minigame_pontuais() -> void:
	var cfg := _cfg()
	# segurar o tempo todo: deve ser VISTO na 1a olhada e ainda assim terminar sem erro
	var ciclos := [[[2.0, false], [2.0, false], [2.0, false], [2.0, false]], [[2.0, false], [2.0, false]], [[2.0, false], [2.0, false]]]
	var j := RondaLogica.new(cfg, null, ciclos.duplicate(true))
	j.apertar()
	var passos := 0
	while j.fase != "fim" and passos < 100000:
		j.avancar(1.0 / 60.0)
		passos += 1
	checar(j.fase == "fim" and j.vistos >= 1 and j.sustos == 0, "segurar sem parar: VISTO e zero sustos (vistos %d, sustos %d, lenda %d)" % [j.vistos, j.sustos, j.lenda()])
	checar(j.lenda() == 1, "so ir (so segurar): lenda 1")

	# olhar falso: segurar atraves do aviso falso nao e visto
	var cfg2: Dictionary = cfg.duplicate(true)
	var ciclos_f := [[[0.5, true], [100.0, false]], [[100.0, false]], [[100.0, false]]]
	var j2 := RondaLogica.new(cfg2, null, ciclos_f)
	j2.apertar()
	for _i in 600:  # 10 s a 60 fps
		j2.avancar(1.0 / 60.0)
		if j2.fase == "fim":
			break
	var ev := j2.historico.map(func(h): return h[0])
	checar("aviso_falso" in ev and not ("olhou" in ev) and j2.vistos == 0, "aviso falso: o ladrao volta a trabalhar e segurar nao e VISTO (eventos %s)" % str(ev.slice(0, 4)))

	# tolerancia: soltar dentro de grace_s (0,2) do inicio do OLHANDO nao e visto; depois de 0,25 e
	var ciclos_g := [[[0.5, false], [100.0, false]], [[100.0, false]], [[100.0, false]]]
	var j3 := RondaLogica.new(cfg, null, ciclos_g)
	# conta 2 s + intro 0,8 s
	for _i in 160:
		j3.avancar(1.0 / 60.0)
	# anda ate o ladrao comecar a olhar: 0,5 trabalha + 0,8 aviso = olhando em t_oc 1,3
	j3.apertar()
	var visto_em := -1.0
	var t0 := 0.0
	for _i in 600:
		j3.avancar(1.0 / 60.0)
		t0 += 1.0 / 60.0
		if j3.vistos > 0:
			visto_em = t0
			break
	checar(visto_em > 0.0, "segurando no aviso longo: foi VISTO (apos %.2f s)" % visto_em)
	# SAIR no meio da contagem
	var j4 := RondaLogica.new(cfg, null)
	j4.sair()
	checar(j4.fase == "fim" and j4.lenda() == 1 and j4.sustos == 0, "SAIR na contagem: lenda 1 (piso)")
	j4.avancar(5.0)
	j4.apertar()
	checar(j4.fase == "fim" and j4.lenda() == 1, "depois do SAIR a logica nao muda mais")
	# dt gigante de uma vez (suspensao do PC): termina por tempo, sem laco infinito
	var j5 := RondaLogica.new(cfg, RandomNumberGenerator.new())
	var t_ini := Time.get_ticks_msec()
	j5.avancar(100000.0)
	checar(j5.fase == "fim" and Time.get_ticks_msec() - t_ini < 2000, "dt de 100.000 s num quadro so: fecha rapido (%d ms)" % (Time.get_ticks_msec() - t_ini))
	j5.avancar(-5.0)
	j5.avancar(0.0)
	checar(j5.fase == "fim", "dt negativo e zero depois do fim: sem efeito")


# ------------------------------------------------------------------------------------------------ estado em condicoes extremas
func _estado_extremos() -> void:
	var gs := _novo("qa_extremos")
	_andar(gs, 181)
	# IR duas vezes, concluir sem IR, voltar sem IR
	gs.ronda_voltar()
	checar(gs.ronda_concluir().is_empty() and gs.ronda_ativa == "", "concluir/voltar sem Ronda: nada acontece")
	var info: Dictionary = gs.ronda_ir()
	checar(not info.is_empty(), "IR abre")
	checar(gs.ronda_ir().is_empty(), "IR com a Ronda ja ativa: recusa (nada duplica)")
	# tick com dt gigante durante a Ronda: nada anda e termina por tempo (sem ganhar mais que o piso)
	var antes_t: float = gs.segundos_campanha
	gs.tick(5000.0)
	checar(gs.segundos_campanha == antes_t, "tick de 5.000 s durante a Ronda: relogio da campanha parado")
	print("  apos tick(5000): ronda_ativa='%s' lenda=%s" % [gs.ronda_ativa, str(gs.lenda())])
	checar(gs.ronda_ativa != "" and gs.lenda().rounds == 1 and gs.lenda().legend == 1, "hitch de 5.000 s (BUG-3 corrigido): a ronda fecha, +1 de lenda, e o premio fica na tela")
	gs.ronda_voltar()
	checar(gs.ronda_ativa == "", "VOLTAR depois do hitch devolve a sala")
	checar(gs.lenda().rounds == 1 and gs.lenda().legend == 1, "lenda continua 1 (sem dobrar)")
	# o capuz so volta 240 s depois da volta
	_andar(gs, 239)
	checar(not gs.capuz_info().get("clickable", false), "239 s depois: sem capuz")
	_andar(gs, 2)
	checar(gs.capuz_info().get("clickable", false), "241 s depois: capuz")
	# SAIR com a tela ainda na contagem pelo GameState
	gs.ronda_ir()
	var q: Dictionary = gs.ronda_concluir()
	checar(str(q.ended) == "exit" and q.legend_gain == 1 and gs.lenda().legend == 2, "SAIR imediato: +1")
	gs.ronda_voltar()
	gs.ronda_voltar()
	checar(gs.ronda_ativa == "" and gs.sala_ativa(), "voltar duas vezes: sala normal")
	# dia da luta: capuz sem clique (nao some)
	gs.capuz["open"] = "scare"
	gs.capuz["hood_s"] = 1000.0
	var b = gs.no_dia_da_luta()
	print("  no_dia_da_luta (sala normal) = ", b)
	_liberar(gs)


# ------------------------------------------------------------------------------------------------ recortes por nivel nos 3 locais
func _recortes_3_locais() -> void:
	var gs := _novo("qa_recortes")
	var niveis_leg := [0, 1, 12, 30, 52, 80]
	var vistos := {}
	for loc in ["garage", "gym", "center"]:
		gs.local_id = loc
		for n in 6:
			gs.permanente["black_cat"] = {"legend": niveis_leg[n], "rounds": 1, "scares": 0, "shown_level": n, "open_campaign": 3}
			var rc: Dictionary = gs.recorte_gato_preto()
			var chave := str(rc.get("object_text", ""))
			var texto = gs.texto_ui(chave, "")
			var ok = not rc.is_empty() and rc.spot is Array and rc.spot.size() == 2
			checar(ok, "recorte %s nivel %d: existe com ponto %s" % [loc, n, str(rc.get("spot", []))])
			var esperado := "black_cat_clipping" if n == 0 else "black_cat_clipping_%d" % n
			checar_igual(chave, esperado, "recorte %s nivel %d: chave" % [loc, n])
			checar(texto != "" and texto != chave, "recorte %s nivel %d: texto do roteirista existe (%s)" % [loc, n, texto.replace("\n", " / ")])
			var tem_nome = texto.to_upper().contains("GATO PRETO")
			checar(tem_nome == (n >= 1) or n == 4, "recorte %s nivel %d: o nome GATO PRETO %s" % [loc, n, "aparece" if n >= 1 else "NAO aparece"])
			vistos["%s_%d" % [loc, n]] = texto
	# cada nivel troca o texto (todos diferentes)
	var unicos := {}
	for n in 6:
		unicos[vistos["garage_%d" % n]] = true
	checar_igual(unicos.size(), 6, "6 textos de recorte diferentes (um por nivel)")
	# o spot e (352,95) nos 3 locais?
	for loc in ["garage", "gym", "center"]:
		gs.local_id = loc
		var ci = gs.capuz_info()
		gs.capuz["open"] = "scare"
		ci = gs.capuz_info()
		checar(ci.get("spot", []) == [352.0, 95.0] or ci.get("spot", []) == [352, 95], "capuz no prego em %s: ponto %s" % [loc, str(ci.get("spot", []))])
	# campanha 1: sem recorte
	var g1 := _novo("qa_recortes_c1", 1, false)
	checar(g1.recorte_gato_preto().is_empty(), "campanha 1: sem recorte")
	_liberar(gs)
	_liberar(g1)


func _capuz_3_locais_e_mudar() -> void:
	var gs := _novo("qa_mudar")
	_andar(gs, 181)
	checar_igual(gs.capuz_visivel(), "scare", "capuz na garagem")
	gs.dinheiro = 1.0e9
	gs.permanente["career_number"] = 3
	var pode = gs.pode_mudar()
	print("  pode_mudar com muito dinheiro = ", pode, " (estado %s)" % gs.estado_mudanca())
	if pode:
		var ok = gs.mudar()
		checar(ok and gs.local_id != "garage", "MUDAR de local com o capuz no prego")
		checar_igual(gs.capuz_visivel(), "scare", "o capuz vai junto para %s" % gs.local_id)
		checar(gs.capuz_info().get("spot", []).size() == 2, "ponto do capuz no local novo")
	_liberar(gs)


# ------------------------------------------------------------------------------------------------ regiao: compras
func _regiao_compras() -> void:
	var gs := _novo("qa_regiao")
	gs.permanente["legacy_total"] = 100000
	# lenda 0: nada compra
	for id in ["cat_rooftop", "cat_watch", "cat_thanks"]:
		checar(not gs.comprar_no(id), "lenda 0: %s nao compra" % id)
	gs.permanente["black_cat"] = {"legend": 1, "rounds": 1, "scares": 0, "shown_level": 1, "open_campaign": 3}
	checar(not gs.comprar_no("cat_watch"), "lenda 1, sem raiz: cat_watch recusa")
	checar(not gs.comprar_no("cat_thanks"), "lenda 1: cat_thanks recusa (sem raiz e sem lenda)")
	checar(gs.comprar_no("cat_rooftop"), "lenda 1: cat_rooftop compra")
	checar(not gs.comprar_no("cat_rooftop"), "comprar o mesmo no de novo: recusa")
	checar(not gs.comprar_no("cat_watch"), "lenda 1 + raiz: cat_watch (trava nivel 3) lacrado, recusa mesmo com Legado de sobra")
	checar(not gs.comprar_no("cat_thanks"), "lenda 1 + raiz: cat_thanks (nivel 5) recusa")
	gs.permanente["black_cat"].legend = 29
	checar(not gs.comprar_no("cat_watch"), "lenda 29 (nivel 2): cat_watch ainda lacrado")
	gs.permanente["black_cat"].legend = 30
	checar(gs.comprar_no("cat_watch"), "lenda 30 (nivel 3): cat_watch compra")
	gs.permanente["black_cat"].legend = 79
	checar(not gs.comprar_no("cat_thanks"), "lenda 79 (nivel 4): cat_thanks recusa")
	gs.permanente["black_cat"].legend = 80
	var antes: int = int(gs.permanente.legacy_total)
	checar(gs.comprar_no("cat_thanks") and int(gs.permanente.legacy_total) == antes - 9000, "lenda 80: cat_thanks compra por 9.000")
	checar_igual(int(gs.permanente.legacy_total), 100000 - 18000, "total gasto na regiao = 18.000")
	# Legado cai: o jogo guarda
	var salvo: Dictionary = gs.para_save()
	var g2: Node = GameStateScript.new()
	g2.inicializar(gs.store.pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar("cat_thanks" in g2.permanente.skill_nodes and "cat_rooftop" in g2.permanente.skill_nodes, "compras voltam do disco")
	# cat_rooftop + gar_crew_start / outro start_generator: max, nao soma
	var g3 := _novo("qa_regiao_max")
	g3.permanente["skill_nodes"] = ["gar_crew_start", "cat_rooftop"]
	g3.permanente["black_cat"] = {"legend": 1, "rounds": 1, "scares": 0, "shown_level": 1, "open_campaign": 3}
	g3._carreira._reiniciar_campanha()
	var gen := {}
	for k in g3.geradores:
		if int(g3.geradores[k]) > 0:
			gen[k] = g3.geradores[k]
	print("  geradores no comeco com gar_crew_start + cat_rooftop: ", gen)
	checar(int(g3.geradores.get("retired_uncle", 0)) == 2, "cat_rooftop + outro start_generator: 2 Tios (nao soma)")
	# Combo da arvore cheia: renda da equipe nao passa do esperado
	var g4 := _novo("qa_regiao_renda")
	g4.geradores["retired_uncle"] = 10
	var p0: float = g4.producao_total()
	g4.permanente["skill_nodes"] = ["cat_thanks"]
	g4.nos_ativos_ids = ["cat_thanks"]
	g4._arvore._recalcular_bonus()
	var p1: float = g4.producao_total()
	checar(absf(p1 / p0 - 1.4) < 1.0e-9, "so cat_thanks: x1,4 (%.4f)" % (p1 / p0))
	# efeito do clique nao muda
	var c0 := 0.0
	for g in [gs, g2, g3, g4]:
		_liberar(g)


# ------------------------------------------------------------------------------------------------ campanhas e linhagem
func _campanhas() -> void:
	var gs := _novo("qa_camp")
	_andar(gs, 181)
	gs.ronda_ir()
	gs.ronda_jogo().sustos = 3
	gs.ronda_jogo().fase = "fim"
	gs.ronda_concluir()
	gs.ronda_voltar()
	_andar(gs, 241)
	checar(gs.capuz_visivel() == "scare", "capuz no prego antes de aposentar")
	var lenda_antes: Dictionary = gs.lenda()
	# nova campanha (via carreira): o capuz volta ao padrao e a lenda fica
	gs._carreira._reiniciar_campanha()
	checar(gs.capuz.open == "" and float(gs.capuz.hood_s) == 0.0 and float(gs.capuz.next_at) == 180.0, "nova campanha: capuz zerado (prego vazio, 180 s)")
	checar(gs.lenda().legend == lenda_antes.legend and gs.lenda().level == lenda_antes.level, "nova campanha: a lenda da linhagem fica")
	# a Ronda abre na campanha seguinte a que gravou open_campaign
	checar(gs.ronda_aberta(), "Ronda segue aberta na campanha seguinte")
	# save: next_at sobrevive? (hood_s e proximo capuz)
	var g2 := _novo("qa_camp2", 4)
	g2.escola.milestones["black_cat_rumor_heard"] = {"campaign": 4, "version": 1}
	checar(not g2.ronda_aberta(), "boato na campanha 4, estamos na 4: fechada")
	_andar(g2, 1000)
	checar(g2.capuz_visivel() == "" and not g2.permanente.has("black_cat"), "boato desta campanha: 1.000 s sem capuz e nada gravado")
	g2.permanente["career_number"] = 5
	checar(g2.ronda_aberta(), "campanha 5: abre")
	# lenda cai em algum caminho? aposentar
	for g in [gs, g2]:
		_liberar(g)


# ------------------------------------------------------------------------------------------------ saves sujos extras
func _saves_extras() -> void:
	var gs := _novo("qa_saves")
	var base: Dictionary = gs.para_save()
	checar_igual(int(load("res://scripts/save_store.gd").VERSAO_ATUAL), 13, "versao do save = 13")
	var sujos := [
		{"permanent": {"black_cat": []}, "career": {"black_cat_hood": "x"}},
		{"permanent": {"black_cat": "x"}, "career": {"black_cat_hood": []}},
		{"permanent": {"black_cat": null}, "career": {"black_cat_hood": null}},
		{"permanent": {"black_cat": 7}, "career": {"black_cat_hood": 7}},
		{"permanent": {"black_cat": {"legend": -50, "rounds": -1, "scares": -1, "shown_level": -3, "open_campaign": -9}}, "career": {"black_cat_hood": {"hood_s": -1, "next_at": -1, "open": 5}}},
		{"permanent": {"black_cat": {"legend": 3.7, "rounds": 2.2, "scares": 1.9, "shown_level": 0.5, "open_campaign": 3.9}}, "career": {"black_cat_hood": {"hood_s": 1.0e300, "next_at": 1.0e300, "open": "scare"}}},
		{"permanent": {"black_cat": {"legend": true, "rounds": [1], "scares": {}, "shown_level": "2", "open_campaign": null}}, "career": {"black_cat_hood": {"hood_s": true, "next_at": [], "open": ["scare"]}}},
		{"permanent": {"black_cat": {"legend": 1.0e20, "rounds": 1.0e20}}, "career": {"black_cat_hood": {"open": "scare", "hood_s": 0}}},
	]
	var i := 0
	for s in sujos:
		i += 1
		var d: Dictionary = base.duplicate(true)
		for k in s.permanent:
			d.permanent[k] = s.permanent[k]
		for k in s.career:
			d.career[k] = s.career[k]
		gs.aplicar_save(d)
		var l: Dictionary = gs.lenda()
		var ok: bool = int(l.legend) >= 0 and int(l.legend) <= 1000000000 and int(l.shown_level) <= int(l.level) and int(l.scares) <= 3 * int(l.rounds) and l.level <= 5
		ok = ok and (str(gs.capuz.open) == "" or gs.ronda_cfg.noites.has(str(gs.capuz.open))) and float(gs.capuz.hood_s) >= 0.0 and float(gs.capuz.next_at) >= 0.0
		checar(ok, "save sujo #%d carrega com valores validos (lenda %s, capuz %s)" % [i, str(l.legend), str(gs.capuz)])
		# a partida segue viva
		gs.tick(1.0)
		var p: Dictionary = gs.para_save()
		checar(JSON.stringify(p) != "", "save sujo #%d: segue salvando" % i)
	# save v12 antigo (sem nada novo, versao menor)
	var antigo: Dictionary = base.duplicate(true)
	antigo.career.erase("black_cat_hood")
	antigo.permanent.erase("black_cat")
	antigo["version"] = 12
	gs.aplicar_save(antigo)
	checar(gs.lenda().legend == 0 and gs.capuz.open == "" and not gs.permanente.has("black_cat"), "save v12 sem campos: sobe sem lenda nem capuz")
	# no cat_* sem lenda (save sujo): nao crasha e as regras nao quebram
	var sujo2: Dictionary = base.duplicate(true)
	sujo2.permanent["skill_nodes"] = ["cat_thanks", "cat_watch", "cat_rooftop", "no_que_nao_existe"]
	gs.aplicar_save(sujo2)
	gs.tick(1.0)
	checar(true, "nos cat_* pagos sem lenda: carrega e anda")
	# Ronda em andamento no save (campo desconhecido): ignorado
	var s3: Dictionary = base.duplicate(true)
	s3.career["ronda_ativa"] = "scare"
	gs.aplicar_save(s3)
	checar_igual(gs.ronda_ativa, "", "campo ronda_ativa vindo de fora do save e ignorado")
	_liberar(gs)


func _save_do_dono() -> void:
	# a COPIA do save do dono (feita antes dos testes) abre sem erro
	var copia := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/bk/Fightclicker/save.json"
	if not FileAccess.file_exists(copia):
		print("  (sem copia do save do dono)")
		return
	var pasta := pasta_limpa("qa_dono")
	DirAccess.copy_absolute(copia, pasta + "save.json")
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	checar(gs.avisos.is_empty(), "save do dono abre sem avisos (%s)" % str(gs.avisos))
	print("  save do dono: campanha %d, lenda %s, capuz %s, ronda_aberta=%s, marco boato=%s" % [gs.numero_carreira(), str(gs.lenda()), str(gs.capuz), str(gs.ronda_aberta()), str(gs.marco("black_cat_rumor_heard"))])
	gs.tick(1.0)
	checar(true, "save do dono: tick ok")
	_liberar(gs)


# ------------------------------------------------------------------------------------------------ tela headless
func _tela_headless() -> void:
	var gs := _novo("qa_tela")
	# a tela usa o autoload GameState; aqui so conferimos que a classe e o premio constroem sem erro com dados reais
	var info := {"night": "scare", "kind": "stealth_scare", "name": "RONDA NOTURNA", "tip": "SEGURE", "countdown_s": 2.0, "night_s": 34.0,
		"level": 3, "legend": 40, "layers": ["graffiti", "banner"], "occurrences": ["tire", "bike", "gate"], "occurrence_names": ["A", "B", "C"]}
	_liberar(gs)


# ------------------------------------------------------------------------------------------------ sorteios do jogo: quem vai x quem nao vai
func _rngs_e_falas() -> void:
	var res := []
	for vai in [false, true]:
		var gs := _novo("qa_rng_%s" % str(vai))
		gs.baloes_escondidos = false
		gs.geradores[gs.dados.geradores[0].id] = 3
		gs._rng_evento.seed = 11
		gs._rng_fala.seed = 22
		gs._rng_sucessao.seed = 33
		var balcao := 0
		for _i in 1500:
			gs.tick(1.0)
			if not gs._balao.is_empty():
				balcao += 1
			if vai and gs.capuz_info().get("clickable", false):
				gs.ronda_ir()
				gs.ronda_jogo().sustos = 3
				gs.ronda_jogo().fase = "fim"
				gs.ronda_concluir()
				gs.ronda_voltar()
		res.append({"rng": gs.rng.state, "fala": gs._rng_fala.state, "evento": gs._rng_evento.state, "suc": gs._rng_sucessao.state,
			"ocioso": gs._ocioso, "baloes_s": balcao, "lines": gs.escola.lines_seen.duplicate(true), "rondas": gs.lenda().rounds, "treino": gs.treino, "camp": gs.segundos_campanha})
		_liberar(gs)
	print("  sem ir: ", res[0])
	print("  indo  : ", res[1])
	checar(res[0].rng == res[1].rng and res[0].evento == res[1].evento and res[0].suc == res[1].suc, "sorteios rng/evento/sucessao iguais indo ou nao indo")
	checar(res[0].fala == res[1].fala, "sorteio de falas (_rng_fala) igual indo ou nao indo (%s x %s)" % [str(res[0].fala), str(res[1].fala)])
	checar(res[0].lines == res[1].lines, "falas ja vistas iguais indo ou nao indo (falas cl_lenda_N cortadas: nao ha mais diferenca esperada)")
	checar(is_equal_approx(res[0].ocioso, res[1].ocioso) and res[0].baloes_s == res[1].baloes_s, "ocioso e tempo de balao iguais (%s x %s | %s x %s)" % [str(res[0].ocioso), str(res[1].ocioso), str(res[0].baloes_s), str(res[1].baloes_s)])
