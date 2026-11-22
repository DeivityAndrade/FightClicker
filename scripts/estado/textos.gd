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
		{"n": NumberFormat.fmt(float(item.get("production", 0.0)) * gs._loja._fator_equipe())})


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
	var modelo := str(n.get("effect_text", ""))
	if gs.passiva_carreira == 2 and gs.arte_id != "" and str(n.get("effect_text_2", "")) != "":
		modelo = str(n.effect_text_2)  # 7b2: os nós da raiz da arte descrevem a 2ª passiva quando ela está escolhida
	return gs.preencher(modelo, {"pct": int(round(100.0 * v)), "n": vn})


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
	elif a.rule.type == "click_crit_bonus":  # 7b1: sem chave em ui_texts, cai no texto padrão (o Roteirista pode trocar)
		var cc: Dictionary = gs.bonus_arte_critico()
		return gs.preencher(texto_ui(chave, "MUAY THAI: CRÍTICO {chance}%"), {"chance": int(round(100.0 * float(cc.chance))),
			"mult": _dec(float(cc.mult), 2).rstrip("0").rstrip(",")})
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
	elif r.type == "click_crit_bonus":  # 7b1: "20% DE CHANCE, x4,1" (com o nó ESTILO: x4,65)
		var chance: float = minf(1.0, float(gs.dados.crit_chance) + float(r.chance_add))
		var mult: float = float(gs.dados.crit_multiplier) + float(r.mult_add) * e
		vars = {"chance": int(round(100.0 * chance)), "mult": _dec(mult, 2).rstrip("0").rstrip(",")}
	return gs.preencher(str(a.rule_text), vars)


## Texto da passiva de luta da arte para o cartão da janela de escolha ("MÃO RÁPIDA: ..."). "" sem arte.
## Vem da chave art_card_<arte>_fight (ui_texts.json, do Roteirista); sem ela, `fight_text` do arts.json.
func texto_passiva(id: String, passiva: int = 1) -> String:
	var a = gs.academia.arte(id)
	if a.is_empty():
		return ""
	if passiva == 2 and not a.passive_2.is_empty():  # 7b2: a 2ª passiva tem o texto no próprio arts.json
		return gs.preencher(str(a.passive_2.fight_text), {})
	var t := texto_ui("art_card_%s_fight" % id, str(a.fight_text))
	return gs.preencher(t, {})


## Nome antigo (o traço +10%/-10% saiu na 7a1): devolve o texto da passiva.
func texto_traco_luta(id: String) -> String:
	return texto_passiva(id)


func _dec(x: float, casas: int) -> String:
	return (("%." + str(casas) + "f") % x).replace(".", ",")  # o jogo usa vírgula decimal


