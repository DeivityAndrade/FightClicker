extends "res://tests/test_base.gd"
## Fase 5: academia (mudança), artes (Boxe e Jiu-jitsu), aparelhos de arte, traço de luta, lutas da academia, aba ESTILO,
## reserva da LOJA, dica de aposentar e save v6. Tudo em pastas de user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String, treino_td: String = TrainingData.CAMINHO_TREINO, dados_lutas: FightData = null,
		dados_academia: GymData = null) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json", treino_td, TrainingData.CAMINHO_GERADORES,
		TrainingData.CAMINHO_TEXTOS, dados_lutas, dados_academia)
	gs.autosave_ativo = false
	gs.dados.box_apparatus = false  # Fase 5.1: estes testes cobrem a compra instantânea (a caixa tem teste próprio)
	gs.dados.box_glove = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0  # sem crítico: contas exatas
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _passar(gs: Node, segundos: float) -> void:
	for i in int(round(segundos * 10.0)):
		gs.tick(0.1)


# Carreira com o cinturão e o dinheiro da mudança, ainda na garagem.
func _com_cinturao(nome: String, dinheiro: float = 1000.0) -> Node:
	var gs := _novo(nome)
	gs.indice_escada = 4
	gs.cinturao = true
	gs.fama = 200  # 4 vitórias da garagem: 30 + 10 + 60 + 100
	gs.dinheiro = dinheiro
	return gs


# Já na academia, com a arte escolhida ("" = deixa a escolha pendente).
func _na_academia(nome: String, arte: String = "") -> Node:
	var gs := _com_cinturao(nome)
	gs.mudar()
	if arte != "":
		gs.escolher_arte(arte)
	return gs


# Carreira da garagem com a arte (artes já liberadas no permanent).
func _com_arte(nome: String, arte: String) -> Node:
	var gs := _novo(nome)
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gs.escolher_arte(arte)
	return gs


func rodar_testes() -> void:
	_teste_dados()
	_teste_mudanca()
	_teste_multiplicador_do_local()
	_teste_reserva_da_loja()
	_teste_primeira_chegada_e_reabrir()
	_teste_escolha_e_nova_carreira()
	_teste_boxe()
	_teste_jiu_jitsu()
	_teste_aparelho_da_arte()
	_teste_traco_de_luta()
	_teste_escada_da_academia()
	_teste_estilo()
	_teste_dica_de_aposentar()
	_teste_dados_mudam_o_jogo()
	_teste_save_v6()
	_teste_migracao_v5()
	_teste_validacoes()
	_teste_textos()


# --- Dados reais ---

func _teste_dados() -> void:
	var a := GymData.carregar()
	checar_igual(a.local_padrao, "garage", "local padrão: garagem")
	checar_igual([a.local("gym").training_mult, a.local("gym").move.cost, a.local("gym").apparatus_suffix], [2.0, 1000.0, "_gym"],
		"academia: x2, $1.000, sufixo _gym")
	checar_igual(a.local("garage").move, {}, "garagem não se compra")
	checar_igual(a.ids_artes(), ["boxing", "bjj"], "2 artes: Boxe e Jiu-jitsu")
	checar_igual(a.arte("boxing").rule, {"type": "manual_click_bonus", "value": 0.5}, "Boxe: +50% no clique manual")
	var rjj: Dictionary = a.arte("bjj").rule
	checar(rjj.type == "crew_time_bonus" and float(rjj.start) > 0.0 and float(rjj.cap) > float(rjj.start), "Jiu-jitsu: regra de tempo (valores vêm do JSON)")
	checar_igual([a.arte("boxing").fight, a.arte("bjj").fight], [{"damage_mult": 1.10, "taken_mult": 1.0}, {"damage_mult": 1.0, "taken_mult": 0.90}],
		"traços de luta: +10% dano / -10% dano recebido")
	var d := TrainingData.carregar()
	checar_igual(d.aparelhos.size(), 3, "3 aparelhos de toda carreira")
	checar_igual(d.aparelhos_arte.size(), 2, "2 aparelhos de arte")
	var pera := d.aparelho("speed_bag")
	var boneco := d.aparelho("grappling_dummy")
	checar_igual([pera.art, pera.unlock.cost, pera.unlock.requires, pera.split], ["boxing", 2500.0, "treadmill",
		{"strength": 0.40, "agility": 0.45, "endurance": 0.15}], "pera: Boxe, 2.500, pede a esteira, 40/45/15")
	checar_igual([boneco.art, boneco.unlock.cost, boneco.split], ["bjj", 2500.0, {"strength": 0.25, "agility": 0.15, "endurance": 0.60}],
		"boneco: Jiu-jitsu, 2.500, 25/15/60")
	checar_igual([pera.upgrades.size(), pera.upgrades[0].cost, pera.upgrades[0].multiplier, pera.upgrades[1].cost, pera.upgrades[1].multiplier],
		[4, 1500.0, 3.0, 15000.0, 5.0], "técnicas do Boxe: x3 por 1.500, x5 por 15.000 (e mais 2 níveis)")
	checar_igual(d.default_focus, "punching_bag", "foco padrão continua o saco")
	a.validar_aparelhos(d)
	checar_igual([a.arte("boxing").apparatus, a.arte("bjj").apparatus], ["speed_bag", "grappling_dummy"], "artes apontam para os aparelhos")
	var f := FightData.carregar()
	checar_igual(f.adversarios.size(), 6, "6 adversários")
	checar_igual([f.adversario("opp_gym_1").location, f.adversario("opp_gym_2").location, f.adversario("opp_tank").location],
		["gym", "gym", "garage"], "Tonhão e Kid na academia; Muralha na garagem")
	checar_igual([f.adversario("opp_gym_1").strength, f.adversario("opp_gym_1").agility, f.adversario("opp_gym_1").endurance,
		f.adversario("opp_gym_1").prize_money, f.adversario("opp_gym_1").prize_fame], [390000.0, 150000.0, 1650000.0, 2500.0, 120.0],
		"Tonhão do Tatame: 390K/150K/1,65M, $2.500, 120 de Fama")
	checar_igual([f.adversario("opp_gym_2").strength, f.adversario("opp_gym_2").agility, f.adversario("opp_gym_2").endurance,
		f.adversario("opp_gym_2").prize_money, f.adversario("opp_gym_2").prize_fame], [1150000.0, 2300000.0, 4600000.0, 6000.0, 200.0],
		"Kid Navalha: 1,15M/2,3M/4,6M, $6.000, 200 de Fama")
	checar_igual(f.indice_cinturao(), 3, "o cinturão é do Seu Muralha (índice 3)")
	checar(not f.adversario("opp_gym_1").belt and not f.adversario("opp_gym_2").belt, "só o Muralha dá o cinturão")
	checar_igual(f.carreira.gym_retire_hint_seconds, 300.0, "dica de aposentar aos 300 s")
	checar_igual(f.ramo("style").requires_arts_unlocked, true, "ramo ESTILO só com artes liberadas")
	for id in ["style_boxing", "style_bjj"]:
		var n := f.no_da_arvore(id)
		checar(n.cost == 1200 and n.effect_type == "art_rule_bonus" and n.effect_value == 0.5 and n.requires_art != "",
			"%s: 1.200 de Legado, +50%% do efeito da arte" % id)
		checar(n.name.length() <= 16 and n.description.length() <= 44, "%s respeita os limites de texto" % id)
	var gs := _novo("f5_textos_dados")
	for chave in ["move_title", "move_button", "move_price", "move_effect", "move_keeps", "move_reserve", "move_reserve_short",
			"move_arrived", "hud_next_move", "hud_location_mult", "no_more_fights_gym", "gym_retire_hint", "art_title", "art_sub_first",
			"art_sub_career", "art_choose", "art_whole_career", "art_last", "hud_art_boxing", "hud_art_bjj", "hud_art_bjj_max",
			"focus_split", "career_card_art", "tree_branch_style", "tree_short_style_boxing", "tree_short_style_bjj",
			"tree_style_art_only", "belt_unlock", "belt_hint"]:
		checar(gs.texto_ui(chave) != "", "ui_texts tem '%s'" % chave)
	for chave in ["tip_unlock_speed_bag", "tip_unlock_grappling_dummy", "tip_gym_loss", "tip_art_boxing", "tip_art_bjj", "tip_move_belt"]:
		checar_igual(gs.lista_ui(chave).size(), 3, "ui_texts: 3 dicas em '%s'" % chave)
	_liberar(gs)


