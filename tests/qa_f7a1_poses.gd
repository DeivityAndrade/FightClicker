extends SceneTree
## QA 7a1: linha do tempo das poses (nome da folha e quadro) dos dois lutadores numa luta real de Jiu-jitsu e de Boxe.
## Mostra as trocas de pose (compactado) e confere: queda + fall, repouso no chao, submission/tap_out parados no ultimo quadro.
## godot --headless --path . --script res://tests/qa_f7a1_poses.gd   (APPDATA temporario)

const PASTA := "user://test/qa7a1poses/"
var gs: Node
var cena: Node
var cap := ""
var feitos := {}


func _initialize() -> void:
	gs = root.get_node("GameState")
	await process_frame
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cap="):
			cap = a.substr(6)
			DirAccess.make_dir_recursive_absolute(cap)
	if cap != "":
		await _caso("bjj", 4, "defensive", "submission")
		quit(0)
		return
	await _caso("bjj", 4, "defensive", "submission")
	await _caso("bjj", 4, "aggressive", "points")
	await _caso("bjj", 5, "defensive", "any")
	await _caso("boxing", 4, "aggressive", "knockout")
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
	gs.permanente = {"legacy_total": 12, "career_number": 2, "careers_finished": 1, "best_wins": 2, "belts_won": 0, "arts_unlocked": [], "last_art": ""}
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


func _caso(arte: String, idx: int, tat: String, quer: String) -> void:
	_novo(arte, idx)
	var opp: Dictionary = gs.lutas.adversarios[idx]
	var achou := {}
	for f in [[1.0, 1.0, 1.0], [1.2, 1.2, 1.2], [0.9, 0.9, 0.9], [1.5, 0.8, 1.5], [0.8, 1.5, 0.8]]:
		var atr := {"strength": opp.strength * f[0], "agility": opp.agility * f[1], "endurance": opp.endurance * f[2]}
		for k in range(1, 400):
			var r := RandomNumberGenerator.new()
			r.seed = k
			var res: Dictionary = gs.motor.lutar([atr.strength, atr.agility, atr.endurance], [opp.strength, opp.agility, opp.endurance], tat, int(r.randi()), false)
			if quer == "any" or (quer == "points" and res.finish == "points") or (res.win and res.finish == quer):
				achou = {"atr": atr, "k": k}
				break
		if not achou.is_empty():
			break
	print("#### %s idx %d %s quer %s -> %s" % [arte, idx, tat, quer, "achou" if not achou.is_empty() else "NAO ACHOU"])
	if achou.is_empty():
		return
	gs.atributos = achou.atr.duplicate()
	gs.definir_tatica(tat)
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	await create_timer(0.4).timeout
	gs.rng.seed = int(achou.k)
	var fluxo: Node = cena.get_node("Fluxo")
	fluxo.abrir_previa()
	await create_timer(0.3).timeout
	fluxo.janela.lutar_pedido.emit()
	await create_timer(0.2).timeout
	var tela: Node = fluxo.tela
	var res_salvo: Dictionary = gs.luta.result
	print("   resultado: finish=%s t_ko=%.2f t_end=%.2f win=%s arena=%s" % [res_salvo.get("finish", "?"), float(res_salvo.t_ko), float(res_salvo.t_end), res_salvo.win, tela.luta.arena])
	var linha: Array = []
	var ant := ["", ""]
	var t_prev := -9.0
	var passos := 0
	var fim_t: float = float(tela._fim_total)
	while tela._clock < fim_t + 0.5 and passos < 400:
		await create_timer(0.1).timeout
		passos += 1
		var a: String = str(tela._l[0].spr.nome_sprite).replace("fight_player_", "").replace("_disc_layered", "").replace("_disc", "")
		var b: String = str(tela._l[1].spr.nome_sprite).replace("opp_gym_1_", "").replace("opp_gym_2_", "")
		var sa := "%s#%d" % [a, tela._l[0].spr.frame]
		var sb := "%s#%d" % [b, tela._l[1].spr.frame]
		if cap != "":
			var chave := ""
			if tela._fase_visual == "ground" and a.begins_with("block") and not feitos.has("block"):
				chave = "block"
			elif tela._fase_visual == "ground" and a.begins_with("uppercut") and not feitos.has("uppercut") and tela._l[0].spr.frame >= 3:
				chave = "uppercut"
			elif a.begins_with("takedown") and tela._l[0].spr.frame >= 3 and not feitos.has("takedown"):
				chave = "takedown"
			elif b.begins_with("fall") and not feitos.has("fall"):
				chave = "fall"
			if chave != "":
				feitos[chave] = true
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(cap.path_join("pose_%s.png" % chave))
				print("   captura %s em t=%.2f" % [chave, tela._clock])
		if a != ant[0] or b != ant[1]:
			print("   t=%5.2f fase=%-8s jogador=%-26s adv=%-26s estado=%s/%s" % [tela._clock, tela._fase_visual, sa, sb, tela._l[0].estado, tela._l[1].estado])
			ant = [a, b]
	# ultimos quadros: parados?
	var f1: int = tela._l[0].spr.frame
	var f2: int = tela._l[1].spr.frame
	await create_timer(0.5).timeout
	print("   fim: jogador %s #%d->#%d (hframes %d) | adv %s #%d->#%d (hframes %d) | letreiro sub visivel=%s" % [tela._l[0].spr.nome_sprite.get_file(), f1, tela._l[0].spr.frame, tela._l[0].spr.hframes,
		tela._l[1].spr.nome_sprite.get_file(), f2, tela._l[1].spr.frame, tela._l[1].spr.hframes, tela._banner_sub_img.visible])
	cena.queue_free()
	cena = null
	await create_timer(0.2).timeout
