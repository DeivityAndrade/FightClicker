extends RefCounted
## Save (para_save/aplicar_save), validações da carga e auxiliares.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


func salvar() -> bool:
	if gs.store.bloqueado:
		gs._avisar("Save não gravado: o arquivo no disco é de uma versão mais nova do jogo.")
		return false
	var unix := gs.store.salvar(para_save())
	if unix < 0:
		gs._avisar("Falha ao gravar o save.")
		return false
	gs.ultimo_save_unix = unix
	gs.ultimo_save_texto = Time.get_time_string_from_system()
	gs._tempo_autosave = 0.0
	gs.salvo.emit(gs.ultimo_save_texto)
	return true


func carregar_save() -> void:
	var r := gs.store.carregar()
	aplicar_save(r.estado)
	gs.ultimo_save_unix = r.saved_at_unix
	gs.ultimo_save_texto = _horario_local(gs.ultimo_save_unix) if gs.ultimo_save_unix > 0 else "nenhum"
	gs._tempo_autosave = 0.0
	gs.avisos.clear()
	if r.mensagem != "":
		gs.avisos.append(r.mensagem)
	gs.avisos_mudaram.emit(gs.avisos)
	gs.carregado.emit(r.status)


func apagar_save() -> void:
	gs.store.apagar()
	aplicar_save({})
	gs.ultimo_save_unix = 0
	gs.ultimo_save_texto = "nenhum"
	gs._tempo_autosave = 0.0
	gs.avisos.clear()
	gs.avisos_mudaram.emit(gs.avisos)


## Campos do estado que vão para o save (v7). Produção e custos não são salvos (vêm de data/).
func para_save() -> Dictionary:
	return {
		"career": {
			"metronome_level": gs.nivel_metronomo,
			"location": gs.local_id,
			"art": gs.arte_id,
			"art_seconds": gs.arte_segundos,
			"art_passive": gs.passiva_carreira,  # 7b2, opcional (ausente = 1ª passiva)
			"apparatus_owned": gs.aparelhos_montados_ids.duplicate(),
			"boxes": gs.caixas_lista.duplicate(true),
			"training": gs.treino,
			"attributes": gs.atributos.duplicate(),
			"focus": gs.foco,
			"generators": gs.geradores.duplicate(),
			"upgrades": gs.niveis_melhoria.duplicate(),
			"paid_generators": gs.geradores_pagos.duplicate(),
			"glove_level": gs.nivel_luva,
			"crew_click": gs.crew_click_comprado,
			"money": gs.dinheiro,
			"fame": gs.fama,
			"ladder_index": gs.indice_escada,
			"belt": gs.cinturao,
			"tactic": gs.tatica,
			"play_seconds": gs.tempo_jogo,
			"campaign_seconds": gs.segundos_campanha,
			"fight_day": gs.fight_day,
			"active_nodes": gs.nos_ativos_ids.duplicate(),
			"gestured_gloves": gs.gestos_calcados.duplicate(),
			"disciple": gs.discipulo.duplicate(true) if not gs.discipulo.is_empty() else null,
			"mentor_greeted": gs.mentor_cumprimentou,
			"money_earned": gs.dinheiro_ganho,
			"fight": gs.luta.duplicate(true) if not gs.luta.is_empty() else null,
			"training_invite": gs.convite.duplicate(),  # 7a2, opcional (save antigo sem ele = padrão)
		},
		"permanent": gs.permanente.duplicate(),
		"ending": gs.fim.duplicate(true) if not gs.fim.is_empty() else null,
		"school": gs.escola.duplicate(true),
	}


