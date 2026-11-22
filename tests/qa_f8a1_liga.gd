extends "res://tests/test_base.gd"
## QA 8a1: fluxo da liga (Kid -> 4 regionais -> campanha completa), arenas, prêmios, dias, Osmar 1 vez, valores extremos, save sujo,
## muitas lutas seguidas, save do dono (cópia). APPDATA temporário; usa user://test/.
const GameStateScript := preload("res://scripts/game_state.gd")
const REG := ["opp_reg_1", "opp_reg_2", "opp_reg_3", "opp_james"]
var dados: FightData


func _novo(nome: String, arte: String = "boxing") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.pular_abertura()
	if arte != "":
		gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		gs.escolher_arte(arte, 1)
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func rodar_testes() -> void:
	dados = FightData.carregar()
	await _fluxo()
	await _osmar()
	_extremos()
	_save_sujo()
	_muitas_lutas()
	_save_dono()


func _fluxo() -> void:
	var gs := _novo("qa_fluxo")
	gs.local_id = "gym"
	gs.cinturao = true
	gs.indice_escada = 5
	gs.lutas.calendario["seconds_per_day"] = 0.0
	var arenas := {}
	for i in dados.adversarios.size():
		arenas[str(dados.adversarios[i].id)] = gs.arena_da_luta(str(dados.adversarios[i].id))
	print("ARENAS ", arenas)
	for i in 6:
		checar(arenas[str(dados.adversarios[i].id)] != "arena_regional", "arena antiga mantida: %s -> %s" % [dados.adversarios[i].id, arenas[str(dados.adversarios[i].id)]])
	for r in REG:
		checar_igual(arenas[r], "arena_regional", "%s na arena regional" % r)
	for i in dados.adversarios.size():
		checar_igual(str(dados.adversarios[i].get("location", "")), "gym" if i >= 4 else str(dados.adversarios[i].get("location", "")), "local %s" % dados.adversarios[i].id)
	gs.atributos = {"strength": 1.0e13, "agility": 1.0e13, "endurance": 1.0e13}
	var visto := []
	for passo in 5:
		var opp: Dictionary = gs.proximo_adversario()
		var din0: float = gs.dinheiro
		var fam0: int = gs.fama
		gs.fight_day = gs.dia_campanha() + 1  # prepara: hoje + 1 dia
		var dias_antes: int = gs.fight_day - gs.dia_campanha()
		gs.fight_day = gs.dia_campanha()
		gs.segundos_campanha = 1.0e9
		var estado_pre: String = gs.estado_escada()
		var info: Dictionary = gs.lutar()
		var r: Dictionary = gs.concluir_luta()
		var prox: Dictionary = gs.proximo_adversario()
		var dias: int = gs.fight_day - gs.dia_campanha()
		print("PASSO %d: %s (%s) venceu=%s +$%s +fama %d | estado antes=%s depois=%s completa=%s liga=%s cinturao_reg=%s | proximo=%s dias_ate=%d (prep %s)" % [passo, opp.id, str(opp.get("league", "-")), str(r.get("win", "?")),
			str(gs.dinheiro - din0), gs.fama - fam0, estado_pre, gs.estado_escada(), str(gs.escada_completa()), str(gs.liga_aberta()), str(gs.cinturao_regional()), str(prox.get("id", "-")), dias, str(prox.get("prep_days", "-"))])
		visto.append([str(opp.id), gs.estado_escada(), prox.get("id", ""), dias, gs.escada_completa()])
		checar(bool(r.get("win", false)), "venceu %s" % opp.id)
		if passo < 4:
			checar(not gs.escada_completa() and gs.estado_escada() != "end", "depois de %s a escada ainda nao esta completa (estado %s)" % [opp.id, gs.estado_escada()])
			checar_igual(int(prox.get("prep_days", -1)), 16 if passo < 3 else 20, "dias de preparo do proximo (%s)" % prox.get("id", "-"))
	checar(gs.escada_completa() and gs.estado_escada() == "end", "completa so depois do James")
	checar(gs.cinturao_regional(), "cinturao regional")
	var fim: Dictionary = gs.aposentar()
	print("FIM summary: ", fim.get("summary", {}))
	checar_igual(int(fim.summary.belts), 2, "belts conta amador + regional")
	print("PERM regional_belts=", gs.permanente.get("regional_belts"), " first=", gs.permanente.get("first_regional_belt_campaign"), " roster.last=", gs.escola.roster.back())
	# derrota para cada regional encerra a carreira
	for idx in [6, 7, 8, 9]:
		var g := _novo("qa_derrota_%d" % idx)
		g.local_id = "gym"
		g.indice_escada = idx
		g.fight_day = 1
		g.segundos_campanha = 1.0e9
		g.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
		g.lutar()
		var r: Dictionary = g.concluir_luta()
		var tf: Dictionary = g.textos_fim() if not g.fim.is_empty() else {}
		checar(not bool(r.win) and not g.fim.is_empty(), "derrota no regional %d encerra a carreira" % idx)
		print("DERROTA ", idx, " reason=", g.fim.get("reason", {}).get("kind", ""), " opp_note=", tf.get("opp_note", ""), " tip=", tf.get("tip", tf.get("extra_tip", "")), " dica_extra=", tf.get("extra", ""))
		_liberar(g)
	_liberar(gs)


