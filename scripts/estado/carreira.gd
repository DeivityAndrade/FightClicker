extends RefCounted
## Estado da escada, fim de carreira, Legado e nova carreira.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


## true durante a luta (resultado decidido, ainda não aplicado) e com a tela de fim pendente:
## a garagem não aceita clique nem compra.
## Fase 5: a janela de escolha da arte aberta também bloqueia (sem clique, Metrônomo, assistido, compra ou luta).
func acoes_bloqueadas() -> bool:
	return _bloqueio_base() or gs.no_dia_da_luta()  # Fase 5.3: no dia só LUTAR e PASSAR O POSTO funcionam


func _bloqueio_base() -> bool:
	return not gs.luta.is_empty() or not gs.fim.is_empty() or gs.sucessao != "none" or gs.cena_sala != "" or gs.escolha_arte_pendente()


func tem_luta_pendente() -> bool:
	return not gs.luta.is_empty()


func tem_fim_pendente() -> bool:
	return not gs.fim.is_empty()


func numero_carreira() -> int:
	return int(gs.permanente.get("career_number", 1))


## true quando o jogador venceu todos os adversários da escada (inclusive os da academia).
func escada_completa() -> bool:
	return gs.indice_escada >= gs.lutas.adversarios.size()


## Próximo adversário que dá para enfrentar AGORA ({} se a escada acabou ou se ele só luta em outro local:
## na garagem, depois do cinturão, o Tonhão pede a mudança). Formato: ver FightData (_montar_adversario).
func proximo_adversario() -> Dictionary:
	if escada_completa():
		return {}
	var opp: Dictionary = gs.lutas.adversarios[gs.indice_escada]
	return opp if _local_permite(opp) else {}


# Adversário sem `location` (garagem) luta em qualquer local; os de outro local só nele.
func _local_permite(opp: Dictionary) -> bool:
	return str(opp.location) == gs.academia.local_padrao or str(opp.location) == gs.local_id


## true se o próximo adversário só luta em outro local (a UI mostra o MUDAR / "PRÓXIMA: MUDE PARA A ACADEMIA").
func precisa_mudar() -> bool:
	return not escada_completa() and not _local_permite(gs.lutas.adversarios[gs.indice_escada])


## "fight" (tem adversário), "move" (precisa mudar de local) ou "end" (escada completa).
func estado_escada() -> String:
	if escada_completa():
		return "end"
	return "move" if precisa_mudar() else "fight"


func pode_lutar() -> bool:
	return not proximo_adversario().is_empty() and not _bloqueio_base()


func pode_aposentar() -> bool:
	return not _bloqueio_base()


## Legado em jogo (o "pote"): derivado da fama e do cinturão, não é salvo.
func legado_em_jogo() -> int:
	var c: Dictionary = gs.lutas.carreira
	return int(floor(gs.fama * c.legacy_per_fame + 1.0e-9)) + (int(c.belt_legacy_bonus) if gs.cinturao else 0)


## Legado que a derrota daria agora.
func legado_se_perder() -> int:
	return _com_bonus_legado(int(floor(legado_em_jogo() * parte_derrota() + 1.0e-9)))


## Fase 5.4: Legado ganho = floor(base x (1 + nó "Caderno do velho")). Vale em qualquer fim de campanha.
func _com_bonus_legado(base: int) -> int:
	return int(floor(base * (1.0 + gs._arvore._b("legacy_bonus")) + 1.0e-9))


## Fração do pote que a derrota leva: `defeat_share` + bônus da árvore, sempre abaixo de `retire_share`.
func parte_derrota() -> float:
	var c: Dictionary = gs.lutas.carreira
	var s := float(c.defeat_share) + gs._arvore._b("defeat_share_bonus")
	var teto := float(c.retire_share) - 0.05
	if s > teto:
		s = maxf(float(c.defeat_share), teto)
	return s


## Aposentar agora: {pote, base, bonus, total, cinturao, zero}. `bonus` só com cinturão.
func previa_aposentar() -> Dictionary:
	var c: Dictionary = gs.lutas.carreira
	var pote := legado_em_jogo()
	var base := int(floor(pote * c.retire_share + 1.0e-9))
	var bonus := int(floor(pote * c.retire_belt_bonus_share + 1.0e-9)) if gs.cinturao else 0
	var total := _com_bonus_legado(base + bonus)
	return {"pote": pote, "base": base, "bonus": bonus, "total": total, "cinturao": gs.cinturao,
		"notebook": total - (base + bonus), "zero": base + bonus == 0,
		"honor": gs.honra_da_saida(gs.indice_escada, gs.cinturao), "wins": gs.indice_escada}


## APOSENTAR (só entre lutas): soma o Legado e cria a tela de fim "saiu por cima". Devolve o `fim`.
func aposentar() -> Dictionary:
	if not pode_aposentar():
		return {}
	_encerrar_carreira("retire", {}, {})
	gs.luta_resolvida.emit({"win": true, "retire": true, "fim": gs.fim.duplicate(true)})
	return gs.fim.duplicate(true)


