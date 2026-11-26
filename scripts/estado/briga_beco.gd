extends RefCounted
## Ronda 2a1: brigas de beco (Esconderijo, Dossiê, aproximação, prévia, luta da noite, estilos).
## Design: docs/fases/ronda2a-design.md; contrato com a UI: docs/fases/ronda2a-contrato.md; números: data/ronda.json -> nights.alley.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.
## Sorteio: SÓ `_rng_ronda` (ciclos da aproximação e a semente da luta). Nunca `rng`, `_rng_evento`, `_rng_fala`, `_rng_sucessao`, `_rng_treino`.
## Save: só `permanent.black_cat.alley` (opcional) e a lenda/contadores que a Ronda já grava. Tudo numa gravação só, ao apertar LUTAR.

const _TETO := 1000000000

var gs: EstadoJogo  # o GameState (autoload)
var _mapa_arte: Dictionary = {}  # cache de by_data_id.alley_fight
var _b: Dictionary = {}  # noite de briga em andamento (só em memória): {bandit, fase, approach, challenge_only, revenge, previa}


func _init(g: EstadoJogo) -> void:
	gs = g


func _cfg() -> RondaData:
	return gs.ronda_cfg


func _noite() -> Dictionary:
	return _cfg().noites.get("alley", {})


func _bandidos() -> Array:
	return _noite().get("bandits", [])


func bandido(id: String) -> Dictionary:
	for b in _bandidos():
		if str(b.id) == id:
			return b
	return {}


# ---------------------------------------------------------------- o chefe (2a2): mesmo formato do bandido, com extras
func _chefe() -> Dictionary:
	return _noite().get("boss", {})


func chefe_id() -> String:
	return str(_chefe().get("id", ""))


## Bandido ou chefe pelo id ({} se não existe). O resto do módulo trata os dois do mesmo jeito.
func alvo(id: String) -> Dictionary:
	var b := bandido(id)
	if b.is_empty() and id != "" and id == chefe_id():
		return _chefe()
	return b


func e_chefe(id: String) -> bool:
	return id != "" and id == chefe_id()


func zerar() -> void:
	_b = {}


## VOLTAR (fim da tela de prêmio ou trava de 120 s): a noite acabou.
func encerrar() -> void:
	var havia := not _b.is_empty()
	_b = {}
	if havia:
		gs.briga_mudou.emit("")


func _t(chave: String, padrao: String = "") -> String:
	return gs.texto_ui(chave, padrao)


# ---------------------------------------------------------------- save: permanent.black_cat.alley
func _alley() -> Dictionary:
	var d = gs.permanente.get("black_cat", {})
	var a = d.get("alley", {}) if d is Dictionary else {}
	return a if a is Dictionary else {}


## permanent.black_cat.boss (2a2): {chefe: {won, lost, first_win_campaign, challenge}}, opcional.
func _boss_save() -> Dictionary:
	var d = gs.permanente.get("black_cat", {})
	var a = d.get("boss", {}) if d is Dictionary else {}
	return a if a is Dictionary else {}


## Ficha de um bandido (sempre completa): {won, lost, first_win_campaign, challenge}.
func _ficha(id: String) -> Dictionary:
	var f = (_boss_save() if e_chefe(id) else _alley()).get(id, {})
	if not (f is Dictionary):
		f = {}
	return {"won": int(f.get("won", 0)), "lost": int(f.get("lost", 0)), "first_win_campaign": int(f.get("first_win_campaign", 0)),
		"challenge": bool(f.get("challenge", false))}


## permanent.black_cat.alley do save: devolve o bloco validado (só bandidos com won + lost > 0). `r` = o permanent já validado.
func validar(v: Variant, r: Dictionary, do_chefe: bool = false) -> Dictionary:
	var saida := {}
	if not (v is Dictionary):
		return saida
	var campanha: int = maxi(1, int(r.get("career_number", 1)))
	for k in v:
		var id := str(k)
		var conhecido: bool = e_chefe(id) if do_chefe else not bandido(id).is_empty()
		if not conhecido:
			gs._avisar("Briga de beco salva com %s desconhecido (%s): ignorado." % ["chefe" if do_chefe else "bandido", id])
			continue
		var f = v[k]
		if not (f is Dictionary):
			continue
		var won: int = gs._inteiro_valido(f.get("won", 0), float(_TETO))
		var lost: int = gs._inteiro_valido(f.get("lost", 0), float(_TETO))
		var desafio: bool = typeof(f.get("challenge", false)) == TYPE_BOOL and f.get("challenge", false)
		if desafio and won == 0:
			gs._avisar("Desafio de %s salvo sem vitória: descartado." % id)
			desafio = false
		var fw: int = gs._inteiro_valido(f.get("first_win_campaign", 0), 999.0)
		if won > 0:
			fw = clampi(fw if fw > 0 else campanha, 1, campanha)
		else:
			fw = 0
		if won + lost > 0:
			saida[id] = {"won": won, "lost": lost, "first_win_campaign": fw, "challenge": desafio}
	var anterior_venceu := true
	for b in ([] if do_chefe else _bandidos()):
		var w: int = int(saida.get(str(b.id), {}).get("won", 0))
		if w > 0 and not anterior_venceu:
			gs._avisar("Bandido %s vencido sem vencer o anterior: mantido (já foi ganho)." % b.id)
		anterior_venceu = w > 0
	return saida


