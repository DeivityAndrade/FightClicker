extends "res://tests/test_base.gd"
## Fase 7b2 (2ª passiva das 3 artes): motor dos 3 ramos novos (casos exatos contra o simulador Python), 1ª passiva e luta sem arte
## intactas, prévia honesta, meta (3 vitórias pela 1ª passiva, somando a linhagem), escolha da passiva, save antigo, notas de derrota
## e campos da luta na tela. Referência: tools/sim/fase7b2_sim.py e docs/fases/fase7b2-design.md.
## Casos exatos: tests/data/fase7b2_casos.json (360 lutas; gerado por `fase7b2_sim.py exportar`). Tudo em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")
const CASOS := "res://tests/data/fase7b2_casos.json"
const TATICAS := ["aggressive", "defensive", "counter"]
const TIPOS := {"boxing": "counter_punch", "bjj": "top_control", "muay_thai": "thai_clinch"}
const FINS := {"boxing": "counter_ko", "bjj": "ground_stop", "muay_thai": "knee_ko"}
const FIM_META := {"boxing": "knockout", "bjj": "submission", "muay_thai": "spin_kick"}
const FIM_PY := {"": "", "dano": "", "dano_dele": "", "contragolpe_ko": "counter_ko", "por_cima": "ground_stop", "joelhada": "knee_ko"}

var dados: FightData
var gym: GymData


func rodar_testes() -> void:
	dados = FightData.carregar()
	gym = GymData.carregar()
	_teste_dados()
	_teste_python_exato()
	_teste_invariantes()
	_teste_nada_muda()
	_teste_previa_honesta()
	_teste_notas_de_derrota()
	_teste_meta()
	_teste_escolha()
	_teste_save_antigo()
	_teste_luta_na_tela()
	_teste_nos_da_arvore()


func _motor(arte: String, passiva: int, extra: float = 0.0) -> Luta:
	var m := Luta.new(dados)
	if arte != "":
		m.passiva = gym.arte(arte).get("passive" if passiva == 1 else "passive_2").duplicate(true)
		m.extra_passiva = extra
	return m


func _opp(id: String) -> Array:
	var o := dados.adversario(id)
	return [o.strength, o.agility, o.endurance]


func _aprox(a: float, b: float, rel: float) -> bool:
	return absf(a - b) <= rel * maxf(maxf(absf(a), absf(b)), 1.0e-12)


func _novo(nome: String, arte: String = "", passiva: int = 0) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	if arte != "":
		gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		if passiva == 2:
			_liberar_2a(gs, arte)
		gs.escolher_arte(arte, passiva)
	return gs


func _liberar_2a(gs: Node, arte: String) -> void:
	gs.permanente["passive_wins"][arte] = 3
	gs.permanente["passives_unlocked"].append(arte)


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


# --- Dados ---
func _teste_dados() -> void:
	for arte in TIPOS:
		var a := gym.arte(arte)
		var p2: Dictionary = a.passive_2
		checar(not p2.is_empty() and p2.type == TIPOS[arte], "%s: passive_2 %s" % [arte, TIPOS[arte]])
		checar_igual(int(p2.unlock.count), 3, "%s: meta de 3 vitórias (decisão do dono)" % arte)
		checar_igual(str(p2.unlock.finish), FIM_META[arte], "%s: a meta conta %s" % [arte, FIM_META[arte]])
		checar(str(p2.name) != "" and str(p2.fight_text) != "" and str(p2.icon) != "", "%s: nome, texto e ícone da 2ª" % arte)
		checar(not a.passive.is_empty(), "%s: a 1ª passiva continua lá" % arte)
	checar(is_equal_approx(float(gym.arte("boxing").passive_2.damage_mult), 0.80) and int(gym.arte("boxing").passive_2.charge_max) == 3, "Contragolpista: dano x0,80 e carga 3")
	checar(is_equal_approx(float(gym.arte("muay_thai").passive_2.clinch_s), 3.5), "Clinch: 3,5 s")
	for k in ["counter_ko", "ground_stop", "knee_ko"]:
		checar(k in MovesData.KINDS, "kind %s em MovesData" % k)
	# GymData recorta o ruim e recusa 2ª passiva sem meta válida
	var ruim := {"arts": [
		{"id": "x", "passive_2": {"type": "top_control", "unlock": {"type": "passive_wins", "count": 3, "finish": "submission"}, "td_base": 9.0, "stop_chance": -2}},
		{"id": "y", "passive_2": {"type": "top_control"}},
		{"id": "z", "passive_2": {"type": "nada", "unlock": {"type": "passive_wins", "count": 3, "finish": "x"}}}]}
	var tmp := "user://test/arts_ruim2.json"
	DirAccess.make_dir_recursive_absolute("user://test")
	escrever(tmp, JSON.stringify(ruim))
	var g2 := GymData.carregar("res://data/locations.json", tmp)
	checar(float(g2.arte("x").passive_2.td_base) == 1.0 and float(g2.arte("x").passive_2.stop_chance) == 0.0, "passive_2 recortada (chances 0-1)")
	checar(g2.arte("y").passive_2.is_empty() and g2.arte("z").passive_2.is_empty(), "passive_2 sem meta válida ou de tipo desconhecido = arte sem 2ª passiva")
	DirAccess.remove_absolute(tmp)


