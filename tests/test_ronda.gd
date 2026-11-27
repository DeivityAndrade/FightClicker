extends "res://tests/test_base.gd"
## Ronda Noturna do Gato Preto: minigame (casos exatos de tests/data/ronda_casos.json), lenda e níveis, capuz (abertura, relógio,
## não acumula, nunca em janela/fala), congelamento, gravação só no fim/SAIR, região GATO PRETO (travas, lacrado, 3 efeitos),
## "quem não joga = igual" e saves antigos/sujos. Referência: tools/sim/ronda_sim.py e docs/fases/ronda-design.md.
## Tudo em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")
const CASOS := "res://tests/data/ronda_casos.json"
const EVENTOS_DO_SIM := ["aviso", "aviso_falso", "visto", "susto", "fim", "fim_tempo"]

var casos: Dictionary


func rodar_testes() -> void:
	casos = JSON.parse_string(ler(CASOS))
	_teste_dados()
	_teste_minigame_casos()
	_teste_minigame_regras()
	_teste_abertura()
	_teste_capuz_regras()
	_teste_relogio_casos()
	_teste_congelamento()
	_teste_concluir_e_sair()
	_teste_fechar_no_meio()
	_teste_arvore()
	_teste_efeitos()
	_teste_saves()
	_teste_quem_nao_joga()
	_teste_hitch_longo()


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
	if com_marco:
		gs.escola.milestones["black_cat_rumor_heard"] = {"campaign": campanha - 1, "version": 1}
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


## Anda `s` segundos de sala, de 1 em 1 s.
func _andar(gs: Node, s: int, passo: float = 1.0) -> void:
	for _i in s:
		gs.tick(passo)


func _noite(gs: Node) -> Dictionary:
	return gs.ronda_cfg.noites["scare"]


## Intervalo do capuz e limiares da lenda: sempre lidos do ronda.json (2a2: nada de 240 nem de limiares no teste).
func _iv(gs: Node) -> int:
	return int(gs.ronda_cfg.capuz.interval_s)


func _lv(gs: Node, i: int) -> int:
	return int(gs.ronda_cfg.niveis[i])


# ---------------------------------------------------------------- dados
func _teste_dados() -> void:
	var gs := _novo("ronda_dados")
	checar(not gs.ronda_cfg.vazio and gs.ronda_cfg.noites.has("scare"), "ronda.json lido (noite scare)")
	var iguais: bool = gs.ronda_cfg.niveis.size() == casos.levels.size()
	for i in mini(gs.ronda_cfg.niveis.size(), casos.levels.size()):
		iguais = iguais and int(gs.ronda_cfg.niveis[i]) == int(casos.levels[i])
	checar(iguais and gs.ronda_cfg.niveis.size() == 5, "niveis da lenda = os dos casos (ronda.json)")
	checar_igual(int(gs.ronda_cfg.capuz.interval_s), 300, "capuz a cada 300 s (2a2)")
	checar_igual(int(gs.ronda_cfg.capuz.first_after_s), 180, "1o capuz aos 180 s")
	checar(gs.ronda_cfg.avisos.is_empty(), "ronda.json sem avisos do validador")
	var ok := true
	for l in 81:
		ok = ok and gs.ronda_cfg.nivel_de(l) == int(casos.nivel[l])
	checar(ok, "nivel da lenda 0..80 bate com os casos (e com o simulador)")
	for id in casos.nos:
		var n: Dictionary = gs.lutas.no_da_arvore(str(id))
		checar_igual(int(n.get("cost", -1)), int(casos.nos[id].cost), "custo do no %s" % id)
		checar_igual(str(n.get("lock", "")), str(casos.nos[id].lock), "trava do no %s" % id)
		checar_igual(str(n.get("effect_type", "")), str(casos.nos[id].effect.type), "efeito do no %s" % id)
	var d := DialogosData.carregar()
	checar(d.erros.is_empty(), "DialogosData.carregar() sem erros (%s)" % str(d.erros))
	checar(d.gatilho("legend_level_up").is_empty() and d.linha("cl_lenda_1").is_empty(), "sem falas do Osmar sobre a lenda (cortadas, vao para a Ronda 2)")
	# dado ruim: noite com kind desconhecido sai com aviso
	var ruim := RondaData.new()
	ruim._ler({"night_order": ["x"], "nights": {"x": {"kind": "bandidos", "occurrences": [{"id": "a"}]}}})
	checar(ruim.vazio and not ruim.avisos.is_empty(), "noite com kind desconhecido: ignorada com aviso")
	checar(RondaData.carregar("res://nao/existe.json").vazio, "arquivo ausente = sem Ronda")
	_liberar(gs)


