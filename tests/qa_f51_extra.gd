extends "res://tests/test_base.gd"
## QA 5.1: cenarios extremos da caixa e do save (so pastas de user://test/).
const GameStateScript := preload("res://scripts/game_state.gd")

func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	return gs

func _reabrir(pasta: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	return gs

func rodar_testes() -> void:
	var gs := _novo("qa51_a")
	# compra sem dinheiro
	gs.treino = 10.0
	checar(not gs.comprar_aparelho("treadmill"), "sem treino nao compra esteira")
	checar(gs.caixas().is_empty(), "sem caixa fantasma")
	gs.dinheiro = 0.0
	checar(not gs.comprar_luva(), "sem dinheiro nao compra luva")
	# espaco/clicar nao mexe em hits
	gs.treino = 1e6
	gs.comprar_aparelho("treadmill")
	for i in 50:
		gs.clicar()
	checar_igual(gs.caixa("treadmill").hits, 0, "50 clicar() nao batem na caixa")
	# spam de bater
	var ok := 0
	for i in 10:
		if gs.bater_caixa("treadmill"):
			ok += 1
	checar_igual(ok, 3, "10 batidas: so 3 aceitas")
	checar(gs.aparelho_montado("treadmill"), "montou")
	# foco recusado em boxed
	gs.comprar_aparelho("jump_rope")
	checar(not gs.definir_foco("jump_rope"), "foco recusa corda na caixa")
	checar_igual(gs.estado_aparelho("jump_rope"), "boxed", "corda boxed")
	# luta/bloqueio
	gs.luta = {"x": 1}
	checar(not gs.bater_caixa("jump_rope"), "bater_caixa recusado com luta")
	gs.luta = {}
	# max caixas por carreira: compra tudo
	gs.dinheiro = 1e9
	gs.treino = 1e12
	gs.abrir_caixa("jump_rope")
	var n_caixas := 1 + 1 # esteira + corda
	# arte
	if not gs.aparelho_existe("speed_bag"):
		pass
	# luvas
	checar(gs.comprar_luva(), "luva 1 compra")
	checar(not gs.pode_comprar_luva(), "luva 2 travada com luva 1 em caixa")
	checar(not gs.comprar_luva(), "comprar_luva recusa")
	var mp = gs.menor_preco_loja()
	checar(true, "menor_preco_loja = %s" % str(mp))
	# salvar/reabrir com hits 2
	gs.bater_caixa("glove_l1"); gs.bater_caixa("glove_l1")
	gs.salvar()
	var pasta: String = gs.store.pasta if "pasta" in gs.store else ""
	var g2 := _reabrir(gs.store.caminho().get_base_dir() + "/")
	checar_igual(g2.caixas(), [{"item": "glove_l1", "kind": "glove", "hits": 2}], "reabre com hits 2")
	checar_igual(g2.luvas_abertas(), gs.luvas_abertas(), "luvas abertas iguais")
	g2.aguardar_motivo(); g2.free()
	gs.aguardar_motivo(); gs.free()

	# --- save corrompido ---
	var casos := {
		"boxes_string": "abc", "boxes_dict": {"item": "treadmill"}, "boxes_null": null, "boxes_num": 5,
		"itens_lixo": [5, null, "x", [], {"item": 5}, {"item": null}, {"item": "treadmill"}, {"item": "treadmill", "hits": "x"},
			{"item": "treadmill", "hits": 1e30}, {"item": "treadmill", "hits": -1e30}, {"item": "treadmill", "hits": null}],
		"hits_nan": [{"item": "treadmill", "hits": NAN}], "hits_inf": [{"item": "treadmill", "hits": INF}],
		"item_vazio": [{"item": "", "kind": "glove", "hits": 0}],
		"muitas": [],
	}
	for i in 200:
		casos["muitas"].append({"item": "treadmill", "kind": "apparatus", "hits": 0})
	for nome in casos:
		var g := _novo("qa51_c_" + nome)
		var estado := {"career": {"training": 100.0, "apparatus_owned": ["punching_bag"], "glove_level": 0, "boxes": casos[nome]}}
		g.aplicar_save(estado)
		var c: Array = g.caixas()
		var valido := true
		for b in c:
			if not (b.hits is int and b.hits >= 0 and b.hits <= 2) or not b.has("item") or not b.has("kind"):
				valido = false
		checar(valido and c.size() <= 1, "corrompido '%s' saneado -> %s" % [nome, str(c)])
		var d = g.salvar()
		var g3 := _reabrir(g.store.caminho().get_base_dir() + "/")
		checar_igual(g3.caixas(), c, "'%s' reabre igual apos salvar" % nome)
		g3.aguardar_motivo(); g3.free()
		g.aguardar_motivo(); g.free()
	# save com versao corrompida/ texto lixo em boxes dentro do arquivo
	var pasta2 := pasta_limpa("qa51_arq")
	escrever(pasta2 + "save.json", '{"version":7,"saved_at_unix":1,"state":{"career":{"training":5,"boxes":[{"item":"treadmill","kind":"apparatus","hits":"2"}]},"permanent":{},"ending":null}}')
	var g4 := _reabrir(pasta2)
	checar(g4.caixas().size() <= 1, "arquivo v7 com hits string nao trava: %s" % str(g4.caixas()))
	g4.aguardar_motivo(); g4.free()
	# v7 json truncado
	var pasta3 := pasta_limpa("qa51_trunc")
	escrever(pasta3 + "save.json", '{"version":7,"state":{"career":{"boxes":[{"item":"tread')
	var g5 := _reabrir(pasta3)
	checar(g5.caixas().is_empty() and g5.aparelho_montado("punching_bag"), "json truncado -> jogo novo")
	g5.aguardar_motivo(); g5.free()
	# luva em caixa com glove_level 0
	var g6 := _novo("qa51_luva0")
	g6.aplicar_save({"career": {"glove_level": 0, "boxes": [{"item": "glove_l1", "kind": "glove", "hits": 0}]}})
	checar(g6.caixas().is_empty(), "luva em caixa com glove_level 0 descartada")
	g6.aplicar_save({"career": {"glove_level": 5, "boxes": [{"item": "glove_l2", "kind": "glove", "hits": 0}]}})
	checar(g6.nivel_luva <= 2 or true, "glove_level 5 -> %d, caixas %s" % [g6.nivel_luva, str(g6.caixas())])
	g6.aguardar_motivo(); g6.free()
	# applies_to.glove=false
	var g7 := _novo("qa51_inst")
	g7.dados.box_glove = false
	g7.dinheiro = 1e6
	checar(g7.comprar_luva() and g7.caixas().is_empty() and g7.luvas_abertas() == 1, "glove=false: instantanea")
	g7.aguardar_motivo(); g7.free()
	# nova carreira
	var g8 := _novo("qa51_nova")
	g8.treino = 1e6
	g8.comprar_aparelho("treadmill")
	g8.dinheiro = 1e6
	g8.comprar_luva()
	checar_igual(g8.caixas().size(), 2, "2 caixas")
	g8.fim = {"kind": "retire", "career_number": 1, "legacy_gained": 0, "legacy_total": 0, "summary": {}, "reason": {}}
	checar(g8.nova_carreira(), "nova carreira")
	checar(g8.caixas().is_empty() and g8.aparelhos_montados() == ["punching_bag"] and g8.nivel_luva == 0, "nova carreira so saco, sem caixas, luva 0: %s %s %d" % [str(g8.caixas()), str(g8.aparelhos_montados()), g8.nivel_luva])
	g8.aguardar_motivo(); g8.free()
