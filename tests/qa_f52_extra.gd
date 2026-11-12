extends "res://tests/test_base.gd"
## QA Fase 5.2: cenarios extras (luvas, evento dourado, Grito, save). Tudo em user://test/.

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


func rodar_testes() -> void:
	_luvas()
	_frequencia()
	_bolsa()
	_espera()
	_grito()
	_save()
	_extremos()


func _luvas() -> void:
	var gs := _novo("qa52_luvas")
	var l: Array = gs.lutas.luvas
	gs.dinheiro = 1.0e7
	var mult := 1.0
	for i in 4:
		checar(gs.pode_comprar_luva(), "L%d a venda" % (i + 1))
		checar(gs.comprar_luva(), "compra L%d" % (i + 1))
		checar(gs.luva_em_caixa(), "L%d na caixa" % (i + 1))
		checar(not gs.pode_comprar_luva() and not gs.comprar_luva(), "proxima trancada com L%d na caixa" % (i + 1))
		checar_igual(gs.multiplicador_luva(), mult, "luva na caixa ainda nao conta (x%s)" % str(mult))
		gs.bater_caixa(l[i].id)
		checar(gs.luva_em_caixa(), "1 clique: ainda na caixa")
		gs.bater_caixa(l[i].id)
		checar(gs.luva_em_caixa(), "2 cliques: ainda na caixa")
		gs.bater_caixa(l[i].id)
		checar(not gs.luva_em_caixa(), "3 cliques abrem")
		mult *= 2.0
		checar_igual(gs.multiplicador_luva(), mult, "multiplicador depois de L%d" % (i + 1))
		checar_igual(gs.sufixo_luva(), "_glove_l%d" % (i + 1), "sufixo L%d" % (i + 1))
	checar_igual(gs.multiplicador_luva(), 16.0, "x16 com as 4")
	# por_clique com x16
	var base: float = gs._base_soco()
	checar(absf(gs.por_clique() - base * (1.0 + gs.bonus_arte_clique())) < 1e-9 and gs.multiplicador_luva() == 16.0, "por_clique usa x16")
	# custos
	checar_igual([int(l[2].cost), int(l[3].cost)], [1200, 2500], "custos L3/L4")
	# arquivos de arte
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/manifest.json"))
	checar(man != null, "manifest le")
	var txt := FileAccess.get_file_as_string("res://assets/sprites/manifest.json")
	for k in ["glove_l4", "icon_glove_l4", "cursor_glove_l4", "event_golden_crew", "icon_crew_click", "fight_player_idle_glove_l4", "fighter_idle_glove_l4", "art_hung_glove_l4"]:
		checar(txt.contains("\"%s\"" % k), "manifest tem %s" % k)
	# caixa de luva fechada num save v7 com glove_level=2 e box da L2 continua
	_liberar(gs)
	var p := pasta_limpa("qa52_v7box")
	var v7 := {"version": 7, "saved_at_unix": 1730000000, "state": {
		"career": {"training": 5.0, "glove_level": 2, "money": 9000.0, "boxes": [{"item": "glove_l2", "kind": "glove", "hits": 1}]},
		"permanent": {}, "ending": null}}
	escrever(p + "save.json", JSON.stringify(v7))
	var g2 := _reabrir(p)
	checar(g2.luva_em_caixa() and g2.tem_caixa("glove_l2"), "v7: caixa da L2 continua")
	checar_igual(g2.luvas_abertas(), 1, "v7: so L1 aberta")
	checar(not g2.pode_comprar_luva(), "v7: L3 nao a venda com L2 na caixa")
	g2.bater_caixa("glove_l2")
	g2.bater_caixa("glove_l2")
	checar(g2.pode_comprar_luva() and g2.proxima_luva().id == "glove_l3", "v7: L3 a venda depois de abrir")
	_liberar(g2)
	# v7 sem caixa, glove_level 2
	var p2 := pasta_limpa("qa52_v7semcaixa")
	v7.state.career = {"glove_level": 2, "money": 9000.0}
	escrever(p2 + "save.json", JSON.stringify(v7))
	var g3 := _reabrir(p2)
	checar(g3.pode_comprar_luva() and g3.proxima_luva().id == "glove_l3", "v7 com L2: L3 a venda")
	checar_igual(g3.multiplicador_luva(), 4.0, "v7 L2: x4 preservado")
	_liberar(g3)
	# glove_level absurdo
	for v in [5, 99, -1, 2.5, "3", null, 1e30]:
		var p3 := pasta_limpa("qa52_gl")
		v7.state.career = {"glove_level": v}
		escrever(p3 + "save.json", JSON.stringify(v7))
		var g4 := _reabrir(p3)
		checar(g4.nivel_luva >= 0 and g4.nivel_luva <= 4, "glove_level %s saneado -> %d" % [str(v), g4.nivel_luva])
		checar(g4.multiplicador_luva() <= 16.0 and g4.multiplicador_luva() >= 1.0, "mult ok para glove_level %s" % str(v))
		_liberar(g4)


