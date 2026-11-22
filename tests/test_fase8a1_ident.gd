extends "res://tests/test_base.gd"
## 8a1: identidade do motor contra os 6 adversarios de antes (sem arte + 6 combinacoes, 3 taticas, 30 sementes, com eventos e a chance).
## Os hashes esperados (tests/data/fase8a1_ident.json) foram gerados com ESTE script rodando no codigo da main (antes da liga):
##   godot --headless --path <copia da main> --script res://tests/test_fase8a1_ident.gd -- --gerar=<arquivo.json>
## Se o motor mudar contra os 6 de antes, o hash muda e o teste falha. Derivado de tests/qa_f8a1_ident.gd (que usa 300 sementes).

const ESPERADO := "res://tests/data/fase8a1_ident.json"
const IDS := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
const COMBOS := [["", 1], ["boxing", 1], ["boxing", 2], ["bjj", 1], ["bjj", 2], ["muay_thai", 1], ["muay_thai", 2]]
const SEMENTES := 30


func _hashes() -> Dictionary:
	var dados := FightData.carregar()
	var gym := GymData.carregar()
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var saida := {}
	for c in COMBOS:
		var m := Luta.new(dados)
		if c[0] != "":
			m.passiva = gym.arte(c[0]).get("passive" if c[1] == 1 else "passive_2").duplicate(true)
		for oid in IDS:
			var o := dados.adversario(oid)
			var adv := [o.strength, o.agility, o.endurance]
			var h := 0
			for tat in ["aggressive", "defensive", "counter"]:
				for i in SEMENTES:
					var f := rng.randf_range(0.3, 1.8)
					var jog := [adv[0] * f * rng.randf_range(0.5, 1.5), adv[1] * f * rng.randf_range(0.5, 1.5), adv[2] * f * rng.randf_range(0.5, 1.5)]
					var r: Dictionary = m.lutar(jog, adv, tat, 1000 + i, true)
					var ev := ""
					for e in r.events:
						ev += "%s:%.3f:%s;" % [str(e.get("type", "")), float(e.get("t", 0.0)), str(e.get("damage", ""))]
					var ch := m.chance(jog, adv, tat) if i % 10 == 0 else -1.0
					h = hash([h, r.win, r.t_end, str(r.get("finish", "")), r.events.size(), ev, r.pct_player, r.pct_opponent, ch])
			saida["%s|%d|%s" % [c[0], c[1], oid]] = str(h)  # texto: o JSON perderia os bits de um inteiro de 64
	return saida


func rodar_testes() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gerar="):
			escrever(a.substr(8), JSON.stringify(_hashes()))
			print("hashes gravados em ", a.substr(8))
			return
	var atual := _hashes()
	var esperado = JSON.parse_string(ler(ESPERADO))
	checar(esperado is Dictionary and esperado.size() == COMBOS.size() * IDS.size(), "hashes esperados existem")
	if not (esperado is Dictionary):
		return
	var diferentes: Array = []
	for k in atual:
		if str(esperado.get(k, "")) != str(atual[k]):
			diferentes.append(k)
	checar(diferentes.is_empty(), "motor igual ao da main contra os 6 de antes (%d de %d combinacoes iguais)%s" % [atual.size() - diferentes.size(), atual.size(),
		"" if diferentes.is_empty() else " | diferentes: " + str(diferentes.slice(0, 4))])
