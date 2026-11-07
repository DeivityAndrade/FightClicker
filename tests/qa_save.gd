extends SceneTree
## QA Fase 2: saves estranhos (so em user://test/qa_save/...). Nunca toca o save real.

var gs: Node


func p(s: String) -> void:
	print("QA| ", s)


func escrever(pasta: String, texto: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pasta))
	var f := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func carregar(nome: String, texto: String) -> void:
	var pasta := "user://test/qa_save/%s/" % nome
	for f in ["save.json", "save.json.bak"]:
		if FileAccess.file_exists(pasta + f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(pasta + f))
	escrever(pasta, texto)
	gs.inicializar(pasta, "res://data/config.json")
	p("%-22s treino=%s atr=%s foco=%s ger=%s niv=%s avisos=%s" % [nome, gs.treino, gs.atributos, gs.foco, gs.geradores, gs.niveis_melhoria, gs.avisos])


func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	carregar("v1_500", '{"version":1,"saved_at_unix":1730000000,"state":{"treino":500}}')
	carregar("v1_neg", '{"version":1,"saved_at_unix":1,"state":{"treino":-50}}')
	carregar("v1_texto", '{"version":1,"saved_at_unix":1,"state":{"treino":"abc"}}')
	carregar("v1_enorme", '{"version":1,"saved_at_unix":1,"state":{"treino":1e308}}')
	carregar("v1_sem_state", '{"version":1,"saved_at_unix":1}')
	carregar("v0", '{"treino":42}')
	carregar("lixo", "{{{ nao eh json")
	carregar("vazio", "")
	carregar("array", "[1,2,3]")
	carregar("v2_campos_ruins", '{"version":2,"saved_at_unix":1,"state":{"career":{"training":-5,"attributes":{"strength":"x","agility":-3,"endurance":7.5,"magia":9},"focus":"xxx","generators":{"neighbor_kid":-4,"retired_uncle":3.7,"fantasma":9},"upgrades":{"punching_bag":9,"jump_rope":-1,"treadmill":"a"}}}}')
	carregar("v2_sem_career", '{"version":2,"saved_at_unix":1,"state":{}}')
	carregar("v2_career_lista", '{"version":2,"saved_at_unix":1,"state":{"career":[1,2]}}')
	carregar("v2_bom", '{"version":2,"saved_at_unix":1,"state":{"career":{"training":1234.5,"attributes":{"strength":900,"agility":200,"endurance":134.5},"focus":"treadmill","generators":{"neighbor_kid":12,"retired_uncle":3},"upgrades":{"punching_bag":2,"jump_rope":0,"treadmill":1}}}}')
	p("  por_clique=%s producao=%s custo viz=%s custo tio=%s nivel_visual saco=%s" % [gs.por_clique(), gs.producao_total(), gs.custo_gerador("neighbor_kid"), gs.custo_gerador("retired_uncle"), gs.nivel_visual("punching_bag")])
	carregar("v2_futuro", '{"version":9,"saved_at_unix":1,"state":{"career":{"training":5}}}')
	# save corrompido com .bak bom
	var pasta := "user://test/qa_save/bak_bom/"
	escrever(pasta, '{"version":2,"saved_at_unix":1,"state":{"career":{"training":77}}}')
	var f := FileAccess.open(pasta + "save.json.bak", FileAccess.WRITE)
	f.store_string('{"version":2,"saved_at_unix":1,"state":{"career":{"training":77}}}')
	f.close()
	var g := FileAccess.open(pasta + "save.json", FileAccess.WRITE)
	g.store_string("corrompido!!")
	g.close()
	gs.inicializar(pasta, "res://data/config.json")
	p("bak_bom: treino=%s avisos=%s" % [gs.treino, gs.avisos])
	# NaN / inf vindo de dentro do jogo: salvar e recarregar
	gs.inicializar("user://test/qa_save/nan/", "res://data/config.json")
	gs.treino = 1e308
	gs.atributos["strength"] = 1e308
	gs.tick(1000.0)
	p("tick enorme: treino=%s finito=%s" % [gs.treino, is_finite(gs.treino)])
	gs.salvar()
	gs.inicializar("user://test/qa_save/nan/", "res://data/config.json")
	p("recarregado: treino=%s finito=%s" % [gs.treino, is_finite(gs.treino)])
	# passo de tempo ruim
	gs.treino = 5.0
	gs.tick(NAN)
	gs.tick(INF)
	gs.tick(-1.0)
	p("tick NaN/Inf/neg: treino=%s" % gs.treino)
	# 1000 compras seguidas
	gs.inicializar("user://test/qa_save/compras/", "res://data/config.json")
	gs.apagar_save()
	gs.treino = 1e18
	var n := 0
	for i in 1000:
		if gs.comprar_gerador("neighbor_kid"):
			n += 1
	p("1000 tentativas com 1e18: compradas=%d saldo=%s" % [n, gs.treino])
	# invariante: soma atributos == ganho ; saldo >= 0
	gs.apagar_save()
	gs.inicializar("user://test/qa_save/inv/", "res://data/config.json")
	gs.apagar_save()
	var ganho_total := 0.0
	var gasto := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 20000:
		var r := rng.randi() % 10
		if r < 6:
			ganho_total += gs.clicar().ganho
		elif r == 6:
			var cg: float = gs.custo_gerador("neighbor_kid")
			if gs.comprar_gerador("neighbor_kid"):
				gasto += cg
		elif r == 7:
			var m: Dictionary = gs.proxima_melhoria(gs.foco)
			if not m.is_empty():
				var c: float = m.cost
				if gs.comprar_melhoria(gs.foco):
					gasto += c
		elif r == 8:
			gs.definir_foco(["punching_bag", "jump_rope", "treadmill"][rng.randi() % 3])
		else:
			var antes: float = gs.treino
			gs.tick(0.1)
			ganho_total += gs.treino - antes
	var soma_attr := 0.0
	for a in gs.atributos:
		soma_attr += gs.atributos[a]
	p("invariante: soma atributos=%s ganho_total=%s saldo=%s ganho-gasto=%s saldo>=0=%s" % [soma_attr, ganho_total, gs.treino, ganho_total - gasto, gs.treino >= 0.0])
	quit(0)
