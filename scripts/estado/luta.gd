extends RefCounted
## Táticas, prévia, risco, revanche e a luta (incluindo o cálculo do motivo em segundo plano).
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


## Atributos que entram na conta da luta: com AQUECIDO (7a2) valem x1,03. Prévia, risco do HUD, chance e motor passam por aqui.
func _atributos_array() -> Array:
	var m := gs._treino.mult_aquecido()
	var a := _atributos_cru()
	return a if m == 1.0 else [a[0] * m, a[1] * m, a[2] * m]


## Os atributos de verdade, sem AQUECIDO (o que a tela mostra como "você").
func _atributos_cru() -> Array:
	return [gs.atributos.get("strength", 0.0), gs.atributos.get("agility", 0.0), gs.atributos.get("endurance", 0.0)]


func _array_adversario(opp: Dictionary) -> Array:
	return [opp.strength, opp.agility, opp.endurance]


func definir_tatica(tatica_id: String) -> bool:
	if gs.lutas.tatica(tatica_id).is_empty():
		return false
	if tatica_id != gs.tatica:
		gs.tatica = tatica_id
		gs.tatica_mudou.emit(gs.tatica)
		atualizar_risco_hud()
	return true


## Risco de uma tática contra o próximo adversário: {label: "easy"|"even"|"hard", chance}.
## `chance` é só para testes e depuração: a tela NÃO mostra a porcentagem (Fase 4).
func risco_tatica(tatica_id: String = "") -> Dictionary:
	var opp := gs.proximo_adversario()
	if opp.is_empty():
		return {}
	var t := gs.tatica if tatica_id == "" else tatica_id
	var p := gs.motor.chance(_atributos_array(), _array_adversario(opp), t)
	return {"label": gs.motor.rotulo(p), "chance": p}


## Dados da janela de prévia (calcula as 3 táticas: ~600 lutas). Não muda nada no jogo.
func previa() -> Dictionary:
	var opp := gs.proximo_adversario()
	if opp.is_empty():
		return {}
	var jog := _atributos_array()
	var cru := _atributos_cru()
	var adv := _array_adversario(opp)
	var riscos := {}
	var com_porcentagem := tem_previa_detalhada()
	var com_passiva: bool = not gs.motor.passiva.is_empty()
	var passivas := {}  # 7a1: linha da passiva de cada tática (a UI troca sem recalcular)
	for t in gs.lutas.taticas:
		if com_passiva:
			# Mesma conta de risco_tatica (chance_detalhada é a chance do motor), mais as vitórias pela passiva.
			var det: Dictionary = gs.motor.chance_detalhada(jog, adv, t.id)
			riscos[t.id] = {"label": gs.motor.rotulo(det.chance), "chance": det.chance}
			passivas[t.id] = gs._textos.passiva_da_previa(gs.motor.estado_passiva(jog, adv, t.id), det, t.id)
		else:
			riscos[t.id] = risco_tatica(t.id)
		riscos[t.id]["percent"] = gs._textos._porcentagem(riscos[t.id].chance)
	var rotulo: String = riscos[gs.tatica].label if riscos.has(gs.tatica) else ""
	var r := {
		"opponent": opp.duplicate(), "you": {"strength": cru[0], "agility": cru[1], "endurance": cru[2]},
		"tactic": gs.tatica, "risks": riscos, "risk": rotulo,
		"lead": gs.motor.destaque(jog, adv),
		"stake_win": gs.texto_stake_win(opp),
		"stake_belt": opp.belt,
		# Fase 4
		"stake_lose": gs.texto_stake_lose(),
		"show_percent": com_porcentagem,
		"percent": int(riscos[gs.tatica].percent) if riscos.has(gs.tatica) else 0,
		"percent_text": gs.preencher(gs.texto_ui("preview_percent", "{n}%"), {"n": int(riscos[gs.tatica].percent)}) if riscos.has(gs.tatica) else "",
		"revenge": e_algoz(opp.id),
		"wait_green": esperar_verde(opp.id, rotulo),
		# Fase 5/7a1: texto curto da passiva da arte (o mesmo do cartão da janela de escolha); "" sem arte
		"art": gs.arte_id,
		"art_fight_text": gs.texto_passiva(gs.arte_id, gs.passiva_carreira),
		"art_passive": gs.passiva_carreira if gs.arte_id != "" else 0,  # 7b2: qual passiva vale nesta carreira (1 | 2)
		# Fase 6c2: nó "Caderno de recordes" (fora do verde); "" até ficar pronto (sinal previa_falta_pronta)
		"missing_line": gs._honra._linha_o_que_falta(opp, jog, adv, rotulo),
	}
	if com_passiva:
		# Fase 7a1 (só com arte): passive_name, passive_line, passive_state, passive_share, passive_share_n da tática escolhida;
		# passive_tactics = {id_da_tática: o mesmo bloco} para a UI trocar de tática sem recalcular.
		var atual: Dictionary = passivas.get(gs.tatica, {})
		r["passive_name"] = atual.get("name", "")
		r["passive_line"] = atual.get("line", "")
		r["passive_state"] = atual.get("state", {})
		r["passive_share"] = atual.get("share", "")
		r["passive_share_n"] = atual.get("share_n", 0)
		r["passive_tactics"] = passivas
	if gs.aquecido():
		r.merge(gs._treino.extras_previa(riscos, cru, adv, com_passiva))  # 7a2: a prévia mostra o AQUECIDO e o quanto ele pesa
	return r


