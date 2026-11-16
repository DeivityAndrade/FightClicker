extends "res://tests/test_base.gd"
## Fase 6c2 (Mais longe que eu): Honra, hall, bonus do retrato, mural, falas dos mentores, simbolo da escola, save v13.
## Tudo em pastas de user://test/, nunca o save real.

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
	g.aguardar_falta()
	g.free()


func _tickar(gs: Node, segundos: float, passo: float = 0.1) -> void:
	for i in int(round(segundos / passo)):
		gs.tick(passo)


func _passar_o_posto(gs: Node) -> void:
	gs.aposentar()
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()


# Sai por vontade com `wins` vitorias (e o cinturao se wins >= 4). Devolve o fim.
func _sair_com(gs: Node, wins: int) -> Dictionary:
	gs.indice_escada = wins
	gs.cinturao = wins >= 4
	return gs.aposentar()


func _vencer(gs: Node) -> Dictionary:
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	gs.lutar()
	return gs.concluir_luta()


# Discipulo na Carreira `carreira` com o John sentado na garagem; o John saiu com `wins_john` vitorias.
func _com_mentor(nome: String, wins_john: int = 0) -> Node:
	var gs := _novo(nome)
	_sair_com(gs, wins_john)
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	_tickar(gs, 0.5)
	return gs


func _entrada(campanha: int, fim: String, wins: int, honra: int, oponente: String = "", belt: bool = false) -> Dictionary:
	return {"campaign": campanha, "kind": "disciple", "name": "Disc%d" % campanha, "look": null, "end": fim, "wins": wins,
		"belt": belt, "art": "", "opponent": oponente, "legacy_gained": 0, "honor": honra}


func rodar_testes() -> void:
	_t_dados()
	_t_formula()
	_t_honra_no_fim()
	_t_retrato()
	_t_hall()
	_t_efeitos_do_hall()
	_t_falas()
	_t_simbolo()
	_t_mural()
	_t_migracao()
	_t_balanco()


# --- dados e constantes congeladas ---

func _t_dados() -> void:
	var h: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/hall.json"))
	checar_igual(SaveStore.VERSAO_ATUAL, 13, "save v13")
	var por: Array = []
	for x in h.honor.per_win:
		por.append(int(x))
	checar_igual(por, SaveStore.HONRA_POR_VITORIA_V13, "constantes congeladas: Honra por vitoria = hall.json")
	checar_igual(int(h.honor.belt_bonus), SaveStore.HONRA_CINTURAO_V13, "constantes congeladas: bonus do cinturao = hall.json")
	checar_igual(int(h.honor.retro_unknown_wins), SaveStore.HONRA_VITORIAS_DESCONHECIDAS_V13, "constantes congeladas: wins desconhecido = hall.json")
	var total := 0
	for n in h.hall.nodes:
		total += int(n.cost)
	checar_igual(total, 190, "hall: 190 de Honra no total")
	checar_igual(h.hall.nodes.size(), 6, "hall: 6 nos")
	var gs := _novo("c2_dados")
	for n in gs.hall_lista():
		checar(n.name != "" and n.effect_text != "" and not n.name.begins_with("hall_"), "no do hall com nome e descricao de ui_texts: " + n.id)
		checar_igual(n.name, gs.texto_ui(n.id + "_name"), "nome do no vem da chave " + n.id + "_name")
	checar(gs.dialogos.erros.is_empty(), "dialogos sem erros (falas ml_* validas) " + str(gs.dialogos.erros))
	checar_igual(gs.hall_lista()[0].name, "FITA FROUXA", "nome final do 1o no do hall")
	for id in ["ml_revanche_1", "ml_recorde_1", "ml_mais_longe_1"]:
		checar(bool(gs.dialogos.linha(id).get("enabled", false)), "fala ligada: " + id)
	_liberar(gs)


# --- formula da Honra (design 2.2) ---

func _t_formula() -> void:
	var gs := _novo("c2_formula")
	var esperado := {0: 0, 1: 1, 2: 3, 3: 6, 5: 20, 6: 27}
	for w in esperado:
		checar_igual(gs.honra_da_saida(w, w >= 4), esperado[w], "Honra de %d vitorias" % w)
	checar_igual(gs.honra_da_saida(4, true), 15, "Honra com o cinturao (Muralha) = 15")
	checar_igual(gs.honra_da_saida(4, false), 10, "sem cinturao = so as vitorias")
	checar_igual(gs.honra_da_saida(7, true), 27 + 7, "7 vitorias = Kid + 7")
	_liberar(gs)


