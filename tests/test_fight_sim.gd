extends "res://tests/test_base.gd"
## Testa a simulação da luta (scripts/luta.gd): fórmulas, determinismo, limites de tempo, grogue, pontos,
## risco honesto, táticas, motivo da derrota e igualdade com o simulador Python (tools/sim/fase3_sim.py).

const ARQUIVO_CASOS := "res://tests/data/fase3_casos.json"

var dados: FightData
var motor: Luta


func rodar_testes() -> void:
	dados = FightData.carregar()
	motor = Luta.new(dados)
	_teste_formulas()
	_teste_determinismo()
	_teste_limites_de_tempo()
	_teste_grogue()
	_teste_pontos_e_empate()
	_teste_destaque()
	_teste_taticas_mudam_rotulo()
	_teste_cada_tatica_e_a_melhor()
	_teste_foco_unico_perde()
	_teste_risco_honesto()
	_teste_igual_ao_python()
	_teste_estatisticas_e_motivo_do_python()
	_teste_motivo_e_estatistica()
	_teste_pos_qa()


func _aprox(a: float, b: float, rel: float) -> bool:
	return absf(a - b) <= rel * maxf(maxf(absf(a), absf(b)), 1.0e-12)


func _opp(id: String) -> Array:
	var o := dados.adversario(id)
	return [o.strength, o.agility, o.endurance]


# Seção 14: jogador 0/0/0 -> vida 100; Dudu efetivo 1.41K / 310 / 1.01K, vida 5.15K.
func _teste_formulas() -> void:
	var zero := motor.efetivos([0.0, 0.0, 0.0])
	checar_igual(motor.vida_max(zero), 100.0, "jogador 0/0/0: vida 100")
	var ef := motor.efetivos(_opp("opp_warmup"))
	checar(_aprox(ef[0], 1410.0, 1e-9) and _aprox(ef[1], 310.0, 1e-9) and _aprox(ef[2], 1010.0, 1e-9),
		"Dudu efetivo 1410 / 310 / 1010")
	checar(_aprox(motor.vida_max(ef), 5150.0, 1e-9), "Dudu: vida 5150")
	# Dano e redução: atacante F=1410, defensor R=1010 -> bruto 1420, redução 0.5 x 1010/2420
	var g := motor.golpe(ef, ef, Luta.NEUTRA, Luta.NEUTRA)
	var red := 0.5 * 1010.0 / (1410.0 + 1010.0)
	checar(_aprox(g[3], red, 1e-12), "redução = 50% x R / (R + F)")
	checar(_aprox(g[0], 1420.0 * (1.0 - red), 1e-12), "dano = (10 + F) x (1 - redução)")
	checar_igual(g[1], 0.05, "agilidades iguais: crítico 5%")
	checar_igual(g[2], 0.03, "agilidades iguais: esquiva 3%")
	# Agilidade só conta para quem é mais ágil.
	var rapido := motor.efetivos([0.0, 1000.0, 0.0])
	var lento := motor.efetivos([0.0, 0.0, 0.0])
	var gr := motor.golpe(rapido, lento, Luta.NEUTRA, Luta.NEUTRA)
	var gl := motor.golpe(lento, rapido, Luta.NEUTRA, Luta.NEUTRA)
	checar(gr[1] > 0.05 and gl[1] == 0.05, "só o mais ágil ganha crítico")
	checar(gl[2] > 0.03 and gr[2] == 0.03, "só o mais lento ganha esquiva extra")
	var t_contra := dados.tatica("counter")
	var ge := motor.golpe(lento, rapido, Luta.NEUTRA, t_contra)
	checar_igual(ge[2], 0.75, "esquiva nunca passa do teto (0.75)")