# ---------------------------------------------------------------- minigame: casos exatos
func _roteiro(cfg: Dictionary, ciclos: Array, entradas: Array, dt: float) -> RondaLogica:
	var r := RondaLogica.new(cfg, null, ciclos.duplicate(true))
	var t := 0.0
	var passos := 0
	while r.fase != "fim" and passos < 100000:
		var seg := false
		var ap := false
		for e in entradas:
			if e.size() == 3 and float(e[0]) - 1.0e-9 <= t and t < float(e[1]) - 1.0e-9:
				seg = true
			if e.size() == 2 and t - 1.0e-9 <= float(e[0]) and float(e[0]) < t + dt - 1.0e-9:
				ap = true
		r.passo(dt, seg and not ap, ap)
		t += dt
		passos += 1
	r.set_meta("passos", passos)
	return r


func _teste_minigame_casos() -> void:
	var gs := _novo("ronda_casos")
	var cfg := _noite(gs)
	var dt := float(casos.dt)
	for nome in casos.minigame:
		var esp: Dictionary = casos.minigame[nome].esperado
		var r := _roteiro(cfg, casos.ciclos, casos.minigame[nome].entradas, dt)
		checar_igual(r.sustos, int(esp.sustos), "%s: sustos" % nome)
		checar_igual(r.vistos, int(esp.vistos), "%s: vistos" % nome)
		checar_igual(r.lenda(), int(esp.lenda), "%s: lenda" % nome)
		checar_igual(int(r.get_meta("passos")), int(esp.passos), "%s: passos" % nome)
		var obt: Array = r.historico.filter(func(e): return str(e[0]) in EVENTOS_DO_SIM)
		var ok: bool = obt.size() == esp.eventos.size()
		for i in mini(obt.size(), esp.eventos.size()):
			ok = ok and str(obt[i][0]) == str(esp.eventos[i][0]) and int(obt[i][1]) == int(esp.eventos[i][1]) and absf(float(obt[i][2]) - float(esp.eventos[i][2])) < 1.0e-6
		checar(ok, "%s: eventos (%d) batem com o simulador" % [nome, obt.size()])
	for s in casos.lenda_da_ronda.size():
		var r := RondaLogica.new(cfg, null, casos.ciclos.duplicate(true))
		r.sustos = s
		checar_igual(r.lenda(), int(casos.lenda_da_ronda[s]), "lenda da ronda com %d sustos" % s)
	_liberar(gs)


func _teste_minigame_regras() -> void:
	var gs := _novo("ronda_regras")
	var cfg := _noite(gs)
	var dt := 1.0 / 16.0
	# gancho de tipo de noite: a lógica nasce do bloco `kind` (hoje só stealth_scare)
	checar_igual(str(cfg.kind), "stealth_scare", "noite scare = kind stealth_scare")
	# contagem e intro: segurar ainda nao anda
	var r := RondaLogica.new(cfg, null, casos.ciclos.duplicate(true))
	checar_igual(r.estado().fase, "contagem", "comeca na contagem")
	for _i in 32:
		r.passo(dt, true, false)
	checar_igual(r.estado().fase, "jogando", "2 s depois: jogando")
	r.passo(dt, true, false)
	checar_igual(r.estado().distancia, 0.0, "no intro segurar nao anda")
	for _i in 13:
		r.passo(dt, true, false)
	checar(r.estado().distancia > 0.0, "depois do intro, segurar anda")
	# tolerancia de 0,2 s: o ladrao comeca a olhar, mas andar nos primeiros 0,2 s ainda nao e visto (caso mexe_na_tolerancia)
	# estatua: soltar congela e nunca e visto
	var p := RondaLogica.new(cfg, null, casos.ciclos.duplicate(true))
	for _i in 600:
		p.passo(dt, false, false)
	checar_igual(p.vistos, 0, "parado nunca e visto")
	# SAIR: o piso vale, bonus de ronda limpa so com os 3
	var s := RondaLogica.new(cfg, null, casos.ciclos.duplicate(true))
	s.sair()
	checar(s.saiu and s.fase == "fim" and s.lenda() == 1, "SAIR na hora = piso 1")
	var s2 := RondaLogica.new(cfg, null, casos.ciclos.duplicate(true))
	s2.sustos = 2
	s2.sair()
	checar_igual(s2.lenda(), 3, "SAIR com 2 sustos = 3 (sem bonus)")
	# aviso falso (3a ocorrencia): sorteio na criacao, mesma semente = mesma lista
	var a := RandomNumberGenerator.new()
	a.seed = 7
	var b := RandomNumberGenerator.new()
	b.seed = 7
	var ra := RondaLogica.new(cfg, a)
	var rb := RondaLogica.new(cfg, b)
	checar_igual(ra._ciclos, rb._ciclos, "mesma semente = mesmos ciclos do ladrao")
	var fakes := 0
	for c in ra._ciclos[2]:
		fakes += 1 if c[1] else 0
	checar(fakes > 0 and ra._ciclos[0].all(func(c): return not c[1]), "so o portao tem aviso falso")
	# avancar(): UI manda apertar/soltar, tick fatia o quadro
	var u := RondaLogica.new(cfg, null, casos.ciclos.duplicate(true))
	u.avancar(2.1)
	checar_igual(u.estado().fase, "jogando", "avancar passa a contagem")
	u.avancar(1.0)
	u.apertar()
	u.avancar(1.0)
	checar(u.estado().distancia > 0.0 and u.estado().segurando, "apertar + avancar = anda")
	u.soltar()
	var d1: float = u.estado().distancia
	u.avancar(1.0)
	checar_igual(u.estado().distancia, d1, "soltar congela")
	_liberar(gs)


