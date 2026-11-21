extends "res://tests/test_base.gd"
## Fase 7b1 (Muay Thai): passiva Canela no motor (casos exatos contra o simulador Python), prévia honesta, regra de treino
## "clique com picos", liberação pela 1ª vitória contra o Kid, save antigo, variante do Choque (batida), nós da árvore e
## "nada muda sem a arte". Referência: tools/sim/fase7b1_sim.py e docs/fases/fase7b1-design.md.
## Casos exatos: tests/data/fase7b1_casos.json (gerado por tools/sim/exportar_casos.py). Tudo em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")
const CASOS := "res://tests/data/fase7b1_casos.json"
const TATICAS := ["aggressive", "defensive", "counter"]

var dados: FightData
var gym: GymData


func rodar_testes() -> void:
	dados = FightData.carregar()
	gym = GymData.carregar()
	_teste_dados()
	_teste_python_exato()
	_teste_laco_regras()
	_teste_nada_muda_sem_a_arte()
	_teste_previa_honesta()
	_teste_notas_de_derrota()
	_teste_clique_com_picos()
	_teste_liberacao()
	_teste_save_antigo()
	_teste_choque_batida()
	_teste_luta_na_tela()
	_teste_arvore_e_aparelho()
	_teste_animacoes_no_manifest()


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
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	if arte != "":
		gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		gs.escolher_arte(arte)
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


# --- Dados ---
func _teste_dados() -> void:
	var a := gym.arte("muay_thai")
	checar(not a.is_empty(), "arte muay_thai carregada")
	checar_igual(a.passive.type, "shin", "passiva Canela (shin)")
	checar_igual(a.rule.type, "click_crit_bonus", "regra: clique com picos")
	checar(is_equal_approx(float(a.rule.chance_add), 0.10) and is_equal_approx(float(a.rule.mult_add), 1.1), "regra: +10% de chance e +1,1 de multiplicador")
	checar_igual(a.unlock.opponent, "opp_gym_2", "liberada pela 1ª vitória contra o Kid")
	checar(gym.arte("boxing").unlock.is_empty() and gym.arte("bjj").unlock.is_empty(), "Boxe e Jiu-jitsu sem `unlock`")
	checar_igual(gym.ids_artes_iniciais(), ["boxing", "bjj"], "1ª chegada à academia: só Boxe e Jiu-jitsu")
	checar_igual(int(a.passive.marks_max), 3, "3 marcas")
	checar(is_equal_approx(float(a.passive.damage_mult), 0.88), "dano x0,88")
	checar("spin_kick" in MovesData.KINDS, "kind novo spin_kick")
	var golpes := MovesData.carregar()
	checar_igual(golpes.disponiveis("muay_thai").size(), 4, "estilo muay_thai: 4 golpes")
	checar(golpes.disponiveis("muay_thai").has("spin_kick") and not golpes.disponiveis("muay_thai").has("jab"), "estilo muay_thai sem golpe de Boxe")
	checar_igual(golpes.golpes.low_kick.defender_anim, "hit_leg", "chute baixo: reação hit_leg")
	var ap := TrainingData.carregar().aparelho("kick_bag")
	checar(not ap.is_empty() and ap.art == "muay_thai", "aparelho kick_bag da arte")
	if not ap.is_empty():
		checar(is_equal_approx(float(ap.split.strength), 0.5) and is_equal_approx(float(ap.split.agility), 0.35) and is_equal_approx(float(ap.split.endurance), 0.15), "saco de chute: divisão 50/35/15")
		checar(ap.crit_texts.size() >= 5, "saco de chute: pelo menos 5 textos de crítico")
	# GymData recorta valores ruins da Canela
	var ruim := {"arts": [{"id": "x", "rule": {"type": "click_crit_bonus", "chance_add": 7.0, "mult_add": -3}, "passive": {"type": "shin", "marks_max": 99, "spin_ko": 5.0}}]}
	var tmp := "user://test/arts_ruim.json"
	DirAccess.make_dir_recursive_absolute("user://test")
	escrever(tmp, JSON.stringify(ruim))
	var g2 := GymData.carregar("res://data/locations.json", tmp)
	checar(float(g2.arte("x").rule.chance_add) == 1.0 and float(g2.arte("x").rule.mult_add) == 0.0, "regra com número fora da faixa é recortada")
	checar(int(g2.arte("x").passive.marks_max) == 5 and float(g2.arte("x").passive.spin_ko) == 1.0, "passiva shin recortada (marcas 1-5, chances 0-1)")
	DirAccess.remove_absolute(tmp)


# --- Casos exatos contra o simulador Python (4 sorteios por ataque) ---
func _teste_python_exato() -> void:
	if not FileAccess.file_exists(CASOS):
		checar(false, "tests/data/fase7b1_casos.json existe (rode tools/sim/exportar_casos.py)")
		return
	var casos: Array = JSON.parse_string(FileAccess.get_file_as_string(CASOS)).exatos
	var iguais := 0
	var primeira := ""
	var fins := {}
	for c in casos:
		var m := _motor(str(c.art), float(c.extra))
		var r := m.lutar_com_sorteios(c.player, c.opponent, c.tactic, PackedFloat64Array(c.draws), true)
		var erro := _comparar(m, r, c)
		fins[str(r.finish)] = true
		if erro == "":
			iguais += 1
		elif primeira == "":
			primeira = "%s (%s, extra %s)" % [erro, c.tactic, str(c.extra)]
	checar_igual(iguais, casos.size(), "GDScript = Python em %d lutas do Muay Thai%s" % [casos.size(), "" if primeira == "" else " | 1ª falha: " + primeira])
	checar(fins.has("spin_kick") and fins.has("damage") and fins.has("points"), "os casos cobrem chute rodado, dano e pontos")


