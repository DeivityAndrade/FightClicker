extends "res://tests/test_base.gd"
## QA 7b1: chute rodado VISTO (evento spin do jogador) nas vitórias contra o Tonhão, pelo jogo de verdade (gs.lutar), por tática e nível de chance.
const GameStateScript := preload("res://scripts/game_state.gd")

func rodar_testes() -> void:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa("qa7b1_rodado"), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	gs.escolher_arte("muay_thai")
	gs.indice_escada = 4
	gs.local_id = "gym"
	var opp: Dictionary = gs.proximo_adversario()
	print("adversário: ", opp.id, " ", opp.strength, "/", opp.agility, "/", opp.endurance)
	for tat in ["aggressive", "defensive", "counter"]:
		for alvo in [0.6, 0.8, 0.95]:
			# acha o fator f (total do jogador = f x total dele, foco 2/2/1) que dá `alvo` de chance na prévia
			var tot_a: float = opp.strength + opp.agility + opp.endurance
			var f := 0.3
			for passo in 60:
				var tot: float = tot_a * f
				var ch: float = gs.motor.chance([tot * 0.4, tot * 0.4, tot * 0.2], [opp.strength, opp.agility, opp.endurance], tat)
				if ch >= alvo:
					break
				f += 0.03
			var tot: float = tot_a * f
			gs.atributos = {"strength": tot * 0.4, "agility": tot * 0.4, "endurance": tot * 0.2}
			gs.tatica = tat
			var venceu := 0
			var viu := 0
			var final_ := 0
			for k in 150:
				gs.luta = {}
				gs.rng.seed = 1000 + k
				var info: Dictionary = gs.lutar()
				if info.is_empty():
					continue
				if bool(info.result.win):
					venceu += 1
					var v := false
					for e in info.events:
						if int(e.who) == 0 and str(e.get("shin_move", "")) == "spin":
							v = true
					if v:
						viu += 1
					if str(info.result.finish) == "spin_kick":
						final_ += 1
			print("%-10s chance~%.2f (f=%.2f): vitórias %3d | chute rodado visto %3d (%.0f%%) | terminou no rodado %3d (%.0f%%)" % [tat, alvo, f, venceu, viu, 100.0 * viu / maxf(venceu, 1), final_, 100.0 * final_ / maxf(venceu, 1)])
	gs.aguardar_motivo()
	gs.free()