func _osmar() -> void:
	# Kid vencido na academia: a fala do Osmar da liga sai uma vez; reabrir (aplicar_save) nao repete.
	var gs := _novo("qa_osmar")
	gs.local_id = "gym"
	gs._escola._gravar_marco(gs._casa._marco_da_chegada(), {}, false)
	gs.indice_escada = 5
	gs.atributos = {"strength": 1.0e13, "agility": 1.0e13, "endurance": 1.0e13}
	var falas: Array = []
	gs.fala_pedida.connect(func(q: String, t: String, id: String) -> void: falas.append(id))
	gs.fight_day = 1
	gs.segundos_campanha = 1.0e9
	gs.lutar()
	gs.concluir_luta()
	for i in 600:
		gs.tick(0.1)
	print("OSMAR falas apos Kid: ", falas)
	checar(falas.count("cl_liga_regional") == 1, "fala do Osmar da liga: %d vez(es) apos vencer o Kid" % falas.count("cl_liga_regional"))
	var estado: Dictionary = gs.para_save()
	for k in 2:
		gs.aplicar_save(estado.duplicate(true))
		for i in 600:
			gs.tick(0.1)
	checar(falas.count("cl_liga_regional") == 1, "reabrir o save nao repete (%d)" % falas.count("cl_liga_regional"))
	# E o cinturao regional: vence os 4 e a fala sai uma vez
	for i in 4:
		gs.fight_day = gs.dia_campanha()
		gs.segundos_campanha = 1.0e9
		gs.lutar()
		gs.concluir_luta()
		for j in 300:
			gs.tick(0.1)
	print("OSMAR falas apos James: ", falas)
	checar(falas.count("cl_cinturao_regional") == 1, "fala do Osmar do cinturao: %d vez(es)" % falas.count("cl_cinturao_regional"))
	# nova campanha e outro cinturao: nao repete (linhagem)
	var f2: Dictionary = gs.aposentar()
	gs.nova_carreira()
	gs.indice_escada = 9
	gs.local_id = "gym"
	gs.atributos = {"strength": 1.0e13, "agility": 1.0e13, "endurance": 1.0e13}
	gs.fight_day = gs.dia_campanha()
	gs.segundos_campanha = 1.0e9
	gs.lutar()
	gs.concluir_luta()
	for j in 600:
		gs.tick(0.1)
	checar(falas.count("cl_cinturao_regional") == 1 and falas.count("cl_liga_regional") == 1, "2o cinturao na linhagem: falas do Osmar nao repetem")
	print("REGIONAL belts=", gs.permanente.get("regional_belts"), " first=", gs.permanente.get("first_regional_belt_campaign"))
	_liberar(gs)


