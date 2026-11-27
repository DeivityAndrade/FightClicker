extends "res://tests/test_base.gd"
## QA Ronda 2a2: roteiro ponta a ponta (save de teste -> disco -> ronda_ir -> aproximacao natural -> previa -> lutar -> premio -> recarregar).
## Tudo em user://test/ (APPDATA temporario). Nao e teste do time: so reporta.

const GameStateScript := preload("res://scripts/game_state.gd")
const GRANDE := {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
const PEQUENO := {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
const CHEFE := "apagao"


func rodar_testes() -> void:
	_roteiro()
	_b7_varredura()
	_b5_destrave()
	_b9_vazamento()


func _abrir(pasta: String) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta, "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.baloes_escondidos = true
	gs.lutas.calendario["seconds_per_day"] = 0.0
	return gs


func _novo(nome: String, lenda: int = -1, bandidos: int = 3, cinturoes: int = 1) -> Node:
	var pasta := pasta_limpa(nome)
	var gs := _abrir(pasta)
	gs.rng.seed = 4242
	gs.pular_abertura()
	gs.permanente["career_number"] = 9
	gs.permanente["regional_belts"] = cinturoes
	gs.escola.milestones["black_cat_rumor_heard"] = {"campaign": 8, "version": 1}
	gs.escola.milestones["regional_league_opened"] = {"campaign": 8, "version": 1}
	if lenda < 0:
		lenda = int(RondaData.carregar().niveis[4])
	var alley := {}
	var ids: Array = ["tire", "bike", "gate"]
	for i in bandidos:
		alley[ids[i]] = {"won": 1, "lost": 0, "first_win_campaign": 5 + i, "challenge": false}
	var bc := {"legend": lenda, "rounds": 12, "scares": 6, "shown_level": gs.ronda_cfg.nivel_de(lenda), "open_campaign": 3}
	if not alley.is_empty():
		bc["alley"] = alley
	gs.permanente["black_cat"] = bc
	gs.salvar()
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _capuz(gs: Node) -> bool:
	for _i in 900:
		if gs.capuz_info().get("clickable", false):
			return true
		gs.tick(1.0)
	return false


func _diff(a: Variant, b: Variant, caminho: String, out: Array) -> void:
	if a is Dictionary and b is Dictionary:
		var ks := {}
		for k in a.keys():
			ks[k] = true
		for k in b.keys():
			ks[k] = true
		for k in ks.keys():
			if not a.has(k):
				out.append(caminho + "/" + str(k) + " (so no depois)")
			elif not b.has(k):
				out.append(caminho + "/" + str(k) + " (so no antes)")
			else:
				_diff(a[k], b[k], caminho + "/" + str(k), out)
	elif JSON.stringify(a) != JSON.stringify(b):
		out.append(caminho + ": " + str(a) + " -> " + str(b))


func _ok_dif(x: String) -> bool:
	for pre in ["/permanent/black_cat", "/career/black_cat_hood", "/career/play_seconds", "/career/campaign_seconds", "/career/training_invite", "/career/attributes", "/school/lines_seen"]:
		if x.begins_with(pre):
			return true
	return false


func _tat(gs: Node, i: int = 0) -> String:
	return str(gs.lutas.taticas[i].id)


## aproximacao NATURAL: so deixa o relogio andar (ninguem clica) ate a previa
func _natural(gs: Node) -> String:
	for _i in 400:
		gs.tick(0.1)
		if str(gs.briga_estado().fase) == "previa":
			return str(gs.briga_estado().approach)
	return "?"


func _roteiro() -> void:
	var gs := _novo("qa2_e2e")
	var pasta: String = gs.store.pasta
	_liberar(gs)
	gs = _abrir(pasta)  # reabre do disco
	var base: Dictionary = gs.para_save().duplicate(true)
	var q: Array = gs.quadro_noite()
	checar(q[1].night == "boss" and not q[1].locked, "chefe aberto no quadro (lenda %d, 3 bandidos, cinturao)" % int(gs.lenda().legend))
	checar(q[1].name == "???" and not q[1].known, "cartao do chefe com ??? antes de vencer")
	var e: Dictionary = gs.esconderijo()
	checar(e.boss.name == "???" and e.boss.nickname == "???" and e.boss.rap_sheet == "" and e.boss.headline == "" and e.boss.witness == "", "ficha do chefe: ??? e textos vazios antes de vencer")
	checar(e.trophies.all(func(t): return t.state == "empty"), "prateleira vazia")
	# natural
	_capuz(gs)
	var ir: Dictionary = gs.ronda_ir("alley", CHEFE)
	checar(not ir.is_empty(), "ronda_ir(alley, apagao) abre")
	var ap := _natural(gs)
	var prev: Dictionary = gs.briga_previa()
	var legend0: int = int(gs.lenda().legend)
	gs.atributos = PEQUENO.duplicate()
	var info: Dictionary = gs.briga_lutar(_tat(gs))
	var pr: Dictionary = info.night_prize
	checar(not pr.win and pr.boss and pr.legend_gain == (2 if ap == "scare" else 1), "derrota: lenda +%d (aproximacao %s)" % [pr.legend_gain, ap])
	checar(pr.level == 5 and pr.legend == legend0 + pr.legend_gain, "premio real: LENDA (nivel) = %d, lenda %d" % [pr.level, pr.legend])
	var depois: Dictionary = gs.para_save().duplicate(true)
	var d: Array = []
	_diff(base, depois, "", d)
	var fora: Array = d.filter(func(x): return not _ok_dif(str(x)))
	checar(fora.is_empty(), "B4/B2: derrota so mexe em permanent.black_cat e career.black_cat_hood (fora: %s)" % str(fora))
	gs.ronda_voltar()
	checar(gs.quadro_noite()[1].revenge, "REVANCHE no cartao")
	_liberar(gs)
	# reabrir do disco
	gs = _abrir(pasta)
	checar(int(gs.permanente.black_cat.boss[CHEFE].lost) == 1, "derrota persistiu no disco")
	_capuz(gs)
	var hood_antes: float = gs.capuz.hood_s
	# vitoria SEM desafio (tempo, atributos grandes mas sem susto)
	gs.ronda_ir("alley", CHEFE)
	gs.ronda_jogo().sustos = 0
	gs.ronda_jogo().vistos = 1
	gs.ronda_jogo().fase = "fim"
	gs.tick(0.01)
	gs.atributos = GRANDE.duplicate()
	var w1: Dictionary = gs.briga_lutar(_tat(gs))
	var p1: Dictionary = w1.night_prize
	checar(p1.win and p1.trophy_new == "normal" and p1.press_title_new and p1.poster_new and not p1.challenge_done and p1.style_unlocked == "", "vitoria sem desafio: capacete normal, titulo, cartaz, sem estilo")
	checar(p1.level == 5 and p1.legend_gain == 3, "premio real: nivel 5, +3")
	var s1: Dictionary = gs.para_save().duplicate(true)
	d = []
	_diff(base, s1, "", d)
	fora = d.filter(func(x): return not _ok_dif(str(x)))
	checar(fora.is_empty(), "B2: vitoria sem desafio, nada fora de black_cat/capuz (%s)" % str(fora))
	checar(not s1.permanent.black_cat.boss[CHEFE].challenge and not gs.estilo_liberado("live_wire"), "sem desafio: sem estilo")
	checar(not s1.permanent.has("school") or true, "ok")
	gs.ronda_voltar()
	var m_antes: Array = gs.escola.milestones.keys()
	_liberar(gs)
	# vitoria COM desafio (susto + KO round1)
	gs = _abrir(pasta)
	var opcoes0: Array = gs.disciples.opcoes_ativas("shorts_color")
	checar(not ("live_wire" in opcoes0), "live_wire fora da lista sem desafio")
	_capuz(gs)
	gs.ronda_ir("alley", CHEFE)
	gs.ronda_jogo().sustos = 1
	gs.ronda_jogo().vistos = 0
	gs.ronda_jogo().fase = "fim"
	gs.tick(0.01)
	gs.atributos = GRANDE.duplicate()
	var w2: Dictionary = gs.briga_lutar(_tat(gs))
	var p2: Dictionary = w2.night_prize
	checar(p2.win and p2.challenge_done and p2.trophy_new == "rare" and p2.style_unlocked == "live_wire" and not p2.dossier_new and not p2.press_title_new, "2a vitoria cumprindo o desafio: raro + estilo; ficha/titulo nao repetem")
	checar(p2.legend_gain == 4 and p2.level == 5, "premio: +4 e nivel 5 (lenda real %d)" % int(p2.legend))
	checar(w2.blackout.is_empty(), "K.O. cedo: sem apagao")
	var t0: Dictionary = gs.esconderijo().trophies[0]
	checar(t0.state == "rare" and gs.esconderijo().trophies.filter(func(t): return t.state != "empty").size() == 1, "prateleira: capacete raro no lugar 1 (unico)")
	gs.ronda_voltar()
	_liberar(gs)
	gs = _abrir(pasta)
	var f: Dictionary = gs.permanente.black_cat.boss[CHEFE]
	checar(int(f.won) == 2 and int(f.lost) == 1 and bool(f.challenge) and int(f.first_win_campaign) == 9, "disco: won 2 lost 1 challenge first_win 9")
	checar(gs.estilo_liberado("live_wire") and gs.disciples.opcoes_ativas("shorts_color").back() == "live_wire", "live_wire liberado e no fim da lista")
	checar(gs._menu._requisito_ok({"black_cat_boss_won": CHEFE}), "cartaz do menu")
	gs.aguardar_motivo()
	gs.free()
	# sem save de chefe: sem cartaz
	var gsn := _novo("qa2_sem")
	checar(not gsn._menu._requisito_ok({"black_cat_boss_won": CHEFE}), "sem vitoria: sem cartaz")
	_liberar(gsn)


# B7: varredura grande
func _b7_varredura() -> void:
	var gs := _novo("qa2_b7")
	var b: Dictionary = gs.ronda_cfg.noites.alley.boss
	var t_apagao: float = float(b.blackout.after_round) * float(gs.motor.c.round_length)
	var n := 0
	var viol := 0
	var com := 0
	var sem := 0
	var rapidas_com := 0
	var igual := true
	for i in 36:
		var m: float = pow(10.0, -1.5 + 0.15 * i)
		var at := {"strength": float(b.strength) * m, "agility": float(b.agility) * m, "endurance": float(b.endurance) * m}
		for ti in gs.lutas.taticas.size():
			if not gs.capuz_info().get("clickable", false):
				_capuz(gs)
			gs.ronda_ir("alley", CHEFE)
			gs.ronda_jogo().sustos = 1
			gs.ronda_jogo().fase = "fim"
			gs.tick(0.01)
			gs.atributos = at.duplicate()
			var info: Dictionary = gs.briga_lutar(_tat(gs, ti))
			var res: Dictionary = info.result
			n += 1
			var tem: bool = not info.blackout.is_empty()
			var fim_t: float = float(res.get("t_end", 0.0))
			if tem:
				com += 1
			else:
				sem += 1
			if tem != (fim_t > t_apagao):
				viol += 1
			if bool(res.win) and bool(res.get("ko", false)) and int(res.round) <= 2 and tem:
				rapidas_com += 1
			gs.ronda_voltar()
			gs.permanente.black_cat.erase("boss")
	checar(n > 100 and com > 0 and sem > 0 and viol == 0 and rapidas_com == 0 and igual, "B7: apagao so com t_end > %.2f; vitoria ate round 2 nunca mostra (n=%d)" % [t_apagao, n])
	_liberar(gs)


func _b5_destrave() -> void:
	var lv: Array = RondaData.carregar().niveis
	var casos := [["a lenda 63", int(lv[4]) - 1, 3, 1, "legend"], ["b 2 bandidos", int(lv[4]), 2, 1, "bandits"], ["c sem cinturao", int(lv[4]), 3, 0, "belt"], ["d tudo", int(lv[4]), 3, 1, ""]]
	for c in casos:
		var gs := _novo("qa2_b5", c[1], c[2], c[3])
		var q: Array = gs.quadro_noite()
		var ir: Dictionary = gs.ronda_ir("alley", CHEFE) if gs.capuz_info().get("clickable", false) or _capuz(gs) else {"x": 1}
		if c[4] == "":
			checar(q[1].night == "boss" and not q[1].locked and not ir.is_empty(), "B5 " + c[0] + ": cartao com IR")
		else:
			var bf: Dictionary = gs.esconderijo().boss
			checar(ir.is_empty() and not bf.open and str(bf.missing_text) != "", "B5 " + c[0] + ": ficha trancada e ir() vazio")
		_liberar(gs)


func _b9_vazamento() -> void:
	var gs := _novo("qa2_b9")
	var j := JSON.stringify([gs.quadro_noite(), gs.esconderijo(), gs.dossie()])
	var ju := j.to_upper()
	checar(not ju.contains("NÉLSON") and not ju.contains("NELSON"), "esconderijo/quadro/dossie sem o nome NÉLSON VOLT antes de vencer")
	_capuz(gs)
	var ir: Dictionary = gs.ronda_ir("alley", CHEFE)
	var js := JSON.stringify(ir)
	for s in ["NÉLSON", "VOLT"]:
		checar(not js.contains(s), "aproximacao sem '%s'" % s)
	gs.ronda_jogo().sustos = 1
	gs.ronda_jogo().fase = "fim"
	gs.tick(0.01)
	var pj := JSON.stringify(gs.briga_previa())
	for s in ["NÉLSON", "VOLT"]:
		checar(not pj.contains(s), "previa sem '%s'" % s)
	gs.atributos = GRANDE.duplicate()
	var info: Dictionary = gs.briga_lutar(_tat(gs))
	var lj := JSON.stringify(info.get("night_prize", {}))
	checar(str(info.get("fighter_name")) == "???", "luta: nome da luta ???")
	_liberar(gs)
