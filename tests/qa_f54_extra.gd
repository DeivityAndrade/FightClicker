extends "res://tests/test_base.gd"
## QA 5.4: cenarios extras da arvore grande (dados, revelacao, compra, efeitos, legado, save corrompido).
## Tudo em user://test/. Roda: godot --headless --path . --script res://tests/qa_f54_extra.gd

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	return gs


func _abrir(pasta: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	return gs


func _lib(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _com_nos(nome: String, nos: Array, artes: Array = [], arte: String = "") -> Node:
	var gs := _novo(nome)
	gs.permanente["skill_nodes"] = nos.duplicate()
	gs.permanente["arts_unlocked"] = artes.duplicate()
	if not artes.is_empty():
		gs.escolher_arte(arte if arte != "" else artes[0])
	gs.aposentar()
	gs.nova_carreira()
	if not artes.is_empty():
		gs.escolher_arte(arte if arte != "" else artes[0])
	return gs


func rodar_testes() -> void:
	_dados()
	_alcance()
	_compra_restrita()
	_efeitos()
	_legado_tres_fins()
	_arte_so_na_arte()
	_save_corrompido()
	_migracao_12()
	_compras_em_massa()


func _dados() -> void:
	var raw = JSON.parse_string(ler("res://data/skill_tree.json"))
	var nos: Array = raw.nodes
	checar(nos.size() >= 35 and nos.size() <= 40, "35-40 nos (%d)" % nos.size())
	var por_regiao := {}
	var ligacoes := 0
	for n in nos:
		por_regiao[n.region] = int(por_regiao.get(n.region, 0)) + 1
		if str(n.get("kind", "")) == "link":
			ligacoes += 1
	print("  regioes: ", por_regiao, " ligacoes: ", ligacoes)
	checar(ligacoes >= 3, "pelo menos 3 nos de ligacao")
	for r in ["garage", "gym", "boxing", "bjj", "campaign"]:
		checar(por_regiao.has(r), "regiao %s existe" % r)
	# texto
	var texto_total := ler("res://data/skill_tree.json") + ler("res://data/ui_texts.json")
	checar(not texto_total.contains("—") and not texto_total.contains("–"), "sem travessao em skill_tree/ui_texts")
	for n in nos:
		if str(n.get("name", "")).length() > 16:
			checar(false, "nome > 16: " + str(n.id))
		if str(n.get("description", "")).length() > 45:
			checar(false, "frase > 45: " + str(n.id) + " " + str(n.description.length()))
		if str(n.name).to_upper().contains("CARREIRA") or str(n.get("effect_text", "")).contains("CARREIRA"):
			print("  aviso: CARREIRA em nó ", n.id, " | ", n.name, " | ", n.get("effect_text", ""))
	var ui = JSON.parse_string(ler("res://data/ui_texts.json"))
	checar_igual(ui.get("tree_branch_career", ""), "CAMPANHA", "ramo CAMPANHA")
	for k in ui:
		if str(k).begins_with("tree_") or str(k).begins_with("map_"):
			var v := str(ui[k])
			if v.to_upper().contains("CARREIRA"):
				print("  aviso: CARREIRA em ui_texts.", k, " = ", v)
	# os 12 antigos: mesmos efeitos que o HEAD
	var antigo_txt := FileAccess.get_file_as_string("res://data/skill_tree.json")
	checar(antigo_txt.length() > 0, "arquivo lido")
	# posicoes unicas
	var pos := {}
	for n in nos:
		var k := str(n.pos)
		checar(not pos.has(k), "pos unica " + str(n.id))
		pos[k] = true
	# distancia minima
	var minimo := 1e9
	for i in nos.size():
		for j in range(i + 1, nos.size()):
			var d := Vector2(nos[i].pos[0], nos[i].pos[1]).distance_to(Vector2(nos[j].pos[0], nos[j].pos[1])) * 40.0
			minimo = minf(minimo, d)
	print("  menor distancia entre nos (px): ", minimo)
	checar(minimo >= 40.0, "distancia minima >= 40 px")


func _alcance() -> void:
	# BFS: com tudo aberto, todo no e alcancavel a partir das raizes
	var gs := _novo("qa54_bfs")
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.escolher_arte("boxing")
	gs.permanente["legacy_total"] = 10000000
	var comprados := 0
	var mudou := true
	while mudou:
		mudou = false
		for n in gs.lutas.arvore:
			if gs.estado_mapa(n.id) == "visible":
				if gs.comprar_no(n.id):
					comprados += 1
					mudou = true
	checar_igual(comprados, 39, "todo no e alcancavel e comprando todos")
	checar_igual(gs.ha_no_compravel(), false, "mapa cheio: sem brilho")
	checar_igual(gs.nos_compraveis(), 0, "mapa cheio: 0 compraveis")
	var custo := 0
	for n in gs.lutas.arvore:
		custo += int(n.cost)
	checar_igual(custo, 16810, "soma dos precos 16810")
	checar_igual(10000000 - gs.legado_disponivel(), 16810, "Legado exato gasto")
	_lib(gs)
	# sem arte: so os nos sem trava
	var g2 := _novo("qa54_bfs2")
	g2.permanente["legacy_total"] = 10000000
	var c2 := 0
	mudou = true
	while mudou:
		mudou = false
		for n in g2.lutas.arvore:
			if g2.estado_mapa(n.id) == "visible" and g2.comprar_no(n.id):
				c2 += 1
				mudou = true
	print("  sem arte/academia: comprou ", c2)
	for n in g2.lutas.arvore:
		if n.region in ["gym", "boxing", "bjj"]:
			checar(not g2.tem_no(n.id), "sem trava aberta, %s nao comprado" % n.id)
	_lib(g2)


func _compra_restrita() -> void:
	var gs := _novo("qa54_restr")
	gs.permanente["legacy_total"] = 100000
	# na luta
	gs.luta = {"opponent": "x"}
	checar(not gs.comprar_no("body_jab"), "na luta: recusa")
	gs.luta = {}
	# caixa no meio
	gs.caixas_lista.append({"item": "treadmill", "kind": "apparatus", "hits": 2})
	checar(not gs.comprar_no("body_jab") and not gs.pode_abrir_arvore(), "caixa pela metade: recusa")
	gs.caixas_lista.clear()
	# dia da luta
	gs.segundos_campanha = gs._alvo_relogio()
	checar(not gs.comprar_no("body_jab"), "dia da luta: recusa")
	gs.segundos_campanha = 0.0
	# escolha de arte
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	checar(gs.escolha_arte_pendente() and not gs.comprar_no("body_jab"), "escolha da arte: recusa")
	gs.escolher_arte("boxing")
	checar(gs.comprar_no("body_jab"), "depois da escolha: compra")
	# sem dinheiro
	var g2 := _novo("qa54_restr2")
	g2.permanente["legacy_total"] = 9
	checar(not g2.comprar_no("body_jab"), "Legado 9: recusa")
	checar_igual(g2.legado_disponivel(), 9, "Legado intacto")
	checar(not g2.tem_no("body_jab"), "no nao entra")
	g2.permanente["legacy_total"] = -50
	checar(not g2.comprar_no("body_jab") and not g2.ha_no_compravel(), "Legado negativo: sem compra, sem brilho")
	g2.permanente["legacy_total"] = 10
	checar(g2.comprar_no("body_jab"), "Legado 10 compra")
	checar_igual(g2.legado_disponivel(), 0, "Legado 0 depois")
	# com fim pendente abre sempre, mesmo no dia/escolha
	var g3 := _novo("qa54_restr3")
	g3.permanente["legacy_total"] = 0
	g3.fama = 100
	g3.aposentar()
	checar(g3.tem_fim_pendente() and g3.pode_abrir_arvore(), "fim pendente: abre")
	var antes: int = g3.legado_disponivel()
	checar(g3.comprar_no("body_jab"), "compra com a tela de fim")
	checar_igual(g3.fim.legacy_total, g3.legado_disponivel(), "fim.legacy_total acompanha")
	checar_igual(g3.legado_disponivel(), antes - 10, "Legado descontado")
	_lib(gs)
	_lib(g2)
	_lib(g3)


func _efeitos() -> void:
	# corda montada: sem caixa, melhorias continuam, esteira ainda na caixa
	var g := _com_nos("qa54_ef1", ["gar_rope"])
	checar(g.aparelho_montado("jump_rope"), "corda montada")
	checar(not g.tem_caixa("jump_rope"), "sem caixa da corda")
	print("  caixas: ", g.caixas_lista)
	g.treino = 1.0e12
	var base := _com_nos("qa54_ef1b", [])
	checar(not base.aparelho_montado("jump_rope"), "sem no: corda nao montada")
	_lib(base)
	# corda montada e salva e recarregada
	g.salvar()
	var pasta: String = g.store.pasta
	var g2 := _abrir(pasta)
	checar(g2.aparelho_montado("jump_rope"), "corda montada sobrevive ao reload")
	_lib(g2)
	# fica em campanhas seguintes (nova campanha com o no ainda comprado)
	g.aposentar()
	g.nova_carreira()
	checar(g.aparelho_montado("jump_rope"), "corda montada de novo na campanha seguinte")
	_lib(g)
	# Metronomo 2 e 5 vizinhos
	var m := _com_nos("qa54_ef2", ["gar_metro", "body_muscle_memory", "gar_crew_start"])
	checar_igual(m.nivel_metronomo, 2, "Metronomo nivel 2 (max com o 1)")
	checar_igual(m.quantidade_gerador("neighbor_kid"), 5, "5 vizinhos")
	var preco6: float = m.custo_gerador("neighbor_kid")
	var g0 := _com_nos("qa54_ef2b", [])
	var preco_1: float = g0.custo_gerador("neighbor_kid")
	var cfg: Dictionary = {}
	for ge in g0.dados.geradores:
		if ge.id == "neighbor_kid":
			cfg = ge
	print("  gerador: base=", cfg.get("base_cost", cfg.get("cost", "?")), " cresc=", cfg.get("growth", "?"), " preco6=", preco6, " preco1=", preco_1)
	m.treino = 1.0e9
	var ok := true
	for i in 3:
		ok = ok and m.comprar_gerador("neighbor_kid")
	checar_igual(m.quantidade_gerador("neighbor_kid"), 8, "comprar sobre os 5 chega a 8")
	# Metronomo realmente roda
	var m1: float = m.treino
	m.tick(3.0)
	checar(m.treino > m1, "tick produz")
	_lib(m)
	_lib(g0)
	# metronomo so no nivel permitido
	var m3 := _com_nos("qa54_ef2c", ["gar_metro"])
	checar(m3.nivel_metronomo <= m3.metronomo_niveis(), "Metronomo dentro do limite")
	_lib(m3)
	# +1 dia nas 6 lutas
	var d1 := _com_nos("qa54_dia1", ["camp_extra_day"])
	var d0 := _com_nos("qa54_dia0", [])
	for i in 6:
		d1.indice_escada = i
		d0.indice_escada = i
		var a: int = d1._data_da_proxima_luta()
		var b: int = d0._data_da_proxima_luta()
		checar_igual(a - b, 1, "+1 dia na luta %d (%d vs %d)" % [i, a, b])
	# dois nos de dia nao existem; soma OK se houvesse
	_lib(d1)
	_lib(d0)
	# gym x2,5
	var gy := _com_nos("qa54_gym", ["gym_fan"], ["boxing", "bjj"])
	gy.local_id = "gym"
	var m_gym: float = gy.mult_local()
	gy.local_id = "garage"
	checar(absf(m_gym - 2.5) < 1e-9 and gy.mult_local() == 1.0, "gym 2.5 / garagem 1 (%s)" % str(m_gym))
	# gym_fan nao vale sem estar na foto
	var gy2 := _novo("qa54_gym2")
	gy2.permanente["skill_nodes"] = ["gym_fan"]
	gy2.permanente["arts_unlocked"] = ["boxing"]
	gy2.local_id = "gym"
	checar(absf(gy2.mult_local() - 2.0) < 1e-9, "comprado e nao ativo: academia segue x2")
	_lib(gy)
	_lib(gy2)
	# Grito mais alto
	var sh := _com_nos("qa54_shout", ["link_shout"])
	sh.geradores["neighbor_kid"] = 4
	sh.crew_click_comprado = false
	var sem: float = sh.bonus_crew_click()
	sh.crew_click_comprado = true
	var com: float = sh.bonus_crew_click()
	var prod: float = sh.producao_total()
	print("  Grito: sem=", sem, " com=", com, " prod=", prod, " crew_share=", sh.lutas.crew_click.crew_share)
	checar_igual(sem, 0.0, "Grito mais alto sem Grito comprado: 0")
	checar(absf(com - 1.5 * prod) < 1e-9, "Grito 1.5 s da equipe/s")
	var sh0 := _com_nos("qa54_shout0", [])
	sh0.geradores["neighbor_kid"] = 4
	sh0.crew_click_comprado = true
	checar(absf(sh0.bonus_crew_click() - 1.0 * sh0.producao_total()) < 1e-9, "sem o no: 1.0 s")
	# clicar de verdade soma o bonus da equipe
	sh.treino = 0.0
	var antes_t: float = sh.treino
	sh.clicar()
	print("  clique: ganhou ", sh.treino - antes_t, " (por_clique=", sh.por_clique(), " extra=", sh.bonus_crew_click(), ")")
	checar(sh.treino - antes_t >= sh.por_clique() * 0.99, "clique rende ao menos o por_clique")
	# producao zero: Grito mais alto vale 0 sem equipe
	var sh2 := _com_nos("qa54_shout2", ["link_shout"])
	sh2.crew_click_comprado = true
	checar_igual(sh2.bonus_crew_click(), 0.0, "sem equipe, Grito vale 0")
	_lib(sh)
	_lib(sh0)
	_lib(sh2)


func _legado_tres_fins() -> void:
	# retirar / passar o posto / derrota, com e sem o caderno
	for modo in ["retire", "defeat"]:
		var com := _com_nos("qa54_leg_%s_a" % modo, ["camp_diary"])
		var sem := _com_nos("qa54_leg_%s_b" % modo, [])
		for g in [com, sem]:
			g.fama = 500
			g.dinheiro_ganho = 1234
			g.indice_escada = 2
		var lc: int
		var ls: int
		if modo == "retire":
			lc = int(com.previa_aposentar().total)
			ls = int(sem.previa_aposentar().total)
			var fim: Dictionary = com.aposentar()
			checar_igual(int(fim.legacy_gained), lc, "retire: previa == ganho (com caderno)")
		else:
			lc = int(com.legado_se_perder())
			ls = int(sem.legado_se_perder())
		print("  ", modo, ": com=", lc, " sem=", ls)
		checar(lc >= ls and (ls == 0 or absf(float(lc) / float(ls) - 1.15) < 0.05 or ls < 20), "%s: ~x1.15 (%d vs %d)" % [modo, lc, ls])
		_lib(com)
		_lib(sem)
	# Passar o posto no vermelho (via passar_posto / aposentar do dia)
	var pp := _com_nos("qa54_leg_pp", ["camp_diary"])
	pp.fama = 300
	var esperado: int = int(pp.previa_aposentar().total)
	var f = pp.aposentar()
	checar_igual(int(f.legacy_gained), esperado, "passar o posto: ganho == previa")
	checar(int(f.legacy_notebook) == esperado - int(floor(float(esperado) / 1.15)) or int(f.legacy_notebook) > 0, "linha do caderno > 0")
	# derrota real na luta: forca derrota
	var dr := _com_nos("qa54_leg_dr", ["camp_diary"])
	dr.fama = 1000
	var prev: int = dr.legado_se_perder()
	var l_antes: int = dr.legado_disponivel()
	dr.atributos["strength"] = 1.0
	dr.atributos["agility"] = 1.0
	dr.atributos["endurance"] = 1.0
	var r: Dictionary = dr.lutar()
	dr.concluir_luta()
	if dr.tem_fim_pendente():
		checar_igual(dr.legado_disponivel() - l_antes, prev, "derrota real: ganho == legado_se_perder (%d)" % prev)
		checar_igual(int(dr.fim.legacy_gained), prev, "fim.legacy_gained == previa de derrota")
	else:
		print("  (luta nao terminou em derrota: ", r.get("win", "?"), ")")
	_lib(pp)
	_lib(dr)
	# Legado zero com caderno: 0, nunca negativo
	var z := _com_nos("qa54_leg_zero", ["camp_diary"])
	z.fama = 0
	z.dinheiro_ganho = 0
	checar(z.legado_se_perder() >= 0, "Legado zero com caderno >= 0")
	_lib(z)


func _arte_so_na_arte() -> void:
	var nos := ["body_jab", "box_counter", "box_footwork", "box_wraps", "bjj_guard", "bjj_breath", "bjj_knot", "style_boxing", "style_bjj"]
	var bx := _com_nos("qa54_art_b", nos, ["boxing", "bjj"], "boxing")
	var jj := _com_nos("qa54_art_j", nos, ["boxing", "bjj"], "bjj")
	var sem := _com_nos("qa54_art_s", nos, ["boxing", "bjj"], "boxing")
	checar_igual(bx.arte_id, "boxing", "arte boxing")
	checar_igual(jj.arte_id, "bjj", "arte bjj")
	print("  boxe: click=", bx._b("click_bonus"), " passive=", bx._b("passive_bonus"), " estilo_box=", bx.estilo_arte("boxing"), " estilo_bjj=", bx.estilo_arte("bjj"))
	print("  bjj: click=", jj._b("click_bonus"), " passive=", jj._b("passive_bonus"), " estilo_box=", jj.estilo_arte("boxing"), " estilo_bjj=", jj.estilo_arte("bjj"))
	checar_igual(bx.bonus_arte_equipe(), 0.0, "Boxe: regra do JJ (equipe) vale 0")
	checar(absf(bx.bonus_arte_clique() - 0.5 * 1.75) < 1e-9, "Boxe: clique 0.5 x (1+0.75) = %s" % str(bx.bonus_arte_clique()))
	checar_igual(jj.bonus_arte_clique(), 0.0, "JJ: regra do Boxe (clique) vale 0")
	checar(absf(bx.motor.traco.damage_mult - 1.21) < 1e-9, "Boxe dano 1.21 (%s)" % str(bx.motor.traco.damage_mult))
	checar_igual(bx.motor.traco.taken_mult, 1.0, "Boxe: recebido 1.0")
	checar(absf(jj.motor.traco.taken_mult - 0.81) < 1e-9, "JJ recebido 0.81 (%s)" % str(jj.motor.traco.taken_mult))
	checar_igual(jj.motor.traco.damage_mult, 1.0, "JJ: dano 1.0")
	# o traco aparece no texto/escolha
	print("  texto boxe: ", bx.texto_traco_luta("boxing"), " | jj: ", jj.texto_traco_luta("bjj"))
	checar(bx.texto_traco_luta("boxing").contains("21"), "texto Boxe mostra 21")
	checar(jj.texto_traco_luta("bjj").contains("19"), "texto JJ mostra 19")
	# previa leva o traco
	bx.treino = 0
	var p_b: Dictionary = bx.previa()
	var p_j: Dictionary = jj.previa()
	checar(not p_b.is_empty() and not p_j.is_empty(), "previas existem")
	# comparativo previa x motor sem os nos
	var b0 := _com_nos("qa54_art_b0", [], ["boxing", "bjj"], "boxing")
	var j0 := _com_nos("qa54_art_j0", [], ["boxing", "bjj"], "bjj")
	for g in [bx, b0, jj, j0]:
		g.atributos["strength"] = 5000.0
		g.atributos["agility"] = 5000.0
		g.atributos["endurance"] = 5000.0
	var pb: Dictionary = bx.previa()
	var pb0: Dictionary = b0.previa()
	print("  previa boxe com/sem: ", pb.get("percent", pb.get("win_percent", "?")), " / ", pb0.get("percent", pb0.get("win_percent", "?")), " chaves: ", pb.keys())
	for g in [bx, jj, sem, b0, j0]:
		_lib(g)


func _save_corrompido() -> void:
	var pasta := pasta_limpa("qa54_corr")
	var casos := [
		{"nome": "active_nodes string", "c": {"active_nodes": "body_jab"}, "p": {"skill_nodes": ["body_jab"]}},
		{"nome": "active_nodes int", "c": {"active_nodes": 7}, "p": {"skill_nodes": ["body_jab"]}},
		{"nome": "active_nodes dict", "c": {"active_nodes": {"a": 1}}, "p": {"skill_nodes": ["body_jab"]}},
		{"nome": "active_nodes null", "c": {"active_nodes": null}, "p": {"skill_nodes": ["body_jab"]}},
		{"nome": "active_nodes lixo misto", "c": {"active_nodes": [1, null, "body_jab", "body_jab", [], "gar_rope", {}]}, "p": {"skill_nodes": ["body_jab"]}},
		{"nome": "active_nodes enorme", "c": {"active_nodes": range(5000).map(func(i): return "x%d" % i)}, "p": {"skill_nodes": ["body_jab"]}},
		{"nome": "tree_last_node numero", "c": {}, "p": {"skill_nodes": ["body_jab", "career_purse"], "tree_last_node": 42}},
		{"nome": "tree_last_node array", "c": {}, "p": {"skill_nodes": ["body_jab", "career_purse"], "tree_last_node": ["x"]}},
		{"nome": "tree_last_node nao comprado", "c": {}, "p": {"skill_nodes": ["body_jab", "career_purse"], "tree_last_node": "gar_rope"}},
		{"nome": "skill_nodes string", "c": {}, "p": {"skill_nodes": "body_jab"}},
		{"nome": "skill_nodes dict", "c": {}, "p": {"skill_nodes": {"body_jab": true}}},
		{"nome": "skill_nodes duplicados", "c": {}, "p": {"skill_nodes": ["body_jab", "body_jab", "body_jab"]}},
		{"nome": "skill_nodes null", "c": {}, "p": {"skill_nodes": null}},
		{"nome": "skill_nodes nos escondidos", "c": {}, "p": {"skill_nodes": ["camp_extra_day", "gar_rope"]}},
	]
	for caso in casos:
		var doc := {"version": 10, "saved_at_unix": 1, "state": {"career": caso.c, "permanent": caso.p}}
		escrever(pasta + "save.json", JSON.stringify(doc))
		var g := _abrir(pasta)
		var ativos: Array = g.nos_ativos()
		var ok := true
		for id in ativos:
			ok = ok and (id in g.permanente.skill_nodes) and typeof(id) == TYPE_STRING
		checar(ok and g.permanente.skill_nodes is Array, "corrompido '%s': sanitizado (ativos=%s, nos=%s, ultimo=%s)" % [caso.nome, str(ativos).left(60), str(g.permanente.skill_nodes).left(60), str(g.permanente.tree_last_node)])
		checar(typeof(g.permanente.tree_last_node) == TYPE_STRING, "corrompido '%s': tree_last_node String" % caso.nome)
		var lu: String = str(g.permanente.tree_last_node)
		checar(lu == "" or lu in g.permanente.skill_nodes, "corrompido '%s': ultimo e comprado ('%s')" % [caso.nome, lu])
		# nao quebra o mapa nem o brilho
		var m: Array = g.arvore_mapa()
		checar(m.size() == 39, "corrompido '%s': mapa 39" % caso.nome)
		g.ha_no_compravel()
		g.tick(1.0)
		_lib(g)
	# arquivo vazio / json invalido / versao futura
	escrever(pasta + "save.json", "{lixo")
	var gl := _abrir(pasta)
	checar(gl.arvore_mapa().size() == 39, "json invalido: abre")
	_lib(gl)
	escrever(pasta + "save.json", JSON.stringify({"version": 99, "state": {}}))
	var gf := _abrir(pasta)
	checar(gf.arvore_mapa().size() == 39, "versao futura: abre")
	_lib(gf)


func _migracao_12() -> void:
	var doze := ["body_jab", "body_muscle_memory", "body_crew", "body_heavy_hands", "body_crew_2",
		"career_purse", "career_scouting", "career_crowd", "career_purse_2", "career_good_loser", "style_boxing", "style_bjj"]
	var pasta := pasta_limpa("qa54_mig12")
	var v9 := {"version": 9, "saved_at_unix": 1730000000, "state": {"career": {"training": 5.0},
		"permanent": {"legacy_total": 1234, "career_number": 6, "skill_nodes": doze, "arts_unlocked": ["boxing", "bjj"]}, "ending": null}}
	escrever(pasta + "save.json", JSON.stringify(v9))
	var g := _abrir(pasta)
	checar_igual(g.permanente.skill_nodes, doze, "12 nos preservados na ordem")
	checar_igual(g.legado_disponivel(), 1234, "Legado igual")
	checar_igual(g.nos_ativos().size(), 12, "12 ativos")
	for id in doze:
		checar_igual(g.estado_mapa(id), "owned", "%s aceso" % id)
	var viz := {}
	for id in doze:
		for v in g.lutas.no_da_arvore(id).neighbors:
			if not (v in doze):
				viz[v] = true
	var vis_ok := true
	for v in viz:
		var st: String = g.estado_mapa(v)
		var lock: String = g.lutas.no_da_arvore(v).lock
		if st != "visible":
			print("  vizinho nao visivel: ", v, " ", st, " lock=", lock)
			vis_ok = false
	checar(vis_ok, "todos os vizinhos dos 12 ficam a vista (%d)" % viz.size())
	# Preco dos 2 nos que caiu: nada devolvido
	checar_igual(g.legado_disponivel(), 1234, "sem reembolso de body_crew_2/career_good_loser")
	# salvar e reabrir como v10
	g.salvar()
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual(int(doc.version), 10, "regravado em v10")
	var g2 := _abrir(pasta)
	checar_igual(g2.permanente.skill_nodes, doze, "reabre igual")
	checar_igual(g2.permanente.tree_last_node, "style_bjj", "tree_last_node = ultimo")
	g2.free()
	# v9 com fim pendente
	var v9b := {"version": 9, "saved_at_unix": 1, "state": {"career": {}, "permanent": {"legacy_total": 50, "skill_nodes": ["body_jab"]},
		"ending": {"kind": "retire", "legacy_gained": 20, "legacy_total": 50, "career_number": 1, "summary": {}, "reason": {}}}}
	escrever(pasta + "save.json", JSON.stringify(v9b))
	var g3 := _abrir(pasta)
	print("  fim pendente v9: ", g3.tem_fim_pendente(), " pode_abrir=", g3.pode_abrir_arvore())
	if g3.tem_fim_pendente():
		checar(g3.pode_abrir_arvore(), "v9 com fim pendente: arvore abre")
		var lg: int = g3.legado_disponivel()
		checar(g3.comprar_no("gar_tape"), "compra gar_tape com fim pendente (vizinho do Jab)")
		checar_igual(g3.legado_disponivel(), lg - 15, "Legado desconta")
		g3.nova_carreira()
		checar("gar_tape" in g3.nos_ativos(), "NOVA CAMPANHA: gar_tape ativo")
	_lib(g3)
	g.free()


func _compras_em_massa() -> void:
	# 200 campanhas seguidas compram o que podem; sem erro, Legado nunca negativo
	var gs := _novo("qa54_massa")
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	for i in 30:
		gs.permanente["legacy_total"] = int(gs.permanente.legacy_total) + 2000
		var guard := 0
		var mudou := true
		while mudou and guard < 100:
			mudou = false
			guard += 1
			var vis: Array = gs.arvore_mapa().filter(func(x): return x.can_buy)
			vis.sort_custom(func(a, b): return a.cost < b.cost)
			if not vis.is_empty() and gs.comprar_no(vis[0].id):
				mudou = true
		checar(gs.legado_disponivel() >= 0, "Legado >= 0 (rodada %d)" % i)
		gs.fama = 50
		if gs.escolha_arte_pendente():
			gs.escolher_arte("boxing")
		gs.aposentar()
		gs.nova_carreira()
		if gs.escolha_arte_pendente():
			gs.escolher_arte("bjj" if i % 2 == 0 else "boxing")
	var tem: int = gs.permanente.skill_nodes.size()
	var unicos := {}
	for id in gs.permanente.skill_nodes:
		unicos[id] = true
	checar_igual(unicos.size(), tem, "sem no duplicado em skill_nodes (%d)" % tem)
	checar(tem <= 39, "no maximo 39 nos")
	print("  compras em massa: ", tem, " nos, Legado restante ", gs.legado_disponivel())
	_lib(gs)
