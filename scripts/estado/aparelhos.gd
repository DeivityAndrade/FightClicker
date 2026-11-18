extends RefCounted
## Aparelhos da fase 4b, modo assistido e caixas de equipamento da 5.1.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


func aparelho_montado(aparelho_id: String) -> bool:
	return aparelho_id in gs.aparelhos_montados_ids


## Fase 5: aparelhos que existem nesta carreira, na ordem de `dados`: os de toda carreira e o da arte escolhida (se houver).
## A UI percorre esta lista (botões de foco, cartões da aba TREINO, teclas 1..4).
func aparelhos_da_carreira() -> Array:
	var r: Array = gs.dados.aparelhos.duplicate()
	for ap in gs.dados.aparelhos_arte:
		if gs.arte_id != "" and str(ap.art) == gs.arte_id:
			r.append(ap)
	return r


## true se o aparelho existe nesta carreira (os de arte só existem na carreira da arte dele).
func aparelho_existe(aparelho_id: String) -> bool:
	var ap := gs.dados.aparelho(aparelho_id)
	return not ap.is_empty() and (str(ap.art) == "" or str(ap.art) == gs.arte_id)


## Ids dos aparelhos montados, na ordem da compra.
func aparelhos_montados() -> Array:
	return gs.aparelhos_montados_ids.duplicate()


## Aparelhos sem `unlock` (sempre montados, vêm de graça em toda carreira).
func _aparelhos_iniciais() -> Array:
	var r: Array = []
	for ap in gs.dados.aparelhos:
		if ap.unlock.is_empty():
			r.append(ap.id)
	return r


## {id, cost, requires, name, description, arrives_as} ou {} se o aparelho já vem montado.
func desbloqueio(aparelho_id: String) -> Dictionary:
	return gs.dados.aparelho(aparelho_id).get("unlock", {})


## Nome curto para frases ("ESTEIRA"): o unlock.name, ou o nome do aparelho.
func nome_curto_aparelho(aparelho_id: String) -> String:
	var u := desbloqueio(aparelho_id)
	return str(u.get("name", gs.dados.aparelho(aparelho_id).get("name", aparelho_id)))


## "owned" | "boxed" (comprado, na caixa) | "buyable" | "missing" | "locked" (inexistente = "locked") | "absent" (aparelho de outra arte: não existe aqui).
func estado_aparelho(aparelho_id: String) -> String:
	if gs.dados.aparelho(aparelho_id).is_empty():
		return "locked"
	if not aparelho_existe(aparelho_id):
		return "absent"
	if aparelho_montado(aparelho_id):
		return "owned"
	if tem_caixa(aparelho_id):
		return "boxed"  # Fase 5.1: comprado, esperando abrir (não treina, não recebe foco)
	var u := desbloqueio(aparelho_id)
	var req := str(u.get("requires", ""))
	if req != "" and not aparelho_montado(req):
		return "locked"
	return "buyable" if Economia.pode_pagar(gs.treino, float(u.cost)) else "missing"


func pode_comprar_aparelho(aparelho_id: String) -> bool:
	return not gs.acoes_bloqueadas() and estado_aparelho(aparelho_id) == "buyable"


## Compra o aparelho com Treino: foco vai para ele e salva na hora.
func comprar_aparelho(aparelho_id: String) -> bool:
	if not pode_comprar_aparelho(aparelho_id):
		return false
	gs._gastar(float(desbloqueio(aparelho_id).cost))
	if gs.dados.box_apparatus:
		# Fase 5.1: chega numa caixa; só monta, foca e treina quando abrir
		_criar_caixa(aparelho_id, "apparatus")
		gs.salvar()
		gs.caixa_criada.emit(aparelho_id, "apparatus")
		gs.economia_mudou.emit()
		return true
	_montar_aparelho(aparelho_id)
	gs.salvar()
	gs.aparelho_comprado.emit(aparelho_id)
	gs.foco_mudou.emit(gs.foco)
	gs.economia_mudou.emit()
	return true


# Monta o aparelho e (se `focus_on_open`) leva o foco para ele. Não salva nem emite sinais.
func _montar_aparelho(aparelho_id: String) -> void:
	if not aparelho_montado(aparelho_id):
		gs.aparelhos_montados_ids.append(aparelho_id)
	if gs.dados.box_focus_on_open:
		gs.foco = aparelho_id


## Chamado pela UI: true enquanto o Shift (ou o botão SEGURAR) estiver pressionado, false ao soltar
## e quando a janela perde o foco. Nada disso vai para o save.
func definir_assistido(segurando: bool) -> void:
	gs._segurando = segurando
	if not segurando:
		gs._acc_assist = _assist_primeiro()
	_atualizar_estado_assist()