# --- Casos exatos contra o simulador Python (4 sorteios por ataque) ---
func _teste_python_exato() -> void:
	if not FileAccess.file_exists(CASOS):
		checar(false, "tests/data/fase7b2_casos.json existe (rode tools/sim/fase7b2_sim.py exportar)")
		return
	var casos: Array = JSON.parse_string(FileAccess.get_file_as_string(CASOS)).exatos
	var iguais := 0
	var primeira := ""
	var fins := {}
	for c in casos:
		var m := _motor(str(c.art), int(c.passive), float(c.extra))
		var r := m.lutar_com_sorteios(c.player, c.opponent, c.tactic, PackedFloat64Array(c.draws), true)
		var erro := _comparar(m, r, c)
		fins[str(c.art) + ":" + str(r.finish)] = true
		if erro == "":
			iguais += 1
		elif primeira == "":
			primeira = "%s (%s, %s, extra %s)" % [erro, c.art, c.tactic, str(c.extra)]
	checar_igual(iguais, casos.size(), "GDScript = Python em %d lutas das 2ªs passivas%s" % [casos.size(), "" if primeira == "" else " | 1ª falha: " + primeira])
	checar_igual(casos.size(), 360, "360 casos exatos")
	for arte in FINS:
		checar(fins.has(arte + ":" + FINS[arte]) and fins.has(arte + ":damage") and fins.has(arte + ":points"),
			"%s: os casos cobrem %s, dano e pontos" % [arte, FINS[arte]])


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
		var flag: bool = bool(e.get("ground", false)) or bool(e.get("clinch", false))
		if absf(e.t - p[0]) > 6e-4 or e.who != int(p[1]) or e.type != p[2] or e.counter != p[3] or int(e.get("charge", 0)) != int(p[6]) \
				or flag != bool(p[7]) or e.move != str(p[8]) or e.finish != str(FIM_PY.get(str(p[9]), "?")):
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
	if r.attempts != int(c.attempts) or not _aprox(r.opp_counter_damage, float(k.dano_contra[1]), 1e-7):
		return "tentativas / contragolpe dele"
	if c.has("carga_pico") and r.charge_peak != int(c.carga_pico):
		return "carga máxima"
	if c.has("quedas") and (r.takedowns != int(c.quedas) or r.stood_up != int(c.levantou) or not _aprox(r.takedown_at, float(c.queda_em), 1e-9)):
		return "quedas / levantou"
	if c.has("clinches") and (r.clinches != int(c.clinches) or r.released != int(c.soltou) or r.knees != int(c.joelhadas) \
			or not _aprox(r.clinch_at, float(c.clinch_em), 1e-9)):
		return "clinches / soltou / joelhadas"
	var est := m.estado_passiva(c.player, c.opponent, c.tactic)
	for chave in c.est:
		if typeof(c.est[chave]) == TYPE_STRING:
			if est[chave] != c.est[chave]:
				return "estado_passiva." + chave
		elif not _aprox(float(est[chave]), float(c.est[chave]), 1e-9):
			return "estado_passiva." + chave
	return ""


# --- Regras que valem em qualquer luta (sementes de verdade) ---
func _teste_invariantes() -> void:
	var ruim := {}
	var ko_de: float = (3.0 - 1.0) * float(dados.combate.round_length)
	for arte in TIPOS:
		var m := _motor(arte, 2)
		var vistos := {}
		for oid in ["opp_tank", "opp_fast", "opp_gym_1", "opp_gym_2"]:
			var adv := _opp(oid)
			for mult in [0.6, 0.9, 1.2]:
				var jog := [adv[0] * mult, adv[1] * mult, adv[2] * mult]
				for tat in TATICAS:
					for s in range(1, 41):
						var r := m.lutar(jog, adv, tat, s, false)
						vistos[str(r.finish)] = int(vistos.get(str(r.finish), 0)) + 1
						if r.draws_used != 0 or not r.has("attempts") or r.has("marks_peak") or r.has("spins"):
							ruim[arte + " campos"] = true
						if r.finish == "counter_ko" and (r.t_ko < ko_de - 1e-9 or not r.win):
							ruim["counter_ko antes do 3º round ou derrota"] = true
						if r.finish == "ground_stop" and (r.takedowns < 1 or r.pct_opponent > 0.5 + 1e-9 or not r.win):
							ruim["ground_stop sem queda ou com ele acima de 50%"] = true
						if r.finish == "knee_ko" and (r.clinches < 1 or r.pct_opponent > 0.4 + 1e-9 or not r.win):
							ruim["knee_ko sem clinch ou com ele acima de 40%"] = true
						if arte == "boxing" and (r.tires or r.tired_at >= 0.0):
							ruim["Contragolpista cansa"] = true
						if r.finish in ["knockout", "submission", "spin_kick"]:
							ruim["fim da 1ª passiva na 2ª"] = true
		checar(not vistos.has("points") or vistos.size() >= 2, "%s: lutas acabam de mais de um jeito (%s)" % [arte, str(vistos)])
	checar(ruim.is_empty(), "regras do laço das 2ªs passivas%s" % ("" if ruim.is_empty() else ": " + str(ruim.keys())))
	# a mesma semente dá a mesma luta; luta com registro = luta sem registro
	for arte in TIPOS:
		var m := _motor(arte, 2)
		var adv := _opp("opp_gym_2")
		var jog := [adv[0] * 0.9, adv[1] * 0.9, adv[2] * 0.9]
		var a := m.lutar(jog, adv, "aggressive", 77, true)
		var b := m.lutar(jog, adv, "aggressive", 77, false)
		checar(a.win == b.win and a.finish == b.finish and is_equal_approx(a.t_end, b.t_end), "%s: registrar eventos não muda a luta" % arte)