# --- A mudança ---

func _teste_mudanca() -> void:
	var gs := _novo("f5_mudanca")
	checar_igual(gs.estado_mudanca(), "locked", "sem cinturão: o botão não existe (locked)")
	checar(not gs.pode_mudar() and not gs.mudar(), "sem cinturão não muda")
	gs.dinheiro = 5000.0
	checar(not gs.mudar() and gs.local_id == "garage", "dinheiro sem cinturão não compra a mudança")
	gs.indice_escada = 4
	gs.cinturao = true
	gs.dinheiro = 999.0
	checar_igual(gs.estado_mudanca(), "missing", "cinturão e $999: apagado (missing)")
	checar(not gs.mudar() and gs.dinheiro == 999.0, "$999 não muda e não gasta")
	checar_igual(gs.mudanca().cost, 1000.0, "o botão mostra o preço 1.000")
	checar_igual(gs.mudanca().price_text, "$1.00K", "texto do preço")
	checar_igual(gs.mudanca().button, "MUDAR", "rótulo do botão")
	# Estado completo antes de mudar.
	gs.dinheiro = 1500.0
	gs.treino = 777.0
	gs.atributos = {"strength": 50.0, "agility": 30.0, "endurance": 10.0}
	gs.geradores["neighbor_kid"] = 5
	gs.geradores_pagos["gen_paid_1"] = 2
	gs.nivel_luva = 1
	gs.nivel_metronomo = 2
	gs.niveis_melhoria["punching_bag"] = 1
	gs.aparelhos_montados_ids = ["punching_bag", "treadmill"]
	gs.foco = "treadmill"
	var locais: Array = []
	gs.local_mudou.connect(func(l): locais.append(l))
	var pedidos: Array = []
	gs.escolha_arte_pedida.connect(func(p): pedidos.append(p))
	checar_igual(gs.estado_mudanca(), "ready", "cinturão e $1.500: pronto")
	checar(gs.mudar(), "muda")
	checar_igual(gs.dinheiro, 500.0, "desconta $1.000 uma vez só")
	checar(not gs.mudar(), "não muda duas vezes")
	checar_igual(gs.dinheiro, 500.0, "segundo MUDAR não gasta")
	checar_igual(gs.local_id, "gym", "agora na academia")
	checar_igual(locais, ["gym"], "sinal local_mudou")
	checar_igual(gs.mudanca(), {}, "depois de mudar não há mais o que comprar")
	checar_igual([gs.treino, gs.atributos, gs.quantidade_gerador("neighbor_kid"), gs.quantidade_gerador("gen_paid_1"), gs.nivel_luva,
		gs.nivel_metronomo, gs.nivel_melhoria("punching_bag"), gs.aparelhos_montados(), gs.foco],
		[777.0, {"strength": 50.0, "agility": 30.0, "endurance": 10.0}, 5, 2, 1, 2, 1, ["punching_bag", "treadmill"], "treadmill"],
		"mudar não tira nada")
	checar_igual(gs.artes_liberadas(), ["boxing", "bjj"], "1ª chegada libera as 2 artes")
	checar(gs.escolha_arte_pendente() and gs.escolha_arte_primeira(), "1ª chegada pede a escolha")
	checar_igual(pedidos, [true], "sinal escolha_arte_pedida(primeira)")
	checar_igual(gs.sufixo_aparelhos(), "_gym", "aparelhos na versão da academia")
	checar_igual(gs.texto_hud_local(), "ACADEMIA: TREINO x2", "HUD da academia")
	checar_igual(gs.proximo_adversario().id, "opp_gym_1", "agora o Tonhão luta")
	# Salvou na hora.
	var gs2: Node = GameStateScript.new()
	gs2.inicializar(gs.store.pasta, "res://data/config.json")
	gs2.autosave_ativo = false
	checar_igual([gs2.local_id, gs2.dinheiro, gs2.artes_liberadas()], ["gym", 500.0, ["boxing", "bjj"]], "a mudança é salva na hora")
	_liberar(gs2)
	# Bloqueios.
	var gs3 := _com_cinturao("f5_mudanca_bloq")
	gs3.luta = {"x": 1}
	checar(not gs3.mudar(), "não muda durante a luta")
	gs3.luta = {}
	_liberar(gs3)
	_liberar(gs)


func _teste_multiplicador_do_local() -> void:
	var gs := _com_cinturao("f5_mult")
	gs.geradores["neighbor_kid"] = 10
	var clique = gs.por_clique()
	var auto = gs.por_auto_soco()
	var equipe = gs.producao_total()
	checar_igual([clique, auto, equipe], [1.0, 1.0, 10.0], "garagem: 1 por clique, 10/s com 10 vizinhos")
	gs.mudar()
	gs.permanente["arts_unlocked"] = []  # isola o multiplicador do local: sem janela de arte e sem arte
	checar_igual([gs.por_clique(), gs.por_auto_soco(), gs.producao_total()], [2.0, 2.0, 20.0], "academia: clique, auto-soco e equipe x2")
	var antes: float = gs.treino
	gs.clicar()
	checar_igual(gs.treino - antes, 2.0, "o clique rende x2")
	gs.auto_socar()
	checar_igual(gs.treino - antes, 4.0, "o auto-soco rende x2")
	_passar(gs, 1.0)
	checar(absf(gs.treino - antes - 4.0 - 20.0) < 1e-6, "a equipe rende x2 por segundo")
	# Preços, dinheiro e Fama não são multiplicados.
	checar_igual(gs.premio_dinheiro(gs.lutas.adversario("opp_gym_1")), 2500.0, "prêmio do Tonhão sem multiplicador")
	_liberar(gs)


func _teste_reserva_da_loja() -> void:
	var gs := _com_cinturao("f5_reserva", 1030.0)
	checar_igual(gs.reserva_mudanca(), 1000.0, "entre o cinturão e a mudança a reserva é $1.000")
	checar_igual(gs.loja_estado(30.0), "ok", "gastar $30 de $1.030 deixa $1.000: ok")
	checar_igual(gs.loja_estado(50.0), "reserve", "gastar $50 de $1.030 deixaria $980: reserva")
	checar_igual(gs.loja_estado(5000.0), "money", "sem dinheiro: money")
	gs.dinheiro = 1100.0
	checar_igual(gs.custo_gerador_pago("gen_paid_1"), 50.0, "Nelson custa $50")
	checar(gs.comprar_gerador_pago("gen_paid_1"), "compra o Nelson (sobram $1.050)")
	var comprou = gs.comprar_gerador_pago("gen_paid_1")  # $80: deixaria $970
	checar(not comprou, "o 2º Nelson ($80) deixaria menos de $1.000: recusado")
	checar_igual(gs.dinheiro, 1050.0, "a recusa não gasta")
	checar_igual(gs.texto_reserva(), "GUARDE $1.00K PARA A MUDANÇA", "motivo escrito no botão")
	checar_igual(gs.texto_reserva(true), "GUARDE $1.00K", "versão curta")
	gs.dinheiro = 1100.0
	checar(not gs.comprar_luva() or gs.dinheiro <= 1100.0, "luva respeita a mesma reserva")
	gs.dinheiro = 1100.0
	gs.nivel_luva = 0
	checar(not gs.pode_comprar_luva(), "luva de $120 deixaria $980: recusada")
	gs.dinheiro = 1100.0
	checar(gs.pode_comprar_metronomo(), "Metrônomo ($80) deixa $1.020: ok")
	gs.mudar()
	checar_igual(gs.reserva_mudanca(), 0.0, "depois de mudar a LOJA volta ao normal")
	gs.dinheiro = 130.0
	checar(gs.pode_comprar_luva(), "depois de mudar compra a luva com $130")
	# Antes do cinturão não há reserva.
	var gs2 := _novo("f5_reserva_sem_cinturao")
	gs2.dinheiro = 130.0
	checar_igual(gs2.reserva_mudanca(), 0.0, "sem cinturão não há reserva")
	checar(gs2.pode_comprar_luva(), "antes do cinturão a loja é livre")
	_liberar(gs2)
	_liberar(gs)


