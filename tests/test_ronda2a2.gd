extends "res://tests/test_base.gd"
## Ronda 2a2 (o chefe Apagão): destrave, quadro e Esconderijo, desafio surprise_early, prévia honesta, apagão só visual, prêmios,
## save (campo boss, saves sujos, gravação única), capuz a 300 s e limiares da lenda lidos do ronda.json.
## Cobre B2, B4-B8, B11, B12, B15 e B16 do design (docs/fases/ronda2a2-design.md §9). B1 é a foto (tools/refatoracao/foto.gd).
## Tudo em user://test/, nunca o save real. Nada de 240 nem de limiares escritos aqui: tudo vem do ronda.json.

const GameStateScript := preload("res://scripts/game_state.gd")
const GRANDE := {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
const PEQUENO := {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
const CHEFE := "apagao"


func rodar_testes() -> void:
	_teste_dados()
	_teste_destrave()
	_teste_quadro_e_esconderijo()
	_teste_desafio_surprise_early()
	_teste_previa()
	_teste_apagao_so_visual()
	_teste_derrota_e_vitoria()
	_teste_desafio_raro_e_estilo()
	_teste_menu_cartaz()
	_teste_save()
	_teste_capuz_300()
	_teste_limiares()
	_teste_chefe_igual()


func _LV(i: int) -> int:
	return int(RondaData.carregar().niveis[i])


func _IV() -> float:
	return float(RondaData.carregar().capuz.interval_s)


## Linhagem pronta para o chefe: lenda no nível 5, os 3 bandidos vencidos, cinturão do Vale (ajustável por argumento).
func _novo(nome: String, lenda: int = -1, bandidos: int = 3, cinturoes: int = 1) -> Node:
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
	gs.permanente["career_number"] = 9
	gs.permanente["regional_belts"] = cinturoes
	gs.escola.milestones["black_cat_rumor_heard"] = {"campaign": 8, "version": 1}
	gs.escola.milestones["regional_league_opened"] = {"campaign": 8, "version": 1}
	if lenda < 0:
		lenda = _LV(4)
	var alley := {}
	var ids: Array = ["tire", "bike", "gate"]
	for i in bandidos:
		alley[ids[i]] = {"won": 1, "lost": 0, "first_win_campaign": 5 + i, "challenge": true}
	var bc := {"legend": lenda, "rounds": 12, "scares": 6, "shown_level": gs.ronda_cfg.nivel_de(lenda), "open_campaign": 3}
	if not alley.is_empty():
		bc["alley"] = alley
	gs.permanente["black_cat"] = bc
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


func _andar(gs: Node, s: int, passo: float = 1.0) -> void:
	for _i in s:
		gs.tick(passo)


func _capuz(gs: Node) -> bool:
	for _i in 420:
		if gs.capuz_info().get("clickable", false):
			return true
		gs.tick(1.0)
	return false


func _aproximar(gs: Node, como: String) -> void:
	var j: RondaLogica = gs.ronda_jogo()
	j.sustos = 1 if como == "scare" else 0
	j.vistos = 1 if como == "seen" else 0
	j.fase = "fim"
	gs.tick(0.01)


func _tatica(gs: Node) -> String:
	return str(gs.lutas.taticas[0].id)


func _bc(gs: Node) -> Dictionary:
	return gs.permanente.get("black_cat", {})


func _ficha(gs: Node) -> Dictionary:
	return _bc(gs).get("boss", {}).get(CHEFE, {})


## Uma noite do chefe inteira com os atributos dados (restaura os da carreira). Devolve a luta ({} se não pôde ir).
func _noite_chefe(gs: Node, como: String, atributos: Dictionary) -> Dictionary:
	if not _capuz(gs):
		return {}
	if gs.ronda_ir("alley", CHEFE).is_empty():
		return {}
	_aproximar(gs, como)
	var guardados: Dictionary = gs.atributos.duplicate()
	gs.atributos = atributos.duplicate()
	var info: Dictionary = gs.briga_lutar(_tatica(gs))
	gs.atributos = guardados
	gs.ronda_voltar()
	return info


func _sem_tempo(s: Dictionary) -> Dictionary:
	s.permanent.erase("black_cat")
	for k in ["black_cat_hood", "play_seconds", "campaign_seconds", "training_invite"]:
		s.career.erase(k)
	return s


# ---------------------------------------------------------------- dados
func _teste_dados() -> void:
	var gs := _novo("r2a2_dados")
	var cfg: RondaData = gs.ronda_cfg
	checar(cfg.avisos.is_empty(), "ronda.json sem avisos do validador (%s)" % str(cfg.avisos))
	var c: Dictionary = cfg.noites.alley.boss
	checar(not c.is_empty() and c.id == CHEFE and c.disponivel, "chefe lido e disponivel")
	checar_igual(c.requires, {"legend_level": 5, "all_bandits": true, "regional_belts_min": 1}, "requires do chefe")
	checar(float(c.strength) > 0.0 and float(c.agility) > 0.0 and float(c.endurance) > 0.0, "atributos positivos")
	checar_igual(str(c.passive.id), "adv_slippery", "passiva adv_slippery da liga")
	checar_igual(str(c.challenge.type), "surprise_early", "desafio surprise_early")
	checar_igual(int(c.challenge.max_round), 2, "desafio ate o round 2")
	checar(c.blackout.after_round >= 1 and c.blackout.dark_s > 0.0 and c.blackout.visual_only, "apagao so visual")
	checar(c.trophy.slot >= 0 and c.trophy.slot <= 3, "trofeu num dos 4 lugares")
	checar_igual(str(c.style.id), "live_wire", "estilo raro live_wire lido (a opcao existe e o requires bate)")
	checar(not gs.disciples.opcao_liberada("shorts_color", "live_wire") and gs.disciples.tem_requisito("shorts_color", "live_wire"), "live_wire exige o estilo")
	# validador: chefe ruim some com aviso; tipo de desafio desconhecido = sem desafio e sem estilo
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/ronda.json"))
	var ruim: Dictionary = base.duplicate(true)
	ruim.nights.alley.boss.strength = 0
	var r1 := RondaData.new()
	r1._ler(ruim)
	checar(r1.noites.alley.boss.is_empty() and not r1.avisos.is_empty(), "atributo 0: chefe ignorado, com aviso")
	var r2 := RondaData.new()
	var sem: Dictionary = base.duplicate(true)
	sem.nights.alley.erase("boss")
	r2._ler(sem)
	checar(r2.noites.alley.boss.is_empty() and r2.noites.alley.bandits.size() == 3, "sem o bloco boss: so a 2a1")
	var r3 := RondaData.new()
	var tipo: Dictionary = base.duplicate(true)
	tipo.nights.alley.boss.challenge.type = "inventado"
	r3._ler(tipo)
	checar(r3.noites.alley.boss.challenge.is_empty() and r3.noites.alley.boss.style.is_empty(), "tipo de desafio desconhecido: sem desafio e sem estilo")
	var r4 := RondaData.new()
	var chave: Dictionary = base.duplicate(true)
	chave.nights.alley.boss.requires["lua"] = 3
	r4._ler(chave)
	checar(not r4.noites.alley.boss.disponivel, "chave desconhecida no requires: chefe indisponivel")
	var r5 := RondaData.new()
	var slot: Dictionary = base.duplicate(true)
	slot.nights.alley.boss.trophy.slot = 9
	r5._ler(slot)
	checar_igual(int(r5.noites.alley.boss.trophy.slot), 3, "slot do troféu fica entre 0 e 3")
	_liberar(gs)


# ---------------------------------------------------------------- destrave (B5)
func _teste_destrave() -> void:
	var a := _novo("r2a2_dest_a", _LV(4) - 1)
	var b := _novo("r2a2_dest_b", _LV(4), 2)
	var c := _novo("r2a2_dest_c", _LV(4), 3, 0)
	var d := _novo("r2a2_dest_d")
	for g in [a, b, c, d]:
		_andar(g, 181)
	checar(not a.chefe_aberto() and a.chefe_falta() == "legend", "(a) lenda do nivel 4 com tudo o mais: trancado pela lenda")
	checar(str(a.quadro_noite()[1].missing_text).contains("5"), "(a) o cartao diz o nivel da lenda")
	checar(not b.chefe_aberto() and b.chefe_falta() == "bandits" and str(b.esconderijo().boss.missing_text) == b.texto_ui("dossier_missing_bandits"), "(b) 2 bandidos: VENCA OS 3 DO BECO")
	checar(b.quadro_noite()[1].night == "alley" and b.quadro_noite()[1].bandit == "gate", "(b) o quadro ainda mostra o proximo bandido")
	checar(not c.chefe_aberto() and c.chefe_falta() == "belt" and str(c.quadro_noite()[1].missing_text) == c.texto_ui("dossier_missing_belt"), "(c) sem cinturao do Vale: PRECISA DO CINTURAO")
	for g in [a, b, c]:
		checar(g.ronda_ir("alley", CHEFE).is_empty() and g.ronda_ativa == "", "trancado: ronda_ir(alley, apagao) devolve {}")
	checar(d.chefe_aberto() and d.chefe_falta() == "" and d.chefe_falta_texto() == "", "(d) tudo junto: aberto")
	var q: Array = d.quadro_noite()
	checar(q.size() == 2 and q[1].night == "boss" and q[1].boss == CHEFE and not q[1].locked, "(d) cartao do chefe aberto no quadro")
	var i: Dictionary = d.ronda_ir("alley", CHEFE)
	checar(not i.is_empty() and i.boss and i.arena == "arena_apagao" and float(i.entrance_s) > 0.0 and str(i.entrance_banner) != "" and d.ronda_ativa == "alley", "(d) ronda_ir devolve boss, arena, letreiro e apagao")
	checar(i.blackout.after_round == 2 and i.blackout.dark_s > 0.0, "ronda_ir: dados do apagao")
	checar(i.occurrences == [CHEFE] and str(i.occurrence_names[0]) == d.texto_ui("alley_occ_apagao_anon"), "antes de vencer a aproximacao mostra o nome anonimo")
	checar(d.briga_estado().boss and d.briga_estado().fase == "aproximacao", "briga_estado marca o chefe")
	# o chefe nao depende do discipulo atual (so da linhagem)
	d.ronda_voltar()
	# cinturao so por permanent.regional_belts; os 3 bandidos so por `won` (o desafio deles nao conta)
	d.permanente.black_cat.alley.tire.challenge = false
	checar(d.chefe_aberto(), "o desafio dos bandidos nao conta para o destrave")
	for g in [a, b, c, d]:
		_liberar(g)


# ---------------------------------------------------------------- quadro e Esconderijo (§2.1, §8.3)
func _teste_quadro_e_esconderijo() -> void:
	var gs := _novo("r2a2_quadro")
	var e: Dictionary = gs.esconderijo()
	checar(e.boss.id == CHEFE and not e.boss.known and e.boss.name == "???" and e.boss.rap_sheet == "" and e.boss.open and e.boss.missing_text == "", "ficha do chefe aberto: silhueta e ??? ate vencer")
	checar(e.boss.passive.id == "adv_slippery" and e.boss.profile == "RÁPIDO" and str(e.boss.challenge_text) != "", "perfil, passiva e desafio do chefe")
	checar(e.trophies.size() == 4 and e.trophies.all(func(t): return t.state == "empty"), "prateleira: 4 lugares vazios antes de vencer")
	var c: Dictionary = gs.quadro_noite()[1]
	checar(c.night == "boss" and not c.locked and not c.challenge_only and not c.revenge and c.profile == "RÁPIDO" and c.name == "???", "cartao aberto: perfil, sem revanche, nome oculto")
	# perdeu: REVANCHE
	gs.permanente.black_cat["boss"] = {CHEFE: {"won": 0, "lost": 1, "first_win_campaign": 0, "challenge": false}}
	checar(gs.quadro_noite()[1].revenge and gs.esconderijo().boss.revenge and not gs.esconderijo().boss.known, "perdeu: REVANCHE no cartao e na ficha")
	# venceu sem desafio: volta o "quieto" e entra o DESAFIO no fim
	gs.permanente.black_cat["boss"] = {CHEFE: {"won": 1, "lost": 1, "first_win_campaign": 9, "challenge": false}}
	var q: Array = gs.quadro_noite()
	checar(q.size() == 3 and q[1].night == "quiet" and q[2].night == "boss" and q[2].challenge_only and q[2].name != "???", "vencido sem desafio: BECO QUIETO + cartao DESAFIO do chefe")
	var eb: Dictionary = gs.esconderijo().boss
	checar(eb.known and eb.name != "???" and str(eb.rap_sheet) != "" and str(eb.headline) != "" and str(eb.witness) != "" and str(eb.press_title) != "" and str(eb.stamp).contains("9"), "ficha aberta: textos, titulo e carimbo da campanha")
	var t0: Dictionary = gs.esconderijo().trophies[0]
	checar(t0.state == "normal" and t0.sprite == "trophy_apagao" and t0.slot == 0 and str(t0.name) != "", "prateleira: capacete normal no lugar 1")
	# venceu com desafio: o raro troca no mesmo lugar e nao sobra cartao
	gs.permanente.black_cat["boss"][CHEFE]["challenge"] = true
	q = gs.quadro_noite()
	checar(q.size() == 2 and q[1].night == "quiet", "vencido com desafio: so o BECO QUIETO")
	var t1: Dictionary = gs.esconderijo().trophies[0]
	checar(t1.state == "rare" and t1.sprite == "trophy_apagao_rare" and t1.slot == t0.slot and gs.esconderijo().trophies.size() == 4, "raro troca o normal no mesmo lugar (ainda 4 lugares)")
	checar(gs.esconderijo().trophies.filter(func(t): return t.state != "empty").size() == 1, "1 capacete por chefe")
	# o Dossie dos bandidos continua com 3 fichas
	checar(gs.dossie().size() == 3, "Dossie: so os 3 bandidos")
	# 2a1 sem o bloco do chefe: silhueta LENDA 5 de sempre
	_liberar(gs)


# ---------------------------------------------------------------- o desafio surprise_early (§3.3)
func _teste_desafio_surprise_early() -> void:
	var gs := _novo("r2a2_desafio")
	var b: Dictionary = gs.ronda_cfg.noites.alley.boss
	var ko1 := {"win": true, "ko": true, "round": 1}
	var ko2 := {"win": true, "ko": true, "round": 2}
	var ko3 := {"win": true, "ko": true, "round": 3}
	checar(gs._beco._cumpriu(b, ko1, "scare") and gs._beco._cumpriu(b, ko2, "scare"), "SUSTO + K.O. no round 1 ou 2: cumpre")
	checar(not gs._beco._cumpriu(b, ko3, "scare"), "SUSTO + K.O. no round 3: nao cumpre")
	checar(not gs._beco._cumpriu(b, ko1, "seen") and not gs._beco._cumpriu(b, ko1, "time"), "K.O. cedo sem SUSTO: nao cumpre")
	checar(not gs._beco._cumpriu(b, {"win": true, "ko": false, "round": 1}, "scare"), "SUSTO sem K.O. (pontos): nao cumpre")
	checar(not gs._beco._cumpriu(b, {"win": false, "ko": true, "round": 1}, "scare"), "perdeu: nao cumpre")
	checar(gs._beco._cond(b, "scare").is_valid() and not gs._beco._cond(b, "seen").is_valid(), "chance do desafio so existe com SUSTO")
	_liberar(gs)


# ---------------------------------------------------------------- previa honesta (B6)
func _teste_previa() -> void:
	var gs := _novo("r2a2_previa")
	_andar(gs, 181)
	gs.ronda_ir("alley", CHEFE)
	_aproximar(gs, "time")
	var p: Dictionary = gs.briga_previa()
	checar(not p.is_empty() and p.boss and p.bandit == CHEFE and p.opponent.name == gs.texto_ui("alley_apagao_anon"), "previa do chefe: anonima antes de vencer")
	var c: Dictionary = p.challenge
	checar(c.type == "surprise_early" and not c.done and c.lost and c.by_tactic.is_empty(), "sem SUSTO: DESAFIO PERDIDO, sem porcentagem")
	var opp := {"id": CHEFE, "strength": gs.ronda_cfg.noites.alley.boss.strength, "agility": gs.ronda_cfg.noites.alley.boss.agility,
		"endurance": gs.ronda_cfg.noites.alley.boss.endurance, "passive": gs.ronda_cfg.noites.alley.boss.passive, "style": "boxing", "name": "", "profile": ""}
	var jog: Array = gs._luta._atributos_cru()
	var adv: Array = gs._luta._array_adversario(opp)
	for t in gs.lutas.taticas:
		var det: Dictionary = gs.motor.chance_detalhada(jog, adv, str(t.id), 0)
		checar_igual(float(p.risks[t.id].chance), float(det.chance), "chance da previa = chance do motor (tatica %s)" % t.id)
	gs.ronda_voltar()
	_liberar(gs)
	var g2 := _novo("r2a2_previa2")
	_andar(g2, 181)
	g2.ronda_ir("alley", CHEFE)
	_aproximar(g2, "scare")
	var p2: Dictionary = g2.briga_previa()
	var cond: Callable = g2._beco._cond(g2.ronda_cfg.noites.alley.boss, "scare")
	var jog2: Array = g2._luta._atributos_cru()
	var opp2 := {"id": CHEFE, "strength": g2.ronda_cfg.noites.alley.boss.strength, "agility": g2.ronda_cfg.noites.alley.boss.agility,
		"endurance": g2.ronda_cfg.noites.alley.boss.endurance, "passive": g2.ronda_cfg.noites.alley.boss.passive, "style": "boxing", "name": "", "profile": ""}
	var adv2: Array = g2._luta._array_adversario(opp2)
	var ok: bool = not p2.challenge.by_tactic.is_empty() and not p2.challenge.lost
	for t in g2.lutas.taticas:
		var det2: Dictionary = g2.motor.chance_detalhada(jog2, adv2, str(t.id), 0, cond)
		ok = ok and int(p2.challenge.by_tactic[t.id]) == g2._textos._porcentagem(float(det2.cond_wins) / float(det2.n))
	checar(ok, "com SUSTO: chance do desafio por tatica = a contagem do K.O. cedo nas mesmas 200 lutas")
	# a previa nunca sabe do apagao
	checar(not p2.has("blackout") or not (p2.blackout is Dictionary and p2.blackout.has("t")), "a previa nao sabe do apagao")
	g2.ronda_voltar()
	_liberar(g2)


# ---------------------------------------------------------------- o apagao e so visual (B7)
func _teste_apagao_so_visual() -> void:
	var gs := _novo("r2a2_apagao")
	var b: Dictionary = gs.ronda_cfg.noites.alley.boss
	var t_apagao: float = float(b.blackout.after_round) * float(gs.motor.c.round_length)
	var longa := false
	var curta := false
	var coerente := true
	var igual := true
	var mults := [0.05, 0.3, 0.6, 1.0, 1.4, 2.0, 4.0, 40.0, 1.0e4]
	for m in mults:
		var guardados: Dictionary = gs.atributos.duplicate()
		var opp := {"strength": b.strength, "agility": b.agility, "endurance": b.endurance}
		var at := {"strength": float(opp.strength) * m, "agility": float(opp.agility) * m, "endurance": float(opp.endurance) * m}
		_andar(gs, 1)
		if not gs.capuz_info().get("clickable", false):
			_capuz(gs)
		gs.ronda_ir("alley", CHEFE)
		_aproximar(gs, "scare")
		gs.atributos = at
		var info: Dictionary = gs.briga_lutar(_tatica(gs))
		gs.atributos = guardados
		# a luta e a do motor com a mesma semente: mesmos eventos, com ou sem o apagao
		var jog: Array = [at.strength, at.agility, at.endurance]
		var adv: Array = gs._luta._array_adversario({"id": CHEFE, "strength": b.strength, "agility": b.agility, "endurance": b.endurance, "passive": b.passive, "style": "boxing", "name": "", "profile": ""})
		var r1: Dictionary = gs.motor.lutar(jog, adv, _tatica(gs), int(info.seed), true)
		var r2: Dictionary = gs.motor.lutar(jog, adv, _tatica(gs), int(info.seed), true)
		igual = igual and r1.events.size() == r2.events.size() and r1.win == r2.win and absf(r1.t_end - r2.t_end) < 1e-12 and r1.win == info.result.win
		var tem: bool = not info.blackout.is_empty()
		coerente = coerente and (tem == (float(r1.t_end) > t_apagao))
		if tem:
			longa = true
			coerente = coerente and absf(float(info.blackout.t) - t_apagao) < 1e-9 and float(info.blackout.dark_s) == float(b.blackout.dark_s)
		else:
			curta = true
		if bool(r1.win) and bool(r1.ko) and int(r1.round) <= int(b.challenge.max_round):
			coerente = coerente and not tem  # uma luta vencida ate o round 2 nunca mostra o apagao
		gs.ronda_voltar()
		gs.permanente.black_cat.erase("boss")
	checar(igual, "a luta da noite e a do motor com a mesma semente (eventos e resultado iguais, apagao ou nao)")
	checar(longa and curta, "houve luta longa (com apagao) e curta (sem apagao) na amostra")
	checar(coerente, "o apagao so aparece quando t_end passa de 2 x round_length; luta vencida ate o round 2 nunca o mostra")
	_liberar(gs)
	# o resultado nao depende do apagao: apagar o bloco do info nao muda nada que o jogo grava (o save so tem a ficha)
	var g2 := _novo("r2a2_apagao2")
	_noite_chefe(g2, "scare", PEQUENO)
	checar(not _ficha(g2).is_empty(), "a noite do chefe grava a ficha (o uso so do _rng_ronda e provado no teste do save igual)")
	_liberar(g2)


# ---------------------------------------------------------------- perder e vencer (B4, B11)
func _teste_derrota_e_vitoria() -> void:
	var gs := _novo("r2a2_premio")
	_andar(gs, 181)
	var antes_save: Dictionary = gs.para_save().duplicate(true)
	var l0: Dictionary = gs.lenda()
	var hood0: float = gs.capuz.hood_s
	# derrota sem SUSTO
	var info: Dictionary = _noite_chefe(gs, "time", PEQUENO)
	var pr: Dictionary = info.night_prize
	checar(not pr.win and pr.boss and pr.legend_gain == 1 and not pr.dossier_new and pr.trophy_new == "" and not pr.press_title_new and not pr.poster_new and pr.style_unlocked == "", "derrota: lenda +1, sem ficha, troféu, título, cartaz nem estilo")
	checar_igual(int(gs.lenda().legend), int(l0.legend) + 1, "lenda +1")
	var f: Dictionary = _ficha(gs)
	checar(int(f.won) == 0 and int(f.lost) == 1 and not bool(f.challenge), "ficha: 1 derrota")
	checar(gs.quadro_noite()[1].revenge and gs.esconderijo().boss.revenge, "REVANCHE no cartao")
	checar(gs.esconderijo().trophies.all(func(t): return t.state == "empty") and not gs.estilo_liberado("live_wire"), "nada na prateleira nem estilo")
	var depois: Dictionary = gs.para_save()
	checar_igual(JSON.stringify(_sem_tempo(depois.duplicate(true)), "", true), JSON.stringify(_sem_tempo(antes_save.duplicate(true)), "", true), "Legado, FAMA, dias, AQUECIDO e carreira iguais depois de perder")
	checar(absf(float(gs.capuz.next_at) - (float(gs.capuz.hood_s) + _IV())) < 1.0e-6 and gs.capuz.open == "", "capuz volta no proximo intervalo de sala")
	checar(gs.capuz.hood_s >= hood0, "relogio so andou para a frente")
	# derrota com SUSTO: lenda +2
	var info2: Dictionary = _noite_chefe(gs, "scare", PEQUENO)
	checar(info2.night_prize.legend_gain == 2 and int(_ficha(gs).lost) == 2, "derrota com SUSTO: lenda +2, 2 derrotas")
	# vitoria sem SUSTO: o desafio e impossivel
	var info3: Dictionary = _noite_chefe(gs, "seen", GRANDE)
	var p3: Dictionary = info3.night_prize
	checar(p3.win and p3.boss and p3.legend_gain == 3 and p3.dossier_new and p3.clipping_new and not p3.challenge_done, "vitoria sem SUSTO: lenda +3, ficha e recorte, sem desafio")
	checar(p3.trophy_new == "normal" and p3.press_title_new and p3.poster_new and str(p3.trophy_line) != "" and str(p3.press_title_line).contains(gs.texto_ui("press_title_apagao")) and str(p3.poster_line) != "", "vitoria: troféu normal, titulo da imprensa e cartaz (com as linhas)")
	checar(p3.title == gs.texto_ui("alley_boss_prize_title") and p3.style_unlocked == "", "titulo do premio do chefe; nenhum estilo sem o desafio")
	checar(not gs.estilo_liberado("live_wire"), "estilo raro so depois do desafio")
	var fw: Dictionary = _ficha(gs)
	checar(int(fw.won) == 1 and int(fw.lost) == 2 and int(fw.first_win_campaign) == 9 and not bool(fw.challenge), "ficha: venceu na campanha 9, sem desafio")
	var t0: Dictionary = gs.esconderijo().trophies[0]
	checar(t0.state == "normal" and gs.esconderijo().boss.known and gs._menu._requisito_ok({"black_cat_boss_won": CHEFE}), "prateleira normal, ficha aberta e cartaz do menu")
	checar(gs.quadro_noite().size() == 3 and gs.quadro_noite()[2].challenge_only, "cartao DESAFIO do chefe no fim do quadro")
	# vencer de novo sem cumprir so da a lenda
	var info4: Dictionary = _noite_chefe(gs, "time", GRANDE)
	var p4: Dictionary = info4.night_prize
	checar(p4.win and not p4.dossier_new and not p4.challenge_done, "vencer de novo sem cumprir: so a lenda")
	checar(p4.trophy_new == "" and not p4.poster_new and not p4.press_title_new, "vencer de novo: nada repetido")
	_liberar(gs)


# ---------------------------------------------------------------- desafio, raro e estilo (B11)
func _teste_desafio_raro_e_estilo() -> void:
	var gs := _novo("r2a2_raro")
	_andar(gs, 181)
	checar(not (("live_wire") in gs.disciples.opcoes_ativas("shorts_color")), "live_wire fora da lista antes do desafio")
	# 1a vitoria ja com o desafio: SUSTO + K.O. no 1o round (atributos enormes)
	var info: Dictionary = _noite_chefe(gs, "scare", GRANDE)
	var p: Dictionary = info.night_prize
	checar(p.win and p.ko and int(p.round) <= 2 and p.challenge_done and p.trophy_new == "rare" and p.style_unlocked == "live_wire", "1a vitoria cumprindo o desafio: raro e estilo na mesma tela")
	checar(str(p.trophy_line) != "" and str(p.trophy_rare_line) != "" and p.press_title_new and p.poster_new, "as linhas da vitoria e do raro vem juntas")
	checar(p.style_text == gs.preencher(gs.texto_ui("alley_style_unlocked"), {"estilo": gs.texto_ui("disc_opt_shorts_color_live_wire")}), "texto do estilo com o nome FIO DESENCAPADO")
	checar(not info.blackout is Dictionary or info.blackout.is_empty(), "K.O. ate o round 2: o apagao nunca acontece")
	checar(bool(_ficha(gs).challenge) and gs.estilo_liberado("live_wire") and gs.esconderijo().boss.style_unlocked, "estilo gravado e liberado")
	var t: Dictionary = gs.esconderijo().trophies[0]
	checar(t.state == "rare" and t.sprite == "trophy_apagao_rare" and gs.esconderijo().trophies.filter(func(x): return x.state != "empty").size() == 1, "capacete raro no mesmo lugar")
	var cores: Array = gs.disciples.opcoes_ativas("shorts_color")
	checar(cores[-1] == "live_wire" and cores[-2] == "night" or cores[-1] == "live_wire", "live_wire no fim da lista de cor do calcao")
	checar(gs.quadro_noite().size() == 2 and gs.quadro_noite()[1].night == "quiet", "com o desafio feito nao sobra cartao")
	# persiste
	gs.salvar()
	var g2: Node = GameStateScript.new()
	g2.inicializar(gs.store.pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar(g2.estilo_liberado("live_wire") and bool(g2.permanente.black_cat.boss[CHEFE].challenge), "tudo persiste no save")
	# look salvo com live_wire sem o estilo volta ao padrao; com o estilo, fica
	var s: Dictionary = g2.para_save().duplicate(true)
	s.career["disciple"] = {"name": "Zuzu", "look": g2.disciples.look_padrao.duplicate(), "campaign": 4}
	s.career.disciple.look["shorts_color"] = "live_wire"
	g2.aplicar_save(s)
	checar(str(g2.discipulo.look.shorts_color) == "live_wire", "discipulo com o calcao FIO DESENCAPADO e o estilo: fica")
	s.permanent.black_cat.boss[CHEFE].challenge = false
	g2.aplicar_save(s)
	checar(str(g2.discipulo.look.shorts_color) == str(g2.disciples.look_padrao.shorts_color), "calcao raro sem o estilo: volta ao padrao")
	var d := DiscipulosData.carregar()
	d.ligar_todas_as_opcoes()
	checar(not ("live_wire" in d.opcoes_ativas("shorts_color")), "ligar_todas_as_opcoes pula o estilo raro")
	for g in [gs, g2]:
		_liberar(g)


# ---------------------------------------------------------------- cartaz no menu (E4)
func _teste_menu_cartaz() -> void:
	var gs := _novo("r2a2_menu")
	var req := {"black_cat_boss_won": CHEFE}
	checar(not gs._menu._requisito_ok(req), "cartaz: nao aparece sem vencer")
	gs.permanente.black_cat["boss"] = {CHEFE: {"won": 0, "lost": 3, "first_win_campaign": 0, "challenge": false}}
	checar(not gs._menu._requisito_ok(req), "cartaz: perder nao conta")
	gs.permanente.black_cat["boss"] = {CHEFE: {"won": 1, "lost": 0, "first_win_campaign": 9, "challenge": false}}
	checar(gs._menu._requisito_ok(req), "cartaz: aparece depois da vitoria (so o 1o desafio nao precisa)")
	checar(not gs._menu._requisito_ok({"black_cat_boss_won": "outro"}), "cartaz: chefe desconhecido nao vale")
	var milestones_antes: Array = gs.escola.milestones.keys()
	gs.salvar()
	checar_igual(gs.escola.milestones.keys(), milestones_antes, "nenhum school.milestones novo")
	_liberar(gs)


# ---------------------------------------------------------------- save (B12)
func _teste_save() -> void:
	var gs := _novo("r2a2_save")
	_andar(gs, 181)
	gs.salvar()
	var pasta: String = gs.store.pasta
	# aproximacao e previa: nada
	gs.ronda_ir("alley", CHEFE)
	gs.salvar()
	var g2: Node = GameStateScript.new()
	g2.inicializar(pasta, "res://data/config.json")
	g2.autosave_ativo = false
	checar(g2.ronda_ativa == "" and g2.capuz.open == "scare" and not _bc(g2).has("boss") and int(_bc(g2).rounds) == 12, "fechou na aproximacao: nada mudou")
	_aproximar(gs, "scare")
	gs.salvar()
	var g3: Node = GameStateScript.new()
	g3.inicializar(pasta, "res://data/config.json")
	g3.autosave_ativo = false
	checar(g3.capuz.open == "scare" and not _bc(g3).has("boss"), "fechou na previa: nada mudou")
	# SAIR na aproximacao nao gasta o capuz (B8)
	var g6 := _novo("r2a2_sair")
	_andar(g6, 181)
	g6.ronda_ir("alley", CHEFE)
	var save_ir: String = JSON.stringify(g6.para_save(), "", true)
	g6.ronda_concluir()
	g6.ronda_voltar()
	checar(g6.capuz.open == "scare" and not _bc(g6).has("boss") and g6.ronda_ativa == "", "SAIR na aproximacao: capuz continua no prego e nada gravado")
	g6.capuz["hood_s"] = float(g6.capuz.hood_s)
	checar(JSON.stringify(g6.para_save(), "", true) == save_ir, "SAIR nao grava nada")
	# LUTAR: gravado uma vez so
	gs.atributos = GRANDE.duplicate()
	var info: Dictionary = gs.briga_lutar(_tatica(gs))
	checar(not info.is_empty(), "LUTAR no chefe")
	var g4: Node = GameStateScript.new()
	g4.inicializar(pasta, "res://data/config.json")
	g4.autosave_ativo = false
	checar(g4.ronda_ativa == "" and g4.capuz.open == "" and int(g4.permanente.black_cat.boss[CHEFE].won) == 1 and int(_bc(g4).rounds) == 13, "fechou na luta: ficha, lenda e capuz gravados")
	checar(bool(g4.permanente.black_cat.boss[CHEFE].challenge) and g4.estilo_liberado("live_wire"), "e o desafio e o estilo")
	g4.salvar()
	var g5: Node = GameStateScript.new()
	g5.inicializar(pasta, "res://data/config.json")
	g5.autosave_ativo = false
	checar(int(g5.permanente.black_cat.boss[CHEFE].won) == 1 and int(_bc(g5).rounds) == 13, "salvar/abrir de novo nao duplica")
	# o que a UI ve depois de fechar: nada pendente
	checar(g5.briga_resultado().is_empty() and g5.briga_estado().fase == "", "nao ha premio pendente nem luta de novo")
	# saves sujos
	var base: Dictionary = g5.para_save().duplicate(true)
	var s1: Dictionary = base.duplicate(true)
	s1.permanent.black_cat["boss"] = {CHEFE: {"won": -3, "lost": "x", "first_win_campaign": 99, "challenge": true}, "fantasma": {"won": 1, "lost": 0}}
	g5.aplicar_save(s1)
	checar(not _bc(g5).has("boss"), "numero ruim sem partida e id desconhecido: nada fica")
	checar(g5.avisos.any(func(x): return str(x).contains("fantasma")), "chefe desconhecido: aviso")
	var s2: Dictionary = base.duplicate(true)
	s2.permanent.black_cat["boss"] = {CHEFE: {"won": 1.0e30, "lost": 2, "first_win_campaign": 99, "challenge": true}}
	g5.aplicar_save(s2)
	var f: Dictionary = _ficha(g5)
	checar(int(f.won) == 1000000000 and int(f.lost) == 2 and int(f.first_win_campaign) == 9 and bool(f.challenge), "gigante = teto; campanha > atual = atual")
	var s3: Dictionary = base.duplicate(true)
	s3.permanent.black_cat["boss"] = {CHEFE: {"won": 0, "lost": 2, "first_win_campaign": 3, "challenge": true}}
	g5.aplicar_save(s3)
	checar(not bool(_ficha(g5).challenge) and int(_ficha(g5).first_win_campaign) == 0, "desafio sem vitoria = false")
	var s4: Dictionary = base.duplicate(true)
	s4.permanent.black_cat["boss"] = {CHEFE: {"won": 1, "lost": 0, "first_win_campaign": 8, "challenge": "sim"}}
	s4.permanent["regional_belts"] = 0
	s4.permanent.black_cat["alley"] = {}
	g5.aplicar_save(s4)
	checar(int(_ficha(g5).won) == 1 and not bool(_ficha(g5).challenge) and g5.avisos.any(func(x): return str(x).contains("sem os requisitos")), "chefe vencido sem os requisitos: mantido, com aviso")
	var s5: Dictionary = base.duplicate(true)
	s5.permanent.black_cat.erase("boss")
	g5.aplicar_save(s5)
	checar(not _bc(g5).has("boss") and not g5.esconderijo().boss.known, "save de antes (sem o campo boss): abre igual")
	var s7: Dictionary = base.duplicate(true)
	s7.permanent.black_cat["boss"] = [1, 2]
	g5.aplicar_save(s7)
	checar(not _bc(g5).has("boss"), "campo boss no formato errado: ignorado")
	for g in [gs, g2, g3, g4, g5, g6]:
		_liberar(g)


# ---------------------------------------------------------------- capuz a 300 s (B15)
func _teste_capuz_300() -> void:
	var gs := _novo("r2a2_capuz")
	var cfg: RondaData = gs.ronda_cfg
	_andar(gs, int(cfg.capuz.first_after_s) - 1)
	checar(not gs.capuz_info().get("clickable", false), "antes do 1o capuz: nada")
	_andar(gs, 1)
	checar(gs.capuz_info().get("clickable", false), "o 1o capuz no tempo do first_after_s")
	gs.ronda_ir()
	gs.ronda_jogo().sustos = 1
	gs.ronda_concluir()
	gs.ronda_voltar()
	var h: float = gs.capuz.hood_s
	checar(absf(float(gs.capuz.next_at) - (h + _IV())) < 1.0e-6, "o proximo capuz = hood_s da volta + intervalo")
	# fora da sala o relogio nao anda
	gs.definir_modal(true)
	_andar(gs, 100)
	gs.definir_modal(false)
	checar_igual(float(gs.capuz.hood_s), h, "fora da sala o relogio do capuz nao anda")
	_andar(gs, int(_IV()) - 1)
	checar(not gs.capuz_info().get("clickable", false), "1 s antes do intervalo: sem capuz")
	_andar(gs, 1)
	checar(gs.capuz_info().get("clickable", false), "no intervalo: o capuz")
	# nao acumula: com o capuz no prego o relogio nao junta outro
	var esp: float = float(gs.capuz.next_at)
	_andar(gs, int(_IV()) * 2)
	gs.ronda_ir()
	gs.ronda_jogo().sustos = 1
	gs.ronda_concluir()
	gs.ronda_voltar()
	checar(not gs.capuz_info().get("clickable", false) and float(gs.capuz.next_at) > esp, "nao acumula: depois de usar espera o intervalo inteiro de novo")
	# o chefe usa o mesmo intervalo
	var g2 := _novo("r2a2_capuz2")
	_noite_chefe(g2, "time", PEQUENO)
	checar(absf(float(g2.capuz.next_at) - (float(g2.capuz.hood_s) + _IV())) < 1.0e-6, "o chefe gasta o capuz e o proximo vem no mesmo intervalo")
	# save com next_at antigo (feito com 240 s) carrega e vale como esta
	var s: Dictionary = g2.para_save().duplicate(true)
	s.career["black_cat_hood"] = {"hood_s": 500.0, "next_at": 740.0, "open": ""}
	g2.aplicar_save(s)
	checar(float(g2.capuz.next_at) == 740.0 and float(g2.capuz.hood_s) == 500.0, "save com next_at antigo carrega o valor gravado")
	_andar(g2, 239)
	checar(not g2.capuz_info().get("clickable", false), "o antigo vale: 239 s depois ainda nao")
	_andar(g2, 2)
	checar(g2.capuz_info().get("clickable", false), "o antigo vale: aos 240 s o capuz volta")
	g2.ronda_ir()
	g2.ronda_jogo().sustos = 1
	g2.ronda_concluir()
	checar(absf(float(g2.capuz.next_at) - (float(g2.capuz.hood_s) + _IV())) < 1.0e-6, "depois dele o intervalo novo")
	g2.ronda_voltar()
	for g in [gs, g2]:
		_liberar(g)


# ---------------------------------------------------------------- limiares da lenda (B16)
func _teste_limiares() -> void:
	var gs := _novo("r2a2_lenda", 0)
	var casos: Dictionary = JSON.parse_string(ler("res://tests/data/ronda_casos.json"))
	var ok := true
	for l in casos.nivel.size():
		ok = ok and gs.ronda_cfg.nivel_de(l) == int(casos.nivel[l])
	checar(ok, "nivel_de() bate com o ronda_casos.json regerado")
	checar_igual(gs.ronda_cfg.nivel_de(_LV(2)), 3, "limiar do nivel 3")
	checar_igual(gs.ronda_cfg.nivel_de(_LV(2) - 1), 2, "um abaixo do nivel 3")
	checar_igual(gs.ronda_cfg.nivel_de(_LV(4)), 5, "limiar do nivel 5")
	_andar(gs, 1)
	gs.permanente["black_cat"] = {"legend": _LV(2), "rounds": 6, "scares": 3, "shown_level": 3, "open_campaign": 3}
	gs.permanente["skill_nodes"] = ["cat_rooftop"]
	checar(gs.briga_aberta(), "nivel 3: as brigas abrem")
	checar_igual(gs.estado_mapa("cat_watch"), "visible", "nivel 3: cat_watch abre")
	gs.permanente["black_cat"].legend = _LV(4) - 1
	checar_igual(gs.estado_mapa("cat_thanks"), "sealed", "um abaixo do nivel 5: cat_thanks lacrado")
	gs.permanente["black_cat"].legend = _LV(4)
	checar_igual(gs.estado_mapa("cat_thanks"), "visible", "nivel 5: cat_thanks abre")
	_liberar(gs)
	# save antigo: lenda 25 (nivel 2 antes) carrega no nivel 3 e mostra a subida uma vez
	var g2 := _novo("r2a2_lenda_velha", 0)
	var s: Dictionary = g2.para_save().duplicate(true)
	s.permanent["black_cat"] = {"legend": _LV(2) + 1, "rounds": 6, "scares": 3, "shown_level": 2, "open_campaign": 3}
	g2.aplicar_save(s)
	checar(g2.lenda().level == 3 and g2.lenda().shown_level == 2 and g2.lenda().legend == _LV(2) + 1, "lenda 25 carrega no nivel 3 (nada se perde); a subida ainda nao foi mostrada")
	g2.permanente["career_number"] = 9
	g2.escola.milestones["black_cat_rumor_heard"] = {"campaign": 8, "version": 1}
	_andar(g2, 181)
	g2.ronda_ir()
	g2.ronda_jogo().sustos = 1
	var p: Dictionary = g2.ronda_concluir()
	checar(p.level_up and p.level == 3 and g2.lenda().shown_level == 3, "o proximo premio da Ronda mostra a subida uma vez")
	g2.ronda_voltar()
	_andar(g2, int(_IV()))
	g2.ronda_ir()
	g2.ronda_jogo().sustos = 1
	var p2: Dictionary = g2.ronda_concluir()
	checar(not p2.level_up, "e nao repete")
	_liberar(g2)


# ---------------------------------------------------------------- chefe = SUSTO para o resto do save (B2)
func _corrida(nome: String, chefe: bool) -> Dictionary:
	var gs := _novo(nome)
	gs.geradores[gs.dados.geradores[0].id] = 3
	var vez := 0
	for _i in 2000:
		gs.tick(1.0)
		if not gs.capuz_info().get("clickable", false):
			continue
		if chefe:
			vez += 1
			if gs.ronda_ir("alley", CHEFE).is_empty():  # chefe vencido com o desafio: volta ao SUSTO
				gs.ronda_ir()
				gs.ronda_jogo().sustos = 1
				gs.ronda_concluir()
				gs.ronda_voltar()
				continue
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
	var r := {"save": JSON.stringify(e, "", true), "rounds": int(gs.lenda().rounds), "boss": _bc(gs).get("boss", {}).duplicate(true)}
	for k in ["rng", "_rng_evento", "_rng_fala", "_rng_sucessao", "_rng_treino"]:
		r[k] = gs.get(k).state
	_liberar(gs)
	return r


func _teste_chefe_igual() -> void:
	var a := _corrida("r2a2_igual_a", false)
	var b := _corrida("r2a2_igual_b", true)
	checar(a.boss.is_empty() and not b.boss.is_empty() and int(b.rounds) > 12, "A so SUSTO; B foi no chefe (perdendo e vencendo)")
	checar(a.save == b.save, "mesma campanha so com SUSTO ou indo no chefe: save igual campo a campo (sem black_cat e capuz)")
	for k in ["rng", "_rng_evento", "_rng_fala", "_rng_sucessao", "_rng_treino"]:
		checar(a[k] == b[k], "sorteio %s igual" % k)
	var d := DiscipulosData.carregar()
	d.liberado = func(_r: String) -> bool: return true
	var d0 := DiscipulosData.carregar()
	var r1 := RandomNumberGenerator.new()
	var r2 := RandomNumberGenerator.new()
	r1.seed = 77
	r2.seed = 77
	checar_igual(JSON.stringify(d.sortear(r1, [])), JSON.stringify(d0.sortear(r2, [])), "sucessao seguinte com live_wire liberado: o rascunho sorteado e o mesmo")
