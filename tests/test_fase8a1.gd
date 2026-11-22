extends "res://tests/test_base.gd"
## Fase 8a1 (liga regional): escada com os 4 regionais, passiva do adversario (travas e guarda) contra o simulador Python,
## sinais da luta, previa, motivo, James (placar e falas), cinturao regional e save antigo. Referencia: tools/sim/fase8a1_sim.py
## e docs/fases/fase8a1-design.md. Casos exatos: tests/data/fase8a1_casos.json (312). Tudo em user://test/, nunca o save real.

const GameStateScript := preload("res://scripts/game_state.gd")
const CASOS := "res://tests/data/fase8a1_casos.json"
const REGIONAIS := ["opp_reg_1", "opp_reg_2", "opp_reg_3", "opp_james"]
const FIM_PY := {"damage": "damage", "points": "points", "knockout": "knockout", "submission": "submission", "spin_kick": "spin_kick",
	"counter_ko": "counter_ko", "ground_stop": "ground_stop", "knee_ko": "knee_ko"}

var dados: FightData
var gym: GymData
var _soma_dif := 0.0
var _max_dif := 0.0


func rodar_testes() -> void:
	dados = FightData.carregar()
	gym = GymData.carregar()
	_teste_dados()
	_teste_python_exato()
	_teste_sinais_e_guarda()
	_teste_escada_e_cinturao()
	_teste_save_antigo()
	_teste_james()
	_teste_nota_e_previa()
	_teste_dialogos()


func _motor(arte: String, passiva: int, extra: float = 0.0) -> Luta:
	var m := Luta.new(dados)
	if arte != "":
		m.passiva = gym.arte(arte).get("passive" if passiva == 1 else "passive_2").duplicate(true)
		m.extra_passiva = extra
	return m


func _adv(id: String) -> Array:
	var o := dados.adversario(id)
	var a: Array = [o.strength, o.agility, o.endurance]
	if not o.get("passive", {}).is_empty():
		a.append(o.passive)
	return a


func _aprox(a: float, b: float, rel: float) -> bool:
	return absf(a - b) <= rel * maxf(maxf(absf(a), absf(b)), 1.0e-12)


func _novo(nome: String, arte: String = "boxing") -> Node:
	var gs: Node = GameStateScript.new()
	gs.inicializar(pasta_limpa(nome), "res://data/config.json")
	gs.autosave_ativo = false
	gs.risco_hud_ativo = false
	gs.lutas.calendario["seconds_per_day"] = 0.0
	gs.pular_abertura()
	if arte != "":
		gs.permanente["arts_unlocked"] = ["boxing", "bjj", "muay_thai"]
		gs.escolher_arte(arte, 1)
	return gs


func _liberar(g: Node) -> void:
	g.aguardar_motivo()
	g.free()