## Dinheiro da vitória contra `opp` com o bônus da árvore.
func premio_dinheiro(opp: Dictionary) -> float:
	return float(opp.prize_money) * (1.0 + gs._arvore._b("money_bonus"))


## Fama da vitória contra `opp` com o bônus da árvore (inteiro, arredondado).
func premio_fama(opp: Dictionary) -> int:
	return int(floor(float(opp.prize_fame) * (1.0 + gs._arvore._b("fame_bonus")) + 0.5))


func tem_previa_detalhada() -> bool:
	return gs._arvore._b("preview_percent") > 0.0


## `permanent.revenge_opponent`: id do adversário que encerrou a última carreira ("" = sem marca).
func algoz() -> String:
	return str(gs.permanente.get("revenge_opponent", ""))


func e_algoz(adversario_id: String) -> bool:
	return adversario_id != "" and adversario_id == algoz()


## Alavanca L1 (decisão D2): "ESPERE FICAR VERDE" contra o algoz e contra todo adversário antes dele na escada,
## enquanto o rótulo da tática escolhida não é "easy". Só texto: não bloqueia nada.
func esperar_verde(adversario_id: String, rotulo: String) -> bool:
	var a := algoz()
	if a == "" or adversario_id == "" or rotulo == "easy" or rotulo == "":
		return false
	var i_alvo := gs.lutas.indice_adversario(adversario_id)
	var i_algoz := gs.lutas.indice_adversario(a)
	return i_alvo >= 0 and i_algoz >= 0 and i_alvo <= i_algoz


## Para o bloco "PRÓXIMA" do HUD: marca de revanche e dica do verde do próximo adversário.
func info_proxima() -> Dictionary:
	var opp := gs.proximo_adversario()
	if opp.is_empty():  # `move`: precisa mudar de local; `end`: escada completa
		return {"revenge": false, "wait_green": false, "move": gs.precisa_mudar(), "end": gs.escada_completa()}
	var r: Dictionary = gs._risco_hud
	var rotulo: String = r.rotulo if r.adversario == opp.id else ""
	return {"revenge": e_algoz(opp.id), "wait_green": esperar_verde(opp.id, rotulo), "move": false, "end": false}


## Último risco calculado para o HUD: {adversario, rotulo ("easy"|"even"|"hard"|""), tatica}.
func risco_proxima() -> Dictionary:
	return gs._risco_hud.duplicate()