func _teste_determinismo() -> void:
	var jog := [8000.0, 8000.0, 8000.0]
	var adv := _opp("opp_strong")
	var a := motor.lutar(jog, adv, "counter", 4242, true)
	var b := motor.lutar(jog, adv, "counter", 4242, true)
	checar_igual(a, b, "mesma semente + mesmo estado = mesma luta, golpe a golpe")
	var diferentes := 0
	for s in range(1, 30):
		if motor.lutar(jog, adv, "counter", s, true).events != a.events:
			diferentes += 1
	checar(diferentes >= 25, "sementes diferentes dão lutas diferentes")
	# Cada ataque consome exatamente 3 sorteios.
	var sorteios := PackedFloat64Array()
	for i in 300:
		sorteios.append(0.5)
	var c := motor.lutar_com_sorteios(jog, adv, "counter", sorteios, true)
	checar_igual(c.draws_used % 3, 0, "3 sorteios por ataque")
	checar_igual(c.draws_used, 3 * c.events.size(), "um evento por ataque (3 sorteios cada)")


# Critérios 5 e 6.3: 10.000 lutas de estados variados.
func _teste_limites_de_tempo() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var menor := INF
	var maior := 0.0
	var ult_evento := 0.0
	var kos := 0
	var n := 10000
	for i in n:
		var estado := _estado_variado(rng)
		var r := motor.lutar(estado[0], estado[1], estado[2], rng.randi(), true)
		var tela := motor.tela(r)
		menor = minf(menor, tela)
		maior = maxf(maior, tela)
		if r.ko:
			kos += 1
		if not r.events.is_empty():
			ult_evento = maxf(ult_evento, r.events[-1].t)
	checar(menor >= 8.0 - 1e-9, "10.000 lutas: tela mínima %.2f s >= 8 s" % menor)
	checar(maior <= 19.0 + 1e-9, "10.000 lutas: tela máxima %.2f s <= 19 s" % maior)
	checar(ult_evento <= 16.0 + 1e-9, "nenhum evento depois de 16 s (último em %.3f)" % ult_evento)
	checar(kos > n / 2, "a maioria termina em K.O. (%d%%)" % (100 * kos / n))


# Estados variados em volta dos adversários (como o simulador): treino 0,15x a 6x o dele.
func _estado_variado(rng: RandomNumberGenerator) -> Array:
	var o: Dictionary = dados.adversarios[rng.randi() % dados.adversarios.size()]
	var adv := [o.strength, o.agility, o.endurance]
	var tot: float = (adv[0] + adv[1] + adv[2]) * exp(rng.randf_range(log(0.15), log(6.0)))
	var w := [pow(rng.randf(), 2.0), pow(rng.randf(), 2.0), pow(rng.randf(), 2.0)]
	var s: float = maxf(w[0] + w[1] + w[2], 1.0e-12)
	var jog := [tot * w[0] / s, tot * w[1] / s, tot * w[2] / s]
	return [jog, adv, dados.taticas[rng.randi() % dados.taticas.size()].id]


# Seção 4.4: K.O. antes de 5 s vira grogue (t_end = 5.0) e o vencedor não muda.
func _teste_grogue() -> void:
	var r := motor.lutar([0.0, 0.0, 0.0], _opp("opp_strong"), "defensive", 3, true)
	checar(r.ko and not r.win, "jogador zerado cai para o Brutão")
	checar(r.t_ko < 5.0, "K.O. antes de 5 s (t_ko = %.2f)" % r.t_ko)
	checar_igual(r.t_end, 5.0, "grogue: a luta só termina em 5.0 s")
	checar_igual(r.round, 1, "K.O. no 1º round")
	checar_igual(r.pct_player, 0.0, "quem caiu fica com 0% de vida")
	checar(_aprox(motor.tela(r), 8.0, 1e-9), "tela de 8.0 s no K.O. mais cedo")
	# Sem grogue: K.O. tardio mantém t_end = t_ko.
	var tardio := 0
	for s in range(1, 200):
		var x := motor.lutar([700.0, 700.0, 700.0], _opp("opp_warmup"), "aggressive", s)
		if x.ko and x.t_ko > 5.0:
			tardio += 1
			if absf(x.t_end - x.t_ko) > 1e-12:
				checar(false, "K.O. depois de 5 s: t_end = t_ko")
				return
	checar(tardio > 0, "existem K.O. depois de 5 s, sem grogue")


