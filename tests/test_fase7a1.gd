extends "res://tests/test_base.gd"
## Fase 7a1 (cada arte luta do seu jeito): passivas do Boxe e do Jiu-jitsu no motor (luta.gd), prévia honesta,
## golpes por arte e fases, notas de derrota e arena por local. Referência: tools/sim/fase7a1_sim.py.
## Casos exatos Python x GDScript: tests/data/fase7a1_casos.json (gerado por tools/sim/exportar_casos.py).
## Tudo em pastas de user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")
const CASOS := "res://tests/data/fase7a1_casos.json"

var dados: FightData
var gym: GymData


func rodar_testes() -> void:
	dados = FightData.carregar()
	gym = GymData.carregar()
	_teste_dados()
	_teste_python_exato()
	_teste_sem_arte_igual()
	_teste_pegada_embalo_cansaco()
	_teste_notas_de_derrota()
	_teste_previa_honesta()
	_teste_golpes_e_fases()
	_teste_arena()
	_teste_estado_e_motivo()


func _motor(arte: String, extra: float = 0.0) -> Luta:
	var m := Luta.new(dados)
	if arte != "":
		m.passiva = gym.arte(arte).passive.duplicate(true)
		m.extra_passiva = extra
	return m


func _opp(id: String) -> Array:
	var o := dados.adversario(id)
	return [o.strength, o.agility, o.endurance]


func _aprox(a: float, b: float, rel: float) -> bool:
	return absf(a - b) <= rel * maxf(maxf(absf(a), absf(b)), 1.0e-12)


func _novo(nome: String, arte: String = "") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	if arte != "":
		gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
		gs.escolher_arte(arte)
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


# --- Dados ---
func _teste_dados() -> void:
	for id in ["boxing", "bjj"]:
		var a := gym.arte(id)
		checar(not a.passive.is_empty(), "%s tem passiva" % id)
		checar(not a.has("fight"), "%s: o traço antigo (fight) saiu" % id)
		checar(not str(a.fight_text).contains("{pct}"), "%s: fight_text sem {pct}" % id)
	checar_igual(gym.arte("boxing").passive.type, "fast_hands", "Boxe: Mão rápida")
	checar_igual(gym.arte("bjj").passive.type, "submission", "Jiu-jitsu: Finalização")
	checar_igual(gym.arte("bjj").passive.tactics.defensive.grip_mult, 1.5, "Jiu-jitsu Defensivo: pegada x1,5")
	checar_igual(gym.local("garage").fight_arena, "arena", "garagem: arena")
	checar_igual(gym.local("gym").fight_arena, "arena_league", "academia: arena da liga")
	var golpes := MovesData.carregar()
	checar("takedown" in MovesData.KINDS and "submission" in MovesData.KINDS, "kinds novos takedown e submission")
	checar(golpes.golpes.has("takedown") and golpes.golpes.has("submission"), "golpes novos carregados (nada ignorado)")
	checar_igual(golpes.golpes.ground_pressure.phase, "ground", "ground_pressure é do chão")
	checar_igual(golpes.disponiveis("bjj").size(), 4, "estilo bjj: 4 golpes")
	checar_igual(golpes.disponiveis("boxing").size(), 5, "estilo boxing: os 5 de sempre")
	var tn := dados.no_da_arvore("box_counter")
	var tb := dados.no_da_arvore("bjj_guard")
	checar(tn.effect_value == 0.5 and tb.effect_value == 0.5, "nós Contragolpe e Base firme valem 0,5")