## Recalcula o risco do HUD (200 lutas) e emite `risco_proxima_mudou` se mudou.
func atualizar_risco_hud() -> void:
	var opp := gs.proximo_adversario()
	if opp.is_empty():
		_definir_risco_hud("", "")
		return
	gs._chave_risco = _chave_estado_risco()
	_definir_risco_hud(opp.id, gs.motor.rotulo_rapido(_atributos_array(), _array_adversario(opp), gs.tatica))


func _definir_risco_hud(adversario: String, rotulo: String) -> void:
	var mudou: bool = gs._risco_hud.adversario != adversario or gs._risco_hud.rotulo != rotulo
	gs._risco_hud = {"adversario": adversario, "rotulo": rotulo, "tatica": gs.tatica}
	if mudou:
		gs.risco_proxima_mudou.emit(adversario, rotulo)


func _chave_estado_risco() -> String:
	return "%d|%s|%s|%s|%s%s" % [gs.indice_escada, gs.tatica, gs.atributos.get("strength", 0.0), gs.atributos.get("agility", 0.0),
		gs.atributos.get("endurance", 0.0), "|warm" if gs.aquecido() else ""]


# No máximo 1 vez por `hud_refresh_seconds` e só se algum atributo (ou a tática) mudou.
func _tick_risco(delta: float) -> void:
	if not gs.risco_hud_ativo or not gs.luta.is_empty():
		return
	gs._tempo_risco += delta
	if gs._tempo_risco < float(gs.lutas.risco.hud_refresh_seconds):
		return
	gs._tempo_risco = 0.0
	if _chave_estado_risco() != gs._chave_risco:
		atualizar_risco_hud()


## LUTAR: simula a luta inteira, grava `career.fight` e salva ANTES da animação. Devolve o mesmo que
## `luta_atual()` ({} se não pode lutar). A UI só anima a lista de eventos.
func lutar() -> Dictionary:
	if not gs.pode_lutar():
		return {}
	gs._reacao_cena = ""  # lutar antes do 1º clique: a reação da cena se perde, os toques seguem a regra comum
	gs._casa._interromper_saida()
	var opp := gs.proximo_adversario()
	var jog := _atributos_array()
	var semente := int(gs.rng.randi())
	var res := gs.motor.lutar(jog, _array_adversario(opp), gs.tatica, semente, false)
	gs.luta = {"opponent": opp.id, "tactic": gs.tatica, "seed": semente,
		"player": {"strength": jog[0], "agility": jog[1], "endurance": jog[2]},
		"result": _resultado_salvo(res)}
	gs._motivo_cache = {}
	gs._treino.gastar_aquecido()  # 7a2: o AQUECIDO vale só para esta luta (ganhe ou perca)
	gs.salvar()
	# O motivo (busca cara, ~100-200 ms) é calculado em segundo plano em TODA luta (custo igual na
	# vitória e na derrota); na vitória é descartado. Fica salvo antes de concluir_luta().
	_iniciar_motivo_fundo()
	var info := luta_atual()
	gs.luta_iniciada.emit(info)
	return info


# Segundo plano: só lê dados (motor, lutas) e escreve em `_motivo_fundo`; o resultado é recolhido na thread principal.
func _iniciar_motivo_fundo() -> void:
	_finalizar_motivo(false)
	var snap := gs.luta.duplicate(true)
	gs._motivo_fundo = {}
	gs._motivo_tarefa = WorkerThreadPool.add_task(func() -> void: gs._motivo_fundo = _calcular_motivo(snap))
	gs._motivo_seed = int(snap.seed)


## Recolhe o motivo calculado em segundo plano. Com `esperar`, bloqueia até terminar (só no fim da luta/testes).
## Se a luta atual é derrota, guarda o motivo em luta["reason"] e salva.
func _finalizar_motivo(guardar: bool, esperar: bool = true) -> void:
	if gs._motivo_tarefa < 0:
		return
	if not esperar and not WorkerThreadPool.is_task_completed(gs._motivo_tarefa):
		return
	WorkerThreadPool.wait_for_task_completion(gs._motivo_tarefa)
	gs._motivo_tarefa = -1
	var pronto := gs._motivo_fundo
	gs._motivo_fundo = {}
	if guardar and not gs.luta.is_empty() and not gs.luta.result.win and int(gs.luta.seed) == gs._motivo_seed \
			and not pronto.is_empty():
		gs.luta["reason"] = pronto
		gs.salvar()