## true se o Shift/botão está pressionado (mesmo sem efeito agora).
func assistido_segurando() -> bool:
	return gs._segurando


## "off" | "waiting" (segurando, mão ainda mexendo) | "active" (socando) | "metronome" (Metrônomo >= 1: assistido some).
func assistido_estado() -> String:
	if gs.nivel_metronomo >= 1:
		return "metronome"
	if not gs._segurando or not gs.sala_ativa():
		return "off"
	return "active" if _mao_parada() else "waiting"


func assistido_disponivel() -> bool:
	return gs.nivel_metronomo == 0


## Segundos entre auto-socos do assistido (já validado contra o Metrônomo 1).
func assistido_intervalo() -> float:
	return gs._assist_interval


func _mao_parada() -> bool:
	return gs._ocioso >= gs.dados.assist_still_seconds - 1.0e-9


func _assist_primeiro() -> float:
	return gs._assist_interval - minf(gs.dados.assist_first_delay, gs._assist_interval)


# Intervalo nunca igual ou mais rápido que o Metrônomo 1.
func _ajustar_assist() -> void:
	gs._assist_interval = gs.dados.assist_interval
	if gs.lutas != null and gs.lutas.metronomo.levels.size() > 0:
		var l1 := float(gs.lutas.metronomo.levels[0].interval)
		if gs._assist_interval <= l1:
			gs._assist_interval = l1 + 1.0
			push_warning("GameState: assist.interval <= Metrônomo 1 (%s s): usando %s s." % [str(l1), str(gs._assist_interval)])
	gs._acc_assist = _assist_primeiro()


func _atualizar_estado_assist() -> void:
	var novo := assistido_estado()
	if novo != gs._estado_assist:
		gs._estado_assist = novo
		gs.assistido_mudou.emit(novo)


func _tick_assistido(delta: float) -> void:
	if assistido_estado() == "active":
		gs._acc_assist += delta
		var n := 0
		while gs._acc_assist >= gs._assist_interval - 1.0e-9 and n < 3:
			gs._acc_assist -= gs._assist_interval
			if not gs.auto_socar().is_empty():
				gs.assist_socos_total += 1
			n += 1
		if gs._acc_assist >= gs._assist_interval:
			gs._acc_assist = fmod(gs._acc_assist, gs._assist_interval)
	else:
		gs._acc_assist = _assist_primeiro()
	_atualizar_estado_assist()


## Caixas fechadas, na ordem da compra: [{item, kind, hits}]. Cópia (mexer nela não muda o jogo).
func caixas() -> Array:
	return gs.caixas_lista.duplicate(true)


## true se o item (id de aparelho ou de luva) está numa caixa fechada.
func tem_caixa(item: String) -> bool:
	return _indice_caixa(item) >= 0


## A caixa do item ({item, kind, hits}) ou {} se não há.
func caixa(item: String) -> Dictionary:
	var i := _indice_caixa(item)
	return gs.caixas_lista[i].duplicate() if i >= 0 else {}


## Cliques que ainda faltam para abrir a caixa do item (0 se não há caixa).
func cliques_faltando(item: String) -> int:
	var i := _indice_caixa(item)
	return maxi(0, gs.cliques_para_abrir() - int(gs.caixas_lista[i].hits)) if i >= 0 else 0


## true se há uma luva esperando na caixa (a próxima só fica à venda depois de abrir).
func luva_em_caixa() -> bool:
	for b in gs.caixas_lista:
		if b.kind == "glove":
			return true
	return false


## Luvas que já valem (abertas): glove_level menos a que está na caixa.
func luvas_abertas() -> int:
	return maxi(0, gs.nivel_luva - (1 if luva_em_caixa() else 0))


## Um clique na caixa (só o mouse; Espaço nunca chama isto). Soma 1 batida; na última abre.
## Não treina, não dá crítico e não mexe em `_ocioso`. false se não há caixa ou a janela/luta bloqueia.
func bater_caixa(item: String) -> bool:
	var i := _indice_caixa(item)
	if i < 0 or gs.acoes_bloqueadas():
		return false
	gs.caixas_lista[i]["hits"] = int(gs.caixas_lista[i].hits) + 1
	var batidas := int(gs.caixas_lista[i].hits)
	gs.caixa_batida.emit(item, batidas)  # inclusive a última (a UI treme 1, 2, 3 px); depois vem caixa_aberta
	if batidas >= gs.cliques_para_abrir():
		abrir_caixa(item)
	return true


