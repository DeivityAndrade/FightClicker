extends "res://tests/test_base.gd"
## Testa a carreira da Fase 2: custos, compra, clique, crítico, melhorias, passivo e invariantes.
## Usa pastas em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.aparelhos_montados_ids = ["punching_bag", "jump_rope", "treadmill"]  # Fase 4b: os testes antigos usam os 3
	return gs


func rodar_testes() -> void:
	_teste_teto3()
	_teste_custo_gerador()
	_teste_compra()
	_teste_gasto_nao_mexe_em_atributo()
	_teste_melhorias_e_multiplicadores()
	_teste_clique()
	_teste_critico_estatistico()
	_teste_passivo_vai_para_o_foco()
	_teste_fps()
	_teste_foco_e_sinais()
	_teste_pessoas_e_muitas_unidades()
	_teste_invariantes()
	_teste_save_ida_e_volta()
	_teste_save_invalido()
	_teste_debug()


func _aprox(a: float, b: float, rel: float) -> bool:
	return absf(a - b) <= rel * maxf(absf(a), absf(b))


func _soma_atributos(gs: Node) -> float:
	var s := 0.0
	for id in gs.atributos:
		s += gs.atributos[id]
	return s


func _teste_teto3() -> void:
	checar_igual(Economia.teto3(60.0), 60.0, "teto3(60) = 60")
	checar_igual(Economia.teto3(93.75), 94.0, "teto3(93.75) = 94")
	checar_igual(Economia.teto3(1364.24), 1370.0, "teto3(1364.24) = 1370")
	checar_igual(Economia.teto3(60.0000000001), 60.0, "teto3(60.0000000001) = 60")
	checar_igual(Economia.teto3(999.2), 1000.0, "teto3(999.2) = 1000")
	checar_igual(Economia.teto3(4163.3), 4170.0, "teto3(4163.3) = 4170")
	checar_igual(Economia.teto3(10000.0), 10000.0, "teto3(10000) = 10000")
	checar_igual(Economia.teto3(0.0), 0.0, "teto3(0) = 0")
	checar_igual(Economia.teto3(-5.0), 0.0, "teto3(negativo) = 0")


# Critério 18 / 20: custo(n) == teto3(base * growth^n) e tabela do design.
func _teste_custo_gerador() -> void:
	var gs := _novo("car_custo")
	var tabela_viz := {0: 60.0, 1: 75.0, 2: 94.0, 3: 118.0, 4: 147.0, 5: 184.0, 9: 448.0, 10: 559.0}
	for n in tabela_viz:
		gs.geradores["neighbor_kid"] = n
		checar_igual(gs.custo_gerador("neighbor_kid"), tabela_viz[n], "vizinho n=%d custa %s" % [n, tabela_viz[n]])
	var tabela_tio := {0: 2500.0, 1: 3130.0, 2: 3910.0, 3: 4890.0, 5: 7630.0}
	for n in tabela_tio:
		gs.geradores["retired_uncle"] = n
		checar_igual(gs.custo_gerador("retired_uncle"), tabela_tio[n], "tio n=%d custa %s" % [n, tabela_tio[n]])
	# Fórmula: igual a teto3(base * growth^n) e dentro de 1% do valor teórico.
	for n in [0, 1, 5, 20, 200]:
		gs.geradores["neighbor_kid"] = n
		var c: float = gs.custo_gerador("neighbor_kid")
		var teorico := 60.0 * pow(1.25, n)
		checar_igual(c, Economia.teto3(teorico), "custo(n=%d) == teto3(base*growth^n)" % n)
		checar(c >= teorico * (1.0 - 1e-9) and c <= teorico * 1.01 + 1.0, "custo(n=%d) ~ base*growth^n (+1%%)" % n)
	gs.geradores["neighbor_kid"] = 20
	checar(_aprox(gs.custo_gerador("neighbor_kid"), 5210.0, 0.001), "vizinho n=20 ~ 5.21K")
	gs.geradores["neighbor_kid"] = 200
	checar(_aprox(gs.custo_gerador("neighbor_kid"), 1.45e21, 0.01), "vizinho n=200 ~ 1.45e21")
	gs.free()


