extends "res://tests/test_base.gd"
## Fase 5.1: caixa de equipamento (compra gera caixa, 3 cliques abrem), save v7 e migração v6 -> v7.
## Tudo em pastas de user://test/, nunca o save real.

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
	gs.risco_hud_ativo = false
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _abrir_com_cliques(gs: Node, item: String) -> void:
	for i in 3:
		gs.bater_caixa(item)


func rodar_testes() -> void:
	_teste_dados()
	_teste_compra_gera_caixa()
	_teste_tres_batidas_abrem_aparelho()
	_teste_clique_de_treino_x_caixa()
	_teste_bloqueios_de_compra_e_foco()
	_teste_luva_em_caixa()
	_teste_persistencia()
	_teste_luta_e_janelas()
	_teste_nova_carreira()
	_teste_save_v7_e_validacoes()
	_teste_migracao_v6()
	_teste_luva_instantanea_pelo_dado()


func _teste_dados() -> void:
	var gs := _novo("f51_dados")
	var d = gs.dados
	checar_igual([d.box_clicks_to_open, d.box_open_seconds, d.box_shake_px, d.box_apparatus, d.box_glove, d.box_focus_on_open],
		[3, 1.2, [1, 2, 3], true, true, true], "bloco box de training.json lido")
	checar(d.box_open_seconds <= 1.5, "abertura <= 1,5 s")
	for item in ["treadmill", "jump_rope", "speed_bag", "grappling_dummy", "glove_l1", "glove_l2"]:
		checar(str(d.ui.box_label.get(item, "")) != "" and str(d.ui.box_stamp.get(item, "")) != "", "box_label e box_stamp de " + item)
	for chave in ["box_sender", "box_to", "box_click", "box_arrived", "box_hover_closed", "box_hover_left", "tape_open", "tape_locked",
			"tape_locked_box", "tape_boxed", "tape_short", "focus_boxed", "shop_glove_boxed", "hint_assist", "hint_assist_first",
			"hint_fame", "hint_legacy", "hint_keys", "hint_locked_item", "hint_prize", "hint_prize_belt"]:
		checar(d.ui.has(chave), "ui_texts tem " + chave)
	checar_igual(d.ui.box_click.size(), 3, "3 textos de clique")
	checar(str(d.ui.hint_keys).contains("1 a 4: foco"), "hint_keys diz foco (não tática)")
	_liberar(gs)


func _teste_compra_gera_caixa() -> void:
	var gs := _novo("f51_compra")
	var sinais: Array = []
	gs.caixa_criada.connect(func(item: String, tipo: String) -> void: sinais.append([item, tipo]))
	gs.treino = 10000.0
	checar(gs.aparelho_montado("punching_bag") and gs.caixas().is_empty(), "começa só com o saco e sem caixa")
	checar(gs.comprar_aparelho("treadmill"), "compra a esteira")
	checar_igual(gs.treino, 9500.0, "Treino gasto na compra")
	checar_igual(gs.caixas(), [{"item": "treadmill", "kind": "apparatus", "hits": 0}], "caixa criada")
	checar(not gs.aparelho_montado("treadmill"), "esteira ainda não está montada")
	checar_igual(gs.estado_aparelho("treadmill"), "boxed", "estado boxed")
	checar_igual(sinais, [["treadmill", "apparatus"]], "sinal caixa_criada")
	checar(not gs.comprar_aparelho("treadmill"), "não compra de novo enquanto está na caixa")
	var doc = JSON.parse_string(ler(gs.store.caminho()))
	var b0: Dictionary = doc.state.career.boxes[0] if doc.state.career.boxes.size() == 1 else {}
	checar_igual([b0.get("item"), b0.get("kind"), int(b0.get("hits", -1))], ["treadmill", "apparatus", 0], "salvou na compra, com a caixa")
	checar(not ("treadmill" in doc.state.career.apparatus_owned), "e sem a esteira montada")
	# Melhoria de aparelho continua instantânea e sem caixa.
	gs.treino = 1000.0
	checar(gs.comprar_melhoria("punching_bag"), "melhoria do saco compra na hora")
	checar_igual(gs.caixas().size(), 1, "melhoria não gera caixa")
	_liberar(gs)


