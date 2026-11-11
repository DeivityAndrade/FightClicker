extends "res://tests/test_base.gd"
## QA Fase 5 (rodada 2, depois dos PRs do Matheus): rounds, golpes visuais deterministicos, evento dourado/FRENESI
## com janela de arte/luta/fim, Boxe x Metronomo/assistido x FRENESI, Jiu-jitsu, mudanca automatica x MUDAR,
## nova carreira, reserva da LOJA, save corrompido com campos novos. Saves so em user://test/.

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	return gs


func _belt(nome: String, dinheiro: float = 1000.0) -> Node:
	var gs = _novo(nome)
	gs.indice_escada = 4
	gs.cinturao = true
	gs.fama = 200
	gs.dinheiro = dinheiro
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _passar(gs: Node, s: float) -> void:
	for i in int(round(s * 10.0)):
		gs.tick(0.1)


func rodar_testes() -> void:
	_rounds()
	_golpes_deterministicos()
	_dourado()
	_boxe_frenesi()
	_mudanca_e_reserva()
	_nova_carreira()
	_save_estranho()


func _rounds() -> void:
	var gs = _novo("r1")
	var rl: float = gs.lutas.combate.round_length
	print("INFO round_length=%s limite=%s" % [rl, gs.lutas.combate.time_limit])
	var ruins := 0
	var kos := 0
	var pontos := 0
	var max_tko := 0.0
	var rounds := {1: 0, 2: 0, 3: 0}
	for idx in 6:
		var opp: Dictionary = gs.lutas.adversarios[idx]
		for f in [0.3, 0.7, 1.0, 1.5]:
			gs.atributos = {"strength": opp.strength * f, "agility": opp.agility * f, "endurance": opp.endurance * f}
			for k in 120:
				var r: Dictionary = gs.motor.lutar(gs._atributos_array(), gs._array_adversario(opp), ["aggressive", "defensive", "counter"][k % 3], 500 + k, true)
				if bool(r.ko):
					kos += 1
					max_tko = maxf(max_tko, float(r.t_ko))
					if int(r.round) < 1 or int(r.round) > 3:
						ruins += 1
					else:
						rounds[int(r.round)] += 1
				else:
					pontos += 1
				for e in r.events:
					var rn := int(floor(float(e.t) / rl)) + 1
					if rn < 1 or rn > 3:
						ruins += 1
	print("INFO kos=%d pontos=%d max_t_ko=%.4f por round=%s" % [kos, pontos, max_tko, rounds])
	checar_igual(ruins, 0, "round de K.O./evento sempre entre 1 e 3 (%d fora)" % ruins)
	checar(max_tko < 16.0, "t_ko < 16 s")
	_liberar(gs)


func _golpes_deterministicos() -> void:
	var gs = _belt("g1")
	gs.mudar()
	gs.escolher_arte("boxing")
	gs.atributos = {"strength": 3.0e5, "agility": 2.0e5, "endurance": 2.0e6}
	gs.rng.seed = 11
	var info: Dictionary = gs.lutar()
	checar(not info.is_empty(), "lutou na academia")
	var a: Dictionary = gs.luta_atual()
	var b: Dictionary = gs.luta_atual()
	var mv_a: Array = a.events.map(func(e): return e.move)
	var mv_b: Array = b.events.map(func(e): return e.move)
	checar_igual(mv_a, mv_b, "golpes iguais em duas chamadas de luta_atual")
	var ok := true
	for e in a.events:
		if str(e.move) != "" and not gs.golpes.golpes.has(str(e.move)):
			ok = false
	checar(ok, "todo golpe do evento existe no catalogo")
	# recarrega do save no meio da luta: mesmos golpes e mesmo resultado
	var g2: Node = GameStateScript.new()
	g2.inicializar(gs.store.pasta, "res://data/config.json")
	g2.autosave_ativo = false
	var c: Dictionary = g2.luta_atual()
	var mv_c: Array = c.events.map(func(e): return e.move)
	checar_igual([mv_c, bool(c.result.win)], [mv_a, bool(a.result.win)], "luta recarregada do save = mesma luta (golpes e resultado)")
	_liberar(g2)
	# golpe nao altera o resultado: mesma luta com outra semente de golpes nao existe como API; confere sem 'move' no motor
	var puro: Dictionary = gs.motor.lutar(gs._atributos_array(), gs._array_adversario(gs.lutas.adversarios[4]), a.tactic, int(a.seed), false)
	checar_igual(bool(puro.win), bool(a.result.win), "motor puro = resultado da luta animada")
	_liberar(gs)