## permanent.black_cat.boss do save (2a2). Chefe vencido sem os requisitos (save sujo) = mantido, com aviso. `beco` = o alley já validado.
func validar_chefe(v: Variant, r: Dictionary, beco: Dictionary) -> Dictionary:
	var saida := validar(v, r, true)
	for id in saida:
		if int(saida[id].won) > 0:
			var todos := true
			for b in _bandidos():
				if int(beco.get(str(b.id), {}).get("won", 0)) == 0:
					todos = false
			if not todos or int(r.get("regional_belts", 0)) < int(_chefe().get("requires", {}).get("regional_belts_min", 0)):
				gs._avisar("Chefe %s vencido sem os requisitos: mantido (já foi ganho)." % id)
	return saida


# ---------------------------------------------------------------- destrave e ordem
## A briga de beco está disponível (lenda no nível pedido, marco da liga, Ronda aberta)?
func aberta() -> bool:
	var n := _noite()
	if n.is_empty() or not bool(n.get("disponivel", false)) or not gs._ronda.ronda_aberta():
		return false
	var rq: Dictionary = n.requires
	if gs._ronda.nivel_lenda() < int(rq.get("legend_level", 0)):
		return false
	var m := str(rq.get("milestone", ""))
	return m == "" or gs.marco(m)


## O capuz abre o Esconderijo (e não o SUSTO direto)?
func esconderijo_ativo() -> bool:
	return str(_cfg().capuz.get("hideout_from", "")) == "alley" and aberta()


## Id do 1º bandido ainda não vencido ("" = os 3 já foram vencidos).
func proximo() -> String:
	for b in _bandidos():
		if int(_ficha(str(b.id)).won) == 0:
			return str(b.id)
	return ""


## Já venceu, mas falta o desafio (e ele existe): o cartão "DESAFIO" volta ao quadro.
func so_desafio(id: String) -> bool:
	var b := alvo(id)
	var f := _ficha(id)
	return not b.is_empty() and int(f.won) > 0 and not bool(f.challenge) and not b.challenge.is_empty()


func pode_ir(id: String) -> bool:
	if e_chefe(id):
		return chefe_aberto() and (int(_ficha(id).won) == 0 or so_desafio(id))
	return aberta() and not bandido(id).is_empty() and (id == proximo() or so_desafio(id))


## O que falta para o chefe, na ordem do design (§2): "legend" | "bandits" | "belt" | "" (nada falta).
func chefe_falta() -> String:
	var c := _chefe()
	var rq: Dictionary = c.get("requires", {})
	if gs._ronda.nivel_lenda() < int(rq.get("legend_level", 0)):
		return "legend"
	if bool(rq.get("all_bandits", false)):
		for b in _bandidos():
			if int(_ficha(str(b.id)).won) == 0:
				return "bandits"
	if int(gs.permanente.get("regional_belts", 0)) < int(rq.get("regional_belts_min", 0)):
		return "belt"
	return ""


## O chefe está aberto (lenda, os 3 bandidos e o Cinturão do Vale; Ronda e briga abertas)?
func chefe_aberto() -> bool:
	var c := _chefe()
	return not c.is_empty() and bool(c.get("disponivel", false)) and aberta() and chefe_falta() == ""


func chefe_falta_texto() -> String:
	match chefe_falta():
		"legend":
			return gs.preencher(_t("dossier_missing_legend", "PRECISA DA LENDA {n}"), {"n": int(_chefe().requires.legend_level)})
		"bandits":
			return _t("dossier_missing_bandits", "VENÇA OS 3 DO BECO")
		"belt":
			return _t("dossier_missing_belt", "PRECISA DO CINTURÃO DO VALE")
	return ""


## "black_cat_style:<id>" liberado? (quem pergunta é o DisciplesData, pela opção com `requires`)
func requisito_liberado(req: String) -> bool:
	if req.begins_with("black_cat_style:"):
		return estilo_liberado(req.substr(16))
	return false


func estilo_liberado(estilo_id: String) -> bool:
	var todos: Array = _bandidos().duplicate()
	if not _chefe().is_empty():
		todos.append(_chefe())
	for b in todos:
		if str(b.style.get("id", "")) == estilo_id and bool(_ficha(str(b.id)).challenge):
			return true
	return false