# --- Dados ---
func _teste_dados() -> void:
	checar_igual(dados.adversarios.size(), 10, "escada = 6 de antes + 4 regionais")
	checar_igual(dados.adversarios.slice(6).map(func(a: Dictionary) -> String: return a.id), REGIONAIS, "ordem da liga")
	for i in 6:
		checar(dados.adversarios[i].get("passive", {}).is_empty() and dados.adversarios[i].get("league", "") == "", "%s: sem passiva nem liga" % dados.adversarios[i].id)
	checar_igual(dados.indice_do_kid(), 5, "o Kid continua sendo o indice 5")
	checar_igual(dados.indice_cinturao_regional(), 9, "o James da o cinturao regional")
	checar_igual(dados.arena_da_liga(dados.adversario("opp_reg_1")), "arena_regional", "arena da liga")
	checar_igual(dados.arena_da_liga(dados.adversario("opp_gym_2")), "", "o Kid segue na arena dele")
	checar_igual(int(dados.adversario("opp_james").prep_days), 20, "James: 20 dias")
	checar(dados.adversario("opp_reg_1").passive.locks.fast_hands.ko_per_streak == 0.0, "Bigorna: K.O. de embalo x0")
	checar(dados.adversario("opp_james").passive.guard.taken_mult == 0.6, "James: guarda x0,6")
	# liga ruim: passiva invalida sai sem passiva; adversario ruim sai
	var ruim := {"id": "regional", "after": "opp_gym_2", "opponents": [
		{"id": "x1", "strength": 1, "agility": 1, "endurance": 1, "passive": {"id": "p", "locks": {"nada": {"a": 1}}}},
		{"id": "x2", "strength": 1, "agility": 1, "endurance": 1, "passive": {"id": "p", "guard": {"rounds": 9, "taken_mult": 0.5}}},
		{"id": "opp_gym_2"}, {"id": ""}]}
	DirAccess.make_dir_recursive_absolute("user://test")
	escrever("user://test/liga_ruim.json", JSON.stringify(ruim))
	var d2 := FightData.carregar(FightData.CAMINHO_LUTAS, FightData.CAMINHO_ADVERSARIOS, FightData.CAMINHO_LOJA, FightData.CAMINHO_CARREIRA,
		FightData.CAMINHO_ARVORE, "user://test/liga_ruim.json")
	checar_igual(d2.adversarios.size(), 8, "liga ruim: so os 2 adversarios validos entram")
	checar(d2.adversarios[6].get("passive", {}).is_empty() and d2.adversarios[7].get("passive", {}).is_empty(), "passivas invalidas = sem passiva")
	var d3 := FightData.carregar(FightData.CAMINHO_LUTAS, FightData.CAMINHO_ADVERSARIOS, FightData.CAMINHO_LOJA, FightData.CAMINHO_CARREIRA,
		FightData.CAMINHO_ARVORE, "user://test/nao_existe.json")
	checar_igual(d3.adversarios.size(), 6, "arquivo da liga ausente = escada de antes")
	DirAccess.remove_absolute("user://test/liga_ruim.json")


# --- Casos exatos contra o simulador Python ---
func _teste_python_exato() -> void:
	if not FileAccess.file_exists(CASOS):
		checar(false, "tests/data/fase8a1_casos.json existe")
		return
	var casos: Array = JSON.parse_string(FileAccess.get_file_as_string(CASOS)).exatos
	var iguais := 0
	var primeira := ""
	for c in casos:
		var m := _motor(str(c.art), int(c.passive), float(c.extra))
		var adv := _adv(str(c.opponent_id))
		var r := m.lutar_com_sorteios(c.player, adv, c.tactic, PackedFloat64Array(c.draws), true)
		var erro := _comparar(m, r, c, adv)
		if erro == "":
			iguais += 1
		elif primeira == "":
			primeira = "%s (%s, %s, %s)" % [erro, c.opponent_id, c.art, c.tactic]
	checar_igual(iguais, casos.size(), "GDScript = Python em %d lutas regionais%s" % [casos.size(), "" if primeira == "" else " | 1a falha: " + primeira])
	checar_igual(casos.size(), 312, "312 casos exatos")
	checar(_soma_dif / casos.size() <= 0.04 and _max_dif <= 0.2, "chance de 200 lutas bate com o Python (media %.3f, max %.3f)" % [_soma_dif / casos.size(), _max_dif])