## Espera o cálculo em segundo plano e deixa o motivo salvo (usado pelos testes e pelo fechamento).
func aguardar_motivo() -> void:
	_finalizar_motivo(true)


func _resultado_salvo(res: Dictionary) -> Dictionary:
	var r := {"win": res.win, "ko": res.ko, "t_ko": res.t_ko, "t_end": res.t_end, "round": res.round,
		"pct_player": res.pct_player, "pct_opponent": res.pct_opponent}
	if res.has("finish"):  # 7a1: só lutas com arte; save sem ele = "damage" se ko, senão "points"
		r["finish"] = res.finish
	return r


## Prefixo do cenário da luta (7a1): a arena é a do local do ADVERSÁRIO (`location`, padrão garagem).
## "arena" = borracharia; "arena_league" = ginásio da liga da academia. A arte do cenário mora no manifest.
func arena_da_luta(adversario_id: String) -> String:
	var opp := gs.lutas.adversario(adversario_id)
	var local_id := str(opp.get("location", gs.academia.local_padrao)) if not opp.is_empty() else gs.academia.local_padrao
	return str(gs.academia.local(local_id).get("fight_arena", "arena"))


## Luta em andamento recalculada da semente (determinística): eventos, tempos e resultado.
## Formato completo em docs/fases/fase3-api.md. {} se não há luta.
func luta_atual() -> Dictionary:
	if gs.luta.is_empty():
		return {}
	var opp := gs.lutas.adversario(gs.luta.opponent)
	var p: Dictionary = gs.luta.player
	var jog := [p.strength, p.agility, p.endurance]
	var res := gs.motor.lutar(jog, _array_adversario(opp), gs.luta.tactic, int(gs.luta.seed), true)
	var salvo: Dictionary = gs.luta.result
	if bool(salvo.win) != bool(res.win) or bool(salvo.ko) != bool(res.ko):
		push_warning("GameState: a luta salva não bate com a simulação (dados mudaram?); vale o resultado salvo.")
	return _montar_info_luta(opp, res, salvo)