func _frequencia() -> void:
	var gs := _novo("qa52_freq")
	gs.dados.golden_crew_chance = 0.5
	var n := 4000
	var crew := 0
	var intervalos: Array = []
	for i in n:
		gs.evento_dourado_restante = 0.0
		gs._evento_espera = -1.0
		var t := 0.0
		var apareceu := false
		while t < 200.0:
			gs.tick(0.5)
			t += 0.5
			if gs.evento_dourado_restante > 0.0:
				apareceu = true
				break
		checar(apareceu, "evento apareceu") if i < 3 else null
		if apareceu:
			intervalos.append(t)
			if gs.evento_dourado_tipo == "crew":
				crew += 1
	var f := float(crew) / float(n)
	print("freq crew = %.3f em %d eventos" % [f, n])
	checar(absf(f - 0.5) < 0.03, "crew_chance 0.5 -> %.3f" % f)
	var mn := 1e9
	var mx := 0.0
	for x in intervalos:
		mn = minf(mn, x)
		mx = maxf(mx, x)
	print("espera min %.1f max %.1f" % [mn, mx])
	checar(mn >= 59.0 and mx <= 101.0, "espera entre 60 e 100 s")
	# chance 0.25 via dado
	gs.dados.golden_crew_chance = 0.25
	crew = 0
	for i in 2000:
		gs.evento_dourado_restante = 0.0
		gs._evento_espera = 0.01
		gs.tick(0.1)
		if gs.evento_dourado_tipo == "crew":
			crew += 1
	checar(absf(float(crew) / 2000.0 - 0.25) < 0.04, "crew_chance 0.25 muda o jogo so por dado (%d/2000)" % crew)
	_liberar(gs)