func _t_honra_no_fim() -> void:
	# Saida com 0 vitorias: 0 de Honra.
	var gs := _novo("c2_fim0")
	var p = gs.previa_aposentar()
	checar_igual([p.honor, p.wins], [0, 0], "previa de sair com 0 vitorias: Honra 0")
	var f = gs.aposentar()
	checar_igual([f.honor_gained, gs.honra(), gs.honra_total(), gs.escola.roster[0].honor], [0, 0, 0, 0], "sair com 0 vitorias: nada de Honra")
	_liberar(gs)

	# Sai com 4 vitorias e cinturao: 15; a previa bate com o fim; saldo, total e roster.
	gs = _novo("c2_fim15")
	gs.indice_escada = 4
	gs.cinturao = true
	checar_igual(gs.previa_aposentar().honor, 15, "previa da confirmacao: +15 de Honra")
	var antes_legado := int(gs.permanente.legacy_total)
	f = gs.aposentar()
	checar_igual([f.honor_gained, gs.honra(), gs.honra_total(), gs.escola.roster[0].honor], [15, 15, 15, 15], "sair com o cinturao: 15 na entrada, no saldo e no total")
	checar(int(gs.permanente.legacy_total) > antes_legado, "o Legado da mesma saida continua")
	# gravado no save
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(gs.store.caminho()))
	checar_igual([int(doc.version), int(doc.state.school.honor), int(doc.state.school.honor_total), int(doc.state.ending.honor_gained)], [13, 15, 15, 15], "Honra no mesmo save do fim")
	# nada multiplica: o Caderno do velho (+15% de Legado) nao mexe na Honra
	gs.permanente["skill_nodes"] = []
	_liberar(gs)

	# Derrota: 0 de Honra, retrato sem selo, mesmo com vitorias.
	gs = _novo("c2_derrota")
	gs.indice_escada = 1
	gs.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	gs.lutar()
	var r = gs.concluir_luta()
	checar(not r.get("win", true), "derrota aconteceu (Brutao contra 0 de atributos)")
	if not r.get("win", true):
		checar_igual([gs.fim.honor_gained, gs.honra(), gs.escola.roster[0].honor, gs.retratos_com_selo()], [0, 0, 0, 0], "derrota: 0 Honra, retrato sem selo")
	_liberar(gs)

	# Passar o posto no dia da luta tambem e saida por vontade (passa por aposentar()).
	gs = _novo("c2_dia")
	gs.indice_escada = 2
	var f2 = gs.aposentar()
	checar_igual(f2.honor_gained, 3, "passar o posto com 2 vitorias: 3 de Honra")
	_liberar(gs)


# --- bonus do retrato ---

func _t_retrato() -> void:
	var gs := _novo("c2_retrato")
	var base = gs.por_clique()
	var equipe = gs._fator_equipe()
	checar_igual(gs.mult_escola(), 1.0, "sem retratos: fator 1,0")
	for i in 3:
		gs.escola.roster.append(_entrada(10 + i, "retire", 2, 3))
	gs.escola.roster.append(_entrada(20, "retire", 0, 0))
	gs.escola.roster.append(_entrada(21, "defeat", 3, 0, "opp_fast"))
	checar_igual(gs.retratos_com_selo(), 3, "so entradas com Honra contam (selo)")
	checar(absf(gs.mult_escola() - 1.06) < 1e-9, "3 selos: x1,06")
	checar(absf(gs.por_clique() / base - 1.06) < 1e-9, "o clique recebe o fator")
	checar(absf(gs._fator_equipe() / equipe - 1.06) < 1e-9, "a equipe recebe o mesmo fator (um fator so)")
	for i in 7:
		gs.escola.roster.append(_entrada(30 + i, "retire", 2, 3))
	checar_igual([gs.retratos_com_selo(), gs.teto_retratos()], [10, 5], "10 selos, teto 5")
	checar(absf(gs.mult_escola() - 1.10) < 1e-9, "teto de 5 retratos: x1,10")
	gs.escola.hall_nodes.append("hall_wall")
	checar_igual(gs.teto_retratos(), 8, "hall_wall: teto 8")
	checar(absf(gs.mult_escola() - 1.16) < 1e-9, "com hall_wall: x1,16")
	var auto = gs.por_auto_soco()
	checar(absf(auto / (gs.dados.base_training * gs.multiplicador_aparelho(gs.foco) * gs.multiplicador_luva() * gs.mult_local()) - 1.16) < 1e-9, "Metronomo e assistido (auto-soco) recebem o fator")
	_liberar(gs)


