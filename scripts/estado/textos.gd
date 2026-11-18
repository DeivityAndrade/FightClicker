extends RefCounted
## Textos montados (dicas, efeitos, tela de fim). Nada aqui muda estado.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


## Qualquer texto de data/ui_texts.json pela chave (padrão se faltar).
func texto_ui(chave: String, padrao: String = "") -> String:
	return str(gs.dados.ui.get(chave, padrao))


## Texto do efeito de uma melhoria, ex.: "x3 POR CLIQUE: SACO".
func texto_efeito_melhoria(melhoria: Dictionary) -> String:
	var alvo := ""
	for ap in gs.dados.todos_aparelhos():
		for m in ap.upgrades:
			if m.id == melhoria.get("id", ""):
				alvo = str(ap.focus_label[1]).to_upper()
	var modelo: String = gs.dados.ui.get("upgrade_effect", "x{mult} POR CLIQUE: {alvo}")
	return modelo.replace("{mult}", NumberFormat.fmt(float(melhoria.get("multiplier", 1.0)))).replace("{alvo}", alvo)


## "CLIQUE +123 (1 S DA EQUIPE)": o que o Grito da equipe soma agora em cada clique.
func texto_efeito_crew_click() -> String:
	return gs.preencher(texto_ui("shop_crew_click_effect", "CLIQUE +{n} (1 S DA EQUIPE)"),
		{"n": NumberFormat.fmt(gs.crew_share_efetivo() * gs.producao_total())})


## Textos prontos de um aparelho não montado (vazio se montado). Chaves: price (n TREINO), after (DEPOIS DA X),
## floor_mark (plaquinha), focus_locked (botão de foco), attr_locked (painel de atributos).
func textos_trancado(aparelho_id: String) -> Dictionary:
	var u = gs.desbloqueio(aparelho_id)
	if u.is_empty() or gs.aparelho_montado(aparelho_id) or not gs.aparelho_existe(aparelho_id):
		return {}
	var nome = gs.nome_curto_aparelho(aparelho_id).to_upper()
	var req := str(u.requires)
	var anterior = gs.nome_curto_aparelho(req).to_upper() if req != "" else ""
	var n := NumberFormat.fmt(float(u.cost))
	var trancado = req != "" and not gs.aparelho_montado(req)
	return {
		"price": gs.preencher(texto_ui("unlock_price", "{n} TREINO"), {"n": n}),
		"after": gs.preencher(texto_ui("unlock_after", "DEPOIS DA {nome}"), {"nome": anterior}) if trancado else "",
		"floor_mark": gs.preencher(texto_ui("floor_mark_after", "{nome} — DEPOIS DA {anterior}"), {"nome": nome, "anterior": anterior}) \
			if trancado else gs.preencher(texto_ui("floor_mark_price", "{nome} — {n} TREINO"), {"nome": nome, "n": n}),
		"focus_locked": gs.preencher(texto_ui("focus_locked_after", "DEPOIS DA {nome}"), {"nome": anterior}) \
			if trancado else gs.preencher(texto_ui("focus_locked_price", "{n}"), {"n": n}),
		"attr_locked": gs.preencher(texto_ui("attr_locked", "COMPRE A {nome} PARA TREINAR"), {"nome": nome}),
	}


## Texto do efeito de uma luva ("x2 POR CLIQUE") ou de um gerador pago ("+25/S").
func texto_efeito_loja(item: Dictionary) -> String:
	if item.has("click_multiplier"):
		return gs.preencher(texto_ui("shop_glove_effect", "x{mult} POR CLIQUE"),
			{"mult": NumberFormat.fmt(float(item.click_multiplier))})
	return gs.preencher(texto_ui("shop_generator_effect", "+{n}/S"),
		{"n": NumberFormat.fmt(float(item.get("production", 0.0)) * gs._fator_equipe())})