# --- Escolha da arte ---

func _teste_primeira_chegada_e_reabrir() -> void:
	var gs := _na_academia("f5_primeira")
	checar(gs.acoes_bloqueadas(), "janela de arte aberta bloqueia as ações")
	checar_igual(gs.clicar(), {}, "sem clique com a janela aberta")
	var t0: float = gs.tempo_jogo
	var cartoes: Array = gs.artes_para_escolha()
	checar_igual(cartoes.map(func(c): return c.id), ["boxing", "bjj"], "janela mostra as 2 artes")
	checar(not cartoes[0].last and not cartoes[1].last, "1ª vez: nenhuma marcada")
	checar_igual(cartoes[0].rule_text, "+50% TREINO NO CLIQUE DA SUA MÃO", "texto da regra do Boxe")
	var rj0: Dictionary = gs.academia.arte("bjj").rule
	checar_igual(cartoes[1].rule_text, "EQUIPE +%d%% (SOBE %d%% POR MINUTO ATÉ %d%%)" % [roundi(100.0 * rj0.start), roundi(100.0 * rj0.per_minute), roundi(100.0 * rj0.cap)], "texto da regra do Jiu-jitsu")
	checar_igual(cartoes[0].fight_text, "BOXE: +10% DE DANO", "traço do Boxe")
	checar_igual(cartoes[1].fight_text, "JIU-JITSU: -10% DE DANO RECEBIDO", "traço do Jiu-jitsu")
	checar_igual([cartoes[0].apparatus, cartoes[0].apparatus_name], ["speed_bag", "PERA"], "aparelho assinatura do Boxe")
	checar_igual(gs.subtitulo_escolha_arte(), "AS DUAS ARTES FICAM LIBERADAS PARA SEMPRE", "subtítulo da 1ª vez")
	checar(not gs.escolher_arte("muay_thai"), "arte inexistente é recusada")
	# Fechar o jogo sem escolher: reabre pedindo.
	var gs2: Node = GameStateScript.new()
	gs2.inicializar(gs.store.pasta, "res://data/config.json")
	gs2.autosave_ativo = false
	var pedidos: Array = []
	gs2.escolha_arte_pedida.connect(func(p): pedidos.append(p))
	gs2.carregar_save()
	checar(gs2.escolha_arte_pendente() and gs2.local_id == "gym", "reabrir sem escolher: a janela volta")
	checar_igual(pedidos, [true], "e o sinal vem de novo")
	_liberar(gs2)
	checar(gs.escolher_arte("bjj"), "1 clique escolhe")
	checar_igual([gs.arte_id, gs.arte_segundos, gs.permanente.last_art], ["bjj", 0.0, "bjj"], "arte, relógio e última arte")
	checar(not gs.escolha_arte_pendente() and not gs.acoes_bloqueadas(), "janela fechada")
	checar(not gs.escolher_arte("boxing"), "não existe troca dentro da carreira")
	checar_igual(gs.arte_id, "bjj", "a arte continua a mesma")
	checar(not gs.has_method("trocar_arte"), "nenhuma função de troca")
	var gs3: Node = GameStateScript.new()
	gs3.inicializar(gs.store.pasta, "res://data/config.json")
	gs3.autosave_ativo = false
	checar_igual([gs3.arte_id, gs3.permanente.last_art], ["bjj", "bjj"], "escolha salva na hora")
	_liberar(gs3)
	checar(t0 >= 0.0, "ok")
	_liberar(gs)


func _teste_escolha_e_nova_carreira() -> void:
	var gs := _na_academia("f5_nova", "boxing")
	gs.aparelhos_montados_ids = ["punching_bag", "treadmill", "speed_bag"]
	gs.niveis_melhoria["speed_bag"] = 1
	_passar(gs, 3.0)
	checar(gs.arte_segundos > 2.9, "o relógio da arte anda com a carreira")
	var pedidos: Array = []
	gs.escolha_arte_pedida.connect(func(p): pedidos.append(p))
	var cartoes: Array = []
	gs.nova_carreira_iniciada.connect(func(c): cartoes.append(c))
	gs.aposentar()
	checar_igual(gs.fim.summary.art, "boxing", "o resumo do fim guarda a arte")
	checar(gs.nova_carreira(), "nova carreira")
	checar_igual([gs.local_id, gs.arte_id, gs.arte_segundos], ["garage", "", 0.0], "volta para a garagem, sem arte, relógio zerado")
	checar_igual(gs.aparelhos_montados(), ["punching_bag"], "aparelho da arte zera")
	checar_igual(gs.nivel_melhoria("speed_bag"), 0, "técnicas zeram")
	checar(gs.escolha_arte_pendente() and not gs.escolha_arte_primeira(), "da 2ª carreira em diante a escolha vem no início")
	checar_igual(pedidos, [false], "sinal escolha_arte_pedida(false)")
	checar_igual(gs.subtitulo_escolha_arte(), "CARREIRA 2: ESCOLHA A ARTE", "subtítulo da carreira")
	var c: Array = gs.artes_para_escolha()
	checar_igual([c[0].last, c[1].last, c[0].last_text], [true, false, "ÚLTIMA: BOXE"], "a última arte vem marcada")
	checar_igual(gs.artes_liberadas(), ["boxing", "bjj"], "as artes ficam liberadas para sempre")
	checar_igual(cartoes.size(), 1, "nova_carreira_iniciada emitido antes da escolha")
	checar_igual(gs.cartao_inicio(), {}, "sem nós e sem arte: sem cartão")
	checar(gs.escolher_arte("boxing"), "escolhe a mesma arte com 1 clique")
	checar_igual(gs.cartao_inicio().art_text, "ARTE: BOXE", "o cartão mostra a arte depois da escolha")
	# Derrota também volta para a garagem sem arte.
	var gs2 := _na_academia("f5_nova_derrota", "bjj")
	gs2.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	gs2.lutar()
	gs2.luta["result"]["win"] = false
	gs2.concluir_luta()
	checar(gs2.tem_fim_pendente(), "derrota na academia")
	gs2.nova_carreira()
	checar_igual([gs2.local_id, gs2.arte_id], ["garage", ""], "depois da derrota: garagem, sem arte")
	_liberar(gs2)
	_liberar(gs)


# --- O que cada arte faz ---

func _teste_boxe() -> void:
	var sem := _novo("f5_boxe_sem")
	var gs := _com_arte("f5_boxe", "boxing")
	var base: float = sem.por_clique()
	for i in 1000:
		sem.clicar()
		gs.clicar()
	checar(absf(gs.treino - 1.5 * sem.treino) < 1e-6, "1000 cliques manuais com Boxe = 1,5 x sem arte (%s x %s)" % [gs.treino, sem.treino])
	checar_igual(gs.por_clique(), 1.5 * base, "por_clique mostra o bônus")
	var sem2 := _novo("f5_boxe_sem2")
	var gs2 := _com_arte("f5_boxe2", "boxing")
	for i in 1000:
		sem2.auto_socar()
		gs2.auto_socar()
	checar_igual(gs2.treino, sem2.treino, "1000 auto-socos (Metrônomo e assistido): igual a sem arte")
	checar_igual(gs2.por_auto_soco(), sem2.por_clique(), "auto-soco sem o bônus")
	# O Metrônomo e o assistido de verdade.
	var gm := _com_arte("f5_boxe_metronomo", "boxing")
	gm.nivel_metronomo = 1
	_passar(gm, 4.0)
	checar_igual(gm.treino, 3.0, "Metrônomo (3 socos em 4 s) sem o bônus do Boxe")
	var ga := _com_arte("f5_boxe_assistido", "boxing")
	ga.definir_assistido(true)
	_passar(ga, 5.0)
	var esperado: float = ga.assist_socos_total * 1.0
	checar(ga.assist_socos_total >= 1 and ga.treino == esperado, "assistido sem o bônus do Boxe")
	# Na academia, x2 por cima.
	var gg := _na_academia("f5_boxe_gym", "boxing")
	checar_igual(gg.por_clique(), 3.0, "academia + Boxe: 2 x 1,5")
	# Boxe não mexe na equipe.
	gg.geradores["neighbor_kid"] = 10
	checar_igual(gg.producao_total(), 20.0, "Boxe não mexe na equipe")
	checar_igual(gs.texto_hud_arte(), "BOXE: +50% NO SEU CLIQUE", "HUD do Boxe")
	for g in [sem, gs, sem2, gs2, gm, ga, gg]:
		_liberar(g)


