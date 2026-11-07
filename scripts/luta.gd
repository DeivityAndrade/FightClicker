class_name Luta
extends RefCounted
## Simulação determinística da luta (design fase3 §4, §6, §7). Funções puras, sem estado de jogo.
## É a porta, linha a linha, de Regras.lutar / chance / passa / motivo de tools/sim/fase3_sim.py.
## Atributos de lutador são Arrays [forca, agilidade, resistencia] (crus, os da garagem).
## Ordem dos sorteios por ataque (fixa): r_esq, r_crit, r_var (3 por ataque, mesmo que não usados).

const ATRIBUTOS: Array[String] = ["strength", "agility", "endurance"]
# Ordem de desempate do motivo: Resistência, Força, Agilidade (índices em ATRIBUTOS).
const ORDEM_MOTIVO: Array[int] = [2, 0, 1]
const NEUTRA := {"damage_mult": 1.0, "taken_mult": 1.0, "pierce": 0.0, "dodge_mult": 1.0, "dodge_bonus": 0.0,
	"counter_mult": 0.0, "crit_guard": 0.0, "block": false}

var c: Dictionary  # combate
var dados: FightData
# Fase 5: traço de luta da arte do jogador ({damage_mult, taken_mult}); neutro = sem arte.
# Multiplica a tática dele na luta e na prévia (uma função só, para o risco continuar honesto).
var traco := {"damage_mult": 1.0, "taken_mult": 1.0}


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
	return aplicar_traco(t)


## Tática do jogador com o traço de luta da arte (cópia; a original não muda).
func aplicar_traco(t: Dictionary) -> Dictionary:
	var dm := float(traco.damage_mult)
	var tm := float(traco.taken_mult)
	if dm == 1.0 and tm == 1.0:
		return t
	var r := t.duplicate()
	r["damage_mult"] = float(t.damage_mult) * dm
	r["taken_mult"] = float(t.taken_mult) * tm
	return r


## Prepara tudo o que é fixo na luta (calculado uma vez, §4.1).
func preparar(jog: Array, adv: Array, tatica_id: String) -> Dictionary:
	var ef_j := efetivos(jog)
	var ef_a := efetivos(adv)
	var tj := _tatica(tatica_id)
	return {
		"tac": [tj, NEUTRA],
		"vmax": [vida_max(ef_j), vida_max(ef_a)],
		"num": [golpe(ef_j, ef_a, tj, NEUTRA), golpe(ef_a, ef_j, NEUTRA, tj)],
		# quem tem mais Agilidade efetiva ataca primeiro; empate: o jogador
		"primeiro": 0 if ef_j[1] >= ef_a[1] else 1,
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


func _contagem(cont: Dictionary, lado: int) -> Dictionary:
	return {"attacks": cont.attacks[lado], "normal_attacks": cont.attacks[lado] - cont.counters[lado],
		"hits": cont.hits[lado], "dodges": cont.dodges[lado], "crits": cont.crits[lado],
		"damage": cont.damage[lado], "counters": cont.counters[lado]}


## Segundos de tela: intro + luta + outro (entre 8 e 19 s por construção).
func tela(res: Dictionary) -> float:
	return c.intro_seconds + res.t_end + c.outro_seconds


# --- Risco (Monte Carlo com sementes fixas 1..N) ---

func chance(jog: Array, adv: Array, tatica_id: String, n: int = 0) -> float:
	if n <= 0:
		n = dados.risco.samples
	var cen := preparar(jog, adv, tatica_id)
	var rng := RandomNumberGenerator.new()
	var sem := PackedFloat64Array()
	var w := 0
	for s in range(1, n + 1):
		rng.seed = s
		if rodar(cen, rng, sem, false).win:
			w += 1
	return float(w) / float(n)


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
