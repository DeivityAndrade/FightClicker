extends "res://tests/test_base.gd"
## Testa a Fase 4: árvore de habilidades, Metrônomo, revanche, dica do verde (alavanca L1), save v4 e dados.
## Usa pastas em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")
const FORTE := 1.0e7


func _novo(nome: String, dados: FightData = null) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json", TrainingData.CAMINHO_TREINO,
		TrainingData.CAMINHO_GERADORES, TrainingData.CAMINHO_TEXTOS, dados)
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.aparelhos_montados_ids = ["punching_bag", "jump_rope", "treadmill"]  # Fase 4b: os testes antigos usam os 3
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


func _atributos(gs: Node, f: float, a: float, r: float) -> void:
	gs.atributos = {"strength": f, "agility": a, "endurance": r}


# Termina a carreira por aposentadoria (pote 0 se não houver fama) para abrir a árvore.
func _ir_para_arvore(gs: Node, legado: int) -> void:
	gs.permanente["legacy_total"] = legado
	gs.aposentar()


func rodar_testes() -> void:
	_teste_dados()
	_teste_compra_de_no()
	_teste_efeito_de_cada_no()
	_teste_aditivo()
	_teste_recarregar_nao_duplica()
	_teste_metronomo_loja()
	_teste_metronomo_caminho_do_clique()
	_teste_metronomo_fora_da_luta()
	_teste_metronomo_carreira()
	_teste_ritmo_maximo()
	_teste_revanche()
	_teste_dica_do_verde()
	_teste_textos_da_previa()
	_teste_migracao()
	_teste_dados_mudam_o_jogo()
	_teste_tempo_morto()
	_teste_tempo_do_lutar()
	_teste_cartao_e_resumo()


# --- Dados (critérios 2, 6, 7) ---

func _teste_dados() -> void:
	var d := FightData.carregar()
	checar_igual(d.arvore.size(), 12, "12 nós na árvore (10 + 2 de ESTILO)")
	var total := 0
	var ramos := {}
	var barato_por_ramo := {}
	var ate40 := {}
	for n in d.arvore:
		total += int(n.cost)
		ramos[n.branch] = true
		if int(n.cost) <= 10:
			barato_por_ramo[n.branch] = true
		if int(n.cost) <= 40:
			ate40[n.branch] = true
	checar_igual(total, 3175 + 2400, "custo total 5.575 (3.175 + 2 x 1.200 do ESTILO)")
	checar_igual(ramos.keys().size(), 3, "três ramos (Corpo, Carreira, Estilo)")
	checar(ramos.has("body") and ramos.has("career") and ramos.has("style"), "ramos body, career e style")
	checar(not d.no_da_arvore("body_muscle_memory").is_empty() and not d.no_da_arvore("career_scouting").is_empty(),
		"Memória muscular e prévia detalhada existem")
	checar_igual(barato_por_ramo.keys().size(), 2, "critério 6: nó de custo <= 10 nos dois ramos")
	checar_igual(ate40.keys().size(), 2, "critério 6: nós <= 40 em ramos diferentes")
	var aposenta_cinturao := 750.0
	checar(aposenta_cinturao / float(total) <= 0.5, "critério 7: cinturão compra <= 50%% (%.0f%%)" % (100.0 * aposenta_cinturao / total))
	checar_igual(d.carreira.legacy_per_fame, 2.0, "Legado x10: legacy_per_fame 2.0")
	checar_igual(d.carreira.belt_legacy_bonus, 100.0, "Legado x10: belt_legacy_bonus 100")
	checar_igual(d.adversario("opp_fast").prize_money, 800.0, "Dinho paga $800")
	checar_igual(d.metronomo.levels.size(), 5, "Metrônomo com 5 níveis")
	checar_igual([d.metronomo.levels[0].cost, d.metronomo.levels[1].cost, d.metronomo.levels[2].cost], [80.0, 150.0, 300.0],
		"Metrônomo: $80 / $150 / $300")
	checar_igual([d.metronomo.levels[0].interval, d.metronomo.levels[1].interval, d.metronomo.levels[2].interval],
		[1.2, 0.9, 0.65], "Metrônomo: 1.2 / 0.9 / 0.65 s (níveis 1 a 3)")
	for n in d.arvore:
		checar(n.name != "" and n.description != "" and n.effect_text != "", "nó %s tem nome, descrição e efeito" % n.id)
		checar(n.name.length() <= 16 and n.description.length() <= 44, "nó %s respeita os limites de texto" % n.id)


# --- Compra (critério 3, 4) ---