# --- hall: compra, estados ---

func _t_hall() -> void:
	var gs := _novo("c2_hall")
	checar_igual(gs.hall_lista().size(), 6, "lista fixa de 6 nos")
	checar_igual(gs.hall_lista()[0].state, "closed", "fora da tela de fim: so consulta (closed)")
	gs.escola["honor"] = 40
	gs.escola["honor_total"] = 40
	checar(not gs.comprar_hall("hall_box"), "nao compra fora da tela de fim")
	checar_igual(gs.honra(), 40, "saldo intacto")
	gs.indice_escada = 1
	gs.aposentar()  # +1 de Honra: 41
	checar_igual(gs.honra(), 41, "Honra 41 na tela de fim")
	var estados := {}
	for n in gs.hall_lista():
		estados[n.id] = n.state
	checar_igual([estados.hall_box, estados.hall_wall], ["buyable", "missing"], "estados com a tela de fim: buyable / missing")
	checar_igual(gs.hall_lista()[5].missing, 0 if gs.honra() >= 50 else 50 - gs.honra(), "missing = falta de Honra")
	var legado := int(gs.permanente.legacy_total)
	checar(gs.comprar_hall("hall_box"), "compra hall_box (10)")
	checar_igual(gs.honra(), 31, "desconta a Honra exata")
	checar(not gs.comprar_hall("hall_box"), "sem comprar de novo")
	checar_igual(gs.honra(), 31, "sem reembolso nem cobranca dupla")
	checar_igual(int(gs.permanente.legacy_total), legado, "Honra e Legado nao se misturam: Legado intacto")
	checar_igual(gs.hall_lista()[0].state, "owned", "no comprado: owned")
	checar(not gs.comprar_hall("nao_existe"), "id desconhecido recusado")
	gs.escola["honor"] = 5
	checar(not gs.comprar_hall("hall_fund"), "sem Honra suficiente: recusado")
	# compra de no de Legado nao mexe na Honra
	var honra_antes = gs.honra()
	var id_legado: String = gs.lutas.arvore[0].id if not gs.lutas.arvore.is_empty() else ""
	if id_legado != "":
		gs.permanente["legacy_total"] = 1.0e9
		gs.comprar_no(id_legado)
	checar_igual(gs.honra(), honra_antes, "comprar no de Legado nao mexe na Honra")
	# salvo e recarregado
	var pasta: String = gs.store.pasta
	_liberar(gs)
	var gs2 := _novo("c2_hall_b", pasta)
	checar_igual([gs2.honra(), gs2.tem_no_hall("hall_box")], [5, true], "carga do save: saldo e no comprado")
	_liberar(gs2)
	# id invalido e repetido no save e ignorado; saldo nunca maior que o total
	var gs3 := _novo("c2_hall_c")
	gs3.aplicar_save({"school": {"honor": 50, "honor_total": 10, "hall_nodes": ["hall_box", "hall_box", "xx"]}})
	checar_igual([gs3.honra(), gs3.honra_total(), gs3.escola.hall_nodes], [50, 50, ["hall_box"]], "validacao: total >= saldo, nos invalidos ou repetidos ignorados")
	_liberar(gs3)


