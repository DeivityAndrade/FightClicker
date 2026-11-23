extends RefCounted
## Fase 6a: marcos, abertura, falas com balão e gesto de calçar.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


## Quem está jogando: "first" (John Bullet, a campanha dele) ou "disciple" (discípulo padrão, das seguintes).
func lutador_atual() -> String:
	return "first" if gs.numero_carreira() <= int(gs.escola.get("first_fighter_campaign", 1)) else "disciple"


## true se o marco da escola já foi gravado (prologue_seen, first_school_win, garage_saved, garage_saved_seen...).
func marco(id: String) -> bool:
	var m = gs.escola.get("milestones", {})
	return m is Dictionary and m.has(id)


## Dados do marco ({campaign, version, ...}); {} se não existe.
func dados_marco(id: String) -> Dictionary:
	return gs.escola.milestones[id].duplicate() if marco(id) else {}


## "pending" (ainda não tocou), "playing" ou "over".
func abertura_estado() -> String:
	return gs._abertura


## Segundos de sala ativa sem clique (zera no clique; começa em 0 ao abrir o jogo). Não conta janela nem luta.
func segundos_ocioso() -> float:
	return gs._parado


## true com balão na tela (comentário ou abertura).
func tem_balao() -> bool:
	return not gs._balao.is_empty()


## Descrição da luva inicial: "o par do John" no 1º lutador, a descrição padrão nos outros.
func descricao_luva_inicial() -> String:
	if lutador_atual() == "first":
		return gs.texto_ui("glove_start_desc", gs.dialogos.texto_objeto("starter_glove_desc"))
	return gs.texto_ui("glove_start_desc_disc", str(gs.lutas.luva_base.get("description", "")))


# Grava um marco (id desconhecido também). false se já existia. `salvar_agora`: false quando quem chama salva em seguida.
func _gravar_marco(id: String, extra: Dictionary = {}, salvar_agora: bool = true) -> bool:
	if marco(id):
		return false
	var m := {"campaign": gs.numero_carreira(), "version": gs.MARCOS_VERSAO}
	for k in extra:
		m[k] = extra[k]
	gs.escola["milestones"][id] = m
	if salvar_agora:
		gs.salvar()
	gs.marco_gravado.emit(id)
	return true


## Pula a abertura (ESC segurado 0,5 s): mesmo estado final de terminar. Em "pending" só grava o marco.
func pular_abertura() -> void:
	if gs._abertura == "pending":
		_gravar_marco("prologue_seen")
		gs._abertura = "over"
		gs._ultimo_comentario = gs._t_real
		gs.abertura_mudou.emit(gs._abertura)
	elif gs._abertura == "playing":
		_terminar_abertura(true)


func _iniciar_abertura() -> void:
	if gs.dialogos.opening.get("lines", []).is_empty():
		pular_abertura()
		return
	gs._abertura = "playing"
	gs._abertura_t = 0.0
	gs._abertura_idx = 0
	gs._abertura_proxima = float(gs.dialogos.opening.get("first_line_at", 1.5))
	_gravar_marco("prologue_seen")  # em t = 0, antes do gesto e de qualquer balão: fechar o jogo não repete nada
	gs.abertura_mudou.emit(gs._abertura)
	pedir_gesto("opening")


func _tick_abertura(delta: float) -> void:
	gs._abertura_t += delta
	if gs._abertura_t >= float(gs.dialogos.opening.get("max_seconds", 20.0)):
		_terminar_abertura(false)  # o balão que está escrevendo termina sozinho
		return
	var ids: Array = gs.dialogos.opening.get("lines", [])
	if gs._abertura_idx < ids.size():
		if gs._balao.is_empty() and gs._gesto.is_empty() and gs.sala_ativa() and gs._abertura_t >= gs._abertura_proxima:
			var l := gs.dialogos.linha(str(ids[gs._abertura_idx]))
			if not l.is_empty() and str(l.speaker) == "coach" and not gs.coach_presente():
				return  # sem Osmar desenhado neste local: espera voltar a um onde ele esteja (o teto de 20 s encerra)
			gs._abertura_idx += 1
			if not l.is_empty():
				_mostrar_fala(l, false)
	elif gs._balao.is_empty():
		_terminar_abertura(false)


