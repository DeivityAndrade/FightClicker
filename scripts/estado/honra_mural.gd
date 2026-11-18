extends RefCounted
## Fase 6c2: Honra, hall, bônus do retrato, mural da escola, vozes dos mentores.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs  # o GameState (autoload)


func _init(g) -> void:
	gs = g


# Campos novos da escola (v13): saldo, total e nós do hall. Inválido vira 0/vazio; saldo nunca passa do total.
func _validar_escola_6c2(s: Dictionary, r: Dictionary) -> void:
	r["honor"] = gs._inteiro_valido(s.get("honor", 0), 1.0e15)
	r["honor_total"] = maxi(gs._inteiro_valido(s.get("honor_total", 0), 1.0e15), int(r.honor))
	var lista = s.get("hall_nodes", [])
	if lista is Array:
		for x in lista:
			var id := str(x)
			if _no_do_hall(id).is_empty() or id in r.hall_nodes:
				gs._avisar("Nó do hall salvo inválido ou repetido (%s): ignorado." % id)
				continue
			r.hall_nodes.append(id)
	elif s.has("hall_nodes"):
		gs._avisar("Nós do hall inválidos: zerados.")


## Saldo de Honra (a moeda do hall; nunca compra Legado).
func honra() -> int:
	return int(gs.escola.get("honor", 0))


## Honra ganha na vida inteira (nunca desce).
func honra_total() -> int:
	return int(gs.escola.get("honor_total", 0))


## A fórmula (só dados): honra de uma saída voluntária com `wins` vitórias. Derrota nunca passa por aqui.
func honra_da_saida(wins: int, belt: bool) -> int:
	var h: Dictionary = gs.hall_cfg.get("honor", {})
	if wins < int(h.get("min_wins", 1)):
		return 0
	var por: Array = h.get("per_win", [])
	var total := 0
	for i in wins:
		if por.is_empty():
			break
		total += int(por[mini(i, por.size() - 1)])
	if belt:
		total += int(h.get("belt_bonus", 0))
	return total


## Entradas do roster com selo (saíram por cima: honor > 0).
func retratos_com_selo() -> int:
	var n := 0
	for e in gs.escola.get("roster", []):
		if int(e.get("honor", 0)) > 0:
			n += 1
	return n


## Quantos retratos contam: 5, ou 8 com o nó hall_wall.
func teto_retratos() -> int:
	return int(gs.hall_cfg.get("portrait", {}).get("max_portraits", 5)) + int(_hall_valor("portrait_cap_plus"))


## Fator de TODO o treino (clique, Metrônomo, assistido e equipe): 1 + 2% por retrato com selo, até o teto.
func mult_escola() -> float:
	var por = float(gs.hall_cfg.get("portrait", {}).get("per_portrait", 0.0))
	return 1.0 + por * float(mini(retratos_com_selo(), teto_retratos()))


func _no_do_hall(id: String) -> Dictionary:
	for n in gs.hall_cfg.get("hall", {}).get("nodes", []):
		if str(n.get("id", "")) == id:
			return n
	return {}


## Soma dos valores dos nós do hall comprados com esse tipo de efeito.
func _hall_valor(tipo: String) -> float:
	var v := 0.0
	for id in gs.escola.get("hall_nodes", []):
		var n := _no_do_hall(str(id))
		if not n.is_empty() and str(n.effect.type) == tipo:
			v += float(n.effect.value)
	return v


func tem_no_hall(id: String) -> bool:
	return id in gs.escola.get("hall_nodes", [])


## Cliques para abrir uma caixa: o dado menos o nó hall_box (mínimo 1).
func cliques_para_abrir() -> int:
	return maxi(1, gs.dados.box_clicks_to_open - int(_hall_valor("box_clicks_minus")))


## Lista fixa do hall: [{id, name, cost, effect_text, state "owned"|"buyable"|"missing"|"closed", missing}].
## "closed" = fora da tela de fim (só consulta); "missing" = faltam `missing` de Honra.
func hall_lista() -> Array:
	var r: Array = []
	for n in gs.hall_cfg.get("hall", {}).get("nodes", []):
		var id := str(n.id)
		var custo := int(n.cost)
		var falta := maxi(0, custo - honra())
		var estado := "owned"
		if not tem_no_hall(id):
			estado = "closed" if gs.fim.is_empty() else ("buyable" if falta == 0 else "missing")
		r.append({"id": id, "name": gs.texto_ui("%s_name" % id, str(n.get("name", id))),
			"cost": custo, "effect_text": gs.texto_ui("%s_desc" % id, str(n.get("effect_text", ""))),
			"state": estado, "missing": 0 if estado == "owned" else falta})
	return r


