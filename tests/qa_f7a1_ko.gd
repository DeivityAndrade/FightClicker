extends "res://tests/test_base.gd"
## QA 7a1: distribuicao do K.O. do Boxe por round, tempos dos golpes antes/depois do cansaco.

var dados: FightData
var gym: GymData
const OPPS := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]


func _opp(id: String) -> Array:
	var o := dados.adversario(id)
	return [o.strength, o.agility, o.endurance]


func rodar_testes() -> void:
	dados = FightData.carregar()
	gym = GymData.carregar()
	var m := Luta.new(dados)
	m.passiva = gym.arte("boxing").passive.duplicate(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	print("## KO do Boxe por adversario (jogador 0.9-1.1x do total dele, AGI alta 40%%, tatica agressiva e defensiva)")
	for oid in OPPS:
		var adv := _opp(oid)
		for t in ["aggressive", "defensive"]:
			var wins := 0
			var ko := 0
			var r1 := 0
			var r2 := 0
			var r3 := 0
			var dano := 0
			var pts := 0
			var n := 2000
			var soma_t := 0.0
			for i in n:
				var tot: float = (adv[0] + adv[1] + adv[2]) * rng.randf_range(0.9, 1.1)
				var w := [0.3, 0.4, 0.3]
				var jog := [tot * w[0], tot * w[1], tot * w[2]]
				var r := m.lutar(jog, adv, t, 70000 + i)
				if r.win:
					wins += 1
					soma_t += r.t_end
					if r.finish == "knockout":
						ko += 1
						if r.round == 1:
							r1 += 1
						elif r.round == 2:
							r2 += 1
						else:
							r3 += 1
					elif r.finish == "damage":
						dano += 1
					else:
						pts += 1
			print("  %s %s: vitorias %d | por dano %d | KO passiva %d (R1 %d, R2 %d, R3 %d) | pontos %d | t medio %.1f s" % [oid, t, wins, dano, ko, r1, r2, r3, pts, soma_t / maxf(1, wins)])
	print("## Intervalos de ataque do jogador em luta longa (boxe, vs Seu Muralha)")
	var adv2 := _opp("opp_tank")
	for t in ["aggressive", "defensive", "counter"]:
		for s in range(1, 200):
			var r := m.lutar([adv2[0] * 0.6, adv2[1] * 1.0, adv2[2] * 1.0], adv2, t, s, true)
			if r.t_end < 15.9:
				continue
			var ts: Array = []
			for e in r.events:
				if e.who == 0 and not e.counter:
					ts.append(snappedf(e.t, 0.01))
			var ivs: Array = []
			for i in range(1, ts.size()):
				ivs.append(snappedf(ts[i] - ts[i - 1], 0.01))
			var tir := 0
			var ult_cans := -1.0
			for e in r.events:
				if e.tired:
					tir += 1
					if ult_cans < 0.0:
						ult_cans = e.t
			print("  %s seed %d: t_end %.1f tires %s | 1o evento cansado em t=%.2f | intervalos %s" % [t, s, r.t_end, r.tires, ult_cans, str(ivs)])
			break