# Seção 4.5: sem K.O. vence quem tem mais % de vida; empate exato fica com o adversário.
func _teste_pontos_e_empate() -> void:
	# Seu Muralha tem muita vida: sem dano suficiente vai aos pontos.
	var r := {}
	for s in range(1, 100):
		r = motor.lutar([200000.0, 200000.0, 200000.0], _opp("opp_tank"), "aggressive", s)
		if not r.ko:
			break
	checar(not r.ko, "perfil do Seu Muralha vai aos pontos")
	checar_igual(r.t_end, 16.0, "sem K.O.: termina em 16 s")
	checar_igual(r.win, r.pct_player > r.pct_opponent, "pontos: vence quem tem mais % de vida")
	# Empate exato: dois lutadores iguais, sorteios neutros (sem esquiva, sem crítico, variação 0), tempo 15 s
	# -> 8 golpes de cada lado, mesma vida -> vence o adversário.
	var pasta := pasta_limpa("fight_empate")
	var texto := ler("res://data/fights.json").replace('"time_limit": 16.0', '"time_limit": 15.0')
	escrever(pasta + "fights.json", texto)
	var d2 := FightData.carregar(pasta + "fights.json")
	checar_igual(d2.combate.time_limit, 15.0, "dado de teste com 15 s")
	var m2 := Luta.new(d2)
	var sorteios := PackedFloat64Array()
	for i in 300:
		sorteios.append(0.5)
	var e := m2.lutar_com_sorteios([0.0, 0.0, 0.0], [0.0, 0.0, 0.0], "none", sorteios, true)
	checar(not e.ko, "iguais com golpes neutros não dão K.O. em 15 s")
	checar_igual(e.pct_player, e.pct_opponent, "% de vida exatamente igual")
	checar(not e.win, "empate exato: vence o adversário")
	checar_igual(e.counts.player.hits, 8, "8 golpes do jogador")
	checar_igual(e.counts.opponent.hits, 8, "8 golpes do adversário")
	# Com 16 s o jogador (que ataca primeiro) dá um golpe a mais e vence.
	var e2 := motor.lutar_com_sorteios([0.0, 0.0, 0.0], [0.0, 0.0, 0.0], "none", sorteios, true)
	checar(e2.win and e2.counts.player.hits == 9, "com 16 s o jogador acerta 9 x 8 e vence")


func _teste_destaque() -> void:
	var dudu := _opp("opp_warmup")
	checar_igual(motor.destaque([0.0, 0.0, 0.0], dudu), "strength", "zerado: a maior razão é a Força (1200x)")
	checar_igual(motor.destaque([1200.0, 100.0, 800.0], dudu), "", "iguais: sem destaque")
	checar_igual(motor.destaque([1200.0, 100.0, 100.0], dudu), "endurance", "ele aguenta 8x mais")
	checar_igual(motor.destaque([100.0, 100.0, 800.0], dudu), "strength", "ele é 12x mais forte")
	var dinho := _opp("opp_fast")
	checar_igual(motor.destaque([20000.0, 1000.0, 6000.0], dinho), "agility", "Dinho: muito mais rápido")
	# Empate exato de razão: Resistência, Força, Agilidade.
	checar_igual(motor.destaque([1.0, 1.0, 1.0], [5.0, 5.0, 5.0]), "endurance", "empate: Resistência primeiro")
	checar_igual(motor.destaque([1.0, 1.0, 5.0], [5.0, 5.0, 5.0]), "strength", "empate sem Resistência: Força")


# Critério 2: trocar a tática muda o rótulo (equilibrado 1/3 com 25.3K contra o Brutão).
func _teste_taticas_mudam_rotulo() -> void:
	var jog := [25300.0 / 3.0, 25300.0 / 3.0, 25300.0 / 3.0]
	var adv := _opp("opp_strong")
	var pc := motor.chance(jog, adv, "counter")
	var pd := motor.chance(jog, adv, "defensive")
	checar_igual(motor.rotulo(pc), "even", "contra-ataque contra o Brutão: EQUILIBRADO (%.0f%%)" % (100.0 * pc))
	checar_igual(motor.rotulo(pd), "hard", "defensivo contra o Brutão: PERIGOSO (%.0f%%)" % (100.0 * pd))
	checar_igual(motor.rotulo_rapido(jog, adv, "counter"), motor.rotulo(pc), "rótulo rápido = rótulo da conta completa (contra-ataque)")
	checar_igual(motor.rotulo_rapido(jog, adv, "defensive"), motor.rotulo(pd), "rótulo rápido = rótulo da conta completa (defensivo)")


