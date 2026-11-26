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


## 8a1: passiva do adversário = 4º item do array dele ([F, A, R, passiva]); ausente = nenhuma (os 6 de antes).
## Assim prévia, risco, robô, motivo e luta recebem a passiva junto com o adversário (sem estado no motor, seguro com threads).
func _pas_adv(adv: Array) -> Dictionary:
	if adv.size() > 3 and adv[3] is Dictionary:
		return adv[3]
	return {}


## 8a1: as travas dele (`locks[tipo da sua passiva]`) valem só se existirem para o seu jeito de lutar.
func _travas_do_adv(adv: Array) -> Dictionary:
	if passiva.is_empty():
		return {}
	var locks = _pas_adv(adv).get("locks", {})
	if locks is Dictionary and locks.get(str(passiva.type), null) is Dictionary:
		return locks[str(passiva.type)]
	return {}


## 8a1: cópia da sua passiva com `campo x mult` das travas dele (a original não muda). Sem trava: a mesma.
func _passiva_ef(adv: Array) -> Dictionary:
	var l := _travas_do_adv(adv)
	if l.is_empty():
		return passiva
	var P := passiva.duplicate()
	for campo in l:
		if P.has(campo):
			P[campo] = float(P[campo]) * float(l[campo])
	return P


## Números da passiva que a prévia mostra e a luta usa (determinístico). {} sem arte.
## Boxe: fator de agilidade, K.O. máximo por golpe, quando cansa. Jiu-jitsu: quando a pegada enche e chance de finalizar.
## Já vem com a trava do adversário (8a1); `estado_passiva_sem_adv` é a mesma conta sem ela.
func estado_passiva(jog: Array, adv: Array, tatica_id: String) -> Dictionary:
	return _estado(jog, adv, tatica_id, true)


func estado_passiva_sem_adv(jog: Array, adv: Array, tatica_id: String) -> Dictionary:
	return _estado(jog, adv, tatica_id, false)


func _estado(jog: Array, adv: Array, tatica_id: String, com_adv: bool) -> Dictionary:
	if passiva.is_empty():
		return {}
	var P := _passiva_ef(adv) if com_adv else passiva
	var ej := efetivos(jog)
	var ea := efetivos(adv)
	var tp: Dictionary = P.tactics.get(tatica_id, {})
	if P.type in ["counter_punch", "top_control", "thai_clinch"]:
		return _estado_passiva2(ej, ea, P, tp, tatica_id)
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
	if P.type == "shin":
		return _estado_shin(ej, ea, P, tp)
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


## Fator F(meu, dele, min, max) = clamp(2 meu / (meu + dele), min, max); 1 se os dois são zero (design 7b2 §1).
func _fator(meu: float, dele: float, minimo: float, maximo: float) -> float:
	return _clamp_fator(2.0 * meu / (meu + dele), minimo, maximo) if meu + dele > 0.0 else 1.0


## 2ªs passivas (design 7b2 §2-§4): números fixos da luta, que a prévia mostra. Determinístico.
func _estado_passiva2(ej: Array, ea: Array, P: Dictionary, tp: Dictionary, tatica_id: String) -> Dictionary:
	if P.type == "counter_punch":
		var fa := _fator(ej[1], ea[1], P.dodge_agility_min, P.dodge_agility_max)
		var tj := _tatica(tatica_id)
		var esq0: float = golpe(ea, ej, NEUTRA, tj)[2]  # a esquiva sua contra o ataque normal dele, sem a passiva
		var esq := minf(c.dodge_cap, esq0 + float(P.dodge_add) * fa * float(tp.get("dodge_mult", 1.0)))
		var fr := _fator(ej[2], ea[0], P.ko_endurance_min, P.ko_endurance_max)
		var cmax := int(P.charge_max)
		var kmax := minf(P.ko_cap, cmax * float(P.ko_per_charge) * fr * float(tp.get("ko_mult", 1.0)) * (1.0 + extra_passiva))
		return {"kind": "counter_punch", "agi_factor": fa, "dodge_now": esq0, "dodge": esq, "dodge_add": esq - esq0,
			"end_factor": fr, "charge_max": cmax, "charge_per_dodge": int(tp.get("charge_per_dodge", P.charge_per_dodge)),
			"ko_max": kmax, "ko_per_charge": kmax / cmax, "ko_from": (float(P.ko_from_round) - 1.0) * c.round_length,
			"ko_round": int(P.ko_from_round), "counter_power": P.counter_power,
			"counter_mult": maxf(float(tj.counter_mult), float(P.counter_mult))}
	if P.type == "top_control":
		var ft := _fator(ej[0], ea[1], P.td_strength_min, P.td_strength_max)
		var td := minf(P.td_cap, float(P.td_base) * ft * float(tp.get("td_mult", 1.0)) * (1.0 + extra_passiva))
		var fe := _fator(ea[1], ej[0], P.escape_agility_min, P.escape_agility_max)
		var esc := minf(P.escape_cap, float(P.escape_base) * fe * float(tp.get("escape_mult", 1.0)))
		return {"kind": "top_control", "str_factor": ft, "td_chance": td, "opp_agi_factor": fe, "escape": esc,
			"stop_life": P.stop_life_max, "stop_chance": P.stop_chance,
			"top_damage_mult": P.top_damage_mult, "bottom_damage_mult": P.bottom_damage_mult}
	var fs := _fator(ej[0], ea[0], P.clinch_strength_min, P.clinch_strength_max)
	var ent := minf(P.clinch_cap, float(P.clinch_base) * fs * float(tp.get("clinch_mult", 1.0)) * (1.0 + extra_passiva))
	var fe2 := _fator(ea[2], ej[2], P.escape_endurance_min, P.escape_endurance_max)
	var esc2 := minf(P.escape_cap, float(P.escape_base) * fe2 * float(tp.get("escape_mult", 1.0)))
	var n1: float = golpe(ej, ea, NEUTRA, NEUTRA)[1]
	var kc := maxf(n1, minf(P.crit_cap, n1 + float(P.clinch_crit_add)))
	var kko := minf(1.0, float(P.knee_ko) * float(tp.get("knee_mult", 1.0)))
	return {"kind": "thai_clinch", "str_factor": fs, "clinch_chance": ent, "opp_end_factor": fe2, "escape": esc2,
		"clinch_life": P.clinch_life_max, "clinch_s": P.clinch_s, "crit_now": n1, "knee_crit": kc, "knee_ko": kko,
		"knee_life": P.knee_life_max, "knee_chance": kc * kko,
		"knee_damage_mult": float(P.knee_damage_mult) * float(tp.get("knee_damage_mult", 1.0))}