func _teste_compra() -> void:
	var gs := _novo("car_compra")
	# Sem saldo: recusa e nada muda.
	gs.treino = 59.0
	checar(not gs.pode_comprar_gerador("neighbor_kid"), "59 não paga o vizinho (60)")
	checar(not gs.comprar_gerador("neighbor_kid"), "compra sem saldo é recusada")
	checar_igual(gs.treino, 59.0, "recusa não mexe no saldo")
	checar_igual(gs.quantidade_gerador("neighbor_kid"), 0, "recusa não mexe na quantidade")
	# Tolerância de float.
	gs.treino = 59.99999999999
	checar(gs.comprar_gerador("neighbor_kid"), "59.99999999999 paga o item de 60 (tolerância)")
	checar_igual(gs.treino, 0.0, "saldo nunca fica negativo")
	checar_igual(gs.quantidade_gerador("neighbor_kid"), 1, "quantidade subiu")
	# Desconta o custo exato.
	gs.treino = 100.0
	checar(gs.comprar_gerador("neighbor_kid"), "compra a 2ª unidade")
	checar_igual(gs.treino, 25.0, "desconta o custo exato (100 - 75)")
	# Id inexistente.
	checar(not gs.comprar_gerador("nao_existe"), "gerador inexistente recusado")
	checar(not gs.comprar_melhoria("nao_existe"), "aparelho inexistente recusado")
	gs.free()


func _teste_gasto_nao_mexe_em_atributo() -> void:
	var gs := _novo("car_gasto")
	for i in 100:
		gs.clicar()
	var antes: Dictionary = gs.atributos.duplicate()
	gs.treino = 1.0e9
	for i in 10:
		gs.comprar_gerador("neighbor_kid")
	gs.comprar_gerador("retired_uncle")
	gs.comprar_melhoria("punching_bag")
	gs.comprar_melhoria("jump_rope")
	checar_igual(gs.atributos, antes, "atributos iguais antes e depois de várias compras")
	checar(gs.treino < 1.0e9, "as compras gastaram saldo")
	gs.free()


func _teste_melhorias_e_multiplicadores() -> void:
	var gs := _novo("car_melhorias")
	checar_igual(gs.multiplicador_aparelho("punching_bag"), 1.0, "sem melhoria: x1")
	checar_igual(gs.por_clique(), 1.0, "por clique inicial = 1")
	checar_igual(gs.nivel_visual("punching_bag"), 0, "sprite nível 0 no início")
	checar_igual(gs.proxima_melhoria("punching_bag").id, "bag_patch", "próxima do saco é bag_patch")
	gs.treino = 299.0
	checar(not gs.pode_comprar_melhoria("punching_bag"), "299 não paga bag_patch (300)")
	gs.treino = 300.0
	checar(gs.comprar_melhoria("punching_bag"), "compra bag_patch")
	checar_igual(gs.treino, 0.0, "bag_patch custou 300")
	checar_igual(gs.multiplicador_aparelho("punching_bag"), 3.0, "bag_patch: x3")
	checar_igual(gs.por_clique(), 3.0, "por clique = 3")
	checar_igual(gs.nivel_visual("punching_bag"), 1, "sprite nível 1 após a 1ª melhoria")
	checar_igual(gs.multiplicador_aparelho("jump_rope"), 1.0, "melhoria do saco não muda a corda")
	gs.definir_foco("jump_rope")
	checar_igual(gs.por_clique(), 1.0, "foco na corda: por clique 1")
	gs.definir_foco("punching_bag")
	gs.treino = 5000.0
	checar(gs.comprar_melhoria("punching_bag"), "compra bag_sand")
	checar_igual(gs.multiplicador_aparelho("punching_bag"), 15.0, "bag_sand: x15 no total")
	checar_igual(gs.por_clique(), 15.0, "por clique = 15")
	checar(not gs.proxima_melhoria("punching_bag").is_empty(), "depois do nível 2 ainda há níveis (agora são 4)")
	gs.treino = 1.0e9
	checar(gs.comprar_melhoria("punching_bag") and gs.comprar_melhoria("punching_bag"), "compra os níveis 3 e 4")
	checar_igual(gs.multiplicador_aparelho("punching_bag"), 300.0, "4 níveis: x300 no total (3 x 5 x 4 x 5)")
	checar(gs.proxima_melhoria("punching_bag").is_empty(), "linha completa: sem próxima")
	gs.treino = 1.0e9
	checar(not gs.pode_comprar_melhoria("punching_bag"), "linha completa não compra mais")
	checar(not gs.comprar_melhoria("punching_bag"), "compra recusada em linha completa")
	checar_igual(gs.treino, 1.0e9, "recusa em linha completa não gasta")
	checar_igual(gs.nivel_melhoria("punching_bag"), 4, "nível 4")
	checar_igual(gs.texto_efeito_melhoria(gs.dados.aparelho("punching_bag").upgrades[0]), "x3 POR CLIQUE: SACO", "texto do efeito")
	checar_igual(gs.texto_ui("panel_attributes"), "ATRIBUTOS", "texto_ui lê chave")
	checar_igual(gs.texto_ui("nao_existe", "x"), "x", "texto_ui usa padrão")
	gs.free()