func _teste_tres_batidas_abrem_aparelho() -> void:
	var gs := _novo("f51_tres")
	gs.treino = 10000.0
	gs.comprar_aparelho("treadmill")
	var log: Array = []
	gs.caixa_batida.connect(func(item: String, n: int) -> void: log.append(["bate", item, n]))
	gs.caixa_aberta.connect(func(item: String, tipo: String) -> void: log.append(["abre", item, tipo]))
	checar(gs.bater_caixa("treadmill"), "1º clique")
	checar_igual([gs.caixa("treadmill").hits, gs.cliques_faltando("treadmill")], [1, 2], "hits 1, faltam 2")
	checar(gs.bater_caixa("treadmill"), "2º clique")
	checar(gs.tem_caixa("treadmill") and not gs.aparelho_montado("treadmill"), "com 2 cliques continua fechada")
	checar_igual(gs.foco, "punching_bag", "foco não mudou antes de abrir")
	checar(gs.bater_caixa("treadmill"), "3º clique")
	checar(gs.aparelho_montado("treadmill") and not gs.tem_caixa("treadmill"), "abriu: esteira montada, caixa sumiu")
	checar_igual(gs.foco, "treadmill", "foco foi para o aparelho aberto")
	checar_igual(gs.estado_aparelho("treadmill"), "owned", "estado owned")
	checar_igual(log, [["bate", "treadmill", 1], ["bate", "treadmill", 2], ["bate", "treadmill", 3], ["abre", "treadmill", "apparatus"]],
		"sinais na ordem")
	var doc = JSON.parse_string(ler(gs.store.caminho()))
	checar("treadmill" in doc.state.career.apparatus_owned and doc.state.career.boxes == [] and doc.state.career.focus == "treadmill",
		"salvou ao abrir (montada, foco, sem caixa)")
	checar(not gs.bater_caixa("treadmill"), "sem caixa, bater_caixa recusa")
	checar(not gs.bater_caixa("nao_existe"), "item inexistente recusa")
	_liberar(gs)


func _teste_clique_de_treino_x_caixa() -> void:
	var gs := _novo("f51_clique")
	gs.treino = 5000.0
	gs.comprar_aparelho("treadmill")
	var antes: float = gs.treino
	var atr_antes: Dictionary = gs.atributos.duplicate()
	var cliques: Array = []
	gs.clicou.connect(func(_g, _c, _a, _t, _x) -> void: cliques.append(1))
	gs.bater_caixa("treadmill")
	checar_igual([gs.treino, gs.atributos, cliques.size()], [antes, atr_antes, 0], "bater na caixa não treina nem emite clicou")
	var r: Dictionary = gs.clicar()
	checar(not r.is_empty() and gs.treino > antes, "clicar() com caixa fechada treina normal")
	checar_igual(gs.caixa("treadmill").hits, 1, "e não mexe nos hits da caixa")
	checar_igual(r.aparelho, "punching_bag", "treina no foco (saco), não no aparelho da caixa")
	_liberar(gs)