# --- Sem arte e 1ª passiva: nada muda ---
func _teste_nada_muda() -> void:
	var s := PackedFloat64Array()
	for i in 600:
		s.append(0.5)
	var sem := _motor("", 1)
	var rs := sem.lutar_com_sorteios([5000.0, 4000.0, 6000.0], _opp("opp_gym_1"), "aggressive", s, true)
	checar(not rs.has("finish") and not rs.has("charge_peak"), "sem arte: resultado sem campos de arte")
	checar_igual(rs.draws_used, 3 * rs.events.size(), "sem arte: 3 sorteios por ataque")
	for arte in TIPOS:
		var m1 := _motor(arte, 1)
		var r1 := m1.lutar_com_sorteios([5000.0, 4000.0, 6000.0], _opp("opp_gym_1"), "aggressive", s, true)
		checar(not r1.has("charge_peak") and not r1.has("takedowns") and not r1.has("clinches"), "%s: a 1ª passiva não ganha campos da 2ª" % arte)
		var det := m1.chance_detalhada([5000.0, 4000.0, 6000.0], _opp("opp_gym_1"), "aggressive")
		checar(not det.has("share") and not det.has("charge_med"), "%s: chance_detalhada da 1ª sem campos da 2ª" % arte)
		var m2 := _motor(arte, 2)
		var r2 := m2.lutar_com_sorteios([5000.0, 4000.0, 6000.0], _opp("opp_gym_1"), "aggressive", s, true)
		checar_igual(r2.draws_used, 4 * r2.events.size(), "%s (2ª): 4 sorteios por ataque" % arte)
	checar(FileAccess.file_exists("res://tests/data/fase7a1_casos.json") and FileAccess.file_exists("res://tests/data/fase7b1_casos.json"),
		"os casos da 7a1 e da 7b1 continuam valendo (test_fase7a1 / test_fase7b1)")
	checar_igual(SaveStore.VERSAO_ATUAL, 13, "save continua v13")
	var gs := _novo("f7b2_sem_arte")
	gs.indice_escada = 3
	var pv: Dictionary = gs.previa()
	checar(not pv.is_empty() and not pv.has("passive_name"), "sem arte: previa() sem campos da passiva")
	var antigo: Dictionary = gs.para_save()
	checar(antigo.career.art_passive == 1 and antigo.permanent.passive_wins.is_empty() and antigo.permanent.passives_unlocked.is_empty(), "sem arte: campos novos do save vazios")
	_liberar(gs)


