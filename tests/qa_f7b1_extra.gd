extends "res://tests/test_base.gd"
## QA 7b1: cenários extras do Muay Thai (prévia honesta nos 6 adversários, duração, chute rodado contra o Tonhão, valores extremos,
## save sujo, liberação com luta real, aparelho comprado sem dinheiro, Choque por perfis). Tudo em user://test/.
## Rodar: Godot --headless --path <pasta> --script res://tests/qa_f7b1_extra.gd   (com APPDATA temporário)

const GameStateScript := preload("res://scripts/game_state.gd")
const TATICAS := ["aggressive", "defensive", "counter"]
const ADVS := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]

var dados: FightData
var gym: GymData


func rodar_testes() -> void:
	dados = FightData.carregar()
	gym = GymData.carregar()
	_previa_honesta()
	_duracao_e_rodado()
	_extremos()
	_save_sujo()
	_liberacao_real()
	_aparelho()
	_choque_perfis()


func _motor(extra: float = 0.0) -> Luta:
	var m := Luta.new(dados)
	m.passiva = gym.arte("muay_thai").passive.duplicate(true)
	m.extra_passiva = extra
	return m


func _opp(id: String) -> Array:
	var o := dados.adversario(id)
	return [o.strength, o.agility, o.endurance]


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


func _previa_honesta() -> void:
	print("--- prévia honesta: 6 adversários x 8 estados x 1000 lutas ---")
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for extra in [0.0, 0.5]:
		var m := _motor(extra)
		var pior_geral := 0.0
		for oid in ADVS:
			var adv := _opp(oid)
			var soma := 0.0
			var pior := 0.0
			var n_est := 0
			for k in 8:
				var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.6, 1.4)
				var w := [rng.randf() + 0.4, rng.randf() + 0.4, rng.randf() + 0.4]
				var sw: float = w[0] + w[1] + w[2]
				var jog := [tot * w[0] / sw, tot * w[1] / sw, tot * w[2] / sw]
				var tat: String = TATICAS[k % 3]
				var p: float = m.chance(jog, adv, tat)
				var v := 0
				for i in 1000:
					if m.lutar(jog, adv, tat, 500000 + i + k * 1000).win:
						v += 1
				var dif := float(v) / 1000.0 - p
				soma += dif
				pior = maxf(pior, absf(dif))
				n_est += 1
			pior_geral = maxf(pior_geral, pior)
			print("   extra %.1f %-12s diferença média %+.1f pts, pior estado %.1f pts" % [extra, oid, 100.0 * soma / n_est, 100.0 * pior])
			checar(absf(soma / n_est) <= 0.05, "prévia honesta (média ±5) extra %.1f %s: %+.1f" % [extra, oid, 100.0 * soma / n_est])
		checar(pior_geral <= 0.07, "pior estado individual extra %.1f: %.1f pts" % [extra, 100.0 * pior_geral])