func _fim_py(f: String) -> String:
	return "spin_kick" if f == "chute_rodado" else ""


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
		if absf(e.t - p[0]) > 6e-4 or e.who != int(p[1]) or e.type != p[2] or e.counter != p[3] or e.marks != int(p[6]) or e.move != str(p[7]) \
				or e.finish != _fim_py(str(p[8])):
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
	if r.marks_peak != int(c.marks_peak) or not _aprox(r.marks_full_at, c.marks_full_at, 1e-9) or r.attempts != int(c.attempts) \
			or r.spins != int(c.spins) or not _aprox(r.opp_counter_damage, c.opp_counter_damage, 1e-7):
		return "marcas / rodados / tentativas / contragolpe"
	var est := m.estado_passiva(c.player, c.opponent, c.tactic)
	for chave in c.est:
		if typeof(c.est[chave]) == TYPE_STRING:
			if est[chave] != c.est[chave]:
				return "estado_passiva." + chave
		elif not _aprox(float(est[chave]), float(c.est[chave]), 1e-9):
			return "estado_passiva." + chave
	return ""


# --- Regras do laço (as que o design manda não errar) ---
func _tudo_acerta(n: int, r_crit: float, r_arte: float) -> PackedFloat64Array:
	var s := PackedFloat64Array()
	for i in n:
		s.append_array(PackedFloat64Array([0.99, r_crit, 0.5, r_arte]))  # esquiva nunca
	return s


func _teste_laco_regras() -> void:
	var m := _motor("muay_thai")
	var adv := _opp("opp_gym_1")
	var jog := [adv[2] * 1.5, adv[1], adv[2] * 0.3]  # FORÇA acima da RESISTÊNCIA dele: 1 marca por chute
	var est := m.estado_passiva(jog, adv, "counter")
	checar_igual(est.kind, "shin", "estado_passiva: kind shin")
	checar(est.mark_gain >= 1.0 - 1e-9 and est.kicks_to_full == 3, "FORÇA contra a RESISTÊNCIA dele: 1 marca por chute, 3 chutes")
	# Sem crítico nenhum (r_crit 0,99): só o acerto normal marca a perna, 1 marca por chute (o evento 'kick' do jogador)
	var r := m.lutar_com_sorteios(jog, adv, "counter", _tudo_acerta(60, 0.99, 0.99), true)
	var marcas_antes := 0
	var subiu := true
	for e in r.events:
		if int(e.marks) < marcas_antes or int(e.marks) > marcas_antes + 1:
			subiu = false
		marcas_antes = int(e.marks)
		if int(e.who) == 1 and e.move != "":
			subiu = false
		if int(e.who) == 0 and e.type == "hit" and e.move != "kick":
			subiu = false
	checar(subiu, "a perna só sobe 1 marca por chute e o adversário nunca tem golpe de Muay Thai")
	# Crítico antes da perna cheia não marca (joelhada/clinch); com a perna cheia vira chute rodado
	var s := PackedFloat64Array()
	for i in 80:
		s.append_array(PackedFloat64Array([0.99, 0.0, 0.5, 0.99]))  # crítico sempre, r_arte nunca derruba
	var rc := m.lutar_com_sorteios(jog, adv, "counter", s, true)
	var so_crit := true
	for e in rc.events:
		if int(e.who) == 0 and e.type != "dodge" and e.move != "crit" and e.move != "spin":
			so_crit = false
	checar(so_crit and rc.marks_peak == 0 and rc.marks_full_at < 0.0, "só crítico: a perna nunca marca (joelhada/clinch)")
	# Perna cheia + crítico = spin; ele ≤ 60% e r_arte < 0,65 derruba
	var mj := _motor("muay_thai")
	var fraco := [adv[0] * 3.0, adv[1] * 3.0, adv[2] * 1.5]
	var achou_spin := false
	var achou_finish := false
	for semente in range(1, 600):
		var rs := mj.lutar(fraco, adv, "aggressive", semente, true)
		if rs.spins > 0:
			achou_spin = true
		if rs.finish == "spin_kick":
			achou_finish = true
			checar(rs.win and rs.ko and rs.marks_full_at >= 0.0, "chute rodado: vence com a perna cheia")
			var ult: Dictionary = rs.events[rs.events.size() - 1]
			checar(ult.move == "spin" and ult.finish == "spin_kick" and int(ult.marks) == 3, "último evento = spin com 3 marcas e finish spin_kick")
			checar(float(rs.t_end) >= float(dados.combate.min_ko_time) - 1e-9, "respeita min_ko_time")
			break
	checar(achou_spin and achou_finish, "aparecem chutes rodados e finalização por chute rodado")
	# Lentidão: com marcas ele ataca mais devagar (intervalo entre os ataques dele cresce)
	var base := float(dados.combate.attack_interval)
	var rl := m.lutar_com_sorteios(jog, adv, "defensive", _tudo_acerta(60, 0.99, 0.99), true)
	var t_ant := -1.0
	var gaps: Array = []
	for e in rl.events:
		if int(e.who) == 1 and e.type != "dodge" and not e.counter:
			if t_ant >= 0.0:
				gaps.append(float(e.t) - t_ant)
			t_ant = float(e.t)
	var cresce := gaps.size() >= 3 and float(gaps[0]) <= base + 1e-6
	var maior := 0.0
	for gp in gaps:
		maior = maxf(maior, float(gp))
	checar(cresce and maior > base * 1.1, "ele fica mais lento com a perna marcada (maior intervalo %.2f s)" % maior)
	# Crítico do jogador sobe com as marcas, teto crit_cap
	var e0 := m.estado_passiva(jog, adv, "counter")
	checar(e0.crit_full >= e0.crit_now and e0.crit_full <= float(gym.arte("muay_thai").passive.crit_cap) + 1e-9, "crítico cheio >= agora e <= teto 60%")
	# 3 estados da prévia por tática
	var ea := m.estado_passiva(jog, adv, "aggressive")
	var ed := m.estado_passiva(jog, adv, "defensive")
	var ec := m.estado_passiva(jog, adv, "counter")
	checar(ea.opp_counter > 0.0 and ed.opp_counter == 0.0 and ec.marks_per_counter > 0.0, "Agressivo: ele contragolpeia; Contra-ataque: o contragolpe marca")
	checar(ea.mark_gain >= ed.mark_gain and ed.slow_full > ea.slow_full, "Agressivo marca mais rápido; Defensivo deixa ele mais lento")
	# o nó mt_shin (extra) acelera as marcas
	var mx := _motor("muay_thai", 0.5)
	var jf := [adv[0] * 0.6, adv[1], adv[2]]
	checar(mx.estado_passiva(jf, adv, "defensive").kicks_to_full <= m.estado_passiva(jf, adv, "defensive").kicks_to_full, "mt_shin: menos chutes para encher")