func _montar_info_luta(opp: Dictionary, res: Dictionary, salvo: Dictionary) -> Dictionary:
	var c: Dictionary = gs.lutas.combate
	var tj := gs.lutas.tatica(str(gs.luta.tactic))
	var neutra := Luta.NEUTRA
	var taticas_lado := [tj if not tj.is_empty() else neutra, neutra]
	var eventos: Array = []
	var vmax: Array = res.life_max
	var n: int = res.events.size()
	# Golpes (só visual, nunca muda o resultado): cada lado usa os golpes do seu estilo. Jogador = boxe por enquanto;
	# `liberados` é o gancho para a árvore de habilidades liberar golpes (ids de nós) no futuro.
	var liberados: Array = []
	# 7a1: Jiu-jitsu usa o estilo "bjj" (em pé e no chão); Boxe e sem arte seguem com "boxing".
	var passiva: Dictionary = gs.motor.passiva
	var tipo_passiva := str(passiva.get("type", ""))
	var eh_top: bool = tipo_passiva == "top_control"  # 7b2: Por cima (Jiu-jitsu): chão pelo evento `ground`, sem pegada
	var eh_cl: bool = tipo_passiva == "thai_clinch"  # 7b2: Clinch (Muay Thai): `clinch` preso, joelhada
	var eh_jj: bool = tipo_passiva == "submission" or eh_top
	var eh_mt: bool = tipo_passiva == "shin"  # 7b1: Muay Thai usa o estilo "muay_thai"
	var golpes_lado: Array = [gs.golpes.disponiveis("bjj" if eh_jj else ("muay_thai" if (eh_mt or eh_cl) else "boxing"), liberados),
		gs.golpes.disponiveis(str(opp.get("style", "boxing")))]
	var golpes_baixo: Array = gs.golpes.disponiveis("ground_bottom")
	var fase := "standing"
	var chao_na_pegada := float(passiva.get("ground_at_grip", 0.5)) if eh_jj else 2.0
	var golpe_anterior: Array = ["", ""]
	var semente_golpes := int(gs.luta.seed)
	for i in n:
		var e: Dictionary = res.events[i]
		var alvo: int = 1 - int(e.who)
		var def_t: Dictionary = taticas_lado[alvo]
		var fator_crit: float = 1.0 + (float(c.crit_multiplier) - 1.0) * (1.0 - float(def_t.crit_guard))
		var tipo: String = e.type
		var kind := "jab"
		if tipo == "dodge":
			kind = "dodge"
		elif e.counter:
			kind = "counter"
		elif tipo == "crit" and fator_crit > 1.0 + 1.0e-9:
			kind = "crit"
		var bloqueou: bool = tipo != "dodge" and bool(def_t.block)
		var d_anim := "dodge" if tipo == "dodge" else ("block" if bloqueou else "hit")
		var lado := int(e.who)
		var golpe_id := ""
		var golpe_anim := ""
		var reacao := ""
		var fase_depois := fase
		var fim_passiva := str(e.get("finish", ""))
		var mt_golpe := str(e.get("move", "")) if eh_mt and lado == 0 else ""
		var p2_golpe := str(e.get("move", "")) if (eh_top or eh_cl) and lado == 0 else ""  # 7b2: takedown | ground | clinch | knee | hit
		if mt_golpe == "spin":
			kind = "spin_kick"  # todo crítico com a perna cheia é chute rodado (derrube ou não)
		if eh_top:
			if kind != "dodge" and p2_golpe == "takedown":
				kind = "takedown"
			fase_depois = "ground" if bool(e.get("ground", false)) else "standing"  # ele levantou = os dois de pé
		elif eh_cl and kind != "dodge" and (p2_golpe == "clinch" or p2_golpe == "knee"):
			kind = "crit"  # prender e joelhar usam os golpes de crítico do estilo (thai_clinch, knee)
		if eh_jj and not eh_top and kind != "dodge":
			# 1º acerto do jogador com a pegada em ground_at_grip: vira queda e a luta vai para o chão;
			# a finalização também leva ao chão. Só visual (design 7a1 §10.2).
			if lado == 0 and fase == "standing" and (float(e.get("grip", 0.0)) >= chao_na_pegada or fim_passiva == "submission"):
				fase_depois = "ground"
				kind = "takedown"
			if fim_passiva == "submission":
				kind = "submission"
				fase_depois = "ground"
		if kind != "dodge":
			var cands: Array = golpes_lado[lado]
			var fase_golpe := ""
			if eh_jj:
				fase_golpe = fase if kind != "takedown" and kind != "submission" else ""
				if lado == 1 and fase == "ground":
					cands = golpes_baixo
			golpe_id = gs.golpes.escolher(cands, kind, semente_golpes, i, str(golpe_anterior[lado]), fase_golpe)
			if golpe_id != "":
				golpe_anterior[lado] = golpe_id
				golpe_anim = str(gs.golpes.golpes[golpe_id].anim)
				if d_anim == "hit":
					reacao = str(gs.golpes.golpes[golpe_id].defender_anim)
					if kind == "spin_kick" and fim_passiva != "spin_kick":
						reacao = "hit_spin"  # o rodado que não derruba: torce e volta à guarda (só o final usa fall_spin)
		eventos.append({
			"t": e.t, "who": e.who, "target": alvo, "type": tipo, "counter": e.counter,
			"kind": kind, "attack_anim": "heavy" if kind == "crit" or kind == "counter" or kind == "spin_kick" else "jab",
			"move": golpe_id, "move_anim": golpe_anim, "defender_move_anim": reacao,
			"defender_anim": d_anim, "blocked": bloqueou,
			"damage": e.damage, "life_after": e.life_after, "life_pct_after": e.life_after / vmax[alvo],
			"round": int(floor(float(e.t) / float(c.round_length))) + 1,
			"ko": bool(salvo.ko) and i == n - 1,
			# 7a1: embalo (Boxe), pegada 0-1 (Jiu-jitsu), cansaço (Boxe), fim ("" | knockout | submission),
			# fase visual ("standing" | "ground") e fase depois do evento (a queda começa em pé e termina no chão).
			"streak": int(e.get("streak", 0)), "grip": float(e.get("grip", 0.0)), "tired": bool(e.get("tired", false)),
			"finish": fim_passiva, "phase": fase, "phase_after": fase_depois,
			# 7b1 (Muay Thai): marcas inteiras na perna DEPOIS do evento (0-3) e o tipo do golpe ("kick"|"crit"|"spin"; "" no adversário)
			"marks": int(e.get("marks", 0)), "shin_move": mt_golpe,
			# 7b2: Contragolpista (carga 0-3 depois do evento), Por cima (`ground`: no chão depois do evento), Clinch (`clinch`: preso depois
			# do evento) e o que o jogador fez em `passive_move` (takedown | ground | clinch | knee | hit | "")
			"charge": int(e.get("charge", 0)), "ground": bool(e.get("ground", false)), "clinch": bool(e.get("clinch", false)),
			"passive_move": p2_golpe,
		})
		fase = fase_depois
	var perdedor := -1
	if salvo.ko:
		perdedor = 1 if salvo.win else 0
	var t_ko := float(salvo.t_ko)
	var grogue := {}
	if salvo.ko and t_ko < float(c.min_ko_time):
		grogue = {"who": perdedor, "from": t_ko, "to": float(c.min_ko_time)}
	var info := {
		"opponent": opp.id, "tactic": gs.luta.tactic, "seed": int(gs.luta.seed), "player": gs.luta.player.duplicate(),
		"events": eventos, "result": salvo.duplicate(), "grogue": grogue, "loser": perdedor,
		"life_max": {"player": vmax[0], "opponent": vmax[1]},
		"intro_seconds": c.intro_seconds, "outro_seconds": c.outro_seconds,
		"screen_seconds": float(c.intro_seconds) + float(salvo.t_end) + float(c.outro_seconds),
		"counts": res.counts,
		# 7a1: cenário (prefixo da arena), tipo da passiva ("" | fast_hands | submission) e dados para o HUD e o fim.
		"arena": arena_da_luta(str(opp.id)), "passive": str(passiva.get("type", "")),
		"art_passive": gs.passiva_carreira if gs.arte_id != "" else 0,
		"streak_peak": int(res.get("streak_peak", 0)), "attempts": int(res.get("attempts", 0)),
		"grip_full_at": float(res.get("grip_full_at", -1.0)), "tired_at": float(res.get("tired_at", -1.0)),
		# `tires`: o lutador cansa nesta luta (Boxe fora do Defensivo). O evento `tired` só fica true quando `tires` é true.
		"tires": bool(res.get("tires", false)),
	}
	if eh_mt:  # 7b1: dados do HUD das marcas e do letreiro (só com Muay Thai)
		info["marks_max"] = int(passiva.marks_max)
		info["limp_from_marks"] = int(passiva.limp_from_marks)
		info["marks_peak"] = int(res.get("marks_peak", 0))
		info["marks_full_at"] = float(res.get("marks_full_at", -1.0))
		info["spins"] = int(res.get("spins", 0))
	# 7b2: campos das 2ªs passivas na luta (só com a passiva do tipo). Eventos já trazem charge | ground | clinch e move.
	match str(passiva.get("type", "")):
		"counter_punch":
			info["charge_max"] = int(passiva.charge_max)
			info["charge_peak"] = int(res.get("charge_peak", 0))
		"top_control":
			info["takedowns"] = int(res.get("takedowns", 0))
			info["stood_up"] = int(res.get("stood_up", 0))
			info["takedown_at"] = float(res.get("takedown_at", -1.0))
		"thai_clinch":
			info["clinches"] = int(res.get("clinches", 0))
			info["released"] = int(res.get("released", 0))
			info["clinch_at"] = float(res.get("clinch_at", -1.0))
			info["knees"] = int(res.get("knees", 0))
			info["clinch_s"] = float(passiva.clinch_s)
	# Save antigo (ou luta sem arte) não guarda `finish`: "damage" se ko, senão "points". Só na cópia que vai para a UI.
	if not info.result.has("finish"):
		info.result["finish"] = "damage" if bool(salvo.ko) else "points"
	return info


