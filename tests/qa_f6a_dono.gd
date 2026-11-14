extends "res://tests/test_base.gd"
## QA 6a: migra uma COPIA do save do dono (copiada para user://test/, o original nunca e tocado).
const GS := preload("res://scripts/game_state.gd")
func rodar_testes() -> void:
	var pasta := pasta_limpa("qa6_copia_dono")
	var orig := ler(SaveStore.PASTA_REAL.path_join("save.json"))
	escrever(pasta + "save.json", orig)
	var antes: Dictionary = JSON.parse_string(orig).state
	var gs: Node = GS.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	checar_igual(gs.numero_carreira(), int(antes.permanent.career_number), "carreira igual")
	checar_igual(gs.lutador_atual(), "first", "campanha atual = John")
	checar_igual(gs.abertura_estado(), "pending", "abertura pendente")
	checar_igual(gs.permanente.legacy_total, int(antes.permanent.legacy_total), "legado igual")
	checar_igual(gs.permanente.skill_nodes.size(), antes.permanent.skill_nodes.size(), "arvore igual")
	checar_igual(gs.permanente.belts_won, int(antes.permanent.belts_won), "belts_won igual")
	checar(is_equal_approx(gs.treino, float(antes.career.training)), "treino igual")
	checar_igual(gs.fight_day, int(antes.career.fight_day), "calendario igual")
	checar_igual(gs.escola.milestones, {}, "sem marcos")
	gs.salvar()
	var d: Dictionary = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual(int(d.version), 11, "regravado v11")
	checar(d.state.career.has("gestured_gloves") and d.state.school.first_fighter_campaign == 3, "campos novos")
	gs.aguardar_motivo()
	gs.free()
