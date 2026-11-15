extends "res://tests/test_base.gd"
## Testa o carregador de dados da Fase 3 (data/fights|opponents|shop|career.json): valores reais, padrões,
## campos inválidos e "mudar o número no JSON muda o jogo" (critério 25).

const GameStateScript := preload("res://scripts/game_state.gd")


func rodar_testes() -> void:
	_teste_dados_reais()
	_teste_textos_existem()
	_teste_arquivos_ausentes_ou_ruins()
	_teste_campos_invalidos()
	_teste_mudar_dado_muda_o_jogo()


func _teste_dados_reais() -> void:
	var d := FightData.carregar()
	checar_igual(d.adversarios.size(), 6, "6 adversários (4 da garagem + 2 da academia)")
	checar_igual(d.adversarios.map(func(a: Dictionary) -> String: return a.id),
		["opp_warmup", "opp_strong", "opp_fast", "opp_tank", "opp_gym_1", "opp_gym_2"], "ordem da escada")
	var dudu := d.adversario("opp_warmup")
	checar_igual([dudu.strength, dudu.agility, dudu.endurance], [1200.0, 100.0, 800.0], "Dudu 1.20K / 100 / 800")
	checar_igual([dudu.prize_money, dudu.prize_fame, dudu.belt], [50.0, 10.0, false], "Dudu: $50, 10 de fama")
	var muralha := d.adversario("opp_tank")
	checar_igual([muralha.strength, muralha.agility, muralha.endurance], [82000.0, 61000.0, 515000.0], "Seu Muralha")
	checar_igual([muralha.prize_money, muralha.prize_fame, muralha.belt], [2500.0, 100.0, true], "Seu Muralha: $2.500, 100, cinturão")
	for a in d.adversarios:
		checar(a.name != a.id and a.description != "" and a.profile != "" and a.entry != "", "%s tem textos" % a.id)
	checar_igual(d.adversario("opp_strong").name, "Brutão do Posto", "nome do Brutão")
	checar_igual(d.taticas.size(), 3, "3 táticas")
	checar_igual(d.tatica_padrao, "defensive", "tática padrão")
	checar_igual(d.tatica("aggressive").damage_mult, 1.35, "agressivo: +35% de dano")
	checar_igual(d.tatica("defensive").crit_guard, 1.0, "defensivo anula o crítico dele")
	checar_igual(d.tatica("counter").counter_mult, 1.0, "contra-ataque devolve golpe")
	checar_igual(d.tatica("counter").dodge_mult, 2.0, "contra-ataque dobra a esquiva")
	checar(d.tatica("defensive").block and not d.tatica("counter").block, "só o defensivo bloqueia")
	checar_igual(d.combate.general_share, 0.10, "10% do treino conta em cada atributo")
	checar_igual(d.combate.time_limit, 16.0, "limite de 16 s")
	checar_igual(d.combate.min_ko_time, 5.0, "K.O. mínimo 5 s")
	checar_igual(d.risco.samples, 200, "200 sementes")
	checar_igual([d.risco.easy_min, d.risco.even_min], [0.90, 0.40], "limiares 0.90 / 0.40")
	checar_igual(d.motivo.search_steps, 14, "busca binária em 14 passos")
	checar_igual(d.geradores_pagos.size(), 1, "1 gerador pago")
	var nelson := d.gerador_pago("gen_paid_1")
	checar_igual([nelson.base_cost, nelson.growth, nelson.production], [50.0, 1.6, 25.0], "Nelson: $50, x1.6, +25/s")
	checar_igual(nelson.draw_thresholds, [1, 4], "Nelson: pessoas em 1 e 4")
	checar_igual(nelson.name, "Prof. Nelson", "nome do Nelson")
	checar_igual(d.luvas.size(), 4, "4 níveis de luva (L3 e L4 na Fase 5.2)")
	checar_igual([d.luvas[2].id, d.luvas[3].id], ["glove_l3", "glove_l4"], "L3 e L4 na ordem")
	checar_igual([d.luvas[0].id, d.luvas[0].cost, d.luvas[0].click_multiplier], ["glove_l1", 120.0, 2.0], "lona $120 x2")
	checar_igual([d.luvas[1].id, d.luvas[1].cost, d.luvas[1].click_multiplier], ["glove_l2", 500.0, 2.0], "couro $500 x2")
	checar_igual(d.luva_base.id, "glove_old", "luva velha é o nível 0")
	checar_igual(d.carreira, {"legacy_per_fame": 2.0, "belt_legacy_bonus": 100.0, "defeat_share": 0.5, "retire_share": 1.0,
		"retire_belt_bonus_share": 0.5, "gym_retire_hint_seconds": 300.0}, "Legado")