# ---------------------------------------------------------------- Esconderijo, quadro e Dossiê
func _passiva_info(b: Dictionary) -> Dictionary:
	var pv = b.get("passive", {})
	if not (pv is Dictionary) or pv.is_empty():
		return {}
	var id := str(pv.id)
	return {"id": id, "name": _t("opp_passive_%s_name" % id, id.to_upper()), "icon": id}


func _revanche(id: String) -> bool:
	var f := _ficha(id)
	return int(f.lost) >= 1 and int(f.won) == 0


func _cartao(b: Dictionary, so_desafio_: bool) -> Dictionary:
	var id := str(b.id)
	return {"night": "alley", "bandit": id, "name": _t(str(b.name), "???") if int(_ficha(id).won) > 0 else _t("fighter_name_hidden", "???"),
		"nickname": _t(str(b.nickname), ""), "profile": str(b.profile), "passive": _passiva_info(b),
		"challenge": {"type": str(b.challenge.get("type", "")), "text": _t(str(b.challenge.get("text", "")), "")},
		"challenge_text": _t(str(b.challenge.get("text", "")), ""), "revenge": _revanche(id), "challenge_only": so_desafio_,
		"style": b.style.duplicate(), "portrait": str(b.dossier.get("portrait", "")), "known": int(_ficha(id).won) > 0}


## O quadro ESTA NOITE: SUSTO, o próximo bandido (ou o cartão quieto) e os cartões DESAFIO.
func quadro_noite() -> Array:
	var l := gs._ronda.lenda()
	var q: Array = [{"night": "scare", "name": _t("hideout_scare_card", "RONDA NO BAIRRO"), "level": int(l.level), "legend": int(l.legend)}]
	var prox := proximo()
	var c := _chefe()
	var chefe_na_vez: bool = prox == "" and not c.is_empty() and bool(c.get("disponivel", false)) and int(_ficha(chefe_id()).won) == 0
	if prox != "":
		q.append(_cartao(bandido(prox), false))
	elif chefe_na_vez:
		q.append(_cartao_chefe(false))
	else:
		q.append({"night": "quiet", "text": _t("hideout_quiet", "O BECO ESTÁ QUIETO. POR ENQUANTO.")})
	for b in _bandidos():
		if so_desafio(str(b.id)):
			q.append(_cartao(b, true))
	if not c.is_empty() and so_desafio(chefe_id()):
		q.append(_cartao_chefe(true))
	return q


## Cartão do chefe no quadro: trancado (silhueta, "???" e o que falta) ou aberto; ou o DESAFIO depois de vencer.
func _cartao_chefe(so_desafio_: bool) -> Dictionary:
	var c := _chefe()
	var k := _cartao(c, so_desafio_)
	k["night"] = "boss"
	k["boss"] = chefe_id()
	k["locked"] = not so_desafio_ and not chefe_aberto()
	k["missing_text"] = chefe_falta_texto() if k.locked else ""
	return k


func _falta_texto(b: Dictionary, i: int) -> String:
	var n := _noite()
	var rq: Dictionary = n.get("requires", {})
	if gs._ronda.nivel_lenda() < int(rq.get("legend_level", 0)):
		return gs.preencher(_t("dossier_missing_legend", "PRECISA DA LENDA {n}"), {"n": int(rq.get("legend_level", 0))})
	var m := str(rq.get("milestone", ""))
	if m != "" and not gs.marco(m):
		return _t("dossier_missing_league", "ENTRE NA LIGA REGIONAL")
	if i > 0:
		var ant: Dictionary = _bandidos()[i - 1]
		if int(_ficha(str(ant.id)).won) == 0:
			return gs.preencher(_t("dossier_missing_prev", "VENÇA {nome} PRIMEIRO"), {"nome": _t(str(ant.nickname), "???"), "n": _t(str(ant.nickname), "???")})
	return ""


## Uma ficha por bandido, na ordem dos dados. O que o jogador ainda não ganhou vem vazio ("???" nos nomes).
func dossie() -> Array:
	var r: Array = []
	var bs := _bandidos()
	for i in bs.size():
		var b: Dictionary = bs[i]
		var id := str(b.id)
		var f := _ficha(id)
		var sabe: bool = int(f.won) > 0
		var d: Dictionary = b.dossier
		var oculto := _t("fighter_name_hidden", "???")
		r.append({"bandit": id, "known": sabe, "won": int(f.won), "lost": int(f.lost), "first_win_campaign": int(f.first_win_campaign),
			"challenge": bool(f.challenge), "style": b.style.duplicate(), "style_unlocked": estilo_liberado(str(b.style.get("id", ""))),
			"portrait": str(d.get("portrait", "")), "name": _t(str(b.name), oculto) if sabe else oculto,
			"nickname": _t(str(b.nickname), oculto) if sabe else oculto,
			"rap_sheet": _t(str(d.get("rap_sheet", "")), "") if sabe else "", "headline": _t(str(d.get("headline", "")), "") if sabe else "",
			"witness": _t(str(d.get("witness", "")), "") if sabe else "", "clipping": _t(str(b.clipping), "") if sabe else "",
			"profile": str(b.profile), "passive": _passiva_info(b), "challenge_text": _t(str(b.challenge.get("text", "")), ""),
			"stamp": gs.preencher(_t("dossier_won_stamp", "VENCIDO NA {n}ª CAMPANHA"), {"n": int(f.first_win_campaign)}) if sabe else "",
			"revenge": _revanche(id), "missing_text": "" if sabe else _falta_texto(b, i)})
	return r