# --- Sem arte, Boxe e Jiu-jitsu: o laço de sempre ---
func _teste_nada_muda_sem_a_arte() -> void:
	var sem := _motor("")
	var s := PackedFloat64Array()
	for i in 400:
		s.append(0.5)
	var rs := sem.lutar_com_sorteios([5000.0, 4000.0, 6000.0], _opp("opp_gym_1"), "aggressive", s, true)
	checar(not rs.has("marks_peak") and not rs.has("finish"), "sem arte: resultado sem campos de arte")
	checar_igual(rs.draws_used, 3 * rs.events.size(), "sem arte: 3 sorteios por ataque")
	for arte in ["boxing", "bjj"]:
		var ma := _motor(arte)
		var ra := ma.lutar_com_sorteios([5000.0, 4000.0, 6000.0], _opp("opp_gym_1"), "aggressive", s, true)
		checar(not ra.has("marks_peak") and not ra.has("spins"), "%s: resultado sem campos do Muay Thai" % arte)
		checar_igual(ra.draws_used, 4 * ra.events.size(), "%s: 4 sorteios por ataque" % arte)
		var det := ma.chance_detalhada([5000.0, 4000.0, 6000.0], _opp("opp_gym_1"), "aggressive")
		checar(not det.has("full_share"), "%s: chance_detalhada sem full_share" % arte)
	# Boxe e JJ idênticos aos casos da 7a1 (o teste da 7a1 compara todos os eventos; aqui só confirma que o arquivo existe)
	checar(FileAccess.file_exists("res://tests/data/fase7a1_casos.json"), "casos da 7a1 continuam valendo (test_fase7a1)")
	# O Muay Thai sem arte escolhida: o save, a prévia e o resto não ganham chave nenhuma
	var gs := _novo("f7b1_sem_arte")
	gs.indice_escada = 3
	var pv: Dictionary = gs.previa()
	checar(not pv.is_empty() and not pv.has("passive_name"), "sem arte: previa() sem campos da passiva")
	checar_igual(gs.bonus_arte_critico(), {"chance": 0.1, "mult": 3.0}, "sem arte: crítico do clique 10% e x3")
	var antigo: Dictionary = gs.para_save()
	checar(not antigo.permanent.arts_unlocked.has("muay_thai"), "sem arte: o save não tem muay_thai")
	checar_igual(SaveStore.VERSAO_ATUAL, 13, "save continua v13")
	_liberar(gs)


# --- Prévia honesta ---
func _teste_previa_honesta() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 654
	var gs := _novo("f7b1_previa", "muay_thai")
	gs.indice_escada = 3
	var soma_dif := 0.0
	var pior := 0.0
	var estados := 0
	for oid in ["opp_gym_1", "opp_gym_2", "opp_tank", "opp_fast"]:
		var adv := _opp(oid)
		for k in 3:
			var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.7, 1.2)
			var w := [rng.randf() + 0.4, rng.randf() + 0.4, rng.randf() + 0.4]
			var sw: float = w[0] + w[1] + w[2]
			var jog := [tot * w[0] / sw, tot * w[1] / sw, tot * w[2] / sw]
			var tat: String = TATICAS[(k + estados) % 3]
			var p: float = gs.motor.chance(jog, adv, tat)
			var det: Dictionary = gs.motor.chance_detalhada(jog, adv, tat)
			checar_igual(det.chance, p, "chance_detalhada = chance (%s, %s)" % [oid, tat])
			# a mesma conta, feita luta por luta com as 200 sementes
			var cheias: Array[float] = []
			var wp := 0
			var vit := 0
			for s in range(1, 201):
				var r: Dictionary = gs.motor.lutar(jog, adv, tat, s)
				if r.win:
					vit += 1
					if r.finish == "spin_kick":
						wp += 1
				if float(r.marks_full_at) >= 0.0:
					cheias.append(float(r.marks_full_at))
			cheias.sort()
			checar(det.wins == vit and det.wins_passive == wp, "wins e wins_passive (rodado) batem com as lutas (%s, %s)" % [oid, tat])
			checar(is_equal_approx(det.full_share, float(cheias.size()) / 200.0), "full_share bate (%s, %s)" % [oid, tat])
			checar(is_equal_approx(det.full_at, cheias[cheias.size() / 2] if not cheias.is_empty() else -1.0), "full_at (mediana) bate (%s, %s)" % [oid, tat])
			# a luta de verdade (sementes aleatórias) fica perto da prévia
			var v := 0
			var n := 1000
			for i in n:
				if gs.motor.lutar(jog, adv, tat, 100000 + i).win:
					v += 1
			var dif := float(v) / n - p
			soma_dif += dif
			pior = maxf(pior, absf(dif))
			estados += 1
	checar(absf(soma_dif / estados) <= 0.03, "Muay Thai: diferença média prévia x real %.1f pontos (<= 3)" % [100.0 * soma_dif / estados])
	checar(pior <= 0.10, "Muay Thai: pior estado %.1f pontos (<= 10, com o ruído das 200 sementes)" % [100.0 * pior])
	# previa() do jogo: campos, mesmo número do motor e a linha de cada tática
	gs.atributos = {"strength": 3.0e6, "agility": 2.5e6, "endurance": 2.0e6}
	gs.local_id = "gym"
	gs.indice_escada = 4
	var pv: Dictionary = gs.previa()
	for campo in ["passive_name", "passive_line", "passive_state", "passive_share", "passive_share_n", "passive_tactics"]:
		checar(pv.has(campo), "previa() tem %s" % campo)
	if not pv.is_empty():
		var jog_gs: Array = [gs.atributos.strength, gs.atributos.agility, gs.atributos.endurance]
		var opp: Dictionary = pv.opponent
		var adv_gs := [opp.strength, opp.agility, opp.endurance]
		checar_igual(pv.passive_name, "CANELA", "nome da passiva")
		for t in TATICAS:
			checar_igual(pv.risks[t].chance, gs.motor.chance(jog_gs, adv_gs, t), "risco da prévia = motor (%s)" % t)
			var bloco: Dictionary = pv.passive_tactics[t]
			var det: Dictionary = gs.motor.chance_detalhada(jog_gs, adv_gs, t)
			var est: Dictionary = gs.motor.estado_passiva(jog_gs, adv_gs, t)
			checar(str(bloco.line) != "" and bloco.kind == "shin", "linha da passiva (%s): %s" % [t, bloco.line])
			checar_igual(bloco.state.kicks_to_full, est.kicks_to_full, "estado da prévia: chutes (%s)" % t)
			checar(is_equal_approx(bloco.state.full_share, det.full_share) and is_equal_approx(bloco.state.spin_chance, est.spin_chance), "estado da prévia: perna cheia e rodado (%s)" % t)
			if not bloco.state.late:
				var rodada := int(floor(float(det.full_at) / float(dados.combate.round_length) + 1e-9)) + 1
				checar(str(bloco.line).contains("%dº ROUND" % rodada) and str(bloco.line).contains("%d%%" % int(round(100.0 * est.spin_chance))), "a linha traz o round e o rodado (%s)" % t)
			else:
				checar(str(bloco.line).contains("DE 10 LUTAS"), "perna que não enche: linha 'SÓ ENCHE EM n DE 10' (%s)" % t)
			checar(str(bloco.share).contains("EM 10 VITÓRIAS"), "linha de vitórias pelo rodado (%s)" % t)
		checar(pv.passive_tactics.aggressive.line.contains("CONTRAGOLPEIA") and pv.passive_tactics.counter.line.contains("CONTRAGOLPE MARCA"), "Agressivo avisa do contragolpe dele; Contra-ataque, que o seu marca")
		checar(not pv.passive_tactics.defensive.line.contains("CONTRAGOLPE"), "Defensivo sem aviso de contragolpe")
	_liberar(gs)


