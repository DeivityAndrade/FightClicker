extends "res://tests/test_base.gd"
## QA 7a1: eventos de uma luta de Jiu-jitsu (golpe escolhido por evento) para achar golpes de boxe no chao.

const GameStateScript := preload("res://scripts/game_state.gd")


func rodar_testes() -> void:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa("qa7a1_eventos"), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.escolher_arte("bjj")
	var contagem := {}
	var estranhos := 0
	var lutas := 0
	for idx in [4, 5]:
		var opp: Dictionary = gs.lutas.adversarios[idx]
		for tat in ["defensive", "aggressive", "counter"]:
			for f in [[1.0, 1.0, 1.0], [1.2, 1.2, 1.2], [0.9, 0.9, 0.9], [1.5, 0.8, 1.5]]:
				var atr := {"strength": opp.strength * f[0], "agility": opp.agility * f[1], "endurance": opp.endurance * f[2]}
				for k in range(1, 40):
					var res: Dictionary = gs.motor.lutar([atr.strength, atr.agility, atr.endurance], [opp.strength, opp.agility, opp.endurance], tat, 1000 * k + idx, false)
					gs.luta = {"opponent": opp.id, "tactic": tat, "seed": 1000 * k + idx, "player": atr.duplicate(), "result": gs._luta._resultado_salvo(res)}
					var info: Dictionary = gs.luta_atual()
					lutas += 1
					for e in info.events:
						if e.type == "dodge":
							continue
						var quem := "J" if e.who == 0 else "A"
						var chave := "%s %s kind=%s move=%s anim=%s reacao=%s" % [quem, e.phase, e.kind, e.move, e.move_anim, e.defender_move_anim]
						contagem[chave] = int(contagem.get(chave, 0)) + 1
						if e.who == 0 and not (e.move_anim in ["clinch_push", "takedown", "ground_pressure", "submission"]):
							estranhos += 1
	print("lutas JJ analisadas: %d; golpes do jogador fora do estilo JJ: %d" % [lutas, estranhos])
	var chaves := contagem.keys()
	chaves.sort()
	for c in chaves:
		print("  %6d  %s" % [contagem[c], c])
	checar(estranhos == 0, "jogador de Jiu-jitsu so usa golpes do estilo bjj (estranhos %d)" % estranhos)
	gs.aguardar_motivo()
	gs.free()
