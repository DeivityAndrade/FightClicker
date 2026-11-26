extends "res://tests/test_base.gd"
## Ronda 2a1 (brigas de beco): destrave e ordem, aproximação, prévia honesta (chance do motor e chance do desafio nas mesmas 200 sementes),
## gravação única no LUTAR, derrota pequena, desafios e estilos, Dossiê, save sujo, D2 (SOLTE E CLIQUE!), "quem briga = quem só faz SUSTO".
## Cobre A2, A4-A7, A10, A11 e A14 do design (docs/fases/ronda2a-design.md §10) no que é lógica; A1 é a foto (tools/refatoracao/foto.gd).
## Tudo em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")
const GRANDE := {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
const PEQUENO := {"strength": 1.0, "agility": 1.0, "endurance": 1.0}


func rodar_testes() -> void:
	_teste_dados()
	_teste_python_exato()
	_teste_destrave()
	_teste_quadro_e_dossie()
	_teste_aproximacao_e_sair()
	_teste_previa_honesta()
	_teste_luta_grava_uma_vez()
	_teste_derrota_pequena()
	_teste_desafios_e_estilos()
	_teste_fechar_o_jogo()
	_teste_save_sujo()
	_teste_d2_dica()
	_teste_sem_rosto_nem_sangue()
	_teste_quem_briga_igual()


## Limiar da lenda do nível i (0 = nível 1) e intervalo do capuz: sempre do ronda.json (2a2: nada fixo no teste).
func _LV(i: int) -> int:
	return int(RondaData.carregar().niveis[i])


func _IV() -> float:
	return float(RondaData.carregar().capuz.interval_s)


func _novo(nome: String, lenda: int = -1, com_marco: bool = true, campanha: int = 4) -> Node:
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
	if lenda < 0:
		lenda = _LV(2)  # nível 3: as brigas abrem
	var nivel: int = gs.ronda_cfg.nivel_de(lenda)
	gs.permanente["black_cat"] = {"legend": lenda, "rounds": 6, "scares": 3, "shown_level": nivel, "open_campaign": 3}
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _andar(gs: Node, s: int, passo: float = 1.0) -> void:
	for _i in s:
		gs.tick(passo)


## Espera o capuz (de 0 ou do próximo relógio).
func _capuz(gs: Node) -> bool:
	for _i in 420:
		if gs.capuz_info().get("clickable", false):
			return true
		gs.tick(1.0)
	return false


## Acaba a aproximação na hora: "scare" | "seen" | "time". Depois o tick passa a noite para a prévia.
func _aproximar(gs: Node, como: String) -> void:
	var j: RondaLogica = gs.ronda_jogo()
	j.sustos = 1 if como == "scare" else 0
	j.vistos = 1 if como == "seen" else 0
	j.fase = "fim"
	gs.tick(0.01)


func _tatica(gs: Node) -> String:
	return str(gs.lutas.taticas[0].id)


## Uma noite de briga inteira: IR, aproximação, LUTAR com os atributos dados (restaura os da carreira), VOLTAR. Devolve a luta.
func _briga(gs: Node, bandido: String, como: String, atributos: Dictionary) -> Dictionary:
	if not _capuz(gs):
		return {}
	if gs.ronda_ir("alley", bandido).is_empty():
		return {}
	_aproximar(gs, como)
	var guardados: Dictionary = gs.atributos.duplicate()
	gs.atributos = atributos.duplicate()
	var info: Dictionary = gs.briga_lutar(_tatica(gs))
	gs.atributos = guardados
	gs.ronda_voltar()
	return info


## Save sem o que a noite pode mudar (black_cat, capuz) e sem os relogios (a espera pelo capuz anda o tempo).
func _sem_tempo(s: Dictionary) -> Dictionary:
	s.permanent.erase("black_cat")
	for k in ["black_cat_hood", "play_seconds", "campaign_seconds", "training_invite"]:
		s.career.erase(k)
	return s


func _bc(gs: Node) -> Dictionary:
	return gs.permanente.get("black_cat", {})


func _ficha(gs: Node, id: String) -> Dictionary:
	return _bc(gs).get("alley", {}).get(id, {})


# ---------------------------------------------------------------- dados
func _teste_dados() -> void:
	var gs := _novo("r2a_dados")
	var cfg: RondaData = gs.ronda_cfg
	checar(cfg.avisos.is_empty(), "ronda.json sem avisos do validador (%s)" % str(cfg.avisos))
	var n: Dictionary = cfg.noites.get("alley", {})
	checar(not n.is_empty() and n.kind == "alley_fight" and n.disponivel, "noite alley lida")
	checar_igual(n.bandits.size(), 3, "3 bandidos")
	checar_igual(n.requires, {"legend_level": 3, "milestone": "regional_league_opened"}, "requires: lenda 3 e o marco da liga")
	checar_igual(float(n.countdown_s) + float(n.approach_s), 10.0, "contagem + aproximacao = 10 s (A7)")
	checar_igual(float(cfg.noites.scare.hold_hint_s), 0.6, "D2: hold_hint_s 0,6")
	checar_igual(str(cfg.capuz.hideout_from), "alley", "hood.hideout_from")
	var ids: Array = n.bandits.map(func(b): return b.id)
	checar_igual(ids, ["tire", "bike", "gate"], "ordem dos bandidos")
	var passivas: Array = n.bandits.map(func(b): return b.passive.id)
	checar_igual(passivas, ["adv_wide_base", "adv_blindado", "adv_iron_chin"], "passivas da liga (validadas pela mesma regra)")
	for b in n.bandits:
		checar(not b.style.is_empty() and not b.challenge.is_empty(), "%s: desafio e estilo" % b.id)
		checar(gs.disciples.tem_requisito(str(b.style.field), str(b.style.option)), "%s: opcao %s com requires no disciples.json" % [b.id, b.style.option])
	# A3: o corte do Bairro agradece vale +20% no jogo (aprovado pelo dono)
	checar_igual(float(gs.lutas.no_da_arvore("cat_thanks").get("effect_value", 0.0)), 0.2, "cat_thanks = +20% (equipe x1,2)")
	# dado ruim: kind novo com bandido invalido, requires desconhecido
	var ruim := RondaData.new()
	ruim._ler({"night_order": ["alley"], "nights": {"alley": {"kind": "alley_fight", "requires": {"lua": 3}, "countdown_s": 2, "approach_s": 8,
		"bandits": [{"id": "x", "strength": 0, "agility": 1, "endurance": 1, "approach": {"id": "x"}}]}}})
	checar(ruim.vazio and not ruim.avisos.is_empty(), "bandido com atributo 0: ignorado com aviso (e noite sem bandido vira vazia)")
	var r2 := RondaData.new()
	r2._ler({"night_order": ["alley"], "nights": {"alley": {"kind": "alley_fight", "requires": {"lua": 3}, "countdown_s": 2, "approach_s": 8,
		"bandits": [{"id": "x", "strength": 5, "agility": 5, "endurance": 5, "approach": {"id": "x"}, "challenge": {"type": "voar"}}]}}})
	checar(not r2.vazio and not bool(r2.noites.alley.disponivel) and r2.noites.alley.bandits[0].challenge.is_empty(), "requires desconhecido = indisponivel; desafio com tipo desconhecido = sem desafio")
	_liberar(gs)


# ---------------------------------------------------------------- casos exatos contra o simulador Python (A6)
func _aprox(a: float, b: float, rel: float) -> bool:
	return absf(a - b) <= rel * maxf(1.0, maxf(absf(a), absf(b)))


func _teste_python_exato() -> void:
	var casos_j: Variant = JSON.parse_string(ler("res://tests/data/ronda2a_casos.json"))
	if not (casos_j is Dictionary):
		checar(false, "tests/data/ronda2a_casos.json existe (rode ronda2a_sim.py exportar)")
		return
	var gs := _novo("r2a_casos")
	var gym := GymData.carregar()
	var bandidos := {}
	for b in gs.ronda_cfg.noites.alley.bandits:
		bandidos[str(b.id)] = b
	bandidos[str(gs.ronda_cfg.noites.alley.boss.id)] = gs.ronda_cfg.noites.alley.boss  # 2a2: o Apagao nos mesmos casos exatos
	var iguais := 0
	var primeira := ""
	var soma := 0.0
	var desafios_ok := 0
	var casos: Array = casos_j.exatos
	for c in casos:
		var m := Luta.new(gs.lutas)
		if str(c.art) != "":
			m.passiva = gym.arte(str(c.art)).get("passive" if int(c.passive) == 1 else "passive_2").duplicate(true)
			m.extra_passiva = float(c.extra)
		var b: Dictionary = bandidos[str(c.opponent_id)]
		var adv: Array = [b.strength, b.agility, b.endurance, b.passive]
		var r := m.lutar_com_sorteios(c.player, adv, c.tactic, PackedFloat64Array(c.draws), true)
		var fim: String = str(r.get("finish", "damage" if r.ko else "points"))
		var erro := ""
		if r.win != c.win or r.ko != c.ko or fim != str(c.finish):
			erro = "resultado (win/ko/finish)"
		elif absf(r.t_ko - c.t_ko) > 1e-9 or absf(r.t_end - c.t_end) > 1e-9:
			erro = "t_ko/t_end"
		elif not _aprox(r.pct_player, c.pct_player, 1e-9) or not _aprox(r.pct_opponent, c.pct_opponent, 1e-9):
			erro = "% de vida"
		elif r.draws_used != c.draws.size() or r.events.size() != c.events.size():
			erro = "sorteios ou numero de eventos"
		else:
			for i in r.events.size():
				var e: Dictionary = r.events[i]
				var p: Array = c.events[i]
				if absf(e.t - p[0]) > 6e-4 or e.who != int(p[1]) or e.type != p[2] or e.counter != p[3]:
					erro = "evento %d" % i
					break
				if e.type != "dodge" and (not _aprox(e.damage, p[4], 1e-7) or not _aprox(e.life_after, p[5], 1e-7)):
					erro = "dano/vida do evento %d" % i
					break
		if erro == "":
			iguais += 1
		elif primeira == "":
			primeira = "%s (%s, %s, %s)" % [erro, c.opponent_id, c.art, c.tactic]
		soma += absf(m.chance(c.player, adv, c.tactic, 200) - float(c.chance_200))
		# o desafio da luta: o mesmo no Python e no jogo (surprise = so a vitoria; o SUSTO vem da aproximacao)
		if bool(gs._beco._cumpriu(b, r, "scare")) == bool(c.challenge.done):
			desafios_ok += 1
	checar_igual(iguais, casos.size(), "GDScript = Python em %d lutas contra os bandidos%s" % [casos.size(), "" if primeira == "" else " | 1a falha: " + primeira])
	checar(casos.size() >= 100, "pelo menos 100 casos exatos (%d)" % casos.size())
	checar(soma / casos.size() <= 0.04, "chance de 200 lutas bate com o Python (media %.3f)" % [soma / casos.size()])
	checar_igual(desafios_ok, casos.size(), "a condicao do desafio da noite bate com o simulador nas mesmas lutas")
	_liberar(gs)


# ---------------------------------------------------------------- destrave e ordem (A5)
func _teste_destrave() -> void:
	var g1 := _novo("r2a_dest1", _LV(2) - 1)
	_andar(g1, 181)
	checar(not g1.briga_aberta() and not g1.capuz_info().hideout, "lenda abaixo do nivel 3: briga fechada, o capuz leva ao SUSTO")
	checar(g1.ronda_ir("alley", "tire").is_empty(), "lenda abaixo do nivel 3: ronda_ir(alley) recusa")
	var i1: Dictionary = g1.ronda_ir()
	checar(str(i1.get("night", "")) == "scare" and g1.ronda_ativa == "scare", "lenda abaixo do nivel 3: ronda_ir() = SUSTO de sempre")
	var g2 := _novo("r2a_dest2", _LV(2), false)
	_andar(g2, 181)
	checar(not g2.briga_aberta() and not g2.capuz_info().hideout, "nivel 3 sem o marco da liga: briga fechada")
	var g3 := _novo("r2a_dest3", _LV(2), true)
	_andar(g3, 181)
	checar(g3.briga_aberta() and g3.capuz_info().hideout and g3.capuz_info().clickable, "nivel 3 + marco: Esconderijo")
	checar_igual(g3.capuz.open, "scare", "o prego continua guardando 'scare'")
	# 2o e 3o so em ordem
	checar(g3.ronda_ir("alley", "bike").is_empty() and g3.ronda_ir("alley", "gate").is_empty() and g3.ronda_ativa == "", "o 2o e o 3o fechados com o 1o por vencer")
	g3.permanente.black_cat["alley"] = {"tire": {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true}}
	checar_igual(g3._beco.proximo(), "bike", "1o vencido: o proximo e o 2o")
	checar(g3._beco.pode_ir("bike") and not g3._beco.pode_ir("gate") and not g3._beco.pode_ir("tire"), "pode_ir: so o 2o (o 1o ja tem o desafio)")
	g3.permanente.black_cat["alley"]["bike"] = {"won": 1, "lost": 0, "first_win_campaign": 5, "challenge": false}
	checar_igual(g3._beco.proximo(), "gate", "2o vencido: o proximo e o 3o")
	checar(g3._beco.pode_ir("gate") and g3._beco.pode_ir("bike"), "o 2o vencido sem desafio volta como DESAFIO")
	# sem o capuz no prego nao entra
	var g4 := _novo("r2a_dest4")
	checar(g4.ronda_ir("alley", "tire").is_empty() and g4.esconderijo().open, "sem capuz: ronda_ir(alley) recusa (o Esconderijo so le)")
	for g in [g1, g2, g3, g4]:
		_liberar(g)


# ---------------------------------------------------------------- quadro ESTA NOITE e Dossiê
func _teste_quadro_e_dossie() -> void:
	var gs := _novo("r2a_quadro")
	var q: Array = gs.quadro_noite()
	checar(q.size() == 2 and q[0].night == "scare" and q[1].night == "alley" and q[1].bandit == "tire", "quadro: SUSTO + 1o bandido")
	checar(q[1].name == "???" and str(q[1].nickname) != "" and not q[1].challenge_only and not q[1].revenge, "bandido: nome oculto, apelido, sem revanche")
	checar(str(q[1].challenge_text) != "" and q[1].passive.id == "adv_wide_base" and q[1].profile == "FORTE", "bandido: desafio, passiva e perfil")
	var d: Array = gs.dossie()
	checar(d.size() == 3 and not d[0].known and d[0].name == "???" and str(d[0].missing_text) == "" and str(d[1].missing_text) != "", "Dossie: 3 fichas; o 2o diz o que falta")
	checar(str(d[0].rap_sheet) == "" and str(d[0].stamp) == "" and str(d[0].witness) == "", "ficha fechada: sem ficha corrida, selo nem testemunha")
	var e: Dictionary = gs.esconderijo()
	checar(e.open and e.trophies.size() == 4 and e.trophies.all(func(t): return t.state == "empty") and e.legend.level == 3 and not e.boss.known and str(e.boss.missing_text).contains("5"), "Esconderijo: aberto, prateleira com 4 lugares vazios, ficha do chefe com LENDA 5")
	# depois de perder (revanche) e de vencer sem desafio
	gs.permanente.black_cat["alley"] = {"tire": {"won": 0, "lost": 2, "first_win_campaign": 0, "challenge": false}}
	checar(gs.quadro_noite()[1].revenge and gs.dossie()[0].revenge and not gs.dossie()[0].known, "perdeu e nao venceu: REVANCHE no quadro e na ficha")
	gs.permanente.black_cat["alley"] = {"tire": {"won": 1, "lost": 0, "first_win_campaign": 5, "challenge": false}}
	var q2: Array = gs.quadro_noite()
	checar(q2.size() == 3 and q2[1].bandit == "bike" and q2[2].bandit == "tire" and q2[2].challenge_only, "vencido sem desafio: cartao DESAFIO depois do proximo")
	checar(q2[2].name != "???" and gs.dossie()[0].known and str(gs.dossie()[0].stamp).contains("5"), "ficha aberta mostra o nome e o carimbo da campanha")
	gs.permanente.black_cat["alley"] = {"tire": {"won": 1, "lost": 0, "first_win_campaign": 5, "challenge": true}, "bike": {"won": 1, "lost": 0, "first_win_campaign": 6, "challenge": true},
		"gate": {"won": 1, "lost": 1, "first_win_campaign": 7, "challenge": true}}
	var q3: Array = gs.quadro_noite()
	checar(q3.size() == 2 and q3[1].night == "boss" and q3[1].locked and str(q3[1].missing_text) != "", "os 3 vencidos com desafio: cartao do chefe trancado (2a2)")
	_liberar(gs)


# ---------------------------------------------------------------- aproximacao, SAIR (A7)
func _teste_aproximacao_e_sair() -> void:
	var gs := _novo("r2a_aprox")
	_andar(gs, 181)
	var antes: String = JSON.stringify(gs.para_save(), "", true)
	var info: Dictionary = gs.ronda_ir("alley", "tire")
	checar(info.night == "alley" and info.kind == "alley_fight" and info.bandit == "tire" and info.occurrences == ["tire"], "ronda_ir(alley): uma ocorrencia, a do bandido")
	checar(float(info.countdown_s) == 2.0 and float(info.approach_s) == 8.0 and str(info.challenge.type) == "surprise" and str(info.challenge.text) != "", "tempos e desafio da noite")
	checar(not gs.sala_ativa() and gs.ronda_ativa == "alley" and gs.briga_estado().fase == "aproximacao", "jogo congelado e fase aproximacao")
	checar_igual(JSON.stringify(gs.para_save(), "", true), antes, "IR nao grava nada")
	var tempo := 0.0
	while tempo < 12.0 and gs.briga_estado().fase == "aproximacao":
		gs.tick(0.1)
		tempo += 0.1
	checar(gs.briga_estado().fase == "previa" and tempo <= 10.2, "sem fazer nada: a aproximacao acaba por tempo em ~10 s (%.1f s)" % tempo)
	checar_igual(gs.briga_estado().approach, "time", "sem SUSTO nem VISTO = TEMPO")
	checar(gs.briga_previa().has("risks") and gs.luta.is_empty() and gs.ronda_ativa == "alley", "prévia disponivel; GameState.luta intocada")
	# SAIR na previa: nada grava, o capuz segue no prego
	var r: Dictionary = gs.ronda_concluir()
	checar(bool(r.get("left", false)) and gs.ronda_ativa == "" and gs.sala_ativa(), "SAIR: devolve a sala")
	checar_igual(JSON.stringify(gs.para_save(), "", true), antes, "SAIR nao grava nada: o save e o mesmo de antes do IR (capuz no prego, lenda igual)")
	_andar(gs, 1)
	checar_igual(gs.capuz_visivel(), "scare", "o capuz continua no prego")
	# SAIR na aproximacao
	antes = JSON.stringify(gs.para_save(), "", true)
	gs.ronda_ir("alley", "tire")
	gs.tick(1.0)
	checar(gs.ronda_concluir().get("left", false) and gs.ronda_ativa == "", "SAIR na aproximacao: {left}")
	checar_igual(JSON.stringify(gs.para_save(), "", true), antes, "SAIR na aproximacao: save igual")
	# briga_lutar fora da previa recusa
	gs.ronda_ir("alley", "tire")
	checar(gs.briga_lutar(_tatica(gs)).is_empty() and gs.briga_previa().is_empty(), "na aproximacao: sem previa e sem LUTAR")
	_aproximar(gs, "scare")
	checar(gs.briga_lutar("tatica_que_nao_existe").is_empty() and gs.briga_estado().fase == "previa", "tatica invalida: recusa e continua na previa")
	gs.ronda_voltar()
	# a trava de seguranca na tela de premio
	_liberar(gs)


# ---------------------------------------------------------------- previa honesta (A6)
func _teste_previa_honesta() -> void:
	for arte in ["", "boxing", "bjj", "muay_thai"]:
		var gs := _novo("r2a_previa_%s" % arte)
		if arte != "":
			gs.arte_id = arte
			gs.passiva_carreira = 1
			gs._academia._atualizar_passiva()
		gs.atributos = {"strength": 3.0e8, "agility": 2.0e8, "endurance": 4.0e8}
		_andar(gs, 181)
		var estados := {}
		for k in ["rng", "_rng_evento", "_rng_fala", "_rng_sucessao", "_rng_treino"]:
			estados[k] = gs.get(k).state
		for id in ["tire", "bike", "gate"]:
			var b: Dictionary = gs.ronda_cfg.noites.alley.bandits.filter(func(x): return x.id == id)[0]
			gs.permanente.black_cat["alley"] = {}
			for ant in gs.ronda_cfg.noites.alley.bandits:
				if ant.id == id:
					break
				gs.permanente.black_cat["alley"][str(ant.id)] = {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true}
			gs.capuz["open"] = "scare"
			if gs.ronda_ativa != "":
				gs.ronda_voltar()
			checar(not gs.ronda_ir("alley", id).is_empty(), "%s/%s: IR" % [arte, id])
			_aproximar(gs, "scare")
			var p: Dictionary = gs.briga_previa()
			var cru := [gs.atributos.strength, gs.atributos.agility, gs.atributos.endurance]
			var adv: Array = [b.strength, b.agility, b.endurance, b.passive]
			var ok := true
			var ok_ch := true
			for t in gs.lutas.taticas:
				var det: Dictionary = gs.motor.chance_detalhada(cru, adv, t.id)
				ok = ok and absf(float(p.risks[t.id].chance) - float(det.chance)) < 1.0e-12
				if str(b.challenge.type) != "surprise":
					# a chance do desafio, contada de fora nas mesmas sementes 1..200
					var cen: Dictionary = gs.motor.preparar(cru, adv, t.id)
					var rng := RandomNumberGenerator.new()
					var c := 0
					for s in range(1, 201):
						rng.seed = s
						var r: Dictionary = gs.motor.rodar(cen, rng, PackedFloat64Array(), false)
						if gs._beco._cumpriu(b, r, "scare"):
							c += 1
					ok_ch = ok_ch and int(p.challenge.by_tactic[t.id]) == int(floor(float(c) / 200.0 * 100.0 + 1.0e-9))
					ok_ch = ok_ch and str(p.challenge.line_by_tactic[t.id]).contains(str(p.challenge.by_tactic[t.id]))
			checar(ok, "%s/%s: a chance da previa e a do motor (chance_detalhada com o array do bandido)" % [arte, id])
			checar(ok_ch, "%s/%s: a chance do desafio e contada nas mesmas 200 sementes" % [arte, id])
			if str(b.challenge.type) == "surprise":
				checar(p.challenge.by_tactic.is_empty() and bool(p.challenge.done), "%s/%s: surprise: sem porcentagem, FEITO com SUSTO" % [arte, id])
			checar(p.you.strength == cru[0] and p.show_percent and str(p.opp_passive_id) == str(b.passive.id), "%s/%s: atributos crus e passiva dele na previa" % [arte, id])
			if arte != "":
				checar(str(p.get("passive_name", "")) != "" and p.has("passive_tactics"), "%s/%s: a passiva da sua arte viaja na previa" % [arte, id])
			gs.ronda_concluir()
		for k in estados:
			checar(gs.get(k).state == estados[k], "%s: a previa nao mexe em %s" % [arte, k])
		_liberar(gs)
	# AQUECIDO nao entra e nao e gasto
	var g2 := _novo("r2a_previa_warm")
	g2.arte_id = "boxing"
	g2._academia._atualizar_passiva()
	g2.atributos = {"strength": 3.0e8, "agility": 2.0e8, "endurance": 4.0e8}
	g2.convite["warm"] = true
	checar(g2.aquecido(), "AQUECIDO ligado para o teste")
	_andar(g2, 181)
	g2.ronda_ir("alley", "tire")
	_aproximar(g2, "seen")
	var pw: Dictionary = g2.briga_previa()
	checar(float(pw.you.strength) == 3.0e8 and not pw.has("warm"), "previa da noite: atributos crus, sem a linha do AQUECIDO")
	g2.briga_lutar(_tatica(g2))
	checar(g2.aquecido(), "AQUECIDO nao e gasto pela noite")
	_liberar(g2)


# ---------------------------------------------------------------- LUTAR: gravacao unica (A6, A11)
func _teste_luta_grava_uma_vez() -> void:
	var gs := _novo("r2a_luta")
	_andar(gs, 181)
	var estados := {}
	for k in ["rng", "_rng_evento", "_rng_fala", "_rng_sucessao", "_rng_treino"]:
		estados[k] = gs.get(k).state
	var carreira_antes: Dictionary = gs.para_save()
	var hood: float = gs.capuz.hood_s
	gs.ronda_ir("alley", "tire")
	_aproximar(gs, "scare")
	var salvos := [0]
	gs.salvo.connect(func(_t): salvos[0] += 1)
	gs.atributos = GRANDE.duplicate()
	gs._rng_ronda.seed = 99
	var rr := RandomNumberGenerator.new()
	rr.seed = 99
	var semente_esperada := int(rr.randi())
	var info: Dictionary = gs.briga_lutar(_tatica(gs))
	checar(not info.is_empty() and int(info.seed) == semente_esperada, "a semente da luta sai do _rng_ronda")
	checar_igual(salvos[0], 1, "uma gravacao so no LUTAR")
	checar(info.art.opponent == "opp_alley_tire" and info.art.vulto == "vulto_fight" and info.art.arena == "arena_alley", "info.art: mapa da arte da noite (manifest alley_fight)")
	checar(info.arena == "arena_alley" and info.night == "alley" and info.fighter_name == "???" and info.events.size() > 0, "info: arena do beco, nome ???, eventos para a tela")
	checar(gs.luta.is_empty() and gs.luta_atual().is_empty(), "GameState.luta intocada (a carreira nem sabe da noite)")
	var pr: Dictionary = info.night_prize
	checar(pr.win and pr.scare and pr.legend_gain == 4 and pr.dossier_new and pr.clipping_new and pr.legend == _LV(2) + 4, "vitoria com SUSTO: lenda +4 (floor 1 + SUSTO 1 + vitoria 2)")
	checar(pr.challenge_done and pr.style_unlocked == "night_band" and str(pr.style_text).contains("{") == false, "desafio da surpresa: estilo faixa da noite")
	var f: Dictionary = _ficha(gs, "tire")
	checar(int(f.won) == 1 and int(f.lost) == 0 and int(f.first_win_campaign) == 4 and bool(f.challenge), "ficha gravada: venceu, campanha 4, desafio feito")
	checar(int(_bc(gs).rounds) == 7 and int(_bc(gs).scares) == 4 and int(_bc(gs).legend) == _LV(2) + 4, "rounds +1, scares +1, lenda +4")
	checar(gs.capuz.open == "" and absf(float(gs.capuz.next_at) - (hood + _IV())) < 1.0e-6, "prego vazio, proximo capuz em +intervalo")
	for k in estados:
		checar(gs.get(k).state == estados[k], "a noite nao mexe em %s" % k)
	checar(gs.briga_resultado() == pr and gs.ronda_concluir() == pr, "briga_resultado e ronda_concluir devolvem o mesmo premio")
	# a carreira nao mexeu em nada alem de black_cat e do capuz
	var depois: Dictionary = gs.para_save()
	for s in [carreira_antes, depois]:
		s.permanent.erase("black_cat")
		s.career.erase("black_cat_hood")
	var ign := ["campaign_seconds", "play_seconds", "attributes", "training", "money_earned", "money", "fight_day"]
	for k in ign:
		carreira_antes.career.erase(k)
		depois.career.erase(k)
	checar_igual(JSON.stringify(depois, "", true), JSON.stringify(carreira_antes, "", true), "carreira igual (fama, Legado, escada, dias): so black_cat e o capuz mudaram")
	# lenda da noite nunca passa de 4 e a premiacao vale uma vez
	var l0: int = int(gs.lenda().legend)
	gs.ronda_voltar()
	checar(gs.ronda_ativa == "" and gs.sala_ativa() and int(gs.lenda().legend) == l0, "VOLTAR devolve a sala sem somar de novo")
	# trava de 120 s na tela de premio
	var g2 := _novo("r2a_trava")
	_andar(g2, 181)
	g2.ronda_ir("alley", "tire")
	_aproximar(g2, "seen")
	g2.briga_lutar(_tatica(g2))
	g2.tick(60.0)
	checar(g2.ronda_ativa == "alley", "60 s no premio: ainda la")
	g2.tick(70.0)
	checar(g2.ronda_ativa == "", "depois de 120 s a sala volta sozinha")
	_liberar(gs)
	_liberar(g2)


# ---------------------------------------------------------------- derrota pequena (A4)
func _teste_derrota_pequena() -> void:
	var gs := _novo("r2a_derrota")
	var info0: Dictionary = _briga(gs, "tire", "scare", GRANDE)  # vence o 1o e deixa uma ficha no Dossie
	checar(info0.night_prize.win, "preparo: venceu o 1o")
	var dossie_antes: Dictionary = _ficha(gs, "tire").duplicate()
	var estado_antes: Dictionary = gs.para_save()
	var l0: Dictionary = gs.lenda()
	var hood0: float = gs.capuz.hood_s
	var info: Dictionary = _briga(gs, "bike", "seen", PEQUENO)
	checar(not info.is_empty() and not info.night_prize.win, "atributos 1: perdeu a briga")
	var pr: Dictionary = info.night_prize
	checar(pr.legend_gain == 1 and not pr.scare and not pr.dossier_new and pr.style_unlocked == "" and not pr.challenge_done, "derrota sem SUSTO: lenda +1, sem ficha, sem recorte, sem estilo")
	checar(pr.revenge and str(pr.title) != "" and str(pr.line) == gs.texto_ui("alley_lose_line"), "REVANCHE e a linha SAIU MANCANDO")
	checar_igual(_ficha(gs, "tire"), dossie_antes, "nada do Dossie some")
	checar(int(_ficha(gs, "bike").lost) == 1 and int(_ficha(gs, "bike").won) == 0, "ficha do bandido: 1 derrota")
	checar_igual(int(gs.lenda().legend), int(l0.legend) + 1, "a lenda so soma")
	checar_igual(JSON.stringify(_sem_tempo(gs.para_save()), "", true), JSON.stringify(_sem_tempo(estado_antes), "", true), "Legado, FAMA, escada, dias, AQUECIDO e carreira iguais depois de perder")
	checar(gs.sala_ativa() and gs.fim.is_empty(), "perder nao encerra a carreira")
	checar(gs.quadro_noite()[1].bandit == "bike" and gs.quadro_noite()[1].revenge, "REVANCHE no quadro")
	var hood1: float = gs.capuz.hood_s
	checar(absf(float(gs.capuz.next_at) - (hood1 + _IV())) < 1.0e-6 and gs.capuz.open == "", "o capuz volta no proximo relogio (intervalo de sala)")
	_andar(gs, int(_IV()) - 1)
	checar(not gs.capuz_info().get("clickable", false), "1 s antes do intervalo: ainda sem capuz")
	_andar(gs, 2)
	checar(gs.capuz_info().get("clickable", false), "intervalo de sala: o capuz volta")
	checar(hood1 >= hood0, "relogio so andou para frente")
	# derrota com SUSTO: lenda +2
	var info2: Dictionary = _briga(gs, "bike", "scare", PEQUENO)
	checar(info2.night_prize.legend_gain == 2 and int(_ficha(gs, "bike").lost) == 2, "derrota com SUSTO: lenda +2; 2 derrotas na ficha")
	_liberar(gs)


# ---------------------------------------------------------------- desafios e estilos (A10)
func _teste_desafios_e_estilos() -> void:
	var gs := _novo("r2a_estilos")
	var d: DiscipulosData = gs.disciples
	for campo in ["headband_color", "socks", "shorts_color"]:
		var antes := d.opcoes_ativas(campo).duplicate()
		checar(not ("night" in antes) and not ("night_wraps" in antes), "%s: estilo travado nao aparece" % campo)
	checar(not gs.estilo_liberado("night_band"), "estilo nao liberado no comeco")
	# o look sujo volta ao padrao
	var look: Dictionary = d.look_padrao.duplicate()
	look["headband_color"] = "night"
	var avisos := []
	checar_igual(d.validar_look(look, avisos).headband_color, d.look_padrao.headband_color, "look com estilo travado: volta ao padrao do campo")
	checar(not avisos.is_empty(), "... com aviso")
	# 1: surpresa
	var i1: Dictionary = _briga(gs, "tire", "scare", GRANDE)
	checar(i1.night_prize.challenge_done and gs.estilo_liberado("night_band") and not gs.estilo_liberado("night_wraps"), "tire com SUSTO e vitoria: faixa da noite")
	checar_igual(d.opcoes_ativas("headband_color")[-1], "night", "faixa da noite no FIM da lista de opcoes")
	var linhas: Array = gs.linhas_tela_criacao() if gs.sucessao != "none" else d.linhas_tela({})
	var achou := false
	for l in linhas:
		if l.field == "headband_color":
			achou = "night" in l.opcoes and str(l.marcas.get("night", "")) == "cat"
	checar(achou, "a tela de personalizacao traz o estilo com a marca do gato")
	look["headband_color"] = "night"
	checar_igual(d.validar_look(look).headband_color, "night", "liberado: o look com o estilo vale")
	# 2: bike vencido sem o desafio (visto, atributos medianos nao garantem K.O. ate o 2o round: forco a condicao pelo resultado)
	var i2: Dictionary = _briga(gs, "bike", "seen", GRANDE)
	checar(i2.night_prize.win, "bike vencido")
	var esperado: bool = bool(i2.result.ko) and int(i2.result.round) <= 2
	checar_igual(bool(i2.night_prize.challenge_done), esperado, "desafio do bike = vencer por K.O. ate o 2o round (%s)" % str(esperado))
	# 3: gate: 60% da vida
	var i3: Dictionary = _briga(gs, "gate", "seen", GRANDE)
	var esp3: bool = bool(i3.night_prize.win) and float(i3.result.pct_player) >= 0.6
	checar_igual(bool(i3.night_prize.challenge_done), esp3, "desafio do gate = vencer com 60%% da vida (pct %.2f)" % float(i3.result.pct_player))
	# forca o estado: tudo feito => os 3 estilos; o rascunho nao muda (sorteio nunca usa estilo)
	gs.permanente.black_cat["alley"] = {"tire": {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true}, "bike": {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true},
		"gate": {"won": 1, "lost": 0, "first_win_campaign": 4, "challenge": true}}
	checar(gs.estilo_liberado("night_band") and gs.estilo_liberado("night_wraps") and gs.estilo_liberado("night_shorts"), "3 estilos liberados")
	var sem: DiscipulosData = DiscipulosData.carregar()
	var com: DiscipulosData = DiscipulosData.carregar()
	com.liberado = func(_r: String) -> bool: return true
	var iguais := true
	var nunca := true
	for semente in range(1, 60):
		var r1 := RandomNumberGenerator.new()
		var r2 := RandomNumberGenerator.new()
		r1.seed = semente
		r2.seed = semente
		var a: Dictionary = sem.sortear(r1, [])
		var b: Dictionary = com.sortear(r2, [])
		iguais = iguais and JSON.stringify(a) == JSON.stringify(b)
		for campo in b.look:
			nunca = nunca and not com.tem_requisito(campo, str(b.look[campo]))
	checar(iguais and nunca, "o sorteio do rascunho e igual com ou sem estilos liberados, e nunca sorteia estilo")
	var t := DiscipulosData.carregar()
	t.ligar_todas_as_opcoes()
	checar(not ("night" in t.opcoes_ativas("shorts_color")) and not ("night_wraps" in t.opcoes_ativas("socks")), "ligar_todas_as_opcoes pula as opcoes com requires")
	var cores: Dictionary = d.cores({"headband_color": "night", "shorts_color": "night", "socks": "night_wraps", "skin": d.look_padrao.skin, "hair_color": d.look_padrao.hair_color,
		"hair_style": d.look_padrao.hair_style, "top": "none", "top_color": d.look_padrao.top_color, "headband": "band"})
	checar(cores.socks.colors.size() == 3 and cores.headband_color.colors.size() == 2 and cores.shorts_color.colors.size() == 4, "cores(): meiao com cores proprias (night_wraps), faixa e calcao da noite")
	var on: Dictionary = d.cores({"shorts_color": "night", "socks": "on"})
	checar_igual(on.socks.colors, [on.shorts_color.colors[0], on.shorts_color.colors[1], on.shorts_color.colors[3]], "meiao 'on' sobre o calcao da noite copia as cores dele")
	_liberar(gs)


# ---------------------------------------------------------------- fechar o jogo (A11)
func _teste_fechar_o_jogo() -> void:
	var gs := _novo("r2a_fechar")
	_andar(gs, 181)
	gs.salvar()
	var pasta: String = gs.store.pasta
	var base: String = JSON.stringify(gs.para_save(), "", true)
	# aproximacao e previa: reabrir = nada aconteceu
	gs.ronda_ir("alley", "tire")
	_andar(gs, 3, 0.1)
	gs.salvar()  # o autosave pode gravar no meio
	var g2: Node = GameStateScript.new()
	g2.inicializar(pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar(g2.ronda_ativa == "" and g2.capuz.open == "scare" and not _bc(g2).has("alley") and int(_bc(g2).rounds) == 6, "fechou na aproximacao: nada mudou, capuz no prego")
	_aproximar(gs, "scare")
	gs.salvar()
	var g3: Node = GameStateScript.new()
	g3.inicializar(pasta, "res://data/config.json")
	g3.autosave_ativo = false
	checar(g3.capuz.open == "scare" and not _bc(g3).has("alley"), "fechou na previa: nada mudou")
	# depois do LUTAR: gravado, uma vez so
	gs.atributos = GRANDE.duplicate()
	var info: Dictionary = gs.briga_lutar(_tatica(gs))
	checar(not info.is_empty(), "LUTAR")
	var g4: Node = GameStateScript.new()
	g4.inicializar(pasta, "res://data/config.json")
	g4.autosave_ativo = false
	checar(g4.ronda_ativa == "" and g4.capuz.open == "" and int(_ficha(g4, "tire").won) == 1 and int(_bc(g4).rounds) == 7, "fechou na luta: a ficha, a lenda e o capuz ja estao gravados")
	checar(bool(_ficha(g4, "tire").challenge) and g4.estilo_liberado("night_band"), "o estilo tambem")
	_andar(g4, 1)
	checar(g4.quadro_noite()[1].bandit == "bike", "reabrir: o proximo bandido no quadro (nada em dobro)")
	checar(g4.briga_resultado().is_empty() and g4.briga_estado().fase == "", "nao ha premio pendente nem rolar de novo")
	g4.salvar()
	var g5: Node = GameStateScript.new()
	g5.inicializar(pasta, "res://data/config.json")
	g5.autosave_ativo = false
	checar_igual(int(_ficha(g5, "tire").won), 1, "salvar/abrir de novo nao duplica")
	for g in [gs, g2, g3, g4, g5]:
		_liberar(g)
	base = base  # (o save "base" so serve de referencia legivel)


# ---------------------------------------------------------------- save sujo (A11)
func _teste_save_sujo() -> void:
	var gs := _novo("r2a_sujo")
	var base: Dictionary = gs.para_save()
	var s1: Dictionary = base.duplicate(true)
	s1.permanent.black_cat["alley"] = {"tire": {"won": -4, "lost": "dois", "first_win_campaign": 99, "challenge": true},
		"bike": {"won": 1.0e30, "lost": 3, "first_win_campaign": 99, "challenge": "sim"}, "fantasma": {"won": 1, "lost": 0}, "gate": 7}
	gs.aplicar_save(s1)
	var a: Dictionary = _bc(gs).get("alley", {})
	checar(not a.has("tire") and not a.has("fantasma") and not a.has("gate"), "numero ruim sem partida (tire), id desconhecido e formato ruim sao ignorados")
	checar(int(a.get("bike", {}).get("won", 0)) == 1000000000 and int(a.bike.lost) == 3 and int(a.bike.first_win_campaign) == 4 and not bool(a.bike.challenge), "gigante = teto; campanha > atual = atual; desafio nao-booleano = false")
	checar(gs.avisos.any(func(x): return str(x).contains("fantasma")), "bandido desconhecido: aviso")
	var s2: Dictionary = base.duplicate(true)
	s2.permanent.black_cat["alley"] = {"tire": {"won": 0, "lost": 2, "first_win_campaign": 3, "challenge": true}}
	gs.aplicar_save(s2)
	checar(not bool(_ficha(gs, "tire").challenge) and int(_ficha(gs, "tire").first_win_campaign) == 0 and int(_ficha(gs, "tire").lost) == 2, "desafio sem vitoria = false (com aviso)")
	var s3: Dictionary = base.duplicate(true)
	s3.permanent.black_cat["alley"] = {"gate": {"won": 1, "lost": 0, "first_win_campaign": 2, "challenge": false}}
	gs.aplicar_save(s3)
	checar(int(_ficha(gs, "gate").won) == 1 and gs.avisos.any(func(x): return str(x).contains("sem vencer o anterior")), "2o/3o vencido fora de ordem: mantem, com aviso")
	# look salvo com estilo nao liberado volta ao padrao
	var s4: Dictionary = base.duplicate(true)
	s4.career["disciple"] = {"name": "Zuzu", "look": gs.disciples.look_padrao.duplicate(), "campaign": 4}
	s4.career.disciple.look["shorts_color"] = "night"
	gs.aplicar_save(s4)
	checar(str(gs.discipulo.look.shorts_color) == str(gs.disciples.look_padrao.shorts_color), "discipulo com calcao da noite sem o estilo: volta ao padrao")
	# o prego so guarda a noite do SUSTO: "alley" no prego (editado a mao) vira vazio
	var s6: Dictionary = base.duplicate(true)
	s6.career["black_cat_hood"] = {"hood_s": 10.0, "next_at": 5.0, "open": "alley"}
	gs.aplicar_save(s6)
	checar_igual(gs.capuz.open, "", "capuz com open='alley' salvo: vira vazio")
	# save de antes (sem o campo): abre igual
	var s0: Dictionary = base.duplicate(true)
	s0.permanent.black_cat.erase("alley")
	gs.aplicar_save(s0)
	checar(not _bc(gs).has("alley") and gs.esconderijo().dossier.all(func(f): return not f.known), "save sem o campo alley: tudo fechado")
	# ida e volta no disco com tudo
	var s5: Dictionary = base.duplicate(true)
	s5.permanent.black_cat["alley"] = {"tire": {"won": 2, "lost": 1, "first_win_campaign": 3, "challenge": true}}
	gs.aplicar_save(s5)
	checar_igual(gs.para_save().permanent.black_cat.alley, {"tire": {"won": 2, "lost": 1, "first_win_campaign": 3, "challenge": true}}, "campo valido volta igual")
	_liberar(gs)


# ---------------------------------------------------------------- D2: SOLTE E CLIQUE! (A14)
func _teste_d2_dica() -> void:
	var gs := _novo("r2a_d2")
	var cfg: Dictionary = gs.ronda_cfg.noites.scare
	var ciclos: Array = []
	for _o in cfg.occurrences:
		var lst: Array = []
		for _c in 40:
			lst.append([9.0, false])  # ladrao longe de olhar: so testa a dica
		ciclos.append(lst)
	var j := RondaLogica.new(cfg, null, ciclos)
	var dt := 1.0 / 60.0
	while j.estado().fase == "contagem":
		j.passo(dt, false, false)
	var hint := float(j.estado().hold_hint_s)
	checar_igual(hint, 0.6, "hold_hint_s = 0,6 no estado")
	var chegou := false
	var t := 0.0
	while t < 12.0 and not bool(j.estado().perto):
		j.passo(dt, true, false)
		t += dt
		checar(not bool(j.estado().dica_soltar) or bool(j.estado().perto), "a dica nunca aparece longe do fim do muro")
		chegou = true
	checar(chegou and bool(j.estado().perto) and not bool(j.estado().dica_soltar), "chegou perto: ainda sem dica")
	for _i in 30:  # 0,5 s
		j.passo(dt, true, false)
	checar(not bool(j.estado().dica_soltar) and float(j.estado().segurando_perto_s) < hint, "0,5 s segurando perto: sem dica")
	for _i in 8:  # 0,63 s
		j.passo(dt, true, false)
	checar(bool(j.estado().dica_soltar), "0,6 s segurando perto: SOLTE E CLIQUE!")
	j.passo(dt, false, false)
	checar(not bool(j.estado().dica_soltar) and float(j.estado().segurando_perto_s) == 0.0, "soltar apaga a dica")
	j.passo(dt, true, false)
	checar(not bool(j.estado().dica_soltar), "apertar de novo recomeca a conta")
	# nada muda no resultado: os mesmos roteiros com e sem leitura da dica
	var a := RondaLogica.new(cfg, null, ciclos.duplicate(true))
	var b := RondaLogica.new(cfg, null, ciclos.duplicate(true))
	for i in 3000:
		var seg: bool = (i / 90) % 2 == 0
		a.passo(dt, seg, false)
		b.estado()
		b.passo(dt, seg, false)
	checar(a.t == b.t and a.sustos == b.sustos and a.vistos == b.vistos and a.historico == b.historico, "ler a dica nao muda a regra nem o resultado")
	# vale na aproximacao da briga (usa os mesmos tempos) e o estado traz o campo
	var jb := RondaLogica.new(gs.ronda_cfg.cfg_aproximacao("tire"), null)
	checar(jb.estado().has("dica_soltar") and float(jb.estado().hold_hint_s) == 0.6, "aproximacao da briga: a mesma dica (0,6 s)")
	_liberar(gs)


# ---------------------------------------------------------------- sem rosto, sem sangue, sem nome (A8, A9)
func _teste_sem_rosto_nem_sangue() -> void:
	var gs := _novo("r2a_rosto")
	gs.discipulo = {"name": "Zuzu", "look": gs.disciples.look_padrao.duplicate(), "campaign": 4}
	var vistos: PackedStringArray = []
	vistos.append(JSON.stringify(gs.esconderijo()))
	var info: Dictionary = _briga(gs, "tire", "scare", GRANDE)
	vistos.append(JSON.stringify(info.night_prize))
	vistos.append(JSON.stringify(gs.esconderijo()))
	_capuz(gs)
	gs.ronda_ir("alley", "bike")
	_aproximar(gs, "seen")
	vistos.append(JSON.stringify(gs.briga_previa()))
	var tudo := "\n".join(vistos)
	checar(not tudo.contains("Zuzu"), "nenhum dado da noite traz o nome do discipulo")
	checar(info.fighter_name == "???" and gs.briga_previa().opponent.name == "???", "o lutador do lado esquerdo e ???")
	gs.ronda_voltar()
	# textos e dados: sem sangue e sem referencias a outro universo
	var cru := ler("res://data/ronda.json").to_lower()
	var ui: Dictionary = JSON.parse_string(ler("res://data/ui_texts.json"))
	var texto := cru
	for k in ui:
		if str(k).begins_with("alley_") or str(k).begins_with("hideout_") or str(k).begins_with("dossier_") or str(k).begins_with("night_alley") or str(k) == "challenge_chance_line" \
				or str(k) == "hint_release_click" or str(k) == "fighter_name_hidden":
			texto += "\n" + str(ui[k]).to_lower()
	for proibido in ["sangue", "blood", "batman", "morcego", "gotham"]:
		checar(not texto.contains(proibido), "busca por '%s' nos dados e textos da 2a1 = 0" % proibido)
	_liberar(gs)


# ---------------------------------------------------------------- quem briga = quem so faz SUSTO (A2)
func _corrida(nome: String, briga: bool) -> Dictionary:
	var gs := _novo(nome)
	gs.geradores[gs.dados.geradores[0].id] = 3
	var vez := 0
	for _i in 1500:
		gs.tick(1.0)
		if not gs.capuz_info().get("clickable", false):
			continue
		var alvo := ""
		if briga:
			alvo = gs._beco.proximo()
			if alvo == "":
				for b in gs.ronda_cfg.noites.alley.bandits:
					if gs._beco.so_desafio(str(b.id)):
						alvo = str(b.id)
						break
		if alvo != "":
			vez += 1
			gs.ronda_ir("alley", alvo)
			_aproximar(gs, "scare" if vez % 2 == 0 else "time")
			var guardados: Dictionary = gs.atributos.duplicate()
			gs.atributos = (PEQUENO if vez % 3 == 1 else GRANDE).duplicate()
			gs.briga_lutar(_tatica(gs))
			gs.atributos = guardados
			gs.ronda_voltar()
		else:
			gs.ronda_ir()
			gs.ronda_jogo().sustos = 1
			gs.ronda_concluir()
			gs.ronda_voltar()
	var e: Dictionary = gs.para_save()
	e.career.erase("black_cat_hood")
	e.permanent.erase("black_cat")
	var r := {"save": JSON.stringify(e, "", true), "rounds": int(gs.lenda().rounds), "alley": _bc(gs).get("alley", {}).duplicate(true)}
	for k in ["rng", "_rng_evento", "_rng_fala", "_rng_sucessao", "_rng_treino"]:
		r[k] = gs.get(k).state
	_liberar(gs)
	return r


func _teste_quem_briga_igual() -> void:
	var a := _corrida("r2a_igual_a", false)
	var b := _corrida("r2a_igual_b", true)
	checar(not b.alley.is_empty() and int(b.rounds) > 6, "B foi em brigas (%d fichas) e A so em SUSTOs" % b.alley.size())
	checar(a.alley.is_empty(), "A nao brigou")
	checar(a.save == b.save, "mesma campanha so com SUSTO ou indo em todas as brigas (ganhando e perdendo): save igual campo a campo (sem black_cat e capuz)")
	for k in ["rng", "_rng_evento", "_rng_fala", "_rng_sucessao", "_rng_treino"]:
		checar(a[k] == b[k], "sorteio %s igual" % k)
	var d := DiscipulosData.carregar()
	d.liberado = func(_r: String) -> bool: return true
	var d0 := DiscipulosData.carregar()
	var r1 := RandomNumberGenerator.new()
	var r2 := RandomNumberGenerator.new()
	r1.seed = 77
	r2.seed = 77
	checar_igual(JSON.stringify(d.sortear(r1, [])), JSON.stringify(d0.sortear(r2, [])), "sucessao seguinte com os 3 estilos liberados: o rascunho e o mesmo")