# --- Prévia honesta ---
func _teste_previa_honesta() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 321
	var soma_dif := 0.0
	var pior := 0.0
	var estados := 0
	for arte in TIPOS:
		var gs := _novo("f7b2_previa_" + arte, arte, 2)
		gs.indice_escada = 3
		checar_igual(gs.motor.passiva.type, TIPOS[arte], "%s: a 2ª passiva está no motor" % arte)
		for oid in ["opp_gym_1", "opp_gym_2", "opp_tank"]:
			var adv := _opp(oid)
			for k in 2:
				var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.7, 1.2)
				var w := [rng.randf() + 0.4, rng.randf() + 0.4, rng.randf() + 0.4]
				var sw: float = w[0] + w[1] + w[2]
				var jog := [tot * w[0] / sw, tot * w[1] / sw, tot * w[2] / sw]
				var tat: String = TATICAS[(k + estados) % 3]
				var p: float = gs.motor.chance(jog, adv, tat)
				var det: Dictionary = gs.motor.chance_detalhada(jog, adv, tat)
				checar_igual(det.chance, p, "chance_detalhada = chance (%s, %s, %s)" % [arte, oid, tat])
				# a mesma conta, luta por luta com as 200 sementes
				var vit := 0
				var wp := 0
				var marcas: Array[float] = []
				for s in range(1, 201):
					var r: Dictionary = gs.motor.lutar(jog, adv, tat, s)
					if r.win:
						vit += 1
						if r.finish == FINS[arte]:
							wp += 1
					if arte == "boxing":
						marcas.append(float(r.charge_peak))
					elif arte == "bjj" and float(r.takedown_at) >= 0.0:
						marcas.append(float(r.takedown_at))
					elif arte == "muay_thai" and float(r.clinch_at) >= 0.0:
						marcas.append(float(r.clinch_at))
				marcas.sort()
				checar(det.wins == vit and det.wins_passive == wp, "wins e wins_passive (%s) batem com as lutas (%s, %s)" % [FINS[arte], oid, tat])
				if arte == "boxing":
					checar_igual(det.charge_med, marcas[marcas.size() / 2], "carga mediana bate (%s, %s)" % [oid, tat])
				else:
					checar(is_equal_approx(det.share, float(marcas.size()) / 200.0), "share bate (%s, %s, %s)" % [arte, oid, tat])
					checar(is_equal_approx(det.at, marcas[marcas.size() / 2] if not marcas.is_empty() else -1.0), "at (mediana) bate (%s, %s, %s)" % [arte, oid, tat])
				var v := 0
				var n := 1000
				for i in n:
					if gs.motor.lutar(jog, adv, tat, 100000 + i).win:
						v += 1
				var dif := float(v) / n - p
				soma_dif += dif
				pior = maxf(pior, absf(dif))
				estados += 1
		# previa() do jogo
		gs.atributos = {"strength": 3.0e6, "agility": 2.5e6, "endurance": 2.0e6}
		gs.local_id = "gym"
		gs.indice_escada = 4
		var pv: Dictionary = gs.previa()
		for campo in ["passive_name", "passive_line", "passive_state", "passive_share", "passive_share_n", "passive_tactics", "art_passive"]:
			checar(pv.has(campo), "%s: previa() tem %s" % [arte, campo])
		if pv.has("passive_tactics"):
			var jog_gs: Array = [gs.atributos.strength, gs.atributos.agility, gs.atributos.endurance]
			var opp: Dictionary = pv.opponent
			var adv_gs := [opp.strength, opp.agility, opp.endurance]
			checar_igual(int(pv.art_passive), 2, "%s: previa().art_passive = 2" % arte)
			for t in TATICAS:
				checar_igual(pv.risks[t].chance, gs.motor.chance(jog_gs, adv_gs, t), "%s: risco da prévia = motor (%s)" % [arte, t])
				var bloco: Dictionary = pv.passive_tactics[t]
				var est: Dictionary = gs.motor.estado_passiva(jog_gs, adv_gs, t)
				var linha := str(bloco.line)
				checar(linha != "" and bloco.kind == TIPOS[arte] and not linha.contains("{") and str(bloco.share).contains("EM 10 VITÓRIAS"),
					"%s: linha e vitórias pela passiva (%s): %s" % [arte, t, linha])
				if arte == "boxing":
					checar(linha.contains("%d%%" % int(round(100.0 * est.dodge))) and linha.contains("%d%%" % int(round(100.0 * est.ko_max))), "Contragolpista: a linha traz a esquiva e o K.O. (%s)" % t)
					checar_igual(linha.contains("NÃO ESPERA"), t == "aggressive", "Contragolpista: aviso do Agressivo só no Agressivo (%s)" % t)
				elif arte == "bjj":
					checar(bloco.state.late == linha.begins_with("SÓ DERRUBA") and linha.contains("DE 10 LUTAS") == bool(bloco.state.late), "Por cima: linha 'SÓ DERRUBA EM n DE 10' quando < metade (%s)" % t)
					if not bloco.state.late:
						checar(linha.contains("%d%%" % int(round(100.0 * est.td_chance))) and linha.contains("ELE LEVANTA") and linha.contains("O JUIZ PARA"), "Por cima: a linha traz a queda, o levantar e o juiz (%s)" % t)
				else:
					checar(bloco.state.late == linha.begins_with("SÓ PRENDE") and linha.contains("DE 10 LUTAS") == bool(bloco.state.late), "Clinch: linha 'SÓ PRENDE EM n DE 10' quando < metade (%s)" % t)
					if not bloco.state.late:
						checar(linha.contains("JOELHADA") and linha.contains("ELE SOLTA"), "Clinch: a linha traz a joelhada e o soltar (%s)" % t)
		_liberar(gs)
	checar(absf(soma_dif / estados) <= 0.03, "2ªs passivas: diferença média prévia x real %.1f pontos (<= 3)" % [100.0 * soma_dif / estados])
	checar(pior <= 0.10, "2ªs passivas: pior estado %.1f pontos (<= 10, com o ruído das 200 sementes)" % [100.0 * pior])


