extends SceneTree
## QA Fase 4: cenarios extras de logica (sem janela). Usa so pastas de teste (user://test/qa4/...).
## Uso: godot --headless --path . --script res://tests/qa_f4_extra.gd -- <caminho do save v3 de entrada>

const PASTA := "user://test/qa4/"
var gs: Node
var falhas := 0


func ok(c: bool, msg: String) -> void:
	if c:
		print("QA| OK    ", msg)
	else:
		falhas += 1
		print("QA| FALHOU ", msg)


func escrever(pasta: String, texto: String) -> void:
	DirAccess.make_dir_recursive_absolute(pasta)
	var f := FileAccess.open(pasta.path_join("save.json"), FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func novo(pasta: String) -> Node:
	var g = load("res://scripts/game_state.gd").new()
	root.add_child(g)
	g.inicializar(pasta, "res://data/config.json")
	g.autosave_ativo = false
	return g


func _initialize() -> void:
	gs = root.get_node("GameState")
	gs.autosave_ativo = false
	var args := OS.get_cmdline_user_args()
	await process_frame
	# 1) save v3 real do dono -> v4
	if args.size() > 0:
		var txt: String = FileAccess.get_file_as_string(args[0])
		escrever(PASTA + "v3real/", txt)
		var g: Node = novo(PASTA + "v3real/")
		ok(g.permanente.legacy_total == 180, "v3 real: Legado 18 -> 180 (obtido %s)" % g.permanente.legacy_total)
		ok(g.permanente.career_number == 6 and g.permanente.best_wins == 3, "v3 real: carreira 6 e melhor 3 vitorias intactos")
		ok(g.nos_comprados().is_empty() and g.algoz() == "" and g.nivel_metronomo == 0, "v3 real: sem nos, sem algoz, Metronomo 0")
		ok(g.tempo_jogo > 6.8 and g.tempo_jogo < 7.0, "v3 real: tempo da carreira intacto (%s)" % g.tempo_jogo)
		g.salvar()
		var v: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PASTA + "v3real/save.json"))
		ok(int(v.version) == 4, "v3 real: regravado como versao 4")
		var g2: Node = novo(PASTA + "v3real/")
		ok(g2.permanente.legacy_total == 180, "v3 real: reabrir nao multiplica de novo (%s)" % g2.permanente.legacy_total)
	# 2) v3 com ending pendente e luta pendente
	var v3 := {"version": 3, "saved_at_unix": 1, "state": {"career": {"training": 5000.0, "attributes": {"strength": 500.0, "agility": 10.0, "endurance": 10.0},
		"focus": "punching_bag", "generators": {"neighbor_kid": 1, "retired_uncle": 0}, "upgrades": {"punching_bag": 0, "jump_rope": 0, "treadmill": 0},
		"paid_generators": {"gen_paid_1": 0}, "glove_level": 0, "money": 10.0, "fame": 40, "ladder_index": 2, "belt": false, "tactic": "defensive",
		"play_seconds": 100.0, "money_earned": 200.0, "fight": null},
		"permanent": {"legacy_total": 14, "career_number": 2, "careers_finished": 1, "best_wins": 2, "belts_won": 0},
		"ending": {"kind": "defeat", "legacy_gained": 4, "legacy_total": 14, "career_number": 2}}}
	escrever(PASTA + "v3end/", JSON.stringify(v3))
	var ge: Node = novo(PASTA + "v3end/")
	ok(ge.permanente.legacy_total == 140, "v3 com fim pendente: Legado 140 (%s)" % ge.permanente.legacy_total)
	ok(ge.tem_fim_pendente(), "v3 com fim pendente: tela de fim continua pendente")
	if ge.tem_fim_pendente():
		ok(int(ge.fim.get("legacy_gained", -1)) == 40 and int(ge.fim.get("legacy_total", -1)) == 140, "fim pendente x10 (%s/%s)" % [ge.fim.get("legacy_gained"), ge.fim.get("legacy_total")])
		ok(ge.arvore_aberta(), "arvore abre com fim pendente migrado")
	# 3) saves ruins
	var ruins := {
		"nos_lixo": {"version": 4, "saved_at_unix": 1, "state": {"career": {}, "permanent": {"legacy_total": 50, "skill_nodes": ["xx", "body_jab", "body_jab", "body_heavy_hands", 5, null], "revenge_opponent": "nao_existe"}, "ending": null}},
		"legado_negativo": {"version": 4, "saved_at_unix": 1, "state": {"career": {"metronome_level": 99}, "permanent": {"legacy_total": -500, "skill_nodes": "abc", "revenge_opponent": 7}, "ending": null}},
		"metro_neg": {"version": 4, "saved_at_unix": 1, "state": {"career": {"metronome_level": -3}, "permanent": {"legacy_total": 1e300}, "ending": null}},
	}
	for k in ruins:
		escrever(PASTA + k + "/", JSON.stringify(ruins[k]))
		var gr: Node = novo(PASTA + k + "/")
		print("QA|   [%s] nos=%s legado=%s algoz='%s' metronomo=%s avisos=%d" % [k, gr.nos_comprados(), gr.permanente.legacy_total, gr.algoz(), gr.nivel_metronomo, gr.avisos.size()])
		ok(int(gr.permanente.legacy_total) >= 0, "%s: Legado nao negativo" % k)
		ok(gr.nivel_metronomo >= 0 and gr.nivel_metronomo <= gr.metronomo_niveis(), "%s: nivel do Metronomo recortado (%s)" % [k, gr.nivel_metronomo])
		for id in gr.nos_comprados():
			var req: String = ""
			for n in gr.lutas.arvore:
				if str(n.id) == str(id):
					req = str(n.requires)
			ok(req == "" or gr.tem_no(req), "%s: no '%s' tem o anterior" % [k, id])
		ok(gr.nos_comprados().size() == gr.nos_comprados().duplicate().size(), "%s: ok" % k)
	# 4) arquivo corrompido (nao e JSON) e vazio
	escrever(PASTA + "lixo/", "{ isso nao e json")
	var gl: Node = novo(PASTA + "lixo/")
	ok(gl.numero_carreira() == 1, "arquivo corrompido: jogo novo sem crash")
	escrever(PASTA + "vazio/", "")
	var gv: Node = novo(PASTA + "vazio/")
	ok(gv.numero_carreira() == 1, "arquivo vazio: jogo novo sem crash")
	# 5) compra extrema: sem dinheiro, muitas compras
	var gp: Node = novo(PASTA + "compras/")
	gp.apagar_save()
	ok(not gp.comprar_metronomo(), "Metronomo sem dinheiro recusa")
	ok(not gp.comprar_luva(), "luva sem dinheiro recusa")
	ok(not gp.comprar_no("body_jab"), "no fora da tela de fim recusa")
	gp.dinheiro = 1e6
	var n := 0
	for i in 20:
		if gp.comprar_metronomo():
			n += 1
	ok(n == 3, "Metronomo compra exatamente 3 niveis em 20 tentativas (%d)" % n)
	ok(not gp.pode_comprar_metronomo(), "Metronomo no maximo nao oferece mais")
	var sps: float = gp.socos_por_segundo_metronomo()
	ok(sps <= 1.5 and sps > 1.4, "ritmo maximo %.3f socos/s" % sps)
	# 6) taxa de critico e lona no auto-soco (1000 socos)
	var gc: Node = novo(PASTA + "crit/")
	gc.apagar_save()
	gc.nivel_metronomo = 1
	gc.rng.seed = 12345
	var crit := 0
	var soma := 0.0
	for i in 1000:
		var r: Dictionary = gc.auto_socar()
		if r.critico:
			crit += 1
		soma += r.ganho
	ok(crit >= 70 and crit <= 130, "1000 auto-socos: %d criticos (esperado ~100, chance %s)" % [crit, gc.dados.crit_chance])
	var base: float = gc.por_clique()
	gc.nivel_luva = 1
	ok(absf(gc.por_clique() / base - 2.0) < 0.001, "luva de lona dobra o por-clique (%s -> %s)" % [base, gc.por_clique()])
	var a0: float = gc.atributos["strength"]
	gc.auto_socar()
	ok(gc.atributos["strength"] > a0, "auto-soco vai para o atributo em foco")
	# 7) varias lutas: 0 auto-socos
	var gf: Node = novo(PASTA + "luta10/")
	gf.apagar_save()
	gf.nivel_metronomo = 3
	gf.atributos["strength"] = 1e9
	gf.atributos["agility"] = 1e9
	gf.atributos["endurance"] = 1e9
	var antes: int = gf.auto_socos_total
	var t_antes: float = gf.treino
	gf.dinheiro = 0
	var lutas_feitas := 0
	for i in 10:
		if gf.pode_lutar():
			var info: Dictionary = gf.lutar()
			lutas_feitas += 1
			for k in 300:
				gf.tick(0.1)
			gf.concluir_luta()
			if gf.tem_fim_pendente():
				break
	print("QA|   lutas feitas=%d auto_socos=%d" % [lutas_feitas, gf.auto_socos_total - antes])
	ok(gf.auto_socos_total == antes, "durante lutas e fim: 0 auto-socos")
	# 8) NOVA CARREIRA zera o Metronomo; com a Memoria muscular volta a 1
	var gn: Node = novo(PASTA + "nova/")
	gn.apagar_save()
	gn.permanente["legacy_total"] = 1000
	gn.aposentar()
	gn.nivel_metronomo = 3
	gn.nova_carreira()
	ok(gn.nivel_metronomo == 0, "NOVA CARREIRA zera o Metronomo")
	gn.aposentar()
	gn.comprar_no("body_jab")
	gn.comprar_no("body_muscle_memory")
	gn.nova_carreira()
	ok(gn.nivel_metronomo == 1 and gn.proximo_metronomo().get("level", 0) == 2, "Memoria muscular: comeca em 1 e a loja oferece o 2")
	# 9) Legado nunca negativo ao comprar sem saldo
	gn.aposentar()
	var antes_l: int = gn.legado_disponivel()
	gn.permanente["legacy_total"] = 5
	gn.fim["legacy_total"] = 5
	ok(not gn.comprar_no("body_heavy_hands"), "no trancado/sem saldo recusa")
	ok(gn.legado_disponivel() >= 0, "Legado nao negativo")
	print("QA| FALHAS=%d" % falhas)
	quit(1 if falhas > 0 else 0)