# ---------------------------------------------------------------- abertura e capuz
func _teste_abertura() -> void:
	var gs := _novo("ronda_abertura", 1, false)
	for camp in [1, 2, 3, 4]:
		gs.permanente["career_number"] = camp
		checar(not gs.ronda_aberta(), "sem boato: campanha %d sem Ronda" % camp)
	gs.permanente["career_number"] = 5
	checar(gs.ronda_aberta(), "sem boato: a rede de seguranca abre na campanha 5")
	var g2 := _novo("ronda_abertura2", 2, false)
	g2.escola.milestones["black_cat_rumor_heard"] = {"campaign": 2, "version": 1}
	checar(not g2.ronda_aberta(), "boato na campanha 2 (campanha 2): ainda fechada")
	g2.permanente["career_number"] = 3
	checar(g2.ronda_aberta(), "boato na campanha 2: abre na 3")
	var g3 := _novo("ronda_abertura3", 3, false)
	g3.escola.milestones["black_cat_rumor_heard"] = {"campaign": 3, "version": 1}
	checar(not g3.ronda_aberta(), "boato na campanha 3: a campanha 3 nao abre")
	g3.permanente["career_number"] = 4
	checar(g3.ronda_aberta(), "boato na campanha 3: abre na 4")
	var g4 := _novo("ronda_abertura4", 3, false)
	g4.escola.milestones["black_cat_rumor_heard"] = {"version": 1}
	checar(g4.ronda_aberta(), "marco sem campanha (save antigo): abre ja")
	g4.escola.milestones["black_cat_rumor_heard"] = {"campaign": "x"}
	checar(g4.ronda_aberta(), "marco com campanha invalida: abre ja")
	var g5 := _novo("ronda_abertura5", 2, false)
	g5.escola.milestones["black_cat_rumor_heard"] = {"campaign": 1, "version": 1}
	checar(not g5.ronda_aberta(), "minimo 3: a campanha 2 nunca ve o capuz")
	# a 1a carreira e quem nao tem o marco nunca veem o capuz ao longo do tempo
	var g6 := _novo("ronda_abertura6", 1, true)
	_andar(g6, 1500)
	checar(g6.capuz_visivel() == "" and not g6.permanente.has("black_cat"), "campanha 1: nenhum capuz em 1.500 s e nada gravado")
	var g7 := _novo("ronda_abertura7", 3, false)
	_andar(g7, 1500)
	checar(g7.capuz_visivel() == "", "sem o marco (campanha 3): nenhum capuz")
	var salvo: Dictionary = g7.para_save()
	checar(not salvo.career.has("black_cat_hood") and not salvo.permanent.has("black_cat"), "Ronda fechada: save sem os campos novos")
	for g in [gs, g2, g3, g4, g5, g6, g7]:
		_liberar(g)