func _extremos() -> void:
	var valores := [0.0, -5.0, 1.0e-300, 1.0, 1.0e6, 1.0e15, 1.0e30, 1.0e300, INF, NAN]
	var problemas := 0
	for combo in [["", 1], ["boxing", 1], ["boxing", 2], ["bjj", 1], ["bjj", 2], ["muay_thai", 1], ["muay_thai", 2]]:
		var g := _novo("qa_ext", str(combo[0]))
		if combo[0] != "" and combo[1] == 2:
			g.permanente["passive_wins"] = {combo[0]: 3}
			g.permanente["passives_unlocked"] = [combo[0]]
			g.escolher_arte(combo[0], 2)
		g.local_id = "gym"
		for idx in [6, 7, 8, 9]:
			g.indice_escada = idx
			for v in valores:
				for tat in ["aggressive", "defensive", "counter"]:
					g.atributos = {"strength": v, "agility": v, "endurance": v}
					g.definir_tatica(tat)
					var pv: Dictionary = g.previa()
					var ch := float(pv.risks[tat].chance)
					var res: Dictionary = g.motor.lutar([v, v, v], g._luta._array_adversario(g.proximo_adversario()), tat, 4242, false)
					var t_end := float(res.get("t_end", -1.0))
					if not is_finite(ch) or ch < 0.0 or ch > 1.0 or not is_finite(t_end) or t_end < 0.0 or t_end > 60.0:
						problemas += 1
						print("EXT PROBLEMA combo=", combo, " idx=", idx, " v=", v, " tat=", tat, " chance=", ch, " t_end=", t_end)
	checar_igual(problemas, 0, "valores extremos (0, negativo, 1e-300, 1e300, INF, NAN): chance em [0,1] e t_end finito")
	# luta completa pelo GameState com extremos
	var g2 := _novo("qa_ext2")
	g2.local_id = "gym"
	for v in [0.0, 1.0e300, NAN]:
		g2.indice_escada = 9
		g2.atributos = {"strength": v, "agility": v, "endurance": v}
		g2.fight_day = 1
		g2.segundos_campanha = 1.0e9
		var info: Dictionary = g2.lutar()
		var r: Dictionary = g2.concluir_luta()
		print("LUTA extrema v=", str(v).left(12), " lutar_vazio=", info.is_empty(), " resumo_chaves=", r.keys().size(), " win=", r.get("win"), " dinheiro=", g2.dinheiro, " fama=", g2.fama, " atributos=", str(g2.atributos).left(80), " luta_pendente=", g2.tem_luta_pendente())
		if not g2.fim.is_empty():
			g2.nova_carreira()
			g2.local_id = "gym"
	_liberar(g2)


