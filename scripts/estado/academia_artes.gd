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
	var d := gs.academia.destino_mudanca()
	if d.is_empty() or d.id == gs.local_id:
		return {}
	var custo := float(d.move.cost)
	return {
		"id": d.move.id, "location": d.id, "cost": custo, "name": d.name, "mult": d.training_mult,
		"button": d.move_button if d.move_button != "" else gs.texto_ui("move_button", "MUDAR"),
		"description": d.move_description,
		"title": gs.texto_ui("move_title"), "price_text": gs.preencher(gs.texto_ui("move_price", "${n}"), {"n": NumberFormat.fmt(custo)}),
		"effect_text": gs.preencher(gs.texto_ui("move_effect"), {"mult": NumberFormat.fmt(float(d.training_mult))}),
		"keeps_text": gs.texto_ui("move_keeps"), "per_career_text": gs.texto_ui("move_per_career"),
		"state": estado_mudanca(),
	}


## "none" (nada a comprar), "locked" (falta o cinturão: o botão não existe), "missing" (cinturão sem o dinheiro: apagado) ou "ready".
func estado_mudanca() -> String:
	var d := gs.academia.destino_mudanca()
	if d.is_empty() or d.id == gs.local_id:
		return "none"
	if not gs.cinturao:
		return "locked"
	return "ready" if Economia.pode_pagar(gs.dinheiro, float(d.move.cost)) else "missing"


func pode_mudar() -> bool:
	return estado_mudanca() == "ready" and not gs.acoes_bloqueadas()


## MUDAR: desconta o preço uma vez, vai para o local, e na 1ª vez libera todas as artes e pede a escolha. Salva na hora.
## Mudar nunca tira nada (geradores, melhorias, aparelhos, luva, Metrônomo, Treino, atributos ficam).
func mudar() -> bool:
	if not pode_mudar():
		return false
	var d := gs.academia.destino_mudanca()
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
	if cena_id != "":
		gs.cena_sala_pedida.emit(cena_id)  # a escolha da arte espera o fim da cena (cena_sala_terminou)
	return true


## Dinheiro que a LOJA não pode gastar: o preço da mudança, entre o cinturão e a mudança (0 nos outros casos).
func reserva_mudanca() -> float:
	if not gs.cinturao:
		return 0.0
	var d := gs.academia.destino_mudanca()
	if d.is_empty() or d.id == gs.local_id:
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
		})
	return r


## Escolhe a arte da carreira (1 clique). Vale a carreira inteira: não existe função de troca. Só com a escolha pendente
## e uma arte liberada. Salva na hora; zera `art_seconds`; guarda `last_art`.
func escolher_arte(id: String) -> bool:
	if not escolha_arte_pendente() or gs.academia.arte(id).is_empty() or not (id in gs.permanente.arts_unlocked):
		return false
	gs.arte_id = id
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
	gs.motor.passiva = gs.academia.arte(gs.arte_id).get("passive", {}).duplicate(true)
	gs.motor.extra_passiva = gs._arvore._b("art_fight_bonus") if not gs.motor.passiva.is_empty() else 0.0


## Tática do jogador já com os multiplicadores da passiva (cópia). Útil para testes e para a UI mostrar números.
func tatica_efetiva(tatica_id: String = "") -> Dictionary:
	return gs.motor.aplicar_passiva(gs.lutas.tatica(gs.tatica) if tatica_id == "" else gs.lutas.tatica(tatica_id))
