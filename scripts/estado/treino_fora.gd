extends RefCounted
## Fase 7a2 (Treino fora de hora): convite do seu Osmar, estado "treino fora", prêmios do Choque e da Panfletagem,
## AQUECIDO e a semente do Gato Preto. Design: docs/fases/fase7a2-design.md; números: data/minigames.json.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.
## Não usa nenhum sorteio do jogo (rng, _rng_evento, _rng_fala, _rng_sucessao): o convite só depende de relógio e regras;
## o minigame usa o `_rng_treino`, que não vai para o save.

const _TEMPO_MAX_PREMIO := 120.0  # trava de segurança: a tela de prêmio nunca prende a sala para sempre

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


# ---------------------------------------------------------------- estado do convite (save: career.training_invite)
func _padrao() -> Dictionary:
	var primeiro := float(gs.minigames.invite.first_after_s) if gs.minigames != null and not gs.minigames.vazio else 300.0
	return {"room_s": 0.0, "next_at": primeiro, "open": "", "open_since": 0.0, "last": "", "warm": false}


## Nova campanha (e carga sem o campo): tudo volta ao padrão, e o minigame em andamento some.
func zerar() -> void:
	gs.convite = _padrao()
	gs.treino_fora = ""
	gs._treino_jogo = null
	gs._treino_premio = {}
	gs._convite_vis = ""
	gs._convite_local = gs.local_id


## Valida o campo do save. Ausente = padrão; número ruim = padrão; `open`/`last` fora da lista = ""; `warm` só com arte e luta pela frente.
func validar(v: Variant) -> Dictionary:
	var r := _padrao()
	if not (v is Dictionary):
		return r
	var room := gs._numero_valido(v.get("room_s", 0.0))
	r["room_s"] = room
	var na = v.get("next_at", null)
	if (typeof(na) == TYPE_FLOAT or typeof(na) == TYPE_INT) and is_finite(float(na)) and float(na) >= 0.0:
		r["next_at"] = minf(float(na), gs.VALOR_MAXIMO)
	var op := str(v.get("open", "")) if v.get("open", "") is String else ""
	r["open"] = op if op in ["spar", "flyers"] and _elegivel(op) else ""
	var desde = v.get("open_since", 0.0)
	r["open_since"] = clampf(gs._numero_valido(desde), 0.0, room) if r.open != "" else 0.0
	var ul := str(v.get("last", "")) if v.get("last", "") is String else ""
	r["last"] = ul if ul in ["spar", "flyers"] else ""
	r["warm"] = typeof(v.get("warm", false)) == TYPE_BOOL and bool(v.get("warm", false)) and gs.arte_id != "" and not gs.escada_completa()
	return r


# ---------------------------------------------------------------- regras do convite
func _kind_cfg(kind: String) -> Dictionary:
	var k = gs.minigames.invite.kinds.get(kind, {})
	return k if k is Dictionary else {}


func _elegivel(kind: String) -> bool:
	if gs.minigames == null or gs.minigames.vazio:
		return false
	var bloco: Dictionary = gs.minigames.spar if kind == "spar" else gs.minigames.flyers
	if bloco.is_empty():
		return false
	var k := _kind_cfg(kind)
	if bool(k.get("requires_art", false)) and gs.arte_id == "":
		return false
	var m := str(k.get("requires_milestone", ""))
	return m == "" or gs.marco(m)


func _escolher() -> String:
	var eleg: Array = []
	for k in ["spar", "flyers"]:
		if _elegivel(k):
			eleg.append(k)
	if eleg.is_empty():
		return ""
	if eleg.size() == 1:
		return str(eleg[0])
	if bool(gs.convite.warm):
		return "flyers"  # o Choque já deu o AQUECIDO que ele pode dar
	if str(gs.convite.last) == "":
		return "spar"
	return "flyers" if str(gs.convite.last) == "spar" else "spar"


## Algo na sala está falando, gesticulando ou abrindo: o balão do convite espera (e o tempo dele para).
func _escondido() -> bool:
	if not gs._balao.is_empty() or gs._abertura != "over" or gs._saida_tocando or not gs._toques.is_empty():
		return true
	return not gs._gesto.is_empty() and str(gs._gesto.get("momento", "")) == "glove"


