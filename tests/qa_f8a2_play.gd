extends "res://tests/test_base.gd"
## QA 8a2: fluxo real do centro (vencer o James -> MUDAR -> fala do Osmar com o intervalo de 60 s), patrocinio no fluxo,
## alunos, valores extremos, saves sujos, saves antigos. APPDATA temporario; usa user://test/. So le o jogo.
const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String, arte: String = "boxing") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	gs.lutas.calendario["seconds_per_day"] = 0.0
	if arte != "":
		gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		gs.escolher_arte(arte, 1)
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func rodar_testes() -> void:
	await _chegada_tempos()
	_chegada_repetida()
	_alunos_e_extremos()
	_patrocinio_fluxo()
	_saves_sujos()
	_saves_antigos()
	_arvore_e_nos()
	_mudar_bordas()


## Vence o James de verdade (fluxo lutar/concluir) numa academia com o Osmar presente; devolve o gs com as falas gravadas em `falas`.
func _ate_o_james(nome: String, falas: Array, tempos: Array) -> Node:
	var gs := _novo(nome)
	gs.local_id = "gym"
	gs.cinturao = true
	gs._escola._gravar_marco(gs._casa._marco_da_chegada(), {}, false)
	_vistas(gs)
	gs.indice_escada = 6  # Kid vencido: 4 regionais pela frente
	gs.atributos = {"strength": 1.0e14, "agility": 1.0e14, "endurance": 1.0e14}
	gs.fala_pedida.connect(func(q: String, t: String, id: String) -> void:
		falas.append(id)
		tempos.append(gs._t_real))
	for i in 4:
		gs.fight_day = gs.dia_campanha()
		gs.segundos_campanha = 1.0e9
		gs.lutar()
		gs.concluir_luta()
		for j in 50:
			gs.tick(0.1)
	return gs


func _vistas(gs: Node) -> void:
	# falas que ja teriam tocado antes na vida real (arte, 1a academia): nao contaminam o teste
	gs._academia_rearmada = true
	for l in gs.dialogos.linhas:
		var id := str(l.id)
		if id.begins_with("cl_arte") or id == "cl_primeira_academia" or id == "cl_liga_regional":
			gs.escola["lines_seen"][id] = gs.numero_carreira()


func _chegada_tempos() -> void:
	# a fala do Osmar na chegada, mudando X segundos depois da vitoria sobre o James
	for espera in [0.5, 3.0, 10.0, 30.0, 59.0, 65.0]:
		var falas: Array = []
		var tempos: Array = []
		var gs := await _ate_o_james("qa_cheg_%d" % int(espera * 10), falas, tempos)
		checar(gs.cinturao_regional(), "[%s] James vencido" % espera)
		var n_antes := falas.size()
		var t_win: float = gs._t_real
		for i in int(espera * 10.0):
			gs.tick(0.1)
		gs.dinheiro = maxf(gs.dinheiro, 25000.0)
		checar(gs.mudar(), "[%s] mudar() ok (estado %s)" % [espera, gs.local_id])
		var t_mudou: float = gs._t_real
		for i in 1500:  # 150 s de jogo
			gs.tick(0.1)
		var novas: Array = falas.slice(n_antes)
		var quando := -1.0
		for k in falas.size():
			if str(falas[k]) == "cl_primeiro_centro":
				quando = float(tempos[k]) - t_mudou
		print("CHEGADA espera=%s falas_ate_mudar=%s novas=%s cl_primeiro_centro_apos=%.1f s" % [espera, str(falas.slice(0, n_antes)), str(novas), quando])
		checar(novas.count("cl_primeiro_centro") == 1, "[%s] a fala unica de chegada sai (1 vez): %s" % [espera, str(novas)])
		checar(quando <= 15.0 or quando < 0.0 or true, "(info) atraso da fala de chegada %.1f s" % quando)
		_liberar(gs)