func _save_sujo() -> void:
	var g := _novo("qa_sujo")
	g.local_id = "gym"
	g.indice_escada = 9
	var base: Dictionary = g.para_save()
	var casos := {
		"rival string": {"school": {"rival": "abc"}},
		"rival array": {"school": {"rival": [1, 2, 3]}},
		"rival negativos": {"school": {"rival": {"met": -5, "school_wins": -1, "james_wins": -2}}},
		"rival strings": {"school": {"rival": {"met": "x", "school_wins": null, "james_wins": [1]}}},
		"rival 1e30": {"school": {"rival": {"met": 1.0e30, "school_wins": 1.0e30, "james_wins": 1.0e30}}},
		"rival NaN": {"school": {"rival": {"met": NAN, "school_wins": INF, "james_wins": -INF}}},
		"rival_spoke int": {"career": {"rival_spoke": 3}},
		"rival_spoke strings": {"career": {"rival_spoke": {"before": "sim", "after": [1]}}},
		"ladder 11": {"career": {"ladder_index": 11}},
		"ladder 99": {"career": {"ladder_index": 99}},
		"ladder -3": {"career": {"ladder_index": -3}},
		"ladder 'x'": {"career": {"ladder_index": "x"}},
		"ladder NaN": {"career": {"ladder_index": NAN}},
		"regional_belts string": {"permanent": {"regional_belts": "x", "first_regional_belt_campaign": [1]}},
		"regional_belts -5/1e30": {"permanent": {"regional_belts": -5, "first_regional_belt_campaign": 1.0e30}},
		"roster regional_belt lixo": {"school": {"roster": [{"regional_belt": "yes", "name": 3}]}},
		"opp_blocks lixo": {"career": {"fight": {"result": {"opp_blocks": "a", "guard_absorbed": 5}}}},
	}
	var ruins := 0
	for nome in casos:
		var est: Dictionary = base.duplicate(true)
		var c: Dictionary = casos[nome]
		for sec in c:
			if not est.has(sec) or not (est[sec] is Dictionary):
				est[sec] = {}
			for k in c[sec]:
				est[sec][k] = c[sec][k]
		g.aplicar_save(est)
		var ok := true
		var rv: Dictionary = g.rival()
		for k in ["met", "school_wins", "james_wins"]:
			if typeof(rv[k]) != TYPE_INT or int(rv[k]) < 0:
				ok = false
		if int(rv.school_wins) + int(rv.james_wins) > int(rv.met):
			ok = false
		if typeof(g.rival_spoke.before) != TYPE_BOOL or typeof(g.rival_spoke.after) != TYPE_BOOL:
			ok = false
		if g.indice_escada < 0 or g.indice_escada > g.lutas.adversarios.size():
			ok = false
		var pr: Dictionary = g.previa() if not g.proximo_adversario().is_empty() else {}
		var sv: Dictionary = g.para_save()
		var js := JSON.stringify(sv)
		if js == "":
			ok = false
		if not ok:
			ruins += 1
		print("SUJO ", nome, ": ", "OK" if ok else "PROBLEMA", " rival=", rv, " spoke=", g.rival_spoke, " indice=", g.indice_escada, " regional_belts=", g.permanente.get("regional_belts"), "/", g.permanente.get("first_regional_belt_campaign"))
	checar_igual(ruins, 0, "save sujo da 8a1: campos sanados, sem erro")
	_liberar(g)


func _muitas_lutas() -> void:
	var g := _novo("qa_muitas")
	g.local_id = "gym"
	g.atributos = {"strength": 1.0e14, "agility": 1.0e14, "endurance": 1.0e14}
	var ok := true
	for i in 400:
		g.indice_escada = 9
		g.fight_day = g.dia_campanha()
		g.segundos_campanha = 1.0e9
		var info: Dictionary = g.lutar()
		if info.is_empty():
			ok = false
			break
		var r: Dictionary = g.concluir_luta()
		var rv: Dictionary = g.rival()
		if int(rv.school_wins) + int(rv.james_wins) > int(rv.met):
			ok = false
	var rv2: Dictionary = g.rival()
	print("MUITAS rival=", rv2, " regional_belts=", g.permanente.get("regional_belts"), " dinheiro=", g.dinheiro, " fama=", g.fama)
	checar(ok, "400 lutas seguidas contra o James: placar coerente")
	checar_igual(int(rv2.met), 400, "met = 400")
	_liberar(g)


func _save_dono() -> void:
	var origem := "C:/Users/deivi/AppData/Roaming/Godot/app_userdata/Fightclicker/"
	var pasta := pasta_limpa("qa_dono")
	var copiou := 0
	if DirAccess.dir_exists_absolute(origem):
		for f in DirAccess.get_files_at(origem):
			if f.ends_with(".json") or f.ends_with(".bak"):
				var src := FileAccess.open(origem + f, FileAccess.READ)
				var dst := FileAccess.open(ProjectSettings.globalize_path(pasta) + f, FileAccess.WRITE)
				if src != null and dst != null:
					dst.store_buffer(src.get_buffer(src.get_length()))
					copiou += 1
	print("SAVE DONO: copiei %d arquivo(s) para %s" % [copiou, pasta])
	if copiou == 0:
		checar(true, "sem save do dono para copiar (pulado)")
		return
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	print("SAVE DONO abriu: indice_escada=", gs.indice_escada, " arte=", gs.arte_id, " local=", gs.local_id, " rival=", gs.rival(), " liga_aberta=", gs.liga_aberta())
	checar(gs.indice_escada >= 0, "copia do save do dono abre sem erro")
	var p: Dictionary = gs.previa() if not gs.proximo_adversario().is_empty() else {}
	checar(true, "previa da copia do save do dono monta")
	gs.free()