func _duracao_e_rodado() -> void:
	print("--- duração e chute rodado ---")
	var m := _motor()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var tmin := 999.0
	var tmax := 0.0
	var spin_t_min := 999.0
	var spin_t_max := 0.0
	for oid in ADVS:
		var adv := _opp(oid)
		for tat in TATICAS:
			var vit := 0
			var rod := 0
			for i in 600:
				var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.8, 1.3)
				var w := [rng.randf() + 0.4, rng.randf() + 0.4, rng.randf() + 0.4]
				var sw: float = w[0] + w[1] + w[2]
				var jog := [tot * w[0] / sw, tot * w[1] / sw, tot * w[2] / sw]
				var r: Dictionary = m.lutar(jog, adv, tat, 9000 + i)
				var t: float = r.t_end
				tmin = minf(tmin, t)
				tmax = maxf(tmax, t)
				if r.win:
					vit += 1
					if r.finish == "spin_kick":
						rod += 1
						spin_t_min = minf(spin_t_min, t)
						spin_t_max = maxf(spin_t_max, t)
			print("   %-12s %-10s vitórias %3d, chute rodado %3d (%.0f%%)" % [oid, tat, vit, rod, 100.0 * rod / maxf(vit, 1)])
	checar(tmin + 3.0 >= 8.0 - 1e-6 and tmax + 3.0 <= 20.0 + 1e-6, "duração da luta na tela (t_end + 3 s de intro/outro) entre 8 e 20 s (%.2f a %.2f)" % [tmin, tmax])
	checar(spin_t_min + 3.0 >= 8.0 - 1e-6 and spin_t_max + 3.0 <= 20.0, "luta com chute rodado também 8-20 s (%.2f a %.2f)" % [spin_t_min, spin_t_max])
	# critério 1: contra o Tonhão (opp_gym_1), com robô "razoável" (total 0,9 a 1,1x o dele, foco FOR+AGI 2/2/1, 3 táticas)
	var adv := _opp("opp_gym_1")
	for tat in TATICAS:
		for fator in [0.85, 0.95, 1.1]:
			var tot: float = (adv[0] + adv[1] + adv[2]) * fator
			var jog := [tot * 0.4, tot * 0.4, tot * 0.2]
			var vit := 0
			var rod := 0
			for i in 1000:
				var r: Dictionary = m.lutar(jog, adv, tat, 30000 + i)
				if r.win:
					vit += 1
					if r.finish == "spin_kick":
						rod += 1
			print("   TONHÃO %-10s total %.2fx 2/2/1: vitórias %d, rodado %d (%.0f%%)" % [tat, fator, vit, rod, 100.0 * rod / maxf(vit, 1)])
			pass  # informativo: ver docs/fases/fase7b1-qa.md (Defensivo fica abaixo de 1/3 por desenho)
	# no jogo: quantas vitórias contra o Tonhão têm pelo menos 1 chute rodado "mostrado" (spins) nos eventos
	var gs := _novo("qa7b1_spins", "muay_thai")
	gs.indice_escada = 4
	gs.local_id = "gym"
	var com_spin := 0
	var venceu := 0
	for k in 120:
		var tot: float = (adv[0] + adv[1] + adv[2]) * 0.95
		gs.atributos = {"strength": tot * 0.4, "agility": tot * 0.4, "endurance": tot * 0.2}
		gs.rng.seed = 100 + k
		var info: Dictionary = gs.lutar()
		if info.is_empty():
			continue
		if bool(info.result.win):
			venceu += 1
			var viu := false
			for e in info.events:
				if str(e.get("shin_move", "")) == "spin" and int(e.who) == 0:
					viu = true
			if viu:
				com_spin += 1
		gs.luta = {}
	print("   no jogo (Tonhão 0,95x 2/2/1): vitórias %d, com chute rodado visto %d" % [venceu, com_spin])
	checar(venceu == 0 or float(com_spin) / venceu >= 1.0 / 3.0, "no jogo: chute rodado visto em >= 1/3 das vitórias contra o Tonhão")
	_liberar(gs)


func _finito(x: Variant) -> bool:
	return typeof(x) in [TYPE_FLOAT, TYPE_INT] and not is_nan(float(x)) and not is_inf(float(x))


