extends RefCounted
## Fase 5: garagem x academia, mudança, artes marciais e traço de luta.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


## Multiplicador global de treino do local atual (garagem 1,0; academia 2,0), lido de data/locations.json.
func mult_local() -> float:
	var m := float(gs.academia.local(gs.local_id).get("training_mult", 1.0))
	if m != 1.0:
		m *= 1.0 + gs._arvore._b("gym_training_bonus")  # Fase 5.4: Ventilador novo (só fora da garagem)
	return m


## Local atual: {id, name, ambience, training_mult, apparatus_suffix, ...}. O sufixo vai nos sprites dos aparelhos básicos.
func local_atual() -> Dictionary:
	return gs.academia.local(gs.local_id)


func sufixo_aparelhos() -> String:
	return str(local_atual().get("apparatus_suffix", ""))


## true se o treino está multiplicado por causa do local (a UI mostra `texto_hud_local()`).
func em_academia() -> bool:
	return mult_local() != 1.0


## Dados do botão MUDAR ({} se não há para onde mudar: já está lá). Chaves: id, location, cost, name, mult, button,
## description, title, price_text, effect_text, keeps_text, per_career_text, state ("locked" sem cinturão,
## "missing" sem dinheiro, "ready").
func mudanca() -> Dictionary:
	var d := gs.academia.destino_mudanca(gs.local_id)  # 8a2: o próximo local depois do atual
	if d.is_empty() or d.id == gs.local_id:
		return {}
	var custo := float(d.move.cost)
	return {
		"id": d.move.id, "location": d.id, "cost": custo, "name": d.name, "mult": d.training_mult,
		"button": d.move_button if d.move_button != "" else gs.texto_ui("move_button", "MUDAR"),
		"description": d.move_description,
		"title": _texto_local("move_title", d.id), "price_text": gs.preencher(gs.texto_ui("move_price", "${n}"), {"n": NumberFormat.fmt(custo)}),
		"effect_text": gs.preencher(_texto_local("move_effect", d.id), {"mult": NumberFormat.fmt(float(d.training_mult))}),
		"keeps_text": gs.texto_ui("move_keeps"), "per_career_text": gs.texto_ui("move_per_career"),
		"state": estado_mudanca(),
		# 8a2: textos por local (centro: chaves com `_center`; "" se o local não tem). Aviso "sem luta nova", toast da chegada e HUD.
		"no_fights_text": gs.texto_ui("move_no_fights_" + str(d.id), ""), "arrived_text": gs.texto_ui("move_arrived_" + str(d.id), ""),
		"hud_next_text": _texto_local("hud_next_move", d.id),
	}


## Texto por local: a academia usa a chave sem sufixo; os outros locais usam `<chave>_<local>` (se não existir, a chave sem sufixo).
func _texto_local(chave: String, local: String) -> String:
	var base := gs.texto_ui(chave)
	if local == "gym":
		return base
	return gs.texto_ui("%s_%s" % [chave, local], base)


## 8a2: o requisito do local de destino vale? "belt" = cinturão amador (o da academia); "regional_belt" = Cinturão do Vale (o do centro).
func _requisito_cumprido(destino: Dictionary) -> bool:
	if str(destino.move.get("requires", "belt")) == "regional_belt":
		return gs.cinturao_regional()
	return gs.cinturao


## "none" (nada a comprar), "locked" (falta o cinturão: o botão não existe), "missing" (cinturão sem o dinheiro: apagado) ou "ready".
func estado_mudanca() -> String:
	var d := gs.academia.destino_mudanca(gs.local_id)
	if d.is_empty() or d.id == gs.local_id:
		return "none"
	if not _requisito_cumprido(d):
		return "locked"
	return "ready" if Economia.pode_pagar(gs.dinheiro, float(d.move.cost)) else "missing"


func pode_mudar() -> bool:
	return estado_mudanca() == "ready" and not gs.acoes_bloqueadas()