# --- Casos exatos contra o simulador Python (4 sorteios por ataque) ---
func _teste_python_exato() -> void:
	if not FileAccess.file_exists(CASOS):
		checar(false, "tests/data/fase7a1_casos.json existe (rode tools/sim/exportar_casos.py)")
		return
	var casos: Array = JSON.parse_string(FileAccess.get_file_as_string(CASOS)).exatos
	var iguais := 0
	var primeira := ""
	var fins := {}
	for c in casos:
		var m := _motor(str(c.art), float(c.extra))
		var r := m.lutar_com_sorteios(c.player, c.opponent, c.tactic, PackedFloat64Array(c.draws), true)
		var erro := _comparar(m, r, c)
		fins[str(c.art) + ":" + str(r.finish)] = true
		if erro == "":
			iguais += 1
		elif primeira == "":
			primeira = "%s (%s, %s, extra %s)" % [erro, c.art, c.tactic, str(c.extra)]
	checar_igual(iguais, casos.size(), "GDScript = Python em %d lutas com arte%s" % [casos.size(), "" if primeira == "" else " | 1ª falha: " + primeira])
	checar(fins.has("boxing:knockout") and fins.has("bjj:submission"), "os casos cobrem nocaute e finalização pela passiva")


# O Python marca "dano" / "dano_dele" no evento; o GDScript só marca a finalização pela passiva ("" = dano ou nada).
func _fim_py(f: String) -> String:
	return "knockout" if f == "nocaute" else ("submission" if f == "finalizacao" else "")


func _comparar(m: Luta, r: Dictionary, c: Dictionary) -> String:
	if r.win != c.win or r.ko != c.ko or r.finish != c.finish:
		return "resultado (win/ko/finish)"
	if absf(r.t_ko - c.t_ko) > 1e-9 or absf(r.t_end - c.t_end) > 1e-9:
		return "t_ko/t_end"
	if not _aprox(r.pct_player, c.pct_player, 1e-9) or not _aprox(r.pct_opponent, c.pct_opponent, 1e-9):
		return "% de vida"
	if r.draws_used != c.draws.size():
		return "sorteios consumidos %d x %d" % [r.draws_used, c.draws.size()]
	if r.events.size() != c.events.size():
		return "número de eventos"
	for i in r.events.size():
		var e: Dictionary = r.events[i]
		var p: Array = c.events[i]
		if absf(e.t - p[0]) > 6e-4 or e.who != int(p[1]) or e.type != p[2] or e.counter != p[3] or e.streak != int(p[6]) or e.finish != _fim_py(str(p[7])):
			return "evento %d" % i
		if e.type != "dodge" and (not _aprox(e.damage, p[4], 1e-7) or not _aprox(e.life_after, p[5], 1e-7)):
			return "dano/vida do evento %d" % i
	var k: Dictionary = c.counts
	var cj: Dictionary = r.counts.player
	var co: Dictionary = r.counts.opponent
	if cj.hits != int(k.acertos[0]) or co.hits != int(k.acertos[1]) or cj.dodges != int(k.esquivas[0]) \
			or co.dodges != int(k.esquivas[1]) or cj.crits != int(k.crits[0]) or co.crits != int(k.crits[1]) \
			or cj.counters != int(k.contras[0]) or co.counters != int(k.contras[1]):
		return "contagens"
	if r.streak_peak != int(c.streak_peak) or r.attempts != int(c.attempts) or not _aprox(r.opp_counter_damage, c.opp_counter_damage, 1e-7):
		return "pico de embalo / tentativas / dano de contragolpe"
	var est := m.estado_passiva(c.player, c.opponent, c.tactic)
	for chave in c.est:
		if typeof(c.est[chave]) == TYPE_STRING:
			if est[chave] != c.est[chave]:
				return "estado_passiva." + chave
		elif not _aprox(float(est[chave]), float(c.est[chave]), 1e-9):
			return "estado_passiva." + chave
	return ""