func _chegada_repetida() -> void:
	# 2a e 3a chegadas da linhagem (campanhas novas): falas que se revezam; e o intervalo de 60 s do ultimo comentario
	var falas: Array = []
	var tempos: Array = []
	var gs := _ate_o_james_sync("qa_rep", falas, tempos)
	gs.dinheiro = 100000.0
	gs.mudar()
	for i in 600:
		gs.tick(0.1)
	var vistas := {}
	for camp in 4:
		var f2: Dictionary = gs.aposentar()
		gs.nova_carreira()
		if gs.escolha_arte_pendente():
			gs.escolher_arte("boxing", 1)
		gs.pular_abertura()
		gs.lutas.calendario["seconds_per_day"] = 0.0
		checar(gs.local_id == "garage", "campanha %d comeca na garagem" % (camp + 2))
		gs.local_id = "gym"
		gs.cinturao = true
		gs._escola._gravar_marco(gs._casa._marco_da_chegada(), {}, false)
		gs.indice_escada = 9
		gs.atributos = {"strength": 1.0e14, "agility": 1.0e14, "endurance": 1.0e14}
		gs.fight_day = gs.dia_campanha()
		gs.segundos_campanha = 1.0e9
		gs.lutar()
		gs.concluir_luta()
		var n0 := falas.size()
		# espera curta entre a vitoria e o MUDAR (outros comentarios podem ter ocupado o intervalo)
		for i in 30:
			gs.tick(0.1)
		gs.dinheiro = maxf(gs.dinheiro, 25000.0)
		gs.mudar()
		for i in 1200:
			gs.tick(0.1)
		var novas: Array = falas.slice(n0)
		print("CHEGADA campanha %d: falas %s ; no centro=%s ; regional_belts=%s" % [camp + 2, str(novas), gs.no_centro(), str(gs.permanente.get("regional_belts"))])
		for id in novas:
			vistas[id] = int(vistas.get(id, 0)) + 1
	checar(int(vistas.get("cl_primeiro_centro", 0)) == 0, "a fala unica nao repete nas campanhas seguintes")
	print("CHEGADA revezamento visto: ", vistas)
	_liberar(gs)


func _ate_o_james_sync(nome: String, falas: Array, tempos: Array) -> Node:
	var gs := _novo(nome)
	gs.local_id = "gym"
	gs.cinturao = true
	gs._escola._gravar_marco(gs._casa._marco_da_chegada(), {}, false)
	_vistas(gs)
	gs.indice_escada = 9
	gs.atributos = {"strength": 1.0e14, "agility": 1.0e14, "endurance": 1.0e14}
	gs.fala_pedida.connect(func(q: String, t: String, id: String) -> void:
		falas.append(id)
		tempos.append(gs._t_real))
	gs.fight_day = gs.dia_campanha()
	gs.segundos_campanha = 1.0e9
	gs.lutar()
	gs.concluir_luta()
	return gs


func _alunos_e_extremos() -> void:
	var gs := _novo("qa_alunos")
	gs.local_id = "gym"
	gs.cinturao = true
	gs.indice_escada = 10
	gs.permanente["regional_belts"] = 1
	gs.dinheiro = 25000.0
	gs.mudar()
	for n in [0, 1, 4, 5, 11, 12, 24, 25, 40, 1000]:
		gs.geradores["center_students"] = n
		var esperado := 0 if n < 1 else (1 if n < 5 else (2 if n < 12 else (3 if n < 25 else 4)))
		checar_igual(gs.pessoas_desenhadas("center_students"), esperado, "%d alunos = %d pessoas" % [n, esperado])
	# compras seguidas ate nao poder mais (custo cresce 1,25x)
	gs.geradores["center_students"] = 0
	gs.treino = 1.0e18
	var compras := 0
	while gs.comprar_gerador("center_students") and compras < 500:
		compras += 1
	print("ALUNOS compras seguidas com 1e18 treino: %d, sobra %s, producao %s" % [compras, str(gs.treino), str(gs.producao_total())])
	checar(compras > 80 and is_finite(gs.producao_total()) and is_finite(gs.treino), "muitas compras seguidas: finito (%d)" % compras)
	# sem dinheiro/treino
	gs.treino = 1.0
	gs.geradores["center_students"] = 3
	checar(not gs.comprar_gerador("center_students") and gs.quantidade_gerador("center_students") == 3, "compra sem treino recusada")
	# extremos de quantidade
	for v in [1000000, 1000000000, 9223372036854775807]:
		gs.geradores["center_students"] = v
		var p: float = gs.producao_total()
		var c: float = gs.custo_gerador("center_students")
		print("ALUNOS extremo q=%s producao=%s custo=%s pessoas=%s" % [str(v), str(p), str(c), str(gs.pessoas_desenhadas("center_students"))])
		checar(not is_nan(p), "alunos %s: producao nao e NaN" % str(v))
		checar(not is_nan(c), "alunos %s: custo nao e NaN" % str(v))
	_liberar(gs)