func _teste_capuz_regras() -> void:
	var gs := _novo("ronda_capuz")
	checar(gs.ronda_aberta() and gs.capuz_visivel() == "", "aberta e sem capuz no comeco")
	_andar(gs, 179)
	checar_igual(gs.capuz_visivel(), "", "aos 179 s: ainda nao")
	_andar(gs, 1)
	checar_igual(gs.capuz_visivel(), "scare", "aos 180 s: o capuz traz a noite scare")
	var info: Dictionary = gs.capuz_info()
	checar(info.clickable and str(info.hover_text) == "SAIR DE NOITE?" and str(info.night) == "scare", "capuz clicavel com o hover do roteirista")
	# nao acumula nem some: 2.000 s parado, ainda 1 so
	var h: float = gs.capuz.hood_s
	_andar(gs, 2000)
	checar(gs.capuz_visivel() == "scare" and gs.capuz.hood_s > h, "capuz parado no prego nao some (e o relogio segue)")
	# janela aberta: continua no prego, sem clique
	gs.modal_aberto = true
	checar(gs.capuz_visivel() == "scare" and not gs.capuz_info().clickable and gs.ronda_ir().is_empty(), "janela aberta: sem clique, ronda_ir recusa")
	gs.modal_aberto = false
	gs._balao = {"id": "x", "ate": 1.0e9}
	checar(not gs.capuz_info().clickable and gs.ronda_ir().is_empty(), "balao de fala na sala: sem clique")
	gs._balao = {}
	gs.luta = {"x": 1}
	checar(gs.ronda_ir().is_empty(), "luta pendente: sem clique")
	gs.luta = {}
	checar(gs.capuz_info().clickable, "tudo livre: clicavel de novo")
	# nao abre sozinha: so o clique
	checar_igual(gs.ronda_ativa, "", "a Ronda nunca abre sozinha")
	_liberar(gs)
	# o capuz nao aparece com janela/balao/dia: tempo de sala nao anda e a vaga espera
	var g2 := _novo("ronda_capuz2")
	g2.capuz["hood_s"] = 500.0
	g2.modal_aberto = true
	_andar(g2, 30)
	checar(g2.capuz_visivel() == "" and float(g2.capuz.hood_s) == 500.0, "janela aberta: o relogio do capuz nao anda e nada aparece")
	g2.modal_aberto = false
	g2._balao = {"id": "x", "ate": 1.0e9}
	_andar(g2, 5)
	checar_igual(g2.capuz_visivel(), "", "balao de fala: o capuz espera")
	g2._balao = {}
	_andar(g2, 1)
	checar_igual(g2.capuz_visivel(), "scare", "balao acabou: aparece no 1o quadro em que tudo vale")
	# o relogio do convite do Osmar nao anda com a Ronda e a Ronda nao toca no rng do jogo
	_liberar(g2)


func _teste_relogio_casos() -> void:
	var gs := _novo("ronda_relogio")
	var marcos: Array = []
	for k in casos.rondas:
		marcos.append(int(k))
	marcos.sort()
	var rondas := 0
	var s := 0
	var ok := true
	for alvo in marcos:
		while s < alvo:
			gs.tick(1.0)
			s += 1
			if gs.capuz_info().get("clickable", false):
				gs.ronda_ir()
				gs.ronda_concluir()
				gs.ronda_voltar()
				rondas += 1
		var esp: int = int(casos.rondas[str(alvo)])
		if rondas != esp:
			ok = false
			print("  rondas em %d s: %d (esperado %d)" % [alvo, rondas, esp])
	checar(ok, "capuzes por campanha (indo na hora) batem com o simulador em 11 marcos de tempo")
	checar_igual(int(gs.lenda().rounds), rondas, "rounds da linhagem = rondas feitas")
	checar_igual(int(gs.lenda().legend), rondas, "SAIR na hora: 1 de lenda por ronda")
	_liberar(gs)


# ---------------------------------------------------------------- congelamento
func _teste_congelamento() -> void:
	var gs := _novo("ronda_congela")
	gs.geradores[gs.dados.geradores[0].id] = 5
	_andar(gs, 181)
	checar(gs.capuz_info().clickable, "capuz pronto")
	var antes := {"treino": gs.treino, "camp": gs.segundos_campanha, "jogo": gs.tempo_jogo, "hood": float(gs.capuz.hood_s),
		"conv": float(gs.convite.room_s), "din": gs.dinheiro, "ativ": gs.sala_ativa()}
	checar(antes.ativ and antes.treino > 0.0, "antes: sala ativa e a equipe produzia")
	var salvo_antes: String = JSON.stringify(gs.para_save(), "", true)
	var info: Dictionary = gs.ronda_ir()
	checar(not info.is_empty() and str(info.kind) == "stealth_scare" and info.occurrences == ["tire", "bike", "gate"], "ronda_ir devolve a noite e as 3 ocorrencias")
	checar(float(info.countdown_s) == 2.0 and float(info.night_s) == 34.0 and int(info.level) == 0, "ronda_ir: tempos e nivel 0")
	checar(str(info.tip) != "" and not str(info.name).contains("GATO"), "ronda_ir: instrucao e titulo sem o nome GATO PRETO no nivel 0")
	checar(not gs.sala_ativa() and gs.ronda_ativa == "scare" and gs.capuz_visivel() == "", "Ronda: sala inativa e capuz some da vista")
	checar_igual(JSON.stringify(gs.para_save(), "", true), salvo_antes, "IR nao grava nada: o save continua com o capuz no prego")
	_andar(gs, 200, 0.1)
	checar(gs.treino == antes.treino and gs.segundos_campanha == antes.camp and gs.tempo_jogo == antes.jogo and gs.dinheiro == antes.din, "20 s de Ronda: treino, relogio, tempo de jogo e dinheiro parados")
	checar(float(gs.capuz.hood_s) == antes.hood and float(gs.convite.room_s) == antes.conv, "relogio do capuz e do convite parados")
	checar(gs.ronda_jogo().estado().fase == "jogando" or gs.ronda_jogo().fase == "fim", "so a noite anda")
	# nada gravado ate agora
	checar(int(gs.lenda().rounds) == 0 and not gs.permanente.has("black_cat") or int(gs.permanente.black_cat.rounds) == 0, "no meio da Ronda: lenda intocada")
	gs.ronda_concluir()
	gs.ronda_voltar()
	checar(gs.sala_ativa() and gs.ronda_ativa == "", "VOLTAR devolve a sala")
	_liberar(gs)