func _fechar() -> void:
	gs.convite["open"] = ""
	gs.convite["open_since"] = 0.0


## Chamado todo quadro dentro do bloco de tick da carreira. `dt` = tempo de sala deste quadro (0 com a sala parada).
func tick(delta: float, dt: float) -> void:
	if gs.minigames == null or gs.minigames.vazio:
		return
	var c: Dictionary = gs.convite
	if gs.treino_fora != "":
		_tick_fora(delta)
		return
	# fecha em silêncio: dia da luta e MUDAR
	if str(c.open) != "" and (gs.no_dia_da_luta() or gs.local_id != gs._convite_local):
		_fechar()
	gs._convite_local = gs.local_id
	if dt <= 0.0 or not gs.coach_presente():
		return
	c["room_s"] = float(c.room_s) + dt
	var inv: Dictionary = gs.minigames.invite
	if str(c.open) != "":
		if _escondido():
			c["open_since"] = float(c.open_since) + dt  # escondido: o tempo do balão para
		elif float(c.room_s) - float(c.open_since) >= float(inv.visible_s) - 1.0e-6:
			_fechar()  # ignorado: some sozinho
	elif float(c.room_s) >= float(c.next_at) - 1.0e-6 and not _escondido():
		var kind := _escolher()
		if kind != "":
			c["open"] = kind
			c["open_since"] = float(c.room_s)
			c["last"] = kind
			c["next_at"] = float(c.room_s) + float(inv.interval_s)


## Chamado no fim do tick: avisa a UI quando o balão aparece ou some.
func atualizar_visivel() -> void:
	var v := convite_visivel()
	if v != gs._convite_vis:
		gs._convite_vis = v
		gs.convite_mudou.emit(v)


## Tipo do convite que a UI deve desenhar agora ("" = nenhum balão): "spar" | "flyers".
func convite_visivel() -> String:
	if gs.minigames == null or gs.minigames.vazio or str(gs.convite.open) == "" or gs.treino_fora != "":
		return ""
	if not gs.sala_ativa() or not gs.coach_presente() or _escondido():
		return ""
	return str(gs.convite.open)


## Para a UI: {kind, restante_s (segundos de sala até sumir), proximo_em_s}. {} sem balão.
func convite_info() -> Dictionary:
	var k := convite_visivel()
	if k == "":
		return {}
	var rest := float(gs.minigames.invite.visible_s) - (float(gs.convite.room_s) - float(gs.convite.open_since))
	return {"kind": k, "restante_s": maxf(rest, 0.0), "proximo_em_s": maxf(float(gs.convite.next_at) - float(gs.convite.room_s), 0.0)}


# ---------------------------------------------------------------- IR, jogo e prêmio
func nivel_treino() -> int:
	return clampi(gs.indice_escada, 0, int(gs.minigames.nivel_max))


## Clicou em IR (ou no Osmar com o balão aberto). Consome o convite, salva e abre o minigame.
## Devolve {} se não havia convite visível; senão {kind, art, level, variant, rumor_text, countdown_s, duration_s}.
func convite_ir() -> Dictionary:
	var kind := convite_visivel()
	if kind == "":
		return {}
	_fechar()
	gs.treino_fora = kind
	gs._treino_premio = {}
	gs._treino_fim_t = 0.0
	gs._rng_treino.randomize()
	var info := {"kind": kind, "art": gs.arte_id, "level": nivel_treino(), "rumor_text": ""}
	if kind == "spar":
		gs._treino_jogo = ChoqueLogica.new(gs.minigames.spar, gs.arte_id, nivel_treino(), gs._rng_treino)
		info["variant"] = gs.arte_id
		info["countdown_s"] = gs.minigames.spar.countdown_s
		info["duration_s"] = gs.minigames.spar.duration_s
	else:
		gs._treino_jogo = PanfletoLogica.new(gs.minigames.flyers, nivel_treino(), gs._rng_treino)
		info["variant"] = "flyers"
		info["countdown_s"] = gs.minigames.flyers.countdown_s
		info["duration_s"] = gs.minigames.flyers.duration_s
		if _rumor_devido():
			info["rumor_text"] = gs.texto_ui("black_cat_rumor", "O VULTO MASCARADO ANDA PELA RUA DE NOITE.")
			gs._escola._gravar_marco(str(gs.minigames.black_cat.rumor.get("milestone", "black_cat_rumor_heard")), {}, false)
	gs.salvar()
	gs.convite_mudou.emit("")
	gs._convite_vis = ""
	gs.treino_fora_mudou.emit(kind)
	return info


