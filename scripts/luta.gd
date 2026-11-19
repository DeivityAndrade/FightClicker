class_name Luta
extends RefCounted
## Simulação determinística da luta (design fase3 §4, §6, §7). Funções puras, sem estado de jogo.
## É a porta, linha a linha, de Regras.lutar / chance / passa / motivo de tools/sim/fase3_sim.py.
## Atributos de lutador são Arrays [forca, agilidade, resistencia] (crus, os da garagem).
## Ordem dos sorteios por ataque (fixa): r_esq, r_crit, r_var (3 por ataque, mesmo que não usados);
## com passiva de arte, r_arte vem em quarto (4 por ataque).

const ATRIBUTOS: Array[String] = ["strength", "agility", "endurance"]
# Ordem de desempate do motivo: Resistência, Força, Agilidade (índices em ATRIBUTOS).
const ORDEM_MOTIVO: Array[int] = [2, 0, 1]
const NEUTRA := {"damage_mult": 1.0, "taken_mult": 1.0, "pierce": 0.0, "dodge_mult": 1.0, "dodge_bonus": 0.0,
	"counter_mult": 0.0, "crit_guard": 0.0, "block": false}

var c: Dictionary  # combate
var dados: FightData
# Fase 7a1: passiva de luta da arte do jogador (data/arts.json -> passive, já validada no GymData).
# Vazia = sem arte: a luta usa o laço de sempre (3 sorteios por ataque). Com passiva: _rodar_arte (4 sorteios).
# Luta, prévia, risco do HUD, robô de teste e motivo usam a mesma função, então a prévia continua honesta.
var passiva := {}
# Soma dos nós `art_fight_bonus` da arte (Contragolpe / Base firme): reforça a passiva.
var extra_passiva := 0.0


func _init(p_dados: FightData) -> void:
	dados = p_dados
	c = p_dados.combate


# --- Números de cada lutador ---

## Atributos efetivos: cru + general_share x total.
func efetivos(x: Array) -> Array:
	var g: float = c.general_share * (float(x[0]) + float(x[1]) + float(x[2]))
	return [x[0] + g, x[1] + g, x[2] + g]


func vida_max(ef: Array) -> float:
	return c.life_base + c.life_per_endurance * ef[2]


## Números de um golpe de `at` em `df` (efetivos): [dano, critico, esquiva, reducao].
func golpe(at: Array, df: Array, ta: Dictionary, td: Dictionary) -> Array:
	var bruto: float = c.damage_base + c.damage_per_strength * at[0]
	var den: float = df[2] + at[0]
	var red: float = c.reduction_max * df[2] / den if den > 0.0 else 0.0
	red *= 1.0 - ta.pierce
	var dano: float = bruto * (1.0 - red) * ta.damage_mult * td.taken_mult
	var soma: float = at[1] + df[1]
	var v: float = (at[1] - df[1]) / soma if soma > 0.0 else 0.0  # vantagem de agilidade, -1..1
	var crit: float = c.crit_base + c.crit_gain * maxf(0.0, v)
	var esq: float = minf(c.dodge_cap, (c.dodge_base + c.dodge_gain * maxf(0.0, -v)) * td.dodge_mult + td.dodge_bonus)
	return [dano, crit, esq, red]


## Tática completa (campos que faltam recebem os neutros). Id desconhecido = neutra.
func _tatica(id: String) -> Dictionary:
	var t := dados.tatica(id)
	if t.is_empty():
		t = NEUTRA
	return aplicar_passiva(t)


## Tática do jogador com os multiplicadores de dano da passiva da arte (cópia; a original não muda).
func aplicar_passiva(t: Dictionary) -> Dictionary:
	if passiva.is_empty():
		return t
	var dm := float(passiva.damage_mult)
	var tm := float(passiva.taken_mult)
	if dm == 1.0 and tm == 1.0:
		return t
	var r := t.duplicate()
	r["damage_mult"] = float(t.damage_mult) * dm
	r["taken_mult"] = float(t.taken_mult) * tm
	return r


func _clamp_fator(x: float, minimo: float, maximo: float) -> float:
	return minf(maxf(x, minimo), maximo)