## Bônus do Jiu-jitsu (sem estilo) após t segundos, lido da regra do JSON.
func _bjj(rj: Dictionary, t: float) -> float:
	return minf(float(rj.cap), float(rj.start) + float(rj.per_minute) * t / 60.0)


func _teste_jiu_jitsu() -> void:
	var gs := _com_arte("f5_jj", "bjj")
	gs.geradores["neighbor_kid"] = 100  # 100/s
	var rj: Dictionary = gs.academia.arte("bjj").rule
	var t_teto: float = (float(rj.cap) - float(rj.start)) / float(rj.per_minute) * 60.0
	var casos := [[0.0, 1.0 + _bjj(rj, 0.0)], [240.0, 1.0 + _bjj(rj, 240.0)], [t_teto, 1.0 + float(rj.cap)], [3600.0, 1.0 + float(rj.cap)]]
	for caso in casos:
		gs.arte_segundos = caso[0]
		checar(absf(gs.producao_total() / 100.0 - caso[1]) < 1e-9, "Jiu-jitsu a %ss: equipe x%s" % [caso[0], caso[1]])
	gs.arte_segundos = 0.0
	checar_igual(gs.texto_hud_arte(), "JIU-JITSU: EQUIPE +%d%%" % roundi(100.0 * _bjj(rj, 0.0)), "HUD do Jiu-jitsu no começo")
	gs.arte_segundos = 240.0
	checar_igual(gs.texto_hud_arte(), "JIU-JITSU: EQUIPE +%d%%" % roundi(100.0 * _bjj(rj, 240.0)), "HUD aos 4 min")
	checar(not gs.arte_no_teto(), "ainda não no teto")
	gs.arte_segundos = t_teto
	checar_igual(gs.texto_hud_arte(), "JIU-JITSU: EQUIPE +%d%% (MÁX.)" % roundi(100.0 * float(rj.cap)), "HUD no teto")
	checar(gs.arte_no_teto(), "no teto aos 6:40")
	checar_igual([gs.por_clique(), gs.por_auto_soco()], [1.0, 1.0], "o clique não muda")
	# O relógio anda no tick.
	var g2 := _com_arte("f5_jj_tick", "bjj")
	g2.geradores["neighbor_kid"] = 100
	_passar(g2, 60.0)
	checar(absf(g2.arte_segundos - 60.0) < 1e-6, "art_seconds anda com o tempo")
	checar(absf(g2.bonus_arte_equipe() - (float(rj.start) + float(rj.per_minute))) < 1e-9, "1 min: +32%")
	# Com o nó ESTILO: começa em 30%, 18/min, teto 150%.
	var g3 := _com_arte("f5_jj_estilo", "bjj")
	g3.permanente["skill_nodes"] = ["style_bjj"]
	g3._recalcular_bonus()
	g3.geradores["neighbor_kid"] = 100
	for caso in [[0.0, 1.0 + 1.5 * _bjj(rj, 0.0)], [240.0, 1.0 + 1.5 * _bjj(rj, 240.0)], [t_teto, 1.0 + 1.5 * float(rj.cap)], [3600.0, 1.0 + 1.5 * float(rj.cap)]]:
		g3.arte_segundos = caso[0]
		checar(absf(g3.producao_total() / 100.0 - caso[1]) < 1e-9, "Jiu-jitsu + ESTILO a %ss: x%s" % [caso[0], caso[1]])
	# Na academia, o x2 multiplica por cima.
	var g4 := _na_academia("f5_jj_gym", "bjj")
	g4.geradores["neighbor_kid"] = 100
	checar(absf(g4.producao_total() - 100.0 * 2.0 * (1.0 + _bjj(rj, 0.0))) < 1e-9, "academia + Jiu-jitsu: 2 x 1,2")
	# Jiu-jitsu não corta o clique nem a árvore: soma.
	g4.permanente["skill_nodes"] = ["body_crew"]
	g4._recalcular_bonus()
	checar(absf(g4.producao_total() - 100.0 * 1.5 * 2.0 * (1.0 + _bjj(rj, 0.0))) < 1e-9, "árvore x local x Jiu-jitsu")
	for g in [gs, g2, g3, g4]:
		_liberar(g)


func _teste_aparelho_da_arte() -> void:
	var sem := _novo("f5_ap_sem")
	checar_igual(sem.aparelhos_da_carreira().map(func(a): return a.id), ["punching_bag", "treadmill", "jump_rope"], "sem arte: só os 3 de sempre")
	checar_igual([sem.estado_aparelho("speed_bag"), sem.estado_aparelho("grappling_dummy")], ["absent", "absent"], "sem arte nenhum dos dois existe")
	checar(not sem.comprar_aparelho("speed_bag") and not sem.definir_foco("speed_bag"), "sem arte não compra nem foca")
	_liberar(sem)
	var gs := _com_arte("f5_ap", "boxing")
	checar_igual(gs.aparelhos_da_carreira().map(func(a): return a.id), ["punching_bag", "treadmill", "jump_rope", "speed_bag"],
		"com Boxe: a pera é o 4º aparelho")
	checar_igual([gs.estado_aparelho("speed_bag"), gs.estado_aparelho("grappling_dummy")], ["locked", "absent"], "pera trancada pela esteira; boneco ausente")
	checar_igual(gs.textos_trancado("grappling_dummy"), {}, "aparelho da outra arte não tem textos")
	checar_igual(gs.textos_trancado("speed_bag").floor_mark, "PERA — DEPOIS DA ESTEIRA", "plaquinha antes da esteira")
	gs.treino = 100000.0
	checar(not gs.comprar_aparelho("speed_bag"), "pede a esteira")
	checar(gs.comprar_aparelho("treadmill"), "compra a esteira")
	gs.treino = 3000.0
	checar_igual(gs.estado_aparelho("speed_bag"), "buyable", "pera comprável depois da esteira")
	checar_igual(gs.textos_trancado("speed_bag").floor_mark, "PERA — 2.50K TREINO", "plaquinha com o preço")
	checar(not gs.comprar_aparelho("grappling_dummy"), "o boneco não existe na carreira de Boxe")
	var comprados: Array = []
	gs.aparelho_comprado.connect(func(a): comprados.append(a))
	gs.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	checar(gs.comprar_aparelho("speed_bag"), "compra a pera")
	checar_igual(gs.treino, 500.0, "desconta 2.500")
	checar_igual([gs.foco, comprados], ["speed_bag", ["speed_bag"]], "foco vai para a pera e o sinal sai")
	checar_igual(gs.atributos, {"strength": 0.0, "agility": 0.0, "endurance": 0.0}, "comprar não mexe nos atributos")
	# Divisão do treino: 40/45/15, saldo recebe tudo.
	var t0: float = gs.treino
	gs.auto_socar()  # sem Boxe no auto-soco: 1 de treino
	checar_igual(gs.treino - t0, 1.0, "o saldo recebe o valor inteiro")
	checar(absf(gs.atributos.strength - 0.40) < 1e-12 and absf(gs.atributos.agility - 0.45) < 1e-12 and absf(gs.atributos.endurance - 0.15) < 1e-12,
		"split 40/45/15 nos atributos")
	gs.clicar()  # com Boxe: 1,5
	checar(absf(gs.atributos.strength - (0.40 + 0.6)) < 1e-12 and absf(gs.atributos.agility - (0.45 + 0.675)) < 1e-12,
		"o clique do Boxe divide 1,5 em 40/45/15")
	checar_igual(gs.textos_trancado("speed_bag"), {}, "montado: sem textos de trancado")
	checar_igual(gs.texto_divisao("speed_bag"), "FOR 40% / AGI 45% / RES 15%", "texto da divisão")
	checar_igual(gs.texto_divisao("punching_bag"), "", "aparelho comum não tem divisão")
	# A equipe também divide, com o aparelho em foco.
	var g2 := _com_arte("f5_ap_equipe", "bjj")
	g2.aparelhos_montados_ids = ["punching_bag", "treadmill", "grappling_dummy"]
	g2.foco = "grappling_dummy"
	g2.geradores["neighbor_kid"] = 10
	g2.arte_segundos = 0.0
	g2.tick(1.0)
	var ganho: float = 10.0 * (1.0 + float(g2.academia.arte("bjj").rule.start))
	checar(absf(g2.treino - ganho) < 1e-9 and absf(g2.atributos.endurance - ganho * 0.60) < 1e-9 and absf(g2.atributos.strength - ganho * 0.25) < 1e-9,
		"a equipe treina nos 3 atributos pelo split do boneco")
	# Técnicas: x3 e x5.
	gs.treino = 20000.0
	var antes: float = gs.por_auto_soco()
	checar(gs.comprar_melhoria("speed_bag"), "técnica 1 (Jab duplo)")
	checar_igual(gs.treino, 18500.0, "desconta 1.500")
	checar_igual(gs.por_auto_soco(), antes * 3.0, "técnica 1: x3")
	checar(gs.comprar_melhoria("speed_bag"), "técnica 2 (Esquiva e volta)")
	checar_igual(gs.treino, 3500.0, "desconta 15.000")
	checar_igual(gs.por_auto_soco(), antes * 15.0, "técnicas: x15 no total")
	checar_igual(gs.nivel_visual("speed_bag"), 1, "visual_level 1")
	# O erro da dica de fim: o aparelho de arte não entra.
	checar_igual(gs._aparelho_da_dica({"kind": "missing", "attribute": "agility"}), "jump_rope", "a dica de fim ignora o aparelho da arte")
	# NOVA CARREIRA zera.
	gs.aposentar()
	gs.nova_carreira()
	checar_igual([gs.aparelhos_montados(), gs.nivel_melhoria("speed_bag"), gs.estado_aparelho("speed_bag")], [["punching_bag"], 0, "absent"],
		"NOVA CARREIRA zera aparelho e técnicas (a arte precisa ser escolhida de novo)")
	# Salvar e reabrir mantém.
	var g3 := _com_arte("f5_ap_salvo", "bjj")
	g3.aparelhos_montados_ids = ["punching_bag", "treadmill", "grappling_dummy"]
	g3.niveis_melhoria["grappling_dummy"] = 1
	g3.foco = "grappling_dummy"
	g3.salvar()
	var g4: Node = GameStateScript.new()
	g4.inicializar(g3.store.pasta, "res://data/config.json")
	g4.autosave_ativo = false
	checar_igual([g4.aparelhos_montados(), g4.nivel_melhoria("grappling_dummy"), g4.foco], [["punching_bag", "treadmill", "grappling_dummy"], 1, "grappling_dummy"],
		"aparelho de arte salvo e carregado")
	for g in [gs, g2, g3, g4]:
		_liberar(g)