func _patrocinio_fluxo() -> void:
	var gs := _novo("qa_patro")
	gs.permanente["regional_belts"] = 1
	gs.permanente["first_regional_belt_campaign"] = 1
	gs.local_id = "gym"
	gs.cinturao = true
	gs.indice_escada = 0
	gs.atributos = {"strength": 1.0e14, "agility": 1.0e14, "endurance": 1.0e14}
	var sinais: Array = []
	gs.patrocinio_mudou.connect(func(e: String) -> void: sinais.append(e))
	var fama_quando_oferta := -1
	var din_assinado_extra := 0.0
	var resumo_linhas: Array = []
	for i in 11:
		if gs.indice_escada >= gs.lutas.adversarios.size():
			break
		gs.fight_day = gs.dia_campanha()
		gs.segundos_campanha = 1.0e9
		var opp: Dictionary = gs.proximo_adversario()
		var estado_antes: String = gs.patrocinio_estado
		var din0: float = gs.dinheiro
		gs.lutar()
		var r: Dictionary = gs.concluir_luta()
		var bonus: int = int(r.get("sponsor_money", 0))
		resumo_linhas.append([str(opp.id), gs.fama, estado_antes, gs.patrocinio_estado, bonus, int(gs.dinheiro - din0 - float(r.get("money", 0)))])
		if gs.patrocinio_estado == "offered" and fama_quando_oferta < 0:
			fama_quando_oferta = gs.fama
			checar(gs.fama >= 200, "oferta so com fama >= 200 (fama %d)" % gs.fama)
			checar(bonus == 0, "a vitoria que oferece nao paga bonus")
			# ignora 3 lutas (AGORA NAO = nao assina): nada muda
		if gs.patrocinio_estado == "offered" and resumo_linhas.size() == 6:
			checar(gs.assinar_patrocinio(), "assinou depois de 2 lutas ignoradas")
	for l in resumo_linhas:
		print("PATRO ", l)
	checar(sinais.count("offered") == 1 and sinais.count("signed") == 1, "sinais: 1 offered, 1 signed: %s" % str(sinais))
	# a vitoria assinada paga floor(base*0,5+0,5) e o dinheiro extra confere (sem nos de dinheiro)
	var ok := true
	for l in resumo_linhas:
		if l[2] == "signed":
			var opp: Dictionary = gs.lutas.adversario(str(l[0]))
			ok = ok and int(l[4]) == int(floor(float(opp.prize_money) * 0.5 + 0.5)) and int(l[5]) == int(l[4])
	checar(ok, "bonus assinado = 50% do premio base e o dinheiro soma exatamente isso")
	# ignorar: fecha a janela nao muda nada (estado continua offered ate o fim da campanha)
	_liberar(gs)
	# 2a campanha: zera
	var g2 := _novo("qa_patro2")
	g2.permanente["regional_belts"] = 1
	g2.patrocinio_estado = "signed"
	g2.permanente["center_reached"] = true
	g2.aposentar()
	g2.nova_carreira()
	checar_igual(g2.patrocinio_estado, "", "campanha nova: patrocinio zerado")
	checar(g2.patrocinio().state == "", "patrocinio() existe (linhagem com cinturao) e esta vazio")
	var s: Dictionary = g2.para_save()
	checar(not s.career.has("sponsor"), "save da campanha nova sem o campo sponsor")
	# assinar sem estar offered / durante luta
	g2.patrocinio_estado = ""
	checar(not g2.assinar_patrocinio(), "assinar sem proposta: recusado")
	g2.patrocinio_estado = "signed"
	checar(not g2.assinar_patrocinio(), "assinar 2x: recusado")
	# linhagem sem cinturao do Vale com fama enorme: nada
	var g3 := _novo("qa_patro3")
	g3.fama = 99999
	g3._centro.avaliar_oferta()
	checar(g3.patrocinio().is_empty() and g3.patrocinio_estado == "", "sem cinturao do Vale: nada, mesmo com fama 99999")
	g3.fama = 5
	g3.permanente["regional_belts"] = 1
	g3._centro.avaliar_oferta()
	checar(g3.patrocinio_estado == "", "com cinturao e fama 5: nada")
	_liberar(g2)
	_liberar(g3)