## "1 SOCO A CADA 2.0 S" para um nível (ex.: proximo_metronomo()).
func texto_efeito_metronomo(nivel_def: Dictionary) -> String:
	return gs.preencher(texto_ui("shop_metronome_effect", "1 SOCO A CADA {s} S"),
		{"s": String.num(float(nivel_def.get("interval", 0.0)), 1)})


## Texto "SE VENCER: $75 (+50%) + 15 FAMA (+50%)" com o bônus da árvore (sem "(+0%)").
func texto_stake_win(opp: Dictionary) -> String:
	var din = NumberFormat.fmt(gs.premio_dinheiro(opp))
	var fam = NumberFormat.fmt(float(gs.premio_fama(opp)))
	var pd = int(round(100.0 * gs._arvore._b("money_bonus")))
	var pf = int(round(100.0 * gs._arvore._b("fame_bonus")))
	if pd > 0:
		din += " " + gs.preencher(texto_ui("stake_bonus", "(+{n}%)"), {"n": pd})
	var texto = gs.preencher(texto_ui("stake_win"), {"n": [din, fam]})
	if pf > 0:  # o bônus da fama vem depois da palavra FAMA
		texto += " " + gs.preencher(texto_ui("stake_bonus", "(+{n}%)"), {"n": pf})
	return texto


## Texto de "perder encerra a carreira": o padrão (50%) ou o percentual real com `career_good_loser`.
func texto_stake_lose() -> String:
	var padrao = float(gs.lutas.carreira.defeat_share)
	if absf(gs.parte_derrota() - padrao) < 1.0e-9:
		return texto_ui("stake_lose")
	return gs.preencher(texto_ui("stake_lose_pct"), {"n": int(round(100.0 * gs.parte_derrota()))})


# Porcentagem mostrada: arredonda para baixo, para nunca mostrar mais do que o rótulo promete.
func _porcentagem(chance: float) -> int:
	return int(floor(chance * 100.0 + 1.0e-9))


## Texto do efeito com {pct} = round(100 x valor) e {n} = valor.
func texto_efeito_no(n: Dictionary) -> String:
	var v := float(n.get("effect_value", 0.0))
	var vn := str(int(v)) if v == floorf(v) else String.num(v)
	return gs.preencher(str(n.get("effect_text", "")), {"pct": int(round(100.0 * v)), "n": vn})


## "ACADEMIA: TREINO x2" fora da garagem, "" na garagem.
func texto_hud_local() -> String:
	if not gs.em_academia():
		return ""
	return gs.preencher(texto_ui("hud_location_mult", "ACADEMIA: TREINO x{mult}"), {"mult": NumberFormat.fmt(gs.mult_local())})


## "GUARDE $1.00K PARA A MUDANÇA" (ou a versão curta "GUARDE $1.00K"). A UI mostra no item recusado por "reserve".
func texto_reserva(curto: bool = false) -> String:
	var chave := "move_reserve_short" if curto else "move_reserve"
	return gs.preencher(texto_ui(chave, "GUARDE ${n} PARA A MUDANÇA"), {"n": NumberFormat.fmt(gs.reserva_mudanca())})


## Subtítulo da janela: "AS DUAS ARTES FICAM LIBERADAS PARA SEMPRE" na 1ª vez, "CARREIRA n: ESCOLHA A ARTE" depois.
func subtitulo_escolha_arte() -> String:
	if gs.escolha_arte_primeira():
		return texto_ui("art_sub_first")
	return gs.preencher(texto_ui("art_sub_career_named", "{nome}: ESCOLHA A ARTE"), {"nome": gs.nome_lutador().to_upper()})


