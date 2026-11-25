extends RefCounted
## Ronda Noturna do Gato Preto: capuz no prego, estado "ronda ativa" (o jogo congela), prêmio, LENDA e níveis.
## Design: docs/fases/ronda-design.md; números: data/ronda.json (lido por RondaData); lógica da noite: RondaLogica.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.
## Não usa nenhum sorteio do jogo: só o `_rng_ronda` (ciclos do ladrão); o capuz é determinístico (só relógio e regras).

const _TEMPO_MAX_PREMIO := 120.0  # trava de segurança: a tela de prêmio nunca prende a sala para sempre
const _TETO := 1000000000

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


func _cfg() -> RondaData:
	return gs.ronda_cfg


# ---------------------------------------------------------------- estado do capuz (save: career.black_cat_hood)
func _padrao() -> Dictionary:
	var primeiro := float(_cfg().capuz.first_after_s)
	return {"hood_s": 0.0, "next_at": primeiro, "open": ""}


## Nova campanha (e carga sem o campo): capuz volta ao padrão e a Ronda em andamento some. A lenda é da linhagem e fica.
func zerar() -> void:
	gs.capuz = _padrao()
	gs.ronda_ativa = ""
	gs._ronda_jogo = null
	gs._ronda_premio = {}
	gs._ronda_fim_t = 0.0
	gs._capuz_vis = ""


## career.black_cat_hood do save: ausente/ruim = padrão; `open` fora de `nights` ou com a Ronda fechada = "".
func validar(v: Variant) -> Dictionary:
	var r := _padrao()
	if not (v is Dictionary):
		return r
	r["hood_s"] = minf(gs._numero_valido(v.get("hood_s", 0.0)), 1.0e12)
	var na = v.get("next_at", null)
	if (typeof(na) == TYPE_FLOAT or typeof(na) == TYPE_INT) and is_finite(float(na)) and float(na) >= 0.0:
		r["next_at"] = minf(float(na), 1.0e12)
	var op := str(v.get("open", "")) if v.get("open", "") is String else ""
	r["open"] = op if _cfg().noites.has(op) and ronda_aberta() else ""
	return r


# ---------------------------------------------------------------- lenda (save: permanent.black_cat)
func _bc() -> Dictionary:
	var d = gs.permanente.get("black_cat", {})
	return d if d is Dictionary else {}


func _bc_num(chave: String) -> int:
	return int(_bc().get(chave, 0))


## Grava um campo; o bloco só existe depois da 1ª ronda (ou da abertura).
func _bc_gravar(campos: Dictionary) -> void:
	var d := _bc().duplicate()
	for k in campos:
		d[k] = campos[k]
	for k in ["legend", "shown_level", "scares", "rounds", "open_campaign"]:
		d[k] = int(d.get(k, 0))
	gs.permanente["black_cat"] = d


func nivel_lenda() -> int:
	if _cfg().vazio:
		return 0
	return _cfg().nivel_de(_bc_num("legend"))


## {legend, level, next_level_at (0 no máximo), max_level, scares, rounds, shown_level}.
func lenda() -> Dictionary:
	var n := nivel_lenda()
	var niveis: Array[int] = _cfg().niveis
	return {"legend": _bc_num("legend"), "level": n, "next_level_at": niveis[n] if n < niveis.size() else 0, "max_level": niveis.size(),
		"scares": _bc_num("scares"), "rounds": _bc_num("rounds"), "shown_level": _bc_num("shown_level")}


## permanent.black_cat do save: ausente = tudo 0; número ruim = 0; gigante = teto; shown_level <= nível da lenda;
## scares <= 3 x rounds. Só grava com ronda feita, lenda ou abertura registrada. Avisa nó `cat_*` com a lenda abaixo da trava.
func validar_permanente(p: Dictionary, r: Dictionary) -> void:
	var v = p.get("black_cat", null)
	if v is Dictionary:
		var lenda_v: int = gs._inteiro_valido(v.get("legend", 0), float(_TETO))
		var rodadas: int = gs._inteiro_valido(v.get("rounds", 0), float(_TETO))
		var nivel := _cfg().nivel_de(lenda_v) if not _cfg().vazio else 0
		var d := {"legend": lenda_v, "rounds": rodadas, "scares": mini(gs._inteiro_valido(v.get("scares", 0), float(_TETO)), 3 * rodadas),
			"shown_level": mini(gs._inteiro_valido(v.get("shown_level", 0), 5.0), nivel),
			"open_campaign": gs._inteiro_valido(v.get("open_campaign", 0), 999.0)}
		if rodadas > 0 or d.open_campaign > 0 or lenda_v > 0:
			r["black_cat"] = d
	var nivel_r := _cfg().nivel_de(int(r.get("black_cat", {}).get("legend", 0))) if not _cfg().vazio else 0
	for id in r.get("skill_nodes", []):
		var trava := str(gs.lutas.no_da_arvore(str(id)).get("lock", ""))
		if trava.begins_with("black_cat:") and nivel_r < int(trava.substr(10)):
			gs._avisar("Nó %s salvo com a lenda abaixo da trava: mantido (já foi pago)." % id)


