extends SceneTree
## QA 8a1: identidade do motor contra os 6 adversarios de hoje: 6 (sem arte + 6 combinacoes = 7) x 3 taticas x 300 sementes, com eventos.
## Roda igual na main e na pasta da 8a1; o hash tem que ser o mesmo. Uso: --script res://tests/qa_f8a1_ident.gd -- --out=<arquivo>
func _initialize() -> void:
	var dados := FightData.carregar()
	var gym := GymData.carregar()
	var ids := ["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"]
	var combos := [["", 1], ["boxing", 1], ["boxing", 2], ["bjj", 1], ["bjj", 2], ["muay_thai", 1], ["muay_thai", 2]]
	var linhas: PackedStringArray = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var tot := 0
	for c in combos:
		var m := Luta.new(dados)
		if c[0] != "":
			m.passiva = gym.arte(c[0]).get("passive" if c[1] == 1 else "passive_2").duplicate(true)
		for oid in ids:
			var o := dados.adversario(oid)
			var adv := [o.strength, o.agility, o.endurance]
			var h := 0
			for tat in ["aggressive", "defensive", "counter"]:
				for i in 300:
					var f := rng.randf_range(0.3, 1.8)
					var jog := [adv[0] * f * rng.randf_range(0.5, 1.5), adv[1] * f * rng.randf_range(0.5, 1.5), adv[2] * f * rng.randf_range(0.5, 1.5)]
					var r: Dictionary = m.lutar(jog, adv, tat, 1000 + i, true)
					var ev := ""
					for e in r.events:
						ev += "%s:%.3f:%s;" % [str(e.get("type", e.get("kind", ""))), float(e.get("t", 0.0)), str(e.get("dmg", e.get("damage", "")))]
					h = hash([h, r.win, r.t_end, str(r.get("finish", "")), r.events.size(), ev, str(r.get("pct", "")), m.chance(jog, adv, tat)])
					tot += 1
			linhas.append("%s %s %s %d" % [c[0], c[1], oid, h])
	var out := "res://tests/qa_ident_out.txt"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string("\n".join(linhas) + "\nTOTAL %d\n" % tot)
	f.close()
	print("ok ", tot)
	quit(0)