func _teste_compra_de_no() -> void:
	var gs := _novo("f4_compra")
	checar(not gs.comprar_no("body_jab"), "critério 4: sem tela de fim a árvore não compra")
	_ir_para_arvore(gs, 10)
	checar(gs.arvore_aberta() and gs.legado_disponivel() == 10, "árvore aberta com a tela de fim, Legado 10")
	var estados := {}
	for n in gs.arvore_nos():
		estados[n.id] = n.state
	checar_igual(estados.body_jab, "buyable", "body_jab comprável")
	checar_igual(estados.career_purse, "buyable", "career_purse comprável")
	checar_igual(estados.body_muscle_memory, "locked", "Memória muscular trancada pelo jab")
	checar_igual(estados.body_crew, "locked", "Garagem animada trancada")
	checar(not gs.comprar_no("body_muscle_memory"), "recusa nó trancado")
	checar_igual(gs.legado_disponivel(), 10, "recusa não gasta")
	checar(not gs.comprar_no("nao_existe"), "recusa id inexistente")
	var sinais: Array = []
	gs.arvore_mudou.connect(func() -> void: sinais.append(1))
	checar(gs.comprar_no("body_jab"), "compra body_jab")
	checar_igual(gs.legado_disponivel(), 0, "desconta o custo exato (10)")
	checar_igual(sinais.size(), 1, "arvore_mudou emitido")
	checar_igual(gs.fim.legacy_total, 0, "o fim pendente mostra o Legado atual")
	checar(not gs.comprar_no("body_jab"), "não compra duas vezes")
	checar(not gs.comprar_no("career_purse"), "sem Legado: recusa")
	var est2: Dictionary = {}
	for n in gs.arvore_nos():
		est2[n.id] = n
	checar_igual(est2.body_jab.state, "owned", "body_jab comprado")
	checar_igual(est2.career_purse.state, "missing", "career_purse: falta Legado")
	checar_igual(est2.career_purse.missing, 10, "faltam 10")
	checar_igual(est2.body_muscle_memory.state, "missing", "agora a Memória muscular só falta Legado")
	checar_igual(est2.body_muscle_memory.requires_name, "Jab de base", "nome do nó anterior")
	var doc = JSON.parse_string(ler(gs.store.caminho()))
	checar(doc.state.permanent.skill_nodes == ["body_jab"] and int(doc.state.permanent.legacy_total) == 0, "salvou na hora (nó e Legado no arquivo)")
	# Legado nunca negativo.
	gs.permanente["legacy_total"] = 5
	checar(not gs.comprar_no("career_purse"), "Legado 5 < 10: recusa")
	checar_igual(gs.permanente.legacy_total, 5, "Legado intacto")
	gs.nova_carreira()
	checar(not gs.comprar_no("career_purse"), "critério 4: depois da NOVA CARREIRA a árvore fecha")
	_liberar(gs)


# --- Efeito de cada nó (critério 11) ---

func _teste_efeito_de_cada_no() -> void:
	var d := FightData.carregar()
	for n in d.arvore:
		if n.requires_art != "":
			continue  # nós ESTILO (valem só com a arte): cobertos em test_fase5.gd
		var gs := _novo("f4_efeito_" + n.id)
		gs.geradores["neighbor_kid"] = 10
		var base_clique: float = gs.por_clique()
		var base_prod: float = gs.producao_total()
		var dudu: Dictionary = gs.lutas.adversario("opp_warmup")
		var premio_d: float = gs.premio_dinheiro(dudu)
		var premio_f: int = gs.premio_fama(dudu)
		var perde: float = gs.parte_derrota()
		_ir_para_arvore(gs, 100000)
		# Cadeia de pré-requisitos até o nó.
		var cadeia: Array = []
		var atual: Dictionary = n
		while not atual.is_empty():
			cadeia.push_front(atual.id)
			atual = d.no_da_arvore(atual.requires) if atual.requires != "" else {}
		for id in cadeia:
			checar(gs.comprar_no(id), "%s: compra %s" % [n.id, id])
		# Antes da NOVA CARREIRA nada muda.
		checar_igual([gs.por_clique(), gs.producao_total(), gs.premio_dinheiro(dudu), gs.premio_fama(dudu), gs.parte_derrota(),
			gs.tem_previa_detalhada()], [base_clique, base_prod, premio_d, premio_f, perde, false],
			"%s: antes da NOVA CARREIRA nada muda" % n.id)
		gs.nova_carreira()
		gs.geradores["neighbor_kid"] = 10
		gs.risco_hud_ativo = false
		match n.id:
			"body_jab":
				checar_igual(gs.por_clique(), base_clique * 2.0, "body_jab: clique x2")
			"body_muscle_memory":
				checar_igual(gs.nivel_metronomo, 1, "Memória muscular: começa com o Metrônomo no nível 1")
				checar_igual(gs.proximo_metronomo().id, "metronome_l2", "e a loja oferece o nível 2")
			"body_heavy_hands":
				checar_igual(gs.por_clique(), base_clique * 2.5, "Mão pesada: clique x2,5 (aditivo com o jab)")
			"body_crew":
				checar_igual(gs.producao_total(), base_prod * 1.5, "Garagem animada: passivo x1,5")
			"body_crew_2":
				checar_igual(gs.producao_total(), base_prod * 2.0, "Garagem lotada: passivo x2")
			"career_purse":
				checar_igual(gs.premio_dinheiro(dudu), premio_d * 1.5, "Bolsa negociada: dinheiro x1,5")
			"career_scouting":
				checar(gs.tem_previa_detalhada() and gs.previa().show_percent, "Olho clínico: prévia mostra a porcentagem")
			"career_purse_2":
				checar_igual(gs.premio_dinheiro(dudu), premio_d * 2.0, "Empresário local: dinheiro x2")
			"career_crowd":
				checar_igual(gs.premio_fama(dudu), 15, "Torcida da rua: fama 10 -> 15")
				checar_igual(gs.premio_fama(gs.lutas.adversario("opp_strong")), 45, "fama 30 -> 45")
			"career_good_loser":
				checar_igual(gs.parte_derrota(), 0.75, "Saber cair: a derrota leva 75%")
				gs.fama = 100
				checar_igual(gs.legado_se_perder(), 150, "derrota com pote 200 leva 150")
		_liberar(gs)


func _teste_aditivo() -> void:
	var gs := _novo("f4_aditivo")
	var base: float = gs.por_clique()
	_ir_para_arvore(gs, 100000)
	for id in ["body_jab", "body_muscle_memory", "body_heavy_hands", "body_crew", "body_crew_2"]:
		gs.comprar_no(id)
	gs.nova_carreira()
	checar_igual(gs.por_clique(), base * 2.5, "jab + mão pesada = x2,5 (não x3)")
	gs.geradores["neighbor_kid"] = 10
	checar_igual(gs.producao_total(), 10.0 * 2.0, "garagem animada + lotada = x2")
	var b: Dictionary = gs.bonus_ativos()
	checar_igual([b.click_bonus, b.passive_bonus], [1.5, 1.0], "bonus_ativos soma por tipo")
	_liberar(gs)