# ---------------------------------------------------------------- fim e SAIR
func _teste_concluir_e_sair() -> void:
	var gs := _novo("ronda_concluir")
	_andar(gs, 180)
	var hood: float = gs.capuz.hood_s
	gs.ronda_ir()
	var j: RondaLogica = gs.ronda_jogo()
	j.sustos = 3
	j.fase = "fim"
	var p: Dictionary = gs.ronda_concluir()
	checar(p.legend_gain == 5 and p.clean and p.scares == 3 and p.left == 0, "3 sustos: +5 de lenda, ronda limpa")
	checar(p.level == 1 and p.level_before == 0 and p.level_up and str(p.level_up_line) != "" and str(p.clipping_text).contains("GATO PRETO"), "subiu ao nivel 1 com a manchete que da o nome")
	checar(str(p.line) != "" and p.ended == "all", "linha de premio pela contagem de sustos")
	var l: Dictionary = gs.lenda()
	checar(l.legend == 5 and l.rounds == 1 and l.scares == 3 and l.level == 1 and l.shown_level == 1 and l.next_level_at == _lv(gs, 1), "lenda da linhagem gravada")
	checar(gs.capuz.open == "" and absf(float(gs.capuz.next_at) - (hood + float(_iv(gs)))) < 1.0e-6, "prego vazio e proximo capuz a +intervalo da volta")
	checar(gs.ronda_concluir() == p, "concluir de novo devolve o mesmo premio")
	checar_igual(gs.recorte_gato_preto().get("object_text", "black_cat_clipping_1") if not gs.recorte_gato_preto().is_empty() else "black_cat_clipping_1", "black_cat_clipping_1", "recorte pelo nivel (chave da manchete 1)")
	checar_igual(gs._ronda.chave_recorte(), "black_cat_clipping_1", "chave do recorte no nivel 1")
	# a gravacao foi uma so e ja esta no disco
	var salvo: Dictionary = gs.para_save()
	checar(salvo.permanent.black_cat.legend == 5 and salvo.career.black_cat_hood.open == "", "save com lenda e prego vazio")
	gs.ronda_voltar()
	# SAIR: piso + sustos feitos, sem bonus
	_andar(gs, _iv(gs) - 1)
	checar(not gs.capuz_info().get("clickable", false), "1 s antes do intervalo: sem capuz")
	_andar(gs, 1)
	checar(gs.capuz_info().get("clickable", false), "proximo capuz um intervalo depois da volta")
	gs.ronda_ir()
	gs.ronda_jogo().sustos = 2
	var q: Dictionary = gs.ronda_concluir()
	checar(q.legend_gain == 3 and not q.clean and q.ended == "exit" and q.left == 1 and not q.level_up, "SAIR com 2 sustos: +3, sem bonus, sem subida")
	checar(str(q.line) == gs.texto_ui("ronda_left_line"), "SAIR usa a linha ronda_left_line")
	gs.ronda_voltar()
	# lenda so cresce; nivel 5 acima: ronda_count so no maximo
	gs.permanente["black_cat"].legend = _lv(gs, 4) - 1
	_andar(gs, _iv(gs))
	gs.ronda_ir()
	gs.ronda_jogo().sustos = 3
	gs.ronda_jogo().fase = "fim"
	var r5: Dictionary = gs.ronda_concluir()
	checar(r5.level == 5 and r5.max_level and r5.level_up, "nivel 5 alcancado")
	gs.ronda_voltar()
	_andar(gs, _iv(gs))
	gs.ronda_ir()
	gs.ronda_jogo().sair()
	var r6: Dictionary = gs.ronda_concluir()
	checar(not r6.level_up and r6.max_level and gs.lenda().legend > _lv(gs, 4) and gs.lenda().next_level_at == 0, "depois do nivel 5: segue contando, sem aviso novo")
	_liberar(gs)


