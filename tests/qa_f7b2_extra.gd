extends "res://tests/test_base.gd"
## QA 7b2: meta com lutas REAIS (gs.lutar + concluir_luta), escolha, save antigo/sujo/corrompido, reconhecimento por luta,
## valores extremos das 3 passivas novas. Tudo em user://test/. Rodar com APPDATA temporário.

const GameStateScript := preload("res://scripts/game_state.gd")
const TATICAS := ["aggressive", "defensive", "counter"]
const ARTES := ["boxing", "bjj", "muay_thai"]
const FIM_META := {"boxing": "knockout", "bjj": "submission", "muay_thai": "spin_kick"}
const FIM2 := {"boxing": "counter_ko", "bjj": "ground_stop", "muay_thai": "knee_ko"}

var dados: FightData
var gym: GymData


func rodar_testes() -> void:
	dados = FightData.carregar()
	gym = GymData.carregar()
	_meta_real()
	_escolha_e_nova_carreira()
	_save_sujo()
	_reconhecimento()
	_extremos()


func _novo(nome: String, arte: String = "", passiva: int = 1) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	if arte != "":
		gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		if passiva == 2:
			gs.permanente["passive_wins"][arte] = 3
			gs.permanente["passives_unlocked"].append(arte)
		gs.escolher_arte(arte, passiva)
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _finito(x: Variant) -> bool:
	return typeof(x) in [TYPE_FLOAT, TYPE_INT] and not is_nan(float(x)) and not is_inf(float(x))


# Faz uma luta REAL contra opp_gym_1 (escada 4, na academia) com atributos = k x os dele; devolve o resumo de concluir_luta ou {} se perdeu.
func _luta_real(gs: Node, k: float, tat: String) -> Dictionary:
	var o := dados.adversario("opp_gym_1")
	gs.local_id = "gym"
	gs.indice_escada = 4
	gs.luta = {}
	gs.tatica = tat
	gs.atributos = {"strength": o.strength * k, "agility": o.agility * k, "endurance": o.endurance * k}
	var info: Dictionary = gs.lutar()
	if info.is_empty():
		return {"erro": "lutar vazio"}
	if not bool(info.result.win):
		gs.aguardar_motivo()
		gs.luta = {}  # descarta (não encerra a carreira)
		return {}
	var fim := str(info.result.get("finish", ""))
	var r: Dictionary = gs.concluir_luta()
	r["_finish"] = fim
	return r


