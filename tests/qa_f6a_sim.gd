extends SceneTree
const GS := preload("res://scripts/game_state.gd")
func _initialize() -> void:
	await process_frame
	var gs: Node = GS.new()
	var pasta := "user://test/qa6_sim/"
	DirAccess.make_dir_recursive_absolute(pasta)
	for f in DirAccess.get_files_at(pasta):
		DirAccess.remove_absolute(pasta + f)
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.rng.seed = 1234
	var log := []
	var t := 0.0
	var lutas := 0
	while t < 1200.0:
		gs.tick(0.1)
		t += 0.1
		gs.clicar()
		if gs.no_dia_da_luta() and gs.luta.is_empty() and gs.fim.is_empty():
			gs.lutar()
			var r: Dictionary = gs.concluir_luta()
			lutas += 1
			log.append("luta@%.0f win=%s" % [t, str(r.get("win"))])
			if not gs.fim.is_empty():
				log.append("fim@%.0f" % t)
				gs.nova_carreira()
		if int(round(t * 10)) % 3000 == 0:
			log.append("t=%.0f treino=%.3f dinheiro=%.3f dia=%s" % [t, gs.treino, gs.dinheiro, str(gs.fight_day)])
	print("\n".join(log))
	print("LUTAS ", lutas)
	quit(0)