func _terminar_abertura(pulada: bool) -> void:
	gs._abertura = "over"
	if pulada:
		_cancelar_balao()
		cancelar_gesto()
	gs._ultimo_comentario = gs._t_real  # o fim da abertura conta como comentário
	gs.abertura_mudou.emit(gs._abertura)


## Um gatilho de comentário chegou (id de data/dialogos.json > triggers). Resolvido no próximo tick: se a sala não
## está calma, só os gatilhos `defer` ficam na vaga única; os outros somem. Público para os testes.
func disparar_gatilho(id: String, params: Dictionary = {}) -> void:
	if gs.dialogos.gatilho(id).is_empty():
		return
	gs._gatilhos_quadro.append({"id": id, "params": params})


## A UI avisa que o balão sumiu (leitura acabou). Sem isso o jogo libera sozinho depois do tempo previsto.
func fala_terminada(id: String) -> void:
	if str(gs._balao.get("id", "")) == id:
		_limpar_balao()


func _ctx_falas(params: Dictionary) -> Dictionary:
	return {"campaign": gs.numero_carreira(), "first_campaign": int(gs.escola.get("first_fighter_campaign", 1)),
		"lutador": lutador_atual(), "location": gs.local_id, "milestones": gs.escola.get("milestones", {}),
		"lines_seen": gs.escola.get("lines_seen", {}), "params": params,
		"mentor_kind": str(params.get("mentor_kind", ""))}


func _mostrar_fala(l: Dictionary, como_comentario: bool, params: Dictionary = {}) -> bool:
	var falante := str(l.speaker)
	var voz := str(gs.dialogos.personagem(falante).get("voice", falante))
	if falante == DialogosData.FALANTE_MENTOR:
		# 6c2: "mentor" vira quem está sentado no caixote: "first" (o John, voz dele) ou "last" (discípulo; voz de mentor_voice)
		var m := gs.mentor_do_caixote()
		if m.is_empty():
			return false
		falante = str(m.id)
		voz = "first"
	var texto := gs.dialogos.texto_balao(l, params)
	var dur := float(gs.dialogos.tempo_fala(texto, voz).total)
	gs._balao = {"id": str(l.id), "ate": gs._t_real + dur + float(gs.dialogos.comments.get("balloon_safety_seconds", 1.0))}
	# A UI pode recusar o balão (sem espaço) chamando fala_recusada() dentro do sinal: aí nada é gravado.
	gs._fala_recusada = false
	if not gs.baloes_escondidos:
		gs.fala_pedida.emit(falante, texto, str(l.id))
	if gs._fala_recusada:
		gs._fala_recusada = false
		gs._balao = {}
		gs._calma = 0.0  # tenta de novo só depois de uma nova calma
		if como_comentario and l.repeat == "once":
			_guardar_vaga({"id": str(l.trigger), "params": {}}, gs.dialogos.prioridade(l), true)
		return false
	if como_comentario:
		gs._ultimo_comentario = gs._t_real
		gs.escola["lines_seen"][str(l.id)] = gs.numero_carreira()
		if l.repeat == "once":
			gs.salvar()  # única: salva na hora (a repetível vai no autosave)
		gs.comentario.emit(str(l.id))
	return true


## A UI não conseguiu mostrar o balão pedido por `fala_pedida`: a fala não conta como vista (a única fica pendente).
## Chamar dentro do tratador do sinal (ou antes de qualquer outra coisa).
func fala_recusada(id: String) -> void:
	if str(gs._balao.get("id", "")) == id:
		gs._fala_recusada = true


func _limpar_balao() -> void:
	gs._balao = {}
	if gs._abertura == "playing":
		gs._abertura_proxima = gs._abertura_t + float(gs.dialogos.opening.get("gap_between", 0.3))


func _cancelar_balao() -> void:
	if gs._balao.is_empty():
		return
	var id := str(gs._balao.id)
	_limpar_balao()
	gs.fala_cancelada.emit(id)


