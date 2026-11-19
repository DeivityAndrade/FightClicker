extends "res://tests/test_base.gd"
## QA 7a1: prévia honesta por adversário x arte x tática, comportamento do embalo / cansaço / pegada,
## duração, valores extremos. Só números no console; nada de PNG, nada de save real.

var dados: FightData
var gym: GymData
const OPPS := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
const TATS := ["aggressive", "defensive", "counter"]


func _motor(arte: String, extra: float = 0.0) -> Luta:
	var m := Luta.new(dados)
	if arte != "":
		m.passiva = gym.arte(arte).passive.duplicate(true)
		m.extra_passiva = extra
	return m


func _opp(id: String) -> Array:
	var o := dados.adversario(id)
	return [o.strength, o.agility, o.endurance]


func rodar_testes() -> void:
	dados = FightData.carregar()
	gym = GymData.carregar()
	_honesta()
	_comportamento_boxe()
	_comportamento_jj()
	_duracao()
	_extremos()


func _honesta() -> void:
	print("## HONESTA: por adversario x arte x tatica (12 estados, 1000 lutas reais por estado; meta +-5)")
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var pior_geral := 0.0
	for arte in ["boxing", "bjj"]:
		var m := _motor(arte)
		for oid in OPPS:
			var adv := _opp(oid)
			for t in TATS:
				var soma_m := 0.0
				var soma_r := 0.0
				var pior_estado := 0.0
				var k := 12
				for i in k:
					var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.6, 1.4)
					var w := [rng.randf() + 0.3, rng.randf() + 0.3, rng.randf() + 0.3]
					var s: float = w[0] + w[1] + w[2]
					var jog := [tot * w[0] / s, tot * w[1] / s, tot * w[2] / s]
					var p: float = m.chance(jog, adv, t)
					var v := 0
					for j in 1000:
						if m.lutar(jog, adv, t, 500000 + i * 7919 + j).win:
							v += 1
					soma_m += p
					soma_r += v / 1000.0
					pior_estado = maxf(pior_estado, absf(v / 1000.0 - p))
				var dif := (soma_r - soma_m) / k * 100.0
				pior_geral = maxf(pior_geral, absf(dif))
				print("  %s %s %s: mostrada %.1f real %.1f dif %+.1f | pior estado %.1f" % [arte, oid, t, soma_m / k * 100, soma_r / k * 100, dif, pior_estado * 100])
				checar(absf(dif) <= 5.0, "honesta %s/%s/%s dif %.1f" % [arte, oid, t, dif])
	print("  pior diferenca de media: %.2f" % pior_geral)