## Muay Thai (Canela, design 7b1 §1.2): marcas por chute, crítico com a perna cheia, chute rodado e lentidão dele. Determinístico.
func _estado_shin(ej: Array, ea: Array, P: Dictionary, tp: Dictionary) -> Dictionary:
	var fm := _clamp_fator(2.0 * ej[0] / (ej[0] + ea[2]), P.mark_strength_min, P.mark_strength_max) if ej[0] + ea[2] > 0.0 else 1.0
	var ganho := minf(P.mark_cap, P.mark_per_kick * fm * float(tp.get("mark_mult", 1.0)) * (1.0 + extra_passiva))
	var mmax := int(P.marks_max)
	var chutes := int(ceil(mmax / ganho - 1e-9)) if ganho > 0.0 else 99
	var fa := _clamp_fator(2.0 * ej[1] / (ej[1] + ea[1]), P.crit_agility_min, P.crit_agility_max) if ej[1] + ea[1] > 0.0 else 1.0
	var n1: float = golpe(ej, ea, NEUTRA, NEUTRA)[1]  # crítico do jogador contra ele (só depende da AGILIDADE)
	var cpm: float = P.crit_per_mark * fa
	var cheio := maxf(n1, minf(P.crit_cap, n1 + mmax * cpm))
	var sko := minf(1.0, P.spin_ko * float(tp.get("spin_mult", 1.0)))
	return {"kind": "shin", "str_factor": fm, "mark_gain": ganho, "kicks_to_full": chutes, "marks_max": mmax,
		"agi_factor": fa, "crit_now": n1, "crit_per_mark": cpm, "crit_full": cheio,
		"slow_full": P.slow_per_mark * float(tp.get("slow_mult", 1.0)) * mmax, "spin_ko": sko, "spin_chance": cheio * sko,
		"opp_counter": float(tp.get("opponent_counter", 0.0)), "marks_per_counter": float(tp.get("marks_per_counter", 0.0))}


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
		if passiva.type == "fast_hands" or passiva.type == "shin":  # Agressivo: ele contragolpeia quando esquiva (o `counter_mult` da tática DELE)
			ta = NEUTRA.duplicate()
			ta["counter_mult"] = float(tp.get("opponent_counter", 0.0))
	var num := [golpe(ef_j, ef_a, tj, ta), golpe(ef_a, ef_j, ta, tj)]
	if not passiva.is_empty() and passiva.type == "counter_punch":
		# Contragolpista: a sua esquiva leva o bônus da passiva e toda esquiva vira contragolpe (counter_mult da passiva)
		num[1][2] = est.dodge
		tj = tj.duplicate()
		tj["counter_mult"] = est.counter_mult
	var cen := {
		"tac": [tj, ta],
		"vmax": [vida_max(ef_j), vida_max(ef_a)],
		"num": num,
		# quem tem mais Agilidade efetiva ataca primeiro; empate: o jogador
		"primeiro": 0 if ef_j[1] >= ef_a[1] else 1,
		"est": est, "tp": tp,
	}
	# 8a1: passiva do adversário (só quem tem; os 6 de antes ficam com o cenário de sempre).
	var pv := _pas_adv(adv)
	if not pv.is_empty():
		cen["adv_pas"] = true
		cen["est_sem"] = _estado(jog, adv, tatica_id, false) if not _travas_do_adv(adv).is_empty() else {}
		var g = pv.get("guard", null)
		if g is Dictionary:
			cen["guard_t"] = float(g.rounds) * float(c.round_length)
			cen["guard_m"] = float(g.taken_mult)
	return cen


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
## 8a1: contra adversário com passiva a luta ganha o estado dela (cópia rasa do cenário, para não acumular entre lutas) e os
## campos opp_blocks / guard_absorbed (+ opp_block / guard nos eventos). Sem passiva dele: exatamente o laço de sempre.
func rodar(cen: Dictionary, rng: RandomNumberGenerator, sorteios: PackedFloat64Array, registro: bool) -> Dictionary:
	if not cen.has("adv_pas"):
		return _rodar_base(cen, rng, sorteios, registro)
	var st := {"blk": 0, "guard_abs": 0.0, "ev_blk": [], "ev_guard": []}
	var c2 := cen.duplicate()
	c2["st"] = st
	var res := _rodar_base(c2, rng, sorteios, registro)
	res["opp_blocks"] = int(st.blk)
	res["guard_absorbed"] = minf(1.0, float(st.guard_abs) / float(cen.vmax[1]))
	if registro:
		for e in res.events:
			e["opp_block"] = false
			e["guard"] = false
		for i in st.ev_blk:
			res.events[i]["opp_block"] = true
		for i in st.ev_guard:
			res.events[i]["guard"] = true
	return res


## Guarda fechada dele (8a1): o dano nele sai x taken_mult. Soma o que a guarda segurou e marca o evento (índice do que vem).
func _guarda(st: Dictionary, d: float, mult: float, indice: int) -> float:
	var novo := d * mult
	st["guard_abs"] = float(st.guard_abs) + (d - novo)
	st.ev_guard.append(indice)
	return novo


## A passiva dele mudou o resultado deste acerto (o mesmo sorteio daria certo sem a trava): só o sinal da tela.
func _bloqueio(st: Dictionary, indice: int) -> void:
	st["blk"] = int(st.blk) + 1
	st.ev_blk.append(indice)