## Linha da passiva na prévia, para uma tática: {name, kind, line, share, share_n, state}. {} sem passiva.
## `est` = Luta.estado_passiva da tática; `det` = Luta.chance_detalhada da mesma tática.
## Textos de data/ui_texts.json (passive_*); a UI só mostra. Nada aqui muda a luta.
func passiva_da_previa(est: Dictionary, det: Dictionary, tatica_id: String) -> Dictionary:
	var P: Dictionary = gs.motor.passiva
	if P.is_empty() or est.is_empty():
		return {}
	var vit := int(det.get("wins", 0))
	var n10 := int(round(10.0 * float(det.get("wins_passive", 0)) / float(vit))) if vit > 0 else 0
	if P.type == "fast_hands":
		var tp: Dictionary = P.tactics.get(tatica_id, {})
		var descansa := float(tp.get("tired_interval_mult", P.tired_interval_mult)) <= 1.0 + 1.0e-9
		var chave := "passive_boxing_line_defensive" if descansa else "passive_boxing_line"
		var linha := gs.preencher(texto_ui(chave, "SOCO A CADA {s} S. K.O. ATÉ {ko}% POR GOLPE. " + ("NÃO CANSA" if descansa else "CANSA NO 3º ROUND")),
			{"s": _dec(est.interval, 2), "ko": int(round(100.0 * float(est.ko_max)))})
		if float(est.opp_counter) > 0.0:
			linha += ". " + texto_ui("passive_boxing_counter_warn", "ELE CONTRAGOLPEIA")
		return {"name": texto_ui("passive_boxing_name", "MÃO RÁPIDA"), "kind": "fast_hands", "line": linha,
			"share": gs.preencher(texto_ui("passive_share_boxing", "{n} EM 10 VITÓRIAS POR K.O."), {"n": n10}), "share_n": n10,
			"state": {"streak_max": est.streak_max, "ko_max": est.ko_max, "interval": est.interval, "tired_at": est.tired_at,
				"tired_round": est.tired_round, "tired": not descansa, "tires": not descansa, "opp_counter": est.opp_counter}}
	if P.type == "shin":
		return _passiva_shin(est, det, n10)
	if P.type in ["counter_punch", "top_control", "thai_clinch"]:
		return _passiva2_da_previa(est, det, n10, P, tatica_id)
	var linha_j := ""
	if est.grip_in_time:
		linha_j = gs.preencher(texto_ui("passive_bjj_line", "PEGADA CHEIA NO {r}º ROUND ({t} S). {p}% POR GOLPE PARA FINALIZAR"),
			{"r": est.grip_round, "t": _dec(est.grip_full_at, 1), "p": int(round(100.0 * float(est.sub_chance)))})
	else:
		linha_j = texto_ui("passive_bjj_line_late", "A PEGADA NÃO ENCHE ANTES DO GONGO")
	return {"name": texto_ui("passive_bjj_name", "FINALIZAÇÃO"), "kind": "submission", "line": linha_j,
		"share": gs.preencher(texto_ui("passive_share_bjj", "{n} EM 10 VITÓRIAS POR FINALIZAÇÃO"), {"n": n10}), "share_n": n10,
		"state": {"grip_full_at": est.grip_full_at, "grip_round": est.grip_round, "grip_in_time": est.grip_in_time,
			"sub_chance": est.sub_chance}}


## Muay Thai (7b1): linha da Canela. `det` traz full_share e full_at (Luta.chance_detalhada). Perna que só enche em menos de
## metade das lutas troca a linha por `passive_muay_thai_line_late`. Agressivo e Contra-ataque acrescentam o aviso deles.
func _passiva_shin(est: Dictionary, det: Dictionary, n10: int) -> Dictionary:
	var compasso := float(gs.lutas.combate.round_length)
	var share := float(det.get("full_share", 0.0))
	var full_at := float(det.get("full_at", -1.0))
	var rodada := (int(floor(full_at / compasso + 1.0e-9)) + 1) if full_at >= 0.0 else 0
	var tarde := share < 0.5
	var linha := ""
	if tarde:
		linha = gs.preencher(texto_ui("passive_muay_thai_line_late", "A PERNA SÓ ENCHE EM {x} DE 10 LUTAS"), {"x": int(round(10.0 * share))})
	else:
		linha = gs.preencher(texto_ui("passive_muay_thai_line", "PERNA CHEIA NO {r}º ROUND ({k} CHUTES). RODADO {p}% POR GOLPE. ELE {s}% MAIS LENTO"),
			{"r": rodada, "k": est.kicks_to_full, "p": int(round(100.0 * float(est.spin_chance))), "s": int(round(100.0 * float(est.slow_full)))})
	if float(est.opp_counter) > 0.0:
		linha += ". " + texto_ui("passive_muay_thai_counter_warn", "ELE CONTRAGOLPEIA")
	if float(est.marks_per_counter) > 0.0:
		linha += ". " + texto_ui("passive_muay_thai_counter_marks", "SEU CONTRAGOLPE MARCA A PERNA")
	return {"name": texto_ui("passive_muay_thai_name", "CANELA"), "kind": "shin", "line": linha,
		"share": gs.preencher(texto_ui("passive_share_muay_thai", "{n} EM 10 VITÓRIAS POR CHUTE RODADO"), {"n": n10}), "share_n": n10,
		"state": {"marks_max": est.marks_max, "kicks_to_full": est.kicks_to_full, "full_at": full_at, "full_round": rodada,
			"full_share": share, "late": tarde, "crit_now": est.crit_now, "crit_full": est.crit_full,
			"spin_chance": est.spin_chance, "slow_full": est.slow_full, "opp_counter": est.opp_counter,
			"marks_per_counter": est.marks_per_counter}}