func _tick_fora(delta: float) -> void:
	# Relógio da campanha parado (sala_ativa falso); só a equipe produz, indo para o foco atual.
	# A equipe só produz enquanto o minigame roda: parado na tela de prêmio, não rende nada (teto de 10%).
	var j = gs._treino_jogo
	var prod := gs.producao_total() if (j == null or j.fase != "fim") else 0.0
	if prod > 0.0:
		gs._ganhar(prod * delta)
	if j != null:
		j.passo(delta)
		if j.fase == "fim":
			gs._treino_fim_t += delta
			if gs._treino_fim_t > _TEMPO_MAX_PREMIO:
				treino_voltar()  # a tela de prêmio nunca chegou a fechar: devolve a sala


## O minigame em andamento (ChoqueLogica | PanfletoLogica) ou null. A UI lê `estado()` e manda as entradas; quem
## faz passar o tempo é o tick do GameState (a UI NÃO chama `passo`).
func treino_jogo() -> Variant:
	return gs._treino_jogo


## Fim do jogo ou SAIR: aplica o prêmio de uma vez, salva e devolve o prêmio. Pode ser chamada de novo (devolve o mesmo).
func treino_concluir() -> Dictionary:
	if gs.treino_fora == "" or gs._treino_jogo == null:
		return {}
	if not gs._treino_premio.is_empty():
		return gs._treino_premio
	var j = gs._treino_jogo
	if j.fase != "fim":
		j.sair()
	var p := _premio_spar(j) if gs.treino_fora == "spar" else _premio_panfleto(j)
	gs._treino_premio = p
	gs.salvar()
	return p


func _premio_spar(j: ChoqueLogica) -> Dictionary:
	var S: Dictionary = gs.minigames.spar
	var ref := gs.producao_total() + gs.minigames.ref_clicks_per_s * gs.por_clique()
	var treino := float(S.reward.max_seconds) * ref * j.nota()
	var antes := gs.atributos.duplicate()
	var ap := str(gs.academia.arte(gs.arte_id).get("apparatus", ""))
	gs._ganhar(treino, ap)
	var delta := {}
	for id in gs.atributos:
		var d := float(gs.atributos[id]) - float(antes.get(id, 0.0))
		if d > 0.0:
			delta[id] = d
	var venceu := j.venceu()
	var novo := false
	var ja := false
	var sem_luta := false
	if venceu:
		if gs.escada_completa():
			sem_luta = true
		elif bool(gs.convite.warm):
			ja = true
		else:
			gs.convite["warm"] = true
			novo = true
	if novo:
		gs.atualizar_risco_hud()
		gs.aquecido_mudou.emit(true)
	return {"kind": "spar", "pontos": j.pontos, "pontos_dele": j.pontos_dele, "nota": j.nota(), "venceu": venceu, "saiu": j.saiu,
		"treino": treino, "atributos": delta, "fama": 0, "aquecido": novo, "aquecido_ja": ja, "sem_luta": sem_luta}


func _premio_panfleto(j: PanfletoLogica) -> Dictionary:
	var i := mini(gs.indice_escada, gs.lutas.adversarios.size() - 1)
	var f := j.fama(float(gs.lutas.adversarios[i].prize_fame))
	gs.fama = clampi(gs.fama + f, 0, int(1.0e15))
	gs.fama_mudou.emit(gs.fama)
	gs.escada_mudou.emit()  # o Legado em jogo depende da fama
	gs.economia_mudou.emit()
	return {"kind": "flyers", "aceitos": j.aceitos, "erros": j.erros, "liquidos": j.liquidos(), "nota": j.nota(), "saiu": j.saiu,
		"treino": 0.0, "atributos": {}, "fama": f, "venceu": false, "aquecido": false, "aquecido_ja": false, "sem_luta": false}