# Janela, luta, tela de fim ou escolha da arte: o balão fecha na hora e o gesto "da sala" para.
func _fechar_para_janela() -> void:
	_cancelar_balao()
	gs._sucessao._cancelar_toques(true)
	if not gs._gesto.is_empty() and str(gs._gesto.momento) in ["opening", "glove", "idle"]:
		cancelar_gesto()


func _tick_falas(delta: float) -> void:
	if gs.cena_sala != "":
		gs._cena_sala_t += delta
		if gs._cena_sala_t > float(gs.escola_cfg.get("gym_arrival", {}).get("max_locked_seconds", 15.0)) * 2.0:
			gs.cena_sala_terminou()  # sem interface para avisar o fim: o relógio não fica parado para sempre
	gs._t_real += delta
	var ativa := gs.sala_ativa()
	if ativa:
		gs._calma += delta
		gs._parado += delta
	else:
		gs._calma = 0.0
	if not gs._balao.is_empty() and gs._t_real >= float(gs._balao.ate):
		_limpar_balao()
	if not gs._gesto.is_empty() and gs._t_real >= float(gs._gesto.ate):
		gs._gesto = {}
	gs._sucessao._tick_toques(delta, ativa)
	if gs._abertura == "pending":
		if ativa and gs.coach_presente():  # o Osmar só abre a escola onde está desenhado
			_iniciar_abertura()
	elif gs._abertura == "playing":
		_tick_abertura(delta)
	if gs._abertura == "over":
		_tick_sala_parada(ativa)
		# A parede muda quando a sala é desenhada na garagem depois do marco; o comentário vem junto.
		if ativa and gs.local_id == "garage" and marco("garage_saved") and not marco("garage_saved_seen"):
			_gravar_marco("garage_saved_seen")
			disparar_gatilho("garage_saved_return")
		elif ativa and gs.local_id == "garage" and marco("garage_saved_seen") and not gs._garagem_retomada and not gs.escola.lines_seen.has("cl_garagem_salva"):
			disparar_gatilho("garage_saved_return")  # fechou o jogo antes da fala: ela nunca se perde
		if ativa and gs.local_id == "garage" and marco("garage_saved_seen"):
			gs._garagem_retomada = true
		# Fechou o jogo logo após NOVA CAMPANHA da derrota: rearma a 1ª derrota (a fala nunca se perde)
		if ativa and gs.local_id == "garage" and not gs._derrota_rearmada:
			gs._derrota_rearmada = true
			var fim_ant = gs.escola.get("last_end", null)
			if fim_ant is Dictionary and str(fim_ant.get("kind", "")) == "defeat" \
					and int(fim_ant.get("campaign", 0)) == gs.numero_carreira() - 1 and not gs.escola.lines_seen.has("cl_primeira_derrota"):
				disparar_gatilho("after_defeat")
		# 6c1: fechou o jogo antes da cl_primeira_academia (ou save antigo que só viu a cena agora): a fala nunca se perde
		if ativa and gs.local_id == "gym" and not gs._academia_rearmada and marco(gs._casa._marco_da_chegada()) and gs.coach_presente():
			gs._academia_rearmada = true
			if not gs.escola.lines_seen.has("cl_primeira_academia"):
				disparar_gatilho("gym_arrival")
		gs._casa._tick_saida(ativa)
	_resolver_gatilhos(delta)