# Critério 10: cada tática é a melhor contra pelo menos um adversário (perfil equilibrado, treino em que a
# melhor dá ~65%).
func _teste_cada_tatica_e_a_melhor() -> void:
	var treino := {"opp_warmup": 1730.0, "opp_strong": 25300.0, "opp_fast": 75200.0, "opp_tank": 514000.0}
	var melhor_de := {}
	for id in treino:
		var t: float = treino[id]
		var jog := [t / 3.0, t / 3.0, t / 3.0]
		var melhor := ""
		var melhor_p := -1.0
		for tat in dados.taticas:
			var p := motor.chance(jog, _opp(id), tat.id, 1500)
			if p > melhor_p:
				melhor_p = p
				melhor = tat.id
		melhor_de[id] = melhor
	checar_igual(melhor_de.opp_warmup, "counter", "Dudu: melhor tática = contra-ataque")
	checar_igual(melhor_de.opp_strong, "counter", "Brutão: melhor tática = contra-ataque")
	checar_igual(melhor_de.opp_fast, "defensive", "Dinho: melhor tática = defensivo")
	checar_igual(melhor_de.opp_tank, "aggressive", "Seu Muralha: melhor tática = agressivo")


# Critério 9: com o mesmo treino total, o "só Força" perde onde o equilibrado vence.
func _teste_foco_unico_perde() -> void:
	var treino := {"opp_warmup": 1960.0, "opp_strong": 28200.0, "opp_fast": 83100.0, "opp_tank": 555000.0}
	for id in treino:
		var t: float = treino[id]
		var melhor_so := 0.0
		var melhor_eq := 0.0
		for tat in dados.taticas:
			melhor_so = maxf(melhor_so, motor.chance([t, 0.0, 0.0], _opp(id), tat.id, 300))
			melhor_eq = maxf(melhor_eq, motor.chance([t / 3.0, t / 3.0, t / 3.0], _opp(id), tat.id, 300))
		checar(melhor_eq - melhor_so >= 0.4, "%s: equilibrado %.0f%% x só Força %.0f%% com o mesmo treino"
			% [id, 100.0 * melhor_eq, 100.0 * melhor_so])


# Critério 3: risco honesto, 500 lutas por rótulo (rótulo pelas sementes 1..200, resultado com semente nova).
func _teste_risco_honesto() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var caixas := {"easy": [0, 0], "even": [0, 0], "hard": [0, 0]}  # [vitórias, lutas]
	var meta := 500
	var tentativas := 0
	while tentativas < 20000 and (caixas.easy[1] < meta or caixas.even[1] < meta or caixas.hard[1] < meta):
		tentativas += 1
		var e := _estado_variado(rng)
		var rot := motor.rotulo(motor.chance(e[0], e[1], e[2]))
		if caixas[rot][1] >= meta:
			continue
		var r := motor.lutar(e[0], e[1], e[2], 1000000 + rng.randi() % 2000000000)
		caixas[rot][1] += 1
		if r.win:
			caixas[rot][0] += 1
	var fa: float = float(caixas.easy[0]) / maxf(1.0, caixas.easy[1])
	var eq: float = float(caixas.even[0]) / maxf(1.0, caixas.even[1])
	var pe: float = float(caixas.hard[0]) / maxf(1.0, caixas.hard[1])
	checar(caixas.easy[1] >= meta and caixas.even[1] >= meta and caixas.hard[1] >= meta, "500 lutas por rótulo (%d/%d/%d)"
		% [caixas.easy[1], caixas.even[1], caixas.hard[1]])
	checar(fa >= 0.85, "FÁCIL vence %.1f%% (>= 85%%)" % (100.0 * fa))
	checar(eq >= 0.40 and eq <= 0.85, "EQUILIBRADO vence %.1f%% (40%% a 85%%)" % (100.0 * eq))
	checar(pe < 0.40, "PERIGOSO vence %.1f%% (< 40%%)" % (100.0 * pe))