func _dourado() -> void:
	# 1. com escolha de arte pendente o relogio espera e pegar recusa
	var gs = _belt("d1")
	gs.mudar()
	checar(gs.escolha_arte_pendente(), "escolha pendente")
	_passar(gs, 200.0)
	checar(gs.evento_dourado_restante <= 0.0, "luva dourada nao aparece com escolha de arte pendente")
	checar(not gs.pegar_evento_dourado(), "nao pega com escolha pendente")
	gs.escolher_arte("bjj")
	_passar(gs, 100.0)
	# deve ter aparecido ao menos uma vez ate aqui (ou esta aparecida)
	var viu: bool = gs.evento_dourado_restante > 0.0
	var t := 0.0
	while gs.evento_dourado_restante <= 0.0 and t < 100.0:
		gs.tick(0.1)
		t += 0.1
	checar(gs.evento_dourado_restante > 0.0, "luva aparece depois da escolha")
	# 2. luva na tela e a luta comeca: nao pega durante a luta
	gs.atributos = {"strength": 3.0e5, "agility": 2.0e5, "endurance": 2.0e6}
	var l: Dictionary = gs.lutar()
	checar(not l.is_empty(), "lutou com luva dourada na sala")
	checar(not gs.pegar_evento_dourado(), "nao pega durante a luta")
	var antes: float = gs.evento_dourado_restante
	_passar(gs, 3.0)
	print("INFO luva restante antes=%.1f depois de 3s de luta=%.1f (expira durante a luta)" % [antes, gs.evento_dourado_restante])
	# 3. FRENESI ligado e a luta termina / aposenta / nova carreira
	var g3 = _novo("d3")
	var t3 := 0.0
	while g3.evento_dourado_restante <= 0.0 and t3 < 100.0:
		g3.tick(0.1)
		t3 += 0.1
	checar(g3.pegar_evento_dourado(), "pega")
	checar(not g3.pegar_evento_dourado(), "pegar 2x seguidas recusa")
	var base: float = g3.por_clique()
	var r: Dictionary = g3.clicar()
	checar_igual(snappedf(float(r.ganho), 0.0001), snappedf(base * g3.FRENESI_MULT, 0.0001), "clique x FRENESI_MULT com FRENESI")
	g3.aposentar()
	print("INFO FRENESI continua na tela de fim: ", g3.frenesi_restante)
	g3.nova_carreira()
	print("INFO apos NOVA CARREIRA: frenesi=%.1f evento=%.1f" % [g3.frenesi_restante, g3.evento_dourado_restante])
	checar(g3.frenesi_restante >= 0.0 and is_finite(g3.frenesi_restante), "frenesi finito apos nova carreira")
	# 4. nao e salvo
	var g4: Node = GameStateScript.new()
	g4.inicializar(g3.store.pasta, "res://data/config.json")
	g4.autosave_ativo = false
	checar_igual([g4.frenesi_restante, g4.evento_dourado_restante], [0.0, 0.0], "frenesi e luva nao vao para o save")
	_liberar(g4)
	# 5. delta absurdo
	var g5 = _novo("d5")
	g5.tick(1.0e9)
	checar(is_finite(g5.treino) and is_finite(g5.tempo_jogo), "tick de 1e9 s finito")
	_liberar(g5)
	_liberar(g3)
	_liberar(gs)


func _boxe_frenesi() -> void:
	var gs = _belt("b1")
	gs.mudar()
	gs.escolher_arte("boxing")
	var pc: float = gs.por_clique()
	var pa: float = gs.por_auto_soco()
	print("INFO boxe por_clique=%s por_auto=%s mult_local=%s" % [pc, pa, gs.mult_local()])
	checar(pc > pa, "Boxe: clique maior que auto-soco")
	# Metronomo nivel maximo e piso do intervalo
	gs.treino = 1.0e18
	gs.dinheiro = 1.0e12
	for i in 12:
		gs.comprar_metronomo()
	var gb: Node = _belt("b2")
	gb.mudar()
	gb.escolher_arte("bjj")
	checar_igual(snappedf(gb.por_auto_soco(), 0.0001), snappedf(pa, 0.0001), "auto-soco igual com Boxe e Jiu-jitsu")
	checar(gb.por_clique() < pc, "Jiu-jitsu nao da bonus de clique")
	# Jiu-jitsu teto
	gb.arte_segundos = 1.0e12
	var teto: float = gb.bonus_arte_equipe()
	gb.arte_segundos = 1.0e300
	checar_igual(gb.bonus_arte_equipe(), teto, "Jiu-jitsu: teto estavel (%s)" % teto)
	checar(gb.arte_no_teto(), "arte_no_teto")
	gb.tick(0.1)
	checar(is_finite(gb.treino) and is_finite(gb.producao_total()), "producao finita no teto")
	_liberar(gb)
	_liberar(gs)