func _teste_recarregar_nao_duplica() -> void:
	var gs := _novo("f4_reabrir")
	var pasta: String = gs.store.pasta
	var base: float = gs.por_clique()
	_ir_para_arvore(gs, 100)
	gs.comprar_no("body_jab")
	gs.comprar_no("career_purse")
	var legado: int = gs.legado_disponivel()
	_liberar(gs)
	var g2 := _reabrir(pasta)  # fechou na tela de fim, depois de comprar
	checar(g2.tem_fim_pendente(), "reabrir: volta à tela de fim")
	checar_igual(g2.nos_comprados(), ["body_jab", "career_purse"], "reabrir: nós mantidos")
	checar_igual(g2.legado_disponivel(), legado, "reabrir: Legado não volta nem duplica")
	g2.nova_carreira()
	checar_igual(g2.por_clique(), base * 2.0, "nova carreira: clique x2")
	_liberar(g2)
	var g3 := _reabrir(pasta)
	checar_igual(g3.por_clique(), base * 2.0, "reabrir de novo: ainda x2 (não duplicou)")
	checar_igual(g3.nos_comprados().size(), 2, "ainda 2 nós")
	checar_igual(g3.legado_disponivel(), legado, "Legado igual")
	_liberar(g3)


# --- Metrônomo na loja (critério 12) ---

func _teste_metronomo_loja() -> void:
	var gs := _novo("f4_metro_loja")
	checar_igual(gs.nivel_metronomo, 0, "começa sem Metrônomo")
	checar_igual(gs.intervalo_metronomo(), 0.0, "sem Metrônomo: intervalo 0")
	checar_igual(gs.proximo_metronomo().id, "metronome_l1", "o 1º à venda é o nível 1")
	checar_igual(gs.texto_efeito_metronomo(gs.proximo_metronomo()), "1 SOCO A CADA 1.2 S", "texto do nível 1")
	checar(not gs.comprar_metronomo(), "sem dinheiro: recusa")
	gs.dinheiro = 79.0
	checar(not gs.comprar_metronomo(), "$79 < $80: recusa")
	gs.dinheiro = 200.0  # cabe no prêmio de 2 vitórias (50 + 150)
	var niveis: Array = []
	gs.metronomo_mudou.connect(func(n: int) -> void: niveis.append(n))
	checar(gs.comprar_metronomo(), "compra o nível 1")
	checar_igual([gs.nivel_metronomo, gs.dinheiro], [1, 120.0], "nível 1, gastou $80")
	checar_igual(gs.texto_efeito_metronomo(gs.proximo_metronomo()), "1 SOCO A CADA 0.9 S", "texto do nível 2")
	checar(not gs.comprar_metronomo(), "$120 < $150: o nível 2 espera")
	gs.dinheiro = 3150.0
	checar(gs.comprar_metronomo() and gs.comprar_metronomo() and gs.comprar_metronomo() and gs.comprar_metronomo(), "compra os níveis 2 a 5")
	checar_igual([gs.nivel_metronomo, gs.dinheiro], [5, 0.0], "nível 5, gastou 150 + 300 + 700 + 2000")
	checar(gs.proximo_metronomo().is_empty() and not gs.pode_comprar_metronomo(), "linha completa")
	checar_igual(niveis, [1, 2, 3, 4, 5], "metronomo_mudou emitido a cada compra")
	checar(gs.socos_por_segundo_metronomo() <= 2.5 + 1e-9 and gs.socos_por_segundo_metronomo() > 2.4, "máximo 2,5 socos/s")
	gs.luta = {"x": 1}
	gs.dinheiro = 1000.0
	gs.nivel_metronomo = 0
	checar(not gs.comprar_metronomo(), "durante a luta a loja está bloqueada")
	gs.luta = {}
	_liberar(gs)


# --- Caminho do clique (critério 13) ---