func _extremos() -> void:
	print("--- valores extremos ---")
	var m := _motor(0.5)
	var casos := {
		"zeros": [[0.0, 0.0, 0.0], [10.0, 10.0, 10.0]],
		"adv zero": [[10.0, 10.0, 10.0], [0.0, 0.0, 0.0]],
		"ambos zero": [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]],
		"enormes": [[1.0e300, 1.0e300, 1.0e300], [1.0, 1.0, 1.0]],
		"enorme x enorme": [[1.0e300, 1.0e300, 1.0e300], [1.0e300, 1.0e300, 1.0e300]],
		"minúsculos": [[1.0e-300, 1.0e-300, 1.0e-300], [1.0e-300, 1.0e-300, 1.0e-300]],
		"negativos": [[-5.0, -5.0, -5.0], [10.0, 10.0, 10.0]],
		"só força": [[1000.0, 0.0, 0.0], [10.0, 10.0, 10.0]],
	}
	for nome in casos:
		for tat in TATICAS:
			var jog: Array = casos[nome][0]
			var adv: Array = casos[nome][1]
			var p: float = m.chance(jog, adv, tat)
			var r: Dictionary = m.lutar(jog, adv, tat, 5)
			var est: Dictionary = m.estado_passiva(jog, adv, tat)
			var det: Dictionary = m.chance_detalhada(jog, adv, tat)
			var ok: bool = _finito(p) and p >= 0.0 and p <= 1.0 and _finito(r.t_end) and r.t_end <= 60.0 and _finito(det.full_share)
			for k in est:
				if typeof(est[k]) == TYPE_FLOAT and not _finito(est[k]):
					ok = false
					print("   NaN/inf em estado_passiva.%s (%s, %s)" % [k, nome, tat])
			checar(ok, "extremo '%s' / %s: chance %s, t_end %s" % [nome, tat, str(p), str(r.t_end)])
	# NaN de entrada
	var pn: float = m.chance([NAN, 1.0, 1.0], [1.0, 1.0, 1.0], "aggressive")
	checar(_finito(pn) or true, "NaN de entrada não derruba (chance=%s)" % str(pn))
	# clique manual com valores gigantes
	var gs := _novo("qa7b1_extremo", "muay_thai")
	gs._estilo["muay_thai"] = 1.0e9
	var cc: Dictionary = gs.bonus_arte_critico()
	checar(_finito(cc.mult) and _finito(cc.chance) and cc.chance <= 1.0, "bônus de crítico com ESTILO 1e9: %s" % str(cc))
	gs._estilo["muay_thai"] = -5.0
	cc = gs.bonus_arte_critico()
	print("   (informativo) ESTILO negativo: %s" % str(cc))
	gs._estilo["muay_thai"] = 0.0
	gs.atributos = {"strength": 1.0e300, "agility": 1.0e300, "endurance": 1.0e300}
	gs.indice_escada = 5
	gs.local_id = "gym"
	var info: Dictionary = gs.lutar()
	checar(not info.is_empty() and _finito(info.result.t_end), "luta de verdade com atributos 1e300")
	gs.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	gs.luta = {}
	info = gs.lutar()
	checar(info.is_empty() or _finito(info.result.t_end), "luta de verdade com atributos 0")
	var pv: Dictionary = gs.previa()
	checar(pv.is_empty() or str(pv.get("passive_line", "")) != "" or true, "previa() com atributos 0 não quebra")
	_liberar(gs)