# --- Motivo da derrota ---
func _teste_notas_de_derrota() -> void:
	var m := _motor("muay_thai")
	var base := {"finish": "points", "life_max": [1000.0, 1000.0], "t_end": 16.0, "opp_counter_damage": 0.0, "marks_full_at": 6.3, "attempts": 0,
		"spins": 0, "marks_peak": 3}
	var r := base.duplicate()
	r.opp_counter_damage = 300.0
	var n := m.nota_passiva(r, "aggressive")
	checar(n.id == "mt_counter" and n.n == 30, "nota mt_counter (30%%): %s" % str(n))
	checar_igual(m.nota_passiva(r, "counter").id, "mt_never_hurt", "contragolpe dele só pesa no Agressivo")
	r = base.duplicate()
	r.marks_full_at = -1.0
	r.marks_peak = 2
	n = m.nota_passiva(r, "defensive")
	checar(n.id == "mt_marks_late" and n.n == 2, "nota mt_marks_late (2 de 3): %s" % str(n))
	r = base.duplicate()
	r.t_end = 5.0  # perdeu antes de a perna encher
	checar_igual(m.nota_passiva(r, "counter").id, "mt_marks_late", "perdeu antes da perna cheia: mt_marks_late")
	r = base.duplicate()
	r.attempts = 2
	r.spins = 3
	n = m.nota_passiva(r, "counter")
	checar(n.id == "mt_held" and n.n == 3, "nota mt_held (3 rodados): %s" % str(n))
	checar_igual(m.nota_passiva(base, "counter").id, "mt_never_hurt", "perna cheia e ele nunca abaixo de 60%: mt_never_hurt")
	# textos: cada id tem frase e dica
	var gs := _novo("f7b1_notas", "muay_thai")
	for id in ["mt_counter", "mt_marks_late", "mt_held", "mt_never_hurt"]:
		var t: Dictionary = gs._textos.passiva_nota_textos({"id": id, "n": 25, "r": 0}, 7)
		checar(str(t.text) != "" and str(t.tip) != "" and not str(t.text).contains("{"), "texto e dica de %s" % id)
	# luta montada: a derrota real de uma luta do Muay Thai traz a nota certa
	var motivo := {}
	var adv := _opp("opp_gym_2")
	var jog := [adv[0] * 0.5, adv[1] * 0.5, adv[2] * 0.5]
	for semente in range(1, 80):
		var res: Dictionary = gs.motor.lutar(jog, adv, "aggressive", semente, false)
		if not res.win:
			motivo = gs.motor.nota_passiva(res, "aggressive")
			break
	checar(not motivo.is_empty() and str(motivo.id).begins_with("mt_"), "derrota real: nota do Muay Thai (%s)" % str(motivo))
	_liberar(gs)


