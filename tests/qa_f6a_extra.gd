extends "res://tests/test_base.gd"
## QA Fase 6a: cenarios extra (save de teste em user://test/, nunca o real).

const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String, pasta: String = "") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta if pasta != "" else pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.dados.crit_chance = 0.0
	gs.lutas.calendario["seconds_per_day"] = 0.0
	return gs


func _tickar(gs: Node, s: float, passo: float = 0.1) -> void:
	for i in int(round(s / passo)):
		gs.tick(passo)


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _vencer(gs: Node) -> Dictionary:
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	gs.lutar()
	return gs.concluir_luta()


func rodar_testes() -> void:
	_s1_derrota_reabre()
	_s2_abertura_reabre_meio()
	_s3_migracao_v10()
	_s4_garage_saved_so_ao_vivo()
	_s5_balao_posicoes()
	_s6_clique_e_espaco()
	_s7_discipulo()
	_s8_comentarios_na_campanha()
	_s9_gym_arrival()
	_s10_aposentar_no_meio_e_nova_em_loop()


# Falas unicas com prioridade >= 9 nao se perdem ao reabrir o jogo
func _s1_derrota_reabre() -> void:
	var gs := _novo("qa6_derrota")
	gs.pular_abertura()
	_tickar(gs, 3.0)
	gs.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	gs.lutar()
	gs.concluir_luta()
	gs.nova_carreira()
	_tickar(gs, 0.5)  # fecha o jogo antes do assentamento (2 s)
	gs.salvar()
	var g2 := _novo("qa6_derrota", gs.store.pasta)
	g2.pular_abertura()
	var v: Array = []
	g2.comentario.connect(func(id: String) -> void: v.append(id))
	_tickar(g2, 30.0)
	checar(v.has("cl_primeira_derrota"), "S1: fechou o jogo logo apos NOVA CAMPANHA da derrota: cl_primeira_derrota volta ao reabrir (obtido: %s)" % str(v))
	checar(not g2.escola.lines_seen.has("cl_primeira_derrota") or v.has("cl_primeira_derrota"), "S1b: nao ficou marcada como vista sem tocar")
	_liberar(gs)
	_liberar(g2)
	# Derrota -> fecha o jogo NA TELA DE FIM -> reabre -> NOVA CAMPANHA: toca
	var g3 := _novo("qa6_derrota2")
	g3.pular_abertura()
	_tickar(g3, 3.0)
	g3.atributos = {"strength": 0.0, "agility": 0.0, "endurance": 0.0}
	g3.lutar()
	g3.concluir_luta()
	g3.salvar()
	var g4 := _novo("qa6_derrota2", g3.store.pasta)
	g4.pular_abertura()
	var v4: Array = []
	g4.comentario.connect(func(id: String) -> void: v4.append(id))
	g4.nova_carreira()
	_tickar(g4, 6.0)
	checar(v4.has("cl_primeira_derrota"), "S1c: derrota, reabre na tela de fim, NOVA CAMPANHA: 1a derrota toca (obtido: %s)" % str(v4))
	_liberar(g3)
	_liberar(g4)


func _s2_abertura_reabre_meio() -> void:
	var gs := _novo("qa6_abre_meio")
	_tickar(gs, 3.0)
	checar_igual(gs.abertura_estado(), "playing", "S2: abertura tocando aos 3 s")
	# fecha o jogo (sem salvar de novo): o marco foi gravado em t=0
	var g2 := _novo("qa6_abre_meio", gs.store.pasta)
	checar_igual(g2.abertura_estado(), "over", "S2: reabrir no meio da abertura: nao toca de novo")
	var fa: Array = []
	g2.fala_pedida.connect(func(_q: String, _t: String, id: String) -> void: fa.append(id))
	_tickar(g2, 30.0)
	checar(fa.is_empty(), "S2: nenhuma fala de abertura ao reabrir")
	# saco vale em ate 3 s
	var g3 := _novo("qa6_abre_3s")
	g3.tick(0.016)
	var antes: float = g3.treino
	g3.clicar()
	checar(g3.treino > antes, "S2: saco vale no 1o quadro da abertura")
	_liberar(gs)
	_liberar(g2)
	_liberar(g3)