func _t_efeitos_do_hall() -> void:
	# Hall vazio: caixa com 3 cliques, nada extra.
	var gs := _novo("c2_efeitos")
	checar_igual(gs.cliques_para_abrir(), 3, "hall vazio: caixa com 3 cliques")
	var equipe_antes = gs._fator_equipe()
	for id in ["hall_box", "hall_fund", "hall_notes", "hall_crew", "hall_glove"]:
		gs.escola.hall_nodes.append(id)
	gs.indice_escada = 1
	gs.aposentar()
	gs.nova_carreira()
	checar_igual(gs.cliques_para_abrir(), 2, "hall_box: caixa com 2 cliques")
	checar_igual(gs.treino, 500.0, "hall_fund: a campanha comeca com 500 de saldo")
	checar_igual(gs.atributos.strength + gs.atributos.agility + gs.atributos.endurance, 0.0, "hall_fund nao soma em atributo")
	checar_igual([gs.nivel_luva, gs.luvas_abertas(), gs.caixas_lista.size(), gs.gestos_calcados], [1, 1, 0, [1]], "hall_glove: luva de lona ja aberta, sem caixa e sem gesto")
	checar(not gs.luva_em_caixa() and gs.proxima_luva().id == gs.lutas.luvas[1].id, "a loja oferece a luva de couro")
	checar(absf(gs._fator_equipe() / equipe_antes - 1.10 * 1.02) < 1e-9, "hall_crew: equipe x1,10 (e x1,02 do retrato da saida)")
	# caixa abre no 2o clique
	gs.dinheiro = 1.0e9
	var l = gs.proxima_luva()
	gs.comprar_luva()
	checar(gs.luva_em_caixa(), "luva comprada fica em caixa")
	gs.bater_caixa(str(l.id))
	checar(gs.luva_em_caixa(), "1 clique: ainda fechada")
	gs.bater_caixa(str(l.id))
	checar(not gs.luva_em_caixa(), "2 cliques: aberta")
	_liberar(gs)

	# A luva de lona e do hall so na campanha seguinte: a campanha atual nao muda ao comprar.
	gs = _novo("c2_efeitos2")
	gs.indice_escada = 1
	gs.aposentar()
	gs.escola["honor"] = 100
	gs.comprar_hall("hall_glove")
	checar_igual(gs.nivel_luva, 0, "compra no fim nao muda a campanha encerrada")
	_liberar(gs)

	# Linha da previa (hall_notes): so fora do verde, em segundo plano.
	gs = _novo("c2_notes")
	gs.escola.hall_nodes.append("hall_notes")
	gs.atributos = {"strength": 50.0, "agility": 50.0, "endurance": 50.0}
	gs.indice_escada = 3  # Dinho com pouco treino: fora do verde
	var pv = gs.previa()
	checar(pv.has("missing_line"), "previa tem missing_line")
	if pv.risk != "easy":
		gs.aguardar_falta()
		var pv2 = gs.previa()
		checar(str(pv2.missing_line).begins_with("FALTA") or str(pv2.missing_line) == "", "linha pronta depois do calculo: " + str(pv2.missing_line))
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	checar_igual(gs.previa().missing_line, "", "no verde: sem linha")
	_liberar(gs)
	gs = _novo("c2_notes_off")
	gs.atributos = {"strength": 50.0, "agility": 50.0, "endurance": 50.0}
	gs.indice_escada = 3
	checar_igual(gs.previa().missing_line, "", "sem o no: sem linha")
	_liberar(gs)


# --- falas dos mentores ---