# Todos os textos do Roteirista que a UI vai pedir existem.
func _teste_textos_existem() -> void:
	var ui: Dictionary = TrainingData.carregar().ui
	var chaves := ["tactic_label", "preview_title", "preview_him", "preview_you", "risk_easy", "risk_even", "risk_hard",
		"risk_label", "fight_button", "back_button", "lead_strength", "lead_agility", "lead_endurance", "stake_win",
		"stake_belt", "stake_lose", "time_rule", "time_rule_tie", "fight_dodge", "fight_crit", "fight_ko", "fight_points",
		"fight_round", "fight_time", "victory_title", "victory_gain", "victory_next", "belt_title", "belt_line",
		"belt_unlock", "belt_hint", "no_more_fights", "end_defeat_title", "end_who_ko", "end_who_points",
		"reason_strength", "reason_agility", "reason_endurance", "tip_strength", "tip_agility", "tip_endurance",
		"tip_tactic", "sum_title", "sum_wins", "sum_belts", "sum_fame", "sum_money", "sum_time", "sum_legacy_gain",
		"sum_legacy_total", "legacy_note", "new_career_button", "retire_button", "retire_confirm_title",
		"retire_confirm_take", "retire_confirm_bonus", "retire_confirm_zero", "retire_confirm_lose", "retire_yes",
		"retire_no", "retire_title", "retire_line", "retire_line_belt", "shop_title", "shop_sub", "shop_buy",
		"shop_hire", "shop_no_money", "hud_money", "hud_fame", "hud_legacy_run", "hud_career", "hud_next_fight",
		"hud_legacy_total"]
	var faltam: Array = []
	for k in chaves:
		if not ui.has(k) or str(ui[k]) == "":
			faltam.append(k)
	checar_igual(faltam, [], "todas as %d chaves de texto da Fase 3 existem em ui_texts.json" % chaves.size())
	checar_igual(ui.reason_agility.size(), 4, "Agilidade: 4 modelos de motivo")
	checar(ui.reason_strength[0].begins_with("FALTARAM") and ui.reason_strength[1].begins_with("FALTARAM"),
		"modelos 1 e 2 de motivo são os 'FALTARAM'")
	checar(not ui.reason_strength[2].begins_with("FALTARAM"), "modelo 3 é a estatística da luta")


func _teste_arquivos_ausentes_ou_ruins() -> void:
	var pasta := pasta_limpa("f3_dados_ruins")
	var d := FightData.carregar(pasta + "a.json", pasta + "b.json", pasta + "c.json", pasta + "d.json")
	checar_igual(d.adversarios.size(), 4, "arquivo ausente: 4 adversários padrão")
	checar_igual(d.adversario("opp_strong").strength, 27000.0, "arquivo ausente: Brutão padrão")
	checar_igual(d.taticas.size(), 3, "arquivo ausente: táticas padrão")
	checar_igual(d.combate.attack_interval, 1.8, "arquivo ausente: combate padrão")
	checar_igual(d.luvas.size(), 4, "arquivo ausente: luvas padrão")
	checar_igual(d.geradores_pagos[0].base_cost, 50.0, "arquivo ausente: Nelson padrão")
	checar_igual(d.carreira.defeat_share, 0.5, "arquivo ausente: Legado padrão")
	escrever(pasta + "lixo.json", "{isso não é json")
	var d2 := FightData.carregar(pasta + "lixo.json", pasta + "lixo.json", pasta + "lixo.json", pasta + "lixo.json")
	checar_igual(d2.adversarios.size(), 4, "JSON inválido: adversários padrão")
	checar_igual(d2.tatica_padrao, "defensive", "JSON inválido: tática padrão")