## MUDAR: desconta o preço uma vez, vai para o local, e na 1ª vez libera todas as artes e pede a escolha. Salva na hora.
## Mudar nunca tira nada (geradores, melhorias, aparelhos, luva, Metrônomo, Treino, atributos ficam).
func mudar() -> bool:
	if not pode_mudar():
		return false
	var d := gs.academia.destino_mudanca(gs.local_id)
	gs._gastar_dinheiro(float(d.move.cost))
	gs._casa._interromper_saida()  # 6c1: trocar de local no meio da saída do John a termina na hora
	var estava_parado := gs.estado_escada() == "move"
	gs.local_id = str(d.id)
	gs._reacao_cena = ""
	if estava_parado and gs.calendario_ligado():
		gs.fight_day = gs._calendario._data_da_proxima_luta()  # B3: chegou ao novo local, folga cheia a partir de hoje
	var primeira: bool = gs.permanente.arts_unlocked.is_empty() and not gs.academia.artes.is_empty()
	if primeira:
		gs.permanente["arts_unlocked"] = gs.academia.ids_artes_iniciais()
	# 6c1: a 1ª chegada à academia toca a cena. O marco entra no MESMO salvar() da mudança (fechar o jogo no meio não repete).
	var cena_id := gs._casa._cena_da_chegada()
	var chegou_centro: bool = gs._centro.ao_mudar_para(gs.local_id)  # 8a2: marco e fala da chegada ao centro (sem cena)
	if cena_id != "":
		gs._escola._gravar_marco(str(gs.escola_cfg.gym_arrival.milestone), {}, false)
		gs.cena_sala = cena_id
		gs._cena_sala_t = 0.0
		gs._sucessao._cancelar_toques(true)
		gs._calendario._checar_sala()
	gs._chave_melhor = ""
	gs.salvar()
	gs.local_mudou.emit(gs.local_id)
	if primeira:
		gs.permanente_mudou.emit()
	gs.escada_mudou.emit()
	gs.economia_mudou.emit()
	gs.atualizar_risco_hud()
	if escolha_arte_pendente():
		gs.escolha_arte_pedida.emit(escolha_arte_primeira())
	if gs.local_id == "gym":
		gs._academia_rearmada = true
		gs.disparar_gatilho("gym_arrival")  # Fase 6a: só a chegada pelo MUDAR (a carga e o NOVA CAMPANHA não passam aqui)
	if chegou_centro:
		gs.permanente_mudou.emit()  # a região CENTRO da árvore abriu (permanent.center_reached)
		gs.disparar_gatilho("center_arrival")  # 8a2: a fala do Osmar (1ª vez da linhagem: única; depois: as que se revezam)
	if cena_id != "":
		gs.cena_sala_pedida.emit(cena_id)  # a escolha da arte espera o fim da cena (cena_sala_terminou)
	return true


## Dinheiro que a LOJA não pode gastar: o preço da mudança, entre o cinturão e a mudança (0 nos outros casos).
func reserva_mudanca() -> float:
	var d := gs.academia.destino_mudanca(gs.local_id)
	if d.is_empty() or d.id == gs.local_id or not _requisito_cumprido(d):  # 8a2: só reserva com o requisito DO DESTINO cumprido
		return 0.0
	return float(d.move.cost)


## Estado de uma compra em dinheiro: "ok", "money" (falta dinheiro) ou "reserve" (deixaria menos que a reserva da mudança).
func loja_estado(custo: float) -> String:
	if not Economia.pode_pagar(gs.dinheiro, custo):
		return "money"
	if gs.dinheiro - custo < reserva_mudanca() * (1.0 - Economia.EPS):
		return "reserve"
	return "ok"


## 7b1: vitória contra `adversario_id` libera as artes com `unlock {type: first_win, opponent}` (a 1ª vez). Grava o marco
## `<arte>_unlocked` (sem salvar: quem chama salva no mesmo save da luta). Devolve os ids liberados agora.
func liberar_por_vitoria(adversario_id: String) -> Array:
	var novas: Array = []
	if gs.permanente.arts_unlocked.is_empty():
		return novas  # nunca chegou à academia: a 1ª chegada é que abre as artes (estado só de teste)
	for a in gs.academia.artes:
		if a.unlock.is_empty() or str(a.unlock.opponent) != adversario_id or a.id in gs.permanente.arts_unlocked:
			continue
		gs.permanente["arts_unlocked"].append(a.id)
		gs._escola._gravar_marco(str(a.id) + "_unlocked", {}, false)
		novas.append(a.id)
	return novas