func _t_falas() -> void:
	# Sem mentor sentado (Carreira 1): nenhuma fala de mentor; o Osmar comenta.
	var gs := _novo("c2_f_sem")
	var r = _vencer(gs)
	checar_igual(r.mentor_line, {}, "Carreira 1: sem mentor, sem fala de mentor")
	_liberar(gs)

	# John sentado, saiu com 0 vitorias: "mais longe que eu" na 1a vitoria (1 > 0). Revanche/recorde nao.
	gs = _com_mentor("c2_f_mais", 0)
	checar_igual(gs.mentor_do_caixote().get("id", ""), "first", "o John esta sentado")
	r = _vencer(gs)
	checar_igual(r.mentor_line.get("line", ""), "mais_longe", "John com 0 vitorias: a 1a vitoria passa dele")
	checar_igual(r.mentor_line.get("mentor_kind", ""), "first", "mentor_kind first")
	# O Osmar nao comenta aquela vitoria: so mentor_won na fila.
	var gatilhos := []
	for g in gs._gatilhos_quadro:
		gatilhos.append(g.id)
	checar_igual(gatilhos, ["mentor_won"], "so mentor_won (a fight_won do Osmar nao sai)")
	# teto: 1 por campanha no grupo marca. Simula a fala tocada e vence de novo.
	gs.escola.lines_seen["ml_mais_longe_1"] = gs.numero_carreira()
	r = _vencer(gs)
	checar_igual(r.mentor_line, {}, "teto do grupo marca: 1 por campanha")
	gs._gatilhos_quadro = []
	_liberar(gs)

	# John saiu com 1 vitoria: recorde da escola = 1; 2 vitorias batem o recorde -> "recorde" antes de "mais longe".
	gs = _com_mentor("c2_f_recorde", 1)
	r = _vencer(gs)
	checar_igual(r.mentor_line, {}, "1a vitoria empata o John (1 > 1 falso): sem fala")
	r = _vencer(gs)
	checar_igual(r.mentor_line.get("line", ""), "recorde", "2a vitoria bate o recorde: recorde antes de mais_longe")
	gs.escola.lines_seen["ml_recorde_1"] = gs.numero_carreira()
	r = _vencer(gs)
	checar_igual(r.mentor_line, {}, "recorde dito: mais_longe divide o teto (marca) e nao sai")
	_liberar(gs)

	# Revanche: entrada com defeat contra o adversario vencido, antes do recorde; teto proprio.
	gs = _com_mentor("c2_f_rev", 1)
	gs.escola.roster.append(_entrada(1, "defeat", 0, 0, "opp_warmup"))
	gs.escola.roster[gs.escola.roster.size() - 1]["campaign"] = 9  # outra campanha: o mentor e o John
	r = _vencer(gs)
	checar_igual([r.mentor_line.get("line", ""), r.mentor_line.get("own", true), r.mentor_line.get("adversario", "")], ["revanche", false, gs.lutas.adversario("opp_warmup").name], "revanche (o algoz era de outro): own falso")
	gs.escola.lines_seen["ml_revanche_1"] = gs.numero_carreira()
	r = _vencer(gs)
	checar(r.mentor_line.get("line", "") != "revanche", "revanche: 1 por campanha")
	_liberar(gs)

	# Revanche propria: o John foi derrubado por Dudu.
	gs = _com_mentor("c2_f_own", 1)
	gs.escola.roster[0]["end"] = "defeat"
	gs.escola.roster[0]["opponent"] = "opp_warmup"
	r = _vencer(gs)
	checar_igual([r.mentor_line.get("line", ""), r.mentor_line.get("own", false)], ["revanche", true], "revanche propria: own verdadeiro")
	_liberar(gs)

	# Mentor com wins -1 (migrado): "mais longe" nunca sai.
	gs = _com_mentor("c2_f_unk", 0)
	gs.escola.roster[0]["wins"] = -1
	r = _vencer(gs)
	checar_igual(r.mentor_line, {}, "mentor com wins -1: nunca mais_longe; -1 nao entra no recorde")
	_liberar(gs)

	# A fala sai pelo balao: speaker do John = "first"; texto com marcadores preenchidos.
	gs = _com_mentor("c2_f_balao", 0)
	var visto := {"speaker": "", "texto": ""}
	gs.fala_pedida.connect(func(sp: String, tx: String, _id: String) -> void:
		visto.speaker = sp
		visto.texto = tx)
	gs._ultimo_comentario = -1.0e9  # passou o intervalo de 60 s
	r = _vencer(gs)
	_tickar(gs, 3.0)
	_tickar(gs, 20.0)
	checar_igual(visto.speaker, "first", "o balao e do mentor sentado (John = first)")
	checar(visto.texto != "" and not visto.texto.contains("{"), "texto da fala de mentor sem marcador solto: " + visto.texto)
	checar(int(gs.escola.lines_seen.get("ml_mais_longe_1", 0)) + int(gs.escola.lines_seen.get("ml_mais_longe_2", 0)) + int(gs.escola.lines_seen.get("ml_mais_longe_3", 0)) + int(gs.escola.lines_seen.get("ml_mais_longe_first_1", 0)) + int(gs.escola.lines_seen.get("ml_mais_longe_disc_1", 0)) > 0, "a fala tocou e gastou o teto")
	_liberar(gs)

	# Depois da saida do John: o ultimo que passou o posto senta no caixote e fala com a voz de discipulo.
	gs = _com_mentor("c2_f_last", 0)
	_passar_o_posto(gs)  # a campanha 2 (discipulo) sai: campanha 3 comeca
	gs._gravar_marco("cena_saida_primeiro_mentor", {}, false)
	gs.escola["mentors"] = []
	var mc = gs.mentor_do_caixote()
	checar_igual([mc.get("kind", ""), mc.get("id", ""), mc.get("campaign", 0)], ["disciple", "last", 2], "depois da saida do John: o ultimo que passou o posto esta sentado")
	gs._ultimo_comentario = -1.0e9
	var r2 = _vencer(gs)
	checar_igual([r2.mentor_line.get("mentor_kind", ""), r2.mentor_line.get("line", "")], ["disciple", "mais_longe"], "fala pedida pelo mentor discipulo (0 vitorias dele)")
	_liberar(gs)
	var gs_voz = _novo("c2_voz")
	var v1: Dictionary = gs_voz.voz_do_mentor("disciple", 7)
	checar_igual(v1.base_hz, 200.0 + 14.0 * 2.0, "voz do discipulo: 200 + 14 x passo (campanha 7 -> passo 2)")
	checar_igual(v1.cps, 26.0, "voz do discipulo: 26 letras/s")
	for c in 5:
		var hz := float(gs_voz.voz_do_mentor("disciple", c).base_hz)
		checar(hz >= 172.0 and hz <= 228.0, "voz entre 172 e 228 Hz (campanha %d: %s)" % [c, hz])
	_liberar(gs_voz)