## Aplica um estado lido do save (formato v7). Campo faltando ou inválido recebe o padrão.
func aplicar_save(estado: Dictionary) -> void:
	var c = estado.get("career", {})
	if not (c is Dictionary):
		c = {}
	gs.treino = gs._numero_valido(c.get("training", 0.0))

	gs.atributos = {}
	var a = c.get("attributes", {})
	for id in gs.dados.atributos:
		gs.atributos[id] = gs._numero_valido(a.get(id, 0.0)) if a is Dictionary else 0.0

	# Fase 5: permanent primeiro (as artes liberadas validam a arte da carreira), depois local e arte
	gs.permanente = _validar_permanente(estado.get("permanent", null))
	_validar_local_e_arte(c)
	gs.aparelhos_montados_ids = gs._aparelhos._validar_aparelhos(c.get("apparatus_owned", null), not c.is_empty())
	var f := str(c.get("focus", ""))
	gs.foco = f if gs.aparelho_montado(f) else gs.dados.default_focus
	if f != "" and not gs.aparelho_montado(f):
		gs._avisar("Foco em aparelho não montado: voltou para o padrão.")

	gs.geradores = {}
	var gens = c.get("generators", {})
	for g in gs.dados.geradores:
		var q = gens.get(g.id, 0) if gens is Dictionary else 0
		gs.geradores[g.id] = gs._inteiro_valido(q, 1.0e9)

	gs.niveis_melhoria = {}
	var us = c.get("upgrades", {})
	for ap in gs.dados.todos_aparelhos():
		var n = us.get(ap.id, 0) if us is Dictionary else 0
		gs.niveis_melhoria[ap.id] = gs._inteiro_valido(n, float(ap.upgrades.size()))
		if gs.niveis_melhoria[ap.id] > 0 and not gs.aparelho_montado(ap.id):
			gs.niveis_melhoria[ap.id] = 0
			gs._avisar("Melhoria em aparelho não montado: zerada.")

	# Fase 3
	gs.geradores_pagos = {}
	var gp = c.get("paid_generators", {})
	for g in gs.lutas.geradores_pagos:
		var q = gp.get(g.id, 0) if gp is Dictionary else 0
		gs.geradores_pagos[g.id] = gs._inteiro_valido(q, 1.0e9)
	gs.nivel_luva = gs._inteiro_valido(c.get("glove_level", 0), float(gs.lutas.luvas.size()))
	gs.crew_click_comprado = typeof(c.get("crew_click", false)) == TYPE_BOOL and c.get("crew_click", false) and not gs.lutas.crew_click.is_empty()
	gs.caixas_lista = gs._aparelhos._validar_caixas(c.get("boxes", null))
	gs.dinheiro = gs._numero_valido(c.get("money", 0.0))
	gs.fama = gs._inteiro_valido(c.get("fame", 0), 1.0e15)
	gs.indice_escada = gs._inteiro_valido(c.get("ladder_index", 0), float(gs.lutas.adversarios.size()))
	# O cinturão é consequência de a escada ter passado do adversário que o dá (Fase 5: o Muralha, não o fim da escada).
	var i_cint: int = gs.lutas.indice_cinturao()
	gs.cinturao = i_cint >= 0 and gs.indice_escada > i_cint
	_corrigir_local_pela_escada()
	var t := str(c.get("tactic", ""))
	gs.tatica = t if not gs.lutas.tatica(t).is_empty() else gs.lutas.tatica_padrao
	gs.tempo_jogo = gs._numero_valido(c.get("play_seconds", 0.0))
	gs.dinheiro_ganho = gs._numero_valido(c.get("money_earned", 0.0))
	gs.luta = _validar_luta(c.get("fight", null))
	# Fase 5.3: relógio e data. Data ausente ou inválida = folga cheia a partir do dia de hoje.
	gs.segundos_campanha = gs._numero_valido(c.get("campaign_seconds", 0.0))
	var fd := -1
	if not gs.escada_completa():
		var bruto = c.get("fight_day", null)
		fd = gs._inteiro_valido(bruto, 1.0e9) if (typeof(bruto) == TYPE_FLOAT or typeof(bruto) == TYPE_INT) else 0
		if fd <= 0 or fd > gs.dia_campanha() + 999:
			fd = gs._calendario._data_da_proxima_luta()
	gs.fight_day = fd
	gs._dia_anterior = gs.dia_campanha()
	gs._aviso_data_chave = -2
	gs._dia_chegou_emitido = false
	gs._academia.liberar_ao_carregar()  # 7b1: save antigo de quem já venceu o Kid recebe o Muay Thai
	gs.nos_ativos_ids = _validar_ativos(c.get("active_nodes", null))
	gs._arvore._recalcular_bonus()
	gs._academia._atualizar_passiva()
	gs.nivel_metronomo = gs._inteiro_valido(c.get("metronome_level", 0), float(gs.metronomo_niveis()))
	gs._acc_metronomo = 0.0
	gs._acc_assist = gs._aparelhos._assist_primeiro()
	gs._chave_melhor = ""
	gs.fim = _validar_fim(estado.get("ending", null))
	# Fase 6a: escola (depois de permanente e fim: o padrão depende deles) e estado volátil das falas
	gs.gestos_calcados = gs._escola._validar_gestos(c.get("gestured_gloves", []))
	gs.escola = gs._escola._validar_escola(estado.get("school", null), not estado.is_empty())
	# 7a2: convite do Osmar e AQUECIDO (precisam da escola e da arte já validadas); o minigame em andamento nunca é salvo
	gs.treino_fora = ""
	gs._treino_jogo = null
	gs._treino_premio = {}
	gs.convite = gs._treino.validar(c.get("training_invite", null))
	gs._convite_local = gs.local_id
	gs._convite_vis = ""
	for b in gs.caixas_lista:  # 6c2: o hall pode ter baixado os cliques da caixa
		b["hits"] = mini(int(b.hits), maxi(0, gs.cliques_para_abrir() - 1))
	# Fase 6b1: passar o posto. O estado da sucessão vem do save (school.handover); o discípulo depois dele.
	gs._sucessao._aplicar_handover_da_carga()
	gs.discipulo = gs._sucessao._validar_discipulo(c.get("disciple", null), not c.is_empty())
	var greeted = c.get("mentor_greeted", true)  # ausente = true: save sem o campo não dispara toques no meio da campanha
	gs.mentor_cumprimentou = typeof(greeted) != TYPE_BOOL or greeted
	gs._escola._reiniciar_falas()
	for arte_def in gs.academia.artes:  # 7b1: arte liberada cuja fala do Osmar ainda não passou (save antigo ou fechou antes de ver)
		if gs._academia.fala_de_liberacao_pendente(str(arte_def.id)):
			gs._escola._gravar_marco(str(arte_def.id) + "_unlocked", {}, false)
			gs.disparar_gatilho(str(arte_def.id) + "_unlocked")
		if gs._academia.fala_passiva2_pendente(str(arte_def.id)):  # 7b2: a fala da 2ª passiva também nunca se perde
			gs._escola._gravar_marco("passive2_%s_unlocked" % arte_def.id, {}, false)
			gs.disparar_gatilho("passive2_%s_unlocked" % arte_def.id)
	gs._luta._finalizar_motivo(false)
	gs._motivo_cache = {}

	_emitir_tudo()