# --- Sem arte: laço de sempre (3 sorteios), sem campos de arte ---
func _teste_sem_arte_igual() -> void:
	var m := _motor("")
	var sorteios := PackedFloat64Array()
	for i in 400:
		sorteios.append(0.5)
	var r := m.lutar_com_sorteios([5000.0, 4000.0, 6000.0], _opp("opp_gym_1"), "aggressive", sorteios, true)
	checar_igual(r.draws_used, 3 * r.events.size(), "sem arte: 3 sorteios por ataque")
	checar(not r.has("finish"), "sem arte: o resultado não ganha campos da arte")
	checar(m.estado_passiva([1.0, 1.0, 1.0], [1.0, 1.0, 1.0], "aggressive").is_empty(), "sem arte: estado_passiva vazio")
	for arte in ["boxing", "bjj"]:
		var ma := _motor(arte)
		var ra := ma.lutar_com_sorteios([5000.0, 4000.0, 6000.0], _opp("opp_gym_1"), "aggressive", sorteios, true)
		checar_igual(ra.draws_used, 4 * ra.events.size(), "%s: 4 sorteios por ataque" % arte)


func _tudo_acerta(n: int, r_arte: float) -> PackedFloat64Array:
	# esquiva nunca (0,99), crítico nunca (0,99), variação 0,5 e r_arte dado
	var s := PackedFloat64Array()
	for i in n:
		s.append_array(PackedFloat64Array([0.99, 0.99, 0.5, r_arte]))
	return s


