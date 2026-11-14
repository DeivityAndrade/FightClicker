extends "res://tests/test_base.gd"
## Fase 5.4: árvore grande (mapa, travas, "vale na próxima campanha", efeitos novos, save v10).
## Tudo em pastas de user://test/, nunca o save real. Números lidos de data/.

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


# Campanha nova que começa com estes nós (e artes liberadas, se pedidas).
func _com_nos(nome: String, nos: Array, artes: Array = []) -> Node:
	var gs := _novo(nome)
	gs.permanente["skill_nodes"] = nos.duplicate()
	gs.permanente["arts_unlocked"] = artes.duplicate()
	if not artes.is_empty():
		gs.escolher_arte(artes[0])  # com artes liberadas a escolha vem antes de qualquer fim
	gs.aposentar()
	gs.nova_carreira()
	return gs


func rodar_testes() -> void:
	_teste_dados()
	_teste_revelacao_e_travas()
	_teste_brilho_e_abertura()
	_teste_vale_na_proxima()
	_teste_efeitos_de_inicio()
	_teste_efeitos_de_jogo()
	_teste_artes()
	_teste_legado()
	_teste_mapa_api()
	_teste_save_v10()
	_teste_dados_no_json()


func _teste_dados() -> void:
	var d := FightData.carregar()
	checar_igual(d.arvore.size(), 39, "39 nós carregados")
	checar_igual(d.no_da_arvore("gar_rope").region, "garage", "região lida")
	checar(d.no_da_arvore("body_jab").root and "gar_tape" in d.no_da_arvore("body_jab").neighbors, "raiz e vizinhos lidos")
	checar("gar_rope" in d.no_da_arvore("gar_tape").neighbors, "vizinhança simétrica")
	checar_igual(d.no_da_arvore("gym_membership").lock, "gym", "trava da região")
	checar_igual(d.no_da_arvore("box_counter").lock, "art:boxing", "trava de arte")
	checar_igual(d.no_da_arvore("gar_crew_start").effect_target, "neighbor_kid", "alvo do start_generator")
	checar_igual(d.no_da_arvore("gar_rope").pos, Vector2(-6, -1), "posição lida")


func _teste_revelacao_e_travas() -> void:
	var gs := _novo("f54_rev")
	for id in ["body_jab", "career_purse"]:
		checar_igual(gs.estado_mapa(id), "visible", "%s é raiz à vista" % id)
	checar_igual(gs.estado_mapa("gar_tape"), "hidden", "gar_tape escondido sem vizinho comprado")
	gs.permanente["legacy_total"] = 10
	checar(gs.comprar_no("body_jab"), "compra body_jab")
	for id in ["gar_tape", "body_muscle_memory", "body_crew", "career_purse"]:
		checar(gs.estado_mapa(id) == "visible", "%s à vista depois do Jab" % id)
	checar_igual(gs.estado_mapa("gar_rope"), "hidden", "gar_rope ainda escondido")
	checar_igual(gs.estado_mapa("body_jab"), "owned", "body_jab aceso")
	# Travas: sem arte liberada nada de academia, boxe e jiu-jitsu, nem por ligação.
	gs.permanente["skill_nodes"] = ["body_jab", "gar_tape", "gar_rope", "link_shout", "career_purse", "career_scouting", "career_purse_2"]
	for id in ["gym_membership", "box_counter", "bjj_guard", "box_wraps", "style_boxing", "style_bjj"]:
		checar_igual(gs.estado_mapa(id), "hidden", "%s trancado sem arte" % id)
	checar_igual(gs.estado_mapa("link_shout"), "owned", "a ligação em si abre")
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	for id in ["gym_membership", "box_counter", "bjj_guard", "box_wraps", "style_boxing", "style_bjj"]:
		checar_igual(gs.estado_mapa(id), "visible", "%s abre com a arte" % id)
	checar_igual(gs.estado_mapa("box_bell"), "hidden", "box_bell ainda escondido")
	gs.permanente["arts_unlocked"] = ["boxing"]
	checar_igual(gs.estado_mapa("bjj_guard"), "hidden", "cada ramo pede a sua arte")
	_liberar(gs)


