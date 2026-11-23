extends RefCounted
## Árvore de Legado: bônus, nós, mapa e compra.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


# Soma, por tipo, dos efeitos dos nós ATIVOS da campanha (aditivo dentro do tipo; ver design §3.5).
# Fase 5.4: lê `nos_ativos_ids` (a foto), nunca `skill_nodes`; nó com `requires_art` só vale jogando aquela arte.
func _recalcular_bonus() -> void:
	var ids: Array = gs.nos_ativos_ids
	gs._bonus = bonus_de(ids, gs.arte_id)
	# Fase 5: nós ESTILO valem só para a arte deles (`requires_art`).
	gs._estilo = {}
	for id in ids:
		var n: Dictionary = gs.lutas.no_da_arvore(str(id))
		if not n.is_empty() and n.effect_type == "art_rule_bonus" and n.requires_art != "":
			gs._estilo[n.requires_art] = float(gs._estilo.get(n.requires_art, 0.0)) + float(n.effect_value)


## Bônus (por tipo de efeito) de uma lista de ids de nós. Tipos: somas (click, passive, money, fame, defeat_share,
## crew_click, gym_training, art_fight, legacy, prep_days, art_rule) e maior valor (metronome_start, preview_percent,
## rope_installed). `arte` "*" = sem filtro de arte; senão só entram nós sem `requires_art` ou da arte dada.
func bonus_de(ids: Array, arte: String = "*") -> Dictionary:
	var b := {}
	for t in FightData.TIPOS_EFEITO:
		b[t] = 0.0
	for id in ids:
		var n: Dictionary = gs.lutas.no_da_arvore(str(id))
		if n.is_empty():
			continue
		if arte != "*" and n.requires_art != "" and n.requires_art != arte:
			continue
		var t: String = n.effect_type
		if t == "start_generator":
			continue  # lido por _aplicar_inicio_da_arvore
		if t == "metronome_start" or t == "preview_percent" or t == "rope_installed":
			b[t] = maxf(float(b[t]), float(n.effect_value))
		else:
			b[t] = float(b[t]) + float(n.effect_value)
	return b


## Efeitos que agem no começo da campanha (depois de zerar): corda montada e geradores de saída.
func _aplicar_inicio_da_arvore() -> void:
	if _b("rope_installed") > 0.0 and not gs.dados.aparelho("jump_rope").is_empty() and not gs.aparelho_montado("jump_rope"):
		gs.aparelhos_montados_ids.append("jump_rope")  # sem caixa e sem foco novo
	for id in gs.nos_ativos_ids:
		var n: Dictionary = gs.lutas.no_da_arvore(str(id))
		if n.is_empty() or n.effect_type != "start_generator" or not gs.geradores.has(n.effect_target):
			continue
		gs.geradores[n.effect_target] = maxi(int(gs.geradores[n.effect_target]), int(n.effect_value))


func _b(tipo: String) -> float:
	return float(gs._bonus.get(tipo, 0.0))


## Bônus ativos da carreira em andamento (cópia, para a UI e os testes).
func bonus_ativos() -> Dictionary:
	return gs._bonus.duplicate()


func nos_comprados() -> Array:
	return gs.permanente.get("skill_nodes", []).duplicate()


func tem_no(id: String) -> bool:
	return id in gs.permanente.get("skill_nodes", [])


func legado_disponivel() -> int:
	return int(gs.permanente.get("legacy_total", 0))


## Estado de um nó para a tela ANTIGA (abas): "owned", "buyable", "missing" (falta Legado) ou "locked" (escondido no mapa).
## Id inexistente: "". O mapa novo usa `estado_mapa`.
func estado_no(id: String) -> String:
	var e := estado_mapa(id)
	if e == "" or e == "owned":
		return e
	if e == "hidden":
		return "locked"
	return "buyable" if legado_disponivel() >= int(gs.lutas.no_da_arvore(id).cost) else "missing"


