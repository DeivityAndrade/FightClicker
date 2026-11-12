extends "res://tests/test_base.gd"
## Testa a Fase 3 no GameState: luta salva antes da animação, prêmio, derrota, Legado, aposentadoria,
## nova carreira, loja, luva, fechar no meio da luta e save v3. Usa pastas em user://test/.

const GameStateScript := preload("res://scripts/game_state.gd")
const FORTE := 1.0e7


func _novo(nome: String, pasta: String = "") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta if pasta != "" else pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.dados.box_apparatus = false  # Fase 5.1: estes testes cobrem a compra instantânea (a caixa tem teste próprio)
	gs.dados.box_glove = false
	gs.risco_hud_ativo = false
	gs.aparelhos_montados_ids = ["punching_bag", "jump_rope", "treadmill"]  # Fase 4b: os testes antigos usam os 3
	return gs


func _reabrir(pasta: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	return gs


func _atributos(gs: Node, f: float, a: float, r: float) -> void:
	gs.atributos = {"strength": f, "agility": a, "endurance": r}


func rodar_testes() -> void:
	_teste_estado_inicial()
	_teste_loja_gerador_pago()
	_teste_luvas()
	_teste_tabela_do_legado()
	_teste_luta_salva_antes_da_animacao()
	_teste_vitoria_e_premio()
	_teste_derrota_fim_de_carreira()
	_teste_cinturao_e_aposentar()
	_teste_aposentar_sempre_rende_mais()
	_teste_fechar_no_meio_da_luta()
	_teste_fechar_na_tela_de_fim()
	_teste_save_v4()
	_teste_save_invalido()
	_teste_eventos_da_luta()
	_teste_textos()
	_teste_motivo_pos_qa()
	_teste_risco_do_hud()
	_teste_previa()


func _teste_estado_inicial() -> void:
	var gs := _novo("f3_inicial")
	checar_igual(gs.indice_escada, 0, "0 vitórias")
	checar_igual(gs.dinheiro, 0.0, "sem dinheiro")
	checar_igual(gs.fama, 0, "sem fama")
	checar_igual(gs.tatica, "defensive", "tática padrão = defensivo")
	checar_igual(gs.numero_carreira(), 1, "Carreira 1")
	checar_igual(gs.proximo_adversario().id, "opp_warmup", "primeiro adversário: Dudu")
	checar_igual(gs.legado_em_jogo(), 0, "pote 0")
	checar_igual(gs.permanente.legacy_total, 0, "Legado total 0")
	checar_igual(gs.luva_equipada().id, "glove_old", "luva velha")
	checar_igual(gs.sufixo_luva(), "", "luva velha: sufixo vazio")
	checar(gs.pode_lutar() and gs.pode_aposentar(), "pode lutar e aposentar desde o minuto 0")
	checar(not gs.acoes_bloqueadas(), "garagem livre")
	_liberar(gs)


# Critérios 18 e 20.
func _teste_loja_gerador_pago() -> void:
	var gs := _novo("f3_loja")
	var custos := [50.0, 80.0, 128.0, 205.0, 328.0, 525.0]
	for i in custos.size():
		gs.geradores_pagos["gen_paid_1"] = i
		checar_igual(gs.custo_gerador_pago("gen_paid_1"), custos[i], "Prof. Nelson n=%d custa $%d" % [i, custos[i]])
	gs.geradores_pagos["gen_paid_1"] = 0
	gs.treino = 777.0
	_atributos(gs, 10.0, 20.0, 30.0)
	gs.dinheiro = 49.0
	checar(not gs.pode_comprar_gerador_pago("gen_paid_1"), "$49 não paga o Nelson")
	checar(not gs.comprar_gerador_pago("gen_paid_1"), "compra sem dinheiro recusada")
	checar_igual(gs.dinheiro, 49.0, "recusa não gasta")
	checar_igual(gs.quantidade_gerador("gen_paid_1"), 0, "recusa não contrata")
	gs.dinheiro = 130.0
	checar(gs.comprar_gerador_pago("gen_paid_1"), "compra o 1º Nelson")
	checar_igual(gs.dinheiro, 80.0, "desconta $50")
	checar(gs.comprar_gerador_pago("gen_paid_1"), "compra o 2º Nelson")
	checar_igual(gs.dinheiro, 0.0, "desconta $80")
	checar_igual(gs.treino, 777.0, "comprar em dinheiro não mexe no Treino")
	checar_igual(gs.atributos, {"strength": 10.0, "agility": 20.0, "endurance": 30.0}, "nem nos atributos")
	checar_igual(gs.producao_total(), 50.0, "2 Nelsons = +50 Treino/s")
	checar_igual(gs.producao_gerador("gen_paid_1"), 50.0, "produção do gerador pago")
	checar_igual(gs.pessoas_desenhadas("gen_paid_1"), 1, "2 Nelsons: 1 pessoa na sala")
	gs.geradores_pagos["gen_paid_1"] = 4
	checar_igual(gs.pessoas_desenhadas("gen_paid_1"), 2, "4 Nelsons: 2 pessoas na sala")
	# Vai para o foco, como os da garagem.
	gs.geradores_pagos["gen_paid_1"] = 2
	gs.definir_foco("treadmill")
	gs.tick(2.0)
	checar_igual(gs.atributos.endurance, 30.0 + 100.0, "produção do Nelson vai para o foco")
	checar_igual(gs.atributos.strength, 10.0, "e só para o foco")
	var sinais: Array = []
	gs.gerador_pago_mudou.connect(func(g: String, q: int) -> void: sinais.append([g, q]))
	gs.dinheiro = 1000.0
	gs.comprar_gerador_pago("gen_paid_1")
	checar_igual(sinais, [["gen_paid_1", 3]], "sinal gerador_pago_mudou")
	_liberar(gs)


# Critérios 8 e 19.
func _teste_luvas() -> void:
	var gs := _novo("f3_luvas")
	gs.dados.crit_chance = 0.0
	for ap in ["punching_bag", "jump_rope", "treadmill"]:
		gs.definir_foco(ap)
		checar_igual(gs.por_clique(), 1.0, "luva velha: clique 1 em %s" % ap)
	var sinais: Array = []
	gs.luva_mudou.connect(func(n: int, suf: String) -> void: sinais.append([n, suf]))
	gs.dinheiro = 119.0
	checar(not gs.comprar_luva(), "$119 não paga a luva de lona")
	gs.dinheiro = 120.0
	checar(gs.comprar_luva(), "compra a luva de lona por $120")
	checar_igual(gs.dinheiro, 0.0, "desconta $120")
	checar_igual(gs.luva_equipada().id, "glove_l1", "luva equipada: lona")
	checar_igual(gs.sufixo_luva(), "_glove_l1", "sufixo da lona")
	checar_igual(sinais, [[1, "_glove_l1"]], "sinal luva_mudou")
	for ap in ["punching_bag", "jump_rope", "treadmill"]:
		gs.definir_foco(ap)
		checar_igual(gs.por_clique(), 2.0, "lona: clique x2 em %s" % ap)
		checar_igual(gs.clicar().ganho, 2.0, "o clique rende x2 em %s" % ap)
	gs.niveis_melhoria["punching_bag"] = 1
	gs.definir_foco("punching_bag")
	checar_igual(gs.por_clique(), 6.0, "luva x2 por cima da melhoria x3 do aparelho")
	checar_igual(gs.multiplicador_aparelho("punching_bag"), 3.0, "multiplicador do aparelho não inclui a luva")
	gs.dinheiro = 500.0
	checar(gs.comprar_luva(), "compra a luva de couro por $500")
	checar_igual(gs.sufixo_luva(), "_glove_l2", "sufixo do couro")
	checar_igual(gs.por_clique(), 12.0, "couro: x2 de novo (x4 no total)")
	checar(not gs.proxima_luva().is_empty(), "L3 e L4 ainda à venda")
	gs.dinheiro = float(gs.proxima_luva().cost)
	checar(gs.comprar_luva(), "compra a luva L3")
	checar_igual(gs.por_clique(), 24.0, "L3: x2 de novo (x8 no total)")
	gs.dinheiro = float(gs.proxima_luva().cost)
	checar(gs.comprar_luva(), "compra a luva L4")
	checar_igual(gs.por_clique(), 48.0, "L4: x16 no total")
	checar(gs.proxima_luva().is_empty(), "linha de luvas completa")
	gs.dinheiro = 99999.0
	checar(not gs.comprar_luva(), "não compra além do último nível")
	# O sufixo bate com o manifest de arte (mesma fonte para cursor, garagem e luta).
	var manifest = JSON.parse_string(ler("res://assets/sprites/manifest.json"))
	var por_id: Dictionary = manifest.by_data_id
	for l in gs.lutas.luvas:
		if not por_id.has(l.id):
			print("  AVISO: %s ainda sem entrada no manifest (arte da 5.2 pendente)" % l.id)
			continue
		checar_igual(l.sprite_suffix, por_id[l.id].sprite_suffix, "%s: sprite_suffix igual ao manifest" % l.id)
	checar_igual(gs.lutas.luva_base.sprite_suffix, por_id.glove_old.sprite_suffix, "luva velha: sufixo igual ao manifest")
	_liberar(gs)


# Seção 8.2: tabela do Legado.
func _teste_tabela_do_legado() -> void:
	var gs := _novo("f3_legado")
	var tabela := [
		# fama, cinturão, pote, perde, aposenta
		[0, false, 0, 0, 0], [10, false, 20, 10, 20], [40, false, 80, 40, 80], [100, false, 200, 100, 200],
		[200, true, 500, 250, 750],
	]
	for l in tabela:
		gs.fama = l[0]
		gs.cinturao = l[1]
		gs.indice_escada = 4 if l[1] else 0
		checar_igual(gs.legado_em_jogo(), l[2], "fama %d: pote %d" % [l[0], l[2]])
		checar_igual(gs.legado_se_perder(), l[3], "fama %d: derrota leva %d" % [l[0], l[3]])
		checar_igual(gs.previa_aposentar().total, l[4], "fama %d: aposentadoria leva %d" % [l[0], l[4]])
	gs.fama = 200
	gs.cinturao = true
	var p: Dictionary = gs.previa_aposentar()
	checar(p.bonus == 250 and p.base == 500 and p.cinturao and not p.zero, "com cinturão: 500 + bônus 250")
	gs.fama = 0
	gs.cinturao = false
	checar(gs.previa_aposentar().zero, "pote 0: 'você leva 0'")
	_liberar(gs)


# Critério 11 (parte 1): o resultado já está decidido e salvo quando a animação começa.
func _teste_luta_salva_antes_da_animacao() -> void:
	var gs := _novo("f3_luta_salva")
	_atributos(gs, FORTE, FORTE, FORTE)
	var sinais: Array = []
	gs.luta_iniciada.connect(func(info: Dictionary) -> void: sinais.append(info))
	var info: Dictionary = gs.lutar()
	checar(not info.is_empty() and sinais.size() == 1, "lutar() devolve a luta e emite luta_iniciada")
	checar(gs.tem_luta_pendente() and gs.acoes_bloqueadas(), "luta pendente bloqueia a garagem")
	checar_igual(gs.lutar(), {}, "não dá para lutar duas vezes")
	checar_igual(gs.aposentar(), {}, "não dá para aposentar durante a luta")
	checar_igual(gs.clicar(), {}, "sem clique durante a luta")
	var doc = JSON.parse_string(ler(gs.store.caminho()))
	checar(doc != null and doc.state.career.fight != null, "o arquivo já tem career.fight antes de concluir")
	checar_igual(doc.state.career.fight.opponent, "opp_warmup", "adversário no arquivo")
	checar(doc.state.career.fight.result.win, "resultado no arquivo (forte vence)")
	checar_igual(gs.dinheiro, 0.0, "nada foi aplicado ainda")
	# A mesma semente recalcula a mesma luta.
	checar_igual(gs.luta_atual().events, info.events, "luta_atual() = mesma lista de eventos")
	_liberar(gs)


# Critérios 12 e 20: prêmio só na vitória.
func _teste_vitoria_e_premio() -> void:
	var gs := _novo("f3_vitoria")
	_atributos(gs, FORTE, FORTE, FORTE)
	gs.treino = 1234.0
	var resumos: Array = []
	gs.luta_resolvida.connect(func(r: Dictionary) -> void: resumos.append(r))
	var dinheiros: Array = []
	gs.dinheiro_mudou.connect(func(v: float) -> void: dinheiros.append(v))
	gs.lutar()
	var r: Dictionary = gs.concluir_luta()
	checar(r.win, "vitória")
	checar_igual(gs.dinheiro, 50.0, "prêmio: $50 (do data/)")
	checar_igual(gs.fama, 10, "prêmio: 10 de fama")
	checar_igual(gs.indice_escada, 1, "próximo adversário liberado")
	checar_igual(gs.proximo_adversario().id, "opp_strong", "o próximo é o Brutão")
	checar_igual(gs.legado_em_jogo(), 20, "pote subiu para 20")
	checar_igual([r.money, r.fame, r.legacy_gain, r.next], [50.0, 10, 20, "opp_strong"], "resumo da vitória")
	checar_igual(gs.treino, 1234.0, "vitória não mexe no Treino")
	checar(not gs.tem_luta_pendente() and not gs.acoes_bloqueadas(), "garagem livre de novo")
	checar_igual(resumos.size(), 1, "luta_resolvida emitido uma vez")
	checar(dinheiros.has(50.0), "dinheiro_mudou emitido")
	checar_igual(gs.concluir_luta(), {}, "concluir de novo não faz nada")
	checar_igual(gs.dinheiro, 50.0, "e não duplica o prêmio")
	# Escada inteira: o último dá o cinturão e acaba as lutas.
	for i in 3:
		gs.lutar()
		gs.concluir_luta()
	checar(gs.cinturao and gs.precisa_mudar() and not gs.escada_completa(), "4 vitórias: cinturão, e o próximo (academia) pede a mudança")
	checar_igual(gs.dinheiro, 3500.0, "50 + 150 + 800 + 2500")
	checar_igual(gs.fama, 200, "fama 10 + 30 + 60 + 100")
	checar_igual(gs.legado_em_jogo(), 500, "pote 400 + 100 do cinturão")
	checar(not gs.pode_lutar(), "depois do cinturão, na garagem, não há luta (só a mudança)")
	checar_igual(gs.lutar(), {}, "lutar() recusa")
	checar_igual(gs.proximo_adversario(), {}, "sem próximo adversário")
	_liberar(gs)


# Critérios 13, 15 e 27: derrota = fim de carreira; Legado = 50%; Nova carreira zera o `career`.
func _teste_derrota_fim_de_carreira() -> void:
	var gs := _novo("f3_derrota")
	gs.indice_escada = 2
	gs.fama = 100
	gs.dinheiro = 321.0
	gs.dinheiro_ganho = 600.0
	gs.tempo_jogo = 900.0
	gs.treino = 55.0
	_atributos(gs, 0.0, 0.0, 0.0)
	var fins: Array = []
	gs.fim_de_carreira.connect(func(f: Dictionary) -> void: fins.append(f))
	gs.lutar()
	var r: Dictionary = gs.concluir_luta()
	checar(not r.win, "derrota")
	var f: Dictionary = gs.fim
	checar_igual(f.kind, "defeat", "tela de fim: derrota")
	checar_igual(f.legacy_gained, 100, "Legado da derrota = 50% do pote (200)")
	checar_igual(gs.permanente.legacy_total, 100, "Legado total 100")
	checar_igual(gs.permanente.careers_finished, 1, "1 carreira encerrada")
	checar_igual(gs.permanente.best_wins, 2, "melhor carreira: 2 vitórias")
	checar_igual(f.opponent, "opp_fast", "perdeu para o Dinho")
	checar_igual(f.summary.wins, 2, "resumo: 2 vitórias")
	checar_igual(f.summary.fame, 100, "resumo: fama")
	checar_igual(f.summary.money_earned, 600.0, "resumo: dinheiro ganho")
	checar_igual(f.summary.play_seconds, 900.0, "resumo: tempo de jogo")
	checar_igual(gs.dinheiro, 321.0, "derrota não dá dinheiro")
	checar(f.reason.has("attribute") and f.reason.attribute in ["strength", "agility", "endurance"], "motivo com atributo decisivo")
	checar(f.reason.has("faltaram") and f.reason.has("stat"), "motivo traz 'faltaram' e a estatística")
	checar_igual(fins.size(), 1, "fim_de_carreira emitido")
	checar(gs.tem_fim_pendente() and gs.acoes_bloqueadas(), "tela de fim bloqueia a garagem")
	# Garagem congelada.
	var antes: Dictionary = gs.para_save()
	checar_igual(gs.clicar(), {}, "sem clique com a tela de fim")
	gs.geradores["neighbor_kid"] = 5
	gs.treino = 1.0e6
	checar(not gs.comprar_gerador("neighbor_kid"), "sem compra com a tela de fim")
	checar(not gs.comprar_melhoria("punching_bag"), "sem melhoria com a tela de fim")
	gs.dinheiro = 5000.0
	checar(not gs.comprar_luva() and not gs.comprar_gerador_pago("gen_paid_1"), "sem loja com a tela de fim")
	gs.tick(5.0)
	checar_igual(gs.atributos.strength, 0.0, "nada produz com a tela de fim")
	checar_igual(gs.tempo_jogo, 900.0, "o tempo de jogo não anda")
	checar_igual(gs.lutar(), {}, "sem luta com a tela de fim")
	checar_igual(gs.aposentar(), {}, "sem aposentar com a tela de fim")
	gs.treino = antes.career.training
	gs.geradores["neighbor_kid"] = 0
	gs.dinheiro = 321.0
	# NOVA CARREIRA.
	checar(gs.nova_carreira(), "nova carreira")
	checar_igual(gs.numero_carreira(), 2, "Carreira 2")
	checar_igual(gs.permanente.legacy_total, 100, "Legado total intacto")
	checar(gs.fim.is_empty() and not gs.acoes_bloqueadas(), "direto na garagem")
	checar_igual([gs.treino, gs.dinheiro, gs.fama, gs.indice_escada, gs.cinturao, gs.nivel_luva, gs.tempo_jogo],
		[0.0, 0.0, 0, 0, false, 0, 0.0], "carreira zerada")
	checar_igual(gs.atributos, {"strength": 0.0, "agility": 0.0, "endurance": 0.0}, "atributos zerados")
	checar_igual(gs.quantidade_gerador("neighbor_kid"), 0, "geradores zerados")
	checar_igual(gs.quantidade_gerador("gen_paid_1"), 0, "geradores pagos zerados")
	checar_igual(gs.tatica, "defensive", "tática volta ao padrão")
	checar(not gs.nova_carreira(), "nova carreira sem tela de fim é recusada")
	checar_igual(gs.permanente.career_number, 2, "e não conta de novo")
	# Derrota com 0 vitórias rende 0.
	var gs2 := _novo("f3_derrota_zero")
	gs2.lutar()
	gs2.concluir_luta()
	checar_igual(gs2.fim.legacy_gained, 0, "derrota sem vitórias: Legado 0")
	_liberar(gs)
	_liberar(gs2)


# Critério 16 e 17.
func _teste_cinturao_e_aposentar() -> void:
	var gs := _novo("f3_aposentar_cinturao")
	gs.indice_escada = 4
	gs.cinturao = true
	gs.fama = 200
	gs.dinheiro = 400.0
	gs.tempo_jogo = 2000.0
	var r: Dictionary = gs.aposentar()
	checar_igual(r.kind, "retire", "aposentadoria cria a tela de fim")
	checar_igual(r.legacy_gained, 750, "cinturão + aposentar = 750")
	checar_igual(gs.permanente.legacy_total, 750, "Legado total 750")
	checar_igual(gs.permanente.belts_won, 1, "1 cinturão ganho")
	checar_igual(gs.permanente.best_wins, 4, "melhor carreira: 4 vitórias")
	checar_igual(r.summary.belts, 1, "resumo: 1 cinturão")
	checar_igual(gs.textos_fim().support, "Cinturão na parede. Joelho no gelo.", "texto de apoio com cinturão")
	gs.nova_carreira()
	checar_igual(gs.numero_carreira(), 2, "Carreira 2")
	checar(not gs.cinturao and gs.indice_escada == 0, "novo começo")
	# Sem cinturão e com pote 0: permitido, leva 0.
	var r2: Dictionary = gs.aposentar()
	checar_igual(r2.legacy_gained, 0, "aposentar com pote 0 leva 0")
	checar_igual(gs.permanente.legacy_total, 750, "Legado anterior intacto")
	checar_igual(gs.textos_fim().support, "O saco fica pro próximo.", "texto de apoio sem cinturão")
	_liberar(gs)


# Critério 16: em todo estado testado, aposentar rende mais (ou igual só com pote 0) que perder.
func _teste_aposentar_sempre_rende_mais() -> void:
	var gs := _novo("f3_aposentar_mais")
	var ruim := 0
	var igual_com_pote := 0
	for fama in range(0, 600):
		for belt in [false, true]:
			gs.fama = fama
			gs.cinturao = belt
			var pote: int = gs.legado_em_jogo()
			var perde: int = gs.legado_se_perder()
			var apos: int = gs.previa_aposentar().total
			if apos < perde:
				ruim += 1
			if pote >= 1 and apos <= perde:
				igual_com_pote += 1
	checar_igual(ruim, 0, "aposentar nunca rende menos que perder")
	checar_igual(igual_com_pote, 0, "com pote >= 1 aposentar rende estritamente mais")
	_liberar(gs)


# Critérios 11 e 27: fechar o jogo no meio da luta não evita a derrota e não duplica nada.
func _teste_fechar_no_meio_da_luta() -> void:
	var gs := _novo("f3_fechar_luta")
	var pasta: String = gs.store.pasta
	gs.fama = 100
	gs.indice_escada = 2
	_atributos(gs, 0.0, 0.0, 0.0)
	var info: Dictionary = gs.lutar()
	checar(not info.result.win, "luta perdida decidida ao apertar LUTAR")
	var eventos_antes: Array = info.events
	_liberar(gs)  # fechou o jogo no meio da animação
	var gs2 := _reabrir(pasta)
	checar(gs2.tem_luta_pendente(), "reabrir: luta pendente")
	checar_igual(gs2.luta_atual().events, eventos_antes, "reabrir: a mesma luta, golpe a golpe")
	checar_igual(gs2.permanente.legacy_total, 0, "ainda sem Legado (não foi aplicado)")
	var r: Dictionary = gs2.concluir_luta()
	checar(not r.win and gs2.tem_fim_pendente(), "reabrir: vai direto para o resultado (derrota)")
	checar_igual(gs2.permanente.legacy_total, 100, "Legado somado uma vez")
	_liberar(gs2)
	var gs3 := _reabrir(pasta)
	checar(not gs3.tem_luta_pendente(), "reabrir de novo: sem luta pendente")
	checar(gs3.tem_fim_pendente(), "reabrir de novo: tela de fim")
	checar_igual(gs3.permanente.legacy_total, 100, "Legado não duplicou")
	checar_igual(gs3.concluir_luta(), {}, "concluir de novo não faz nada")
	checar_igual(gs3.permanente.legacy_total, 100, "Legado ainda 100")
	_liberar(gs3)
	# Vitória fechada no meio: prêmio uma vez só.
	var gs4 := _novo("f3_fechar_vitoria")
	var pasta2: String = gs4.store.pasta
	_atributos(gs4, FORTE, FORTE, FORTE)
	gs4.lutar()
	_liberar(gs4)
	var gs5 := _reabrir(pasta2)
	gs5.concluir_luta()
	checar_igual(gs5.dinheiro, 50.0, "vitória aplicada ao reabrir")
	_liberar(gs5)
	var gs6 := _reabrir(pasta2)
	checar_igual(gs6.dinheiro, 50.0, "e não repete ao reabrir de novo")
	checar_igual(gs6.indice_escada, 1, "uma vitória só")
	_liberar(gs6)


# Critério 27: fim pendente e aposentadoria sobrevivem ao fechamento sem duplicar Legado.
func _teste_fechar_na_tela_de_fim() -> void:
	var gs := _novo("f3_fechar_fim")
	var pasta: String = gs.store.pasta
	gs.fama = 100
	gs.indice_escada = 2
	gs.aposentar()
	var fim: Dictionary = gs.fim.duplicate(true)
	checar_igual(gs.permanente.legacy_total, 200, "aposentou com pote 200")
	_liberar(gs)
	var gs2 := _reabrir(pasta)
	checar_igual(gs2.fim.kind, "retire", "reabrir: tela de fim da aposentadoria")
	checar_igual(gs2.fim.legacy_gained, fim.legacy_gained, "mesmo Legado ganho")
	checar_igual(gs2.permanente.legacy_total, 200, "Legado não somou de novo")
	checar(gs2.acoes_bloqueadas(), "garagem bloqueada até NOVA CARREIRA")
	checar(gs2.nova_carreira(), "nova carreira")
	_liberar(gs2)
	var gs3 := _reabrir(pasta)
	checar(gs3.fim.is_empty() and gs3.numero_carreira() == 2, "reabrir: Carreira 2 na garagem")
	checar_igual(gs3.permanente.legacy_total, 200, "Legado mantido")
	_liberar(gs3)


func _teste_save_v4() -> void:
	var gs := _novo("f3_save")
	var pasta: String = gs.store.pasta
	gs.treino = 1234.5
	gs.atributos = {"strength": 900.0, "agility": 200.0, "endurance": 134.5}
	gs.geradores_pagos["gen_paid_1"] = 2
	gs.nivel_luva = 1
	gs.dinheiro = 30.0
	gs.fama = 40
	gs.indice_escada = 2
	gs.tatica = "counter"
	gs.tempo_jogo = 742.0
	gs.dinheiro_ganho = 200.0
	gs.permanente = {"legacy_total": 14, "career_number": 3, "careers_finished": 2, "best_wins": 3, "belts_won": 0,
		"skill_nodes": ["body_jab"], "revenge_opponent": "opp_fast"}
	checar(gs.salvar(), "salvou")
	var doc = JSON.parse_string(ler(gs.store.caminho()))
	checar_igual(int(doc.version), SaveStore.VERSAO_ATUAL, "arquivo na versão atual")
	checar(doc.state.has("career") and doc.state.has("permanent") and doc.state.has("ending"), "career, permanent e ending")
	checar(doc.state.ending == null and doc.state.career.fight == null, "ending e fight nulos")
	checar_igual(doc.state.career.paid_generators.gen_paid_1, 2.0, "paid_generators no arquivo")
	_liberar(gs)
	var gs2 := _reabrir(pasta)
	checar_igual(gs2.quantidade_gerador("gen_paid_1"), 2, "Nelsons restaurados")
	checar_igual(gs2.nivel_luva, 1, "luva restaurada")
	checar_igual(gs2.dinheiro, 30.0, "dinheiro restaurado")
	checar_igual(gs2.fama, 40, "fama restaurada")
	checar_igual(gs2.indice_escada, 2, "escada restaurada")
	checar_igual(gs2.tatica, "counter", "tática restaurada")
	checar_igual(gs2.tempo_jogo, 742.0, "tempo de jogo restaurado")
	checar_igual(gs2.dinheiro_ganho, 200.0, "dinheiro ganho restaurado")
	checar_igual(gs2.permanente.legacy_total, 14, "Legado total restaurado")
	checar_igual(gs2.numero_carreira(), 3, "Carreira 3 restaurada")
	checar_igual(gs2.producao_total(), 50.0, "produção recalculada dos dados")
	checar(gs2.avisos.is_empty(), "abre sem avisos")
	_liberar(gs2)


# Seção 12.2.
func _teste_save_invalido() -> void:
	var gs := _novo("f3_save_invalido")
	gs.aplicar_save({"career": {"glove_level": 99, "ladder_index": 99, "belt": true, "tactic": "lixo", "money": -5,
		"fame": -3, "play_seconds": "x", "paid_generators": {"gen_paid_1": -4}}, "permanent": {"career_number": 0,
		"legacy_total": -9}})
	checar_igual(gs.nivel_luva, gs.lutas.luvas.size(), "glove_level recortado ao máximo")
	checar_igual(gs.indice_escada, 6, "ladder_index recortado ao nº de adversários")
	checar(gs.cinturao, "cinturão com a escada passada do Muralha")
	checar_igual(gs.tatica, "defensive", "tática inválida = padrão")
	checar_igual(gs.dinheiro, 0.0, "dinheiro negativo = 0")
	checar_igual(gs.fama, 0, "fama negativa = 0")
	checar_igual(gs.tempo_jogo, 0.0, "tempo inválido = 0")
	checar_igual(gs.quantidade_gerador("gen_paid_1"), 0, "gerador pago negativo = 0")
	checar_igual(gs.numero_carreira(), 1, "career_number >= 1")
	checar_igual(gs.permanente.legacy_total, 0, "Legado negativo = 0")
	gs.aplicar_save({"career": {"belt": true, "ladder_index": 2}})
	checar(not gs.cinturao, "belt sem escada completa vira falso")
	gs.aplicar_save({"career": {"belt": false, "ladder_index": 4}})
	checar(gs.cinturao, "B7: escada completa com belt falso vira cinturão")
	# Luta com adversário inexistente: descartada, sem vitória nem derrota.
	var ruim := {"opponent": "opp_fantasma", "tactic": "counter", "seed": 5, "player": {"strength": 1, "agility": 1, "endurance": 1},
		"result": {"win": false, "ko": true, "t_ko": 3.0, "t_end": 5.0, "round": 1, "pct_player": 0.0, "pct_opponent": 1.0}}
	gs.aplicar_save({"career": {"fight": ruim}})
	checar(not gs.tem_luta_pendente() and not gs.tem_fim_pendente(), "luta inexistente descartada")
	checar_igual(gs.permanente.legacy_total, 0, "sem derrota, sem Legado")
	checar_igual(gs.indice_escada, 0, "sem vitória")
	ruim.opponent = "opp_strong"  # fora da vez (a carreira está no 1º)
	gs.aplicar_save({"career": {"fight": ruim}})
	checar(not gs.tem_luta_pendente(), "luta fora da vez descartada")
	ruim.opponent = "opp_warmup"
	gs.aplicar_save({"career": {"fight": ruim}})
	checar(gs.tem_luta_pendente(), "luta válida é mantida")
	gs.aplicar_save({"ending": {"kind": "lixo"}})
	checar(not gs.tem_fim_pendente(), "tela de fim de tipo desconhecido descartada")
	gs.aplicar_save({"career": "lixo", "permanent": 5, "ending": 7})
	checar_igual(gs.numero_carreira(), 1, "blocos inválidos: padrão")
	_liberar(gs)


# Registro dos eventos para a UI animar (critério 7).
func _teste_eventos_da_luta() -> void:
	var gs := _novo("f3_eventos")
	gs.definir_tatica("defensive")
	_atributos(gs, 3000.0, 3000.0, 3000.0)
	var info: Dictionary = gs.lutar()
	var ev: Array = info.events
	checar(ev.size() > 0, "a luta tem eventos")
	var ordenado := true
	var vida_ok := true
	var ult := {"0": 1.0, "1": 1.0}
	var tipos_ok := true
	for e in ev:
		for chave in ["t", "who", "target", "type", "counter", "kind", "attack_anim", "defender_anim", "damage", "life_after",
				"life_pct_after", "ko", "blocked", "round"]:
			if not e.has(chave):
				tipos_ok = false
		if e.t > 16.0 + 1e-9:
			ordenado = false
		if e.life_pct_after < 0.0 or e.life_pct_after > 1.0 + 1e-12 or e.life_pct_after > ult[str(e.target)] + 1e-12:
			vida_ok = false
		ult[str(e.target)] = e.life_pct_after
		if not (e.kind in ["jab", "crit", "counter", "dodge"]) or not (e.attack_anim in ["jab", "heavy"]) \
				or not (e.defender_anim in ["hit", "block", "dodge"]):
			tipos_ok = false
		if e.type == "dodge" and (e.damage != 0.0 or e.defender_anim != "dodge"):
			tipos_ok = false
		if e.who == 1 and e.type != "dodge" and not e.blocked:
			tipos_ok = false  # tática defensiva: o jogador bloqueia
		if e.who == 0 and e.blocked:
			tipos_ok = false
	checar(tipos_ok, "campos e valores dos eventos")
	checar(ordenado, "nenhum evento depois de 16 s")
	checar(vida_ok, "a vida só desce e fica entre 0 e 1")
	for i in range(1, ev.size()):
		if ev[i].t < ev[i - 1].t - 1e-12:
			ordenado = false
	checar(ordenado, "eventos em ordem de tempo")
	checar(info.screen_seconds >= 8.0 - 1e-9 and info.screen_seconds <= 19.0 + 1e-9, "tela entre 8 e 19 s")
	checar_igual(info.intro_seconds, 1.5, "intro 1.5 s")
	checar_igual(info.outro_seconds, 1.5, "outro 1.5 s")
	if info.result.ko:
		checar(ev[-1].ko, "o último evento do K.O. está marcado")
		checar_igual(ev[-1].life_after, 0.0, "vida 0 no K.O.")
	checar(info.loser == (-1 if not info.result.ko else (1 if info.result.win else 0)), "perdedor coerente")
	# Cada tática tem sua animação: contra-ataque gera contra-golpes que viram `heavy`.
	var gs2 := _novo("f3_eventos_contra")
	gs2.definir_tatica("counter")
	_atributos(gs2, 1500.0, 1500.0, 1500.0)
	var contras := 0
	var cru := 0
	for s in range(1, 60):
		gs2.rng.seed = s
		gs2.luta = {}
		var i2: Dictionary = gs2.lutar()
		for e in i2.events:
			if e.counter:
				contras += 1
				if e.kind != "counter" or e.attack_anim != "heavy" or e.who != 0:
					cru += 1
		gs2.concluir_luta()
		if gs2.tem_fim_pendente():
			gs2.nova_carreira()
			gs2.definir_tatica("counter")
		_atributos(gs2, 1500.0, 1500.0, 1500.0)
		gs2.indice_escada = 0
	checar(contras > 0, "o contra-ataque gera contra-golpes (%d)" % contras)
	checar_igual(cru, 0, "contra-golpe: kind=counter, heavy, do jogador")
	# Grogue: K.O. antes de 5 s.
	var gs3 := _novo("f3_eventos_grogue")
	_atributos(gs3, 0.0, 0.0, 0.0)
	var i3: Dictionary = gs3.lutar()
	checar(not i3.grogue.is_empty() and i3.grogue.who == 0 and i3.grogue.to == 5.0, "K.O. cedo: grogue do jogador até 5.0 s")
	checar_igual(i3.screen_seconds, 8.0, "tela de 8.0 s")
	_liberar(gs)
	_liberar(gs2)
	_liberar(gs3)


func _teste_textos() -> void:
	var gs := _novo("f3_textos")
	checar_igual(GameStateScript.preencher("SE VENCER: ${n} + {n} FAMA", {"n": ["50", "10"]}), "SE VENCER: $50 + 10 FAMA", "preencher: dois {n}")
	checar_igual(GameStateScript.preencher("{nome} VENCEU NO {n}º ROUND", {"nome": "Dudu", "n": 2}), "Dudu VENCEU NO 2º ROUND", "preencher: nome e n")
	checar_igual(gs.texto_ui("time_rule_tie"), "EMPATE EXATO: FICA COM ELE", "time_rule_tie")
	checar_igual(gs.lutas.tatica("defensive").hint, "Fecha a guarda. O crítico dele não entra.", "dica do defensivo")
	checar_igual(gs.lista_ui("reason_strength").size(), 3, "motivo de Força: 3 modelos")
	checar_igual(gs.lista_ui("reason_agility").size(), 4, "motivo de Agilidade: 4 modelos")
	checar_igual(gs.lista_ui("tip_endurance").size(), 3, "3 dicas por atributo")
	# Derrota real: frases da tela de fim (com 'faltaram' e com a estatística como segunda linha).
	gs.indice_escada = 2
	gs.fama = 40
	_atributos(gs, 6000.0, 6000.0, 3000.0)
	gs.lutar()
	gs.concluir_luta()
	var t: Dictionary = gs.textos_fim()
	checar_igual(t.title, "FIM DE CARREIRA", "título")
	checar(t.who.begins_with("Dinho Pulga VENCEU"), "quem venceu: %s" % t.who)
	checar(gs.fim.reason.faltaram > 0.0, "existe 'faltaram' neste estado")
	checar(t.reason.begins_with("FALTARAM ") and " DE " in t.reason, "motivo principal 'FALTARAM n DE ...': %s" % t.reason)
	checar(t.stat != "", "segunda linha com a estatística da luta: %s" % t.stat)
	checar(t.tip != "", "dica de ação: %s" % t.tip)
	checar(not ("{" in t.who + t.reason + t.stat + t.tip), "nenhuma variável sem preencher")
	var motivo: Dictionary = gs.fim.reason
	var nome_attr: String = {"strength": "FORÇA", "agility": "AGILIDADE", "endurance": "RESISTÊNCIA"}[motivo.attribute]
	checar(nome_attr in t.reason.to_upper(), "o motivo cita o atributo decisivo (%s)" % nome_attr)
	# Fim salvo antes da correção (sem `kind`, sem 'faltaram'): a estatística vira o motivo, sem passar de 100%.
	var antigo := {"kind": "defeat", "opponent": "opp_fast", "tactic": "defensive", "seed": 4, "player": {}, "summary": {},
		"result": {"ko": true, "round": 1}, "reason": {"attribute": "endurance", "faltaram": -1.0, "round": 1, "model": 0,
		"tip": 0, "better_tactic": "", "stat": {"kind": "life_taken", "n": 100, "k": 3}}}
	var t2: Dictionary = gs.textos_fim(antigo)
	checar(t2.reason != "" and t2.stat == "" and not ("{" in t2.reason), "fim antigo: a estatística assume o motivo: %s" % t2.reason)
	antigo.reason.stat = {"kind": "stronger", "n": 20982, "k": 0}
	checar_igual(gs.textos_fim(antigo).reason, "", "fim antigo com 'stronger' absurdo: estatística vazia")
	_liberar(gs)


func _teste_risco_do_hud() -> void:
	var gs := _novo("f3_hud")
	gs.risco_hud_ativo = true
	var sinais: Array = []
	gs.risco_proxima_mudou.connect(func(a: String, r: String) -> void: sinais.append([a, r]))
	gs.atualizar_risco_hud()
	checar_igual(gs.risco_proxima().adversario, "opp_warmup", "HUD: próxima = Dudu")
	checar_igual(gs.risco_proxima().rotulo, "hard", "HUD: sem treino é PERIGOSO")
	_atributos(gs, FORTE, FORTE, FORTE)
	gs.tick(0.4)
	checar_igual(gs.risco_proxima().rotulo, "hard", "HUD só recalcula depois de 1 s")
	gs.tick(0.7)
	checar_igual(gs.risco_proxima().rotulo, "easy", "HUD recalcula depois de 1 s: FÁCIL")
	checar(sinais.size() >= 1 and sinais[-1] == ["opp_warmup", "easy"], "sinal risco_proxima_mudou")
	gs.definir_tatica("counter")
	checar_igual(gs.risco_proxima().tatica, "counter", "HUD usa a última tática")
	gs.indice_escada = 4
	gs.atualizar_risco_hud()
	checar_igual(gs.risco_proxima().adversario, "", "depois do cinturão: sem próxima luta")
	_liberar(gs)


func _teste_previa() -> void:
	var gs := _novo("f3_previa")
	_atributos(gs, 100.0, 100.0, 100.0)
	gs.treino = 500.0
	var antes: Dictionary = gs.para_save()
	var p: Dictionary = gs.previa()
	checar_igual(p.opponent.id, "opp_warmup", "prévia: Dudu")
	checar_igual(p.you.strength, 100.0, "prévia: seus atributos crus")
	checar_igual(p.risks.keys().size(), 3, "prévia: risco das 3 táticas")
	for t in p.risks:
		checar(p.risks[t].label in ["easy", "even", "hard"], "rótulo válido (%s)" % t)
	checar_igual(p.risk, p.risks[gs.tatica].label, "risco da tática escolhida")
	checar_igual(p.stake_win, "SE VENCER: $50 + 10 FAMA", "prêmio em jogo")
	checar_igual(p.lead, "strength", "destaque: ele é muito mais forte")
	checar(not p.stake_belt, "o 1º não é a luta do cinturão")
	checar_igual(gs.para_save(), antes, "abrir a prévia não muda nada (critério 4)")
	gs.indice_escada = 3
	checar(gs.previa().stake_belt, "a luta do cinturão mostra stake_belt")
	_liberar(gs)


# Pós-QA (design §16, B2-B5): motivo calculado em lutar(), azar, textos novos e plural.
func _teste_motivo_pos_qa() -> void:
	# B5: o motivo é calculado e salvo em lutar(); a leitura depois é instantânea e igual.
	var gs := _novo("f3_pos_qa")
	gs.indice_escada = 2
	_atributos(gs, 6000.0, 6000.0, 3000.0)
	gs.lutar()
	gs.aguardar_motivo()  # segundo plano termina e grava em luta.reason + save, antes de concluir_luta()
	checar(gs.luta.has("reason") and gs.luta.reason.kind == "missing", "B5: motivo calculado em segundo plano: %s" % str(gs.luta.get("reason", {}).get("kind")))
	var arq := FileAccess.open(gs.store.caminho(), FileAccess.READ)
	checar(arq != null and arq.get_as_text().contains("\"reason\""), "B5: motivo já está no arquivo salvo antes do resultado")
	var t0 := Time.get_ticks_msec()
	var m: Dictionary = gs.motivo_da_luta()
	checar(Time.get_ticks_msec() - t0 < 20, "B5: motivo_da_luta() só lê (sem busca)")
	checar_igual(m, gs.luta.reason, "B5: motivo_da_luta() devolve o calculado")
	var salvo: Dictionary = gs.para_save()
	checar(salvo.career.fight.has("reason"), "B5: motivo vai no save da luta")
	gs.concluir_luta()
	checar_igual(gs.fim.reason.kind, "missing", "fim guarda reason.kind")
	checar(gs.fim.reason.faltaram > 0.0, "kind missing tem faltaram")
	_liberar(gs)
	# Azar: textos de luck, dica tip_luck, nada de tip_tactic nem tip_<atributo>.
	var gl := _novo("f3_azar")
	var fim_azar := {"kind": "defeat", "opponent": "opp_warmup", "tactic": "counter", "seed": 7, "player": {}, "summary": {},
		"result": {"ko": false}, "reason": {"seed": 7, "kind": "luck", "attribute": "", "faltaram": -1.0, "far_n": 0,
		"round": 1, "model": 1, "tip": 1, "better_tactic": "defensive", "stat": {"kind": "luck_odds", "n": 9, "k": 0}}}
	var tl: Dictionary = gl.textos_fim(fim_azar)
	checar(tl.reason in gl.lista_ui("reason_luck"), "azar: linha principal de reason_luck: %s" % tl.reason)
	checar(tl.tip in gl.lista_ui("tip_luck"), "azar: dica de tip_luck: %s" % tl.tip)
	checar_igual(tl.tip_tactic, "", "azar: sem dica de tática")
	checar_igual(tl.stat, "ISSO ACONTECE EM 9 DE CADA 100 LUTAS", "azar: estatística luck_odds")
	fim_azar.reason.stat = {"kind": "luck_rare", "n": 0, "k": 0}
	checar_igual(gl.textos_fim(fim_azar).stat, "ISSO QUASE NUNCA ACONTECE", "azar: luck_rare")
	# Estatísticas novas e plural.
	var r := {"kind": "defeat", "opponent": "opp_fast", "tactic": "defensive", "seed": 1, "player": {}, "summary": {},
		"result": {"ko": true, "round": 1}, "reason": {"kind": "missing", "attribute": "strength", "faltaram": 1500.0,
		"model": 0, "tip": 0, "better_tactic": "", "stat": {"kind": "stronger_x", "n": 4, "k": 0}}}
	checar(" 4 " in gl.textos_fim(r).stat and "{" not in gl.textos_fim(r).stat, "stronger_x: %s" % gl.textos_fim(r).stat)
	r.reason.stat = {"kind": "stronger_cap", "n": 10, "k": 0}
	checar(" 10 " in gl.textos_fim(r).stat and "MAIS DE" in gl.textos_fim(r).stat, "stronger_cap: %s" % gl.textos_fim(r).stat)
	r.reason.stat = {"kind": "points", "n": 35, "k": 60}
	checar(gl.textos_fim(r).stat.contains("35%") and gl.textos_fim(r).stat.contains("60%"), "points: %s" % gl.textos_fim(r).stat)
	r.reason.stat = {"kind": "life_taken", "n": 100, "k": 1}
	checar(gl.textos_fim(r).stat.ends_with("1 GOLPE"), "plural: 1 GOLPE (%s)" % gl.textos_fim(r).stat)
	r.reason.stat = {"kind": "life_taken", "n": 100, "k": 3}
	checar(gl.textos_fim(r).stat.ends_with("3 GOLPES"), "plural: 3 GOLPES")
	# Fallback far / far_plain.
	r.reason = {"kind": "far", "attribute": "endurance", "faltaram": -1.0, "far_n": 12, "model": 0, "tip": 0,
		"better_tactic": "", "stat": {"kind": "points", "n": 10, "k": 90}}
	checar_igual(gl.textos_fim(r).reason, "ELE TINHA 12X O SEU TREINO", "far: razão no texto")
	r.reason.kind = "far_plain"
	checar_igual(gl.textos_fim(r).reason, "TREINE MUITO MAIS ANTES DE ENCARAR ELE", "far_plain")
	checar(gl.textos_fim(r).tip != "", "far: dica do atributo")
	_liberar(gl)


# Espera o motivo em segundo plano antes de liberar o GameState (senão o objeto fica travado).
func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()