func _teste_traco_de_luta() -> void:
	var sem := _novo("f5_traco_sem")
	var bx := _com_arte("f5_traco_bx", "boxing")
	var bj := _com_arte("f5_traco_bj", "bjj")
	var jog := [5000.0, 3000.0, 20000.0]
	var adv := [8000.0, 4000.0, 30000.0]
	for t in ["aggressive", "defensive", "counter"]:
		var n_sem: Array = sem.motor.preparar(jog, adv, t).num
		var n_bx: Array = bx.motor.preparar(jog, adv, t).num
		var n_bj: Array = bj.motor.preparar(jog, adv, t).num
		checar(absf(n_bx[0][0] / n_sem[0][0] - 1.10) < 1e-9 and absf(n_bx[1][0] - n_sem[1][0]) < 1e-9, "%s: Boxe +10%% no dano que causa" % t)
		checar(absf(n_bj[1][0] / n_sem[1][0] - 0.90) < 1e-9 and absf(n_bj[0][0] - n_sem[0][0]) < 1e-9, "%s: Jiu-jitsu -10%% no dano recebido" % t)
	checar_igual(sem.tatica_efetiva("aggressive").damage_mult, 1.35, "sem arte a tática não muda")
	checar(absf(bx.tatica_efetiva("aggressive").damage_mult - 1.35 * 1.10) < 1e-9, "tatica_efetiva do Boxe")
	checar(absf(bj.tatica_efetiva("aggressive").taken_mult - 1.25 * 0.90) < 1e-9, "tatica_efetiva do Jiu-jitsu")
	checar_igual(bx.lutas.tatica("aggressive").damage_mult, 1.35, "a tática dos dados não é alterada")
	# Prévia e luta usam a mesma tática: a chance da prévia é a do motor da luta.
	for g in [sem, bx, bj]:
		g.atributos = {"strength": 200000.0, "agility": 60000.0, "endurance": 700000.0}
		g.indice_escada = 3
		var risco: Dictionary = g.risco_tatica("defensive")
		var direta: float = g.motor.chance([200000.0, 60000.0, 700000.0], [82000.0, 61000.0, 515000.0], "defensive")
		checar_igual(risco.chance, direta, "prévia e motor concordam (arte '%s')" % g.arte_id)
	var p_sem: float = sem.risco_tatica("defensive").chance
	var p_bx: float = bx.risco_tatica("defensive").chance
	var p_bj: float = bj.risco_tatica("defensive").chance
	checar(p_bx >= p_sem and p_bj >= p_sem, "o traço nunca piora a chance (%s / %s / %s)" % [p_sem, p_bx, p_bj])
	# Texto na prévia.
	checar_igual(sem.previa().art_fight_text, "", "sem arte: sem linha de traço")
	checar_igual(bx.previa().art_fight_text, "BOXE: +10% DE DANO", "prévia do Boxe")
	checar_igual(bj.previa().art_fight_text, "JIU-JITSU: -10% DE DANO RECEBIDO", "prévia do Jiu-jitsu")
	# A luta decidida usa o traço: recalcular da semente dá o mesmo resultado.
	bx.atributos = {"strength": 90000.0, "agility": 60000.0, "endurance": 500000.0}
	bx.lutar()
	var info: Dictionary = bx.luta_atual()
	checar_igual(info.result.win, bool(bx.luta.result.win), "luta salva = luta recalculada com o traço")
	# Honestidade: a chance da prévia bate com a frequência real de vitórias (mesmo motor, sementes diferentes).
	var vitorias := 0
	var n := 300
	for i in n:
		if bx.motor.lutar([90000.0, 60000.0, 500000.0], [82000.0, 61000.0, 515000.0], "defensive", 777 + i).win:
			vitorias += 1
	var chance: float = bx.motor.chance([90000.0, 60000.0, 500000.0], [82000.0, 61000.0, 515000.0], "defensive")
	checar(absf(float(vitorias) / n - chance) < 0.12, "chance da prévia honesta com o traço (%s x %s)" % [float(vitorias) / n, chance])
	for g in [sem, bx, bj]:
		_liberar(g)