## Texto do HUD da arte: "BOXE: +50% NO SEU CLIQUE", "JIU-JITSU: EQUIPE +48%" (ou "... (MÁX.)"). "" sem arte.
## O do Jiu-jitsu muda com o tempo: a UI pode ler 1 vez por segundo.
func texto_hud_arte() -> String:
	var a = gs.academia.arte(gs.arte_id)
	if a.is_empty():
		return ""
	var pct := 0
	var chave = "hud_art_" + gs.arte_id
	if a.rule.type == "manual_click_bonus":
		pct = int(round(100.0 * gs.bonus_arte_clique()))
	elif a.rule.type == "crew_time_bonus":
		pct = int(round(100.0 * gs.bonus_arte_equipe()))
		if gs.arte_no_teto() and gs.dados.ui.has(chave + "_max"):
			chave += "_max"
	return gs.preencher(texto_ui(chave, ""), {"pct": pct})


## Texto da regra da arte para a janela de escolha: "+50% TREINO NO CLIQUE DA SUA MÃO", "EQUIPE +20% (SOBE 12% POR MINUTO ATÉ 100%)".
func texto_regra_arte(id: String) -> String:
	var a = gs.academia.arte(id)
	if a.is_empty():
		return ""
	var e = 1.0 + gs.estilo_arte(id)
	var r: Dictionary = a.rule
	var vars := {}
	if r.type == "manual_click_bonus":
		vars = {"pct": int(round(100.0 * float(r.value) * e))}
	elif r.type == "crew_time_bonus":
		vars = {"pct": int(round(100.0 * float(r.start) * e)), "rate": int(round(100.0 * float(r.per_minute) * e)),
			"cap": int(round(100.0 * float(r.cap) * e))}
	return gs.preencher(str(a.rule_text), vars)


## Texto do traço de luta da arte: "BOXE: +10% DE DANO", "JIU-JITSU: -10% DE DANO RECEBIDO". "" sem arte.
func texto_traco_luta(id: String) -> String:
	var a = gs.academia.arte(id)
	if a.is_empty():
		return ""
	var f: Dictionary = a.fight
	var extra := 0.0  # Fase 5.4: nós ativos da arte (Contragolpe / Base firme), valem também na janela de escolha
	for nid in gs.nos_ativos_ids:
		var n: Dictionary = gs.lutas.no_da_arvore(str(nid))
		if not n.is_empty() and n.effect_type == "art_fight_bonus" and n.requires_art == id:
			extra += float(n.effect_value)
	var pct := 0
	if absf(float(f.damage_mult) - 1.0) > 1.0e-9:
		pct = int(round((float(f.damage_mult) * (1.0 + extra) - 1.0) * 100.0))
	elif absf(float(f.taken_mult) - 1.0) > 1.0e-9:
		pct = int(round((1.0 - float(f.taken_mult) * maxf(0.0, 1.0 - extra)) * 100.0))
	return gs.preencher(str(a.fight_text), {"pct": pct})


## Texto "FOR 40% / AGI 45% / RES 15%" do aparelho de arte ("" para os de toda carreira).
func texto_divisao(aparelho_id: String) -> String:
	var ap = gs.dados.aparelho(aparelho_id)
	if ap.is_empty() or str(ap.art) == "":
		return ""
	var d: Dictionary = ap.split
	return gs.preencher(texto_ui("focus_split", "FOR {f}% / AGI {a}% / RES {r}%"), {
		"f": int(round(100.0 * float(d.get("strength", 0.0)))), "a": int(round(100.0 * float(d.get("agility", 0.0)))),
		"r": int(round(100.0 * float(d.get("endurance", 0.0))))})


## Bloco PRÓXIMA LUTA: {show, text, legacy, seconds}. `show` = o adversário da academia está PERIGOSO (na melhor das 3 táticas)
## há >= `gym_retire_hint_seconds` (career.json) seguidos. `legacy` = o Legado que aposentar agora leva (mesmo cálculo da confirmação).
## Os segundos não vão para o save (reabrir o jogo zera a contagem).
func dica_aposentar() -> Dictionary:
	var legado = int(gs.previa_aposentar().total)
	var dias = gs.dias_para_luta()
	var limite = int(gs.lutas.calendario.get("retire_hint_days", 3))
	var vermelho = str(gs._risco_hud.rotulo) == "hard" and str(gs._risco_hud.adversario) == str(gs.proximo_adversario().get("id", "x"))
	var mostrar = gs.fim.is_empty() and gs.luta.is_empty() and limite > 0 and dias >= 0 and dias <= limite \
		and vermelho and legado > 0
	return {"show": mostrar, "legacy": legado, "days": dias,
		"text": gs.preencher(texto_ui("retire_hint", "PASSAR O POSTO AGORA LEVA {n} DE LEGADO"), {"n": legado})}


