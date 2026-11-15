extends SceneTree
## QA 5.3 (janela real): prévia do dia com a fita de revanche + traço da arte; relógio com a janela minimizada/sem foco.
## godot --path . --resolution 1280x720 --position 1950,40 --script res://tests/qa_f53_shot.gd
const OUT := "C:/Users/deivi/AppData/Local/Temp/claude/4ea5d9e6a0b1fa65/ba632f0d-dc81-4067-8465-81b47bdd6b21/scratchpad/qa53/"

var gs: Node
var cena: Control
var fluxo


func frames(n: int) -> void:
	for i in n:
		await process_frame


func esperar(s: float) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < s * 1000.0:
		await process_frame


func shot(nome: String) -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.get_texture().get_image().save_png(OUT + nome + ".png")


func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	cena = load("res://scenes/garagem.tscn").instantiate()
	root.add_child(cena)
	fluxo = cena.get_node("Fluxo")
	await frames(10)
	gs.apagar_save()
	gs.dados.crit_chance = 0.0
	# 1) prévia do dia com revanche + arte
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.permanente["last_art"] = "boxing"
	gs.arte_id = "boxing"
	gs._atualizar_traco()
	gs.permanente["revenge_opponent"] = "opp_warmup"
	gs.atributos = {"strength": 200.0, "agility": 60.0, "endurance": 100.0}
	gs.fama = 200
	gs.fight_day = 13
	gs.segundos_campanha = 12.0 * 30.0 - 1.0
	await esperar(2.5)
	print("no_dia=", gs.no_dia_da_luta(), " janela=", fluxo.janela, " revenge=", gs.previa().get("revenge"))
	await esperar(0.8)
	shot("previa_dia_revanche_arte")
	if fluxo.janela != null:
		print("janela rect: ", fluxo.janela.get_global_rect())
	# 2) relógio com a janela minimizada (fora do dia)
	if fluxo.janela != null:
		fluxo.janela.passar_pedido.emit()
		await frames(5)
		fluxo.janela.cancelou.emit()
		await frames(5)
	gs.fight_day = 100
	gs.segundos_campanha = 50.0
	gs.geradores[gs.dados.geradores[0].id] = 10
	fluxo._fechar()
	await frames(5)
	print("sala_ativa antes de minimizar: ", gs.sala_ativa(), " dia=", gs.dia_campanha())
	var c0: float = gs.segundos_campanha
	var t0: float = gs.treino
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	await esperar(3.0)
	print("MINIMIZADO 3 s reais: relogio +", gs.segundos_campanha - c0, " treino +", gs.treino - t0)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await esperar(0.5)
	quit(0)