# --- Pegada, embalo e cansaço ---
func _teste_pegada_embalo_cansaco() -> void:
	var adv := _opp("opp_gym_1")
	var fort := [adv[0] * 1.5, adv[1], adv[2] * 1.5]
	# Pegada: o 1º acerto que finaliza só vem com a pegada cheia (t >= t_cheia da prévia) e ela cresce linear.
	for tat in ["defensive", "counter", "aggressive"]:
		var mj := _motor("bjj")
		var est := mj.estado_passiva(fort, adv, tat)
		var r := mj.lutar_com_sorteios(fort, adv, tat, _tudo_acerta(80, 0.0), true)
		if r.finish == "submission":
			checar(r.t_ko >= est.grip_full_at - 1e-9, "JJ %s: finaliza só depois da pegada encher (%.2f >= %.2f)" % [tat, r.t_ko, est.grip_full_at])
			checar_igual(r.events[-1].grip, 1.0, "JJ %s: pegada 1,0 ao finalizar" % tat)
		var e0: Dictionary = r.events[0]
		checar(absf(e0.grip - minf(1.0, e0.t / est.grip_full_at)) < 1e-12, "JJ %s: pegada = t / t_cheia" % tat)
		checar_igual(r.grip_full_at, est.grip_full_at, "JJ %s: resultado traz grip_full_at" % tat)
	var e_def := _motor("bjj").estado_passiva(fort, adv, "defensive")
	var e_agr := _motor("bjj").estado_passiva(fort, adv, "aggressive")
	checar(e_def.grip_full_at < e_agr.grip_full_at, "Defensivo enche a pegada antes do Agressivo")
	checar(absf(e_def.grip_full_at / e_agr.grip_full_at - 0.75 / 1.5) < 1e-9 or e_def.grip_rate >= 1.0 - 1e-9, "pegada: taxa x1,5 contra x0,75")
	var base := _motor("bjj").estado_passiva(fort, adv, "counter")
	var com_no := _motor("bjj", 0.5).estado_passiva(fort, adv, "counter")
	checar(com_no.grip_full_at < base.grip_full_at, "Base firme: a pegada enche mais rápido")
	checar(com_no.grip_rate <= 1.0 + 1e-9, "pegada respeita o teto de 1,0 por round")
	# Embalo: sobe 1 por acerto, teto 5; esquiva do adversário zera; Contra-ataque dá +2 no contragolpe.
	var mb := _motor("boxing")
	var rb := mb.lutar_com_sorteios(fort, adv, "defensive", _tudo_acerta(60, 1.0), true)
	var ult := 0
	var subiu_ok := true
	for e in rb.events:
		if e.who == 0 and e.type != "dodge":
			subiu_ok = subiu_ok and e.streak == mini(5, ult + 1)
			ult = e.streak
	checar(subiu_ok and rb.streak_peak == 5, "embalo: +1 por acerto, teto 5")
	# esquiva dele no 3º ataque do jogador: sorteio r_esq baixo para o ataque nº k do jogador
	var s := _tudo_acerta(60, 1.0)
	var mb2 := _motor("boxing")
	var rb0 := mb2.lutar_com_sorteios(fort, adv, "defensive", s, true)
	var idx_j: Array = []
	for i in rb0.events.size():
		if rb0.events[i].who == 0:
			idx_j.append(i)
	s[idx_j[3] * 4] = 0.0  # o 4º ataque do jogador é esquivado
	var rb3 := mb2.lutar_com_sorteios(fort, adv, "defensive", s, true)
	checar(rb3.events[idx_j[3]].type == "dodge" and rb3.events[idx_j[3]].streak == 0, "embalo zera quando ele esquiva")
	checar_igual(rb3.events[idx_j[4]].streak, 1, "depois da esquiva o embalo recomeça em 1")
	# Cansaço: intervalo do jogador a partir de 10,67 s = 1,98 s (Defensivo: 1,80 s).
	for tat in ["aggressive", "defensive"]:
		var mc := _motor("boxing")
		var forte := [adv[0] * 0.3, adv[1], adv[2] * 3.0]  # luta longa: dano pequeno, vida grande
		var rc := mc.lutar_com_sorteios(forte, adv, tat, _tudo_acerta(60, 1.0), true)
		var ts: Array = []
		for e in rc.events:
			if e.who == 0 and not e.counter:
				ts.append(e.t)
		var tired_ok := true
		var passo_depois := 0.0
		for i in range(1, ts.size()):
			if ts[i - 1] >= 10.6667 and passo_depois == 0.0:
				passo_depois = ts[i] - ts[i - 1]
		for e in rc.events:
			if e.who == 0:
				tired_ok = tired_ok and (e.tired == (tat != "defensive" and e.t >= 10.6667 - 1e-6))
		checar(tired_ok, "Boxe %s: flag tired liga em 10,67 s (Defensivo nunca)" % tat)
		checar_igual(rc.tires, tat != "defensive", "Boxe %s: resultado traz tires" % tat)
		checar_igual(mc.estado_passiva(forte, adv, tat).tires, tat != "defensive", "Boxe %s: estado_passiva.tires" % tat)
		var esperado := 1.8 if tat == "defensive" else 1.98
		checar(passo_depois == 0.0 or absf(passo_depois - esperado) < 1e-6, "Boxe %s: soco a cada %.2f s depois de cansar (%.4f)" % [tat, esperado, passo_depois])
		checar_igual(rc.tired_at, 2.0 * float(dados.combate.round_length), "Boxe: tired_at = início do 3º round")
	# Velocidade pela AGILIDADE: mais agilidade, menos intervalo (rounds 1-2).
	var lento := _motor("boxing").estado_passiva([1000.0, 100.0, 1000.0], [1000.0, 5000.0, 1000.0], "counter")
	var agil := _motor("boxing").estado_passiva([1000.0, 5000.0, 1000.0], [1000.0, 100.0, 1000.0], "counter")
	checar(absf(lento.interval - 1.8) < 1e-9 and absf(agil.interval - 1.44 / 1.25) < 1e-9, "Boxe: intervalo de 1,80 s a 1,15 s pela AGILIDADE")
	var igual := _motor("boxing").estado_passiva([1000.0, 1000.0, 1000.0], [1000.0, 1000.0, 1000.0], "counter")
	checar(absf(igual.interval - 1.44) < 1e-9, "Boxe: agilidade igual = 1,44 s")
	# Agressivo: o adversário ganha contragolpe (counter_mult 0,8) só no Boxe.
	var cen_b: Dictionary = _motor("boxing").preparar(fort, adv, "aggressive")
	checar_igual(cen_b.tac[1].counter_mult, 0.8, "Boxe Agressivo: ele contragolpeia")
	var cen_b2: Dictionary = _motor("boxing").preparar(fort, adv, "defensive")
	checar_igual(cen_b2.tac[1].counter_mult, 0.0, "Boxe Defensivo: ele não contragolpeia")
	var cen_j: Dictionary = _motor("bjj").preparar(fort, adv, "aggressive")
	checar_igual(cen_j.tac[1].counter_mult, 0.0, "Jiu-jitsu: ele não ganha contragolpe")
	# Dano: Boxe x0,88, Jiu-jitsu x1,20 (o traço antigo saiu).
	var sem := _motor("")
	var n_sem: Array = sem.preparar(fort, adv, "defensive").num
	var n_bx: Array = _motor("boxing").preparar(fort, adv, "defensive").num
	var n_jj: Array = _motor("bjj").preparar(fort, adv, "defensive").num
	checar(absf(n_bx[0][0] / n_sem[0][0] - 0.88) < 1e-9 and absf(n_bx[1][0] - n_sem[1][0]) < 1e-9, "Boxe: dano x0,88, recebido igual")
	checar(absf(n_jj[0][0] / n_sem[0][0] - 1.20) < 1e-9 and absf(n_jj[1][0] - n_sem[1][0]) < 1e-9, "Jiu-jitsu: dano x1,20, recebido igual")