func _resolver_gatilhos(delta: float) -> void:
	if not gs._vaga.is_empty() and gs.sala_ativa() and not gs._saida_tocando:  # 6c1: a vaga não envelhece durante a saída do John
		gs._vaga["espera"] = float(gs._vaga.espera) + delta
		if float(gs._vaga.espera) > float(gs.dialogos.comments.get("defer_max_seconds", 15.0)) and not bool(gs._vaga.get("persiste", false)):
			gs._vaga = {}  # fala única (persiste) nunca é perdida: fica até o próximo espaço livre
	var novos := gs._gatilhos_quadro
	gs._gatilhos_quadro = []
	if novos.is_empty() and gs._vaga.is_empty():
		return
	var grupo := novos.duplicate()
	if not gs._vaga.is_empty():
		grupo.append({"id": gs._vaga.id, "params": gs._vaga.params, "vaga": true})
	var calma_base := gs.sala_ativa() and gs._abertura == "over" and gs._balao.is_empty() and not gs._saida_tocando \
		and gs._calma >= float(gs.dialogos.comments.get("settle_seconds", 2.0))
	if not calma_base:
		# Sem sala calma: só os `defer` esperam (uma vaga, vence a de maior prioridade); o resto é descartado.
		for g in novos:
			if bool(gs.dialogos.gatilho(str(g.id)).get("defer", false)):
				var m := _melhor_do_grupo([g])
				if not m.is_empty():
					_guardar_vaga(g, gs.dialogos.prioridade(m.linha), m.linha.repeat == "once")
		return
	var melhor := _melhor_do_grupo(grupo)
	if melhor.is_empty():
		if not gs._vaga.is_empty():
			gs._vaga = {}  # nada mais a dizer (a fala já tocou ou a condição mudou)
		return
	var g_ganho: Dictionary = melhor.g
	if (not gs._gesto.is_empty() or not gs._toques.is_empty()) and bool(gs.dialogos.comments.get("after_gesture", true)):
		# "O gesto antes da fala": espera ele acabar (ou ser cancelado) na vaga.
		if not g_ganho.has("vaga"):
			_guardar_vaga(g_ganho, gs.dialogos.prioridade(melhor.linha), melhor.linha.repeat == "once")
		return
	var l: Dictionary = melhor.linha
	var filler := gs.dialogos.prioridade(l) <= int(gs.dialogos.comments.get("filler_max_priority", 4))
	var intervalo := float(gs.dialogos.comments.get("gap_filler_seconds" if filler else "gap_min_seconds", 60.0))
	# Prioridade 9 ou mais (garagem salva, 1ª derrota): só precisa de espaço livre, sem o intervalo de 60 s.
	if gs.dialogos.prioridade(l) < 9 and gs._t_real - gs._ultimo_comentario < intervalo:
		# 6c1: o comentário da arte (uma vez por campanha) nunca se perde só pelo intervalo: espera na vaga até poder falar.
		# 8a2: a fala única de um gatilho `defer` (chegada ao centro) também espera na vaga, e não se perde pelo intervalo.
		var unica_adiada: bool = str(l.repeat) == "once" and bool(gs.dialogos.gatilho(str(g_ganho.id)).get("defer", false))
		if not g_ganho.has("vaga") and (unica_adiada or str(g_ganho.id) == str(gs.escola_cfg.get("art_comment", {}).get("trigger", "art_choice"))):
			_guardar_vaga(g_ganho, gs.dialogos.prioridade(l), true)
		return  # sem intervalo: o novo some; a vaga (se for ela) segue esperando até vencer o tempo dela
	if g_ganho.has("vaga"):
		gs._vaga = {}
	_mostrar_fala(l, true, g_ganho.params)


func _melhor_do_grupo(grupo: Array) -> Dictionary:
	var todas: Array = []
	var dono := {}
	var osmar := gs.coach_presente()
	for g in grupo:
		for l in gs.dialogos.candidatas(str(g.id), _ctx_falas(g.params)):
			if str(l.speaker) == "coach" and not osmar:
				continue  # 6c1: só fala quem está desenhado neste local (nunca balão sem personagem embaixo)
			if str(l.speaker) == DialogosData.FALANTE_MENTOR and gs.mentor_do_caixote().is_empty():
				continue  # 6c2: sem mentor sentado, nenhuma fala de mentor
			todas.append(l)
			dono[str(l.id)] = g
	var melhor := gs.dialogos.melhor(todas, _ctx_falas({}), gs._rng_fala)
	if melhor.is_empty():
		return {}
	return {"linha": melhor, "g": dono[str(melhor.id)]}


func _guardar_vaga(g: Dictionary, prio: int, persiste: bool = false) -> void:
	if gs._vaga.is_empty() or prio > int(gs._vaga.prio):
		gs._vaga = {"id": str(g.id), "params": g.params, "prio": prio, "espera": 0.0, "persiste": persiste}


