extends "res://tests/test_base.gd"
## QA 7b2: soak do robô com as 3 artes liberadas e escolha aleatória de passiva (1, 2 ou padrão), luta nas 3 táticas, aposenta, muda de carreira; confere invariantes da meta.
const GS := preload("res://scripts/game_state.gd")
var _rng := RandomNumberGenerator.new()

func rodar_testes() -> void:
	var mt_lutas := 0
	var mt_spin := 0
	var kick_focus := 0
	var viol := 0
	var fim2 := 0
	for ep in 4:
		var gs: Node = GS.new()
		gs.inicializar(pasta_limpa("qa7b2_soak%d" % ep), "res://data/config.json")
		gs.autosave_ativo = false
		gs.risco_hud_ativo = false
		gs.pular_abertura()
		gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		_rng.seed = 555 + ep
		gs.rng.seed = 9 + ep
		var ok := true
		for i in 6000:
			_passo(gs)
			if gs.luta.has("result") and str(gs.luta.result.get("finish", "")) == "spin_kick" and gs.arte_id == "muay_thai":
				mt_spin += 1
			if gs.arte_id == "muay_thai" and gs.foco == "kick_bag":
				kick_focus += 1
			if gs.passiva_carreira == 2 and (gs.arte_id == "" or not gs.passiva_liberada(gs.arte_id)):
				viol += 1
			if gs.luta.has("result"):
				var fz := str(gs.luta.result.get("finish", ""))
				if fz in ["counter_ko", "ground_stop", "knee_ko"] and gs.passiva_carreira != 2:
					viol += 1
				if fz in ["counter_ko", "ground_stop", "knee_ko"]:
					fim2 += 1
			for a in gs.permanente.get("passive_wins", {}):
				if int(gs.permanente.passive_wins[a]) < 0:
					viol += 1
			if not is_finite(gs.treino) or not is_finite(gs.dinheiro):
				ok = false
				break
		checar(ok and is_finite(gs.treino), "soak %d: treino e dinheiro finitos (treino %s)" % [ep, str(gs.treino)])
		var estado: Dictionary = gs.para_save()
		checar(gs.salvar(), "soak %d: salva" % ep)
		gs.aguardar_motivo()
		gs.free()
	print("   violacoes de invariante: %d; luta pendente com fim de 2a passiva (amostras): %d; rodado %d" % [viol, fim2, mt_spin])
	checar_igual(viol, 0, "invariantes: 2a passiva so com a meta; fins de 2a so com a 2a; contagem nao negativa")
	checar(true, "soak terminou sem erro de script")

func _passo(gs: Node) -> void:
	if gs.cena_sala != "":
		gs.cena_sala_terminou()
		return
	if gs.escolha_arte_pendente():
		gs.escolher_arte(["muay_thai", "bjj", "boxing"][_rng.randi() % 3], _rng.randi() % 3)
		return
	if not gs.fim.is_empty():
		gs.nova_carreira()
		return
	if gs.sucessao != "none":
		gs.sucessao_tela_aberta()
		if gs.sucessao == "scene_2" or gs.sucessao == "arriving":
			gs.sucessao_terminou()
		return
	if not gs.luta.is_empty():
		gs.concluir_luta()
		return
	var r := _rng.randf()
	if r < 0.30:
		for k in _rng.randi_range(1, 40):
			gs.clicar()
	elif r < 0.50:
		gs.tick([0.1, 0.5, 1.0, 5.0, 30.0][_rng.randi() % 5])
	elif r < 0.62:
		match _rng.randi() % 6:
			0:
				for g in gs.dados.geradores:
					gs.comprar_gerador(str(g.id))
			1:
				for ap in gs.dados.aparelhos:
					gs.comprar_melhoria(str(ap.id))
			2:
				for ap in gs.dados.aparelhos:
					gs.comprar_aparelho(str(ap.id))
					gs.abrir_caixa(str(ap.id))
			3:
				gs.comprar_luva()
			4:
				gs.comprar_metronomo()
			5:
				for id in ["style_muay_thai", "mt_shin", "box_counter", "bjj_guard", "style_boxing", "style_bjj"]:
					gs.comprar_no(id)
	elif r < 0.70:
		gs.pegar_evento_dourado()
	elif r < 0.88:
		if gs.pode_lutar():
			if _rng.randf() < 0.8:
				var f := 2000.0 * float(1 + gs.indice_escada) * float(1 + _rng.randi() % 40)
				gs.atributos = {"strength": f, "agility": f * 0.7, "endurance": f * 0.5}
			gs.tatica = ["aggressive", "defensive", "counter"][_rng.randi() % 3]
			gs.lutar()
	elif r < 0.93:
		gs.definir_foco("kick_bag" if _rng.randf() < 0.5 else str(gs.dados.aparelhos[_rng.randi() % gs.dados.aparelhos.size()].id))
	elif r < 0.935:
		gs.aposentar()
	else:
		gs.tick(60.0)