## 7b1, ao carregar: quem já venceu o adversário da liberação (best_wins >= índice + 1, ou a carreira atual já passou dele)
## recebe a arte, sem tocar no resto. Devolve os ids acrescentados.
func liberar_ao_carregar() -> Array:
	var novas: Array = []
	if gs.permanente.arts_unlocked.is_empty():
		return novas
	for a in gs.academia.artes:
		if a.unlock.is_empty() or a.id in gs.permanente.arts_unlocked:
			continue
		var i: int = gs.lutas.indice_adversario(str(a.unlock.opponent))
		if i < 0:
			continue
		if int(gs.permanente.get("best_wins", 0)) >= i + 1 or gs.indice_escada >= i + 1:
			gs.permanente["arts_unlocked"].append(a.id)
			novas.append(a.id)
	return novas


## A fala do Osmar da arte liberada ainda não passou? (a única nunca se perde: volta a pedir ao carregar.)
func fala_de_liberacao_pendente(arte_id: String) -> bool:
	return arte_id in gs.permanente.get("arts_unlocked", []) and not gs.academia.arte(arte_id).get("unlock", {}).is_empty() 		and gs.dialogos.gatilho(arte_id + "_unlocked") != {} and not gs.escola.lines_seen.has("cl_" + arte_id)


## 7b2: vitória da escada `finish` conta para a meta da 2ª passiva? Só com arte, com a 1ª passiva e quando a luta acabou do jeito da 1ª
## (`passive_2.unlock.finish`: knockout | submission | spin_kick). Soma na linhagem (`permanent.passive_wins`). Sem salvar: quem chama
## salva no mesmo save da luta. Devolve {art, n, m, counted, unlocked_now, text}; {} se não contou nada (sem arte / 2ª passiva / outro fim).
func contar_vitoria_passiva(finish: String) -> Dictionary:
	var a := gs.academia.arte(gs.arte_id)
	if a.is_empty() or a.passive_2.is_empty() or gs.passiva_carreira != 1 or finish != str(a.passive_2.unlock.finish):
		return {}
	_garantir_campos_passiva()
	var vitorias: Dictionary = gs.permanente["passive_wins"]
	var n := int(vitorias.get(a.id, 0)) + 1
	vitorias[a.id] = n
	var m := int(a.passive_2.unlock.count)
	var novo := false
	if n >= m and not (a.id in gs.permanente["passives_unlocked"]):
		gs.permanente["passives_unlocked"].append(a.id)
		gs._escola._gravar_marco("passive2_%s_unlocked" % a.id, {}, false)
		novo = true
	var r := progresso_passiva(str(a.id))
	r["counted"] = true
	r["unlocked_now"] = novo
	r["text"] = gs.preencher(gs.texto_ui("passive2_unlocked_line"), {"nome": str(a.passive_2.name).to_upper()}) if novo else ""
	return r


## 7b2: meta da 2ª passiva de uma arte: {art, n (já limitado à meta), m, finish, finish_text, text ("2/3 K.O. DE EMBALO"), liberada, has}.
## `has` = false quando a arte não tem 2ª passiva.
func progresso_passiva(arte_id: String) -> Dictionary:
	var a := gs.academia.arte(arte_id)
	if a.is_empty() or a.passive_2.is_empty():
		return {"art": arte_id, "has": false, "n": 0, "m": 0, "finish": "", "finish_text": "", "text": "", "liberada": false}
	var m := int(a.passive_2.unlock.count)
	var n := mini(int(gs.permanente.get("passive_wins", {}).get(arte_id, 0)), m)
	var fim := str(a.passive_2.unlock.finish)
	var fim_txt := gs.texto_ui("passive_finish_" + fim, fim.to_upper())
	return {"art": arte_id, "has": true, "n": n, "m": m, "finish": fim, "finish_text": fim_txt,
		"text": gs.preencher(gs.texto_ui("art_card_passive_progress", "{n}/{m} {fim}"), {"n": n, "m": m, "fim": fim_txt}),
		"liberada": passiva_liberada(arte_id)}


## Estado só de teste (permanent montado à mão): garante os 3 campos da 7b2.
func _garantir_campos_passiva() -> void:
	for chave in ["passive_wins", "last_passive"]:
		if not (gs.permanente.get(chave, null) is Dictionary):
			gs.permanente[chave] = {}
	if not (gs.permanente.get("passives_unlocked", null) is Array):
		gs.permanente["passives_unlocked"] = []


func passiva_liberada(arte_id: String) -> bool:
	return arte_id in gs.permanente.get("passives_unlocked", [])


## Passiva marcada por padrão no cartão da arte: a última escolhida (se a 2ª ainda vale), senão a 1ª.
func passiva_padrao(arte_id: String) -> int:
	if int(gs.permanente.get("last_passive", {}).get(arte_id, 1)) == 2 and passiva_liberada(arte_id):
		return 2
	return 1