func _teste_metronomo_caminho_do_clique() -> void:
	var gs := _novo("f4_metro_clique")
	gs.rng.seed = 777
	gs.nivel_metronomo = 2
	var cliques: Array = []
	var autos: Array = []
	gs.clicou.connect(func(g: float, c: bool, ap: String, at: String, t: String) -> void: cliques.append(g))
	gs.auto_socou.connect(func(g: float, c: bool, ap: String, at: String, t: String) -> void: autos.append([g, c, ap, at, t]))
	var base: float = gs.por_clique()
	var crits := 0
	var soma := 0.0
	for i in 1000:
		var r: Dictionary = gs.auto_socar()
		soma += r.ganho
		if r.critico:
			crits += 1
	var taxa := float(crits) / 1000.0
	checar(absf(taxa - gs.dados.crit_chance) <= 0.03, "taxa de crítico do auto-soco = %.1f%% (esperado %.0f%% +- 3)" % [taxa * 100.0, gs.dados.crit_chance * 100.0])
	checar_igual(autos.size(), 1000, "auto_socou emitido 1000 vezes")
	checar_igual(cliques.size(), 0, "auto-soco NÃO emite clicou (a UI não treme)")
	checar(autos[0].size() == 5 and autos[0][2] == "punching_bag" and autos[0][3] == "strength", "sinal traz ganho, crítico, aparelho, atributo, texto")
	checar(absf(gs.treino - soma) < 1e-6 and absf(gs.atributos.strength - soma) < 1e-6, "treino vai para o saldo e para o atributo do foco")
	# Luva de lona: o treino por soco dobra.
	gs.nivel_luva = 1
	checar_igual(gs.por_clique(), base * 2.0, "luva de lona dobra o treino do auto-soco")
	var antes: float = gs.treino
	var r2: Dictionary = gs.auto_socar()
	checar_igual(r2.ganho, base * 2.0 * (gs.dados.crit_multiplier if r2.critico else 1.0), "ganho do auto-soco usa a luva")
	checar(absf(gs.treino - antes - r2.ganho) < 1e-9, "e vai todo para o saldo")
	# Foco em outro aparelho: o treino vai para o atributo dele.
	gs.definir_foco("jump_rope")
	var ag0: float = gs.atributos.agility
	var r3: Dictionary = gs.auto_socar()
	checar(r3.atributo == "agility" and gs.atributos.agility > ag0, "o treino vai para o atributo em foco (agilidade)")
	# Com o jab da árvore o auto-soco também dobra.
	var g2 := _novo("f4_metro_jab")
	var b2: float = g2.por_clique()
	_ir_para_arvore(g2, 10)
	g2.comprar_no("body_jab")
	g2.nova_carreira()
	checar_igual(g2.por_clique(), b2 * 2.0, "jab da árvore vale para o Metrônomo")
	g2.rng.seed = 5
	var r4: Dictionary = g2.auto_socar()
	checar_igual(r4.ganho, b2 * 2.0 * (g2.dados.crit_multiplier if r4.critico else 1.0), "ganho do auto-soco com o jab")
	_liberar(g2)
	_liberar(gs)


# --- Fora da luta (critério 16) ---

func _teste_metronomo_fora_da_luta() -> void:
	var gs := _novo("f4_metro_luta")
	gs.nivel_metronomo = 3
	gs.rng.seed = 11
	var autos: Array = []
	gs.auto_socou.connect(func(_g: float, _c: bool, _a: String, _t: String, _x: String) -> void: autos.append(1))
	# Garagem livre: soca.
	for i in 20:
		gs.tick(0.1)
	checar(autos.size() >= 2, "garagem livre: o Metrônomo soca (%d socos em 2 s)" % autos.size())
	# 10 lutas completas: 0 socos e 0 treino do Metrônomo durante a luta pendente.
	_atributos(gs, FORTE, FORTE, FORTE)
	var socos_na_luta := 0
	for i in 10:
		gs.indice_escada = 0
		gs.cinturao = false
		var n0 := autos.size()
		var t0: float = gs.treino
		gs.lutar()
		for k in 50:
			gs.tick(0.2)  # 10 s de luta
		socos_na_luta += autos.size() - n0
		checar(gs.treino == t0 + 0.0 or gs.treino >= t0, "treino não encolhe")
		gs.concluir_luta()
	checar_igual(socos_na_luta, 0, "critério 16: 0 auto-socos durante 10 lutas")
	# Tela de fim aberta.
	gs.aposentar()
	var n1 := autos.size()
	var t1: float = gs.treino
	for k in 100:
		gs.tick(0.1)
	checar_igual(autos.size(), n1, "tela de fim: 0 auto-socos")
	checar_igual(gs.treino, t1, "tela de fim: o treino não anda")
	gs.nova_carreira()
	# Janela modal (prévia, confirmação, cartão): para.
	gs.nivel_metronomo = 3
	gs.definir_modal(true)
	var n2 := autos.size()
	for k in 50:
		gs.tick(0.1)
	checar_igual(autos.size(), n2, "janela aberta: 0 auto-socos")
	checar_igual(gs.treino, 0.0, "janela aberta: 0 treino do Metrônomo")
	gs.definir_modal(false)
	for k in 30:
		gs.tick(0.1)
	checar(autos.size() > n2, "janela fechada: volta a socar")
	checar(autos.size() - n2 <= 5, "sem acumular socos do tempo parado (%d)" % (autos.size() - n2))
	_liberar(gs)


# --- Metrônomo na carreira (critério 17) ---

func _teste_metronomo_carreira() -> void:
	var gs := _novo("f4_metro_carreira")
	gs.nivel_metronomo = 2
	gs.aposentar()
	gs.nova_carreira()
	checar_igual(gs.nivel_metronomo, 0, "NOVA CARREIRA zera o Metrônomo")
	var pasta: String = gs.store.pasta
	gs.nivel_metronomo = 3
	gs.salvar()
	_liberar(gs)
	var g2 := _reabrir(pasta)
	checar_igual(g2.nivel_metronomo, 3, "o nível do Metrônomo vai no save")
	var doc = JSON.parse_string(ler(g2.store.caminho()))
	checar_igual(int(doc.state.career.metronome_level), 3, "career.metronome_level no arquivo")
	_ir_para_arvore(g2, 100)
	g2.comprar_no("body_jab")
	g2.comprar_no("body_muscle_memory")
	g2.nova_carreira()
	checar_igual(g2.nivel_metronomo, 1, "com a Memória muscular: nível 1 no minuto 0")
	checar_igual(g2.proximo_metronomo().id, "metronome_l2", "a loja oferece o nível 2")
	g2.aposentar()
	g2.nova_carreira()
	checar_igual(g2.nivel_metronomo, 1, "e na carreira seguinte também")
	# save com nível maior que o máximo é recortado
	g2.aplicar_save({"career": {"metronome_level": 99}})
	checar_igual(g2.nivel_metronomo, 5, "nível inválido recortado ao máximo")
	_liberar(g2)


# --- Ritmo máximo (critério 15) ---

