extends "res://tests/test_base.gd"
## QA Fase 5: risco honesto com traco de arte (previa x resultado real) e dica de aposentar.
const GameStateScript := preload("res://scripts/game_state.gd")


func _gs(nome: String, arte: String, idx: int) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.indice_escada = idx
	gs.cinturao = true
	gs.fama = 200
	gs.dinheiro = 1000.0
	gs.mudar()
	if arte != "":
		gs.escolher_arte(arte)
	return gs


func rodar_testes() -> void:
	for idx in [4, 5]:
		for arte in ["", "boxing", "bjj"]:
			var gs = _gs("e2_%d_%s" % [idx, arte], arte, idx)
			var opp: Dictionary = gs.proximo_adversario()
			var f = 1.0
			gs.atributos = {"strength": opp.strength * 0.95 * f, "agility": opp.agility * 0.95 * f, "endurance": opp.endurance * 0.95 * f}
			for tat in ["aggressive", "defensive", "counter"]:
				gs.definir_tatica(tat)
				var p: float = gs.risco_tatica(tat).chance
				var vit := 0
				var n := 600
				for k in n:
					var r: Dictionary = gs.motor.lutar(gs._atributos_array(), gs._array_adversario(opp), tat, 1000 + k, false)
					if bool(r.win):
						vit += 1
				var emp := float(vit) / n
				print("INFO idx=%d arte=%-6s tatica=%-10s chance_previa=%.3f empirico=%.3f dif=%.3f" % [idx, arte, tat, p, emp, p - emp])
				checar(absf(p - emp) < 0.07, "previa honesta idx=%d arte=%s %s" % [idx, arte, tat])
			# lutar de verdade pelo GameState: a luta usa o mesmo traco?
			if arte == "":
				gs.aguardar_motivo()
				gs.free()
				continue
			gs.definir_tatica("defensive")
			gs.rng.seed = 5
			var l: Dictionary = gs.lutar()
			var peq: Dictionary = gs.motor.lutar(gs._atributos_array(), gs._array_adversario(opp), "defensive", int(l.seed), false)
			checar_igual(bool(l.result.win), bool(peq.win), "GameState.lutar usa o mesmo motor/traco (idx=%d %s)" % [idx, arte])
			gs.aguardar_motivo()
			gs.free()
	# dica de aposentar com risco_hud ativo e a 1 s de diferenca
	var g8 = _gs("e2_dica", "boxing", 4)
	g8.risco_hud_ativo = true
	g8.atributos = {"strength": 100.0, "agility": 100.0, "endurance": 100.0}
	var t := 0.0
	var visto := -1.0
	for i in 4000:
		g8.tick(0.1)
		t += 0.1
		if visto < 0.0 and g8.dica_aposentar().show:
			visto = t
	print("INFO dica visivel em t=%.1f" % visto)
	checar(visto >= 299.0 and visto <= 302.0, "dica aos 300 s (%.1f)" % visto)
	# aposentar zera dica; nova carreira zera
	g8.aposentar()
	checar(not g8.dica_aposentar().show, "dica some com tela de fim")
	g8.nova_carreira()
	checar(not g8.dica_aposentar().show, "dica zerada na nova carreira")
	# tela de fim na academia depois de aposentar sem lutar: tip_extra
	var g9 = _gs("e2_tip", "bjj", 4)
	var f = g9.aposentar()
	var tf: Dictionary = g9.textos_fim(f)
	print("INFO tip_extra (moveu e aposentou sem lutar): '%s'" % tf.get("tip_extra", ""))
	var tips: Array = []
	for s in 30:
		g9.fim.seed = s
		tips.append(g9.textos_fim(g9.fim).get("tip_extra", ""))
	print("INFO variantes: ", tips.slice(0, 12))
	g8.free()
	g9.free()
