extends "res://tests/test_base.gd"
## QA 7b2: com que frequência o fim pela 2ª passiva aparece (por tática, divisão e força), em lutas reais do motor.
const ARTES := ["boxing", "bjj", "muay_thai"]
const FIM2 := {"boxing": "counter_ko", "bjj": "ground_stop", "muay_thai": "knee_ko"}
func rodar_testes() -> void:
	var dados := FightData.carregar()
	var gym := GymData.carregar()
	for arte in ARTES:
		var m := Luta.new(dados)
		m.passiva = gym.arte(arte).passive_2.duplicate(true)
		for oid in ["opp_gym_1", "opp_tank", "opp_gym_2"]:
			var o := dados.adversario(oid)
			var adv := [o.strength, o.agility, o.endurance]
			var tot: float = adv[0] + adv[1] + adv[2]
			for esc in [0.8, 0.9, 1.0, 1.1]:
				for div in [[1,1,1],[2,1,1],[1,2,1],[1,1,2],[2,1,2]]:
					var sd: float = div[0] + div[1] + div[2]
					var jog := [tot * esc * div[0] / sd, tot * esc * div[1] / sd, tot * esc * div[2] / sd]
					var linha := ""
					for tat in ["aggressive", "defensive", "counter"]:
						var d := m.chance_detalhada(jog, adv, tat)
						var w := int(d.wins)
						var pa := 10.0 * float(d.wins_passive) / maxf(w, 1)
						linha += " %s: %3d%% (%.1f em 10)" % [tat.substr(0, 3), int(100.0 * d.chance), pa]
					print("%-9s %-10s x%.1f %s |%s" % [arte, oid, esc, str(div), linha])
	checar(true, "ok")