func _teste_campos_invalidos() -> void:
	var pasta := pasta_limpa("f3_campos_ruins")
	escrever(pasta + "fights.json", '{"combat": {"life_base": -5, "time_limit": 3, "min_ko_time": 9, "crit_base": 7, "attack_interval": 0}, '
		+ '"tactics": [{"id": "aggressive", "damage_mult": -2, "pierce": 5}, {"id": "aggressive"}, {"id": ""}, {"id": "so_nome"}], '
		+ '"default_tactic": "nao_existe", "risk": {"samples": 5, "easy_min": 0.2, "even_min": 0.5}}')
	escrever(pasta + "opponents.json", '{"opponents": [{"id": "x", "strength": "lixo", "agility": -3, "prize_money": 9}, {"id": "x"}, {"id": ""}]}')
	escrever(pasta + "shop.json", '{"paid_generators": [{"id": "g", "base_cost": 0, "growth": 0.5, "draw_thresholds": [3, 1]}], '
		+ '"gloves": {"levels": [{"id": "l", "cost": -1, "click_multiplier": 0.3}]}}')
	escrever(pasta + "career.json", '{"defeat_share": 0.9, "retire_share": 0.5, "legacy_per_fame": "x"}')
	var d := FightData.carregar(pasta + "fights.json", pasta + "opponents.json", pasta + "shop.json", pasta + "career.json")
	checar_igual(d.combate.life_base, 100.0, "combate: valor negativo = padrão")
	checar_igual(d.combate.crit_base, 0.05, "combate: chance > 1 = padrão")
	checar_igual(d.combate.attack_interval, 1.8, "combate: intervalo 0 = padrão")
	checar(d.combate.time_limit > d.combate.min_ko_time, "tempos incoerentes voltam ao padrão")
	checar_igual(d.taticas.size(), 2, "tática repetida ou sem id ignorada")
	checar_igual(d.tatica("aggressive").damage_mult, 1.0, "tática: multiplicador negativo = 1")
	checar_igual(d.tatica("aggressive").pierce, 0.0, "tática: pierce fora de 0..1 = 0")
	checar_igual(d.tatica("so_nome").counter_mult, 0.0, "tática: counter_mult ausente = 0")
	checar_igual(d.tatica_padrao, "aggressive", "default_tactic inexistente = padrão válido (defensive não existe: a primeira)")
	checar_igual(d.risco.samples, 200, "risk.samples fora de 20..2000 = 200")
	checar(d.risco.easy_min > d.risco.even_min, "limiares incoerentes voltam ao padrão")
	checar_igual(d.adversarios.size(), 1, "adversário repetido ou sem id ignorado")
	checar_igual(d.adversarios[0].strength, 0.0, "atributo inválido = padrão (0 para id desconhecido)")
	checar_igual(d.adversarios[0].agility, 0.0, "atributo negativo = padrão")
	checar_igual(d.adversarios[0].prize_money, 9.0, "prêmio válido mantido")
	checar_igual(d.geradores_pagos[0].base_cost, 50.0, "gerador pago: custo 0 = padrão")
	checar_igual(d.geradores_pagos[0].growth, 1.6, "gerador pago: growth < 1 = padrão")
	checar_igual(d.geradores_pagos[0].draw_thresholds, [1], "gerador pago: limites inválidos = [1]")
	checar_igual(d.luvas[0].cost, 120.0, "luva: custo negativo = padrão do id (desconhecido: 120)")
	checar_igual(d.luvas[0].click_multiplier, 2.0, "luva: multiplicador < 1 = padrão")
	checar(d.carreira.defeat_share < d.carreira.retire_share, "defeat_share >= retire_share volta ao padrão")
	checar_igual(d.carreira.legacy_per_fame, 2.0, "legacy_per_fame inválido = padrão")


# Critério 25: mudar o prêmio ou um atributo de adversário no JSON e reabrir muda o jogo.
func _teste_mudar_dado_muda_o_jogo() -> void:
	var pasta := pasta_limpa("f3_dado_muda")
	var texto := ler("res://data/opponents.json").replace('"prize_money": 50,', '"prize_money": 777,') \
		.replace('"strength": 1200,', '"strength": 5.0e9,')
	escrever(pasta + "opponents.json", texto)
	var d := FightData.carregar("res://data/fights.json", pasta + "opponents.json")
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta + "save/", "res://data/config.json", TrainingData.CAMINHO_TREINO, TrainingData.CAMINHO_GERADORES,
		TrainingData.CAMINHO_TEXTOS, d)
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.atributos = {"strength": 1.0e7, "agility": 1.0e7, "endurance": 1.0e7}
	checar_igual(gs.proximo_adversario().strength, 5.0e9, "o atributo do adversário veio do JSON")
	gs.lutar()
	checar(not gs.luta.result.win, "o Dudu de 5 bilhões de Força vence quem tem 10 milhões")
	gs.luta = {}
	gs.atributos = {"strength": 1.0e11, "agility": 1.0e11, "endurance": 1.0e11}
	gs.lutar()
	gs.concluir_luta()
	checar_igual(gs.dinheiro, 777.0, "o prêmio veio do JSON")
	gs.free()