func _teste_ritmo_maximo() -> void:
	var pasta := pasta_limpa("f4_ritmo")
	escrever(pasta + "shop.json", '{"paid_generators": [{"id": "gen_paid_1", "base_cost": 50, "growth": 1.6, "production": 25, "draw_thresholds": [1]}],'
		+ '"gloves": {"levels": [{"id": "glove_l1", "cost": 120, "click_multiplier": 2}]},'
		+ '"metronome": {"levels": [{"id": "m1", "cost": 10, "interval": 0.1}, {"id": "m2", "cost": 20, "interval": 0.05},'
		+ '{"id": "m3", "cost": 0, "interval": 1.0}, {"id": "m4", "cost": 5, "interval": 500}]}}')
	var d := FightData.carregar(FightData.CAMINHO_LUTAS, FightData.CAMINHO_ADVERSARIOS, pasta + "shop.json")
	checar_igual(d.metronomo.levels.size(), 1, "m2 (não mais rápido), custo 0 e m4 ignorados")
	checar(d.metronomo.levels[0].interval >= 0.3 - 1e-9, "intervalo 0.1 recortado para >= 0.3")
	var gs := _novo("f4_ritmo_jogo", d)
	gs.nivel_metronomo = 1
	var n := 0
	gs.auto_socou.connect(func(_g: float, _c: bool, _a: String, _t: String, _x: String) -> void: n += 1)
	for i in 100:
		gs.tick(0.1)  # 10 s
	checar(n <= 34, "dado errado de intervalo: no máximo ~3,3 socos/s (%d socos em 10 s)" % n)
	n = 0
	gs.tick(5.0)
	checar(n <= 3, "um quadro enorme dá no máximo 3 socos (%d)" % n)
	_liberar(gs)


# --- Revanche (critérios 18 e 19) ---

func _teste_revanche() -> void:
	var gs := _novo("f4_revanche")
	checar_igual(gs.algoz(), "", "começa sem algoz")
	gs.indice_escada = 2
	gs.fama = 100
	_atributos(gs, 0.0, 0.0, 0.0)
	gs.lutar()
	gs.concluir_luta()
	checar_igual(gs.permanente.revenge_opponent, "opp_fast", "a derrota marca o Dinho como algoz")
	var doc = JSON.parse_string(ler(gs.store.caminho()))
	checar_igual(doc.state.permanent.revenge_opponent, "opp_fast", "marca no arquivo (mesmo save do Legado)")
	gs.nova_carreira()
	checar(gs.e_algoz("opp_fast") and not gs.e_algoz("opp_strong"), "na carreira seguinte só o Dinho tem a marca")
	gs.indice_escada = 2
	checar(gs.previa().revenge, "a prévia contra o Dinho traz revenge = true")
	checar(gs.info_proxima().revenge, "o bloco PRÓXIMA também")
	gs.indice_escada = 1
	checar(not gs.previa().revenge, "contra o Brutão não há marca")
	# Vencer o algoz: momento de revanche uma vez só.
	gs.indice_escada = 2
	_atributos(gs, FORTE, FORTE, FORTE)
	gs.lutar()
	var r: Dictionary = gs.concluir_luta()
	checar(r.win and r.revenge, "vencer o algoz devolve revenge = true")
	checar(r.revenge_line.contains("Dinho"), "e a linha do momento traz o nome")
	checar_igual(gs.algoz(), "", "a marca some")
	checar_igual(gs.concluir_luta(), {}, "concluir de novo não repete")
	gs.indice_escada = 3
	gs.lutar()
	checar(not gs.concluir_luta().revenge, "vencer outro adversário depois não é revanche")
	# Aposentadoria não marca (e limpa a marca anterior).
	gs.permanente["revenge_opponent"] = "opp_tank"
	gs.aposentar()
	checar_igual(gs.algoz(), "", "aposentadoria limpa a marca")
	gs.nova_carreira()
	# Reabrir com a vitória pendente: aplica uma vez e mostra a revanche uma vez.
	var g2 := _novo("f4_revanche_pendente")
	var pasta: String = g2.store.pasta
	g2.permanente["revenge_opponent"] = "opp_warmup"
	_atributos(g2, FORTE, FORTE, FORTE)
	g2.lutar()
	_liberar(g2)
	var g3 := _reabrir(pasta)
	var rr: Dictionary = g3.concluir_luta()
	checar(rr.revenge, "luta pendente ao reabrir: revanche mostrada")
	_liberar(g3)
	var g4 := _reabrir(pasta)
	checar(g4.concluir_luta().is_empty() and g4.algoz() == "", "e não de novo ao reabrir outra vez")
	_liberar(g4)
	_liberar(gs)


# --- Dica do verde e alavanca L1 (critérios 20 e 21) ---