func _meta_real() -> void:
	print("--- meta com lutas reais ---")
	for arte in ARTES:
		var gs := _novo("qa7b2_meta_" + arte, arte, 1)
		var n_antes := 0
		var passou_por := []
		var contou_errado := 0
		var avisos := 0
		var liberou_em := -1
		var vitorias := 0
		var tentativas := 0
		var por_fim := {}
		while tentativas < 400 and not gs.passiva_liberada(arte):
			tentativas += 1
			var tat: String = TATICAS[tentativas % 3]
			var r := _luta_real(gs, 0.95 + 0.05 * float(tentativas % 5), tat)
			if r.is_empty():
				continue
			if r.has("erro"):
				checar(false, "luta real: " + str(r.erro))
				break
			vitorias += 1
			var f: String = r._finish
			por_fim[f] = int(por_fim.get(f, 0)) + 1
			var n_dep: int = gs.progresso_passiva(arte).n
			var esperado: bool = f == FIM_META[arte]
			if (n_dep - n_antes) != (1 if esperado else 0):
				contou_errado += 1
			if esperado:
				passou_por.append(n_dep)
				if bool(r.passive_goal.get("unlocked_now", false)):
					avisos += 1
					liberou_em = n_dep
			elif not r.passive_goal.is_empty():
				contou_errado += 1
			n_antes = n_dep
			# 2/3: ainda travada
			if n_dep == 2:
				checar(not gs.passiva_liberada(arte) and gs.passivas_do_cartao(arte)[1].locked, "%s: com 2/3 continua travada" % arte)
		print("   %s: %d vitórias reais em %d tentativas, fins %s, progressão %s" % [arte, vitorias, tentativas, str(por_fim), str(passou_por)])
		checar(gs.passiva_liberada(arte) and liberou_em == 3 and avisos == 1, "%s: a 3ª vitória pela passiva libera e o aviso sai 1 vez" % arte)
		checar_igual(contou_errado, 0, "%s: só vitória pelo fim da 1ª passiva conta (dano/pontos/outros não)" % arte)
		# outras artes não foram tocadas
		for outra in ARTES:
			if outra != arte:
				checar_igual(int(gs.permanente.passive_wins.get(outra, 0)), 0, "%s: o progresso de %s ficou em 0" % [arte, outra])
		# depois de liberada, mais vitórias não reavisam
		var reavisou := 0
		for i in 30:
			var r2 := _luta_real(gs, 1.0, "aggressive")
			if not r2.is_empty() and r2.get("passive2_unlocked", "") != "":
				reavisou += 1
		checar_igual(reavisou, 0, "%s: depois de liberada nenhum aviso novo em 30 lutas" % arte)
		# a fala do mentor: pedida 1 vez no gatilho
		var gat := 0
		for g in gs._gatilhos_quadro:
			if str(g.id) == "passive2_%s_unlocked" % arte:
				gat += 1
		print("   %s: gatilhos da fala do mentor na fila: %d" % [arte, gat])
		checar(gat <= 1, "%s: a fala do mentor está na fila no máximo 1 vez (%d)" % [arte, gat])
		# a carreira atual continua na 1ª passiva
		checar_igual(gs.passiva_carreira, 1, "%s: carreira atual na 1ª passiva" % arte)
		_liberar(gs)
	# vitórias reais com a 2ª passiva não contam
	var g2 := _novo("qa7b2_meta_2a", "boxing", 2)
	var fins := {}
	for i in 60:
		var r3 := _luta_real(g2, 1.0, "counter")
		if not r3.is_empty():
			fins[r3._finish] = int(fins.get(r3._finish, 0)) + 1
			checar(r3.passive_goal.is_empty(), "com a 2ª passiva nenhuma vitória conta (fim %s)" % r3._finish)
	print("   Contragolpista em luta real (Contra-ataque, 1,0x): fins %s" % str(fins))
	checar_igual(int(g2.permanente.passive_wins.get("boxing", 0)), 3, "passive_wins não mudou com a 2ª passiva")
	_liberar(g2)
	# sem arte (1ª carreira): nada conta
	var g0 := _novo("qa7b2_meta_semarte")
	for i in 20:
		_luta_real(g0, 1.0, "aggressive")
	checar(g0.permanente.get("passive_wins", {}).is_empty() or g0.permanente.passive_wins.values().all(func(v): return int(v) == 0), "sem arte: nada soma na meta")
	_liberar(g0)


func _escolha_e_nova_carreira() -> void:
	print("--- escolha da 2ª passiva e nova carreira ---")
	var gs := _novo("qa7b2_escolha")
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	for arte in ARTES:
		checar(not gs.escolher_arte(arte, 2), "%s: 2ª travada não pode ser escolhida" % arte)
	checar(gs.escolha_arte_pendente(), "a escolha segue pendente depois das recusas")
	gs.permanente["passive_wins"]["bjj"] = 3
	gs.permanente["passives_unlocked"].append("bjj")
	checar(not gs.escolher_arte("boxing", 2), "liberar só o bjj não libera o boxe")
	checar(gs.escolher_arte("bjj", 2), "bjj liberada: escolhe a 2ª")
	checar(not gs.escolher_arte("bjj", 1) and not gs.escolher_arte("boxing", 1), "vale a carreira toda: sem troca no meio")
	checar_igual(gs.passiva_carreira, 2, "continua na 2ª")
	# luta de verdade com a 2ª passiva: tipo certo no motor e na tela
	var info: Dictionary = {}
	gs.indice_escada = 3
	gs.local_id = "gym"
	var o := dados.adversario("opp_gym_1")
	gs.atributos = {"strength": o.strength, "agility": o.agility, "endurance": o.endurance}
	info = gs.lutar()
	checar(info.passive == "top_control" and int(info.art_passive) == 2, "luta real da carreira usa top_control (2ª)")
	gs.aguardar_motivo()
	gs.luta = {}
	# fim de carreira por aposentadoria -> nova carreira: volta a poder escolher, e o padrão é a última
	gs.indice_escada = 0
	gs.local_id = "garage"
	var fim: Dictionary = gs.aposentar()
	checar(not fim.is_empty(), "aposentou")
	checar(gs.nova_carreira(), "nova carreira")
	checar(gs.escolha_arte_pendente() and gs.arte_id == "" and gs.passiva_carreira == 1, "nova carreira: escolha pendente, sem arte, passiva 1 até escolher")
	var cartoes: Array = gs.artes_para_escolha()
	var bjj := {}
	for c in cartoes:
		if c.id == "bjj":
			bjj = c
	checar(not bjj.is_empty() and not bjj.passives[1].locked and int(bjj.passive_default) == 2, "o cartão do bjj vem destravado e marcado na 2ª (última escolha)")
	checar(gs.escolher_arte("bjj", 1) and gs.passiva_carreira == 1 and gs.motor.passiva.type == "submission", "nova carreira: dá para voltar à 1ª")
	checar(int(gs.permanente.passive_wins.bjj) == 3 and gs.passiva_liberada("bjj"), "a meta e a liberação são da linhagem (continuam)")
	# salvar e recarregar mantém tudo
	gs.salvar()
	_liberar(gs)


