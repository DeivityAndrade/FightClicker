extends "res://tests/test_base.gd"
## QA 7b1: "N EM 10 VITÓRIAS POR CHUTE RODADO" da prévia x luta real (1000 lutas por estado e tática).
const GS := preload("res://scripts/game_state.gd")

func rodar_testes() -> void:
	var gs: Node = GS.new()
	gs.inicializar(pasta_limpa("qa7b1_share"), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	gs.escolher_arte("muay_thai")
	gs.local_id = "gym"
	var estados: Array = []
	estados.append([5, [4.83e6, 9.66e6, 2.17e7], "captura defensive (Kid)"])
	for f in [[0.7, 0.9, 1.0], [0.85, 1.0, 1.0], [1.0, 1.0, 1.0], [1.1, 1.0, 1.0]]:
		estados.append([4, f, "Tonhão fator"])
	for e in estados:
		gs.indice_escada = e[0]
		var opp: Dictionary = gs.proximo_adversario()
		var a: Array = e[1]
		var jog: Array
		if a[0] > 1000.0:
			jog = a
		else:
			var t: float = (opp.strength + opp.agility + opp.endurance) * a[0]
			jog = [t * 0.4, t * 0.4, t * 0.2]
			if e[2] == "Tonhão fator":
				jog = [t * 0.4 * a[1], t * 0.4, t * 0.2]
		gs.atributos = {"strength": jog[0], "agility": jog[1], "endurance": jog[2]}
		var adv := [opp.strength, opp.agility, opp.endurance]
		var tot_j: float = jog[0] + jog[1] + jog[2]
		for tat in ["aggressive", "defensive", "counter"]:
			gs.tatica = tat
			var pv: Dictionary = gs.previa()
			var n_prev := int(pv.passive_tactics[tat].share_n)
			var w := 0
			var sp := 0
			for i in 1000:
				var r: Dictionary = gs.motor.lutar(jog, adv, tat, 700000 + i)
				if r.win:
					w += 1
					if r.finish == "spin_kick":
						sp += 1
			var n_real := int(round(10.0 * sp / maxf(w, 1)))
			var dado: String = "chance prévia %.2f real %.2f" % [float(pv.risks[tat].chance), w / 1000.0]
			print("%-26s %s total %.0f %-10s prévia %d EM 10 | real %d EM 10 (%d de %d) | %s" % [e[2], opp.id, tot_j, tat, n_prev, n_real, sp, w, dado])
			checar(absi(n_prev - n_real) <= 1, "%s %s %s: prévia %d x real %d" % [e[2], opp.id, tat, n_prev, n_real])
	gs.aguardar_motivo()
	gs.free()