func _teste_brilho_e_abertura() -> void:
	var gs := _novo("f54_brilho")
	gs.permanente["legacy_total"] = 9
	checar(not gs.ha_no_compravel(), "Legado 9: sem brilho")
	gs.permanente["legacy_total"] = 10
	checar(gs.ha_no_compravel(), "Legado 10: brilho")
	checar(gs.pode_abrir_arvore(), "abre no meio da campanha")
	gs.permanente["arts_unlocked"] = ["boxing"]
	checar(not gs.pode_abrir_arvore() and not gs.comprar_no("body_jab"), "escolha da arte pendente: fechada")
	checar(gs.ha_no_compravel(), "o brilho não olha se o mapa abre")
	gs.escolher_arte("boxing")
	checar(gs.pode_abrir_arvore(), "depois da escolha abre")
	gs.caixas_lista.append({"item": "treadmill", "kind": "apparatus", "hits": 1})
	checar(not gs.pode_abrir_arvore(), "caixa no meio da abertura: fechada")
	gs.caixas_lista.clear()
	gs.caixas_lista.append({"item": "treadmill", "kind": "apparatus", "hits": 0})
	checar(gs.pode_abrir_arvore(), "caixa fechada sem batida não trava")
	gs.caixas_lista.clear()
	gs.segundos_campanha = gs._alvo_relogio()
	checar(gs.no_dia_da_luta() and not gs.pode_abrir_arvore(), "dia da luta: fechada")
	gs.segundos_campanha = 0.0
	gs.luta = {"opponent": "x"}
	checar(not gs.pode_abrir_arvore(), "na luta: fechada")
	gs.luta = {}
	_liberar(gs)


func _teste_vale_na_proxima() -> void:
	var gs := _novo("f54_proxima")
	gs.permanente["legacy_total"] = 100
	var antes: float = gs.por_clique()
	var revelados: Array = []
	gs.no_revelado.connect(func(ids): revelados.append_array(ids))
	checar(gs.comprar_no("body_jab"), "compra no meio da campanha")
	checar(gs.tem_no("body_jab") and not ("body_jab" in gs.nos_ativos()), "comprado, mas ainda não ativo")
	checar_igual(gs.por_clique(), antes, "por_clique não muda na campanha atual")
	checar("gar_tape" in revelados and "body_crew" in revelados, "sinal no_revelado com os vizinhos")
	checar_igual(gs.permanente.tree_last_node, "body_jab", "tree_last_node gravado")
	var item: Dictionary = gs.arvore_mapa().filter(func(x): return x.id == "body_jab")[0]
	checar(item.next_campaign and item.state == "owned", "cartão: VALE NA PRÓXIMA CAMPANHA")
	gs.aposentar()
	gs.nova_carreira()
	checar(absf(gs.por_clique() - antes * 2.0) < 1e-9, "depois da NOVA CAMPANHA o Jab (+100%) vale")
	checar("body_jab" in gs.nos_ativos(), "foto tirada")
	_liberar(gs)


func _teste_efeitos_de_inicio() -> void:
	var gs := _com_nos("f54_ini", ["gar_rope", "gar_metro", "gar_crew_start", "camp_extra_day"])
	checar(gs.aparelho_montado("jump_rope") and not gs.tem_caixa("jump_rope"), "corda já montada, sem caixa")
	checar(not gs.aparelho_montado("treadmill"), "a esteira continua na compra")
	checar_igual(gs.nivel_metronomo, 2, "Metrônomo começa no nível 2")
	checar_igual(gs.quantidade_gerador("neighbor_kid"), 5, "5 Vizinhos de saída")
	var base := _com_nos("f54_ini0", [])
	checar(gs.custo_gerador("neighbor_kid") > base.custo_gerador("neighbor_kid"), "o preço do próximo segue a curva (qtd 5)")
	checar_igual(gs.fight_day, base.fight_day + 1, "+1 dia na data da luta")
	checar_igual(base.nivel_metronomo, 0, "sem nós: Metrônomo 0")
	checar(not base.aparelho_montado("jump_rope"), "sem nós: corda na compra")
	checar_igual(gs._data_da_proxima_luta(), gs.dia_campanha() + int(gs.lutas.adversarios[0].prep_days) + 1, "prep +1")
	_liberar(gs)
	_liberar(base)