func _teste_dica_do_verde() -> void:
	var gs := _novo("f4_verde")
	var base := {"kind": "defeat", "career_number": 1, "legacy_gained": 0, "legacy_total": 0, "opponent": "opp_fast", "tactic": "defensive",
		"seed": 1, "player": {}, "summary": {"wins": 0, "belts": 0, "fame": 0, "money_earned": 0.0, "play_seconds": 0.0},
		"result": {"ko": true, "round": 2}}
	for k in ["missing", "far", "far_plain"]:
		var f: Dictionary = base.duplicate(true)
		f["reason"] = {"kind": k, "attribute": "agility", "faltaram": 100.0, "far_n": 12, "model": 0, "tip": 0, "better_tactic": "",
			"stat": {"kind": "points", "n": 10, "k": 90}}
		checar_igual(gs.textos_fim(f).wait_green, "VOLTE A ENFRENTAR ELE QUANDO A PRÉVIA FICAR VERDE", "derrota '%s': dica do verde" % k)
	var azar: Dictionary = base.duplicate(true)
	azar["reason"] = {"kind": "luck", "attribute": "", "faltaram": -1.0, "far_n": 0, "model": 0, "tip": 0, "better_tactic": "",
		"stat": {"kind": "luck_odds", "n": 9, "k": 0}}
	checar_igual(gs.textos_fim(azar).wait_green, "", "derrota por azar: sem dica do verde (só a de azar)")
	checar(gs.textos_fim(azar).tip != "", "azar: continua a dica de azar")
	gs.indice_escada = 0
	var ret: Dictionary = {"kind": "retire", "career_number": 1, "legacy_gained": 0, "legacy_total": 0, "opponent": "", "summary": {"belts": 0}}
	checar_igual(gs.textos_fim(ret).wait_green, "", "aposentadoria: sem dica do verde")
	# Prévia: algoz = Seu Muralha (alavanca L1).
	gs.permanente["revenge_opponent"] = "opp_tank"
	_atributos(gs, 0.0, 0.0, 0.0)
	gs.indice_escada = 1  # Brutão (antes do algoz), não verde
	checar(gs.previa().wait_green, "L1: antes do algoz e não verde: ESPERE FICAR VERDE")
	gs.indice_escada = 3
	checar(gs.previa().wait_green, "contra o próprio algoz, não verde: mostra")
	_atributos(gs, FORTE, FORTE, FORTE)
	gs.indice_escada = 1
	checar_igual(gs.previa().risk, "easy", "forte: verde")
	checar(not gs.previa().wait_green, "L1: verde: a linha não aparece")
	# Depois do algoz na escada, sem algoz e depois de vencer o algoz: nada.
	gs.permanente["revenge_opponent"] = "opp_strong"
	_atributos(gs, 0.0, 0.0, 0.0)
	gs.indice_escada = 2
	checar(not gs.previa().wait_green, "quem vem depois do algoz: a linha não aparece")
	gs.indice_escada = 0
	checar(gs.previa().wait_green, "o Dudu vem antes do Brutão (algoz): mostra")
	gs.permanente["revenge_opponent"] = ""
	checar(not gs.previa().wait_green, "sem algoz: não aparece")
	# Só texto: LUTAR continua liberado e o rótulo não muda.
	gs.permanente["revenge_opponent"] = "opp_tank"
	gs.indice_escada = 1
	var rotulo_antes: String = gs.previa().risk
	checar(gs.pode_lutar(), "L1 só é texto: pode lutar do mesmo jeito")
	checar_igual(gs.risco_tatica().label, rotulo_antes, "o rótulo é o mesmo (a cor nunca mente)")
	_liberar(gs)


# --- Textos da prévia (bônus visíveis, critério 10) ---

func _teste_textos_da_previa() -> void:
	var gs := _novo("f4_previa_textos")
	checar_igual(gs.previa().stake_win, "SE VENCER: $50 + 10 FAMA", "sem nós: prêmio sem bônus")
	checar_igual(gs.previa().stake_lose, "PERDER ENCERRA A CARREIRA (METADE DO LEGADO)", "sem nós: perder = metade")
	checar(not gs.previa().show_percent, "sem nós: sem porcentagem")
	_ir_para_arvore(gs, 2000)
	for id in ["career_purse", "career_scouting", "career_crowd", "career_good_loser"]:
		gs.comprar_no(id)
	gs.nova_carreira()
	var p: Dictionary = gs.previa()
	checar_igual(p.stake_win, "SE VENCER: $75 (+50%) + 15 FAMA (+50%)", "prêmio com bônus e (+50%)")
	checar_igual(p.stake_lose, "PERDER ENCERRA A CARREIRA (75% DO LEGADO)", "perder leva 75%")
	checar(p.show_percent and p.percent_text.ends_with("%"), "porcentagem: %s" % p.percent_text)
	for t in p.risks:
		var chance: float = p.risks[t].chance
		var pct: int = p.risks[t].percent
		checar(pct <= int(chance * 100.0 + 1e-6) and (chance < 0.9 or pct >= 90), "porcentagem de %s não passa do rótulo (%d%%, %.3f)" % [t, pct, chance])
	_liberar(gs)


# --- Migração (critério 28) ---