func _comportamento_boxe() -> void:
	print("## BOXE")
	var m := _motor("boxing")
	var adv := _opp("opp_gym_1")
	var jog := [adv[0] * 1.0, adv[1] * 1.0, adv[2] * 0.9]
	for t in TATS:
		var n := 3000
		var ko := 0
		var ko_r12 := 0
		var win := 0
		var cansado_ev := 0
		var embalo_ok := true
		var zera_ok := true
		var contra := 0
		var tired_antes_r3 := 0
		var tires := 0
		var sem_cans_ok := true
		var iv_r3 := 0.0
		var cnt_iv := 0
		for s in n:
			var r := m.lutar(jog, adv, t, 10 + s, true)
			if r.win:
				win += 1
			if r.finish == "knockout":
				ko += 1
				if r.round <= 2:
					ko_r12 += 1
			if r.tires:
				tires += 1
			var ult_streak := 0
			var ult_t_j := -1.0
			for e in r.events:
				if e.streak < 0 or e.streak > 5:
					embalo_ok = false
				if e.who == 0 and e.type == "dodge":
					pass
				if e.who == 1 and e.type == "dodge":
					pass
				# jogador atacou e adversario esquivou: no evento, quem = 0, type dodge -> streak zera
				if e.who == 0 and e.type == "dodge" and e.streak != 0:
					zera_ok = false
				if e.tired:
					cansado_ev += 1
					if e.t < 10.66:
						tired_antes_r3 += 1
					if t == "defensive":
						sem_cans_ok = false
				if e.who == 1 and e.counter:
					contra += 1
		print("  %s: vitorias %.1f%% | KO passiva %.1f%% (round<=2: %d de %d) | tires=%d | cansado evs=%d antes r3=%d | contragolpes dele=%d" %
			[t, 100.0 * win / n, 100.0 * ko / n, ko_r12, ko, tires, cansado_ev, tired_antes_r3, contra])
		checar(embalo_ok, "boxe %s: embalo entre 0 e 5" % t)
		checar(zera_ok, "boxe %s: embalo zera quando ele esquiva" % t)
		checar(tired_antes_r3 == 0, "boxe %s: CANSADO so a partir do 3o round" % t)
		if t == "defensive":
			checar(tires == 0 and cansado_ev == 0, "boxe defensivo nunca cansa (tires=false, nenhum evento tired)")
		else:
			checar(tires == n and cansado_ev > 0, "boxe %s cansa" % t)
		if t == "aggressive":
			checar(contra > 0, "agressivo leva contragolpe")
		else:
			checar(contra == 0 or t == "counter", "%s: sem contragolpe especial dele" % t)
	# estado_passiva por tatica
	for t in TATS:
		var st := m.estado_passiva(jog, adv, t)
		print("  estado %s: tires=%s interval=%.3f ko_max=%.3f opp_counter=%.2f tired_at=%.2f" % [t, st.tires, st.interval, st.ko_max, st.opp_counter, st.tired_at])
	# intervalo do jogador (soco a soco) antes/depois do cansaco, defensivo e agressivo
	for t in ["aggressive", "defensive"]:
		var r := m.lutar([adv[0] * 3, adv[1] * 0.2, adv[2] * 8], adv, t, 5, true)
		var ts: Array = []
		for e in r.events:
			if e.who == 0 and not e.counter:
				ts.append(e.t)
		var ivs: Array = []
		for i in range(1, ts.size()):
			ivs.append(snappedf(ts[i] - ts[i - 1], 0.001))
		print("  intervalos do jogador (%s): %s" % [t, str(ivs)])


func _comportamento_jj() -> void:
	print("## JIU-JITSU")
	var m := _motor("bjj")
	var adv := _opp("opp_gym_1")
	for t in TATS:
		var n := 3000
		var wins := 0
		var fin := 0
		var grip_mono := true
		var grip_cheia_ok := true
		var jog := [adv[0] * 0.9, adv[1] * 0.6, adv[2] * 1.2]
		var cheia: float = m.estado_passiva(jog, adv, t).grip_full_at
		var fin_antes := 0
		for s in n:
			var r := m.lutar(jog, adv, t, 100 + s, true)
			if r.win:
				wins += 1
				if r.finish == "submission":
					fin += 1
			if r.finish == "submission" and r.t_ko < cheia - 1e-6:
				fin_antes += 1
			var ant := 0.0
			for e in r.events:
				if e.grip < ant - 1e-9:
					grip_mono = false
				ant = e.grip
				if e.t >= cheia and absf(e.grip - 1.0) > 1e-9:
					grip_cheia_ok = false
		var st := m.estado_passiva(jog, adv, t)
		print("  %s: vitorias %d (finalizacao %.0f%% das vitorias) | grip_full_at %.2f round %d | sub_chance %.2f" % [t, wins, 100.0 * fin / maxf(1.0, wins), st.grip_full_at, st.grip_round, st.sub_chance])
		checar(grip_mono and grip_cheia_ok, "jj %s: pegada monotona e 100%% a partir de t_cheia" % t)
		checar(fin_antes == 0, "jj %s: nenhuma finalizacao antes da pegada cheia" % t)
	# critério 1: 1 em 3 vitórias vs Tonhão por finalização (melhor tática, estados do verde ~0.9-1.0x)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var wins_t := 0
	var fin_t := 0
	var luta_n := 0
	var por_arte_fin := {"aggressive": [0, 0], "defensive": [0, 0], "counter": [0, 0]}
	for i in 400:
		var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.85, 1.05)
		var w := [rng.randf() + 0.5, rng.randf() + 0.5, rng.randf() + 0.5]
		var s2: float = w[0] + w[1] + w[2]
		var jg := [tot * w[0] / s2, tot * w[1] / s2, tot * w[2] / s2]
		var melhor := "aggressive"
		var pm := -1.0
		for t in TATS:
			var p := m.chance(jg, adv, t)
			if p > pm:
				pm = p
				melhor = t
		for t in [melhor, "defensive"]:
			var r := m.lutar(jg, adv, t, 9000 + i, false)
			if t == melhor:
				luta_n += 1
				if r.win:
					wins_t += 1
					if r.finish == "submission":
						fin_t += 1
			if t == "defensive":
				var pa: Array = por_arte_fin["defensive"]
				if r.win:
					pa[0] += 1
					if r.finish == "submission":
						pa[1] += 1
	print("  vs Tonhao (verde/amarelo, melhor tatica): %d vitorias de %d, finalizacao em %.0f%% das vitorias" % [wins_t, luta_n, 100.0 * fin_t / maxf(1, wins_t)])
	print("  vs Tonhao tatica DEFENSIVA fixa: finalizacao em %.0f%% das vitorias" % [100.0 * por_arte_fin["defensive"][1] / maxf(1, por_arte_fin["defensive"][0])])
	checar(float(fin_t) / maxf(1, wins_t) >= 1.0 / 3.0, "criterio 1: >= 1 em 3 vitorias vs Tonhao por finalizacao (melhor tatica)")