func _teste_escada_da_academia() -> void:
	var gs := _com_cinturao("f5_escada")
	checar_igual(gs.proximo_adversario(), {}, "na garagem, depois do Muralha, o Tonhão não luta")
	checar(gs.precisa_mudar() and not gs.escada_completa(), "precisa mudar, e a escada não acabou")
	checar_igual(gs.estado_escada(), "move", "estado da escada: move")
	checar(not gs.pode_lutar() and gs.lutar() == {}, "lutar() recusa na garagem")
	checar_igual(gs.info_proxima().move, true, "info_proxima avisa que precisa mudar")
	checar(gs.cinturao, "cinturão = a escada passou do Muralha")
	var g0 := _novo("f5_escada_sem")
	g0.indice_escada = 3
	checar(not g0.cinturao and g0.proximo_adversario().id == "opp_tank", "antes de vencer o Muralha não há cinturão")
	gs.mudar()
	gs.escolher_arte("boxing")
	gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
	checar_igual(gs.estado_escada(), "fight", "na academia: luta")
	gs.dinheiro = 0.0
	gs.lutar()
	var r: Dictionary = gs.concluir_luta()
	checar(r.win and r.opponent == "opp_gym_1", "vence o Tonhão")
	checar_igual([gs.dinheiro, gs.fama, gs.indice_escada], [2500.0, 320, 5], "Tonhão paga $2.500 e 120 de Fama")
	checar_igual(r.next, "opp_gym_2", "o próximo é o Kid Navalha")
	gs.lutar()
	r = gs.concluir_luta()
	checar(r.win and r.opponent == "opp_gym_2", "vence o Kid")
	checar_igual([gs.dinheiro, gs.fama, gs.indice_escada], [8500.0, 520, 6], "Kid paga $6.000 e 200 de Fama")
	checar(gs.escada_completa() and gs.estado_escada() == "end" and not gs.pode_lutar(), "vencer o Kid: fim da escada")
	checar_igual(gs.proximo_adversario(), {}, "sem próximo adversário")
	checar_igual(gs.legado_em_jogo(), 1140, "pote 1.140 depois do Kid")
	checar_igual(gs.previa_aposentar().total, 1710, "aposentar com tudo vencido leva 1.710")
	# Derrota na academia leva metade do pote (design 7.3): no Tonhão 250, no Kid 370.
	var g2 := _na_academia("f5_escada_derrota", "bjj")
	checar_igual([g2.legado_em_jogo(), g2.previa_aposentar().total, g2.legado_se_perder()], [500, 750, 250],
		"cinturão: pote 500, aposentar 750, perder no Tonhão 250")
	g2.indice_escada = 5
	g2.fama = 320
	checar_igual([g2.legado_em_jogo(), g2.previa_aposentar().total, g2.legado_se_perder()], [740, 1110, 370],
		"depois do Tonhão: pote 740, aposentar 1.110, perder no Kid 370")
	var g3 := _na_academia("f5_escada_revanche", "bjj")
	# Revanche e "espere o verde" valem para os da academia (regras por adversário).
	g3.permanente["revenge_opponent"] = "opp_gym_2"
	checar(g3.esperar_verde("opp_gym_1", "hard") and g3.esperar_verde("opp_gym_2", "even"), "espere o verde vale para os da academia")
	for g in [gs, g0, g2, g3]:
		_liberar(g)


func _teste_estilo() -> void:
	var gs := _novo("f5_estilo")
	checar_igual(gs.arvore_ramos().map(func(b): return b.id), ["body", "career"], "sem artes liberadas a aba ESTILO some")
	gs.permanente["legacy_total"] = 5000
	gs.aposentar()
	var ids_sem: Array = gs.arvore_nos().map(func(n): return n.id)
	checar(not ("style_boxing" in ids_sem), "e os nós ESTILO não aparecem")
	checar_igual(gs.estado_no("style_boxing"), "locked", "nó ESTILO trancado sem a arte liberada")
	checar(not gs.comprar_no("style_boxing"), "e não se compra")
	var antes: int = gs.legado_disponivel()
	gs.permanente["arts_unlocked"] = ["boxing", "bjj"]
	checar_igual(gs.arvore_ramos().map(func(b): return b.id), ["body", "career", "style"], "com artes liberadas a aba ESTILO aparece")
	var estilo: Array = gs.arvore_nos().filter(func(n): return n.branch == "style")
	checar_igual(estilo.size(), 2, "2 nós na aba")
	checar_igual(estilo[0].art_only_text, "SÓ VALE JOGANDO DE BOXE", "texto 'só vale jogando de'")
	checar_igual(estilo[0].effect_text, "BOXE: BÔNUS DO CLIQUE CRESCE 50%", "texto do efeito")
	checar_igual(estilo[0].state, "buyable", "comprável com a arte e o Legado")
	checar(gs.comprar_no("style_boxing"), "compra Mão de sino")
	checar_igual(gs.legado_disponivel(), antes - 1200, "desconta 1.200 de Legado")
	checar(not gs.comprar_no("style_boxing"), "não compra duas vezes")
	checar_igual(gs.estilo_arte("boxing"), 0.0, "o efeito só vale a partir da NOVA CARREIRA")
	gs.nova_carreira()
	checar_igual([gs.estilo_arte("boxing"), gs.estilo_arte("bjj")], [0.5, 0.0], "efeito só na arte do nó")
	gs.escolher_arte("boxing")
	checar_igual(gs.bonus_arte_clique(), 0.75, "Boxe com o nó: +75%")
	checar_igual(gs.por_clique(), 1.75, "e o clique rende 1,75")
	checar_igual(gs.texto_regra_arte("boxing"), "+75% TREINO NO CLIQUE DA SUA MÃO", "a janela de arte já mostra o número com o nó")
	checar_igual(gs.texto_hud_arte(), "BOXE: +75% NO SEU CLIQUE", "HUD com o nó")
	# O nó do Boxe não afeta quem joga de Jiu-jitsu.
	var g2 := _com_arte("f5_estilo_bjj", "bjj")
	g2.permanente["skill_nodes"] = ["style_boxing"]
	g2._recalcular_bonus()
	g2.arte_segundos = 0.0
	checar_igual(g2.bonus_arte_equipe(), float(g2.academia.arte("bjj").rule.start), "nó do Boxe não muda o Jiu-jitsu")
	_liberar(g2)
	_liberar(gs)


func _teste_dica_de_aposentar() -> void:
	var gs := _na_academia("f5_dica", "bjj")
	gs.risco_hud_ativo = true
	gs.atributos = {"strength": 100.0, "agility": 100.0, "endurance": 100.0}  # nada contra o Tonhão: PERIGOSO
	gs.fama = 100
	checar(not gs.dica_aposentar().show, "no começo a dica não aparece")
	_passar(gs, 120.0)
	checar(not gs.dica_aposentar().show, "aos 2 min ainda não")
	_passar(gs, 190.0)
	var d: Dictionary = gs.dica_aposentar()
	checar(d.show and d.seconds >= 300.0, "depois de 5 min PERIGOSO a dica aparece")
	checar_igual(d.legacy, int(gs.previa_aposentar().total), "usa o mesmo cálculo de Legado da confirmação")
	checar_igual(d.text, "APOSENTAR AGORA LEVA %d DE LEGADO" % d.legacy, "texto da dica")
	# Ficar forte zera a contagem.
	gs.atributos = {"strength": 1.0e9, "agility": 1.0e9, "endurance": 1.0e9}
	_passar(gs, 3.0)
	checar(not gs.dica_aposentar().show, "sair do PERIGOSO apaga a dica")
	# Na garagem não há dica.
	var g2 := _novo("f5_dica_garagem")
	g2.risco_hud_ativo = true
	_passar(g2, 400.0)
	checar(not g2.dica_aposentar().show, "na garagem a dica não existe")
	_liberar(g2)
	_liberar(gs)


# --- Dados mudam o jogo ---