# Mesma luta, golpe a golpe, com os mesmos sorteios do simulador Python.
func _teste_igual_ao_python() -> void:
	var casos = _ler_casos()
	if casos == null:
		return
	var exatos: Array = casos.exatos
	var iguais := 0
	var primeira_falha := ""
	for c in exatos:
		var sorteios := PackedFloat64Array(c.draws)
		var r := motor.lutar_com_sorteios(c.player, c.opponent, c.tactic, sorteios, true)
		var erro := _comparar(r, c)
		if erro == "":
			iguais += 1
		elif primeira_falha == "":
			primeira_falha = "%s (jogador %s, adversário %s, %s)" % [erro, str(c.player), str(c.opponent), c.tactic]
	checar_igual(iguais, exatos.size(), "GDScript = Python em %d lutas com sorteios iguais%s"
		% [exatos.size(), "" if primeira_falha == "" else " | 1ª falha: " + primeira_falha])


func _comparar(r: Dictionary, c: Dictionary) -> String:
	if r.win != c.win or r.ko != c.ko:
		return "resultado (win/ko)"
	if absf(r.t_ko - c.t_ko) > 1e-9 or absf(r.t_end - c.t_end) > 1e-9:
		return "t_ko/t_end"
	if not _aprox(r.pct_player, c.pct_player, 1e-9) or not _aprox(r.pct_opponent, c.pct_opponent, 1e-9):
		return "% de vida"
	if r.draws_used != c.draws.size():
		return "sorteios consumidos %d x %d" % [r.draws_used, c.draws.size()]
	if r.events.size() != c.events.size():
		return "número de eventos %d x %d" % [r.events.size(), c.events.size()]
	for i in r.events.size():
		var e: Dictionary = r.events[i]
		var p: Array = c.events[i]
		if absf(e.t - p[0]) > 6e-4 or e.who != int(p[1]) or e.type != p[2] or e.counter != p[3]:
			return "evento %d" % i
		# O simulador não registra dano/vida na esquiva.
		if e.type != "dodge" and (not _aprox(e.damage, p[4], 1e-7) or not _aprox(e.life_after, p[5], 1e-7)):
			return "dano/vida do evento %d" % i
	var cj: Dictionary = r.counts.player
	var co: Dictionary = r.counts.opponent
	var k: Dictionary = c.counts
	if cj.hits != int(k.acertos[0]) or co.hits != int(k.acertos[1]) or cj.dodges != int(k.esquivas[0]) \
			or co.dodges != int(k.esquivas[1]) or cj.crits != int(k.crits[0]) or co.crits != int(k.crits[1]) \
			or cj.counters != int(k.contras[0]) or co.counters != int(k.contras[1]):
		return "contagens"
	return ""


# O gerador é outro: compara chance (1.000 sementes) e rótulo dentro de uma tolerância, e o atributo decisivo.
func _teste_estatisticas_e_motivo_do_python() -> void:
	var casos = _ler_casos()
	if casos == null:
		return
	var dentro := 0
	var rotulos_ok := 0
	var total: int = casos.estatisticas.size()
	for c in casos.estatisticas:
		var p := motor.chance(c.player, c.opponent, c.tactic, 1000)
		if absf(p - c.chance) <= 0.08:
			dentro += 1
		var perto := false
		for lim in [dados.risco.easy_min, dados.risco.even_min]:
			if absf(c.chance - lim) < 0.06:
				perto = true
		if perto or motor.rotulo(p) == {"facil": "easy", "equilibrado": "even", "perigoso": "hard"}[c.label]:
			rotulos_ok += 1
	checar_igual(dentro, total, "chance do GDScript dentro de 8 pontos da do Python em %d estados" % total)
	checar_igual(rotulos_ok, total, "rótulo igual ao do Python (fora da beira das faixas)")
	var iguais := 0
	for c in casos.motivos:
		var m := motor.motivo(c.player, c.opponent, c.tactic)
		if m.attribute == c.attribute:
			iguais += 1
	checar_igual(iguais, casos.motivos.size(), "atributo decisivo igual ao do Python em %d derrotas" % casos.motivos.size())
	# Explicação pós-QA: kind (luck/missing) e atributo iguais aos do Python em estados claros.
	var expl_ok := 0
	for c in casos.explicacoes:
		var p := motor.chance(c.player, c.opponent, c.tactic)
		var e := motor.explicar(c.player, c.opponent, c.tactic, 1, p)
		if e.kind == c.kind and e.attribute == c.attribute:
			expl_ok += 1
	checar_igual(expl_ok, casos.explicacoes.size(), "kind e atributo do motivo iguais ao do Python em %d casos" % casos.explicacoes.size())