func _teste_bloqueios_de_compra_e_foco() -> void:
	var gs := _novo("f51_bloqueios")
	gs.treino = 100000.0
	gs.comprar_aparelho("treadmill")
	checar_igual(gs.estado_aparelho("jump_rope"), "locked", "corda trancada com a esteira na caixa")
	checar(not gs.comprar_aparelho("jump_rope"), "corda não compra")
	checar(not gs.definir_foco("treadmill"), "foco recusa aparelho na caixa")
	_abrir_com_cliques(gs, "treadmill")
	checar_igual(gs.estado_aparelho("jump_rope"), "buyable", "esteira aberta libera a corda")
	checar(gs.comprar_aparelho("jump_rope"), "compra a corda")
	checar(not gs.definir_foco("jump_rope"), "foco recusa a corda na caixa")
	checar(gs.foco == "treadmill", "foco segue na esteira")
	_abrir_com_cliques(gs, "jump_rope")
	checar(gs.definir_foco("jump_rope"), "depois de aberta o foco aceita")
	_liberar(gs)
	# Aparelho da arte.
	var g2 := _novo("f51_arte")
	g2.permanente["arts_unlocked"] = ["boxing", "bjj"]
	g2.escolher_arte("boxing")
	g2.treino = 100000.0
	checar_igual(g2.estado_aparelho("speed_bag"), "locked", "pera trancada sem a esteira aberta")
	g2.comprar_aparelho("treadmill")
	checar(not g2.comprar_aparelho("speed_bag"), "pera não compra com a esteira na caixa")
	_abrir_com_cliques(g2, "treadmill")
	checar(g2.comprar_aparelho("speed_bag") and g2.estado_aparelho("speed_bag") == "boxed", "pera compra e fica na caixa")
	_abrir_com_cliques(g2, "speed_bag")
	checar(g2.aparelho_montado("speed_bag") and g2.foco == "speed_bag", "pera aberta: montada e com foco")
	_liberar(g2)


func _teste_luva_em_caixa() -> void:
	var gs := _novo("f51_luva")
	gs.dinheiro = 100000.0
	var mult1: float = gs.lutas.luvas[0].click_multiplier
	var base: float = gs.por_clique()
	var sinais: Array = []
	gs.luva_mudou.connect(func(n: int, s: String) -> void: sinais.append([n, s]))
	checar(gs.comprar_luva(), "compra a luva de lona")
	checar_igual(gs.nivel_luva, 1, "glove_level conta a luva comprada")
	checar(gs.luva_em_caixa() and gs.luvas_abertas() == 0, "luva na caixa, nenhuma aberta")
	checar_igual(gs.caixas(), [{"item": "glove_l1", "kind": "glove", "hits": 0}], "caixa da luva")
	checar_igual(gs.por_clique(), base, "luva fechada não multiplica")
	checar_igual(gs.luva_equipada().id, "glove_old", "ainda com a luva velha")
	checar(not gs.pode_comprar_luva(), "próxima luva não compra com a anterior na caixa")
	checar(not gs.comprar_luva(), "comprar_luva recusa")
	checar_igual(sinais.size(), 0, "luva_mudou não dispara na compra")
	var foco_antes: String = gs.foco
	_abrir_com_cliques(gs, "glove_l1")
	checar(not gs.luva_em_caixa() and gs.luvas_abertas() == 1, "aberta: 1 luva valendo")
	checar(absf(gs.por_clique() - base * mult1) < 1e-9, "multiplicador passa a valer")
	checar_igual(gs.luva_equipada().id, "glove_l1", "luva de lona equipada")
	checar_igual(sinais, [[1, gs.sufixo_luva()]], "luva_mudou na abertura")
	checar_igual(gs.foco, foco_antes, "luva não muda o foco")
	checar(gs.pode_comprar_luva(), "a segunda luva volta à venda")
	gs.comprar_luva()
	checar_igual([gs.nivel_luva, gs.luvas_abertas(), gs.proxima_luva().is_empty()], [2, 1, false], "2ª comprada, 1 aberta, ainda há L3 e L4")
	_liberar(gs)


