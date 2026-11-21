extends "res://tests/test_base.gd"
## QA 7b2: abre uma COPIA do save do dono (variavel QA_SAVE_COPIA = pasta da copia, com save.json) e confere que abre sem erro.
const GS := preload("res://scripts/game_state.gd")
func rodar_testes() -> void:
	var pasta := OS.get_environment("QA_SAVE_COPIA")
	checar(pasta != "", "QA_SAVE_COPIA definida")
	var gs: Node = GS.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	checar(gs.permanente.has("passive_wins") and gs.permanente.passives_unlocked is Array, "campos 7b2 existem depois de abrir")
	checar(gs.passiva_carreira == 1, "passiva da carreira = 1 (save de antes da 7b2)")
	for a in ["boxing", "bjj", "muay_thai"]:
		var pr: Dictionary = gs.progresso_passiva(a)
		print("   %s: %s liberada=%s" % [a, pr.text, str(pr.liberada)])
	print("   artes liberadas: %s; arte da carreira: '%s'; escada %d" % [str(gs.permanente.arts_unlocked), gs.arte_id, gs.indice_escada])
	gs.artes_para_escolha(); gs.previa(); gs.luta_atual()
	checar(gs.salvar(), "salva (na copia)")
	gs.aguardar_motivo()
	gs.free()