## Tudo do Esconderijo de uma vez (ver o contrato).
func esconderijo() -> Dictionary:
	var rq: Dictionary = _noite().get("requires", {})
	return {"open": aberta(), "legend": gs._ronda.lenda(), "board": quadro_noite(), "dossier": dossie(),
		"boss": _ficha_chefe(), "trophies": _prateleira(), "requires": rq.duplicate()}


## A ficha do chefe do Esconderijo. "???" e textos vazios até vencer. Sem chefe nos dados = a silhueta "LENDA 5" da 2a1.
func _ficha_chefe() -> Dictionary:
	var c := _chefe()
	if c.is_empty():
		return {"known": false, "missing_text": gs.preencher(_t("dossier_missing_legend", "PRECISA DA LENDA {n}"), {"n": 5})}
	var id := chefe_id()
	var f := _ficha(id)
	var sabe: bool = int(f.won) > 0
	var d: Dictionary = c.dossier
	var oculto := _t("fighter_name_hidden", "???")
	var aberto := chefe_aberto()
	return {"id": id, "known": sabe, "won": int(f.won), "lost": int(f.lost), "first_win_campaign": int(f.first_win_campaign),
		"challenge": bool(f.challenge), "open": aberto, "missing_text": "" if sabe or aberto else chefe_falta_texto(),
		"portrait": str(d.get("portrait", "")), "name": _t(str(c.name), oculto) if sabe else oculto,
		"nickname": _t(str(c.nickname), oculto) if sabe else oculto,
		"rap_sheet": _t(str(d.get("rap_sheet", "")), "") if sabe else "", "headline": _t(str(d.get("headline", "")), "") if sabe else "",
		"witness": _t(str(d.get("witness", "")), "") if sabe else "", "clipping": _t(str(c.clipping), "") if sabe else "",
		"press_title": _t(str(c.press_title), "") if sabe else "", "profile": str(c.profile), "passive": _passiva_info(c),
		"challenge_text": _t(str(c.challenge.get("text", "")), ""),
		"stamp": gs.preencher(_t("dossier_won_stamp", "VENCIDO NA {n}ª CAMPANHA"), {"n": int(f.first_win_campaign)}) if sabe else "",
		"revenge": _revanche(id), "style": c.style.duplicate(), "style_unlocked": estilo_liberado(str(c.style.get("id", "")))}


## A prateleira do Esconderijo: 4 lugares [{slot, id, state "empty"|"normal"|"rare", sprite, name}]. Derivada do save.
func _prateleira() -> Array:
	var l: Array = []
	for i in 4:
		l.append({"slot": i, "id": "", "state": "empty", "sprite": "", "name": ""})
	var c := _chefe()
	if c.is_empty():
		return l
	var t: Dictionary = c.trophy
	var f := _ficha(chefe_id())
	var estado := "rare" if bool(f.challenge) and int(f.won) > 0 else ("normal" if int(f.won) > 0 else "empty")
	l[int(t.slot)] = {"slot": int(t.slot), "id": str(t.id), "state": estado,
		"sprite": str(t.sprite_rare) if estado == "rare" else (str(t.sprite) if estado == "normal" else ""),
		"name": _t(str(t.name_rare) if estado == "rare" else str(t.name), "") if estado != "empty" else ""}
	return l