func _teste_fechar_no_meio() -> void:
	var gs := _novo("ronda_meio")
	_andar(gs, 180)
	gs.ronda_ir()
	_andar(gs, 100, 0.1)
	gs.salvar()  # o autosave pode gravar no meio da Ronda
	var pasta: String = gs.store.pasta
	var lenda_antes: Dictionary = gs.lenda()
	gs.ronda_jogo().sustos = 2
	var g2: Node = GameStateScript.new()
	g2.inicializar(pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar(g2.ronda_ativa == "" and g2.sala_ativa() == g2.sala_ativa(), "reabrir: na sala, sem Ronda em andamento")
	checar(g2.lenda() == lenda_antes and g2.capuz.open == "scare", "fechar no meio: nao da nem tira lenda e o capuz segue no prego")
	checar(int(g2.permanente.get("black_cat", {}).get("rounds", 0)) == 0, "nada de ronda contada")
	_liberar(gs)
	_liberar(g2)


# ---------------------------------------------------------------- arvore
func _teste_arvore() -> void:
	var gs := _novo("ronda_arvore")
	gs.permanente["legacy_total"] = 30000
	var ids := ["cat_rooftop", "cat_watch", "cat_thanks"]
	checar(ids.all(func(i): return not gs.lutas.no_da_arvore(i).is_empty()), "3 nos do GATO PRETO na arvore")
	checar(not gs.lutas.regiao("black_cat").is_empty(), "regiao black_cat")
	checar("cat_rooftop" in gs.lutas.no_da_arvore("camp_extra_day").neighbors, "cat_rooftop liga em camp_extra_day")
	for i in ids:
		checar_igual(gs.estado_mapa(i), "hidden", "lenda 0: %s escondido" % i)
	checar(not gs.arvore_mapa_info().regions.filter(func(r): return r.id == "black_cat")[0].open, "regiao fechada com lenda 0")
	gs.permanente["black_cat"] = {"legend": 1, "rounds": 1, "scares": 0, "shown_level": 1, "open_campaign": 3}
	checar_igual(gs.estado_mapa("cat_rooftop"), "visible", "lenda 1: raiz a vista")
	checar_igual(gs.estado_mapa("cat_watch"), "hidden", "lenda 1: vizinho sem o raiz comprado escondido")
	checar(gs.arvore_mapa_info().regions.filter(func(r): return r.id == "black_cat")[0].open, "regiao aberta com a lenda no nivel 1")
	# o raiz precisa de um vizinho comprado (camp_extra_day) ou ser raiz: e raiz
	gs.permanente["skill_nodes"] = ["cat_rooftop"]
	checar_igual(gs.estado_mapa("cat_watch"), "sealed", "lenda 1 + raiz comprado: cat_watch lacrado")
	checar_igual(gs.estado_mapa("cat_thanks"), "sealed", "lenda 1: cat_thanks lacrado")
	checar_igual(gs.estado_no("cat_watch"), "locked", "aba antiga: lacrado = trancado")
	var item: Dictionary = gs.arvore_mapa().filter(func(n): return n.id == "cat_watch")[0]
	checar(item.state == "sealed" and str(item.sealed_text) == "PRECISA DA LENDA NÍVEL 3" and str(item.sealed_name) == "???" and not item.can_buy, "mapa: lacrado com titulo e subtitulo do roteirista, sem compra")
	gs.permanente["black_cat"].legend = _lv(gs, 2)
	checar_igual(gs.estado_mapa("cat_watch"), "visible", "lenda nivel 3: cat_watch abre")
	checar_igual(gs.estado_mapa("cat_thanks"), "sealed", "lenda nivel 3: cat_thanks segue lacrado")
	gs.permanente["black_cat"].legend = _lv(gs, 4)
	checar_igual(gs.estado_mapa("cat_thanks"), "visible", "lenda nivel 5: cat_thanks abre")
	# compra: gasta Legado exato; Legado insuficiente recusa
	gs.permanente["skill_nodes"] = []
	gs.permanente["legacy_total"] = 2999
	checar(not gs.comprar_no("cat_rooftop"), "2.999 de Legado: nao compra")
	gs.permanente["legacy_total"] = 3000
	checar(gs.comprar_no("cat_rooftop") and gs.permanente.legacy_total == 0, "3.000: compra e zera")
	checar_igual(gs.texto_efeito_no(gs.lutas.no_da_arvore("cat_rooftop")), "COMEÇA A CAMPANHA COM 2 TIOS NA EQUIPE", "texto do efeito do Atalho")
	checar_igual(gs.texto_efeito_no(gs.lutas.no_da_arvore("cat_thanks")), "+20% TREINO/S DA EQUIPE", "texto do efeito da equipe")
	_liberar(gs)


func _teste_efeitos() -> void:
	var gs := _novo("ronda_efeitos")
	var i_kid: int = gs.lutas.indice_do_kid()
	var i_liga: int = i_kid + 1
	checar(str(gs.lutas.adversarios[i_liga].get("league", "")) != "" and str(gs.lutas.adversarios[i_kid].get("league", "")) == "", "indices: Kid sem liga, o seguinte na liga")
	var base_kid: int = gs._calendario._prep_do_indice(i_kid)
	var base_liga: int = gs._calendario._prep_do_indice(i_liga)
	var base_gym: int = gs._calendario._prep_do_indice(0)
	gs.nos_ativos_ids = ["cat_watch"]
	gs._arvore._recalcular_bonus()
	checar_igual(gs._calendario._prep_do_indice(i_liga), base_liga + 2, "cat_watch: +2 dias nas lutas da liga")
	checar(gs._calendario._prep_do_indice(i_kid) == base_kid and gs._calendario._prep_do_indice(0) == base_gym, "cat_watch: o resto das lutas nao muda")
	for i in range(i_liga, gs.lutas.adversarios.size()):
		checar_igual(gs._calendario._prep_do_indice(i), int(gs.lutas.adversarios[i].prep_days) + 2, "liga %d: +2" % i)
	# soma com o 'Um dia a mais' (prep_days_bonus) sem se confundir
	gs.nos_ativos_ids = ["cat_watch", "camp_extra_day"]
	gs._arvore._recalcular_bonus()
	checar_igual(gs._calendario._prep_do_indice(i_liga), base_liga + 3, "cat_watch + Um dia a mais: +3 na liga")
	checar_igual(gs._calendario._prep_do_indice(i_kid), base_kid + 1, "Um dia a mais continua valendo em todas")
	# 2 Tios no comeco da campanha (max, nao soma)
	gs.permanente["skill_nodes"] = ["cat_rooftop"]
	gs._carreira._reiniciar_campanha()
	checar_igual(int(gs.geradores.get("retired_uncle", 0)), 2, "cat_rooftop: campanha comeca com 2 Tios")
	checar(gs.treino == 0.0 and gs.dinheiro == 0.0, "so a equipe: nada de dinheiro nem treino de graca")
	# +20% de equipe (passive_bonus; corte aprovado pelo dono na 2a1: era +40%)
	var sem: float = gs.producao_total()
	gs.geradores["retired_uncle"] = 10
	var p0: float = gs.producao_total()
	gs.nos_ativos_ids = ["cat_thanks"]
	gs._arvore._recalcular_bonus()
	var p1: float = gs.producao_total()
	checar(absf(p1 / p0 - 1.2) < 1.0e-9 and sem >= 0.0, "cat_thanks: equipe +20%%")
	# nao mexe na chance de luta: o bonus novo nao existe em outros tipos
	checar(gs._arvore.bonus_de(["cat_watch"])["league_prep_days_bonus"] == 2.0 and gs._arvore.bonus_de(["cat_watch"])["click_bonus"] == 0.0, "cat_watch so tem o efeito novo")
	_liberar(gs)


# ---------------------------------------------------------------- saves
func _teste_saves() -> void:
	var gs := _novo("ronda_saves")
	var base: Dictionary = gs.para_save()
	# save antigo (sem os campos): carrega e nao grava nada novo
	var s0: Dictionary = base.duplicate(true)
	s0.career.erase("black_cat_hood")
	s0.permanent.erase("black_cat")
	gs.aplicar_save(s0)
	checar(gs.lenda().legend == 0 and gs.capuz.open == "" and float(gs.capuz.next_at) == 180.0, "save antigo: lenda 0 e capuz no padrao")
	# save sujo
	var s1: Dictionary = base.duplicate(true)
	s1.permanent["black_cat"] = {"legend": "muita", "rounds": -5, "scares": 99, "shown_level": 9, "open_campaign": 1.0e20}
	s1.career["black_cat_hood"] = {"hood_s": -3, "next_at": "x", "open": "fight"}
	gs.aplicar_save(s1)
	checar(gs.lenda().legend == 0 and gs.lenda().rounds == 0 and gs.lenda().scares == 0 and gs.lenda().shown_level == 0, "save sujo (tipos/negativos): tudo 0")
	checar(gs.capuz.hood_s == 0.0 and gs.capuz.next_at == 180.0 and gs.capuz.open == "", "capuz sujo: padrao e open invalido = vazio")
	var s2: Dictionary = base.duplicate(true)
	s2.permanent["black_cat"] = {"legend": _lv(gs, 1), "rounds": 2, "scares": 99, "shown_level": 9, "open_campaign": 3}
	s2.career["black_cat_hood"] = {"hood_s": 50.0, "next_at": 290.0, "open": "scare"}
	gs.aplicar_save(s2)
	checar(gs.lenda().scares == 6 and gs.lenda().shown_level == 2 and gs.lenda().legend == _lv(gs, 1), "scares <= 3 x rounds e shown_level <= nivel")
	checar(gs.capuz.open == "scare" and gs.capuz.hood_s == 50.0, "capuz valido volta como estava")
	var s3: Dictionary = base.duplicate(true)
	s3.permanent["black_cat"] = {"legend": 1.0e30, "rounds": 1.0e30}
	gs.aplicar_save(s3)
	checar(gs.lenda().legend == 1000000000, "lenda gigante = teto 1e9")
	# Ronda fechada: open nao vale
	var g2 := _novo("ronda_saves2", 1, false)
	var s4: Dictionary = g2.para_save()
	s4.career["black_cat_hood"] = {"hood_s": 5.0, "next_at": 9.0, "open": "scare"}
	g2.aplicar_save(s4)
	checar(g2.capuz.open == "", "Ronda fechada: open vira vazio")
	# no cat_* com a lenda abaixo da trava: fica e avisa
	var s5: Dictionary = base.duplicate(true)
	s5.permanent["skill_nodes"] = ["cat_rooftop"]
	gs.aplicar_save(s5)
	checar("cat_rooftop" in gs.permanente.skill_nodes and gs.avisos.any(func(a): return a.contains("cat_rooftop")), "no cat_* pago com lenda baixa: fica, com aviso")
	# ida e volta no disco
	var g3 := _novo("ronda_saves3")
	_andar(g3, 180)
	g3.ronda_ir()
	g3.ronda_jogo().sustos = 1
	g3.ronda_concluir()
	g3.ronda_voltar()
	g3.salvar()
	var g4: Node = GameStateScript.new()
	g4.inicializar(g3.store.pasta, "res://data/config.json")
	g4.autosave_ativo = false
	checar(g4.lenda() == g3.lenda() and g4.capuz == g3.capuz, "lenda e capuz voltam iguais do disco")
	for g in [gs, g2, g3, g4]:
		_liberar(g)


# ---------------------------------------------------------------- quem nao joga = igual
func _corrida(nome: String, vai: bool) -> String:
	var gs := _novo(nome)
	gs.geradores[gs.dados.geradores[0].id] = 3
	for _i in 1500:
		gs.tick(1.0)
		if vai and gs.capuz_info().get("clickable", false):
			gs.ronda_ir()
			gs.ronda_concluir()
			gs.ronda_voltar()
	var e: Dictionary = gs.para_save()
	e.career.erase("black_cat_hood")
	e.permanent.erase("black_cat")
	var r := JSON.stringify(e, "", true)
	var rondas: int = int(gs.lenda().rounds)
	_liberar(gs)
	return "%d|%s" % [rondas, r]


func _teste_quem_nao_joga() -> void:
	var a := _corrida("ronda_nj_a", false)
	var b := _corrida("ronda_nj_b", true)
	var ra := a.split("|", true, 1)
	var rb := b.split("|", true, 1)
	checar(int(ra[0]) == 0 and int(rb[0]) > 0, "A nao foi em nenhuma ronda; B foi em %s" % rb[0])
	checar(ra[1] == rb[1], "mesma campanha indo em todas ou nunca: save igual campo a campo (sem lenda/capuz)")


# Um quadro unico com delta enorme (PC suspenso) nao pode pular o premio: a janela de premio sempre aparece.
func _teste_hitch_longo() -> void:
	var gs := _novo("ronda_hitch")
	_andar(gs, 180)
	gs.ronda_ir()
	gs.tick(5000.0)
	checar(gs.ronda_ativa == "scare" and not gs._ronda_premio.is_empty(), "hitch de 5000 s: a Ronda fecha mas o premio fica esperando")
	checar(int(gs.lenda().rounds) == 1 and int(gs.lenda().legend) >= 1, "hitch: a lenda entrou uma vez")
	gs.tick(0.5)
	checar(gs.ronda_ativa == "scare", "quadro seguinte curto: ainda na tela de premio")
	gs.tick(5000.0)
	checar(gs.ronda_ativa == "", "depois de ver o premio, outro hitch longo devolve a sala (trava de 120 s)")
	checar(int(gs.lenda().rounds) == 1, "a lenda nao entrou duas vezes")
	_liberar(gs)