# Luta salva: adversário inexistente (ou fora da vez) ou formato ruim é descartada, sem vitória nem derrota.
func _validar_luta(v: Variant) -> Dictionary:
	if v == null:
		return {}
	if not (v is Dictionary):
		gs._avisar("Luta salva inválida: descartada.")
		return {}
	var opp := gs.lutas.adversario(str(v.get("opponent", "")))
	var r = v.get("result", null)
	var p = v.get("player", null)
	if opp.is_empty() or gs.lutas.indice_adversario(opp.id) != gs.indice_escada or not (r is Dictionary) or not (p is Dictionary) 			or not r.has("win") or not gs._carreira._local_permite(opp):
		gs._avisar("Luta salva com adversário inexistente ou dados inválidos: descartada.")
		return {}
	var tt := str(v.get("tactic", ""))
	var motivo_salvo = v.get("reason", null)
	var luta_ok := {
		"opponent": opp.id, "tactic": tt if not gs.lutas.tatica(tt).is_empty() else gs.lutas.tatica_padrao,
		"seed": gs._inteiro_valido(v.get("seed", 0), 4294967295.0),
		"player": {"strength": gs._numero_valido(p.get("strength", 0.0)), "agility": gs._numero_valido(p.get("agility", 0.0)),
			"endurance": gs._numero_valido(p.get("endurance", 0.0))},
		"result": {"win": r.win == true, "ko": r.get("ko", false) == true, "t_ko": gs._numero_ou(r.get("t_ko", -1.0), -1.0),
			"t_end": gs._numero_valido(r.get("t_end", 0.0)), "round": gs._inteiro_valido(r.get("round", 0), 1000.0),
			"pct_player": gs._numero_valido(r.get("pct_player", 0.0)), "pct_opponent": gs._numero_valido(r.get("pct_opponent", 0.0))},
	}
	# 7a1: `finish` é opcional (save antigo sem ele vale "damage" se ko, senão "points"; a UI usa luta_atual().result.finish).
	# Incoerente (editado à mão) = campo descartado: precisa bater com `ko`/`win` e com a arte da carreira.
	var fim := str(r.get("finish", ""))
	var tipo_arte := str(gs.motor.passiva.get("type", ""))  # 7b2: a passiva que vale na carreira (1ª ou 2ª)
	var ko_ok: bool = luta_ok.result.ko
	var ganhou: bool = luta_ok.result.win
	var coerente: bool = (fim == "damage" and ko_ok) or (fim == "points" and not ko_ok) 		or (fim == "knockout" and ko_ok and ganhou and tipo_arte == "fast_hands") 		or (fim == "submission" and ko_ok and ganhou and tipo_arte == "submission") 		or (fim == "spin_kick" and ko_ok and ganhou and tipo_arte == "shin") 		or (fim == "counter_ko" and ko_ok and ganhou and tipo_arte == "counter_punch") 		or (fim == "ground_stop" and ko_ok and ganhou and tipo_arte == "top_control") 		or (fim == "knee_ko" and ko_ok and ganhou and tipo_arte == "thai_clinch")
	if coerente and tipo_arte != "":  # sem arte o jogo nunca grava `finish`
		luta_ok.result["finish"] = fim
	# Motivo calculado em lutar(); ausente (save antigo) = calculado sob demanda.
	if motivo_salvo is Dictionary and not motivo_salvo.is_empty():
		luta_ok["reason"] = motivo_salvo.duplicate(true)
	return luta_ok