func pode_comprar_hall(id: String) -> bool:
	var n := _no_do_hall(id)
	return not n.is_empty() and not gs.fim.is_empty() and not tem_no_hall(id) and honra() >= int(n.cost)


## Compra um nó: só com a tela de fim pendente, sem reembolso, desconta a Honra exata, um salvar() só.
func comprar_hall(id: String) -> bool:
	if not pode_comprar_hall(id):
		return false
	gs.escola["honor"] = honra() - int(_no_do_hall(id).cost)
	gs.escola["hall_nodes"].append(id)
	gs.salvar()
	gs.honra_mudou.emit(honra())
	gs.hall_mudou.emit()
	return true


# Efeitos de começo de campanha (depois de zerar): Treino inicial e Luva de lona já aberta (sem caixa, sem gesto).
func _aplicar_inicio_do_hall() -> void:
	var t := _hall_valor("start_training")
	if t > 0.0:
		gs.treino += t
	var g := int(_hall_valor("start_glove"))
	if g > 0:
		gs.nivel_luva = clampi(maxi(gs.nivel_luva, g), 0, gs.lutas.luvas.size())
		for n in range(1, gs.nivel_luva + 1):
			if not (n in gs.gestos_calcados):
				gs.gestos_calcados.append(n)


# Linha "FALTA ~N DE ATRIBUTO" da prévia (nó hall_notes). Calcula em segundo plano; "" até ficar pronta.
func _linha_o_que_falta(opp: Dictionary, jog: Array, adv: Array, rotulo: String) -> String:
	if not tem_no_hall("hall_notes") or rotulo == "easy" or rotulo == "":
		return ""
	var chave = "%s|%s|%s" % [str(opp.id), gs.tatica, str(jog)]
	if str(gs._falta_cache.get("chave", "")) == chave:
		return str(gs._falta_cache.texto)
	gs._falta_chave_atual = chave
	if gs._falta_tarefa < 0:
		var tat = gs.tatica
		var j := jog.duplicate()
		var a := adv.duplicate()
		gs._falta_fundo = {}
		gs._falta_tarefa = WorkerThreadPool.add_task(func() -> void: gs._falta_fundo = _calcular_falta(j, a, tat, chave))
	return ""


func _calcular_falta(jog: Array, adv: Array, tat: String, chave: String) -> Dictionary:
	# Mesmo atributo que a prévia realça em vermelho (`destaque`); sem realce, o do motivo da derrota.
	var atr = gs.motor.destaque(jog, adv)
	var falta := -1.0
	if atr != "":
		falta = gs.motor.falta_para(jog, adv, tat, Luta.ATRIBUTOS.find(atr))
	else:
		var m = gs.motor.motivo(jog, adv, tat)
		atr = str(m.attribute)
		falta = float(m.faltaram)
	var texto := ""
	if falta >= 0.0:  # -1 = nem 16x o total basta: sem número, sem linha
		texto = gs.preencher(gs.texto_ui("preview_missing_line", "FALTA ~{n} DE {atributo}"),
			{"n": NumberFormat.fmt(Economia.teto3(falta)), "atributo": str(gs.dados.atributo_info(atr).name).to_upper()})
	return {"chave": chave, "texto": texto}


## Recolhe a linha calculada em segundo plano. Com `esperar`, bloqueia até terminar.
func _finalizar_falta(esperar: bool) -> void:
	if gs._falta_tarefa < 0:
		return
	if not esperar and not WorkerThreadPool.is_task_completed(gs._falta_tarefa):
		return
	WorkerThreadPool.wait_for_task_completion(gs._falta_tarefa)
	gs._falta_tarefa = -1
	var pronto = gs._falta_fundo
	gs._falta_fundo = {}
	if pronto.is_empty():
		return
	gs._falta_cache = pronto
	if str(pronto.chave) == gs._falta_chave_atual:
		gs.previa_falta_pronta.emit(str(pronto.texto))


## Espera a linha "o que mais falta" ficar pronta (testes e fechamento).
func aguardar_falta() -> void:
	_finalizar_falta(true)