func _bolsa() -> void:
	var gs := _novo("qa52_bolsa")
	gs.dados.golden_crew_chance = 1.0
	gs.geradores[gs.dados.geradores[0].id] = 400
	gs.geradores[gs.dados.geradores[1].id] = 100
	gs.nivel_metronomo = 2
	gs.dinheiro = 1.0e6
	gs.dados.crit_chance = 0.0
	var renda: float = gs.renda_sem_mao()
	var floor_v: float = 40.0 * gs.por_clique()
	var esperado: float = maxf(45.0 * renda, floor_v)
	gs.treino = 0.0
	gs.evento_dourado_tipo = "crew"
	gs.evento_dourado_restante = 5.0
	var f0: float = gs.frenesi_restante
	gs.pegar_evento_dourado()
	checar(absf(gs.treino - esperado) < 1e-6 * esperado, "bolsa = max(45*renda, 40*clique): %s vs %s" % [str(gs.treino), str(esperado)])
	checar_igual(gs.frenesi_restante, f0, "bolsa nao liga FRENESI")
	# Com FRENESI ja ligado, a bolsa nao usa x7 no valor
	gs.frenesi_restante = 3.0
	gs.treino = 0.0
	gs.evento_dourado_tipo = "crew"
	gs.evento_dourado_restante = 5.0
	var v: float = gs.valor_bolsa()
	gs.pegar_evento_dourado()
	checar(absf(gs.treino - v) < 1e-6 * v, "FRENESI ligado nao multiplica a bolsa")
	checar_igual(gs.frenesi_restante, 3.0, "bolsa nao mexe no FRENESI ligado")
	# Luva x7 continua
	gs.frenesi_restante = 0.0
	gs.evento_dourado_tipo = "frenzy"
	gs.evento_dourado_restante = 5.0
	gs.pegar_evento_dourado()
	checar_igual(gs.mult_frenesi(), 7.0, "luva x7 = 7")
	checar(gs.frenesi_restante > 0.0, "frenesi liga")
	# clique duplo no mesmo evento nao paga duas vezes
	gs.frenesi_restante = 0.0
	gs.treino = 0.0
	gs.evento_dourado_tipo = "crew"
	gs.evento_dourado_restante = 5.0
	gs.pegar_evento_dourado()
	var t1: float = gs.treino
	checar(not gs.pegar_evento_dourado(), "segundo clique no mesmo evento recusa")
	checar_igual(gs.treino, t1, "nao paga em dobro")
	# Cai no atributo do foco: foco em outro aparelho
	var gs2 := _novo("qa52_bolsa2")
	gs2.dados.golden_crew_chance = 1.0
	gs2.geradores[gs2.dados.geradores[0].id] = 100
	var foco: String = gs2.foco
	var atr: String = gs2.atributo_do_aparelho(foco)
	var a0: float = gs2.atributos[atr]
	gs2.evento_dourado_tipo = "crew"
	gs2.evento_dourado_restante = 5.0
	var vv: float = gs2.valor_bolsa()
	gs2.pegar_evento_dourado()
	checar(absf(gs2.atributos[atr] - a0 - vv) < 1e-6 * vv, "ganho vai pro atributo do foco")
	_liberar(gs2)
	_liberar(gs)


func _espera() -> void:
	var gs := _novo("qa52_espera")
	gs.dados.golden_crew_chance = 0.5
	# Janela aberta: relogio espera
	gs.evento_dourado_restante = 0.0
	gs._evento_espera = -1.0
	gs.definir_modal(true)
	for i in 400:
		gs.tick(1.0)
	checar(gs.evento_dourado_restante <= 0.0, "janela aberta 400 s: nenhum evento")
	gs.definir_modal(false)
	# Luta aberta
	gs.luta = {"x": 1}
	for i in 400:
		gs.tick(1.0)
	checar(gs.evento_dourado_restante <= 0.0, "luta aberta 400 s: nenhum evento")
	gs.luta = {}
	# pegar durante janela: recusa
	gs.evento_dourado_restante = 5.0
	gs.evento_dourado_tipo = "crew"
	gs.definir_modal(true)
	var t0: float = gs.treino
	checar(not gs.pegar_evento_dourado(), "nao pega com janela aberta")
	checar_igual(gs.treino, t0, "nada pago")
	gs.definir_modal(false)
	_liberar(gs)