func _comparar(m: Luta, r: Dictionary, c: Dictionary, adv: Array) -> String:
	var fim: String = str(r.get("finish", "damage" if r.ko else "points"))
	if r.win != c.win or r.ko != c.ko or fim != str(c.finish):
		return "resultado (win/ko/finish)"
	if absf(r.t_ko - c.t_ko) > 1e-9 or absf(r.t_end - c.t_end) > 1e-9:
		return "t_ko/t_end"
	if not _aprox(r.pct_player, c.pct_player, 1e-9) or not _aprox(r.pct_opponent, c.pct_opponent, 1e-9):
		return "% de vida"
	if r.draws_used != c.draws.size():
		return "sorteios consumidos %d x %d" % [r.draws_used, c.draws.size()]
	if r.events.size() != c.events.size():
		return "numero de eventos"
	for i in r.events.size():
		var e: Dictionary = r.events[i]
		var p: Array = c.events[i]
		if absf(e.t - p[0]) > 6e-4 or e.who != int(p[1]) or e.type != p[2] or e.counter != p[3]:
			return "evento %d" % i
		if e.type != "dodge" and (not _aprox(e.damage, p[4], 1e-7) or not _aprox(e.life_after, p[5], 1e-7)):
			return "dano/vida do evento %d" % i
	# chance_200: o Python usa outro gerador de sementes (1..200), entao aqui so se confere a ordem de grandeza (ver o teste estatistico)
	var dif := absf(m.chance(c.player, adv, c.tactic, 200) - float(c.chance_200))
	_soma_dif += dif
	_max_dif = maxf(_max_dif, dif)
	if str(c.art) != "":
		var est := m.estado_passiva(c.player, adv, c.tactic)
		for chave in c.est:
			if typeof(c.est[chave]) == TYPE_STRING or typeof(c.est[chave]) == TYPE_BOOL:
				if est[chave] != c.est[chave]:
					return "estado_passiva." + chave
			elif not _aprox(float(est[chave]), float(c.est[chave]), 1e-9):
				return "estado_passiva." + chave
	return ""


# --- Sinais (opp_block) e guarda ---
func _teste_sinais_e_guarda() -> void:
	# Bigorna x Mao rapida: o K.O. de embalo nunca sai; o sinal aparece em alguma luta
	var m := _motor("boxing", 1)
	var adv := _adv("opp_reg_1")
	var ko_embalo := 0
	var sinais := 0
	for s in range(1, 301):
		var jog := [adv[0] * 1.3, adv[1] * 1.3, adv[2] * 1.3]
		var r := m.lutar(jog, adv, "aggressive", s, true)
		if r.finish == "knockout":
			ko_embalo += 1
		sinais += int(r.opp_blocks)
		var marcados := 0
		for e in r.events:
			marcados += 1 if e.opp_block else 0
		if marcados != int(r.opp_blocks):
			ko_embalo += 1000
	checar_igual(ko_embalo, 0, "Bigorna: nenhum K.O. de embalo e eventos marcados = opp_blocks")
	checar(sinais > 0, "Bigorna: o sinal AGUENTOU aparece (%d em 300 lutas)" % sinais)
	# Estaca x Por cima, Sabao x Clinch
	for par in [["bjj", "opp_reg_2"], ["muay_thai", "opp_reg_3"]]:
		var mm := _motor(str(par[0]), 2)
		var a2 := _adv(str(par[1]))
		var tot := 0
		for s in range(1, 101):
			tot += int(mm.lutar([a2[0], a2[1], a2[2]], a2, "defensive" if par[0] == "muay_thai" else "aggressive", s, false).opp_blocks)
		checar(tot > 0, "%s: sinal da trava aparece (%d)" % [par[1], tot])
	# sem trava para o seu jeito: nenhum sinal, estado igual ao sem passiva
	var mc := _motor("boxing", 2)
	var a3 := _adv("opp_reg_1")
	var a3s := [a3[0], a3[1], a3[2]]
	checar_igual(mc.estado_passiva([1e8, 1e8, 1e8], a3, "counter"), mc.estado_passiva([1e8, 1e8, 1e8], a3s, "counter"), "Contragolpista passa livre pelo Bigorna")
	# Guarda do James: dano nele x0,6 so no 1o round; absorbed > 0; evento marcado
	var advj := _adv("opp_james")
	var mj := _motor("", 0)
	var rj := mj.lutar([advj[0], advj[1], advj[2]], advj, "aggressive", 5, true)
	checar(float(rj.guard_absorbed) > 0.0 and float(rj.guard_absorbed) <= 1.0, "James: a guarda absorveu parte da vida dele (%.3f)" % float(rj.guard_absorbed))
	var ate := float(dados.combate.round_length) * 1.0
	var ok := true
	for e in rj.events:
		if bool(e.guard) != (e.who == 0 and e.type != "dodge" and e.t < ate):
			ok = false
	checar(ok, "guarda marca exatamente os acertos seus no 1o round")
	# contra os 6 de antes o motor nao ganha campos novos
	var r0 := mj.lutar([1e6, 1e6, 1e6], _adv("opp_gym_2"), "aggressive", 3, true)
	checar(not r0.has("opp_blocks") and not r0.events[0].has("guard"), "Kid: motor igual ao de antes (sem campos da passiva dele)")