## 7b2: linha da 2ª passiva na prévia (design 7b2 §8.2). Os números vêm do mesmo `estado_passiva` e das mesmas 200 sementes da chance;
## a linha não repete limiares fixos (50%, 80%). Top/Clinch: se derruba/prende em menos de metade das lutas, a linha vira `_line_late`.
func _passiva2_da_previa(est: Dictionary, det: Dictionary, n10: int, P: Dictionary, tatica_id: String) -> Dictionary:
	var compasso := float(gs.lutas.combate.round_length)
	var tipo := str(P.type)
	var share := float(det.get("share", 0.0))
	var at := float(det.get("at", -1.0))
	var rodada := (int(floor(at / compasso + 1.0e-9)) + 1) if at >= 0.0 else 0
	var tarde := share < 0.5
	var pct := func(x: float) -> int: return int(round(100.0 * x))
	var linha := ""
	var estado := {}
	var nome := ""
	var share_txt := ""
	if tipo == "counter_punch":
		nome = texto_ui("passive_counter_punch_name", "CONTRAGOLPISTA")
		linha = gs.preencher(texto_ui("passive_counter_punch_line", "VOCÊ ESQUIVA {d}%. CADA ESQUIVA CARREGA (+{c}). NO 3º ROUND, K.O. ATÉ {k}% POR GOLPE"),
			{"d": pct.call(est.dodge), "c": est.charge_per_dodge, "k": pct.call(est.ko_max)})
		var tp: Dictionary = P.tactics.get(tatica_id, {})
		if float(tp.get("dodge_mult", 1.0)) < 1.0:  # Agressivo: "você não espera"
			linha += ". " + texto_ui("passive_counter_punch_line_aggressive", "NO AGRESSIVO VOCÊ NÃO ESPERA")
		share_txt = gs.preencher(texto_ui("passive_share_counter_punch", "{n} EM 10 VITÓRIAS POR K.O. NO CONTRAGOLPE"), {"n": n10})
		estado = {"dodge_now": est.dodge_now, "dodge": est.dodge, "charge_max": est.charge_max, "charge_per_dodge": est.charge_per_dodge,
			"charge_med": float(det.get("charge_med", 0.0)), "ko_max": est.ko_max, "ko_round": est.ko_round, "ko_from": est.ko_from,
			"end_factor": est.end_factor, "counter_power": est.counter_power}
	elif tipo == "top_control":
		nome = texto_ui("passive_top_control_name", "POR CIMA")
		if tarde:
			linha = gs.preencher(texto_ui("passive_top_control_line_late", "SÓ DERRUBA EM {x} DE 10 LUTAS"), {"x": int(round(10.0 * share))})
		else:
			linha = gs.preencher(texto_ui("passive_top_control_line", "DERRUBA {p}% POR ACERTO (NO {r}º ROUND). ELE LEVANTA {e}%. COM ELE FRACO, O JUIZ PARA ({s}%)"),
				{"p": pct.call(est.td_chance), "r": rodada, "e": pct.call(est.escape), "s": pct.call(est.stop_chance)})
		share_txt = gs.preencher(texto_ui("passive_share_top_control", "{n} EM 10 VITÓRIAS COM O JUIZ PARANDO"), {"n": n10})
		estado = {"td_chance": est.td_chance, "td_at": at, "td_round": rodada, "td_share": share, "late": tarde, "escape": est.escape,
			"stop_life": est.stop_life, "stop_chance": est.stop_chance}
	else:
		nome = texto_ui("passive_thai_clinch_name", "CLINCH")
		if tarde:
			linha = gs.preencher(texto_ui("passive_thai_clinch_line_late", "SÓ PRENDE EM {x} DE 10 LUTAS"), {"x": int(round(10.0 * share))})
		else:
			linha = gs.preencher(texto_ui("passive_thai_clinch_line", "PRENDE {p}% POR ACERTO (NO {r}º ROUND). NO CLINCH: JOELHADA {k}% DE CRÍTICO. ELE SOLTA {e}%"),
				{"p": pct.call(est.clinch_chance), "r": rodada, "k": pct.call(est.knee_crit), "e": pct.call(est.escape)})
		share_txt = gs.preencher(texto_ui("passive_share_thai_clinch", "{n} EM 10 VITÓRIAS POR JOELHADA"), {"n": n10})
		estado = {"clinch_chance": est.clinch_chance, "clinch_at": at, "clinch_round": rodada, "clinch_share": share, "late": tarde,
			"escape": est.escape, "clinch_life": est.clinch_life, "clinch_s": est.clinch_s, "crit_now": est.crit_now,
			"knee_crit": est.knee_crit, "knee_ko": est.knee_ko, "knee_life": est.knee_life}
	return {"name": nome, "kind": tipo, "line": linha, "share": share_txt, "share_n": n10, "state": estado}


