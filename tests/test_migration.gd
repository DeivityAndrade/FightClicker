extends "res://tests/test_base.gd"
## Testa a migração do save v1 (Fase 1) para v2 (Fase 2). Tudo em user://test/.

const GameStateScript := preload("res://scripts/game_state.gd")


func rodar_testes() -> void:
	_teste_v1_abre_sem_perder_treino()
	_teste_v0_chega_na_v3()
	_teste_v1_invalido()
	_teste_regravar_v3()
	_teste_v2_abre_como_carreira_1()
	_teste_v2_regravar_e_invalido()


func _abrir(nome: String, texto: String) -> Node:
	var pasta := pasta_limpa(nome)
	escrever(pasta + "save.json", texto)
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	return gs


# Critério 21: um save da Fase 1 abre com o treino mantido.
func _teste_v1_abre_sem_perder_treino() -> void:
	var gs := _abrir("mig_v1", '{"version": 1, "saved_at_unix": 1730000000, "state": {"treino": 42}}')
	checar_igual(gs.treino, 42.0, "v1 {treino: 42} -> saldo 42")
	checar_igual(gs.atributos.strength, 0.0, "atributo força começa em 0")
	checar_igual(gs.atributos.agility, 0.0, "atributo agilidade começa em 0")
	checar_igual(gs.atributos.endurance, 0.0, "atributo resistência começa em 0")
	checar_igual(gs.foco, "punching_bag", "foco = saco")
	checar_igual(gs.quantidade_gerador("neighbor_kid"), 0, "sem geradores")
	checar_igual(gs.nivel_melhoria("punching_bag"), 0, "sem melhorias")
	checar(gs.avisos.is_empty(), "abre sem avisos")
	checar_igual(gs.ultimo_save_unix, 1730000000, "data do save mantida")
	gs.free()

	var gs2 := _abrir("mig_v1_grande", '{"version": 1, "state": {"treino": 1.5e300}}')
	checar_igual(gs2.treino, 1.5e300, "treino enorme da v1 mantido")
	gs2.free()


func _teste_v0_chega_na_v3() -> void:
	var gs := _abrir("mig_v0", '{"treino": 77}')
	checar_igual(gs.treino, 77.0, "v0 passa pelas migrações e chega na v5")
	checar_igual(gs.foco, "punching_bag", "v0: foco padrão")
	gs.free()


func _teste_v1_invalido() -> void:
	for t in ['{"version": 1, "state": {"treino": "lixo"}}', '{"version": 1, "state": {"treino": -9}}',
			'{"version": 1, "state": {}}', '{"version": 1}', '{"version": 1, "state": 5}']:
		var gs := _abrir("mig_v1_ruim", t)
		checar_igual(gs.treino, 0.0, "v1 inválido %s -> saldo 0" % t)
		checar_igual(gs.foco, "punching_bag", "v1 inválido: jogo abre")
		gs.free()


# Depois de migrar e salvar, o arquivo já é v3 e reabre igual.
func _teste_regravar_v3() -> void:
	var gs := _abrir("mig_regravar", '{"version": 1, "state": {"treino": 500}}')
	var pasta: String = gs.store.pasta
	checar(gs.salvar(), "salvar após migrar")
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual(int(doc.version), SaveStore.VERSAO_ATUAL, "arquivo regravado na versão atual")
	checar_igual(float(doc.state.career.training), 500.0, "treino 500 no arquivo v3")
	checar(FileAccess.file_exists(pasta + "save.json.bak"), "save v1 antigo ficou como backup")
	var bak = JSON.parse_string(ler(pasta + "save.json.bak"))
	checar_igual(int(bak.version), 1, "backup ainda é o original v1")
	gs.free()
	var gs2: Node = GameStateScript.new()
	gs2.inicializar(pasta, "res://data/config.json")
	checar_igual(gs2.treino, 500.0, "reabrir o v4 mantém o treino")
	gs2.free()