# --- Escada, calendario e cinturao ---
func _teste_escada_e_cinturao() -> void:
	var gs := _novo("f8a1_escada")
	gs.indice_escada = 5
	gs.local_id = "gym"
	gs.fight_day = gs._calendario._data_da_proxima_luta()
	checar(not gs.escada_completa(), "antes do Kid: escada nao completa")
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	var vistos: Array = []
	for i in 5:
		var opp: Dictionary = gs.proximo_adversario()
		if opp.is_empty():
			break
		gs.fight_day = 1
		gs.segundos_campanha = 1.0e9
		var info: Dictionary = gs.lutar()
		if info.is_empty():
			break
		var r: Dictionary = gs.concluir_luta()
		vistos.append(str(opp.id))
		if i == 0:
			checar(bool(r.league_opened) and gs.marco("regional_league_opened") and gs.liga_aberta(), "vencer o Kid abre a liga (marco)")
			checar(not gs.escada_completa() and gs.proximo_adversario().id == "opp_reg_1", "depois do Kid vem o Bigorna")
			checar_igual(gs.arena_da_luta("opp_reg_1"), "arena_regional", "arena regional")
	checar_igual(vistos, ["opp_gym_2"] + REGIONAIS, "a escada termina no James")
	checar(gs.escada_completa() and gs.cinturao_regional() and gs.estado_escada() == "end", "depois do James: campanha completa e cinturao regional")
	checar_igual(int(gs.permanente.regional_belts), 1, "linhagem: 1 cinturao regional")
	checar_igual(int(gs.permanente.first_regional_belt_campaign), gs.numero_carreira(), "linhagem: campanha do 1o cinturao regional")
	checar(gs.marco("regional_belt_first"), "marco do 1o cinturao regional")
	checar_igual(int(gs.rival().met), 1, "placar: 1 encontro")
	checar_igual(int(gs.rival().school_wins), 1, "placar: a escola venceu")
	var fim: Dictionary = gs.aposentar()
	checar_igual(int(fim.summary.belts), 1, "o fim da carreira conta o cinturao regional") if not fim.is_empty() else checar(false, "aposentou")
	checar(gs.escola.roster.back().get("regional_belt", false) == true, "roster guarda regional_belt")
	_liberar(gs)


# --- Save antigo depois do Kid ---
func _teste_save_antigo() -> void:
	var gs := _novo("f8a1_antigo")
	gs.indice_escada = 6
	gs.local_id = "gym"
	gs.fight_day = -1
	var estado: Dictionary = gs.para_save()
	estado.career["ladder_index"] = 6
	estado.career["fight_day"] = -1
	estado.career.erase("rival_spoke")
	estado.school.erase("rival")
	estado.school.milestones.erase("regional_league_opened")
	gs.aplicar_save(estado)
	checar(not gs.escada_completa() and gs.liga_aberta(), "save com indice 6 abre na liga")
	checar(gs.fight_day > 0 and gs.fight_day - gs.dia_campanha() == int(dados.adversario("opp_reg_1").prep_days) + int(gs._arvore._b("prep_days_bonus")),
		"folga cheia (16 dias) para o Bigorna")
	checar(gs.marco("regional_league_opened"), "marco da liga gravado ao carregar")
	checar(gs.rival() == {"met": 0, "school_wins": 0, "james_wins": 0} and not gs.rival_spoke.before, "campos novos ausentes = padrao")
	estado.school["rival"] = {"met": 1, "school_wins": 3, "james_wins": 2}
	gs.aplicar_save(estado)
	checar_igual(int(gs.rival().met), 5, "school_wins + james_wins > met corrige o met")
	_liberar(gs)


