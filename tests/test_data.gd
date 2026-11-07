extends "res://tests/test_base.gd"
## Testa o carregador de dados da garagem (data/*.json): valores reais, padrões e arquivos inválidos.

const GameStateScript := preload("res://scripts/game_state.gd")


func rodar_testes() -> void:
	_teste_dados_reais()
	_teste_arquivos_ausentes_ou_ruins()
	_teste_campos_invalidos()
	_teste_preco_muda_sem_codigo()
	_teste_crit_chance_muda_frequencia()


func _teste_dados_reais() -> void:
	var d := TrainingData.carregar()
	checar_igual(d.base_training, 1.0, "base_training = 1")
	checar_igual(d.crit_chance, 0.10, "crit_chance = 0.10")
	checar_igual(d.crit_multiplier, 3.0, "crit_multiplier = 3")
	checar_igual(d.default_focus, "punching_bag", "foco inicial")
	checar_igual(d.aparelhos.size(), 3, "3 aparelhos")
	checar_igual(d.aparelhos[0].id, "punching_bag", "ordem: saco primeiro")
	checar_igual(d.aparelho("jump_rope").attribute, "agility", "corda = agilidade")
	checar_igual(d.aparelho("treadmill").attribute, "endurance", "esteira = resistência")
	for a in d.aparelhos:
		checar_igual(a.upgrades.size(), 2, "%s tem 2 níveis" % a.id)
		checar_igual(a.upgrades[0].cost, 300.0, "%s nível 1 custa 300" % a.id)
		checar_igual(a.upgrades[0].multiplier, 3.0, "%s nível 1 x3" % a.id)
		checar_igual(a.upgrades[1].cost, 5000.0, "%s nível 2 custa 5000" % a.id)
		checar_igual(a.upgrades[1].multiplier, 5.0, "%s nível 2 x5" % a.id)
		checar_igual(a.upgrades[0].visual_level, 1, "%s nível 1 troca o sprite" % a.id)
		checar(a.crit_texts.size() == 5 and a.name != a.id and a.first_hint != "", "%s tem textos" % a.id)
		checar(a.upgrades[0].name != a.upgrades[0].id and a.upgrades[0].description != "", "%s: melhoria com texto" % a.id)
	checar_igual(d.geradores.size(), 2, "2 geradores")
	checar_igual(d.gerador("neighbor_kid").base_cost, 60.0, "vizinho 60")
	checar_igual(d.gerador("neighbor_kid").growth, 1.25, "vizinho x1.25")
	checar_igual(d.gerador("neighbor_kid").production, 1.0, "vizinho +1/s")
	checar_igual(d.gerador("neighbor_kid").draw_thresholds, [1, 10, 25], "vizinho: pessoas em 1, 10, 25")
	checar_igual(d.gerador("retired_uncle").base_cost, 2500.0, "tio 2500")
	checar_igual(d.gerador("retired_uncle").production, 8.0, "tio +8/s")
	checar_igual(d.gerador("retired_uncle").draw_thresholds, [1, 10], "tio: pessoas em 1, 10")
	checar_igual(d.gerador("neighbor_kid").name, "Vizinho da casa 12", "nome do vizinho")
	checar_igual(d.atributo_info("strength").name, "Força", "nome do atributo")
	checar(d.atributo_info("agility").hint != "", "dica do atributo")
	checar(d.ui.has("buy_generator") and d.ui.has("maxed") and d.ui.has("upgrade_effect"), "textos de interface")


func _teste_arquivos_ausentes_ou_ruins() -> void:
	var pasta := pasta_limpa("dados_ruins")
	var d := TrainingData.carregar(pasta + "nao_existe.json", pasta + "nao_existe2.json", pasta + "nao_existe3.json")
	checar_igual(d.aparelhos.size(), 3, "arquivo ausente: aparelhos padrão")
	checar_igual(d.geradores.size(), 2, "arquivo ausente: geradores padrão")
	checar_igual(d.gerador("neighbor_kid").base_cost, 60.0, "arquivo ausente: custo padrão")
	checar_igual(d.default_focus, "punching_bag", "arquivo ausente: foco padrão")
	escrever(pasta + "lixo.json", "{isso não é json")
	var d2 := TrainingData.carregar(pasta + "lixo.json", pasta + "lixo.json", pasta + "lixo.json")
	checar_igual(d2.aparelhos.size(), 3, "JSON inválido: aparelhos padrão")
	checar_igual(d2.geradores.size(), 2, "JSON inválido: geradores padrão")