## Dados da janela do mural. `entries` na ordem do roster (o John é a 1ª): {campaign, kind, name, look, art, wins, belt,
## end, end_key, end_text, opponent, opponent_name, sealed, honor, symbol, extra_key, career_text, wins_text, art_text}.
func mural() -> Dictionary:
	var cfg: Dictionary = gs.escola_cfg.get("mural", {})
	var fins: Dictionary = cfg.get("end_texts", {})
	var itens: Array = []
	for e in gs.escola.get("roster", []):
		var fim_tipo := str(e.get("end", "unknown"))
		var honra_e := int(e.get("honor", 0))
		var chave := str(fins.get("unknown", ""))
		if fim_tipo == "retire":
			chave = str(fins.get("retire_sealed", "")) if honra_e > 0 else str(fins.get("retire_plain", ""))
		elif fim_tipo == "defeat":
			chave = str(fins.get("defeat", ""))
		var oponente := str(e.get("opponent", ""))
		var nome_op = str(gs.lutas.adversario(oponente).get("name", "")) if oponente != "" else ""
		var wins := int(e.get("wins", -1))
		var extra := ""
		if str(e.get("kind", "")) == "first" and gs.marco(str(cfg.get("first_left_milestone", ""))):
			extra = str(cfg.get("first_left_text", ""))
		var arte := str(e.get("art", ""))
		var wins_texto := ""
		if wins < 0:
			wins_texto = gs.texto_ui(str(cfg.get("wins_unknown_text", "mural_wins_unknown")), "?")
		elif wins == 1:
			wins_texto = gs.texto_ui("mural_wins_one", "1 VITÓRIA")
		else:
			wins_texto = gs.preencher(gs.texto_ui("mural_wins", "{n} VITÓRIAS"), {"n": wins})
		itens.append({"campaign": int(e.campaign), "kind": str(e.kind), "name": str(e.name), "look": e.get("look", null),
			"art": arte, "wins": wins, "belt": bool(e.get("belt", false)), "end": fim_tipo, "end_key": chave,
			"end_text": gs.preencher(gs.texto_ui(chave), {"adversario": nome_op.to_upper()}) if (chave != str(fins.get("defeat", "")) or nome_op != "")
				else gs.texto_ui("mural_end_defeat_unknown", "PAROU NUMA LUTA"),
			"opponent": oponente, "opponent_name": nome_op, "sealed": honra_e > 0, "honor": honra_e,
			"symbol": simbolo_na_entrada(e), "extra_key": extra,
			"career_text": gs.preencher(gs.texto_ui("mural_career", "CARREIRA {n}"), {"n": int(e.campaign)}),
			"wins_text": wins_texto,
			"art_text": gs.nome_arte(arte).to_upper() if arte != "" else gs.texto_ui("mural_art_none", "—")})
	var contam := mini(retratos_com_selo(), teto_retratos())
	var por = float(gs.hall_cfg.get("portrait", {}).get("per_portrait", 0.0))
	var pct := int(round(100.0 * por * contam))
	return {"entries": itens, "honor": honra(), "sealed": retratos_com_selo(), "counted": contam, "cap": teto_retratos(),
		"bonus_pct": pct, "columns": int(cfg.get("columns", 5)), "rows_per_page": int(cfg.get("rows_per_page", 2)),
		"bonus_line": gs.preencher(gs.texto_ui("mural_bonus_line"), {"n": retratos_com_selo(), "c": contam, "cap": teto_retratos(), "pct": pct})}


## O mural na sala atual: {spot [x, y] ou [] (ponto ainda sem arte), spot_name, object_text (chave de objects)}; {} onde não aparece.
## Abre a qualquer hora em que a sala está ativa (a UI decide); nada vai para o save.
func mural_na_sala() -> Dictionary:
	var cfg: Dictionary = gs.escola_cfg.get("mural", {})
	if cfg.is_empty() or not cfg.get("spot_by_location", {}).has(gs.local_id):
		return {}
	var req = str(cfg.get("requires_milestone_by_location", {}).get(gs.local_id, ""))
	if req != "" and not gs.marco(req):
		return {}
	var nome = str(cfg.spot_by_location[gs.local_id])
	return {"spot": gs._casa._cena_dados_pontos().ponto_caminho(nome), "spot_name": nome, "object_text": str(cfg.get("object_text", "mural"))}


## Campanha do 1º cinturão amador da escola (o menor entre o marco da garagem salva, o roster e a campanha atual); 0 = nenhuma.
func campanha_do_simbolo() -> int:
	var cfg: Dictionary = gs.escola_cfg.get("school_symbol", {})
	var melhor := 0
	var marco_id := str(cfg.get("from_milestone", "garage_saved"))
	if gs.marco(marco_id):
		melhor = int(gs.dados_marco(marco_id).get("campaign", 0))
	if bool(cfg.get("also_roster_belt", true)):
		for e in gs.escola.get("roster", []):
			if bool(e.get("belt", false)) and (melhor <= 0 or int(e.campaign) < melhor):
				melhor = int(e.campaign)
	if gs.cinturao and (melhor <= 0 or gs.numero_carreira() < melhor):
		melhor = gs.numero_carreira()
	return melhor


## O lutador atual usa o símbolo no peito? Discípulo (nunca o John) de campanha >= `campanha_do_simbolo()`.
func simbolo_no_lutador() -> bool:
	var c := campanha_do_simbolo()
	return gs.lutador_atual() == "disciple" and c > 0 and gs.numero_carreira() >= c