func _rodar_base(cen: Dictionary, rng: RandomNumberGenerator, sorteios: PackedFloat64Array, registro: bool) -> Dictionary:
	if not passiva.is_empty():
		match str(passiva.type):
			"shin":
				return _rodar_shin(cen, rng, sorteios, registro)
			"counter_punch":
				return _rodar_contra(cen, rng, sorteios, registro)
			"top_control":
				return _rodar_cima(cen, rng, sorteios, registro)
			"thai_clinch":
				return _rodar_clinch(cen, rng, sorteios, registro)
		return _rodar_arte(cen, rng, sorteios, registro)
	var limite: float = c.time_limit
	var intervalo: float = c.attack_interval
	var atraso: float = c.counter_delay
	var spread: float = c.damage_spread
	var st: Dictionary = cen.get("st", {})  # 8a1: estado da passiva dele (vazio = nenhuma)
	var guard_t: float = float(cen.get("guard_t", -1.0))
	var guard_m: float = float(cen.get("guard_m", 1.0))
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
		if alvo == 1 and t < guard_t:  # 8a1: guarda fechada dele
			d = _guarda(st, d, guard_m, eventos.size())
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
	var ko_sem := float(cen.get("est_sem", {}).get("ko_per_streak", 0.0))  # 8a1: o K.O. de embalo sem a trava dele
	var frente: bool = float(P.need_ahead) >= 0.5
	var limite: float = c.time_limit
	var base: float = c.attack_interval
	var atraso: float = c.counter_delay
	var spread: float = c.damage_spread
	var st: Dictionary = cen.get("st", {})  # 8a1: estado da passiva dele (vazio = nenhuma)
	var guard_t: float = float(cen.get("guard_t", -1.0))
	var guard_m: float = float(cen.get("guard_m", 1.0))
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
		if alvo == 1 and t < guard_t:  # 8a1: guarda fechada dele
			d = _guarda(st, d, guard_m, eventos.size())
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
					elif r_arte < embalo * ko_sem:
						_bloqueio(st, eventos.size())  # 8a1: queixo de ferro: sem a trava este K.O. teria saído
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


## Laço do Muay Thai (porta de _lutar_shin, tools/sim/fase7b1_sim.py). Mesmos 4 sorteios por ataque (r_esq, r_crit, r_var, r_arte;
## r_arte só vale no chute rodado). Só o acerto normal do jogador marca a perna; as marcas inteiras (lidas ANTES do ataque) deixam
## o adversário mais lento e sobem o crítico do jogador. Resultado = o de sempre + finish ("damage"|"spin_kick"|"points"),
## marks_peak, marks_full_at (-1 se não encheu), attempts, spins, opp_counter_damage. Eventos ganham marks, move ("kick"|"crit"|"spin"), finish.
func _rodar_shin(cen: Dictionary, rng: RandomNumberGenerator, sorteios: PackedFloat64Array, registro: bool) -> Dictionary:
	var P := passiva
	var est: Dictionary = cen.est
	var tp: Dictionary = cen.tp
	var frente: bool = float(P.need_ahead) >= 0.5
	var limite: float = c.time_limit
	var base: float = c.attack_interval
	var atraso: float = c.counter_delay
	var spread: float = c.damage_spread
	var st: Dictionary = cen.get("st", {})  # 8a1: estado da passiva dele (vazio = nenhuma)
	var guard_t: float = float(cen.get("guard_t", -1.0))
	var guard_m: float = float(cen.get("guard_m", 1.0))
	var cm: float = c.crit_multiplier
	var tac: Array = cen.tac
	var vmax: Array = cen.vmax
	var num: Array = cen.num
	var vida := [vmax[0], vmax[1]]
	var iv_j: float = base * float(P.interval_mult)
	var mmax := int(P.marks_max)
	var ganho: float = est.mark_gain
	var por_contra := float(tp.get("marks_per_counter", 0.0))
	var lento: float = float(P.slow_per_mark) * float(tp.get("slow_mult", 1.0))
	var cpm: float = est.crit_per_mark
	var ccap: float = P.crit_cap
	var spin_vida: float = P.spin_life_max
	var sko: float = est.spin_ko
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
	var perna := 0.0  # contínua, 0..mmax; as marcas inteiras são o que a tela mostra
	var cheia_em := -1.0
	var tentativas := 0
	var rodados := 0
	var finish := ""
	var t_ko := -1.0
	var vencedor := -1

	while true:
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
		var marcas := mini(mmax, int(floor(perna + 1e-9)))
		if eh_contra:
			contra_t.remove_at(idx_contra)
			contra_q.remove_at(idx_contra)
		elif quem == 0:
			prox[0] += iv_j
		else:
			prox[1] += base * (1.0 + lento * marcas)  # mancando: ele ataca mais devagar
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
			if tac[alvo].counter_mult > 0.0 and t + atraso <= limite + 1e-9:
				contra_t.append(t + atraso)
				contra_q.append(alvo)
			if registro:
				eventos.append({"t": t, "who": quem, "type": "dodge", "counter": false, "damage": 0.0,
					"life_after": vida[alvo], "streak": 0, "grip": 0.0, "tired": false, "finish": "",
					"marks": marcas, "move": ""})
			continue
		var crit_p: float = n[1]
		if quem == 0:
			crit_p = maxf(crit_p, minf(ccap, crit_p + marcas * cpm))  # cada marca: + crit_per_mark x fator de AGILIDADE
		var e_crit: bool = r_crit < crit_p
		var d: float = n[0]
		if e_crit:
			d *= 1.0 + (cm - 1.0) * (1.0 - tac[alvo].crit_guard)
		if eh_contra:
			d *= tac[quem].counter_mult
			if quem == 1:
				dano_contra_dele += d * (1.0 + spread * (2.0 * r_var - 1.0))
		d *= 1.0 + spread * (2.0 * r_var - 1.0)
		if alvo == 1 and t < guard_t:  # 8a1: guarda fechada dele
			d = _guarda(st, d, guard_m, eventos.size())
		vida[alvo] -= d
		cont.hits[quem] += 1
		cont.damage[quem] += d
		if e_crit:
			cont.crits[quem] += 1
		var golpe_v := ""
		if quem == 0:
			golpe_v = "spin" if (e_crit and marcas >= mmax) else ("crit" if e_crit else "kick")
		var fim := ""
		if vida[alvo] <= 1e-9 * vmax[alvo]:
			fim = "damage"
		elif quem == 0:
			if golpe_v == "spin":
				rodados += 1
				var portao: bool = not frente or vida[1] * vmax[0] <= vida[0] * vmax[1]
				if vida[1] <= spin_vida * vmax[1] and portao:
					tentativas += 1
					if r_arte < sko:
						fim = "spin_kick"
			elif golpe_v == "kick":
				var g := maxf(ganho, por_contra) if eh_contra else ganho
				perna = minf(float(mmax), perna + g)
				if perna >= mmax - 1e-9 and cheia_em < 0.0:
					cheia_em = t
		if registro:
			eventos.append({"t": t, "who": quem, "type": "crit" if e_crit else "hit", "counter": eh_contra,
				"damage": d, "life_after": maxf(0.0, vida[alvo]), "streak": 0, "grip": 0.0, "tired": false,
				"finish": fim if fim != "damage" else "", "marks": mini(mmax, int(floor(perna + 1e-9))), "move": golpe_v})
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
		"finish": finish, "streak_peak": 0, "attempts": tentativas,
		"opp_counter_damage": dano_contra_dele, "grip_full_at": -1.0, "tired_at": -1.0,
		"tires": false, "ahead_at_tired": false,
		"marks_peak": mini(mmax, int(floor(perna + 1e-9))), "marks_full_at": cheia_em, "spins": rodados,
	}
	if registro:
		res["events"] = eventos
	return res