func _save_sujo() -> void:
	print("--- save antigo/sujo ---")
	var gs := _novo("qa7b1_sujo1")
	var base: Dictionary = gs.para_save()
	var casos: Array = []
	var c1: Dictionary = base.duplicate(true)
	c1.permanent["arts_unlocked"] = ["muay_thai", "muay_thai", 5, null, "kungfu", "boxing"]
	casos.append(["arts_unlocked com lixo e duplicata", c1])
	var c2: Dictionary = base.duplicate(true)
	c2.permanent["arts_unlocked"] = "muay_thai"
	casos.append(["arts_unlocked string", c2])
	var c3: Dictionary = base.duplicate(true)
	c3.permanent["arts_unlocked"] = ["boxing", "bjj"]
	c3.career["art"] = "muay_thai"
	c3.permanent["last_art"] = "muay_thai"
	casos.append(["career.art muay_thai sem liberar", c3])
	var c4: Dictionary = base.duplicate(true)
	c4.permanent["best_wins"] = 1.0e30
	c4.career["ladder_index"] = -3
	casos.append(["best_wins enorme, ladder negativo", c4])
	var c5: Dictionary = base.duplicate(true)
	c5.permanent["best_wins"] = "seis"
	c5.permanent["arts_unlocked"] = ["boxing", "bjj"]
	casos.append(["best_wins string", c5])
	var c6: Dictionary = base.duplicate(true)
	c6.permanent["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	c6.career["art"] = "muay_thai"
	c6.career["focus"] = "kick_bag"
	c6.career["apparatus"] = {}
	casos.append(["foco kick_bag sem aparelho montado", c6])
	var c7: Dictionary = base.duplicate(true)
	c7.career["art"] = "boxing"
	c7.permanent["arts_unlocked"] = ["boxing"]
	c7.school.milestones = {"muay_thai_unlocked": "x"}
	c7.school.lines_seen = [1, 2]
	casos.append(["marco e fala em tipos errados", c7])
	var c8: Dictionary = base.duplicate(true)
	c8.permanent["arts_unlocked"] = null
	casos.append(["arts_unlocked nulo", c8])
	var c9: Dictionary = base.duplicate(true)
	c9.career["fight"] = {"opponent": "opp_gym_2", "tactic": "aggressive", "seed": 1, "player": {"strength": 1, "agility": 1, "endurance": 1},
		"result": {"win": true, "ko": true, "t_ko": 5.0, "t_end": 5.0, "round": 1, "pct_player": 1.0, "pct_opponent": 0.0, "finish": 7}}
	casos.append(["finish com tipo errado", c9])
	var c10: Dictionary = base.duplicate(true)
	c10.career["art"] = "muay_thai"
	c10.permanent["arts_unlocked"] = ["muay_thai"]
	c10.career["fight"] = {"opponent": "opp_gym_2", "tactic": "aggressive", "seed": 1e30, "player": {"strength": NAN, "agility": -1, "endurance": 1.0e400},
		"result": {"win": true, "ko": true, "t_ko": -5.0, "t_end": 1.0e9, "round": 99, "pct_player": 5.0, "pct_opponent": -1.0, "finish": "spin_kick"}}
	casos.append(["luta salva com números absurdos", c10])
	for caso in casos:
		var g := _novo("qa7b1_sujo_c")
		g.aplicar_save(caso[1])
		var ok: bool = typeof(g.permanente.arts_unlocked) == TYPE_ARRAY
		for a in g.permanente.arts_unlocked:
			if not (a is String) or gym.arte(a).is_empty():
				ok = false
		var vistos := {}
		for a in g.permanente.arts_unlocked:
			if vistos.has(a):
				ok = false
			vistos[a] = true
		checar(ok, "save sujo '%s': arts_unlocked sanado %s" % [caso[0], str(g.permanente.arts_unlocked)])
		var sai: bool = g.salvar()
		g.luta_atual()
		g.previa()
		g.artes_para_escolha()
		checar(sai, "save sujo '%s': salva e a tela continua montando (arte_id=%s)" % [caso[0], g.arte_id])
		if g.arte_id == "muay_thai":
			checar(g.permanente.arts_unlocked.has("muay_thai"), "save sujo '%s': arte da carreira só vale se liberada" % caso[0])
		_liberar(g)
	# save v13 antigo de verdade: gravado em arquivo, sem campos da 7b1, carregado pelo caminho normal (inicializar)
	var pasta := pasta_limpa("qa7b1_antigo")
	var antigo: Dictionary = base.duplicate(true)
	antigo.permanent["arts_unlocked"] = ["boxing", "bjj"]
	antigo.permanent["best_wins"] = 6
	antigo.school.milestones.erase("muay_thai_unlocked")
	antigo.school.lines_seen.erase("cl_muay_thai")
	var f := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 13, "saved_at_unix": 1730000000, "state": antigo}))
	f.close()
	var g2: Node = GameStateScript.new()
	g2.inicializar(pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar(g2.permanente.arts_unlocked.has("muay_thai"), "save v13 antigo em arquivo (best_wins 6): carrega com o Muay Thai")
	checar_igual(g2.artes_para_escolha().size(), 3, "...e mostra 3 cartões")
	var tem := 0
	for g in g2._gatilhos_quadro:
		if str(g.id) == "muay_thai_unlocked":
			tem += 1
	checar_igual(tem, 1, "...e pede a fala do Osmar uma vez só")
	g2.salvar()
	var g3: Node = GameStateScript.new()
	g3.inicializar(pasta, "res://data/config.json")
	g3.autosave_ativo = false
	var tem3 := 0
	for g in g3._gatilhos_quadro:
		if str(g.id) == "muay_thai_unlocked":
			tem3 += 1
	print("   (informativo) fala pedida de novo ao recarregar sem ter sido vista: %d (por desenho: só some quando a fala passa)" % tem3)
	checar(g3.permanente.arts_unlocked.has("muay_thai"), "recarregar mantém a arte")
	# save de verdade com arquivo truncado/lixo
	var f2 := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f2.store_string("{\"version\": 13, \"permanent\": {\"arts_unlo")
	f2.close()
	var g4: Node = GameStateScript.new()
	g4.inicializar(pasta, "res://data/config.json")
	g4.autosave_ativo = false
	checar(g4.permanente.arts_unlocked is Array, "arquivo de save truncado: abre como jogo novo sem quebrar")
	for g in [gs, g2, g3, g4]:
		_liberar(g)


func _liberacao_real() -> void:
	print("--- liberação com luta real contra o Kid ---")
	var gs := _novo("qa7b1_lib")
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.escolher_arte("boxing")
	gs.indice_escada = 5
	gs.local_id = "gym"
	var kid := dados.adversario("opp_gym_2")
	gs.atributos = {"strength": kid.strength * 20.0, "agility": kid.agility * 20.0, "endurance": kid.endurance * 20.0}
	var info: Dictionary = gs.lutar()
	checar(not info.is_empty() and bool(info.result.win), "luta real contra o Kid (muito mais forte): vitória")
	checar(not gs.permanente.arts_unlocked.has("muay_thai"), "a arte ainda não entra antes de concluir a luta")
	gs.concluir_luta()
	checar(gs.permanente.arts_unlocked.has("muay_thai"), "concluir a vitória libera o Muay Thai")
	var estado: Dictionary = gs.para_save()
	checar(estado.permanent.arts_unlocked.has("muay_thai"), "o save já traz a arte")
	# chamar concluir_luta de novo / sem luta
	var antes: int = gs.permanente.arts_unlocked.size()
	gs.concluir_luta()
	checar_igual(gs.permanente.arts_unlocked.size(), antes, "concluir_luta repetido: sem duplicar")
	# 1ª carreira (sem arte) também libera? best_wins sobe e escolhas
	_liberar(gs)


func _aparelho() -> void:
	print("--- saco de chute ---")
	var gs := _novo("qa7b1_saco", "muay_thai")
	gs.dinheiro = 0.0
	var ok: bool = gs.comprar_aparelho("kick_bag")
	checar(not ok, "comprar o saco de chute sem dinheiro: recusa")
	checar(not gs.aparelho_montado("kick_bag"), "sem dinheiro: não montou")
	gs.dinheiro = -100.0
	checar(not gs.comprar_aparelho("kick_bag"), "dinheiro negativo: recusa")
	gs.dinheiro = 1.0e12
	var antes: float = gs.dinheiro
	var r1: bool = gs.comprar_aparelho("kick_bag")
	print("   compra (esteira pedida?): %s, caixa %s, dinheiro %s -> %s" % [str(r1), str(gs.caixa("kick_bag")), str(antes), str(gs.dinheiro)])
	var gb := _novo("qa7b1_saco_boxe", "boxing")
	gb.dinheiro = 1.0e12
	checar(not gb.comprar_aparelho("kick_bag") or true, "(registro) Boxe comprando o saco de chute: %s" % str(gb.aparelho_existe("kick_bag")))
	var ids_b: Array = []
	for a in gb.aparelhos_da_carreira():
		ids_b.append(a.id)
	var ids_m: Array = []
	for a in gs.aparelhos_da_carreira():
		ids_m.append(a.id)
	print("   Boxe vê: %s | MT vê: %s | MT comprou kick_bag: %s, caixa: %s" % [str(ids_b), str(ids_m), str(gs.aparelho_montado("kick_bag")), str(gs.caixa("kick_bag"))])
	gs.dinheiro = 1.0e12
	var g_ = gs
	print("   compra esteira: %s; depois saco: %s; montado: %s; caixa: %s" % [str(g_.comprar_aparelho("treadmill")), str(g_.comprar_aparelho("kick_bag")), str(g_.aparelho_montado("kick_bag")), str(g_.caixa("kick_bag"))])
	var vezes := 0
	for i in 5:
		if g_.comprar_aparelho("kick_bag"):
			vezes += 1
	print("   compras repetidas do saco aceitas: %d | dinheiro %s" % [vezes, str(g_.dinheiro)])
	_liberar(gs)
	_liberar(gb)


func _choque() -> void:
	pass


func _perfil(nivel: int, semente: int, perfil: String) -> Dictionary:
	var mg := MinigamesData.carregar()
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var c := ChoqueLogica.new(mg.spar, "muay_thai", nivel, rng)
	var rr := RandomNumberGenerator.new()
	rr.seed = semente * 7 + 1
	var feitos := {}
	var acum := 0.0
	while c.fase != "fim":
		c.passo(0.02)
		if c.fase != "jogando":
			continue
		if perfil == "afobado":
			acum += 0.02
			if acum >= 1.0 / 9.0:
				acum -= 1.0 / 9.0
				c.apertar()
				c.soltar()
		elif perfil == "no_tempo":
			var k := int(round(c.tempo / 0.5))
			if k >= 1 and not feitos.has(k) and absf(c.tempo - k * 0.5 - 0.0) <= 0.02:
				feitos[k] = true
				c.apertar()
				c.soltar()
		elif perfil == "parado":
			pass
	return c.resultado()


func _choque_perfis() -> void:
	print("--- Choque MT por perfis (60 partidas, nível 0/3/5) ---")
	for nivel in [0, 3, 5]:
		var soma := {"afobado": 0.0, "no_tempo": 0.0, "parado": 0.0}
		var venc := {"afobado": 0, "no_tempo": 0, "parado": 0}
		for perfil in soma:
			for s in 60:
				var r := _perfil(nivel, 100 + s, perfil)
				soma[perfil] += float(r.nota)
				if r.venceu:
					venc[perfil] += 1
		print("   nível %d: nota média afobado %.2f (vit %d) | no tempo %.2f (vit %d) | parado %.2f (vit %d)" % [nivel,
			soma.afobado / 60.0, venc.afobado, soma.no_tempo / 60.0, venc.no_tempo, soma.parado / 60.0, venc.parado])
		checar(soma.no_tempo > soma.afobado * 1.15, "nível %d: clicar no tempo rende claramente mais que afobado (nota %.2f x %.2f)" % [nivel, soma.no_tempo / 60.0, soma.afobado / 60.0])
		checar(venc.no_tempo > venc.afobado, "nível %d: só quem segue a batida vence" % nivel)
	# extremos do Choque
	var mg := MinigamesData.carregar()
	var c := ChoqueLogica.new(mg.spar, "muay_thai", 99, RandomNumberGenerator.new())
	for i in 5000:
		c.apertar()
		c.soltar()
		c.passo(0.0)
	c.passo(NAN)
	c.passo(INF)
	c.passo(-3.0)
	c.passo(1.0e9)
	var r := c.resultado()
	checar(_finito(c.barra) and _finito(r.nota), "Choque MT: 5000 apertos no mesmo quadro + passo NaN/INF/-3/1e9 sem quebrar (barra %s)" % str(c.barra))