## Números da passiva que a prévia mostra e a luta usa (determinístico). {} sem arte.
## Boxe: fator de agilidade, K.O. máximo por golpe, quando cansa. Jiu-jitsu: quando a pegada enche e chance de finalizar.
func estado_passiva(jog: Array, adv: Array, tatica_id: String) -> Dictionary:
	if passiva.is_empty():
		return {}
	var P := passiva
	var ej := efetivos(jog)
	var ea := efetivos(adv)
	var tp: Dictionary = P.tactics.get(tatica_id, {})
	if P.type == "fast_hands":
		var tem: bool = ej[1] + ea[1] > 0.0
		var agi_raw: float = 2.0 * ej[1] / (ej[1] + ea[1]) if tem else 1.0
		var fa := _clamp_fator(agi_raw, P.ko_agility_min, P.ko_agility_max) if tem else 1.0
		var pmax := minf(P.ko_cap, P.streak_max * P.ko_per_streak * fa * float(tp.get("ko_mult", 1.0)) * (1.0 + extra_passiva))
		var iv: float = float(c.attack_interval) * float(P.interval_mult)
		if float(P.speed_agility_max) > 1.0:
			iv = iv / _clamp_fator(agi_raw, P.speed_agility_min, P.speed_agility_max)
		return {"kind": "fast_hands", "agi_raw": agi_raw, "agi_factor": fa, "ko_max": pmax, "ko_per_streak": pmax / P.streak_max,
			"streak_max": int(P.streak_max), "interval": iv,
			"tired_at": (P.tired_from_round - 1.0) * c.round_length, "tired_round": int(P.tired_from_round),
			# `tires`: nesta tática o lutador cansa no 3º round (Defensivo não cansa: o intervalo fica em 1,80 s)
			"tires": float(tp.get("tired_interval_mult", P.tired_interval_mult)) > 1.0 + 1.0e-9,
			"opp_counter": float(tp.get("opponent_counter", 0.0))}
	var tem_r: bool = ej[2] + ea[0] > 0.0
	var fr := _clamp_fator(2.0 * ej[2] / (ej[2] + ea[0]), P.grip_endurance_min, P.grip_endurance_max) if tem_r else 1.0
	var taxa := minf(P.grip_rate_max, P.grip_per_round * fr * float(tp.get("grip_mult", 1.0)) * (1.0 + extra_passiva))
	var t_cheia: float = c.round_length / taxa
	var tem_f: bool = ej[0] + ea[0] > 0.0
	var ff := _clamp_fator(2.0 * ej[0] / (ej[0] + ea[0]), P.sub_strength_min, P.sub_strength_max) if tem_f else 1.0
	return {"kind": "submission", "grip_rate": taxa, "grip_full_at": t_cheia,
		"grip_round": int(floor(t_cheia / c.round_length + 1e-9)) + 1,
		"grip_in_time": t_cheia <= c.time_limit + 1e-9,
		"end_factor": fr, "str_factor": ff, "sub_chance": minf(P.sub_cap, P.sub_base * ff)}


## Prepara tudo o que é fixo na luta (calculado uma vez, §4.1).
func preparar(jog: Array, adv: Array, tatica_id: String) -> Dictionary:
	var ef_j := efetivos(jog)
	var ef_a := efetivos(adv)
	var tj := _tatica(tatica_id)
	var ta := NEUTRA
	var est := {}
	var tp := {}
	if not passiva.is_empty():
		est = estado_passiva(jog, adv, tatica_id)
		tp = passiva.tactics.get(tatica_id, {})
		if passiva.type == "fast_hands":  # Agressivo: ele contragolpeia quando esquiva (o `counter_mult` da tática DELE)
			ta = NEUTRA.duplicate()
			ta["counter_mult"] = float(tp.get("opponent_counter", 0.0))
	return {
		"tac": [tj, ta],
		"vmax": [vida_max(ef_j), vida_max(ef_a)],
		"num": [golpe(ef_j, ef_a, tj, ta), golpe(ef_a, ef_j, ta, tj)],
		# quem tem mais Agilidade efetiva ataca primeiro; empate: o jogador
		"primeiro": 0 if ef_j[1] >= ef_a[1] else 1,
		"est": est, "tp": tp,
	}


# --- A luta ---