func _validar_permanente(v: Variant) -> Dictionary:
	var p: Dictionary = v if v is Dictionary else {}
	var r := {
		"legacy_total": gs._inteiro_valido(p.get("legacy_total", 0), 1.0e15),
		"career_number": maxi(1, gs._inteiro_valido(p.get("career_number", 1), 1.0e9)),
		"careers_finished": gs._inteiro_valido(p.get("careers_finished", 0), 1.0e9),
		"best_wins": gs._inteiro_valido(p.get("best_wins", 0), 1.0e9),
		"belts_won": gs._inteiro_valido(p.get("belts_won", 0), 1.0e9),
		"skill_nodes": _validar_nos(p.get("skill_nodes", [])),
		"revenge_opponent": _validar_algoz(p.get("revenge_opponent", "")),
		"arts_unlocked": _validar_artes_liberadas(p.get("arts_unlocked", [])),
		"last_art": _validar_arte_id(p.get("last_art", "")),
	}
	_validar_passivas2(p, r)
	r["tree_last_node"] = _validar_ultimo_no(p.get("tree_last_node", ""), r.skill_nodes)  # Fase 5.4
	return r


# Nós salvos: ignora id inexistente ou repetido e nó cujo `requires` não está na lista (com aviso).
func _validar_nos(v: Variant) -> Array:
	var saida: Array = []
	if not (v is Array):
		return saida
	for x in v:
		var id := str(x)
		if gs.lutas.no_da_arvore(id).is_empty() or id in saida:
			gs._avisar("Nó da árvore salvo inválido ou repetido (%s): ignorado." % id)
			continue
		saida.append(id)
	var mudou := true
	while mudou:
		mudou = false
		for id in saida.duplicate():
			var pai: String = gs.lutas.no_da_arvore(id).requires
			if pai != "" and not (pai in saida):
				gs._avisar("Nó da árvore salvo sem o anterior (%s): ignorado." % id)
				saida.erase(id)
				mudou = true
	return saida


func _validar_algoz(v: Variant) -> String:
	var id := str(v) if v is String else ""
	return id if not gs.lutas.adversario(id).is_empty() else ""


# Tela de fim pendente: tipo desconhecido ou formato ruim vira "nenhuma".
func _validar_fim(v: Variant) -> Dictionary:
	if v == null:
		return {}
	if not (v is Dictionary) or not (str(v.get("kind", "")) in ["defeat", "retire"]):
		gs._avisar("Tela de fim salva inválida: descartada.")
		return {}
	var s = v.get("summary", {})
	if not (s is Dictionary):
		s = {}
	var r = v.get("result", {})
	var rs = v.get("reason", {})
	var pl = v.get("player", {})
	return {
		"kind": str(v.kind), "career_number": maxi(1, gs._inteiro_valido(v.get("career_number", 1), 1.0e9)),
		"legacy_gained": gs._inteiro_valido(v.get("legacy_gained", 0), 1.0e15),
		"legacy_notebook": gs._inteiro_valido(v.get("legacy_notebook", 0), 1.0e15),
		"legacy_total": gs._inteiro_valido(v.get("legacy_total", 0), 1.0e15),
		"honor_gained": gs._inteiro_valido(v.get("honor_gained", 0), 1.0e15),
		"opponent": str(v.get("opponent", "")), "tactic": str(v.get("tactic", "")),
		"seed": gs._inteiro_valido(v.get("seed", 0), 4294967295.0),
		"player": pl.duplicate(true) if pl is Dictionary else {},
		"result": r.duplicate(true) if r is Dictionary else {},
		"reason": rs.duplicate(true) if rs is Dictionary else {},
		"summary": {"wins": gs._inteiro_valido(s.get("wins", 0), 1.0e9), "belts": gs._inteiro_valido(s.get("belts", 0), 1.0e9),
			"fame": gs._inteiro_valido(s.get("fame", 0), 1.0e15), "money_earned": gs._numero_valido(s.get("money_earned", 0.0)),
			"play_seconds": gs._numero_valido(s.get("play_seconds", 0.0)), "art": _validar_arte_id(s.get("art", "")),
			"location": str(s.get("location", ""))},
	}