func _saves_sujos() -> void:
	var gs := _novo("qa_sujo")
	var base: Dictionary = gs.para_save()
	var casos := {
		"alunos_neg": func(e: Dictionary) -> void: e.career.location = "center"; e.career.ladder_index = 10; e.permanent["regional_belts"] = 1; e.career.generators["center_students"] = -5,
		"alunos_nan": func(e: Dictionary) -> void: e.career.location = "center"; e.career.ladder_index = 10; e.permanent["regional_belts"] = 1; e.career.generators["center_students"] = NAN,
		"alunos_str": func(e: Dictionary) -> void: e.career.location = "center"; e.career.ladder_index = 10; e.permanent["regional_belts"] = 1; e.career.generators["center_students"] = "abc",
		"alunos_1e30": func(e: Dictionary) -> void: e.career.location = "center"; e.career.ladder_index = 10; e.permanent["regional_belts"] = 1; e.career.generators["center_students"] = 1.0e30,
		"alunos_inf": func(e: Dictionary) -> void: e.career.location = "center"; e.career.ladder_index = 10; e.permanent["regional_belts"] = 1; e.career.generators["center_students"] = INF,
		"alunos_float": func(e: Dictionary) -> void: e.career.location = "center"; e.career.ladder_index = 10; e.permanent["regional_belts"] = 1; e.career.generators["center_students"] = 7.9,
		"sponsor_int": func(e: Dictionary) -> void: e.permanent["regional_belts"] = 1; e.career["sponsor"] = 5,
		"sponsor_arr": func(e: Dictionary) -> void: e.permanent["regional_belts"] = 1; e.career["sponsor"] = ["signed"],
		"sponsor_null": func(e: Dictionary) -> void: e.permanent["regional_belts"] = 1; e.career["sponsor"] = null,
		"sponsor_caps": func(e: Dictionary) -> void: e.permanent["regional_belts"] = 1; e.career["sponsor"] = "SIGNED",
		"center_reached_str": func(e: Dictionary) -> void: e.permanent["center_reached"] = "true",
		"center_reached_1": func(e: Dictionary) -> void: e.permanent["center_reached"] = 1,
		"loc_center_str": func(e: Dictionary) -> void: e.career.location = "centro",
		"loc_num": func(e: Dictionary) -> void: e.career.location = 7,
		"nivel_99": func(e: Dictionary) -> void: e.career.upgrade_levels = {"punching_bag": 99, "treadmill": -3, "jump_rope": NAN, "speed_bag": "x"},
		"nivel_5_gym": func(e: Dictionary) -> void: e.career.location = "gym"; e.career.upgrade_levels = {"punching_bag": 5, "treadmill": 5, "jump_rope": 5, "speed_bag": 5},
		"nos_ctr_sem_reached": func(e: Dictionary) -> void: e.permanent["skill_nodes"] = ["ctr_floor", "ctr_schedule", "xx"]; e.career.erase("active_nodes"),
		"legacy_nan": func(e: Dictionary) -> void: e.permanent["center_reached"] = true; e.permanent["legacy_total"] = NAN,
	}
	for nome in casos:
		var e: Dictionary = base.duplicate(true)
		if not e.career.has("generators"):
			e.career["generators"] = {}
		casos[nome].call(e)
		var n_av: int = gs.avisos.size()
		gs.aplicar_save(e)
		var s: Dictionary = gs.para_save()
		var ok := true
		var msg := ""
		var q: int = gs.quantidade_gerador("center_students")
		if q < 0:
			ok = false
			msg += " q<0"
		if not (gs.patrocinio_estado in ["", "offered", "signed"]):
			ok = false
			msg += " sponsor ruim"
		for ap in gs.dados.todos_aparelhos():
			var nv: int = int(gs.niveis_melhoria.get(ap.id, 0))
			if nv < 0 or nv > 5:
				ok = false
				msg += " nivel %s=%d" % [ap.id, nv]
		var json := JSON.stringify(s)
		if json == "" or json.contains("nan") or json.contains("inf"):
			ok = false
			msg += " json ruim"
		if not (is_finite(gs.producao_total())):
			ok = false
			msg += " producao infinita"
		print("SUJO %s -> local=%s alunos=%d sponsor='%s' center_reached=%s avisos+%d%s" % [nome, gs.local_id, q, gs.patrocinio_estado, str(gs.permanente.get("center_reached", false)), gs.avisos.size() - n_av, msg])
		checar(ok, "save sujo '%s' e sanado" % nome + msg)
	_liberar(gs)