## Fase 5.4: estado de um nó no mapa: "owned" (comprado), "visible" (à vista: raiz ou vizinho de comprado, trava aberta)
## ou "hidden". Calculado de skill_nodes + travas (não vai para o save). Id inexistente: "".
func estado_mapa(id: String) -> String:
	var n: Dictionary = gs.lutas.no_da_arvore(id)
	if n.is_empty():
		return ""
	if tem_no(id):
		return "owned"
	if not trava_aberta(str(n.lock)):
		return "hidden"
	if n.root:
		return "visible"
	for v in n.neighbors:
		if tem_no(str(v)):
			return "visible"
	return "hidden"


## Trava de região/nó: "" sempre; "gym" com alguma arte liberada (um discípulo já chegou à academia); "art:<id>" com a arte liberada.
func trava_aberta(trava: String) -> bool:
	if trava == "":
		return true
	if trava == "gym":
		return not gs.permanente.get("arts_unlocked", []).is_empty()
	if trava == "center":  # 8a2: aberta na 1ª mudança da linhagem para o centro
		return bool(gs.permanente.get("center_reached", false))
	if trava.begins_with("art:"):
		return trava.substr(4) in gs.permanente.get("arts_unlocked", [])
	return false


## Lista de nós na ordem do arquivo. Cada item: {id, branch, branch_name, requires, requires_name, cost, name,
## description, effect_text (já com número), icon, effect_type, effect_value, state, missing (Legado que falta, 0 se nenhum)}.
## Fase 5: ramos que a aba mostra ([{id, name}]). O ramo ESTILO só aparece com alguma arte liberada.
func arvore_ramos() -> Array:
	var r: Array = []
	for b in gs.lutas.ramos:
		if not b.requires_arts_unlocked or not gs.artes_liberadas().is_empty():
			r.append({"id": b.id, "name": b.name})
	return r


func arvore_nos() -> Array:
	var lista: Array = []
	var visiveis: Array = arvore_ramos().map(func(b): return b.id)
	for n in gs.lutas.arvore:
		if not (n.branch in visiveis):
			continue
		var item: Dictionary = n.duplicate()
		# Fase 5: nó de arte diz "SÓ VALE JOGANDO DE BOXE"
		item["art_only_text"] = gs.preencher(gs.texto_ui("tree_style_art_only", "SÓ VALE JOGANDO DE {nome}"),
			{"nome": str(gs.academia.arte(n.requires_art).get("name", "")).to_upper()}) if n.requires_art != "" else ""
		item["branch_name"] = str(gs.lutas.ramo(n.branch).get("name", n.branch))
		item["requires_name"] = str(gs.lutas.no_da_arvore(n.requires).get("name", "")) if n.requires != "" else ""
		item["effect_text"] = gs.texto_efeito_no(n)
		item["state"] = estado_no(n.id)
		item["missing"] = maxi(0, int(n.cost) - legado_disponivel()) if item.state == "missing" else 0
		lista.append(item)
	return lista


## Fase 5.4: a árvore abre em qualquer momento, menos na luta, no dia da luta, na escolha da arte e com caixa
## no meio da abertura (já tem batida). Com a tela de fim pendente abre sempre.
func pode_abrir_arvore() -> bool:
	if not gs.luta.is_empty():
		return false
	if not gs.fim.is_empty():
		return true
	if gs.no_dia_da_luta() or gs.escolha_arte_pendente():
		return false
	for b in gs.caixas_lista:
		if int(b.hits) > 0:
			return false
	return true


## Compat: "a árvore está aberta" (mesma regra de `pode_abrir_arvore`).
func arvore_aberta() -> bool:
	return pode_abrir_arvore()


## À vista, com Legado para pagar e mapa aberto.
func pode_comprar_no(id: String) -> bool:
	return pode_abrir_arvore() and pode_pagar_no(id)


## Igual a `pode_comprar_no`, sem olhar se o mapa está aberto (o brilho do botão usa isto).
func pode_pagar_no(id: String) -> bool:
	return estado_mapa(id) == "visible" and legado_disponivel() >= int(gs.lutas.no_da_arvore(id).cost)


## true se existe nó à vista que o Legado paga: o botão da sala brilha (mesmo com o mapa fechado).
func ha_no_compravel() -> bool:
	for n in gs.lutas.arvore:
		if pode_pagar_no(n.id):
			return true
	return false