# ---------------------------------------------------------------- IR e a aproximação
## Clicou IR de um cartão do Esconderijo. Congela o jogo, NÃO grava. {} se não pode.
func ir(bandido_id: String) -> Dictionary:
	if not gs._ronda._clicavel() or not pode_ir(bandido_id):
		return {}
	var b := alvo(bandido_id)
	var noite := _noite()
	gs.ronda_ativa = "alley"
	gs._ronda_premio = {}
	gs._ronda_fim_t = 0.0
	gs._rng_ronda.randomize()
	gs._ronda_jogo = RondaLogica.new(_cfg().cfg_aproximacao(bandido_id), gs._rng_ronda)
	var solo := so_desafio(bandido_id)
	_b = {"bandit": bandido_id, "fase": "aproximacao", "approach": "", "challenge_only": solo, "revenge": _revanche(bandido_id), "previa": {}, "boss": e_chefe(bandido_id)}
	var nivel: int = gs._ronda.nivel_lenda()
	var nome_oc := _t(str(b.approach.get("name", "")), "")
	if e_chefe(bandido_id) and int(_ficha(bandido_id).won) == 0:  # antes de vencer o chefe é "o da caixa de luz"
		nome_oc = _t("alley_occ_apagao_anon", nome_oc)
	var info := {"night": "alley", "kind": "alley_fight", "bandit": bandido_id, "name": _t(str(noite.name), "BRIGA NO BECO"),
		"tip": _t(str(noite.tip), ""), "countdown_s": noite.countdown_s, "approach_s": noite.approach_s, "night_s": noite.approach_s,
		"level": nivel, "legend": int(gs._ronda.lenda().legend), "layers": gs._ronda._ruas(), "occurrences": [str(b.approach.id)],
		"occurrence_names": [nome_oc if nome_oc != "" else str(b.approach.id).to_upper()],
		"challenge": {"type": str(b.challenge.get("type", "")), "text": _t(str(b.challenge.get("text", "")), "")},
		"challenge_only": solo, "revenge": _b.revenge, "nickname": _t(str(b.nickname), ""), "profile": str(b.profile),
		"hold_hint_s": noite.hold_hint_s, "spot": str(b.approach.get("spot", ""))}
	info.merge(_extras_chefe(b))
	gs.capuz_mudou.emit("")
	gs._capuz_vis = ""
	gs.ronda_mudou.emit("alley")
	gs.briga_mudou.emit("aproximacao")
	return info


## {fase "aproximacao"|"previa"|"luta"|"", bandit, approach "scare"|"seen"|"time"|"", challenge_only, revenge}.
## Chaves só do chefe (letreiro de entrada, arena, apagão); {} para bandido.
func _extras_chefe(b: Dictionary) -> Dictionary:
	if not e_chefe(str(b.id)):
		return {}
	return {"boss": true, "entrance_banner": _t(str(b.entrance_banner), ""), "entrance_s": float(b.entrance_s), "arena": str(b.arena),
		"blackout": {"after_round": int(b.blackout.after_round), "dark_s": float(b.blackout.dark_s)}}


func estado() -> Dictionary:
	if _b.is_empty():
		return {"fase": "", "bandit": "", "approach": "", "challenge_only": false, "revenge": false, "boss": false}
	return {"fase": str(_b.fase), "bandit": str(_b.bandit), "approach": str(_b.approach), "challenge_only": bool(_b.challenge_only),
		"revenge": bool(_b.revenge), "boss": bool(_b.get("boss", false))}


## Chamado pelo tick no lugar de TUDO enquanto `ronda_ativa == "alley"`.
func tick(delta: float) -> void:
	var j = gs._ronda_jogo
	if j == null or _b.is_empty():
		return
	if str(_b.fase) == "aproximacao":
		j.avancar(delta)
		if j.fase == "fim":  # SUSTO, VISTO ou TEMPO: os três levam à luta
			_b["approach"] = "scare" if j.sustos > 0 else ("seen" if j.vistos > 0 else "time")
			_b["fase"] = "previa"
			gs.briga_mudou.emit("previa")
	elif str(_b.fase) == "luta":
		gs._ronda_fim_t += delta
		if gs._ronda_fim_t > gs._ronda._TEMPO_MAX_PREMIO:
			gs._ronda.ronda_voltar()


## SAIR (aproximação ou prévia): nada gravado, o capuz continua no prego, a sala volta. Depois do LUTAR devolve o prêmio.
func sair() -> Dictionary:
	if not gs._ronda_premio.is_empty():
		return gs._ronda_premio
	_b = {}
	gs.ronda_ativa = ""
	gs._ronda_jogo = null
	gs._ronda_fim_t = 0.0
	gs.ronda_mudou.emit("")
	gs.briga_mudou.emit("")
	return {"left": true}


# ---------------------------------------------------------------- a luta da noite
func _opp(b: Dictionary) -> Dictionary:
	return {"id": str(b.id), "strength": b.strength, "agility": b.agility, "endurance": b.endurance, "passive": b.passive.duplicate(true),
		"style": "boxing", "name": str(b.name), "profile": str(b.profile)}


func _array(b: Dictionary) -> Array:
	return gs._luta._array_adversario(_opp(b))