## A fala do Osmar da 2ª passiva ainda não passou? (a única nunca se perde: volta a pedir ao carregar.)
func fala_passiva2_pendente(arte_id: String) -> bool:
	return passiva_liberada(arte_id) and gs.dialogos.gatilho("passive2_%s_unlocked" % arte_id) != {} 		and not gs.escola.lines_seen.has("cl_passive2_" + arte_id)


## Artes liberadas para sempre (ids), na ordem do arquivo.
func artes_liberadas() -> Array:
	return gs.permanente.get("arts_unlocked", []).duplicate()


func nome_arte(id: String) -> String:
	return str(gs.academia.arte(id).get("name", ""))


## true quando a janela de escolha da arte deve estar aberta: artes liberadas, carreira viva e sem arte escolhida.
## Cobre a 1ª chegada, o início de toda carreira e reabrir o jogo sem ter escolhido. Enquanto vale, `acoes_bloqueadas()`.
func escolha_arte_pendente() -> bool:
	return gs.arte_id == "" and gs.fim.is_empty() and gs.sucessao == "none" and gs.cena_sala == "" and not gs.permanente.get("arts_unlocked", []).is_empty()


## true na escolha da 1ª chegada (nunca escolheu arte): subtítulo `art_sub_first`.
func escolha_arte_primeira() -> bool:
	return str(gs.permanente.get("last_art", "")) == ""


## Cartões da janela de escolha: [{id, name, tagline, rule_text, fight_text, icon, apparatus, apparatus_name, last, last_text}].
## `last` = a arte da carreira anterior (já vem marcada). Textos com os números já preenchidos (com o nó ESTILO, se houver).
func artes_para_escolha() -> Array:
	var r: Array = []
	var ultima := str(gs.permanente.get("last_art", ""))
	for a in gs.academia.artes:
		if not (a.id in gs.permanente.get("arts_unlocked", [])):
			continue
		var eh_ultima: bool = a.id == ultima
		r.append({
			"id": a.id, "name": a.name, "tagline": a.tagline, "icon": a.icon,
			"rule_text": gs.texto_regra_arte(a.id), "fight_text": gs.texto_traco_luta(a.id),
			"apparatus": a.apparatus, "apparatus_name": gs.nome_curto_aparelho(a.apparatus).to_upper() if a.apparatus != "" else "",
			"last": eh_ultima,
			"last_text": gs.preencher(gs.texto_ui("art_last", "ÚLTIMA: {nome}"), {"nome": str(a.name).to_upper()}) if eh_ultima else "",
			"passives": passivas_do_cartao(str(a.id)), "passive_default": passiva_padrao(str(a.id)),
		})
	return r


## 7b2: as opções de passiva do cartão da arte: [{n (1|2), name, fight_text, icon, locked, locked_text, selected, progress}].
## Arte sem `passive_2` devolve só a 1ª (como antes). A 2ª vem travada até bater a meta (`progress.text` = "2/3 K.O. DE EMBALO").
func passivas_do_cartao(arte_id: String) -> Array:
	var a := gs.academia.arte(arte_id)
	if a.is_empty():
		return []
	var padrao := passiva_padrao(arte_id)
	var r: Array = [{"n": 1, "name": gs.texto_ui("passive_%s_name" % arte_id, str(a.name)), "fight_text": gs.texto_passiva(arte_id),
		"icon": "", "locked": false, "selected": padrao == 1, "progress": {}, "locked_text": ""}]
	if not a.passive_2.is_empty():
		var prog := progresso_passiva(arte_id)
		r.append({"n": 2, "name": str(a.passive_2.name), "fight_text": str(a.passive_2.fight_text), "icon": str(a.passive_2.icon),
			"locked": not prog.liberada, "selected": padrao == 2, "progress": prog,
			"locked_text": gs.texto_ui("art_card_passive_locked", "TRAVADO") if not prog.liberada else ""})
	return r


