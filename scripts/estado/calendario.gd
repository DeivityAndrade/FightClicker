extends RefCounted
## Fase 5.3: relógio da campanha, dias, data da luta e avisos.
## Trabalha nas variáveis do GameState (`gs`); as funções públicas continuam em GameState como repasses.

var gs: EstadoJogo  # o GameState (autoload)


func _init(g: EstadoJogo) -> void:
	gs = g


## A ÚNICA condição de tick: relógio da campanha, equipe, Metrônomo, assistido, clique, luva dourada e Jiu-jitsu
## só andam com ela. Perder foco ou minimizar NÃO desliga; janela, luta, escolha da arte e dia da luta sim.
func sala_ativa() -> bool:
	return gs.fim.is_empty() and gs.sucessao == "none" and gs.cena_sala == "" and gs.luta.is_empty() and not gs.escolha_arte_pendente() and not gs.modal_aberto and not no_dia_da_luta()


func calendario_ligado() -> bool:
	return float(gs.lutas.calendario.get("seconds_per_day", 0.0)) > 0.0


func _segundos_por_dia() -> float:
	return float(gs.lutas.calendario.get("seconds_per_day", 0.0))


## Dia da campanha (começa em 1). Sem calendário: sempre 1.
func dia_campanha() -> int:
	if not calendario_ligado():
		return 1
	return 1 + int(floor((gs.segundos_campanha + 1.0e-6) / _segundos_por_dia()))


## Depois do último adversário (Kid): "Campanha completa", sem data nem relógio.
func campanha_completa() -> bool:
	return gs.escada_completa()


## Dias que faltam para a próxima luta (0 = é hoje); -1 sem calendário ou sem próxima luta.
func dias_para_luta() -> int:
	if not calendario_ligado() or gs.fight_day <= 0 or campanha_completa():
		return -1
	return maxi(0, gs.fight_day - dia_campanha())


## true quando o relógio chegou na data da próxima luta (e o adversário luta neste local).
## Se o adversário pede outra sala (Tonhão com o jogador na garagem), o relógio segue sem travar.
func no_dia_da_luta() -> bool:
	if not calendario_ligado() or gs.fight_day <= 0 or gs.estado_escada() != "fight":
		return false
	return gs.segundos_campanha >= _alvo_relogio() - 1.0e-6


func _alvo_relogio() -> float:
	return float(gs.fight_day - 1) * _segundos_por_dia()


func _prep_do_indice(i: int) -> int:
	if i < 0 or i >= gs.lutas.adversarios.size():
		return 14
	return int(gs.lutas.adversarios[i].get("prep_days", 14)) + int(gs._b("prep_days_bonus"))


## Data da próxima luta contada a partir do dia de hoje (-1 se a escada acabou).
func _data_da_proxima_luta() -> int:
	if gs.escada_completa():
		return -1
	return dia_campanha() + _prep_do_indice(gs.indice_escada)


## Avança o relógio com a regra única. Devolve o tempo de sala usado (0 com a sala parada).
func _avancar_relogio(delta: float) -> float:
	if not sala_ativa():
		return 0.0
	if not calendario_ligado() or campanha_completa():
		return delta
	if gs.estado_escada() == "move":
		return delta  # B3: a próxima luta é em outro local; o relógio não conta até chegar lá
	var dt := delta
	if gs.fight_day > 0 and gs.estado_escada() == "fight":
		var restante := _alvo_relogio() - gs.segundos_campanha
		if restante <= delta:
			dt = maxf(restante, 0.0)
			gs.segundos_campanha = _alvo_relogio()  # trava exatamente no dia
			return dt
	gs.segundos_campanha += dt
	return dt


# Emite dia, avisos e chegada do dia (cada aviso uma vez por data).
func _verificar_calendario() -> void:
	if not calendario_ligado():
		return
	var dia := dia_campanha()
	if dia != gs._dia_anterior:
		gs._dia_anterior = dia
		gs.dia_mudou.emit(dia)
	if gs.fight_day != gs._aviso_data_chave:
		gs._aviso_data_chave = gs.fight_day
		gs._aviso_feito = {"warn": false, "sound": false}
		gs._dia_chegou_emitido = false
	var dias := dias_para_luta()
	if dias > 0:
		var w := int(gs.lutas.calendario.warn_days)
		var s := int(gs.lutas.calendario.warn_sound_days)
		# B2: no máximo um aviso por verificação; o limiar mais próximo alcançado marca os anteriores
		if s > 0 and dias <= s and not gs._aviso_feito.sound:
			gs._aviso_feito.sound = true
			gs._aviso_feito.warn = true
			gs.aviso_data.emit(dias)
		elif w > 0 and dias <= w and not gs._aviso_feito.warn:
			gs._aviso_feito.warn = true
			gs.aviso_data.emit(dias)
	elif dias == 0 and gs.fight_day > 0 and not gs._aviso_feito.sound:
		# B2: tick grande saltou direto para o dia: avisa uma vez com o último limiar (1 dia)
		var s2 := int(gs.lutas.calendario.warn_sound_days)
		gs._aviso_feito.sound = true
		gs._aviso_feito.warn = true
		if s2 > 0:
			gs.aviso_data.emit(s2)
	if no_dia_da_luta():
		if not gs._dia_chegou_emitido:
			gs._dia_chegou_emitido = true
			gs.dia_da_luta_chegou.emit()
	else:
		gs._dia_chegou_emitido = false


func _checar_sala() -> void:
	var a := sala_ativa()
	if a != gs._sala_antes:
		gs._sala_antes = a
		if not a:
			gs._escola._fechar_para_janela()  # Fase 6a: nunca fica balão (nem gesto da sala) por baixo de janela ou luta
			gs._casa._interromper_saida()  # 6c1: janela, luta, tela de fim ou dia da luta terminam a saída do John na hora
		gs.sala_ativa_mudou.emit(a)