# --- passive_note: uma por id, na ordem do design ---
func _teste_notas_de_derrota() -> void:
	var mb := _motor("boxing")
	var mj := _motor("bjj")
	var base := {"ahead_at_tired": true, "finish": "points", "life_max": [1000.0, 1000.0], "t_end": 16.0, "opp_counter_damage": 0.0, "streak_peak": 5,
		"attempts": 0, "grip_full_at": -1.0, "tired_at": 10.6667}
	var r := base.duplicate()
	r.opp_counter_damage = 250.0
	var n := mb.nota_passiva(r, "aggressive")
	checar(n.id == "boxing_counter" and n.n == 25, "nota boxing_counter (25%%): %s" % str(n))
	checar(mb.nota_passiva(r, "defensive").is_empty(), "Defensivo: contragolpe só conta no Agressivo e ele não cansa: sem nota")
	r = base.duplicate()
	checar_igual(mb.nota_passiva(r, "aggressive").id, "boxing_tired", "nota boxing_tired (chegou cansado ao 3º round)")
	r.ahead_at_tired = false
	checar(mb.nota_passiva(r, "aggressive").is_empty(), "já estava atrás ao cansar: o cansaço não pesou, sem nota")
	r.ahead_at_tired = true
	r.t_end = 8.0
	checar(mb.nota_passiva(r, "aggressive").is_empty(), "perdeu cedo, embalo alto: sem nota")
	r.streak_peak = 2
	n = mb.nota_passiva(r, "aggressive")
	checar(n.id == "boxing_streak" and n.n == 2, "nota boxing_streak (pico 2)")
	r = base.duplicate()
	r.streak_peak = 1
	r.t_end = 16.0
	checar_igual(mb.nota_passiva(r, "defensive").id, "boxing_streak", "Defensivo não cansa: nota de embalo")
	# Jiu-jitsu
	var j := {"finish": "points", "life_max": [1000.0, 1000.0], "t_end": 5.0, "opp_counter_damage": 0.0, "streak_peak": 0,
		"attempts": 0, "grip_full_at": 10.6667, "tired_at": -1.0}
	n = mj.nota_passiva(j, "counter")
	checar(n.id == "bjj_grip_late" and n.r == 3, "nota bjj_grip_late (10,67 s = já no 3º round)")
	j.t_end = 16.0
	checar_igual(mj.nota_passiva(j, "counter").id, "bjj_never_hurt", "nota bjj_never_hurt")
	j.attempts = 3
	n = mj.nota_passiva(j, "counter")
	checar(n.id == "bjj_escaped" and n.n == 3, "nota bjj_escaped (3 vezes)")
	j.grip_full_at = 20.0
	checar_igual(mj.nota_passiva(j, "aggressive").id, "bjj_grip_late", "pegada que não enche em 16 s: bjj_grip_late")
	checar(_motor("").nota_passiva(j, "aggressive").is_empty(), "sem arte: sem nota")
	# Textos (as chaves do Roteirista existem em ui_texts.json)
	var gs := _novo("f7a1_notas", "bjj")
	checar_igual(gs._textos._dec(1.52, 2), "1,52", "decimal com vírgula")
	var um: Dictionary = gs._textos.passiva_nota_textos({"id": "bjj_escaped", "n": 1, "r": 2}, 0)
	checar(str(um.text).contains("1 VEZ") and not str(um.text).contains("VEZES"), "singular: 1 VEZ (%s)" % um.text)
	var t: Dictionary = gs._textos.passiva_nota_textos({"id": "bjj_escaped", "n": 3, "r": 2}, 1)
	checar(str(t.text).contains("3") and str(t.tip) != "", "texto e dica da nota bjj_escaped")
	for id in ["boxing_counter", "boxing_tired", "boxing_streak", "bjj_grip_late", "bjj_escaped", "bjj_never_hurt"]:
		var tt: Dictionary = gs._textos.passiva_nota_textos({"id": id, "n": 1, "r": 1}, 0)
		checar(str(tt.text) != "" and str(tt.tip) != "", "textos da nota %s existem" % id)
	_liberar(gs)