func _teste_migracao() -> void:
	var pasta := pasta_limpa("f4_mig_v3")
	var v3 := {"version": 3, "saved_at_unix": 1730000000, "state": {
		"career": {"training": 1234.5, "attributes": {"strength": 900, "agility": 200, "endurance": 134.5}, "focus": "jump_rope",
			"generators": {"neighbor_kid": 12}, "upgrades": {"punching_bag": 2}, "paid_generators": {"gen_paid_1": 2},
			"glove_level": 1, "money": 30.0, "fame": 40, "ladder_index": 2, "belt": false, "tactic": "counter",
			"play_seconds": 742.0, "money_earned": 200.0, "fight": null},
		"permanent": {"legacy_total": 14, "career_number": 3, "careers_finished": 2, "best_wins": 3, "belts_won": 0},
		"ending": null}}
	escrever(pasta + "save.json", JSON.stringify(v3))
	var gs := _reabrir(pasta)
	checar_igual(gs.permanente.legacy_total, 140, "v3 -> v4: Legado x10 (14 -> 140)")
	checar_igual(gs.nos_comprados(), [], "nenhum nó comprado")
	checar_igual(gs.algoz(), "", "sem marca de revanche")
	checar_igual(gs.nivel_metronomo, 0, "Metrônomo 0")
	checar_igual([gs.treino, gs.fama, gs.indice_escada, gs.dinheiro, gs.nivel_luva, gs.tatica, gs.numero_carreira()],
		[1234.5, 40, 2, 30.0, 1, "counter", 3], "carreira em andamento intacta")
	checar_igual(gs.quantidade_gerador("gen_paid_1"), 2, "Nelsons mantidos")
	checar_igual(gs.permanente.careers_finished, 2, "recordes mantidos")
	gs.salvar()
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual(int(doc.version), SaveStore.VERSAO_ATUAL, "regravado na versão atual")
	_liberar(gs)
	var g2 := _reabrir(pasta)
	checar_igual(g2.permanente.legacy_total, 140, "reabrir depois de migrar não multiplica de novo")
	_liberar(g2)
	# Tela de fim pendente e luta pendente também convertem / ficam intactas.
	var pasta2 := pasta_limpa("f4_mig_v3_fim")
	var v3b: Dictionary = v3.duplicate(true)
	v3b.state["ending"] = {"kind": "defeat", "career_number": 3, "legacy_gained": 7, "legacy_total": 14, "opponent": "opp_fast",
		"tactic": "defensive", "seed": 1, "player": {}, "result": {}, "reason": {}, "summary": {"wins": 2}}
	escrever(pasta2 + "save.json", JSON.stringify(v3b))
	var g3 := _reabrir(pasta2)
	checar_igual([g3.fim.legacy_gained, g3.fim.legacy_total, g3.permanente.legacy_total], [70, 140, 140],
		"v3 com fim pendente: ending x10 e Legado x10")
	checar_igual(g3.algoz(), "", "e sem marca de revanche")
	checar(g3.arvore_aberta(), "a árvore abre direto (fim pendente)")
	_liberar(g3)
	# Cadeia v0 -> v4.
	var pasta3 := pasta_limpa("f4_mig_v0")
	escrever(pasta3 + "save.json", '{"treino": 77}')
	var g4 := _reabrir(pasta3)
	checar_igual([g4.treino, g4.permanente.legacy_total, g4.nos_comprados()], [77.0, 0, []], "v0 -> v4 em cadeia")
	_liberar(g4)
	# Save v4 editado: nós inválidos, repetidos e sem o anterior são ignorados (sem devolver Legado).
	var g5 := _novo("f4_nos_ruins")
	g5.aplicar_save({"permanent": {"legacy_total": 5, "skill_nodes": ["body_jab", "body_jab", "lixo", "body_heavy_hands", "career_scouting"],
		"revenge_opponent": "opp_fantasma"}})
	checar_igual(g5.nos_comprados(), ["body_jab"], "nós repetidos, inexistentes e sem o anterior ignorados")
	checar_igual(g5.permanente.legacy_total, 5, "o Legado não é devolvido")
	checar_igual(g5.algoz(), "", "algoz inexistente vira vazio")
	_liberar(g5)


# --- Dados mudam o jogo sem código (critério 30) ---

func _teste_dados_mudam_o_jogo() -> void:
	var pasta := pasta_limpa("f4_dados")
	escrever(pasta + "tree.json", '{"branches": [{"id": "body", "name": "CORPO"}, {"id": "career", "name": "CARREIRA"}], "nodes": ['
		+ '{"id": "a", "branch": "body", "requires": "", "cost": 3, "effect": {"type": "click_bonus", "value": 4.0}, "name": "A", "effect_text": "+{pct}%"},'
		+ '{"id": "b", "branch": "body", "requires": "a", "cost": 7, "effect": {"type": "magia", "value": 1}},'
		+ '{"id": "c", "branch": "linhagem", "requires": "", "cost": 7, "effect": {"type": "click_bonus", "value": 1}},'
		+ '{"id": "d", "branch": "career", "requires": "a", "cost": 7, "effect": {"type": "money_bonus", "value": 1}},'
		+ '{"id": "e", "branch": "career", "requires": "", "cost": 0, "effect": {"type": "money_bonus", "value": 1}},'
		+ '{"id": "f", "branch": "career", "requires": "g", "cost": 2, "effect": {"type": "fame_bonus", "value": 1}},'
		+ '{"id": "g", "branch": "career", "requires": "f", "cost": 2, "effect": {"type": "fame_bonus", "value": 1}}]}')
	escrever(pasta + "shop.json", '{"paid_generators": [{"id": "gen_paid_1", "base_cost": 50, "growth": 1.6, "production": 25, "draw_thresholds": [1]}],'
		+ '"gloves": {"levels": [{"id": "glove_l1", "cost": 120, "click_multiplier": 2}]},'
		+ '"metronome": {"levels": [{"id": "m1", "cost": 5, "interval": 3.0}, {"id": "m2", "cost": 9, "interval": 1.5}]}}')
	var d := FightData.carregar(FightData.CAMINHO_LUTAS, FightData.CAMINHO_ADVERSARIOS, pasta + "shop.json",
		FightData.CAMINHO_CARREIRA, pasta + "tree.json")
	var ids: Array = []
	for n in d.arvore:
		ids.append(n.id)
	checar_igual(ids, ["a", "d", "f", "g"], "tipo desconhecido, ramo inexistente e custo 0 ignorados")
	checar_igual(d.no_da_arvore("f").requires, "", "ciclo em 'requires' vira vazio")
	checar_igual(d.no_da_arvore("g").requires, "f", "e o outro lado do ciclo fica ligado ao primeiro")
	checar_igual(d.no_da_arvore("d").requires, "", "requires de outro ramo vira vazio")
	var gs := _novo("f4_dados_jogo", d)
	_ir_para_arvore(gs, 3)
	checar(gs.comprar_no("a"), "preço do JSON (3)")
	gs.nova_carreira()
	checar_igual(gs.por_clique(), 5.0, "valor do JSON (+400%) -> clique x5")
	checar_igual(gs.texto_efeito_no(d.no_da_arvore("a")), "+400%", "effect_text do JSON")
	gs.dinheiro = 5.0
	checar(gs.comprar_metronomo(), "Metrônomo com custo do JSON ($5)")
	checar_igual(gs.intervalo_metronomo(), 3.0, "intervalo do JSON (3 s)")
	checar_igual(gs.texto_efeito_metronomo(gs.proximo_metronomo()), "1 SOCO A CADA 1.5 S", "texto com o intervalo do JSON")
	_liberar(gs)
	# Árvore ausente: sem nós, o jogo abre normalmente.
	var vazio := FightData.carregar(FightData.CAMINHO_LUTAS, FightData.CAMINHO_ADVERSARIOS, FightData.CAMINHO_LOJA,
		FightData.CAMINHO_CARREIRA, pasta + "nao_existe.json")
	checar(vazio.arvore.is_empty(), "arquivo da árvore ausente: sem nós")
	# defeat_share + bônus >= retire_share é recortado.
	var g2 := _novo("f4_dados_teto")
	g2._bonus = {"defeat_share_bonus": 5.0}
	checar(g2.parte_derrota() < g2.lutas.carreira.retire_share, "derrota nunca rende tanto quanto aposentar")
	_liberar(g2)