## VOLTAR (fecha a tela de prêmio) ou depois do SAIR: devolve a sala. O próximo convite espera `min_after_return_s` de sala.
func treino_voltar() -> void:
	if gs.treino_fora == "":
		return
	if gs._treino_premio.is_empty():
		treino_concluir()
	var c: Dictionary = gs.convite
	c["next_at"] = maxf(float(c.next_at), float(c.room_s) + float(gs.minigames.invite.min_after_return_s))
	gs.treino_fora = ""
	gs._treino_jogo = null
	gs._treino_premio = {}
	gs._treino_fim_t = 0.0
	gs.treino_fora_mudou.emit("")


# ---------------------------------------------------------------- AQUECIDO
## AQUECIDO guardado e valendo para a próxima luta (precisa de arte e de luta pela frente).
func aquecido() -> bool:
	return bool(gs.convite.get("warm", false)) and gs.arte_id != "" and not gs.escada_completa()


## Fator dos atributos do jogador na luta: 1 + attr_bonus com AQUECIDO, senão 1. A MESMA conta na prévia, no risco, no motor.
func mult_aquecido() -> float:
	if not aquecido() or gs.minigames.spar.is_empty():
		return 1.0
	return 1.0 + float(gs.minigames.spar.warm.attr_bonus)


## Gasto quando a luta começa (ganhe ou perca).
func gastar_aquecido() -> void:
	if bool(gs.convite.get("warm", false)):
		gs.convite["warm"] = false
		gs.aquecido_mudou.emit(false)


## Chaves extras da prévia (só existem com AQUECIDO): warm, warm_pct, warm_gain (da tática escolhida), warm_gains (por tática), warm_line.
func extras_previa(riscos: Dictionary, cru: Array, adv: Array, com_passiva: bool) -> Dictionary:
	var ganhos := {}
	for t in gs.lutas.taticas:
		var sem: float = gs.motor.chance_detalhada(cru, adv, t.id).chance if com_passiva else gs.motor.chance(cru, adv, t.id)
		ganhos[t.id] = int(riscos[t.id].percent) - int(gs._textos._porcentagem(sem))
	var pct := int(round(100.0 * float(gs.minigames.spar.warm.attr_bonus)))
	var atual: int = int(ganhos.get(gs.tatica, 0))
	return {"warm": true, "warm_pct": pct, "warm_gain": atual, "warm_gains": ganhos,
		"warm_line": gs.preencher(gs.texto_ui("warm_preview_line", "AQUECIDO: +{pct}% NOS ATRIBUTOS (+{n} NA CHANCE)"), {"pct": pct, "n": atual})}


# ---------------------------------------------------------------- Gato Preto (só a semente)
func _clipping() -> Dictionary:
	if gs.minigames == null or gs.minigames.vazio:
		return {}
	var s = gs.minigames.black_cat.get("clipping", {})
	return s if s is Dictionary else {}


# As condições do recorte (sem olhar o manifest): marco, campanha e marco do local.
func _recorte_condicoes() -> bool:
	var s := _clipping()
	if s.is_empty():
		return false
	var req := str(s.get("requires_milestone", ""))
	if req != "" and not gs.marco(req):
		return false
	if gs.numero_carreira() < int(s.get("min_campaign", 2)):
		return false
	var por_local = s.get("requires_milestone_by_location", {})
	var rl := str(por_local.get(gs.local_id, "")) if por_local is Dictionary else ""
	return rl == "" or gs.marco(rl)


## O recorte de jornal do local atual: {spot [x, y], object_text} ou {} (campanha 1, sem o marco, ou sem ponto no manifest).
func recorte_gato_preto() -> Dictionary:
	if not _recorte_condicoes():
		return {}
	var s := _clipping()
	var spots = s.get("spot_by_location", {})
	var nome := str(spots.get(gs.local_id, "")) if spots is Dictionary else ""
	if nome == "":
		return {}
	var p: Array = gs._casa._cena_dados_pontos().ponto_caminho(nome)
	if p.is_empty():
		return {}
	return {"spot": p, "object_text": str(s.get("object_text", "black_cat_clipping"))}


func _rumor_devido() -> bool:
	var r = gs.minigames.black_cat.get("rumor", {})
	if not (r is Dictionary):
		return false
	var m := str(r.get("milestone", "black_cat_rumor_heard"))
	return _recorte_condicoes() and not gs.marco(m)
