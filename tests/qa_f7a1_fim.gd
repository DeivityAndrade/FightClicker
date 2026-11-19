extends SceneTree
## QA 7a1: tela de fim depois de derrota com cada nota da passiva (6 ids). Abre a cena principal com save de teste
## (user://test/qa7a1fim/), captura PNG em --saida=... (pasta temporaria) e mede se algum texto cai sobre os botoes.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f7a1_fim.gd -- --saida=C:\tmp\

const PASTA := "user://test/qa7a1fim/"
var gs: Node
var cena: Node
var saida := "user://test/qa7a1fim_out/"


func _initialize() -> void:
	gs = root.get_node("GameState")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			saida = a.substr(8)
	DirAccess.make_dir_recursive_absolute(saida)
	await process_frame
	await _tudo()
	quit(0)


func _novo(arte: String, idx: int) -> void:
	if cena != null:
		cena.queue_free()
		cena = null
	gs.definir_assistido(false)
	gs.inicializar(PASTA, "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 1
	gs.pular_abertura()
	gs.atributos = {"strength": 300.0, "agility": 60.0, "endurance": 200.0}
	gs.treino = 1234.0
	gs.dinheiro = 0.0
	gs.fama = 0
	gs.indice_escada = 0
	gs.permanente = {"legacy_total": 12, "career_number": 2, "careers_finished": 1, "best_wins": 2, "belts_won": 0, "arts_unlocked": [], "last_art": ""}
	gs.nivel_metronomo = 0
	gs.modal_aberto = false
	gs._recalcular_bonus()
	for g in gs.dados.geradores:
		gs.geradores[g.id] = 3
	gs.indice_escada = idx
	gs.cinturao = true
	gs.local_id = "gym"
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.permanente["last_art"] = arte
	gs.arte_id = arte
	gs.arte_segundos = 0.0
	gs._atualizar_traco()
	gs.aparelhos_montados_ids = ["punching_bag", "treadmill", "jump_rope"]
	gs.foco = "punching_bag"
	gs.treino = 800.0


func _tudo() -> void:
	var achados := {}
	for arte in ["boxing", "bjj"]:
		for idx in [4, 5]:
			_novo(arte, idx)
			var opp: Dictionary = gs.lutas.adversarios[idx]
			for tat in ["aggressive", "defensive", "counter"]:
				for f in [[0.6, 0.6, 0.6], [0.7, 0.7, 0.7], [0.8, 0.8, 0.8], [0.9, 0.9, 0.9], [0.8, 0.5, 0.8], [0.6, 1.0, 1.0], [1.0, 0.6, 1.0], [1.0, 1.0, 0.6], [1.0, 1.0, 1.0]]:
					var atr := {"strength": opp.strength * f[0], "agility": opp.agility * f[1], "endurance": opp.endurance * f[2]}
					for k in range(1, 120):
						var r := RandomNumberGenerator.new()
						r.seed = k
						var res: Dictionary = gs.motor.lutar([atr.strength, atr.agility, atr.endurance], [opp.strength, opp.agility, opp.endurance], tat, int(r.randi()), false)
						if bool(res.win):
							continue
						var nota: Dictionary = gs.motor.nota_passiva(res, tat)
						var id := str(nota.get("id", "nenhuma"))
						var chave := id
						if not achados.has(chave):
							achados[chave] = {"arte": arte, "idx": idx, "tat": tat, "atr": atr, "k": k}
	print("notas achadas: ", achados.keys())
	for id in achados:
		var a: Dictionary = achados[id]
		_novo(str(a.arte), int(a.idx))
		gs.atributos = a.atr.duplicate()
		gs.definir_tatica(str(a.tat))
		gs.rng.seed = int(a.k)
		gs.lutar()
		gs.aguardar_motivo()
		gs.concluir_luta()
		var t: Dictionary = gs.textos_fim()
		print("== %s (%s %s idx %d)" % [id, a.arte, a.tat, a.idx])
		print("   who: %s" % t.get("who", ""))
		print("   reason: %s" % t.get("reason", ""))
		print("   stat: %s" % t.get("stat", ""))
		print("   tip: %s" % t.get("tip", ""))
		print("   tip_extra: %s" % t.get("tip_extra", ""))
		print("   passive_note: %s" % t.get("passive_note", ""))
		print("   passive_note_tip: %s" % t.get("passive_note_tip", ""))
		cena = load("res://scenes/main.tscn").instantiate()
		root.add_child(cena)
		await process_frame
		await create_timer(1.3).timeout
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png(saida.path_join("fim_%s.png" % id))
		# medida: algum rotulo da janela passa de onde os botoes comecam?
		var janela: Node = cena.get_node("Fluxo").janela
		if janela != null:
			var botoes: Array = []
			var labels: Array = []
			for n in janela.find_children("*", "Button", true, false):
				if (n as Control).is_visible_in_tree():
					botoes.append(n)
			for n in janela.find_children("*", "Label", true, false):
				if (n as Control).is_visible_in_tree() and str((n as Label).text) != "":
					labels.append(n)
			var topo_botoes := 9999.0
			for b in botoes:
				topo_botoes = minf(topo_botoes, (b as Control).get_global_rect().position.y)
			var base_lbl := 0.0
			var ultimo := ""
			for l in labels:
				var rect: Rect2 = (l as Control).get_global_rect()
				if rect.end.y <= topo_botoes + 0.5 or true:
					pass
			# o texto mais baixo que ainda esta acima dos botoes
			var folga_min := 9999.0
			for l in labels:
				var rect: Rect2 = (l as Control).get_global_rect()
				if rect.position.y < topo_botoes:
					var folga := topo_botoes - rect.end.y
					if folga < folga_min:
						folga_min = folga
						ultimo = (l as Label).text
			print("   botoes: %d topo %.1f (tela 1280x720 = 2x) | folga minima entre texto e botao %.1f px | texto mais baixo: %s" % [botoes.size(), topo_botoes / 2.0, folga_min / 2.0, ultimo])