# Fio entre os sinais que já existem e os gatilhos (design §1.4).
func _ligar_gatilhos_de_fala() -> void:
	var pares: Array = [[gs.caixa_criada, _fala_caixa_criada], [gs.melhoria_comprada, _fala_melhoria],
		[gs.metronomo_mudou, _fala_metronomo], [gs.crew_click_mudou, _fala_crew], [gs.caixa_aberta, _fala_caixa_aberta],
		[gs.luta_resolvida, _fala_luta_resolvida], [gs.aviso_data, _fala_aviso_data], [gs.luta_resolvida, gs._sucessao._toques_apos_vitoria]]
	for par in pares:
		var sinal: Signal = par[0]
		var rotina: Callable = par[1]
		if not sinal.is_connected(rotina):
			sinal.connect(rotina)


func _fala_caixa_criada(item: String, tipo: String) -> void:
	disparar_gatilho("big_purchase", {"what": tipo, "item": item})


func _fala_melhoria(aparelho: String, _melhoria: String, nivel: int) -> void:
	var total: int = gs.dados.aparelho(aparelho).get("upgrades", []).size()
	if total > 0 and nivel == total:  # 8a2: só na última de sempre (a 5ª do centro não repete a fala)
		disparar_gatilho("big_purchase", {"what": "upgrade_max", "item": aparelho})


func _fala_metronomo(nivel: int) -> void:
	if gs._metro_prev == 0 and nivel >= 1:
		disparar_gatilho("big_purchase", {"what": "metronome", "item": "metronome"})
	gs._metro_prev = nivel


func _fala_crew(comprado: bool) -> void:
	if comprado and not gs._crew_prev:
		disparar_gatilho("big_purchase", {"what": "crew_click", "item": "crew_click"})
	gs._crew_prev = comprado


func _fala_caixa_aberta(item: String, tipo: String) -> void:
	disparar_gatilho("box_opened", {"kind": tipo, "item": item})
	if tipo == "glove":
		disparar_gatilho("glove_new", {"item": item})
		pedir_gesto("glove", gs.luvas_abertas())


func _fala_luta_resolvida(resumo: Dictionary) -> void:
	var fm = resumo.get("mentor_line", {})
	if bool(resumo.get("win", false)) and not resumo.has("retire") and fm is Dictionary and not fm.is_empty():
		disparar_gatilho("mentor_won", fm)  # 6c2: o mentor comenta; a fight_won do Osmar não sai nesta vitória
	elif bool(resumo.get("win", false)) and not resumo.has("retire"):
		disparar_gatilho("fight_won", {"revenge": bool(resumo.get("revenge", false)), "record": bool(resumo.get("record", false)),
			"opponent": str(resumo.get("opponent", ""))})


func _fala_aviso_data(dias: int) -> void:
	if dias == int(gs.lutas.calendario.get("warn_days", 3)):
		var proximo: Dictionary = {} if gs.escada_completa() else gs.lutas.adversarios[gs.indice_escada]
		disparar_gatilho("fight_near", {"opponent": str(proximo.get("id", ""))})


