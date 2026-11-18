extends SceneTree
const GameStateScript := preload("res://scripts/game_state.gd")
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	await process_frame
	var gs: Node = GameStateScript.new()
	gs.inicializar("user://test/qa_thread/", "res://data/config.json")
	gs.autosave_ativo = false
	gs.pular_abertura()
	gs.escola.hall_nodes.append("hall_notes")
	gs.atributos = {"strength": 50.0, "agility": 50.0, "endurance": 50.0}
	gs.indice_escada = 3
	var pv: Dictionary = gs.previa()
	print("risk=", pv.risk, " linha='", pv.missing_line, "'")
	# troca de tatica varias vezes rapido (cache/chave)
	for t in ["aggressive", "counter", "defensive", "aggressive"]:
		gs.tatica = t
		gs.previa()
	gs.aguardar_falta()
	print("aguardou")
	gs.free()
	quit(0)