## Abre a caixa já (o 3º clique chama isto; público para testes). Aplica o item, foca (aparelho) e salva.
func abrir_caixa(item: String) -> bool:
	var i := _indice_caixa(item)
	if i < 0:
		return false
	var tipo := str(gs.caixas_lista[i].kind)
	gs.caixas_lista.remove_at(i)
	if tipo == "apparatus":
		_montar_aparelho(item)
	gs.salvar()
	gs.caixa_aberta.emit(item, tipo)
	if tipo == "apparatus":
		gs.aparelho_comprado.emit(item)
		gs.foco_mudou.emit(gs.foco)
	else:
		gs.luva_mudou.emit(luvas_abertas(), gs.sufixo_luva())
	gs.economia_mudou.emit()
	return true


func _indice_caixa(item: String) -> int:
	for i in gs.caixas_lista.size():
		if gs.caixas_lista[i].item == item:
			return i
	return -1


func _criar_caixa(item: String, tipo: String) -> void:
	gs.caixas_lista.append({"item": item, "kind": tipo, "hits": 0})


# Lê career.boxes: ausente/inválido = []. Descarta entrada inexistente, repetida, de aparelho já montado ou de
# outra arte, e luva que não é exatamente a última comprada. Corrige kind pelo item e prende hits em 0..clicks-1.
func _validar_caixas(v: Variant) -> Array:
	var r: Array = []
	if not (v is Array):
		return r
	var max_hits := maxi(0, gs.dados.box_clicks_to_open - 1)
	for x in v:
		if not (x is Dictionary):
			gs._avisar("Caixa salva inválida: ignorada.")
			continue
		var item := str(x.get("item", ""))
		var tipo := ""
		if not gs.dados.aparelho(item).is_empty():
			tipo = "apparatus"
		elif _indice_luva(item) >= 0:
			tipo = "glove"
		if tipo == "":
			gs._avisar("Caixa de item desconhecido ('%s'): ignorada." % item)
			continue
		if _indice_caixa_em(r, item) >= 0:
			gs._avisar("Caixa repetida ('%s'): ignorada." % item)
			continue
		if tipo == "apparatus":
			if desbloqueio(item).is_empty() or aparelho_montado(item) or not aparelho_existe(item):
				gs._avisar("Caixa de aparelho inválido ('%s'): ignorada." % item)
				continue
		elif _indice_luva(item) != gs.nivel_luva - 1:
			gs._avisar("Caixa de luva fora de lugar ('%s'): ignorada." % item)
			continue
		var h = x.get("hits", 0)
		var hits := 0
		if typeof(h) == TYPE_FLOAT or typeof(h) == TYPE_INT:
			hits = int(clampf(floorf(float(h)) if is_finite(float(h)) else 0.0, 0.0, float(max_hits)))
		r.append({"item": item, "kind": tipo, "hits": hits})
	return r


func _indice_caixa_em(lista: Array, item: String) -> int:
	for i in lista.size():
		if lista[i].item == item:
			return i
	return -1


func _indice_luva(item: String) -> int:
	for i in gs.lutas.luvas.size():
		if str(gs.lutas.luvas[i].id) == item:
			return i
	return -1


# Lista de aparelhos montados: ignora inexistente/repetido (com aviso) e sempre inclui os sem `unlock`.
func _validar_aparelhos(v: Variant, avisar_ausente: bool = true) -> Array:
	var r: Array = []
	if v is Array:
		for x in v:
			var id := str(x)
			if gs.dados.aparelho(id).is_empty() or id in r:
				gs._avisar("Aparelho salvo inválido ou repetido ('%s'): ignorado." % id)
				continue
			if not aparelho_existe(id):  # Fase 5: aparelho de outra arte (ou de arte sem arte escolhida)
				gs._avisar("Aparelho de outra arte no save ('%s'): removido." % id)
				continue
			r.append(id)
	elif avisar_ausente:
		gs._avisar("Aparelhos montados ausentes no save: só os iniciais.")
	for id in _aparelhos_iniciais():
		if not (id in r):
			r.insert(0, id)
	return r


# Aparelho que treina o atributo decisivo da derrota, se não estiver montado ("" se montado ou sorte).
func _aparelho_da_dica(motivo: Dictionary) -> String:
	if str(motivo.get("kind", "")) == "luck":
		return ""
	var atributo := str(motivo.get("attribute", ""))
	for ap in gs.dados.aparelhos:  # só os aparelhos de toda carreira (o da arte não entra na conta)
		if ap.attribute == atributo:
			return "" if aparelho_montado(ap.id) else str(ap.id)
	return ""