# --- 7b2: as 2ªs passivas (porta de _lutar_contra, _lutar_cima e _lutar_clinch de tools/sim/fase7b2_sim.py) ---

## Próximo evento: [t, tipo (0 contragolpe | 1 ataque normal), quem, índice do contragolpe]. Menor tempo; no empate, contragolpe
## antes de ataque normal; depois o jogador (igual ao laço de sempre).
func _proximo_evento(prox: Array, contra_t: Array[float], contra_q: Array[int]) -> Array:
	var t: float = prox[0]
	var tipo := 1
	var quem := 0
	if prox[1] < t:
		t = prox[1]
		quem = 1
	var idx := -1
	for i in contra_t.size():
		var tc := contra_t[i]
		var qc := contra_q[i]
		if tc < t or (tc == t and (tipo == 1 or qc < quem)):
			t = tc
			tipo = 0
			quem = qc
			idx = i
	return [t, tipo, quem, idx]


## Os 4 sorteios de um ataque [r_esq, r_crit, r_var, r_arte] (do rng ou da lista dada).
func _sorteios4(rng: RandomNumberGenerator, sorteios: PackedFloat64Array, usados: int) -> Array:
	if rng != null:
		var a := rng.randf()
		var b := rng.randf()
		var d := rng.randf()
		var e := rng.randf()
		return [a, b, d, e]
	return [sorteios[usados], sorteios[usados + 1], sorteios[usados + 2], sorteios[usados + 3]]


## Fim comum das 2ªs passivas: o resultado de sempre + `extra` (campos da passiva). `finish` vazio = acabou por pontos.
func _fechar_passiva2(vida: Array, vmax: Array, finish: String, t_ko: float, vencedor: int, cont: Dictionary, usados: int,
		eventos: Array, registro: bool, extra: Dictionary) -> Dictionary:
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
		t_fim = c.time_limit
		finish = "points"
	var res := {
		"win": venceu, "ko": ko, "t_ko": t_ko, "t_end": t_fim, "round": round_n,
		"pct_player": p0, "pct_opponent": p1,
		"counts": {"player": _contagem(cont, 0), "opponent": _contagem(cont, 1)},
		"life_max": vmax.duplicate(), "draws_used": usados,
		"finish": finish, "streak_peak": 0, "attempts": 0,
		"opp_counter_damage": 0.0, "grip_full_at": -1.0, "tired_at": -1.0, "tires": false, "ahead_at_tired": false,
	}
	res.merge(extra, true)
	if registro:
		res["events"] = eventos
	return res


## Evento das 2ªs passivas: os campos de sempre (com os das outras artes neutros) + `extra` (charge | ground | clinch, move).
func _evento2(t: float, quem: int, tipo: String, contra: bool, dano: float, vida_depois: float, fim: String, extra: Dictionary) -> Dictionary:
	var e := {"t": t, "who": quem, "type": tipo, "counter": contra, "damage": dano, "life_after": vida_depois,
		"streak": 0, "grip": 0.0, "tired": false, "finish": fim, "marks": 0, "move": ""}
	e.merge(extra, true)
	return e