func _save_sujo() -> void:
	print("--- save antigo / sujo / corrompido (7b2) ---")
	var gs := _novo("qa7b2_sujo0", "bjj", 1)
	var base: Dictionary = gs.para_save()
	var casos: Array = []
	var mk := func(nome: String, f: Callable) -> void:
		var c: Dictionary = base.duplicate(true)
		f.call(c)
		casos.append([nome, c])
	mk.call("passive_wins array", func(c): c.permanent["passive_wins"] = [1, 2, 3])
	mk.call("passive_wins string", func(c): c.permanent["passive_wins"] = "tres")
	mk.call("passive_wins valores strings/null/NaN", func(c): c.permanent["passive_wins"] = {"boxing": "9", "bjj": null, "muay_thai": NAN})
	mk.call("passive_wins 1e30 e -1e30", func(c): c.permanent["passive_wins"] = {"boxing": 1.0e30, "bjj": -1.0e30})
	mk.call("passives_unlocked inteiro", func(c): c.permanent["passives_unlocked"] = 7)
	mk.call("passives_unlocked dict", func(c): c.permanent["passives_unlocked"] = {"boxing": true})
	mk.call("passives_unlocked lixo+duplicata", func(c): c.permanent["passives_unlocked"] = ["boxing", "boxing", 5, null, "sumo"])
	mk.call("last_passive em tipos errados", func(c): c.permanent["last_passive"] = {"boxing": "2", "bjj": [2], "x": 2, "muay_thai": 2.0})
	mk.call("last_passive string", func(c): c.permanent["last_passive"] = "boxing")
	mk.call("art_passive 2 sem meta", func(c): c.career["art_passive"] = 2)
	mk.call("art_passive string '2' sem meta", func(c): c.career["art_passive"] = "2")
	mk.call("art_passive 99", func(c): c.career["art_passive"] = 99)
	mk.call("art_passive -1", func(c): c.career["art_passive"] = -1)
	mk.call("art_passive null", func(c): c.career["art_passive"] = null)
	mk.call("art_passive 2 sem arte", func(c): c.career["art_passive"] = 2; c.career["art"] = "")
	mk.call("art_passive 2.0 com meta por passive_wins", func(c): c.career["art_passive"] = 2.0; c.permanent["passive_wins"] = {"bjj": 3}; c.permanent["passives_unlocked"] = [])
	mk.call("finish ground_stop com a 1ª passiva", func(c): c.career["fight"] = {"opponent": "opp_warmup", "tactic": "aggressive", "seed": 3, "player": {"strength": 1, "agility": 1, "endurance": 1}, "result": {"win": true, "ko": true, "t_ko": 8.0, "t_end": 8.0, "round": 1, "pct_player": 0.5, "pct_opponent": 0.0, "finish": "ground_stop"}})
	mk.call("finish knee_ko com Boxe 2ª", func(c): c.career["art"] = "boxing"; c.career["art_passive"] = 2; c.permanent["passives_unlocked"] = ["boxing"]; c.career["fight"] = {"opponent": "opp_warmup", "tactic": "aggressive", "seed": 3, "player": {"strength": 1, "agility": 1, "endurance": 1}, "result": {"win": true, "ko": true, "t_ko": 8.0, "t_end": 8.0, "round": 1, "pct_player": 0.5, "pct_opponent": 0.0, "finish": "knee_ko"}})
	for caso in casos:
		var g := _novo("qa7b2_sujo_c")
		g.aplicar_save(caso[1])
		var p: Dictionary = g.permanente
		var ok := p.passive_wins is Dictionary and p.passives_unlocked is Array and p.last_passive is Dictionary
		for k in p.passive_wins:
			if not (typeof(p.passive_wins[k]) == TYPE_INT and int(p.passive_wins[k]) >= 0 and gym.arte(k).passive_2.size() > 0):
				ok = false
		var vistos := {}
		for a in p.passives_unlocked:
			if not (a is String) or gym.arte(a).is_empty() or vistos.has(a):
				ok = false
			vistos[a] = true
		# regra de ouro: a 2ª passiva ativa só com a meta liberada
		if g.passiva_carreira == 2:
			ok = ok and g.passiva_liberada(g.arte_id) and g.arte_id != ""
		checar(ok, "save sujo '%s': campos sanados (wins %s, lib %s, art_passive %d)" % [caso[0], str(p.passive_wins), str(p.passives_unlocked), g.passiva_carreira])
		var sai: bool = g.salvar()
		g.luta_atual()
		g.previa()
		g.artes_para_escolha()
		g.progresso_passiva("boxing")
		checar(sai, "save sujo '%s': salva e as telas montam" % caso[0])
		_liberar(g)
	# arquivo real: save v13 antigo (sem nenhum campo 7b2) e depois truncado
	var pasta := pasta_limpa("qa7b2_arquivo")
	var antigo: Dictionary = base.duplicate(true)
	antigo.permanent.erase("passive_wins")
	antigo.permanent.erase("passives_unlocked")
	antigo.permanent.erase("last_passive")
	antigo.career.erase("art_passive")
	antigo.permanent["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	var f := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 13, "saved_at_unix": 1730000000, "state": antigo}))
	f.close()
	var g2: Node = GameStateScript.new()
	g2.inicializar(pasta, "res://data/config.json")
	g2.autosave_ativo = false
	var tudo_zero := true
	for a in ARTES:
		var pr: Dictionary = g2.progresso_passiva(a)
		if pr.n != 0 or pr.liberada or pr.m != 3:
			tudo_zero = false
	checar(tudo_zero and g2.passiva_carreira == 1, "save v13 antigo em arquivo: 0/3 nas 3 artes, travadas, passiva 1")
	g2.salvar()
	var g3: Node = GameStateScript.new()
	g3.inicializar(pasta, "res://data/config.json")
	g3.autosave_ativo = false
	checar(g3.permanente.has("passive_wins") and g3.permanente.has("passives_unlocked"), "depois de salvar e recarregar os campos novos existem")
	var corrompido: String = JSON.stringify({"version": 13, "saved_at_unix": 1730000000, "state": base})
	var f2 := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f2.store_string(corrompido.substr(0, corrompido.length() / 2))
	f2.close()
	var g4: Node = GameStateScript.new()
	g4.inicializar(pasta, "res://data/config.json")
	g4.autosave_ativo = false
	checar(g4.permanente.passive_wins is Dictionary and g4.passiva_carreira == 1, "save truncado ao meio: abre como jogo novo sem erro")
	for g in [gs, g2, g3, g4]:
		_liberar(g)


func _reconhecimento() -> void:
	print("--- reconhecimento: sinais da 2ª passiva por luta (vitórias, adversário Tonhão/Kid, 1,0x) ---")
	for arte in ARTES:
		for primeira in [false, true]:
			var m := Luta.new(dados)
			m.passiva = gym.arte(arte).get("passive" if primeira else "passive_2").duplicate(true)
			for oid in ["opp_tank", "opp_gym_2"]:
				var o := dados.adversario(oid)
				var adv := [o.strength, o.agility, o.endurance]
				for tat in TATICAS:
					var jog := [adv[0] * 1.05, adv[1] * 1.05, adv[2] * 1.05]
					var vit := 0
					var fim_p := 0
					var sinal := 0
					var tipo := ""
					for s in 600:
						var r: Dictionary = m.lutar(jog, adv, tat, 910000 + s, true)
						if not r.win:
							continue
						vit += 1
						var viu := false
						if r.get("finish", "") == FIM2[arte] or (primeira and r.get("finish", "") == FIM_META[arte]):
							fim_p += 1
						for e in r.events:
							if arte == "boxing" and e.has("charge") and int(e.charge) >= 1 and int(e.who) == 0:
								viu = true
							elif arte == "bjj" and e.has("ground") and bool(e.ground):
								viu = true
							elif arte == "muay_thai" and e.has("clinch") and bool(e.clinch):
								viu = true
							elif arte == "muay_thai" and int(e.get("marks", 0)) >= 1:
								viu = true
						if viu:
							sinal += 1
					print("   %-9s %s %-8s %-10s: %3d vitórias, sinal do jeito (carga/chão/clinch ou marca) em %3d%%, fim pela passiva %3d%%" % [arte, "1ª" if primeira else "2ª", oid, tat, vit, 100 * sinal / maxi(vit, 1), 100 * fim_p / maxi(vit, 1)])


func _extremos() -> void:
	print("--- extremos nas 3 passivas novas ---")
	var casos := {
		"zeros": [[0.0, 0.0, 0.0], [10.0, 10.0, 10.0]],
		"adv zero": [[10.0, 10.0, 10.0], [0.0, 0.0, 0.0]],
		"ambos zero": [[0.0, 0.0, 0.0], [0.0, 0.0, 0.0]],
		"enormes": [[1.0e300, 1.0e300, 1.0e300], [1.0, 1.0, 1.0]],
		"enorme x enorme": [[1.0e300, 1.0e300, 1.0e300], [1.0e300, 1.0e300, 1.0e300]],
		"minúsculos": [[1.0e-300, 1.0e-300, 1.0e-300], [1.0e-300, 1.0e-300, 1.0e-300]],
		"negativos": [[-5.0, -5.0, -5.0], [10.0, 10.0, 10.0]],
		"só força": [[1000.0, 0.0, 0.0], [10.0, 10.0, 10.0]],
		"só agilidade": [[0.0, 1000.0, 0.0], [10.0, 10.0, 10.0]],
		"só resistência": [[0.0, 0.0, 1000.0], [10.0, 10.0, 10.0]],
		"adv só resistência": [[10.0, 10.0, 10.0], [0.0, 0.0, 1.0e9]],
		"NaN": [[NAN, 1.0, 1.0], [1.0, 1.0, 1.0]],
		"INF": [[INF, INF, INF], [1.0, 1.0, 1.0]],
	}
	for arte in ARTES:
		for extra in [0.0, 0.5, 1.0e9, -3.0]:
			var m := Luta.new(dados)
			m.passiva = gym.arte(arte).passive_2.duplicate(true)
			m.extra_passiva = extra
			for nome in casos:
				for tat in TATICAS:
					var jog: Array = casos[nome][0]
					var adv: Array = casos[nome][1]
					var p: float = m.chance(jog, adv, tat)
					var r: Dictionary = m.lutar(jog, adv, tat, 5, true)
					var est: Dictionary = m.estado_passiva(jog, adv, tat)
					var det: Dictionary = m.chance_detalhada(jog, adv, tat)
					var ok := true
					if nome != "NaN" and nome != "INF":
						ok = _finito(p) and p >= 0.0 and p <= 1.0 and _finito(r.t_end) and r.t_end <= 60.0
						for k in est:
							if typeof(est[k]) == TYPE_FLOAT and not _finito(est[k]):
								ok = false
								print("   NaN/inf em estado_passiva.%s (%s, %s, %s, extra %s)" % [k, arte, nome, tat, str(extra)])
						for k in ["share", "at", "charge_med"]:
							if det.has(k) and not _finito(det[k]):
								ok = false
						for e in r.events:
							if int(e.get("charge", 0)) < 0 or int(e.get("charge", 0)) > 3 or not _finito(e.damage):
								ok = false
					checar(ok, "extremo %s '%s' %s extra %s: chance %s t_end %s" % [arte, nome, tat, str(extra), str(p), str(r.t_end)])