## Uma entrada do roster usa o símbolo? Vale para o mural e para o mentor sentado/em pé (use `campaign` do mentor).
func simbolo_na_entrada(e: Dictionary) -> bool:
	var c := campanha_do_simbolo()
	return str(e.get("kind", "")) == "disciple" and c > 0 and int(e.get("campaign", 0)) >= c


## O mentor sentado no caixote agora: {id "first"|"last", name, campaign, kind "first"|"disciple"} ou {}.
func mentor_do_caixote() -> Dictionary:
	for m in gs.mentores_na_sala():
		if str(m.get("role", "")) == "seat":
			return {"id": str(m.id), "name": str(m.name), "campaign": int(m.campaign), "kind": "first" if str(m.id) == "first" else "disciple"}
	return {}


## Timbre do mentor para a voz: {base_hz, cps, vowel_order, vowel_steps}. O John usa a voz `first`; discípulo: escola.json.
func voz_do_mentor(kind: String, campanha: int) -> Dictionary:
	if kind == "first":
		return gs.dialogos.voices.get("first", {}).duplicate()
	var v: Dictionary = gs.escola_cfg.get("mentor_voice", {})
	var passos: Array = v.get("steps", [0])
	var hz := float(v.get("base_hz", 200)) + float(v.get("step_hz", 14)) * float(passos[campanha % maxi(1, passos.size())])
	return {"base_hz": hz, "cps": float(v.get("cps", 26)), "vowel_order": str(v.get("vowel_order", "uoaei")),
		"vowel_steps": v.get("vowel_steps", [0, 2, 4, 5, 7])}


## Maior número de vitórias de uma entrada do roster (wins -1 = desconhecido não conta).
func recorde_da_escola() -> int:
	var m := 0
	for e in gs.escola.get("roster", []):
		m = maxi(m, int(e.get("wins", -1)))
	return m


func _entrada_da_campanha(campanha: int) -> Dictionary:
	for e in gs.escola.get("roster", []):
		if int(e.campaign) == campanha:
			return e
	return {}


# O teto por grupo: já tocou alguma fala do grupo nesta campanha (lines_seen == campanha atual)?
func _grupo_de_fala_usado(grupo: String) -> bool:
	var caps: Dictionary = gs.escola_cfg.get("mentor_lines", {}).get("caps", {})
	for l in gs.dialogos.linhas:
		if str(l.trigger) != "mentor_won":
			continue
		var k := str(l.conditions.get("mentor_line", ""))
		if str(caps.get(k, k)) == grupo and int(gs.escola.lines_seen.get(str(l.id), -1)) == gs.numero_carreira():
			return true
	return false


# Vitória sobre `opp` (indice_escada já somado): qual fala o mentor do caixote pede? {} = nenhuma.
# Ordem revanche > recorde > mais longe que eu; no máximo uma. Devolve os params de mentor_won.
func _fala_do_mentor(opp: Dictionary) -> Dictionary:
	var cfg: Dictionary = gs.escola_cfg.get("mentor_lines", {})
	var mentor := mentor_do_caixote()
	if cfg.is_empty() or mentor.is_empty() or gs.dialogos.gatilho(str(cfg.get("trigger", "mentor_won"))).is_empty():
		return {}
	var minha := _entrada_da_campanha(int(mentor.campaign))
	var caps: Dictionary = cfg.get("caps", {})
	for k in cfg.get("order", []):
		var params := {"line": k, "mentor_line": k, "adversario": str(opp.name), "mentor": "", "own": false, "mentor_kind": mentor.kind}
		match str(k):
			"revanche":
				var achou := {}
				for e in gs.escola.get("roster", []):
					if str(e.get("end", "")) == "defeat" and str(e.get("opponent", "")) == str(opp.id):
						if achou.is_empty() or (int(e.campaign) == int(mentor.campaign) and str(e.kind) == str(minha.get("kind", ""))):
							achou = e
				if achou.is_empty():
					continue
				params["mentor"] = str(achou.name)
				params["own"] = not minha.is_empty() and int(achou.campaign) == int(minha.campaign)
			"recorde":
				var rec := recorde_da_escola()
				if rec < int(cfg.get("record_min_wins", 1)) or gs.indice_escada <= rec:
					continue
			"mais_longe":
				if minha.is_empty() or int(minha.get("wins", -1)) < 0 or gs.indice_escada <= int(minha.wins):
					continue
			_:
				continue
		if _grupo_de_fala_usado(str(caps.get(k, k))):
			continue
		if gs.dialogos.candidatas("mentor_won", gs._ctx_falas(params)).is_empty():
			continue  # sem fala escrita para este caso: não gasta a vitória nem cala o Osmar
		return params
	return {}