# --- Clique com picos ---
func _teste_clique_com_picos() -> void:
	var gs := _novo("f7b1_clique", "muay_thai")
	checar_igual(gs.bonus_arte_clique(), 0.0, "Muay Thai não tem o bônus de clique do Boxe")
	var cc: Dictionary = gs.bonus_arte_critico()
	checar(is_equal_approx(float(cc.chance), 0.20) and is_equal_approx(float(cc.mult), 4.1), "crítico do clique manual: 20%% e x4,1 (%s)" % str(cc))
	gs._estilo["muay_thai"] = 0.5
	cc = gs.bonus_arte_critico()
	checar(is_equal_approx(float(cc.mult), 4.65) and is_equal_approx(float(cc.chance), 0.20), "com o nó ESTILO: x4,65 e a chance fica 20%")
	gs._estilo["muay_thai"] = 0.0
	checar(gs.texto_regra_arte("muay_thai").contains("20% DE CHANCE") and gs.texto_regra_arte("muay_thai").contains("x4,1"), "texto da regra: %s" % gs.texto_regra_arte("muay_thai"))
	# estatística: 6000 cliques manuais e 6000 automáticos
	gs.rng.seed = 99
	var base: float = gs.por_clique()
	var crit := 0
	var mult_ok := true
	for i in 6000:
		var r: Dictionary = gs.clicar()
		if bool(r.critico):
			crit += 1
			if not _aprox(float(r.ganho), base * 4.1 * gs._loja.mult_frenesi(), 1e-9):
				mult_ok = false
		elif not _aprox(float(r.ganho), base * gs._loja.mult_frenesi(), 1e-9):
			mult_ok = false
	var taxa := float(crit) / 6000.0
	checar(absf(taxa - 0.20) <= 0.025, "clique manual: %.1f%% de crítico (esperado 20%%)" % [100.0 * taxa])
	checar(mult_ok, "o crítico do clique manual vale x4,1 e o normal x1")
	var crit_a := 0
	var mult_a := true
	var base_a: float = gs.por_auto_soco()
	for i in 6000:
		var r: Dictionary = gs.auto_socar()
		if bool(r.critico):
			crit_a += 1
			if not _aprox(float(r.ganho), base_a * 3.0, 1e-9):
				mult_a = false
	var taxa_a := float(crit_a) / 6000.0
	checar(absf(taxa_a - 0.10) <= 0.02 and mult_a, "auto-soco (Metrônomo): 10%% e x3 como sem arte (%.1f%%)" % [100.0 * taxa_a])
	# Boxe e Jiu-jitsu: crítico de sempre
	var gb := _novo("f7b1_clique_boxe", "boxing")
	checar_igual(gb.bonus_arte_critico(), {"chance": 0.1, "mult": 3.0}, "Boxe: crítico do clique de sempre")
	checar(is_equal_approx(gb.bonus_arte_clique(), 0.5), "Boxe: +50% no clique")
	_liberar(gs)
	_liberar(gb)


# --- Liberação pela 1ª vitória contra o Kid ---
func _luta_pronta(gs: Node, ganhou: bool) -> void:
	gs.luta = {"opponent": "opp_gym_2", "tactic": "aggressive", "seed": 1, "player": {"strength": 1.0, "agility": 1.0, "endurance": 1.0},
		"result": {"win": ganhou, "ko": false, "t_ko": -1.0, "t_end": 16.0, "round": 0, "pct_player": 0.5 if ganhou else 0.0,
			"pct_opponent": 0.0 if ganhou else 0.5}}


func _teste_liberacao() -> void:
	# 1ª chegada à academia: só Boxe e Jiu-jitsu
	var gs := _novo("f7b1_lib_mudar")
	gs.cinturao = true
	gs.dinheiro = 1.0e15
	checar(gs.mudar(), "mudar para a academia")
	checar_igual(gs.permanente.arts_unlocked, ["boxing", "bjj"], "1ª chegada à academia: 2 artes (o Muay Thai espera o Kid)")
	checar_igual(gs.artes_para_escolha().size(), 2, "escolha da arte com 2 cartões")
	# vitória contra o Kid
	gs.indice_escada = 5
	var avisos := []
	gs.permanente_mudou.connect(func() -> void: avisos.append(1))
	_luta_pronta(gs, true)
	gs.concluir_luta()
	checar(gs.permanente.arts_unlocked.has("muay_thai"), "1ª vitória contra o Kid libera o Muay Thai")
	checar(gs.marco("muay_thai_unlocked"), "marco muay_thai_unlocked gravado")
	checar(avisos.size() >= 1, "sai permanente_mudou")
	var tem_gatilho := false
	for g in gs._gatilhos_quadro:
		if str(g.id) == "muay_thai_unlocked":
			tem_gatilho = true
	checar(tem_gatilho, "o gatilho da fala do Osmar foi pedido")
	var ctx := {"campaign": 1, "first_campaign": 1, "lutador": "first", "location": "gym", "milestones": gs.escola.milestones, "lines_seen": {}, "params": {}}
	checar(gs.dialogos.candidatas("muay_thai_unlocked", ctx).size() == 1, "a fala cl_muay_thai fica disponível (uma vez)")
	ctx.lines_seen = {"cl_muay_thai": 1}
	checar(gs.dialogos.candidatas("muay_thai_unlocked", ctx).is_empty(), "depois de vista, não repete")
	checar_igual(gs.artes_para_escolha().size(), 3, "a próxima escolha de arte tem 3 cartões")
	var cartao: Dictionary = gs.artes_para_escolha()[2]
	checar(cartao.id == "muay_thai" and str(cartao.rule_text).contains("20% DE CHANCE") and str(cartao.fight_text).begins_with("CANELA") \
		and cartao.apparatus == "kick_bag", "cartão do Muay Thai: regra, passiva e aparelho")
	# no mesmo save da luta: o estado salvo já traz a arte e o marco
	var estado: Dictionary = gs.para_save()
	checar(estado.permanent.arts_unlocked.has("muay_thai") and estado.school.milestones.has("muay_thai_unlocked"), "o save da vitória já traz a arte e o marco")
	# segunda vitória contra o Kid (outra carreira): sem duplicar
	var n_antes: int = gs.permanente.arts_unlocked.size()
	gs.indice_escada = 5
	_luta_pronta(gs, true)
	gs.concluir_luta()
	checar_igual(gs.permanente.arts_unlocked.size(), n_antes, "2ª vitória contra o Kid: sem duplicar a arte")
	# vitória contra outro adversário não libera nada
	var g2 := _novo("f7b1_lib_outro")
	g2.permanente["arts_unlocked"] = ["boxing", "bjj"]
	g2.indice_escada = 4
	g2.local_id = "gym"
	g2.luta = {"opponent": "opp_gym_1", "tactic": "aggressive", "seed": 1, "player": {"strength": 1.0, "agility": 1.0, "endurance": 1.0},
		"result": {"win": true, "ko": false, "t_ko": -1.0, "t_end": 16.0, "round": 0, "pct_player": 0.5, "pct_opponent": 0.0}}
	g2.concluir_luta()
	checar(not g2.permanente.arts_unlocked.has("muay_thai"), "vencer o Dinho não libera o Muay Thai")
	# derrota contra o Kid também não
	var g3 := _novo("f7b1_lib_derrota")
	g3.permanente["arts_unlocked"] = ["boxing", "bjj"]
	g3.indice_escada = 5
	g3.local_id = "gym"
	_luta_pronta(g3, false)
	g3.concluir_luta()
	checar(not g3.permanente.arts_unlocked.has("muay_thai"), "perder para o Kid não libera o Muay Thai")
	# escolher a arte nova só na próxima escolha (a da carreira atual não muda)
	var g4 := _novo("f7b1_lib_escolha")
	g4.permanente["arts_unlocked"] = ["boxing", "bjj"]
	g4.escolher_arte("boxing")
	g4.indice_escada = 5
	g4.local_id = "gym"
	_luta_pronta(g4, true)
	g4.concluir_luta()
	checar_igual(g4.arte_id, "boxing", "a arte da carreira atual não muda")
	checar(g4.permanente.arts_unlocked.has("muay_thai"), "mas o Muay Thai já ficou liberado")
	for g in [gs, g2, g3, g4]:
		_liberar(g)