## O desafio da noite foi cumprido? `res` = resultado do motor; `aproximacao` = "scare" | "seen" | "time".
func _cumpriu(b: Dictionary, res: Dictionary, aproximacao: String) -> bool:
	if not bool(res.win):
		return false
	var ch: Dictionary = b.challenge
	match str(ch.get("type", "")):
		"surprise":
			return aproximacao == "scare"
		"early_finish":
			return bool(res.ko) and int(res.round) <= int(ch.max_round)
		"clean_win":
			return float(res.pct_player) >= float(ch.min_life) - 1.0e-9
		"surprise_early":  # 2a2: SUSTO na aproximação E K.O./finalização até o fim do round max_round
			return aproximacao == "scare" and bool(res.ko) and int(res.round) <= int(ch.max_round)
	return false


## Condição por luta para a chance do desafio (contada nas mesmas sementes da chance de vencer). `surprise` não tem porcentagem.
func _cond(b: Dictionary, aproximacao: String = "") -> Callable:
	var ch: Dictionary = b.challenge
	var tipo := str(ch.get("type", ""))
	if tipo == "surprise_early":  # sem SUSTO o desafio já está perdido (sem porcentagem)
		tipo = "early_finish" if aproximacao == "scare" else ""
	match tipo:
		"early_finish":
			var mr := int(ch.max_round)
			return func(r: Dictionary) -> bool: return bool(r.win) and bool(r.ko) and int(r.round) <= mr
		"clean_win":
			var ml := float(ch.min_life)
			return func(r: Dictionary) -> bool: return bool(r.win) and float(r.pct_player) >= ml - 1.0e-9
	return Callable()


## A prévia da noite (só depois da aproximação). Mesmo formato do `previa()` da carreira, com o bandido no lugar do adversário.
func previa() -> Dictionary:
	if _b.is_empty() or str(_b.fase) != "previa":
		return {}
	var b := alvo(str(_b.bandit))
	if _b.previa.is_empty():
		_b["previa"] = _calcular_previa(b)
	var r: Dictionary = (_b.previa as Dictionary).duplicate(true)
	var ch: Dictionary = r.challenge
	var feito: bool = str(_b.approach) == "scare"
	if str(ch.get("type", "")) == "surprise":
		ch["done"] = feito
	elif str(ch.get("type", "")) == "surprise_early":
		ch["done"] = false  # só se cumpre no resultado da luta
		ch["lost"] = not feito  # sem SUSTO: "DESAFIO: PERDIDO" (by_tactic vem vazio)
	r["approach"] = {"result": str(_b.approach), "text": _t("alley_approach_%s" % str(_b.approach), "")}
	return r


func _calcular_previa(b: Dictionary) -> Dictionary:
	var jog: Array = gs._luta._atributos_cru()
	var adv := _array(b)
	var opp := _opp(b)
	var com_passiva: bool = not gs.motor.passiva.is_empty()
	var cond := _cond(b, str(_b.approach))
	var riscos := {}
	var passivas := {}
	var por_tatica := {}
	var linhas := {}
	for t in gs.lutas.taticas:
		var det: Dictionary = gs.motor.chance_detalhada(jog, adv, str(t.id), 0, cond)
		riscos[t.id] = {"label": gs.motor.rotulo(det.chance), "chance": det.chance, "percent": gs._textos._porcentagem(det.chance)}
		if com_passiva:
			passivas[t.id] = gs._textos.passiva_da_previa(gs.motor.estado_passiva(jog, adv, t.id), det, t.id)
		if det.has("cond_wins"):
			var pct: int = gs._textos._porcentagem(float(det.cond_wins) / float(det.n))
			por_tatica[t.id] = pct
			linhas[t.id] = gs.preencher(_t("challenge_chance_line", "CHANCE DO DESAFIO: {n}%"), {"n": pct})
	var tatica := str(gs.tatica) if riscos.has(gs.tatica) else str(gs.lutas.tatica_padrao)
	var id := str(b.id)
	var f := _ficha(id)
	var oculto := _t("alley_apagao_anon", "???") if e_chefe(id) else _t("fighter_name_hidden", "???")
	var r := {
		"night": "alley", "bandit": id, "boss": e_chefe(id),
		"opponent": {"id": id, "name": _t(str(b.name), oculto) if e_chefe(id) and int(f.won) > 0 else oculto, "nickname": _t(str(b.nickname), ""), "profile": str(b.profile),
			"strength": b.strength, "agility": b.agility, "endurance": b.endurance},
		"you": {"strength": jog[0], "agility": jog[1], "endurance": jog[2]},
		"tactic": tatica, "risks": riscos, "risk": str(riscos[tatica].label), "lead": gs.motor.destaque(jog, adv),
		"show_percent": true, "percent": int(riscos[tatica].percent),
		"percent_text": gs.preencher(_t("preview_percent", "{n}%"), {"n": int(riscos[tatica].percent)}),
		"revenge": int(f.lost) >= 1 and int(f.won) == 0,
		"art": gs.arte_id, "art_fight_text": gs.texto_passiva(gs.arte_id, gs.passiva_carreira),
		"art_passive": gs.passiva_carreira if gs.arte_id != "" else 0,
		"challenge": {"type": str(b.challenge.get("type", "")), "text": _t(str(b.challenge.get("text", "")), ""), "by_tactic": por_tatica,
			"line_by_tactic": linhas},
	}
	if com_passiva:
		var atual: Dictionary = passivas.get(tatica, {})
		r["passive_name"] = atual.get("name", "")
		r["passive_line"] = atual.get("line", "")
		r["passive_state"] = atual.get("state", {})
		r["passive_share"] = atual.get("share", "")
		r["passive_share_n"] = atual.get("share_n", 0)
		r["passive_tactics"] = passivas
	r.merge(gs._liga.chaves_previa(opp))  # a passiva dele (ícone, nome, linha, se atrapalha o seu jeito)
	r.merge(_extras_chefe(b))
	return r