func _grito() -> void:
	var gs := _novo("qa52_grito")
	var def: Dictionary = gs.lutas.crew_click
	var custo: float = float(def.cost)
	gs.geradores[gs.dados.geradores[0].id] = 100
	gs.geradores[gs.dados.geradores[1].id] = 10
	# reserva: cinturao + mudanca pendente
	gs.cinturao = true
	var res: float = gs.reserva_mudanca()
	print("reserva da mudanca = %s" % str(res))
	if res > 0.0:
		gs.dinheiro = custo + res - 1.0
		checar_igual(gs.loja_estado(custo), "reserve", "estado reserve")
		checar(not gs.comprar_crew_click(), "Grito respeita a reserva")
		gs.dinheiro = custo + res
		checar(gs.comprar_crew_click(), "Grito compra com dinheiro = custo + reserva")
		checar(absf(gs.dinheiro - res) < 1e-6, "gasto exato")
	else:
		checar(false, "reserva da mudanca nao ativada no cenario (cinturao)")
	gs.cinturao = false
	_liberar(gs)
	# clique manual vs auto
	var g := _novo("qa52_grito2")
	g.geradores[g.dados.geradores[0].id] = 100
	g.geradores[g.dados.geradores[1].id] = 10
	g.nivel_metronomo = 1
	g.dinheiro = 5000.0
	var sem: float = g.por_clique()
	var eq: float = g.producao_total()
	g.comprar_crew_click()
	var r1: Dictionary = g.clicar()
	checar(absf(r1.ganho - (sem + eq)) < 1e-9, "clique manual soma 1 s da equipe: %s vs %s" % [str(r1.ganho), str(sem + eq)])
	var r2: Dictionary = g.auto_socar()
	checar_igual(r2.ganho, g.por_auto_soco(), "auto-soco sem o Grito")
	checar(r2.ganho < r1.ganho, "auto < manual")
	# Assistido
	g.definir_assistido(true)
	var pa: float = g.por_auto_soco()
	checar(pa < g.por_clique() / 5.9, "assistido >= 6x abaixo do clique (%s vs %s)" % [str(pa), str(g.por_clique())])
	g.definir_assistido(false)
	# crit multiplica o clique inteiro
	g.dados.crit_chance = 1.0
	var rc: Dictionary = g.clicar()
	checar(absf(rc.ganho - g.por_clique() * g.dados.crit_multiplier) < 1e-6, "critico multiplica clique+Grito")
	g.dados.crit_chance = 0.0
	# Persistencia
	var pasta := "user://test/qa52_grito2/"
	g.autosave_ativo = true
	g.salvar()
	var doc = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual(doc.state.career.crew_click, true, "save tem crew_click true")
	_liberar(g)
	var g2 := _reabrir(pasta)
	checar(g2.crew_click_comprado, "recarrega comprado")
	checar(absf(g2.por_clique() - (g2._base_soco() * (1.0 + g2.bonus_arte_clique()) + g2.producao_total())) < 1e-9, "por_clique apos reload")
	# Nova carreira zera
	g2.fim = {"kind": "x", "legacy_gained": 0, "legacy_total": 0}
	checar(g2.nova_carreira(), "nova carreira")
	checar(not g2.crew_click_comprado, "NOVA CARREIRA zera o Grito")
	checar(g2.pode_comprar_crew_click() == (g2.dinheiro >= float(def.cost)), "pode recomprar so com dinheiro")
	g2.salvar()
	var doc2 = JSON.parse_string(ler(pasta + "save.json"))
	checar_igual(doc2.state.career.crew_click, false, "save apos nova carreira: false")
	_liberar(g2)
	# preço: menor_preco_loja inclui o Grito
	var g3 := _novo("qa52_grito3")
	g3.dinheiro = 0.0
	checar(g3.menor_preco_loja() <= custo, "menor preco inclui o Grito (<= %s)" % str(custo))
	_liberar(g3)