# ---------------------------------------------------------------- abertura
## Campanha em que a Ronda abre para a linhagem (0 = sem dados). Regra: campanha do boato + 1 (mínimo 3); sem boato, a rede de
## segurança (campanha 5); o que vier primeiro. Depois de aberta fica gravada em `open_campaign`.
func campanha_de_abertura() -> int:
	if _cfg().vazio:
		return 0
	var gravada := _bc_num("open_campaign")
	if gravada > 0:
		return gravada
	var ab: Dictionary = _cfg().abertura
	var rede := int(ab.no_rumor_from_campaign)
	var m := str(ab.requires_milestone)
	if m != "" and gs.marco(m):
		var c = gs._escola.dados_marco(m).get("campaign", null)
		var de := gs.numero_carreira()  # marco sem campanha (save antigo): abre já
		if (typeof(c) == TYPE_INT or typeof(c) == TYPE_FLOAT) and is_finite(float(c)) and float(c) >= 1.0:
			de = int(c) + int(ab.campaigns_after_rumor)
		return mini(maxi(de, int(ab.min_campaign)), rede)
	return rede


func ronda_aberta() -> bool:
	var c := campanha_de_abertura()
	return c > 0 and gs.numero_carreira() >= c


# ---------------------------------------------------------------- capuz
func _escolher_noite() -> String:
	for id in _cfg().ordem:
		if _cfg().noites[id].requires.is_empty():  # requires != {} ainda não tem regra: indisponível
			return id
	return ""


func _fechada_para_o_capuz() -> bool:
	return _cfg().vazio or gs.ronda_ativa != ""


## Chamado todo quadro dentro do bloco de tick da carreira. `dt` = tempo de sala deste quadro (0 com a sala parada).
func tick(dt: float) -> void:
	if _fechada_para_o_capuz() or not ronda_aberta():
		return
	if _bc_num("open_campaign") == 0:
		_bc_gravar({"open_campaign": campanha_de_abertura()})
	if dt <= 0.0:
		return
	var c: Dictionary = gs.capuz
	c["hood_s"] = float(c.hood_s) + dt
	if str(c.open) == "" and float(c.hood_s) >= float(c.next_at) - 1.0e-6 and not gs._treino._escondido() and not gs.no_dia_da_luta():
		c["open"] = _escolher_noite()


## Chamado no fim do tick: avisa a UI quando o capuz aparece ou some do prego.
func atualizar_visivel() -> void:
	var v := capuz_visivel()
	if v != gs._capuz_vis:
		gs._capuz_vis = v
		gs.capuz_mudou.emit(v)


## Id da noite que o capuz traz, enquanto ele está no prego ("" = nenhum). Continua desenhado com janela/fala/dia da luta
## (aí sem clique: ver `capuz_info().clickable`).
func capuz_visivel() -> String:
	if _fechada_para_o_capuz() or gs.treino_fora != "" or str(gs.capuz.get("open", "")) == "" or not ronda_aberta():
		return ""
	return str(gs.capuz.open)


func _clicavel() -> bool:
	return capuz_visivel() != "" and gs.sala_ativa() and not gs._treino._escondido()


## {night, spot [x, y] ou [] (ponto do local ainda sem arte), hover_text, clickable}; {} sem capuz no prego.
func capuz_info() -> Dictionary:
	var n := capuz_visivel()
	if n == "":
		return {}
	var nome := str(_cfg().capuz.spot_by_location.get(gs.local_id, ""))
	var p: Array = gs._casa._cena_dados_pontos().ponto_caminho(nome) if nome != "" else []
	return {"night": n, "spot": p, "spot_name": nome, "hover_text": gs.texto_ui(str(_cfg().capuz.hover_text), "SAIR DE NOITE?"),
		"clickable": _clicavel()}


# ---------------------------------------------------------------- IR, jogo e prêmio
func _ruas() -> Array:
	var camadas: Array = _cfg().camadas
	var n := nivel_lenda()
	return (camadas[n] as Array).duplicate() if n < camadas.size() and camadas[n] is Array else []


## Clicou no capuz. NÃO grava nada (o capuz continua no prego do save); abre a Ronda e congela o jogo.
func ronda_ir() -> Dictionary:
	if not _clicavel():
		return {}
	var id := capuz_visivel()
	var noite: Dictionary = _cfg().noites[id]
	gs.ronda_ativa = id
	gs._ronda_premio = {}
	gs._ronda_fim_t = 0.0
	gs._rng_ronda.randomize()
	gs._ronda_jogo = RondaLogica.new(noite, gs._rng_ronda)
	var nivel := nivel_lenda()
	var ids: Array = []
	var nomes: Array = []
	for o in noite.occurrences:
		ids.append(o.id)
		nomes.append(gs.texto_ui(str(o.get("name", "")), str(o.id).to_upper()) if str(o.get("name", "")) != "" else str(o.id).to_upper())
	var titulo := gs.texto_ui("night_scare_name_cat", "") if nivel >= 1 else ""
	if titulo == "":
		titulo = gs.texto_ui(str(noite.name), "RONDA NOTURNA")
	var info := {"night": id, "kind": noite.kind, "name": titulo, "tip": gs.texto_ui(str(noite.tip), ""), "countdown_s": noite.countdown_s,
		"night_s": noite.night_s, "level": nivel, "legend": _bc_num("legend"), "layers": _ruas(), "occurrences": ids, "occurrence_names": nomes}
	gs.capuz_mudou.emit("")
	gs._capuz_vis = ""
	gs.ronda_mudou.emit(id)
	return info