## Mapa da arte da noite (manifest by_data_id.alley_fight): {opponent (by_data_id do bandido), vulto (by_data_id), arena (prefixo), portrait}.
## Lido do manifest uma vez; sem o mapa, devolve os ids por convenção (opp_alley_<id>, vulto_fight, arena_alley).
func arte_da_noite(bandido_id: String) -> Dictionary:
	if _mapa_arte.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/manifest.json"))
		var m = j.get("by_data_id", {}).get("alley_fight", {}) if j is Dictionary else {}
		_mapa_arte = m if m is Dictionary and not m.is_empty() else {"bandits": {}, "vulto": "vulto_fight", "arena": "arena_alley"}
	var opp := str(_mapa_arte.get("bandits", {}).get(bandido_id, "opp_alley_%s" % bandido_id))
	return {"opponent": opp, "vulto": str(_mapa_arte.get("vulto", "vulto_fight")), "arena": str(_mapa_arte.get("arena", "arena_alley")),
		"portrait": "portrait_" + opp}


## LUTAR: sorteia a semente, luta e grava TUDO numa gravação só. {} se não está na prévia ou a tática não existe.
func lutar(tatica_id: String) -> Dictionary:
	if _b.is_empty() or str(_b.fase) != "previa" or gs.lutas.tatica(tatica_id).is_empty():
		return {}
	var b := alvo(str(_b.bandit))
	var id := str(b.id)
	var chefe := e_chefe(id)
	var noite := _noite()
	var jog: Array = gs._luta._atributos_cru()
	var semente := int(gs._rng_ronda.randi())
	var res: Dictionary = gs.motor.lutar(jog, _array(b), tatica_id, semente, true)
	var venceu := bool(res.win)
	var sustou := str(_b.approach) == "scare"
	var feito := _cumpriu(b, res, str(_b.approach))
	# ---- a gravação única
	var f := _ficha(id)
	var tinha: bool = bool(f.challenge)
	var primeira: bool = venceu and int(f.won) == 0
	if venceu:
		f["won"] = mini(int(f.won) + 1, _TETO)
		if int(f.first_win_campaign) == 0:
			f["first_win_campaign"] = gs.numero_carreira()
	else:
		f["lost"] = mini(int(f.lost) + 1, _TETO)
	f["challenge"] = tinha or (venceu and feito)
	var al := (_boss_save() if chefe else _alley()).duplicate(true)  # 2a2: o chefe vive em `boss`, os bandidos em `alley`
	al[id] = f
	var L: Dictionary = noite.legend
	var antes := gs._ronda.lenda()
	var ganho: int = int(L.floor) + (int(L.per_scare) if sustou else 0) + (int(L.win) if venceu else 0)
	var nova: int = mini(int(antes.legend) + ganho, _TETO)
	var nivel: int = _cfg().nivel_de(nova)
	var subiu: bool = nivel > int(antes.shown_level)
	var abre: int = int(gs._ronda._bc_num("open_campaign"))
	gs._ronda._bc_gravar({"legend": nova, "rounds": mini(int(antes.rounds) + 1, _TETO),
		"scares": mini(int(antes.scares) + (1 if sustou else 0), _TETO), "shown_level": maxi(nivel, int(antes.shown_level)),
		"open_campaign": abre if abre > 0 else gs._ronda.campanha_de_abertura(), ("boss" if chefe else "alley"): al})
	gs.capuz["open"] = ""
	gs.capuz["next_at"] = float(gs.capuz.hood_s) + float(_cfg().capuz.interval_s)
	gs.salvar()
	# ---- o que a UI mostra
	var novo_desafio: bool = venceu and feito and not tinha
	var estilo: Dictionary = b.style if novo_desafio else {}
	var trofeu := ""  # 2a2: "" | "normal" | "rare" (o raro troca o normal no mesmo lugar)
	if chefe and novo_desafio:
		trofeu = "rare"
	elif chefe and primeira:
		trofeu = "normal"
	var linhas_nivel := gs.lista_ui("ronda_level_up_line")
	var premio := {"night": "alley", "bandit": id, "win": venceu, "ko": bool(res.ko), "finish": str(res.get("finish", "damage" if bool(res.ko) else "points")),
		"round": int(res.round), "approach": str(_b.approach), "scare": sustou, "legend_gain": ganho, "legend": nova,
		"level_before": int(antes.level), "level": nivel, "level_up": subiu,
		"level_up_line": str(linhas_nivel[nivel - 1]) if subiu and nivel >= 1 and nivel - 1 < linhas_nivel.size() else "",
		"max_level": nivel >= _cfg().niveis.size(), "next_level_at": gs._ronda.lenda().next_level_at,
		"challenge_done": novo_desafio, "challenge_ever": bool(f.challenge), "style_unlocked": str(estilo.get("id", "")), "style": estilo.duplicate(),
		"style_text": gs.preencher(_t("alley_style_unlocked", "ESTILO NOVO: {estilo}"),
			{"estilo": _t("disc_opt_%s_%s" % [estilo.get("field", ""), estilo.get("option", "")], str(estilo.get("id", "")).to_upper())}) if novo_desafio else "",
		"dossier_new": primeira, "clipping_new": primeira, "revenge": not venceu and int(f.won) == 0,
		"title": _t("alley_prize_title", "BRIGA GANHA") if venceu else _t("alley_lose_title", "NOITE PERDIDA"),
		"line": _t("alley_win_line", "") if venceu else _t("alley_lose_line", "SAIU MANCANDO"),
		"sub": "" if venceu else _t("alley_lose_sub", ""),
		"headline": _t(str(b.dossier.get("headline", "")), "") if primeira else "", "clipping_text": _t(str(b.clipping), "") if primeira else "",
		"dossier_line": _t("alley_dossier_new", "") if primeira else "", "clipping_line": _t("alley_clipping_new", "") if primeira else "",
		"challenge_line": _t("alley_challenge_cleared", "") if novo_desafio else ""}
	if chefe:
		premio["boss"] = true
		premio["title"] = _t("alley_boss_prize_title", "O BECO ACENDEU") if venceu else _t("alley_lose_title", "NOITE PERDIDA")
		premio["trophy_new"] = trofeu
		premio["press_title_new"] = primeira
		premio["poster_new"] = primeira
		premio["trophy_line"] = _t("alley_trophy_new", "") if primeira else ""
		premio["trophy_rare_line"] = _t("alley_trophy_rare", "") if novo_desafio else ""  # na 1ª vitória com desafio vêm as duas linhas
		premio["press_title_line"] = gs.preencher(_t("alley_press_title_new", ""), {"titulo": _t(str(b.press_title), "")}) if primeira else ""
		premio["poster_line"] = _t("alley_poster_new", "") if primeira else ""
		premio["press_title"] = _t(str(b.press_title), "") if primeira else ""
	gs._ronda_premio = premio
	gs._ronda_fim_t = 0.0
	_b["fase"] = "luta"
	# ---- a luta para a tela (formato do luta_atual(), sem passar por GameState.luta)
	var salvo: Dictionary = gs._luta._resultado_salvo(res)
	var luta := {"opponent": id, "tactic": tatica_id, "seed": semente, "player": {"strength": jog[0], "agility": jog[1], "endurance": jog[2]}}
	var info: Dictionary = gs._luta._montar_info_luta(_opp(b), res, salvo, luta)
	info["arena"] = str(b.arena) if chefe else "arena_alley"
	info["art"] = arte_da_noite(id)
	info["night"] = "alley"
	info["bandit"] = id
	info["fighter_name"] = _t("fighter_name_hidden", "???")
	info.merge(_extras_chefe(b))
	if chefe:
		# O apagão é só visual: na virada do round `after_round` para o seguinte, se a luta ainda não acabou. Nada do resultado muda.
		var t_apagao := float(b.blackout.after_round) * float(gs.motor.c.round_length)
		info["blackout"] = {"t": t_apagao, "dark_s": float(b.blackout.dark_s)} if float(res.t_end) > t_apagao else {}
	info["ko_banner"] = _t("alley_ko_banner", "APAGOU!")
	info["points_banner"] = _t("alley_points_win", "SAIU TONTO E FUGIU")
	info["lose_line"] = _t("alley_lose_line", "SAIU MANCANDO")
	info["night_prize"] = premio
	gs.briga_mudou.emit("luta")
	gs.dossie_mudou.emit()
	if nivel != int(antes.level):
		gs.lenda_mudou.emit(nivel)
	gs.permanente_mudou.emit()
	return info