# --- Motivo da derrota (§12) ---
func _teste_notas_de_derrota() -> void:
	var base := {"finish": "points", "life_max": [1000.0, 1000.0], "t_end": 32.0, "t_ko": -1.0, "ko": false, "opp_counter_damage": 0.0, "attempts": 0}
	var cp := _motor("boxing", 2)
	var r := base.duplicate()
	r.t_end = 7.0
	r.t_ko = 7.0
	r.ko = true
	checar_igual(cp.nota_passiva(r, "counter").id, "cp_early", "Contragolpista: caiu antes do 3º round = cp_early")
	r = base.duplicate()
	r.attempts = 4
	var n := cp.nota_passiva(r, "counter")
	checar(n.id == "cp_held" and n.n == 4, "cp_held (4 contragolpes): %s" % str(n))
	checar_igual(cp.nota_passiva(base, "counter").id, "cp_never_hurt", "chegou ao 3º sem tentativa = cp_never_hurt")
	var tc := _motor("bjj", 2)
	r = base.duplicate()
	r.takedowns = 0
	r.stood_up = 0
	checar_igual(tc.nota_passiva(r, "aggressive").id, "tc_no_takedown", "Por cima sem queda = tc_no_takedown")
	r.takedowns = 3
	r.stood_up = 2
	n = tc.nota_passiva(r, "aggressive")
	checar(n.id == "tc_stood_up" and n.n == 2, "tc_stood_up (2 vezes): %s" % str(n))
	r.stood_up = 1
	checar_igual(tc.nota_passiva(r, "aggressive").id, "tc_never_hurt", "caiu e levantou pouco, sem tentativa = tc_never_hurt")
	r.attempts = 2
	checar(tc.nota_passiva(r, "aggressive").is_empty(), "Por cima com tentativas e poucos levantares: sem nota")
	var cl := _motor("muay_thai", 2)
	r = base.duplicate()
	r.clinches = 0
	r.released = 0
	checar_igual(cl.nota_passiva(r, "defensive").id, "cl_never", "Clinch sem prender = cl_never")
	r.clinches = 4
	r.released = 3
	n = cl.nota_passiva(r, "defensive")
	checar(n.id == "cl_released" and n.n == 3, "cl_released (3 vezes): %s" % str(n))
	r.released = 0
	r.attempts = 2
	n = cl.nota_passiva(r, "defensive")
	checar(n.id == "cl_held" and n.n == 2, "cl_held (2 joelhadas): %s" % str(n))
	# a 1ª passiva continua com as notas dela
	checar(_motor("muay_thai", 1).nota_passiva({"finish": "points", "life_max": [1000.0, 1000.0], "t_end": 16.0, "opp_counter_damage": 0.0, "marks_full_at": 6.3,
		"attempts": 0, "spins": 0, "marks_peak": 3}, "counter").id == "mt_never_hurt", "1ª passiva do Muay Thai: nota de sempre")
	# textos: cada id tem frase e dica, sem chave solta
	var gs := _novo("f7b2_notas", "boxing")
	for id in ["cp_early", "cp_held", "cp_never_hurt", "tc_no_takedown", "tc_stood_up", "tc_never_hurt", "cl_never", "cl_released", "cl_held"]:
		var t: Dictionary = gs._textos.passiva_nota_textos({"id": id, "n": 3, "r": 0}, 5)
		checar(str(t.text) != "" and str(t.tip) != "" and not str(t.text).contains("{"), "texto e dica de %s" % id)
	# derrota real traz a nota da passiva do tipo
	for arte in TIPOS:
		var m := _motor(arte, 2)
		var adv := _opp("opp_gym_2")
		var jog := [adv[0] * 0.5, adv[1] * 0.5, adv[2] * 0.5]
		var achou := {}
		for semente in range(1, 80):
			var res: Dictionary = m.lutar(jog, adv, "aggressive", semente, false)
			if not res.win:
				achou = m.nota_passiva(res, "aggressive")
				break
		var prefixo: String = {"boxing": "cp_", "bjj": "tc_", "muay_thai": "cl_"}[arte]
		checar(achou.is_empty() or str(achou.id).begins_with(prefixo), "%s: derrota real traz nota %s* (%s)" % [arte, prefixo, str(achou)])
	_liberar(gs)


# --- A meta: 3 vitórias pela 1ª passiva, somando a linhagem ---
func _luta_pronta(gs: Node, finish: String, ganhou: bool = true) -> void:
	var ko := finish != "damage" and finish != "points"
	gs.local_id = "garage"
	gs.luta = {"opponent": "opp_warmup", "tactic": "aggressive", "seed": 1, "player": {"strength": 1.0, "agility": 1.0, "endurance": 1.0},
		"result": {"win": ganhou, "ko": ko or finish == "damage", "t_ko": 8.0, "t_end": 16.0, "round": 1, "pct_player": 0.5 if ganhou else 0.0,
			"pct_opponent": 0.0 if ganhou else 0.5, "finish": finish}}
	gs.indice_escada = 0