## Pede o gesto. `momento`: "opening", "fight_intro", "victory", "glove" (com `nivel`) ou "idle". Devolve o plano
## (e emite `gesto_pedido`) ou {} se não vale: discípulo nunca faz; luva já festejada; sala não ativa (glove, idle).
## A UI chama "fight_intro" no começo da animação da luta e "victory" quando começa o `outro`;
## "opening", "glove" e "idle" o GameState chama sozinho. Plano: {momento, version ("full"|"short"), start, duration,
## rip_at (-1 no curto), taps [t1, t2] (t2 - t1 = tap_interval), rip_sound, tap_sound, pose_at (só na vitória)}.
func pedir_gesto(momento: String, nivel: int = -1) -> Dictionary:
	if lutador_atual() != "first":
		return {}
	var g: Dictionary = gs.dialogos.gesture
	var inicio := 0.0
	match momento:
		"opening":
			inicio = float(g.get("opening_start", 0.3))
		"fight_intro":
			inicio = float(g.get("fight_intro_start", 0.3))
		"victory":
			inicio = float(g.get("victory_short_start", 0.15))
		"glove":
			if nivel < 1 or nivel in gs.gestos_calcados or not gs.sala_ativa():
				return {}
			gs.gestos_calcados.append(nivel)  # cancelado pelo clique também conta como feito
			inicio = float(g.get("glove_start", 0.3))
		"idle":
			if not gs.sala_ativa() or not gs._balao.is_empty() or not gs._gesto.is_empty():
				return {}
		_:
			return {}
	var curto := momento == "victory" or momento == "idle"
	var primeiro := float(g.get("short_tap_at", 0.11) if curto else g.get("full_tap_at", 0.56))
	var sons: Dictionary = g.get("sounds", {})
	var plano := {"momento": momento, "version": "short" if curto else "full", "start": inicio,
		"duration": float(g.get("short_seconds", 0.44) if curto else g.get("full_seconds", 0.89)),
		"rip_at": -1.0 if curto else float(g.get("rip_at", 0.11)),
		"taps": [primeiro, primeiro + float(g.get("tap_interval", 0.22))],
		"rip_sound": str(sons.get("rip", "strap_rip")), "tap_sound": str(sons.get("tap", "tap_glove")),
		"pose_at": float(g.get("victory_pose_at", 0.6)) if momento == "victory" else -1.0}
	gs._gesto = {"momento": momento, "ate": gs._t_real + inicio + float(plano.duration)}
	gs.gesto_pedido.emit(plano)
	return plano


## Qualquer clique do jogador (saco, botão, fora do alvo): cancela o gesto e zera a "sala parada".
## `clicar()` já chama isto; a UI chama nos outros cliques.
func registrar_clique() -> void:
	gs._sucessao._cancelar_toques(false)  # Fase 6b1: qualquer clique cancela os toques do mentor (com a guarda do 1º clique)
	gs._toque_vitoria = -1.0  # e desiste dos toques que esperavam a volta da vitória
	gs._parado = 0.0
	gs._gestos_parada = 0
	gs._proximo_gesto_parada = float(gs.dialogos.gesture.get("idle_first_seconds", 20.0))
	gs._idle_comentou = false
	cancelar_gesto()


func cancelar_gesto() -> void:
	if gs._gesto.is_empty():
		return
	gs._gesto = {}
	gs.gesto_cancelado.emit()


# Sala parada: gesto curto aos 20 s, depois a cada 30 a 60 s (no máximo 3 por parada); comentário "parado" aos 45 s.
func _tick_sala_parada(ativa: bool) -> void:
	if not ativa:
		return
	var g: Dictionary = gs.dialogos.gesture
	if lutador_atual() == "first" and gs._gestos_parada < int(g.get("idle_max_per_stop", 3)) and gs._parado >= gs._proximo_gesto_parada \
			and gs._balao.is_empty() and gs._gesto.is_empty():
		if not pedir_gesto("idle").is_empty():
			gs._gestos_parada += 1
			gs._proximo_gesto_parada = gs._parado + gs._rng_fala.randf_range(float(g.get("idle_repeat_min", 30.0)), float(g.get("idle_repeat_max", 60.0)))
	if not gs._idle_comentou and gs._parado >= float(gs.dialogos.comments.get("idle_comment_seconds", 45.0)):
		gs._idle_comentou = true
		disparar_gatilho("idle")


# Zera o que é só de sessão (balão, vaga, intervalo, gesto) e decide o estado da abertura. Carga e "Apagar save".
func _reiniciar_falas() -> void:
	if not gs._balao.is_empty():
		gs.fala_cancelada.emit(str(gs._balao.id))
	gs._balao = {}
	gs._gesto = {}
	gs._toques = {}
	gs._toque_ultimo = -1.0e9
	gs._toque_vitoria = -1.0
	gs._vaga = {}
	gs._gatilhos_quadro = []
	gs._ultimo_comentario = -1.0e9
	gs._calma = 0.0
	gs._parado = 0.0
	gs._gestos_parada = 0
	gs._proximo_gesto_parada = float(gs.dialogos.gesture.get("idle_first_seconds", 20.0))
	gs._idle_comentou = false
	gs._garagem_retomada = false
	gs._derrota_rearmada = false
	gs.cena_sala = ""  # 6c1: nada do que é só de sessão sobra depois de carregar
	gs._saida_tocando = false
	gs._saida_elenco = {}
	gs._academia_rearmada = false
	gs._arte_comentada = gs.arte_id == "" or gs.arte_segundos >= float(gs.escola_cfg.get("art_comment", {}).get("after_art_seconds", 60.0))
	gs._abertura_t = 0.0
	gs._abertura_idx = 0
	gs._abertura = "over" if marco("prologue_seen") else "pending"
	gs.abertura_mudou.emit(gs._abertura)


