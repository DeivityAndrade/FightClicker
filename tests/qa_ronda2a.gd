extends "res://tests/test_base.gd"
## QA da Ronda 2a1: cenarios que o test_ronda2a.gd nao cobre (abuso da API, extremos, saves sujos, muitas noites, previa x motor com mais sementes).
## Tudo em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")
const GRANDE := {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
const PEQUENO := {"strength": 1.0, "agility": 1.0, "endurance": 1.0}


func rodar_testes() -> void:
	_abuso_da_api()
	_extremos()
	_saves_sujos()
	_muitas_noites()
	_previa_x_motor()
	_rngs_e_relogio()
	_estilos_extra()
	_disco()
	_quem_briga_igual_b()


func _novo(nome: String, lenda: int = 30, com_marco: bool = true, campanha: int = 4) -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.baloes_escondidos = true
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.rng.seed = 4242
	gs._rng_evento.seed = 11
	gs._rng_fala.seed = 22
	gs._rng_sucessao.seed = 33
	gs._rng_treino.seed = 44
	gs.pular_abertura()
	gs.permanente["career_number"] = campanha
	gs.escola.milestones["black_cat_rumor_heard"] = {"campaign": campanha - 1, "version": 1}
	if com_marco:
		gs.escola.milestones["regional_league_opened"] = {"campaign": campanha - 1, "version": 1}
	gs.permanente["black_cat"] = {"legend": lenda, "rounds": 6, "scares": 3, "shown_level": gs.ronda_cfg.nivel_de(lenda), "open_campaign": 3}
	return gs


func _lib(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _capuz(gs: Node) -> bool:
	for _i in 400:
		if gs.capuz_info().get("clickable", false):
			return true
		gs.tick(1.0)
	return false


func _fim_aprox(gs: Node, como: String) -> void:
	var j: RondaLogica = gs.ronda_jogo()
	j.sustos = 1 if como == "scare" else 0
	j.vistos = 1 if como == "seen" else 0
	j.fase = "fim"
	gs.tick(0.01)


func _tat(gs: Node) -> String:
	return str(gs.lutas.taticas[0].id)


func _bc(gs: Node) -> Dictionary:
	return gs.permanente.get("black_cat", {})


func _abuso_da_api() -> void:
	var gs := _novo("qa2a_abuso")
	# nada de briga com a Ronda fora do capuz
	checar(gs.briga_lutar(_tat(gs)).is_empty(), "briga_lutar sem noite: {}")
	checar(gs.briga_previa().is_empty(), "briga_previa sem noite: {}")
	checar(gs.ronda_ir("alley", "").is_empty() and gs.ronda_ir("alley", "xyz").is_empty() and gs.ronda_ir("alley", "TIRE").is_empty(), "ids vazios/invalidos/caixa errada: recusa")
	checar(gs.ronda_ir("naoexiste", "tire").is_empty() or gs.ronda_ativa == "scare", "noite desconhecida nao abre a briga (cai no SUSTO ou recusa)")
	if gs.ronda_ativa != "":
		gs.ronda_concluir()
		gs.ronda_voltar()
	gs.capuz["open"] = "scare"
	gs.capuz["next_at"] = 0.0
	gs.tick(1.0)
	checar(not gs.ronda_ir("alley", "tire").is_empty(), "IR ok")
	checar(gs.ronda_ir("alley", "tire").is_empty(), "IR duas vezes seguidas: a 2a recusa (nao recria a aproximacao)")
	checar(gs.ronda_ir().is_empty(), "ronda_ir() do SUSTO durante a briga: recusa")
	_fim_aprox(gs, "seen")
	checar(gs.briga_lutar("").is_empty() and gs.briga_lutar("x").is_empty() and gs.briga_lutar("PADRAO").is_empty(), "taticas ruins: recusa")
	checar(gs.briga_estado().fase == "previa", "continua na previa depois de tatica ruim")
	var info = gs.briga_lutar(_tat(gs))
	checar(not info.is_empty(), "LUTAR ok")
	var salvo1: String = JSON.stringify(gs.para_save(), "", true)
	checar(gs.briga_lutar(_tat(gs)).is_empty() and gs.briga_lutar(_tat(gs)).is_empty(), "LUTAR 2x e 3x: {} (nao rola de novo)")
	checar_igual(JSON.stringify(gs.para_save(), "", true), salvo1, "LUTAR repetido nao muda o save")
	checar(gs.ronda_ir("alley", "bike").is_empty(), "IR durante o premio: recusa")
	var p1 = gs.ronda_concluir()
	var p2 = gs.ronda_concluir()
	checar(p1 == p2 and p1 == info.night_prize, "ronda_concluir 2x devolve o mesmo premio, nao soma lenda")
	gs.ronda_voltar()
	gs.ronda_voltar()
	checar(gs.ronda_ativa == "" and gs.briga_estado().fase == "", "VOLTAR 2x e inofensivo")
	checar(gs.briga_resultado().is_empty() and gs.briga_previa().is_empty(), "sem premio nem previa depois de voltar")
	checar_igual(int(gs.lenda().legend), int(info.night_prize.legend), "lenda = a do premio, uma so vez")
	# SAIR na previa e depois chamar LUTAR
	_capuz(gs)
	var alvo_s: String = gs._beco.proximo()
	if alvo_s == "":
		alvo_s = "tire"
	gs.capuz["open"] = "scare"
	checar(not gs.ronda_ir("alley", alvo_s).is_empty(), "IR no proximo para o teste de SAIR")
	_fim_aprox(gs, "time")
	gs.ronda_concluir()
	checar(gs.briga_lutar(_tat(gs)).is_empty() and gs.ronda_ativa == "", "SAIR na previa e depois LUTAR: recusa")
	_lib(gs)


func _extremos() -> void:
	var gs := _novo("qa2a_extremos", 9999)
	checar(gs.briga_aberta(), "lenda 9999: briga aberta")
	var casos := [
		{"strength": 0.0, "agility": 0.0, "endurance": 0.0},
		{"strength": 1.0e300, "agility": 1.0e300, "endurance": 1.0e300},
		{"strength": 1.0e-9, "agility": 1.0e12, "endurance": 5.0},
	]
	var n := 0
	for a in casos:
		for b in ["tire", "bike", "gate"]:
			_capuz(gs)
			gs.permanente.black_cat["alley"] = {}
			if b != "tire":
				gs.permanente.black_cat["alley"]["tire"] = {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true}
			if b == "gate":
				gs.permanente.black_cat["alley"]["bike"] = {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true}
			gs.capuz["open"] = "scare"
			var r = gs.ronda_ir("alley", b)
			if r.is_empty():
				continue
			_fim_aprox(gs, ["scare", "seen", "time"][n % 3])
			var guard: Dictionary = gs.atributos.duplicate()
			gs.atributos = a.duplicate()
			var pv = gs.briga_previa()
			var ok_p: bool = not pv.is_empty()
			for t in gs.lutas.taticas:
				var ch := float(pv.risks[t.id].chance)
				ok_p = ok_p and ch >= 0.0 and ch <= 1.0 and not is_nan(ch)
			var info = gs.briga_lutar(_tat(gs))
			gs.atributos = guard
			checar(ok_p and not info.is_empty() and info.has("night_prize"), "atributos extremos %s vs %s: chance valida e luta roda" % [str(a.strength), b])
			var pr: Dictionary = info.get("night_prize", {})
			checar(int(pr.get("legend_gain", 0)) >= 1 and int(pr.get("legend_gain", 0)) <= 4, "lenda ganha entre 1 e 4 (%s)" % str(pr.get("legend_gain", -1)))
			gs.ronda_voltar()
			n += 1
	checar(int(_bc(gs).legend) < 1000000000, "lenda nao estourou")
	# lenda no teto 1e9
	gs.permanente.black_cat["legend"] = 999999999
	_capuz(gs)
	gs.permanente.black_cat["alley"] = {}
	gs.capuz["open"] = "scare"
	gs.ronda_ir("alley", "tire")
	_fim_aprox(gs, "scare")
	gs.atributos = GRANDE.duplicate()
	gs.briga_lutar(_tat(gs))
	checar(int(_bc(gs).legend) <= 1000000000, "lenda nunca passa do teto 1e9 (obtido %s)" % str(_bc(gs).legend))
	gs.ronda_voltar()
	_lib(gs)


func _saves_sujos() -> void:
	var gs := _novo("qa2a_sujo")
	var base: Dictionary = gs.para_save()
	var sujeiras := [
		"texto", [1, 2, 3], null, 42, true,
		{"tire": "x", "bike": [], "gate": null},
		{"tire": {"won": INF, "lost": NAN, "first_win_campaign": -INF, "challenge": true}},
		{"tire": {"won": "3", "lost": "1", "first_win_campaign": "2", "challenge": "true"}},
		{"tire": {"won": 1.5, "lost": -0.5, "first_win_campaign": 3.7, "challenge": 1}},
		{"tire": {"won": 5, "lost": 0, "first_win_campaign": 0, "challenge": true}},
		{"tire": {"won": 1, "lost": 0, "first_win_campaign": 99999, "challenge": true}},
		{"": {"won": 1}, " tire": {"won": 1}, "TIRE": {"won": 1}},
		{"tire": {}, "bike": {}, "gate": {}},
		{"tire": {"won": 0, "lost": 0, "first_win_campaign": 5, "challenge": true}},
		{"tire": {"won": 2147483648, "lost": 9223372036854775807, "first_win_campaign": 1, "challenge": false}},
	]
	var i := 0
	for s in sujeiras:
		var x: Dictionary = base.duplicate(true)
		x.permanent.black_cat["alley"] = s
		gs.aplicar_save(x)
		var a: Variant = _bc(gs).get("alley", {})
		var ok: bool = (a is Dictionary)
		if ok:
			for k in a:
				var f: Dictionary = a[k]
				ok = ok and k in ["tire", "bike", "gate"] and int(f.won) >= 0 and int(f.lost) >= 0 and int(f.won) <= 1000000000 and int(f.lost) <= 1000000000
				ok = ok and int(f.first_win_campaign) >= 0 and int(f.first_win_campaign) <= 4
				ok = ok and typeof(f.challenge) == TYPE_BOOL and (not bool(f.challenge) or int(f.won) > 0)
				ok = ok and (int(f.won) > 0 or int(f.first_win_campaign) == 0)
		checar(ok, "save sujo #%d carrega e fica coerente: %s" % [i, JSON.stringify(a)])
		var e = gs.esconderijo()
		checar(e.dossier.size() == 3 and e.board.size() >= 2, "save sujo #%d: Esconderijo abre sem erro" % i)
		i += 1
	# black_cat inteiro sujo
	for bc in ["texto", [], null, {"legend": "muita", "alley": {"tire": {"won": 1}}}, {"legend": -5, "rounds": -1, "scares": 9999, "alley": {"tire": {"won": 1}}}]:
		var y: Dictionary = base.duplicate(true)
		y.permanent["black_cat"] = bc
		gs.aplicar_save(y)
		var l = gs.lenda()
		checar(int(l.legend) >= 0 and int(l.scares) <= 3 * maxi(int(l.rounds), 0) + 3 * 0 + 3 * int(l.rounds) + 100000, "black_cat sujo (%s): lenda coerente (%s)" % [JSON.stringify(bc), JSON.stringify(l)])
		checar(gs.esconderijo().dossier.size() == 3, "black_cat sujo: Esconderijo abre")
	# marco e capuz sujos
	var z: Dictionary = base.duplicate(true)
	z.career["black_cat_hood"] = {"hood_s": -50.0, "next_at": 1e30, "open": ["alley"]}
	gs.aplicar_save(z)
	checar(gs.capuz.open in ["", "scare"], "capuz sujo: open valido (%s)" % str(gs.capuz.open))
	# save antigo (sem o campo, versao 12-ish): abre igual, nao grava alley
	var o: Dictionary = base.duplicate(true)
	o.permanent.black_cat.erase("alley")
	gs.aplicar_save(o)
	checar(not gs.para_save().permanent.black_cat.has("alley"), "save antigo sem alley: para_save() nao inventa o campo")
	gs.salvar()
	var doc = JSON.parse_string(FileAccess.get_file_as_string(gs.store.pasta.path_join("save.json")))
	checar(doc is Dictionary and int(doc.get("version", -1)) == 13, "versao do save em disco continua 13")
	_lib(gs)


func _muitas_noites() -> void:
	var gs := _novo("qa2a_muitas")
	gs.geradores[gs.dados.geradores[0].id] = 2
	var rounds0 := int(_bc(gs).rounds)
	var scares0 := int(_bc(gs).scares)
	var noites := 0
	var vit := {}
	for _i in 4000:
		gs.tick(1.0)
		gs.capuz["open"] = "scare"
		gs.capuz["next_at"] = 0.0
		if not gs.capuz_info().get("clickable", false):
			continue
		var alvo = gs._beco.proximo()
		if alvo == "":
			for b in gs.ronda_cfg.noites.alley.bandits:
				if gs._beco.so_desafio(str(b.id)):
					alvo = str(b.id)
					break
		var forte: bool = (noites % 4) != 0
		if alvo == "":
			# tudo vencido e com desafio: o capuz ainda leva ao SUSTO
			gs.ronda_ir()
			gs.ronda_jogo().sustos = 1
			gs.ronda_concluir()
			gs.ronda_voltar()
		else:
			gs.ronda_ir("alley", alvo)
			_fim_aprox(gs, ["scare", "seen", "time"][noites % 3])
			var g: Dictionary = gs.atributos.duplicate()
			gs.atributos = (GRANDE if forte else PEQUENO).duplicate()
			var r = gs.briga_lutar(gs.lutas.taticas[noites % gs.lutas.taticas.size()].id)
			gs.atributos = g
			if not r.is_empty() and r.night_prize.win:
				vit[alvo] = int(vit.get(alvo, 0)) + 1
			gs.ronda_voltar()
		noites += 1
		if noites >= 80:
			break
	var l = gs.lenda()
	checar(noites >= 40, "muitas noites seguidas: %d" % noites)
	checar(int(l.rounds) == rounds0 + noites, "rounds = noites jogadas (%d)" % (int(l.rounds) - rounds0))
	checar(int(l.scares) <= 3 * int(l.rounds) and int(l.scares) >= scares0, "scares <= 3 x rounds (scares %d, rounds %d)" % [int(l.scares), int(l.rounds)])
	checar(vit.size() == 3, "os 3 bandidos acabaram vencidos (%s)" % JSON.stringify(vit))
	var a: Dictionary = _bc(gs).alley
	var coerente := true
	for k in a:
		coerente = coerente and int(a[k].won) + int(a[k].lost) > 0
	checar(coerente, "so fichas com partida no save")
	var q = gs.quadro_noite()
	checar(q.size() >= 2 and (q[1].night == "quiet" or q[1].night == "alley"), "quadro coerente no fim")
	# o save em disco volta igual
	gs.salvar()
	var g2: Node = GameStateScript.new()
	g2.inicializar(gs.store.pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar_igual(JSON.stringify(g2.permanente.black_cat), JSON.stringify(gs.permanente.black_cat), "ida e volta no disco depois de %d noites" % noites)
	_lib(g2)
	_lib(gs)


## previa x motor com 1000 sementes independentes: a chance mostrada (200 sementes) tem de cair perto da frequencia real.
func _previa_x_motor() -> void:
	var gs := _novo("qa2a_previa")
	var pior := 0.0
	var linhas := []
	var ordem := ["tire", "bike", "gate"]
	for k in [0.5, 0.8, 1.0, 1.3]:
		for id in ordem:
			gs.permanente.black_cat["alley"] = {}
			for ant in ordem:
				if ant == id:
					break
				gs.permanente.black_cat["alley"][ant] = {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true}
			var b: Dictionary = gs.ronda_cfg.noites.alley.bandits.filter(func(x): return x.id == id)[0]
			gs.atributos = {"strength": float(b.strength) * k, "agility": float(b.agility) * k, "endurance": float(b.endurance) * k}
			gs.capuz["open"] = "scare"
			gs.capuz["next_at"] = 0.0
			gs.tick(1.0)
			var ri = gs.ronda_ir("alley", id)
			if ri.is_empty():
				checar(false, "IR %s" % id)
				continue
			_fim_aprox(gs, "seen")
			var p = gs.briga_previa()
			var cru := [gs.atributos.strength, gs.atributos.agility, gs.atributos.endurance]
			var adv: Array = [b.strength, b.agility, b.endurance, b.passive]
			for t in gs.lutas.taticas:
				var cen: Dictionary = gs.motor.preparar(cru, adv, t.id)
				var rng := RandomNumberGenerator.new()
				var v := 0
				var N := 1000
				for s in range(10001, 10001 + N):
					rng.seed = s
					var r: Dictionary = gs.motor.rodar(cen, rng, PackedFloat64Array(), false)
					if bool(r.win):
						v += 1
				var real := float(v) / float(N)
				var mostrada := float(p.risks[t.id].chance)
				pior = maxf(pior, absf(real - mostrada))
				linhas.append("k=%.1f %s/%s mostrada %.3f real(1000) %.3f" % [k, id, t.id, mostrada, real])
			gs.ronda_concluir()
	print("   ", "\n   ".join(linhas))
	checar(pior <= 0.08, "previa (200 sementes) bate com 1000 sementes independentes, pior diferenca %.3f" % pior)
	_lib(gs)


func _rngs_e_relogio() -> void:
	var gs := _novo("qa2a_rng")
	_capuz(gs)
	var est := {}
	for k in ["rng", "_rng_evento", "_rng_fala", "_rng_sucessao", "_rng_treino"]:
		est[k] = gs.get(k).state
	var ps: float = gs.get("play_seconds") if gs.get("play_seconds") != null else -1.0
	var para_antes = gs.para_save()
	gs.ronda_ir("alley", "tire")
	for _i in 300:
		gs.tick(0.1)
	checar(gs.briga_estado().fase == "previa", "aproximacao inteira por tick real (30 s) chega a previa")
	checar_igual(JSON.stringify(gs.para_save().career.get("play_seconds", 0)), JSON.stringify(para_antes.career.get("play_seconds", 0)), "relogio de jogo parado durante a aproximacao e a previa")
	checar_igual(JSON.stringify(gs.para_save().career.get("campaign_seconds", 0)), JSON.stringify(para_antes.career.get("campaign_seconds", 0)), "campaign_seconds parado")
	checar_igual(JSON.stringify(gs.para_save().career.get("money", 0)), JSON.stringify(para_antes.career.get("money", 0)), "dinheiro parado")
	gs.briga_lutar(_tat(gs))
	for _i in 50:
		gs.tick(1.0)  # na tela do premio
	for k in est:
		checar(gs.get(k).state == est[k], "%s intocado depois da noite inteira" % k)
	# 120 s depois a sala volta sozinha, so uma vez
	gs.tick(100.0)
	checar(gs.ronda_ativa == "", "trava de 120 s devolve a sala")
	_lib(gs)


func _estilos_extra() -> void:
	var gs := _novo("qa2a_estilo")
	var d: DiscipulosData = gs.disciples
	# 500 rascunhos reais pelo jogo: nenhum com estilo, mesmo com tudo liberado
	gs.permanente.black_cat["alley"] = {"tire": {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true},
		"bike": {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true}, "gate": {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true}}
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ruim := 0
	for _i in 500:
		var r: Dictionary = d.sortear(rng, [])
		for campo in r.look:
			if d.tem_requisito(campo, str(r.look[campo])):
				ruim += 1
	checar_igual(ruim, 0, "500 rascunhos com os 3 estilos liberados: nenhum sorteou estilo")
	for campo in ["headband_color", "socks", "shorts_color"]:
		var l: Array = d.opcoes_ativas(campo)
		var ultimo := str(l[-1])
		checar(d.tem_requisito(campo, ultimo) and d.marca_da_opcao(campo, ultimo) == "cat", "%s: o estilo e o ULTIMO da lista e tem a marca do gato (%s)" % [campo, ultimo])
		var normais := l.filter(func(x): return not d.tem_requisito(campo, str(x)))
		checar(normais.size() == l.size() - 1, "%s: so 1 estilo na lista" % campo)
	# re-travar: perde o estilo => some da lista e do look
	gs.permanente.black_cat["alley"] = {}
	checar(not ("night" in d.opcoes_ativas("headband_color")), "estilo some da lista se a ficha some (save sujo/restaurado)")
	_lib(gs)


## O disco: aproximacao nao grava, LUTAR grava uma vez (conta o numero de vezes que o save.json muda).
func _disco() -> void:
	var gs := _novo("qa2a_disco")
	_capuz(gs)
	gs.salvar()
	var arq: String = gs.store.pasta.path_join("save.json")
	var m0 := FileAccess.get_md5(arq)
	gs.ronda_ir("alley", "tire")
	for _i in 120:
		gs.tick(0.1)
	_fim_aprox(gs, "scare")
	gs.briga_previa()
	checar_igual(FileAccess.get_md5(arq), m0, "save.json em disco igual durante aproximacao e previa (autosave desligado aqui)")
	# autosave ligado: simula o autosave durante a noite
	gs.autosave_ativo = true
	gs.tick(31.0)
	var g2: Node = GameStateScript.new()
	g2.inicializar(gs.store.pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar(g2.capuz.open == "scare" and not _bc(g2).has("alley"), "autosave no meio da previa: ao reabrir, capuz no prego e nada gravado (open=%s)" % str(g2.capuz.open))
	_lib(g2)
	gs.autosave_ativo = false
	gs.atributos = GRANDE.duplicate()
	gs.briga_lutar(_tat(gs))
	var g3: Node = GameStateScript.new()
	g3.inicializar(gs.store.pasta, "res://data/config.json")
	g3.autosave_ativo = false
	checar(int(g3.permanente.black_cat.alley.tire.won) == 1 and g3.capuz.open == "" and int(g3.permanente.black_cat.rounds) == 7, "fechar logo apos LUTAR: tudo gravado uma vez")
	# reabrir e reabrir de novo sem tocar: idempotente
	g3.salvar()
	var g4: Node = GameStateScript.new()
	g4.inicializar(gs.store.pasta, "res://data/config.json")
	g4.autosave_ativo = false
	checar_igual(JSON.stringify(g4.permanente.black_cat), JSON.stringify(g3.permanente.black_cat), "reabrir 2x: identico")
	_lib(g3)
	_lib(g4)
	_lib(gs)


## "quem briga = quem so faz SUSTO" por outro roteiro: B le o Esconderijo, sai na aproximacao, entra de novo, mexe na previa e luta (taticas variadas).
func _corrida_b(nome: String, modo: String) -> Dictionary:
	var gs := _novo(nome)
	gs.geradores[gs.dados.geradores[0].id] = 3
	var n := 0
	for _i in 2400:
		gs.tick(1.0)
		if not gs.capuz_info().get("clickable", false):
			continue
		n += 1
		if modo == "susto":
			gs.ronda_ir()
			gs.ronda_jogo().sustos = 1
			gs.ronda_concluir()
			gs.ronda_voltar()
			continue
		gs.esconderijo()
		gs.dossie()
		gs.quadro_noite()
		var alvo: String = gs._beco.proximo()
		if alvo == "":
			for b in gs.ronda_cfg.noites.alley.bandits:
				if gs._beco.so_desafio(str(b.id)):
					alvo = str(b.id)
					break
		if alvo == "":
			gs.ronda_ir()
			gs.ronda_jogo().sustos = 1
			gs.ronda_concluir()
			gs.ronda_voltar()
			continue
		gs.ronda_ir("alley", alvo)
		for _k in 30:
			gs.tick(0.1)
		gs.ronda_concluir()  # SAIR: o capuz continua
		gs.ronda_ir("alley", alvo)
		_fim_aprox(gs, ["scare", "seen", "time"][n % 3])
		gs.briga_previa()
		var guard: Dictionary = gs.atributos.duplicate()
		gs.atributos = (GRANDE if n % 3 != 1 else PEQUENO).duplicate()
		gs.briga_lutar(gs.lutas.taticas[n % gs.lutas.taticas.size()].id)
		gs.atributos = guard
		gs.ronda_voltar()
	var e: Dictionary = gs.para_save()
	e.career.erase("black_cat_hood")
	e.permanent.erase("black_cat")
	var r := {"save": JSON.stringify(e, "", true), "alley": _bc(gs).get("alley", {}).duplicate(true), "noites": n}
	for k in ["rng", "_rng_evento", "_rng_fala", "_rng_sucessao", "_rng_treino"]:
		r[k] = gs.get(k).state
	_lib(gs)
	return r


func _quem_briga_igual_b() -> void:
	var a := _corrida_b("qa2a_ig_a", "susto")
	var b := _corrida_b("qa2a_ig_b", "briga")
	checar(a.noites == b.noites and a.noites >= 8, "mesmas noites (%d)" % int(a.noites))
	checar(not b.alley.is_empty() and a.alley.is_empty(), "B brigou (%s), A so SUSTO" % JSON.stringify(b.alley))
	checar_igual(a.save == b.save, true, "save igual campo a campo (sem black_cat e capuz) com roteiro B")
	for k in ["rng", "_rng_evento", "_rng_fala", "_rng_sucessao", "_rng_treino"]:
		checar(a[k] == b[k], "sorteio %s igual" % k)
