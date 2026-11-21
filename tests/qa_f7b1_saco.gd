extends "res://tests/test_base.gd"
## QA 7b1: saco de chute (compra com Treino, caixa, divisão 50/35/15, melhorias, só para o Muay Thai).
const GS := preload("res://scripts/game_state.gd")

func _novo(nome: String, arte: String) -> Node:
	var gs: Node = GS.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	gs.escolher_arte(arte)
	return gs

func rodar_testes() -> void:
	var gs := _novo("qa7b1_saco_a", "muay_thai")
	gs.treino = 0.0
	checar(not gs.comprar_aparelho("kick_bag"), "sem Treino: recusa")
	gs.treino = 1.0e9
	checar(not gs.comprar_aparelho("kick_bag"), "sem a esteira: recusa (requires treadmill)")
	checar(gs.comprar_aparelho("treadmill"), "compra a esteira")
	print("   caixas: ", gs.caixas())
	for c in gs.caixas():
		gs.abrir_caixa(str(c.item))
	checar(gs.aparelho_montado("treadmill"), "esteira montada depois de abrir a caixa")
	var antes: float = gs.treino
	checar(gs.comprar_aparelho("kick_bag"), "compra o saco de chute (2.500)")
	checar(is_equal_approx(antes - gs.treino, 2500.0), "custou 2.500 (gastou %s)" % str(antes - gs.treino))
	checar(not gs.aparelho_montado("kick_bag"), "chega em CAIXA: ainda não montado")
	checar(not gs.caixa("kick_bag").is_empty(), "caixa do saco de chute existe")
	checar(not gs.comprar_aparelho("kick_bag"), "comprar de novo com a caixa fechada: recusa")
	gs.definir_foco("kick_bag")
	checar(gs.foco != "kick_bag", "não dá para focar no saco antes de abrir a caixa (foco=%s)" % gs.foco)
	checar(gs.abrir_caixa("kick_bag"), "abre a caixa")
	checar(gs.aparelho_montado("kick_bag"), "montado")
	checar(not gs.comprar_aparelho("kick_bag"), "comprar de novo depois de montado: recusa")
	gs.definir_foco("kick_bag")
	checar_igual(gs.foco, "kick_bag", "foco no saco de chute")
	var a0 := {"s": gs.atributos.strength, "a": gs.atributos.agility, "e": gs.atributos.endurance}
	gs.tick(10.0)
	for i in 300:
		gs.clicar()
	var ds: float = gs.atributos.strength - a0.s
	var da: float = gs.atributos.agility - a0.a
	var de: float = gs.atributos.endurance - a0.e
	var tot: float = ds + da + de
	print("   divisão obtida: FOR %.3f AGI %.3f RES %.3f (esperado 0,50/0,35/0,15)" % [ds / tot, da / tot, de / tot])
	checar(tot > 0.0 and absf(ds / tot - 0.5) < 0.02 and absf(da / tot - 0.35) < 0.02 and absf(de / tot - 0.15) < 0.02, "divisão de atributos 50/35/15 com o foco no saco")
	# melhorias
	gs.treino = 1.0e12
	var n := 0
	for i in 6:
		if gs.comprar_melhoria("kick_bag"):
			n += 1
	checar_igual(n, 4, "4 melhorias do saco (tech_mt_1..4) e não mais")
	# valores absurdos
	gs.treino = -50.0
	checar(not gs.comprar_aparelho("kick_bag"), "Treino negativo: recusa")
	# Boxe não vê o saco de chute; Jiu-jitsu também não
	for arte in ["boxing", "bjj"]:
		var gb := _novo("qa7b1_saco_" + arte, arte)
		gb.treino = 1.0e12
		gb.comprar_aparelho("treadmill")
		for c in gb.caixas():
			gb.abrir_caixa(str(c.item))
		var ids: Array = []
		for ap in gb.aparelhos_da_carreira():
			ids.append(ap.id)
		checar(not ids.has("kick_bag") and not gb.comprar_aparelho("kick_bag"), "%s não vê nem compra o saco de chute" % arte)
		gb.definir_foco("kick_bag")
		checar(gb.foco != "kick_bag", "%s: foco forçado em kick_bag é recusado" % arte)
		gb.aguardar_motivo()
		gb.free()
	# Muay Thai não vê pera nem boneco
	var ids2: Array = []
	for ap in gs.aparelhos_da_carreira():
		ids2.append(ap.id)
	checar(not ids2.has("speed_bag") and not ids2.has("grappling_dummy") and ids2.has("kick_bag"), "Muay Thai vê o saco de chute e não vê pera/boneco: %s" % str(ids2))
	gs.aguardar_motivo()
	gs.free()