# Critério 9: valor emitido == o que entrou no saldo e no atributo.
func _teste_clique() -> void:
	var gs := _novo("car_clique")
	gs.dados.crit_chance = 0.0
	gs.niveis_melhoria["punching_bag"] = 1
	var emitidos: Array = []
	gs.clicou.connect(func(g: float, c: bool, a: String, at: String, t: String) -> void: emitidos.append([g, c, a, at, t]))
	var r: Dictionary = gs.clicar()
	checar_igual(r.ganho, 3.0, "sem crítico: ganho = base x mult = 3")
	checar(not r.critico and r.texto_critico == "", "sem crítico: flag falsa e sem texto")
	checar_igual(gs.treino, 3.0, "saldo recebeu o ganho")
	checar_igual(gs.atributos.strength, 3.0, "atributo recebeu o ganho")
	checar_igual(emitidos.size(), 1, "um sinal por clique")
	checar_igual(emitidos[0][0], 3.0, "sinal traz o mesmo valor")
	checar_igual(emitidos[0][2], "punching_bag", "sinal traz o aparelho")
	checar_igual(emitidos[0][3], "strength", "sinal traz o atributo")

	gs.dados.crit_chance = 1.0
	r = gs.clicar()
	checar_igual(r.ganho, 9.0, "com crítico: ganho = base x mult x 3 = 9")
	checar(r.critico and r.texto_critico != "", "crítico traz flag e texto sorteado")
	checar(r.texto_critico in gs.dados.aparelho("punching_bag").crit_texts, "texto vem da lista do aparelho")
	checar_igual(gs.treino, 12.0, "saldo = 3 + 9")
	checar_igual(gs.atributos.strength, 12.0, "atributo = 3 + 9")
	checar_igual(emitidos[1][0], 9.0, "sinal do crítico traz 9")
	checar_igual(emitidos[1][1], true, "sinal do crítico marca critico")

	# Soma de 20 cliques (critério 9).
	gs.dados.crit_chance = 0.5
	gs.treino = 0.0
	gs.atributos.strength = 0.0
	emitidos.clear()
	for i in 20:
		gs.clicar()
	var soma := 0.0
	for e in emitidos:
		soma += e[0]
	checar_igual(soma, gs.treino, "soma dos números mostrados = saldo")
	checar_igual(soma, gs.atributos.strength, "soma dos números mostrados = atributo")
	gs.free()


func _teste_critico_estatistico() -> void:
	var gs := _novo("car_critico")
	gs.rng.seed = 12345
	var criticos := 0
	for i in 10000:
		if gs.clicar().critico:
			criticos += 1
	checar(criticos >= 900 and criticos <= 1100, "10.000 cliques a 10%% -> %d críticos (900..1100)" % criticos)
	gs.free()


# Critério 7: com renda passiva só o atributo em foco sobe; trocar o foco desvia na hora.
func _teste_passivo_vai_para_o_foco() -> void:
	var gs := _novo("car_passivo")
	checar_igual(gs.producao_total(), 0.0, "0 geradores: passivo 0")
	gs.geradores["neighbor_kid"] = 4
	gs.geradores["retired_uncle"] = 1
	checar_igual(gs.producao_total(), 12.0, "4 vizinhos + 1 tio = 4 + 8 = 12/s")
	gs.tick(2.0)
	checar_igual(gs.atributos.strength, 24.0, "passivo foi para a força")
	checar_igual(gs.atributos.agility, 0.0, "agilidade parada")
	checar_igual(gs.atributos.endurance, 0.0, "resistência parada")
	gs.definir_foco("jump_rope")
	gs.tick(1.0)
	checar_igual(gs.atributos.agility, 12.0, "após trocar o foco, o passivo vai para a agilidade")
	checar_igual(gs.atributos.strength, 24.0, "força não subiu mais")
	checar_igual(gs.treino, 36.0, "saldo recebeu tudo")
	gs.free()


# Critério: 30 e 144 FPS dão o mesmo total.
func _teste_fps() -> void:
	var totais := {}
	for fps in [30, 144]:
		var gs := _novo("car_fps")
		gs.geradores["neighbor_kid"] = 7
		gs.geradores["retired_uncle"] = 3
		for i in fps * 10:
			gs.tick(1.0 / fps)
		totais[fps] = gs.treino
		checar(_aprox(gs.atributos.strength, gs.treino, 1e-12), "atributo = saldo a %d FPS" % fps)
		gs.free()
	checar(_aprox(totais[30], totais[144], 1e-9), "30 FPS = 144 FPS (%s x %s)" % [totais[30], totais[144]])
	checar(_aprox(totais[30], 31.0 * 10.0, 1e-9), "10 s a 31/s = 310")