func _teste_save_antigo() -> void:
	var gs := _novo("f7b1_antigo")
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	# 1) best_wins >= índice do Kid + 1 (6)
	var e1: Dictionary = gs.para_save()
	e1.permanent["best_wins"] = 6
	gs.aplicar_save(e1)
	checar(gs.permanente.arts_unlocked.has("muay_thai"), "save antigo: best_wins 6 recebe o Muay Thai")
	var com_fala := false
	for g in gs._gatilhos_quadro:
		if str(g.id) == "muay_thai_unlocked":
			com_fala = true
	checar(com_fala and gs.marco("muay_thai_unlocked"), "save antigo: a fala sai uma vez (marco ausente)")
	# 2) a carreira atual já passou do Kid
	var e2: Dictionary = gs.para_save()
	e2.permanent["arts_unlocked"] = ["boxing", "bjj"]
	e2.permanent["best_wins"] = 0
	e2.career["ladder_index"] = 6
	e2.school.milestones.erase("muay_thai_unlocked")
	gs.aplicar_save(e2)
	checar(gs.permanente.arts_unlocked.has("muay_thai"), "save antigo: carreira atual além do Kid recebe o Muay Thai")
	# 3) ainda no Kid: nada
	var e3: Dictionary = gs.para_save()
	e3.permanent["arts_unlocked"] = ["boxing", "bjj"]
	e3.permanent["best_wins"] = 5
	e3.career["ladder_index"] = 5
	gs.aplicar_save(e3)
	checar(not gs.permanente.arts_unlocked.has("muay_thai"), "save antigo: quem ainda não venceu o Kid não recebe a arte")
	checar_igual(gs.artes_para_escolha().size(), 2, "quem nunca venceu o Kid vê 2 cartões")
	# 4) marco existe e a fala já foi vista: sem fala repetida
	var e4: Dictionary = gs.para_save()
	e4.permanent["arts_unlocked"] = ["boxing", "bjj"]
	e4.permanent["best_wins"] = 6
	e4.school.milestones["muay_thai_unlocked"] = {"campaign": 1, "version": 1}
	e4.school.lines_seen["cl_muay_thai"] = 1
	gs.aplicar_save(e4)
	var repetiu := false
	for g in gs._gatilhos_quadro:
		if str(g.id) == "muay_thai_unlocked":
			repetiu = true
	checar(gs.permanente.arts_unlocked.has("muay_thai") and not repetiu, "save antigo com a fala vista: sem fala repetida")
	# 5) save sujo: arte inexistente / career.art muay_thai sem liberar vira "sem arte"
	var e5: Dictionary = gs.para_save()
	e5.permanent["arts_unlocked"] = ["boxing", "bjj"]
	e5.permanent["best_wins"] = 0
	e5.career["ladder_index"] = 0
	e5.career["art"] = "muay_thai"
	gs.aplicar_save(e5)
	checar_igual(gs.arte_id, "", "career.art muay_thai sem a arte liberada é ignorada")
	# 6) finish spin_kick só vale com a arte Muay Thai
	var e6: Dictionary = gs.para_save()
	e6.permanent["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	e6.career["art"] = "muay_thai"
	e6.career["ladder_index"] = 3
	e6.career["fight"] = {"opponent": "opp_tank", "tactic": "counter", "seed": 3, "player": {"strength": 1, "agility": 1, "endurance": 1},
		"result": {"win": true, "ko": true, "t_ko": 8.0, "t_end": 8.0, "round": 1, "pct_player": 0.5, "pct_opponent": 0.0, "finish": "spin_kick"}}
	gs.aplicar_save(e6)
	checar_igual(gs.luta.get("result", {}).get("finish", ""), "spin_kick", "luta salva com chute rodado e arte Muay Thai: finish mantido")
	var e7: Dictionary = e6.duplicate(true)
	e7.career["art"] = "boxing"
	gs.aplicar_save(e7)
	checar(not gs.luta.get("result", {}).has("finish"), "finish spin_kick com outra arte é descartado")
	checar(gs.salvar(), "o save com o Muay Thai grava")
	checar_igual(SaveStore.VERSAO_ATUAL, 13, "save continua v13")
	_liberar(gs)


# --- Choque do Muay Thai: combo no tempo ---
func _choque(nivel: int = 0, semente: int = 11) -> ChoqueLogica:
	var mg := MinigamesData.carregar()
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return ChoqueLogica.new(mg.spar, "muay_thai", nivel, rng)


func _andar_ate(c: ChoqueLogica, t: float) -> void:
	# anda em passos de 0,02 s até o relógio do jogo (depois da contagem) chegar em t
	while c.fase == "contagem" or (c.tempo < t - 1.0e-9 and c.fase != "fim"):
		c.passo(0.02)


func _teste_choque_batida() -> void:
	var mg := MinigamesData.carregar()
	checar(mg.spar.variants.has("muay_thai"), "minigames.json: variante muay_thai carregada")
	var v: Dictionary = mg.spar.variants.muay_thai
	checar(is_equal_approx(float(v.beat_s), 0.5) and is_equal_approx(float(v.window_s), 0.12) and int(v.combo_kick) == 3, "batida 0,5 s, janela 0,12 s, 3º clique = chute")
	var c := _choque()
	checar_igual(c.arte, "muay_thai", "ChoqueLogica aceita muay_thai")
	c.apertar()
	checar(c.pegar_eventos().is_empty(), "clique na contagem é ignorado")
	c.soltar()
	_andar_ate(c, 0.5)
	checar(c.estado().na_janela, "na batida 0,5 a janela está aberta")
	c.apertar()
	var ev := c.pegar_eventos()
	checar(ev.has("no_tempo") and c.combo == 1, "1º clique no tempo: combo 1")
	c.soltar()
	c.apertar()  # 2º clique na MESMA batida = fora do tempo
	checar(c.pegar_eventos().has("fora_do_tempo") and c.combo == 0, "2º clique na mesma batida é fora do tempo e zera o combo")
	c.soltar()
	_andar_ate(c, 1.0)
	c.apertar()
	c.soltar()
	checar_igual(c.combo, 1, "batida 1,0: combo 1 de novo")
	_andar_ate(c, 2.0)  # pulou a batida 1,5 (não zera)
	c.apertar()
	c.soltar()
	checar_igual(c.combo, 2, "pular uma batida não zera o combo")
	_andar_ate(c, 2.5)
	var b0 := c.barra
	var chutes0 := c.chutes
	c.apertar()
	ev = c.pegar_eventos()
	c.soltar()
	checar(ev.has("chute") and c.combo == 0 and c.chutes == chutes0 + 1, "3º clique no tempo vira CHUTE e o combo volta a 0")
	checar(c.barra - b0 >= 0.30 - 0.0 or c.estado().congelado, "o chute empurra forte (>= 0,30 com o fôlego cheio)")
	# fora do tempo (meio da batida) zera o combo e empurra pouco
	_andar_ate(c, 3.0)
	c.apertar()
	c.soltar()
	checar_igual(c.combo, 1, "(combo 1 de novo na batida 3,0)")
	_andar_ate(c, 3.25)  # entre batidas
	checar(not c.estado().na_janela, "no meio entre duas batidas a janela está fechada")
	var bf := c.barra
	c.apertar()
	ev = c.pegar_eventos()
	c.soltar()
	checar(ev.has("fora_do_tempo") and c.combo == 0, "clique fora do tempo zera o combo")
	checar(absf(c.barra - bf) <= 0.03 + 1.0e-9 and c.barra >= bf - 1.0e-9 or c.estado().congelado, "empurrão fraco (0,03 x força)")
	# segurar vira guarda (como o Boxe)
	_andar_ate(c, 4.0)
	c.apertar()
	c.passo(0.3)
	checar(c.estado().guarda, "segurar 0,2 s = guarda")
	c.soltar()
	# afobado não marca ponto; no tempo marca (mesma semente, mesmos padrões)
	var afobado := _choque(0, 21)
	var no_tempo := _choque(0, 21)
	while afobado.fase != "fim":
		afobado.passo(0.02)
		if afobado.fase == "jogando" and int(round(afobado.tempo * 50.0)) % 5 == 0:  # 10 cliques por segundo, sem ritmo
			afobado.apertar()
			afobado.soltar()
	var t_b := 0.5
	var feitos := {}
	while no_tempo.fase != "fim":
		no_tempo.passo(0.02)
		if no_tempo.fase == "jogando":
			var k := int(round(no_tempo.tempo / 0.5))
			if k >= 1 and not feitos.has(k) and absf(no_tempo.tempo - k * 0.5) <= 0.02:
				feitos[k] = true
				no_tempo.apertar()
				no_tempo.soltar()
	checar(no_tempo.pontos > afobado.pontos and afobado.pontos == 0, "clicar no tempo rende mais que clicar afobado (%d x %d pontos)" % [no_tempo.pontos, afobado.pontos])
	checar(no_tempo.chutes >= 5 and no_tempo.fora_do_tempo == 0, "no tempo: dá chutes e não erra a batida (%d chutes)" % no_tempo.chutes)
	# determinismo
	var a1 := _choque(2, 5)
	var a2 := _choque(2, 5)
	for i in 2000:
		a1.passo(0.02)
		a2.passo(0.02)
		if i % 25 == 0:
			a1.apertar()
			a1.soltar()
			a2.apertar()
			a2.soltar()
	checar_igual(a1.resultado(), a2.resultado(), "mesma semente e mesmas entradas: mesmo resultado")
	# Boxe continua igual (clique) e arte desconhecida cai no Boxe
	var bx := ChoqueLogica.new(mg.spar, "boxing", 0, RandomNumberGenerator.new())
	_andar_ate(bx, 0.5)
	bx.apertar()
	checar(bx.pegar_eventos().has("clique"), "Boxe: o evento continua 'clique'")
	var estranho := ChoqueLogica.new(mg.spar, "kungfu", 0, RandomNumberGenerator.new())
	checar_igual(estranho.arte, "boxing", "arte desconhecida joga como Boxe")


# --- A luta na tela (campos novos de luta_atual) ---
func _teste_luta_na_tela() -> void:
	var gs := _novo("f7b1_tela", "muay_thai")
	gs.indice_escada = 3
	gs.atributos = {"strength": 3.0e5, "agility": 2.0e5, "endurance": 2.0e5}
	var info: Dictionary = gs.lutar()
	checar(not info.is_empty(), "lutar() com Muay Thai")
	checar_igual(info.passive, "shin", "luta_atual().passive = shin")
	for chave in ["marks_max", "limp_from_marks", "marks_peak", "marks_full_at", "spins"]:
		checar(info.has(chave), "luta_atual() tem %s" % chave)
	var ok_golpes := true
	var ok_marcas := true
	var antes := 0
	var rodado_ok := true
	for e in info.events:
		if not e.has("marks") or not e.has("shin_move"):
			ok_marcas = false
			continue
		if int(e.marks) < antes or int(e.marks) > 3:
			ok_marcas = false
		antes = int(e.marks)
		if int(e.who) == 0 and e.kind != "dodge":
			var id := str(e.move)
			if not (id in ["low_kick", "knee", "thai_clinch", "spin_kick"]):
				ok_golpes = false
			if e.shin_move == "spin" and (e.kind != "spin_kick" or id != "spin_kick" or e.move_anim != "spin_kick"):
				rodado_ok = false
			if e.shin_move == "spin" and e.defender_anim == "hit" and not (e.defender_move_anim in ["hit_spin", "fall_spin"]):
				rodado_ok = false
	checar(ok_golpes, "o jogador só usa golpes do Muay Thai (nenhum de Boxe)")
	checar(ok_marcas, "marcas inteiras crescentes (0-3) em todos os eventos")
	checar(rodado_ok, "todo crítico com a perna cheia é spin_kick com reação hit_spin/fall_spin")
	if str(info.result.finish) == "spin_kick":
		var ult: Dictionary = info.events[info.events.size() - 1]
		checar(ult.finish == "spin_kick" and ult.defender_move_anim == "fall_spin", "chute rodado final: reação fall_spin")
	var de_novo: Dictionary = gs.luta_atual()
	checar_igual(de_novo.result, info.result, "recalcular dá o mesmo resultado")
	# um chute rodado que derruba aparece numa luta montada
	var m: Luta = gs.motor
	var adv := _opp("opp_gym_2")
	var fraco := [adv[0] * 3.0, adv[1] * 3.0, adv[2] * 1.5]
	var achou := false
	gs.indice_escada = 5
	for semente in range(1, 600):
		if m.lutar(fraco, adv, "aggressive", semente, false).finish == "spin_kick":
			gs.luta = {"opponent": "opp_gym_2", "tactic": "aggressive", "seed": semente,
				"player": {"strength": fraco[0], "agility": fraco[1], "endurance": fraco[2]},
				"result": _resultado_de(m.lutar(fraco, adv, "aggressive", semente, false))}
			achou = true
			break
	checar(achou, "achou uma luta com chute rodado final")
	if achou:
		var i2: Dictionary = gs.luta_atual()
		var u: Dictionary = i2.events[i2.events.size() - 1]
		checar(i2.result.finish == "spin_kick" and u.finish == "spin_kick" and u.kind == "spin_kick" and u.defender_move_anim == "fall_spin" and u.ko, "luta montada: último golpe = chute rodado que derruba (fall_spin)")
	_liberar(gs)


func _resultado_de(res: Dictionary) -> Dictionary:
	return {"win": res.win, "ko": res.ko, "t_ko": res.t_ko, "t_end": res.t_end, "round": res.round, "pct_player": res.pct_player,
		"pct_opponent": res.pct_opponent, "finish": res.finish}


# --- Animações: o que a tela usa existe no manifest (idle, golpes, reações, folhas do Choque) ---
func _teste_animacoes_no_manifest() -> void:
	var man: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/manifest.json"))
	var acoes: Dictionary = man.by_data_id.player_fight.actions
	for a in ["mt_idle", "low_kick", "knee", "thai_clinch", "spin_kick"]:
		checar(acoes.has(a) and man.sprites.has(str(acoes[a]) + "_disc"), "jogador: ação %s e folha _disc no manifest" % a)
	for oid in ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]:
		var oa: Dictionary = man.by_data_id[oid].actions
		for r in ["hit_leg", "limp", "limp_heavy", "held_clinch", "fall_spin", "hit_spin"]:
			checar(oa.has(r) and man.sprites.has(str(oa[r])), "%s: reação %s no manifest" % [oid, r])
	for s in ["fighter_low_kick_disc", "fighter_low_kick"]:
		if man.sprites.has(s):
			checar_igual(int(man.sprites[s].frames), 6, "%s: 6 quadros" % s)
	var mt: Dictionary = man.minigame_layout.spar.player_actions.mt
	for k in ["idle", "click", "kick", "guard", "pushed"]:
		checar(mt.has(k), "Choque do Muay Thai: pose %s no manifest" % k)
	var sala := FileAccess.get_file_as_string("res://ui/sala.gd")
	checar(sala.contains('SACO_CHUTE := "kick_bag"') and sala.contains("fighter_low_kick"), "a sala usa fighter_low_kick no saco de chute")
	var mapa := FileAccess.get_file_as_string("res://ui/janela_mapa.gd")
	checar(mapa.contains('"muay_thai"') and mapa.contains('"bjj", "muay_thai", "campaign"'), "o mapa da árvore conhece o chão muay_thai")