func _emitir_tudo(pedir_arte: bool = true) -> void:
	gs._metro_prev = gs.nivel_metronomo  # Fase 6a: carga e NOVA CAMPANHA não contam como compra
	gs._crew_prev = gs.crew_click_comprado
	gs.treino_mudou.emit(gs.treino)
	gs.aquecido_mudou.emit(gs.aquecido())  # 7a2
	for id in gs.atributos:
		gs.atributo_mudou.emit(id, gs.atributos[id])
	gs.foco_mudou.emit(gs.foco)
	gs.dinheiro_mudou.emit(gs.dinheiro)
	gs.fama_mudou.emit(gs.fama)
	gs.tatica_mudou.emit(gs.tatica)
	gs.luva_mudou.emit(gs.luvas_abertas(), gs.sufixo_luva())
	gs.caixas_mudaram.emit()
	gs.metronomo_mudou.emit(gs.nivel_metronomo)
	gs.crew_click_mudou.emit(gs.crew_click_comprado)
	gs.local_mudou.emit(gs.local_id)
	gs.arte_mudou.emit(gs.arte_id)
	gs._aparelhos._atualizar_estado_assist()
	gs.escada_mudou.emit()
	gs.economia_mudou.emit()
	gs.carreira_mudou.emit()
	gs.honra_mudou.emit(gs.honra())
	gs.hall_mudou.emit()
	gs.campanha_completa_mudou.emit()
	if gs.risco_hud_ativo:
		gs.atualizar_risco_hud()
	gs._calendario._verificar_calendario()  # reabrir com Faltam <= 3 mostra a faixa uma vez; no dia, abre a prévia do dia
	gs._calendario._checar_sala()
	if pedir_arte and gs.escolha_arte_pendente():
		gs.escolha_arte_pedida.emit(gs.escolha_arte_primeira())


# Pasta do save: "--save-dir=..." na linha de comando, pasta de testes em --script, ou a real.
func _pasta_save_inicial() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-dir="):
			return arg.trim_prefix("--save-dir=")
	var args := OS.get_cmdline_args()
	if "--script" in args or "-s" in args:
		return gs.PASTA_SAVE_TESTES
	return SaveStore.PASTA_REAL


func _horario_local(unix: int) -> String:
	var bias_s: int = Time.get_time_zone_from_system().get("bias", 0) * 60
	return Time.get_time_string_from_unix_time(unix + bias_s)


# career.location e career.art: inexistente volta ao padrão (arte fora das liberadas vira ""), tudo com aviso.
func _validar_local_e_arte(c: Dictionary) -> void:
	var l := str(c.get("location", ""))
	if gs.academia.local(l).is_empty():
		if c.has("location"):
			gs._avisar("Local salvo inexistente ('%s'): voltou para o padrão." % l)
		l = gs.academia.local_padrao
	gs.local_id = l
	var a := str(c.get("art", ""))
	if a != "" and (gs.academia.arte(a).is_empty() or not (a in gs.permanente.arts_unlocked)):
		gs._avisar("Arte salva inexistente ou não liberada ('%s'): ignorada." % a)
		a = ""
	gs.arte_id = a
	gs.arte_segundos = gs._numero_valido(c.get("art_seconds", 0.0)) if a != "" else 0.0
	# 7b2: career.art_passive (ausente = 1). A 2ª só vale com a arte, a 2ª passiva dela e a meta batida; senão volta para a 1ª (com aviso).
	var ap := 1
	var bruto_ap = c.get("art_passive", 1)
	if (typeof(bruto_ap) == TYPE_INT or typeof(bruto_ap) == TYPE_FLOAT) and int(bruto_ap) == 2:
		if a != "" and not gs.academia.arte(a).passive_2.is_empty() and (a in gs.permanente.get("passives_unlocked", [])):
			ap = 2
		else:
			gs._avisar("Carreira salva com a 2ª passiva sem a meta batida ('%s'): voltou para a 1ª." % a)
	gs.passiva_carreira = ap
	gs._academia._atualizar_passiva()


