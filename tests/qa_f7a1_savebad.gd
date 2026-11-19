extends SceneTree
## QA 7a1: luta pendente com `finish` incoerente (save editado/antigo) e abrindo a tela de luta; so olha erros de script.
## godot --headless --path . --script res://tests/qa_f7a1_savebad.gd   (APPDATA temporario)

const PASTA := "user://test/qa7a1savebad/"
var gs: Node
var cena: Node


func _initialize() -> void:
	gs = root.get_node("GameState")
	await process_frame
	for caso in ["sem_arte_finish_submission", "boxe_finish_submission", "jj_finish_knockout", "finish_lixo", "jj_sem_finish_ko", "t_ko_negativo_com_finish"]:
		await _rodar(caso)
	print("FIM")
	quit(0)


func _novo(arte: String) -> void:
	if cena != null:
		cena.queue_free()
		cena = null
	gs.definir_assistido(false)
	gs.inicializar(PASTA, "res://data/config.json")
	gs.autosave_ativo = false
	gs.apagar_save()
	gs.rng.seed = 1
	gs.pular_abertura()
	gs.permanente = {"legacy_total": 12, "career_number": 2, "careers_finished": 1, "best_wins": 2, "belts_won": 0, "arts_unlocked": ["boxing", "bjj"], "last_art": arte}
	gs.modal_aberto = false
	gs._recalcular_bonus()
	gs.indice_escada = 4
	gs.cinturao = true
	gs.local_id = "gym"
	gs.arte_id = arte
	gs._atualizar_traco()
	gs.aparelhos_montados_ids = ["punching_bag", "treadmill", "jump_rope"]
	gs.foco = "punching_bag"


func _rodar(caso: String) -> void:
	var arte := "bjj" if caso.begins_with("jj") else ("boxing" if caso.begins_with("boxe") else ("" if caso.begins_with("sem") else "bjj"))
	_novo(arte)
	var opp: Dictionary = gs.lutas.adversarios[4]
	var atr := {"strength": opp.strength * 1.2, "agility": opp.agility * 1.2, "endurance": opp.endurance * 1.2}
	gs.atributos = atr.duplicate()
	gs.rng.seed = 7
	var info: Dictionary = gs.lutar()
	if info.is_empty():
		print("%s: lutar() vazio" % caso)
		return
	var r: Dictionary = gs.luta.result
	match caso:
		"sem_arte_finish_submission":
			r["finish"] = "submission"
		"boxe_finish_submission":
			r["finish"] = "submission"
		"jj_finish_knockout":
			r["finish"] = "knockout"
		"finish_lixo":
			r["finish"] = "banana"
		"jj_sem_finish_ko":
			r.erase("finish")
			r["ko"] = true
			r["t_ko"] = 6.0
		"t_ko_negativo_com_finish":
			r["finish"] = "submission"
			r["t_ko"] = -1.0
			r["ko"] = true
	gs.salvar()
	# recarrega pelo caminho do save (validacao)
	gs.inicializar(PASTA, "res://data/config.json")
	gs.autosave_ativo = false
	var tem: bool = not gs.luta.is_empty()
	var fin: String = str(gs.luta.get("result", {}).get("finish", "(sem)"))
	print("== %s: luta pendente apos recarregar=%s finish salvo=%s" % [caso, tem, fin])
	if not tem:
		return
	var la: Dictionary = gs.luta_atual()
	print("   luta_atual.result.finish=%s eventos=%d ultimo.finish=%s" % [la.result.finish, la.events.size(), la.events[-1].finish if la.events.size() > 0 else "-"])
	cena = load("res://scenes/main.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	await create_timer(0.5).timeout
	var tela: Node = cena.get_node("Fluxo").tela
	if tela == null or not tela.visible:
		print("   tela de luta nao abriu (luta pendente) visivel=%s" % [tela != null and tela.visible])
		cena.queue_free()
		cena = null
		return
	var fim_t: float = float(tela._fim_total)
	var t0 := Time.get_ticks_msec()
	tela._clock = fim_t - 4.0
	await create_timer(1.0).timeout
	var banner: bool = tela._banner_sub_img.visible
	print("   FINALIZOU visivel=%s  _passiva=%s" % [banner, tela._passiva])
	tela._clock = fim_t + 0.5
	await create_timer(1.0).timeout
	cena.queue_free()
	cena = null