func _teste_foco_e_sinais() -> void:
	var gs := _novo("car_foco")
	checar_igual(gs.foco, "punching_bag", "foco inicial = saco")
	var focos: Array = []
	gs.foco_mudou.connect(func(a: String) -> void: focos.append(a))
	checar(gs.definir_foco("treadmill"), "troca para a esteira")
	checar_igual(gs.foco, "treadmill", "foco atualizado")
	checar_igual(gs.atributo_do_aparelho("treadmill"), "endurance", "esteira = resistência")
	checar(not gs.definir_foco("lixo"), "foco inexistente recusado")
	checar_igual(gs.foco, "treadmill", "foco mantido após recusa")
	gs.dados.crit_chance = 0.0
	gs.clicar()
	checar_igual(gs.atributos.endurance, 1.0, "clique foi para a resistência")
	gs.definir_foco("jump_rope")
	gs.clicar()
	checar_igual(gs.atributos.agility, 1.0, "clique foi para a agilidade")
	checar_igual(focos, ["treadmill", "jump_rope"], "sinal foco_mudou emitido")

	# Sinais de compra.
	var ger: Array = []
	var mel: Array = []
	var eco := [0]
	gs.gerador_mudou.connect(func(g: String, q: int) -> void: ger.append([g, q]))
	gs.melhoria_comprada.connect(func(a: String, m: String, n: int) -> void: mel.append([a, m, n]))
	gs.economia_mudou.connect(func() -> void: eco[0] += 1)
	gs.treino = 1000.0
	gs.comprar_gerador("neighbor_kid")
	gs.comprar_melhoria("treadmill")
	checar_igual(ger, [["neighbor_kid", 1]], "gerador_mudou emitido")
	checar_igual(mel, [["treadmill", "treadmill_oil", 1]], "melhoria_comprada emitida")
	checar_igual(eco[0], 2, "economia_mudou a cada compra")
	gs.free()


# Critério 17: 200 unidades, compra continua funcionando; desenho respeita o limite.
func _teste_pessoas_e_muitas_unidades() -> void:
	var gs := _novo("car_pessoas")
	var esperado_viz := {0: 0, 1: 1, 9: 1, 10: 2, 24: 2, 25: 3, 200: 3}
	for q in esperado_viz:
		gs.geradores["neighbor_kid"] = q
		checar_igual(gs.pessoas_desenhadas("neighbor_kid"), esperado_viz[q], "vizinho com %d: %d pessoa(s)" % [q, esperado_viz[q]])
	var esperado_tio := {0: 0, 1: 1, 10: 2, 200: 2}
	for q in esperado_tio:
		gs.geradores["retired_uncle"] = q
		checar_igual(gs.pessoas_desenhadas("retired_uncle"), esperado_tio[q], "tio com %d: %d pessoa(s)" % [q, esperado_tio[q]])
	gs.geradores["neighbor_kid"] = 200
	gs.treino = 1.0e30
	var antes: float = gs.treino
	checar(gs.comprar_gerador("neighbor_kid"), "compra com 200 unidades funciona")
	checar_igual(gs.quantidade_gerador("neighbor_kid"), 201, "201 vizinhos")
	checar(gs.treino < antes, "desconta o custo")
	checar_igual(gs.pessoas_desenhadas("neighbor_kid"), 3, "sala continua com 3 pessoas")
	gs.free()


# Invariantes da seção 1: soma dos atributos == treino ganho; saldo == ganho - gasto.
func _teste_invariantes() -> void:
	var gs := _novo("car_invariantes")
	gs.rng.seed = 7
	var gasto := 0.0
	for i in 600:
		gs.clicar()
		if i % 50 == 0:
			var c: float = gs.custo_gerador("neighbor_kid")
			if gs.comprar_gerador("neighbor_kid"):
				gasto += c
		if i == 300:
			gs.definir_foco("treadmill")
		gs.tick(0.1)
	var ganho := _soma_atributos(gs)
	checar(ganho > 0.0 and gasto > 0.0, "houve ganho e gasto")
	checar(_aprox(gs.treino, ganho - gasto, 1e-9), "saldo == ganho - gasto (%s vs %s)" % [gs.treino, ganho - gasto])
	checar(gs.treino >= 0.0, "saldo nunca negativo")
	gs.free()


