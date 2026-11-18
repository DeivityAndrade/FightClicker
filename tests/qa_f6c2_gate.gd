extends "res://tests/test_base.gd"
const GameStateScript := preload("res://scripts/game_state.gd")
func rodar_testes() -> void:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa("qa_gate"), "res://data/config.json")
	gs.autosave_ativo = false
	gs.pular_abertura()
	gs.local_id = "garage"
	var g: Dictionary = gs.mural_na_sala()
	checar(not g.is_empty() and g.spot.size() == 2, "garagem: mural sempre " + str(g))
	gs.local_id = "gym"
	checar_igual(gs.mural_na_sala(), {}, "academia sem a cena: sem mural")
	gs._gravar_marco("cena_primeira_academia", {}, false)
	var a: Dictionary = gs.mural_na_sala()
	checar(not a.is_empty() and a.spot.size() == 2, "academia depois da cena: mural " + str(a))
	gs.local_id = "inexistente"
	checar_igual(gs.mural_na_sala(), {}, "local desconhecido: sem mural")
	# hall.json: nomes finais dos 6 nos
	var nomes := []
	for n in gs.hall_lista():
		nomes.append(n.name)
	print("nomes: ", nomes)
	checar_igual(nomes, ["FITA FROUXA", "VAQUINHA", "CADERNINHO", "TURMA DA ESCOLA", "LUVA NO GANCHO", "PAREDE MAIOR"], "nomes finais dos 6 nos (textos do Roteirista)")
	var descs := []
	for n in gs.hall_lista():
		descs.append(n.effect_text)
	print("descs: ", descs)
	gs.aguardar_falta()
	gs.free()
