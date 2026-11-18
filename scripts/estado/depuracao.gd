extends RefCounted
## Depuração e QA: tempo morto, atalhos de teste (debug_*).
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


## Métrica de tempo morto da carreira: {atual, maximo, total} em segundos. Tempo morto = garagem livre, próximo
## adversário PERIGOSO na melhor das 3 táticas e nada da loja cabe no dinheiro. Só atualiza com `risco_hud_ativo`.
func tempo_morto() -> Dictionary:
	return {"atual": gs._morto_atual, "maximo": gs._morto_max, "total": gs._morto_total}


## Menor preço da loja agora (próximo Prof. Nelson, próxima luva, próximo nível do Metrônomo), em dinheiro.
func menor_preco_loja() -> float:
	var m := INF
	for g in gs.lutas.geradores_pagos:
		m = minf(m, gs.custo_gerador_pago(g.id))
	var l = gs.proxima_luva()
	if not l.is_empty() and not gs.luva_em_caixa():
		m = minf(m, float(l.cost))
	if not gs.lutas.crew_click.is_empty() and not gs.crew_click_comprado:
		m = minf(m, float(gs.lutas.crew_click.cost))
	var mt = gs.proximo_metronomo()
	if not mt.is_empty():
		m = minf(m, float(mt.cost))
	return m


func _tick_tempo_morto(delta: float) -> void:
	var morto := false
	var opp = gs.proximo_adversario()
	if gs.risco_hud_ativo and gs.luta.is_empty() and not opp.is_empty():
		_atualizar_melhor_risco(delta)
		morto = gs._perigoso_melhor and gs.dinheiro < menor_preco_loja()
	if morto:
		gs._morto_atual += delta
		gs._morto_total += delta
		gs._morto_max = maxf(gs._morto_max, gs._morto_atual)
	else:
		gs._morto_atual = 0.0


# "Perigoso na melhor das 3 táticas": recalcula só quando atributos ou escada mudam, no máximo 1 vez por refresh do HUD.
func _atualizar_melhor_risco(delta: float) -> void:
	gs._tempo_melhor += delta
	var chave = "%d|%s|%s|%s" % [gs.indice_escada, gs.atributos.get("strength", 0.0), gs.atributos.get("agility", 0.0),
		gs.atributos.get("endurance", 0.0)]
	if chave == gs._chave_melhor:
		return
	if gs._chave_melhor != "" and gs._tempo_melhor < float(gs.lutas.risco.hud_refresh_seconds):
		return
	gs._tempo_melhor = 0.0
	gs._chave_melhor = chave
	var opp = gs.proximo_adversario()
	var algum_ok := false
	for t in gs.lutas.taticas:
		if gs.motor.passa(gs._atributos_array(), gs._array_adversario(opp), t.id, int(gs.lutas.risco.samples), float(gs.lutas.risco.even_min)):
			algum_ok = true
			break
	gs._perigoso_melhor = not algum_ok


func debug_disponivel() -> bool:
	return OS.is_debug_build()


## Multiplica só o saldo (nunca os atributos).
func debug_multiplicar_saldo() -> void:
	if not debug_disponivel():
		return
	gs._definir_treino(maxf(gs.treino, 1.0) * gs.config.multiplicador_debug)
	gs.economia_mudou.emit()


## Soma unidades de cada gerador de graça.
func debug_somar_geradores() -> void:
	if not debug_disponivel():
		return
	for g in gs.dados.geradores:
		gs.geradores[g.id] = gs.quantidade_gerador(g.id) + int(gs.config.debug_unidades_gerador)
		gs.gerador_mudou.emit(g.id, gs.geradores[g.id])
	gs.economia_mudou.emit()
