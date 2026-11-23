extends "res://tests/test_base.gd"
## QA 8a2 (2): efeito dos nos CENTRO na campanha seguinte, nome do recorte, ida e volta pelo disco, 2o mudar, centro e luta.
const GameStateScript := preload("res://scripts/game_state.gd")


func _novo(nome: String, arte: String = "boxing") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	gs.lutas.calendario["seconds_per_day"] = 0.0
	if arte != "":
		gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		gs.escolher_arte(arte, 1)
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func rodar_testes() -> void:
	_nos_na_campanha_seguinte()
	_recorte_nome()
	_disco()
	_luta_no_centro()


func _nos_na_campanha_seguinte() -> void:
	var gs := _novo("qx_nos")
	gs.permanente["legacy_total"] = 100000
	gs.permanente["center_reached"] = true
	var clique0: float = gs.clique_base() if gs.has_method("clique_base") else -1.0
	var dias0: int = gs.lutas.adversarios[0].get("prep_days", 14) + int(gs._arvore._b("prep_days_bonus"))
	checar(gs.comprar_no("ctr_door") and gs.comprar_no("ctr_schedule") and gs.comprar_no("ctr_floor"), "compra os 3 nos")
	print("NOS antes de nova campanha: click_bonus=%s prep=%s gym_bonus=%s" % [gs._arvore._b("click_bonus"), gs._arvore._b("prep_days_bonus"), gs._arvore._b("gym_training_bonus")])
	gs.fim = {}
	gs.aposentar()
	gs.nova_carreira()
	if gs.escolha_arte_pendente():
		gs.escolher_arte("boxing", 1)
	gs.pular_abertura()
	print("NOS campanha 2: click_bonus=%s prep=%s gym_bonus=%s" % [gs._arvore._b("click_bonus"), gs._arvore._b("prep_days_bonus"), gs._arvore._b("gym_training_bonus")])
	checar_igual(gs._arvore._b("gym_training_bonus"), 0.25, "campanha seguinte: Piso +25%")
	checar_igual(gs._arvore._b("prep_days_bonus"), 1.0, "campanha seguinte: +1 dia")
	gs.local_id = "gym"
	checar_igual(gs.mult_local(), 2.5, "academia x2,5 na campanha seguinte")
	gs.local_id = "center"
	checar_igual(gs.mult_local(), 5.0, "centro x5 (x6 so com o Ventilador tambem)")
	gs.local_id = "garage"
	checar_igual(gs.mult_local(), 1.0, "garagem continua x1")
	_liberar(gs)


func _recorte_nome() -> void:
	var gs := _novo("qx_recorte")
	gs.permanente["first_regional_belt_campaign"] = 3
	gs.permanente["regional_belts"] = 1
	var r: Dictionary = gs.recorte_do_vale()
	print("RECORTE campanha sem roster: name='%s' text='%s'" % [str(r.get("name", "?")), str(r.get("text", ""))])
	checar(str(r.get("name", "")) != "", "recorte de uma campanha passada sem entrada no roster: o nome nao fica vazio (obtido '%s')" % str(r.get("name", "")))
	gs.permanente["first_regional_belt_campaign"] = gs.numero_carreira()
	gs.discipulo = {"name": ""}
	var q: Dictionary = gs.recorte_do_vale()
	print("RECORTE nome do discipulo vazio: name='%s' text='%s'" % [str(q.get("name", "?")), str(q.get("text", ""))])
	_liberar(gs)


func _disco() -> void:
	# ida e volta pelo disco no centro, com alunos, 5a melhoria, patrocinio assinado e fala vista
	var pasta := pasta_limpa("qx_disco")
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
	gs.escolher_arte("bjj", 1)
	gs.local_id = "gym"
	gs.cinturao = true
	gs.indice_escada = 10
	gs.permanente["regional_belts"] = 1
	gs.permanente["first_regional_belt_campaign"] = 1
	gs.dinheiro = 90000.0
	gs.mudar()
	gs.treino = 1.0e13
	for i in 7:
		gs.comprar_gerador("center_students")
	gs.niveis_melhoria["punching_bag"] = 4
	gs.comprar_melhoria("punching_bag")
	gs.patrocinio_estado = "offered"
	gs.assinar_patrocinio()
	var antes: Dictionary = gs.para_save()
	gs.salvar()
	_liberar(gs)
	var g2: Node = GameStateScript.new()
	g2.inicializar(pasta, "res://data/config.json")
	g2.autosave_ativo = false
	g2.risco_hud_ativo = false
	var depois: Dictionary = g2.para_save()
	for s in [antes, depois]:
		s.erase("saved_at_unix")
		if s.career.has("play_seconds"):
			s.career.erase("play_seconds")
	checar_igual(g2.local_id, "center", "disco: volta no centro")
	checar_igual(g2.quantidade_gerador("center_students"), 7, "disco: 7 alunos")
	checar_igual(g2.niveis_melhoria["punching_bag"], 5, "disco: 5a melhoria")
	checar_igual(g2.patrocinio_estado, "signed", "disco: contrato assinado")
	checar_igual(g2.pessoas_desenhadas("center_students"), 2, "disco: 2 pessoas")
	checar(bool(g2.permanente.get("center_reached", false)) and g2.marco("center_arrival"), "disco: center_reached e marco")
	checar(JSON.stringify(antes) == JSON.stringify(depois), "disco: save identico depois de recarregar")
	if JSON.stringify(antes) != JSON.stringify(depois):
		for k in antes.career:
			if JSON.stringify(antes.career[k]) != JSON.stringify(depois.career.get(k)):
				print("DIF career.", k, " ", str(antes.career[k]).left(120), " | ", str(depois.career.get(k)).left(120))
	_liberar(g2)


func _luta_no_centro() -> void:
	# no centro a escada esta completa: sem luta, sem previa, sem data
	var gs := _novo("qx_luta")
	gs.local_id = "gym"
	gs.cinturao = true
	gs.indice_escada = 10
	gs.permanente["regional_belts"] = 1
	gs.dinheiro = 90000.0
	gs.mudar()
	print("CENTRO escada_completa=%s proximo=%s pode_lutar=%s" % [str(gs.escada_completa()), str(gs.proximo_adversario().get("id", "")), str(gs.pode_lutar() if gs.has_method("pode_lutar") else "?")])
	checar(gs.escada_completa(), "no centro a escada esta completa")
	var r: Dictionary = gs.aposentar()
	checar(not r.is_empty(), "no centro da para passar o posto")
	checar_igual(int(gs.permanente.get("regional_belts", 0)), 1, "cinturao regional contado 1 vez")
	gs.nova_carreira()
	checar_igual(gs.local_id, "garage", "proximo discipulo comeca na garagem")
	checar(not gs.no_centro() and gs.quantidade_gerador("center_students") == 0, "alunos zerados, fora do centro")
	checar(not gs.cinturao_regional(), "cinturao regional da campanha zerado")
	_liberar(gs)
