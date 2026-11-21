extends "res://tests/test_base.gd"
## QA 7b2: prévia honesta das 3 passivas novas, 6 adversários x N estados x 3 táticas x 1000+ lutas reais; duração de tela.
## Rodar: Godot --headless --path <pasta> --script res://tests/qa_f7b2_previa.gd   (APPDATA temporário)
## Variáveis: QA_ESTADOS (padrão 10), QA_LUTAS (padrão 1000).

const TATICAS := ["aggressive", "defensive", "counter"]
const ADVS := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
const ARTES := ["boxing", "bjj", "muay_thai"]

var dados: FightData
var gym: GymData


func rodar_testes() -> void:
	dados = FightData.carregar()
	gym = GymData.carregar()
	var n_est := int(OS.get_environment("QA_ESTADOS")) if OS.get_environment("QA_ESTADOS") != "" else 10
	var n_lut := int(OS.get_environment("QA_LUTAS")) if OS.get_environment("QA_LUTAS") != "" else 1000
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261121
	var t0 := Time.get_ticks_msec()
	var geral_pior := 0.0
	var geral_n := 0
	var geral_gt5 := 0
	var piores: Array = []
	var dmin := 999.0
	var dmax := 0.0
	for arte in ARTES:
		for extra in [0.0, 0.5]:
			var m := Luta.new(dados)
			m.passiva = gym.arte(arte).passive_2.duplicate(true)
			m.extra_passiva = extra
			var soma_abs := 0.0
			var soma_sin := 0.0
			var n := 0
			var pior := 0.0
			var gt5 := 0
			for oid in ADVS:
				var o := dados.adversario(oid)
				var adv := [o.strength, o.agility, o.endurance]
				var soma_adv := 0.0
				var n_adv := 0
				for k in n_est:
					var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.5, 1.3)
					var w := [rng.randf() + 0.2, rng.randf() + 0.2, rng.randf() + 0.2]
					var sw: float = w[0] + w[1] + w[2]
					var jog := [tot * w[0] / sw, tot * w[1] / sw, tot * w[2] / sw]
					for tat in TATICAS:
						var p: float = m.chance(jog, adv, tat)
						if p < 0.03 or p > 0.97:
							continue  # saturado: não discrimina
						var v := 0
						for i in n_lut:
							var r := m.lutar(jog, adv, tat, 700000 + i + k * 13)
							if r.win:
								v += 1
							dmin = minf(dmin, float(r.t_end))
							dmax = maxf(dmax, float(r.t_end))
						var dif := float(v) / n_lut - p
						soma_abs += absf(dif)
						soma_sin += dif
						soma_adv += dif
						n_adv += 1
						n += 1
						if absf(dif) > 0.05:
							gt5 += 1
						if absf(dif) > pior:
							pior = absf(dif)
						piores.append([absf(dif), arte, extra, oid, tat, p, float(v) / n_lut, jog, adv])
				print("  %s extra %.1f %s: %d estados, dif média por adversário %+.2f pts" % [arte, extra, oid, n_adv, 100.0 * soma_adv / maxf(n_adv, 1)])
			print("== %s extra %.1f: %d estados, |dif| média %.2f, viés %+.2f, pior %.1f pts, >5 pts: %d" % [arte, extra, n, 100.0 * soma_abs / n, 100.0 * soma_sin / n, 100.0 * pior, gt5])
			geral_pior = maxf(geral_pior, pior)
			geral_n += n
			geral_gt5 += gt5
	piores.sort_custom(func(a, b): return a[0] > b[0])
	print("--- 6 piores estados (1000 lutas) ---")
	var re := Luta.new(dados)
	for j in mini(6, piores.size()):
		var x: Array = piores[j]
		# remedir o pior com 8000 lutas para separar ruído do viés
		var m2 := Luta.new(dados)
		m2.passiva = gym.arte(x[1]).passive_2.duplicate(true)
		m2.extra_passiva = x[2]
		var v8 := 0
		for i in 8000:
			if m2.lutar(x[7], x[8], x[4], 3000000 + i).win:
				v8 += 1
		print("%s extra %.1f %s %s: mostrada %.1f%% real(1000) %.1f%% real(8000) %.1f%%  dif8000 %+.1f" % [x[1], x[2], x[3], x[4], 100.0 * x[5], 100.0 * x[6], 100.0 * float(v8) / 8000.0, 100.0 * (float(v8) / 8000.0 - x[5])])
	print("RESUMO: %d estados, pior %.1f pts, >5 pts em %d (%.1f%%); t_end min %.2f max %.2f => tela %.1f a %.1f s; %.0f s" % [geral_n, 100.0 * geral_pior, geral_gt5, 100.0 * geral_gt5 / geral_n, dmin, dmax, dmin + 3.0, dmax + 3.0, (Time.get_ticks_msec() - t0) / 1000.0])
	checar(geral_n > 0, "rodou")