# --- James: falas e placar ---
func _teste_james() -> void:
	var gs := _novo("f8a1_james")
	gs.indice_escada = 9
	gs.local_id = "gym"
	gs.fight_day = 1
	gs.segundos_campanha = 1.0e9
	var casos := [
		[{"met": 0, "school_wins": 0, "james_wins": 0}, "first", 3],
		[{"met": 1, "school_wins": 0, "james_wins": 1}, "revenge", 2],
		[{"met": 2, "school_wins": 1, "james_wins": 1}, "school_won", 2],
		[{"met": 3, "school_wins": 1, "james_wins": 2}, "many", 2],
	]
	for c in casos:
		gs.escola["rival"] = c[0].duplicate()
		gs.rival_spoke = {"before": false, "after": false}
		checar_igual(gs._liga.situacao_intro(), c[1], "situacao %s" % c[1])
		var ids: Array = gs.fala_previa_james()
		checar_igual(ids.size(), c[2], "%s: %d falas" % [c[1], c[2]])
		var ok := true
		for i in ids.size():
			ok = ok and ids[i] == "rival_james_intro_%s_%d" % [c[1], i + 1]
		checar(ok, "%s: ids em ordem" % c[1])
		var soma := 0.0
		for id in ids:
			soma += gs.dialogos.duracao_fala(str(id))
		checar(soma <= 13.0, "%s: falas somam %.1f s (<= 13)" % [c[1], soma])
	# lutar grava rival_spoke e devolve ids sem mexer no resultado; pular/reabrir nao repete
	gs.escola["rival"] = {"met": 0, "school_wins": 0, "james_wins": 0}
	gs.rival_spoke = {"before": false, "after": false}
	gs.atributos = {"strength": 1.0e12, "agility": 1.0e12, "endurance": 1.0e12}
	var info: Dictionary = gs.lutar()
	checar_igual(info.intro_lines, ["rival_james_intro_first_1", "rival_james_intro_first_2", "rival_james_intro_first_3"], "lutar() traz a apresentacao")
	checar_igual(str(info.outro_line), "rival_james_after_lose_first_1", "fala de depois: o James perdeu, 1o encontro")
	checar(gs.rival_spoke.before and gs.rival_spoke.after, "rival_spoke gravado quando a luta comeca")
	checar_igual(gs.luta_atual().get("intro_lines", []), [], "luta_atual (reabrir) nao repete")
	var salvo: Dictionary = gs.para_save()
	checar(salvo.career.rival_spoke.before and salvo.career.rival_spoke.after, "o save leva rival_spoke")
	checar(gs.fala_previa_james().is_empty() and gs.fala_depois_james(true) == "", "2a vez na campanha: nada")
	gs.concluir_luta()
	checar_igual(int(gs.rival().met), 1, "placar apos a luta")
	_liberar(gs)
	# depois: James venceu x situacoes
	var g2 := _novo("f8a1_james2")
	for caso in [[{"met": 0, "school_wins": 0, "james_wins": 0}, true, "rival_james_after_win_first_1"],
			[{"met": 1, "school_wins": 1, "james_wins": 0}, false, "rival_james_after_lose_school_won_1"],
			[{"met": 1, "school_wins": 0, "james_wins": 1}, true, "rival_james_after_win_many_1"],
			[{"met": 2, "school_wins": 0, "james_wins": 2}, false, "rival_james_after_lose_many_1"]]:
		g2.indice_escada = 9
		g2.local_id = "gym"
		g2.escola["rival"] = caso[0].duplicate()
		g2.rival_spoke = {"before": true, "after": false}
		var ganhou: bool = not caso[1]
		var id: String = g2.fala_depois_james(ganhou)
		checar_igual(id, caso[2], "fala de depois %s" % caso[2])
		checar(not g2.dialogos.linha(id).is_empty(), "fala %s existe" % id)
	_liberar(g2)
	# derrota para o James encerra a carreira e conta james_wins
	var g3 := _novo("f8a1_james3")
	g3.indice_escada = 9
	g3.local_id = "gym"
	g3.fight_day = 1
	g3.segundos_campanha = 1.0e9
	g3.atributos = {"strength": 1.0, "agility": 1.0, "endurance": 1.0}
	g3.lutar()
	var r3: Dictionary = g3.concluir_luta()
	checar(not bool(r3.win) and not g3.fim.is_empty(), "derrota para o James encerra a carreira")
	checar_igual(int(g3.rival().james_wins), 1, "placar: James venceu 1")
	var fim: Dictionary = g3.textos_fim()
	checar(str(fim.get("opp_note", "")) != "" and str(fim.get("opp_note_id", "")) == "adv_blindado", "motivo da derrota: a guarda pesou (%s)" % str(fim.get("opp_note", "")))
	g3.nova_carreira()
	checar(not g3.rival_spoke.before and not g3.rival_spoke.after, "campanha nova: o James volta a falar")
	_liberar(g3)