func _teste_campos_invalidos() -> void:
	var pasta := pasta_limpa("dados_campos")
	escrever(pasta + "t.json", JSON.stringify({
		"click": {"base_training": -3, "crit_chance": 7, "crit_multiplier": "x", "campo_novo": 1},
		"default_focus": "nada",
		"apparatus": [
			{"id": "punching_bag", "attribute": "strength", "upgrades": [
				{"id": "bag_patch", "cost": "caro", "multiplier": 0.5, "visual_level": 9},
				{"id": "bag_patch", "cost": 10, "multiplier": 2}]},
			{"id": "", "attribute": "strength"},
			{"id": "punching_bag", "attribute": "strength"},
			{"id": "sem_atributo", "attribute": "magia"},
			{"id": "jump_rope", "attribute": "agility"},
		]}))
	escrever(pasta + "g.json", JSON.stringify({"generators": [
		{"id": "neighbor_kid", "base_cost": -1, "growth": 0.5, "production": "x", "draw_thresholds": [10, 5]},
		{"id": "neighbor_kid", "base_cost": 5},
		{"id": "", "base_cost": 5},
		{"id": "tio_novo", "base_cost": 100, "growth": 2, "production": 3, "draw_thresholds": [2, 4]},
	]}))
	var d := TrainingData.carregar(pasta + "t.json", pasta + "g.json", pasta + "nada.json")
	checar_igual(d.base_training, 1.0, "base_training inválido usa o padrão")
	checar_igual(d.crit_chance, 0.10, "crit_chance fora da faixa usa o padrão")
	checar_igual(d.crit_multiplier, 3.0, "crit_multiplier inválido usa o padrão")
	checar_igual(d.default_focus, "punching_bag", "default_focus inexistente usa o padrão")
	checar_igual(d.aparelhos.size(), 2, "ids vazios, repetidos e atributo inválido ignorados")
	var saco := d.aparelho("punching_bag")
	checar_igual(saco.upgrades.size(), 1, "melhoria repetida ignorada")
	checar_igual(saco.upgrades[0].cost, 300.0, "cost inválido usa o padrão do design")
	checar_igual(saco.upgrades[0].multiplier, 3.0, "multiplier < 1 usa o padrão do design")
	checar_igual(saco.upgrades[0].visual_level, 0, "visual_level inválido usa 0")
	checar_igual(d.geradores.size(), 2, "gerador repetido e id vazio ignorados")
	var viz := d.gerador("neighbor_kid")
	checar_igual(viz.base_cost, 60.0, "base_cost negativo usa o padrão")
	checar_igual(viz.growth, 1.25, "growth < 1 usa o padrão")
	checar_igual(viz.production, 1.0, "production inválida usa o padrão")
	checar_igual(viz.draw_thresholds, [1], "draw_thresholds não crescente vira [1]")
	checar_igual(d.gerador("tio_novo").draw_thresholds, [2, 4], "draw_thresholds válido é mantido")


# Critério 20: mudar base_cost em data/ muda o preço sem tocar no código.
func _teste_preco_muda_sem_codigo() -> void:
	var pasta := pasta_limpa("dados_preco")
	escrever(pasta + "g.json", JSON.stringify({"generators": [
		{"id": "neighbor_kid", "base_cost": 100, "growth": 1.25, "production": 1}]}))
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta + "save/", "res://data/config.json", "res://data/training.json", pasta + "g.json")
	checar_igual(gs.custo_gerador("neighbor_kid"), 100.0, "base_cost 100 muda o 1º preço")
	gs.geradores["neighbor_kid"] = 1
	checar_igual(gs.custo_gerador("neighbor_kid"), 125.0, "2º preço = 100 x 1.25")
	gs.free()


# Critério 11: mudar a chance em data/ muda a frequência.
func _teste_crit_chance_muda_frequencia() -> void:
	var pasta := pasta_limpa("dados_crit")
	escrever(pasta + "t.json", JSON.stringify({"click": {"base_training": 1, "crit_chance": 0.5, "crit_multiplier": 2}}))
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta + "save/", "res://data/config.json", pasta + "t.json")
	gs.autosave_ativo = false
	gs.rng.seed = 99
	var criticos := 0
	for i in 2000:
		var r: Dictionary = gs.clicar()
		if r.critico:
			criticos += 1
			if r.ganho != 2.0:
				criticos -= 10000
	checar(criticos > 900 and criticos < 1100, "chance 50%% -> %d críticos em 2000" % criticos)
	gs.free()