## A lógica da Ronda em andamento (RondaLogica) ou null. A UI lê `estado()` e manda `apertar()`/`soltar()`; o tempo anda no tick.
func ronda_jogo() -> Variant:
	return gs._ronda_jogo


## Chamado pelo tick no lugar de TUDO: a Ronda congela o jogo, só a lógica da noite anda.
func tick_jogo(delta: float) -> void:
	var j = gs._ronda_jogo
	if j == null:
		return
	j.avancar(delta)
	if j.fase == "fim":
		if gs._ronda_premio.is_empty():
			ronda_concluir()  # a lenda entra no fim, mesmo que a tela de prêmio nunca chame
			return  # o quadro do fim não conta para a trava: o prêmio sempre aparece (mesmo após um hitch longo)
		gs._ronda_fim_t += delta
		if gs._ronda_fim_t > _TEMPO_MAX_PREMIO:
			ronda_voltar()


## Fim ou SAIR: soma a lenda, esvazia o prego, marca o próximo capuz e salva TUDO numa gravação só. Devolve o prêmio (de novo: o mesmo).
func ronda_concluir() -> Dictionary:
	if gs.ronda_ativa == "" or gs._ronda_jogo == null:
		return {}
	if not gs._ronda_premio.is_empty():
		return gs._ronda_premio
	var j: RondaLogica = gs._ronda_jogo
	if j.fase != "fim":
		j.sair()
	var noite: Dictionary = _cfg().noites[gs.ronda_ativa]
	var res := j.resultado()
	var antes := lenda()
	var nova: int = mini(int(antes.legend) + int(res.lenda), _TETO)
	var nivel := _cfg().nivel_de(nova)
	var subiu: bool = nivel > int(antes.shown_level)
	var abre := _bc_num("open_campaign")
	_bc_gravar({"legend": nova, "rounds": mini(int(antes.rounds) + 1, _TETO), "scares": mini(int(antes.scares) + j.sustos, _TETO),
		"shown_level": maxi(nivel, int(antes.shown_level)), "open_campaign": abre if abre > 0 else campanha_de_abertura()})
	gs.capuz["open"] = ""
	gs.capuz["next_at"] = float(gs.capuz.hood_s) + float(_cfg().capuz.interval_s)
	gs.salvar()
	var fim_tempo: bool = not j.historico.is_empty() and str(j.historico[-1][0]) == "fim_tempo"
	var motivo := "exit" if j.saiu else ("time" if fim_tempo else "all")
	var total: int = noite.occurrences.size()
	var linhas := gs.lista_ui("ronda_reward_line")
	var texto := ""
	if motivo == "exit":
		texto = gs.texto_ui("ronda_left_line", "")
	elif motivo == "time":
		texto = gs.texto_ui("ronda_dawn_line", "")
	elif j.sustos < linhas.size():
		texto = str(linhas[j.sustos])
	var linhas_nivel := gs.lista_ui("ronda_level_up_line")
	var premio := {"night": gs.ronda_ativa, "scares": j.sustos, "seen": j.vistos, "done": j.sustos + j.vistos, "legend_gain": res.lenda,
		"legend": nova, "level_before": int(antes.level), "level": nivel, "level_up": subiu, "clean": j.sustos >= total,
		"left": total - j.sustos - j.vistos, "scares_total": _bc_num("scares"), "rounds": _bc_num("rounds"), "ended": motivo,
		"line": texto, "level_up_line": str(linhas_nivel[nivel - 1]) if subiu and nivel >= 1 and nivel - 1 < linhas_nivel.size() else "",
		"max_level": nivel >= _cfg().niveis.size(), "next_level_at": lenda().next_level_at,
		"clipping_text": gs.texto_ui(_cfg().chave_recorte(nivel), "")}
	gs._ronda_premio = premio
	if nivel != int(antes.level):
		gs.lenda_mudou.emit(nivel)
	gs.permanente_mudou.emit()
	return premio


## VOLTAR (fecha a tela de prêmio) ou depois do SAIR: devolve a sala.
func ronda_voltar() -> void:
	if gs.ronda_ativa == "":
		return
	if gs._ronda_premio.is_empty():
		ronda_concluir()
	gs.ronda_ativa = ""
	gs._ronda_jogo = null
	gs._ronda_premio = {}
	gs._ronda_fim_t = 0.0
	gs.ronda_mudou.emit("")


# ---------------------------------------------------------------- recorte do Gato Preto pelo nível da lenda
## Chave de texto do recorte agora (nível 0 = a de sempre). O nome GATO PRETO só aparece do nível 1 em diante.
func chave_recorte() -> String:
	return _cfg().chave_recorte(nivel_lenda()) if not _cfg().vazio else ""