## Fim da animação (ou luta pendente ao reabrir): aplica o resultado UMA vez e salva.
## Vitória: prêmio. Derrota: Legado + tela de fim. Devolve o resumo ({} se não havia luta).
func concluir_luta() -> Dictionary:
	if gs.luta.is_empty():
		return {}
	_finalizar_motivo(true)  # garante o motivo pronto e salvo antes de aplicar o resultado
	var snap := gs.luta.duplicate(true)
	var opp := gs.lutas.adversario(snap.opponent)
	var resumo := {}
	if snap.result.win:
		var pote_antes := gs.legado_em_jogo()
		gs.luta = {}
		var premio := premio_dinheiro(opp)
		var premio_f := premio_fama(opp)
		gs.dinheiro = clampf(gs.dinheiro + premio, 0.0, gs.VALOR_MAXIMO)
		gs.dinheiro_ganho += premio
		gs.fama += premio_f
		gs.indice_escada += 1
		if opp.belt:
			gs.cinturao = true
		# Fase 6a: marcos da escola, gravados no mesmo save do prêmio. A garagem só é salva por vitória AO VIVO
		# sobre o adversário do cinturão (qualquer lutador da escola); nunca por belts_won.
		var recorde := int(gs.permanente.best_wins) > 0 and gs.indice_escada > int(gs.permanente.best_wins)
		var primeira_vitoria := gs._escola._gravar_marco("first_school_win", {}, false)
		var artes_novas := gs._academia.liberar_por_vitoria(str(opp.id))  # 7b1: 1ª vitória contra o Kid libera o Muay Thai (mesmo save)
		var meta := gs._academia.contar_vitoria_passiva(str(snap.result.get("finish", "")))  # 7b2: vitória pela 1ª passiva soma na meta (mesmo save)
		var garagem_salva := false
		if opp.belt:
			garagem_salva = gs._escola._gravar_marco("garage_saved", {"opponent": str(opp.id), "by_first": gs.lutador_atual() == "first"}, false)
		# 6c1: a 1ª vitória de um discípulo na academia, com o John ainda na escola, arma a saída dele (mesmo save do prêmio).
		gs._casa._marcar_vitoria_na_academia(str(opp.id))
		# Revanche: vencer o algoz limpa a marca (no mesmo save do prêmio).
		var revanche := e_algoz(opp.id)
		if revanche:
			gs.permanente["revenge_opponent"] = ""
		# Fase 5.3: a próxima data conta do dia em que esta luta aconteceu (-1 depois do Kid).
		gs.fight_day = gs._calendario._data_da_proxima_luta()
		if gs.escada_completa():
			gs.campanha_completa_mudou.emit()
		var proximo := gs.proximo_adversario()
		var fala_mentor := gs._honra._fala_do_mentor(opp)  # 6c2: só pede; quem fala é o gatilho mentor_won
		resumo = {"win": true, "mentor_line": fala_mentor, "fight_day": gs.fight_day, "opponent": opp.id, "money": premio, "fame": premio_f,
			"legacy_gain": gs.legado_em_jogo() - pote_antes, "legacy_run": gs.legado_em_jogo(), "belt": opp.belt,
			"next": proximo.get("id", ""), "next_name": proximo.get("name", ""), "revenge": revanche,
			"record": recorde, "first_school_win": primeira_vitoria, "garage_saved": garagem_salva,
			"revenge_line": gs.preencher(gs.texto_ui("victory_revenge_line"), {"nome": opp.name}) if revanche else "",
			# 7b2: passive_goal = {} se a luta não contou; senão {art, n, m, text ("2/3 K.O. DE EMBALO"), counted, unlocked_now, ...}.
			# passive2_unlocked = id da arte cuja 2ª passiva abriu AGORA ("" nas outras); passive2_line = o aviso único (texto pronto)
			"passive_goal": meta, "passive2_unlocked": str(meta.get("art", "")) if bool(meta.get("unlocked_now", false)) else "",
			"passive2_line": str(meta.get("text", ""))}
		gs.dinheiro_mudou.emit(gs.dinheiro)
		gs.fama_mudou.emit(gs.fama)
		gs.escada_mudou.emit()
		gs.economia_mudou.emit()
		gs.salvar()
		if revanche or not artes_novas.is_empty() or not meta.is_empty():
			gs.permanente_mudou.emit()
		if bool(meta.get("unlocked_now", false)):
			gs.disparar_gatilho("passive2_%s_unlocked" % meta.art)  # a fala do Osmar (uma vez, na próxima sala livre)
		for arte_nova in artes_novas:
			gs.disparar_gatilho(str(arte_nova) + "_unlocked")  # a fala do Osmar (uma vez, na próxima sala livre)
		atualizar_risco_hud()
	else:
		var motivo := motivo_da_luta(snap)
		gs.luta = {}
		gs._carreira._encerrar_carreira("defeat", snap, motivo)
		resumo = {"win": false, "fim": gs.fim.duplicate(true)}
	gs._motivo_cache = {}
	gs.luta_resolvida.emit(resumo)
	return resumo