func _teste_meta() -> void:
	var avisos := []
	for arte in TIPOS:
		var gs := _novo("f7b2_meta_" + arte, arte, 1)
		gs.permanente_mudou.connect(func() -> void: avisos.append(1))
		var fim: String = FIM_META[arte]
		checar(not gs.passiva_liberada(arte), "%s: 2ª passiva travada no começo" % arte)
		var pr: Dictionary = gs.progresso_passiva(arte)
		checar(pr.has and pr.n == 0 and pr.m == 3 and pr.text.begins_with("0/3 "), "%s: progresso 0/3 (%s)" % [arte, pr.text])
		# 2 pela passiva + 2 por dano (e 1 por pontos): 2/3 e cadeado
		_luta_pronta(gs, fim)
		var r: Dictionary = gs.concluir_luta()
		checar(r.passive_goal.counted and r.passive_goal.n == 1 and not r.passive_goal.unlocked_now and r.passive2_unlocked == "", "%s: 1ª vitória pela passiva conta (1/3)" % arte)
		_luta_pronta(gs, "damage")
		r = gs.concluir_luta()
		checar(r.passive_goal.is_empty() and gs.progresso_passiva(arte).n == 1, "%s: vitória por dano não conta" % arte)
		_luta_pronta(gs, "points")
		gs.concluir_luta()
		_luta_pronta(gs, fim)
		r = gs.concluir_luta()
		var pr2: Dictionary = gs.progresso_passiva(arte)
		checar(pr2.n == 2 and not pr2.liberada and pr2.text.begins_with("2/3 "), "%s: 2/3 e cadeado (%s)" % [arte, pr2.text])
		checar(gs.passivas_do_cartao(arte)[1].locked, "%s: cartão com a 2ª travada" % arte)
		# fim de outra arte não conta
		var outro: String = "spin_kick" if fim != "spin_kick" else "knockout"
		_luta_pronta(gs, outro)
		gs.concluir_luta()
		checar_igual(gs.progresso_passiva(arte).n, 2, "%s: fim de outra arte (%s) não conta" % [arte, outro])
		# derrota não conta (a carreira acaba): 3ª vitória vem antes, numa luta nova
		var n_avisos := avisos.size()
		_luta_pronta(gs, fim)
		r = gs.concluir_luta()
		checar(r.passive_goal.n == 3 and r.passive_goal.unlocked_now and r.passive2_unlocked == arte, "%s: a 3ª libera (3/3)" % arte)
		checar(str(r.passive2_line).begins_with("NOVO JEITO DE LUTAR: ") and str(r.passive2_line).contains(str(gym.arte(arte).passive_2.name).to_upper()), "%s: aviso único de liberação (%s)" % [arte, r.passive2_line])
		checar(gs.passiva_liberada(arte) and gs.marco("passive2_%s_unlocked" % arte) and avisos.size() > n_avisos, "%s: liberada, marco gravado e permanente_mudou" % arte)
		var tem_gatilho := false
		for g in gs._gatilhos_quadro:
			if str(g.id) == "passive2_%s_unlocked" % arte:
				tem_gatilho = true
		checar(tem_gatilho, "%s: a fala do mentor foi pedida" % arte)
		var ctx := {"campaign": 1, "first_campaign": 1, "lutador": "first", "location": "garage", "milestones": gs.escola.milestones, "lines_seen": {}, "params": {}}
		checar_igual(gs.dialogos.candidatas("passive2_%s_unlocked" % arte, ctx).size(), 1, "%s: a fala do mentor existe (uma vez)" % arte)
		ctx.lines_seen = {"cl_passive2_" + arte: 1}
		checar(gs.dialogos.candidatas("passive2_%s_unlocked" % arte, ctx).is_empty(), "%s: depois de vista, não repete" % arte)
		# 4ª vitória: sem aviso de novo, e o progresso fica em 3/3
		_luta_pronta(gs, fim)
		r = gs.concluir_luta()
		checar(not r.passive_goal.unlocked_now and r.passive2_unlocked == "" and gs.progresso_passiva(arte).n == 3, "%s: depois de liberada não avisa de novo (n limitado a 3)" % arte)
		checar_igual(gs.passiva_carreira, 1, "%s: a carreira atual continua na 1ª passiva" % arte)
		var estado: Dictionary = gs.para_save()
		checar(estado.permanent.passive_wins[arte] == 4 and estado.permanent.passives_unlocked.has(arte), "%s: o save traz as vitórias e a liberação" % arte)
		_liberar(gs)
	# a vitória com a 2ª passiva não conta, e a linhagem soma entre carreiras
	var g2 := _novo("f7b2_meta_2a", "boxing", 2)
	_luta_pronta(g2, "counter_ko")
	var r2: Dictionary = g2.concluir_luta()
	checar(r2.passive_goal.is_empty() and int(g2.permanente.passive_wins.get("boxing", 0)) == 3, "vitória com a 2ª passiva não conta (counter_ko)")
	var g3 := _novo("f7b2_meta_linhagem", "bjj", 1)
	_luta_pronta(g3, "submission")
	g3.concluir_luta()
	g3.arte_id = ""  # outra carreira (outro lutador) da mesma linhagem
	g3.escolher_arte("bjj", 1)
	_luta_pronta(g3, "submission")
	g3.concluir_luta()
	checar_igual(g3.progresso_passiva("bjj").n, 2, "a linhagem soma as vitórias de carreiras diferentes")
	_liberar(g2)
	_liberar(g3)