## Luta completa com semente. registro=true devolve também a lista de eventos.
func lutar(jog: Array, adv: Array, tatica_id: String, semente: int, registro: bool = false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return rodar(preparar(jog, adv, tatica_id), rng, PackedFloat64Array(), registro)


## Luta com sorteios dados (testes contra o simulador Python): cada ataque consome 3 números.
func lutar_com_sorteios(jog: Array, adv: Array, tatica_id: String, sorteios: PackedFloat64Array,
		registro: bool = false) -> Dictionary:
	return rodar(preparar(jog, adv, tatica_id), null, sorteios, registro)


## Núcleo. `rng` null = usa a lista `sorteios`.
func rodar(cen: Dictionary, rng: RandomNumberGenerator, sorteios: PackedFloat64Array, registro: bool) -> Dictionary:
	if not passiva.is_empty():
		return _rodar_arte(cen, rng, sorteios, registro)
	var limite: float = c.time_limit
	var intervalo: float = c.attack_interval
	var atraso: float = c.counter_delay
	var spread: float = c.damage_spread
	var cm: float = c.crit_multiplier
	var tac: Array = cen.tac
	var vmax: Array = cen.vmax
	var num: Array = cen.num
	var vida := [vmax[0], vmax[1]]
	var prox := [0.0, 0.0]
	prox[cen.primeiro] = c.first_attack
	prox[1 - cen.primeiro] = c.first_attack + intervalo / 2.0
	var contra_t: Array[float] = []
	var contra_q: Array[int] = []
	var cont := {
		"attacks": [0, 0], "counters": [0, 0], "hits": [0, 0], "dodges": [0, 0], "crits": [0, 0],
		"damage": [0.0, 0.0],
	}
	var eventos: Array = []
	var usados := 0
	var ko := false
	var t_ko := -1.0
	var vencedor_ko := -1

	while true:
		# Próximo evento: menor tempo; no empate, contra-golpe antes de ataque normal; depois jogador.
		var t: float = prox[0]
		var tipo := 1
		var quem := 0
		if prox[1] < t:
			t = prox[1]
			quem = 1
		var idx_contra := -1
		for i in contra_t.size():
			var tc := contra_t[i]
			var qc := contra_q[i]
			if tc < t or (tc == t and (tipo == 1 or qc < quem)):
				t = tc
				tipo = 0
				quem = qc
				idx_contra = i
		var eh_contra := tipo == 0
		if t > limite + 1e-9:
			break
		if eh_contra:
			contra_t.remove_at(idx_contra)
			contra_q.remove_at(idx_contra)
		else:
			prox[quem] += intervalo
		var alvo := 1 - quem
		var n: Array = num[quem]
		var r_esq: float
		var r_crit: float
		var r_var: float
		if rng != null:
			r_esq = rng.randf()
			r_crit = rng.randf()
			r_var = rng.randf()
		else:
			r_esq = sorteios[usados]
			r_crit = sorteios[usados + 1]
			r_var = sorteios[usados + 2]
			usados += 3
		cont.attacks[quem] += 1
		if eh_contra:
			cont.counters[quem] += 1
		if not eh_contra and r_esq < n[2]:
			cont.dodges[alvo] += 1
			if tac[alvo].counter_mult > 0.0 and t + atraso <= limite + 1e-9:
				contra_t.append(t + atraso)
				contra_q.append(alvo)
			if registro:
				eventos.append({"t": t, "who": quem, "type": "dodge", "counter": false, "damage": 0.0,
					"life_after": vida[alvo]})
			continue
		var e_crit: bool = r_crit < n[1]
		var d: float = n[0]
		if e_crit:
			d *= 1.0 + (cm - 1.0) * (1.0 - tac[alvo].crit_guard)
		if eh_contra:
			d *= tac[quem].counter_mult
		d *= 1.0 + spread * (2.0 * r_var - 1.0)
		vida[alvo] -= d
		cont.hits[quem] += 1
		cont.damage[quem] += d
		if e_crit:
			cont.crits[quem] += 1
		if registro:
			eventos.append({"t": t, "who": quem, "type": "crit" if e_crit else "hit", "counter": eh_contra,
				"damage": d, "life_after": maxf(0.0, vida[alvo])})
		if vida[alvo] <= 1e-9 * vmax[alvo]:
			ko = true
			t_ko = t
			vencedor_ko = quem
			break

	var p0: float = maxf(0.0, vida[0]) / vmax[0]
	var p1: float = maxf(0.0, vida[1]) / vmax[1]
	var venceu: bool
	var t_fim: float
	var round_n := 0
	if ko:
		venceu = vencedor_ko == 0
		t_fim = maxf(t_ko, c.min_ko_time)  # K.O. cedo: o caído fica grogue até min_ko_time
		round_n = int(floor(t_ko / c.round_length)) + 1
	else:
		venceu = p0 > p1  # empate exato: vence o adversário
		t_fim = limite
	var res := {
		"win": venceu, "ko": ko, "t_ko": t_ko, "t_end": t_fim, "round": round_n,
		"pct_player": p0, "pct_opponent": p1,
		"counts": {"player": _contagem(cont, 0), "opponent": _contagem(cont, 1)},
		"life_max": vmax.duplicate(), "draws_used": usados,
	}
	if registro:
		res["events"] = eventos
	return res


## Laço da luta com passiva de arte (porta de RegrasArte._lutar_arte, tools/sim/fase7a1_sim.py). 4 sorteios por ataque,
## de qualquer lado: r_esq, r_crit, r_var, r_arte (r_arte só vale no acerto do jogador: K.O. ou finalização).
## Resultado = o de sempre + finish ("damage"|"knockout"|"submission"|"points"), streak_peak, attempts,
## opp_counter_damage, grip_full_at (-1 sem JJ), tired_at (-1 sem Boxe). Eventos ganham streak, grip, tired, finish.
func _rodar_arte(cen: Dictionary, rng: RandomNumberGenerator, sorteios: PackedFloat64Array, registro: bool) -> Dictionary:
	var P := passiva
	var est: Dictionary = cen.est
	var tp: Dictionary = cen.tp
	var box: bool = P.type == "fast_hands"
	var frente: bool = float(P.need_ahead) >= 0.5
	var limite: float = c.time_limit
	var base: float = c.attack_interval
	var atraso: float = c.counter_delay
	var spread: float = c.damage_spread
	var cm: float = c.crit_multiplier
	var tac: Array = cen.tac
	var vmax: Array = cen.vmax
	var num: Array = cen.num
	var vida := [vmax[0], vmax[1]]
	var iv_j: float = base * float(P.interval_mult)
	if box and float(P.speed_agility_max) > 1.0:  # Mão rápida: mais AGILIDADE, socos mais rápidos (rounds 1-2)
		iv_j = iv_j / _clamp_fator(est.agi_raw, P.speed_agility_min, P.speed_agility_max)
	var iv_cans := 0.0
	var t_cansa := -1.0
	var ko_passo := 0.0
	var embalo_max := 0
	var por_acerto := 0
	var por_contra := 0
	var ko_vida := 0.0
	var t_cheia := -1.0
	var p_fin := 0.0
	var sub_vida := 1.0
	if box:
		iv_cans = base * float(tp.get("tired_interval_mult", P.tired_interval_mult))
		t_cansa = est.tired_at
		ko_passo = est.ko_per_streak
		embalo_max = int(P.streak_max)
		por_acerto = int(P.streak_per_hit)
		por_contra = int(tp.get("streak_per_counter", P.streak_per_hit))
		ko_vida = P.ko_life_max
	else:
		t_cheia = est.grip_full_at
		p_fin = est.sub_chance
		sub_vida = P.sub_life_max
	var prox := [0.0, 0.0]
	prox[cen.primeiro] = c.first_attack
	prox[1 - cen.primeiro] = c.first_attack + base / 2.0
	var contra_t: Array[float] = []
	var contra_q: Array[int] = []
	var cont := {
		"attacks": [0, 0], "counters": [0, 0], "hits": [0, 0], "dodges": [0, 0], "crits": [0, 0],
		"damage": [0.0, 0.0],
	}
	var dano_contra_dele := 0.0
	var eventos: Array = []
	var usados := 0
	var embalo := 0
	var embalo_pico := 0
	var tentativas := 0
	var finish := ""
	var visto_cansaco := false  # já passou do `tired_at`?
	var vantagem_no_cansaco := false  # ao chegar ao cansaço, o jogador não estava atrás (vida %)?
	var t_ko := -1.0
	var vencedor := -1

	while true:
		# Próximo evento: igual ao laço de sempre (menor tempo; contra-golpe antes; jogador antes)
		var t: float = prox[0]
		var tipo := 1
		var quem := 0
		if prox[1] < t:
			t = prox[1]
			quem = 1
		var idx_contra := -1
		for i in contra_t.size():
			var tc := contra_t[i]
			var qc := contra_q[i]
			if tc < t or (tc == t and (tipo == 1 or qc < quem)):
				t = tc
				tipo = 0
				quem = qc
				idx_contra = i
		var eh_contra := tipo == 0
		if t > limite + 1e-9:
			break
		var passou_cansaco: bool = box and t >= t_cansa - 1e-9  # a partir daqui vale o intervalo `iv_cans`
		if passou_cansaco and not visto_cansaco:
			visto_cansaco = true
			vantagem_no_cansaco = vida[0] * vmax[1] >= vida[1] * vmax[0]
		var cansado: bool = passou_cansaco and bool(est.tires)  # flag para a tela (só cansa quem tem `tires`)
		if eh_contra:
			contra_t.remove_at(idx_contra)
			contra_q.remove_at(idx_contra)
		elif quem == 0:
			prox[0] += iv_cans if passou_cansaco else iv_j
		else:
			prox[1] += base
		var alvo := 1 - quem
		var n: Array = num[quem]
		var r_esq: float
		var r_crit: float
		var r_var: float
		var r_arte: float
		if rng != null:
			r_esq = rng.randf()
			r_crit = rng.randf()
			r_var = rng.randf()
			r_arte = rng.randf()
		else:
			r_esq = sorteios[usados]
			r_crit = sorteios[usados + 1]
			r_var = sorteios[usados + 2]
			r_arte = sorteios[usados + 3]
			usados += 4
		cont.attacks[quem] += 1
		if eh_contra:
			cont.counters[quem] += 1
		if not eh_contra and r_esq < n[2]:
			cont.dodges[alvo] += 1
			if box and quem == 0:
				embalo = 0
			if tac[alvo].counter_mult > 0.0 and t + atraso <= limite + 1e-9:
				contra_t.append(t + atraso)
				contra_q.append(alvo)
			if registro:
				eventos.append({"t": t, "who": quem, "type": "dodge", "counter": false, "damage": 0.0,
					"life_after": vida[alvo], "streak": embalo, "grip": _pegada(t, t_cheia), "tired": cansado, "finish": ""})
			continue
		var e_crit: bool = r_crit < n[1]
		var d: float = n[0]
		if e_crit:
			d *= 1.0 + (cm - 1.0) * (1.0 - tac[alvo].crit_guard)
		if eh_contra:
			d *= tac[quem].counter_mult
			if quem == 1:
				dano_contra_dele += d * (1.0 + spread * (2.0 * r_var - 1.0))
		d *= 1.0 + spread * (2.0 * r_var - 1.0)
		vida[alvo] -= d
		cont.hits[quem] += 1
		cont.damage[quem] += d
		if e_crit:
			cont.crits[quem] += 1
		var fim := ""  # "damage" | "knockout" | "submission"
		if vida[alvo] <= 1e-9 * vmax[alvo]:
			fim = "damage"
		elif quem == 0:
			var portao: bool = not frente or vida[1] * vmax[0] <= vida[0] * vmax[1]
			if box:
				embalo = mini(embalo_max, embalo + (por_contra if eh_contra else por_acerto))
				embalo_pico = maxi(embalo_pico, embalo)
				if vida[1] <= ko_vida * vmax[1] and portao:
					tentativas += 1
					if r_arte < embalo * ko_passo:
						fim = "knockout"
			elif t >= t_cheia - 1e-9 and vida[1] <= sub_vida * vmax[1] and portao:
				tentativas += 1
				if r_arte < p_fin:
					fim = "submission"
		if registro:
			eventos.append({"t": t, "who": quem, "type": "crit" if e_crit else "hit", "counter": eh_contra,
				"damage": d, "life_after": maxf(0.0, vida[alvo]), "streak": embalo, "grip": _pegada(t, t_cheia),
				"tired": cansado, "finish": fim if fim != "damage" else ""})
		if fim != "":
			finish = fim
			t_ko = t
			vencedor = quem
			break

	var p0: float = maxf(0.0, vida[0]) / vmax[0]
	var p1: float = maxf(0.0, vida[1]) / vmax[1]
	var ko := finish != ""
	var venceu: bool
	var t_fim: float
	var round_n := 0
	if ko:
		venceu = vencedor == 0
		t_fim = maxf(t_ko, c.min_ko_time)
		round_n = int(floor(t_ko / c.round_length)) + 1
	else:
		venceu = p0 > p1  # empate exato: vence o adversário
		t_fim = limite
		finish = "points"
	var res := {
		"win": venceu, "ko": ko, "t_ko": t_ko, "t_end": t_fim, "round": round_n,
		"pct_player": p0, "pct_opponent": p1,
		"counts": {"player": _contagem(cont, 0), "opponent": _contagem(cont, 1)},
		"life_max": vmax.duplicate(), "draws_used": usados,
		"finish": finish, "streak_peak": embalo_pico, "attempts": tentativas,
		"opp_counter_damage": dano_contra_dele, "grip_full_at": t_cheia, "tired_at": t_cansa,
		"tires": box and bool(est.tires), "ahead_at_tired": vantagem_no_cansaco,
	}
	if registro:
		res["events"] = eventos
	return res


## Pegada (0..1) no instante t; 0 quando a arte não tem pegada (t_cheia < 0).
func _pegada(t: float, t_cheia: float) -> float:
	return minf(1.0, t / t_cheia) if t_cheia > 0.0 else 0.0


## Nota da passiva no motivo da derrota (design 7a1 §9): a 1ª que valer, tirada da própria luta (sem simulação nova).
## `res` = resultado da luta perdida (campos da passiva), `tatica_id` = a usada. {} se nenhuma ou sem arte.
## {id, n, r}: boxing_counter | boxing_tired | boxing_streak | bjj_grip_late | bjj_escaped | bjj_never_hurt.
func nota_passiva(res: Dictionary, tatica_id: String) -> Dictionary:
	if passiva.is_empty() or not res.has("finish"):
		return {}
	var vmax_j: float = res.life_max[0]
	var t_fim: float = res.t_end
	if passiva.type == "fast_hands":
		var pct := 100.0 * float(res.opp_counter_damage) / vmax_j
		if tatica_id == "aggressive" and float(res.opp_counter_damage) >= 0.2 * vmax_j:
			return {"id": "boxing_counter", "n": mini(100, int(round(pct))), "r": 0}
		# Só pesou se ele chegou ao cansaço sem estar atrás e acabou perdendo (design §9 apertado pelo QA, B6)
		if t_fim >= float(res.tired_at) and tatica_id != "defensive" and bool(res.get("ahead_at_tired", false)):
			return {"id": "boxing_tired", "n": 0, "r": 0}
		if int(res.streak_peak) <= 2:
			return {"id": "boxing_streak", "n": int(res.streak_peak), "r": 0}
		return {}
	var cheia: float = res.grip_full_at
	var rodada := int(floor(cheia / float(c.round_length) + 1e-9)) + 1
	if t_fim < cheia or cheia > float(c.time_limit) + 1e-9:
		return {"id": "bjj_grip_late", "n": 0, "r": rodada}
	if int(res.attempts) >= 1:
		return {"id": "bjj_escaped", "n": int(res.attempts), "r": rodada}
	return {"id": "bjj_never_hurt", "n": 0, "r": rodada}


func _contagem(cont: Dictionary, lado: int) -> Dictionary:
	return {"attacks": cont.attacks[lado], "normal_attacks": cont.attacks[lado] - cont.counters[lado],
		"hits": cont.hits[lado], "dodges": cont.dodges[lado], "crits": cont.crits[lado],
		"damage": cont.damage[lado], "counters": cont.counters[lado]}


## Segundos de tela: intro + luta + outro (entre 8 e 19 s por construção).
func tela(res: Dictionary) -> float:
	return c.intro_seconds + res.t_end + c.outro_seconds


# --- Risco (Monte Carlo com sementes fixas 1..N) ---

func chance(jog: Array, adv: Array, tatica_id: String, n: int = 0) -> float:
	return float(chance_detalhada(jog, adv, tatica_id, n).chance)


## Mesma conta de chance(), contando também quantas vitórias vieram da passiva (K.O. ou finalização).
## {chance, wins, wins_passive, n}.
func chance_detalhada(jog: Array, adv: Array, tatica_id: String, n: int = 0) -> Dictionary:
	if n <= 0:
		n = dados.risco.samples
	var cen := preparar(jog, adv, tatica_id)
	var rng := RandomNumberGenerator.new()
	var sem := PackedFloat64Array()
	var w := 0
	var wp := 0
	for s in range(1, n + 1):
		rng.seed = s
		var r := rodar(cen, rng, sem, false)
		if r.win:
			w += 1
			var f: String = r.get("finish", "")
			if f == "knockout" or f == "submission":
				wp += 1
	return {"chance": float(w) / float(n), "wins": w, "wins_passive": wp, "n": n}


## Mesmo resultado que chance(...) >= limiar, parando cedo quando já se sabe.
func passa(jog: Array, adv: Array, tatica_id: String, n: int, limiar: float) -> bool:
	var precisa := int(ceil(limiar * n - 1e-9))
	var cen := preparar(jog, adv, tatica_id)
	var rng := RandomNumberGenerator.new()
	var sem := PackedFloat64Array()
	var w := 0
	for s in range(1, n + 1):
		rng.seed = s
		if rodar(cen, rng, sem, false).win:
			w += 1
			if w >= precisa:
				return true
		elif w + (n - s) < precisa:
			return false
	return w >= precisa


## "easy" | "even" | "hard" (chaves de texto: risk_easy, risk_even, risk_hard).
func rotulo(p: float) -> String:
	if p >= dados.risco.easy_min:
		return "easy"
	if p >= dados.risco.even_min:
		return "even"
	return "hard"


## Rótulo sem calcular a chance inteira (para a conta barata do HUD); igual a rotulo(chance()).
func rotulo_rapido(jog: Array, adv: Array, tatica_id: String) -> String:
	var n: int = dados.risco.samples
	if passa(jog, adv, tatica_id, n, dados.risco.easy_min):
		return "easy"
	if passa(jog, adv, tatica_id, n, dados.risco.even_min):
		return "even"
	return "hard"


## Chance de cada tática: {id: chance}.
func chances_por_tatica(jog: Array, adv: Array) -> Dictionary:
	var r := {}
	for t in dados.taticas:
		r[t.id] = chance(jog, adv, t.id)
	return r


# --- Motivo da derrota (§7) ---

## Menor quantidade extra do atributo `i` que deixa a luta fácil, ou -1 se nem 16 x o total basta.
func falta_para(jog: Array, adv: Array, tatica_id: String, i: int) -> float:
	var m: Dictionary = dados.motivo
	var n: int = dados.risco.samples
	var alvo: float = m.target
	var tot: float = float(jog[0]) + float(jog[1]) + float(jog[2])
	var tot_adv: float = float(adv[0]) + float(adv[1]) + float(adv[2])
	# Teto (B2): 16 x total + 1000, ou 4 x total do adversário, o que for maior.
	var hi: float = maxf(m.search_max_share * tot + 1000.0, m.search_opp_share * tot_adv)
	if not passa(_com_extra(jog, i, hi), adv, tatica_id, n, alvo):
		return -1.0
	var lo := 0.0
	for _p in int(m.search_steps):
		var meio := (lo + hi) / 2.0
		if passa(_com_extra(jog, i, meio), adv, tatica_id, n, alvo):
			hi = meio
		else:
			lo = meio
	return hi


func _com_extra(jog: Array, i: int, extra: float) -> Array:
	var x := [jog[0], jog[1], jog[2]]
	x[i] = x[i] + extra
	return x


## Atributo decisivo: o de MENOR falta (empate: Resistência, Força, Agilidade). Se nenhum chega a
## "fácil", o de maior chance com +Delta. Retorna {attribute, faltaram (-1 se não existe), faltas{id: valor}}.
func motivo(jog: Array, adv: Array, tatica_id: String) -> Dictionary:
	var faltas := {}
	var melhor_i := -1
	var melhor_f := INF
	for i in ORDEM_MOTIVO:
		var f := falta_para(jog, adv, tatica_id, i)
		faltas[ATRIBUTOS[i]] = f
		if f >= 0.0 and f < melhor_f:
			melhor_f = f
			melhor_i = i
	if melhor_i >= 0:
		return {"attribute": ATRIBUTOS[melhor_i], "faltaram": melhor_f, "faltas": faltas}
	var tot: float = float(jog[0]) + float(jog[1]) + float(jog[2])
	var delta := maxf(float(dados.motivo.delta_min), float(dados.motivo.delta_share) * tot)
	var melhor_p := -1.0
	for i in ORDEM_MOTIVO:
		var p := chance(_com_extra(jog, i, delta), adv, tatica_id)
		if p > melhor_p:
			melhor_p = p
			melhor_i = i
	return {"attribute": ATRIBUTOS[melhor_i], "faltaram": -1.0, "faltas": faltas}


## Destaque "ELE É MUITO MAIS ...": atributo (id) de maior razão dele/seu, se >= lead_ratio; senão "".
func destaque(jog: Array, adv: Array) -> String:
	var melhor := ""
	var melhor_r: float = dados.motivo.lead_ratio
	for i in ORDEM_MOTIVO:
		var r: float = float(adv[i]) / maxf(1.0, float(jog[i]))
		if r >= melhor_r and (melhor == "" or r > melhor_r):
			melhor = ATRIBUTOS[i]
			melhor_r = r
	return melhor


## Ordem das estatísticas por motivo (design §16.4): a 1ª válida ganha. "luck" = derrota por azar.
const ORDEM_STAT := {
	"endurance": ["life_taken", "stronger", "crits", "dodged"],
	"strength": ["stronger", "life_taken", "crits", "dodged"],
	"agility": ["crits", "dodged", "life_taken", "stronger"],
	"luck": ["crits", "dodged"],
}


## Razão de força por golpe (dano dele / vida máx. sua) ÷ (seu dano / vida máx. dele).
func _razao_forca(res: Dictionary, jog: Array, adv: Array, tatica_id: String) -> float:
	var cj: Dictionary = res.counts.player
	var ca: Dictionary = res.counts.opponent
	var vmax: Array = res.life_max
	var cen := preparar(jog, adv, tatica_id)
	var dele: float = ca.damage / ca.hits / vmax[0] if ca.hits > 0 else cen.num[1][0] / vmax[0]
	var meu: float = cj.damage / cj.hits / vmax[1] if cj.hits > 0 else cen.num[0][0] / vmax[1]
	if meu <= 0.0:
		return INF
	return dele / meu


## Estatística `modelo` se for válida nesta luta (tabela 16.4), senão {}.
func _stat_valida(modelo: String, res: Dictionary, jog: Array, adv: Array, tatica_id: String) -> Dictionary:
	var m: Dictionary = dados.motivo
	var cj: Dictionary = res.counts.player
	var ca: Dictionary = res.counts.opponent
	var vmax: Array = res.life_max
	match modelo:
		"life_taken":
			var n := int(round(100.0 * minf(ca.damage, vmax[0]) / vmax[0]))  # sem o excesso do golpe final
			if n >= m.stat_life_min_pct:
				return {"kind": "life_taken", "n": n, "k": ca.hits}
		"stronger":
			var r := _razao_forca(res, jog, adv, tatica_id)
			if r < m.stat_stronger_min_ratio:
				return {}
			if r >= m.stat_stronger_cap_ratio:
				return {"kind": "stronger_cap", "n": int(m.stat_stronger_cap_ratio), "k": 0}
			if r >= m.stat_stronger_x_ratio:
				return {"kind": "stronger_x", "n": int(floor(r)), "k": 0}
			return {"kind": "stronger", "n": int(round(100.0 * (r - 1.0))), "k": 0}
		"crits":
			if ca.crits >= m.stat_crits_min and ca.crits > cj.crits:
				return {"kind": "crits", "n": ca.crits, "k": cj.crits}
		"dodged":
			var atq: int = cj.normal_attacks
			if atq >= m.stat_dodge_min_attacks:
				var n := int(round(100.0 * ca.dodges / atq))
				if n >= m.stat_dodge_min_pct:
					return {"kind": "dodged", "n": n, "k": 0}
	return {}


## Estatística da luta para a 2ª linha da tela de fim (design §16.4).
## `chave`: endurance | strength | agility | luck. `p` = chance da tática usada (só para luck).
## Retorna {kind, n, k}: life_taken | stronger | stronger_x | stronger_cap | crits | dodged | points |
## luck_odds | luck_rare. Sempre devolve uma (último recurso).
func estatistica(chave: String, res: Dictionary, jog: Array, adv: Array, tatica_id: String, p: float = 0.0) -> Dictionary:
	for modelo in ORDEM_STAT.get(chave, ORDEM_STAT.agility):
		var st := _stat_valida(modelo, res, jog, adv, tatica_id)
		if not st.is_empty():
			return st
	if chave == "luck":
		var n := int(round(100.0 * (1.0 - p)))
		return {"kind": "luck_odds", "n": n, "k": 0} if n >= 1 else {"kind": "luck_rare", "n": 0, "k": 0}
	if res.ko:
		return {"kind": "life_taken", "n": 100, "k": res.counts.opponent.hits}  # K.O. é sempre 100%
	return {"kind": "points", "n": int(round(100.0 * res.pct_player)), "k": int(round(100.0 * res.pct_opponent))}


## Motivo completo da derrota (design §16.1). `p` = chance da tática usada.
## Retorna {kind: luck|missing|far|far_plain, attribute, faltaram (cru, -1 = não existe), far_n, stat, res}.
func explicar(jog: Array, adv: Array, tatica_id: String, semente: int, p: float) -> Dictionary:
	var res := lutar(jog, adv, tatica_id, semente, false)
	if p >= float(dados.motivo.luck_min):
		return {"kind": "luck", "attribute": "", "faltaram": -1.0, "far_n": 0, "res": res,
			"stat": estatistica("luck", res, jog, adv, tatica_id, p)}
	var m := motivo(jog, adv, tatica_id)
	var kind := "missing"
	var far_n := 0
	if m.faltaram < 0.0:
		var razao := (float(adv[0]) + float(adv[1]) + float(adv[2])) / maxf(1.0, float(jog[0]) + float(jog[1]) + float(jog[2]))
		kind = "far" if razao >= float(dados.motivo.far_min_ratio) else "far_plain"
		far_n = int(floor(razao))
	return {"kind": kind, "attribute": m.attribute, "faltaram": m.faltaram, "far_n": far_n, "res": res,
		"stat": estatistica(m.attribute, res, jog, adv, tatica_id, p)}