# Soma o Legado e os recordes, cria `fim` e salva, tudo num único save.
func _encerrar_carreira(tipo: String, snap: Dictionary, motivo: Dictionary) -> void:
	var ganho := legado_se_perder() if tipo == "defeat" else int(previa_aposentar().total)
	var caderno := ganho - (int(floor(legado_em_jogo() * parte_derrota() + 1.0e-9)) if tipo == "defeat" else int(previa_aposentar().total) - int(previa_aposentar().notebook))
	gs.permanente["legacy_total"] = int(gs.permanente.legacy_total) + ganho
	# Revanche: a derrota marca quem venceu; a aposentadoria limpa a marca (mesmo save do Legado).
	gs.permanente["revenge_opponent"] = str(snap.get("opponent", "")) if tipo == "defeat" else ""
	gs.permanente["careers_finished"] = int(gs.permanente.careers_finished) + 1
	gs.permanente["best_wins"] = maxi(int(gs.permanente.best_wins), gs.indice_escada)
	if gs.cinturao:
		gs.permanente["belts_won"] = int(gs.permanente.belts_won) + 1
	var motivo_fim := motivo.duplicate()
	# 6c2: Honra só por saída voluntária com vitórias; nunca multiplicada; no mesmo salvar() do Legado.
	var honra_ganha := gs.honra_da_saida(gs.indice_escada, gs.cinturao) if tipo == "retire" else 0
	gs.escola["honor"] = gs.honra() + honra_ganha
	gs.escola["honor_total"] = gs.honra_total() + honra_ganha
	gs._casa._interromper_saida()  # 6c1: o fim da campanha termina a saída do John na hora
	gs.escola["last_end"] = {"kind": tipo, "campaign": numero_carreira()}  # Fase 6a: o comentário da derrota usa isto
	if tipo == "defeat":
		motivo_fim["unlock_tip"] = gs._aparelhos._aparelho_da_dica(motivo)
	gs.fim = {
		"kind": tipo, "career_number": numero_carreira(), "legacy_gained": ganho, "legacy_notebook": caderno,
		"legacy_total": int(gs.permanente.legacy_total), "honor_gained": honra_ganha,
		"opponent": str(snap.get("opponent", "")), "tactic": str(snap.get("tactic", gs.tatica)),
		"seed": int(snap.get("seed", 0)), "player": snap.get("player", {}).duplicate(),
		"result": snap.get("result", {}).duplicate(), "reason": motivo_fim,
		"summary": {"wins": gs.indice_escada, "belts": (1 if gs.cinturao else 0) + (1 if gs._liga.cinturao_regional() else 0), "fame": gs.fama,
			"money_earned": gs.dinheiro_ganho, "play_seconds": gs.tempo_jogo, "art": gs.arte_id, "location": gs.local_id},
	}
	gs._sucessao._registrar_na_lista_da_escola(tipo, snap, ganho, honra_ganha)
	gs.salvar()
	if honra_ganha > 0:
		gs.honra_mudou.emit(gs.honra())
	gs.permanente_mudou.emit()
	gs.fim_de_carreira.emit(gs.fim.duplicate(true))


## NOVA CARREIRA (só com a tela de fim pendente): zera `career`, mantém `permanent`, soma 1 em
## "Carreira N". Volta direto para a garagem.
func nova_carreira() -> bool:
	if gs.fim.is_empty():
		return false
	_reiniciar_campanha()
	# Caminho direto (sem a tela de criação): o discípulo, se houver, é o padrão. A interface usa receber_discipulo().
	if gs.lutador_atual() == "disciple" and gs.discipulo.is_empty():
		gs.discipulo = gs._sucessao._discipulo_padrao()
	gs.salvar()
	gs._tempo_autosave = 0.0
	gs._save._emitir_tudo(false)
	gs.permanente_mudou.emit()
	_emitir_inicio_da_campanha()
	return true


# Zera a carreira e soma 1 em "Carreira N" (sem salvar nem emitir). Fase 6b1: usado por nova_carreira() e receber_discipulo().
func _reiniciar_campanha() -> void:
	# Fase 5.4: a foto dos nós (o que vale nesta campanha) é tirada aqui, ANTES de zerar (a data usa "+1 dia").
	gs.nos_ativos_ids = gs.permanente.get("skill_nodes", []).duplicate()
	gs.arte_id = ""
	gs._arvore._recalcular_bonus()
	_zerar_carreira()
	gs.permanente["career_number"] = int(gs.permanente.career_number) + 1
	gs.fim = {}
	gs.discipulo = {}
	gs.mentor_cumprimentou = false
	gs._arvore._aplicar_inicio_da_arvore()
	gs._honra._aplicar_inicio_do_hall()
	gs.nivel_metronomo = mini(int(gs._arvore._b("metronome_start")), gs.metronomo_niveis())