## Quantos nós à vista o Legado paga agora ("{n} NÓS PARA COMPRAR").
func nos_compraveis() -> int:
	var c := 0
	for n in gs.lutas.arvore:
		if pode_pagar_no(n.id):
			c += 1
	return c


func _ids_a_vista() -> Array:
	var r: Array = []
	for n in gs.lutas.arvore:
		if estado_mapa(n.id) != "hidden":
			r.append(n.id)
	return r


## Compra o nó: desconta o Legado exato, grava o nó e salva (um save só). Recusa (nada muda) com o mapa fechado,
## nó já comprado, escondido ou Legado insuficiente. Os bônus valem a partir da PRÓXIMA campanha (`nos_ativos_ids`).
func comprar_no(id: String) -> bool:
	if not pode_comprar_no(id):
		return false
	var n: Dictionary = gs.lutas.no_da_arvore(id)
	var antes := _ids_a_vista()
	gs.permanente["legacy_total"] = maxi(0, int(gs.permanente.legacy_total) - int(n.cost))
	var nos: Array = gs.permanente.get("skill_nodes", [])
	nos.append(id)
	gs.permanente["skill_nodes"] = nos
	gs.permanente["tree_last_node"] = id
	# O `fim` pendente mostra o Legado total: mantém igual ao disponível.
	if not gs.fim.is_empty():
		gs.fim["legacy_total"] = int(gs.permanente.legacy_total)
	var novos: Array = []
	for x in _ids_a_vista():
		if not (x in antes):
			novos.append(x)
	gs.salvar()
	gs.arvore_mudou.emit()
	gs.permanente_mudou.emit()
	if not novos.is_empty():
		gs.no_revelado.emit(novos)
	return true


## Nós que valem na campanha atual (a foto de `career.active_nodes`).
func nos_ativos() -> Array:
	return gs.nos_ativos_ids.duplicate()


## Mapa inteiro para a UI (o `docs/fases/fase5.4-api.md` descreve cada chave). A UI desenha só o que não é "hidden".
func arvore_mapa() -> Array:
	var lista: Array = []
	for n in gs.lutas.arvore:
		if n.region == "" or gs.lutas.regiao(n.region).is_empty():
			continue  # nó antigo sem região (arquivo v1)
		var estado := estado_mapa(n.id)
		var item: Dictionary = n.duplicate(true)
		item["state"] = estado
		item["region_name"] = str(gs.lutas.regiao(n.region).get("name", ""))
		item["effect_text"] = gs.texto_efeito_no(n)
		item["can_buy"] = pode_comprar_no(n.id)
		item["affordable"] = pode_pagar_no(n.id)
		item["missing"] = maxi(0, int(n.cost) - legado_disponivel()) if estado == "visible" else 0
		item["active"] = n.id in gs.nos_ativos_ids
		item["next_campaign"] = estado == "owned" and not (n.id in gs.nos_ativos_ids)  # etiqueta VALE NA PRÓXIMA CAMPANHA
		item["needs_shout"] = n.effect_type == "crew_click_bonus" and not gs.crew_click_comprado
		item["art_only_text"] = gs.preencher(gs.texto_ui("tree_style_art_only", "SÓ VALE JOGANDO DE {nome}"),
			{"nome": str(gs.academia.arte(n.requires_art).get("name", "")).to_upper()}) if n.requires_art != "" else ""
		lista.append(item)
	return lista


## Dados gerais do mapa: {unit_px, regions: [{id, name, icon, lock, open}], last_node, legacy, open, can_buy_count}.
func arvore_mapa_info() -> Dictionary:
	var regs: Array = []
	for r in gs.lutas.regioes:
		regs.append({"id": r.id, "name": r.name, "icon": r.icon, "lock": r.lock, "open": trava_aberta(str(r.lock))})
	var ultimo := str(gs.permanente.get("tree_last_node", ""))
	return {"unit_px": float(gs.lutas.mapa_arvore.get("unit_px", 40.0)), "regions": regs, "last_node": ultimo,
		"legacy": legado_disponivel(), "open": pode_abrir_arvore(), "can_buy_count": nos_compraveis()}