# Critério 26: um save v2 da Fase 2 abre como Carreira 1, com tudo mantido, e o bloco permanente zerado.
func _teste_v2_abre_como_carreira_1() -> void:
	var v2 := '{"version": 2, "saved_at_unix": 1730000000, "state": {"career": {"training": 1234.5, "attributes": {"strength": 900, "agility": 200, "endurance": 134.5}, "focus": "jump_rope", "generators": {"neighbor_kid": 12, "retired_uncle": 3}, "upgrades": {"punching_bag": 2, "jump_rope": 0, "treadmill": 1}}}}'
	var gs := _abrir("mig_v2", v2)
	checar_igual(gs.treino, 1234.5, "v2: Treino mantido")
	checar_igual(gs.atributos.strength, 900.0, "v2: Força mantida")
	checar_igual(gs.atributos.agility, 200.0, "v2: Agilidade mantida")
	checar_igual(gs.atributos.endurance, 134.5, "v2: Resistência mantida")
	checar_igual(gs.foco, "jump_rope", "v2: foco mantido")
	checar_igual(gs.quantidade_gerador("neighbor_kid"), 12, "v2: vizinhos mantidos")
	checar_igual(gs.quantidade_gerador("retired_uncle"), 3, "v2: tios mantidos")
	checar_igual(gs.nivel_melhoria("punching_bag"), 2, "v2: melhoria do saco mantida")
	checar_igual(gs.nivel_melhoria("treadmill"), 1, "v2: melhoria da esteira mantida")
	checar_igual(gs.numero_carreira(), 1, "v2 vira a Carreira 1")
	checar_igual(gs.permanente, {"legacy_total": 0, "career_number": 1, "careers_finished": 0, "best_wins": 0, "belts_won": 0, "skill_nodes": [], "tree_last_node": "", "revenge_opponent": "", "arts_unlocked": [], "last_art": ""},
		"bloco permanente zerado (sem nós, sem algoz, sem artes)")
	checar_igual([gs.dinheiro, gs.fama, gs.indice_escada, gs.cinturao, gs.nivel_luva, gs.tempo_jogo],
		[0.0, 0, 0, false, 0, 0.0], "campos novos no padrão")
	checar_igual(gs.tatica, "defensive", "tática padrão")
	checar(not gs.tem_luta_pendente() and not gs.tem_fim_pendente(), "sem luta nem tela de fim")
	checar(gs.avisos.is_empty(), "abre sem avisos")
	checar_igual(gs.ultimo_save_unix, 1730000000, "data do save mantida")
	gs.free()


func _teste_v2_regravar_e_invalido() -> void:
	var gs := _abrir("mig_v2_regravar", '{"version": 2, "saved_at_unix": 5, "state": {"career": {"training": 77, "focus": "treadmill"}}}')
	var pasta: String = gs.store.pasta
	checar(gs.salvar(), "salvar após migrar a v2")
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual(int(doc.version), SaveStore.VERSAO_ATUAL, "arquivo regravado na versão atual")
	checar(doc.state.has("permanent") and doc.state.has("ending"), "v3 tem permanent e ending")
	var bak = JSON.parse_string(ler(pasta + "save.json.bak"))
	checar_igual(int(bak.version), 2, "o save v2 original ficou como backup")
	gs.free()
	var gs2: Node = GameStateScript.new()
	gs2.inicializar(pasta, "res://data/config.json")
	checar_igual(gs2.treino, 77.0, "reabrir o v4 mantém o treino")
	checar_igual(gs2.foco, "treadmill", "e o foco")
	gs2.free()
	for t in ['{"version": 2}', '{"version": 2, "state": 5}', '{"version": 2, "state": {"career": "lixo"}}']:
		var g3 := _abrir("mig_v2_ruim", t)
		checar_igual(g3.treino, 0.0, "v2 inválido %s -> saldo 0" % t)
		checar_igual(g3.numero_carreira(), 1, "v2 inválido: Carreira 1")
		g3.free()