# Motivo: o atributo decisivo é o que, com menos treino, deixa a luta FÁCIL.
func _teste_motivo_e_estatistica() -> void:
	# Só-saco contra o Dinho: o decisivo é Resistência (design 13.7).
	var jog := [30000.0, 0.0, 0.0]
	var adv := _opp("opp_fast")
	var m := motor.motivo(jog, adv, "defensive")
	checar(m.faltaram >= 0.0, "existe 'faltaram' (nenhum atributo precisa de mais de 16x o total)")
	checar_igual(m.attribute, "endurance", "só-saco contra o Dinho: o decisivo é a Resistência")
	var com_extra := [jog[0], jog[1], jog[2] + m.faltaram * 1.05]
	checar(motor.chance(com_extra, adv, "defensive") >= 0.88, "com 'faltaram' (+5%) a luta fica fácil")
	checar(motor.chance([jog[0], jog[1], jog[2] + m.faltas.endurance * 0.4], adv, "defensive") < 0.9,
		"com bem menos que 'faltaram' ainda não é fácil")
	# Estatística do registro.
	var r := motor.lutar(jog, adv, "defensive", 12, true)
	var est := motor.estatistica("endurance", r, jog, adv, "defensive")
	checar_igual(est.kind, "life_taken", "estatística de Resistência: vida tirada")
	checar(est.n >= 0 and est.k >= 0, "n e k existem")
	var est2 := motor.estatistica("strength", r, jog, adv, "defensive")
	checar(est2.kind in ["stronger", "stronger_x", "stronger_cap"], "estatística de Força: bate mais forte (%s)" % est2.kind)
	var est3 := motor.estatistica("agility", r, jog, adv, "defensive")
	checar(est3.kind in ["dodged", "crits", "life_taken", "stronger", "stronger_x", "stronger_cap"], "estatística de Agilidade: válida (%s)" % est3.kind)


func _ler_casos() -> Variant:
	if not FileAccess.file_exists(ARQUIVO_CASOS):
		checar(false, "arquivo de casos do Python existe (rode tools/sim/exportar_casos.py)")
		return null
	var casos = JSON.parse_string(ler(ARQUIVO_CASOS))
	checar(casos is Dictionary and casos.has("exatos"), "casos do Python legíveis")
	return casos if casos is Dictionary else null