# --- Prévia honesta: chance mostrada = a do motor; vitórias reais dentro de ±5 pontos ---
func _teste_previa_honesta() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 321
	for arte in ["boxing", "bjj"]:
		var gs := _novo("f7a1_previa_" + arte, arte)
		gs.indice_escada = 3
		var soma_dif := 0.0
		var pior := 0.0
		var estados := 0
		for oid in ["opp_gym_1", "opp_gym_2", "opp_tank"]:
			var adv := _opp(oid)
			for k in 2:
				var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.8, 1.1)
				var w := [rng.randf() + 0.4, rng.randf() + 0.4, rng.randf() + 0.4]
				var s: float = w[0] + w[1] + w[2]
				var jog := [tot * w[0] / s, tot * w[1] / s, tot * w[2] / s]
				var tat: String = ["aggressive", "defensive", "counter"][(k + estados) % 3]
				var p: float = gs.motor.chance(jog, adv, tat)
				var det: Dictionary = gs.motor.chance_detalhada(jog, adv, tat)
				checar_igual(det.chance, p, "chance_detalhada = chance (%s)" % arte)
				var v := 0
				var n := 1000
				for i in n:
					if gs.motor.lutar(jog, adv, tat, 100000 + i).win:
						v += 1
				var dif := float(v) / n - p
				soma_dif += dif
				pior = maxf(pior, absf(dif))
				estados += 1
		checar(absf(soma_dif / estados) <= 0.03, "%s: diferença média prévia x real %.1f pontos (<= 3)" % [arte, 100.0 * soma_dif / estados])
		checar(pior <= 0.08, "%s: pior estado %.1f pontos (<= 8, ruído da prévia de 200 sementes incluído)" % [arte, 100.0 * pior])
		# previa() do jogo traz os campos passive_* e o mesmo número do motor
		var pv: Dictionary = gs.previa()
		checar(not pv.is_empty(), "%s: previa() disponível" % arte)
		if not pv.is_empty():
			for campo in ["passive_name", "passive_line", "passive_state", "passive_share", "passive_share_n", "passive_tactics"]:
				checar(pv.has(campo), "%s: previa() tem %s" % [arte, campo])
			var jog_gs: Array = [gs.atributos.get("strength", 0.0), gs.atributos.get("agility", 0.0), gs.atributos.get("endurance", 0.0)]
			var opp: Dictionary = pv.opponent
			for t in ["aggressive", "defensive", "counter"]:
				checar_igual(pv.risks[t].chance, gs.motor.chance(jog_gs, [opp.strength, opp.agility, opp.endurance], t),
					"%s: risco da prévia = motor (%s)" % [arte, t])
				checar(pv.passive_tactics.has(t) and str(pv.passive_tactics[t].line) != "", "%s: linha da passiva da tática %s" % [arte, t])
		_liberar(gs)
	var sem := _novo("f7a1_previa_sem")
	sem.indice_escada = 3
	var pv2: Dictionary = sem.previa()
	checar(not pv2.is_empty() and not pv2.has("passive_name") and pv2.art_fight_text == "", "sem arte: previa() sem campos da passiva")
	_liberar(sem)