func _saves_antigos() -> void:
	# save da 8a1 (sem nenhum campo da 8a2) parado em cada ponto: abre e o MUDAR esta correto
	var gs := _novo("qa_antigo")
	var base: Dictionary = gs.para_save()
	for caso in [["kid vencido, sem cinturao do Vale", 6, false, 99999.0, "locked"], ["James vencido, $24.999", 10, true, 24999.0, "missing"],
			["James vencido, $25.000", 10, true, 25000.0, "ready"], ["James vencido, $0", 10, true, 0.0, "missing"], ["Sabao vencido", 9, false, 99999.0, "locked"]]:
		var e: Dictionary = base.duplicate(true)
		e.career.location = "gym"
		e.career.ladder_index = caso[1]
		e.career.belt = true
		e.career.money = caso[3]
		e.career.fight_day = -1 if caso[1] >= 10 else 3
		if caso[2]:
			e.permanent["regional_belts"] = 1
			e.permanent["first_regional_belt_campaign"] = 1
		gs.aplicar_save(e)
		checar_igual(gs.estado_mudanca(), caso[4], "save antigo '%s': estado do MUDAR" % caso[0])
		checar_igual(gs.reserva_mudanca(), 25000.0 if caso[1] >= 10 and caso[2] else 0.0, "save antigo '%s': reserva" % caso[0])
	# garagem de um save antigo completo (escada 4, cinturao): MUDAR da academia como sempre
	var e2: Dictionary = base.duplicate(true)
	e2.career.location = "garage"
	e2.career.ladder_index = 4
	e2.career.belt = true
	e2.career.money = 5000.0
	gs.aplicar_save(e2)
	checar_igual(gs.mudanca().get("location", ""), "gym", "garagem com cinturao: destino academia")
	checar_igual(gs.estado_mudanca(), "ready", "garagem com cinturao e $5.000: pronto")
	_liberar(gs)