# --- Árvore e aparelho ---
func _teste_arvore_e_aparelho() -> void:
	var gs := _novo("f7b1_arvore")
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	checar(not gs.trava_aberta("art:muay_thai"), "região MUAY THAI trancada sem a arte")
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	checar(gs.trava_aberta("art:muay_thai"), "região MUAY THAI abre com a arte liberada")
	for id in ["style_muay_thai", "mt_shin", "mt_oil", "mt_rope"]:
		var n := dados.no_da_arvore(id)
		checar(not n.is_empty(), "nó %s existe" % id)
	var custos := {"mt_shin": 200, "style_muay_thai": 1200, "mt_oil": 400, "mt_rope": 300}
	for id in custos:
		checar_igual(int(dados.no_da_arvore(id).cost), custos[id], "custo de %s" % id)
	checar(dados.regioes.any(func(r): return r.id == "muay_thai" and r.lock == "art:muay_thai"), "região muay_thai com trava art:muay_thai")
	# nó mt_shin aumenta o `extra` da passiva só com o Muay Thai
	gs.escolher_arte("muay_thai")
	gs.permanente["skill_nodes"] = ["mt_shin"]
	gs.nos_ativos_ids = ["mt_shin"]
	gs._arvore._recalcular_bonus()
	gs._academia._atualizar_passiva()
	checar(is_equal_approx(gs.motor.extra_passiva, 0.5), "mt_shin: extra da passiva 0,5")
	gs.nos_ativos_ids = ["style_muay_thai"]
	gs._arvore._recalcular_bonus()
	checar(is_equal_approx(float(gs.bonus_arte_critico().mult), 4.65), "style_muay_thai: crítico x4,65")
	_liberar(gs)
	# aparelho e golpes do aparelho
	var gb := _novo("f7b1_aparelho", "muay_thai")
	checar_igual(gb.academia.arte("muay_thai").apparatus, "kick_bag", "o aparelho da arte é o saco de chute")
	checar(gb.dados.aparelho("kick_bag").crit_texts.size() >= 5, "saco de chute com textos de crítico")
	_liberar(gb)