# --- Escolha da passiva no começo da carreira ---
func _teste_escolha() -> void:
	var gs := _novo("f7b2_escolha")
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	var cartoes: Array = gs.artes_para_escolha()
	checar(cartoes.size() == 3 and cartoes[0].passives.size() == 2 and cartoes[0].passives[0].n == 1 and cartoes[0].passives[1].n == 2, "cartões com 2 opções de passiva")
	checar(cartoes[0].passives[1].locked and cartoes[0].passives[1].progress.text.begins_with("0/3 ") and cartoes[0].passives[1].locked_text == "TRAVADO", "a 2ª vem travada com o progresso")
	checar(cartoes[0].passives[0].selected and not cartoes[0].passives[1].selected and cartoes[0].passive_default == 1, "a 1ª vem marcada")
	checar(not gs.escolher_arte("boxing", 2) and gs.escolha_arte_pendente(), "escolher a 2ª travada é recusado (a escolha continua pendente)")
	checar(not gs.escolher_arte("boxing", 3), "passiva inválida é recusada")
	# libera e escolhe a 2ª
	_liberar_2a(gs, "boxing")
	checar(not gs.artes_para_escolha()[0].passives[1].locked, "liberada, a 2ª sai do cadeado")
	checar(gs.escolher_arte("boxing", 2), "escolher a 2ª liberada")
	checar_igual(gs.passiva_carreira, 2, "passiva_carreira = 2")
	checar_igual(gs.motor.passiva.type, "counter_punch", "o motor recebe o Contragolpista")
	checar(is_equal_approx(gs.motor.extra_passiva, 0.0), "sem nó: extra 0")
	checar(not gs.escolher_arte("bjj", 1), "a escolha vale a carreira inteira (sem troca)")
	var estado: Dictionary = gs.para_save()
	checar(estado.career.art_passive == 2 and estado.permanent.last_passive.boxing == 2, "o save grava career.art_passive e last_passive")
	# o nó da raiz reforça a passiva ativa
	gs.permanente["skill_nodes"] = ["box_counter"]
	gs.nos_ativos_ids = ["box_counter"]
	gs._arvore._recalcular_bonus()
	gs._academia._atualizar_passiva()
	checar(is_equal_approx(gs.motor.extra_passiva, 0.5), "box_counter: extra 0,5 também na 2ª passiva")
	checar(gs.texto_efeito_no(dados.no_da_arvore("box_counter")).begins_with("CONTRAGOLPISTA: K.O. +50%"), "nó da raiz descreve a 2ª passiva quando ela está escolhida (%s)" % gs.texto_efeito_no(dados.no_da_arvore("box_counter")))
	var ko1: float = gs.motor.estado_passiva([4000.0, 4000.0, 4000.0], _opp("opp_gym_1"), "counter").ko_max
	gs.motor.extra_passiva = 0.0
	var ko0: float = gs.motor.estado_passiva([4000.0, 4000.0, 4000.0], _opp("opp_gym_1"), "counter").ko_max
	checar(is_equal_approx(ko1, minf(0.6, ko0 * 1.5)), "o nó multiplica o K.O. do contragolpe por 1,5")
	# recarregar o save mantém a passiva
	var copia: Dictionary = gs.para_save()
	gs.aplicar_save(copia)
	checar(gs.passiva_carreira == 2 and gs.motor.passiva.type == "counter_punch", "carregar o save mantém a 2ª passiva")
	# nova escolha: a última marcada vem por padrão
	gs.arte_id = ""
	gs.passiva_carreira = 1
	gs._academia._atualizar_passiva()
	checar_igual(gs.artes_para_escolha()[0].passive_default, 2, "a última escolha (2ª) vem marcada")
	checar(gs.escolher_arte("boxing") and gs.passiva_carreira == 2, "escolher sem dizer a passiva usa a marcada")
	# nova carreira volta à 1ª (a escolha acontece de novo)
	gs.fim = {"kind": "retire", "career_number": 1, "summary": {}}
	gs.arte_id = "boxing"
	gs._carreira._reiniciar_campanha()
	checar(gs.passiva_carreira == 1 and gs.arte_id == "" and gs.motor.passiva.is_empty(), "nova campanha: sem arte e passiva 1 até escolher")
	# arte sem passive_2 mostra uma opção só
	gs.academia.arte("bjj")["passive_2"] = {}
	checar_igual(gs.passivas_do_cartao("bjj").size(), 1, "arte sem 2ª passiva: 1 opção só")
	checar(not gs.progresso_passiva("bjj").has, "progresso de arte sem 2ª passiva: has = false")
	_liberar(gs)


# --- Save antigo e save sujo ---
func _teste_save_antigo() -> void:
	var gs := _novo("f7b2_antigo", "bjj", 1)
	var e1: Dictionary = gs.para_save()
	e1.permanent.erase("passive_wins")
	e1.permanent.erase("passives_unlocked")
	e1.permanent.erase("last_passive")
	e1.career.erase("art_passive")
	gs.aplicar_save(e1)
	checar(gs.progresso_passiva("bjj").n == 0 and not gs.passiva_liberada("bjj") and gs.passiva_carreira == 1, "save antigo (sem os campos): abre com 0/3, travada e 1ª passiva")
	checar(gs.motor.passiva.type == "submission", "save antigo: a 1ª passiva de sempre")
	# 2ª passiva salva sem a meta batida volta para a 1ª
	var e2: Dictionary = gs.para_save()
	e2.career["art_passive"] = 2
	gs.aplicar_save(e2)
	checar(gs.passiva_carreira == 1 and gs.motor.passiva.type == "submission", "art_passive 2 sem a meta: volta para a 1ª")
	# meta batida mas lista perdida: libera ao carregar
	var e3: Dictionary = gs.para_save()
	e3.permanent["passive_wins"] = {"bjj": 5, "inexistente": 2, "boxing": -4}
	e3.permanent["passives_unlocked"] = ["lixo"]
	gs.aplicar_save(e3)
	checar(gs.passiva_liberada("bjj") and gs.permanente.passive_wins.has("bjj") and not gs.permanente.passive_wins.has("inexistente"), "passive_wins >= meta libera ao carregar; arte inexistente sai")
	checar(not gs.permanente.passives_unlocked.has("lixo") and gs.permanente.passive_wins.get("boxing", 0) == 0, "lixo na lista e número negativo são limpos")
	# o save com a 2ª passiva grava e abre de novo
	var e4: Dictionary = gs.para_save()
	e4.career["art_passive"] = 2
	gs.aplicar_save(e4)
	checar(gs.passiva_carreira == 2 and gs.motor.passiva.type == "top_control", "art_passive 2 com a meta batida: vale")
	# `finish` de 2ª passiva: aceito só com a passiva do tipo certa
	var luta := {"opponent": "opp_warmup", "tactic": "aggressive", "seed": 3, "player": {"strength": 1, "agility": 1, "endurance": 1},
		"result": {"win": true, "ko": true, "t_ko": 8.0, "t_end": 8.0, "round": 1, "pct_player": 0.5, "pct_opponent": 0.0, "finish": "ground_stop"}}
	var e5: Dictionary = gs.para_save()
	e5.career["fight"] = luta
	e5.career["ladder_index"] = 0
	gs.aplicar_save(e5)
	checar_igual(gs.luta.get("result", {}).get("finish", ""), "ground_stop", "luta salva com ground_stop e Por cima: finish mantido")
	var e6: Dictionary = e5.duplicate(true)
	e6.career["art_passive"] = 1
	gs.aplicar_save(e6)
	checar(not gs.luta.get("result", {}).has("finish"), "ground_stop com a 1ª passiva é descartado")
	checar(gs.salvar(), "o save grava")
	checar_igual(SaveStore.VERSAO_ATUAL, 13, "save continua v13")
	_liberar(gs)