# --- Golpes por arte e fases (queda, chão, finalização) ---
func _teste_golpes_e_fases() -> void:
	var gs := _novo("f7a1_fases", "bjj")
	var adv := _opp("opp_gym_1")
	var jog := [adv[0] * 1.2, adv[1], adv[2] * 1.2]
	var achou := false
	for semente in range(1, 400):
		var res: Dictionary = gs.motor.lutar(jog, adv, "defensive", semente, false)
		if res.finish != "submission":
			continue
		achou = true
		gs.luta = {"opponent": "opp_gym_1", "tactic": "defensive", "seed": semente,
			"player": {"strength": jog[0], "agility": jog[1], "endurance": jog[2]}, "result": gs._luta._resultado_salvo(res)}
		var info: Dictionary = gs.luta_atual()
		checar_igual(info.passive, "submission", "luta_atual: passive = submission")
		checar_igual(info.result.finish, "submission", "luta_atual: result.finish")
		checar_igual(info.arena, "arena_league", "luta contra o Tonhão: arena da liga")
		var ev: Array = info.events
		var visto_queda := false
		var fases_ok := true
		var ult_fase := "standing"
		for e in ev:
			if e.phase == "ground" and ult_fase == "standing":
				fases_ok = false  # só pode ir para o chão pelo evento da queda (phase_after)
			if e.kind == "takedown":
				visto_queda = true
				fases_ok = fases_ok and e.phase == "standing" and e.phase_after == "ground" and e.who == 0 and e.grip >= 0.5
				fases_ok = fases_ok and gs.golpes.golpes[e.move].anim == "takedown"
			elif not visto_queda and e.type != "dodge":
				fases_ok = fases_ok and e.phase == "standing" and (e.who == 1 or gs.golpes.golpes[e.move].anim == "clinch_push")
			elif visto_queda and e.type != "dodge" and e.kind != "submission":
				fases_ok = fases_ok and e.phase == "ground"
				fases_ok = fases_ok and (gs.golpes.golpes[e.move].anim == ("ground_pressure" if e.who == 0 else "ground_punch"))
			ult_fase = e.phase_after
		checar(fases_ok, "fases: em pé (clinch) até a queda, depois chão (pressão / soco de baixo)")
		var ultimo: Dictionary = ev[-1]
		checar(ultimo.kind == "submission" and ultimo.finish == "submission" and gs.golpes.golpes[ultimo.move].anim == "submission", "último golpe: finalização")
		checar_igual(ultimo.defender_move_anim, "tap_out", "o adversário bate no chão (tap_out)")
		checar(ultimo.ko, "evento final marcado como K.O.")
		break
	checar(achou, "achou uma luta com finalização para checar as fases")
	_liberar(gs)
	# Boxe e sem arte seguem com os golpes de boxe, sempre em pé
	for arte in ["boxing", ""]:
		var g2 := _novo("f7a1_fases_box" + arte, arte)
		var res2: Dictionary = g2.motor.lutar([5000.0, 4000.0, 6000.0], adv, "aggressive", 77, false)
		g2.luta = {"opponent": "opp_gym_1", "tactic": "aggressive", "seed": 77,
			"player": {"strength": 5000.0, "agility": 4000.0, "endurance": 6000.0}, "result": g2._luta._resultado_salvo(res2)}
		var ok := true
		for e in g2.luta_atual().events:
			ok = ok and e.phase == "standing"
			if e.who == 0 and e.move != "":
				ok = ok and g2.golpes.golpes[e.move].style == "boxing"
		checar(ok, "arte '%s': golpes de boxe, sempre em pé" % arte)
		_liberar(g2)