func _s3_migracao_v10() -> void:
	var pasta := pasta_limpa("qa6_v10")
	var career := {"training": 123456.0, "money": 77.0, "fame": 55, "ladder_index": 5, "glove_level": 3, "belt": true,
		"campaign_seconds": 400.0, "fight_day": 14, "active_nodes": [], "metronome_level": 2}
	var perm := {"legacy_total": 900, "career_number": 7, "careers_finished": 6, "best_wins": 9, "belts_won": 4,
		"skill_nodes": [], "revenge_opponent": "", "tree_last_node": ""}
	var doc := {"version": 10, "saved_at_unix": 1730000000, "state": {"career": career, "permanent": perm, "ending": null}}
	escrever(pasta + "save.json", JSON.stringify(doc))
	var gs := _novo("qa6_v10", pasta)
	checar_igual(gs.numero_carreira(), 7, "S3: numero da carreira preservado")
	checar_igual(gs.lutador_atual(), "first", "S3: campanha atual = John")
	checar_igual(gs.escola.first_fighter_campaign, 7, "S3: first_fighter_campaign = 7")
	checar(is_equal_approx(gs.treino, 123456.0) and gs.nivel_luva == 3, "S3: treino/luva preservados")
	checar(not gs.marco("garage_saved") and not gs.marco("first_school_win"), "S3: sem marcos criados")
	_tickar(gs, 40.0)
	checar(not gs.marco("garage_saved_seen"), "S3: reabrir nao cria garage_saved_seen")
	# Proxima vitoria ao vivo contra o Muralha ainda vale (belt:true e escada alem do Muralha?)
	_liberar(gs)
	# v10 sem 'ending' nem campos opcionais
	var p2 := pasta_limpa("qa6_v10b")
	escrever(p2 + "save.json", JSON.stringify({"version": 10, "state": {"career": {"training": 5.0}, "permanent": {"career_number": 1}}}))
	var g2 := _novo("qa6_v10b", p2)
	checar_igual(g2.escola.first_fighter_campaign, 1, "S3b: v10 minimo migra")
	_liberar(g2)
	# v10 com luta pendente
	var p3 := pasta_limpa("qa6_v10c")
	var d3 := doc.duplicate(true)
	d3.state.career["fight"] = {"opponent": "opp_warmup"}
	escrever(p3 + "save.json", JSON.stringify(d3))
	var g3 := _novo("qa6_v10c", p3)
	g3.tick(1.0)
	checar_igual(g3.abertura_estado(), "pending", "S3c: luta pendente: abertura espera")
	_liberar(g3)
	# save v11 tem .bak do v10? (backup de migracao)
	var arqs := DirAccess.get_files_at(pasta)
	print("  arquivos apos migrar: ", arqs)