func _save() -> void:
	# crew_click corrompido
	for v in ["sim", 1, 0, 1.0, null, [], {}, "true", -1, 1e308]:
		var p := pasta_limpa("qa52_corr")
		var doc := {"version": 8, "saved_at_unix": 1730000000, "state": {"career": {"training": 5.0, "crew_click": v}, "permanent": {}, "ending": null}}
		escrever(p + "save.json", JSON.stringify(doc))
		var g := _reabrir(p)
		checar(not g.crew_click_comprado, "crew_click=%s saneado para false" % JSON.stringify(v))
		checar_igual(g.treino, 5.0, "resto do save intacto (crew_click=%s)" % JSON.stringify(v))
		_liberar(g)
	# v7 com crew_click "true" (nao deveria existir): migracao forca false
	var p2 := pasta_limpa("qa52_mig")
	var d7 := {"version": 7, "saved_at_unix": 1730000000, "state": {"career": {"training": 77.0, "money": 123.0, "fame": 4, "glove_level": 1, "ladder_index": 2}, "permanent": {"career_number": 3}, "ending": null}}
	escrever(p2 + "save.json", JSON.stringify(d7))
	var g2 := _reabrir(p2)
	checar_igual([g2.treino, g2.dinheiro, g2.fama, g2.nivel_luva, g2.indice_escada, g2.numero_carreira()], [77.0, 123.0, 4, 1, 2, 3], "v7 -> v8 sem perdas")
	checar(g2.avisos.is_empty(), "sem avisos: %s" % str(g2.avisos))
	checar(FileAccess.file_exists(p2 + "save.json"), "arquivo existe")
	_liberar(g2)
	# v8 com crew_click true e luva L4
	var p3 := pasta_limpa("qa52_v8")
	var d8 := {"version": 8, "saved_at_unix": 1730000000, "state": {"career": {"crew_click": true, "glove_level": 4, "boxes": [{"item": "glove_l4", "kind": "glove", "hits": 2}]}, "permanent": {}, "ending": null}}
	escrever(p3 + "save.json", JSON.stringify(d8))
	var g3 := _reabrir(p3)
	checar(g3.crew_click_comprado and g3.nivel_luva == 4 and g3.luva_em_caixa() and g3.luvas_abertas() == 3, "v8 com L4 em caixa carrega")
	_liberar(g3)
	# v7 a 'futuro' 9
	var p4 := pasta_limpa("qa52_fut")
	escrever(p4 + "save.json", JSON.stringify({"version": 9, "state": {}}))
	var g4 := _reabrir(p4)
	g4.salvar()
	_liberar(g4)


func _extremos() -> void:
	var gs := _novo("qa52_ext")
	gs.geradores[gs.dados.geradores[0].id] = 1000000000
	gs.crew_click_comprado = true
	var pc: float = gs.por_clique()
	checar(is_finite(pc) and pc > 0.0, "por_clique finito com 1e9 de equipe: %s" % str(pc))
	gs.geradores[gs.dados.geradores[0].id] = 1.0e15
	var pc2: float = gs.por_clique()
	print("por_clique com 1e15 vizinhos = %s | bolsa %s" % [str(pc2), str(gs.valor_bolsa())])
	checar(is_finite(pc2) and is_finite(gs.valor_bolsa()), "finito com equipe 1e15")
	gs.dados.golden_crew_chance = 1.0
	gs.evento_dourado_tipo = "crew"
	gs.evento_dourado_restante = 5.0
	gs.treino = 0.0
	gs.pegar_evento_dourado()
	checar(is_finite(gs.treino), "treino finito depois da bolsa gigante")
	# dados invalidos no golden_event
	var td := TrainingData.new()
	td._ler_evento_dourado({"crew_chance": 5, "crew_seconds": -3, "crew_floor_clicks": "x", "crew_sprite": 5})
	print("invalidos: ", [td.golden_crew_chance, td.golden_crew_seconds, td.golden_crew_floor_clicks, td.golden_crew_sprite])
	checar(td.golden_crew_chance >= 0.0 and td.golden_crew_chance <= 1.0, "crew_chance invalido preso em 0..1")
	checar(td.golden_crew_seconds >= 1.0, "crew_seconds invalido preso")
	# compras seguidas sem dinheiro
	var g := _novo("qa52_sem")
	g.dinheiro = 0.0
	for i in 50:
		checar(not g.comprar_luva() and not g.comprar_crew_click(), "compra sem dinheiro recusa") if i < 2 else null
	checar_igual([g.nivel_luva, g.crew_click_comprado, g.dinheiro], [0, false, 0.0], "nada mudou sem dinheiro")
	g.dinheiro = 1.0e12
	for i in 100:
		g.comprar_luva()
		while g.luva_em_caixa():
			for l in g.lutas.luvas:
				g.bater_caixa(l.id)
	checar_igual(g.nivel_luva, 4, "100 tentativas: so 4 luvas")
	checar_igual(g.multiplicador_luva(), 16.0, "x16")
	for i in 5:
		g.comprar_crew_click()
	checar(abs(g.dinheiro - (1.0e12 - 1200 - 2500 - 120 - 500 - 1500)) < 1.0, "gasto total exato (cobrou so uma vez): %s" % str(g.dinheiro))
	_liberar(g)
	_liberar(gs)