# --- Arena por local do adversário ---
func _teste_arena() -> void:
	var gs := _novo("f7a1_arena")
	for id in ["opp_warmup", "opp_strong", "opp_fast", "opp_tank"]:
		checar_igual(gs.arena_da_luta(id), "arena", "%s luta na borracharia" % id)
	for id in ["opp_gym_1", "opp_gym_2"]:
		checar_igual(gs.arena_da_luta(id), "arena_league", "%s luta na liga da academia" % id)
	checar_igual(gs.arena_da_luta("nao_existe"), "arena", "adversário desconhecido: arena padrão")
	# quem já mudou continua enfrentando os amadores na borracharia
	gs.local_id = "gym"
	checar_igual(gs.arena_da_luta("opp_warmup"), "arena", "na academia, amador ainda na borracharia")
	_liberar(gs)


# --- Estado salvo (finish opcional) e motivo ---
func _teste_estado_e_motivo() -> void:
	var gs := _novo("f7a1_motivo", "boxing")
	gs.indice_escada = 4
	var jog := [3000.0, 2000.0, 3000.0]
	var adv := _opp("opp_gym_2")
	var snap := {"opponent": "opp_gym_2", "tactic": "aggressive", "seed": 5,
		"player": {"strength": jog[0], "agility": jog[1], "endurance": jog[2]}, "result": {}}
	var m: Dictionary = gs._luta._calcular_motivo(snap)
	checar(m.has("passive_note"), "com arte: o motivo traz passive_note")
	var sem := _novo("f7a1_motivo_sem")
	var m2: Dictionary = sem._luta._calcular_motivo(snap)
	checar(not m2.has("passive_note"), "sem arte: o motivo não tem passive_note (igual a antes)")
	# luta com arte salva o `finish`; carregar o save devolve o mesmo
	gs.atributos = {"strength": 90000.0, "agility": 60000.0, "endurance": 500000.0}
	gs.indice_escada = 3
	gs.autosave_ativo = false
	var info: Dictionary = gs.lutar()
	if not info.is_empty():
		checar(gs.luta.result.has("finish"), "luta com arte grava result.finish")
		gs.salvar()
		var g3: Node = GameStateScript.new()
		g3.inicializar(gs.store.pasta, "res://data/config.json")
		g3.autosave_ativo = false
		checar_igual(g3.luta.get("result", {}).get("finish", ""), gs.luta.result.finish, "finish sobrevive ao salvar e carregar")
		_liberar(g3)
		# save editado à mão: finish que não bate com a arte (Boxe não finaliza) ou com ko é descartado
		for ruim in ["submission", "points" if gs.luta.result.ko else "damage", "lixo"]:
			gs.luta.result["finish"] = ruim
			gs.salvar()
			var g4: Node = GameStateScript.new()
			g4.inicializar(gs.store.pasta, "res://data/config.json")
			g4.autosave_ativo = false
			checar(not g4.luta.get("result", {"finish": 1}).has("finish"), "finish incoerente '%s' descartado na carga" % ruim)
			_liberar(g4)
	sem.indice_escada = 3
	sem.atributos = {"strength": 90000.0, "agility": 60000.0, "endurance": 500000.0}
	if not sem.lutar().is_empty():
		checar(not sem.luta.result.has("finish"), "sem arte: result sem finish (save igual ao de antes)")
		checar_igual(sem.luta_atual().result.finish, "damage" if sem.luta.result.ko else "points", "sem arte: luta_atual preenche finish")
	_liberar(gs)
	_liberar(sem)