## Boxe, Contragolpista (design 7b2 §2): toda esquiva sua vira contragolpe (x counter_power) e soma carga; cada round que começa
## soma carga. A partir do `ko_from_round`, acerto seu com ele abaixo de `ko_life_max` e carga > 0 pode ser K.O. (metade fora do contragolpe).
## Não cansa. Resultado: finish "counter_ko", charge_peak, attempts. Eventos ganham `charge` (0-3 depois do evento).
func _rodar_contra(cen: Dictionary, rng: RandomNumberGenerator, sorteios: PackedFloat64Array, registro: bool) -> Dictionary:
	var P := passiva
	var est: Dictionary = cen.est
	var limite: float = c.time_limit
	var base: float = c.attack_interval
	var atraso: float = c.counter_delay
	var spread: float = c.damage_spread
	var st: Dictionary = cen.get("st", {})  # 8a1: estado da passiva dele (vazio = nenhuma)
	var guard_t: float = float(cen.get("guard_t", -1.0))
	var guard_m: float = float(cen.get("guard_m", 1.0))
	var cm: float = c.crit_multiplier
	var tac: Array = cen.tac
	var vmax: Array = cen.vmax
	var num: Array = cen.num
	var vida := [vmax[0], vmax[1]]
	var iv_j: float = base * float(P.interval_mult)
	var cmax := int(est.charge_max)
	var por_esq := int(est.charge_per_dodge)
	var kpc: float = est.ko_per_charge
	var ko_de: float = est.ko_from
	var kvida: float = P.ko_life_max
	var hmult: float = P.hit_ko_mult
	var pot: float = P.counter_power
	var por_round := int(P.charge_per_round)
	var prox := [0.0, 0.0]
	prox[cen.primeiro] = c.first_attack
	prox[1 - cen.primeiro] = c.first_attack + base / 2.0
	var contra_t: Array[float] = []
	var contra_q: Array[int] = []
	var cont := {"attacks": [0, 0], "counters": [0, 0], "hits": [0, 0], "dodges": [0, 0], "crits": [0, 0], "damage": [0.0, 0.0]}
	var eventos: Array = []
	var usados := 0
	var carga := 0
	var carga_pico := 0
	var rounds_vistos := 0
	var tentativas := 0
	var finish := ""
	var t_ko := -1.0
	var vencedor := -1

	while true:
		var prox_ev := _proximo_evento(prox, contra_t, contra_q)
		var t: float = prox_ev[0]
		var quem: int = prox_ev[2]
		var eh_contra: bool = int(prox_ev[1]) == 0
		if t > limite + 1e-9:
			break
		if eh_contra:
			contra_t.remove_at(int(prox_ev[3]))
			contra_q.remove_at(int(prox_ev[3]))
		elif quem == 0:
			prox[0] += iv_j
		else:
			prox[1] += base
		var alvo := 1 - quem
		var rd := int(floor(t / c.round_length + 1e-9))  # rounds que já passaram (0, 1, 2)
		if rd > rounds_vistos:
			carga = mini(cmax, carga + por_round * (rd - rounds_vistos))
			carga_pico = maxi(carga_pico, carga)
			rounds_vistos = rd
		var n: Array = num[quem]
		var sor := _sorteios4(rng, sorteios, usados)
		if rng == null:
			usados += 4
		var r_esq: float = sor[0]
		var r_crit: float = sor[1]
		var r_var: float = sor[2]
		var r_arte: float = sor[3]
		cont.attacks[quem] += 1
		if eh_contra:
			cont.counters[quem] += 1
		if not eh_contra and r_esq < n[2]:
			cont.dodges[alvo] += 1
			if alvo == 0:
				carga = mini(cmax, carga + por_esq)
				carga_pico = maxi(carga_pico, carga)
			if tac[alvo].counter_mult > 0.0 and t + atraso <= limite + 1e-9:
				contra_t.append(t + atraso)
				contra_q.append(alvo)
			if registro:
				eventos.append(_evento2(t, quem, "dodge", false, 0.0, vida[alvo], "", {"charge": carga}))
			continue
		var e_crit: bool = r_crit < n[1]
		var d: float = n[0]
		if e_crit:
			d *= 1.0 + (cm - 1.0) * (1.0 - tac[alvo].crit_guard)
		if eh_contra:
			d *= tac[quem].counter_mult * (pot if quem == 0 else 1.0)
		d *= 1.0 + spread * (2.0 * r_var - 1.0)
		if alvo == 1 and t < guard_t:  # 8a1: guarda fechada dele
			d = _guarda(st, d, guard_m, eventos.size())
		vida[alvo] -= d
		cont.hits[quem] += 1
		cont.damage[quem] += d
		if e_crit:
			cont.crits[quem] += 1
		var fim := ""
		if vida[alvo] <= 1e-9 * vmax[alvo]:
			fim = "damage"
		elif quem == 0 and t >= ko_de - 1e-9 and carga > 0 and vida[1] <= kvida * vmax[1]:
			tentativas += 1
			if r_arte < carga * kpc * (1.0 if eh_contra else hmult):
				fim = "counter_ko"
		if registro:
			eventos.append(_evento2(t, quem, "crit" if e_crit else "hit", eh_contra, d, maxf(0.0, vida[alvo]),
				fim if fim != "damage" else "", {"charge": carga}))
		if fim != "":
			finish = fim
			t_ko = t
			vencedor = quem
			break
	return _fechar_passiva2(vida, vmax, finish, t_ko, vencedor, cont, usados, eventos, registro,
		{"charge_peak": carga_pico, "attempts": tentativas})