func _s4_garage_saved_so_ao_vivo() -> void:
	# Carrega save com garage_saved no disco: o resumo de uma vitoria seguinte nao traz garage_saved
	var gs := _novo("qa6_gs_vivo")
	gs.pular_abertura()
	for i in 4:
		_vencer(gs)
	checar(gs.marco("garage_saved"), "S4: garage_saved ao vivo")
	gs.salvar()
	var g2 := _novo("qa6_gs_vivo", gs.store.pasta)
	var r: Dictionary = _vencer(g2)
	checar(not bool(r.get("garage_saved", false)), "S4: depois de reabrir, vitoria seguinte nao traz selo")
	# Selo so aparece na vez que o marco nasce: 2o cinturao (campanha 2)
	g2.aposentar()
	g2.nova_carreira()
	var selos := 0
	for i in 6:
		var rr: Dictionary = _vencer(g2)
		if bool(rr.get("garage_saved", false)):
			selos += 1
	checar_igual(selos, 0, "S4: cinturao da campanha 2 nao repete o selo")
	_liberar(gs)
	_liberar(g2)
	# Save v10 com belt=true e escada depois do muralha: vitoria depois NAO salva garagem retroativa?
	var pasta := pasta_limpa("qa6_gs_v10")
	var career := {"training": 500.0, "money": 20.0, "fame": 5, "ladder_index": 0, "glove_level": 1, "belt": false,
		"campaign_seconds": 40.0, "fight_day": 9, "active_nodes": [], "metronome_level": 0}
	var perm := {"legacy_total": 120, "career_number": 3, "careers_finished": 2, "best_wins": 4, "belts_won": 2,
		"skill_nodes": [], "revenge_opponent": "", "tree_last_node": ""}
	escrever(pasta + "save.json", JSON.stringify({"version": 10, "state": {"career": career, "permanent": perm, "ending": null}}))
	var g3 := _novo("qa6_gs_v10", pasta)
	g3.pular_abertura()
	var achou := false
	for i in 5:
		var rr: Dictionary = _vencer(g3)
		if bool(rr.get("garage_saved", false)):
			achou = true
	checar(achou, "S4: save v10: o proximo cinturao ao vivo salva a garagem")
	_liberar(g3)


func _s5_balao_posicoes() -> void:
	# Balao.calcular para todas as combinacoes: foco saco/corda x speaker, 2 linhas largas
	var info: Dictionary = {}
	var oc: Dictionary = info.get("original_trainer", {})
	var a: Array = [1, -63]
	var p: Array = [196, 236]
	var cab_coach := Vector2(float(p[0]) + float(a[0]), float(p[1]) + float(a[1]))
	var a2: Array = [1, -65]
	var ok_total := 0
	var falhas: Array = []
	for foco in ["foco_saco", "foco_corda"]:
		var pe := Vector2(303, 272) if foco == "foco_saco" else Vector2(336, 272)
		var cab_john := pe + Vector2(float(a2[0]), float(a2[1]))
		for quem in ["coach", "first"]:
			for w in [40.0, 100.0, 172.0]:
				for h in [17.0, 26.0]:
					var cab: Vector2 = cab_coach if quem == "coach" else cab_john
					var outro: Vector2 = cab_john if quem == "coach" else cab_coach
					var evitar := [Rect2(outro.x - 9.0, outro.y, 18.0, 18.0)]
					var c: Dictionary = Balao.calcular(cab, w, h, evitar)
					ok_total += 1
					if not bool(c.ok):
						falhas.append("%s/%s w=%d h=%d" % [foco, quem, int(w), int(h)])
					else:
						var corpo: Rect2 = c.corpo
						if corpo.position.y - 6.0 < 40.0:
							falhas.append("PERTO DA FAIXA %s/%s w=%d h=%d y=%d" % [foco, quem, int(w), int(h), int(corpo.position.y)])
	print("  balao: %d combinacoes, falhas/proximos da faixa: %s" % [ok_total, str(falhas)])
	checar(falhas.is_empty(), "S5: nenhum balao descartado nem junto da faixa de aviso (esteira/corda incluidas)")


func _s6_clique_e_espaco() -> void:
	var gs := _novo("qa6_espaco")
	gs.pular_abertura()
	_tickar(gs, 3.0)
	gs._ultimo_comentario = -1.0e9
	var n := [0]
	gs.comentario.connect(func(_id: String) -> void: n[0] += 1)
	gs.disparar_gatilho("box_opened", {"kind": "glove", "item": "x"})
	gs.tick(0.1)
	checar(gs.tem_balao(), "S6: balao ativo")
	var t0: float = gs.treino
	var d0: float = gs.dano_total if "dano_total" in gs else 0.0
	gs.clicar()
	checar(gs.tem_balao(), "S6: clicar() no alvo nao fecha o balao (so cancela gesto)")
	checar(gs.treino > t0, "S6: clique treina com balao na tela")
	_liberar(gs)