# --- Tempo morto (métrica para o QA) ---

func _teste_tempo_morto() -> void:
	var gs := _novo("f4_morto")
	gs.risco_hud_ativo = true
	_atributos(gs, 0.0, 0.0, 0.0)  # Dudu perigoso com 0 de treino
	gs.dinheiro = 0.0
	for i in 40:
		gs.tick(0.5)
	var m: Dictionary = gs.tempo_morto()
	checar(m.has("atual") and m.has("maximo") and m.has("total"), "tempo_morto() devolve atual, maximo e total")
	checar(m.atual >= 15.0 and m.maximo >= 15.0, "perigoso e sem dinheiro para a loja: tempo morto corre (%.1f s)" % m.atual)
	gs.dinheiro = 80.0  # cabe o Metrônomo 1 ($80): sai do tempo morto
	gs.tick(0.5)
	checar_igual(gs.tempo_morto().atual, 0.0, "cabe algo da loja: o trecho fecha")
	checar(gs.tempo_morto().maximo >= 15.0, "e o maior trecho fica guardado")
	gs.dinheiro = 0.0
	gs.tick(0.5)
	checar(gs.tempo_morto().atual > 0.0, "sem dinheiro de novo: novo trecho")
	gs.aposentar()
	gs.nova_carreira()
	checar_igual(gs.tempo_morto().maximo, 0.0, "nova carreira zera a métrica")
	gs.risco_hud_ativo = false
	_liberar(gs)


# --- Critério 33: o tempo do clique em LUTAR! não depende do resultado ---

func _teste_tempo_do_lutar() -> void:
	var tv: Array = []
	var td: Array = []
	for i in 6:
		var gs := _novo("f4_tempo_lutar_%d" % i)
		_atributos(gs, FORTE, FORTE, FORTE)
		var t0 := Time.get_ticks_usec()
		gs.lutar()
		tv.append((Time.get_ticks_usec() - t0) / 1000.0)
		gs.concluir_luta()
		_liberar(gs)
		var gd := _novo("f4_tempo_lutar_d%d" % i)
		gd.indice_escada = 3
		_atributos(gd, 0.0, 0.0, 0.0)
		var t1 := Time.get_ticks_usec()
		gd.lutar()
		td.append((Time.get_ticks_usec() - t1) / 1000.0)
		gd.concluir_luta()
		_liberar(gd)
	tv.sort()
	td.sort()
	print("  lutar() mediana: vitória %.1f ms, derrota %.1f ms" % [tv[3], td[3]])
	checar(tv[3] < 80.0 and td[3] < 80.0, "lutar() não calcula o motivo na hora (vitória %.1f ms, derrota %.1f ms)" % [tv[3], td[3]])
	checar(absf(tv[3] - td[3]) < 25.0, "a diferença entre vitória e derrota é imperceptível (%.1f ms)" % absf(tv[3] - td[3]))


# --- Cartão de início e resumo da garagem (critério 9) ---

func _teste_cartao_e_resumo() -> void:
	var gs := _novo("f4_cartao")
	checar(gs.cartao_inicio().is_empty() and gs.resumo_legado().count == 0, "sem nós: sem cartão e sem resumo")
	_ir_para_arvore(gs, 100)
	gs.comprar_no("body_jab")
	gs.comprar_no("career_purse")
	var cartoes: Array = []
	gs.nova_carreira_iniciada.connect(func(c: Dictionary) -> void: cartoes.append(c))
	gs.nova_carreira()
	checar_igual(cartoes.size(), 1, "nova_carreira_iniciada emitido uma vez")
	var c: Dictionary = cartoes[0]
	checar_igual(c.title, "CARREIRA 2 — O QUE VOCÊ TROUXE:", "título do cartão")
	checar_igual(c.nodes.size(), 2, "uma linha por nó")
	checar_igual(c.nodes[0].effect_text, "+100% TREINO POR CLIQUE", "efeito do jab em número")
	checar_igual(c.nodes[1].effect_text, "+50% DINHEIRO POR VITÓRIA", "efeito da bolsa em número")
	checar_igual(gs.resumo_legado().label, "LEGADO: 2 NÓS", "rótulo do resumo")
	var pasta: String = gs.store.pasta
	_liberar(gs)
	var g2 := _reabrir(pasta)
	var n := 0
	g2.nova_carreira_iniciada.connect(func(_c: Dictionary) -> void: n += 1)
	g2.carregar_save()
	checar_igual(n, 0, "o cartão não reaparece ao carregar o save")
	_liberar(g2)
