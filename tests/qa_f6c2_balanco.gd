extends "res://tests/test_base.gd"
## QA 6c2: resumo deterministico da economia (hall vazio, sem retratos). Rodado na arvore da 6c2 e na do origin/main para comparar.
const GameStateScript := preload("res://scripts/game_state.gd")
const IGNORAR := ["missing_line", "honor", "wins"]

func _limpo(d: Dictionary) -> Dictionary:
	var r := {}
	for k in d:
		if not (k in IGNORAR):
			r[k] = d[k]
	return r

func rodar_testes() -> void:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa("qa_bal"), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	var t := 0.0
	for i in 18000:
		gs.tick(0.1)
		t += 0.1
		if i % 2 == 0:
			gs.clicar()
		if i % 100 == 0:
			for g in gs.dados.geradores:
				gs.comprar_gerador(str(g.id))
			for ap in gs.dados.todos_aparelhos():
				gs.comprar_aparelho(str(ap.id)) if gs.has_method("comprar_aparelho") else null
				gs.comprar_melhoria(str(ap.id)) if gs.has_method("comprar_melhoria") else null
		if i % 3000 == 0 or i == 17999:
			print("T=%d treino=%.6f dinheiro=%.6f clique=%.9f prod=%.9f equipe=%.9f" % [int(t), gs.treino, gs.dinheiro, gs.por_clique(), gs.producao_total(), gs._fator_equipe()])
	for idx in 4:
		gs.indice_escada = idx
		gs.atributos = {"strength": 30.0 * (idx + 1), "agility": 20.0 * (idx + 1), "endurance": 25.0 * (idx + 1)}
		gs.aguardar_motivo()
		print("previa ", idx, " ", JSON.stringify(_limpo(gs.previa())))
	gs.fama = 4321
	gs.indice_escada = 4
	gs.cinturao = true
	print("aposentar ", JSON.stringify(_limpo(gs.previa_aposentar())))
	print("derrota ", gs.legado_se_perder(), " pote ", gs.legado_em_jogo())
	gs.aguardar_motivo()
	gs.free()