## Jiu-jitsu, Por cima (design 7b2 §3): em pé, acerto seu (que não derrubou por dano) pode derrubar (r_arte < td). Por cima: você bate
## mais rápido, ele esquiva metade e bate fraco, e a cada ataque normal dele ANTES de resolver r_arte < esc o faz levantar. Por cima, com ele
## abaixo de `stop_life_max`, cada acerto pode parar a luta. Resultado: finish "ground_stop", takedowns, stood_up, takedown_at, attempts.
func _rodar_cima(cen: Dictionary, rng: RandomNumberGenerator, sorteios: PackedFloat64Array, registro: bool) -> Dictionary:
	var P := passiva
	var est: Dictionary = cen.est
	var limite: float = c.time_limit
	var base: float = c.attack_interval
	var atraso: float = c.counter_delay
	var spread: float = c.damage_spread
	var st: Dictionary = cen.get("st", {})  # 8a1: estado da passiva dele (vazio = nenhuma)
	var guard_t: float = float(cen.get("guard_t", -1.0))
	var guard_m: float = float(cen.get("guard_m", 1.0))
	var cm: float = c.crit_multiplier
	var tac: Array = cen.tac
	var vmax: Array = cen.vmax
	var num: Array = cen.num
	var vida := [vmax[0], vmax[1]]
	var iv_pe: float = base * float(P.interval_mult)
	var iv_chao: float = iv_pe * float(P.top_interval_mult)
	var td: float = est.td_chance
	var td_sem := float(cen.get("est_sem", {}).get("td_chance", 0.0))  # 8a1: a queda sem a trava dele
	var esc: float = est.escape
	var top_d: float = P.top_damage_mult
	var bot_d: float = P.bottom_damage_mult
	var bot_e: float = P.bottom_dodge_mult
	var svida: float = P.stop_life_max
	var sch: float = P.stop_chance
	var prox := [0.0, 0.0]
	prox[cen.primeiro] = c.first_attack
	prox[1 - cen.primeiro] = c.first_attack + base / 2.0
	var contra_t: Array[float] = []
	var contra_q: Array[int] = []
	var cont := {"attacks": [0, 0], "counters": [0, 0], "hits": [0, 0], "dodges": [0, 0], "crits": [0, 0], "damage": [0.0, 0.0]}
	var dano_contra_dele := 0.0
	var eventos: Array = []
	var usados := 0
	var chao := false
	var quedas := 0
	var levantou := 0
	var queda_em := -1.0
	var tentativas := 0
	var finish := ""
	var t_ko := -1.0
	var vencedor := -1

	while true:
		var prox_ev := _proximo_evento(prox, contra_t, contra_q)
		var t: float = prox_ev[0]
		var quem: int = prox_ev[2]
		var eh_contra: bool = int(prox_ev[1]) == 0
		if t > limite + 1e-9:
			break
		if eh_contra:
			contra_t.remove_at(int(prox_ev[3]))
			contra_q.remove_at(int(prox_ev[3]))
		elif quem == 0:
			prox[0] += iv_chao if chao else iv_pe
		else:
			prox[1] += base
		var alvo := 1 - quem
		var sor := _sorteios4(rng, sorteios, usados)
		if rng == null:
			usados += 4
		var r_esq: float = sor[0]
		var r_crit: float = sor[1]
		var r_var: float = sor[2]
		var r_arte: float = sor[3]
		if quem == 1 and not eh_contra and chao and r_arte < esc:
			chao = false  # ele levantou (o ataque sai em pé)
			levantou += 1
		var n: Array = num[quem]
		var dano: float = n[0]
		var crit: float = n[1]
		var esq: float = n[2]
		if chao:
			if quem == 0:
				dano *= top_d
				esq *= bot_e
			else:
				dano *= bot_d
		cont.attacks[quem] += 1
		if eh_contra:
			cont.counters[quem] += 1
		if not eh_contra and r_esq < esq:
			cont.dodges[alvo] += 1
			if tac[alvo].counter_mult > 0.0 and t + atraso <= limite + 1e-9:
				contra_t.append(t + atraso)
				contra_q.append(alvo)
			if registro:
				eventos.append(_evento2(t, quem, "dodge", false, 0.0, vida[alvo], "", {"ground": chao}))
			continue
		var e_crit: bool = r_crit < crit
		var d: float = dano
		if e_crit:
			d *= 1.0 + (cm - 1.0) * (1.0 - tac[alvo].crit_guard)
		if eh_contra:
			d *= tac[quem].counter_mult
			if quem == 1:
				dano_contra_dele += d * (1.0 + spread * (2.0 * r_var - 1.0))
		d *= 1.0 + spread * (2.0 * r_var - 1.0)
		if alvo == 1 and t < guard_t:  # 8a1: guarda fechada dele
			d = _guarda(st, d, guard_m, eventos.size())
		vida[alvo] -= d
		cont.hits[quem] += 1
		cont.damage[quem] += d
		if e_crit:
			cont.crits[quem] += 1
		var fim := ""
		var golpe_v := ""
		if vida[alvo] <= 1e-9 * vmax[alvo]:
			fim = "damage"
		elif quem == 0:
			if chao:
				golpe_v = "ground"
				if vida[1] <= svida * vmax[1]:
					tentativas += 1
					if r_arte < sch:
						fim = "ground_stop"
			elif r_arte < td:
				golpe_v = "takedown"
				chao = true
				quedas += 1
				if queda_em < 0.0:
					queda_em = t
			elif r_arte < td_sem:
				_bloqueio(st, eventos.size())  # 8a1: base larga: sem a trava a queda teria entrado
		if registro:
			eventos.append(_evento2(t, quem, "crit" if e_crit else "hit", eh_contra, d, maxf(0.0, vida[alvo]),
				fim if fim != "damage" else "", {"ground": chao, "move": golpe_v}))
		if fim != "":
			finish = fim
			t_ko = t
			vencedor = quem
			break
	return _fechar_passiva2(vida, vmax, finish, t_ko, vencedor, cont, usados, eventos, registro,
		{"takedowns": quedas, "stood_up": levantou, "takedown_at": queda_em, "attempts": tentativas,
		"opp_counter_damage": dano_contra_dele})