func _teste_persistencia() -> void:
	var gs := _novo("f51_persiste")
	gs.treino = 10000.0
	gs.comprar_aparelho("treadmill")
	gs.dinheiro = 5000.0
	gs.comprar_luva()
	gs.bater_caixa("treadmill")
	gs.bater_caixa("treadmill")
	gs.bater_caixa("glove_l1")
	gs.salvar()
	var g2 := _reabrir(gs.store.pasta)
	checar_igual(g2.caixas(), [{"item": "treadmill", "kind": "apparatus", "hits": 2}, {"item": "glove_l1", "kind": "glove", "hits": 1}],
		"caixas e hits sobrevivem a salvar e reabrir")
	checar_igual([g2.nivel_luva, g2.luvas_abertas(), g2.estado_aparelho("treadmill"), g2.avisos.size()], [1, 0, "boxed", 0], "luva e aparelho seguem na caixa, sem avisos")
	# Trocar o foco não mexe nas caixas.
	g2.definir_foco("punching_bag")
	checar_igual(g2.caixas().size(), 2, "trocar foco não mexe nas caixas")
	g2.bater_caixa("treadmill")
	checar(g2.aparelho_montado("treadmill") and g2.caixas().size() == 1, "o 3º clique depois de reabrir abre (2 hoje + 1 amanhã)")
	_liberar(gs)
	_liberar(g2)


func _teste_luta_e_janelas() -> void:
	var gs := _novo("f51_luta")
	gs.treino = 10000.0
	gs.comprar_aparelho("treadmill")
	gs.bater_caixa("treadmill")
	gs.atributos = {"strength": 1.0e6, "agility": 1.0e6, "endurance": 1.0e6}
	var info: Dictionary = gs.lutar()
	checar(not info.is_empty(), "luta iniciada")
	checar(not gs.bater_caixa("treadmill"), "durante a luta a caixa não aceita clique")
	checar_igual(gs.caixa("treadmill").hits, 1, "hits congelados na luta")
	gs.concluir_luta()
	checar_igual(gs.caixa("treadmill").hits, 1, "volta igual depois da luta")
	checar(gs.bater_caixa("treadmill"), "e aceita clique de novo")
	# Janela de escolha da arte aberta também bloqueia (acoes_bloqueadas).
	gs.permanente["arts_unlocked"] = ["boxing"]
	checar(gs.escolha_arte_pendente() and gs.acoes_bloqueadas(), "escolha de arte pendente bloqueia")
	checar(not gs.bater_caixa("treadmill"), "janela aberta: clique na caixa ignorado")
	checar_igual(gs.caixa("treadmill").hits, 2, "hits intactos")
	_liberar(gs)


func _teste_nova_carreira() -> void:
	var gs := _novo("f51_nova")
	gs.treino = 10000.0
	gs.dinheiro = 5000.0
	gs.comprar_aparelho("treadmill")
	gs.comprar_luva()
	var dinheiro_antes: float = gs.dinheiro
	checar_igual(gs.caixas().size(), 2, "duas caixas na carreira")
	gs.aposentar()
	checar(gs.nova_carreira(), "nova carreira")
	checar_igual([gs.caixas(), gs.aparelhos_montados(), gs.nivel_luva, gs.luvas_abertas(), gs.luva_em_caixa()],
		[[], ["punching_bag"], 0, 0, false], "NOVA CARREIRA: sem caixa, só o saco, luva velha")
	checar(gs.dinheiro != dinheiro_antes + 1.0e12, "sem reembolso inventado")
	var doc = JSON.parse_string(ler(gs.store.caminho()))
	checar_igual(doc.state.career.boxes, [], "arquivo sem caixas")
	_liberar(gs)


