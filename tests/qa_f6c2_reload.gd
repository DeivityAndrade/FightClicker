extends "res://tests/test_base.gd"
const GameStateScript := preload("res://scripts/game_state.gd")
func _novo(nome: String, pasta: String = "") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta if pasta != "" else pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	return gs
func rodar_testes() -> void:
	var pasta := pasta_limpa("qa_reload")
	var gs := _novo("qa_reload", pasta)
	gs.indice_escada = 3
	var f: Dictionary = gs.aposentar()
	checar_igual(f.honor_gained, 6, "6 de Honra com 3 vitorias")
	gs.free()
	for i in 3:
		var g := _novo("qa_reload_b%d" % i, pasta)
		checar_igual([g.fim.get("honor_gained", -1), g.honra(), g.honra_total(), g.escola.roster.size(), g.escola.roster[0].honor], [6, 6, 6, 1, 6], "recarga %d com fim pendente: Honra estavel" % (i + 1))
		g.salvar()
		g.free()
	# autosave tick com fim pendente nao duplica
	var g2 := _novo("qa_reload_c", pasta)
	for i in 2000:
		g2.tick(0.1)
	checar_igual([g2.honra(), g2.escola.roster.size()], [6, 1], "ticks com fim pendente: nada muda")
	checar(g2.comprar_hall("hall_box") == false, "6 de Honra nao compra a de 10")
	g2.free()