func _validar_gestos(v: Variant) -> Array:
	var r: Array = []
	if not (v is Array):
		return r
	for x in v:
		if typeof(x) != TYPE_FLOAT and typeof(x) != TYPE_INT:
			continue
		var n := int(x)
		if n >= 1 and n <= gs.lutas.luvas.size() and not (n in r):
			r.append(n)
	return r


# state.school: ausente ou inválido recebe o padrão da migração (campanha atual, ou a próxima se há fim pendente).
func _validar_escola(v: Variant, havia_save: bool) -> Dictionary:
	var padrao_primeiro := gs.numero_carreira() + (1 if not gs.fim.is_empty() else 0)
	var s: Dictionary = {}
	if v is Dictionary:
		s = v
	elif v != null:
		gs._avisar("Bloco da escola inválido: recriado pelo padrão.")
	elif havia_save:
		push_warning("GameState: save sem o bloco da escola: recriado pelo padrão.")
	var r := {"first_fighter_campaign": padrao_primeiro, "milestones": {}, "lines_seen": {}, "last_end": null,
		"handover": null, "mentors": [], "roster": [], "honor": 0, "honor_total": 0, "hall_nodes": []}
	var f = s.get("first_fighter_campaign", null)
	if (typeof(f) == TYPE_INT or typeof(f) == TYPE_FLOAT) and is_finite(float(f)) and float(f) >= 1.0 and float(f) < 1.0e9:
		r["first_fighter_campaign"] = int(f)
	elif f != null:
		gs._avisar("Campanha do 1º lutador inválida: padrão aplicado.")
	var marcos = s.get("milestones", {})
	if marcos is Dictionary:
		for id in marcos:
			var m = marcos[id]
			var extra := {}
			var camp := 1
			var ver := gs.MARCOS_VERSAO
			if m is Dictionary:
				extra = m.duplicate(true)
				camp = maxi(1, gs._inteiro_valido(m.get("campaign", 1), 1.0e9))
				ver = maxi(1, gs._inteiro_valido(m.get("version", gs.MARCOS_VERSAO), 1.0e6))
			extra["campaign"] = camp
			extra["version"] = ver
			r["milestones"][str(id)] = extra
	elif s.has("milestones"):
		gs._avisar("Marcos da escola inválidos: zerados.")
	var vistas = s.get("lines_seen", {})
	if vistas is Dictionary:
		for id in vistas:
			if typeof(vistas[id]) == TYPE_INT or typeof(vistas[id]) == TYPE_FLOAT:
				var n := gs._inteiro_valido(vistas[id], 1.0e9)
				if n >= 1:
					r["lines_seen"][str(id)] = n
	elif s.has("lines_seen"):
		gs._avisar("Falas vistas inválidas: zeradas.")
	var le = s.get("last_end", null)
	if le is Dictionary and str(le.get("kind", "")) in ["defeat", "retire"]:
		r["last_end"] = {"kind": str(le.kind), "campaign": maxi(1, gs._inteiro_valido(le.get("campaign", 1), 1.0e9))}
	elif not gs.fim.is_empty():
		r["last_end"] = {"kind": str(gs.fim.kind), "campaign": int(gs.fim.career_number)}
	gs._sucessao._validar_escola_6b(s, r)
	gs._honra._validar_escola_6c2(s, r)
	gs._liga.validar_escola(s, r)  # 8a1: placar do James
	return r