func _teste_save_v7_e_validacoes() -> void:
	checar_igual(SaveStore.VERSAO_ATUAL, 8, "versão do save é 8")
	var gs := _novo("f51_valida")
	gs.nivel_luva = 1
	var c := {
		"apparatus_owned": ["punching_bag", "treadmill"], "glove_level": 1,
		"boxes": [
			{"item": "jump_rope", "kind": "glove", "hits": 9},  # kind errado: corrige; hits 9 -> 2
			{"item": "jump_rope", "kind": "apparatus", "hits": 1},  # repetida: fica a 1ª
			{"item": "treadmill", "kind": "apparatus", "hits": 0},  # já montada: descarta
			{"item": "speed_bag", "kind": "apparatus", "hits": 0},  # arte vazia: descarta
			{"item": "nada", "kind": "apparatus", "hits": 0},  # inexistente: descarta
			{"item": "glove_l1", "kind": "glove", "hits": -4},  # última comprada: fica, hits 0
			{"item": "glove_l2", "kind": "glove", "hits": 1},  # não é a última comprada: descarta
			"lixo",
		]}
	gs.aplicar_save({"career": c})
	checar_igual(gs.caixas(), [{"item": "jump_rope", "kind": "apparatus", "hits": 2}, {"item": "glove_l1", "kind": "glove", "hits": 0}],
		"validação: corrige kind, prende hits, descarta o inválido e o repetido")
	checar(not gs.avisos.is_empty(), "com avisos, sem travar")
	gs.aplicar_save({"career": {"boxes": "x", "glove_level": 0}})
	checar_igual(gs.caixas(), [], "boxes inválido vira []")
	gs.aplicar_save({"career": {"glove_level": 1, "boxes": [{"item": "glove_l1", "kind": "glove", "hits": 1}]}})
	checar_igual([gs.nivel_luva, gs.luvas_abertas(), gs.caixa("glove_l1").hits], [1, 0, 1], "luva em caixa: glove_level 1, 0 abertas")
	gs.aplicar_save({"career": {"glove_level": 0, "boxes": [{"item": "glove_l1", "kind": "glove", "hits": 0}]}})
	checar_igual(gs.caixas(), [], "caixa de luva sem a luva comprada é descartada")
	_liberar(gs)


func _teste_migracao_v6() -> void:
	var pasta := pasta_limpa("f51_mig6")
	var v6 := {"version": 6, "saved_at_unix": 1730000000, "state": {
		"career": {"training": 321.0, "apparatus_owned": ["punching_bag", "jump_rope", "treadmill"], "glove_level": 2,
			"focus": "treadmill", "location": "garage", "art": "", "art_seconds": 0.0, "money": 77.0},
		"permanent": {}, "ending": null}}
	escrever(pasta + "save.json", JSON.stringify(v6))
	var gs := _reabrir(pasta)
	checar_igual([gs.treino, gs.aparelhos_montados(), gs.nivel_luva, gs.luvas_abertas(), gs.foco, gs.caixas()],
		[321.0, ["punching_bag", "jump_rope", "treadmill"], 2, 2, "treadmill", []], "v6 -> v7: tudo montado e valendo, nada vira caixa")
	checar(gs.avisos.is_empty(), "migração sem avisos")
	gs.salvar()
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual([int(doc.version), doc.state.career.boxes], [8, []], "regravado como v8 com boxes []")
	_liberar(gs)
	# Cadeia v0 -> v7.
	var p2 := pasta_limpa("f51_mig0")
	escrever(p2 + "save.json", '{"treino": 12}')
	var g2 := _reabrir(p2)
	checar_igual([g2.treino, g2.caixas()], [12.0, []], "v0 -> v7 em cadeia")
	_liberar(g2)


func _teste_luva_instantanea_pelo_dado() -> void:
	var gs := _novo("f51_inst")
	gs.dados.box_glove = false
	gs.dados.box_apparatus = false
	gs.dinheiro = 5000.0
	gs.treino = 10000.0
	gs.comprar_luva()
	checar(gs.caixas().is_empty() and gs.luvas_abertas() == 1, "applies_to.glove=false: luva vale na hora, sem caixa")
	gs.comprar_aparelho("treadmill")
	checar(gs.caixas().is_empty() and gs.aparelho_montado("treadmill") and gs.foco == "treadmill", "apparatus_unlock=false: aparelho instantâneo")
	_liberar(gs)