func _teste_save_ida_e_volta() -> void:
	var gs := _novo("car_save")
	gs.treino = 1234.5
	gs.atributos = {"strength": 900.0, "agility": 200.0, "endurance": 134.5}
	gs.definir_foco("jump_rope")
	gs.geradores = {"neighbor_kid": 12, "retired_uncle": 3}
	gs.niveis_melhoria = {"punching_bag": 2, "jump_rope": 0, "treadmill": 1}
	checar(gs.salvar(), "salvou")
	var pasta: String = gs.store.pasta
	var doc = JSON.parse_string(ler(gs.store.caminho()))
	checar_igual(int(doc.version), SaveStore.VERSAO_ATUAL, "arquivo na versão atual")
	checar(doc.state.has("career"), "estado dentro de career")
	gs.free()

	var gs2: Node = GameStateScript.new()
	gs2.inicializar(pasta, "res://data/config.json")
	checar_igual(gs2.treino, 1234.5, "saldo restaurado")
	checar_igual(gs2.atributos.strength, 900.0, "força restaurada")
	checar_igual(gs2.atributos.agility, 200.0, "agilidade restaurada")
	checar_igual(gs2.atributos.endurance, 134.5, "resistência restaurada")
	checar_igual(gs2.foco, "jump_rope", "foco restaurado")
	checar_igual(gs2.quantidade_gerador("neighbor_kid"), 12, "vizinhos restaurados")
	checar_igual(gs2.quantidade_gerador("retired_uncle"), 3, "tios restaurados")
	checar_igual(gs2.nivel_melhoria("punching_bag"), 2, "nível do saco restaurado")
	checar_igual(gs2.nivel_melhoria("treadmill"), 1, "nível da esteira restaurado")
	checar_igual(gs2.producao_total(), 12.0 + 24.0, "produção recalculada dos dados")
	checar(gs2.avisos.is_empty(), "abrir sem avisos")
	gs2.free()


# Seção 8: validação de cada campo do save.
func _teste_save_invalido() -> void:
	var gs := _novo("car_save_invalido")
	gs.aplicar_save({"career": {
		"training": -50, "attributes": {"strength": -1, "agility": "x", "desconhecido": 9},
		"focus": "inexistente", "generators": {"neighbor_kid": 3.7, "retired_uncle": -2, "sumiu": 5},
		"apparatus_owned": ["punching_bag", "jump_rope", "treadmill"],
		"upgrades": {"punching_bag": 99, "jump_rope": -1, "treadmill": 1.9}}})
	checar_igual(gs.treino, 0.0, "treino negativo vira 0")
	checar_igual(gs.atributos.strength, 0.0, "atributo negativo vira 0")
	checar_igual(gs.atributos.agility, 0.0, "atributo inválido vira 0")
	checar(not gs.atributos.has("desconhecido"), "atributo desconhecido ignorado")
	checar_igual(gs.foco, "punching_bag", "foco inexistente vira o padrão")
	checar_igual(gs.quantidade_gerador("neighbor_kid"), 3, "gerador não inteiro: floor")
	checar_igual(gs.quantidade_gerador("retired_uncle"), 0, "gerador negativo vira 0")
	checar(not gs.geradores.has("sumiu"), "gerador que não existe mais é ignorado")
	checar_igual(gs.nivel_melhoria("punching_bag"), 4, "nível recortado ao máximo")
	checar_igual(gs.nivel_melhoria("jump_rope"), 0, "nível negativo vira 0")
	checar_igual(gs.nivel_melhoria("treadmill"), 1, "nível fracionado: floor")
	gs.aplicar_save({"career": "lixo"})
	checar_igual(gs.treino, 0.0, "career inválido: tudo no padrão")
	gs.aplicar_save({})
	checar_igual(gs.foco, "punching_bag", "estado vazio: foco padrão")
	gs.free()


func _teste_debug() -> void:
	var gs := _novo("car_debug")
	checar(gs.debug_disponivel() == OS.is_debug_build(), "depuração só em build de debug")
	gs.clicar()
	var forca: float = gs.atributos.strength
	gs.debug_somar_geradores()
	checar_igual(gs.quantidade_gerador("neighbor_kid"), 10, "+10 vizinhos")
	checar_igual(gs.quantidade_gerador("retired_uncle"), 10, "+10 tios")
	gs.debug_multiplicar_saldo()
	checar_igual(gs.atributos.strength, forca, "depuração não mexe em atributo")
	gs.free()