# O começo da campanha, na ordem da 6a: cartão, escolha da arte (a UI trata "arte antes do cartão") e a fala da derrota.
func _emitir_inicio_da_campanha() -> void:
	gs.nova_carreira_iniciada.emit(cartao_inicio())
	# Com as artes liberadas, a escolha vem ANTES do cartão (a UI abre a janela e depois mostra `cartao_inicio()`).
	if gs.escolha_arte_pendente():
		gs.escolha_arte_pedida.emit(gs.escolha_arte_primeira())
	# Fase 6a: depois de uma derrota o treinador comenta no 1º momento calmo da campanha nova.
	var fim_anterior = gs.escola.get("last_end", null)
	if fim_anterior is Dictionary and str(fim_anterior.get("kind", "")) == "defeat" \
			and int(fim_anterior.get("campaign", 0)) == numero_carreira() - 1:
		gs.disparar_gatilho("after_defeat")
		gs._derrota_rearmada = true


func _zerar_carreira() -> void:
	gs.gestos_calcados = []
	gs.frenesi_restante = 0.0
	gs.evento_dourado_restante = 0.0
	gs._evento_espera = -1.0
	gs.treino = 0.0
	gs.atributos = {}
	for id in gs.dados.atributos:
		gs.atributos[id] = 0.0
	gs.aparelhos_montados_ids = gs._aparelhos._aparelhos_iniciais()
	gs.caixas_lista = []  # Fase 5.1: caixa fechada some com a carreira, sem reembolso
	gs.foco = gs.dados.default_focus
	gs.geradores = {}
	for g in gs.dados.geradores:
		gs.geradores[g.id] = 0
	gs.niveis_melhoria = {}
	for ap in gs.dados.todos_aparelhos():
		gs.niveis_melhoria[ap.id] = 0
	gs.geradores_pagos = {}
	for g in gs.lutas.geradores_pagos:
		gs.geradores_pagos[g.id] = 0
	# Fase 5: toda carreira começa na garagem e sem arte (a janela de arte vem logo depois, se já liberou)
	gs.local_id = gs.academia.local_padrao
	gs.arte_id = ""
	gs.passiva_carreira = 1  # 7b2: a passiva se escolhe junto com a arte
	gs.arte_segundos = 0.0
	gs._academia._atualizar_passiva()
	gs.segundos_campanha = 0.0
	gs._arte_comentada = true  # sem arte ainda: o comentário volta a valer quando ela for escolhida
	gs.nivel_luva = 0
	gs.crew_click_comprado = false
	gs.dinheiro = 0.0
	gs.fama = 0
	gs.indice_escada = 0
	gs.fight_day = gs._calendario._data_da_proxima_luta()  # Dia 1 + folga do primeiro adversário
	gs.cinturao = false
	gs.rival_spoke = {"before": false, "after": false}  # 8a1: o James volta a falar na campanha nova
	gs.tatica = gs.lutas.tatica_padrao
	gs.tempo_jogo = 0.0
	gs.dinheiro_ganho = 0.0
	gs.luta = {}
	gs.nivel_metronomo = 0
	gs._acc_metronomo = 0.0
	gs._acc_assist = gs._aparelhos._assist_primeiro()
	gs._morto_atual = 0.0
	gs._morto_max = 0.0
	gs._morto_total = 0.0
	gs._chave_melhor = ""
	gs._luta._finalizar_motivo(false)
	gs._motivo_cache = {}
	gs._treino.zerar()  # 7a2: o convite e o AQUECIDO são da campanha


## Lista dos nós ativos (ordem da compra): [{id, name, effect_text, icon}]. Cartão de início e resumo da garagem.
func resumo_legado() -> Dictionary:
	var itens: Array = []
	for id in gs.nos_ativos_ids:
		var n: Dictionary = gs.lutas.no_da_arvore(str(id))
		if not n.is_empty():
			itens.append({"id": n.id, "name": n.name, "effect_text": gs.texto_efeito_no(n), "icon": n.icon})
	return {"count": itens.size(), "nodes": itens,
		"label": gs.preencher(gs.texto_ui("legacy_nodes_label", "LEGADO: {n} NÓS"), {"n": itens.size()})}


## Cartão "o que você trouxe" ({} sem nós): {title, career, nodes}. A UI mostra por até 1,8 s.
func cartao_inicio() -> Dictionary:
	var r := resumo_legado()
	if r.count == 0 and gs.arte_id == "":
		return {}
	# Fase 5: `art` / `art_text` ("ARTE: BOXE") só depois da escolha (a UI chama de novo ao fechar a janela de arte)
	return {"title": gs.preencher(gs.texto_ui("career_card_title_named", "{nome}: O QUE VOCÊ TROUXE"), {"nome": gs.nome_lutador().to_upper()}),
		"career": numero_carreira(), "name": gs.nome_lutador(), "nodes": r.nodes, "art": gs.arte_id,
		"art_text": gs.preencher(gs.texto_ui("career_card_art", "ARTE: {nome}"), {"nome": gs.nome_arte(gs.arte_id).to_upper()}) if gs.arte_id != "" else ""}