## Motivo da derrota (design §7): {attribute, faltaram, who, round, model, tip, stat, better_tactic}.
## Calcula até ~9.000 lutas simuladas: chame durante a animação. Resultado fica em cache.
func motivo_da_luta(snap: Dictionary = {}) -> Dictionary:
	if snap.is_empty():
		snap = gs.luta
		_finalizar_motivo(true)  # já pronto em segundo plano (a animação dura segundos)
		snap = gs.luta
	if snap.is_empty():
		return {}
	var pronto = snap.get("reason", null)
	if pronto is Dictionary and not pronto.is_empty():
		return pronto  # calculado em lutar()
	if not gs._motivo_cache.is_empty() and gs._motivo_cache.get("seed") == int(snap.seed):
		return gs._motivo_cache
	gs._motivo_cache = _calcular_motivo(snap)
	return gs._motivo_cache


func _calcular_motivo(snap: Dictionary) -> Dictionary:
	var opp := gs.lutas.adversario(snap.opponent)
	var p: Dictionary = snap.player
	var jog := [p.strength, p.agility, p.endurance]
	var adv := _array_adversario(opp)
	var tat := str(snap.tactic)
	var seed_i := int(snap.seed)
	var chances := gs.motor.chances_por_tatica(jog, adv)
	var usada: float = chances.get(tat, 0.0)
	var m := gs.motor.explicar(jog, adv, tat, seed_i, usada)
	var res: Dictionary = m.res
	var faltaram := -1.0
	if m.faltaram >= 0.0:
		faltaram = Economia.teto3(m.faltaram)
	var melhor := ""
	var minimo := usada + float(gs.lutas.motivo.tactic_tip_gap) - 1.0e-12
	for t in gs.lutas.taticas:
		if t.id != tat and chances[t.id] >= minimo and (melhor == "" or chances[t.id] > chances[melhor]):
			melhor = t.id
	if m.kind == "luck":
		melhor = ""  # azar nunca culpa a tática
	var r := {
		"seed": seed_i, "kind": m.kind, "attribute": m.attribute, "faltaram": faltaram, "far_n": m.far_n,
		"who": "ko" if res.ko else "points", "round": res.round,
		"model": (seed_i / 3) % 2, "tip": seed_i % 3,
		"stat": m.stat,
		"better_tactic": melhor,
	}
	# 7a1: com arte, 1 linha extra quando a passiva pesou ({id, n, r} ou {}); sem arte a chave nem existe (save igual ao de antes).
	if not gs.motor.passiva.is_empty():
		r["passive_note"] = gs.motor.nota_passiva(res, tat)
	return r