# Escada além do 1º adversário de outro local com a carreira na garagem (save editado): vai para esse local.
func _corrigir_local_pela_escada() -> void:
	for i in gs.lutas.adversarios.size():
		var loc := str(gs.lutas.adversarios[i].location)
		if loc != gs.academia.local_padrao:
			if gs.indice_escada > i and gs.local_id == gs.academia.local_padrao and not gs.academia.local(loc).is_empty():
				gs._avisar("Escada passou do 1º adversário de '%s' na garagem: carreira movida para lá." % loc)
				gs.local_id = loc
			return


func _validar_artes_liberadas(v: Variant) -> Array:
	var r: Array = []
	if not (v is Array):
		return r
	for x in v:
		var id := str(x)
		if gs.academia.arte(id).is_empty() or id in r:
			gs._avisar("Arte liberada inválida ou repetida ('%s'): ignorada." % id)
			continue
		r.append(id)
	return r


func _validar_arte_id(v: Variant) -> String:
	var id := str(v) if v is String else ""
	return id if not gs.academia.arte(id).is_empty() else ""


# 7b2: vitórias pela 1ª passiva (soma da linhagem), 2ªs passivas liberadas e a última escolhida. Tudo opcional (save antigo = vazio).
# Só vale arte que tem `passive_2`; a meta batida (passive_wins >= count) libera a 2ª mesmo que a lista tenha se perdido.
func _validar_passivas2(p: Dictionary, r: Dictionary) -> void:
	var vitorias := {}
	var bruto = p.get("passive_wins", {})
	if bruto is Dictionary:
		for id in bruto:
			var a := gs.academia.arte(str(id))
			if a.is_empty() or a.passive_2.is_empty():
				continue
			if typeof(bruto[id]) in [TYPE_INT, TYPE_FLOAT]:
				vitorias[str(id)] = gs._inteiro_valido(bruto[id], 1.0e9)
	var liberadas: Array = []
	var lista = p.get("passives_unlocked", [])
	if lista is Array:
		for x in lista:
			var a := gs.academia.arte(str(x))
			if not a.is_empty() and not a.passive_2.is_empty() and not (str(x) in liberadas):
				liberadas.append(str(x))
	for a in gs.academia.artes:
		if not a.passive_2.is_empty() and int(vitorias.get(a.id, 0)) >= int(a.passive_2.unlock.count) and not (a.id in liberadas):
			liberadas.append(a.id)
	var ultima := {}
	var lp = p.get("last_passive", {})
	if lp is Dictionary:
		for id in lp:
			if str(id) in liberadas and typeof(lp[id]) in [TYPE_INT, TYPE_FLOAT] and int(lp[id]) == 2:
				ultima[str(id)] = 2
			elif not gs.academia.arte(str(id)).is_empty():
				ultima[str(id)] = 1
	r["passive_wins"] = vitorias
	r["passives_unlocked"] = liberadas
	r["last_passive"] = ultima


# Fase 5.4: último nó comprado (centro do mapa). Id desconhecido ou não comprado volta para o último de skill_nodes ("" se não há).
func _validar_ultimo_no(v: Variant, nos: Array) -> String:
	var id := str(v) if v is String else ""
	if id != "" and id in nos:
		return id
	return str(nos[-1]) if not nos.is_empty() else ""


# Fase 5.4: career.active_nodes. Ausente (save antigo) = cópia de skill_nodes; senão só ids conhecidos, comprados e sem repetição.
func _validar_ativos(v: Variant) -> Array:
	var nos: Array = gs.permanente.get("skill_nodes", [])
	if not (v is Array):
		return nos.duplicate()
	var r: Array = []
	for x in v:
		var id := str(x)
		if id in nos and not (id in r) and not gs.lutas.no_da_arvore(id).is_empty():
			r.append(id)
	return r