func _s7_discipulo() -> void:
	var gs := _novo("qa6_disc")
	gs.pular_abertura()
	_tickar(gs, 2.0)
	gs.aposentar()
	gs.nova_carreira()
	var gestos: Array = []
	gs.gesto_pedido.connect(func(p: Dictionary) -> void: gestos.append(p))
	checar(gs.pedir_gesto("fight_intro").is_empty() and gs.pedir_gesto("victory").is_empty() and gs.pedir_gesto("glove", 1).is_empty() and gs.pedir_gesto("idle").is_empty() and gs.pedir_gesto("opening").is_empty(), "S7: discipulo nunca faz gesto")
	_tickar(gs, 130.0)
	checar(gestos.is_empty(), "S7: sala parada 130 s: discipulo sem gesto")
	# fala do discipulo: o texto do treinador na campanha 2 nao usa nome do John errado
	var vistas: Array = []
	gs.comentario.connect(func(id: String) -> void: vistas.append(id))
	gs.disparar_gatilho("glove_new", {})
	_tickar(gs, 3.0)
	print("  disc glove_new falas: ", vistas)
	checar(not vistas.has("cl_luva_par"), "S7: cl_luva_par (o par do John) nao toca no discipulo")
	_liberar(gs)


func _s8_comentarios_na_campanha() -> void:
	# Simula 15 min de sala com compras/caixas esporadicas e confere as regras
	var gs := _novo("qa6_camp")
	var ts: Array = []
	var ids: Array = []
	gs.comentario.connect(func(id: String) -> void: ts.append(gs._t_real); ids.append(id))
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var segs := 0.0
	while segs < 900.0:
		gs.tick(0.1)
		segs += 0.1
		if int(segs * 10) % 30 == 0 and rng.randf() < 0.5:
			gs.clicar()
		if int(segs * 10) % 450 == 0:
			gs.disparar_gatilho("big_purchase", {"what": "apparatus", "item": "treadmill"})
		if int(segs * 10) % 900 == 0:
			gs.disparar_gatilho("box_opened", {"kind": "glove", "item": "g"})
	var minimo := 1.0e9
	for i in range(1, ts.size()):
		minimo = minf(minimo, float(ts[i]) - float(ts[i - 1]))
	print("  comentarios 15 min: %d, menor intervalo %.1f s, ids %s" % [ids.size(), minimo, str(ids)])
	var rep := {}
	var dup := false
	for id in ids:
		if rep.has(id):
			dup = true
		rep[id] = true
	checar(not dup, "S8: nenhuma fala repetida na campanha")
	checar(ids.size() <= 10, "S8: <= 10 comentarios em 15 min (sem a abertura)")
	_liberar(gs)


func _s9_gym_arrival() -> void:
	var gs := _novo("qa6_gym")
	gs.pular_abertura()
	_tickar(gs, 3.0)
	gs.cinturao = true
	gs.dinheiro = 1.0e9
	gs.mudar()
	gs.escolher_arte(gs.academia.ids_artes()[0])
	var pedidos: Array = []
	gs.fala_pedida.connect(func(q: String, _t: String, id: String) -> void: pedidos.append([q, id, gs.local_id]))
	_tickar(gs, 5.0)
	print("  gym_arrival pedidos: ", pedidos)
	checar(pedidos.is_empty() or pedidos[0][2] != "gym", "S9: (informativo) fala do treinador pedida na academia: %s" % str(pedidos))
	_liberar(gs)


func _s10_aposentar_no_meio_e_nova_em_loop() -> void:
	var gs := _novo("qa6_loop")
	gs.pular_abertura()
	for i in 12:
		_tickar(gs, 5.0)
		_vencer(gs)
		gs.aposentar()
		gs.nova_carreira()
	checar(gs.escola.milestones.has("prologue_seen"), "S10: 12 campanhas curtas sem erro; prologue_seen mantido")
	checar_igual(gs.escola.first_fighter_campaign, 1, "S10: first_fighter_campaign estavel")
	_liberar(gs)