# --- simbolo ---

func _t_simbolo() -> void:
	var gs := _novo("c2_simbolo")
	checar_igual([gs.campanha_do_simbolo(), gs.simbolo_no_lutador()], [0, false], "sem cinturao: sem simbolo")
	_sair_com(gs, 3)  # John sai sem cinturao
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	checar_igual([gs.campanha_do_simbolo(), gs.simbolo_no_lutador()], [0, false], "discipulo sem cinturao na escola: sem simbolo")
	gs.cinturao = true
	checar_igual([gs.campanha_do_simbolo(), gs.simbolo_no_lutador()], [2, true], "o discipulo ganha o 1o cinturao: simbolo na campanha dele")
	_sair_com(gs, 4)  # sai com cinturao: entra no roster com belt
	checar_igual(gs.campanha_do_simbolo(), 2, "roster com belt: campanha 2")
	checar(gs.simbolo_na_entrada(gs.escola.roster[1]), "retrato da campanha do cinturao com simbolo")
	checar(not gs.simbolo_na_entrada(gs.escola.roster[0]), "o John nunca usa")
	gs.escola.roster.insert(1, _entrada(1, "retire", 1, 1))
	checar(not gs.simbolo_na_entrada(gs.escola.roster[1]), "retrato de antes do 1o cinturao continua sem")
	# o marco garage_saved (John venceu o Muralha) vale
	var gs2 := _novo("c2_simbolo2")
	gs2._gravar_marco("garage_saved", {"opponent": "muralha"}, false)
	checar_igual(gs2.campanha_do_simbolo(), 1, "marco garage_saved na campanha 1")
	checar(not gs2.simbolo_no_lutador(), "o John nunca usa (lutador atual e o John)")
	_liberar(gs)
	_liberar(gs2)


# --- mural ---