func _mudanca_e_reserva() -> void:
	# mudanca automatica: simula o fim da vitoria do cinturao (o prêmio paga)
	var gs = _novo("m1")
	gs.indice_escada = 3
	gs.dinheiro = 0.0
	gs.fama = 100
	gs.atributos = {"strength": 5.0e6, "agility": 5.0e6, "endurance": 5.0e7}
	var l: Dictionary = gs.lutar()
	checar(not l.is_empty(), "lutou com o Muralha")
	gs.aguardar_motivo()
	var d0: float = gs.dinheiro
	print("INFO dinheiro depois de iniciar a luta do Muralha (antes do fim animado): %s idx=%s cinturao=%s" % [d0, gs.indice_escada, gs.cinturao])
	# a luta foi decidida: quando o premio entra? (chama o fim, se existir)
	for n in ["concluir_luta", "terminar_luta", "finalizar_luta", "fechar_luta"]:
		if gs.has_method(n):
			print("INFO metodo de fim: ", n)
			gs.call(n)
			break
	print("INFO apos fim: dinheiro=%s idx=%s cinturao=%s local=%s estado_mudanca=%s pode_mudar=%s" % [gs.dinheiro, gs.indice_escada, gs.cinturao, gs.local_id, gs.estado_mudanca(), gs.pode_mudar()])
	if gs.cinturao:
		var antes: float = gs.dinheiro
		checar(gs.mudar(), "mudar apos cinturao")
		checar_igual(gs.dinheiro, antes - 1000.0, "cobrou 1000 uma vez")
		checar(not gs.mudar(), "mudar de novo recusa")
		checar_igual(gs.dinheiro, antes - 1000.0, "nao cobrou de novo")
	_liberar(gs)
	# reserva: a LOJA com cinturao e $1500 (premio entrou)
	var g2 = _belt("m2", 1500.0)
	check_loja(g2)
	_liberar(g2)


func check_loja(g: Node) -> void:
	checar_igual(g.reserva_mudanca(), 1000.0, "reserva 1000 com cinturao")
	checar_igual(g.loja_estado(500.0), "ok", "gasta 500 de 1500 ok")
	checar_igual(g.loja_estado(501.0), "reserve", "501 de 1500 deixaria menos que a reserva")
	checar_igual(g.loja_estado(2000.0), "money", "2000 sem dinheiro")
	g.mudar()
	checar_igual(g.reserva_mudanca(), 0.0, "sem reserva depois de mudar")


func _nova_carreira() -> void:
	var gs = _belt("n1")
	gs.mudar()
	gs.escolher_arte("boxing")
	gs.treino = 1.0e9
	gs.comprar_aparelho("treadmill")
	gs.comprar_aparelho("speed_bag")
	gs.definir_foco("speed_bag")
	checar_igual(gs.foco, "speed_bag", "foco na pera")
	gs.aposentar()
	gs.nova_carreira()
	checar_igual([gs.local_id, gs.arte_id, gs.escolha_arte_pendente()], ["garage", "", true], "nova carreira: garagem, sem arte, pendente")
	checar(gs.foco == "punching_bag", "foco volta ao saco (%s)" % gs.foco)
	checar(not gs.aparelho_existe("speed_bag") or gs.estado_aparelho("speed_bag") != "owned", "pera nao veio junto")
	checar_igual(gs.estado_mudanca(), "locked", "MUDAR trancado de novo")
	checar_igual(gs.reserva_mudanca(), 0.0, "sem reserva na nova carreira")
	# outra arte: equipamento da outra nao existe
	gs.escolher_arte("bjj")
	checar_igual(gs.estado_aparelho("speed_bag"), "absent", "pera ausente com Jiu-jitsu")
	checar(not gs.comprar_aparelho("speed_bag"), "compra da pera recusada com Jiu-jitsu")
	checar(not gs.definir_foco("speed_bag"), "foco na pera recusado com Jiu-jitsu")
	_liberar(gs)


func _save_estranho() -> void:
	for caso in range(6):
		var nome := "s%d" % caso
		var pasta := pasta_limpa(nome)
		var gs = _novo(nome)
		gs.indice_escada = 4
		gs.cinturao = true
		gs.dinheiro = 1000.0
		gs.mudar()
		gs.escolher_arte("boxing")
		gs.salvar()
		_liberar(gs)
		var f = FileAccess.open(pasta + "save.json", FileAccess.READ)
		var txt: String = f.get_as_text()
		f.close()
		var j: Dictionary = JSON.parse_string(txt)
		var st: Dictionary = j["state"]
		match caso:
			0:
				st["career"]["location"] = 5
			1:
				st["career"]["art"] = ["boxing"]
			2:
				st["career"]["art_seconds"] = "x"
			3:
				st["career"]["gear"] = null
			4:
				st["permanent"]["arts_unlocked"] = "boxing"
			5:
				st["career"]["location"] = "gym"
				st["career"]["art"] = "muay_thai"
		var w = FileAccess.open(pasta + "save.json", FileAccess.WRITE)
		w.store_string(JSON.stringify(j))
		w.close()
		var DirA = DirAccess.open(pasta)
		if DirA != null and DirA.file_exists("save.json.bak"):
			DirA.remove("save.json.bak")
		var g2: Node = GameStateScript.new()
		g2.inicializar(pasta, "res://data/config.json")
		g2.autosave_ativo = false
		var ok: bool = is_finite(g2.treino) and (g2.local_id == "garage" or g2.local_id == "gym") and (g2.arte_id in ["", "boxing", "bjj"])
		checar(ok, "save alterado caso %d carrega sano (local=%s arte=%s)" % [caso, g2.local_id, g2.arte_id])
		g2.tick(0.1)
		_liberar(g2)