# --- A luta na tela ---
func _teste_luta_na_tela() -> void:
	for arte in TIPOS:
		var gs := _novo("f7b2_tela_" + arte, arte, 2)
		gs.indice_escada = 3
		gs.atributos = {"strength": 3.0e5, "agility": 2.0e5, "endurance": 2.0e5}
		var info: Dictionary = gs.lutar()
		checar(not info.is_empty(), "%s: lutar() com a 2ª passiva" % arte)
		checar_igual(info.passive, TIPOS[arte], "%s: luta_atual().passive" % arte)
		checar_igual(int(info.art_passive), 2, "%s: luta_atual().art_passive = 2" % arte)
		var campos: Array = {"boxing": ["charge_max", "charge_peak"], "bjj": ["takedowns", "stood_up", "takedown_at"],
			"muay_thai": ["clinches", "released", "clinch_at", "knees", "clinch_s"]}[arte]
		for chave in campos:
			checar(info.has(chave), "%s: luta_atual() tem %s" % [arte, chave])
		var ok := true
		var chao_antes := false
		for e in info.events:
			if not (e.has("charge") and e.has("ground") and e.has("clinch") and e.has("passive_move")):
				ok = false
			if int(e.charge) < 0 or int(e.charge) > 3:
				ok = false
			if arte == "bjj" and e.kind != "dodge" and int(e.who) == 0 and e.passive_move == "takedown" and (e.kind != "takedown" or e.phase_after != "ground"):
				ok = false
			if arte == "bjj" and (e.phase_after == "ground") != bool(e.ground):
				ok = false
			chao_antes = bool(e.ground)
		checar(ok, "%s: eventos com charge/ground/clinch/passive_move coerentes" % arte)
		checar_igual(gs.luta_atual().result, info.result, "%s: recalcular dá o mesmo resultado" % arte)
		_liberar(gs)
	# luta montada com cada fim: o último evento carrega `finish`
	for arte in TIPOS:
		var gs := _novo("f7b2_tela_fim_" + arte, arte, 2)
		var m: Luta = gs.motor
		var adv := _opp("opp_gym_1")
		var jog := [adv[0] * 2.0, adv[1] * 2.0, adv[2] * 2.0]
		var achou := false
		gs.indice_escada = 4
		gs.local_id = "gym"
		for semente in range(1, 3000):
			for tat in TATICAS:
				var res := m.lutar(jog, adv, tat, semente, false)
				if res.finish == FINS[arte]:
					gs.luta = {"opponent": "opp_gym_1", "tactic": tat, "seed": semente, "player": {"strength": jog[0], "agility": jog[1], "endurance": jog[2]},
						"result": {"win": res.win, "ko": res.ko, "t_ko": res.t_ko, "t_end": res.t_end, "round": res.round, "pct_player": res.pct_player,
							"pct_opponent": res.pct_opponent, "finish": res.finish}}
					achou = true
					break
			if achou:
				break
		checar(achou, "%s: achou uma luta que acaba em %s" % [arte, FINS[arte]])
		if achou:
			var i2: Dictionary = gs.luta_atual()
			var u: Dictionary = i2.events[i2.events.size() - 1]
			checar(i2.result.finish == FINS[arte] and u.finish == FINS[arte] and u.ko, "%s: último evento traz finish %s e K.O." % [arte, FINS[arte]])
		_liberar(gs)


# --- Nós da árvore: texto da 2ª passiva ---
func _teste_nos_da_arvore() -> void:
	for id in ["box_counter", "bjj_guard", "mt_shin"]:
		var n := dados.no_da_arvore(id)
		checar(not n.is_empty() and int(n.cost) == 200 and is_equal_approx(float(n.effect_value), 0.5), "nó %s não mudou (200, 0,5)" % id)
	var ui: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/skill_tree.json"))
	var com_texto2 := 0
	for no in ui.nodes:
		if str(no.get("effect_text_2", "")) != "":
			com_texto2 += 1
	checar_igual(com_texto2, 3, "3 nós com effect_text_2")