## Escolhe a arte da carreira (1 clique). Vale a carreira inteira: não existe função de troca. Só com a escolha pendente
## e uma arte liberada. Salva na hora; zera `art_seconds`; guarda `last_art`.
func escolher_arte(id: String, passiva: int = 0) -> bool:
	if not escolha_arte_pendente() or gs.academia.arte(id).is_empty() or not (id in gs.permanente.arts_unlocked):
		return false
	# 7b2: `passiva` 0 = a marcada por padrão (a última escolhida, se vale); 1 ou 2 = escolha. A 2ª só com a meta batida.
	var qual := passiva_padrao(id) if passiva == 0 else passiva
	if qual != 1 and qual != 2:
		return false
	if qual == 2 and not (passiva_liberada(id) and not gs.academia.arte(id).passive_2.is_empty()):
		return false
	gs.arte_id = id
	gs.passiva_carreira = qual
	_garantir_campos_passiva()
	gs.permanente["last_passive"][id] = qual
	gs.arte_segundos = 0.0
	gs._arte_comentada = false
	gs.permanente["last_art"] = id
	gs._arvore._recalcular_bonus()  # Fase 5.4: nós da arte passam a valer
	_atualizar_passiva()
	gs._chave_melhor = ""
	gs.salvar()
	gs.arte_mudou.emit(gs.arte_id)
	gs.permanente_mudou.emit()
	gs.economia_mudou.emit()
	gs.atualizar_risco_hud()
	return true


## Soma dos nós ESTILO comprados da arte (0 ou 0,5): o efeito da regra dela fica x(1 + estilo).
func estilo_arte(id: String) -> float:
	return float(gs._estilo.get(id, 0.0))


## Bônus do Boxe no clique MANUAL (0,50; com o nó 0,75). 0 sem arte ou com outra arte.
func bonus_arte_clique() -> float:
	var a := gs.academia.arte(gs.arte_id)
	if a.is_empty() or a.rule.type != "manual_click_bonus":
		return 0.0
	return float(a.rule.value) * (1.0 + estilo_arte(gs.arte_id))


## Crítico do clique MANUAL: {chance, mult} efetivos. Sem arte (ou Boxe/Jiu-jitsu) = o de sempre (10%, x3). Muay Thai
## (`click_crit_bonus`): chance + chance_add e mult + mult_add x (1 + estilo). A tela lê daqui; o auto-soco nunca usa o bônus.
func bonus_arte_critico() -> Dictionary:
	var chance: float = gs.dados.crit_chance
	var mult: float = gs.dados.crit_multiplier
	var a := gs.academia.arte(gs.arte_id)
	if not a.is_empty() and a.rule.type == "click_crit_bonus":
		chance = minf(1.0, chance + float(a.rule.chance_add))
		mult += float(a.rule.mult_add) * (1.0 + estilo_arte(gs.arte_id))
	return {"chance": chance, "mult": mult}


## Bônus do Jiu-jitsu na equipe: (1 + estilo) x min(teto, começo + por_minuto x minutos de arte). 0 sem a arte.
func bonus_arte_equipe() -> float:
	var a := gs.academia.arte(gs.arte_id)
	if a.is_empty() or a.rule.type != "crew_time_bonus":
		return 0.0
	var r: Dictionary = a.rule
	return (1.0 + estilo_arte(gs.arte_id)) * minf(float(r.cap), float(r.start) + float(r.per_minute) * gs.arte_segundos / 60.0)


## true quando o bônus da equipe chegou no teto (a UI mostra "(MÁX.)").
func arte_no_teto() -> bool:
	var a := gs.academia.arte(gs.arte_id)
	if a.is_empty() or a.rule.type != "crew_time_bonus":
		return false
	var r: Dictionary = a.rule
	return float(r.start) + float(r.per_minute) * gs.arte_segundos / 60.0 >= float(r.cap) - 1.0e-9


# A passiva de luta da arte vai para o motor (luta e prévia usam a mesma função). Sem arte = passiva vazia.
# `extra` = nós art_fight_bonus (Contragolpe: K.O. +50%; Base firme: pegada +50%), só da arte jogada.
func _atualizar_passiva() -> void:
	var arte := gs.academia.arte(gs.arte_id)
	var chave := "passive_2" if gs.passiva_carreira == 2 and not arte.get("passive_2", {}).is_empty() else "passive"
	gs.motor.passiva = arte.get(chave, {}).duplicate(true)
	gs.motor.extra_passiva = gs._arvore._b("art_fight_bonus") if not gs.motor.passiva.is_empty() else 0.0


## Tática do jogador já com os multiplicadores da passiva (cópia). Útil para testes e para a UI mostrar números.
func tatica_efetiva(tatica_id: String = "") -> Dictionary:
	return gs.motor.aplicar_passiva(gs.lutas.tatica(gs.tatica) if tatica_id == "" else gs.lutas.tatica(tatica_id))