func _teste_dados_mudam_o_jogo() -> void:
	var pasta := pasta_limpa("f5_dados_json")
	escrever(pasta + "locations.json", '{"default_location":"garage","locations":[{"id":"garage","training_mult":1.0,"name":"G"},'
		+ '{"id":"gym","training_mult":3.0,"apparatus_suffix":"_gym","move":{"id":"move_gym","cost":400,"currency":"money","requires":"belt"},"name":"A"}]}')
	escrever(pasta + "arts.json", '{"arts":[{"id":"boxing","name":"Boxe","apparatus":"speed_bag","rule":{"type":"manual_click_bonus","value":1.0},'
		+ '"fight":{"damage_mult":1.3,"taken_mult":1.0},"rule_text":"+{pct}%","fight_text":"B +{pct}%"},'
		+ '{"id":"bjj","name":"J","apparatus":"grappling_dummy","rule":{"type":"crew_time_bonus","start":0.5,"per_minute":0.1,"cap":0.8},'
		+ '"fight":{"damage_mult":1.0,"taken_mult":0.8},"rule_text":"x","fight_text":"y"}]}')
	var ac := GymData.carregar(pasta + "locations.json", pasta + "arts.json")
	var gs := _novo("f5_dados_jogo", TrainingData.CAMINHO_TREINO, null, ac)
	gs.indice_escada = 4
	gs.cinturao = true
	gs.dinheiro = 399.0
	checar(not gs.mudar(), "preço do JSON: $399 não paga $400")
	gs.dinheiro = 400.0
	checar(gs.mudar() and gs.dinheiro == 0.0, "preço do JSON: $400 muda")
	checar_igual(gs.por_clique(), 3.0, "multiplicador do JSON: x3")
	gs.escolher_arte("boxing")
	checar_igual(gs.por_clique(), 3.0 * 2.0, "regra do Boxe do JSON: +100%")
	checar(absf(gs.tatica_efetiva("aggressive").damage_mult - 1.35 * 1.3) < 1e-9, "traço do JSON: +30% de dano")
	_liberar(gs)
	var gj := _novo("f5_dados_jj", TrainingData.CAMINHO_TREINO, null, ac)
	gj.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gj.escolher_arte("bjj")
	gj.geradores["neighbor_kid"] = 10
	gj.arte_segundos = 3600.0
	checar_igual(gj.producao_total(), 18.0, "teto do JSON: +80%")
	gj.arte_segundos = 0.0
	checar_igual(gj.producao_total(), 15.0, "começo do JSON: +50%")
	_liberar(gj)
	# Split e custo do aparelho no JSON de treino.
	var texto := ler(TrainingData.CAMINHO_TREINO)
	texto = texto.replace('"split": { "strength": 0.40, "agility": 0.45, "endurance": 0.15 }', '"split": { "strength": 1.0, "agility": 0.0, "endurance": 0.0 }')
	texto = texto.replace('"id": "unlock_speed_bag", "cost": 2500', '"id": "unlock_speed_bag", "cost": 100')
	escrever(pasta + "training.json", texto)
	var gt := _novo("f5_dados_treino", pasta + "training.json")
	gt.permanente["arts_unlocked"] = ["boxing", "bjj"]
	gt.escolher_arte("boxing")
	gt.aparelhos_montados_ids = ["punching_bag", "treadmill"]
	gt.treino = 100.0
	checar(gt.comprar_aparelho("speed_bag"), "custo do aparelho vem do JSON")
	gt.auto_socar()
	checar_igual(gt.atributos.strength, 1.0, "split do JSON: tudo na Força")
	_liberar(gt)
	# Adversário da academia no JSON.
	var op := ler(FightData.CAMINHO_ADVERSARIOS).replace('"strength": 390000', '"strength": 123')
	escrever(pasta + "opponents.json", op)
	var fd := FightData.carregar(FightData.CAMINHO_LUTAS, pasta + "opponents.json")
	checar_igual(fd.adversario("opp_gym_1").strength, 123.0, "atributos do Tonhão vêm do JSON")
	# Dado ruim: split que não soma 1 normaliza; location inexistente no save volta ao padrão.
	var ruim := ler(TrainingData.CAMINHO_TREINO).replace('"split": { "strength": 0.40, "agility": 0.45, "endurance": 0.15 }',
		'"split": { "strength": 2.0, "agility": 2.0, "endurance": 0.0 }')
	escrever(pasta + "ruim.json", ruim)
	var td := TrainingData.carregar(pasta + "ruim.json")
	checar_igual(td.aparelho("speed_bag").split, {"strength": 0.5, "agility": 0.5, "endurance": 0.0}, "split que não soma 1 é normalizado")
	var sem_split := ler(TrainingData.CAMINHO_TREINO).replace('"split": { "strength": 0.40, "agility": 0.45, "endurance": 0.15 },', "")
	escrever(pasta + "sem_split.json", sem_split)
	var td2 := TrainingData.carregar(pasta + "sem_split.json")
	checar(td2.aparelho("speed_bag").is_empty(), "aparelho sem attribute e sem split é ignorado")


# --- Save v6 ---