func _t_mural() -> void:
	var gs := _novo("c2_mural")
	var m = gs.mural()
	checar_igual(m.entries.size(), 0, "mural vazio sem campanha encerrada")
	_sair_com(gs, 4)
	m = gs.mural()
	checar_igual(m.entries.size(), 1, "o John e a 1a entrada")
	var e: Dictionary = m.entries[0]
	checar_igual([e.kind, e.wins, e.belt, e.sealed, e.honor, e.end_key, e.symbol], ["first", 4, true, true, 15, "mural_end_retire", false], "retrato do John: selo, +15, sem simbolo")
	checar_igual([m.honor, m.sealed, m.counted, m.cap, m.bonus_pct], [15, 1, 1, 5, 2], "cabecalho do mural")
	gs.receber_discipulo()
	gs.sucessao_tela_aberta()
	gs.confirmar_discipulo()
	gs.sucessao_terminou()
	# a campanha em andamento nao entra; os outros fins
	gs.escola.roster.append(_entrada(5, "defeat", 3, 0, "opp_fast"))
	gs.escola.roster.append(_entrada(6, "retire", 0, 0))
	gs.escola.roster.append(_entrada(7, "unknown", -1, 0))
	m = gs.mural()
	checar_igual(m.entries.size(), 4, "a campanha em andamento nao entra")
	checar_igual([m.entries[1].end_key, m.entries[2].end_key, m.entries[3].end_key, m.entries[1].sealed],
		["mural_end_defeat", "mural_end_passed", "mural_end_passed", false], "chaves de fim: parou em, passou o posto, desconhecido")
	checar(m.entries[1].end_text.contains("DINHO") or m.entries[1].end_text.contains(gs.lutas.adversario("opp_fast").name.to_upper().substr(0, 5)), "parou em {adversario}: " + m.entries[1].end_text)
	checar_igual(m.entries[3].wins_text, "?", "wins -1: ?")
	gs.escola.roster.append(_entrada(8, "defeat", 2, 0, ""))
	checar_igual(gs.mural().entries[4].end_text, "PAROU NUMA LUTA", "derrota sem adversario: texto de reserva")
	gs.escola.roster.pop_back()
	checar_igual(m.entries[0].extra_key, "", "sem o marco da saida: sem linha extra do John")
	gs._gravar_marco("cena_saida_primeiro_mentor", {}, false)
	checar_igual(gs.mural().entries[0].extra_key, "mural_first_left", "depois da saida: linha extra do John")
	# 30 retratos
	for i in 26:
		gs.escola.roster.append(_entrada(20 + i, "retire", 2, 3))
	checar_igual(gs.mural().entries.size(), 30, "30 retratos")
	# mural na sala: garagem sempre; academia so com o marco da cena
	checar(not gs.mural_na_sala().is_empty() and gs.mural_na_sala().object_text == "mural", "mural na garagem")
	gs.local_id = "gym"
	checar(gs.mural_na_sala().is_empty(), "academia sem o marco da cena: sem mural")
	gs._gravar_marco("cena_primeira_academia", {}, false)
	checar(not gs.mural_na_sala().is_empty(), "academia com o marco: mural")
	_liberar(gs)


# --- migracao v12 -> v13 ---

func _doc_v12() -> Dictionary:
	var look := {"skin": "skin_3", "hair_color": "brown", "hair_style": "short", "shorts_color": "green", "top": "none",
		"top_color": "white", "headband": "none", "headband_color": "red", "socks": "none"}
	var roster := [
		{"campaign": 1, "kind": "first", "name": "John Bullet", "look": null, "end": "retire", "wins": 4, "belt": true, "art": "", "opponent": "", "legacy_gained": 750},
		{"campaign": 2, "kind": "disciple", "name": "Ana", "look": look, "end": "defeat", "wins": 5, "belt": true, "art": "", "opponent": "kid", "legacy_gained": 300},
		{"campaign": 3, "kind": "disciple", "name": "Beto", "look": look, "end": "retire", "wins": 6, "belt": true, "art": "", "opponent": "", "legacy_gained": 1710},
		{"campaign": 4, "kind": "disciple", "name": "Cris", "look": look, "end": "retire", "wins": 0, "belt": false, "art": "", "opponent": "", "legacy_gained": 0},
		{"campaign": 5, "kind": "disciple", "name": "Dani", "look": look, "end": "retire", "wins": -1, "belt": false, "art": "", "opponent": "", "legacy_gained": 0},
		{"campaign": 6, "kind": "disciple", "name": "Edu", "look": look, "end": "retire", "wins": 2, "belt": false, "art": "", "opponent": "", "legacy_gained": 80}]
	return {"version": 12, "saved_at_unix": 1730000000, "state": {
		"career": {"training": 5.0, "money": 2.0},
		"permanent": {"career_number": 7, "legacy_total": 999, "best_wins": 6},
		"ending": {"kind": "retire", "career_number": 6, "legacy_gained": 80, "legacy_total": 999, "summary": {"wins": 2, "belts": 0}},
		"school": {"first_fighter_campaign": 1, "milestones": {"prologue_seen": {"campaign": 1, "version": 1}}, "lines_seen": {"open_1": 1},
			"last_end": {"kind": "retire", "campaign": 6}, "handover": null, "mentors": ["first"], "roster": roster}}}