func _teste_efeitos_de_jogo() -> void:
	# Grito mais alto: só com o Grito da loja comprado.
	var gs := _com_nos("f54_grito", ["gar_rope", "link_shout"])
	gs.geradores["neighbor_kid"] = 10
	gs.crew_click_comprado = false
	checar_igual(gs.bonus_crew_click(), 0.0, "sem o Grito da loja: 0")
	gs.crew_click_comprado = true
	var esperado: float = (float(gs.lutas.crew_click.crew_share) + 0.5) * gs.producao_total()
	checar(absf(gs.bonus_crew_click() - esperado) < 1e-9, "Grito 1,0 -> 1,5 s da equipe")
	_liberar(gs)
	# Academia x2,5
	var g2 := _com_nos("f54_gym", ["gym_fan"], ["boxing", "bjj"])
	g2.local_id = "gym"
	checar(absf(g2.mult_local() - 2.0 * 1.25) < 1e-9, "academia x2 -> x2,5")
	g2.local_id = "garage"
	checar_igual(g2.mult_local(), 1.0, "garagem continua x1")
	_liberar(g2)
	# Caderno do velho: +15% de Legado, arredondando para baixo
	var g3 := _com_nos("f54_diario", ["camp_diary"])
	g3.fama = 100
	var pote: int = g3.legado_em_jogo()
	var antes: int = g3.legado_disponivel()
	var fim: Dictionary = g3.aposentar()
	checar_igual(fim.legacy_gained, int(floor(pote * 1.15 + 1.0e-9)), "Legado x1,15 (floor)")
	checar_igual(g3.legado_disponivel(), antes + fim.legacy_gained, "o Legado soma o valor com bônus")
	checar(fim.legacy_notebook > 0, "a tela de fim sabe quanto veio do caderno")
	_liberar(g3)
	# Derrota também leva o bônus
	var g4 := _com_nos("f54_diario2", ["camp_diary"])
	g4.fama = 100
	checar_igual(g4.legado_se_perder(), int(floor(floor(g4.legado_em_jogo() * g4.parte_derrota()) * 1.15 + 1.0e-9)), "derrota também x1,15")
	_liberar(g4)


func _teste_artes() -> void:
	var nos := ["body_jab", "box_counter", "box_footwork", "bjj_guard", "bjj_breath"]
	var arts := ["boxing", "bjj"]
	var sem := _com_nos("f54_art0", [], arts)
	sem.escolher_arte("boxing")
	var dano0: float = sem.motor.traco.damage_mult
	var rec0: float = sem.academia.arte("bjj").fight.taken_mult
	var bx := _com_nos("f54_art1", nos, arts)
	bx.escolher_arte("boxing")
	checar(absf(bx.motor.traco.damage_mult - dano0 * 1.1) < 1e-9, "Contragolpe: dano x1,10 (1,10 -> 1,21)")
	checar_igual(bx.motor.traco.taken_mult, 1.0, "Boxe não mexe no dano recebido")
	checar(absf(bx._b("click_bonus") - 1.25) < 1e-9, "Jogo de pernas vale no Boxe")
	checar_igual(bx._b("passive_bonus"), 0.0, "Respirar fundo (JJ) não vale no Boxe")
	var jj := _com_nos("f54_art2", nos, arts)
	jj.escolher_arte("bjj")
	checar(absf(jj.motor.traco.taken_mult - rec0 * 0.9) < 1e-9, "Base firme: recebido x0,90 (0,90 -> 0,81)")
	checar_igual(jj._b("click_bonus"), 1.0, "Jogo de pernas não vale no JJ (só o Jab)")
	checar(absf(jj._b("passive_bonus") - 0.25) < 1e-9, "Respirar fundo vale no JJ")
	checar_igual(bx.texto_traco_luta("boxing"), bx.preencher(str(bx.academia.arte("boxing").fight_text), {"pct": 21}), "texto do traço: Boxe +21%")
	checar_igual(jj.texto_traco_luta("bjj"), jj.preencher(str(jj.academia.arte("bjj").fight_text), {"pct": 19}), "texto do traço: JJ -19%")
	checar(jj.texto_efeito_no(jj.lutas.no_da_arvore("link_shout")).contains("0.5"), "Grito +0.5 vem do formatador")
	for g in [sem, bx, jj]:
		_liberar(g)


func _teste_legado() -> void:
	var gs := _novo("f54_legado")
	gs.permanente["legacy_total"] = 1000
	var comprados := 0
	for id in ["body_jab", "gar_tape", "gar_rope"]:
		if gs.comprar_no(id):
			comprados += int(gs.lutas.no_da_arvore(id).cost)
	checar_igual(gs.legado_disponivel(), 1000 - comprados, "Legado exato descontado")
	checar(not gs.comprar_no("body_jab"), "não compra duas vezes")
	checar(not gs.comprar_no("camp_extra_day"), "não compra nó escondido")
	checar(not gs.comprar_no("nao_existe"), "id inexistente recusado")
	_liberar(gs)


func _teste_mapa_api() -> void:
	var gs := _novo("f54_api")
	var mapa: Array = gs.arvore_mapa()
	checar_igual(mapa.size(), 39, "arvore_mapa traz os 39 nós")
	var n: Dictionary = mapa.filter(func(x): return x.id == "link_shout")[0]
	checar(n.needs_shout and n.pos is Vector2 and n.state == "hidden", "campos do mapa (needs_shout, pos, state)")
	var info: Dictionary = gs.arvore_mapa_info()
	checar(info.unit_px == 40.0 and info.regions.size() == 9, "info do mapa")
	_liberar(gs)