func _teste_save_v6() -> void:
	checar_igual(SaveStore.VERSAO_ATUAL, 7, "versão do save é 7 (Fase 5.1)")
	var gs := _na_academia("f5_save", "bjj")
	gs.geradores["neighbor_kid"] = 3
	_passar(gs, 12.0)
	gs.salvar()
	var doc = JSON.parse_string(ler(gs.store.caminho()))
	var c: Dictionary = doc.state.career
	checar_igual([int(doc.version), c.location, c.art, absf(float(c.art_seconds) - 12.0) < 1e-6], [7, "gym", "bjj", true], "career.location, art e art_seconds no arquivo")
	checar_igual([doc.state.permanent.arts_unlocked, doc.state.permanent.last_art], [["boxing", "bjj"], "bjj"], "permanent.arts_unlocked e last_art no arquivo")
	var g2: Node = GameStateScript.new()
	g2.inicializar(gs.store.pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar_igual([g2.local_id, g2.arte_id, absf(g2.arte_segundos - 12.0) < 1e-6, g2.artes_liberadas(), g2.permanente.last_art, g2.avisos.size()],
		[ "gym", "bjj", true, ["boxing", "bjj"], "bjj", 0], "recarregar mantém tudo, sem avisos")
	# Fim de carreira pendente com arte no resumo.
	gs.aposentar()
	var g3: Node = GameStateScript.new()
	g3.inicializar(gs.store.pasta, "res://data/config.json")
	g3.autosave_ativo = false
	checar_igual(g3.fim.summary.art, "bjj", "ending.summary.art salvo")
	checar(not g3.escolha_arte_pendente(), "com a tela de fim pendente não pede a arte")
	# Cadeia v0 -> v7.
	var g4: Node = GameStateScript.new()
	var pasta := pasta_limpa("f5_cadeia")
	escrever(pasta + "save.json", '{"treino": 77}')
	g4.inicializar(pasta, "res://data/config.json")
	g4.autosave_ativo = false
	checar_igual([g4.treino, g4.local_id, g4.arte_id, g4.artes_liberadas()], [77.0, "garage", "", []], "v0 -> v7 em cadeia")
	g4.salvar()
	checar_igual(int(JSON.parse_string(ler(pasta + "save.json")).version), 7, "regravado como v7")
	for g in [gs, g2, g3, g4]:
		_liberar(g)


func _teste_migracao_v5() -> void:
	var base := '{"version": 5, "saved_at_unix": 1730000000, "state": {"career": {"metronome_level": 1, "apparatus_owned": ["punching_bag", "jump_rope", "treadmill"], '
	base += '"training": 5000, "attributes": {"strength": 900, "agility": 200, "endurance": 134}, "focus": "treadmill", "generators": {"neighbor_kid": 7, "retired_uncle": 1}, '
	base += '"upgrades": {"punching_bag": 1}, "paid_generators": {"gen_paid_1": 2}, "glove_level": 2, "money": %s, "fame": 200, "ladder_index": %d, "belt": %s, '
	base += '"tactic": "counter", "play_seconds": 1800, "money_earned": 2000, "fight": null}, '
	base += '"permanent": {"legacy_total": 300, "career_number": 3, "careers_finished": 2, "best_wins": 4, "belts_won": 1, "skill_nodes": ["body_jab"], "revenge_opponent": ""}, "ending": null}}'
	# Carreira em andamento sem cinturão: segue na garagem, sem arte, sem mexer no dinheiro.
	var pasta := pasta_limpa("f5_mig_andamento")
	escrever(pasta + "save.json", base % ["30", 2, "false"])
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	checar_igual([gs.local_id, gs.arte_id, gs.arte_segundos, gs.artes_liberadas(), gs.permanente.last_art], ["garage", "", 0.0, [], ""],
		"v5 -> v6: garagem, sem arte, nenhuma arte liberada")
	checar_igual([gs.dinheiro, gs.indice_escada, gs.cinturao, gs.treino, gs.foco, gs.nivel_luva, gs.nivel_metronomo, gs.tatica, gs.fama,
		gs.quantidade_gerador("neighbor_kid"), gs.nivel_melhoria("punching_bag"), gs.tempo_jogo, gs.nos_comprados(), gs.numero_carreira()],
		[30.0, 2, false, 5000.0, "treadmill", 2, 1, "counter", 200, 7, 1, 1800.0, ["body_jab"], 3], "v5 -> v6: nada se perde")
	checar(not gs.escolha_arte_pendente() and gs.avisos.is_empty(), "sem artes liberadas não há escolha e não há avisos")
	_liberar(gs)
	# Cinturão e $0: ganha os $1.000 e vê o MUDAR.
	var p2 := pasta_limpa("f5_mig_cinturao")
	escrever(p2 + "save.json", base % ["0", 4, "true"])
	var g2: Node = GameStateScript.new()
	g2.inicializar(p2, "res://data/config.json")
	g2.autosave_ativo = false
	checar_igual([g2.dinheiro, g2.cinturao, g2.local_id, g2.estado_mudanca(), g2.precisa_mudar()], [1000.0, true, "garage", "ready", true],
		"v5 com cinturão e $0: $1.000 e o MUDAR")
	checar(g2.mudar(), "e dá para mudar")
	_liberar(g2)
	# Cinturão com dinheiro de sobra: não mexe.
	var p3 := pasta_limpa("f5_mig_cinturao_rico")
	escrever(p3 + "save.json", base % ["5000", 4, "true"])
	var g3: Node = GameStateScript.new()
	g3.inicializar(p3, "res://data/config.json")
	g3.autosave_ativo = false
	checar_igual(g3.dinheiro, 5000.0, "v5 com cinturão e $5.000: dinheiro intacto")
	_liberar(g3)
	# Sem cinturão e sem dinheiro: continua sem.
	var p4 := pasta_limpa("f5_mig_sem")
	escrever(p4 + "save.json", base % ["0", 3, "false"])
	var g4: Node = GameStateScript.new()
	g4.inicializar(p4, "res://data/config.json")
	g4.autosave_ativo = false
	checar_igual([g4.dinheiro, g4.cinturao], [0.0, false], "v5 sem cinturão e $0: continua $0")
	_liberar(g4)


func _teste_validacoes() -> void:
	var gs := _novo("f5_valida")
	# Local inexistente.
	gs.aplicar_save({"career": {"location": "lixo", "art": "", "art_seconds": 5}, "permanent": {}})
	checar_igual(gs.local_id, "garage", "local inexistente -> garagem")
	checar(not gs.avisos.is_empty(), "e avisa")
	# Arte fora das liberadas.
	gs.aplicar_save({"career": {"art": "boxing", "art_seconds": 99}, "permanent": {"arts_unlocked": []}})
	checar_igual([gs.arte_id, gs.arte_segundos], ["", 0.0], "arte fora de arts_unlocked -> sem arte, relógio 0")
	gs.aplicar_save({"career": {"art": "muay_thai"}, "permanent": {"arts_unlocked": ["boxing", "bjj"]}})
	checar_igual(gs.arte_id, "", "arte inexistente -> sem arte")
	checar(gs.escolha_arte_pendente(), "carreira viva sem arte e com artes liberadas abre a janela")
	# art_seconds inválido.
	gs.aplicar_save({"career": {"art": "bjj", "art_seconds": -5}, "permanent": {"arts_unlocked": ["boxing", "bjj"]}})
	checar_igual(gs.arte_segundos, 0.0, "art_seconds negativo -> 0")
	gs.aplicar_save({"career": {"art": "bjj", "art_seconds": "x"}, "permanent": {"arts_unlocked": ["boxing", "bjj"]}})
	checar_igual(gs.arte_segundos, 0.0, "art_seconds inválido -> 0")
	# Lista de artes: inexistente e repetida ignoradas; last_art inválida.
	gs.aplicar_save({"career": {}, "permanent": {"arts_unlocked": ["boxing", "boxing", "x", 5], "last_art": "x"}})
	checar_igual([gs.artes_liberadas(), gs.permanente.last_art], [["boxing"], ""], "arts_unlocked sem repetida/inexistente; last_art inválida -> ''")
	# Aparelho de outra arte, melhorias e foco.
	gs.aplicar_save({"career": {"art": "boxing", "apparatus_owned": ["punching_bag", "treadmill", "grappling_dummy", "speed_bag"],
		"upgrades": {"grappling_dummy": 2, "speed_bag": 1}, "focus": "grappling_dummy"}, "permanent": {"arts_unlocked": ["boxing", "bjj"]}})
	checar_igual(gs.aparelhos_montados(), ["punching_bag", "treadmill", "speed_bag"], "aparelho de outra arte sai do save")
	checar_igual([gs.nivel_melhoria("grappling_dummy"), gs.nivel_melhoria("speed_bag"), gs.foco], [0, 1, "punching_bag"], "técnicas dele zeram e o foco volta ao padrão")
	# Aparelho de arte sem arte escolhida.
	gs.aplicar_save({"career": {"apparatus_owned": ["punching_bag", "speed_bag"]}, "permanent": {}})
	checar_igual(gs.aparelhos_montados(), ["punching_bag"], "aparelho de arte sem arte escolhida sai")
	# Escada além do 1º da academia, na garagem (save editado).
	gs.aplicar_save({"career": {"ladder_index": 5, "location": "garage"}, "permanent": {}})
	checar_igual([gs.local_id, gs.cinturao, gs.proximo_adversario().id], ["gym", true, "opp_gym_2"], "escada na academia move a carreira para lá")
	# Escada em 4 na garagem é legítima (precisa mudar).
	gs.aplicar_save({"career": {"ladder_index": 4, "location": "garage"}, "permanent": {}})
	checar_igual([gs.local_id, gs.cinturao, gs.precisa_mudar()], ["garage", true, true], "escada em 4 na garagem: cinturão e MUDAR")
	# Luta pendente do Tonhão na garagem é descartada.
	gs.aplicar_save({"career": {"ladder_index": 4, "location": "garage", "fight": {"opponent": "opp_gym_1", "tactic": "defensive", "seed": 1,
		"player": {"strength": 1, "agility": 1, "endurance": 1}, "result": {"win": true}}}, "permanent": {}})
	checar(gs.luta.is_empty(), "luta do Tonhão pendente na garagem é descartada")
	# Resumo do fim sem arte vale "".
	gs.aplicar_save({"career": {}, "permanent": {}, "ending": {"kind": "retire", "summary": {"wins": 1}}})
	checar_igual(gs.fim.summary.art, "", "ending.summary.art ausente vale ''")
	_liberar(gs)


func _teste_textos() -> void:
	var gs := _na_academia("f5_textos", "boxing")
	var m: Dictionary = {}
	gs.apagar_save()
	var g := _com_cinturao("f5_textos_mudanca")
	m = g.mudanca()
	checar_igual([m.title, m.effect_text, m.keeps_text, m.per_career_text, m.state], ["ACADEMIA BOA ESQUINA", "TREINO x2 / 2 LUTAS DA CASA",
		"TUDO O QUE VOCÊ COMPROU VAI JUNTO", "VALE ATÉ O FIM DESTA CARREIRA", "ready"], "textos da mudança")
	checar_igual(g.info_proxima().move, true, "bloco PRÓXIMA sabe que precisa mudar")
	checar_igual(g.texto_ui("hud_next_move"), "PRÓXIMA: MUDE PARA A ACADEMIA", "texto do HUD antes de mudar")
	# Dicas extras de fim.
	var gd := _na_academia("f5_dica_extra", "boxing")
	gd.indice_escada = 4
	gd.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
	gd.lutar()
	gd.luta["result"]["win"] = false
	gd.concluir_luta()
	var tf: Dictionary = gd.textos_fim()
	checar(tf.tip_extra in gd.lista_ui("tip_gym_loss"), "derrota na academia: dica da casa")
	var gr := _com_cinturao("f5_dica_retire")
	gr.aposentar()
	checar(gr.textos_fim().tip_extra in gr.lista_ui("tip_move_belt"), "aposentou com o cinturão sem mudar: dica da mudança")
	# N4: quem já mudou para a academia e se aposenta sem lutar lá não recebe a dica da mudança.
	var gm := _na_academia("f5_dica_retire_gym", "boxing")
	gm.aposentar()
	checar(not (gm.textos_fim().tip_extra in gm.lista_ui("tip_move_belt")), "aposentou já na academia: sem dica da mudança")
	for x in [gs, g, gd, gr, gm]:
		_liberar(x)
