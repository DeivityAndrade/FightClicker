extends "res://tests/test_base.gd"
## QA 5.3: cenarios extras (datas das 6 lutas, delta gigante, Tonhao na garagem, avisos, dica, migracao e fight_day corrompido).
## Tudo em user://test/. Roda: godot --headless --path . --script res://tests/qa_f53_extra.gd

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


func _lib(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func rodar_testes() -> void:
	_datas_das_6_lutas()
	_delta_gigante_nunca_pula()
	_tonhao_na_garagem()
	_avisos_reabrir()
	_dica()
	_corrompido()
	_migracao()
	_dia_30s()
	_save_real_copia()


func _dia_30s() -> void:
	var g := _novo("qa53_dia")
	g.tick(29.9)
	checar_igual(g.dia_campanha(), 1, "29,9 s = Dia 1")
	g.tick(0.1)
	checar_igual(g.dia_campanha(), 2, "30,0 s = Dia 2")
	g.tick(30.0 * 2 - 0.05)
	checar_igual(g.dia_campanha(), 3, "89,95 s = Dia 3")
	_lib(g)


func _datas_das_6_lutas() -> void:
	var g := _novo("qa53_datas")
	var esperado := [12, 13, 10, 16, 24, 16]
	var obtido := []
	var dia_base := 5
	g.segundos_campanha = float(dia_base - 1) * 30.0
	for i in 6:
		g.indice_escada = i
		g.local_id = "garage" if i < 4 else "gym"
		obtido.append(g._data_da_proxima_luta() - g.dia_campanha())
	checar_igual(obtido, esperado, "folga das 6 lutas (dias depois da luta anterior)")
	# Fluxo real: vence as 4 amadoras com tempo andando entre elas
	var g2 := _novo("qa53_datas2")
	g2.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	var datas := [g2.fight_day]
	var dias := [g2.dia_campanha()]
	for i in 4:
		g2.tick(31.0)  # +1 dia
		dias.append(g2.dia_campanha())
		g2.lutar()
		g2.concluir_luta()
		datas.append(g2.fight_day)
	# Dudu 1+12, depois dia+13 (Brutao), +10, +16, e o cinturao -> Tonhao +24
	checar_igual(datas[0], 13, "data do Dudu = Dia 13")
	checar_igual(datas[1], dias[1] + 13, "data do Brutao = dia da luta + 13")
	checar_igual(datas[2], dias[2] + 10, "data do Dinho = dia da luta + 10")
	checar_igual(datas[3], dias[3] + 16, "data do Muralha = dia da luta + 16")
	print("  datas: ", datas, " dias de luta: ", dias, " indice=", g2.indice_escada, " local=", g2.local_id, " estado=", g2.estado_escada())
	_lib(g2)


func _delta_gigante_nunca_pula() -> void:
	var g := _novo("qa53_gigante")
	g.geradores[g.dados.geradores[0].id] = 10
	var alvo: float = float(g.fight_day - 1) * 30.0
	var avisos := []
	g.aviso_data.connect(func(d): avisos.append(d))
	g.tick(1.0e7)
	checar_igual(g.segundos_campanha, alvo, "tick(1e7): relogio para exatamente no dia")
	checar(g.no_dia_da_luta(), "tick gigante: dia da luta")
	print("  avisos com 1 tick gigante saindo do Dia 1: ", avisos)
	# varios deltas aleatorios incluindo 5-60 s (app minimizado/estrangulado)
	var g2 := _novo("qa53_gigante2")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var alvo2: float = float(g2.fight_day - 1) * 30.0
	var passou := false
	for i in 400:
		g2.tick(rng.randf_range(0.001, 90.0))
		if g2.segundos_campanha > alvo2 + 1e-6:
			passou = true
	checar(not passou, "deltas 0,001-90 s: nunca passa do dia")
	_lib(g)
	_lib(g2)


func _tonhao_na_garagem() -> void:
	# Tonhao com o jogador na garagem (cinturao sem mudar): o relogio nao trava
	var g := _novo("qa53_tonhao")
	g.indice_escada = 4
	g.cinturao = true
	g.local_id = "garage"
	g.fight_day = 1 + 24
	print("  estado_escada na garagem com Tonhao: ", g.estado_escada(), "  mudanca: ", g.estado_mudanca())
	g.tick(24.0 * 30.0 + 120.0)
	print("  segundos=", g.segundos_campanha, " dia=", g.dia_campanha(), " dias_para_luta=", g.dias_para_luta(), " no_dia=", g.no_dia_da_luta())
	checar(g.segundos_campanha > 24.0 * 30.0, "garagem com Tonhao: relogio segue (nao fica preso)")
	g.dinheiro = 1.0e9
	var pode: bool = g.pode_mudar()
	print("  pode_mudar=", pode)
	if pode:
		g.mudar()
		print("  depois de mudar: local=", g.local_id, " no_dia=", g.no_dia_da_luta(), " fight_day=", g.fight_day, " dia=", g.dia_campanha(), " arte pendente=", g.escolha_arte_pendente())
	_lib(g)


func _avisos_reabrir() -> void:
	for faltam in [4, 3, 2, 1]:
		var pasta := pasta_limpa("qa53_av%d" % faltam)
		var g := _reabrir(pasta)
		g.segundos_campanha = float(g.fight_day - faltam - 1) * 30.0 + 1.0
		g.salvar()
		g.free()
		var g3: Node = GameStateScript.new()
		var rec := []
		g3.aviso_data.connect(func(d): rec.append(d))
		g3.inicializar(pasta, "res://data/config.json")
		g3.autosave_ativo = false
		g3.tick(0.1)
		print("  reabrir com Faltam ", faltam, ": avisos=", rec, " dias_para_luta=", g3.dias_para_luta())
		# reabrir de novo, mesmo dia
		g3.free()
	# 1 aviso por data: 2 campanhas, avisos de 3 e 1 para cada data
	var gs := _novo("qa53_av_serie")
	var rec2 := []
	gs.aviso_data.connect(func(d): rec2.append([gs.fight_day, d]))
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	for luta in 2:
		var alvo: float = float(gs.fight_day - 1) * 30.0
		while gs.segundos_campanha < alvo - 0.01:
			gs.tick(1.0)
		gs.lutar()
		gs.concluir_luta()
	print("  avisos em 2 datas esperando o dia: ", rec2)
	checar_igual(rec2.size(), 4, "2 datas esperadas ate o dia = 4 avisos (3 e 1 por data)")
	_lib(gs)


func _dica() -> void:
	var g := _novo("qa53_dica")
	g.fama = 100
	g.risco_hud_ativo = false
	var res := {}
	for dias in [5, 4, 3, 2, 1, 0]:
		for rot in ["easy", "even", "hard"]:
			g.fight_day = 30
			g.segundos_campanha = float(30 - dias - 1) * 30.0 + 1.0
			g._definir_risco_hud(str(g.proximo_adversario().id), rot)
			res["%d_%s" % [dias, rot]] = bool(g.dica_aposentar().show)
	var so_certo := true
	for k in res:
		var partes: PackedStringArray = k.split("_")
		var esperado := int(partes[0]) <= 3 and partes[1] == "hard"
		if res[k] != esperado:
			so_certo = false
			print("  dica errada em ", k, ": ", res[k])
	checar(so_certo, "dica so aparece com Faltam <= 3 e vermelho")
	# pote 0
	g.fama = 0
	g._definir_risco_hud(str(g.proximo_adversario().id), "hard")
	checar(not bool(g.dica_aposentar().show), "pote 0: sem dica")
	# academia
	g.fama = 100
	g.indice_escada = 4
	g.cinturao = true
	g.local_id = "gym"
	g.fight_day = 30
	g.segundos_campanha = float(30 - 2 - 1) * 30.0 + 1.0
	g._definir_risco_hud(str(g.proximo_adversario().id), "hard")
	checar(bool(g.dica_aposentar().show), "academia: dica aparece no vermelho com 2 dias")
	# adversario do selo diferente do proximo: sem dica
	g._definir_risco_hud("opp_warmup", "hard")
	checar(not bool(g.dica_aposentar().show), "selo de outro adversario nao mostra dica")
	# no dia (0 dias): mostra? o design diz <=3 inclui 0
	_lib(g)


func _corrompido() -> void:
	var casos := {
		"string": "abc", "float": 12.7, "nan": NAN, "inf": INF, "neg": -3, "zero": 0, "menos1": -1,
		"enorme": 1.0e12, "bool": true, "nulo": null, "array": [1, 2], "dict": {"a": 1}, "999": 999, "1000": 1000, "1005": 1005,
	}
	for k in casos:
		var pasta := pasta_limpa("qa53_cor_" + k)
		var g := _reabrir(pasta)
		g.salvar()
		g.free()
		var doc = JSON.parse_string(ler(pasta + "save.json"))
		doc.state.career["fight_day"] = casos[k]
		var txt := JSON.stringify(doc) if typeof(casos[k]) != TYPE_FLOAT or is_finite(casos[k]) else ""
		if k == "nan":
			txt = ler(pasta + "save.json").replace('"fight_day": 13', '"fight_day": NaN')
		if k == "inf":
			txt = ler(pasta + "save.json").replace('"fight_day": 13', '"fight_day": Infinity')
		escrever(pasta + "save.json", txt)
		var g2 := _reabrir(pasta)
		var ok: bool = g2.fight_day == 13 or (k in ["float", "999", "1000"] and g2.fight_day > 0)
		print("  fight_day=", k, " -> ", g2.fight_day, " dias_para_luta=", g2.dias_para_luta(), " avisos=", g2.avisos.size())
		checar(g2.fight_day > 0 and g2.fight_day < 5000, "fight_day corrompido '%s' vira data valida (%d)" % [k, g2.fight_day])
		_lib(g2)
	# campaign_seconds corrompido
	for k2 in ["abc", -50, 1.0e18, true, null]:
		var pasta2 := pasta_limpa("qa53_cs")
		var g4 := _reabrir(pasta2)
		g4.salvar()
		g4.free()
		var doc2 = JSON.parse_string(ler(pasta2 + "save.json"))
		doc2.state.career["campaign_seconds"] = k2
		escrever(pasta2 + "save.json", JSON.stringify(doc2))
		var g5 := _reabrir(pasta2)
		print("  campaign_seconds=", k2, " -> ", g5.segundos_campanha, " dia=", g5.dia_campanha(), " fight_day=", g5.fight_day)
		checar(is_finite(g5.segundos_campanha) and g5.segundos_campanha >= 0.0, "campaign_seconds '%s' vira valor valido" % str(k2))
		_lib(g5)


func _migracao() -> void:
	# v8 com varios estados, sem perder nada
	var base_career := {"training": 1234.0, "ladder_index": 3, "glove_level": 2, "boxes": [{"item": "treadmill", "kind": "apparatus", "hits": 1}],
		"crew_click": true, "money": 555.0, "play_seconds": 900.0, "fame": 77, "metronome_level": 1}
	var perm := {"legacy_total": 321}
	var casos := {
		"andamento_idx3": {"career": base_career, "permanent": perm, "ending": null},
		"gym_idx4_gym": {"career": {"ladder_index": 4, "belt": true, "location": "gym", "art": "boxing"}, "permanent": {"arts_unlocked": ["boxing", "bjj"], "last_art": "boxing"}, "ending": null},
		"gym_idx4_garagem": {"career": {"ladder_index": 4, "belt": true, "location": "garage"}, "permanent": {}, "ending": null},
		"kid_vencido": {"career": {"ladder_index": 6, "belt": true, "location": "gym"}, "permanent": {}, "ending": null},
		"fim_pendente": {"career": {"ladder_index": 2}, "permanent": perm, "ending": {"kind": "defeat", "career_number": 1, "legacy_gained": 10, "legacy_total": 10, "opponent": "opp_fast", "tactic": "balanced", "summary": {"wins": 2, "belts": 0, "fame": 5, "money_earned": 1, "play_seconds": 5, "art": "", "location": "garage"}}},
	}
	for k in casos:
		var pasta := pasta_limpa("qa53_mig_" + k)
		escrever(pasta + "save.json", JSON.stringify({"version": 8, "saved_at_unix": 1730000000, "state": casos[k]}))
		var g := _reabrir(pasta)
		print("  mig ", k, ": dia=", g.dia_campanha(), " fight_day=", g.fight_day, " completa=", g.campanha_completa(), " idx=", g.indice_escada,
			" local=", g.local_id, " no_dia=", g.no_dia_da_luta(), " fim=", not g.fim.is_empty(), " avisos=", g.avisos, " legado=", g.permanente.get("legacy_total"))
		if k == "andamento_idx3":
			checar_igual([g.treino, g.nivel_luva, g.crew_click_comprado, g.dinheiro, g.fama, g.nivel_metronomo, g.caixas().size(), int(g.permanente.legacy_total)],
				[1234.0, 2, true, 555.0, 77, 1, 1, 321], "mig andamento: treino, luva, Grito, dinheiro, fama, Metronomo, caixa e Legado preservados")
			checar_igual([g.dia_campanha(), g.fight_day, g.dias_para_luta()], [1, 17, 16], "mig andamento: folga cheia do Muralha (16)")
			checar(not g.no_dia_da_luta(), "mig andamento: nao abre no dia")
		if k == "gym_idx4_gym":
			checar_igual(g.fight_day, 25, "mig academia: Tonhao com folga cheia (24)")
		if k == "kid_vencido":
			checar(g.campanha_completa() and g.fight_day == -1, "mig Kid vencido: campanha completa")
		if k == "fim_pendente":
			checar(not g.fim.is_empty() and g.fight_day == 13 and g.segundos_campanha == 0.0, "mig fim pendente: fim preservado, nova campanha data 13")
		_lib(g)


func _save_real_copia() -> void:
	# Copia (somente leitura) do save real do dono para pasta de teste: migra e confere
	var origem := SaveStore.PASTA_REAL + "save.json"
	if not FileAccess.file_exists(origem):
		print("  (sem save real para copiar)")
		return
	var pasta := pasta_limpa("qa53_real")
	escrever(pasta + "save.json", FileAccess.get_file_as_string(origem))
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	print("  save real (copia): version=", doc.get("version"))
	var g := _reabrir(pasta)
	print("  abriu: dia=", g.dia_campanha(), " fight_day=", g.fight_day, " idx=", g.indice_escada, " local=", g.local_id, " avisos=", g.avisos)
	checar(g.fight_day > 0, "save real (copia) abre com data valida")
	_lib(g)