## Nota da passiva no fim da derrota: {id, n, r, text, tip} (text/tip "" se a chave faltar). {} sem nota.
## `nota` vem de Luta.nota_passiva (guardada no motivo); `semente` escolhe a dica entre as da chave tip_passive_<id>.
func passiva_nota_textos(nota: Dictionary, semente: int) -> Dictionary:
	if nota.is_empty():
		return {}
	var id := str(nota.id)
	var tips := lista_ui("tip_passive_" + id)
	var modelo := texto_ui("reason_passive_" + id, "")
	if int(nota.n) == 1:  # singular: "1 VEZ" (chave `_one` se existir; senão troca VEZES por VEZ)
		modelo = texto_ui("reason_passive_" + id + "_one", modelo.replace("VEZES", "VEZ").replace("vezes", "vez"))
	return {"id": id, "n": nota.n, "r": nota.r,
		"text": gs.preencher(modelo, {"n": nota.n, "r": nota.r}),
		"tip": str(tips[semente % tips.size()]) if not tips.is_empty() else ""}


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
	var saida := {"title": texto_ui("end_defeat_title"), "who": quem, "reason": principal, "stat": texto_stat,
		"tip": dica, "tip_tactic": dica_t, "support": texto_ui("end_support_line_disc", texto_ui("end_support_line")),
		"tactic_name": str(gs.lutas.tatica(tt).get("name", "")),
		"wait_green": "" if kind == "luck" else texto_ui("tip_wait_green"),
		"tip_extra": _dica_extra(f)}
	# 7a1: nota da passiva (só com arte e quando pesou): passive_note (texto) e passive_note_tip (dica), abaixo da estatística.
	var nota := passiva_nota_textos(r.get("passive_note", {}), semente)
	if not nota.is_empty():
		saida["passive_note"] = nota.text
		saida["passive_note_tip"] = nota.tip
		saida["passive_note_id"] = nota.id
	# 8a1: a passiva DELE pesou: ocupa a linha da passiva (a nota da sua arte nao aparece nesta derrota). opp_note* tambem vao separados.
	var nota_adv: Dictionary = gs._liga.textos_nota(r.get("opp_note", {}), semente)
	if not nota_adv.is_empty():
		saida["opp_note"] = nota_adv.text
		saida["opp_note_tip"] = nota_adv.tip
		saida["opp_note_id"] = nota_adv.id
		saida["passive_note"] = nota_adv.text
		saida["passive_note_tip"] = nota_adv.tip
		saida["passive_note_id"] = nota_adv.id
	return saida


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