## Muay Thai, Clinch (design 7b2 §4): com ele abaixo de `clinch_life_max`, acerto seu pode prender (r_arte < ent) por `clinch_s`.
## Preso: ele não esquiva, o seu crítico sobe (joelhada), você bate mais rápido e ele bate fraco; a cada ataque normal dele, ANTES de
## resolver, r_arte < esc solta. Joelhada crítica com ele abaixo de `knee_life_max` pode derrubar. Resultado: finish "knee_ko",
## clinches, released, clinch_at, knees, attempts. Eventos ganham `clinch` (preso depois do evento) e `move` ("clinch"|"knee"|"hit").
func _rodar_clinch(cen: Dictionary, rng: RandomNumberGenerator, sorteios: PackedFloat64Array, registro: bool) -> Dictionary:
	var P := passiva
	var est: Dictionary = cen.est
	var limite: float = c.time_limit
	var base: float = c.attack_interval
	var atraso: float = c.counter_delay
	var spread: float = c.damage_spread
	var st: Dictionary = cen.get("st", {})  # 8a1: estado da passiva dele (vazio = nenhuma)
	var guard_t: float = float(cen.get("guard_t", -1.0))
	var guard_m: float = float(cen.get("guard_m", 1.0))
	var cm: float = c.crit_multiplier
	var tac: Array = cen.tac
	var vmax: Array = cen.vmax
	var num: Array = cen.num
	var vida := [vmax[0], vmax[1]]
	var iv_j: float = base * float(P.interval_mult)
	var iv_cl: float = iv_j * float(P.clinch_interval_mult)
	var ent: float = est.clinch_chance
	var ent_sem := float(cen.get("est_sem", {}).get("clinch_chance", 0.0))  # 8a1: o clinch sem a trava dele
	var esc: float = est.escape
	var cl_s: float = P.clinch_s
	var cl_vida: float = P.clinch_life_max
	var kc: float = est.knee_crit
	var kko: float = est.knee_ko
	var kvida: float = P.knee_life_max
	var ctk: float = P.clinch_taken_mult
	var kdm: float = est.knee_damage_mult
	var prox := [0.0, 0.0]
	prox[cen.primeiro] = c.first_attack
	prox[1 - cen.primeiro] = c.first_attack + base / 2.0
	var contra_t: Array[float] = []
	var contra_q: Array[int] = []
	var cont := {"attacks": [0, 0], "counters": [0, 0], "hits": [0, 0], "dodges": [0, 0], "crits": [0, 0], "damage": [0.0, 0.0]}
	var dano_contra_dele := 0.0
	var eventos: Array = []
	var usados := 0
	var preso_ate := -1.0
	var clinches := 0
	var soltou := 0
	var tentativas := 0
	var joelhadas := 0
	var clinch_em := -1.0
	var finish := ""
	var t_ko := -1.0
	var vencedor := -1

	while true:
		var prox_ev := _proximo_evento(prox, contra_t, contra_q)
		var t: float = prox_ev[0]
		var quem: int = prox_ev[2]
		var eh_contra: bool = int(prox_ev[1]) == 0
		if t > limite + 1e-9:
			break
		var preso: bool = t < preso_ate - 1e-9
		if eh_contra:
			contra_t.remove_at(int(prox_ev[3]))
			contra_q.remove_at(int(prox_ev[3]))
		elif quem == 0:
			prox[0] += iv_cl if preso else iv_j
		else:
			prox[1] += base
		var alvo := 1 - quem
		var sor := _sorteios4(rng, sorteios, usados)
		if rng == null:
			usados += 4
		var r_esq: float = sor[0]
		var r_crit: float = sor[1]
		var r_var: float = sor[2]
		var r_arte: float = sor[3]
		if quem == 1 and not eh_contra and preso and r_arte < esc:
			preso = false  # soltou (o ataque sai fora do clinch)
			preso_ate = t
			soltou += 1
		var n: Array = num[quem]
		var dano: float = n[0]
		var crit: float = n[1]
		var esq: float = n[2]
		if preso:
			if quem == 0:
				esq = 0.0
				crit = kc
				dano *= kdm
			else:
				dano *= ctk
		cont.attacks[quem] += 1
		if eh_contra:
			cont.counters[quem] += 1
		if not eh_contra and r_esq < esq:
			cont.dodges[alvo] += 1
			if tac[alvo].counter_mult > 0.0 and t + atraso <= limite + 1e-9:
				contra_t.append(t + atraso)
				contra_q.append(alvo)
			if registro:
				eventos.append(_evento2(t, quem, "dodge", false, 0.0, vida[alvo], "", {"clinch": preso}))
			continue
		var e_crit: bool = r_crit < crit
		var d: float = dano
		if e_crit:
			d *= 1.0 + (cm - 1.0) * (1.0 - tac[alvo].crit_guard)
		if eh_contra:
			d *= tac[quem].counter_mult
			if quem == 1:
				dano_contra_dele += d * (1.0 + spread * (2.0 * r_var - 1.0))
		d *= 1.0 + spread * (2.0 * r_var - 1.0)
		if alvo == 1 and t < guard_t:  # 8a1: guarda fechada dele
			d = _guarda(st, d, guard_m, eventos.size())
		vida[alvo] -= d
		cont.hits[quem] += 1
		cont.damage[quem] += d
		if e_crit:
			cont.crits[quem] += 1
		var fim := ""
		var golpe_v := ""
		if quem == 0:
			golpe_v = "knee" if preso else "hit"
			if preso and e_crit:
				joelhadas += 1
		if vida[alvo] <= 1e-9 * vmax[alvo]:
			fim = "damage"
		elif quem == 0:
			if preso:
				if e_crit and vida[1] <= kvida * vmax[1]:
					tentativas += 1
					if r_arte < kko:
						fim = "knee_ko"
			elif vida[1] <= cl_vida * vmax[1] and r_arte < ent:
				golpe_v = "clinch"
				preso_ate = t + cl_s
				clinches += 1
				if clinch_em < 0.0:
					clinch_em = t
			elif vida[1] <= cl_vida * vmax[1] and r_arte < ent_sem:
				_bloqueio(st, eventos.size())  # 8a1: ensaboado: sem a trava o clinch teria prendido
		if registro:
			eventos.append(_evento2(t, quem, "crit" if e_crit else "hit", eh_contra, d, maxf(0.0, vida[alvo]),
				fim if fim != "damage" else "", {"clinch": t < preso_ate - 1e-9, "move": golpe_v}))
		if fim != "":
			finish = fim
			t_ko = t
			vencedor = quem
			break
	return _fechar_passiva2(vida, vmax, finish, t_ko, vencedor, cont, usados, eventos, registro,
		{"clinches": clinches, "released": soltou, "clinch_at": clinch_em, "knees": joelhadas, "attempts": tentativas,
		"opp_counter_damage": dano_contra_dele})


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
	if passiva.type in ["counter_punch", "top_control", "thai_clinch"]:
		return _nota_passiva2(res)
	if passiva.type == "shin":
		return _nota_shin(res, tatica_id, vmax_j, t_fim)
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


