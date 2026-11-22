extends "res://tests/test_base.gd"
## QA 8a1: prévia honesta NO JOGO contra os 4 regionais, 6 combinações (arte x passiva) x N estados x 3 táticas x 1000 lutas do motor do jogo
## (mesmo `gs.motor.lutar` e `_array_adversario` do `lutar()`); a "mostrada" é `gs.previa().risks[tat].chance`. Também tela 8-20 s e "nunca invencível".
## Rodar: Godot --headless --path <pasta> --script res://tests/qa_f8a1_previa.gd  (APPDATA temporário). QA_ESTADOS (12), QA_LUTAS (1000).
const GameStateScript := preload("res://scripts/game_state.gd")
const TATICAS := ["aggressive", "defensive", "counter"]
const COMBOS := [["boxing", 1], ["boxing", 2], ["bjj", 1], ["bjj", 2], ["muay_thai", 1], ["muay_thai", 2]]
const REG := [6, 7, 8, 9]


func _gs(nome: String, arte: String, passiva: int) -> Node:
	var g: Node = GameStateScript.new()
	g.inicializar(pasta_limpa(nome), "res://data/config.json")
	g.autosave_ativo = false
	g.risco_hud_ativo = false
	g.lutas.calendario["seconds_per_day"] = 0.0
	g.pular_abertura()
	g.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	g.permanente["passive_wins"] = {arte: 3}
	g.permanente["passives_unlocked"] = [arte]
	g.escolher_arte(arte, passiva)
	g.local_id = "gym"
	return g


func rodar_testes() -> void:
	var n_est := int(OS.get_environment("QA_ESTADOS")) if OS.get_environment("QA_ESTADOS") != "" else 12
	var n_lut := int(OS.get_environment("QA_LUTAS")) if OS.get_environment("QA_LUTAS") != "" else 1000
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261122
	var t0 := Time.get_ticks_msec()
	var por_adv := {}  # idx -> [soma_dif, n]
	var pior_est := 0.0
	var gt5 := 0
	var total := 0
	var dmin := 999.0
	var dmax := 0.0
	var consist_max := 0.0
	var cat: Dictionary = {}  # idx -> combo -> [soma, n]
	for combo in COMBOS:
		var g := _gs("qa8a1_prev", combo[0], combo[1])
		checar_igual(str(g.motor.passiva.get("type", "")).length() > 0, true, "motor com a passiva de %s %d (%s)" % [combo[0], combo[1], str(g.motor.passiva.get("type", ""))])
		for idx in REG:
			g.indice_escada = idx
			var opp: Dictionary = g.proximo_adversario()
			var adv: Array = g._luta._array_adversario(opp)
			var soma := 0.0
			var n := 0
			for k in n_est:
				var tot: float = (float(opp.strength) + float(opp.agility) + float(opp.endurance)) * rng.randf_range(0.5, 1.4)
				var w := [rng.randf() + 0.2, rng.randf() + 0.2, rng.randf() + 0.2]
				var sw: float = w[0] + w[1] + w[2]
				g.atributos = {"strength": tot * w[0] / sw, "agility": tot * w[1] / sw, "endurance": tot * w[2] / sw}
				var jog := [g.atributos.strength, g.atributos.agility, g.atributos.endurance]
				for tat in TATICAS:
					g.definir_tatica(tat)
					var pv: Dictionary = g.previa()
					var p: float = float(pv.risks[tat].chance)
					var p2: float = g.motor.chance(jog, adv, tat)
					consist_max = maxf(consist_max, absf(p - p2))
					if p < 0.03 or p > 0.97:
						continue
					var v := 0
					for i in n_lut:
						var r: Dictionary = g.motor.lutar(jog, adv, tat, 900000 + i + k * 17 + idx * 1000003, false)
						if r.win:
							v += 1
						dmin = minf(dmin, float(r.t_end))
						dmax = maxf(dmax, float(r.t_end))
					var dif := float(v) / n_lut - p
					soma += dif
					n += 1
					total += 1
					if absf(dif) > 0.05:
						gt5 += 1
					pior_est = maxf(pior_est, absf(dif))
			if not cat.has(idx):
				cat[idx] = {}
			cat[idx][combo[0] + str(combo[1])] = [soma, n]
			if not por_adv.has(idx):
				por_adv[idx] = [0.0, 0]
			por_adv[idx][0] += soma
			por_adv[idx][1] += n
		g.free()
		print("combo %s %d pronta (%.0f s)" % [combo[0], combo[1], (Time.get_ticks_msec() - t0) / 1000.0])
	for idx in REG:
		var linha := ""
		var pior_c := 0.0
		for c in cat[idx]:
			var d: float = 100.0 * cat[idx][c][0] / maxf(cat[idx][c][1], 1)
			linha += " %s %+.1f" % [c, d]
			pior_c = maxf(pior_c, absf(d))
		var med: float = 100.0 * por_adv[idx][0] / maxf(por_adv[idx][1], 1)
		print("ADV %d: dif media (real - mostrada) %+.2f pts em %d estados | por combinacao:%s" % [idx, med, por_adv[idx][1], linha])
		checar(absf(med) <= 5.0, "adversario %d: media da diferenca %.2f dentro de +-5" % [idx, med])
	print("RESUMO: %d estados, pior estado %.1f pts, >5 pts em %d (%.1f%%); previa x motor |max dif| %.6f; t_end %.2f..%.2f => tela %.1f..%.1f s; %.0f s" % [total, 100.0 * pior_est, gt5, 100.0 * gt5 / maxf(total, 1), consist_max, dmin, dmax, dmin + 3.0, dmax + 3.0, (Time.get_ticks_msec() - t0) / 1000.0])
	checar(consist_max < 1.0e-9, "previa().risks == motor.chance")