# Pós-QA (design §16.7): azar, teto novo da busca, validade das estatísticas, último recurso.
func _teste_pos_qa() -> void:
	# Azar: estado com chance >= 0.90 e semente que perde -> luck, sem busca, sem atributo.
	var adv := _opp("opp_warmup")
	var achou := false
	for t in range(100, 3000, 100):
		var jog := [float(t), float(t) * 0.3, float(t) * 0.5]
		var p := motor.chance(jog, adv, "counter")
		if p < 0.90 or p >= 1.0:
			continue
		for sem in range(1, 3000):
			if not motor.lutar(jog, adv, "counter", sem).win:
				var e := motor.explicar(jog, adv, "counter", sem, p)
				checar_igual(e.kind, "luck", "azar: p=%.3f e derrota -> luck" % p)
				checar_igual(e.attribute, "", "azar: sem atributo")
				checar_igual(e.faltaram, -1.0, "azar: sem faltaram")
				checar(e.stat.kind in ["crits", "dodged", "luck_odds", "luck_rare"], "azar: estatística de azar (%s)" % e.stat.kind)
				achou = true
				break
		if achou:
			break
	checar(achou, "azar: achou estado com chance >= 0.90 que perde")
	# Teto novo: só Força com T = 500 contra o Brutão -> missing com faltaram acima de 16 x T + 1000.
	var brutao := _opp("opp_strong")
	var jog2 := [500.0, 0.0, 0.0]
	var p2 := motor.chance(jog2, brutao, "counter")
	var e2 := motor.explicar(jog2, brutao, "counter", 1, p2)
	checar_igual(e2.kind, "missing", "teto novo: só Força T=500 vs Brutão é missing")
	checar(e2.faltaram > 16.0 * 500.0 + 1000.0, "teto novo: faltaram %.0f > 16 x T + 1000" % e2.faltaram)
	# Estatística: nunca 'stronger' fora de 20-99; Brutão com T = 8.6K só Agilidade -> stronger_cap n = 10.
	var jog3 := [0.0, 8600.0, 0.0]
	var r3 := motor.lutar(jog3, brutao, "counter", 3, true)
	var s3 := motor.estatistica("strength", r3, jog3, brutao, "counter")
	checar(s3.kind != "stronger" or (s3.n >= 20 and s3.n < 100), "stronger só entre 20 e 99")
	checar_igual(s3.kind, "stronger_cap", "Brutão com só Agilidade: soco dele vale MAIS DE 10")
	checar_igual(s3.n, 10, "stronger_cap com n = 10")
	var visto := 0
	for adv_id in ["opp_warmup", "opp_strong", "opp_fast", "opp_tank"]:
		for tot in [100.0, 1000.0, 10000.0, 100000.0]:
			for sem in [1, 2, 3]:
				var j := [tot * 0.5, tot * 0.3, tot * 0.2]
				var rr := motor.lutar(j, _opp(adv_id), "defensive", sem, true)
				for chave in ["strength", "endurance", "agility", "luck"]:
					var st := motor.estatistica(chave, rr, j, _opp(adv_id), "defensive", 0.95)
					visto += 1
					if st.kind == "stronger" and (st.n < 20 or st.n >= 100):
						checar(false, "stronger fora da faixa: %d" % st.n)
					if st.kind == "dodged" and st.n < 20:
						checar(false, "esquiva abaixo de 20%%: %d" % st.n)
					if st.kind == "life_taken" and st.n < 10:
						checar(false, "vida tirada abaixo de 10%%: %d" % st.n)
	checar(visto > 0, "estatísticas percorridas: %d" % visto)
	# Último recurso: K.O. -> sempre há estatística; pontos sem outra válida -> points.
	var igual := _opp("opp_warmup")
	var fake := {"ko": false, "pct_player": 0.4, "pct_opponent": 0.5, "life_max": [100.0, 100.0],
		"counts": {"player": {"damage": 0.0, "hits": 0, "crits": 0, "normal_attacks": 0, "dodges": 0, "attacks": 0, "counters": 0},
		"opponent": {"damage": 0.0, "hits": 0, "crits": 0, "normal_attacks": 0, "dodges": 0, "attacks": 0, "counters": 0}}}
	var pt := motor.estatistica("endurance", fake, igual, igual, "counter")
	checar_igual(pt.kind, "points", "pontos sem outra estatística válida: points")
	checar_igual(pt.n, 40, "points: sua vida 40%")
	checar_igual(pt.k, 50, "points: vida dele 50%")
	fake.ko = true
	checar_igual(motor.estatistica("endurance", fake, igual, igual, "counter").kind, "life_taken", "K.O. sem outra: life_taken")
	# luck_odds / luck_rare
	checar_igual(motor.estatistica("luck", fake, igual, igual, "counter", 0.91).kind, "luck_odds", "azar com p=0.91: luck_odds")
	checar_igual(motor.estatistica("luck", fake, igual, igual, "counter", 0.91).n, 9, "luck_odds n = 9")
	checar_igual(motor.estatistica("luck", fake, igual, igual, "counter", 0.999).kind, "luck_rare", "azar com p=0.999: luck_rare")