## Lista de textos de uma chave de ui_texts.json (ex.: variações das dicas). [] se não for lista.
func lista_ui(chave: String) -> Array:
	var v = gs.dados.ui.get(chave, [])
	return v if v is Array else []


## Textos prontos (sentence case, a UI aplica to_upper) da tela de fim. Chaves:
## title, who, reason, stat, tip, tip_tactic, support, tactic_name. Vazios quando não se aplicam.
func textos_fim(f: Dictionary = {}) -> Dictionary:
	if f.is_empty():
		f = gs.fim
	if f.is_empty():
		return {}
	if f.kind == "retire":
		var belt: bool = int(f.summary.get("belts", 0)) > 0
		return {"title": texto_ui("retire_title"), "who": "", "reason": "", "stat": "", "tip": "", "tip_tactic": "",
			"support": texto_ui("retire_line_belt" if belt else "retire_line"), "tactic_name": "", "wait_green": "",
			"tip_extra": _dica_extra(f)}
	var r: Dictionary = f.reason
	var opp = gs.lutas.adversario(str(f.opponent))
	var nome: String = opp.get("name", str(f.opponent))
	var atributo := str(r.get("attribute", "strength"))
	var res: Dictionary = f.result
	var quem := ""
	if bool(res.get("ko", false)):
		quem = gs.preencher(texto_ui("end_who_ko"), {"nome": nome, "n": int(r.get("round", 1))})
	else:
		quem = gs.preencher(texto_ui("end_who_points"), {"nome": nome})
	var modelos := lista_ui("reason_" + atributo)
	var st: Dictionary = r.get("stat", {})
	var texto_stat := _texto_estatistica(st)
	var principal := ""
	var faltaram := float(r.get("faltaram", -1.0))
	var semente := int(r.get("seed", 0))
	# Fim salvo antes da correção não tem `kind`: "faltaram" existe = missing; senão a estatística vira o motivo.
	var kind := str(r.get("kind", "missing" if faltaram >= 0.0 else "legacy"))
	match kind:
		"luck":
			atributo = "luck"
			var l := lista_ui("reason_luck")
			principal = str(l[semente % l.size()]) if not l.is_empty() else ""
		"far":
			principal = gs.preencher(texto_ui("reason_far"), {"n": int(r.get("far_n", 2))})
		"far_plain":
			principal = texto_ui("reason_far_plain")
		"missing":
			if modelos.size() >= 2:
				principal = gs.preencher(str(modelos[int(r.get("model", 0)) % 2]), {"n": NumberFormat.fmt(faltaram)})
		_:
			principal = texto_stat  # sem "faltaram": a estatística da luta vira o motivo
			texto_stat = ""
	var tip_ap := str(r.get("unlock_tip", ""))
	var dicas := lista_ui(("tip_unlock_" + tip_ap) if tip_ap != "" and kind != "luck" else ("tip_" + atributo))
	if dicas.is_empty() and tip_ap != "" and kind != "luck":
		dicas = [gs.preencher(texto_ui("tip_unlock", "COMPRE A {nome} CEDO NA PRÓXIMA CARREIRA"), {"nome": gs.nome_curto_aparelho(tip_ap).to_upper()})]
	var dica := str(dicas[int(r.get("tip", 0)) % dicas.size()]) if not dicas.is_empty() else ""
	var dica_t := ""
	var tt := str(r.get("better_tactic", ""))
	var pool := lista_ui("tip_tactic")
	if kind == "luck":
		tt = ""
	if tt != "" and not pool.is_empty():
		dica_t = str(pool[int(r.get("tip", 0)) % pool.size()])
	return {"title": texto_ui("end_defeat_title"), "who": quem, "reason": principal, "stat": texto_stat,
		"tip": dica, "tip_tactic": dica_t, "support": texto_ui("end_support_line_disc", texto_ui("end_support_line")),
		"tactic_name": str(gs.lutas.tatica(tt).get("name", "")),
		"wait_green": "" if kind == "luck" else texto_ui("tip_wait_green"),
		"tip_extra": _dica_extra(f)}