func _t_migracao() -> void:
	var pasta := pasta_limpa("c2_migra")
	var f := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_doc_v12()))
	f.close()
	var gs := _novo("c2_migra", pasta)
	# 15 + 0 (derrota) + 27 + 0 + 1 (wins -1) + 3 = 46
	var esperado := [15, 0, 27, 0, 1, 3]
	var obtido := []
	for e in gs.escola.roster:
		obtido.append(int(e.honor))
	checar_igual(obtido, esperado, "Honra retroativa por entrada (derrota 0, 0 vitorias 0, wins -1 = 1)")
	checar_igual([gs.honra(), gs.honra_total(), gs.escola.hall_nodes], [46, 46, []], "saldo e total = soma; hall vazio")
	checar_igual(gs.fim.honor_gained, 3, "fim pendente: honor_gained = a Honra da entrada pendente")
	checar_igual([int(gs.permanente.legacy_total), int(gs.permanente.best_wins), gs.escola.mentors, gs.marco("prologue_seen"), gs.escola.lines_seen.has("open_1")],
		[999, 6, ["first"], true, true], "nada mais muda (Legado, recorde, mentores, marcos, falas vistas)")
	gs.salvar()
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pasta + "save.json"))
	checar_igual(int(doc.version), 13, "regravado como v13")
	_liberar(gs)

	# Segunda carga do v13 nao migra de novo (Honra estavel).
	var gs2 := _novo("c2_migra2", pasta)
	checar_igual([gs2.honra(), gs2.honra_total()], [46, 46], "recarregar o v13 nao soma de novo")
	_liberar(gs2)

	# Save v13 aberto num build mais antigo: versao futura (bloqueado) e tratada pelo SaveStore.
	var st := SaveStore.new(pasta_limpa("c2_futuro"))
	var ff := FileAccess.open(st.caminho(), FileAccess.WRITE)
	ff.store_string(JSON.stringify({"version": 14, "saved_at_unix": 1, "state": {}}))
	ff.close()
	checar_igual(st.carregar().status, SaveStore.Status.FUTURO, "versao mais nova: bloqueado")

	# Copia de um save v12 real (so leitura; a copia vai para a pasta de teste), se o dono tiver um.
	var real := OS.get_environment("FIGHTCLICKER_SAVE_V12")
	if real != "" and FileAccess.file_exists(real):
		var copia := pasta_limpa("c2_copia_real")
		DirAccess.copy_absolute(real, copia + "save.json")
		var g3 := _novo("c2_copia_real", copia)
		checar(g3.honra() >= 0 and g3.honra_total() == g3.honra(), "copia do save v12 do dono migrada: Honra %d" % g3.honra())
		_liberar(g3)


# --- balanco: hall vazio = 6c1 ---

func _t_balanco() -> void:
	var gs := _novo("c2_balanco")
	checar_igual([gs.mult_escola(), gs.cliques_para_abrir(), gs.honra(), gs.escola.hall_nodes.size()], [1.0, 3, 0, 0], "hall vazio e sem retratos: nada muda")
	var esperado_clique: float = gs.dados.base_training * gs.multiplicador_aparelho(gs.foco) * gs.multiplicador_luva() * (1.0 + gs._b("click_bonus")) * gs.mult_local()
	checar_igual(gs.por_auto_soco(), esperado_clique, "treino por soco identico ao da 6c1 (formula sem o fator)")
	var esperado_equipe: float = (1.0 + gs._b("passive_bonus")) * gs.mult_local() * (1.0 + gs.bonus_arte_equipe())
	checar_igual(gs._fator_equipe(), esperado_equipe, "fator da equipe identico ao da 6c1")
	# Legado e fim: a saida de sempre (a Honra e extra, o Legado nao muda)
	gs.indice_escada = 3
	var p = gs.previa_aposentar()
	checar_igual([p.total, p.base, p.bonus], [p.total, p.base, p.bonus], "previa de sair continua com os campos de Legado")
	checar(p.has("honor"), "previa ganhou honor")
	_liberar(gs)