# --- Previa e motivo da passiva dele ---
func _teste_nota_e_previa() -> void:
	var gs := _novo("f8a1_previa", "boxing")
	gs.indice_escada = 6
	gs.local_id = "gym"
	gs.atributos = {"strength": 1.0e8, "agility": 1.0e8, "endurance": 1.0e8}
	var p: Dictionary = gs.previa()
	checar(p.opp_passive_id == "adv_iron_chin" and p.opp_passive_hits and p.opp_passive_name == "QUEIXO DE FERRO", "previa: Bigorna atrapalha a Mao rapida")
	checar(str(p.opp_passive_hits_text).begins_with("ATRAPALHA") and str(p.opp_passive_line) != "" and p.opp_passive_icon == "adv_iron_chin", "previa: textos e icone")
	gs.indice_escada = 7
	checar(not bool(gs.previa().opp_passive_hits) and gs.previa().opp_passive_hits_text == "NÃO ATRAPALHA O SEU JEITO", "previa: Estaca nao atrapalha a Mao rapida")
	gs.indice_escada = 9
	checar(bool(gs.previa().opp_passive_hits), "previa: a guarda atrapalha todos")
	gs.indice_escada = 5
	checar(not gs.previa().has("opp_passive_id"), "previa do Kid: sem chaves novas")
	# nota do motor
	var m := _motor("bjj", 2)
	var adv := _adv("opp_reg_2")
	var n := m.nota_adversario({"win": false, "opp_blocks": 3}, adv)
	checar(n.id == "adv_wide_base" and n.n == 3, "opp_note: Base larga perdeu com trava")
	checar(m.nota_adversario({"win": false, "opp_blocks": 0}, adv).is_empty() and m.nota_adversario({"win": true, "opp_blocks": 2}, adv).is_empty(), "opp_note: so quando pesou e perdeu")
	var sab := m.nota_adversario({"win": false, "opp_blocks": 0, "released": 2}, _adv("opp_reg_3"))
	checar(sab.id == "adv_slippery", "opp_note: Ensaboado tambem pela soltura")
	var bl := m.nota_adversario({"win": false, "guard_absorbed": 0.123}, _adv("opp_james"))
	checar(bl.id == "adv_blindado" and bl.n == 12, "opp_note: Blindado em %% da vida")
	_liberar(gs)


func _teste_dialogos() -> void:
	var d := DialogosData.carregar()
	checar_igual(d.erros.size(), 0, "dialogos.json sem erros do validador (%s)" % str(d.erros))
	for id in ["regional_league_opened", "regional_belt_first", "james_intro", "james_after"]:
		checar(not d.gatilho(id).is_empty(), "gatilho %s existe" % id)
	checar(not d.texto_objeto("regional_poster", "title").is_empty() and not d.texto_objeto("regional_poster").is_empty(), "cartaz da liga")
	for id in ["cl_liga_regional", "cl_cinturao_regional"]:
		checar(not d.linha(id).is_empty(), "fala %s existe" % id)
	var gs := _novo("f8a1_osmar", "")
	gs.indice_escada = 6
	gs.aplicar_save(gs.para_save())
	checar(gs.marco("regional_league_opened"), "carregar com indice >= 6 grava o marco e pede a fala do Osmar")
	_liberar(gs)