# Fase 5 (opcional para a UI): dica extra do fim de carreira. Derrota na academia -> `tip_gym_loss`; derrota jogando de
# uma arte -> `tip_art_<arte>`; aposentou com o cinturão sem lutar na academia -> `tip_move_belt`. "" nos outros casos.
func _dica_extra(f: Dictionary) -> String:
	var s: Dictionary = f.get("summary", {})
	var lista: Array = []
	var indice := int(f.get("career_number", 1))
	if f.kind == "retire":
		# Só se encerrou com o cinturão ainda na garagem (a mudança é automática depois do cinturão).
		if int(s.get("belts", 0)) > 0 and str(s.get("location", "")) == gs.academia.local_padrao:
			lista = lista_ui("tip_move_belt")
	else:
		var opp = gs.lutas.adversario(str(f.get("opponent", "")))
		indice = int(f.get("reason", {}).get("tip", 0))
		if not opp.is_empty() and str(opp.location) != gs.academia.local_padrao:
			lista = lista_ui("tip_gym_loss")
		elif str(s.get("art", "")) != "":
			lista = lista_ui("tip_art_" + str(s.art))
	return str(lista[indice % lista.size()]) if not lista.is_empty() else ""


func _texto_estatistica(st: Dictionary) -> String:
	var kind := str(st.get("kind", ""))
	var n := int(st.get("n", 0))
	var k := int(st.get("k", 0))
	match kind:
		"life_taken":
			var t := _modelo_reason("reason_endurance", 2, {"n": n, "k": k})
			if k == 1:  # singular: "1 GOLPE"
				t = t.replace(" 1 GOLPES", " 1 GOLPE").replace(" 1 golpes", " 1 golpe")
			return t
		"stronger":
			# Fim salvo antes da correção podia ter n fora de 20-99: sem texto.
			return _modelo_reason("reason_strength", 2, {"n": n}) if n >= 20 and n < 100 else ""
		"stronger_x":
			return gs.preencher(texto_ui("stat_stronger_x"), {"n": n})
		"stronger_cap":
			return gs.preencher(texto_ui("stat_stronger_cap"), {"n": n})
		"dodged":
			return _modelo_reason("reason_agility", 2, {"n": n})
		"crits":
			return _modelo_reason("reason_agility", 3, {"n": n, "k": k})
		"points":
			return gs.preencher(texto_ui("stat_points"), {"n": n, "k": k})
		"luck_odds":
			return gs.preencher(texto_ui("stat_luck_odds"), {"n": n})
		"luck_rare":
			return texto_ui("stat_luck_rare")
	return ""


func _modelo_reason(chave: String, i: int, vars: Dictionary) -> String:
	var l := lista_ui(chave)
	return gs.preencher(str(l[i]), vars) if l.size() > i else ""


## Texto do diálogo de confirmação de "Apagar save" (avisa se o save é de versão mais nova).
func texto_confirmar_apagar() -> String:
	if gs.store != null and gs.store.bloqueado:
		return "Este save é de uma versão mais nova do jogo. Apagar mesmo assim?"
	return "Apagar o save e o backup e começar do zero?"


## Texto do HUD no lugar de "Carreira N": só o nome, em maiúsculas.
func texto_hud_lutador() -> String:
	return gs.preencher(texto_ui("hud_disciple", "{nome}"), {"nome": gs.nome_lutador().to_upper()})