func _duracao() -> void:
	print("## DURACAO")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for arte in ["", "boxing", "bjj"]:
		var m := _motor(arte)
		var mn := 999.0
		var mx := 0.0
		for i in 6000:
			var adv := _opp(OPPS[i % 6])
			var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.3, 3.0)
			var w := [rng.randf() + 0.2, rng.randf() + 0.2, rng.randf() + 0.2]
			var s: float = w[0] + w[1] + w[2]
			var jog := [tot * w[0] / s, tot * w[1] / s, tot * w[2] / s]
			var r := m.lutar(jog, adv, TATS[i % 3], 1 + i, false)
			var tela := m.tela(r)
			mn = minf(mn, tela)
			mx = maxf(mx, tela)
		print("  arte '%s': tela %.2f a %.2f s" % [arte, mn, mx])
		checar(mn >= 8.0 - 1e-6 and mx <= 20.0 + 1e-6, "arte '%s': luta de 8 a 20 s (%.2f..%.2f)" % [arte, mn, mx])


func _extremos() -> void:
	print("## EXTREMOS")
	for arte in ["boxing", "bjj", ""]:
		var m := _motor(arte)
		var casos := {
			"zeros": [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]],
			"jogador zero": [[0.0, 0.0, 0.0], [100.0, 100.0, 100.0]],
			"adv zero": [[100.0, 100.0, 100.0], [0.0, 0.0, 0.0]],
			"gigante": [[1e15, 1e15, 1e15], [100.0, 100.0, 100.0]],
			"gigante adv": [[100.0, 100.0, 100.0], [1e15, 1e15, 1e15]],
			"so agilidade": [[0.0, 1e6, 0.0], [1e6, 1.0, 1e6]],
			"so forca": [[1e6, 0.0, 0.0], [1.0, 1e6, 1e6]],
		}
		for nome in casos:
			for t in ["aggressive", "defensive", "counter", "inexistente", ""]:
				var jog: Array = casos[nome][0]
				var adv: Array = casos[nome][1]
				var r := m.lutar(jog, adv, t, 3, true)
				var ok: bool = is_finite(r.t_end) and r.t_end <= 16.0 + 1e-6 and is_finite(r.pct_player) and is_finite(r.pct_opponent)
				var p := m.chance(jog, adv, t)
				ok = ok and is_finite(p) and p >= 0.0 and p <= 1.0
				var st := m.estado_passiva(jog, adv, t)
				for k in st:
					if typeof(st[k]) == TYPE_FLOAT and not is_finite(st[k]):
						ok = false
				checar(ok, "extremo '%s' arte '%s' tatica '%s' sem NaN/inf (t_end %s, chance %s)" % [nome, arte, t, r.t_end, p])