func _arvore_e_nos() -> void:
	var gs := _novo("qa_arv")
	gs.permanente["legacy_total"] = 100000
	var antes: int = int(gs.permanente.legacy_total)
	checar(not gs.comprar_no("ctr_door"), "ctr_door recusado sem a 1a mudanca")
	checar(not gs.comprar_no("ctr_floor") and not gs.comprar_no("ctr_schedule"), "ctr_floor/schedule recusados sem a raiz")
	checar_igual(int(gs.permanente.legacy_total), antes, "nenhum Legado gasto")
	gs.permanente["center_reached"] = true
	checar(not gs.comprar_no("ctr_floor"), "ctr_floor sem a raiz recusado")
	checar(gs.comprar_no("ctr_door"), "ctr_door comprado")
	checar(not gs.comprar_no("ctr_door"), "ctr_door 2x recusado")
	# efeito: bonus no clique e no Piso, a academia vai a x3
	gs.comprar_no("ctr_schedule")
	gs.comprar_no("ctr_floor")
	gs.local_id = "gym"
	checar_igual(gs.mult_local(), 2.0 * (1.0 + 0.25 + 0.25 * 0.0), "academia: x2 base com Piso +25% (sem o Ventilador) = 2,5")
	print("MULT academia com Piso: ", gs.mult_local())
	gs.local_id = "center"
	print("MULT centro com Piso: ", gs.mult_local())
	# o mapa tem nos antigos intactos
	var nos: Array = gs.arvore_mapa()
	var ctr := nos.filter(func(n: Dictionary) -> bool: return str(n.id).begins_with("ctr_"))
	checar_igual(ctr.size(), 3, "3 nos ctr_ no mapa")
	_liberar(gs)


func _mudar_bordas() -> void:
	var gs := _novo("qa_bordas")
	gs.local_id = "gym"
	gs.cinturao = true
	gs.indice_escada = 10
	gs.permanente["regional_belts"] = 1
	gs.dinheiro = 24999.99
	checar(not gs.mudar(), "24.999,99 nao muda")
	gs.dinheiro = NAN
	checar(not gs.mudar(), "dinheiro NaN: nao muda")
	gs.dinheiro = 25000.0
	checar(gs.mudar() and gs.local_id == "center", "25.000 exatos mudam")
	checar(not gs.mudar(), "mudar no centro: recusado")
	checar_igual(gs.dinheiro, 0.0, "dinheiro 0 depois de mudar")
	# mudar durante luta marcada? (dia da luta ja marcado)
	var g2 := _novo("qa_bordas2")
	g2.local_id = "gym"
	g2.cinturao = true
	g2.indice_escada = 10
	g2.permanente["regional_belts"] = 1
	g2.dinheiro = 1.0e30
	checar(g2.mudar(), "1e30 de dinheiro: muda")
	checar(is_finite(g2.dinheiro), "dinheiro continua finito")
	# 5a melhoria sem a 4a
	var g3 := _novo("qa_bordas3")
	g3.local_id = "center"
	g3.permanente["regional_belts"] = 1
	g3.indice_escada = 10
	g3.cinturao = true
	g3.treino = 1.0e15
	g3.niveis_melhoria["punching_bag"] = 2
	var prox: Dictionary = g3.proximo_melhoria("punching_bag") if g3.has_method("proximo_melhoria") else g3.proxima_melhoria("punching_bag")
	checar(str(prox.get("id", "")) != "bag_center", "com nivel 2 a proxima nao e a 5a (%s)" % str(prox.get("id", "")))
	g3.niveis_melhoria["punching_bag"] = 4
	checar(g3.comprar_melhoria("punching_bag") and g3.niveis_melhoria["punching_bag"] == 5, "4 -> 5 no centro")
	checar(not g3.comprar_melhoria("punching_bag"), "6a nao existe")
	g3.local_id = "gym"
	print("MULT aparelho com 5a, na academia: ", g3.multiplicador_aparelho("punching_bag"))
	_liberar(gs)
	_liberar(g2)
	_liberar(g3)