## Motivo da derrota pela passiva DELE (8a1 §3.3): {id, n} ou {}. Sem simulação nova: lê os campos da luta já feita.
## Queixo de ferro / Base larga: perdeu e a trava segurou ao menos 1 acerto (n = quantos). Ensaboado: também se ele soltou 2+ vezes.
## Blindado: sempre pesa (n = % da vida dele que a guarda segurou).
func nota_adversario(res: Dictionary, adv: Array) -> Dictionary:
	var id := str(_pas_adv(adv).get("id", ""))
	if id == "" or bool(res.win):
		return {}
	if id == "adv_blindado":
		return {"id": id, "n": int(round(100.0 * float(res.get("guard_absorbed", 0.0))))}
	var blocos := int(res.get("opp_blocks", 0))
	if blocos >= 1 or (id == "adv_slippery" and int(res.get("released", 0)) >= 2):
		return {"id": id, "n": blocos}
	return {}


## Motivo da derrota das 2ªs passivas (design 7b2 §12), a 1ª que valer, na ordem da tabela. {} se nenhuma.
## cp_early | cp_held | cp_never_hurt (Contragolpista); tc_no_takedown | tc_stood_up | tc_never_hurt (Por cima);
## cl_never | cl_released | cl_held (Clinch).
func _nota_passiva2(res: Dictionary) -> Dictionary:
	match str(passiva.type):
		"counter_punch":
			var ko_de := (float(passiva.ko_from_round) - 1.0) * float(c.round_length)
			var t_fim: float = float(res.t_ko) if bool(res.ko) else float(res.t_end)  # quando a luta acabou de verdade
			if t_fim < ko_de - 1e-9:
				return {"id": "cp_early", "n": 0, "r": 0}
			if int(res.attempts) >= 1:
				return {"id": "cp_held", "n": int(res.attempts), "r": 0}
			return {"id": "cp_never_hurt", "n": 0, "r": 0}
		"top_control":
			if int(res.takedowns) == 0:
				return {"id": "tc_no_takedown", "n": 0, "r": 0}
			if int(res.stood_up) >= 2:
				return {"id": "tc_stood_up", "n": int(res.stood_up), "r": 0}
			if int(res.attempts) == 0:
				return {"id": "tc_never_hurt", "n": 0, "r": 0}
		"thai_clinch":
			if int(res.clinches) == 0:
				return {"id": "cl_never", "n": 0, "r": 0}
			if int(res.released) >= 2:
				return {"id": "cl_released", "n": int(res.released), "r": 0}
			if int(res.attempts) >= 1:
				return {"id": "cl_held", "n": int(res.attempts), "r": 0}
	return {}


## Motivo da derrota do Muay Thai (design 7b1 §11), a 1ª que valer: mt_counter | mt_marks_late | mt_held | mt_never_hurt.
func _nota_shin(res: Dictionary, tatica_id: String, vmax_j: float, t_fim: float) -> Dictionary:
	var cheia: float = res.marks_full_at
	if tatica_id == "aggressive" and float(res.opp_counter_damage) >= 0.2 * vmax_j:
		return {"id": "mt_counter", "n": mini(100, int(round(100.0 * float(res.opp_counter_damage) / vmax_j))), "r": 0}
	if cheia < 0.0 or t_fim < cheia:
		return {"id": "mt_marks_late", "n": int(res.marks_peak), "r": 0}
	if int(res.attempts) >= 1:
		return {"id": "mt_held", "n": int(res.spins), "r": 0}
	return {"id": "mt_never_hurt", "n": 0, "r": 0}


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


## Mesma conta de chance(), contando também quantas vitórias vieram da passiva (K.O., finalização ou chute rodado).
## {chance, wins, wins_passive, n}; no Muay Thai também full_share (fração das lutas em que a perna encheu) e
## full_at (mediana de marks_full_at dessas lutas; -1 se nenhuma).
## `cond` (opcional, Ronda 2a1): Callable(resultado) -> bool, contada nas MESMAS sementes em `cond_wins` (chance do desafio da noite).
func chance_detalhada(jog: Array, adv: Array, tatica_id: String, n: int = 0, cond: Callable = Callable()) -> Dictionary:
	if n <= 0:
		n = dados.risco.samples
	var cen := preparar(jog, adv, tatica_id)
	var rng := RandomNumberGenerator.new()
	var sem := PackedFloat64Array()
	var w := 0
	var wp := 0
	var cheias: Array[float] = []
	var marcas: Array[float] = []  # 7b2: Por cima / Clinch: 1º instante da queda / do clinch; Contragolpista: carga máxima de cada luta
	var wc := 0
	for s in range(1, n + 1):
		rng.seed = s
		var r := rodar(cen, rng, sem, false)
		if cond.is_valid() and bool(cond.call(r)):
			wc += 1
		if r.win:
			w += 1
			var f: String = r.get("finish", "")
			if f == "knockout" or f == "submission" or f == "spin_kick" or f == "counter_ko" or f == "ground_stop" or f == "knee_ko":
				wp += 1
		if float(r.get("marks_full_at", -1.0)) >= 0.0:
			cheias.append(float(r.marks_full_at))
		if float(r.get("takedown_at", -1.0)) >= 0.0:
			marcas.append(float(r.takedown_at))
		if float(r.get("clinch_at", -1.0)) >= 0.0:
			marcas.append(float(r.clinch_at))
		if r.has("charge_peak"):
			marcas.append(float(r.charge_peak))
	var res := {"chance": float(w) / float(n), "wins": w, "wins_passive": wp, "n": n}
	if cond.is_valid():
		res["cond_wins"] = wc
	if passiva.is_empty():
		return res
	if passiva.type == "shin":
		cheias.sort()
		res["full_share"] = float(cheias.size()) / float(n)
		res["full_at"] = cheias[cheias.size() / 2] if not cheias.is_empty() else -1.0
	elif passiva.type == "top_control" or passiva.type == "thai_clinch":
		marcas.sort()
		res["share"] = float(marcas.size()) / float(n)  # em quantas lutas derrubou / prendeu
		res["at"] = marcas[marcas.size() / 2] if not marcas.is_empty() else -1.0  # mediana do 1º instante
	elif passiva.type == "counter_punch":
		marcas.sort()
		res["charge_med"] = marcas[marcas.size() / 2] if not marcas.is_empty() else 0.0
	return res


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