func _abrir(pasta: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	return gs


func _teste_save_v10() -> void:
	checar_igual(SaveStore.VERSAO_ATUAL, 11, "save v11")
	var pasta := pasta_limpa("f54_save")
	var gs := _abrir(pasta)
	gs.permanente["legacy_total"] = 10
	gs.comprar_no("body_jab")
	gs.salvar()
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	checar(int(doc.version) == 11 and doc.state.career.active_nodes == [] and doc.state.permanent.tree_last_node == "body_jab",
		"active_nodes e tree_last_node no arquivo")
	gs.free()
	# migração v9: nós ficam, active = nós, sem reembolso
	var v9 := {"version": 9, "saved_at_unix": 1730000000, "state": {"career": {"training": 5.0},
		"permanent": {"legacy_total": 77, "career_number": 2, "skill_nodes": ["body_jab", "body_crew"], "arts_unlocked": []}, "ending": null}}
	escrever(pasta + "save.json", JSON.stringify(v9))
	var g2 := _abrir(pasta)
	checar_igual(g2.permanente.skill_nodes, ["body_jab", "body_crew"], "v9: nós ficam")
	checar_igual(g2.nos_ativos(), ["body_jab", "body_crew"], "v9: a campanha atual já tinha os nós")
	checar_igual(g2.legado_disponivel(), 77, "v9: sem reembolso nem cobrança")
	checar_igual(g2.permanente.tree_last_node, "body_crew", "v9: último nó")
	checar_igual(g2.estado_mapa("gar_tape"), "visible", "v9: vizinho abre sozinho")
	checar(absf(g2._b("passive_bonus") - 0.5) < 1e-9, "v9: bônus continuam valendo")
	g2.free()
	# v9 sem nós
	escrever(pasta + "save.json", JSON.stringify({"version": 9, "saved_at_unix": 1, "state": {"career": {}, "permanent": {}}}))
	var g3 := _abrir(pasta)
	checar(g3.nos_ativos().is_empty() and g3.permanente.tree_last_node == "", "v9 sem nós")
	g3.free()
	# id desconhecido
	escrever(pasta + "save.json", JSON.stringify({"version": 10, "saved_at_unix": 1, "state": {"career": {"active_nodes": ["lixo", "body_jab", "gar_tape"]},
		"permanent": {"skill_nodes": ["body_jab", "lixo"], "tree_last_node": "lixo"}}}))
	var g4 := _abrir(pasta)
	checar_igual(g4.nos_ativos(), ["body_jab"], "active_nodes só com nós comprados e conhecidos")
	checar_igual(g4.permanente.tree_last_node, "body_jab", "tree_last_node inválido volta ao último comprado")
	g4.free()


# Mudar custo/valor no JSON muda o jogo sem código.
func _teste_dados_no_json() -> void:
	var pasta := pasta_limpa("f54_json")
	escrever(pasta + "tree.json", '{"version": 2, "regions": [{"id": "r", "name": "R", "lock": ""}], "nodes": ['
		+ '{"id": "a", "region": "r", "pos": [0, 0], "root": true, "neighbors": ["b"], "cost": 3, "effect": {"type": "click_bonus", "value": 4}},'
		+ '{"id": "b", "region": "r", "pos": [1, 0], "neighbors": ["a"], "cost": 2, "effect": {"type": "legacy_bonus", "value": 0.5}},'
		+ '{"id": "c", "region": "r", "pos": [2, 0], "neighbors": [], "cost": 2, "effect": {"type": "click_bonus", "value": 1}}]}')
	var d := FightData.carregar(FightData.CAMINHO_LUTAS, FightData.CAMINHO_ADVERSARIOS, FightData.CAMINHO_LOJA,
		FightData.CAMINHO_CARREIRA, pasta + "tree.json")
	checar_igual(d.arvore.size(), 3, "árvore de teste carregada")
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa("f54_json_jogo"), "res://data/config.json", TrainingData.CAMINHO_TREINO,
		TrainingData.CAMINHO_GERADORES, TrainingData.CAMINHO_TEXTOS, d)
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.permanente["legacy_total"] = 3
	checar(gs.comprar_no("a"), "preço do JSON (3)")
	checar_igual(gs.estado_mapa("c"), "hidden", "nó sem caminho fica escondido")
	var base: float = gs.por_clique()
	gs.aposentar()
	gs.nova_carreira()
	checar(absf(gs.por_clique() - base * 5.0) < 1e-9, "valor do JSON (+400%) -> clique x5")
	_liberar(gs)
